/**
* MobilityWorks (c) - 2017
*
* Tested By:
* Created Date: 11/10/2017
* Developer: Alexander Miller
*
* Alexander Miller - AMILLER7 - 7/02/2018 - Update to automatically roll up Work Order GP Calculations of Work Orders on non-canceled Sales Orders Headers
* Alexander Miller - AMILLER8 - 9/24/2018 - W-000361 - Update to handle the new Opportunity object for TransitWorks
* Alexander Miller - AMM9     - 11/21/2018 -  W-000501 - Update to win Opportunities on Sales Order firm. Work Order "winning" logic is no longer needed
* Alexander Miller - AMM10    - 11/21/2018 - W-000493 - Update to disable the WOrk Order 2020 Due Date functionality so we could upgrade from 18.3.3 to 19.30
* Alexander MIller - AMM11    - 11/07/2019 - IN00075421 - Update to record the original labor of the Work Order on creation
*/
trigger workOrderTrigger on rstk__wocst__c (before insert, before update, after insert, after update) {

    WorkOrderTriggerHandler tempHandler = new WorkOrderTriggerHandler(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);  

    if(Trigger.isBefore)
    {
        // AMM10
        // if(Trigger.isInsert)
        // {
        //     tempHandler.updateWorkOrderDueDateForScheduling();
        // }
        // AMM10

        tempHandler.updateLinkingToChassis();
        tempHandler.updateSalesRepEmail();

        if(Trigger.isUpdate)
        {
            tempHandler.refreshAllFieldsNeeded();
            temphandler.updatePromiseDate();
            // AMM11
            tempHandler.recordOriginalLaborHoursOnCreate(); 
            // AMM11
        }
    }
    else if(Trigger.isAfter)
    {
        tempHandler.refreshAllFieldsNeeded();

        if(Trigger.isUpdate || Trigger.isInsert) 
        {            
            tempHandler.updateLinkingToChassisWithWorkOrders(); 
            tempHandler.updatePlannedBuildDate();
            tempHandler.updatePlannedBuildCompleteDate();
            tempHandler.updateBuildStartDate();
            tempHandler.updateBuildCompletDate();
            // AMILLER8
            tempHandler.updateWorkOrderWithCustomOpp();
            // AMILLER8
        }

        // AMM9
        // if(Trigger.isInsert)
        // {
        //     tempHandler.updateOpportunityToWonStatus();
        // }
        // AMM9

        // AMILLER7 AMILLER8
        if(Trigger.isUpdate)
        {
            //tempHandler.updateRelatedOpportunityTotalEstimatedGP();
        }
        // AMILLER7 AMILLER8

        tempHandler.updateAllMaps();
    }
}