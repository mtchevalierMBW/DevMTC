/**
 * CommercialQuoteProc_TEST
 * Tests: CommercialQuoteProcess // OppTrigger, SolOppTrigger, CommercialQuoteTrigger 
 * Programmer: Bryan Leaman
 * Date: 2016-02-19
 *
 *	2016-05-12	B. Leaman	BLL1 - Test notify manager of repair order routine.
 *	2018-04-30	B. Leaman	BLL2 - new required field on opportunity -- Sales_Channel__c. 
 */
@isTest
private class CommercialQuoteProc_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); // BLL1

	@testSetup
	private static void setupTestData() {
		TestHelper_MW.createBaseFFAData(FFAdata);

		TestHelper_MW th = new TestHelper_MW();
		
		MW_TriggerControls__c lostOpportunity = new MW_TriggerControls__c(Name='LostOpportunity', Enabled__c=true);
		MW_TriggerControls__c lostSolutionOpp = new MW_TriggerControls__c(Name='LostSolutionOpp', Enabled__c=true);
		MW_TriggerControls__c wonCommercialQuote = new MW_TriggerControls__c(Name='WonCommercialQuote', Enabled__c=true);

	     dealer.TestClassUtil tc = new dealer.TestClassUtil();
	     tc.insertDMSSettings();
        dealer__FixedOperationsSettings__c fixedOpsSettings = new dealer__FixedOperationsSettings__c(
        	dealer__Repair_Order_Index__c=1
        );
        insert(fixedOpsSettings); 

		System.runAs(FFAdata.TestUser) {
			Account a = th.getBusinessAccount('1');
			dealer__Vehicle_Inventory__c v = new dealer__Vehicle_Inventory__c(
				dealer__VIN__c = '11122233344455566', dealer__Stock_Number__c = '55566B',
				dealer__Year__c='2021', dealer__Make__c='Toyota', dealer__Model__c='Futuristic',
				New_Used_Other__c='Used', Division__c='Commercial',
				dealer__Store_Location__c=FFAdata.DealerLocation.Id
			);
			insert(v);
			Opportunity o = new Opportunity(
				Name='Test commercial opp', AccountId=a.Id, StageName='Pending', CloseDate=Date.today(),
				Sales_Channel__c = 'MBW N/A'	// BLL1a
			);
			insert(o);
			dealer__Sales_Up__c su = new dealer__Sales_Up__c(
				Name='Test sales up', dealer__Customer_Account__c = a.Id, dealer__Lead_Status__c='Pending'
			);
			insert(su);
   	    	CommercialQuote__c cq = new CommercialQuote__c(
	            Salesperson__c = UserInfo.getUserId(),
	            Status__c='Pending',
	            Opportunity__c = o.Id,
	            SolutionOpportunity__c = su.Id,
	            VehicleInventory__c = v.Id,
	            Location__c=FFAdata.DealerLocation.Id
	        );
	        insert(cq);
	        
			Map<String, Schema.RecordTypeInfo> cqoRcdTypes = Schema.SObjectType.Commercial_Quote_Options__c.getRecordTypeInfosByName();
			//cqoRcdTypes.get('rtname').getRecordTypeId();
	        
	        Commercial_Quote_Options__c cqo1 = new Commercial_Quote_Options__c(
	        	Name='Chassis 1', RecordTypeId=cqoRcdTypes.get('Chassis Options').getRecordTypeId(), 
	        	Description__c='Chassis option 1',
	        	Cost__c=12000, Selling_Price__c=14000, Freight__c=300, 
	        	Vehicle_Manufacturer__c='Ford', Wheelbase__c='Regular'
	        );
	        insert(cqo1);
	        Commercial_Quote_Options__c cqo2 = new Commercial_Quote_Options__c(
	        	Name='SafetyNet', RecordTypeId=cqoRcdTypes.get('Interior Upgrades').getRecordTypeId(), 
	        	Description__c='Interior safety net',
	        	Cost__c=1200, Selling_Price__c=1400, Freight__c=0, 
	        	Vehicle_Manufacturer__c='Ford', Wheelbase__c='Regular'
	        );
	        insert(cqo2);
	        Commercial_Quote_Options__c cqo3 = new Commercial_Quote_Options__c(
	        	Name='SafetyNet', RecordTypeId=cqoRcdTypes.get('Exterior Upgrades').getRecordTypeId(), 
	        	Description__c='Exterior safety net',
	        	Cost__c=1200, Selling_Price__c=1400, Freight__c=0, 
	        	Vehicle_Manufacturer__c='Ford', Wheelbase__c='Regular'
	        );
	        insert(cqo3);

			VehicleInventory_CommercialOption__c vico = new VehicleInventory_CommercialOption__c(
				CommercialQuoteOption__c=cqo1.Id,
				VehicleInventory__c=v.Id,
				Cost__c=12000, SellingPrice__c=14000, OptionType__c='Chassis Options',
				Quantity__c=1, Description__c=cqo1.Description__c
			);
			insert(vico);

			CommercialQuoteLine__c line1 = new CommercialQuoteLine__c(
				Commercial_Quote__c=cq.Id,
				Commercial_Quote_Options__c=cqo2.Id,
				Cost__c=cqo2.Cost__c, Selling_Price__c=cqo2.Selling_Price__c,
				Quantity__c=1, Line_Type__c='Interior Upgrades',
				Description__c=cqo2.Description__c
			);
			insert(line1);	
			CommercialQuoteLine__c line2 = new CommercialQuoteLine__c(
				Commercial_Quote__c=cq.Id,
				Commercial_Quote_Options__c=cqo3.Id,
				Cost__c=cqo3.Cost__c, Selling_Price__c=cqo3.Selling_Price__c,
				Quantity__c=1, Line_Type__c='Exterior Upgrades',
				Description__c=cqo3.Description__c
			);
			insert(line2);	
			
		}
	}

	private static testMethod void unitTestWonQuote() {
		FFAdata.refresh();
		System.runAs(FFAdata.TestUser) {
			CommercialQuote__c cq1 = [
				select Id, Status__c, Salesperson__c, Opportunity__c, SolutionOpportunity__c, VehicleInventory__c, Location__c
				from CommercialQuote__c
				limit 1
			];
			CommercialQuote__c cq2 = cq1.clone(true,false,true,true);
			cq1.Status__c = 'Won';
			Map<Id, CommercialQuote__c> oldMap = new Map<Id, CommercialQuote__c>();
			List<CommercialQuote__c> newList = new List<CommercialQuote__c>();
			// Use cq1 as the "new" since it will have the lines to create the RO from
			oldMap.put(cq1.Id, cq2);
			newList.add(cq1);
			CommercialQuoteProcess.WonCommercialQuote(newList, oldMap);
			CommercialQuoteProcess.WonCommercialVehicle(newList, oldMap);
			CommercialQuoteProcess.AutoCreateDeliveryRO(newList, oldMap);

			cq1.Status__c = 'Delivered';
			CommercialQuoteProcess.DeliveredCommercialVehicle(newList, oldMap);
			CommercialQuoteProcess.CreatePostingEntry(newList, oldMap);
		}
	}

	private static testMethod void unitTestLostSolOpp() {
		FFAdata.refresh();
		System.runAs(FFAdata.TestUser) {
			dealer__Sales_Up__c su1 = [
				select Id, Name, dealer__Customer_Account__c, dealer__Lead_Status__c
				from dealer__Sales_Up__c
				limit 1
			]; 
			dealer__Sales_Up__c su2 = su1.clone(true,false,true,true);
			su1.dealer__Lead_Status__c = 'Pending';
			su2.dealer__Lead_Status__c = 'Lost';
			Map<Id, dealer__Sales_Up__c> oldMap = new Map<Id, dealer__Sales_Up__c>();
			Map<Id, dealer__Sales_Up__c> newMap = new Map<Id, dealer__Sales_Up__c>();
			oldMap.put(su1.Id, su1);
			newMap.put(su2.Id, su2);
			CommercialQuoteProcess.LostSolutionOpportunity(newMap, oldMap);
		}
	}

	private static testMethod void unitTestLostOpp() {
		FFAdata.refresh();
		System.runAs(FFAdata.TestUser) {
			Opportunity opp1 = [
				select Id, Name, StageName
				from Opportunity
				limit 1
			]; 
			Opportunity opp2 = opp1.clone(true,false,true,true);
			opp1.StageName = 'Pending';
			opp2.StageName = 'Lost';
			Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();
			Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();
			oldMap.put(opp1.Id, opp1);
			newMap.put(opp2.Id, opp2);
			CommercialQuoteProcess.LostOpportunity(newMap, oldMap);
		}
	}

	private static testMethod void testCreateRO() {
		FFAdata.refresh();
		System.runAs(FFAdata.TestUser) {
			CommercialQuote__c cq = [
				select Id, Status__c, Location__c, Customer__c, ServiceRepairOrder__c, Salesperson__c, Opportunity__c, SolutionOpportunity__c, VehicleInventory__c
				from CommercialQuote__c
				limit 1
			];
			CommercialQuoteProcess.CreateROFromCommercialQuote(cq);
			CommercialQuoteProcess.NotifyManagerOfRepairOrder(cq);	// BLL1a 
		}
	}

}