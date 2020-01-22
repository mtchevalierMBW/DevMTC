/**
 * SalesAppointment_Trigger
 * Test by: SalesAppointment_Trigger_TEST 
 * Uses: MW_TriggerControls__c custom setting 'Sales_Appt_First_Visit'
 * 
 * Code coverage:
 *  2018-05-14  100%    (9/9)
 *
 * Modification log:
 *  2015-06-12  B. Leaman   Created
 *  2015-10-22  B. Leaman   BLL1 - set new BDC_Created flag & BDC Rep when the BDC creates the appointment.
 *  2016-08-11  B. Leaman   BLL2 - Set owner as the person assigned to for My Team to work.
 *  2016-12-05  B. Leaman   BLL3 - No appointment allowed on a 'Quote' Solution Opp. First appointment *must* be a 'First visit'.
 *  2017-10-16  B. Leaman   BLL4 - ensure no nulls in lists for soql.
 *  2017-10-17  B. Leaman   BLL5 - update to use currentusersingleton.
 *  2018-01-26  B. Leaman   BLL6 - soft-code BDC settings to allow for exceptions by user.
 *	2018-10-03	B. Leaman	BLL7 W-000448 - auto-populate account from the contact (where possible).
 */
    
trigger SalesAppointment_Trigger on dealer__Sales_Appointment__c (before insert, before update) {

    SalesAppointmentProcess sappt = new SalesAppointmentProcess(Trigger.new, Trigger.oldMap);

    // BLL1a - BDC_Created flag
    if (Trigger.isBefore && Trigger.isInsert) {
        sappt.BdcTracking();
        sappt.MarketingScore();
    }
    // BLL1a end

    if (Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert)) {

        // set owner according to assignee (or running user)
        sappt.AssigneeAsOwner();
        sappt.PopulateAccountFromContact();	// BLL7a

        MW_TriggerControls__c SlsApptFirstVisit = MW_TriggerControls__c.getInstance('Sales_Appt_First_Visit');
        if (SlsApptFirstVisit==null || SlsApptFirstVisit.Enabled__c) {
            // One and only 1 first visit, no appt on "quote" types
            sappt.FirstVisitControls();
        }

    } // end if isBefore and (isInsert or isUpdate)

    //class SalesAppointmentException extends Exception {}

}