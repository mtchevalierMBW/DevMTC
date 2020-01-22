/**
 * FFA_ServiceDepartment - Facilitates the async posting of Service documents
 * Tested by: FFA_ServiceDepartment_TC
 *
 *  Test coverage log:
 *  2017-07-01  36% (239/656)
 *  2017-07-02  76% (459/602) 
 *  2017-11-14  76% (467/610)
 *  2018-01-17  76% (468/611)
 *	2019-01-04	78%	(491/625)
 *
 * 2016-01-25   B. Leaman   BLL1 - Add monitor email capability for RO issues we're having.
 * 2016-01-26   J. Kuljis   JVK2 - HALF Rounding on the Misc Charges Amount
 * 2016-02-21   B. Leaman   BLL2 - GetReady adds to conversion cost on a commercial vehicle.
 * 2016-03-03   B. Leaman   BLL3 - Bulkify queries during postRepairOrder.
 * 2016-03-28   RedTeal     RT1  - Moved transaction/journal creations to different try blocks
 * 2016-04-01   B. Leaman   BLL8 - Standardize preference of ro's vehicle inventory reference rather than service veh reference to inventory;
 *                          Do vehicle inventory cost update regardless of whether a service vehicle is specified (uses inventory vehicle)
 * 2016-04-15   B. Leaman   BLL9 IT#23367 - fix update to commercial vehicle conversion cost to look at MCEO lines only.
 * 2016-06-10   B. Leaman   BLL10 Fix error where no Labor_Cost_Of_Sale journal line was created because there were no labor charges,
 *                          but there were labor hours, so it needs to update that line.
 * 2016-06-12   J. Kuljis   JVK3 - If there is a cost of labor but not a sale amount add an account# to the jLines MAP (NULL Reference Error Fix)
 * 2016-06-20   J. Kuljis   JVK4 - If the Journal is not in Balance, do not post.  This is rolling back the entire transaction.
 * 2016-06-20   J. Kuljis   JVK5 - Associate the Vehicle Inventory Record ID with the Service Vehicle if it is not already there.
 * 2016-06-23   J. Kuljis   JVK6 - Use DB Savepoints to control rollback of events in postRepairOrder
 * 2016-06-29   J. Kuljis   JVK7 - Only allow current month posting, per Jeff Smith.
 *                                 Period   *       Accounting period in which this document falls. Calculated from the document date, or by default the period 
 *                                 that contains the date of input, but you can amend it by selecting a new period. If you enter a document date for a year that 
 *                                 does not exist in your organization, then the period is set to blank. You can only save a document or post a transaction 
 *                                 to an open period.
 * 2016-07-11   B. Leaman   BLL11 Fix control numbers again. 1240 (MCEO) s/b stock#; 1280 s/b deal or quote#.
 * 2016-07-12   B. Leaman   BLL12 Ignore vehicle type -- MCEO adds to conversion, GRxV adds to chassis.
 * 2016-08-04   B. Leaman   BLL13 Fix control numbers again. 1240 & 1280 when there is not other deal or quote# referenced. 
 * 2016-08-23   J. Kuljis   JVK8 - Set Scale on line.dealer__Sublet_Cost__c
 * 2016-10-26   B. Leaman   BLL14 - Missing vehicle inventory references on journal lines for RO posting.
 * 2016-11-08   B. Leaman   BLL15 - Inventory reserve support.
 * 2016-11-18   J. Kuljis   JVK9 - Correct bug allowing sublet with 0 cost to cutomer to bypass posting to the repair order sublet CS / Sale Account
 * 2016-12-01   B. Leaman   BLL16 - correct error message
 * 2016-12-29   B. Leaman   BLL17 - Replace custom lookups with managed versions (Deal obj) - only changed commented out code 
 * 2017-01-19   B. Leaman   BLL18 - Use RO's vehicle inventory reference, if specified.
 * 2017-06-05   B. Leaman   BLL19 - reference vehicle on inventory reserve.
 * 2017-07-02   B. Leaman   BLL20 - Remove BLL15 Inventory Reserve support. Too many issues like
 *                          veh moves to rental and reserve won't be relieved. 
 * 2017-11-14   B. Leaman   BLL21 - move getready vehicle cost updates to separate routine that can be used in re-open process too.
 * 2018-04-20   B. Leaman   BLL22 - fix cashiering entries for RO posting - was lumping all into 1 account's A/R.
 * 2018-05-10   B. Leaman   BLL23 - fix cashiering entries again -- wasn't combining credit/refund; was replacing value causing out-of-balance journal;
 *							also, record each cashiering entry separately for posting (by using cashier rcd id instead of composit key of gl acct, cust account, & pay method);
 * 2018-07-30	B. Leaman	BLL24 - allow posting when running tests.
 * 2018-10-18   B. Leaman   BLL25 - Support for multiple warranty accounts; add error message text when journal failes to create;
 * 2018-11-19   B. Leaman   W-000487    BLL26 - Warranty receivable account can be Account - Customer or General Ledger Account line type, depending on GL acct.
 *							Also change parts return from A/R 1112 to clearing 2114 acct.
 * 2019-01-08	B. Leaman	W-000539 BLL27 - handle case where stock vehicle is specified, but service vehicle is not.
 * 2019-04-08	B. Leaman	W-000473 BLL28 - reduce warranty clearing by deductible.
 * 2019-05-02	B. Leaman	W-000575 BLL29 - only include cashiering entries that were created while the RO
 *							was still open. (Don't create A/R for additional cash received after posting when RO is re-opened and re-posted!)
 * 2019-06-19	B. Leaman	W-000710 BLL30 - Hit account's correct AR account (Accounts Receivable Control) that is used in cash entry.
 * 2019-07-15	B. Leaman	W-000575 impl BLL31 - force using an AR account for warranty if the vendor pays instead of issueing credits for warranty.
 * 2019-08-30	B. Leaman	W-000749 BLL32 - don't force null conversion cost to $0 unless we need to adjust the conversion cost (due to MCEO labor type)
 * 2019-11-26	B. Leaman	W-000796 BLL33 - protect against double-posting
 */
