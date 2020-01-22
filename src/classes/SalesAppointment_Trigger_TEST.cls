/**
 * SalesAppointment_Trigger_TEST
 * Create 2 First Visit appointments and test that the second generated an exception.
 * Tests SalesAppointment_Trigger
 *
 * 	2015-06-12  B. Leaman     Created
 *	2018-09-13	B. Leaman	Try to reduce SOQL queries by setting start/stop test boundaries.
 *	2019-09-18	B. Leaman	W-000730 BLL1 new requirements in DT 5.x
 */
@isTest
private class SalesAppointment_Trigger_TEST {

	// BLL1
	@TestSetup
	static void setupEnv() {
		dealer.TestClassUtil tc = new dealer.TestClassUtil();
		tc.insertDMSSettings();
	}
	// BLL1

    static testMethod void OnlyOneFirstVisit() {
        // turn on BDC appt flag for this user
        MW_BDC_Settings__c bdc = MW_BDC_Settings__c.getValues(UserInfo.getUserId());
        if (bdc==null) bdc = new MW_BDC_Settings__c(SetupOwnerId=UserInfo.getUserId());
        bdc.BDC_Created_SalesAppt__c = true;
        upsert(bdc);

        RecordType rt = [select Id, Name from RecordType 
                         where SObjectType='Account' and IsPersonType=true
                         limit 1];
        // Create a person account
        Account p = new Account(
            RecordTypeId=rt.Id, 
            FirstName='Test', 
            LastName='PersonAccount'
        );
        insert(p);
        p = [select Id, FirstName, LastName, PersonContactId from Account where Id=:p.Id];
        
        // Create a solution opportunity
        dealer__Sales_Up__c s = new dealer__Sales_Up__c(
            Name='Test Solution Opportunity',
            dealer__Customer_Account__c = p.Id 
        );
        insert(s);
        
        Test.startTest();	// BLL1a
        
        DateTime dt = DateTime.now();
        dealer__Sales_Appointment__c appt1 = new dealer__Sales_Appointment__c(
           dealer__Appointment_Type__c = 'First Visit',
           dealer__Assigned_To__c = UserInfo.getUserId(),
           dealer__Customer__c = p.PersonContactId,
           dealer__Sales_Up__c = s.Id,
           dealer__DateTime__c = dt,
           dealer__Date__c = dt.date(),
           dealer__Time__c = dt.format('hh:mm a')
        );
        insert(appt1);
        dealer__Sales_Appointment__c appt2 = new dealer__Sales_Appointment__c(
           dealer__Appointment_Type__c = 'First Visit',
           dealer__Assigned_To__c = UserInfo.getUserId(),
           dealer__Customer__c = p.PersonContactId,
           dealer__Sales_Up__c = s.Id,
           dealer__DateTime__c = dt,
           dealer__Date__c = dt.date(),
           dealer__Time__c = dt.format('hh:mm a')
        );
        try {
            insert(appt2);
        } catch(Exception e) {
            System.assert(e.getMessage().contains('first visit'), 'Did not get an error on second first visit');
        }
        appt1.dealer__Appointment_Type__c = 'Other';
        update(appt1);

        Test.stopTest();	// BLL1a

    }
}