/** TransactionLineItemReferences
 * Copy references from Journal lines, Cash Entry Lines to resulting transaction lines
 * Tested by: TransactionReferences_TEST
 * 
 * Coverage:
 *	2018-04-26	81% (86/105)
 *	2019-09-13	82%	(88/107)
 * 
 *  2015-08-20	B. Leaman	BLL1 - Add Finance Company & Vehicle Inventory lookup fields
 *  2015-08-27	B. Leaman	BLL2 - Add support to pull control# from payable invoice expense line item
 *  2015-09-24	B. Leaman	BLL3 - Add support for payable invoice lines (not just expense lines) and 
 *  						reduce number of SOQL queries.
 *  2015-09-30	B. Leaman	BLL4 - Force integer line numbers, add payable credit notes.
 *  2015-10-08	B. Leaman	BLL5 - Copy in customer reference from journal line too.
 *	2015-11-09	B. Leaman	BLL6 - Copy vendor reference.
 *	2016-02-04	B. Leaman	BLL7 - Don't reset control# if it got a value! (Manual corrections!)
 *							// e.g. added "&& l.Control__c==null" to condition: if (ctl!=null && l.Control__c==null) l.Control__c = ctl;
 *	2017-05-25	B. Leaman	BLL8 IT#25116 - Need better way to build account schedule report.
 *	2016-07-14	B. Leaman	BLL9 IT#28414 - correct Customer name vs Third party payor confusion in cash entry lines.
 *	2017-10-16	B. Leaman	BLL10 - ensure no non-selective queries from having null in a list
 *	2018-04-26	B. Leaman	BLL11 - add support for sales invoice & sales credit control#s.
 *	2019-09-13	B. Leaman	W-000754 BLL12 - fill in vehicle lookup from control# (for PIN/PCR) on vehicle GL accts.
 */
