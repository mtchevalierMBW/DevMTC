/**
 * ServiceROTransports_Test
 * Tests: ServiceROTransports
 * Date: Jan 9, 2017
 * Programmer: Bryan Leaman
 *
 *  2017-05-04  B. Leaman   BLL1 - remove custom Dealer_Location_Users__c obj.
 *  2018-05-07  B. Leaman   BLL2 - need misc charge option of 'Freight' when adding parts; increase coverage;
 *	2019-12-30	B. Leaman	BLL3 - increase coverage
 *
Ledger entries for parts?
List<dealer__Parts_Ledger__c> fifoLedger = [Select Id, dealer__Quantity__c, dealer__Item_Value__c, dealer__Transaction_Note__c
                                                    from dealer__Parts_Ledger__c
                                                    where dealer__Parts_Sale_Line__c = NULL
                                                    and dealer__Part__c =:inv.Id
                                                    and dealer__Quantity__c > 0
                                                    order by dealer__Entry_Date__c ASC
                                                    limit :Integer.valueOf(qsold)];
 */
@isTest
private class ServiceROTransports_Test {

    private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

    @testSetup
    static void setupFFA() {
        TestHelper_MW.createBaseFFAData(FFAdata);
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
        dealer__FixedOperationsSettings__c fs = dealer__FixedOperationsSettings__c.getOrgDefaults();
        fs.dealer__Parts_Inventory_Control_Method__c = 'FIFO';
        fs.dealer__DO_NOT_Run_Managed_RO_Trigger__c = true;
        fs.dealer__Repair_Order_Index__c = 1;
        insert fs;
        dealer__Dealer_Location__c store = new dealer__Dealer_Location__c(
            Id=FFAData.DealerLocation.Id, Centralized_Purchasing_On_Off__c=true
        );
        update(store);
        
        // disable custom triggers
        List<MW_TriggerControls__c> turnoff = new List<MW_TriggerControls__c>();
        turnoff.add(new MW_TriggerControls__c(Name='AccountCounty', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='AccountLastService', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='AccountLastSale', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='AccountRcdType', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='AvataxDeal', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='AvataxRental', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='AvataxRepair', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='DealBuyerAccount', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='DealCustomFDF', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='DealLocationLatLng', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='DealerTradeIntegrity', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='DealerTradeStatusChange', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='DealerQuoteValidation', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='DealerStatusValidation', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='DefaultDimension1', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='LastAccountSale', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='LeadBusHrsElapsed', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='LeadClearLatLng', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='LeadClosestStore', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='LeadMWCommercial', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='LinkApptToSlop', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='LinkProposalToSlop', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='NoCommVehOnDeal', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='ProposalPostTax', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='ProposalPreventDelete', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='ProtectPostedDeal', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='ProtectPostedQuote', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='ProtectSROLocation', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='RentalPostTax', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='RepairOrderProtect', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='RepairPostTax', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='RestrictVehicleLocation', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='ReversingJournal', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='SalesUpUpdateContactInfo', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='Sales_Appt_First_Visit', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='SolutionOppDeals', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='Solution_Opp_Open_Chassis', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='SROTriggers', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='TechTimeCredit', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='TechTimeDate', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='uploadAccountHelper', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='uploadContactHelper', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='uploadPartKitHelper', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='uploadPartKitItemHelper', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='uploadTaskHelper', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='upload_Service_Vehicle_Helper', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='WonCommercialQuote', Enabled__c=false));
        insert(turnoff);

        TestHelper_MW th = new TestHelper_MW();

        // Account & vehicle to test with
        Account pa = th.getPersonAccount('1');
        dealer__Dealer_Location__c loc = th.getDealerLocation('1');
        //BLL1d insert(new Dealer_Location_Users__c(Dealer_Location__c=loc.Id, User__c=FFAdata.TestUser.Id, Technician__c=true));
        //BLL1d try {   // Should already be there, but just in case...
        insert(new dealer__Dealer_Location_User__c(dealer__Dealer_Location__c=loc.Id, dealer__User__c=FFAdata.TestUser.Id, dealer__Technician__c=true));
        //BLL1d } catch(Exception e) {}

        // Need service pmt types
        List<ServicePaymentType__c> spts = new List<ServicePaymentType__c>();
        spts.add(new ServicePaymentType__c(Name='IEN',Default_Labor_Rate__c=52,Description__c='Test IEN'));
        spts.add(new ServicePaymentType__c(Name='IEU',Default_Labor_Rate__c=52,Description__c='Test IEU'));
        spts.add(new ServicePaymentType__c(Name='IEO',Default_Labor_Rate__c=52,Description__c='Test IEO'));
        spts.add(new ServicePaymentType__c(Name='CR',Default_Labor_Rate__c=110,Description__c='Test CR'));
        insert(spts);

        insert(new dealer__StandardOpCode__c(
            Name='60CHECKIN',
            dealer__Company_Number__c=FFAdata.DealerLocation.dealer__Company_Number__c
        ));

        dealer__Vehicle_Inventory__c v = new dealer__Vehicle_Inventory__c(
            dealer__VIN__c = '11122233344455567', 
            dealer__Make__c = 'Toyota',
            dealer__Model__c = 'Future',
            dealer__Year__c = '2019',
            dealer__Stock_Number__c = '44455567'
        );
        insert(v);
        dealer__Service_Vehicle__c sv = [select Id from dealer__Service_Vehicle__c limit 1];

        // Need freight misc charge line

        // BLL2a
        insert(new Misc_Charge_Option__c(
            Name='Freight',
            Location__c=FFAData.DealerLocation.Id,  
            General_Ledger_Account__c=FFAData.glaMap.values()[0].Id
        ));
        // BLL2a end
                
        // Test RO
        dealer__Service_Repair_Order__c dsr = new dealer__Service_Repair_Order__c(
            dealer__Vehicle__c = sv.Id, 
            dealer__Vehicle_Inventory__c = v.Id,
            dealer__Mileage_In__c = 123,
            dealer__Customer__c = pa.Id,
            dealer__Company_Number__c = FFAData.DealerLocation.dealer__Company_Number__c,
            dealer__Company__c = FFAData.DealerLocation.Id
        );
        insert(dsr);

        insert(new dealer__Service_Job__c(
            dealer__Cause__c ='Test',
            dealer__Labor_Charges__c =12,
            dealer__Service_Repair_Order__c = dsr.id,
            dealer__Labor_Type__c='I',
            dealer__Labor_Rate__c='Test',
            dealer__Misc_Charges__c=11,
            dealer__Concern__c='test',
            dealer__CustomerConcern__c='test',
            dealer__Correction__c='test',
            dealer__Op_Code__c='60CHECKIN',
            dealer__Parts_Total__c=7,
            dealer__Service_Type__c='MR',
            dealer__Line_Number__c=1,
            dealer__Stat__c='Open',
            dealer__Technician__c=FFAdata.TestUser.Id,
            dealer__Book_Time__c=11,
            Payment_Method__c = spts[spts.size()-1].Id  // BLL2a
        ));                    

        List<dealer__Parts_Master__c> pms = new List<dealer__Parts_Master__c>();
        dealer__Parts_Master__c pm1 = new dealer__Parts_Master__c(
            Name = 'A12345-AC',
            dealer__Part_No__c = 'VMI:A12345-AC',
            dealer__Part_Description__c = 'Test Part System',
            dealer__Manufacturer__c = 'OT',
            dealer__Cost__c = 3.75,
            dealer__Retail_Price__c = 5.00
        );
        pms.add(pm1);
        dealer__Parts_Master__c pm2 = new dealer__Parts_Master__c(
            Name = 'B6789-Z',
            dealer__Part_No__c = 'VMI:B6789-Z',
            dealer__Part_Description__c = 'Test Part2 System',
            dealer__Manufacturer__c = 'OT',
            dealer__Cost__c = 13.75,
            dealer__Retail_Price__c = 25.00
        );
        pms.add(pm2);
        insert(pms);
     
        List<dealer__Parts_Inventory__c> pinvs = new List<dealer__Parts_Inventory__c>();
        dealer__Parts_Inventory__c pinv1 = new dealer__Parts_Inventory__c(
            //dealer__Stocking_Group__c = dpsg.id,
            dealer__Parts_Master__c = pm1.Id,
            dealer__Cost__c = 11,
            dealer__List__c = 1,
            dealer__Location__c = FFAdata.DealerLocation.Id,
            dealer__Entry_Date__c = Date.Today(),
            dealer__On_Hand__c   = 50,  // was 11
            dealer__Description__c = 'Test'
        );
        pinvs.add(pinv1);
        dealer__Parts_Inventory__c pinv2 = new dealer__Parts_Inventory__c(
            //dealer__Stocking_Group__c = dpsg.id,
            dealer__Parts_Master__c = pm2.Id,
            dealer__Cost__c = 11,
            dealer__List__c = 1,
            dealer__Location__c = FFAdata.DealerLocation.Id,
            dealer__Entry_Date__c = Date.Today(),
            dealer__On_Hand__c   = 5,   // was 11
            dealer__Description__c = 'Test'
        );
        pinvs.add(pinv2);
        insert(pinvs);
        
        List<dealer__Parts_Ledger__c> ledgers = new List<dealer__Parts_Ledger__c>();
        dealer__Parts_Ledger__c partLedger = new dealer__Parts_Ledger__c(
            dealer__Quantity__c = 1,
            dealer__Item_Value__c = 5.00,
            dealer__Transaction_Note__c = '',
            dealer__Part__c = pinv1.Id
        );
        ledgers.add(partLedger);
        for(Integer i=0; i<10; i++) {
            ledgers.add(new dealer__Parts_Ledger__c(
            dealer__Quantity__c = 1,
            dealer__Item_Value__c = 5.00,
            dealer__Transaction_Note__c = '',
            dealer__Part__c = pinv2.Id
            ));
        }
        insert(ledgers);        
    }

