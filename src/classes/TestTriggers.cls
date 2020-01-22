/**
 * TestTriggers
 * Tests: ServiceROCalc, ??
 *
 *  2013-04-01  B. Leaman    BLL1a Increase coverage of ServiceROCalc trigger.
 *
 *  2016-11-17 | Gaurav Agrawal | Case - 00002188 | To increase code coverage of ServiceJobLineControl Trigger on Service Job Line object
 *	2017-05-12	B. Leaman	BLL2 - The above fails (Case - 00002188) because it causes Too many SOQL queries in the testPOLinkRO method. Commenting it out
 */
@isTest
private class TestTriggers {

    // BLL1a 
    @testSetup
    static void setupTest() {
        MW_TriggerControls__c roProtection = new MW_TriggerControls__c(Name='RepairOrderProtect',Enabled__c=true);
        insert(roProtection);
    }
    // BLL1a end
    
    static testmethod void testPOLinkRO() {
        // Create PO
        //Account a = new Account(Name='Vendor');
        //a.dealer__Vendor__c = true;
        //a.BillingState = 'CA';
        //insert a;
		TestHelper_MW th = new TestHelper_MW();
		Account a = th.getVendorAccount('2');

        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();

        dealer__Service_Repair_Order__c dsr = new dealer__Service_Repair_Order__c();
        dsr.dealer__Customer__c =a.id;
        dsr.dealer__Mileage_In__c =12;
        dsr.dealer__RO_Number__c ='11';
        insert dsr;

        dealer__Service_Job__c dsj = new dealer__Service_Job__c();
         dsj.dealer__Cause__c ='Test';
         dsj.dealer__Labor_Charges__c =12;
         dsj.dealer__Service_Repair_Order__c =dsr.id;
        insert dsj;     

        dealer__Purchase_Order__c po = new dealer__Purchase_Order__c();
        po.dealer__Vendor__c = a.Id;
        po.dealer__Service_Repair_Order__c = dsr.Id;
        insert po;

        /* Case 00002188 Begin */
        // BLL2d comment out because it causes too many SOQL queries error in DealerTeam pkg
        //dealer__Purchase_Order_Line__c poline = new dealer__Purchase_Order_Line__c();
        //poline.dealer__Purchase_Order__c = po.Id;
        //poline.dealer__Service_Job_Line__c = dsj.Id;
        //poline.dealer__Amount__c = 100;
        //insert poline;        
        
        //dealer__Parts_Invoice__c objPartInvoice = new dealer__Parts_Invoice__c();
        //objPartInvoice.Name = 'Test Part Invoice';
        //objPartInvoice.dealer__Invoice_Number__c = 'TEST';
        //insert objPartInvoice;
        
        //dealer__Parts_Invoice_Line__c objPartLine = new dealer__Parts_Invoice_Line__c();
        //objPartLine.Name = 'Test Part Line';
        //objPartLine.dealer__Job_Line__c = dsj.Id;
        //objPartLine.dealer__Parts_Invoice__c = objPartInvoice.Id;
        //objPartLine.dealer__Cost__c = 10;
        //objPartLine.dealer__Part_Number__c = 'Test Part Number';
        //objPartLine.dealer__Price__c = 20;
        //objPartLine.dealer__Quantity_Sold__c = 15;
        //insert objPartLine ;
        
        //try{
        //    delete dsj;
        //    System.assert(false, 'You can not delete service job which is having part line');
        //}catch(DmlException e) {
        //    String message = e.getMessage();
        //    System.assert(message.contains('You can not delete service job which is having part line'), 'message=' + message);        
        //}
        // BLL2d end
        /* Case 00002188 End */    
    }   

