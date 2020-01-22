/**
* CashEntryAutoCreateDT_TEST
* Tests: CashEntryAutoCreateDT
* Date: 2019-04-23
* Programmer: Bryan Leaman
 * Project: #
 * Update proposal F&I overall status info when credit application statuses are updated.
 *
 * Coverage:
 *
 * Modifications: 
 *
*/
@isTest
private class CashEntryAutoCreateDT_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupData() {
		TestHelper_MW.createBaseFFAData(FFAdata);

		dealer.TestClassUtil tc = new dealer.TestClassUtil();
		tc.insertDMSSettings();

		System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();
			Account a = th.getPersonAccount('1');

			th.createGeneralLedgerAccounts(new List<String>{'1001t','1100'});
			FFAdata.refresh(); 

			// Force same company as current user
			update(new dealer__Dealer_Location__c(
				Id=FFAdata.DealerLocation.Id, 
				Financial_Force_Dimension_1__c=FFAdata.Dimension1.Id,
				Company__c=FFAdata.CurrentCompany.Id
			));

			// Set A/R control on account
			update(new Account(Id=a.Id, c2g__CODAAccountsReceivableControl__c=FFAdata.GLAMap.get('1001t').Id));

			// Create cash entry
        	c2g__codaBankAccount__c ba = new c2g__codaBankAccount__c(
			Name='Test bank',
			c2g__AccountName__c = 'Test account',
				c2g__AccountNumber__c = '1001T',
				c2g__BankName__c = 'Test bank name',
				c2g__ReportingCode__c = '1001t',
				c2g__OwnerCompany__c = FFAdata.CurrentCompany.Id,
				c2g__GeneralLedgerAccount__c = FFAdata.GLAMap.get('1001t').Id
        	);
			insert(ba);

			List<dealer__Payment_Methods__c> payms = new List<dealer__Payment_Methods__c>();
			payms.add(new dealer__Payment_Methods__c(
				Name='Cash', dealer__Method__c='Cash', dealer__Type__c='Cash', dealer__Description__c='Cash'
			));
			insert(payms);

			List<PaymentMethodsByLocation__c> pmbls = new List<PaymentMethodsByLocation__c>();
			pmbls.add(new PaymentMethodsByLocation__c(
				Name='Test', Method__c='Cash', 
				Location__c=FFAdata.DealerLocation.dealer__Company_Number__c,
				Deposit_Account__c='1001t', FF_Payment_Method__c='Cash'
			));
			insert(pmbls);

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
        		Account__c = a.Id,
        		CustomerContact__c = a.PersonContactId,
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
				dealer__Rental_Vehicle__c = rental.id,
				Rental_Vehicle__c = rental.id,
        		dealer__Policy_No__c = 'See RentCentric',
        		dealer__Policy_Expiration_Date__c = Date.today().addYears(1),
        		dealer__Time_OUT__c = '06:00:00',
        		dealer__Time_DUE_IN__c = '20:00:00',
        		Rental_fee__c = 200.00
			);
			insert(ra);

			dealer__Cashering__c cashierEntry = new dealer__Cashering__c(
				dealer__Customer__c = a.Id,
				dealer__Amount__c = 10,
				dealer__Company_Number__c = FFAdata.DealerLocation.dealer__Company_Number__c,
				dealer__Location__c = FFAdata.DealerLocation.Id,
				dealer__Payment_Method__c = 'Cash',
				Create_Cash_Entry__c = true,
				dealer__Rental_Agreement__c = ra.Id
			);
			insert(cashierEntry);
		}
	}

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
			Test.startTest();
			Database.executeBatch(new CashEntryAutoCreateDT(null, true, null, null, null, null), 1 );
			Test.stopTest();
			List<c2g__codaCashEntry__c> ce = [
				select Id, Name,
					(select Id, Name, Cashier__c from c2g__CashEntryLineItems__r)
				from c2g__codaCashEntry__c
			];
			List<dealer__Cashering__c> cashiers = [select Id, Name, Cash_Entry_Line_Item__c from dealer__Cashering__c where Cash_Entry_Line_Item__c!=null];
			System.assert(ce.size()==1, 'Did not get a cash entry');
			System.assert(ce[0].c2g__CashEntryLineItems__r.size()==1, 'Did not get a cash entry line');
			System.assert(ce[0].c2g__CashEntryLineItems__r[0].Cashier__c!=null, 'Cash entry line did not reference cashier record');
			System.assert(cashiers.size()>0, 'Cashier record does not reference the cash entry line item');
		}
	}

	// testSchedule
	//---------------------------------------
	static testMethod void unitSchedule() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
			Test.startTest();
			CashEntryAutoCreatedT.scheduleMe();
			Test.stopTest();
		}
	}

}