    // unitTest
    //---------------------------------------
    static testMethod void unitTest() {
        FFAdata.refresh(); 
                        
        System.runAs(FFAdata.TestUser) {
            TestHelper_MW th = new TestHelper_MW();

            dealer__Service_Job__c sjob = [select Id from dealer__Service_Job__c limit 1];
            dealer__Parts_Inventory__c pinv = [select Id from dealer__Parts_Inventory__c limit 1];
            dealer__Service_Repair_Order__c dsr = [select Id from dealer__Service_Repair_Order__c limit 1];

            Test.startTest();
            PageReference sro = Page.ServiceTRS;
            Test.setCurrentPage(sro);

            ApexPages.currentPage().getParameters().put('id', dsr.Id);
            ServiceROTransports st = new ServiceROTransports();

            //ApexPages.currentPage().getParameters().removeAll();
            //ApexPages.currentPage().getParameters().put('rid', sjob.Id);
            //ApexPages.currentPage().getParameters().put('QTY', '25');
            //ApexPages.currentPage().getParameters().put('PartInventoryId', pinv.Id);
            //ApexPages.currentPage().getParameters().put('SalePrice', '90.99');
            //ApexPages.currentPage().getParameters().put('Order', '0');
            //st.createPartLine();
            
            //dealer__Parts_Invoice_Line__c invL = [select Id from dealer__Parts_Invoice_Line__c where dealer__Service_Repair_Order__c =:dsr.Id limit 1];
            //ApexPages.currentPage().getParameters().put('Id', invL.Id);
            //ApexPages.currentPage().getParameters().put('QTY', '30');
            //ServiceROTransports stupdate = new ServiceROTransports();
            //stupdate.updatePartLine();
            
            // BLL2a
            String jobLineId = st.jobLineId;
            String ttId = st.ttId;
            String ttResult = st.ttResult;
            String updateResult = st.updateResult;
            String lookupPartResult = st.lookupPartResult;
            String masterId = st.masterId;
            String locationId = st.locationId;
            dealer__Dealer_Location__c location = st.location;
            String searchtxt = st.search;
            String responseString = st.responseString;
            
            st.LoadMiscChargeOptionsForLocId(null);
            st.LoadMiscChargeOptionsForLocId(FFAData.DealerLocation.id);
            st.LoadMiscChargeOptionsForLocAbbrev('');
            st.LoadMiscChargeOptionsForLocAbbrev(FFAData.DealerLocation.dealer__Company_Number__c);
            // BLL2a end
            
			// BLL3
			ServiceROTransports.cMiscOption cmo = new ServiceROTransports.cMiscOption(new Misc_Charge_Option__c(Name='Test', Quantity__c=1, Rate__c=50.0, General_Ledger_Account__c=null));
			dealer__Parts_Inventory__c pi = [select Id, dealer__Parts_Master__c from dealer__Parts_Inventory__c limit 1];
			st.masterId = pi.dealer__Parts_Master__c;
			st.getStoreInventory();
			// BLL3 end

            Test.stopTest();            
        }
    }

    
    // BLL2a
    static testMethod void testActions() {
        FFAdata.refresh(); 
                        
        System.runAs(FFAdata.TestUser) {
            TestHelper_MW th = new TestHelper_MW();

            dealer__Service_Job__c sjob = [select Id from dealer__Service_Job__c limit 1];
            dealer__Parts_Inventory__c pinv = [select Id from dealer__Parts_Inventory__c limit 1];
            dealer__Service_Repair_Order__c dsr = [select Id from dealer__Service_Repair_Order__c limit 1];

            Test.startTest();
            PageReference sro = Page.ServiceTRS;
            Test.setCurrentPage(sro);

            ApexPages.currentPage().getParameters().put('id', dsr.id);
            ApexPages.currentPage().getParameters().put('roid', dsr.id);
            ApexPages.currentPage().getParameters().put('roId', dsr.id);

            ApexPages.currentPage().getParameters().put('action', 'operations');
            ServiceROTransports st = new ServiceROTransports();

            ApexPages.currentPage().getParameters().put('action', 'payment_methods');
            st = new ServiceROTransports();

            ApexPages.currentPage().getParameters().put('action', 'techs');
            st = new ServiceROTransports();

            ApexPages.currentPage().getParameters().put('action', 'rolines');
            st = new ServiceROTransports();

            dealer__Service_Job__c dsj = [select Id from dealer__Service_Job__c limit 1];
            ApexPages.currentPage().getParameters().put('action', 'read_parts');
            ApexPages.currentPage().getParameters().put('lid', dsj.Id);
            st = new ServiceROTransports();

            ApexPages.currentPage().getParameters().put('action', 'search_parts');
            ApexPages.currentPage().getParameters().put('filter[filters][0][value]', 'oil');
            st = new ServiceROTransports();

            dealer__Parts_Master__c pm = [select Id from dealer__Parts_Master__c limit 1];
            ApexPages.currentPage().getParameters().put('action', 'global_inventory');
            ApexPages.currentPage().getParameters().put('mid', pm.Id);
            st = new ServiceROTransports();
            
        }
    }


