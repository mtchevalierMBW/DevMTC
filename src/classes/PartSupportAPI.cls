/**
* PartSupportAPI
* Tested by: PartSupportAPITest
*
* Coverage:
*	2018-10-15	35%	(115/325) (qa & production, less in dev because of no data)
*   2018-11-12  70% (230/325)
*	2019-10-15	86% (251/289)
*
* Modifications:
*   2018-11-12  B. Leaman   W-000485    BLL1 Fix part cost calculation; also improve code coverage;
* 	2018-11-12  J. Kuljis   W-000485    JVK1 Update part price, cost and total values based on data append flow
*   2018-11-19  JK / BL     W-000491    JVK2 With DTv4.14.5 setInternalWarrantyPartsToCost now only needs to set price to cost
* 	2019-04-05	B. Leaman	W-000625	BLL2 - Freeze part pricing for warranty (once authorized? or from estimates?)
*	2019-10-15	B. Leaman	W-000739 BLL3 - improve code coverage.
**/

public class PartSupportAPI {

    /**
     * cleanLedger corrects the association of Purchase Order Lines with their corresponding service invoice lines
     * This code is a second level of corrective code to ensure any transactions that result in an out of order 
     * sequence are corrected.
     */
    public static void cleanLedger(Id partId) {
        
        // Get the list of PO / Sale Lines
        List<dealer__Parts_Ledger__c> ledgers = [SELECT Id, Name, dealer__Purchase_Order__c, dealer__Repair_Order_Line__c,
                                                        dealer__Parts_Sale_Line__r.Name,
                                                        dealer__Parts_Sale_Line__r.dealer__Purchase_Order__c, 
                                                        dealer__Parts_Sale_Line__c, 
                                                        dealer__Parts_Sale_Line__r.dealer__Purchase_Order_Line__c,
                                                        dealer__Parts_Sale_Line__r.dealer__Purchase_Order_Line__r.dealer__Amount__c,
                                                        dealer__Parts_Sale_Line__r.dealer__Purchase_Order_Line__r.dealer__Purchase_Order_Accepted_Date__c,
                                                        dealer__Parts_Sale_Line__r.dealer__Purchase_Order_Line__r.dealer__Purchase_Order__c,
                                                        dealer__Parts_Sale_Line__r.dealer__Purchase_Order_Line__r.Received_By__c, 
                                                        dealer__Parts_Sale_Line__r.dealer__Purchase_Order_Line__r.dealer__Part_Quantity_Outstanding__c,
                                                        dealer__Item_Value__c
                                                    FROM dealer__Parts_Ledger__c 
                                                    WHERE dealer__Part__c =:partId];
        
        List<dealer__Parts_Ledger__c> ledgerUpdate = new List<dealer__Parts_Ledger__c>();
        Map<Id, dealer__Parts_Ledger__c> ledgerByInvoiceId = new Map<Id, dealer__Parts_Ledger__c>();
        for(dealer__Parts_Ledger__c ll : ledgers) {
            if(ll.dealer__Parts_Sale_Line__c != null 
                && ledgerByInvoiceId.get(ll.dealer__Parts_Sale_Line__c) ==null) {
                    ledgerByInvoiceId.put(ll.dealer__Parts_Sale_Line__c, ll);
            }
        }
        
        Set<Id> poRemovalIds = new Set<Id>();
        
        for(dealer__Parts_Ledger__c ll : ledgers) {
            
            // Do we have a linked Purchase Order to the Part Sale Line
            if(ll.dealer__Parts_Sale_Line__r.dealer__Purchase_Order__c!=null
                && (ll.dealer__Parts_Sale_Line__r.dealer__Purchase_Order_Line__r.dealer__Purchase_Order__c != ll.dealer__Purchase_Order__c)
              	&& ll.dealer__Parts_Sale_Line__r.dealer__Purchase_Order_Line__r.dealer__Purchase_Order_Accepted_Date__c!=null
                && ll.dealer__Parts_Sale_Line__r.dealer__Purchase_Order_Line__r.dealer__Part_Quantity_Outstanding__c == 0) {
                    // Here are the missmatched PO Lines
                    System.debug(ll.dealer__Parts_Sale_Line__r.dealer__Purchase_Order__c +' '+ll.dealer__Parts_Sale_Line__r.dealer__Purchase_Order_Line__r.dealer__Purchase_Order__c +' '+ll.dealer__Purchase_Order__c);
                    System.debug(ledgerByInvoiceId.get(ll.dealer__Parts_Sale_Line__c));
                    
                    if(ledgerByInvoiceId.get(ll.dealer__Parts_Sale_Line__c)!=null) {
                        
                        // Ledger Update
                        // ll.dealer__Parts_Sale_Line__c=ledgerByInvoiceId.get(ll.dealer__Parts_Sale_Line__c).Id;
                        ll.dealer__Transaction_Note__c=ll.dealer__Parts_Sale_Line__r.dealer__Purchase_Order__c+' received;Sold on '+ll.dealer__Parts_Sale_Line__r.Name;
                        ll.dealer__Quantity__c=0;
                        ll.dealer__Purchase_Order__c=ll.dealer__Parts_Sale_Line__r.dealer__Purchase_Order_Line__r.dealer__Purchase_Order__c;
                        ll.dealer__Item_Value__c=ll.dealer__Parts_Sale_Line__r.dealer__Purchase_Order_Line__r.dealer__Amount__c;
                        ll.dealer__Purchased_By__c=ll.dealer__Parts_Sale_Line__r.dealer__Purchase_Order_Line__r.Received_By__c;
                        ledgerUpdate.add(ll); 
                        
                        if(!poRemovalIds.contains(ll.dealer__Parts_Sale_Line__r.dealer__Purchase_Order_Line__r.dealer__Purchase_Order__c)) {
                            poRemovalIds.add(ll.dealer__Parts_Sale_Line__r.dealer__Purchase_Order_Line__r.dealer__Purchase_Order__c);
                        }
                    }
                }
        }
        
        List<dealer__Parts_Ledger__c> ledgerDeletion = [SELECT Id, Name FROM dealer__Parts_Ledger__c WHERE dealer__Purchase_Order__c IN:poRemovalIds AND dealer__Parts_Sale_Line__c = NULL];
                
        // Prepate Transaction
        //BLL3 Savepoint sp = Database.setSavepoint();
        
        //BLL3 try {
            if(!ledgerUpdate.isEmpty()) update ledgerUpdate;
            
            if(!ledgerDeletion.isEmpty()) delete ledgerDeletion;
            
            /*
            if(!PartSupportAPI.onHandMatched(partId)) {
                database.rollback(sp);
                throw new PartSupportAPIException('On-Hand and Physical On-Hand do not match');
            }
			*/
            
        //BLL3 } Catch(DmlException e) {
        //BLL3     database.rollback(sp);
        //BLL3     throw new PartSupportAPIException(e.getMessage());
        //BLL3 }
    }
         
