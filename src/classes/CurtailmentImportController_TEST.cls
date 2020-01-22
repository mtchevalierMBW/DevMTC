/**
 * CurtailmentImportController_TEST
 * Tests: CurtailmentImportController, CurtailmentImportController_2, Curtailment_BatchProcess
 *
 *  2016-09-26  MarinerTek
 *	2017-10-23	B. Leaman	BLL1 - increase coverage for new date floored column.
 *	2018-02-27	B. Leaman	BLL2 - new GL account for Huntington PPV floorplan.
 *	2018-08-16	B. Leaman	BLL3 - handle new requirement of referencing bank account for GLA 1001 (all GLAs 10*)
 *	2019-10-03	B. Leaman	W-000762 BLL4 - improve code coverage
 */
@isTest
private class CurtailmentImportController_TEST
{    
    public static String csvTest {get; set;}
    //test setup 
    private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 
    @testSetup static void setupFFA() {
        TestHelper_MW.createBaseFFAData(FFAdata);
        FFAdata.CurrentCompany.DefaultPayableDimension1__c = FFAdata.dimension1.Id;
        update(FFAdata.CurrentCompany);

		System.runAs(FFAdata.TestUser) {
        
		         // Need specific accounts
		    List<c2g__codaGeneralLedgerAccount__c> glas = new List<c2g__codaGeneralLedgerAccount__c>();
		    glas.add(new c2g__codaGeneralLedgerAccount__c(
		      c2g__ReportingCode__c ='2515',
		      c2g__Type__c='Balance Sheet',
		      VehicleRequired__c=true, VehicleComponent__c='Chassis',
		      Name='2515 Test'
		    ));
		    glas.add(new c2g__codaGeneralLedgerAccount__c(
		      c2g__ReportingCode__c ='2510',
		      c2g__Type__c='Balance Sheet',
		      VehicleRequired__c=true, VehicleComponent__c='Conversion',
		      Name='2510 Test'
		    ));
		    glas.add(new c2g__codaGeneralLedgerAccount__c(
		      c2g__ReportingCode__c ='2500',
		      c2g__Type__c='Balance Sheet',
		      Name='2500 Test'
		    ));
		    // BLL2a
		    glas.add(new c2g__codaGeneralLedgerAccount__c(
		      c2g__ReportingCode__c ='2505',
		      c2g__Type__c='Balance Sheet',
		      Name='2505 Test'
		    ));
		    // BLL2a end
		    glas.add(new c2g__codaGeneralLedgerAccount__c(
		      c2g__ReportingCode__c ='1001',
		      c2g__Type__c='Balance Sheet',
		      VehicleRequired__c=true, VehicleComponent__c='Chassis',
		      Name='1001 Test'
		    ));
		    insert glas;
		    
		    TestHelper_MW th = new TestHelper_MW();
		    
		    c2g__codaDimension1__c dimWMK = new c2g__codaDimension1__c();
		    dimWMK.Name = '100 - WMK, LLC. COMPANY DIMENSION';
		    dimWMK.c2g__ReportingCode__c = '100';
		    insert(dimWMK);
		    
		    // BLL3a - Need bank account for GLA 1001 journal entries
		    c2g__codaGeneralLedgerAccount__c gla1001 = [select Id from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c='1001'];
		    c2g__codaBankAccount__c bank = new c2g__codaBankAccount__c(
		    	Name='Test Bank', c2g__ReportingCode__c='1001CH', c2g__BankName__c='Test Bank',
		    	c2g__AccountName__c='CompanyAcct', c2g__AccountNumber__c='123456789',
		    	c2g__BankAccountCurrency__c=FFAData.HomeCurrency.Id,
		    	//c2g__OwnerCompany__c = FFAData.CurrentCompany.Id,
		    	c2g__GeneralLedgerAccount__c = gla1001.id
		    );
		    insert(bank);
		    // BLL3a end
		    
		    //make locations 
		    // create 2 locations, a vehicle and a trade
		    dealer__Dealer_Location__c loc1 = th.getDealerLocation('1');
		    dealer__Dealer_Location__c loc2 = th.getDealerLocation('2');
		    //c2g__codaCompany__c testCompany = TestHelper_MW.createFFACompany('W M K, LLC', UserInfo.getUserId());
		    //BLL3d FFAdata.CurrentCompany.Name = 'W M K, LLC';	
		    FFAdata.CurrentCompany.c2g__ExternalId__c = 'WMK';	// BLL3a
		    update(FFAdata.CurrentCompany);
		    
		    loc1.Company__c = FFAdata.CurrentCompany.Id;
		    loc1.Financial_Force_Dimension_1__c = dimWMK.Id;
		    update(loc1);
		    loc2.Company__c = FFAdata.CurrentCompany.Id;
		    loc2.Financial_Force_Dimension_1__c = dimWMK.Id;
		    update(loc2);
		    system.debug('FFAdata Current Company: ' + FFAdata.CurrentCompany);
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
		        dealer__VIN__c=('11234567890123456').substring(0,17),
		        dealer__Vehicle_Cost__c = 10000,
		        Floorplanned__c = true,
		        Paid__c = false,
		        Chassis_Floorplan__c = 'Huntington New',
		        Current_Floored_Amount__c = 15000,
		        dealer__Stock_Number__c = '4AB342'
		        //vehicle1.dealer__Store_Location__r.Company__r.Id = loc1.Id;
		        //vehicle1.dealer__Store_Location__r.Financial_Force_Dimension_1__c = loc1.Financial_Force_Dimension_1__c;
		    ));
		        
