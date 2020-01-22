/**
 * DealProcess_TEST
 * Tests: DealProcess_TEST
 * Date: Aug 8, 2016
 * Programmer: Bryan Leaman
 *
 *	2016-12-19	B. Leaman	BLL1 - Fix tests for newly added validations of deals.
 *	2016-12-29	B. Leaman	BLL2 - Replace custom lookups with managed versions (Deal obj)
 *	2017-01-03	B. Leaman	BLL3 - Change to use new "FundingOption__c" field.
 *	2017-02-27	B. Leaman	BLL4 - Record type change for commercial    
 *	2017-05-04	B. Leaman	BLL5 - Alter to reduce SOQL queries in any 1 test method.
 *	2018-09-12	B. Leaman	BLL6 - reduce soql queries
 *	2018-10-03	B. Leaman	BLL7 - increase code coverage
 *	2019-01-22	B. Leaman	W-000562 BLL8 - increase code coverage
 *
 */
@isTest
private class DealProcess_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
       	TestHelper_MW th = new TestHelper_MW();
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
        insert(new dealer__FixedOperationsSettings__c(dealer__Repair_Order_Index__c=1));
        insert(new RetailDefaults__c(ProposalNumber__c=7));  

		// BLL6a - turn off some trigger functions we don't need for testing
		List<MW_TriggerControls__c> tcs = new List<MW_TriggerControls__c>();
		tcs.add(new MW_TriggerControls__c(Name='SROTriggers', Enabled__c=false));
		tcs.add(new MW_TriggerControls__c(Name='VehicleStsGetRdy', Enabled__c=false));
		tcs.add(new MW_TriggerControls__c(Name='DealDuplicateStockSale', Enabled__c=false));
		tcs.add(new MW_TriggerControls__c(Name='ProposalESCStatus', Enabled__c=false));

		tcs.add(new MW_TriggerControls__c(Name='Solution_Opp_Open_Chassis', Enabled__c=false));
		tcs.add(new MW_TriggerControls__c(Name='DealBuyerAccount', Enabled__c=false));
		tcs.add(new MW_TriggerControls__c(Name='SolutionOppDeals', Enabled__c=false));
		tcs.add(new MW_TriggerControls__c(Name='SalesUpUpdateContactInfo', Enabled__c=false));

		insert(tcs);
        // BLL6a

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
			dealer__Store_Location__c = FFAdata.DealerLocation.Id, // BLL8a
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

	// dealTriggerTests
	//---------------------------------------
	static testMethod void dealTriggerTests() {
		FFAdata.refresh();
		List<dealer__Deal__c> newList = new List<dealer__Deal__c>();
		Map<Id,dealer__Deal__c> oldMap = new Map<Id,dealer__Deal__c>(); 
                        
		System.runAs(FFAdata.TestUser) {

			// Get sales up & vehicle
			dealer__Sales_Up__c dsp = [select Id from dealer__Sales_Up__c limit 1];
			dealer__Vehicle_Inventory__c veh = [select Id from dealer__Vehicle_Inventory__c limit 1];

			Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();	// BLL1a
			// Deal Integrity
   		    dealer__Deal__c oldd = new dealer__Deal__c(
   		    	Name = 'Test',
	   	    	dealer__Deal_Type__c = 'Retail Vehicle Sale',	// BLL1a
   		    	//BLL4d RecordTypeId = RcdTypes.get('Retail Vehicle Sale').getRecordTypeId(), // BLL1a
   		    	RecordTypeId = RcdTypes.get('Retail').getRecordTypeId(), // BLL4a
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
	   	    insert oldd;
			dealer__Deal__c newd = oldd.clone(true, false, false, true);
			oldMap.put(oldd.Id, oldd);
			newList.add(newd);

			Test.startTest();	// BLL6a

			DealProcess dp = new DealProcess(newList, oldMap);

			oldd.dealer__Status__c = 'Pending';
			newd.dealer__Status__c = 'Pending';
			newd.dealer__Co_Buyer__c = newd.dealer__Buyer__c;
			dp.ProposalIntegrity();

			// Create trade from sales up
			dp.CreateTradeFromSalesUp();

			// Won deal
			oldd.dealer__Status__c = 'Pending';
			newd.dealer__Status__c = 'Won - Deposit';
			//dp.ProcessStatusChange();
			dp.StatusChangeValidation();	
			// dp.WonSolutionOpportunities();
			dp.VehiclesSoldNotDelivered();
			dp.VehiclesDelivered();
			//BLL5d dp.PostSalesTax();
			//BLL5d dp.DeliveryRepairOrders();
			//BLL5d dp.PostingEntries();
			//BLL5d dp.PostingProposals();	// NEW: only accounting can approve final status of Won - Posted
			// Vehicle should be Sold - Not Delivered
			dealer__Vehicle_Inventory__c vehsnd = [select Id, dealer__Status_Code__c from dealer__Vehicle_Inventory__c where Id=:veh.Id];
			System.assertEquals('Sold - Not Delivered', vehsnd.dealer__Status_Code__c, 'Vehicle status did not change');

			// BLL1a - Test WonSolutionOpportunities via trigger
			oldd.dealer__Status__c = 'Won - Deposit';
			update(oldd);
			// BLL1a end

			Test.stopTest();	// BLL6a

		}
	}
						
	// dealTriggerValidations - error messages
	static testMethod void dealTriggerValidations() {
       	TestHelper_MW th = new TestHelper_MW();
       	Id uid = UserInfo.getUserId(); 
		FFAdata.refresh();
		List<dealer__Deal__c> newList = new List<dealer__Deal__c>();
		Map<Id,dealer__Deal__c> oldMap = new Map<Id,dealer__Deal__c>(); 
                        
		System.runAs(FFAdata.TestUser) {

			// Get sales up & vehicle
			dealer__Sales_Up__c dsp = [select Id from dealer__Sales_Up__c limit 1];
			dealer__Vehicle_Inventory__c veh = [select Id from dealer__Vehicle_Inventory__c limit 1];

			Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();	// BLL1a
			// Deal Integrity
   		    dealer__Deal__c oldd = new dealer__Deal__c(
   		    	Name = 'Test',
	   	    	dealer__Deal_Type__c = 'Retail Vehicle Sale',	// BLL1a
   		    	//BLL4d RecordTypeId = RcdTypes.get('Retail Vehicle Sale').getRecordTypeId(), // BLL1a
   		    	//BLL7d RecordTypeId = RcdTypes.get('Retail').getRecordTypeId(), // BLL4a
   		    	RecordTypeId = RcdTypes.get('Commercial').getRecordTypeId(),	// BLL7a
   		    	TaxCalcDT__c = DateTime.now(), 	// BLL1a
   		    	dealer__Auto_Insurance_Agent__c='Test',
	   	    	dealer__Deal_ID__c ='Test',
	   	    	dealer__Sales_Lead__c = dsp.id,
	   	    	dealer__Status__c ='Pending',
	   	    	dealer__Deal_Date__c =System.Today(),
	   	    	Proposed_Delivery_Date__c =System.Today(),
	   	    	dealer__Vehicle__c = veh.Id,
	   	    	//BLL7d - allow process to fill this in: dealer__Store_Location__c = FFAdata.DealerLocation.Id,
	   	    	Funding_option__c = 'Cash', // BLL3a
	   	    	dealer__DeliveryRepairOrder__c = null	// BLL2c
	   	    );

			Test.startTest();	// BLL7a
			
	   	    insert oldd;
			dealer__Deal__c newd = oldd.clone(true, false, false, true);
			oldMap.put(oldd.Id, oldd);
			newList.add(newd);

			DealProcess dp = new DealProcess(newList, oldMap);
			Account tpp = th.getThirdPartyAccount('1');
			newd.dealer__Buyer__c = tpp.Id;
			newd.dealer__Co_Buyer__c = tpp.Id;
			newd.OwnerId = uid;
			dp.ProposalIntegrity();

			oldd.dealer__Status__c = 'Won - Posted';
			newd.dealer__Status__c = 'Won - Posted';
			newd.dealer__Buyer__c = newd.dealer__Co_Buyer__c;
			dp.ProposalIntegrity();

			oldd.dealer__Status__c='Won - GM Approval'; 
			newd.dealer__Status__c='Won - Production';
			newd.Funding_Option__c = null;
			dp.StatusChangeValidation();
			
			// payor 
			newd.dtmob__Auto_Grant_Payor__c=tpp.Id;
			newd.AutoGrant__c=null;
			newd.Third_Party_Pay_1__c=tpp.Id;
			newd.dealer__Deferred_Down_1__c=null;
			newd.Third_Party_Pay_2__c=tpp.Id;
			newd.dealer__Deferred_Down_2__c=null;
			newd.Third_Party_Pay_3__c=tpp.Id;
			newd.dealer__Deferred_Down_3__c=null;
			dp.StatusChangeValidation();

			newd.dtmob__Auto_Grant_Payor__c=null;
			newd.AutoGrant__c=1000;
			newd.Third_Party_Pay_1__c=null;
			newd.dealer__Deferred_Down_1__c=1000;
			newd.Third_Party_Pay_2__c=null;
			newd.dealer__Deferred_Down_2__c=1000;
			newd.Third_Party_Pay_3__c=null;
			newd.dealer__Deferred_Down_3__c=1000;
			dp.StatusChangeValidation();
			newd.dealer__Deferred_Down_1__c=null;
			newd.dealer__Deferred_Down_2__c=null;
			newd.dealer__Deferred_Down_3__c=null;

			newd.dealer__Status__c = 'Won - F&I';
			oldd.dealer__Status__c = 'Won - GM Approval';
			dp.StatusChangeValidation();
			
			Test.stopTest();	// BLL7a

		}
	}

	// dealTriggerCreateRO
	//---------------------------------------
	static testMethod void dealTriggerCreateRO() {
		FFAdata.refresh();
		List<dealer__Deal__c> newList = new List<dealer__Deal__c>();
		Map<Id,dealer__Deal__c> oldMap = new Map<Id,dealer__Deal__c>(); 
                        
		System.runAs(FFAdata.TestUser) {
			// Get sales up & vehicle
			dealer__Sales_Up__c dsp = [select Id from dealer__Sales_Up__c limit 1];
			dealer__Vehicle_Inventory__c veh = [select Id from dealer__Vehicle_Inventory__c limit 1];

			Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();	// BLL1a
			// Deal Integrity
   		    dealer__Deal__c oldd = new dealer__Deal__c(
   		    	Name = 'Test',
	   	    	dealer__Deal_Type__c = 'Retail Vehicle Sale',	// BLL1a
   		    	//BLL4d RecordTypeId = RcdTypes.get('Retail Vehicle Sale').getRecordTypeId(), // BLL1a
   		    	RecordTypeId = RcdTypes.get('Retail').getRecordTypeId(), // BLL4a
   		    	TaxCalcDT__c = DateTime.now(), 	// BLL1a
   		    	dealer__Auto_Insurance_Agent__c='Test',
	   	    	dealer__Deal_ID__c ='Test',
	   	    	dealer__Sales_Lead__c = dsp.id,
				dealer__Status__c = 'Won - Deposit',
	   	    	dealer__Deal_Date__c =System.Today(),
	   	    	Proposed_Delivery_Date__c =System.Today(),
	   	    	dealer__Vehicle__c = veh.Id,
	   	    	dealer__Store_Location__c = FFAdata.DealerLocation.Id,
	   	    	Funding_option__c = 'Cash', // BLL3a
	   	    	dealer__DeliveryRepairOrder__c = null	// BLL2c
	   	    );
	   	    insert oldd;
			dealer__Deal__c newd = oldd.clone(true, false, false, true);
			oldMap.put(oldd.Id, oldd);
			newList.add(newd);

			DealProcess dp = new DealProcess(newList, oldMap);
			// Production: create RO
			newd.dealer__Status__c = 'Won - Production';
			dp.StatusChangeValidation();	
			//dp.WonSolutionOpportunities();
			//dp.VehiclesSoldNotDelivered();
			//dp.VehiclesDelivered();
			//dp.PostSalesTax();
//x			dp.DeliveryRepairOrders();
			//BLL5d dp.PostingEntries();
			//BLL5d dp.PostingProposals();	// NEW: only accounting can approve final status of Won - Posted
//x			System.assert(newd.dealer__DeliveryRepairOrder__c!=null,'Delivery Repair Order was not created');	// BLL2c
			
		}
	}


	// dealTriggerTests2
	//---------------------------------------
	static testMethod void dealTriggerTests2() {
		FFAdata.refresh();
		List<dealer__Deal__c> newList = new List<dealer__Deal__c>();
		Map<Id,dealer__Deal__c> oldMap = new Map<Id,dealer__Deal__c>(); 
                        
		System.runAs(FFAdata.TestUser) {

			// Get sales up & vehicle
			dealer__Sales_Up__c dsp = [select Id from dealer__Sales_Up__c limit 1];
			dealer__Vehicle_Inventory__c veh = [select Id from dealer__Vehicle_Inventory__c limit 1];

			Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();	// BLL1a
			// Deal Integrity
   		    dealer__Deal__c oldd = new dealer__Deal__c(
   		    	Name = 'Test',
	   	    	dealer__Deal_Type__c = 'Retail Vehicle Sale',	// BLL1a
   		    	//BLL4d RecordTypeId = RcdTypes.get('Retail Vehicle Sale').getRecordTypeId(), // BLL1a
   		    	RecordTypeId = RcdTypes.get('Retail').getRecordTypeId(), // BLL4a
   		    	TaxCalcDt__c = DateTime.now(), 	// BLL1a
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
	   	    insert oldd;
			dealer__Deal__c newd = oldd.clone(true, false, false, true);
			oldMap.put(oldd.Id, oldd);
			newList.add(newd);

			DealProcess dp = new DealProcess(newList, oldMap);

			Test.startTest();	// BLL6a

			oldd.dealer__Status__c = 'Pending';
			newd.dealer__Status__c = 'Pending';
			newd.dealer__Co_Buyer__c = newd.dealer__Buyer__c;
			dp.ProposalIntegrity();

			// BLL1a - Test WonSolutionOpportunities via trigger
			oldd.dealer__Status__c = 'Won - Delivery';
			update(oldd);
			// BLL1a end

			// Delivered
			oldd.dealer__Status__c = 'Won - Delivery';
			newd.dealer__Status__c = 'Won - Delivered';
			dp.StatusChangeValidation();	
			dp.WonSolutionOpportunities();
			dp.VehiclesSoldNotDelivered();
			dp.VehiclesDelivered();
			dp.PostSalesTax();
			//BLL5d dp.DeliveryRepairOrders();
			//BLL5d dp.PostingEntries();
			//BLL5d dp.PostingProposals();	// NEW: only accounting can approve final status of Won - Posted
			// Vehicle should be Delivered
			dealer__Vehicle_Inventory__c vehdlv = [select Id, dealer__Status_Code__c from dealer__Vehicle_Inventory__c where Id=:veh.Id];
			System.assertEquals('Delivered', vehdlv.dealer__Status_Code__c, 'Vehicle status did not change');
			
			// Un-Delivered (remove posting entry)
			oldd.dealer__Status__c = 'Won - Delivered';
			newd.dealer__Status__c = 'Won - Delivery';
			dp.StatusChangeValidation();	
			dp.WonSolutionOpportunities();
			dp.VehiclesSoldNotDelivered();
			dp.VehiclesDelivered();
			dp.PostSalesTax();
			//BLL5d dp.DeliveryRepairOrders();
			//BLL5d dp.PostingEntries();
			//BLL5d dp.PostingProposals();	// NEW: only accounting can approve final status of Won - Posted
			
			// Posted
			oldd.dealer__Status__c = 'Won - Delivered';
			newd.dealer__Status__c = 'Won - Posted';
			dp.StatusChangeValidation();	
			dp.WonSolutionOpportunities();
			dp.VehiclesSoldNotDelivered();
			dp.VehiclesDelivered();
			dp.PostSalesTax();
			dp.DeliveryRepairOrders();
			dp.PostingEntries();
			dp.PostingProposals();	// NEW: only accounting can approve final status of Won - Posted

			Test.stopTest();	// BLL6a

		}
	}


	static testmethod void leaseTests() {
		FFAdata.refresh();
		List<dealer__Deal__c> newList = new List<dealer__Deal__c>();
		Map<Id,dealer__Deal__c> oldMap = new Map<Id,dealer__Deal__c>(); 
                        
		System.runAs(FFAdata.TestUser) {

			// Get sales up & vehicle
			dealer__Sales_Up__c dsp = [select Id from dealer__Sales_Up__c limit 1];
			dealer__Vehicle_Inventory__c veh = [select Id from dealer__Vehicle_Inventory__c limit 1];

			Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();	// BLL1a
			// Deal Integrity
   		    dealer__Deal__c oldd = new dealer__Deal__c(
   		    	Name = 'Test',
	   	    	dealer__Deal_Type__c = 'Retail Vehicle Sale',	// BLL1a
   		    	//BLL4d RecordTypeId = RcdTypes.get('Retail Vehicle Sale').getRecordTypeId(), // BLL1a
   		    	RecordTypeId = RcdTypes.get('Retail').getRecordTypeId(), // BLL4a
   		    	TaxCalcDt__c = DateTime.now(), 	// BLL1a
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
	   	    insert oldd;
	   	    
	   	    // Select all fields from TaxRuleSetting__c
			Map<String, Schema.SObjectField> dealFieldMap =  Schema.dealer__Deal__c.SObjectType.getDescribe().fields.getMap();
			List<String> dealFieldList = new List<String>();
			for(string f : dealFieldMap.keySet()) /* if (dealFieldMap.get(f).getDescribe().isAccessible()) */ dealFieldList.add(f);
			String dealfields = String.join(dealFieldList,',');
			String soql = 'select ' + dealfields + ' from dealer__Deal__c where Id=\'' + oldd.Id + '\' LIMIT 1';
			oldd = Database.query(soql);
	   	    
			dealer__Deal__c newd = oldd.clone(true, false, false, true);
			oldMap.put(oldd.Id, oldd);
			newList.add(newd);

			DealProcess dp = new DealProcess(newList, oldMap);
			newd.ChassisResidualPct__c = 45;
			newd.ChassisMSRP__c = 20000;
			newd.ConversionResidualPct__c = 75;
			newd.ConversionMSRP__c = 12000;
			newd.TaxOnCostReduction__c = 150;
			newd.Contract_Number_of_Payments__c = 24;
			dp.FinanceCalculations(newd);
			
		}
		
	}

	static testmethod void miscDealMethods() {
		FFAdata.refresh();
		List<dealer__Deal__c> newList = new List<dealer__Deal__c>();
		Map<Id,dealer__Deal__c> oldMap = new Map<Id,dealer__Deal__c>(); 
                        
		System.runAs(FFAdata.TestUser) {

			// Get sales up & vehicle
			dealer__Sales_Up__c dsp = [select Id from dealer__Sales_Up__c limit 1];
			dealer__Vehicle_Inventory__c veh = [select Id from dealer__Vehicle_Inventory__c limit 1];

			Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();	// BLL1a
			// Deal Integrity
   		    dealer__Deal__c oldd = new dealer__Deal__c(
   		    	Name = 'Test',
	   	    	dealer__Deal_Type__c = 'Retail Vehicle Sale',	// BLL1a
   		    	//BLL4d RecordTypeId = RcdTypes.get('Retail Vehicle Sale').getRecordTypeId(), // BLL1a
   		    	RecordTypeId = RcdTypes.get('Retail').getRecordTypeId(), // BLL4a
   		    	TaxCalcDt__c = DateTime.now(), 	// BLL1a
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
	   	    insert oldd;
	   	    
	   	    // Select all fields from TaxRuleSetting__c
			Map<String, Schema.SObjectField> dealFieldMap =  Schema.dealer__Deal__c.SObjectType.getDescribe().fields.getMap();
			List<String> dealFieldList = new List<String>();
			for(string f : dealFieldMap.keySet()) /* if (dealFieldMap.get(f).getDescribe().isAccessible()) */ dealFieldList.add(f);
			String dealfields = String.join(dealFieldList,',');
			String soql = 'select ' + dealfields + ' from dealer__Deal__c where Id=\'' + oldd.Id + '\' LIMIT 1';
			oldd = Database.query(soql);
	   	    
			dealer__Deal__c newd = oldd.clone(true, false, false, true);
			oldMap.put(oldd.Id, oldd);
			newList.add(newd);

			DealProcess dp = new DealProcess(newList, oldMap);
			dp.NonVehicleCommission(newd);
			dp.DeleteProtection();
			dp.ProcessStatusChange();
			dp.sendEmailNotification('test subject', 'body text of email');
		}
		
	}


	// BLL7a 
	static testmethod void EscMethods() {
		FFAdata.refresh();
		List<dealer__Deal__c> newList = new List<dealer__Deal__c>();
		Map<Id,dealer__Deal__c> oldMap = new Map<Id,dealer__Deal__c>(); 
                        
		System.runAs(FFAdata.TestUser) {

			// Get sales up & vehicle
			dealer__Sales_Up__c dsp = [select Id, dealer__Customer_Account__c from dealer__Sales_Up__c limit 1];
			dealer__Vehicle_Inventory__c veh = [select Id from dealer__Vehicle_Inventory__c limit 1];

			Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();	// BLL1a

   		    dealer__Deal__c oldd = new dealer__Deal__c(
   		    	Name = 'Test',
	   	    	dealer__Deal_Type__c = 'Retail Vehicle Sale',	
   		    	RecordTypeId = RcdTypes.get('Retail').getRecordTypeId(), 
   		    	TaxCalcDt__c = DateTime.now(), 	
   		    	dealer__Auto_Insurance_Agent__c='Test',
	   	    	dealer__Deal_ID__c ='Test',
	   	    	dealer__Sales_Lead__c = dsp.id,
	   	    	dealer__Status__c ='Pending',
	   	    	dealer__Deal_Date__c =System.Today(),
	   	    	Proposed_Delivery_Date__c =System.Today(),
	   	    	dealer__Vehicle__c = veh.Id,
	   	    	dealer__Store_Location__c = FFAdata.DealerLocation.Id,
	   	    	Funding_option__c = 'Cash', 
	   	    	dealer__DeliveryRepairOrder__c = null,	
	   	    	dealer__Buyer__c = dsp.dealer__Customer_Account__c
	   	    );
	   	    insert oldd;
	   	    insert(new dealer__Service_Contract__c(
	   	    	dealer__Status__c = null,
	   	    	dealer__Car_Deal__c = oldd.Id,
	   	    	dealer__Odometer_at_Sale__c = 1,
	   	    	dealer__Customer__c = dsp.dealer__Customer_Account__c,
	   	    	dealer__Start_Date__c = System.today()
	   	    ));
	   	    
	   	    // Select all fields from TaxRuleSetting__c
			Map<String, Schema.SObjectField> dealFieldMap =  Schema.dealer__Deal__c.SObjectType.getDescribe().fields.getMap();
			List<String> dealFieldList = new List<String>();
			for(string f : dealFieldMap.keySet()) /* if (dealFieldMap.get(f).getDescribe().isAccessible()) */ dealFieldList.add(f);
			String dealfields = String.join(dealFieldList,',');
			String soql = 'select ' + dealfields + ' from dealer__Deal__c where Id=\'' + oldd.Id + '\' LIMIT 1';
			oldd = Database.query(soql);
	   	    
			dealer__Deal__c newd = oldd.clone(true, false, false, true);
			oldMap.put(oldd.Id, oldd);
			newList.add(newd);

			Test.startTest();
			oldd.dealer__Status__c = 'Pending';
			newd.dealer__Status__c = 'Won - Delivered';
			DealProcess dp = new DealProcess(newList, oldMap);
			dp.ProposalESCStatus();
			oldd.dealer__Status__c = 'Won - Delivered';
			newd.dealer__Status__c = 'Pending';
			dp.ProposalESCStatus();
			// won't do anything, but will get a few lines executed
			DealProcess.MarkProposalsAppraisalsLost(new Set<Id>{oldd.Id});
			DealProcess.RecalcGPSharing(new Set<Id>{oldd.Id});	
			// end of dummy calls to get a couple additional lines to execute
			Test.stopTest();

		}
		
	}


	// testVA_and_Misc
	//---------------------------------------
	static testMethod void testVA_and_Misc() {
		FFAdata.refresh();
		TestHelper_MW th = new TestHelper_MW();
		List<dealer__Deal__c> newList = new List<dealer__Deal__c>();
		Map<Id,dealer__Deal__c> oldMap = new Map<Id,dealer__Deal__c>(); 
                        
		System.runAs(FFAdata.TestUser) {
			Account tp1 = th.getThirdPartyAccount('1');
			Account tp2 = th.getThirdPartyAccount('2');
			Account tp3 = th.getThirdPartyAccount('3');

			// Get sales up & vehicle
			dealer__Sales_Up__c dsp = [select Id, dealer__Customer_Account__c from dealer__Sales_Up__c limit 1];
			dealer__Vehicle_Inventory__c veh = [select Id from dealer__Vehicle_Inventory__c limit 1];

			Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();	// BLL1a

   		    dealer__Deal__c oldd = new dealer__Deal__c(
   		    	Name = 'Test',
	   	    	dealer__Deal_Type__c = 'Retail Vehicle Sale',	
   		    	RecordTypeId = RcdTypes.get('Retail').getRecordTypeId(), 
   		    	TaxCalcDT__c = DateTime.now(), 	
   		    	dealer__Auto_Insurance_Agent__c='Test',
	   	    	dealer__Deal_ID__c ='Test',
	   	    	dealer__Sales_Lead__c = dsp.id,
	   	    	dealer__Status__c ='Won - Delivered',
	   	    	dealer__Deal_Date__c =System.Today(),
	   	    	Proposed_Delivery_Date__c =System.Today(),
	   	    	dealer__Vehicle__c = veh.Id,
	   	    	dealer__Store_Location__c = FFAdata.DealerLocation.Id,
	   	    	Funding_option__c = 'Cash', 
	   	    	dealer__DeliveryRepairOrder__c = null	
	   	    );
			oldd.Third_Party_Pay_1__c = tp1.Id;
			oldd.dealer__Deferred_Down_1__c = 10;
			oldd.Third_Party_Pay_2__c = tp2.Id;
			oldd.dealer__Deferred_Down_2__c = 10;
			oldd.Third_Party_Pay_3__c = tp3.Id;
			oldd.dealer__Deferred_Down_3__c = 10;
			oldd.VA_Deal__c = true;
			oldd.VA_Paperwork_Approved__c = true;
	   	    insert oldd;
			oldMap.put(oldd.Id, oldd);
			dealer__Deal__c newd = oldd.clone(true, false, false, true);
			newd.dealer__Status__c = 'Pending';
			newd.dealer__Deferred_Down_1__c = 11;
			newd.dealer__Deferred_Down_2__c = 11;
			newd.dealer__Deferred_Down_3__c = 11;
			newList.add(newd);

        	dealer__Service_Vehicle__c sv = new dealer__Service_Vehicle__c(
				dealer__Veh_Owner__c = dsp.dealer__Customer_Account__c,
        	    Name='Test trade', dealer__Make__c = 'Toyota', dealer__Model_Code__c = 'Sienna', dealer__Year__c = '2000',
        	    dealer__VIN__c = '12345678901234567'
        	);
        	insert(sv);
			
        	dealer__Trade_In__c t = new dealer__Trade_In__c(
        	    Name='Test trade', dealer__Make__c = 'Toyota', dealer__Model__c = 'Sienna', dealer__Year__c = '2000',
        	    dealer__VIN__c = '12345678901234567', 
        	    dealer__Car_Deal__c = oldd.Id,
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
				dealer__Vehicle_Owner__c = dsp.dealer__Customer_Account__c,
				dealer__Status__c = 'Pending'
			);
			insert(ap);


			Test.startTest();

			Set<String> fieldset = DealProcess.DealFieldsToRetrieve();

			DealProcess dp = new DealProcess(newList, oldMap);
			dp.ProposalIntegrity();
			dp.VehiclesNotSoldAnymore();

			oldd.dealer__Status__c = 'Won - Delivery';
			newd.dealer__Status__c = 'Won - Delivered';
			dp = new DealProcess(newList, oldMap);
			dp.ProposalIntegrity();
			
			update(oldd);
			newd = oldd.clone(true, false, false, true);
			newList = new List<dealer__Deal__c>();
			newList.add(newd);
			dp = new DealProcess(newList, oldMap);
			dp.ProposalIntegrity();
			dp.PostingEntries();

			Test.stopTest();	

		}
	}
	
}