	@InvocableMethod(label='Purchase Order Ledger Assignment' description='Set the Purchase Order Line against the corresponding negative sale.')
    public static void setLedgerAssignment(List<dealer__Purchase_Order_Line__c> poLines) {
        for(dealer__Purchase_Order_Line__c pol : poLines) {
            if(pol.dealer__Part__c != null 
               && pol.dealer__Purchase_Order_Accepted_Date__c != null) {
                   PartSupportAPI.cleanLedger(pol.dealer__Part__c);
               }
        }
    }
    
    /**
     * Method to move parts on hand from one master to another
     */
    public static void migrateOnHand(Id oldMasterId, Id newMasterId) {
       
		//BLL3 SavePoint sp = Database.setSavepoint();
        
        // Get New Master Def
		dealer__Parts_Master__c pm = [SELECT dealer__Applications__c, dealer__Core_Required__c, dealer__Core_Value__c, dealer__Cost__c, 
                                      		dealer__Height__c, dealer__Jobber_Price__c, dealer__Labor_Time__c, dealer__Length__c, 
                                      		dealer__MAP__c, dealer__MFG_Comments__c, dealer__Manufacturer__c, dealer__Pack_QTY__c, 
                                      		dealer__Part_Description__c, dealer__Part_No_Display__c, dealer__Part_No__c, 
                                      		dealer__Price_Tape_Date__c, dealer__Raw_Part_Number__c, dealer__Retail_Price__c, 
                                      		dealer__Return_Code__c, dealer__UPC__c, dealer__Warranty_Price__c, dealer__Weight__c, 
                                      		dealer__Width__c, dealer__Catalog_Image__c, Id, Name 
                                      	FROM dealer__Parts_Master__c 
                                      	where Id=:newMasterId limit 1];
        
        // Get all old parts with onhand
        List<dealer__Parts_Inventory__c> oldInventory = [SELECT Id, dealer__On_Hand__c, dealer__Location__c, dealer__Part_No__c ,
                                                         		(SELECT Id, dealer__Quantity__c, dealer__Item_Value__c,
                                                                 		dealer__Entry_Date__c, dealer__Transaction_Note__c  
                                                                 	FROM dealer__Parts_Ledgers__r)
                                                         	FROM dealer__Parts_Inventory__c 
                                                         	WHERE dealer__Parts_Master__c =:oldMasterId
                                                        	AND dealer__On_Hand__c > 0];
        
		// Identify new Parts
        Map<Id, dealer__Parts_Inventory__c> newInvMap = new Map<Id, dealer__Parts_Inventory__c>();  // LocId
		List<dealer__Parts_Inventory__c> newInventory = [SELECT Id, Name, dealer__On_Hand__c, dealer__Location__c , dealer__Part_No__c 
                                                            	FROM dealer__Parts_Inventory__c 
                                                         		WHERE dealer__Parts_Master__c =:newMasterId];	
        for(dealer__Parts_Inventory__c ni : newInventory) {
            newInvMap.put(ni.dealer__Location__c, ni);
        }
        
        // Set old ledgers and new ledger lists
        List<dealer__Parts_Ledger__c> oldLedger = new List<dealer__Parts_Ledger__c>();
        List<dealer__Parts_Ledger__c> newLedger = new List<dealer__Parts_Ledger__c>();
        List<dealer__Parts_Inventory__c> updateInventoryList = new List<dealer__Parts_Inventory__c>();

        // Create History for Tracking of Chages 
        List<dealer__Part_Inventory_History__c> outHistory = new List<dealer__Part_Inventory_History__c>();
        List<dealer__Part_Inventory_History__c> inHistory = new List<dealer__Part_Inventory_History__c>();
        
        // String for email report
		String attachmentFile = 'The following Ledger items have been re-assigned durring the Part Migration for Master '+pm.Name+'\r\n';
        		attachmentFile += 'Old Record,Existing Item Value,Existing Quantity,New Record,Item Value\r\n';
        
        // Iterate the old parts
        for(dealer__Parts_Inventory__c pi : oldInventory) {
            // Does part exist in new ID?
			dealer__Parts_Inventory__c newRecord = new dealer__Parts_Inventory__c();
            if(newInvMap.get(pi.dealer__Location__c)==null) {
                // Create Part
				newRecord = PartSupportAPI.createPartFromMaster(pi.dealer__Location__c, pm);
            } else {
                newRecord = newInvMap.get(pi.dealer__Location__c);
                newRecord.dealer__Parts_Master__c=pm.Id;
            }

            Decimal valueTransfer = 0;
            
            // Iterate the ledger list
            for(dealer__Parts_Ledger__c ll : pi.dealer__Parts_Ledgers__r) {
                if(ll.dealer__Quantity__c>0) {
                    dealer__Parts_Ledger__c newL = new dealer__Parts_Ledger__c();
                    ll.dealer__Transaction_Note__c += (ll.dealer__Transaction_Note__c != null && ll.dealer__Transaction_Note__c.right(1)==';') ? ';On-Hand migrated to new Part# '+newRecord.dealer__Part_No__c : 'On-Hand migrated to new Part# '+newRecord.dealer__Part_No__c; 
                    ll.dealer__Quantity__c = 0;
                    oldLedger.add(ll);
                    
                    newL.dealer__Part__c = newRecord.Id;
                    newL.dealer__Quantity__c=1;
                    newL.dealer__Item_Value__c=ll.dealer__Item_Value__c;
                    newL.dealer__Transaction_Note__c = 'On-Hand migrated from Part# '+pi.dealer__Part_No__c; 
                    newLedger.add(newL);
                    valueTransfer += ll.dealer__Item_Value__c;
                    
                    attachmentFile += pi.dealer__Part_No__c+','+newL.dealer__Quantity__c+','+ll.dealer__Item_Value__c+','+newRecord.dealer__Part_No__c+','+newL.dealer__Item_Value__c+'\r\n'; 
                }
            }            
            
            newRecord.dealer__On_Hand__c = (newRecord.dealer__On_Hand__c==null) ? pi.dealer__On_Hand__c : pi.dealer__On_Hand__c + newRecord.dealer__On_Hand__c;
            
            // Set History Tracking 
            outHistory.add(new dealer__Part_Inventory_History__c(
                                    dealer__Part__c=pi.Id, 
                                    dealer__Quantity_Adjustment__c=(pi.dealer__On_Hand__c*-1), 
                                    dealer__Transaction_Time__c=DateTime.now(), 
                                    dealer__Transaction_Event__c='Migrate On-Hand',
                                    dealer__Units_Relieved__c=pi.dealer__On_Hand__c,
                                    dealer__Value_Relieved__c=valueTransfer
                                )
                            );
            inHistory.add(new dealer__Part_Inventory_History__c(
                                    dealer__Part__c=newRecord.Id, 
                                    dealer__Quantity_Adjustment__c=pi.dealer__On_Hand__c, 
                                    dealer__Transaction_Time__c=DateTime.now(), 
                                    dealer__Transaction_Event__c='Migrate On-Hand'
                                )
                            );

            pi.dealer__On_Hand__c = 0;
            pi.dealer__Status__c = 'Obsolete';
            
        	updateInventoryList.add(newRecord);
            updateInventoryList.add(pi);
            
            System.debug(newRecord);
            System.debug(pi);
        }
        
        //BLL3 try {
            
			Attachment attach = new Attachment();
            Blob body = Blob.valueOf(attachmentFile);
            attach.Body = body;
            attach.Name = 'MasterMigrateAuditRecord.csv';
            attach.IsPrivate = false;
            attach.parentid = newMasterId;
            attach.ContentType = 'text/csv';
            insert attach;           
            
            system.debug('New Record');
            system.debug(updateInventoryList);
            system.debug('New Ledger');
            System.debug(newLedger);
            system.debug('Old Ledger');
            System.debug(oldLedger);
            
            update updateInventoryList;
            insert newLedger;
            update oldLedger;

            insert inHistory;
            insert outHistory;

        //BLL3 } Catch(DmlException e) {
        //BLL3    database.rollback(sp);
        //BLL3    throw new PartSupportAPIException(e.getMessage());
        //BLL3 }
    }
    
