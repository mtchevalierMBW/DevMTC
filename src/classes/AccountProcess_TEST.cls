/**
 * AccountProcess_TEST
 * Tests: AccountProcess_TEST
 * Date: Apr 11, 2016
 * Programmer: Bryan Leaman
 *
 *
 *	2016-12-22	B. Leaman	BLL1 - Ignore error of not finding service vehicle created for inventnory vehicle.
 *	2018-07-16	B. Leaman	BLL2 - merge influencer association tests into this class as most function
 *							is now in the AccountProcess class.
 *	2019-01-21	B. Leaman	W-000560 BLL3 - no longer moving opportunities with acct owner change.
 *  2019-03-28  A. Miller   W-000555 AMM4 Update to handle sycning the Mobile and Other phone numbers
 *	2019-10-08	B. Leaman	W-000764 BLL4 - Ensure locations are being assigned to accounts when created!\
 *	2020-01-29	M. Chevalier MTC5 - Wrote tests for updateClosestStorePerAccount and BuildDefaultDataValuesValidationsSummaries
 *	2020-01-28	M. Chevalier MTC6 - rewrote test for updateClosestStorePerAccount using SObjectFabricator class
 */
@isTest
private class AccountProcess_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		TestHelper_MW th = new TestHelper_MW();
		
		System.runAs(FFAdata.TestUser) {
			Account a = th.getPersonAccount('1');
			
   			// create vehicle 
			dealer__Vehicle_Inventory__c veh = new dealer__Vehicle_Inventory__c(
			Name='(TESTX) 2020 Toyota Future',
				New_Used_Other__c='Commercial',
				dealer__Stock_Number__c='TESTX',
				dealer__VIN__c='Z1234567890TUVWXY',
				dealer__Year__c='2020', dealer__Make__c='Toyota', dealer__Model__c='Future',
				dealer__Mileage__c=123000,
				dealer__Sale_Date__c=Date.today()
			);
			insert(veh);
			// Set related service vehicle owner
			dealer__Service_Vehicle__c sv;
			try {	// BLL1a
				sv = [
					select Id, dealer__Veh_Owner__c 
					from dealer__Service_Vehicle__c
					where dealer__Sales_Inventory__c=:veh.Id
					limit 1
				];
				sv.dealer__Veh_Owner__c = a.Id;
				update(sv);
			} catch(Exception e) {}		// BLL1a
		}
	}

	// accountUpdate
	//---------------------------------------
	static testMethod void accountUpdate() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
			Map<Id,Account> acctmap = new Map<Id,Account>([
				select Id, Name, LastServiceDate__c, LastVehicleSaleDate__c, LastEquipmentSaleDate__c from Account limit 1
			]);
				
			AccountProcess.LastServiceAndSale(acctmap);
			System.debug(acctmap);
			AccountProcess.LastServiceAndSale(null);
			
		}
	}


	// proposal update
	//---------------------------------------
	static testMethod void proposalUpdate() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
			Account a = [select Id, Name, LastServiceDate__c, LastVehicleSaleDate__c, LastEquipmentSaleDate__c from Account limit 1];
			Map<Id,dealer__Deal__c> dealmap = new Map<Id,dealer__Deal__c>();
			dealmap.put(UserInfo.getUserId(), new dealer__Deal__c(
				dealer__Buyer__c=a.Id, 
				Proposed_Delivery_Date__c=Date.today(), 
				dealer__Deal_Type__c='Equipment Only Sale',
				dealer__Status__c='Won - Posted'
			)); 
			AccountProcess.RecordLastSale(dealmap);
			dealmap.put(UserInfo.getUserId(), new dealer__Deal__c(
				dealer__Buyer__c=a.Id, 
				Proposed_Delivery_Date__c=Date.today(), 
				dealer__Deal_Type__c='Retail Vehicle Sale',
				dealer__Status__c='Won - Posted'
			)); 
			AccountProcess.RecordLastSale(dealmap);
			System.debug(dealmap);
			AccountProcess.RecordLastSale(null);
			
		}
	}


	// repair order update
	//---------------------------------------
	static testMethod void repairOrderUpdate() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
			Account a = [select Id, Name, LastServiceDate__c, LastVehicleSaleDate__c, LastEquipmentSaleDate__c from Account limit 1];
			Map<Id,dealer__Service_Repair_Order__c> romap = new Map<Id,dealer__Service_Repair_Order__c>();
			romap.put(UserInfo.getUserId(), new dealer__Service_Repair_Order__c(
				dealer__Customer__c=a.Id,
				dealer__Status__c='Posted',
				dealer__Posted_Date_Time__c=DateTime.now()
			)); 
			romap.put(UserInfo.getUserId(), new dealer__Service_Repair_Order__c(
				dealer__Customer__c=a.Id,
				dealer__Status__c='Posted',
				dealer__Posted_Date_Time__c=DateTime.now()
			)); 
			AccountProcess.RecordLastService(romap);
			System.debug(romap);
			AccountProcess.RecordLastService(null);
			
		}
	}


    static testMethod void removeInfluencedAccount() {
    	// BLL1a
		Map<String, Schema.RecordTypeInfo> IARcdTypes = Schema.SObjectType.InfluencerAssociation2__c.getRecordTypeInfosByName();
		Schema.RecordTypeInfo LeadIaRti = IARcdTypes.get('Lead');
		Schema.RecordTypeInfo AcctIaRti = IARcdTypes.get('Account');
		Id LeadIaRtId = LeadIaRti.getRecordTypeId();
		Id AcctIaRtId = AcctIaRti.getRecordTypeId();
		// BLL1a end
		
		TestHelper_MW th = new TestHelper_MW();
		
        Account master = th.getInfluencerAccount('1');
        Account person  = th.getPersonAccount('2');
        
        InfluencerAssociation2__c ia = new InfluencerAssociation2__c(RecordTypeId=AcctIaRtId, InfluencerAccount__c=master.id, InfluencedAccount__c=person.id);
        
        Test.startTest();
        insert(ia);
        delete(person);
        Test.stopTest();
        
        List<InfluencerAssociation2__c> iaList = [
           select Name, InfluencerAccount__c, InfluencedAccount__c
           from InfluencerAssociation2__c
           where InfluencerAccount__c=:master.id
        ];
        
        System.assert(iaList.size()==0, 'Influencer association was not removed when influenced account was deleted.');
        if (iaList.size()>0) {
        	System.debug(iaList[0]);
        }
    }

    static testMethod void missingInfluencedAccount() {
    	// BLL1a
		Map<String, Schema.RecordTypeInfo> IARcdTypes = Schema.SObjectType.InfluencerAssociation2__c.getRecordTypeInfosByName();
		Schema.RecordTypeInfo LeadIaRti = IARcdTypes.get('Lead');
		Schema.RecordTypeInfo AcctIaRti = IARcdTypes.get('Account');
		Id LeadIaRtId = LeadIaRti.getRecordTypeId();
		Id AcctIaRtId = AcctIaRti.getRecordTypeId();
		// BLL1a end

		TestHelper_MW th = new TestHelper_MW();
		
        Account master = th.getInfluencerAccount('1');
        
        InfluencerAssociation2__c ia = new InfluencerAssociation2__c(RecordTypeId=AcctIaRtId, InfluencerAccount__c=master.id);
        
        Test.startTest();
        try {
        	insert(ia);
        } catch(Exception e) {
        	System.debug(e.getMessage());
        }
        Test.stopTest();
        
        List<InfluencerAssociation2__c> iaList = [
           select Name, InfluencerAccount__c, InfluencedAccount__c
           from InfluencerAssociation2__c
           where InfluencerAccount__c=:master.id
        ];
        
        System.assert(iaList.size()==0, 'Influencer association was created with no influenced account specified.');
    }

   	// BLL1a
    static testMethod void InfluencerForLead() {
		Map<String, Schema.RecordTypeInfo> IARcdTypes = Schema.SObjectType.InfluencerAssociation2__c.getRecordTypeInfosByName();
		Schema.RecordTypeInfo LeadIaRti = IARcdTypes.get('Lead');
		Schema.RecordTypeInfo AcctIaRti = IARcdTypes.get('Account');
		Id LeadIaRtId = LeadIaRti.getRecordTypeId();
		Id AcctIaRtId = AcctIaRti.getRecordTypeId();

		TestHelper_MW th = new TestHelper_MW();
		
        Account master = th.getInfluencerAccount('1');
        Lead l = new Lead(FirstName='TestLead', LastName='Leader', Phone='(212) 555-1229');
        insert(l);
        InfluencerAssociation2__c ia = new InfluencerAssociation2__c(RecordTypeId=LeadIaRtId, InfluencerAccount__c=master.id, InfluencedLead__c=l.Id);
        
        Test.startTest();
        insert(ia);
        Test.stopTest();
        
        List<InfluencerAssociation2__c> iaList = [
           select Name, InfluencerAccount__c, InfluencedAccount__c
           from InfluencerAssociation2__c
           where InfluencerAccount__c=:master.id
        ];
        
        System.assert(iaList.size()==1, 'Influencer association was NOT created for a lead.');
    }


    static testMethod void removeInfluencedLead() {
    	// BLL1a
		Map<String, Schema.RecordTypeInfo> IARcdTypes = Schema.SObjectType.InfluencerAssociation2__c.getRecordTypeInfosByName();
		Schema.RecordTypeInfo LeadIaRti = IARcdTypes.get('Lead');
		Schema.RecordTypeInfo AcctIaRti = IARcdTypes.get('Account');
		Id LeadIaRtId = LeadIaRti.getRecordTypeId();
		Id AcctIaRtId = AcctIaRti.getRecordTypeId();
		// BLL1a end
		
		TestHelper_MW th = new TestHelper_MW();
		
        Account master = th.getInfluencerAccount('1');
        Lead l = new Lead(FirstName='TestLead', LastName='Leader', Phone='(212) 555-1229');
        insert(l);
        InfluencerAssociation2__c ia = new InfluencerAssociation2__c(RecordTypeId=LeadIaRtId, InfluencerAccount__c=master.id, InfluencedLead__c=l.Id);
        
        Test.startTest();
        insert(ia);
        delete(l);
        Test.stopTest();
        
        List<InfluencerAssociation2__c> iaList = [
           select Name, InfluencerAccount__c, InfluencedLead__c
           from InfluencerAssociation2__c
           where InfluencerAccount__c=:master.id
        ];
        
        System.assert(iaList.size()==0, 'Influencer association was not removed when influenced lead was deleted.');
        if (iaList.size()>0) {
        	System.debug(iaList[0]);
        }
    }
	// BLL1a end

	// TestUpdatingObjOwners
	static testmethod void TestOwnerReassignment() {
		FFAdata.refresh(); 
		TestHelper_MW th = new TestHelper_MW();
		Account a = th.getPersonAccount('1');
		a.OwnerId = UserInfo.getUserId();
		update(a);
		System.debug(a.OwnerId);
		Task t = new Task(
			WhatId=a.Id, 
			Subject='Test task',
			OwnerId=a.OwnerId);
		insert(t);
		dealer__Sales_Up__c s = new dealer__Sales_Up__c(
			dealer__Customer_Account__c=a.Id, 
			dealer__Lead_Status__c='Pending', 
			Name='TestSolOpp',
			dealer__Salesperson_1__c=a.OwnerId);
		insert(s);
		// BLL3d
		//Opportunity o = new Opportunity(AccountId=a.Id, StageName='Pending', Name='TestOpp',CloseDate=Date.today(), Sales_Channel__c='MBW N/A');
		//insert(o);		
		// BLL3 end
		
		//System.runAs(FFAdata.TestUser) {
			Test.startTest();
System.debug(a.OwnerId);
System.debug(FFadata.TestUser.Id);
			a.OwnerId = FFAdata.TestUser.Id;
			update(a);
			Test.stopTest();
		//}
		Task newt = [select Id, Subject, OwnerId from Task limit 1];
		dealer__Sales_Up__c news = [select Id, OwnerId from dealer__Sales_Up__c limit 1];
		// BLL3d
		//Opportunity newo = [select Id, Name, OwnerId from Opportunity limit 1];
		// BLL3 end

		System.assertEquals(FFAdata.TestUser.Id, newt.OwnerId, 'Task ownership did not change');
		System.assertEquals(FFAdata.TestUser.Id, news.OwnerId, 'Solution opportunity ownership did not change');
		// BLL3d
		//System.assertEquals(FFAdata.TestUser.Id, newo.OwnerId, 'Opportunity ownership did not change');
		// BLL3 end
	}

	static testmethod void TestInfluencerAddition() {
		TestHelper_MW th = new TestHelper_MW();
		Account a = th.getPersonAccount('1');
		Account i = th.getInfluencerAccount('2');
		Contact c = new Contact(FirstName='TestContact3',LastName='ContactLast3',AccountId=i.Id);
		insert(c);

		Test.startTest();
		a.AddNewInfluencer__c = i.Id;
		a.AddNewInfluencerContact__c = c.Id;
		update(a);
		Test.stopTest();
		
		InfluencerAssociation2__c ia2 = [select Id, Name, InfluencerAccount__c, InfluencerContact__c, InfluencedAccount__c from InfluencerAssociation2__c limit 1];
		System.assert(ia2!=null, 'Influencer association was not created');		
	}

   static testmethod void OwnerAndLocationByNames() {

		FFAdata.refresh(); 
		TestHelper_MW th = new TestHelper_MW();

		List<Account> acc;
		// BLL4
		//User o = [select Id, Name from User where isActive=true and Id!=:FFAdata.TestUser.Id limit 1];
		User o = [select Id, Name from User where Id=:UserInfo.getUserId() limit 1];		
		//dealer__Dealer_Location__c l = [select Id, Name from dealer__Dealer_Location__c limit 1];
		dealer__Dealer_Location__c l = FFAData.DealerLocation;
		update(new User(Id=FFAdata.TestUser.Id, Division=l.dealer__Company_Number__c));
		List<Account> acc_c;
		// BLL4

		System.runAs(FFAdata.TestUser) {
			Test.startTest();
   	 
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

			Test.stopTest();
		
			// BLL4
			Account c = new Account(
				Name = 'Testing defaul location',
				BillingState = 'OH',
				BillingPostalCode = '44641',
				upload_RecordType__c = 'Business Account'
			);
			insert(c);
			acc_c = [select Id, Name, OwnerId, Store_Location__c from Account where Id=:c.Id];
			// BLL4
		
			acc = [
				select Id, Name, OwnerId, Store_Location__c
                from Account
                where Id=:a.Id
            ];
		}

		System.assert(acc.size()==1);
		System.assert(acc[0].OwnerId == o.Id, 'Expected owner ' + o.Name + ' id ' + o.Id + ' got owner ' + acc[0].OwnerId);
		System.assert(acc[0].Store_Location__c == l.Id, 'Expected store id ' + l.Id + ' got store ' + acc[0].Store_Location__c);
		// BLL4
		System.assert(acc_c.size()==1);
		System.assertEquals(FFAData.DealerLocation.Id, acc_c[0].Store_Location__c, 'Did not assign user\'s assigned store to account');
		// BLL4 end
   }
   
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


	// BLL3a
	private static testMethod void ContactDesiredVehicles() {
		//TestHelper_MW th = new TestHelper_MW();
		//Account p = th.getPersonAccount('1');
		Contact c = new Contact(FirstName = 'Testing', LastName='Contact1');
		insert(c);
		
		Test.startTest();
		c.Desired_Vehicles__c = '12345B';
		update(c);
		c.Desired_Vehicles__c = 'This is going to be a long vehicle description, so be ready';
		update(c);
		c.Desired_Vehicles__c = '23456C';
		update(c);
		Test.stopTest();
		
		Contact check_c = [
			select Id, Desired_Vehicles__c
			from Contact where Id=:c.Id 
			limit 1
		];
		System.assertEquals('12345B; This is going to be a long vehicle description, so be ready; 23456C', 
			check_c.Desired_Vehicles__c, 'Did not properly concatenate desired vehicles on account record');	// BLL4c account record
	}
	// BLL3a end

	
	private static testMethod void ContactInfluencerCleanup() {
		Map<String, Schema.RecordTypeInfo> IARcdTypes = Schema.SObjectType.InfluencerAssociation2__c.getRecordTypeInfosByName();
		Schema.RecordTypeInfo AcctIaRti = IARcdTypes.get('Account');
		Id AcctIaRtId = AcctIaRti.getRecordTypeId();

		TestHelper_MW th = new TestHelper_MW();
		Account p = th.getPersonAccount('1');
		Contact c = new Contact(FirstName = 'Testing', LastName='Contact1');
		insert(c);
		
		InfluencerAssociation2__c ia2 = new InfluencerAssociation2__c(
			RecordTypeId = AcctIaRtId,
			InfluencedAccount__c = p.Id,
			InfluencerContact__c = c.Id
		);
		insert(ia2);
		
		Test.startTest();
		delete(c);
		Test.stopTest();
			
		List<InfluencerAssociation2__c> ia2list = [select Id, Name from InfluencerAssociation2__c where InfluencedAccount__c=:p.id ];
		System.assert(ia2list.size()==0, 'Contact influencer association was not removed when contact was deleted');
	}
	
    // AMM4
	private static testMethod void TestAccountSyncning()
	{
		TestHelper_MW th = new TestHelper_MW();
		
		Account p = th.getPersonAccount('1');
		String testPhoneNumber = '1234567890';
		p.PersonMobilePhone = testPhoneNumber;
		p.PersonOtherPhone = testPhoneNumber;

		Test.StartTest();
		update p;
		Test.StopTest();

		p = [SELECT Id, 
				PersonMobilePhone, 
				PersonOtherPhone, 
				BusinessMobilePhone__c, 
				BusinessOtherPhone__c 
			FROM Account
			WHERE Id = :p.Id
			LIMIT 1];

		System.assertEquals(testPhoneNumber, p.PersonMobilePhone);
		System.assertEquals(testPhoneNumber, p.PersonOtherPhone);
		System.assertEquals(testPhoneNumber, p.BusinessMobilePhone__c);
		System.assertEquals(testPhoneNumber, p.BusinessOtherPhone__c);
	}
	// AMM4

	// MTC4 start
    @IsTest
    static void updateClosestStorePerAccount_givenEmptyList_returnsVoid() {
        Test.startTest();
            AccountProcess.updateClosestStorePerAccount(new List<Account>());
        Test.stopTest();
    }
	// MTC5 start
    @IsTest
    static void updateClosestStorePerAccount_givenSingleCustomer_returnsVoid() {
		List<Account> accts = new List<Account>{
				(Account) new sfab_FabricatedSObject(Account.class)
						.setField(Account.BillingLatitude, 41.155330)
						.setField(Account.BillingLongitude, -81.420850)
						.toSObject()
		};
        Test.startTest();
			AccountProcess.updateClosestStorePerAccount(accts);
        Test.stopTest();
    }
	// MTC5 end
	// MTC4 end
}