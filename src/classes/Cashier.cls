/**
 * Cashier
 * Tested by: Cashier_TC
 * Coverage:
 * 	2017-10-30	63% (190/298) 
 *	2017-11-30	63% (202/316)
 *	2018-08-30	65% (217/330)
 *	2018-09-25	88% (242/275)
 *  2018-11-02  81% (237/292)
 *	2019-01-14	80% (235/292)
 * 
 *    Date     Programmer     Description
 * ----------  -----------  -----------------------------------------------------------------------------------
 * 2015-08-28	B. Leaman	BLL1 - Change control# to stock# for get-ready ROs; store link to vehicle inventory
 * 2015-09-01	J. Kuljis	JVK1 - Discounted RO apply 3300 and laborsales
 * 2015-09-08	J. Kuljis	JVK2 - Discount was incorrectly reducing the dealer__Amount__c value (Already reduced by the discount) 
 * 							Also, was throwing a null error if not set.
 * 2015-09-14	J. Kuljis	JVK3 - Amount due must include Internal and Warranty 
 * 2015-09-16	J. Kuljis	JVK4 - Sublet C/S set as a debit
 * 2015-09-24	D. RAY   	DR1 - Move update of RO Lines before the RO is set to posted.
 * 2015-10-01	B. Leaman	BLL2 - FinancialForce determines which period based on Journal date - use invoice date instead of today.
 * 2015-09-28   B. Leaman   BLL3 - NOTE: Control__c is not being set correctly according to Deeanna. Need clarification to be able to fix!
 * 2015-10-6	D. RAY     	DR2  - Adding Labor/Parts cost to vehicle Inventory
 * 2015-10-07	B. Leaman	BLL4 - Don't create journal if there are no lines.
 * 2015-10-12	B. Leaman	BLL5 - Fix journal date & posting period logic - still a question about what date to use
 * 							for the journal date. Leaving as "today" for now. Consider using accepted date or invoice date?
 * 2015-10-14   J. Kuljis   JVK5 - Remove the warranty total from the cashier amount IT15252 - Warranty reveivable applied by job lines
 * 2015-10-26   J. Kuljis   JVK6 - Include the Internal Charge in RO Query
 * 2015-10-29	B. Leaman	BLL6 - Sublet inventory control# changed to RO# so it can net out with PO on account sched.
 *							Use cost instead of sale amount for sublet C/S and sublet inventory transaction lines.
 * 2015-10-30	B. Leaman	BLL7 - Only GetReady lines are added to the vehicle cost. 11/5 also update custom vehicle cost field.
 * 2015-11-08   J. Kuljis   JVK7 - IT16191 Change warranty receivable to customer line type per FF Direction
 * 2015-12-09   RedTeal     RT1  - Changed how misc charges are saved as journal items. Will now show as seperate items instead of being
 * 								   aggregated into one (multiple instances of the same misc charge will be aggregated into one line under the
 * 								   same GLA).
 * 2015-12-23	B. Leaman	BLL8a - replace dealer__Customer_Invoice_Total__c with CustomerInvoiceTotal__c.
 * 2015-12-26   J. Kuljis   JVK8 - Async posting does not require posting in this class.
 * 2016-1-5     RedTeal     RT2  - Prevent ROs from being posted if there are any POs that are not accepted.
 * 2016-02-05	B. Leaman	BLL9a IT19894 - Prevent InvoiceRO action from changing status from Posted back to Invoiced.
 * 2016-04-05   RedTeal     RT2  - added field to query 
 * 2016-04-13	B. Leaman	BLL10 IT#19657 - support for confirmation of post if no labor or parts, adjust to increase code coverage;
 * 2016-05-11	B. Leaman	BLL11 - Don't clear out paidby object instance -- it causes an error even when you re-select a customer.
 *							I'm going to just stop clearing it at all; alternative would be to clear paidby.dealer__Customer__c instead of clearing paidby.
 * 2016-06-12   J. Kuljis   JVK9 - Updated the VOID RO Method to now allow a VOID to be performed if there are labor and parts on the repair order
 * 2016-06-15	B. Leaman	BLL12 - Add informational message that RO is being posted.
 * 2016-07-13	B. Leaman	BLL13 - Require the "Paid by" account reference. Otherwise journal will not be created.
 * 2016-09-13	B. Leaman	BLL14 - Double-check RO status so it can't be posted from multiple tabs!
 * 2016-11-18  Gaurav Agrawal  Case# 00002186 - Prevent posting/void of RO if the RO, or Job Lines are associated with a PO Header or Line
 * 2017-01-05  J.Kuljis JVK10 - Reversal of repair order pagereference method
 * 2016-12-29	B. Leaman	BLL15 - Replace custom lookups with managed versions (Deal obj)
 * 2017-02-03	B. Leaman	BLL16 IR-0007181 - Lock RO before submitting for posting so it can't be posted twice.
 * 2017-10-30	B. Leaman	BLL17 Don't allow invoicing an RO with no job lines.
 * 2017-11-30	B. Leaman	BLL18 - add error message if RO needs taxes recalculated, allow void on invoiced ro.
 * 2018-08-30	B. Leaman	BLL19 - DT4.0 - need to mark lines complete to update status to invoiced.
 * 2018-09-25	B. Leaman	BLL20 - improve code coverage  
 * 2018-10-24   B. Leaman   W-000471    BLL21 - Don't allow entry of $0 cashiering entries.
 * 2018-11-01   B. Leaman   W-000479    BLL22 - Don't allow posting if there are open parts orders (CPT requests) -- just like protection for open POs.
 * 2019-01-14	B. Leaman	W-000548	BLL23 - Don't allow posting RO if PO is in Open or Partial status, fix line status to ensure required qty was received.
 *							Also prevent submit for posting if there are open parts orders, but not based on qty, as they aren't always ordering every piece if they have some inventory.
 * 2019-03-28	B. Leaman	W-000632	BLL24 - don't allow posting an RO if PO is voided. They need to remove part if they void the po.
 * 2019-04-08	B. Leaman	W-000473	BLL25 - warranty deductible support (MW_TriggerControls__c: 'RODeductibleAddToTotal' enabled until DT adds it in.)
 * 2019-04-30	B. Leaman	W-000575	BLL26 - store new method of payment drop-down
 * 2019-06-12	B. Leaman	W-000575 fix BLL27 - ignore cashier entries made while the RO was in posted status (new payment entry component).
 */