    public static dealer__Parts_Inventory__c createPartFromMaster(Id locationId, dealer__Parts_Master__c pm) {
        
        	dealer__Dealer_Location__c loc = [SELECT Id, Name, dealer__Company_Number__c FROM dealer__Dealer_Location__c WHERE Id=:locationId LIMIT 1];
        
            dealer__Parts_Inventory__c newP = new dealer__Parts_Inventory__c(
                dealer__Parts_Master__c=pm.Id,
                dealer__Location__c=locationId,
                dealer__Part_No__c=loc.dealer__Company_Number__c+':'+pm.dealer__Part_No__c,
                dealer__Description__c=pm.dealer__Part_Description__c,
                dealer__MFG__c=pm.dealer__Manufacturer__c,
                dealer__Cost__c=pm.dealer__Cost__c,
                dealer__List__c=pm.dealer__Retail_Price__c,
                dealer__Pack_QTY__c=pm.dealer__Pack_QTY__c
            );  
        
        //BLL3 try {
            insert newP;
        //BLL3 } Catch(DmlException e) {
        //BLL3     throw new PartSupportAPIException(e.getMessage());
        //BLL3 }
        
        return newp;
    }
    
    /**
    When an Order Line is updated to include a parts line and a transfer line, map costs from the transfer line ledger to the part line ledger
    The cost of the parts line is updated instead this resolves a timing issue for month end.
    */
    public static void setLedgerItemsBasedOnTransferValue(List<dealer__Parts_Order__c> triggerList) {
        // 1) Evalute the Orders to capture items with Transfer Lines and Parts Invoice Lines
        Map<Id, dealer__Parts_Order__c> partsLinesToValidate = new Map<Id, dealer__Parts_Order__c>();
        Set<Id> invoiceLineIds = new Set<Id>();
        Set<Id> transferLineIds = new Set<Id>();
        Set<Id> lineIds = new Set<Id>();
        Map<Id, dealer__Parts_Invoice_Line__c> partLinesToUpdate = new Map<Id, dealer__Parts_Invoice_Line__c>();

        for(dealer__Parts_Order__c order : triggerList) {
            if(order.dealer__Parts_Line__c != null && order.dealer__Transfer_Line__c != null) {
                // Matched record
                partsLinesToValidate.put(order.dealer__Parts_Line__c, order);
                lineIds.add(order.dealer__Parts_Line__c);
                lineIds.add(order.dealer__Transfer_Line__c);
                transferLineIds.add(order.dealer__Transfer_Line__c);
                invoiceLineIds.add(order.dealer__Parts_Line__c);
            }
        }

        // 2) Inspect matched lines
        Map<Id, dealer__Parts_Ledger__c> invoiceLineLedgers = new Map<Id, dealer__Parts_Ledger__c>(); // Mapped by invoice line id
        Map<Id, List<dealer__Parts_Ledger__c>> mappedTransferLineLedgers = new Map<Id, List<dealer__Parts_Ledger__c>>();
        Map<Id, dealer__Parts_Invoice_Line__c> partInvoiceLineMap = new Map<Id, dealer__Parts_Invoice_Line__c>([SELECT Id, Name, dealer__Purchase_Order_Line__c FROM dealer__Parts_Invoice_Line__c WHERE Id IN:invoiceLineIds]);

        // 2.a) Check the parts invoice lines for consistancy
		for(dealer__Parts_Order__c order : triggerList) {
			//if(order.dealer__Parts_Line__c	!= null 
              //	&& partInvoiceLineMap.get(order.dealer__Parts_Line__c) != null
               	// && partInvoiceLineMap.get(order.dealer__Parts_Line__c).dealer__ ) {
                	   
               // }
        }
        
        // 2.b) inspect matched lines for transfer values
        for(dealer__Parts_Ledger__c pl : [SELECT Id, dealer__Parts_Sale_Line__c, dealer__Item_Value__c FROM dealer__Parts_Ledger__c WHERE dealer__Parts_Sale_Line__c IN:transferLineIds ]) {
            List<dealer__Parts_Ledger__c> ledgerList = (mappedTransferLineLedgers.get(pl.dealer__Parts_Sale_Line__c)!=null) ? mappedTransferLineLedgers.get(pl.dealer__Parts_Sale_Line__c) : new List<dealer__Parts_Ledger__c>();
            ledgerList.add(pl);
            System.debug(pl);
            mappedTransferLineLedgers.put(pl.dealer__Parts_Sale_Line__c, ledgerList);    
        }

        List<dealer__Parts_Ledger__c> ledgerUpdate = new List<dealer__Parts_Ledger__c>();
        for(dealer__Parts_Ledger__c pl : [SELECT Id, dealer__Item_Value__c, dealer__Quantity__c, dealer__Part__c, dealer__Parts_Sale_Line__c FROM dealer__Parts_Ledger__c WHERE dealer__Parts_Sale_Line__c IN:invoiceLineIds]) {
            
            System.debug(pl);
            System.assert(partsLinesToValidate.get(pl.dealer__Parts_Sale_Line__c)!=null, 'Part Sales Line not in invoice table');
            System.assert(mappedTransferLineLedgers.get(partsLinesToValidate.get(pl.dealer__Parts_Sale_Line__c).dealer__Transfer_Line__c)!=null, 'Transfer map does not contain this item '+partsLinesToValidate.get(pl.dealer__Parts_Sale_Line__c).dealer__Transfer_Line__c);

            ledgerUpdate.add(
                new dealer__Parts_Ledger__c(
                    Id=pl.Id,
                    dealer__Item_Value__c=mappedTransferLineLedgers.get(partsLinesToValidate.get(pl.dealer__Parts_Sale_Line__c).dealer__Transfer_Line__c)[0].dealer__Item_Value__c
                )
            ); 

            List<dealer__Parts_Ledger__c> ledgerRe = mappedTransferLineLedgers.get(partsLinesToValidate.get(pl.dealer__Parts_Sale_Line__c).dealer__Transfer_Line__c);
            ledgerRe.remove(0);
            mappedTransferLineLedgers.put(partsLinesToValidate.get(pl.dealer__Parts_Sale_Line__c).dealer__Transfer_Line__c, ledgerRe);
            System.debug(mappedTransferLineLedgers);

        }

        // 3) Exec update
        if(!ledgerUpdate.isEmpty()) {
            //BLL3 try {
                update ledgerUpdate;
                System.debug(ledgerUpdate);
            //BLL1d } Catch(DmlException e) {
            //BLL1d     throw new PartSupportAPIException(e.getMessage());
            //BLL3 } Catch(Exception e) {
            //BLL3     throw new PartSupportAPIException(e.getMessage());
            //BLL3 }
        }


    }
    
