global class POBatchReceive implements Database.Batchable<sObject>, Database.Stateful {
    
    String query;
    Set<Id> poIds;
    global List<Id> failedIds;
    
    global POBatchReceive(List<Id> idList) {
        failedIds = new List<Id>();
        poIds = new Set<Id>(idList);
        List<dealer__Purchase_Order__c> poList = [SELECT Id, dealer__PO_Accounting_Name__c FROM dealer__Purchase_Order__c WHERE Id IN :poIds];
        
        List<String> accountingNames = new List<String>();        
        for(dealer__Purchase_Order__c po : poList) {
            accountingNames.add(po.dealer__PO_Accounting_Name__c);
        }
        
        List<c2g__codaTransactionLineItem__c> transactionLines = [SELECT Id, Control__c, c2g__GeneralLedgerAccount__r.Name, c2g__Transaction__r.Purchase_Order__c 
                                                                  FROM c2g__codaTransactionLineItem__c WHERE c2g__Transaction__r.Purchase_Order__c IN :poIds AND c2g__GeneralLedgerAccount__r.Name = '1220 - Inventory-Parts'];
        if(transactionLines.size() > 0) {
            for(c2g__codaTransactionLineItem__c transactionLine : transactionLines) {
                poIds.remove(transactionLine.c2g__Transaction__r.Purchase_Order__c);
            }
        }
        
        query = 'Select Id, Name, Part_Quantity_Outstanding__c, dealer__PO_Accounting_Name__c, dealer__PO_Amount__c, dealer__Company__c, dealer__Accepted_DateTime__c, dealer__Accepted_By__c, dealer__Status__c, LastModifiedById, dealer__Service_Repair_Order__c, dealer__Service_Repair_Order__r.Name from dealer__Purchase_Order__c where Id IN :poIds ';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<dealer__Purchase_Order__c> scope) {
        for(dealer__Purchase_Order__c po : scope) {
            try {
                SavePoint sp = Database.setSavePoint();

                Decimal partVal = po.dealer__PO_Amount__c;
                if(partVal==null || partVal==0) {
                    throw new FFAccountingException('Error receiving part, the value to apply is 0 ');
                }
                
                // Select Sum of all Transactions posted to ensure there is not an overposting sittuation
                Decimal transactionAmount = (Decimal) [Select SUM(c2g__DualDebits__c) totalValue from c2g__codaTransaction__c where Purchase_Order__c =:po.Id][0].get('totalValue');
                if(transactionAmount==null) { transactionAmount=0;}
                
                               
                // Get the location record
                dealer__Dealer_Location__c loc = FFAccounting.getDealerLocation(po.dealer__Company__c); 
                
                // Sanity Check
                if(loc.Financial_Force_Dimension_1__c==null) {
                    throw new FFAccountingException('Financial Force Dimension 1 not set for Location '+po.dealer__Company__c);
                }               
                
                Map<String, c2g__codaGeneralLedgerAccount__c> gl_accounts = new Map<String, c2g__codaGeneralLedgerAccount__c>();
                Set<String> rc = new Set<String>{'1220','2115'};
                    for(c2g__codaGeneralLedgerAccount__c gl : [Select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c IN:rc limit 10]) {
                        gl_accounts.put(gl.c2g__ReportingCode__c, gl);
                    }
               
               
                
                Id journalId = null;
                Date jdate = Date.today();
                
                c2g__codaJournal__c journalHeader       =   new c2g__codaJournal__c();
                journalHeader.c2g__OwnerCompany__c      =   FFAccounting.getFFCompany(loc.Id);
                journalHeader.c2g__JournalCurrency__c   =   FFAccounting.currency(journalHeader.c2g__OwnerCompany__c);
                journalHeader.c2g__JournalDescription__c=   'Purchase Order ' + po.Name; 
                if (po.dealer__Accepted_DateTime__c!=null) jdate = po.dealer__Accepted_DateTime__c.date();
                journalHeader.c2g__JournalDate__c       =   jdate;
                journalHeader.c2g__Reference__c         =   po.Name;
                journalHeader.Source__c                 =   'PUR';
                journalHeader.Purchase_Order__c         =   po.Id;
                
                // Create the Journal Lines
                List<c2g__codaJournalLineItem__c> jLines = new List<c2g__codaJournalLineItem__c>();
                
                String controlnbr = po.dealer__PO_Accounting_Name__c;	// BLL2a
                // No: Only sublets use RO#. if (po.dealer__Service_Repair_Order__c!=null) controlnbr = po.dealer__Service_Repair_Order__r.Name; 	// BLL2a
                
                jLines.add(new c2g__codaJournalLineItem__c(
                    c2g__Journal__c=journalId,
                    c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                    c2g__LineNumber__c=1,
                    c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('2115').Id,
                    c2g__Value__c=(partVal *-1),
                    c2g__LineType__c='General Ledger Account',
                    Control__c=controlnbr	// BLL2a
                    //BLL2d Control__c=po.Name
                )
                          ); 
                
                jLines.add(new c2g__codaJournalLineItem__c(
                    c2g__Journal__c=journalId,
                    c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                    c2g__LineNumber__c=2,
                    c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('1220').Id,
                    c2g__Value__c=(partVal),
                    c2g__LineType__c='General Ledger Account',
                    Control__c=controlnbr	// BLL2a
                    //BLL2d Control__c=po.Name
                )
                          );
                
                // Process Journal Lines
                try {
                    
                    journalId = FinancialForce_MBW.createJournalApi(journalHeader, jLines);
                    FFAccounting.postJournal(journalId);
                    FFAccounting.applyJournalToRegister(po.Id, journalId);
                    
                } Catch(DmlException e) {
                    Database.rollback(sp);
                    throw new FFAccountingException('Unable to create the journal lines '+e.getMessage());
                }
                
                // Update Accepted Date on Purchase Order - only if the po is completely received.
                if(po.Part_Quantity_Outstanding__c == 0) {
                    try {
                        po.dealer__Accepted_By__c = po.LastModifiedById;
                        po.dealer__Accepted_DateTime__c = DateTime.now();
                        po.dealer__Status__c = 'Accepted';
                        
                        update po;
                        
                    }  Catch(DmlException e) {
                        Database.rollback(sp);
                        throw new FFAccountingException('Failed to update purchase order accepted status');
                    }
                }
            }
            catch (Exception e) {
               failedIds.add(po.Id);
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        System.debug(failedIds);
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] {'admin@dealearteam.com', 'admin+dealerteam@redteal.com'});
        mail.setSenderDisplayName('Posting Alert');
        mail.setSubject('PO Failures');
        String body = 'Failed POs: \n';
        for(Id poId : failedIds) {
            body += poId + '\n';
        }
        mail.setPlainTextBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    public class FFAccountingException extends Exception{}

}