    // repairorderCRUD
    //---------------------------------------
    //static testMethod void repairorderCRUD() {
    //  FFAdata.refresh(); 
    //
    //  System.runAs(FFAdata.TestUser) {
    //      TestHelper_MW th = new TestHelper_MW();
    //
    //      dealer__Service_Job__c sjob = [select Id from dealer__Service_Job__c limit 1];
    //      dealer__Parts_Inventory__c pinv = [select Id from dealer__Parts_Inventory__c limit 1];
    //      dealer__Service_Repair_Order__c dsr = [select Id from dealer__Service_Repair_Order__c limit 1];
    //
    //      PageReference sro = Page.ServiceTRS;
    //      Test.setCurrentPage(sro);
    //
    //      Test.startTest();
    //
    //       
    //      Test.stopTest();            
    //  }
    //}
    // BLL2a end


    // createPartLine
    //---------------------------------------
    static testMethod void createPartLine() {
        FFAdata.refresh(); 
                        
        System.runAs(FFAdata.TestUser) {
            TestHelper_MW th = new TestHelper_MW();

            dealer__Service_Job__c sjob = [select Id from dealer__Service_Job__c limit 1];
            dealer__Parts_Inventory__c pinv = [select Id from dealer__Parts_Inventory__c limit 1];
            dealer__Service_Repair_Order__c dsr = [select Id from dealer__Service_Repair_Order__c limit 1];

            PageReference sro = Page.ServiceTRS;
            Test.setCurrentPage(sro);

            ApexPages.currentPage().getParameters().put('id', dsr.Id);
            ServiceROTransports st = new ServiceROTransports();

            Test.startTest();
            ApexPages.currentPage().getParameters().clear();
            ApexPages.currentPage().getParameters().put('rid', sjob.Id);
            ApexPages.currentPage().getParameters().put('lid', sjob.Id);
            ApexPages.currentPage().getParameters().put('QTY', '25');
            ApexPages.currentPage().getParameters().put('PartInventoryId', pinv.Id);
            ApexPages.currentPage().getParameters().put('SalePrice', '90.99');
            ApexPages.currentPage().getParameters().put('Order', '0');
            st.createPartLine();

            
            // BLL2a
            ApexPages.currentPage().getParameters().put('action', 'create');
            st = new ServiceROTransports();
            st.saveAction();

            dealer__Parts_Invoice__c pi = [select Id from dealer__Parts_Invoice__c limit 1];
            ApexPages.currentPage().getParameters().put('roid', dsr.Id);
            ApexPages.currentPage().getParameters().put('Id', pi.Id);
            ApexPages.currentPage().getParameters().put('action', 'update');
            st = new ServiceROTransports();
            st.saveAction();

            ApexPages.currentPage().getParameters().put('action', 'delete');
            st = new ServiceROTransports();
            st.saveAction();
            // BLL2a end
            
            //dealer__Parts_Invoice_Line__c invL = [select Id from dealer__Parts_Invoice_Line__c where dealer__Service_Repair_Order__c =:dsr.Id limit 1];
            //ApexPages.currentPage().getParameters().put('Id', invL.Id);
            //ApexPages.currentPage().getParameters().put('QTY', '30');
            //ServiceROTransports stupdate = new ServiceROTransports();
            //stupdate.updatePartLine();
            
            Test.stopTest();            
        }
    }

