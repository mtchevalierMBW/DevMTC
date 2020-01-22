/**
 * AvaTax_MBW_TEST
 * Tests: AvaTax_MBW
 * Programmer: Bryan Leaman
 * Date: 2015-11-12
 * 
 *	2016-01-30	B. Leaman	BLL1 - Set up tax rule that runs some extra code.
 *	2016-05-05	B. Leaman	BLL2 - add additional tax rule overrides to test more code.
 *	2016-08-02	B. Leaman	BLL3 - add test setup to provide dealerteam base settings.
 *	2016-10-10	B. Leaman	BLL4 - test do not collect out-of-state taxes logic (increase coverage)
 * 	2016-11-29	B. Leaman	BLL5 - Add test for adjustTax routine (used to un-commit taxes)
 *	2016-12-14	B. Leaman	BLL6 - Fix error caused by new validation rule that discount cannot exceed customer charges.
 *	2017-02-27	B. Leaman	BLL7 - Adjustments for commercial record type
 *	2017-06-09	B. Leaman	BLL8 - New routine to test for sales tax paid monthly with lease pmt.
 *							increase coverage.
 *	2018-01-11	B. Leaman	BLL9 - increase coverage, DME
 *	2018-05-29	B. Leaman	BLL10 - Correct for new validation rule on service estimate lines; increase coverage & new "With Cert" logic;
 *
 */
@isTest
private class AvaTax_MBW_TEST {

	// BLL9a
	// can't with seeAllData @testSetup
	static void setupData() {
		dealer.TestClassUtil tc = new dealer.TestClassUtil();	// BLL3a   
	    tc.insertDMSSettings();   	// BLL3a
		
        // BLL1a 
        List<TaxRuleSetting__c> taxrules = new List<TaxRuleSetting__c>();	// BLL4a
        TaxRuleSetting__c taxrule = new TaxRuleSetting__c(
        	Name='Testing',
        	Chassis__c = 'P0000000',
        	Conversion__c = 'PH050301',
        	ConversionWithCert__c = 'PH050302',
        	ChassisLessTrade__c = 'P0000000',
        	LuxuryValue__c = 9000,
        	LuxuryVehicle__c = 'P0000000',
        	// BLL9a
        	CombineDocFeeWithChassis__c = true,
        	AutoGrant_NetChassis__c = true,
        	GPC_NetChassis__c = true,
			Chassis_AtStore__c = true,
			ConversionGrant__c = 'NT',
			// BLL10a
			Trade_NetChassis__c = true,
			ChassisMinTaxable__c = 1000,
			AdaptiveEquipment__c = 'PH050301',
			AdaptiveEquipmentTX__c = 'P000000',
			AdaptiveEquipWithCert__c = 'PH050302',
			AdaptiveEquipLabor__c = 'PH050301',
			AdaptiveEquipLaborTX__c = 'P000000',
			AdaptiveEquipLaborWithCert__c = 'PH050302',
			AdaptiveEquipSublet__c = 'PH050301',
			AdaptiveEquipSubletTX__c = 'P000000',
			AdaptiveEquipSubletWithCert__c = 'PH050302',
			RepairParts__c = 'P0000000',
			RepairPartsTX__c = 'P0000000',
			RepairPartsWithCert__c = 'P0000000',
			RepairLabor__c = 'P0000000',
			RepairLaborTX__c = 'P0000000',
			RepairLaborWithCert__c = 'P0000000',
			RepairSublet__c = 'P0000000',
			RepairSubletTX__c = 'P0000000',
			RepairSubletWithCert__c = 'P0000000',
			// BLL10a end
			CombineConversionWithChassis__c=true
        );
        //BLL4d insert(taxrule);
        // BLL4a
        taxrules.add(taxrule);	
        taxrules.add(new TaxRuleSetting__c(
        	Name='Testing2',
        	StateDefault__c='DC'
		));
        insert(taxrules);
        // BLL4a
        // BLL2a
        List<TaxRuleOverride__c> trolist = new List<TaxRuleOverride__c>();	// BLL4a
        TaxRuleOverride__c tro1 = new TaxRuleOverride__c(
        	TaxRuleSetting__C=taxrule.Id,
        	FieldName__c='AddedEquipment',
        	Condition__c='EquipmentOnlyDeal',
        	TaxCode__c='P0000000', TaxCodeTX__c='P0000000', TaxCodeWithCert__c='P0000000'
        );
        //BLL4dinsert(tro1);
        trolist.add(tro1);	// BLL4a
        TaxRuleOverride__c tro2 = new TaxRuleOverride__c(
        	TaxRuleSetting__C=taxrule.Id,
        	FieldName__c='AddedEquipSublet',
        	Condition__c='EquipmentOnlyDeal',
        	TaxCode__c='P0000000', TaxCodeTX__c='P0000000', TaxCodeWithCert__c='P0000000'
        );
        //BLL4d insert(tro2);
        trolist.add(tro2);	// BLL4a
        TaxRuleOverride__c tro3 = new TaxRuleOverride__c(
        	TaxRuleSetting__C=taxrule.Id,
        	FieldName__c='AddedEquipLabor',
        	Condition__c='EquipmentOnlyDeal',
        	TaxCode__c='P0000000', TaxCodeTX__c='P0000000', TaxCodeWithCert__c='P0000000'
        );
        //BLL4d insert(tro3);
        trolist.add(tro3);	// BLL4a

		// BLL9a
        trolist.add(new TaxRuleOverride__c(
        	TaxRuleSetting__C=taxrule.Id,
        	FieldName__c='AddedEquipment',
        	Condition__c='DME/Other',
        	TaxCode__c='P0000000', TaxCodeTX__c='P0000000', TaxCodeWithCert__c='P0000000'
        ));
        trolist.add(new TaxRuleOverride__c(
        	TaxRuleSetting__C=taxrule.Id,
        	FieldName__c='AddedEquipSublet',
        	Condition__c='DME/Other',
        	TaxCode__c='P0000000', TaxCodeTX__c='P0000000', TaxCodeWithCert__c='P0000000'
        ));
        trolist.add(new TaxRuleOverride__c(
        	TaxRuleSetting__C=taxrule.Id,
        	FieldName__c='AddedEquipLabor',
        	Condition__c='DME/Other',
        	TaxCode__c='P0000000', TaxCodeTX__c='P0000000', TaxCodeWithCert__c='P0000000'
        ));
        // BLL9a end

        insert(trolist);	// BLL4a
        // BLL2a end
		
		
	}
	// BLL9a end
	
