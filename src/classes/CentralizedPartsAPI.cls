/**
CentralizedPartsAPI
Tested by: CentralizedParts_TC
Coverage:
	2019-11-22	x%	(/)

Modifications:
	2018-06-14	B. Leaman	BLL1 - perform createCPTRecordsFromConvertedEstimate to a future method.
	2019-03-21	B. Leaman	BLL2 - add monitor of execution converting estimate-to-ro parts orders to CPT.
	2019-03-25	B. Leaman	W-000629 BLL3 - Don't add a new stock order for each parts line and fix qty to order
							not to increase the quantity by the negative on-hand.
	2019-10-22	B. Leaman	W-000629 BLL4 - conditionally create CPT records in @future method
	2019-11-22	IN00077189	BLL5 - copy order urgency into part line (if empty and if line came from an estimate)
**/
public class CentralizedPartsAPI {
    /*
     * This method creates CPT entries for Repair Orders that are created from the Estimate Conversion Process
     * Note: The estimate conversion process is managed (dealer) 
     * Adding lines to a Service Repair Order is non-managed, and the CPT Records are optionally created in that process.
     * In the future it is possible to migrate all job line creation to this method, or a similar method.
     */
    public static void createCPTRecordsFromConvertedEstimate(List<dealer__Parts_Invoice_Line__c> pils) {
		// BLL4
		MW_TriggerControls__c CreateCPTFuture = MW_TriggerControls__c.getInstance('CreateCPTFuture');
		if (CreateCPTFuture==null || CreateCPTFuture.Enabled__c) {
		// BLL4 end
    		CentralizedPartsAPI.createCPTRecordsFromEstimateFuture(JSON.serialize(pils));	// BLL1a
		// BLL4
		} else {
			CentralizedPartsAPI.createCPTRecordsFromEstimateNow(JSON.serialize(pils));
		}
		// BLL4 end
    }   // BLL1a
    // BLL1a
    @future     
    public static void createCPTRecordsFromEstimateFuture(String pilJSON) {
	// BLL4
		CentralizedPartsAPI.createCPTRecordsFromEstimateNow(pilJSON);
	}
    public static void createCPTRecordsFromEstimateNow(String pilJSON) {
	// BLL4 end
		// BLL2
		boolean notifyOfError = false;
		MonitorExecution mon = new MonitorExecution('createCPTFromEstimateFuture');
		// BLL2 end
    	List<dealer__Parts_Invoice_Line__c> pils = (List<dealer__Parts_Invoice_Line__c>) JSON.deserialize(pilJSON, List<dealer__Parts_Invoice_Line__c>.class);
        System.debug(pils);
	// BLL1a end        
		// originating service estimates
		Set<Id> repairOrderIds = new Set<Id>();
		// BLL2
		Set<Id> seSublineIds = new Set<Id>();
		// BLL2 end
        for(dealer__Parts_Invoice_Line__c pil : pils) {
            if (pil.dealer__Service_Repair_Order__c!=null) repairOrderIds.add(pil.dealer__Service_Repair_Order__c);
			// BLL2
			if (pil.dealer__Service_Estimate_Subline_Creator__c!=null) seSublineIds.add(pil.dealer__Service_Estimate_Subline_Creator__c);
			// BLL2 end
        }
        
		// BLL2
		Map<Id,dealer__Service_Estimate_Subline__c> sublineMap = new Map<Id,dealer__Service_Estimate_Subline__c>([
			select Id, Name, dealer__Parts_Master__c, dealer__Parts_Master__r.Name, dealer__Part_Quantity__c,
				dealer__Service_Estimate_Line__c, ServiceEstimateId__c, dealer__Part_Cost__c, dealer__Part_Price__c
			from dealer__Service_Estimate_Subline__c
			where Id in :seSublineIds
		]);
		mon.log('dealer__Service_Estimate_Subline__c: ' + JSON.serialize(sublineMap));
		mon.log('dealer__Parts_Invoice_Line__c: ' + JSON.serialize(pils));
		mon.log('repairOrderIds: ' + JSON.serialize(repairOrderIds));
		mon.log('seSublineIds: ' + JSON.serialize(seSublineIds));
		// BLL2 end 

        /*
        Map<Id, dealer__Service_Estimate__c> estimateMap = new Map<Id, dealer__Service_Estimate__c>();
        for(dealer__Service_Estimate__c se : ses) {
            if(se.dealer__Service_Repair_Order__c!=null) {
                repairOrderIds.add(se.dealer__Service_Repair_Order__c);
				estimateMap.put(se.dealer__Service_Repair_Order__c, se);
            }
        }      
        
        System.debug(repairOrderIds);
        System.debug(estimateMap);
        
       	
        if(repairOrderIds.isEmpty())
            return;
        */
        
        // The originating lines
        Map<Id, dealer__Parts_Invoice_Line__c> partInvoiceLineMap = new Map<Id, dealer__Parts_Invoice_Line__c>([
        	SELECT Id, Name, dealer__Service_Repair_Order__c, dealer__Part__c, 
				dealer__Part_Master_Record__c, dealer__Quantity_Ordered__c, 
				dealer__Sold_Via__c, dealer__Quantity_Sold__c, 
				dealer__Part__r.dealer__On_Hand__c
			FROM dealer__Parts_Invoice_Line__c
			WHERE dealer__Service_Repair_Order__c IN:repairOrderIds
			  AND dealer__Parts_Order__c=null
			  AND dealer__Sold_Via__c = 'Estimate'
		]);
		// BLL2
		mon.log('Map of Parts Invoice Lines will include prior estimates too:');
		mon.log('map of dealer__Parts_Invoice_Line__c: ' + JSON.serialize(partInvoiceLineMap));
		// BLL2 end 

        List<dealer__Parts_Invoice_Line__c> partsInvoiceLines = partInvoiceLineMap.values();
        
		// stop if nothing to process!
        if(partsInvoiceLines.isEmpty()) return;
        
        // Transaction Control
		//BLL2d SavePoint sp = Database.setSavepoint() ;
        
        // Collections
        
		Map<Id, dealer__Service_Repair_Order__c> repairOrder = new Map<Id, dealer__Service_Repair_Order__c>();
		Map<Id, dealer__Stock_Order__c> stockOrders = new Map<Id, dealer__Stock_Order__c>();
        Map<Id, dealer__Service_Estimate__c> estimateMap = new Map<Id, dealer__Service_Estimate__c>();
        Map<Id, Id> partInvoiceToRoId = new Map<Id, Id>();
        
        // Creation Maps and Lists
        List<dealer__Stock_Order__c> stockOrdersToCreate = new List<dealer__Stock_Order__c>();
        List<dealer__Parts_Order__c> partsOrderLinesToCreate = new List<dealer__Parts_Order__c>();
		
		System.debug('Build estimate map');
        for(dealer__Service_Estimate__c se : [SELECT Id, Name, dealer__Service_Repair_Order__c, CPT_Order_Urgency__c FROM dealer__Service_Estimate__c WHERE dealer__Service_Repair_Order__c IN:repairOrderIds]) {
            estimateMap.put(se.dealer__Service_Repair_Order__c, se);
            System.debug(se);
        }
		// BLL2
		mon.log('Estimate map is used to obtain order urgency only');
		mon.log('map of RO to dealer__Service_Estimate__c: ' + JSON.serialize(estimateMap));
		// BLL2 end 
        
        repairOrder = new Map<Id, dealer__Service_Repair_Order__c>(
            [SELECT Id, Name, dealer__Company__c, dealer__Company__r.Centralized_Purchasing_On_Off__c,
             		dealer__RO_Number__c, 
             		(SELECT Id, Name FROM dealer__Orders__r)
				FROM dealer__Service_Repair_Order__c 
             	WHERE Id IN:repairOrderIds]
        );
		// BLL2
		mon.log('map of dealer__Service_Repair_Order__c: ' + JSON.serialize(repairOrder));
		// BLL2 end 
        
		// Map the stock orders to the Repair Order ID Map
        for(Id roId : repairOrder.keySet()) {
            dealer__Service_Repair_Order__c ro = repairOrder.get(roId);
            for(dealer__Stock_Order__c so : ro.dealer__Orders__r) {
                stockOrders.put(ro.Id, so);
            }
        }
		// BLL2
		mon.log('stock order map by RO: ' + JSON.serialize(stockOrders));
		// BLL2 end 

        // Get the associated Queue for Processing
		QueueSobject q = new QueueSobject();
        //BLL5d try {
            q = [SELECT Id, QueueId FROM QueueSobject where SobjectType = 'dealer__Parts_Order__c' limit 1];
        //BLL5d } Catch(QueryException e) {
        //BLL5d     throw new CPTException(e.getMessage());
        //BLL5d }

        
        
        // Process Records
        // Do we have all of the necessary stock orders
		for(dealer__Parts_Invoice_Line__c pil : partsInvoiceLines) {

            partInvoiceToRoId.put(pil.Id, pil.dealer__Service_Repair_Order__c);
			
            // Qualify the record
            if(repairOrder.get(pil.dealer__Service_Repair_Order__c)!=null
              	&& repairOrder.get(pil.dealer__Service_Repair_Order__c).dealer__Company__c!=null 
               	&& repairOrder.get(pil.dealer__Service_Repair_Order__c).dealer__Company__r.Centralized_Purchasing_On_Off__c) {
                	
                    // Magic happens here
                    // 1) Stock Order Header is Created if does not exist, 
                    if(stockOrders.get(pil.dealer__Service_Repair_Order__c)==null) {
						// BLL3
                        //stockOrderstoCreate.add(
						dealer__Stock_Order__c newstockorder =
						// BLL3 end
                            new dealer__Stock_Order__c(
                                Name='CPT#'+repairOrder.get(pil.dealer__Service_Repair_Order__c).dealer__RO_Number__c,
                                dealer__Status__c='Incomplete',
                                dealer__Company__c=repairOrder.get(pil.dealer__Service_Repair_Order__c).dealer__Company__c,
                                dealer__Service_Repair_Order__c=pil.dealer__Service_Repair_Order__c,
                                dealer__Date_Ordered__c=Date.Today(),
                                dealer__Order_Type__c='Special Order'
                            );
						// BLL3
                        //);
						stockorderstoCreate.add(newstockorder);
						stockOrders.put(pil.dealer__Service_Repair_Order__c, newstockorder);
						// BLL3 end
                    }  
                }
		}

		// BLL2
		mon.log('stock orders to create: ' + JSON.serialize(stockOrderstoCreate));
		// BLL2 end 

        // If we have stock orders to create, 
        if(!stockOrdersToCreate.isEmpty()){
            //BLL5d try {
                insert stockOrdersToCreate;
                
				// BLL3 - doing this earlier in the stream now
                //for(dealer__Stock_Order__c so : stockOrdersToCreate) {
                //	stockOrders.put(so.dealer__Service_Repair_Order__c, so);    
                //}
				// BLL3 end
                
            //BLL5d } Catch(DmlException e) {
            //BLL5d     Database.rollback(sp);
            //BLL5d     throw new CPTException(e.getMessage());
            //BLL5d }
        }
		// BLL2
		mon.log('stock orders after create: ' + JSON.serialize(stockOrders));
		// BLL2 end 
        
		// Finally, process the CPT Requests Entries
        for(dealer__Parts_Invoice_Line__c pil : partsInvoiceLines) {
            
            
            System.debug(pil);
            System.debug(repairOrder.get(pil.dealer__Service_Repair_Order__c));
            
			// Qualify the record
            if(pil.dealer__Quantity_Ordered__c != null &&
               pil.dealer__Quantity_Ordered__c > 0 &&
               repairOrder.get(pil.dealer__Service_Repair_Order__c)!=null
              	&& repairOrder.get(pil.dealer__Service_Repair_Order__c).dealer__Company__c!=null 
               	&& repairOrder.get(pil.dealer__Service_Repair_Order__c).dealer__Company__r.Centralized_Purchasing_On_Off__c) {
                	
					// BLL3 - adjust qty ordered?
					dealer__Parts_Invoice_line__c pp = partInvoiceLineMap.get(pil.Id);
            		Decimal onHandAtSale = (pp.dealer__Part__r.dealer__On_Hand__c>0) ? pp.dealer__Part__r.dealer__On_Hand__c : 0;
					Decimal qtyToOrder = (pil.dealer__Quantity_Sold__c >= onHandAtSale) ? pil.dealer__Quantity_Sold__c-onHandAtSale : 0;
					if (qtyToOrder>0) {
					// BLL3 end

                    // 2) Create the parts order line from invoice line
                    partsOrderLinesToCreate.add(
                        new dealer__Parts_Order__c(
                            dealer__Order_Date__c=Date.today(),
                            dealer__Order__c=stockOrders.get(pil.dealer__Service_Repair_Order__c).Id,
                            dealer__Parts_Inventory__c=pil.dealer__Part__c,
                            dealer__Parts_Master__c=pil.dealer__Part_Master_Record__c,
							// BLL3
                            //dealer__Quantity_Ordered__c = pil.dealer__Quantity_Ordered__c,
							dealer__Quantity_Ordered__c = qtyToOrder,
							// BLL3 end
                            dealer__Parts_Line__c=pil.Id,
                            OwnerId=q.QueueId
						)
                    ); 
					
					// BLL3
					}
					// BLL3 end
					
                    
            } // End of Record Qualification
        }
        
        System.debug(partsOrderLinesToCreate);
		// BLL2
		mon.log('partsOrderLinesToCreate: ' + JSON.serialize(partsOrderLinesToCreate));
		// BLL2 end 
        
        // If we have stock orders to create, 
        if(!partsOrderLinesToCreate.isEmpty()){
            //BLL5d try {
                
                insert partsOrderLinesToCreate;
                
            //BLL5d } Catch(DmlException e) {
            //BLL5d     Database.rollback(sp);
            //BLL5d     throw new CPTException(e.getMessage());
            //BLL5d }
        }
        
        // System.assert(1!=1, 'throwing a rollback');
        
        // If we have Parts Order Lines, create them.
        List<dealer__Parts_Invoice_Line__c> invoiceLinesToUpdate = new List<dealer__Parts_Invoice_Line__c>();
        for(dealer__Parts_Order__c ol : partsOrderLinesToCreate) {
            
            Id roId = partInvoiceToRoId.get(ol.dealer__Parts_Line__c);
            dealer__Parts_Invoice_Line__c partInvoiceLine = partInvoiceLineMap.get(ol.dealer__Parts_Line__c);
            String orderUrgency = (estimateMap.get(roId)!=null) ? estimateMap.get(roId).CPT_Order_Urgency__c : null;
            System.debug(roId);
            System.debug(estimateMap);
            System.debug(estimateMap.get(roId));
            System.debug('orderUrgency ' + orderUrgency);
            
            Decimal onHandAtSale = (partInvoiceLine.dealer__Part__r.dealer__On_Hand__c>0) ? partInvoiceLine.dealer__Part__r.dealer__On_Hand__c : 0;
			// BLL3
			Decimal qtyToOrder = (partInvoiceLine.dealer__Quantity_Sold__c >= onHandAtSale) ? partInvoiceLine.dealer__Quantity_Sold__c-onHandAtSale : 0;
			// BLL3 end
			// BLL5
            //invoiceLinesToUpdate.add(new dealer__Parts_Invoice_Line__c(
            dealer__Parts_Invoice_Line__c updline = new dealer__Parts_Invoice_Line__c(
            		Id=ol.dealer__Parts_Line__c,
                	Parts_Order__c=ol.Id,
                	dealer__Parts_Order__c=ol.Id,
					//BLL5 dealer__Order_Type__c=orderUrgency,
					// BLL3
                	//dealer__Quantity_Ordered__c=Math.abs(partInvoiceLine.dealer__Quantity_Sold__c - onHandAtSale)
					dealer__Quantity_Ordered__c=qtyToOrder
					// BLL3 end
            //BLL5	)
			);
			if (!String.isBlank(orderUrgency)) updline.dealer__Order_Type__c=orderUrgency;
			invoiceLinesToUpdate.add(updline);
			// BLL5 end
        }

		// BLL2
		mon.log('parts invoice lines to update: ' + JSON.serialize(invoiceLinesToUpdate));
		// BLL2 end 

        // If we have Invoice Lines to Update, update them.
        if(!invoiceLinesToUpdate.isEmpty()){
            //BLL5d try {
                
                update invoiceLinesToUpdate;
                
            //BLL5d } Catch(DmlException e) {
            //BLL5d     Database.rollback(sp);
            //BLL5d     throw new CPTException(e.getMessage());
            //BLL5d }
			// BLL2
			if (notifyOfError || mon.AlwaysNotify) mon.notifyAdmin();
			// BLL2 end
        }        

    } 