    // saveActions1
    //---------------------------------------
    static testMethod void saveActions1() {
        FFAdata.refresh(); 
                        
        System.runAs(FFAdata.TestUser) {
            TestHelper_MW th = new TestHelper_MW();

            dealer__Service_Job__c sjob = [select Id from dealer__Service_Job__c limit 1];
            dealer__Parts_Master__c pm = [select Id from dealer__Parts_Master__c limit 1];
            dealer__Parts_Inventory__c pinv = [select Id from dealer__Parts_Inventory__c limit 1];
            dealer__Service_Repair_Order__c dsr = [select Id from dealer__Service_Repair_Order__c limit 1];

            PageReference sro = Page.ServiceTRS;
            Test.setCurrentPage(sro);

            ApexPages.currentPage().getParameters().put('id', dsr.Id);
            ServiceROTransports st = new ServiceROTransports();

            Test.startTest();

            ApexPages.currentPage().getParameters().put('action', 'part');
            ApexPages.currentPage().getParameters().put('mid', pm.Id);
            ApexPages.currentPage().getParameters().put('lid', FFAData.DealerLocation.Id);
            st.saveAction();


            // Create Parts Line
            ApexPages.currentPage().getParameters().put('action', 'create_parts_line');
            ApexPages.currentPage().getParameters().put('mid', pm.Id);
            ApexPages.currentPage().getParameters().put('QTY', '1');
            ApexPages.currentPage().getParameters().put('rid', sjob.Id);
            ApexPages.currentPage().getParameters().put('lid', sjob.Id);
            ApexPages.currentPage().getParameters().put('PartInventoryId', pinv.Id);
            ApexPages.currentPage().getParameters().put('SalePrice', '5.00');
            st.saveAction();

            st.jobLineId = sjob.Id;
            st.getReadParts();

            dealer__Parts_Invoice_Line__c plin = [select Id from dealer__Parts_Invoice_Line__c limit 1];
            ServicePaymentType__c spt = [select Id, Name from ServicePaymentType__c where Name='CR' limit 1];
            // Update Parts Line
            ApexPages.currentPage().getParameters().put('action', 'update_parts_Line');
            ApexPages.currentPage().getParameters().put('Id', plin.Id);
            ApexPages.currentPage().getParameters().put('mid', pm.Id);
            ApexPages.currentPage().getParameters().put('QTY', '2');
            ApexPages.currentPage().getParameters().put('rid', sjob.Id);
            ApexPages.currentPage().getParameters().put('PartInventoryId', pinv.Id);
            ApexPages.currentPage().getParameters().put('SalePrice', '5.50');
            ApexPages.currentPage().getParameters().put('Payment_Method__c',spt.Id);
            st.saveAction();
            
            st.partLine = plin.Id;
            st.getPartLine();

            Test.stopTest();
        }
    }


