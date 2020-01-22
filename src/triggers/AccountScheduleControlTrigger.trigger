/**
 * AccountScheduleControlTrigger
 * Tested by: AccountScheduleControlProcess_TEST
 * Date: Jul 10, 2017
 * Programmer: Bryan Leaman
 *
 */
trigger AccountScheduleControlTrigger on AccountScheduleControl__c (before update) {

	if (Trigger.isBefore && Trigger.isUpdate) new AccountScheduleControlProcess().updateRequestedControlTotals(Trigger.new);

}