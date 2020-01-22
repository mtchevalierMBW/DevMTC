/**
 * CQ_EXT_TEST
 * Tests: CQ_EXT
 * 
 *  2015-03-30  B. Leaman	BLL1    Add attachment to test email to increase coverage.
 * 	2016-02-23	B. Leaman	BLL2	Test new routines added for selling commercial vehicle from inventory.
 *	2016-10-04	B. Leaman	BLL3	Adjust test class for new validations (in trigger).
 *	2018-04-30	B. Leaman	BLL4 - new required field on opportunities - Sales_Channel__c.
 * 
 */
@isTest
private class CQ_EXT_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	private static void setupTestData() {
		TestHelper_MW.createBaseFFAData(FFAdata);
	}
	
    static testmethod void testGeneralMethods() {
        
        Account a = new Account(Name='ABC Motors', BillingState='CA', Phone='5309909');
        insert a;

        Opportunity o = new Opportunity(Name='ABC Motors-', AccountId=a.Id, StageName='Closed', CloseDate=Date.Today());
        o.Sales_Channel__c = 'MBW N/A';	// BLL4a
        insert o;

        // Get Record Types for CommercialQuoteOptions
        List<RecordType> recordTypes = [SELECT Id, SobjectType, IsActive, Description, DeveloperName, NamespacePrefix, Name FROM RecordType where SobjectType = 'Commercial_Quote_Options__c' and DeveloperName = 'Wheelbase_Options'];
        Commercial_Quote_Options__c cqoptions = new Commercial_Quote_Options__c(
            RecordTypeId=recordTypes[0].Id,
            Name='Long Wheelbase Option',
            Cost__c=9999
            // , TransitWorks_Cost__c=9999  // Removed 2015-03-24 BLL
        );
        insert cqoptions;

        CommercialQuote__c cq = new CommercialQuote__c(
            Salesperson__c = UserInfo.getUserId(),
            Opportunity__c = o.Id
        );
        insert cq;

        CommercialQuoteLine__c line = new CommercialQuoteLine__c(
            Commercial_Quote__c = cq.Id,
            Commercial_Quote_Options__c = cqoptions.Id,
            Quantity__c = 1,
            Description__c = 'Test',
            Cost__c = 999,
            Selling_Price__c = 2000
        );
        insert line;

        ApexPages.StandardController sc = new ApexPages.StandardController(cq);
        CQ_EXT q = new CQ_EXT(sc);

        // Generate from an Opp
        q.startQuoteFromOpp(o.Id);

        // Getters
        CommercialQuoteLine__c[] wheelbaseitems =   q.getWheelBaseSelectedItems();
        CommercialQuoteLine__c[] longWheelbase  =   q.getLongWheelBaseSelectedItems();
        CommercialQuoteLine__c[] addSeats       =   q.getAdditionalSeatingItems();
        CommercialQuoteLine__c[] addFabric      =   q.getFabricItems();
        CommercialQuoteLine__c[] wheelchairR    =   q.getWheelChairRestraints();
        CommercialQuoteLine__c[] interiorOptions=   q.getInteriorOptions();
        CommercialQuoteLine__c[] stantionPoles  =   q.getStantItems();
        CommercialQuoteLine__c[] extItems       =   q.getExtItems();
        CommercialQuoteLine__c[] chairStorage   =   q.getChairStorageItems();
        CommercialQuoteLine__c[] safetyItems    =   q.getSafetyItems();
        CommercialQuoteLine__c[] miscItems      =   q.getMiscItems();
        CommercialQuoteLine__c[] allItems       =   q.getAllItems();

        Commercial_Quote_Options__c[] modalTable    =   q.getModalTable();
        Commercial_Quote_Options__c[] loadOptions   =   q.getQuoteOptions();
        q.getMultiselectModalTable(); // ignore results
        q.save(); 
        
        // PageReference
        q.addOptionToQuote();  // Test without the optionId
        q.optionId = loadOptions[0].Id;
        q.addOptionToQuote();

        q.removeItem(); // Test without an optionId to Remove
        q.itemToRemove = wheelbaseitems[0].Id;
        q.removeItem();

        q.saveCommercialQuote();
        q.printPDF();
        q.doNothing();

        q.addOtherOption(); // Test Blank
        q.otherQTY = 1;
        q.otherName= 'Test Item';
        q.otherPrice=500;
        q.otherCost =100;
        q.addOtherOption();

        Opportunity opp = q.getOpportunity();

        // Clone Test
        q.cloneQuote();


        q.emailPDF();

        // Messaging Methods
        q.toAddress = 'jarrett@dealerteam.com';
        q.subject   = 'subject';
        q.body      = 'To the customer message';
        // BLL1a start: Add attachment 
        q.aBody = blob.valueOf('Test attachment text');
        q.aContentType = 'text/plain';
        q.aFileName = 'attach.txt';
        q.addAttachment();
        // BLL1a end: Add attachment
        q.emailPDFDirect();

        q.placeOrder();


    }

    static testmethod void testRemotes() {

        Account a = new Account(Name='ABC Motors', BillingState='CA', Phone='5309909');
        insert a;

        Opportunity o = new Opportunity(Name='ABC Motors-', AccountId=a.Id, StageName='Closed', CloseDate=Date.Today());
        o.Sales_Channel__c = 'MBW N/A';	// BLL4a
        insert o;

        // Get Record Types for CommercialQuoteOptions
        List<RecordType> recordTypes = [SELECT Id, SobjectType, IsActive, Description, DeveloperName, NamespacePrefix, Name FROM RecordType where SobjectType = 'Commercial_Quote_Options__c' and DeveloperName = 'Wheelbase_Options'];
        Commercial_Quote_Options__c cqoptions = new Commercial_Quote_Options__c(
            RecordTypeId=recordTypes[0].Id,
            Name='Long Wheelbase Option',
            Cost__c=9999
            // ,TransitWorks_Cost__c=9999 // Removed 2015-03-24 BLL
        );
        insert cqoptions;



        CommercialQuote__c cq = new CommercialQuote__c(
            Salesperson__c = UserInfo.getUserId(),
            Opportunity__c = o.Id
        );
        insert cq;

        CommercialQuoteLine__c line = new CommercialQuoteLine__c(
            Commercial_Quote__c = cq.Id,
            Commercial_Quote_Options__c = cqoptions.Id,
            Quantity__c = 1,
            Description__c = 'Test',
            Cost__c = 999,
            Selling_Price__c = 2000
        );
        insert line;

        ApexPages.StandardController sc = new ApexPages.StandardController(cq);
        CQ_EXT q = new CQ_EXT(sc);
        q.getChassisOptions();
        q.getquoteAuthor();
        q.getreferenceAttachments();
        q.addOptionsToQuote();
        q.doRecap();
        
        // Remotes returning an object
        Account b = CQ_EXT.lookupCustomerRecord(a.Id);

        Commercial_Quote_Options__c cqoResult = CQ_EXT.lookupOption(cqoptions.Id);

        CQ_EXT.setLineDetails(line.Id+'~2~100');
        CQ_EXT.recapTotals(cq.Id);
        //CQ_EXT.setFreight('OH');
        CQ_EXT.saveField(cq.Id+'~State__c~CA');
        CQ_EXT.clearSelectedOptions(cq.Id);
    }
    
    // Test results when quote is marked 'Won'
    static testmethod void TestQuoteWonTrigger() {
        // setup data
        Account acc = new Account(Name='TEST CQ Acc', BillingState='OH', BillingPostalCode='44641');
        //acc.RecordTypeId =[Select Id, SobjectType, Name 
        //                   From RecordType 
        //                   Where Name ='Person Account' and SobjectType ='Account'  
        //                   limit 1].Id;
        insert acc;
        Opportunity opp = new Opportunity(Name='TEST CQ Opp',StageName='Pending',CloseDate=system.today());
        opp.Sales_Channel__c = 'MBW N/A';	// BLL4a
        opp.AccountId = acc.Id;
        insert opp;
        //System.debug('Test opportunity id='+opp.Id);
        
        CommercialQuote__c cq = new CommercialQuote__c(Status__c='Pending',
                                    Contact__c='TEST CQ Contact', Email_Address__c='test@example.com');
        cq.Opportunity__c = opp.Id;
        insert cq;
        //System.debug('Test quote id=' + cq.Id);
        
        Test.startTest();
        // Update the commercial quote to Won
        cq.Status__c = 'Won';
        cq.New_Customer__c = 'No';	// BLL3a
        cq.Market_Segment__c = 'TestSegment';	// BLL3a
        update cq;
        Test.stopTest();
        
        // Get opportunity and ensure it is now won
        List<Opportunity> opps = [select Id, Name, StageName 
                            from Opportunity
                            where Id=:opp.Id];
        System.assert(opps.size()==1);
        System.assertEquals('Won', opps[0].StageName);
    }
    
    // BLL2a
    static testmethod void AddCommercialVehicle() {
		FFAdata.refresh();
		System.runAs(FFAdata.TestUser) {
	        Account a = new Account(Name='ABC Motors', BillingState='CA', Phone='5309909');
	        insert a;
	        Opportunity o = new Opportunity(Name='ABC Motors-', AccountId=a.Id, StageName='Closed', CloseDate=Date.Today());
        	o.Sales_Channel__c = 'MBW N/A';	// BLL4a
	        insert o;
	
	        String CQOptionRecordType='Chassis Options';
	        Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.Commercial_Quote_Options__c.getRecordTypeInfosByName();
	        
	        // create a commercial quote option
	        Commercial_Quote_Options__c cqopt = new Commercial_Quote_Options__c(
	            RecordTypeId=RcdTypes.get(CQOptionRecordType).getRecordTypeId(), 
	            Name='TestOption', Active__c=true, 
	            Vehicle_Manufacturer__c='Ford', Wheelbase__c='Regular', 
	            Description__c='Test option description',
	            Cost__c=100.00, Freight__c=0.00, Selling_Price__c=140.00,
	            Internal_Note__c='No note'
	        );
	        insert(cqopt);
	        
	        // create vehicle 
	        dealer__Vehicle_Inventory__c veh = new dealer__Vehicle_Inventory__c(
	            Name='(TESTX) 2020 Toyota Future',
	            New_Used_Other__c='Used', Division__c='Commercial', 
	            dealer__Stock_Number__c='TESTX',
	            dealer__VIN__c='Z1234567890TUVWXY',
	            dealer__Year__c='2020', dealer__Make__c='Toyota', dealer__Model__c='Future',
	            dealer__Mileage__c=123000,
	            dealer__Store_Location__c=FFAdata.DealerLocation.Id, dealer__Company_Number__c=FFAdata.DealerLocation.dealer__Company_Number__c
	        );
	        insert(veh);
	
	        // Create a vehicle commercial option
	        VehicleInventory_CommercialOption__c obj = new VehicleInventory_CommercialOption__c(
	            VehicleInventory__c=veh.Id, CommercialQuoteOption__c=cqopt.Id, Quantity__c=1,
	            OptionType__c=CQOptionRecordType,  
	            Cost__c=cqopt.Cost__c, SellingPrice__c=cqopt.Selling_Price__c,
	            Notes__c=cqopt.Internal_Note__c
	        );
	        insert(obj);
	
			Test.startTest();
			CommercialQuote__c cq = new CommercialQuote__c(
				Salesperson__c = UserInfo.getUserId(),
				Opportunity__c = o.Id
			);
			insert(cq);

			PageReference pgRef = Page.CQ2; 
			Test.setCurrentPage(pgRef); //Set the page for Test Method

	        ApexPages.StandardController sc = new ApexPages.StandardController(cq);
	        CQ_EXT q = new CQ_EXT(sc);
			List<Commercial_Quote_Options__c> cl = q.getChassisList();
			q.addCommercialVehicle(veh.id);
			
			CQ_EXT.QuoteWrapper wrapper = new CQ_EXT.QuoteWrapper(q.quoteInstance, q.newTask);	// BLL7c add newTask 
            String quoteJSON = JSON.serialize(wrapper);
            Cookie quoteCookie = new Cookie('quote', quoteJSON, null, -1, false);
            ApexPages.currentPage().setCookies(new Cookie[]{quoteCookie});
            q.getQuoteFromCookie(q.quoteInstance, q.newTask);
			q.rmvCommercialVehicle();
			
			Test.stopTest();
			
		}
	    	
    }
    // BLL2a end
    
}