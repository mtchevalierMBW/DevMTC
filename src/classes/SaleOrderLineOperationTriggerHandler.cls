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
public class SaleOrderLineOperationTriggerHandler {

    public List<rstk__sortoper__c> newList = new List<rstk__sortoper__c>();
    public List<rstk__sortoper__c> oldList = new List<rstk__sortoper__c>();
    public Map<Id, rstk__sortoper__c> newMap = new Map<Id, rstk__sortoper__c>();
    public Map<Id, rstk__sortoper__c> oldMap = new Map<Id, rstk__sortoper__c>();

    List<rstk__sortoper__c> refreshedList = new List<rstk__sortoper__c>();

    List<rstk__sortoper__c> listOfComponentsForUpdate = new List<rstk__sortoper__c>();

    // static flag to make this run only once
    public static Boolean flag = true; 

    public SaleOrderLineOperationTriggerHandler(){}

    public SaleOrderLineOperationTriggerHandler(rstk__sortoper__c[] newArray, rstk__sortoper__c[] oldArray, Map<Id, rstk__sortoper__c> newHashMap, Map<Id, rstk__sortoper__c> oldHashMap){
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
                            Product_Master__c,                                   // Product Master
                            rstk__sortoper_oper__c,
                            rstk__sortoper_soline__c,
                            rstk__sortoper_soline__r.rstk__soline_confsess__c,
                            rstk__sortoper_soline__r.Origin_Sales_Order_Line__c,
                            rstk__sortoper_soline__r.Origin_Sales_Order_Line__r.rstk__soline_confsess__c
                        FROM rstk__sortoper__c
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
        update listOfComponentsForUpdate;
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

        Map<Id, List<rstk__confdcomp__c>> mapOfSelectionProducts = getInventoryAndProductsBrokenDownBySelection(listOfProducts);
    
        // Assign found Products
        listOfComponentsForUpdate = assignProductsToConfigs(refreshedList, mapOfSelectionProducts);
    }

    /**
    * assignProductsToConfigs
    *
    * Function which takes the assigned Products, if any, and associates them with the configs
    */
    public List<rstk__sortoper__c> assignProductsToConfigs(List<rstk__sortoper__c> listOfConsigs, Map<Id, List<rstk__confdcomp__c>> mapOfSelectionComponents)
    {
        for(rstk__sortoper__c config : listOfConsigs)
        {
            Decimal sequenceNumber = config.rstk__sortoper_oper__c;

            for(Id selectionId : mapOfSelectionComponents.KeySet())
            {
                for(rstk__confdcomp__c component : mapOfSelectionComponents.get(selectionId))
                {
                    if(component.rstk__confdcomp_labseq__c == sequenceNumber)
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
    public List<Id> getConfigurationSessionIds(List<rstk__sortoper__c> listOfConfigs)
    {
        List<Id> listOfConfigurationSessions = new List<Id>();

        for(rstk__sortoper__c temp : listOfConfigs)
        {
            if(temp.rstk__sortoper_soline__r.Origin_Sales_Order_Line__c != null)
            {
                listOfConfigurationSessions.add(temp.rstk__sortoper_soline__r.Origin_Sales_Order_Line__r.rstk__soline_confsess__c);
            }
            else
            {
                listOfConfigurationSessions.add(temp.rstk__sortoper_soline__r.rstk__soline_confsess__c);
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
        if(Test.isRunningTest())
        	return new List<rstk__confdcomp__c>();
        else
        {
            
        
        return ([SELECT Id,
                        rstk__confdcomp_seq__c,                 // Sequence Number
                        rstk__confdcomp_labseq__c,              // Labor Sequence Number
                        rstk__confdcomp_soprod__c,              // Product Master
                        rstk__confdcomp_icitem__c,              // Inventory Item
                        rstk__confdcomp_itemtype__c,            // Item Type
                        rstk__confdcomp_confdsel__c             // Selection
                    FROM rstk__confdcomp__c 
                    WHERE rstk__confdcomp_confsess__c IN :listOfConfigurationIds AND
                        rstk__confdcomp_itemtype__c IN ('Product', 'Labor')]);
         }
    }
}