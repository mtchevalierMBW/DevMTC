/**
 * PayableInvoiceTrigger
 * Tested by: Dimension1Default_TEST
 * Date: Jun 13, 2018
 * Programmer: Bryan Leaman
 *
 */
trigger PayableInvoiceTrigger on c2g__codaPurchaseInvoice__c (before insert, before update) {

		Dimension1Default.PayableInvoices(Trigger.new);

}