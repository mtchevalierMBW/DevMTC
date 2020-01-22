/**
 * CreditApplicationTrigger
 * Tested by: CreditApplicationTrigger_TEST
 * Date: 2019-02-26
 * Programmer: Bryan Leaman
 * Project: W-000579
 * Update proposal F&I overall status info when credit application statuses are updated.
 *
 * Coverage:
 *
 * Modifications: 
 *	2019-07-03	B. Leaman	BLL1 - add integrity updates (Approved vs Countered sts)
 */
 trigger CreditApplicationTrigger on dealer__Credit_Application__c (before insert, after insert, after update, after delete) {

	 if (Trigger.isBefore && Trigger.isInsert) {
		 CreditApplicationProcess.creditApplicationDefaults(Trigger.new);
	 }

	// BLL1
	if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
		CreditApplicationProcess.creditApplicationIntegrity(Trigger.new);
	}
	// BLL1 end

	MW_TriggerControls__c ProposalCreditAppSts = MW_TriggerControls__c.getInstance('ProposalCreditAppSts');
	if (Trigger.isAfter && !Trigger.isDelete) {
		// Reflect any changes in credit applications to overall proposal status
		if (ProposalCreditAppSts==null || ProposalCreditAppSts.Enabled__c) {
			CreditApplicationProcess.updateCreditAppProposalStatus(Trigger.new);
		}
	}

	if (Trigger.isAfter && Trigger.isDelete) {
		// Deleting a credit application can alter the overall proposal credit status too!
		if (ProposalCreditAppSts==null || ProposalCreditAppSts.Enabled__c) {
			CreditApplicationProcess.updateCreditAppProposalStatus(Trigger.old);
		}
	}

}