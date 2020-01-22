/**
 * CashEntryBatchProcesses
 * Tested by: CashEntryBatchProcesses_TEST
 * Date: 2019-04-30
 * Programmer: Bryan Leaman
 * Project: W-000575
 * Update proposal F&I overall status info when credit application statuses are updated.
 *
 * Coverage:
 *
 * Modifications: 
 *
**/
public with sharing class CashEntryBatchProcesses {
 
	@AuraEnabled
	public static void launchCreateCashEntries(String selectcriteria) {
		System.debug(selectcriteria);
		Database.executeBatch(new CashEntryAutoCreateDT(null, true, selectcriteria, null, null, null),1);
	}

	@AuraEnabled
	public static void launchPostCashEntries(){
		Database.executeBatch(new CashEntryAutoPostDT(null, true, null, '<= TODAY', null, null),1);
	}

	@AuraEnabled
	public static void launchCashMatching(){
		Database.executeBatch(new CashEntryAutoMatchDT(null, true, null, null, null, null),1);
	}

}