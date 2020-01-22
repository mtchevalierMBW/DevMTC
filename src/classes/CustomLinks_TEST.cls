/**
 * CustomLinks_TEST
 * Tests: CustomLinks
 * Date: Sep 13, 2018
 * Programmer: Bryan Leaman
 *
 */
@isTest
private class CustomLinks_TEST {

	@TestSetup
	static void setupData(){
		List<CustomLinks__c> links = new List<CustomLinks__c>();
		links.add(new CustomLinks__c(Name='General', GroupLabel__c='General'));
		links.add(new CustomLinks__c(Name='Google', Link__c='http://www.google.com', GroupLabel__c='General'));
		links.add(new CustomLinks__c(Name='Yahoo', Link__c='http://www.yahoo.com', GroupLabel__c='Test2'));
		insert(links);
	}

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		CustomLinks cls = new CustomLinks();
		Component.Apex.outputPanel panel = cls.getCustomLinkPanels();
		System.assert(panel!=null, 'Did not get an output panel');
		System.assert(panel.childComponents.size()>0, 'Output panel has no child components');
	}

 
	// LexTest
	//---------------------------------------
	static testMethod void LexTest() {
		List<String> groups = CustomLinks.GetGroupNames();
		List<CustomLinks__c> linklist = CustomLinks.GetGroupLinks(groups[0]);
	}

}