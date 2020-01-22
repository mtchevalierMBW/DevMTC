/**
* KitProcess_TEST
* Tests: KitProcess
* Date: 2019-08-13
* Programmer: Bryan Leaman
* Project: W-000729
*
* Coverage:
*
* Modifications: 
*
**/
@isTest
private class KitProcess_TEST {

	//private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupData() {
		//TestHelper_MW.createBaseFFAData(FFAdata);
		dealer.TestClassUtil tc = new dealer.TestClassUtil();
		tc.insertDMSSettings();

		List<Kit_Category__c> kcList = new List<Kit_Category__c>();
		kcList.add(new Kit_Category__c(Name='Conversion Package', Type__c='Category', External_ID__c='CT1', Conversion_Package__c=true));
		kcList.add(new Kit_Category__c(Name='Chassis', Type__c='Category', External_ID__c='CT2', Chassis_Package__c=true));
		kcList.add(new Kit_Category__c(Name='Other', Type__c='Category', External_ID__c='CT3'));
		insert(kclist);

	}

	// ConversionKit
	//---------------------------------------
	static testMethod void ConversionKit() {
		//FFAdata.refresh(); 
		//System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();
			Test.startTest();
			
			Kit_Category__c convKit = [select Id from Kit_Category__c where Name='Conversion Package' limit 1];
			insert(new dealer__Parts_Kit__c(
				Name='Test Conversion Kit', 
				dealer__Description__c='Test conversion kit description',
				External_ID__c = 'convkit123',  
	   	        Category__c=convKit.Id,
				Conv_MFG__c='BraunAbility'
			));

			Test.stopTest();
		//}
	}

	@isTest
	private static void RecordTypeTests() {
   	
   		TestHelper_MW th = new TestHelper_MW();
   		User u = th.getTestUser('1');
    	System.runAs(u) {
	   		// Need a location
	   		dealer__Dealer_Location__c loc = th.getDealerLocation('1');
	   		dealer__Parts_Stocking_Group__c psg = th.getDefaultPartsStockingGroup();
	   	   
			Test.startTest();
	   	
			Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Parts_Kit__c.getRecordTypeInfosByName();
			Schema.RecordTypeInfo ConvKitInfo = RcdTypes.get('Conversion Package');
			Schema.RecordTypeInfo PartsKitInfo = RcdTypes.get('Parts Kit');
			Schema.RecordTypeInfo ChassisKitInfo = RcdTypes.get('Chassis');
			Id ConvKitRtId = ConvKitInfo==null ? null : ConvKitInfo.getRecordTypeId();
			Id PartsKitRtId = PartsKitInfo==null ? null : PartsKitInfo.getRecordTypeId();
			Id ChassisKitRtId = ChassisKitInfo==null ? null : ChassisKitInfo.getRecordTypeId();

			List<dealer__Parts_Kit__c> kits = new List<dealer__Parts_Kit__c>();
	   		kits.add(new dealer__Parts_Kit__c(
				Name='Test Kit 0123', 
				RecordTypeId=PartsKitRtId, 
				dealer__Description__c='Test kit description',
				External_ID__c = 'xxyyyzzz0123',  
	   	        Upload_Category__c='CT1'
			));
	   		kits.add(new dealer__Parts_Kit__c(
				Name='Test Kit 0124', 
				RecordTypeId=PartsKitRtId, 
				dealer__Description__c='Test kit description',
				External_ID__c = 'xxyyyzzz0124',  
	   	        Upload_Category__c='CT2'
			));
	   		kits.add(new dealer__Parts_Kit__c(
				Name='Test Kit 0125', 
				RecordTypeId=ConvKitRtId, 
				dealer__Description__c='Test kit description',
				External_ID__c = 'xxyyyzzz0125',  
	   	        Upload_Category__c='KC3'
			));
	   		kits.add(new dealer__Parts_Kit__c(
				Name='Test Kit 0126', 
				RecordTypeId=ChassisKitRtId, 
				dealer__Description__c='Test kit description',
				External_ID__c = 'xxyyyzzz0126', 
	   	        Upload_Category__c=null
			));
   	    	insert(kits);
	
	    	for(dealer__Parts_Kit__c pk : [
				select Id, Name, RecordType.Name, Category__c, Category__r.Name,
					Category__r.Conversion_Package__c, Category__r.Chassis_Package__c
				from dealer__Parts_Kit__c
			]) {
				System.debug(pk);
	   			if (pk.Category__r.Conversion_Package__c)
				   System.assertEquals(pk.RecordType.Name, 'Conversion Package', 'Conversion Kit RecordType was not properly assigned');
	   			if (pk.Category__r.Chassis_Package__c)
				   System.assertEquals(pk.RecordType.Name, 'Chassis', 'Conversion Kit RecordType was not properly assigned');
	   			if (!pk.Category__r.Conversion_Package__c && !pk.Category__r.Chassis_Package__c) 
				   System.assert(pk.RecordType.Name!='Conversion Package' && pk.RecordType.Name!='Chassis', 'Kit RecordType was left as Conversion Package or Chassis when category is neither: ' 
				   	+ JSON.serialize(pk));
			}
	   	   
			Test.stopTest();
    	}
	}


	@isTest
	private static void ResolveUploadReferences() {
   	
   		TestHelper_MW th = new TestHelper_MW();
   		User u = th.getTestUser('1');
    	System.runAs(u) {
	   		// Need a location
	   		dealer__Dealer_Location__c loc = th.getDealerLocation('1');
	   		dealer__Parts_Stocking_Group__c psg = th.getDefaultPartsStockingGroup();
	   	   
			Test.startTest();
	   	
			dealer__Parts_Master__c pm1 = th.getPartsMaster('1A');
			dealer__Parts_Master__c pm2 = th.getPartsMaster('1B');
	
			Kit_Category__c cat = new Kit_Category__c(Name='Test Category', Type__c='Category', External_ID__c='CT1');
			Kit_Category__c sub = new Kit_Category__c(Name='Test SubCategory', Type__c='Sub-category', External_ID__c='ST1');
			Kit_Category__c mfg = new Kit_Category__c(Name='Test Manufacturer', Type__c='Manufacturer', External_ID__c='MT1');
			List<Kit_Category__c> kcList = new List<Kit_Category__c>();
			kclist.add(cat);
			kclist.add(sub);
			kclist.add(mfg);
			insert(kclist);

	    	String kitname = 'Test Kit 0123';
	   		dealer__Parts_Kit__c kit = new dealer__Parts_Kit__c(
				Name=kitname, dealer__Description__c='Test kit description',
				External_ID__c = 'xxyyyzzz0123',  
	   	        Upload_Category__c='CT1', 
				Upload_Sub_Category__c='ST1', 
				Upload_Manufacturer__c='MT1');
   	    	insert(kit);
	
	    	dealer__Parts_Kit__c newkit = [
				select Id, Name, Category__c, Sub_Category__c, Manufacturer__c
				from dealer__Parts_Kit__c
				where Id=:kit.Id limit 1
			];
	   		System.assertEquals(cat.Id, newkit.Category__c, 'Category was not properly assigned');
	   		System.assertEquals(sub.Id, newkit.Sub_Category__c, 'Sub-category was not properly assigned');
	   		System.assertEquals(mfg.Id, newkit.Manufacturer__c, 'Manufacturer was not properly assigned');
	
			List<dealer__Parts_Kit_Item__c> pkitems = new List<dealer__Parts_Kit_Item__c>();
	    	dealer__Parts_Kit_Item__c pk1 = new dealer__Parts_Kit_Item__c(
				upload_Kit__c = kitname,
				upload_Part__c = pm1.dealer__Part_No__c, // 'TST:TESTPART1',
				dealer__Quantity__c = 1
			);
			pkitems.add(pk1);
			dealer__Parts_Kit_Item__c pk2 = new dealer__Parts_Kit_Item__c(
				upload_Kit__c = kitname,
				upload_Part__c = pm2.dealer__Part_No__c, // 'TST:TESTPART2',
				dealer__Quantity__c = 2
			);
	    	pkitems.add(pk2);
			insert(pkitems);
	   	   
			Test.stopTest();
    	}
	}

}