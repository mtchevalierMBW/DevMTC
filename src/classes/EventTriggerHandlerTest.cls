/**
 * WMK, LLC (c) - 2019 
 *
 * EventTriggerHandlerTest
 * 
 * Created By:   Alexander Miller
 * Created Date: 1/31/2019 
 * Work Item:    W-000571
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 * 2019-03-27   A. Miller   W-000631 AMM1 - Update to handle edge case with Person Accounts
 */
@isTest(SeeAllData=true)
public class EventTriggerHandlerTest {

    static testmethod void testEventSetAccountField() {

        // 1. Set up Person Account, Business Account, TransitWorks Account, Opportunity, Opportunity__c, and Solution Opportunity
        TestHelper_MW th = new TestHelper_MW();

        Account personAccount = th.getPersonAccount('1');

        // AMM1
        Account personAccount2 = th.getPersonAccount('3');
        Contact tempContact = [SELECT Id FROM Contact WHERE AccountId = :personAccount2.Id LIMIT 1];
        // AMM1

        Account businessAccount = th.getBusinessAccount('2');

        User salesUser = RootStockDataFactory.createSalesUser();
        //insert salesUser;   

        Opportunity tempOpportunity = RootStockDataFactory.createOpportunity('testCustomOpp', 'Pending', 'MBW', System.Today(), salesUser.Id);
        tempOpportunity.AccountId = personAccount.Id;
        insert tempOpportunity;

        Opportunity__c customOpp = RootStockDataFactory.createGenericCustomOpportunity('testCustomOpp', 'MBW', System.Today(), salesUser.Id);
        customOpp.Account__c = personAccount.Id;
        insert customOpp;

        dealer__Sales_Up__c solutionOpportunity = new dealer__Sales_Up__c();
        solutionOpportunity.dealer__Customer_Account__c = businessAccount.Id;
        insert solutionOpportunity;

        // 2. Create 40 tasks for each object to be inserted at once (minus TW Account)
        
        List<Event> insertionEventList = new List<Event>();

        for(Integer i = 0; i < 6; i++)
        {
            for(Integer k = 0; k < 20; k++)
            {
                if(i == 0)
                {
                    insertionEventList.add(new Event(Subject = 'Test person : ' + k, WhatId = personAccount.Id, DurationInMinutes=10, ActivityDateTime=System.Now())); 
                }
                else if(i == 1)
                {
                    insertionEventList.add(new Event(Subject = 'Test business : ' + k, WhatId = businessAccount.Id, DurationInMinutes=10, ActivityDateTime=System.Now()));
                }
                else if(i == 2)
                {   
                    insertionEventList.add(new Event(Subject = 'Test Opp : ' + k, WhatId = tempOpportunity.Id, DurationInMinutes=10, ActivityDateTime=System.Now()));
                }
                else if(i == 3)
                {
                    insertionEventList.add(new Event(Subject = 'Test Custom Opp : ' + k, WhatId = customOpp.Id, DurationInMinutes=10, ActivityDateTime=System.Now()));
                }
                else if(i == 4)
                {
                    insertionEventList.add(new Event(Subject = 'Test SLOP : ' + k, WhatId = solutionOpportunity.Id, DurationInMinutes=10, ActivityDateTime=System.Now()));
                }
                // AMM1
                else if(i == 5)
                {
                    insertionEventList.add(new Event(Subject = 'Test Contact : ' + k, WhoId = tempContact.Id, DurationInMinutes=10, ActivityDateTime=System.Now()));
                }
                // AMM1
            }
        }

        Test.startTest();

        // 3. Insert all tasks at once

        insert insertionEventList;

        // 4. Verify all tasks were created

        Test.stopTest();

        List<Event> listOfEvents = ([SELECT Id, 
                                    WhatId, 
                                    WhoId, 
                                    Account__c 
                                FROM Event
                                WHERE Id IN :insertionEventList]);

        for(Event tempEvent : listOfEvents)
        {
            System.assertNotEquals(null, tempEvent.Account__c);
        }
    }
}