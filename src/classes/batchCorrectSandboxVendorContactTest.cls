/**
* MobilityWorks (c) - 2017
*
* batchCorrectSandboxVendorContactTest
* Date: 10/20/2017
* Programmer: Alexander Miller
*/
@isTest(SeeAllData=true)
public class batchCorrectSandboxVendorContactTest {

	public static testMethod void testRun(){
		Test.startTest();
		batchCorrectSandboxVendorContact temp = new batchCorrectSandboxVendorContact();
		database.executeBatch(temp);
		Test.stopTest();
	}
}