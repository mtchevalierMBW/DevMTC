/**
* TransitWorks (c) - 2018
*
* SOCONFIGTrigger
* 
* Tested by: 
* Programmer: Alexander Miller
* Date: 2018-04-23
*/
trigger SOCONFIGTrigger on rstk__soconfig__c (After insert) {

    SOCONFIGTriggerHandler tempHandler = new SOCONFIGTriggerHandler(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);

    if(Trigger.isInsert)
    {
        if(SOCONFIGTriggerHandler.flag == true)
        {
            SOCONFIGTriggerHandler.flag = false;
            tempHandler.refreshList();
            tempHandler.updateProductMasters();
        }
    }
    
    tempHandler.updateMaps();
}