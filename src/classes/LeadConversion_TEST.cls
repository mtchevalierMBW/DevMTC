/**
 * LeadConversion_TEST
 * Tests: LeadConversion_EXT, LeadTrigger_MW
 * 
 *	2016-10-20	B. Leaman	Need to adjust to reduce SOQL queries after change to create tasks for chassis sales.
 *	2018-07-09	B. Leaman	BLL2 - Test influencer copy as well.
 *  2019-07-27  A. Miller   AMM1 - W-000552 Appointment location
 *  2019-08-27	B. Leaman	W-000738 BLL31 copy price point from lead into solution opp (lead conversion mapping handles account and contact)
 * 							Also increase code coverage;
 *	2019-09-18	B. Leaman	W-000730 BLL4 - DT 5.x new requirements
 */
@isTest
private class LeadConversion_TEST {

	// BLL4
	@TestSetup
	static void setupEnv() {
		dealer.TestClassUtil tc = new dealer.TestClassUtil();
		tc.insertDMSSettings();
	}
	// BLL4

    @isTest static void testLeadConversion1() {
        TestHelper_MW th = new TestHelper_MW();
        th.suspendDupeCatcher();

        dealer__Dealer_Location__c loc = th.getDealerLocation('1');
        RecordType rt = th.getRetailLeadRt();
        
        Lead lead = new Lead();
        lead.Store_Location__c = loc.Id;
        lead.RecordTypeId = rt.Id;
        lead.FirstName = 'TestLead';
        lead.LastName = 'Conversion';
        lead.PostalCode = '90210';
        lead.Phone = '(330) 555-1111';
        lead.Email = 'testlead.conversion@example.com';
        lead.State = 'CA';
        lead.Company = 'Testing Conversion';
        // BLL1 additional info to be passed to Arcadium
        lead.Desired_Vehicles__c = '1234B';
        lead.Vehicle_preference__c = 'Toyota Sienna';
        lead.Rental_pickup_location__c = 'Akron';
        lead.Rental_pick_up__c = Date.today();
        lead.Rental_drop_off__c = Date.today();
        lead.Van_year__c = '2000';
        lead.Van_make__c = 'Toyota';
        lead.Van_model__c = 'Sienaa';
        lead.Van_VIN__c = '123456789ABCDEFGH';
        lead.Currently_own__c = 'n/a';
        lead.Contact_availability__c = 'M-F 8-5';
        lead.Vehicle_information__c = 'My van';
        lead.Van_odometer__c = '153000';
        lead.Nearest_location__c = 'Akron';
        lead.Referral_method__c = 'Friend';
        lead.Visited_a_store__c = 'Yes';
        lead.Solution_Type__c = 'Chassis/Conversion';
        // BLL1 end additional info
        insert lead;
 
        Test.startTest();
         
        PageReference pgRef = Page.LeadConversion; 
        Test.setCurrentPage(pgRef); //Set the page for Test Method
        ApexPages.currentPage().getParameters().put('id', lead.id);
        ApexPages.currentPage().getParameters().put('retURL', '/');
        ApexPages.StandardController leadCtlr = new ApexPages.StandardController(lead);
        //LeadConversion_CTLR lc = new LeadConversion_CTLR();
        LeadConversion_EXT lc = new LeadConversion_EXT(leadCtlr);
        
        for(Id i : lc.procRcdTypeMap.keySet()) {
            if (lc.procRcdTypeMap.get(i)=='Person Account') {
                lc.procRcdTypeId = i;
                lc.setProcess();
            }
        }
        
        lc.crtAccount = true;
        lc.crtContact = true;
        lc.crtTask = true;
        lc.crtOpportunity = true;
        lc.crtSolutionOpportunity = true;
        lc.crtSalesAppointment = true;
        lc.sndEmail = false;
        lc.solOpp.Solution_Type__c = lead.Solution_Type__c;
        lc.salesAppointment.dealer__Date__c = Date.today();
        lc.salesAppointment.dealer__Time__c = '08:00 AM'; 
        lc.task.ActivityDate = Date.today();
        //lc.sendToArcadium();
        lc.doNotCreateTask = true;	// BLL1a

        lc.convert();

        Test.stopTest();
        th.resumeDupeCatcher();

    }

