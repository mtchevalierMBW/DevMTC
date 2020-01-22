/*
* ServiceJobLineControl
* Tested by: ServiceRepairOrder2_TC
* 
* Coverage:
* 	2017-10-17	88% (21/24)
*	2018-04-06	88% (37/42)
* 	2019-09-20	85%	(36/42)
*	2019-12-17	100%	(10/10)
* 
*   2015-09-22  J. Kuljis   JVK2 - Allow invoiced lines editing override
*   2015-09-30  D. Ray      DR1 - Sync Cause with with extended field
*
*   2016-09-09 | Gaurav Agrawal | Case - 00002053 | Prevent GR* Labor Types without Vehicle Inventory
*
* NOT: Case 2053 fix is causing issues in test. Commenting out until it is reviewed again. 
* I cannot create a NON-Get-Ready RO (one that is NOT using a GR* method) without an inventory vehicle. -- Bryan Leaman
*
*   2016-11-17 | Gaurav Agrawal | Case - 00002188 | Prevent deleting job lines if there are sub lines (Parts/Misc)
*	2017-10-16	B. Leaman	BLL1 - prevent non-selective query (null in a list), eliminate unused code;
*	2017-11-21	B. Leaman	BLL2 - don't reference Trigger.new in delete context.
*	2018-04-05	B. Leamna	BLL3 - don't allow a line to be marked complete if tech time is missing the technician.
*	2019-08-05	B. Leaman	W-000728 BLL4 - trying to remove SOQL limit tests to ensure updates occur.
*	2019-12-17	B. Leaman	W-000788 BLL5 - Refactor trigger & If location splits book time from actual, recalc labor total.
*							Merge in ServiceJob_After trigger.
*/

