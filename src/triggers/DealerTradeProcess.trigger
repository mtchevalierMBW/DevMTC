/**
 * DealerTradeProcess
 * Tested by: VehicleTransfer_TEST
 * Date: Dec 23, 2015
 * Programmer: Bryan Leaman
 * 
 */
trigger DealerTradeProcess on dealer__Dealer_Trade__c (before insert, before update, before delete) {
 
	MW_TriggerControls__c DealerTradeIntegrity = MW_TriggerControls__c.getInstance('DealerTradeIntegrity'); 
	MW_TriggerControls__c DealerTradeStatusChange = MW_TriggerControls__c.getInstance('DealerTradeStatusChange'); 
	MW_TriggerControls__c DealerTradePreventDelete = MW_TriggerControls__c.getInstance('DealerTradePreventDelete'); 

	if (Trigger.isInsert || Trigger.isUpdate) {
		if (DealerTradeIntegrity==null || DealerTradeIntegrity.Enabled__c==true) new VehicleTransfer(Trigger.new).DealerTradeIntegrity(Trigger.oldMap);
		if (DealerTradeStatusChange==null || DealerTradeStatusChange.Enabled__c==true) new VehicleTransfer(Trigger.new).DealerTradeStatusChange(Trigger.oldMap);
	}
	
	if (Trigger.isDelete) {
		if (DealerTradePreventDelete==null || DealerTradePreventDelete.Enabled__c==true) new VehicleTransfer(Trigger.new).DealerTradePreventDelete(Trigger.oldMap);
	}

}