    static testMethod void dealTaxes() {
		setupData();	// BLL9a
        TestHelper_MW th = new TestHelper_MW();
        Account buyer = th.getPersonAccount('1');
        Account tpp = th.getThirdPartyAccount('1');
        dealer__Dealer_Location__c loc = th.getDealerLocation('1');
        
        TaxRuleSetting__c taxrule = [select Id, Name from TaxRuleSetting__c where Name='Testing' limit 1];
        
        // BLL4a Assign tax rules to location
        loc.TaxRuleSetting__c = taxrule.Id;
        update(loc);
        // BLL4a end
        
        Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();

        // Don't need a saved deal for this to work
        dealer__Deal__c deal = new dealer__Deal__c(
            Name='TestDeal', 
	        //BLL7d RecordTypeId=RcdTypes.get('Equipment Only Sale').getRecordTypeId(),	// BLL4a
	        RecordTypeId=RcdTypes.get('Retail').getRecordTypeId(),	// BLL7a
	        dealer__Deal_Type__c = 'Equipment Only',	// BLL7a
            dealer__Deal_ID__c='TestDeal123',
            dealer__Store_Location__c=loc.Id, 
            dealer__Buyer__c=buyer.Id, 
            dealer__Buyer_Address__c = '1600 Pennsylvania Ave', 
            dealer__Buyer_City__c='Washington', 
            dealer__Buyer_State__c='DC', 
            dealer__Buyer_Postal_Code__c='20500',
            dealer__Vehicle__c=null, 
			dealer__Business_Address__c = '1601 Pennsylvania Ave',	// BLL9a
			dealer__Business_City__c = 'Washington',	// BLL9a
			dealer__Business_State__c = 'DC',	// BLL9a
			dealer__Business_Postal_Code__c = '20500',	// BLL9a
            Proposed_Delivery_Date__c=Date.today(),
            Chassis_Price__c=10000, 
            Conversion_Taxable__c=false, 
            Conversion_Price__c=1000,
            Conversion_Discount__c=100,
            GVW_GVWR__c=5, 
            Tire_Fee__c=10, 
            Smog_Fee__c=20, 
            Electronic_Filing_Fee__c=30, 
            dealer__Doc_Fee__c=40, 
            dealer__License_Fee__c=50,
            Registration_Title_Fee__c=60, 
            Smog_Cert__c=70, 
            dealer__Sales_Tax__c=80,
            dealer__Rebate__c=100, 
            Rebate_Description__c='Rebate 1', 
            Rebate_2__c=200, 
            Rebate_2_Description__c='Rebate 2', 
            Rebate_3__c=300, 
            Rebate_3_Description__c='Rebate 3',
            MBW_Rewards__c=50,
            AutoGrant__c=5,
            Government_Price_Concession__c=5,
            dtmob__Auto_Grant_Payor__c = tpp.Id,
            dealer__Deferred_Note_1__c = '1394',
            Third_Party_Pay_1__c = tpp.Id,
            Total_Price__c=1500.00,
			dealer__Deferred_Down_1__c=1000	// BLL10a
        );
        // TODO: Create deal, add aftermarket, trade, esc
        Test.startTest();
        
		deal.dealer__Deal_Type__c='Equipment Only Sale';	// BLL4a
        AvaTax_MBW tax = AvaTax_MBW.getInstanceDeal(deal);
        
        tax.getAvataxClient();
        tax.getHash();
        Test.setMock(WebServiceMock.class, new AvaTaxRequestMock());
        tax.calculateTax();
        // BLL8a
        //tax.getLeaseSalesTaxInPmt();
        tax.getLeaseTaxMethod();
        tax.debugRequestSummary();	
        tax.debugTaxRequestLines();	
        tax.debugTaxResultSummary();
        tax.useFairMarketValue();
        tax.getFairMarketValueURL();
        tax.getShowPartLaborSplit();
        tax.showChassisTaxableSelection();
        // BLL8a end
        insert(deal);
        dealer__After_Market__c m = new dealer__After_Market__c(
            Name='Misc', dealer__Car_Deal__c = deal.Id, 
            dealer__Cost__c = 1.00, dealer__Sale_Price__c = 2.00, 
            dealer__Company_Number__c = loc.dealer__Company_Number__c
        );
        insert(m);
        dealer__Trade_In__c t = new dealer__Trade_In__c(
            Name='Test trade', dealer__Make__c = 'Toyota', dealer__Model__c = 'Sienna', dealer__Year__c = '2000',
            dealer__VIN__c = '12345678901234567', dealer__Car_Deal__c = deal.Id,
            dealer__ACV__c = 2000, dealer__Trade_Allowance__c = 2000, dealer__Odometer_At_Trade_In__c = 160000
        );
        insert(t);
        AvaTax_MBW tax2 = AvaTax_MBW.getInstanceDealId(deal.Id);

        Test.setMock(WebServiceMock.class, new AvaTaxRequestMock());
        Avatax_MBW.postDealsFuture(new Set<Id>{deal.Id});

        buyer.SalesTaxStatus__c = 'Exempt';
        update(buyer);
        tax = AvaTax_MBW.getInstanceDeal(deal);
        buyer.ExemptionCertificate__c='n/a';
        update(buyer);
        tax = AvaTax_MBW.getInstanceDeal(deal);

		// BLL4a Try out-of-state logic
		deal.DoNotCollectTax__c = true;
		//BLL7d deal.dealer__Deal_Type__c='Retail Vehicle Sale';
		deal.dealer__Deal_Type__c = 'Chassis/Conversion';	// BLL7a
		//BLL7d deal.RecordTypeId=RcdTypes.get('Retail Vehicle Sale').getRecordTypeId();
		deal.RecordTypeId=RcdTypes.get('Retail').getRecordTypeId();	// BLL7a
		deal.HaveRequiredTaxCert__c = true;	// BLL10a
        tax = AvaTax_MBW.getInstanceDeal(deal);
        // BLL4a end

		// BLL10a
		tax.getTaxDocumentRequired();
		tax.saveDealTaxHeader();
		tax.saveDealTaxDetail();
		// BLL10a end

        Test.stopTest();
    }
    
