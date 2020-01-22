/**
 * VehicleFlooring_CTRL
 * Tested by: VehicleFlooring_CTRL_TEST
 * 
 * Payoff columns: SERIAL_NBR=VIN, STOCK_NBR=StockNbr, PMT_AMT=Amt to pay (on journal, audit to current floored amt)
 *
 * Flooring columns: CLTR_CD=>determine floorplan, PRINC_RQST_AMT=CurrentAmt, ORIG_AMT_RQST=OriginalAmt, STOCK_NBR=StockNbr, VIN_NBR=VIN
 *	 CLTR_CD values: TRADEB, TRADE12, TRADEAUTO, USED12, USEDB, USEDAUTO, NEW, NEWAUTO
 *
 * Curtailment columns: serial_nbr, stock_nbr, pmt_amt, curr_princ_amt 
 *
 *	Code coverage:
 *	2018-03-20	83% (287/342)
 *	2018-03-26	89% (406/455)
 *	2018-07-02	86% (426/490)
 *	2018-08-16	87% (429/493)
 *
 *	2018-07-02	B. Leaman	Remove spaces from VIN (TCF).
 *	2018-08-15	B. Leaman	BLL2 - Support for bank account line type on 1001 GL account.
 *	2019-06-28	B. Leaman	BLL3 - Transitworks name change and Conv Mfg.
 *
 */
