/**
 * ServiceVehicleCompanyNumber_TC
 * Tests: ServiceVehicleCompanyNumber trigger
 *
 * Coverage:
 * 	2018-04-04	93% (14/15)
 *
**/
@isTest
private class ServiceVehicleCompanyNumber_TC {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	private static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
	}

	private static testmethod Void UnitMilestone() {
		
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();
			
			contact con = new contact();
			con.Phone = '8888888';
			con.LastName = 'Test';
			insert con;
			
			dealer__Service_Vehicle__c  dsv = new dealer__Service_Vehicle__c ();
			dsv.dealer__VIN__c ='Test5551212';
			dsv.Name='Test';
			dsv.dealer__Body_Style__c = 'Test';
			dsv.dealer__Company_Number__c='12123';
			dsv.dealer__Veh_Owner_Contact__c = con.id;
			dsv.dealer__Carline__c ='Test';
			dsv.dealer__Make__c  ='Test';
			dsv.dealer__Year__c  ='2013';
			insert dsv;
			
			User u = [select Id, Division from User where Id=:UserInfo.getUserId() limit 1];
			dealer__Dealer_Location__c l = th.getDealerLocation('1');
			u.Division = l.dealer__Company_Number__c;
			update(u);
			
			dsv.dealer__Body_Style__c = 'Test12';
			update dsv;
		}
		
	}

}