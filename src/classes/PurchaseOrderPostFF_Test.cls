/**
 *  PurchaseOrderPostFF_Test
 * Tests: PurchaseOrderPostFF
 *
 * 2015-10-20   Jitendra Gupta.
 * 2015-11-06   B. Leaman   BLL1 - Don't create accepted POs to test with -- cannot update their lines.
 * 2016-02-29	B. Leaman	BLL2 - Switch method of creating FF data to use TestHelper_MW. 
 * 							Tests were not able to succeed with my change to PurchaseOrderPostFF that gets the FF company in constructor (to obtain the Payables default dimension).
 * 2019-02-01	B. Leaman	W-000573 BLL3 fix test failures due to missing fields in SOQL.
 */
@isTest
private class PurchaseOrderPostFF_Test {

    private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); // BLL1
    @testSetup
    static void setupFFA() {
      TestHelper_MW.createBaseFFAData(FFAdata);
    }
    
    static dealer__Purchase_Order__c CreateTestPurchaseOrder(dealer__Dealer_Location__c loc, Account vend, c2g__codaGeneralLedgerAccount__c gla){
        // dealer__Parts_Invoice__c, dealer__Parts_Line__c, dealer__PO_Lines__c,
        dealer__Purchase_Order__c po =  new dealer__Purchase_Order__c(
        dealer__Invoice_Amount__c = 90000, dealer__Invoice_Date__c = date.today(), dealer__Invoice_Number__c = '12345', dealer__PO_Key__c = '112233', dealer__Post_Date_Time__c = datetime.now(), dealer__Requested_By__c = 'test person', dealer__Type__c= 'Sublet', dealer__Vendor_City__c = 'Test City' , dealer__Vendor_Country__c = 'USA', dealer__Vendor_Email__c='test@test1.com', dealer__Vendor_Name__c = 'Test Vendor', dealer__Vendor_Phone__c = '12121223', dealer__Vendor_Postal_Code__c='343434', dealer__Vendor_State__c='GA', dealer__Vendor_Street__c = 'Main St', dealer__VIN__c = '34343', dealer__Comments__c = 'test comm', 
        dealer__Freight__c = 500, NMEDA_Fee__c = 300, Invoice_Adjustment__c = 40, 
        dealer__Company__c = loc.Id, 
        dealer__Vendor__c = vend.Id, 
        Parts_Amount__c = 1000, Misc_Charge__c = 1001,  GeneralLedgerAccount__c = gla.Id);
        //BLL1d dealer__Accepted_By__c = userinfo.getuserId(), dealer__Accepted_DateTime__c= datetime.now(),         
        
        return po;
    }
    
   // static c2g__codaDimension1__c CreateTestFinDimention(){
   //     c2g__codaDimension1__c dim1 = new c2g__codaDimension1__c();
   //     dim1.c2g__ExternalId__c = 'FakeId';
   //     dim1.c2g__ReportingCode__c = 'FakeCode';
   //     dim1.c2g__UnitOfWork__c = 1234567;
   //     insert dim1;
   //     return dim1;
   // }
    
    //static dealer__Dealer_Location__c CreateTestLocation(c2g__codaCompany__c comp, c2g__codaDimension1__c dim1){
    //    dealer__Dealer_Location__c loc = new dealer__Dealer_Location__c(
    //    dealer__Address__c = '301, Main St', BAR_Number__c = '2323223', dealer__City__c = 'New York', Country__c = 'USA', dealer__Email__c = 'test@test.com',dealer__Company_Number__c = '45655', dealer__Postal_Code__c = '343434', dealer__State__c = 'GA', Financial_Force_Dimension_1__c = dim1.Id, Company__c = comp.Id);
    //    insert loc;
    //    return loc;
    //}
    
    static dealer__Service_Repair_Order__c CreateTestServiceRepairOrder(Account acc, dealer__Dealer_Location__c loc){
        dealer__Service_Repair_Order__c rec = new dealer__Service_Repair_Order__c(
        dealer__Customer__c = acc.Id, dealer__Color_Code__c = '34343', 
        dealer__Company__c = loc.Id, 
        dealer__Create_Date_Time__c = datetime.now());
        insert rec;
        return rec;
    }
    
    static list<c2g__codaGeneralLedgerAccount__c> CreateTestGenAcc(set<String> codes){
        list<c2g__codaGeneralLedgerAccount__c> cgds = new list<c2g__codaGeneralLedgerAccount__c>();
        for(String code: codes){
            c2g__codaGeneralLedgerAccount__c cgd = new c2g__codaGeneralLedgerAccount__c();
            cgd.c2g__ReportingCode__c = code;
            cgd.c2g__Type__c='Manual Journal';
            cgd.Name='Test';
            cgds.add(cgd);
        }
        insert cgds;
        return cgds;
    }
    
    static list<dealer__Purchase_Order_Line__c>  CreateTestPurchaseOrderLines(dealer__Purchase_Order__c po, list<c2g__codaGeneralLedgerAccount__c> cgds){
        list<dealer__Purchase_Order_Line__c> lines = new list<dealer__Purchase_Order_Line__c>();
        GeneralLedgerAcctMW__c glact = [Select Id from GeneralLedgerAcctMW__c limit 1];
        Integer idx = 0;
        for(c2g__codaGeneralLedgerAccount__c cgd : cgds){
            dealer__Purchase_Order_Line__c line1 = new dealer__Purchase_Order_Line__c();
            line1.dealer__Purchase_Order__c = po.Id;
            line1.dealer__Amount__c = 10000;
            line1.Add_to_Chassis__c = true;
            line1.Add_to_Conversion__c = false;
            line1.General_Ledger_Account__c = cgd.Id;
            line1.GeneralLedgerAcct__c=glact.Id;
            lines.add(line1);
            idx++;
        }
        insert lines;
        return lines;
    }
    
    //static c2g__codaCompany__c CreateTestCompany(){
    //	Group g = TestHelper_MW.createFFAQueue(UserInfo.getUserId());	// BLLxa
    //    c2g__codaCompany__c cdc = new c2g__codaCompany__c();
    //    cdc.ownerId=g.Id;	// BLLxa
    //    cdc.Name ='Test CODA Company';
    //    cdc.c2g__CODABaseDate1__c='TestDate';
    //    cdc.c2g__CODADaysOffset1__c=12;
    //    insert cdc;
    //    insert new c2g__codaUserCompany__c(c2g__Company__c = cdc.Id, c2g__User__c = UserInfo.getUserId()); // BLLxa
    //    return cdc;
    //}

    //static User createUser(dealer__Dealer_Location__c ddl){
    //    Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
    //    
    //    User u = new User();
    //    u.Alias = 'standt';
    //    u.Email='testabc@gmail.com';
    //    u.EmailEncodingKey='UTF-8';
    //    u.LastName='Testing';
    //    u.LanguageLocaleKey='en_US';
    //    u.LocaleSidKey='en_US';
    //    u.ProfileId = p.Id;
    //    u.TimeZoneSidKey='America/Los_Angeles';
    //    u.UserName='tesa00@gmail.com';
    //    u.CompanyName = 'FF Test Company';
    //    u.Dealership_Location__c =ddl.dealer__Company_Number__c;
    //    //u.service_manager__c  ='Test';
    //    u.Division =ddl.dealer__Company_Number__c; // Setting this to the MBW Company
    //    insert u; 
    //    return u;
    //}
    
    // BLLxd
    //static void  CreateGroupMember(dealer__Dealer_Location__c ddl){
	//
    //    User u = createUser(ddl);
    //    Group grp = [select Id from Group where Type = 'Queue' Limit 1];
    //    User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
    //    System.runAs(thisUser){
    //        GroupMember gm = new GroupMember();
    //        gm.UserOrGroupId = u.Id;
    //        gm.GroupId = grp.Id;
    //        insert gm;
    //    }
    //}
    
    static dealer__Purchase_Order__c CreatePurchaseOrderTestData(RecordType rt, Decimal invoiceamt){
        //c2g__codaCompany__c comp = CreateTestCompany();
        //c2g__codaDimension1__c dim1 = CreateTestFinDimention();
        //dealer__Dealer_Location__c loc = CreateTestLocation(comp,dim1);
        //FFATests.createFFAQueue(CreateUser(loc).id);	
        //CreateGroupMember(loc);	// BLLxd
        
        Account acc = new Account(name = 'test',AccountSource ='Dealer',dealer__Vendor__c=true); insert acc;
        
        
        Set<String> rc = new Set<String>{'1220','2115','2100','4905','5304','4950','1274'};
        list<c2g__codaGeneralLedgerAccount__c> GenLedgerAccs = CreateTestGenAcc(rc);    
        
        //dealer__Purchase_Order__c p = CreateTestPurchaseOrder(loc, acc, GenLedgerAccs[0]);
        dealer__Purchase_Order__c p = CreateTestPurchaseOrder(FFAdata.DealerLocation, acc, GenLedgerAccs[0]);
        p.recordTypeId = rt.Id;
        p.dealer__Invoice_Amount__c = invoiceamt;
        insert p;
        list<dealer__Purchase_Order_Line__c> poLines = CreateTestPurchaseOrderLines(p,GenLedgerAccs);
        return p;
    }
    
    static testmethod void testPurchaseOrder_PartsPurchase() {
		FFAdata.refresh();
		System.runAs(FFAdata.TestUser) {
			
        RecordType rt = [select id from Recordtype where sobjecttype = 'dealer__Purchase_Order__c' and developername = 'Parts_Purchase'];
        dealer__Purchase_Order__c p = CreatePurchaseOrderTestData(rt,90000);  
        
		// BLL3
        //p = [
        //    SELECT dealer__Invoice_Amount__c, dealer__Invoice_Date__c, dealer__Invoice_Number__c, dealer__PO_Key__c, dealer__PO_Number__c, dealer__Parts_Invoice__c, dealer__Parts_Line__c, dealer__Post_Date_Time__c, dealer__Requested_By__c, dealer__Service_Repair_Order__c, dealer__Type__c, dealer__Vendor_City__c, dealer__Vendor_Country__c, dealer__Vendor_Email__c, dealer__Vendor_Name__c, dealer__Vendor_Phone__c, dealer__Vendor_Postal_Code__c, dealer__Vendor_State__c, dealer__Vendor_Street__c, dealer__Vendor__c, dealer__PO_Amount__c, dealer__PO_Lines__c, dealer__VIN__c, dealer__Company__c, dealer__Accepted_By__c, dealer__Comments__c, dealer__PO_Accounting_Name__c, dealer__Accepted_DateTime__c, dealer__Freight__c, NMEDA_Fee__c, Invoice_Adjustment__c, Id, Name,Parts_Amount__c,Misc_Charge__c
        //    FROM dealer__Purchase_Order__c 
        //    where id = :P.Id limit 1];
        p = [
            SELECT dealer__Invoice_Amount__c, dealer__Invoice_Date__c, dealer__Invoice_Number__c, dealer__PO_Key__c, dealer__PO_Number__c, dealer__Parts_Invoice__c, dealer__Parts_Line__c, dealer__Post_Date_Time__c, dealer__Requested_By__c, dealer__Service_Repair_Order__c, dealer__Type__c, dealer__Vendor_City__c, dealer__Vendor_Country__c, dealer__Vendor_Email__c, dealer__Vendor_Name__c, dealer__Vendor_Phone__c, dealer__Vendor_Postal_Code__c, dealer__Vendor_State__c, dealer__Vendor_Street__c, dealer__Vendor__c, dealer__PO_Amount__c, dealer__PO_Lines__c, dealer__VIN__c, dealer__Company__c, dealer__Accepted_By__c, dealer__Comments__c, dealer__PO_Accounting_Name__c, dealer__Accepted_DateTime__c, dealer__Freight__c, NMEDA_Fee__c, Invoice_Adjustment__c, Id, Name,Parts_Amount__c,Misc_Charge__c,
				GeneralLedgerAccount__c, Payable_Invoice__c
            FROM dealer__Purchase_Order__c 
            where id = :P.Id limit 1
		];
		// BLL3 end
            System.debug('dealer__Invoice_Amount__c--->' + p.dealer__Invoice_Amount__c);
            System.debug('dealer__Freight__c--->' + p.dealer__Freight__c);
            System.debug('NMEDA_Fee__c--->' + p.NMEDA_Fee__c);
            System.debug('Misc_Charge__c--->' + p.Misc_Charge__c);
            System.debug('dealer__PO_Amount__c--->' + p.dealer__PO_Amount__c);
            System.debug('Parts_Amount__c--->' + p.Parts_Amount__c);
   
        ApexPages.StandardController poc = new ApexPages.StandardController(p);
        PurchaseOrderPostFF pf = new PurchaseOrderPostFF(poc);

        pf.save();
        pf.genSubletLines();
        pf.getExistingLines();
        pf.gettLines();
        pf.genPartsLines();
        pf.genMiscLines();
        pf.applyVendorInvoice();
      
        pf.returnToPurchaseOrder();
        pf.pos(-9);
        String poid = pf.poid;
        pf.getjLines();
        try{
            pf.createPayableInvoice();
        }catch(Exception ex){}
        try{
            pf.postToFF();
        }catch(Exception ex){}

		}

    }
    
    static testmethod void testPurchaseOrder_Miscellaneous() {
		FFAdata.refresh();
		System.runAs(FFAdata.TestUser) {

        RecordType rt = [select id from Recordtype where sobjecttype = 'dealer__Purchase_Order__c' and developername = 'Misc'];
        dealer__Purchase_Order__c p = CreatePurchaseOrderTestData(rt,70000);       
		// BLL3
        //p = [
        //    SELECT dealer__Invoice_Amount__c, dealer__Invoice_Date__c, dealer__Invoice_Number__c, dealer__PO_Key__c, dealer__PO_Number__c, dealer__Parts_Invoice__c, dealer__Parts_Line__c, dealer__Post_Date_Time__c, dealer__Requested_By__c, dealer__Service_Repair_Order__c, dealer__Type__c, dealer__Vendor_City__c, dealer__Vendor_Country__c, dealer__Vendor_Email__c, dealer__Vendor_Name__c, dealer__Vendor_Phone__c, dealer__Vendor_Postal_Code__c, dealer__Vendor_State__c, dealer__Vendor_Street__c, dealer__Vendor__c, dealer__PO_Amount__c, dealer__PO_Lines__c, dealer__VIN__c, dealer__Company__c, dealer__Accepted_By__c, dealer__Comments__c, dealer__PO_Accounting_Name__c, dealer__Accepted_DateTime__c, dealer__Freight__c, NMEDA_Fee__c, Invoice_Adjustment__c, Id, Name,Parts_Amount__c,Misc_Charge__c, GeneralLedgerAccount__c
        //    FROM dealer__Purchase_Order__c 
        //    where id = :P.Id limit 1];
        p = [
            SELECT dealer__Invoice_Amount__c, dealer__Invoice_Date__c, dealer__Invoice_Number__c, dealer__PO_Key__c, dealer__PO_Number__c, dealer__Parts_Invoice__c, dealer__Parts_Line__c, dealer__Post_Date_Time__c, dealer__Requested_By__c, dealer__Service_Repair_Order__c, dealer__Type__c, dealer__Vendor_City__c, dealer__Vendor_Country__c, dealer__Vendor_Email__c, dealer__Vendor_Name__c, dealer__Vendor_Phone__c, dealer__Vendor_Postal_Code__c, dealer__Vendor_State__c, dealer__Vendor_Street__c, dealer__Vendor__c, dealer__PO_Amount__c, dealer__PO_Lines__c, dealer__VIN__c, dealer__Company__c, dealer__Accepted_By__c, dealer__Comments__c, dealer__PO_Accounting_Name__c, dealer__Accepted_DateTime__c, dealer__Freight__c, NMEDA_Fee__c, Invoice_Adjustment__c, Id, Name,Parts_Amount__c,Misc_Charge__c, 
				GeneralLedgerAccount__c, Payable_Invoice__c
            FROM dealer__Purchase_Order__c 
            where id = :P.Id limit 1
		];
		// BLL3 end
            System.debug('dealer__Invoice_Amount__c--->' + p.dealer__Invoice_Amount__c);
            System.debug('dealer__Freight__c--->' + p.dealer__Freight__c);
            System.debug('NMEDA_Fee__c--->' + p.NMEDA_Fee__c);
            System.debug('Misc_Charge__c--->' + p.Misc_Charge__c);
            System.debug('dealer__PO_Amount__c--->' + p.dealer__PO_Amount__c);
            System.debug('Parts_Amount__c--->' + p.Parts_Amount__c);
        ApexPages.StandardController poc = new ApexPages.StandardController(p);
        PurchaseOrderPostFF pf = new PurchaseOrderPostFF(poc);

        pf.save();
        pf.genSubletLines();
        pf.getExistingLines();
        pf.gettLines();
        pf.genPartsLines();
        pf.genMiscLines();
        pf.applyVendorInvoice();
        pf.returnToPurchaseOrder();
        pf.pos(-9);
        String poid = pf.poid;
        pf.getjLines();
        try{
            pf.createPayableInvoice();
        }catch(Exception ex){}
        try{
            pf.postToFF();
        }catch(Exception ex){}
        
		}
		
    }
    
    static testmethod void testPurchaseOrder_Miscellaneous_DifferantPOAmt() {
		FFAdata.refresh();
		System.runAs(FFAdata.TestUser) {

        RecordType rt = [select id from Recordtype where sobjecttype = 'dealer__Purchase_Order__c' and developername = 'Misc'];
        dealer__Purchase_Order__c p = CreatePurchaseOrderTestData(rt,90000);       
        p = [
            SELECT dealer__Invoice_Amount__c, dealer__Invoice_Date__c, dealer__Invoice_Number__c, dealer__PO_Key__c, dealer__PO_Number__c, dealer__Parts_Invoice__c, dealer__Parts_Line__c, dealer__Post_Date_Time__c, dealer__Requested_By__c, dealer__Service_Repair_Order__c, dealer__Type__c, dealer__Vendor_City__c, dealer__Vendor_Country__c, dealer__Vendor_Email__c, dealer__Vendor_Name__c, dealer__Vendor_Phone__c, dealer__Vendor_Postal_Code__c, dealer__Vendor_State__c, dealer__Vendor_Street__c, dealer__Vendor__c, dealer__PO_Amount__c, dealer__PO_Lines__c, dealer__VIN__c, dealer__Company__c, dealer__Accepted_By__c, dealer__Comments__c, dealer__PO_Accounting_Name__c, dealer__Accepted_DateTime__c, dealer__Freight__c, NMEDA_Fee__c, Invoice_Adjustment__c, Id, Name,Parts_Amount__c,Misc_Charge__c,GeneralLedgerAccount__c 
            FROM dealer__Purchase_Order__c 
            where id = :P.Id limit 1];
            System.debug('dealer__Invoice_Amount__c--->' + p.dealer__Invoice_Amount__c);
            System.debug('dealer__Freight__c--->' + p.dealer__Freight__c);
            System.debug('NMEDA_Fee__c--->' + p.NMEDA_Fee__c);
            System.debug('Misc_Charge__c--->' + p.Misc_Charge__c);
            System.debug('dealer__PO_Amount__c--->' + p.dealer__PO_Amount__c);
            System.debug('Parts_Amount__c--->' + p.Parts_Amount__c);
        ApexPages.StandardController poc = new ApexPages.StandardController(p);
        PurchaseOrderPostFF pf = new PurchaseOrderPostFF(poc);
        pf.gettLines();
        
		}
		
    }
    
    static testmethod void testPurchaseOrder_Sublet() {
		FFAdata.refresh();
		System.runAs(FFAdata.TestUser) {

        RecordType rt = [select id from Recordtype where sobjecttype = 'dealer__Purchase_Order__c' and developername = 'Sublet'];
        dealer__Purchase_Order__c p = CreatePurchaseOrderTestData(rt,70000);       
		// BLL3
        //p = [
        //    SELECT dealer__Invoice_Amount__c, dealer__Invoice_Date__c, dealer__Invoice_Number__c, dealer__PO_Key__c, dealer__PO_Number__c, dealer__Parts_Invoice__c, dealer__Parts_Line__c, dealer__Post_Date_Time__c, dealer__Requested_By__c, dealer__Service_Repair_Order__c, dealer__Type__c, dealer__Vendor_City__c, dealer__Vendor_Country__c, dealer__Vendor_Email__c, dealer__Vendor_Name__c, dealer__Vendor_Phone__c, dealer__Vendor_Postal_Code__c, dealer__Vendor_State__c, dealer__Vendor_Street__c, dealer__Vendor__c, dealer__PO_Amount__c, dealer__PO_Lines__c, dealer__VIN__c, dealer__Company__c, dealer__Accepted_By__c, dealer__Comments__c, dealer__PO_Accounting_Name__c, dealer__Accepted_DateTime__c, dealer__Freight__c, NMEDA_Fee__c, Invoice_Adjustment__c, Id, Name,Parts_Amount__c,Misc_Charge__c
        //    FROM dealer__Purchase_Order__c 
        //    where id = :P.Id limit 1];
        p = [
            SELECT dealer__Invoice_Amount__c, dealer__Invoice_Date__c, dealer__Invoice_Number__c, dealer__PO_Key__c, dealer__PO_Number__c, dealer__Parts_Invoice__c, dealer__Parts_Line__c, dealer__Post_Date_Time__c, dealer__Requested_By__c, dealer__Service_Repair_Order__c, dealer__Type__c, dealer__Vendor_City__c, dealer__Vendor_Country__c, dealer__Vendor_Email__c, dealer__Vendor_Name__c, dealer__Vendor_Phone__c, dealer__Vendor_Postal_Code__c, dealer__Vendor_State__c, dealer__Vendor_Street__c, dealer__Vendor__c, dealer__PO_Amount__c, dealer__PO_Lines__c, dealer__VIN__c, dealer__Company__c, dealer__Accepted_By__c, dealer__Comments__c, dealer__PO_Accounting_Name__c, dealer__Accepted_DateTime__c, dealer__Freight__c, NMEDA_Fee__c, Invoice_Adjustment__c, Id, Name,Parts_Amount__c,Misc_Charge__c,
				GeneralLedgerAccount__c, Payable_Invoice__c
            FROM dealer__Purchase_Order__c 
            where id = :P.Id limit 1
		];
		// BLL3 end
            System.debug('dealer__Invoice_Amount__c--->' + p.dealer__Invoice_Amount__c);
            System.debug('dealer__Freight__c--->' + p.dealer__Freight__c);
            System.debug('NMEDA_Fee__c--->' + p.NMEDA_Fee__c);
            System.debug('Misc_Charge__c--->' + p.Misc_Charge__c);
            System.debug('dealer__PO_Amount__c--->' + p.dealer__PO_Amount__c);
            System.debug('Parts_Amount__c--->' + p.Parts_Amount__c);
        ApexPages.StandardController poc = new ApexPages.StandardController(p);
        PurchaseOrderPostFF pf = new PurchaseOrderPostFF(poc);

        pf.save();
        pf.genSubletLines();
        pf.getExistingLines();
        pf.gettLines();
        pf.genPartsLines();
        pf.genMiscLines();
        pf.applyVendorInvoice();
        pf.returnToPurchaseOrder();
        pf.pos(-9);
        String poid = pf.poid;
        pf.getjLines();
        try{
            pf.createPayableInvoice();
        }catch(Exception ex){}
        try{
            pf.postToFF();
        }catch(Exception ex){}
        
    	}
    	
    }
    
    static testmethod void testPurchaseOrder_Sublet_DifferantPOAmount() {
		FFAdata.refresh();
		System.runAs(FFAdata.TestUser) {

        RecordType rt = [select id from Recordtype where sobjecttype = 'dealer__Purchase_Order__c' and developername = 'Sublet'];
        dealer__Purchase_Order__c p = CreatePurchaseOrderTestData(rt,90000);       
		// BLL3
        //p = [
        //    SELECT dealer__Invoice_Amount__c, dealer__Invoice_Date__c, dealer__Invoice_Number__c, dealer__PO_Key__c, dealer__PO_Number__c, dealer__Parts_Invoice__c, dealer__Parts_Line__c, dealer__Post_Date_Time__c, dealer__Requested_By__c, dealer__Service_Repair_Order__c, dealer__Type__c, dealer__Vendor_City__c, dealer__Vendor_Country__c, dealer__Vendor_Email__c, dealer__Vendor_Name__c, dealer__Vendor_Phone__c, dealer__Vendor_Postal_Code__c, dealer__Vendor_State__c, dealer__Vendor_Street__c, dealer__Vendor__c, dealer__PO_Amount__c, dealer__PO_Lines__c, dealer__VIN__c, dealer__Company__c, dealer__Accepted_By__c, dealer__Comments__c, dealer__PO_Accounting_Name__c, dealer__Accepted_DateTime__c, dealer__Freight__c, NMEDA_Fee__c, Invoice_Adjustment__c, Id, Name,Parts_Amount__c,Misc_Charge__c
        //    FROM dealer__Purchase_Order__c 
        //    where id = :P.Id limit 1];
        p = [
            SELECT dealer__Invoice_Amount__c, dealer__Invoice_Date__c, dealer__Invoice_Number__c, dealer__PO_Key__c, dealer__PO_Number__c, dealer__Parts_Invoice__c, dealer__Parts_Line__c, dealer__Post_Date_Time__c, dealer__Requested_By__c, dealer__Service_Repair_Order__c, dealer__Type__c, dealer__Vendor_City__c, dealer__Vendor_Country__c, dealer__Vendor_Email__c, dealer__Vendor_Name__c, dealer__Vendor_Phone__c, dealer__Vendor_Postal_Code__c, dealer__Vendor_State__c, dealer__Vendor_Street__c, dealer__Vendor__c, dealer__PO_Amount__c, dealer__PO_Lines__c, dealer__VIN__c, dealer__Company__c, dealer__Accepted_By__c, dealer__Comments__c, dealer__PO_Accounting_Name__c, dealer__Accepted_DateTime__c, dealer__Freight__c, NMEDA_Fee__c, Invoice_Adjustment__c, Id, Name,Parts_Amount__c,Misc_Charge__c, 
				GeneralLedgerAccount__c, Payable_Invoice__c
            FROM dealer__Purchase_Order__c 
            where id = :P.Id limit 1
		];
		// BLL3 end
            System.debug('dealer__Invoice_Amount__c--->' + p.dealer__Invoice_Amount__c);
            System.debug('dealer__Freight__c--->' + p.dealer__Freight__c);
            System.debug('NMEDA_Fee__c--->' + p.NMEDA_Fee__c);
            System.debug('Misc_Charge__c--->' + p.Misc_Charge__c);
            System.debug('dealer__PO_Amount__c--->' + p.dealer__PO_Amount__c);
            System.debug('Parts_Amount__c--->' + p.Parts_Amount__c);
        ApexPages.StandardController poc = new ApexPages.StandardController(p);
        PurchaseOrderPostFF pf = new PurchaseOrderPostFF(poc);

        pf.save();
        pf.genSubletLines();
        pf.getExistingLines();
        pf.gettLines();
        pf.genPartsLines();
        pf.genMiscLines();
        pf.applyVendorInvoice();
        pf.returnToPurchaseOrder();
        pf.pos(-9);
        String poid = pf.poid;
        pf.getjLines();
        try{
            pf.createPayableInvoice();
        }catch(Exception ex){}
        try{
            pf.postToFF();
        }catch(Exception ex){}
        
    	}
    	
    }
}