/**
 * ServiceRO_Print
 * Tested by: ServiceRO_Print_TC
 *
 * Coverage:
 *	2019-07-29	89%	(126/141)
 *
 *	2015-09-22	B. Leaman	BLL1 IT14458 - Get location from the RO.
 *	2015-10-06   J. Kuljis   JVK1 IT15140 - Set invoiced time to the local time
 *	2015-10-15	B. Leaman	BLL2 IT15592 - Print description from sublet on customer copy (getServiceJobLines)
 *	2015-12-08	B. Leaman	BLL3 hack-Getting error on ServiceRepairOrderCustomerCopy on vehicle inventory fields;
 *							provide new access to vehicle inventory fields.
 *	2016-01-05   RedTeal     RT1 - Sum the total deposit payments
 *	2016-01-14	B. Leaman	BLL4 - Support for part type (New, Rebuilt, ReConditioned, Used)
 *	2016-01-28	B. Leaman	BLL5 - Obtain default labor rate
 *	2016-10-03	B. Leaman	BLL6 IT#32268 - Print all misc charge types on signature page.
 *	2016-12-02	B. Leaman	BLL7 IR-0003977 - Use custom Labor Cost field instead of DealerTeam technician cost field, which is showing a sum of hourly rates for each tech time entry.
 *	2017-04-20	B. Leaman	BLL8 - Restore total sublet; this isn't included as a misc charge.
 *	2017-12-18	B. Leaman	BLL9 - ignore not finding logo (dev sandboxes).
 *	2018-04-10	B. Leaman	BLL10 - printouts need to see Standard Operation Code on the lines.
 *	2019-04-08	B. Leaman	W-000473 BLL11 - warranty deductible adjustments
 */
