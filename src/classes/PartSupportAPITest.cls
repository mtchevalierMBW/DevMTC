/**
Modifications:
*   2018-11-12  B. Leaman   W-000485    Improve code coverage. 
*	2019-10-15	B. Leaman	W-000730 BLL2 Don't require SeeAllData
**/

@isTest
private class PartSupportAPITest {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
		dealer__FixedOperationsSettings__c fixedOpsSettings = new dealer__FixedOperationsSettings__c(
			dealer__Repair_Order_Index__c=1,
			dealer__PurchaseOrderPartsReceiptAddress__c='blackhole@example.com'
	    );
	    insert(fixedOpsSettings); 


		TestHelper_MW th = new TestHelper_MW();
		Account p = th.getPersonAccount('1');
		Account v = th.getVendorAccount('2');

        // Create a Parts Master Entry
        List<dealer__Parts_Master__c> pms = new List<dealer__Parts_Master__c>();
		pms.add(new dealer__Parts_Master__c(
        	Name = 'TEST_PART_1',
        	dealer__Retail_Price__c = 9.99,
			dealer__Cost__c = 7.99,
        	dealer__Manufacturer__c = 'MFG'
		));
        pms.add(new dealer__Parts_Master__c(
        	Name = 'TEST_PART_2',
        	dealer__Retail_Price__c = 8.99,
			dealer__Cost__c = 6.99,
        	dealer__Manufacturer__c = 'MFG'
		));
        insert pms;   
        List<dealer__Parts_Inventory__c> pis = new List<dealer__Parts_Inventory__c>();
		pis.add(new dealer__Parts_Inventory__c(
        	dealer__Part_No__c = '9963666666',
        	dealer__Cost__c = 60,
        	dealer__List__c = 60,
        	dealer__MFG__c = 'MFG',
        	dealer__Parts_Master__c = pms[0].Id,
			dealer__On_Hand__c = 1,
			dealer__Location__c = FFAdata.DealerLocation.Id,
			dealer__Last_Sale_Date__c = Date.today()
		));
        pis.add(new dealer__Parts_Inventory__c(
        	dealer__Part_No__c = '9963777777',
        	dealer__Cost__c = 70,
        	dealer__List__c = 70,
        	dealer__MFG__c = 'MFG',
			dealer__On_Hand__c = 2,
        	dealer__Parts_Master__c = pms[1].Id,
			dealer__Location__c = FFAdata.DealerLocation.Id,
			dealer__Last_Sale_Date__c = Date.today()
		));
        insert pis; 
		pis = [
			select Id, dealer__Part_No__c, dealer__Part_Number__c, 
				dealer__Cost__c, dealer__List__c, dealer__Location__c, 
				dealer__MFG__c, dealer__On_Hand__c, dealer__Parts_Master__c,
				dealer__Last_Sale_Date__c
			from dealer__Parts_Inventory__c
		];

		dealer__Service_Repair_Order__c sro = new dealer__Service_Repair_Order__c(
			dealer__Customer__c =p.id,
			dealer__Mileage_In__c =12,
			dealer__RO_Number__c ='11',
			//dealer__VIN__c = dsv.dealer__VIN__c,
			//dealer__Vehicle__c = dsv.Id,
			dealer__Company__c = FFAdata.DealerLocation.Id
		);
        insert(sro);
		sro = [
			select Id, Name, dealer__Customer__c, dealer__Mileage_In__c, dealer__RO_Number__c
			from dealer__Service_Repair_Order__c
			where Id=:sro.Id limit 1
		];
		dealer__Service_Job__c dsj = new dealer__Service_Job__c(
			dealer__Cause__c ='Test',
			dealer__Labor_Charges__c =12,
			dealer__Service_Repair_Order__c =sro.id,
			dealer__Labor_Type__c = 'C'
		);
		insert(dsj);