		    insert new Curtailment_CSV_Templates__c(Name = 'Test', Floorplan__c = 'Huntington New', VIN_Column__c = 'VIN', Amount_Column__c = 'Amount', Original_Amount__c = 'Original Amount', Date_Floored_Column__c='Date Floored' );	// BLL1c
		
		     
		    testVehicles.add(new dealer__Vehicle_Inventory__c(
		        dealer__Status_Code__c='Company Vehicle',
		        Name='(TEST)20xx Dodge Caravan',
		        dealer__Year__c='20xx',
		        dealer__Make__c='Dodge',
		        dealer__Model__c='Grand Caravan',
		        dealer__Store_Location__c=loc1.Id,
		        Insurance_Start_Date__c = Date.valueOf('2008-01-01 00:00:00'),
		        dealer__VIN__c=('21234567890123456').substring(0,17),
		        dealer__Vehicle_Cost__c = 10000,
		        Floorplanned__c = true,
		        Paid__c = false,
		        Chassis_Floorplan__c = 'Huntington Used',
		        Current_Floored_Amount__c = 15000,
		        dealer__Stock_Number__c = '4DE134'
		        //vehicle1.dealer__Store_Location__r.Company__r.Id = loc1.Id;
		        //vehicle1.dealer__Store_Location__r.Financial_Force_Dimension_1__c = loc1.Financial_Force_Dimension_1__c;
		    ));
		          
		    testVehicles.add(new dealer__Vehicle_Inventory__c(
		        dealer__Status_Code__c='Rental',
		        Name='(TEST)20xx Ford Escape',
		        dealer__Year__c='20xx',
		        dealer__Make__c='Ford',
		        dealer__Model__c='Escape',
		        dealer__Store_Location__c=loc2.Id,
		        Insurance_Start_Date__c = Date.valueOf('1900-01-01 00:00:00'),
		        dealer__VIN__c=('31234567890123456').substring(0,17),
		        dealer__Vehicle_Cost__c = 10000,
		        Floorplanned__c = true,
		        Paid__c = false,
		        Chassis_Floorplan__c = 'Huntington Rental',
		        Current_Floored_Amount__c = 15000,
		        dealer__Stock_Number__c = '4BE142'
		        //vehicle2.dealer__Store_Location__r.Company__r.Id = loc1.Id;
		        //vehicle2.dealer__Store_Location__r.Financial_Force_Dimension_1__c = loc1.Financial_Force_Dimension_1__c;
		    ));
		        
