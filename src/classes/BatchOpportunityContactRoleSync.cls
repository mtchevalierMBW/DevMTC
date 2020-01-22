/**
 * BatchOpportunityContactRoleSync
 * 
 * Created By: Alexander Miller
 * Created Date: 10/15/2018 
 * Tested By: 
 * Work Item: 
 * 
 * Description: 
 * 
 * Batch class which creates the Opportunity Contact Role 
 * records so Pardot syncs correctly
 *
 * It searches for all MBW Opportunities and finds ones not already listed in a Opportunity Contact Role
 * reocrd.
 */
global without sharing class BatchOpportunityContactRoleSync implements Database.Batchable<sObject>, Schedulable, Database.Stateful {

    global void execute(SchedulableContext SC) 
    {        
        BatchOpportunityContactRoleSync thisBatch = new BatchOpportunityContactRoleSync();
        database.executeBatch(thisBatch, 1); 
    }

 	global Database.QueryLocator start(Database.BatchableContext BC) 
    {
        String mobilityWorksOppRecordType = 'MBWC_OppRecordType';
        Id mbwOppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(mobilityWorksOppRecordType).getRecordTypeId();

        // Go-Live Query
        String query = 'SELECT Id, RecordTypeId, AccountId FROM Opportunity WHERE Id NOT IN (SELECT OpportunityId FROM OpportunityContactRole) AND RecordTypeId = \'' + mbwOppRecordTypeId + '\' AND AccountId != null';
        
        if(Test.IsRunningTest())
        {
            query = 'SELECT Id, RecordTypeId, AccountId FROM Opportunity WHERE Id NOT IN (SELECT OpportunityId FROM OpportunityContactRole) AND RecordTypeId = \'' + mbwOppRecordTypeId + '\' AND AccountId != null LIMIT 1';
        }
        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Opportunity> opportunityList) 
    {
        List<OpportunityContactRole> listOfOppContactRoles = new List<OpportunityContactRole>();

        List<Id> listOfAccountIds = new List<Id>();

        for(Opportunity tempOpp : opportunityList)
        {
            listOfAccountIds.add(tempOpp.AccountId);
        }

        List<Contact> listOfContacts = ([SELECT Id, 
                                            AccountId FROM 
                                            Contact 
                                        WHERE AccountId IN :listOfAccountIds AND 
                                              Contact_Status__c = 'Active']);

        for(Opportunity tempOpp : opportunityList)
        {
            if(tempOpp.AccountId != null)
            {
                for(Contact tempCon : listOfContacts)
                {
                    if(tempCon.AccountId == tempOpp.AccountId)
                    {
                        OpportunityContactRole tempRole = new OpportunityContactRole();

                        tempRole.ContactId = tempCon.Id;
                        tempRole.OpportunityId = tempOpp.Id;
                        tempRole.Role = 'Decision Maker';

                        listOfOppContactRoles.add(tempRole);
                    }
                }   
            }
        }

        insert listOfOppContactRoles;
    }
    
    global void finish(Database.BatchableContext BC) {}
}