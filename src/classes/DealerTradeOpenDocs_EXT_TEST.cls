/**
 * DealerTradeOpenDocs_EXT_TEST
 * Tests: DealerTradeOpenDocs_EXT
 * Date: Jul 14, 2016
 * Programmer: Bryan Leaman
 *
 *	2016-12-19	B. Leaman	BLL1 - Changes for new validations added to deals & sales ups.
 *	2017-02-28	B. Leaman	BLL2 - changes for proposal record types for commercial.
 */
@isTest
private class DealerTradeOpenDocs_EXT_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);

		TestHelper_MW th = new TestHelper_MW();
		
		// create account
		Account a = th.getPersonAccount('1');

		// create sales up
        dealer__Sales_Up__c  dsp = new dealer__Sales_Up__c(
        	dealer__Lead_Date__c = System.Today(),
			dealer__First_Store_Visit_Date__c = DateTime.now(), 	// BLL1a
        	dealer__Lead_Status__c= 'Pending',
        	dealer__Lead_Type__c= 'List',
        	dealer__Source__c = 'Pride',
        	Solution_Type__c = 'Rental',
        	dealer__Customer_Account__c = a.id
		);
        insert dsp;

        // create vehicle 
        dealer__Vehicle_Inventory__c veh = new dealer__Vehicle_Inventory__c(
            Name='(TESTX) 2020 Toyota Future',
            New_Used_Other__c='Used', 
            Division__c='Commercial', 
            dealer__Stock_Number__c='TESTX',
            dealer__VIN__c='Z1234567890TUVWXY',
            dealer__Year__c='2020', dealer__Make__c='Toyota', dealer__Model__c='Future',
            dealer__Mileage__c=123000
        );
        insert(veh);

		Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();	// BLL1a
		// Create deal		
		dealer__Deal__c dd = new dealer__Deal__c(
        	Name = 'Test',
   	    	dealer__Deal_Type__c = 'Retail Vehicle Sale',	// BLL1a
  		    //BLL2d RecordTypeId = RcdTypes.get('Retail Vehicle Sale').getRecordTypeId(), // BLL1a
  		    RecordTypeId = RcdTypes.get('Retail').getRecordTypeId(), // BLL2a
        	dealer__Auto_Insurance_Agent__c='Test',
        	dealer__Deal_ID__c ='Test',
        	dealer__Sales_Lead__c = dsp.id,
        	dealer__Status__c ='Won - Delivered',
        	dealer__Deal_Date__c =System.Today(),
        	Proposed_Delivery_Date__c =System.Today(),
        	dealer__Vehicle__c = veh.Id
        );
        insert dd;
        
        // create opportunity
		Opportunity o = new Opportunity(
			Name='Test commercial opp', AccountId=a.Id, StageName='Pending', CloseDate=Date.today()
		);
		
		// create commercial quote
		CommercialQuote__c cq = new CommercialQuote__c(
			Salesperson__c = UserInfo.getUserId(),
			Status__c='Pending',
			Opportunity__c = o.Id,
			VehicleInventory__c = veh.Id,
			Location__c=FFAdata.DealerLocation.Id
		);
		insert(cq);
        
	}

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
			
			dealer__Vehicle_Inventory__c veh = [select Id, Name from dealer__Vehicle_Inventory__c limit 1];
			dealer__Dealer_Trade__c dt = new dealer__Dealer_Trade__c(
				dealer__Stock_No__c = veh.Id
			);
			insert(dt);
			
			Test.startTest();
			
			PageReference pgRef = Page.DealerTradeOpenDocs; 
			Test.setCurrentPage(pgRef); //Set the page for Test Method
			ApexPages.currentPage().getParameters().put('id', dt.Id);
			ApexPages.currentPage().getParameters().put('retURL', '/');
			ApexPages.StandardController sc = new ApexPages.StandardController(dt);
			DealerTradeOpenDocs_EXT dtod = new DealerTradeOpenDocs_EXT(sc);
			dtod.getOpenDocuments();
			
			Test.stopTest();
						
		}
	}

}