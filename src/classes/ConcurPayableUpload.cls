/**
 * ConcurPayableUpload
 * Tested by: ConcurPayableProcess_TEST
 * 
 * Coverage:
 *	2018-08-21	87% (169/193)
 *
 * Modifications:
 * 
 */

/**
ParseConcurPaymentData();
List<dealer__Purchase_Order__c> POs = PurchaseOrderUpdatesForPayRequests( requests );
Map<String, List<dealer__Purchase_Order__c>> poMapByCmp = ChunkPOsByCompany(POs);
for(String key : poMapByCmp.keySet()) {
	List<dealer__Purchase_Order__c> polist = poMapByCmp.get(key);
	// submit to async process... 
	// ...to do: CreatePurchaseInvoices(polist);
}
**/
public with sharing class ConcurPayableUpload {

	public ParseCSV csv;
	public ConcurPayableProcess cpp;

	public String batchId {get;set;}
	public Date batchDate {get;set;}
	public Integer recordCount {get;set;}
	public Decimal totalAmount {get;set;}
	
	public List<PayableRequest> requests {get;set;}
	public List<dealer__Purchase_Order__c> poList {get;set;}
	public Map<String, List<dealer__Purchase_Order__c>> poMapByCmp {get;set;}


	public String fileName {get;set;}
	public Blob csvBlob {get;set;}
	public Set<String> unrecognizedColumns;	
	public List<PayableRequest> errorRcds {get;private set;}
	public List<PayableRequest> readyRcds {get;private set;}
    public boolean haveData {get;private set;}
    public boolean haveGoodData {get;private set;}
    public boolean dataSubmitted {get;private set;}
    public boolean haveErrors {get;private set;}
    public boolean processComplete {get;private set;}


	// constructor
	//---------------------------
	public ConcurPayableUpload() {
		startOver();
	}
	
	public void startOver() {
		// put reset items here!
		csv = ParseCSV.StrictParser();
		cpp = new ConcurPayableProcess();
		fileName = null;
		csvBlob = null;
		unrecognizedColumns = new Set<String>();
		errorRcds = new List<PayableRequest>();
		readyRcds = new List<PayableRequest>();
		haveData = false;
		haveGoodData = false;
		dataSubmitted = false;
		haveErrors = false;
		processComplete = false;
	}
	

	// submitCsv
	//-----------------------
	public void submitCsv() {
		String csvData;
		if (csvBlob!=null) {
			csvData = csvBlob.toString();
		}
		if (!String.isBlank(csvData)) {
			//try {
				
				ParseConcurPaymentData(csvData);
				haveData = requests!=null && requests.size()>0;
				POList = cpp.PurchaseOrderUpdatesForPayRequests( requests );		
	
				// check for existing vendor invoices, which will cause FF PIN to fail
				Map<Id,Map<String,c2g__codaPurchaseInvoice__c>> vndInvPinMap = findExistingVendorInvoices(requests);

				// Basic error/edit checking
				for(PayableRequest pr : requests) {
					if (pr.po==null) pr.errorMsgs.add('PO not found in DealerTeam');
					if (pr.po!=null && pr.po.dealer__Status__c=='Posted') pr.errorMsgs.add('PO has already been posted');
					if (pr.po!=null && pr.po.dealer__Post_Date_Time__c!=null) pr.errorMsgs.add('PO was previously posted on ' + pr.po.dealer__Post_Date_Time__c.format('MM/dd/yyyy'));
					if (pr.po!=null && pr.po.dealer__Status__c!='Accepted' && pr.po.dealer__Status__c!='Partial' && pr.po.dealer__Status__c!='Posted') pr.errorMsgs.add('PO has not been accepted (Status=' + pr.po.dealer__Status__c + ')');
					if (pr.po!=null && pr.po.Payable_Invoice__c!=null) pr.errorMsgs.add('PO already has a payable invoice: ' + pr.po.Payable_Invoice__r.Name);
					
					// check for re-use of vendor invoice number
					Map<String,c2g__codaPurchaseInvoice__c> vinvmap; 
					if (pr.po!=null) vinvmap = vndInvPinMap.get(pr.po.dealer__Vendor__c);
					if (vinvmap==null) vinvmap = new Map<String,c2g__codaPurchaseInvoice__c>();
					if (!String.isBlank(pr.InvoiceNbr) && vinvmap.containsKey(pr.InvoiceNbr)) pr.errorMsgs.add('Vendor invoice "' + pr.InvoiceNbr + '" has already been processed');
				}
				
				// If one line has an error, treat other lines as having errors too!
				Set<String> errorPOs = new Set<String>();
				for(PayableRequest pr : requests) {
					if (pr.errorMsgs.size()>0) errorPOs.add(pr.PONumber);
				}
				for(PayableRequest pr : requests) {
					if (errorPOs.contains(pr.PONumber) && pr.errorMsgs.size()==0) pr.ErrorMsgs.add('Error(s) on other line(s) for this PO');
				}
	
				for(PayableRequest pr : requests) {
					if (pr.errorMsgs.size()==0) readyRcds.add(pr);
					else errorRcds.add(pr);
				}
				haveGoodData = readyRcds.size()>0;
			
			//} catch(Exception e) {
			//	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error parsing the upload: ' + e.getMessage()));
			//}
			
		} else {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must select a valid csv file to upload.'));
		}
	}


	// findExistingVendorInvoices
	//---------------------------------------
	public Map<Id,Map<String,c2g__codaPurchaseInvoice__c>> findExistingVendorInvoices(List<PayableRequest> requests) { 
		Map<Id,Map<String,c2g__codaPurchaseInvoice__c>> vndInvPinMap = new Map<Id,Map<String,c2g__codaPurchaseInvoice__c>>();
		Set<Id> vendorIds = new Set<Id>();
		Set<String> vendorInvs = new Set<String>();
		for(PayableRequest pr : requests) {
			if (pr.po!=null) vendorIds.add(pr.po.dealer__Vendor__c);
			if (!String.isBlank(pr.InvoiceNbr)) vendorInvs.add(pr.InvoiceNbr);
		}
		List<c2g__codaPurchaseInvoice__c> pinvs = new List<c2g__codaPurchaseInvoice__c>();
		if (vendorIds.size()>0 && vendorInvs.size()>0) {
			pinvs = [
				select Id, Name, c2g__Account__c, c2g__AccountInvoiceNumber__c
				from c2g__codaPurchaseInvoice__c
				where c2g__Account__c in :vendorIds and c2g__AccountInvoiceNumber__c in :vendorInvs
				  and c2g__InvoiceStatus__c='Complete'
			];
		}
		for(c2g__codaPurchaseInvoice__c pinv : pinvs) {
			Map<String,c2g__codaPurchaseInvoice__c> vinvmap = vndInvPinMap.get(pinv.c2g__Account__c);
			if (vinvmap==null) vinvmap = new Map<String,c2g__codaPurchaseInvoice__c>();
			vinvmap.put(pinv.c2g__AccountInvoiceNumber__c, pinv);
			vndInvPinMap.put(pinv.c2g__Account__c, vinvmap);
		}
		return vndInvPinMap;
	}


	// processUpload
	//---------------------------
	public void processUpload() {
		Map<Id,dealer__Purchase_Order__c> POMap = new Map<Id,dealer__Purchase_Order__c>(); 
		POList = new List<dealer__Purchase_Order__c>();
		for(PayableRequest pr : readyRcds) { 
			if (pr.po!=null) POMap.put(pr.po.Id, pr.po);
		}
		poList = POMap.values();
//		for(dealer__Purchase_Order__c po : poList) {
//			po.dealer__Status__c='Posted';
//			po.dealer__Post_Date_Time__c=currentdt;
//		}
//		update(poList);
		poMapByCmp = cpp.ChunkPOsByCompany(poList, 50);
		SendPOsToAsyncProcess(poMapByCmp);
		processComplete = true;		
	}

	// 	ParseConcurPaymentData
	//---------------------------
	public void ParseConcurPaymentData(String data) {
		requests = new List<PayableRequest>();

		// parser doesn't work well with pipe character (|)
		data = data.replace('^',' ').replace('|','^');	
		
		csv.fieldDelimiter = '^';
		csv.stringDelimiter = '';	// not used, but dbl-quotes can show up in the data!
		csv.hasColumnHeadings = false;
 		csv.setCsvData(data);
 		//csv.debug = true;
		Map<Integer, Map<Integer,String>> csvmap = csv.getRowsMapByColumnNbr();
		System.debug(csvmap);
		
		Map<Integer,String> header = csvmap.get(1);
		System.debug(header);
		if (header==null || header.size()==0) throw new parserException('Missing Concur Extract header line');
		
		batchId = header.get(2);
		batchDate = Date.valueOf(header.get(3));
		recordCount = Integer.valueOf(header.get(4));
		totalAmount = Decimal.valueOf(header.get(5));
		
		for(Integer r = 2; r<=csvmap.size(); r++) {
			Map<Integer,String> rowdata = csvmap.get(r);
			System.debug(rowdata);
			PayableRequest pr = new PayableRequest();

			try {			
				pr.InvoiceNbr = nullToEmptyString(rowdata.get(6));
				pr.InvoiceDate = textToDate(nullToEmptyString(rowdata.get(7)),'(col 7)');
				pr.InvoiceAmt = textToDecimal(nullToEmptyString(rowdata.get(9)),'(col 9)');
				pr.PONumber = nullToEmptyString(rowdata.get(13));
				pr.ShippingAmt = textToDecimal(nullToEmptyString(rowdata.get(49)),'(col 49)');
				//pr.NMEDAAmt = textToDecimal(nullToEmptyString(rowdata.get(50)),'(col 50)');
				//pr.NMEDAAmt = textToDecimal(nullToEmptyString(rowdata.get(161)),'(col 161)');
				//pr.NMEDAAmt = textToDecimal(nullToEmptyString(rowdata.get(244)),'(col 244)');
				pr.NMEDAAmt = textToDecimal(nullToEmptyString(rowdata.get(212)),'(col 212)');
				pr.LineShippingAmt = textToDecimal(nullToEmptyString(rowdata.get(58)),'(col 58)');
				if (pr.LineShippingAmt==null) pr.LineShippingAmt = 0.00;
				System.debug(pr.LineShippingAmt);
				pr.TotalAmt = textToDecimal(nullToEmptyString(rowdata.get(63)),'(col 63)');
				pr.CurrencyCode = nullToEmptyString(rowdata.get(65));
				pr.ReceiptQty = textToDecimal(nullToEmptyString(rowdata.get(93)),'(col 93)');
				pr.LinePO = nullToEmptyString(rowdata.get(128));
				pr.POLineId = nullToEmptyString(rowdata.get(130));
				pr.LineDescription = nullToEmptyString(rowdata.get(133));
				String itemQtyStr = nullToEmptyString(rowdata.get(136));
				pr.ItemQty = String.isBlank(itemQtyStr) ? 0 : textToDecimal(itemQtyStr,'(col 136)');
				String unitPriceStr = nullToEmptyString(rowdata.get(137));
				pr.UnitPrice = String.isBlank(unitPriceStr) ? 0 : textToDecimal(unitPriceStr,'(col 137)');
				pr.TotalPrice = textToDecimal(nullToEmptyString(rowdata.get(138)),'(col 138)');
				pr.PartNbr = nullToEmptyString(rowdata.get(162));
				pr.VendorName = nullToEmptyString(rowdata.get(164));
				pr.VendorCode = nullToEmptyString(rowdata.get(165));
				pr.po = null;
				System.debug(pr);
				for(Integer c : rowdata.keySet()) {
					System.debug('Col: ' + c + ' = "' + rowdata.get(c) + '"');
				}
				
			} catch(Exception e) {
				pr.ErrorMsgs.add(e.getMessage());
				for(Integer c : rowdata.keySet()) {
					System.debug('Col: ' + c + ' = "' + rowdata.get(c) + '"');
				}
			}
			
			requests.add(pr);
		}
		
	}
	
	// Convert column of text from csv to a date, providing more meaningful error if it fails
	public Date textToDate(String colVal, String info) {
		Date rtnDate;
		try {
			rtnDate = Date.valueOf(colVal);
		} catch(Exception e) {
			throw new parserException('Cannot convert "' + colVal + '" ' + info + ' to a Date: ' + e.getMessage());
		}
		return rtnDate;
	}
	
	// Convert column of text from csv to a decimal, providing more meaningful error if it fails
	public Decimal textToDecimal(String colVal, String info) {
		Decimal rtnDecimal;
		try {
			rtnDecimal = String.isBlank(colVal) ? 0 : Decimal.valueOf(colVal);
			if (rtnDecimal==null) rtnDecimal = 0.00;
		} catch(Exception e) {
			throw new parserException('Cannot convert "' + colVal + '" ' + info + ' to a Decimal: ' + e.getMessage());
		}
		return rtnDecimal;
	}
	
	// SendPOsToAsyncProcess
	public void SendPOsToAsyncProcess(Map<String, List<dealer__Purchase_Order__c>> poMapByCmp) {
		Organization org = [select Id, Name, isSandbox from Organization limit 1];
		List<String> payloads = new List<String>();
		for(String key : poMapByCmp.keySet()) {
			List<dealer__Purchase_Order__c> pos = poMapByCmp.get(key);
			// submit to async process... 
			// ...to do: CreatePurchaseInvoices(polist);
			AccountingEmailService.AccountingPayload ap = new AccountingEmailService.AccountingPayload();
			ap.recordId = UserInfo.getUserId();
			ap.orgId = org.Id;
			ap.requestedBy = UserInfo.getUserId();
			ap.action = 'create_payable_invoices';
			ap.emailRecipient = UserInfo.getUserEmail();
			ap.details = JSON.serialize(pos);  
			payloads.add(JSON.serialize(ap));
		}		
		FFAccounting.EmailAsyncHandler(payloads);
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Create payable invoices sent in ' + String.valueOf(payloads.size()) + (payloads.size()==1 ? ' batch' : ' batches')));
	}


	// nullToEmptyString
	//---------------------------
	public String nullToEmptyString(String n) {
		return n==null ? '' : n;
	}


	//===========================
	public class PayableRequest {
		public List<String> warningMsgs {get;set;}
		public String warningMsgStr {get {return String.join(warningMsgs,'; ');} }
		public List<String> errorMsgs {get;set;}
		public String errorMsgStr {get {return String.join(errorMsgs,'; ');} }
		public Date InvoiceDate {get;set;}
		public String InvoiceNbr {get;set;}
		public Decimal InvoiceAmt {get;set;}
		public String PONumber {get;set;}
		public Decimal ShippingAmt {get;set;}
		public Decimal LineShippingAmt {get;set;}
		public Decimal NMEDAAmt {get;set;}	// Concur's tax amount
		public Decimal TotalAmt {get;set;}
		public String CurrencyCode {get;set;}
		public String LinePO {get;set;}
		public String POLineId {get;set;}
		public String LineDescription {get;set;}
		public String PartNbr {get;set;}
		public Decimal ItemQty {get;set;}
		public Decimal ReceiptQty {get;set;}
		public Decimal UnitPrice {get;set;}
		public Decimal TotalPrice {get;set;}
		public String VendorName {get;set;}
		public String VendorCode {get;set;}
		public Id POId {get;set;}
		public Integer NbrLines {get;set;}

		// ?
		public dealer__Purchase_Order__c PO {get;set;}
		
		public PayableRequest() {
			warningMsgs = new List<String>();
			errorMsgs = new List<String>();
			NbrLines = 0;
		}

	}

	public class parserException extends Exception { }	
	
}