    @future
    public static void processOrderCount(Id partId){
        System.debug('in future method '+partId);
        PartSupportApi.customOrderCount(new dealer__Parts_Inventory__c(Id = partId));
    }  
 
	// This method explains how to process on-order in trigger context
	// a trigger can have up to 200 records in context.  We need the SOQL to be bulkified.
    public static List<dealer__Parts_Inventory__c> performOrderCount(List<dealer__Parts_Inventory__c> parts) {
        
        // Get the affected Recordes
		System.debug('Creating Set of Id(s)');
        Set<Id> partIds = new Set<Id>();
        for(dealer__Parts_Inventory__c pi : parts) {
            partIds.add(pi.Id);
        }
        System.debug(partIds);
        
        
        // Query the affected Records
        AggregateResult[] ar = [SELECT dealer__Parts_Inventory__c, SUM(dealer__Quantity_Ordered__c) orderCount FROM dealer__Parts_Order__c 
                                WHERE ( dealer__Purchase_Order__c = null )
                                AND dealer__Parts_Inventory__c IN:partIds
                               	GROUP BY dealer__Parts_Inventory__c];
        
		System.debug(ar);        
        
        AggregateResult[] arPO = [SELECT dealer__Part__c, SUM(dealer__Part_Quantity_Outstanding__c) poCount 
                                      FROM dealer__Purchase_Order_Line__c 
                                      WHERE ( dealer__Purchase_Order__r.dealer__Status__c = 'OPEN'
                                             OR dealer__Purchase_Order__r.dealer__Status__c = 'Partial' )
                                      AND dealer__Part__c IN:partIds
                                 	GROUP BY dealer__Part__c];
		System.debug(arPO);         
              
        // Reference Map
		Map<Id, dealer__Parts_Inventory__c> partMap = new Map<Id, dealer__Parts_Inventory__c>();
        Map<Id, Decimal> partOrderCount = new Map<Id, Decimal>();
        
        // Set Loop, iterate our Parts Orders
        for(AggregateResult a : ar) {
            System.debug(a);
            Id recordid = (Id)a.get('dealer__Parts_Inventory__c');
            Decimal preCount = (partOrderCount.get(recordid)!=null) ? Math.abs(Decimal.valueOf(String.valueOf(partOrderCount.get(recordid)))) : 0;
            Decimal thisCount = (a.get('orderCount')!=null) ? Math.abs(Decimal.valueOf(String.valueOf(a.get('orderCount')))) : 0;
            partOrderCount.put(recordid, preCount+thisCount);
        }        
        
        // Set Loop, iterate our Parts Orders
        for(AggregateResult a : arPO) {
            System.debug(a);
            Id recordid = (Id)a.get('dealer__Part__c');
            Decimal preCount = (partOrderCount.get(recordid)!=null) ? Math.abs(Decimal.valueOf(String.valueOf(partOrderCount.get(recordid)))) : 0;
            Decimal thisCount = (a.get('poCount')!=null) ? Math.abs(Decimal.valueOf(String.valueOf(a.get('poCount')))) : 0;
            partOrderCount.put(recordid, preCount+thisCount);
        }
        
        // Set Loop, interate our PO Lines
        
        // Assignment Loop
        for(Id i : partOrderCount.keySet()) {
            System.debug(i);
			Decimal pov = partOrderCount.get(i);
            partMap.put(i, new dealer__parts_Inventory__c(Id=i, dealer__On_Order__c=pov));
        }
        
        System.debug(partMap); 
        
        return partMap.values();
    }

