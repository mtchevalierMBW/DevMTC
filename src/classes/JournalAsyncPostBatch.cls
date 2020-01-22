global class JournalAsyncPostBatch implements Database.Batchable<sObject> {
	
	String query;
	
	global JournalAsyncPostBatch() {
		query = 'SELECT Id FROM dealer__Service_Repair_Order__c WHERE dealer__Status__c = \'Posted\' AND Journal__c = null AND Total_RO_Charges__c > 0';
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		for(sObject repairOrder : scope) {
			FFA_ServiceDepartment.postRepairOrder(repairOrder.Id);
		}
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}