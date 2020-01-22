/**
 * RentalAgreementMW_EXT_TEST
 * Tests: RentalAgreementMW_EXT
 * 
 *  2015-11-17  B. Leaman  BLL1 add new test method to increase coverage%; also someone's removal of SeeAllData=true and
 *              creating a posting template was incomplete, causing drastically reduced code coverage - correcting.
 *  2016-08-03  B. Leaman   BLL2 insert DMSSettings to avoid error due to new requirement in DealerTeam.
 *	2016-08-23	B. Leaman	BLL3 specify related account for the contact - it's required on insert rather than derived from contact.
 *	2016-11-23	B. Leaman	BLL4 - custom contact field so it can be controlled by the account lookup
 *	2016-12-19	B. Leaman	BLL5 - Don't use "Returned" status - DealerTeam imposed a lockdown of the record. 
 *	2018-12-11	B. Leaman	W-000513 BLL6 changes for lightning interface
 */
@isTest
private with sharing class RentalAgreementMW_EXT_TEST {

    private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); // BLL1
  @testSetup
  static void setupFFA() {
    TestHelper_MW.createBaseFFAData(FFAdata);
    dealer.TestClassUtil tc = new dealer.TestClassUtil();   // BLL2a
    tc.insertDMSSettings();     // BLL2a
  }

  @isTest
  private static void UseControllerExtension() {
    TestHelper_MW th = new TestHelper_MW();
    FFAdata.refresh();
       //dealer__Dealer_Location__c dl = th.getDealerLocation('1');
       //FFAdata.TestUser.Division = dl.dealer__Company_Number__c;
       //update(FFAdata.TestUser);
       
    System.runAs(FFAdata.TestUser) {
       
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
    
    //c2g__codaCompany__c cdc = new c2g__codaCompany__c();
    //cdc.Name ='Test';
    ////cdc.c2g__TaxCode__c=123;
    //cdc.c2g__CODABaseDate1__c='Test';
    //cdc.c2g__CODADaysOffset1__c=12;
    //insert cdc;
    
    /*c2g__codaJournal__c cj = new c2g__codaJournal__c();
    cj.c2g__JournalDate__c =system.Today();
    cj.c2g__Type__c='Manual Journal';
    cj.c2g__OwnerCompany__c =cdc.id;
    insert cj;*/

       //dealer__Dealer_Location__c loc = th.getDealerLocation('1');
       Account acct1 = th.getBusinessAccount('1');
     
       //RecordType businessRt = [select Id, Name from RecordType where Name like 'Business%' limit 1];
       //Account acct1 = new Account(RecordTypeId=businessRt.Id, Name='Rental account', BillingState='OH', BillingPostalCode='44641');
       //insert(acct1);
       Contact cont1 = new Contact(FirstName = 'Rental', LastName='Account', AccountId=acct1.Id);
       insert(cont1);
     
       // TODO: Set up a new location with division, region, company, etc.
       // TODO: Update current account to specify the test location
       //dealer__Dealer_Location__c loc = [select Id, Name, Company__c from dealer__Dealer_Location__c where Company__c!=null limit 1];

       // Third party payor
       //RecordType payorRt = [select Id, Name from RecordType where Name like 'Third%' limit 1];
       //Account payor1 = new Account(RecordTypeId=payorRt.Id, Name='Payor Test Account', BillingState='OH', BillingPostalCode='44641');
       //insert(payor1);
       Account payor1 = th.getThirdPartyAccount('1');

       Test.startTest();
     
       dealer__Rental_Agreements__c ra = new dealer__Rental_Agreements__c();
        //BLL4d ra.dealer__Contact__c = cont1.Id;
        ra.CustomerContact__c = cont1.Id;	// BLL4a
        ra.Account__c = acct1.Id;	// BLL3a
        //ra.Location__c = loc.Id;
        ra.Location__c = FFAdata.DealerLocation.Id;
        //BLL5d ra.dealer__Agreement_Status__c = 'Returned';	
        ra.dealer__Agreement_Status__c = 'Open';	// BLL5a
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

       PageReference pgRef = Page.RentalAgreementMW; 
       Test.setCurrentPage(pgRef); //Set the page for Test Method
       ApexPages.currentPage().getParameters().put('id', ra.id);
       ApexPages.currentPage().getParameters().put('mode', 'view');
       ApexPages.currentPage().getParameters().put('retURL', '/');
     
       ApexPages.StandardController raController = new ApexPages.StandardController(ra);
       RentalAgreementMW_EXT ra_ext = new RentalAgreementMW_EXT(raController);
       ra_ext.updateTotals();
       ra_ext.changeContact();
       ra_ext.changeAccount();
       ra_ext.save();
       ra_ext.getCanEdit();
       ra_ext.getCanPost();
       ra_ext.post();
    // ra_ext.getFFCompany(cdc);
       //BLL6d ApexPages.PageReference p1 = ra_ext.backToList();
       ApexPages.PageReference p2 = ra_ext.editMode();
       ApexPages.PageReference p3 = ra_ext.displayMode();

       // Specify a payor (for RentalAgreements_MW trigger test coverage)
       dealer__Rental_Agreements__c ra2 = new dealer__Rental_Agreements__c();
        //BLL4d ra2.dealer__Contact__c = cont1.Id;
        ra2.CustomerContact__c = cont1.Id;	// BLL4a
        ra2.Account__c = acct1.Id;	// BLL3a
        ra2.ThirdPartyPayor__c = payor1.Id;
        //ra2.Location__c = loc.Id;
        ra2.Location__c = FFAdata.DealerLocation.Id;
        //BLL5d ra2.dealer__Agreement_Status__c = 'Returned';
        ra2.dealer__Agreement_Status__c = 'Open';	// BLL5a
        ra2.dealer__Return_Date__c = Date.today(); 
        ra2.dealer__Date_DUE_In__c = ra.dealer__Return_Date__c; 
        ra2.dealer__Date_Out__c = ra.dealer__Return_Date__c.addDays(-1); 
        ra2.dealer__Drivers_Birthdate__c = Date.newInstance(1915, 1, 1);
        ra2.dealer__Drivers_Lic__c = 'n/a';
        ra2.dealer__Drivers_Lic_Exp__c = Date.today().addYears(2);
        ra2.dealer__Fuel_Charge_per_Gallon__c = 0;
        ra2.dealer__Insurer__c = 'See RentCentric';
        ra2.dealer__Return_Mileage__c = 101;
        ra2.dealer__Mileage_Out__c = ra2.dealer__Return_Mileage__c - 100;
        ra2.dealer__Policy_No__c = 'See RentCentric';
        ra2.dealer__Policy_Expiration_Date__c = Date.today().addYears(1);
        ra2.dealer__Time_OUT__c = '06:00:00';
        ra2.dealer__Time_DUE_IN__c = '20:00:00';
        ra2.Rental_fee__c = 200.00;
        ra2.dealer__Excess_Miles_Fee__c = 1.00;
        ra2.Excess_Miles_Charge__c = 0.00;
        ra2.Pickup_Delivery_Fee__c = 0.00;
        ra2.dealer__Refueling_Fee__c = 0.00;
        ra2.dealer__Adjustment_Charges__c = 0.00;
        ra2.dealer__Discount__c = 0.00;
        ra2.dealer__Deposit_Amount__c = 0.00;
        ra2.Sales_Tax__c = 0.00;
        ra2.CountySalesTax__c = 0.00;
        ra2.CitySalesTax__c = 0.00;
        ra2.ThirdTierRentalTax__c = 0.00;
    insert(ra2);

    ra_ext.defaultLocation();
    //ra_ext.accountName='Test';
    ra_ext.validAgreement();

    Test.stopTest();
    
    dealer__Rental_Agreements__c raafter = [
           select Id, dealer__Agreement_Status__c 
           from dealer__Rental_Agreements__c 
           where Id=:ra.Id 
           limit 1
    ];
    //System.assertEquals('Paid', raafter.dealer__Agreement_Status__c, 'After posting, agreement was not listed as "Paid"');
    System.assert(raafter.dealer__Agreement_Status__c!=null, 'After posting, agreement still had no status');

    dealer__Rental_Agreements__c ra2after = [
           select Id, dealer__Customer_Pay_Amount__c 
           from dealer__Rental_Agreements__c 
           where Id=:ra2.Id 
           limit 1
    ];
    System.assertEquals(0.00,ra2after.dealer__Customer_Pay_Amount__c, 'Customer pay amount is not 0.00 with 3rd party payor!');
    }

  }

  private static testMethod void testNewAgreement() {
    TestHelper_MW th = new TestHelper_MW();
    FFAdata.refresh();
    System.runAs(FFAdata.TestUser) {
        PageReference pgRef = Page.RentalAgreementMW; 
        Test.setCurrentPage(pgRef); //Set the page for Test Method
        ApexPages.currentPage().getParameters().put('mode', 'view');
        ApexPages.currentPage().getParameters().put('retURL', '/');
        dealer__Rental_Agreements__c ra = new dealer__Rental_Agreements__c();
        ApexPages.StandardController raController = new ApexPages.StandardController(ra);
        RentalAgreementMW_EXT ra_ext = new RentalAgreementMW_EXT(raController);
    }    
  }

}