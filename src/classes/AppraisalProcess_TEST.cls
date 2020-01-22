/**
 * AppraisalProcess_TEST
 * Tests: AppraisalProcess_TEST
 * Date: Feb 16, 2018
 * Programmer: Bryan Leaman
 *
 */
@isTest
private class AppraisalProcess_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		TestHelper_MW th = new TestHelper_MW();
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
		System.runAs(FFAdata.TestUser) {

			Account la = th.getBusinessAccount('2');
			dealer__Dealer_Location__c loc = new dealer__Dealer_Location__c(
				Id = FFAdata.DealerLocation.Id,
				dealer__Location_Account__c = la.Id
			);
			update(loc);
			
			Account a = th.getPersonAccount('1');
	        dealer__Sales_Up__c  dsp = new dealer__Sales_Up__c(
	        	dealer__Lead_Date__c=System.Today(),
	        	dealer__Lead_Status__c='Pending',
	        	dealer__Lead_Type__c='List',
	        	dealer__Source__c ='Pride',
	        	Solution_Type__c ='Equipment',
	        	dealer__Customer_Account__c =a.id
	        );
	        insert(dsp);
	
			Map<String, Schema.RecordTypeInfo> dealRcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();	// BLL11a
    	    dealer__Deal__c deal = new dealer__Deal__c(
    	    	Name = 'Test',
   	    		dealer__Deal_Type__c = 'Equipment',	
    	    	dealer__Auto_Insurance_Agent__c='Test',
    	    	dealer__Deal_ID__c ='Test',
    	    	dealer__Sales_Lead__c = dsp.id,
    	    	dealer__Status__c ='Pending',
    	    	dealer__Deal_Date__c =System.Today(),
    	    	Proposed_Delivery_Date__c =System.Today(),
    	    	dealer__Store_Location__c = FFAdata.DealerLocation.Id, 
    	    	dealer__Salesperson_1__c = UserInfo.getUserId()
    	    );
    	    insert(deal);

        	dealer__Service_Vehicle__c sv = new dealer__Service_Vehicle__c(
				dealer__Veh_Owner__c = a.Id,
        	    Name='Test trade', dealer__Make__c = 'Toyota', dealer__Model_Code__c = 'Sienna', dealer__Year__c = '2000',
        	    dealer__VIN__c = '12345678901234567'
        	);
        	insert(sv);
			
        	dealer__Trade_In__c t = new dealer__Trade_In__c(
        	    Name='Test trade', dealer__Make__c = 'Toyota', dealer__Model__c = 'Sienna', dealer__Year__c = '2000',
        	    dealer__VIN__c = '12345678901234567', 
        	    dealer__Car_Deal__c = deal.Id,
        	    dealer__ACV__c = 2000, dealer__Trade_Allowance__c = 2000, dealer__Odometer_At_Trade_In__c = 160000,
        	    dealer__Service_Vehicle__c = sv.Id
        	);
        	insert(t);
        	
			dealer__Appraisal__c ap = new dealer__Appraisal__c(
				dealer__Appraised_By__c = UserInfo.getUserId(),
				dealer__Store_Location__c = FFAdata.DealerLocation.Id,
				dtmob__Trade_In__c = t.Id,
				dtmob__Transportation_Handling__c = 'Store Responsibility',
				dealer__Service_Vehicle__c = sv.Id,  
				dealer__Vehicle_Owner__c = a.Id,
				dealer__Status__c = 'Pending'
			);
			insert(ap);

		} 
	}

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
			
			dealer__Dealer_Location__c loc = [select Id, Name, dealer__Location_Account__c from dealer__Dealer_Location__c limit 1];
			System.debug(loc);
			dealer__Service_Vehicle__c sv = [select Id, dealer__VIN__c, dealer__Veh_Owner__c from dealer__Service_Vehicle__c limit 1];
			System.debug(sv);			
			dealer__Appraisal__c ap = [select Id, dealer__Status__c, dealer__Vehicle_Owner__c, dealer__Service_Vehicle__c from dealer__Appraisal__c limit 1];
			System.debug(ap);

			Test.startTest();
			ap.dealer__Status__c = 'Won';
			update(ap);
			Test.stopTest();

			dealer__Dealer_Location__c loc2 = [select Id, Name, dealer__Location_Account__c from dealer__Dealer_Location__c limit 1];
			System.debug(loc2);
			dealer__Service_Vehicle__c sv2 = [select Id, dealer__VIN__c, dealer__Veh_Owner__c from dealer__Service_Vehicle__c limit 1];
			System.debug(sv2);			
			dealer__Appraisal__c ap2 = [select Id, dealer__Status__c, dealer__Vehicle_Owner__c, dealer__Service_Vehicle__c from dealer__Appraisal__c limit 1];
			System.debug(ap2);
			
			
		}
	}

}