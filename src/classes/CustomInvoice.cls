/**
 * CustomInvoice
 * Tested by: CustomInvoice_TC,DealProcess_TEST
 * 2015-08-31	B. Leaman	Get service vehicle from link, default to VIN lookup only if missing and VIN is not empty.
 * 2015-09-03	J. Kuljis	JVK1 Set the company based on the Proposal not the logged in user.  
 * 2015-10-06	J. Kuljis	JVK1 - IT14799 Repair order lines should be updated if an approval fails.
 * 2015-11-18	B. Leaman	BLL2 - trap for exception of not finding a matching service vehicle by inventory or VIN.
 * 2016-01-26   J. Kuljis   JVK2 - Update the software to use the managed ro index.
 * 2016-02-09   RedTeal     RT1  - Added lookup from RO to deal object
 * 2016-02-11   J. Kuljis   JVK3 - Added index sync check
 * 2016-08-19 	J. Kuljis	JVK4 - If Vehicle does not exist (Customer owned Chasis) default to IEO
 * 2016-12-09   Gaurav      #W 000798 - Mapped Location's Lookup field Primary Service Center on Location to newly created SRO if not null
 * 2016-12-21	B. Leaman	BLL3 - Don't assign RO numbers -- it's done via DealerTeam trigger now.
 * 2016-12-29	B. Leaman	BLL4 - Replace custom lookups with managed versions (Deal obj)
 * 2017-02-21	B. Leaman	BLL5 - Commercial RO should use MCEO op-code -- no, just use IEN/IEU/IEO.
 * 2017-03-30	B. Leaman	BLL6 - Need to get the assigned RO number before creating lines         
 * 2017-04-19	S.Travarca  MTEK - Email new user group when negative quantity found           
 * 2017-05-18	B. Leaman	BLL7 - Fix qty on concern line, don't email for qty=0.
 * 2017-09-18	B. Leaman	BLL8 IR-0016771 - Move MTEK to proposal process when ready for delivery.
 * 2019-07-22	B. Leaman	BLL9 W-000714 - Home Access production to use IHA labor type.
 */
