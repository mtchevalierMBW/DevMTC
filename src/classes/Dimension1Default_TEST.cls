/**
 * Dimension1Default_TEST
 * Tests: Dimension1Default (used by TransactionLineDefaultDim1, CashEntryLineDefaultDim1)
 * Programmer: Bryan Leaman
 * Date: Jan 29, 2016
 * 
 *	2018-06-13	B. Leaman	BLL1 - test new dim1 defaults for Payable Invoices, Credits & Exp Lines;
 */
@isTest
private class Dimension1Default_TEST {
    
    private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); // BLL1

    @testSetup static void setupData() {
        TestHelper_MW.createBaseFFAData(FFAdata);
        update(new c2g__codaCompany__c(
        	Id=FFAdata.CurrentCompany.Id,
        	DefaultPayableDimension1__c=FFAdata.Dimension1.Id, 
        	ForcePayableDimension1__c=true
        ));
        insert(new MW_TriggerControls__c(Name=' LeadClearLatLng', Enabled__c=false));
    }


    static testMethod void transactionLines() {
        //TestHelper_MW th = new TestHelper_MW();
        FFAdata.refresh();

        List<c2g__codaTransactionLineItem__c> tli = new List<c2g__codaTransactionLineItem__c>();
        tli.add(new c2g__codaTransactionLineItem__c(
            c2g__OwnerCompany__c = FFAdata.CurrentCompany.Id,
            c2g__Dimension1__c = null
        ));
        Dimension1Default.TransactionLines(tli);
    }

    static testMethod void cashentryLines() {
        TestHelper_MW th = new TestHelper_MW();
        FFAdata.refresh();

        List<c2g__codaCashEntryLineItem__c> tli = new List<c2g__codaCashEntryLineItem__c>();
        tli.add(new c2g__codaCashEntryLineItem__c(
            c2g__CashEntry__c = null,
            c2g__OwnerCompany__c = FFAdata.CurrentCompany.Id,
            c2g__AccountDimension1__c = null
        ));
        Dimension1Default.CashEntryPaymentLines(tli);
    }

	static testMethod void PayableInvoices() {
        TestHelper_MW th = new TestHelper_MW();
        FFAdata.refresh();
        System.runAs(FFAdata.TestUser) {
        	Account a = th.getPersonAccount('1');
	        a.c2g__CODAAccountsReceivableControl__c = FFAdata.GLAMap.values()[0].Id;
	        a.c2g__CODAAccountsPayableControl__c = FFAdata.GLAMap.values()[0].Id;
	        a.c2g__CODAAccountTradingCurrency__c = 'USD';
	        update(a);
	        System.debug(a);
			c2g__codaPurchaseInvoice__c p = new c2g__codaPurchaseInvoice__c(
    	        c2g__OwnerCompany__c = FFAdata.CurrentCompany.Id,
				c2g__Account__c = a.Id,
				c2g__AccountInvoiceNumber__c = 'Test123',
				c2g__CopyAccountValues__c = false
			);
			insert(p);
			c2g__codaPurchaseInvoiceExpenseLineItem__c pl = new c2g__codaPurchaseInvoiceExpenseLineItem__c(
				c2g__PurchaseInvoice__c = p.Id,
				c2g__GeneralLedgerAccount__c = a.c2g__CODAAccountsPayableControl__c,
				c2g__Dimension1__c = FFAdata.Dimension1.Id,
				c2g__NetValue__c = 1.00,
				ffap__SetGLAToDefault__c = false,
				c2g__SetGLAToDefault__c = false
			);
			insert(pl);
        }
	}

	static testMethod void PayableCredits() {
        TestHelper_MW th = new TestHelper_MW();
        FFAdata.refresh();
        System.runAs(FFAdata.TestUser) {
        	Account a = th.getPersonAccount('1');
	        a.c2g__CODAAccountsReceivableControl__c = FFAdata.GLAMap.values()[0].Id;
	        a.c2g__CODAAccountsPayableControl__c = FFAdata.GLAMap.values()[0].Id;
	        a.c2g__CODAAccountTradingCurrency__c = 'USD';
	        update(a);
	        System.debug(a);
			c2g__codaPurchaseCreditNote__c p = new c2g__codaPurchaseCreditNote__c(
	            c2g__OwnerCompany__c = FFAdata.CurrentCompany.Id,
				c2g__Account__c = a.Id,
				c2g__AccountCreditNoteNumber__c = 'Test1234',
				c2g__CopyAccountValues__c = false
			);
			insert(p);
			c2g__codaPurchaseCreditNoteExpLineItem__c pl = new c2g__codaPurchaseCreditNoteExpLineItem__c(
				c2g__PurchaseCreditNote__c = p.Id,
				c2g__GeneralLedgerAccount__c = a.c2g__CODAAccountsPayableControl__c,
				c2g__Dimension1__c = FFAdata.Dimension1.Id,
				c2g__NetValue__c = 1.00,
				ffap__SetGLAToDefault__c = false,
				c2g__SetGLAToDefault__c = false
			);
			insert(pl);
        }
	}

}