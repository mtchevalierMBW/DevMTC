/**
* WorkOrderTriggerHandlerTest 
* 
* Programmer: Alexander Miller
* Date: 2017-09-14
*
* Alexander Miller - AMiLLER8 - 7/6/2018 - Update to make the trigger handler modular to increase code coverage
* Alexander Miller - AMM9     - 11/07/2019 - IN - Update to record the original labor of the Work Order on creation
* Alexander MIller - AMM12    - 12/10/2019 - Update requested for Communities to handle Promise and Planned Completion Dates
*/
@isTest(SeeAllData = true)
public class WorkOrderTriggerHandlerTest {

    public static testMethod void testConstructor(){
        
        Test.startTest();

        WorkOrderTriggerHandler tempHandler = new WorkOrderTriggerHandler();

        Test.stopTest();
    }

    public static testMethod void testChassisAssignment(){
        
        Test.startTest();

        rstk__wocst__c tempWorkOrder = ([SELECT Id FROM rstk__wocst__c WHERE Chassis_Formula__c != null LIMIT 1]);

        update tempWorkOrder;

        Test.stopTest();
    }
    
    public static testMethod void testUpdatePromiseDate(){
        
        Test.startTest();
        
        WorkOrderTriggerHandler tempHandler = new WorkOrderTriggerHandler();
        
        rstk__wocst__c tempWorkOrder = ([SELECT Id, 
                                         rstk__wocst_duedte__c,
                                         rstk__wocst_schedpickdte__c,
                                         rstk__wocst_schdcompdate__c,
                                         rstk__wocst_schedfirmdte__c
                                        FROM rstk__wocst__c 
                                        WHERE rstk__wocst_ordsts__c = '5' LIMIT 1]);
        
        Date tempWorkOrderDate = tempWorkOrder.rstk__wocst_duedte__c.addDays(-1);
        tempWorkOrder.rstk__wocst_schedpickdte__c = tempWorkOrderDate.addDays(-3);
        tempWorkOrder.rstk__wocst_reldte__c = tempWorkOrderDate.addDays(-4);
        tempWorkOrder.rstk__wocst_schedfirmdte__c = tempWorkOrderDate.addDays(-5);
        tempWorkOrder.rstk__wocst_duedte__c = tempWorkOrderDate;
        tempWorkOrder.Promise_Date__c = null;
        
        update tempWorkOrder;
        
        Test.stopTest();
    }

    /*
    public static testMethod void testWorkOrder8(){
        
        Test.startTest();

        List<rstk__wocst__c> tempWorkOrder = ([SELECT Id, Chassis__c FROM rstk__wocst__c WHERE rstk__wocst_ordsts_pl__c = '8-Receipts completed' LIMIT 1]);
        
        List<Id> chassisIds = new List<Id>();

        Chassis_Master__c temp = new Chassis_Master__c();
        temp.Name = 'Test';
        temp.Year__c = '2017';
        temp.Make__c = 'Toyota';
        temp.Division__c = ([SELECT Id FROM rstk__sydiv__c WHERE Name = 'Akron (AK)' LIMIT 1]).Id;
        temp.VIN__c = '123456789';
        temp.Key_Tag__c = '23456';
        insert temp;

        tempWorkOrder.get(0).Chassis__c = temp.Id;

        update tempWorkOrder;

        Test.stopTest();
    } 
	*/

    public static testMethod void testRefreshAllFieldsNeeded()
    {
        Test.StartTest();

        rstk__wocst__c tempOrder = [SELECT Id FROM rstk__wocst__c LIMIT 1];

        WorkOrderTriggerHandler tempHandler = new WorkOrderTriggerHandler();
        tempHandler.newList.add(tempOrder);

        tempHandler.refreshAllFieldsNeeded();

        Test.StopTest();
    }

    public static testMethod void testUpdateWorkOrderDueDateForScheduling()
    {
        rstk__wocst__c tempOrder = [SELECT Id, 
                                        rstk__wocst_duedte__c,
                                        rstk__wocst_schedfirmdte__c,
                                        rstk__wocst_schedpickdte__c,
                                        rstk__wocst_reldte__c
                                    FROM rstk__wocst__c LIMIT 1];

        WorkOrderTriggerHandler tempHandler = new WorkOrderTriggerHandler();
        tempHandler.newList.add(tempOrder);

        tempHandler.updateWorkOrderDueDateForScheduling();

        // System.assertEquals(tempHandler.schedulingDueDate, tempHandler.newList.get(0).rstk__wocst_duedte__c);
        // System.assertEquals(tempHandler.schedulingDueDate, tempHandler.newList.get(0).rstk__wocst_schedfirmdte__c);
        // System.assertEquals(tempHandler.schedulingDueDate, tempHandler.newList.get(0).rstk__wocst_schedpickdte__c);
        // System.assertEquals(tempHandler.schedulingDueDate, tempHandler.newList.get(0).rstk__wocst_reldte__c);
    }

