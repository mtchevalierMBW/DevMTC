/**
* TransitWorks (c) - 2018
*
* WorkOrderOperationTrigger
* 
* Tested by: 
* Programmer: Alexander Miller
* Date: 2018-04-23
*/
trigger WorkOrderOperationTrigger on rstk__woordop__c (After Insert) {

    WorkOrderOperationTriggerHandler tempHandler = new WorkOrderOperationTriggerHandler(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);

    if(Trigger.isInsert)
    {
        tempHandler.refreshList();
        temphandler.updateWorkOrderComponentsWithProducts();
    }
    
    tempHandler.updateMaps();
}