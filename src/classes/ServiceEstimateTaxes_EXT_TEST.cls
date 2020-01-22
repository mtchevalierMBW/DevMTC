/**
 * ServiceEstimateTaxes_EXT_TEST
 * Tests: ServiceEstimateTaxes_EXT_TEST
 * Date: Jan 30, 2018
 * Programmer: Bryan Leaman
 *
 *	2018-05-25	B. Leaman	BLL1 - use valid payment types instead of 'C', 'I' or 'W'.
 */
@isTest
private class ServiceEstimateTaxes_EXT_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW th = new TestHelper_MW();
		TestHelper_MW.createBaseFFAData(FFAdata);
		//FFAdata.refresh(); 
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
        
        // create a service estimate
        Account p = th.getPersonAccount('1');
        dealer__Service_Estimate__c est = new dealer__Service_Estimate__c(
        	dealer__Customer__c = p.Id,
        	dealer__Store_Location__c = FFAdata.DealerLocation.Id,
        	dealer__Status__c = 'Open',
        	TaxResults_JSON__c = '{"TotalExemption":0,"TotalDiscount":0,"TotalAmt":30,"TaxableAmt":30,"Tax":2.03,"DocumentName":"SE-006818","byLine":[{"TaxableAmt":30.00,"Tax":2.03,"LineNo":"1"}],"byJurisdiction":[{"TaxType":"Sales","TaxRate":0.057500,"TaxableAmt":30.00,"Tax":1.73,"JurisdictionType":"State","JurisdictionCode":"39","Jurisdiction":"OHIO"},{"TaxType":"Sales","TaxRate":0.010000,"TaxableAmt":30.00,"Tax":0.30,"JurisdictionType":"County","JurisdictionCode":"153","Jurisdiction":"SUMMIT"}]}'
        );
        insert(est);
        
        // BLL1a
        DescribeFieldResult lbrtype = dealer__Service_Estimate_Line__c.dealer__Labor_Type__c.getDescribe();
		List<Schema.PicklistEntry> ltplvs = lbrtype.getPicklistValues();
		// ltplvs[n].getLabel(), ltplvs[n].getValue()
		String customer_labor_type;
		String warranty_labor_type;
		for(Integer i=0; i<ltplvs.size(); i++) {
			if (ltplvs[i].getValue().length()>1) {
				if (String.isBlank(customer_labor_type)) customer_labor_type = ltplvs[i].getValue();
				else if (String.isBlank(warranty_labor_type)) warranty_labor_type = ltplvs[i].getValue();
			}
		}

        // Service Payment
        List<ServicePaymentType__c> spts = new List<ServicePaymentType__c>();    
        spts.add(new ServicePaymentType__c (
			Name = customer_labor_type,
			Payment_Type__c = 'C',
			Default_Labor_Rate__c = 70
		));
        spts.add(new ServicePaymentType__c (
			Name = warranty_labor_type,
			Payment_Type__c = 'W',   
			Default_Labor_Rate__c = 90
		));
        insert spts;
		// BLL1a end 
		        
        dealer__StandardOpCode__c sop = new dealer__StandardOpCode__c(
        	Name = 'Test_operation',
        	dealer__Active__c = true,
        	dealer__Pay_Type__c = 'C',
        	dealer__Labor_Rate__c = 50,
        	OperationTaxType__c = 'Non-mobility'
        );
        insert(sop);
        
        dealer__Service_Estimate_Line__c estl = new dealer__Service_Estimate_Line__c(
        	dealer__Service_Estimate__c = est.Id,
        	dealer__Labor_Operation__c = sop.Id,
        	dealer__Labor__c = 5,
        	dealer__Labor_Type__c = spts[0].Name 
        );
        insert(estl);
	}

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();

			dealer__Service_Estimate__c est = [select id, Name from dealer__Service_Estimate__c limit 1];

			Test.startTest();

			PageReference pgRef = Page.ServiceEstimateTaxes;
			Test.setCurrentPage(pgRef); //Set the page for Test Method
			ApexPages.currentPage().getParameters().put('id', est.id);
			ApexPages.currentPage().getParameters().put('retURL', '/');
			ApexPages.StandardController sc = new ApexPages.StandardController(est);
			ServiceEstimateTaxes_EXT esttax = new ServiceEstimateTaxes_EXT(sc);
			
			List<String> j = esttax.Jurisdictions;
			List<String> jt = esttax.JurisdictionTypes;
			List<Decimal> a = esttax.TaxableAmounts;
			List<Decimal> r = esttax.TaxPcts;
			List<Decimal> t = esttax.TaxAmts;
			Decimal tt = esttax.TotalTax;
			boolean d = esttax.debug;
			boolean needrecalc = esttax.getNeedToCalculateTaxes();
			
			// test remote action
	        Test.setMock(WebServiceMock.class, new AvaTaxRequestMock());
			ServiceEstimateTaxes_EXT.CalculateTaxes((String) est.id);
			
			Test.stopTest();
		}
	}

}