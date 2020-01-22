/**
 * PayableCreditNoteTrigger
 * Tested by: Dimension1Default_TEST
 * Date: Jun 13, 2018
 * Programmer: Bryan Leaman
 *
 */
trigger PayableCreditNoteTrigger on c2g__codaPurchaseCreditNote__c (before insert, before update) {

	Dimension1Default.PayableCredits(Trigger.new);

}