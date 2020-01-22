/**
 * SalesOrderHdrTriggerHandler
 * Tested by: SalesOrderHdrTriggerTest
 * Date: November 22, 2017
 * Programmer: Alexander Miller
 *
 * Alexander Miller (AMILLER1) 1.20.2018 Add functionality to automatically set an order to tax exempt unless part sales
 * Alexander Miller (AMILLER2) 5.2.2018 Updated work order to follow the same path with maps in updateAllMaps(), update to only let this class run once per record
 * Alexander Miller (AMILLER3) 7.9.2018 Update to calculate Number of entered orders, non-canceled, are entered below an opportnity
 * Alexander Miller (AMILLER4) 8.30.2018 Update to ignore canceled orders since they are usually part of a transfer
 * Alexander Miller (AMILLER5) 8.30.2018 Update to make sure division of the new orders are in sync
 * Alexander Miller (AMILLER6) 9.4.2018  Update to handle the removal of a Chassis from Sales Order Headers. The Chassis Master's references should be cleared out.
 * Alexander Miller (AMILLER7) 9.24.20178 - W-00361 - Update to handle the new TransitWorks custom Opportunities
 * Alexander Miller (AMILLER8) 11.1.2018  - W-000464 - Update to handle Opportunity Allocation checks
 * Alexander Miller (AMM9)     11.20.2018 - W-000498 - Update to handle the Project Budget/Cost object being tied to the Chassis Master for simpler reporting
 * Alexander Miller (AMM10)    2.25.2019  - IR-0049646 - Update to handle allowing multiple Chassis References on Canceled orders
 */
public class SalesOrderHdrTriggerHandler {

    public List<rstk__sohdr__c> newList = new List<rstk__sohdr__c>();
    public List<rstk__sohdr__c> oldList = new List<rstk__sohdr__c>();
    public Map<Id, rstk__sohdr__c> newMap = new Map<Id, rstk__sohdr__c>();
    public Map<Id, rstk__sohdr__c> oldMap = new Map<Id, rstk__sohdr__c>();

    public static List<rstk__sohdr__c> refreshedNewList = new List<rstk__sohdr__c>();

    public static Map<Id, rstk__sohdr__c> salesOrderHeaderMap = new Map<Id, rstk__sohdr__c>();
    public static Map<Id, Chassis_Master__c> chassisMasterMap = new Map<Id, Chassis_Master__c>();
    public static Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
    // AMILLER7
    public static Map<Id, Opportunity__c> opportunityCustomMap = new Map<Id, Opportunity__c>();
    public Map<Id, rstk__sohdr__c> salesOrderMap = new Map<Id, rstk__sohdr__c>();
    // AMILLER7
    public static Map<Id, rstk__wocst__c> workOrderMap = new Map<Id, rstk__wocst__c>();

    private static boolean run = true;

    Public static String changeHeaderMode = 'Change Header';

    public SalesOrderHdrTriggerHandler(){}

    public SalesOrderHdrTriggerHandler(rstk__sohdr__c [] newArray, rstk__sohdr__c [] oldArray, Map<Id, rstk__sohdr__c > newHashMap, Map<Id, rstk__sohdr__c > oldHashMap){
        newList = newArray;
        oldList = oldArray;
        newMap = newHashMap;
        oldMap = oldHashMap;
    }

    /**
    * AMILLER2
    * runOnce
    *
    * Function which helps prevent duplicate calls during updates
    */
    public static boolean runOnce(){
        if(run)
        {
            run=false;
            return true;
        }
        else
        {
            return run;
        }
    }

