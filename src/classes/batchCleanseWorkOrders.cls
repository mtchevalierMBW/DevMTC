/**
* MobilityWorks (c) - 2017
*
* batchTemplate
* Tested by: 
* Date: 
* Programmer: 
*
* To call it:
*
* String[] listOfWorkOrders = new String[]{'aGy500000004DS6'};
* Database.executeBatch(new batchCleanseWorkOrders(listOfWorkOrders), 1);
*/
global class batchCleanseWorkOrders implements Database.Batchable<sObject>, Database.Stateful{

    // stateful global variable that will survive execution contexts
    global List<String> listOfIds;

    global Map<Id, rstk__woorddmd__c> workOrderComponentsToUpdate;

    public batchCleanseWorkOrders(){}

    public batchCleanseWorkOrders(List<String> listOfWorkOrderIds)
    {
        this.listOfIds = listOfWorkOrderIds;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {  

        String query = 'SELECT Id, ' +
                            'rstk__wocst_soline__c,' +
                            'rstk__wocst_soline__r.rstk__soline_confsess__c,' +
                            '(SELECT Id, ' +
                            'rstk__woorddmd_oper__c,' +
                            'rstk__woorddmd_compitem__c ' +
                            'FROM rstk__woorddmds__r) ' + 
                        'FROM rstk__wocst__c ' +
                        'WHERE Id IN :listOfIds';

        System.debug(query);

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<rstk__wocst__c> listTemp) 
    {
        // 1. Query for all configuration selections within the session
        List<Id> listOfConfigIds = new List<Id>();

        for(rstk__wocst__c tempWork : listTemp)
        {
            listOfConfigIds.add(tempWork.rstk__wocst_soline__r.rstk__soline_confsess__c);
        }

        List<rstk__confdsel__c> listOfSessionSelectionAndComponents = getConfigurationSessionSelections(listOfConfigIds);

        // 2. Query the current setup for the same selection, if found
        List<Id> listOfSelectionIds = new List<Id>();

        for(rstk__confdsel__c tempConfigSess : listOfSessionSelectionAndComponents)
        {
            listOfSelectionIds.add(tempConfigSess.rstk__confdsel_confsel__c);
        }

        List<rstk__confsel__c> listOfConfigSetup = getConfigurationSelections(listOfSelectionIds);

        // 3. Correct all work order components from the orignial query, if need be
        workOrderComponentsToUpdate = getCorrectedComponentList(listTemp, listOfSessionSelectionAndComponents, listOfConfigSetup);

        // 4. Update components
        // for(rstk__woorddmd__c temp : workOrderComponentsToUpdate.values())
        // {
        //     System.debug(temp);
        // }
    }   

    /**
    * getCorrectedComponentList
    *
    * Function which looks at the current work order component, configurator session selections,
    * and the configurator current setup. 
    *
    * - If the work order component inventory exists in the configurator session selections, check the configurator setup for the same selection. 
    * - If the configurator setup contains the selection, check for the exact same inventory item. 
    * - If the component has a different operation sequence number, then update it to the configurator setup. 
    * - - Else, leave it alone.
    */
    public Map<Id, rstk__woorddmd__c> getCorrectedComponentList(List<rstk__wocst__c> workOrderAndComponents, List<rstk__confdsel__c> sessionSelections, List<rstk__confsel__c> configSetup)
    {
        Map<Id, rstk__woorddmd__c> mapOfComponents = new Map<Id, rstk__woorddmd__c>();

        // Work Order
        for(rstk__wocst__c tempOrder : workOrderAndComponents)
        {
            // Work Order Component
            for(rstk__woorddmd__c tempComponent : tempOrder.rstk__woorddmds__r)
            {
                // Session Selection
                for(rstk__confdsel__c sessionSelection : sessionSelections)
                {
                    // Session Selection Component
                    for(rstk__confdcomp__c tempSessionComponent : sessionSelection.rstk__confdcomps__r)
                    {
                        if(tempSessionComponent.rstk__confdcomp_icitem__c == tempComponent.rstk__woorddmd_compitem__c)
                        {
                            // Setup Selection
                            for(rstk__confsel__c tempSetupSelection : configSetup)
                            {
                                // Setup Selection Component
                                for(rstk__confcomp__c tempSetup : tempSetupSelection.rstk__confcomps__r)
                                {
                                    // Same inventory item but the sequence is different
                                    if(tempSetup.rstk__confcomp_icitem__c == tempComponent.rstk__woorddmd_compitem__c &&
                                       tempSetup.rstk__confcomp_labseq__c !=  tempComponent.rstk__woorddmd_oper__c)
                                       {

                                           if(mapOfComponents.get(tempComponent.Id) == null)
                                           {
                                               mapOfComponents.put(tempComponent.Id, new rstk__woorddmd__c());
                                           }

                                           tempComponent.rstk__woorddmd_oper__c = tempSetup.rstk__confcomp_labseq__c;
                                           mapOfComponents.put(tempComponent.Id, tempComponent);
                                       }
                                }
                            }
                        }
                    }
                }
            }
        }

        return mapOfComponents;
    }

    /**
    * getConfigurationSelections
    *
    * Function which gets the current setup as the base rules for what should be happening right now
    */
    public List<rstk__confsel__c> getConfigurationSelections(List<Id> listOfConfigSelectionIds)
    {
        return ([SELECT Id,
                    (SELECT Id,
                        rstk__confcomp_icitem__c,
                        rstk__confcomp_labseq__c,
                        rstk__confcomp_confsel__c
                    FROM rstk__confcomps__r)
                FROM rstk__confsel__c 
                WHERE Id IN :listOfConfigSelectionIds]);
    }

    /* 
    * getConfigurationSessionSelections
    *
    * Function which gets the configuration session selections and all children components (inv, prod, labor)
    */
    public List<rstk__confdsel__c> getConfigurationSessionSelections(List<Id> listOfConfigSessionIds)
    {
        return ([SELECT Id,
                    rstk__confdsel_confsel__c,
                    (SELECT Id,
                        rstk__confdcomp_confdsel__c,
                        rstk__confdcomp_icitem__c,
                        rstk__confdcomp_labseq__c
                    FROM rstk__confdcomps__r)
                FROM rstk__confdsel__c
                WHERE rstk__confdsel_confsess__c IN :listOfConfigSessionIds]);
    }
     
    global void finish(Database.BatchableContext BC) 
    {
        Database.executeBatch(new batchCleanseWorkOrderLineUpdate(workOrderComponentsToUpdate.values()), 1);
    }
}