    // saveActions2
    //---------------------------------------
    static testMethod void saveActions2() {
        FFAdata.refresh(); 
                        
        System.runAs(FFAdata.TestUser) {
            TestHelper_MW th = new TestHelper_MW();

            dealer__Service_Job__c sjob = [select Id from dealer__Service_Job__c limit 1];
            dealer__Parts_Master__c pm = [select Id from dealer__Parts_Master__c limit 1];
            dealer__Parts_Inventory__c pinv = [select Id from dealer__Parts_Inventory__c limit 1];
            dealer__Service_Repair_Order__c dsr = [select Id from dealer__Service_Repair_Order__c limit 1];

            PageReference sro = Page.ServiceTRS;
            Test.setCurrentPage(sro);

            ApexPages.currentPage().getParameters().put('id', dsr.Id);
            ServiceROTransports st = new ServiceROTransports();

            ApexPages.currentPage().getParameters().put('action', 'part');
            ApexPages.currentPage().getParameters().put('mid', pm.Id);
            ApexPages.currentPage().getParameters().put('lid', FFAData.DealerLocation.Id);
            st.saveAction();


            // Create Parts Line
            ApexPages.currentPage().getParameters().put('action', 'create_parts_line');
            ApexPages.currentPage().getParameters().put('mid', pm.Id);
            ApexPages.currentPage().getParameters().put('QTY', '1');
            ApexPages.currentPage().getParameters().put('rid', sjob.Id);
            ApexPages.currentPage().getParameters().put('lid', sjob.Id);
            ApexPages.currentPage().getParameters().put('PartInventoryId', pinv.Id);
            ApexPages.currentPage().getParameters().put('SalePrice', '5.00');
            st.saveAction();

            Test.startTest();

            dealer__Parts_Invoice_Line__c plin = [select Id from dealer__Parts_Invoice_Line__c limit 1];

            // Delete Parts Line
            dealer__Parts_Invoice_Line__c pil = [select Id from dealer__Parts_Invoice_Line__c limit 1];
            ApexPages.currentPage().getParameters().put('action', 'delete_parts_Line');
            ApexPages.currentPage().getParameters().put('Id', plin.Id);
            st.saveAction();

            Test.stopTest();
        }
    }


    // saveActions3a
    //---------------------------------------
    static testMethod void saveActions3a() {
        FFAdata.refresh(); 
                        
        System.runAs(FFAdata.TestUser) {
            TestHelper_MW th = new TestHelper_MW();

            dealer__Service_Job__c sjob = [select Id from dealer__Service_Job__c limit 1];
            dealer__Service_Repair_Order__c dsr = [select Id from dealer__Service_Repair_Order__c limit 1];

            PageReference sro = Page.ServiceTRS;
            Test.setCurrentPage(sro);

            ApexPages.currentPage().getParameters().put('id', dsr.Id);
            ServiceROTransports st = new ServiceROTransports();

            Test.startTest();

            // Delete Job Line
            ApexPages.currentPage().getParameters().put('action', 'delete_line');
            ApexPages.currentPage().getParameters().put('Id', sjob.Id);
            st.saveAction();

            Test.stopTest();
        }
    }


