/**
 * WMK, LLC (c) - 2019 
 *
 * InMotionCampaignQuestionnaireController
 * 
 * Created By:   Alexander Miller
 * Created Date: 2/28/2019 
 * Work Item:    W-000603
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 * Alexander Miller    AMM1        IN00064455     6/7/2019  Change Ron collins to Tasha Terry
 */
public class inMotionResponseTriggerHandler {

    public static void createCampaignMembers(List<In_Motion_Response__c> newList)
    {
        List<CampaignMember> listOfCampaignMembers = new List<CampaignMember>();

        List<Id> listOfAccountIds = new List<Id>();

        for(In_Motion_Response__c tempResponse : newList)
        {
            listOfAccountIds.add(tempResponse.Account__c);
        }

        List<Contact> listOfContacts = ([SELECT Id, 
                                            AccountId
                                        FROM Contact 
                                        WHERE AccountId IN :listOfAccountIds]);

        Map<Id, Contact> mapofContactByAccount = new Map<Id, Contact>();

        for(Contact tempContact : listOfContacts)
        {
            mapofContactByAccount.put(tempContact.AccountId, tempContact);
        }

        System.debug(listOfAccountIds);
        System.debug(listOfContacts);

        List<CampaignMember> listOfExistingCampaignMembers = ([SELECT Id,
                                                                ContactId, 
                                                                CampaignId
                                                            FROM CampaignMember
                                                            WHERE ContactId IN :listOfContacts AND
                                                                Campaign.Name IN ('2019 InMotion Phone Call', '2019 InMotion Email / Web', '2019 InMotion', '2019 InMotion Direct Mail')]);

        System.debug(listOfExistingCampaignMembers);

        Map<Id, CampaignMember> mapOfCampaignByAccount = new Map<Id, CampaignMember>();

        for(CampaignMember tempMember : listOfExistingCampaignMembers)
        {
            mapOfCampaignByAccount.put(tempMember.ContactId, tempMember);
        }

        System.debug(mapOfCampaignByAccount);
        
        for(In_Motion_Response__c tempResponse : newList)
        {
            if(mapOfCampaignByAccount.get(mapofContactByAccount.get(tempResponse.Account__c).Id) == null)
            {
                String tempStatus = '';

                if(tempResponse.Answer__c == '0 - 6 Months')
                {
                    tempStatus = 'P1';
                }
                else if(tempResponse.Answer__c == '7 - 12 Months')
                {
                    tempStatus = 'P2';
                }
                else if(tempResponse.Answer__c == 'A Year From Now' || tempResponse.Answer__c == '2 Years From Now')
                {
                    tempStatus = 'P3';
                }

                if(tempStatus != '')
                {
                    listOfCampaignMembers.add(new CampaignMember(
                        CampaignId = tempResponse.Campaign_Id__c,
                        ContactId = mapofContactByAccount.get(tempResponse.Account__c).Id,
                        Status = tempStatus
                    ));
                }                
            }
        }   

        System.debug(listOfCampaignMembers); 

        insert listOfCampaignMembers;
    }

    public static void setAccountNextPurchaseTimeframe(List<In_Motion_Response__c> newList)
    {
        List<Account> listOfAccounts = new List<Account>();

        for(In_Motion_Response__c tempResponse : newList)
        {
            if(tempResponse.Answer__c == '0 - 6 Months')
            {
                listOfAccounts.add(new Account(
                                        Id = tempResponse.Account__c, 
                                        Next_Purchase_Timeframe__c = '0 to 6 Months'
                                    ));
            }
            else if(tempResponse.Answer__c == '7 - 12 Months')
            {
                listOfAccounts.add(new Account(
                                        Id = tempResponse.Account__c, 
                                        Next_Purchase_Timeframe__c = '7 to 12 Months'
                                    ));
            }
            else if(tempResponse.Answer__c == 'A Year From Now')
            {
                listOfAccounts.add(new Account(
                                        Id = tempResponse.Account__c, 
                                        Next_Purchase_Timeframe__c = 'A Year From Now'
                                    ));
            }
            else if(tempResponse.Answer__c == '2 Years From Now')
            {
                listOfAccounts.add(new Account(
                                        Id = tempResponse.Account__c, 
                                        Next_Purchase_Timeframe__c = '2 Years From Now'
                                    ));
            }
        }
        
        update listOfAccounts;
    }

