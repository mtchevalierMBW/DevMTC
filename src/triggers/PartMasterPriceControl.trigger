/** PartMasterPriceControl
 * Tested by: PartsPricing_TEST
 * 2015-08-07  B. Leaman   BLL1 Don't run logic if cost is null (causing test failure in DealMBW_TC)
 * 2015-09-03  B. Leaman   BLL2 Rewrite matrix logic. 
 *                         Previously all parts <= 4000.00 were at 1.6x, over 4000.00 at 5x
 *                            because there were no else statements, so the last condition ruled.
 *                         Also, use setScale(2) because system appears to be storing more decimal places
 *                            and then every subsequent record update logs a price change to history 
 *                            butshowing no actual change.
 * 2015-09-16  B. Leaman   BLL3 Adjust markup for cost>4000 to 1.4x per Ray Morton, Jeff Smith, Jerry August.
 * 2015-11-3   RedTeal	   RT1 - Updates the extended cost of any associated kit items when the cost is changed.
 * 2016-01-31  J. Kuljis   JVK1 - Set status of Master on inventory parts.
 * 2017-10-16	B. Leaman	BLL4 - don't run any non-selective queries.    
 * 2018-03-02	B. Leaman	BLL5 - new part supersession logic; move kit component cost update to "after" trigger context;
 *							Also move part pricing matrix to new part process
 * 2019-03-28   A. Miller   AMM6/BLL6 - W-000554 Update to handle uppercases
 * 2019-07-26	B. Leaman	W-000703 BLL7 - Parts master static price changes to replicate down to parts.
 */
