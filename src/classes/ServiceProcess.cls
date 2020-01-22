/**
 * ServiceProcess
 * Tested by: ServiceRepairOrder2_TC
 * Date: 2019-12-17
 * Programmer: Bryan Leaman
 * Project: 
 *
 * Coverage:
 *	2019-12-17	93%	(84/90)
 *
 * Modifications: 
 *	2019-12-27	BLL3	W-000788 Force book time = actual time on job lines.
 *	2020-01-02	BLL4	W-000788 attempt to allow corrections to book time on posted ROs
 *
**/
public with sharing class ServiceProcess {

	private static Map<Id,dealer__Service_Job__c> JobLines = new Map<Id,dealer__Service_Job__c>();

	private static Map<String, Decimal> slrdMap = new Map<String, Decimal>();
	private static Set<Id> spmIds = new Set<Id>();
	private static Set<Id> locIds = new Set<Id>();

	private static Map<Id, dealer__StandardOpCode__c> OpCodeMap = new Map<Id, dealer__StandardOpCode__c>();
	private static Map<String, ServicePaymentType__c> SptMap = new Map<String, ServicePaymentType__c>();

    private static Map<Id,dealer__Service_Repair_Order__c> SroMap = new Map<Id,dealer__Service_Repair_Order__c>();
	private static List<dealer__Service_Job__c> ROJobLines = new List<dealer__Service_Job__c>();
	public static boolean ReloadROLines = false;
	private static Set<Id> PartInvJobLines = new Set<Id>();
	private static List<dealer__Parts_Invoice_Line__c> PartInvLines = new List<dealer__Parts_Invoice_Line__c>();
	private static Set<String> commEquipPmtMthds = new Set<String>{'MCEO'};
	private static Set<String> getReadyPmtMthds = new Set<String>{'GRNV','GRUV'};
	private static Set<Id> getReadypmtIds = null;
	private static Set<Id> commEquipPmtIds = null;

	// RetrieveJobLines - to get related RO company (store) and pay method info
	public static void RetrieveJobLines(Set<Id> jlids) {
		if (ReloadROLines || (jlids.size()>0 && !JobLines.keySet().containsAll(jlids))) {
			jlids.addAll(JobLines.keySet());
			JobLines = new Map<Id,dealer__Service_Job__c>([
				select Id, Name, 
					Payment_Method__c, Payment_Method__r.Default_Labor_Rate__c,
					dealer__Service_Repair_Order__c, dealer__Service_Repair_Order__r.dealer__Company__c, dealer__Service_Repair_Order__r.dealer__Company__r.LaborBookEqualsActualTime__c,
					(select Id, dealer__Actual_Time_Entry__c from dealer__Technician_Job_Times__r)
				from dealer__Service_Job__c
				where Id in :jlids
			]);
		}
		ReloadROLines = false;
	}


	// RetrieveLaborRateDefaults
	public static void RetrieveLaborRateDefaults(Set<Id> spms, Set<Id> locs) {

		// only run soql if there are new Ids needed
		if (spms.size()>0 && locs.size()>0 
			&& (!spmIds.containsAll(spms) || !locIds.containsAll(locs))) { 

			// build needed service payment method & location combo keys
			spmIds.addAll(spms);
			locIds.addAll(locs);

			// retrieve all labor rate info & build spm + loc key to info
			for(ServicePaymentType__c spt : [
				SELECT Id, Default_Labor_Rate__c, 
					( SELECT Location__c, Labor_Rate__c 
					  FROM LaborRateDefaults__r 
					  WHERE Location__c in :locIds
					)
				FROM ServicePaymentType__c 
				WHERE Id in :spmIds
			]) {
				// Pay method default labor rate
				slrdMap.put(spt.Id, spt.Default_Labor_Rate__c);
				// Store override labor rate
				for(ServiceLaborRateDefaults__c slrd : spt.LaborRateDefaults__r) {
					slrdMap.put(spt.Id + ':' + slrd.Location__c, slrd.Labor_Rate__c);
				}
			}
		}
		System.debug(slrdMap);
	}


	// LaborCalculations
	public static void LaborCalculations(List<dealer__Service_Job__c> newlist, Map<Id,dealer__Service_Job__c> oldmap) {
		System.debug('ServiceProcess.LaborCalculations');
		Set<Id> jlIds = new Set<Id>();
		Set<Id> spms = new Set<Id>();
		Set<Id> locs = new Set<Id>();

		for(dealer__Service_Job__c jl : newlist) {
			if (jl.Id!=null) jlIds.add(jl.Id);
			if (jl.Payment_Method__c!=null) spms.add(jl.Payment_Method__c);
		}
		ServiceProcess.RetrieveJobLines(jlIds);
		for(dealer__Service_Job__c jl : JobLines.values()) {
			if (jl.dealer__Service_Repair_Order__r.dealer__Company__c!=null) locs.add(jl.dealer__Service_Repair_Order__r.dealer__Company__c);
		}
		RetrieveLaborRateDefaults(spms, locs);
		// BLL3
		// force book time = actual time depending on location settings
		Map<Id,Decimal> actualTimeMap =  new Map<Id,Decimal>();
		for(dealer__Service_Job__c jl : JobLines.values()) {
			Decimal hrs = 0;
			for(dealer__Technician_Job_Time__c tt : jl.dealer__Technician_Job_Times__r) {
				if (tt.dealer__Actual_Time_Entry__c!=null) hrs += tt.dealer__Actual_Time_Entry__c;
			}
			actualTimeMap.put(jl.Id, hrs);
		}
		// BLL3 end

		for (dealer__Service_Job__c jl : newlist) {
			System.debug(jl);
			dealer__Service_Job__c oldjob = oldMap!=null ? oldMap.get(jl.Id) : null;
			dealer__Service_Job__c jline = JobLines.get(jl.Id);
			// BLL3
			if (jline!=null && jline.dealer__Service_Repair_Order__r.dealer__Company__r.LaborBookEqualsActualTime__c) {
				Decimal actualHrs = actualTimeMap.get(jl.Id);
				if (actualHrs!=null) jl.dealer__Book_Time__c = actualHrs;
			}
			// BLL3 end

			// BLL4 - only if not an admin update of book hours only
			if (!jl.CorrectBookTimeOnly__c) {
			// BLL4 end
				if (jline != null && jl.dealer__Book_Time__c!=null
					&& (oldjob==null || jl.dealer__Labor_Charges__c==null || jl.dealer__Labor_Charges__c==0.0
					    || jl.Payment_Method__c!=oldjob.Payment_Method__c || jl.dealer__Book_Time__c!=oldjob.dealer__Book_Time__c)) {
					System.debug(jline);
					Decimal laborrate = slrdMap.get(jl.Payment_Method__c);
					System.debug(laborrate);
					String locRateKey = jl.Payment_Method__c + ':' + jline.dealer__Service_Repair_Order__r.dealer__Company__c;
					System.debug(locRateKey);
					System.debug(slrdMap.get(locRateKey));
					if (slrdMap.containsKey(locRateKey)) laborrate = slrdMap.get(locRateKey);
					System.debug(laborrate);
					if (laborrate!=null) {
						jl.dealer__Labor_Charges__c = jl.dealer__Book_Time__c * laborrate;
						System.debug(jl.dealer__Book_Time__c);
						jl.dealer__Labor_Charges__c = jl.dealer__Labor_Charges__c.setScale(2, System.RoundingMode.HALF_UP);
						System.debug(jl.dealer__Labor_Charges__c);
					}
				}
			// BLL4
			}
			jl.CorrectBookTimeOnly__c=false;
			// BLL4 end
			System.debug(jl);
		}
	}


	// RequireTechniciansOnCompleteLines
	public static void RequireTechniciansOnCompleteLines(List<dealer__Service_Job__c> newlist, Map<Id,dealer__Service_Job__c> oldMap) {
		Set<Id> sjobids = new Set<Id>();
		Set<Id> missingtechs = new Set<Id>();	
   		for(dealer__Service_Job__c jl : newlist) {
			if (jl.dealer__Stat__c=='Complete') sjobids.add(jl.Id);
		}
		List<dealer__Technician_Job_Time__c> techtime = new List<dealer__Technician_Job_Time__c>();
		if (sjobids.size()>0) techtime = [
  			select Id, Name, dealer__Service_Job_Line__c, dealer__Technician__c
  			from dealer__Technician_Job_Time__c 
  			where dealer__Service_Job_Line__c in :sjobids and dealer__Technician__c=null
  		];
  		for(dealer__Technician_Job_Time__c tjt : techtime) { 
  			System.debug(tjt.dealer__Service_Job_Line__c);
  			missingtechs.add(tjt.dealer__Service_Job_Line__c);
  		}
  		system.debug(missingtechs);
   		for(dealer__Service_Job__c jl : newlist) {
			dealer__Service_Job__c oldjl = oldMap!=null ? oldMap.get(jl.Id) : null;
			System.debug(jl.dealer__Stat__c);
			System.debug(jl.id);
   			if (jl.dealer__Stat__c=='Complete' && missingtechs.contains(jl.Id) 
   				&& oldjl!=null && oldjl.dealer__Stat__c!=jl.dealer__Stat__c) {
	   			jl.addError('Line ' + jl.Name + ' has labor without a technician');
			   }
   		}
	}


	// SetPartTotalForWarrAndInternal
	public static void SetPartTotalForWarrAndInternal(List<dealer__Service_Job__c> newlist) {
    	for(dealer__Service_Job__c jl : newlist) {
    	    if((jl.dealer__Labor_Type__c == 'W' || jl.dealer__Labor_Type__c =='I')
    	      	&& jl.dealer__Parts_Total__c != jl.dealer__Parts_Cost__c ) {
    	        	jl.dealer__Parts_Total__c = jl.dealer__Parts_Cost__c;
    	    }
    	}
	}

	// RetrieveStandardOpCodes
	public static void RetrieveStandardOpCodes(Set<Id> opids) {
		if (opids.size()>0 && !OpCodeMap.keySet().containsAll(opids)) {
	    	OpCodeMap = new Map<Id,dealer__StandardOpCode__c>([
				Select Id, Default_Payment_Method__c, dealer__Pay_Type__c 
				From dealer__StandardOpCode__c 
				where Id=:opIds limit 5000
			]);
		}
	}

	// RetrieveServicePaymentTypes
	public static void RetrieveServicePaymentTypes() {
	    if (SptMap.size()==0) {
			for(ServicePaymentType__c sp : [
	    		select Id, Name, Payment_Type__c 
	    		from ServicePaymentType__c
	    	]) {
	    	    SptMap.put(sp.Name, sp);
	    	}
		}
	}

	// DefaultPayMethodAndLaborType
	public static void DefaultPayMethodAndLaborType(List<dealer__Service_Job__c> newlist) {
	    Set<Id> opIds = new Set<Id>();
	    for(dealer__Service_Job__c j : newlist) {
	        // Get a List of Jobs without Payment Methods
	        if(j.Payment_Method__c == null && j.dealer__Standard_Operation_Code__c !=null) {
	            if (j.dealer__Standard_Operation_Code__c!=null) opIds.add(j.dealer__Standard_Operation_Code__c);	// BLL2c
	        }            
	    }

		ServiceProcess.RetrieveStandardOpCodes(opIds);
		ServiceProcess.RetrieveServicePaymentTypes();

		// Update job lines labor type and/or pay method
	    for(dealer__Service_Job__c jl : newlist) {
	        if(jl.Payment_Method__c == null && jl.dealer__Standard_Operation_Code__c !=null) {
	            if(OpCodeMap.get(jl.dealer__Standard_Operation_Code__c)!= null) {
	                // If Labor_Type__c == Name payment method, set to that method
	                if(SptMap.get(jl.dealer__Labor_Type__c)!=null) {
	                    jl.Payment_Method__c = SptMap.get(jl.dealer__Labor_Type__c).Id;
	                    if(jl.dealer__Labor_Type__c != 'C' && jl.dealer__Labor_Type__c != 'W' && jl.dealer__Labor_Type__c != 'I') {
	                        jl.dealer__Labor_Type__c = SptMap.get(jl.dealer__Labor_Type__c).Payment_Type__c;
	                    }
	                }
	                if(jl.Payment_Method__c == null && OpCodeMap.get(jl.dealer__Standard_Operation_Code__c).Default_Payment_Method__c !=null) {
	                    jl.Payment_Method__c = OpCodeMap.get(jl.dealer__Standard_Operation_Code__c).Default_Payment_Method__c;
	                    jl.dealer__Labor_Type__c = OpCodeMap.get(jl.dealer__Standard_Operation_Code__c).dealer__Pay_Type__c; 
	                }
	            }
	        }
	    }

	}


	// MapExtendedCauseToCause
	public static void MapExtendedCauseToCause(List<dealer__Service_Job__c> newlist) {
        for(dealer__Service_Job__c j : newlist) {
			// DR1 Sync Cause with with extended field
			if(j.dealer__CauseExtended__c !=null) {
				j.dealer__Cause__c = j.dealer__CauseExtended__c.abbreviate(250);
			}
		}
	}

	// RetrieveSroMapAndJobLines
	public static void RetrieveSroMapAndJobLines(Set<Id> roids) {
		if (SROMap==null) SROMap = new Map<Id, dealer__Service_Repair_Order__c>();
		if (ROJobLines==null) ROJobLines = new List<dealer__Service_Job__c>();
		if (ReloadROLines || (roids.size()>0 && !SROMap.keySet().containsAll(roids))) {
			roids.addAll(SROMap.keySet());
    	    SroMap = new Map<Id,dealer__Service_Repair_Order__c>([
				select Id, GetReady_RO__c, CommercialConversionEquip__c 
				from dealer__Service_Repair_Order__c 
				where Id in :roids
			]);
			ROJobLines = [
	    		select Id, Name, dealer__Service_Repair_Order__c, Payment_Method__c, Payment_Method__r.Name 
	    		from dealer__Service_Job__c 
		   		where dealer__Service_Repair_Order__c in :roIds 
	    	];
		}
		ReloadROLines = false;
	}


	// RetrievePmtMethodIds
	public static void RetrievePmtMethodIds() {
		Set<String> paymentMethods = new Set<String>();
		paymentMethods.addAll(getReadyPmtMthds);
		paymentMethods.addAll(commEquipPmtMthds);
		if(getReadyPmtIds == null || commEquipPmtIds == null) {
			getReadyPmtIds = new Set<Id>();
			commEquipPmtIds = new Set<Id>();
			for(ServicePaymentType__c spt : [
				select Name, Id 
				from ServicePaymentType__c
				where Name in :paymentMethods
			]) {
				if (getReadyPmtMthds.contains(spt.Name)) getReadyPmtIds.add(spt.Id);
				if (commEquipPmtMthds.contains(spt.Name)) commEquipPmtIds.add(spt.Id);
			}
		}

	}

	// SetGetReadyROFlags
	public static void SetGetReadyROFlags(List<dealer__Service_Job__c> newlist, Map<Id,dealer__Service_Job__c> oldMap) {
		System.debug('SetGetReadyROFlags');
	    // List of affected service repair order Ids (from service job lines)
	    Set<Id> sroIds = new Set<Id>(); 
		Set<Id> updatedJobIds = new Set<Id>();
	    // List of affected service repair orders
	    //List<dealer__Service_Repair_Order__c> sros = new List<dealer__Service_Repair_Order__c>();
	    // List of affected service repair orders that have a GRNV or GRUV line
	    Set<Id> getRdyIds = new Set<Id>();
	    Set<Id> commConvIds = new Set<Id>(); // BLL2a 
	    // List of service repair orders needing a change to the "getReady" flag	// BLL2c or commConv flag
	    List<dealer__Service_Repair_Order__c> updsros = new List<dealer__Service_Repair_Order__c>();

		// list of job ids being updated in this request
		if (newlist!=null) {
			for(dealer__Service_Job__c j : newlist) updatedJobIds.add(j.Id);
		}

		RetrievePmtMethodIds();
    	for (dealer__Service_Job__c j : (newlist!=null ? newlist : oldMap.values())) {
			//if (Trigger.isDelete || Trigger.isInsert) 
			sroIds.add(j.dealer__Service_Repair_Order__c);
			//if (Trigger.isUpdate && Trigger.oldMap.get(j.Id).Payment_Method__c!=j.Payment_Method__c) 
			//if (oldMap!=null && oldMap.get(j.Id).Payment_Method__c!=j.Payment_Method__c) sroIds.add(j.dealer__Service_Repair_Order__c);
			System.debug(j);
			if (commEquipPmtIds.contains(j.Payment_Method__c)) commConvIds.add(j.dealer__Service_Repair_Order__c);
			if (getReadyPmtIds.contains(j.Payment_Method__c)) getRdyIds.add(j.dealer__Service_Repair_Order__c);
    	}
		
    	// Build list of Service Repair Orders affected 
    	if (sroIds.size()>0) {
			RetrieveSROMapAndJobLines(sroIds);
    	    //sros = [select Id, GetReady_RO__c, CommercialConversionEquip__c from dealer__Service_Repair_Order__c where Id in :sroIds];
	    	// Build set of those service repair orders that have a GRNV or GRUV line
        	//for (dealer__Service_Job__c l : [
            //    select dealer__Service_Repair_Order__c, Payment_Method__r.Name	// BLL2c add Payment_Method__r.Name
            //    from dealer__Service_Job__c 
            //    where dealer__Service_Repair_Order__c in :sroIds 
            //    and Payment_Method__r.Name in :pmtMethodNames]) {	// BLL2c add MCEO
			for (dealer__Service_Job__c l : ROJobLines) {
				// Don't look at committed value for lines updated in this trigger!
				if (!updatedJobIds.contains(l.id)) {
					System.debug(l.Name + ':' + l.Payment_Method__r.Name);
					if (commEquipPmtIds.contains(l.Payment_Method__c)) commConvIds.add(l.dealer__Service_Repair_Order__c);
					if (getReadyPmtIds.contains(l.Payment_Method__c)) getRdyIds.add(l.dealer__Service_Repair_Order__c);
				}
        	}
	    }   
		System.debug(commConvIds);
		System.debug(getRdyIds);

	    // Update any SROs whose "getReady" flag needs to change
	    for (dealer__Service_Repair_Order__c sro : SroMap.values()) {
	    	boolean updateRO = false;
	    	if (sro.GetReady_RO__c==true && !getRdyIds.contains(sro.Id)) {
	    		sro.getReady_RO__c = false;
	    		updateRO = true;
	    		//BLL2d updsros.add(sro);
	    	} else if (sro.GetReady_RO__c==false && getRdyIds.contains(sro.Id)) {
	    		sro.getReady_RO__c = true;
	    		updateRO = true;
	    		//BLL2d updsros.add(sro);
	    	}
	    	// BLL2a
	    	if (sro.CommercialConversionEquip__c==true && !commConvIds.contains(sro.Id)) {
	    		sro.CommercialConversionEquip__c = false;
	    		updateRO = true;
	    	} else if (sro.CommercialConversionEquip__c==false && commConvIds.contains(sro.Id)) {
	    		sro.CommercialConversionEquip__c = true;
	    		updateRO = true;
	    	}
	    	if (updateRO) updsros.add(sro);
	    	// BLL2a end
	    } 
	    if (updsros.size()>0) {
	    	System.debug('Have ' + String.valueOf(updsros.size()) + ' ROs to update getready or commercialconversion flag');
			System.debug('DML Update->'+JSON.serialize(updsros));
			Database.update(updsros);	// BLL3a
	    }		
	}

	// RetrievePartInvoiceLines
	public static void RetrievePartInvoiceLines(Set<Id> jobids) {
		if (PartInvLines==null) PartInvLines = new List<dealer__Parts_Invoice_Line__c>();
		if (jobids.size()>0 && !PartInvJobLines.containsAll(jobids)) {
			jobids.addAll(PartInvJobLines);
			PartInvLines = [
				SELECT ID, dealer__Job_Line__c, dealer__Pay_Type__c 
				FROM dealer__Parts_Invoice_Line__c 
				WHERE dealer__Job_Line__c IN :jobids
			];
		}
	}

	// UpdatePayTypes
	public static void UpdatePayTypes(List<dealer__Service_Job__c> newlist) {
		System.debug('UpdatePayTypes');
        Map<Id, dealer__Service_Job__c> jobMap = new Map<Id, dealer__Service_Job__c>();
        for (dealer__Service_Job__c j : newlist)  jobMap.put(j.Id, j);
        System.debug(jobMap);

        // Get associated Parts Lines
		RetrievePartInvoiceLines(jobMap.keySet());
		//List<dealer__Parts_Invoice_Line__c> pils = [
		//	SELECT ID, dealer__Job_Line__c, dealer__Pay_Type__c 
		//	FROM dealer__Parts_Invoice_Line__c 
		//	WHERE dealer__Job_Line__c IN:jobMap.keySet()
		//];
        
        List<dealer__Parts_Invoice_Line__c> updateLines = new List<dealer__Parts_Invoice_Line__c>();
        if(!PartInvLines.isEmpty()) {
            for(dealer__Parts_Invoice_Line__c pil : PartInvLines) {
				dealer__Service_Job__c sj = jobMap.get(pil.dealer__Job_Line__c);
				System.debug(pil);
				System.debug(pil.dealer__Job_Line__c);
				System.debug(sj);
				if(sj!=null && pil.dealer__Pay_Type__c != sj.dealer__Labor_Type__c) {
                    updateLines.add(new dealer__Parts_Invoice_Line__c( Id=pil.Id,
                        dealer__Pay_Type__c=sj.dealer__Labor_Type__c
                    ));
                }   
            }
        }
        
		System.debug('DML Update->' + JSON.serialize(updateLines));
        if(!updateLines.isEmpty()) update updateLines;

	}
}