/**
 * FinanceCompanyAccount
 * Tested by: FinanceCompanyAccount_TEST
 *
 * Keep an associated account for each finance company.
 * Currently this is only a one-way update. If someone has authority to change the account address, 
 * it does NOT update back to the finance company.
 * 
 */
trigger FinanceCompanyAccount on dealer__Finance_Company__c (after delete, before insert, before update) {

   Set<Id> finAcctIds = new Set<Id>();
   Map<Id, Account> finaccts = new Map<Id, Account>();
   Map<Id, Account> fcAccts = new Map<Id, Account>();
   List<Account> updAccts = new List<Account>();
   List<Account> dltAccts = new List<Account>();
   RecordType fcRt = null;
   
   // Create/Update associated accounts
   if (Trigger.isBefore) {
   	   for(dealer__Finance_Company__c fc : Trigger.new) {
   	   	   if(fc.FinanceAccount__c!=null) {
   	           finAcctIds.add(fc.FinanceAccount__c);
   	   	   }
   	   }
   	   if (finAcctIds.size()>0) {
   	       finaccts = new Map<Id, Account>([
   	           select Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode
   	   	       from Account 
   	   	       where Id in :finAcctIds]);
   	   }
   	   for(dealer__Finance_Company__c f : Trigger.new) {
   	   	   // does it need to be updated?
   	   	   Account fa = finaccts.get(f.FinanceAccount__c);
   	   	   if (fa==null) {
   	   	   	   if (fcRt==null) {
   	   	   	   	   fcRt = [select Id, Name from RecordType where SobjectType='Account' and Name='Finance Company' limit 1];
   	   	   	   }
   	   	   	   Account newFcAcct = new Account(
   	   	          RecordTypeId = fcRt.Id, 
   	   	          Name = f.Name,
   	   	     	  BillingStreet = f.dealer__Bank_Address__c,
   	   	     	  BillingCity = f.dealer__Bank_City__c,
   	   	     	  BillingState = f.dealer__Bank_State__c,
   	   	     	  BillingPostalCode = f.dealer__Bank_Zip__c,
   	   	     	  SFSSDupeCatcher__Override_DupeCatcher__c=true
   	   	       ); 
   	   	       fcAccts.put(f.Id, newFcAcct);
   	   	       updAccts.add(newFcAcct);
   	   	   } else if (f.Name!=fa.Name 
   	   	     || f.dealer__Bank_Address__c!=fa.BillingStreet || f.dealer__Bank_City__c!=fa.BillingCity
   	   	     || f.dealer__Bank_State__c!= fa.BillingState || f.dealer__Bank_Zip__c!=fa.BillingPostalCode ) {
				fa.Name = f.Name;
   	   	     	fa.BillingStreet = f.dealer__Bank_Address__c;
   	   	     	fa.BillingCity = f.dealer__Bank_City__c;
   	   	     	fa.BillingState = f.dealer__Bank_State__c;
   	   	     	fa.BillingPostalCode = f.dealer__Bank_Zip__c;
				fa.SFSSDupeCatcher__Override_DupeCatcher__c=true;
   	   	     	updAccts.add(fa);
   	   	   }
   	   }  // end for Trigger.new
   	   
   	   // Update any that need changed
   	   if (updAccts.size()>0) {
   	   	   upsert(updAccts);
	   	   // Now assign the account id just created to the corresponding finance company
	   	   for(dealer__Finance_Company__c f : Trigger.new) {
	   	   	   if (f.FinanceAccount__c==null) {
	   	   	   	   f.FinanceAccount__c = fcAccts.get(f.Id).Id;
	   	   	   }
	   	   }
   	   }
   }
   
   // Delete associated account
   if (Trigger.isDelete) {
   	  for(dealer__Finance_Company__c fd : Trigger.old ) {
   	  	  if(fd.FinanceAccount__c!=null) {
   	  	      dltAccts.add(new Account(Id=fd.FinanceAccount__c));
   	  	  }
   	  }
   	  if (dltAccts.size()>0) {
   	  	  delete(dltAccts);
   	  }
   }

}