trigger TransactionLineItemReferences on c2g__codaTransactionLineItem__c (before insert, before update, before delete) {

	// This didn't work, so not implemented. Reversing transaction document number was not in place when lines were created.
	//if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
	//	MW_TriggerControls__c reversingJournal = MW_TriggerControls__c.getInstance('ReversingJournal');
	//	if (reversingJournal==null || reversingJournal.Enabled__c) TransactionLineProcess.reversingTransactionLines(Trigger.new);
	//}

    // List of transaction Ids for these lines
	if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {	// BLL8a
	    Set<Id> transactions = new Set<Id>();
	    for(c2g__codaTransactionLineItem__c tli : Trigger.new) {
	        if (tli.c2g__Transaction__c!=null) transactions.add(tli.c2g__Transaction__c);	// BLL10c
	    }
	    System.debug(transactions);
	    
	    // Map of transaction-id => document number (JNL# or CSH#)
	    Map<Id, String> tDocNbr = new Map<Id, String>();
	    Set<String> journals = new Set<String>();
	    Set<String> cashentries = new Set<String>();
	    Set<String> purchinvexp = new Set<String>(); // BLL2a
	    Set<String> purchcrexp = new Set<String>(); // BLL4a
	    Set<Id> purchinvtrn = new Set<Id>(); // BLL4a
	    Set<Id> purchcrtrn = new Set<Id>(); // BLL4a
		// BLL11a
	    Set<String> slsinv = new Set<String>();	
	    Set<String> slscrd = new Set<String>();
	    Set<Id> invtrn = new Set<Id>();
	    Set<Id> crdtrn = new Set<Id>();	
	    // BLL11a end
	    for(c2g__codaTransaction__c t : [select Id, c2g__TransactionType__c, c2g__DocumentNumber__c from c2g__codaTransaction__c where Id in :transactions]) {
	    	if (!String.isBlank(t.c2g__DocumentNumber__c) && t.c2g__TransactionType__c!=null) {	// BLL10c !=null changed to !isBlank
		        tDocNbr.put(t.Id, t.c2g__DocumentNumber__c);
		        if(t.c2g__TransactionType__c=='Journal' || t.c2g__DocumentNumber__c.startsWith('JNL')) {
		            journals.add(t.c2g__DocumentNumber__c);	
		        }
		        if(t.c2g__TransactionType__c=='Cash' || t.c2g__DocumentNumber__c.startsWith('CSH')) {
		            cashentries.add(t.c2g__DocumentNumber__c);
		        }
		        // BLL2a begin
		        if(t.c2g__TransactionType__c=='Purchase Invoice' || t.c2g__DocumentNumber__c.startsWith('PIN')) {
		            purchinvexp.add(t.c2g__DocumentNumber__c);
		            purchinvtrn.add(t.Id); // BLL4a
		        }
		        // BLL2a end
		        // BLL4a begin
		        if(t.c2g__TransactionType__c=='Purchase Credit Note' || t.c2g__DocumentNumber__c.startsWith('PCR')) {
		            purchcrexp.add(t.c2g__DocumentNumber__c);
		            purchcrtrn.add(t.Id); 
		        }
		        // BLL4a end
		        // BLL11a
		        if (t.c2g__TransactionType__c=='Invoice'  || t.c2g__DocumentNumber__c.startsWith('SIN')) {
		        	slsinv.add(t.c2g__DocumentNumber__c);
		        	invtrn.add(t.Id);
		        }
		        if (t.c2g__TransactionType__c=='Credit Note' || t.c2g__DocumentNumber__c.startsWith('SCR')) {
		        	slscrd.add(t.c2g__DocumentNumber__c);
		        	crdtrn.add(t.Id);
		        }
		        // BLL11a end
	    	}
	    }
	    System.debug(journals);
	    System.debug(cashentries);
	    System.debug(purchinvexp); // BLL2a
	    System.debug(purchcrexp); // BLL4a
	    
	    // Create map of document number + line number to additional references needed on the transaction lines
	    Map<String, String> control = new Map<String, String>();
	    Map<String, Id> thirdpty = new Map<String, Id>();
	    Map<String, Id> salesperson = new Map<String, Id>();
	    Map<String, Id> financecomp = new Map<String, Id>();
	    Map<String, Id> vehicle = new Map<String, Id>();
	    Map<String, Id> customer = new Map<String, Id>();  // BLL5a
	    Map<String, Id> vendor = new Map<String, Id>(); // BLL6a
	    if (journals.size()>0) {  // BLL3a
		    for (c2g__codaJournalLineItem__c jl : [select Id, c2g__Journal__r.Name, Control__c, Third_Party_Payor__c, c2g__LineNumber__c,
		                                           Sales_Person__c, Finance_Company__c, Vehicle_Inventory__c, Customer_Name__c,
		                                           Vendor_Name__c  
		                                           from c2g__codaJournalLineItem__c 
		                                           where c2g__Journal__r.Name in :journals]) {
		        String key = jl.c2g__Journal__r.Name + ':' + String.valueOf(Integer.valueOf(jl.c2g__LineNumber__c));
		        control.put(key, jl.Control__c);
		        thirdpty.put(key, jl.Third_Party_Payor__c);
		        salesperson.put(key, jl.Sales_Person__c); // BLL1c - correct build of key
		        financecomp.put(key, jl.Finance_Company__c); // BLL1a
		        vehicle.put(key, jl.Vehicle_Inventory__c); // BLL1a
		        customer.put(key, jl.Customer_Name__c); // BLL5a
		        vendor.put(key, jl.Vendor_Name__c); // BLL6a
		    }
	    } // BLL3a
	
	    if (cashentries.size()>0) { // BLL3a
		    for (c2g__codaCashEntryLineItem__c cl : [select Id, c2g__CashEntry__r.Name, Control__c, Third_Party_Payor__c, c2g__LineNumber__c, CustomerName__c	// BLL9c 
		                                          from c2g__codaCashEntryLineItem__c 
		                                          where c2g__CashEntry__r.Name in :cashentries]) {
		        control.put(cl.c2g__CashEntry__r.Name + ':' + String.valueOf(Integer.valueOf(cl.c2g__LineNumber__c)), cl.Control__c);
		        thirdpty.put(cl.c2g__CashEntry__r.Name + ':' + String.valueOf(Integer.valueOf(cl.c2g__LineNumber__c)), cl.Third_Party_Payor__c);
		        customer.put(cl.c2g__CashEntry__r.Name + ':' + String.valueOf(Integer.valueOf(cl.c2g__LineNumber__c)), cl.CustomerName__c);	// BLL9a
		        // no salesperson (yet)
		    }
	    } // BLL3a
	
	    if (purchinvexp.size()>0) { // BLL3a
		    // BLL2a begin
		    for (c2g__codaPurchaseInvoiceExpenseLineItem__c pl : [select Id, c2g__PurchaseInvoice__r.Name, Control__c, c2g__LineNumber__c 
		                                          from c2g__codaPurchaseInvoiceExpenseLineItem__c 
		                                          where c2g__PurchaseInvoice__r.Name in :purchinvexp]) {
		        control.put(pl.c2g__PurchaseInvoice__r.Name + ':' + String.valueOf(Integer.valueOf(pl.c2g__LineNumber__c)), pl.Control__c);
		        // no third party
		        // no salesperson
		    }
		    // BLL2a end
		    // BLL3a begin
		    for (c2g__codaPurchaseInvoiceLineItem__c pil : [select Id, c2g__PurchaseInvoice__r.Name, Control__c, c2g__LineNumber__c 
		                                          from c2g__codaPurchaseInvoiceLineItem__c 
		                                          where c2g__PurchaseInvoice__r.Name in :purchinvexp]) {
		        control.put(pil.c2g__PurchaseInvoice__r.Name + ':' + String.valueOf(Integer.valueOf(pil.c2g__LineNumber__c)), pil.Control__c);
		        // no third party
		        // no salesperson
		    }
		    // BLL3a end
	    } // BLL3a
	
	    // BLL4a begin
	    if (purchcrexp.size()>0) { 
		    for (c2g__codaPurchaseCreditNoteExpLineItem__c pc : [select Id, c2g__PurchaseCreditNote__r.Name, Control__c, c2g__LineNumber__c 
		                                          from c2g__codaPurchaseCreditNoteExpLineItem__c
		                                          where c2g__PurchaseCreditNote__r.Name in :purchcrexp]) {
		        control.put(pc.c2g__PurchaseCreditNote__r.Name + ':' + String.valueOf(Integer.valueOf(pc.c2g__LineNumber__c)), pc.Control__c);
		        // no third party
		        // no salesperson
		    }
		    for (c2g__codaPurchaseCreditNoteLineItem__c pcl : [select Id, c2g__PurchaseCreditNote__r.Name, Control__c, c2g__LineNumber__c 
		                                          from c2g__codaPurchaseCreditNoteLineItem__c 
		                                          where c2g__PurchaseCreditNote__r.Name in :purchcrexp]) {
		        control.put(pcl.c2g__PurchaseCreditNote__r.Name + ':' + String.valueOf(Integer.valueOf(pcl.c2g__LineNumber__c)), pcl.Control__c);
		        // no third party
		        // no salesperson
		    }
	    } 
	    // BLL4a end

		// BLL11a
	    if (slsinv.size()>0) { 
		    for (c2g__codaInvoiceLineItem__c sil : [select Id, c2g__Invoice__r.Name, Control__c, c2g__LineNumber__c 
		                                          from c2g__codaInvoiceLineItem__c 
		                                          where c2g__Invoice__r.Name in :slsinv]) {
		        control.put(sil.c2g__Invoice__r.Name + ':' + String.valueOf(Integer.valueOf(sil.c2g__LineNumber__c)), sil.Control__c);
		    }
	    }
	    if (slscrd.size()>0) {
		    for (c2g__codaCreditNoteLineItem__c scl : [select Id, c2g__CreditNote__r.Name, Control__c, c2g__LineNumber__c 
		                                          from c2g__codaCreditNoteLineItem__c 
		                                          where c2g__CreditNote__r.Name in :slscrd]) {
		        control.put(scl.c2g__CreditNote__r.Name + ':' + String.valueOf(Integer.valueOf(scl.c2g__LineNumber__c)), scl.Control__c);
		    }
	    }
	    // BLL11a end

	
	    System.debug(control);
	    System.debug(thirdpty);
	
	    // Now for each transaction line, get document number (from map)
	    // and from that + transaction line#, get references & update fields!
	    for(c2g__codaTransactionLineItem__c l : Trigger.new) {
	        String doc = tDocNbr.get(l.c2g__Transaction__c);
	        if (doc!=null) {
	            String key = doc + ':' + String.valueOf(Integer.valueOf(l.c2g__LineNumber__c));
	            if (purchinvtrn.contains(l.c2g__Transaction__c)) key =  doc + ':' + String.valueOf(Integer.valueOf(l.c2g__LineNumber__c)-1);
	            if (purchcrtrn.contains(l.c2g__Transaction__c)) key =  doc + ':' + String.valueOf(Integer.valueOf(l.c2g__LineNumber__c)-1);
	            // BLL11a
	            if (invtrn.contains(l.c2g__Transaction__c)) key =  doc + ':' + String.valueOf(Integer.valueOf(l.c2g__LineNumber__c)-1);
	            if (crdtrn.contains(l.c2g__Transaction__c)) key =  doc + ':' + String.valueOf(Integer.valueOf(l.c2g__LineNumber__c)-1);
	            // BLL11a
	            String ctl = control.get(key);
	            if (ctl!=null && l.Control__c==null) l.Control__c = ctl;
	            Id third = thirdpty.get(key);
	            if (third!=null && l.Third_Party_Payor_TL__c==null) l.Third_Party_Payor_TL__c = third;
	            Id slsp = salesperson.get(key);
	            if (slsp!=null && l.Salesperson__c==null) l.Salesperson__c = slsp;
	            Id finc = financecomp.get(key);  // BLL1a
	            if (finc!=null && l.Finance_Company__c==null) l.Finance_Company__c = finc;  // BLL1a
	            Id vehi = vehicle.get(key);  // BLL1a
	            if (vehi!=null && l.Vehicle_Inventory__c==null) l.Vehicle_Inventory__c = vehi;  // BLL1a
	            Id cust = customer.get(key);  // BLL5a
	            if (cust!=null && l.Customer_Name__c==null) l.Customer_Name__c = cust;  // BLL5a
	            Id vend = vendor.get(key); // BLL6a
	            if (vend!=null && l.Vendor_Name__c==null) l.Vendor_Name__c = vend; // BLL6a
	        }
	    }


		// BLL12 - set vehicle reference if missing
		MW_TriggerControls__c pinVehicleReference = MW_TriggerControls__c.getInstance('PINVehicleReference');
		if (pinVehicleReference==null || pinVehicleReference.Enabled__c) TransactionLineProcess.LookupVehicleFromControl(Trigger.new);
		// BLL12 end

	}	// BLL8a end if before insert, before update



	// BLL8a Control 
	if (Trigger.isBefore) {
		MW_TriggerControls__c AccountScheduleCtl = MW_TriggerControls__c.getInstance('AccountScheduleControl');
		if (AccountScheduleCtl==null || AccountScheduleCtl.Enabled__c==true) (new AccountScheduleControlProcess()).updateTransactionControls(Trigger.new, Trigger.oldMap);
	}
	// BLL8a end


}