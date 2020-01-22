/**
 * TaskProcess
 * Tested by: Test_LeadClasses
 * Date: 2018-12-07
 * Programmer: Bryan Leaman
 *
 * Coverage
 * 2018-12-07	100%	(50/50)
 *
 * Modifications
 * 2018-12-07	B. Leaman	W-000511 Written; setResponseTime refactored from TaskTrigger_MW.
 * 2018-12-18	B. Leaman	W-000532 BLL1; restrict activity subjects to picklist values;
 *							commented out for now, but hanging on to code;
 * 2019-01-30   A. Miller   W-000571 AMM1 - Update to handle tying Tasks to all Accounts based on What Id for Opportunities, Solution Opportunities, and custom Opportunities
 * 2019-02-08   A. Miller   IR-0048769 AMM2 - Fix for make sure WhatId isn't null
 * 2019-03-27   A. Miller   W-000631 AMM3 - Update to handle edge case with Person Accounts
**/
public with sharing class TaskProcess {

	// BLL1
	public static Set<String> TaskSubjects;
	// BLL1

	// setResponseTime - new task on a lead indicates BDC has responded, record elapsed times
	public static void setResponseTime(List<Task> newlist) {
		String pfx = Schema.Lead.SObjectType.getDescribe().getKeyPrefix();
        System.debug('Running TaskTrigger_MW business hours elapsed calcs');
	
  	    DateTime rightnow = DateTime.Now();
     	BusinessHours bh = [select Id from BusinessHours where IsDefault=true limit 1];
     	List<Id> taskleads = new List<Id>();
     	List<Lead> leads = new List<Lead>();
     	List<Lead> updleads = new List<Lead>();
	     	    
        // Get list of Leads (WhoId) affected
        // Can't tell Leads using Who.Type - it's null at this point
        for(Task t : newlist) {
			if (t.WhoId!=null && String.valueOf(t.WhoId).startsWith(pfx)) taskleads.add(t.WhoId);
        }
        System.debug('Nbr task leads = ' + taskleads.size());
	        
	    // Update Leads that don't have response times already calculated and have been
	    // taken out of the queue (to prevent update on automated emails)
	    if (taskleads.size()>0) leads = [select Id, Name, CreatedDate, Lead_Queue_Name__c
	             from Lead
	             where Id in :taskleads 
	               and isConverted=false
	               and Lead_Queue_Name__c!=null and BusHrs_Time_In_Queue__c!=null 
	               and BusHrs_Response_Time_BDC__c=null 
	    ];
	    System.debug('Leads to update: ' + leads.size());
	    if (leads.size()>0) {
		    for(Lead l : leads) {
		        // Elapsed queue and response times - raw & business hours
				Long elapsed_msec = rightnow.getTime() - l.CreatedDate.getTime();
				Integer elapsed_min = Math.min(99999, (Integer) ((elapsed_msec / 1000) / 60));
		        Long bh_elapsed_msec = BusinessHours.diff(bh.Id, l.CreatedDate, rightnow);
				Integer bh_elapsed_min = Math.min(99999, (Integer) ((bh_elapsed_msec / 1000) / 60));
		  			
		  		// Response time (activity recorded and response time not previously calculated)
			    l.Response_Time_BDC__c = elapsed_min; 
			    l.BusHrs_Response_Time_BDC__c = bh_elapsed_min;
			    updleads.add(l);
		    } // end for Lead l : leads
		    
		    if (updleads.size()>0) {
		        update(updleads);
		    }
		    
	    } // end if leads.size()>0
            
	}

	// assignSubtype
	//---------------------------------------
	public static void assignSubtype (List<Task> newlist) {

		List<TaskSubtypeRule> rules = new List<TaskSubtypeRule>();
		for(TaskSubtypeRule__c tsr : [
			select Name, TypePattern__c, SubjectPattern__c, Subtype__c
			from TaskSubtypeRule__c 
			order by Sequence__c
		]) {
			rules.add(new TaskSubtypeRule(tsr.Name, tsr.TypePattern__c, tsr.SubjectPattern__c, tsr.Subtype__c));
		}
		// default rules in the absense of finding any custom settings
		if (rules.size()==0) {
			rules.add(new TaskSubtypeRule('Pardot list email', '.*', '(?i)Pardot.*Email.*', 'ListEmail'));
			rules.add(new TaskSubtypeRule('Call', '.*', '(?i)Call.*', 'Call'));
			rules.add(new TaskSubtypeRule('Email', '.*', '(?i)E-?mail.*', 'Email'));
		}

		for(Task t : newlist) {
			if (!t.isRecurrence && !String.isBlank(t.Subject)) {	// cannot set on recurrances!
				for(TaskSubtypeRule r : rules) {
					if (r.pPattern.matcher(t.Subject).matches() && r.tPattern.matcher(t.Type).matches()) {
						t.TaskSubtype = r.Subtype;
						System.debug('TaskSubtype=' + t.TaskSubtype + ' for subject: ' + t.Subject);
						break;	// use the first match only!
					}
				}
			}
		}
	}

	public class TaskSubtypeRule {
		public String Name {get;set;}
		public String SubjectPattern {get;set;}
		public String TypePattern {get;set;}
		public String Subtype {get;set;}
		public Pattern pPattern {get;set;}
		public Pattern tPattern {get;set;}
		public TaskSubtypeRule(String n, String t, String p, String s) {
			Name=n;
			TypePattern = t;
			SubjectPattern = p;
			Subtype = s;
			pPattern = Pattern.compile(SubjectPattern);
			tPattern = Pattern.compile(TypePattern);
		}
	}

	// BLL1
	// restrictSubject
	//---------------------------
//	public static void restrictSubject(List<Task> newlist) {
//		boolean allowTaskSubjectOverride = FeatureManagement.checkPermission('Task_Subject_Override');
//		System.debug(allowTaskSubjectOverride);
//		allowTaskSubjectOverride = Utility.hasCustomPermission('Task_Subject_Override');
//		System.debug(allowTaskSubjectOverride);
//
//		if (TaskSubjects==null) {
//			TaskSubjects = new Set<String>();
//			Schema.DescribeFieldResult dfr = Task.Subject.getDescribe();
//			List<Schema.PicklistEntry> plvs = dfr.getPicklistValues();
//			for(Schema.PicklistEntry p : plvs) TaskSubjects.add(p.getLabel());
//		}
//		if (!allowTaskSubjectOverride) {
//			for(Task t : newlist) {
//				if (!TaskSubjects.contains(t.Subject))
//					t.addError('Task subject is not one of the defined options');
//			}
//		}
//	}
	// BLL1


	// AMM1
	/**
	* setAccountField
	*
	* Process which sets the Account field of the Task
	* based on whether its directly or indrectly tied 
	* to one. If its indirectly tied to an Account
	* via Opportunity, Opportunity__c, or Solution Opportunity,
	* then the Accounts are taken from those objects instead.
	*
	* @param List<Task> newList - Trigger context of Tasks
	*/
	public static void setAccountField(List<Task> newList)
	{
		Map<Id, List<Task>> mapOfOpportunityTasks = new Map<Id, List<Task>>();
		Map<Id, List<Task>> mapOfCustomOpportunityTasks = new Map<Id, List<Task>>();
		Map<Id, List<Task>> mapOfSolutionOpportunityTasks = new Map<Id, List<Task>>();
		// AMM3
		Map<Id, List<Task>> mapOfContactTasks = new Map<Id, List<Task>>();
		List<Id> listOfAccountIds = new List<Id>();
		Map<Id, Task> mapOfPotentialPersonAccountTasks = new Map<Id, Task>();
		// AMM3

		for(Task tempTask : newList)
		{
			// AMM2
			if(tempTask.WhatId != null)
			{
			// AMM2

				// 1. Get Object Id of from the WhatId field
				String sObjName = tempTask.WhatId.getSObjectType().getDescribe().getName();
				
				System.debug(tempTask.Subject);
				System.debug(sObjName);

				// 2. Bucket the tasks into their respective ties to WhatId objects			

				if(sObjName.equalsIgnoreCase('Account'))
				{
					tempTask.Account__c = tempTask.WhatId;

					// AMM3
					if(tempTask.WhoId == null)
					{
						listOfAccountIds.add(tempTask.WhatId);
						mapOfPotentialPersonAccountTasks.put(tempTask.WhatId, tempTask);
					}
					// AMM3
				}
				else if(sObjName.equalsIgnoreCase('Opportunity'))
				{
					if(mapOfOpportunityTasks.get(tempTask.WhatId) == null)
					{
						List<Task> tempList = new List<Task>();

						tempList.add(tempTask);

						mapOfOpportunityTasks.put(tempTask.WhatId, tempList);
					}
					else 
					{
						List<Task> tempList = mapOfOpportunityTasks.get(tempTask.WhatId);

						tempList.add(tempTask);

						mapOfOpportunityTasks.put(tempTask.WhatId, tempList);
					}
				}
				else if(sObjName.equalsIgnoreCase('Opportunity__c'))
				{
					if(mapOfCustomOpportunityTasks.get(tempTask.WhatId) == null)
					{
						List<Task> tempList = new List<Task>();

						tempList.add(tempTask);

						mapOfCustomOpportunityTasks.put(tempTask.WhatId, tempList);
					}
					else 
					{
						List<Task> tempList = mapOfCustomOpportunityTasks.get(tempTask.WhatId);

						tempList.add(tempTask);

						mapOfCustomOpportunityTasks.put(tempTask.WhatId, tempList);
					}
				}
				else if(sObjName.equalsIgnoreCase('dealer__Sales_Up__c'))
				{
					if(mapOfSolutionOpportunityTasks.get(tempTask.WhatId) == null)
					{
						List<Task> tempList = new List<Task>();

						tempList.add(tempTask);

						mapOfSolutionOpportunityTasks.put(tempTask.WhatId, tempList);
					}
					else 
					{
						List<Task> tempList = mapOfSolutionOpportunityTasks.get(tempTask.WhatId);

						tempList.add(tempTask);

						mapOfSolutionOpportunityTasks.put(tempTask.WhatId, tempList);
					}
				}
			// AMM2 
			}
			// AMM3
			else if(tempTask.WhoId != null)
			{
				String sObjectNameWhoId = tempTask.WhoId.getSObjectType().getDescribe().getName();

				System.debug(tempTask.Subject);
				System.debug(sObjectNameWhoId);

				if(sObjectNameWhoId.equalsIgnoreCase('Contact'))
				{
					if(mapOfContactTasks.get(tempTask.WhoId) == null)
					{
						List<Task> tempList = new List<Task>();

						tempList.add(tempTask);

						mapOfContactTasks.put(tempTask.WhoId, tempList);
					}
					else 
					{
						List<Task> tempList = mapOfContactTasks.get(tempTask.WhoId);

						tempList.add(tempTask);

						mapOfContactTasks.put(tempTask.WhoId, tempList);
					}
				}
			}

			System.debug(mapOfContactTasks);

			// AMM3
			// AMM2
		}
		
		// 3. If the WhatId bucket contains anything, query those records to get the Account Ids
		// 4. Map the records for the before context to update automatically

		if(mapOfOpportunityTasks.keySet().size() > 0)
		{
			List<Opportunity> listOfOpportunities = ([SELECT Id, 
														AccountId 
													FROM Opportunity 
													WHERE Id IN :mapOfOpportunityTasks.keySet()]);

			for(Opportunity tempOpportunity : listOfOpportunities)
			{
				if(mapOfOpportunityTasks.get(tempOpportunity.Id) != null)
				{
					for(Task tempTask : mapOfOpportunityTasks.get(tempOpportunity.Id))
					{
						tempTask.Account__c = tempOpportunity.AccountId;
					}
				}
			}
		}	

		if(mapOfCustomOpportunityTasks.keySet().size() > 0)
		{
			List<Opportunity__c> listOfCustomOpportunities = ([SELECT Id, 
																Account__c 
															FROM Opportunity__c 
															WHERE Id IN :mapOfCustomOpportunityTasks.keySet()]);

			for(Opportunity__c tempOpportunity : listOfCustomOpportunities)
			{
				if(mapOfCustomOpportunityTasks.get(tempOpportunity.Id) != null)
				{
					for(Task tempTask : mapOfCustomOpportunityTasks.get(tempOpportunity.Id))
					{
						tempTask.Account__c = tempOpportunity.Account__c;
					}
				}
			}
		}

		if(mapOfSolutionOpportunityTasks.keySet().size() > 0)
		{
			List<dealer__Sales_Up__c> listOfSolutionOpportunities = ([SELECT Id, 
                                                                        dealer__Buyer_Contact__c,
																		dealer__Customer_Account__c 
																	FROM dealer__Sales_Up__c 
																	WHERE Id IN :mapOfSolutionOpportunityTasks.keySet()]);


			for(dealer__Sales_Up__c tempOpportunity : listOfSolutionOpportunities)
			{
				if(mapOfSolutionOpportunityTasks.get(tempOpportunity.Id) != null)
				{
					for(Task tempTask : mapOfSolutionOpportunityTasks.get(tempOpportunity.Id))
					{
						tempTask.Account__c = tempOpportunity.dealer__Customer_Account__c;
                        
                        if(tempOpportunity.dealer__Buyer_Contact__c != null && (tempTask.WhoId == null || tempTask.WhoId != tempOpportunity.dealer__Buyer_Contact__c))
                        {
                           tempTask.WhoId = tempOpportunity.dealer__Buyer_Contact__c; 
						}
					}
				}
			}
		}

		// AMM3
		if(mapOfContactTasks.keySet().size() > 0)
		{
			List<Contact> listOfContacts = ([SELECT Id, 
												AccountId 
											FROM Contact 
											WHERE Id IN :mapOfContactTasks.keySet()]);

			for(Contact tempContact : listOfContacts)
			{
				if(mapOfContactTasks.get(tempContact.Id) != null)
				{
					for(Task tempTask : mapOfContactTasks.get(tempContact.Id))
					{
						tempTask.Account__c = tempContact.AccountId;
						
						if(tempTask.WhatId == null)
						{
							tempTask.WhatId = tempContact.AccountId;
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

			for(Id accountId : mapOfPotentialPersonAccountTasks.keySet())
			{
				if(mapOfContactsToAccounts.get(accountId) != null)
				{
					mapOfPotentialPersonAccountTasks.get(accountId).WhoId = mapOfContactsToAccounts.get(accountId).Id;
				}
			}
		}
		// AMM3	
	}
	// AMM1
}