/**
 * ConcurPayableProcess
 * Tested by: ConcurPayableProcess_TEST
 * Date: Jul 19, 2018
 * Programmer: Bryan Leaman
 *
 * Coverage:
 *	2018-08-21	83% (231/276)
 *
 * Modification:
 * 
 */
public with sharing class ConcurPayableProcess {

	Map<Id,c2g__codaCompany__c> companyMap;
	Map<Id,dealer__Dealer_Location__c> locationMap;
	Map<String, c2g__codaGeneralLedgerAccount__c> glAcctMap;
	Set<Id> GLsMatchViaPO;
	Id subletRtId;
	Map<Id,Id> dim1Map;
	Map<Id,Id> corpDim1Map;
	List<String> errors;
	public List<String> NotificationRecipients {get;set;}

	// ConcurPayableProcess
	//---------------------------------------
	public ConcurPayableProcess() {
		NotificationRecipients = new List<String>{UserInfo.getUserEmail()};	// default to running user
		
		// Required GLs
        glAcctMap = new Map<String, c2g__codaGeneralLedgerAccount__c>();
        Set<String> glaCodes = new Set<String>{'1220','2115','2100','4905','5304','4950'};
        for(c2g__codaGeneralLedgerAccount__c gl : [
        	select Id, Name, c2g__ReportingCode__c 
        	from c2g__codaGeneralLedgerAccount__c 
        	where c2g__ReportingCode__c IN :glaCodes
        	]) {
            glAcctMap.put(gl.c2g__ReportingCode__c, gl);
        }  
        GLsMatchViaPO = new Set<Id>();
        GLsMatchViaPO.add(glAcctMap.get('2115').Id);

		// All companies & locations
		companyMap = new Map<Id,c2g__codaCompany__c>([select Id, Name, DefaultPayableDimension1__c from c2g__codaCompany__c]);
		locationMap = new Map<Id, dealer__Dealer_Location__c>([select Id, Name, Company__c from dealer__Dealer_Location__c]);
        
        // sublet record type
        Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Purchase_Order__c.getRecordTypeInfosByName();
        Schema.RecordTypeInfo rtInfo = RcdTypes.get('Sublet');
        subletRtId = rtInfo.getRecordTypeId();

		// filled later with all PO ids and their payable dimension1 (from location or company default/override)
        dim1Map = new Map<Id,Id>();
        corpDim1Map = new Map<Id,Id>();
	}


	// PurchaseOrderUpdatesForPayRequests
	public List<dealer__Purchase_Order__c> PurchaseOrderUpdatesForPayRequests(List<ConcurPayableUpload.PayableRequest> payrqsts) {
		// updates to POs (setting invoice nbr & amt, parts, freight, nmeda & misc charge amounts)		
		List<dealer__Purchase_Order__c> updPOs = new List<dealer__Purchase_Order__c>();

		// map to DealerTeam POs referenced in request
		Set<String> poNumbers = new Set<String>();
		System.debug(payrqsts.size());
		for(ConcurPayableUpload.PayableRequest pr : payrqsts) poNumbers.add(pr.PONumber);
		System.debug(poNumbers);
		
		Map<String,dealer__Purchase_Order__c> pomap = new Map<String,dealer__Purchase_Order__c>();
		for(dealer__Purchase_Order__c po :[
			select Id, Name, dealer__PO_Number__c, dealer__Status__c, dealer__Post_Date_Time__c,      
				dealer__Vendor__c, dealer__Vendor__r.Name, dealer__Vendor__r.c2g__CODADaysOffset1__c,  
				dealer__PO_Accounting_Name__c, dealer__Invoice_Number__c, 
				Payable_Invoice__c, Payable_Invoice__r.Name, dealer__Invoice_Amount__c, dealer__Invoice_Date__c,
				dealer__Company__c, dealer__Company__r.Financial_Force_Dimension_1__c,
				dealer__Company__r.Company__c, dealer__Company__r.Company__r.DefaultPayableDimension1__c, 
				Parts_Amount__c, dealer__Freight__c, NMEDA_Fee__c, Misc_Charge__c,
				dealer__PO_Amount__c, dealer__Type__c, RecordTypeId
			from dealer__Purchase_Order__c
			where dealer__PO_Number__c in :poNumbers
		]) {
			pomap.put(po.dealer__PO_Number__c, po);
		}
		
		// cross reference payable requests to PO ids
		//for(ConcurPayableUpload.PayableRequest pr : payrqsts) {
		//	dealer__Purchase_Order__c po = pomap.get(pr.PONumber);
			//if (po!=null) {
		for(dealer__Purchase_Order__c po : pomap.values()) {
				po.Parts_Amount__c = 0;
				po.dealer__Freight__c = 0;
				po.Misc_Charge__c = 0;
				po.NMEDA_Fee__c = 0;
				po.dealer__Invoice_Amount__c = 0;
				po.dealer__Invoice_Number__c = '';
				// po.Id = pr.POId;
				pomap.put(po.dealer__PO_Number__c, po);
		}
			//}
		//}
		System.debug(pomap);

		// generate payable invoices and related lines
		System.debug(payrqsts.size());
		for(ConcurPayableUpload.PayableRequest pr : payrqsts) {
			dealer__Purchase_Order__c po = pomap.get(pr.PONumber);
			System.debug(pr.PONumber);
			System.debug(po);
			if (po!=null) {
				po.dealer__Invoice_Date__c = pr.InvoiceDate;
				if (po.Parts_Amount__c==null) po.Parts_Amount__c = 0.00;
				if (po.dealer__Freight__c==null) po.dealer__Freight__c = 0.00;
				if (po.NMEDA_Fee__c==null) po.NMEDA_Fee__c = 0.00;
				if (po.Misc_Charge__c==null) po.Misc_Charge__c = 0.00;

				//NOTE: need to accumulate all request lines for a PO!
				po.Parts_Amount__c += pr.TotalPrice!=null ? pr.TotalPrice : 0;
				po.dealer__Freight__c += pr.LineShippingAmt;
				po.NMEDA_Fee__c += pr.NMEDAAmt;
				po.Misc_Charge__c += 0;	// not supported?
				po.dealer__Invoice_Amount__c = pr.InvoiceAmt;	// total on each line
				po.dealer__Invoice_Number__c = pr.InvoiceNbr;	// inv# is on each line
				pr.po = po;
				pr.poId = po.Id;
				pomap.put(pr.PONumber,po);
			}
		}
		updPOs = pomap.values();
		System.debug(updPOs.size());
		System.debug(updPOs);
		
		return updPOs;	
	}


	// ChunkPOsByCompany
	public Map<String, List<dealer__Purchase_Order__c>> ChunkPOsByCompany(List<dealer__Purchase_Order__c> polist, Integer maxPerChunk) {
		Map<String, List<dealer__Purchase_Order__c>> pomap = new Map<String, List<dealer__Purchase_Order__c>>();
		Map<Id,Integer> cmpCountMap = new Map<Id,Integer>();
		if (maxPerChunk==null || maxPerChunk<1) maxPerChunk = 100;
		
		for(dealer__Purchase_Order__c po : polist) {
			Integer nbrPos = cmpCountMap.get(po.dealer__Company__r.Company__c);
			if (nbrPos==null) nbrPOs = 0;
			Integer chunknbr = (Integer) nbrPOs / maxPerChunk;
			
			String key = po.dealer__Company__r.Company__c + '_' + String.valueOf(chunknbr);
			List<dealer__Purchase_Order__c> pochunk = pomap.get(key);
			if (pochunk==null) pochunk = new List<dealer__Purchase_Order__c>();
			pochunk.add(po);	
			
			nbrPos += 1;
			cmpCountMap.put(po.dealer__Company__r.Company__c, nbrPos);
			pomap.put(key,pochunk);
		}
		return pomap;	
	}

	
	// CreatePurchaseInvoices
	// List of POIds *must* be in the same FF company!
	public void ProcessPurchaseInvoices(List<dealer__Purchase_Order__c> polist) {
		List<String> processedRcds;
		errors = new List<String>();
		// Dimensions...
		for(dealer__Purchase_Order__c po : polist) {
			dim1Map.put(po.Id, po.dealer__Company__r.Financial_Force_Dimension_1__c);
			corpDim1Map.put(po.Id, po.dealer__Company__r.Financial_Force_Dimension_1__c);
			if (po.dealer__Company__r.Company__r.DefaultPayableDimension1__c!=null)
        		corpDim1Map.put(po.Id, po.dealer__Company__r.Company__r.DefaultPayableDimension1__c);    
        }
		
		// payable invoices to create
		List<c2g__codaPurchaseInvoice__c> pilist = new List<c2g__codaPurchaseInvoice__c>();
		// payable lines to create, linked to payable invoice
		Map<Integer,List<c2g__codaPurchaseInvoiceExpenseLineItem__c>> linesmap = new Map<Integer,List<c2g__codaPurchaseInvoiceExpenseLineItem__c>>();
		List<c2g__codaPurchaseInvoiceExpenseLineItem__c> allLines = new List<c2g__codaPurchaseInvoiceExpenseLineItem__c>();

		// generate payable invoices and related lines
		Map<Id,c2g__codaPurchaseInvoice__c> poPinMap = new Map<Id,c2g__codaPurchaseInvoice__c>();
		DateTime currentdt = DateTime.now();
		for(dealer__Purchase_Order__c po : polist) {
			c2g__codaPurchaseInvoice__c pi = createPayableInvoice(po);
			pilist.add(pi);
			linesmap.put(pilist.size(), createPayableInvoiceLines(po));
			//po.dealer__Status__c='Posted';
			po.dealer__Post_Date_Time__c=currentdt;
			poPinMap.put(po.Id, pi);
		}

		try {
	
			// Insert payable invoices
			insert(pilist);
			
			// assign created payable invoice id to PO
			for(dealer__Purchase_Order__c po : polist) {
				c2g__codaPurchaseInvoice__c pi = poPinMap.get(po.Id);
				po.Payable_Invoice__c = pi.Id;
			}

			// update POs with posted status and date/time
			update(polist);
			
			// re-read records to get assigned PIN names
			Set<Id> pinIds = new Set<Id>();
			for(c2g__codaPurchaseInvoice__c pi : pilist) pinIds.add(pi.Id);
			List<c2g__codaPurchaseInvoice__c> newpilist = [
				select Id, Name, c2g__InvoiceDescription__c, c2g__AccountInvoiceNumber__c
				from c2g__codaPurchaseInvoice__c 
				where Id in :pinIds
			];
			
			// Assign purchase invoice Id to its lines
			for(Integer i=0; i<pilist.size(); i++) {
				c2g__codaPurchaseInvoice__c pi = pilist[i];
				List<c2g__codaPurchaseInvoiceExpenseLineItem__c> pilines = linesmap.get(i+1);
				Decimal balance = 0;
				for(c2g__codaPurchaseInvoiceExpenseLineItem__c line : pilines) {
					line.c2g__PurchaseInvoice__c = pi.Id;
					balance += line.c2g__NetValue__c;
				}
				if (balance!=0) {
					errors.add(pi.Name + ' for ' + pi.c2g__InvoiceDescription__c
						+ ' does not balance to $0 -- actual balance is ' + String.valueOf(balance));
				}
				allLines.addAll(pilines);
			}
			insert(allLines);	
			
			processedRcds = new List<String>();
			
			// post PINs ?
        	c2g__codaCompany__c comp = companyMap.get(polist[0].dealer__Company__r.Company__c);
			c2g.CODAAPICommon_9_0.Context ctx9 = new c2g.CODAAPICommon_9_0.Context();
			ctx9.CompanyName = comp.Name;
			List<c2g.CODAAPICommon.Reference> bulkPINs = new List<c2g.CODAAPICommon.Reference>();
			for(c2g__codaPurchaseInvoice__c pin : newpilist) {
				processedRcds.add(pin.Name + ', ' + pin.c2g__AccountInvoiceNumber__c + ', ' + pin.c2g__InvoiceDescription__c);
				bulkPINs.add(c2g.CODAAPICommon.Reference.getRef(pin.Id, null));
			}
			MW_TriggerControls__c PostUploadedPINs = MW_TriggerControls__c.getInstance('PostUploadedPINs');
			if (PostUploadedPINs==null || PostUploadedPINs.Enabled__c==true) {
				try {
					c2g.CODAAPIPurchaseInvoice_9_0.BulkPostPurchaseInvoice(ctx9, bulkPINs);
					NotifySuccess(processedRcds);
				} catch(Exception e) {
					NotifyError('Posting Payable Invoices Failed', processedRcds, e);
				}
			}
			
		} catch(Exception e) {
			NotifyError('Error generating Payable Invoices', polist, e);
		}
		
	}
	

	public void NotifyError(String msg, List<dealer__Purchase_Order__c> polist, Exception e) {
		Organization org = [select Id, Name, isSandbox from Organization limit 1];
		String subject = 'Concur payable process failure';
		String body = msg + '\n' + e.getMessage() + '\n\n';
		for(dealer__Purchase_Order__c po : polist) {
			body += po.dealer__PO_Number__c + '\n';
		}
		if (org.isSandbox) body = 'SANDBOX TEST RUN\n\n' + body;
		List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setToAddresses(NotificationRecipients); 
		mail.setSubject(subject);
		mail.setPlainTextBody(body);
		emailMsgs.add(mail);
		Messaging.sendEmail(emailMsgs);
	}
	public void NotifyError(String msg, List<String> records, Exception e) {
		Organization org = [select Id, Name, isSandbox from Organization limit 1];
		String subject = 'Concur payable process failure';
		String body = msg + '\n' + e.getMessage() + '\n\n';
		for(String rcd : records) {
			body += rcd + '\n';
		}
		if (org.isSandbox) body = 'SANDBOX TEST RUN\n\n' + body;
		List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setToAddresses(NotificationRecipients); 
		mail.setSubject(subject);
		mail.setPlainTextBody(body);
		emailMsgs.add(mail);
		Messaging.sendEmail(emailMsgs);
	}

	public void NotifySuccess(List<String> records) {
		Organization org = [select Id, Name, isSandbox from Organization limit 1];
		String subject = 'Concur payable process completion';
		String body = 'The following payable invoices have been processed:\n\n';
		for(String rcd : records) {
			body += rcd + '\n';
		}
		if (org.isSandbox) body = 'SANDBOX TEST RUN\n\n' + body;
		List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setToAddresses(NotificationRecipients); 
		mail.setSubject(subject);
		mail.setPlainTextBody(body);
		emailMsgs.add(mail);
		Messaging.sendEmail(emailMsgs);
	}

    /*
    *
    *   CreatePayableInvoice - 
    *       Creates the header record for a payable invoice.  The payable invoice is generated once Accounting applys a Vendor Invoice to a Purchase Order
    */
    public c2g__codaPurchaseInvoice__c createPayableInvoice(dealer__Purchase_Order__c po) {

		c2g__codaPurchaseInvoice__c p = new c2g__codaPurchaseInvoice__c();
        try {
			// Get company
            c2g__codaCompany__c comp = companyMap.get(po.dealer__Company__r.Company__c);

            // Get Accounting Currency
            c2g__codaAccountingCurrency__c curr = [Select Id from c2g__codaAccountingCurrency__c where c2g__OwnerCompany__c =:comp.Id limit 1];
            // Get Period Data
            // c2g__codaPeriod__c period = [Select Id from c2g__codaPeriod__c where c2g__StartDate__c >=:Date.today() and c2g__Closed__c=false limit 1];
            Id dim1Id = dim1Map.get(po.Id);
            Id corpDim1Id = corpDim1Map.get(po.Id);
			Date duedate = po.dealer__Invoice_Date__c;
			if (duedate==null) duedate = Date.today();
			if (po!=null && po.dealer__Vendor__c!=null && po.dealer__Vendor__r.c2g__CODADaysOffset1__c!=null) 
				duedate = duedate.addDays(Integer.valueOf(po.dealer__Vendor__r.c2g__CODADaysOffset1__c));
			if (duedate<po.dealer__Invoice_Date__c) duedate = po.dealer__Invoice_Date__c;
			if (duedate<Date.today()) duedate = Date.today();

			if (po!=null) System.debug(po.dealer__Invoice_Date__c);
			if (po!=null && po.dealer__Vendor__c!=null) System.debug(po.dealer__Vendor__r.c2g__CODADaysOffset1__c);
			System.debug(duedate);

            p.c2g__Account__c       =   po.dealer__Vendor__c;
            p.c2g__OwnerCompany__c  =   comp.Id;
            p.c2g__Dimension1__c = corpDim1Id;
            p.ffap__DeriveDueDate__c=   false;
            p.ffap__DerivePeriod__c =   true;
            p.c2g__DeriveDueDate__c=    false; 
            p.c2g__DerivePeriod__c =    true;  
            //p.c2g__InvoiceDate__c   =   po.dealer__Invoice_Date__c;
            p.c2g__InvoiceDate__c = Date.today();
            p.c2g__DueDate__c = duedate;
            if (p.c2g__InvoiceDate__c==null) p.c2g__InvoiceDate__c = Date.today();
            p.c2g__InvoiceCurrency__c   =   curr.Id;
            p.c2g__InvoiceDescription__c=   po.dealer__PO_Accounting_Name__c;
            p.c2g__AccountInvoiceNumber__c= po.dealer__Invoice_Number__c;
            p.c2g__InvoiceStatus__c = 'In Progress';
            p.ffap__CopyAccountValues__c = false; 
            p.c2g__CopyAccountValues__c = false;  
            p.Source__c = 'PB'; 

        } catch(DmlException e) {
            throw new POException('Error Creating Payable Invoice from Purchase Order '+e.getMessage());
        }

        return p;
    }


	/*
	 * CreatePayableInvoiceLines
	*/
	public List<c2g__codaPurchaseInvoiceExpenseLineItem__c> createPayableInvoiceLines(dealer__Purchase_Order__c po) {

		// Iterate TLines for the Expense Lines to be placed on a Purchase Order
		List<c2g__codaPurchaseInvoiceExpenseLineItem__c> pl = new List<c2g__codaPurchaseInvoiceExpenseLineItem__c>();

		String controlnbr = po.dealer__PO_Accounting_Name__c; 
		System.debug(po);

		// Payable line - is generated automatically when posting the PIN
        //if(po.dealer__Invoice_Amount__c > 0) {
		//	pl.add(new c2g__codaPurchaseInvoiceExpenseLineItem__c(
		//		c2g__NetValue__c = -po.dealer__Invoice_Amount__c,
		//		c2g__LineDescription__c = po.dealer__Vendor__r.Name + ': ' + po.dealer__PO_Accounting_Name__c,
		//		c2g__Dimension1__c = dim1Map.get(po.Id),
		//		ffap__SetGLAToDefault__c = false,
		//		c2g__SetGLAToDefault__c = false, 
		//		c2g__GeneralLedgerAccount__c = glAcctMap.get('2100').Id,
		//		Control__c = controlnbr 
		//	));
        //}

		// Sublet and Miscellaneous - unbilled (not used at present)
		// NOTE: What if dealer__PO_Amount__c != dealer__Invoice_Amount__c ???
        //if(po.dealer__Type__c == 'Sublet' || po.dealer__Type__c == 'Miscellaneous') {
		//	pl.add(new c2g__codaPurchaseInvoiceExpenseLineItem__c(
		//		c2g__NetValue__c = po.dealer__PO_Amount__c,
		//		c2g__LineDescription__c = po.dealer__Vendor__r.Name + ': ' + po.dealer__PO_Accounting_Name__c,
		//		c2g__Dimension1__c = dim1Map.get(po.Id),
		//		ffap__SetGLAToDefault__c = false,
		//		c2g__SetGLAToDefault__c = false, 
		//		c2g__GeneralLedgerAccount__c = glAcctMap.get('2115').Id,
		//		Control__c = controlnbr 
		//	));
        //}

		// Parts PO
		if (po.dealer__Type__c != 'Sublet' && po.dealer__Type__c != 'Miscellaneous') {	
			// ensure no nulls in arithmetic
			if (po.Parts_Amount__c==null) po.Parts_Amount__c = 0;
			if (po.dealer__Freight__c==null) po.dealer__Freight__c = 0;
			if (po.NMEDA_Fee__c==null) po.NMEDA_Fee__c = 0;
			if (po.Misc_Charge__c==null) po.Misc_Charge__c = 0;
			System.debug(po);
				
			// Unbilled purchases
			if (po.Parts_Amount__c!=null & po.Parts_Amount__c!=0) {
				pl.add(new c2g__codaPurchaseInvoiceExpenseLineItem__c(
					c2g__NetValue__c=po.Parts_Amount__c,
					c2g__LineDescription__c=po.dealer__Vendor__r.Name + ': ' + po.dealer__PO_Accounting_Name__c,
					c2g__Dimension1__c=dim1Map.get(po.Id),
					ffap__SetGLAToDefault__c=false,
					c2g__SetGLAToDefault__c=false, 
					c2g__GeneralLedgerAccount__c=glAcctMap.get('2115').Id,
					Control__c=controlnbr 
				));
			}
				
			// Purchase variance
			// If PA & PO != Apply Difference to Clear Entry
			if(po.Parts_Amount__c > 0 && (po.dealer__PO_Amount__c != po.Parts_Amount__c)) {
				// Unbilled purchases adjustment
				pl.add(new c2g__codaPurchaseInvoiceExpenseLineItem__c(
					c2g__NetValue__c=(po.dealer__PO_Amount__c - po.Parts_Amount__c),
					c2g__LineDescription__c=po.dealer__Vendor__r.Name + ': ' + po.dealer__PO_Accounting_Name__c,
					c2g__Dimension1__c=dim1Map.get(po.Id),
					ffap__SetGLAToDefault__c=false,
					c2g__SetGLAToDefault__c=false,  
					c2g__GeneralLedgerAccount__c=glAcctMap.get('2115').Id,
					Control__c=controlnbr  
				));
				// PPV
				pl.add(new c2g__codaPurchaseInvoiceExpenseLineItem__c(
					c2g__NetValue__c=(po.Parts_Amount__c - po.dealer__PO_Amount__c),
					c2g__LineDescription__c=po.dealer__Vendor__r.Name + ': ' + po.dealer__PO_Accounting_Name__c,
					c2g__Dimension1__c=dim1Map.get(po.Id),
					ffap__SetGLAToDefault__c=false,
					c2g__SetGLAToDefault__c=false,  
					c2g__GeneralLedgerAccount__c=glAcctMap.get('4950').Id,
					Control__c=controlnbr  
				));
			}
	
			// Freight
			if(po.dealer__Freight__c != null && po.dealer__Freight__c > 0) {
				pl.add(new c2g__codaPurchaseInvoiceExpenseLineItem__c(
					c2g__NetValue__c=po.dealer__Freight__c,
					c2g__LineDescription__c=po.dealer__Vendor__r.Name + ': ' + po.dealer__PO_Accounting_Name__c,
					c2g__Dimension1__c=dim1Map.get(po.Id),
					ffap__SetGLAToDefault__c=false,
					c2g__SetGLAToDefault__c=false,  
					c2g__GeneralLedgerAccount__c=glAcctMap.get('4905').Id,
					Control__c=controlnbr  
				));
			}

			// NMEDA Fee
			if(po.NMEDA_Fee__c != null && po.NMEDA_Fee__c > 0) {
				pl.add(new c2g__codaPurchaseInvoiceExpenseLineItem__c(
					c2g__NetValue__c=po.NMEDA_Fee__c,
					c2g__LineDescription__c=po.dealer__Vendor__r.Name + ': ' + po.dealer__PO_Accounting_Name__c,
					c2g__Dimension1__c=dim1Map.get(po.Id),
					ffap__SetGLAToDefault__c=false,
					c2g__SetGLAToDefault__c=false,  
					c2g__GeneralLedgerAccount__c=glAcctMap.get('5304').Id,
					Control__c=controlnbr  
				));
			}

        	// Misc Charge - not yet supported -- need to know GL account#!
			// RT1 - misc can be less than 0
        	if(po.Misc_Charge__c!= null && po.Misc_Charge__c != 0) {    
				pl.add(new c2g__codaPurchaseInvoiceExpenseLineItem__c(
				c2g__NetValue__c=po.Misc_Charge__c,
				c2g__LineDescription__c=po.dealer__Vendor__r.Name + ': ' + po.dealer__PO_Accounting_Name__c,
				c2g__Dimension1__c=dim1Map.get(po.Id),
					ffap__SetGLAToDefault__c=false,
					c2g__SetGLAToDefault__c=false,  
					c2g__GeneralLedgerAccount__c=glAcctMap.get('xxxx').Id,
					Control__c=controlnbr  
				));
        	}
		}

		// Adjust control# on sublets except for 2115 acct
		for(c2g__codaPurchaseInvoiceExpenseLineItem__c piel : pl) {
			if (po.RecordTypeId==subletRtId && po.dealer__Service_Repair_Order__r.Name!=null) {
				if (!GLsMatchViaPO.contains(piel.c2g__GeneralLedgerAccount__c))
					piel.Control__c = po.dealer__Service_Repair_Order__r.Name;
			}
		}
		
		return pl;
	}


	public class POException extends Exception {}

}