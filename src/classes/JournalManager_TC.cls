/**
 * JournalManager_TC
 * Tests: JournalManager
 *
 * 2015-09-28   B. Leaman   BLL1 - increase coverage
 * 2015-10-20   J. Kuliis   JVK1 - re-written to not use existing data and leverage the TestHelper_MW
 * 2015-12-26   J. Kuljis   JVk2 - Update code coverage
 * 2016-04-27	B. Leaman	BLL2 IT#23367 - Allow changing dimension1 on screen.
 * 2017-01-12	B. Leaman	BLL3 - fix for new validation rule on journal date.
 * 2017-07-02	B. Leaman	BLL4 - Add LineType__c field to entry rules.
 * 2019-09-26	B. Leaman	BLL5 - Changes for DT 5.x (too manu soql queries)
 */
@isTest
private class JournalManager_TC {

	private static TestHelper_MW.FFATestData FFAData = new TestHelper_MW.FFATestData(); 
	@TestSetup
	static void makeData(){
		TestHelper_MW.createBaseFFAData(FFAData);

		System.runAs(FFAData.TestUser) {
		}
	}

    static testmethod Void Myunittest() {

		FFAData.refresh();

		System.runAs(FFAData.TestUser) {

        Account a = new Account();
        a.FirstName ='Bruce';
        a.LastName  ='Shwartz';
        a.AccountSource ='Dealer';
        insert a;
    
        // Set base dms data
        TestHelper_MW th = new TestHelper_MW();
        UtilityTestData_AC ut=new UtilityTestData_AC();
        //dealer__Dealer_Location__c loc = th.getDealerLocation('1');
/**BLL6     dealer__Dealer_Location__c ddl = new dealer__Dealer_Location__c();
        ddl.Name ='Test';
        ddl.dealer__City__c ='Test';
        ddl.dealer__Postal_Code__c='301352';
        ddl.dealer__State__c='Te';
        ddl.dealer__Company_Number__c='Test';
        //ddl.Financial_Force_Dimension_1__c=
        ddl.dealer__Service_Director__c =Userinfo.getuserid();
        insert ddl;
        // Set the User Data
        Profile p = [select id from profile where name='System Administrator'];

        User u = new User();
        u.FirstName = 'Dealer';
        u.LastName = 'Team';
        u.Alias = 'DTAdmin';
        u.Username = 'dealerteam@example.com';
        u.Email = 'dealerteam@example.com';
        u.CommunityNickname = 'ffd';
        u.Phone = '555.555.5555';
        u.IsActive = true;
        u.ProfileId = p.Id;
        u.TimeZoneSidKey = 'America/New_York';
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'ISO-8859-1';
        u.LanguageLocaleKey = 'en_US';
        u.Title = 'Head of Testing';
        u.CompanyName = 'WMK Inc.';
        u.Division = ddl.dealer__Company_Number__c;

        insert u;

        System.runAs(u) {
**/
        // Setup the FFA Data
      //  Map<String,c2g__codaGeneralLedgerAccount__c> GLAMap = FFATests.createGLAccounts();
      c2g__codaGeneralLedgerAccount__c gla = new c2g__codaGeneralLedgerAccount__c();
             gla.c2g__ReportingCode__c ='12';
             gla.c2g__Type__c='Manual Journal';
             gla.Name='Test';
             insert gla; 
      
	  /** BLL6
        c2g__codaCompany__c CurrentCompany = FFATests.createFFACompany('FinancialForce', FFATests.createFFAQueue(u.Id).Id);
        FFATests.createUserCompany(CurrentCompany.Id, u.Id);
        c2g__codaAccountingCurrency__c HomeCurrency = FFATests.createHomeCurrency('USD');
        c2g__codaPeriod__c CurrentPeriod = FFATests.createYearPeriods();
        c2g__codaDimension1__c Dimension = FFATests.createDimension();
	  **/
	  	c2g__codaCompany__c CurrentCompany = FFAData.CurrentCompany;
		c2g__codaAccountingCurrency__c HomeCurrency = FFAData.HomeCurrency;
		c2g__codaPeriod__c CurrentPeriod = FFAData.CurrentPeriod;
		c2g__codaDimension1__c Dimension = FFAData.Dimension1;
		dealer__Dealer_Location__c ddl = FFAData.DealerLocation;

        ddl.Financial_Force_Dimension_1__c = Dimension.Id;
        ddl.Company__c = CurrentCompany.Id;

        update ddl;


        // Generate the DealerTeam data for the Journal 
        PostingTemplate__c  pt      = th.getPostingTemplate();
        dealer__Sales_Up__c salesup = th.getSalesUp(a.Id);
       // dealer__Deal__c     deal    = th.getDealBasic(salesup.Id, loc.Id, a.Id);
       dealer__Deal__c     deal = ut.getDealBasic(salesup.Id,ddl.Id,a.Id);
        dealer__Vehicle_Inventory__c vehicle = th.getVehicleInventory('1');

  
        
  dealer__Trade_In__c dti = new dealer__Trade_In__c();
  dti.dealer__Odometer_at_Trade_In__c=11;
  dti.Name='Test';
  dti.Sale_Type__c='Used';
  dti.dealer__Pay_Off_Amount__c=1;
  dti.dealer__Trade_Allowance__c=11;
  dti.dealer__Car_Deal__c=Deal.Id;
  dti.Chassis_Allowance__c=11;
  dti.dealer__ACV__c=11;
  dti.dealer__VIN__c='Test';
  dti.dealer__Stock_Number__c='0123';
  insert dti;
  
	c2g__codaPeriod__c prd = [select c2g__EndDate__c from c2g__codaPeriod__c where Id=:CurrentPeriod.Id];	// BLL3a        

        Posting_Entry__c pe = new Posting_Entry__c();
            pe.Location__c=ddl.Id;          
            pe.Posting_Template__c=pt.Id;
            pe.Proposal__c=deal.Id;
            pe.Stock__c=vehicle.Id;
            insert pe;

        // Generate the Journal data
      c2g__codaJournal__c cj = new c2g__codaJournal__c();
            //BLL3d cj.c2g__JournalDate__c =system.Today();
            cj.c2g__JournalDate__c = prd.c2g__EndDate__c;	// BLL3a
            cj.c2g__Type__c='Manual Journal';
           cj.c2g__OwnerCompany__c =CurrentCompany.id;
           cj.c2g__Type__c='Manual Journal';
           cj.c2g__JournalCurrency__c = FFAData.HomeCurrency.Id;
            cj.c2g__Period__c= CurrentPeriod.Id;   
            insert cj;

        // Line data
        c2g__codaJournalLineItem__c ccj = new c2g__codaJournalLineItem__c();
            ccj.c2g__Journal__c =cj.id;
            ccj.c2g__LineType__c='General Ledger Account';
            ccj.c2g__GeneralLedgerAccount__c = gla.Id;
            ccj.c2g__Value__c =12; 
            ccj.c2g__Dimension1__c = Dimension.Id;             
            insert ccj; 

        // Posting Template Entry
        PostingTemplateEntryRule__c pte = new PostingTemplateEntryRule__c();
            pte.Posting_Template__c=pt.id;
            pte.Action__c='Sales Tax Payable'; 
            pte.General_Ledger_Account__c=gla.Id;
            pte.Default_Memo__c='Tax';
            pte.Page_Order__c=12;
            pte.LineType__c='General Ledger Account';	// BLL4a
            insert pte;
            
  dealer__Service_Contract__c sc2= new dealer__Service_Contract__c();
            sc2.dealer__Deductable__c=0.00;
            sc2.Type__c='GAC';
            sc2.dealer__Car_Deal__c =deal.id;
            insert sc2;
            sc2.Type__c='type';
            Update Sc2;
             
            PostingTemplate__c po= new PostingTemplate__c();
            po.Name='poname';
            po.Object_Name__c='Proposal';
            insert po; 
            
            PostingTemplateEntryRule__c ptr= new PostingTemplateEntryRule__c();
            ptr.FieldName__c='filed';
            ptr.Posting_Template__c=po.id;
            ptr.Action__c='Commission Accrual';
            ptr.LineType__c='General Ledger Account';	// BLL4a
            insert ptr;
         
      
             List<dealer__Service_Contract__c> protectionProd =new List<dealer__Service_Contract__c>();
            protectionProd.add(sc2);
            
            
        // Actual Test
          Test.startTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(pe);
            ApexPages.currentPage().getParameters().put('id', pe.id);
            JournalManager  jm = new JournalManager(new ApexPages.StandardController(pe));
            jm.lookupTemplateRules();
            jm.entry.Posting_Template__c=pt.id;
            jm.lookupTemplateRules();
            jm.entry.Posting_Template__c=Null;
            jm.lookupTemplateRules();
            jm.entryId ='Test';
            jm.dim ='Test';
            jm.getLines();
            jm.loadProposalData();
            jm.proposal.dealer__Store_Location__c=ddl.id;
            jm.loadProposalData();
            jm.proposal.dealer__Store_Location__c=Null;
            jm.loadProposalData();
            //BLL5d jm.createJournal();
            jm.tBalance =1;
            jm.createJournal();

            // JVK2
            jm.credit(22.20);
            jm.credit(null);
            jm.debit(22.20);
            jm.debit(null);
            jm.nonNull(20.12);  
            jm.nonNull(null);
            // End JVK2

            JournalManager.lines jml = new JournalManager.lines();
            jml.amount  = 12.12;
            jml.action ='Account Receivable';
            jml.memo ='Test';
            jml.accountName  ='Test';
            //BLL2d jml.division ='12345';
            jml.jline.c2g__Dimension1__c = Dimension.Id;	// BLL2a
            jml.StockNbr='Test';
            jml.VIN='Test';
            jml.Description='Description';
            jm.calcLines();  // BLL1a
            jm.createJournal(); // BLL1a
jm.actionTotal('S');
            jm.save(); // JVK2

            List<PostingTemplateEntryRule__c> rules = [Select Id, Name, Action__c, General_Ledger_Account__c, General_Ledger_Account__r.Name, Default_Memo__c, LineType__c	// BLL4c add line type 
                                                    from PostingTemplateEntryRule__c limit 1];
            List<c2g__codaGeneralLedgerAccount__c> gl = [Select Id, Name from c2g__codaGeneralLedgerAccount__c limit 1];
            jm.processCommissions(rules[0], gl[0]);
            
            
     
          
            
           jm.processProtection(protectionProd,ptr,'s',gla);
         
            dealer__Dealer_Trade__c trade= new dealer__Dealer_Trade__c();
            trade.dealer__Salesperson__c=Userinfo.getUserID();
            insert trade;
        Test.stopTest();   

        }

    }
   
}