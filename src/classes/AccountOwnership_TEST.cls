/**
 * AccountOwnershiP_TEST
 * Tests: AccountOwnership trigger
 * 
 * Create an account, solution opportunity, task & opportunity
 * Change ownership of the account
 * Verify ownership of the other 3 related items has changed
 *
 * Modifications:
 * 	2018-10-16	BLL1 - Opportunities are no longer owned by individuals (switching to platform licensing).
 *
 */
@isTest
private class AccountOwnership_TEST {

    static testMethod void changeAccountOwner() {
        TestHelper_MW th = new TestHelper_MW();
        Account p = th.getBusinessAccount('1');
        Task t = new Task(
            Subject='Test task',
            Status='Not started',
            WhatId=p.Id
        );
        insert(t);

		Map<String, Schema.RecordTypeInfo> OppRcdTypes = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
		Schema.RecordTypeInfo OppRtInfo = OppRcdTypes.get('MBWC_OppRecordType');
        Opportunity o = new Opportunity(
            Name='Test opportunity',
            StageName='Pending',
            CloseDate=Date.today(),
            AccountId=p.Id,
            Sales_Channel__c='MBW N/A',
            RecordTypeId=OppRtInfo.getRecordTypeId()
        );
        insert(o);
        Contact c = new Contact(AccountId=p.Id, FirstName='Test', LastName='TestContact');
        insert(c);
        dealer__Sales_Up__c s = new dealer__Sales_Up__c(
            Name='Test sales up',
            dealer__Lead_Status__c='Pending',
            dealer__Customer_Account__c=p.Id,
            dealer__Buyer_Contact__c = c.Id
        );
        insert(s);
        User u = th.getTestUser('1');
        
        Test.startTest();
        p.OwnerId = u.Id;
        update(p);
        Test.stopTest();
        
        Task newt = [select Id, Subject, OwnerId from Task where Id=:t.Id limit 1]; 
        Opportunity newo = [select Id, Name, OwnerId from Opportunity where Id=:o.Id limit 1]; 
        dealer__Sales_Up__c news = [select Id, Name, OwnerId from dealer__Sales_Up__c where Id=:s.Id limit 1]; 

        System.assertEquals(u.Id, newt.OwnerId, 'Task owner did not get changed');
        //BLL1 Opportunities are going to be owned by a generic user now
        //BLL1d System.assertEquals(u.Id, newo.OwnerId, 'Opportunity owner did not get changed');
        System.assertEquals(u.Id, news.OwnerId, 'Solution Opportunity owner did not get changed');

    }
}