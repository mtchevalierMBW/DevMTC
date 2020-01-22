/**
 * Deal_MBW2_Test
 * Tests: Deal_MBW2
 * Date: Jan 26, 2017
 * Programmer: Bryan Leaman
 *
 *	2017-06-05	B. Leaman	BLL1 - new method for forms, add coverage.
 *	2017-06-09	B. Leaman	BLL2 - mobilityguard powertrain, lease & sub-prime loan.
 *	2017-08-15	B. Leaman	BLL3 - lease calculator
 *	2018-01-03	B. Leaman	BLL4 - increase coverage
 *	// 2018-02-07	B. Leaman	BLL5 - Process builder causing error in FromNewSolOpp test.
 *	2018-04-24	B. Leaman	BLL6 - increase coverage.
 *	2018-08-28	B. Leaman	BLL7 - reduce SOQL queries in unitTest2 and testRemotes3.
 *	2018-12-11	B. Leaman	W-000519 BLL8 - add test to get purchase agreement form, 
 *							also adj soql over proposal obj for required fields in controller ext.
 *	2019-01-17	B. Leaman	W-000553 BLL9 - catch up on test coverage with latest change.
 *	2019-03-04	B. Leaman	W-000579 BLL10 - F&I moved to lightning component; new constructor for Alex's project
 *  2019-04-02  A. Miller   W-000582 AMM10 - Update to handle the part kit favorite click in remoting  
 * 
 * Routines still not tested:
 *		some commercial logic
 * 		savePartOnProposal()
 *		selectProduct() with escSelectedId!=null
 *		addKitToProposal with addKitId kit consisting of parts
 *		updateEquipmentSale & updateEquipmentQty with valid parms
 *		remote updateServiceContractSale(String scSale)
 *		remote toggleTaxExempt(String t) 
 *		remote compileFDF(String fd) 
 */
@isTest
private class Deal_MBW2_Test {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 
	// BLL8
	private static List<String> extraFields = new List<String> {
		'dealer__Vehicle__r.dealer__VIN__c',
        'dealer__Vehicle__r.Conversion__c',
        'dealer__Vehicle__r.Conversion__r.dealer__Description__c',
        'dealer__Vehicle__r.New_Used_Other__c',
        'dealer__Vehicle__r.Unit_Type__c',
        'dealer__Vehicle__r.dealer__Body_Type__c',
        'dealer__Vehicle__r.dealer__Fuel_Type__c',
        'dealer__Vehicle__r.dealer__Mileage__c',
        'dealer__Vehicle__r.Name',
        'dealer__Finance_Institution_Account__r.Name',
        'dealer__Finance_Institution_Account__r.dealer__Bank_Address__c',
        'dealer__Finance_Institution_Account__r.dealer__Bank_City__c',
        'dealer__Finance_Institution_Account__r.dealer__Bank_State__c',
        'dealer__Finance_Institution_Account__r.dealer__Bank_Zip__c',
        'dealer__Finance_Institution_Account__r.FinanceAccount__c',
        'dealer__Co_Buyer__r.FirstName',
        'dealer__Co_Buyer__r.MiddleName',
        'dealer__Co_Buyer__r.LastName',
        'dealer__Service_Vehicle__r.dealer__Last_Odometer__c',
        'dealer__Vehicle__r.dealer__Vehicle_Cost__c',
        'dealer__Vehicle__r.Conversion_Cost__c',
        'dealer__Service_Vehicle__r.dealer__Make__c',
        'dealer__Service_Vehicle__r.dealer__Carline__c',
        'dealer__Service_Vehicle__r.dealer__Trim_Level__c',
        'dealer__Service_Vehicle__r.dealer__Year__c',
        'dealer__Service_Vehicle__r.dealer__Ext_Color__c',
        'dealer__Service_Vehicle__r.dealer__Body_Type__c',
        'dealer__Service_Vehicle__r.dealer__VIN__c'
	};
	// BLL8 end

	@testSetup
	static void setupFFA() {
		TestHelper_MW th = new TestHelper_MW();

		TestHelper_MW.createBaseFFAData(FFAdata);
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
		insert(new MW_TriggerControls__c(Name='SalesUpUpdateContactInfo',Enabled__c=false));
        dealer__FixedOperationsSettings__c fixedOpsSettings = new dealer__FixedOperationsSettings__c(
        	dealer__Repair_Order_Index__c=1
        );
        insert(fixedOpsSettings); 
        RetailDefaults__c rtd = new RetailDefaults__c(ProposalNumber__c=7);  
        insert(rtd);  

		insert(new MW_TriggerControls__c(Name='NoCommVehOnDeal',Enabled__c=false));
		insert(new MW_TriggerControls__c(Name='RestrictVehicleLocation',Enabled__c=false));
		insert(new MW_TriggerControls__c(Name='UpdateDealVehCosts',Enabled__c=false));
		insert(new MW_TriggerControls__c(Name='AccountLastSale',Enabled__c=false));
		insert(new MW_TriggerControls__c(Name='ProposalPostTax',Enabled__c=false));
		insert(new MW_TriggerControls__c(Name='AvataxDeal',Enabled__c=false));
	
		System.runAs(FFAdata.TestUser) {

			Account a = th.getPersonAccount('1');
			Account v = th.getVendorAccount('1');
        
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
	
			Map<String, Schema.RecordTypeInfo> supRcdTypes = Schema.SObjectType.dealer__Sales_Up__c.getRecordTypeInfosByName();	// BLL11a
	        dealer__Sales_Up__c  dsp = new dealer__Sales_Up__c();
	        dsp.dealer__Lead_Date__c=System.Today();
	        dsp.dealer__Lead_Status__c='Pending';
	        dsp.dealer__Lead_Type__c='List';
	        dsp.dealer__Source__c ='Pride';
	        dsp.Solution_Type__c ='Chassis/Conversion';
	        dsp.dealer__Customer_Account__c =a.id;
	        dsp.RecordTypeId = supRcdTypes.get('Commercial').getRecordTypeId();
	        insert dsp;
	
			Map<String, Schema.RecordTypeInfo> dealRcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();	// BLL11a
    	    dealer__Deal__c dd = new dealer__Deal__c();
    	    dd.Name = 'Test';
    	    dd.RecordTypeId = dealRcdTypes.get('Commercial').getRecordTypeId();
   	    	dd.dealer__Deal_Type__c = 'Chassis/Conversion';	
    	    dd.dealer__Auto_Insurance_Agent__c='Test';
    	    dd.dealer__Deal_ID__c ='Test';
    	    dd.dealer__Sales_Lead__c = dsp.id;
    	    dd.dealer__Status__c ='Pending';
    	    dd.dealer__Deal_Date__c =System.Today();
    	    dd.Proposed_Delivery_Date__c =System.Today();
    	    dd.dealer__Vehicle__c = veh.Id;	
    	    dd.dealer__Store_Location__c = FFAdata.DealerLocation.Id; 
    	    dd.dealer__Salesperson_1__c = UserInfo.getUserId();
    	    dd.MultiQuote_Payment_Grid__c = '{'
 	           + '"Term1": "2","Term2": "3","Term3":"4","Rate1":"33","Rate2":"44","Rate3":"44","Down1":"44","Down2":"44","Down3":"33",'
 	           + '"Row1_1":"1","Row1_2":"2","Row1_3":"3","Row2_1":"1","Row2_2":"2","Row2_3":"3","Row3_1":"1","Row3_2":"2","Row3_3":"3",'
 	           + '"Balloon": "1"'
 	           + '}';	// BLL4a
			dd.Vehicle_Source__c = 'Inventory';	// BLL9
    	    insert dd;

	        Kit_Category__c kc = new Kit_Category__c();
	        kc.External_ID__c='Tst';
	        kc.Order__c=1;
	        kc.Type__c='Category';
	        List<Kit_Category__c> kitcats = new List<Kit_Category__c>();
	        kitcats.add(kc);
	
	        Kit_Category__c kc1 = new Kit_Category__c();
	        kc1.External_ID__c='Ts1';
	        kc1.Order__c=1;
	        kc1.Type__c='Manufacturer';
	        kitcats.add(kc1);
			// BLL9
			Kit_Category__c kc2 = new Kit_Category__c(
				External_ID__c='Ts2',
				Order__c=2,
				Type__c='Sub-Category'
			);
			kitcats.add(kc2);
			// BLL9 end

	        insert(kitcats);
	
	        dealer__Parts_Kit__c dpk = new dealer__Parts_Kit__c();
	        dpk.Name='Test12';
	        dpk.dealer__Description__c ='searchDescriptionString';
	        dpk.Retail_Price__c =1;
	        dpk.Parts_Cost__c=1;
	        dpk.CMC_Price__c =1;
	        dpk.Category__c =kc.id;
	        dpk.Manufacturer__c =kc1.id;
			dpk.Sub_Category__c=kc2.id;	// BLL9
	        insert dpk;

			// BLL9
			List<dealer__Parts_Master__c> pms = new List<dealer__Parts_Master__c>();
			pms.add(new dealer__Parts_Master__c(
	            Name='TestPart',
	            dealer__Retail_Price__c = 10.0,
    	        dealer__Manufacturer__c = 'TST'
			));
			insert(pms);
	        dealer__Parts_Inventory__c pi = new dealer__parts_Inventory__c(
    	        dealer__Parts_Master__c = pms[0].Id,
        	    dealer__Location__c = FFAdata.DealerLocation.Id,
				dealer__Company_Number__c = FFAdata.DealerLocation.dealer__Company_Number__c, 
            	dealer__Part_No__c = 'TestPart',
	            dealer__Cost__c = 5.0,
    	        dealer__List__c = 10.0,
        	    dealer__MFG__c = 'TST'
        );
        insert(pi);
			// BLL9 end

	        try {
	        	TaxRuleSetting__c dfttaxrule = new TaxRuleSetting__c(Name='Default');
	        	insert(dfttaxrule);
	        } catch(Exception e) {}
	        
    	}
	}

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();

