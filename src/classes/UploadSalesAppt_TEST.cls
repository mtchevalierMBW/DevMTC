/**
 * UploadSalesAppt_TEST
 * Tests: Upload_Link_Sales_Appt_to_SLOP
 * Date: 2015-12-22
 * Written by: Bryan Leaman
 * 
 *	2016-09-08	B. Leaman	BLL1 - fix test - need assigned-to as well as owner.
 *	2019-09-18	B. Leaman	W-000730 BLL2 - new requirements in DT 5.x
 */
@isTest
private class UploadSalesAppt_TEST {

	// BLL2
	@TestSetup
	static void setupEnv() {
		dealer.TestClassUtil tc = new dealer.TestClassUtil();
		tc.insertDMSSettings();
	}
	// BLL2

    static testMethod void myUnitTest() {
    	TestHelper_MW th = new TestHelper_MW();
    	User own = th.getTestUser('1');
		System.debug(own);
		
		Account pa = th.getPersonAccount('1');
		pa = [select Id, Name, PersonContactId from Account where Id=:pa.Id limit 1];
		System.debug(pa);
		
		dealer__Dealer_Location__c loc = th.getDealerLocation('1');
		
		dealer__Sales_Up__c sup = new dealer__Sales_Up__c(
			Legacy_ID__c = 'TEST_LEGACY_1',
			dealer__Buyer_Contact__c = pa.PersonContactId,
			OwnerId = own.Id
		);
		insert(sup);
		System.debug(sup);
		
		Test.startTest();

		dealer__Sales_Appointment__c sa = new dealer__Sales_Appointment__c(
			Legacy_Opportunity__c = sup.Legacy_ID__c,
			dealer__Customer__c = pa.PersonContactId,
			dealer__Date__c = Date.today(),
			dealer__Time__c = '10:00 AM',
			dealer__DateTime__c = Datetime.now(),
			Upload_Location__c = loc.Name,
		    Upload_Owner__c = own.Name,
		    dealer__Assigned_To__c = own.Id		// BLL1a
		);
		insert(sa);
		System.debug(sa);
		
		dealer__Sales_Appointment__c sa2 = new dealer__Sales_Appointment__c(
			Legacy_Opportunity__c = sup.Legacy_ID__c,
			dealer__Customer__c = pa.PersonContactId,
			dealer__Date__c = Date.today(),
			dealer__Time__c = '11:00 AM',
			dealer__DateTime__c = Datetime.now(),
			Upload_Location__c = loc.Name,
		    Upload_Owner__c = 'x' + own.Name + 'x'
		);
		insert(sa2);
		System.debug(sa2);
		
		Test.stopTest();
		
		List<dealer__Sales_Appointment__c> sas = [
			select Id, Name, OwnerId, dealer__Assigned_To__c
			from dealer__Sales_Appointment__c
			where Id in (:sa.Id, :sa2.Id) 
		];
		System.assert(sas.size()==2, 'Did not create 2 appointments');
		System.assert(sas[0].dealer__Assigned_To__c!=sas[1].dealer__Assigned_To__c, 'Both appointments have the same owner');
		
    }
}