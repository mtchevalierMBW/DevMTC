/**
 * RAISIN_Utility
 * Tested by: RAISIN_Utility_TEST
 * Date: Feb 12, 2018
 * Programmer: Bryan Leaman
 *
 * Coverage: 
 *	2018-02-15	85% (289/340)
 *	2018-08-23	85% (322/376)
 *
 * Modification log:
 *	2018-06-29	B. Leaman	Fix DATE_TIME_FORMAT to use 24-hour clock instead of 12-hour (HH instead of hh).
 *	2018-08-23	B. Leaman	BLL1 - default part to "New" (Used=false) if part type is empty.
 *	2018-10-18	B. Leaman	W-000461 BLL2	Reduce SOQL query count.
 *	2019-11-14	B. Leaman	W-000782 BLL3 - Only consider Equipment & Conversion proposals.
 **/
/** sample:
RAISIN_Utility r = new RAISIN_Utility();
String xml = r.getJobListXML(new List<Id>{'a2Mc0000001QCT5'});
System.debug(xml.replaceAll('>','>\n'));
**
Database.executeBatch(new RAISIN_Utility(),50);
**
RAISIN_Utility.ScheduleMe();
 **/
global with sharing class RAISIN_Utility implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

	private transient XmlStreamWriter xml;

	global List<Id> specificRoIds;
	global List<dealer__Service_Repair_Order__c> updSROs;
	global String query;
	global boolean doUpdateSROs;
    global String errmsgs;
	global Map<String,String> MfgMap;
	// BLL3
	public static final List<String> DealTypesForDocutrack = new List<String>{
		'Chassis/Conversion', 'Equipment Only',
		'Equipment Only Sale', 'Retail Vehicle Sale'
	};
	// BLL3
    public static final List<String> CRON_LIST = new List<String>{
    	'0 0 7-21 ? * MON-SAT *',		// 4 times per hour between 7 a.m. and 9 p.m. (EST) Mon-Sat
    	'0 15 7-21 ? * MON-SAT *',
    	'0 30 7-21 ? * MON-SAT *',
    	'0 45 7-21 ? * MON-SAT *'
    };
	
	global final String DATE_TIME_FORMAT = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\''; // UTC datetime: use formatGmt()!
	
	global final Map<String,String> LoweredFloorMfgIdMap = new Map<String,String>{
		'BraunAbility'=>'1', 'VMI'=>'2', 'IMS'=>'3', 'Vision'=>'4', 'Eldorado'=>'5', 
		'Nor-Cal'=>'6', 'Freedom Motors'=>'7', 'Rollx'=>'8', 'AMS'=>'9'};
	
	global final Map<String,String> VehicleTypeMap = new Map<String,String>{
		'Consumer'=>'1',
		'Commercial'=>'2',
		'Minivan'=>'3', 'Mini Van'=>'3',
		'Full Size Van'=>'4',
		'Pickup/SUV'=>'5', 'SUV'=>'5', 'Truck'=>'5', 
		'Other'=>'6',
		'Lowered Floor'=>'7', // ?
		'Raised Roof'=>'8',	// FS_Raised_Top__c!=null !=None
		'Raised Door'=>'9'	// ?
	};


	// RAISIN_Utility
	//---------------------------------------
	public RAISIN_Utility() {
		doUpdateSROs = true;
		errmsgs = '';
		MfgMap = new Map<String,String>();
		for(Account v : [select Id, Raisin_Mfg_Id__c, Parts_Prefix__c from Account where Parts_Prefix__c!=null and Raisin_Mfg_Id__c!=null]) 
			MfgMap.put(v.Parts_Prefix__c, v.Raisin_Mfg_Id__c);
		query = 'select Id, Name, Raisin_Last_Sent_DT__c, LastModifiedDate, Deal__c, Deal__r.dealer__Deal_Type__c '
			+ 'from dealer__Service_Repair_Order__c ' 
			+ 'where dealer__Company__c!=null and dealer__Company__r.Raisin_Id__c!=null '
			+ 'and dealer__Status__c != \'Void\' and dealer__Status__c!=\'Posted\' '
			+ 'and (Raisin_Needs_Update__c=true or RAISIN_Sent_Hash__c=null) and Deal__c!=null ';
		// BLL3
		query += ' and Deal__r.dealer__Deal_Type__c in (\'' + String.join(DealTypesForDocutrack, '\',\'') + '\') ';
		// BLL3
	}

	// Used to force an update of one or more ROs
	public void SendUpdateForJobIds(List<Id> jobIds) {
		specificRoIds  = new List<Id>();
		specificRoIds.addAll(jobIds);
		query = 'select Id, Name, Raisin_Last_Sent_DT__c, LastModifiedDate, Deal__c, Deal__r.dealer__Deal_Type__c '
			+ 'from dealer__Service_Repair_Order__c '
			+ 'where Id in :specificRoIds '
			+ 'and dealer__Company__c!=null and dealer__Company__r.Raisin_Id__c!=null ';
	}
	
	// CalculateRoHash - returns a hash used to determine if it changed meaningfully for Raisin
	// ------------------------------------------------------------
	public static String CalculateRoHash(dealer__Service_Repair_Order__c ro, List<dealer__Parts_Invoice_Line__c> parts) {
		String meaningfulData = ro.Name + ';' + ro.dealer__Customer__c
			+ ';' + ro.dealer__Vehicle_Inventory__c + ';' + ro.dealer__Vehicle__c + ';';
		for(dealer__Parts_Invoice_Line__c l : parts) {
			meaningfulData += l.Id + ';' + l.Name + ';' + l.dealer__Part__c + ';' + String.valueOf(l.dealer__Quantity_Sold__c) + ';';
		}
        Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(meaningfulData));
        String b64 = EncodingUtil.base64Encode(hash);
        return b64;     
	}

	// UpdateRoHashes - SRO trigger on update only
	// update the current hash, compare with last sent hash and set update flag if needed
	//-------------------------------------------------------------
	public static void UpdateRoHashes(List<dealer__Service_Repair_Order__c> newlist) {
		List<Id> roIdList = new List<Id>();
		// BLL2 - only bother recalculating hash if the RAISIN_Needs_Update__c flag is NOT already set
		//BLL2d for(dealer__Service_Repair_Order__c ro : newlist) roIdList.add(ro.Id);
		for(dealer__Service_Repair_Order__c ro : newlist) if (!ro.RAISIN_Needs_Update__c && ro.dealer__Number_of_Repair_Lines__c>0 && ro.dealer__Parts_Cost__c!=0) roIdList.add(ro.Id); // BLL2a
		// BLL2 end
		Map<Id, dealer__Service_Repair_Order__c> PartsMap = new Map<Id, dealer__Service_Repair_Order__c>();
		if (roIdList.size()>0) PartsMap = RAISIN_Utility.getRoMapFromIds(roIdList);
		for(dealer__Service_Repair_Order__c ro : newlist) {
			dealer__Service_Repair_Order__c roparts = PartsMap.get(ro.Id);
			// BLL3
			System.debug(roparts);
			// if (roparts!=null) {
			if (roparts!=null && DealTypesForDocutrack.contains(roparts.Deal__r.dealer__Deal_Type__c)) {
			// BLL3
				String hash = RAISIN_Utility.CalculateRoHash(ro, roparts.dealer__Parts_Lines__r);
				ro.RAISIN_Current_Hash__c = hash;
				ro.RAISIN_Needs_Update__c = ro.RAISIN_Needs_Update__c || hash!=ro.RAISIN_Sent_Hash__c;
			}
		}
	}

	// generateCustomerBlock
	//-----------------------------------------------
	private void generateCustomerBlock(dealer__Service_Repair_Order__c ro) {

		xml.writeStartElement(null, 'Customer', null);

		// ExtCustomerId
		xml.writeStartElement(null, 'ExtCustomerId', null);
		xml.writeCharacters(ro.dealer__Customer__c);
		xml.writeEndElement();

		// CustomerNumber
		xml.writeStartElement(null, 'CustomerNumber', null);
		xml.writeCharacters(ro.dealer__Customer__r.ClientID__c);	// 50
		xml.writeEndElement();

		// Name
		String fname = '';
		String lname = ro.dealer__Customer__r.Name;
		if (ro.dealer__Customer_Contact__c!=null) {
			fname = ro.dealer__Customer_Contact__r.FirstName;
			lname = ro.dealer__Customer_Contact__r.LastName;
		}
		// FirstName
		if (!String.isBlank(fname)) {
			xml.writeStartElement(null, 'FirstName', null);
			xml.writeCharacters(fname.left(100));
			xml.writeEndElement();
		}
		// LastName
		if (!String.isBlank(lname)) {
			xml.writeStartElement(null, 'LastName', null);
			xml.writeCharacters(lname.left(100));
			xml.writeEndElement();
		}

		List<String> addrparts = new List<String>();
		if (!String.isBlank(ro.dealer__Customer__r.BillingStreet)) addrparts = ro.dealer__Customer__r.BillingStreet.split('\n');
		if (addrparts.size()>=1) {
			// Address1
			xml.writeStartElement(null, 'Address1', null);
			xml.writeCharacters(addrparts[0].left(50));
			xml.writeEndElement();
		}
		if (addrparts.size()>=2) {
			// Address2
			xml.writeStartElement(null, 'Address2', null);
			xml.writeCharacters(addrparts[1].left(50));
			xml.writeEndElement();
		}

		// City
		if (!String.isBlank(ro.dealer__Customer__r.BillingCity)) {
			xml.writeStartElement(null, 'City', null);
			xml.writeCharacters(ro.dealer__Customer__r.BillingCity.left(50));
			xml.writeEndElement();
		}

		// StateCode
		if (!String.isBlank(ro.dealer__Customer__r.BillingState) && ro.dealer__Customer__r.BillingState.length()<=3) {
			xml.writeStartElement(null, 'StateCode', null);
			xml.writeCharacters(ro.dealer__Customer__r.BillingState.left(3));
			xml.writeEndElement();
		}

		// Zip
		if (!String.isBlank(ro.dealer__Customer__r.BillingPostalCode)) {
			xml.writeStartElement(null, 'Zip', null);
			xml.writeCharacters(ro.dealer__Customer__r.BillingPostalCode.left(15));
			xml.writeEndElement();
		}

		// Phone
		String phone = ro.dealer__Customer__r.Phone!=null ? ro.dealer__Customer__r.Phone : ro.dealer__Customer__r.PersonHomePhone;
		if (!String.isBlank(phone)) {
			xml.writeStartElement(null, 'Phone', null);
			xml.writeCharacters(phone.left(20));
			xml.writeEndElement();
		}

		// Email
		String email = ro.dealer__Customer__r.dealer__Billing_Email__c;
		email = ro.dealer__Customer__r.PersonEmail;
		if (!String.isBlank(email)) {
			xml.writeStartElement(null, 'Email', null);
			xml.writeCharacters(email.substringBefore(',').left(150));
			xml.writeEndElement();
		}

		// Elems skipped: PmdType1, PmdMake1, PmdSerial1, 
		// Elems skipped: PmdType2, PmdMake2, PmdModel2, PmdSerial2
		//xml.writeStartElement(null, 'Elem', null);
		//xml.writeCharacters('');	// 100
		//xml.writeEndElement();

		// UpdatedAt
		xml.writeStartElement(null, 'UpdatedAt', null);
		xml.writeCharacters(ro.dealer__Customer__r.LastModifiedDate.formatGmt(DATE_TIME_FORMAT));
		xml.writeEndElement();
		
		xml.writeEndElement();	// Customer
		
	}

	// generateVehicleBlock
	//-----------------------------------------------
	private void generateVehicleBlock(dealer__Service_Repair_Order__c ro) {
		boolean useStockVeh = (ro.dealer__Vehicle_Inventory__c!=null);
		String vid = useStockVeh ? ro.dealer__Vehicle_Inventory__c : ro.dealer__Vehicle__c;
		String vin = useStockVeh ? ro.dealer__Vehicle_Inventory__r.dealer__VIN__c : ro.dealer__Vehicle__r.dealer__VIN__c;
		String year = useStockVeh ? ro.dealer__Vehicle_Inventory__r.dealer__Year__c : ro.dealer__Vehicle__r.dealer__Year__c;
		String make = useStockVeh ? ro.dealer__Vehicle_Inventory__r.dealer__Make__c : ro.dealer__Vehicle__r.dealer__Make__c;
		String model = useStockVeh ? ro.dealer__Vehicle_Inventory__r.dealer__Model__c : ro.dealer__Vehicle__r.dealer__Carline__c;
		Decimal odometer = useStockVeh ? ro.dealer__Vehicle_Inventory__r.dealer__Mileage__c : ro.dealer__Vehicle__r.dealer__Last_Odometer__c;
		DateTime vehlastupdate = useStockVeh ? ro.dealer__Vehicle_Inventory__r.LastModifiedDate : ro.dealer__Vehicle__r.LastModifiedDate; 

		if (String.isBlank(vid)) return;	// no vehicle!

		xml.writeStartElement(null, 'Vehicle', null);

		String LoweredFloorMfgId = '';
		String LoweredFloorMfgOther = usestockveh ? ro.dealer__Vehicle_Inventory__r.Conv_MFG__c : ro.dealer__Vehicle__r.dealer__Conversion_MFG__c;
		if (LoweredFloorMfgIdMap.containsKey(LoweredFloorMfgOther)) {
			LoweredFloorMfgId = LoweredFloorMfgIdMap.get(LoweredFloorMfgOther);
			LoweredFloorMfgOther = '';
		}
		
		
		List<String> VehTypes = new List<String>();
		String VehTypeOther = '';
		if (ro.dealer__Vehicle_Inventory__c!=null) VehTypeOther = ro.dealer__Vehicle_Inventory__r.Unit_Type__c;
		if (!String.isBlank(ro.dealer__Vehicle_Inventory__r.Division__c) && VehicleTypeMap.containsKey(ro.dealer__Vehicle_Inventory__r.Division__c))
			VehTypes.add(VehicleTypeMap.get(ro.dealer__Vehicle_Inventory__r.Division__c));
		if (!String.isBlank(VehTypeOther) && VehicleTypeMap.containsKey(VehTypeOther)) {
			VehTypes.add(VehicleTypeMap.get(ro.dealer__Vehicle_Inventory__r.Unit_Type__c));
			VehTypeOther = '';
		}
		if (ro.dealer__Vehicle_Inventory__c!=null && !String.isBlank(ro.dealer__Vehicle_Inventory__r.FS_Raised_Top__c)) {
			VehTypes.add(VehicleTypeMap.get('Raised Roof'));
		}

		// ExtVehicleId
		xml.writeStartElement(null, 'ExtVehicleId', null);
		xml.writeCharacters(vid);
		xml.writeEndElement();

		// Vin
		if (!String.isBlank(vin)) {
			xml.writeStartElement(null, 'Vin', null);
			xml.writeCharacters(vin.left(17));
			xml.writeEndElement();
		}

		// Year
		if (!String.isBlank(year) && year.isNumeric() && year.length()==4) {
			xml.writeStartElement(null, 'Year', null);
			xml.writeCharacters(year);	// integer
			xml.writeEndElement();
		}

		// Make
		if (!String.isBlank(make)) {
			xml.writeStartElement(null, 'Make', null);
			xml.writeCharacters(make.left(50));
			xml.writeEndElement();
		}

		// Model
		if (!String.isBlank(model)) {
			xml.writeStartElement(null, 'Model', null);
			xml.writeCharacters(model.left(50));
			xml.writeEndElement();
		}

		// Odometer
		if (odometer!=null) {
			xml.writeStartElement(null, 'Odometer', null);
			xml.writeCharacters(String.valueOf(odometer));	// integer
			xml.writeEndElement();
		}

		// MobilityVehicleTypes
		xml.writeStartElement(null, 'MobilityVehicleTypes', null);
		for(String mvt : VehTypes) {
			// MobilityVehicleTypeId
			xml.writeStartElement(null, 'MobilityVehicleTypeId', null);
			xml.writeCharacters(mvt);
			xml.writeEndElement();
		}
		xml.writeEndElement();

		// MobilityVehicleTypeOther
		if (!String.isBlank(VehTypeOther)) {
			xml.writeStartElement(null, 'MobilityVehicleTypeOther', null);
			xml.writeCharacters(VehTypeOther.left(100));
			xml.writeEndElement();
		}
 
		// LoweredFloorManufacturerId
		if (!String.isBlank(LoweredFloorMfgId)) {
			xml.writeStartElement(null, 'LoweredFloorManufacturerId', null);
			xml.writeCharacters(LoweredFloorMfgId);	// integer
			xml.writeEndElement();
		} else {
			xml.writeEmptyElement(null, 'LoweredFloorManufacturerId', null);
		}

		// LoweredFloorManufacturerOther
		if (!String.isBlank(LoweredFloorMfgOther)) {
			xml.writeStartElement(null, 'LoweredFloorManufacturerOther', null);
			xml.writeCharacters(LoweredFloorMfgOther.left(100));
			xml.writeEndElement();
		}

		// KeyCount
		if (ro.dealer__Vehicle_Inventory__r.of_Keys__c!=null) {
			xml.writeStartElement(null, 'KeyCount', null);
			xml.writeCharacters(ro.dealer__Vehicle_Inventory__r.of_Keys__c);	// integer
			xml.writeEndElement();
		}

		// RemoteCount
		if (ro.dealer__Vehicle_Inventory__r.of_Remotes__c!=null) {
			xml.writeStartElement(null, 'RemoteCount', null);
			xml.writeCharacters(ro.dealer__Vehicle_Inventory__r.of_Remotes__c);	// integer
			xml.writeEndElement();
		}

		// CurbWeight
		//xml.writeStartElement(null, 'CurbWeight', null);
		//xml.writeCharacters('');	// 20
		//xml.writeEndElement();

		// FuelCapacity
		if (ro.dealer__Vehicle_Inventory__r.dealer__Fuel_Tank_Capacity__c!=null) {
			xml.writeStartElement(null, 'FuelCapacity', null);
			xml.writeCharacters(String.valueOf(ro.dealer__Vehicle_Inventory__r.dealer__Fuel_Tank_Capacity__c));	// limit 13 dig!
			xml.writeCharacters(' gallon');	// limit 20 char total !
			xml.writeEndElement();
		}

		// UpdatedAt
		xml.writeStartElement(null, 'UpdatedAt', null);
		xml.writeCharacters(vehlastupdate.formatGmt(DATE_TIME_FORMAT));
		xml.writeEndElement();

		xml.writeEndElement();	// vehicle
		
	}

	// generateInstallsBlock
	//-----------------------------------------------
	private void generateInstallsBlock(dealer__Service_Repair_Order__c ro) {
		xml.writeStartElement(null, 'Installs', null);
		
		for(dealer__Parts_Invoice_Line__c l : ro.dealer__Parts_Lines__r) {

			xml.writeStartElement(null, 'Install', null);
			
			// ExtInstallId
			xml.writeStartElement(null, 'ExtInstallId', null);
			xml.writeCharacters(l.Id);	
			xml.writeEndElement();

			String mfgId = '';
			String mfgOther = l.dealer__Part__r.dealer__MFG__c;
			if (MfgMap.containsKey(mfgOther)) {
				mfgId = MfgMap.get(mfgOther);
				mfgOther = '';
			}
			// ManufacturerId
			if (!String.isBlank(mfgId)) {
				xml.writeStartElement(null, 'ManufacturerId', null);
				xml.writeCharacters(mfgId);	// integer
				xml.writeEndElement();
			} else {
				//xml.writeCharacters('<ManufacturerId xsi:nil="true"/>');
				xml.writeEmptyElement(null, 'ManufacturerId', null);
			}

			// PartNumber	
			if (!String.isBlank(l.dealer__Part__r.dealer__Part_Number__c)) {
				xml.writeStartElement(null, 'PartNumber', null);
				xml.writeCharacters(l.dealer__Part__r.dealer__Part_Number__c.left(100));
				xml.writeEndElement();
			}

			// Description
			if (!String.isBlank(l.dealer__Part_Description__c)) {
				xml.writeStartElement(null, 'Description', null);
				xml.writeCharacters(l.dealer__Part_Description__c.left(200));
				xml.writeEndElement();
			}

			// Used
			xml.writeStartElement(null, 'Used', null);
			// BLL1c - following line: default to "New" if part_type__c is left empty (null)
			xml.writeCharacters((!String.isBlank(l.Part_type__c) && l.Part_type__c!='N') ? 'true' : 'false');
			xml.writeEndElement();


			// SerialNumber
			//xml.writeStartElement(null, 'SerialNumber', null);
			//xml.writeCharacters('');	// 50
			//xml.writeEndElement();

			// UpdatedAt
			xml.writeStartElement(null, 'UpdatedAt', null);
			xml.writeCharacters(l.LastModifiedDate.formatGmt(DATE_TIME_FORMAT));
			xml.writeEndElement();

			xml.writeEndElement();	// Install
		}

		xml.writeEndElement();	// Installs
	}

	// generateSentToOtherDealerBlock
	//-----------------------------------------------
	private void generateSentToOtherDealerBlock(dealer__Service_Repair_Order__c ro) {
		// SentToOtherDealer
		xml.writeStartElement(null, 'SentToOtherDealer', null);
		xml.writeCharacters('false');
		xml.writeEndElement();

		// SentToName
		//xml.writeStartElement(null, 'SentToName', null);
		//xml.writeCharacters('');	// 100
		//xml.writeEndElement();
		// SentToPhone
		//xml.writeStartElement(null, 'SentToPhone', null);
		//xml.writeCharacters('');	// 20
		//xml.writeEndElement();
		// SentToCity
		//xml.writeStartElement(null, 'SentToCity', null);
		//xml.writeCharacters('');	// 50
		//xml.writeEndElement();
		// SentToStateCode
		//xml.writeStartElement(null, 'SentToStateCode', null);
		//xml.writeCharacters('');	// 3
		//xml.writeEndElement();
		// SentToZip
		//xml.writeStartElement(null, 'SentToZip', null);
		//xml.writeCharacters('');	// 15
		//xml.writeEndElement();
		// SentToLabelNumber
		//xml.writeStartElement(null, 'SentToLabelNumber', null);
		//xml.writeCharacters('');	// integer
		//xml.writeEndElement();

		// SentToWorkTypes
		//xml.writeStartElement(null, 'SentToWorkTypes', null);
			// OutsideDealerWorkTypeId
			//xml.writeStartElement(null, 'OutsideDealerWorkTypeId', null);
			//xml.writeCharacters('');
			//xml.writeEndElement();
		//xml.writeEndElement();
		// SentToWorkTypeOther
		//xml.writeStartElement(null, 'SentToWorkTypeOther', null);
		//xml.writeCharacters('');	// 200
		//xml.writeEndElement();

	}

	// generateJob
	//-----------------------------------------------
	private void generateJob(dealer__Service_Repair_Order__c ro) {
		xml.writeStartElement(null,'Job', null);
			// ExtJobid
			xml.writeStartElement(null,'ExtJobId', null);
			xml.writeCharacters(ro.Id);
			xml.writeEndElement();

			// DealerId
			xml.writeStartElement(null, 'DealerId', null);
			xml.writeCharacters(ro.dealer__Company__r.Raisin_Id__c);
			xml.writeEndElement();
	
			// Customer info
			generateCustomerBlock(ro);
			
			// Vehicle info
			if (ro.dealer__Vehicle_Inventory__c!=null || ro.dealer__Vehicle__c!=null) {
				generateVehicleBlock(ro);
			}
			
			// Install info (parts)
			generateInstallsBlock(ro);

			// JobNumber
			xml.writeStartElement(null, 'JobNumber', null);
			xml.writeCharacters(ro.Name.removeStart('RO#'));
			xml.writeEndElement();

			//? IsCargoUseOnly
			xml.writeStartElement(null, 'IsCargoUseOnly', null);
			xml.writeCharacters('false');
			xml.writeEndElement();

			//? IsPassThrough 
			xml.writeStartElement(null, 'IsPassThrough', null);
			xml.writeCharacters('false');
			xml.writeEndElement();

			generateSentToOtherDealerBlock(ro);	// hard-coded as "false"

			// LabelNumber
			if (!String.isBlank(ro.Raisin_Label_Nbr__c)) {
				xml.writeStartElement(null, 'LabelNumber', null);
				xml.writeCharacters(ro.Raisin_Label_Nbr__c);
				xml.writeEndElement();
			}

			// UpdatedAt
			xml.writeStartElement(null, 'UpdatedAt', null);
			xml.writeCharacters(ro.LastModifiedDate.formatGmt(DATE_TIME_FORMAT));
			xml.writeEndElement();
			
		xml.writeEndElement();
	}

	// generateJobListxml
	//-----------------------------------------------
	private void generateJobList(List<Id> jobidlist) {
		DateTime starttime = DateTime.now();
		
		xml.writeStartDocument('utf-8','1.0');
		xml.writeStartElement(null,'RaisinDataExchange', null);
		Integer roCount = 0;
		Map<Id, dealer__Service_Repair_Order__c> roMap = RAISIN_Utility.getRoMapFromIds(jobidlist); 
		for(dealer__Service_Repair_Order__c ro : roMap.values()) {
			//if (ro.dealer__Parts_Lines__r.size()>0) {
				generateJob(ro);
				++roCount;
				// to update last date/time sent to Raisin
				updSROs.add(new dealer__Service_Repair_Order__c(
					Id=ro.Id, 
					RAISIN_Needs_Update__c = false,
					Raisin_Last_Sent_DT__c = starttime,
					RAISIN_Sent_Hash__c = RAISIN_Utility.CalculateRoHash(ro, ro.dealer__Parts_Lines__r)
				));
			//}
		}
		xml.writeEndDocument();
		if (roCount==0) xml = null;
	}
	
	// getRoLsitFromIds
	//-----------------------------------------------
	public static Map<Id, dealer__Service_Repair_Order__c> getRoMapFromIds(List<Id> idList) {
		return new Map<Id, dealer__Service_Repair_Order__c>([
			select Id, Name, dealer__Company__r.Raisin_Id__c, Raisin_Label_Nbr__c, LastModifiedDate, 
				dealer__Customer__c, dealer__Customer__r.Name, dealer__Customer__r.ClientID__c,
				dealer__Customer__r.BillingStreet, dealer__Customer__r.BillingCity, dealer__Customer__r.BillingState, dealer__Customer__r.BillingPostalCode, 
				dealer__Customer__r.PersonHomePhone, dealer__Customer__r.Phone,  dealer__Customer__r.dealer__Billing_Email__c, 
				dealer__Customer__r.PersonEmail, dealer__Customer__r.LastModifiedDate,   
				dealer__Customer_Contact__c, dealer__Customer_Contact__r.Name, dealer__Customer_Contact__r.FirstName, dealer__Customer_Contact__r.LastName,
				dealer__Vehicle_Inventory__c, dealer__Vehicle_Inventory__r.dealer__VIN__c, dealer__Vehicle_Inventory__r.dealer__Mileage__c, 
				dealer__Vehicle_Inventory__r.dealer__Year__c, dealer__Vehicle_Inventory__r.dealer__Make__c, dealer__Vehicle_Inventory__r.dealer__Model__c,
				dealer__Vehicle_Inventory__r.Division__c,  dealer__Vehicle_Inventory__r.Unit_Type__c,
				dealer__Vehicle_Inventory__r.FS_Raised_Top__c, dealer__Vehicle_Inventory__r.of_Keys__c, dealer__Vehicle_Inventory__r.of_Remotes__c,
				dealer__Vehicle_Inventory__r.dealer__Fuel_Tank_Capacity__c,  	
				dealer__Vehicle_Inventory__r.Conv_MFG__c, dealer__Vehicle_Inventory__r.LastModifiedDate, 
				dealer__Vehicle__c, dealer__Vehicle__r.dealer__VIN__c, dealer__Vehicle__r.dealer__Last_Odometer__c, 
				dealer__Vehicle__r.dealer__Year__c, dealer__Vehicle__r.dealer__Make__c, dealer__Vehicle__r.dealer__Carline__c,
				dealer__Vehicle__r.dealer__Conversion_MFG__c, dealer__Vehicle__r.LastModifiedDate, 
				Deal__c, Deal__r.dealer__Deal_Type__c, 
				//(	select Id, Name 
				//	from dealer__Job_Lines__r
				//	order by Name
				//),
				(	select Id, Name, dealer__Part__c, dealer__Part__r.dealer__Part_Number__c, dealer__Part__r.dealer__MFG__c,  
						dealer__Part__r.dealer__Parts_Master__c,  dealer__Part__r.dealer__Parts_Master__r.dealer__Manufacturer__c,
						dealer__Part_Description__c, Part_type__c, dealer__Quantity_Sold__c, 
						LastModifiedDate
					from dealer__Parts_Lines__r
					order by Name, dealer__Part__c
				)
			from dealer__Service_Repair_Order__c 
			where Id in :idlist
			  and dealer__Company__c!=null and dealer__Company__r.Raisin_Id__c!=null
		]);
	}

	// getJobListXML
	//-----------------------------------------------
	public String getJobListXML(List<Id> jobidlist) {
		xml = new XmlStreamWriter();
		updSROs = new List<dealer__Service_Repair_Order__c>();

		generateJobList(jobidlist);

		Database.SaveResult[] saveresults = new List<Database.SaveResult>();
	
		if (doUpdateSROs && updSROs.size()>0) saveresults = Database.update(updSROs, false);

		System.debug('List of failed updates:');
		for(Integer i=0; i<updSROs.size(); i++) {
			dealer__Service_Repair_Order__c o = updSROs[i];
			System.debug(o);
			Database.SaveResult sr = saveresults.size()>i ? saveresults[i] : null;
			System.debug(sr);
			if (sr!=null && !sr.isSuccess()) {
				String errmsgline = o.Id + ',' + o.Name + ': ';
				System.debug(errmsgline);
				for(Database.Error de : sr.getErrors()) {
					errmsgline += '[' + String.join(de.getFields(), ', ') + '] '
						+ de.getMessage() + '\r';
				}
				System.debug(errmsgline);
				errmsgs += errmsgline;
			}
		}
		return xml!=null ? xml.getXmlString() : null;
	}



	//------------------------------------------------------------
	// Batch & Schedulable interfaces 
	//------------------------------------------------------------

	// start - query the database
	global Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(query);
	}


	// execute for a batch of records
	global void execute(Database.BatchableContext bc, List<sObject> scope) {
		List<dealer__Service_Repair_Order__c> objs = (List<dealer__Service_Repair_Order__c>) scope;
		System.debug('Record count: ' + String.valueOf(objs.size()));
		List<Id> roIds = new List<Id>();

		// Update
		for(dealer__Service_Repair_Order__c o : objs) {
			roIds.add(o.Id);
		}
		String xmldoc = getJobListXML(roIds);
		
		//TODO: do something with it ...
		sendEmail(xmldoc);
		
	}
	
	
	// finish - send results via email
	global void finish(Database.BatchableContext bc) {
		//sendEmail();
	}


	// sendEmail of the results	
	global void sendEmail(String resultxml) {
		Organization org = [select Id, Name, InstanceName, isSandbox from Organization limit 1];
		
		MobilityForceSettings__c MobilityForceSettings = MobilityForceSettings__c.getOrgDefaults();
		String RaisinRecipient = '';
		RaisinRecipient = MobilityForceSettings.RAISIN_app_recipient__c;

		MonitorExecution__c RAISINapp = MonitorExecution__c.getInstance('RAISIN_app');
		String RaisinAdmin = '';
		if (!org.isSandbox && !String.isBlank(errmsgs)) RaisinAdmin += 'ithelp@mobilityworks.com';	// help desk ticket

		// Add raisin app admin if monitoring turned on
		List<User> users = new List<User>();
		if (RAISINapp!=null && !String.isBlank(RAISINapp.AdminName__c)) users =[select Id, Name, Email from User where Name=:RAISINapp.AdminName__c];
		if (RAISINapp!=null && RAISINapp.Enabled__c && users.size()>0) RaisinAdmin += (String.isBlank(RaisinAdmin) ? '':',') + users[0].Email;
		
		//String csvheader = 'col1,col2,etc\n';
		List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
		List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();
		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		List<String> recipients = new List<String>();
		if (!org.isSandbox && !String.isBlank(RaisinRecipient)) recipients.addAll(RaisinRecipient.split(','));
		if (!String.isBlank(RaisinAdmin) && (org.isSandbox || !String.isBlank(errmsgs))) recipients.addAll(RaisinAdmin.split(','));
		//System.debug(recipients.size());
		if (recipients.size()==0) recipients.add(UserInfo.getUserEmail());
		System.debug(recipients);
		//for(String r : recipients) System.debug('Recipient: ' + r);
		 
		mail.setToAddresses(recipients); 
		String subject = 'Production Work Export for RAISIN app FTP';
		if (org.isSandbox) subject += ' (' + org.InstanceName + ')';
		mail.setSubject(subject);
		String body = 'RAISIN Export job part has completed.\n\n';
		if (!doUpdateSROs) body += 'Test only! RO date sent NOT Updated!\n\n';
		if (String.isBlank(resultxml)) body += 'No data generated for xml.\n\n';
		if (!String.isBlank(errmsgs)) body += errmsgs + '\n\n';
		mail.setPlainTextBody(body);
		
		Messaging.EmailFileAttachment resultcsv = new Messaging.EmailFileAttachment();
			resultcsv.setContentType('text/xml');
			resultcsv.setFileName('in.' + DateTime.now().format('yyyyMMddHHmmss') + '.xml');
			resultcsv.setInline(false);
			if (!String.isBlank(resultxml)) resultcsv.Body = Blob.valueOf(resultxml);
			if (!String.isBlank(resultxml)) listOfAttachments.add(resultcsv);
		//Messaging.EmailFileAttachment upderrors = new Messaging.EmailFileAttachment();
		//	upderrors.setContentType('text/plain');
		//	upderrors.setFileName('UpdateErrors.txt');
		//	upderrors.setInline(false);
		//	upderrors.Body = Blob.valueOf(errmsgs);
		//	if (!String.isBlank(errmsgs)) listOfAttachments.add(upderrors);
		mail.setFileAttachments(listOfAttachments);
		emailMsgs.add(mail);
	
		// Only send if records were selected for processing...
		//if (resultmap.size()>0 || !String.isBlank(errmsgs)) Messaging.sendEmail(emailMsgs);
		Messaging.sendEmail(emailMsgs);
		
		// Reset to clear HEAP
		//resultmap = new Map<Id,String>();
		errmsgs = '';
		
	}


	// Schedulable context
	global void execute(SchedulableContext ctx) {
		String maxrcds = Test.isRunningTest() ? '1' : null;
		BatchSchedule__c bs = [
			select Name, ClassName__c, CronSchedule__c, Parameters__c, ScheduledJobId__c, Active__c, BatchSize__c
			from BatchSchedule__c
			where ScheduledJobId__c=:ctx.getTriggerId()
		];
		if (bs==null || bs.Active__c) {
			RAISIN_Utility b = new RAISIN_Utility();
			Database.executeBatch(b, Integer.valueOf(bs.BatchSize__c));
		}
	}

	// scheduleMe self-scheduler
	public static List<String> scheduleMe() {
		String thisClassName = RAISIN_Utility.class.getName();
		// from schedule custom settings
		List<BatchSchedule__c> bss = [
			select Name, ClassName__c, CronSchedule__c, Parameters__c, ScheduledJobId__c, Active__c, BatchSize__c
			from BatchSchedule__c 
			where ClassName__c=:thisClassName
		];
		// First remove existing scheduled jobs ... 
		for(BatchSchedule__c bs : bss) {
			try {
				if (!String.isBlank(bs.ScheduledJobId__c)) System.abortJob((Id) bs.ScheduledJobId__c);
			} catch(Exception e) {System.debug(e);}
		}

		// set default schedule if none found
		Integer i = 0;
		if (bss.size()==0) {
			for(String cron : RAISIN_Utility.CRON_LIST) {
				String devname = thisClassName.left(37) + '_' + String.valueOf(i);
				bss.add(new BatchSchedule__c(
					Name = devname,
					ClassName__c = thisClassName,
					CronSchedule__c = cron,
					BatchSize__c = 25,
					Active__c=true
				));
				++i;
			}
		}
		
		// Now schedule the jobs that are in the BatchSchedule list for this class
		List<String> jobIds = new List<String>();
		RAISIN_Utility m = new RAISIN_Utility();
		for(BatchSchedule__c bs : bss) {
			System.debug(bs.CronSchedule__c);
			String jobname = bs.Name;
			if (Test.isRunningTest()) jobname += '_TEST';
			if (bs.Active__c) {
				Id jobId = System.schedule(jobname, bs.CronSchedule__c, m);
				bs.ScheduledJobId__c = jobId;
				jobIds.add(jobId);
			}
		}
		upsert(bss);
		return jobIds;
	}


}