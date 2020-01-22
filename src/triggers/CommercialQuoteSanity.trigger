/**
 * CommercialQuoteSanity
 * Tested by: CQEXT_Test
 * 
 *	2016-02-21	B. Leaman	BLL1 - Won commercial quote can mark opportunity *or* solution opportunity (sales up) as won.
 *							Also mark vehicle as Sold Not Delivered or Delivered, based on comm.quote status changes.
 *	2016-03-02	B. Leaman	BLL2 - Create RO when commercial quote for an inventory vehicle moves to the production stage.
 *	2016-04-15	B. Leaman	BLL3 IT#23367 - Post commercial quotes (create posting entries)
 *	2016-04-15	B. Leaman	BLL4 IT#23367 - Protect posted commercial quote from updates that affect dollars.
 *	2016-06-24	B. Leaman	BLL5 - Support for ability to recalc GP and commission on update, but don't bother if it's
 *							an interactive screen field update because the screen will do that for all affected fields
 *							already (and we don't want to start displaying on-screen message about GP changing if they just did it.)
 *	2016-07-18	B. Leaman	BLL6 - Change owner to match salesperson, if different.
 *	2017-03-01	B. Leaman	BLL7 - fix for old quote status=null.
 *	2017-03-07	B. Leaman	BLL8 - administrative update flag for fixing posted quotes.
 */
