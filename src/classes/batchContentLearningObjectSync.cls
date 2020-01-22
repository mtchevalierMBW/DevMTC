/**
 * WMK, LLC (c) - 2018 
 *
 * batchContentLearningObjectSync
 * 
 * Created By:   Alexander Miller
 * Created Date: 12/5/2018 
 * Tested By:    batchContentLearningObjectSyncTest
 * Work Item:    W-000421
 *
 * Modified By         Alias       Work Item       Date      Reason
 * -----------------------------------------------------------------
 */
global class batchContentLearningObjectSync implements Database.Batchable<Schema.sObjectType>, Schedulable, Database.Stateful {

    global void execute(SchedulableContext SC) 
    {        
        batchContentLearningObjectSync thisBatch = new batchContentLearningObjectSync();
        database.executeBatch(thisBatch, 1); 
    }

    global Iterable<Schema.sObjectType> start(Database.BatchableContext BC){

        if(Test.isRunningTest())
        {
            List<Schema.sObjectType> tempList = new List<Schema.sObjectType>();
            tempList.add(Schema.getGlobalDescribe().get('Account'));
            return tempList;
		}
        
        return Schema.getGlobalDescribe().values();
    }

    global void execute(Database.BatchableContext BC, List<Schema.sObjectType> objectList)
    {
        // 1. List to add on, if any
        List<Content_Learning_Objects__c> listToAdd = new List<Content_Learning_Objects__c>();

        // 2. Get the current custom setting values
        Content_Learning_Objects__c tempCustomSetting = Content_Learning_Objects__c.getInstance();
        Map<String, Content_Learning_Objects__c> mapOfObjects = Content_Learning_Objects__c.getall();

        // 3. If it exists in the list, then ignore. Else, add to list to add on
        for(Schema.SObjectType o : objectList)
        {
            Schema.DescribeSObjectResult objResult = o.getDescribe();

            if(mapOfObjects.get(objResult.getLabel()) == null)
            {
                listToAdd.add(new Content_Learning_Objects__c(Name = objResult.getLabel(), API_Name__c = objResult.getName(), Enabled__c = false ));
            }
        }

        insert listToAdd; 
    }

    global void finish(Database.BatchableContext BC) {}
}