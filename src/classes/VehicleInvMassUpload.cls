/**
 * VehicleInvMassUpload
 * Tested by: VehicleInvMassUpload_TEST
 * Date: May 30, 2018
 * Programmer: Bryan Leaman
 *
 * Coverage:
 *	2018-06-11	94% (162/172)
 *	2018-06-27	76% (354/460)
 *	2018-08-17	80%	(409/510)
 *
 * Modifications:
 *	2018-09-06	B. Leaman	BLL1 - add support for notes from template.
 *	2018-09-07	B. Leaman	BLL2 - reset days in current status (by assigning status code assignment date), use users default record type
 *	2018-09-11	B. Leaman	BLL3 - only create PO if vehicle was created
 */
public with sharing class VehicleInvMassUpload {

	public String fileName {get;set;}
	public Blob csvBlob {get;set;}
	public Set<String> unrecognizedColumns;	
	public List<VehicleUploadWrapper> errorRcds {get;private set;}
	public List<VehicleUploadWrapper> readyRcds {get;private set;}
	//public List<VehicleUploadWrapper> goodRcdData {get {
	//	System.debug('getGoodRcdData');
	//	List<VehicleUploadWrapper> vehs = new List<VehicleUploadWrapper>(); 
	//	for(VehicleUploadWrapper rr : readyRcds) {System.debug(rr);vehs.add(rr);} 
	//	return vehs;
	//} private set;}
    public boolean haveData {get;private set;}
    public boolean haveGoodData {get;private set;}
    public boolean dataSubmitted {get;private set;}
    public boolean haveErrors {get;private set;}
    public boolean missingCosts {get;private set;}
    public boolean processComplete {get;private set;}
    public dealer__Purchase_Order__c chassisPO {get;set;}
    public dealer__Purchase_Order__c conversionPO {get;set;}
    public Integer VehiclesPerPO {get;set;}
    private dealer__Vehicle_Inventory__c  templateVeh;

	public String CreatePoOption {get;set;}

	// private work data ...
	private boolean POAddCostsToVeh = true;

	// Lookup/reference field values to map to Ids
	//	{
	//		'Conversion__c' => { 'BraunAbility1' => slsfrcid1, 'BraunAbility2' => slsfrcid2 }, 
	//		'OtherField__c' => { 'Value1' => id1 }
	//	}
	private Map<String, Map<String,Id>> refFldMap = new Map<String, Map<String,Id>>(); 
	private Map<String, Schema.sObjectType> refToMap = new Map<String, Schema.sObjectType>(); 

	// field definition maps by field name and field label (either can be used in CSV column heading)
	transient private Map<String, Schema.DescribeFieldResult> fnMap;
	transient private Map<String, Schema.DescribeFieldResult> lblMap;
	//transient private List<VehicleUploadWrapper> vehList;

	private Map<Integer, Map<String,String>> csvmap;
	private List<String> csvColNames;
	private Integer mappingerrors;
	private	Map<String, dealer__Purchase_Order__c> StockNbrPOMap;
	private	Map<String, dealer__Purchase_Order__c> StockNbrPOMap2;
    private Integer NewVehicles;
    private Integer NewPOs;
    public List<dealer__Purchase_Order__c> CreatedPurchaseOrders {get;private set;}

	public dealer__Purchase_Order_Line__c ChassisFFRefs {get;set;}
	public dealer__Purchase_Order_Line__c ConversionFFRefs {get;set;}
	public dealer__Purchase_Order_Line__c ChassisContraFFRefs {get;set;}
	public dealer__Purchase_Order_Line__c ConversionContraFFRefs {get;set;}

	//BLL2d private transient Map<String, Schema.RecordTypeInfo> VehRcdTypes;
	//BLL2d private transient Schema.RecordTypeInfo UsedRtInfo;
	private transient Schema.RecordTypeInfo DftRtInfo;	// BLL2a
	
	// For restricting/editing picklist values...
	Map<String, Map<String,String>> picklistFldMap;

	//-------------------------------------------------------------
	// temporary hard-coded mappings to be made more maintainable
	//private Map<String,String> UnbilledGLMap = new Map<String,String>{
	//	'Default' => '2115',	
	//	'Ally SmartAuction' => '2500', 'Ally SmartAuction:7/80' => '2505',
	//	'TRANSITWORKS' => '2903'
	//};
	//private Map<String,String> UnbilledDim1Map = new Map<String,String>{
	//	// default is to use the receiving store's dimension1
	//	'TRANSITWORKS:PPV' => '199',
	//	'Ally SmartAuction' => '100'
	//};
	//private Map<String,String> ChassisGL = new Map<String,String>{
	//	'New' => '1242', 'Used' => '1244',
	//	'TEMPE' => '1255',
	//	'GE' => '1250',
	//	'TCF' => '1247'
	//};
	//private Map<String,String> ConversionGL = new Map<String,String>{
	//	'BraunAbility' => '1240',
	//	'GE' => '1251',
	//	'TEMPE' => '1256',
	//	'TCF' => '1248'
	//};
	//-------------------------------------------------------------
	//Map<String,c2g__codaGeneralLedgerAccount__c> glMap;
	//Map<String,c2g__codaDimension1__c> dim1Map;
	//Map<Id, dealer__Dealer_Location__c> LocIdMap;


	// VehicleInvMassUpload
	//---------------------------------------
	public VehicleInvMassUpload() {
		startOver();
		ChassisFFRefs = new dealer__Purchase_Order_Line__c();
		ConversionFFRefs = new dealer__Purchase_Order_Line__c();
		ChassisContraFFRefs = new dealer__Purchase_Order_Line__c();
		ConversionContraFFRefs = new dealer__Purchase_Order_Line__c();
		//BLL2d VehRcdTypes = Schema.SObjectType.dealer__Vehicle_Inventory__c.getRecordTypeInfosByName();
		//BLL2d UsedRtInfo = VehRcdTypes.get('Used');
		// BLL2a
		Schema.DescribeSObjectResult dsr = dealer__Vehicle_Inventory__c.SObjectType.getDescribe();
		for(Schema.RecordTypeInfo rti : dsr.getRecordTypeInfos()) {
    		if(rti.isDefaultRecordTypeMapping()) {
        		DftRtInfo = rti;
    		}
		}
		// BLL2a end
	}

	// noAction
	//-----------------------
	public void noAction() {}

	// reEdit
	public void reEdit() {
		boolean requireChassisCost = CreatePoOption=='Chassis' || CreatePoOption=='Combined' || CreatePoOption=='Separate';
		boolean requireConversionCost = CreatePoOption=='Conversion' || CreatePoOption=='Combined' || CreatePoOption=='Separate';
		Integer missingChassisCost = 0;
		Integer missingConversionCost = 0;
		for(VehicleUploadWrapper vuw : readyRcds) {
			if (vuw.ChassisCost==null || vuw.ChassisCost==0) missingChassisCost++;
			if (vuw.ConversionCost==null || vuw.ConversionCost==0) missingConversionCost++;
		}
		if (requireChassisCost && missingChassisCost>0) {
			missingCosts = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
				'Chassis cost is required for ' + CreatePoOption + ' purchase orders, but missing on ' + String.valueOf(missingChassisCost) + ' vehicles'));
		} 
		if (requireConversionCost && missingConversionCost>0) {
			missingCosts = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
				'Conversion cost is required for ' + CreatePoOption + ' purchase orders, but missing on ' + String.valueOf(missingConversionCost) + ' vehicles'));
		} 
	}

	// startOver
	//-----------------------
	public void startOver() {
		unrecognizedColumns = new Set<String>();
		haveData = false;
		haveGoodData = false;
		dataSubmitted = false;
		processComplete = false;
		fileName = null;
		csvBlob = null;
		errorRcds = null;
		readyRcds = null;
		CreatePoOption = null;
		chassisPO = new dealer__Purchase_Order__c();
		conversionPO = new dealer__Purchase_Order__c();
		VehiclesPerPO = 1;
		picklistFldMap = new Map<String,Map<String,String>>();
		missingCosts = false;
	}
	
	// loadLocationMap
	// depends on having loaded reference field mappings prior (refFldMap)
	//------------------------------------
	//public void loadLocationMap() {
	//	Set<Id> locIdSet = new Set<Id>();
	//	// get all referenced location Ids
	//	Map<String,Id> locNameMap = refFldMap.get('dealer__store_location__c');
	//	if (locNameMap==null) locNameMap = new Map<String, Id>();
	//	for(Id locId : locNameMap.values()) {
	//		locIdSet.add(locId);
	//	} 
	//	LocIdMap = new Map<Id, dealer__Dealer_Location__c>([
	//		select Id, Name, Financial_Force_Dimension_1__c, Financial_Force_Dimension_1__r.c2g__ReportingCode__c
	//		from dealer__Dealer_Location__c
	//		where Id in :locIdSet
	//	]);
	//}

	// loadFFMaps
	// depends on having run loadLocationMap prior
	//------------------------------------
	//public void loadFFMaps() {
	//	glMap = new Map<String,c2g__codaGeneralLedgerAccount__c>();
	//	dim1Map = new Map<String,c2g__codaDimension1__c>();
	//
	//	Set<String> GLAcctCodes = new Set<String>();
	//	Set<String> Dim1Codes = new Set<String>();
	//
	//	for(String code : UnbilledGLMap.values()) GLAcctCodes.add(code);
	//	for(String code : ChassisGL.values()) GLAcctCodes.add(code);
	//	for(String code : ConversionGL.values()) GLAcctCodes.add(code);
	//	
	//	for(String dim1 : UnbilledDim1Map.values()) Dim1Codes.add(dim1);
	//	for(dealer__Dealer_Location__c loc : LocIdMap.values()) Dim1Codes.add(loc.Financial_Force_Dimension_1__r.c2g__ReportingCode__c);
	//	
	//	for(c2g__codaGeneralLedgerAccount__c gla : [
	//		select Id, Name, c2g__ReportingCode__c 
	//		from c2g__codaGeneralLedgerAccount__c 
	//		where c2g__ReportingCode__c in :GLAcctCodes]
	//		) {
	//		glMap.put(gla.c2g__ReportingCode__c, gla);
	//	}
	//	
	//	for(c2g__codaDimension1__c dim1 : [
	//		select Id, Name, c2g__ReportingCode__c
	//		from c2g__codaDimension1__c
	//		where c2g__ReportingCode__c in :Dim1Codes
	//		]) {
	//		dim1Map.put(dim1.c2g__ReportingCode__c, dim1);
	//	}
	//	
	//}

	// submitCsv
	//-----------------------
	public void submitCsv() {
		String csvData;
		if (csvBlob!=null) {
			//System.debug(csvBlob);
			csvData = csvBlob.toString();
			//System.debug(csvData);
		}
		haveData = !String.isBlank(csvData); 
		if (haveData) {
			templateVeh = new dealer__Vehicle_Inventory__c();
			if (ChassisPO!=null && ChassisPO.Vehicle_Inventory_Template__c!=null) templateVeh = LoadVehicleTemplate(ChassisPO.Vehicle_Inventory_Template__c);
			ValidateVehicleUpload(CreateVehicleList(csvData, templateVeh));
		} else {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'You must select a valid csv file to upload.'));
		}
		//if (CreatePoOption==null) {
		//	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'You must select a PO creation option.'));
		//}
	}

	// LoadVehicleTemplate
	//------------------------------------------
	public dealer__Vehicle_Inventory__c LoadVehicleTemplate(Id vehId) {
		dealer__Vehicle_Inventory__c templateVeh;
		Map<String, Schema.SObjectField> vehFieldMap =  Schema.dealer__Vehicle_Inventory__c.SObjectType.getDescribe().fields.getMap();
		List<String> vehFieldList = new List<String>();
		for(string f : vehFieldMap.keySet()) if (vehFieldMap.get(f).getDescribe().isCreateable()) vehFieldList.add(f);
		String vehfields = String.join(vehFieldList, ',');
		String soql = 'select ' + vehfields
			+ ', (SELECT Id, Title, Body FROM Notes) '	// BLL1a 
			+ 'from dealer__Vehicle_Inventory__c where Id=\'' + vehId + '\' ';
		List<dealer__Vehicle_Inventory__c> templateVehs = Database.query(soql);
		if (templateVehs!=null && templateVehs.size()>0) templateVeh = templateVehs[0];
		return templateVeh;
	}
	
	// processUpload
	//-----------------------
	public void processUpload() {
		System.debug('processUpload');
		createVehicles(readyRcds, templateVeh);
		if (CreatePoOption!='None') createPurchaseOrders(readyRcds, CreatePoOption, chassisPO, conversionPO);
		for(VehicleUploadWrapper vuw : readyRcds) System.debug(vuw);
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 
			'Created ' + String.valueOf(NewVehicles) + ' vehicle records and ' + String.valueOf(NewPOs) + ' purchase orders'));
		processComplete = true;
		System.debug(processComplete);
	}

	// ResolveGLAccounts
	//-----------------------
	public void ResolveGLAccounts() {
		Set<Id> GLAcctIdsMW = new Set<Id>();

		if (ChassisFFRefs.GeneralLedgerAcct__c!=null) GLAcctIdsMW.add(ChassisFFRefs.GeneralLedgerAcct__c);
		if (ConversionFFRefs.GeneralLedgerAcct__c!=null) GLAcctIdsMW.add(ConversionFFRefs.GeneralLedgerAcct__c);
		if (ChassisContraFFRefs.GeneralLedgerAcct__c!=null) GLAcctIdsMW.add(ChassisContraFFRefs.GeneralLedgerAcct__c);
		if (ConversionContraFFRefs.GeneralLedgerAcct__c!=null) GLAcctIdsMW.add(ConversionContraFFRefs.GeneralLedgerAcct__c);

		Map<Id,GeneralLedgerAcctMW__c> GLAcctMWMap = new Map<Id, GeneralLedgerAcctMW__c>([
			select Id, GeneralLedgerAccountFF__c
			from GeneralLedgerAcctMW__c
			where Id in :GLAcctIdsMW
		]);

		if (ChassisFFRefs.GeneralLedgerAcct__c!=null) ChassisFFRefs.General_Ledger_Account__c = GLAcctMWMap.get(ChassisFFRefs.GeneralLedgerAcct__c).GeneralLedgerAccountFF__c;
		if (ConversionFFRefs.GeneralLedgerAcct__c!=null) ConversionFFRefs.General_Ledger_Account__c = GLAcctMWMap.get(ConversionFFRefs.GeneralLedgerAcct__c).GeneralLedgerAccountFF__c;
		if (ChassisContraFFRefs.GeneralLedgerAcct__c!=null) ChassisContraFFRefs.General_Ledger_Account__c = GLAcctMWMap.get(ChassisContraFFRefs.GeneralLedgerAcct__c).GeneralLedgerAccountFF__c;
		if (ConversionContraFFRefs.GeneralLedgerAcct__c!=null) ConversionContraFFRefs.General_Ledger_Account__c = GLAcctMWMap.get(ConversionContraFFRefs.GeneralLedgerAcct__c).GeneralLedgerAccountFF__c;
	}

	// createVehicles
	public void createVehicles(List<VehicleUploadWrapper> vehs, dealer__Vehicle_Inventory__c template) {
		NewVehicles = 0;
		List<dealer__Vehicle_Inventory__c> vilist = new List<dealer__Vehicle_Inventory__c>();
		for(VehicleUploadWrapper vuw : vehs) {
			vuw.ChassisCost = vuw.Vehicle.dealer__Vehicle_Cost__c;
			vuw.ConversionCost = vuw.Vehicle.Conversion_Cost__c;
			// TODO: Always do the same? or Not?
			if (CreatePoOption=='Chassis') {
				if (POAddCostsToVeh) vuw.Vehicle.dealer__Vehicle_Cost__c = 0;
				//if (POAddCostsToVeh) vuw.Vehicle.Conversion_Cost__c = 0;
			} else if (CreatePoOption=='Conversion') {
				//if (POAddCostsToVeh) vuw.Vehicle.dealer__Vehicle_Cost__c = 0;
				if (POAddCostsToVeh) vuw.Vehicle.Conversion_Cost__c = 0;
			} else if (CreatePoOption=='Combined') {
				if (POAddCostsToVeh) vuw.Vehicle.dealer__Vehicle_Cost__c = 0;
				if (POAddCostsToVeh) vuw.Vehicle.Conversion_Cost__c = 0;
			} else if (CreatePoOption=='Separate') {
				if (POAddCostsToVeh) vuw.Vehicle.dealer__Vehicle_Cost__c = 0;
				if (POAddCostsToVeh) vuw.Vehicle.Conversion_Cost__c = 0;
			} else if (CreatePoOption=='None') {
				//if (POAddCostsToVeh) vuw.Vehicle.dealer__Vehicle_Cost__c = 0;
				//if (POAddCostsToVeh) vuw.Vehicle.Conversion_Cost__c = 0;
			}
			vilist.add(vuw.Vehicle);
		}
		if (vilist.size()>0) System.debug(JSON.serializePretty(vilist[0]));
		Database.SaveResult[] saveresults = new List<Database.SaveResult>();
		saveresults = Database.insert(vilist, false); 

		Map<Id,String> resultmap = new Map<Id,String>();
		System.debug('List of failed updates:');
		for(Integer i=0; i<vilist.size(); i++) {
			dealer__Vehicle_Inventory__c vi = vilist[i];
			VehicleUploadWrapper vuw = vehs[i];
            Database.SaveResult sr = saveresults.size()>i ? saveresults[i] : null;
			if (sr!=null && !sr.isSuccess()) {
				System.debug(vi);
				System.debug(vuw);
				String resultline = resultmap.get(vi.Id);
				String errmsg = '';
				String errmsgline = '';
				for(Database.Error de : sr.getErrors()) {
					errmsgline += '[' + String.join(de.getFields(), ', ') + '] '
						+ de.getMessage() + '\r';
					errmsg += de.getMessage() + '; ';
				}
				System.debug(errmsgline);
				errmsg = errmsg.replaceAll('\\s',' ');
				if (vi.Id!=null && resultline!=null) resultmap.put(vi.Id,resultline+',"Error:'+errmsg+'"');
				if (!String.isBlank(errmsg)) vuw.ErrorMsgs.add(errmsg);
			}
		}


		NewVehicles += vilist.size();

		List<Note> newNotes = new List<Note>();	// BLL1a

		// Debug: Ensure that vehs list copy of vehicle inventory record now contains the new Id!!! and pull the location so we can resolve dimension1
		for(VehicleUploadWrapper vuw : vehs) {
			System.debug(vuw);
			System.debug(vuw.Vehicle);
			//System.assert(vuw.Vehicle.Id!=null, 'Vehicle ' + vuw.Vehicle.dealer__Stock_Number__c + ' was not assigned a salesforce Id');
			if (vuw.Vehicle.Id==null) {
				String errstring = 'Stock# ' + vuw.Vehicle.dealer__Stock_Number__c + ' was not assigned a salesforce Id';
				System.debug(errstring);
				vuw.ErrorMsgs.add(errstring);
			} else {
				// BLL1a
				// duplicate notes
				for(Note n : template.Notes) {
					newNotes.add(new Note(
						Title=n.Title, Body=n.Body, ParentId=vuw.Vehicle.Id
					));
				}
				// BLL1a end
			}
			String dmlerr = resultmap.get(vuw.Vehicle.Id);
			if (!String.isBlank(dmlerr)) vuw.ErrorMsgs.add(dmlerr);
			vuw.errorMsgText = String.join(vuw.errorMsgs, '; ');
			vuw.warningMsgText = String.join(vuw.warningMsgs, '; ');
		}
		if (newNotes.size()>0) insert(newNotes);	// BLL1a
		
	}
	
	// createPurchaseOrders
	//-------------------------------------------
	public void createPurchaseOrders(List<VehicleUploadWrapper> vehs, String poOption, dealer__Purchase_Order__c chassisPO, dealer__Purchase_Order__c conversionPO) {
		boolean needContra = true;
		NewPOs = 0;
				
		String initials = UserInfo.getFirstName().left(1) + UserInfo.getLastName().left(1);
		
		try {
			ResolveGLAccounts();
		} catch(Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid GL Account setup: ' + e.getMessage()));
			haveErrors = true;
			haveGoodData = false; // don't allow processing of any records
		}

		// resolve to created vehicles for location info
		Set<Id> vehIds = new Set<Id>();
		for(VehicleUploadWrapper vuw : vehs) {
			vehIds.add(vuw.Vehicle.Id);
		}
		Map<Id,dealer__Vehicle_Inventory__c> vehMap = new Map<Id,dealer__Vehicle_Inventory__c>();
		vehMap = new Map<Id,dealer__Vehicle_Inventory__c>([
			select Id, Name, dealer__VIN__c, dealer__Stock_Number__c, dealer__Year__c, dealer__Make__c, dealer__Model__c,
					dealer__Vehicle_Cost__c, Conversion_Cost__c, dealer__Store_Location__c, dealer__Store_Location__r.Financial_Force_Dimension_1__c
			from dealer__Vehicle_Inventory__c
			where Id in :vehIds
		]);
	
		// GL Account map
		List<Id> glAcctIds = new List<Id>();
		if (ChassisFFRefs.General_Ledger_Account__c!=null) glAcctIds.add(ChassisFFRefs.General_Ledger_Account__c);
		if (ConversionFFRefs.General_Ledger_Account__c!=null) glAcctIds.add(ConversionFFRefs.General_Ledger_Account__c);
		if (ChassisContraFFRefs.General_Ledger_Account__c!=null) glAcctIds.add(ChassisContraFFRefs.General_Ledger_Account__c);
		if (ConversionFFRefs.General_Ledger_Account__c!=null) glAcctIds.add(ConversionFFRefs.General_Ledger_Account__c);
		Map<Id, GeneralLedgerAcctMW__c> glmap = new Map<Id, GeneralLedgerAcctMW__c>();
		for(GeneralLedgerAcctMW__c glamw : [
			select Id, Name, GeneralLedgerAccountFF__c, GeneralLedgerAccountFF__r.c2g__ReportingCode__c
			from GeneralLedgerAcctMW__c
			where GeneralLedgerAccountFF__c in :glAcctIds
		]) {
			glmap.put(glamw.GeneralLedgerAccountFF__c, glamw);
		}	// end for glamw
		// GL Account map end
		
		List<dealer__Purchase_Order__c> pos = new List<dealer__Purchase_Order__c>();
		Map<Integer,List<dealer__Purchase_Order_Line__c>> polinemap = new Map<Integer,List<dealer__Purchase_Order_Line__c>>();
		//List<dealer__Purchase_Order__c> pos2 = new List<dealer__Purchase_Order__c>();
		//Map<Integer,List<dealer__Purchase_Order_Line__c>> polinemap2 = new Map<Integer,List<dealer__Purchase_Order_Line__c>>();
		Integer vehCount = 0;
		Integer poCount = 0;

		// Record type
		Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Purchase_Order__c.getRecordTypeInfosByName();
		Schema.RecordTypeInfo rtInfo = RcdTypes.get('Vehicle Purchase');
		Id vehRcdType = rtInfo.getRecordTypeId();
		
		dealer__Purchase_Order__c newpo1 = new dealer__Purchase_Order__c();
		dealer__Purchase_Order__c newpo2 = new dealer__Purchase_Order__c();
		if (poOption=='Chassis' || poOption=='Combined' || poOption=='Separate') {
			newpo1.dealer__Vendor__c = chassisPO.dealer__Vendor__c;
			newpo1.RecordTypeId = vehRcdType;
			newpo1.dealer__Status__c = 'Open';
			System.debug(newpo1);
		}
		if (poOption=='Conversion' || poOption=='Separate') {
			newpo2.dealer__Vendor__c = conversionPO.dealer__Vendor__c;
			newpo2.RecordTypeId = vehRcdType;
			newpo2.dealer__Status__c = 'Open';
			System.debug(newpo2);
		}
		List<dealer__Purchase_Order_Line__c> newlines1 = new List<dealer__Purchase_Order_Line__c>();
		List<dealer__Purchase_Order_Line__c> newlines2 = new List<dealer__Purchase_Order_Line__c>();

		System.debug(vehMap);

		// Chassis/Conversion/Combined POs
		for(VehicleUploadWrapper vuw : vehs) {
			vehCount++;
			System.debug(vuw);
			
			dealer__Vehicle_Inventory__c veh = vuw.Vehicle;
			dealer__Vehicle_Inventory__c vehm = vehMap.get(veh.Id);
			System.debug(veh);
			System.debug(vehm);
			
			// BLL3a can only create a PO if the vehicle was created...
			if (vehm!=null) {
				
			// If we've exceeded nbr vehicle per po, create a new PO
			if (vehCount>VehiclesPerPo) {
				// Add current POs & lines & then create new ones
				pos.add(newpo1);
				polinemap.put(poCount++, newlines1);
				if (poOption=='Conversion' || poOption=='Separate') {
					pos.add(newpo2);
					polinemap.put(poCount++, newlines2);
				}	// end Conversion or Separate (use 2nd instance of po & lines)
				
				// New POs & lines for next vehicle(s)
				newpo1 = new dealer__Purchase_Order__c();
				newlines1 = new List<dealer__Purchase_Order_Line__c>();
				newpo2 = new dealer__Purchase_Order__c();
				newlines2 = new List<dealer__Purchase_Order_Line__c>();
				System.debug(newpo1);
				System.debug(newpo2);
				System.debug(poOption);
				if (poOption=='Chassis' || poOption=='Combined' || poOption=='Separate') {
					newpo1.dealer__Vendor__c = chassisPO.dealer__Vendor__c;
					newpo1.RecordTypeId = vehRcdType;
					newpo1.dealer__Status__c = 'Open';
					System.debug(newpo1);
				}
				if (poOption=='Conversion' || poOption=='Separate') {
					newpo2.dealer__Vendor__c = conversionPO.dealer__Vendor__c;
					newpo2.RecordTypeId = vehRcdType;
					newpo2.dealer__Status__c = 'Open';
					System.debug(newpo2);
				}
				vehCount = 1;	// Starting over, Current vehicle will be the first one on next new PO
			} // poCount>VehiclePerPo
			
			// set po location
			newpo1.dealer__Company__c = vehm.dealer__Store_Location__c;
			newpo2.dealer__Company__c = vehm.dealer__Store_Location__c;
			
			dealer__Purchase_Order_Line__c chassisline = new dealer__Purchase_Order_Line__c();
			dealer__Purchase_Order_Line__c chassiscontraline = new dealer__Purchase_Order_Line__c();
			dealer__Purchase_Order_Line__c conversionline = new dealer__Purchase_Order_Line__c();
			dealer__Purchase_Order_Line__c conversioncontraline = new dealer__Purchase_Order_Line__c();
			
			// store VIN, Stock#, make, model, etc. in different fields (header) when it's 1-for-1 vehicle to PO
			if (VehiclesPerPO==1) {
				if (poOption=='Chassis' || poOption=='Combined' || poOption=='Separate') assignVehToPO(newpo1, veh);
				if (poOption=='Conversion' || poOption=='Separate') assignVehToPO(newpo2, veh);
			} else {	// Store vehicle reference info on the PO line instead
				if (poOption=='Chassis' || poOption=='Combined' || poOption=='Separate') assignVehToPOLine(chassisline, veh);
				if (poOption=='Conversion' || poOption=='Separate') assignVehToPOLine(conversionline, veh);
			}

			chassisline.dealer__Description__c = initials + ' upload';
			chassisline.dealer__Amount__c = vuw.ChassisCost;
			chassisline.General_Ledger_Account__c = ChassisFFRefs.General_Ledger_Account__c;
			chassisline.Dimension_1__c = vehm.dealer__Store_Location__r.Financial_Force_Dimension_1__c;
			if (POAddCostsToVeh) chassisline.Add_to_Chassis__c = true;

			conversionline.dealer__Description__c = initials + ' upload';
			conversionline.dealer__Amount__c = vuw.ConversionCost;
			conversionline.General_Ledger_Account__c = ConversionFFRefs.General_Ledger_Account__c;
			conversionline.Dimension_1__c = vehm.dealer__Store_Location__r.Financial_Force_Dimension_1__c;
			if (POAddCostsToVeh) conversionline.Add_to_Conversion__c = true;

			System.debug(vuw);
			System.debug(chassiscontraline);
			if (needContra) {
				chassiscontraline.dealer__Description__c = initials + ' upload';
				chassiscontraline.dealer__Amount__c = (vuw.ChassisCost!=null) ? -vuw.ChassisCost : 0;
				chassiscontraline.General_Ledger_Account__c = ChassisContraFFRefs.General_Ledger_Account__c;
				chassiscontraline.Dimension_1__c = vehm.dealer__Store_Location__r.Financial_Force_Dimension_1__c;
				if (ChassisContraFFRefs.Dimension_1__c!=null) chassiscontraline.Dimension_1__c = ChassisContraFFRefs.Dimension_1__c;

				if (poOption=='Combined')
					chassiscontraline.dealer__Amount__c -= (vuw.ConversionCost!=null) ? vuw.ConversionCost : 0;
				else {
					conversioncontraline.dealer__Description__c = initials + ' upload';
					conversioncontraline.dealer__Amount__c = (vuw.ConversionCost!=null) ? -vuw.ConversionCost : 0;
					conversioncontraline.General_Ledger_Account__c = ConversionContraFFRefs.General_Ledger_Account__c;
					conversioncontraline.Dimension_1__c = vehm.dealer__Store_Location__r.Financial_Force_Dimension_1__c;
					if (ConversionContraFFRefs.Dimension_1__c!=null) conversioncontraline.Dimension_1__c = ConversionContraFFRefs.Dimension_1__c;
				}	// end not combined
			}	// end needContra

			if (poOption=='Chassis' || poOption=='Combined' || poOption=='Separate') newlines1.add(chassisline);
			if (poOption=='Combined') newlines1.add(conversionline);
			if (poOption=='Conversion' || poOption=='Separate') newlines2.add(conversionline);
			if (needContra && (poOption=='Chassis' || poOption=='Combined' || poOption=='Separate')) newlines1.add(chassiscontraline); 
			if (needContra && (poOption=='Conversion' || poOption=='Separate')) newlines2.add(conversioncontraline);
			
			} // BLL3a end only create po if vehicle was created
			
		}	// end for vehs 

		pos.add(newpo1);
		polinemap.put(poCount++, newlines1);
		if (poOption=='Conversion' || poOption=='Separate') {
			pos.add(newpo2);
			polinemap.put(poCount++, newlines2);
		}	// end Conversion or Separate (use 2nd instance of po & lines)
		
		// Insert all POs
		for(dealer__Purchase_Order__c po : pos) System.debug(po);
		insert(pos);
		NewPOs += pos.size();
		
		Set<Id> poids = new Set<Id>();
		for(dealer__Purchase_Order__c po : pos) poids.add(po.Id);
		
		// get map so we can retrieve assigned po numbers
		Map<Id, dealer__Purchase_Order__c> pomap = new Map<Id, dealer__Purchase_Order__c>([
			select Id, Name, dealer__PO_Number__c, dealer__VIN__c, dealer__StockNumber__c, dealer__PO_Accounting_Name__c
			from dealer__Purchase_Order__c
			where Id in :poids
		]);
		
		// Assign PO ids to related lines and insert
		List<dealer__Purchase_Order_Line__c> allLines = new List<dealer__Purchase_Order_Line__c>();
		for(Integer i=0; i<pos.size(); i++) {
			dealer__Purchase_Order__c po = pos[i];
			dealer__Purchase_Order__c poname = pomap.get(po.Id);
			List<dealer__Purchase_Order_Line__c> lines = polinemap.get(i);
			for(dealer__Purchase_Order_Line__c l : lines) {
				l.dealer__Purchase_Order__c = po.Id;
				l.dealer__Description__c = 'PO#' + poname.dealer__PO_Number__c + ' ' + l.dealer__Description__c;
				l.GeneralLedgerAcct__c = glmap.get(l.General_Ledger_Account__c).Id;
			}
			alllines.addAll(lines);
		}	// end for each po (assign lines to created po records)
		insert(alllines);

		// Map stock nbrs to POs
		StockNbrPOMap = new Map<String, dealer__Purchase_Order__c>();
		StockNbrPOMap2 = new Map<String, dealer__Purchase_Order__c>();
		for(dealer__Purchase_Order__c po : pomap.values()) {
			if (!StockNbrPOMap.containsKey(po.dealer__StockNumber__c)) StockNbrPOMap.put(po.dealer__StockNumber__c, po);
			else StockNbrPOMap2.put(po.dealer__StockNumber__c, po);
		}
		System.debug(StockNbrPOMap);
		if (readyRcds.size()>0) System.debug(readyRcds[0].Vehicle);
		// Link vehicle wrapper records to created POs
		for(VehicleUploadWrapper vuw : vehs) {
			dealer__Purchase_Order__c po = StockNbrPOMap.get(vuw.Vehicle.dealer__Stock_Number__c);
			dealer__Purchase_Order__c po2 = StockNbrPOMap2.get(vuw.Vehicle.dealer__Stock_Number__c);
			if (po!=null) {
				vuw.PONumber = po.dealer__PO_Accounting_Name__c;
				vuw.POId = po.Id;
			}
			if (po2!=null) {
				vuw.PONumber2 = po2.dealer__PO_Accounting_Name__c;
				vuw.POId2 = po2.Id;
			}
			System.debug(po);
			System.debug(po2);
			System.debug(vuw);
		}

		CreatedPurchaseOrders = new List<dealer__Purchase_Order__c>();
		CreatedPurchaseOrders.addAll(pos);
		
	}	// end createPurchaseOrders 


	// assignVehToPO
	public void assignVehToPO(dealer__Purchase_Order__c po, dealer__Vehicle_Inventory__c veh) {
		po.dealer__VIN__c = veh.dealer__VIN__c;
		po.dealer__StockNumber__c = veh.dealer__Stock_Number__c;
		po.dealer__Year__c = veh.dealer__Year__c;
		po.dealer__Make__c = veh.dealer__Make__c;
		po.dealer__Model__c = veh.dealer__Model__c;
		po.dealer__Vehicle_Inventory__c = veh.Id;
	}


	// assignVehToPOLine - not implemented (yet)
	public void assignVehToPOLine(dealer__Purchase_Order_Line__c line, dealer__Vehicle_Inventory__c veh) {
		//line.VIN__c = veh.dealer__VIN__c;
		//line.StockNumber__c = veh.dealer__Stock_Number__c;
		//line.Year__c = veh.dealer__Year__c;
		//line.Make__c = veh.dealer__Make__c;
		//line.Model__c = veh.dealer__Model__c;
		//line.Vehicle_Inventory__c = veh.Id;
	}



	// ValidateVehicleUpload
	//----------------------------------------
	public void ValidateVehicleUpload(List<VehicleUploadWrapper> vehList) {
		User u = CurrentUserSingleton.getInstance();
		dealer__Dealer_Location__c dftloc = null;
		try {
			if (u!=null && !String.isBlank(u.Division)) dftloc = [select Id, Name, dealer__Company_Number__c from dealer__Dealer_Location__c where dealer__Company_Number__c=:u.Division limit 1];
		} catch(Exception e) {System.debug(e);}
		
		errorRcds = new List<VehicleUploadWrapper>();
		readyRcds = new List<VehicleUploadWrapper>();

		haveErrors = false;
		//if (CreatePoOption==null) {
		//	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'You must specify the PO creation option'));
		//	haveErrors = true;
		//	haveData = false;
		//}
		boolean requireChassisCost = CreatePoOption!=null && CreatePoOption!='None' && CreatePoOption!='Conversion';
		boolean requireConversionCost = CreatePoOption!=null && CreatePoOption!='None' && CreatePoOption!='Chassis';

		Set<String> newstocknbrs = new Set<String>();
		for(VehicleUploadWrapper vuw : vehList) {
			dealer__Vehicle_Inventory__c v = vuw.Vehicle;
			if (!String.isBlank(v.dealer__Stock_Number__c)) newstocknbrs.add(v.dealer__Stock_Number__c);
		}
		// check for existing stock numbers
		Map<String,dealer__Vehicle_Inventory__c> vehMap = new Map<String,dealer__Vehicle_Inventory__c>();
		for(dealer__Vehicle_Inventory__c v : [
			select Id, Name, dealer__Stock_Number__c, dealer__VIN__c
			from dealer__Vehicle_Inventory__c 
			where dealer__Stock_Number__c in :newstocknbrs
		]) {
			vehMap.put(v.dealer__Stock_Number__c, v);
		}

		// Audit vehicles to insert, dividing into errors & ready lists
		for(VehicleUploadWrapper vuw : vehList) {
			dealer__Vehicle_Inventory__c v = vuw.Vehicle;
			if (v.dealer__Store_Location__c==null && dftloc!=null) v.dealer__Store_Location__c = dftloc.Id;
			
			// validate stock nbr
			if (String.isBlank(v.dealer__Stock_Number__c)) {
				vuw.errorMsgs.add('Record missing stock number: ' + v.dealer__VIN__c + ', ' + v.dealer__Year__c + ' ' + v.dealer__Make__c + v.dealer__Model__c);
			} else if (vehMap.containsKey(v.dealer__Stock_Number__c)) {
				dealer__Vehicle_Inventory__c existingveh = vehMap.get(v.dealer__Stock_Number__c);
				if (existingveh.Id==null) vuw.errorMsgs.add('Stock number ' + v.dealer__Stock_Number__c + ' already assigned in this upload ' + existingveh.dealer__VIN__c);
				if (existingveh.Id!=null) vuw.errorMsgs.add('Stock number ' + v.dealer__Stock_Number__c + ' already used on inventory VIN ' + existingveh.dealer__VIN__c + ': ' + existingveh.Name);
			}
			
			// validate costs required
			if (requireChassisCost && (v.dealer__Vehicle_Cost__c==null || v.dealer__Vehicle_Cost__c<=0)) vuw.errorMsgs.add('Chassis cost is required and must be greater than 0');
			if (requireConversionCost && (v.Conversion_Cost__c==null || v.Conversion_Cost__c<=0)) vuw.errorMsgs.add('Conversion cost is required and must be greater than 0');
			
			vuw.errorMsgText = String.join(vuw.errorMsgs, '; ');
			vuw.warningMsgText = String.join(vuw.warningMsgs, '; ');
			if (vuw.errorMsgs.size()==0) {
				readyRcds.add(vuw);
				// planning to be an inventory record, so add to map to enable check for same stock# twice in upload!
				vehMap.put(vuw.Vehicle.dealer__Stock_Number__c, vuw.Vehicle);
			} else errorRcds.add(vuw);
		}
		haveGoodData = readyRcds.size()>0;
		haveErrors = haveErrors || errorRcds.size()>0;

	}

	// CreateVehicleList - from the csv data, matching up csv columns to Vehicle Inventory fields (by field name or label)
	//----------------------------------------
	public List<VehicleUploadWrapper> CreateVehicleList(String data) {
		return CreateVehicleList(data, new dealer__Vehicle_Inventory__c());
	}
	public List<VehicleUploadWrapper> CreateVehicleList(String data, dealer__Vehicle_Inventory__c templateVeh) {
		// BLL2a Get user's default record type...
		Schema.DescribeSObjectResult dsr = dealer__Vehicle_Inventory__c.SObjectType.getDescribe();
		for(Schema.RecordTypeInfo rti : dsr.getRecordTypeInfos()) {
    		if(rti.isDefaultRecordTypeMapping()) {
        		DftRtInfo = rti;
    		}
		}
		// BLL2a end

		List<VehicleUploadWrapper> newVehs = new List<VehicleUploadWrapper>();
 		ParseCSV csv = ParseCSV.StrictParser();
 		csv.debug = true;
		// System.debug(data);
		csv.setCsvData(data);
 		csvmap = csv.getRowsMapByColumnName();
 		System.debug(csvmap.size());
		csvColNames = csv.getColumnNames();
		System.debug(csvColNames);
		unrecognizedColumns = new Set<String>();
		
		// Build fnMap, lblMap, RefToMap, RefFldMap (see global declare for info on these)
		// also maps of valid picklist values for fields included in csv file
		BuildFieldMaps();

		//// load up FF reference maps...
		//loadLocationMap();
		//loadFFMaps();
		
		// Map each csv row to a new vehicle inventory records
		// For each row in CSV ...
		for(Map<String,String> row : csvmap.values()) {
			mappingerrors = 0;
			dealer__Vehicle_Inventory__c veh = MapColValuesToNewVeh(row, templateVeh);
			System.debug(veh);
			VehicleUploadWrapper viw = new VehicleUploadWrapper(veh);
			if (mappingerrors>0) {
				viw.ErrorMsgs.add('Field mapping errors (' + String.valueOf(mappingerrors) + ')');
			}
			newVehs.add(viw);
		}
		System.debug(newVehs.size());
		return newVehs;
	}


	// MapColValuesToNewVeh
	//-----------------------------------
	public dealer__Vehicle_Inventory__c MapColValuesToNewVeh(Map<String,String> row, dealer__Vehicle_Inventory__c templateVeh) {
		Set<String> TrueValues = new Set<String>{'1','true','yes'};
		dealer__Vehicle_Inventory__c rtnVehicle = templateVeh.clone(false, true, false, false);
		// Ensure certain required fields are specified in the upload by removing them from the cloned template
		rtnVehicle.dealer__VIN__c = null;
		rtnVehicle.dealer__Stock_Number__c = null;
		rtnVehicle.dealer__Status_Code_Assignment_Date__c = Date.today();	// BLL2a
		// ensure Id and record type Id doesn't come from template (default='Used')
		//BLL2d VehRcdTypes = Schema.SObjectType.dealer__Vehicle_Inventory__c.getRecordTypeInfosByName();
		//BLL2d UsedRtInfo = VehRcdTypes.get('Used');
		//BLL2d rtnVehicle.RecordTypeId = UsedRtInfo.getRecordTypeId();
		rtnVehicle.RecordTypeId = DftRtInfo.getRecordTypeId();	// BLL2a
		rtnVehicle.Id = null;

		System.debug('Field type names & ordinals checked:');
		System.debug(Schema.DisplayType.Reference.name() + ':' + Schema.DisplayType.Reference.ordinal());
		System.debug(Schema.DisplayType.Integer.name() + ':' + Schema.DisplayType.Integer.ordinal());
		System.debug(Schema.DisplayType.Currency.name() + ':' + Schema.DisplayType.Currency.ordinal());
		System.debug(Schema.DisplayType.Double.name() + ':' + Schema.DisplayType.Double.ordinal());
		System.debug(Schema.DisplayType.Percent.name() + ':' + Schema.DisplayType.Percent.ordinal());
		System.debug(Schema.DisplayType.Date.name() + ':' + Schema.DisplayType.Date.ordinal());
		System.debug(Schema.DisplayType.Time.name() + ':' + Schema.DisplayType.Time.ordinal());
		System.debug(Schema.DisplayType.DateTime.name() + ':' + Schema.DisplayType.DateTime.ordinal());
		
		// set fields based on csv upload data...
		for(String k : row.keySet()) {
			String colName = k.toLowerCase();
			//System.debug(colName);
			String dataval = row.get(colName);
			Schema.DescribeFieldResult dfr;
			if (fnMap.containsKey(colName)) dfr = fnMap.get(colName);
			else if (lblMap.containsKey(colName)) dfr = lblMap.get(colName);
			//System.debug(dfr);
				
			// Map data val to object field ...
			//System.debug(refFldMap);
			if (dfr!=null) {
				if (!String.isBlank(dataval)) {
					Schema.DisplayType fldType = dfr.getType();
					System.debug(fldType);
					System.debug(fldType.name());
					System.debug(fldType.ordinal());
					try {
						if (fldType==Schema.DisplayType.Reference) {
							Map<String,Id> nameMap = refFldMap.get(dfr.getName().toLowerCase());
							//System.debug(dfr.getName());
							//System.debug(nameMap.get(dataval));
							if (nameMap!=null && nameMap.containsKey(dataval)) rtnVehicle.put(dfr.getName(), nameMap.get(dataval));
						} else if (fldType==Schema.DisplayType.Integer) {
							rtnVehicle.put(dfr.getName(), Integer.valueOf(dataval));
						} else if (fldType==Schema.DisplayType.Currency) {
							rtnVehicle.put(dfr.getName(), Decimal.valueOf(dataval));
						} else if (fldType==Schema.DisplayType.Double) {
							rtnVehicle.put(dfr.getName(), Decimal.valueOf(dataval));
						} else if (fldType==Schema.DisplayType.Boolean) {
							boolean boolval = dataval!=null && TrueValues.contains(dataval.toLowerCase());
							rtnVehicle.put(dfr.getName(), boolval);
						} else if (fldType==Schema.DisplayType.Percent) {
							rtnVehicle.put(dfr.getName(), Decimal.valueOf(dataval));
						} else if (fldType==Schema.DisplayType.Date) {
							Date dateval;
							try {
								dateval = Date.valueOf(dataval);
							} catch(Exception e) {
								try {
									dateval = Date.parse(dataval);
								} catch(Exception e2) {}
							}
							rtnVehicle.put(dfr.getName(), dateval);
						} else if (fldType==Schema.DisplayType.DateTime) {
							DateTime datetimeval;
							try {
								datetimeval = DateTime.valueOf(dataval);
							} catch(Exception e) {
								try {
									datetimeval = DateTime.parse(dataval);
								} catch(Exception e2) {}
							}
							rtnVehicle.put(dfr.getName(), datetimeval);
						} else if (fldType==Schema.DisplayType.Time) {
							Time timeval;
							List<String> hms = dataval.split(':');
							if (hms.size()==3) {
								List<String> seconds = hms[2].split('.');
								timeval = Time.newInstance(Integer.valueOf(hms[0]), Integer.valueOf(hms[1]), Integer.valueOf(seconds[0]), 
									(seconds.size()==2) ? Integer.valueOf(seconds[1]) : 0);
							}
							rtnVehicle.put(dfr.getName(), timeval);
						} else if (fldType==Schema.DisplayType.Picklist) {
							Map<String,String> plvMap = picklistFldMap.get(dfr.getName().toLowerCase());
							if (plvMap!=null) {
								String plval = plvMap.get(dataval);
								if (plval!=null) rtnVehicle.put(dfr.getName(), plval);
								else { 
									mappingerrors++;
									ApexPages.addMessage(new ApexPAges.Message(ApexPages.Severity.ERROR,
										'Invalid picklist value "' + dataval + '" for field ' + dfr.getLabel() + ' (' + dfr.getName() + ')'));
								}
							}
						} else if (fldType==Schema.DisplayType.Picklist || fldType==Schema.DisplayType.MultiPicklist) {
							Map<String,String> plvMap = picklistFldMap.get(dfr.getName().toLowerCase());
							if (plvMap!=null) {
								List<String> datavals = dataval.split(';');
								Set<String> plset = new Set<String>();
								for(String d : datavals) {
									if (plvMap.containsKey(d)) {
										plset.add(plvMap.get(d));
									} else {
										mappingerrors++;
										ApexPages.addMessage(new ApexPAges.Message(ApexPages.Severity.ERROR,
											'Invalid picklist value "' + d + '" for field ' + dfr.getLabel() + ' (' + dfr.getName() + ')'));
									}
								}
								dataval = String.join(new List<String>(plset), ';');
								rtnVehicle.put(dfr.getName(), dataval);
							}
						} else {
							rtnVehicle.put(dfr.getName(), dataval);
						}
					} catch(Exception err) {
						mappingerrors++;
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
							'Error mapping field ' + dfr.getName() + ' (' + fldtype.name() + ') : ' + err.getMessage()));
					}
				}
			} else unrecognizedColumns.add(colName);

		}	// end for row.keySet
		return rtnVehicle;
		
	}	// end MapColValuesToNewVeh


	// BuildFieldMaps
	//------------------------------------
	public void BuildFieldMaps() {
		fnMap = new Map<String, Schema.DescribeFieldResult>();
		lblMap = new Map<String, Schema.DescribeFieldResult>();
		
		// vehicle inventory object field map by field name 
		Map<String, Schema.SObjectField> viFieldMap =  Schema.dealer__Vehicle_Inventory__c.SObjectType.getDescribe().fields.getMap();
		
    	// Select all fields from {sobject}
		for(Schema.SObjectField f : viFieldMap.values()) {
			Schema.DescribeFieldResult dfr = f.getDescribe();
			//if (dfr.isAccessible()) {
			if (dfr.isCreateable()) {
				String fldnamelc = dfr.getName().toLowerCase();
				String fldlabellc = dfr.getLabel().toLowerCase();
				
				fnMap.put(fldnamelc, dfr);
				
				// Only use the first instance encounered if there are duplicate field labels
				// csv should use field names for any duplicated labels to ensure consistent/predictable results
				if (!lblMap.containsKey(fldlabellc)) lblMap.put(fldlabellc, dfr);
				
				// Build list of reference fields that need resolution
				Schema.DisplayType fldType = dfr.getType();
				String colName = csvColNames.contains(fldnamelc) ? fldnamelc : fldlabellc;
				if (csvColNames.contains(colName)) {
					if (fldType==Schema.DisplayType.Reference) {
						// Build list of all reference names to lookup 
						Map<String,Id> nameIdMap = new Map<String,Id>();
						for(Map<String,String> row : csvmap.values()) {
							String dataval = row.get(colName);
							if (!String.isBlank(dataval)) {
								if (!nameIdMap.containsKey(dataval)) nameIdMap.put(dataval,null);
							}
						}
						if (nameIdMap.size()>0) {
							refToMap.put(fldnamelc, dfr.getReferenceTo()[0]);
							refFldMap.put(fldnamelc, nameIdMap);
						}
					}	// end if Reference field
					// Build map of valid picklist values - allow xls to specify label *or* value
					if (fldType==Schema.DisplayType.Picklist || fldTYpe==Schema.DisplayType.MultiPicklist) {
						List<Schema.PicklistEntry> plvs = dfr.getPicklistValues();
						Map<String,String> plvMap = new Map<String,String>();
						for(Schema.PicklistEntry p : plvs) {
							plvMap.put(p.getLabel(), p.getValue());
							plvMap.put(p.getValue(), p.getValue());
						}
						picklistFldMap.put(fldnamelc, plvMap);
					}
				}	// end if field included in csv file
			}	// end if field is createable
		}	// end for each field in object

		// Resolve Names to Ids for all csv values in reference field columns
		BuildNameIdMaps();

	}	// end BuildFieldMaps


	// BuildNameIdMaps
	//---------------------------------------
	public void BuildNameIdMaps() {
		
		// Get Name/Id pairs for every needed reference field lookup
		for(String fld : refToMap.keySet()) {
			Schema.sObjectType objType = refToMap.get(fld);
			Schema.DescribeSObjectResult dsr = objType.getDescribe(); 
			Map<String,Id> nameIdMap = refFldMap.get(fld);
			if (nameIdMap!=null && nameIdMap.size()>0) {
				Set<String> nameset = nameIdMap.keySet();
				List<String> namelist = new List<String>(nameset);
				String nameliststr = '';
				if (namelist.size()>0) nameliststr = '\'' + String.join(namelist, '\',\'') + '\'';
				String soql = 'select Id, Name from ' + dsr.getName() 
					+ ' where Name in (' + nameliststr + ') ';
				if (dsr.getName()=='RecordType') soql += ' and SObjectType=\'dealer__Vehicle_Inventory__c\' ';
				System.debug(soql);
				for(Sobject o : Database.query(soql)) {
					nameIdMap.put((String) o.get('Name'), (Id) o.get('Id'));
				}
				refFldMap.put(fld,nameIdMap);
			}
		}
		// end Get Name/Id pairs for reference fields
	}


	// AcceptVehiclePOs
	//------------------------------
	public void AcceptVehiclePOs() {
		List<String> payloads = new List<String>();
		for(dealer__Purchase_Order__c po : CreatedPurchaseOrders) {
			payloads.add('{"recordId" : "'+po.Id+'", "orgId" : "'+UserInfo.getOrganizationId()+'", "requestedBy" : "'+UserInfo.getUserId()+'", "action" : "accept_purchase_order"}');
		}
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Submitted ' + String.valueOf(payloads.size()) + ' Vehicle Purchase Orders to be Accepted'));
        FFAccounting.emailAsyncHandler(payloads);
        CreatedPurchaseOrders.clear();
	}


	// VehicleUploadWrapper
	//----------------------------------
	public class VehicleUploadWrapper {
		public dealer__Vehicle_Inventory__c Vehicle {get;set;}
		public Integer RowNbr {get;private set;}
		public Decimal ChassisCost {get;private set;}
		public Decimal ConversionCost {get;private set;}
		public List<String> warningMsgs {get;set;}
		public List<String> errorMsgs {get;set;}
		public String warningMsgText {get;set;}
		public String errorMsgText {get;set;}
		public Id POId {get;set;}
		public String PONumber {get;set;}
		public Id POId2 {get;set;}
		public String PONumber2 {get;set;}
		public VehicleUploadWrapper(dealer__Vehicle_Inventory__c v) {
			Vehicle = v;
			ChassisCost = v.dealer__Vehicle_Cost__c;
			ConversionCost = v.Conversion_Cost__c;
			warningMsgs = new List<String>();
			errorMsgs = new List<String>();
		}
	}

}