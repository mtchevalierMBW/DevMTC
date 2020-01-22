/**
 * GeneralLedgerAccount_MW
 * Tested by:
 * Programmer: Bryan Leaman
 * Date: 2015-10-29
 * 
 * Keep GeneralLedgerAcct__c object in sync with FF GL accounts. Uses GeneralLedgerAcctMW class for updates.
 */
trigger GeneralLedgerAccount_MW on c2g__codaGeneralLedgerAccount__c (after delete, after insert, after undelete, 
after update) {

	// Delete corresponding entries in custom GL Acct obj
    if (Trigger.isDelete) {
    	GeneralLedgerAcctMW.deleteAccounts(Trigger.old);
    }

    // Create corresponding entries in custom GL Acct obj    
    if (Trigger.isInsert || Trigger.isUpdate) {
    	GeneralLedgerAcctMW.upsertAccounts(Trigger.new);
    }

    // Treat undelete like an insert    
    if (Trigger.isUndelete) {
    	GeneralLedgerAcctMW.upsertAccounts(Trigger.new);
    }

}