/**
* TransitWorks (c) - 2018
*
* SOCONFIGTriggerHandler
* 
* Tested by: 
* Programmer: Alexander Miller
* Date: 2018-04-23
*
* Primary handler class for the SOCONFIG trigger
*
* Modified By           Alias         Work Item       Date          Reason
* --------------------------------------------------------------------------------------------------
* Alexander Miller      AMM1          W-000462      10/21/2018     Update to handle non-selective query on Engineering BOMs
*/
public class SOCONFIGTriggerHandler {

    public List<rstk__soconfig__c> newList = new List<rstk__soconfig__c>();
    public List<rstk__soconfig__c> oldList = new List<rstk__soconfig__c>();
    public Map<Id, rstk__soconfig__c> newMap = new Map<Id, rstk__soconfig__c>();
    public Map<Id, rstk__soconfig__c> oldMap = new Map<Id, rstk__soconfig__c>();

    List<rstk__soconfig__c> refreshedList = new List<rstk__soconfig__c>();

    List<rstk__soconfig__c> listOfProcessedConfigs = new List<rstk__soconfig__c>();
    
    // static flag to make this run only once
    public static Boolean flag = true; 

    public SOCONFIGTriggerHandler(){}

    public SOCONFIGTriggerHandler(rstk__soconfig__c[] newArray, rstk__soconfig__c[] oldArray, Map<Id, rstk__soconfig__c> newHashMap, Map<Id, rstk__soconfig__c> oldHashMap){
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
                            Product_Master__c,
                            rstk__soconfig_icitem__c,
                            rstk__soconfig_oper__c,
                            rstk__soconfig_soline__c,
                            rstk__soconfig_soline__r.rstk__soline_confsess__c,
                            rstk__soconfig_soline__r.Origin_Sales_Order_Line__c,
                            rstk__soconfig_soline__r.Origin_Sales_Order_Line__r.rstk__soline_confsess__c
                        FROM rstk__soconfig__c
                        WHERE Id IN :newList AND
                        Product_Master__c = null]);
    }

    /** 
    * updateMaps
    *
    * Function which updates the maps updated throughout this class
    */
    public void updateMaps()
    {
        for(rstk__soconfig__c temp : listOfProcessedConfigs)
        {
            System.debug(temp);
        }

        update listOfProcessedConfigs;
        //Database.executeBatch(new batchSOCONFIG(listOfProcessedConfigs), 1);
    }

    /**
    * updateProductMasters 
    *
    * Function which takes the Configuration Session's Product mapping, if any 
    * and copies it to the newly made SOCONFIG to be translated later
    */
    public void updateProductMasters()
    {
        // get Configuration Sessions Selection Components
        List<Id> idsToProcess = getConfigurationSessionIds(refreshedList);
        System.debug(idsToProcess);

        List<rstk__confdcomp__c> listOfProducts = getConfigurationSessionSelectionComponents(idsToProcess);
        System.debug(listOfProducts);

        Map<Id, List<rstk__confdcomp__c>> mapOfSelectionProducts = getInventoryAndProductsBrokenDownBySelection(listOfProducts);
    
        // Assign found Products
        listOfProcessedConfigs = assignProductsToConfigs(refreshedList, mapOfSelectionProducts);
        System.debug(listOfProcessedConfigs);

        for(rstk__soconfig__c config : listOfProcessedConfigs)
        {
            System.debug(config.Product_Master__c);
        }
    }

    /**
    * assignProductsToConfigs
    *
    * Function which takes the assigned Products, if any, and associates them with the configs
    */
    public List<rstk__soconfig__c> assignProductsToConfigs(List<rstk__soconfig__c> listOfConsigs, Map<Id, List<rstk__confdcomp__c>> mapOfSelectionComponents)
    {
        for(rstk__soconfig__c config : listOfConsigs)
        {
            Decimal sequenceNumber = config.rstk__soconfig_oper__c;

            Id inventoryItem = config.rstk__soconfig_icitem__c;

            for(Id selectionId : mapOfSelectionComponents.KeySet())
            {
                for(rstk__confdcomp__c component : mapOfSelectionComponents.get(selectionId))
                {
                    if(component.rstk__confdcomp_labseq__c == sequenceNumber &&
                        component.rstk__confdcomp_icitem__c == inventoryItem)
                    {
                        config.Product_Master__c = getProductMasterFromSelection(mapOfSelectionComponents.get(selectionId));
                    }
                }
            }
        }

        return  listOfConsigs;
    }

    public Id getProductMasterFromSelection(List<rstk__confdcomp__c> listOfSelection)
    {
        for(rstk__confdcomp__c component : listOfSelection)
        {
            if(component.rstk__confdcomp_itemtype__c == 'Product')
            {
                return component.rstk__confdcomp_soprod__c;
            }
        }

        return null;
    }

    /**
    * getConfigurationSessionIds
    *
    * Function which gets the configuration sessions
    */
    public List<Id> getConfigurationSessionIds(List<rstk__soconfig__c> listOfConfigs)
    {
        List<Id> listOfConfigurationSessions = new List<Id>();

        for(rstk__soconfig__c temp : listOfConfigs)
        {
            if(temp.rstk__soconfig_soline__r.Origin_Sales_Order_Line__c != null)
            {
                listOfConfigurationSessions.add(temp.rstk__soconfig_soline__r.Origin_Sales_Order_Line__r.rstk__soline_confsess__c);
            }
            // AMM1
            //else
            else if(temp.rstk__soconfig_soline__r.rstk__soline_confsess__c != null)
            // AMM1
            {   
                listOfConfigurationSessions.add(temp.rstk__soconfig_soline__r.rstk__soline_confsess__c);
            }
        }

        return listOfConfigurationSessions;
    }

    public Map<Id, List<rstk__confdcomp__c>> getInventoryAndProductsBrokenDownBySelection(List<rstk__confdcomp__c> selectionComponents)
    {
        Map<Id, List<rstk__confdcomp__c>> mapOfComponents = new Map<Id, List<rstk__confdcomp__c>>(); 

        for(rstk__confdcomp__c comp : selectionComponents)
        {
            if(mapOfComponents.get(comp.rstk__confdcomp_confdsel__c) == null)
            {
                mapOfComponents.put(comp.rstk__confdcomp_confdsel__c, new List<rstk__confdcomp__c>());
            }

            mapOfComponents.get(comp.rstk__confdcomp_confdsel__c).add(comp);
        }

        return mapOfComponents;
    }

    /**
    * getConfigurationSessionSelectionComponents
    *
    * Function which gets the components found by the configuration session which made this SOCONFIG
    */
    public List<rstk__confdcomp__c> getConfigurationSessionSelectionComponents(List<Id> listOfConfigurationIds)
    {
        System.debug(listOfConfigurationIds);
        // AMM1
        //if(Test.isRunningTest())
        if(Test.isRunningTest() || listOfConfigurationIds == null || listOfConfigurationIds.size() == 0)
        // AMM1
        	return new List<rstk__confdcomp__c>();
        else{

        	return ([SELECT Id,
                        rstk__confdcomp_seq__c,                 // Sequence Number
                        rstk__confdcomp_labseq__c,              // Labor Sequence Number
                        rstk__confdcomp_soprod__c,              // Product Master
                        rstk__confdcomp_icitem__c,              // Inventory Item
                        rstk__confdcomp_itemtype__c,            // Item Type
                        rstk__confdcomp_confdsel__c             // Selection
                    FROM rstk__confdcomp__c 
                    WHERE rstk__confdcomp_confsess__c IN :listOfConfigurationIds AND
                        rstk__confdcomp_itemtype__c IN ('Product', 'Inventory')]);
         }
    }
}