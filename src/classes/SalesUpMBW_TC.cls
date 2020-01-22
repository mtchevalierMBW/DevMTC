/**
 * SalesUpMBW_TC
 * Tests: SalesUpMBW class, SalesUpMBWContact trigger
 *
 *	2015-12-10	B. Leaman	BLL1 add tests for new upload_Account__c and upload_Owner__c fields.
 *	2016-01-12	B. Leaman	BLL2 create trigger control setting for SalesUpUpdateContactInfo for tests.
 * 	2016-01-28	B. Leaman	BLL3 - too many SOQL queries - add startTest & stopTest to help reduce;
 *	2017-07-11	B. Leaman	BLL4 - additional test for code coverage. 
 *	2018-08-30	B. Leaman	BLL5 - new requirements due to opportunity synchronization.
 *	2019-09-17	B. Leaman	W-000730 BLL6 - fix errors with DT 5.x upgrade.
 */
@isTest
Public Class SalesUpMBW_TC{

	// BLL6
	@TestSetup
	static void setupEnv() {
		dealer.TestClassUtil tc = new dealer.TestClassUtil();
		tc.insertDMSSettings();
	}
	// BLL6 end

	Static testmethod Void Myunittest(){
		
		// BLL2a - test this code in the trigger even though the control was implemented so we can disable this in production
		MW_TriggerControls__c updateContactInfo = new MW_TriggerControls__c(Name='SalesUpUpdateContactInfo', Enabled__c=true);
		insert(updateContactInfo);
		// BLL2a end
		
		Contact con = new Contact();
		con.Phone = '8888888';
		con.LastName = 'Test';
		insert con;
		
		RecordType rt = [select Id, Name from RecordType where isPersonType=true limit 1];
		Account a = new Account(RecordTypeId=rt.Id);
		a.LastName ='Test';
		a.AccountSource ='Dealer';
		a.FirstName='test';
		a.PersonHomePhone='1236536586';
		a.PersonMobilePhone='12345676796';
		a.PersonEmail='Test@gmail.com';
		a.dealer__PersonContactId__c=con.id;
		insert a;
		 
		
		dealer__Sales_Up__c  dsp = new dealer__Sales_Up__c();
		dsp.dealer__Lead_Date__c=System.Today();
		dsp.dealer__Lead_Status__c='Pending';
		dsp.dealer__Lead_Type__c='List';
		dsp.dealer__Source__c ='Pride';	// BLL5c
		dsp.Solution_Type__c ='Rental';	// BLL5c
		dsp.dealer__Customer_Account__c =a.id;
		dsp.dealer__Co_Buyer__c = a.id;
		dsp.dealer__Buyer_Contact__c = con.id;
		dsp.dealer__Home_Phone__c ='5265363';
		dsp.dealer__Mobile__c ='3142372678';
		dsp.dealer__Email__c = 'Test@gmail.com';
		dsp.dealer__Salesperson_1__c = UserInfo.getUserId();
		insert dsp;
		
		Test.startTest(); // BLL3a
		
		ApexPages.StandardController sc = new ApexPages.StandardController(dsp);
		ApexPages.currentPage().getParameters().put('id', dsp.id);
		ApexPages.currentPage().getParameters().put('_lkid', a.id);
		SalesUpMBW sbw = new SalesUpMBW(new ApexPages.StandardController(dsp));
		
		 
		Account acc=[Select PersonContactId from Account where LastName ='Test'];
		sbw.personsAccountReference='';
		Map<String, String> urlParameters = new Map<String, String>();
		 
		sbw.personsAccountReference = acc.PersonContactId  ;
		 
		
		//sbw.personsAccountContact(acc.PersonContactId );
		sbw.accountFromContact(acc.PersonContactId);
		sbw.personsAccount(a.id);
		sbw.lookupPersonsAccountId(acc.PersonContactId );
		
		// non-person acct test for SalesUpMBWContact trigger
		
		RecordType rt2 = [select Id, Name from RecordType where isPersonType=false and Name like 'Bus%' limit 1];
		Account a2 = new Account(RecordTypeId=rt2.Id);
		a2.Name ='Test2 acct';
		//a2.AccountSource ='Dealer';
		a2.Phone='1236536589';
		a2.BillingState='OH';
		a2.BillingPostalCode='44641';
		insert a2;
		
		Contact con2 = new Contact();
		con2.Phone = '8888889';
		con2.LastName = 'Test9';
		con2.AccountId = a2.Id;
		insert con2;
		
		
		dealer__Sales_Up__c  dsp2 = new dealer__Sales_Up__c();
		dsp2.dealer__Lead_Date__c=System.Today();
		dsp2.dealer__Lead_Status__c='Pending';
		dsp2.dealer__Lead_Type__c='List';
		dsp2.dealer__Source__c ='Pride_lkid';
		dsp2.Solution_Type__c = 'Chassis/Conversion';
		dsp2.dealer__Customer_Account__c =a2.id;
		dsp2.dealer__Co_Buyer__c = a2.id;
		dsp2.dealer__Buyer_Contact__c = con2.id;
		dsp2.dealer__Home_Phone__c ='5265363';
		dsp2.dealer__Mobile__c ='3142372678';
		dsp2.dealer__Email__c = 'Test2@gmail.com';
		dsp2.dealer__Salesperson_1__c = UserInfo.getUserId();
		insert dsp2;
		
		sbw.validRecord();
		sbw.save();
		
		Test.stopTest(); // BLL3a
	
	}
	
	// BLL1a
	static testmethod void testUploads() {
		TestHelper_MW th = new TestHelper_MW();
		User u = th.getTestUser('1');
		User u2 = [select Id, Name from User where Id=:u.Id];
		Account a = th.getPersonAccount('1');
		a.dealer__External_ID__c = 'Test 123 xyz';
		update(a);
		Test.startTest();
		dealer__Sales_Up__c s = new dealer__Sales_Up__c(
			Name = 'Test salesup',	// BLL5a
			upload_Owner__c=u2.Name.toLowerCase(),
			upload_Account__c=a.dealer__External_ID__c,
			upload_BDC__c='Missing Name'
		);
		insert(s); 
		Test.stopTest();
		dealer__Sales_Up__c s2 = [select Id, Name, dealer__Customer_Account__c, OwnerId from dealer__Sales_Up__c where Id=:s.Id];
		System.assert(s2.OwnerId!=UserInfo.getUserId(), 'Did not get correct owner');
		System.assert(s2.dealer__Customer_Account__c==a.Id, 'Did not get correct account');
	}
	// BLL1a end
	

	// BLLxa address change test
	static testmethod void testAddrChg() {
		TestHelper_MW th = new TestHelper_MW();
		Account a = th.getBusinessAccount('1');
		Contact c = new Contact(FirstName='BL', LastName='LTest', AccountId=a.Id,
			MailingStreet='101 King St', MailingCity='Lancaster', MailingState='PA',
			MailingPostalCode='17601');
		insert(c);
		dealer__Sales_Up__c s = new dealer__Sales_Up__c(
			dealer__Customer_Account__c=a.Id,
			dealer__Buyer_Contact__c=c.Id,
			BuyerContact__c=c.Id,
			dealer__Lead_Date__c=System.Today(),
			dealer__Lead_Status__c='Pending',
			dealer__Lead_Type__c='List',
			dealer__Source__c ='Pride_lkid',
			Solution_Type__c = 'Chassis/Conversion',
			dealer__Home_Phone__c ='5265363',
			dealer__Mobile__c ='3142372678',
			dealer__Email__c = 'Test2@gmail.com',
			dealer__Salesperson_1__c = UserInfo.getUserId()
		);
		insert(s);
		s.dealer__Mailing_Street__c = '102 King St';
		s.dealer__Mailing_City__c='Lancaster';
		s.dealer__Mailing_State__c='PA';
		s.dealer__Mailing_Zip__c='17602';
		update(s);
	}

	static testmethod void testOwnerChg() {

		TestHelper_MW th = new TestHelper_MW();
		Account a = th.getPersonAccount('1');
		dealer__Sales_Up__c s = new dealer__Sales_Up__c(
			dealer__Customer_Account__c=a.Id,
			dealer__Lead_Date__c=System.Today(),
			dealer__Lead_Status__c='Pending',
			dealer__Lead_Type__c='List',
			dealer__Source__c ='Pride_lkid',
			Solution_Type__c = 'Chassis/Conversion',
			dealer__Home_Phone__c ='5265363',
			dealer__Mobile__c ='3142372678',
			dealer__Email__c = 'Test2@gmail.com',
			dealer__Salesperson_1__c = UserInfo.getUserId()
		);
		insert(s);
        DateTime dt = DateTime.now();
        dealer__Sales_Appointment__c appt1 = new dealer__Sales_Appointment__c(
           dealer__Appointment_Type__c = 'First Visit',
           dealer__Assigned_To__c = UserInfo.getUserId(),
           dealer__Customer__c = a.PersonContactId,
           dealer__Sales_Up__c = s.Id,
           dealer__DateTime__c = dt,
           dealer__Date__c = dt.date(),
           dealer__Time__c = dt.format('hh:mm a')
        );
        insert(appt1);

       Profile prof = [select id from profile where name='system Administrator'];
       User usr = new User(alias = 'usr', email='us.name@vmail.com',
                  emailencodingkey='UTF-8', lastname='lstname',
                  timezonesidkey='America/Los_Angeles',
                  languagelocalekey='en_US',
                  localesidkey='en_US', profileid = prof.Id,
                  username='testuser128@test.mobilityworks.com',
                  Division='DT1');
        insert usr;
		
		Test.startTest();
		s.dealer__Salesperson_1__c = usr.Id;
		update(s);
		Test.stopTest();
		
	}
	
}