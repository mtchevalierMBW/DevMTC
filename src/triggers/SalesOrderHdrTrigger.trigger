/**
 * SalesOrderHdrTrigger
 * Tested by: SalesOrderDimensionProcess_TEST, SalesOrderHdrTriggerTest
 * Date: Jul 5, 2017
 * Programmer: Bryan Leaman
 *
 * Alexander Miller (AMILLER) 9.27.2017 Updating to handle Customer Linking for Chassis Master
 * Alexander Miller (AMILLER2) 9.27.2017 Prompting user to enter hold reason on Chassis if available
 * Alexander Miller (AMILLER3) 11.9.2017 Adding functionality to trigger the Process Builder handling Chassis Ship Charge on SO Line
 * Alexander Miller (AMILLER4) 5.2.2018 Update to only let this class run once per record
 * Alexander Miller (AMILLER5) 9.4.2018  Update to handle the removal of a Chassis from Sales Order Headers. The Chassis Master's references should be cleared out.
 * Alexander Miller (AMILLER6) 9.24.2018 - W-000361 - update to handle the new TransitWorks custom Opportunities
 * Alexander Miller (AMM7)     11.1.2018 - W-000464 - Update to handle Opportunity Allocation checks
 */
trigger SalesOrderHdrTrigger on rstk__sohdr__c (before update, before insert, after insert, after update) {

    MW_TriggerControls__c SalesOrderDimensionProcess = MW_TriggerControls__c.getInstance('SalesOrderDimensionProcess'); 
    if (SalesOrderDimensionProcess==null || SalesOrderDimensionProcess.Enabled__c==true) 
        new SalesOrderDimensionProcess(Trigger.new, Trigger.oldMap).updateLineDimensions(); 

    SalesOrderHdrTriggerHandler tempHandler = new SalesOrderHdrTriggerHandler(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);

    if(Trigger.isBefore)
    {
        if(Trigger.isUpdate)
        {
            tempHandler.chassisRemoval(Trigger.newMap, Trigger.oldMap); // AMILLER5
        }
    }
    else if(Trigger.isAfter)
    {
        // AMILLER4
        if(SalesOrderHdrTriggerHandler.runOnce())
        {
            tempHandler.refreshAllFieldsNeeded();

            // AMILLER6
            tempHandler.updateCustomOpportunityLink(); 
            tempHandler.updateSalesRep();
            // AMILLER6

            tempHandler.updateChassisTotalShipSale();
            
            if(Trigger.isUpdate)
            {
                tempHandler.linkChassis();
                tempHandler.updateRelatedWorkOrderIfChassisChanged();
            }

            if(Trigger.isInsert || Trigger.isUpdate)
            {
                temphandler.updateRelatedOpportunityTotalSoPrice();
                // AMM7
                tempHandler.checkIfChassisAllocationIsLegal(Trigger.newMap, Trigger.oldMap);
                tempHandler.checkIfChassisIsUsedInAnotherOrder(Trigger.newMap, Trigger.oldMap);
                // AMM7
            }
            
            tempHandler.updateAllMaps();
        }
    }
}