    public static void customOrderCount(dealer__Parts_Inventory__c pi) {
        
            	AggregateResult[] ar = [SELECT SUM(dealer__Quantity_Ordered__c) orderCount FROM dealer__Parts_Order__c 
                                        		WHERE ( dealer__Purchase_Order__c = null )
                                       			AND dealer__Parts_Inventory__c =:pi.Id]; 
               
               AggregateResult[] arPO = [SELECT SUM(dealer__Part_Quantity_Outstanding__c) poCount 
                                         FROM dealer__Purchase_Order_Line__c 
                                       		WHERE ( dealer__Purchase_Order__r.dealer__Status__c = 'OPEN'
                                       				 	OR dealer__Purchase_Order__r.dealer__Status__c = 'Partial' )
                                       		AND dealer__Part__c =:pi.Id]; 
               
               System.debug(ar);
               System.debug(arPO);
        
        	   Decimal count = 0;
        
        	   // Orders Count
               if(ar[0]!=null && ar[0].get('orderCount')!=null) count += Math.abs((Decimal)ar[0].get('orderCount'));
        
        	   // non-orders count
               if(arPO[0]!=null && arPO[0].get('poCount')!=null) count += Math.abs((Decimal)arPO[0].get('poCount'));
        
        	    List<dealer__Parts_Invoice_Line__c> pil = [SELECT Id, LastModifiedDate FROM dealer__Parts_Invoice_Line__c WHERE dealer__Part__c=:pi.Id ORDER BY LastModifiedDate DESC limit 1];
                if(pil.size()==1) pi.dealer__Last_Sale_Date__c = Date.valueOf(pil[0].LastModifiedDate);

			   pi.dealer__On_Order__c = count;
               update pi;        
    }
    
