/**
 * CashMatchingProcess_TEST
 * Tests: CashMatchingProcess_TEST
 * Date: Jul 23, 2018
 * Programmer: Bryan Leaman
 *
 */
@isTest
private class CashMatchingProcess_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		//FFAdata.refresh(); 
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
	}

	// unitTestGoodMatch
	//---------------------------------------
	static testMethod void unitTestGoodMatch() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();

			List<c2g__codaGeneralLedgerAccount__c> glalist = new List<c2g__codaGeneralLedgerAccount__c>(); 
			Integer i = 0;
			for(c2g__codaGeneralLedgerAccount__c gl : FFAdata.GLAMap.values()) {
				glalist.add(gl);
			}

        	Account pa = th.getPersonAccount('1');
        	pa.c2g__CODAAccountsPayableControl__c = glalist[0].Id;
        	pa.c2g__CODAAccountsReceivableControl__c = glalist[0].Id;
        	pa.c2g__CODADimension1__c = FFAdata.Dimension1.Id;
        	update(pa);
        	
			update(new dealer__Dealer_Location__c(Id=FFAdata.DealerLocation.Id, Financial_Force_Dimension_1__c=FFAdata.Dimension1.Id));
			
			// Same dimension1: Generate cash entry, A/R and match them
			c2g__codaJournal__c j = new c2g__codaJournal__c(
				c2g__OwnerCompany__c = FFAdata.CurrentCompany.Id,
				c2g__JournalDescription__c = 'Test journal',
				Source__c = 'GE'
			);
			insert(j);
			List<c2g__codaJournalLineItem__c> jlines = new List<c2g__codaJournalLineItem__c>();
			jlines.add(new c2g__codaJournalLineItem__c(
				c2g__Journal__c = j.Id,
				c2g__GeneralLedgerAccount__c = glalist[0].Id,
				c2g__Account__c = pa.Id,
				c2g__LineType__c = 'Account - Customer',
				c2g__Value__c = -100,
				c2g__Dimension1__c = FFAdata.Dimension1.Id
			));
			jlines.add(new c2g__codaJournalLineItem__c(
				c2g__Journal__c = j.Id,
				c2g__GeneralLedgerAccount__c = glalist[1].Id,
				c2g__LineType__c = 'General Ledger Account',
				c2g__Value__c = 100,
				c2g__Dimension1__c = FFAdata.Dimension1.Id
			));
			insert(jlines);

			// Post journal
			c2g.CODAAPICommon_10_0.Context ctx10 = new c2g.CODAAPICommon_10_0.Context();
			ctx10.CompanyName = FFAdata.CurrentCompany.Name;
            c2g.CODAAPICommon.Reference journalRef = c2g.CODAApiCommon.getRef(j.Id, null);
            c2g.CODAAPIJournal_12_0.PostJournal(ctx10, journalRef);

			// Create cash entry
	        c2g__codaBankAccount__c ba = new c2g__codaBankAccount__c(
				Name='Test bank',
				c2g__AccountName__c = 'Test account',
				c2g__AccountNumber__c = '123',
				c2g__BankName__c = 'Test bank name',
				c2g__ReportingCode__c = '123',
				c2g__GeneralLedgerAccount__c = glalist[0].Id
        	);
			insert(ba);

			c2g__codaCashEntry__c ce = new c2g__codaCashEntry__c(
            	c2g__BankAccount__c = ba.Id,
            	c2g__Type__c='Payment'
			);
			insert(ce);
			List<c2g__codaCashEntryLineItem__c> celines = new List<c2g__codaCashEntryLineItem__c>();
			celines.add(new c2g__codaCashEntryLineItem__c(
				c2g__CashEntry__c = ce.Id,
				c2g__Account__c = pa.Id,
				c2g__CashEntryValue__c = 100.00,
				Control__c = 'TestCashEntryLine 1',
				c2g__AccountDimension1__c = FFAdata.Dimension1.Id,
				ffcash__DeriveAccountDimensions__c = false
			));
			insert(celines);
			
			// Post cash
			c2g.CODAAPICommon_7_0.Context ctx7 = new c2g.CODAAPICommon_7_0.Context(); 
			ctx7.CompanyName = FFAdata.CurrentCompany.Name;
            c2g.CODAAPICommon.Reference ceRef = c2g.CODAApiCommon.getRef(ce.Id, null);
			c2g.CODAAPICashEntry_7_0.PostCashEntry(ctx7, ceref);
			
			Test.startTest();

			// Match transaction & cash
			c2g.CODAAPICommon_8_0.Context ctx = new c2g.CODAAPICommon_8_0.Context();
			ctx.CompanyName = FFAdata.CurrentCompany.Name;
		
			c2g.CODAAPICashMatchingTypes_8_0.Configuration config = new c2g.CODAAPICashMatchingTypes_8_0.Configuration();
			config.Account = c2g.CODAAPICommon.Reference.getRef(pa.Id, pa.Name);
			config.MatchingCurrencyMode = c2g.CODAAPICashMatchingTypes_8_0.enumMatchingCurrencyMode.Document; 
			config.MatchingDate = Date.today();
			config.MatchingPeriod = c2g.CODAAPICommon.Reference.getRef(FFAdata.CurrentPeriod.Id, FFAdata.CurrentPeriod.Name);
		
			List<c2g.CODAAPICashMatchingTypes_8_0.Item> items = new List<c2g.CODAAPICashMatchingTypes_8_0.Item>();
			c2g.CODAAPICashMatchingTypes_8_0.Item item;
			for(c2g__codaTransactionLineItem__c tli : [
					select Id, Name, c2g__HomeValue__c, LastModifiedDate 
					from c2g__codaTransactionLineItem__c
					where c2g__LineType__c='Account'
				]) {
				item = new c2g.CODAAPICashMatchingTypes_8_0.Item();
					item.TransactionLineItem = c2g.CODAAPICommon.Reference.getRef(tli.Id, tli.Name);
					item.Paid = tli.c2g__HomeValue__c;
					item.Discount = 0.00;
					item.WriteOff = 0.00;
					item.TransactionLineItemSystemModStamp = tli.LastModifiedDate;
				items.add(item);
			}
	
			// Setup analysis - no discounts or writeoffs needed for this
			c2g.CODAAPICashMatchingTypes_8_0.Analysis analysis = new c2g.CODAAPICashMatchingTypes_8_0.Analysis();
			analysis.DiscountGLA = null;
			analysis.WriteOffGLA = null;
			analysis.CurrencyWriteOffGLA = null;
	
			// Call API! (or not)
			c2g.CODAAPICashMatching_8_0.Match(ctx, config, items, analysis);

			Test.stopTest();

		}

	}


	// unitTestBadMatch
	//---------------------------------------
	static testMethod void unitTestBadMatch() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();

			List<c2g__codaGeneralLedgerAccount__c> glalist = new List<c2g__codaGeneralLedgerAccount__c>(); 
			Integer i = 0;
			for(c2g__codaGeneralLedgerAccount__c gl : FFAdata.GLAMap.values()) {
				glalist.add(gl);
			}

        	Account pa = th.getPersonAccount('1');
        	pa.c2g__CODAAccountsPayableControl__c = glalist[0].Id;
        	pa.c2g__CODAAccountsReceivableControl__c = glalist[0].Id;
        	pa.c2g__CODADimension1__c = FFAdata.Dimension1.Id;
        	update(pa);
        	
			update(new dealer__Dealer_Location__c(Id=FFAdata.DealerLocation.Id, Financial_Force_Dimension_1__c=FFAdata.Dimension1.Id));
			
			// Same dimension1: Generate cash entry, A/R and match them
			c2g__codaJournal__c j = new c2g__codaJournal__c(
				c2g__OwnerCompany__c = FFAdata.CurrentCompany.Id,
				c2g__JournalDescription__c = 'Test journal',
				Source__c = 'GE'
			);
			insert(j);
			List<c2g__codaJournalLineItem__c> jlines = new List<c2g__codaJournalLineItem__c>();
			jlines.add(new c2g__codaJournalLineItem__c(
				c2g__Journal__c = j.Id,
				c2g__GeneralLedgerAccount__c = glalist[0].Id,
				c2g__Account__c = pa.Id,
				c2g__LineType__c = 'Account - Customer',
				c2g__Value__c = -100,
				c2g__Dimension1__c = FFAdata.Dimension1b.Id
			));
			jlines.add(new c2g__codaJournalLineItem__c(
				c2g__Journal__c = j.Id,
				c2g__GeneralLedgerAccount__c = glalist[1].Id,
				c2g__LineType__c = 'General Ledger Account',
				c2g__Value__c = 100,
				c2g__Dimension1__c = FFAdata.Dimension1b.Id
			));
			insert(jlines);

			// Post journal
			c2g.CODAAPICommon_10_0.Context ctx10 = new c2g.CODAAPICommon_10_0.Context();
			ctx10.CompanyName = FFAdata.CurrentCompany.Name;
            c2g.CODAAPICommon.Reference journalRef = c2g.CODAApiCommon.getRef(j.Id, null);
            c2g.CODAAPIJournal_12_0.PostJournal(ctx10, journalRef);

			// Create cash entry
	        c2g__codaBankAccount__c ba = new c2g__codaBankAccount__c(
				Name='Test bank',
				c2g__AccountName__c = 'Test account',
				c2g__AccountNumber__c = '123',
				c2g__BankName__c = 'Test bank name',
				c2g__ReportingCode__c = '123',
				c2g__GeneralLedgerAccount__c = glalist[0].Id
        	);
			insert(ba);

			c2g__codaCashEntry__c ce = new c2g__codaCashEntry__c(
            	c2g__BankAccount__c = ba.Id,
            	c2g__Type__c='Payment'
			);
			insert(ce);
			List<c2g__codaCashEntryLineItem__c> celines = new List<c2g__codaCashEntryLineItem__c>();
			celines.add(new c2g__codaCashEntryLineItem__c(
				c2g__CashEntry__c = ce.Id,
				c2g__Account__c = pa.Id,
				c2g__CashEntryValue__c = 100.00,
				Control__c = 'TestCashEntryLine 1',
				c2g__AccountDimension1__c = FFAdata.Dimension1.Id,
				ffcash__DeriveAccountDimensions__c = false
			));
			insert(celines);
			
			// Post cash
			c2g.CODAAPICommon_7_0.Context ctx7 = new c2g.CODAAPICommon_7_0.Context(); 
			ctx7.CompanyName = FFAdata.CurrentCompany.Name;
            c2g.CODAAPICommon.Reference ceRef = c2g.CODAApiCommon.getRef(ce.Id, null);
			c2g.CODAAPICashEntry_7_0.PostCashEntry(ctx7, ceref);
			
			Test.startTest();

			// Match transaction & cash
			c2g.CODAAPICommon_8_0.Context ctx = new c2g.CODAAPICommon_8_0.Context();
			ctx.CompanyName = FFAdata.CurrentCompany.Name;
		
			c2g.CODAAPICashMatchingTypes_8_0.Configuration config = new c2g.CODAAPICashMatchingTypes_8_0.Configuration();
			config.Account = c2g.CODAAPICommon.Reference.getRef(pa.Id, pa.Name);
			config.MatchingCurrencyMode = c2g.CODAAPICashMatchingTypes_8_0.enumMatchingCurrencyMode.Document; 
			config.MatchingDate = Date.today();
			config.MatchingPeriod = c2g.CODAAPICommon.Reference.getRef(FFAdata.CurrentPeriod.Id, FFAdata.CurrentPeriod.Name);
		
			List<c2g.CODAAPICashMatchingTypes_8_0.Item> items = new List<c2g.CODAAPICashMatchingTypes_8_0.Item>();
			c2g.CODAAPICashMatchingTypes_8_0.Item item;
			for(c2g__codaTransactionLineItem__c tli : [
					select Id, Name, c2g__HomeValue__c, LastModifiedDate 
					from c2g__codaTransactionLineItem__c
					where c2g__LineType__c='Account'
				]) {
				item = new c2g.CODAAPICashMatchingTypes_8_0.Item();
					item.TransactionLineItem = c2g.CODAAPICommon.Reference.getRef(tli.Id, tli.Name);
					item.Paid = tli.c2g__HomeValue__c;
					item.Discount = 0.00;
					item.WriteOff = 0.00;
					item.TransactionLineItemSystemModStamp = tli.LastModifiedDate;
				items.add(item);
			}
	
			// Setup analysis - no discounts or writeoffs needed for this
			c2g.CODAAPICashMatchingTypes_8_0.Analysis analysis = new c2g.CODAAPICashMatchingTypes_8_0.Analysis();
			analysis.DiscountGLA = null;
			analysis.WriteOffGLA = null;
			analysis.CurrencyWriteOffGLA = null;
	
			boolean matchSucceeded = false;
			try {
				// Call API! (or not)
				c2g.CODAAPICashMatching_8_0.Match(ctx, config, items, analysis);
				matchSucceeded = true;
			} Catch(Exception e) {
			}
			System.assert(matchSucceeded==false, 'Matching two different dimensions was allowed!');

			Test.stopTest();

		}
	}


}