	        Account a = [select Id, PersonContactId from Account where dealer__Vendor__c=false and isPersonAccount=true limit 1];	
	        Account v = [select Id, dealer__Vendor__c from Account where dealer__Vendor__c=true limit 1];	
	        System.debug(v);
			dealer__Sales_Up__c dsp = [select Id from dealer__Sales_Up__c limit 1];	
			// BLL8
	        //dealer__Deal__c dd = [select Id, RecordTypeId, dealer__Auto_Insurance_Agent__c, dealer__Deal_ID__c,
	        //	dealer__Sales_Lead__c, dealer__Status__c, dealer__Deal_Date__c, Proposed_Delivery_Date__c,
	        //	dealer__Vehicle__c, dealer__Buyer__c, dealer__Deal_Type__c, dealer__Salesperson_1__c,
			//	dealer__Desk_Manager__c, dtmob__Service_Manager__c, // BLL8
	        //	Commission_Employee_1__c
	        //	from dealer__Deal__c where dealer__Sales_Lead__c=:dsp.Id limit 1
	        //];	
			Map<String, Schema.SObjectField> objFieldMap =  Schema.dealer__Deal__c.SObjectType.getDescribe().fields.getMap();
			List<String> objFieldList = new List<String>(extraFields);
			for(string f : objFieldMap.keySet()) if (objFieldMap.get(f).getDescribe().isAccessible()) objFieldList.add(f);
			String objfields = String.join(objFieldList,',');
			String soql = 'select ' + objfields + ' from dealer__Deal__c where dealer__Sales_Lead__c=\'' + dsp.Id + '\' limit 1';
			List<dealer__Deal__c> ddlist = Database.query(soql);
			dealer__Deal__c dd = ddlist.size()>0 ? ddlist[0] : null;
			// BLL8 end

			dealer__Parts_Kit__c dpk = [select Id, Name, dealer__Description__c from dealer__Parts_Kit__c limit 1];

			Kit_Category__c kc = [select Id, External_ID__c, Order__c, Type__c from Kit_Category__c where Type__c='Category' limit 1];
			Kit_Category__c km = [select Id, External_ID__c, Order__c, Type__c from Kit_Category__c where Type__c='Manufacturer' limit 1];

// misc additional records needed
	        dealer__Service_Vehicle__c  dsv = new dealer__Service_Vehicle__c ();
	        dsv.dealer__VIN__c ='Test';
	        dsv.Name='Test';
	        dsv.dealer__Body_Style__c = 'Test';
	        dsv.dealer__Company_Number__c='12123';
	        dsv.dealer__Veh_Owner_Contact__c = a.PersonContactId;
	        dsv.dealer__Carline__c ='Test';
	        dsv.dealer__Make__c  ='Test';
	        dsv.dealer__Year__c  ='2013';
	        insert dsv;
        
	        dealer__Form__c dfm = new dealer__Form__c();
	        dfm.dealer__Page_Name__c='Test';
	        dfm.Name='Test';
	        dfm.dealer__Print_Type__c='Impact';
	        insert dfm;
// end misc records needed

			Test.startTest();

    	    dealer__After_Market__c dam = new dealer__After_Market__c();
    	    dam.dealer__Car_Deal__c =dd.id;
    	    //BLL1 dam.dealer__Company_Number__c='Location 1';
			dam.dealer__Company_Number__c=FFAdata.DealerLocation.dealer__Company_Number__c;	// BLL1
    	    dam.dealer__Cost__c=1;
    	    dam.dealer__Description__c='Test';
    	    dam.dealer__Labor_Sale__c=12;
    	    dam.dealer__List_Price__c=1;
    	    dam.dealer__Parts_Kit__c=dpk.id;
    	    dam.dealer__Parts_Sale__c=3; 
    	    dam.dealer__Sale_Price__c=4; 
    	    dam.dealer__Vendor__c=v.id;	 
    	    dam.Labor_Hours__c=1;
    	    dam.Taxable__c=True;
    	    dam.dealer__Sale_Price__c = 2;
    	    dam.Name='Test';
    	    insert dam;

/** moved outside Test.startTest();        
	        dealer__Service_Vehicle__c  dsv = new dealer__Service_Vehicle__c ();
	        dsv.dealer__VIN__c ='Test';
	        dsv.Name='Test';
	        dsv.dealer__Body_Style__c = 'Test';
	        dsv.dealer__Company_Number__c='12123';
	        dsv.dealer__Veh_Owner_Contact__c = a.PersonContactId;
	        dsv.dealer__Carline__c ='Test';
	        dsv.dealer__Make__c  ='Test';
	        dsv.dealer__Year__c  ='2013';
	        insert dsv;
        
	        dealer__Form__c dfm = new dealer__Form__c();
	        dfm.dealer__Page_Name__c='Test';
	        dfm.Name='Test';
	        dfm.dealer__Print_Type__c='Impact';
	        insert dfm;
**/
	        ApexPages.StandardController sc = new ApexPages.StandardController(dd);
	        ApexPages.currentPage().getParameters().put('id', dd.id);
	        Deal_MBW2 dmb = new Deal_MBW2(new ApexPages.StandardController(dd));
	        dmb.deal = dd;
	        Id selectedPartNumber = dmb.selectedPartNumber;
	        List<String> esctypes = dmb.getEscTypes();	// BLL1a

			// Misc
			boolean vt = dmb.viewTransactions;
			boolean icv = dmb.isCustomerVehicle;
			String subj = dmb.subject;
			String body = dmb.body;
			Blob ablob = dmb.abody;
			String ct = dmb.acontenttype;
			String fn = dmb.afilename;
			List<dealer__Parts_Master__c> pml = dmb.getPartsResults();
			List<Deal_MBW2.cPartsKit> aKits = dmb.aKits;
			Decimal amlt = dmb.afterMarketLbrTotal;
			List<dealer__Form__c> formList = dmb.formList;
			Component.Apex.outputPanel op = dmb.getFormsTableRows();	// BLL1a
			Decimal TaxTotal = dmb.TaxTotal;
			PageReference cp = dmb.gotoClonePage();
			PageReference erd = dmb.emailReleasingDealer();
			PageReference epdf = dmb.emailPDFDirect();
			// end misc

	        List<dealer__Trade_In__c> TradeList = dmb.tradeInList;
	        //List<dealer__Service_Contract__c> soldOnProposal = dmb.soldOnProposal ;
	        //boolean testmgp = dmb.hasMobilityGuardPowertrain;	// BLL2a 
	        //List<dealer__Service_Contract__c> soldOnProposalSC =dmb.soldOnProposalSC;
	        //List<dealer__Service_Contract__c> soldOnProposalGAP=dmb.soldOnProposalGAP;
	        //List<dealer__Service_Contract__c> soldOnProposalDF=dmb.soldOnProposalDF;
	        //List<dealer__Service_Contract__c> soldOnProposalRoad=dmb.soldOnProposalRoad;
	        //List<dealer__Service_Contract__c> soldOnProposalMGP=dmb.soldOnProposalMGP;	// BLL2a

	        List<dealer__After_Market__c> selectedKits =dmb.selectedKits ;
	        Decimal tradVal = dmb.tradeValue;
	        dmb.escMileage ='Test';
	        dmb.thumbnailURL ='Test';
	        dmb.searchByNotes ='Test';
	        Decimal afterMarketTotal = dmb.afterMarketTotal;

	        dmb.cmc =new user();
	        Decimal serviceContractTotal = dmb.serviceContractTotal;
	        dmb.recordTypeName ='Test';
	        dmb.recordTypeLabel ='Test';

	        dmb.appendBuyerDetails(a.id);
	        dmb.getCategories();
			// BLL9
	        dmb.selectCategory=null;
	        dmb.getequipmentMFG();
			// BLL9
	        dmb.selectCategory=kc.id;
	        dmb.getequipmentMFG();
	        dmb.selectMFG = km.id;
	        dmb.getsubcat();

	        dmb.selectCategory=kc.id;
	        dmb.selectMFG = null;
	        dmb.selectSubCat =null;
	        dmb.getAvailablePartsKits();

	        dmb.selectCategory=null;
	        dmb.selectMFG = km.id;
	        dmb.selectSubCat =null;
	        dmb.getAvailablePartsKits();

	        dmb.searchByPartNumber = dpk.Name;
	        dmb.searchByDescription =dpk.dealer__Description__c;
	        dmb.selectCategory=kc.id;
	        dmb.selectSubCat =null;
	        dmb.selectMFG =km.id;
	        dmb.getAvailablePartsKits();

    	    dmb.selectCategory=kc.id;
    	    dmb.getAvailablePartsKits();
	
	        System.debug(Limits.getQueries());

	        dmb.searchByPartNumber ='1';
	        dmb.searchParts();
	        dmb.searchByPartNumber = null; // needs to be missing to get to search by description code
	        dmb.searchByDescription='Test';
	        dmb.searchParts();
        
			dmb.searchByDescription='Testa';
			dmb.searchParts();
			dmb.searchByPartNumber ='11';
			dmb.searchParts();
        
			dmb.getcPartsSize();
        
 	   		dmb.saveBuyerFields();
 	    	dmb.deal.dealer__Co_Buyer__c = a.id;
 	    	dmb.saveCoBuyerFields();
 	    	dmb.navigateAdvancedSearch();  

 	    	Deal_MBW2.addParts adPart = new Deal_MBW2.addParts();
 	    	//AMM10
			//Deal_MBW2.cPartsKit cPK = new Deal_MBW2.cPartsKit(dpk, true, 1, true);
			Deal_MBW2.cPartsKit cPK = new Deal_MBW2.cPartsKit(dpk, true, 1, true, true);
			// AMM10 end
 	    	Deal_MBW2.wMultiQuote wM = new Deal_MBW2.wMultiQuote('{'
 	           + '"Term1": "2","Term2": "3","Term3":"4","Rate1":"33","Rate2":"44","Rate3":"44","Down1":"44","Down2":"44","Down3":"33",'
 	           + '"Row1_1":"1","Row1_2":"2","Row1_3":"3","Row2_1":"1","Row2_2":"2","Row2_3":"3","Row3_1":"1","Row3_2":"2","Row3_3":"3",'
 	           + '"Balloon": "1"'
 	           + '}');
 	        dmb.multiquote = wM;

			System.debug('Finished multiquote');

 	    	dmb.printPDF();
 	    	dmb.emailPDF();
 	   		dmb.addService();
 	    	dmb.addPart();
 	    	dmb.savePart();

			System.debug('Finished savePart');

	        dmb.searchESC();
	        //dmb.saveService();	// currently causing Too many SOQL queries 2018-01-25
	        dmb.newServiceContract();
			System.debug('Finished ESC');

