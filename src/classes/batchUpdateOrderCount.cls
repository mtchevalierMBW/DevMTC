public class batchUpdateOrderCount implements Database.Batchable<sObject> {
	
	String query;
	
	public batchUpdateOrderCount() {
		query = 'SELECT Id, Name, dealer__On_Order__c FROM dealer__Parts_Inventory__c ';
	}
	
	public Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	public void execute(Database.BatchableContext BC, List<sObject> scope) {
		   List<dealer__Parts_Inventory__c> partsList = (List<dealer__Parts_Inventory__c>) scope;
		   for(dealer__Parts_Inventory__c pi : partsList) {
				PartSupportAPI.customOrderCount(pi);
           }
	}
	
	public void finish(Database.BatchableContext BC) {
		
	}
	
}