		List<dealer__Purchase_Order__c> pos = new List<dealer__Purchase_Order__c>();
		pos.add(new dealer__Purchase_Order__c(
        	dealer__Vendor__c = v.Id,
			dealer__Accepted_DateTime__c = Date.today(),
			dealer__Accepted_By__c = UserInfo.getUserId(),
        	dealer__Vendor_Email__c = 'test@blackhole.org',
        	RecordTypeId=Schema.SObjectType.dealer__Purchase_Order__c.getRecordTypeInfosByName().get('Parts Purchase').getRecordTypeId(),
			dealer__Company__c = FFAdata.DealerLocation.Id
		));
		pos.add(new dealer__Purchase_Order__c(
        	dealer__Vendor__c = v.Id,
        	dealer__Vendor_Email__c = 'test@blackhole.org',
        	RecordTypeId=Schema.SObjectType.dealer__Purchase_Order__c.getRecordTypeInfosByName().get('Parts Purchase').getRecordTypeId(),
			dealer__Company__c = FFAdata.DealerLocation.Id
		));
		insert(pos);
		List<dealer__Purchase_Order_Line__c> polines = new List<dealer__Purchase_Order_Line__c>();
		polines.add(new dealer__Purchase_Order_Line__c(
        	dealer__Purchase_Order__c = pos[0].id,
        	dealer__Part__c = pis[0].Id,
        	dealer__Part_Quantity__c = 2,
			dealer__Part_Quantity_Received__c = 2,
			dealer__Amount__c = 18.98
		));
		polines.add(new dealer__Purchase_Order_Line__c(
        	dealer__Purchase_Order__c = pos[1].id,
        	dealer__Part__c = pis[0].Id,
        	dealer__Part_Quantity__c = 5,
			dealer__Amount__c = 49.95
		));
		polines.add(new dealer__Purchase_Order_Line__c(
        	dealer__Purchase_Order__c = pos[1].id,
        	dealer__Part__c = pis[1].Id,
        	dealer__Part_Quantity__c = 1,
			dealer__Amount__c = 8.90
		));
		insert(polines);

        dealer__Parts_Invoice__c dpinv = new dealer__Parts_Invoice__c(
			dealer__Customer_Contact__c = p.PersonContactId,
			dealer__Counterman__c=userinfo.getuserid(),
			dealer__Invoice_Number__c ='1',
			dealer__Location__c = FFAdata.DealerLocation.Id
		);
        insert(dpinv);
        List<dealer__Parts_Invoice_Line__c> dpls = new List<dealer__Parts_Invoice_Line__c>();
		dpls.add(new dealer__Parts_Invoice_Line__c(
			dealer__Parts_Invoice__c=dpinv.id,
			Name='test',
			dealer__Core__c=12,
			dealer__Cost__c=12,
			dealer__Price__c=12,
			dealer__Part_Number__c=pis[0].dealer__Part_Number__c,
			dealer__Purchase_Order_Line__c = polines[0].Id,
			dealer__Quantity_Sold__c=1,
			dealer__Quantity_Ordered__c=1,
			dealer__Job_Line__c=dsj.Id,
			dealer__Service_Repair_Order__c=sro.Id,   
			dealer__Part_Description__c='test',
			dealer__Total_Price__c=12,
			dealer__Pay_Type__c='C'
		));
		dpls.add(new dealer__Parts_Invoice_Line__c(
			dealer__Parts_Invoice__c=dpinv.id,
			Name='test',
			dealer__Core__c=12,
			dealer__Cost__c=12,
			dealer__Price__c=12,
			dealer__Part_Number__c=pis[1].dealer__Part_Number__c,
			dealer__Quantity_Sold__c=1,
			dealer__Quantity_Ordered__c=1,
			//dealer__Job_Line__c=dsj.id,
			//dealer__Service_Repair_Order__c=dsr.id                  
			dealer__Part_Description__c='test',
			dealer__Total_Price__c=12,
			dealer__Pay_Type__c='C'
		));
		insert(dpls);

		dealer__Stock_Order__c dso = new dealer__Stock_Order__c(
			Name='CPT#' + sro.Name,
			dealer__Company__c = FFAdata.DealerLocation.Id,
			dealer__Date_Ordered__c = Date.today(),
			dealer__Manufacturer__c = 'MFG',
			dealer__Order_Type__c = 'Stock',
			dealer__Service_Repair_Order__c = sro.Id,
			dealer__Status__c = 'Ordered'
		);
		insert(dso);
		insert(new dealer__Parts_Order__c(
			dealer__Order__c = dso.Id,
			dealer__Order_Date__c = Date.today(),
			dealer__Parts_Inventory__c = pis[0].Id,
			dealer__Parts_Invoice__c = dpinv.Id,
			dealer__Parts_Line__c = dpls[0].Id,
			dealer__Quantity_Ordered__c = dpls[0].dealer__Quantity_Ordered__c,
			dealer__Transfer_Line__c = dpls[0].Id,
			dealer__Value__c = dpls[0].dealer__Total_Price__c
		));

