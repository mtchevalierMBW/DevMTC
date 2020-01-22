@isTest (seeAllData=true)
private class Test_ImportPartData {


	static testmethod void testImportPartData() {
		
		// Create the base parts used in this test	
		/*	
			dealer__Parts_Inventory__c p = new dealer__Parts_Inventory__c();
			p.Name = 'ADAPTSHIFT';
			p.dealer__Part_No__c  = 'CHO:ADA:ADAPTSHIFT';
			p.dealer__Description__c = 'Test Part Trigger';
			p.dealer__MFG__c = 'ADA';
			p.dealer__Cost__c= 99;
			p.dealer__List__c= 129;
			p.dealer__Pack_QTY__c = 0;
			p.dealer__Company_Number__c = 'CHO';

			insert p;

			dealer__Parts_Inventory__c p1 = new dealer__Parts_Inventory__c();
			p1.Name = 'H-370-525-HF';
			p1.dealer__Part_No__c  = 'OAK:AMF:H-370-525-HF';
			p1.dealer__Description__c = 'Test Part Trigger';
			p1.dealer__MFG__c = 'AMF';
			p1.dealer__Cost__c= 99;
			p1.dealer__List__c= 129;
			p1.dealer__Pack_QTY__c = 0;
			p1.dealer__Company_Number__c = 'OAK';

			insert p1;

			dealer__Parts_Inventory__c p2 = new dealer__Parts_Inventory__c();
			p2.Name = 'H-370-525-HV';
			p2.dealer__Part_No__c  = 'BUR:AMF:H-370-525-HV';
			p2.dealer__Description__c = 'Test Part Trigger';
			p2.dealer__MFG__c = 'AMF';
			p2.dealer__Cost__c= 99;
			p2.dealer__List__c= 129;
			p2.dealer__Pack_QTY__c = 0;
			p2.dealer__Company_Number__c = 'BUR';

			insert p2;
		*/			

		ImportPartData ipd = new ImportPartData();

		// Build CSV String
		String 	csv = 'Part,OnHand,Net,Relief,Event,RcvDate,Company,LegacyPart';
			   	csv += 'CHO:ADA:ADAPTSHIFT,1,95,FALSE,Data Load,2013-02-06T16:00:00.000Z,CHO,ADA-ADAPTSHIFT';
				csv += 'OAK:AMF:H-370-525-HF,2,184,FALSE,Data Load,2015-08-14T16:00:00.000Z,OAK,AMF-H-370-525-HF';
				csv += 'BUR:AMF:H-370-525-HV,1,184,FALSE,Data Load,2015-07-21T16:00:00.000Z,BUR,AMF-H-370-525-HV';


		// Set blob based on String
		ipd.csvFileBody = Blob.valueOf(csv);

		// Test Errors
		ipd.createHistory();
		

		// Iterate Locations
		dealer__Dealer_Location__c l = ipd.location;
		ipd.locationList();

		// Build History
		List<dealer__Parts_Ledger__c> lLines = ipd.getLedgerLines();
		ipd.buildLedger();

		// Create History
		ipd.createHistory();

		// Build Parts
		ipd.buildPartsInventory();


	}
}