/**
 * WOTravelerReport_CTRL_TEST
 * Tests: WOTravelerReport_CTRL
 * Date: Mar 13, 2017
 * Programmer: Bryan Leaman
 *
 * Uses seeAllData=true because of the complexity of setting up rootstock.
 */
@isTest(seeAllData=true)
private class WOTravelerReport_CTRL_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {

		rstk__wocst__c wo = [select Id from rstk__wocst__c WHERE rstk__wocst_soline__r.rstk__soline_confsess__c != null AND rstk__wocst_ordsts_pl__c IN ('5-Pick List records generated', '8-Receipts completed') limit 1];

		PageReference pgRef = Page.WOTravelerReport; 
		Test.setCurrentPage(pgRef); //Set the page for Test Method
		ApexPages.currentPage().getParameters().put('id', wo.id);
		ApexPages.currentPage().getParameters().put('retURL', '/');
		WOTravelerReport_CTRL woctl = new WOTravelerReport_CTRL();
		WOTravelerReport2_CTRL woctl2 = new WOTravelerReport2_CTRL();
		WOTravelerReport3 woctl3 = new WOTravelerReport3();
		System.assertEquals(null, woctl3.strConfigurationSession );
		System.assertEquals(null, woctl3.listOfComponentsFromConfigurator ); 
	}

}