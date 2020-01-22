/**
 * TransactionLineDefaultDim1
 * Tested by: TransactionReferences_TEST,DefaultDimension1_TEST
 * Programmer: Bryan Leaman
 * Date: Jan 29, 2016
 */
trigger TransactionLineDefaultDim1 on c2g__codaTransactionLineItem__c (before insert) {

    MW_TriggerControls__c DefaultDim1 = MW_TriggerControls__c.getInstance('DefaultDimension1');
    if (DefaultDim1==null || DefaultDim1.Enabled__c) Dimension1Default.TransactionLines(Trigger.new);
   
}