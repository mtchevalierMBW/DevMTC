/**
 * JournalManager_TC2
 * Tests: JournalManager
 * Date: Apr 14, 2016
 * Programmer: Bryan Leaman
 *
 *	2016-06-07	B. Leaman	BLL1 - don't run vehicle transfer triggers - causing too many SOQL during test
 * 	2016-06-20	B. Leaman	BLL2 - fewer DMLs, reduce SOQLs.
 *	2017-07-02	B. Leaman	BLL3 - add LineType__c to entry rules.
 *	2018-04-30	B. Leaman	BLL4 - new required field on opportunities (Sales_Channel__c)
 *	2019-09-24	B. Leaman	BLL5 - new DT 5 requirements (and too manu soql queries)
 */
@isTest
private class JournalManager_TC2 {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);

		// BLL5
		dealer.TestClassUtil tc = new dealer.TestClassUtil();
		tc.insertDMSSettings();
		// BLL5 end

		// Setup posting template
		PostingTemplate__c pt = new PostingTemplate__c(
			Name='Commercial Quote Sale', Active__c=true,
			Object_Name__c='Commercial Quote'
		);
		insert(pt);
		
		// Simple posting template rules that will balance out
		List<PostingTemplateEntryRule__c> rules = new List<PostingTemplateEntryRule__c>();	// BLL2a
		rules.add(new PostingTemplateEntryRule__c(
			Action__c='Chassis Sale', FieldName__c='Chassis_Price__c',
			Posting_Template__c=pt.Id, 
			LineType__c='General Ledger Account', ReverseValue__c=false,  
			General_Ledger_Account__c=FFAdata.GLAMap.get('accountsReceivableControl').Id
		));
		//insert(rule1);
		rules.add(new PostingTemplateEntryRule__c(
			Action__c='Chassis Sale', FieldName__c='Chassis_Price__c',
			Posting_Template__c=pt.Id, 
			LineType__c='General Ledger Account', ReverseValue__c=true, 
			General_Ledger_Account__c=FFAdata.GLAMap.get('accountsReceivableControl').Id
		));
		//insert(rule2);
		rules.add(new PostingTemplateEntryRule__c(
			Action__c='Conversion Cost', FieldName__c=null,
			Posting_Template__c=pt.Id, 
			LineType__c='General Ledger Account', ReverseValue__c=false,  
			General_Ledger_Account__c=FFAdata.GLAMap.get('cogs').Id
		));
		//insert(rule3);
		rules.add(new PostingTemplateEntryRule__c(
			Action__c='Conversion Cost', FieldName__c=null,
			Posting_Template__c=pt.Id, 
			LineType__c='General Ledger Account', ReverseValue__c=true, 
			General_Ledger_Account__c=FFAdata.GLAMap.get('cogs').Id
		));
		//insert(rule4);

		rules.add(new PostingTemplateEntryRule__c(
			Action__c='Account Receivable',
			Posting_Template__c=pt.id,
			LineType__c='General Ledger Account', ReverseValue__c=false,
			General_Ledger_Account__c=FFAdata.GLAMap.get('cogs').Id
		));		
		rules.add(new PostingTemplateEntryRule__c(
			Action__c='Account Receivable',
			Posting_Template__c=pt.id,
			LineType__c='General Ledger Account', ReverseValue__c=true,
			General_Ledger_Account__c=FFAdata.GLAMap.get('cogs').Id
		));		

		rules.add(new PostingTemplateEntryRule__c(
			Action__c='3rd Party/Government Receivable',
			Posting_Template__c=pt.id,
			LineType__c='General Ledger Account', ReverseValue__c=false,
			General_Ledger_Account__c=FFAdata.GLAMap.get('cogs').Id
		));		
		rules.add(new PostingTemplateEntryRule__c(
			Action__c='3rd Party/Government Receivable',
			Posting_Template__c=pt.id,
			LineType__c='General Ledger Account', ReverseValue__c=true,
			General_Ledger_Account__c=FFAdata.GLAMap.get('cogs').Id
		));		

		rules.add(new PostingTemplateEntryRule__c(
			Action__c='Third Party 1',
			Posting_Template__c=pt.id,
			LineType__c='General Ledger Account', ReverseValue__c=false,
			General_Ledger_Account__c=FFAdata.GLAMap.get('cogs').Id
		));		
		rules.add(new PostingTemplateEntryRule__c(
			Action__c='Third Party 1',
			Posting_Template__c=pt.id,
			LineType__c='General Ledger Account', ReverseValue__c=true,
			General_Ledger_Account__c=FFAdata.GLAMap.get('cogs').Id
		));		

		rules.add(new PostingTemplateEntryRule__c(
			Action__c='Third Party 2',
			Posting_Template__c=pt.id,
			LineType__c='General Ledger Account', ReverseValue__c=false,
			General_Ledger_Account__c=FFAdata.GLAMap.get('cogs').Id
		));		
		rules.add(new PostingTemplateEntryRule__c(
			Action__c='Third Party 2',
			Posting_Template__c=pt.id,
			LineType__c='General Ledger Account', ReverseValue__c=true,
			General_Ledger_Account__c=FFAdata.GLAMap.get('cogs').Id
		));		
		insert(rules);	// BLL2a

		// BLL1a
		// Don't run these triggers: getting too many SOQL during tests and they
		// have their own test methods
		List<MW_TriggerControls__c> triggerControls = new List<MW_TriggerControls__c>();
		triggerControls.add(new MW_TriggerControls__c(Name='DealerTradeIntegrity', Enabled__c=false)); 
		triggerControls.add(new MW_TriggerControls__c(Name='DealerTradeStatusChange', Enabled__c=false));
		insert(triggerControls);
		// BLL1a end 
		
	}

	// commercialQuote
	//---------------------------------------
	static testMethod void commercialQuote() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();

	        Account a = th.getBusinessAccount('1');
			Contact c = new Contact(FirstName='Be a', LastName='Tester', Phone='(234) 555-1219', AccountId=a.Id);
			insert c;	        
	
	        Opportunity o = new Opportunity(Name='ABC Motors-', AccountId=a.Id, StageName='Closed', CloseDate=Date.Today());
	        o.Sales_Channel__c = 'MBW N/A';	// BLL4a
	        insert o;
	
	        // Get Record Types for CommercialQuoteOptions
			Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.Commercial_Quote_Options__c.getRecordTypeInfosByName();
	        Commercial_Quote_Options__c cqoptions = new Commercial_Quote_Options__c(
	            RecordTypeId = RcdTypes.get('Wheelbase Options').getRecordTypeId(),
	            Name = 'Long Wheelbase Option',
	            Cost__c = 9999
	        );
	        insert cqoptions;
	
	        CommercialQuote__c cq = new CommercialQuote__c(
	            Salesperson__c = UserInfo.getUserId(),
	            Opportunity__c = o.Id,
	            Chassis_Cost__c = 10000, Chassis_Price__c = 10000,
	            Location__c = FFAdata.DealerLocation.Id
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
			
			PostingTemplate__c pt = [select Id from PostingTemplate__c where Name='Commercial Quote Sale'];
			
			// Posting entry
			Posting_Entry__c pe = new Posting_Entry__c(
				Location__c=FFAdata.DealerLocation.Id,
				Posting_Template__c = pt.Id,
				CommercialQuote__c = cq.Id
			);
			insert pe;
			
			// Actual Test
			Test.startTest();
			ApexPages.StandardController sc = new ApexPages.StandardController(pe);
			ApexPages.currentPage().getParameters().put('id', pe.id);
			JournalManager  jm = new JournalManager(new ApexPages.StandardController(pe));
			jm.lookupTemplateRules();
			jm.tBalance=0;
			jm.createJournal();
			Test.stopTest();
			
		}
	}

	static testMethod void proposal() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
        TestHelper_MW th = new TestHelper_MW();
        //UtilityTestData_AC ut=new UtilityTestData_AC();
        Account a = th.getPersonAccount('1');

		//  Map<String,c2g__codaGeneralLedgerAccount__c> GLAMap = FFATests.createGLAccounts();
		c2g__codaGeneralLedgerAccount__c gla = new c2g__codaGeneralLedgerAccount__c();
             gla.c2g__ReportingCode__c ='12';
             gla.c2g__Type__c='Manual Journal';
             gla.Name='Test';
             insert gla; 
      
		// Generate the DealerTeam data for the Journal 
		//PostingTemplate__c  pt      = th.getPostingTemplate();
        dealer__Sales_Up__c salesup = th.getSalesUp(a.Id);
		// dealer__Deal__c     deal    = th.getDealBasic(salesup.Id, loc.Id, a.Id);
		//dealer__Deal__c     deal = ut.getDealBasic(salesup.Id,FFAdata.DealerLocation.Id,a.Id);

        dealer__Deal__c deal = new dealer__Deal__c(
        	dealer__Deal_ID__c = '000000000000001',
        	dealer__Buyer__c = a.Id,
        	dealer__Sales_Lead__c = salesup.Id,
        	dealer__Store_Location__c = FFAdata.DealerLocation.Id,
        	dealer__Licence__c = '100',
        	Name = '12342',
	    	Commission__c =12.5,
	    	Commission_2__c=53.2,
	    	Commission_3__c=45.2,
	    	Commission_4__c=77.25,
	    	Flat__c=10.0,
	    	Commission_FI_1__c=44,
	    	Commission_FI_2__c=11.0,
	    	Commission_FI_3__c=12.0,
	    	Commission_FI_4__c=24.0,
	    	Commission_Flat_2__c=31.0,
	    	Commission_Flat_3__c=9.20,
	    	Commission_Flat_4__c=13.02
        );
        insert deal;

        dealer__Vehicle_Inventory__c vehicle = th.getVehicleInventory('1');

		dealer__Trade_In__c dti = new dealer__Trade_In__c();
		dti.dealer__Odometer_at_Trade_In__c=11;
		dti.Name='Test';
		dti.Sale_Type__c='Used';
		dti.dealer__Pay_Off_Amount__c=1;
		dti.dealer__Trade_Allowance__c=11;
		dti.dealer__Car_Deal__c=deal.Id;
		dti.Chassis_Allowance__c=11;
		dti.dealer__ACV__c=11;
		dti.dealer__VIN__c='Test';
		dti.dealer__Stock_Number__c='0123';
		insert dti;
  
        // Generate the Journal data
		//c2g__codaJournal__c cj = new c2g__codaJournal__c();
        //   cj.c2g__JournalDate__c =system.Today();
        //   cj.c2g__Type__c='Manual Journal';
        //   cj.c2g__OwnerCompany__c = FFAdata.CurrentCompany.Id;
        //   cj.c2g__Type__c='Manual Journal';
        //   cj.c2g__JournalCurrency__c = HomeCurrency.Id;
        //   cj.c2g__Period__c= CurrentPeriod.Id;   
        //   insert cj;

        // Line data
        //c2g__codaJournalLineItem__c ccj = new c2g__codaJournalLineItem__c();
        //    ccj.c2g__Journal__c =cj.id;
        //    ccj.c2g__LineType__c='General Ledger Account';
        //    ccj.c2g__GeneralLedgerAccount__c = gla.Id;
        //    ccj.c2g__Value__c =12; 
        //    ccj.c2g__Dimension1__c = FFAdata.Dimension1.Id;             
        //    insert ccj; 


		// Posting template
		PostingTemplate__c pt = new PostingTemplate__c(
			Name='Proposal Sale', Active__c=true,
			Object_Name__c='Proposal'
		);
		insert(pt);
		
        // Posting Template Entry
        List<PostingTemplateEntryRule__c> rules = new List<PostingTemplateEntryRule__c>();	// BLL2a
		rules.add(new PostingTemplateEntryRule__c(
            Posting_Template__c=pt.id,
            Action__c='Sales Tax Payable',
            General_Ledger_Account__c=gla.Id,
            Default_Memo__c='Tax',
            LineType__c='General Ledger Account',	// BLL3a
            Page_Order__c=12));
            //insert pte;
        PostingTemplateEntryRule__c pte = rules[0];	// BLL2a - just need one rule reference later on
		rules.add(new PostingTemplateEntryRule__c(
        	Posting_Template__c=pt.Id,
        	Action__c='Trade-in',
        	General_Ledger_Account__c=gla.Id,
            LineType__c='General Ledger Account',	// BLL3a
        	Default_Memo__c=''
        ));
		rules.add(new PostingTemplateEntryRule__c(
        	Posting_Template__c=pt.Id,
        	Action__c='Account Receivable',
        	General_Ledger_Account__c=gla.Id,
            LineType__c='Account - Customer',	// BLL3a
        	Default_Memo__c=''
        ));

		rules.add(new PostingTemplateEntryRule__c(
        	Posting_Template__c=pt.Id,
        	Action__c='Extended Warranty - Sales',
        	General_Ledger_Account__c=gla.Id,
            LineType__c='General Ledger Account',	// BLL3a
        	Default_Memo__c=''
        ));
		rules.add(new PostingTemplateEntryRule__c(
        	Posting_Template__c=pt.Id,
        	Action__c='Extended Warranty - COGS',
        	General_Ledger_Account__c=gla.Id,
            LineType__c='General Ledger Account',	// BLL3a
        	Default_Memo__c=''
        ));
		rules.add(new PostingTemplateEntryRule__c(
        	Posting_Template__c=pt.Id,
        	Action__c='Extended Warranty - Payable',
        	General_Ledger_Account__c=gla.Id,
            LineType__c='General Ledger Account',	// BLL3a
        	Default_Memo__c=''
        ));

		rules.add(new PostingTemplateEntryRule__c(
        	Posting_Template__c=pt.Id,
        	Action__c='GAP Insurance - Sales',
        	General_Ledger_Account__c=gla.Id,
            LineType__c='General Ledger Account',	// BLL3a
        	Default_Memo__c=''
        ));
		rules.add(new PostingTemplateEntryRule__c(
        	Posting_Template__c=pt.Id,
        	Action__c='GAP Insurance - COGS',
        	General_Ledger_Account__c=gla.Id,
            LineType__c='General Ledger Account',	// BLL3a
        	Default_Memo__c=''
        ));
		rules.add(new PostingTemplateEntryRule__c(
        	Posting_Template__c=pt.Id,
        	Action__c='GAP Insurance - Payable',
        	General_Ledger_Account__c=gla.Id,
            LineType__c='General Ledger Account',	// BLL3a
        	Default_Memo__c=''
        ));

