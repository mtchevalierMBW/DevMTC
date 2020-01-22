/**
 * RentalAgreementLex_TEST
 * Tests: RentalAgreementLex
 * Date: Sep 24, 2018
 * Programmer: Bryan Leaman
 *
 *	2019-01-24	W-000564 BLL1 - additional code coverage for vehicle & user's default location method.
 */
@isTest
private class RentalAgreementLex_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
        insert(new MW_TriggerControls__c(Name='RentalPostTax',Enabled__c=true));

        List<TaxRuleSetting__c> taxrules = new List<TaxRuleSetting__c>();	// BLL4a
        TaxRuleSetting__c taxrule = new TaxRuleSetting__c(
        	Name='Testing',
        	Chassis__c = 'P0000000',
        	Conversion__c = 'PH050301',
        	ConversionWithCert__c = 'PH050302',
        	ChassisLessTrade__c = 'P0000000',
        	LuxuryValue__c = 9000,
        	LuxuryVehicle__c = 'P0000000',
        	CombineDocFeeWithChassis__c = true,
        	AutoGrant_NetChassis__c = true,
        	GPC_NetChassis__c = true,
			Chassis_AtStore__c = true,
			ConversionGrant__c = 'NT',
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
			RentalAutomaticCalc__c = true,
			CombineConversionWithChassis__c=true
        );
        insert(taxrule);
        update(new dealer__Dealer_Location__c(Id=FFAdata.DealerLocation.Id, TaxRuleSetting__c=taxrule.Id));
	}

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
        	Account pa = th.getPersonAccount('1');
        
			// BLL1a
			dealer__Vehicle_Inventory__c rental = new dealer__Vehicle_Inventory__c(
				dealer__Stock_Number__c = 'RENTME',
				dealer__Year__c = '2020',
				dealer__Make__c = 'Toyota',
				dealer__Model__c = 'Sienna',
				dealer__VIN__c = '123RENTAL4567890Z',
				New_Used_Other__c = 'Rental'
			);
			insert(rental);
			// BLL1a end

			dealer__Rental_Agreements__c ra = new dealer__Rental_Agreements__c(
        		Account__c = pa.Id,
        		CustomerContact__c = pa.PersonContactId,
        		Location__c = FFAdata.DealerLocation.Id,
        		dealer__Agreement_Status__c = 'Open',
        		dealer__Return_Date__c = Date.today(), 
        		dealer__Date_DUE_In__c = Date.today(), 
        		dealer__Date_Out__c = Date.today().addDays(-1), 
        		dealer__Drivers_Birthdate__c = Date.newInstance(1915, 1, 1),
        		dealer__Drivers_Lic__c = 'n/a',
        		dealer__Drivers_Lic_Exp__c = Date.today().addYears(2),
        		dealer__Fuel_Charge_per_Gallon__c = 0,
        		dealer__Insurer__c = 'See RentCentric',
        		dealer__Mileage_Out__c = 1,
	        	dealer__Return_Mileage__c = 101,
				// BLL1a
				dealer__Rental_Vehicle__c = rental.id,
				Rental_Vehicle__c = rental.id,
				// BLL1a end
        		dealer__Policy_No__c = 'See RentCentric',
        		dealer__Policy_Expiration_Date__c = Date.today().addYears(1),
        		dealer__Time_OUT__c = '06:00:00',
        		dealer__Time_DUE_IN__c = '20:00:00',
        		Rental_fee__c = 200.00,
        		dealer__Excess_Miles_Fee__c = 1.00,
        		Excess_Miles_Charge__c = 0.00,
        		Pickup_Delivery_Fee__c = 0.00,
        		dealer__Refueling_Fee__c = 0.00,
        		dealer__Adjustment_Charges__c = 0.00,
        		dealer__Discount__c = 0.00,
        		dealer__Deposit_Amount__c = 0.00,
        		Sales_Tax__c = 5.00,
        		CountySalesTax__c = 4.00,
        		CitySalesTax__c = 3.00,
        		ThirdTierRentalTax__c = 2.00
			);
			insert(ra);

	        Test.setMock(WebServiceMock.class, new AvaTaxRequestMock());
	        Test.startTest();
			RentalAgreementLex.postRentalAgreement(ra.Id);
			Id cid = RentalAgreementLex.ContactForAccount(pa.Id);
			System.assert(cid!=null, 'Did not find person contact Id for a person account');
			Id aid = RentalAgreementLex.AccountForContact(cid);
			System.assertEquals(pa.Id,aid, 'Account-to-Contact reference error');
			// BLL1a
			Id locid = RentalAgreementLex.UsersDefaultLocation();
			System.assert(locid!=null, 'Did not retrieve a default location id');
			// BLL1a end
			Test.stopTest();
			
		}
	}

}