/**
 * upload_Link_Proposal_to_SLOP_TEST
 * Tests: upload_Link_Proposal_to_SLOP
 * Date: Mar 28, 2016
 * Programmer: Bryan Leaman
 *
 */
@isTest
private class upload_Link_Proposal_to_SLOP_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		MW_TriggerControls__c LinkProposalToSlop = new MW_TriggerControls__c(Name='LinkProposalToSlop',Enabled__c=true);
		insert(LinkProposalToSlop);
	}

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
        	Account a = th.getPersonAccount('1');

        	dealer__Sales_Up__c slop = new dealer__Sales_Up__c(
        		Name='Test SLOP', 
        		Legacy_ID__c='TestXYZ123',
        		dealer__Salesperson_1__c=FFAdata.TestUser.Id,
        		OwnerId=FFAdata.TestUser.Id,
        		dealer__Customer_Account__c=a.Id,
        		dealer__Lead_Status__c='Pending',
				dealer__Lead_Type__c='List',
				dealer__Source__c ='Pridexyz',
				Solution_Type__c ='Rental'
        	);
        	insert(slop);

			Test.startTest();
			
			dealer__Deal__c d = new dealer__Deal__c(
				legacy_Opportunity__c=slop.Legacy_ID__c,
				Name = 'Test',
				dealer__Auto_Insurance_Agent__c='Test',
				dealer__Deal_ID__c ='Test',
				//dealer__Sales_Lead__c = slop.Id,
				dealer__Status__c ='Pending',
				dealer__Deal_Date__c =System.Today(),
				Proposed_Delivery_Date__c =System.Today()
			);
			insert(d);
			
			Test.stopTest();
			dealer__Deal__c resultDeal = [
				select Id, Name, dealer__Sales_Lead__c 
				from dealer__Deal__c
				where Id=:d.Id
			];
			
			System.assertEquals(slop.Id, resultDeal.dealer__Sales_Lead__c, 'Did not attach Deal to Slop');
			
		}
	}

}