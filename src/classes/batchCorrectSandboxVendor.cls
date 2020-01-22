/**
* MobilityWorks (c) - 2017
*
* batchCorrectSandboxVendor 
* Tested by: batchCorrectSandboxVendorTest 
* Date: 10/12/2017
* Programmer: Alexander Miller
*
* Description: Post refresh, this class must be run in order to correct the sandbox data
*              To prevent issues with production
*/
global class batchCorrectSandboxVendor implements Database.Batchable<sObject>, Schedulable, Database.Stateful{

    public batchCorrectSandboxVendor(){}

    global void execute(SchedulableContext SC) {
        batchCorrectSandboxVendor thisBatch = new batchCorrectSandboxVendor();
        database.executeBatch(thisBatch); 
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {  
        String query = 'SELECT Id, rstk__povendpoaddr_contactemail__c FROM rstk__povendpoaddr__c WHERE rstk__povendpoaddr_contactemail__c != null';

        if(Test.isRunningTest())
        {
             query += ' LIMIT 1';
        }

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<rstk__povendpoaddr__c> listTemp) {
        
        if(runningInASandbox())
        {
            for(rstk__povendpoaddr__c tempVendor : listTemp)
            {
                String originalEmail = tempVendor.rstk__povendpoaddr_contactemail__c;
                String newEmail = originalEmail.substring(0, originalEmail.IndexOf('@'));
                newEmail = newEmail + '@example.com';
                tempVendor.rstk__povendpoaddr_contactemail__c = newEmail;
            }

            update listTemp;
        }
    }   
     
    global void finish(Database.BatchableContext BC) {
        if(!Test.isRunningTest())
        {
        	batchCorrectSandboxVendorContact thisBatch = new batchCorrectSandboxVendorContact();
        	database.executeBatch(thisBatch);
        }
    }

    public static Boolean runningInASandbox() {
        return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }
}