    /**
    * refreshAllFieldsNeeded
    *
    * function which grabs every connected field possible at the very
    * beginning so minimal SOQL queries are used since RootStock
    * has recursive trigger logic built in. 
    */
    public void refreshAllFieldsNeeded()
    {
        refreshedNewList = ([SELECT Id,
                                (SELECT Id, 
                                        rstk__soline_sohdr__c, 
                                        rstk__soline_sohdr__r.Chassis__c, 
                                        rstk__soline_price__c,
                                        rstk__searchindex__c
                                    FROM rstk__solines__r),
                                rstk__sohdr_cancelled__c,
                                Opportunity__c,
                                Opportunity__r.OwnerId,
                                Opportunity__r.Owner.Email,
                                Opportunity__r.Owner.Profile.Name,
                                // AMILLER7
                                Opportunity__r.Opportunity__c,
                                Opportunity_custom__c,
                                Opportunity_custom__r.OwnerId,
                                Opportunity_custom__r.Owner.Email,
                                Opportunity_custom__r.Owner.Profile.Name,
                                rstk__sohdr_opportunity__r.Opportunity__c,
                                rstk__sohdr_opportunity__r.Opportunity__r.OwnerId,
                                rstk__sohdr_opportunity__r.Opportunity__r.Owner.Email,
                                rstk__sohdr_opportunity__r.Opportunity__r.Owner.Profile.Name,
                                // AMILLER7
                                rstk__sohdr_opportunity__c,
                                rstk__sohdr_opportunity__r.OwnerId,
                                rstk__sohdr_opportunity__r.Owner.Email,
                                rstk__sohdr_opportunity__r.Owner.Profile.Name,
                                Chassis__c,
                                Chassis__r.Customer__c,
                                Chassis__r.Sales_Order_Chassis__c, 
                                Chassis__r.Work_Order_Chassis__c,
                                Chassis__r.Project_Master__c,
                                rstk__sohdr_custno__c,
                               Sales_Rep__c,
                                Sales_Rep__r.Email,
                                rstk__sohdr_otype__c,
                                rstk__sohdr_proj__c,
                                rstk__sohdr_otype__r.rstk__sootype_ordtype__c,
                                rstk__sohdr_taxexempt__c,
                                rstk__sohdr_div__c // AMILLER5
                            FROM rstk__sohdr__c
                            WHERE Id IN :newMap.keySet()]);
    }

    /**
    * updateAllMaps
    *
    * function which is called at the end of each after trigger and 
    * updates all of the maps used in the entire process at once.
    * This is to help prevent multiple DMLs/Triggers on the same 
    * object as much as possible in a manageable way.
    */
    public void updateAllMaps() 
    {
        update salesOrderMap.values();
        update chassisMasterMap.values();
        update opportunityMap.values();
        // AMILLER7
        update opportunityCustomMap.values();
        // AMILLER2
        update workOrderMap.values();
        
        // move inventory over if possible
        // replaced by front-loading the project assignment before receipt. Should not be hitting a home project initially
        //RootStockProjectToProjectTransfer.invokeProjectToProjectVehicleTransfer(chassisMasterMap.values());
    }

    /**
    * updateCustomOpportunityLink
    *
    * Function which pastes the new Custom Opportunity link to the Sales Oder header
    */
    public void updateCustomOpportunityLink()
    {        
        System.debug(refreshedNewList);

        for(rstk__sohdr__c tempSale : refreshedNewList)
        {   
            if(tempSale.Opportunity_custom__c == null && 
                tempSale.rstk__sohdr_opportunity__c != null &&
                tempSale.rstk__sohdr_opportunity__r.Opportunity__c != null)
            {
                if(salesOrderMap.get(tempSale.Id) == null)
                {
                    salesOrderMap.put(tempSale.Id, new rstk__sohdr__c(Id = tempSale.Id, Opportunity_custom__c = tempSale.rstk__sohdr_opportunity__r.Opportunity__c));
                }
                else
                {
                    salesOrderMap.get(tempSale.Id).Opportunity_custom__c = tempSale.rstk__sohdr_opportunity__r.Opportunity__c;
                }
            }
            else if(tempSale.Opportunity_custom__c == null && 
                        tempSale.Opportunity__c != null &&
                        tempSale.Opportunity__r.Opportunity__c != null)
            {
                if(salesOrderMap.get(tempSale.Id) == null)
                {
                    salesOrderMap.put(tempSale.Id, new rstk__sohdr__c(Id = tempSale.Id, Opportunity_custom__c = tempSale.Opportunity__r.Opportunity__c));
                }
                else
                {
                    salesOrderMap.get(tempSale.Id).Opportunity_custom__c = tempSale.Opportunity__r.Opportunity__c;
                }
            }
        }
    }

