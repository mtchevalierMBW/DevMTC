/**
 * VehicleTransfer_TEST
 * Tests: VehicleTransfer
 * Date: Dec 23, 2015
 * Programmer: Bryan Leaman
 *
 *	2018-08-21	B. Leaman	BLL1 - new op code on generated RO 
 */
@isTest
private class VehicleTransfer_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 
	@testSetup static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		FFAdata.CurrentCompany.DefaultPayableDimension1__c = FFAdata.dimension1.Id;
		update(FFAdata.CurrentCompany);

		// Need specific accounts
		List<c2g__codaGeneralLedgerAccount__c> glas = new List<c2g__codaGeneralLedgerAccount__c>();
		glas.add(new c2g__codaGeneralLedgerAccount__c(
			c2g__ReportingCode__c ='1244',
			c2g__Type__c='Balance Sheet',
			VehicleRequired__c=true, VehicleComponent__c='Chassis',
			Name='1244 Test'
		));
		glas.add(new c2g__codaGeneralLedgerAccount__c(
			c2g__ReportingCode__c ='1245',
			c2g__Type__c='Balance Sheet',
			VehicleRequired__c=true, VehicleComponent__c='Conversion',
			Name='1245 Test'
		));
		glas.add(new c2g__codaGeneralLedgerAccount__c(
			c2g__ReportingCode__c ='2903',
			c2g__Type__c='Balance Sheet',
			Name='2903 Test'
		));
		glas.add(new c2g__codaGeneralLedgerAccount__c(
			c2g__ReportingCode__c ='1240',
			c2g__Type__c='Balance Sheet',
			VehicleRequired__c=true, VehicleComponent__c='Conversion',
			Name='1240 Test'
		));
		glas.add(new c2g__codaGeneralLedgerAccount__c(
			c2g__ReportingCode__c ='1242',
			c2g__Type__c='Balance Sheet',
			VehicleRequired__c=true, VehicleComponent__c='Chassis',
			Name='1242 Test'
		));
		glas.add(new c2g__codaGeneralLedgerAccount__c(
			c2g__ReportingCode__c ='1265',
			c2g__Type__c='Balance Sheet',
			Name='1265 Test'
		));
		insert glas;
		
		dealer.TestClassUtil tc = new dealer.TestClassUtil();
		tc.insertDMSSettings();
		dealer__FixedOperationsSettings__c fixedOpsSettings = new dealer__FixedOperationsSettings__c(
			dealer__Repair_Order_Index__c=1
		);
		insert(fixedOpsSettings); 

		insert(new dealer__StandardOpCode__c(
			//Name='60CHECKIN',
			Name='30CONSUMERVEHICLETRANSFER',	// BLLxa
			dealer__Company_Number__c=FFAdata.DealerLocation.dealer__Company_Number__c
		));
		insert(new ServicePaymentType__c(
			Name='GRNV', 
			Description__c='Get Ready New Vehicle',
			Payment_Type__c='I'
		));
		insert(new ServicePaymentType__c(
			Name='GRUV', 
			Description__c='Get Ready Used Vehicle',
			Payment_Type__c='I'
		));
		
	}

	static testMethod void unitTest() {
		TestHelper_MW th = new TestHelper_MW();
		FFAdata.refresh();

		System.runAs(FFAdata.testUser) {
			
			// create 2 locations, a vehicle and a trade
			dealer__Dealer_Location__c loc1 = th.getDealerLocation('1');
			dealer__Dealer_Location__c loc2 = th.getDealerLocation('2');
			loc1.Company__c = FFAdata.CurrentCompany.Id;
			loc1.Financial_Force_Dimension_1__c = FFAdata.dimension1.Id;
			update(loc1);
			loc2.Company__c = FFAdata.CurrentCompany.Id;
			loc2.Financial_Force_Dimension_1__c = FFAdata.dimension1b.Id;
			update(loc2);
			
			dealer__Vehicle_Inventory__c veh = th.getVehicleInventory('1');
			
			Test.startTest();
			dealer__Dealer_Trade__c trade = new dealer__Dealer_Trade__c(
				dealer__Stock_No__c = veh.Id,
				dealer__Outbound_Location__c = loc1.Id,
				dealer__Store_Location__c = loc2.Id,
				dealer__Transfer_Status__c = 'Not submitted',
				Transport_Method__c = 'Drivers'
			);
			insert(trade);

			// Test run methods...
			VehicleTransfer tfr = new VehicleTransfer(new Set<Id>{trade.Id});
			List<dealer__Dealer_Trade__c> trades = tfr.getDealerTrades();
			Map<Id,dealer__Vehicle_Inventory__c> vehMap = tfr.getTradedVehiclesMap();
			Map<Id,dealer__Dealer_Location__c> locMap = tfr.getDealerLocationsMap();
			Map<String,c2g__codaGeneralLedgerAccount__c> glMap = tfr.getVehicleTradeGLAcctMap();
			Map<Id,c2g__codaAccountingCurrency__c> currMap = tfr.getCurrencyMap();
			
			dealer__Dealer_Trade__c trade2 = trade.clone(true, false, false, true);
			trade2.dealer__Transfer_Status__c = 'Requested';
			List<dealer__Dealer_Trade__c> newList = new List<dealer__Dealer_Trade__c>{trade2};
			Map<Id,dealer__Dealer_Trade__c> oldMap = new Map<Id, dealer__Dealer_Trade__c>();
			oldMap.put(trade.Id, trade);

			VehicleTransfer vt = new VehicleTransfer(newList);
			vt.DealerTradeStatusChange(oldMap);

			vt = new VehicleTransfer(newList);
			trade2.dealer__Transfer_Status__c = 'Approved';
			vt.DealerTradeStatusChange(oldMap);

			vt = new VehicleTransfer(newList);
			trade2.dealer__Transfer_Status__c = 'In Transit';
			vt.DealerTradeStatusChange(oldMap);

			vt = new VehicleTransfer(newList);
			trade2.dealer__Transfer_Status__c = 'Received';
			vt.DealerTradeStatusChange(oldMap);
			
			tfr.ProcessInboundTrades();
			tfr.ProcessOutboundTrades();
			tfr.ProcessInboundIntercompany();
			tfr.ProcessOutboundIntercompany();
			
			tfr.UpdateVehicleLocations();
			Test.stopTest();

		}		
	}

	static testMethod void createTradeJournals() {
		TestHelper_MW th = new TestHelper_MW();
		FFAdata.refresh();

		System.runAs(FFAdata.testUser) {
			
			// create 2 locations, a vehicle and a trade
			dealer__Dealer_Location__c loc1 = th.getDealerLocation('1');
			dealer__Dealer_Location__c loc2 = th.getDealerLocation('2');
			loc1.Company__c = FFAdata.CurrentCompany.Id;
			loc1.Financial_Force_Dimension_1__c = FFAdata.dimension1.Id;
			update(loc1);
			loc2.Company__c = FFAdata.CurrentCompany.Id;
			loc2.Financial_Force_Dimension_1__c = FFAdata.dimension1b.Id;
			update(loc2);
			
			dealer__Vehicle_Inventory__c veh = th.getVehicleInventory('1');
			
			dealer__Dealer_Trade__c trade = new dealer__Dealer_Trade__c(
				dealer__Stock_No__c = veh.Id,
				dealer__Outbound_Location__c = loc1.Id,
				dealer__Store_Location__c = loc2.Id,
				dealer__Transfer_Status__c = 'Requested',
				Transport_Method__c = 'Drivers'
			);
			insert(trade);

			// Test run methods...
			VehicleTransfer tfr = new VehicleTransfer(new Set<Id>{trade.Id});
			
			Test.startTest();
			tfr.createOutboundTradeJournals();
			tfr.createInboundTradeJournals();
			Test.stopTest();

		}		
	}


	static testMethod void createIntercompanyJournals() {
		TestHelper_MW th = new TestHelper_MW();
		FFAdata.refresh();

		System.runAs(FFAdata.testUser) {
			
			// create 2 locations, a vehicle and a trade
			dealer__Dealer_Location__c loc1 = th.getDealerLocation('1');
			dealer__Dealer_Location__c loc2 = th.getDealerLocation('2');
			loc1.Company__c = FFAdata.CurrentCompany.Id;
			loc1.Financial_Force_Dimension_1__c = FFAdata.dimension1.Id;
			update(loc1);
			loc2.Company__c = FFAdata.CurrentCompany.Id;
			loc2.Financial_Force_Dimension_1__c = FFAdata.dimension1b.Id;
			update(loc2);
			
			dealer__Vehicle_Inventory__c veh = th.getVehicleInventory('1');
			
			dealer__Dealer_Trade__c trade = new dealer__Dealer_Trade__c(
				dealer__Stock_No__c = veh.Id,
				dealer__Outbound_Location__c = loc1.Id,
				dealer__Store_Location__c = loc2.Id,
				dealer__Transfer_Status__c = 'Requested',
				Transport_Method__c = 'Drivers'
			);
			insert(trade);

			// Test run methods...
			VehicleTransfer tfr = new VehicleTransfer(new Set<Id>{trade.id});
			
			Test.startTest();
			tfr.createOutboundIntercompanyJournals();
			tfr.createInboundIntercompanyJournals();
			Test.stopTest();

		}		
	}

	
	static testMethod void dealerTransferExt() {
		TestHelper_MW th = new TestHelper_MW();
		FFAdata.refresh();

		System.runAs(FFAdata.testUser) {
			dealer__Vehicle_Inventory__c veh = th.getVehicleInventory('1');
			PageReference pgRef = Page.NewDealerTrade; 
			Test.setCurrentPage(pgRef); //Set the page for Test Method
			ApexPages.currentPage().getParameters().put('vehId', veh.Id);
			//ApexPages.currentPage().getParameters().put('retURL', '/');
			ApexPages.StandardController sc = new ApexPages.StandardController(new dealer__Dealer_Trade__c());
			DealerTrade_EXT ext = new DealerTrade_EXT(sc);
			ext.save();
			ext.cancel();
		}		
		
	}


	static testMethod void testGLMethods() {
		TestHelper_MW th = new TestHelper_MW();
		FFAdata.refresh();

		System.runAs(FFAdata.testUser) {
			
			dealer__Vehicle_Inventory__c veh = th.getVehicleInventory('1');
			VehicleTransfer tfr = new VehicleTransfer(new Set<Id>{});
			
			Test.startTest();
			Set<String> stocknbrs = new Set<String>{veh.dealer__Stock_Number__c};
			Map<String,List<c2g__codaTransactionLineItem__c>> tlinemap = tfr.getVehicleTransactions(stocknbrs);
			//tfr.summarizeByAccountAndDimension(tlinemap.get(veh.dealer__Stock_Number__c));
			Map<String,Decimal> summary = tfr.summarizeByVehicleComponentType(tlinemap.get(veh.dealer__Stock_Number__c));
			Test.stopTest();

		}		
	}

}