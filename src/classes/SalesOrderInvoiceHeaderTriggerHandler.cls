/**
* SalesOrderInvoiceHeaderTriggerHandler
* 
* Tested by: SalesOrderInvHdrTriggerHandlerTest
* Programmer: Alexander Miller
* Date: 2017-09-14
*
* Primary handler class for the opportunity trigger
*
*
* 06-28-2018 Alexander Miller (AMILLER) - Bug 000356 idenfied where the future will fire and take up the Async channels even though it won't 
*                                           update the County because the County field is already filled in. Migrated pre-processing check to the Handler
*                                           to prevent Future fires from happening unless absolutely needed.
*
* 07-03-2018 Alexander Miller (AMILLER2) -Bug where the County was derived from the Billing and not shipping address
*
* 09-27-2018 Alexander Miller (AMILLER3) - W-000361 - Update to carry the new Opportunity Link
* 02-19-2019 Alexander Miller (AMM4)     - IR-0049158 - Update to handle Project Budget/Cost record update since it doesn't seem to occur on invoicing
* 04-17-2019 Alexander Miller (AMM5)     - IR-0052901 - Update to handle Project Budget/Cost records not updating
*/
public class SalesOrderInvoiceHeaderTriggerHandler{ 

    /** runOnce - a static variable to prevent double runs in the future callout */
    public static boolean runOnce = true;

    /** salesInvoiceObject - string containing the API name of the FinancialForce Sales Invoice object */
    public static String salesInvoiceObject = 'c2g__codaInvoice__c';
    
    /** creditNoteObject - string containing the API name of the FinancialForce Sales Credit Note object */
    public static String creditNoteObject = 'c2g__codaCreditNote__c';

    public static Map<Id, c2g__codaInvoice__c> saleInvoicesToUpdate = new Map<Id, c2g__codaInvoice__c>();
    public static Map<Id, c2g__codaTransaction__c> transactionsToUpdate = new Map<Id, c2g__codaTransaction__c>();
    public static Map<Id, c2g__codaCreditNote__c> creditNotesToUpdate = new Map<Id, c2g__codaCreditNote__c>();
    
    // AMILLER3
    public static Map<Id, Opportunity__c> customOpportunityToUpdate = new Map<Id, Opportunity__c>();
    // AMILLER3

    public SalesOrderInvoiceHeaderTriggerHandler(){} 

    /**
    * updateAllMaps
    *
    * Single function which takes all the updates made in this handler 
    * and performs one DML per object.
    */
    public static void updateAllMaps()
    {
        update saleInvoicesToUpdate.values();
        update transactionsToUpdate.values();
        update creditNotesToUpdate.values();
        update customOpportunityToUpdate.values(); // AMILLER3
    }

    // AMILLER3
    /**
    * updateOpportunityInfo
    *
    * Function which takes the Sales Order Header's new
    * Opportunity link and pastes it into the Invoice
    */
    public static void updateOpportunityInfo(List<rstk__soinv__c> newList)
    {
        List<Id> listOfSalesOrderIds = new List<Id>();

        for(rstk__soinv__c tempInvoice : newList)
        {
            if(tempInvoice.Opportunity__c == null)
            {
                listOfSalesOrderIds.add(tempInvoice.rstk__soinv_order__c);
            }
        }

        List<rstk__sohdr__c> listOfRelatedSalesOrders = ([SELECT Id,
                                                            Opportunity_custom__c 
                                                        FROM rstk__sohdr__c 
                                                        WHERE Id IN :listOfSalesOrderIds]);
        
        for(rstk__soinv__c tempInvoice : newList)
        {
            for(rstk__sohdr__c tempSale : listOfRelatedSalesOrders)
            {
                if(tempInvoice.rstk__soinv_order__c == tempSale.Id && tempSale.Opportunity_custom__c != null)
                {
                    tempInvoice.Opportunity__c = tempSale.Opportunity_custom__c;
                }
            }
        }
    }

