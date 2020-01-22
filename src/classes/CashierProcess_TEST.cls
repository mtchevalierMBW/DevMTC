/**
* CashierProcess_TEST
* Tests: CashierProcess
* Date: 2019-04-30
* Programmer: Bryan Leaman
 * Project: W-000575
 * Update proposal F&I overall status info when credit application statuses are updated.
 *
 * Coverage:
 *
 * Modifications: 
 *
*/
@isTest
private class CashierProcess_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupData() {
		TestHelper_MW.createBaseFFAData(FFAdata);

		dealer.TestClassUtil tc = new dealer.TestClassUtil();
		tc.insertDMSSettings();

		// allow deletion of cashier if they're not attached to a cash entry
		List<MW_TriggerControls__c> tcs = new List<MW_TriggerControls__c>();
		tcs.add(new MW_TriggerControls__c(Name='CashierDeletePrevention',Enabled__c=false));
		tcs.add(new MW_TriggerControls__c(Name='CashierUpdatePrevention',Enabled__c=false));
		tcs.add(new MW_TriggerControls__c(Name='CashierFFLink',Enabled__c=true));
		tcs.add(new MW_TriggerControls__c(Name='CashierFFLock',Enabled__c=true));
		insert(tcs);

		System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();
			Account a = th.getPersonAccount('1');
			Account va = th.getThirdPartyAccount('2');

			th.createGeneralLedgerAccounts(new List<String>{'1001t'});
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

			// setup a deal	
			dealer__Sales_Up__c  dsp = new dealer__Sales_Up__c(
	        	dealer__Lead_Date__c=System.Today(),
	        	dealer__Lead_Status__c='Pending',
	        	dealer__Lead_Type__c='List',
	        	dealer__Source__c ='Pride',
	        	Solution_Type__c ='Equipment',
	        	dealer__Customer_Account__c =a.id
	        );
	        insert(dsp);			Map<String, Schema.RecordTypeInfo> dealRcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();	// BLL11a
    	    dealer__Deal__c deal = new dealer__Deal__c(
    	    	Name = 'Test',
   	    		dealer__Deal_Type__c = 'Equipment',	
    	    	dealer__Auto_Insurance_Agent__c='Test',
    	    	dealer__Deal_ID__c ='Test',
    	    	dealer__Sales_Lead__c = dsp.id,
    	    	dealer__Status__c ='Pending',
    	    	dealer__Deal_Date__c =System.Today(),
    	    	Proposed_Delivery_Date__c =System.Today(),
    	    	dealer__Store_Location__c = FFAdata.DealerLocation.Id, 
				dtmob__Auto_Grant_Payor__c = va.Id,
				AutoGrant__c = 4,
				Third_Party_Pay_1__c = va.Id,
				dealer__Deferred_Down_1__c = 1,
				Third_Party_Pay_2__c = va.Id,
				dealer__Deferred_Down_2__c = 2,
				Third_Party_Pay_3__c = va.Id,
				dealer__Deferred_Down_3__c = 3,
    	    	dealer__Salesperson_1__c = UserInfo.getUserId()
    	    );
    	    insert(deal);

