/**
 * Change Log:
 *  2015-10-8   D. Ray  DR1 - Increase Test Coverege
 *  2016-02-02  B. Leaman   IT#19480 - Replace getMakes with generating list once in constructor and use built-in getter.
 *  2016-03-24  B. Leaman   BLL2 - Changed some selections to multi-select (List<String>).
 *  2018-04-18  B. Leaman   BLL3 - test the searchall function.
 *  2018-08-17  B. Leaman   BLL4 - additional info needed to test return to deal.
 */
@isTest
private class VehicleAdvancedSearch_TC{

    private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

    @testSetup
    static void setupFFA() {
        TestHelper_MW.createBaseFFAData(FFAdata);
        TestHelper_MW th = new TestHelper_MW();
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
        insert(new dealer__FixedOperationsSettings__c(dealer__Repair_Order_Index__c=1));
        insert(new RetailDefaults__c(ProposalNumber__c=7));  

        // BLL4a
        Account a = th.getPersonAccount('1');
        
        // Need service pmt types
        List<ServicePaymentType__c> spts = new List<ServicePaymentType__c>();
        spts.add(new ServicePaymentType__c(Name='IEN',Default_Labor_Rate__c=52,Description__c='Test IEN'));
        spts.add(new ServicePaymentType__c(Name='IEU',Default_Labor_Rate__c=52,Description__c='Test IEU'));
        spts.add(new ServicePaymentType__c(Name='IEO',Default_Labor_Rate__c=52,Description__c='Test IEO'));
        insert(spts);
        
        // create vehicle 
        dealer__Vehicle_Inventory__c veh = new dealer__Vehicle_Inventory__c(
            Name='(TESTX) 2020 Toyota Future',
            New_Used_Other__c='Used', Division__c='Commercial',
            dealer__Status_Code__c = 'Ready For Sale', 
            dealer__Stock_Number__c='TESTX',
            dealer__VIN__c='11234567890TUVWXY',
            dealer__Year__c='2020', dealer__Make__c='Toyota', dealer__Model__c='Future',
            dealer__Mileage__c=123000
        );
        insert(veh);

        dealer__Sales_Up__c  dsp = new dealer__Sales_Up__c(
            dealer__Lead_Date__c=System.Today(),
            dealer__First_Store_Visit_Date__c = DateTime.now(),     // BLL1a
            dealer__Lead_Status__c='Pending',
            dealer__Lead_Type__c='List',
            dealer__Source__c ='Pride',
            Solution_Type__c ='Chassis/Conversion',
            dealer__Customer_Account__c =a.id,
            dealer__Trade_Year__c = '2016',
            dealer__Trade_Make__c = 'Toyota',
            dealer__Trade_Model__c = 'Greatness'
        );
        insert dsp;
        // BLL4a - end

        dealer__Vehicle_Inventory__c dvi = new dealer__Vehicle_Inventory__c();
        dvi.dealer__VIN__c ='12';
        dvi.dealer__Engine_Description__c ='Test';
        dvi.Conversion_Cost__c=1; 
        dvi.dealer__Make__c ='Test';
        dvi.dealer__Model__c='test';
        dvi.dealer__Stock_Number__c='12';
        dvi.dealer__Year__c='2014';
        insert dvi;

        // BLL4a
            Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();    // BLL1a
            // Deal Integrity
            dealer__Deal__c deal = new dealer__Deal__c(
                Name = 'Test',
                dealer__Deal_Type__c = 'Retail Vehicle Sale',   // BLL1a
                RecordTypeId = RcdTypes.get('Retail').getRecordTypeId(), // BLL4a
                TaxCalcDT__c = DateTime.now(),  // BLL1a
                dealer__Auto_Insurance_Agent__c='Test',
                dealer__Deal_ID__c ='Test',
                dealer__Sales_Lead__c = dsp.id,
                dealer__Status__c ='Pending',
                dealer__Deal_Date__c =System.Today(),
                Proposed_Delivery_Date__c =System.Today(),
                dealer__Vehicle__c = veh.Id,
                dealer__Store_Location__c = FFAdata.DealerLocation.Id,
                Funding_option__c = 'Cash', // BLL3a
                dealer__DeliveryRepairOrder__c = null   // BLL2c
            );
            insert deal;
        // BLL4a - end
    
    }


