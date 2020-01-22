/**
 * SObjectHistory_EXT_TEST
 * Tests: SObjectHistory_EXT
 * Programmer: Bryan Leaman
 * Date: 2015-11-02
 * 
 * Modifications:
 *	2019-12-03	B. Leaman	Ignore failure to find existing history (in a fresh sandbox).
 */

@isTest
private class SObjectHistory_EXT_TEST {

    static testMethod void standardObjectHistory() {
        TestHelper_MW th = new TestHelper_MW();
        
        Account a = th.getPersonAccount('1');
        a.dealer__Active__c = 'No';
        update(a);
        a.dealer__Active__c = 'Yes';
        update(a);
        
        // Just need std controller on an object that tracks history
        ApexPages.StandardController stdController = new ApexPages.StandardController(a);
        Test.startTest();
        SObjectHistory_EXT hist_ext = new SObjectHistory_EXT(stdController);
        List<SObjectHistory_EXT.SObjectHistoryLine> lines = hist_ext.getHistoryLines();
        Test.stopTest();
    }

    static testMethod void customObjectHistory() {
        TestHelper_MW th = new TestHelper_MW();
        
        dealer__Dealer_Location__c loc = th.getDealerLocation('1');
        loc.AutoAssignRetail__c = true;
        update(loc);
        loc.AutoAssignRetail__c = false;
        update(loc);
        
        // Just need std controller on an object that tracks history
        ApexPages.StandardController stdController = new ApexPages.StandardController(loc);
        Test.startTest();
        SObjectHistory_EXT hist_ext = new SObjectHistory_EXT(stdController);
        List<SObjectHistory_EXT.SObjectHistoryLine> lines = hist_ext.getHistoryLines();
        Test.stopTest();
    }
    
  // Need some actual history to run the controller through its paces
  @isTest(seeAllData=true)
  static void usingExistingData() {
	List<AggregateResult> ra = [select Count(Id), AccountId from AccountHistory Group by AccountId Order by Count(Id) desc limit 20];
	if (ra.size()>0) {
		Id aid = (Id) ra[0].get('AccountId');
		List<Account> accts = [select Id, Name from Account where Id=:aid];
		Account a = accts.size()>0 ? accts[0] : null;
		if (a!=null) {
    		ApexPages.StandardController stdController = new ApexPages.StandardController(a);
    		SObjectHistory_EXT hist_ext = new SObjectHistory_EXT(stdController);
    		List<SObjectHistory_EXT.SObjectHistoryLine> acctLines = hist_ext.getHistoryLines();
		}
	}


	List<AggregateResult> rl = [select Count(Id), ParentId from dealer__Dealer_Location__History Group by ParentId Order by Count(Id) desc limit 2];
	if (rl.size()>0) {
		Id lid = (Id) rl[0].get('ParentId');
		List<dealer__Dealer_Location__c> locs = [select Id, Name from dealer__Dealer_Location__c where Id=:lid];
		dealer__Dealer_Location__c loc = locs.size()>0 ? locs[0] : null;
		if (loc!=null) {
    		ApexPages.StandardController stdController = new ApexPages.StandardController(loc);
    		SObjectHistory_EXT hist_ext = new SObjectHistory_EXT(stdController);
    		List<SObjectHistory_EXT.SObjectHistoryLine> locLines = hist_ext.getHistoryLines();
		}
	}
  }


    
}