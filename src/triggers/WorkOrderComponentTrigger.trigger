/**
* TransitWorks (c) - 2018
*
* SOCONFIGTrigger
* 
* Tested by: 
* Programmer: Alexander Miller
* Date: 2018-04-23
*/
trigger WorkOrderComponentTrigger on rstk__woorddmd__c (After Insert) {

    WorkOrderComponentTriggerHandler tempHandler = new WorkOrderComponentTriggerHandler(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);

    if(Trigger.isInsert)
    {
        tempHandler.refreshList();
        temphandler.updateWorkOrderComponentsWithProducts();
    }
    
    tempHandler.updateMaps();
}