/**
* MobilityWorks (c) - 2018
*
* changeToAccountClassTest
* Created: 8/28/2018
* Developer: Alexander Miller
*
* Modifications:
*	2019-09-18	B. Leaman	W-000730 BLL1 - getting "Cannot see person account record type" error
*/
@isTest
public class changeToAccountClassTest {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData();
    
    @testSetup
    public static void setup()
    {
        TestHelper_MW th = new TestHelper_MW();
        
        Account tempAccount = th.getPersonAccount('1');
		System.debug(tempAccount);
        Account tempAccount2 = th.getBusinessAccount('2');
		System.debug(tempAccount2);
	}
    
    public static testMethod void testUpdateAccountToBusinessAccount()
    {
        Test.startTest();
        
        TestHelper_MW th = new TestHelper_MW();
        
        Account tempAccount = [SELECT Id FROM Account WHERE RecordTypeId = :Schema.SObjectType.Account.getRecordTypeInfosByName().get('PersonAccount').getRecordTypeId() LIMIT 1];
		System.debug(tempAccount);
        
        changeToAccountClass.updateAccountToBusinessAccount(tempAccount.Id);
        
        tempAccount = [SELECt Id, 
                       RecordTypeId 
                       FROM Account 
                       LIMIT 1];
		System.debug(tempAccount);
        
        System.assertEquals(th.getBusinessAccountRt().Id, tempAccount.RecordTypeId);
        
        Test.stopTest();
    }

     public static testMethod void testUpdateAccountToPersonAccount()
    {
        Test.startTest();
        
        TestHelper_MW th = new TestHelper_MW();
        
        Account tempAccount = [SELECt Id FROM Account WHERE RecordTypeId = :Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId() LIMIT 1];
		System.debug(tempAccount);
        
        changeToAccountClass.updateAccountToPersonAccount(tempAccount.Id);
        
        tempAccount = [SELECt Id, 
                       RecordTypeId 
                       FROM Account 
                       LIMIT 1];
		System.debug(tempAccount);
        
        Test.stopTest();
    }
    
    public static testMethod void testValidateAccountToPersonAccount()
    {
        Test.startTest();
        
        TestHelper_MW th = new TestHelper_MW();
        
        Account tempAccount = [SELECt Id FROM Account WHERE RecordTypeId = :Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId() LIMIT 1];
        
        Contact con1 = new Contact(LastName = '123', AccountId = tempAccount.Id);
        insert con1;
        
        User tempNewUser = th.getTestUser('00');
        
        Contact con2 = new Contact(LastName = '1233_AMM', AccountId = tempAccount.Id, OwnerId = tempNewUser.Id);
        insert con2;
        
        Account tempAccount2 = th.getBusinessAccount('1AMILLER');
        tempAccount2.Name='AMTest';
        
        tempAccount2.ParentId = tempAccount.Id;
        update tempAccount2;
        
        changeToAccountClass.validateAccountToPersonAccount(tempAccount.Id);
        
        Test.stopTest();
    }
}