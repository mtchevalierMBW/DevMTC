/**
 * ServiceVehicleESC_EXT_TEST
 * Tests: ServiceVehicleESC_EXT_TEST
 * Date: May 4, 2018
 * Programmer: Bryan Leaman
 *
 * Modification Log:
 *
 */
@isTest
private class ServiceVehicleESC_EXT_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		//FFAdata.refresh(); 
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
	}

	// ctrlExtTest
	//---------------------------------------
	static testMethod void ctrlExtTest() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();

			//PageReference pgRef = Page.{pagename}; 
			//Test.setCurrentPage(pgRef); //Set the page for Test Method
			//ApexPages.currentPage().getParameters().put('id', obj.id);

			Account pa = th.getPersonAccount('1');
			dealer__Service_Vehicle__c sv = new dealer__Service_Vehicle__c(
				dealer__VIN__c = 'ABCDEFGHIJ1234567',
				dealer__Year__c = String.valueOf(Date.today().year()),
				dealer__Carline__c = 'CurrentMdl',
				dealer__Make__c = 'Toyota',
				dealer__Veh_Owner__c = pa.Id
			);
			insert(sv);
			dealer__Service_Estimate__c est = new dealer__Service_Estimate__c(
				dealer__Service_Vehicle__c = sv.Id,
				dealer__Customer__c = pa.Id,
				dealer__Current_Mileage__c = 1
			);
			insert(est);
			dealer__Service_Repair_Order__c ro = new dealer__Service_Repair_Order__c(
				dealer__Vehicle__c = sv.Id,
				dealer__Customer__c = pa.Id,
				dealer__Mileage_In__c = 1
			);
			insert(ro);

			// from service vehicle
			ApexPages.StandardController svehctl = new ApexPages.StandardController(sv);
			ServiceVehicleESC_EXT ext1 = new ServiceVehicleESC_EXT(svehctl);
			List<dealer__Service_Contract__c> esclist1 = ext1.ServiceContracts;
			
			// from repair order
			ApexPages.StandardController sroctl = new ApexPages.StandardController(ro);
			ServiceVehicleESC_EXT ext2 = new ServiceVehicleESC_EXT(sroctl);
			List<dealer__Service_Contract__c> esclist2 = ext2.ServiceContracts;

			// from repair estimate
			ApexPages.StandardController estctl = new ApexPages.StandardController(est);
			ServiceVehicleESC_EXT ext3 = new ServiceVehicleESC_EXT(estctl);
			List<dealer__Service_Contract__c> esclist3 = ext2.ServiceContracts;
			
		}
	}

}