/**
 * JournalLineReferences
 * Tested by:  TransactionReferences_TEST, ReversingJournal_TEST
 * 
 * Copy journal header reference fields to journal lines until there is another way to get header info on the
 * "Manage lines" screen provided by Financial Force.
 * Also pull dimension1 from payable invoice when automatic cash matching entries are missing dimension1.
 * Tested by: TransactionReferences_TEST, ReversingJournal_TEST
 *
 * Coverage:
 *	2018-04-26	100% (15/15)
 * 
 * MW Trigger Controls entry "ReversingJournal" enables/disables copying source journal lines custom fields to reversing journal lines.
 *
 *  2015-08-03  B. Leaman   Created to get header info copied to the lines until there is a better way.
 *  2015-12-14  B. Leaman   BLL1 IT#17587 Copy source journal line custom fields to reversing journal lines.
 *  2016-02-22  B. Leaman   BLL2 - Set Dim1 when missing on Cash Matching Journal lines.
 *  2017-02-28  B. Leaman   BLL3 - Handle cancelling journal in addition to reversing journal.
 *	2017-05-08	B. Leaman	BLL4 Restructure & add support for TW Po receipt control numbers.
 *	2018-04-26	B. Leaman	BLL5 - (For TW) - if Control# is empty and this journal references a SIN or SCR, use that document number for the Control.
 *  2018-08-14  A. Miller   AMILLER1 - Update to handle dimesnion changes to journal lines prior to posting
 */ 
trigger JournalLineReferences on c2g__codaJournalLineItem__c (before insert, before update) {
	
	// BLL4a
	JournalLineItemProcess handler = new JournalLineItemProcess(Trigger.new, Trigger.oldMap);
	
    if (Trigger.isBefore && Trigger.isInsert) {
		handler.MissingDim1OnCashMatch();
        handler.transitWorksDefaultInvoiceCogsDimension(); // AMILLER1
    }
    // BLL4a end

    if (Trigger.isBefore && Trigger.isInsert) {
    	handler.CopyRefsFromJournalHeader();
    }
    
    // BLL5a
    MW_TriggerControls__c rstkSinScrDftControl = MW_TriggerControls__c.getInstance('rstkSinScrDftControl');
    if (rstkSinScrDftControl==null || rstkSinScrDftControl.Enabled__c) {
    	if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
    		handler.DefaultControlForSlsInvAndCrd();
    	}
    }
    // BLL5a end
    
    MW_TriggerControls__c reversingJournal = MW_TriggerControls__c.getInstance('ReversingJournal');
    if (reversingJournal==null || reversingJournal.Enabled__c) {
        if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
			handler.CopyCustomFromReferencedJournal();	// BLL4a
        } // Trigger isbefore and (isInsert or isUpdate)
    } // reversingJournal
    // BLL1a end
    
    // Build control# for Rootstock PO receipts
    MW_TriggerControls__c rstkPORcptControl = MW_TriggerControls__c.getInstance('rstkPORcptControl');
    if (rstkPORcptControl==null || rstkPORcptControl.Enabled__c) {
    	if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {	
    		handler.ControlNbrForRootstockPORcpts();
    	}
    }
    
}