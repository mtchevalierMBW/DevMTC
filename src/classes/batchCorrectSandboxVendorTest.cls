/**
* MobilityWorks (c) - 2017
*
* batchCorrectSandboxVendorTest
* Date: 10/20/2017
* Programmer: Alexander Miller
*/
@isTest(SeeAllData=true)
public class batchCorrectSandboxVendorTest {

	public static testMethod void testRun(){
		Test.startTest();
		batchCorrectSandboxVendor temp = new batchCorrectSandboxVendor();
		database.executeBatch(temp);
		Test.stopTest();
	}
}