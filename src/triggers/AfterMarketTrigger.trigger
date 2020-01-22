/***
 *
 *	AfterMarketTrigger
 * 
 *	2017-03-30	B. Leaman	BLL1 - switch to new Deal controller extension (commercial proposal project)
 * 
***/
trigger AfterMarketTrigger on dealer__After_Market__c (after insert, after update, after delete) {
	if(trigger.size == 1 && (Trigger.isUpdate || Trigger.isDelete) ) {
		// Begin looping through items in trigger
        for(dealer__After_Market__c am : Trigger.old) {
            // Run Static Update Method when After Market Item is edited
            if(am.dealer__Car_Deal__c!=null)
                Deal_MBW2.totalAllAMItems( am.dealer__Car_Deal__c );
        }
	} else if (trigger.size == 1 && Trigger.isInsert) {

        for(dealer__After_Market__c am : Trigger.new) {
            // Run Static Update Method when After Market Item is edited
            if(am.dealer__Car_Deal__c!=null)
                Deal_MBW2.totalAllAMItems( am.dealer__Car_Deal__c );
        }

	}
}