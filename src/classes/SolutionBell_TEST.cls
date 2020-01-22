/**
* SolutionBell_TEST
* Tests: SolutionBell
* Date: 2019-07-02
* Programmer: Bryan Leaman
* Project: #
*
* Coverage:
*
* Modifications: 
*
*/
@isTest
private class SolutionBell_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
		TestHelper_MW th = new TestHelper_MW();
		Account a = th.getCommercialAccount('1');
		Contact c = new Contact(FirstName='Test', LastName='Contact', AccountId=a.Id);
		insert(c);

	    // create vehicle 
	    dealer__Vehicle_Inventory__c veh = new dealer__Vehicle_Inventory__c(
	        Name='(TESTX) 2020 Toyota Future',
	        New_Used_Other__c='Used', Division__c='Consumer', 
	        dealer__Stock_Number__c='TESTX',
	        dealer__VIN__c='11234567890TUVWXZ',
	        dealer__Year__c='2020', dealer__Make__c='Toyota', dealer__Model__c='Future',
	        dealer__Mileage__c=1230
	    );
	    insert(veh);
		dealer__Vehicle_Inventory__c rentalveh = new dealer__Vehicle_Inventory__c(
			dealer__Stock_Number__c = 'RENTME',
			dealer__Year__c = '2020',
			dealer__Make__c = 'Toyota',
			dealer__Model__c = 'Sienna',
			dealer__VIN__c = '123RENTAL4567890Z',
			New_Used_Other__c = 'Rental'
		);
		insert(rentalveh);


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
		List<dealer__Deal__c> deals = new List<dealer__Deal__c>();
		for(Integer i=0;i<15;i++){
    		deals.add(new dealer__Deal__c(
    			Name = 'Test_'+String.valueOf(i+1),
    			RecordTypeId = dealRcdTypes.get('Commercial').getRecordTypeId(),
   	    		dealer__Deal_Type__c = 'Chassis/Conversion',
    			dealer__Auto_Insurance_Agent__c='Test',
    			dealer__Deal_ID__c ='Test_'+String.valueOf(i+1),
    			dealer__Sales_Lead__c = dsp.id,
    			dealer__Status__c ='Won - Delivered',
    			dealer__Deal_Date__c =System.Today(),
    			Proposed_Delivery_Date__c =System.Today(),
    			dealer__Vehicle__c = veh.Id,
    			dealer__Store_Location__c = FFAdata.DealerLocation.Id,
    			dealer__Salesperson_1__c = UserInfo.getUserId(),
				AdministrativeUpdate__c = true,
				Vehicle_Source__c = 'Inventory'
			));
		}
		insert(deals);

		List<dealer__Rental_Agreements__c> rentals = new List<dealer__Rental_Agreements__c>();
		for(Integer i=0; i<5; i++) {
			rentals.add(new dealer__Rental_Agreements__c(
        		Account__c = a.Id,
        		CustomerContact__c = c.Id,
        		Location__c = FFAdata.DealerLocation.Id,
        		dealer__Agreement_Status__c = 'Paid',
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
				dealer__Rental_Vehicle__c = rentalveh.id,
				Rental_Vehicle__c = rentalveh.id,
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
			));
		}
		insert(rentals);

	}

	// unitTest1
	//---------------------------------------
	static testMethod void unitTest1() {
		Test.startTest();
		DateTime now = DateTime.now();
		SolutionBell.countSolutionsForYear(now.year());
		Test.stopTest();
	}

	// unitTest2
	//---------------------------------------
	static testMethod void unitTest2() {
		Test.startTest();
		DateTime now = DateTime.now();
		SolutionBell.findSolutions(now.year(), 0, 8);			
		Test.stopTest();
	}

}