		List<dealer__Parts_Ledger__c> pls = new List<dealer__Parts_Ledger__c>();
		pls.add(new dealer__Parts_Ledger__c(
			dealer__Entry_Date__c = Date.today(),
			dealer__Item_Value__c = 6.99,
			dealer__Quantity__c = 1,
			dealer__Part__c = pis[0].Id,
			dealer__Parts_Sale_Line__c = dpls[0].Id,
			dealer__Purchase_Order__c = polines[0].dealer__Purchase_Order__c,
			dealer__Transaction_Note__c = 'Test'
		));
		insert(pls);


		dealer__PartPhysicalInventory__c ppi = new dealer__PartPhysicalInventory__c(
			dealer__Location__c = FFAdata.DealerLocation.Id,
			Name = 'Test Physical',
			dealer__Status__c = 'Not Started'
		);
		insert(ppi);
		dealer__PartsPhysicalDetail__c ppd = new dealer__PartsPhysicalDetail__c(
			dealer__Parts_Physical_Inventory__c = ppi.Id,
			dealer__Part__c = pis[0].Id,
			dealer__Initial_Quantity__c = 1,
			dealer__Count__c = 2
		);
		insert(ppd);
	}

    @isTest
    static void testCleanLedger() {
        // BLL1
        dealer__Parts_Inventory__c pi = [
            SELECT Id, Name 
            FROM dealer__Parts_Inventory__c 
            WHERE dealer__Last_Sale_Date__c != null LIMIT 1
        ];
        List<dealer__Purchase_Order_Line__c> poLines = [
            SELECT Id, dealer__Part__c, dealer__Purchase_Order_Accepted_Date__c 
            FROM dealer__Purchase_Order_Line__c 
            WHERE dealer__Purchase_Order__r.RecordType.DeveloperName ='Parts_Purchase'
            AND dealer__Purchase_Order__r.dealer__Accepted_DateTime__c != null
            LIMIT 5
        ];
        
        // Invokable Method
		PartSupportAPI.setLedgerAssignment(poLines);
    }
    
    @isTest
    static void testCreateFromMaster() {
        dealer__Dealer_Location__c loc = dealer.TestClassUtil.insertDealerLocation('XYZ', 'Xylophone');	
        dealer__Parts_Master__c masterRecord = dealer.TestClassUtil.insertPartsMaster();
		dealer__Parts_Master__c pm = [
			SELECT dealer__Applications__c, dealer__Core_Required__c, dealer__Core_Value__c, dealer__Cost__c, 
				dealer__Height__c, dealer__Jobber_Price__c, dealer__Labor_Time__c, dealer__Length__c, 
				dealer__MAP__c, dealer__MFG_Comments__c, dealer__Manufacturer__c, dealer__Pack_QTY__c, 
				dealer__Part_Description__c, dealer__Part_No_Display__c, dealer__Part_No__c, 
				dealer__Price_Tape_Date__c, dealer__Raw_Part_Number__c, dealer__Retail_Price__c, 
				dealer__Return_Code__c, dealer__UPC__c, dealer__Warranty_Price__c, dealer__Weight__c, 
				dealer__Width__c, dealer__Catalog_Image__c, Id, Name 
			FROM dealer__Parts_Master__c 
			WHERE Id=:masterRecord.Id 
			LIMIT 1
		];
        PartSupportAPI.createPartFromMaster(loc.Id, pm);
		        
    }
    
    @isTest
    static void testPartLastSaleDate() {
       	dealer__Parts_Inventory__c[] pi = [SELECT Id, dealer__Parts_Master__c FROM dealer__Parts_Inventory__c WHERE dealer__On_Hand__c > 0 LIMIT 1];
        // BLL1
        //PartSupportAPI.customOrderCount(pi[0]);
        Test.startTest();
        PartSupportAPI.processOrderCount(pi[0].Id);    // processOrderCount calls customOrderCount
       	pi = [
			SELECT Id, dealer__Parts_Master__c 
			FROM dealer__Parts_Inventory__c 
			WHERE dealer__On_Order__c > 0 
			LIMIT 1
		];
        if (pi.size()>0) PartSupportAPI.performOrderCount(pi);
        Test.stopTest();    // will allow @Future method to complete
        // BLL1 end
    }
    
    @isTest
    static void testMigrateOnHand() {
        dealer__Parts_Inventory__c[] pi = [
			SELECT Id, dealer__Parts_Master__c 
			FROM dealer__Parts_Inventory__c 
			WHERE dealer__On_Hand__c > 0 
			LIMIT 2
		];
        PartSupportAPI.migrateOnHand(pi[0].dealer__Parts_Master__c, pi[1].dealer__Parts_Master__c);
    }
    
    @isTest
    static void testPartSupportBatch() {
        PartSupportBatch psb = new PartSupportBatch();
        // Database.executeBatch(psb, 1);
    }
    
    @isTest
    static void testPartOnOrderBatch() {
        batchUpdateOrderCount pb = new batchUpdateOrderCount();
    }

    // BLL1
    @isTest
    static void testLedgerItemsBasedOnTransferValue() {
        List<dealer__Parts_Order__c> pords = [
            select Id, Name, dealer__Parts_Line__c, dealer__Transfer_Line__c
            from dealer__Parts_Order__c
            where dealer__Parts_Line__c!=null and dealer__Transfer_Line__c!=null
            limit 3
        ];
        update(pords);
		PartSupportAPI.setLedgerItemsBasedOnTransferValue(pords);
    }

    @isTest
    static void testPhysicalAPI() {
        dealer__PartPhysicalInventory__c ppi = [
            select Id 
            from dealer__PartPhysicalInventory__c 
            order by CreatedDate desc
            limit 1];
        PartSupportAPI.completePhysicalAPIMethod(ppi);
    }

    @isTest
    static void testIntWarrPartsAtCost() {
		MW_TriggerControls__c IntAndWarrPartsAtCost = MW_TriggerControls__c.getInstance('IntAndWarrPartsAtCost');
        boolean enabled = IntAndWarrPartsAtCost==null ? true : IntAndWarrPartsAtCost.Enabled__c;
        List<dealer__Parts_Invoice_Line__c> pils = [
            select Id, Name 
            from dealer__Parts_Invoice_Line__c
            where dealer__Service_Repair_Order__r.dealer__Status__c in ('Open','Cashier')
                and dealer__Pay_Type__c in ('I','W')
            order by CreatedDate desc
            limit 3
        ];
        // Force code to run even if turned off 
        if (IntAndWarrPartsAtCost!=null && !enabled) {
            IntAndWarrPartsAtCost.Enabled__c = true;
            update(IntAndWarrPartsAtCost);
        }

        update(pils);

        // Put setting back
        if (IntAndWarrPartsAtCost!=null) {
            IntAndWarrPartsAtCost.Enabled__c = enabled;
            update(IntAndWarrPartsAtCost);
        }
    }

    //@isTest
    //static void testSetLedgerFromTransfer() {
    //    Map<String, Schema.SObjectField> objFieldMap =  Schema.dealer__Parts_Order__c.SObjectType.getDescribe().fields.getMap();
    //    List<String> objFieldList = new List<String>();
    //    for(string f : objFieldMap.keySet()) objFieldList.add(f);
    //    String objfields = String.join(objFieldList,',');
    //    String soql = 'select ' + objfields 
    //        + ' from dealer__Parts_Order__c '
    //        + ' where dealer__Parts_Line__c!=null and dealer__Transfer_Line__c!=null '
    //        + ' limit 5';
    //    List<dealer__Parts_Order__c> pords = Database.query(soql);
    //
    //    Test.startTest();
    //    //update(pords);
    //    PartSupportAPI.setLedgerItemsBasedOnTransferValue(pords);
    //    Test.stopTest();
    //}
    // BLL1 end


}