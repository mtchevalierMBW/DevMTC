/**
* CashMatchingHistoryTrigger
* Tested by: CashMatchingProcess_TEST
* Date: July 23, 2018
* Programmer: Bryan Leaman
*
*	2018-07-23	B. Leaman	IR-0012718/W-000474	Written.
*
**/
trigger CashMatchingHistoryTrigger on c2g__codaCashMatchingHistory__c (before insert, before update) {

	MW_TriggerControls__c CashMatchCrossDimProtect = MW_TriggerControls__c.getInstance('CashMatchCrossDimProtect');
	if (Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert)) {
		if (CashMatchCrossDimProtect==null || CashMatchCrossDimProtect.Enabled__c) 
			CashMatchingProcess.PreventMatchingAcrossDimension1s(Trigger.new);
	} 
    
}