/**
 * FormManager_EXT_TEST
 * Tests: FormManager_EXT, FormControl_EXT
 * Date: Apr 21, 2016
 * Programmer: Bryan Leaman
 *
 *	2017-05-11	B. Leaman	BLL1 - increase coverage.
 *	2017-06-09	B. Leaman	BLL2 - coverage for new availability expression support.
 *
 * Code coverage:
 *	2017-06-09	FormManager_EXT		92% (90/97)
 */
@isTest
private class FormManager_EXT_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		//TestHelper_MW.createBaseFFAData(FFAdata);
		dealer__Form__c df = new dealer__Form__c(
			Name='TestForm', DocumentType__c='Commercial Quote', dealer__Active__c=true,
			dealer__DocumentContentId__c='TEST_123_ID', dealer__Print_Type__c='FDF', 
			dealer__FDF_Code__c='Test {!quote.Id}', dealer__Flatten__c=true,
			AvailabilityExpression__c='{!deal.Id!=null}',	// BLL2a
			dealer__Impact_Code__c=EncodingUtil.base64Encode(Blob.valueOf('Test {!quote.Id}'))	// BLL1a
		);
		insert(df);
	}

	// formManagerTest
	//---------------------------------------
	static testMethod void formManagerTest() {
		//FFAdata.refresh(); 
                        
		//System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
		
			CommercialQuote__c cq = new CommercialQuote__c(VIN__c='TestCQ123');

			// BLL1a
			insert(cq);	
			PageReference pgRef = Page.FormManagerCQ; 
			Test.setCurrentPage(pgRef); //Set the page for Test Method
			ApexPages.currentPage().getParameters().put('id', cq.id);
			FormManager_EXT fm = new FormManager_EXT(new ApexPages.standardController(cq));
			
			// BLL1a
			fm.getSObjFieldAsString(cq, 'VIN__c');
			fm.rtvFormList();
			Component.Apex.outputPanel op = fm.getFormsTableRows();	// BLL2a
			dealer__Form__c df = [select Id from dealer__Form__c limit 1];
			fm.formId = df.Id;
			fm.selectImpactForm();
			fm.getcompiled_form();
			fm.returnToDocument();
			// BLL1a end
		//}
	}


	// formControlTest
	//---------------------------------------
	static testMethod void formControlTest() {
		//FFAdata.refresh(); 
                        
		//System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
			dealer__Form__c form = [select Id from dealer__Form__c where dealer__Print_Type__c='FDF' limit 1];
			CommercialQuote__c cq = new CommercialQuote__c();
			FormControl_EXT fc = new FormControl_EXT(new ApexPages.standardController(cq));
			fc.form = fc.lookupForm(form.Id);
			fc.getFDF();
			
			
		//}
	}

}