/**
* PartsSalesLineTrigger
* Tested by: PartsSalesLineTriggerTest
* 
* Coverage:
* 2017-10-17	80% (20/25)
* 2018-10-22    82% (23/28)
* 
* Date             |Developer            |Work#
* Notes
* ---------------------------------------------
* 2016.09.06       |Gaurav          |Case-00002028
* Updated trigger for adding Extended price value to its Parent Service Job's part total field
*
* 2017.01.05       |Gaurav          |Case-00002338
* Updated trigger to set Price to the same value as Cost
*
*	2017-05-12		B. Leaman		BLL1 - Updating another obj s/b AFTER trigger. Then parts total will work
*									with multiple record insert/update properly.
* Also comment out Case-00002338, as it's not in production yet.
*	2017-10-16		B. Leaman		BLL2 - don't add nulls to Id lists, which can cause non-selective queries;
*									No before actions exist (until pending DT mods are implemented), so don't fire in "before" context.
* 
* 	2017-10-24 		J. Kuljis		JVK1 - Re-introduce the automated markdown of parts totals if their set to paytypes of I/W
* 	2018-10-11 		J.Kuljis		JVK2 - Automated markdown could fail if cost was set to 0 prior to trigger execution
*											Updated to always apply cost based on part cost.
*	2018-10-22	B. Leaman	IR-0042441	BLL3 - Looks like both DealerTeam and custom code are issueing DML to update service job lines.
*										Update custom code to implement a flag to disable our update (and re-enable easily if this doesn't work).
*/

