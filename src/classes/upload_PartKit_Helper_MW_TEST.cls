/**
 * upload_PartKit_Helper_MW_TEST
 * Tests: upload_PartKit_Helper_MW, upload_PartKitItem_Helper_MW
 */
@isTest(seeAllData=true)
private class upload_PartKit_Helper_MW_TEST {

   @isTest
   private static void ResolveLookups() {
   	
//   	   TestHelper_MW th = new TestHelper_MW();
//   	
//   	   //User u = [select Id, Name, Division from User where Id=:UserInfo.getUserId() limit 1];
//   	   //u.Division = loc.dealer__Company_Number__c;
//   	   //update(u);
//   	   User u = th.getTestUser('1');
//
//       System.runAs(u) {
//
//	   	   // Need a location
//	   	   dealer__Dealer_Location__c loc = th.getDealerLocation('1');
//	   	   dealer__Parts_Stocking_Group__c psg = th.getDefaultPartsStockingGroup();
//	   	   
//	   	   Test.startTest();
//	   	
//	       //dealer__Parts_Master__c p1 = new dealer__Parts_Master__c(
//	       //      Name='TESTPART1', dealer__Manufacturer__c='TST',
//	       //      dealer__Raw_Part_Number__c = 'TESTPART1',
//	       //      dealer__Part_No__c='TST:TESTPART1',
//	       //      dealer__Retail_Price__c=3.00,
//	       //      dealer__Cost__c=1.00
//	       //);
//	       //insert(p1);
//	       //dealer__Parts_Master__c pm1 = [select Id, Name, dealer__Part_No__c from dealer__Parts_Master__c where Id=:p1.Id limit 1];
//	       //dealer__Parts_Inventory__c pi1 = [select Id, Name from dealer__Parts_Inventory__c where dealer__Parts_Master__c=:p1.Id limit 1];
//	       //System.debug('Parts Master Id=' + pm1.Id + '; Name=' + pm1.Name + '; Part_No=' + pm1.dealer__Part_No__c);
//	       //System.debug('Parts Inventory Id=' + pi1.Id + '; Name=' + pi1.Name + '; Parts Mstr=' + pi1.dealer__Parts_Master__c);
//	       dealer__Parts_Master__c pm1 = th.getPartsMaster('1A');
//	       
//	       //dealer__Parts_Master__c p2 = new dealer__Parts_Master__c(
//	       //      Name='TESTPART2', dealer__Manufacturer__c='TST',
//	       //      dealer__Part_No__c='TST:TESTPART2',
//	       //      dealer__Raw_Part_Number__c='TESTPART2',
//	       //      dealer__Retail_Price__c=3.50,
//	       //      dealer__Cost__c=1.75
//	       //);
//	       //insert(p2);
//	       //dealer__Parts_Master__c pm2 = [select Id, Name, dealer__Part_No__c from dealer__Parts_Master__c where Id=:p2.Id limit 1];
//	       //dealer__Parts_Inventory__c pi2 = [select Id, Name from dealer__Parts_Inventory__c where dealer__Parts_Master__c=:p2.Id limit 1];
//	       //System.debug('Parts Master Id=' + pm2.Id + '; Name=' + pm2.Name + '; Part_No=' + pm2.dealer__Part_No__c);
//	       //System.debug('Parts Inventory Id=' + pi2.Id + '; Name=' + pi2.Name + '; Parts Mstr=' + pi2.dealer__Parts_Master__c);
//	       dealer__Parts_Master__c pm2 = th.getPartsMaster('1B');
//	
//	   	   Kit_Category__c cat = new Kit_Category__c(Name='Test Category', Type__c='Category', External_ID__c='CT1');
//	   	   Kit_Category__c sub = new Kit_Category__c(Name='Test SubCategory', Type__c='Sub-category', External_ID__c='ST1');
//	   	   Kit_Category__c mfg = new Kit_Category__c(Name='Test Manufacturer', Type__c='Manufacturer', External_ID__c='MT1');
//	       insert(cat);
//	       insert(sub);
//	       insert(mfg);
//	       
//	       String kitname = 'Test Kit 0123';
//	   	   dealer__Parts_Kit__c kit = new dealer__Parts_Kit__c(Name=kitname, dealer__Description__c='Test kit description',
//	   	                 External_ID__c = 'xxyyyzzz0123',  
//	   	                 Upload_Category__c='CT1', Upload_Sub_Category__c='ST1', Upload_Manufacturer__c='MT1');
//	   	   //try {
//	   	       insert(kit);
//	   	   //} catch (Exception e) {
//	   	   //	   System.debug('Unable to create kit');
//	   	   //	   System.debug(kit);
//	   	   //}
//	
//	       dealer__Parts_Kit__c newkit = [select Id, Name, Category__c, Sub_Category__c, Manufacturer__c
//	                                       from dealer__Parts_Kit__c
//	                                       where Id=:kit.Id limit 1];
//	   	   System.assertEquals(cat.Id, newkit.Category__c, 'Category was not properly assigned');
//	   	   System.assertEquals(sub.Id, newkit.Sub_Category__c, 'Sub-category was not properly assigned');
//	   	   System.assertEquals(mfg.Id, newkit.Manufacturer__c, 'Manufacturer was not properly assigned');
//	
//	       dealer__Parts_Kit_Item__c pk1 = new dealer__Parts_Kit_Item__c(
//	           upload_Kit__c = kitname,
//	           upload_Part__c = pm1.dealer__Part_No__c, // 'TST:TESTPART1',
//	           dealer__Quantity__c = 1
//	       );
//	       insert(pk1);
//	       dealer__Parts_Kit_Item__c pk2 = new dealer__Parts_Kit_Item__c(
//	           upload_Kit__c = kitname,
//	           upload_Part__c = pm2.dealer__Part_No__c, // 'TST:TESTPART2',
//	           dealer__Quantity__c = 2
//	       );
//	       insert(pk2);
//	   	   
//	   	   Test.stopTest();
//   	   
//       }
   }
   
}