	// BLL10a
    static testMethod void testCancelTax() {
		setupData();	// BLL9a
        TestHelper_MW th = new TestHelper_MW();
        Account buyer = th.getPersonAccount('1');
        Account tpp = th.getThirdPartyAccount('1');
        dealer__Dealer_Location__c loc = th.getDealerLocation('1');
        
        TaxRuleSetting__c taxrule = [select Id, Name from TaxRuleSetting__c where Name='Testing' limit 1];
        
        // BLL4a Assign tax rules to location
        loc.TaxRuleSetting__c = taxrule.Id;
        update(loc);
        // BLL4a end
        
        Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();

        // Don't need a saved deal for this to work
        dealer__Deal__c deal = new dealer__Deal__c(
            Name='TestDeal', 
	        //BLL7d RecordTypeId=RcdTypes.get('Equipment Only Sale').getRecordTypeId(),	// BLL4a
	        RecordTypeId=RcdTypes.get('Retail').getRecordTypeId(),	// BLL7a
	        dealer__Deal_Type__c = 'Equipment Only',	// BLL7a
            dealer__Deal_ID__c='TestDeal123',
            dealer__Store_Location__c=loc.Id, 
            dealer__Buyer__c=buyer.Id, 
            dealer__Buyer_Address__c = '1600 Pennsylvania Ave', 
            dealer__Buyer_City__c='Washington', 
            dealer__Buyer_State__c='DC', 
            dealer__Buyer_Postal_Code__c='20500',
            dealer__Vehicle__c=null, 
			dealer__Business_Address__c = '1601 Pennsylvania Ave',	// BLL9a
			dealer__Business_City__c = 'Washington',	// BLL9a
			dealer__Business_State__c = 'DC',	// BLL9a
			dealer__Business_Postal_Code__c = '20500',	// BLL9a
            Proposed_Delivery_Date__c=Date.today(),
            Chassis_Price__c=10000, 
            Conversion_Taxable__c=false, 
            Conversion_Price__c=1000,
            Conversion_Discount__c=100,
            GVW_GVWR__c=5, 
            Tire_Fee__c=10, 
            Smog_Fee__c=20, 
            Electronic_Filing_Fee__c=30, 
            dealer__Doc_Fee__c=40, 
            dealer__License_Fee__c=50,
            Registration_Title_Fee__c=60, 
            Smog_Cert__c=70, 
            dealer__Sales_Tax__c=80,
            dealer__Rebate__c=100, 
            Rebate_Description__c='Rebate 1', 
            Rebate_2__c=200, 
            Rebate_2_Description__c='Rebate 2', 
            Rebate_3__c=300, 
            Rebate_3_Description__c='Rebate 3',
            MBW_Rewards__c=50,
            AutoGrant__c=5,
            Government_Price_Concession__c=5,
            dtmob__Auto_Grant_Payor__c = tpp.Id,
            dealer__Deferred_Note_1__c = '1394',
            Third_Party_Pay_1__c = tpp.Id,
            Total_Price__c=1500.00,
			dealer__Deferred_Down_1__c=1000	// BLL10a
        );
        insert(deal);
        
        Test.startTest();
        
        AvaTax_MBW tax = AvaTax_MBW.getInstanceDealId(deal.Id);
        
        Test.setMock(WebServiceMock.class, new AvaTaxRequestMock());
        tax.cancelTax('Testing');
        
        Test.stopTest();
    }
    // BLL10a end
    