    @isTest static void testLeadConversion2() {
        TestHelper_MW th = new TestHelper_MW();
        th.suspendDupeCatcher();

        dealer__Dealer_Location__c loc = th.getDealerLocation('1');
        RecordType rt = th.getRetailLeadRt();
        
        Lead lead = new Lead();
        lead.Store_Location__c = loc.Id;
        lead.RecordTypeId = rt.Id;
        lead.FirstName = 'TestLead2';
        lead.LastName = 'Conversion2';
        lead.PostalCode = '90211';
        lead.Phone = '(330) 555-2222';
        lead.Email = 'testlead2.conversion2@example.com';
        lead.State = 'CA';
        lead.Company = 'Testing Conversion2';
        // BLL1 additional info to be passed to Arcadium
        lead.Desired_Vehicles__c = '1234B';
        lead.Vehicle_preference__c = 'Toyota Sienna';
        lead.Rental_pickup_location__c = 'Akron';
        lead.Rental_pick_up__c = Date.today();
        lead.Rental_drop_off__c = Date.today();
        lead.Van_year__c = '2000';
        lead.Van_make__c = 'Toyota';
        lead.Van_model__c = 'Sienaa';
        lead.Van_VIN__c = '123456789ABCDEFGI';
        lead.Currently_own__c = 'n/a';
        lead.Contact_availability__c = 'M-F 8-5';
        lead.Vehicle_information__c = 'My van';
        lead.Van_odometer__c = '153000';
        lead.Nearest_location__c = 'Akron';
        lead.Referral_method__c = 'Friend';
        lead.Visited_a_store__c = 'Yes';
        lead.Solution_Type__c = 'Chassis/Conversion';
        // BLL1 end additional info
		// BLL31
		lead.pi__comments__c = 'Test comment'; 
		lead.Description = 'Test description';
		lead.Email_Lead_Content__c = 'Email lead content test';
		// BLL31 end
        insert lead;
 
        Test.startTest();
         
        PageReference pgRef = Page.LeadConversion; 
        Test.setCurrentPage(pgRef); //Set the page for Test Method
        ApexPages.currentPage().getParameters().put('id', lead.id);
        ApexPages.currentPage().getParameters().put('retURL', '/');
        ApexPages.StandardController leadCtlr = new ApexPages.StandardController(lead);
        //LeadConversion_CTLR lc = new LeadConversion_CTLR();
        LeadConversion_EXT lc = new LeadConversion_EXT(leadCtlr);
        lc.legacyStore = false;
        lc.solOpp.Solution_Type__c = 'Equipment';
        lc.setProcess();
        lc.solOpp.Solution_Type__c = 'Service';
        lc.setProcess();
        lc.solOpp.Solution_Type__c = 'Other/Unknown';
        lc.setProcess();
        lc.solOpp.Solution_Type__c = 'Rental';
        lc.setProcess();
        lc.sendEmailOnly();
        lc.dummyFunction();
        
        List<SelectOption> lu = lc.getLocationUsers();
        lc.markQualified();

        for(Id i : lc.procRcdTypeMap.keySet()) {
            if (lc.procRcdTypeMap.get(i).startsWith('Bus')) {
                lc.procRcdTypeId = i;
                lc.setProcess();
            }
        }
        lc.assignAccount();

		// BLL31
		List<SelectOption> acctopts = lc.acctNameOptions;
		List<SelectOption> contopts = lc.contNameOptions;
		String oppflds = lc.OppFieldsRequired;
		String apptflds = lc.SlsApptFieldsRequired;
		String taskflds = lc.TaskFieldsRequired;
		// BLL31 end

        Test.stopTest();
        th.resumeDupeCatcher();

    }

