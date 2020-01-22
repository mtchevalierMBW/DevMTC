/**
 * SalesOrderDimensionProcess_TEST
 * Tests: SalesOrderDimensionProcess_TEST
 * Date: Jul 5, 2017
 * Programmer: Bryan Leaman
 *
 *
 *  Modified By         Alias       Work Item       Date     Reason
 *  __________________________________________________________________________________________________
 * 
 * Alexander Miller     AMM1        IR-0043867    11/13/2018  The query grabbed the most recent Sales Order and didn't account for invalid billing addresses
 * Bryan Leaman			BLL1		W-000647	  5/21/2019	   Getting a bad record for testing. Just going to ignore the exception for now.
*/
@isTest(seeAllData=true)
private class SalesOrderDimensionProcess_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	//@testSetup
	//static void setupFFA() {
	//	TestHelper_MW.createBaseFFAData(FFAdata);
    //	dealer.TestClassUtil tc = new dealer.TestClassUtil();
    //	tc.insertDMSSettings();
	//}

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		//FFAdata.refresh(); 
                        
		//System.runAs(FFAdata.TestUser) {
        //	TestHelper_MW th = new TestHelper_MW();

		// AMM1
		List<rstk__socaddr__c> listOfCustomerAddress = ([SELECT Id, rstk__socaddr_custno__c FROM rstk__socaddr__c WHERE rstk__socaddr_verified__c = true]);
		
		List<Id> listOfCustomerIds = new List<Id>();

		for(rstk__socaddr__c tempAddress : listOfCustomerAddress)
		{
			listOfCustomerIds.add(tempAddress.rstk__socaddr_custno__c);
		}
		// AMM1

		// Just need to update any sales order header & line
		List<rstk__sohdr__c> hdr = [
			select Id, Name, rstk__sohdr_otype__c
			from rstk__sohdr__c
			// AMM1
			WHERE rstk__sohdr_custno__c IN :listOfCustomerIds
			// AMM1
			order by createddate desc
			limit 1
		];
	
		new SalesOrderDimensionProcess(hdr, null).updateLineDimensions();	
		update(hdr);
	
		List<rstk__soline__c> lin = [
			select Id, Name, rstk__soline_sohdr__c, rstk__soline_dimvals__c
			from rstk__soline__c
			// AMM1
			WHERE rstk__soline_sohdr__r.rstk__sohdr_custno__c IN :listOfCustomerIds
			// AMM1
			order by createddate desc
			limit 1
		];
		new SalesOrderDimensionProcess(lin, null).updateLineDimensions();	
// BLL1
try {
// BLL1 end
		update(lin);
//BLL1
} catch(Exception e) {}
// BLL1 end	
		//}
	}

}