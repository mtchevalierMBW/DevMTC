/**
CentralizedParts_TC
Tests: CentralizedParts, CentralizedPartsStoreInventory, CentralizedPartsAPI

Modifications:
2018-11-23  B. Leaman   W-000492 BLL1 - add test classes for CentralizedPartsStoreInvenotry
2019-11-22	B. Leaman	W-000794 BLL2 - test Centralized Parts API methods
**/
@isTest
private class CentralizedParts_TC {

    private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); // BLL1

    // BLL1
    @testSetup
    static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
        TestHelper_MW th = new TestHelper_MW();
		dealer.TestClassUtil tc = new dealer.TestClassUtil();
		tc.insertDMSSettings();

		// BLL2
		update(new dealer__Dealer_Location__c(
			Id=FFAdata.DealerLocation.Id,
			Centralized_Purchasing_On_Off__c=true
		));

		// get labor types for service payment method creation
        DescribeFieldResult lbrtype = dealer__Service_Estimate_Line__c.dealer__Labor_Type__c.getDescribe();
		List<Schema.PicklistEntry> ltplvs = lbrtype.getPicklistValues();
		String customer_labor_type;
		String warranty_labor_type;
		for(Integer i=0; i<ltplvs.size(); i++) {
			if (ltplvs[i].getValue().length()>1) {
				if (String.isBlank(customer_labor_type)) customer_labor_type = ltplvs[i].getValue();
				else if (String.isBlank(warranty_labor_type)) warranty_labor_type = ltplvs[i].getValue();
			}
		}
        // Service Payment
        List<ServicePaymentType__c> spts = new List<ServicePaymentType__c>();    
        spts.add(new ServicePaymentType__c (
			Name = customer_labor_type,
			Payment_Type__c = 'C',
			Default_Labor_Rate__c = 70
		));
        spts.add(new ServicePaymentType__c (
			Name = warranty_labor_type,
			Payment_Type__c = 'W',   
			Default_Labor_Rate__c = 90
		));
        insert spts;
		// BLL2 end
    }
    // BLL1 end

    static testmethod void testCPT() {

        TestHelper_MW th = new TestHelper_MW();

        dealer__Dealer_Location__c loc = th.getDealerLocation('1');

        // Check to see if a Queue exists
        CentralizedParts cpt_no_queue = new CentralizedParts();

        // Create the CPT Queue
        Group grp = new Group(Type = 'Queue', Name = 'CPT Group');
        insert grp;

        //QueueSObject q = new QueueSObject(QueueId=grp.Id, SobjectType='dealer__Parts_Order__c');
        //insert q;

        // Begin Constructor Tests
        CentralizedParts cpt = new CentralizedParts();
        Id aid = cpt.acceptedId;
        cpt.refresh();
        String uSettings = cpt.getuserSettings();

        CentralizedParts.saveUserSelection(uSettings);


        // Perform SOQL methods
        cpt.getMasterMFG();
        cpt.getLocations();

        cpt.getReceived();
        cpt.getInProcessOrders();
        cpt.getIncomplete();
        cpt.getOpenOrders();
        cpt.getMyOrders();

        // Test When Settings Exist
        // 
                // Insert User Settings
        insert new CentralizedPartsSettings__c(User__c=UserInfo.getUserId(), Settings__c='{  "urgencies" : [ "Ground", "3 Day", "2 Day", "Overnight", "Saturday", "Saturday Overnight", "N/A", "Drop-Ship", "Vendor", "Transfer" ],  "manufacturers" : [ "Other", "AMF", "ADC", "ADAPT", "BRA", "MPD", "MPS", "QST", "SL", "VMI" ],  "stores" : [],  "tab" : "open"}');
        
        CentralizedParts cpt_Repeat = new CentralizedParts();

    }

    // BLL1
    static testmethod void testCentralizedPartsInvView() {

    	FFAdata.refresh();
        TestHelper_MW th = new TestHelper_MW();

        dealer__Parts_Master__c pm = new dealer__Parts_Master__c(
            Name='TestPart',
            dealer__Retail_Price__c = 10.0,
            dealer__Manufacturer__c = 'TST'
        );
        insert(pm); 
        dealer__Parts_Inventory__c pi = new dealer__parts_Inventory__c(
            dealer__Parts_Master__c = pm.Id,
            dealer__Location__c = FFAdata.DealerLocation.Id,
            dealer__Part_No__c = 'TestPart',
            dealer__Cost__c = 5.0,
            dealer__List__c = 10.0,
            dealer__MFG__c = 'TST'
        );
        insert(pi);

        dealer__Stock_Order__c sord = new dealer__Stock_Order__c(
            Name='CPT#'+'Test', //dsr.dealer__RO_Number__c,
            dealer__Status__c='Incomplete',
            dealer__Company__c=FFAdata.DealerLocation.Id,
            //dealer__Service_Repair_Order__c=dsr.Id,
            dealer__Date_Ordered__c=Date.Today(),
            dealer__Order_Type__c='Special Order'
            //OwnerId=q.QueueId
        );
        insert(sord);

        dealer__Parts_Order__c pord = new dealer__Parts_Order__c(
            dealer__Order_Date__c = Date.today(),
            dealer__Order__c = sord.Id,
            dealer__Parts_Inventory__c = pi.Id,
            dealer__Parts_Master__c = pm.Id,
            dealer__Quantity_Ordered__c = 1
            //dealer__Parts_Line__c=partsline.Id
            //OwnerId=q.QueueId
		);
        insert(pord);

        Test.startTest();
        PageReference pgRef = Page.CentralizedPartsStoreInventoryView; 
		Test.setCurrentPage(pgRef); //Set the page for Test Method
		ApexPages.currentPage().getParameters().put('id', sord.id);
		ApexPages.StandardController sc = new ApexPages.StandardController(new dealer__Stock_Order__c(Id=sord.Id));
		CentralizedPartsStoreInventory cpsi = new CentralizedPartsStoreInventory(sc);
        CentralizedPartsStoreInventory.PartOrderWrapper pow = new CentralizedPartsStoreInventory.PartOrderWrapper(pord, pm);
        Test.stopTest();

    }
    // BLL1 end

	// BLL2
	static testmethod void test_cpAPI() {
		FFAdata.refresh();
		System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();
			dealer__Service_Estimate_SubLine__c subline = createEstimateAndPartSubline();
			dealer__Parts_Inventory__c p = [select Id from dealer__Parts_Inventory__c limit 1];
			Test.startTest();

			// create RO and insert part line from estimate
			Account a = th.getPersonAccount('1');
        	dealer__Service_Repair_Order__c dsr = new dealer__Service_Repair_Order__c(
        		dealer__Customer__c =a.id,
        		dealer__Mileage_In__c =12,
        		dealer__RO_Number__c ='11',
        		//dealer__VIN__c = dsv.dealer__VIN__c,
        		//dealer__Vehicle__c = dsv.Id,
				dealer__Company__c = FFAdata.DealerLocation.Id
			);
        	insert dsr;
        
        	dealer__Service_Job__c dsj = new dealer__Service_Job__c(
				dealer__Cause__c ='Test',
				dealer__Labor_Charges__c =12,
				dealer__Service_Repair_Order__c =dsr.id,
				dealer__Labor_Type__c = 'C'
			);
        	insert dsj;

			dealer__Parts_Invoice__c pi = new dealer__Parts_Invoice__c(
				dealer__Customer__c = a.Id,
				dealer__Customer_Contact__c = a.PersonContactId,
            	Name = 'Test Invoice',
				dealer__Company_Number__c = FFAdata.DealerLocation.dealer__Company_Number__c,
				dealer__Location__c = FFAdata.DealerLocation.Id,
            	dealer__Deposit__c = 100,
            	dealer__Invoice_Number__c = 'inv1234'       
			);
			insert(pi);
			List<dealer__Parts_Invoice_Line__c> pils = new List<dealer__Parts_Invoice_Line__c>();
			dealer__Parts_Invoice_Line__c pil = new dealer__Parts_Invoice_Line__c(
        		Name = 'Test Part Invoice Line',
        		dealer__Part_Number__c = 'A88999',
				dealer__Part__c = p.Id,
        		dealer__Quantity_Sold__c = 1,
        		dealer__Cost__c = 1000,
        		dealer__Price__c = 1001,
				dealer__Job_Line__c = dsj.Id,
				dealer__Service_Repair_Order__c = dsr.Id,
				dealer__Parts_Invoice__c = pi.Id,
				dealer__Sold_Via__c = 'Estimate',
				dealer__Quantity_Ordered__c = 1,
				dealer__Service_Estimate_Subline_Creator__c = subline.Id
			);
			pils.add(pil);
			insert(pil);
			CentralizedPartsAPI.CopyOrderUrgencyFromEstimate(pils);

			Test.stopTest();
		}
	}

    public static dealer__Service_Estimate_SubLine__c createEstimateAndPartSubline() {
		Id partId = createPart();
        ServicePaymentType__c cpt = [select Id, Name from ServicePaymentType__c where Payment_Type__c = 'C' limit 1];
        //ServicePaymentType__c wpt = [select Id, Name from ServicePaymentType__c where Payment_Type__c = 'W' limit 1];
        
        // Create a Parts Master Entry
        dealer__Parts_Master__c pm = new dealer__Parts_Master__c();
        pm.Name = 'FL1A__TEST_PART';
        pm.dealer__Retail_Price__c = 99.99;
        pm.dealer__Cost__c = 115;
        insert pm;        
                
        dealer__Parts_Inventory__c pi = new dealer__Parts_Inventory__c(
            Name='ToBeChanged',
            dealer__Bin__c='A123',
            dealer__Entry_Date__c=Date.today(),
            dealer__Cost__c=Decimal.valueOf('123.45'),
            dealer__List__c=Decimal.valueOf('224.95'),
            dealer__Part_No__c='A88999',
            dealer__Source__c='Temp',
            dealer__Parts_Master__c = pm.Id,
            dealer__Location__c=FFAdata.DealerLocation.Id,
            dealer__On_Hand__c=2,
            dealer__On_Order__c  = 100
        );
        
        insert pi;    
        
        //Service Estimate
        dealer__Service_Estimate__c se = new dealer__Service_Estimate__c(
        	dealer__Cosmetic_Notes__c='Repair / Repaint Bumper'
        );
        insert se;
        
        //Service Estimate Line
        dealer__Service_Estimate_Line__c sel = new dealer__Service_Estimate_Line__c(
            		dealer__Service_Estimate__c=se.Id,
                	dealer__Labor_Type__c = cpt.Name);	
        insert sel;

        // Sub Line
        dealer__Service_Estimate_SubLine__c newSubLine = new dealer__Service_Estimate_SubLine__c(
                    dealer__Line_Type__c='Parts',
            		dealer__Parts_Master__c = pm.id,
            		dealer__Part_Price__c = 6,
                    dealer__Service_Estimate_Line__c=sel.Id);       
        insert newSubLine;    
		return newSubLine;
	}

    public static Id createPart() {
        // Create a Parts Master Entry
        dealer__Parts_Master__c pm = new dealer__Parts_Master__c(
        	Name = 'FL1A__TEST_PART',
        	dealer__Retail_Price__c = 99.99,
        	dealer__Manufacturer__c = 'FD'
		);
        insert pm;      

        dealer__Parts_Inventory__c inventory = new dealer__Parts_Inventory__c(
        	dealer__Part_No__c = '9963777777',
        	dealer__Cost__c = 70,
        	dealer__List__c = 70,
        	dealer__MFG__c = 'MFG',
        	dealer__Parts_Master__c = pm.Id,
			dealer__Location__c = FFAdata.DealerLocation.Id
		);
        insert inventory; 

        return inventory.Id;       
    }
	// BLL2 end

}