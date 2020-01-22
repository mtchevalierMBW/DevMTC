/**
PartInvoiceLineControl
Tested by:

Coverage:

Modifications:
2019-11-22	IN00077189	BLL1 - copy order urgency into part line (if empty and if line came from an estimate)

**/
trigger PartInvoiceLineControl on dealer__Parts_Invoice_Line__c (before insert, after insert, before update) {
	
	// BLL1
	MW_TriggerControls__c SublineOrderUrgency = MW_TriggerControls__c.getInstance('SublineOrderUrgency');
	if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
		if (SublineOrderUrgency==null || SublineOrderUrgency.Enabled__c) {
			System.debug('CopyOrderUrgencyFromEstimate');
			CentralizedPartsAPI.CopyOrderUrgencyFromEstimate(Trigger.new);
		}
	}
	// BLL1 end
    if(Trigger.isAfter && Trigger.isInsert) {
        CentralizedPartsAPI.createCPTRecordsFromConvertedEstimate(Trigger.new);
    }
}