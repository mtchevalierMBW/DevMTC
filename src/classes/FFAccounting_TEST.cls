/**
* FFAccounting_TEST
* Tests: portions of FFAccounting
* Date: 2019-04-15
* Programmer: Bryan Leaman
* Project: W-000575
* Update proposal F&I overall status info when credit application statuses are updated.
*
* Coverage:
*
* Modifications: 
*	2019-09-23	B. Leaman	W-000756 BLL1 - coverage for partsPhysicalVariance(Id physicalInvId, Decimal adjustVal)
*
*/
@isTest
private class FFAccounting_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupData() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		dealer.TestClassUtil tc = new dealer.TestClassUtil();
		tc.insertDMSSettings();
		// Force same company as current user
		update(new dealer__Dealer_Location__c(
			Id=FFAdata.DealerLocation.Id, 
			Financial_Force_Dimension_1__c=FFAdata.Dimension1.Id,
			Company__c=FFAdata.CurrentCompany.Id
		));
		System.runAs(FFAData.TestUser) {
			TestHelper_MW th = new TestHelper_MW();
			th.createGeneralLedgerAccounts(new List<String>{'1100','1200','1220','1225','4960'});
			for(c2g__codaGeneralLedgerAccount__c g : [select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c]) {
				FFAdata.GLAMap.put(g.c2g__ReportingCode__c, g);
			}
        	c2g__codaBankAccount__c ba = new c2g__codaBankAccount__c(
				Name='Test bank',
				c2g__OwnerCompany__c = FFAdata.CurrentCompany.Id,
				c2g__AccountName__c = 'Test account',
				c2g__AccountNumber__c = '123',
				c2g__BankName__c = 'Test bank name',
				c2g__ReportingCode__c = '123',
				c2g__GeneralLedgerAccount__c = FFAdata.GLAMap.get('1100').Id
       		);
			insert(ba);
			insert(new PaymentMethodsByLocation__c (
				Name = 'Cash', 
				Method__c = 'Cash', 
				Deposit_Account__c = ba.c2g__ReportingCode__c,
				Location__c = FFAdata.DealerLocation.dealer__Company_Number__c
			));
		}
	}

	static testmethod void testPostCashEntry() {
        FFAdata.refresh();
        System.runAs(FFAdata.TestUser) {
			System.debug(Utility.MemberOfGroupHierarchy(FFAdata.TestUser.Id));
	        c2g__codaBankAccount__c ba = [select Id from c2g__codaBankAccount__c limit 1];

			// Create cash entry
			c2g__codaCashEntry__c ce = new c2g__codaCashEntry__c(
				c2g__OwnerCompany__c = FFAdata.CurrentCompany.Id,
            	c2g__BankAccount__c = ba.Id,
            	c2g__Type__c='Receipt'
			);
			insert(ce);
			List<c2g__codaCashEntryLineItem__c> celines = new List<c2g__codaCashEntryLineItem__c>();
			celines.add(new c2g__codaCashEntryLineItem__c(
				c2g__CashEntry__c = ce.Id,
				c2g__Account__c = FFAdata.Account.Id,
				c2g__CashEntryValue__c = 100.00,
				Control__c = 'TestCashEntryLine 1',
				c2g__AccountDimension1__c = FFAdata.Dimension1.Id,
				ffcash__DeriveAccountDimensions__c = false
			));
			insert(celines);
			Test.startTest();
			FFAccounting.postCashEntry(ce.Id);
			Test.stopTest();
		}
		
	}

	// BLL1
	// BLL1
	@IsTest
	static void physicalInventoryVariance(){
		
        FFAdata.refresh();
		dealer__PartPhysicalInventory__c physInv = new dealer__PartPhysicalInventory__c(
			Name='Test physcial',
			dealer__Location__c=FFAdata.DealerLocation.Id
		);
		insert(physInv);
        System.runAs(FFAdata.TestUser) {
			Test.startTest();
			FFAccounting.partsPhysicalVariance(physInv.Id, 10.00);	
			Test.stopTest();
		}
		
	}

	//// testAccountingInterface
	//static testmethod void testAccountingInterface(){
	//	TestHelper_MW th = new TestHelper_MW();
    //    FFAdata.refresh();
    //    System.runAs(FFAdata.TestUser) {
	//		Account pa = th.getPersonAccount('1');
    //   		dealer__Rental_Agreements__c ra = new dealer__Rental_Agreements__c(
    //    		Account__c = pa.Id,
    //    		CustomerContact__c = pa.personContactId,
	//	        Location__c = FFAdata.DealerLocation.Id,
    //    		dealer__Agreement_Status__c = 'Open',
	//			dealer__Return_Date__c = Date.today(),
    //    		dealer__Date_DUE_In__c = Date.today(),
	//			dealer__Date_Out__c = date.today().addDays(-1),
	//			dealer__Drivers_Birthdate__c = Date.newInstance(1915, 1, 1),
	//			dealer__Drivers_Lic__c = 'n/a',
	//			dealer__Drivers_Lic_Exp__c = Date.today().addYears(2),
	//			dealer__Fuel_Charge_per_Gallon__c = 0,
	//			dealer__Insurer__c = 'See RentCentric',
	//			dealer__Return_Mileage__c = 101,
	//			dealer__Mileage_Out__c = 11,
	//			dealer__Policy_No__c = 'See RentCentric',
	//			dealer__Policy_Expiration_Date__c = Date.today().addYears(1),
	//			dealer__Time_OUT__c = '06:00:00',
	//			dealer__Time_DUE_IN__c = '20:00:00',
	//			Rental_fee__c = 200.00,
	//			dealer__Excess_Miles_Fee__c = 1.00,
	//			Excess_Miles_Charge__c = 0.00,
	//			Pickup_Delivery_Fee__c = 0.00,
	//			dealer__Refueling_Fee__c = 0.00,
	//			dealer__Adjustment_Charges__c = 0.00,
	//			dealer__Discount__c = 0.00,
	//			dealer__Deposit_Amount__c = 0.00,
	//			Sales_Tax__c = 5.00,
	//			CountySalesTax__c = 4.00,
	//			CitySalesTax__c = 3.00,
	//			ThirdTierRentalTax__c = 2.00
	//		);
    //   		insert(ra);
	//
	//		Test.startTest();	
	//		System.debug(FFAdata.DealerLocation);
	//		dealer__Cashering__c cash = new dealer__Cashering__c(
	//			dealer__Amount__c = 215,
	//			dealer__Company_Number__c = FFAdata.DealerLocation.dealer__Company_Number__c,
	//			dealer__Location__c = FFAdata.DealerLocation.Id,
	//			dealer__Customer__c = pa.Id,
	//			dealer__Payment_Method__c = 'Cash',
	//			dealer__Rental_Agreement__c = ra.Id
	//		);
	//		insert(cash);
	//		AccountingInterface.createReceiptFromCashierRecord(cash.id);
	//		Test.stopTest();
	//	}
	//	
	//}

}