			// Setup an RO
			dealer__Service_Vehicle__c   dsv = new dealer__Service_Vehicle__c();
        	dsv.dealer__VIN__c ='TestXYZ';
        	dsv.Name='Test';
        	dsv.dealer__Body_Style__c = 'Test';
        	dsv.dealer__Company_Number__c='12123';
        	dsv.dealer__Veh_Owner_Contact__c = a.PersonContactId; 
        	dsv.dealer__Carline__c ='Test';
        	dsv.dealer__Make__c  ='Test';
        	dsv.dealer__Year__c  ='2013';
        	insert dsv;
			dealer__Service_Repair_Order__c   dsr = new dealer__Service_Repair_Order__c();
        	dsr.dealer__Customer__c =a.id;
        	dsr.dealer__Mileage_In__c =12;
        	dsr.dealer__RO_Number__c ='11';
        	dsr.dealer__VIN__c = 'TestXYZ';
        	dsr.dealer__Vehicle__c = dsv.Id;
        	dsr.dealer__Company__c=FFAdata.DealerLocation.Id;
        	insert dsr;

		}
	}

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();
			Account a = [select Id from Account limit 1];
			dealer__Rental_Agreements__c ra = [select Id from dealer__Rental_Agreements__c limit 1];
			dealer__Deal__c deal = [select Id from dealer__Deal__c limit 1];
			dealer__Service_Repair_Order__c sro = [select Id from dealer__Service_Repair_Order__c limit 1];

			Test.startTest();
			List<dealer__Cashering__c> cashiering = new List<dealer__Cashering__c>();
			System.debug('[[[ before insert cashiering ]]]');
			cashiering.add(new dealer__Cashering__c(
				dealer__Customer__c = a.Id,
				dealer__Amount__c = 10,
				dealer__Company_Number__c = FFAdata.DealerLocation.dealer__Company_Number__c,
				dealer__Location__c = FFAdata.DealerLocation.Id,
				dealer__Payment_Method__c = 'Cash',
				Create_Cash_Entry__c = true,
				dealer__Rental_Agreement__c = ra.Id
			));
			cashiering.add(new dealer__Cashering__c(
				dealer__Customer__c = a.Id,
				dealer__Amount__c = 10,
				dealer__Company_Number__c = FFAdata.DealerLocation.dealer__Company_Number__c,
				dealer__Location__c = FFAdata.DealerLocation.Id,
				dealer__Payment_Method__c = 'Cash',
				Create_Cash_Entry__c = true,
				dealer__Deal__c = deal.Id
			));
			cashiering.add(new dealer__Cashering__c(
				dealer__Customer__c = a.Id,
				dealer__Amount__c = 10,
				dealer__Company_Number__c = FFAdata.DealerLocation.dealer__Company_Number__c,
				dealer__Location__c = FFAdata.DealerLocation.Id,
				dealer__Payment_Method__c = 'Cash',
				Create_Cash_Entry__c = true,
				dealer__Service_Repair_Order__c = sro.Id
			));
			insert(cashiering);
			System.debug('[[[ after insert cashiering ]]]');

			List<dealer__Cashering__c> clist = [select Id, dealer__Location__c from dealer__Cashering__c];
			dealer__Cashering__c c = clist[0];
			System.debug('[[[ start test ]]]');
			CashierProcess.userLocation();
			CashierProcess.documentInfo(ra.Id);
			CashierProcess.documentInfo(deal.Id);
			CashierProcess.documentInfo(sro.Id);
			System.debug('[[[ before delete ]]]');
			CashierProcess.deleteCashier(c.Id);
			System.debug('[[[ after delete ]]]');
			Object s = CashierProcess.settings();
			CashierProcess.SetCompanyNumber(clist);
			List<c2g__codaCashEntry__c> celist = new List<c2g__codaCashEntry__c>();
			celist.add(new c2g__codaCashEntry__c());
			CashierProcess.RestrictManualCashEntries(celist);
			List<c2g__codaCashEntryLineItem__c> cellist = new List<c2g__codaCashEntryLineItem__c>();
			cellist.add(new c2g__codaCashEntryLineItem__c());
			CashierProcess.RestrictManualCashEntryLines(cellist);
			Test.stopTest();
		}
	}

	static testmethod void testTotalCollected() {
		FFAdata.refresh();
		Account a = [select Id, Name, isPersonAccount, PersonContactId from Account limit 1];
		dealer__Rental_Agreements__c ra = [select Id from dealer__Rental_Agreements__c limit 1];
		dealer__Deal__c deal = [select Id from dealer__Deal__c limit 1];
		dealer__Service_Repair_Order__c sro = [select Id from dealer__Service_Repair_Order__c limit 1];
		System.runAs(FFAdata.TestUser) {
			CashierProcess.sumDealCashier = true;
			CashierProcess.sumServiceCashier = true;
			CashierProcess.sumRentalCashier = true;
			Test.startTest();
			
			List<dealer__Cashering__c> cashiering = new List<dealer__Cashering__c>();
			System.debug('[[[ before insert cashiering ]]]');
			cashiering.add(new dealer__Cashering__c(
				dealer__Customer__c = a.Id,
				dealer__Amount__c = 10,
				dealer__Company_Number__c = FFAdata.DealerLocation.dealer__Company_Number__c,
				dealer__Location__c = FFAdata.DealerLocation.Id,
				dealer__Payment_Method__c = 'Check',
				Create_Cash_Entry__c = true,
				dealer__Deal__c = deal.Id
			));
			cashiering.add(new dealer__Cashering__c(
				dealer__Customer__c = a.Id,
				dealer__Amount__c = 10,
				dealer__Company_Number__c = FFAdata.DealerLocation.dealer__Company_Number__c,
				dealer__Location__c = FFAdata.DealerLocation.Id,
				dealer__Payment_Method__c = 'Check',
				Create_Cash_Entry__c = true,
				dealer__Service_Repair_Order__c = sro.Id
			));
			cashiering.add(new dealer__Cashering__c(
				dealer__Customer__c = a.Id,
				dealer__Amount__c = 10,
				dealer__Company_Number__c = FFAdata.DealerLocation.dealer__Company_Number__c,
				dealer__Location__c = FFAdata.DealerLocation.Id,
				dealer__Payment_Method__c = 'Check',
				Create_Cash_Entry__c = true,
				dealer__Rental_Agreement__c = ra.Id
			));
			insert(cashiering);
			System.debug('[[[ after insert cashiering ]]]');
			Test.stopTest();

			// check results!
			dealer__Rental_Agreements__c ra2 = [select Id, Total_Collected__c from dealer__Rental_Agreements__c where Id=:ra.Id limit 1];
			dealer__Deal__c deal2 = [select Id, Total_Collected__c from dealer__Deal__c where Id=:deal.Id limit 1];
			dealer__Service_Repair_Order__c sro2 = [select Id, Total_Collected__c from dealer__Service_Repair_Order__c where Id=:sro.Id limit 1];
			System.assertEquals(10, ra2.Total_Collected__c, 'Rental total collected is incorrect');
			System.assertEquals(10, sro2.Total_Collected__c, 'Service Repair Order total collected is incorrect');
			System.assertEquals(10, deal2.Total_Collected__c, 'Proposal total collected is incorrect');

		}
	}

}