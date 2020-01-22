/**
 * TaskProcessTest
 * Date: 2019-01-30
 * Work Item: W-000571
 * Programmer: Alex Miller
 *
 * Modifications 
 * 2019-03-27   A. Miller   W-000631 AMM1 - Update to handle edge case with Person Accounts
**/
@isTest(SeeAllDAta=true)
public class TaskProcessTest {

    // AMM1
    static testmethod void testTaskSetAccountField() {

        // 1. Set up Person Account, Business Account, TransitWorks Account, Opportunity, Opportunity__c, and Solution Opportunity
        TestHelper_MW th = new TestHelper_MW();

        Account personAccount = th.getPersonAccount('1');

        // AMM1
        Account personAccount2 = th.getPersonAccount('3');
        Contact tempContact = [SELECT Id FROM Contact WHERE AccountId = :personAccount2.Id LIMIT 1];
        // AMM1

        Account businessAccount = th.getBusinessAccount('2');

        User salesUser = RootStockDataFactory.createSalesUser();
        
        Opportunity tempOpportunity = RootStockDataFactory.createOpportunity('testCustomOpp', 'Pending', 'MBW', System.Today(), salesUser.Id);
        tempOpportunity.AccountId = personAccount.Id;
        insert tempOpportunity;

        Opportunity__c customOpp = RootStockDataFactory.createGenericCustomOpportunity('testCustomOpp', 'MBW', System.Today(), salesUser.Id);
        customOpp.Account__c = personAccount.Id;
        insert customOpp;

        dealer__Sales_Up__c solutionOpportunity = new dealer__Sales_Up__c();
        solutionOpportunity.dealer__Customer_Account__c = businessAccount.Id;
        insert solutionOpportunity;

        // 2. Create 20 tasks for each object to be inserted at once (minus TW Account)
        
        List<Task> insertionTaskList = new List<Task>();

        for(Integer i = 0; i < 6; i++)
        {
            for(Integer k = 0; k < 20; k++)
            {
                if(i == 0)
                {
                    insertionTaskList.add(new Task(Subject = 'Test person : ' + k, WhatId = personAccount.Id));
                }
                else if(i == 1)
                {
                    insertionTaskList.add(new Task(Subject = 'Test business : ' + k, WhatId = businessAccount.Id));
                }
                else if(i == 2)
                {   
                    insertionTaskList.add(new Task(Subject = 'Test Opp : ' + k, WhatId = tempOpportunity.Id));
                }
                else if(i == 3)
                {
                    insertionTaskList.add(new Task(Subject = 'Test Custom Opp : ' + k, WhatId = customOpp.Id));
                }
                else if(i == 4)
                {
                    insertionTaskList.add(new Task(Subject = 'Test SLOP : ' + k, WhatId = solutionOpportunity.Id));
                }
                // AMM1
                else if(i == 5)
                {
                    insertionTaskList.add(new Task(Subject = 'Test Contact : ' + k, WhoId = tempContact.Id));
                }
                // AMM1
            }
        }

        Test.startTest();

        // 3. Insert all tasks at once

        insert insertionTaskList;

        // 4. Verify all tasks were created

        Test.stopTest();

        List<Task> listOfTasks = ([SELECT Id, 
                                    WhatId, 
                                    WhoId, 
                                    Account__c 
                                FROM Task
                                WHERE Id IN :insertionTaskList]);

        for(Task tempTask : listOfTasks)
        {
            System.assertNotEquals(null, tempTask.Account__c);
        }
    }
    // AMM1

}