    @isTest static void testLeadConversion3() {
        TestHelper_MW th = new TestHelper_MW();
        th.suspendDupeCatcher();

        dealer__Dealer_Location__c loc = th.getDealerLocation('1');

        RecordType rt = th.getRetailLeadRt();
        Lead lead = new Lead(
            RecordTypeId = rt.Id, FirstName = 'TestLead3', LastName = 'Conversion3',
            State = 'CA', PostalCode = '90211', Phone = '(330) 555-3333', 
            Email = 'testlead3.conversion3@example.com',
            Company = 'Testing Conversion2',
            Store_Location__c = loc.Id
        );
        insert lead;

        RecordType rt2 = th.getBusinessAccountRt();
        Account a = new Account(Name='TestConvert3 Account3', RecordTypeId=rt2.Id, BillingState='CA');
        insert(a);
		// BLL31
		Contact c = new Contact(AccountId=a.Id, FirstName='Contact', LastName='LastName', Phone='330-555-1213');
		insert(c);
		// BLL31 end
 
        Test.startTest();
         
        PageReference pgRef = Page.LeadConversion; 
        Test.setCurrentPage(pgRef); //Set the page for Test Method
        ApexPages.currentPage().getParameters().put('id', lead.id);
        ApexPages.currentPage().getParameters().put('retURL', '/');
        ApexPages.StandardController leadCtlr = new ApexPages.StandardController(lead);
        //LeadConversion_CTLR lc = new LeadConversion_CTLR();
        LeadConversion_EXT lc = new LeadConversion_EXT(leadCtlr);
        
        lc.contact.AccountId = a.Id;

		// BLL31
		lc.solOpp.dealer__Customer_Account__c = a.Id;
		lc.solOpp.BuyerContact__c = c.Id;
		//List<SelectOption> acctopts = lc.acctNameOptions;
		//List<SelectOption> contopts = lc.contNameOptions;
		// BLL31 end
        lc.assignAccount();
		// BLL31
		lc.assignContact();
		// BLL31 end

        lc.crtAccount = true;
        lc.crtContact = true;
        lc.crtTask = true;
        lc.crtOpportunity = true;
        lc.crtSolutionOpportunity = true;
        lc.crtSalesAppointment = true;
        lc.sndEmail = true;

        lc.solOpp.Name='';
        lc.task.Subject='';
        lc.opportunity.Name='';
        lc.salesAppointment.dealer__Date__c = null;
        lc.salesAppointment.dealer__Time__c = null;
        lc.task.ActivityDate = null;
        lc.subject = '';
        lc.message = '';
        lc.recipients = '';

        boolean rslt = lc.validConversionRequest();
        System.assertEquals(false, rslt, 'Conversion request should have been invalid');

        lc.solOpp.Name='A';
        lc.task.Subject='B';
        lc.opportunity.Name='C';
        boolean rslt2 = lc.validConversionRequest();
        System.assertEquals(false, rslt2, 'Conversion request should have been invalid');

        List<String> sendtonobody = new List<String>(); 
        sendtonobody.add('nobody@example.com');
        lc.sendNotification(sendtonobody, 'Test subject', 'Test message');

        Test.stopTest();
        th.resumeDupeCatcher();

    }

