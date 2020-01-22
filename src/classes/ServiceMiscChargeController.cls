/**
	ServiceMiscChargeController
	Tested by: ServiceRepairOrder2_TC
	
	Coverage:
	2018-04-06	87% (61/70)
	
	Modification log: 
	2018-04-05	B. Leaman	BLL1 - populate custom GL account references when copying records.
	2018-10-31	B. Leaman	W-000477	BLL2 - copy technician job time creator and parts line fields (dealer__Technician_Job_Time_Creator__c, dealer__Parts_Line__c); 
	
**/
public class ServiceMiscChargeController {

// loadLocsForRows - build map of service job line id to location id
// location id and misc charge type are used to obtain GL accounts via the loadLocMiscChgs map
private static Map<Id,Id> loadLocsForRows(List<dealer__Service_Misc_Charge__c> newRows) {
    Map<Id,Id> JobLineMapToLoc = new Map<Id,Id>();
    Set<Id> jobids = new Set<Id>();
	for(dealer__Service_Misc_Charge__c row : newRows) {
		System.debug(row.dealer__Service_Job_Lines__c);
		jobids.add(row.dealer__Service_Job_Lines__c);
	}
	System.debug(jobids);
	for(dealer__Service_Job__c sj : [
		select Id, dealer__Service_Repair_Order__r.dealer__Company__c 
		from dealer__Service_Job__c
		where Id in :jobids
	]) {
		System.debug(sj.Id);
		System.debug(sj.dealer__Service_Repair_Order__r.dealer__Company__c);
		JobLineMapToLoc.put(sj.Id, sj.dealer__Service_Repair_Order__r.dealer__Company__c);
	}
	System.debug(JobLineMapToLoc);
	return JobLineMapToLoc;
}

// loadLocMiscChgs - builds a map of locationid + : + MiscChgType => Misc_Charge_Option__c sobject
// used to assign gl codes to custom misc charge lines object being created
private static Map<String,Misc_Charge_Option__c> loadLocMiscChgs(List<dealer__Service_Misc_Charge__c> newRows, Map<Id,Id> JobLineMapToLoc ) {
	Map<String,Misc_Charge_Option__c> locMiscChgs = new Map<String,Misc_Charge_Option__c>();
	Set<Id> locids = new Set<Id>();
	if (locMiscChgs==null || locMiscChgs.size()==0) {
		System.debug(JobLineMapToLoc);
		for(Misc_Charge_Option__c m : [
			select Id, Name, Location__c, General_Ledger_Account__c, General_Ledger_Acct_MW__c
			from Misc_Charge_Option__c
			where Location__c in :JobLineMapToLoc.values()
		]) {
			String key = m.Location__c + ':' + m.Name;
			System.debug(key);
			System.debug(m);
			locMiscChgs.put(key, m);
		}
	}
	System.debug(locMiscChgs);
	return locMiscChgs;
}
/* BLL1a */

    public static void insertNewRows(List<dealer__Service_Misc_Charge__c> newRows) {
	   	Map<Id,Id> JobLineMapToLoc = ServiceMiscChargeController.loadLocsForRows(newRows);	// BLL1a
    	Map<String,Misc_Charge_Option__c> locMiscChgs = ServiceMiscChargeController.loadLocMiscChgs(newRows, JobLineMapToLoc);	// BLL1a
    	
        List<ServiceMiscCharges__c > newRecords = new List<ServiceMiscCharges__c>();
        for(dealer__Service_Misc_Charge__c smc : newRows) {
        	System.debug(smc.dealer__Service_Job_Lines__c);
			Id locid = JobLineMapToLoc.get(smc.dealer__Service_Job_Lines__c);	// BLL1a
			String key = locid + ':' + smc.dealer__Type__c;
			System.debug(key);
			Misc_Charge_Option__c lm = locMiscChgs.get(key);	// BLL1a
			System.debug(lm); 

            newRecords.add(
            	new ServiceMiscCharges__c(
                	Service_Job_Line__c=smc.dealer__Service_Job_Lines__c,
                    Amount__c=smc.dealer__Amount__c,
                    Type__c=smc.dealer__Type__c,
                    Managed_Estimate_Id__c=smc.Id,
					// BLL2a
					Technician_Job_Time_Creator__c = smc.dealer__Technician_Job_Time_Creator__c,	// BLL2a
					Part_Line__c = smc.dealer__Parts_Line__c,	// BLL2a
					// BLL2a end
                    General_Ledger_Account__c=(lm!=null) ? lm.General_Ledger_Account__c : null,	// BLL1a
                    General_Ledger_Acct_MW__c=(lm!=null) ? lm.General_Ledger_Acct_MW__c : null	// BLL1a
                )
            );
        }
        
        try {
            insert newRecords;
        } Catch(DmlException e) {
			throw new SMCException(e.getMessage());
        }
    }
    
