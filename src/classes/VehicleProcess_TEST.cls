/**
 * VehicleProcess_TEST
 * Tests: VehicleProcess
 * Date: Mar 13, 2018
 * Programmer: Bryan Leaman
 *
 * Floorplan payment re-calculations can be initiated manually by issuing a general update to the vehicle records:
 	BatchTouchRecordsSOQL ba = new BatchTouchRecordsSOQL(
 		'select Id, Name from dealer__Vehicle_Inventory__c where Floorplanned__c=true and Paid__c=false and Original_Floored_Amount__c!=null ', true);
	Database.executeBatch(ba);
 *
 * Schedule monthly (schedule/run as IT Department): (sec min hr day mth weekday year)
 	System.schedule('RecalcFloorplanPmts', '0 30 0 1 * ? *',	// 12:30 a.m. 1st of the month
 	 new BatchTouchRecordsSOQL(
 		'select Id, Name from dealer__Vehicle_Inventory__c where Floorplanned__c=true and Paid__c=false and Original_Floored_Amount__c!=null ', true));
 *
 * Change log:
 *	2018-03-13	B. Leaman	BLL3 - Created & combined from other test classes; added additional assertions to assure functionality;
 * 
 */
@isTest
private class VehicleProcess_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
	}

	// FloorplanPayments
	//---------------------------------------
	static testMethod void FloorplanPayments() {
		//FFAdata.refresh(); 
		//System.runAs(FFAdata.TestUser) {
        //	TestHelper_MW th = new TestHelper_MW();
			
		dealer__Vehicle_Inventory__c v = new dealer__Vehicle_Inventory__c(
			Floorplanned__c = true, 
			Paid__c = false, 
			Original_Floored_Amount__c = 10000, 
			Current_Floored_Amount__c = 9000, 
			Chassis_Floorplan__c = 'Huntington Used', 
			Chassis_Floored_Date__c = Date.today().addMonths(-10), 
			Conversion_Floorplan__c = 'Ignored', 
			Conv_Floored_Date__c = Date.today(), 
			New_Used_Other__c = 'Used', 
			dealer__Status_Code__c = 'Ready For Sale', 
			Conv_MFG__c = 'Braun', 
			ChassisPayment__c=null, ChassisPayment_1__c=null, ChassisPayment_2__c=null
		);

		VehicleProcess vp = new VehicleProcess(new List<dealer__Vehicle_Inventory__c>{v}, null, null);
		vp.CalculatePayments();

		System.debug(v);
		System.assertEquals(1000, v.ChassisPayment__c, 'Huntington Used curtailment month 10 was not 10% of floored amt');
		System.assertEquals(1000, v.ChassisPayment_1__c, 'Huntington Used curtailment month 11 was not 10% of floored amt');
		System.assertEquals(4000, v.ChassisPayment_2__c, 'Huntington Used curtailment month 12 was not 40% of floored amt');
		
		//}
	}

	
	// unitTest
    static testMethod void unitTest() {

		FFAdata.refresh();
		//System.runAs(FFAdata.TestUser) {
			Test.startTest();
	        dealer__Vehicle_Inventory__c veh = new dealer__Vehicle_Inventory__c(
	        	dealer__Year__c='2021', dealer__Make__c='Unknown', dealer__Model__c='Futuristic',
	        	dealer__VIN__c='12345698765ABCZYX', dealer__Stock_Number__c='ABCZYX',
	        	dealer__Store_Location__c=FFAdata.DealerLocation.Id, 	// BLL3a 
	        	PaymentDueDays__c=1, PaymentDueDate__c=null, dealer__Sale_Date__c = Date.today()
	        );
	        insert(veh);
	        dealer__Vehicle_Inventory__c archiveVeh = veh;
	        ArchiveVehicleInventory.archiveRecord(archiveVeh.Id);

	        Test.stopTest();
	        dealer__Vehicle_Inventory__c vehafter = [
	        	select Id, Name, PaymentDueDays__c, PaymentDueDate__c, OwnerId
	        	from dealer__Vehicle_Inventory__c
	        	where Id=:veh.Id
	        ];
	        System.assert(vehafter.PaymentDueDate__c>Date.today(), 'Did not set payment due date');
	        System.assert(vehafter.OwnerId!=UserInfo.getUserId(), 'Vehicle owner was not set to location service reporting user');	// BLL3a

		//}
        
    }

    static testmethod void testVehicleTrigger() {

		TestHelper_MW th = new TestHelper_MW();
		
        dealer__Dealer_Location__c ddl = new dealer__Dealer_Location__c();
        ddl.Name ='Test';
        ddl.dealer__City__c ='Test';
        ddl.dealer__Postal_Code__c='301352';
        ddl.dealer__State__c='Te';
        ddl.dealer__Company_Number__c='DT1';
        ddl.dealer__Service_Director__c =UserInfo.getUserId();
        ddl.Name='Test';
        ddl.Region__c='Test';
        ddl.dealer__Physical_Location__Longitude__s = -77.1;
        ddl.dealer__Physical_Location__Latitude__s = 38.8;
        insert ddl;     

        Profile prof = [select id from profile where name='system Administrator'];
        User usr = new User(alias = 'usr', email='us.name@vmail.com',
                  emailencodingkey='UTF-8', lastname='lstname',
                  timezonesidkey='America/Los_Angeles',
                  languagelocalekey='en_US',
                  localesidkey='en_US', profileid = prof.Id,
                  username='testuser128@test.mobilityworks.com',
                  Division='DT1');
                  insert usr;
                  
        System.runAs(usr){
            
            dealer__Vehicle_Inventory__c v = new dealer__Vehicle_Inventory__c();
            v.dealer__Year__c = '2015';
            v.dealer__Make__c = 'Honda';
            v.dealer__Model__c= 'Civic';

            v.dealer__Stock_Number__c = '1234-5678';
            v.dealer__VIN__c = '12345669696969';
            v.dealer__Company_Number__c = 'DT1';
            //v.dealer__Store_Location__c = ddl.Id;

            insert v;

	        // Check result location
	        dealer__Vehicle_Inventory__c v2 = [
	        	select Id, dealer__Store_Location__c, dealer__Company_Number__c
	        	from dealer__Vehicle_Inventory__c
	        	where Id=:v.Id
	        ];
	        System.debug(v2);
	        System.assertEquals(ddl.Id, v2.dealer__Store_Location__c,  'Vehicle Inventory was not set to user location');

			dealer__Dealer_Location__c dloc2 = th.getDealerLocation('1');
	        v2.dealer__Store_Location__c = dloc2.Id;
	        //v2.dealer__Company_Number__c = null;
			System.debug('Set store location to ' + dloc2.Id);
	        update(v2);
        
	        dealer__Vehicle_Inventory__c v3 = [
	        	select Id, dealer__Store_Location__c, dealer__Company_Number__c
	        	from dealer__Vehicle_Inventory__c
	        	where Id=:v.Id
	        ];
	        System.debug(v3);
	        System.assertEquals(dloc2.dealer__Company_Number__c, v3.dealer__Company_Number__c, 'Vehicle Inventory was not set to new location abbrev');

        }

    }
    
    // BLL2a 
    static testmethod void testProposalUpd() {
        FFAdata.refresh(); 
                        
        System.runAs(FFAdata.TestUser) {
            TestHelper_MW th = new TestHelper_MW();

            Account a = th.getPersonAccount('1');

            dealer__Vehicle_Inventory__c v = new dealer__Vehicle_Inventory__c(
                dealer__Year__c = '2015',
                dealer__Make__c = 'Honda',
                dealer__Model__c= 'Civic',
                dealer__Stock_Number__c = '1234-5678',
                dealer__VIN__c = '12345669696969',
                dealer__Store_Location__c = FFAdata.DealerLocation.Id,
                dealer__Vehicle_Cost__c = 10000,
                Conversion_Cost__c = 8000
            );
            insert(v);

            dealer__Sales_Up__c  dsp = new dealer__Sales_Up__c(
                dealer__Lead_Date__c=System.Today(),
                dealer__Lead_Status__c='Pending',
                dealer__Lead_Type__c='List',
                dealer__Source__c ='Pride',
                Solution_Type__c ='Rental',
                dealer__Customer_Account__c =a.id,
                dealer__First_Store_Visit_Date__c = Datetime.now()
            );
            insert(dsp); 
                    
            dealer__Deal__c deal = new dealer__Deal__c(
                Name = 'Test',
                dealer__Auto_Insurance_Agent__c='Test',
                dealer__Deal_ID__c ='Test',
                dealer__Sales_Lead__c = dsp.id,
                dealer__Status__c ='Pending',
                dealer__Deal_Date__c =System.Today(),
                Proposed_Delivery_Date__c =System.Today(),
                dealer__Store_Location__c = FFAdata.DealerLocation.Id,
                dealer__Vehicle__c = v.Id,
                Vehicle_Source__c = 'Inventory'
            );
            insert(deal);
             
            Test.startTest();
            v.dealer__Vehicle_Cost__c += 1000;
            v.Conversion_Cost__c += 1000;
            update(v);
            Test.stopTest();

        }
    }
    // BLL2a end
 
}