    public static void createFollowUpTasks(List<In_Motion_Response__c> newList)
    {
        List<Task> listOfTasks = new List<Task>();

        List<Id> listOfActionIds = new List<Id>();

        for(In_Motion_Response__c tempResponse : newList)
        {
            listOfActionIds.add(tempResponse.In_Motion_Action__c);
        }

        System.debug(listOfActionIds);

        Map<Id, In_Motion_Action__c> mapOfActions = new Map<Id, In_Motion_Action__c>([SELECT Id,
                                                                                        Task_Description__c,
                                                                                        Task_Due_Date_In_Days__c,
                                                                                        Task_Subject__c,
                                                                                        In_Motion_Option__c,
                                                                                        In_Motion_Option__r.In_Motion_Question__c
                                                                                    FROM In_Motion_Action__c 
                                                                                    WHERE Id IN :listOfActionIds]);

        System.debug(mapOfActions);

        Id bethOldaker = [SELECT Id FROM User WHERE Name = 'Beth Oldaker' LIMIT 1].Id;
        // AMM1 
        // Id ronCollins = [SELECT Id FROM User WHERE Name = 'Ronald Collins' LIMIT 1].Id;
        Id ronCollins = [SELECT Id FROM User WHERE Name = 'Tasha Terry' LIMIT 1].Id;
        // AMM1

        for(In_Motion_Response__c tempResponse : newList)
        {
            Id tempOwner = null;

            if(mapOfActions.get(tempResponse.In_Motion_Action__c) != null && 
                mapOfActions.get(tempResponse.In_Motion_Action__c).id == tempResponse.In_Motion_Action__c)
            {
                String status = '';
                if(tempResponse.Answer__c == '0 - 6 Months')
                {
                   status = 'P1';
                   tempOwner = bethOldaker;
                }
                else if(tempResponse.Answer__c == '7 - 12 Months')
                {
                    status = 'P2';
                    tempOwner = bethOldaker;
                }
                else if(tempResponse.Answer__c == 'A Year From Now' || tempResponse.Answer__c == '2 Years From Now')
                {
                    status = 'P3';
                    tempOwner = ronCollins;
                }

                if(status != '')
                {
                    listOfTasks.add(new Task(
                        WhatId = tempResponse.Account__c, 
                        OwnerId = tempOwner != null ? tempOwner : Id.valueOf(tempResponse.Account_Owner_Id__c),
                        Subject = 'InMotion Follow Up ' + status,
                        ActivityDate = System.Today().addDays(Integer.valueOf(mapOfActions.get(tempResponse.In_Motion_Action__c).Task_Due_Date_In_Days__c))
                    ));
                }
            }
        }

        System.debug(listOfTasks);

        insert listOfTasks;
    }

    public static void stickerTaskCreation(List<In_Motion_Response__c> newList)
    {
         List<Task> listOfTasks = new List<Task>();

        List<Id> listOfActionIds = new List<Id>();

        for(In_Motion_Response__c tempResponse : newList)
        {
            listOfActionIds.add(tempResponse.In_Motion_Action__c);
        }

        System.debug(listOfActionIds);

        Map<Id, In_Motion_Action__c> mapOfActions = new Map<Id, In_Motion_Action__c>([SELECT Id,
                                                                                        Task_Description__c,
                                                                                        Task_Due_Date_In_Days__c,
                                                                                        Task_Subject__c,
                                                                                        In_Motion_Option__c,
                                                                                        In_Motion_Option__r.In_Motion_Question__c
                                                                                    FROM In_Motion_Action__c 
                                                                                    WHERE Id IN :listOfActionIds]);

        System.debug(mapOfActions);

        Id bailey = [SELECT Id FROM User WHERE Name = 'Bailey Mendlik' LIMIT 1].Id;

        for(In_Motion_Response__c tempResponse : newList)
        {
            Id tempOwner = null;

            System.debug(mapOfActions.get(tempResponse.In_Motion_Action__c) != null);
            System.debug(mapOfActions.get(tempResponse.In_Motion_Action__c).id == tempResponse.In_Motion_Action__c);
            System.debug(tempResponse.Answer__c.contains('#MW-'));

            if(mapOfActions.get(tempResponse.In_Motion_Action__c) != null && 
                mapOfActions.get(tempResponse.In_Motion_Action__c).id == tempResponse.In_Motion_Action__c)
            {
                if(tempResponse.Answer__c.contains('#MW-'))
                {
                    listOfTasks.add(new Task(
                        WhatId = tempResponse.Account__c, 
                        OwnerId = bailey,
                        Subject = tempResponse.Answer__c,
                        ActivityDate = System.Today()
                    ));
                }
            }
        }

        System.debug(listOfTasks);

        insert listOfTasks;
    }
}