    /**
    * updateSalesRep
    *
    * Function which takes the parenting Opportunity and pastes the owner
    * if said owner is a Sales Profile user
    */
    public void updateSalesRep()
    {
        // AMILLER7
        for(rstk__sohdr__c tempSales : refreshedNewList)
        {
            if(tempSales.Opportunity_custom__c != null && 
                tempSales.Sales_Rep__c == null)
            {
                if(salesOrderMap.get(tempSales.Id) == null)
                {
                    salesOrderMap.put(tempSales.Id, new rstk__sohdr__c(Id = tempSales.Id, Sales_Rep__c = tempSales.Opportunity_custom__r.OwnerId));
                }
                else 
                {
                   salesOrderMap.get(tempSales.Id).Sales_Rep__c = tempSales.Opportunity_custom__r.OwnerId;
                }
            }
            else if(tempSales.rstk__sohdr_opportunity__c != null && 
                tempSales.rstk__sohdr_opportunity__r.Opportunity__c != null && 
                tempSales.rstk__sohdr_opportunity__r.Opportunity__r.Owner.Profile.Name.contains('Sale') &&
                tempSales.Sales_Rep__c == null)
            {
                if(salesOrderMap.get(tempSales.Id) == null)
                {
                    salesOrderMap.put(tempSales.Id, new rstk__sohdr__c(Id = tempSales.Id, Sales_Rep__c = tempSales.rstk__sohdr_opportunity__r.Opportunity__r.OwnerId));
                }
                else 
                {
                   salesOrderMap.get(tempSales.Id).Sales_Rep__c = tempSales.rstk__sohdr_opportunity__r.Opportunity__r.OwnerId;
                }
            }
            // Removed due to bad design
            // if(tempSales.Sales_Rep_Opportunity__c != null && tempSales.Sales_Rep_Opportunity__c != '')
            // {
            //     tempSales.Sales_Rep__c = tempSales.Sales_Rep_Opportunity__c;
            // }
        }
        // AMILLER7
    }

    // AMILLER6
    /**
    * chassisRemoval 
    *
    * Function which looks at the before and after to find
    * any Sales Order Headers which are removing a Chassis.
    * An update is needed to clear out the Chassis Master's 
    * reference back to the Sales Order
    *
    * A workflow rule works in tandem with this to assign the 
    * Ower as IT Department for reporting purposes.
    */
    public void chassisRemoval(Map<Id, rstk__sohdr__c> newMap, Map<Id, rstk__sohdr__c> oldMap)
    {
        for(rstk__sohdr__c tempOrder : newMap.values())
        {
            if(oldMap != null && 
                oldMap.get(tempOrder.Id) != null && 
                oldMap.get(tempOrder.Id).Chassis__c != null && 
                oldMap.get(tempOrder.Id).Chassis__c != newMap.get(tempOrder.Id).Chassis__c)
            {
                if(chassisMasterMap.get(oldMap.get(tempOrder.Id).Chassis__c) == null)
                {   
                    chassisMasterMap.put(oldMap.get(tempOrder.Id).Chassis__c, new Chassis_Master__c(Id = oldMap.get(tempOrder.Id).Chassis__c, 
                                                                                                        Sales_Order_Chassis__c = null, 
                                                                                                        Customer__c = null,
                                                                                                        Opportunity__c = null,
                                                                                                        // AMILLER7
                                                                                                        Opportunity_custom__c = null,
                                                                                                        // AMILLER7
                                                                                                        Project_Master__c = null,
                                                                                                        Project_Workbench__c = null,
                                                                                                        // AMM9
                                                                                                        Project_Budget_Cost__c = null,
                                                                                                        // AMM9
                                                                                                        Division__c = null
                                                                                                    ));
                }
            }
        }
    }
    // AMILLER6