    @isTest // (seeAllData=true)
    static void repairOrderTaxes() {
    	setupData();
		//dealer.TestClassUtil tc = new dealer.TestClassUtil();
	    //tc.insertDMSSettings();
	    
        TestHelper_MW th = new TestHelper_MW();
        Account buyer = th.getPersonAccount('1');
        buyer.BillingStreet='1600 Pennsylvania Ave';
        buyer.BillingCity='Washington';
        buyer.BillingState='DC'; 
        buyer.BillingPostalCode='16000';
        update(buyer);
        dealer__Dealer_Location__c loc = th.getDealerLocation('1');
        Contact c = [select Id from Contact where AccountId=:buyer.Id limit 1];

        dealer__Service_Vehicle__c  dsv = new dealer__Service_Vehicle__c (
            dealer__VIN__c ='Testxx',
            Name='Test',
            dealer__Body_Style__c = 'Test',
            dealer__Company_Number__c=loc.dealer__Company_Number__c,
            dealer__Veh_Owner_Contact__c = c.Id,
            dealer__Carline__c ='Test',
            dealer__Make__c  ='Test',
            dealer__Year__c  ='2013',
            dealer__Last_Service__c =system.today(),
            dealer__Last_Activity__c =system.today()
        );
        insert dsv;

        //c2g__codaGeneralLedgerAccount__c cgd = new c2g__codaGeneralLedgerAccount__c(
        //  c2g__ReportingCode__c ='58',
        //  c2g__Type__c='Manual Journal',
        //  Name='Test'
        //);
        //insert cgd;

        //c2g__codaDimension1__c dim1 = new c2g__codaDimension1__c(
        //  Name ='Test',
        //  c2g__ReportingCode__c ='Test'
        //);
        //insert dim1;  

        dealer__Service_Repair_Order__c sro = new dealer__Service_Repair_Order__c(
            Name='TestRO', 
            dealer__Company__c=loc.Id,
            dealer__Company_Number__c=loc.dealer__Company_Number__c,
            dealer__Customer__c=buyer.Id,
            dealer__Customer_Contact__c=c.Id,
            dealer__Mileage_In__c = 12,
            dealer__RO_Number__c = '11',
            dealer__Status__c = 'Open',
            dealer__Customer_Charges__c = 12,
            dealer__Tax__c = 11,
            dealer__Hazardous_Materials__c = 16,
            dealer__Shop_Supplies__c= 12,
            dealer__Discount_Total__c = 0	// BLL6c dealer__Discount_Total__c = 11
        );
        insert(sro);

        ServicePaymentType__c spt = new ServicePaymentType__c(
            Default_Labor_Rate__c=12,
            Payment_Type__c='C',
            Description__c='Test',
            Shop_Supplies_Rate__c=12,
            Hazmat_Fee__c=12,
            Freight_Rate__c=12
            //Labor_Sale_Account__c=cgd.id,
            //Labor_Cost_of_Sale_Account__c=cgd.id,
            //Warranty_Receivable_Account__c=cgd.id,
            //Parts_Cost_of_Sale__c=cgd.id,
            //Parts_Inventory__c=cgd.id,
            //Work_In_Process__c=cgd.id,
            //Parts_Sales__c=cgd.id,
            //Internal_Sales__c=cgd.id,  
            //Sublet_CS__c=cgd.id,
            //Sublet_Sales__c=cgd.id,
            //Sublet_Inventory__c=cgd.id
        );
        insert spt; 

        dealer__StandardOpCode__c dso= new dealer__StandardOpCode__c(
            Name ='Test'
        );
        insert dso;

        dealer__Service_Job__c dsj = new dealer__Service_Job__c(
            dealer__Service_Repair_Order__c = sro.id, 
            dealer__Actual_Time__c = 12,
            dealer__Book_Time__c = 12,
            dealer__Cause__c = 'Test',
            dealer__Concern__c = 'Test',
            dealer__Correction__c = 'Test',
            dealer__Estimate__c = 12,
            dealer__Job_Added_Date__c = system.today(),
            dealer__Job_Line_Id__c = 'Test',
            dealer__Labor_Charges__c = 12,
            dealer__Labor_Rate__c = 'Test',
            dealer__Labor_Type__c = 'C',
            dealer__Line_Number__c = 12,
            dealer__Op_Code__c = 'Test',
            dealer__Parent_Record__c = 'Test',
            dealer__Parts_Cost__c = 12,
            //dealer__Parts_Line__c = dpi.id,
            dealer__Parts_Total__c = 12,
            dealer__Service_Type__c = 'MR',
            dealer__Standard_Operation_Code__c = dso.id,
            dealer__Stat__c = 'Test',
            dealer__Sublet_Total__c = 12,
            dealer__Technician_Cost__c = 12,
            dealer__Technician__c = Userinfo.getuserid(),
            Payment_Notes__c = 'Test',
            dealer__Add_On__c = True,
            dealer__Misc_Charges__c = 12,
            dealer__Op_Description__c = 'Test',
            dealer__Technician_ID__c = 'Test',
            dealer__CustomerConcern__c = 'Test',
            dealer__Claim__c = 'Test',
            dealer__Paid_By__c = buyer.id,
            Payment_Method__c = spt.id,
            External_ID__c = 'Test' 
        );
        insert dsj;
        
        ServiceMiscCharges__c misc = new ServiceMiscCharges__c(
            Type__c='Freight', 
            Service_Job_Line__c=dsj.Id,
            Amount__c=1.00
        );
        insert(misc);
        
        Test.startTest();
        AvaTax_MBW tax = AvaTax_MBW.getInstanceSROId(sro.Id);
        AvaTax_MBW tax2 = AvaTax_MBW.getInstanceSRO(sro);
        
        //tax.getAvataxClient();
        //tax.getHash();
        Test.setMock(WebServiceMock.class, new AvaTaxRequestMock());
        tax.calculateTax();

        tax.gettaxRslt = new TaxSvc.getTaxResult();
        tax.gettaxRslt.TaxLines = new TaxSvc.ArrayOfTaxLine();
        tax.gettaxRslt.TaxLines.TaxLine = new List<TaxSvc.TaxLine>();
        tax.gettaxRslt.TaxLines.TaxLine.add(new TaxSvc.TaxLine());
        tax.gettaxRslt.TaxLines.TaxLine[0].No = '1: Parts';
        tax.gettaxRslt.TaxLines.TaxLine[0].TaxCalculated = 1.00;
        tax.summarizeTaxByRepairLine();
        
        tax.saveServiceTaxHeader();
        tax.saveServiceTaxDetail();
        
        Test.setMock(WebServiceMock.class, new AvaTaxRequestMock());
        Avatax_MBW.postServiceFuture(new Set<Id>{sro.Id});

        buyer.SalesTaxStatus__c = 'Exempt';
        update(buyer);
        tax = AvaTax_MBW.getInstanceSRO(sro);
        buyer.ExemptionCertificate__c='n/a';
        update(buyer);
        tax = AvaTax_MBW.getInstanceSRO(sro);
        
        Test.stopTest();
    }
    
