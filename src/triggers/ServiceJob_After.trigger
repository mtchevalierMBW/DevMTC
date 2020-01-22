/**
 * ServiceJob_After
 * Tested by: ServiceRepairOrder2_TC
 *
 * Coverage:
 *	2018-12-18	95%	(47/49)
 *
 * Updates service repair order with flag to indicate whether it's a get-ready repair order or not.
 *
 *	2015-09-04	B. Leaman	BLL1 - Set GetReady_RO__c flag on service repair order based on line payment method GRNV, GRUV
 *	2016-07-18	B. Leaman	BLL2 - Similar flag for MCEO (Commercial added equipment) that adds to vehicle conversion cost.
 *	2016-11-02	B. Leaman	BLL3 - Allow to fail if we're unable to update the RO GetReady or Commercial Equipment flags.
 *  2017-11-02  J. Kuljis   JVK1 - Update parts invoice lines in after context for payment method changes on the job line
 *  2018-10-18	B. Leaman	W-000461	BLL4	Reduce SOQL query count.
 *	2018-12-17	B. Leaman	W-000530	BLL5	Fix issues setting GetReady and CommEquipment flags.
 *	2019-12-18	B. Leaman	W-000788 BLL6 - Move to ServiceProcess handler & merge into ServiceJobLineControl trigger.
 */
