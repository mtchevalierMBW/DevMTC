/**
 * SalesOrderInvoiceHeaderTrigger 
 * Tested by: SalesOrderInvHdrTriggerHandler
 * Date: Oct 18, 2017
 * Programmer: Alexander Miller
 *
 * 06-28-2018 Alexander Miller (AMILLER) - Bug 000356 idenfied where the future will fire and take up the Async channels even though it won't 
 *                                           update the County because the County field is already filled in. Migrated pre-processing check to the Handler
 *                                           to prevent Future fires from happening unless absolutely needed.
 * 02-19-2019 Alexander Miller (AMM1)     - IR-0049158 - Update to handle Project Budget/Cost record update since it doesn't seem to occur on invoicing
 */
trigger SalesOrderInvoiceHeaderTrigger on rstk__soinv__c (after update) {
    
    if(Trigger.isAfter)
    {  
        if(SalesOrderInvoiceHeaderTriggerHandler.runOnce)
        {
            SalesOrderInvoiceHeaderTriggerHandler.fireFutureLocateAddressIfNeeded(Trigger.new);
        } 
        
        if(Trigger.isUpdate)
        { 
            SalesOrderInvoiceHeaderTriggerHandler.addChassisToFinancialForceRecords(Trigger.new);   

            // AMM1
            SalesOrderInvoiceHeaderTriggerHandler.updateProjectBudgetCostTransferToAR(Trigger.new, Trigger.oldMap);
            // AMM1
        }

        SalesOrderInvoiceHeaderTriggerHandler.updateAllMaps();
    }
}