/**
*   Accounting Integration Email Service
*       This class processes messages sent by various transaction 
*       screens.  The payload should consist of a record ID, Org ID, RequestedBy, action
*
*       
*           recordId    -   Source transaction record to be processed
*           orgId       -   OrgId of the source email, Check to ensure we are processing for the right org.
*           requestedBy -   Posting user of the transaction
*           action      -   Enumeration of the supported payloads
*
*           ffaccountingintegration@q-2e28pdknj7nllnhyxdw9gw0regfornty1a347z58hczf72ts3w.w-8wanjmay.cs13.apex.sandbox.salesforce.com
*           
* Tested by: AccountingEmailService_TC
* 
*   2015-12-31  B. Leaman   BLL1 Add support for rental agreements, re-organize if statements to increase coverage%      
*   2016-02-19  RedTeal     RT1   - Accept Vehilce POs now done asynchronously
*   2016-06-01  B. Leaman   BLL2 Add Vehicle Transfers (dealer trades)
*   2016-08-23  J. Kuljis   JVK1 - Add parttransfer support
*   2016-10-26  J. Kuljis   JVK2 - Update parttransfer to include commit / reversal
*	2016-12-01	B. Leaman	BLL3a - Log failure to trigger email message; consolidate code to improve coverage%.
*	2018-03-19	B. Leaman	BLL4a - add vehicle flooring actions and "details" payload string for more generalized handling of specific processes.
*	2018-08-08	B. Leaman	BLL5a - payable invoice interface from Concur
*   2019-02-06  J. Kuljis	W-000575 BLL6 - not using: JVK3 - add cashier_entry method to support recording of cash entry records directly from cashier events. 
*	2019-09-19	B. Leaman	W-000756 BLL7 - Physical inventory posting
*/
global class AccountingEmailService implements Messaging.InboundEmailHandler {
  global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
      Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
      Set<String> ActionSkipRegister = new Set<String>{'outbound_trade','inbound_trade','outbound_intercomp_trade','inbound_intercomp_trade','depreciate_rental',
      		'vehicle_floored', 'vehicle_curtailment', 'vehicle_payoff'	// BLL4a
      	};

        // If Message was opened succesfully
        if(result.success) {
            String emailBody = email.plainTextBody;

			try {	// BLL3a
            
             //BLL3d if(email.Subject.indexOf('Asyncnronous Processing Request - Depreciation') != -1){
                
                //BLL3d String[] emailLines = emailBody.split('\\~');
                
                //BLL3d for(String item : emailLines){
                    
                    //BLL3d system.debug('MARINERTEK ITEM: ' + item);

                    //BLL3d try{
                    //BLL3d    AccountingPayload a = (AccountingPayload)JSON.deserializeStrict(item, AccountingPayload.class);
                    //BLL3d    if (a.action=='depreciate_rental') { FFAccounting.depreciateRental(a.recordId, a.vehicleIds) ; }
                        
                    //BLL3d }catch(JSONException e) { throw new AESException('Error processing payload '+item+' | ' + e.getMessage());
                    //BLL3d } catch(DmlException e) { throw new AESException('Error processing payload '+item+' | ' + e.getMessage());
                    //BLL3d } catch(Exception e) { throw new AESException('Error processing payload '+item+' | ' + e.getMessage());              
                    //BLL3d }
                //BLL3d }
             //BLL3d }
             //BLL3d else{
                // Open the payload and check the contents.
                try {
                    System.debug(email.plainTextBody);
                    
                    AccountingPayload a = (AccountingPayload)JSON.deserializeStrict(email.plainTextBody, AccountingPayload.class);
                    
                    // Perform Org Validation
                    if(!orgValid(a.orgId)) { throw new AESException('Org ID incorrect for the following payload '+email.plainTextBody); }
    
                    // BLL2a - Dealer Trades (Vehicle transfers)
                    if (a.action=='outbound_trade') new VehicleTransfer(new Set<Id>{a.recordId}).createOutboundTradeJournals();
                    if (a.action=='inbound_trade')  new VehicleTransfer(new Set<Id>{a.recordId}).createInboundTradeJournals();
                    if (a.action=='outbound_intercomp_trade')    new VehicleTransfer(new Set<Id>{a.recordId}).createOutboundIntercompanyJournals();
                    if (a.action=='inbound_intercomp_trade') new VehicleTransfer(new Set<Id>{a.recordId}).createInboundIntercompanyJournals();
                   	if (a.action=='depreciate_rental') { FFAccounting.depreciateRental(a.recordId, a.vehicleIds, a.emailRecipient) ; }

					// Flooring updates - BLL4a
					if (a.action == 'vehicle_floored') { VehicleFlooring_CTRL.CreateAndPostJournal('floored', a.emailRecipient, a.details);}
					if (a.action == 'vehicle_curtailment') {VehicleFlooring_CTRL.CreateAndPostJournal('curtailment', a.emailRecipient, a.details);}
					if (a.action == 'vehicle_payoff') {VehicleFlooring_CTRL.CreateAndPostJournal('payoff', a.emailRecipient, a.details );}
					// BLL4a end

                    if (ActionSkipRegister.contains(a.action)) return result;   // Skip invoice register for this transaction
                    // BLL2a end
                    // Rental Depreciation - BLL3 moved here from separate section from when payload was going to be a list of payloads 
    
                    // Log to Invoice Register
                    createInvoiceRegister(a.recordId);
    
                    // Process Repair Order
                    if(a.action == 'service_repair_order_post') { FFA_ServiceDepartment.postRepairOrder(a.recordId); }
                    if(a.action == 'service_repair_order_reverse') { FFAccounting.reverseServiceRepairOrder(a.recordId); }
 
					/*-----------------		PURCHASE ORDER METHODS		----------------*/
                    if(a.action == 'parts_receipt') { FFAccounting.receivePartsFromPO(a.recordId, a.partsReceiptValue); }                   
                    if(a.action == 'purchase_order_sublet') { FFAccounting.receiveSubletPO(a.recordId); }
                    if(a.action == 'purchase_order_misc') { FFAccounting.receiveMiscPO(a.recordId); }
                    if(a.action == 'accept_purchase_order') { FFAccounting.acceptVehiclePurchaseOrder(a.recordId); }
                    if(a.action == 'create_payable_invoices') { FFAccounting.createPayableInvoices(a.details, a.emailRecipient);}	// BLL5a
					// BLL
					if(a.action == 'reverse_sublet_po') { FFAccounting.reverseSubletPurchaseOrder(a.recordId); }
					// BLL end
                    
					/*-----------------		PARTS TRANSFERS 	-----------------*/
                    if(a.action == 'parttransfer_post') { FFAccounting.receiveTransferPO(a.recordId); } //JVK1 - Deprecated
                    if(a.action == 'partsTransferRequest') { FFAccounting.commitTransferPO(a.recordId); } //JVK2 - Committed Status
                    if(a.action == 'partsTransferReverse') { FFAccounting.reverseTransferPO(a.recordId); } //JVK2 - Reversed Status

					// BLL7
					// Physical inventory variance
					if (a.action == 'parts_physical_variance') {FFAccounting.partsPhysicalVariance(a.recordId, a.partsReceiptValue); }
					// BLL7 end

					/*-----------------		PARTS QTY ADJUSTMENT 	----------------*/
                    if(a.action == 'parts_quantity_adjustment') { FFAccounting.adjustPartsInventory(a.recordId, a.partsReceiptValue); }
    
                    // Parts Returns
                    if(a.action == 'parts_return_to_vendor') { FFA_ServiceDepartment.postPartsReturn(a.recordId); }
              
                    // Rental agreements - BLL1a
                    if (a.action == 'rental_agreement_post') { FFA_RentalDepartment.postRental(a.recordId); }

                    //JVK3
                    // Cashier Object related events
                    //if (a.action == 'cashier_entry') { AccountingInterface.createReceiptFromCashierRecord(a.recordId); }
                    // JVK3 End

                } catch(JSONException e) { throw new AESException('Error processing payload '+email.plainTextBody+' | ' + e.getMessage());
                } catch(DmlException e) { throw new AESException('Error processing payload '+email.plainTextBody+' | ' + e.getMessage());
                } catch(Exception e) { throw new AESException('Error processing payload '+email.plainTextBody+' | ' + e.getMessage());              
                }
             //BLL3d }
            // BLL3a 
            } catch(Exception e) {
                String errorMsg = 'Failed to process Asynchronous Posting request.\n' + e.getMessage();
                System.debug(errorMsg);
                Error_Log__c log = new Error_Log__c();
                log.trace__c = errorMsg;
                insert log; 
            }
            // BLL3a end
        } 

        return result;
  }

  /*
  *
  * validate the orgId passed by the email payload is the same as the processing org
  *
  */
  public Boolean orgValid(String orgId) {
    //BLL3d if(orgId != UserInfo.getOrganizationId()) {
    //BLL3d     return false;
    //BLL3d }
    //BLL3d return true;
    return (orgId == UserInfo.getOrganizationId());	// BLL3a
  }

  global class AccountingPayload {
    public String recordId {get;set;}
    public String orgId {get;set;}
    public Id requestedBy {get;set;}
    public String action {get;set;}
    public Decimal partsReceiptValue {get;set;}
    public String vehicleIds {get;set;}
    public String emailRecipient {get;set;}
    public String details {get;set;}	// BLLxa
  }

  /**
   * [createInvoiceRegister description]
   * @param  recordId [description]
   * @return          [description]
   */
  @testVisible
  global Boolean createInvoiceRegister(Id recordId) {
  		boolean rtnOk = false;	// BLL3a
        try {
            // insert new InvoiceRegister__c(RecordId__c=recordId);
            //BLL3d return true;
            rtnOk = true;
        } Catch(DmlException e) { }	// BLL3c close exception -- no additional action needed
            //BLL3d return false;
        //BLL3d }

        // BLL3d return false;
        return rtnOk;	// BLL3a
  }

  global class AESException extends Exception {}
}