    static testMethod void rentalTaxes() {
		//dealer.TestClassUtil tc = new dealer.TestClassUtil();	// BLL3a   
	    //tc.insertDMSSettings();   	// BLL3a
        TestHelper_MW th = new TestHelper_MW();
        Account buyer = th.getPersonAccount('1');
        dealer__Dealer_Location__c loc = th.getDealerLocation('1');

        // Don't need a saved deal for this to work
        dealer__Rental_Agreements__c ra = new dealer__Rental_Agreements__c(
            Location__c=loc.Id,
            Account__c=buyer.Id,
            Excess_Miles_Charge__c = 0.00,
            dealer__Refueling_Fee__c = 0.00,
            dealer__Discount__c = 0.00,
            Sales_Tax__c = 0.00,
            CountySalesTax__c = 0.00,
            CitySalesTax__c = 0.00,
            ThirdTierRentalTax__c = 0.00,
            dealer__Return_Date__c = Date.today(),
            Rental_fee__c = 100.00,
            Pickup_Delivery_Fee__c = 0.00, 
            dealer__Adjustment_Charges__c = 0.00,
            dealer__Deposit_Amount__c = 0.00,
            Rentcentric_Contract__c = 'TESTING',
            dealer__Date_DUE_In__c = Date.today(),
            dealer__Drivers_Birthdate__c = Date.newInstance(1915, 1, 1),
            dealer__Drivers_Lic__c = 'n/a',
            dealer__Drivers_Lic_Exp__c = Date.today().addYears(2),
            dealer__Fuel_Charge_per_Gallon__c = 0,
            dealer__Insurer__c = 'See RentCentric',
            dealer__Return_Mileage__c = 101,
            dealer__Mileage_Out__c = 10,
            dealer__Policy_No__c = 'See RentCentric',
            dealer__Policy_Expiration_Date__c = Date.today().addYears(1),
            dealer__Time_OUT__c = '06:00:00',
            dealer__Time_DUE_IN__c = '20:00:00',
            dealer__Excess_Miles_Fee__c = 1.00
        );
        Test.startTest();
        AvaTax_MBW tax = AvaTax_MBW.getInstanceRental(ra);
        tax.updRentalTaxHeader(ra);
        
        //tax.getAvataxClient();
        //tax.getHash();
        //Test.setMock(WebServiceMock.class, new AvaTaxRequestMock());
        //tax.calculateTax();
        insert(ra);
        
        Test.setMock(WebServiceMock.class, new AvaTaxRequestMock());
        Avatax_MBW.postRentalFuture(new Set<Id>{ra.Id});

        buyer.SalesTaxStatus__c = 'Exempt';
        update(buyer);
        tax = AvaTax_MBW.getInstanceRental(ra);
        buyer.ExemptionCertificate__c='n/a';
        update(buyer);
        tax = AvaTax_MBW.getInstanceRental(ra);
        
        Test.stopTest();
    }
    