    @isTest static void testLeadConversion4() {
        TestHelper_MW th = new TestHelper_MW();
        th.suspendDupeCatcher();

        dealer__Dealer_Location__c loc = th.getDealerLocation('1');
        RecordType rt = th.getRetailLeadRt();
        Lead lead = new Lead();
        lead.Store_Location__c = loc.Id;
        lead.RecordTypeId = rt.Id;
        lead.FirstName = 'TestLead4';
        lead.LastName = 'Conversion4';
        lead.PostalCode = '90211';
        lead.Phone = '(330) 555-4444';
        lead.Email = 'testlead4.conversion2@example.com';
        lead.State = 'CA';
        lead.Company = 'Testing Conversion2';
        // BLL1 additional info to be passed to Arcadium
        lead.Desired_Vehicles__c = '1234B';
        lead.Solution_Type__c = 'Chassis/Conversion';
        // BLL1 end additional info
        insert lead;

		// BLL2a
        Account ia = th.getInfluencerAccount('1');	
		Map<String, Schema.RecordTypeInfo> IARcdTypes = Schema.SObjectType.InfluencerAssociation2__c.getRecordTypeInfosByName();
		System.debug(IARcdTypes);
		Schema.RecordTypeInfo LeadIaRti = IARcdTypes.get('Lead');
		Id LeadIaRtId = LeadIaRti.getRecordTypeId();
		List<InfluencerAssociation2__c> newialist = new List<InfluencerAssociation2__c>();
		newialist.add(new InfluencerAssociation2__c(
				RecordTypeId=LeadIaRtId, 
				InfluencedLead__c=lead.Id,	// Influenced account
				InfluencerAccount__c=ia.Id	// influencer Account
		));
		insert(newialist);
		// BLL2a end
 
        PageReference pgRef = Page.LeadConversion; 
        Test.setCurrentPage(pgRef); //Set the page for Test Method
        ApexPages.currentPage().getParameters().put('id', lead.id);
        ApexPages.currentPage().getParameters().put('retURL', '/');
        ApexPages.StandardController leadCtlr = new ApexPages.StandardController(lead);
        //LeadConversion_CTLR lc = new LeadConversion_CTLR();
        LeadConversion_EXT lc = new LeadConversion_EXT(leadCtlr);
        lc.legacyStore = false;
        List<SelectOption> lu = lc.getLocationUsers();
        lc.markQualified();
        lc.crtAccount = true;
        lc.crtContact = true;
        lc.crtTask = true;
        lc.crtOpportunity = true;
        lc.crtSolutionOpportunity = true;
        lc.crtSalesAppointment = true;
        lc.sndEmail = false;
        lc.solOpp.Solution_Type__c = lead.Solution_Type__c;
        lc.salesAppointment.dealer__Date__c = Date.today();
        lc.salesAppointment.dealer__Time__c = '08:00 AM'; 
        lc.task.ActivityDate = Date.today();
        // AMM1
        lc.salesAppointment.Appointment_location__c = 'Home';
        // AMM1

        Test.startTest();
        for(Id i : lc.procRcdTypeMap.keySet()) {
            if (lc.procRcdTypeMap.get(i).startsWith('Bus')) {
                lc.procRcdTypeId = i;
                lc.setProcess();
            }
        }
        lc.doNotCreateTask = true;	// BLL1a
        lc.convert();

        // BLL2a
		System.debug([select Id, RecordTypeId, InfluencerAccount__c, InfluencedAccount__c, InfluencedLead__c from InfluencerAssociation2__c]);
        List<InfluencerAssociation2__c> ia2s = [select Id from InfluencerAssociation2__c where InfluencerAccount__c=:ia.Id and InfluencedAccount__c!=null];
        System.assert(ia2s.size()>0, 'Did not get a copy of the lead\'s influencer association');
        // BLL2a

        Test.stopTest();

        th.resumeDupeCatcher();

    }

    @isTest static void testLeadConversion5() {
        TestHelper_MW th = new TestHelper_MW();
        th.suspendDupeCatcher();

        dealer__Dealer_Location__c loc = th.getDealerLocation('1');
        loc.Legacy_Systems__c = true;
        update(loc);
        RecordType rt = th.getRetailLeadRt();
        
        Lead lead = new Lead();
        lead.Store_Location__c = loc.Id;
        lead.RecordTypeId = rt.Id;
        lead.FirstName = 'TestLead5';
        lead.LastName = 'Conversion5';
        lead.PostalCode = '90210';
        lead.Phone = '(330) 555-1115';
        lead.Email = 'testlead.conversion5@example.com';
        lead.State = 'CA';
        lead.Company = 'Testing Conversion';
        // BLL1 additional info to be passed to Arcadium
        lead.Desired_Vehicles__c = '1234B';
        lead.Vehicle_preference__c = 'Toyota Sienna';
        lead.Rental_pickup_location__c = 'Akron';
        lead.Rental_pick_up__c = Date.today();
        lead.Rental_drop_off__c = Date.today();
        lead.Van_year__c = '2000';
        lead.Van_make__c = 'Toyota';
        lead.Van_model__c = 'Sienaa';
        lead.Van_VIN__c = '123456789ABCDEFGH';
        lead.Currently_own__c = 'n/a';
        lead.Contact_availability__c = 'M-F 8-5';
        lead.Vehicle_information__c = 'My van';
        lead.Van_odometer__c = '153000';
        lead.Nearest_location__c = 'Akron';
        lead.Referral_method__c = 'Friend';
        lead.Visited_a_store__c = 'Yes';
        lead.Solution_Type__c = 'Chassis/Conversion';
        // BLL1 end additional info
        insert lead;
 
        Test.startTest();
         
        PageReference pgRef = Page.LeadConversion; 
        Test.setCurrentPage(pgRef); //Set the page for Test Method
        ApexPages.currentPage().getParameters().put('id', lead.id);
        ApexPages.currentPage().getParameters().put('retURL', '/');
        ApexPages.StandardController leadCtlr = new ApexPages.StandardController(lead);
        //LeadConversion_CTLR lc = new LeadConversion_CTLR();
        LeadConversion_EXT lc = new LeadConversion_EXT(leadCtlr);
        
        lc.sendToArcadium();

        Test.stopTest();
        th.resumeDupeCatcher();

    }

