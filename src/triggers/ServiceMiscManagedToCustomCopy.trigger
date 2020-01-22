/**
 * created by DealerTeam to assist the logical transition of records created in the managed interface to the custom RO Screen.
 
 * Tested by: ServiceRepairOrder2_TC
 *	
 *	Coverage:
 *	2018-04-06	100% (6/6)
 *
 *  Modifications:
 *  2018-11-14  B. Leaman   W-000477  BLL1 - Update misc charge line with tech time or part creator id
 * 
 */
// BLL1
//BLL1d trigger ServiceMiscManagedToCustomCopy on dealer__Service_Misc_Charge__c (after insert, after update, after delete) {
trigger ServiceMiscManagedToCustomCopy on dealer__Service_Misc_Charge__c (before insert, after insert, after update, after delete) {
// BLL1

  // BLL1
  if (Trigger.isBefore && Trigger.isInsert) {
      ServiceMiscChargeController.LinkMiscChgToCreator(Trigger.new);
  }
  // BLL1

  // BLL1
  if (Trigger.isAfter) {
  // BLL1
      /* Copy rows created in the Managed Misc. Charge Table to the Custom Table */
      if(Trigger.isInsert) {
      	ServiceMiscChargeController.insertNewRows(Trigger.new);
      }

      if(Trigger.isUpdate) {
        ServiceMiscChargeController.updateExistingRows(Trigger.new);
      }

      if(Trigger.isDelete) {
     		ServiceMiscChargeController.deleteRemovedRows(Trigger.old);
      }
  // BLL1
  }
  // BLL1

}