public without sharing class FFA_ServiceDepartment {
    public FFA_ServiceDepartment() {}

    /**
     * postPartsReturn
     */
    public static void postPartsReturn(Id invoiceId) {
        // Basic function is to Debit parts inventory and Credit 1112 (Returns A/R)
        Map<String, c2g__codaGeneralLedgerAccount__c> gl_accounts = new Map<String, c2g__codaGeneralLedgerAccount__c>();
		// BLL26
        //Set<String> rc = new Set<String>{'1220','1112'};
        //for(c2g__codaGeneralLedgerAccount__c gl : [Select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c IN:rc limit 10]) {
        //    gl_accounts.put(gl.c2g__ReportingCode__c, gl);
        //}
        //Set<String> rc = new Set<String>{'1220','1112','2114'};
		MobilityForceSettings__c mfs = MobilityForceSettings__c.getOrgDefaults();
		if (String.isBlank(mfs.Parts_Return_Credit_Acct__c)) mfs.Parts_Return_Credit_Acct__c = '1220';
		if (String.isBlank(mfs.Parts_Return_Debit_Acct__c)) mfs.Parts_Return_Debit_Acct__c = '2114';
        Set<String> rc = new Set<String>();
		rc.add(mfs.Parts_Return_Credit_Acct__c);
		rc.add(mfs.Parts_Return_Debit_Acct__c);
        for(c2g__codaGeneralLedgerAccount__c gl : [Select Id, Name, c2g__ReportingCode__c, c2g__GLAGroup__c from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c IN:rc limit 10]) {
            gl_accounts.put(gl.c2g__ReportingCode__c, gl);
        }
        Map<String,String> jrnLineTypeMap = new Map<String,String>{
            'Accounts Receivable'=>'Account - Customer',
            'Accounts Payable'=>'Account - Vendor'
        };
		// BLL26 end

        // Get the invoice 
        dealer__Parts_Invoice__c pi = [Select Id, Name, dealer__Customer__c, dealer__Location__c from dealer__Parts_Invoice__c where Id=:invoiceId limit 1];

        // Get the location information
        dealer__Dealer_Location__c loc = FFAccounting.getDealerLocation(pi.dealer__Location__c); 

        // Get the Lines
        List<dealer__Parts_Invoice_Line__c> lines = [Select Id, Name, dealer__Counterman__c, dealer__Parts_Invoice__c, 
                                                        dealer__Quantity_Sold__c, dealer__Part__c, dealer__Part_Number__c,
                                                        dealer__Part_Description__c, dealer__Cost__c, dealer__Purchase_Order_Line__c, 
                                                        dealer__Purchase_Order_Line__r.Name, 
                                                        dealer__Purchase_Order_Line__r.dealer__Purchase_Order__c 
                                                            From dealer__Parts_Invoice_Line__c 
                                                        Where dealer__Parts_Invoice__c=:pi.Id];


        // Create the Journal
        c2g__codaJournal__c journalHeader       =   new c2g__codaJournal__c();
        journalHeader.c2g__OwnerCompany__c      =   FFAccounting.getFFCompany(pi.dealer__Location__c);
        journalHeader.c2g__Period__c            =   FFAccounting.getCurrentPeriod(journalHeader.c2g__OwnerCompany__c); // JVK7
        journalHeader.c2g__JournalCurrency__c   =   FFAccounting.currency(journalHeader.c2g__OwnerCompany__c);
        journalHeader.c2g__JournalDescription__c=   'Parts Return ' + pi.Name; 
        Date jdate = Date.today();
        journalHeader.c2g__JournalDate__c       =   jdate;
        journalHeader.c2g__Reference__c         =   pi.Name;
        journalHeader.Source__c                 =   'SVC';
        journalHeader.Customer__c               =   pi.dealer__Customer__c;
		// BLL26
		journalHeader.Vendor__c			=	pi.dealer__Customer__c;
		// BLL26 end

        // Prepare the Lines
        Decimal debitAR = 0;
        List<c2g__codaJournalLineItem__c> jLines = new List<c2g__codaJournalLineItem__c>();
        for(dealer__Parts_Invoice_Line__c pl : lines) {

            // incriment the debit value
            debitAR+=pl.dealer__Cost__c;

            jLines.add(new c2g__codaJournalLineItem__c(
                    c2g__Journal__c=null,
                    c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                    c2g__LineNumber__c=1,
                    c2g__LineDescription__c=pi.Name + ' ' + pl.dealer__Part_Number__c,
                    //BLL26
					//c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('1220').Id,
					c2g__GeneralLedgerAccount__c=(String)gl_accounts.get(mfs.Parts_Return_Credit_Acct__c).Id,
					// BLL26 end
                    c2g__Value__c=FFAccounting.credit(pl.dealer__Cost__c),
                    c2g__LineType__c='General Ledger Account',
					// BLL26
					Vendor_Name__c = pi.dealer__Customer__c,
					// BLL26 end
                    Control__c=pi.Name
                )
            );            
        } 

		// BLL26
        //jLines.add(new c2g__codaJournalLineItem__c(
		c2g__codaJournalLineItem__c debitline = new c2g__codaJournalLineItem__c(
		// BLL26 end
                c2g__Journal__c=null,
                c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                c2g__LineNumber__c=2,
                c2g__LineDescription__c=pi.Name,
				// BLL26
                //c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('1112').Id,
				c2g__GeneralLedgerAccount__c=(String)gl_accounts.get(mfs.Parts_Return_Debit_Acct__c).Id,
				// BLL26 end
                c2g__Value__c=FFAccounting.debit(debitAR),
				// BLL26
                //c2g__LineType__c='Account - Customer', 
                //c2g__Account__c=pi.dealer__Customer__c,
				c2g__LineType__c='General Ledger Account', 
				Vendor_Name__c = pi.dealer__Customer__c,
				// BLL26 end
                Control__c=pi.Name
		// BLL26
        //    )
		// BLL26 end
        );         
		// BLL26
        String linetype = jrnLineTypeMap.get((String) gl_accounts.get(mfs.Parts_Return_Debit_Acct__c).c2g__GLAGroup__c);
        if (!String.isBlank(linetype)) debitline.c2g__LineType__c = linetype;
        if (!String.isBlank(linetype)) debitline.c2g__Account__c = pi.dealer__Customer__c;
		jLines.add(debitline);
		// BLL26 end

        // Create and post the Journal
        try {
             
             Id journalId = FinancialForce_MBW.createJournalApi(journalHeader, jLines);
             FFAccounting.postJournal(journalId);
             FFAccounting.applyJournalToRegister(pi.Id, journalId);

        } Catch(DmlException e) {
            FFA_ServiceDepartment.notifyException('postPartsReturn', e, invoiceId, journalHeader, jLines); // BLL1a
            throw new FFASException('Error posting transaction '+e.getMessage());
        }
        // BLL1a   
        Catch(Exception e) {
            FFA_ServiceDepartment.notifyException('postPartsReturn', e, invoiceId, journalHeader, jLines); 
            throw new FFASException('Error posting transaction '+e.getMessage());
        }
        // BLL1a end
    }

    /**
     * postRepairOrder - commit a repair order to the General Ledger
     * @param roId Record ID of the repair order
     * @return  void - no return
     */
    public static void postRepairOrder(Id roId) {

        // BLL11a
        Set<String> glDocCtlNbr = new Set<String>{'1280'};
        Set<String> glStockCtlNbr = new Set<String>{'1240'};
        // BLL11a end

        // Transaction Control
        SavePoint sp = Database.setSavePoint();

        // Records we will be using to commit to the General Ledger
        dealer__Service_Repair_Order__c ro;
        List<dealer__Service_Job__c> roLines;

        // Get the Entire RO And Related Lines
        // //
        DescribeSObjectResult describeRO = dealer__Service_Repair_Order__c.getSObjectType().getDescribe();
        List<String> ro_fieldNames = new List<String>( describeRO.fields.getMap().keySet() );
        ro_fieldNames.add('dealer__Vehicle__r.dealer__Sales_Inventory__c');
        ro_fieldNames.add('dealer__Vehicle__r.dealer__Stock_Number__c');
        ro_fieldNames.add('dealer__Vehicle_Inventory__r.dealer__Stock_Number__c');  // BLL8a
        ro_fieldNames.add('Deal__r.Name');  // BLL11a
        ro_fieldNames.add('CommercialQuote__r.Name');   // BLL11a

        DescribeSObjectResult describeJob = dealer__Service_Job__c.getSObjectType().getDescribe();
        List<String> job_fieldNames = new List<String>( describeJob.fields.getMap().keySet() );

        ro = Database.query('SELECT ' + String.join( ro_fieldNames, ',' ) + ' FROM dealer__Service_Repair_Order__c WHERE Id = \''+String.escapeSingleQuotes(roId) +'\' limit 1 ');
        roLines = Database.query('SELECT ' + String.join( job_fieldNames, ',' )+ ' FROM dealer__Service_Job__c WHERE dealer__Service_Repair_Order__c = \''+String.escapeSingleQuotes(roId) +'\' LIMIT 200');
        System.debug(roId);
        System.debug(ro.Id);

		// BLL33 - Protect against double posting
		if (ro.Journal__c!=null) {
			c2g__codaJournal__c jrn = [
				select Id, Name, c2g__JournalStatus__c,
					(select Id, Name from c2g__ReversingJournals__r),
					(select Id, Name from c2g__CancellingJournals__r)
				from c2g__codaJournal__c
				where Id=:ro.Journal__c
			];
			if (jrn.c2g__ReversingJournals__r.size()==0 && jrn.c2g__CancellingJournals__r.size()==0) {
                insert(new Error_Log__c(
					trace__c=ro.Name + ' was previously posted and has not been reversed or cancelled'
				));
				return;
			}
		}
		// BLL33 end

        // Prepare the Journal and Lines for Commit
        dealer__Dealer_Location__c loc = FFAccounting.getDealerLocation(ro.dealer__Company__c);
        if(loc.Financial_Force_Dimension_1__c==null) { throw new FFASException('Financial Force Dimension 1 not set for Location '+ro.dealer__Company__c); }

        // JVK7
        // Enforce Strict Current Period Posting
            Id ownerCompanyId = FFAccounting.getFFCompany(loc.Id);
            Id periodId = FFAccounting.getCurrentPeriod(ownerCompanyId);

            if(periodId == null) {

                Database.rollback(sp);

                //String errorMsg = 'Current period is non-existant or closed for ' + ro.Name;
                //Error_Log__c log = new Error_Log__c();
                //log.trace__c = errorMsg;
                //insert log;
                insert(new Error_Log__c(trace__c='Current period is non-existant or closed for ' + ro.Name)); 

                return;                
            } 
        // End JVK7

        Id journalIdNull = null;
        c2g__codaJournal__c journalHeader = new c2g__codaJournal__c();
        //BLL15d Map<Id, c2g__codaJournalLineItem__c> jLines = new Map<Id, c2g__codaJournalLineItem__c>();
        Map<String, c2g__codaJournalLineItem__c> jLines = new Map<String, c2g__codaJournalLineItem__c>();   // BLL15a - Don't want to combine inventory reserve lines with existing ones!       
        
        // Loop Lines
        Decimal line_number     = 1;
        Decimal timeLabor       = 0;
        Decimal labor_cost      = 0;
        Decimal freight_total   = 0;
        Decimal shop_total      = 0;
        Decimal hazmat_total    = 0;
		// BLL28
		Decimal remainingDeductible = ro.dealer__Warranty_Deductible__c;
		if (remainingDeductible==null || remainingDeductible<0) remainingDeductible=0;
		// BLL28 end

        Id laborSaleAccount;

        //BLL3d AggregateResult[] shopSupplies;
        //BLL3d AggregateResult[] freightCharges;

        c2g__codaGeneralLedgerAccount__c shop_supplies_account = [Select Id from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c = '5202' limit 1];
        c2g__codaGeneralLedgerAccount__c freight_account = [Select Id from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c = '4905' limit 1];

        // BLL1a - List of accounts to get link to vehicle inventory (12xx except 1220)
        Map<Id, c2g__codaGeneralLedgerAccount__c> vehGlAccts = new Map<Id, c2g__codaGeneralLedgerAccount__c>([
            select Id, c2g__ReportingCode__c 
            from c2g__codaGeneralLedgerAccount__c
            //BLL14d where c2g__ReportingCode__c like '12%' and c2g__ReportingCode__c != '1220' and c2g__ReportingCode__c!='1221'
            where VehicleRequired__c=true   //BLL14a
        ]);
        // BLL1a end
        // BLL11a
        Map<Id,c2g__codaGeneralLedgerAccount__c> docGlAcctMap = new Map<Id,c2g__codaGeneralLedgerAccount__c>();
        for(c2g__codaGeneralLedgerAccount__c gla : vehGlAccts.values()) {
            if (glDocCtlNbr.contains(gla.c2g__ReportingCode__c)) docGlAcctMap.put(gla.Id, gla);
        }
        Map<Id,c2g__codaGeneralLedgerAccount__c> stockGlAcctMap = new Map<Id,c2g__codaGeneralLedgerAccount__c>();
        for(c2g__codaGeneralLedgerAccount__c gla : vehGlAccts.values()) {
            if (glstockCtlNbr.contains(gla.c2g__ReportingCode__c)) stockGlAcctMap.put(gla.Id, gla);
        }
        // BLL11a end

        // Repair Orders can be controlled by either a Stock# if on an inventory record or the RO number
        String controlnbr = null;
        // BLL11a
        String documentnbr = null;  
        String stocknbr = null; 
        if (ro.dealer__Vehicle_Inventory__r.dealer__Stock_Number__c!=null) stocknbr = ro.dealer__Vehicle_Inventory__r.dealer__Stock_Number__c;
        if (stocknbr==null && ro.dealer__Vehicle__r.dealer__Stock_Number__c!=null) stocknbr = ro.dealer__Vehicle__r.dealer__Stock_Number__c; 
        // BLL11a - end

        Id vehInv = null;  // reference to be stored in journal lines
        //BLL14d if (ro.GetReady_RO__c==true) { 
            if (ro.dealer__Vehicle__c!=null) {
                //BLL8d vehInv = ro.dealer__Vehicle__r.dealer__Sales_Inventory__c;  // ro.dealer__Vehicle_Inventory__c is not always set!
                // BLL8a
                vehInv = vehInv = ro.dealer__Vehicle_Inventory__c;
                if (vehInv==null && ro.dealer__Vehicle__r!=null)  vehInv = ro.dealer__Vehicle__r.dealer__Sales_Inventory__c;
                // BLL11d if (ro.dealer__Vehicle_Inventory__r.dealer__Stock_Number__c!=null) controlnbr = ro.dealer__Vehicle_Inventory__r.dealer__Stock_Number__c;
                // BLL8a
                // BLL11d if (ro.dealer__Vehicle__r.dealer__Stock_Number__c!=null && ro.dealer__Vehicle_Inventory__r.dealer__Stock_Number__c==null) controlnbr = ro.dealer__Vehicle__r.dealer__Stock_Number__c; // BLL8c
                //BLL14d controlnbr = stocknbr; // BLL11a
				// BLL27
                //if (ro.GetReady_RO__c || ro.CommercialConversionEquip__c) controlnbr = stocknbr;    // BLL14a
				// BLL27 end
            }
        //BLL14d }
		// BLL27
        if (!String.isBlank(stocknbr) && (ro.GetReady_RO__c || ro.CommercialConversionEquip__c))
			controlnbr = stocknbr; 
		// BLL27 end

        // Check to see if we have a Deal# associated with this Repair Order
        //BLL11d if (controlnbr==null) {
            // BLL11d dealer__Deal__c[] deal = [select Id, Name from dealer__Deal__c where dealer__DeliveryRepairOrder__c=:ro.Id ]; // BLL17c
            // BLL11d if (deal.size()==1) {
            // BLL11d   controlnbr = deal[0].Name;
            // BLL11d }
        // BLL11d }
        if (ro.Deal__c!=null && ro.Deal__r.Name!=null) documentnbr = ro.Deal__r.Name;   // BLL11a
        if (ro.CommercialQuote__c!=null && ro.CommercialQuote__r.Name!=null) documentnbr = ro.CommercialQuote__r.Name;  // BLL11a
        if (controlnbr==null) controlnbr = documentnbr; // BLL11a
        if (controlnbr==null) controlnbr = ro.Name;


        // BLL3a - bulkify queries that were running for every RO line
        // Get payment methods needed
        Set<Id> spmIds = new Set<Id>();
        for(dealer__Service_Job__c line : roLines) spmIds.add(line.Payment_Method__c);
        // BLL26 - Need GL account type 
        //Map<Id,ServicePaymentType__c> spmMap = new Map<Id,ServicePaymentType__c>([
        //    select Id, Name, Default_Labor_Rate__c, Payment_Type__c, Labor_Sale_Account__c, Labor_Cost_of_Sale_Account__c, Warranty_Receivable_Account__c, Description__c, Shop_Supplies_Rate__c, Hazmat_Fee__c, Freight_Rate__c, Parts_Sales__c, Parts_Cost_of_Sale__c, Parts_Inventory__c, Work_In_Process__c, Warranty_Billing_Account__c, Internal_Sales__c, Sublet_Inventory__c, Sublet_Sales__c, Sublet_CS__c
        //        // BLL20d , Inventory_Reserve__c    // BLL15a 
        //    from ServicePaymentType__c 
        //    where Id in :spmIds
        //]);
        Map<Id,ServicePaymentType__c> spmMap = new Map<Id,ServicePaymentType__c>([
            select Id, Name, Default_Labor_Rate__c, Payment_Type__c, Description__c, 
                Shop_Supplies_Rate__c, Hazmat_Fee__c, Freight_Rate__c, 
                Labor_Sale_Account__c, Labor_Cost_of_Sale_Account__c, 
                Warranty_Receivable_Account__c, Warranty_Receivable_Account__r.c2g__GLAGroup__c, 
                Parts_Sales__c, Parts_Cost_of_Sale__c, 
                Parts_Inventory__c, Work_In_Process__c, Warranty_Billing_Account__c, Internal_Sales__c, 
				Warranty_Billing_Account__r.WarrantyAsReceivable__c, Warranty_Billing_Account__r.c2g__CODAAccountsReceivableControl__c,	Warranty_Billing_Account__r.c2g__CODAAccountsPayableControl__c, // BLL31
                Sublet_Inventory__c, Sublet_Sales__c, Sublet_CS__c
            from ServicePaymentType__c 
            where Id in :spmIds
        ]);
        Map<String,String> jrnLineTypeMap = new Map<String,String>{
            'Accounts Receivable'=>'Account - Customer',
            'Accounts Payable'=>'Account - Vendor'
        };
        // BLL26 end
        // summarize freight charges by line
        List<AggregateResult> frtSmry = [
            select Service_Job_Line__c, SUM(Amount__c) line 
            from ServiceMiscCharges__c 
            where Service_Job_Line__r.dealer__Service_Repair_Order__c = :ro.Id and Type__c = 'Freight'
            group by Service_Job_Line__c
        ];
        Map<Id, AggregateResult> frtMap = new Map<Id, AggregateResult>();
        for(AggregateResult ar : frtSmry) frtMap.put((Id) ar.get('Service_Job_Line__c'), ar);                          
        // Other misc charges
        Map<Id, List<ServiceMiscCharges__c>> mscMap = new Map<Id, List<ServiceMiscCharges__c>>();
        for(ServiceMiscCharges__c m : [
            select Id, Service_Job_Line__c, Type__c, Quantity__c, Amount__c, General_Ledger_Account__c 
            from ServiceMiscCharges__c 
            where Service_Job_Line__r.dealer__Service_Repair_Order__c = :ro.Id and Type__c != 'Freight'
            ]) {
            List<ServiceMiscCharges__c> smc;
            if (mscMap.containsKey(m.Service_Job_Line__c)) smc = mscMap.get(m.Service_Job_Line__c);
            else smc = new List<ServiceMiscCharges__c>();
            smc.add(m);
            mscMap.put(m.Service_Job_Line__c, smc); 
        }
        // BLL3a end
        
        // BLL20d Map<Id,Decimal> invreserve = new Map<Id,Decimal>();   // BLL15a
        Set<String> getReadyPmtMethods=new Set<String>{'GRNV','GRUV'};  // BLL15a
        Set<String> addVehRefPmtMthds=new Set<String>{'MCEO','GRNV','GRUV'};    // BLL14a
        
        for(dealer__Service_Job__c line : roLines) {

            System.debug('Starting job line ' + line.Id);                               

            // Check to see that Job Line has a Payment Method
            if(line.Payment_Method__c == null) {

                // JVK6
                Database.rollback(sp);

                //String errorMsg = 'Line payment method is blank for Repair Order ' + ro.Name;
                //Error_Log__c log = new Error_Log__c();
                //log.trace__c = errorMsg;
                //insert log; 
                insert(new Error_Log__c(trace__c='Line payment method is blank for Repair Order ' + ro.Name)); 

                return; 
                //JVK6

            }

            // Get Payment Settings
            // BLL3d ServicePaymentType__c payment_method = [SELECT Default_Labor_Rate__c, Payment_Type__c, Labor_Sale_Account__c, Labor_Cost_of_Sale_Account__c, Warranty_Receivable_Account__c, Description__c, Shop_Supplies_Rate__c, Hazmat_Fee__c, Freight_Rate__c, Parts_Sales__c, Parts_Cost_of_Sale__c, Parts_Inventory__c, Work_In_Process__c, Name, Id, Warranty_Billing_Account__c, Internal_Sales__c, Sublet_Inventory__c, Sublet_Sales__c, Sublet_CS__c FROM ServicePaymentType__c where Id=:line.Payment_Method__c limit 1];
            ServicePaymentType__c payment_method = spmMap.get(line.Payment_Method__c);  // BLL3a

            boolean addVehRef = addVehRefPmtMthds.contains(payment_method.Name);    // BLL14a

            if(payment_method.Labor_Cost_of_Sale_Account__c == null ||
                payment_method.Labor_Sale_Account__c == null ||
                payment_method.Parts_Sales__c == null ||
                payment_method.Parts_Cost_of_Sale__c == null ||
                payment_method.Parts_Inventory__c == null ||
                payment_method.Work_In_Process__c ==null) {
                

                // JVK6
                    Database.rollback(sp);

                    //String errorMsg = 'Payment Method contains a null value on one or more account lines Repair Order ' + ro.Name +'\r\n'+JSON.serializePretty(payment_method);
                    //Error_Log__c log = new Error_Log__c();
                    //log.trace__c = errorMsg;
                    //insert log; 
                    insert(new Error_Log__c(trace__c='Payment Method contains a null value on one or more account lines Repair Order ' + ro.Name +'\r\n'+JSON.serializePretty(payment_method))); 

                    return; 
                // End JVK6
            }

            // Set Labor Sale Account
            laborSaleAccount = payment_method.Labor_Sale_Account__c;
            /*
            |   LABOR SALES
            */
            if(jLines.get(payment_method.Labor_Sale_Account__c)==null && line.dealer__Labor_Charges__c>0) {
                jLines.put(payment_method.Labor_Sale_Account__c, new c2g__codaJournalLineItem__c(
                        c2g__Journal__c=journalIdNull,
                        c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                        c2g__LineDescription__c='Labor Sales '+ro.Name,
                        c2g__LineNumber__c=line_number,
                        c2g__GeneralLedgerAccount__c=payment_method.Labor_Sale_Account__c,
                        c2g__Value__c=0,
                        c2g__DebitCredit__c='Credit',
                        c2g__LineType__c='General Ledger Account',
                        Vehicle_Inventory__c = (addVehRef && vehGlAccts.containsKey(payment_method.Labor_Sale_Account__c)?vehInv:null), // BLL1a, BLL14c
                        Customer_Name__c = ro.dealer__Customer__c,  // BLL4a
                        Control__c=controlnbr  // BLL1c was ro.Name
                    )
                );
                line_number++;
            }

            if(line.dealer__Labor_Charges__c != null && line.dealer__Labor_Charges__c>0) {
                jLines.get(payment_method.Labor_Sale_Account__c).c2g__Value__c-=line.dealer__Labor_Charges__c.setScale(2, System.RoundingMode.HALF_UP);
            }

            /*
            |   LABOR COST OF SALES
            */
            if(jLines.get(payment_method.Labor_Cost_of_Sale_Account__c)==null 
                && (line.dealer__Labor_Charges__c>0 || line.dealer__Actual_Time__c!=null && line.dealer__Actual_Time__c>0)) {   // BLL10c add tests for actual time
                if(loc.Internal_Labor_Rate__c==null) { throw new FFASException('Internal Labor Rate must be set on the Location'); } // *Could be outside the loop
                jLines.put(payment_method.Labor_Cost_of_Sale_Account__c, new c2g__codaJournalLineItem__c(
                        c2g__Journal__c=journalIdNull,
                        c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                        c2g__LineDescription__c='Labor Cost of Sales '+ro.Name,
                        c2g__LineNumber__c=line_number,
                        c2g__GeneralLedgerAccount__c=payment_method.Labor_Cost_of_Sale_Account__c,
                        c2g__Value__c=0,
                        c2g__DebitCredit__c='Debit',
                        c2g__LineType__c='General Ledger Account',
                        Vehicle_Inventory__c = (addVehRef && vehGlAccts.containsKey(payment_method.Labor_Cost_of_Sale_Account__c)?vehInv:null), // BLL1a, BLL14c
                        Customer_Name__c = ro.dealer__Customer__c,  // BLL4a
                        Control__c=controlnbr  // BLL1c was ro.Name
                    )
                );
                line_number++;
            }

            // Throwing an error if there is no labor_cost.  
            if(line.dealer__Actual_Time__c!=null&&line.dealer__Actual_Time__c>0) {
                labor_cost = (line.dealer__Actual_Time__c*loc.Internal_Labor_Rate__c);
                System.debug(labor_cost);

                // JVK3
                // Error can occur of the labor value is 0 but there is a cost of labor
                c2g__codaJournalLineItem__c lcos = new c2g__codaJournalLineItem__c(
                            c2g__Journal__c=journalIdNull,
                            c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                            c2g__LineDescription__c='Labor Cost of Sales '+ro.Name,
                            c2g__LineNumber__c=line_number,
                            c2g__GeneralLedgerAccount__c=payment_method.Labor_Cost_of_Sale_Account__c,
                            c2g__Value__c=0,
                            c2g__DebitCredit__c='Debit',
                            c2g__LineType__c='General Ledger Account',
                            Vehicle_Inventory__c = (addVehRef && vehGlAccts.containsKey(payment_method.Labor_Cost_of_Sale_Account__c)?vehInv:null), // BLL1a, BLL14c
                            Customer_Name__c = ro.dealer__Customer__c,  // BLL4a
                            Control__c=controlnbr  // BLL1c was ro.Name
                            );

                if(jLines.get(payment_method.Labor_Cost_of_Sale_Account__c)==null) {
                        //jLines.put(payment_method.Labor_Cost_of_Sale_Account__c, new c2g__codaJournalLineItem__c(
                        //    c2g__Journal__c=journalIdNull,
                        //    c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                        //    c2g__LineDescription__c='Labor Cost of Sales '+ro.Name,
                        //    c2g__LineNumber__c=line_number,
                        //    c2g__GeneralLedgerAccount__c=payment_method.Labor_Cost_of_Sale_Account__c,
                        //    c2g__Value__c=0,
                        //    c2g__DebitCredit__c='Debit',
                        //    c2g__LineType__c='General Ledger Account',
                        //    Vehicle_Inventory__c = (addVehRef && vehGlAccts.containsKey(payment_method.Labor_Cost_of_Sale_Account__c)?vehInv:null), // BLL1a, BLL14c
                        //    Customer_Name__c = ro.dealer__Customer__c,  // BLL4a
                        //    Control__c=controlnbr  // BLL1c was ro.Name
                        //    )
                        //);
                        jLines.put(payment_method.Labor_Cost_of_Sale_Account__c, lcos);
                        line_number++;
                }
                // End JVK3

                jLines.get(payment_method.Labor_Cost_of_Sale_Account__c).c2g__Value__c += labor_cost.setScale(2);
            }

            /*
            |   WORK IN PROCESS
            */          
            if(jLines.get(payment_method.Work_In_Process__c)==null) {  //JVK3 (Remove Labor_Charges__c>0)
                if(loc.Internal_Labor_Rate__c==null) { throw new FFASException('Internal Labor Rate must be set on the Location'); } // *Could be outside the loop
                jLines.put(payment_method.Work_In_Process__c, new c2g__codaJournalLineItem__c(
                        c2g__Journal__c=journalIdNull,
                        c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                        c2g__LineDescription__c='Work in Process '+ro.Name,
                        c2g__LineNumber__c=line_number,
                        c2g__GeneralLedgerAccount__c=payment_method.Work_In_Process__c,
                        c2g__Value__c=0,
                        c2g__DebitCredit__c='Credit',
                        c2g__LineType__c='General Ledger Account',
                        Vehicle_Inventory__c = (addVehRef && vehGlAccts.containsKey(payment_method.Work_In_Process__c)?vehInv:null), // BLL1a, BLL14c
                        Customer_Name__c = ro.dealer__Customer__c,  // BLL4a
                        Control__c=controlnbr  // BLL1c was ro.Name
                    )
                );
                line_number++;
            }

            if(line.dealer__Actual_Time__c!=null&&line.dealer__Actual_Time__c>0) {
                timeLabor =    (line.dealer__Actual_Time__c*loc.Internal_Labor_Rate__c);
                jLines.get(payment_method.Work_In_Process__c).c2g__Value__c -= timeLabor.setScale(2);
            }

            /*
            |   PARTS RO SALES
            */
            if(line.dealer__Parts_Total__c==null) {line.dealer__Parts_Total__c=0;}
            if(line.dealer__Parts_Cost__c==null) {line.dealer__Parts_Total__c=0;}
            c2g__codaJournalLineItem__c ps = new c2g__codaJournalLineItem__c(
                        c2g__Journal__c=journalIdNull,
                        c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                        c2g__LineDescription__c='Parts Sales '+ro.Name,
                        c2g__LineNumber__c=line_number,
                        c2g__GeneralLedgerAccount__c=payment_method.Parts_Sales__c,
                        c2g__Value__c=0,
                        c2g__DebitCredit__c='Credit',
                        c2g__LineType__c='General Ledger Account',
                        Vehicle_Inventory__c = (addVehRef && vehGlAccts.containsKey(payment_method.Parts_Sales__c)?vehInv:null), // BLL1a, BLL14c
                        Customer_Name__c = ro.dealer__Customer__c,  // BLL4a
                        Control__c=controlnbr  // BLL1c was ro.Name
            );
            if(jLines.get(payment_method.Parts_Sales__c)==null && line.dealer__Parts_Total__c>0) {
                //jLines.put(payment_method.Parts_Sales__c, new c2g__codaJournalLineItem__c(
                //        c2g__Journal__c=journalIdNull,
                //        c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                //        c2g__LineDescription__c='Parts Sales '+ro.Name,
                //        c2g__LineNumber__c=line_number,
                //        c2g__GeneralLedgerAccount__c=payment_method.Parts_Sales__c,
                //        c2g__Value__c=0,
                //        c2g__DebitCredit__c='Credit',
                //        c2g__LineType__c='General Ledger Account',
                //        Vehicle_Inventory__c = (addVehRef && vehGlAccts.containsKey(payment_method.Parts_Sales__c)?vehInv:null), // BLL1a, BLL14c
                //        Customer_Name__c = ro.dealer__Customer__c,  // BLL4a
                //        Control__c=controlnbr  // BLL1c was ro.Name
                //    )
                //);
                jLines.put(payment_method.Parts_Sales__c, ps);
                line_number++;
            }

            if(line.dealer__Parts_Total__c>0) jLines.get(payment_method.Parts_Sales__c).c2g__Value__c -= line.dealer__Parts_Total__c;

            /*
            |   PARTS COST OF SALE
            */
            c2g__codaJournalLineItem__c pcos = new c2g__codaJournalLineItem__c(
                        c2g__Journal__c=journalIdNull,
                        c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                        c2g__LineDescription__c='Parts Cost of Sales '+ro.Name,
                        c2g__LineNumber__c=line_number,
                        c2g__GeneralLedgerAccount__c=payment_method.Parts_Cost_of_Sale__c,
                        c2g__Value__c=0,
                        c2g__DebitCredit__c='Debit',
                        c2g__LineType__c='General Ledger Account',
                        Vehicle_Inventory__c = (addVehRef && vehGlAccts.containsKey(payment_method.Parts_Cost_of_Sale__c)?vehInv:null), // BLL1a, BLL14c
                        Customer_Name__c = ro.dealer__Customer__c,  // BLL4a
                        Control__c=controlnbr  // BLL1c was ro.Name
            );            
            if(jLines.get(payment_method.Parts_Cost_of_Sale__c)==null && line.dealer__Parts_Cost__c>0) {
                //jLines.put(payment_method.Parts_Cost_of_Sale__c, new c2g__codaJournalLineItem__c(
                //        c2g__Journal__c=journalIdNull,
                //        c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                //        c2g__LineDescription__c='Parts Cost of Sales '+ro.Name,
                //        c2g__LineNumber__c=line_number,
                //        c2g__GeneralLedgerAccount__c=payment_method.Parts_Cost_of_Sale__c,
                //        c2g__Value__c=0,
                //        c2g__DebitCredit__c='Debit',
                //        c2g__LineType__c='General Ledger Account',
                //        Vehicle_Inventory__c = (addVehRef && vehGlAccts.containsKey(payment_method.Parts_Cost_of_Sale__c)?vehInv:null), // BLL1a, BLL14c
                //        Customer_Name__c = ro.dealer__Customer__c,  // BLL4a
                //        Control__c=controlnbr  // BLL1c was ro.Name
                //    )
                //);
                jLines.put(payment_method.Parts_Cost_of_Sale__c, pcos);
                line_number++;
            }

            if(line.dealer__Parts_Cost__c>0) jLines.get(payment_method.Parts_Cost_of_Sale__c).c2g__Value__c += line.dealer__Parts_Cost__c;

            /*
            |   PARTS INVENTORY CREDIT
            */      
            c2g__codaJournalLineItem__c pi = new c2g__codaJournalLineItem__c(
                        c2g__Journal__c=journalIdNull,
                        c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                        c2g__LineDescription__c='Parts Cost of Sales '+ro.Name,
                        c2g__LineNumber__c=line_number,
                        c2g__GeneralLedgerAccount__c=payment_method.Parts_Inventory__c,
                        c2g__Value__c=0,
                        c2g__DebitCredit__c='Credit',
                        c2g__LineType__c='General Ledger Account',
                        Vehicle_Inventory__c = (addVehRef && vehGlAccts.containsKey(payment_method.Parts_Inventory__c)?vehInv:null), // BLL1a, BLL14c
                        Customer_Name__c = ro.dealer__Customer__c,  // BLL4a
                        Control__c=controlnbr  // BLL1c was ro.Name
            );
            if(jLines.get(payment_method.Parts_Inventory__c)==null && line.dealer__Parts_Cost__c>0) {
                //jLines.put(payment_method.Parts_Inventory__c, new c2g__codaJournalLineItem__c(
                //        c2g__Journal__c=journalIdNull,
                //        c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                //        c2g__LineDescription__c='Parts Cost of Sales '+ro.Name,
                //        c2g__LineNumber__c=line_number,
                //        c2g__GeneralLedgerAccount__c=payment_method.Parts_Inventory__c,
                //        c2g__Value__c=0,
                //        c2g__DebitCredit__c='Credit',
                //        c2g__LineType__c='General Ledger Account',
                //        Vehicle_Inventory__c = (addVehRef && vehGlAccts.containsKey(payment_method.Parts_Inventory__c)?vehInv:null), // BLL1a, BLL14c
                //        Customer_Name__c = ro.dealer__Customer__c,  // BLL4a
                //        Control__c=controlnbr  // BLL1c was ro.Name
                //    )
                //);
                jLines.put(payment_method.Parts_Inventory__c, pi);
                line_number++;
            }

            if(line.dealer__Parts_Cost__c>0) jLines.get(payment_method.Parts_Inventory__c).c2g__Value__c -= line.dealer__Parts_Cost__c;

            /*
            |   FREIGHT CHARGES ON THIS LINE
            */
            //BLL3d freightCharges = [Select SUM(Amount__c) line 
            //BLL3d                                FROM ServiceMiscCharges__c 
            //BLL3d                                where Service_Job_Line__c =:line.Id
            //BLL3d                                and Type__c = 'Freight'];
            Decimal freightCharges = frtMap.containsKey(line.Id) ? (Decimal) frtMap.get(line.Id).get('line') : 0.00;    // BLL3a
            //BLL3d if(jLines.get(freight_account.Id)==null && (Decimal)freightCharges[0].get('line')>0) {
            if(jLines.get(freight_account.Id)==null && freightCharges>0) {
                jLines.put(freight_account.Id, new c2g__codaJournalLineItem__c(
                        c2g__Journal__c=journalIdNull,
                        c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                        c2g__LineDescription__c='Freight Charges '+ro.Name,
                        c2g__LineNumber__c=line_number,
                        c2g__GeneralLedgerAccount__c=freight_account.Id,
                        c2g__Value__c=0,
                        c2g__DebitCredit__c='Credit',
                        c2g__LineType__c='General Ledger Account',
                        Vehicle_Inventory__c = (addVehRef && vehGlAccts.containsKey(freight_account.Id)?vehInv:null), // BLL1a, BLL14c
                        Customer_Name__c = ro.dealer__Customer__c,  // BLL4a
                        Control__c=controlnbr  // BLL1c was ro.Name
                    )
                );
                line_number++;
            }

            //BLL3dif((Decimal)freightCharges[0].get('line')>0) {
            if (freightCharges>0) { // BLL3a
                //BLL3d freight_total = (Decimal)freightCharges[0].get('line');
                freight_total = freightCharges.setScale(2, System.RoundingMode.HALF_UP);    // BLL3a
                jLines.get(freight_account.Id).c2g__Value__c -= freight_total.setScale(2);
            }

            /*
            |   SHOP / HAZ / OTHER THIS LINE
            */
            //RT1
            //BLL3d List<ServiceMiscCharges__c> miscCharges = [SELECT Id, Service_Job_Line__c, Type__c, Quantity__c, Amount__c, General_Ledger_Account__c 
            //BLL3d                                            FROM ServiceMiscCharges__c WHERE Service_Job_Line__c = :line.Id AND Type__c != 'Freight'];
            List<ServiceMiscCharges__c> miscCharges = mscMap.containsKey(line.Id) ? mscMap.get(line.Id) : new List<ServiceMiscCharges__c>();    // BLL3a
            System.debug('Shop supplies: ' + miscCharges);
            for(ServiceMiscCharges__c miscCharge : miscCharges) {
                c2g__codaJournalLineItem__c currentLine = jLines.get(miscCharge.General_Ledger_Account__c);
                if(currentLine == null) {
                    currentLine = new c2g__codaJournalLineItem__c(
                        c2g__Journal__c=journalIdNull,
                        c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                        c2g__LineDescription__c=miscCharge.Type__c,
                        c2g__LineNumber__c=line_number,
                        c2g__GeneralLedgerAccount__c=miscCharge.General_Ledger_Account__c,
                        c2g__Value__c=miscCharge.Amount__c.setScale(2, System.RoundingMode.HALF_UP) * -1, // HALF_UP ROUNDING - JVK1
                        c2g__DebitCredit__c='Credit',
                        c2g__LineType__c='General Ledger Account',
                        //Vehicle_Inventory__c = (vehGlAccts.containsKey(shop_supplies_account.Id)?vehInv:null), // BLL1a
                        Vehicle_Inventory__c = (addVehRef && vehGlAccts.containsKey(miscCharge.General_Ledger_Account__c)?vehInv:null), // BLL1a, BLL14c
                        Customer_Name__c = ro.dealer__Customer__c,  // BLL4a
                        Control__c=controlnbr  // BLL1c was ro.Name
                    );
                    jLines.put(miscCharge.General_Ledger_Account__c, currentLine);
                }
                else { currentLine.c2g__Value__c += miscCharge.Amount__c.setScale(2) * -1; }
                line_number++;
            }
           

            /*
            |   WARRANTY CHARGES
            */
            // BLL25a summarize warranty by the billing account (not GL account)
            /**BLL25d 
            c2g__codaJournalLineItem__c wr = new c2g__codaJournalLineItem__c(
                            c2g__Journal__c=journalIdNull,
                            c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                            c2g__LineDescription__c='Warranty Sales '+ro.Name,
                            c2g__LineNumber__c=line_number,
                            c2g__GeneralLedgerAccount__c=payment_method.Warranty_Receivable_Account__c,
                            c2g__Value__c=0,
                            c2g__DebitCredit__c='Debit',
                            c2g__LineType__c='Account - Customer', // JVK7 - IT16191 Change to Customer to allow payable credits
                            c2g__Account__c=payment_method.Warranty_Billing_Account__c,
                            Vehicle_Inventory__c = (addVehRef && vehGlAccts.containsKey(payment_method.Warranty_Receivable_Account__c)?vehInv:null), // BLL1a, BLL14c
                            Customer_Name__c = ro.dealer__Customer__c,  // BLL4a
                            Control__c=controlnbr  // BLL1c was ro.Name
            );
            BLL25d end **/
            if(payment_method.Payment_Type__c=='W') {
                //BLL25d if(jLines.get(payment_method.Warranty_Receivable_Account__c)==null && line.dealer__Line_Total__c>0) {
                //BLL25d    jLines.put(payment_method.Warranty_Receivable_Account__c, new c2g__codaJournalLineItem__c(
                if(jLines.get(payment_method.Warranty_Billing_Account__c)==null && line.dealer__Line_Total__c>0) {  // BLL25a

                    // BLL26 - Variable Line Type based on GL account type 
                    //jLines.put(payment_method.Warranty_Billing_Account__c, new c2g__codaJournalLineItem__c(          // BLL25a
                    //        c2g__Journal__c=journalIdNull,
                    //        c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                    //        c2g__LineDescription__c='Warranty Sales '+ro.Name,
                    //        c2g__LineNumber__c=line_number,
                    //        c2g__GeneralLedgerAccount__c=payment_method.Warranty_Receivable_Account__c,
                    //        c2g__Value__c=0,
                    //        c2g__DebitCredit__c='Debit',
                    //        c2g__LineType__c='Account - Customer', // JVK7 - IT16191 Change to Customer to allow payable credits
                    //        c2g__Account__c=payment_method.Warranty_Billing_Account__c,
                    //        Vehicle_Inventory__c = (addVehRef && vehGlAccts.containsKey(payment_method.Warranty_Receivable_Account__c)?vehInv:null), // BLL1a, BLL14c
                    //        Customer_Name__c = ro.dealer__Customer__c,  // BLL4a
                    //        Control__c=controlnbr  // BLL1c was ro.Name
                    //    )
                    //);
                    c2g__codaJournalLineItem__c warrRcvLine = new c2g__codaJournalLineItem__c(          // BLL25a
                            c2g__Journal__c=journalIdNull,
                            c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                            c2g__LineDescription__c='Warranty Sales '+ro.Name,
                            c2g__LineNumber__c=line_number,
                            c2g__GeneralLedgerAccount__c=payment_method.Warranty_Receivable_Account__c,
                            c2g__Value__c=0,
                            c2g__DebitCredit__c='Debit',
                            c2g__LineType__c='General Ledger Account', 
                            Vehicle_Inventory__c = (addVehRef && vehGlAccts.containsKey(payment_method.Warranty_Receivable_Account__c)?vehInv:null), 
                            Customer_Name__c = ro.dealer__Customer__c,
							// BLL26
							Vendor_Name__c = payment_method.Warranty_Billing_Account__c,
							// BLL26 end
                            Control__c=controlnbr  
                    );
                    String linetype = jrnLineTypeMap.get(payment_method.Warranty_Receivable_Account__r.c2g__GLAGroup__c);
                    if (!String.isBlank(linetype)) warrRcvLine.c2g__LineType__c = linetype;
                    if (!String.isBlank(linetype)) warrRcvLine.c2g__Account__c = payment_method.Warranty_Billing_Account__c;
					// BLL31
					if (payment_method.Warranty_Billing_Account__r.WarrantyAsReceivable__c) {
						if (linetype=='Account - Customer' && payment_method.Warranty_Billing_Account__r.c2g__CODAAccountsReceivableControl__c!=null) 
							warrRcvLine.c2g__GeneralLedgerAccount__c = payment_method.Warranty_Billing_Account__r.c2g__CODAAccountsReceivableControl__c;
						if (linetype=='Account - Vendor' && payment_method.Warranty_Billing_Account__r.c2g__CODAAccountsPayableControl__c!=null) 
							warrRcvLine.c2g__GeneralLedgerAccount__c = payment_method.Warranty_Billing_Account__r.c2g__CODAAccountsPayableControl__c;
					}		
					// BLL31 end
                    jLines.put(payment_method.Warranty_Billing_Account__c, warrRcvLine);
                    // BLL26 end

                    //BLL25d jLines.put(payment_method.Warranty_Receivable_Account__c, wr);
                    line_number++;
                }
                if(line.dealer__Line_Total__c>0) {
                    //BLL25d jLines.get(payment_method.Warranty_Receivable_Account__c).c2g__Value__c += line.dealer__Line_Total__c;
                    // BLL28d jLines.get(payment_method.Warranty_Billing_Account__c).c2g__Value__c += line.dealer__Line_Total__c;  // BLL25a
					c2g__codaJournalLineItem__c warr = jLines.get(payment_method.Warranty_Billing_Account__c);
					warr.c2g__Value__c += line.dealer__Line_Total__c;
					// BLL28
					Decimal applyDeductibleAmt = Math.min(warr.c2g__Value__c, remainingDeductible);
					if (applyDeductibleAmt>0) warr.c2g__Value__c -= applyDeductibleAmt;
					remainingDeductible -= applyDeductibleAmt; 
					// BLL28 end
                }
            }           

            /*
            |   INTERNAL CHARGES
            */  
            if(payment_method.Payment_Type__c=='I') {
                if(jLines.get(payment_method.Internal_Sales__c)==null && line.dealer__Line_Total__c>0) {
                    jLines.put(payment_method.Internal_Sales__c, new c2g__codaJournalLineItem__c(
                            c2g__Journal__c=journalIdNull,
                            c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                            c2g__LineDescription__c='Internal Sales '+ro.Name,
                            c2g__LineNumber__c=line_number,
                            c2g__GeneralLedgerAccount__c=payment_method.Internal_Sales__c,
                            c2g__Value__c=0,
                            c2g__DebitCredit__c='Debit',
                            c2g__LineType__c='General Ledger Account',
                            Vehicle_Inventory__c = (addVehRef && vehGlAccts.containsKey(payment_method.Internal_Sales__c)?vehInv:null), // BLL1a, BLL14c
                            Customer_Name__c = ro.dealer__Customer__c,  // BLL4a
                            Control__c=controlnbr  // BLL1c was ro.Name
                        )
                    );
                    line_number++;
                }

                if(line.dealer__Line_Total__c>0) {
                    jLines.get(payment_method.Internal_Sales__c).c2g__Value__c += line.dealer__Line_Total__c;
                }
            }  

            /*
            |   SUBLET CHARGES
            */            
            c2g__codaJournalLineItem__c ss = new c2g__codaJournalLineItem__c(
                                c2g__Journal__c=journalIdNull,
                                c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                                c2g__LineDescription__c='Sublet Sales '+ro.Name,
                                c2g__LineNumber__c=line_number,
                                c2g__GeneralLedgerAccount__c=payment_method.Sublet_Sales__c,
                                c2g__Value__c=FFAccounting.credit(line.dealer__Sublet_Total__c).setScale(2, System.RoundingMode.HALF_UP),
                                c2g__DebitCredit__c='Credit',
                                c2g__LineType__c='General Ledger Account',
                                Vehicle_Inventory__c = (addVehRef && vehGlAccts.containsKey(payment_method.Sublet_Sales__c)?vehInv:null), // BLL1a, BLL14c
                                Customer_Name__c = ro.dealer__Customer__c,  // BLL4a
                                Control__c=controlnbr  // BLL1c was ro.Name
            );    
            c2g__codaJournalLineItem__c scos = new c2g__codaJournalLineItem__c(
                                c2g__Journal__c=journalIdNull,
                                c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                                c2g__LineDescription__c='Sublet C/S '+ro.Name,
                                c2g__LineNumber__c=line_number,
                                c2g__GeneralLedgerAccount__c=payment_method.Sublet_CS__c,
                                c2g__Value__c=  FFAccounting.debit(line.dealer__Sublet_Cost__c).setScale(2, System.RoundingMode.HALF_UP), // BLL6c FFAccounting.debit(line.dealer__Sublet_Total__c), JVK6 replace with subCost and setscale
                                c2g__DebitCredit__c='Debit',
                                c2g__LineType__c='General Ledger Account',
                                Vehicle_Inventory__c = (addVehRef && vehGlAccts.containsKey(payment_method.Sublet_CS__c)?vehInv:null), // BLL1a, BLL14c
                                Customer_Name__c = ro.dealer__Customer__c,  // BLL4a
                                Control__c=controlnbr  // BLL1c was ro.Name
            );
            c2g__codaJournalLineItem__c sinv =new c2g__codaJournalLineItem__c(
                                c2g__Journal__c=journalIdNull,
                                c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                                c2g__LineDescription__c='Sublet Inventory '+ro.Name,
                                c2g__LineNumber__c=line_number,
                                c2g__GeneralLedgerAccount__c=payment_method.Sublet_Inventory__c,
                                c2g__Value__c=FFAccounting.credit(line.dealer__Sublet_Cost__c).setScale(2, System.RoundingMode.HALF_UP), // BLL6c FFAccounting.credit(line.dealer__Sublet_Total__c), JVK8 replace with SubCost
                                c2g__DebitCredit__c='Credit',
                                c2g__LineType__c='General Ledger Account',
                                Vehicle_Inventory__c = (addVehRef && vehGlAccts.containsKey(payment_method.Sublet_Inventory__c)?vehInv:null), // BLL1a, BLL14c
                                Customer_Name__c = ro.dealer__Customer__c,  // BLL4a
                                //BLL6d Control__c=controlnbr  // BLL1c was ro.Name
                                Control__c=ro.name // BLL6a
            );
            if(line.dealer__Sublet_Total__c != null && (line.dealer__Sublet_Total__c >= 0 || line.dealer__Sublet_Cost__c >= 0)) { //JVK9
                // Check the setup of the Payment Method to see if we are able top close this RO
                if(payment_method.Sublet_CS__c == null || payment_method.Sublet_Sales__c == null || payment_method.Sublet_Inventory__c == null) { 
                    throw new FFASException('Error: Payment method setup incomplete.  This repair order shows sublet charges however this payment method does not have the accounts setup for sublet charges.');
                }
                    // JVK4 - Multiple Sublets will not have new sublet CS/Sales Account entries
                    if(jLines.get(payment_method.Sublet_Sales__c)!=null) {
                       jLines.get(payment_method.Sublet_Sales__c).c2g__Value__c+=FFAccounting.credit(line.dealer__Sublet_Total__c).setScale(2, System.RoundingMode.HALF_UP);
                    } else {
                        // Sublet Sales
                        // 
                        // JVK6 - Round DecimalFFAccounting.credit(line.dealer__Sublet_Total__c

                        //jLines.put(payment_method.Sublet_Sales__c, new c2g__codaJournalLineItem__c(
                        //        c2g__Journal__c=journalIdNull,
                        //        c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                        //        c2g__LineDescription__c='Sublet Sales '+ro.Name,
                        //        c2g__LineNumber__c=line_number,
                        //        c2g__GeneralLedgerAccount__c=payment_method.Sublet_Sales__c,
                        //        c2g__Value__c=FFAccounting.credit(line.dealer__Sublet_Total__c).setScale(2, System.RoundingMode.HALF_UP),
                        //        c2g__DebitCredit__c='Credit',
                        //        c2g__LineType__c='General Ledger Account',
                        //        Vehicle_Inventory__c = (addVehRef && vehGlAccts.containsKey(payment_method.Sublet_Sales__c)?vehInv:null), // BLL1a, BLL14c
                        //        Customer_Name__c = ro.dealer__Customer__c,  // BLL4a
                        //        Control__c=controlnbr  // BLL1c was ro.Name
                        //        )
                        //);
                        jLines.put(payment_method.Sublet_Sales__c, ss);
                        line_number++;
                    }

                    if(jLines.get(payment_method.Sublet_CS__c)!=null){
                        jLines.get(payment_method.Sublet_CS__c).c2g__Value__c+=FFAccounting.debit(line.dealer__Sublet_Cost__c).setScale(2, System.RoundingMode.HALF_UP);
                    } else {
                        
                        // Sublet C/S
                        //jLines.put(payment_method.Sublet_CS__c, new c2g__codaJournalLineItem__c(
                        //        c2g__Journal__c=journalIdNull,
                        //        c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                        //        c2g__LineDescription__c='Sublet C/S '+ro.Name,
                        //        c2g__LineNumber__c=line_number,
                        //        c2g__GeneralLedgerAccount__c=payment_method.Sublet_CS__c,
                        //        c2g__Value__c=  FFAccounting.debit(line.dealer__Sublet_Cost__c).setScale(2, System.RoundingMode.HALF_UP), // BLL6c FFAccounting.debit(line.dealer__Sublet_Total__c), JVK6 replace with subCost and setscale
                        //        c2g__DebitCredit__c='Debit',
                        //        c2g__LineType__c='General Ledger Account',
                        //        Vehicle_Inventory__c = (addVehRef && vehGlAccts.containsKey(payment_method.Sublet_CS__c)?vehInv:null), // BLL1a, BLL14c
                        //        Customer_Name__c = ro.dealer__Customer__c,  // BLL4a
                        //        Control__c=controlnbr  // BLL1c was ro.Name
                        //        )
                        //);
                        jLines.put(payment_method.Sublet_CS__c, scos);
                        line_number++;  
                    }

        
                    // Sublet Inventory Clearing
                    if(jLines.get(payment_method.Sublet_Inventory__c)!=null) {
                       jLines.get(payment_method.Sublet_Inventory__c).c2g__Value__c+=FFAccounting.credit(line.dealer__Sublet_Cost__c).setScale(2, System.RoundingMode.HALF_UP);
                    } else {
                        
                        //jLines.put(payment_method.Sublet_Inventory__c, new c2g__codaJournalLineItem__c(
                        //        c2g__Journal__c=journalIdNull,
                        //        c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                        //        c2g__LineDescription__c='Sublet Inventory '+ro.Name,
                        //        c2g__LineNumber__c=line_number,
                        //        c2g__GeneralLedgerAccount__c=payment_method.Sublet_Inventory__c,
                        //        c2g__Value__c=FFAccounting.credit(line.dealer__Sublet_Cost__c).setScale(2, System.RoundingMode.HALF_UP), // BLL6c FFAccounting.credit(line.dealer__Sublet_Total__c), JVK8 replace with SubCost
                        //        c2g__DebitCredit__c='Credit',
                        //        c2g__LineType__c='General Ledger Account',
                        //        Vehicle_Inventory__c = (addVehRef && vehGlAccts.containsKey(payment_method.Sublet_Inventory__c)?vehInv:null), // BLL1a, BLL14c
                        //        Customer_Name__c = ro.dealer__Customer__c,  // BLL4a
                        //        //BLL6d Control__c=controlnbr  // BLL1c was ro.Name
                        //        Control__c=ro.name // BLL6a
                        //        )
                        //);
                        jLines.put(payment_method.Sublet_Inventory__c, sinv);
                        line_number++;                                       
                    }
            }
            
            // BLL20d
            // BLL15a - accumulate inv reserve if GRNV/GRUV/MCEO
            //System.debug(addVehRef);
            //System.debug(payment_method.Inventory_Reserve__c);
            //System.debug(payment_method.Labor_Sale_Account__c);
            //BLL20d if (getReadyPmtMethods.contains(payment_method.Name) && payment_method.Inventory_Reserve__c!=null && payment_method.Labor_Sale_Account__c!=null
            //BLL20d    && line.dealer__Actual_Time__c!=null && line.dealer__Actual_Time__c!=0 && line.dealer__Labor_Charges__c!=null && line.dealer__Labor_Charges__c!=0) {    
            //BLL20d    Decimal laborcost = line.dealer__Actual_Time__c * loc.Internal_Labor_Rate__c;
            //BLL20d    //System.debug('laborcost='+String.valueOf(laborcost));
            //BLL20d    Decimal addreserve = line.dealer__Labor_Charges__c - labor_cost;
            //BLL20d    //System.debug('addreserve='+String.valueOf(addreserve));
            //BLL20d    Decimal reserve = invreserve.get(payment_method.Inventory_Reserve__c);
            //BLL20d    if (reserve==null) reserve = 0.00;
            //BLL20d    reserve -= addreserve;
            //BLL20d    //System.debug('reserve='+String.valueOf(reserve));
            //BLL20d    invreserve.put(payment_method.Inventory_Reserve__c,reserve.setScale(2));
            //BLL20d    Decimal servicebilling = invreserve.get(payment_method.Labor_Sale_Account__c);
            //BLL20d    if (servicebilling==null) servicebilling = 0.00;
            //BLL20d    servicebilling += addreserve;
            //BLL20d    //System.debug('servicebilling='+String.valueOf(servicebilling));
            //BLL20d    invreserve.put(payment_method.Labor_Sale_Account__c,servicebilling);
            //BLL20d }
            //BLL20d // BLL15a end  
            
            System.debug('Done with job line ' + line.Id);                               

        } // End of Job Lines

        /*
        |   SALES TAX
        */      
        c2g__codaJournalLineItem__c stax = new c2g__codaJournalLineItem__c(
                    c2g__Journal__c=journalIdNull,
                    c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                    c2g__LineDescription__c='Sales Tax '+ro.Name,
                    c2g__LineNumber__c=line_number,
                    c2g__GeneralLedgerAccount__c=loc.Sales_Tax_Account__c,
                    c2g__Value__c=0,
                    c2g__DebitCredit__c='Credit',
                    c2g__LineType__c='General Ledger Account',
                    Customer_Name__c = ro.dealer__Customer__c,
                    Control__c = controlnbr
        );
        if(jLines.get(loc.Sales_Tax_Account__c)==null && ro.dealer__Customer_Tax__c>0) { // Bleaman - Tax Field chosen Non Managed

            if(loc.Sales_Tax_Account__c==null) { 

                Database.rollback(sp);

                //String errorMsg = 'Location must have a Sales Tax account assigned. for Repair Order ' + ro.Name;
                //Error_Log__c log = new Error_Log__c();
                //log.trace__c = errorMsg;
                //insert log;
                insert(new Error_Log__c(trace__c='Location must have a Sales Tax account assigned. for Repair Order ' + ro.Name)); 

                return;
            }

            //jLines.put(loc.Sales_Tax_Account__c, new c2g__codaJournalLineItem__c(
            //        c2g__Journal__c=journalIdNull,
            //        c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
            //        c2g__LineDescription__c='Sales Tax '+ro.Name,
            //        c2g__LineNumber__c=line_number,
            //        c2g__GeneralLedgerAccount__c=loc.Sales_Tax_Account__c,
            //        c2g__Value__c=0,
            //        c2g__DebitCredit__c='Credit',
            //        c2g__LineType__c='General Ledger Account',
            //        Customer_Name__c = ro.dealer__Customer__c,
            //        Control__c = controlnbr
            //    )
            //);
            jLines.put(loc.Sales_Tax_Account__c, stax);
            line_number++;
        }
        if(ro.dealer__Customer_Tax__c>0) {
            ro.dealer__Customer_Tax__c = ro.dealer__Customer_Tax__c.setScale(2, System.RoundingMode.HALF_UP);
            jLines.get(loc.Sales_Tax_Account__c).c2g__Value__c -= ro.dealer__Customer_Tax__c;
        }

        // BLL3a - additional GL Accounts needed
        Map<String,c2g__codaGeneralLedgerAccount__c> glAcctMap = new Map<String,c2g__codaGeneralLedgerAccount__c>();    // BLL3a
        for(c2g__codaGeneralLedgerAccount__c g : [
                select Id, c2g__ReportingCode__c 
                from c2g__codaGeneralLedgerAccount__c 
                where c2g__ReportingCode__c in('3301', '1110', '1100') 
            ]) { 
            glAcctMap.put(g.c2g__ReportingCode__c,g);
        }
        // BLL3a end

        /*
        |   Discount
        */
        Decimal discount_amount = (ro.dealer__Discount_Total__c *-1);
        c2g__codaGeneralLedgerAccount__c discount_applied_labor = glAcctMap.get('3301');
        c2g__codaJournalLineItem__c disc = new c2g__codaJournalLineItem__c( // BLL3c remove [0]
                    c2g__Journal__c=journalIdNull,
                    c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                    c2g__LineDescription__c='Discount '+ro.Name,
                    c2g__LineNumber__c=line_number,
                    c2g__GeneralLedgerAccount__c=discount_applied_labor.Id, // BLL3c remove [0]
                    c2g__Value__c=discount_amount.setScale(2, System.RoundingMode.HALF_UP), // Normally a negative number
                    c2g__DebitCredit__c='Debit',
                    c2g__LineType__c='General Ledger Account',
                    Customer_Name__c = ro.dealer__Customer__c,
                    Control__c = controlnbr
        );
        // JVK1
        if(ro.dealer__Discount_Total__c!= null && ro.dealer__Discount_Total__c!=0) {

            // Add the CR to applied discounts
            //BLL3d c2g__codaGeneralLedgerAccount__c[] discount_applied_labor = [Select Id, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c = '3301' limit 1];
            //c2g__codaGeneralLedgerAccount__c discount_applied_labor = glAcctMap.get('3301');
            //BLL3d if(discount_applied_labor.size()!=1) {
            if (discount_applied_labor==null) { // BLL3a
                Database.rollback(sp);

                //String errorMsg = 'Repair Order Discount must have access to account# 3301 ' + ro.Name;
                //Error_Log__c log = new Error_Log__c();
                //log.trace__c = errorMsg;
                //insert log; 
                insert(new Error_Log__c(trace__c='Repair Order Discount must have access to account# 3301 ' + ro.Name)); 

                return;
            }

            // Set Discount as a Decimal.
            //Decimal discount_amount = (ro.dealer__Discount_Total__c *-1);

            //jLines.put(discount_applied_labor.Id, new c2g__codaJournalLineItem__c(    // BLL3c remove [0]
            //        c2g__Journal__c=journalIdNull,
            //        c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
            //        c2g__LineDescription__c='Discount '+ro.Name,
            //        c2g__LineNumber__c=line_number,
            //        c2g__GeneralLedgerAccount__c=discount_applied_labor.Id,   // BLL3c remove [0]
            //        c2g__Value__c=discount_amount.setScale(2, System.RoundingMode.HALF_UP), // Normally a negative number
            //        c2g__DebitCredit__c='Debit',
            //        c2g__LineType__c='General Ledger Account',
            //        Customer_Name__c = ro.dealer__Customer__c,
            //        Control__c = controlnbr
            //    )
            //);
            jLines.put(discount_applied_labor.Id, disc);
            line_number++;                        
        }
        // JVK1 End

        /*
        |   CASHIERING ENTRIES
        */ 

        // Loop Cashiered Payments and apply to either 1100 (Customer) or 1110 (3rd Party)
        System.debug(ro.Id);
// BLL29
//        for(dealer__Cashering__c c : [  Select Id, dealer__Amount__c, dealer__Customer__c, dealer__Customer__r.RecordType.Name,
//                                            dealer__Payment_Method__c
//                                        FROM dealer__Cashering__c where dealer__Service_Repair_Order__c =:ro.Id]) {
        for(dealer__Cashering__c c : [  
			Select Id, dealer__Amount__c, dealer__Customer__c, dealer__Customer__r.RecordType.Name,
				dealer__Customer__r.c2g__CODAAccountsReceivableControl__c, 	// BLL30a
                dealer__Payment_Method__c
			From dealer__Cashering__c 
			Where dealer__Service_Repair_Order__c =:ro.Id
			   and Cashiered_while_Posted__c=false
			   and dealer__Amount__c!=0
			]) {
// BLL29 end
            System.debug(c.dealer__Customer__r.RecordType.Name);
            // test is incorrect and therefore never succeeding and always hitting the "Else" section.
            //if(c.dealer__Customer__r.RecordType.Name == 'Third_Party_Payor') {
            //    // 1110
            //    //BLL3d c2g__codaGeneralLedgerAccount__c rec_tpp = [Select Id from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c = '1110' limit 1];
            //    c2g__codaGeneralLedgerAccount__c rec_tpp = glAcctMap.get('1110'); // BLL3a
            //    if (rec_tpp==null) throw new FFASException('RO cannot access account 1110');  // BLL3a
            //    if(jLines.get(rec_tpp.Id)==null && c.dealer__Amount__c!=0) {
            //        jLines.put(rec_tpp.Id, new c2g__codaJournalLineItem__c(
            //                c2g__Journal__c=journalIdNull,
            //                c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
            //                c2g__LineDescription__c='Accounts Receivable '+ro.Name,
            //                c2g__LineNumber__c=line_number,
            //                c2g__GeneralLedgerAccount__c=rec_tpp.Id,
            //                c2g__Value__c=0,
            //                c2g__DebitCredit__c='Debit',
            //                c2g__LineType__c='Account - Vendor',
            //                Third_Party_Payor__c=c.dealer__Customer__c,
            //                c2g__Account__c=c.dealer__Customer__c,
            //                Customer_Name__c = ro.dealer__Customer__c,
            //                Control__c = controlnbr        
            //            )
            //        );
            //        line_number++;
            //    }
            //
            //    if(c.dealer__Amount__c!=0) {
            //        jLines.get(rec_tpp.Id).c2g__Value__c += (c.dealer__Amount__c + ro.dealer__Discount_Total__c);
            //    }               
            //} else {
                // 1100 
                //BLL3d c2g__codaGeneralLedgerAccount__c rec_acct = [Select Id from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c = '1100' limit 1];
                c2g__codaGeneralLedgerAccount__c rec_acct = glAcctMap.get('1100');
				// BLL30
				if (c.dealer__Customer__r.c2g__CODAAccountsReceivableControl__c!=null) rec_acct = new c2g__codaGeneralLedgerAccount__c(Id=c.dealer__Customer__r.c2g__CODAAccountsReceivableControl__c);
				// BLL30 end
                if (rec_acct==null) throw new FFASException('RO cannot access account 1100');   // BLL3a
                //BLL23d String key = rec_acct.Id + ':' + c.dealer__Customer__c + ':' + c.dealer__Payment_Method__c; // BLL22a
                //BLL23d if (c.dealer__Amount__c<0) key += ':credit';
                // BLL23a
                String key = c.Id;	
                c2g__codaJournalLineItem__c jline = jLines.get(key);
                if (jline==null) {
                    jline = new c2g__codaJournalLineItem__c(
                            c2g__Journal__c=journalIdNull,
                            c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                            c2g__LineDescription__c='Accounts Receivable '+ro.Name,
                            c2g__LineNumber__c=line_number,
                            c2g__GeneralLedgerAccount__c=rec_acct.Id,
                            c2g__Value__c=0,
                            //c2g__DebitCredit__c='Debit',
                            c2g__LineType__c='Account - Customer',
                            c2g__Account__c=c.dealer__Customer__c,
                            Customer_Name__c = ro.dealer__Customer__c,  // BLL4a
                            //BLL3d  Control__c=ro.Name
                            Control__c = controlnbr  // BLL3a          
                    );
                    line_number++;
                }
                jline.c2g__Value__c += c.dealer__Amount__c;
                jlines.put(key, jline);
                // BLL23a end
                // BLL23d
                //BLL22d if(jLines.get(rec_acct.Id)==null && c.dealer__Amount__c>0) {
                //if(jLines.get(key)==null && c.dealer__Amount__c>0) {  // BLL22a
                //    //BLL22d jLines.put(rec_acct.Id, new c2g__codaJournalLineItem__c(
                //    jLines.put(key, new c2g__codaJournalLineItem__c(
                //            c2g__Journal__c=journalIdNull,
                //            c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                //            c2g__LineDescription__c='Accounts Receivable '+ro.Name,
                //            c2g__LineNumber__c=line_number,
                //            c2g__GeneralLedgerAccount__c=rec_acct.Id,
                //            c2g__Value__c=0,
                //            c2g__DebitCredit__c='Debit',
                //            c2g__LineType__c='Account - Customer',
                //            c2g__Account__c=c.dealer__Customer__c,
                //            Customer_Name__c = ro.dealer__Customer__c,  // BLL4a
                //            //BLL3d  Control__c=ro.Name
                //            Control__c = controlnbr  // BLL3a          
                //        )
                //    );
                //    line_number++;
                //}

                //Decimal tVal_rec = 0;
                //BLL22d if(jLines.get(rec_acct.Id)!=null && c.dealer__Amount__c>=0) {
                //BLL22d     if(jLines.get(rec_acct.Id).c2g__Value__c == null) {
                //BLL22d         jLines.get(rec_acct.Id).c2g__Value__c = 0;
                //BLL22d     }
                //BLL22d     tVal_rec = c.dealer__Amount__c; //JVK2
                //BLL22d     jLines.get(rec_acct.Id).c2g__Value__c += tVal_rec.setScale(2);
                //BLL22d }
                // BLL22a
                //if(jLines.get(key)!=null && c.dealer__Amount__c>=0) {
                //  if(jLines.get(key).c2g__Value__c == null) {
                //      jLines.get(key).c2g__Value__c = 0;
                //  }
                //  tVal_rec = c.dealer__Amount__c; //JVK2
                //  jLines.get(key).c2g__Value__c += tVal_rec.setScale(2);
                //}
                // BLL22a end

                // Check for Deposit Refunds
                //if(c.dealer__Amount__c<0) {
                //    //BLL22d jLines.put(c.Id, new c2g__codaJournalLineItem__c(
                //    jLines.put(key, new c2g__codaJournalLineItem__c(
                //            c2g__Journal__c=journalIdNull,
                //            c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                //            c2g__LineDescription__c='Accounts Receivable '+ro.Name,
                //            c2g__LineNumber__c=line_number,
                //            c2g__GeneralLedgerAccount__c=rec_acct.Id,
                //            c2g__DebitCredit__c='Debit',
                //            c2g__LineType__c='Account - Customer',
                //            c2g__Account__c=c.dealer__Customer__c,
                //            c2g__Value__c = c.dealer__Amount__c.setScale(2),                   
                //            Customer_Name__c = ro.dealer__Customer__c,  // BLL4a
                //            //BLL3d  Control__c=ro.Name
                //            Control__c = controlnbr  // BLL3a          
                //        )
                //    );
                //    line_number++;
                //}
                // BLL23d                        
                                       
            //}
        }

        //BLL20d 
        // BLL15a - add journal lines for inventory reserve
        //BLL20d System.debug('Processing inventory reserve');
        //BLL20d //System.debug(invreserve.keySet());
        //BLL20d for(Id glid : invreserve.keySet()) {
        //BLL20d    Decimal amount = invreserve.get(glid);
        //BLL20d    //System.debug(glid);
        //BLL20d    //System.debug(amount);
        //BLL20d    if (amount!=null && amount!=0) {
        //BLL20d        jLines.put('InventoryReserve-'+String.valueOf(line_number), new c2g__codaJournalLineItem__c(
        //BLL20d            c2g__Journal__c=journalIdNull,
        //BLL20d            c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
        //BLL20d            c2g__LineDescription__c=((amount<0) ? 'Inventory Reserve '+ro.Name : 'Service Billing ' + ro.Name),
        //BLL20d            c2g__LineNumber__c=line_number,
        //BLL20d            c2g__GeneralLedgerAccount__c=glid,
        //BLL20d            c2g__Value__c= amount,
        //BLL20d            c2g__DebitCredit__c= ((amount<0) ? 'Credit' : 'Debit'),
        //BLL20d            c2g__LineType__c='General Ledger Account',
        //BLL20d            Customer_Name__c = ro.dealer__Customer__c,
        //BLL20d            Vehicle_Inventory__c = (amount<0 ? vehInv : null),  // BLL19a 
        //BLL20d            Control__c = controlnbr
        //BLL20d        ));
        //BLL20d        line_number++;
        //BLL20d    }                                       
        //BLL20d }
        //BLL20d ro.InternalLaborRate__c = loc.Internal_Labor_Rate__c;  // save this value for when proposal or quote is posted
        // BLL15a end


        // Create the Journal Object
        journalHeader.c2g__OwnerCompany__c      =   ownerCompanyId;  // JVK7 (Get owner company at begining of routine)
        journalHeader.c2g__Period__c            =   periodId;
        journalHeader.c2g__JournalCurrency__c   =   FFAccounting.currency(journalHeader.c2g__OwnerCompany__c);
        journalHeader.c2g__JournalDescription__c=   'RO Cashier ' + ro.Name; 
        Date jdate = Date.today();
        // if (ro.dealer__Invoiced_Date_Time__c!=null) jdate = ro.dealer__Invoiced_Date_Time__c.date(); // JVK7.1 (Seems that the journal date was pushing items backward.)
        journalHeader.c2g__JournalDate__c       =   jdate;
        journalHeader.c2g__Reference__c         =   ro.Name;
        journalHeader.Source__c                 =   'SVC';
        journalHeader.Customer__c               =   ro.dealer__Customer__c;
        journalHeader.Repair_Order__c           =   ro.Id; 


        // BLL11a - fix control# based on GL account numbers (replace RO# as control#)
        // Replace control# if it's the RO name and is for an account controlled by document or stock number.
        // There are still other areas of code that set this to one of these other values for other reasons that may still be valid.
        MonitorExecution mon = new MonitorExecution('PostRepairOrder'); 
        for(c2g__codaJournalLineItem__c jl : jlines.values()) {
            // Debug : show every line
            mon.log('Line='+String.valueOf(jl.c2g__LineNumber__c) + ', ' + jl.c2g__LineDescription__c + ', GL=' + jl.c2g__GeneralLedgerAccount__c + ', value='+String.valueOf(jl.c2g__Value__c));
            if (jl.Control__c==ro.Name && docGlAcctMap.containsKey(jl.c2g__GeneralLedgerAccount__c)) jl.Control__c=documentnbr;
            if (jl.Control__c==ro.Name && stockGlAcctMap.containsKey(jl.c2g__GeneralLedgerAccount__c)) jl.Control__c=stocknbr;
            if (String.isBlank(jl.Control__c)) jl.Control__c=controlnbr;    // BLL13a
            // BLL26 round all values to 2 decimals (having issue with internal part costs)
            jl.c2g__Value__c = jl.c2g__Value__c.setScale(2, System.RoundingMode.HALF_UP);
            // BLL26 end
        }
        if (mon.AlwaysNotify) mon.NotifyAdmin();
        // BLL11a end

        Id journalId = null;

		System.debug('*=* Create and Post RO Journal ***');
		System.debug(jLines.size());
		for(c2g__codaJournalLineItem__c jl : jLines.values()) System.debug(String.valueOf(jl.c2g__LineDescription__c) + ' : ' + String.valueOf(jl.c2g__Value__c));

        if (jLines.size()>0) {  // If there are no lines then there shall not be a journal
            try {

				System.debug(ro);
                // Create Journal and Lines using Bryans Static Method
                journalId = FinancialForce_MBW.createJournalApi(journalHeader, jLines.values());

                // Set the Journal on the RO for future reference
                if(journalId!=null) {
                    ro.Journal__c = journalId;
                    ro.dealer__Posted_Date_Time__c = Datetime.now();
                    ro.dealer__Status__c = 'Posted';
                	System.debug('*=* Mark RO Posted ***');
                    update ro;
                    System.debug(ro);
                }

            } Catch(DmlException e) {

				System.debug(e);

                //String errorMsg = 'Repair Order Failed to Create Journal ' + ro.Name +'\r\n'+JSON.serializePretty(jLines.values());
                
                Database.rollback(sp);

                //Error_Log__c log = new Error_Log__c();
                //log.trace__c = errorMsg;
                //insert log; 
                insert(new Error_Log__c(trace__c='Repair Order Failed to Create Journal: '
                    + e.getMessage() + '\r\n'   // BLL25a
                    + ro.Name +'\r\n'+JSON.serializePretty(jLines.values()))); 

                ro.dealer__Status__c='GL Error';
                ro.Journal__c=null;
                update ro;

                return;

            } Catch(SObjectException e) {

				System.debug(e);
                //String errorMsg = 'Repair Order Failed to Create Journal ' + ro.Name +'\r\n'+JSON.serializePretty(jLines.values());
                
                Database.rollback(sp);

                //Error_Log__c log = new Error_Log__c();
                //log.trace__c = errorMsg;
                //insert log; 
                insert(new Error_Log__c(trace__c='Repair Order Failed to Create Journal: '
                    + e.getMessage() + '\r\n'   // BLL25a
                    + ro.Name +'\r\n'+JSON.serializePretty(jLines.values()))); 

                ro.dealer__Status__c='GL Error';
                ro.Journal__c=null;
                update ro;                
                
                return;

            } Catch(Exception e) {

				System.debug(e);
                //String errorMsg = 'Repair Order Failed to Create Journal  ' + ro.Name +'\r\n'+JSON.serializePretty(jLines.values());
                
                Database.rollback(sp);

                //Error_Log__c log = new Error_Log__c();
                //log.trace__c = errorMsg;
                //insert log; 
                insert(new Error_Log__c(trace__c='Repair Order Failed to Create Journal: ' 
                    + e.getMessage() + '\r\n'   // BLL25a
                    + ro.Name +'\r\n'+JSON.serializePretty(jLines.values()))); 

                ro.dealer__Status__c='GL Error';
                ro.Journal__c=null;
                update ro;                
                
                return;

            }


            // Attempt to Post Journal
            //RT1 - journal only
            try {
            // Final Post
            

                /*
                    If the Journal is Not in Balance do not Post
                 */
                // JVK4
                c2g__codaJournal__c jrnlInBalance = [Select Id, c2g__Total__c from c2g__codaJournal__c where Id=:journalId limit 1];
                System.debug(jrnlInBalance);
                //BLL24d if(!Test.isRunningTest() && jrnlInBalance.c2g__Total__c==0) {
                if(jrnlInBalance.c2g__Total__c==0) {	// BLL24a
                	System.debug('*=* Posting journal ***');
                	FFAccounting.postJournal(journalId);
                	System.debug('*=* Posted! ***');
                }
                
                // Record the InvoiceRegister
                System.debug('*=* Apply to register ***');
                FFAccounting.applyJournalToRegister(ro.Id, journalId);
                System.debug('*=* Applied to register ***');
                //RT1
                //FFAccounting.applyTransactionToRegister(ro.Id, journalId); 

            

            } Catch(DmlException e) {
            	
            	System.debug(e);
                //String errorMsg = 'Repair Order failed to POST Journal '+ro.Name;
                
                Database.rollback(sp);

                //Error_Log__c log = new Error_Log__c();
                //log.trace__c = errorMsg;
                //insert log; 
                insert(new Error_Log__c(trace__c='Repair Order failed to POST Journal '+ro.Name)); 

                ro.dealer__Status__c='GL Error';
                update ro;

                return;
            } Catch(Exception e) {
            	
            	System.debug(e);
                //String errorMsg = 'Repair Order failed to POST Journal '+ro.Name;
                
                Database.rollback(sp);

                //Error_Log__c log = new Error_Log__c();
                //log.trace__c = errorMsg;
                //insert log; 
                insert(new Error_Log__c(trace__c='Repair Order failed to POST Journal '+ro.Name)); 

                ro.dealer__Status__c='GL Error';
                update ro;   

                return;
            }

            //RT1 - transaction only
            try {
                // Final Post
                // Check to see if Journal is IN Balance before posting.

                c2g__codaJournal__c jrnl_total = [Select c2g__Total__c from c2g__codaJournal__c where Id=:journalId limit 1];
                System.debug(jrnl_total);

                if(jrnl_total.c2g__Total__c==0) {

                    /*
                    if(!Test.isRunningTest()) {
                      FFAccounting.postJournal(journalId);
                    }
                    
                    // Record the InvoiceRegister
                    FFAccounting.applyJournalToRegister(ro.Id, journalId);
                    */
                    FFAccounting.applyTransactionToRegister(ro.Id, journalId);
                    System.debug('*=* Applied to register ***');

                }

            } Catch(DmlException e) {

				System.debug(e);
                //String errorMsg = 'Repair Order failed to POST Journal '+ro.Name;
                
                Database.rollback(sp);

                //Error_Log__c log = new Error_Log__c();
                //log.trace__c = errorMsg;
                //insert log; 
                insert(new Error_Log__c(trace__c='Repair Order failed to POST Journal '+ro.Name)); 

                ro.dealer__Status__c='GL Error';
                update ro;

                return;
            } Catch(Exception e) {
            	
            	System.debug(e);
                //String errorMsg = 'Repair Order failed to POST Journal '+ro.Name;
                
                Database.rollback(sp);

                //Error_Log__c log = new Error_Log__c();
                //log.trace__c = errorMsg;
                //insert log; 
                insert(new Error_Log__c(trace__c='Repair Order failed to POST Journal '+ro.Name)); 

                ro.dealer__Status__c='GL Error';
                update ro;                

                return;
            }
        }

        // Update the Vehicle Information
        dealer__Service_Vehicle__c[] svehicle = [Select Id, dealer__Sales_Inventory__c from dealer__Service_Vehicle__c where Id=:ro.dealer__Vehicle__c limit 1];
        if(svehicle.size()==1) {
            svehicle[0].dealer__Last_Service__c = Date.valueOf(ro.dealer__Create_Date_Time__c);
            if(ro.dealer__Mileage_Out__c!=null) svehicle[0].dealer__Last_Odometer__c = ro.dealer__Mileage_Out__c;
            svehicle[0].dealer__Last_Activity__c = Date.today();
			System.debug('*=* Updating service vehicle ***');
            update svehicle;
			System.debug('*=* Updated service vehicle ***');
        } // BLL8a

        // BLL21a
        try {
        	System.debug('*=* Update stock vehicle ***');
            FFA_ServiceDepartment.GetReadyUpdateVehicle('Post', ro, (svehicle.isEmpty()?null:svehicle[0]));
        	System.debug('*=* Updated stock vehicle ***');
        } catch(Exception e) {
        	System.debug(e);
            Database.rollback(sp);
            insert(new Error_Log__c(
                trace__c = 'Type: ' + e.getTypeName() + '\n' + 'Cause: ' + e.getCause() + '\n' + 'Message: ' 
                        + e.getMessage() + '\n' + 'Line #: ' + e.getLineNumber() + '\n' + e.getStackTraceString() + '\n'
                        + 'Failed to update vehicle/conversion cost for GRNV/GRUV/MCEO Repair Order : ' + ro.Name));    // BLL16c correct error message
            ro.dealer__Status__c='GL Error';
            update ro;                
        }
        // BLL21a end

        // BLL21c moved getready code to new routine...
        //BLL8d }
        System.debug(ro);
        System.debug([select Id, Name, dealer__Status__c from dealer__Service_Repair_Order__c where Id=:ro.Id]);       
        System.debug('*=* Done! ***');
    }

    // BLL21a
    // GetReadyUpdateVehicle - update vehicle costs for GetReady (GRNV, GRUV, MCEO) payment methods
    // action=Post | ReOpen: Post adds to vehicle costs, ReOpen subtracts from vehicle costs
    // dealer__Service_Repair_Order__c required fields: Id, Name, dealer__Vehicle_Inventory__c, dealer__Vehicle__c
    // dealer__Service_Vehicle__c is optional and will be queried if missing
    public static void GetReadyUpdateVehicle(String action, dealer__Service_Repair_Order__c ro, dealer__Service_Vehicle__c svehicle) {
        boolean addToCost = true;   // BLL21a
        if (action.contains('Open')) addToCost = false; // BLL21a
        List<dealer__Service_Vehicle__c> svehicles = new List<dealer__Service_Vehicle__c>();
        if (svehicle==null) svehicles = [Select Id, dealer__Sales_Inventory__c from dealer__Service_Vehicle__c where Id=:ro.dealer__Vehicle__c limit 1];
        if (svehicle==null && !svehicles.isEmpty()) svehicle = svehicles[0];    // BLL21a
         

            // DR2b
            // Update Vehicle Inventory Cost
            // BLL7d
            //if(svehicle[0].dealer__Sales_Inventory__c != null && ro.dealer__Internal_Charges__c != null && ro.dealer__Internal_Charges__c > 0) {
            // BLL7a
            // Summarize getready line internal costs
            AggregateResult[] getrdy = [
                select Payment_Method__r.Name PMname, sum(dealer__Line_Total__c) sumGetRdy  // BLL9c add Payment_Method__r.Name
                from  dealer__Service_Job__c
                where dealer__Service_Repair_Order__c=:ro.Id and Payment_Method__r.Name in ('GRUV', 'GRNV', 'MCEO') // BLL9c add MCEO
                group by Payment_Method__r.Name // BLL9a
            ];
            //BLL9d Decimal sumGetRdy = (getrdy.size()==1) ? (Decimal) getrdy[0].get('sumGetRdy') : 0.00;
            //BLL9d if (sumGetRdy!=null && sumGetRdy!=0.00) {
            if (getrdy.size()>0) {  // BLL9a
            // BLL7a end
            // 
            //               
            //  JVK - 4/5/2016 - Sometimes the service vehicle list is empty (if so query and set, also list index 0 error found if not set)
                Id vehInvId = null;
                //BLL21d if(!svehicle.isEmpty() && svehicle[0].dealer__Sales_Inventory__c != null) {
                if (svehicle!=null && svehicle.dealer__Sales_Inventory__c!=null) {  // BLL21a
                    vehInvId = svehicle.dealer__Sales_Inventory__c; 
                }
                
                // BLL18a - use RO's vehicle if specified! (should always be specified now)
                if (ro.dealer__Vehicle_Inventory__c!=null) vehInvId = ro.dealer__Vehicle_Inventory__c;

                // JVK5
                if(vehInvId==null && ro.dealer__VIN_Service_Vehicle__c!=null) {
                    dealer__Vehicle_Inventory__c[] vehicleInvRecords = [Select Id from dealer__Vehicle_Inventory__c where dealer__VIN__c =:ro.dealer__VIN_Service_Vehicle__c order by CreatedDate desc limit 1];
                    if(!vehicleInvRecords.isEmpty()) vehInvId=vehicleInvRecords[0].Id;
                }
                // End JVK5

                // JVK6
                if(vehInvId==null) {

                    //BLL21d Database.rollback(sp);

                    //String errorMsg = 'Vehicle Inventory Record not associated with Service Vehicle - Failed to insert Posting Entry for Repair Order ' + ro.Name;
                    //Error_Log__c log = new Error_Log__c();
                    //log.trace__c = errorMsg;
                    //insert log; 
                    insert(new Error_Log__c(trace__c='Vehicle Inventory Record not set - Failed to update vehicle for Repair Order ' + ro.Name)); 

                    return;                    
                }
                // End JVK6


                //BLL21d try {

                    dealer__Vehicle_Inventory__c vehInvRec = [
                        SELECT Id, dealer__Vehicle_Cost__c, dealer__Status_Code__c, New_Used_Other__c, Conversion_Cost__c  
                        FROM dealer__Vehicle_Inventory__c 
                        WHERE Id =: vehInvId LIMIT 1
                    ];
                    if(vehInvRec!=null) {
                        if (vehInvRec.dealer__Vehicle_Cost__c==null) vehInvRec.dealer__Vehicle_Cost__c = 0.00;
                        if (vehInvRec.Conversion_Cost__c==null) vehInvRec.Conversion_Cost__c = 0.00; // BLL2a
                        //if (vehInvRec.dealer__Vehicle_Cost__c!=null && vehInvRec.dealer__Vehicle_Cost__c >= 0) {
                            // cost field
                            // BLL7d vehInvRec.dealer__Vehicle_Cost__c += ro.dealer__Internal_Charges__c;
                        //} 
                        // BLL2a
                        // BLL12d if (vehInvRec.New_Used_Other__c=='Commercial') {  // add MCEO to conversion
                            //BLL9d vehInvRec.Conversion_Cost__c += sumGetRdy;
                            // BLL9a
                            for(AggregateResult r : getrdy) {
                                if (r.get('PMname')=='MCEO') 
                                    if (addToCost) vehInvRec.Conversion_Cost__c += (Decimal) r.get('sumGetRdy');
                                    else vehInvRec.Conversion_Cost__c -= (Decimal) r.get('sumGetRdy');
                            }
                            // BLL9a - end
                        // BLL12d } else {
                        // BLL2a end
                            //BLL9d vehInvRec.dealer__Vehicle_Cost__c += sumGetRdy;  // BLL7a
                            // BLL9a
                            for(AggregateResult r : getrdy) {
                                if (r.get('PMname')=='GRNV' || r.get('PMname')=='GRUV')
                                    if (addToCost) vehInvRec.dealer__Vehicle_Cost__c += (Decimal) r.get('sumGetRdy');
                                    else vehInvRec.dealer__Vehicle_Cost__c -= (Decimal) r.get('sumGetRdy');
                            }
                            // BLL9a - end
                        // BLL12d } // BLL2a
                        update vehInvRec;
                    }
                //BLL21d allow error to bubble back up 
                //BLl21d } Catch(DmlException e) {
                    
                //BLL21d    ro.dealer__Status__c = 'GL Error';
                //BLL21d    update ro;

                //BLL21d    insert(new Error_Log__c(
                //BLL21d        trace__c = 'Type: ' + e.getTypeName() + '\n' + 'Cause: ' + e.getCause() + '\n' + 'Message: ' 
                //BLL21d        + e.getMessage() + '\n' + 'Line #: ' + e.getLineNumber() + '\n' + e.getStackTraceString() + '\n'
                //BLL21d        + 'Failed to update vehicle/conversion cost for GRNV/GRUV/MCEO Repair Order : ' + ro.Name));    // BLL16c correct error message
                    //insert log;                      

                    // throw new FFASException('Error Updating Vehicle Inventory: '+e.getMessage());
                    
                //BLL21d}
            }
            // /DR2b
        
    }
    // BLL21a

    // BLL1a
    public static void notifyException(String routine, Exception error, Id docId, c2g__codaJournal__c journalHeader, List<c2g__codaJournalLineItem__c> journalLines) {
        try {
            MonitorExecution mon = new MonitorExecution('FFA_ServiceDepartment');
            mon.log('Routine: ' + routine);
            mon.log('Document: ' + docId);
            if (error!=null) {
                mon.log('Exception: ' + error.getTypeName() + ': ' + error.getMessage());
                //mon.log('Cause: ' + error.getCause());
                //mon.log('Stack trace: ' + error.getStackTraceString());
            }
            //mon.log('Journal header: ' + JSON.serialize(journalHeader));
            //mon.log('Journal lines: ' + JSON.serialize(journalLines));
            for(c2g__codaJournalLineItem__c l : journalLines) {
                mon.log('Line ' + String.valueOf(l.c2g__LineNumber__c)
                    + ': ' + l.c2g__LineType__c + ' ' + l.c2g__LineDescription__c + ' ' 
                    + ' ' + l.Control__c + ' ' + String.valueOf(l.c2g__HomeValue__c));
            }

            mon.notifyAdmin();

        } catch(Exception e) { System.debug('notifyException failed: ' + e.getMessage()); }
    }


    public class FFASException extends Exception {}
}