public without sharing class CustomInvoice {
    public CustomInvoice() {}
    public string emailBody{ get; set; }
    
    public dealer__Service_Repair_Order__c createROFromDeal(dealer__Deal__c dealObject) {
        // Get Associated Creating User
        String invoiceName = 'RO#';

        // Get location infomration
        dealer__Dealer_Location__c location = [
        	select Id, Name, dealer__Company_Number__c, dealer__Service_Director__c, Primary_Service_Center__c, Primary_Service_Center__r.Id, Primary_Service_Center__r.dealer__Company_Number__c
        	from dealer__Dealer_Location__c 
        	where Id =:dealObject.dealer__Store_Location__c 
        	limit 1
        ];

        // Get service vehicle record
        dealer__Service_Vehicle__c sv = null;  // BLL1c
        // BLL1a begin - get service vehicle using reference field if possible
        if (dealObject.dealer__Service_Vehicle__c!=null) {	// BLL4c
        	sv = [Select Id from dealer__Service_Vehicle__c where Id=:dealObject.dealer__Service_Vehicle__c limit 1];	// BLL4c
        }
        if (sv==null && dealObject.dealer__Vehicle__c!=null) {
        	try { // BLL2a
        		sv = [Select Id from dealer__Service_Vehicle__c where dealer__Sales_Inventory__c=:dealObject.dealer__Vehicle__c limit 1];
        	} catch(Exception e) {/* No service vehicle attached to inventory vehicle */} // BLL2a
        }
        // BLL1a end
        if (sv==null && !String.isBlank(dealObject.dealer__VIN__c)) {  // BLL1a - only if still need service veh and VIN is not missing
        	try {  // BLL2a
           		sv = [Select Id from dealer__Service_Vehicle__c where dealer__VIN__c =:dealObject.dealer__VIN__c limit 1];
        	} catch(Exception e) {/* no service vehicle matching VIN */}  // BLL2a
        } // BLL1a 
        
        // Instantiate the RO  
        dealer__Service_Repair_Order__c ro = new dealer__Service_Repair_Order__c(); 
        
        // BLL3d 
        //dealer__FixedOperationsSettings__c fixedOpsSettings = dealer__FixedOperationsSettings__c.getOrgDefaults();
        //ro.dealer__RO_Number__c = String.valueOf(fixedOpsSettings.dealer__Repair_Order_Index__c.setScale(0)); //JVK2

        //// Check to see if the index is in alignment
        //dealer__Service_Repair_Order__c[] roIndexCheck = [Select Id from dealer__Service_Repair_Order__c where dealer__RO_Number__c=:ro.dealer__RO_Number__c limit 1];
        //if(roIndexCheck.size()>0) {
        //    fixedOpsSettings.dealer__Repair_Order_Index__c++;
        //    ro.dealer__RO_Number__c = String.valueOf(fixedOpsSettings.dealer__Repair_Order_Index__c.setScale(0));
        //}

        //try { //JVK3
        //    fixedOpsSettings.dealer__Repair_Order_Index__c++; //JVK2
        //    update fixedOpsSettings;
        //} Catch(DmlException e) {
        //    dealObject.addError('Unable to create the delivery repair order '+e.getMessage());
        //}
		// BLL3d end
		
        //ro.Name = 'RO#'+location.dealer__Company_Number__c+'-'; // BLL3c +ro.dealer__RO_Number__c;

        /* Work 000798 Begin */
        //If Primary Service Center of Location is null then get the fields of deal location for SRO field population
        if(location.Primary_Service_Center__c == null){
            ro.Name = 'RO#'+location.dealer__Company_Number__c+'-';		//BLL3c +ro.dealer__RO_Number__c;
            ro.dealer__Company_Number__c = location.dealer__Company_Number__c;
            ro.dealer__Company__c  = location.Id; //JVK1
        }
        //else take Primary Service Center field of Location lookup on deal for SRO fields
        else{
            ro.Name = 'RO#'+location.Primary_Service_Center__r.dealer__Company_Number__c+'-';	//BLL3c +ro.dealer__RO_Number__c;
            ro.dealer__Company_Number__c = location.Primary_Service_Center__r.dealer__Company_Number__c;
            ro.dealer__Company__c  = location.Primary_Service_Center__r.Id;        
        }
        /* Work 000798 End */

        if(dealObject.dealer__Mileage__c == null) { 
            dealObject.dealer__Mileage__c = 0;
        }
        ro.dealer__Create_Date_Time__c = Datetime.now();
        ro.dealer__Service_Advisor__c = location.dealer__Service_Director__c;
        if (sv!=null) {
            ro.dealer__Vehicle__c = sv.Id;
        }
        ro.dealer__Vehicle_Inventory__c = dealObject.dealer__Vehicle__c;
        ro.dealer__Mileage_In__c = dealObject.dealer__Mileage__c;
        ro.dealer__Customer__c = dealObject.dealer__Buyer__c;
        ro.dealer__RO_Number__c = ro.dealer__RO_Number__c;

        //RT1
        ro.Deal__c = dealObject.Id;
        // Add Service Vehicle Linking for Equipment Only


        System.debug(ro);
        try {

            insert ro;
            System.debug(Limits.getQueries());
            // BLL6a - Need RO Name & Number
            dealer__Service_Repair_Order__c newro = [select Id, Name, dealer__RO_Number__c from dealer__Service_Repair_Order__c where id=:ro.Id];
            ro.Name = newro.Name;
            ro.dealer__RO_Number__c = newro.dealer__RO_Number__c;
            // BLL6a end
            createLines(ro, dealObject);

        } catch(DmlException e) {
            dealObject.addError('Unable to create the delivery repair order '+e.getMessage());
        }   



        // Update the Proposal
        try {
            dealObject.dealer__DeliveryRepairOrder__c = ro.Id;	// BLL4c

        } Catch(DmlException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to update proposal with RO# '+ro.Name));
            return null;
        }

        return ro;
    }


    // JVK1 - Moved to seperate method so we can re-create lines if necessary
    public Boolean createLines(dealer__Service_Repair_Order__c ro, dealer__Deal__c dealObject) {
		// BLL5a - not needed - always use IEx
		//Map<String, Schema.RecordTypeInfo> DealRcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();
		//Schema.RecordTypeInfo CommRtInfo = DealRcdTypes.get('Commercial');
		//Id commRtId = CommRtInfo!=null ? CommRtInfo.getRecordTypeId() : null;
		//boolean Commercial = dealObject.RecordTypeId==CommRtId;
		// BLL5a end

        // Delete Lines if they exists.
        if(ro.Id==null) {
            dealObject.addError('Unable to add job lines, the repair order ID is missing');
        }
        
        dealer__Service_Job__c[] jobLines = [Select Id, dealer__Line_Total__c from dealer__Service_Job__c where dealer__Service_Repair_Order__c=:ro.Id limit 500];
        if(jobLines.size()>0) {
            try {
                for(dealer__Service_Job__c j : jobLines) {
                    if(j.dealer__Line_Total__c != null && j.dealer__Line_Total__c > 0) {
                        dealObject.addError('Unable to remove existing job lines, this repair has dollars associated with the job lines.');
                    }
                }                
                delete jobLines;
            } catch(DmlException d) {
                dealObject.addError('Failed to remove existing job lines. '+d.getMessage());
            }
        }

        // Create Job Lines based on the Additional Equipment Items
        List<dealer__After_Market__c> lines = [
        	SELECT Id, Name, dealer__Car_Deal__c, dealer__Company_Number__c, dealer__Cost__c, 
        		dealer__Description__c, dealer__Labor_Sale__c, dealer__List_Price__c, 
        		dealer__Parts_Kit__c, dealer__Parts_Kit__r.Name, dealer__Part__c, dealer__Part__r.Name,  
        		dealer__Parts_Sale__c, dealer__Sale_Price__c, dealer__Vendor__c, Labor_Hours__c, Taxable__c, 
        		Gross__c, dealer__Quantity__c, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById 
        	FROM dealer__After_Market__c 
        	where dealer__Car_Deal__c=:dealObject.Id 
        	limit 500
        ];  

        // Get Vehicle Data
        dealer__Deal__c dl = [SELECT Id, Name, dealer__Stock_Number__c, dealer__Deal_Type__c, dealer__NUO__c, dealer__Vehicle__r.dealer__NUO__c FROM dealer__Deal__c where Id=:dealObject.Id];
        // Get Default Op Code
        dealer__StandardOpCode__c[] sop = [Select Id, Name from dealer__StandardOpCode__c where Name = '99PROD' limit 1];
        // Get NUO Payment Methods
        // BLL5d
        //ServicePaymentType__c ieo = [Select Id from ServicePaymentType__c where Name = 'IEO'];
        //ServicePaymentType__c ieu = [Select Id from ServicePaymentType__c where Name = 'IEU'];
        //ServicePaymentType__c ien = [Select Id from ServicePaymentType__c where Name = 'IEN'];
        // BLL5d end
        // BLL5a
        Map<String,Id> sptmap = new Map<String,Id>();
        // BLL9
		//for(ServicePaymentType__c s : [select Id, Name from ServicePaymentType__c where Name in ('IEO','IEU','IEN','MCEO')]) {
        for(ServicePaymentType__c s : [select Id, Name from ServicePaymentType__c where Name in ('IEO','IEU','IEN','MCEO','IHA')]) {
		// BLL9 end
        	sptmap.put(s.Name,s.Id);
        }
        // BLL5a end

        List<dealer__Service_Job__c> jLines = new List<dealer__Service_Job__c>();
    	
        emailBody = ro.Name + ' for Proposal ' + dl.Name + ' is removing parts from Stock #' + dl.dealer__Stock_Number__c + ': \n';
		//BLL8d Boolean sndEmail = false; //MTEK - email flag     
        Integer i = 1;
        for(dealer__After_Market__c a : lines) {
            dealer__Service_Job__c newLine = new dealer__Service_Job__c();
            newLine.dealer__Service_Repair_Order__c = ro.Id;
            newLine.Name = ro.Name+'-'+i;
            newLine.dealer__Line_Number__c=i;
            newLine.dealer__Service_Type__c='MR';
            newLine.dealer__Labor_Type__c='I';
            //newLine.dealer__CustomerConcern__c = a.dealer__Description__c;  // Add the suggested hours
            
			//MTEK - More detailed Concerns and email body when qty -1
			//BLL7d newLine.dealer__CustomerConcern__c = i + ' ' + a.dealer__Description__c;
			newLine.dealer__CustomerConcern__c = a.dealer__Description__c;
			if (a.dealer__Parts_Kit__c!=null) newLine.dealer__CustomerConcern__c += ' (' + a.dealer__Parts_Kit__r.Name + ')';
			if (a.dealer__Part__c!=null) newLine.dealer__CustomerConcern__c += ' (' + a.dealer__Part__r.Name + ')';
			// BLL7a
			if (a.dealer__Quantity__c>1 || a.dealer__Quantity__c<0) newLine.dealer__CustomerConcern__c = 'Qty ' + String.valueOf(Math.abs(a.dealer__Quantity__c)) + ' - ' + newLine.dealer__CustomerConcern__c;
			if (a.dealer__Quantity__c<0) newLine.dealer__CustomerConcern__c = 'Remove ' + newLine.dealer__CustomerConcern__c;
			// BLL7a end
            //BLL8d if(a.dealer__Quantity__c<0){	// BLL7c was < 1 (2017-06-06)
            //BLL8d     //BLL7d newLine.dealer__CustomerConcern__c = 'Remove ' + a.dealer__Quantity__c + ': ' + a.dealer__Description__c + '.';
            //BLL8d     //Get proposal to provide information for email 
			//BLL8d 	emailBody += 'Qty:' + a.dealer__Quantity__c + ' Part Name: ' + a.Name + ' Dealer List Price ' + a.dealer__Sale_Price__c  + '. \n';
            //BLL8d     sndEmail = true;
            //BLL8d }
            //MTEK
            
            if(a.Labor_Hours__c != null) {
                newLine.dealer__CustomerConcern__c = newLine.dealer__CustomerConcern__c + ' Estimated Service Hours : ' +a.Labor_Hours__c;
            }


            if(sop.size()>0) {
                newLine.dealer__Standard_Operation_Code__c = sop[0].Id;
                newLine.dealer__Op_Code__c = sop[0].Name;
            }

            if(dl.dealer__Vehicle__r.dealer__NUO__c != null && dl.dealer__Vehicle__r.dealer__NUO__c =='U') newLine.Payment_Method__c = sptmap.get('IEU');	//BLL5c ieu.Id;

            if(dl.dealer__Vehicle__r.dealer__NUO__c != null && dl.dealer__Vehicle__r.dealer__NUO__c =='N')  newLine.Payment_Method__c = sptmap.get('IEN');	//BLL5c ien.Id;

            if(dl.dealer__Deal_Type__c!=null && dl.dealer__Deal_Type__c.startsWith('Equipment')) newLine.Payment_Method__c = sptmap.get('IEO');	//BLL5c ieo.Id;

			// BLL9
            if(dl.dealer__Deal_Type__c!=null && dl.dealer__Deal_Type__c=='Home Access' && sptmap.containsKey('IHA')) newLine.Payment_Method__c = sptmap.get('IHA');	//BLL5c ieo.Id;
			// BLL9

            // BLL5a - not needed, always use IEx
            //if (Commercial) newLine.Payment_Method__c = sptmap.get('MCEO');
            // BLL5a end
            
            // JVK4
            if(newLine.Payment_Method__c==null) newLine.Payment_Method__c = sptmap.get('IEO');	//BLL5c ieo.Id;

            // add support for New (IEN), Used (IEU), Equipment Only (IEO)

            
            jLines.add(newLine);

            i++;
        }   

        if(jLines.size()>0) {
            try {
                insert jLines;
                //BLL8d if(sndEmail) sendEmailConfirmation(ro.Name);
                return true;
            } catch (DmlException e) {
                dealObject.addError('Unable to create the delivery repair order job lines '+e);
            }
        } 

        return false;   
    }
    
    //MTEK - email group when qty < 0
    //BLL8d private void sendEmailConfirmation(String roname) {
	//BLL8d 	//get email group
	//BLL8d 	Set<String> userIds = new Set<String>();
	//BLL8d 	List<String> emailGroup = new List<String>();
    //BLL8d     List<Group> g = [Select Id, (select userOrGroupId from groupMembers) FROM group WHERE Name = 'Part Removal Notification'];
	//BLL8d 
	//BLL8d 	// group members up to second level
    //BLL8d     Set<Id> groupIds = new Set<Id>();
    //BLL8d     if (g.size()>0) {
    //BLL8d     	groupIds.add(g[0].Id);
    //BLL8d     	for(GroupMember gm : g[0].groupMembers) {
    //BLL8d     		if (Schema.Group.SObjectType == gm.userOrGroupId.getSObjectType()) groupIds.add(gm.userOrGroupId);
    //BLL8d     	}
    //BLL8d 	}
	//BLL8d 	List<GroupMember> gms = [select Id, userOrGroupId from GroupMember where GroupId in :groupIds];
    //BLL8d     for(GroupMember gm : gms) userIds.add(gm.userOrGroupId);
    //BLL8d     
    //BLL8d     User[] usr = [Select email FROM user WHERE id IN :userIds];
    //BLL8d     for(User u: usr) emailGroup.add(u.email);
    //BLL8d     
    //BLL8d     Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
    //BLL8d     Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    //BLL8d     mail.setToAddresses(emailGroup);
    //BLL8d     Organization org = [select Id, isSandbox from Organization limit 1];
    //BLL8d     if (org.isSandbox) emailBody = 'Sandbox NOT sending to: ' + String.join(emailGroup,', ') + '\n\n' + emailBody;
    //BLL8d     if (org.isSandbox) mail.setToAddresses(new List<String>{UserInfo.getUserEmail()});
    //BLL8d     mail.setSubject(roname + ' to remove parts Alert');
    //BLL8d     mail.setPlainTextBody(emailBody);
    //BLL8d     if (emailGroup.size()>0) Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    //BLL8d     
    //BLL8d }
    //MTEK
}