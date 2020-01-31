/**
 * AccountManagement_TEST
 * Test: AccountManagement trigger, ContactTrigger
 *
 *  2015-08-21  B. Leaman   BLL1 - Update test since AP account is not being set on customers anymore.
 * 	2015-10-30	B. Leaman	BLL2 - Test setting Do Not Call, Email or Mail flags on Deceased accounts.
 *	2016-01-05	B. Leaman	BLL3 - Test concatenation of Desired_Vehicles__c field (from Pardot).
 *	2016-05-02	B. Leaman	BLL4 - Also test contact's Desired_Vehicles__c process.
 *  2020-01-28	M. Chevalier MTC1 - rewrote emptytest after implementing TriggerHandler framework
 */
@isTest
private class AccountManagement_TEST {
	static testmethod void emptytest() {
		insert new Account(Name='testAccount');
	}
/**	
   @isTest
   private static void OwnerLocationRecordTypeByNames() {
     
       User o = [select Id, Name from User where isActive=true limit 1];
       //dealer__Dealer_Location__c l = [select Id, Name from dealer__Dealer_Location__c limit 1];
     dealer__Dealer_Location__c ddl = new dealer__Dealer_Location__c();
    ddl.Name ='Test';
    ddl.dealer__City__c ='Test';
    ddl.dealer__Postal_Code__c='301352';
    ddl.dealer__State__c='Te';
    ddl.dealer__Company_Number__c='12345';
    ddl.dealer__Service_Director__c =Userinfo.getuserid();
    insert ddl;
       Test.startTest();
    
       // Plain & simple (no upload helper)
       Account plain = new Account(Name='Test noupload account', BillingState='OH', BillingPostalCode='44641');
       insert(plain);
   
       Account a = new Account();
       a.Name = 'Test upload helper';
       a.BillingState = 'OH';
       a.BillingPostalCode = '44641';
       a.upload_Location__c =ddl.Name.toLowerCase();
       a.upload_Owner__c = o.Name.toLowerCase();
       a.upload_RecordType__c = 'Business Account';
       insert(a);

       Account b = new Account();
       b.Name = 'Test upload vendor helper';
       b.BillingState = 'PA';
       b.BillingPostalCode = '17601';
       b.upload_Location__c = ddl.Name.toLowerCase();
       b.upload_RecordType__c = 'Vendor';
       b.upload_Owner__c = 'general manager'; // will not be found, so use Store G.M.
       insert(b);
       
       // Person account
       Account p = new Account();
       p.upload_RecordType__c = 'Person Account';
       p.FirstName = 'Person';
       p.LastName = 'Account';
       p.PersonMailingState = 'OK';
       p.PersonEmail = 'person.account@example.com';
       p.PersonHomePhone = '(555) 555-1212';
       insert(p);

       Test.stopTest();

       List<Account> acc = [select Id, Name, OwnerId, Store_Location__c,
                                   c2g__CODAAccountsPayableControl__c, c2g__CODAAccountsReceivableControl__c
                       from Account
                       where Id=:a.Id];
       System.assert(acc.size()==1);
       System.assert(acc[0].OwnerId == o.Id, 'Expected owner ' + o.Name + ' id ' + o.Id + ' got owner ' + acc[0].OwnerId);
       System.assert(acc[0].Store_Location__c == ddl.Id, 'Expected store id ' + ddl.Id + ' got store ' + acc[0].Store_Location__c);
       //BLL1d System.assert(acc[0].c2g__CODAAccountsPayableControl__c!=null, 'AP Control is null');
       //System.assert(acc[0].c2g__CODAAccountsReceivableControl__c!=null, 'AR Control is null');
       
       // BLL1a begin block verify vendor account
       // Check out vendor
       List<Account> acc2 = [select Id, Name, OwnerId, Store_Location__c,
                                   c2g__CODAAccountsPayableControl__c, c2g__CODAAccountsReceivableControl__c,
                                   c2g__CODADescription1__c, c2g__CODADaysOffset1__c, c2g__CODADiscount1__c
                       from Account
                       where Id=:b.Id];
       System.assert(acc2.size()==1);
       //System.assert(acc2[0].c2g__CODAAccountsPayableControl__c!=null, 'AP Control is null');
       System.assert(acc2[0].c2g__CODADescription1__c=='Net 30 Days', 'Vendor terms is not Net 30 Days');
       System.assert(acc2[0].c2g__CODADaysOffset1__c==30.0, 'Vendor days offset is not 30');
       System.assert(acc2[0].c2g__CODADiscount1__c==0, 'Vendor discount is not 0%');
       // BLL1a end block
       
   }

	// BLL2a
	private static testmethod void DeceasedPerson() {
   		TestHelper_MW th = new TestHelper_MW();
   		Account a = th.getPersonAccount('1');
   		a.Account_Status__c = 'Deceased';
   		Test.startTest();
   		update(a);
   		// Increase code coverage...
   		a.FirstName = 'ABCDEFG';
   		a.LastName = 'HIJKLMNOP';
   		update(a);
   		a.FirstName = 'abcdefghijkl';
   		a.LastName = 'mnopqrstuvw';
   		update(a);
   		Test.stopTest();
   		Account aupd = [
   			select Id, Name, PersonDoNotCall, PersonHasOptedOutOfEmail, Mail_Opt_Out__c, dealer__PersonsDoNotCall__c, dealer__EmailOptOut__c
			from Account
			where Id=:a.Id
			limit 1
   		];
   		System.assert(aupd.PersonDoNotCall && aupd.PersonHasOptedOutOfEmail && aupd.Mail_Opt_Out__c && aupd.dealer__PersonsDoNotCall__c && aupd.dealer__EmailOptOut__c,
   		    'Deceased PersonAccount was not flagged for do not call, email or mail'
   		);
	}   

	// Third party account to increase code coverage
	private static testmethod void ThirdPartyPayor() {
   		TestHelper_MW th = new TestHelper_MW();
   		c2g__codaGeneralLedgerAccount__c gla = new c2g__codaGeneralLedgerAccount__c(
   		    Name = '1100 - Test', c2g__ReportingCode__c = '1100', c2g__Type__c='Profit and Loss'
   		);
   		//try {
   			insert(gla);
   		//} catch(Exception e) {}
		Test.startTest();
		Account a = th.getThirdPartyAccount('1');
		Test.stopTest();
	}
	// BLL2a end

	// BLL3a
	private static testMethod void DesiredVehicles() {
		TestHelper_MW th = new TestHelper_MW();
		Account p = th.getPersonAccount('1');
		Test.startTest();
		p.Desired_Vehicles__c = '12345B';
		p.Desired_Vehicles__pc = '12346B';	// BLL4a
		update(p);
		p.Desired_Vehicles__c = 'This is going to be a long vehicle description, so be ready';
		p.Desired_Vehicles__pc = 'This is going to be a long vehicle description, so be ready';	// BLL4a
		update(p);
		p.Desired_Vehicles__c = '23456C';
		p.Desired_Vehicles__pc = '23457C';	// BLL4a
		update(p);
		Test.stopTest();
		Account check_p = [
			select Id, Name, Desired_Vehicles__c, Desired_Vehicles__pc	// BLL4c add Desired_Vehicles_pc
			from Account where Id=:p.Id 
			limit 1
		];
		System.assertEquals('12345B; This is going to be a long vehicle description, so be ready; 23456C', 
			check_p.Desired_Vehicles__c, 'Did not properly concatenate desired vehicles on account record');	// BLL4c account record
		System.assertEquals('12346B; This is going to be a long vehicle description, so be ready; 23457C', 
			check_p.Desired_Vehicles__pc, 'Did not properly concatenate desired vehicles on contact record');	// BLL4a
	}
	// BLL3a end
**/
}