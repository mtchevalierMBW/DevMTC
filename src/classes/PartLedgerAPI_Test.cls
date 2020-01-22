@isTest
private class PartLedgerAPI_Test {

	@testSetup
	static void createTestData() {

		// Create location, master and part
        dealer__Dealer_Location__c loc = dealer.TestClassUtil.insertDealerLocation('DT1', 'DealerTeam Motors');	

		dealer__Parts_Master__c pm = new dealer__Parts_Master__c();
		pm.Name = 'Oil Filter';
		pm.dealer__Retail_Price__c = 100;
		pm.dealer__Manufacturer__c = 'FD';            
		insert pm;

		// Create a Test Part
		dealer__Parts_Inventory__c part = new dealer__Parts_Inventory__c();
		part.dealer__Description__c = 'Oil Filter';
		part.dealer__Cost__c = 10;
		part.dealer__Source__c = 'Stocking';
		part.dealer__On_Hand__c = 1;
		part.dealer__Part_No__c = 'FL1A-XX';
		part.dealer__List__c = 22;
		part.dealer__Parts_Master__c = pm.Id;
		part.dealer__Location__c=loc.Id;
		insert part;		

		// -- Heavy Lift, create all of the necessary history for this part. //
		
		// 1) dataload
		//dealer__Part__c, dealer__Cost__c, dealer__Quantity_Adjustment__c, dealer__Transaction_Event__c, dealer__Transaction_Time__c
		dealer__Part_Inventory_History__c pih = new dealer__Part_Inventory_History__c(
				dealer__Part__c=part.Id,
				dealer__Cost__c=100,
				dealer__Quantity_Adjustment__c=1,
				dealer__Transaction_Event__c='Data Load',
				dealer__Transaction_Time__c=DateTime.now()
		); 	
		insert pih;

		// 2) Purchase Lines
		PartLedgerAPI_Test.createPurhcaseLines(part);

		// 3) Sales Lines
		

	}

	static testmethod void testLedgerRebuild() {
		dealer__Parts_Inventory__c pi = [SELECT Id FROM dealer__Parts_Inventory__c LIMIT 1];
		PartLedgerAPI.rebuiltLedgerReportingTable(pi.Id);
	}

	static testmethod void testPartRegisterEXT() {
		dealer__Parts_Inventory__c pi = [SELECT Id FROM dealer__Parts_Inventory__c LIMIT 1];
		PartRegister_EXT.register(pi.Id);
	}

	static private void createPurhcaseLines(dealer__Parts_Inventory__c part) {
        
		Account accRec = new Account();
        accRec.Name = 'Test Account';
        accRec.Type = 'Customer - Direct';
        accRec.dealer__Vendor__c = true;
        insert accRec;

        dealer__Purchase_Order__c po = new dealer__Purchase_Order__c();
        po.dealer__Vendor__c = accRec.Id;
        po.dealer__Vendor_Email__c = 'test@gmail.com';
        insert po;		

        dealer__Purchase_Order_Line__c poline = new dealer__Purchase_Order_Line__c();
        poline.dealer__Purchase_Order__c = po.id;
        poline.dealer__Part__c = part.Id;
        poline.dealer__Part_Quantity__c =1;
        poline.dealer__Amount__c = 111;
        insert poline;		


	}
}