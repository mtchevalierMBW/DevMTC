/**
 * CashierTrigger
 * Tested by: CashierTrigger_TEST
 * Date: 2019-04-19
 * Programmer: Bryan Leaman
 * Project: W-000575 & W-000710
 *
 * Coverage:
 *	2019-04-19	88% (38/43)
 *
 * Modifications: 
 *
 */
 trigger CashierTrigger on dealer__Cashering__c (before update, before delete, after insert, after update, after delete) {

	 System.debug('CashierTrigger');
	CashierProcess.ProtectCashierRecords(Trigger.new, Trigger.old, Trigger.oldMap,
		Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete, Trigger.isBefore, Trigger.isAfter);

	// BLL1
	if (Trigger.isBefore && !Trigger.isDelete) CashierProcess.SetCompanyNumber(Trigger.new);
	// BLL1 end

	if (Trigger.isAfter) CashierProcess.UpdateDocumentTotals(Trigger.new, Trigger.oldMap, Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete);

}