    // AMM9
    public static testMethod void testRecordOriginalLaborHoursOnCreate()
    {
        Test.StartTest();

        rstk__wocst__c tempOrder = [SELECT Id, Total_Labor_Hours_Oncreate__c FROM rstk__wocst__c WHERE ID IN (SELECT rstk__wopsch_ordno__c FROM rstk__wopsch__c WHERE rstk__wopsch_schrunhrs__c > 0)LIMIT 1];

        WorkOrderTriggerHandler tempHandler = new WorkOrderTriggerHandler();
        tempHandler.newList.add(tempOrder);

        tempHandler.recordOriginalLaborHoursOnCreate();

        tempOrder = [SELECT Id, Total_Labor_Hours_Oncreate__c FROM rstk__wocst__c WHERE Id = :tempOrder.Id LIMIT 1];

        Test.StopTest();
    }
    // AMM9

    // AMM12
    public static testMethod void testUpdatePlannedBuildCompleteDateDueBelowPromise()
    {
        Test.StartTest();

        rstk__wocst__c tempOrder = [SELECT Id, 
                                        rstk__wocst_duedte__c,
                                        Chassis__c,
                                        Promise_Date__c,
                                        Hold_Release_ETA__c,
                                        rstk__wocst_schedpickdte__c,
                                        rstk__wocst_schdcompdate__c
                                    FROM rstk__wocst__c 
                                    WHERE Chassis__r.Status__c = 'In Production'
                                    LIMIT 1];
		
        Date tempWorkOrderDate = tempOrder.rstk__wocst_duedte__c.addDays(-1); 
        tempOrder.rstk__wocst_schdcompdate__c = tempWorkOrderDate.addDays(-2);
        tempOrder.rstk__wocst_schedpickdte__c = tempWorkOrderDate.addDays(-3);
        tempOrder.rstk__wocst_reldte__c = tempWorkOrderDate.addDays(-4);
        tempOrder.rstk__wocst_schedfirmdte__c = tempWorkOrderDate.addDays(-5);
        tempOrder.rstk__wocst_duedte__c = tempWorkOrderDate;
        tempOrder.Promise_Date__c = tempOrder.rstk__wocst_duedte__c.addDays(-10);
        tempOrder.Hold__c = false;

        update tempOrder;

        Test.StopTest();

        Chassis_Master__c tempChassis = [SELECT Id,
                        Planned_Completion_Date__c 
                    FROM Chassis_Master__c 
                    WHERE Id = :tempOrder.Chassis__c 
                    LIMIT 1];
        
        System.assertEquals(tempWorkOrderDate, tempChassis.Planned_Completion_Date__c);
    }

    public static testMethod void testUpdatePlannedBuildCompleteDateDueEqualPromise()
    {
        Test.StartTest();

        rstk__wocst__c tempOrder = [SELECT Id, 
                                        rstk__wocst_duedte__c,
                                        Chassis__c,
                                        Promise_Date__c,
                                        Hold_Release_ETA__c,
                                        rstk__wocst_schedpickdte__c,
                                        rstk__wocst_schdcompdate__c
                                    FROM rstk__wocst__c 
                                    WHERE Chassis__r.Status__c = 'In Production'
                                    LIMIT 1];
	
        Date tempWorkOrderDate = tempOrder.rstk__wocst_duedte__c.addDays(-1); 
        tempOrder.rstk__wocst_schdcompdate__c = tempWorkOrderDate.addDays(-2);
        tempOrder.rstk__wocst_schedpickdte__c = tempWorkOrderDate.addDays(-3);
        tempOrder.rstk__wocst_reldte__c = tempWorkOrderDate.addDays(-4);
        tempOrder.rstk__wocst_schedfirmdte__c = tempWorkOrderDate.addDays(-5);
        tempOrder.rstk__wocst_duedte__c = tempWorkOrderDate;
        tempOrder.Promise_Date__c = tempWorkOrderDate;
        tempOrder.Hold__c = false;

        update tempOrder;

        Test.StopTest();

        Chassis_Master__c tempChassis = [SELECT Id,
                        Planned_Completion_Date__c 
                    FROM Chassis_Master__c 
                    WHERE Id = :tempOrder.Chassis__c 
                    LIMIT 1];
        
        System.assertEquals(tempWorkOrderDate, tempChassis.Planned_Completion_Date__c);

    }

