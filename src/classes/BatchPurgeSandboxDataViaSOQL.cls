/**
 * BatchPurgeSandboxDataViaSOQL
 * Tested by: BatchPurgeSandboxDataViaSOQL_TEST
 * Date: 2018-12-31
 * Programmer: Bryan Leaman
 * 
 * Run it now:
Database.executeBatch(new BatchPurgeSandboxDataViaSOQL('select Id from dealer__Vehicle_Equipment__c', true));
Database.executeBatch(new BatchPurgeSandboxDataViaSOQL('select Id from dealer__Service_Vehicle_Equipment__c', true));
Database.executeBatch(new BatchPurgeSandboxDataViaSOQL('select Id from c2g__ReportingBalance__c', true));


 */
 global class BatchPurgeSandboxDataViaSOQL implements Database.Batchable<sObject>, Database.Stateful {

    global final String query;
    global boolean doUpdate;

    // BatchDeleteVehicleEquipment constructor - generate query string & initialize
    global BatchPurgeSandboxDataViaSOQL(String soql, boolean doUpd) {
        doUpdate = doUpd;
        query = soql;
    }


    // start - query the database
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Organization org = [select isSandbox from Organization limit 1];
        System.assert(org.isSandbox || Test.isRunningTest(), 'Not a sandbox org or Test run!!!');
		System.debug(query);
        return Database.getQueryLocator(query);
    }

    // execute for a batch of records
    global void execute(Database.BatchableContext bc, List<sObject> scope) {
        List<SObject> objs = (List<SObject>) scope;
        System.debug('Record count: ' + String.valueOf(objs.size()));

        // Delete
        if (doUpdate) Database.delete(objs, false);

    }
    
    
    // finish - send results via email
    global void finish(Database.BatchableContext bc) {
    }


}