/**
 * VehicleInvMassUpload_TEST
 * Tests: VehicleInvMassUpload
 * Date: May 30, 2018
 * Programmer: Bryan Leaman
 *
 * Modification Log:
 *
 */
@isTest
private class VehicleInvMassUpload_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupTest() {
		TestHelper_MW th = new TestHelper_MW();
		TestHelper_MW.createBaseFFAData(FFAdata);
		FFAdata.refresh(); 
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();

		// GeneralLedgerAccount 
		c2g__codaGeneralLedgerAccount__c gla = new c2g__codaGeneralLedgerAccount__c(
			Name='1299 - VehicleGL',
			c2g__ReportingCode__c = '1299',
			c2g__Type__c='Balance Sheet'
		);
		insert(gla);
		
		// Vehicle template
		Map<String, Schema.RecordTypeInfo> viRcdTypes = Schema.SObjectType.dealer__Vehicle_Inventory__c.getRecordTypeInfosByName();
		Schema.RecordTypeInfo TmpltRtInfo = viRcdTypes.get('Vehicle Template');
        insert(new dealer__Vehicle_Inventory__c(
        	RecordTypeId = TmpltRtInfo.getRecordTypeId(),
        	dealer__VIN__c = 'testingxyz',
        	dealer__Stock_Number__c = 'Test#xyz',
        	dealer__Year__c = '2020',
        	dealer__Make__c = 'Toyota',
        	dealer__Model__c = 'tbd',
        	dealer__Purchase_Date__c = Date.today(),
        	Conv_MFG__c = 'BraunAbility'
        ));
	
	}

	// unitTest
	//---------------------------------------
	static testMethod void TestWithoutPo() {
		//FFAdata.refresh(); 
		//System.runAs(FFAdata.TestUser) {
        //	TestHelper_MW th = new TestHelper_MW();

			String csvdata = 'RecordTypeId,VIN,dealer__Stock_Number__c,dealer__Year__c,dealer__Make__c,dealer__Model__c\n'
				+ 'Used,1234567890ABCDEFG,TEST123,2020,Toyota,MegaSeller\n'
				+ 'Used,234567890ABCDEFGH,TEST123,2020,Toyota,MegaSeller\n';
			VehicleInvMassUpload vimu = new VehicleInvMassUpload();
			List<VehicleInvMassUpload.VehicleUploadWrapper> vehl = vimu.CreateVehicleList(csvdata);
			System.assertEquals(2, vehl.size(), 'Did not get expected vehicle count from csv data');

			vimu.startOver();
			vimu.noAction();
			vimu.createPoOption = 'None';
			vimu.csvBlob = Blob.valueOf(csvdata);
			vimu.fileName = 'test.csv';
			vimu.submitCsv();
			vimu.reEdit();
			System.assert(vimu.readyRcds != null && vimu.errorRcds != null, 'Did not complete validation properly');
			System.debug(vimu.readyRcds.size());
			System.debug(vimu.errorRcds.size());
			System.assertEquals(vehl.size(),vimu.readyRcds.size()+vimu.errorRcds.size(), 
				'Number of error plus good records did not equal number of vehicles to upload');
			System.assertEquals(1, vimu.readyRcds.size(), 'Number of vehicle records ready to create is NOT correct');
			System.assertEquals(1, vimu.errorRcds.size(), 'Number of vehicle records in error is NOT correct');
			vimu.processUpload();
			
			// Note: field=>value map requires field names to be lowercase
			dealer__Vehicle_Inventory__c newveh = vimu.MapColValuesToNewVeh(
				new Map<String,String>{'dealer__make__c'=>'VehicleMake', 'dealer__model__c'=>'VehicleModel'},
				new dealer__Vehicle_Inventory__c(dealer__Year__c='2020')
			);
			System.assert(newveh.dealer__Year__c=='2020', 'New vehicle record does not contain value from template.');		
			System.assert(newveh.dealer__Make__c=='VehicleMake', 'New vehicle record does not contain vehicle make from data.');		
			System.assert(newveh.dealer__Model__c=='VehicleModel', 'New vehicle record does not contain vehicle make from data.');		
							
			dealer__Vehicle_Inventory__c tmp = [select Id from dealer__Vehicle_Inventory__c where Conv_MFG__c='BraunAbility' limit 1];
			dealer__Vehicle_Inventory__c tmplt = vimu.LoadVehicleTemplate(tmp.Id);
			System.assert(tmplt.Conv_MFG__c=='BraunAbility', 'Did not load vehicle template correctly.');	
		//}
	}
	


	// TestWithPO
	//---------------------------------------
	static testMethod void TestWithPO() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
			Account v = th.getVendorAccount('1');

			c2g__codaGeneralLedgerAccount__c gla = [select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c limit 1];
			GeneralLedgerAcctMW__c glamw = [select Id, Name from GeneralLedgerAcctMW__c limit 1];
	
			String csvdata = 'RecordTypeId,Company,VIN,dealer__Stock_Number__c,dealer__Year__c,dealer__Make__c,dealer__Model__c,Chassis Cost,Conversion Cost,New_Used_Other__c,dealer__Inventory_Date__c\n'
				+ 'Used,TestLoc,1234567890ABCDEFG,TEST1234,2020,Toyota,MegaSeller,10000,9000,Used,1/1/2018\n'
				+ 'Used,TestLoc,234567890ABCDEFGH,TEST1235,2020,Toyota,MegaSeller,8000,6500,Used,1/1/2018\n';
			VehicleInvMassUpload vimu = new VehicleInvMassUpload();
			List<VehicleInvMassUpload.VehicleUploadWrapper> vehl = vimu.CreateVehicleList(csvdata);
			System.assertEquals(2, vehl.size(), 'Did not get expected vehicle count from csv data');

			vimu.startOver();
			vimu.csvBlob = Blob.valueOf(csvdata);
			vimu.fileName = 'test.csv';
			vimu.submitCsv();
			vimu.createPoOption = 'Combined';
			System.debug(vimu.readyRcds);
			System.assert(vimu.readyRcds != null && vimu.errorRcds != null, 'Did not complete validation properly');
			System.debug(vimu.readyRcds.size());
			System.debug(vimu.errorRcds.size());
			System.assertEquals(vehl.size(),vimu.readyRcds.size()+vimu.errorRcds.size(), 
				'Number of error plus good records did not equal number of vehicles to upload');
			System.assertEquals(2, vimu.readyRcds.size(), 'Number of vehicle records ready to create is NOT correct');
			System.assertEquals(0, vimu.errorRcds.size(), 'Number of vehicle records in error is NOT correct');
			
			vimu.chassisPO.dealer__Vendor__c = v.Id;
			vimu.conversionPO.dealer__Vendor__c = v.Id;
			vimu.ChassisFFRefs.GeneralLedgerAcct__c = glamw.Id;
			vimu.ConversionFFRefs.GeneralLedgerAcct__c = glamw.Id;
			vimu.ChassisContraFFRefs.GeneralLedgerAcct__c = glamw.Id;
			vimu.ConversionContraFFRefs.GeneralLedgerAcct__c = glamw.Id;
			vimu.processUpload();
			
			// Note: field=>value map requires field names to be lowercase
			dealer__Vehicle_Inventory__c newveh = vimu.MapColValuesToNewVeh(
				new Map<String,String>{'dealer__make__c'=>'VehicleMake', 'dealer__model__c'=>'VehicleModel'},
				new dealer__Vehicle_Inventory__c(dealer__Year__c='2020')
			);
			System.assert(newveh.dealer__Year__c=='2020', 'New vehicle record does not contain value from template.');		
			System.assert(newveh.dealer__Make__c=='VehicleMake', 'New vehicle record does not contain vehicle make from data.');		
			System.assert(newveh.dealer__Model__c=='VehicleModel', 'New vehicle record does not contain vehicle make from data.');		
							
			dealer__Vehicle_Inventory__c tmp = [select Id from dealer__Vehicle_Inventory__c where Conv_MFG__c='BraunAbility' limit 1];
			dealer__Vehicle_Inventory__c tmplt = vimu.LoadVehicleTemplate(tmp.Id);
			System.assert(tmplt.Conv_MFG__c=='BraunAbility', 'Did not load vehicle template correctly.');	
		}
	}

	// ctrlExtTest
	//---------------------------------------
	//static testMethod void ctrlExtTest() {
	//	FFAdata.refresh(); 
	//	System.runAs(FFAdata.TestUser) {
    //   	TestHelper_MW th = new TestHelper_MW();
	//
	//		//dealer__Vehicle_Inventory__c veh = new dealer__Vehicle_Inventory__c();
	//		//PageReference pgRef = Page.{pagename}; 
	//		//Test.setCurrentPage(pgRef); //Set the page for Test Method
	//		//ApexPages.currentPage().getParameters().put('id', veh.id);
	//		//ApexPages.StandardController sc = new ApexPages.StandardController(veh);
	//		//VehicleInvMassUpload lc = new VehicleInvMassUpload(sc);
	//	}
	//}

}