    /**
    * updateOpportunityLandedGP
    *
    * Function which takes the total intercompany invoice amount against the 
    * project's total cost and reports their GP
    */
    public static void updateOpportunityLandedGP(List<rstk__soinv__c> newList, Map<Id, rstk__soinv__c> oldMap)
    {
        // 1. Filter for anything that is newly transfered to A/R and has the new Custom Opportunity link
        List<Id> listOfOpportunitiesNewlyInvoiced = new List<Id>();
        Map<Id, Decimal> mapOfGpByOpportunity = new Map<Id, Decimal>();

        for(rstk__soinv__c tempInvoice : newList)
        {
            if(tempInvoice.rstk__soinv_transferred__c == true && 
                oldMap != null && 
                tempInvoice.rstk__soinv_transferred__c != oldMap.get(tempInvoice.Id).rstk__soinv_transferred__c &&
                tempInvoice.Opportunity__c != null)
            {
                listOfOpportunitiesNewlyInvoiced.add(tempInvoice.Opportunity__c);
            }
        }

        // 2. Query for the related Chassis Master and pull their GP calculations
        List<Chassis_Master__c> listOfChassisMaster = ([SELECT Id,
                                                            Gross_Profit__c,
                                                            Opportunity_custom__c
                                                        FROM Chassis_Master__c
                                                        WHERE Opportunity_custom__c IN :listOfOpportunitiesNewlyInvoiced]);

        for(Chassis_Master__c tempChassis : listOfChassisMaster)
        {
            if(mapOfGpByOpportunity.get(tempChassis.Opportunity_custom__c) == null)
            {
                mapOfGpByOpportunity.put(tempChassis.Opportunity_custom__c, tempChassis.Gross_Profit__c);
            }
            else 
            {
                Decimal tempGP = mapOfGpByOpportunity.get(tempChassis.Opportunity_custom__c);
                tempGP += tempChassis.Gross_Profit__c;
                mapOfGpByOpportunity.put(tempChassis.Opportunity_custom__c, tempGP);
            }
        }

        // 3. Update Opportunities
        for(Id tempOpp : mapOfGpByOpportunity.keySet())
        {
            if(customOpportunityToUpdate.get(tempOpp) == null)
            {
                customOpportunityToUpdate.put(tempOpp, new Opportunity__c(Id=tempOpp, Landed_GP__c = mapOfGpByOpportunity.get(tempOpp)));
            }
            else 
            {
                customOpportunityToUpdate.get(tempOpp).Landed_GP__c = mapOfGpByOpportunity.get(tempOpp);
            }
        }
    }

    // AMILLER3

    /**
    * addChassisToFinancialForceRecords
    *
    * function which figures out the object of the financialforce object 
    * and then adds the Chassis master reference
    *
    * @param List<rstk__soinv__c>  - all of the new Sales Order Invoice records
    */
    public static void addChassisToFinancialForceRecords(List<rstk__soinv__c> tempNewList)
    {
        /** listOfSalesInvoices - list containing all FinancialForce Sale Invoices tied to Sales Order Invoice Headers in Rootstock */
        List<c2g__codaInvoice__c> listOfSalesInvoices = new List<c2g__codaInvoice__c>();
        
        /** listOfSalesCreditNotes - list containing all FinancialForce Sales Credit Notes tied to Sales Order Invoice Headers in Rootstock */
        List<c2g__codaCreditNote__c> listOfSalesCreditNotes = new List<c2g__codaCreditNote__c>();

        for(rstk__soinv__c tempSaleOrderInvoice : tempNewList)
        {
            if(tempSaleOrderInvoice.rstk__soinv_acctinvoice__c != null && tempSaleOrderInvoice.rstk__soinv_acctinvoice__c != '')
            {
                Id tempId = tempSaleOrderInvoice.rstk__soinv_acctinvoice__c;
                String objectType = String.valueOf(tempId.getsobjecttype());
            
                if(objectType.equals(salesInvoiceObject))
                {
                    if(saleInvoicesToUpdate.get(tempId) == null)
                    {
                        saleInvoicesToUpdate.put(tempId, new c2g__codaInvoice__c(Id=tempId, Chassis_Master__c=tempSaleOrderInvoice.Chassis__c,
                                                            Sales_Order_Invoice_Header__c = tempSaleOrderInvoice.Id));

                        System.debug(tempSaleOrderInvoice.Id);
                    }
                    else
                    {
                        saleInvoicesToUpdate.get(tempId).Chassis_Master__c=tempSaleOrderInvoice.Chassis__c;
                        saleInvoicesToUpdate.get(tempId).Sales_Order_Invoice_Header__c=tempSaleOrderInvoice.Id;
                        System.debug(tempSaleOrderInvoice.Id);
                    }   
                }
                else if(objectType.equals(creditNoteObject))
                {
                    if(creditNotesToUpdate.get(tempId) == null)
                    {
                        creditNotesToUpdate.put(tempId, new c2g__codaCreditNote__c(Id=tempId, Chassis_Master__c=tempSaleOrderInvoice.Chassis__c,
                                                                                Sales_Order_Invoice_Header__c=tempSaleOrderInvoice.Id));
                                                                                System.debug(tempSaleOrderInvoice.Id);
                    }
                    else
                    {
                        creditNotesToUpdate.get(tempId).Chassis_Master__c=tempSaleOrderInvoice.Chassis__c;
                        creditNotesToUpdate.get(tempId).Sales_Order_Invoice_Header__c=tempSaleOrderInvoice.Id;
                        System.debug(tempSaleOrderInvoice.Id);
                    } 
                }
            }
        }
    }

