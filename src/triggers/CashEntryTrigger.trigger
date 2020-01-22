/**
 * CashEntryTrigger
 * Tested by: CashEntryTrigger_TEST
 * Date: 2019-05-15
 * Programmer: Bryan Leaman
 * Project: W-000575
 * Prevent stores from entering manual cash entries if they are using the new automated cash entry system.
 *
 * Coverage:
 *
 * Modifications: 
 *
 */
 trigger CashEntryTrigger on c2g__codaCashEntry__c (before insert, before update) {

	CashierProcess.RestrictManualCashEntries(Trigger.new);

}