//'GAP Insurance'
//'Roadside Assistance'
//'Diamond Fusion'            

		rules.add(new PostingTemplateEntryRule__c(
        	Posting_Template__c=pt.Id,
        	Action__c='Conversion Sales',
        	General_Ledger_Account__c=gla.Id,
            LineType__c='General Ledger Account',	// BLL3a
        	Default_Memo__c=''
        ));
		rules.add(new PostingTemplateEntryRule__c(
        	Posting_Template__c=pt.Id,
        	Action__c='Conversion Inventory',
        	General_Ledger_Account__c=gla.Id,
            LineType__c='General Ledger Account',	// BLL3a
        	Default_Memo__c=''
        ));
		rules.add(new PostingTemplateEntryRule__c(
        	Posting_Template__c=pt.Id,
        	Action__c='Additional Equipment Sales',
        	General_Ledger_Account__c=gla.Id,
            LineType__c='General Ledger Account',	// BLL3a
        	Default_Memo__c=''
        ));
		rules.add(new PostingTemplateEntryRule__c(
        	Posting_Template__c=pt.Id,
        	Action__c='Additional Equipment Cost',
        	General_Ledger_Account__c=gla.Id,
            LineType__c='General Ledger Account',	// BLL3a
        	Default_Memo__c=''
        ));
		rules.add(new PostingTemplateEntryRule__c(
        	Posting_Template__c=pt.Id,
        	Action__c='Additional Equipment Inventory',
        	General_Ledger_Account__c=gla.Id,
            LineType__c='General Ledger Account',	// BLL3a
        	Default_Memo__c=''
        ));
        insert(rules);

        Posting_Entry__c pe = new Posting_Entry__c();
            pe.Location__c=FFAdata.DealerLocation.Id;          
            pe.Posting_Template__c=pt.Id;
            pe.Proposal__c=deal.Id;
            pe.Stock__c=vehicle.Id;
            insert pe;

		dealer__Service_Contract__c sc2= new dealer__Service_Contract__c();
            sc2.dealer__Deductable__c=0.00;
            sc2.Type__c='GAP';
            sc2.dealer__Car_Deal__c =deal.id;
            insert sc2;
            //sc2.Type__c='Service Contract';
            //Update Sc2;
             
            PostingTemplate__c po= new PostingTemplate__c();
            po.Name='poname';
            po.Object_Name__c='Proposal';
            insert po; 
            
            PostingTemplateEntryRule__c ptr= new PostingTemplateEntryRule__c();
            ptr.FieldName__c='filed';
            ptr.Posting_Template__c=po.id;
            ptr.Action__c='Commission Accrual';
            insert ptr;
         
      
			List<dealer__Service_Contract__c> protectionProd =new List<dealer__Service_Contract__c>();
			protectionProd.add(sc2);
            
        // Actual Test
		Test.startTest();

            ApexPages.StandardController sc = new ApexPages.StandardController(pe);
            ApexPages.currentPage().getParameters().put('id', pe.id);
            JournalManager  jm = new JournalManager(new ApexPages.StandardController(pe));
            jm.lookupTemplateRules();
            jm.entry.Posting_Template__c=pt.id;
            jm.lookupTemplateRules();
            jm.entry.Posting_Template__c=Null;
            jm.lookupTemplateRules();
            jm.entryId ='Test';
            jm.dim ='Test';
            jm.getLines();
            jm.loadProposalData();
            jm.proposal.dealer__Store_Location__c=FFAdata.DealerLocation.Id;
            jm.loadProposalData();
            jm.proposal.dealer__Store_Location__c=Null;
            jm.loadProposalData();
			jm.tBalance=1;	// BLL5a
            jm.createJournal();
            //jm.tBalance =1;
            //jm.createJournal();
            jm.tBalance = 0;
            //BLL5d jm.createJournal();

            // JVK2
            jm.credit(22.20);
            jm.credit(null);
            jm.debit(22.20);
            jm.debit(null);
            jm.nonNull(20.12);  
            jm.nonNull(null);
            // End JVK2

            JournalManager.lines jml = new JournalManager.lines();
            jml.amount  = 12.12;
            jml.action ='Account Receivable';
            jml.memo ='Test';
            jml.accountName  ='Test';
            //BLL2d jml.division ='12345';
            jml.jline.c2g__Dimension1__c = FFAdata.Dimension1.Id;	// BLL2a
            jml.StockNbr='Test';
            jml.VIN='Test';
            jml.Description='Description';
            jm.calcLines();  // BLL1a
            jm.createJournal(); // BLL1a
			jm.actionTotal('S');
            // BLL2d getting too many soqls, skip this for now: jm.save(); // JVK2

            //List<PostingTemplateEntryRule__c> rules = [
            //	Select Id, Name, Action__c, General_Ledger_Account__c, General_Ledger_Account__r.Name, Default_Memo__c 
            //    from PostingTemplateEntryRule__c
            //    where Posting_Template__c=:pt.Id limit 1];
            //List<c2g__codaGeneralLedgerAccount__c> gl = [
            //	Select Id, Name 
            //	from c2g__codaGeneralLedgerAccount__c 
            //	where Id=:gla.Id limit 1];
            //jm.processCommissions(rules[0], gl[0]);
            jm.processCommissions(pte, gla);
            
            List<PostingTemplateEntryRule__c> protrules = [
            	Select Id, Name, Action__c, General_Ledger_Account__c, General_Ledger_Account__r.Name, Default_Memo__c, LineType__c	// BLL3c 
                from PostingTemplateEntryRule__c
                where Posting_Template__c=:pt.Id and Action__c like '%GAP%'
            ];
			for(PostingTemplateEntryRule__c pter : protrules) {
				jm.processProtection(protectionProd,pter,protectionProd[0].Type__c,gla);
			}
         
            dealer__Dealer_Trade__c trade= new dealer__Dealer_Trade__c();
            trade.dealer__Salesperson__c=Userinfo.getUserID();
            insert trade;

			Test.stopTest();                

        }

	}

	static testMethod void proposal2() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
        TestHelper_MW th = new TestHelper_MW();
        //UtilityTestData_AC ut=new UtilityTestData_AC();
        Account a = th.getPersonAccount('1');

		//  Map<String,c2g__codaGeneralLedgerAccount__c> GLAMap = FFATests.createGLAccounts();
		c2g__codaGeneralLedgerAccount__c gla = new c2g__codaGeneralLedgerAccount__c();
             gla.c2g__ReportingCode__c ='12';
             gla.c2g__Type__c='Manual Journal';
             gla.Name='Test';
             insert gla; 
      
		// Generate the DealerTeam data for the Journal 
		//PostingTemplate__c  pt      = th.getPostingTemplate();
        dealer__Sales_Up__c salesup = th.getSalesUp(a.Id);
		// dealer__Deal__c     deal    = th.getDealBasic(salesup.Id, loc.Id, a.Id);
		//dealer__Deal__c     deal = ut.getDealBasic(salesup.Id,FFAdata.DealerLocation.Id,a.Id);

        dealer__Deal__c deal = new dealer__Deal__c(
        	dealer__Deal_ID__c = '000000000000001',
        	dealer__Buyer__c = a.Id,
        	dealer__Sales_Lead__c = salesup.Id,
        	dealer__Store_Location__c = FFAdata.DealerLocation.Id,
        	dealer__Licence__c = '100',
        	Name = '12342',
	    	Commission__c =12.5,
	    	Commission_2__c=53.2,
	    	Commission_3__c=45.2,
	    	Commission_4__c=77.25,
	    	Flat__c=10.0,
	    	Commission_FI_1__c=44,
	    	Commission_FI_2__c=11.0,
	    	Commission_FI_3__c=12.0,
	    	Commission_FI_4__c=24.0,
	    	Commission_Flat_2__c=31.0,
	    	Commission_Flat_3__c=9.20,
	    	Commission_Flat_4__c=13.02
        );
        insert deal;

        dealer__Vehicle_Inventory__c vehicle = th.getVehicleInventory('1');

		dealer__Trade_In__c dti = new dealer__Trade_In__c();
		dti.dealer__Odometer_at_Trade_In__c=11;
		dti.Name='Test';
		dti.Sale_Type__c='Used';
		dti.dealer__Pay_Off_Amount__c=1;
		dti.dealer__Trade_Allowance__c=11;
		dti.dealer__Car_Deal__c=deal.Id;
		dti.Chassis_Allowance__c=11;
		dti.dealer__ACV__c=11;
		dti.dealer__VIN__c='Test';
		dti.dealer__Stock_Number__c='0123';
		insert dti;
  
        // Generate the Journal data
		//c2g__codaJournal__c cj = new c2g__codaJournal__c();
        //   cj.c2g__JournalDate__c =system.Today();
        //   cj.c2g__Type__c='Manual Journal';
        //   cj.c2g__OwnerCompany__c = FFAdata.CurrentCompany.Id;
        //   cj.c2g__Type__c='Manual Journal';
        //   cj.c2g__JournalCurrency__c = HomeCurrency.Id;
        //   cj.c2g__Period__c= CurrentPeriod.Id;   
        //   insert cj;

        // Line data
        //c2g__codaJournalLineItem__c ccj = new c2g__codaJournalLineItem__c();
        //    ccj.c2g__Journal__c =cj.id;
        //    ccj.c2g__LineType__c='General Ledger Account';
        //    ccj.c2g__GeneralLedgerAccount__c = gla.Id;
        //    ccj.c2g__Value__c =12; 
        //    ccj.c2g__Dimension1__c = FFAdata.Dimension1.Id;             
        //    insert ccj; 


		// Posting template
		PostingTemplate__c pt = new PostingTemplate__c(
			Name='Proposal Sale', Active__c=true,
			Object_Name__c='Proposal'
		);
		insert(pt);
		
        // Posting Template Entry
        List<PostingTemplateEntryRule__c> rules = new List<PostingTemplateEntryRule__c>();	// BLL2a
		rules.add(new PostingTemplateEntryRule__c(
            Posting_Template__c=pt.id,
            Action__c='Sales Tax Payable',
            General_Ledger_Account__c=gla.Id,
            Default_Memo__c='Tax',
            LineType__c='General Ledger Account',	// BLL3a
            Page_Order__c=12));
            //insert pte;
        PostingTemplateEntryRule__c pte = rules[0];	// BLL2a - just need one rule reference later on
		rules.add(new PostingTemplateEntryRule__c(
        	Posting_Template__c=pt.Id,
        	Action__c='Trade-in',
        	General_Ledger_Account__c=gla.Id,
            LineType__c='General Ledger Account',	// BLL3a
        	Default_Memo__c=''
        ));
		rules.add(new PostingTemplateEntryRule__c(
        	Posting_Template__c=pt.Id,
        	Action__c='Account Receivable',
        	General_Ledger_Account__c=gla.Id,
            LineType__c='Account - Customer',	// BLL3a
        	Default_Memo__c=''
        ));

		rules.add(new PostingTemplateEntryRule__c(
        	Posting_Template__c=pt.Id,
        	Action__c='Extended Warranty - Sales',
        	General_Ledger_Account__c=gla.Id,
            LineType__c='General Ledger Account',	// BLL3a
        	Default_Memo__c=''
        ));
		rules.add(new PostingTemplateEntryRule__c(
        	Posting_Template__c=pt.Id,
        	Action__c='Extended Warranty - COGS',
        	General_Ledger_Account__c=gla.Id,
            LineType__c='General Ledger Account',	// BLL3a
        	Default_Memo__c=''
        ));
		rules.add(new PostingTemplateEntryRule__c(
        	Posting_Template__c=pt.Id,
        	Action__c='Extended Warranty - Payable',
        	General_Ledger_Account__c=gla.Id,
            LineType__c='General Ledger Account',	// BLL3a
        	Default_Memo__c=''
        ));

		rules.add(new PostingTemplateEntryRule__c(
        	Posting_Template__c=pt.Id,
        	Action__c='GAP Insurance - Sales',
        	General_Ledger_Account__c=gla.Id,
            LineType__c='General Ledger Account',	// BLL3a
        	Default_Memo__c=''
        ));
		rules.add(new PostingTemplateEntryRule__c(
        	Posting_Template__c=pt.Id,
        	Action__c='GAP Insurance - COGS',
        	General_Ledger_Account__c=gla.Id,
            LineType__c='General Ledger Account',	// BLL3a
        	Default_Memo__c=''
        ));
		rules.add(new PostingTemplateEntryRule__c(
        	Posting_Template__c=pt.Id,
        	Action__c='GAP Insurance - Payable',
        	General_Ledger_Account__c=gla.Id,
            LineType__c='General Ledger Account',	// BLL3a
        	Default_Memo__c=''
        ));