    /* 
     * temporarily copied the complete method to non-managed code to overcome delay in package upgrade
     * 
     */
    public static void completePhysicalAPIMethod(dealer__PartPhysicalInventory__c ppi){

        SavePoint sp = Database.setSavePoint();

        // 1. Save the variance report as an attachment to the physical.
            PageReference variancePage = Page.dealer__PartsPhysicalVarianceReport;
            Blob vrb;
            if(!Test.isRunningTest()) vrb = variancePage.getContentAsPDF();
            else vrb = Blob.valueOf('Test Coverage Blob');
            Attachment d = new Attachment();
            d.ParentId = ppi.Id;
            d.Body = vrb;
            d.ContentType = 'application/pdf';
            d.Name = 'VarianceReport.pdf';

            //BLL3 try {
                insert d;
            //BLL3 } Catch(Exception e) {
            //BLL3     Database.Rollback(sp);
            //BLL3     throw new PartSupportAPIException(e.getMessage());
            //BLL3 }

        // 2. Update the inventory
        List<dealer__Parts_Inventory__c> pUpdate = new List<dealer__Parts_Inventory__c>();
        List<dealer__PartsPhysicalDetail__c> pWorkFile = new List<dealer__PartsPhysicalDetail__c>();
        List<dealer__PartsPhysicalDetail__c> pEntireSet= [Select Id from dealer__PartsPhysicalDetail__c where dealer__Parts_Physical_Inventory__c =: ppi.Id];
        Set<Id> pUpdateAffectedIds = new Set<Id>();

        for(dealer__PartsPhysicalDetail__c ppd : [Select Id, dealer__Part__c, dealer__Part__r.dealer__On_Hand__c, dealer__Part__r.dealer__Cost__c, dealer__Count__c, dealer__Cost__c, dealer__Variance__c from dealer__PartsPhysicalDetail__c where dealer__Parts_Physical_Inventory__c =: ppi.Id and dealer__Variance__c = true]) {
            if(ppd.dealer__Variance__c) {
                pUpdateAffectedIds.add(ppd.dealer__Part__c);
                pWorkFile.add(ppd);
            }
        }

        // 2b. Generate the Ledger Entry
        // Prepare the ledger adjustments for each of the affected parts.
        List<dealer__Part_Inventory_History__c> adjust_history = new List<dealer__Part_Inventory_History__c>();
        List<dealer__Parts_Ledger__c> ledger_update = new List<dealer__Parts_Ledger__c>();
        List<dealer__Parts_Ledger__c> ledger_insert = new List<dealer__Parts_Ledger__c>();
        List<dealer__Parts_Ledger__c> ledger_list = [Select Id, dealer__Item_Value__c, dealer__Part__c 
                                                        from dealer__Parts_Ledger__c
                                                        where dealer__Quantity__c = 1
                                                        and dealer__Part__c IN :pUpdateAffectedIds 
                                                        order by CreatedDate ASC];
        Map<Id, dealer__Parts_Ledger__c> ledger_map = new Map<Id, dealer__Parts_Ledger__c>(ledger_list);

        Decimal variance_value = 0;

        // Process the work file
        for(dealer__PartsPhysicalDetail__c ppw : pWorkFile) {

            // Prepare our ledger entries
            System.debug(ppw.dealer__Part__r.dealer__On_Hand__c);

            // If Increase on Part
            if(ppw.dealer__Count__c>ppw.dealer__Part__r.dealer__On_Hand__c) {
                for(Decimal i=ppw.dealer__Part__r.dealer__On_Hand__c; i < ppw.dealer__Count__c; i++) {

                    variance_value += ppw.dealer__Part__r.dealer__Cost__c;

                    ledger_insert.add(new dealer__Parts_Ledger__c(
                                            dealer__Part__c=ppw.dealer__Part__c,
                                            dealer__Entry_Date__c=Date.today(),
                                            dealer__Quantity__c=1,
                                            dealer__Item_Value__c=ppw.dealer__Part__r.dealer__Cost__c,
                                            dealer__Transaction_Note__c='Physical Inventory Variance Increase'
                                        )
                                );
                }
            }

            // If decrease on Part
            if(ppw.dealer__Count__c<ppw.dealer__Part__r.dealer__On_Hand__c) {

                Decimal decrease_amount = ppw.dealer__Part__r.dealer__On_Hand__c - ppw.dealer__Count__c;

                for(dealer__Parts_Ledger__c ll : ledger_list) {
                    if(ll.dealer__Part__c == ppw.dealer__Part__c && decrease_amount > 0) {

                        variance_value += ll.dealer__Item_Value__c;

                        ledger_update.add(new dealer__Parts_Ledger__c(
                                Id=ll.Id,
                                dealer__Quantity__c=0,
                                dealer__Transaction_Note__c='Physical Inventory Variance Decrease'
                            )
                        );

                        decrease_amount--;
                    }
                }
            }

            // 2c. Set parts history record
            if( ppw.dealer__Count__c==null) { ppw.dealer__Count__c=0; }
            Decimal physical_variance_count = 0;
            if(ppw.dealer__Count__c > ppw.dealer__Part__r.dealer__On_Hand__c) {
                physical_variance_count = ppw.dealer__Count__c - ppw.dealer__Part__r.dealer__On_Hand__c;
            }
            if(ppw.dealer__Count__c < ppw.dealer__Part__r.dealer__On_Hand__c) {
                physical_variance_count = ppw.dealer__Part__r.dealer__On_Hand__c - ppw.dealer__Count__c;
            }


            adjust_history.add(new dealer__Part_Inventory_History__c(
                                                        dealer__Part__c=ppw.dealer__Part__c,
                                                        dealer__Transaction_Event__c='Physical Variance',
                                                        dealer__Transaction_Time__c=Datetime.now(),
                                                        dealer__Quantity_Adjustment__c=physical_variance_count,
                                                        dealer__Event_Notes__c='Physical Variance of '+physical_variance_count
                                            )
            );


            // Prepare Part On Hand Adjustment
            pUpdate.add(new dealer__Parts_Inventory__c(         
                                    Id=ppw.dealer__Part__c, 
                                    dealer__On_Hand__c=ppw.dealer__Count__c
                            )
                        );            
        }

        // 3. Erase the lines of the physical
        
        // 4. Post the Physical
        ppi.dealer__Status__c = 'Complete';

        try {
            
            update ppi;

            if(!ledger_update.isEmpty()) update ledger_update;

            if(!ledger_insert.isEmpty()) insert ledger_insert;

            if(!pUpdate.isEmpty()) update pUpdate;

            if(!adjust_history.isEmpty()) insert adjust_history;

            if(!pEntireSet.isEmpty()) delete pEntireSet;

            System.debug(variance_value);
            System.debug(pUpdate);
            System.debug(ledger_insert);
            System.debug(ledger_update);
            System.debug(adjust_history);

        } Catch(DmlException e) {
                Database.Rollback(sp);
				throw new PartSupportAPIException('Failed to complete Physical '+e.getMessage());
        }

        // Apply the GL Value
        dealer__FixedOperationsSettings__c fops = dealer__FixedOperationsSettings__c.getOrgDefaults();     
        if(fops.dealer__PurchaseOrderPartsReceiptAddress__c!=null) {
            // Check Validity of email handle

            // Prepare Message
            String message = '{ "recordId" : "' + ppi.Id + '", "orgId" : "'+UserInfo.getOrganizationId()+'", "requestedBy" : "'+UserInfo.getUserId()+'", "action" : "parts_physical_variance", "partsReceiptValue" : "' + variance_value + '" }';
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<String> sendTo = new List<String>();
            sendTo.add(fops.dealer__PurchaseOrderPartsReceiptAddress__c);
            mail.setToAddresses(sendTo);
            mail.setSubject('Parts Physical Adj.');
            mail.setPlainTextBody(message);

            try {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            } catch(Exception e) {
                              
                database.rollback(sp);
                throw new PartSupportAPIException('Error: Unable to post inventory adjustment to the Third Party General Ledger');
            }
            
        }             
    } 
    
