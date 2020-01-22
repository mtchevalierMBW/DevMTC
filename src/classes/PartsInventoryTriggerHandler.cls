/** PartsInventoryTriggerHandler
 * Tested by: PartsPricing_TEST
 * 2015-08-07	B. Leaman   BLL1 Don't run logic if cost is null 
 * 2015-09-16	B. Leaman	BLL2 Fix matrix & Add markup for parts over $4k
 * 2015-10-12   J. Kuljis   JVK1 Price matrix has two components, List and Sell Price  -- See Jill and Ray
 * 2016-03-14   RedTeal     RT1 - Moved logic out of PartsInventoryPriceControl trigger to this handler class. Will also
 								  update status of part/part master if the status is 'Obsolete w/ Inventory' and on hand
 								  is 0 to 'Obsolete'
 * 2016-06-30	B. Leaman	BLL3 JVK1 should not have been moved to production. It is inflating list prices by 20%.
 * 2017-04-26	J. Kuljis	JVK2 Add sync to register copy table in after context future callout.
 * 2018-03-05	B. Leaman	BLL4 Remove duplication of price matrix in part and inventory routines; remove newListPrice logic as it wasn't being used;
 */ 

public  class PartsInventoryTriggerHandler {
	//RT1 - use to prevent recursive trigger calls
	public static boolean allowTrigger = true;

	public static void beforeHandler(List<dealer__Parts_Inventory__c> newList) {
		List<String> partMasterIds = new List<String>();
	    for(dealer__Parts_Inventory__c p : newList) {
	    	if(p.dealer__Status__c != 'Obsolete') {
		    	if (p.dealer__Cost__c!=null) { // BLL1a
					//BLL4d Decimal newSellPrice = p.dealer__Cost__c * 1.00;  // JVK1a
					//BLL4d Decimal newListPrice = p.dealer__Cost__c * 1.00;
			        // BLL2d begin
			        //p.dealer__List__c = (p.dealer__Cost__c * 5);
			        //if(p.dealer__Cost__c >= 1) { p.dealer__List__c = (p.dealer__Cost__c * 5); }
			        //if(p.dealer__Cost__c <= 2.5) { p.dealer__List__c = (p.dealer__Cost__c * 4.5); }
			        //if(p.dealer__Cost__c <= 5) { p.dealer__List__c = (p.dealer__Cost__c * 4); }
			        //if(p.dealer__Cost__c <= 25) { p.dealer__List__c = (p.dealer__Cost__c * 3.75); }
			        //if(p.dealer__Cost__c <= 33) { p.dealer__List__c = (p.dealer__Cost__c * 3.5); }
			        //if(p.dealer__Cost__c <= 49) { p.dealer__List__c = (p.dealer__Cost__c * 3.2); }
			        //if(p.dealer__Cost__c <= 65) { p.dealer__List__c = (p.dealer__Cost__c * 2.8); }
			        //if(p.dealer__Cost__c <= 81) { p.dealer__List__c = (p.dealer__Cost__c * 2.3); }
			        //if(p.dealer__Cost__c <= 2000) { p.dealer__List__c = (p.dealer__Cost__c * 2); }
			        //if(p.dealer__Cost__c <= 4000) { p.dealer__List__c = (p.dealer__Cost__c * 1.6); }
			        // BLL2d end
			        // BLL2a begin
			        // JVK1
			        //BLL4d if (p.dealer__Cost__c <= 1.00)         { newSellPrice = (p.dealer__Cost__c * 5.00); newListPrice = (p.dealer__Cost__c * 5.20);  }
			        //BLL4d else if (p.dealer__Cost__c <=    2.50) { newSellPrice = (p.dealer__Cost__c * 4.50); newListPrice = (p.dealer__Cost__c * 4.70);  }
			        //BLL4d else if (p.dealer__Cost__c <=    5.00) { newSellPrice = (p.dealer__Cost__c * 4.00); newListPrice = (p.dealer__Cost__c * 4.20);  }
			        //BLL4d else if (p.dealer__Cost__c <=   25.00) { newSellPrice = (p.dealer__Cost__c * 3.75); newListPrice = (p.dealer__Cost__c * 3.95);  }
			        //BLL4d else if (p.dealer__Cost__c <=   33.00) { newSellPrice = (p.dealer__Cost__c * 3.50); newListPrice = (p.dealer__Cost__c * 3.70);  }  
			        //BLL4d else if (p.dealer__Cost__c <=   49.00) { newSellPrice = (p.dealer__Cost__c * 3.20); newListPrice = (p.dealer__Cost__c * 3.40);  }  
			        //BLL4d else if (p.dealer__Cost__c <=   65.00) { newSellPrice = (p.dealer__Cost__c * 2.80); newListPrice = (p.dealer__Cost__c * 3.00);  }  
			        //BLL4d else if (p.dealer__Cost__c <=   81.00) { newSellPrice = (p.dealer__Cost__c * 2.30); newListPrice = (p.dealer__Cost__c * 2.50);  }  
			        //BLL4d else if (p.dealer__Cost__c <= 2000.00) { newSellPrice = (p.dealer__Cost__c * 2.00); newListPrice = (p.dealer__Cost__c * 2.20);  }  
			        //BLL4d else if (p.dealer__Cost__c <= 4000.00) { newSellPrice = (p.dealer__Cost__c * 1.66); newListPrice = (p.dealer__Cost__c * 1.86);  }  
			        //BLL4d else if (p.dealer__Cost__c >  4000.00) { newSellPrice = (p.dealer__Cost__c * 1.40); newListPrice = (p.dealer__Cost__c * 1.60);  } 
		        	//BLL3d No, use the same as parts master p.dealer__List__c = newListPrice.setScale(2, System.RoundingMode.HALF_UP);
    				Decimal newSellPrice = PartsProcess.RetailPriceMarkUpFromCost(p.dealer__Cost__c);	// BLL4a
		        	p.dealer__List__c = newSellPrice.setScale(2, System.RoundingMode.HALF_UP);	// BLL3a
		        	//JVK1a, BLLd until okayed p.Sell_Price__c = newSellPrice.setScale(2, System.RoundingMode.HALF_UP);
		        	// BLL2a end 
		    	} // BLL1a endif dealer__Cost__c!=null

		    	//RT1
		    	if(p.dealer__On_Hand__c == 0 && p.dealer__Status__c == 'Obsolete w/ Inventory') {
		    		p.dealer__Status__c = 'Obsolete'; 
		    		partMasterIds.add(p.dealer__Parts_Master__c);
		    	}
	    	}
	    }

	   
	}