	// BLL31
    @isTest static void testLeadConversion6() {
        TestHelper_MW th = new TestHelper_MW();
        th.suspendDupeCatcher();

        dealer__Dealer_Location__c loc = th.getDealerLocation('1');
        loc.Legacy_Systems__c = true;
        update(loc);
        RecordType rt = th.getCommercialLeadRt();
        
        Lead lead = new Lead();
        lead.Store_Location__c = loc.Id;
        lead.RecordTypeId = rt.Id;
        lead.FirstName = 'TestLead6';
        lead.LastName = 'Conversion6';
        lead.PostalCode = '90219';
        lead.Phone = '(330) 555-1116';
        lead.Email = 'testlead.conversion6@example.com';
        lead.State = 'CA';
        lead.Company = 'Testing Conversion';

        lead.Desired_Vehicles__c = '1234B';
        lead.Vehicle_preference__c = 'Toyota Sienna';
        lead.Rental_pickup_location__c = 'Akron';
        lead.Rental_pick_up__c = Date.today();
        lead.Rental_drop_off__c = Date.today();
        lead.Van_year__c = '2000';
        lead.Van_make__c = 'Toyota';
        lead.Van_model__c = 'Sienaa';
        lead.Van_VIN__c = '123456789ABCDEFGH';
        lead.Currently_own__c = 'n/a';
        lead.Contact_availability__c = 'M-F 8-5';
        lead.Vehicle_information__c = 'My van';
        lead.Van_odometer__c = '153000';
        lead.Nearest_location__c = 'Akron';
        lead.Referral_method__c = 'Friend';
        lead.Visited_a_store__c = 'Yes';
        lead.Solution_Type__c = 'Chassis/Conversion';

        insert lead;
 
        Test.startTest();
         
        PageReference pgRef = Page.LeadConversion; 
        Test.setCurrentPage(pgRef); //Set the page for Test Method
        ApexPages.currentPage().getParameters().put('id', lead.id);
        ApexPages.currentPage().getParameters().put('retURL', '/');
        ApexPages.StandardController leadCtlr = new ApexPages.StandardController(lead);
        LeadConversion_EXT lc = new LeadConversion_EXT(leadCtlr);
        
        lc.crtAccount = true;
        lc.crtContact = true;
        lc.crtTask = true;
        lc.crtOpportunity = true;
        lc.crtSolutionOpportunity = true;
        lc.crtSalesAppointment = true;
        lc.sndEmail = false;
        lc.solOpp.Solution_Type__c = lead.Solution_Type__c;
        lc.salesAppointment.dealer__Date__c = Date.today();
        lc.salesAppointment.dealer__Time__c = '08:00 AM'; 
        lc.task.ActivityDate = Date.today();
        lc.doNotCreateTask = true;	// BLL1a
		String emailRqd = lc.EmailFieldsRequired;

        lc.convert();

        Test.stopTest();
        th.resumeDupeCatcher();

    }
	// BLL31 end
}