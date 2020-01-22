/**
* ConfigurationSessionTrigger
* Tested By: objectTriggerTest
* Programmer: Alexander Miller
* 
* Description: Trigger to handle all process operations for the Configuration Session object
*
* Alexander Miller - 8/31/2018 - AMILLER1 - Update to handle prevention of clones when the session is deactivated
* Alexander Miller - 9/24/2018 - AMILLER2 - W-000361 - Update to handle custom Opportunity linking
*/
trigger ConfigurationSessionTrigger on rstk__confsess__c (after update, after Insert) {

    ConfigurationSessionTriggerHandler tempHandler = new ConfigurationSessionTriggerHandler(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
    
    if(Trigger.isAfter) 
    {
        if(tempHandler.runOnce())
        {
            tempHandler.markLatestSalesOrder();
            tempHandler.pasteClone();
            // AMILLER2
            tempHandler.copyCustomOpportunityLink(Trigger.new);
            // AMILLER2
            tempHandler.updateMaps(); 
        }
        
        //tempHandler.preventCloneOnDeactivatedSessions(Trigger.new);
    }
}