trigger CommercialQuoteSanity on CommercialQuote__c (before insert, before update, after insert, after update) {
	
	if(Trigger.isBefore) {
		for(CommercialQuote__c c : Trigger.new) {
			// Ensure values exist (replace null with defaults) and numbers are properly rounded!
			if(c.Chassis_QTY__c==null) { c.Chassis_QTY__c=0; }
			if(c.Commercial_Rebate__c == null ) { c.Commercial_Rebate__c = 0; }
			if(c.Commission_Rate__c==null) { c.Commission_Rate__c = 0.2; }
			if(c.Chassis_Cost__c!=null) { c.Chassis_Cost__c = c.Chassis_Cost__c.setScale(2, System.RoundingMode.HALF_UP); } else { c.Chassis_Cost__c = 0; }
			if(c.Chassis_Price__c!=null) { c.Chassis_Price__c = c.Chassis_Price__c.setScale(2, System.RoundingMode.HALF_UP); } else { c.Chassis_Price__c = 0; }
			if(c.Dealer_document_fee_temp_tag__c!=null) { c.Dealer_document_fee_temp_tag__c = c.Dealer_document_fee_temp_tag__c.setScale(2, System.RoundingMode.HALF_UP); }
			if(c.Commercial_rebate__c!=null) { c.Commercial_rebate__c = c.Commercial_rebate__c.setScale(2, System.RoundingMode.HALF_UP); }
			if(c.Mobility_rebate__c!=null) { c.Mobility_rebate__c = c.Mobility_rebate__c.setScale(2, System.RoundingMode.HALF_UP); }
			if(c.Additional_Ford_Rebate_Or_Special_Financ__c!=null) { c.Additional_Ford_Rebate_Or_Special_Financ__c = c.Additional_Ford_Rebate_Or_Special_Financ__c.setScale(2, System.RoundingMode.HALF_UP); }
			if(c.Government_Price_Concession__c!=null) { c.Government_Price_Concession__c = c.Government_Price_Concession__c.setScale(2, System.RoundingMode.HALF_UP); }
			if(c.Freight_Cost__c!=null) { c.Freight_Cost__c = c.Freight_Cost__c.setScale(2, System.RoundingMode.HALF_UP); } else { c.Freight_Cost__c = 0; }
			if(c.Freight_Amount__c!=null) { c.Freight_Amount__c = c.Freight_Amount__c.setScale(2, System.RoundingMode.HALF_UP); } else { c.Freight_Amount__c = 0; }
			if(c.Tax__c!=null) { c.Tax__c = c.Tax__c.setScale(2, System.RoundingMode.HALF_UP); }
			if(c.Total__c!=null) { c.Total__c = c.Total__c.setScale(2, System.RoundingMode.HALF_UP); }
			if(c.Total_After_Discounts_Rebates__c!=null) { c.Total_After_Discounts_Rebates__c = c.Total_After_Discounts_Rebates__c.setScale(2, System.RoundingMode.HALF_UP); }
		
			//BLL5d Decimal chassis_price 	=	(c.Chassis_Price__c * c.Chassis_QTY__c);
			//BLL5d Decimal chassis_cost  	= 	(c.Chassis_Cost__c * c.Chassis_QTY__c);
			//BLL5d Decimal cost 			=	chassis_cost + c.Total_Options_Cost__c + c.Freight_Cost__c;
			//BLL5d Decimal price 			=	chassis_price + c.Total_Options_Price__c + c.Freight_Amount__c;
			//BLL5d Decimal gross 			=	(price - cost) - c.Commercial_Rebate__c;
			//BLL5d Decimal commission		=	(gross * (c.Commission_Rate__c / 100));

			//BLL5d c.Unit_Gross_Profit__c = (gross / c.Chassis_QTY__c);
			//BLL5d c.Total_Gross_Profit__c= gross;	
	
			if (c.Salesperson__c!=c.OwnerId && c.Salesperson__c!=null && !c.AdministrativeUpdate__c) c.OwnerId = c.Salesperson__c;	// BLL6a
	
		}	
	}

	if (Trigger.isBefore) {
		// Move gross & commission calcs to external class
		CommercialQuoteProcess.RecalcGPandCommissionBulk(Trigger.new, Trigger.oldMap);
	}


	// BLL4a - protect posted quotes from updates
	// Just lastmodified* fields means an empty update (just to fire the trigger) & TaxPostDT/TaxCommitDT
	MW_TriggerControls__c protectPostedQuote = MW_TriggerControls__c.getInstance('ProtectPostedQuote');
	if(protectPostedQuote == null || protectPostedQuote.Enabled__c) { 
		Set<String> allowedfieldupdates = new Set<String>{'lastmodifieddate','lastmodifiedbyid',
			'delivery_date__c', 'ownerid'
		};
		if (Trigger.isBefore && Trigger.isUpdate) {
			for(CommercialQuote__c cq : Trigger.new) {
				CommercialQuote__c oldcq = Trigger.oldMap!=null ? Trigger.oldMap.get(cq.Id) : null;
				if (oldcq!=null && oldcq.Status__c!=null && (oldcq.Status__c.contains('Booked') || oldcq.Status__c.contains('Posted') || oldcq.Status__c.contains('Received'))) {	// BLL7c, BLL8c
					if (cq.Status__c!=null && (cq.Status__c.contains('Booked') || cq.Status__c.contains('Posted') || cq.Status__c.contains('Received'))) {	// BLL8c
						// allow if it's only updating certain fields
						if (!cq.AdministrativeUpdate__c && !SObjectChangedFields.OnlyAllowedFieldsChanged(cq, oldcq, allowedfieldupdates)) {	// BLL8c
							cq.addError('Posted Commercial Quotes cannot be edited (' 
								+ JSON.serialize(SObjectChangedFields.getChangedFieldList(cq, oldcq)) +')');
						}
					}
				}
			}
		}
	}
	// BLL4a end

	// BLL1a
	MW_TriggerControls__c wonCommercialQuote = MW_TriggerControls__c.getInstance('WonCommercialQuote');
   	if (wonCommercialQuote==null || wonCommercialQuote.Enabled__c) {
		if (Trigger.isAfter && Trigger.isUpdate) CommercialQuoteProcess.WonCommercialQuote(Trigger.new, Trigger.oldMap);
		if (Trigger.isBefore && Trigger.isUpdate) CommercialQuoteProcess.AutoCreateDeliveryRO(Trigger.new, Trigger.oldMap);	// BLL2a
		if (Trigger.isAfter && Trigger.isUpdate) CommercialQuoteProcess.WonCommercialVehicle(Trigger.new, Trigger.oldMap);
		if (Trigger.isBefore && Trigger.isUpdate) CommercialQuoteProcess.DeliveredCommercialVehicle(Trigger.new, Trigger.oldMap);
		if (Trigger.isAfter && Trigger.isUpdate) CommercialQuoteProcess.CreatePostingEntry(Trigger.new, Trigger.oldMap);
	}
	// BLL1a end

	// BLL1d logic moved to separate class and enhanced
    // Mark opportunity won for won commercial quotes
    //if (Trigger.isAfter) {
    //    List<Opportunity> oppupdates = new List<Opportunity>();
    //    List<Id> wonopps = new List<Id>();
    //    // Build list of won quotes
    //    for(CommercialQuote__c cq : Trigger.new) {
    //    	if (Trigger.isUpdate) {
    //           CommercialQuote__c oldcq = Trigger.oldMap.get(cq.Id);
    //           if (cq.Status__c.equals('Won') && !oldcq.Status__c.equals(cq.Status__c)) {
    //               wonopps.add(cq.Opportunity__c);
    //           }
    //    	} else if (Trigger.isInsert && cq.Status__c.equals('Won')) {
    //            wonopps.add(cq.Opportunity__c);
    //    	}
    //    }
    //    // Get opportunities not already won for won quotes
    //    oppupdates = [select Id, Name, StageName
    //                  from Opportunity 
    //                  where Id in :wonopps and StageName!='Won'];
    //    // Change opportunity to won
    //    for(Opportunity o:oppupdates) {
    //        o.StageName='Won';
    //    }  
    //    // Effect the updates to opportunities
    //    if (oppupdates.size()>0) {
    //        update oppupdates;
    //    }
    //}  
    //BLL1d
    
    // BLL8a
    if (Trigger.isBefore) for(CommercialQuote__c c : Trigger.new) c.AdministrativeUpdate__c = false; 
    
}