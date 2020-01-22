/**
 * PartsProcess_TEST
 * Tests: PartsProcess_TEST
 * Date: Mar 5, 2018
 * Programmer: Bryan Leaman
 *
 *	2019-07-18	B. Leaman	W-000554	BLL1 test part master uppercase functions
 *	2019-07-26	B. Leaman	W-000703 BLL2 - replicate static price changes down to parts inventory records
 */
@isTest
private class PartsProcess_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		//FFAdata.refresh(); 
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
	}

	// PartPricingTest
	//---------------------------------------
	static testMethod void PartPricingTest() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
			System.assertEquals(4.5, PartsProcess.RetailPriceMarkUpFromCost(0.90), 'Markup from $0.90 failed');
			System.assertEquals(5, PartsProcess.RetailPriceMarkUpFromCost(1.00), 'Markup from $1 failed');
			System.assertEquals(11.25, PartsProcess.RetailPriceMarkUpFromCost(2.50), 'Markup from $2.50 failed');
			System.assertEquals(20, PartsProcess.RetailPriceMarkUpFromCost(5.00), 'Markup from $5 failed');
			System.assertEquals(93.75, PartsProcess.RetailPriceMarkUpFromCost(25.00), 'Markup from $25 failed');
			System.assertEquals(115.5, PartsProcess.RetailPriceMarkUpFromCost(33.00), 'Markup from $33 failed');
			System.assertEquals(156.8, PartsProcess.RetailPriceMarkUpFromCost(49.00), 'Markup from $49 failed');
			System.assertEquals(182, PartsProcess.RetailPriceMarkUpFromCost(65.00), 'Markup from $65 failed');
			System.assertEquals(186.3, PartsProcess.RetailPriceMarkUpFromCost(81.00), 'Markup from $81 failed');
			System.assertEquals(4000, PartsProcess.RetailPriceMarkUpFromCost(2000.00), 'Markup from $2000 failed');
			System.assertEquals(5601.4, PartsProcess.RetailPriceMarkUpFromCost(4001.00), 'Markup from $4001 failed');
		}
	}


	// PrependTest
	//---------------------------------------
	static testMethod void PrependTest() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
			
			String test1 = PartsProcess.prepend('TestString',null,128);
			System.debug('>'+test1+'<');
			System.assertEquals('>TestString<', '>'+test1+'<', 'Prepend to null field failed');

			String test2 = PartsProcess.prepend('TestString','',128);
			System.assertEquals('>TestString<','>'+test2+'<','Prepend to empty field failed');

			String test3 = PartsProcess.prepend('TestString',' ',128);
			System.assertEquals('>TestString<','>'+test3+'<','Prepend to blank field failed');

			String test4 = PartsProcess.prepend(
			'Fifty_character_part_name_number_One_1_twelve_more',
			'Fifty_character_part_name_number_Two_2_twelve_more',128);
			System.assertEquals('Fifty_character_part_name_number_One_1_twelve_more, Fifty_character_part_name_number_Two_2_twelve_more',
				test4, 'Prepend 50 characters to existing 50 characters failed');			

			String test5 = PartsProcess.prepend(
			'Fifty_character_part_name_number_One_1_twelve_more',
			'Fifty_character_part_name_number_Two_2_twelve_more, Forty_character_part_name_number_Three_3',128);
			System.assertEquals('Fifty_character_part_name_number_One_1_twelve_more, Fifty_character_part_name_number_Two_2_twelve_more',
				test5, 'Prepend 50 characters to existing 92 characters failed to truncate properly');			
			
		}
	}


	// SupersessionTest
	//---------------------------------------
	static testMethod void SupersessionTest() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();

        	// create part master
        	dealer__Parts_Master__c pm = new dealer__Parts_Master__c(
        		Name = 'TestPartNbr',
        		dealer__Manufacturer__c = 'BRA',
        		External_ID__c = 'TestPartNbr',
        		dealer__Cost__c = 1,
        		dealer__Retail_Price__c = 5
        	);
        	insert(pm);
        	
        	// create part inventory
        	dealer__Parts_Inventory__c pi = new dealer__Parts_Inventory__c(
        		dealer__Description__c = 'Testing',
        		dealer__Location__c = FFAdata.DealerLocation.Id,
        		dealer__Parts_Master__c = pm.Id,
        		dealer__Cost__c = 5,
        		dealer__MFG__c = 'BRA'
        	);
        	insert(pi);
        	
        	// update part master to run supersession
        	pm = [select Id, Name, dealer__Part_No__c, CreateSupersession__c, Supersedes__c from dealer__Parts_Master__c where Id=:pm.Id];
        	pm.CreateSupersession__c = 'NewPartNbr';
        	update(pm);	
        	
        	dealer__Parts_Master__c pm2 = [select Id, Name, dealer__Part_No__c, Supersedes__c from dealer__Parts_Master__c where Id=:pm.Id];
        	dealer__Parts_Inventory__c pi2 = [select Id, Name, dealer__Part_No__c from dealer__Parts_Inventory__c where Id=:pi.Id];

		}
	}

	// test forcing part numbers to uppercase
	static testmethod void upperCasePartNbrs() {
		List<dealer__Parts_Master__c> pmlist = new List<dealer__Parts_Master__c>();
		pmlist.add(new dealer__Parts_Master__c(
			Name='lc', dealer__Raw_Part_Number__c='BRA:lc', dealer__Part_No__c='BRA:lc'
		));
		pmlist.add(new dealer__Parts_Master__c(
			Name='UC', dealer__Raw_Part_Number__c='BRA:UC', dealer__Part_No__c='BRA:UC'
		));
		PartsProcess.ensureUppercase(pmlist);
		for(dealer__Parts_Master__c pm : pmlist) {
			System.debug(pm);
			System.assert(pm.Name.equals(pm.Name.replaceAll('[a-z]','')), 'Part name "' + pm.Name + '" is not all uppercase');
			System.assert(pm.dealer__Raw_Part_Number__c.equals(pm.dealer__Raw_Part_Number__c.replaceAll('[a-z]','')), 'Raw part number "' + pm.dealer__Raw_Part_Number__c + '" is not all uppercase');
			System.assert(pm.dealer__Part_No__c.equals(pm.dealer__Part_No__c.replaceAll('[a-z]','')), 'Part number "' + pm.dealer__Part_No__c + '" is not all uppercase');
		}

		List<dealer__Parts_Inventory__c> plist = new List<dealer__Parts_Inventory__c>();
		plist.add(new dealer__Parts_Inventory__c(Name='Test:1', dealer__Part_No__c='Test:1'));
		plist.add(new dealer__Parts_Inventory__c(Name='TEST:2', dealer__Part_No__c='TEST:2'));
		PartsProcess.ensureUppercasePart(plist);
		for(dealer__Parts_Inventory__c p : plist) {
			System.debug(p);
			System.assert(p.Name.equals(p.Name.replaceAll('[a-z]','')), 'Part name "' + p.Name + '" is not all uppercase');
			System.assert(p.dealer__Part_No__c.equals(p.dealer__Part_No__c.replaceAll('[a-z]','')), 'Part number "' + p.dealer__Part_No__c + '" is not all uppercase');
		}

	}

	// BLL2
	// test forcing part numbers to uppercase
	static testmethod void staticPricingTest() {
		
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
			dealer__Dealer_Location__c loc1 = FFAdata.DealerLocation;
			dealer__Dealer_Location__c loc2 = th.getDealerLocation('2');

			List<dealer__Parts_Master__c> pmlist = new List<dealer__Parts_Master__c>();
			pmlist.add(new dealer__Parts_Master__c(
				Name='STATIC1', dealer__Raw_Part_Number__c='STATIC1', dealer__Part_No__c='STATIC1', 
				Static_price__c=1.23, dealer__Retail_Price__c=1.23, dealer__Cost__c = 1,
				dealer__Manufacturer__c='TST'
			));
			pmlist.add(new dealer__Parts_Master__c(
				Name='NOSTATIC2', dealer__Raw_Part_Number__c='NOSTATIC2', dealer__Part_No__c='NOSTATIC2', 
				Static_price__c=null, dealer__Retail_Price__c=3.10, dealer__Cost__c = 1,
				dealer__Manufacturer__c='TST'
			));
			insert(pmlist);

			List<dealer__Parts_Inventory__c> pilist = new List<dealer__Parts_Inventory__c>();
			pilist.add(new dealer__Parts_Inventory__c(
				dealer__Parts_Master__c=pmlist[0].Id,
				Name='STATIC1',
				dealer__Part_No__c='STATIC1',
				dealer__Location__c=loc1.Id,
				dealer__MFG__c='TST',
				dealer__Cost__c=1, dealer__List__c=1.1
			));
			pilist.add(new dealer__Parts_Inventory__c(
				dealer__Parts_Master__c=pmlist[0].Id,
				Name='STATIC1',
				dealer__Part_No__c='STATIC1',
				dealer__Static_Price__c=1.50,
				dealer__Location__c=loc2.Id,
				dealer__MFG__c='TST',
				dealer__Cost__c=1, dealer__List__c=1.1
			));
			pilist.add(new dealer__Parts_Inventory__c(
				dealer__Parts_Master__c=pmlist[1].Id,
				Name='NOSTATIC2',
				dealer__Part_No__c='NOSTATIC2',
				dealer__Location__c=loc1.Id,
				dealer__MFG__c='TST',
				dealer__Cost__c=1, dealer__List__c=1.1
			));
			pilist.add(new dealer__Parts_Inventory__c(
				dealer__Parts_Master__c=pmlist[1].Id,
				Name='NOSTATIC2',
				dealer__Part_No__c='NOSTATIC2',
				dealer__Static_Price__c=1.50,
				dealer__Location__c=loc2.Id,
				dealer__MFG__c='TST',
				dealer__Cost__c=1, dealer__List__c=1.1
			));
			insert(pilist);

			// Check results
			System.debug([select Id, Name, Static_price__c from dealer__Parts_Master__c]);
			Map<Id,dealer__Parts_Inventory__c> pimap = new Map<Id, dealer__Parts_Inventory__c>([
				select Id, dealer__Parts_Master__c, dealer__Static_Price__c, dealer__Cost__c
				from dealer__Parts_Inventory__c
			]);
			System.debug(pimap);
			for(dealer__Parts_Inventory__c pi : pimap.values()) System.debug(pi);

			System.assertEquals(1.23, pimap.get(pilist[0].Id).dealer__Static_Price__c, 'New part did not get part master static price');
			System.assertEquals(1.50, pimap.get(pilist[1].Id).dealer__Static_Price__c, 'New part did not keep its static price override');

			System.assertEquals(null, pimap.get(pilist[2].Id).dealer__Static_Price__c, 'New part somehow picked up a static price when master has none');
			System.assertEquals(1.50, pimap.get(pilist[3].Id).dealer__Static_Price__c, 'New part did not keep its static price override when master has none');

			// Change static price on master!
			System.debug(pmlist[0]);
			update(new dealer__Parts_Master__c(Id=pmlist[0].Id, Static_price__c=1.65, dealer__Retail_Price__c=pmlist[0].dealer__Retail_Price__c));

			// Check results
			System.debug([select Id, Name, Static_price__c from dealer__Parts_Master__c]);
			pimap = new Map<Id, dealer__Parts_Inventory__c>([
				select Id, dealer__Parts_Master__c, dealer__Static_Price__c
				from dealer__Parts_Inventory__c
			]);
			System.debug(pimap);

			System.assertEquals(1.65, pimap.get(pilist[0].Id).dealer__Static_Price__c, 'Inventory part static price was not updated');
			System.assertEquals(1.65, pimap.get(pilist[1].Id).dealer__Static_Price__c, 'Inventory part static price was not updated');

		}

	}
	// BLL2 end
}