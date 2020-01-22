/**
 * ItemsToApprove_CTLR_TEST
 * Tests: ItemsToApprove_CTLR
 * Date: Oct 14, 2016
 * Programmer: Bryan Leaman
 *
 *  2016-12-19  B. Leaman   BLL1 - adjustments for new validations enforced.
 *  2017-01-25  B. Leaman   BLL2 - switch to managed field for service mgr.
 *  2017-02-28  B. Leaman   BLL3 - changes to record types for commercial proposals.
 *	2019-01-24	B. Leaman	W-000565 BLL4 test new methods for lightning version of items to approve.
 * 
 */
@isTest
private class ItemsToApprove_CTLR_TEST {

    private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

    @testSetup
    static void setupFFA() {
        TestHelper_MW.createBaseFFAData(FFAdata);
        TestHelper_MW th = new TestHelper_MW();
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
        insert(new dealer__FixedOperationsSettings__c(dealer__Repair_Order_Index__c=1));
        insert(new RetailDefaults__c(ProposalNumber__c=7));  

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
            dealer__Stock_Number__c='TESTX',
            dealer__VIN__c='11234567890TUVWXY',
            dealer__Year__c='2020', dealer__Make__c='Toyota', dealer__Model__c='Future',
            dealer__Mileage__c=123000
        );
        insert(veh);

        dealer__Sales_Up__c  dsp = new dealer__Sales_Up__c(
            dealer__Lead_Date__c=System.Today(),
            dealer__Lead_Status__c='Pending',
            dealer__Lead_Type__c='List',
            dealer__Source__c ='Pride',
            Solution_Type__c ='Chassis/Conversion',
            dealer__Customer_Account__c =a.id,
            dealer__Trade_Year__c = '2016',
            dealer__Trade_Make__c = 'Toyota',
            dealer__First_Store_Visit_Date__c = DateTime.now(),     // BLL1a
            dealer__Trade_Model__c = 'Greatness'
        );
        insert dsp;
    
        Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();    // BLL1a
        dealer__Deal__c dd = new dealer__Deal__c(
            Name = 'Test',
            dealer__Deal_Type__c = 'Retail Vehicle Sale',   // BLL1a
            //BLL3d RecordTypeId = RcdTypes.get('Retail Vehicle Sale').getRecordTypeId(), // BLL1a
            RecordTypeId = RcdTypes.get('Retail').getRecordTypeId(), // BLL3a
            dealer__Auto_Insurance_Agent__c='Test',
            dealer__Deal_ID__c ='Test',
            dealer__Sales_Lead__c = dsp.id,
            dealer__Status__c ='Pending',
            dealer__Deal_Date__c =System.Today(),
            Proposed_Delivery_Date__c =System.Today(),
            dealer__Vehicle__c = veh.Id,
            dealer__Store_Location__c = FFAdata.DealerLocation.Id,
            TaxCalcDT__c = System.today(),
            Commission_Employee_1__c = UserInfo.getUserId(),
            dealer__Desk_Manager__c = UserInfo.getUserId(),
            dealer__F_I_Manager__c = UserInfo.getUserId(),
            Sales_Admin__c = UserInfo.getUserId(),
            dealer__Salesperson_1__c = UserInfo.getUserId(),
            //BLL2d Service_Manager__c = UserInfo.getUserId()
            dtmob__Service_Manager__c = UserInfo.getUserId()    // BLL2a
        );
        insert dd;

        System.runAs(FFAdata.TestUser) {
            Set<Id> ids = new Set<Id>();

            ids.add(dd.Id);
            
            Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitrequest();
            app.setObjectId(dd.Id);
            //Submit the approval request for the Campaign
            Approval.ProcessResult result = Approval.process(app);

            //ApprovalProcessUtil apu = new ApprovalProcessUtil(ids);
            //apu.getObjectApproverMap();
        }
        
    }

    // unitTest
    //---------------------------------------
    static testMethod void unitTest() {
        FFAdata.refresh(); 
                        
        Test.startTest();

        List<ProcessInstanceWorkItem> workitems = [
            select Id, OriginalActorId, ActorId
            from ProcessInstanceWorkItem
        ];

        System.assert(workitems.size()>0, 'Did not find any generated approvals');
        
        System.runAs(new User(Id=workitems[0].ActorId)) {
            Test.setCurrentPage(Page.ItemsToApprovePage); 
            ItemsToApprove_CTLR ctl = new ItemsToApprove_CTLR();
            ctl.manageAll();
            List<ItemsToApprove_CTLR.ApprovalItem> items = ctl.getApprovalItems();
            System.assert(items.size()>0, 'Did not find any items to approve');
        }

        Test.stopTest();
        
    }

	// testLightningMethods 
	static testMethod void testLightningMethods() {
		List<String> cols = ItemsToApprove_CTLR.getColumnLabels();
		List<ItemsToApprove_CTLR.ApprovalItem> items = ItemsToApprove_CTLR.getListOfItems(true);
	}

}