		    testVehicles.add(new dealer__Vehicle_Inventory__c(
		        dealer__Status_Code__c='Rental',
		        Name='(TEST)20xx Ford Mustang',
		        dealer__Year__c='20xx',
		        dealer__Make__c='Ford',
		        dealer__Model__c='Mustang',
		        dealer__Store_Location__c=loc2.Id,
		        Insurance_Start_Date__c = Date.valueOf('1900-01-01 00:00:00'),
		        dealer__VIN__c=('91234567890123456').substring(0,17),
		        dealer__Vehicle_Cost__c = 10000,
		        Floorplanned__c = true,
		        Paid__c = false,
		        Chassis_Floorplan__c = 'Huntington Rental',
		        Current_Floored_Amount__c = 15000,
		        dealer__Stock_Number__c = '9BE142'
		        //vehicle2.dealer__Store_Location__r.Company__r.Id = loc1.Id;
		        //vehicle2.dealer__Store_Location__r.Financial_Force_Dimension_1__c = loc1.Financial_Force_Dimension_1__c;
		    ));
		        
		    
		    testVehicles.add(new dealer__Vehicle_Inventory__c(
		        dealer__Status_Code__c='Rental',
		        Name='(TEST)20xx Ford Explorer',
		        dealer__Year__c='20xx',
		        dealer__Make__c='Ford',
		        dealer__Model__c='Explorer',
		        dealer__Store_Location__c=loc2.Id,
		        Insurance_Start_Date__c = Date.valueOf('1900-01-01 00:00:00'),
		        dealer__VIN__c=('31234568790123456').substring(0,17),
		        dealer__Vehicle_Cost__c = 10000,
		        Floorplanned__c = true,
		        Paid__c = false,
		        Chassis_Floorplan__c = '',
		        Current_Floored_Amount__c = 15000,
		        dealer__Stock_Number__c = '6GD215'
		        //vehicle2.dealer__Store_Location__r.Company__r.Id = loc1.Id;
		        //vehicle2.dealer__Store_Location__r.Financial_Force_Dimension_1__c = loc1.Financial_Force_Dimension_1__c;
		    ));
		    
		    testVehicles.add(new dealer__Vehicle_Inventory__c(
		        dealer__Status_Code__c='Rental',
		        Name='(TEST)20xx Ford Explorer',
		        dealer__Year__c='20xx',
		        dealer__Make__c='Ford',
		        dealer__Model__c='Explorer',
		        dealer__Store_Location__c=loc2.Id,
		        Insurance_Start_Date__c = Date.valueOf('1900-01-01 00:00:00'),
		        dealer__VIN__c=('31234568790123459').substring(0,17),
		        dealer__Vehicle_Cost__c = 10000,
		        Floorplanned__c = true,
		        Paid__c = false,
		        Chassis_Floorplan__c = 'Huntington Rental',
		        Current_Floored_Amount__c = 15000,
		        dealer__Stock_Number__c = '6GD115'
		        //vehicle2.dealer__Store_Location__r.Company__r.Id = loc1.Id;
		        //vehicle2.dealer__Store_Location__r.Financial_Force_Dimension_1__c = loc1.Financial_Force_Dimension_1__c;
		    ));
		    
