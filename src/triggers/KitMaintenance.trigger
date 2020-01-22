/**
KitMaintenance
Tested by: KitProcess_TEST

2015-11-10   RT1 - dealer__Kit_Price__c now updated to eqaul the dealer__Kit_Cost__c field
2019-08-13	W-000729 BLL1 Refactor to helper class; new support for conversion packages;
**/

trigger KitMaintenance on dealer__Parts_Kit__c (before insert, before update) {

	if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        MW_TriggerControls__c uploadHelper = MW_TriggerControls__c.getInstance('uploadPartKitHelper');
        if (uploadHelper==null || uploadHelper.Enabled__c) KitProcess.uploadHelper(Trigger.New);

		KitProcess.setCostAndPrice(Trigger.New);
		KitProcess.ConversionKitRecordType(Trigger.New);
		KitProcess.ConversionKitDefaultCalcs(Trigger.New, Trigger.oldMap);
	}

//	for(dealer__Parts_Kit__c pk : Trigger.new) {
//		// Roll-Up fields fire the parent record to save
//		if(pk.dealer__Item_Count__c>0) {
//			pk.Parts_Cost__c = pk.dealer__Kit_Cost__c;
//            pk.dealer__Kit_Price__c = pk.dealer__Kit_Cost__c;//RT1
//		}
//
//		if(pk.CMC_Price__c==null) 
//			pk.CMC_Price__c=0;
//	}

}