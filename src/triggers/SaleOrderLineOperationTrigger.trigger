/**
* TransitWorks (c) - 2018
*
* WorkOrderOperationTrigger
* 
* Tested by: 
* Programmer: Alexander Miller
* Date: 2018-04-23
*/
trigger SaleOrderLineOperationTrigger on rstk__sortoper__c (After Insert) {

    SaleOrderLineOperationTriggerHandler tempHandler = new SaleOrderLineOperationTriggerHandler(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);

    if(Trigger.isInsert)
    {
        if(SaleOrderLineOperationTriggerHandler.flag == true)
        {
            SaleOrderLineOperationTriggerHandler.flag = false;
            tempHandler.refreshList();
            temphandler.updateProductMasters();
            tempHandler.updateMaps();
        }
    }
}