    /**
    * fireFutureLocateAddressIfNeeded
    *
    * Function which cycles through all the Sales Orders found in the new map. If any of them 
    * have a blank County, then it will pass on the ID of the Sales Order Invoice to the future 
    * method. Otherwise, it just lets it sit.
    *
    * @param - tempNewList List<rstk__soinv__c> list of Invoices to be evaluated for their County status
    */
    public static void fireFutureLocateAddressIfNeeded(List<rstk__soinv__c> tempNewList)
    {
        //AMILLER
        Set<Id> setOfIds = new Set<Id>();

        for(rstk__soinv__c tempInvoice : tempNewList)
        {
            if(String.isBlank(tempInvoice.County__c))
            {
                setOfIds.add(tempInvoice.Id);
            }
        }

        if(setOfIds.size() > 0)
        {
            SalesOrderInvoice_LocateAddress(setOfIds);
        }  
        //AMILLER 
    }
    
    // Updates account with county
    @future(callout=true)
    public static void SalesOrderInvoice_LocateAddress(Set<Id> acctids) {

        runOnce = false;

        MonitorExecution mon = new MonitorExecution('SalesOrderInvoice_LocateAddress');
      
        boolean error = false;
        
        List<rstk__soinv__c> toUpdate = new List<rstk__soinv__c>();

        List<rstk__soinv__c> accounts = ([SELECT Id, 
                                                County__c,
                                                rstk__soinv_address1__c, 
                                                rstk__soinv_city__c,
                                                rstk__soinv_state__c, 
                                                rstk__soinv_zip__c, 
                                                rstk__soinv_country__c,
                                                // AMILLER2
                                                Sales_Order_Shipping_Street_1__c,
                                                Sales_Order_Shipping_Street_2__c,
                                                Sales_Order_Shipping_Street_3__c,
                                                Sales_Order_Shipping_City__c,
                                                Sales_Order_Shipping_State__c,
                                                Sales_Order_Shipping_Zip__c,
                                                Sales_Order_Shipping_Country__c
                                                // AMILLER2
                                        FROM rstk__soinv__c
                                        WHERE Id in :acctids]);

        for(rstk__soinv__c a : accounts) 
        {
            boolean updateAcct = false;
            
            try { 
                
                System.debug(a.County__c);

                if (String.isBlank(a.County__c)) 
                {
                    System.debug('made it in?');

                    String address = '';

                    if (a.Sales_Order_Shipping_City__c=='Unknown')
                    {
                        // a.Sales_Order_Shipping_City__c = null;  // BLL3a Skip this city name // AMILLER2
                    }
                
                    if (a.Sales_Order_Shipping_Street_1__c <> null)
                    {
                        address = address + a.Sales_Order_Shipping_Street_1__c;
                    }

                    if (a.Sales_Order_Shipping_City__c <> null)
                    {
                        address = address + ' ' + a.Sales_Order_Shipping_City__c;
                    }

                    if (a.Sales_Order_Shipping_State__c <> null)
                    {
                        address = address + ' ' + a.Sales_Order_Shipping_State__c;
                    }
                
                    if (a.Sales_Order_Shipping_Zip__c <> null)
                    { 
                        address = address + ' ' + a.Sales_Order_Shipping_Zip__c;
                    }
                    
                    if (a.Sales_Order_Shipping_Country__c <> null)
                    { 
                        address = address + ' ' + a.Sales_Order_Shipping_Country__c;
                    }

                    address = address.trim();
                    
                    GeoLocationResult loc = GeoLocationHelper.getAddressLocation(address);
                    
                    mon.log('Account address: ' + address + ' = ' + JSON.serialize(loc));  // BLL2a
          
                    // only trustworthy if specified zip matches return zip 
                    if (loc!=null) 
                    {   
                        // AMILLER2                     
                        // if (String.isBlank(a.Sales_Order_Shipping_City__c) && !String.isBlank(loc.City)) 
                        // {
                        //     a.Sales_Order_Shipping_City__c = loc.City;
                        //     System.debug('Assigned city ' + a.Sales_Order_Shipping_City__c + ' from geo location result');
                        // }
                        
                        // if (String.isBlank(a.Sales_Order_Shipping_State__c) && !String.isBlank(loc.StateCode)) 
                        // {
                        //     a.Sales_Order_Shipping_State__c = loc.StateCode;
                        //     System.debug('Assigned state ' + a.Sales_Order_Shipping_State__c + ' from geo location result');
                        // }
                        // AMILLER2  

                        if (String.isBlank(a.County__c) && !String.isBlank(loc.County))
                        {
                            a.County__c = loc.County;
                            System.debug('Assigned county ' + a.County__c + ' from geo location result');
                        }

                        updateAcct = true;

                        System.debug('Assigned County');

                    } else {
                        System.debug('Could not retrieve location for address: ' + address);
                    }
                }
            } catch(Exception e) { 
                mon.log('EXCEPTION: ' + e.getTypeName() + '; ' + e.getMessage() + '; ' + e.getCause() + '; line ' + String.valueOf(e.getLineNumber()) + ';\n' + e.getStackTraceString());  // BLL6a
                error = true;
            } 
            
            // Update lead if either lat/lng changed or store assigned
            if (updateAcct) 
            {
                toUpdate.add(a);
            }
        }

        if (toUpdate.size()>0 || Test.isRunningTest()) 
        {
            try {
                update(toUpdate);
            } catch(Exception e) {
                mon.log('EXCEPTION: ' + e.getTypeName() + '; ' + e.getMessage() + '; ' + e.getCause() + '; line ' + String.valueOf(e.getLineNumber()) + ';\n' + e.getStackTraceString());  // BLL6a
                error = true;
                System.debug('Error in Account_LocateAddress: ' + e);
            }
        }

        if (error || mon.AlwaysNotify) 
        {
            mon.notifyAdmin();
        }
   }

