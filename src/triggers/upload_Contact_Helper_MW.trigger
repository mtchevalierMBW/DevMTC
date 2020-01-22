// Contact upload helper 
// link Contact to Account using external ID from Legacy system 
// and set ownership of contact to same as account
// Uses MW_TriggerControls__c custom list settings for:
// uploadContactHelper
trigger upload_Contact_Helper_MW on Contact (before insert, before update) {
  
    if (Trigger.isBefore) {

        MW_TriggerControls__c uploadHelper = MW_TriggerControls__c.getInstance('uploadContactHelper');
        if (uploadHelper==null || uploadHelper.Enabled__c || Test.isRunningTest()) {


            List<String> extIds = new List<String>();
            // get lists of text to translate to ids
            for(Contact t: Trigger.new) {
                  String s = t.Upload_AccountID__c;
                  if (!String.isBlank(s)) {
                      extIds.add(s);
                  }
                  //System.debug(ExtIDs);
            }
  

            Map<String,Account> acctMap = new Map<String,Account>();
            for(Account a : [select Id, Name, dealer__External_Id__c, OwnerId from Account where dealer__External_Id__c in :extIds]) {
                    acctMap.put(a.dealer__External_Id__c, a);
            }


            for(Contact c : Trigger.New) {
                    //System.debug('Acct ID:' + c.upload_AccountID__c);
                    Account a = acctMap.get(c.upload_accountID__c);
                    if (a!=null) {
                            System.debug('Account ID: ' + a.id + ', Owner: ' + a.ownerid);
                            c.AccountId = a.Id;
                            c.OwnerId = a.OwnerId;
                            //System.debug('Contact ID: ' + c.id + ' Acccount ID: ' + c.upload_accountID__c);
                            c.upload_AccountID__c='';
                    }
            }

                  
        } // if uploadAccountHelper enabled
         
    } // if Trigger.isBefore

}