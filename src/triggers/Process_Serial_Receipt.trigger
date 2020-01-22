/*  Process Serial Receipt - JPritt 6/7/2017 
     Uses MW_TriggerControls__c custom list settings : Rootstock_Serial_Inventory_Receipts
*/

trigger Process_Serial_Receipt on rstk__icitemsrl__c(before insert, before update, after insert, after update) {

  MW_TriggerControls__c Rootstock_Serial_Inventory_Receipts = MW_TriggerControls__c.getInstance('Rootstock_Serial_Inventory_Receipts');
      if (Rootstock_Serial_Inventory_Receipts==null || Rootstock_Serial_Inventory_Receipts.Enabled__c) {

   SerialInvProcess SIP=new SerialInvProcess();


   if (Trigger.isBefore) {   
     SIP.copyChassisDataToReceipt(Trigger.New);     
   } // end-if trigger.isBefore
 
  
   if (Trigger.isAfter) {
     SIP.LinkChassisToFirstInvRec(Trigger.New);  
   }
  
 } 
} // end trigger