    static testmethod Void UnitMilestone(){

        // BLL3 - removed creation of user & vehicle in favor of setup routine above
        
        FFAdata.refresh();  // BLL3a 
        System.runAs(FFAdata.TestUser) {    // BLL3c

            dealer__Deal__c deal = [select Id, Name from dealer__Deal__c limit 1];

            // DR1a
            PageReference searchPage = Page.VehicleSearchAdvanced;
            searchPage.getParameters().put('year', '2014');
            searchPage.getParameters().put('make', 'Test');
            searchPage.getParameters().put('model', 'test');
            searchPage.getParameters().put('debug', 'true');
            Test.setCurrentPage(searchPage);
            // / DR1a

            VehicleAdvancedSearch vas = new VehicleAdvancedSearch();

            //vas.getQueryString();
            vas.vehicleSearch();
            //vas.doSearch();
            vas.proposalId = deal.Id;   // BLL4a
            vas.returnToDeal();
            vas.getVehResult();
            vas.getYears();
            //vas.getMakes(); //BLL1d - no longer writing a getter for this, built once at class instantiation.
            vas.getModels(); 
            vas.getTrims();
            vas.getRecordTypes();
            vas.getInteriors(); 
            vas.getVehTypes(); 
            vas.getRegions();
            vas.getBranchLocations();
            vas.getStatusCodes();
            vas.getRampTypes();
            vas.getRampOperationItems();
            vas.getConversions();
            vas.getConversionModels();
            vas.getRampLocations();   
            vas.getnewUsedOthers(); 
            vas.getFloorTypes();
            vas.getFloorCuts();  

            // DR1b
            vas.reset();

            //searchPage.getParameters().put('year', '2014');
            //searchPage.getParameters().put('make', 'Test');
            searchPage.getParameters().put('division', 'test');

            //BLL2d vas.vehType = 'Used';
            vas.vehType.add('Used');    // BLL2a
            vas.recordType = 'Used';
            //BLL2d vas.newUsedOther = 'Used';
            vas.newUsedOther.add('Used');   // BLL2a
            vas.year.add('2014');
            vas.make.add('test');
            //vas.model ='test';
            //vas.minPrice = 0;
            //vas.maxPrice = 100000;
            vas.trim = 'test';
            vas.businessDivision = 'test';
            //vas.FeaturedVan = 'test';
            vas.FeaturedVan.add('test');
            //vas.extColor = 'test';
            //vas.intColor = 'test';
            //vas.interior = 'test';
            //vas.minOdometer = 0;
            //vas.maxOdometer = 0;
            //vas.convMfg = 'test';
            //vas.convModel = 'test';
            //vas.rampType = 'test';
            //vas.rampOperation = 'test';
            //vas.rampLoc = 'test';
            //vas.kneel = 'Yes';
            //vas.minConv = 'test';
            //vas.maxConv = 'test';
            //vas.minChassis = 'test';
            //vas.maxChassis = 'test';
            //vas.maxChassis = 'test';
            //BLL2d vas.status = 'test';
            //vas.status.add('test');   // BLL2a
            //vas.vehicleSearch();

            //BLL2d vas.status = 'All';
            //vas.status.clear();   // BLL2a 
            //vas.kneel = 'No';
            ////vas.vehicleSearch();

            //vas.stockNum = '12365';
            //vas.vehicleSearch();
            // /DR1b

            vas.status.add('test');
            vas.statusCheckSearch();
            vas.statusCheckErrorReportSearch();
            string vehResult = vas.GetJson;


        }
    }
    
    // BLL3a
    static testmethod Void searchall(){

        FFAdata.refresh(); 
        System.runAs(FFAdata.TestUser) {
            PageReference searchPage = Page.VehicleSearchAdvanced;
            searchPage.getParameters().put('searchall', 'Test');
            Test.setCurrentPage(searchPage);

            VehicleAdvancedSearch vas = new VehicleAdvancedSearch();

            vas.vehicleSearch();
        }
    }
    // BLL3a end    
    
}