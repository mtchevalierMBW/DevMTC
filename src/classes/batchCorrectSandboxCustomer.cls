/**
* MobilityWorks (c) - 2017
*
* batchCorrectSandboxCustomerRecords
* Tested by: 
* Date: 10/12/2017
* Programmer: Alexander Miller
*
* Description: Post refresh, this class must be run in order to correct the sandbox data
*              To prevent issues with production
*/
global class batchCorrectSandboxCustomer implements Database.Batchable<sObject>, Schedulable, Database.Stateful{

    public batchCorrectSandboxCustomer (){}

    global void execute(SchedulableContext SC) {
        batchCorrectSandboxCustomer thisBatch = new batchCorrectSandboxCustomer();
        database.executeBatch(thisBatch); 
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {  
        
        if(runningInASandbox())
        {
            turnOffSystemDefaults();
        }

        String query = 'SELECT Id, rstk__socaddr_email__c FROM rstk__socaddr__c WHERE rstk__socaddr_email__c  != null';
        
        if(Test.isRunningTest())
        {
            query += ' LIMIT 1';
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<rstk__socaddr__c> listTemp) {
        
        if(runningInASandbox())
        {
            for(rstk__socaddr__c tempCustomer : listTemp){
                String originalEmail = tempCustomer.rstk__socaddr_email__c;
                String newEmail = originalEmail.substring(0, originalEmail.IndexOf('@'));
                newEmail = newEmail + '@example.com';
                tempCustomer.rstk__socaddr_email__c = newEmail;
            }
        
        update listTemp;
        
        }
    }   
     
    global void finish(Database.BatchableContext BC) {
        if(!Test.isRunningTest())
        {
        	batchCorrectSandboxVendor thisBatch = new batchCorrectSandboxVendor();
        	database.executeBatch(thisBatch); 
        }
    }
    
    public static Boolean runningInASandbox() {
        return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }

    public static void turnOffSystemDefaults()
    {
        rstk__sydefault__c temp = ([SELECT Id, rstk__sydefault_addrpolicycust__c, rstk__sydefault_addrpolicyvend__c  FROM rstk__sydefault__c WHERE Name = 'SYDEFAULT' LIMIT 1]);
        temp.rstk__sydefault_addrpolicycust__c = false;
        temp.rstk__sydefault_addrpolicyvend__c = false;
        update temp;
    }
}