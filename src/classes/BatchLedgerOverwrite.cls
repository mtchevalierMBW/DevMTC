global class BatchLedgerOverwrite implements Database.Batchable<sObject>, Database.Stateful {
	
	String query;
	Exception[] errors = new Exception[0];

	global BatchLedgerOverwrite(String locationCode) {
		if(locationCode == 'ALL') {
			query = 'SELECT Id FROM dealer__Parts_Inventory__c';
		} else if(locationCode == 'ALL-PACK') {
			query = 'SELECT Id FROM dealer__Parts_Inventory__c WHERE dealer__Pack_QTY__c > 1';
		} else {
			query = 'SELECT Id FROM dealer__Parts_Inventory__c WHERE dealer__Location__r.dealer__Company_Number__c = \'' +locationCode + '\' ';
		}
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		   List<dealer__Parts_Inventory__c> partsList = (List<dealer__Parts_Inventory__c>) scope;
		   for(dealer__Parts_Inventory__c pi : partsList) {
			   try {
					PartLedgerCopy.mv(pi.Id);
			   } Catch(Exception e) {
				   	errors.add(e);
			   }
		   }
	}
	
	global void finish(Database.BatchableContext BC) {
        if(!errors.isEmpty()) {

			String messageBody = '';
			for(Exception e : errors) {
				messageBody += e.getMessage()+'\r\n';
			}
			
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setSubject('Errors occurred on Ledger Copy');
            mail.setTargetObjectId(UserInfo.getUserId());
            mail.setSaveAsActivity(false);
            mail.setPlainTextBody(messageBody);
            Messaging.sendEmail(new Messaging.Email[] { mail });
        }		
	} 

}