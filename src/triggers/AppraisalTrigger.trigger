/**
 * AppraisalTrigger
 * Tested by: ? // AppraisalTrigger_TEST 
 * Date: Feb 16, 2018
 * Programmer: Bryan Leaman
 *
 */
trigger AppraisalTrigger on dealer__Appraisal__c (after update) {

	MW_TriggerControls__c wonappraisals = MW_TriggerControls__c.getInstance('WonAppraisals');
	if (wonappraisals==null || wonappraisals.Enabled__c) new AppraisalProcess(Trigger.new, Trigger.oldMap).ProcessWonAppraisals();

}