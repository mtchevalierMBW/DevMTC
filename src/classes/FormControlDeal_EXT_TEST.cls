/**
 * FormControlDeal_EXT_TEST
 * Tests: FormControlDeal_EXT
 * Date: Sep 27, 2016
 * Programmer: Bryan Leaman
 *
 *	2017-01-02	B. Leaman	BLL1 Handle new restrictions on deal type & vehicle type.
 *	2017-01-25	B. Leaman	BLL2 Switch to managed field for Service mgr.
 *	2017-02-28	B. Leaman	BLL3 - changes to record types for commercial proposals.
 */
@isTest
private class FormControlDeal_EXT_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
       	TestHelper_MW th = new TestHelper_MW();
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
        insert(new dealer__FixedOperationsSettings__c(dealer__Repair_Order_Index__c=1));
        insert(new RetailDefaults__c(ProposalNumber__c=7));  

		Account a = th.getPersonAccount('1');
        
       	// Need service pmt types
       	List<ServicePaymentType__c> spts = new List<ServicePaymentType__c>();
       	spts.add(new ServicePaymentType__c(Name='IEN',Default_Labor_Rate__c=52,Description__c='Test IEN'));
       	spts.add(new ServicePaymentType__c(Name='IEU',Default_Labor_Rate__c=52,Description__c='Test IEU'));
       	spts.add(new ServicePaymentType__c(Name='IEO',Default_Labor_Rate__c=52,Description__c='Test IEO'));
       	insert(spts);
        
        // create vehicle 
        dealer__Vehicle_Inventory__c veh = new dealer__Vehicle_Inventory__c(
            Name='(TESTX) 2020 Toyota Future',
            New_Used_Other__c='Used', Division__c='Commercial', 
            dealer__Stock_Number__c='TESTX',
            dealer__VIN__c='11234567890TUVWXY',
            dealer__Year__c='2020', dealer__Make__c='Toyota', dealer__Model__c='Future',
            dealer__Mileage__c=123000
        );
        insert(veh);

        dealer__Sales_Up__c  dsp = new dealer__Sales_Up__c(
        	dealer__Lead_Date__c=System.Today(),
        	dealer__Lead_Status__c='Pending',
        	dealer__Lead_Type__c='List',
        	dealer__Source__c ='Pride',
        	Solution_Type__c ='Chassis/Conversion',
        	dealer__Customer_Account__c =a.id,
			dealer__Trade_Year__c = '2016',
			dealer__Trade_Make__c = 'Toyota',
			dealer__Trade_Model__c = 'Greatness'
		);
        insert dsp;

		Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();	// BLL1a
	
   	    dealer__Deal__c dd = new dealer__Deal__c(
   	    	Name = 'Test',
   	    	dealer__Deal_Type__c = 'Retail Vehicle Sale',	// BLL1a
  		    //BLL3d RecordTypeId = RcdTypes.get('Retail Vehicle Sale').getRecordTypeId(), // BLL1a
  		    RecordTypeId = RcdTypes.get('Retail').getRecordTypeId(), // BLL3a
   	    	dealer__Auto_Insurance_Agent__c='Test',
	    	dealer__Deal_ID__c ='Test',
	    	dealer__Sales_Lead__c = dsp.id,
	    	dealer__Buyer__c = a.id,
	    	dealer__Status__c ='Pending',
	    	dealer__Deal_Date__c =System.Today(),
	    	Proposed_Delivery_Date__c =System.Today(),
	    	dealer__Vehicle__c = veh.Id,
	    	dealer__Store_Location__c = FFAdata.DealerLocation.Id,
	    	TaxCalcDT__c = System.today(),
	    	Commission_Employee_1__c = UserInfo.getUserId(),
	    	dealer__Desk_Manager__c = UserInfo.getUserId(),
	    	dealer__F_I_Manager__c = UserInfo.getUserId(),
	    	Sales_Admin__c = UserInfo.getUserId(),
	    	dealer__Salesperson_1__c = UserInfo.getUserId(),
	    	//BLL2d Service_Manager__c = UserInfo.getUserId()
	    	dtmob__Service_Manager__c = UserInfo.getUserId()	// BLL2a
	    );
	    insert dd;

		// Add an ESC
		insert(new dealer__Service_Contract__c(Type__c='GAP', dealer__Car_Deal__c=dd.Id, dealer__Cost__c=1, dealer__Sale_Price__c=2));

		// Create a form
		insert(new dealer__Form__c(
			Name='Test form', dealer__Form_ID__c='Test form', 
			dealer__Impact_Code__c='fDFeMV57IWRlYWwubmFtZX1+fA==',
			dealer__FDF_Code__c='{!deal.Name}',
			dealer__Print_Type__c='Impact'
		));

	}

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();

			dealer__Deal__c dd = [select Id from dealer__Deal__c limit 1];
			dealer__Form__c df = [select Id from dealer__Form__c limit 1];
			
			Test.setCurrentPage(Page.FormFDFDataDeal); //Set the page for Test Method
			ApexPages.currentPage().getParameters().put('id', dd.id);
			ApexPages.currentPage().getParameters().put('fid', df.id);
			ApexPages.StandardController sc = new ApexPages.StandardController(dd);
			FormControlDeal_EXT ext = new FormControlDeal_EXT(sc);
			
			// run some extension methods
			List<String> ofn = ext.getObjectFieldNames();
			String ofns = ext.getObjectFieldNamesSimple();
			Component.Apex.OutputText prv = ext.getPreview();
			Component.Apex.OutputText fdf = ext.getFDF();
			Account buyer = ext.getBuyer();
			Account cobuyer = ext.getCoBuyer();
			Account tp1 = ext.getThirdParty1();
			Account tp2 = ext.getThirdParty2();
			Account tp3 = ext.getThirdParty3();
			dealer__Trade_In__c ti1 = ext.getTradeIn1();
			dealer__Trade_In__c ti2 = ext.getTradeIn2();
			dealer__Trade_In__c ti3 = ext.getTradeIn3();
			List<dealer__Discount_Rebate__c> dlist = ext.retrieveDiscountList();
			List<dealer__After_Market__c> amlist = ext.retrieveAftermarketList();
			List<dealer__Service_Contract__c> sclist = ext.retrieveServiceContractList();
			List<dealer__Trade_In__c> til = ext.tradeInList;
			String dn = ext.deal_name;
			dealer__Finance_Company__c f = ext.financeCo;
			ext.getIsPersonAccount();
			Integer esctypesize = ext.escType.size();
			Integer escpricesize = ext.escSalePrice.size();
			
		}
	}

}