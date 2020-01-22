/**
* MobilityWorks (c) - 2017
*
* WorkOrderTriggerHandler
* 
* Tested by: WorkOrderTriggerHandlerTest
* Programmer: Alexander Miller
* Date: 2017-09-14
*
* Primary handler class for the Work Order trigger
*
* Alexander Miller - AMILLER1 - 1/9/2018 - Updated to have promise date logic
* Alexander Miller - AMILLER2 - 2/2/2018 - Updates to handle reversals of Work Orders
* Alexander Miller - AMILLER3 - 3/14/2018 - Update to handle planned build and complete date to rely on Scheduler only
* Alexander Miller - AMILLER4 - 3/28/2018 - Update to handle setting all scheduled dates for MRP to future due date on insert
* Alexander Miller - AMILLER5 - 3/29/2018 - Update to allow Planned Completion Date to move with Scheduler Work Order Due Date Moves
* Alexander Miller - AMILLER6 - 4/23/2018 - Update ot allow super users to schedule. Update to say when standard hours equals actual, move to Production complete
* Alexander Miller - AMILLER7 - 9/5/2018 - Update to handle the new Opportunity field
* Alexander Miller - AMILLER8 - 9/24/2018 - W-00361 - Update to handle the new TransitWorks opportunity custom object
* Alexander Miller - AMM9     - 11/21/2018 -  W-000501 - Update to win Opportunities on Sales Order firm. Work Order "winning" logic is no longer needed
* Alexander Miller - AMM10    - 11/30/2018 - W-000493 - Disabling the need for the due date to be "unscheduled"
* Alexander Miller - AMM11    - 11/07/2019 - IN - Update to record the original labor of the Work Order on creation
* Alexander MIller - AMM12    - 12/10/2019 - Update requested for Communities to handle Promise and Planned Completion Dates
*/
public without sharing class WorkOrderTriggerHandler{

    public List<rstk__wocst__c> newList = new List<rstk__wocst__c>();
    public List<rstk__wocst__c> oldList = new List<rstk__wocst__c>();
    public Map<Id, rstk__wocst__c> newMap = new Map<Id, rstk__wocst__c>();
    public Map<Id, rstk__wocst__c> oldMap = new Map<Id, rstk__wocst__c>();

    public List<rstk__wocst__c> refreshedNewList = new List<rstk__wocst__c>();

    public Map<Id, Chassis_Master__c> chassisMasterMap = new Map<Id, Chassis_Master__c>();
    
    // AMILLER8
    public Map<Id, Opportunity__c> customOppMap = new Map<Id, Opportunity__c>();
    // AMILLER8

    public Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
    // AMILLER8
    public Map<Id, rstk__wocst__c> workOrderMap = new Map<Id, rstk__wocst__c>();
    // AMILLER8

    public String statusInProduction = 'In Production';
    public String statusProductionComplete = 'Production Complete';
    // AMILLER2
    public String statusReadyForReview = 'Ready For Review';
    public String statusReadyToShip = 'Ready To Ship';
    public String statusShipped = 'Shipped';
    // AMILLER2
    
    // AMILLER3
    public Id id1;
    Profile tempProfile;
    // AMILLER3

    // Business process dictactes that when the work order is first created, the 
    // due date is set to 12/31/2050. This tells scheduling it needs to be scheduled.
    public Date schedulingDueDate = Date.newInstance(2020, 12, 31);

    public WorkOrderTriggerHandler(){}

    public WorkOrderTriggerHandler(rstk__wocst__c[] newArray, rstk__wocst__c[] oldArray, Map<Id, rstk__wocst__c> newHashMap, Map<Id, rstk__wocst__c> oldHashMap){
        newList = newArray;
        oldList = oldArray;
        newMap = newHashMap;
        oldMap = oldHashMap;
        
        id1 = userinfo.getProfileId();
        tempProfile = [select Name from profile where id = :id1 LIMIT 1];
    }

    /**
    * refreshAllFieldsNeeded
    * 
    * function which queries the system once to grab all of the connected
    * fields to be used in the rest of the entire class to reduce
    * limit usage
    */
    public void refreshAllFieldsNeeded()
    {
        refreshedNewList = ([SELECT Id, 
                                    rstk__wocst_totrunhrs__c,
                                    rstk__wocst_totrunhrstd__c,
                                    rstk__wocst_soline__c,
                                    rstk__wocst_totlabhrs__c,
                                    rstk__wocst_soline__r.rstk__soline_sohdr__c,
                                    rstk__wocst_soline__r.rstk__soline_sohdr__r.Sales_Rep__c,
                                    // AMILLER7
                                    rstk__wocst_soline__r.rstk__soline_sohdr__r.rstk__sohdr_cancelled__c, 
                                    rstk__wocst_soline__r.rstk__soline_sohdr__r.Opportunity__c,
                             		rstk__wocst_soline__r.rstk__soline_sohdr__r.Opportunity__r.RecordType.Name,
                             		// AMILLER7
                                    // AMILLER8
                                    rstk__wocst_ordsts__c,
                                    Opportunity_custom__c,
                                    rstk__wocst_soline__r.rstk__soline_sohdr__r.Opportunity_custom__c,
                                    rstk__wocst_soline__r.rstk__soline_sohdr__r.Opportunity_custom__r.Estimated_GP__c,
                                    rstk__wocst_soline__r.rstk__soline_sohdr__r.Opportunity_custom__r.Landed_GP__c,
                                    rstk__wocst_soline__r.rstk__soline_sohdr__r.Opportunity_custom__r.Status__c,
                                    // AMILLER8
                                    rstk__wocst_soline__r.rstk__soline_sohdr__r.rstk__sohdr_opportunity__c,
                                    rstk__wocst_soline__r.rstk__soline_sohdr__r.rstk__sohdr_opportunity__r.RecordType.Name,
                                    rstk__wocst_soline__r.rstk__soline_sohdr__r.Sales_Rep__r.Email,
                                    Chassis__c,
                                    Chassis__r.Build_Start_Date__c,
                                    Chassis__r.Status__c,
                                    Chassis__r.Work_Order_Chassis__c,
                                    // AMILLER2
                                    Chassis__r.Planned_Build_Date__c,
                                    Chassis__r.Build_Complete_Date__c,
                                    Chassis__r.Planned_Completion_Date__c,
                                    // AMILLER2
                                    // AMM12
                                    Promise_Date__c ,
                                    Hold__c,
                                    Hold_Release_ETA__c,
                                    // AMM12
                                    rstk__wocst_duedte__c,
                                    rstk__wocst_ordsts_pl__c,
                                    rstk__wocst_schedpickdte__c
                             FROM rstk__wocst__c
                             WHERE Id IN :newList]);
    }

    /**
    * updateAllMaps
    *
    * function which is called at the end of each after trigger and 
    * updates all of the maps used in the entire process at once.
    * This is to help prevent multiple DMLs/Triggers on the same 
    * object as much as possible in a manageable way.
    */
    public void updateAllMaps()
    {
        update opportunityMap.values();
        update chassisMasterMap.values();
        // AMILLER8
        update customOppMap.values();
        update workOrderMap.values();
        // AMILLER8
    }

    /**
    * updateWorkOrderDueDateForScheduling
    *
    * Function which sets all new Work Orders
    * to 12/31/2020 automatically so Scheduling
    * can set the due date on their end.
    */
    public void updateWorkOrderDueDateForScheduling()
    {
        // AMM10
        // for(rstk__wocst__c tempWorkOrder : newList)
        // {
        //     System.debug(tempWorkOrder.rstk__wocst_duedte__c);
        //     System.debug(tempWorkOrder.rstk__wocst_schedfirmdte__c);
        //     System.debug(tempWorkOrder.rstk__wocst_schedpickdte__c);
        //     System.debug(tempWorkOrder.rstk__wocst_reldte__c);

        //     // tempWorkOrder.rstk__wocst_duedte__c = schedulingDueDate;
        //     // // AMILLER4
        //     // tempWorkOrder.rstk__wocst_schedfirmdte__c = schedulingDueDate;
        //     // tempWorkOrder.rstk__wocst_schedpickdte__c = schedulingDueDate;
        //     // tempWorkOrder.rstk__wocst_reldte__c = schedulingDueDate;
        //     // AMILLER4
        // }
        // AMM10
    }

    // AMILLER8
    /**
    * updateWorkOrderWithCustomOpp
    *
    * Function which pastes the custom TransitWorks Opportunity to the Work 
    * Order as its being created
    */
    public void updateWorkOrderWithCustomOpp()
    {
        for(rstk__wocst__c tempWorkOrder : refreshedNewList)
        {
            if(tempWorkOrder.Opportunity_custom__c == null && 
                tempWorkOrder.rstk__wocst_soline__r.rstk__soline_sohdr__c != null &&
                tempWorkOrder.rstk__wocst_soline__r.rstk__soline_sohdr__r.Opportunity_custom__c != null)
            {
                if(workOrderMap.get(tempWorkOrder.Id) == null)
                {
                    tempWorkOrder.Opportunity_custom__c = tempWorkOrder.rstk__wocst_soline__r.rstk__soline_sohdr__r.Opportunity_custom__c;
                    workOrderMap.put(tempWorkOrder.Id, tempWorkOrder);
                }
                else 
                {
                    workOrderMap.get(tempWorkOrder.Id).Opportunity_custom__c = tempWorkOrder.rstk__wocst_soline__r.rstk__soline_sohdr__r.Opportunity_custom__c;
                }
            }
        }
    }
    // AMILLER8

    //AMILLER1
    /**
    * updatePromiseDate
    *
    * Function used to update the promise date
    * when scheduling marks the due date from 12/31/2025
    * to the new due date.
    */
    public void updatePromiseDate()
    {
        for(rstk__wocst__c tempWorkOrder : newList)
        {
            if(
                // Due Date changed
                tempWorkOrder.rstk__wocst_duedte__c != oldMap.get(tempWorkOrder.Id).rstk__wocst_duedte__c && 
                // Due Date changed from 12/31/2025
                // AMM10
                // oldMap.get(tempWorkOrder.Id).rstk__wocst_duedte__c == schedulingDueDate &&
                // AMM10
                // The Promise Date is not already filled in, meaning its just been scheduled
                tempWorkOrder.Promise_Date__c == null && 
                // Make sure the current user is the scheduler or system admin
                (tempProfile.Name.containsIgnoreCase('scheduling') || tempProfile.Name.containsIgnoreCase('super') || Test.IsRunningTest()) // AMILLER6
                )
            {
                tempWorkOrder.Promise_Date__c = tempWorkOrder.rstk__wocst_duedte__c;
                tempWorkOrder.Promise_Date_Not_Sent__c = true;
            }
        }
    }
    ///AMILLER1

    /**
    * updateLinkingToChassis
    * 
    * Paste the formula chassis Id into the lookup from the sales order
    * in order to side-step SOQL limits
    *
    * This if a before insert/update operation
    */
    public void updateLinkingToChassis(){

        for(rstk__wocst__c tempWorkOrder : newList)
        {
            if(tempWorkOrder.Chassis_Formula__c != null)
            {
              tempWorkOrder.Chassis__c = tempWorkOrder.Chassis_Formula__c;
            }
        }
    }

    /**
    * updateLinkingToChassis
    * 
    * Paste the formula chassis Id into the lookup from the sales order
    * in order to side-step SOQL limits
    *
    * This if a before insert/update operation
    */
    public void updateSalesRepEmail()
    {
        for(rstk__wocst__c tempWorkOrder : newList)
        {
            if(tempWorkOrder.Sales_Rep_Formula__c != null)
            {
              tempWorkOrder.Sales_Rep_Email__c = tempWorkOrder.Sales_Rep_Formula__c;
            }
        }
    }

    /**
    * updateBuildStartDate
    *
    * fucntion which checks if the Work Order Stauts or Chassis referenced
    * has labor issued. If so, then the Chassis Build Start Date should be updated
    * to Today's date
    */
    public void updateBuildStartDate()
    {
        for(rstk__wocst__c tempWorkOrder : refreshedNewList)
        {
            if(tempWorkOrder.Chassis__c != null &&
                // AMILLER2
                tempWorkOrder.Chassis__r.Build_Start_Date__c == null &&
                // AMILLER2
                // Labor changed and is greater than zero while the old was zero
                (oldMap != null && oldMap.get(tempWorkOrder.Id) != null && oldMap.get(tempWorkOrder.Id).rstk__wocst_totlabhrs__c != tempWorkOrder.rstk__wocst_totlabhrs__c &&
                oldMap.get(tempWorkOrder.Id).rstk__wocst_totlabhrs__c == 0)
                ) 
            {
                if(chassisMasterMap.get(tempWorkOrder.Chassis__c) != null)
                {
                    chassisMasterMap.get(tempWorkOrder.Chassis__c).Build_Start_Date__c = System.Today();
                    chassisMasterMap.get(tempWorkOrder.Chassis__c).Status__c = statusInProduction;
                }
                else 
                {
                    chassisMasterMap.put(tempWorkOrder.Chassis__c, new Chassis_Master__c(Id = tempWorkOrder.Chassis__c, 
                                                                                Build_Start_Date__c = System.Today(),
                                                                                Status__c = statusInProduction));
                }

            } 
        }
    }

    /**
    * updateBuildCompletDate
    *
    * fucntion which checks if the Work Order Stauts or Chassis referenced
    * was changed to 8. If so, then the Chassis Build Start Date should be updated
    * to Today's date
    */
    public void updateBuildCompletDate()
    {
        for(rstk__wocst__c tempWorkOrder : refreshedNewList)
        {

            // AMILLER6
            Decimal totalStandardHours = tempWorkOrder.rstk__wocst_totrunhrstd__c;
            Decimal totalChargedHours = tempWorkOrder.rstk__wocst_totrunhrs__c;

            if(
                // make sure a chassis is available and the new Work Order Status is 5
                //tempWorkOrder.rstk__wocst_ordsts_pl__c == '8-Receipts completed' &&
                
                totalStandardHours == totalChargedHours && 

                oldMap != null && oldMap.get(tempWorkOrder.Id) != null &&

                // make sure the Status was changed in this operation or the Chassis was changed
                (
                    (
                        // AMILLER6
                        //tempWorkOrder.rstk__wocst_ordsts_pl__c != oldMap.get(tempWorkOrder.Id).rstk__wocst_ordsts_pl__c
                        tempWorkOrder.rstk__wocst_totrunhrs__c != oldMap.get(tempWorkOrder.Id).rstk__wocst_totrunhrs__c
                    ) 
                    ||
                    tempWorkOrder.Chassis__c != oldMap.get(tempWorkOrder.Id).Chassis__c
                ) &&
                    tempWorkOrder.Chassis__c != null && 
                    (
                        tempWorkOrder.Chassis__r.Status__c != 'Ready For Review' &&
                        tempWorkOrder.Chassis__r.Status__c != 'Ready To Ship' &&
                        tempWorkOrder.Chassis__r.Status__c != 'Shipped'
                    )
                ) 
            {
                if(chassisMasterMap.get(tempWorkOrder.Chassis__c) != null)
                {
                    if(tempWorkOrder.Chassis__r.Build_Complete_Date__c == null)
                    {
                        chassisMasterMap.get(tempWorkOrder.Chassis__c).Build_Complete_Date__c = System.Today();
                    }

                    if(tempWorkOrder.Chassis__r.Status__c != statusReadyForReview && tempWorkOrder.Chassis__r.Status__c != statusReadyToShip && tempWorkOrder.Chassis__r.Status__c != statusShipped)
                    {
                        chassisMasterMap.get(tempWorkOrder.Chassis__c).Status__c = statusProductionComplete;
                    }
                }
                else
                {
                    Chassis_Master__c tempChassis = null;
                    
                    if(tempWorkOrder.Chassis__r.Status__c != statusReadyForReview && tempWorkOrder.Chassis__r.Status__c != statusReadyToShip && tempWorkOrder.Chassis__r.Status__c != statusShipped)
                    {   
                        if(tempChassis == null)
                        {
                            tempChassis = new Chassis_Master__c();
                            tempChassis.Id = tempWorkOrder.Chassis__c;
                        }

                        tempChassis.Status__c = statusProductionComplete;
                    }
                    
                    if(tempChassis.Build_Complete_Date__c == null)
                    {
                        if(tempChassis == null)
                        {
                            tempChassis = new Chassis_Master__c();
                            tempChassis.Id = tempWorkOrder.Chassis__c;
                        }

                        tempChassis.Build_Complete_Date__c = System.Today();
                    }

                    if(tempChassis != null)
                    {
                        chassisMasterMap.put(tempWorkOrder.Chassis__c, tempChassis);
                    }
                }
            }
        }
    }

    /**
    * updatePlannedBuildCompletDate
    *
    * fucntion which takes the Work Order due date and pastes it 
    * into the Chassis Master's planned build completion date field
    */
    public void updatePlannedBuildDate()
    { 
        for(rstk__wocst__c tempWorkOrder : refreshedNewList)
        {
            if(
                // Make sure due date is filled in
                tempWorkOrder.rstk__wocst_schedpickdte__c != null && 

                // paste if fresh or changed
                ( 
                    (oldMap == null || oldMap.get(tempWorkOrder.Id) == null) ||
                    oldMap.get(tempWorkOrder.Id).rstk__wocst_schedpickdte__c != tempWorkOrder.rstk__wocst_schedpickdte__c
                ) &&
                // make sure chassis exists
                tempWorkOrder.Chassis__c != null && 
                // AMILLER2
                // AMILLER5
                // tempWorkOrder.Chassis__r.Planned_Build_Date__c == null &&
                // / AMILLER5
                // AMILLER3
                (tempProfile.Name.containsIgnoreCase('scheduling') || Test.IsRunningTest())
                ) 
            {
                if(chassisMasterMap.get(tempWorkOrder.Chassis__c) != null)
                {
                    chassisMasterMap.get(tempWorkOrder.Chassis__c).Planned_Build_Date__c = tempWorkOrder.rstk__wocst_schedpickdte__c.addDays(7);
                }
                else 
                {
                    chassisMasterMap.put(tempWorkOrder.Chassis__c, new Chassis_Master__c(Id = tempWorkOrder.Chassis__c, 
                                                                                Planned_Build_Date__c = tempWorkOrder.rstk__wocst_schedpickdte__c.addDays(7)));
                }
            } 
        }
    }

    /**
    * updatePlannedBuildCompleteDate
    *
    * fucntion which takes the Work Order due date and pastes it 
    * into the Chassis Master's planned build completion date field
    */
    public void updatePlannedBuildCompleteDate()
    {
        for(rstk__wocst__c tempWorkOrder : refreshedNewList)
        {
            if(
                // Make sure due date is filled in
                tempWorkOrder.rstk__wocst_duedte__c != null && 
                
                // paste if fresh or changed
                ( 
                    (oldMap == null || oldMap.get(tempWorkOrder.Id) == null)
                    ||
                    (
                        oldMap.get(tempWorkOrder.Id).rstk__wocst_duedte__c != null && 
                        oldMap.get(tempWorkOrder.Id).rstk__wocst_duedte__c != tempWorkOrder.rstk__wocst_duedte__c
                    )
                ) &&

                // make sure chassis exists
                tempWorkOrder.Chassis__c != null &&
                // AMILLER3
                // AMILLER3
                //tempProfile.Name.containsIgnoreCase('scheduling') && 
                // AMILLER5
                // AMM12
                (tempProfile.Name.containsIgnoreCase('scheduling') || Test.IsRunningTest()))
                //tempProfile.Name.containsIgnoreCase('scheduling'))
                // AMM12
                // / AMILLER5
                // AMILLER2
                // tempWorkOrder.Chassis__r.Planned_Completion_Date__c == null) // AMILLER5
                // AMILLER2) 
            {
                System.debug(chassisMasterMap.get(tempWorkOrder.Chassis__c) != null);

                if(chassisMasterMap.get(tempWorkOrder.Chassis__c) != null)
                {
                    // AMM12
                    // Due < Promise ; Plan Comp = Promise
                    if(tempWorkOrder.rstk__wocst_duedte__c < tempWorkOrder.Promise_Date__c && tempWorkOrder.Hold__c == false)
                    {
                        chassisMasterMap.get(tempWorkOrder.Chassis__c).Planned_Completion_Date__c = tempWorkOrder.Promise_Date__c.addDays(7);
                    }
                    // Due = Promise ; Plan Comp = Promise
                    else if(tempWorkOrder.rstk__wocst_duedte__c == tempWorkOrder.Promise_Date__c && tempWorkOrder.Hold__c == false)
                    {
                        chassisMasterMap.get(tempWorkOrder.Chassis__c).Planned_Completion_Date__c = tempWorkOrder.rstk__wocst_duedte__c;
                    }
                    // Due  > Promise ; Plan Comp = Due
                    else if(tempWorkOrder.rstk__wocst_duedte__c > tempWorkOrder.Promise_Date__c && tempWorkOrder.Hold__c == false)
                    {
                        chassisMasterMap.get(tempWorkOrder.Chassis__c).Planned_Completion_Date__c = tempWorkOrder.rstk__wocst_duedte__c;
                    }
                    // Hold ; Plan Comp = Hold Release
                    else if(tempWorkOrder.Hold__c && tempWorkOrder.Hold_Release_ETA__c != null)
                    {
                        chassisMasterMap.get(tempWorkOrder.Chassis__c).Planned_Completion_Date__c = tempWorkOrder.Hold_Release_ETA__c;
                    }
                    // AMM12

                    System.debug(chassisMasterMap.get(tempWorkOrder.Chassis__c).Planned_Completion_Date__c);
                }
                else 
                {
                    chassisMasterMap.put(tempWorkOrder.Chassis__c, new Chassis_Master__c(Id = tempWorkOrder.Chassis__c, 
                                                                                Planned_Completion_Date__c = tempWorkOrder.rstk__wocst_duedte__c.addDays(7)));
                }
            } 
            else if(tempWorkOrder.rstk__wocst_duedte__c != null && 
                    tempWorkOrder.Chassis__c != null)
            {
                if(tempWorkOrder.Hold__c && tempWorkOrder.Hold_Release_ETA__c != null)
                {
                    chassisMasterMap.get(tempWorkOrder.Chassis__c).Planned_Completion_Date__c = tempWorkOrder.Hold_Release_ETA__c;
                }
            }
        }
    }

    /**
    * updateLinkingToChassisWithWorkOrders
    *
    * fucntion which pastes the Work Order Id onto the Chassis's
    * Work Order field for linking purposes
    */
    public void updateLinkingToChassisWithWorkOrders(){

        for(rstk__wocst__c tempWorkOrder : refreshedNewList)
        {            
            if(tempWorkOrder.Chassis__c != null && chassisMasterMap.get(tempWorkOrder.Chassis__c) != null) 
            {
                chassisMasterMap.get(tempWorkOrder.Chassis__c).Work_Order_Chassis__c = tempWorkOrder.Id;
            } 
            else if(tempWorkOrder.Chassis__c != null && chassisMasterMap.get(tempWorkOrder.Chassis__c) == null)
            {
                chassisMasterMap.put(tempWorkOrder.Chassis__c, new Chassis_Master__c(Id = tempWorkOrder.Chassis__c, 
                                                                                Work_Order_Chassis__c = tempWorkOrder.Id));
            }
        }
    }
    
    /**
    * updateRelatedOpportunityTotalEstimatedGP
    *
    * function which takes all of the Work Orders related to the parent 
    * Opportunity and generates the total Work Order Price
    */
    //public void updateRelatedOpportunityTotalEstimatedGP()
    //{
    //    List<rstk__wocst__c> listOfAllRelatedWorkOrdersByOpportunity = new List<rstk__wocst__c>();
    //    List<List<rstk__wocst__c>> twoDimensionalArrayOfWorkOrdersByOpportunity = new List<List<rstk__wocst__c>>();
    //    Map<Id, Opportunity> mapOfOpportunityIds = new Map<Id, Opportunity>();
    //    // AMILLER8
    //    Map<Id, Opportunity__c> mapOfCustomOpportunityIds = new Map<Id, Opportunity__c>();
    //    // AMILLER8
    //
    //    for(rstk__wocst__c tempWorkOrder : refreshedNewList)
    //    {
    //        // AMILLER8
    //        if(tempWorkOrder.Opportunity_custom__c != null && 
    //            tempWorkOrder.rstk__wocst_soline__r.rstk__soline_sohdr__r.rstk__sohdr_cancelled__c == false && 
    //            mapOfCustomOpportunityIds.get(tempWorkOrder.Opportunity_custom__c) == null)
    //        {
    //            mapOfCustomOpportunityIds.put(tempWorkOrder.Opportunity_custom__c , 
    //                                    new Opportunity__c(Id=tempWorkOrder.Opportunity_custom__c ));
    //        }
    //        
    //        // if(tempWorkOrder.rstk__wocst_soline__r.rstk__soline_sohdr__r.rstk__sohdr_opportunity__c != null && 
    //        //     tempWorkOrder.rstk__wocst_soline__r.rstk__soline_sohdr__r.rstk__sohdr_cancelled__c == false)
    //        // {
    //            
    //        //     if(mapOfOpportunityIds.get(tempWorkOrder.rstk__wocst_soline__r.rstk__soline_sohdr__r.rstk__sohdr_opportunity__c) == null) 
    //        //     {
    //        //         mapOfOpportunityIds.put(tempWorkOrder.rstk__wocst_soline__r.rstk__soline_sohdr__r.rstk__sohdr_opportunity__c , 
    //        //                                 new Opportunity(Id=tempWorkOrder.rstk__wocst_soline__r.rstk__soline_sohdr__r.rstk__sohdr_opportunity__c ));
    //        //     } 
    //        // }
    //        // AMILLER8
    //    }
    //
    //    // take all of the Opportunities Ids and then query to find all of the related Sales Orders to update the opp
    //    listOfAllRelatedWorkOrdersByOpportunity = ([SELECT Id, 
    //                                                        Pre_Calculated_Total_Gross_Profit__c,
    //                                                        Pre_Calculated_Total_Fringe_Cost__c,
    //                                                        Pre_Calculated_Total_Labor_Overhead__c,
    //                                                       Pre_Calculated_Total_Labor_Price__c,
    //                                                        Pre_Calculated_Total_Material_Overhead__c,
    //                                                        Pre_Calculated_Total_Material_Price__c,
    //                                                        // AMILLER8
    //                                                        Opportunity_custom__c,
    //                                                        Opportunity_custom__r.Estimated_GP__c,
    //                                                        // AMILLER8
    //                                                        rstk__wocst_soline__r.rstk__soline_sohdr__r.rstk__sohdr_opportunity__r.Estimated_GP__c
    //                                                FROM rstk__wocst__c 
    //                                                WHERE Opportunity_custom__c IN :mapOfCustomOpportunityIds.KeySet() 
    //                                                ]);
	//	
	//	// clear the totals for accurate calculations
    //  for(rstk__wocst__c tempWorkOrder : listOfAllRelatedWorkOrdersByOpportunity)
    //    {
    //        // AMILLER8
    //        if(tempWorkOrder.Opportunity_custom__c != null && customOppMap.get(tempWorkOrder.Opportunity_custom__c) != null) 
    //        {
    //            customOppMap.get(tempWorkOrder.Opportunity_custom__c).Estimated_GP__c = 0;
    //        }
    //        // if(opportunityMap.get(tempWorkOrder.rstk__wocst_soline__r.rstk__soline_sohdr__r.rstk__sohdr_opportunity__c) != null) 
    //        // {
    //        //     opportunityMap.get(tempWorkOrder.rstk__wocst_soline__r.rstk__soline_sohdr__r.rstk__sohdr_opportunity__c).Estimated_GP__c = 0;
    //        // }
    //        // AMILLER8
    //    }
    //
    //      // calculate the totals
    //    for(rstk__wocst__c tempWorkOrder : listOfAllRelatedWorkOrdersByOpportunity)
    //    {
    //        // AMILLER8
    //        if(tempWorkOrder.Opportunity_custom__c != null && customOppMap.get(tempWorkOrder.Opportunity_custom__c) == null && tempWorkOrder.Pre_Calculated_Total_Gross_Profit__c != null) 
    //        {
    //            customOppMap.put(tempWorkOrder.Opportunity_custom__c, new Opportunity__c(Id = tempWorkOrder.Opportunity_custom__c, 
    //                                                                                    Estimated_GP__c = tempWorkOrder.Pre_Calculated_Total_Gross_Profit__c));
    //        } 
    //        else if(tempWorkOrder.Opportunity_custom__c != null && customOppMap.get(tempWorkOrder.Opportunity_custom__c) != null && tempWorkOrder.Pre_Calculated_Total_Gross_Profit__c != null)
    //        {
    //            customOppMap.get(tempWorkOrder.Opportunity_custom__c).Estimated_GP__c = customOppMap.get(tempWorkOrder.Opportunity_custom__c).Estimated_GP__c + tempWorkOrder.Pre_Calculated_Total_Gross_Profit__c;
    //        }
    //
    //        // if(opportunityMap.get(tempWorkOrder.rstk__wocst_soline__r.rstk__soline_sohdr__r.rstk__sohdr_opportunity__c) != null) 
    //        // {
    //        //     opportunityMap.get(tempWorkOrder.rstk__wocst_soline__r.rstk__soline_sohdr__r.rstk__sohdr_opportunity__c).Estimated_GP__c = opportunityMap.get(tempWorkOrder.rstk__wocst_soline__r.rstk__soline_sohdr__r.rstk__sohdr_opportunity__c).Estimated_GP__c + tempWorkOrder.Pre_Calculated_Total_Gross_Profit__c;
    //        // } 
    //        // else
    //        // {
    //        //     opportunityMap.put(tempWorkOrder.rstk__wocst_soline__r.rstk__soline_sohdr__r.rstk__sohdr_opportunity__c, new Opportunity(Id = tempWorkOrder.rstk__wocst_soline__r.rstk__soline_sohdr__r.rstk__sohdr_opportunity__c, 
    //        //                                                                             Estimated_GP__c = tempWorkOrder.Pre_Calculated_Total_Gross_Profit__c));
    //        // }
    //        // AMILLER8
    //    }
    //}

    // AMM11
    /*
    * recordOriginalLaborHoursOnCreate
    *
    * Function which looks at the newly inserted Work Order
    * and sees how much labor is associated with it.
    */
    public void recordOriginalLaborHoursOnCreate()
    {
        for(rstk__wocst__c tempWorkOrder : newList)
        {
            if(workOrderMap.get(tempWorkOrder.Id) == null && (tempWorkOrder.Total_Labor_Hours_Oncreate__c == null || tempWorkOrder.Total_Labor_Hours_Oncreate__c == 0)) 
            {
                workOrderMap.put(tempWorkOrder.Id, tempWorkOrder);
            }             
        }

        List<rstk__wopsch__c> listOfOperations = ([SELECT Id, 
                                                    rstk__wopsch_ordno__c, 
                                                    rstk__wopsch_schrunhrs__c
                                                FROM rstk__wopsch__c 
                                                WHERE rstk__wopsch_ordno__c	 IN :workOrderMap.keySet() AND
                                                    Created_After_Work_Order__c = false]);

        for(rstk__wopsch__c tempOperation : listOfOperations)
        {
            if(workOrderMap.get(tempOperation.rstk__wopsch_ordno__c) != null)
            {
                rstk__wocst__c tempWorkOrder = workOrderMap.get(tempOperation.rstk__wopsch_ordno__c);

                tempWorkOrder.Total_Labor_Hours_Oncreate__c = tempWorkOrder.Total_Labor_Hours_Oncreate__c != null ? tempWorkOrder.Total_Labor_Hours_Oncreate__c : 0;

                tempWorkOrder.Total_Labor_Hours_Oncreate__c = tempWorkOrder.Total_Labor_Hours_Oncreate__c + tempOperation.rstk__wopsch_schrunhrs__c;

                workOrderMap.put(tempOperation.rstk__wopsch_ordno__c, tempWorkOrder); 
            }
        }
    }
    // AMM11
}