    @isTest(seeAllData=true)
    static void testWithData() {
        Test.startTest();
        try {
        dealer__Deal__c deal = [select Id from dealer__Deal__c where dealer__Status__c != 'Won - Delivered' limit 1 ];
            AvaTax_MBW dealtax = AvaTax_MBW.getInstanceDealId(deal.Id);
            dealtax.calculateTax();
            dealtax.summarizeTaxResult();
            dealtax.saveDealTaxHeader();
            dealtax.saveDealTaxDetail();
            AvaTax_MBW.postDealsFuture(new Set<Id>{deal.Id});
        } catch(Exception e1) {}

        try {
            dealer__Service_Repair_Order__c sro = [select Id from dealer__Service_Repair_Order__c limit 1];
            AvaTax_MBW srotax = AvaTax_MBW.getInstanceSROId(sro.Id);
        } catch(Exception e2) {}

        try {
            dealer__Rental_Agreements__c ra = [select Id from dealer__Rental_Agreements__c limit 1];
            AvaTax_MBW renttax = AvaTax_MBW.getInstanceRentalId(ra.Id);
        } catch(Exception e3) {}
        Test.stopTest();
    }
    
    // Test TaxSvc
    static testMethod void taxServices() {
        TaxSvc.TaxSvcSoap client = new TaxSvc.TaxSvcSoap('https://development.avalara.net');
        client.Security = new TaxSvc.Security();
        client.Security.UsernameToken.Username = '1100154358';
        client.Security.UsernameToken.Password = 'AFB71E14294BE4AE';
        client.Profile = new TaxSvc.Profile();
        client.Profile.Client = 'MobilityWorks,1,0';

        TaxSvc.TaxAddress addr = new TaxSvc.TaxAddress();
        TaxSvc.TaxDetail det = new TaxSvc.TaxDetail();
        TaxSvc.TaxLine taxline = new TaxSvc.TaxLine();
        TaxSvc.Line line = new TaxSvc.Line();
        TaxSvc.Message msg = new TaxSvc.Message();

        Test.setMock(WebServiceMock.class, new AvaTaxRequestMock());

        TaxSvc.PingResult ping = client.Ping('ping');

        TaxSvc.IsAuthorizedResult auth = client.IsAuthorized('test');

        TaxSvc.PostTaxRequest PostTaxRequest = new TaxSvc.PostTaxRequest();
        TaxSvc.PostTaxResult post = client.PostTax(PostTaxRequest);

        TaxSvc.CancelTaxRequest CancelTaxRequest = new TaxSvc.CancelTaxRequest();
        TaxSvc.CancelTaxResult cancel = client.CancelTax(CancelTaxRequest);

        TaxSvc.CommitTaxRequest CommitTaxRequest = new TaxSvc.CommitTaxRequest();
        TaxSvc.CommitTaxResult commitx = client.CommitTax(CommitTaxRequest);

        TaxSvc.AdjustTaxRequest AdjustTaxRequest = new TaxSvc.AdjustTaxRequest();
        TaxSvc.AdjustTaxResult adjust = client.AdjustTax(AdjustTaxRequest);

        TaxSvc.GetTaxHistoryRequest HistoryRequest = new TaxSvc.GetTaxHistoryRequest();
        TaxSvc.GetTaxHistoryResult hist = client.GetTaxHistory(HistoryRequest);
        
        TaxSvc.ApplyPaymentRequest appyPmtReq = new TaxSvc.ApplyPaymentRequest();
        TaxSvc.ApplyPaymentResult apply = client.ApplyPayment(appyPmtReq);

        TaxSvc.ReconcileTaxHistoryRequest ReconcileRequest = new TaxSvc.ReconcileTaxHistoryRequest();
        TaxSvc.ReconcileTaxHistoryResult recon = client.ReconcileTaxHistory(ReconcileRequest);
    }
    
