global with sharing class ArchiveVehicleInventory {

	
	webservice static void archiveRecord(Id recordId) {
		dealer__Vehicle_Inventory__c record = [SELECT Id, RecordTypeId FROM dealer__Vehicle_Inventory__c WHERE Id = :recordId];
		Map<String,Schema.RecordTypeInfo> recordTypeMap = Schema.SObjectType.dealer__Vehicle_Inventory__c.getRecordTypeInfosByName();	
	 	Id archivedId = recordTypeMap.get('Archived').getRecordTypeId();

	 	record.RecordTypeId = archivedId;
	 	update record; 
	}
}