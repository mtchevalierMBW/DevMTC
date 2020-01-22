/**
 * JournalLineItemProcess
 * Tested by: TransactionReferences_TEST, ReversingJournal_TEST, JournalLineItemProcessTest
 * Date: May 8, 2017
 * Programmer: Bryan Leaman
 *
 *	Code coverage:
 *	2018-04-26	73% (77/105) w/o a reversing journal available for ReversingJournal_TEST (uses seealldata)
 *				92% (97/105) with a reversing journal available for ReversingJournal_TEST (uses seealldata)
 *  2018-07-30  71% (0/136)
 *  2018-08-14  70% (95/135)
 *
 *
 *	Modification log:
 *	2018-04-26	B. Leaman	BLL1 - default control# for SIN and SCR journals (TransitWorks)
 *  2018-07-30  A. Miller   AMILLER1 - Update to change the cost line item of a SOISS journal header to the RootStock Division's cost dimension before inserting
 *	2019-07-09	B. Leaman	BLL2 - TransitWorks name change to Driverge Vehicle Innovations.
 *	2019-07-22	B. Leaman	BLL3 - handle test failures by being more conditional about setting value if linkage breaks down
 */
public with sharing class JournalLineItemProcess {

	List<c2g__codaJournalLineItem__c> newlist;
	Map<Id,c2g__codaJournalLineItem__c> oldMap;
	Map<Id, c2g__codaJournal__c> jrnMap;
	
	// JournalLineItemProcess
	//---------------------------------------
	public JournalLineItemProcess(List<c2g__codaJournalLineItem__c> nlist, Map<Id,c2g__codaJournalLineItem__c> oMap) {
		newlist = nlist;
		oldMap = omap;
	} // end constructor


	// build map of referenced journal headers
	//-------------------------------------------------
	public void BuildJournalMap() {
		// only build once
		if (jrnMap!=null) return;
		jrnMap = new Map<Id, c2g__codaJournal__c>();
        Set<Id> jrnIds = new Set<Id>();
        for(c2g__codaJournalLineItem__c l : newList) jrnIds.add(l.c2g__Journal__c);
        if (jrnIds.size()>0) {
        	for(c2g__codaJournal__c j : 
        	    [ select Id, Name, Customer__c, Sales_Person__c, Third_Party_Payor__c, Other_Payor__c, Vendor__c, c2g__Type__c,
        	    	c2g__SourceJournal__c, c2g__OriginalJournal__c, c2g__JournalDescription__c,  
        	    	c2g__OwnerCompany__r.Name, c2g__OwnerCompany__r.c2g__ExternalId__c
        	      from c2g__codaJournal__c 
        	      where Id in :jrnIds]) {
				jrnMap.put(j.Id, j);
			}
        }
	} // end BuildJournalMap
	

	// Supply missing DIM1 on cash matching lines
	//-------------------------------------------------
	public void MissingDim1OnCashMatch() {
        Set<String> CashMatchPINs = new Set<String>(); 
		Set<Id> CashMatchJournals = new Set<Id>();

		// Build map of journal headers
		BuildJournalMap();

        for(c2g__codaJournal__c j : jrnMap.values()) { 
			if (j.c2g__Type__c=='Cash Matching Journal') CashMatchJournals.add(j.Id);
        }

		// get set of journals and referenced cash matching PIN numbers
        for(c2g__codaJournalLineItem__c l : newList) {
            String pin = null;
            if (l.c2g__LineDescription__c!=null && l.c2g__LineDescription__c.contains(' PIN')) pin=l.c2g__LineDescription__c.substring(l.c2g__LineDescription__c.indexOf(' PIN')).trim();
            if (l.c2g__Dimension1__c==null && !String.isBlank(pin)) CashMatchPINs.add(pin); 
        }
    
        // get PIN header dimension 1's
        Map<String,Id> pinDim1 = new Map<String,Id>();
        if (CashMatchPINs.size()>0) {
            List<c2g__codaPurchaseInvoice__c> payableInvs = [
                select Id, Name, c2g__Dimension1__c
                from c2g__codaPurchaseInvoice__c
                where Name in :CashMatchPINs
            ];
            for(c2g__codaPurchaseInvoice__c pi : payableInvs) pinDim1.put(pi.Name, pi.c2g__Dimension1__c);
        }
        
		// Supply missing DIM1s from PIN
        for(c2g__codaJournalLineItem__c l : newList) {
			if (l.c2g__Dimension1__c==null && CashMatchJournals.contains(l.c2g__Journal__c)) {
				String pin = null;
				if (l.c2g__LineDescription__c!=null && l.c2g__LineDescription__c.contains(' PIN')) pin=l.c2g__LineDescription__c.substring(l.c2g__LineDescription__c.indexOf(' PIN')).trim();
				l.c2g__Dimension1__c = pinDim1.get(pin);
			}
		}
		
	} // end MissingDim1OnCashMatch
	
	
	// Copy reference fields from journal header (if missing on lines)
	//-----------------------------------------------
	public void CopyRefsFromJournalHeader() {
        Map<Id, Id> jCustomer = new Map<Id, Id>();
        Map<Id, Id> jSalesperson = new Map<Id, Id>();
        Map<Id, Id> jThirdParty = new Map<Id, Id>();   
        Map<Id, Id> jVendor = new Map<Id, Id>();

		// Build map of journal headers
		BuildJournalMap();

        for(c2g__codaJournal__c j : jrnMap.values()) { 
            jCustomer.put(j.Id, j.Customer__c);
            jSalesperson.put(j.Id, j.Sales_Person__c);
            jThirdParty.put(j.Id, j.Third_Party_Payor__c);
            jVendor.put(j.Id, j.Vendor__c);
        }

        for(c2g__codaJournalLineItem__c l : newList) {
            if (l.Sales_Person__c==null) l.Sales_Person__c = jSalesperson.get(l.c2g__Journal__c);
            if (l.Customer_Name__c==null) l.Customer_Name__c = jCustomer.get(l.c2g__Journal__c);
            if (l.Third_Party_Payor__c==null) l.Third_Party_Payor__c = jThirdParty.get(l.c2g__Journal__c);
            if (l.Vendor_Name__c==null) l.Vendor_Name__c = jVendor.get(l.c2g__Journal__c);
        }		
	} // end CopyRefsFromJournalHeader


	// Copy custom fields from source of reversing or cancelling journal lines
	public void CopyCustomFromReferencedJournal() {
		// Map journal to source journal - only for reversing journals
		Set<Id> srcJrn = new Set<Id>();
		Map<Id,Id> jrnRefIdSrcIdMap = new Map<Id,Id>();  // Journal to source journal

		// Build map of journal headers
		BuildJournalMap();
            
		for(c2g__codaJournal__c j : jrnMap.values()) {
			if (j.c2g__Type__c=='Reversing Journal' || j.c2g__Type__c=='Cancelling Journal') {
				if (j.c2g__SourceJournal__c!=null) srcJrn.add(j.c2g__SourceJournal__c);	
				if (j.c2g__SourceJournal__c!=null) jrnRefIdSrcIdMap.put(j.Id, j.c2g__SourceJournal__c);	
				if (j.c2g__OriginalJournal__c!=null) srcJrn.add(j.c2g__OriginalJournal__c);	
				if (j.c2g__OriginalJournal__c!=null) jrnRefIdSrcIdMap.put(j.Id, j.c2g__OriginalJournal__c);	
				System.debug(j);
			} // if reversing or cancelling journal
		} // for journals
            
		// Map sourcejournalid + '-' + line number to source journal line
		Map<String,c2g__codaJournalLineItem__c> srcLineMap = new Map<String,c2g__codaJournalLineItem__c>();
		if (srcJrn.size()>0) {
			for(c2g__codaJournalLineItem__c srcl : [
				select Id, Name, c2g__LineNumber__c, c2g__Journal__c, 
					Control__c, Customer_Name__c, Finance_Company__c, 
					Sales_Person__c, Stock_Number__c, Third_Party_Payor__c, Vehicle_Inventory__c, Vendor_Name__c
				from c2g__codaJournalLineItem__c 
				where c2g__Journal__c in :srcJrn
				]) {
				String key = srcl.c2g__Journal__c + '-' + String.valueOf(Integer.valueOf(srcl.c2g__LineNumber__c));
				srcLineMap.put(key, srcl);
				System.debug(key);
				System.debug(srcl);
			} // for soql source journals
		} // srcJrn.size()>0
            
		// For each line, get corresponding line from source journal and copy in custom fields
		for(c2g__codaJournalLineItem__c l : newList) {
			Id srcId = jrnRefIdSrcIdMap.get(l.c2g__Journal__c);
			if (srcId!=null) {
				String key = srcId + '-' + String.valueOf(Integer.valueOf(l.c2g__LineNumber__c));
				c2g__codaJournalLineItem__c sl = srcLineMap.get(key);
				System.debug(key);
				System.debug(sl);
				if (sl!=null) {
					l.Control__c = sl.Control__c;
					l.Customer_Name__c = sl.Customer_Name__c;
					l.Finance_Company__c = sl.Finance_Company__c;
					l.Sales_Person__c = sl.Sales_Person__c;
					l.Stock_Number__c = sl.Stock_Number__c;
					l.Third_Party_Payor__c = sl.Third_Party_Payor__c;
					l.Vehicle_Inventory__c = sl.Vehicle_Inventory__c;
					l.Vendor_Name__c = sl.Vendor_Name__c;
				} // sourcejournalline!=null
			} // srcId!=null
		} // for newList 		
	} // end CopyCustomFromReferencedJournal 


	// ControlNbrForRootstockPORcpts
	//------------------------------------------
	public void ControlNbrForRootstockPORcpts() {
		Set<String> PORcpDesc = new Set<String>{'PORCPT','PORCPTR','ODC','SHOPSUPCOM'};

		// Build map of journal headers
		BuildJournalMap();
		
		Set<Id> rcptJrnIds = new Set<Id>();
		for(c2g__codaJournalLineItem__c jl : newList) {
			c2g__codaJournal__c jrn = jrnMap.get(jl.c2g__Journal__c);
			// BLL2
			//if (jrn!=null && PORcpDesc.contains(jrn.c2g__JournalDescription__c)
			//	&& jrn.c2g__OwnerCompany__r.Name.contains('TransitWorks')) rcptJrnIds.add(jl.c2g__Journal__c);
			if (jrn!=null && PORcpDesc.contains(jrn.c2g__JournalDescription__c)
				&& (jrn.c2g__OwnerCompany__r.c2g__ExternalId__c=='TWK'))
				rcptJrnIds.add(jl.c2g__Journal__c);
			// BLL2 end
		}

		// Get receipt numbers from rootstock cost transaction(s) for the journals
		List<rstk__sytxncst__c> csttrns = [
			select Id, Name, rstk__sytxncst_journalentryno__c, rstk__sytxncst_porcptno__c, rstk__sytxncst_ord__c
			from rstk__sytxncst__c 
			where rstk__sytxncst_journalentryno__c in :rcptJrnIds
			  and CreatedDate = LAST_N_DAYS:14
		];
		Set<Decimal> rcptnos = new Set<Decimal>();
		Map<String,rstk__sytxncst__c> jrnTxnCstMap = new Map<String,rstk__sytxncst__c>();
		for(rstk__sytxncst__c csttrn : csttrns) {
			//BLLd rcptnos.add(csttrn.rstk__sytxncst_porcptno__c);
			jrnTxnCstMap.put(csttrn.rstk__sytxncst_journalentryno__c, csttrn);
		}
		
		// Get PO from receipts
		//BLLd List<rstk__porcptap__c> porcpts = [
		//BLLd 	select Id, Name, rstk__porcptap_rcptno__c, rstk__porcptap_ordno__c, rstk__porcptap_ordno__r.rstk__pohdr_ordno__c
		//BLLd 	from rstk__porcptap__c
		//BLLd 	where rstk__porcptap_rcptno__c in :rcptnos
		//BLLd ];
		//BLLd Map<Decimal,rstk__porcptap__c> porcptmap = new Map<Decimal,rstk__porcptap__c>();
		//BLLd for(rstk__porcptap__c por : porcpts) {
		//BLLd 	porcptmap.put(por.rstk__porcptap_rcptno__c, por);
		//BLLd }

		// Update journal lines' Control# ponumber-rcpt
		for(c2g__codaJournalLineItem__c jl : newList) {
			rstk__sytxncst__c costtrn = jrnTxnCstMap.get(jl.c2g__Journal__c);
			//rstk__porcptap__c porcpt = null; 
			if (costtrn!=null) {
				//BLLd porcpt = porcptmap.get(costtrn.rstk__sytxncst_porcptno__c);
				//String newControl = porcpt.rstk__porcptap_ordno__r.rstk__pohdr_ordno__c + '-' + costtrn.rstk__sytxncst_porcptno__c;
				//jl.Control__c=newControl;
				//BLLd jl.Control__c = (porcpt!=null ? porcpt.rstk__porcptap_ordno__r.rstk__pohdr_ordno__c : costtrn.rstk__sytxncst_ord__c); 
					// BLLd + '-' + costtrn.rstk__sytxncst_porcptno__c;
				jl.Control__c = costtrn.rstk__sytxncst_ord__c;
			} // end costtrn!=null && porcpt!=null
		} // end for journal lines
			
	} // end ControlNbrForRootstockPORcpts

	// BLL1a
	// DefaultControlForSlsInvAndCrd 
	// use first "word" from c2g__JournalReference__c if control# is empty (SIN# or SCR#)
	public void DefaultControlForSlsInvAndCrd() {
		Set<String> prefixes = new Set<String>{'SIN','SCR'};
		
		for(c2g__codaJournalLineItem__c jl : newList) {
			System.debug(jl.JournalReference__c);
			String pfx = String.isBlank(jl.JournalReference__c) ? '' : jl.JournalReference__c.left(3);
			System.debug(pfx); 
			if (String.isBlank(jl.Control__c) && !String.isBlank(jl.JournalReference__c)
				&& prefixes.contains(pfx) ) {
				jl.Control__c = jl.JournalReference__c.split(' ')[0];
				System.debug(jl.Control__c);
			}
		}
	}
	// BLL1a end

	// AMILLER1
    /**
	* transitWorksDefaultInvoiceCogsDimension
	*
	* Function which changes the Dimension 1 value of the journal line 
	* item for the finished good releivement line on invoicing
	*/
    public void transitWorksDefaultInvoiceCogsDimension()
    {
        System.debug(newlist);
        
        // 1. Cycle through all of the Journal Line Items for Invoice Lines hitting COGs (Line Description = 'SOISS', and Debit/Credit = 'Credit') and keep a list of them
    	List<c2g__codaJournalLineItem__c> listOfCogLines = new List<c2g__codaJournalLineItem__c>();
     	
        for(c2g__codaJournalLineItem__c tempItem : newlist)
        {
            if(tempItem.c2g__LineDescription__c == 'SOISS' && 
                tempItem.c2g__DebitCredit__c == 'Credit')
            {
                listOfCogLines.add(tempItem);
            }
        }
        
        System.debug(listOfCogLines);
        
    	// 2. Cycle through the cleaned list and collect the IDs to query Cost Transactions matching the Journal Header
    	List<Id> listOfJournalHeaderIds = new List<Id>();
        
        for(c2g__codaJournalLineItem__c tempLine : listOfCogLines)
        {
            listOfJournalHeaderIds.add(tempLine.c2g__Journal__c);
        }
        
        System.debug(listOfJournalHeaderIds);
        
        // 3. Query the Cost Transactions for the same Journal Headers. Collect Division Cost Dimension
        List<rstk__sytxncst__c> listOfCostTransactions = ([SELECT Id,
                                                            	rstk__sytxncst_div__c,
                                                                rstk__sytxncst_div__r.rstk__sydiv_dimval__c,
                                                           		rstk__sytxncst_div__r.rstk__sydiv_dimval__r.rstk__sydim_dimval__c,
                                                           		rstk__sytxncst_journalentryno__c
                                                           FROM rstk__sytxncst__c
                                                           WHERE rstk__sytxncst_journalentryno__c IN :listOfJournalHeaderIds 
                                                               // If you hit a non-selective query, try logged-in user's manufacturing user record as an indexed filter. Wasn't originally added due to SOQL limit concerns
                                                               AND CreatedDate = LAST_N_Days:30
															ORDER BY CreatedDate DESC
															]);
        
        Map<Id, rstk__sytxncst__c> mapOfTransactionsByJournal = new Map<Id, rstk__sytxncst__c>();
        
        for(rstk__sytxncst__c tempTran : listOfCostTransactions)
        {
            mapOfTransactionsByJournal.put(tempTran.rstk__sytxncst_journalentryno__c, tempTran);
        }
        
        System.debug(mapOfTransactionsByJournal);
        
        // 4. Query the database for the FinancialForce equivalent dimensions
        Set<String> setOfDimensionValues = new Set<String>();
        
        for(rstk__sytxncst__c tempTransaction : listOfCostTransactions)
        {
			System.debug(tempTransaction);
            setOfDimensionValues.add(tempTransaction.rstk__sytxncst_div__r.rstk__sydiv_dimval__r.rstk__sydim_dimval__c);
        }

		System.debug(setOfDimensionValues);
        
        List<c2g__codaDimension1__c> listOfFFDimensions = ([SELECT Id,
                                                            	c2g__ReportingCode__c
                                                            FROM c2g__codaDimension1__c 
                                                            WHERE c2g__ReportingCode__c IN :setOfDimensionValues]);
        
        Map<String, c2g__codaDimension1__c> mapOfFFDimensionsByReportingCode = new Map<String, c2g__codaDimension1__c>();
        
        for(c2g__codaDimension1__c tempDim : listOfFFDimensions)
        {
        	mapOfFFDimensionsByReportingCode.put(tempDim.c2g__ReportingCode__c, tempDim);
        }
        
        System.debug(setOfDimensionValues);
        System.debug(mapOfFFDimensionsByReportingCode);
        
        // 5. Assign the Cost Dimension to all the lines still in the list to be updated in the Before Insert context
        for(c2g__codaJournalLineItem__c tempLineItem : listOfCogLines)
        {
			// BLL3
			//tempLineItem.c2g__Dimension1__c = mapOfFFDimensionsByReportingCode.get(mapOfTransactionsByJournal.get(tempLineItem.c2g__Journal__c).rstk__sytxncst_div__r.rstk__sydiv_dimval__r.rstk__sydim_dimval__c).Id;
			rstk__sytxncst__c sytxn = mapOfTransactionsByJournal.get(tempLineItem.c2g__Journal__c);
			c2g__codaDimension1__c dim1 = null;
			if (sytxn!=null) dim1 = mapOfFFDimensionsByReportingCode.get(sytxn.rstk__sytxncst_div__r.rstk__sydiv_dimval__r.rstk__sydim_dimval__c);
			if (dim1!=null) tempLineItem.c2g__Dimension1__c = dim1.Id;
			// BLL3 end
        }
        
        System.debug(listOfCogLines);
	}
	// AMILLER1
}