	        dmb.returnToDeal();
	        dmb.newTrade();
			System.debug('Finished newTrade');
	        dmb.tradeData.dealer__Year__c = '2014';
	        dmb.tradeData.dealer__Make__c = '2014';
	        dmb.tradeData.dealer__Model__c = '2014';
	        dmb.saveTrade();
			System.debug('Finished saveTrade');
	        Test.StopTest();	
			
		}
	}


	// unitTest2
	//---------------------------------------
	static testMethod void unitTest2() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
			
	        Account a = [select Id, PersonContactId from Account where dealer__Vendor__c=false limit 1];	
	        Account v = [select Id, dealer__Vendor__c from Account where dealer__Vendor__c=true limit 1];	

			dealer__Sales_Up__c dsp = [select Id from dealer__Sales_Up__c limit 1];	
			// BLL8
	        //dealer__Deal__c dd = [select Id, RecordTypeId, dealer__Auto_Insurance_Agent__c, dealer__Deal_ID__c,
	        //	dealer__Sales_Lead__c, dealer__Status__c, dealer__Deal_Date__c, Proposed_Delivery_Date__c,
	        //	dealer__Vehicle__c, dealer__Buyer__c, dealer__Deal_Type__c, dealer__Salesperson_1__c,
			//	dealer__Desk_Manager__c, dtmob__Service_Manager__c, // BLL8
	        //	Commission_Employee_1__c
	        //	from dealer__Deal__c where dealer__Sales_Lead__c=:dsp.Id limit 1
	        //];	
			Map<String, Schema.SObjectField> objFieldMap =  Schema.dealer__Deal__c.SObjectType.getDescribe().fields.getMap();
			List<String> objFieldList = new List<String>(extraFields);
			for(string f : objFieldMap.keySet()) if (objFieldMap.get(f).getDescribe().isAccessible()) objFieldList.add(f);
			String objfields = String.join(objFieldList,',');
			String soql = 'select ' + objfields + ' from dealer__Deal__c where dealer__Sales_Lead__c=\'' + dsp.Id + '\' limit 1';
			List<dealer__Deal__c> ddlist = Database.query(soql);
			dealer__Deal__c dd = ddlist.size()>0 ? ddlist[0] : null;
			// BLL8 end

			dealer__Parts_Kit__c dpk = [select Id, Name from dealer__Parts_Kit__c limit 1];
	
			Test.startTest(); 
	
	        dealer__After_Market__c dam = new dealer__After_Market__c();
	        dam.dealer__Car_Deal__c =dd.id;
	        //BLL1 dam.dealer__Company_Number__c='Location 1';
			dam.dealer__Company_Number__c=FFAdata.DealerLocation.dealer__Company_Number__c;	// BLL1
	        dam.dealer__Cost__c=1;
	        dam.dealer__Description__c='Test';
	        dam.dealer__Labor_Sale__c=12;
	        dam.dealer__List_Price__c=1;
	        dam.dealer__Parts_Kit__c=dpk.id;
	        dam.dealer__Parts_Sale__c=3; 
	        dam.dealer__Sale_Price__c=4; 
	        dam.dealer__Vendor__c=v.id;	 
	        dam.Labor_Hours__c=1;
	        dam.Taxable__c=True;
	        dam.dealer__Sale_Price__c = 2;
	        dam.Name='Test';
	        insert dam;
	
	        ApexPages.StandardController sc = new ApexPages.StandardController(dd);
	        ApexPages.currentPage().getParameters().put('id', dd.id);
	        ApexPages.currentPage().getParameters().put('v', dd.dealer__Vehicle__c);	// BLL6a
	        dd.dealer__Vehicle__c = null;	// BLL6a
	        Deal_MBW2 dmb = new Deal_MBW2(new ApexPages.StandardController(dd));
	        dmb.deal = dd;
	
	        dmb.addKitId = dpk.id;
	        dmb.addKitToProposal();
	        dmb.getVehicleData();
	  
	        dmb.getxmlTag();
	        dmb.selectImpactForm();
	        dmb.base64Decode('s==');
	        dmb.getcompiled_form();
	
	        dmb.deleteEquipmentId = dam.id;
	        dmb.deleteEquipment();

