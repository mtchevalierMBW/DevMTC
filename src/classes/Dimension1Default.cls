/**
 * Dimension1Default
 * Tested by: Dimension1Default_TEST
 * Programmer: Bryan Leaman
 * Date: Jan 29, 2016
 *
 * Coverage:
 *	2018-06-15	98% (59/60)
 * 
 *	2018-02-05	B. Leaman	BLL1 - Cash entry default dimension 1 needs to be supplied on payment refunds
 *							too, not just type "Payment". 
 *	2018-06-13	B. Leaman	BLL2 - Default payable dimension1 on PIN & PCR for TW.
 */
public with sharing class Dimension1Default {
 
    // TransactionLines - add default dimension1 (from company) for transaction line items
    //------------------------------------------------------------------------------------
    static public void TransactionLines(List<c2g__codaTransactionLineItem__c> lines) { 
        Set<Id> companySet = new Set<Id>();
        for(c2g__codaTransactionLineItem__c l : lines) {
            if (l.c2g__Dimension1__c==null) {
                companySet.add(l.c2g__OwnerCompany__c);
            }
        }
        
        if (companySet.size()>0) {
			Map<Id,c2g__codaCompany__c> companies; 
			companies = Dimension1Default.CompanyMapForIds(companySet);
        
            for(c2g__codaTransactionLineItem__c l : lines) {
                if (l.c2g__Dimension1__c==null) {
                    c2g__codaCompany__c cmp = companies.get(l.c2g__OwnerCompany__c);
                    if (cmp!=null) {
                        l.c2g__Dimension1__c = cmp.DefaultPayableDimension1__c;
                    }
                }
            }
        }
    }
    

    // CashEntryLines - add default dimension1 (from company) for payment cash entry lines
    //------------------------------------------------------------------------------------
    static public void CashEntryPaymentLines(List<c2g__codaCashEntryLineItem__c> lines) {
        Set<Id> companySet = new Set<Id>();
        Set<Id> cashEntrySet = new Set<Id>();
        for(c2g__codaCashEntryLineItem__c l : lines) {
            if (l.c2g__AccountDimension1__c==null) {
                companySet.add(l.c2g__OwnerCompany__c);
                cashEntrySet.add(l.c2g__CashEntry__c);
            }
        }
        
        MW_TriggerControls__c DefaultDimension1 = MW_TriggerControls__c.getInstance('DefaultDimension1');
        if (DefaultDimension1==null || DefaultDimension1.Enabled__c) {
            if (companySet.size()>0) {
				Map<Id,c2g__codaCompany__c> companies; 
				companies = Dimension1Default.CompanyMapForIds(companySet);
                Map<Id,c2g__codaCashEntry__c> cashentries = new Map<Id,c2g__codaCashEntry__c>([
                    select Id, Name, c2g__Type__c
                    from c2g__codaCashEntry__c
                    where Id in :cashEntrySet
                ]);
            
                for(c2g__codaCashEntryLineItem__c l : lines) {
                    if (l.c2g__AccountDimension1__c==null) {
                        c2g__codaCompany__c cmp = companies.get(l.c2g__OwnerCompany__c);
                        c2g__codaCashEntry__c ce = cashentries.get(l.c2g__CashEntry__c);
                        if (cmp!=null && ce!=null && ce.c2g__Type__c!=null && ce.c2g__Type__c.startsWith('Payment')) {	// BLL1c
                            l.c2g__AccountDimension1__c = cmp.DefaultPayableDimension1__c;
                        }
                    }
                }
            }
        }
    }

	
	// BLL2a
	// CompanyMapForIds
	//-------------------------------------------------------------------------------------
	static public Map<Id,c2g__codaCompany__c> CompanyMapForIds(Set<Id> companySet) {
		Map<Id,c2g__codaCompany__c> companymap = new Map<Id,c2g__codaCompany__c>();
		if (companySet.size()>0) companymap = new Map<Id,c2g__codaCompany__c>([
			select Id, Name, DefaultPayableDimension1__c, ForcePayableDimension1__c
			from c2g__codaCompany__c
			where Id in :companySet
	    ]);
		return companymap;
	}
 
    // Payable Invoices - force default dimension1 (from company) 
    //------------------------------------------------------------------------------------
    static public void PayableInvoices(List<c2g__codaPurchaseInvoice__c> pinvs) { 
		Map<Id,c2g__codaCompany__c> companies; 
        Set<Id> companySet = new Set<Id>();
        for(c2g__codaPurchaseInvoice__c pi : pinvs) companySet.add(pi.c2g__OwnerCompany__c);
		companies = Dimension1Default.CompanyMapForIds(companySet);

        if (companies.size()>0) {
			for(c2g__codaPurchaseInvoice__c pi : pinvs) {
				if (pi.c2g__InvoiceStatus__c!='Complete') {
					c2g__codaCompany__c cmp = companies.get(pi.c2g__OwnerCompany__c);
					if (cmp!=null && (pi.c2g__Dimension1__c==null || cmp.ForcePayableDimension1__c==true)) {
						pi.c2g__Dimension1__c = cmp.DefaultPayableDimension1__c;
					}
				}
            }
        }
    }
 
    // Payable Invoices Expense Lines - force default dimension1 (from company)  
    //------------------------------------------------------------------------------------
    //static public void PayableInvoiceExpLines(List<c2g__codaPurchaseInvoiceExpenseLineItem__c> lines) { 
	//	Map<Id,c2g__codaCompany__c> companies; 
	//	Set<Id> companySet = new Set<Id>();
	//	Set<Id> pIds = new Set<Id>();
	//	for(c2g__codaPurchaseInvoiceExpenseLineItem__c l : lines) {
	//		companySet.add(l.c2g__OwnerCompany__c);
	//		pIds.add(l.c2g__PurchaseInvoice__c);
	//	}
	//	companies = Dimension1Default.CompanyMapForIds(companySet);
	//	Map<Id,c2g__codaPurchaseInvoice__c> pinvMap = new Map<Id,c2g__codaPurchaseInvoice__c>([
	//		select Id, c2g__InvoiceStatus__c
	//		from c2g__codaPurchaseInvoice__c
	//		where Id in :pIds
	//	]);
	//
	//	if (companies.size()>0) {
	//		for(c2g__codaPurchaseInvoiceExpenseLineItem__c l : lines) {
	//			c2g__codaCompany__c cmp = companies.get(l.c2g__OwnerCompany__c);
	//			c2g__codaPurchaseInvoice__c pinv=pinvMap.get(l.c2g__PurchaseInvoice__c);
	//			if (cmp!=null && pinv!=null && pinv.c2g__InvoiceStatus__c!='Complete'
	//				&& (l.c2g__Dimension1__c==null || cmp.ForcePayableDimension1__c==true)) {
	//				l.c2g__Dimension1__c = cmp.DefaultPayableDimension1__c;
	//			}
	//		}
	//	}
    //}
 
    // Payable Credit Notes - force default dimension1 (from company) 
    //------------------------------------------------------------------------------------
    static public void PayableCredits(List<c2g__codaPurchaseCreditNote__c> pcred) { 
		Map<Id,c2g__codaCompany__c> companies; 
        Set<Id> companySet = new Set<Id>();
        for(c2g__codaPurchaseCreditNote__c pc : pcred) companySet.add(pc.c2g__OwnerCompany__c);
		companies = Dimension1Default.CompanyMapForIds(companySet);

        if (companies.size()>0) {
			for(c2g__codaPurchaseCreditNote__c pi : pcred) {
				if (pi.c2g__CreditNoteStatus__c!='Complete') {
					c2g__codaCompany__c cmp = companies.get(pi.c2g__OwnerCompany__c);
					if (cmp!=null && (pi.c2g__Dimension1__c==null || cmp.ForcePayableDimension1__c==true)) {
						pi.c2g__Dimension1__c = cmp.DefaultPayableDimension1__c;
					}
				}
            }
        }
    }
 
    // Payable Credit Expense Lines - force default dimension1 (from company)  
    //------------------------------------------------------------------------------------
    //static public void PayableCreditExpLines(List<c2g__codaPurchaseCreditNoteExpLineItem__c> lines) { 
	//	Map<Id,c2g__codaCompany__c> companies; 
    //  Set<Id> companySet = new Set<Id>();
	//	Set<Id> pIds = new Set<Id>();
	//	for(c2g__codaPurchaseCreditNoteExpLineItem__c l : lines) {
	//		companySet.add(l.c2g__OwnerCompany__c);
	//		pIds.add(l.c2g__PurchaseCreditNote__c);
	//	}
	//	companies = Dimension1Default.CompanyMapForIds(companySet);
	//	Map<Id,c2g__codaPurchaseCreditNote__c> pcredMap = new Map<Id,c2g__codaPurchaseCreditNote__c>([
	//		select Id, c2g__CreditNoteStatus__c
	//		from c2g__codaPurchaseCreditNote__c
	//		where Id in :pIds
	//	]);
    //  if (companies.size()>0) {
	//		for(c2g__codaPurchaseCreditNoteExpLineItem__c l : lines) {
	//			c2g__codaCompany__c cmp = companies.get(l.c2g__OwnerCompany__c);
	//			c2g__codaPurchaseCreditNote__c pinv=pcredMap.get(l.c2g__PurchaseCreditNote__c);
	//			if (cmp!=null && pinv!=null && pinv.c2g__CreditNoteStatus__c!='Complete'
	//				&& (l.c2g__Dimension1__c==null || cmp.ForcePayableDimension1__c==true)) {
	//				l.c2g__Dimension1__c = cmp.DefaultPayableDimension1__c;
	//			}
    //      }
    //   }
	//}
	// BLL2a end

}