/**
 * ConcurPurchaseAndReceiptExport_TEST
 * Tests: ConcurPurchaseAndReceiptExport
 * Date: Jun 1, 2018
 * Programmer: Bryan Leaman
 *
 * Modification Log:
 *
 */
@isTest
private class ConcurPurchaseAndReceiptExport_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();
	        dealer.TestClassUtil tc = new dealer.TestClassUtil();
	        tc.insertDMSSettings();
	
			insert(new dealer__Dealer_Location__c(
				dealer__Company_Number__c = 'AKR',
				Name = 'Test Akron',
				dealer__Street__c = '810 Moe Dr.',
				dealer__City__c = 'Akron',
				dealer__State__c = 'OH',
				dealer__Postal_Code__c = '44310'
			));
	
			Account v = th.getVendorAccount('1');
			v.Name = 'Braun Corp';
			update(v);
	
			Map<String, Schema.RecordTypeInfo> poRcdTypes = Schema.SObjectType.dealer__Purchase_Order__c.getRecordTypeInfosByName();
			Schema.RecordTypeInfo poRtInfo = poRcdTypes.get('Parts Purchase');
	
			dealer__Purchase_Order__c po = new dealer__Purchase_Order__c(
				RecordTypeId = poRtInfo.getRecordTypeId(),
				dealer__Vendor__c = v.Id
			);
			insert(po);
	
	        List<dealer__Parts_Master__c> pms = new List<dealer__Parts_Master__c>();
	        dealer__Parts_Master__c pm1 = new dealer__Parts_Master__c(
	            Name = 'A12345-AC',
	            dealer__Part_No__c = 'VMI:A12345-AC',
	            dealer__Part_Description__c = 'Test Part System',
	            dealer__Manufacturer__c = 'OT',
	            dealer__Cost__c = 3.75,
	            dealer__Retail_Price__c = 5.00
	        );
	        pms.add(pm1);
	        insert(pms);
	     
	        List<dealer__Parts_Inventory__c> pinvs = new List<dealer__Parts_Inventory__c>();
	        dealer__Parts_Inventory__c pinv1 = new dealer__Parts_Inventory__c(
	            dealer__Parts_Master__c = pm1.Id,
	            dealer__Cost__c = 11,
	            dealer__List__c = 1,
	            dealer__Location__c = FFAdata.DealerLocation.Id,
	            dealer__Entry_Date__c = Date.Today(),
	            dealer__On_Hand__c   = 50,  
	            dealer__Description__c = 'Test'
	        );
	        pinvs.add(pinv1);
	        insert(pinvs);
	
			List<dealer__Purchase_Order_Line__c> polines = new List<dealer__Purchase_Order_Line__c>();
			polines.add(new dealer__Purchase_Order_Line__c(
				dealer__Purchase_Order__c = po.Id,
				dealer__Part_Quantity__c = 2, 
				dealer__Part_Quantity_Received__c = 1,
				dealer__Amount__c = 10.00,  
				dealer__Part__c = pinv1.Id, 
				dealer__Parts_Master__c = pm1.Id 
			));
			insert(polines);
	        
	        List<dealer__Part_Inventory_History__c> pihs = new List<dealer__Part_Inventory_History__c>();
			pihs.add(new dealer__Part_Inventory_History__c(
				dealer__Transaction_Event__c = 'Purchase Order Received',
				dealer__Quantity_Adjustment__c = 1, 
				dealer__Transaction_Time__c = DateTime.now(),
				dealer__Purchase_Order__c = po.Id,
				dealer__Part__c = pinv1.Id
	        ));
	        insert(pihs);
			
		} 
	}

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
			ConcurPurchaseAndReceiptExport concur = new ConcurPurchaseAndReceiptExport();
			concur.RetrieveAndGenerateExportData();
			
			List<dealer__Purchase_Order__c> polist = [
				select Id, dealer__PO_Number__c, Name, dealer__Status__c, CreatedDate, dealer__Date_Required__c,
				Payable_Invoice__c, Payable_Invoice__r.c2g__InvoiceStatus__c,  
				dealer__Vendor__c, dealer__Vendor__r.Name, dealer__Vendor__r.ClientID__c, 
				dealer__Vendor__r.c2g__CODADaysOffset1__c, 
				dealer__Vendor__r.c2g__CODADiscount1__c, dealer__Vendor__r.c2g__CODAAccountTradingCurrency__c, 
				dealer__Company__c, dealer__Company__r.Name, dealer__Company__r.dealer__Company_Number__c, 
				dealer__Company__r.dealer__Street__c,
				dealer__Company__r.dealer__City__c, dealer__Company__r.dealer__State__c, dealer__Company__r.dealer__Postal_Code__c, dealer__Company__r.Country__c,
				dealer__Company__r.Financial_Force_Dimension_1__r.c2g__ReportingCode__c,
				LastModifiedDate, 
				( select Id, Name, dealer__Description__c, dealer__Part_Quantity__c, dealer__Part_Quantity_Received__c,
					dealer__Part_Cost__c, dealer__Amount__c, dealer__Item_Value__c, 
					dealer__Part__c, dealer__Parts_Master__c, dealer__Parts_Master__r.Name,
					dealer__Parts_Master__r.dealer__Part_Description__c, 
					LastModifiedDate
				  from dealer__Purchase_Order_Line__r
				  order by Name),
				( select Id, Name, dealer__Quantity_Adjustment__c, dealer__Transaction_Time__c,
					dealer__Part__c, dealer__Part__r.dealer__Pack_QTY__c, dealer__Part__r.dealer__Parts_Master__r.Name, Description__c
				  from dealer__Parts_Inventory_History__r
				  where dealer__Transaction_Event__c in ('Purchase Order Received')
				)
				from dealer__Purchase_Order__c
			];
			concur.includePOsText = polist[0].dealer__PO_Number__c;
			concur.GenerateExportData(poList);
			concur.FinalizeExport();
		}
	}

}