/**
* MobilityWorks (c) - 2017
*
* batchCorrectSandboxCustomerContactTest
* Date: 10/20/2017
* Programmer: Alexander Miller
*/
@isTest(SeeAllData=true)
public class batchCorrectSandboxCustomerContactTest {

	public static testMethod void testRun(){
		Test.startTest();
		batchCorrectSandboxCustomerContact temp = new batchCorrectSandboxCustomerContact();
		database.executeBatch(temp);
		Test.stopTest();
	}
}