    static testmethod void testTaxRules() {
        TaxRuleSetting__c tr = new TaxRuleSetting__c(
            Name='Default', StateDefault__c='XX'
        );
        insert(tr);
        TaxRuleOpCodeSetting__c op = new TaxRuleOpCodeSetting__c(
            TaxRuleSetting__c = tr.Id, Name='Default'
        );
        insert(op);
        AvaTax_MBW at = new AvaTax_MBW();
        at.getTaxRules(null);
        at.getTaxRules(null,'XX');
    }
    
    static testmethod void testSummary() {
        AvaTax_MBW at = new AvaTax_MBW();
        at.gettaxRslt = new TaxSvc.GetTaxResult();
        at.gettaxRslt.TaxLines = new TaxSvc.ArrayOfTaxLine();
        at.gettaxRslt.TaxLines.TaxLine = new List<TaxSvc.TaxLine>();
        TaxSvc.TaxLine line = new TaxSvc.TaxLine();
        TaxSvc.TaxDetail detail = new TaxSvc.TaxDetail();
        line.TaxDetails = new TaxSvc.ArrayOfTaxDetail();
        line.TaxDetails.TaxDetail = new List<TaxSvc.TaxDetail>();
        line.TaxDetails.TaxDetail.add(new TaxSvc.TaxDetail());
        at.gettaxRslt.TaxLines.TaxLine.add(line);
        at.summarizeTaxResult();
    }

	// BLL5a
	static testmethod void testAdjustTax() {
		// Note: no actual document exists during this test, but the test mock returns success anyway
		AvaTax_MBW tax = new AvaTax_MBW();
		tax.gettaxReq = tax.getAvataxRequest(
			'WMK',  
			'DocumentName',
			'Customer Name',
			Date.today(),
			'CustomerId'
		);
		tax.gettaxReq.Lines = new TaxSvc.ArrayOfLine();
		tax.gettaxReq.Lines.Line = new List<TaxSvc.Line>();
		TaxSvc.Line line = new TaxSvc.Line();
		line.No = '1';
		line.ItemCode = 'Test tax item';
		line.Description = 'Test tax line';
		line.Amount = 15.50;
		line.TaxCode = 'P0000000'; 
		tax.gettaxReq.Lines.Line.add(line);
        Test.setMock(WebServiceMock.class, new AvaTaxRequestMock());
		tax.adjustTax(8,'Testing');	
	}
	// BLL5a end

