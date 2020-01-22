/**
 * PurchaseOrderPostingTest
 * Tests: PurchaseOrderPostFF
 *
 * 2015-09-22   B. Leaman   BLL1 - Make sure Misc PO has lines so the post function succeeds.
 */
 @isTest
private class PurchaseOrderPostingTest {
   /* static testmethod void testPurchaseOrder() {
        dealer__Purchase_Order__c p = [
            SELECT dealer__Invoice_Amount__c, dealer__Invoice_Date__c, dealer__Invoice_Number__c, dealer__PO_Key__c, dealer__PO_Number__c, dealer__Parts_Invoice__c, dealer__Parts_Line__c, dealer__Post_Date_Time__c, dealer__Requested_By__c, dealer__Service_Repair_Order__c, dealer__Type__c, dealer__Vendor_City__c, dealer__Vendor_Country__c, dealer__Vendor_Email__c, dealer__Vendor_Name__c, dealer__Vendor_Phone__c, dealer__Vendor_Postal_Code__c, dealer__Vendor_State__c, dealer__Vendor_Street__c, dealer__Vendor__c, dealer__PO_Amount__c, dealer__PO_Lines__c, dealer__VIN__c, dealer__Company__c, dealer__Accepted_By__c, dealer__Comments__c, dealer__PO_Accounting_Name__c, dealer__Accepted_DateTime__c, dealer__Freight__c, NMEDA_Fee__c, Invoice_Adjustment__c, Id, Name 
            FROM dealer__Purchase_Order__c 
            where dealer__Type__c = 'Sublet' and dealer__Company__c != null 
            order by CreatedDate Desc 
            limit 1];

        ApexPages.StandardController poc = new ApexPages.StandardController(p);
        PurchaseOrderPostFF pf = new PurchaseOrderPostFF(poc);

        pf.save();
        pf.genSubletLines();

        pf.postToFF();
    }

    static testmethod void testAmountNotEqualInvoice() {

       // dealer__Purchase_Order__c p = [SELECT dealer__Invoice_Amount__c, dealer__Invoice_Date__c, dealer__Invoice_Number__c, dealer__PO_Key__c, dealer__PO_Number__c, dealer__Parts_Invoice__c, dealer__Parts_Line__c, dealer__Post_Date_Time__c, dealer__Requested_By__c, dealer__Service_Repair_Order__c, dealer__Type__c, dealer__Vendor_City__c, dealer__Vendor_Country__c, dealer__Vendor_Email__c, dealer__Vendor_Name__c, dealer__Vendor_Phone__c, dealer__Vendor_Postal_Code__c, dealer__Vendor_State__c, dealer__Vendor_Street__c, dealer__Vendor__c, dealer__PO_Amount__c, dealer__PO_Lines__c, dealer__VIN__c, dealer__Company__c, dealer__Accepted_By__c, dealer__Comments__c, dealer__PO_Accounting_Name__c, dealer__Accepted_DateTime__c, dealer__Freight__c, NMEDA_Fee__c, Invoice_Adjustment__c, Id, Name FROM dealer__Purchase_Order__c where dealer__Type__c = 'Parts Purchase' and dealer__Company__c != null order by CreatedDate Desc limit 1];
     Account  acc = new Account();
        acc.LastName ='Test';
        acc.AccountSource ='Dealer';
        acc.BillingState = 'CA';
        
        insert acc;
        c2g__codaDimension1__c cdm1 = new c2g__codaDimension1__c();
        cdm1.Name ='Test';
        cdm1.c2g__ReportingCode__c ='Test';
        insert cdm1;  
   dealer__Dealer_Location__c   ddl = new dealer__Dealer_Location__c();
        ddl.Name ='Test';
        ddl.dealer__City__c ='Test';
        ddl.dealer__Postal_Code__c='301352';
        ddl.dealer__State__c='Te';
        ddl.dealer__Company_Number__c='SAN';
        ddl.dealer__Service_Director__c =Userinfo.getuserid();
        ddl.Financial_Force_Dimension_1__c=cdm1.id;
        insert ddl;
           dealer__Purchase_Order__c   p = new dealer__Purchase_Order__c();
           p.dealer__Vendor__c =acc.id; 
           p.dealer__Company__c=ddl.id;
            p.Invoice_Adjustment__c = 999;
            p.dealer__Invoice_Amount__c = 999;
            insert p;
         c2g__codaGeneralLedgerAccount__c cgd = new c2g__codaGeneralLedgerAccount__c();
        cgd.c2g__ReportingCode__c ='52';
        cgd.c2g__Type__c='Manual Journal';
        cgd.Name='Test';
        insert cgd;

       


        c2g__codaBankAccount__c ccb = new c2g__codaBankAccount__c();
        ccb.Name='Test';
        ccb.c2g__ReportingCode__c='12';
        ccb.c2g__BankName__c='Test';
        ccb.c2g__AccountName__c='TestA';
        ccb.c2g__AccountNumber__c='123';
        ccb.c2g__GeneralLedgerAccount__c=cgd.id;
        insert ccb;

          c2g__codaJournal__c cj = new c2g__codaJournal__c();
        cj.c2g__JournalDate__c =system.Today();
        cj.c2g__Type__c='Manual Journal';
        insert cj;
            c2g__codaJournalLineItem__c ccj = new c2g__codaJournalLineItem__c();
        ccj.c2g__Journal__c =cj.id;
        ccj.c2g__LineType__c='Bank Account';
        ccj.c2g__Value__c =12;
        ccj.c2g__BankAccount__c=ccb.id;
        ccj.c2g__Dimension1__c =cdm1.id;
        ccj.Control__c='test';      
        
            ApexPages.StandardController poc = new ApexPages.StandardController(p);
        PurchaseOrderPostFF pf = new PurchaseOrderPostFF(poc);
        pf.save();
        pf.genPartsLines(); 
        pf.postToFF();
    }

    static testmethod void testPOParts() {
        dealer__Purchase_Order__c p = [SELECT dealer__Invoice_Amount__c, dealer__Invoice_Date__c, dealer__Invoice_Number__c, dealer__PO_Key__c, dealer__PO_Number__c, dealer__Parts_Invoice__c, dealer__Parts_Line__c, dealer__Post_Date_Time__c, dealer__Requested_By__c, dealer__Service_Repair_Order__c, dealer__Type__c, dealer__Vendor_City__c, dealer__Vendor_Country__c, dealer__Vendor_Email__c, dealer__Vendor_Name__c, dealer__Vendor_Phone__c, dealer__Vendor_Postal_Code__c, dealer__Vendor_State__c, dealer__Vendor_Street__c, dealer__Vendor__c, dealer__PO_Amount__c, dealer__PO_Lines__c, dealer__VIN__c, dealer__Company__c, dealer__Accepted_By__c, dealer__Comments__c, dealer__PO_Accounting_Name__c, dealer__Accepted_DateTime__c, dealer__Freight__c, NMEDA_Fee__c, Invoice_Adjustment__c, Id, Name FROM dealer__Purchase_Order__c where dealer__Type__c = 'Parts Purchase' and dealer__Company__c != null order by CreatedDate Desc limit 1];

        ApexPages.StandardController poc = new ApexPages.StandardController(p);
        PurchaseOrderPostFF pf = new PurchaseOrderPostFF(poc);

        pf.save();
        pf.genPartsLines(); 

        pf.postToFF();  
    }

    static testmethod void testMisc() {
        dealer__Purchase_Order__c p = [
        SELECT dealer__Invoice_Amount__c, dealer__Invoice_Date__c, dealer__Invoice_Number__c, dealer__PO_Key__c, dealer__PO_Number__c, dealer__Parts_Invoice__c, dealer__Parts_Line__c, dealer__Post_Date_Time__c, dealer__Requested_By__c, dealer__Service_Repair_Order__c, dealer__Type__c, dealer__Vendor_City__c, dealer__Vendor_Country__c, dealer__Vendor_Email__c, dealer__Vendor_Name__c, dealer__Vendor_Phone__c, dealer__Vendor_Postal_Code__c, dealer__Vendor_State__c, dealer__Vendor_Street__c, dealer__Vendor__c, dealer__PO_Amount__c, dealer__PO_Lines__c, dealer__VIN__c, dealer__Company__c, dealer__Accepted_By__c, dealer__Comments__c, dealer__PO_Accounting_Name__c, dealer__Accepted_DateTime__c, dealer__Freight__c, NMEDA_Fee__c, Invoice_Adjustment__c, Id, Name
        FROM dealer__Purchase_Order__c 
        where dealer__Type__c = 'Miscellaneous' and dealer__Company__c != null
          and dealer__PO_Lines__c>0  // BLL1a
        order by CreatedDate Desc 
        limit 1];

        ApexPages.StandardController poc = new ApexPages.StandardController(p);
        PurchaseOrderPostFF pf = new PurchaseOrderPostFF(poc);

        pf.save();
        pf.genMiscLines();

        pf.postToFF();  

        p.dealer__Invoice_Amount__c = 999;
        p.Invoice_Adjustment__c = 129;

        ApexPages.StandardController poc2 = new ApexPages.StandardController(p);
        PurchaseOrderPostFF pf2 = new PurchaseOrderPostFF(poc2);

        pf2.save();
        pf2.genMiscLines();

        pf2.postToFF(); 

        pf2.returnToPurchaseOrder();        
    } */  
}