//'GAP Insurance'
//'Roadside Assistance'
//'Diamond Fusion'            

		rules.add(new PostingTemplateEntryRule__c(
        	Posting_Template__c=pt.Id,
        	Action__c='Conversion Sales',
        	General_Ledger_Account__c=gla.Id,
            LineType__c='General Ledger Account',	// BLL3a
        	Default_Memo__c=''
        ));
		rules.add(new PostingTemplateEntryRule__c(
        	Posting_Template__c=pt.Id,
        	Action__c='Conversion Inventory',
        	General_Ledger_Account__c=gla.Id,
            LineType__c='General Ledger Account',	// BLL3a
        	Default_Memo__c=''
        ));
		rules.add(new PostingTemplateEntryRule__c(
        	Posting_Template__c=pt.Id,
        	Action__c='Additional Equipment Sales',
        	General_Ledger_Account__c=gla.Id,
            LineType__c='General Ledger Account',	// BLL3a
        	Default_Memo__c=''
        ));
		rules.add(new PostingTemplateEntryRule__c(
        	Posting_Template__c=pt.Id,
        	Action__c='Additional Equipment Cost',
        	General_Ledger_Account__c=gla.Id,
            LineType__c='General Ledger Account',	// BLL3a
        	Default_Memo__c=''
        ));
		rules.add(new PostingTemplateEntryRule__c(
        	Posting_Template__c=pt.Id,
        	Action__c='Additional Equipment Inventory',
        	General_Ledger_Account__c=gla.Id,
            LineType__c='General Ledger Account',	// BLL3a
        	Default_Memo__c=''
        ));
        insert(rules);

        Posting_Entry__c pe = new Posting_Entry__c();
            pe.Location__c=FFAdata.DealerLocation.Id;          
            pe.Posting_Template__c=pt.Id;
            pe.Proposal__c=deal.Id;
            pe.Stock__c=vehicle.Id;
            insert pe;

		dealer__Service_Contract__c sc2= new dealer__Service_Contract__c();
            sc2.dealer__Deductable__c=0.00;
            sc2.Type__c='GAP';
            sc2.dealer__Car_Deal__c =deal.id;
            insert sc2;
            //sc2.Type__c='Service Contract';
            //Update Sc2;
             
            PostingTemplate__c po= new PostingTemplate__c();
            po.Name='poname';
            po.Object_Name__c='Proposal';
            insert po; 
            
            PostingTemplateEntryRule__c ptr= new PostingTemplateEntryRule__c();
            ptr.FieldName__c='filed';
            ptr.Posting_Template__c=po.id;
            ptr.Action__c='Commission Accrual';
            ptr.LineType__c='General Ledger Account';	// BLL3a
            insert ptr;
         
      
			List<dealer__Service_Contract__c> protectionProd =new List<dealer__Service_Contract__c>();
			protectionProd.add(sc2);
            
        // Actual Test
		Test.startTest();

            ApexPages.StandardController sc = new ApexPages.StandardController(pe);
            ApexPages.currentPage().getParameters().put('id', pe.id);
            JournalManager  jm = new JournalManager(new ApexPages.StandardController(pe));
            jm.lookupTemplateRules();
            jm.entry.Posting_Template__c=pt.id;
            jm.lookupTemplateRules();
            jm.entry.Posting_Template__c=Null;
            jm.lookupTemplateRules();
            jm.entryId ='Test';
            jm.dim ='Test';
            jm.getLines();
            jm.loadProposalData();
            jm.proposal.dealer__Store_Location__c=FFAdata.DealerLocation.Id;
            jm.loadProposalData();
            jm.proposal.dealer__Store_Location__c=Null;
            jm.loadProposalData();
            jm.createJournal();
            //jm.tBalance =1;
            //jm.createJournal();
            jm.tBalance = 0;
            //BLL5d jm.createJournal();

            // JVK2
            jm.credit(22.20);
            jm.credit(null);
            jm.debit(22.20);
            jm.debit(null);
            jm.nonNull(20.12);  
            jm.nonNull(null);
            // End JVK2

            JournalManager.lines jml = new JournalManager.lines();
            jml.amount  = 12.12;
            jml.action ='Account Receivable';
            jml.memo ='Test';
            jml.accountName  ='Test';
            //BLL2d jml.division ='12345';
            jml.jline.c2g__Dimension1__c = FFAdata.Dimension1.Id;	// BLL2a
            jml.StockNbr='Test';
            jml.VIN='Test';
            jml.Description='Description';
            jm.calcLines();  // BLL1a
            jm.createJournal(); // BLL1a
			jm.actionTotal('S');
            jm.save(); // JVK2

            //List<PostingTemplateEntryRule__c> rules = [
            //	Select Id, Name, Action__c, General_Ledger_Account__c, General_Ledger_Account__r.Name, Default_Memo__c 
            //    from PostingTemplateEntryRule__c
            //    where Posting_Template__c=:pt.Id limit 1];
            //List<c2g__codaGeneralLedgerAccount__c> gl = [
            //	Select Id, Name 
            //	from c2g__codaGeneralLedgerAccount__c 
            //	where Id=:gla.Id limit 1];
            //jm.processCommissions(rules[0], gl[0]);
            jm.processCommissions(pte, gla);
            
            List<PostingTemplateEntryRule__c> protrules = [
            	Select Id, Name, Action__c, General_Ledger_Account__c, General_Ledger_Account__r.Name, Default_Memo__c, LineType__c	// BLL3c 
                from PostingTemplateEntryRule__c
                where Posting_Template__c=:pt.Id and Action__c like '%GAP%'
            ];
			for(PostingTemplateEntryRule__c pter : protrules) {
				jm.processProtection(protectionProd,pter,protectionProd[0].Type__c,gla);
			}
         
            dealer__Dealer_Trade__c trade= new dealer__Dealer_Trade__c();
            trade.dealer__Salesperson__c=Userinfo.getUserID();
            insert trade;

			Test.stopTest();                

        }

	}

}