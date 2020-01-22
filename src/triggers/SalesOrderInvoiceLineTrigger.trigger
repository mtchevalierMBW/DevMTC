/**
 * SalesOrderInvoiceLineTrigger
 * Tested by: SalesOrderInvoiceLineTriggerHandlerTest
 * Date: August 17th, 2018
 * Programmer: Alexander Miller
 *
 * Alexander Miller - AMM1 - IR-0047426 - 1/24/2019 - Update to handle the insertion of the records so Product Names are pasted
 */
trigger SalesOrderInvoiceLineTrigger on rstk__soinvline__c (before update, before insert, after update, after insert) {

    SalesOrderInvoiceLineTriggerHandler tempHandler = new SalesOrderInvoiceLineTriggerHandler();

    // AMM1
    // if(Trigger.isUpdate)
    if(Trigger.isUpdate || Trigger.isInsert)
    // AMM1
    {
        //List<rstk__soinvline__c> tempList = tempHandler.refreshAllFieldsNeeded(Trigger.new);

        tempHandler.salesOrderInvoiceLineProductNamePasting(Trigger.new);
    }
}