/**
 * MiscChargeOption_Trigger
 * Tested by: MiscChargeOption_Trigger_TEST
 * Date: Sep 8, 2016
 * Programmer: Bryan Leaman
 *
 */
trigger MiscChargeOption_Trigger on Misc_Charge_Option__c (before insert, before update) {

	Set<Id> GLAcctIdsMW = new Set<Id>();
	Set<Id> GLAcctIdsFF = new Set<Id>();
	
	for(Misc_Charge_Option__c mco : Trigger.new) {
		if (mco.General_Ledger_Account__c!=null) GLAcctIdsFF.add(mco.General_Ledger_Account__c);
		if (mco.General_Ledger_Acct_MW__c!=null) GLAcctIdsMW.add(mco.General_Ledger_Acct_MW__c);
	}

	Map<Id,Id> GLAcctFFtoMW = new Map<Id,Id>();
	Map<Id,Id> GLAcctMWtoFF = new Map<Id,Id>();
	for(GeneralLedgerAcctMW__c glmw : [
			select Id, GeneralLedgerAccountFF__c 
			from GeneralLedgerAcctMW__c 
			where Id in :GLAcctIdsMW or GeneralLedgerAccountFF__c in :GLAcctIdsFF
		]) {
		GLAcctFFtoMW.put(glmw.GeneralLedgerAccountFF__c, glmw.Id);
		GLAcctMWtoFF.put(glmw.Id, glmw.GeneralLedgerAccountFF__c);
	}

	for(Misc_Charge_Option__c mco : Trigger.new) {
		Misc_Charge_Option__c oldmco = (Trigger.oldMap!=null) ? Trigger.oldMap.get(mco.Id) : null;
		// Favor changed account over one that didn't change
		if (oldmco!=null && oldmco.General_Ledger_Account__c!= mco.General_Ledger_Account__c && mco.General_Ledger_Account__c!=null) mco.General_Ledger_Acct_MW__c = GLAcctFFtoMW.get(mco.General_Ledger_Account__c); 
		if (oldmco!=null && oldmco.General_Ledger_Acct_MW__c!= mco.General_Ledger_Acct_MW__c && mco.General_Ledger_Acct_MW__c!=null) mco.General_Ledger_Account__c = GLAcctMWtoFF.get(mco.General_Ledger_Acct_MW__c);
		// If either is missing, fill it in
		if (mco.General_Ledger_Acct_MW__c==null && mco.General_Ledger_Account__c!=null)  mco.General_Ledger_Acct_MW__c = GLAcctFFtoMW.get(mco.General_Ledger_Account__c);
		if (mco.General_Ledger_Account__c==null && mco.General_Ledger_Acct_MW__c!=null)  mco.General_Ledger_Account__c = GLAcctMWtoFF.get(mco.General_Ledger_Acct_MW__c);
		// Make sure they're sync'd to each other!
		if (mco.General_Ledger_Account__c!=null) mco.General_Ledger_Acct_MW__c = GLAcctFFtoMW.get(mco.General_Ledger_Account__c);
		if (mco.General_Ledger_Acct_MW__c!=null) mco.General_Ledger_Account__c = GLAcctMWtoFF.get(mco.General_Ledger_Acct_MW__c);
	}


}