/**
 * Deal_UpdateControl_Test
 * Tests: Deal_UpdateControl_Test
 * Date: Jan 12, 2017
 * Programmer: Bryan Leaman
 *
 *	2017-02-28	B. Leaman	BLL1 - changes for commercial proposal record type
 */
@isTest
private class Deal_UpdateControl_Test {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
       	TestHelper_MW th = new TestHelper_MW();
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
        insert(new dealer__FixedOperationsSettings__c(dealer__Repair_Order_Index__c=1));
        insert(new RetailDefaults__c(ProposalNumber__c=7));  

		Account a = th.getPersonAccount('1');
        
       	// Need service pmt types
       	List<ServicePaymentType__c> spts = new List<ServicePaymentType__c>();
       	spts.add(new ServicePaymentType__c(Name='IEN',Default_Labor_Rate__c=52,Description__c='Test IEN'));
       	spts.add(new ServicePaymentType__c(Name='IEU',Default_Labor_Rate__c=52,Description__c='Test IEU'));
       	spts.add(new ServicePaymentType__c(Name='IEO',Default_Labor_Rate__c=52,Description__c='Test IEO'));
       	insert(spts);
        
        // create vehicle 
        dealer__Vehicle_Inventory__c veh = new dealer__Vehicle_Inventory__c(
            Name='(TESTX) 2020 Toyota Future',
            New_Used_Other__c='Used', Division__c='Commercial',
            dealer__Status_Code__c = 'Ready For Sale', 
            dealer__Stock_Number__c='TESTX',
            dealer__VIN__c='11234567890TUVWXY',
            dealer__Year__c='2020', dealer__Make__c='Toyota', dealer__Model__c='Future',
            dealer__Mileage__c=123000
        );
        insert(veh);

        dealer__Sales_Up__c  dsp = new dealer__Sales_Up__c(
        	dealer__Lead_Date__c=System.Today(),
			dealer__First_Store_Visit_Date__c = DateTime.now(), 	// BLL1a
        	dealer__Lead_Status__c='Pending',
        	dealer__Lead_Type__c='List',
        	dealer__Source__c ='Pride',
        	Solution_Type__c ='Chassis/Conversion',
        	dealer__Customer_Account__c =a.id,
			dealer__Trade_Year__c = '2016',
			dealer__Trade_Make__c = 'Toyota',
			dealer__Trade_Model__c = 'Greatness'
		);
        insert dsp;
	}

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		FFAdata.refresh();
                        
		System.runAs(FFAdata.TestUser) {

			// Get sales up & vehicle
			dealer__Sales_Up__c dsp = [select Id from dealer__Sales_Up__c limit 1];
			dealer__Vehicle_Inventory__c veh = [select Id from dealer__Vehicle_Inventory__c limit 1];
			Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();	// BLL1a
   		    dealer__Deal__c d = new dealer__Deal__c(
   		    	Name = 'Test',
	   	    	dealer__Deal_Type__c = 'Retail Vehicle Sale',	// BLL1a
   		    	//BLL1d RecordTypeId = RcdTypes.get('Retail Vehicle Sale').getRecordTypeId(), 
   		    	RecordTypeId = RcdTypes.get('Retail').getRecordTypeId(), // BLL1a
   		    	TaxCalcDT__c = DateTime.now(), 	// BLL1a
   		    	dealer__Auto_Insurance_Agent__c='Test',
	   	    	dealer__Deal_ID__c ='Test',
	   	    	dealer__Sales_Lead__c = dsp.id,
	   	    	dealer__Status__c ='Pending',
	   	    	dealer__Deal_Date__c =System.Today(),
	   	    	Proposed_Delivery_Date__c =System.Today(),
	   	    	dealer__Vehicle__c = veh.Id,
	   	    	dealer__Store_Location__c = FFAdata.DealerLocation.Id,
	   	    	Funding_option__c = 'Cash', // BLL3a
	   	    	dealer__DeliveryRepairOrder__c = null	// BLL2c
	   	    );
	   	    insert d;
	   	    d.Funding_option__c = 'Cash';
	   	    Test.startTest();
			Deal_UpdateControl.updateFandIData(d);
			Test.stopTest();
		}
	}

}