trigger PartMasterPriceControl on dealer__Parts_Master__c (before insert, before update, after update) {

	MW_TriggerControls__c PartSupersession = MW_TriggerControls__c.getInstance('PartSupersession');
	boolean partSupersessionEnabled = PartSupersession==null || PartSupersession.Enabled__c==true;

	// BLL5a
	if (Trigger.isBefore && Trigger.isUpdate && partSupersessionEnabled) PartsProcess.doPartMasterSupersessions(Trigger.new, Trigger.oldMap);
	if (Trigger.isAfter && Trigger.isUpdate && partSupersessionEnabled) PartsProcess.doPartsInventorySupersession(Trigger.new, Trigger.oldMap);
	// BLL5a end
    	
	// BLL7
	if (Trigger.isAfter && Trigger.isUpdate) PartsProcess.MasterStaticPriceUpdate(Trigger.new, Trigger.oldMap);
	// BLL7 end

    if(Trigger.isBefore) {

        // AMM6/BLL6
        if (!Trigger.isDelete) PartsProcess.ensureUppercase(Trigger.new);
        // AMM6

    	for(dealer__Parts_Master__c p : Trigger.new) {
    		if (p.dealer__Cost__c!=null) {  // BLL1a
    			//BLL5d Decimal newRetailPrice = p.dealer__Cost__c * 1.00;
    			Decimal newRetailPrice = p.dealer__Retail_Price__c = PartsProcess.RetailPriceMarkUpFromCost(p.dealer__Cost__c);	// BLL5a
    	        //p.dealer__Retail_Price__c = p.dealer__Cost__c * 5;
    	        //if(p.dealer__Cost__c >= 1)    { p.dealer__Retail_Price__c = (p.dealer__Cost__c * 5); }
    	        //BLLxd if (p.dealer__Cost__c <= 1.00)         { newRetailPrice = (p.dealer__Cost__c * 5.00); }
    	        //BLLxd else if (p.dealer__Cost__c <=    2.50) { newRetailPrice = (p.dealer__Cost__c * 4.50); }
    	        //BLLxd else if (p.dealer__Cost__c <=    5.00) { newRetailPrice = (p.dealer__Cost__c * 4.00); }
    	        //BLLxd else if (p.dealer__Cost__c <=   25.00) { newRetailPrice = (p.dealer__Cost__c * 3.75); }
    	        //BLLxd else if (p.dealer__Cost__c <=   33.00) { newRetailPrice = (p.dealer__Cost__c * 3.50); }  
    	        //BLLxd else if (p.dealer__Cost__c <=   49.00) { newRetailPrice = (p.dealer__Cost__c * 3.20); }  
    	        //BLLxd else if (p.dealer__Cost__c <=   65.00) { newRetailPrice = (p.dealer__Cost__c * 2.80); }  
    	        //BLLxd else if (p.dealer__Cost__c <=   81.00) { newRetailPrice = (p.dealer__Cost__c * 2.30); }  
    	        //BLLxd else if (p.dealer__Cost__c <= 2000.00) { newRetailPrice = (p.dealer__Cost__c * 2.00); }  
    	        //BLLxd else if (p.dealer__Cost__c <= 4000.00) { newRetailPrice = (p.dealer__Cost__c * 1.66); }  
    	        //BLLxd else if (p.dealer__Cost__c >  4000.00) { newRetailPrice = (p.dealer__Cost__c * 1.40); }  // BLL3c (was 1.00)
            	p.dealer__Retail_Price__c = newRetailPrice.setScale(2, System.RoundingMode.HALF_UP);
    		} // BLL1a endif dealer__Cost__c!=null
    		
    	}	// BLL5a
    } // BLL5a	// End Before Context
    
    if (Trigger.isAfter && Trigger.isUpdate) {	// BLL5a
		
        List<String> updatedIds = new List<String>();
    	for(dealer__Parts_Master__c p : Trigger.new) {
            if (Trigger.isUpdate) {	// BLL4a when Trigger.isBefore, p.Id will be null
	            //RT1
	            if(Trigger.oldMap == null) {
	                updatedIds.add(p.Id);
	            }
	            else{
	                dealer__Parts_Master__c oldMaster = Trigger.oldMap.get(p.Id);
	                if(p.dealer__Cost__c != oldMaster.dealer__Cost__c) {
	                    updatedIds.add(p.Id);
	                }
	            }//End RT1
            }	// BLL4a
        }    
        
		// BLL4 stop adding null to updatedIds on insert, causing this query to be non-selective...
        List<dealer__Parts_Kit_Item__c> kitItems = [SELECT Id, dealer__Parts_Master__c, dealer__Extended_Cost__c, dealer__Quantity__c FROM dealer__Parts_Kit_Item__c WHERE dealer__Parts_Master__c IN :updatedIds];
        if(kitItems.size() > 0) {
            for(dealer__Parts_Kit_Item__c kitItem : kitItems) {
                dealer__Parts_Master__c newPartsMaster = Trigger.newMap.get(kitItem.dealer__Parts_Master__c);
                kitItem.dealer__Extended_Cost__c = newPartsMaster.dealer__Cost__c * kitItem.dealer__Quantity__c;
            }
            update kitItems;        
        }

    } // End After-Update Context

    if(Trigger.isAfter && !Trigger.isDelete) { //JVK1

        // Create Map of Parts
        Map<Id, String> pmStatusMap = new Map<Id, String>();
        for(dealer__Parts_Master__c p : Trigger.new) {
            pmStatusMap.put(p.Id, p.dealer__Status__c);
        }

        // If requires update place in List
        List<dealer__Parts_Inventory__c> pinv = new List<dealer__Parts_Inventory__c>();
        for(dealer__Parts_Inventory__c pts : [Select Id, dealer__Parts_Master__c, dealer__Status__c from dealer__Parts_Inventory__c where dealer__Parts_Master__c IN:pmStatusMap.keySet() limit 2000 for update]) {
            // Check current status against map;
            if(pmStatusMap.get(pts.dealer__Parts_Master__c) != pts.dealer__Status__c) {
                pinv.add(new dealer__Parts_Inventory__c(Id=pts.Id, dealer__Status__c=pmStatusMap.get(pts.dealer__Parts_Master__c)));
            }
        }

        // Apply list with updated status to the inventory
        try {
            if(!pinv.isEmpty()) {
                update pinv;
            }
        } Catch(DmlException e) {
            Trigger.new[0].addError('Unable to update the Parts Inventory Record Status '+e.getMessage());
        }
    }

}