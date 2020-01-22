/*
* BatchOpportunityContactRoleSyncTest
* Date: 10/15/2018
* Programmer: Alexander Miller
* Work Item: 
* 
* Testing: 
*/
@isTest
public class BatchOpportunityContactRoleSyncTest {

     @testSetup
    public static void setup()
    {
        String mobilityWorksOppRecordType = 'MBWC_OppRecordType';

        Account tempAccount = new Account();
        tempAccount.Name = 'BatchLightningAttachmentMigrationTest';
        insert tempAccount;

        Opportunity tempOpp = new Opportunity();
        tempOpp.Name = 'BatchLightningAttachmentMigrationTest';
        tempOpp.AccountId = tempAccount.Id;
        tempOpp.CloseDate = System.Today();
        tempOpp.StageName = 'Pending';
        tempOpp.Sales_Channel__c = 'MBW N/A';
        tempOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(mobilityWorksOppRecordType).getRecordTypeId();
        insert tempOpp;
    }

    public static testMethod void testScheduler()
    {   
       Test.startTest();        
       BatchOpportunityContactRoleSync sh1 = new BatchOpportunityContactRoleSync();
       String sch = '0 0 23 * * ?'; 
       system.schedule('BatchOpportunityContactRoleSyncTest', sch, sh1);
       Test.stopTest();
    }

    public static testMethod void testBatch()
    {
        Test.startTest();
        BatchOpportunityContactRoleSync sh1 = new BatchOpportunityContactRoleSync();
        database.executeBatch(sh1, 1);
        Test.stopTest();
    }
}