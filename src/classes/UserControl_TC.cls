/*
	UserControl_TC
	Test: UserControl trigger

	2019-02-08	B. Leaman	W-000588 increase code coverage (use stores that have existing roles)
*/
@isTest
Public Class UserControl_TC{

	@TestSetup
	static void makeData(){


		List<dealer__Dealer_Location__c> locs = new List<dealer__Dealer_Location__c>();
		dealer__Dealer_Location__c ddl = new dealer__Dealer_Location__c();
		ddl.Name ='Test';
		ddl.dealer__City__c ='Test';
		ddl.dealer__Postal_Code__c='301352';
		ddl.dealer__State__c='Te';
		// BLL1
		//ddl.dealer__Company_Number__c='12365';
		ddl.dealer__Company_Number__c = 'AKR';
		// BLL1 end
		//ddl.dealer__Service_Director__c =u.id;
		// BLL1d insert ddl;
		locs.add(ddl);

		dealer__Dealer_Location__c ddl2 = new dealer__Dealer_Location__c();
		ddl2.Name ='Test2';
		ddl2.dealer__City__c ='Test2';
		ddl2.dealer__Postal_Code__c='301353';
		ddl2.dealer__State__c='Te';
		// BLL1
		//ddl2.dealer__Company_Number__c='12365';
		ddl2.dealer__Company_Number__c = 'TOL';
		// BLL1 end
		//ddl2.dealer__Service_Director__c =u.id;
		// BLL1d insert ddl;
		locs.add(ddl2);

		insert(locs);

	}

	Static testmethod Void Myunittest1(){

		List<UserRole> parents =new List<UserRole>();
		parents.add(new UserRole(Name='Parent1 Region'));
		parents.add(new UserRole(Name='Parent2 Region'));
		insert(parents);

		List<UserRole> roles = new List<UserRole>();
		roles.add(new UserRole(Name='AKR_Store', ParentRoleId=parents[0].Id));
		roles.add(new UserRole(Name='TOL_Store', ParentRoleId=parents[1].Id));
		insert(roles);

		Map<String,UserRole> roleNameMap = new Map<String,UserRole>();
		Map<Id,UserRole> roleMap = new Map<Id,UserRole>([select Id, Name, DeveloperName, ParentRoleId from UserRole]);
		for(UserRole r : roleMap.values()) roleNameMap.put(r.DeveloperName,r);

		Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 

		Test.startTest();
		User u = new User();
		u.Alias = 'standt';
		u.Email='testabc@gmail.com';
		u.EmailEncodingKey='UTF-8';
		u.LastName='Testing';
		u.LanguageLocaleKey='en_US';
		u.LocaleSidKey='en_US';
		u.ProfileId = p.Id;
		u.TimeZoneSidKey='America/Los_Angeles';
		u.UserName='tesa1111@gmail.com';
		u.Dealership_Location__c ='Test';
		//u.service_manager__c  ='Test';
		u.Division ='12365';
		insert u;
		Test.stopTest();

	// BLL2 - split into 2 tests to avoid DML on setup object after other DML
	}

	Static testmethod Void Myunittest2(){

		List<UserRole> parents =new List<UserRole>();
		parents.add(new UserRole(Name='Parent1'));
		parents.add(new UserRole(Name='Parent2'));
		insert(parents);

		List<UserRole> roles = new List<UserRole>();
		roles.add(new UserRole(Name='AKR_Store', ParentRoleId=parents[0].Id));
		roles.add(new UserRole(Name='TOL_Store', ParentRoleId=parents[1].Id));
		insert(roles);

		Map<String,UserRole> roleNameMap = new Map<String,UserRole>();
		Map<Id,UserRole> roleMap = new Map<Id,UserRole>([select Id, Name, DeveloperName, ParentRoleId from UserRole]);
		for(UserRole r : roleMap.values()) roleNameMap.put(r.DeveloperName,r);

		Profile p1 = [SELECT Id FROM Profile WHERE Name='Standard User']; 

		Test.StartTest();

		User u1 = new User();
		u1.Alias = 'standt';
		u1.Email='testabc@gmail.com';
		u1.EmailEncodingKey='UTF-8';
		u1.LastName='Testing';
		u1.LanguageLocaleKey='en_US';
		u1.LocaleSidKey='en_US';
		u1.ProfileId = p1.Id;
		u1.TimeZoneSidKey='America/Los_Angeles';
		u1.UserName='diligentasddasd@sfdc.com';
		u1.Dealership_Location__c ='Test';
		//u.service_manager__c  ='Test';
		// BLL1
		//u1.Division ='12365';
		u1.Division = 'AKR';
		u1.UserRoleId = roleNameMap.get(u1.Division+'_Store').Id;
		// BLL1 end
		insert u1;

		u1.Dealership_Location__c ='Testav';
		// BLL1
		u1.Division = 'TOL';
		// BLL1 end
		update u1;
		Test.stopTest();

	// BLL2 end
	}
}