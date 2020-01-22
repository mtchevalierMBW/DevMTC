/**
* BatchPurgeSandboxDataViaSOQL_TEST
* Tests: BatchPurgeSandboxDataViaSOQL
* Date: 2018-12-31
* Programmer: Bryan Leaman
*
* NOTE: There is code inside BatchPurgeSandboxDataViaSOQL that prevents it from running 
* in a production environment unless it's in a test class!
*
*/
@isTest
private class BatchPurgeSandboxDataViaSOQL_TEST {

	 @testSetup
	 static void setupData() {
		 TestHelper_MW th = new TestHelper_MW();
		 Account a = th.getPersonAccount('1');
		 Account b = th.getPersonAccount('2');
	 }

	 // unitTest
	 //---------------------------------------
	 static testMethod void unitTest() {
		Test.startTest();
		Database.executeBatch(new BatchPurgeSandboxDataViaSOQL(
			'select Id from Account Where RecordType.Name=\'Person Account\' ', true
		));
		Test.stopTest();
	 }

}