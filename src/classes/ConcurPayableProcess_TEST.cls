/**
 * ConcurPayableProcess_TEST
 * Tests: ConcurPayableProcess_TEST
 * Date: Jul 19, 2018
 * Programmer: Bryan Leaman
 *
 */
@isTest
private class ConcurPayableProcess_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);

		TestHelper_MW th = new TestHelper_MW();
		th.createGeneralLedgerAccounts(new List<String>{'1220','2115','2100','4905','5304','4950'});
		
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();

		System.runAs(FFAdata.TestUser) {
			Account vendor = th.getVendorAccount('1');
			th.CreateTestPOData('Parts Purchase', FFAData.DealerLocation, vendor, 995);			
		}
		
	}

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
			ConcurPayableProcess cpp = new ConcurPayableProcess();
			List<dealer__Purchase_Order__c> POList = [
				select Id, Name, dealer__PO_Number__c, dealer__Status__c, dealer__Post_Date_Time__c,   
					dealer__Vendor__c, dealer__Vendor__r.Name, dealer__Vendor__r.c2g__CODADaysOffset1__c, dealer__PO_Accounting_Name__c, dealer__Invoice_Number__c, 
					Payable_Invoice__c, dealer__Invoice_Amount__c, dealer__Invoice_Date__c,
					dealer__Company__c, dealer__Company__r.Financial_Force_Dimension_1__c,
					dealer__Company__r.Company__c, dealer__Company__r.Company__r.DefaultPayableDimension1__c, 
					Parts_Amount__c, dealer__Freight__c, NMEDA_Fee__c, Misc_Charge__c,
					dealer__PO_Amount__c, dealer__Type__c, RecordTypeId
				from dealer__Purchase_Order__c
			];
			Map<String, List<dealer__Purchase_Order__c>> poMapByCmp = cpp.ChunkPOsByCompany(POList, 50);
			cpp.ProcessPurchaseInvoices(poMapByCmp.values()[0]);
		}
	}


	static testMethod void testUpload() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();
			dealer__Purchase_Order__c po = [
				select Id, Name, dealer__PO_Number__c, dealer__Status__c, dealer__Post_Date_Time__c,   
					dealer__Vendor__c, dealer__Vendor__r.Name, dealer__Vendor__r.c2g__CODADaysOffset1__c, dealer__PO_Accounting_Name__c, dealer__Invoice_Number__c, 
					Payable_Invoice__c, dealer__Invoice_Amount__c, dealer__Invoice_Date__c,
					dealer__Company__c, dealer__Company__r.Financial_Force_Dimension_1__c,
					dealer__Company__r.Company__c, dealer__Company__r.Company__r.DefaultPayableDimension1__c, 
					Parts_Amount__c, dealer__Freight__c, NMEDA_Fee__c, Misc_Charge__c,
					dealer__PO_Amount__c, dealer__Type__c, RecordTypeId
				from dealer__Purchase_Order__c
				limit 1
			];
			String isodate = DateTime.now().format('yyyy-MM-dd');
			ConcurPayableUpload cpu = new ConcurPayableUpload();
			String data = 'EXTRACT|4|yyyy-mm-dd|2|995.0000\n'
				+ 'DETAIL|33|*MW PO Policy|The Braun Corporation (BRACOR)-717567||717567|yyyy-mm-dd|yyyy-mm-dd|442.0000|442.0000|yyyy-mm-dd|yyyy-mm-dd|ponumber|115||||||||||||||||||||||||||||||||US|US|Y|9.0000|0.0000|79C0E6C7D9AC4513B63F|yyyy-mm-dd|CLIENT|||||9.0000|SAGE|SAGE|2115|433.0000|442.0000|DR|USD|840|US, Dollar|2115|||||||||||||||||||||79||0727543538||1.0000|invoiceap|invoiceap@mobilityworks.com|AP||Invoice||N||||||||||||||||||||Mid-West|155|||||US|US|ponumber|1|180627419099|1|1|ASSEMBLY MOTOR RAMP KLAUBER 12V 1.2 RPM KIT SHIPOUT|2000   |Unbilled|1.0000|433.0000|433.0000||||||||||||||||||||||||51654AK2907KS||The Braun Corporation|BRACOR|BRACOR|8C41B2D9230B467EB91E|39014 Eagle Way|||Chicago|IL|60678-1390|US|||||||||||||||||||N|||||||||||||||||||0.0000||0.0000||0.0000||0.0000|||||0.0000|0.0000||||||N|||||||||||||||||0.0000|0.0000|0.0000|||442.0000|0.0000||433.0000|\n'
				+ 'DETAIL|34|*MW PO Policy|The Braun Corporation (BRACOR)-718012||718012|yyyy-mm-dd|yyyy-mm-dd|553.0000|553.0000|yyyy-mm-dd|yyyy-mm-dd|ponumber|171|||||||||||||||||||||US|||||||||||US|US|Y|182.9600|0.0000|988505E63CA14029AA4E|yyyy-mm-dd|CLIENT|||||182.9600|SAGE|SAGE|2115|75.0000|553.0000|DR|USD|840|US, Dollar|2115|||||||||||||||||||||80||0710535313||1.0000|invoiceap|invoiceap@mobilityworks.com|AP||Invoice||N||||||||||||||||||||Mid-West|155|||||US|US|ponumber|1|180615411621|1|1|KIT CENTER ROW VINYL SEAT / ADA MANUAL SHIP OUT|2000   |Unbilled|1.0000|75.0000|75.0000||||||||||||||||||||||||E53F26-1101BKKS||The Braun Corporation|BRACOR|BRACOR|8C41B2D9230B467EB91E|39014 Eagle Way|||Chicago|IL|60678-1390|US|||||||||||||||||||N|||||||||||||||||||0.0000||0.0000||0.0000||0.0000|||||0.0000|0.0000||||||N|||||||||||||||||0.0000|0.0000|0.0000|||553.0000|0.0000||75.0000|\n';
			data = data.replace('yyyy-mm-dd', isodate).replace('ponumber', po.dealer__PO_Number__c);
			cpu.csvBlob = Blob.valueOf(data);
			cpu.submitCsv();
			cpu.processUpload();
		}
	}


}