    /**
    * linkChassis
    *
    */
    public void linkChassis()
    {
        // Query for Project Workbenchs and Project Masters
        List<Id> listOfProjectIds = new List<Id>();

        for(rstk__sohdr__c tempSalesOrder : refreshedNewList)
        {
            listOfProjectIds.add(tempSalesOrder.rstk__sohdr_proj__c);
        }

        List<rstk__pjwkb__c> listOfProjects = ([SELECT Id, 
                                                    rstk__pjwkb_proj_master__c
                                                FROM rstk__pjwkb__c
                                                WHERE rstk__pjwkb_proj_master__c in :listOfProjectIds]);

        Map<Id, rstk__pjwkb__c> mapOfProjectToWorkBench = new Map<Id, rstk__pjwkb__c>();

        for(rstk__pjwkb__c tempProject : listOfProjects)
        {
            mapOfProjectToWorkBench.put(tempProject.rstk__pjwkb_proj_master__c, tempProject);
        }  

        // AMM9
        List<rstk__pjprojcst__c> listOfProjectBudgets = ([SELECT Id, 
                                                            rstk__pjprojcst_proj__c
                                                        FROM rstk__pjprojcst__c
                                                        WHERE rstk__pjprojcst_proj__c in :listOfProjectIds]);

        Map<Id, rstk__pjprojcst__c> mapOfProjectToBudgets = new Map<Id, rstk__pjprojcst__c>();

        for(rstk__pjprojcst__c tempProject : listOfProjectBudgets)
        {
            mapOfProjectToBudgets.put(tempProject.rstk__pjprojcst_proj__c, tempProject);
        }
        // AMM9

        for(rstk__sohdr__c tempSalesOrder : refreshedNewList)
        {
            if(tempSalesOrder.Chassis__c != null && tempSalesOrder.rstk__sohdr_cancelled__c == false) // AMILLER4
            {
                String salesRepEmail = tempSalesOrder.Sales_Rep__r.Email != null ? tempSalesOrder.Sales_Rep__r.Email : '';

                // upsert into map to be updated in updateAllMaps()
                if(chassisMasterMap.get(tempSalesOrder.Chassis__c) != null) 
                {
                    chassisMasterMap.get(tempSalesOrder.Chassis__c).Customer__c = tempSalesOrder.rstk__sohdr_custno__c;
                    chassisMasterMap.get(tempSalesOrder.Chassis__c).Sales_Order_Chassis__c = tempSalesOrder.Id;
                    chassisMasterMap.get(tempSalesOrder.Chassis__c).Opportunity__c = tempSalesOrder.rstk__sohdr_opportunity__c != null ? tempSalesOrder.rstk__sohdr_opportunity__c : tempSalesOrder.Opportunity__c;
                    // AMILLER7
                    chassisMasterMap.get(tempSalesOrder.Chassis__c).Opportunity_custom__c = tempSalesOrder.Opportunity_custom__c != null ? tempSalesOrder.Opportunity_custom__c : tempSalesOrder.Opportunity__r.Opportunity__c;
                    // AMILLER7
                    chassisMasterMap.get(tempSalesOrder.Chassis__c).Project_Master__c = tempSalesOrder.rstk__sohdr_proj__c;
                    chassisMasterMap.get(tempSalesOrder.Chassis__c).Project_Workbench__c = mapOfProjectToWorkBench.get(tempSalesOrder.rstk__sohdr_proj__c).Id;
                    chassisMasterMap.get(tempSalesOrder.Chassis__c).Division__c = tempSalesOrder.rstk__sohdr_div__c;
                    
                    // AMM9
                    chassisMasterMap.get(tempSalesOrder.Chassis__c).Project_Budget_Cost__c = mapOfProjectToBudgets.get(tempSalesOrder.rstk__sohdr_proj__c).Id;
                    // AMM9

                    if(tempSalesOrder.Sales_Rep__c != null)
                    {  
                        chassisMasterMap.get(tempSalesOrder.Chassis__c).OwnerId = tempSalesOrder.Sales_Rep__c;
                        chassisMasterMap.get(tempSalesOrder.Chassis__c).Sales_Rep_Email__c = salesRepEmail;
                    }
                } 
                else if(tempSalesOrder.Chassis__c != null && tempSalesOrder.rstk__sohdr_cancelled__c == false) // AMILLER4
                {
                    if(tempSalesOrder.Sales_Rep__c != null)
                    {  
                        chassisMasterMap.put(tempSalesOrder.Chassis__c, new Chassis_Master__c(Id = tempSalesOrder.Chassis__c, 
                                                                                        Customer__c = tempSalesOrder.rstk__sohdr_custno__c,
                                                                                        Sales_Order_Chassis__c = tempSalesOrder.Id,
                                                                                        Opportunity__c = tempSalesOrder.rstk__sohdr_opportunity__c != null ? tempSalesOrder.rstk__sohdr_opportunity__c : tempSalesOrder.Opportunity__c,
                                                                                        // AMILLER7
                                                                                        Opportunity_custom__c = tempSalesOrder.Opportunity_custom__c != null ? tempSalesOrder.Opportunity_custom__c :  tempSalesOrder.Opportunity__r.Opportunity__c,
                                                                                        // AMILLER7
                                                                                        Project_Master__c = tempSalesOrder.rstk__sohdr_proj__c,
                                                                                        // AMM9
                                                                                        Project_Budget_Cost__c = mapOfProjectToBudgets.get(tempSalesOrder.rstk__sohdr_proj__c).Id,
                                                                                        // AMM9
                                                                                        OwnerId = tempSalesOrder.Sales_Rep__c,
                                                                                        Project_Workbench__c = mapOfProjectToWorkBench.get(tempSalesOrder.rstk__sohdr_proj__c).Id,
                                                                                        Division__c = tempSalesOrder.rstk__sohdr_div__c)); // AMILLER5
                    }
                    else 
                    {
                        chassisMasterMap.put(tempSalesOrder.Chassis__c, new Chassis_Master__c(Id = tempSalesOrder.Chassis__c, 
                                                                                        Customer__c = tempSalesOrder.rstk__sohdr_custno__c,
                                                                                        Sales_Order_Chassis__c = tempSalesOrder.Id,
                                                                                        Opportunity__c = tempSalesOrder.rstk__sohdr_opportunity__c != null ? tempSalesOrder.rstk__sohdr_opportunity__c : tempSalesOrder.Opportunity__c,
                                                                                        // AMILLER7
                                                                                        Opportunity_custom__c = tempSalesOrder.Opportunity_custom__c != null ? tempSalesOrder.Opportunity_custom__c :  tempSalesOrder.Opportunity__r.Opportunity__c,
                                                                                        // AMILLER7
                                                                                        Project_Master__c = tempSalesOrder.rstk__sohdr_proj__c,
                                                                                        // AMM9
                                                                                        Project_Budget_Cost__c = mapOfProjectToBudgets.get(tempSalesOrder.rstk__sohdr_proj__c).Id,
                                                                                        // AMM9
                                                                                        Project_Workbench__c = mapOfProjectToWorkBench.get(tempSalesOrder.rstk__sohdr_proj__c).Id,
                                                                                        Division__c = tempSalesOrder.rstk__sohdr_div__c)); // AMILLER5
                    }
                }
            }
        }
    }