		    testVehicles.add(new dealer__Vehicle_Inventory__c(
		        dealer__Status_Code__c='Rental',
		        Name='(TEST)20xx Ford Explorer',
		        dealer__Year__c='20xx',
		        dealer__Make__c='Ford',
		        dealer__Model__c='Explorer',
		        dealer__Store_Location__c=loc2.Id,
		        Insurance_Start_Date__c = Date.valueOf('1900-01-01 00:00:00'),
		        dealer__VIN__c=('31234568790123450').substring(0,17),
		        dealer__Vehicle_Cost__c = 10000,
		        Floorplanned__c = true,
		        Paid__c = false,
		        Chassis_Floorplan__c = 'Huntington Rental',
		        Current_Floored_Amount__c = 0,
		        dealer__Stock_Number__c = '6GD315'
		        //vehicle2.dealer__Store_Location__r.Company__r.Id = loc1.Id;
		        //vehicle2.dealer__Store_Location__r.Financial_Force_Dimension_1__c = loc1.Financial_Force_Dimension_1__c;
		    ));

			// BLL4 dupe vin
			testVehicles.add(new dealer__Vehicle_Inventory__c(
		        dealer__Status_Code__c='Rental',
		        Name='(TEST)20xx Ford Explorer',
		        dealer__Year__c='20xx',
		        dealer__Make__c='Ford',
		        dealer__Model__c='Explorer',
		        dealer__Store_Location__c=loc2.Id,
		        Insurance_Start_Date__c = Date.valueOf('1900-01-01 00:00:00'),
		        dealer__VIN__c=('31234568790123450').substring(0,17),
		        dealer__Vehicle_Cost__c = 10000,
		        Floorplanned__c = true,
		        Paid__c = false,
		        Chassis_Floorplan__c = 'Huntington Rental',
		        Current_Floored_Amount__c = 0,
		        dealer__Stock_Number__c = '6GD315A'
		        //vehicle2.dealer__Store_Location__r.Company__r.Id = loc1.Id;
		        //vehicle2.dealer__Store_Location__r.Financial_Force_Dimension_1__c = loc1.Financial_Force_Dimension_1__c;
		    ));
			// BLL4 end dupe vin

		    testVehicles.add(new dealer__Vehicle_Inventory__c(
		        dealer__Status_Code__c='Rental',
		        Name='(TEST)20xx Ford Explorer',
		        dealer__Year__c='20xx',
		        dealer__Make__c='Ford',
		        dealer__Model__c='Explorer',
		        dealer__Store_Location__c=loc2.Id,
		        Insurance_Start_Date__c = Date.valueOf('1900-01-01 00:00:00'),
		        dealer__VIN__c=('31234568790123499').substring(0,17),
		        dealer__Vehicle_Cost__c = 10000,
		        Floorplanned__c = true,
		        Paid__c = true,
		        Chassis_Floorplan__c = 'Huntington Used',
		        Current_Floored_Amount__c = 15000,
		        dealer__Stock_Number__c = '6GE315'
		        //vehicle2.dealer__Store_Location__r.Company__r.Id = loc1.Id;
		        //vehicle2.dealer__Store_Location__r.Financial_Force_Dimension_1__c = loc1.Financial_Force_Dimension_1__c;
		    ));
		          