    // AMM4
    /**
    * updateProjectBudgetCostTransferToAR
    *
    * Function which takes the Project Master reference
    * to the invoice and forces an update to the 
    * child Project Budget/Cost record so all 
    * values are updated when Transfer to A/R 
    * occurs.
    */
    public static void updateProjectBudgetCostTransferToAR(List<rstk__soinv__c> tempNewList, Map<Id, rstk__soinv__c> oldMap)
    {
        List<Id> listOfProjectMasterIds = new List<Id>();

        System.debug('updateProjectBudgetCostTransferToAR');

        for(rstk__soinv__c tempInvoice : tempNewList)
        { 
            // Only account for those records which were just transfered 
            if(oldMap != null && oldMap.get(tempInvoice.Id) != null && 
                oldMap.get(tempInvoice.Id).rstk__soinv_transferred__c == false && 
                tempInvoice.rstk__soinv_transferred__c == true && 
                // AMM5
                //tempInvoice.rstk__soinv_grandtotal__c == 0 && 
                // AMM5
                // AMM4
                tempInvoice.rstk__soinv_txntype__c == 'Invoice') 
                // AMM4
            {   
                listOfProjectMasterIds.add(tempInvoice.rstk__soinv_project__c);
            }
        }

        System.debug('updateProjectBudgetCostTransferToAR: listOfProjectMasterIds: ' + listOfProjectMasterIds);

        if(listOfProjectMasterIds.size() > 0)
        {
            List<rstk__pjprojcst__c> listOfProjectBudgetCost = ([SELECT Id 
                                                            FROM rstk__pjprojcst__c 
                                                            WHERE rstk__pjprojcst_proj__c IN :listOfProjectMasterIds]);

            System.debug('updateProjectBudgetCostTransferToAR: listOfProjectBudgetCost: ' + listOfProjectBudgetCost);

            // Call update to commence rollups  
            update listOfProjectBudgetCost;
        }
    }
    // AMM4
}