    /**
    * updateRelatedOpportunityTotalSoPrice
    *
    * function which takes all of the Sales Orders related to the parent 
    * Opportunity and generates the total Sales Order Price
    */
    public void updateRelatedOpportunityTotalSoPrice()
    {
        List<rstk__sohdr__c> listOfAllRelatedSalesOrdersByOpportunity = new List<rstk__sohdr__c>();
        List<List<rstk__sohdr__c>> twoDimensionalArrayOfSalesOrdersByOpportunity = new List<List<rstk__sohdr__c>>();
        Map<Id, Opportunity> mapOfOpportunityIds = new Map<Id, Opportunity>();
        // AMILLER7
        Map<Id, Opportunity__c> mapOfOpportunityCustomIds = new Map<Id, Opportunity__c>();
        // AMILLER7

        for(rstk__sohdr__c tempSalesOrder : refreshedNewList)
        {
            if(tempSalesOrder.rstk__sohdr_opportunity__c != null)
            {
                if(mapOfOpportunityIds.get(tempSalesOrder.rstk__sohdr_opportunity__c) == null) 
                {
                    mapOfOpportunityIds.put(tempSalesOrder.rstk__sohdr_opportunity__c, new Opportunity(Id=tempSalesOrder.rstk__sohdr_opportunity__c));
                } 
            }

            // AMILLER7
            if(tempSalesOrder.Opportunity_custom__c != null)
            {
                if(mapOfOpportunityCustomIds.get(tempSalesOrder.Opportunity_custom__c) == null) 
                {
                    mapOfOpportunityCustomIds.put(tempSalesOrder.Opportunity_custom__c, new Opportunity__c(Id=tempSalesOrder.Opportunity_custom__c));
                } 
            }
            // AMILLER7
        }

        // take all of the Opportunities Ids and then query to find all of the related Sales Orders to update the opp
        listOfAllRelatedSalesOrdersByOpportunity = ([SELECT Id,
                                                        rstk__sohdr_cancelled__c,
                                                        Opportunity__c,
                                                        Intercompany_Excluded_Price__c,
                                                        rstk__sohdr_ordertotal__c, 
                                                        rstk__sohdr_opportunity__c, 
                                                        rstk__sohdr_opportunity__r.Sales_Order_Total_Price__c,
                                                        // AMILLER7
                                                        Opportunity__r.Opportunity__c,
                                                        Opportunity_custom__c,
                                                        Opportunity_custom__r.Sales_Order_Total_Price__c
                                                        // AMILLER7
                                                    FROM rstk__sohdr__c 
                                                    WHERE rstk__sohdr_cancelled__c = false AND
                                                        (rstk__sohdr_opportunity__c IN :mapOfOpportunityIds.KeySet() OR
                                                        Opportunity__c IN :mapOfOpportunityIds.KeySet() OR
                                                        Opportunity_custom__c IN :mapOfOpportunityCustomIds.keySet())]); // AMILLER7


        // clear the totals for accurate calculations
        for(rstk__sohdr__c tempSalesOrder : listOfAllRelatedSalesOrdersByOpportunity)
        {
            // AMILLER7
            if(opportunityCustomMap.get(tempSalesOrder.Opportunity_custom__c) != null ) 
            {
                opportunityCustomMap.get(tempSalesOrder.Opportunity_custom__c).Sales_Order_Total_Price__c = 0;
            }
            else if(tempSalesorder.Opportunity_custom__r != null && opportunityCustomMap.get(tempSalesOrder.Opportunity_custom__c) == null )
            {
                opportunityCustomMap.put(tempSalesorder.Opportunity_custom__c, new Opportunity__c(Id = tempSalesorder.Opportunity_custom__c, Sales_Order_Total_Price__c = 0));
            }
            // AMILLER7
            else if(opportunityMap.get(tempSalesOrder.rstk__sohdr_opportunity__c) != null ) 
            {
                opportunityMap.get(tempSalesOrder.rstk__sohdr_opportunity__c).Sales_Order_Total_Price__c = 0;
            }
            else if(opportunityMap.get(tempSalesOrder.Opportunity__c) != null)
            {
                opportunityMap.get(tempSalesOrder.Opportunity__c).Sales_Order_Total_Price__c = 0;
            }
        }
        
        // calculate the totals
        for(rstk__sohdr__c tempSalesOrder : listOfAllRelatedSalesOrdersByOpportunity)
        {
            System.debug(tempSalesOrder);

            // AMILLER7
            if(opportunityCustomMap.get(tempSalesOrder.Opportunity_custom__c) != null)
            {
                opportunityCustomMap.get(tempSalesOrder.Opportunity_custom__c).Sales_Order_Total_Price__c = opportunityCustomMap.get(tempSalesOrder.Opportunity_custom__c).Sales_Order_Total_Price__c + tempSalesOrder.Intercompany_Excluded_Price__c;
            }
            // AMILLER7
            else if(opportunityMap.get(tempSalesOrder.rstk__sohdr_opportunity__c) != null) 
            {
                opportunityMap.get(tempSalesOrder.rstk__sohdr_opportunity__c).Sales_Order_Total_Price__c = opportunityMap.get(tempSalesOrder.rstk__sohdr_opportunity__c).Sales_Order_Total_Price__c + tempSalesOrder.Intercompany_Excluded_Price__c;
            } 
            else if(opportunityMap.get(tempSalesOrder.Opportunity__c) != null)
            {
                opportunityMap.get(tempSalesOrder.Opportunity__c).Sales_Order_Total_Price__c = opportunityMap.get(tempSalesOrder.Opportunity__c).Sales_Order_Total_Price__c + tempSalesOrder.Intercompany_Excluded_Price__c;
            }
            else
            {
                Opportunity tempOpp = tempSalesOrder.rstk__sohdr_opportunity__c != null ? new Opportunity(Id = tempSalesOrder.rstk__sohdr_opportunity__c, Sales_Order_Total_Price__c = tempSalesOrder.Intercompany_Excluded_Price__c) : new Opportunity(Id = tempSalesOrder.Opportunity__c, Sales_Order_Total_Price__c = tempSalesOrder.Intercompany_Excluded_Price__c);

                opportunityMap.put(tempOpp.Id, tempOpp);
            }
        }

        // AMILLER3
        // Calculate total orders entered
        for(rstk__sohdr__c tempSalesOrder : listOfAllRelatedSalesOrdersByOpportunity)
        {
            // AMILLER7
            if(opportunityCustomMap.get(tempSalesOrder.Opportunity_custom__c) != null)
            {
                opportunityCustomMap.get(tempSalesOrder.Opportunity_custom__c).Number_of_Orders_Entered__c = 0;
            }
            // AMILLER7
            else if(opportunityMap.get(tempSalesOrder.rstk__sohdr_opportunity__c) != null ) 
            {
                opportunityMap.get(tempSalesOrder.rstk__sohdr_opportunity__c).Number_of_Orders_Entered__c = 0;
            }
            else if(opportunityMap.get(tempSalesOrder.Opportunity__c) != null)
            {
                opportunityMap.get(tempSalesOrder.Opportunity__c).Number_of_Orders_Entered__c = 0;
            }
        }


        for(rstk__sohdr__c tempSalesOrder : listOfAllRelatedSalesOrdersByOpportunity)
        {
            System.debug(tempSalesOrder);

            // AMILLER7
            if(opportunityCustomMap.get(tempSalesOrder.Opportunity_custom__c) != null && tempSalesOrder.rstk__sohdr_cancelled__c != true)
            {
                Decimal tempInt = opportunityCustomMap.get(tempSalesOrder.Opportunity_custom__c).Number_of_Orders_Entered__c;
                opportunityCustomMap.get(tempSalesOrder.Opportunity_custom__c).Number_of_Orders_Entered__c = tempInt + 1;
            }
            // AMILLER7
            if(opportunityMap.get(tempSalesOrder.Opportunity__c) != null && tempSalesOrder.rstk__sohdr_cancelled__c != true)
            {
                Decimal tempInt = opportunityMap.get(tempSalesOrder.Opportunity__c).Number_of_Orders_Entered__c;
                opportunityMap.get(tempSalesOrder.Opportunity__c).Number_of_Orders_Entered__c = tempInt + 1;
            }
        }
        // AMILLER3
    }

