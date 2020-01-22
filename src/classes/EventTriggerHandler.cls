/**
 * WMK, LLC (c) - 2019 
 *
 * EventTriggerHandler
 * 
 * Created By:   Alexander Miller
 * Created Date: 1/31/2019 
 * Tested By: EventTriggerHandlerTest
 * Work Item:    W-000571
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *	B. Leaman			BLL1		W-000595	2019-02-14	Fix error: De-reference null.
 *  A. Miller           AMM2        W-000631    2019-03-27  Update to handle edge case with Person Accounts
 */
public class EventTriggerHandler {

    public EventTriggerHandler(){}

    /**
    * setAccountField
    *
    * Process which sets the Account field of the Event
    * based on whether its directly or indrectly tied 
    * to one. If its indirectly tied to an Account
    * via Opportunity, Opportunity__c, or Solution Opportunity,
    * then the Accounts are taken from those objects instead.
    *
    * @param List<Event> newList - Trigger context of Tasks
    */
    public void setAccountField(List<Event> newList)
    {
        Map<Id, List<Event>> mapOfOpportunityEvents = new Map<Id, List<Event>>();
        Map<Id, List<Event>> mapOfCustomOpportunityEvents = new Map<Id, List<Event>>();
        Map<Id, List<Event>> mapOfSolutionOpportunityEvents = new Map<Id, List<Event>>();
        // AMM3
		Map<Id, List<Event>> mapOfContactEvents = new Map<Id, List<Event>>();
		List<Id> listOfAccountIds = new List<Id>();
		Map<Id, Event> mapOfPotentialPersonAccountEvents = new Map<Id, Event>();
		// AMM3

        for(Event tempEvent : newList)
        {
            // 1. Get Object Id of from the WhatId field
            // BLL1 : WhatId might be null
			//String sObjName = tempEvent.WhatId.getSObjectType().getDescribe().getName();
			if(tempEvent.WhatId != null)
            {            
                String sObjName = tempEvent.WhatId.getSObjectType().getDescribe().getName();
			    //if (tempEvent.WhatId!=null) sObjName = tempEvent.WhatId.getSObjectType().getDescribe().getName();
                // BLL1 end

                System.debug(sObjName);

                // 2. Bucket the events into their respective ties to WhatId objects            

                // BLL1
                if(sObjName.equalsIgnoreCase('Account'))
                //if(!String.isBlank(sObjName) && sObjName.equalsIgnoreCase('Account'))
                // BLL1 end
                {
                    tempEvent.Account__c = tempEvent.WhatId;

                    // AMM3
                    if(tempEvent.WhoId == null)
                    {
                        listOfAccountIds.add(tempEvent.WhatId);
                        mapOfPotentialPersonAccountEvents.put(tempEvent.WhatId, tempEvent);
                    }
                    // AMM3
                }
                // BLL1
                else if(sObjName.equalsIgnoreCase('Opportunity'))
                //else if(!String.isBlank(sObjName) && sObjName.equalsIgnoreCase('Opportunity'))
                // BLL1 end
                {
                    if(mapOfOpportunityEvents.get(tempEvent.WhatId) == null)
                    {
                        List<Event> tempList = new List<Event>();

                        tempList.add(tempEvent);

                        mapOfOpportunityEvents.put(tempEvent.WhatId, tempList);
                    }
                    else 
                    {
                        List<Event> tempList = mapOfOpportunityEvents.get(tempEvent.WhatId);

                        tempList.add(tempEvent);

                        mapOfOpportunityEvents.put(tempEvent.WhatId, tempList);
                    }
                }
                // BLL1
                else if(sObjName.equalsIgnoreCase('Opportunity__c'))
                //else if(!String.isBlank(sObjName) && sObjName.equalsIgnoreCase('Opportunity__c'))
                // BLL1 end
                {
                    if(mapOfCustomOpportunityEvents.get(tempEvent.WhatId) == null)
                    {
                        List<Event> tempList = new List<Event>();

                        tempList.add(tempEvent);

                        mapOfCustomOpportunityEvents.put(tempEvent.WhatId, tempList);
                    }
                    else 
                    {
                        List<Event> tempList = mapOfCustomOpportunityEvents.get(tempEvent.WhatId);

                        tempList.add(tempEvent);

                        mapOfCustomOpportunityEvents.put(tempEvent.WhatId, tempList);
                    }
                }
                // BLL1
                else if(sObjName.equalsIgnoreCase('dealer__Sales_Up__c'))
                //else if(!String.isBlank(sObjName) && sObjName.equalsIgnoreCase('dealer__Sales_Up__c'))
                // BLL1 end
                {
                    if(mapOfSolutionOpportunityEvents.get(tempEvent.WhatId) == null)
                    {
                        List<Event> tempList = new List<Event>();

                        tempList.add(tempEvent);

                        mapOfSolutionOpportunityEvents.put(tempEvent.WhatId, tempList);
                    }
                    else 
                    {
                        List<Event> tempList = mapOfSolutionOpportunityEvents.get(tempEvent.WhatId);

                        tempList.add(tempEvent);

                        mapOfSolutionOpportunityEvents.put(tempEvent.WhatId, tempList);
                    }
                }
            }
            else if(tempEvent.WhoId != null)
			{
				String sObjectNameWhoId = tempEvent.WhoId.getSObjectType().getDescribe().getName();

				System.debug(tempEvent.Subject);
				System.debug(sObjectNameWhoId);

				if(sObjectNameWhoId.equalsIgnoreCase('Contact'))
				{
					if(mapOfContactEvents.get(tempEvent.WhoId) == null)
					{
						List<Event> tempList = new List<Event>();

						tempList.add(tempEvent);

						mapOfContactEvents.put(tempEvent.WhoId, tempList);
					}
					else 
					{
						List<Event> tempList = mapOfContactEvents.get(tempEvent.WhoId);

						tempList.add(tempEvent);

						mapOfContactEvents.put(tempEvent.WhoId, tempList);
					}
				}
			}
        }
        
        // 3. If the WhatId bucket contains anything, query those records to get the Account Ids
        // 4. Map the records for the before context to update automatically

        if(mapOfOpportunityEvents.keySet().size() > 0)
        {
            List<Opportunity> listOfOpportunities = ([SELECT Id, 
                                                        AccountId 
                                                    FROM Opportunity 
                                                    WHERE Id IN :mapOfOpportunityEvents.keySet()]);

            for(Opportunity tempOpportunity : listOfOpportunities)
            {
                if(mapOfOpportunityEvents.get(tempOpportunity.Id) != null)
                {
                    for(Event tempEvent : mapOfOpportunityEvents.get(tempOpportunity.Id))
                    {
                        tempEvent.Account__c = tempOpportunity.AccountId;
                    }
                }
            }
        }   

        if(mapOfCustomOpportunityEvents.keySet().size() > 0)
        {
            List<Opportunity__c> listOfCustomOpportunities = ([SELECT Id, 
                                                                Account__c 
                                                            FROM Opportunity__c 
                                                            WHERE Id IN :mapOfCustomOpportunityEvents.keySet()]);

            for(Opportunity__c tempOpportunity : listOfCustomOpportunities)
            {
                if(mapOfCustomOpportunityEvents.get(tempOpportunity.Id) != null)
                {
                    for(Event tempEvent : mapOfCustomOpportunityEvents.get(tempOpportunity.Id))
                    {
                        tempEvent.Account__c = tempOpportunity.Account__c;
                    }
                }
            }
        }

        if(mapOfSolutionOpportunityEvents.keySet().size() > 0)
        {
            List<dealer__Sales_Up__c> listOfSolutionOpportunities = ([SELECT Id, 
                                                                        dealer__Buyer_Contact__c,
                                                                        dealer__Customer_Account__c 
                                                                    FROM dealer__Sales_Up__c 
                                                                    WHERE Id IN :mapOfSolutionOpportunityEvents.keySet()]);


            for(dealer__Sales_Up__c tempOpportunity : listOfSolutionOpportunities)
            {
                if(mapOfSolutionOpportunityEvents.get(tempOpportunity.Id) != null)
                {
                    for(Event tempEvent : mapOfSolutionOpportunityEvents.get(tempOpportunity.Id))
                    {
                        tempEvent.Account__c = tempOpportunity.dealer__Customer_Account__c;

                        if(tempOpportunity.dealer__Buyer_Contact__c != null && (tempEvent.WhoId == null || tempEvent.WhoId != tempOpportunity.dealer__Buyer_Contact__c))
                        {
                           tempEvent.WhoId = tempOpportunity.dealer__Buyer_Contact__c; 
						}
                    }
                }
            }
        }

        // AMM3
		if(mapOfContactEvents.keySet().size() > 0)
		{
			List<Contact> listOfContacts = ([SELECT Id, 
												AccountId 
											FROM Contact 
											WHERE Id IN :mapOfContactEvents.keySet()]);

			for(Contact tempContact : listOfContacts)
			{
				if(mapOfContactEvents.get(tempContact.Id) != null)
				{
					for(Event tempEvent : mapOfContactEvents.get(tempContact.Id))
					{
						tempEvent.Account__c = tempContact.AccountId;
						
						if(tempEvent.WhatId == null)
						{
							tempEvent.WhatId = tempContact.AccountId;
						}
					}
				}
			}
		}

		// 5. Process potential Person Accounts
		if(listOfAccountIds.size() > 0)
		{	
			Map<Id, Contact> mapOfContactsToAccounts = new Map<Id, Contact>();

			List<Contact> listOfContacts = ([SELECT Id, 
												AccountId 
											FROM Contact 
											WHERE AccountId IN :listOfAccountIds]);

			for(Contact tempContact : listOfContacts)
			{
				mapOfContactsToAccounts.put(tempContact.AccountId, tempContact);
			}

			for(Id accountId : mapOfPotentialPersonAccountEvents.keySet())
			{
				if(mapOfContactsToAccounts.get(accountId) != null)
				{
					mapOfPotentialPersonAccountEvents.get(accountId).WhoId = mapOfContactsToAccounts.get(accountId).Id;
				}
			}
		}
		// AMM3	       
    }
}