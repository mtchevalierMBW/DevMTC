/**
 * UploadReferenceHelper_TEST
 * Tests: UploadReferenceHelper
 * 
 *
 */
@isTest
private class UploadReferenceHelper_TEST {

    static testMethod void unitTest() {
    	
    	TestHelper_MW th = new TestHelper_MW();
    	dealer__Dealer_Location__c loc = th.getDealerLocation('1');

		Test.startTest();    	
        UploadReferenceHelper urh = new UploadReferenceHelper(
        	'upload_Location__c', 'dealer__Dealer_Location__c', 'Name', 
 			new Map<String,String>{'Store_Location__c'=>'Id'}
        );
 		urh.retainReferenceValue = true;  // Don't remove the upload_Location__c values
 		List<Account> acctList = new List<Account>();
 		Account a = new Account(Name='TestAcct', upload_Location__c=loc.Name, Store_Location__c=null);
 		acctList.add(a);
 		urh.updAllReferences(acctList);
 		Test.stopTest();
 		System.assert(a.Store_Location__c!=null,'Did not assign location to account');
 		
    }
    
}