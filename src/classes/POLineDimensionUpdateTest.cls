@isTest
public class POLineDimensionUpdateTest{
    public static testmethod void executePOLineDimensionUpdate(){
        Test.startTest();
        
        //Account a = new Account(Name='Test Acc');
        //a.dealer__Vendor__c = true;
        //a.BillingState = 'CA';
        //insert a;
		TestHelper_MW th = new TestHelper_MW();
		Account a = th.getBusinessAccount('1');

        
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
        
        dealer__Service_Repair_Order__c dsr = new dealer__Service_Repair_Order__c();
        dsr.dealer__Customer__c =a.id;
        dsr.dealer__Mileage_In__c =13;
        dsr.dealer__RO_Number__c ='12';
        insert dsr;
        
        dealer__Service_Job__c dsj = new dealer__Service_Job__c();
        dsj.dealer__Cause__c ='Test Job';
        dsj.dealer__Labor_Charges__c =12;
        dsj.dealer__Service_Repair_Order__c =dsr.id;
        dsj.dealer__Labor_Type__c = 'I';
        insert dsj;
        
        // BLL1a
		Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Purchase_Order__c.getRecordTypeInfosByName();
		Schema.RecordTypeInfo rtInfo = RcdTypes.get('Vehicle Purchase');
		// BLL1a end
		
        c2g__codaDimension1__c dimWMK = new c2g__codaDimension1__c();
        dimWMK.Name = '100 - WMK, LLC. COMPANY DIMENSION';
        dimWMK.c2g__ReportingCode__c = 'FFA3B';
        insert(dimWMK);
        
        //Insert record for Location object
        dealer__Dealer_Location__c objLocation = new dealer__Dealer_Location__c();
        objLocation.Name = 'Test';
        objLocation.dealer__City__c = 'City';
        objLocation.dealer__Company_Number__c = '123';
        objLocation.dealer__Postal_Code__c = '123324';
        objLocation.dealer__State__c = 'CA';
        objLocation.Financial_Force_Dimension_1__c = dimWMK.Id;
        insert objLocation;
        
        dealer__Purchase_Order__c po = new dealer__Purchase_Order__c();
        po.RecordTypeId = rtInfo.getRecordTypeId();	// BLL1a
        po.dealer__Vendor__c = a.Id;
        po.dealer__Service_Repair_Order__c = dsr.Id;
        po.dealer__Company__c = objLocation.Id;
        po.dealer__Status__c = 'Open';
        insert po;

        dealer__Purchase_Order_Line__c poline = new dealer__Purchase_Order_Line__c();
        poline.dealer__Purchase_Order__c = po.Id;
        poline.dealer__Service_Job_Line__c = dsj.Id;
        poline.dealer__Amount__c = 100;
        //poline.dealer__Customer_Total__c = 110;	// BLL1a
        insert poline;
        
        POLineDimensionUpdate objBatch = new POLineDimensionUpdate();
        Database.executeBatch(objBatch);
        Test.stopTest();
    }
}