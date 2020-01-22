/**
 * BatchLightningNoteMigration
 * 
 * Created By: Alexander Miller
 * Created Date: 10/2/2018 
 * Tested By: BatchLightningNoteMigrationTest
 * Work Item: W-000413
 * 
 * Description:
 * 
 * Batch class which takes all the Notes of a given period and object
 * and copies them to the new Lightning compatible objects
 *
 * 1. You must provide the API name of the object. Account --> Account, Chassis Master --> Chassis_Master__c, etc
 * 2. You must provide a start date. This is the date the batch will look back to and no further
 * 3. You must provide the batch size for the scheduled class. Some objects may allow more than others
 *
 * - Only 100,000 documents can be made/modified in a 24 hour period. The class won't let a single  batch go over that 
 *     amount but nothing prevents a collection of them hitting that limit. 
 * - SOQL will prevent you from querying more than 50,000 rows in a single calls anyways. 
 * - This batch is set to 20,000 Notes in a single call for maximized success
 * - NOTE: SANDBOX ONLY ALLOWS 2,500 IN A 24 HOUR PERIOD
 *
 * To get queries of the current counts, use this:
 *
 * SELECT COUNT() FROM Note WHERE Parent.Type = 'Account' AND CreatedDate >= 2017-01-01T00:00:00Z
 *
 * Example Call (unscheduled):
 *
 * BatchLightningNoteMigration thisBatch = new BatchLightningNoteMigration('Chassis_Master__c', DateTime.newInstanceGMT(2018, 9, 1));
 * database.executeBatch(thisBatch, 1); 
 * 
 * Example Call (scheduled):
 * 
 * BatchLightningNoteMigration sh1 = new BatchLightningNoteMigration('Account', DateTime.newInstanceGMT(2018, 9, 1));
 * String sch = '0 0 23 * * ?'; 
 * System.schedule('BLAM Account 2018-9-1', sch, sh1);
 *
 * To view progress:
 *
 * SELECT COUNT() FROM ContentNote WHERE CreatedDate = TODAY
 */
global class BatchLightningNoteMigration implements Database.Batchable<sObject>, Schedulable, Database.Stateful {

    global String objectName;
    global DateTime startDate;

    public BatchLightningNoteMigration(String objectAPIName, DateTime startDate)
    {
        this.objectName = objectAPIName;
        this.startDate = startDate;
    }

	global void execute(SchedulableContext SC) 
    {        
        BatchLightningNoteMigration thisBatch = new BatchLightningNoteMigration(this.objectName, this.startDate);
        database.executeBatch(thisBatch, 1); 
    }

 	global Database.QueryLocator start(Database.BatchableContext BC) 
    {
        // Go-Live Query
        String query = 'SELECT Id, Title, Body, ParentId FROM Note WHERE Parent.Type = \'' + objectName +'\' AND CreatedDate >= ' + startDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + ' LIMIT 100000';

        System.debug(objectName);
        System.debug(startDate);

        // Dev Query
        //String query = 'SELECT Id, Title, Body, ParentId FROM Note WHERE Parent.Type = \'' + objectName +'\' AND CreatedDate >= ' + startDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + ' LIMIT 1';  
        
        if(Test.IsRunningTest())
        {
            query = 'SELECT Id, Title, Body, ParentId FROM Note WHERE Parent.Type = \'' + objectName +'\' AND CreatedDate >= ' + startDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + ' LIMIT 1';  
        }
        
        return Database.getQueryLocator(query);
    }

	global void execute(Database.BatchableContext BC, List<Note> attachmentList)
    {
        LightningFileUtility tempUtility = new LightningFileUtility();
        
        for(Note tempAttachment : attachmentList)
        {
            tempUtility.addFile(tempAttachment.Title, tempAttachment.Body, tempAttachment.ParentId, true, null);
        }
        
        tempUtility.commitFiles();
    }

	global void finish(Database.BatchableContext BC) {}
}