	// bll9a
	static testmethod void testDME() {
		setupData();	// BLL9a

        TestHelper_MW th = new TestHelper_MW();
        Account buyer = th.getPersonAccount('1');
        Account tpp = th.getThirdPartyAccount('1');
        dealer__Dealer_Location__c loc = th.getDealerLocation('1');
        
        TaxRuleSetting__c taxrule = [select Id, Name from TaxRuleSetting__c where Name='Testing' limit 1];
        
        // BLL4a Assign tax rules to location
        loc.TaxRuleSetting__c = taxrule.Id;
        update(loc);
        // BLL4a end
        
        Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();

        // Don't need a saved deal for this to work
        dealer__Deal__c deal = new dealer__Deal__c(
            Name='TestDeal', 
	        //BLL7d RecordTypeId=RcdTypes.get('Equipment Only Sale').getRecordTypeId(),	// BLL4a
	        RecordTypeId=RcdTypes.get('Retail').getRecordTypeId(),	// BLL7a
	        dealer__Deal_Type__c = 'DME/Other',	// BLL7a
            dealer__Deal_ID__c='TestDeal123',
            dealer__Store_Location__c=loc.Id, 
            dealer__Buyer__c=buyer.Id, 
            dealer__Buyer_Address__c = '1600 Pennsylvania Ave', 
            dealer__Buyer_City__c='Washington', 
            dealer__Buyer_State__c='DC', 
            dealer__Buyer_Postal_Code__c='20500',
            dealer__Vehicle__c=null, 
			dealer__Business_Address__c = '1601 Pennsylvania Ave',
			dealer__Business_City__c = 'Washington',
			dealer__Business_State__c = 'DC',
			dealer__Business_Postal_Code__c = '20500',
			dealer__Delivery_Street__c = '1601 Pennsylvania Ave',
			dealer__Delivery_City__c = 'Washington',
			dealer__Delivery_State__c = 'DC',
			DeliveryPostalCode__c = '20500',	
            Proposed_Delivery_Date__c=Date.today(),
            Chassis_Price__c=10000, 
            Conversion_Taxable__c=false, 
            Conversion_Price__c=1000,
            Conversion_Discount__c=100,
            GVW_GVWR__c=5, 
            Tire_Fee__c=10, 
            Smog_Fee__c=20, 
            Electronic_Filing_Fee__c=30, 
            dealer__Doc_Fee__c=40, 
            dealer__License_Fee__c=50,
            Registration_Title_Fee__c=60, 
            Smog_Cert__c=70, 
            dealer__Sales_Tax__c=80,
            dealer__Rebate__c=100, 
            Rebate_Description__c='Rebate 1', 
            Rebate_2__c=200, 
            Rebate_2_Description__c='Rebate 2', 
            Rebate_3__c=300, 
            Rebate_3_Description__c='Rebate 3',
            MBW_Rewards__c=50,
            AutoGrant__c=5,
            dtmob__Auto_Grant_Payor__c = tpp.Id,
            Total_Price__c=1500.00 
        );
        // TODO: Create deal, add aftermarket, trade, esc

        Test.startTest();
        AvaTax_MBW tax = AvaTax_MBW.getInstanceDeal(deal);

	}
	// BLL9a end

    
    @isTest 
    static void serviceEstimateTaxes() {
    	setupData();
		//dealer.TestClassUtil tc = new dealer.TestClassUtil();
	    //tc.insertDMSSettings();
	    
        TestHelper_MW th = new TestHelper_MW();
        Account buyer = th.getPersonAccount('1');
        buyer.BillingStreet='1600 Pennsylvania Ave';
        buyer.BillingCity='Washington';
        buyer.BillingState='PA'; 
        buyer.BillingPostalCode='16000';
        update(buyer);
        dealer__Dealer_Location__c loc = th.getDealerLocation('1');
        loc.dealer__Company_Number__c = 'DET';	// one of the original, permitted locations to use S.E.s
        Contact c = [select Id from Contact where AccountId=:buyer.Id limit 1];

        dealer__Service_Vehicle__c  dsv = new dealer__Service_Vehicle__c (
            dealer__VIN__c ='Testxx',
            Name='Test',
            dealer__Body_Style__c = 'Test',
            dealer__Company_Number__c=loc.dealer__Company_Number__c,
            dealer__Veh_Owner_Contact__c = c.Id,
            dealer__Carline__c ='Test',
            dealer__Make__c  ='Test',
            dealer__Year__c  ='2013',
            dealer__Last_Service__c =system.today(),
            dealer__Last_Activity__c =system.today()
        );
        insert dsv;

        dealer__Service_Estimate__c est = new dealer__Service_Estimate__c(
            dealer__Store_Location__c=loc.Id,
            dealer__Company_Number__c=loc.dealer__Company_Number__c,
            dealer__Customer__c=buyer.Id,
            dealer__Status__c = 'Open',
            dealer__Service_Vehicle__c = dsv.Id,
            MobilityTaxable__c = true,
            HaveRequiredTaxCert__c = true
        );
        insert(est);

		// BLL10a
		// Find valid picklist values that aren't 'C', 'I', 'W'; call the first one customer labor type & the second warranty
        DescribeFieldResult lbrtype = dealer__Service_Estimate_Line__c.dealer__Labor_Type__c.getDescribe();
		List<Schema.PicklistEntry> ltplvs = lbrtype.getPicklistValues();
		String customer_labor_type;
		String warranty_labor_type;
		for(Integer i=0; i<ltplvs.size(); i++) {
			if (ltplvs[i].getValue().length()>1) {
				if (String.isBlank(customer_labor_type)) customer_labor_type = ltplvs[i].getValue();
				else if (String.isBlank(warranty_labor_type)) warranty_labor_type = ltplvs[i].getValue();
			}
		}
		// BLL10a end

        ServicePaymentType__c spt = new ServicePaymentType__c(
            Default_Labor_Rate__c=12,
            Payment_Type__c='C',
            Description__c='Test',
            Shop_Supplies_Rate__c=12,
            Hazmat_Fee__c=12,
            Freight_Rate__c=12
        );
        insert spt; 

        dealer__StandardOpCode__c dso= new dealer__StandardOpCode__c(
            Name ='Test'
        );
        insert dso;

        List<dealer__Service_Estimate_Line__c> estl = new List<dealer__Service_Estimate_Line__c>();
        estl.add(new dealer__Service_Estimate_Line__c(
            dealer__Service_Estimate__c = est.Id,
            dealer__Labor_Type__c = customer_labor_type, 
            dealer__Labor__c = 12,
            dealer__Parts__c = 12,
            dealer__Sublet_Charges__c = 12
        ));
        insert(estl);
        
        List<dealer__Service_Estimate_Subline__c> subl = new List<dealer__Service_Estimate_Subline__c>();
		subl.add(new dealer__Service_Estimate_Subline__c(
            dealer__Service_Estimate_Line__c = estl[0].Id, 
            dealer__Line_Type__c = 'Miscellaneous',
            dealer__Misc_Charge_Code__c = 'Shop supplies',
            dealer__Misc_Charge_Amount__c = 5.50 
        ));
        insert(subl);
        
        Test.startTest();
        AvaTax_MBW tax = AvaTax_MBW.getInstanceServiceEstimateId(est.Id);

        Test.setMock(WebServiceMock.class, new AvaTaxRequestMock());
        tax.calculateTax();

		AvaTax_MBW.TaxResults rslt = tax.summarizeTaxResults();
		String rsltStr = JSON.serialize(rslt);
		//System.debug(rsltStr);
		tax.saveEstimateTaxDetail();
       
        Test.stopTest();
    }
    
    
}