public with sharing class ServiceRO_Print {

	public List<MiscChargeSummary> CustMiscCharges {get;private set;}	// BLL6a
	public List<MiscChargeSummary> IntMiscCharges {get;private set;}	// BLL6a
	public List<MiscChargeSummary> WarrMiscCharges {get;private set;}	// BLL6a
	public List<MiscChargeSummary> AllMiscCharges {get;private set;}	// BLL6a
	public dealer__Service_Repair_Order__c ro {get;set;}
	public dealer__Dealer_Location__c userLoc {get;set;}
    public DateTime invoiceTime {get;set;}
    public dealer__Vehicle_Inventory__c vi {get;private set;} // BLL3a

    //RT1
    public Decimal total_deposit {
        get {
            AggregateResult[] sumDeposit = [SELECT SUM(dealer__Amount__c) line FROM dealer__Cashering__c WHERE dealer__Service_Repair_Order__c = :ro.Id AND dealer__Deposit__c = true];
            Decimal total = (Decimal)sumDeposit[0].get('line');
            if(total == null) { 
                total = 0; 
            }
            return total.setScale(2);
        }

        set;
    }

    //BLL6d public Decimal total_hazmat {
    //BLL6d     get {
    //BLL6d         AggregateResult[] sum_hazmat = [Select SUM(Amount__c) line 
    //BLL6d                 FROM ServiceMiscCharges__c 
    //BLL6d                 where Repair_Order_ID__c =:ro.Id
    //BLL6d                 and Type__c = 'Hazardous Materials'];
    //BLL6d         Decimal t = (Decimal)sum_hazmat[0].get('line');
    //BLL6d         if(t==null) { t=0; }
    //BLL6d         return t.setScale(2);
    //BLL6d     }   
    //BLL6d     set;
    //BLL6d }

    //BLL6d public Decimal total_shop {
    //BLL6d     get {
    //BLL6d         AggregateResult[] sum_shop = [Select SUM(Amount__c) line 
    //BLL6d                 FROM ServiceMiscCharges__c 
    //BLL6d                 where Repair_Order_ID__c =:ro.Id
    //BLL6d                 and Type__c = 'Shop Supplies'];
    //BLL6d         Decimal t = (Decimal)sum_shop[0].get('line');
    //BLL6d         if(t==null) { t=0; }
    //BLL6d         return t.setScale(2);
    //BLL6d     }   
    //BLL6d     set;
    //BLL6d }

    //BLL6d public Decimal total_freight {
    //BLL6d     get {
    //BLL6d         AggregateResult[] sumf = [Select SUM(Amount__c) line 
    //BLL6d                 FROM ServiceMiscCharges__c 
    //BLL6d                 where Repair_Order_ID__c =:ro.Id
    //BLL6d                 and Type__c = 'Freight'];
    //BLL6d         Decimal t = (Decimal)sumf[0].get('line');
    //BLL6d         if(t==null) { t=0; }
    //BLL6d         return t.setScale(2);
    //BLL6d     }   
    //BLL6d     set;
    //BLL6d } 

	// BLL8a restore these
    public Decimal total_sublet {
       get {
            AggregateResult[] sumf = [Select SUM(dealer__Sublet_Total__c) line From dealer__Service_Job__c where dealer__Service_Repair_Order__c=:ro.Id];
            Decimal t = (Decimal)sumf[0].get('line');
            if(t==null) { t=0; }
            return t.setScale(2);
        }   
        set;
    }        

    public Decimal total_sublet_w {
        get {
            AggregateResult[] sumf = [Select SUM(dealer__Sublet_Total__c) line From dealer__Service_Job__c where dealer__Service_Repair_Order__c=:ro.Id AND dealer__Labor_Type__c = 'W'];
            Decimal t = (Decimal)sumf[0].get('line');
            if(t==null) { t=0; }
            return t.setScale(2);
        }   
        set;
    }  

    public Decimal total_sublet_cust {
       get {
            AggregateResult[] sumf = [Select SUM(dealer__Sublet_Total__c) line From dealer__Service_Job__c where dealer__Service_Repair_Order__c=:ro.Id AND (Payment_Method__r.Payment_Type__c = 'C' OR dealer__Labor_Type__c = 'C')];
            Decimal t = (Decimal)sumf[0].get('line');
            if(t==null) { t=0; }
            return t.setScale(2);
        }   
        set;
    }

    //BLL6d public Decimal total_hazmat_w {
    //BLL6d     get {
    //BLL6d         AggregateResult[] sum_hazmat = [Select SUM(Amount__c) line 
    //BLL6d                 FROM ServiceMiscCharges__c 
    //BLL6d                 where Repair_Order_ID__c =:ro.Id
    //BLL6d                 and Type__c = 'Hazardous Materials'
    //BLL6d                 and Payment_Type__c = 'W'];
    //BLL6d         Decimal t = (Decimal)sum_hazmat[0].get('line');
    //BLL6d         if(t==null) { t=0; }
    //BLL6d         return t.setScale(2);
    //BLL6d     }   
    //BLL6d     set;
    //BLL6d }

    //BLL6d public Decimal total_shop_w {
    //BLL6d     get {
    //BLL6d         AggregateResult[] sum_shop = [Select SUM(Amount__c) line 
    //BLL6d                 FROM ServiceMiscCharges__c 
    //BLL6d                 where Repair_Order_ID__c =:ro.Id
    //BLL6d                 and Type__c = 'Shop Supplies'
    //BLL6d                 and Payment_Type__c = 'W'];
    //BLL6d         Decimal t = (Decimal)sum_shop[0].get('line');
    //BLL6d         if(t==null) { t=0; }
    //BLL6d         return t.setScale(2);
    //BLL6d     }   
    //BLL6d     set;
    //BLL6d }

    //BLL6d public Decimal total_freight_w {
    //BLL6d     get {
    //BLL6d         AggregateResult[] sumf = [Select SUM(Amount__c) line 
    //BLL6d                 FROM ServiceMiscCharges__c 
    //BLL6d                 where Repair_Order_ID__c =:ro.Id
    //BLL6d                 and Type__c = 'Freight'
    //BLL6d                 and Payment_Type__c = 'W'];
    //BLL6d         Decimal t = (Decimal)sumf[0].get('line');
    //BLL6d         if(t==null) { t=0; }
    //BLL6d         return t.setScale(2);
    //BLL6d     }   
    //BLL6d     set;
    //BLL6d } 
        
	// BLL11
	public Boolean AddDeductibleToAmtDue {get;set;}
	public Decimal WarrantyDeductible {get;set;}
	// BLL11 end

	public ServiceRO_Print(ApexPages.StandardController controller) {
		
		// BLL1a - need the company field
		Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.dealer__Service_Repair_Order__c.fields.getMap();
        List<String> fieldList = new List<String>();
        Set<String> fieldNames = fieldMap.keySet(); 
        fieldList.add('dealer__Company__c');
		fieldList.add('dealer__Warranty_Deductible__c');	// BLL11a
        fieldList.addAll(fieldNames);
        if(!Test.isRunningTest()) controller.addFields(fieldList);
		// BLL1a end

		// Get Record
		ro 	=	(dealer__Service_Repair_Order__c)controller.getRecord();

		// BLL11
		MW_TriggerControls__c RODeductibleAddToTotal = MW_TriggerControls__c.getInstance('RODeductibleAddToTotal');
		AddDeductibleToAmtDue = (RODeductibleAddToTotal==null || RODeductibleAddToTotal.Enabled__c);
		if (ro.dealer__Warranty_Deductible__c==null) ro.dealer__Warranty_Deductible__c = 0;
		if (ro.dealer__Warranty_Charges__c==null) ro.dealer__Warranty_Charges__c = 0;
		if (AddDeductibleToAmtDue) WarrantyDeductible = Math.min(ro.dealer__Warranty_Deductible__c, ro.dealer__Warranty_Charges__c);
		// BLL11 end

        //JVK1
        invoiceTime = null;
        // JRP1 Use Posted Date as Invoiced Date first... cases where posted RO has blank Invoice Date
        if(ro.dealer__Posted_Date_Time__c!=null) {
            TimeZone tz = UserInfo.getTimeZone();
            invoiceTime = ro.dealer__Posted_Date_Time__c.AddSeconds(tz.getOffset(ro.dealer__Posted_Date_Time__c)/1000);
        }
        if(ro.dealer__Invoiced_Date_Time__c!=null) {
            TimeZone tz = UserInfo.getTimeZone();
            invoiceTime = ro.dealer__Invoiced_Date_Time__c.AddSeconds(tz.getOffset(ro.dealer__Invoiced_Date_Time__c)/1000);
        }
        // End JVK1

		// BLL1a - Get location from the RO!
        try {
        	System.debug('Getting location from RO ' + ro.dealer__Company__c);
	        userLoc = [
	        	select Id, Name, dealer__Street__c, dealer__City__c, dealer__Company_Number__c, dealer__Main_Phone__c, dealer__Postal_Code__c, dealer__State__c, dealer__Website__c, BAR_Number__c, EPA_Number__c, Tax_ID__c, Customer_Pay_Labor_Rate__c, dealer_License_name__c // BLL5c
	        	from dealer__Dealer_Location__c 
	        	where Id = :ro.dealer__Company__c
	        	LIMIT 1
	        ];
        } catch(Exception e) {  
        // BLL1a - end - default to user loc -- should NEVER happen, so commented out
            System.debug(e.getMessage());  // BLL1a
	    //    String userId = UserInfo.getUserId();
	    //    String userLocKey = [SELECT Division FROM User WHERE Id =: userId LIMIT 1].Division;
	    //    if(userLocKey!=null&&userLocKey!='') {
	    //        userLoc = [SELECT Id, Name, dealer__Address__c, dealer__City__c, dealer__Company_Number__c, dealer__Main_Phone__c, dealer__Postal_Code__c, dealer__State__c, dealer__Website__c, BAR_Number__c, EPA_Number__c, Tax_ID__c FROM dealer__Dealer_Location__c WHERE dealer__Company_Number__c =: userLocKey LIMIT 1];
	    //    } else {
	            userLoc = null;
	    //    }
        } // BLL1a
        System.debug(userLoc); // BLL1a
        
        // BLL3a
        if (ro.dealer__Vehicle_Inventory__c!=null) {
        	try {
        	vi = [
        		select dealer__VIN__c, dealer__Year__c, dealer__Make__c, dealer__Model__c, dealer__License__c, dealer__Stock_Number__c
        		from dealer__Vehicle_Inventory__c 
        		where Id=:ro.dealer__Vehicle_Inventory__c
        	];
        	} catch(Exception e) {}
        }
        // BLL3a end
        
        // BLL6a sum up all misc charges by type - always generate lines for Freight, HazMat, Sublet, Shop supplies
        Map<String,MiscChargeSummary> CustMiscChargeMap = new Map<String,MiscChargeSummary>();
        Map<String,MiscChargeSummary> WarrMiscChargeMap = new Map<String,MiscChargeSummary>();
        Map<String,MiscChargeSummary> IntMiscChargeMap = new Map<String,MiscChargeSummary>();
        Map<String,MiscChargeSummary> AllMiscChargeMap = new Map<String,MiscChargeSummary>();
        //CustMiscChargeMap.put('Freight', new MiscChargeSummary('Freight', 0.00));
        //CustMiscChargeMap.put('Hazardous Materials', new MiscChargeSummary('Hazardous Materials', 0.00));
        //CustMiscChargeMap.put('Shop Supplies', new MiscChargeSummary('Shop Supplies', 0.00));
        //CustMiscChargeMap.put('Sublet', new MiscChargeSummary('Sublet', 0.00));
        System.debug(CustMiscChargeMap.values());
		AggregateResult[] sumf = [Select Service_Job_Line__r.dealer__Labor_Type__c PmtType, Type__c, SUM(Amount__c) amt 
			from ServiceMiscCharges__c 
			where Repair_Order_ID__c =:ro.Id
			group by Service_Job_Line__r.dealer__Labor_Type__c, Type__c
		];
		for(AggregateResult ar : sumf) {
			System.debug(ar);
			String pmtt = (String) ar.get('PmtType');
			String mctype = (String) ar.get('Type__c');
			Decimal amt = (Decimal) ar.get('amt');
			MiscChargeSummary mcs = CustMiscChargeMap.get(mctype);
			if (pmtt=='W') mcs = WarrMiscChargeMap.get(mctype);
			if (pmtt=='I') mcs = IntMiscChargeMap.get(mctype);
			if (mcs==null) mcs = new MiscChargeSummary(mctype, 0.00);
			mcs.Amount += amt;
			if (pmtt=='W') WarrMiscChargeMap.put(mctype, mcs);
			if (pmtt=='I') IntMiscChargeMap.put(mctype, mcs);
			if (pmtt!='W' && pmtt!='I') CustMiscChargeMap.put(mctype, mcs);
			// Total summary of all misc charges
			MiscChargeSummary amcs = AllMiscChargeMap.get(mctype);
			if (amcs==null) amcs = new MiscChargeSummary(mctype, 0.00);
			amcs.Amount += amt;
			AllMiscChargeMap.put(mctype, amcs);
		}
		System.debug(CustMiscChargeMap);
		System.debug(IntMiscChargeMap);
		System.debug(WarrMiscChargeMap);
		CustMiscCharges = CustMiscChargeMap.values();
		IntMiscCharges = IntMiscChargeMap.values();
		WarrMiscCharges = WarrMiscChargeMap.values();
		AllMiscCharges = AllMiscChargeMap.values();
        // BLL6a end
	}

    public string printDateTime { 
            get {
                datetime dt = datetime.now();
                return dt.format('MM/dd/yyyy HH:mm a');
            }
    }    

    public String getInvoiceLogo() {
    	String rtnURL = null;	// BLL9a
    	try {	// BLL9a
        	Document doc = [Select Id from Document Where DeveloperName = 'InvoiceLogo' limit 1];
        	String imageId = doc.Id;
        	imageId = imageId.substring(0,15);
        	rtnURL = 'servlet/servlet.FileDownload?file='+imageId;	// BLL9a
        	// BLL9d return 'servlet/servlet.FileDownload?file='+imageId;
    	} catch (Exception e) {}	// BLL9a
    	return rtnURL;	// BLL9a
    }  

    /*
     *  Get Job Lines
     * 
     *      Params: ro.Id
     */
    public List<dealer__Service_Job__c> getServiceJobList() {
        List<dealer__Service_Job__c> jLines = new List<dealer__Service_Job__c>();
        if(ro.Id!=null) {
            jLines = [Select Id, dealer__Labor_Type__c, dealer__Labor_Rate__c,dealer__Actual_Time__c, dealer__Labor_Charges__c,     dealer__Misc_Charges__c, dealer__Cause__c, dealer__CauseExtended__c, dealer__Concern__c, dealer__CustomerConcern__c, dealer__Correction__c,
                            dealer__Op_Code__c, dealer__Line_Total__c, dealer__Parts_Total__c, dealer__Service_Type__c, dealer__Line_Number__c,
                            dealer__Standard_Operation_Code__c, dealer__Standard_Operation_Code__r.Name,  // BLL10a
                            dealer__Operation_Code_Description__c, dealer__Stat__c, dealer__Technician__c, dealer__Book_Time__c , Payment_Method__c, Payment_Method__r.Name,
            				(SELECT dealer__Purchase_Order__c, dealer__Purchase_Order__r.Name, dealer__Account__c, dealer__Description__c, dealer__Part_Quantity__c, dealer__Part__c, dealer__Parts_Invoice__c, dealer__Customer_Total__c, dealer__Service_Job_Line__c, Name, Id FROM dealer__Purchase_Order_Line__r), // BLL2a
                            dealer__Sublet_Total__c 
                        from dealer__Service_Job__c 
                        where dealer__Service_Repair_Order__c =:ro.Id 
                        order by dealer__Line_Number__c asc
                        limit 1000];
        }
        return jLines;
    }  

    
    /*
     * Get Parts Lines
     * 
     *      params: ro.Id
     */
    public List<dealer__Parts_Invoice_Line__c> getServicePartsList() {
        List<dealer__Parts_Invoice_Line__c> plines = new List<dealer__Parts_Invoice_Line__c>();
        if(ro.Id!=null) {
        	// BLL4a add Part_type__c (New, Rebuilt, ReConditioned, Used)
            plines = [SELECT Id, dealer__Job_Line__c, dealer__Service_Job_Line_Number__c, 
                        dealer__Extended_Price__c, dealer__Part_Description__c, dealer__Part_Number__c, dealer__Price__c, dealer__Total_Price__c, dealer__Cost__c, Extended_Cost__c, dealer__Service_Line_Payment_Method__c, dealer__Pay_Type__c, dealer__Quantity_Sold__c, Name, Part_type__c 
                    FROM dealer__Parts_Invoice_Line__c
                    WHERE dealer__Service_Repair_Order__c=:ro.Id
                    ORDER by dealer__Service_Job_Line_Number__c asc
                    LIMIT 1000];
        }
        // BLL4a default part type if missing (default shows as "New" on screen)
        for(dealer__Parts_Invoice_Line__c p : plines) {
        	if (p.Part_type__c==null) p.Part_type__c = 'N';
        }
        // BLL4a
        return plines;
    }  

    /**
     * Get Misc Lines
     * 
     *     Params: ro.Id
     */
    public List<ServiceMiscCharges__c> getMiscList() {
        List<ServiceMiscCharges__c> misclines = new List<ServiceMiscCharges__c>();
        if(ro.Id!=null) {
        misclines = [SELECT Id, Name, Amount__c, Service_Job_Line__c, Type__c from ServiceMiscCharges__c
                    WHERE Repair_Order_ID__c =:ro.Id
                    LIMIT 1000];
        }
        
        return misclines;
    }  

    /**
     * Get Lines "Loaded" List
     * 
     *     Params: ro.Id
     */
    public List<dealer__Service_Job__c> getLinesList() {
        List<dealer__Service_Job__c> linesList = new List<dealer__Service_Job__c>();
        if(ro.Id!=null) {
        linesList = [SELECT ID, Name, dealer__Service_Repair_Order__c, dealer__Actual_Time__c, dealer__Book_Time__c, dealer__Cause__c, dealer__CauseExtended__c, dealer__Concern__c, dealer__Correction__c, dealer__Customer_Id__c, dealer__Estimate__c, dealer__Gross_Profit__c, dealer__Job_Added_Date__c, dealer__Job_ELR__c, dealer__Job_Finish__c, dealer__Job_Line_Id__c, dealer__Job_Start__c, dealer__Labor_Charges__c, dealer__Labor_Rate__c, dealer__Labor_Type__c, dealer__Line_Number__c, dealer__Line_Total__c, dealer__Op_Code__c, dealer__Operation_Code_Description__c, dealer__Parent_Record__c, dealer__Parts_Cost__c, dealer__Parts_Invoice_Id__c, dealer__Parts_Line__c, dealer__Parts_Total__c, dealer__RO_Invoice_Date_Time__c, dealer__RO_Number__c, dealer__RO_Status__c, dealer__Repair_Order_Id__c, dealer__Repair_Order__c, dealer__Service_Type__c, dealer__Service_Vehicle_Id__c, dealer__Standard_Operation_Code__c, dealer__Stat__c, dealer__Sublet_Total__c, dealer__Technician_Cost__c, dealer__Technician__c, dealer__Currently_Active__c, dealer__Sum_of_Billed_Hours__c, Payment_Notes__c, dealer__Add_On__c, dealer__Misc_Charges__c, dealer__Op_Description__c, dealer__Technician_ID__c, dealer__CustomerConcern__c, dealer__RO_Open_Date_Time__c, dealer__Claim__c, dealer__Paid_By__c, Payment_Method__c, Payment_Method__r.Name,
			Labor_Cost__c,	// BLL7a
            (SELECT dealer__Parts_Invoice__c, dealer__Bin__c, dealer__Core__c, dealer__Cost__c, dealer__Counterman_No__c, dealer__Counterman__c, dealer__Currently_Available__c, dealer__Drop_Ship__c, dealer__Extended_Price__c, dealer__Gross_Margin__c, dealer__Job_Line__c, dealer__List__c, dealer__MFG__c, dealer__Net_Price__c, dealer__Net__c, dealer__Order_Type__c, dealer__Part_Description__c, dealer__Part_Number__c, dealer__Part__c, dealer__Pay_Type__c, dealer__Price_Level_Strategy__c, dealer__Price_Level__c, dealer__Price__c, dealer__Quantity_Ordered__c, dealer__Quantity_Sold__c, dealer__Sale_Date__c, dealer__Service_Job_Line_Number__c, dealer__Service_Line_Payment_Method__c, dealer__Service_Repair_Order__c, dealer__Sold_Via__c, dealer__Source__c, dealer__Stocking_Group__c, dealer__Total_Price__c, dealer__Total_Tax__c, dealer__Transaction_Code__c, Name, Id, Extended_Cost__c FROM dealer__Parts_Lines__r),
            (SELECT dealer__Service_Job_Line__c, dealer__Actual_Time__c, dealer__Available_Flat_Rate_Time__c, dealer__Book_Time__c, dealer__Diag_Repair__c, dealer__Efficiency__c, dealer__Elapsed_Time_Minutes__c, dealer__End_Time__c, dealer__Flat_Rate_Time__c, dealer__Job_Name__c, dealer__Job_Status__c, dealer__Labor_Type__c, dealer__Repair_Order_Name__c, dealer__Repair_Order_Number__c, dealer__Start_Time__c, dealer__Technician__c, dealer__Technician__r.Name, dealer__Time_Punch_Notes__c, Time_Clock_Entry__c, dealer__Actual_Time_Entry__c, dealer__Date__c, dealer__Time_Clock__c, Name, Id, Payment_Method_Labor_Rate__c, Labor_Total__c FROM dealer__Technician_Job_Times__r),
            (SELECT dealer__Purchase_Order__c, dealer__Purchase_Order__r.Name, dealer__Account__c, dealer__Amount__c, dealer__Description__c, dealer__Drop_Ship_Address__c, dealer__Drop_Ship_To__c, dealer__Part_Quantity__c, dealer__Part__c, dealer__Parts_Invoice__c, dealer__Customer_Total__c, dealer__Special_Instructions__c, General_Ledger_Account__c, dealer__Service_Job_Line__c, Name, Id FROM dealer__Purchase_Order_Line__r),
            (SELECT Id, Name, Amount__c, Service_Job_Line__c, Type__c from Service_Misc_Charge__r),
                dealer__Standard_Operation_Code__r.Name, dealer__Standard_Operation_Code__r.Id
            FROM dealer__Service_Job__c WHERE dealer__Service_Repair_Order__c =: ro.Id Order By dealer__Line_Number__c ASC limit 2000];
        }
        
        return linesList;
    }  
    
    // BLL5a
    public Decimal getDefaultLaborRate() {
    	Decimal lbrRate = userLoc!=null ? userLoc.Customer_Pay_Labor_Rate__c : null;
    	ServicePaymentType__c spt;
    	try {
    		spt = [select Id from ServicePaymentType__c where Name='CR' limit 1];
    		ServiceLaborRateDefaults__c slrd = [
    			select Id, Labor_Rate__c
    			from ServiceLaborRateDefaults__c
    			where Location__c=:userLoc.Id and Service_Payment_Method__c=:spt.Id
    			limit 1
    		];
    		lbrRate = slrd.Labor_Rate__c;
    	} catch(Exception e) {}
		return lbrRate;
    }
    // BLL5a end

	// BLL6a
	public class MiscChargeSummary {
		public String Type {get;set;}
		public Decimal Amount {get;set;}
		public MiscChargeSummary(String chgtype, Decimal amt) {
			Type = chgtype;
			Amount = amt;
		}
	}
	// BLL6a end

}