    /**
    * updateChassisTotalShipSale
    *
    * function which takes all of the children lines of the order
    * and sums all lines with a product containing the name "Vehicle Ship".
    * The Outbound Ship Sale is updated with the total sum for the order
    */
    public void updateChassisTotalShipSale()
    {
        for(rstk__sohdr__c tempHeader : refreshedNewList)
        {
            Decimal totalShipAmount = 0;

            for(rstk__soline__c tempSoLine : tempHeader.rstk__solines__r)
            {
                if(tempSoLine.rstk__searchindex__c.contains('VEHICLE SHIP'))
                {
                    totalShipAmount += tempSoLine.rstk__soline_price__c;
                }
            }

            if(chassisMasterMap.get(tempHeader.Chassis__c) != null) 
            {
                chassisMasterMap.get(tempHeader.Chassis__c).Outbound_Ship_Sale__c = totalShipAmount;
            } 
            else if(tempHeader.Chassis__c != null)
            {
                chassisMasterMap.put(tempHeader.Chassis__c, new Chassis_Master__c(Id = tempHeader.Chassis__c, 
                                                                                    Outbound_Ship_Sale__c = totalShipAmount));
            }
        }
    }

    // AMILLER8
    /**
    * checkIfChassisAllocationIsLegal
    *
    * Function to check on the update of a Sales Order to ensure the 
    * Chassis involved was allocated to the header Opportunity
    * prior
    *
    * @param newSOMap - Map<Id, rstk__sohdr__c> map of sales orders in the new context in the before update call
    */
    public void checkIfChassisAllocationIsLegal(Map<Id, rstk__sohdr__c> newSOMap, Map<Id, rstk__sohdr__c> oldSOMap)
    {   
        // 1. Figure out which Sales Orders have Chassis Modified to save resources
        List<rstk__sohdr__c> listOfSalesOrdersModifiedChassis = new List<rstk__sohdr__c>();
        List<Id> listOfSOIds = new List<Id>();

        for(rstk__sohdr__c tempSalesOrder : newSOMap.values())
        {
            if(tempSalesOrder.Chassis__c != null && 
                oldSOMap.get(tempSalesOrder.Id) != null && 
                newSOMap.get(tempSalesOrder.Id).Chassis__c != oldSOMap.get(tempSalesOrder.Id).Chassis__c &&
                tempSalesOrder.Opportunity_custom__c != null)
            {
                listOfSalesOrdersModifiedChassis.add(tempSalesOrder);
                // 2. Get the Custom Opportunity Ids
                listOfSOIds.add(tempSalesOrder.Opportunity_custom__c);
            }
        }

        // 3. Query the system for all the chassis tied to those Opportunities through allocation
        Map<Id, Chassis_Master__c> mapOfChassis = new Map<Id, Chassis_Master__c>([SELECT Id,
                                                                                    Opportunity_Allocation__c,
                                                                                    Opportunity_Allocation__r.Name,
                                                                                    Name
                                                                                FROM Chassis_Master__c 
                                                                                WHERE Opportunity_Allocation__c != null AND
                                                                                    Opportunity_Allocation__c IN :listOfSOIds]);

        Map<Id, Id> mapOfChassisToOpportunities = new Map<Id, Id>();

        for(Chassis_Master__c tempChassis : mapOfChassis.values())
        {
            mapOfChassisToOpportunities.put(tempChassis.Id, tempChassis.Opportunity_Allocation__c);
        }

        // 4. Validate they are proper chassis and show an error otherwise
        for(rstk__sohdr__c tempSalesOrder : listOfSalesOrdersModifiedChassis)
        {
            if(tempSalesOrder.Chassis__c != null && mapOfChassis.get(tempSalesOrder.Chassis__c) == null )
            {
                tempSalesOrder.addError('Chassis ' + tempSalesOrder.Chassis__c + ' is not assigned to an Opportunity through the Allocation process or it is assigned to a different Opportunity. Please contact your IT Department if you believe this is an error.');
            }
        }
    }

