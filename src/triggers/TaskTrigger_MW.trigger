/**
 *	TaskTrigger_MW
 *	Tested by: Test_LeadClasses
 *	
 * Coverage:
 *	2018-12-07	100%	(6/6)
 *
 *	2017-10-16	B. Leaman	BLL1 ensure no nulls in soql query to create non-selective queries.
 * 	2018-10-22	B. Leaman 	W-000461	BLL2 - Don't query leads for WhoId that isn't a lead.
 *	2018-12-07	B. Leaman	W-000511 BLL3 - Refactor into class and add TaskSubtype designation based on pattern matching on subject line
 *  2019-01-30  A. Miller   W-000571 AMM1 - Update to handle tying Tasks to all Accounts based on What Id for Opportunities, Solution Opportunities, and custom Opportunities
**/
// BLL3
//trigger TaskTrigger_MW on Task (after insert, after update) {
// AMM1
// trigger TaskTrigger_MW on Task (before insert, after insert, after update) {    System.debug('Running TaskTrigger_MW');
trigger TaskTrigger_MW on Task (before insert, before update, after insert, after update) {    System.debug('Running TaskTrigger_MW');
// AMM1

	if (Trigger.isBefore && (Trigger.isInsert)) {
		MW_TriggerControls__c taskSubtype = MW_TriggerControls__c.getInstance('taskSubtype');
		if (taskSubtype==null || taskSubtype.Enabled__c) TaskProcess.assignSubtype(Trigger.new);
	}

	// AMM1
	if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate))
	{
		TaskProcess.setAccountField(Trigger.new);
	}
	// AMM1

	if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
	    MW_TriggerControls__c busHours = MW_TriggerControls__c.getInstance('LeadBusHrsElapsed');
		if (busHours==null || busHours.Enabled__c) TaskProcess.setResponseTime(Trigger.new);
	}

// BLL3 end

/** BLL3d moved to TaskProcess
	// BLL2
	String pfx = Schema.Lead.SObjectType.getDescribe().getKeyPrefix();
	// BLL2 end
    if (Trigger.isInsert || Trigger.isUpdate) {
	    MW_TriggerControls__c busHours = MW_TriggerControls__c.getInstance('LeadBusHrsElapsed');
	    
	    // Lead last activity date isn't updated synchronously with creation of a task,
		// so we need this trigger to calc actual response times.
	    if (busHours==null || busHours.Enabled__c || Test.isRunningTest()) {
	        System.debug('Running TaskTrigger_MW business hours elapsed calcs');
	
	  	    DateTime rightnow = DateTime.Now();
	     	BusinessHours bh = [select Id from BusinessHours where IsDefault=true limit 1];
	     	List<Id> taskleads = new List<Id>();
	     	List<Lead> leads = new List<Lead>();
	     	List<Lead> updleads = new List<Lead>();
	     	    
	        // Get list of Leads (WhoId) affected
	        // Can't tell Leads using Who.Type - it's null at this point
	        for(Task t : Trigger.new) {
           		// BLL2
				//if (t.WhoId!=null) taskleads.add(t.WhoId);	// BLL1c
				if (t.WhoId!=null && String.valueOf(t.WhoId).startsWith(pfx)) taskleads.add(t.WhoId);
				// BLL2 end
	        }
	        System.debug('Nbr task leads = ' + taskleads.size());
	        
	        // Update Leads that don't have response times already calculated and have been
	        // taken out of the queue (to prevent update on automated emails)
			// BLL2
	        //leads = [select Id, Name, CreatedDate, Lead_Queue_Name__c
	        //         from Lead
	        //         where Id in :taskleads 
	        //           and isConverted=false
	        //           and Lead_Queue_Name__c!=null and BusHrs_Time_In_Queue__c!=null 
	        //           and BusHrs_Response_Time_BDC__c=null 
	        //];
	        if (taskleads.size()>0) leads = [select Id, Name, CreatedDate, Lead_Queue_Name__c
	                 from Lead
	                 where Id in :taskleads 
	                   and isConverted=false
	                   and Lead_Queue_Name__c!=null and BusHrs_Time_In_Queue__c!=null 
	                   and BusHrs_Response_Time_BDC__c=null 
	        ];
			// BLL2 end
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
            
	    } // busHours enabled
	    
    } // isInsert || isUpdate
**/    

}