// BLL7d remove next line to reduce SOQL queries, still have 75.7% coverage
//			dmb.removeVehicle();
	
	        Test.stopTest(); 
			
		}
		
	}


	// unitTest3
	//---------------------------------------
	static testMethod void unitTest3() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
			
	        Account a = [select Id, PersonContactId from Account where dealer__Vendor__c=false limit 1];	
	        Account v = [select Id, dealer__Vendor__c from Account where dealer__Vendor__c=true limit 1];	

			dealer__Sales_Up__c dsp = [select Id from dealer__Sales_Up__c limit 1];	
			// BLL8
	        //dealer__Deal__c dd = [select Id, RecordTypeId, dealer__Auto_Insurance_Agent__c, dealer__Deal_ID__c,
	        //	dealer__Sales_Lead__c, dealer__Status__c, dealer__Deal_Date__c, Proposed_Delivery_Date__c,
	        //	dealer__Vehicle__c, dealer__Buyer__c, dealer__Deal_Type__c, dealer__Salesperson_1__c,
			//	dealer__Desk_Manager__c, dtmob__Service_Manager__c, // BLL8
	        //	Commission_Employee_1__c
	        //	from dealer__Deal__c where dealer__Sales_Lead__c=:dsp.Id limit 1
	        //];
			Map<String, Schema.SObjectField> objFieldMap =  Schema.dealer__Deal__c.SObjectType.getDescribe().fields.getMap();
			List<String> objFieldList = new List<String>(extraFields);
			for(string f : objFieldMap.keySet()) if (objFieldMap.get(f).getDescribe().isAccessible()) objFieldList.add(f);
			String objfields = String.join(objFieldList,',');
			String soql = 'select ' + objfields + ' from dealer__Deal__c where dealer__Sales_Lead__c=\'' + dsp.Id + '\' limit 1';
			List<dealer__Deal__c> ddlist = Database.query(soql);
			dealer__Deal__c dd = ddlist.size()>0 ? ddlist[0] : null;
			// BLL8 end

	        dealer__Vehicle_Inventory__c vi = [select Id from dealer__Vehicle_Inventory__c limit 1];
	        
			dealer__Parts_Kit__c dpk = [select Id, Name from dealer__Parts_Kit__c limit 1];

			Kit_Category__c kc = [select Id, External_ID__c, Order__c, Type__c from Kit_Category__c where Type__c='Category' limit 1];
			Kit_Category__c km = [select Id, External_ID__c, Order__c, Type__c from Kit_Category__c where Type__c='Manufacturer' limit 1];
	        
	        dealer__After_Market__c dam = new dealer__After_Market__c();
	        dam.dealer__Car_Deal__c =dd.id;
	        //BLL1d dam.dealer__Company_Number__c='Location 1';
			dam.dealer__Company_Number__c=FFAdata.DealerLocation.dealer__Company_Number__c;	// BLL1
	        dam.dealer__Cost__c=1;
	        dam.dealer__Description__c='Test';
	        dam.dealer__Labor_Sale__c=12;
	        dam.dealer__List_Price__c=1;
	        dam.dealer__Parts_Kit__c=dpk.id;
	        dam.dealer__Parts_Sale__c=3; 
	        dam.dealer__Sale_Price__c=4; 
	        dam.dealer__Vendor__c=v.id;	 
	        dam.Labor_Hours__c=1;
	        dam.Taxable__c=True;
	        dam.dealer__Sale_Price__c = 2;
	        dam.Name='Test';
	        insert dam;
	
			dealer__Service_Vehicle__c  dsv;
			try {
				dsv = [select Id, Name, dealer__VIN__c,
					dealer__Body_Style__c, dealer__Company_Number__c, dealer__Veh_Owner_Contact__c,
					dealer__Carline__c, dealer__Make__c, dealer__Year__c 
					from dealer__Service_Vehicle__c  
					limit 1
				];
			} catch(Exception e) {}	
	
			Test.startTest();	 

	        ApexPages.StandardController sc = new ApexPages.StandardController(dd);
	        ApexPages.currentPage().getParameters().put('id', dd.id);
	        Deal_MBW2 dmb = new Deal_MBW2(new ApexPages.StandardController(dd));

	        dmb.deal = dd;
	        dmb.selectCategory = kc.Id;
	        dmb.selectMFG = km.Id;
	        dmb.getsubcat(); 
	        dmb.selectProduct();
	        dmb.deleteProduct();
	        dmb.deleteProduct();
	        dmb.returnToDeal();
	        dmb.newTrade();

			dmb.createCommercialQuote();
			dmb.removeCommercialQuote();
			dmb.chgDealType();

			// BLL8
			dealer__Form__c pa = dmb.purAgreement;
			// BLL8 end

			Test.stopTest();

		}
		
	}


	// unitTest4
	//---------------------------------------
	static testMethod void unitTest4() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
			
	        Account a = [select Id, PersonContactId from Account where dealer__Vendor__c=false limit 1];	
	        Account v = [select Id, dealer__Vendor__c from Account where dealer__Vendor__c=true limit 1];	

			dealer__Sales_Up__c dsp = [select Id from dealer__Sales_Up__c limit 1];	
			// BLL8
	        //dealer__Deal__c dd = [select Id, RecordTypeId, dealer__Auto_Insurance_Agent__c, dealer__Deal_ID__c,
	        //	dealer__Sales_Lead__c, dealer__Status__c, dealer__Deal_Date__c, Proposed_Delivery_Date__c,
	        //	dealer__Vehicle__c, dealer__Buyer__c, dealer__Deal_Type__c, dealer__Salesperson_1__c,
			//	dealer__Desk_Manager__c, dtmob__Service_Manager__c, // BLL8
	        //	Commission_Employee_1__c
	        //	from dealer__Deal__c where dealer__Sales_Lead__c=:dsp.Id limit 1
	        //];
			Map<String, Schema.SObjectField> objFieldMap =  Schema.dealer__Deal__c.SObjectType.getDescribe().fields.getMap();
			List<String> objFieldList = new List<String>(extraFields);
			for(string f : objFieldMap.keySet()) if (objFieldMap.get(f).getDescribe().isAccessible()) objFieldList.add(f);
			String objfields = String.join(objFieldList,',');
			String soql = 'select ' + objfields + ' from dealer__Deal__c where dealer__Sales_Lead__c=\'' + dsp.Id + '\' limit 1';
			List<dealer__Deal__c> ddlist = Database.query(soql);
			dealer__Deal__c dd = ddlist.size()>0 ? ddlist[0] : null;
			// BLL8 end
	        
	        dealer__Vehicle_Inventory__c vi = [select Id from dealer__Vehicle_Inventory__c limit 1];
	        
			dealer__Parts_Kit__c dpk = [select Id, Name from dealer__Parts_Kit__c limit 1];

	        ApexPages.StandardController sc = new ApexPages.StandardController(dd);
	        ApexPages.currentPage().getParameters().put('id', dd.id);
	        Deal_MBW2 dmb = new Deal_MBW2(new ApexPages.StandardController(dd));
	        
			Test.startTest();	 

	        dealer__After_Market__c dam = new dealer__After_Market__c();
	        dam.dealer__Car_Deal__c =dd.id;
	        //BLL1d dam.dealer__Company_Number__c='Location 1';
			dam.dealer__Company_Number__c=FFAdata.DealerLocation.dealer__Company_Number__c;	// BLL1
	        dam.dealer__Cost__c=1;
	        dam.dealer__Description__c='Test';
	        dam.dealer__Labor_Sale__c=12;
	        dam.dealer__List_Price__c=1;
	        dam.dealer__Parts_Kit__c=dpk.id;
	        dam.dealer__Parts_Sale__c=3; 
	        dam.dealer__Sale_Price__c=4; 
	        dam.dealer__Vendor__c=v.id;	 
	        dam.Labor_Hours__c=1;
	        dam.Taxable__c=True;
	        dam.dealer__Sale_Price__c = 2;
	        dam.Name='Test';
	        insert dam;
	
	       
	        dealer__Service_Vehicle__c  dsv = new dealer__Service_Vehicle__c ();
	        dsv.dealer__VIN__c ='Test';
	        dsv.Name='Test';
	        dsv.dealer__Body_Style__c = 'Test';
	        dsv.dealer__Company_Number__c='12123';
	        dsv.dealer__Veh_Owner_Contact__c = a.PersonContactId;
	        dsv.dealer__Carline__c ='Test';
	        dsv.dealer__Make__c  ='Test';
	        dsv.dealer__Year__c  ='2013';
	        insert dsv;
	        
	        dmb.deal = dd;
			dmb.addKitId = dpk.id;
	        dmb.addKitToProposal();
	        dmb.addKitId = dpk.id;
	        dmb.addKitToProposal();
	        dmb.getxmlTag();
	        dmb.selectImpactForm();
	        dmb.base64Decode('s');
	        dmb.getcompiled_form();
	
			dmb.subletDescription='Test';
			dmb.subletCost=12;
			dmb.subletSale=11;
	
	        dmb.deleteEquipmentId = dam.id;
	        dmb.tradeData.dealer__Year__c = '2014';
	        dmb.tradeData.dealer__Make__c = '2014';
	        dmb.tradeData.dealer__Model__c = '2014';
	        dmb.saveTrade();
	        dmb.addSublet();
	        dmb.saveSublet();
	        dmb.subletDescription=null;
	        dmb.subletCost=null;
	        dmb.subletSale=null;
	        dmb.saveSublet();
	        
	        dmb.subletDescription='Test';
	        dmb.subletCost=1.00;
	        dmb.subletSale=2.00;
	        dmb.saveSublet();
	
	        Deal_MBW2.orderResponse ordRes = new Deal_MBW2.orderResponse();
	
	        Account na = new Account();
	        na.FirstName = 'Bob';
	        na.LastName = 'Seiger';
	        insert na;
	        Deal_MBW2.addServiceVehicle('{"VIN": "90909890","Year": "2014","Make":"2014","Model":"2014","OwnerName":"Mahesh","OwnerId":"'+na.Id+'","Odometer":"2"}');
	        Deal_MBW2.updateEquipmentSale(dam.id);

			Test.stopTest();
				 
		}
		
	}


	// BLL2a
	// testServiceContract
	//---------------------------------------
	static testMethod void testServiceContract() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
	        Account a = [select Id, PersonContactId from Account where dealer__Vendor__c=false and isPersonAccount=true limit 1];	

			dealer__Sales_Up__c dsp = [select Id from dealer__Sales_Up__c limit 1];	
			// BLL8
	        //dealer__Deal__c dd = [select Id, RecordTypeId, dealer__Auto_Insurance_Agent__c, dealer__Deal_ID__c,
	        //	dealer__Sales_Lead__c, dealer__Status__c, dealer__Deal_Date__c, Proposed_Delivery_Date__c,
	        //	dealer__Vehicle__c, dealer__Buyer__c, dealer__Deal_Type__c, dealer__Salesperson_1__c,
			//	dealer__Desk_Manager__c, dtmob__Service_Manager__c, // BLL8
	        //	Commission_Employee_1__c
	        //	from dealer__Deal__c where dealer__Sales_Lead__c=:dsp.Id limit 1
	        //];	
			Map<String, Schema.SObjectField> objFieldMap =  Schema.dealer__Deal__c.SObjectType.getDescribe().fields.getMap();
			List<String> objFieldList = new List<String>(extraFields);
			for(string f : objFieldMap.keySet()) if (objFieldMap.get(f).getDescribe().isAccessible()) objFieldList.add(f);
			String objfields = String.join(objFieldList,',');
			String soql = 'select ' + objfields + ' from dealer__Deal__c where dealer__Sales_Lead__c=\'' + dsp.Id + '\' limit 1';
			List<dealer__Deal__c> ddlist = Database.query(soql);
			dealer__Deal__c dd = ddlist.size()>0 ? ddlist[0] : null;
			// BLL8 end

			Test.startTest();

	        dealer__Service_Vehicle__c  dsv = new dealer__Service_Vehicle__c ();
	        dsv.dealer__VIN__c ='Test';
	        dsv.Name='Test';
	        dsv.dealer__Body_Style__c = 'Test';
	        dsv.dealer__Company_Number__c='12123';
	        dsv.dealer__Veh_Owner_Contact__c = a.PersonContactId;
	        dsv.dealer__Carline__c ='Test';
	        dsv.dealer__Make__c  ='Test';
	        dsv.dealer__Year__c  ='2013';
	        insert dsv;

			Map<String, Schema.RecordTypeInfo> dealRcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();	// BLL4

	        ApexPages.StandardController sc = new ApexPages.StandardController(dd);
	        ApexPages.currentPage().getParameters().put('id', dd.id);
	        ApexPages.currentPage().getParameters().put('RecordType', dealRcdTypes.get('Commercial').getRecordTypeId() );	// BLL4a
	        Deal_MBW2 dmb = new Deal_MBW2(new ApexPages.StandardController(dd));
	        dmb.deal = dd;
	        List<String> esctypes = dmb.getEscTypes();	// BLL1a

			// Service Contract routines
	        List<dealer__Trade_In__c> TradeList = dmb.tradeInList;
	        List<dealer__Service_Contract__c> soldOnProposal = dmb.soldOnProposal ;
	        boolean testmgp = dmb.hasMobilityGuardPowertrain;	// BLL2a 
	        List<dealer__Service_Contract__c> soldOnProposalSC =dmb.soldOnProposalSC;
	        List<dealer__Service_Contract__c> soldOnProposalGAP=dmb.soldOnProposalGAP;
	        List<dealer__Service_Contract__c> soldOnProposalDF=dmb.soldOnProposalDF;
	        List<dealer__Service_Contract__c> soldOnProposalRoad=dmb.soldOnProposalRoad;
	        List<dealer__Service_Contract__c> soldOnProposalMGP=dmb.soldOnProposalMGP;	// BLL2a

			// test with null deal id	-- BLL4a
			dmb.deal.id = null;
	        soldOnProposal = dmb.soldOnProposal;
	        testmgp = dmb.hasMobilityGuardPowertrain; 
	        soldOnProposalSC =dmb.soldOnProposalSC;
	        soldOnProposalGAP=dmb.soldOnProposalGAP;
	        soldOnProposalDF=dmb.soldOnProposalDF;
	        soldOnProposalRoad=dmb.soldOnProposalRoad;
	        soldOnProposalMGP=dmb.soldOnProposalMGP;
			
		}
	}
	// BLL2a end	


	// TestTaxRoutines
	//---------------------------------------
	static testMethod void TestTaxRoutines() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
			
	        Account a = [select Id, PersonContactId from Account where dealer__Vendor__c=false limit 1];	
	        Account v = [select Id, dealer__Vendor__c from Account where dealer__Vendor__c=true limit 1];	

			dealer__Sales_Up__c dsp = [select Id from dealer__Sales_Up__c limit 1];	
			// BLL8
	        //dealer__Deal__c dd = [select Id, RecordTypeId, dealer__Auto_Insurance_Agent__c, dealer__Deal_ID__c,
	        //	dealer__Sales_Lead__c, dealer__Status__c, dealer__Deal_Date__c, Proposed_Delivery_Date__c,
	        //	dealer__Vehicle__c, dealer__Buyer__c, dealer__Deal_Type__c, dealer__Salesperson_1__c,
			//	dealer__Desk_Manager__c, dtmob__Service_Manager__c, // BLL8
	        //	Commission_Employee_1__c
	        //	from dealer__Deal__c where dealer__Sales_Lead__c=:dsp.Id limit 1
	        //];
			Map<String, Schema.SObjectField> objFieldMap =  Schema.dealer__Deal__c.SObjectType.getDescribe().fields.getMap();
			List<String> objFieldList = new List<String>(extraFields);
			for(string f : objFieldMap.keySet()) if (objFieldMap.get(f).getDescribe().isAccessible()) objFieldList.add(f);
			String objfields = String.join(objFieldList,',');
			String soql = 'select ' + objfields + ' from dealer__Deal__c where dealer__Sales_Lead__c=\'' + dsp.Id + '\' limit 1';
			List<dealer__Deal__c> ddlist = Database.query(soql);
			dealer__Deal__c dd = ddlist.size()>0 ? ddlist[0] : null;
			// BLL8 end
	        
	        dealer__Vehicle_Inventory__c vi = [select Id from dealer__Vehicle_Inventory__c limit 1];
			dealer__Parts_Kit__c dpk = [select Id, Name from dealer__Parts_Kit__c limit 1];
	        
			Test.startTest();	 

	        ApexPages.StandardController sc = new ApexPages.StandardController(dd);
	        ApexPages.currentPage().getParameters().put('id', dd.id);
	        Deal_MBW2 dmb = new Deal_MBW2(new ApexPages.StandardController(dd));
	        Test.setMock(WebServiceMock.class, new AvaTaxRequestMock());
			List<DealTaxes__c> dtlist = dmb.getTaxes();
			dmb.pageCalcTax();
	
			Test.stopTest();
				 
		}
		
	}

	// TestRemotes1
	//---------------------------------------
	static testMethod void TestRemotes1() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
			
	        Account a = [select Id, PersonContactId from Account where dealer__Vendor__c=false limit 1];	
	        Account v = [select Id, dealer__Vendor__c from Account where dealer__Vendor__c=true limit 1];	

			dealer__Sales_Up__c dsp = [select Id from dealer__Sales_Up__c limit 1];	
			// BLL8
	        //dealer__Deal__c dd = [select Id, RecordTypeId, dealer__Auto_Insurance_Agent__c, dealer__Deal_ID__c,
	        //	dealer__Sales_Lead__c, dealer__Status__c, dealer__Deal_Date__c, Proposed_Delivery_Date__c,
	        //	dealer__Vehicle__c, dealer__Buyer__c, dealer__Deal_Type__c, dealer__Salesperson_1__c,
			//	dealer__Desk_Manager__c, dtmob__Service_Manager__c, // BLL8
	        //	Commission_Employee_1__c
	        //	from dealer__Deal__c where dealer__Sales_Lead__c=:dsp.Id limit 1
	        //];
			Map<String, Schema.SObjectField> objFieldMap =  Schema.dealer__Deal__c.SObjectType.getDescribe().fields.getMap();
			List<String> objFieldList = new List<String>(extraFields);
			for(string f : objFieldMap.keySet()) if (objFieldMap.get(f).getDescribe().isAccessible()) objFieldList.add(f);
			String objfields = String.join(objFieldList,',');
			String soql = 'select ' + objfields + ' from dealer__Deal__c where dealer__Sales_Lead__c=\'' + dsp.Id + '\' limit 1';
			List<dealer__Deal__c> ddlist = Database.query(soql);
			dealer__Deal__c dd = ddlist.size()>0 ? ddlist[0] : null;
			// BLL8 end
	        
	        dealer__Vehicle_Inventory__c vi = [select Id from dealer__Vehicle_Inventory__c limit 1];
	        
			dealer__Parts_Kit__c dpk = [select Id, Name from dealer__Parts_Kit__c limit 1];
	        
			Test.startTest();	 

	        ApexPages.StandardController sc = new ApexPages.StandardController(dd);
	        ApexPages.currentPage().getParameters().put('id', dd.id);
	        Deal_MBW2 dmb = new Deal_MBW2(new ApexPages.StandardController(dd));

	        dealer__After_Market__c dam = new dealer__After_Market__c();
	        dam.dealer__Car_Deal__c =dd.id;
	        //BLL1d dam.dealer__Company_Number__c='Location 1';
			dam.dealer__Company_Number__c=FFAdata.DealerLocation.dealer__Company_Number__c;	// BLL1
	        dam.dealer__Cost__c=1;
	        dam.dealer__Description__c='Test';
	        dam.dealer__Labor_Sale__c=12;
	        dam.dealer__List_Price__c=1;
	        dam.dealer__Parts_Kit__c=dpk.id;
	        dam.dealer__Parts_Sale__c=3; 
	        dam.dealer__Sale_Price__c=4; 
	        dam.dealer__Vendor__c=v.id;	 
	        dam.Labor_Hours__c=1;
	        dam.Taxable__c=True;
	        dam.dealer__Sale_Price__c = 2;
	        dam.Name='Test';
	        insert dam;
	        
	        Deal_MBW2.saveField(dd.id);
	        Deal_MBW2.lookupCustomerRecord(a.id, a.PersonContactId); 
	
	        Deal_MBW2.saveDealDate(dd.id+'~'+'8/8/2015'+'~dd');
	        Deal_MBW2.saveDealDate(dd.id+'~'+'8/8/2015'+'~pd');
	        Deal_MBW2.selectStockNumber(dd.dealer__Vehicle__c);   
	        Deal_MBW2.saveField(dd.Id+'~dealer__Deal_Type__c~Wholesale');
	
	        Deal_MBW2.aftermarketItems(dd.Id);
	        Deal_MBW2.serviceContractItems(dd.Id);
	        Deal_MBW2.setAfterMarketOrder('{"items" : [{"RecordId" : "'+dam.Id+'" , "PageOrder" : "1"}]}');

			//Deal_MBW2.saveDealStatus(dd.Id+'~' + 'Pending');	// BLL1a
	
			Test.stopTest();
				 
		}
		
	}


	// TestRemotes2
	//---------------------------------------
	static testMethod void TestRemotes2() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
			
	        Account a = [select Id, PersonContactId from Account where dealer__Vendor__c=false limit 1];	
	        Account v = [select Id, dealer__Vendor__c from Account where dealer__Vendor__c=true limit 1];	

			dealer__Sales_Up__c dsp = [select Id from dealer__Sales_Up__c limit 1];	
			// BLL8
	        //dealer__Deal__c dd = [select Id, RecordTypeId, dealer__Auto_Insurance_Agent__c, dealer__Deal_ID__c,
	        //	dealer__Sales_Lead__c, dealer__Status__c, dealer__Deal_Date__c, Proposed_Delivery_Date__c,
	        //	dealer__Vehicle__c, dealer__Buyer__c, dealer__Deal_Type__c, dealer__Salesperson_1__c,
			//	dealer__Desk_Manager__c, dtmob__Service_Manager__c, // BLL8
	        //	Commission_Employee_1__c
	        //	from dealer__Deal__c where dealer__Sales_Lead__c=:dsp.Id limit 1
	        //];
			Map<String, Schema.SObjectField> objFieldMap =  Schema.dealer__Deal__c.SObjectType.getDescribe().fields.getMap();
			List<String> objFieldList = new List<String>(extraFields);
			for(string f : objFieldMap.keySet()) if (objFieldMap.get(f).getDescribe().isAccessible()) objFieldList.add(f);
			String objfields = String.join(objFieldList,',');
			String soql = 'select ' + objfields + ' from dealer__Deal__c where dealer__Sales_Lead__c=\'' + dsp.Id + '\' limit 1';
			List<dealer__Deal__c> ddlist = Database.query(soql);
			dealer__Deal__c dd = ddlist.size()>0 ? ddlist[0] : null;
			// BLL8 end
	        
	        dealer__Vehicle_Inventory__c vi = [select Id from dealer__Vehicle_Inventory__c limit 1];
	        
			dealer__Parts_Kit__c dpk = [select Id, Name from dealer__Parts_Kit__c limit 1];

	        ApexPages.StandardController sc = new ApexPages.StandardController(dd);
	        ApexPages.currentPage().getParameters().put('id', dd.id);
	        Deal_MBW2 dmb = new Deal_MBW2(new ApexPages.StandardController(dd));
	        
			Test.startTest();
				 
	        Deal_MBW2.saveField(dd.id+'~dealer__Amt_Financed__c~20');
	        Deal_MBW2.saveField(dd.id+'~Proposed_Delivery_Date__c~' + Datetime.now().format('MM/dd/yyyy'));
	        Deal_MBW2.saveField(dd.id+'~Commission_Rate__c~20');

			Test.stopTest();
				 
		}
		
	}


	// TestRemotes3
	//---------------------------------------
	static testMethod void TestRemotes3() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
			
	        Account a = [select Id, PersonContactId from Account where dealer__Vendor__c=false limit 1];	
	        Account v = [select Id, dealer__Vendor__c from Account where dealer__Vendor__c=true limit 1];	

			dealer__Sales_Up__c dsp = [select Id from dealer__Sales_Up__c limit 1];	
			// BLL8
	        //dealer__Deal__c dd = [select Id, RecordTypeId, dealer__Auto_Insurance_Agent__c, dealer__Deal_ID__c,
	        //	dealer__Sales_Lead__c, dealer__Status__c, dealer__Deal_Date__c, Proposed_Delivery_Date__c,
	        //	dealer__Vehicle__c, dealer__Buyer__c, dealer__Deal_Type__c, dealer__Salesperson_1__c,
			//	dealer__Desk_Manager__c, dtmob__Service_Manager__c, // BLL8
	        //	Commission_Employee_1__c
	        //	from dealer__Deal__c where dealer__Sales_Lead__c=:dsp.Id limit 1
	        //];
			Map<String, Schema.SObjectField> objFieldMap =  Schema.dealer__Deal__c.SObjectType.getDescribe().fields.getMap();
			List<String> objFieldList = new List<String>(extraFields);
			for(string f : objFieldMap.keySet()) if (objFieldMap.get(f).getDescribe().isAccessible()) objFieldList.add(f);
			String objfields = String.join(objFieldList,',');
			String soql = 'select ' + objfields + ' from dealer__Deal__c where dealer__Sales_Lead__c=\'' + dsp.Id + '\' limit 1';
			List<dealer__Deal__c> ddlist = Database.query(soql);
			dealer__Deal__c dd = ddlist.size()>0 ? ddlist[0] : null;
			// BLL8 end
	        
	        dealer__Vehicle_Inventory__c vi = [select Id from dealer__Vehicle_Inventory__c limit 1];
	        
			dealer__Parts_Kit__c dpk = [select Id, Name from dealer__Parts_Kit__c limit 1];
	        
	        ApexPages.StandardController sc = new ApexPages.StandardController(dd);
	        ApexPages.currentPage().getParameters().put('id', dd.id);
	        Deal_MBW2 dmb = new Deal_MBW2(new ApexPages.StandardController(dd));

			Test.startTest();	 

	        dealer__After_Market__c dam = new dealer__After_Market__c();
	        dam.dealer__Car_Deal__c =dd.id;
	        //BLL1d dam.dealer__Company_Number__c='Location 1';
			dam.dealer__Company_Number__c=FFAdata.DealerLocation.dealer__Company_Number__c;	// BLL1
	        dam.dealer__Cost__c=1;
	        dam.dealer__Description__c='Test';
	        dam.dealer__Labor_Sale__c=12;
	        dam.dealer__List_Price__c=1;
	        dam.dealer__Parts_Kit__c=dpk.id;
	        dam.dealer__Parts_Sale__c=3; 
	        dam.dealer__Sale_Price__c=4; 
	        dam.dealer__Vendor__c=v.id;	 
	        dam.Labor_Hours__c=1;
	        dam.Taxable__c=True;
	        dam.dealer__Sale_Price__c = 2;
	        dam.Name='Test';
	        insert dam;
	        
	        dealer__Service_Contract__c dsc= new dealer__Service_Contract__c();
	        dsc.dealer__Deductable__c=12;
	        dsc.dealer__Description__c='Test';
	        dsc.dealer__Car_Deal__c = dd.Id;
	        insert dsc;

	        Deal_MBW2.dealGrossSVC(dsc.id);
	        Deal_MBW2.dealGrossEquipment(dam.id);
	        Deal_MBW2.equipmentSale(dam.id);
	        Deal_MBW2.serviceContractCost(dsc.id);
	        Deal_MBW2.serviceContractSale(dsc.id);
	        Deal_MBW2.toggleTax(dam.id);
	        Deal_MBW2.toggleTax(dam.Id+':true');
	        Deal_MBW2.togglePrint(dam.id);
	        Deal_MBW2.togglePrint(dam.Id+':true');
	        
