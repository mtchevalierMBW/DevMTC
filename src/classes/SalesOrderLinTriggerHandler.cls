/**
 * SalesOrderLinTriggerHandler
 * Tested by: SalesOrderLinTriggerHandlerTest
 * Date: August 18th, 2018
 * Programmer: Alexander Miller
 *
 * Alexander Miller - AMM1    - 1/17/2019 - IR-0047378 - Moving Sales Order Line process builder here to win opportunities automatically.
 * Alexander Miller - AMM2    - 5/15/2019 - W-000570   - Update to handle moving Opportunity statuses on line creation
 */
public class SalesOrderLinTriggerHandler {

    public List<rstk__soline__c > newList = new List<rstk__soline__c >();
    public List<rstk__soline__c > oldList = new List<rstk__soline__c >();
    public Map<Id, rstk__soline__c> newMap = new Map<Id, rstk__soline__c >();
    public Map<Id, rstk__soline__c > oldMap = new Map<Id, rstk__soline__c >();

    public Map<Id, rstk__sohdr__c> mapOfSalesOrders = new Map<Id, rstk__sohdr__c>();
    public Map<Id, Opportunity__c> mapOfOpportunities = new Map<Id, Opportunity__c>();

    public SalesOrderLinTriggerHandler(){}

    public SalesOrderLinTriggerHandler(rstk__soline__c [] newArray, rstk__soline__c [] oldArray, Map<Id, rstk__soline__c > newHashMap, Map<Id, rstk__soline__c > oldHashMap){
        newList = newArray;
        oldList = oldArray;
        newMap = newHashMap;
        oldMap = oldHashMap;
    }

    /**
    * refreshAllFieldsNeeded
    *
    * function which grabs every connected field possible at the very
    * beginning so minimal SOQL queries are used since RootStock
    * has recursive trigger logic built in. 
    */
    public List<rstk__soline__c> refreshAllFieldsNeeded(List<rstk__soline__c> newList)
    {
        return ([SELECT Id,
                 Name,
                 Product_Name__c,
                 rstk__soline_prod__c,
                 rstk__soline_prod__r.Name,
                 Configuration_Session_Name__c,
                 rstk__soline_confsess__c,
                 rstk__soline_confsess__r.Name,
                 Origin_Sales_Order_Line__c,
                 Origin_Sales_Order_Line__r.rstk__soline_confsess__c,
                 Origin_Sales_Order_Line__r.rstk__soline_confsess__r.Name,
                 rstk__formula_dimval1__c,
                 rstk__soline_sohdr__c,
                 // AMM1 
                 rstk__soline_firm__c,
                 rstk__soline_sohdr__r.Opportunity_custom__c,
                 rstk__soline_sohdr__r.Opportunity_custom__r.Status__c,
                 // AMM1
                 rstk__soline_sohdr__r.Dimension__c
                FROM rstk__soline__c
                WHERE Id IN :newList]);
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
        update mapOfSalesOrders.values();
        // AMM1
        update mapOfOpportunities.values();
        // AMM1
    }

    /**
    * salesOrderLineProductNamePasting
    *
    * Function which pastes the Product Name of the line
    * to the custom Product name field for reporting purposes.
    *
    * This should be done in a before context to help prevent collision
    * with RootStock trigger processes.
    *
    * @param newList - List of refreshed lines
    * @param newMap - Map of before context lines directly from the trigger
    */
    public void salesOrderLineProductNamePasting(List<rstk__soline__c> newList)
    {        
        for(rstk__soline__c tempLine : newList)
        {            
            if(tempLine.rstk__soline_prod__c != null && (tempLine.Product_Name__c == null || tempLine.Product_Name__c != tempLine.Product_Name_Formula__c))
            {
                tempLine.Product_Name__c = tempLine.Product_Name_Formula__c;
            }
        }
    }

    /**
    * salesOrderLineConfigurationSessionNamePasting
    *
    * Function which pastes the Configuration Session Name of the line
    * to the custom Configuration Session Name field for reporting and global searching purposes.
    *
    * This should be done in a before context to help prevent collision
    * with RootStock trigger processes.
    *
    * @param newList - List of refreshed lines
    * @param newMap - Map of before context lines directly from the trigger
    */
    public void salesOrderLineConfigurationSessionNamePasting(List<rstk__soline__c> newList)
    {
        for(rstk__soline__c tempLine : newList)
        {             
            // Exported directly from Configurator
            //if(tempLine.rstk__soline_confsess__c != null && tempLine.Configuration_Session_Name__c == null && tempLine.Configuration_Session_Name__c != tempLine.rstk__soline_confsess__r.Name)
            //{
            //    newMap.get(tempLine.Id).Configuration_Session_Name__c = tempLine.rstk__soline_confsess__r.Name;
            //}
            // Division Change Tool Exported
            //else if(tempLine.Origin_Sales_Order_Line__c != null && tempLine.Origin_Sales_Order_Line__r.rstk__soline_confsess__c != null && (tempLine.Configuration_Session_Name__c == null || tempLine.Configuration_Session_Name__c != tempLine.Origin_Sales_Order_Line__r.rstk__soline_confsess__r.Name))
            //{
            //    newMap.get(tempLine.Id).Configuration_Session_Name__c = tempLine.Origin_Sales_Order_Line__r.rstk__soline_confsess__r.Name;
            //}
            
            if(tempLine.Configuration_Session_Name_Formula__c != tempLine.Configuration_Session_Name__c)
            {
                tempLine.Configuration_Session_Name__c = tempLine.Configuration_Session_Name_Formula__c;
            }
        }
    }

