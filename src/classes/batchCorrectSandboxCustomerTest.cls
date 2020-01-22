/**
* MobilityWorks (c) - 2017
*
* batchCorrectSandboxCustomerTest
* Date: 10/20/2017
* Programmer: Alexander Miller
*/
@isTest(SeeAllData=true)
public class batchCorrectSandboxCustomerTest {

	public static testMethod void testRun(){
		Test.startTest();
		batchCorrectSandboxCustomer temp = new batchCorrectSandboxCustomer();
		database.executeBatch(temp);
		Test.stopTest();
	}
}