public without sharing class Cashier {
    
    public dealer__Service_Repair_Order__c ro {get;set;}
    public dealer__Service_Repair_Order__c paidBy {get;set;}
    public Decimal amount {get;set;}
    public Decimal balance_due {get;set;}
    public String method {get;set;}
    public Boolean deposit {get;set;}
    public String authcode {get;set;}
    public c2g__codaDimension1__c dim1 {get;set;}
    public dealer__Dealer_Location__c loc {get;set;}
    private String poNumbersToDisplay;
    private String poNumbers;
	private boolean RequireTaxCalc;	// BLL18a
	public boolean NeedToCalcTax {get;private set;}	// BLL18a
    public String openPartsOrders;  // BLL22a
	// BLL24
	public Set<String> IncompletePOStatus = new Set<String>{'Open','Partial'};
	public Set<String> IncompletePOStatusParts = new Set<String>{'Open','Partial','Void'};
	// BLL24 end
	// BLL25
	public boolean AddDeductibleToAmtDue {get;set;}
	// BLL25 end

    /* Controller */
    public Cashier() {

        poNumbersToDisplay = '';
        poNumbers = '';
        paidBy = new dealer__Service_Repair_Order__c();
        if(ApexPages.currentPage().getParameters().get('id')==null)  throw new CashierException('Cashier Applicaiton Compenents may only be accessed when referenced by a Repair Order');

        // BLL1 add dealer__Vehicle__r.dealer__Stock_Number__c, dealer__Vehicle__r.dealer__Sales_Inventory__c 
        ro = [Select Id, Name, Journal__c, dealer__Customer__c, dealer__Customer_Charges__c, dealer__Customer_Invoice_Total__c, dealer__Discount_Total__c, dealer__Company__c, CustomerInvoiceTotal__c,  dealer__Customer_Tax__c, 
                    dealer__Create_Date_Time__c, dealer__Vehicle__c, dealer__Posted_Date_Time__c, dealer__Tax__c, dealer__Invoiced_Date_Time__c,dealer__Warranty_Charges__c, Total_RO_Charges__c,
                    dealer__Vehicle__r.dealer__Stock_Number__c, dealer__Vehicle__r.dealer__Sales_Inventory__c, GetReady_RO__c, dealer__Internal_Charges__c, // BLL3c add GetReady_RO__c , JVK6  add dealer__Internal_Charges__c, RT2 add Total_RO_Charges__c
                    LaborHoursCustomer__c, LaborHoursInternal__c, LaborHoursWarranty__c, // BLL10a 
                    dealer__Customer_Parts_Charges__c, dealer__Internal_Parts_Charges__c, dealer__Warranty_Parts_Charges__c, // BLL10a
                    TaxHash__c, 	// BLL18a
					dealer__Warranty_Deductible__c, // BLL25a
                    dealer__Status__c	// BLL12a
                        from dealer__Service_Repair_Order__c where Id=:ApexPages.currentPage().getParameters().get('id') limit 1];
		System.debug(ro);
        if(paidBy.dealer__Customer__c==null) {
            paidBy.dealer__Customer__c = ro.dealer__Customer__c;
        }

		// BLL25
		MW_TriggerControls__c RODeductibleAddToTotal = MW_TriggerControls__c.getInstance('RODeductibleAddToTotal');
		AddDeductibleToAmtDue = (RODeductibleAddToTotal==null || RODeductibleAddToTotal.Enabled__c);
		// BLL25 end

        // Set the amount by default, to the outstanding balance of the work order
		// BLL27
        //AggregateResult[] sumCashier = [Select SUM(dealer__Amount__c) asum FROM dealer__Cashering__c where dealer__Service_Repair_Order__c =:ro.Id];
		AggregateResult[] sumCashier = [Select SUM(dealer__Amount__c) asum FROM dealer__Cashering__c where dealer__Service_Repair_Order__c =:ro.Id and Cashiered_while_Posted__c=false];
		// BLL27 end
        Decimal tot = (Decimal)sumCashier[0].get('asum');
        Decimal roTot = 0;
        amount = 0;
        // Check for NULL Values on Both Customer and Warranty Values
        // BLL8d if(ro.dealer__Customer_Invoice_Total__c!=null) {
        // BLL8d    amount += ro.dealer__Customer_Invoice_Total__c;
        // BLL8d }
        // BLL8a
        if(ro.CustomerInvoiceTotal__c!=null) {
            amount += ro.CustomerInvoiceTotal__c;
        }
        // BLL8a end

        /* 
        JVK5 - 
        if(ro.dealer__Warranty_Charges__c!=null) { 
            amount += ro.dealer__Warranty_Charges__c;
        }
        JVK5 - End
        */ 

		// BLL18a tax calcs are required before cashiering RO
        RequireTaxCalc = true;
        MW_TriggerControls__c AvataxRepair = MW_TriggerControls__c.getInstance('AvataxRepair');  // BLL8a
       	if (AvataxRepair!=null && AvataxRepair.Enabled__c==false) RequireTaxCalc = false;
       	NeedToCalcTax = NeedToRecalcTax();
       	if (NeedToCalcTax && ro.dealer__Status__c!='Posted') ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must recalculate sales taxes.'));
       	//BLL20d }
       	// BLL18a end

        if(tot==null) { tot=0; }    
        amount = (amount - tot);
        amount = amount.setScale(2);

		// BLL25
		if (ro.dealer__Warranty_Charges__c==null) ro.dealer__Warranty_Charges__c=0;
		if (ro.dealer__Warranty_Deductible__c==null) ro.dealer__Warranty_Deductible__c=0;
		if (AddDeductibleToAmtDue) amount += Math.min(ro.dealer__Warranty_Deductible__c, ro.dealer__Warranty_Charges__c);
		// BLL25 end

        balance_due = amount;
        // Get Location Information
        loc     =   [Select Id, Name, Financial_Force_Dimension_1__c, Company__c, Internal_Labor_Rate__c, Sales_Tax_Account__c 
                                                from dealer__Dealer_Location__c 
                                                where Id=:ro.dealer__Company__c limit 1];
        if(loc.Financial_Force_Dimension_1__c!=null) {
        dim1                            =   [Select Id, Name from c2g__codaDimension1__c 
                                                where Id=:loc.Financial_Force_Dimension_1__c limit 1];  
        } else {
            throw new CashierException('Location '+loc.Name+' must have the Financial Force Dimmension 1 field set to before attempting to Post');
        }

    }

	// BLL18a
	// getNeedToRecalcTax
	//-----------------------------
	private boolean NeedToRecalcTax() {
		String hash = null; 
		AvaTax_MBW serviceTaxation = AvaTax_MBW.getInstanceSROId(ro.Id);
		if (serviceTaxation!=null) {
			hash = serviceTaxation.getHash();
		}
		return RequireTaxCalc && (hash!=ro.TaxHash__c);
	}
	// BLL18a end

    // Getters
    public List<dealer__Cashering__c> cashier_entries {
        get {
                // BLL27
				// return [SELECT dealer__Amount__c, dealer__Close_Date__c, dealer__Company_Number__c, dealer__Credit_Card_Authorization_Code__c, dealer__Customer__c, dealer__Deposit__c, dealer__Payment_Method__c, dealer__Service_Repair_Order__c, Id, Name FROM dealer__Cashering__c where dealer__Service_Repair_Order__c =:ro.Id limit 500];
				return [SELECT dealer__Amount__c, dealer__Close_Date__c, dealer__Company_Number__c, dealer__Credit_Card_Authorization_Code__c, dealer__Customer__c, dealer__Deposit__c, dealer__Payment_Method__c, dealer__Service_Repair_Order__c, Id, Name FROM dealer__Cashering__c where dealer__Service_Repair_Order__c =:ro.Id and Cashiered_while_Posted__c=false limit 500];
				// BLL27 end
            }
        set;
    }

    public List<SelectOption> getPaymentMethods() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '-- Select One --'));
        
        Map<String, dealer__Payment_Methods__c> methods = dealer__Payment_Methods__c.getAll();
        for(String paymentMethodName : methods.keySet()) {
            dealer__Payment_Methods__c pm = methods.get(paymentMethodName);
            options.add(new SelectOption(pm.Name, pm.dealer__Method__c));
        }
        return options;
    }

    // Page References
    public PageReference returnToRo() {

        PageReference p = new ApexPages.StandardController(ro).view();
        p.setRedirect(true);
        return p;
    }
    
    /*Case# 00002186 Begin */
    
    //Method to check related Purchase Orders with Status Open
    private Boolean PurchaseOrderError(){
        // BLL23
		//List<dealer__Purchase_Order__c> purchaseOrders = [SELECT Id, Name FROM dealer__Purchase_Order__c WHERE dealer__Service_Repair_Order__c = :ro.Id AND dealer__Status__c = 'Open'];
		// BLL24
		//List<dealer__Purchase_Order__c> purchaseOrders = [
		//	select Id, Name 
		//	from dealer__Purchase_Order__c 
		//	where dealer__Service_Repair_Order__c = :ro.Id AND dealer__Status__c in ('Open','Partial','Void')
		//];
		List<dealer__Purchase_Order__c> purchaseOrders = [
			select Id, Name 
			from dealer__Purchase_Order__c 
			where dealer__Service_Repair_Order__c = :ro.Id AND dealer__Status__c in :IncompletePOStatus
		];
		// BLL24 end
		// BLL23 end
        
        List<String> ponames = new List<String>();
        
        for(dealer__Purchase_Order__c po : purchaseOrders) ponames.add(po.Name);
        poNumbers = String.join(ponames, ', ');
        //BLL20d if(purchaseOrders.size() > 0){
        //BLL20d     return true;
        //BLL20d } else {
        //BLL20d     return false;
        //BLL20d }
        return (purchaseOrders.size()>0);	// BLL20a
    }
    
    //Method to get Purchase Order Line Item related to RO's Service Job Lines
	// BLL Note 1/14/19: Should this query parts lines & related PO lines to see that the required qty has been received? Issue is posting ROs on partially-received POs.
    private Boolean PurchaseOrderLineItemError(){
		// BLL23
        //Set<Id> ServiceJobLineIdSet = new Set<Id>();
        //List<dealer__Purchase_Order_Line__c> PurchaseOrderLineList = new List<dealer__Purchase_Order_Line__c>();
        //List<String> PurchaseOrderLineNames = new List<String>();
        //
        //for(dealer__Service_Job__c objServiceJob : [SELECT Id FROM dealer__Service_Job__c WHERE dealer__Service_Repair_Order__c =: ro.Id]){
        //    ServiceJobLineIdSet.add(objServiceJob.Id);          
        //}
        //
        //for(dealer__Purchase_Order_Line__c objPurchaseOrderLine : [SELECT Id, Name, dealer__Purchase_Order__r.Name FROM dealer__Purchase_Order_Line__c WHERE dealer__Service_Job_Line__c IN : ServiceJobLineIdSet AND dealer__Purchase_Order__r.dealer__Status__c = 'Open']){
        //    PurchaseOrderLineList.add(objPurchaseOrderLine);
        //    PurchaseOrderLineNames.add(objPurchaseOrderLine.dealer__Purchase_Order__r.Name);
        //}
        //poNumbersToDisplay = String.join(PurchaseOrderLineNames, ',');
        ////BLL20d if(PurchaseOrderLineList.size()>0){
        ////BLL20d     return true;
        ////BLL20d } else {
        ////BLL20d     return false;
        ////BLL20d }
        //return (PurchaseOrderLineList.size()>0);	// BLL20a     
		List<String> PurchaseOrderLineNames = new List<String>();  
		for(dealer__Parts_Invoice_Line__c pil : [
			select Id, Name, dealer__Service_Repair_Order__c, dealer__Quantity_Sold__c, dealer__Quantity_Ordered__c, 
				dealer__Purchase_Order_Line__c, dealer__Purchase_Order_Line__r.dealer__Part_Quantity_Received__c,
				dealer__Purchase_Order_Line__r.dealer__Purchase_Order__r.Name,
				dealer__Purchase_Order_Line__r.dealer__Purchase_Order__r.dealer__Status__c, 
				dealer__Part__r.dealer__Pack_QTY__c
			from dealer__Parts_Invoice_Line__c
			where dealer__Service_Repair_Order__c=:ro.Id
		]) {
			//Decimal qtyRcvd = pil.dealer__Purchase_Order_Line__r.dealer__Part_Quantity_Received__c;
			//if (qtyRcvd!=null && pil.dealer__Part__r.dealer__Pack_QTY__c!=null) qtyRcvd *= pil.dealer__Part__r.dealer__Pack_QTY__c;
			//if (qtyRcvd!=null && pil.dealer__Quantity_Sold__c!=null 
			//	&& qtyRcvd<pil.dealer__Quantity_Sold__c) {
			// BLL24
			//if (pil.dealer__Purchase_Order_Line__r.dealer__Purchase_Order__r.dealer__Status__c=='Open'
			//	|| pil.dealer__Purchase_Order_Line__r.dealer__Purchase_Order__r.dealer__Status__c=='Partial') {
			//	PurchaseOrderLineNames.add(pil.dealer__Purchase_Order_Line__r.dealer__Purchase_Order__r.Name);
			//}
			if (IncompletePOStatusParts.contains(pil.dealer__Purchase_Order_Line__r.dealer__Purchase_Order__r.dealer__Status__c)) {
				PurchaseOrderLineNames.add(pil.dealer__Purchase_Order_Line__r.dealer__Purchase_Order__r.Name);
			}
			// BLL24 end
			//}
		}
		poNumbersToDisplay = String.join(PurchaseOrderLineNames, ',');
		return !String.isBlank(ponumbersToDisplay);
		// BLL23 end
    }
    /*Case# 00002186 End */ 

    // BLL22
    //Method to check related Parts Orders 
    private boolean PartsOrderError(Id roId) {
        List<dealer__Stock_Order__c> partsOrders = [
            select Id, Name,
                ( select Id, Name, dealer__Parts_Inventory__r.Name 
                  from dealer__Parts_Orders__r
                  where dealer__Purchase_Order__c=null
                )
            from dealer__Stock_Order__c
            where dealer__Service_Repair_Order__c=:roId and (dealer__Status__c=null or dealer__Status__c='Incomplete')	// BLL23 add check for null
        ];
        
        List<String> openorders = new List<String>();
        
        for(dealer__Stock_Order__c ord : partsOrders) {
            for(dealer__Parts_Order__c partord : ord.dealer__Parts_Orders__r) {
                openorders.add(
                    String.isBlank(partord.dealer__Parts_Inventory__r.Name) ? partord.Name : partord.dealer__Parts_Inventory__r.Name
                );
            }
        }
        openPartsOrders = String.join(openorders, ', ');
        return (openorders.size()>0);	// BLL20a
    }
    // BLL22 end

    // BLL20a invoiceROError
    
    public PageReference invoiceRO() {
		// BLL27
        //AggregateResult[] sumCashier = [Select SUM(dealer__Amount__c) asum FROM dealer__Cashering__c where dealer__Service_Repair_Order__c =:ro.Id];
        AggregateResult[] sumCashier = [Select SUM(dealer__Amount__c) asum FROM dealer__Cashering__c where dealer__Service_Repair_Order__c =:ro.Id and Cashiered_while_Posted__c=false];
		// BLL27 end
        Decimal tot = (Decimal)sumCashier[0].get('asum');
        if(tot==null) { tot=0; }    
        if(ro.dealer__Warranty_Charges__c==null)  ro.dealer__Warranty_Charges__c=0;

		// BLL20a
        PageReference r = new Apexpages.standardcontroller(ro).view();
        r.getParameters().put('id', ro.id);
        r.setRedirect(true);
        // BLL20a end

		System.debug(ro.CustomerInvoiceTotal__c);
		System.debug(tot);
        // BLL8d amount = (ro.dealer__Customer_Invoice_Total__c - tot);  // used to subtract warranty charges too
        amount = (ro.CustomerInvoiceTotal__c - tot);  // used to subtract warranty charges too // BLL8a
        if(amount > 0) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Customer Pay Total must be cashiered before closing invoice.'));
        //BLL20d     return null;            
        //BLL20d }       
        
        /* Case# 00002186 Begin */      
        if(PurchaseOrderError()) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to Invoice Repair Order because it is having Open purchase orders: ' + poNumbers));
        //BLL20d     return null;
        //BLL20d }       
        else if(PurchaseOrderLineItemError()) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to Invoice Repair Order because it is having Open Purchase Orders of related Purchase Order Line Items: ' + poNumbersToDisplay));
        //BLL20d     return null;
        //BLL20d }
        /* Case# 00002186 End */
        // BLL22
        if (PartsOrderError(ro.Id)) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to Invoice Repair Order because it has open parts orders: ' + openPartsOrders));
        // BLL22 end
        
		dealer__Service_Repair_Order__c checkro = null;	// bll16a
        try {	//BLL16a
        // BLL9a
        checkro = [
        	select Id, Name, dealer__Status__c, dealer__Invoiced_Date_Time__c, dealer__Posted_Date_Time__c, dealer__Warranty_Charges__c, dealer__Total_Repair_Order_Charges__c,	// BLL16c
        		(Select Id from dealer__Job_Lines__r)	// BLL17a 
        	from dealer__Service_Repair_Order__c 
        	where Id=:ro.Id
        	FOR UPDATE	// BLL16a
        ];
		if (checkro.dealer__Status__c=='Posted') ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Repair order is already posted.'));
		//BLL20d 	return null;
		//BLL20d }
        // BLL9a end
        // BLL16a
        } catch(Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Repair order is in use on another screen. Try again later'));
			//BLL20d return null;
        }
        // BLL16a end
        // BLL17a
        if (checkro.dealer__Job_Lines__r.size()==0) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You cannot invoice a repair order that has no job lines'));
		//BLL20d 	return null;
        //BLL20d }
        // BLL17a end

    	// BLL18a
    	if (NeedToRecalcTax()) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must recalculate sales taxes before invoicing this RO.'));
        //BLL20d     return null;
    	//BLL20d }
    	// BLL18a end

		// BLL20a - return before attempting updates if there are errors
		System.debug(ApexPages.getMessages());
		if (ApexPages.hasMessages(ApexPages.Severity.ERROR)) r=null;
		if (r==null) return r;
		// BLL20a end

		// BLL19a - make sure lines are marked complete
        // Build list of lines Complete lines before RO is set to posted
        List<dealer__Service_Job__c> roLines = [SELECT dealer__Service_Repair_Order__c, dealer__Actual_Time__c, dealer__Book_Time__c, dealer__Cause__c, dealer__Concern__c, dealer__Correction__c, dealer__Customer_Id__c, dealer__Estimate__c, dealer__Gross_Profit__c, dealer__Job_Added_Date__c, dealer__Job_ELR__c, dealer__Job_Finish__c, dealer__Job_Line_Id__c, dealer__Job_Start__c, dealer__Labor_Charges__c, dealer__Labor_Rate__c, dealer__Labor_Type__c, dealer__Line_Number__c, dealer__Line_Total__c, dealer__Op_Code__c, dealer__Operation_Code_Description__c, dealer__Parent_Record__c, dealer__Parts_Cost__c, dealer__Parts_Invoice_Id__c, dealer__Parts_Line__c, dealer__Parts_Total__c, dealer__RO_Invoice_Date_Time__c, dealer__RO_Number__c, dealer__RO_Status__c, dealer__Repair_Order_Id__c, dealer__Repair_Order__c, dealer__Service_Type__c, dealer__Service_Vehicle_Id__c, dealer__Standard_Operation_Code__c, dealer__Stat__c, dealer__Sublet_Cost__c, dealer__Sublet_Total__c, dealer__Technician_Cost__c, dealer__Technician__c, dealer__Currently_Active__c, dealer__Sum_of_Billed_Hours__c, Payment_Notes__c, dealer__Add_On__c, dealer__Misc_Charges__c, dealer__Op_Description__c, dealer__Technician_ID__c, dealer__CustomerConcern__c, dealer__RO_Open_Date_Time__c, dealer__Claim__c, dealer__Paid_By__c, Payment_Method__c, External_ID__c, Name, Id FROM dealer__Service_Job__c where dealer__Service_Repair_Order__c=:ro.Id limit 500];
		List<dealer__Service_Job__c> updLines = new List<dealer__Service_Job__c>();
        // bulk update lines to completed. 
        for(dealer__Service_Job__c line : roLines) {
            if(line.dealer__Stat__c != 'Complete') {
                updLines.add(new dealer__Service_Job__c(Id=line.Id, dealer__Stat__c = 'Complete'));
            }
        }
        if (updLines.size()>0) update updLines;
		// BLL19a
        
	    //BL16d ro.dealer__Invoiced_Date_Time__c = Datetime.now();
        //BLL16d ro.dealer__Status__c = 'Invoiced';
        checkro.dealer__Invoiced_Date_Time__c = Datetime.now();	// BLL16a
        checkro.dealer__Status__c = 'Invoiced';	// BLL16a
        checkro.dealer__Warranty_Charges__c = ro.dealer__Warranty_Charges__c;	// BLL16a
        try {
	        //BLL16d update ro;        
	        update checkro;	// BLL16a
        } catch(DMLException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'DML Error '+e.getMessage()));
            //BLL20d return null;        	    
        }
        
        //BLL20d PageReference r = new Apexpages.standardcontroller(ro).view();
        //BLL20d r.getParameters().put('id', ro.id);
        //BLL20d r.setRedirect(true);

		if (ApexPages.hasMessages(ApexPages.Severity.ERROR)) r=null;	// BLL20a
        return r;
    }

    /*
    *
    *   VOID a Repair Order
    *
    */
    public PageReference doVoid() {
		// BLL20a
        PageReference r = new Apexpages.standardcontroller(ro).view();
        r.getParameters().put('id', ro.id);
        r.setRedirect(true);
        // BLL20a

		dealer__Service_Repair_Order__c checkro = null;	// bll16a
    	try { 	// BLL16a
        // BLL9a
        checkro = [
        	select Id, Name, dealer__Status__c, dealer__Invoiced_Date_Time__c, dealer__Posted_Date_Time__c, dealer__Warranty_Charges__c, dealer__Total_Repair_Order_Charges__c,	// BLL16c
        		(select Id, Name, dealer__Stat__c from dealer__Job_Lines__r) // BLL18a 
        	from dealer__Service_Repair_Order__c 
        	where Id=:ro.Id
        	FOR UPDATE
        ];
        // BLL16a
        } catch(Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Repair order is in use on another screen. Try again later'));
			//BLL20d return null;
        }
        // BLL16a end

        // JVK9
        if(checkro.dealer__Total_Repair_Order_Charges__c !=null 
                && checkro.dealer__Total_Repair_Order_Charges__c > 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Repair order still has charges.  Please remove any charges from this Repair Order before trying to Void.'));
            //BLL20d return null;            
        }

        /* Case# 00002186 Begin */
        if(PurchaseOrderError()) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to Void Repair Order because it is having Open purchase orders: ' + poNumbers));
        //BLL20d     return null;
        else if(PurchaseOrderLineItemError()) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to Void Repair Order because it is having Open Purchase Orders of related Purchase Order Line Items: ' + poNumbersToDisplay));
        //BLL20d     return null;
        //BLL20d }
        /* Case# 00002186 End */
        // BLL22
        if (PartsOrderError(ro.Id)) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to Void Repair Order because it has open parts orders: ' + openPartsOrders));
        // BLL22 end
        
		if (checkro.dealer__Status__c=='Posted') ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Repair order is already posted.'));
		//BLL20d 	return null;
		//BLL20d }
        // BLL9a end

        //BLL16d ro.dealer__Status__c = 'Void';
        checkro.dealer__Status__c = 'Void';	// BLL16d
        // BLL18a
        checkro.dealer__Invoiced_Date_Time__c = null;	
        List<SObject> updobjs = new List<SObject>();
        updobjs.add(checkro);
        dealer__Service_Job__c jobline = null;
        if (checkro.dealer__Job_Lines__r.size()>0) jobline = new dealer__Service_Job__c(Id=checkro.dealer__Job_Lines__r[0].Id, dealer__Stat__c='Open');	// BLL18a
		if (jobline!=null) updobjs.add(jobline);
		// BLL18a end        

		// BLL20a - don't attempt update if there were errors
		System.debug(ApexPages.getMessages());
		if (ApexPages.hasMessages(ApexPages.Severity.ERROR)) r=null;	// BLL20a
		if (r==null) return r;

        try {
            //BLL16d update ro;
            //BLL18d update checkro;	// BLL16a
            Database.update(updobjs);	// BLL18a
        } catch(DmlException e) {

            System.debug('Failed '+e.getMessage());

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            //BLL20d return null;
        }

        //BLL20d PageReference r = new Apexpages.standardcontroller(ro).view();
        //BLL20d r.getParameters().put('id', ro.id);
        //BLL20d r.setRedirect(true);
		if (ApexPages.hasMessages(ApexPages.Severity.ERROR)) r=null;	// BLL20a
		
        return r;
    }    

    // Update the method to perform cash matching
    public PageReference applyPayment() {
    	// BLL18a
    	if (NeedToRecalcTax()) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must recalculate sales taxes before applying payments to this RO.'));
        //BLL20d     return null;
    	//BLL20d }
    	// BLL18a end
        
        //BLL20d SavePoint sp = Database.setSavepoint();
        System.debug(method);
        if(method==null || method=='') ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Payment Method is Required'));
        //BLL20d     Database.rollback(sp);
        //BLL20d     return null;
        //BLL20d }
        
        // BLL13a
        if (paidBy.dealer__Customer__c==null) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Paid by account is Required'));
        //BLL20d     Database.rollback(sp);
        //BLL20d     return null;
        //BLL20d }
        // BLL13a end

        // BLL21 - cannot create an entry for $0
        if (amount==null || amount==0)  ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Payment amount cannot be $0'));
        // BLL21 end

        // Create the Cashier Line
        dealer__Cashering__c line = new dealer__Cashering__c(
                                            dealer__Service_Repair_Order__c=ro.Id,
                                            dealer__Payment_Method__c=method,
                                            dealer__Deposit__c=deposit,
                                            dealer__Amount__c=amount,
                                            dealer__Customer__c=paidBy.dealer__Customer__c,
                                            dealer__Close_Date__c=Date.today(),
                                            dealer__Credit_Card_Authorization_Code__c=authcode
                                        );
		// BLL26
		line.Method_of_Payment__c = method;
		// BLL26 end

		// BLL20a Only try inserting if there were no errors yet 
		System.debug(ApexPages.getMessages());
		if (ApexPages.hasMessages(ApexPages.Severity.ERROR)) return null;	// BLL20a

		// BLL20 - without try/catch & try/catch/throw blocks, original errors will just be thrown
		// and a rollback is automatic.
        //BLL20d try {
            insert line;
            balance_due -= amount;	// BLL3a
        //BLL20d } catch(DmlException e) {
            //BLL20d ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            //BLL20d Database.rollback(sp);
            //BLL20d return null;
        //BLL20d }

		// BLL20a Only continue if there were no errors yet 
		if (ApexPages.hasMessages(ApexPages.Severity.ERROR)) return null;	// BLL20a

        // Set Invoice Date/Time if Deposit is not marked

        system.debug(deposit);
        system.debug(deposit);

        if(deposit==null || deposit == false) {

            system.debug('applying invoice');
            ro.dealer__Status__c = 'Invoiced';
            ro.dealer__Invoiced_Date_Time__c = Datetime.now();

            // set all job lines to complete
            List<dealer__Service_Job__c> jls = new List<dealer__Service_Job__c>();
            for(dealer__Service_Job__c linelist : [SELECT Id, dealer__Stat__c from dealer__Service_Job__c where dealer__Service_Repair_Order__c=:ro.Id and dealer__Stat__c != 'Complete']) {
                linelist.dealer__Stat__c = 'Complete';
                jls.add(linelist);
            }
            if(jls.size()>0) {
                //BLL20d try {
                    update jls;
                //BLL20d } catch(DmlException e) {
                    //BLL20d Database.rollback(sp);
                //BLL20d     throw new CashierException('Error updating job lines to complete '+e.getMessage());
                //BLL20d }
            }

            //BLL20d try {
                update ro;
            //BLL20d } catch(DmlException e) {
            //BLL20d     Database.rollback(sp);
            //BLL20d     throw new CashierException('Error updating repair order status '+e.getMessage());
            //BLL20d }   
        }

        // Reset the inputs
        clearInputs();        

        // Method called via AJAX, Return Null
        return null;
    }

    /**
     * postInvoice - Commits repair order to the general ledger
     * @return pageReference
     */
    public PageReference postInvoice() {
    	// BLL18a
    	if (NeedToRecalcTax()) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must recalculate sales taxes before posting this RO.'));
        //BLL20d     return null;
    	//BLL20d }
    	// BLL18a end

		// BLL14a
		//BLL16d moved dealer__Service_Repair_Order__c checkro = [
		//BLL16d 	select Id, Name, dealer__Posted_Date_Time__c, dealer__Status__c
		//BLL16d	from dealer__Service_Repair_Order__c
		//BLL16d	where Id=:ro.Id
		//BLL16d ];
		// BLL14a end
        //BLL14d if(ro.dealer__Posted_Date_Time__c!=null) {
        //BLL16d if (checkro.dealer__Posted_Date_Time__c!=null) {	// BLL14a
        //BLL16d    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Repair Order already Posted.'));
        //BLL16d    return null;        
        //BLL16d}

/* Commented code because code moved to method PurchaseOrderError for Case 00002186 Begin 
        //RT2
        List<dealer__Purchase_Order__c> purchaseOrders = [SELECT Id, Name FROM dealer__Purchase_Order__c WHERE dealer__Service_Repair_Order__c = :ro.Id AND dealer__Status__c != 'Accepted' AND dealer__Status__c != 'Void' AND dealer__Status__c != 'Posted'];
		// BLL10a
		List<String> ponames = new List<String>();
		for(dealer__Purchase_Order__c po : purchaseOrders) ponames.add(po.Name);
		String poNumbers = String.join(ponames, ',');
Comment End */      
		// BLL10a
    
        /* Case# 00002186 Begin */
        //BLL20d if(PurchaseOrderError()) {
            //BLL10d String poNumbers = '';
            //BLL10d for(dealer__Purchase_Order__c purchaseOrder : purchaseOrders) {
            //BLL10d     poNumbers += purchaseOrder.Name + ', ';
            //BLL10d }
            //BLL10d poNumbers = poNumbers.removeEnd(', ');
        //BLL20d     ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to Post Repair Order because it is having Open purchase orders: ' + poNumbers));
        //BLL20d     return null;
        //BLL20d }else if(PurchaseOrderLineItemError()){         
        //BLL20d     ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to Post Repair Order because it is having Open Purchase Orders of related Purchase Order Line Items: ' + poNumbersToDisplay));
        //BLL20d     return null;
		//BLL20d }
		if(PurchaseOrderError()) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to Post Repair Order because it is having Open purchase orders: ' + poNumbers));
		else if(PurchaseOrderLineItemError()) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to Post Repair Order because it is having Open Purchase Orders of related Purchase Order Line Items: ' + poNumbersToDisplay));
        /* Case# 00002186 End */
        // BLL22
        if (PartsOrderError(ro.Id)) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to Post Repair Order because it has open parts orders: ' + openPartsOrders));
        // BLL22 end

        // Transaction Control
        SavePoint sp = Database.setSavePoint();

        // Get Sum of REPAIR ORDER 
		// BLL27
        //AggregateResult[] sumCashier = [Select SUM(dealer__Amount__c) asum FROM dealer__Cashering__c where dealer__Service_Repair_Order__c =:ro.Id];
        AggregateResult[] sumCashier = [Select SUM(dealer__Amount__c) asum FROM dealer__Cashering__c where dealer__Service_Repair_Order__c =:ro.Id and Cashiered_while_Posted__c=false];
		// BLL27 end
        Decimal tot = (Decimal)sumCashier[0].get('asum');
        if(tot==null) { tot=0; }    
        if(ro.dealer__Warranty_Charges__c==null) ro.dealer__Warranty_Charges__c=0;

        // BLL8d if((ro.dealer__Customer_Invoice_Total__c) != tot) {  // used to add warranty charges
        // BLL8d    System.debug(ro.dealer__Customer_Invoice_Total__c);
        System.debug(ro.CustomerInvoiceTotal__c);
        System.debug(ro.dealer__Warranty_Charges__c);
        System.debug(tot);
		// BLL25
		Decimal amountDue = ro.CustomerInvoiceTotal__c;
		if (AddDeductibleToAmtDue) amountDue += Math.min(ro.dealer__Warranty_Deductible__c, ro.dealer__Warranty_Charges__c);

        // used to add warranty charges
        //BLL25d if((ro.CustomerInvoiceTotal__c) != tot) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to Post Repair Order until all money is collected.'));
        if(amountDue != tot) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to Post Repair Order until all money is collected.'));
		// BLL25 end
        //BLL20d     return null;            
        //BLL20d }

        //BLL16d moved ro.dealer__Posted_Date_Time__c = Datetime.now();
        //BLL16d ro.dealer__Status__c = 'Posted';

        // DR1
        // Build list of lines Complete lines before RO is set to posted
        List<dealer__Service_Job__c> roLines = [SELECT dealer__Service_Repair_Order__c, dealer__Actual_Time__c, dealer__Book_Time__c, dealer__Cause__c, dealer__Concern__c, dealer__Correction__c, dealer__Customer_Id__c, dealer__Estimate__c, dealer__Gross_Profit__c, dealer__Job_Added_Date__c, dealer__Job_ELR__c, dealer__Job_Finish__c, dealer__Job_Line_Id__c, dealer__Job_Start__c, dealer__Labor_Charges__c, dealer__Labor_Rate__c, dealer__Labor_Type__c, dealer__Line_Number__c, dealer__Line_Total__c, dealer__Op_Code__c, dealer__Operation_Code_Description__c, dealer__Parent_Record__c, dealer__Parts_Cost__c, dealer__Parts_Invoice_Id__c, dealer__Parts_Line__c, dealer__Parts_Total__c, dealer__RO_Invoice_Date_Time__c, dealer__RO_Number__c, dealer__RO_Status__c, dealer__Repair_Order_Id__c, dealer__Repair_Order__c, dealer__Service_Type__c, dealer__Service_Vehicle_Id__c, dealer__Standard_Operation_Code__c, dealer__Stat__c, dealer__Sublet_Cost__c, dealer__Sublet_Total__c, dealer__Technician_Cost__c, dealer__Technician__c, dealer__Currently_Active__c, dealer__Sum_of_Billed_Hours__c, Payment_Notes__c, dealer__Add_On__c, dealer__Misc_Charges__c, dealer__Op_Description__c, dealer__Technician_ID__c, dealer__CustomerConcern__c, dealer__RO_Open_Date_Time__c, dealer__Claim__c, dealer__Paid_By__c, Payment_Method__c, External_ID__c, Name, Id FROM dealer__Service_Job__c where dealer__Service_Repair_Order__c=:ro.Id limit 500];

        // bulk update lines to completed. 
        for(dealer__Service_Job__c line : roLines) {
            if(line.dealer__Stat__c != 'Complete') {
                line.dealer__Stat__c = 'Complete';
            }
        }

		// BLL20a Only continue if there were no errors yet 
		System.debug(ApexPages.getMessages());
		if (ApexPages.hasMessages(ApexPages.Severity.ERROR)) return null;	// BLL20a

		dealer__Service_Repair_Order__c checkro = null;	// bll16a
		try {
		// BLL16 - this should update RO to Cashier automatically if not already there & prevent posting GetReady w/o vehicle
        update roLines;
        // /DR1

		//BLL16a - check right before update & lock RO
			checkro = [
	        	select Id, Name, dealer__Status__c, dealer__Invoiced_Date_Time__c, dealer__Posted_Date_Time__c, dealer__Warranty_Charges__c, dealer__Total_Repair_Order_Charges__c	// BLL16c 
				from dealer__Service_Repair_Order__c
				where Id=:ro.Id
				FOR UPDATE	// BLL16a added 
			];
	        if (checkro.dealer__Posted_Date_Time__c!=null) {	// BLL14a
	            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Repair Order was already Posted.'));
	            //BLL20d return null;        
	        }
            checkro.dealer__Posted_Date_Time__c = Datetime.now();
            checkro.dealer__Status__c = 'Posted';
        } catch(Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Repair order may be in use on another screen. Try again later. \nMessage=' + e.getMessage()));
			//BLL20d return null;
        }
        //BLL16a end

		// BLL20a Only continue if there were no errors yet 
		if (ApexPages.hasMessages(ApexPages.Severity.ERROR)) return null;	// BLL20a

        try {
            //BLL16d update ro;
            update checkro;	// BLL16a
        } catch(DmlException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unknown DML Error : '+e.getMessage()));
            Database.rollback(sp);
            //BLL20d return null;                
        }

		// BLL25a Only continue if there were no errors yet 
		if (ApexPages.hasMessages(ApexPages.Severity.ERROR)) return null;	// BLL20a

        // FFA - Async Posting
        String accountingPayload = '{"recordId" : "'+ro.Id+'", "orgId" : "'+UserInfo.getOrganizationId()+'", "requestedBy" : "'+UserInfo.getUserId()+'", "action" : "service_repair_order_post"}';

        FFAccounting.emailAsyncHandler(accountingPayload);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Repair order is being posted to accounting.'));	// BLL12a
        //BLL12d return null;
		ApexPages.PageReference nextp = returnToRO();	// BLL12a 
        return nextp;	// BLL12a

    }

	/**
	 * Reverse RepairOrder VF Page Message
	 * added JVK9 1/5/2016
	 */
    public void reverseRepairOrder() {
        try {
        	String accountingPayload = '{"recordId" : "'+ro.Id+'", "orgId" : "'+UserInfo.getOrganizationId()+'", "requestedBy" : "'+UserInfo.getUserId()+'", "action" : "service_repair_order_reverse"}';
        	FFAccounting.emailAsyncHandler(accountingPayload);			
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Repair Order Re-Open Request Processing.'));
        } Catch(Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            //BLL20d return null;            
        }

		//BLL20d 
        //BLL20d return null;         
    }

    // BLL1a begin
    // getLocationFFCompany
    //----------------------------------------------------
    public c2g__codaCompany__c getFFCompany(Id compid) {
		// Get FF Company Information - TODO: Based on location this is for!
        c2g__codaCompany__c comp=null;
        if (compid!=null) {
			List<c2g__codaCompany__c> comps = [select Id, Name from c2g__codaCompany__c where Id=:compid];
			if (comps.size()>0) {
		        comp = comps[0];
		        System.debug('Using company ' + comp.Name);
			} else throw new PostingException('Not authorized to the financial company');
        } else throw new PostingException('Missing the financial company');
        
        // Currently selected company
        //List<ID> groupIds = new List<ID>();
		//for(GroupMember member : [select GroupId from GroupMember where Group.Type = 'Queue' and UserOrGroupId = :UserInfo.getUserId()]) {
		//	groupIds.add(member.GroupId);				
		//} 
		//c2g__codaCompany__c[] companies = 
		//	[select RecordType.Name, Id, Name, c2g__TaxCode__c, c2g__CODABaseDate1__c, c2g__CODADaysOffset1__c from c2g__codaCompany__c where OwnerId in :groupIds];
		// Ensure the user has a single current company
		//if (companies.size() == 0)
		//	throw new PostingException('Current company has not been set for this user');
		//if (companies.size() > 1)
		//	throw new PostingException('This operation is not valid in multiple company mode'); 
		//if (companies[0].Id!=comp.Id) 
		//    throw new PostingException('Your current company is ' + companies[0].Name + '. '
		//          + 'Please select the transaction company ' + comp.Name + '.');

		return comp;
    }
    // BLL1a end

    public Id createJournal() {

        // Generate Journal Items for Posting
        if(loc.Company__c==null) throw new CashierException('Dealership Location does not have the Financial Force Company Set.');


        //c2g__codaCompany__c[] compl  =  [Select Id from c2g__codaCompany__c where Id=:loc.Company__c Limit 1];
        //if(compl.size()==0) {
        //    throw new CashierException('Error : Your Location does not have an active Financial Force Company set.  Please select a Financial Force Compny before creating a journal.');
        //}
        //c2g__codaCompany__c comp = compl[0];
        c2g__codaCompany__c comp = getFFCompany(loc.Company__c);  // BLL1a

        // Get Accounting Currency
        c2g__codaAccountingCurrency__c[] curl = [Select Id from c2g__codaAccountingCurrency__c where c2g__OwnerCompany__c =:comp.Id limit 1];
        if(curl.size()==0)  throw new CashierException('Error : The Company Selected does not have an active currency set');

        c2g__codaAccountingCurrency__c cur = curl[0];
        // Get Period Data
        // BLL2d - don't try to set period, FF determines it automatically
        // c2g__codaPeriod__c[] periodl =  [Select Id from c2g__codaPeriod__c where c2g__StartDate__c >=:Date.today() and c2g__Closed__c=false limit 1];
        // if(periodl.size()==0) {
        //    throw new CashierException('Error : Current Accounting Period not Open');
        //}
        //c2g__codaPeriod__c period = periodl[0];
        // BLL2d end
        // Add Error if Period is not open does not exist

        System.debug('Prep Create Journal');

        // Build the Journal
        c2g__codaJournal__c tJrnl       =   new c2g__codaJournal__c();
        tJrnl.c2g__OwnerCompany__c      =   comp.Id;
        tJrnl.c2g__JournalCurrency__c   =   cur.Id;
        //tJrnl.c2g__JournalDescription__c=   'Created by RO Cashier';  // <- Store# 112 or AKR ? Then Proposal Number
        tJrnl.c2g__JournalDescription__c=   'RO Cashier ' + ro.Name;  // BLL1a  
        // BLL2d tJrnl.c2g__JournalDate__c       =   Date.today();
        Date jdate = Date.today();  // BLL2a
        if (ro.dealer__Invoiced_Date_Time__c!=null) jdate = ro.dealer__Invoiced_Date_Time__c.date();  // BLL2a
        tJrnl.c2g__JournalDate__c		=	jdate;  // BLL2a
        tJrnl.c2g__Reference__c         =   ro.Name;
        // BLL2d tJrnl.c2g__Period__c            =   period.Id;
        tJrnl.Source__c = 'SVC';  // BLL1a
        tJrnl.Customer__c = ro.dealer__Customer__c;  // BLL1a 
        tJrnl.Repair_Order__c = ro.Id;  // BLL1a
        //tJrnl.Control__c = ''; // Should be Stock#
        //tJrnl.Refernce# = //RO Number


        System.debug(tJrnl);

        try {
            insert tJrnl;
            System.debug(tJrnl);
        } catch(DmlException e) {
             System.debug(e.getMessage());
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to Create Journal '+e));
             //BLL20d return null; //BLL20-failed insert will return null for the SObject Id anyway
        }   

        System.debug('Method Exit');

        return tJrnl.Id;    
    }

    public c2g__codaJournalLineItem__c journalEntry(Id journal, Id dim, Id account, String type, String drcr, Decimal amount) {
        c2g__codaJournalLineItem__c tempLine = new c2g__codaJournalLineItem__c();   
        tempLine.c2g__Journal__c                =   journal;
        tempLine.c2g__Dimension1__c             =   dim;
        tempLine.c2g__LineDescription__c        =   ro.Name;
        tempLine.c2g__GeneralLedgerAccount__c   =   account;
        tempLine.c2g__Value__c                  =   amount;
        tempLine.c2g__LineType__c               =   type;

        return tempLine;    
    }

    public void clearInputs() {
        //BLL11d paidBy=null; if you want to clear something, clear paidby.dealer__Customer__c, but not paidby itself!
        authcode=null; // BLL11a
        amount=null;
        method=null;
        deposit=null;
    }

    public Decimal credit(Decimal d) {
        if(d==null) {
            return 0;
        } else if(d>0) {
            return d*-1;
        } else {
            return d;
        }

        //return 0;
    }

    public Decimal debit(Decimal d) {
        if(d==null) {
            return 0;
        }

        if(d<0) {
            return d*-1;
        } else {
            return d;
        }

        //return 0;
    }    

    // BLL21
    public void noaction() {}
    public boolean getHaveValidData() {
        return amount!=null && amount!=0 && paidBy.dealer__Customer__c!=null && method!=null;
    }
    // BLL21 end

    // Exception
    public class CashierException extends Exception {}

    public class PostingException extends Exception {}

}