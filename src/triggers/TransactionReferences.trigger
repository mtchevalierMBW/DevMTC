/** TransactionReferences
 * Pull document reference (lookup & text references) from Journal header into transaction header
 * based on c2g__codaTransaction__c.c2g__DocumentNumber__c
 * Tested by: TransactionReferences_TEST 
 * 
 *  2015-08-05  B. Leaman   Add support for copying source from cash entries
 *  2015-08-20  B. Leaman   BLL1 - add Finance Company lookup field 
 *  2015-10-02	B. Leaman	BLL2 - Set source to 'PB' for payable invoices & credit notes.
 *  2015-10-27	B. Leaman	BLL3 - Log execution for debugging why some sources are missing on transaction headers.
 *							Also run on updates if the document number changed.
 *	2015-11-09	B. Leaman	BLL4 - Copy vendor too
 *	2016-03-14	B. Leaman	BLL5 - Update transaction lines for reversing journals.
 *	2016-04-14	B. Leaman	BLL6 - Add commercial quote reference.
 */
trigger TransactionReferences on c2g__codaTransaction__c (before insert, after insert, before update, after update) {

	// BLL5a Attempt to assign custom fields (like control nbr) to transactions lines when a journal is reversed
	if (Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert)) {
		MW_TriggerControls__c reversingJournal = MW_TriggerControls__c.getInstance('ReversingJournal');
		if (reversingJournal==null || reversingJournal.Enabled__c) TransactionLineProcess.checkReversingTransaction(Trigger.new, Trigger.oldMap);
	}
	// BLL5a end

	MonitorExecution monitor = new MonitorExecution('TransactionReferences');  // BLL3a
	boolean sendlog = false;  // BLL3a

    if (Trigger.isBefore) {  // BLL3c
		Set<String> journalnames = new Set<String>();
		Set<String> cashnames = new Set<String>();
		Set<String> payablenames = new Set<String>();  // BLL2a
		Set<String> paycreditnames = new Set<String>();  // BLL2a
		for(c2g__codaTransaction__c t : Trigger.new) {
			c2g__codaTransaction__c oldTrn = null;  // BLL3a
			if (Trigger.isUpdate) oldTrn = Trigger.oldMap.get(t.Id);  // BLL3a
			if (oldTrn==null 
			    || oldTrn.c2g__DocumentNumber__c!=t.c2g__DocumentNumber__c
			    || t.Source__c==null) {  // BLL3a
				monitor.log(t.Name + ' : ' + t.c2g__DocumentNumber__c);  // BLL3a
			    if (!String.isBlank(t.c2g__DocumentNumber__c) && t.c2g__TransactionType__c!=null	// BLLxc !=null to !isBlank
			        && (t.c2g__TransactionType__c=='Journal' || t.c2g__DocumentNumber__c.startsWith('JNL'))
			        && !journalnames.contains(t.c2g__DocumentNumber__c)) {
			          journalnames.add(t.c2g__DocumentNumber__c);
			    }
			    if (!String.isBlank(t.c2g__DocumentNumber__c) && t.c2g__TransactionType__c!=null	// BLLxc !=null to !isBlank
			        && (t.c2g__TransactionType__c=='Cash' || t.c2g__DocumentNumber__c.startsWith('CSH'))
			        && !cashnames.contains(t.c2g__DocumentNumber__c)) {
			          cashnames.add(t.c2g__DocumentNumber__c);
			    }
			    // BLL2a
			    if (!String.isBlank(t.c2g__DocumentNumber__c) && t.c2g__TransactionType__c!=null	// BLLxc !=null to !isBlank
			        && (t.c2g__TransactionType__c=='Purchase Invoice' || t.c2g__DocumentNumber__c.startsWith('PIN'))
			        && !payablenames.contains(t.c2g__DocumentNumber__c)) {
			          payablenames.add(t.c2g__DocumentNumber__c);
			    }
			    if (!String.isBlank(t.c2g__DocumentNumber__c) && t.c2g__TransactionType__c!=null	// BLLxc !=null to !isBlank
			        && (t.c2g__TransactionType__c=='Payable Credit Note' || t.c2g__TransactionType__c=='Purchase Credit Note'  
			           || t.c2g__DocumentNumber__c.startsWith('PCR'))
			        && !paycreditnames.contains(t.c2g__DocumentNumber__c)) {
			          paycreditnames.add(t.c2g__DocumentNumber__c);
			    }
			    // BLL2a end
			} // BLL3a 
		} 
		
		// Get info from journal (header)
		Map<String, c2g__codaJournal__c> jinfo = new Map<String, c2g__codaJournal__c>();
		if (journalnames.size()>0) { // BLL2a
			for(c2g__codaJournal__c j : 
			   [ select Id, Name, Source__c, Proposal__c, Rental_Agreement__c, Repair_Order__c, Purchase_Order__c,
			            Customer__c, Third_Party_Payor__c, Other_Payor__c, Sales_Person__c, Finance_Company__C,
			            Vendor__c, CommercialQuote__c	// BLL6c added commercial quote
			     from c2g__codaJournal__c
			     where Name in :journalnames ]) {
			   jinfo.put(j.Name, j);
			}
		} // BLL2a

		// Get info from cash entries (header)
		Map<String, c2g__codaCashEntry__c> cinfo = new Map<String, c2g__codaCashEntry__c>();
		if (cashnames.size()>0) { // BLL2a
			for(c2g__codaCashEntry__c c : 
			   [ select Id, Name, Source__c
			     from c2g__codaCashEntry__c
			     where Name in :cashnames ]) {
			   cinfo.put(c.Name, c);
			}
		} // BLL2a

		// Get info from payable invoices (header) BLL2a
		Map<String, c2g__codaPurchaseInvoice__c> pinfo = new Map<String, c2g__codaPurchaseInvoice__c>();
		if (payablenames.size()>0) {
			for(c2g__codaPurchaseInvoice__c p : 
			   [ select Id, Name, Source__c
			     from c2g__codaPurchaseInvoice__c
			     where Name in :payablenames ]) {
			   pinfo.put(p.Name, p);
			}
		}
		
		// Get info from payable credit notes (header) BLL2a
		Map<String, c2g__codaPurchaseCreditNote__c> pcinfo = new Map<String, c2g__codaPurchaseCreditNote__c>();
		if (paycreditnames.size()>0) {
			for(c2g__codaPurchaseCreditNote__c pc : 
			   [ select Id, Name, Source__c
			     from c2g__codaPurchaseCreditNote__c
			     where Name in :paycreditnames ]) {
			   pcinfo.put(pc.Name, pc);
			}
		}
		// BLL2a end
		
		monitor.log('jinfo='+JSON.serialize(jinfo));  // BLL3a
		monitor.log('cinfo='+JSON.serialize(cinfo));  // BLL3a
		monitor.log('pinfo='+JSON.serialize(pinfo));  // BLL3a
		monitor.log('pcinfo='+JSON.serialize(pcinfo));   // BLL3a
		 
		for (c2g__codaTransaction__c t : Trigger.new) {
		    c2g__codaJournal__c j = jinfo.get(t.c2g__DocumentNumber__c);
		    c2g__codaCashEntry__c c = cinfo.get(t.c2g__DocumentNumber__c);
		    c2g__codaPurchaseInvoice__c p = pinfo.get(t.c2g__DocumentNumber__c);
		    c2g__codaPurchaseCreditNote__c pc = pcinfo.get(t.c2g__DocumentNumber__c);

			c2g__codaTransaction__c oldTrn = null;  // BLL3a
			if (Trigger.isUpdate) oldTrn = Trigger.oldMap.get(t.Id);  // BLL3a
	
			if (oldTrn==null 
			    || oldTrn.c2g__DocumentNumber__c!=t.c2g__DocumentNumber__c
			    || t.Source__c==null) {  // BLL3a
			    // Journals ...
			    if (j!=null) {
			        t.Source__c = j.Source__c;
			        t.Proposal__c = j.Proposal__c;
			        t.CommercialQuote__c = j.CommercialQuote__c;	// BLL6a
			        t.Rental_Agreement__c = j.Rental_Agreement__c;
			        t.Repair_Order__c = j.Repair_Order__c;
			        t.Purchase_Order__c = j.Purchase_Order__c;
			        t.Customer__c = j.Customer__c;
			        t.Third_Party_Payor__c = j.Third_Party_Payor__c;
			        t.Other_Payor__c = j.Other_Payor__c;
			        t.Sales_Person__c = j.Sales_Person__c;
			        t.Finance_Company__c = j.Finance_Company__c;  // BLL1a
			        t.Vendor__c = j.Vendor__c; // BLL4a
			    } 
			    // Cash entries ...
			    if (c!=null) {
			        t.Source__c = c.Source__c;
			    }
			    // Payable Invoices ...
			    if (p!=null) {
			        t.Source__c = p.Source__c;
			    }
			    // Payable Credit Notes ...
			    if (pc!=null) {
			        t.Source__c = pc.Source__c;
			    }
			    // BLL3a
			    if (String.isBlank(t.Source__c)) {
			    	sendlog = true;
			    	monitor.log('Missing document source for ' + t.Name + ' from ' + t.c2g__DocumentNumber__c);  
			    }
			} // BLL3a
		} // BLL3a
	} 

	if (sendlog || monitor.AlwaysNotify) monitor.notifyAdmin();  // BLL3a
	
}