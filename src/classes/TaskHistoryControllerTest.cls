/**
 * WMK, LLC (c) - 2018 
 *
 * TaskHistoryControllerTest
 * 
 * Created By:   Alexander Miller
 * Created Date: 12/12/2018 
 * Work Item:    W-000516
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */
 @isTest
public class TaskHistoryControllerTest {

    @TestSetup
    static void makeData()
    {
        Account tempAccount = new Account();
        tempAccount.Name = 'TaskHistoryControllerTest';

        insert tempAccount;

        Task tempTask = new Task();
        tempTask.Subject = 'Testing function';
        tempTask.WhatId = tempAccount.Id;

        insert tempTask;
    }

    public static testMethod void testInitialize(){
      
        test.startTest();
        
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;

        System.assertNotEquals(0, TaskHistoryController.getTasksByParentId(accountId).size());

        test.stopTest();
      
    }
}