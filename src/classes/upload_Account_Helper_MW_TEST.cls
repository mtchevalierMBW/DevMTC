//@isTest(seeAllData=true)
@isTest
private class upload_Account_Helper_MW_TEST {

   @isTest
   private static void OwnerAndLocationByNames() {
   	 
/**
       User o = [select Id, Name from User where isActive=true limit 1];
       dealer__Dealer_Location__c l = [select Id, Name from dealer__Dealer_Location__c limit 1];
   
       // Plain & simple (no upload helper)
       Account plain = new Account(Name='Test noupload account', BillingState='OH', BillingPostalCode='44641');
       insert(plain);
   
       Account a = new Account();
       a.Name = 'Test upload helper';
       a.BillingState = 'OH';
       a.BillingPostalCode = '44641';
       a.upload_Location__c = l.Name.toLowerCase();
       a.upload_Owner__c = o.Name.toLowerCase();
       a.upload_RecordType__c = 'Business Account';
       insert(a);

       Account b = new Account();
       b.Name = 'Test upload vendor helper';
       b.BillingState = 'PA';
       b.BillingPostalCode = '17601';
       b.upload_Location__c = l.Name.toLowerCase();
       b.upload_RecordType__c = 'Vendor';
       b.upload_Owner__c = 'general manager'; // will not be found, so use Store G.M.
       insert(b);

       List<Account> acc = [select Id, Name, OwnerId, Store_Location__c
                       from Account
                       where Id=:a.Id];
       System.assert(acc.size()==1);
       System.assert(acc[0].OwnerId == o.Id, 'Expected owner ' + o.Name + ' id ' + o.Id + ' got owner ' + acc[0].OwnerId);
       System.assert(acc[0].Store_Location__c == l.Id, 'Expected store id ' + l.Id + ' got store ' + acc[0].Store_Location__c);
**/
   }

}