    /**
     * setInternalWarrantyPartsToCost - Apply rule of costing to parts sales when attached to internal/warranty sales
     * @param List<Parts_Invoice_Line__c>
     * @context Trigger based context (BEFORE && INSERT || UPDATE)
     * @notes This method replaces logic inside the PartSalesLineTrigger.  Per DT Case# 4013
     */ 
    public static void setInternalWarrantyPartsToCost(List<dealer__Parts_Invoice_Line__c> triggerNew){

        // BLL1a
		MW_TriggerControls__c IntAndWarrPartsAtCost = MW_TriggerControls__c.getInstance('IntAndWarrPartsAtCost'); 
        if (IntAndWarrPartsAtCost==null || IntAndWarrPartsAtCost.Enabled__c) {
        // BLL1a

			// BLL2
			Set<Id> roIds = new Set<Id>();
			for(dealer__Parts_Invoice_Line__c pil : triggerNew) {
				if (pil.dealer__Service_Repair_Order__c!=null) roIds.add(pil.dealer__Service_Repair_Order__c);
			}
			Map<Id, dealer__Service_Repair_Order__c> roMap = new Map<Id, dealer__Service_Repair_Order__c>([
				select Id, Name, Warranty_Auth__c, dealer__Warranty_Auth__c
				from dealer__Service_Repair_Order__c
				where Id in :roIds
			]);
			// BLL2 end

            /* JVK2 Not necessary as of DT v 4.14.5
            // Boolean exit var if not needed
    		Boolean runPriceToCost = false;

            // Obtain Master Records to determine Cost
    		Set<Id> partIds = new Set<Id>();
            for(dealer__Parts_Invoice_Line__c pil :triggerNew) {
    			partIds.add(pil.dealer__Part__c);    
                if(pil.dealer__Service_Line_Payment_Method__c != null && (pil.dealer__Service_Line_Payment_Method__c=='I' || pil.dealer__Service_Line_Payment_Method__c=='W')) {
                    runPriceToCost = true;
                }
            }  

            if(!runPriceToCost || partIds.isEmpty()) {
                // return unadulterated map
                return;
            }

            // Obtain fresh cost values from Part Record
            Map<Id, dealer__Parts_Inventory__c> partInventory = new Map<Id, dealer__Parts_Inventory__c>([SELECT Id, dealer__Cost__c  FROM dealer__Parts_Inventory__c WHERE Id IN:partIds]);
            JVK2 end */ 

            // Set the Values as specificed 
    		for(dealer__Parts_Invoice_Line__c pil : triggerNew) {           
                //JVK2d System.assert(partInventory.get(pil.dealer__Part__c)!=null, 'Part Inventory Map does not contain an entry for '+pil.dealer__Part__c);
                if(pil.dealer__Job_Line__c != null 
                    && pil.dealer__Service_Line_Payment_Method__c != null
                    && (pil.dealer__Service_Line_Payment_Method__c=='I' || pil.dealer__Service_Line_Payment_Method__c=='W')){

                        /* JVK2 Not necessary as of DT v 4.14.5
                        // BLL1
                        //pil.dealer__Cost__c = (partInventory.get(pil.dealer__Part__c).dealer__Cost__c / pil.dealer__Quantity_Sold__c);
                    	//pil.dealer__Price__c = pil.dealer__Cost__c;
                        //pil.dealer__Total_Price__c  = pil.dealer__Cost__c; 
                        Decimal cost = partInventory.get(pil.dealer__Part__c).dealer__Cost__c;
                        cost = cost.setScale(2, System.RoundingMode.HALF_UP); 
                        
                        // if (cost!=null && cost!=0) { 
                        //    pil.dealer__Cost__c = cost * pil.dealer__Quantity_Sold__c;
                    	//    pil.dealer__Price__c = cost;
                        //    pil.dealer__Total_Price__c = pil.dealer__Cost__c;
                        //}
                        // BLL1 end
                         
						// JVK1 Start
						// IF we have no cost, set one based on replenishment cost
						// It is important to not overwrite this value if it has been previously set
                        if(pil.dealer__Cost__c==0 || pil.dealer__Cost__c==null) {
							pil.dealer__Cost__c = cost * pil.dealer__Quantity_Sold__c;
                        }
                        
                        // If we are in this section of the loop, we are setting sale price equal to cost=
                        pil.dealer__Price__c = pil.dealer__Cost__c / pil.dealer__Quantity_Sold__c;
                        pil.dealer__Price__c = pil.dealer__Price__c.setScale(2, System.RoundingMode.HALF_UP);    // BLL1a
                        pil.dealer__Total_Price__c = pil.dealer__Cost__c;   
                        // JVK1 End
                        JVK2 end */

						// BLL2
						dealer__Service_Repair_Order__c ro = roMap.get(pil.dealer__Service_Repair_Order__c);
						if (pil.dealer__Service_Line_Payment_Method__c=='I'
							|| (ro!=null && !String.isBlank(ro.Warranty_Auth__c))) {
						// BLL2 end

                        // JVK2 - DT 4.14.5 corrected to not reset cost of part transfer purchase order receiving that triggers line value changes
                        pil.dealer__Price__c = pil.dealer__Cost__c / pil.dealer__Quantity_Sold__c;
                        pil.dealer__Price__c = pil.dealer__Price__c.setScale(2, System.RoundingMode.HALF_UP);
                        pil.dealer__Total_Price__c = pil.dealer__Cost__c;  						
                        // JVK2 End

						// BLL2
						}
						// BLL2 end

                }        
            }		
        }
    // BLL1
    }
    // BLL1 end
    
    public class PartSupportAPIException extends Exception {}
}