/**
 * upload_Task_Helper_MW_TEST
 * Tests: upload_Task_Helper_MW
 * 
 */
@isTest
private class upload_Task_Helper_MW_TEST {

    static testMethod void testUploadHelper() {
       Account plain = new Account(Name='Test noupload account', BillingState='OH', BillingPostalCode='44641',
               dealer__External_ID__c='ABC123TEST@X');
       insert(plain);
       Task t = new Task();
       t.upload_Owner__c = UserInfo.getName();
       t.upload_Account__c = plain.dealer__External_ID__c;
       t.ActivityDate = Date.today(); 
       t.Description = 'test message';
       t.Subject='Email sent '; 
       t.Status='Completed';
       insert(t);
    }
}