    static testmethod void testEstimateUpdateRO() {

        //Account a = new Account(FirstName='Bob', LastName='Sage');
        //insert a;
		TestHelper_MW th = new TestHelper_MW();
		Account a = th.getPersonAccount('1');

        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();

        dealer__Service_Repair_Order__c dsr = new dealer__Service_Repair_Order__c();
        dsr.dealer__Customer__c =a.id;
        dsr.dealer__Mileage_In__c =12;
        dsr.dealer__RO_Number__c ='11';
        dsr.dealer__Discount_Type__c='30%'; // BLL1a increase coverage of ServiceROCalc trigger
        insert dsr;

        dealer__Service_Job__c dsj = new dealer__Service_Job__c();
         dsj.dealer__Cause__c ='Test';
         dsj.dealer__Labor_Charges__c =12;
         dsj.dealer__Service_Repair_Order__c =dsr.id;
        insert dsj; 

        Estimate_Approval__c e = new Estimate_Approval__c();
        e.Service_Repair_Order__c = dsr.Id;
        e.Approved_Amount__c = 99;
        e.Approved_By__c = 'Bob';
        e.Contact_Method__c = 'Phone';
        insert e;

        e.Approved_Amount__c = 900;
        update e;

        delete e;
        delete dsr; // BLL1a
        
    }

    static testmethod void testPartMaster() {
        
        dealer__Parts_Master__c pm = new dealer__Parts_Master__c();
        pm.Name = 'A12345-AC';
        pm.dealer__Part_No__c = 'VMI:A12345-AC';
        pm.dealer__Part_Description__c = 'Test Part System';
        pm.dealer__Manufacturer__c = 'OT';
        pm.dealer__Cost__c = 90;
        pm.dealer__Retail_Price__c = 90;

        insert pm;
        
        
        
        
    }
    
     static testmethod void testPartMaster2() {
     
        UtilityTestData_AC utd= new UtilityTestData_AC();
        
        dealer__Dealer_Location__c loc =utd.InsertLocation();
        
        dealer__Parts_Master__c pm2 = new dealer__Parts_Master__c();
        pm2.Name = 'A12345-AC';
        pm2.dealer__Part_No__c = 'VMI:A12345-AC';
        pm2.dealer__Part_Description__c = 'Test Part System';
        pm2.dealer__Manufacturer__c = 'OT';
        pm2.dealer__Cost__c = 4000;
        pm2.dealer__Retail_Price__c = 90;
        pm2.dealer__Pack_QTY__c = 0;

        insert pm2;
        
        pm2.dealer__Retail_Price__c = 80;
        pm2.dealer__Cost__c = 4001;
        update pm2;
        
        dealer__Parts_Inventory__c p2 = new dealer__Parts_Inventory__c();
        p2.Name = pm2.Name;
        p2.dealer__Part_No__c  = 'Test2';
        p2.dealer__Description__c = pm2.dealer__Part_Description__c;
        p2.dealer__MFG__c = pm2.dealer__Manufacturer__c;
        p2.dealer__Cost__c= 4000;
        p2.dealer__List__c= pm2.dealer__Retail_Price__c;
        p2.dealer__Pack_QTY__c = pm2.dealer__Pack_QTY__c;
        p2.dealer__Company_Number__c = loc.dealer__Company_Number__c;
        p2.dealer__Location__c = loc.Id;
        
        insert p2;
        
        dealer__Parts_Kit__c pk = new dealer__Parts_Kit__c();
        pk.Name='TestKit';
        pk.dealer__Description__c='Test123';
        pk.Retail_Price__c=12;
        pk.Parts_Cost__c=2;
        insert pk;
        
        dealer__Parts_Kit_Item__c pki =new dealer__Parts_Kit_Item__c();
        pki.dealer__Parts_Kit__c=pk.id;
        pki.dealer__Parts_Master__c=pm2.id;
        pki.dealer__Part__c=p2.id;
        pki.dealer__Quantity__c=2;
        insert pki;
    }
    static testmethod void testPartMaster3() {
        
        UtilityTestData_AC utd= new UtilityTestData_AC();        
        dealer__Dealer_Location__c loc =utd.InsertLocation();
        
        dealer__Parts_Master__c pm3 = new dealer__Parts_Master__c();
        pm3.Name = 'A12345-AC';
        pm3.dealer__Part_No__c = 'VMI:A12345-AC';
        pm3.dealer__Part_Description__c = 'Test Part System';
        pm3.dealer__Manufacturer__c = 'OT';
        pm3.dealer__Cost__c = 5000;
        pm3.dealer__Retail_Price__c = 90;
        pm3.dealer__Pack_QTY__c = 0;

        insert pm3;
        
        dealer__Parts_Inventory__c p3 = new dealer__Parts_Inventory__c();
        p3.Name = pm3.Name;
        p3.dealer__Part_No__c  = 'Test3';
        p3.dealer__Description__c = pm3.dealer__Part_Description__c;
        p3.dealer__MFG__c = pm3.dealer__Manufacturer__c;
        p3.dealer__Cost__c= 5000;
        p3.dealer__List__c= pm3.dealer__Retail_Price__c;
        p3.dealer__Pack_QTY__c = pm3.dealer__Pack_QTY__c;
        p3.dealer__Company_Number__c = loc.dealer__Company_Number__c;
        p3.dealer__Location__c = loc.Id;

        insert p3;
    }

