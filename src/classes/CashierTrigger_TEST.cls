/**
* CashierTrigger_TEST
* Tests: CashierTrigger
* Date: 2019-04-19
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
private class CashierTrigger_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupData() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		dealer.TestClassUtil tc = new dealer.TestClassUtil();
		tc.insertDMSSettings();
		update(new dealer__Dealer_Location__c(
			Id=FFAdata.DealerLocation.Id, 
			Financial_Force_Dimension_1__c=FFAdata.Dimension1.Id,
			Company__c=FFAdata.CurrentCompany.Id
		));
		update(new User(Id=FFAdata.TestUser.Id, Division=FFAdata.DealerLocation.dealer__Company_Number__c));

		System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();
			List<c2g__codaGeneralLedgerAccount__c> glalist = new List<c2g__codaGeneralLedgerAccount__c>(); 
			Integer i = 0;
			for(c2g__codaGeneralLedgerAccount__c gl : FFAdata.GLAMap.values()) {
				glalist.add(gl);
			}
       		Account pa = th.getPersonAccount('1');
       		pa.c2g__CODAAccountsPayableControl__c = glalist[0].Id;
       		pa.c2g__CODAAccountsReceivableControl__c = glalist[0].Id;
       		pa.c2g__CODADimension1__c = FFAdata.Dimension1.Id;
       		update(pa);
	
			update(new dealer__Dealer_Location__c(Id=FFAdata.DealerLocation.Id, Financial_Force_Dimension_1__c=FFAdata.Dimension1.Id));

			// Create cash entry
        	c2g__codaBankAccount__c ba = new c2g__codaBankAccount__c(
			Name='Test bank',
			c2g__AccountName__c = 'Test account',
				c2g__AccountNumber__c = '123',
				c2g__BankName__c = 'Test bank name',
				c2g__ReportingCode__c = '123',
				c2g__GeneralLedgerAccount__c = glalist[0].Id
        	);
			insert(ba);
			c2g__codaCashEntry__c ce = new c2g__codaCashEntry__c(
        	   	c2g__BankAccount__c = ba.Id,
        	   	c2g__Type__c='Receipt',
				c2g__Date__c=Date.today(),
				Automated_Entry__c = true
			);
			insert(ce);
			List<c2g__codaCashEntryLineItem__c> celines = new List<c2g__codaCashEntryLineItem__c>();
			celines.add(new c2g__codaCashEntryLineItem__c(
				c2g__CashEntry__c = ce.Id,
				c2g__Account__c = pa.Id,
				c2g__CashEntryValue__c = 10.00,
				Control__c = 'TestCashEntryLine 1',
				c2g__AccountDimension1__c = FFAdata.Dimension1.Id,
				ffcash__DeriveAccountDimensions__c = false
			));
			insert(celines);

			List<MW_TriggerControls__c> tclist = new List<MW_TriggerControls__c>();
			tclist.add(new MW_TriggerControls__c(Name='CashierUpdatePrevention', Enabled__c=false));
			tclist.add(new MW_TriggerControls__c(Name='CashierDeletePrevention', Enabled__c=false));
			tclist.add(new MW_TriggerControls__c(Name='CashierFFLink', Enabled__c=false));
			tclist.add(new MW_TriggerControls__c(Name='CashierFFLock', Enabled__c=true));
			insert(tclist);
			
		}

	}

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();
			Account a = [select Id, Name, isPersonAccount, PersonContactId from Account limit 1];
			c2g__codaCashEntryLineItem__c cel = [select Id, Name from c2g__codaCashEntryLineItem__c limit 1];

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
			
			Test.startTest();

			// update with no significant changes
			boolean updated = false;
			cashierEntry.Cash_Entry_Line_Item__c = cel.Id;
			try {
				update(cashierEntry);
				updated = true;
			} catch(Exception e) {
				System.debug(e);
			}
			System.assert(updated==true, 'Insignificant update was prevented');

			// update with amount change, but not prevented unless FF entry exists (disable general update prevention)
			updated = false;
			MW_TriggerControls__c cashierupdate = MW_TriggerControls__c.getInstance('CashierUpdatePrevention');
			cashierupdate.Enabled__c=true;
			update(cashierupdate);
			cashierEntry.dealer__Amount__c += 1;
			try {
				update(cashierEntry);
				updated = true;
			} catch(Exception e) {
				System.debug(e);
			}
			System.assert(updated==false, 'Cashier entry update was permitted');

			boolean deleted = false;
			try {
				delete(cashierEntry);
				deleted = true;
			} catch(Exception e) {
				System.debug(e);
			}
			System.assert(deleted==true, 'Cashier entry deletion was denied though not a posted cash entry');

			Test.stopTest();

		}
	}


}