    public static testMethod void testUpdatePlannedBuildCompleteDateDueAbovePromise()
    {
        Test.StartTest();

        rstk__wocst__c tempOrder = [SELECT Id, 
                                        rstk__wocst_duedte__c,
                                        Chassis__c,
                                        Promise_Date__c,
                                        Hold_Release_ETA__c,
                                        rstk__wocst_schdcompdate__c,
                                        rstk__wocst_schedpickdte__c
                                    FROM rstk__wocst__c 
                                    WHERE Chassis__r.Status__c = 'In Production'
                                    LIMIT 1];

        Date tempWorkOrderDate = tempOrder.rstk__wocst_duedte__c.addDays(-1);   
        tempOrder.rstk__wocst_schdcompdate__c = tempWorkOrderDate.addDays(-2);
        tempOrder.rstk__wocst_schedpickdte__c = tempWorkOrderDate.addDays(-3);
        tempOrder.rstk__wocst_reldte__c = tempWorkOrderDate.addDays(-4);
        tempOrder.rstk__wocst_schedfirmdte__c = tempWorkOrderDate.addDays(-5);
        tempOrder.rstk__wocst_duedte__c = tempWorkOrderDate;
        tempOrder.Promise_Date__c = tempWorkOrderDate.addDays(-1);
        tempOrder.Hold__c = false;

        update tempOrder;

        Test.StopTest();

        Chassis_Master__c tempChassis = [SELECT Id,
                        Planned_Completion_Date__c 
                    FROM Chassis_Master__c 
                    WHERE Id = :tempOrder.Chassis__c 
                    LIMIT 1];
        
        System.assertEquals(tempWorkOrderDate, tempChassis.Planned_Completion_Date__c);

    }

    public static testMethod void testUpdatePlannedBuildCompleteDateDueHoldPromise()
    {
        Test.StartTest();

        rstk__wocst__c tempOrder = [SELECT Id, 
                                        rstk__wocst_duedte__c,
                                        Chassis__c,
                                        Promise_Date__c,
                                        Hold_Release_ETA__c,
                                        rstk__wocst_schedpickdte__c,
                                        rstk__wocst_schdcompdate__c
                                    FROM rstk__wocst__c 
                                    WHERE Chassis__r.Status__c = 'In Production'
                                    LIMIT 1];
		
        Date tempWorkOrderDate = tempOrder.rstk__wocst_duedte__c.addDays(-1);
        tempOrder.rstk__wocst_schdcompdate__c = tempWorkOrderDate.addDays(-2);
        tempOrder.rstk__wocst_schedpickdte__c = tempWorkOrderDate.addDays(-3);
        tempOrder.rstk__wocst_reldte__c = tempWorkOrderDate.addDays(-4);
        tempOrder.rstk__wocst_schedfirmdte__c = tempWorkOrderDate.addDays(-5);
        tempOrder.rstk__wocst_duedte__c = tempWorkOrderDate;
        tempOrder.Promise_Date__c = tempWorkOrderDate;
        tempOrder.Hold__c = true;
        tempOrder.Hold_Description__c = 'Test';
        tempOrder.Hold_Reason__c = 'Material';
        tempOrder.Hold_Release_ETA__c = Date.newinstance(2019, 12, 13);

        update tempOrder;

        Test.StopTest();

        Chassis_Master__c tempChassis = [SELECT Id,
                        Planned_Completion_Date__c 
                    FROM Chassis_Master__c 
                    WHERE Id = :tempOrder.Chassis__c 
                    LIMIT 1];
        
        System.assertEquals(Date.newinstance(2019, 12, 13), tempChassis.Planned_Completion_Date__c);
    }
    
    public static testMethod void testUpdateWorkOrderWithCustomOpp()
    {
        Test.StartTest();
        
        rstk__wocst__c tempOrder = [SELECT Id
                                    FROM rstk__wocst__c 
                                    WHERE Chassis__r.Status__c = 'In Production' AND
                                    	rstk__wocst_soline__r.rstk__soline_sohdr__r.Opportunity_custom__c != null 
                                    LIMIT 1];
       
        tempOrder.Opportunity_custom__c = null;
        
        update tempOrder;
        
        Test.StopTest();
        
        tempOrder = [SELECT Id,
                      Opportunity_custom__c
                     FROM rstk__wocst__c 
                     WHERE Id = :tempOrder.Id
                     LIMIT 1];
        
       	System.assertNotEquals(null, tempOrder.Opportunity_custom__c);
	}
    // AMM12
}