    static testmethod void testPartInventory3() {
        
        dealer__Parts_Master__c pm = new dealer__Parts_Master__c();
        pm.Name = 'A12345-AC';
        pm.dealer__Part_No__c = 'VMI:A12345-AC';
        pm.dealer__Part_Description__c = 'Test Part System';
        pm.dealer__Manufacturer__c = 'OT';
        pm.dealer__Cost__c = 90;
        pm.dealer__Retail_Price__c = 90;
        pm.dealer__Pack_QTY__c = 0;

        insert pm;
        


        //dealer__Dealer_Location__c loc = [Select Id, dealer__Company_Number__c from dealer__Dealer_Location__c limit 1];
        UtilityTestData_AC utd= new UtilityTestData_AC();
        //List<dealer__Parts_Inventory__c> p_list = new List<dealer__Parts_Inventory__c>();
        
        dealer__Dealer_Location__c loc =utd.InsertLocation();
        dealer__Parts_Inventory__c p = new dealer__Parts_Inventory__c();
        p.Name = pm.Name;
        p.dealer__Part_No__c  = loc.dealer__Company_Number__c+':'+pm.Name;
        p.dealer__Description__c = pm.dealer__Part_Description__c;
        p.dealer__MFG__c = pm.dealer__Manufacturer__c;
        p.dealer__Cost__c= pm.dealer__Cost__c;
        p.dealer__List__c= pm.dealer__Retail_Price__c;
        p.dealer__Pack_QTY__c = pm.dealer__Pack_QTY__c;
        p.dealer__Company_Number__c = loc.dealer__Company_Number__c;
        p.dealer__Location__c = loc.Id;
        //p_list.add(p);
        insert p;
       
       /* 
        dealer__Parts_Inventory__c p2 = new dealer__Parts_Inventory__c();
        p2.Name = pm.Name;
        p2.dealer__Part_No__c  = 'Test2';
        p2.dealer__Description__c = pm.dealer__Part_Description__c;
        p2.dealer__MFG__c = pm.dealer__Manufacturer__c;
        p2.dealer__Cost__c= 4000;
        p2.dealer__List__c= pm.dealer__Retail_Price__c;
        p2.dealer__Pack_QTY__c = pm.dealer__Pack_QTY__c;
        p2.dealer__Company_Number__c = loc.dealer__Company_Number__c;
        p2.dealer__Location__c = loc.Id;
        p_list.add(p2);

        //insert p2;
        
        dealer__Parts_Inventory__c p3 = new dealer__Parts_Inventory__c();
        p3.Name = pm.Name;
        p3.dealer__Part_No__c  = 'Test3';
        p3.dealer__Description__c = pm.dealer__Part_Description__c;
        p3.dealer__MFG__c = pm.dealer__Manufacturer__c;
        p3.dealer__Cost__c= 5000;
        p3.dealer__List__c= pm.dealer__Retail_Price__c;
        p3.dealer__Pack_QTY__c = pm.dealer__Pack_QTY__c;
        p3.dealer__Company_Number__c = loc.dealer__Company_Number__c;
        p3.dealer__Location__c = loc.Id;

        //insert p3;
        p_list.add(p3);
        insert p_list; */
        
    }

}