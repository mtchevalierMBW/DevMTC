/**
 * ConcurPurchaseAndReceiptExport
 * Tested by: ConcurPurchaseAndReceiptExport_TEST
 * Date: June 1, 2018
 * Programmer: Bryan Leaman
 *
 * New MobilityForce Setting:
 *	LastConcurExport__c (Date/Time)
 *
 * Coverage:
 *	2018-06-04	97% (210/216)
 *
 * Modifications:
 * 
 */
public with sharing class ConcurPurchaseAndReceiptExport {

	public String updatedSinceTxt {get;set;}
	public DateTime updatedSince {get;set;}
	public boolean IncludeClosedPOs {get;set;}
	public boolean AllPOsOpen {get;set;}
	public String poExport {get;private set;}
	public String rctExport {get;private set;}
	public List<ExportDetails> ExportedPOs {get;private set;}
	
	private List<String> openPoSts = new List<String>{'Open', 'Partial', 'Accepted'};
	private String CONCUR_DATE_FMT = 'yyyy-MM-dd';
	private MobilityForceSettings__c mfs;
	
	// temporary
	public String includePOsText {get;set;}
		// DEK-186461,ORL-187851,BEA-189628,LAX-193837,FLD-193829,NAS-193727,SEL-189985,FWR-193011,MIA-193029,LRG-192905
	private List<String> includePOs;

	// ConcurPurchaseAndReceiptExport
	//---------------------------------------
	public ConcurPurchaseAndReceiptExport() {
		mfs = MobilityForceSettings__c.getOrgDefaults();
		updatedSince = mfs.LastConcurExport__c;
		//updatedSince = DateTime.newInstance(Date.newInstance(2018, 05, 21), Time.newInstance(0, 0, 0, 0));
		updatedSinceTxt = updatedSince!=null ? updatedSince.format('MM/dd/yyyy hh:mm a') : DateTime.now().addDays(-1).format('MM/dd/yyyy hh:mm a');		
		openPoSts = new List<String>{'Open', 'Partial', 'Accepted'};
		includePOsText = '';
		includePOs = new List<String>();
		IncludeClosedPOs = false;
		AllPOsOpen = false;
		ExportedPOs = new List<ExportDetails>();
	}

	// ChangedPurchaseOrders
	//---------------------------------------
	public void RetrieveAndGenerateExportData() {
		GenerateExportData(ChangedPurchaseOrders());
	}

	// ChangedPurchaseOrders
	//---------------------------------------
	public List<dealer__Purchase_Order__c> ChangedPurchaseOrders() {
		mfs.LastConcurExport__c = DateTime.now();	// don't update the setting with this value unless successful

		// Get list of vendors we're exporting to Concur
		Map<Id, Account> vendorMap = new Map<Id, Account>([
			select Id, Name
			from Account
			where dealer__Vendor__c=true
				and Name = 'braun corp'
		]);
		System.debug(vendorMap);
		
		// Purchase Orders
		//===========================================
		if (!String.isBlank(includePOsText)) includePOs = includePOsText.split(',');		
		System.debug('Purchase orders');
		try {
			updatedSince = DateTime.parse(updatedSinceTxt);
		} catch(Exception e) {
			try {
				updatedSince = DateTime.valueOf(updatedSinceTxt);
			} catch(Exception e2) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Date/time format error'));
				return new List<dealer__Purchase_Order__c>();
			}
		}
		System.debug(updatedSince);
		
		// List all POs that have changed since "updatedSince" date/time
		List<dealer__Purchase_Order__c> polist = [
			select Id, dealer__PO_Number__c, Name, dealer__Status__c, CreatedDate, dealer__Date_Required__c,
				Payable_Invoice__c, Payable_Invoice__r.c2g__InvoiceStatus__c,  
				dealer__Vendor__c, dealer__Vendor__r.Name, dealer__Vendor__r.ClientID__c, 
				dealer__Vendor__r.c2g__CODADaysOffset1__c, 
				dealer__Vendor__r.c2g__CODADiscount1__c, dealer__Vendor__r.c2g__CODAAccountTradingCurrency__c, 
				dealer__Company__c, dealer__Company__r.Name, dealer__Company__r.dealer__Company_Number__c, 
				dealer__Company__r.dealer__Street__c,
				dealer__Company__r.dealer__City__c, dealer__Company__r.dealer__State__c, dealer__Company__r.dealer__Postal_Code__c, dealer__Company__r.Country__c,
				dealer__Company__r.Financial_Force_Dimension_1__r.c2g__ReportingCode__c,
				LastModifiedDate, 
				( select Id, Name, dealer__Description__c, dealer__Part_Quantity__c, dealer__Part_Quantity_Received__c,
					dealer__Part_Cost__c, dealer__Amount__c, dealer__Item_Value__c,  
					dealer__Part__c, dealer__Parts_Master__c, dealer__Parts_Master__r.Name,
					dealer__Parts_Master__r.dealer__Part_Description__c, 
					LastModifiedDate
				  from dealer__Purchase_Order_Line__r
				  order by Name),
				( select Id, Name, dealer__Quantity_Adjustment__c, dealer__Transaction_Time__c,
					dealer__Part__c, dealer__Part__r.dealer__Pack_QTY__c, dealer__Part__r.dealer__Parts_Master__r.Name, Description__c,
					LastModifiedDate
				  from dealer__Parts_Inventory_History__r
				  where dealer__Transaction_Event__c in ('Purchase Order Received')
				)
			from dealer__Purchase_Order__c
			where dealer__Vendor__c in :vendorMap.keySet()
				and RecordType.Name='Parts Purchase'
				and (LastModifiedDate >= :updatedSince or dealer__PO_Number__c in :includePOs)
		];
		
		return polist;		
	}

	// StandardizeStreet
	//---------------------------------------
	public List<String> StandardizeStreet(String street) {
		// split multi-line addresses into a list of address lines
		// treat a comma in the address line as a new line (cannot embed commas in export file)
		if (street==null) street = '';
		return street.replaceAll('\n','\r').replaceAll('\r\r','\r').split('\r');
	}

	// GenerateExportData
	//---------------------------------------
	public void GenerateExportData(List<dealer__Purchase_Order__c> polist) {
		poExport = '';
		rctExport = '';

		String TestIndicator = 'N';
		Organization org = [select Id, Name, isSandbox from Organization limit 1];
		//if (org.isSandbox) TestIndicator = 'Y';

		// Get bill-to info (from Akron Store)
		dealer__Dealer_Location__c billto = [
			select Id, Name, dealer__Street__c, dealer__City__c, dealer__State__c, dealer__Postal_Code__c, Country__c,
				dealer__Company_Number__c 
			from dealer__Dealer_Location__c
			where dealer__Company_Number__c = 'AKR'
			limit 1
		];
		billto.Name = 'MobilityWorks';	// Using Akron address, but not the Akron store name
		billto.dealer__Company_Number__c = 'MW';
		List<String> billtostreet =  StandardizeStreet(billto.dealer__Street__c);
		
		// update export time on each PO so we can tell which ones have changed next time
		// set export date/time to NOW + 30 seconds to allow for update time
		// Integer offsetSeconds = 30;
		// DateTime now = DateTime.now();
		// DateTime nowPlus = now.addSeconds(offsetSeconds);
		// List<dealer__Purchase_Order__c> updPOconcur = new List<dealer__Purchase_Order__c>();
		// for(dealer__Purchase_Order__c po : polist) updPOconcur.add(new dealer__Purchase_Order__c(Id=po.Id, ConcurExportDateTime__c=nowPlus));
		// Database.update(updPOconcur);
		
		// Formatting of export lines to Concur
		String PoFormat300 = '300,{0},{1},{2},,,{3},,{4},{5},{6},,{7},,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,';
		String PoFormat220 = '220,{0},MobilityWorks of {1},{2},{3},{4},{5},{6},{7},{8},,,,,,,,,,';
		String PoFormat210 = '210,{0},{1},{2},{3},{4},{5},{6},{7},{8},,,,,,,,,,';
		String PoFormat200 = '200,{0},PO Policy,{1},{2},{3},{4},,,,,{5},,{6},,,,{7},,,{8},,{9},,,,,,,,{10},,,,,,,{11},,,,,,,,,,,,,,,,,,,,,,,';
		
		List<String> AllPOsExport = new List<String>();

		for(dealer__Purchase_Order__c po : polist) {
			List<String> POExport = new List<String>();
		
			// skip or include closed/processed POs
			if (IncludeClosedPOs || po.Payable_Invoice__c==null) {
		
				// default days due
				if(po.dealer__Vendor__r.c2g__CODADaysOffset1__c==null) po.dealer__Vendor__r.c2g__CODADaysOffset1__c = 30;	
			
				String DateRequired = '';
				if (po.dealer__Date_Required__c!=null) DateRequired = DateTime.newInstance(po.dealer__Date_Required__c, Time.newInstance(0,0,0,0)).format(CONCUR_DATE_FMT);
				String StatusOfPO = OpenPOSts.contains(po.dealer__Status__c) ? 'TRAN' : 'CLSD';
				
				// temporary
				if (po.Payable_Invoice__c!=null && !includePOs.contains(po.dealer__PO_Number__c)) StatusOfPO = 'CLSD';	// if we've paid it already, it's closed
				if (AllPOsOpen) StatusOfPO = 'TRAN';
				
				String ReceiptType = 'WQTY';
				//System.debug(po.Name + ', ' + po.dealer__Vendor__r.Name);
			
				ExportDetails exp = new ExportDetails();
				exp.Status = StatusOfPO;
				exp.poNumber = po.dealer__PO_Number__c;
				exp.LastModified = po.LastModifiedDate;
				exp.NbrLines = po.dealer__Purchase_Order_Line__r.size();
				exp.NbrReceipts = po.dealer__Parts_Inventory_History__r.size();
				exp.QtyOrdered = 0;
				exp.QtyReceived = 0;
				exp.QtyOutstanding = 0;
			
				Integer LineNbr = 0;
				for(dealer__Purchase_Order_Line__c line : po.dealer__Purchase_Order_Line__r) {
					String ExpenseType = 'Unbilled';
					String UOM = 'EACH';
					LineNbr++;
					String description = line.dealer__Parts_Master__r.dealer__Part_Description__c;
					if (description==null) description='';
					description = description.replaceAll(',', ' ');
					description = description.replaceAll('\'', ' ').replaceAll('"',' ');
					description = description.replaceAll('™', '(TM) ');
					POExport.add( String.format( PoFormat300, new List<String>{
						line.Name, 
						String.valueOf(LineNbr),
						line.dealer__Parts_Master__r.Name,
						ExpenseType, 
						'"'+description+'"', 
						String.valueOf(line.dealer__Part_Quantity__c),
						String.valueOf(line.dealer__Item_Value__c),
						UOM
					}) );
					exp.QtyOrdered += line.dealer__Part_Quantity__c;
				}

				for(dealer__Part_Inventory_History__c trans : po.dealer__Parts_Inventory_History__r) {
					Decimal qtyRcvd = trans.dealer__Quantity_Adjustment__c;
					if (trans.dealer__Part__r.dealer__Pack_QTY__c>0) 
						qtyRcvd = qtyRcvd / trans.dealer__Part__r.dealer__Pack_QTY__c;
					exp.QtyReceived += qtyRcvd;
				}
				exp.QtyOutstanding = exp.QtyOrdered - exp.QtyReceived;

			
				// Only export if there were lines, lest we get a record type sequence error from Concur
				if (LineNbr!=0) {
					// Ship-to line
					List<String> shiptostreet = StandardizeStreet(po.dealer__Company__r.dealer__Street__c);
					POExport.add( String.format( PoFormat220, new List<String>{
						po.dealer__Company__r.dealer__Company_Number__c,
						po.dealer__Company__r.Name,
						shiptostreet.size()>0 ? '"'+shiptostreet[0]+'"' : '',
						shiptostreet.size()>1 ? '"'+shiptostreet[1]+'"' : '',
						shiptostreet.size()>2 ? '"'+shiptostreet[2]+'"' : '',
						po.dealer__Company__r.dealer__City__c,
						po.dealer__Company__r.dealer__State__c,
						po.dealer__Company__r.dealer__Postal_Code__c,
						po.dealer__Company__r.Country__c!=null ? po.dealer__Company__r.Country__c : 'US'
					}));
					// Bill-to line
					POExport.add( String.format( PoFormat210, new List<String>{
						billto.dealer__Company_Number__c,
						billto.Name,
						billtostreet.size()>0 ? '"'+billtostreet[0]+'"' : '',
						billtostreet.size()>1 ? '"'+billtostreet[1]+'"' : '',
						billtostreet.size()>2 ? '"'+billtostreet[2]+'"' : '',
						billto.dealer__City__c,
						billto.dealer__State__c,
						billto.dealer__Postal_Code__c,
						billto.Country__c !=null ? billto.Country__c : 'US'
					}));
					// PO Header
					POExport.add( String.format( PoFormat200, new List<String>{
						po.dealer__PO_Number__c,
						po.dealer__Vendor__r.c2g__CODAAccountTradingCurrency__c, 
						po.dealer__Vendor__r.ClientID__c, 
						po.dealer__Vendor__r.ClientID__c, 
						po.CreatedDate.format(CONCUR_DATE_FMT),
						String.valueOf(po.dealer__Vendor__r.c2g__CODADaysOffset1__c), 
						String.valueOf(po.dealer__Vendor__r.c2g__CODADiscount1__c),
						TestIndicator,
						DateRequired, 
						StatusOfPO,
						ReceiptType, 
						po.dealer__Company__r.Financial_Force_Dimension_1__r.c2g__ReportingCode__c
					}));
					//System.debug(POExport);
					AllPOsExport.addAll(POExport);
					ExportedPOs.add(exp);
				}
			}	// end if not initial load or no purchase invoice yet
		}
		
		//for(String l : AllPOsExport) System.debug(l);
		poExport = String.join(AllPOsExport, '\r');
		
		
		// Receipts!
		//===========================================
		String RctFormat200 = '200,{0},{1},{2},,{3},{4},{5},{6},,,,,,,,,,,,,,,,,,,,';
		
		
		// Receipts based on part transaction history
		//----------------------------------------
		System.debug('Receipts by PO Transaction History');
		List<String> TransRctsExport = new List<String>();
		
		// build po line & qty map for matching ledger entries to lines
		//Map<String, List<String>> PartLineMap = new Map<String, List<String>>();
		//Map<String, Decimal> LineQtyMap = new Map<String, Decimal>();
		//for(dealer__Purchase_Order__c po : polist) {
		//	for(dealer__Purchase_Order_Line__c line : po.dealer__Purchase_Order_Line__r) {
		//		List<String> partlines = PartLineMap.containsKey(line.dealer__Parts_Master__r.Name) ? PartLineMap.get(line.dealer__Parts_Master__r.Name) : new List<String>();
		//		partlines.add(line.Name);
		//		PartLineMap.put(line.dealer__Parts_Master__r.Name, partlines);
		//		LineQtyMap.put(line.Name, line.dealer__Part_Quantity__c);
		//	}
		//}
		
		for(dealer__Purchase_Order__c po : polist) {
			List<String> TransRctExport = new List<String>();

			// skip or include closed/processed POs
			if (IncludeClosedPOs || po.Payable_Invoice__c==null || AllPOsOpen) {
	
				// map part line qtys by po 
				Map<String, List<String>> PartLineMap = new Map<String, List<String>>();
				Map<String, Decimal> LineQtyMap = new Map<String, Decimal>();
				for(dealer__Purchase_Order_Line__c line : po.dealer__Purchase_Order_Line__r) {
					List<String> partlines = PartLineMap.containsKey(line.dealer__Parts_Master__r.Name) ? PartLineMap.get(line.dealer__Parts_Master__r.Name) : new List<String>();
					partlines.add(line.Name);
					PartLineMap.put(line.dealer__Parts_Master__r.Name, partlines);
					LineQtyMap.put(line.Name, line.dealer__Part_Quantity__c);
				}
						
				for(dealer__Part_Inventory_History__c trans : po.dealer__Parts_Inventory_History__r) {
					String DeleteRct = 'N';
					String UOM = 'EACH';
					String RcvDate = trans.dealer__Transaction_Time__c.format(CONCUR_DATE_FMT);
					// adjust transaction qty by pack size
					Decimal qtyRcvd = trans.dealer__Quantity_Adjustment__c;
					if (trans.dealer__Part__r.dealer__Pack_QTY__c>0) 
						qtyRcvd = qtyRcvd / trans.dealer__Part__r.dealer__Pack_QTY__c;
			
					String lineName = '';
					List<String> partlines = PartLineMap.containsKey(trans.dealer__Part__r.dealer__Parts_Master__r.Name) ? PartLineMap.get(trans.dealer__Part__r.dealer__Parts_Master__r.Name) : new List<String>();
					for(String partline : partlines) {
						Decimal qtyremaining = LineQtyMap.get(partline);
						if (String.isBlank(lineName) && qtyremaining > qtyRcvd) {
							qtyremaining -= qtyRcvd;
							LineQtyMap.put(partline, qtyremaining);
							lineName = partline;
						}	
					}
					if (String.isBlank(lineName) && partlines.size()>0) lineName = partlines[0];
					if (String.isBlank(lineName)) lineName = trans.Name;	 // Should never happen!
						TransRctExport.add( String.format( RctFormat200, new List<String>{
							po.dealer__PO_Number__c, lineName, trans.Name,
							UOM,  
							String.valueOf(qtyRcvd),
							RcvDate,
							DeleteRct
						}) );
				}
			}	// end not initial load or no payable invoice yet
		
			TransRctsExport.addAll(TransRctExport);
		}
		
		//for(String l : TransRctsExport) System.debug(l);
		rctExport = String.join(TransRctsExport, '\r');
		
	}

	// FinalizeExport
	//------------------------------------
	public void FinalizeExport() {
		SaveLastExportDT();
		EmailResults();
	}

	// saveLastExportDT
	//----------------------------------
	public void SaveLastExportDT() {
		upsert(mfs);
		mfs = MobilityForceSettings__c.getOrgDefaults();
		updatedSince = mfs.LastConcurExport__c;
		updatedSinceTxt = updatedSince!=null ? updatedSince.format('MM/dd/yyyy hh:mm a') : DateTime.now().addDays(-1).format('MM/dd/yyyy hh:mm a');		
	}

	// emailResults
	//----------------------------------
	public void emailResults() {
		Organization org = [select Id, Name, isSandbox from Organization limit 1];
		List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
		List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();

		String expdatetime = updatedSince.format('yyyy-MM-dd_HHmmss');
		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		List<String> recipients = new List<String>{ UserInfo.getUserEmail() };
		//if (!org.isSandbox) recipients.add('another.email@mobilityworks.com');
		mail.setToAddresses(recipients);
		String subject = 'Concur PO//Rct export results';
		if (org.isSandbox) subject = 'Sandbox: ' + subject; 
		mail.setSubject(subject);
		String body = 'Attached are the Purchase Order and Receipt file for import into Concur.\n\n';
		mail.setPlainTextBody(body);
		
		Messaging.EmailFileAttachment purchaseorders = new Messaging.EmailFileAttachment();
			purchaseorders.setContentType('text/plain');
			purchaseorders.setFileName('PurchaseOrders_' + expdatetime + '.txt');
			purchaseorders.setInline(false);
			purchaseorders.Body = Blob.valueOf(poExport);
			if (!String.isBlank(poExport)) listOfAttachments.add(purchaseorders);
		Messaging.EmailFileAttachment receipts = new Messaging.EmailFileAttachment();
			receipts.setContentType('text/plain');
			receipts.setFileName('POReceipts_' + expdatetime + '.txt');
			receipts.setInline(false);
			receipts.Body = Blob.valueOf(rctExport);
			if (!String.isBlank(rctExport)) listOfAttachments.add(receipts);
		mail.setFileAttachments(listOfAttachments);
		emailMsgs.add(mail);

		// Only send if there's something to send
		if (emailMsgs.size()>0) Messaging.sendEmail(emailMsgs);
		
	}
	
	// Exportdetails
	public class ExportDetails {
		public String poNumber {get;set;}
		public String Status {get;set;}
		public DateTime LastModified {get;set;}
		public Integer NbrLines {get;set;}
		public Integer NbrReceipts {get;set;}
		public Decimal QtyOrdered {get;set;}
		public Decimal QtyReceived {get;set;}
		public Decimal QtyOutstanding {get;set;}
	}

}