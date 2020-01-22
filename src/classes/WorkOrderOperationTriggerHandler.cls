/**
* TransitWorks (c) - 2018
*
* WorkOrderOperationTriggerHandler
* 
* Tested by: 
* Programmer: Alexander Miller
* Date: 2018-04-24
*
* Primary handler class for the Work Order Component trigger
*/
public class WorkOrderOperationTriggerHandler {

    public List<rstk__woordop__c> newList = new List<rstk__woordop__c>();
    public List<rstk__woordop__c> oldList = new List<rstk__woordop__c>();
    public Map<Id, rstk__woordop__c> newMap = new Map<Id, rstk__woordop__c>();
    public Map<Id, rstk__woordop__c> oldMap = new Map<Id, rstk__woordop__c>();

    List<rstk__woordop__c> refreshedList = new List<rstk__woordop__c>();

    Map<Id,rstk__woordop__c> mapOfComponentsForUpdate = new Map<Id,rstk__woordop__c>();

    public WorkOrderOperationTriggerHandler(){}

    public WorkOrderOperationTriggerHandler(rstk__woordop__c[] newArray, rstk__woordop__c[] oldArray, Map<Id, rstk__woordop__c> newHashMap, Map<Id, rstk__woordop__c> oldHashMap){
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
                            Name,
                            rstk__woordop_allowaccind__c,
                            rstk__woordop_setuplabgrd__c,
                            rstk__woordop_setuphrstd__c,
                            rstk__woordop_runtype_pl__c,
                            rstk__woordop_runlabgrd__c,
                            rstk__woordop_runhrstd__c,
                            rstk__woordop_machtype_pl__c,
                            rstk__woordop_machno__c,
                            rstk__woordop_machhrstd__c,
                            rstk__woordop_ordno__r.rstk__wocst_soline__c,
                            rstk__woordop_oper__c,
                            rstk__woordop_setuptype_pl__c,
                            Product_Master__c                                   // Product Master
                        FROM rstk__woordop__c
                        WHERE Id IN :newList]);
    }

    /** 
    * updateMaps
    *
    * Function which updates the maps updated throughout this class
    */
    public void updateMaps()
    {
        // You have to use an async process on single records to make this work
        Database.executeBatch(new batchWorkOrderOperation(mapOfComponentsForUpdate.values()), 1);
    }

    public void updateWorkOrderComponentsWithProducts()
    {
        // 1. get the Sales Order Line ids
        List<Id> listOfIds = getListOfSalesOrderLineIds(refreshedList);

        // 2. get the SOCONFIG lines with all the needed info
        List<rstk__sortoper__c> listOfCONFIGS = getSalesOrderLineSOCONFIGs(listOfIds);

        // 3. bucket the SOCONFIG lines by Sales Order Line
        Map<Id, List<rstk__sortoper__c>> mapOfLinesToConfigs = getBucketOfConfigsByLine(listOfCONFIGS);

        // 4. Assign the products to the appropriate component for the update
        mapOfComponentsForUpdate = assignComponentProducts(mapOfLinesToConfigs, refreshedList);
    }    

    /**
    * getListOfSalesOrderLineIds
    *
    * Funciton which gets all of the Sales Order Line Ids so later we can get the SOCONFIG lines
    */
    public List<Id> getListOfSalesOrderLineIds(List<rstk__woordop__c> listOfComponents)
    {
        List<Id> listOfIds = new List<Id>();

        for(rstk__woordop__c comp : listOfComponents)
        {
            listOfIds.add(comp.rstk__woordop_ordno__r.rstk__wocst_soline__c);
        }

        return listOfIds;
    }

    /**
    * getConfigurationSessionSelectionComponents
    *
    * Function which gets the components found by the configuration session which made this SOCONFIG
    */
    public List<rstk__sortoper__c> getSalesOrderLineSOCONFIGs(List<Id> listSalesOrderLineId)
    {
        return ([SELECT Id,                     
                    Product_Master__c,          // Product Master
                    rstk__sortoper_soline__c,   // Sales Order Line
                    rstk__sortoper_oper__c      // Operation Number
                FROM rstk__sortoper__c
                WHERE rstk__sortoper_soline__c IN :listSalesOrderLineId]);
    }

    /**
    * getBucketOfConfigsByLine
    *
    * Function which takes the SOCONFIG lines and buckets them by Sales Order Line Id
    */
    public Map<Id, List<rstk__sortoper__c>> getBucketOfConfigsByLine(List<rstk__sortoper__c> listOfCONFIGs)
    {
        Map<Id, List<rstk__sortoper__c>> mapOfBucketedItems = new Map<Id, List<rstk__sortoper__c>>();

        for(rstk__sortoper__c config : listOfCONFIGs)
        {
            if(mapOfBucketedItems.get(config.rstk__sortoper_soline__c) == null)
            {
                mapOfBucketedItems.put(config.rstk__sortoper_soline__c, new List<rstk__sortoper__c>());
            }

            mapOfBucketedItems.get(config.rstk__sortoper_soline__c).add(config);
        }

        return mapOfBucketedItems;
    }

    /**
    * assignComponentProducts
    *
    * function which looks at the SOCONFIG lines and matches them to the current work order components found on creation.
    * if they match up by Inventory item and operation number, then its a match and will assign the Product found on the SOCONFIG
    */
    public Map<Id, rstk__woordop__c> assignComponentProducts(Map<Id, List<rstk__sortoper__c>> mapOfSOCONFIG, List<rstk__woordop__c> listOfComponents)
    {
        Map<Id, rstk__woordop__c> mapOfComponentsReturn = new Map<Id, rstk__woordop__c>();

        for(Id configMapKey : mapOfSOCONFIG.KeySet())
        {
            for(rstk__sortoper__c config : mapOfSOCONFIG.get(configMapKey))
            {       
                for(rstk__woordop__c component : listOfComponents)
                {   
                    if(component.rstk__woordop_oper__c == config.rstk__sortoper_oper__c)
                    {
                        if(mapOfComponentsReturn.get(component.Id) == null)
                        {
                            mapOfComponentsReturn.put(component.Id, new rstk__woordop__c());
                        }

                        component.Product_Master__c = config.Product_Master__c;
                        mapOfComponentsReturn.put(component.Id, component);
                        System.debug(mapOfComponentsReturn.get(component.Id));
                    }
                }
            }   
        }

        return mapOfComponentsReturn;
    }
}