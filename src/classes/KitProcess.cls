/**
 * KitProcess
 * Tested by: KitProcess_TEST
 * Date: 2019-08-13
 * Programmer: Bryan Leaman
 * Project: W-000729
 *
 * Coverage:
 *	2019-08-19	100%	(101/101)
 *
 * Modifications: 
 *
**/
public with sharing class KitProcess {
 
	// uploadHelper - fill in category, manufacture, subcategory by name
	//-------------------------------------------------------------------
	public static void uploadHelper(List<dealer__Parts_Kit__c> newlist) {
   	
    	// Get list of unique id codes included in new records
    	Set<String> kitcatcodes = new Set<String>();
    	for (dealer__Parts_Kit__c k : newlist) {
    		if (!String.isBlank(k.Upload_Category__c) && !kitcatcodes.contains(k.Upload_Category__c)) {
    			kitcatcodes.add(k.Upload_Category__c);
    		}
    		if (!String.isBlank(k.Upload_Sub_Category__c) && !kitcatcodes.contains(k.Upload_Sub_Category__c)) {
    			kitcatcodes.add(k.upload_Sub_Category__c);
    		}
    		if (!String.isBlank(k.Upload_Manufacturer__c) && !kitcatcodes.contains(k.upload_Manufacturer__c)) {
    			kitcatcodes.add(k.Upload_Manufacturer__c);
    		}
    	}
    	System.debug(kitcatcodes);
    	
    	// Get map of external id code & salesforce id from Kit Categories
    	Map<String, Id> kcmap = new Map<String, Id>();
    	if (kitcatcodes.size()>0) {
	    	for (Kit_Category__c kc : [select Id, External_ID__c from Kit_Category__c 
	    	                           where External_ID__c in :kitcatcodes]) {
	    		kcmap.put(kc.External_ID__c, kc.Id);
	    		System.debug('Mapping ' + kc.External_ID__c + ' to id ' + kc.Id);
	    	}
    	}
    	    	
    	// Loop through new records and assign lookup references where the upload ids exist
    	for(dealer__Parts_Kit__c k : newlist) {
    		if (String.isBlank(k.Category__c) && !String.isBlank(k.Upload_Category__c)) {
    			k.Category__c = kcmap.get(k.Upload_Category__c);
    			k.Upload_Category__c = null;
    		}
    		if (String.isBlank(k.Sub_Category__c) && !String.isBlank(k.Upload_Sub_Category__c)) {
    			k.Sub_Category__c = kcmap.get(k.Upload_Sub_Category__c);
    			k.Upload_Sub_Category__c = null;
    		}
    		if (String.isBlank(k.Manufacturer__c) && !String.isBlank(k.Upload_Manufacturer__c)) {
    			k.Manufacturer__c = kcmap.get(k.Upload_Manufacturer__c);
    			k.Upload_Manufacturer__c = null;
    		}
    	}
        
	}

	// setCostAndPrice
	//------------------------------
	public static void setCostAndPrice(List<dealer__Parts_Kit__c> newlist) {
		for(dealer__Parts_Kit__c pk : newlist) {
			// Roll-Up fields fire the parent record to save
			if(pk.dealer__Item_Count__c>0) {
				pk.Parts_Cost__c = pk.dealer__Kit_Cost__c;
	            pk.dealer__Kit_Price__c = pk.dealer__Kit_Cost__c;//RT1
			}
			if(pk.CMC_Price__c==null) pk.CMC_Price__c=0;
		}
	}


	// ConversionKitRecordType
	public static void ConversionKitRecordType(List<dealer__Parts_Kit__c> newlist) {
		Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Parts_Kit__c.getRecordTypeInfosByName();
		Schema.RecordTypeInfo ConvKitInfo = RcdTypes.get('Conversion Package');
		Schema.RecordTypeInfo PartsKitInfo = RcdTypes.get('Parts Kit');
		Schema.RecordTypeInfo ChassisKitInfo = RcdTypes.get('Chassis');

		//Schema.RecordTypeInfo MasterKitInfo = RcdTypes.get('Master');
		//for(Schema.RecordTypeInfo rtinfo : RcdTypes.values()) {
		//	if (rtinfo.isMaster()) MasterKitInfo = rtinfo;
		//} 
		// Id DefaultRtId = MasterKitInfo.getRecordTypeId();

		Id ConvKitRtId = ConvKitInfo==null ? null : ConvKitInfo.getRecordTypeId();
		Id PartsKitRtId = PartsKitInfo==null ? null : PartsKitInfo.getRecordTypeId();
		Id ChassisKitRtId = ChassisKitInfo==null ? null : ChassisKitInfo.getRecordTypeId();

		// Build map of referenced kit categories (need to look for 'Conversion Package')
		Set<Id> CategoryIds = new Set<Id>();
		for(dealer__Parts_Kit__c pk : newlist) {
			if (pk.Category__c!=null) CategoryIds.add(pk.Category__c);
			if (pk.Sub_Category__c!=null) CategoryIds.add(pk.Sub_Category__c);
		} 
		Map<Id, Kit_Category__c> catMap = new Map<Id, Kit_Category__c>([
			select Id, Name, Conversion_Package__c, Chassis_Package__c
			from Kit_Category__c
			where Id in :CategoryIds
		]);

		// Re-assign any mis-matched record types based on selected category
		for(dealer__Parts_Kit__c pk : newlist) {
			Kit_Category__c cat = catMap.get(pk.Category__c);
			Kit_Category__c subcat = catMap.get(pk.Sub_Category__c);

			boolean isConversionPkg = (cat!=null && cat.Conversion_Package__c==true)
				|| (subcat!=null && subcat.Conversion_Package__c==true);
			boolean isChassisPkg = (cat!=null && cat.Chassis_Package__c==true)
				|| (subcat!=null && subcat.Chassis_Package__c==true);

			// NOT a conversion package, but has conversion record type
			if (!isConversionPkg && pk.RecordTypeId==ConvKitRtId) {
				pk.RecordTypeId=PartsKitRtId;
			}
			// IS a conversion package, but NOT a conversion record type
			if (isConversionPkg && pk.RecordTypeId!=ConvKitRtId) {
				pk.RecordTypeId=ConvKitRtId;
			}

			// NOT a chassis package, but has chassis record type
			if (!isChassisPkg && pk.RecordTypeId==ChassisKitRtId) {
				pk.RecordTypeId=PartsKitRtId;
			}
			// IS a chassis package, but NOT a chassis record type
			if (isChassisPkg && pk.RecordTypeId!=ChassisKitRtId) {
				pk.RecordTypeId=ChassisKitRtId;
			}

			// Clear out conversion fields if NOT a conversion kit
			if (!isConversionPkg) {
				KitProcess.clearConversionFields(pk);
			}
		}
	}

	// clearConversionFields
	public static void clearConversionFields(dealer__Parts_Kit__c pk) {
		pk.Conv_MFG__c = null;
		pk.MV_Ramp_Operation__c = null;
		pk.Ramp_Location__c = null;
		pk.MV_Ramp_Type__c = null;
		pk.Rubber_Flooring__c = false;
		pk.Conv_MFG_Code__c = null;

		pk.Dealer_Cost__c = null;
		pk.Freight__c = null;
		pk.NMEDA_Fee__c = null;
		pk.Prep_Title_Fee__c = null;
		pk.Front_End_Discount__c = null;
		pk.Back_End_Discount__c = null;
		// formula pk.Discount__c = null;
		// formula pk.MW_Cost__c = null;
		pk.CMC_Inventory_Pack__c = null;
		// formula pk.Inventory_Cost__c = null;
		pk.MarkUp__c = null;
	}


	// ConversionKitDefaultCalcs
	//-----------------------------
	public static void ConversionKitDefaultCalcs(List<dealer__Parts_Kit__c> newlist, Map<Id,dealer__Parts_Kit__c> oldmap) {

		Map<String, Conversion_Kit_Defaults__c> dftMap = Conversion_Kit_Defaults__c.getAll();
		Conversion_Kit_Defaults__c dft = dftMap.get('DEFAULT');
		if (dft==null) dft = new Conversion_Kit_Defaults__c();

		Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Parts_Kit__c.getRecordTypeInfosByName();
		Schema.RecordTypeInfo ConvKitInfo = RcdTypes.get('Conversion Package');
		Id ConvKitRtId = ConvKitInfo==null ? null : ConvKitInfo.getRecordTypeId();

		for(dealer__Parts_Kit__c pk : newlist) {
			if (pk.RecordTypeId==ConvKitRtId) {
				dealer__Parts_Kit__c oldpk = oldmap!=null ? oldmap.get(pk.Id) : null;
				Boolean changedMfg = oldpk==null || oldpk.Conv_MFG__c!=pk.Conv_MFG__c;

				// Default settings for automatic calcs
				Conversion_Kit_Defaults__c mfgdft = dftMap.get(pk.Conv_MFG__c);
				if (mfgdft==null) mfgdft = new Conversion_Kit_Defaults__c();
				Decimal dftFreight = mfgdft.Freight__c!=null ? mfgdft.Freight__c : dft.Freight__c;
				Decimal dftNMEDApct = mfgdft.NMEDA_Pct__c!=null ? mfgdft.NMEDA_Pct__c : dft.NMEDA_Pct__c;
				Decimal dftDiscountPct = mfgdft.Discount_Pct__c!=null ? mfgdft.Discount_Pct__c : dft.Discount_Pct__c;
				Decimal dftPack = mfgdft.Pack__c!=null ? mfgdft.Pack__c : dft.Pack__c;

				// Normalize fields used in calcs
				if (dftNMEDApct==null) dftNMEDApct = 0;
				if (dftDiscountPct==null) dftDiscountPct = 0;
				Decimal DealerCost = (pk.Dealer_Cost__c!=null) ? pk.Dealer_Cost__c : 0;
				Decimal Freight = (pk.Freight__c!=null) ? pk.Freight__c : 0;
				Decimal PrepTitleFee = (pk.Prep_Title_Fee__c!=null) ? pk.Prep_Title_Fee__c : 0;

				if (changedMfg || pk.Freight__c==null) pk.Freight__c = dftFreight;
				if (changedMfg || pk.NMEDA_Fee__c==null) 
					if (pk.Dealer_Cost__c!=null) pk.NMEDA_Fee__c = DealerCost * (dftNMEDApct/100);
				if (changedMfg || pk.Front_End_Discount__c==null) 
					if (pk.Dealer_Cost__c!=null) pk.Front_End_Discount__c = (DealerCost+Freight+PrepTitleFee) * (dftDiscountPct/100);
				if (changedMfg || pk.CMC_Inventory_Pack__c==null) pk.CMC_Inventory_Pack__c = dftPack;
			}
		}
	}


	//// EVALUATE:
	//// vehicle inventory sync custom fields to managed ones??? might depend 
	//// on whether we can add dependencies to managed picklists
	//public static void SyncFromManagedFields(List<dealer__Vehicle_Inventory__c> newlist) {
	//	for(dealer__Vehicle_Inventory__c v : newlist) {
	//		v.Conv_MFG__c = v.dealer__Conv_MFG__c;
	//		v.MV_Ranp_Operation__c = v.dealer__MV_Ranp_Operation__c; // [sic]
	//		v.Ramp_Location__c = v.dealer__Ramp_Location__c;
	//		v.MV_Ramp_Type__c = v.dealer__MV_Ramp_Type__c;
	//	}
	//}

}