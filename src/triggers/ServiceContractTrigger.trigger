/**
 * ServiceContractTrigger
 * Tested by: DealMBW_TC
 * A trigger for Service Contracts
 * 
 *	2017-03-30	B. Leaman	BLL1 - switch to new Deal controller extension (commercial proposal project)
 * 	2018-02-12 	B. Leaman	BLL2 - Make sure we don't update proposal if price/cost didn't change!
 */
trigger ServiceContractTrigger on dealer__Service_Contract__c (after insert, after update, after delete) {

    if(trigger.size == 1 && Trigger.isDelete ) {	// BLL2c remove isUpdate
        // Begin looping through items in trigger
        for(dealer__Service_Contract__c sc : Trigger.old) {
            // Run Static Update Method when Service COntract is edited
            if(sc.dealer__Car_Deal__c!=null) Deal_MBW2.totalAllAMItems( sc.dealer__Car_Deal__c );
        }
    }
    if (trigger.size == 1 && Trigger.isInsert) {
        // Begin looping through items in trigger
        for(dealer__Service_Contract__c sc : Trigger.new) {
            // Run Static Update Method when Service COntract is edited
            if(sc.dealer__Car_Deal__c!=null) Deal_MBW2.totalAllAMItems( sc.dealer__Car_Deal__c );
        }
    }
    // BLL2a
    if (trigger.size==1 && Trigger.isUpdate) {
    	for(dealer__Service_Contract__c sc : Trigger.new) {
    		dealer__Service_COntract__c oldsc = Trigger.oldMap.get(sc.Id);
    		if (oldsc!=null && sc.dealer__Car_Deal__c!=null
    			&& (oldsc.dealer__Cost__c!=sc.dealer__Cost__c || oldsc.dealer__Sale_Price__c!=sc.dealer__Sale_Price__c)) {
    			Deal_MBW2.totalAllAMItems( sc.dealer__Car_Deal__c );
    		}
    	}
    }
	// BLL2a end
}