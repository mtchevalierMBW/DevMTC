/**
* MobilityWorks (c) - 2018
*
* changeToBusinessAccountClassTest
* Created: 8/28/2018
* Developer: Alexander Miller
*
* Modifications:
*	2019-09-18	B. Leaman	W-000730 BLL1 - getting an error that the account is already a business account
*/
@isTest
public class changeToBusinessAccountClassTest {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData();
    
    @testSetup
    public static void setup()
    {
        TestHelper_MW th = new TestHelper_MW();
        
        Account tempAccount = th.getPersonAccount('1');
		System.debug(tempAccount);
	}
    
    public static testMethod void testUpdateAccountToBusinessAccount()
    {
        Test.startTest();
        
        TestHelper_MW th = new TestHelper_MW();
        
        Account tempAccount = [SELECt Id FROM Account LIMIT 1];
		System.debug(tempAccount);
        
        changeToBusinessAccountClass.updateAccountToBusinessAccount(tempAccount.Id);
        
        tempAccount = [SELECt Id, 
                       RecordTypeId 
                       FROM Account 
                       LIMIT 1];
		System.debug(tempAccount);
        
        System.assertEquals(th.getBusinessAccountRt().Id, tempAccount.RecordTypeId);
        
        Test.stopTest();
    }
}