    /**
    * salesOrderLineCopyDim1ToHeader
    *
    * Function which pastes the Dimension 1 value to the Header of the line
    * if either blank or doesn't match. Used for reporting purposes.
    *
    * This should be done in a before context to help prevent collision
    * with RootStock trigger processes.
    *
    * @param newList - List of refreshed lines
    */
    public void salesOrderLineCopyDim1ToHeader(List<rstk__soline__c> newList)
    {
        for(rstk__soline__c tempLine : newList)
        {
            if(tempLine.rstk__formula_dimval1__c != null && 
                (tempLine.rstk__soline_sohdr__r.Dimension__c == null || 
                String.isEmpty(tempLine.rstk__soline_sohdr__r.Dimension__c) || 
                tempLine.rstk__soline_sohdr__r.Dimension__c != tempLine.rstk__formula_dimval1__c))
            {
                mapOfSalesOrders.put(tempLine.rstk__soline_sohdr__c, new rstk__sohdr__c(Id = tempLine.rstk__soline_sohdr__c, Dimension__c = tempLine.rstk__formula_dimval1__c));
            }
        }
    }
    
    // AMM1
    /**
    * salesOrderLineCopyDim1ToHeader
    *
    * Function which pastes the Dimension 1 value to the Header of the line
    * if either blank or doesn't match. Used for reporting purposes.
    *
    * This should be done in a before context to help prevent collision
    * with RootStock trigger processes.
    *
    * @param newList - List of refreshed lines
    */
    public void winOpportunity(List<rstk__soline__c> newList)
    {
        for(rstk__soline__c tempLine : newList)
        {
            if(tempLine.rstk__soline_sohdr__c != null &&
               tempLine.rstk__soline_sohdr__r.Opportunity_custom__c != null &&
                tempLine.rstk__soline_firm__c == true &&
                tempLine.rstk__soline_sohdr__r.Opportunity_custom__r.Status__c != 'Won')
            {
                if(mapOfOpportunities.get(tempLine.rstk__soline_sohdr__r.Opportunity_custom__c) == null)
                {
                    Opportunity__c tempOpp = new Opportunity__c();
                    tempOpp.Id = tempLine.rstk__soline_sohdr__r.Opportunity_custom__c;
                    tempOpp.Status__c = 'Won';

                    mapOfOpportunities.put(tempOpp.Id,tempOpp);
                }
            }
        }
    }
    // AMM1

    // AMM2
    /**
    * salesOrderLinesCreatedOpportunity
    * 
    * Function which updates the parent Opportunity on the creation of a Sales
    * Order Line to keep the probability moving along. Probability and Opportunity-only 
    * fields are handled in Workflows instead of triggers.
    *
    * @param newList - List<rstk__soline__c>
    */
    public void salesOrderLinesCreatedOpportunity(List<rstk__soline__c> newList)
    {
        System.debug('in here');
        List<Id> listOfSalesOrderIds = new List<Id>();
        List<Id> listOfOpportunityIds = new List<Id>();
        Map<Id, Opportunity__c> mapOfSalesOrdersToOpportunities = new Map<Id, Opportunity__c>();

        for(rstk__soline__c soLine : newList)
        {
            listOfSalesOrderIds.add(soLine.rstk__soline_sohdr__c);
        }
        
        System.debug(listOfSalesOrderIds);

        List<rstk__sohdr__c> listOfSalesOderHeaders = ([SELECT Id, 
                                                            Opportunity_custom__c 
                                                        FROM rstk__sohdr__c 
                                                        WHERE Id IN :listOfSalesOrderIds]);

        for(rstk__sohdr__c tempSalesOrder : listOfSalesOderHeaders)
        {
            listOfOpportunityIds.add(tempSalesOrder.Opportunity_custom__c);
        }
        
        System.debug(listOfOpportunityIds);

        Map<Id, Opportunity__c> mapOfOpportunities =new Map<Id, Opportunity__c>([SELECT Id, 
                                                                                    Status__c 
                                                                                FROM Opportunity__c 
                                                                                WHERE Id IN :listOfOpportunityIds]);

        for(rstk__sohdr__c tempSalesOrder : listOfSalesOderHeaders )
        {
            if(mapOfOpportunities.get(tempSalesOrder.Opportunity_custom__c) != null)
            {
                mapOfSalesOrdersToOpportunities.put(tempSalesOrder.Id, mapOfOpportunities.get(tempSalesOrder.Opportunity_custom__c));
            }
        }
        
        System.debug(mapOfSalesOrdersToOpportunities);

        for(rstk__soline__c tempLine : newList)
        {            
            if(mapOfSalesOrdersToOpportunities.get(tempLine.rstk__soline_sohdr__c) != null &&
                mapOfSalesOrdersToOpportunities.get(tempLine.rstk__soline_sohdr__c).Status__c != 'Order Written Waiting Proofed')
            {
                System.debug('inside if statement');
                
                if(mapOfOpportunities.get(mapOfSalesOrdersToOpportunities.get(tempLine.rstk__soline_sohdr__c).Id) == null)
                {
                    Opportunity__c tempOpp = new Opportunity__c();
                    tempOpp.Id = tempLine.rstk__soline_sohdr__r.Opportunity_custom__c;
                    tempOpp.Status__c = 'Order Written Waiting Proofed';
    
                    mapOfOpportunities.put(tempOpp.Id,tempOpp);
                }
                else
                {
                    Opportunity__c tempOpp = mapOfOpportunities.get(mapOfSalesOrdersToOpportunities.get(tempLine.rstk__soline_sohdr__c).Id);
                    tempOpp.Status__c = 'Order Written Waiting Proofed';
    
                    mapOfOpportunities.put(tempOpp.Id,tempOpp);
                }
                
            }
        }
        
       update mapOfOpportunities.values();
    }
    // AMM2
}