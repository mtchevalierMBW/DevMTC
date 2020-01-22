/**
* TransitWorks (c) - 2018
*
* WorkOrderComponentTriggerHandler
* 
* Tested by: 
* Programmer: Alexander Miller
* Date: 2018-04-24
*
* Primary handler class for the Work Order Component trigger
*/
public class WorkOrderComponentTriggerHandler {

    public List<rstk__woorddmd__c> newList = new List<rstk__woorddmd__c>();
    public List<rstk__woorddmd__c> oldList = new List<rstk__woorddmd__c>();
    public Map<Id, rstk__woorddmd__c> newMap = new Map<Id, rstk__woorddmd__c>();
    public Map<Id, rstk__woorddmd__c> oldMap = new Map<Id, rstk__woorddmd__c>();

    List<rstk__woorddmd__c> refreshedList = new List<rstk__woorddmd__c>();

    Map<Id,rstk__woorddmd__c> mapOfComponentsForUpdate = new Map<Id,rstk__woorddmd__c>();

    public WorkOrderComponentTriggerHandler(){}

    public WorkOrderComponentTriggerHandler(rstk__woorddmd__c[] newArray, rstk__woorddmd__c[] oldArray, Map<Id, rstk__woorddmd__c> newHashMap, Map<Id, rstk__woorddmd__c> oldHashMap){
        newList = newArray;
        oldList = oldArray;
        newMap = newHashMap;
        oldMap = oldHashMap;
    }

    /*
    * refreshList
    *
    * Single query to handle all the desired fields
    */
    public void refreshList()
    {
        refreshedList = ([SELECT Id,
                            rstk__woorddmd_ordno__c,                            // Work Order
                            rstk__woorddmd_ordno__r.rstk__wocst_soline__c,      // Sales Order Line
                            rstk__woorddmd_compitem__c,                         // Inventory Item
                            rstk__woorddmd_oper__c,                             // Operation Number
                            Product_Master__c                                   // Product Master
                        FROM rstk__woorddmd__c
                        WHERE Id IN :newList]);
    }

    /** 
    * updateMaps
    *
    * Function which updates the maps updated throughout this class
    */
    public void updateMaps()
    {
        update mapOfComponentsForUpdate.values();
    }

    public void updateWorkOrderComponentsWithProducts()
    {
        // 1. get the Sales Order Line ids
        List<Id> listOfIds = getListOfSalesOrderLineIds(refreshedList);

        // 2. get the SOCONFIG lines with all the needed info
        List<rstk__soconfig__c> listOfCONFIGS = getSalesOrderLineSOCONFIGs(listOfIds);

        // 3. bucket the SOCONFIG lines by Sales Order Line
        Map<Id, List<rstk__soconfig__c>> mapOfLinesToConfigs = getBucketOfConfigsByLine(listOfCONFIGS);

        // 4. Assign the products to the appropriate component for the update
        mapOfComponentsForUpdate = assignComponentProducts(mapOfLinesToConfigs, refreshedList);
    }    

    /**
    * getListOfSalesOrderLineIds
    *
    * Funciton which gets all of the Sales Order Line Ids so later we can get the SOCONFIG lines
    */
    public List<Id> getListOfSalesOrderLineIds(List<rstk__woorddmd__c> listOfComponents)
    {
        List<Id> listOfIds = new List<Id>();

        for(rstk__woorddmd__c comp : listOfComponents)
        {
            listOfIds.add(comp.rstk__woorddmd_ordno__r.rstk__wocst_soline__c);
        }

        return listOfIds;
    }

    /**
    * getConfigurationSessionSelectionComponents
    *
    * Function which gets the components found by the configuration session which made this SOCONFIG
    */
    public List<rstk__soconfig__c> getSalesOrderLineSOCONFIGs(List<Id> listSalesOrderLineId)
    {
        return ([SELECT Id,                     
                    Product_Master__c,          // Product Master
                    rstk__soconfig_icitem__c,   // Inventory Item
                    rstk__soconfig_soline__c,   // Sales Order Line
                    rstk__soconfig_oper__c      // Operation Number
                FROM rstk__soconfig__c
                WHERE rstk__soconfig_soline__c IN :listSalesOrderLineId]);
    }

    /**
    * getBucketOfConfigsByLine
    *
    * Function which takes the SOCONFIG lines and buckets them by Sales Order Line Id
    */
    public Map<Id, List<rstk__soconfig__c>> getBucketOfConfigsByLine(List<rstk__soconfig__c> listOfCONFIGs)
    {
        Map<Id, List<rstk__soconfig__c>> mapOfBucketedItems = new Map<Id, List<rstk__soconfig__c>>();

        for(rstk__soconfig__c config : listOfCONFIGs)
        {
            if(mapOfBucketedItems.get(config.rstk__soconfig_soline__c) == null)
            {
                mapOfBucketedItems.put(config.rstk__soconfig_soline__c, new List<rstk__soconfig__c>());
            }

            mapOfBucketedItems.get(config.rstk__soconfig_soline__c).add(config);
        }

        return mapOfBucketedItems;
    }

    /**
    * assignComponentProducts
    *
    * function which looks at the SOCONFIG lines and matches them to the current work order components found on creation.
    * if they match up by Inventory item and operation number, then its a match and will assign the Product found on the SOCONFIG
    */
    public Map<Id, rstk__woorddmd__c> assignComponentProducts(Map<Id, List<rstk__soconfig__c>> mapOfSOCONFIG, List<rstk__woorddmd__c> listOfComponents)
    {
        Map<Id, rstk__woorddmd__c> mapOfComponentsReturn = new Map<Id, rstk__woorddmd__c>();

        for(Id configMapKey : mapOfSOCONFIG.KeySet())
        {
            for(rstk__soconfig__c config : mapOfSOCONFIG.get(configMapKey))
            {       
                for(rstk__woorddmd__c component : listOfComponents)
                {   
                    if(component.rstk__woorddmd_oper__c == config.rstk__soconfig_oper__c &&
                        component.rstk__woorddmd_compitem__c == config.rstk__soconfig_icitem__c)
                    {
                        if(mapOfComponentsReturn.get(component.Id) == null)
                        {
                            mapOfComponentsReturn.put(component.Id, new rstk__woorddmd__c());
                        }
                        component.Product_Master__c = config.Product_Master__c;
                        mapOfComponentsReturn.put(component.Id, component);
                    }
                }
            }   
        }

        return mapOfComponentsReturn;
    }
}