/**
 * FFA_RentalDepartment_TEST
 * Tests: FFA_RentalDepartment_TEST
 * Date: Mar 7, 2016
 * Programmer: Bryan Leaman
 *
 *	2016-08-02	B. Leaman	Need dealerteam base settings for rental tests.
 *	2016-09-08	B. Leaman	BLL1 - fix test for new validation rule - set both account and contact.
 *	2016-12-19	B. Leaman	BLL2 - change to not use "Returned" status - DealerTeam locks the record at that point.
 */
@isTest
private class FFA_RentalDepartment_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		dealer.TestClassUtil tc = new dealer.TestClassUtil();	// BLL1a   
	    tc.insertDMSSettings();   	// BLL1a
		TestHelper_MW.createBaseFFAData(FFAdata);

	    PostingTemplate__c pt = new PostingTemplate__c();
	    pt.Active__c =True;
	    pt.Object_Name__c='Rental Agreements';
	    insert pt;
	    
	    c2g__codaGeneralLedgerAccount__c cgd = new c2g__codaGeneralLedgerAccount__c();
	    cgd.c2g__ReportingCode__c ='12';
	    cgd.c2g__Type__c='Manual Journal';
	    cgd.Name='Test';
	    insert cgd;
	         
	    PostingTemplateEntryRule__c pte = new PostingTemplateEntryRule__c();
	    pte.Posting_Template__c=pt.id;
	    pte.Action__c='Sales Tax Payable'; // 'CA City Tax'; 
	    pte.General_Ledger_Account__c=cgd.id;
	    pte.Default_Memo__c='Test';
	    pte.Page_Order__c=12;
	    pte.FieldName__c = 'dealer__Customer_Pay_Amount__c';
	    insert pte;
	        	
	    PostingTemplateEntryRule__c pte2 = new PostingTemplateEntryRule__c();
	    pte2.Posting_Template__c=pt.id;
	    pte2.Action__c='Sales Tax Payable'; // 'CA City Tax'; 
	    pte2.General_Ledger_Account__c=cgd.id;
	    pte2.Default_Memo__c='Test';
	    pte2.Page_Order__c=12;
	    pte2.FieldName__c = 'dealer__Customer_Pay_Amount__c';
	    pte2.ReverseValue__c = true;
	    insert pte2;
	}

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
        	
        	Account acct1 = th.getPersonAccount('1');
        	Account pa = [select Id, Name, PersonContactId from Account where Id=:acct1.Id limit 1];
        	
	        dealer__Rental_Agreements__c ra = new dealer__Rental_Agreements__c();
	        ra.dealer__Contact__c = pa.PersonContactId;
	        ra.Account__c = pa.Id;	// BLL1a
	        //ra.Location__c = loc.Id;
	        ra.Location__c = FFAdata.DealerLocation.Id;
	        //BLL2d ra.dealer__Agreement_Status__c = 'Returned';
	        ra.dealer__Agreement_Status__c = 'Open'; 	// BLL2a
	        ra.dealer__Return_Date__c = Date.today(); 
	        ra.dealer__Date_DUE_In__c = ra.dealer__Return_Date__c; 
	        ra.dealer__Date_Out__c = ra.dealer__Return_Date__c.addDays(-1); 
	        ra.dealer__Drivers_Birthdate__c = Date.newInstance(1915, 1, 1);
	        ra.dealer__Drivers_Lic__c = 'n/a';
	        ra.dealer__Drivers_Lic_Exp__c = Date.today().addYears(2);
	        ra.dealer__Fuel_Charge_per_Gallon__c = 0;
	        ra.dealer__Insurer__c = 'See RentCentric';
	        ra.dealer__Return_Mileage__c = 101;
	        ra.dealer__Mileage_Out__c = ra.dealer__Return_Mileage__c - 100;
	        ra.dealer__Policy_No__c = 'See RentCentric';
	        ra.dealer__Policy_Expiration_Date__c = Date.today().addYears(1);
	        ra.dealer__Time_OUT__c = '06:00:00';
	        ra.dealer__Time_DUE_IN__c = '20:00:00';
	        ra.Rental_fee__c = 200.00;
	        ra.dealer__Excess_Miles_Fee__c = 1.00;
	        ra.Excess_Miles_Charge__c = 0.00;
	        ra.Pickup_Delivery_Fee__c = 0.00;
	        ra.dealer__Refueling_Fee__c = 0.00;
	        ra.dealer__Adjustment_Charges__c = 0.00;
	        ra.dealer__Discount__c = 0.00;
	        ra.dealer__Deposit_Amount__c = 0.00;
	        ra.Sales_Tax__c = 5.00;
	        ra.CountySalesTax__c = 4.00;
	        ra.CitySalesTax__c = 3.00;
	        ra.ThirdTierRentalTax__c = 2.00;
	        insert(ra);

		    FFA_RentalDepartment.postRental(ra.Id);
		    	
		}
	}

}