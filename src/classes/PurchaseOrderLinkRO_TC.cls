/**
 * PurchaseOrderLinkRO_TC
 * Tests: PurchaseOrderLinkRO trigger
 *
 * 	2016-06-20	B. Leaman	BLL1 increase coverage
 *	2019-04-22	B. Leaman	W-000659 BLL2 - test prevent unauthorized deletion of a po.
 */
@isTest
public  class PurchaseOrderLinkRO_TC{
	public static  testmethod void MyunitTest(){

		//Account a = new Account(Name='Vendor');
        //a.dealer__Vendor__c = true;
        //a.BillingState = 'CA';
        //insert a;
		TestHelper_MW th = new TestHelper_MW();
		Account a = th.getVendorAccount('1');

        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();

        dealer__Service_Repair_Order__c dsr = new dealer__Service_Repair_Order__c();
        dsr.dealer__Customer__c =a.id;
        dsr.dealer__Mileage_In__c =12;
        dsr.dealer__RO_Number__c ='11';
        insert dsr;

		List<dealer__Service_Job__c> jobs = new List<dealer__Service_Job__c>();	// BLL1a
        dealer__Service_Job__c dsj = new dealer__Service_Job__c();
         dsj.dealer__Cause__c ='Test';
         dsj.dealer__Labor_Charges__c =12;
         dsj.dealer__Service_Repair_Order__c =dsr.id;
         dsj.dealer__Labor_Type__c = 'I';
        //insert dsj;     
        jobs.add(dsj);
        // BLL1a
        dealer__Service_Job__c dsj2 = new dealer__Service_Job__c(
        	dealer__Cause__c ='Test2',
        	dealer__Labor_Charges__c = 14,
        	dealer__Labor_Type__c = 'I',
        	dealer__Service_Repair_Order__c = dsr.id
        );
        jobs.add(dsj2);
        insert(jobs);
        // BLL1a end     

		// BLL1a
		Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Purchase_Order__c.getRecordTypeInfosByName();
		Schema.RecordTypeInfo rtInfo = RcdTypes.get('Sublet');
		// BLL1a end

        Test.startTest();

        dealer__Purchase_Order__c po = new dealer__Purchase_Order__c();
        po.RecordTypeId = rtInfo.getRecordTypeId();	// BLL1a
        po.dealer__Vendor__c = a.Id;
        po.dealer__Service_Repair_Order__c = dsr.Id;
        insert po;

        dealer__Purchase_Order_Line__c poline = new dealer__Purchase_Order_Line__c();
        poline.dealer__Purchase_Order__c = po.Id;
        poline.dealer__Service_Job_Line__c = dsj.Id;
        poline.dealer__Amount__c = 100;
        //poline.dealer__Customer_Total__c = 110;	// BLL1a
        insert poline;
        poline.dealer__Amount__c = 200;
        poline.dealer__Customer_Total__c = 210;	// BLL1a
        poline.dealer__Service_Job_Line__c = dsj2.Id;	// BLL1a
        Update poline;

        Test.stopTest();

		// Can't do another -- too many SOQL
        //poline.dealer__Service_Job_Line__c = dsj.Id;	// BLL1a
        //Update poline;	// BLL1a
	}

	// BLL2
	public static testmethod void testPreventDelete(){

		Account a = new Account(Name='Vendor');
        a.dealer__Vendor__c = true;
        a.BillingState = 'CA';
        insert a;

        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();

		Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Purchase_Order__c.getRecordTypeInfosByName();
		Schema.RecordTypeInfo rtInfo = RcdTypes.get('Sublet');
        dealer__Purchase_Order__c po = new dealer__Purchase_Order__c();
        po.RecordTypeId = rtInfo.getRecordTypeId();	
        po.dealer__Vendor__c = a.Id;
        insert po;

        dealer__Purchase_Order_Line__c poline = new dealer__Purchase_Order_Line__c();
        poline.dealer__Purchase_Order__c = po.Id;
        poline.dealer__Amount__c = 100;
        insert poline;

		boolean deleted = false;
        Test.startTest();
		try {
			delete po;
			deleted = true;
		} catch(Exception e) {
			System.debug(e);
		}
        Test.stopTest();
		System.assert(deleted==false, 'PO Deletion was NOT prevented');

	}
	// BLL2 end

}