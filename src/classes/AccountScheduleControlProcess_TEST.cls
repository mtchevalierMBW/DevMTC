/**
 * AccountScheduleControlProcess_TEST
 * Tests: AccountScheduleControlProcess_TEST
 * Date: May 26, 2017
 * Programmer: Bryan Leaman
 *
 *	Date		Developer	Description
 *	----------	----------	--------------------------------------------------------------
 *	2017-06-19	B. Leaman	BLL1 - Coverage for new routine.
 *	2017-07-10	B. Leaman	BLL2 - New routine to test.
 */
@isTest
private class AccountScheduleControlProcess_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
        //dealer.TestClassUtil tc = new dealer.TestClassUtil();
        //tc.insertDMSSettings();
		c2g__codaGeneralLedgerAccount__c g = FFAdata.GLAMap.get('cogs');
		g.VehicleRequired__c = true;
		g.ScheduledAccount__c = true;
		update(g);
		
		System.runAs(FFAdata.TestUser) {

			// Create vehicle (stock=55566B)
			dealer__Vehicle_Inventory__c v = new dealer__Vehicle_Inventory__c(
				dealer__VIN__c = '11122233344455566', dealer__Stock_Number__c = '55566B',
				dealer__Year__c='2021', dealer__Make__c='Toyota', dealer__Model__c='Futuristic',
				New_Used_Other__c='Commercial',
				dealer__Store_Location__c=FFAdata.DealerLocation.Id
			);
			insert(v);
			
            c2g__codaJournal__c newj = new c2g__codaJournal__c();
            newj.c2g__JournalDate__c =system.today();
            newj.Source__c ='GE';
            newj.c2g__Type__c='Manual Journal';
            newj.c2g__JournalStatus__c='In Progress';
            insert(newj);
    
            List<c2g__codaJournalLineItem__c> newl = new List<c2g__codaJournalLineItem__c>();
            newl.add(new c2g__codaJournalLineItem__c(
            	c2g__Journal__c = newj.Id,
            	c2g__Value__c = 1.00,
            	c2g__GeneralLedgerAccount__c = FFAdata.GLAMap.get('cogs').Id,
            	c2g__LineType__c = 'General Ledger Account',
            	c2g__LineNumber__c = 1,
            	Control__c = v.dealer__Stock_Number__c,
            	Sales_Person__c = UserInfo.getUserId(),
            	c2g__Dimension1__c = FFAdata.Dimension1.Id
            )); 
            newl.add(new c2g__codaJournalLineItem__c(
            	c2g__Journal__c = newj.Id,
            	c2g__Value__c = -1.00,
            	c2g__GeneralLedgerAccount__c = FFAdata.GLAMap.get('cogs').Id,  
            	c2g__LineType__c = 'General Ledger Account', 
            	c2g__LineNumber__c = 2,
            	Control__c = v.dealer__Stock_Number__c,
            	c2g__Dimension1__c = FFAdata.Dimension1.Id
			));
            insert(newl);
            
            c2g.CODAAPICommon.Reference ref = new c2g.CODAAPICommon.Reference();
            ref.Id = newj.Id;
            c2g.CODAAPIJournal_9_0.PostJournal(null, ref);
		}

	}

	// Additional coverage when updating the control#
	static testMethod void updateControl() {
		c2g__codaTransactionLineItem__c tl = [
			select Id, Control__c 
			from c2g__codaTransactionLineItem__c 
			where AccountScheduleControl__c!=null 
			limit 1
		];
		tl.Control__c += '-x';
		update(tl);
	}

	static testMethod void batchRebuildTest() {
			AccountScheduleControl__c ctl = [
				select Id, Control__c, GeneralLedgerAccount__r.c2g__ExternalId__c, Dimension1__r.c2g__ExternalId__c
				from AccountScheduleControl__c
				limit 1
			];
			Test.startTest();
			AccountScheduleControl_BatchRebuild ba = new AccountScheduleControl_BatchRebuild('1', false, 
				new List<String>{ctl.GeneralLedgerAccount__r.c2g__ExternalId__c}, new List<String>{ctl.Dimension1__r.c2g__ExternalId__c}, null);
			Database.executeBatch(ba);
			Test.stopTest();
	}
	

	static testMethod void batchBuildTest() {
			AccountScheduleControl__c ctl = [
				select Id, Control__c, GeneralLedgerAccount__r.c2g__ExternalId__c, Dimension1__r.c2g__ExternalId__c
				from AccountScheduleControl__c
				limit 1
			];
			Test.startTest();
			AccountScheduleControl_BatchBuild ba = new AccountScheduleControl_BatchBuild('1', false, 
				new List<String>{ctl.GeneralLedgerAccount__r.c2g__ExternalId__c}, new List<String>{ctl.Dimension1__r.c2g__ExternalId__c}, null);
			Database.executeBatch(ba);
			Test.stopTest();
	}
	
	static testMethod void batchCleanUp() {
		Test.startTest();
		AccountScheduleControl_BatchRebuild.scheduleMe();
		AccountScheduleControl_CleanUp.scheduleMe();
		Test.stopTest();
	}
	
	static testMethod void testTransaction() {
		FFAdata.refresh(); 
                        
        c2g__codaGeneralLedgerAccount__c gla = [select Id, Name from c2g__codaGeneralLedgerAccount__c where ScheduledAccount__c=true limit 1]; 
                        
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
    		Test.startTest();    	

            c2g__codaJournal__c newj = new c2g__codaJournal__c();
            newj.c2g__JournalDate__c =system.today();
            newj.Source__c ='GE';
            newj.c2g__Type__c='Manual Journal';
            newj.c2g__JournalStatus__c='In Progress';
            insert(newj);
    
            List<c2g__codaJournalLineItem__c> newl = new List<c2g__codaJournalLineItem__c>();
            newl.add(new c2g__codaJournalLineItem__c(
            	c2g__Journal__c = newj.Id,
            	c2g__Value__c = 123.00,
            	c2g__GeneralLedgerAccount__c = gla.Id,
            	c2g__LineType__c = 'General Ledger Account',
            	c2g__LineNumber__c = 1,
            	Control__c = 'ABC',
            	c2g__Dimension1__c = FFAdata.Dimension1.Id
            )); 
            newl.add(new c2g__codaJournalLineItem__c(
            	c2g__Journal__c = newj.Id,
            	c2g__Value__c = -123.00,
            	c2g__GeneralLedgerAccount__c = gla.Id,  
            	c2g__LineType__c = 'General Ledger Account', 
            	c2g__LineNumber__c = 2,
            	Control__c = 'XYZ',
            	c2g__Dimension1__c = FFAdata.Dimension1.Id
			));
            insert(newl);
            
            c2g.CODAAPICommon.Reference ref = new c2g.CODAAPICommon.Reference();
            ref.Id = newj.Id;
            c2g.CODAAPIJournal_9_0.PostJournal(null, ref);

			Test.stopTest();
		}
		
		String ctlkey = String.valueOf(gla.Id).substring(0,15) + ':' + String.valueOf(FFAdata.Dimension1.Id).substring(0,15) + ':' + 'ABC';
		System.debug(ctlkey);
		List<AccountScheduleControl__c> ctl = [select Id, Name, Balance__c, ScheduleKey__c, RecalcControlTotal__c, BeginDate__c, EndDate__c from AccountScheduleControl__c where ScheduleKey__c=:ctlkey ];
		// BLL1a coverage for new routines
		if (ctl.size()>0) {
			AccountScheduleControlProcess ascp = new AccountScheduleControlProcess();
			ascp.updateControlTotal(ctl[0].Id);
			ascp.updateRequestedControlTotals(ctl); // BLL2a new routine to call 
		}
		// BLL1a end
		for(AccountScheduleControl__c c:ctl) System.debug(c.ScheduleKey__c);
		System.Assert(ctl.size()>0, 'Did not find the control record');
		System.AssertEquals(123.00, ctl[0].Balance__c, 'Did not get expected control total');	
	}

}