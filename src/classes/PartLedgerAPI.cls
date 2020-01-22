public with sharing class PartLedgerAPI {

	// Singleton container for sales counts 
	private static Map<Id, Integer> saleCount = null;

	public static Map<Id, dealer__Parts_Invoice_Line__c> salesmap(Id partId) {
		return new Map<Id, dealer__Parts_Invoice_Line__c>([SELECT dealer__Parts_Invoice__c, dealer__Bin__c, dealer__Core__c, dealer__Cost__c, dealer__Counterman_No__c, dealer__Counterman__c, dealer__Currently_Available__c, dealer__Drop_Ship__c, dealer__Extended_Price__c, dealer__Gross_Margin__c, dealer__Job_Line__c, dealer__List__c, dealer__MFG__c, dealer__Net_Price__c, dealer__Net__c, dealer__Order_Type__c, dealer__Part_Description__c, dealer__Part_Number__c, dealer__Part__c, dealer__Pay_Type__c, dealer__Price_Level_Strategy__c, dealer__Price_Level__c, dealer__Price__c, dealer__Quantity_Ordered__c, dealer__Quantity_Sold__c, dealer__Sale_Date__c, dealer__Service_Job_Line_Number__c, dealer__Service_Line_Payment_Method__c, dealer__Service_Repair_Order__c, dealer__Sold_Via__c, dealer__Source__c, dealer__Stocking_Group__c, dealer__Total_Price__c, dealer__Total_Tax__c, dealer__Transaction_Code__c, Currently_On_Order__c, Extended_Cost__c, Negative_QTY__c, Part_Master_Record__c, dealer__Currently_On_Order__c, dealer__Extended_Cost__c, dealer__Negative_QTY__c, dealer__Part_Master_Record__c, dealer__Purchase_Order_Line__c, PO_ETA__c, PO_Name__c, PO_Tracking__c, Parts_Order__c, Part_type__c, dealer__Purchase_Order__c, Repair_Order_Posted_Date_Time__c, Dimmension_1_Id__c, Financial_Force_Company_Id__c, Purchase_Order_Cost_Variance__c, Incorrect__c, Purchase_Order_Same_Quantity_as_Sold__c, dealer__Comment__c, Name, Id, 
			dealer__Purchase_Order_Line__r.dealer__Purchase_Order__c,
			dealer__Job_Line__r.Name,
			dealer__Part__r.dealer__Pack_QTY__c,
			CreatedDate
		FROM  dealer__Parts_Invoice_Line__c WHERE dealer__Part__c=:partId
		ORDER BY CreatedDate ASC]);
	}

	public static Map<Id, dealer__Purchase_Order_Line__c> purchasemap(Id partId) {
		return new Map<Id, dealer__Purchase_Order_Line__c>([SELECT dealer__Purchase_Order__c, dealer__Account__c, 
															dealer__Amount__c, dealer__Description__c, 
															dealer__Drop_Ship_Address__c, dealer__Drop_Ship_To__c, 
															dealer__Part_Quantity__c, dealer__Part__c, dealer__Parts_Invoice__c, 
															dealer__Special_Instructions__c, dealer__Customer_Total__c, 
															dealer__Parts_Line__c, dealer__Parts_Master__c, 
															dealer__Service_Job_Line__c, dealer__Part_Quantity_Outstanding__c, 
															dealer__Part_Quantity_Received__c, General_Ledger_Account__c,
															RecordType__c, dealer__Part_Cost__c, dealer__RecordType__c, 
															Add_to_Chassis__c, Add_to_Conversion__c, dealer__Item_Value__c, 
															dealer__Purchase_Order_Accepted_Date__c, LabelPrintRcvQty__c, 
															dealer__Returned_to_Vendor__c, GeneralLedgerAcct__c, 
															Part_Invoice_Line_Cost__c, Cost_Matched_to_Master__c, 
															dealer__Pack_Part_Override__c, Dimension_1__c, Name, Id, 
															Pack_Count__c, dealer__Parts_Line__r.Name,
			dealer__Purchase_Order__r.CreatedById,
			dealer__Purchase_Order__r.CreatedBy.Name,
			dealer__Purchase_Order__r.Name,
			dealer__Part__r.dealer__Pack_QTY__c,
			dealer__Purchase_Order__r.dealer__Accepted_DateTime__c
		 FROM dealer__Purchase_Order_Line__c WHERE dealer__Part__c =:partId 
		 AND dealer__Purchase_Order__r.dealer__Accepted_DateTime__c != NULL
		 ORDER BY dealer__Purchase_Order__r.dealer__Accepted_DateTime__c ASC]);		
	}

	public static List<dealer__Parts_Ledger__c> preledger(Id partId) {
		return [SELECT dealer__Part__c, dealer__Current_Value__c, dealer__Entry_Date__c, dealer__Item_Value__c, 
				dealer__Parts_Sale_Line__c, dealer__Purchase_Order__c, dealer__Purchased_By__c, 
				dealer__Quantity__c, dealer__Repair_Order_Line__c, dealer__Sold_By__c, dealer__Transaction_Note__c, 
				Value_of_One__c, Name, Id 
			FROM dealer__Parts_Ledger__c 
			WHERE dealer__Part__c=:partId];		
	}

	public static void clearReportingLedger(Id partId) {
		List<PartLedgerReporting__c> rl = [SELECT Id FROM PartLedgerReporting__c WHERE Part__c=:partId];
		if(!rl.isEmpty())
			delete rl;		
	}

	public static void rebuiltLedgerReportingTable(Id partId) {
		
		// Lookup our part 
		Map<Id, dealer__Parts_Inventory__c> partRecords = new Map<Id, dealer__Parts_Inventory__c>([SELECT Id, dealer__On_Hand__c FROM dealer__Parts_Inventory__c WHERE Id=:partId limit 1]);

		// Clear the reporting ledger for this part
		PartLedgerAPI.clearReportingLedger(partId);

		// Get Data Load, Physical Variance from History Table.
		// Three values we are targeting
		// Data Load, Manual On Hand Adjustment, Physical Variance 
		List<dealer__Part_Inventory_History__c> dataloadhistory = new List<dealer__Part_Inventory_History__c>();
		List<dealer__Part_Inventory_History__c> physicalHistory = new List<dealer__Part_Inventory_History__c>();
		List<dealer__Part_Inventory_History__c> manualAdjustments = new List<dealer__Part_Inventory_History__c>();
		Set<String> historySearchValues = new Set<String> { 'Data Load', 'Physical Variance', 'Manual On Hand Adjustment' };

		for(dealer__Part_Inventory_History__c pih : [SELECT Id, Name, dealer__Part__c, dealer__Part__r.dealer__Cost__c, dealer__Cost__c, dealer__Quantity_Adjustment__c, dealer__Transaction_Event__c, dealer__Transaction_Time__c 
														FROM dealer__Part_Inventory_History__c 
														WHERE dealer__Part__c=:partId 
														AND dealer__Transaction_Event__c IN :historySearchValues]) {

					if(pih.dealer__Transaction_Event__c=='Data Load') {	dataloadhistory.add(pih); }
					if(pih.dealer__Transaction_Event__c=='Physical Variance') {	physicalHistory.add(pih); }
					if(pih.dealer__Transaction_Event__c=='Manual On Hand Adjustment') {	manualAdjustments.add(pih); }
		
		}

		// Get all the sales history
		Map<Id, dealer__Parts_Invoice_Line__c> sales = PartLedgerAPI.salesmap(partId);

		// Get all of the purchse history
		Map<Id, dealer__Purchase_Order_Line__c> purchases =  PartLedgerAPI.purchasemap(partId);

		// Get non-related e vents
		List<dealer__Parts_Ledger__c> preledger = PartLedgerAPI.preledger(partId);

		// Organize data for use
		List<PartLedgerReporting__c> purchase_ledger = new List<PartLedgerReporting__c>();
		Map<Id, dealer__Parts_Invoice_Line__c> partSaleByPurchaseOrderLine = new Map<Id, dealer__Parts_Invoice_Line__c>();
		Map<Id, dealer__Parts_Invoice_Line__c> partSaleByJobLine = new Map<Id, dealer__Parts_Invoice_Line__c>();
		List<dealer__Parts_Invoice_Line__c> saleslines = new List<dealer__Parts_Invoice_Line__c>();
		Map<Id, dealer__Parts_Invoice_Line__c> salesLinesWithNoPO = new Map<Id, dealer__Parts_Invoice_Line__c>();
		Map<Id, Decimal> salesLineCount = new Map<Id, Decimal>();
		Map<Id, dealer__Parts_Invoice_Line__c> filledSales = new Map<Id, dealer__Parts_Invoice_Line__c>();

		// Upload our dataload records first, as prerquisite data 
		// Create the dataload Ledgers
		List<PartLedgerReporting__c> dataloadLedger = PartLedgerAPI.insertHistoryEvent(dataloadhistory, 'Data Load');
		List<PartLedgerReporting__c> varianceLedger = PartLedgerAPI.insertHistoryEvent(physicalHistory, 'Physical Variance');
		List<PartLedgerReporting__c> manualAdjustmentLedger = PartLedgerAPI.insertHistoryEvent(manualAdjustments, 'Manual On Hand Adjustment');

		// Iterate sales lines, creating two maps, each of these maps will allow us to build reference data
		for(Id pl : sales.keySet()) {
			dealer__Parts_Invoice_Line__c salesline = sales.get(pl);
			saleslines.add(salesline);
			salesLinesWithNoPO.put(salesline.Id, salesline);
			salesLineCount.put(salesLine.Id, salesLine.dealer__Quantity_Sold__c);

			if(salesline.dealer__Purchase_Order_Line__c!=null) {
				partSaleByPurchaseOrderLine.put(salesline.dealer__Purchase_Order_Line__c, salesline);
				if(salesLinesWithNoPO.get(salesline.Id)!=NULL) {   salesLinesWithNoPO.remove(salesline.Id); }
			}

			if(salesline.dealer__Job_Line__c!=null) {
				partSaleByJobLine.put(salesline.dealer__Job_Line__c, salesline);
				// if(salesLinesWithNoPO.get(salesline.Id)!=NULL) {   salesLinesWithNoPO.remove(salesline.Id); }
			}
		}

		// Iterate Purchase Lines
		for(Id pl : purchases.keySet()) {

			dealer__Purchase_Order_Line__c poline = purchases.get(pl);

			// QTY Iteration, if pack part and override not set then it is QTY * Pack Value
			Integer pCount = 1;
			if(poline.dealer__Pack_Part_Override__c==false 
				&& poline.dealer__Part__r.dealer__Pack_QTY__c != null 
				&& poline.dealer__Part__r.dealer__Pack_QTY__c > 1) {

					pCount = (Integer)poline.dealer__Part__r.dealer__Pack_QTY__c;
			}

			for(Integer i=1; i<=(poline.dealer__Part_Quantity_Received__c * pCount); i++) {

				// If pack override is checked the item value is the individual value, if not it is a pack value.
				Decimal lineItemValue = 0;
				if(poline.dealer__Pack_Part_Override__c==true) {
					lineItemValue=poline.dealer__Item_Value__c;
				} else {
					lineItemValue=(poline.dealer__Item_Value__c/poline.Pack_Count__c);
				}


				PartLedgerReporting__c nL = new PartLedgerReporting__c();
				nL.Part__c=poline.dealer__Part__c;
				nL.Purchase_Order__c=poline.dealer__Purchase_Order__c;
				nL.Quantity__c=1;
				nL.Purchased_By__c=poline.dealer__Purchase_Order__r.CreatedBy.Name;
				nL.Item_Value__c=lineItemValue;
				nL.Transaction_Note__c=poline.dealer__Purchase_Order__r.Name+' received;';
				nL.Entry_Date__c=Date.valueOf(poline.dealer__Purchase_Order__r.dealer__Accepted_DateTime__c);

				// If we have a sale line associate the records.
				if(partSaleByPurchaseOrderLine.get(poline.Id)!=null
					&&  salesLineCount.get(partSaleByPurchaseOrderLine.get(poline.Id).Id)>0) {

					nL.Parts_Sale_Line__c=partSaleByPurchaseOrderLine.get(poline.Id).Id;
					nL.Quantity__c=0;
					nL.Transaction_Note__c+='Sold on '+partSaleByPurchaseOrderLine.get(poline.Id).Name+';';
 
					// Deprecate sale counts
					salesLineCount.put(nL.Parts_Sale_Line__c, salesLineCount.get(nL.Parts_Sale_Line__c) - 1);	
				}

				if(partSaleByJobLine.get(poline.dealer__Service_Job_Line__c)!=null 
					&& nL.Parts_Sale_Line__c==null
					&& salesLineCount.get(partSaleByJobLine.get(poline.dealer__Service_Job_Line__c).Id)>0) {

					nL.Parts_Sale_Line__c=partSaleByJobLine.get(poline.dealer__Service_Job_Line__c).Id;
					nL.Quantity__c=0;
					nL.Transaction_Note__c+='Sold on '+partSaleByJobLine.get(poline.dealer__Service_Job_Line__c).Name+';';

					salesLineCount.put(nL.Parts_Sale_Line__c, salesLineCount.get(nL.Parts_Sale_Line__c) - 1);
				}

				if(nL.Parts_Sale_Line__c!=null && filledSales.get(nL.Parts_Sale_Line__c)==null) {
					filledSales.put(nL.Parts_Sale_Line__c, sales.get(nL.Parts_Sale_Line__c));
				}

				purchase_ledger.add(nL);
			}
		}

		// Create the Purchase Ledgers
		try {
			insert purchase_ledger;
		} Catch(DmlException e) {
			throw new PartLedgerAPIException(e.getMessage());
		}

		// Iterate Each Sales Line and if PS is not in the list add to the ledger
		List<PartLedgerReporting__c> saleLedger = new List<PartLedgerReporting__c>();
		Map<Id, PartLedgerReporting__c> purchaseLedgerUpdate = new Map<Id, PartLedgerReporting__c>();

		// Iterate the Sales Lines with No Invoice and assoicate with Ledgers in Chronological Order

		List<PartLedgerReporting__c> lupdate = new List<PartLedgerReporting__c>();
		List<PartLedgerReporting__c> lAddUnmatchedSale = new List<PartLedgerReporting__c>();
		List<PartLedgerReporting__c> postPurhcaseLedger = new List<PartLedgerReporting__c>();
		postPurhcaseLedger.addAll(dataloadLedger);
		postPurhcaseLedger.addAll(varianceLedger);
		postPurhcaseLedger.addAll(manualAdjustmentLedger);
		postPurhcaseLedger.addAll(purchase_ledger);

		for(Id slnopo : salesLinesWithNoPO.keyset()) {
			// Sales Line
			dealer__Parts_Invoice_Line__c invLine = salesLinesWithNoPO.get(slnopo);
			System.debug('Targeting line '+invLine.Name);

			for(PartLedgerReporting__c lr : postPurhcaseLedger) {
				if(lr.Quantity__c==1 
					&& salesLineCount.get(invLine.Id)>0
					&& lr.Item_Value__c==(invLine.dealer__Cost__c / invLine.dealer__Quantity_Sold__c)) {

					lr.Parts_Sale_Line__c=invLine.Id;
					lr.Quantity__c=0;
					lr.Transaction_Note__c+='Sold on '+invLine.Name+';';
					salesLineCount.put(invLine.Id, salesLineCount.get(invLine.Id) - 1);					
					
					// filled ledger
					if(filledSales.get(invLine.Id)==null) {
						filledSales.put(invLine.Id, invLine);
					}

					System.debug('Unmatched Sale cost same '+invLine.Name);
					System.debug(lr);

					lupdate.add(lr);


				} else {
					if(lr.Quantity__c==1 
						&& salesLineCount.get(invLine.Id)>0
						&& lr.Item_Value__c!=(invLine.dealer__Cost__c / invLine.dealer__Quantity_Sold__c)) {
						// Umatched Sale, must have come from dataload.
						PartLedgerReporting__c umLine = new PartLedgerReporting__c();
						umLine.Part__c=lr.Part__c;
						umLine.Quantity__c=0;
						umLine.Item_Value__c=invLine.dealer__Cost__c;
						umLine.Transaction_Note__c='Sold on '+invLine.Name+';';
						umLine.Parts_Sale_Line__c=invLine.Id;
						umLine.Entry_Date__c=Date.valueOf(invLine.CreatedDate);

						salesLineCount.put(invLine.Id, salesLineCount.get(invLine.Id) - 1);					
						
						// filled ledger
						if(filledSales.get(invLine.Id)==null) {
							filledSales.put(invLine.Id, invLine);
						}

						System.debug('Unmatched Sale cost not same '+invLine.Name);
						System.debug(lr);

						lAddUnmatchedSale.add(umLine);
					}
				}
			}
		}

		if(lupdate.size()>0) {
			try {
				update lupdate;
			} Catch(DmlException e) {
				throw new PartLedgerAPIException(e.getMessage());
			}
		}

		if(lAddUnmatchedSale.size()>0) {
			try {
				insert lAddUnmatchedSale;
			} Catch(DmlException e) {
				throw new PartLedgerAPIException(e.getMessage());
			}
		}


		// Iterate the ledger lines for manual adjustments and data loading
		List<PartLedgerReporting__c> postLedger = new List<PartLedgerReporting__c>();
		for(dealer__Parts_Ledger__c pl : preledger) {

			// Loop all lines that are obvious dataload or adjustments
			if(pl.dealer__Parts_Sale_Line__c==null 
				&& pl.dealer__Purchase_Order__c==null
				&& pl.dealer__Repair_Order_Line__c==null
				&& !pl.dealer__Transaction_Note__c.containsIgnoreCase('Part Removed from Invoice')) {

					PartLedgerReporting__c nL = new PartLedgerReporting__c();
					nL.Part__c=pl.dealer__Part__c;
					nL.Quantity__c=pl.dealer__Quantity__c;
					nL.Item_Value__c=pl.dealer__Item_Value__c;
					nL.Transaction_Note__c=pl.dealer__Transaction_Note__c;
					nL.Entry_Date__c=pl.dealer__Entry_Date__c;	
					postLedger.add(nL);

			}


			// Loop all Negative Sales Lines 
			// For this to work correctly we need to ensure that this sale line is not offset by a purchase order.
			// The tricky part is that PO's don't have to explicitely reference the Sales line. 

			/*
				! May be flawed, neg sales can be offset inaccurately by a po received on a separate order
			*/
			if(pl.dealer__Quantity__c == -1 
				&& pl.dealer__Parts_Sale_Line__c!=null
				&& filledSales.get(pl.dealer__Parts_Sale_Line__c)==null) {
				
					PartLedgerReporting__c nL = new PartLedgerReporting__c();
					nL.Part__c=pl.dealer__Part__c;
					nl.Parts_Sale_Line__c=pl.dealer__Parts_Sale_Line__c;
					nL.Quantity__c=pl.dealer__Quantity__c;
					nL.Item_Value__c=pl.dealer__Item_Value__c;
					nL.Transaction_Note__c=pl.dealer__Transaction_Note__c;
					nL.Entry_Date__c=pl.dealer__Entry_Date__c;	

					System.debug('Neagtive Sales, no offsetting PO '+pl.dealer__Transaction_Note__c);

					// postLedger.add(nL);
			}
		}

		if(postLedger.size()>0) {  
			try {
				insert postLedger;
			} Catch(DmlException e) {
				throw new PartLedgerAPIException(e.getMessage());
			}
		}

		if(purchases.size()==0 && sales.size()==0) {
			List<PartLedgerReporting__c> lr = [SELECT Id, Name, Parts_Sale_Line__c, Transaction_Note__c, Quantity__c FROM PartLedgerReporting__c WHERE Part__c=:partId];
			try {
				delete lr; //This might have been a mistake, although the items in the table are usually manual adjustments that we can not determine their validity.
			} Catch(DmlException e) {
				throw new PartLedgerAPIException(e.getMessage());
			}

			// Load the example table into the Reporting Table
			List<PartLedgerReporting__c> prAdd = new List<PartLedgerReporting__c>();
			for(dealer__Parts_Ledger__c pl : [SELECT dealer__Part__c, dealer__Current_Value__c, dealer__Entry_Date__c, dealer__Item_Value__c, dealer__Parts_Sale_Line__c, dealer__Purchase_Order__c, 
												dealer__Purchased_By__c, dealer__Quantity__c, dealer__Repair_Order_Line__c, dealer__Sold_By__c, dealer__Transaction_Note__c, Value_of_One__c, Id, Name 
												FROM dealer__Parts_Ledger__c where dealer__Part__c=:partId]) {

					prAdd.add(new PartLedgerReporting__c(
							Part__c=pl.dealer__Part__c,
							Item_Value__c=pl.dealer__Item_Value__c,
							Parts_Sale_Line__c=pl.dealer__Parts_Sale_Line__c,
							Purchase_Order__c=pl.dealer__Purchase_Order__c,
							Purchased_By__c=pl.dealer__Purchased_By__c,
							Quantity__c=pl.dealer__Quantity__c,
							Transaction_Note__c=pl.dealer__Transaction_Note__c 
						)
					);
			}

			if(prAdd.size()>0) {
				try {
					insert prAdd;
				} Catch(DmlException e) {
					throw new PartLedgerAPIException(e.getMessage());
				}
			}
		}

		// At the end of the run if there is a difference between the postLedger and preLedger assume data load for positive sales and line deletion for negative balances.
		dealer__Parts_Inventory__c afterInventory = [SELECT Id, dealer__Physical_OnHand__c, Physical_Reporting_On_Hand__c, dealer__Cost__c,
																dealer__Entry_Date__c, dealer__Pack_QTY__c
															 FROM dealer__Parts_Inventory__c 
															 WHERE Id=:partId];

		if(afterInventory.dealer__Physical_OnHand__c != afterInventory.Physical_Reporting_On_Hand__c) {
			System.debug(afterInventory);

			// If PhysicalOH > ReportingOH
			if(afterInventory.dealer__Physical_OnHand__c > afterInventory.Physical_Reporting_On_Hand__c) {

				// Often times we are seeing manual adjustments in this section, due to the fact that we are out of balance after building our logic
				
				// Possible we would like to set the after item value to the cost value, divided by pack total

				Integer c = (Integer)afterInventory.dealer__Physical_OnHand__c - (Integer)afterInventory.Physical_Reporting_On_Hand__c;
				List<PartLedgerReporting__c> prl = new List<PartLedgerReporting__c>();
				for(Integer i=1; i<=Math.abs(c); i++) {
					PartLedgerReporting__c nL = new PartLedgerReporting__c();
					nL.Part__c=afterInventory.Id; 
					nL.Quantity__c=1;
					nL.Item_Value__c=(afterInventory.dealer__Pack_QTY__c != null && afterInventory.dealer__Pack_QTY__c > 1) ? (afterInventory.dealer__Cost__c / afterInventory.dealer__Pack_QTY__c) : afterInventory.dealer__Cost__c;
					nL.Transaction_Note__c='<UNKNOWN>';
					nL.Entry_Date__c=afterInventory.dealer__Entry_Date__c;	
					prl.add(nL);					
				}

				System.debug(prl);

				try {
					if(prl.size()>0) {
						System.debug('Physical OH > Reporting OH');
						System.debug(prl);
						insert prl;
					}
				} Catch(DmlException e) {
					throw new PartLedgerAPIException(e.getMessage());
				}
			}

			// Less than
			if(afterInventory.dealer__Physical_OnHand__c < afterInventory.Physical_Reporting_On_Hand__c) {
				// Decrement 
				Integer sz = (Integer)afterInventory.Physical_Reporting_On_Hand__c - (Integer)afterInventory.dealer__Physical_OnHand__c;
				List<PartLedgerReporting__c> plr_decrement = new List<PartLedgerReporting__c>();
				for(PartLedgerReporting__c plr : [SELECT Id, Name,Transaction_Note__c FROM PartLedgerReporting__c WHERE Part__c=:afterInventory.Id AND Quantity__c=1 ORDER BY Entry_Date__c ASC LIMIT :Math.abs(sz)]) {					
					
					System.debug(plr);
					String preNote = plr.Transaction_Note__c;
					plr.Quantity__c=0;
					plr.Transaction_Note__c=preNote;
					plr_decrement.add(plr);
				}
				try {
					System.debug(plr_decrement);
					if(plr_decrement.size()>0) {
						System.debug(plr_decrement);
						update plr_decrement;
					}
				} Catch(DmlException e) {
					throw new PartLedgerAPIException(e.getMessage());
				}
			}

			afterInventory = [SELECT Id, dealer__Physical_OnHand__c, Physical_Reporting_On_Hand__c, dealer__Cost__c,dealer__Entry_Date__c
															 FROM dealer__Parts_Inventory__c 
															 WHERE Id=:partId];
			if(afterInventory.dealer__Physical_OnHand__c != afterInventory.Physical_Reporting_On_Hand__c) {
				// Final run to look for neg sales.
				// Get negative sales 
				List<PartLedgerReporting__c> negSales = new List<PartLedgerReporting__c>();
				List<PartLedgerReporting__c> negSalesUpdate = new List<PartLedgerReporting__c>();
				Map<Id, dealer__Parts_Invoice_Line__c> unMatchedSalesLines = sales;

				System.debug(unMatchedSalesLines);
				List<PartLedgerReporting__c> plusLines = new List<PartLedgerReporting__c>();
				for(PartLedgerReporting__c plr : [SELECT Id, Name, Parts_Sale_Line__c, Transaction_Note__c, Quantity__c FROM PartLedgerReporting__c WHERE Part__c=:afterInventory.Id ORDER BY Entry_Date__c ASC]) {					
					if(unMatchedSalesLines.get(plr.Parts_Sale_Line__c)!=null) {
						unMatchedSalesLines.remove(plr.Parts_Sale_Line__c);
					}

					if(plr.Quantity__c==1) {
						plusLines.add(plr);
					}
				}

				System.debug(unMatchedSalesLines);
	
				// If we have left over items it is time to add them as negative
				for(Id umsid : unMatchedSalesLines.keySet()) {
					dealer__Parts_Invoice_Line__c pLine = unMatchedSalesLines.get(umsid);
					for(Integer i=1; i<=pLine.dealer__Quantity_Sold__c; i++) {

						// if plus lines not empty
						if(!plusLines.isEmpty()) {

							PartLedgerReporting__c nL = plusLines.get(0);
							nL.Parts_Sale_Line__c=pLine.Id;
							nL.Quantity__c=0;
							nL.Transaction_Note__c='Sold on '+pLine.Name;
							negSalesUpdate.add(nL);

							plusLines.remove(0);
 
						} else {
							System.debug('Negative Sale cnt: '+i); 
							// if Plus lines is empty
							PartLedgerReporting__c nL = new PartLedgerReporting__c();
							nL.Part__c=pLine.dealer__Part__c;
							nL.Parts_Sale_Line__c=pLine.Id;
							nL.Quantity__c=-1;
							nL.Item_Value__c=(pLine.dealer__Cost__c/pLine.dealer__Quantity_Sold__c);
							nL.Transaction_Note__c='Sold negative '+pLine.Name;
							nL.Entry_Date__c=Date.valueOf(pLine.CreatedDate);
							negSales.add(nL);	

						}					
					}
				}

				if(negSalesUpdate.size()>0) {
					try {
						// update negSalesUpdate; --Seems to be causing problems
					} Catch(DmlException e) {
						throw new PartLedgerAPIException(e.getMessage());
					}
				}

				if(negSales.size()>0) {
					try {
						insert negSales;
					} Catch(DmlException e) {
						throw new PartLedgerAPIException(e.getMessage());
					}
				}

			}

		}
	
	}

	public static List<PartLedgerReporting__c> insertHistoryEvent(List<dealer__Part_Inventory_History__c> historyEvent, String eventName) {
		List<PartLedgerReporting__c> dataloadledger = new List<PartLedgerReporting__c>();
		for(dealer__Part_Inventory_History__c dhist : historyEvent) {
			for(Integer i=0; i<(Integer)dhist.dealer__Quantity_Adjustment__c; i++) {
				Decimal dcost = 0;
				if(dhist.dealer__Cost__c!=null){ dcost=dhist.dealer__Cost__c; } else { dcost=dhist.dealer__Part__r.dealer__Cost__c; }
				dataloadledger.add(new PartLedgerReporting__c(
						Item_Value__c=dcost,
						Part__c=dhist.dealer__Part__c,
						Quantity__c=1,
						Transaction_Note__c=eventName+';',
						Entry_Date__c=Date.valueOf(dhist.dealer__Transaction_Time__c)
					)
				);

				System.debug(dataloadledger);
			}
		}

		if(dataloadledger.size()>0) {
			try {
				System.debug(eventName+' Inserted size: '+dataloadledger.size());
				insert dataloadledger;
			} Catch(DmlException e) {
				throw new PartLedgerAPIException(e.getMessage());
			}
		} 

		return dataloadLedger;
	}

	public class PartLedgerAPIException extends Exception {}
}