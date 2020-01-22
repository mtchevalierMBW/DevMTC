/**
* CashEntryAutoMatchDT_TEST
* Tests: CashEntryAutoMatchDT_TEST
* Date: 2019-04-17
* Programmer: Bryan Leaman
* Project: W-000575
* Update proposal F&I overall status info when credit application statuses are updated.
*
* Modifications: 
*
*/
@isTest
private class CashEntryAutoMatchDT_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupData() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		TestHelper_MW th = new TestHelper_MW();
		dealer.TestClassUtil tc = new dealer.TestClassUtil();
		tc.insertDMSSettings();
		System.runAs(FFAdata.TestUser) {

			/*List<c2g__codaGeneralLedgerAccount__c> glalist = new List<c2g__codaGeneralLedgerAccount__c>(); 
			Integer i = 0;
			for(c2g__codaGeneralLedgerAccount__c gl : FFAdata.GLAMap.values()) {
				glalist.add(gl);
			}*/

        	Account pa = th.getPersonAccount('1');
        	//pa.c2g__CODAAccountsPayableControl__c = glalist[0].Id;
        	//pa.c2g__CODAAccountsReceivableControl__c = glalist[0].Id;
        	pa.c2g__CODAAccountsPayableControl__c = FFAdata.GLAMap.values()[0].Id;
        	pa.c2g__CODAAccountsReceivableControl__c = FFAdata.GLAMap.values()[0].Id;
        	pa.c2g__CODADimension1__c = FFAdata.Dimension1.Id;
        	update(pa);
        	
			update(new dealer__Dealer_Location__c(Id=FFAdata.DealerLocation.Id, Financial_Force_Dimension_1__c=FFAdata.Dimension1.Id));
			
	        c2g__codaBankAccount__c ba = new c2g__codaBankAccount__c(
				Name='Test bank',
				c2g__AccountName__c = 'Test account',
				c2g__AccountNumber__c = '123',
				c2g__BankName__c = 'Test bank name',
				c2g__ReportingCode__c = '123',
				//c2g__GeneralLedgerAccount__c = glalist[0].Id
				c2g__GeneralLedgerAccount__c = FFAdata.GLAMap.values()[0].Id
        	);
			insert(ba);

		}
	}


	// testFullAmountOver2Entries()
	//---------------------------------------
	static testMethod void testFullAmountOver2Entries() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();

			Account pa = [select Id from Account where isPersonAccount=true limit 1];
			c2g__codaBankAccount__c ba = [select Id from c2g__codaBankAccount__c where c2g__ReportingCode__c='123' limit 1];

			// Journal
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
				c2g__GeneralLedgerAccount__c = FFAdata.GLAMap.values()[0].Id, // glalist[0].Id,
				c2g__Account__c = pa.Id,
				c2g__LineType__c = 'Account - Customer',
				c2g__Value__c = 75,
				Control__c = 'TEST_MATCH',
				c2g__Dimension1__c = FFAdata.Dimension1.Id
			));
			jlines.add(new c2g__codaJournalLineItem__c(
				c2g__Journal__c = j.Id,
				c2g__GeneralLedgerAccount__c = FFAdata.GLAMap.values()[0].Id, //glalist[0].Id,
				c2g__Account__c = pa.Id,
				c2g__LineType__c = 'Account - Customer',
				c2g__Value__c = 25,
				Control__c = 'TEST_MATCH',
				c2g__Dimension1__c = FFAdata.Dimension1.Id
			));
			jlines.add(new c2g__codaJournalLineItem__c(
				c2g__Journal__c = j.Id,
				c2g__GeneralLedgerAccount__c = FFAdata.GLAMap.values()[1].Id, //glalist[1].Id,
				c2g__LineType__c = 'General Ledger Account',
				c2g__Value__c = -100,
				c2g__Dimension1__c = FFAdata.Dimension1.Id
			));
			insert(jlines);

			// Post journal
			c2g.CODAAPICommon_10_0.Context ctx10 = new c2g.CODAAPICommon_10_0.Context();
			ctx10.CompanyName = FFAdata.CurrentCompany.Name;
            c2g.CODAAPICommon.Reference journalRef = c2g.CODAApiCommon.getRef(j.Id, null);
            c2g.CODAAPIJournal_12_0.PostJournal(ctx10, journalRef);

			// Cash entry
			c2g__codaCashEntry__c ce = new c2g__codaCashEntry__c(
            	c2g__BankAccount__c = ba.Id,
            	c2g__Type__c='Receipt',
				AutoMatchCash__c=true,
				Automated_Entry__c=true
			);
			insert(ce);
			List<c2g__codaCashEntryLineItem__c> celines = new List<c2g__codaCashEntryLineItem__c>();
			celines.add(new c2g__codaCashEntryLineItem__c(
				c2g__CashEntry__c = ce.Id,
				c2g__Account__c = pa.Id,
				c2g__CashEntryValue__c = 80.00,
				c2g__PaymentValue__c = 80.00,
				c2g__BankAccountValue__c = 80.00,
				Control__c = 'TEST_MATCH',
				c2g__AccountDimension1__c = FFAdata.Dimension1.Id,
				ffcash__DeriveAccountDimensions__c = false
			));
			celines.add(new c2g__codaCashEntryLineItem__c(
				c2g__CashEntry__c = ce.Id,
				c2g__Account__c = pa.Id,
				c2g__CashEntryValue__c = 20.00,
				c2g__PaymentValue__c = 20.00,
				c2g__BankAccountValue__c = 20.00,
				Control__c = 'TEST_MATCH',
				c2g__AccountDimension1__c = FFAdata.Dimension1.Id,
				ffcash__DeriveAccountDimensions__c = false
			));
			insert(celines);
			
			// Post cash
			c2g.CODAAPICommon_7_0.Context ctx7 = new c2g.CODAAPICommon_7_0.Context(); 
			ctx7.CompanyName = FFAdata.CurrentCompany.Name;
            c2g.CODAAPICommon.Reference ceRef = c2g.CODAApiCommon.getRef(ce.Id, null);
			c2g.CODAAPICashEntry_7_0.PostCashEntry(ctx7, ceref);

			System.debug('[[[ Transaction Line Items Before Matching]]]');
			for(c2g__codaTransactionLineItem__c tl : [
				select Id, Name, c2g__Transaction__r.Name, c2g__Account__r.Name,
					c2g__Dimension1__r.Name, c2g__Transaction__r.c2g__OwnerCompany__r.Name,
					Control__c,	c2g__AccountOutstandingValue__c, c2g__AccountValue__c
				from c2g__codaTransactionLineItem__c
				where c2g__LineType__c='Account'
			]) {
				System.debug(String.join(new List<String>{
					tl.Id, tl.Name, tl.c2g__Transaction__r.c2g__OwnerCompany__r.Name,
					tl.c2g__Dimension1__r.Name, tl.c2g__Transaction__r.Name, 
					tl.Control__c,	tl.c2g__Account__r.Name,					
					String.valueOf(tl.c2g__AccountOutstandingValue__c), 
					String.valueOf(tl.c2g__AccountValue__c)
				}, ', '));
			}
			System.debug('[[[ END Transaction Line Items ]]]');

			Test.startTest();
			CashEntryAutoMatchDT cashmatch = new CashEntryAutoMatchDT(null, true, null, null, null, null);
			Database.executeBatch(cashmatch,1);
			Test.stopTest();

			System.debug('[[[ Transaction Line Items After Matching ]]]');
			Decimal outstanding = 0;
			Decimal credits = 0;
			Decimal debits = 0;
			for(c2g__codaTransactionLineItem__c tl : [
				select Id, Name, c2g__Transaction__r.Name, c2g__Account__r.Name,
					c2g__Dimension1__r.Name, c2g__Transaction__r.c2g__OwnerCompany__r.Name,
					Control__c,	c2g__AccountOutstandingValue__c, c2g__AccountValue__c
				from c2g__codaTransactionLineItem__c
				where c2g__LineType__c='Account'
			]) {
				outstanding += tl.c2g__AccountOutstandingValue__c;
				if (tl.c2g__AccountOutstandingValue__c<0) credits += tl.c2g__AccountOutstandingValue__c;
				if (tl.c2g__AccountOutstandingValue__c>0) debits += tl.c2g__AccountOutstandingValue__c;
				System.debug(String.join(new List<String>{
					tl.Id, tl.Name, tl.c2g__Transaction__r.c2g__OwnerCompany__r.Name,
					tl.c2g__Dimension1__r.Name, tl.c2g__Transaction__r.Name, 
					tl.Control__c,	tl.c2g__Account__r.Name,					
					String.valueOf(tl.c2g__AccountOutstandingValue__c), 
					String.valueOf(tl.c2g__AccountValue__c)
				}, ', '));
			}
			System.debug('[[[ END Transaction Line Items ]]]');
			System.assertEquals(0, outstanding, 'Account has an outstanding balance after matching full pmt');
			System.assertEquals(0, credits, 'Account credits were not fully applied');
			System.assertEquals(0, debits, 'Account debits were not properly reduced');
		}
	}


	// testPartialMatchUnderpaid
	//---------------------------------------
	static testMethod void testPartialMatchUnderpaid() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();

			Account pa = [select Id from Account where isPersonAccount=true limit 1];
			c2g__codaBankAccount__c ba = [select Id from c2g__codaBankAccount__c where c2g__ReportingCode__c='123' limit 1];

			// Journal
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
				c2g__GeneralLedgerAccount__c = FFAdata.GLAMap.values()[0].Id, // glalist[0].Id,
				c2g__Account__c = pa.Id,
				c2g__LineType__c = 'Account - Customer',
				c2g__Value__c = 75,
				Control__c = 'TEST_MATCH',
				c2g__Dimension1__c = FFAdata.Dimension1.Id
			));
			jlines.add(new c2g__codaJournalLineItem__c(
				c2g__Journal__c = j.Id,
				c2g__GeneralLedgerAccount__c = FFAdata.GLAMap.values()[0].Id, //glalist[0].Id,
				c2g__Account__c = pa.Id,
				c2g__LineType__c = 'Account - Customer',
				c2g__Value__c = 25,
				Control__c = 'TEST_MATCH',
				c2g__Dimension1__c = FFAdata.Dimension1.Id
			));
			jlines.add(new c2g__codaJournalLineItem__c(
				c2g__Journal__c = j.Id,
				c2g__GeneralLedgerAccount__c = FFAdata.GLAMap.values()[1].Id, //glalist[1].Id,
				c2g__LineType__c = 'General Ledger Account',
				c2g__Value__c = -100,
				c2g__Dimension1__c = FFAdata.Dimension1.Id
			));
			insert(jlines);

			// Post journal
			c2g.CODAAPICommon_10_0.Context ctx10 = new c2g.CODAAPICommon_10_0.Context();
			ctx10.CompanyName = FFAdata.CurrentCompany.Name;
            c2g.CODAAPICommon.Reference journalRef = c2g.CODAApiCommon.getRef(j.Id, null);
            c2g.CODAAPIJournal_12_0.PostJournal(ctx10, journalRef);

			c2g__codaCashEntry__c ce = new c2g__codaCashEntry__c(
            	c2g__BankAccount__c = ba.Id,
            	c2g__Type__c='Receipt',
				AutoMatchCash__c=true,
				Automated_Entry__c=true
			);
			insert(ce);
			List<c2g__codaCashEntryLineItem__c> celines = new List<c2g__codaCashEntryLineItem__c>();
			celines.add(new c2g__codaCashEntryLineItem__c(
				c2g__CashEntry__c = ce.Id,
				c2g__Account__c = pa.Id,
				c2g__CashEntryValue__c = 80.00,
				c2g__PaymentValue__c = 80.00,
				c2g__BankAccountValue__c = 80.00,
				Control__c = 'TEST_MATCH',
				c2g__AccountDimension1__c = FFAdata.Dimension1.Id,
				ffcash__DeriveAccountDimensions__c = false
			));
			insert(celines);
			
			// Post cash
			c2g.CODAAPICommon_7_0.Context ctx7 = new c2g.CODAAPICommon_7_0.Context(); 
			ctx7.CompanyName = FFAdata.CurrentCompany.Name;
            c2g.CODAAPICommon.Reference ceRef = c2g.CODAApiCommon.getRef(ce.Id, null);
			c2g.CODAAPICashEntry_7_0.PostCashEntry(ctx7, ceref);

			System.debug('[[[ Transaction Line Items Before Matching]]]');
			for(c2g__codaTransactionLineItem__c tl : [
				select Id, Name, c2g__Transaction__r.Name, c2g__Account__r.Name,
					c2g__Dimension1__r.Name, c2g__Transaction__r.c2g__OwnerCompany__r.Name,
					Control__c,	c2g__AccountOutstandingValue__c, c2g__AccountValue__c
				from c2g__codaTransactionLineItem__c
				where c2g__LineType__c='Account'
			]) {
				System.debug(String.join(new List<String>{
					tl.Id, tl.Name, tl.c2g__Transaction__r.c2g__OwnerCompany__r.Name,
					tl.c2g__Dimension1__r.Name, tl.c2g__Transaction__r.Name, 
					tl.Control__c,	tl.c2g__Account__r.Name,					
					String.valueOf(tl.c2g__AccountOutstandingValue__c), 
					String.valueOf(tl.c2g__AccountValue__c)
				}, ', '));
			}
			System.debug('[[[ END Transaction Line Items ]]]');

			Test.startTest();
			CashEntryAutoMatchDT cashmatch = new CashEntryAutoMatchDT(null, true, null, null, null, null);
			Database.executeBatch(cashmatch,1);
			Test.stopTest();

			Decimal outstanding = 0;
			Decimal debits = 0;
			Decimal credits = 0;
			System.debug('[[[ Transaction Line Items After Matching ]]]');
			for(c2g__codaTransactionLineItem__c tl : [
				select Id, Name, c2g__Transaction__r.Name, c2g__Account__r.Name,
					c2g__Dimension1__r.Name, c2g__Transaction__r.c2g__OwnerCompany__r.Name,
					Control__c,	c2g__AccountOutstandingValue__c, c2g__AccountValue__c
				from c2g__codaTransactionLineItem__c
				where c2g__LineType__c='Account'
			]) {
				outstanding += tl.c2g__AccountOutstandingValue__c;
				if (tl.c2g__AccountOutstandingValue__c<0) credits += tl.c2g__AccountOutstandingValue__c;
				if (tl.c2g__AccountOutstandingValue__c>0) debits += tl.c2g__AccountOutstandingValue__c;
				System.debug(String.join(new List<String>{
					tl.Id, tl.Name, tl.c2g__Transaction__r.c2g__OwnerCompany__r.Name,
					tl.c2g__Dimension1__r.Name, tl.c2g__Transaction__r.Name, 
					tl.Control__c,	tl.c2g__Account__r.Name,					
					String.valueOf(tl.c2g__AccountOutstandingValue__c), 
					String.valueOf(tl.c2g__AccountValue__c)
				}, ', '));
			}
			System.debug('[[[ END Transaction Line Items ]]]');
			System.assertEquals(20, outstanding, 'Account does not have a debit balance after underpaying');
			System.assertEquals(0, credits, 'Account credits were not fully applied');
			System.assertEquals(20, debits, 'Account debits were not properly reduced');
		}
	}


	// testMatchOverpaid
	//---------------------------------------
	static testMethod void testMatchOverpaid() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();

			Account pa = [select Id from Account where isPersonAccount=true limit 1];
			c2g__codaBankAccount__c ba = [select Id from c2g__codaBankAccount__c where c2g__ReportingCode__c='123' limit 1];

			// Journal
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
				c2g__GeneralLedgerAccount__c = FFAdata.GLAMap.values()[0].Id, // glalist[0].Id,
				c2g__Account__c = pa.Id,
				c2g__LineType__c = 'Account - Customer',
				c2g__Value__c = 75,
				Control__c = 'TEST_MATCH',
				c2g__Dimension1__c = FFAdata.Dimension1.Id
			));
			jlines.add(new c2g__codaJournalLineItem__c(
				c2g__Journal__c = j.Id,
				c2g__GeneralLedgerAccount__c = FFAdata.GLAMap.values()[0].Id, //glalist[0].Id,
				c2g__Account__c = pa.Id,
				c2g__LineType__c = 'Account - Customer',
				c2g__Value__c = 25,
				Control__c = 'TEST_MATCH',
				c2g__Dimension1__c = FFAdata.Dimension1.Id
			));
			jlines.add(new c2g__codaJournalLineItem__c(
				c2g__Journal__c = j.Id,
				c2g__GeneralLedgerAccount__c = FFAdata.GLAMap.values()[1].Id, //glalist[1].Id,
				c2g__LineType__c = 'General Ledger Account',
				c2g__Value__c = -100,
				c2g__Dimension1__c = FFAdata.Dimension1.Id
			));
			insert(jlines);

			// Post journal
			c2g.CODAAPICommon_10_0.Context ctx10 = new c2g.CODAAPICommon_10_0.Context();
			ctx10.CompanyName = FFAdata.CurrentCompany.Name;
            c2g.CODAAPICommon.Reference journalRef = c2g.CODAApiCommon.getRef(j.Id, null);
            c2g.CODAAPIJournal_12_0.PostJournal(ctx10, journalRef);

			c2g__codaCashEntry__c ce = new c2g__codaCashEntry__c(
            	c2g__BankAccount__c = ba.Id,
            	c2g__Type__c='Receipt',
				AutoMatchCash__c=true,
				Automated_Entry__c=true
			);
			insert(ce);
			List<c2g__codaCashEntryLineItem__c> celines = new List<c2g__codaCashEntryLineItem__c>();
			celines.add(new c2g__codaCashEntryLineItem__c(
				c2g__CashEntry__c = ce.Id,
				c2g__Account__c = pa.Id,
				c2g__CashEntryValue__c = 80.00,
				c2g__PaymentValue__c = 80.00,
				c2g__BankAccountValue__c = 80.00,
				Control__c = 'TEST_MATCH',
				c2g__AccountDimension1__c = FFAdata.Dimension1.Id,
				ffcash__DeriveAccountDimensions__c = false
			));
			celines.add(new c2g__codaCashEntryLineItem__c(
				c2g__CashEntry__c = ce.Id,
				c2g__Account__c = pa.Id,
				c2g__CashEntryValue__c = 30.00,
				c2g__PaymentValue__c = 30.00,
				c2g__BankAccountValue__c = 30.00,
				Control__c = 'TEST_MATCH',
				c2g__AccountDimension1__c = FFAdata.Dimension1.Id,
				ffcash__DeriveAccountDimensions__c = false
			));
			insert(celines);
			
			// Post cash
			c2g.CODAAPICommon_7_0.Context ctx7 = new c2g.CODAAPICommon_7_0.Context(); 
			ctx7.CompanyName = FFAdata.CurrentCompany.Name;
            c2g.CODAAPICommon.Reference ceRef = c2g.CODAApiCommon.getRef(ce.Id, null);
			c2g.CODAAPICashEntry_7_0.PostCashEntry(ctx7, ceref);

			System.debug('[[[ Transaction Line Items Before Matching]]]');
			for(c2g__codaTransactionLineItem__c tl : [
				select Id, Name, c2g__Transaction__r.Name, c2g__Account__r.Name,
					c2g__Dimension1__r.Name, c2g__Transaction__r.c2g__OwnerCompany__r.Name,
					Control__c,	c2g__AccountOutstandingValue__c, c2g__AccountValue__c
				from c2g__codaTransactionLineItem__c
				where c2g__LineType__c='Account'
			]) {
				System.debug(String.join(new List<String>{
					tl.Id, tl.Name, tl.c2g__Transaction__r.c2g__OwnerCompany__r.Name,
					tl.c2g__Dimension1__r.Name, tl.c2g__Transaction__r.Name, 
					tl.Control__c,	tl.c2g__Account__r.Name,					
					String.valueOf(tl.c2g__AccountOutstandingValue__c), 
					String.valueOf(tl.c2g__AccountValue__c)
				}, ', '));
			}
			System.debug('[[[ END Transaction Line Items ]]]');

			Test.startTest();
			CashEntryAutoMatchDT cashmatch = new CashEntryAutoMatchDT(null, true, null, null, null, null);
			Database.executeBatch(cashmatch,1);
			Test.stopTest();

			Decimal outstanding = 0;
			Decimal credits = 0;
			Decimal debits = 0;
			System.debug('[[[ Transaction Line Items After Matching ]]]');
			for(c2g__codaTransactionLineItem__c tl : [
				select Id, Name, c2g__Transaction__r.Name, c2g__Account__r.Name,
					c2g__Dimension1__r.Name, c2g__Transaction__r.c2g__OwnerCompany__r.Name,
					Control__c,	c2g__AccountOutstandingValue__c, c2g__AccountValue__c
				from c2g__codaTransactionLineItem__c
				where c2g__LineType__c='Account'
			]) {
				outstanding += tl.c2g__AccountOutstandingValue__c;
				if (tl.c2g__AccountOutstandingValue__c<0) credits += tl.c2g__AccountOutstandingValue__c;
				if (tl.c2g__AccountOutstandingValue__c>0) debits += tl.c2g__AccountOutstandingValue__c;
				System.debug(String.join(new List<String>{
					tl.Id, tl.Name, tl.c2g__Transaction__r.c2g__OwnerCompany__r.Name,
					tl.c2g__Dimension1__r.Name, tl.c2g__Transaction__r.Name, 
					tl.Control__c,	tl.c2g__Account__r.Name,					
					String.valueOf(tl.c2g__AccountOutstandingValue__c), 
					String.valueOf(tl.c2g__AccountValue__c)
				}, ', '));
			}
			System.debug('[[[ END Transaction Line Items ]]]');
			System.assertEquals(-10, outstanding, 'Account does not have a credit balance after overpaying');
			System.assertEquals(-10, credits, 'Account credits were not properly applied');
			System.assertEquals(0, debits, 'Account debits were not fully reduced');
		}
	}



	// testUnderpaidWithWriteoff
	//---------------------------------------
	static testMethod void testUnderpaidWithWriteoff() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();
			MobilityForceSettings__c mfs = MobilityForceSettings__c.getOrgDefaults();
			mfs.Writeoff_Overpayment__c = 5;
			mfs.Writeoff_Underpayment__c = 5;
			mfs.Writeoff_GL_Acct__c = FFAdata.GLAMap.values()[0].c2g__ReportingCode__c;
			upsert(mfs);

			Account pa = [select Id from Account where isPersonAccount=true limit 1];
			c2g__codaBankAccount__c ba = [select Id from c2g__codaBankAccount__c where c2g__ReportingCode__c='123' limit 1];

			// Journal
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
				c2g__GeneralLedgerAccount__c = FFAdata.GLAMap.values()[0].Id, // glalist[0].Id,
				c2g__Account__c = pa.Id,
				c2g__LineType__c = 'Account - Customer',
				c2g__Value__c = 75,
				Control__c = 'TEST_MATCH',
				c2g__Dimension1__c = FFAdata.Dimension1.Id
			));
			jlines.add(new c2g__codaJournalLineItem__c(
				c2g__Journal__c = j.Id,
				c2g__GeneralLedgerAccount__c = FFAdata.GLAMap.values()[0].Id, //glalist[0].Id,
				c2g__Account__c = pa.Id,
				c2g__LineType__c = 'Account - Customer',
				c2g__Value__c = 25,
				Control__c = 'TEST_MATCH',
				c2g__Dimension1__c = FFAdata.Dimension1.Id
			));
			jlines.add(new c2g__codaJournalLineItem__c(
				c2g__Journal__c = j.Id,
				c2g__GeneralLedgerAccount__c = FFAdata.GLAMap.values()[1].Id, //glalist[1].Id,
				c2g__LineType__c = 'General Ledger Account',
				c2g__Value__c = -100,
				c2g__Dimension1__c = FFAdata.Dimension1.Id
			));
			insert(jlines);

			// Post journal
			c2g.CODAAPICommon_10_0.Context ctx10 = new c2g.CODAAPICommon_10_0.Context();
			ctx10.CompanyName = FFAdata.CurrentCompany.Name;
            c2g.CODAAPICommon.Reference journalRef = c2g.CODAApiCommon.getRef(j.Id, null);
            c2g.CODAAPIJournal_12_0.PostJournal(ctx10, journalRef);

			c2g__codaCashEntry__c ce = new c2g__codaCashEntry__c(
            	c2g__BankAccount__c = ba.Id,
            	c2g__Type__c='Receipt',
				AutoMatchCash__c=true,
				Automated_Entry__c=true
			);
			insert(ce);
			List<c2g__codaCashEntryLineItem__c> celines = new List<c2g__codaCashEntryLineItem__c>();
			celines.add(new c2g__codaCashEntryLineItem__c(
				c2g__CashEntry__c = ce.Id,
				c2g__Account__c = pa.Id,
				c2g__CashEntryValue__c = 98.00,
				c2g__PaymentValue__c = 98.00,
				c2g__BankAccountValue__c = 98.00,
				Control__c = 'TEST_MATCH',
				c2g__AccountDimension1__c = FFAdata.Dimension1.Id,
				ffcash__DeriveAccountDimensions__c = false
			));
			insert(celines);
			
			// Post cash
			c2g.CODAAPICommon_7_0.Context ctx7 = new c2g.CODAAPICommon_7_0.Context(); 
			ctx7.CompanyName = FFAdata.CurrentCompany.Name;
            c2g.CODAAPICommon.Reference ceRef = c2g.CODAApiCommon.getRef(ce.Id, null);
			c2g.CODAAPICashEntry_7_0.PostCashEntry(ctx7, ceref);

			System.debug('[[[ Transaction Line Items Before Matching]]]');
			for(c2g__codaTransactionLineItem__c tl : [
				select Id, Name, c2g__Transaction__r.Name, c2g__Account__r.Name,
					c2g__Dimension1__c, c2g__Dimension1__r.Name, c2g__Transaction__r.c2g__OwnerCompany__r.Name,
					Control__c,	c2g__AccountOutstandingValue__c, c2g__AccountValue__c
				from c2g__codaTransactionLineItem__c
				where c2g__LineType__c='Account'
			]) {
				System.debug(String.join(new List<String>{
					tl.Id, tl.Name, tl.c2g__Transaction__r.c2g__OwnerCompany__r.Name,
					tl.c2g__Dimension1__r.Name, tl.c2g__Transaction__r.Name, 
					tl.Control__c,	tl.c2g__Account__r.Name,					
					String.valueOf(tl.c2g__AccountOutstandingValue__c), 
					String.valueOf(tl.c2g__AccountValue__c)
				}, ', '));
			}
			System.debug('[[[ END Transaction Line Items ]]]');

			Test.startTest();
			CashEntryAutoMatchDT cashmatch = new CashEntryAutoMatchDT(null, true, null, null, null, null);
			Database.executeBatch(cashmatch,1);
			Test.stopTest();

			Decimal outstanding = 0;
			Decimal debits = 0;
			Decimal credits = 0;
			System.debug('[[[ Transaction Line Items After Matching ]]]');
			for(c2g__codaTransactionLineItem__c tl : [
				select Id, Name, c2g__Transaction__r.Name, c2g__Account__r.Name,
					c2g__Dimension1__c, c2g__Dimension1__r.Name, c2g__Transaction__r.c2g__OwnerCompany__r.Name,
					Control__c,	c2g__AccountOutstandingValue__c, c2g__AccountValue__c
				from c2g__codaTransactionLineItem__c
				where c2g__LineType__c='Account'
			]) {
				outstanding += tl.c2g__AccountOutstandingValue__c;
				if (tl.c2g__AccountOutstandingValue__c<0) credits += tl.c2g__AccountOutstandingValue__c;
				if (tl.c2g__AccountOutstandingValue__c>0) debits += tl.c2g__AccountOutstandingValue__c;
				System.debug(String.join(new List<String>{
					tl.Id, tl.Name, tl.c2g__Transaction__r.c2g__OwnerCompany__r.Name,
					tl.c2g__Dimension1__r.Name, tl.c2g__Transaction__r.Name, 
					tl.Control__c,	tl.c2g__Account__r.Name,					
					String.valueOf(tl.c2g__AccountOutstandingValue__c), 
					String.valueOf(tl.c2g__AccountValue__c)
				}, ', '));
			}
			System.debug('[[[ END Transaction Line Items ]]]');
			System.assertEquals(0, outstanding, 'Account balance did not clear');
			System.assertEquals(0, credits, 'Account credits were not properly applied');
			System.assertEquals(0, debits, 'Account debits were not fully reduced');

			System.debug('[[[ check for dim1 ]]]');
			for(c2g__codaJournalLineItem__c jl : [select Id, Name, c2g__Journal__r.Name, c2g__Dimension1__c, c2g__Value__c from c2g__codaJournalLineItem__c ]) {
				System.debug(jl);
				System.assert(!String.isBlank(jl.c2g__Dimension1__c), jl.Name + ' is missing Dimension1!');
			}
		}
	}


	// testOverpaidWithWriteoff
	//---------------------------------------
	static testMethod void testOverpaidWithWriteoff() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();
			MobilityForceSettings__c mfs = MobilityForceSettings__c.getOrgDefaults();
			mfs.Writeoff_Overpayment__c = 5;
			mfs.Writeoff_Underpayment__c = 5;
			mfs.Writeoff_GL_Acct__c = FFAdata.GLAMap.values()[0].c2g__ReportingCode__c;
			upsert(mfs);

			Account pa = [select Id from Account where isPersonAccount=true limit 1];
			c2g__codaBankAccount__c ba = [select Id from c2g__codaBankAccount__c where c2g__ReportingCode__c='123' limit 1];

			// Journal
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
				c2g__GeneralLedgerAccount__c = FFAdata.GLAMap.values()[0].Id, // glalist[0].Id,
				c2g__Account__c = pa.Id,
				c2g__LineType__c = 'Account - Customer',
				c2g__Value__c = 75,
				Control__c = 'TEST_MATCH',
				c2g__Dimension1__c = FFAdata.Dimension1.Id
			));
			jlines.add(new c2g__codaJournalLineItem__c(
				c2g__Journal__c = j.Id,
				c2g__GeneralLedgerAccount__c = FFAdata.GLAMap.values()[0].Id, //glalist[0].Id,
				c2g__Account__c = pa.Id,
				c2g__LineType__c = 'Account - Customer',
				c2g__Value__c = 25,
				Control__c = 'TEST_MATCH',
				c2g__Dimension1__c = FFAdata.Dimension1.Id
			));
			jlines.add(new c2g__codaJournalLineItem__c(
				c2g__Journal__c = j.Id,
				c2g__GeneralLedgerAccount__c = FFAdata.GLAMap.values()[1].Id, //glalist[1].Id,
				c2g__LineType__c = 'General Ledger Account',
				c2g__Value__c = -100,
				c2g__Dimension1__c = FFAdata.Dimension1.Id
			));
			insert(jlines);

			// Post journal
			c2g.CODAAPICommon_10_0.Context ctx10 = new c2g.CODAAPICommon_10_0.Context();
			ctx10.CompanyName = FFAdata.CurrentCompany.Name;
            c2g.CODAAPICommon.Reference journalRef = c2g.CODAApiCommon.getRef(j.Id, null);
            c2g.CODAAPIJournal_12_0.PostJournal(ctx10, journalRef);

			c2g__codaCashEntry__c ce = new c2g__codaCashEntry__c(
            	c2g__BankAccount__c = ba.Id,
            	c2g__Type__c='Receipt',
				AutoMatchCash__c=true,
				Automated_Entry__c=true
			);
			insert(ce);
			List<c2g__codaCashEntryLineItem__c> celines = new List<c2g__codaCashEntryLineItem__c>();
			celines.add(new c2g__codaCashEntryLineItem__c(
				c2g__CashEntry__c = ce.Id,
				c2g__Account__c = pa.Id,
				c2g__CashEntryValue__c = 80.00,
				c2g__PaymentValue__c = 80.00,
				c2g__BankAccountValue__c = 80.00,
				Control__c = 'TEST_MATCH',
				c2g__AccountDimension1__c = FFAdata.Dimension1.Id,
				ffcash__DeriveAccountDimensions__c = false
			));
			celines.add(new c2g__codaCashEntryLineItem__c(
				c2g__CashEntry__c = ce.Id,
				c2g__Account__c = pa.Id,
				c2g__CashEntryValue__c = 21.00,
				c2g__PaymentValue__c = 21.00,
				c2g__BankAccountValue__c = 21.00,
				Control__c = 'TEST_MATCH',
				c2g__AccountDimension1__c = FFAdata.Dimension1.Id,
				ffcash__DeriveAccountDimensions__c = false
			));
			insert(celines);
			
			// Post cash
			c2g.CODAAPICommon_7_0.Context ctx7 = new c2g.CODAAPICommon_7_0.Context(); 
			ctx7.CompanyName = FFAdata.CurrentCompany.Name;
            c2g.CODAAPICommon.Reference ceRef = c2g.CODAApiCommon.getRef(ce.Id, null);
			c2g.CODAAPICashEntry_7_0.PostCashEntry(ctx7, ceref);

			System.debug('[[[ Transaction Line Items Before Matching]]]');
			for(c2g__codaTransactionLineItem__c tl : [
				select Id, Name, c2g__Transaction__r.Name, c2g__Account__r.Name,
					c2g__Dimension1__r.Name, c2g__Transaction__r.c2g__OwnerCompany__r.Name,
					Control__c,	c2g__AccountOutstandingValue__c, c2g__AccountValue__c
				from c2g__codaTransactionLineItem__c
				where c2g__LineType__c='Account'
			]) {
				System.debug(String.join(new List<String>{
					tl.Id, tl.Name, tl.c2g__Transaction__r.c2g__OwnerCompany__r.Name,
					tl.c2g__Dimension1__r.Name, tl.c2g__Transaction__r.Name, 
					tl.Control__c,	tl.c2g__Account__r.Name,					
					String.valueOf(tl.c2g__AccountOutstandingValue__c), 
					String.valueOf(tl.c2g__AccountValue__c)
				}, ', '));
			}
			System.debug('[[[ END Transaction Line Items ]]]');

			Test.startTest();
			CashEntryAutoMatchDT cashmatch = new CashEntryAutoMatchDT(null, true, null, null, null, null);
			Database.executeBatch(cashmatch,1);
			Test.stopTest();

			Decimal outstanding = 0;
			Decimal credits = 0;
			Decimal debits = 0;
			System.debug('[[[ Transaction Line Items After Matching ]]]');
			for(c2g__codaTransactionLineItem__c tl : [
				select Id, Name, c2g__Transaction__r.Name, c2g__Account__r.Name,
					c2g__Dimension1__r.Name, c2g__Transaction__r.c2g__OwnerCompany__r.Name,
					Control__c,	c2g__AccountOutstandingValue__c, c2g__AccountValue__c
				from c2g__codaTransactionLineItem__c
				where c2g__LineType__c='Account'
			]) {
				outstanding += tl.c2g__AccountOutstandingValue__c;
				if (tl.c2g__AccountOutstandingValue__c<0) credits += tl.c2g__AccountOutstandingValue__c;
				if (tl.c2g__AccountOutstandingValue__c>0) debits += tl.c2g__AccountOutstandingValue__c;
				System.debug(String.join(new List<String>{
					tl.Id, tl.Name, tl.c2g__Transaction__r.c2g__OwnerCompany__r.Name,
					tl.c2g__Dimension1__r.Name, tl.c2g__Transaction__r.Name, 
					tl.Control__c,	tl.c2g__Account__r.Name,					
					String.valueOf(tl.c2g__AccountOutstandingValue__c), 
					String.valueOf(tl.c2g__AccountValue__c)
				}, ', '));
			}
			System.debug('[[[ END Transaction Line Items ]]]');
			System.assertEquals(0, outstanding, 'Account balance did not clear');
			System.assertEquals(0, credits, 'Account credits were not properly applied');
			System.assertEquals(0, debits, 'Account debits were not fully reduced');

			System.debug('[[[ check for dim1 ]]]');
			for(c2g__codaJournalLineItem__c jl : [select Id, Name, c2g__Journal__r.Name, c2g__Dimension1__c, c2g__Value__c from c2g__codaJournalLineItem__c ]) {
				System.debug(jl);
				System.assert(!String.isBlank(jl.c2g__Dimension1__c), jl.Name + ' is missing Dimension1!');
			}
		}
	}


	// testSchedule
	//---------------------------------------
	static testMethod void testSchedule() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();
			Test.startTest();
			CashEntryAutoMatchDT.scheduleMe();
			Test.stopTest();
			for(c2g__codaTransactionLineItem__c tl : [
				select Id, Name, c2g__Transaction__r.Name, c2g__Account__r.Name,
					c2g__AccountOutstandingValue__c, c2g__AccountValue__c
				from c2g__codaTransactionLineItem__c
			]) {
				System.debug(tl);
			}
		}
	}

}