    // saveActions3b
    //---------------------------------------
    static testMethod void saveActions3b() {
        FFAdata.refresh(); 
                        
        System.runAs(FFAdata.TestUser) {
            TestHelper_MW th = new TestHelper_MW();

            dealer__Service_Job__c sjob = [select Id from dealer__Service_Job__c limit 1];
            dealer__Service_Repair_Order__c dsr = [select Id from dealer__Service_Repair_Order__c limit 1];

            PageReference sro = Page.ServiceTRS;
            Test.setCurrentPage(sro);

            ApexPages.currentPage().getParameters().put('id', dsr.Id);
            ApexPages.currentPage().getParameters().put('roid', dsr.Id);
            ServiceROTransports st = new ServiceROTransports();

            Test.startTest();

            ServicePaymentType__c spt = [select Id, Name from ServicePaymentType__c where Name='CR' limit 1];
            // Update Job Line
            ApexPages.currentPage().getParameters().clear();
            ApexPages.currentPage().getParameters().put('action', 'create_line');
            // Causes field is not writable error: ApexPages.currentPage().getParameters().put('Id', sjob.Id);
            ApexPages.currentPage().getParameters().put('rid', dsr.Id);
            ApexPages.currentPage().getParameters().put('dealer__Repair_Order_Id__c', dsr.Id);
            ApexPages.currentPage().getParameters().put('dealer__CustomerConcern__c', 'test1');
            ApexPages.currentPage().getParameters().put('dealer__CauseExtended__c', 'test2');
            ApexPages.currentPage().getParameters().put('dealer__Correction__c', 'test3');
            ApexPages.currentPage().getParameters().put('dealer__Standard_Operation_Code__c', spt.Id);
            ApexPages.currentPage().getParameters().put('dealer__Stat__c', 'Open');
            ApexPages.currentPage().getParameters().put('dealer__Standard_Operation_Code__r.Name', spt.Name);
            ApexPages.currentPage().getParameters().put('Payment_Method__c',spt.Id);
            st.saveAction();

            Test.stopTest();
        }
    }

    // saveActions3c
    //---------------------------------------
    static testMethod void saveActions3c() {
        FFAdata.refresh(); 
                        
        System.runAs(FFAdata.TestUser) {
            TestHelper_MW th = new TestHelper_MW();

            dealer__Service_Job__c sjob = [select Id from dealer__Service_Job__c limit 1];
            dealer__Service_Repair_Order__c dsr = [select Id from dealer__Service_Repair_Order__c limit 1];

            PageReference sro = Page.ServiceTRS;
            Test.setCurrentPage(sro);

            ApexPages.currentPage().getParameters().put('id', dsr.Id);
            ApexPages.currentPage().getParameters().put('roid', dsr.Id);
            ServiceROTransports st = new ServiceROTransports();

            Test.startTest();

            ServicePaymentType__c spt = [select Id, Name from ServicePaymentType__c where Name='CR' limit 1];
            // Update Job Line
            ApexPages.currentPage().getParameters().put('action', 'update_line');
            ApexPages.currentPage().getParameters().put('Id', sjob.Id);
            ApexPages.currentPage().getParameters().put('dealer__Repair_Order_Id__c', dsr.Id);
            ApexPages.currentPage().getParameters().put('dealer__CustomerConcern__c', 'test1');
            ApexPages.currentPage().getParameters().put('dealer__CauseExtended__c', 'test2');
            ApexPages.currentPage().getParameters().put('dealer__Correction__c', 'test3');
            ApexPages.currentPage().getParameters().put('dealer__Standard_Operation_Code__c', spt.Id);
            ApexPages.currentPage().getParameters().put('dealer__Stat__c', 'Open');
            ApexPages.currentPage().getParameters().put('dealer__Standard_Operation_Code__r.Name', spt.Name);
            ApexPages.currentPage().getParameters().put('Payment_Method__c',spt.Id);
            st.saveAction();

            Test.stopTest();
        }
    }

    // saveActions4
    //---------------------------------------
    static testMethod void saveActions4() {
        FFAdata.refresh(); 
                        
        System.runAs(FFAdata.TestUser) {
            TestHelper_MW th = new TestHelper_MW();

            dealer__Service_Job__c sjob = [select Id from dealer__Service_Job__c limit 1];
            dealer__Parts_Master__c pm = [select Id from dealer__Parts_Master__c limit 1];
            dealer__Parts_Inventory__c pinv = [select Id from dealer__Parts_Inventory__c limit 1];
            dealer__Service_Repair_Order__c dsr = [select Id from dealer__Service_Repair_Order__c limit 1];

            PageReference sro = Page.ServiceTRS;
            Test.setCurrentPage(sro);

            ApexPages.currentPage().getParameters().put('id', dsr.Id);
            ServiceROTransports st = new ServiceROTransports();

            Test.startTest();

            // Create tech time
            ApexPages.currentPage().getParameters().put('action', 'create_tech_time');
            ApexPages.currentPage().getParameters().put('lid', sjob.Id);
            ApexPages.currentPage().getParameters().put('dealer__Technician__c[Id]', UserInfo.getUserId());
            ApexPages.currentPage().getParameters().put('dealer__Actual_Time_Entry__c', '1');
            ApexPages.currentPage().getParameters().put('Labor_Total__c', '52');
            ApexPages.currentPage().getParameters().put('dealer__Date__c', DateTime.now().format('MM/dd/YYYY'));
            st.saveAction();

            dealer__Technician_Job_Time__c tt = [select Id from dealer__Technician_Job_Time__c where dealer__Service_Job_Line__c=:sjob.Id limit 1];
            st.ttId = tt.Id;
            st.getTechRow();
            st.getTechTimes();

            // Update tech time
            ApexPages.currentPage().getParameters().clear();
            ApexPages.currentPage().getParameters().put('action', 'update_tech_time');
            ApexPages.currentPage().getParameters().put('dealer__Technician__c', UserInfo.getUserId());
            ApexPages.currentPage().getParameters().put('Id', tt.Id);
            ApexPages.currentPage().getParameters().put('dealer__Actual_Time_Entry__c', '1');
            ApexPages.currentPage().getParameters().put('dealer__Date__c', DateTime.now().format('MM/dd/YYYY'));
            st.saveAction();

            Test.stopTest();

        }
    }