trigger PartsSalesLineTrigger on dealer__Parts_Invoice_Line__c (before insert, before update, after insert, after update ) {	// BLL1c

    /* Case-00002028 Begin */
    //Set of Ids of SRO
    Set<Id> ServiceJobLineIdSet = new Set<Id>();
    
    //Map of Service Job Id and List of Parts
    Map<Id, List<dealer__Parts_Invoice_Line__c>> ServiceJobIdAndPartLineListMap = new Map<Id, List<dealer__Parts_Invoice_Line__c>>(); 
    
    //Map Service job Id and service job
    Map<Id, dealer__Service_Job__c> ServiceJobIdMap = new Map<Id, dealer__Service_Job__c>();
    
    //List of service job that is created to update the service job records
    List<dealer__Service_Job__c> ServiceJobList = new List<dealer__Service_Job__c>();
    
    //BLL2d if(Trigger.isBefore){
    //BLL2d     //Condition to checek for Insert or Update trigger
    //BLL2d     if(Trigger.isInsert || Trigger.isUpdate){
    //BLL2d         //For loop to populate service job line Id set
    //BLL2d         for(dealer__Parts_Invoice_Line__c objPartInvoiceLine : Trigger.New){
    //BLL2d             if (objPartInvoiceLine.dealer__Job_Line__c!=null) ServiceJobLineIdSet.add(objPartInvoiceLine.dealer__Job_Line__c);	// BLL2c
                 /*Case-00002338 Begin*/
                 //Setting up Price value same as Cost
                 //   if(objPartInvoiceLine.dealer__Cost__c != null && (objPartInvoiceLine.dealer__Pay_Type__c == 'I' || objPartInvoiceLine.dealer__Pay_Type__c =='W')){
                 //         objPartInvoiceLine.dealer__Price__c = objPartInvoiceLine.dealer__Cost__c; 
                 //   }
                /*Case-00002338 End*/
    //BLL2d         }
    //BLL2d     }
    //BLL2d }	// BLL1a
    
    // JVK1
	/* replaced with JVK2
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
		for(dealer__Parts_Invoice_Line__c ol : Trigger.new) {           
            if(ol.dealer__Job_Line__c != null 
               	&& ol.dealer__Cost__c != null 
                && ol.dealer__Service_Line_Payment_Method__c != null
                && (ol.dealer__Service_Line_Payment_Method__c=='I' || ol.dealer__Service_Line_Payment_Method__c=='W')){
                	ol.dealer__Price__c = (ol.dealer__Cost__c / ol.dealer__Quantity_Sold__c); 
                    ol.dealer__Total_Price__c  = ol.dealer__Cost__c;
            }        
        }
    }
	*/
    // End JVK1

    // JVK2 - Rewrite parts pricing markdown to prevent race condition of Cost__c == 0
    // // DT Case# 4013 - Details in API Class
	if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
		PartSupportAPI.setInternalWarrantyPartsToCost(Trigger.new);
    }
    // JVK2 END
    
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) { 	// BLL1a
		for(dealer__Parts_Invoice_Line__c objPartInvoiceLine : Trigger.New){	// BLL1a
			if (objPartInvoiceLine.dealer__Job_Line__c!=null) ServiceJobLineIdSet.add(objPartInvoiceLine.dealer__Job_Line__c);	// BLL1a, BLL2c
		}	// BLL1a
            
        //For loop to populate ServiceJob Maps
        for(dealer__Service_Job__c objServiceJob : [SELECT Id, Name, dealer__Parts_Total__c, (SELECT Id, Name, dealer__Extended_Price__c FROM dealer__Parts_Lines__r) FROM dealer__Service_Job__c WHERE ID IN : ServiceJobLineIdSet]){
            ServiceJobIdAndPartLineListMap.put(objServiceJob.Id, objServiceJob.dealer__Parts_Lines__r);
            ServiceJobIdMap.put(objServiceJob.Id, objServiceJob);
        }
        System.debug('ServiceJobIdAndPartLineListMap >>'+ServiceJobIdAndPartLineListMap);
        System.debug('ServiceJobIdMap >>'+ServiceJobIdMap);
        
        //If trigger is for Insert or Update
        if(Trigger.isInsert || Trigger.isUpdate){
            //BLL2d already done: ServiceJobLineIdSet = new Set<Id>();
            
            //For loop to fetch all the related parts and update part total field that is sum of Extended price of all related parts
            for(dealer__Parts_Invoice_Line__c objPartInvoiceLine : Trigger.New){
            
                //If Part is having Job line            
                if(objPartInvoiceLine.dealer__Job_Line__c != null){
                
                    //Create new service job and assign updated service job
                    dealer__Service_Job__c objServiceJob = new dealer__Service_Job__c();
                    
                    //Get the service job from Map
                    if (objPartInvoiceLine.dealer__Job_Line__c!=null) objServiceJob = ServiceJobIdMap.get(objPartInvoiceLine.dealer__Job_Line__c);	// BLL2c
                    
                    //Assign 0 to parts total to service job
                    //BLL1d objServiceJob.dealer__Parts_Total__c = 0.0;
                    Decimal partstotal = 0.00;	// BLL1a
                    
                    //Loop through the list of all the related parts of service job
                    for (dealer__Parts_Invoice_Line__c objPartLine : ServiceJobIdAndPartLineListMap.get(objPartInvoiceLine.dealer__Job_Line__c)){
                        
                        //Add Extended price to Parts Total field
                        //BLL1d objServiceJob.dealer__Parts_Total__c += objPartLine.dealer__Extended_Price__c;
                        partstotal += objPartLine.dealer__Extended_Price__c;	// BLL1a                     
                        System.debug('objServiceJob.dealer__Parts_Total__c -->>'+objServiceJob.dealer__Parts_Total__c);
                        // BLL new lines need added, existing lines updated in case of multiple line update/insert               
                    }
                    
                    if(objServiceJob!=null && objServiceJob.id!=null && !ServiceJobLineIdSet.contains(objServiceJob.id)){	// BLL2c
                    	//System.debug(partstotal);
                    	//System.debug(objServiceJob.dealer__Parts_Total__c);
                        //Add Service job to list to update the service jobs
                        if (partstotal!=objServiceJob.dealer__Parts_Total__c) {	// BLL1a - only update if it's different!
                        	objServiceJob.dealer__Parts_Total__c = partstotal;	// BLL1a
                        	ServiceJobList.add(objServiceJob);
                        }	// BLL1a
                        ServiceJobLineIdSet.add(objServiceJob.id);
                    }
                }
            }
        }
    }	// BLL1a
    //BLL2d if (Trigger.isBefore) {	// BLL1a
        /*Case-00002338 Begin*/
        //if(Trigger.isUpdate){
        //    for(dealer__Parts_Invoice_Line__c objPartInvoiceLine : Trigger.New){
        //        //If Old value of Price is changed it should not be changed.
        //        dealer__Parts_Invoice_Line__c objOldPartInvoiceLine = Trigger.oldMap.get(objPartInvoiceLine.id);
        //        if(objOldPartInvoiceLine.dealer__Price__c != objPartInvoiceLine.dealer__Price__c && (objPartInvoiceLine.dealer__Pay_Type__c == 'I' || objPartInvoiceLine.dealer__Pay_Type__c =='W')){
        //            objPartInvoiceLine.dealer__Price__c = objPartInvoiceLine.dealer__Cost__c; 
        //        }
        //    }
        //} 
      /*Case-00002338 End*/
    //BLL2d }
    

	// BLL3
	MW_TriggerControls__c PartsSalesUpdatesJob = MW_TriggerControls__c.getInstance('PartsSalesUpdatesJob');	
	// BLL3 end

    //If list is not empty
    // BLL3
    //if(ServiceJobList.size() > 0) {
    if (ServiceJobList.size()>0 && (PartsSalesUpdatesJob==null || PartsSalesUpdatesJob.Enabled__c==true)) {
    // BLL3 end
        System.debug('ServiceJobList before-->>'+ServiceJobList);
        //Update the service job list
        update ServiceJobList;
        System.debug('ServiceJobList after-->>'+ServiceJobList);        
    } 
    /* Case-00002028 End */  

}