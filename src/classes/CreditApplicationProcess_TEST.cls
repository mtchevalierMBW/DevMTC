/**
* CreditApplicationProcess_TEST
* Tests: CreditApplicationProcess, CreditApplicationTrigger
* Date: 2019-02-18
* Programmer: Bryan Leaman
* Project: W-000579
*
* Modifications:
*/
@isTest
private class CreditApplicationProcess_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupData() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		TestHelper_MW th = new TestHelper_MW();
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
		System.runAs(FFAdata.TestUser) {

			Account la = th.getBusinessAccount('2');
			dealer__Dealer_Location__c loc = new dealer__Dealer_Location__c(
				Id = FFAdata.DealerLocation.Id,
				dealer__Location_Account__c = la.Id
			);
			update(loc);
			
			Account a = th.getPersonAccount('1');
	        dealer__Sales_Up__c  dsp = new dealer__Sales_Up__c(
	        	dealer__Lead_Date__c=System.Today(),
	        	dealer__Lead_Status__c='Pending',
	        	dealer__Lead_Type__c='List',
	        	dealer__Source__c ='Pride',
	        	Solution_Type__c ='Equipment',
	        	dealer__Customer_Account__c =a.id
	        );
	        insert(dsp);
	
			Map<String, Schema.RecordTypeInfo> dealRcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();	// BLL11a
    	    dealer__Deal__c deal = new dealer__Deal__c(
    	    	Name = 'Test',
   	    		dealer__Deal_Type__c = 'Equipment',	
    	    	dealer__Auto_Insurance_Agent__c='Test',
    	    	dealer__Deal_ID__c ='Test',
    	    	dealer__Sales_Lead__c = dsp.id,
    	    	dealer__Status__c ='Pending',
    	    	dealer__Deal_Date__c =System.Today(),
    	    	Proposed_Delivery_Date__c =System.Today(),
    	    	dealer__Store_Location__c = FFAdata.DealerLocation.Id, 
    	    	dealer__Salesperson_1__c = UserInfo.getUserId()
    	    );
    	    insert(deal);
		}
	}

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();
			dealer__Deal__c deal = [select Id, Name, dealer__Sales_Lead__c from dealer__Deal__c limit 1];
			List<dealer__Credit_Application__c> creditapps = CreditApplicationProcess.ProposalCreditApplications(null);
			dealer__Credit_Application__c ca = new dealer__Credit_Application__c(Name='Test', Proposal__c=deal.Id, Solution_Opportunity__c=deal.dealer__Sales_Lead__c);
			Test.startTest();
			insert(ca);
			CreditApplicationProcess.markCreditAppReceived(deal.Id);
			CreditApplicationProcess.submitCreditAppRcd(ca.Id);
			CreditApplicationProcess.acceptCreditAppRcd(ca.Id);
			CreditApplicationProcess.deleteCreditAppRcd(ca.Id);
			Test.stopTest();
		}
	}

}