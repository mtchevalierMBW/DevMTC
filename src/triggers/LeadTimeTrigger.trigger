/**
* TransitWorks (c) - 2018
*
* LeadTimeTriggerHandler
*
* Created By: Alexander Miller
* Created Date: 8/20/2018
* Tested By: LeadTimeTriggerHandlerTest
*/
trigger LeadTimeTrigger on Lead_Time__c (after insert, after update) {
	
    LeadTimeTriggerHandler tempHandler = new LeadTimeTriggerHandler();
    
    if(Trigger.isAfter)
    {
        if(Trigger.isUpdate || Trigger.isInsert)
        {
            tempHandler.flagIfIdenticalLeadTimeExists(Trigger.new);
        }
	}    
}