/**
 * VehicleFlooring_CTRL_TEST
 * Tests: VehicleFlooring_CTRL_TEST
 * Date: Mar 15, 2018
 * Programmer: Bryan Leaman
 *
 *	2018-08-16	B. Leaman	BLL1 - setup bank accounts to reference the 1001 GLA used.
 */
@isTest
private class VehicleFlooring_CTRL_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		//FFAdata.refresh(); 
        //dealer.TestClassUtil tc = new dealer.TestClassUtil();
        //tc.insertDMSSettings();
		System.runAs(FFAdata.TestUser) {

	        c2g__codaCompany__c comp = [select Id, Name, c2g__ExternalId__c from c2g__codaCompany__c limit 1];
	        comp.c2g__ExternalId__c = 'WMK';
	        update(comp);
	        System.debug(comp);
	        c2g__codaDimension1__c dim1 = new c2g__codaDimension1__c(Name='Dimension 100', c2g__ReportingCode__c='100');
	        insert(dim1);
	        System.debug(dim1);
	        
	        List<c2g__codaGeneralLedgerAccount__c> glaccts = new List<c2g__codaGeneralLedgerAccount__c>();
	        glaccts.add(new c2g__codaGeneralLedgerAccount__c(Name='1001', c2g__ReportingCode__c='1001', c2g__Type__c='Manual Journal'));
	        glaccts.add(new c2g__codaGeneralLedgerAccount__c(Name='2500', c2g__ReportingCode__c='2500', c2g__Type__c='Manual Journal'));
	        glaccts.add(new c2g__codaGeneralLedgerAccount__c(Name='2505', c2g__ReportingCode__c='2505', c2g__Type__c='Manual Journal'));
	        glaccts.add(new c2g__codaGeneralLedgerAccount__c(Name='2510', c2g__ReportingCode__c='2510', c2g__Type__c='Manual Journal'));
	        glaccts.add(new c2g__codaGeneralLedgerAccount__c(Name='2515', c2g__ReportingCode__c='2515', c2g__Type__c='Manual Journal'));
			insert(glaccts);
	
		    // BLL1a - Need bank account for GLA 1001 journal entries
		    c2g__codaGeneralLedgerAccount__c gla1001 = [select Id from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c='1001'];
		    c2g__codaBankAccount__c bank = new c2g__codaBankAccount__c(
		    	Name='Test Bank', c2g__ReportingCode__c='1001CH', c2g__BankName__c='Test Bank',
		    	c2g__AccountName__c='CompanyAcct', c2g__AccountNumber__c='123456789',
		    	c2g__BankAccountCurrency__c=FFAData.HomeCurrency.Id,
		    	c2g__OwnerCompany__c = FFAData.CurrentCompany.Id,
		    	c2g__GeneralLedgerAccount__c = gla1001.id
		    );
		    insert(bank);
		    // BLL1a end
	        
	        List<dealer__Vehicle_Inventory__c> vehicles = new List<dealer__Vehicle_Inventory__c>();
	        
	        dealer__Vehicle_Inventory__c v1 = new dealer__Vehicle_Inventory__c(
	        	dealer__VIN__c = 'TEST1234567890ABC',
	        	dealer__Stock_Number__c = '890ABC',
	        	dealer__Make__c = 'Toyota',
	        	dealer__Model__c = 'FutureVan',
	        	dealer__Year__c = '2020',
	        	Chassis_Floorplan__c = 'Not Floored - Paperwork'
	        );
	        vehicles.add(v1);
	        dealer__Vehicle_Inventory__c v2 = new dealer__Vehicle_Inventory__c(
	        	dealer__VIN__c = 'TEST1234567891ABC',
        		dealer__Stock_Number__c = '891ABC',
        		dealer__Make__c = 'Toyota',
        		dealer__Model__c = 'FutureVan',
        		dealer__Year__c = '2021',
        		Floorplanned__c = true,
        		Paid__c = false,
        		Chassis_Floorplan__c = 'Huntington Used',
        		Original_Floored_Amount__c = 30000,
        		Current_Floored_Amount__c = 15000 
        	);
        	vehicles.add(v2);
        	dealer__Vehicle_Inventory__c v3 = new dealer__Vehicle_Inventory__c(
        		dealer__VIN__c = 'TEST1234567892ABC',
        		dealer__Stock_Number__c = '892ABC',
        		dealer__Make__c = 'Toyota',
        		dealer__Model__c = 'FutureVan',
        		dealer__Year__c = '2022',
        		Floorplanned__c = true,
        		Paid__c = false,
        		Chassis_Floorplan__c = 'Huntington Used',
        		Original_Floored_Amount__c = 30000,
        		Current_Floored_Amount__c = 15000 
        	);
        	vehicles.add(v3);
        	insert(vehicles);
		}
	}

	// flooredTest
	//---------------------------------------
	static testMethod void flooredTest() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
			
			VehicleFlooring_CTRL vf = new VehicleFlooring_CTRL();
			vf.uploadType = 'floored';
			vf.uploadData = Blob.valueOf('vin_nbr,cltr_cd,princ_rqst_amt,orig_amt_rqst\n'
				+ 'TEST1234567890ABC,USEDB,30000,30000');
			vf.uploadFilename = 'test.csv';
			System.assertEquals(false, vf.haveData, 'haveData indicates data has been uploaded already');
			vf.submitCSV();
			System.assertEquals(true, vf.haveData, 'haveData indicates data has NOT been uploaded');
			vf.processUpload();
			
			Map<Id,String> vehupdates = new Map<Id,String>();
			for(VehicleFlooring_CTRL.FlooringUploadData fud : vf.FlooringData) {
				vehupdates.put(fud.VehId, JSON.serialize(fud));
			}
			String payloadStr = vf.generatePayload(vehupdates);
			AccountingEmailService.AccountingPayload payload = (AccountingEmailService.AccountingPayload)JSON.deserializeStrict(payloadStr ,AccountingEmailService.AccountingPayload.class);
			vehicleFlooring_CTRL.CreateAndPostJournal(vf.uploadType, UserInfo.getUserEmail(), payload.details);
			
		}
	}


	// curtailmentTest
	//---------------------------------------
	static testMethod void curtailmentTest() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
    		TestHelper_MW th = new TestHelper_MW();
			
			VehicleFlooring_CTRL vf = new VehicleFlooring_CTRL();
			vf.uploadType = 'curtailment';
			vf.uploadData = Blob.valueOf('serial_nbr,stock_nbr,pmt_amt,curr_princ_amt\n'
				+ 'TEST1234567891ABC,891ABC,200,5000');
			vf.uploadFilename = 'test.csv';
			System.assertEquals(false, vf.haveData, 'haveData indicates data has been uploaded already');
			vf.submitCSV();
			System.assertEquals(true, vf.haveData, 'haveData indicates data has NOT been uploaded');
			vf.processUpload();
	
			Map<Id,String> vehupdates = new Map<Id,String>();
			for(VehicleFlooring_CTRL.FlooringUploadData fud : vf.FlooringData) {
				vehupdates.put(fud.VehId, JSON.serialize(fud));
			}
			String payloadStr = vf.generatePayload(vehupdates);
			AccountingEmailService.AccountingPayload payload = (AccountingEmailService.AccountingPayload)JSON.deserializeStrict(payloadStr ,AccountingEmailService.AccountingPayload.class);
			vehicleFlooring_CTRL.CreateAndPostJournal(vf.uploadType, UserInfo.getUserEmail(), payload.details);
			
		}
	}


	// payoffTest
	//---------------------------------------
	static testMethod void payoffTest() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
			
			VehicleFlooring_CTRL vf = new VehicleFlooring_CTRL();
			vf.uploadType = 'payoff';
			vf.uploadData = Blob.valueOf('serial_nbr,stock_nbr,pmt_amt\n'
				+ 'TEST1234567892ABC,890ABC,15000');
			vf.uploadFilename = 'test.csv';
			System.assertEquals(false, vf.haveData, 'haveData indicates data has been uploaded already');
			vf.submitCSV();
			System.assertEquals(true, vf.haveData, 'haveData indicates data has NOT been uploaded');
			vf.processUpload();

			Map<Id,String> vehupdates = new Map<Id,String>();
			for(VehicleFlooring_CTRL.FlooringUploadData fud : vf.FlooringData) {
				vehupdates.put(fud.VehId, JSON.serialize(fud));
			}
			String payloadStr = vf.generatePayload(vehupdates);
			AccountingEmailService.AccountingPayload payload = (AccountingEmailService.AccountingPayload)JSON.deserializeStrict(payloadStr ,AccountingEmailService.AccountingPayload.class);
			vehicleFlooring_CTRL.CreateAndPostJournal(vf.uploadType, UserInfo.getUserEmail(), payload.details);
			
		}
	}

}