	public static void afterHandler(List<dealer__Parts_Inventory__c> newList) {
		//RT1
		List<String> partMasterIds = new List<String>();
	    for(dealer__Parts_Inventory__c p : newList) {
			if(p.dealer__On_Hand__c == 0 && p.dealer__Status__c == 'Obsolete') {
	    		partMasterIds.add(p.dealer__Parts_Master__c);
	    	}
    	}
     	if(partMasterIds.size() > 0) {
	    	List<dealer__Parts_Master__c> partsMasters = [SELECT Id, (SELECT dealer__Status__c FROM dealer__Parts_Inventories__r) FROM dealer__Parts_Master__c WHERE Id IN :partMasterIds];
	    	List<dealer__Parts_Master__c> updateMasters = new List<dealer__Parts_Master__c>();

	    	for(dealer__Parts_Master__c partMaster : partsMasters) {
	    		boolean obsolete = true;
	    		for(dealer__Parts_Inventory__c part : partMaster.dealer__Parts_Inventories__r) {
	    			if(part.dealer__Status__c != 'Obsolete') {
	    				obsolete = false;
	    				break;
	    			}
	    		}
	    		if(obsolete) {
	    			partMaster.dealer__Status__c = 'Obsolete';
	    			updateMasters.add(partMaster);
	    		}
	    	}
	    	if(updateMasters.size() > 0) {
	    		allowTrigger = false;
	    		update updateMasters;
	    	}
	    }
	    //end RT1
	}

/*
	JVK2
	Temporary code block to get the copy register synced 
	<--
*/
	public static void performRegisterSync(List<dealer__Parts_Inventory__c> newList, Map<Id, dealer__Parts_Inventory__c> oldMap) {
		// Incase something goes horribly wrong...
		MW_TriggerControls__c runRL = MW_TriggerControls__c.getInstance('CopyReportingLedger');

		for(dealer__Parts_Inventory__c pi : newList) {
			if(runRL!=null 
				&& runRL.Enabled__c==true
				&& oldMap!=null
				&& oldMap.get(pi.Id)!=null 
				&& oldMap.get(pi.Id).dealer__On_Hand__c!=null 
				&& pi.dealer__On_Hand__c != null 
				&& pi.dealer__On_Hand__c != oldMap.get(pi.Id).dealer__On_Hand__c) {
				PartsInventoryTriggerHandler.syncRegister(pi.Id);
			}
		}
	}

	@future 
	public static void syncRegister( Id partId ) {
		PartLedgerAPI.rebuiltLedgerReportingTable(partId);
	}
/*
	END JVK2
	Temporary code block to get the copy register synced 
	-->
*/	
}