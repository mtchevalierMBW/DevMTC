trigger EstimateUpdateRO on Estimate_Approval__c (after insert, after update, after delete) {
	if(Trigger.size==1) {  // Trigger not bulkfied to prevent govenor limits from being reached.
		if(Trigger.isInsert || Trigger.isUpdate) {
			Decimal eVal = 0;
			AggregateResult[] sumAmount = [Select SUM(Approved_Amount__c) asum FROM Estimate_Approval__c 
											where Service_Repair_Order__c =:trigger.new[0].Service_Repair_Order__c ];
			eVal = (decimal) sumAmount[0].get('asum');
			// Get Repair Order and Set value
			dealer__Service_Repair_Order__c ro = [select Id from dealer__Service_Repair_Order__c 
													where Id=:Trigger.new[0].Service_Repair_Order__c limit 1];

			if(eVal==null) {eVal=0;}
			ro.dealer__Estimate__c = eVal;

			update ro;
		}

		if(Trigger.isDelete) {
			Decimal eVal = 0;
			AggregateResult[] sumAmount = [Select SUM(Approved_Amount__c) asum FROM Estimate_Approval__c 
											where Service_Repair_Order__c =:trigger.old[0].Service_Repair_Order__c ];
			eVal = (decimal) sumAmount[0].get('asum');
			// Get Repair Order and Set value
			dealer__Service_Repair_Order__c ro = [select Id from dealer__Service_Repair_Order__c 
													where Id=:Trigger.old[0].Service_Repair_Order__c limit 1];

			if(eVal==null) {eVal=0;}
			ro.dealer__Estimate__c = eVal;

			update ro;
		}
	}
}