trigger ServiceJobLineControl on dealer__Service_Job__c (before insert, before update, before delete, after insert, after update, after delete) {    

	// Set default pay method and labor type on job lines if missing
    if(Trigger.isBefore && Trigger.isInsert) {
		ServiceProcess.DefaultPayMethodAndLaborType(Trigger.new);
    }

	// BLL5 
	if (Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert)) {
		ServiceProcess.LaborCalculations(Trigger.new, Trigger.oldMap);
	}
	// BLL5 end

	if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
		// Map extended cause to cause
        ServiceProcess.MapExtendedCauseToCause(Trigger.new);
		// BLL3a - ensure technician specified on all labor lines
		ServiceProcess.RequireTechniciansOnCompleteLines(Trigger.new, Trigger.oldMap);
	}
	// BLL3a end

	// Ensure part charges equal cost for Warranty & Internal
	if (Trigger.isBefore && !Trigger.isDelete) {	// BLLa
		ServiceProcess.SetPartTotalForWarrAndInternal(Trigger.new);
	}	// BLLa


	// Pull in ServiceJob_After trigger functions

	if (Trigger.isAfter) ServiceProcess.SetGetReadyROFlags(Trigger.new, Trigger.oldMap);

    if(Trigger.isAfter && Trigger.isUpdate) ServiceProcess.UpdatePayTypes(Trigger.new);


    /* Case - 00002053 Begin */
    /** BLL removed - logic was causing issues - unable to create any RO without vehicle inventory
      * Also, there is already a simple validation rule for this that just needs "Open" status to be checked
      * to accomplish the same thing.
    //Trigger is for Insert and Update events
    if(Trigger.isInsert || Trigger.isUpdate){
        
        //Set of Payment Method Ids
        Set<Id> PaymentMethodIdSet = new Set<Id>();
        
        //Set of SRO IDs
        Set<Id> SROIdSet = new Set<Id>();
        
        //Map of Payment Method Id and its Name
        Map<Id, ServicePaymentType__c> PaymentMethodIdNameMap = new Map<Id, ServicePaymentType__c>();
        
        //Map of SRO ID and SRO
        Map<Id, dealer__Service_Repair_Order__c> SROIdMap = new Map<Id, dealer__Service_Repair_Order__c>();
        
        //For loop to get Payment method Ids in Set of Ids
        for(dealer__Service_Job__c objServiceJob : Trigger.new){
           
            if(objServiceJob.Payment_Method__c != null){
                PaymentMethodIdSet.add(objServiceJob.Payment_Method__c);
            }
            
            if(objServiceJob.dealer__Service_Repair_Order__c != null){
                SROIdSet.add(objServiceJob.dealer__Service_Repair_Order__c);
            }
        }
        
        //For loop to fill Map of Payment Method Id and Name
        for(ServicePaymentType__c objServicePayment : [SELECT ID, Name, Payment_Type__c FROM ServicePaymentType__c WHERE ID IN : PaymentMethodIdSet]){
            PaymentMethodIdNameMap.put(objServicePayment.Id, objServicePayment);
        }
        
        //For loop to fill Map of SRO ID and SRO
        for(dealer__Service_Repair_Order__c objSRO : [SELECT Id, dealer__Vehicle_Inventory__c FROM dealer__Service_Repair_Order__c WHERE ID IN : SROIdSet]){
            SROIdMap.put(objSRO.Id, objSRO);
        }
        
        //For loop of Insert/Update trigger instance
        for(dealer__Service_Job__c objServiceJob : Trigger.new){        

            //Condition of error if Labor type of Service Job i.e. Payment Method Name Starts with 'GR' or Related SRO having no vehicle inventory present
            if(PaymentMethodIdNameMap.get(objServiceJob.Payment_Method__c).Payment_Type__c.startsWithIgnoreCase('GR') || SROIdMap.get(objServiceJob.dealer__Service_Repair_Order__c).dealer__Vehicle_Inventory__c == null){
                objServiceJob.addError('Please Select different Labor Type and Fill Vehicle Inventory for SRO');
            }     
        }
    }
    **/
    /* Case - 00002053 End */


        // Check for Invoiced Date and Prevent Changes
            // JVK1
            //BLL1d MW_TriggerControls__c roProtection = MW_TriggerControls__c.getInstance('RepairOrderProtect');
            //BLL1d boolean postProtected = true;
            //BLL1d if(roProtection!=null) {
            //BLL1d     postProtected = roProtection.Enabled__c;
            //BLL1d } 
            // JVK1
			// BLL5
            //for(dealer__Service_Job__c j : Trigger.New) {

                /*
                 -- This does not work due to the posting process --
                if(j.dealer__RO_Invoice_Date_Time__c != null) {

                    if(postProtected==true) {
                        j.addError('Posted Repair Order Lines may not be edited.');
                    }
                }
                */

                // DR1 Sync Cause with with extended field
            //    if(j.dealer__CauseExtended__c !=null) {
            //        j.dealer__Cause__c = j.dealer__CauseExtended__c.abbreviate(250);
            //    }
                // /DR1
                
            //}
			// BLL5 end
        //}
        
        
        /* Case 00002188 Begin */
/** BLL1d - not in production. Commenting out until reviewed again...
        if(Trigger.isBefore && Trigger.isDelete){
            //Set of Ids of Service Job
            Set<Id> ServiceJobIdSet = new Set<Id>();            
            
            //Map of Service Job id and its related Part lines
            Map<Id, List<dealer__Parts_Invoice_Line__c>> ServiceJobMap = new Map<Id, List<dealer__Parts_Invoice_Line__c>>();
                       
            //For loop to get all the Ids of Service Job in Trigger's Context 
            for(dealer__Service_Job__c objServiceJob : Trigger.old) {
                ServiceJobIdSet.add(objServiceJob.Id);
            }
            
            //For loop to create Map of Service Job Id and its related Part lines
            for(dealer__Service_Job__c objServiceJob : [SELECT Id, Name, (SELECT id, Name FROM dealer__Parts_Lines__r) FROM dealer__Service_Job__c WHERE Id IN : ServiceJobIdSet]){
                if(objServiceJob.dealer__Parts_Lines__r.size()>0){
                    ServiceJobMap.put(objServiceJob.Id, objServiceJob.dealer__Parts_Lines__r);
                }
            }
            
            //For loop to check Service Job's Part lines 
            for(dealer__Service_Job__c objServiceJob : Trigger.old){
                //If present then throw the error
                if(ServiceJobMap.get(objServiceJob.Id) != null){           
                    objServiceJob.addError('You can not delete service job which is having part line');
                }
            }
        }
**/
        /* Case 00002188 End */                
    // BLL4
	//}
	// BLL4
}