/* BLL7d
	        dsc.dealer__Car_Deal__c = dd.Id;
	        dsc.dealer__Cost__c = 99;
	        update dsc;
*/
			Test.stopTest();
				 
		}
		
	}


	// FromNewSolOpp
	//---------------------------------------
	static testMethod void FromNewSolOpp() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
			
	        Account a = [select Id, PersonContactId from Account where dealer__Vendor__c=false limit 1];	
	        Account v = [select Id, dealer__Vendor__c from Account where dealer__Vendor__c=true limit 1];	
	        DateTime now = DateTime.now();

	        dealer__Sales_Up__c sup = new dealer__Sales_Up__c(
	            dealer__Lead_Date__c=System.Today(),
	            dealer__Lead_Status__c='Pending',
	            dealer__Lead_Type__c='List',
	            dealer__Source__c ='Pride',
	            //dealer__Latest_Appointment_Date_Time__c = now,	// BLL5a
	            //Follow_Up_Stage__c = '6',	// BLL5a
	            Solution_Type__c ='Chassis/Conversion',
	            Company__c = FFAData.DealerLocation.Id, 	
	            dealer__Customer_Account__c =a.id
	        );
	        insert(sup);

			Test.startTest();	 
			
	        // Create an appointment too - BLL4a fix for test error requiring shown appt
	        dealer__Sales_Appointment__c salesAppointment = new dealer__Sales_Appointment__c();
	        salesAppointment.dealer__Appointment_Type__c = 'First Visit';
	        salesAppointment.dealer__Time__c = now.format('hh:mm a');
	        salesAppointment.dealer__DateTime__c = now;
	        salesAppointment.dealer__Date__c = now.date();
	        salesAppointment.dealer__Customer__c = a.PersonContactId;
	        salesAppointment.dealer__Notes__c = 'Appointment for test';
	        salesAppointment.dealer__Sales_Up__c = sup.Id;
	        salesAppointment.dealer__Confirmed__c = true;
	        salesAppointment.dealer__Appointment_Result__c = 'Shown';
	        //salesAppointment.dealer__Appointment_Result__c = 'Open';	// BLL5a
	        salesAppointment.OwnerId = UserInfo.getUserId();
	        salesAppointment.dealer__Assigned_To__c = UserInfo.getUserId();
	        insert(salesAppointment);
	
	        // b=001W000000JptRu&rType=Retail_Vehicle_Sale&s=a1yW0000000eJ82&v=a2PW00000007T4N
	        dealer__Deal__c dd = new dealer__Deal__c();
	        ApexPages.StandardController sc = new ApexPages.StandardController(dd);
	        ApexPages.currentPage().getParameters().put('b', a.Id);
	        ApexPages.currentPage().getParameters().put('s', sup.Id);
	        ApexPages.currentPage().getParameters().put('rType', 'Retail_Vehicle_Sale');
	        Deal_MBW2 dmb = new Deal_MBW2(new ApexPages.StandardController(dd));
	        dmb.saveProposal();

			Test.stopTest();
				 
		}
		
	}


	// unitTest5
	//---------------------------------------
	static testMethod void unitTest5() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();
			
	        Account a = [select Id, PersonContactId from Account where dealer__Vendor__c=false limit 1];	
	        Account v = [select Id, dealer__Vendor__c from Account where dealer__Vendor__c=true limit 1];	

			dealer__Sales_Up__c dsp = [select Id from dealer__Sales_Up__c limit 1];	
			// BLL8
	        //dealer__Deal__c dd = [select Id, RecordTypeId, dealer__Auto_Insurance_Agent__c, dealer__Deal_ID__c,
	        //	dealer__Sales_Lead__c, dealer__Status__c, dealer__Deal_Date__c, Proposed_Delivery_Date__c,
	        //	dealer__Vehicle__c, dealer__Buyer__c, dealer__Deal_Type__c, dealer__Salesperson_1__c,
			//	dealer__Desk_Manager__c, dtmob__Service_Manager__c, // BLL8
	        //	Commission_Employee_1__c
	        //	from dealer__Deal__c where dealer__Sales_Lead__c=:dsp.Id limit 1
	        //];
			Map<String, Schema.SObjectField> objFieldMap =  Schema.dealer__Deal__c.SObjectType.getDescribe().fields.getMap();
			List<String> objFieldList = new List<String>(extraFields);
			for(string f : objFieldMap.keySet()) if (objFieldMap.get(f).getDescribe().isAccessible()) objFieldList.add(f);
			String objfields = String.join(objFieldList,',');
			String soql = 'select ' + objfields + ' from dealer__Deal__c where dealer__Sales_Lead__c=\'' + dsp.Id + '\' limit 1';
			List<dealer__Deal__c> ddlist = Database.query(soql);
			dealer__Deal__c dd = ddlist.size()>0 ? ddlist[0] : null;
			// BLL8 end
	        
	        dealer__Vehicle_Inventory__c vi = [select Id from dealer__Vehicle_Inventory__c limit 1];
	        
			dealer__Parts_Kit__c dpk = [select Id, Name from dealer__Parts_Kit__c limit 1];

	        ApexPages.StandardController sc = new ApexPages.StandardController(dd);
	        ApexPages.currentPage().getParameters().put('id', dd.id);
	        Deal_MBW2 dmb = new Deal_MBW2(new ApexPages.StandardController(dd));

			Test.startTest();	 
			
			dmb.setDefaultFees();
			
			dd.Deliver_to__c='Customer';
			dmb.chgDeliverTo();
			dd.Deliver_to__c='Releasing Dealer';
			dmb.chgDeliverTo();
			dd.Deliver_to__c='Store';
			dmb.chgDeliverTo();
			dd.Deliver_to__c='Other';
			dmb.chgDeliverTo();
			Deal_MBW2.TotalAllAMItems(dd.Id);

			Account cb = th.getPersonAccount('2');
			dd.dealer__Co_Buyer__c = cb.Id;
			dd.dealer__Status__c='Pending';
			dmb.markLost();
			dmb.markPending();	// BLL5a
			
			//BLL10d dmb.getMemberOfFIteam();
			//BLL10d dmb.applicationBackToStore();
			//BLL10d dmb.applicationReceived();
			//BLL10d dmb.applicationRejected();
			//BLL10d dmb.applicationApproved();
			//BLL10d dmb.btnSaveFandI();

			dmb.partItem = new Deal_MBW2.addParts();
			dmb.partItem.part = null;
			dmb.partItem.partNumber = 'Test';
			dmb.partItem.description = 'Test description';
			dmb.partItem.partQTY = 1;
			dmb.partItem.cost = 5;
			dmb.partItem.saleprice = 8;
			dmb.partItem.selectMultiple = false;

			Test.stopTest();
				 
		}
		
	}



	// unitTest6
	//---------------------------------------
	static testMethod void unitTest6() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();
			
	        Account a = [select Id, PersonContactId from Account where dealer__Vendor__c=false limit 1];	
	        Account v = [select Id, dealer__Vendor__c from Account where dealer__Vendor__c=true limit 1];	

			dealer__Sales_Up__c dsp = [select Id from dealer__Sales_Up__c limit 1];	
			// BLL8
	        //dealer__Deal__c dd = [select Id, RecordTypeId, dealer__Auto_Insurance_Agent__c, dealer__Deal_ID__c,
	        //	dealer__Sales_Lead__c, dealer__Status__c, dealer__Deal_Date__c, Proposed_Delivery_Date__c,
	        //	dealer__Vehicle__c, dealer__Buyer__c, dealer__Deal_Type__c, dealer__Salesperson_1__c,
			//	dealer__Desk_Manager__c, dtmob__Service_Manager__c, // BLL8
	        //	Commission_Employee_1__c, dealer__Store_Location__c
	        //	from dealer__Deal__c where dealer__Sales_Lead__c=:dsp.Id limit 1
	        //];
			Map<String, Schema.SObjectField> objFieldMap =  Schema.dealer__Deal__c.SObjectType.getDescribe().fields.getMap();
			List<String> objFieldList = new List<String>(extraFields);
			for(string f : objFieldMap.keySet()) if (objFieldMap.get(f).getDescribe().isAccessible()) objFieldList.add(f);
			String objfields = String.join(objFieldList,',');
			String soql = 'select ' + objfields + ' from dealer__Deal__c where dealer__Sales_Lead__c=\'' + dsp.Id + '\' limit 1';
			List<dealer__Deal__c> ddlist = Database.query(soql);
			dealer__Deal__c dd = ddlist.size()>0 ? ddlist[0] : null;
			// BLL8 end
	        
	        dealer__Vehicle_Inventory__c vi = [select Id from dealer__Vehicle_Inventory__c limit 1];
	        
			dealer__Parts_Kit__c dpk = [select Id, Name from dealer__Parts_Kit__c limit 1];

			// add a conversion build
			CommercialQuote__c cq = new CommercialQuote__c(
				Proposal__c = dd.Id,
				Customer__c = dd.dealer__Buyer__c,
				Location__c = dd.dealer__Store_Location__c,
				SolutionOpportunity__c=dd.dealer__Sales_Lead__c
			);
			insert(cq);
			dd.Commercial_Quote__c = cq.Id;
			update(dd);
	        
			Test.startTest();	 
			
	        ApexPages.StandardController sc = new ApexPages.StandardController(dd);
	        ApexPages.currentPage().getParameters().put('id', dd.id);
	        Deal_MBW2 dmb = new Deal_MBW2(new ApexPages.StandardController(dd));
	        dd.Contract_Type__c='Loan';	// BLL2a
	        dmb.saveProposal();

			Test.stopTest();
				 
		}
		
	}


	// unitTest7
	//---------------------------------------
	static testMethod void unitTest7() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();

	        Account a = [select Id, PersonContactId from Account where dealer__Vendor__c=false and isPersonAccount=true limit 1];	
	        Account v = [select Id, dealer__Vendor__c from Account where dealer__Vendor__c=true limit 1];	
	        System.debug(v);
			dealer__Sales_Up__c dsp = [select Id from dealer__Sales_Up__c limit 1];	
			// BLL8
	        //dealer__Deal__c dd = [select Id, RecordTypeId, dealer__Auto_Insurance_Agent__c, dealer__Deal_ID__c,
	        //	dealer__Sales_Lead__c, dealer__Status__c, dealer__Deal_Date__c, Proposed_Delivery_Date__c,
	        //	dealer__Vehicle__c, dealer__Buyer__c, dealer__Deal_Type__c, dealer__Salesperson_1__c,
			//	dealer__Desk_Manager__c, // BLL8
	        //	Commission_Employee_1__c
	        //	from dealer__Deal__c where dealer__Sales_Lead__c=:dsp.Id limit 1
	        //];	
			Map<String, Schema.SObjectField> objFieldMap =  Schema.dealer__Deal__c.SObjectType.getDescribe().fields.getMap();
			List<String> objFieldList = new List<String>(extraFields);
			for(string f : objFieldMap.keySet()) if (objFieldMap.get(f).getDescribe().isAccessible()) objFieldList.add(f);
			String objfields = String.join(objFieldList,',');
			String soql = 'select ' + objfields + ' from dealer__Deal__c where dealer__Sales_Lead__c=\'' + dsp.Id + '\' limit 1';
			List<dealer__Deal__c> ddlist = Database.query(soql);
			dealer__Deal__c dd = ddlist.size()>0 ? ddlist[0] : null;
			// BLL8 end

			dealer__Parts_Kit__c dpk = [select Id, Name, dealer__Description__c from dealer__Parts_Kit__c limit 1];

			Kit_Category__c kc = [select Id, External_ID__c, Order__c, Type__c from Kit_Category__c where Type__c='Category' limit 1];
			Kit_Category__c km = [select Id, External_ID__c, Order__c, Type__c from Kit_Category__c where Type__c='Manufacturer' limit 1];

			Test.startTest();

    	    dealer__After_Market__c dam = new dealer__After_Market__c();
    	    dam.dealer__Car_Deal__c =dd.id;
    	    //BLL1d dam.dealer__Company_Number__c='Location 1';
			dam.dealer__Company_Number__c=FFAdata.DealerLocation.dealer__Company_Number__c;	// BLL1
    	    dam.dealer__Cost__c=1;
    	    dam.dealer__Description__c='Test';
    	    dam.dealer__Labor_Sale__c=12;
    	    dam.dealer__List_Price__c=1;
    	    dam.dealer__Parts_Kit__c=dpk.id;
    	    dam.dealer__Parts_Sale__c=3; 
    	    dam.dealer__Sale_Price__c=4; 
    	    dam.dealer__Vendor__c=v.id;	 
    	    dam.Labor_Hours__c=1;
    	    dam.Taxable__c=True;
    	    dam.dealer__Sale_Price__c = 2;
    	    dam.Name='Test';
    	    insert dam;
        
	        dealer__Service_Vehicle__c  dsv = new dealer__Service_Vehicle__c ();
	        dsv.dealer__VIN__c ='Test';
	        dsv.Name='Test';
	        dsv.dealer__Body_Style__c = 'Test';
	        dsv.dealer__Company_Number__c='12123';
	        dsv.dealer__Veh_Owner_Contact__c = a.PersonContactId;
	        dsv.dealer__Carline__c ='Test';
	        dsv.dealer__Make__c  ='Test';
	        dsv.dealer__Year__c  ='2013';
	        insert dsv;
        
	        List<dealer__Form__c> dfms = new List<dealer__Form__c>();	// BLL4a

	        dealer__Form__c dfm = new dealer__Form__c();
	        dfm.dealer__Page_Name__c='Test';
	        dfm.Name='Test';
	        dfm.dealer__Print_Type__c='Impact';
	        dfms.add(dfm);	// BLL4a

			// BLL4a
			dfms.add(new dealer__Form__c(
	        	dealer__Page_Name__c='TestLaser',
	        	Name='TestLaser',
	        	dealer__Print_Type__c='Laser'
			));

			dfms.add(new dealer__Form__c(
	        	dealer__Page_Name__c='TestFDF',
	        	Name='TestFDF',
	        	dealer__Print_Type__c='FDF',
	        	AvailabilityExpression__c = '{!dealer__Deal__c.Id!=null}'
			));
	        
	        insert dfms;	// BLL4a

	        ApexPages.StandardController sc = new ApexPages.StandardController(dd);
	        ApexPages.currentPage().getParameters().put('id', dd.id);
	        Deal_MBW2 dmb = new Deal_MBW2(new ApexPages.StandardController(dd));
	        dmb.deal = dd;
	        Id selectedPartNumber = dmb.selectedPartNumber;
	        List<String> esctypes = dmb.getEscTypes();	// BLL1a

			// Misc
			boolean vt = dmb.viewTransactions;
			boolean icv = dmb.isCustomerVehicle;
			String subj = dmb.subject;
			String body = dmb.body;
			Blob ablob = dmb.abody;
			String ct = dmb.acontenttype;
			String fn = dmb.afilename;
			List<dealer__Parts_Master__c> pml = dmb.getPartsResults();
			List<Deal_MBW2.cPartsKit> aKits = dmb.aKits;
			Decimal amlt = dmb.afterMarketLbrTotal;
			List<dealer__Form__c> formList = dmb.formList;
			Component.Apex.outputPanel op = dmb.getFormsTableRows();	// BLL1a
			Decimal TaxTotal = dmb.TaxTotal;
			PageReference cp = dmb.gotoClonePage();
			PageReference erd = dmb.emailReleasingDealer();
			PageReference epdf = dmb.emailPDFDirect();
			// end misc
        
	        List<dealer__Trade_In__c> TradeList = dmb.tradeInList;
	        List<dealer__Service_Contract__c> soldOnProposal = dmb.soldOnProposal ;
	        boolean testmgp = dmb.hasMobilityGuardPowertrain;	// BLL2a 
	        //List<dealer__Service_Contract__c> soldOnProposalSC =dmb.soldOnProposalSC;
	        //List<dealer__Service_Contract__c> soldOnProposalGAP=dmb.soldOnProposalGAP;
	        //List<dealer__Service_Contract__c> soldOnProposalDF=dmb.soldOnProposalDF;
	        //List<dealer__Service_Contract__c> soldOnProposalRoad=dmb.soldOnProposalRoad;

	        Test.StopTest();	
			
		}
	}


	// unitTest8 - misc other conditions
	//---------------------------------------
	static testMethod void unitTest8() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();

	        Account a = [select Id, PersonContactId from Account where dealer__Vendor__c=false and isPersonAccount=true limit 1];	
	        Account v = [select Id, dealer__Vendor__c from Account where dealer__Vendor__c=true limit 1];	
	        System.debug(v);
			dealer__Sales_Up__c dsp = [select Id from dealer__Sales_Up__c limit 1];	
			// BLL8
	        //dealer__Deal__c dd = [select Id, RecordTypeId, dealer__Auto_Insurance_Agent__c, dealer__Deal_ID__c,
	        //	dealer__Sales_Lead__c, dealer__Status__c, dealer__Deal_Date__c, Proposed_Delivery_Date__c,
	        //	dealer__Vehicle__c, dealer__Buyer__c, dealer__Deal_Type__c, dealer__Salesperson_1__c,
			//	dealer__Desk_Manager__c, // BLL8
	        //	Commission_Employee_1__c
	        //	from dealer__Deal__c where dealer__Sales_Lead__c=:dsp.Id limit 1
	        //];	
			Map<String, Schema.SObjectField> objFieldMap =  Schema.dealer__Deal__c.SObjectType.getDescribe().fields.getMap();
			List<String> objFieldList = new List<String>(extraFields);
			for(string f : objFieldMap.keySet()) if (objFieldMap.get(f).getDescribe().isAccessible()) objFieldList.add(f);
			String objfields = String.join(objFieldList,',');
			String soql = 'select ' + objfields + ' from dealer__Deal__c where dealer__Sales_Lead__c=\'' + dsp.Id + '\' limit 1';
			List<dealer__Deal__c> ddlist = Database.query(soql);
			dealer__Deal__c dd = ddlist.size()>0 ? ddlist[0] : null;
			// BLL8 end

			update(new dealer__Vehicle_Inventory__c(Id=dd.dealer__Vehicle__c, dealer__Status_Code__c = 'Sold - Not Delivered'));

			Test.startTest();

	        ApexPages.StandardController sc = new ApexPages.StandardController(dd);
	        ApexPages.currentPage().getParameters().put('id', dd.id);
	        Deal_MBW2 dmb = new Deal_MBW2(new ApexPages.StandardController(dd));
	        dmb.deal = dd;
	        dd.dealer__Vehicle__c = v.id;
	        //dd.Vehicle_Status__c = 'Sold - Not Delivered';
	        dd.dealer__Status__c = 'Won - Delivery';
	        //dd.Open_Service_Repair_Orders__c = 1;
			dmb.RecordTypeName = 'Retail';
			dmb.issueWarningMsgs();

			// BLL9
			dmb.approveVA();
			dmb.revokeVA();
			// BLL9 end

			Test.stopTest();
			
		}
	}

	// TemplateMethod
	//---------------------------------------
	static testMethod void TemplateMethod() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
			
	        Account a = [select Id, PersonContactId from Account where dealer__Vendor__c=false limit 1];	
	        Account v = [select Id, dealer__Vendor__c from Account where dealer__Vendor__c=true limit 1];	

			dealer__Sales_Up__c dsp = [select Id from dealer__Sales_Up__c limit 1];	
			// BLL8
	        //dealer__Deal__c dd = [select Id, RecordTypeId, dealer__Auto_Insurance_Agent__c, dealer__Deal_ID__c,
	        //	dealer__Sales_Lead__c, dealer__Status__c, dealer__Deal_Date__c, Proposed_Delivery_Date__c,
	        //	dealer__Vehicle__c, dealer__Buyer__c, dealer__Deal_Type__c, dealer__Salesperson_1__c,
			//	dealer__Desk_Manager__c, // BLL8
	        //	Commission_Employee_1__c
	        //	from dealer__Deal__c where dealer__Sales_Lead__c=:dsp.Id limit 1
	        //];
			Map<String, Schema.SObjectField> objFieldMap =  Schema.dealer__Deal__c.SObjectType.getDescribe().fields.getMap();
			List<String> objFieldList = new List<String>(extraFields);
			for(string f : objFieldMap.keySet()) if (objFieldMap.get(f).getDescribe().isAccessible()) objFieldList.add(f);
			String objfields = String.join(objFieldList,',');
			String soql = 'select ' + objfields + ' from dealer__Deal__c where dealer__Sales_Lead__c=\'' + dsp.Id + '\' limit 1';
			List<dealer__Deal__c> ddlist = Database.query(soql);
			dealer__Deal__c dd = ddlist.size()>0 ? ddlist[0] : null;
			// BLL8 end
	        
	        dealer__Vehicle_Inventory__c vi = [select Id from dealer__Vehicle_Inventory__c limit 1];
	        
			dealer__Parts_Kit__c dpk = [select Id, Name from dealer__Parts_Kit__c limit 1];

	        ApexPages.StandardController sc = new ApexPages.StandardController(dd);
	        ApexPages.currentPage().getParameters().put('id', dd.id);
	        Deal_MBW2 dmb = new Deal_MBW2(new ApexPages.StandardController(dd));
	        
			Test.startTest();	 

			Test.stopTest();
				 
		}
		
	}


	// newDealEmptyReturn routines that return empty results
	//---------------------------------------
	static testMethod void newDealEmptyReturn() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
			
	        Account a = [select Id, PersonContactId from Account where dealer__Vendor__c=false limit 1];	
	        Account v = [select Id, dealer__Vendor__c from Account where dealer__Vendor__c=true limit 1];	

			dealer__Sales_Up__c dsp = [select Id from dealer__Sales_Up__c limit 1];	
	        dealer__Deal__c dd = new dealer__Deal__c(dealer__Sales_Lead__c=dsp.Id);

	        ApexPages.StandardController sc = new ApexPages.StandardController(dd);
	        Deal_MBW2 dmb = new Deal_MBW2(new ApexPages.StandardController(dd));
	        
			Test.startTest();	 

	        List<dealer__Trade_In__c> TradeList = dmb.tradeInList;
	        List<dealer__Service_Contract__c> soldOnProposal = dmb.soldOnProposal;
			List<dealer__After_Market__c> sk = dmb.selectedKits;
			Decimal amt = dmb.afterMarketTotal;
			Decimal amlt = dmb.afterMarketLbrTotal;
			Decimal sct = dmb.serviceContractTotal;
	        boolean testmgp = dmb.hasMobilityGuardPowertrain;	// BLL2a 
			dmb.saveProposal();

			// BLL2a
			Decimal gap = dmb.getGapAmount();
			Decimal svc = dmb.getServiceContractAmount();
			Decimal rsp = dmb.getRoadsideAmount();
			dealer__Service_Contract__c gapp = dmb.getGapPolicy();
			dealer__Service_Contract__c svcp = dmb.getServiceContractPolicy();
			dealer__Service_Contract__c rspp = dmb.getRoadsidePolicy();
			// BLL2a end
						
			Test.stopTest();
				 
		}
		
	}

	static testmethod void testLeaseCalc() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
			
	        Account a = [select Id, PersonContactId from Account where dealer__Vendor__c=false limit 1];	
	        Account v = [select Id, dealer__Vendor__c from Account where dealer__Vendor__c=true limit 1];	

			dealer__Sales_Up__c dsp = [select Id from dealer__Sales_Up__c limit 1];	
			// BLL8
	        //dealer__Deal__c dd = [select Id, RecordTypeId, dealer__Auto_Insurance_Agent__c, dealer__Deal_ID__c,
	        //	dealer__Sales_Lead__c, dealer__Status__c, dealer__Deal_Date__c, Proposed_Delivery_Date__c,
	        //	dealer__Vehicle__c, dealer__Buyer__c, dealer__Deal_Type__c, dealer__Salesperson_1__c,
			//	dealer__Desk_Manager__c, // BLL8
	        //	Commission_Employee_1__c
	        //	from dealer__Deal__c where dealer__Sales_Lead__c=:dsp.Id limit 1
	        //];
			Map<String, Schema.SObjectField> objFieldMap =  Schema.dealer__Deal__c.SObjectType.getDescribe().fields.getMap();
			List<String> objFieldList = new List<String>(extraFields);
			for(string f : objFieldMap.keySet()) if (objFieldMap.get(f).getDescribe().isAccessible()) objFieldList.add(f);
			String objfields = String.join(objFieldList,',');
			String soql = 'select ' + objfields + ' from dealer__Deal__c where dealer__Sales_Lead__c=\'' + dsp.Id + '\' limit 1';
			List<dealer__Deal__c> ddlist = Database.query(soql);
			dealer__Deal__c dd = ddlist.size()>0 ? ddlist[0] : null;
			// BLL8 end
	        
	        dealer__Vehicle_Inventory__c vi = [select Id from dealer__Vehicle_Inventory__c limit 1];
	        
			dealer__Parts_Kit__c dpk = [select Id, Name from dealer__Parts_Kit__c limit 1];

	        ApexPages.StandardController sc = new ApexPages.StandardController(dd);
	        ApexPages.currentPage().getParameters().put('id', dd.id);
	        Deal_MBW2 dmb = new Deal_MBW2(new ApexPages.StandardController(dd));

			dealer__Finance_Company__c fc = new dealer__Finance_Company__c(
				Name='Test Financial Inst',
				AcquisitionFee__c = 500,
				dealer__New_Vehicle_Rate__c = 0.321,
				dealer__Used_Vehicle_Rate__c = 0.321
			);
			insert(fc);
	        
			Test.startTest();
			dd.dealer__Finance_Institution_Account__c = fc.Id;
			dd.ChassisMSRP__c = 20000;
			dd.ConversionMSRP__c = 15000;
			dd.ChassisResidualPct__c = 25;
			dd.ConversionResidualPct__c = 65;
			dd.Contract_Number_of_Payments__c = 36;
			dd.LeaseMoneyFactor__c = 0.00321;
			dd.Chassis_Price__c = 21000;
			dd.Conversion_Price__c = 18000;
			dd.Contract_Type__c = 'Lease';
			dmb.initLease();
			dmb.calculateLeasePmt();
			dd.DesiredUpfrontCash__c = 5000;
			dmb.LeaseDesiredUpfrontCash();
			dd.DesiredUpfrontCash__c = 5000;
			dmb.lease.DownPayment=-1;	// BLL5a
			dmb.LeaseDesiredUpfrontCash();	// BLL5a
			
			// BLL5a additional lease logic
        	dmb.lease.SalesTaxMethod='Monthly Up-front';
        	dmb.saveLeaseResults();
        	dmb.lease.SalesTaxMethod='Monthly';
        	dmb.saveLeaseResults();
			// BLL5a end

			// BLL9
			dd.DesiredUpfrontCash__c = null;
			dmb.lease.DownPayment=null;	// BLL5a
			dmb.LeaseDesiredUpfrontCash();	// BLL5a
			// BLL9 end

			// BLL4a - validation fails
			dd.ChassisResidualPct__c = null;
			dd.ConversionResidualPct__c = null;
			dd.LeaseMoneyFactor__c = null;
			dd.Contract_Number_of_Payments__c = null;	 
			dmb.validateLeaseData();

			// Loan calcs
			dd.Contract_Type__c= 'Loan';
			dmb.FinancialInstitutionDefaults();

			Test.stopTest();
				 
		}
	} 

	static testmethod void testNewDeal() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
			Map<String, Schema.RecordTypeInfo> dealRcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();	// BLL11a
			dealer__Sales_Up__c dsp = [select Id from dealer__Sales_Up__c limit 1];	
   	    	dealer__Deal__c dd = new dealer__Deal__c();
    	    dd.Name = 'Test';
    	    dd.RecordTypeId = dealRcdTypes.get('Retail').getRecordTypeId();
   	    	dd.dealer__Deal_Type__c = 'Chassis/Conversion';	
    	    dd.dealer__Auto_Insurance_Agent__c='Test';
    	    dd.dealer__Deal_ID__c ='Test';
    	    dd.dealer__Sales_Lead__c = dsp.id;
    	    dd.dealer__Status__c ='Pending';
    	    dd.dealer__Deal_Date__c =System.Today();
    	    dd.dealer__Salesperson_1__c = UserInfo.getUserId();

	        ApexPages.StandardController sc = new ApexPages.StandardController(dd);
	        ApexPages.currentPage().getParameters().put('id', dd.id);
	        Deal_MBW2 dmb = new Deal_MBW2(new ApexPages.StandardController(dd));	// BLL9
		}
	}

	// BLL9
	static testmethod void testEquipmentOnlyDeal() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
			Map<String, Schema.RecordTypeInfo> dealRcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();	// BLL11a
			dealer__Sales_Up__c dsp = [select Id from dealer__Sales_Up__c limit 1];	
	   	    dealer__Deal__c dd = new dealer__Deal__c();
    	    dd.Name = 'Test';
    	    dd.RecordTypeId = dealRcdTypes.get('Retail').getRecordTypeId();
   	    	dd.dealer__Deal_Type__c = 'Equipment Only';	
    	    dd.dealer__Auto_Insurance_Agent__c='Test';
    	    dd.dealer__Deal_ID__c ='Test';
    	    dd.dealer__Sales_Lead__c = dsp.id;
    	    dd.dealer__Status__c ='Pending';
    	    dd.dealer__Deal_Date__c =System.Today();
    	    dd.dealer__Salesperson_1__c = UserInfo.getUserId();

			Test.startTest();
	        ApexPages.StandardController sc = new ApexPages.StandardController(dd);
	        ApexPages.currentPage().getParameters().put('id', dd.id);
	        Deal_MBW2 dmb = new Deal_MBW2(new ApexPages.StandardController(dd));
			dmb.saveProposal();

			// new method to test as well
			MobilityForceSettings__c mfs = MobilityForceSettings__c.getInstance();
			mfs.DealMBW2Printing__c = false;
			upsert(mfs);
			dmb.gotoFormsPage();
			mfs.DealMBW2Printing__c = true;
			upsert(mfs);
			dmb.gotoFormsPage();
			dmb.removeVehicle();

			dmb.serviceItem = new Deal_MBW2.addService();
			dmb.serviceItem.description = 'Test';
			dmb.serviceItem.booktime = 1.0;
			dmb.serviceItem.cost = 50;
			dmb.serviceItem.saleprice = 50;
			dmb.serviceItem.taxable = true;

			dealer__Parts_Master__c pm = [select Id from dealer__Parts_Master__c limit 1];
			dmb.selectedPartNumber = pm.Id;
			dmb.savePartOnProposal();

			Test.stopTest();
		}
	}
	// BLL9 end 

	// AMM10
	public static testMethod void testFavoriteClick()
	{		
		Test.startTest();
		
		// Test the click
		dealer__Parts_Kit__c tempPartsKit = new dealer__Parts_Kit__c();
		tempPartsKit.dealer__Description__c = 'Favorite';
		insert tempPartsKit;
		Deal_MBW2.favoriteClick(tempPartsKit.Id, true, null, true);
		Deal_MBW2.favoriteClick(tempPartsKit.Id, false, null, true);			
		Test.stopTest();
	}
	// AMM10

}