trigger ServiceJob_After on dealer__Service_Job__c (after delete, after insert, after update) {

	// BLL6
//	if (Trigger.isAfter) ServiceProcess.SetGetReadyROFlags(Trigger.isDelete ? Trigger.old : Trigger.new);
	// BLL6 end

//    // List of affected service repair order Ids (from service job lines)
//    Set<Id> sroIds = new Set<Id>(); 
//    // List of affected service repair orders
//    List<dealer__Service_Repair_Order__c> sros = new List<dealer__Service_Repair_Order__c>();
//    // List of affected service repair orders that have a GRNV or GRUV line
//    Set<Id> getRdyIds = new Set<Id>();
//    Set<Id> commConvIds = new Set<Id>(); // BLL2a 
//    // List of service repair orders needing a change to the "getReady" flag	// BLL2c or commConv flag
//    List<dealer__Service_Repair_Order__c> updsros = new List<dealer__Service_Repair_Order__c>();
//
//	// BLL5
//	Set<String> commEquipPmtMthds = new Set<String>{'MCEO'};
//	Set<String> getReadyPmtMthds = new Set<String>{'GRNV','GRUV'};
//	Set<String> pmtMethodNames = new Set<String>();
//	pmtMethodNames.addAll(commEquipPmtMthds);
//	pmtMethodNames.addAll(getReadyPmtMthds);
//	// BLL5 end
//
//    for (dealer__Service_Job__c j : (Trigger.isDelete ? Trigger.Old : Trigger.New)) {
//   	    // BLL4 - only need to check again if is new or deleted job line or payment method changed 
//           //sroIds.add(j.dealer__Service_Repair_Order__c);
//           if (Trigger.isDelete || Trigger.isInsert) sroIds.add(j.dealer__Service_Repair_Order__c);
//           //if (Trigger.isUpdate && Trigger.oldMap.get(j.Id).Payment_Method__r!=j.Payment_Method__r) sroIds.add(j.dealer__Service_Repair_Order__c);
//           if (Trigger.isUpdate && Trigger.oldMap.get(j.Id).Payment_Method__c!=j.Payment_Method__c) sroIds.add(j.dealer__Service_Repair_Order__c);
//        // BLL4 end
//    }
// 
//    // Build list of Service Repair Orders affected 
//    // BLL4 - only query if there is something to select
//    // sros = [select Id, GetReady_RO__c, CommercialConversionEquip__c from dealer__Service_Repair_Order__c where Id in :sroIds];	// BLL2c add CommercialConversionEquip__c
//    if (sroIds.size()>0) {
//        sros = [select Id, GetReady_RO__c, CommercialConversionEquip__c from dealer__Service_Repair_Order__c where Id in :sroIds];
//    // BLL4 end
//    // Build set of those service repair orders that have a GRNV or GRUV line
//		// BLL5
//        //for (dealer__Service_Job__c l : [
//        //        select dealer__Service_Repair_Order__c, Payment_Method__r.Name	// BLL2c add Payment_Method__r.Name
//        //        from dealer__Service_Job__c 
//        //        where dealer__Service_Repair_Order__c in :sroIds 
//        //        and Payment_Method__r.Name in ('GRNV','GRUV','MCEO')]) {	// BLL2c add MCEO
//        for (dealer__Service_Job__c l : [
//                select dealer__Service_Repair_Order__c, Payment_Method__r.Name	// BLL2c add Payment_Method__r.Name
//                from dealer__Service_Job__c 
//                where dealer__Service_Repair_Order__c in :sroIds 
//                and Payment_Method__r.Name in :pmtMethodNames]) {	// BLL2c add MCEO
//            //if (l.Payment_Method__r.Name=='MCEO') commConvIds.add(l.dealer__Service_Repair_Order__c);	// BLL2a
//			if (commEquipPmtMthds.contains(l.Payment_Method__r.Name)) commConvIds.add(l.dealer__Service_Repair_Order__c);
//            //else getRdyIds.add(l.dealer__Service_Repair_Order__c);	// BLL2c add "else"
//			if (getReadyPmtMthds.contains(l.Payment_Method__r.Name)) getRdyIds.add(l.dealer__Service_Repair_Order__c);
//        }
//		// BLL5 end
//    // BLL4a
//    }   
//    // BLL4a end
//
//    // Update any SROs whose "getReady" flag needs to change
//    for (dealer__Service_Repair_Order__c sro : sros) {
//    	boolean updateRO = false;
//    	if (sro.GetReady_RO__c==true && !getRdyIds.contains(sro.Id)) {
//    		sro.getReady_RO__c = false;
//    		updateRO = true;
//    		//BLL2d updsros.add(sro);
//    	} else if (sro.GetReady_RO__c==false && getRdyIds.contains(sro.Id)) {
//    		sro.getReady_RO__c = true;
//    		updateRO = true;
//    		//BLL2d updsros.add(sro);
//    	}
//    	// BLL2a
//    	if (sro.CommercialConversionEquip__c==true && !commConvIds.contains(sro.Id)) {
//    		sro.CommercialConversionEquip__c = false;
//    		updateRO = true;
//    	} else if (sro.CommercialConversionEquip__c==false && commConvIds.contains(sro.Id)) {
//    		sro.CommercialConversionEquip__c = true;
//    		updateRO = true;
//    	}
//    	if (updateRO) updsros.add(sro);
//    	// BLL2a end
//    } 
//    if (updsros.size()>0) {
//    	System.debug('Have ' + String.valueOf(updsros.size()) + ' ROs to update getready or commercialconversion flag');
//		//BLL3d Database.DMLOptions dml = new Database.DMLOptions();
//		//BLL3d dml.optAllOrNone = false;   
//		//BLL3d Database.update(updsros, dml);
//		Database.update(updsros);	// BLL3a
//    }

    // If After Update,Insert process Parts Line Payment types
    // BLL4 - there cannot be any related parts lines on a newly-inserted job line yet
    //if(Trigger.isInsert || Trigger.isUpdate) {
//    if(Trigger.isAfter && Trigger.isUpdate) {
    // BLL4
//		ServiceProcess.UpdatePayTypes(Trigger.new);
//        Map<Id, dealer__Service_Job__c> jobMap = new Map<Id, dealer__Service_Job__c>();
//        for (dealer__Service_Job__c j : Trigger.New)  jobMap.put(j.Id, j);
//        
//        // Get associated Parts Lines
//		List<dealer__Parts_Invoice_Line__c> pils = [SELECT ID, dealer__Job_Line__c, dealer__Pay_Type__c 
//                                            	FROM dealer__Parts_Invoice_Line__c 
//                                            	WHERE dealer__Job_Line__c IN:jobMap.keySet()];
//       
//        
//        List<dealer__Parts_Invoice_Line__c> updateLines = new List<dealer__Parts_Invoice_Line__c>();
//        if(!pils.isEmpty()) {
//            for(dealer__Parts_Invoice_Line__c pil : pils) {
//				
//				if(pil.dealer__Pay_Type__c != jobMap.get(pil.dealer__Job_Line__c).dealer__Labor_Type__c) {
//                    updateLines.add(new dealer__Parts_Invoice_Line__c( Id=pil.Id,
//                        dealer__Pay_Type__c=jobMap.get(pil.dealer__Job_Line__c).dealer__Labor_Type__c
//                    ));
//                }   
//            }
//        }
//                
//        if(!updateLines.isEmpty()) update updateLines;

//    }

}