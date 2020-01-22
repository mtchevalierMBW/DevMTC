/**
 * WMK, LLC (c) - 2018 
 *
 * ProjectBudgetCostTrigger
 * 
 * Created By:   Alexander Miller
 * Created Date: 11/22/2018 
 * Tested By:    ProjectBudgetCostTriggerHandlerTest
 * Work Item:    W-000498
 *
 * Modified By         Alias       Work Item       Date         Reason
 * -------------------------------------------------------------------
 * Alexander Miller    AMM1        W-000589      2/18/2019     Update to capture NIC Issue transactions
 */
trigger ProjectBudgetCostTrigger on rstk__pjprojcst__c (after update) {

    ProjectBudgetCostTriggerHandler tempHandler = new ProjectBudgetCostTriggerHandler();

    if(Trigger.isAfter)
    {
        if(Trigger.isUpdate)
        {
            if(ProjectBudgetCostTriggerHandler.runOnce())
            {
                tempHandler.updateProjectPartSaleCost(Trigger.new);

                tempHandler.updateProjectFreightCost(Trigger.new);

                tempHandler.updateProjectFreightSale(Trigger.new);
                
                tempHandler.updateProjectSalesTax(Trigger.new);
                
                tempHandler.updateProjectIntercompany(Trigger.new);

                tempHandler.updateRelatedOpporutnities(Trigger.new);

                // AMM1
                tempHandler.updateProjectNicIssue(Trigger.new);
                // AMM1

                tempHandler.updateMaps();
            }
        }
    }
}