    /**
    * checkIfChassisIsUsedInAnotherOrder
    *
    * Function which takes looks at all the other 
    * orders in the system to ensure the Chassis
    * is not used on another order
    *
    * @param newSOMap - Map<Id, rstk__sohdr__c> map of sales orders in the new context in the before update call
    */
    public void checkIfChassisIsUsedInAnotherOrder(Map<Id, rstk__sohdr__c> newSOMap, Map<Id, rstk__sohdr__c> oldSOMap)
    {
        // 1. Figure out which Sales Orders have Chassis Modified to save resources
        List<rstk__sohdr__c> listOfSalesOrdersModifiedChassis = new List<rstk__sohdr__c>();
        List<Id> listofChassisId = new List<Id>();

        for(rstk__sohdr__c tempSalesOrder : newSOMap.values())
        {
            if(tempSalesOrder.Chassis__c != null && 
                oldSOMap.get(tempSalesOrder.Id) != null && 
                newSOMap.get(tempSalesOrder.Id).Chassis__c != oldSOMap.get(tempSalesOrder.Id).Chassis__c)
            {
                listOfSalesOrdersModifiedChassis.add(tempSalesOrder);
                listofChassisId.add(tempSalesOrder.Chassis__c);
            }
        }

        System.debug(listOfSalesOrdersModifiedChassis);

        // 2. Query every Sales Order in the system to see if multiples exist
        List<rstk__sohdr__c> listOfSalesOrders = ([SELECT Id,
                                                    Name,
                                                    Chassis__c
                                                FROM rstk__sohdr__c 
                                                WHERE Chassis__c != null AND
                                                    Chassis__c IN :listofChassisId AND
                                                    rstk__sohdr_cancelled__c = false]);

        System.debug(listOfSalesOrders);

        // 3. Compile list of Chassis with list of Sales Orders
        Map<Id, List<rstk__sohdr__c>> mapOfChassisToSalesOrders = new Map<Id, List<rstk__sohdr__c>>();

        for(rstk__sohdr__c tempSalesOrder : listOfSalesOrders)
        {
            if(mapOfChassisToSalesOrders.get(tempSalesOrder.Chassis__c) == null)
            {
                List<rstk__sohdr__c> tempList = new List<rstk__sohdr__c>();

                tempList.add(tempSalesOrder);

                mapOfChassisToSalesOrders.put(tempSalesOrder.Chassis__c, tempList);
            }
            else 
            {
                List<rstk__sohdr__c> tempList = mapOfChassisToSalesOrders.get(tempSalesOrder.Chassis__c);

                tempList.add(tempSalesOrder);

                mapOfChassisToSalesOrders.put(tempSalesOrder.Chassis__c, tempList);
            }
        }

        System.debug(mapOfChassisToSalesOrders);

        // 4. Validate they are proper chassis and show an error otherwise
        for(rstk__sohdr__c tempSalesOrder : newSOMap.values())
        {
            if(tempSalesOrder.Chassis__c != null && mapOfChassisToSalesOrders.get(tempSalesOrder.Chassis__c) != null && mapOfChassisToSalesOrders.get(tempSalesOrder.Chassis__c).size() > 1)
            {
                tempSalesOrder.addError('Chassis ' + tempSalesOrder.Chassis__c + ' is assigned to multiple Sales Orders which is not allowed. Please contact your IT Department if you believe this is an error.');
            }
        }
    }
    // AMILLER8

    /**
    * updateRelatedWorkOrderIfChassisChanged
    *
    * function which fires if the Sales Order 
    * Chassis Master reference changed or was 
    * newly inserted. It updates the Work Order
    */
    public void updateRelatedWorkOrderIfChassisChanged()
    {

        List<rstk__wocst__c> listOfWorkOrdersToUpdate = new List<rstk__wocst__c>();
        Set<Id> setOfSalesId = new Set<Id>();

        // get a list of all sales which have modified chassis references
        for(rstk__sohdr__c tempSales : refreshedNewList)
        {
            if(oldMap.get(tempSales.Id).Chassis__c != tempSales.Chassis__c)
            {
                setOfSalesId.add(tempSales.Id);
            }
        }

        // AMILLER2
        // compile list of work orders to update
        workOrderMap = new Map<Id, rstk__wocst__c>([SELECT Id FROM rstk__wocst__c WHERE rstk__wocst_soline__r.rstk__soline_sohdr__c IN :setOfSalesId]);
    }
}