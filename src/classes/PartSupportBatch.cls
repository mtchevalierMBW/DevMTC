public class PartSupportBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    // Public defenitions 
    String[] errors = new String[0];
    String query;
    
    // Constructor
    public PartSupportBatch() {
        //Affected Items
        query = 'SELECT dealer__Purchase_Order_Accepted_Date__c, dealer__Part__c, Name, Id FROM dealer__Purchase_Order_Line__c WHERE dealer__Purchase_Order_Accepted_Date__c = THIS_MONTH';
    }

    // Start Context
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    // Execute Context
    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<dealer__Purchase_Order_Line__c> poLineList = (List<dealer__Purchase_Order_Line__c>) scope;
        for(dealer__Purchase_Order_Line__c pl : poLineList) {
            // PartLedgerAPI.rebuildLedger(pi.Id);
            try {
                PartSupportAPI.cleanLedger(pl.dealer__Part__c);
            } Catch(Exception e) {
                errors.add(pl.dealer__Part__c + ' : ' +e.getMessage());
            }
        }
    }
    
    // Finish Context
    public void finish(Database.BatchableContext BC) {
        if(!errors.isEmpty()) {

            String messageBody = '';
            for(String s : errors) {
                messageBody += s+'\r\n';
            }
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setSubject('Part Ledger Clean Feedback');
            mail.setTargetObjectId(UserInfo.getUserId());
            mail.setSaveAsActivity(false);
            mail.setPlainTextBody(messageBody);
            Messaging.sendEmail(new Messaging.Email[] { mail });
        }       
    }  
}