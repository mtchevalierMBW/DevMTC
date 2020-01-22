/**
 * upload_RO_Helpers_TEST
 * Tests: upload_RO_Detail_Helper, upload_RO_Invoice_Helper
 *
 *  2016-07-18  B. Leaman   BLL1 - MCEO requires a quote number on the RO, so skip certain service payment types.
 *  2018-05-07  B. Leaman   BLL2 - IE* requires a proposal number on the RO, so skip those too.
 *	2019-07-22	B. Leaman	BLL3 - need to select active labor types!
 * TODO: remove need for seealldata=true
 */
@isTest(seeAllData=true)
private class upload_RO_Helpers_TEST {

    static testMethod void uploadROHelpers() {

        dealer__Dealer_Location__c loc = [select Id, Name from dealer__Dealer_Location__c limit 1];
        //RecordType rt = [select Id, Name from RecordType where isPersonType=true limit 1];
        //Account a = new Account(RecordTypeId = rt.Id, FirstName='TestRO', LastName='ROLast', BillingState='OH', BillingPostalCode='44742',
        //          dealer__External_ID__c='RO_TEST_EXTID_123');
        //insert(a);
		TestHelper_MW th = new TestHelper_MW();
		Account a = th.getPersonAccount('1');
		a.dealer__External_ID__c='RO_TEST_EXTID_123';
		update(a);

        dealer__Service_Repair_Order__c sro = new dealer__Service_Repair_Order__c();
        sro.dealer__Mileage_In__c = 1;
        sro.dealer__RO_Number__c = 'TEST_RO_12345_BLL';
        sro.upload_Customer__c = a.dealer__External_ID__c;
        sro.upload_Location__c = loc.Name;
        insert(sro);

        ServicePaymentType__c  spt = [
            Select name, id, Payment_Type__c 
            From ServicePaymentType__c
            where Name not in ('MCEO', 'GRNV', 'GRUV', 'IEO', 'IEU', 'IEN') // BLL1a, BLL2ac
			  and Active__c=true	// BLL3a
            limit 1
        ]; 

        dealer__Service_Job__c sj= new dealer__Service_Job__c();
        sj.Upload_Pay_Method__c = spt.Name;
        sj.dealer__Service_Repair_Order__c = sro.Id;
        insert(sj);
        
        dealer__Service_Job__c sjafter = [
            select Id, Name, Upload_Pay_Method__c, Payment_Method__c, dealer__Labor_Type__c
            from dealer__Service_Job__c 
            where Id=:sj.Id 
            limit 1
        ];
        System.assert(sjafter.upload_Pay_Method__c==null, 'Upload Pay Method was not removed');
        System.assert(sjafter.Payment_Method__c!=null, 'Pay Method was not assigned');
        System.assert(sjafter.dealer__Labor_Type__c!=null, 'Labor Type was not removed');
    }
    
}