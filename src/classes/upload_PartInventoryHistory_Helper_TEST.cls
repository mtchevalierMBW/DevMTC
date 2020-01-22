/**
 * upload_PartInventoryHistory_Helper_TEST
 * 
 * Tests: upload_PartInventoryHistory_Helper trigger (look up Loc:Mfg:Part in parts inventory during data load)
 *
 */
@isTest(seeAllData=true)
private class upload_PartInventoryHistory_Helper_TEST {

    static testMethod void testUpload() {
        
        Id historyId = null;
        String locMfgPart = null;
    
        TestHelper_MW th = TestHelper_MW.getInstance();
   	
   	    // Need a location
   	    //dealer__Dealer_Location__c loc = [select Id, Name, dealer__Company_Number__c from dealer__Dealer_Location__c limit 1];
   	    dealer__Dealer_Location__c loc = th.getDealerLocation('1');
   	
   	    //User u = [select Id, Name, Division from User where Id=:UserInfo.getUserId() limit 1];
   	    //u.Division = loc.dealer__Company_Number__c;
   	    //update(u);
   	    User userObj = th.getTestUser('1');
   	    
   	    System.runAs(userObj) {
   	   
   	        dealer__Parts_Master__c p1 = th.getPartsMaster('1');
	        dealer__Parts_Inventory__c pi1 = th.getPartsInventory('1');
	        
	   	    Test.startTest();
	
	        dealer__Part_Inventory_History__c h = new dealer__Part_Inventory_History__c();
			h.dealer__Cost__c = 1.00;
			h.dealer__Quantity_Adjustment__c = 1;
			h.dealer__Transaction_Event__c = 'Test';
			h.uploadPart__c = pi1.dealer__Part_No__c;
			locMfgPart = pi1.dealer__Part_No__c;
			try {
			    insert(h);
			    historyId = h.Id;
			} catch(Exception insertErr) { }
		
   	    } 
		Test.stopTest();
		
        dealer__Part_Inventory_History__c h_after = [
            select Id, dealer__Part__r.Name, dealer__Part__r.dealer__Part_No__c
            from dealer__Part_Inventory_History__c
            where Id=:historyId
        ];        
        System.assertEquals(locMfgPart, h_after.dealer__Part__r.dealer__Part_No__c, 'Part Inventory History referenced part is not correct.');
        
    }
}