/**
 * JournalCustom
 * Tested by: ReversingJournal_TEST
 *
 * MW Trigger Controls entry "ReversingJournal" enables/disables copying source journal custom fields to reversing journal.
 *
 * Copy custom fields from referenced source journal on a reversing journal (or cancelling journal).
 *
 *	2016-03-14	B. Leaman	BLL1 - Reversing journal lines 
 *	2016-07-01	B. Leaman	BLL2 - Also map commercial quote field.
 *	2017-02-28	B. Leaman	BLL3 - Also cancelling journals.
 *	2017-05-12	B. Leaman	BLL4 - move logic to a class; add transitworks journal source codes;
 *	2018-03-06	B. Leaman	BLL5 - fill in the journal header c2g__Reference__c with the SCR# if the reference ie blank/null and the SCR is provided.
 */
trigger JournalCustom on c2g__codaJournal__c (before insert, before update) {

	JournalProcess jp = new JournalProcess(Trigger.new, Trigger.oldMap);	// BLL4a

	// Copy custom values from source journal on reversing entries
	MW_TriggerControls__c reversingJournal = MW_TriggerControls__c.getInstance('ReversingJournal');
	if (Trigger.isBefore && (reversingJournal==null || reversingJournal.Enabled__c )) jp.ReversingJournal();
	
	if (Trigger.isBefore && Trigger.isInsert) jp.RootstockSourceCode();	// BLL4a
	if (Trigger.isBefore && Trigger.isInsert) jp.RootstockSalesCreditReference();	// BLL5a

	// BLL1a Attempt to assign custom fields (like control nbr) to journal lines when a journal is reversed
	// This didn't work, so trigger no longer fires after insert/update
	//if (Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert)) {
		//MW_TriggerControls__c reversingJournal = MW_TriggerControls__c.getInstance('ReversingJournal');
	//	if (reversingJournal==null || reversingJournal.Enabled__c) TransactionLineProcess.checkReversingJournal(Trigger.newMap, Trigger.oldMap);
	//}
	// BLL1a end
	
}