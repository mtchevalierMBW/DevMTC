/**
 *	PayableCreditExpLineTrigger
 *	Tested by: PayableCreditExpLineTrigger_TEST
 *	Written by: Bryan Leaman
 *	Date: February 22, 2017
 *
 *	2018-06-13	B. Leaman	 BLL1 - Add dimension1 default logic
**/
trigger PayableCreditExpLineTrigger on c2g__codaPurchaseCreditNoteExpLineItem__c (before insert, before update) {

	// BLL1a - NO, this only need done on header record (which set the dim1 on the payable acct (2100))
	// Dimension1Default.PayableCreditExpLines(Trigger.new);

	if (Trigger.isInsert && Trigger.isBefore) {	// BLL1a
		// List of payable credit notes
		Set<Id> pcrIds = new Set<Id>();
		for(c2g__codaPurchaseCreditNoteExpLineItem__c pce : Trigger.new) {
			if (pce.c2g__PurchaseCreditNote__c!=null) pcrIds.add(pce.c2g__PurchaseCreditNote__c);
		}
	    
	    // Get referenced payable invoices
	    Set<Id> pinIds = new Set<Id>();
	    Map<Id,c2g__codaPurchaseCreditNote__c> pcrMap = new Map<Id,c2g__codaPurchaseCreditNote__c>();
	    if (pcrIds.size()>0) pcrMap = new Map<Id,c2g__codaPurchaseCreditNote__c>([
	    	select Id, Name, c2g__PurchaseInvoice__c
	    	from c2g__codaPurchaseCreditNote__c
	    	where Id in :pcrIds
	    ]); 
	    for(c2g__codaPurchaseCreditNote__c p : pcrMap.values()) 
	    	if (p.c2g__PurchaseInvoice__c!=null) pinIds.add(p.c2g__PurchaseInvoice__c);
	    
		// Map pin id + line# to pin exp line
		Map<String,c2g__codaPurchaseInvoiceExpenseLineItem__c> pieMap = new Map<String,c2g__codaPurchaseInvoiceExpenseLineItem__c>();
		if (pinIds.size()>0) 
			for(c2g__codaPurchaseInvoiceExpenseLineItem__c pie : 
				[select Id, Control__c, c2g__LineNumber__c, c2g__PurchaseInvoice__c from c2g__codaPurchaseInvoiceExpenseLineItem__c where c2g__PurchaseInvoice__c in :pinIds])
				pieMap.put(pie.c2g__PurchaseInvoice__c + ':' + String.valueOf(Integer.valueOf(pie.c2g__LineNumber__c)), pie);
	    
	    // Map in the Control number
		for(c2g__codaPurchaseCreditNoteExpLineItem__c pce : Trigger.new) {
			c2g__codaPurchaseCreditNote__c pcr = pcrMap.get(pce.c2g__PurchaseCreditNote__c);
			String key = '';
			if (pcr!=null) key = pcr.c2g__PurchaseInvoice__c + ':' + String.valueOf(Integer.valueOf(pce.c2g__LineNumber__c));
			c2g__codaPurchaseInvoiceExpenseLineItem__c pie = pieMap.get(key);
			if (pie!=null && !String.isBlank(pie.Control__c) && String.isBlank(pce.Control__c))
				pce.Control__c = pie.Control__c; 
		}
	}	// BLL1a
    
}