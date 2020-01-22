/**
* MobilityWorks (c) - 2017
*
* batchCorrectSandboxVendorContact 
* Tested by: batchCorrectSandboxVendorContactTest
* Date: 10/12/2017
* Programmer: Alexander Miller
*
* Description: Post refresh, this class must be run in order to correct the sandbox data
*              To prevent issues with production
*/
global class batchCorrectSandboxVendorContact implements Database.Batchable<sObject>, Schedulable, Database.Stateful{

    public batchCorrectSandboxVendorContact(){}

    global void execute(SchedulableContext SC) {
        batchCorrectSandboxVendorContact thisBatch = new batchCorrectSandboxVendorContact();
        database.executeBatch(thisBatch); 
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {  
        String query = 'SELECT Id, rstk__pocontact_email__c FROM rstk__pocontact__c WHERE rstk__pocontact_email__c != null';
        
        if(Test.isRunningTest())
        {
        	query += ' LIMIT 1';
        }
        
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<rstk__pocontact__c> listTemp) {
        
        if(runningInASandbox())
        {
            for(rstk__pocontact__c tempVendor : listTemp)
            {
                String originalEmail = tempVendor.rstk__pocontact_email__c;
                String newEmail = originalEmail.substring(0, originalEmail.IndexOf('@'));
                newEmail = newEmail + '@example.com';
                tempVendor.rstk__pocontact_email__c = newEmail;
            }

            update listTemp;
        }
    }   
     
    global void finish(Database.BatchableContext BC) {
        if(!Test.isRunningTest())
        {
			batchCorrectSandboxCustomerContact thisBatch = new batchCorrectSandboxCustomerContact();
        	database.executeBatch(thisBatch); 
        }
    }

    public static Boolean runningInASandbox() {
        return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }
}