    // saveActions5
    //---------------------------------------
    static testMethod void saveActions5() {
        FFAdata.refresh(); 
                        
        System.runAs(FFAdata.TestUser) {
            TestHelper_MW th = new TestHelper_MW();

            dealer__Service_Job__c sjob = [select Id from dealer__Service_Job__c limit 1];
            dealer__Parts_Master__c pm = [select Id from dealer__Parts_Master__c limit 1];
            dealer__Parts_Inventory__c pinv = [select Id from dealer__Parts_Inventory__c limit 1];
            dealer__Service_Repair_Order__c dsr = [select Id from dealer__Service_Repair_Order__c limit 1];

            PageReference sro = Page.ServiceTRS;
            Test.setCurrentPage(sro);

            ApexPages.currentPage().getParameters().put('id', dsr.Id);
            ServiceROTransports st = new ServiceROTransports();

            Test.startTest();

            // Create tech time
            ApexPages.currentPage().getParameters().put('action', 'create_tech_time');
            ApexPages.currentPage().getParameters().put('lid', sjob.Id);
            ApexPages.currentPage().getParameters().put('dealer__Technician__c[Id]', UserInfo.getUserId());
            ApexPages.currentPage().getParameters().put('dealer__Actual_Time_Entry__c', '1');
            ApexPages.currentPage().getParameters().put('Labor_Total__c', '52');
            ApexPages.currentPage().getParameters().put('dealer__Date__c', DateTime.now().format('MM/dd/YYYY'));
            st.saveAction();

            dealer__Technician_Job_Time__c tt = [select Id from dealer__Technician_Job_Time__c where dealer__Service_Job_Line__c=:sjob.Id limit 1];

            // Delete tech time
            ApexPages.currentPage().getParameters().put('action', 'delete_tech_time');
            ApexPages.currentPage().getParameters().put('Id', tt.Id);
            st.saveAction();

            Test.stopTest();

        }
    }


    // saveActions6 - misc charges
    //---------------------------------------
    static testMethod void saveActions6() {
        FFAdata.refresh(); 
                        
        System.runAs(FFAdata.TestUser) {
            TestHelper_MW th = new TestHelper_MW();

            dealer__Service_Job__c sjob = [select Id from dealer__Service_Job__c limit 1];
            dealer__Parts_Master__c pm = [select Id from dealer__Parts_Master__c limit 1];
            dealer__Parts_Inventory__c pinv = [select Id from dealer__Parts_Inventory__c limit 1];
            dealer__Service_Repair_Order__c dsr = [select Id from dealer__Service_Repair_Order__c limit 1];

            PageReference sro = Page.ServiceTRS;
            Test.setCurrentPage(sro);

            ApexPages.currentPage().getParameters().put('id', dsr.Id);
            ServiceROTransports st = new ServiceROTransports();

            Test.startTest();

            // Create misc charge
            ApexPages.currentPage().getParameters().put('action', 'create_misc');
            ApexPages.currentPage().getParameters().put('lid', sjob.Id);
            ApexPages.currentPage().getParameters().put('rid', dsr.Id);
            ApexPages.currentPage().getParameters().put('Type__c', 'Freight');
            ApexPages.currentPage().getParameters().put('Quantity__c', '1');
            ApexPages.currentPage().getParameters().put('Amount__c', '3.50');
            ApexPages.currentPage().getParameters().put('General_Ledger_Account__c', FFAData.glaMap.values()[0].Id);
            st.saveAction();

            ServiceMiscCharges__c misc = [select Id from ServiceMiscCharges__c limit 1];

            // Update misc charge
            ApexPages.currentPage().getParameters().put('action', 'update_misc');
            ApexPages.currentPage().getParameters().put('Id', misc.Id);
            ApexPages.currentPage().getParameters().put('lid', sjob.Id);
            ApexPages.currentPage().getParameters().put('Service_Job_Line__c', sjob.Id);
            ApexPages.currentPage().getParameters().put('newLineId', sjob.Id);
            ApexPages.currentPage().getParameters().put('rid', dsr.Id);
            ApexPages.currentPage().getParameters().put('Quantity__c', '1');
            ApexPages.currentPage().getParameters().put('Amount__c', '3.75');
            st.saveAction();

            // Delete misc charge
            ApexPages.currentPage().getParameters().put('action', 'delete_misc');
            ApexPages.currentPage().getParameters().put('Id', misc.Id);
            ApexPages.currentPage().getParameters().put('rid', dsr.Id);
            ApexPages.currentPage().getParameters().put('lid', sjob.Id);
            st.saveAction();

            Test.stopTest();
        }
    }