		    insert testVehicles;
		    system.debug('TEST VEHICLES: ' + testVehicles);

		}
		
    dealer.TestClassUtil tc = new dealer.TestClassUtil();
    tc.insertDMSSettings();
    dealer__FixedOperationsSettings__c fixedOpsSettings = new dealer__FixedOperationsSettings__c(
      dealer__Repair_Order_Index__c=1
    );
    insert(fixedOpsSettings); 
    system.debug('CSV test: ' + csvTest);
  }
  
    @isTest
    static void testCurtailmentController() {
       //setup test helpers
       FFAdata.refresh();
        csvTest = 'PMT_SORT_CD,DLR_NBR,CITY_NMEDLR_NME,STR_LINE1_ADDR,STR_LINE2_ADDR,STT_ABBR,ZIP_CD_NBR,CO_NME,LOAN_ID,DLR_BANK_ACCT_CD,SERIAL_NBR,INV_NBR,STOCK_NBR,MODEL_NME,CURR_PRINC_AMT,CURT_DUE_AMT,CURT_DUE_DT,PMT_AMT,DLR_PMT_ID,PMT_TYP_CD,UNITS_PD,WMS_PULLED_IND,USER_CD,RQST_STS,STS_RSN,POST_DT\n';   
        csvTest += 'PMT_SORT_CD,DLR_NBR,CITY_NMEDLR_NME,STR_LINE1_ADDR,STR_LINE2_ADDR,STT_ABBR,ZIP_CD_NBR,CO_NME,LOAN_ID,DLR_BANK_ACCT_CD,SERIAL_NBR,INV_NBR,STOCK_NBR,MODEL_NME,CURR_PRINC_AMT,CURT_DUE_AMT,CURT_DUE_DT,PMT_AMT,DLR_PMT_ID,PMT_TYP_CD,UNITS_PD,WMS_PULLED_IND,USER_CD,RQST_STS,STS_RSN,POST_DT\n';
        
        //add test vehicles to csv
        csvTest += 'C,10000097,AKRON,WMK INC.,810 MOE DRIVE,,OH,44310,Huntington National Bank,OPER,,,11234567890123456,,4AB342,Escape,10000,0,,2000,20000,PRINC,1,1,DEEANAE,Posted,DAS Payments,9/20/2016 11:49:48 AM\n';
        csvTest += 'C,10000097,AKRON,WMK INC.,810 MOE DRIVE,,OH,44310,Huntington National Bank,OPER,,,21234567890123456,,4DE134,Escape,20000,0,,1000,20000,PRINC,1,1,DEEANAE,Posted,DAS Payments,9/20/2016 11:49:48 AM\n';
        csvTest += 'C,10000097,AKRON,WMK INC.,810 MOE DRIVE,,OH,44310,Huntington National Bank,OPER,,,31234567890123456,,4BE142,Escape,30000,0,,3000,20000,PRINC,1,1,DEEANAE,Posted,DAS Payments,9/20/2016 11:49:48 AM\n';
        csvTest += 'C,10000097,AKRON,WMK INC.,810 MOE DRIVE,,OH,44310,Huntington National Bank,OPER,,,91234567890123456,,9BE142,Escape,30000,0,,3000,20000,PRINC,1,1,DEEANAE,Posted,DAS Payments,9/20/2016 11:49:48 AM\n';
        csvTest += 'C,10000097,AKRON,WMK INC.,810 MOE DRIVE,,OH,44310,Huntington National Bank,OPER,,,31234568790123456,,6GD215,Explorer,30000,0,,3000,20000,PRINC,1,1,DEEANAE,Posted,DAS Payments,9/20/2016 11:49:48 AM\n';
        csvTest += 'C,10000097,AKRON,WMK INC.,810 MOE DRIVE,,OH,44310,Huntington National Bank,OPER,,,31234567890123459,,6GD115,Explorer,30000,0,,0,20000,PRINC,1,1,DEEANAE,Posted,DAS Payments,9/20/2016 11:49:48 AM\n';
        csvTest += 'C,10000097,AKRON,WMK INC.,810 MOE DRIVE,,OH,44310,Huntington National Bank,OPER,,,31234568790123450,,6GD315,Explorer,30000,0,,3000,20000,PRINC,1,1,DEEANAE,Posted,DAS Payments,9/20/2016 11:49:48 AM\n';
        csvTest += 'C,10000097,AKRON,WMK INC.,810 MOE DRIVE,,OH,44310,Huntington National Bank,OPER,,,31234568790123499,,6GE315,Explorer,30000,0,,3000,20000,PRINC,1,1,DEEANAE,Posted,DAS Payments,9/20/2016 11:49:48 AM\n';
        
        for(Integer i=0; i<10;i++) //add more vehicles to csv
        {
            csvTest += 'C,10000097,AKRON,WMK INC.,810 MOE DRIVE,,OH,44310,Huntington National Bank,OPER,,,'+i+',,test'+i+',Escape,10000,0,,2000,20000,PRINC,1,1,DEEANAE,Posted,DAS Payments,9/20/2016 11:49:48 AM\n';
        }
        
        string csvTest2 = 'blank,VIN,Amount,Original Amount,Date Floored\n';           
        //add test vehicles to csv
		csvTest2 += 'a,123456,500,500,2017-02-01\n';	// BLL1c
        csvTest2 += 'a,31234568790123499,1000,500,1/1/17,\n';	// BLL1c
        csvTest2 += 'a,000000,0,0,\n';	// BLL1c
        csvTest2 += 'a,000000,0,0,\n';	// BLL1c
         
       	//Map<String, Decimal> tMap = new Map<String, Decimal>();
       	Map<String, String> tMap = new Map<String, String>();
        tMap.put('123456', '100.00,100.00,2017-02-01');	// BLL1c
        tMap.put('31234568790123499','1000.00,1000.00,1/1/17');	// BLL1c
            System.runAs(FFAdata.testUser) {
                test.startTest();

                //initialize constructors
                CurtailmentImportController c = new CurtailmentImportController();
                c.importCSVFile(); //accomodate catch block
                c.csvFileBody = Blob.valueOf(csvTest);
                c.testBool = true;
                c.importCSVFile();
                c.submitCurtailments();
                c.getShowCurtailmentbtn();
                c.getShowCurtailmentTable();
                c.getShowImportBtns();
                c.getShowResetbtn();
                c.getSummaryList();
                c.getShowSummaryTable();
                
                test.stopTest();
            }
   }        

    @isTest
    static void testCurtailmentController2() {
       //setup test helpers
       FFAdata.refresh();
        csvTest = 'PMT_SORT_CD,DLR_NBR,CITY_NMEDLR_NME,STR_LINE1_ADDR,STR_LINE2_ADDR,STT_ABBR,ZIP_CD_NBR,CO_NME,LOAN_ID,DLR_BANK_ACCT_CD,SERIAL_NBR,INV_NBR,STOCK_NBR,MODEL_NME,CURR_PRINC_AMT,CURT_DUE_AMT,CURT_DUE_DT,PMT_AMT,DLR_PMT_ID,PMT_TYP_CD,UNITS_PD,WMS_PULLED_IND,USER_CD,RQST_STS,STS_RSN,POST_DT\n';   
        csvTest += 'PMT_SORT_CD,DLR_NBR,CITY_NMEDLR_NME,STR_LINE1_ADDR,STR_LINE2_ADDR,STT_ABBR,ZIP_CD_NBR,CO_NME,LOAN_ID,DLR_BANK_ACCT_CD,SERIAL_NBR,INV_NBR,STOCK_NBR,MODEL_NME,CURR_PRINC_AMT,CURT_DUE_AMT,CURT_DUE_DT,PMT_AMT,DLR_PMT_ID,PMT_TYP_CD,UNITS_PD,WMS_PULLED_IND,USER_CD,RQST_STS,STS_RSN,POST_DT\n';
        
        //add test vehicles to csv
        csvTest += 'C,10000097,AKRON,WMK INC.,810 MOE DRIVE,,OH,44310,Huntington National Bank,OPER,,,11234567890123456,,4AB342,Escape,10000,0,,2000,20000,PRINC,1,1,DEEANAE,Posted,DAS Payments,9/20/2016 11:49:48 AM\n';
        csvTest += 'C,10000097,AKRON,WMK INC.,810 MOE DRIVE,,OH,44310,Huntington National Bank,OPER,,,21234567890123456,,4DE134,Escape,20000,0,,1000,20000,PRINC,1,1,DEEANAE,Posted,DAS Payments,9/20/2016 11:49:48 AM\n';
        csvTest += 'C,10000097,AKRON,WMK INC.,810 MOE DRIVE,,OH,44310,Huntington National Bank,OPER,,,31234567890123456,,4BE142,Escape,30000,0,,3000,20000,PRINC,1,1,DEEANAE,Posted,DAS Payments,9/20/2016 11:49:48 AM\n';
        csvTest += 'C,10000097,AKRON,WMK INC.,810 MOE DRIVE,,OH,44310,Huntington National Bank,OPER,,,91234567890123456,,9BE142,Escape,30000,0,,3000,20000,PRINC,1,1,DEEANAE,Posted,DAS Payments,9/20/2016 11:49:48 AM\n';
        csvTest += 'C,10000097,AKRON,WMK INC.,810 MOE DRIVE,,OH,44310,Huntington National Bank,OPER,,,31234568790123456,,6GD215,Explorer,30000,0,,3000,20000,PRINC,1,1,DEEANAE,Posted,DAS Payments,9/20/2016 11:49:48 AM\n';
        csvTest += 'C,10000097,AKRON,WMK INC.,810 MOE DRIVE,,OH,44310,Huntington National Bank,OPER,,,31234567890123459,,6GD115,Explorer,30000,0,,0,20000,PRINC,1,1,DEEANAE,Posted,DAS Payments,9/20/2016 11:49:48 AM\n';
        csvTest += 'C,10000097,AKRON,WMK INC.,810 MOE DRIVE,,OH,44310,Huntington National Bank,OPER,,,31234568790123450,,6GD315,Explorer,30000,0,,3000,20000,PRINC,1,1,DEEANAE,Posted,DAS Payments,9/20/2016 11:49:48 AM\n';
        csvTest += 'C,10000097,AKRON,WMK INC.,810 MOE DRIVE,,OH,44310,Huntington National Bank,OPER,,,31234568790123499,,6GE315,Explorer,30000,0,,3000,20000,PRINC,1,1,DEEANAE,Posted,DAS Payments,9/20/2016 11:49:48 AM\n';
        
        for(Integer i=0; i<10;i++) //add more vehicles to csv
        {
            csvTest += 'C,10000097,AKRON,WMK INC.,810 MOE DRIVE,,OH,44310,Huntington National Bank,OPER,,,'+i+',,test'+i+',Escape,10000,0,,2000,20000,PRINC,1,1,DEEANAE,Posted,DAS Payments,9/20/2016 11:49:48 AM\n';
        }
        
        string csvTest2 = 'blank,VIN,Amount,Original Amount,Date Floored\n';           
        //add test vehicles to csv
		csvTest2 += 'a,123456,500,500,2017-02-01\n';	// BLL1c
        csvTest2 += 'a,31234568790123499,1000,500,1/1/17,\n';	// BLL1c
        csvTest2 += 'a,000000,0,0,\n';	// BLL1c
        csvTest2 += 'a,000000,0,0,\n';	// BLL1c
         
       	//Map<String, Decimal> tMap = new Map<String, Decimal>();
       	Map<String, String> tMap = new Map<String, String>();
        tMap.put('123456', '100.00,100.00,2017-02-01');	// BLL1c
        tMap.put('31234568790123499','1000.00,1000.00,1/1/17');	// BLL1c
            System.runAs(FFAdata.testUser) {
                test.startTest();

                Test.setCurrentPage(Page.CurtailmentImport_2);
                CurtailmentImportController_2 c2 = new CurtailmentImportController_2();
                c2.testBool = true;
                c2.floorplan = 'Test';
                c2.csvFileBody = Blob.valueOf(csvTest2);
                c2.importCSVFile(); //accomodate catch block
                c2.csvFileBody = Blob.valueOf(csvTest2);
                c2.importCSVFile();
                c2.submitCurtailments();
                c2.getShowCurtailmentbtn();
                c2.getShowCurtailmentTable();
                c2.getShowImportBtns();
                c2.getShowResetbtn();
                c2.getShowUploadTable();
                c2.getvehicleSubmitCount();
                c2.getOptions();
                c2.reset();
                
                Curtailment_BatchProcess ba = new Curtailment_BatchProcess(tMap);
        		Database.executeBatch(ba);

                test.stopTest();
            }
   }        

}