	// BLL5
	private static Map<Id, dealer__Service_Estimate_SubLine__c> sesublinemap;
	// BLL5 end
	// BLL5
	// CopyOrderUrgencyFromEstimate
	public static void CopyOrderUrgencyFromEstimate(List<dealer__Parts_Invoice_Line__c> partslines) {
		// pull order urgency from estimate (if part came from an estimate)
		if (sesublinemap==null) sesublinemap = new Map<Id, dealer__Service_Estimate_SubLine__c>();
		Set<Id> sesublineids = new Set<Id>();
		for(dealer__Parts_Invoice_Line__c pil : partslines) {
			System.debug(pil.dealer__Service_Estimate_Subline_Creator__c);
			// if missing order urgency (type) && this came from an estimate subline ...
			if (String.isBlank(pil.dealer__Order_Type__c) && pil.dealer__Service_Estimate_Subline_Creator__c!=null) {
				sesublineids.add(pil.dealer__Service_Estimate_Subline_Creator__c);
			}
		}
		// if there are any estimate sublines we need to get the CPT order urgency for... create a map
		// only run SOQL if there are sublines needed *and* we don't already have them all from a prior invocation!
		if (sesublineids.size()>0 && !sesublinemap.keySet().containsAll(sesublineids)) {
			sesublinemap = new Map<Id, dealer__Service_Estimate_SubLine__c>([
				select Id, dealer__Service_Estimate_Line__c,
					dealer__Service_Estimate_Line__r.dealer__Service_Estimate__c,
					dealer__Service_Estimate_Line__r.dealer__Service_Estimate__r.CPT_Order_Urgency__c
				from dealer__Service_Estimate_SubLine__c
				where Id in :sesublineids
			]);
		}
		System.debug(sesublinemap);
		// apply CPT order urgency to part invoice line record
		for(dealer__Parts_Invoice_Line__c pil : partslines) {
			// only if urgency is blank and this came from an estimate subline
			if (String.isBlank(pil.dealer__Order_Type__c) && pil.dealer__Service_Estimate_Subline_Creator__c!=null) {
				dealer__Service_Estimate_SubLine__c sesubline = sesublinemap.get(pil.dealer__Service_Estimate_Subline_Creator__c);
				if (sesubline!=null && !String.isBlank(sesubline.dealer__Service_Estimate_Line__r.dealer__Service_Estimate__r.CPT_Order_Urgency__c)) {
					pil.dealer__Order_Type__c = sesubline.dealer__Service_Estimate_Line__r.dealer__Service_Estimate__r.CPT_Order_Urgency__c;
					System.debug(pil.dealer__Order_Type__c);
				}
			}
		}
	}
	// BLL5 end

    /* Exception Interface */
    public class CPTException extends Exception {}
}