public with sharing class VehicleFlooring_CTRL {

	public static final Integer JOURNAL_THRESHHOLD = 249;
	
	public String uploadType {get;set;}
    public Blob uploadData {get;set;}
    public String uploadFilename {get;set;}
    public boolean haveData {get;private set;}
    public boolean haveGoodData {get;private set;}
    public boolean dataSubmitted {get;private set;}
    public List<FlooringUploadData> FlooringData {get;private set;}
    public List<FlooringUploadData> FlooringErrors {get;private set;}
    public Decimal TotalAmount {get;private set;}
    public Decimal TotalErrAmount {get;private set;}

    private transient Map<Integer,FlooringUploadData> FlooringRequest;
    private List<String> columnNames;
    private boolean csvError;

    private static List<String> neededGlAccts = new List<String>{'1001'};
    private static Map<String,String> floorplanGlMap = new Map<String,String>{
    	'Huntington New'=>'2515',
    	'Huntington Rental'=>'2510',
    	'Huntington Used'=>'2500',
    	'Huntington PPV'=>'2505'
    };
    private static Map<String,String> NUMfgFloorplanMap = new Map<String,String>{
    	'AMS'=>'Other',
    	'BraunAbility'=>'Braun',
    	'VMI'=>'VMI',
    	'TransitWorks'=>'MBW-Rev',	// BLL3 obsolete now
		'Driverge'=>'MBW-Rev',	// BLL3a 
		'MobilityWorks'=>'MBW-Rev'	// BLL3a (actually using this one)
    };
    
    
	// constructor
	//---------------------------
	public VehicleFlooring_CTRL() {
		haveData = false;
		haveGoodData = false;
		dataSubmitted = false;
    }

	// saveUploadType
	public void saveUploadType() {
		System.debug(uploadType);
		//uploadType = uploadType;
	}

	// startOver
	public void startOver() {
		haveData = false;
		haveGoodData = false;
		uploadFilename = null;
		uploadData = null;
		dataSubmitted = false;
		FlooringData = null;
		FlooringErrors = null;
		TotalAmount = 0.00;
		TotalErrAmount = 0.00;
	}

	// submitCSV
	public void submitCSV() {
		TotalAmount = 0.00;
		TotalErrAmount =  0.00;
		csvError = false;
		if (uploadData==null) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must select aCSV file to upload.'));
			csvError = true;
		} 
		System.debug(uploadType);
		//if (ApexPages.currentPage().getParameters().containsKey('uploadType'))
		//	uploadType=ApexPages.currentPage().getParameters().get('uploadType');
		//System.debug(uploadType);

		ParseCSV parser = ParseCSV.StrictParser();
	    FlooringRequest = new Map<Integer,FlooringUploadData>();
		try {
			parser.setCsvData(uploadData.toString());
			columnNames = parser.getColumnNames();
			Map<Integer,Map<String,String>> csv = parser.getRowsMapByColumnName();
			if (csv!=null) System.debug(csv.get(1));	// debug first row retrieved

			// Reads csv data, audits, and places requests in "FlooringRequest" map by row#
			if (uploadType=='payoff') prepPayoffVehicles(csv);
			else if (uploadType=='floored') prepFlooredVehicles(csv);
			else if (uploadType=='curtailment') prepCurtailmentVehicles(csv);
			else {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Internal error: Unrecognized upload type: ' + uploadType));
				csvError = true;
			}

			// Place each csv record requested in either FlooringErrors or FlooringData list for display & review
			FlooringData = new List<FlooringUploadData>();
			FlooringErrors = new List<FlooringUploadData>();

			for(Integer r : FlooringRequest.keySet()) {
				FlooringUploadData fud = FlooringRequest.get(r);
				if (fud==null) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Internal Error: Did not find request data for row ' + String.valueOf(r)));
				else {
					// Additional audits...
					if (fud.VehId==null) fud.ErrorMsgs += 'Vehicle Inventory record not found. ';
					if (fud.VIN!=null && fud.VIN.length()<=7) fud.ErrorMsgs = 'Invalid VIN';
					if (fud.VehId==null) System.debug('Missing VIN: ' + fud.VIN);
					// Disposition of request row -- valid to process or not
					if (String.isBlank(fud.ErrorMsgs)){
						FlooringData.add(fud);
						TotalAmount += uploadType=='floored' ? fud.FlooredAmt : fud.PaymentAmt;
					} else {
						FlooringErrors.add(fud);
						TotalErrAmount += uploadType=='floored' ? fud.FlooredAmt : fud.PaymentAmt;
					}
					FlooringRequest.remove(r);
				}
			}
			haveGoodData = FlooringData.size()>0;

		} catch(Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error parsing csv data: ' + e.getMessage()));
			csvError = true;
		}
		uploadData = null;
	}
	
	
	// prepPayoffVehicles
	private void prepPayoffVehicles(Map<Integer,Map<String,String>> csv) {
		List<String> missingColumns = new List<String>();
		if (!columnNames.contains('serial_nbr')) missingColumns.add('serial_nbr');
		if (!columnNames.contains('stock_nbr')) missingColumns.add('stock_nbr');
		if (!columnNames.contains('pmt_amt')) missingColumns.add('pmt_amt');
		if (missingColumns.size()>0) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Selected csv file is missing columns: ' + String.join(missingColumns, ', ')));
			csvError = true;
		}
		if (!csvError) {
			haveData = true;
		}
		auditCsvDataPayoff(csv);
	}
	
	// auditCsvDataPayoff
	public void auditCsvDataPayoff(Map<Integer,Map<String,String>> csvMap) {
		// Build list of VINs and template of data for display/audit
		Map<String,Integer> vinRowMap = new Map<String,Integer>();
		for(Integer r : csvMap.keySet()) {
			Map<String,String> rowdata = csvMap.get(r);
			String vin = rowdata.get('serial_nbr');
			if (vin==null) System.debug(csvMap.get(r));
			if (!String.isBlank(vin)) {
				vin = vin.remove(' ');	// BLL1a
				FlooringUploadData fud = new FlooringUploadData(r,vin);
				String pmt_amt = rowdata.get('pmt_amt');
				Decimal pmt = Decimal.valueOf(pmt_amt);
				fud.PaymentAmt = pmt;
				if (!vinRowMap.containsKey(vin)) vinRowMap.put(vin,r);
				else fud.ErrorMsgs += 'Duplicate VIN in csv data - skipped. ';
				FlooringRequest.put(r,fud);
			}
		}

		// retrieve all referenced vehicles by VIN, fill in data for display/audit
		for(dealer__Vehicle_Inventory__c veh : [
			select Id, Name, dealer__VIN__c, dealer__Stock_Number__c, New_Used_Other__c,
				Floorplanned__c, Chassis_Floorplan__c, Chassis_Floored_Date__c, Conversion_Floorplan__c, Conv_Floored_Date__c,   
				Original_Floored_Amount__c, Current_Floored_Amount__c, Paid__c
			from dealer__Vehicle_Inventory__c
			where dealer__VIN__c in :vinRowMap.keySet() and RecordType.Name!='Vehicle Template' and RecordType.Name!='Archived'
			order by dealer__VIN__c, Chassis_Floored_Date__c desc NULLS LAST
		]) {
			Integer row = vinRowMap.get(veh.dealer__VIN__c);
			if (row!=null && row!=0 && FlooringRequest.containsKey(row) && csvMap.containsKey(row)) {
				Map<String,String> rowdata = csvMap.get(row);
				FlooringUploadData fud = FlooringRequest.get(row);
				
				if (fud.VehId==null || fud.VehId==veh.Id || !String.isBlank(fud.ErrorMsgs)) {
					// first vehicle found for this VIN had errors, so reset to this occurance
					if (fud.VehId!=veh.Id && !String.isBlank(fud.ErrorMsgs)) {
						fud.WarningMsgs += ' Multiple vehicles for VIN: ' + fud.StockNbr + '. ';
						fud.ErrorMsgs = '';
					}
					fud.VehId = veh.Id;
					fud.Name = veh.Name;
					fud.StockNbr = veh.dealer__Stock_Number__c;
					fud.NewUsedOther = veh.New_Used_Other__c;
					fud.Floorplan = veh.Chassis_Floorplan__c;
					fud.Floorplanned = veh.Floorplanned__c;
					fud.OriginalAmt = veh.Original_Floored_Amount__c;
					fud.CurrentAmt = veh.Current_Floored_Amount__c;
					fud.Paid = veh.Paid__c;
					fud.FlooredDate = veh.Chassis_Floored_Date__c;
	
					// Basic auditing...
					if (fud.PaymentAmt!=fud.CurrentAmt) fud.WarningMsgs += 'Bank payment amount ' + String.valueOf(fud.PaymentAmt) + ' does not match current floored amount ' + String.valueOf(fud.CurrentAmt) + '. ';
					if (fud.Paid==true) fud.ErrorMsgs += 'Vehicle is already paid off. ';
					else {
						if (fud.Floorplanned==false) fud.ErrorMsgs += 'Vehicle is not floored. ';
						else {
							if (String.isBlank(fud.Floorplan) || !fud.Floorplan.startsWith('Huntington')) fud.ErrorMsgs += 'Chassis floorplan is not Huntington. ';
							String glcode = '';
							glcode = VehicleFlooring_CTRL.floorplanGlMap.get(fud.Floorplan);
							System.debug(uploadType + ' ' + fud.Floorplan + '/' + fud.NewFloorplan + ' gl# ' + glcode);
							if (String.isBlank(glcode)) fud.ErrorMsgs += 'Could not determine GL account for floorplan ' + fud.Floorplan + '. ';
						}
					}

				} else {
					if (String.isBlank(fud.WarningMsgs)) {
						fud.WarningMsgs += ' Multiple vehicles for VIN: ' + veh.dealer__Stock_Number__c + '. ';
					}
				}
				//FlooringUploadData.put(r,fud); // ? do I need to store it again, or is updating the object enough?

			}
		}
		
	}

	
	// prepPayoffVehicles
	private void prepCurtailmentVehicles(Map<Integer,Map<String,String>> csv) {
		List<String> missingColumns = new List<String>();
		if (!columnNames.contains('serial_nbr')) missingColumns.add('serial_nbr');
		if (!columnNames.contains('stock_nbr')) missingColumns.add('stock_nbr');
		if (!columnNames.contains('pmt_amt')) missingColumns.add('pmt_amt');
		if (!columnNames.contains('curr_princ_amt')) missingColumns.add('curr_princ_amt');
		if (missingColumns.size()>0) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Selected csv file is missing columns: ' + String.join(missingColumns, ', ')));
			csvError = true;
		}
		if (!csvError) {
			haveData = true;
		}
		auditCsvDataCurtailment(csv);
	}
	
	// auditCsvDataPayoff
	public void auditCsvDataCurtailment(Map<Integer,Map<String,String>> csvMap) {
		// Build list of VINs and template of data for display/audit
		Map<String,Integer> vinRowMap = new Map<String,Integer>();
		for(Integer r : csvMap.keySet()) {
			Map<String,String> rowdata = csvMap.get(r);
			String vin = rowdata.get('serial_nbr');
			if (vin==null) System.debug(csvMap.get(r));
			if (!String.isBlank(vin)) {
				vin = vin.remove(' ');	// BLL1a
				FlooringUploadData fud = new FlooringUploadData(r,vin);
				String pmt_amt = rowdata.get('pmt_amt');
				try {
					Decimal pmt = Decimal.valueOf(pmt_amt);
					fud.PaymentAmt = pmt;
				} catch(Exception e) {fud.ErrorMsgs += 'Invalid payment amount: ' + pmt_amt;} 
				String curr_amt = rowdata.get('curr_princ_amt');
				try {
					Decimal currentAmt = Decimal.valueOf(curr_amt);
					fud.NewCurrentAmt = currentAmt;
				} catch(Exception e) {fud.ErrorMsgs += 'Invalid current amount: ' + curr_amt;}
				if (!vinRowMap.containsKey(vin)) vinRowMap.put(vin,r);
				else fud.ErrorMsgs += 'Duplicate VIN in csv data - skipped. ';
				FlooringRequest.put(r,fud);
			}
		}

		// retrieve all referenced vehicles by VIN, fill in data for display/audit
		for(dealer__Vehicle_Inventory__c veh : [
			select Id, Name, dealer__VIN__c, dealer__Stock_Number__c, New_Used_Other__c,
				Floorplanned__c, Chassis_Floorplan__c, Chassis_Floored_Date__c, Conversion_Floorplan__c, Conv_Floored_Date__c,   
				Original_Floored_Amount__c, Current_Floored_Amount__c, Paid__c
			from dealer__Vehicle_Inventory__c
			where dealer__VIN__c in :vinRowMap.keySet() and RecordType.Name!='Vehicle Template' and RecordType.Name!='Archived'
			order by dealer__VIN__c, Chassis_Floored_Date__c desc NULLS LAST
		]) {
			Integer row = vinRowMap.get(veh.dealer__VIN__c);
			if (row!=null && row!=0 && FlooringRequest.containsKey(row) && csvMap.containsKey(row)) {
				Map<String,String> rowdata = csvMap.get(row);
				FlooringUploadData fud = FlooringRequest.get(row);
				
				if (fud.VehId==null || fud.VehId==veh.Id || !String.isBlank(fud.ErrorMsgs)) {
					// first vehicle found for this VIN had errors, so reset to this occurance
					if (fud.VehId!=veh.Id && !String.isBlank(fud.ErrorMsgs)) {
						fud.WarningMsgs += ' Multiple vehicles for VIN: ' + fud.StockNbr + '. ';
						fud.ErrorMsgs = '';
					}
					fud.VehId = veh.Id;
					fud.Name = veh.Name;
					fud.StockNbr = veh.dealer__Stock_Number__c;
					fud.NewUsedOther = veh.New_Used_Other__c;
					fud.Floorplan = veh.Chassis_Floorplan__c;
					fud.Floorplanned = veh.Floorplanned__c;
					fud.OriginalAmt = veh.Original_Floored_Amount__c;
					fud.CurrentAmt = veh.Current_Floored_Amount__c;
					fud.Paid = veh.Paid__c;
					fud.FlooredDate = veh.Chassis_Floored_Date__c;
	
					if (veh.Current_Floored_Amount__c==null) veh.Current_Floored_Amount__c = 0.00;
					if (fud.CurrentAmt==null) fud.CurrentAmt = 0.00;
					if (fud.PaymentAmt==null) fud.PaymentAmt = 0.00;
	
					// Basic auditing...
					if (fud.NewCurrentAmt!=(veh.Current_Floored_Amount__c-fud.PaymentAmt)) 
						fud.WarningMsgs += 'Current amount on vehicle ' + String.valueOf(veh.Current_Floored_Amount__c) + ' does not match amount from bank ' 
							+ String.valueOf(fud.NewCurrentAmt) + '. ';
					if (fud.Paid==true) fud.ErrorMsgs += 'Vehicle is already paid off. ';
					else {
						if (fud.Floorplanned==false) fud.ErrorMsgs += 'Vehicle is not floored. ';
						else {
							if (String.isBlank(fud.Floorplan) || !fud.Floorplan.startsWith('Huntington')) fud.ErrorMsgs += 'Chassis floorplan is not Huntington. ';
							String glcode = '';
							glcode = VehicleFlooring_CTRL.floorplanGlMap.get(fud.Floorplan);
							System.debug(uploadType + ' ' + fud.Floorplan + ' gl# ' + glcode);
							if (String.isBlank(glcode)) fud.ErrorMsgs += 'Could not determine GL account for floorplan ' + fud.Floorplan + '. ';
						}
					}
				} else {
					if (String.isBlank(fud.WarningMsgs)) {
						fud.WarningMsgs += ' Multiple vehicles for VIN: ' + veh.dealer__Stock_Number__c + '. ';
					}
				}
				//FlooringUploadData.put(r,fud); // ? do I need to store it again, or is updating the object enough?

			}
		}
		
	}

	
	public String FloorplanFromCollateralCode(String cc) {
		String floorplan = '';
	    Map<String,String> CollateralCodeFloorplans = new Map<String,String>{
	    	'USED'      => 'Huntington Used',
	    	'USEDAUTO'  => 'Huntington Used',
	    	'USEDB'     => 'Huntington Used',
	    	'TRADE'     => 'Huntington Used',
	    	'TRADEAUTO' => 'Huntington Used',
	    	'TRADEB'    => 'Huntington Used',
	    	'USED12'    => 'Huntington PPV',
	    	'TRADE12'   => 'Huntington PPV',
	    	'NEW'	    => 'Huntington New',
	    	'NEWAUTO'   => 'Huntington New'
	    };
	    floorplan = CollateralCodeFloorplans.get(cc);
		return floorplan;		
	}

	// prepFlooredVehicles
	private void prepFlooredVehicles(Map<Integer,Map<String,String>> csv) {
		List<String> missingColumns = new List<String>();
		if (!columnNames.contains('vin_nbr')) missingColumns.add('vin_nbr');
		if (!columnNames.contains('cltr_cd')) missingColumns.add('cltr_cd');
		if (!columnNames.contains('princ_rqst_amt')) missingColumns.add('princ_rqst_amt');
		if (!columnNames.contains('orig_amt_rqst')) missingColumns.add('orig_amt_rqst');
		if (missingColumns.size()>0) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Selected csv file is missing columns: ' + String.join(missingColumns, ', ')));
			csvError = true;
		}
		haveData = !csverror;
		auditCsvDataFloored(csv);
	}

	// auditCsvDataFloored
	public void auditCsvDataFloored(Map<Integer,Map<String,String>> csvMap) {
	    FlooringRequest = new Map<Integer,FlooringUploadData>();

		// Build list of VINs and template of data for display/audit
		Map<String,Integer> vinRowMap = new Map<String,Integer>();
		if (csvMap!=null) System.debug(csvMap.size());
		for(Integer r : csvMap.keySet()) {
			Map<String,String> rowdata = csvMap.get(r);
			String vin = rowdata.get('vin_nbr');
			System.debug(String.valueOf(r) + ':' + vin);
			String collateralCode = rowdata.get('cltr_cd');
			String principleAmtStr = rowdata.get('princ_rqst_amt');
			String originalAmtStr = rowdata.get('orig_amt_rqst');
			Decimal princAmt = Decimal.valueOf(principleAmtStr);
			Decimal origAmt = Decimal.valueOf(originalAmtStr);
			String newfloorplan = FloorplanFromCollateralCode(collateralCode);
			String gl = floorplanGlMap.get(newfloorplan);

			if (vin==null) System.debug(csvMap.get(r));
			if (!String.isBlank(vin)) {
				vin = vin.remove(' ');	// BLL1a
				FlooringUploadData fud = new FlooringUploadData(r,vin);
				fud.NewFloorplan = newfloorplan;
				fud.FlooredAmt = origAmt;
				fud.FlooredCurrentAmt = princAmt;
				fud.PaymentAmt = 0;
				if (!vinRowMap.containsKey(vin)) vinRowMap.put(vin,r);
				else fud.ErrorMsgs += 'Duplicate VIN in csv data - skipped. ';
				if (String.isBlank(gl)) fud.ErrorMsgs += 'Could not determine GL account for floorplan ' + newfloorplan + ' (' + collateralCode + '). ';
				FlooringRequest.put(r,fud);
			}
		}

		// retrieve all referenced vehicles by VIN, fill in data for display/audit
		for(dealer__Vehicle_Inventory__c veh : [
			select Id, Name, dealer__VIN__c, dealer__Stock_Number__c, Chassis_Floorplan__c, Floorplanned__c, 
				Original_Floored_Amount__c, Current_Floored_Amount__c, Chassis_Floored_Date__c, Paid__c,
				New_Used_Other__c, Conv_MFG__c
			from dealer__Vehicle_Inventory__c
			where dealer__VIN__c in :vinRowMap.keySet() and RecordType.Name!='Vehicle Template' and RecordType.Name!='Archived'
			order by dealer__VIN__c, dealer__Inventory_Date__c desc NULLS FIRST
		]) {
			Integer row = vinRowMap.get(veh.dealer__VIN__c);
			if (row!=null && row!=0 && FlooringRequest.containsKey(row) && csvMap.containsKey(row)) {
				Map<String,String> rowdata = csvMap.get(row);
				FlooringUploadData fud = FlooringRequest.get(row);
				
				if (fud.VehId==null || fud.VehId==veh.Id || !String.isBlank(fud.ErrorMsgs)) {
					// first vehicle found for this VIN had errors, so reset to this occurance
					if (fud.VehId!=veh.Id && !String.isBlank(fud.ErrorMsgs)) {
						fud.WarningMsgs += ' Multiple vehicles for VIN: ' + fud.StockNbr + '. ';
						fud.ErrorMsgs = '';
					}
					fud.VehId = veh.Id;
					fud.Name = veh.Name;
					fud.StockNbr = veh.dealer__Stock_Number__c;
					fud.NewUsedOther = veh.New_Used_Other__c;
					fud.Floorplan = veh.Chassis_Floorplan__c;
					fud.Floorplanned = veh.Floorplanned__c;
					fud.OriginalAmt = veh.Original_Floored_Amount__c;
					fud.CurrentAmt = veh.Current_Floored_Amount__c;
					fud.Paid = veh.Paid__c;
					fud.FlooredDate = veh.Chassis_Floored_Date__c;
					fud.NewConvFloorplan = fud.NewFloorplan;
					System.debug(veh);
					System.debug(fud);
					if (veh.New_Used_Other__c=='New/Used') {
						fud.NewConvFloorplan = NUMfgFloorplanMap.get(veh.Conv_MFG__c);
						if (fud.NewConvFloorplan==null) fud.NewConvFloorplan = 'Other';
						System.debug(fud);
					}
	
					// Basic auditing...
	
					if (fud.Floorplan != 'Not floored - Paperwork') fud.ErrorMsgs += 'Vehicle flooring was NOT "Not Floored - Paperwork".';
					if (String.isBlank(fud.NewFloorplan)) fud.ErrorMsgs += 'New Floorplan not found for collateral code ' + rowdata.get('cltr_cd') + '.';
					if (String.isBlank(fud.ErrorMsgs)) {
						// don't set this here, show on-screen what the vehicle record already has
						//fud.Floorplanned = true;
						//fud.FlooredDate = Date.today();
					}

				} else {
					if (String.isBlank(fud.WarningMsgs)) {
						fud.WarningMsgs += ' Multiple vehicles for VIN: ' + veh.dealer__Stock_Number__c + '. ';
					}
				}
				//FlooringUploadData.put(r,fud); // ? do I need to store it again, or is updating the object enough?

			}
		}

	}


	public String generatePayload(Map<Id, String> vehupdates) {
		Organization org = [select Id, Name, isSandbox from Organization];
		String action = '';
		if (uploadType=='payoff') action='vehicle_payoff';
		if (uploadType=='curtailment') action='vehicle_curtailment';
		if (uploadType=='floored') action='vehicle_floored';

		AccountingEmailService.AccountingPayload payload = new AccountingEmailService.AccountingPayload();
		payload.recordId = UserInfo.getUserId();
		payload.orgId = org.Id;
		payload.requestedby = UserInfo.getUserId();
		payload.action = action;
		payload.emailRecipient = UserInfo.getUserEmail();
		payload.details = JSON.serialize(vehupdates);
		//String payload = '{ "recordId":"' + UserInfo.getUserId() + '", "orgId": "' + org.Id + '", '
		//	+ '"requestedby":"' + UserInfo.getUserId() + '",'
		//	+ '"action":"' + action + '", '
		//	+ '"emailRecipient":"' + UserInfo.getUserEmail() + '",'
		//	+ '"details":"' + JSON.serialize(vehupdates) + '"}';
		return JSON.serialize(payload);
	}

	// processUpload
	public void processUpload() {
		Map<Id, String> vehupdates = new Map<Id, String>();
		if (FlooringData==null) FlooringData = new List<FlooringUploadData>();	// prevent blowup on null object
		
		for(FlooringUploadData fud : FlooringData) {
			vehupdates.put(fud.VehId, JSON.serialize(fud));
			if (vehupdates.size() >= VehicleFlooring_CTRL.JOURNAL_THRESHHOLD) {
				String payload = generatePayload(vehupdates);
				FFAccounting.EmailAsyncHandler(payload);
				vehupdates.clear();
			}
		}

		if (vehupdates.size()>0) {
			// email async process
			String payload = generatePayload(vehupdates);
			FFAccounting.EmailAsyncHandler(payload);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Flooring update (' + uploadType + ') has been submitted.'));
			dataSubmitted = true;
		}
		
	}

    
    // createAndPostJournal - called from Async FinancialForce process (email handler)
    // Also updates vehicle records!
    // process that sends requests to email handler will split the vehicle map into bite-sized chunks
    // so this routine only has 1 journal to create & post
    public static void CreateAndPostJournal(String mode, String recipient, String vehPmtString) {
    	// mode = payoff | floored | curtailment
    	// vehPmtData Map Id to JSON data needed for journal
    	/**
    		{ vehId => { Floorplan=>'Huntington PPV', Floored=>true, Paid=>false, OriginalAmt=>10000, CurrentAmount=>9000, Payment=>1000, BorrowAmt=>10000},
    		...
    	**/
    	System.debug(vehPmtString);
		Map<String, Object> vehPmtData = (Map<String, Object>) JSON.deserializeUntyped(vehPmtString);
		String message = '';

		c2g__codaCompany__c WMK_Company;
		c2g__codaDimension1__c WMK_Dimension1;
		c2g__codaBankAccount__c WMK_HNB_Bank;	// BLL2a
	
		WMK_Company = [SELECT Id, Name FROM c2g__codaCompany__c WHERE c2g__ExternalId__c = 'WMK'];
		WMK_Dimension1 = [SELECT Id, Name FROM c2g__codaDimension1__c WHERE c2g__ReportingCode__c = '100'];
		WMK_HNB_Bank = [select Id, Name from c2g__codaBankAccount__c where 	c2g__OwnerCompany__c=:WMK_Company.Id and c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c='1001' limit 1];	// BLL2a
		
		String pmtlinetype = mode=='floored' ? 'Credit' : 'Debit';
		String offsetlinetype = pmtlinetype=='Credit' ? 'Debit' : 'Credit';
		Date today = Date.today();
		
		// Build list of necessary GL accounts & audit list for completeness
    	Map<String,Id> glMap=new Map<String,Id>();	// BLL2a
    	VehicleFlooring_CTRL.neededGlAccts.addAll(floorplanGlMap.values());	
		for(c2g__codaGeneralLedgerAccount__c gl : [
			select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c in :VehicleFlooring_CTRL.neededGlAccts
		]) glMap.put(gl.c2g__ReportingCode__c, gl.Id);
		List<String> missingAccounts = new List<String>();
		for(String s : VehicleFlooring_CTRL.neededGlAccts) if (!glMap.containsKey(s)) missingAccounts.add(s);
		if (missingAccounts.size()>0) throw new VehicleFlooringException('Missing GL Accounts: ' + String.join(missingAccounts, ', '));

		c2g__codaJournal__c jrn = new c2g__codaJournal__c(
			c2g__JournalStatus__c = 'In Progress',
			c2g__Type__c = 'Manual Journal',
			c2g__OwnerCompany__c = WMK_Company.Id,
			c2g__JournalDate__c = today,
			Source__c = 'GE'
		);
		if (mode=='floored') {
			jrn.c2g__JournalDescription__c = 'Huntington Floored (' + DateTime.now().format('yyyy-MM-dd') + ')';
			jrn.c2g__Reference__c = 'Floored';
		} else if (mode=='payoff') {
			jrn.c2g__JournalDescription__c = 'Huntington Payments (' + DateTime.now().format('yyyy-MM-dd') + ')';
			jrn.c2g__Reference__c = 'Payoff';
		} else if (mode=='curtailment') {
			jrn.c2g__JournalDescription__c = 'Huntington Curtailments (' + DateTime.now().format('yyyy-MM-dd') + ')';
			jrn.c2g__Reference__c = 'Curtailment';
		}

		List<dealer__Vehicle_Inventory__c> vehUpdates = new List<dealer__Vehicle_Inventory__c>();
		List<c2g__codaJournalLineItem__c> jlines = new list<c2g__codaJournalLineItem__c>();
		Decimal sumAmt = 0.00;
		for(String vehIdStr : vehPmtData.keySet()) {
			Id vehId = (Id) vehIdStr;
			FlooringUploadData fud = (FlooringUploadData) JSON.deserialize((String) vehPmtData.get(vehId), FlooringUploadData.class);
			System.debug(fud);
			if (fud==null) throw new VehicleFlooringException('Internal error for Vehicle Id: ' + vehId);
			
			//Journal Lines entry for vehicle and reset lines
			String glcode = '';
			if (mode=='floored') glcode = VehicleFlooring_CTRL.floorplanGlMap.get(fud.NewFloorplan);
			else glcode = VehicleFlooring_CTRL.floorplanGlMap.get(fud.Floorplan);
			System.debug(mode + ' ' + fud.Floorplan + '/' + fud.NewFloorplan + ' gl# ' + glcode);
			
			c2g__codaJournalLineItem__c l = new c2g__codaJournalLineItem__c(
				c2g__LineType__c = 'General Ledger Account',
				c2g__LineDescription__c = 'Vehicle ' + mode + ' - ' + fud.StockNbr,
				c2g__GeneralLedgerAccount__c = glMap.get(glcode),
				c2g__DebitCredit__c = pmtlinetype,
				c2g__Dimension1__c = WMK_Dimension1.Id,
				Control__c = fud.StockNbr,
				Vehicle_Inventory__c = vehId
			);
			dealer__Vehicle_inventory__c veh = new dealer__Vehicle_Inventory__c(Id=vehId);
			System.debug(veh);
			if (mode=='floored') {
				veh.Floorplanned__c = true;
				veh.Paid__c = false;
				veh.Chassis_Floorplan__c = fud.NewFloorplan;
				veh.Chassis_Floored_Date__c = today;
				veh.Original_Floored_Amount__c = fud.FlooredAmt;
				veh.Current_Floored_Amount__c = fud.FlooredCurrentAmt;
				l.c2g__Value__c = pmtlinetype=='Credit' ? 0-fud.FlooredAmt : fud.FlooredAmt;
				if (fud.NewUsedOther!='New/Used') {
					veh.Conversion_Floorplan__c = fud.NewFloorplan;
					veh.Conv_Floored_Date__c = today;
				} else {
					veh.Conversion_Floorplan__c = fud.NewConvFloorplan;
				}
			} else if (mode=='payoff') {
				//Don't do this! veh.Floorplanned__c = false;
				veh.Paid__c = true;
				l.c2g__Value__c = pmtlinetype=='Credit' ? 0-fud.PaymentAmt : fud.PaymentAmt;
			} else if (mode=='curtailment') {
				//if (veh.Current_Floored_Amount__c==null) veh.Current_Floored_Amount__c = 0; 
				//if (fud.CurrentAmt!=null) veh.Current_Floored_Amount__c = fud.CurrentAmt;
				if (fud.NewCurrentAmt!=null) veh.Current_Floored_Amount__c = fud.NewCurrentAmt;
				if (fud.OriginalAmt!=null) veh.Original_Floored_Amount__c = fud.OriginalAmt;

				// ToDo: floor dates from csv file!
				//if (floor_date!=null) vcl.Chassis_Floored_Date__c = floor_date;
				//if (floor_date!=null) vcl.Conv_Floored_Date__c = floor_date;

				if (veh.Current_Floored_Amount__c!=null && veh.Current_Floored_Amount__c<0) veh.Current_Floored_Amount__c = 0;
				if (veh.Current_Floored_Amount__c!=null && veh.Current_Floored_Amount__c==0) {
					veh.Paid__c = true;
					veh.Chassis_Floorplan__c = 'Not Floored - Fully Curtailed';
					//if (fud.NewUsedOther!='New/Used') {
						veh.Conversion_Floorplan__c = 'Not Floored - Fully Curtailed';
					//}
				}
				l.c2g__Value__c = pmtlinetype=='Credit' ? 0-fud.PaymentAmt : fud.PaymentAmt;
			}
			vehUpdates.add(veh);
			sumAmt += l.c2g__Value__c;
			jlines.add(l);
			message += l.Control__c + ', ' + l.c2g__Value__c.format() + ', ' + glcode + ', '
				+ ((mode=='floored') ? fud.NewFloorplan : fud.Floorplan) 
				+ '\r';
		}
	
		if (jlines.size()>0) {
			c2g__codaJournalLineItem__c l = new c2g__codaJournalLineItem__c(
				//BLL2d c2g__LineType__c = 'General Ledger Account',
				c2g__LineType__c = 'Bank Account',	// BLL2a
				c2g__BankAccount__c = WMK_HNB_Bank.Id, 	// BLL2a
				c2g__GeneralLedgerAccount__c = glMap.get('1001'),
				c2g__DebitCredit__c = offsetlinetype,
				c2g__Dimension1__c = WMK_Dimension1.Id,
				c2g__Value__c = 0 - SumAmt,
				c2g__LineDescription__c = 'HNB FLOORING ' + mode.toUpperCase() + ' ' + DateTime.now().format('yyyy-MM')
			);
			l.Control__c = l.c2g__LineDescription__c;
			jlines.add(l);
			message += 'Offset total, ' + l.c2g__Value__c.format() + ', ' + '1001' + '\r';
		}

		String errmsgs = '';

		c2g__codaJournal__c j;
		Id journalId = null;
		if (jlines.size()>0) journalId = FinancialForce_MBW.createJournalApi(jrn, jlines);
		if (jlines.size()>0) j = [select Id, Name from c2g__codaJournal__c where Id=:journalId limit 1];
		try {
			if (journalId!=null) FFAccounting.postJournal(journalId);
		} catch(Exception e) {
			errmsgs = 'Unable to post journal '  + (j!=null?j.Name:'') + ' (' + journalId + ')\n';
			errmsgs += e.getMessage() + '\n\n';
			//errmsgs += vehPmtStr + '\n';
		}

		// try to update vehicles, record & report any errors
		Map<Id, String> resultmap = new Map<Id, String>();
		Database.SaveResult[] saveresults = new List<Database.SaveResult>();
		saveresults = Database.update(vehUpdates, false); 
		System.debug('List of failed updates:');
		for(Integer i=0; i<vehUpdates.size(); i++) {
			dealer__Vehicle_Inventory__c o = vehUpdates[i];
			String resultline = resultmap.get(o.Id);
			String errmsg = '';
			Database.SaveResult sr = saveresults.size()>i ? saveresults[i] : null;
			if (sr!=null && !sr.isSuccess()) {
				String errmsgline = o.Id + ',' + o.Name + ': ';
				for(Database.Error de : sr.getErrors()) {
					errmsgline += '[' + String.join(de.getFields(), ', ') + '] '
						+ de.getMessage() + '\r';
					errmsg += de.getMessage() + '; ';
				}
				System.debug(errmsgline);
				errmsgs += errmsgline;
				errmsg = errmsg.replaceAll('\\s',' ');
				if (o.Id!=null && resultline!=null) resultmap.put(o.Id,resultline+',"Error:'+errmsg+'"');
			}
		}

		// email result?
		String body = 'Journal ' + (j!=null?j.Name:'-') + ' (' + journalId + ') created for vehicle flooring update (' + mode + ')'
			+ ' for $ ' + SumAmt.setScale(2).format() + '\n\n';
		String subject = 'Flooring updates complete: ' + mode;
		if (!String.isBlank(errmsgs)) {
			subject = 'Error(s) processing vehicle flooring updates: ' + mode;
			body += ' with errors (see below)\n\n';
		}
		if (!String.isBlank(errmsgs)) body += errmsgs + '\n\n';
		body += 'Journal lines:\rControl#, Amount, GL Acct, Floorplan\r' + message;
		System.debug('SendEmail("' + mode + '", "' + recipient + '", "' + subject + ', "' + body + '")');
		VehicleFlooring_CTRL.sendEmail(mode, recipient, subject, body);
    }

	// sendEmail of the results	
	public static void sendEmail(String mode, String recipient, String subject, String body) {
		System.debug('sendEmail for ' + mode + ' to ' + recipient + ' re: ' + subject);
		Organization org = [select Id, Name, isSandbox from Organization limit 1];
		//String csvheader = 'col1,col2,etc\n';
		List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
		//List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();
		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		List<String> recipients = new List<String>();
		recipients.add(recipient);
		//if (!org.isSandbox) recipients.add('another.email@mobilityworks.com');
		mail.setToAddresses(recipients); 
		mail.setSubject(subject);
		mail.setPlainTextBody(body);
		
		//Messaging.EmailFileAttachment resultcsv = new Messaging.EmailFileAttachment();
		//	resultcsv.setContentType('text/csv');
		//	resultcsv.setFileName('results.csv');
		//	resultcsv.setInline(false);
		//	resultcsv.Body = Blob.valueOf(csvheader + String.join(resultmap.values(),'\n'));
		//	if (resultmap.size()>0) listOfAttachments.add(resultcsv);
		//Messaging.EmailFileAttachment upderrors = new Messaging.EmailFileAttachment();
		//	upderrors.setContentType('text/plain');
		//	upderrors.setFileName('UpdateErrors.txt');
		//	upderrors.setInline(false);
		//	upderrors.Body = Blob.valueOf(errmsgs);
		//	if (!String.isBlank(errmsgs)) listOfAttachments.add(upderrors);
		//mail.setFileAttachments(listOfAttachments);
		emailMsgs.add(mail);
		Messaging.sendEmail(emailMsgs);
	}

    
    public class FlooringUploadData {
    	//public dealer__Vehicle_Inventory__c vehicle {get;set;}
    	public Integer RowNbr {get;set;}
    	public Id VehId {get;set;}
    	public String Name {get;set;}
    	public String StockNbr {get;set;}
    	public String VIN {get;set;}
    	public String NewUsedOther {get;set;}
    	public String Floorplan {get;set;}
    	public boolean Floorplanned {get;set;}
    	public Decimal OriginalAmt {get;set;}
    	public Decimal CurrentAmt {get;set;}
    	public boolean Paid {get;set;}
    	public Date FlooredDate {get;set;}
    	public Decimal PaymentAmt {get;set;}
    	public String NewFloorplan {get;set;}
    	public Decimal FlooredAmt {get;set;}
    	public Decimal FlooredCurrentAmt {get;set;}
    	public Decimal NewCurrentAmt {get;set;}
    	public String ErrorMsgs {get;set;}
    	public String WarningMsgs {get;set;}
    	public String InfoMsgs {get;set;}
    	public String NewConvFloorplan {get;set;}
    	
    	public FlooringUploadData(Integer row, String vinbr) {
    		//vehicle = new dealer__Vehicle_Inventory__c();
    		RowNbr = row;
    		VehId = null;
    		VIN = vinbr;
    		Name = '';
    		StockNbr = '';
    		Floorplan = '';
    		Floorplanned = false;
    		OriginalAmt = 0;
    		CurrentAmt = 0;
    		Paid = false;
    		FlooredDate = null;
    		ErrorMsgs = '';
    		WarningMsgs = '';
    		InfoMsgs = '';
    		PaymentAmt = 0.00;
    		NewFloorplan = '';
    		FlooredAmt = 0.00;
    		FlooredCurrentAmt = 0.00;
    		NewConvFloorplan = '';
    	}
    }
    
    public class VehicleFlooringException extends Exception {}
    
}