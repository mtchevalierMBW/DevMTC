/**
 * RentalVehicleDepreciation_Tests
 * Tests: RentalVehicleDepreciation_CTLR
 *
 *  2016-08-17  MarinerTek
 *	2017-05-18	B. Leaman	BLL1 New GL accounts
 */
@isTest
private class RentalVehicleDepreciation_Tests
{    
//test setup 
        private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 
      @testSetup static void setupFFA() {
		    TestHelper_MW.createBaseFFAData(FFAdata);
		    FFAdata.CurrentCompany.DefaultPayableDimension1__c = FFAdata.dimension1.Id;
		    update(FFAdata.CurrentCompany);
		
		    // Need specific accounts
		    List<c2g__codaGeneralLedgerAccount__c> glas = new List<c2g__codaGeneralLedgerAccount__c>();
		    glas.add(new c2g__codaGeneralLedgerAccount__c(
		      c2g__ReportingCode__c ='1270',
		      c2g__Type__c='Balance Sheet',
		      VehicleRequired__c=true, VehicleComponent__c='Chassis',
		      Name='1270 Test'
		    ));
		    glas.add(new c2g__codaGeneralLedgerAccount__c(
		      c2g__ReportingCode__c ='4855',
		      c2g__Type__c='Balance Sheet',
		      VehicleRequired__c=true, VehicleComponent__c='Conversion',
		      Name='4855 Test'
		    ));
		    glas.add(new c2g__codaGeneralLedgerAccount__c(
		      c2g__ReportingCode__c ='8014',
		      c2g__Type__c='Balance Sheet',
		      Name='8014 Test'
		    ));
		    glas.add(new c2g__codaGeneralLedgerAccount__c(
		      c2g__ReportingCode__c ='1242',
		      c2g__Type__c='Balance Sheet',
		      VehicleRequired__c=true, VehicleComponent__c='Chassis',
		      Name='1242 Test'
		    ));
			// BLL1a
		    glas.add(new c2g__codaGeneralLedgerAccount__c(
		      c2g__ReportingCode__c ='1271',
		      c2g__Type__c='Balance Sheet',
		      VehicleRequired__c=true, VehicleComponent__c='Chassis',
		      Name='1271 Test'
		    ));
		    glas.add(new c2g__codaGeneralLedgerAccount__c(
		      c2g__ReportingCode__c ='1272',
		      c2g__Type__c='Balance Sheet',
		      VehicleRequired__c=true, VehicleComponent__c='Chassis',
		      Name='1272 Test'
		    ));
			// BLL1a end
		    insert glas;
		    
		    TestHelper_MW th = new TestHelper_MW();
		    
		    //make locations 
		    // create 2 locations, a vehicle and a trade
		    dealer__Dealer_Location__c loc1 = th.getDealerLocation('1');
		    dealer__Dealer_Location__c loc2 = th.getDealerLocation('2');
		    dealer__Dealer_Location__c loc3 = th.getDealerLocation('3');	// BLL5a
		    c2g__codaCompany__c testCompany = TestHelper_MW.createFFACompany('test', UserInfo.getUserId());
		    
		    loc1.Company__c = FFAdata.CurrentCompany.Id;
		    loc1.Financial_Force_Dimension_1__c = FFAdata.dimension1b.Id;
		    update(loc1);
		    loc2.Company__c = testCompany.Id;
		    loc2.Financial_Force_Dimension_1__c = FFAdata.dimension1b.Id;
		    update(loc2);
		    // BLL5a
		    loc3.Company__c = testCompany.Id;	
		    loc3.Financial_Force_Dimension_1__c = null;
		    // Do not set dimension1 on location 3!
		    update(loc3);
		    // BLL5a end
		    
		    //make vehicles    
		    List <dealer__Vehicle_Inventory__c> testVehicles = new List<dealer__Vehicle_Inventory__c>();
			testVehicles.add(new dealer__Vehicle_Inventory__c(
		        dealer__Status_Code__c='Company Vehicle',
		        Name='(TEST)20xx Dodge Caravan',
		        dealer__Year__c='20xx',
		        dealer__Make__c='Dodge',
		        dealer__Model__c='Grand Caravan',
		        dealer__Store_Location__c=loc1.Id,
		        Insurance_Start_Date__c = Date.valueOf('2008-01-01 00:00:00'),
		        dealer__Stock_Number__c='test1',
		        dealer__VIN__c=('112345678901234567').substring(0,17),
		        dealer__Vehicle_Cost__c = 10000,
		        //vehicle1.dealer__Store_Location__r.Company__r.Id = loc1.Id;
		        //vehicle1.dealer__Store_Location__r.Financial_Force_Dimension_1__c = loc1.Financial_Force_Dimension_1__c;
		        Last_Depreciation_Date__c = Date.valueOf('2008-01-01 00:00:00')
		    ));
		     
		    testVehicles.add(new dealer__Vehicle_Inventory__c(
		        dealer__Status_Code__c='Company Vehicle',
		        Name='(TEST)20xx Dodge Caravan',
		        dealer__Year__c='20xx',
		        dealer__Make__c='Dodge',
		        dealer__Model__c='Grand Caravan',
		        dealer__Store_Location__c=loc1.Id,
		        Insurance_Start_Date__c = Date.valueOf('2008-01-01 00:00:00'),
		        dealer__Stock_Number__c='test2',
		        dealer__VIN__c=('212345678901234567').substring(0,17),
		        dealer__Vehicle_Cost__c = 10000,
		        //vehicle1.dealer__Store_Location__r.Company__r.Id = loc1.Id;
		        //vehicle1.dealer__Store_Location__r.Financial_Force_Dimension_1__c = loc1.Financial_Force_Dimension_1__c;
		        Last_Depreciation_Date__c = Date.valueOf('2008-01-01 00:00:00')
		    ));

			testVehicles.add(new dealer__Vehicle_Inventory__c(
		        dealer__Status_Code__c='Rental',
		        Name='(TEST)20xx Ford Escape',
		        dealer__Year__c='20xx',
		        dealer__Make__c='Ford',
		        dealer__Model__c='Escape',
		        dealer__Store_Location__c=loc2.Id,	
		        Insurance_Start_Date__c = Date.valueOf('1900-01-01 00:00:00'),
		        dealer__Stock_Number__c='test3',
		        dealer__VIN__c=('312345678901234567').substring(0,17),
		        dealer__Vehicle_Cost__c = 10000,
		        //vehicle2.dealer__Store_Location__r.Company__r.Id = loc1.Id;
		        //vehicle2.dealer__Store_Location__r.Financial_Force_Dimension_1__c = loc1.Financial_Force_Dimension_1__c;
		        Last_Depreciation_Date__c = Date.valueOf('1900-01-01 00:00:00')
		    ));
		          
		    // BLL5a
		    testVehicles.add(new dealer__Vehicle_Inventory__c(
                dealer__Status_Code__c='Rental',
                Name='(TEST)20xx Ford Escape',
                dealer__Year__c='20xx',
                dealer__Make__c='Ford',
                dealer__Model__c='Escape',
                Insurance_Start_Date__c = Date.valueOf('1900-01-01 00:00:00'),
                dealer__Stock_Number__c='test4',
                dealer__VIN__c=('412345678901234567').substring(0,17),
                dealer__Vehicle_Cost__c = 10000,
                dealer__Store_Location__c = loc3.Id,	
                Last_Depreciation_Date__c = Date.valueOf('1900-01-01 00:00:00')
            ));
		    // BLL5a end
		    insert testVehicles;
		          
		    dealer.TestClassUtil tc = new dealer.TestClassUtil();
		    tc.insertDMSSettings();
		    dealer__FixedOperationsSettings__c fixedOpsSettings = new dealer__FixedOperationsSettings__c(
		      dealer__Repair_Order_Index__c=1
		    );
		    insert(fixedOpsSettings); 
    
	}
	
	
    @isTest
    static void testRVDController() {
        //setup test helpers
       FFAdata.refresh();
       //try{
        System.runAs(FFAdata.testUser) {
            //initialize constructors
            RentalVehicleDepreciation_CTLR rvd = new RentalVehicleDepreciation_CTLR();
            
            // BLL5d - causing null value reference in controller because non-writable fields are referenced
            // Therefore all records must be inserted into the database for the controller to succeed.
			//dealer__Dealer_Location__c loc = [select Id from dealer__Dealer_Location__c limit 1];	// BLL5a
            //rvd.vehicles.add(new dealer__Vehicle_Inventory__c(
            //    dealer__Status_Code__c='Rental',
            //    Name='(TEST)20xx Ford Escape',
            //    dealer__Year__c='20xx',
            //    dealer__Make__c='Ford',
            //    dealer__Model__c='Escape',
            //    Insurance_Start_Date__c = Date.valueOf('1900-01-01 00:00:00'),
            //    dealer__Stock_Number__c='test4',
            //    dealer__VIN__c=('412345678901234567').substring(0,17),
            //    dealer__Vehicle_Cost__c = 10000,
                // BLL5a
            //    dealer__Store_Location__c = loc.Id,	
			//	Rental_Depreciation_Exp__c = null,
			//	Rental_New_Vehicle_Cost__c = null,
				// BLL5a end
            //    Last_Depreciation_Date__c = Date.valueOf('1900-01-01 00:00:00')
            //));
            // BLL5a this one was never added to the vehicle list, but force it in to test error-handling lines
            dealer__Vehicle_Inventory__c veh4 = [
            	select Id, dealer__Status_Code__c, Name, dealer__Year__c, dealer__Make__c,
            		dealer__Model__c, dealer__Store_Location__r.Name, Rental_Vehicle_Costs__c,
            		Rental_Depreciation_Exp__c, Rental_New_Vehicle_Cost__c, Insurance_Start_Date__c,
            		dealer__Store_Location__r.Company__r.Id, dealer__Store_Location__r.Financial_Force_Dimension_1__c,
					dealer__Stock_Number__c, Last_Depreciation_Date__c, Chassis_Floorplan__c 
            	from dealer__Vehicle_Inventory__c
            	where dealer__Stock_Number__c = 'test4'
            	limit 1
            ];
            rvd.vehicles.add(veh4);
            // BLL5a end
            
            rvd.getVehicles();
            rvd.getShowDepreciateTable();
            rvd.submitDepreciation(); 
            rvd.getSummaryList();
            rvd.getShowSummaryTable();
        }
        //}catch(System.NullPointerException e){
        //System.Debug('Null Exception Error: ' + e);
        //}
	}
        
}