    public static void updateExistingRows(List<dealer__Service_Misc_Charge__c> updateRows) {
	   	Map<Id,Id> JobLineMapToLoc = ServiceMiscChargeController.loadLocsForRows(updateRows);	// BLL1a
    	Map<String,Misc_Charge_Option__c> locMiscChgs = ServiceMiscChargeController.loadLocMiscChgs(updateRows, JobLineMapToLoc);	// BLL1a

        List<ServiceMiscCharges__c> miscChargesToUpdate = new List<ServiceMiscCharges__c>();
        for(dealer__Service_Misc_Charge__c smc : updateRows) {
        	System.debug(smc.dealer__Service_Job_Lines__c);
			Id locid = JobLineMapToLoc.get(smc.dealer__Service_Job_Lines__c);	// BLL1a
			String key = locid + ':' + smc.dealer__Type__c;
			System.debug(key);
			Misc_Charge_Option__c lm = locMiscChgs.get(key);	// BLL1a
			System.debug(lm);
            miscChargesToUpdate.add(
            	new ServiceMiscCharges__c(
                	Service_Job_Line__c=smc.dealer__Service_Job_Lines__c,
                    Amount__c=smc.dealer__Amount__c,
                    Type__c=smc.dealer__Type__c,
                    Managed_Estimate_Id__c=smc.Id, 
					// BLL2a
					Technician_Job_Time_Creator__c = smc.dealer__Technician_Job_Time_Creator__c,	// BLL2a
					Part_Line__c = smc.dealer__Parts_Line__c,	// BLL2a
					// BLL2a end
                    General_Ledger_Account__c=(lm!=null) ? lm.General_Ledger_Account__c : null,	// BLL1a
                    General_Ledger_Acct_MW__c=(lm!=null) ? lm.General_Ledger_Acct_MW__c : null	// BLL1a
                )
            );            
        }
        
        try {
            upsert miscChargesToUpdate Managed_Estimate_Id__c;
        } Catch(DmlException e) {
			throw new SMCException(e.getMessage());
        }
    }
    
    public static void deleteRemovedRows(List<dealer__Service_Misc_Charge__c> remRows) {
        Set<String> deleteIds = new Set<String>();
        for(dealer__Service_Misc_Charge__c smc : remRows) {
            deleteIds.add(String.valueOf(smc.Id));
        }
        
        List<ServiceMiscCharges__c> chargesToRemove = [SELECT Id FROM ServiceMiscCharges__c WHERE Managed_Estimate_Id__c IN:deleteIds];
        
        if(!chargesToRemove.isEmpty()){
            try {
                delete chargesToRemove;
            } Catch(DmlException e) {
				throw new SMCException(e.getMessage());
        	}
        }
    }

	// BLL2
	public static void LinkMiscChgToCreator(List<dealer__Service_Misc_Charge__c> newRows) {
		Map<Id,Id> eslCreatorMap = new Map<Id,Id>();
		Set<Id> sublineIds = new Set<Id>();
		Set<Id> estimateIds = new Set<Id>();

		// build map of estimate sublines to part & labor line IDs
		Set<Id> joblineIds = new Set<Id>();
		for(dealer__Service_Misc_Charge__c smc : newRows) {
			joblineIds.add(smc.dealer__Service_Job_Lines__c);
			sublineIds.add(smc.dealer__Service_Estimate_Subline_Creator__c);
		}

		// get all service estimates (really should only be 1 in any insert operation)
		for(dealer__Service_Estimate_Subline__c sesl : [
			select Id, ServiceEstimateId__c, dealer__SystemGeneratedFor__c
			from dealer__Service_Estimate_SubLine__c
			where Id in :sublineIds
		]) {
			estimateIds.add(sesl.ServiceEstimateId__c);
			// also map misc charge sublines to their subline creator
			eslCreatorMap.put(sesl.Id, sesl.dealer__SystemGeneratedFor__c);
		}

		// get list of parts & labor on job lines
		List<dealer__Technician_Job_Time__c> techtimes = [
			select Id, dealer__Service_Estimate_Subline_Creator__c, dealer__Service_Job_Line__c
			from dealer__Technician_Job_Time__c
			where dealer__Service_Job_Line__c in :joblineIds
			   and dealer__Service_Estimate_Subline_Creator__c!=null
		];
		List<dealer__Parts_Invoice_Line__c> partslines = [
			select Id, dealer__Service_Estimate_Subline_Creator__c, dealer__Job_Line__c
			from dealer__Parts_Invoice_Line__c
			where dealer__Job_Line__c in :joblineIds
			   and dealer__Service_Estimate_Subline_Creator__c!=null
		];

		// build map estimate subline Id to corresponding part line or tech time
		for(dealer__Technician_Job_Time__c tt : techtimes) eslCreatorMap.put(tt.dealer__Service_Estimate_Subline_Creator__c, tt.Id);
		for(dealer__Parts_Invoice_Line__c pl : partslines) eslCreatorMap.put(pl.dealer__Service_Estimate_Subline_Creator__c, pl.Id);

		for(dealer__Service_Misc_Charge__c smc : newRows) {
			Id creator = eslCreatorMap.get(smc.dealer__Service_Estimate_Subline_Creator__c);
			// misc charge subline creator is the service estimate misc charge subline, need to get that subline's creator subline
			if (creator!=null && creator.getSObjectType()==dealer__Service_Estimate_Subline__c.SObjectType)
				creator = eslCreatorMap.get(creator);
			Id partCreator = null;
			Id laborCreator = null;
			if (creator!=null && creator.getSObjectType()==dealer__Parts_Invoice_Line__c.SObjectType)
				partCreator = creator;
			if (creator!=null && creator.getSObjectType()==dealer__Technician_Job_Time__c.SObjectType)
				laborCreator = creator;
			smc.dealer__Parts_Line__c = partCreator;
			smc.dealer__Technician_Job_Time_Creator__c = laborCreator;
		}

	}
	// BLL2 end

    public class SMCException Extends Exception {}
}