    // miscGetters
    //---------------------------------------
    static testMethod void miscGetters() {
        FFAdata.refresh(); 
                        
        System.runAs(FFAdata.TestUser) {
            TestHelper_MW th = new TestHelper_MW();

            dealer__Service_Job__c sjob = [select Id, dealer__Labor_Type__c from dealer__Service_Job__c limit 1];
            dealer__Parts_Master__c pm = [
                select Id, Name, dealer__Part_Description__c, dealer__Manufacturer__c
                from dealer__Parts_Master__c
                limit 1
            ];
            dealer__Parts_Inventory__c pinv = [select Id from dealer__Parts_Inventory__c limit 1];
            dealer__Service_Repair_Order__c dsr = [select Id from dealer__Service_Repair_Order__c limit 1];

            PageReference sro = Page.ServiceTRS;
            Test.setCurrentPage(sro);
            ApexPages.currentPage().getParameters().put('id', dsr.Id);
            ApexPages.currentPage().getParameters().put('rid', dsr.Id);
            ApexPages.currentPage().getParameters().put('coNum', FFAData.DealerLocation.dealer__Company_Number__c);
            ServiceROTransports st = new ServiceROTransports();

            Test.startTest();
            
            st.rid = dsr.id;
            st.getOperationCodes();
            
            st.getPaymentMethods();
            st.roId = dsr.Id;
            st.getROLines();
            st.getTechnicians();
            st.getStatusCodes();
            st.getMiscTypes();
            st.search = 'test';
            st.getSearchParts();

            ServiceROTransports.PartSearch ps = new ServiceROTransports.PartSearch(pm);
            String pn = ps.PartName;
            String pd = ps.PartDescription;
            Id pmid = ps.PartMasterId;
            String mfg = ps.PartMFG;
            String sd = ps.search_display;
            ServiceROTransports.StoreInventory si = new ServiceROTransports.StoreInventory('TestStore', 5);
            String str = si.store;
            Integer qty = si.qty;
            Test.stopTest();
        }
    }

    // laborRateRecalc
    //---------------------------------------
    static testMethod void laborRateRecalc() {
        FFAdata.refresh(); 
                        
        System.runAs(FFAdata.TestUser) {
            TestHelper_MW th = new TestHelper_MW();

            dealer__Service_Job__c sjob = [select Id, dealer__Labor_Type__c from dealer__Service_Job__c limit 1];
            dealer__Parts_Master__c pm = [
                select Id, Name, dealer__Part_Description__c, dealer__Manufacturer__c
                from dealer__Parts_Master__c
                limit 1
            ];
            dealer__Parts_Inventory__c pinv = [select Id from dealer__Parts_Inventory__c limit 1];
            dealer__Service_Repair_Order__c dsr = [select Id from dealer__Service_Repair_Order__c limit 1];

            PageReference sro = Page.ServiceTRS;
            Test.setCurrentPage(sro);
            ApexPages.currentPage().getParameters().put('id', dsr.Id);
            ApexPages.currentPage().getParameters().put('rid', dsr.Id);
            ApexPages.currentPage().getParameters().put('coNum', FFAData.DealerLocation.dealer__Company_Number__c);
            System.debug('new ServiceROTransports');
            ServiceROTransports st = new ServiceROTransports();

            // Create tech time
            //ApexPages.currentPage().getParameters().put('action', 'create_tech_time');
            //ApexPages.currentPage().getParameters().put('lid', sjob.Id);
            //ApexPages.currentPage().getParameters().put('dealer__Technician__c[Id]', UserInfo.getUserId());
            //ApexPages.currentPage().getParameters().put('dealer__Actual_Time_Entry__c', '1');
            //ApexPages.currentPage().getParameters().put('Labor_Total__c', '52');
            //ApexPages.currentPage().getParameters().put('dealer__Date__c', DateTime.now().format('MM/dd/YYYY'));
            System.debug('create_tech_time');
            //st.saveAction();
            insert new dealer__Technician_Job_Time__c(
                dealer__Service_Job_Line__c = sjob.Id,
                dealer__Technician__c = UserInfo.getUserId(),
                dealer__Actual_Time_Entry__c = 1.0,
                Labor_Total__c = 52.0,
                dealer__Date__c = Date.today()
            );

            Test.startTest();
            
            st.rid = dsr.id;
            ServicePaymentType__c spt = [select Id, Name from ServicePaymentType__c where Name='CR' limit 1];
            ApexPages.currentPage().getParameters().put('Payment_Method__c', spt.Id);
            ApexPages.currentPage().getParameters().put('dealer__CustomerConcern__c', 'test1');
            ApexPages.currentPage().getParameters().put('dealer__CauseExtended__c', 'test2');
            ApexPages.currentPage().getParameters().put('dealer__Correction__c', 'test3');
            System.debug('laborRateRecalculation');
            st.laborRateRecalculation(sjob.Id, sjob);
            System.debug('laborRateRecalculation end');

            Test.stopTest();
        }
    }

}