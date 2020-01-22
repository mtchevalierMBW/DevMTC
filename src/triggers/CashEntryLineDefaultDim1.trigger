/**
 * CashEntryLineDefaultDim1
 * Tested by: TransactionReferences_TEST,DefaultDimension1_TEST,CashEntryTrigger_TEST
 * Programmer: Bryan Leaman
 * Date: Jan 29, 2016
 */
trigger CashEntryLineDefaultDim1 on c2g__codaCashEntryLineItem__c (before insert, before update) {

    MW_TriggerControls__c DefaultDim1 = MW_TriggerControls__c.getInstance('DefaultDimension1');
    if (DefaultDim1==null || DefaultDim1.Enabled__c) Dimension1Default.CashEntryPaymentLines(Trigger.new);
    
	CashierProcess.RestrictManualCashEntryLines(Trigger.new);

}