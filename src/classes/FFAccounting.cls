/**
*   
*   FFAccounting  - This Class provides a static interface to Financial Force integration by DealerTeam DMS
*   Tested by: FFATests, FFATests2, FFAccounting_TEST
*
* Code coverage:
*	2017-09-05	78% (665/843)
*	2017-11-07	83% (697/836)
*	2017-11-14	83% (697/838)
*	2018-12-11	74%	(670/905)
*	2019-04-15	78%	(694/886)
*	2019-06-11	79% (704/888)
*	2019-07-11	84%	(746/888)
* 
* To cover: 
*	eliminate: catch/rollback/throw except for better error msg, 
*	reverseServiceRepairOrder, postCashEntry
*
* Modificaiton log:
*   2016-01-07  B. Leaman   BLL1 - Do NOT check if the user is logged into that company! Async posting bypasses this requirement.
*
*   2016-02-19  RedTeal     RT1   - Accept Vehilce POs now done asynchronously
*   2016-02-25  B. Leaman   BLL2 - Need to provide Control__c field value on all journal lines either PO or RO number, if not using stock#.
*   2016-04-06  B. Leaman   BLL3 IT#19590 - set vendor name on journal and lines.
*   2016-04-12  B. Leaman   BLL4 IT#23087 - need vendor name on MAS import, so add it to the journal description.
*   2016-04-21  B. Leaman   BLL5 - need control# on payable invoice lines.
*   2016-06-02  B. Leaman   BLL6 - Need PO# as control number for account 2115 on vehicle PO.
*   2016-06-10  B. Leaman   BLL7 - Use default payable dimension1 for the PIN header dimension1.
*   2016-06-29  J. Kuljis   JVK1 - Add Static method to lookup current period.
*   2016-06-29  J. Kuljis   JVK2 - Enforce current period posting on purchase orders.
*   2016-07-29  B. Leaman   BLL8 - Use CurrentUserSingleton to reduce SOQLs.
*   2016-08-17  J. Kuljis   JVK3 - Support for Parts Transfers, added a new method receiveTransferPO
*   2016-09-14  B. Leaman   BLL9 - Log failed emails to FFAccountingFailure__c so they can be easily reprocessed.
*   2016-10-26  J. Kuljis   JVK4 - Add support for part transfer commit and part transfer reversal
*   2016-11-04  J. Kuljis   JVK5 - Include accepted and committed reference fields on the transfer object to the Journal
*   2106-11-08  J. Kuljis   JVK6 - Correct inventory adjustment (Reverse Credits and Debits)
*   2016-12-09  Gaurav      #W 000799 - Changed description on Journal and its journal line and Added document source IA
*   2016-12-15  J. Kuljis   JVK7 - Respect location dimension1 on PO Line for Vehicle Purchase Order
*	2016-12-29	B. Leaman	BLL10 - Payable invoice line should have PO# for control# (vehicle POs)
*   2017-01-04	J. Kuljis	JVK8 - Reverse Service Repair Order
*	2017-01-09	B. Leaman	BLL11 - Fix applying transaction Id to register.
*	2017-01-10	B. Leaman	BLL12 - undo BLL10 again. Only use PO# for 2115 account
*	2017-02-23	B. Leaman	BLL13 - fix rental depreciation account for Demo - Not for Sale
*	2017-05-18	B. Leaman	BLL14 - new account numbers (IR-0012202) 
*	2017-09-05	B. Leaman	BLL15 IR-0013741 - rental & demo depreciation   
*	2017-10-23	B. Leaman	BLL16 IR-0021823 - better description on reversing journal.
*	2017-11-02	B. Leaman	BLL17 - FF v17 changes how the postJournal API call works with company context.   
*	2017-11-14	B. Leaman	BLL18 - need to reverse vehicle cost updates when re-opening a get-ready RO.
*	2017-12-07	B. Leaman	BLL19 - fix accounting period selection in receive vehicle po.
*	2017-12-18	B. Leaman	BLL20 - don't re-open an open RO (in case of double re-open from the cashier page).
*	2018-01-10	B. Leaman	BLL21 - Attempt to re-open avalara tax record, even if there is no customer charge, 
*							but ignore if it fails (in case document was not recorded in Avalara)
*	2018-03-07	B. Leaman	BLL22 - patch parts transfer reversal getting PO id.
*	2018-08-08	B. Leaman	BLL23 - create payable invoices from concur process
*	2018-12-12	DealerTeam	W-000524 JVK9 - re-open sublet PO.
*	2019-04-11	B. Leaman	W-000575 BLL24 - post cash entry; clean up catch/rollback/throw & catch/throw; increase coverage;
*	2019-06-11	B. Leaman	W-000706 BLL25 - prevent duplication of the accept PO function.
*	2019-08-21	B. Leaman	W-000728 BLL26 - improve efficiency (reduce SOQL queries)
*	2019-09-18	B. Leaman	W-000757 BLL27 - be able to reverse a parts transfer with the parts invoice Id instead of the transfer Id
*	2019-09-23	B. Leaman	W-000756 BLL28 - Post parts physical inventory variance
*	2019-10-29	B. Leaman	W-000771 BLL29 - Properly handle credits on misc & sublet POs.
* 	2019-12-31	B. Leaman	BLL30 - allow RO re-open if there is no journal at all and it was posted over 10 min ago
*/
public without sharing class FFAccounting {

	// BLL26
	public static EmailServicesAddress ffaEmailAddress; 
	// BLL26 end

    /**
    *   Constructor
    */
    public FFAccounting() {}

    /**
    *   Post the parts received on a purchase order to the General Ledger
    *
    *   updates: 12-23-2015 - JVK - Parts purchase orders need to be able to be partially receipted.
    */
    public static void receivePartsFromPO(Id poId, Decimal partVal) {
        // Lookup the Parts Purchase Order
        dealer__Purchase_Order__c po = [Select Id, Name, Part_Quantity_Outstanding__c, dealer__PO_Accounting_Name__c, dealer__PO_Amount__c, 
                                                dealer__Company__c, dealer__Accepted_DateTime__c, 
                                                dealer__Accepted_By__c, dealer__Status__c, LastModifiedById,
                                                dealer__Vendor__c, dealer__Vendor__r.Name, // BLL3a & BLL4a 
                                                dealer__Service_Repair_Order__c, dealer__Service_Repair_Order__r.Name // BLL2a
                                            from dealer__Purchase_Order__c where Id=:poId 
                                            limit 1];

        // Ensure the value is set
        // 
        System.debug(partVal);
        
        if(partVal==null || partVal==0) {
            throw new FFAccountingException('Error receiving part, the value to apply is 0 ');
        }

        // Select Sum of all Transactions posted to ensure there is not an overposting sittuation
        Decimal transactionAmount = (Decimal) [Select SUM(c2g__DualDebits__c) totalValue from c2g__codaTransaction__c where Purchase_Order__c =:po.Id][0].get('totalValue');
        if(transactionAmount==null) { transactionAmount=0;}

        if(transactionAmount>=po.dealer__PO_Amount__c)  throw new FFAccountingException('Error: GL Transactions can not excede purchase order values for this PO.');

        // Get the location record
        dealer__Dealer_Location__c loc = FFAccounting.getDealerLocation(po.dealer__Company__c); 

        // Sanity Check
        if(loc.Financial_Force_Dimension_1__c==null) throw new FFAccountingException('Financial Force Dimension 1 not set for Location '+po.dealer__Company__c);

        Map<String, c2g__codaGeneralLedgerAccount__c> gl_accounts = new Map<String, c2g__codaGeneralLedgerAccount__c>();
        Set<String> rc = new Set<String>{'1220','2115'};
        for(c2g__codaGeneralLedgerAccount__c gl : [Select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c IN:rc limit 10]) {
            gl_accounts.put(gl.c2g__ReportingCode__c, gl);
        }

        // Set Transaction Control
        //BLL24d SavePoint sp = Database.setSavePoint();

        // Create the Journal
        /*
        Id journal = FFAccounting.createJournal(po.dealer__Company__c, 'Purchase Order '+po.Name, po.Name, po.Name, 'PUR', Date.valueOf(po.dealer__Accepted_DateTime__c));
        */
        
        Id journalId = null;
        Date jdate = Date.today();

        c2g__codaJournal__c journalHeader       =   new c2g__codaJournal__c();
        journalHeader.c2g__OwnerCompany__c      =   FFAccounting.getFFCompany(loc.Id);
        journalHeader.c2g__Period__c            =   FFAccounting.getCurrentPeriod(journalHeader.c2g__OwnerCompany__c);
        journalHeader.c2g__JournalCurrency__c   =   FFAccounting.currency(journalHeader.c2g__OwnerCompany__c);
        //BLL4d journalHeader.c2g__JournalDescription__c=   'Purchase Order ' + po.Name;
        journalHeader.c2g__JournalDescription__c = po.dealer__Vendor__r.Name + ': Purchase Order ' + po.dealer__PO_Accounting_Name__c; 
        // if (po.dealer__Accepted_DateTime__c!=null) jdate = po.dealer__Accepted_DateTime__c.date();
        journalHeader.c2g__JournalDate__c       =   jdate;
        journalHeader.c2g__Reference__c         =   po.Name;
        journalHeader.Source__c                 =   'PUR';
        journalHeader.Purchase_Order__c         =   po.Id;
        journalHeader.Vendor__c                 =   po.dealer__Vendor__c;  // BLL3a

        // Create the Journal Lines
        List<c2g__codaJournalLineItem__c> jLines = new List<c2g__codaJournalLineItem__c>();

        String controlnbr = po.dealer__PO_Accounting_Name__c;   // BLL2a
        // No: Only sublets use RO#. if (po.dealer__Service_Repair_Order__c!=null) controlnbr = po.dealer__Service_Repair_Order__r.Name;    // BLL2a
        
        jLines.add(new c2g__codaJournalLineItem__c(
                c2g__Journal__c=journalId,
                c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                c2g__LineNumber__c=1,
                //BLL4d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                c2g__LineDescription__c=po.dealer__Vendor__r.Name + ': ' + po.dealer__PO_Accounting_Name__c, // BLL4a
                c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('2115').Id,
                c2g__Value__c=(partVal *-1),
                c2g__LineType__c='General Ledger Account',
                Vendor_Name__c=po.dealer__Vendor__c,    // BLL4a
                Control__c=controlnbr   // BLL2a
                //BLL2d Control__c=po.Name
            )
        ); 

        jLines.add(new c2g__codaJournalLineItem__c(
                c2g__Journal__c=journalId,
                c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                c2g__LineNumber__c=2,
                //BLL4d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                c2g__LineDescription__c=po.dealer__Vendor__r.Name + ': ' + po.dealer__PO_Accounting_Name__c, // BLL4a
                c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('1220').Id,
                c2g__Value__c=(partVal),
                c2g__LineType__c='General Ledger Account',
                Vendor_Name__c=po.dealer__Vendor__c,    // BLL4a
                Control__c=controlnbr   // BLL2a
                //BLL2d Control__c=po.Name
            )
        );

        // Process Journal Lines
        try {

             journalId = FinancialForce_MBW.createJournalApi(journalHeader, jLines);
             FFAccounting.postJournal(journalId);
             FFAccounting.applyJournalToRegister(po.Id, journalId);

        } Catch(DmlException e) {
            //BLL24 Database.rollback(sp);
            throw new FFAccountingException('Unable to create the journal lines '+e.getMessage());
        }

        // Update Accepted Date on Purchase Order - only if the po is completely received.
        if(po.Part_Quantity_Outstanding__c == 0) {
            try {
                po.dealer__Accepted_By__c = po.LastModifiedById;
                po.dealer__Accepted_DateTime__c = DateTime.now();
                po.dealer__Status__c = 'Accepted';

                update po;

            }  Catch(DmlException e) {
                //BLL24d Database.rollback(sp);
                throw new FFAccountingException('Failed to update purchase order accepted status ' + e.getMessage());
            }
        }
    }
    
    /**
     * Adjust Parts on-hand (Part Management Screen)
     */
    public static void adjustPartsInventory(Id invRecordId, Decimal adjustVal) {

        // Get Parts Inventory Record
        dealer__Parts_Inventory__c inventoryRecord = [SELECT Id, Name, dealer__Location__c FROM dealer__Parts_Inventory__c WHERE Id=:invRecordId LIMIT 1];

        // Get the location record
        dealer__Dealer_Location__c loc = FFAccounting.getDealerLocation(inventoryRecord.dealer__Location__c); 

        // Sanity Check
        if(loc.Financial_Force_Dimension_1__c==null) throw new FFAccountingException('Financial Force Dimension 1 not set for Location '+inventoryRecord.dealer__Location__c);

        Map<String, c2g__codaGeneralLedgerAccount__c> gl_accounts = new Map<String, c2g__codaGeneralLedgerAccount__c>();
        Set<String> rc = new Set<String>{'1220','4960'};
        for(c2g__codaGeneralLedgerAccount__c gl : [Select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c IN:rc limit 10]) {
            gl_accounts.put(gl.c2g__ReportingCode__c, gl);
        }
        System.debug('GL Accounts ->'+gl_accounts);
        
		// Set Transaction Control
        //BLL24d SavePoint sp = Database.setSavePoint();
        
        Id journalId = null;
        Date jdate = Date.today();

        c2g__codaJournal__c journalHeader       =   new c2g__codaJournal__c();
        journalHeader.c2g__OwnerCompany__c      =   FFAccounting.getFFCompany(loc.Id);
        journalHeader.c2g__Period__c            =   FFAccounting.getCurrentPeriod(journalHeader.c2g__OwnerCompany__c);
        journalHeader.c2g__JournalCurrency__c   =   FFAccounting.currency(journalHeader.c2g__OwnerCompany__c);
        journalHeader.c2g__JournalDescription__c =  inventoryRecord.Name + ' Perpetual Inventory Adjustment ';    //Work 000799
        journalHeader.c2g__JournalDate__c       =   jdate;
        journalHeader.c2g__Reference__c         =   inventoryRecord.Name;
        journalHeader.Source__c                 =   'IA';                                                         //Work 000799

        // Create the Journal Lines
        List<c2g__codaJournalLineItem__c> jLines = new List<c2g__codaJournalLineItem__c>();
        
        jLines.add(new c2g__codaJournalLineItem__c(
                c2g__Journal__c=journalId,
                c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                c2g__LineNumber__c=1,
                c2g__LineDescription__c=inventoryRecord.Name + 'Perpetual Inventory Adjustment',  //Work 000799
                c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('1220').Id,
                c2g__Value__c=(adjustVal),
                c2g__LineType__c='General Ledger Account'
            )
        ); 

        jLines.add(new c2g__codaJournalLineItem__c(
                c2g__Journal__c=journalId,
                c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                c2g__LineNumber__c=2,
                c2g__LineDescription__c=inventoryRecord.Name + 'Perpetual Inventory Adjustment',   //Work 000799
                c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('4960').Id,
                c2g__Value__c=(adjustVal  *-1),
                c2g__LineType__c='General Ledger Account'
            )
        );

        // Process Journal Lines
        try {

             journalId = FinancialForce_MBW.createJournalApi(journalHeader, jLines);

        } Catch(DmlException e) {
            //BLL24d Database.rollback(sp);
            throw new FFAccountingException('Unable to create the journal lines '+e.getMessage());
        }
    }
    

    // BLL28
    /**
     * Post Parts Variance from Physical Inventory
     */
    public static void partsPhysicalVariance(Id physicalInvId, Decimal adjustVal) {

        // Get Parts Physical Inventory Record
        dealer__PartPhysicalInventory__c physicalInvRcd = [
			select Id, Name, dealer__Location__c, Journal__c, Saved_Variance_Total__c 
			from dealer__PartPhysicalInventory__c 
			where Id=:physicalInvId 
			  and Journal__c=null
			limit 1
		];
		adjustVal = physicalInvRcd.Saved_Variance_Total__c;

        // Get the location record
        dealer__Dealer_Location__c loc = FFAccounting.getDealerLocation(physicalInvRcd.dealer__Location__c); 

        // Sanity Check
        if(loc==null || loc.Financial_Force_Dimension_1__c==null) throw new FFAccountingException('Financial Force Dimension 1 not set for Location Id ' + physicalInvRcd.dealer__Location__c);

        Map<String, c2g__codaGeneralLedgerAccount__c> gl_accounts = new Map<String, c2g__codaGeneralLedgerAccount__c>();
        Set<String> rc = new Set<String>{'1220','4960'};
        for(c2g__codaGeneralLedgerAccount__c gl : [
			Select Id, Name, c2g__ReportingCode__c 
			from c2g__codaGeneralLedgerAccount__c 
			where c2g__ReportingCode__c IN:rc 
		]) {
            gl_accounts.put(gl.c2g__ReportingCode__c, gl);
        }
        System.debug('GL Accounts ->'+gl_accounts);
        
		Id journalId = null;
        Date jdate = Date.today();

        c2g__codaJournal__c journalHeader       =   new c2g__codaJournal__c();
        journalHeader.c2g__OwnerCompany__c      =   FFAccounting.getFFCompany(loc.Id);
        journalHeader.c2g__Period__c            =   FFAccounting.getCurrentPeriod(journalHeader.c2g__OwnerCompany__c);
        journalHeader.c2g__JournalCurrency__c   =   FFAccounting.currency(journalHeader.c2g__OwnerCompany__c);
        journalHeader.c2g__JournalDescription__c =  'Recording the final results of the parts physical inventory audit'; 
        journalHeader.c2g__JournalDate__c       =   jdate;
        journalHeader.c2g__Reference__c         =   physicalInvRcd.Name; // Parts Physical Inventory Audit
        journalHeader.Source__c                 =   'PI'; 

        // Create the Journal Lines
        List<c2g__codaJournalLineItem__c> jLines = new List<c2g__codaJournalLineItem__c>();
        
        jLines.add(new c2g__codaJournalLineItem__c(
                c2g__Journal__c=journalId,
                c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                c2g__LineNumber__c=1,
                c2g__LineDescription__c=physicalInvRcd.Name + ' Physical Inventory Variance', 
                c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('1220').Id,
                c2g__Value__c=adjustVal,
                c2g__LineType__c='General Ledger Account'
            )
        ); 

        jLines.add(new c2g__codaJournalLineItem__c(
                c2g__Journal__c=journalId,
                c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                c2g__LineNumber__c=2,
                c2g__LineDescription__c=physicalInvRcd.Name + ' Physical Inventory Variance',  
                c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('4960').Id,
                c2g__Value__c= -adjustVal,
                c2g__LineType__c='General Ledger Account'
            )
        );

        // Process Journal Lines
        try {

            journalId = FinancialForce_MBW.createJournalApi(journalHeader, jLines);
			FFAccounting.postJournal(journalId);
			Database.update(new dealer__PartPhysicalInventory__c(Id=physicalInvRcd.Id, Journal__c=journalId), false);

        } Catch(DmlException e) {
            throw new FFAccountingException('Unable to create the journal lines ' + e.getMessage());
        }
    }
	// BLL28 end

    /**
     * Commit the Transfer PO JVK4
     */
    public static void commitTransferPO(Id purchsaeOrderId) {
        
       // Get associated Account#'s 
        Map<String, c2g__codaGeneralLedgerAccount__c> gl_accounts = new Map<String, c2g__codaGeneralLedgerAccount__c>();
        Set<String> rc = new Set<String>{'1220','1225'};
        for(c2g__codaGeneralLedgerAccount__c gl : [Select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c IN:rc limit 10]) {
            gl_accounts.put(gl.c2g__ReportingCode__c, gl);
        }

        // Get the transfer record from the POID
        dealer__PartTransfer__c transfer = [Select Id, Name, dealer__From_Location__c, dealer__To_Location__c, dealer__Purchase_Order__c From dealer__PartTransfer__c where dealer__Purchase_Order__c =:purchsaeOrderId limit 1];   
        dealer__Purchase_Order__c po = [Select Id, Name, Part_Quantity_Outstanding__c, dealer__PO_Accounting_Name__c, dealer__PO_Amount__c, 
                                                dealer__Company__c, dealer__Accepted_DateTime__c, 
                                                dealer__Accepted_By__c, dealer__Status__c, LastModifiedById,
                                                dealer__Vendor__c, dealer__Vendor__r.Name,
                                                dealer__Service_Repair_Order__c, dealer__Service_Repair_Order__r.Name
                                            from dealer__Purchase_Order__c where Id=:purchsaeOrderId
                                                limit 1];

        // Set Transaction Control
        //BLL24d SavePoint sp = Database.setSavePoint();        
        
        dealer__Dealer_Location__c loc = FFAccounting.getDealerLocation(po.dealer__Company__c);
        dealer__Dealer_Location__c out_loc = FFAccounting.getDealerLocation(transfer.dealer__From_Location__c);
        
        Id journalId = null;
        Date jdate = Date.today();
    
        c2g__codaJournal__c journalHeader       =   new c2g__codaJournal__c();
        journalHeader.c2g__OwnerCompany__c      =   FFAccounting.getFFCompany(loc.Id);
        journalHeader.c2g__Period__c            =   FFAccounting.getCurrentPeriod(journalHeader.c2g__OwnerCompany__c);
        journalHeader.c2g__JournalCurrency__c   =   FFAccounting.currency(journalHeader.c2g__OwnerCompany__c);
        journalHeader.c2g__JournalDescription__c =  'Initiate Transfer '+po.dealer__Vendor__r.Name + ': Purchase Order ' + po.dealer__PO_Accounting_Name__c; 
        journalHeader.c2g__JournalDate__c       =   jdate;
        journalHeader.c2g__Reference__c         =   'Transfer '+po.Name;
        journalHeader.Source__c                 =   'PUR';
        journalHeader.Purchase_Order__c         =   po.Id;
        journalHeader.Vendor__c                 =   po.dealer__Vendor__c;
        
        List<c2g__codaJournalLineItem__c> jLines = new List<c2g__codaJournalLineItem__c>();
        String controlnbr = po.dealer__PO_Accounting_Name__c;   
        
        // In Physical Location
        jLines.add(new c2g__codaJournalLineItem__c(
                c2g__Journal__c=journalId,
                c2g__Dimension1__c=out_loc.Financial_Force_Dimension_1__c,
                c2g__LineNumber__c=2,
                c2g__LineDescription__c='Initiaite Transfer '+transfer.Name +' from '+ out_loc.dealer__Company_Number__c +' to '+ loc.dealer__Company_Number__c +' on ' + po.dealer__PO_Accounting_Name__c,
                c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('1225').Id,
                c2g__Value__c=(po.dealer__PO_Amount__c),
                c2g__LineType__c='General Ledger Account',
                Vendor_Name__c=po.dealer__Vendor__c,
                Control__c=controlnbr
            )
        );
                
        
        // Out Location
        jLines.add(new c2g__codaJournalLineItem__c(
                c2g__Journal__c=journalId,
                c2g__Dimension1__c=out_loc.Financial_Force_Dimension_1__c,
                c2g__LineNumber__c=1,
                c2g__LineDescription__c='Initiaite Transfer '+transfer.Name +' from '+ out_loc.dealer__Company_Number__c +' to '+ loc.dealer__Company_Number__c +' on ' + po.dealer__PO_Accounting_Name__c,
                c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('1220').Id,
                c2g__Value__c=(po.dealer__PO_Amount__c *-1),
                c2g__LineType__c='General Ledger Account',
                Vendor_Name__c=po.dealer__Vendor__c,
                Control__c=controlnbr
            )
        ); 

        // Process Journal Lines
        try {
             //if(!test.isRunningTest()){
                 journalId = FinancialForce_MBW.createJournalApi(journalHeader, jLines);
                 FFAccounting.postJournal(journalId);
                 FFAccounting.applyJournalToRegister(po.Id, journalId);
    
                 // Set the ID of the Commit Journal on the transfer record
                 transfer.Commit_Journal__c = journalId;
                 update transfer;
             //}

        } Catch(DmlException e) {
            //BLL24d Database.rollback(sp);
            if(!test.isRunningTest()) throw new FFAccountingException('Unable to create the journal lines '+e.getMessage());
        } 
        
    }
    
    /**
     * Accept transfer, clear holding account JVK4
     */
    public static void receiveTransferPO(Id transferId) {
        
       // Get associated Account#'s 
        Map<String, c2g__codaGeneralLedgerAccount__c> gl_accounts = new Map<String, c2g__codaGeneralLedgerAccount__c>();
        Set<String> rc = new Set<String>{'1220','1225', '2903'};
        for(c2g__codaGeneralLedgerAccount__c gl : [Select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c IN:rc limit 10]) {
            gl_accounts.put(gl.c2g__ReportingCode__c, gl);
        }

        // Set Transaction Control
        //BLL24d SavePoint sp = Database.setSavePoint();        

        dealer__PartTransfer__c transfer = [Select Id, Name, dealer__From_Location__c, dealer__To_Location__c, dealer__Purchase_Order__c From dealer__PartTransfer__c where Id=:transferId limit 1];
        dealer__Purchase_Order__c po = [Select Id, Name, Part_Quantity_Outstanding__c, dealer__PO_Accounting_Name__c, dealer__PO_Amount__c, 
                                                dealer__Company__c, dealer__Accepted_DateTime__c, 
                                                dealer__Accepted_By__c, dealer__Status__c, LastModifiedById,
                                                dealer__Vendor__c, dealer__Vendor__r.Name,
                                                dealer__Service_Repair_Order__c, dealer__Service_Repair_Order__r.Name
                                            from dealer__Purchase_Order__c where Id=:transfer.dealer__Purchase_Order__c 
                                            limit 1]; 
        
        
        
        dealer__Dealer_Location__c loc = FFAccounting.getDealerLocation(po.dealer__Company__c);
        dealer__Dealer_Location__c out_loc = FFAccounting.getDealerLocation(transfer.dealer__From_Location__c);
        
        Id journalId = null;
        Date jdate = Date.today();
    
        c2g__codaJournal__c journalHeader       =   new c2g__codaJournal__c();
        journalHeader.c2g__OwnerCompany__c      =   FFAccounting.getFFCompany(loc.Id);
        journalHeader.c2g__Period__c            =   FFAccounting.getCurrentPeriod(journalHeader.c2g__OwnerCompany__c);
        journalHeader.c2g__JournalCurrency__c   =   FFAccounting.currency(journalHeader.c2g__OwnerCompany__c);
        journalHeader.c2g__JournalDescription__c = po.dealer__Vendor__r.Name + ': Purchase Order ' + po.dealer__PO_Accounting_Name__c; 
        journalHeader.c2g__JournalDate__c       =   jdate;
        journalHeader.c2g__Reference__c         =   'Transfer '+po.Name;
        journalHeader.Source__c                 =   'PUR';
        journalHeader.Purchase_Order__c         =   po.Id;
        journalHeader.Vendor__c                 =   po.dealer__Vendor__c;
        
        List<c2g__codaJournalLineItem__c> jLines = new List<c2g__codaJournalLineItem__c>();
        String controlnbr = po.dealer__PO_Accounting_Name__c;   
        
        /* (SAME COMPANY) Does this transaction exist in the same ff company?  */
        if(loc.Company__r.MainCompanyDimension1__c==out_loc.Company__r.MainCompanyDimension1__c) {

            // Debit the inventory account for the receiving party
            jLines.add(new c2g__codaJournalLineItem__c(
                    c2g__Journal__c=journalId,
                    c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                    c2g__LineNumber__c=1,
                    c2g__LineDescription__c=transfer.Name +' from '+ out_loc.dealer__Company_Number__c +' to '+ loc.dealer__Company_Number__c +' on ' + po.dealer__PO_Accounting_Name__c,
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('1220').Id,
                    c2g__Value__c=(po.dealer__PO_Amount__c),
                    c2g__LineType__c='General Ledger Account',
                    Vendor_Name__c=po.dealer__Vendor__c,
                    Control__c=controlnbr
                )
            );
                    
            
            // Credit the transfer account on the out company
            jLines.add(new c2g__codaJournalLineItem__c(
                    c2g__Journal__c=journalId,
                    c2g__Dimension1__c=out_loc.Financial_Force_Dimension_1__c,
                    c2g__LineNumber__c=2,
                    c2g__LineDescription__c=transfer.Name +' from '+ out_loc.dealer__Company_Number__c +' to '+ loc.dealer__Company_Number__c +' on ' + po.dealer__PO_Accounting_Name__c,
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('1225').Id,
                    c2g__Value__c=(po.dealer__PO_Amount__c *-1),
                    c2g__LineType__c='General Ledger Account',
                    Vendor_Name__c=po.dealer__Vendor__c,
                    Control__c=controlnbr
                )
            );             
        }
        
        /* (CROSS COMPANY) Does this transction cross ff companies? */
        if(loc.Company__r.MainCompanyDimension1__c!=out_loc.Company__r.MainCompanyDimension1__c) {
            
            // Debit the inventory account for the receiving party
            jLines.add(new c2g__codaJournalLineItem__c(
                    c2g__Journal__c=journalId, c2g__LineNumber__c=1,
                    c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                    c2g__LineDescription__c=transfer.Name +' from '+ out_loc.dealer__Company_Number__c +' to '+ loc.dealer__Company_Number__c +' on ' + po.dealer__PO_Accounting_Name__c,
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('1220').Id,
                    c2g__Value__c=(po.dealer__PO_Amount__c), c2g__LineType__c='General Ledger Account',
                    Vendor_Name__c=po.dealer__Vendor__c, Control__c=controlnbr
                )
            );
                    
            
            // Credit the transfer account on the out company
            jLines.add(new c2g__codaJournalLineItem__c(
                    c2g__Journal__c=journalId, c2g__LineNumber__c=2,
                    c2g__Dimension1__c=out_loc.Financial_Force_Dimension_1__c,
                    c2g__LineDescription__c=transfer.Name +' from '+ out_loc.dealer__Company_Number__c +' to '+ loc.dealer__Company_Number__c +' on ' + po.dealer__PO_Accounting_Name__c,
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('1225').Id,
                    c2g__Value__c=(po.dealer__PO_Amount__c *-1), c2g__LineType__c='General Ledger Account',
                    Vendor_Name__c=po.dealer__Vendor__c, Control__c=controlnbr
                )
            ); 

            // Intercompany clearing account for in location
            jLines.add(new c2g__codaJournalLineItem__c(
                    c2g__Journal__c=journalId, c2g__LineNumber__c=3,
                    c2g__Dimension1__c=loc.Company__r.MainCompanyDimension1__c,
                    c2g__LineDescription__c=transfer.Name +' from '+ out_loc.dealer__Company_Number__c +' to '+ loc.dealer__Company_Number__c +' on ' + po.dealer__PO_Accounting_Name__c,
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('2903').Id,
                    c2g__Value__c=(po.dealer__PO_Amount__c * -1), c2g__LineType__c='General Ledger Account',
                    Vendor_Name__c=po.dealer__Vendor__c, Control__c=controlnbr
                )
            );
            
            // Out Location Clearing Account
            jLines.add(new c2g__codaJournalLineItem__c(
                    c2g__Journal__c=journalId, c2g__LineNumber__c=4,
                    c2g__Dimension1__c=out_loc.Company__r.MainCompanyDimension1__c,
                    c2g__LineDescription__c=transfer.Name +' from '+ out_loc.dealer__Company_Number__c +' to '+ loc.dealer__Company_Number__c +' on ' + po.dealer__PO_Accounting_Name__c,
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('2903').Id,
                    c2g__Value__c=(po.dealer__PO_Amount__c), c2g__LineType__c='General Ledger Account',
                    Vendor_Name__c=po.dealer__Vendor__c, Control__c=controlnbr
                )
            );             
        }


        // Process Journal Lines
        try {

             journalId = FinancialForce_MBW.createJournalApi(journalHeader, jLines);
             FFAccounting.postJournal(journalId);
             FFAccounting.applyJournalToRegister(po.Id, journalId);

             transfer.Accept_Journal__c=journalId;
             update transfer;

        } Catch(DmlException e) {
            //BLL24d Database.rollback(sp);
            throw new FFAccountingException('Unable to create the journal lines '+e.getMessage());
        }        
        
    }
    
    /**
     * Reverse Committed Transfer JVK4
     */
    public static void reverseTransferPO(Id transferId) {

		// BLL22a get the transfer Id from the referenced PO (if PO id is sent instead of tfr id)
		System.debug(transferId);
		if (transferId.getSObjectType()==Schema.dealer__Purchase_Order__c.SObjectType) {
			List<dealer__PartTransfer__c> pts = [select Id from dealer__PartTransfer__c where dealer__Purchase_Order__c=:transferId];
			if (pts.size()==1) transferId = pts[0].Id;
		}
		// BLL22a end
		// BLL27
		if (transferId.getSObjectType()==Schema.dealer__Parts_Invoice__c.SObjectType) {
			List<dealer__PartTransfer__c> pts = [select Id from dealer__PartTransfer__c where dealer__Parts_Invoice__c=:transferId];
			if (pts.size()==1) transferId = pts[0].Id;
		}
		// BLL27 end
		        
        // Get the journal to be reversed
        dealer__PartTransfer__c transfer = [
			SELECT Id, Name, Commit_Journal__c, Commit_Journal__r.c2g__OwnerCompany__c, Commit_Journal__r.c2g__JournalDate__c,
				Commit_Journal__r.c2g__Reference__c, Commit_Journal__r.Purchase_Order__r.Name, 
				dealer__Purchase_Order__c, dealer__Purchase_Order__r.Name
			FROM dealer__PartTransfer__c WHERE Id=:transferId
		];

        List<c2g__codaCompany__c> ListCompany = new List<c2g__codaCompany__c>();
        
        ListCompany = [SELECT Id, Name, OwnerId FROM c2g__codaCompany__c WHERE Id=:transfer.Commit_Journal__r.c2g__OwnerCompany__c];

        c2g__codaCompany__c company;
        
        if(ListCompany.size() > 0) company = ListCompany[0];

        //c2g__codaPeriod__c period = FinancialForce_MBW.getOpenPeriod(company, transfer.Commit_Journal__r.c2g__JournalDate__c);        
        c2g__codaPeriod__c period = FinancialForce_MBW.getOpenPeriod(company, Date.today()); //JVK8 //Set to Todays Date (No crossing periods)        

        List<c2g.CODAAPIJournalTypes_12_0.ReversingInformation> reversalRecords = new List<c2g.CODAAPIJournalTypes_12_0.ReversingInformation>();

        c2g.CODAAPICommon.Reference jRef = new c2g.CODAAPICommon.Reference();
        jRef.Id=transfer.Commit_Journal__c;

        c2g.CODAAPIJournalTypes_12_0.ReversingInformation reversal = new c2g.CODAAPIJournalTypes_12_0.ReversingInformation();
        reversal.OriginalJournalRef = jRef;
        reversal.ReversingDescription = 'Reversing part transfer ' + transfer.Name + ', ' 
			+ transfer.Commit_Journal__r.c2g__Reference__c;	// BLL16a
        reversal.ReversingReference = transfer.Name;
        reversal.ReversingPeriod = new c2g.CODAAPICommon.Reference();
        reversal.ReversingPeriod.Name = period.Name;
        reversal.ReversingDate = Date.today();

        reversalRecords.add(reversal);

        System.debug(reversalRecords);
        
        //BLL24d try {
            
            c2g.CODAAPICommon_10_0.Context ctx = new c2g.CODAAPICommon_10_0.Context();
            ctx.CompanyName = Company.Name;
            System.debug(ctx);
            
            c2g.CODAAPIJournal_12_0.BulkReverseJournal(ctx, reversalRecords);

        //BLL24d } Catch(Exception e) {
        //BLL24d     throw new FFAccountingException(e.getMessage());
        //BLL24d }            
    }

	// JVK9
    /**
     *
     * reverse sublet purchase order
     *
     */
    public static void reverseSubletPurchaseOrder(Id poId) {

        // Logic flow : https://www.lucidchart.com/documents/edit/39527dad-6d45-499c-9d76-3b23e056c2d0/0
        FFAccounting fa = new FFAccounting();

        // Obtain the record
        dealer__Purchase_Order__c po = fa.purchaseOrderSelector(poId);

        // Preflight validation
        if(po.RecordType.DeveloperName!='Sublet') throw new FFAccountingException('Only sublet purchase orders may be reversed.');

        // Is payables processed
        if(fa.isSubletPayablesProcessed(po)) throw new FFAccountingException('Purchase Order already has a payable invoice attached.  Unable to reverse.');

        // If the RO is posted, halt execution and alert user
        if(fa.isRepairOrderPosted(po)) throw new FFAccountingException('Associated Service Repair Order is Posted, please reverse assocaited Journal');

        // Create reversing journal in current period
        //BLL24d try {
            fa.reverseSubletPurchaseOrderExec(po, fa.journalQuerySelectorByPurchaseOrder(po.Id));
        //BLL24d } Catch(Exception e) {
        //BLL24d     throw new FFAccountingException(e.getMessage());
        //BLL24d }

    }

    /* Called from the reverseSubletPurchaseOrder method */
    public dealer__Purchase_Order__c purchaseOrderSelector(Id poId) {
        return [SELECT Id, Name, Payable_Invoice__c, dealer__Accepted_DateTime__c, dealer__Accepted_By__c, dealer__Status__c, dealer__Service_Repair_Order__c, 
                    dealer__Service_Repair_Order__r.dealer__Status__c,dealer__Service_Repair_Order__r.Journal__c,dealer__Service_Repair_Order__r.Journal__r.Name,dealer__Service_Repair_Order__r.Journal__r.c2g__JournalStatus__c,
					dealer__Service_Repair_Order__r.Journal__r.c2g__Type__c,
                    RecordType.DeveloperName 
                FROM dealer__Purchase_Order__c 
                WHERE Id =:poId LIMIT 1];        
    }

    /* Called from the reverseSubletPurchaseOrder method */
    public c2g__codaJournal__c journalQuerySelectorByPurchaseOrder(Id poId) {
        c2g__codaJournal__c[] journals = [
			SELECT Id, Name, c2g__JournalStatus__c, Purchase_Order__c, c2g__OwnerCompany__c
			FROM  c2g__codaJournal__c 
			WHERE Purchase_Order__c =: poId 
			  AND c2g__JournalStatus__c='Complete' 
			ORDER BY CreatedDate DESC
			LIMIT 1
		];
        System.assert(journals.size()==1, 'No complete journal found for Purchase Order');
        return journals[0];
    }

	/* isJournalReversed */
	public boolean isJournalReversed(Id journalid) {
		c2g__codaJournal__c journal = [
			select Id, c2g__JournalStatus__c,
				(select Id, Name, c2g__Type__c, c2g__JournalStatus__c from c2g__ReversingJournals__r)
			from c2g__codaJournal__c
			where Id=:journalid
			limit 1
		];
		System.debug(journal);
		System.debug(journal.c2g__ReversingJournals__r);
		if (journal.c2g__ReversingJournals__r.size()>0) System.debug(journal.c2g__ReversingJournals__r[0]);
		return journal!=null && journal.c2g__ReversingJournals__r.size()==1 
			&& journal.c2g__ReversingJournals__r[0].c2g__Type__c=='Reversing Journal'
			&& journal.c2g__ReversingJournals__r[0].c2g__JournalStatus__c=='Complete';
	}

    /* Used to determine if the payables are already posted on this purchase order */
    public boolean isSubletPayablesProcessed(dealer__Purchase_Order__c po) {
        //BLL24d if(po.Payable_Invoice__c!=null) {
        //BLL24d     return true;
        //BLL24d }
        //BLL24d return false;
		return po.Payable_Invoice__c!=null;	// BLL24a
    }

    /* Used when reversing a purchase order to ensure the associated repair order is not posted */
    public boolean isRepairOrderPosted(dealer__Purchase_Order__c po) {
        //BLL24d if(po.dealer__Service_Repair_Order__r.Journal__c!=null && po.dealer__Service_Repair_Order__r.Journal__r.c2g__JournalStatus__c=='Complete') {
        //BLL24d    return true;
        //BLL24d }
        //BLL24d return false;
		System.debug(po.dealer__Service_Repair_Order__r.Journal__r.Name);
		System.debug(po.dealer__Service_Repair_Order__r.Journal__r.c2g__JournalStatus__c);
		return po.dealer__Service_Repair_Order__r.Journal__c!=null 
			&& !isJournalReversed(po.dealer__Service_Repair_Order__r.Journal__c); 	// BLL24a
    }

    /* Perform the reversing of a Sublet Purchase Order */
    public void reverseSubletPurchaseOrderExec(dealer__Purchase_Order__c po, c2g__codaJournal__c jrnl) {

        List<c2g__codaCompany__c> ListCompany = new List<c2g__codaCompany__c>();
        ListCompany = [SELECT Id, Name, OwnerId FROM c2g__codaCompany__c WHERE Id=:jrnl.c2g__OwnerCompany__c];

       	c2g__codaCompany__c company;        
        if(ListCompany.size() > 0){
            company = ListCompany[0];
        } else {
            throw new FFAccountingException('No company found on the journal.');
        }		

		c2g__codaPeriod__c period = FinancialForce_MBW.getOpenPeriod(company, Date.today());
        List<c2g.CODAAPIJournalTypes_12_0.ReversingInformation> reversalRecords = new List<c2g.CODAAPIJournalTypes_12_0.ReversingInformation>();

        c2g.CODAAPICommon.Reference jRef = new c2g.CODAAPICommon.Reference();
        jRef.Id=jrnl.Id;

        c2g.CODAAPIJournalTypes_12_0.ReversingInformation reversal = new c2g.CODAAPIJournalTypes_12_0.ReversingInformation();
        reversal.OriginalJournalRef = jRef;
        reversal.ReversingDescription = 'Reopen ' + po.Name + ' reversing journal ' + jrnl.Name;
        reversal.ReversingReference = po.Name;
        reversal.ReversingPeriod = new c2g.CODAAPICommon.Reference();
        reversal.ReversingPeriod.Name = period.Name;
        reversal.ReversingDate = Date.today();

        reversalRecords.add(reversal);
    
        //BLL24d try {
            
            c2g.CODAAPICommon_10_0.Context ctx = new c2g.CODAAPICommon_10_0.Context();
            ctx.CompanyName = Company.Name;
            c2g.CODAAPIJournal_12_0.BulkReverseJournal(ctx, reversalRecords);
           	
            // re-open purchase order
            po.dealer__Status__c = 'Open';
			po.dealer__Accepted_DateTime__c = null;

            update po;

        //BLL24d } Catch(Exception e) {
        //BLL24d     throw new FFAccountingException(e.getMessage());
        //BLL24d }            
    }
	// JVK9
    
    /**
     * Reverse the service RO, added 1/4/2017 - JVK8
     */
    public static void reverseServiceRepairOrder(Id roId) {
        
        dealer__Service_Repair_Order__c ro = [
        	SELECT Id, Name, Journal__c, Journal__r.Name, Journal__r.c2g__OwnerCompany__c, dealer__Company__c,
        		dealer__Status__c, dealer__Posted_Date_Time__c,	// BLL20a , BLL30c
        		dealer__Customer_Charges__c, dealer__Vehicle_Inventory__c, dealer__Vehicle__c 	// BLL18c 
        	FROM dealer__Service_Repair_Order__c 
        	WHERE Id=:roId LIMIT 1
        ];
        
        // BLL20a
        if (ro.dealer__Status__c!='Posted') {
        	System.debug(ro);
        	throw new FFAccountingException('RO ' + ro.Name + ' is not posted, so it cannot be re-opened.');
        }
        // BLL20a end
        
        // First Transaction must be the Callout
        //BLL21d if(ro.dealer__Customer_Charges__c!=null&&ro.dealer__Customer_Charges__c>0) {
	        try {
				AvaTax_MBW serviceTaxation = AvaTax_MBW.getInstanceSROId(ro.Id);
				serviceTaxation.adjustTax(8, 'Re-open Repair Order');
	        } Catch(Exception e) {
	    //BLL21d         throw new FFAccountingException(e.getMessage());
	        }
        //BLL21d }
        
        //BLL16d  Open RO's for Editing
		//BLL16d MW_TriggerControls__c tc = new MW_TriggerControls__c();
        //BLL16d try {
		//BLL16d 	tc = [SELECT Enabled__c, Description__c, Name, Id FROM MW_TriggerControls__c WHERE Name='RepairOrderProtect' LIMIT 1];	// BLL16c
    	//BLL16d 	tc.Enabled__c=false;
        //BLL16d     update tc;
        //BLL16d } Catch(DmlException e) {
        //BLL16d     throw new FFAccountingException(e.getMessage());
        //BLL16d }
        
		// BLL30 - if no journal and it's been less than 15 min, throw error
		if (ro.Journal__c==null && ro.dealer__Posted_Date_Time__c>DateTime.now().addMinutes(-15) ) {
			throw new FFAccountingException(ro.Name + ' has not had enough time to finished posting. Please try re-opening later.');
		}

		// BLL30 - if there is a journal reverse it
		if (ro.Journal__c!=null) { 

        List<c2g__codaCompany__c> ListCompany = new List<c2g__codaCompany__c>();
        ListCompany = [SELECT Id, Name, OwnerId FROM c2g__codaCompany__c WHERE Id=:ro.Journal__r.c2g__OwnerCompany__c];

       	c2g__codaCompany__c company;        
        if(ListCompany.size() > 0){
            company = ListCompany[0];
        } else {
            throw new FFAccountingException('No company found on the journal.');
        }		

		c2g__codaPeriod__c period = FinancialForce_MBW.getOpenPeriod(company, Date.today());
        List<c2g.CODAAPIJournalTypes_12_0.ReversingInformation> reversalRecords = new List<c2g.CODAAPIJournalTypes_12_0.ReversingInformation>();

        c2g.CODAAPICommon.Reference jRef = new c2g.CODAAPICommon.Reference();
        jRef.Id=ro.Journal__c;

        c2g.CODAAPIJournalTypes_12_0.ReversingInformation reversal = new c2g.CODAAPIJournalTypes_12_0.ReversingInformation();
        reversal.OriginalJournalRef = jRef;
        //BLL16d reversal.ReversingDescription = 'Reversing Service Repair Order';
        reversal.ReversingDescription = 'Reopen ' + ro.Name + ' reversing journal ' + ro.Journal__r.Name;	// BLL16a
        reversal.ReversingReference = ro.Name;
        reversal.ReversingPeriod = new c2g.CODAAPICommon.Reference();
        reversal.ReversingPeriod.Name = period.Name;
        reversal.ReversingDate = Date.today();

        reversalRecords.add(reversal);
    
        //BLL24d try {
            
            c2g.CODAAPICommon_10_0.Context ctx = new c2g.CODAAPICommon_10_0.Context();
            ctx.CompanyName = Company.Name;
            c2g.CODAAPIJournal_12_0.BulkReverseJournal(ctx, reversalRecords);
		}	// BLL30 end
            ro.TaxPostDT__c = null;
            ro.TaxCommitDT__c = null;
            //ro.dealer__Status__c = 'Cashier';
            ro.dealer__Status__c = 'Open';
            ro.dealer__Posted_Date_Time__c = null;
            update ro;
        
        	// BLL18a
        	FFA_ServiceDepartment.GetReadyUpdateVehicle('ReOpen', ro, null);
        	// BLL18a end
            
            //BLL16d tc.Enabled__c=true;
            //BLL16d update tc;
        //BLL24d } Catch(Exception e) {
        //BLL24d     throw new FFAccountingException(e.getMessage());
        //BLL24d }    
        
    }
    /**
     * receiveMiscPO - receive the contents of a miscellaneous purchsae order
     * @param poId : purchase order record id
     */
    public static void receiveMiscPO(Id poId) {

        dealer__Purchase_Order__c po = [Select Id, Name, dealer__PO_Amount__c, dealer__Accepted_DateTime__c, dealer__Company__c, dealer__PO_Accounting_Name__c, dealer__Vendor__c, dealer__Vendor__r.Name from dealer__Purchase_Order__c where Id=:poId limit 1];
        List<dealer__Purchase_Order_Line__c> poLines = [SELECT dealer__Amount__c, dealer__Description__c, GeneralLedgerAcct__c, GeneralLedgerAcct__r.GeneralLedgerAccountFF__c, dealer__Item_Value__c, dealer__RecordType__c, dealer__Purchase_Order__c, Id, Name, dealer__Account__c 
                                                            FROM dealer__Purchase_Order_Line__c
                                                            Where dealer__Purchase_Order__c =: po.Id];

        // Journal header and Lines
        dealer__Dealer_Location__c loc = FFAccounting.getDealerLocation(po.dealer__Company__c); 
        Id journalId = null;
        Date jdate = Date.today();

        c2g__codaJournal__c journalHeader       =   new c2g__codaJournal__c();
        journalHeader.c2g__OwnerCompany__c      =   FFAccounting.getFFCompany(po.dealer__Company__c);
        journalHeader.c2g__Period__c            =   FFAccounting.getCurrentPeriod(journalHeader.c2g__OwnerCompany__c); //JVK2
        journalHeader.c2g__JournalCurrency__c   =   FFAccounting.currency(journalHeader.c2g__OwnerCompany__c);
        //BLL4d journalHeader.c2g__JournalDescription__c=   'Purchase Order ' + po.Name; 
        journalHeader.c2g__JournalDescription__c = po.dealer__Vendor__r.Name + ': Purchase Order ' + po.dealer__PO_Accounting_Name__c; 
        // if (po.dealer__Accepted_DateTime__c!=null) jdate = po.dealer__Accepted_DateTime__c.date(); //JVK2
        journalHeader.c2g__JournalDate__c       =   jdate;
        journalHeader.c2g__Reference__c         =   po.Name;
        journalHeader.Source__c                 =   'PUR';
        journalHeader.Purchase_Order__c         =   po.Id;
        journalHeader.Vendor__c                 =   po.dealer__Vendor__c;  // BLL3a

        // Coda Line Detail 
        List<c2g__codaJournalLineItem__c> lines = new List<c2g__codaJournalLineItem__c>();
        
        // Set Required Balance
        Decimal balance = 0;

        // Get related account numbers
        Map<String, c2g__codaGeneralLedgerAccount__c> gl_accounts = new Map<String, c2g__codaGeneralLedgerAccount__c>();
        Set<String> rc = new Set<String>{'1220','2115','2100','4905','5304','4950'};
        for(c2g__codaGeneralLedgerAccount__c gl : [Select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c IN:rc limit 10]) {
            gl_accounts.put(gl.c2g__ReportingCode__c, gl);
        }       

        String controlnbr = po.dealer__PO_Accounting_Name__c;   // BLL2a
        // No: Only sublets use RO#. if (po.dealer__Service_Repair_Order__c!=null) controlnbr = po.dealer__Service_Repair_Order__r.Name;    // BLL2a

        // Set the unbilled purchases
        lines.add(new c2g__codaJournalLineItem__c(
                c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                c2g__LineNumber__c=1,
                //BLL4d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                c2g__LineDescription__c=po.dealer__Vendor__r.Name + ': ' + po.dealer__PO_Accounting_Name__c, // BLL4a
                c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('2115').Id,
                //BLL29 
				//c2g__Value__c=FFAccounting.credit(po.dealer__PO_Amount__c),
				c2g__Value__c= -po.dealer__PO_Amount__c,
				// BLL29 end
                c2g__LineType__c='General Ledger Account',
                Vendor_Name__c=po.dealer__Vendor__c,    // BLL4a
                Control__c=controlnbr   // BLL2a
                
            )
        );
        balance+=po.dealer__PO_Amount__c;

        // Iterate the PO Lines for MISC Charges
        for(dealer__Purchase_Order_Line__c pl : poLines) {
            lines.add(new c2g__codaJournalLineItem__c(
                    c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                    c2g__LineNumber__c=1,
                    //BLL4d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                    c2g__LineDescription__c=po.dealer__Vendor__r.Name + ': ' + po.dealer__PO_Accounting_Name__c, // BLL4a
                    c2g__GeneralLedgerAccount__c=pl.GeneralLedgerAcct__r.GeneralLedgerAccountFF__c,
                    // BLL29
					//c2g__Value__c=FFAccounting.debit(pl.dealer__Amount__c),
					c2g__Value__c=pl.dealer__Amount__c,
					// BLL29 end
                    c2g__LineType__c='General Ledger Account', 
                    Vendor_Name__c=po.dealer__Vendor__c,    // BLL4a
                    Control__c=controlnbr   // BLL2a
                )
            );          
        }

        //BLL24d SavePoint sp = Database.setSavePoint();

        // Process Journal Lines
        try {

             journalId = FinancialForce_MBW.createJournalApi(journalHeader, lines);
             FFAccounting.postJournal(journalId);
             FFAccounting.applyJournalToRegister(po.Id, journalId);

        } Catch(DmlException e) {
            //BLL24d Database.rollback(sp);
            throw new FFAccountingException('Unable to create the journal lines '+e.getMessage());
        }

    }

    /**
     * receiveSubletPO - Receive a sublet purchase order
     * @param poId - purchase order record id
     * @return void
     * 
     */
    public static void receiveSubletPO(Id poId) {

        dealer__Purchase_Order__c po = [
            Select Id, Name, dealer__PO_Amount__c, dealer__Accepted_DateTime__c, dealer__Company__c, dealer__PO_Accounting_Name__c, dealer__Vendor__c, dealer__Vendor__r.Name, // BLL4c
                dealer__Service_Repair_Order__c, dealer__Service_Repair_Order__r.Name
            from dealer__Purchase_Order__c where Id=:poId limit 1];
        List<dealer__Purchase_Order_Line__c> poLines = [SELECT dealer__Amount__c, dealer__Description__c, GeneralLedgerAcct__c, GeneralLedgerAcct__r.GeneralLedgerAccountFF__c, dealer__Item_Value__c, dealer__RecordType__c, dealer__Purchase_Order__c, Id, Name, dealer__Account__c 
                                                            FROM dealer__Purchase_Order_Line__c
                                                            Where dealer__Purchase_Order__c =: po.Id];

        // Journal header and Lines
        dealer__Dealer_Location__c loc = FFAccounting.getDealerLocation(po.dealer__Company__c); 
        Id journalId = null;
        Date jdate = Date.today();

        c2g__codaJournal__c journalHeader       =   new c2g__codaJournal__c();
        journalHeader.c2g__OwnerCompany__c      =   FFAccounting.getFFCompany(po.dealer__Company__c);
        journalHeader.c2g__Period__c            =   FFAccounting.getCurrentPeriod(journalHeader.c2g__OwnerCompany__c); // JVK2
        journalHeader.c2g__JournalCurrency__c   =   FFAccounting.currency(journalHeader.c2g__OwnerCompany__c);
        //BLL4d journalHeader.c2g__JournalDescription__c=   'Purchase Order ' + po.Name; 
        journalHeader.c2g__JournalDescription__c = po.dealer__Vendor__r.Name + ': Purchase Order ' + po.dealer__PO_Accounting_Name__c; 
        // if (po.dealer__Accepted_DateTime__c!=null) jdate = po.dealer__Accepted_DateTime__c.date(); //JVK2
        journalHeader.c2g__JournalDate__c       =   jdate;
        journalHeader.c2g__Reference__c         =   po.Name;
        journalHeader.Source__c                 =   'PUR';
        journalHeader.Purchase_Order__c         =   po.Id;
        journalHeader.Vendor__c                 =   po.dealer__Vendor__c;  // BLL3a

        // Coda Line Detail 
        List<c2g__codaJournalLineItem__c> jLines = new List<c2g__codaJournalLineItem__c>();
        
        // Set Required Balance
        Decimal balance = 0;

        // Get related account numbers
        Map<String, c2g__codaGeneralLedgerAccount__c> gl_accounts = new Map<String, c2g__codaGeneralLedgerAccount__c>();
        Set<String> rc = new Set<String>{'1220','2115','2100','4905','5304','4950', '1274'};
        for(c2g__codaGeneralLedgerAccount__c gl : [Select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c IN:rc limit 10]) {
            gl_accounts.put(gl.c2g__ReportingCode__c, gl);
        }       

        String controlnbr = po.dealer__PO_Accounting_Name__c;   // BLL2a
        String ronbr = controlnbr; // Default if no RO# found
        // No: Only sublets use RO#. if (po.dealer__Service_Repair_Order__c!=null) controlnbr = po.dealer__Service_Repair_Order__r.Name;    // BLL2a
        // Yes: And this is the sublet routine! -- BLL
        if (po.dealer__Service_Repair_Order__c!=null) ronbr = po.dealer__Service_Repair_Order__r.Name;  // BLL2a
        
                // Credit Unbilled Purchases
        jLines.add(new c2g__codaJournalLineItem__c(
                c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                c2g__LineNumber__c=1,
                //BLL4d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                c2g__LineDescription__c=po.dealer__Vendor__r.Name + ': ' + po.dealer__PO_Accounting_Name__c, // BLL4a
                c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('2115').Id,
                // BLL29 
				//c2g__Value__c=FFAccounting.credit(po.dealer__PO_Amount__c),
				c2g__Value__c=-po.dealer__PO_Amount__c,
				// BLL29 end
                c2g__LineType__c='General Ledger Account',
                Vendor_Name__c=po.dealer__Vendor__c,    // BLL4a
                Control__c=controlnbr   // BLL2a
            )
        );

        // Debit Sublet Pre-Paid
        jLines.add(new c2g__codaJournalLineItem__c(
                c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                c2g__LineNumber__c=2,
                //BLL4d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                c2g__LineDescription__c=po.dealer__Vendor__r.Name + ': ' + po.dealer__PO_Accounting_Name__c, // BLL4a
                c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('1274').Id,
                // BLL29
				//c2g__Value__c=FFAccounting.debit(po.dealer__PO_Amount__c),
				c2g__Value__c=po.dealer__PO_Amount__c,
				// BLL29 end
                c2g__LineType__c='General Ledger Account', 
                Vendor_Name__c=po.dealer__Vendor__c,    // BLL4a
                //BLL5d Control__c=controlnbr   // BLL2a
                Control__c=ronbr    // BLL5a 
            )
        );  

        //BLL24d SavePoint sp = Database.setSavePoint();

        // Process Journal Lines
        try {

             journalId = FinancialForce_MBW.createJournalApi(journalHeader, jLines);
             FFAccounting.postJournal(journalId);
             FFAccounting.applyJournalToRegister(po.Id, journalId);

        } Catch(DmlException e) {
            //BLL24d Database.rollback(sp);
            throw new FFAccountingException('Unable to create the journal lines '+e.getMessage());
        }       
    }

    /**
    *   Get Dealership Location Record
    *       - JVK2 updated to include Company__r.Company__r.MainCompanyDimension1__c
    */
    public static dealer__Dealer_Location__c getDealerLocation(Id locationId) {
        return [Select Id, Name, Company__c, dealer__Company_Number__c, Company__r.MainCompanyDimension1__c, Financial_Force_Dimension_1__c, Internal_Labor_Rate__c, Sales_Tax_Account__c from dealer__Dealer_Location__c where Id=:locationId limit 1];
    }   

    /**
     * get the current accounting period, prevent posting to any period but the period that is now
     * 
     */
    public static Id getCurrentPeriod(Id ownerCompanyId) {
        return [SELECT Id FROM c2g__codaPeriod__c 
                    where c2g__OwnerCompany__c=:ownerCompanyId 
                        and c2g__StartDate__c = THIS_MONTH 
                        and c2g__Closed__c = false limit 1].Id;
    }
    
    /**
    *   Get the Financial Force Company ID
    *
    */
    public static Id getFFCompany(Id compid) {

        dealer__Dealer_Location__c[] loc = [Select Id, Company__c, Company__r.Name from dealer__Dealer_Location__c where Id =:compid limit 1];         

        if(loc.size() == 0) throw new FFAccountingException('Location does not have an accounting company set.');

        //BLL1d 
        // Currently selected company
        //List<ID> groupIds = new List<ID>();
        //for(GroupMember member : [select GroupId from GroupMember where Group.Type = 'Queue' and UserOrGroupId = :UserInfo.getUserId()]) {
        //    groupIds.add(member.GroupId);               
        //} 
        //c2g__codaCompany__c[] companies = 
        //    [select RecordType.Name, Id, Name, c2g__TaxCode__c, c2g__CODABaseDate1__c, c2g__CODADaysOffset1__c from c2g__codaCompany__c where OwnerId in :groupIds];
        // Ensure the user has a single current company
        //if (!Test.isRunningTest()){ 
        //if (companies.size() == 0)
        //    throw new FFAccountingException('Current company has not been set for this user');
        //      
        //if (companies.size() > 1)
        //    throw new FFAccountingException('This operation is not valid in multiple company mode'); 
        //if (companies[0].Id!=loc[0].Company__c) 
        //    throw new FFAccountingException('Your current company is ' + companies[0].Name + '. '
        //          + 'Please select the transaction company ' + loc[0].Company__r.Name + '.');
        //}
        //BLL1d 
        return loc[0].Company__c;
    }

    /**
    *   Get the Financial Force Currency ID
    *
    */
    public static Id currency(Id companyId) {

        System.debug(companyId);

        c2g__codaAccountingCurrency__c[] currencyRecord = [Select Id from c2g__codaAccountingCurrency__c where c2g__OwnerCompany__c =:companyId limit 1];
        if(currencyRecord.size()==0) throw new FFAccountingException('Error: No Accounting Currency Selected');

        return currencyRecord[0].Id;
    }

    /**
    *   Enumeration of the objects supported
    *
    */
    public Enum supportedObject { PURCHASE_ORDER, REPAIR_ORDER, PARTS_INVOICE, DEAL}

    /**
    *   Get the 3 Character Object Key
    *
    */
    public static String objectType(Id recordId) {
        String objectName = '';
        try{
            //Get prefix from record ID
            //This assumes that you have passed at least 3 characters
            String myIdPrefix = String.valueOf(recordId).substring(0,3);
             
            //Get schema information
            Map<String, Schema.SObjectType> gd =  Schema.getGlobalDescribe(); 
             
            //Loop through all the sObject types returned by Schema
            for(Schema.SObjectType stype : gd.values()){
                Schema.DescribeSObjectResult r = stype.getDescribe();
                String prefix = r.getKeyPrefix();
                System.debug('Prefix is ' + prefix);
                 
                //Check if the prefix matches with requested prefix
                if(prefix!=null && prefix.equals(myIdPrefix)){
                    objectName = r.getName();
                    System.debug('Object Name! ' + objectName);
                    break;
                }
            }
        } catch(Exception e){
            System.debug(e);
        }
        return objectName;      
    }


    /**
    *   Create the Journal and Return an ID
    *
    */
    public static Id createJournal(Id dtcompanyId, String journalDescription, String reference, String control, String journal, Date transactionDate) {

        // JVK - I beleive this method to be deprecated.  Can not find any reference

        /* Modified to use Bryan Leamans FinancialForce_MBW API - 12.2015 */
        /* Based on an 
         showing example Structure 
            "
                Sample code to create a journal & line this way:
                 
                List<c2g__codaCompany__c> authCmps = [
                Select Id, Name, OwnerId from c2g__codaCompany__c where Name like 'Mobility%'
                ];
                c2g__codaJournal__c j = new c2g__codaJournal__c();
                j.c2g__OwnerCompany__c = authCmps[0].Id;
                j.c2g__JournalDate__c = Date.today();
                j.c2g__Reference__c = 'Test ref';
                j.c2g__JournalDescription__c = 'Test description';
                c2g__codaAccountingCurrency__c curr = [
                select Id from c2g__codaAccountingCurrency__c where c2g__OwnerCompany__c=:j.c2g__OwnerCompany__c limit 1
                ];
                j.c2g__JournalCurrency__c = curr.Id;
                j.Source__c = 'TST';  // test a custom field
                               
                List<c2g__codaGeneralLedgerAccount__c> gla = [select Id from c2g__codaGeneralLedgerAccount__c limit 5];
                List<c2g__codaDimension1__c> dim1 = [select Id from c2g__codaDimension1__c limit 5];
                 
                List<c2g__codaJournalLineItem__c> lines = new List<c2g__codaJournalLineItem__c>();
                lines.add(new c2g__codaJournalLineItem__c());
                lines[0].c2g__LineType__c = 'General Ledger Account';
                lines[0].c2g__GeneralLedgerAccount__c = gla[0].Id;
                lines[0].c2g__Dimension1__c = dim1[0].Id;
                lines[0].c2g__Value__c = 1.00;
                lines[0].Control__c = 'test control'; // Test a custom field
                Id rsltid = FinancialForce_MBW.createJournalApi(j, lines);
                 
                System.debug(rsltid);

        

        try {

            Id comp = FFAccounting.getFFCompany(dtcompanyId);
            Id cur = FFAccounting.currency(comp); 

            // Build the Journal
            c2g__codaJournal__c tJrnl       =   new c2g__codaJournal__c();
            tJrnl.c2g__OwnerCompany__c      =   comp;
            tJrnl.c2g__JournalCurrency__c   =   cur;
            tJrnl.c2g__JournalDescription__c =  journalDescription;
            tJrnl.c2g__Reference__c         =   reference;
            tJrnl.Source__c = journal;  // Should be PUR for purchase orders

            //tJrnl.Purchase_Order__c = po.Id;  // BLL1a
            // tJrnl.Vendor__c = po.dealer__Vendor__c;  // BLL1a

            Date jdate = Date.today();
            if (transactionDate!=null) jdate = transactionDate;

            c2g__codaPeriod__c period = [
                select Id, c2g__StartDate__c, c2g__EndDate__c, c2g__AP__c, c2g__Closed__c 
                from c2g__codaPeriod__c
                where c2g__OwnerCompany__c=:comp and c2g__EndDate__c>:jdate
                  and c2g__Closed__c!=true and c2g__AP__c!=true
                order by c2g__StartDate__c
                limit 1
            ];

            // If the period starts after the transaction date (posting next month), force current period & chg date
            if (period.c2g__StartDate__c > jdate) {
                tJrnl.c2g__Period__c = period.Id;
                tJrnl.ffgl__DerivePeriod__c = false;
                tJrnl.c2g__JournalDate__c = period.c2g__StartDate__c;
            } else {  // Otherwise, let FF determine period
                tJrnl.c2g__JournalDate__c = jdate;
                tJrnl.ffgl__DerivePeriod__c = true;         
            }



            Id newJournal = FinancialForce_MBW.createJournalApi(tJrnl, new List<c2g__codaJournalLineItem__c>());
            return newJournal;

        } catch(DmlException e) {
             throw new FFAccountingException('Failed to create Journal '+e);
        } catch(SObjectException e) {
            throw new FFAccountingException('Failed to create Journal '+e);
        } catch(Exception e) {
            throw new FFAccountingException('Failed to create Journal '+e);
        }

        */

        return null;
    }    


    /**
     * postJournal - Post the journal to the general ledger
     */
    public static void postJournal(Id journalId) {

        //BLL24d try {
			c2g__codaJournal__c j = [select Id, c2g__OwnerCompany__r.Name from c2g__codaJournal__c where Id=:journalId];	// BLL17a
            // Process Journal and post transaction
            c2g.CODAAPICommon_10_0.Context context = new c2g.CODAAPICommon_10_0.Context();
            context.CompanyName = j.c2g__OwnerCompany__r.Name;	// BLL17a
            c2g.CODAAPICommon.Reference journalRef = c2g.CODAApiCommon.getRef(journalId, null);
            c2g.CODAAPIJournal_12_0.PostJournal(context, journalRef);

        //BLL24d } Catch(Exception e) {
        //BLL24d     throw new FFAccountingException(e.getMessage());
        //BLL24d }
    }

	// BLL24
    /**
     * postCashEntry - Post a cash entry to the general ledger
     */
    public static void postCashEntry(Id cashentryId) {
		c2g__codaCashEntry__c ce = new c2g__codaCashEntry__c(Id=cashentryId);
		//try {
			c2g__codaCashEntry__c c = [select Id, c2g__OwnerCompany__r.Name from c2g__codaCashEntry__c where Id=:cashentryId];	
            // Post transaction
            c2g.CODAAPICommon_7_0.Context context = new c2g.CODAAPICommon_7_0.Context();
            context.CompanyName = c.c2g__OwnerCompany__r.Name;	// BLL17a
			System.debug(context);
            c2g.CODAAPICommon.Reference cashentryRef = c2g.CODAApiCommon.getRef(cashentryId, null);
			//c2g.CODAAPICashEntryTypes_7_0.CashEntry getce = c2g.CODAAPICashEntry_7_0.GetCashEntry(context, cashentryRef);
			//System.debug(getce);
            c2g.CODAAPICashEntry_7_0.PostCashEntry(context, cashentryRef);
			System.debug(cashentryRef);
			//ce.AutomatedPostSts__c = 'Posted';
		//} catch(Exception e) {
		//	ce.AutomatedPostSts__c = e.getMessage() + '\n' + e.getStackTraceString();
		//}
		//update(ce);
    }
	// BLL24 end

    /**
    *   Create the Purchase Invoice and return the Purchase Invoice Record
    *
    */
    public static c2g__codaPurchaseInvoice__c createPayableInvoice(Id companyId, Id dimm1Id, Id vendorId, Date invoiceDate, String invoiceDescription, String invoiceNumber) {

        try {


            Id company_id = getFFCompany(companyId);
            // BLL7a
            Id apdim1Id = dimm1Id;
            c2g__codaCompany__c comp = [select Id, DefaultPayableDimension1__c from c2g__codaCompany__c where Id=:company_id limit 1];
            if (comp!=null && comp.DefaultPayableDimension1__c!=null) apdim1Id = comp.DefaultPayableDimension1__c;
            // BLL7a

            c2g__codaPurchaseInvoice__c p = new c2g__codaPurchaseInvoice__c();
            p.c2g__Account__c       =   vendorId;
            p.c2g__OwnerCompany__c  =   company_id;
            //BLL7d p.c2g__Dimension1__c    =   dimm1Id;
            p.c2g__Dimension1__c = apdim1Id;    // BLL7a
            p.ffap__DeriveDueDate__c=   true;
            p.ffap__DerivePeriod__c =   true;
            p.c2g__InvoiceDate__c   =   invoiceDate;
            p.c2g__InvoiceCurrency__c   =   FFAccounting.currency(company_id);
            p.c2g__InvoiceDescription__c=   invoiceDescription;
            p.c2g__AccountInvoiceNumber__c= invoiceNumber;
            p.c2g__InvoiceStatus__c = 'In Progress';
            p.ffap__CopyAccountValues__c = false;    //  JVK1   // BLL4c
            p.c2g__CopyAccountValues__c = false;     //  JVK1   // BLL4c

            System.debug(p);

            return p;

        } catch(DmlException e) {
            throw new FFAccountingException('Error Creating Payable Invoice from Purchase Order '+e.getMessage());
        }

        // return null;
    }

    /**
    *   Create the Payable Invoice Lines 
    *
    */
    public static List<c2g__codaPurchaseInvoiceExpenseLineItem__c> createPayableInvoiceLines(Id payableIncoiceId, Id dim1, List<dealer__Purchase_Order_Line__c> lines) {            

        // BLL5a
        String controlnbr = '';
        String ponbr = '';	// BLL12a
        if (lines.size()>0) {
            Id lineid = lines[0].Id;
            dealer__Purchase_Order_Line__c pol = [select Id, dealer__Purchase_Order__c from dealer__Purchase_Order_Line__c where Id=:lineid limit 1];
            Id poid = pol.dealer__Purchase_Order__c;
            dealer__Purchase_Order__c po = [select Id, dealer__StockNumber__c, dealer__PO_Accounting_Name__c from dealer__Purchase_Order__c where Id=:poid limit 1];
            ponbr = po.dealer__PO_Accounting_Name__c;	// BLL12a
            // use PO number or stock number, not just stock number
            if (!String.isBlank(po.dealer__StockNumber__c)) controlnbr = po.dealer__StockNumber__c;
            else controlnbr = po.dealer__PO_Accounting_Name__c;
            //controlnbr = po.dealer__PO_Accounting_Name__c;	// BLL10a
        }
        // BLL5a end

		// BLL12a
		Map<Id,c2g__codaGeneralLedgerAccount__c> po_ctrl = new Map<Id,c2g__codaGeneralLedgerAccount__c>([
			select Id, c2g__ReportingCode__c, Name
			from c2g__codaGeneralLedgerAccount__c
			where c2g__ReportingCode__c in ('2115')
		]);
		// BLL12a end

        // Iterate TLines for the Expense Lines to be placed on a Purchase Order

        List<c2g__codaPurchaseInvoiceExpenseLineItem__c> pl = new List<c2g__codaPurchaseInvoiceExpenseLineItem__c>();
        for(dealer__Purchase_Order_Line__c j : lines) {

            pl.add(new c2g__codaPurchaseInvoiceExpenseLineItem__c(
                    c2g__PurchaseInvoice__c=payableIncoiceId,
                    c2g__NetValue__c=j.dealer__Amount__c,
                    c2g__LineDescription__c=j.dealer__Description__c,
                    c2g__Dimension1__c=j.Dimension_1__c,
                    ffap__SetGLAToDefault__c=false,
                    Control__c = po_ctrl.containsKey(j.General_Ledger_Account__c) ? ponbr : controlnbr, // BLL5a, BLL12c
                    c2g__GeneralLedgerAccount__c=j.General_Ledger_Account__c
                )
            );
        }

        return pl;
    }

    /**
    *   Update Vehicle Costs based on Purchase Order Lines
    *
    */
    public static dealer__Vehicle_Inventory__c addsToCost(Id poId, List<dealer__Purchase_Order_Line__c> lines) {

        dealer__Purchase_Order__c po = [Select Id, dealer__Vehicle_Inventory__c from dealer__Purchase_Order__c where Id=:poId limit 1];
        if(po.dealer__Vehicle_Inventory__c==null) throw new FFAccountingException('Unable to update vehicle adds to cost when a vehicle is not present on the purchase order.');
        
        dealer__Vehicle_Inventory__c veh = [Select Id, dealer__Vehicle_Cost__c, Conversion_Cost__c from dealer__Vehicle_Inventory__c where Id=:po.dealer__Vehicle_Inventory__c limit 1];

        Decimal chassisCost     = 0;
        Decimal conversionCost  = 0;

        for (dealer__Purchase_Order_Line__c ln : lines) {              
                    
                    if(ln.Add_to_Chassis__c==true && ln.dealer__Amount__c!=null) {
                        chassisCost += ln.dealer__Amount__c;
                    }
                    if(ln.Add_to_Conversion__c==true && ln.dealer__Amount__c!=null){
                        conversionCost += ln.dealer__Amount__c;
                    }                    
        }

        if(veh.dealer__Vehicle_Cost__c == null) { veh.dealer__Vehicle_Cost__c=0; }
        if(veh.Conversion_Cost__c == null) { veh.Conversion_Cost__c=0; }

        veh.dealer__Vehicle_Cost__c +=  chassisCost;
        veh.Conversion_Cost__c      +=  conversionCost;

        return veh;
    }

    /**
     * credit - method to set value as a valid credit
     * @param  d [description]
     * @return   [description]
     */
    public static Decimal credit(Decimal d) {
    	Decimal rtn = d;
        if(d==null) rtn = 0;
        else if(d>0) rtn = d*-1;
        return rtn;
    }

    /**
     * debit - method to set the value as a valid debit
     * @param  d [description]
     * @return   [description]
     */
    public static Decimal debit(Decimal d) {
    	Decimal rtn = d;
        if(d==null) rtn = 0;
        else if(d<0) rtn = d*-1;
        return rtn;
    }   

    /**
     * applyJournalToRegister - Set the Journal ID in the regsiter based on ID
     */
    public static void applyJournalToRegister(Id recordId, Id journalId) {
        InvoiceRegister__c r = new InvoiceRegister__c(RecordId__c=recordId, Journal__c=journalId);
        try {
            upsert r RecordId__c;
        } catch(DmlException e) {
            // FFAccountingException('Error applying journal to register '+e.getMessage());
        }       
    }

    /**
     * applyTransactionToRegister - Set the Journal ID in the regsiter based on ID
     */
    public static void applyTransactionToRegister(Id recordId, Id journalId) {
        
        Id transactionId = [SELECT c2g__Transaction__c from c2g__codaJournal__c where Id=:journalId limit 1].Id;
        
        if(transactionId==null) {
            // FFAccountingException('Error, Transaction not present on the Journal '); 
        }

        //BLL11d InvoiceRegister__c r = new InvoiceRegister__c(RecordId__c=recordId, Transaction__c=transactionId);
        try {
	        InvoiceRegister__c r = new InvoiceRegister__c(RecordId__c=recordId, Transaction__c=transactionId);	// BLL11a
            upsert r RecordId__c;
        } catch(DmlException e) {
            // FFAccountingException('Error applying journal to register '+e.getMessage());
        }       
    }    

        

    /**
     * emailAsyncHandler - create and email and deliver to Async Handler
     */
    public static void emailAsyncHandler(String payload) {
	// BLL24
		deliverAsyncPayload('Email', payload);
	}
	public static void deliverAsyncPayload(String DeliveryMethod, String payload) {
		Exception emailException;
	// BLL24 end

        // BLL9a
        //Organization org = [select Id, Name from Organization limit 1];
		Organization org = OrganizationSingleton.getInstance();
        // BLL9a end

		if (DeliveryMethod=='Email') {
	        // Derive Email Handle from Org Configuation
    	    String emailHandle ='';
        	//BLL24d if(!Test.isRunningTest()) {
			// BLL26
	        //ApexClass apexClass= [SELECT Id, Name FROM ApexClass where Name = 'AccountingEmailService' and NamespacePrefix = null limit 1];
	        //EmailServicesFunction emailServicesFunction = [SELECT Id, FunctionName, IsActive, ApexClassId, ErrorRoutingAddress FROM EmailServicesFunction where ApexClassId=:apexClass.Id limit 1]; 
	        //EmailServicesAddress emailServicesAddress = [SELECT LocalPart, EmailDomainName, Id, RunAsUserId, FunctionId FROM EmailServicesAddress where FunctionId=:emailServicesFunction.Id limit 1];
			EmailServicesAddress emailServicesAddress = FFAccounting.getFFAEmailServiceAddress();
			// BLL26

          	System.debug(emailServicesAddress);

	        emailHandle = emailServicesAddress.LocalPart+'@'+emailServicesAddress.EmailDomainName;
	        //BLL24d } else {
	        //BLL24d   emailHandle = 'fake@blackhole.org';
	        //BLL24d }

	        System.debug(emailHandle);

	        Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
	        String[] toAddresses = new String[] {emailHandle};
	        mail.setToAddresses(toAddresses); 
	        mail.setSubject('Asyncnronous Processing Request');
	        mail.setPlainTextBody(payload);
	        mail.setTargetObjectId(UserInfo.getUserId());
	        mail.setTreatTargetObjectAsRecipient(false);
	
	        try {
	            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	        } catch(Exception e) {
			// BLL24
				DeliveryMethod = 'Batch';
				emailException = e;
			}
		}

		if (DeliveryMethod=='Batch') {
		// BLL24 end
            // BLL9a - log error to object for later reprocessing
            FFAccountingFailure__c ffaf = new FFAccountingFailure__c(
                Payload__c = payload, SourceOrganizationName__c=org.Name, SourceOrganizationId__c=org.Id
            );
            String errmsg = emailException!=null ? emailException.getMessage() : '';
            if (errmsg!=null && errmsg.length()>128) errmsg = errmsg.substring(0,128);
            ffaf.ErrorMessage__c = errmsg;
            try {
                AccountingEmailService.AccountingPayload a = (AccountingEmailService.AccountingPayload)JSON.deserializeStrict(payload, AccountingEmailService.AccountingPayload.class);
                ffaf.SourceObjectId__c = a.recordId;
                ffaf.Action__c = a.action;
                if (!String.isBlank(ffaf.SourceObjectId__c)) ffaf.SourceObjectType__c = String.valueOf(((Id) ffaf.SourceObjectId__c).getSObjectType());
            } catch(Exception e2) {}
            insert(ffaf);
            // BLL9a end
        } 
    }

    public static void emailAsyncHandler(List <String> payloadList) {
		deliverAsyncPayloads('Email', payloadList);
	}
	// BLL24
    public static void deliverAsyncPayloads(String DeliveryMethod, List <String> payloadList) {
		Exception emailException;
	// BLL24 end
        // BLL9a
        Organization org = [select Id, Name from Organization limit 1];
        // BLL9a end

		if (DeliveryMethod=='Email') {
	        // Derive Email Handle from Org Configuation
	        String emailHandle ='';
	        //BLL24d if(!Test.isRunningTest()) {
			// BLL26
	        //ApexClass apexClass= [SELECT Id, Name FROM ApexClass where Name = 'AccountingEmailService' and NamespacePrefix = null limit 1];
	        //EmailServicesFunction emailServicesFunction = [SELECT Id, FunctionName, IsActive, ApexClassId, ErrorRoutingAddress FROM EmailServicesFunction where ApexClassId=:apexClass.Id limit 1]; 
	        //EmailServicesAddress emailServicesAddress = [SELECT LocalPart, EmailDomainName, Id, RunAsUserId, FunctionId FROM EmailServicesAddress where FunctionId=:emailServicesFunction.Id limit 1];
			EmailServicesAddress emailServicesAddress = FFAccounting.getFFAEmailServiceAddress();
			// BLL26

	        System.debug(emailServicesAddress);

	        emailHandle = emailServicesAddress.LocalPart+'@'+emailServicesAddress.EmailDomainName;
	        //BLL24d } else {
	        //BLL24d   emailHandle = 'fake@blackhole.org';
	        //BLL24d }

	        System.debug(emailHandle);
	
	        List <Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
	        //TESTING INDIVIDUAL EMAILS
	        for(String item : payloadList){
	            Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
	            String[] toAddresses = new String[] {emailHandle};
	            mail.setToAddresses(toAddresses);
	            mail.setSubject('Asyncnronous Processing Request - Depreciation');
	            mail.setPlainTextBody(item);
	            emailList.add(mail);
	        }
	        try {
	            Messaging.sendEmail(emailList);
	        } catch(Exception e) {
			// BLL24
				emailException = e;
				DeliveryMethod = 'Batch';
        	    System.Debug('Error handling email: test');
    	        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Error Message:' + e);
	            ApexPages.addMessage(myMsg); 
			}
		}

		if (DeliveryMethod=='Batch') {
		// BLL24 end
            // BLL9a - log error to object for later reprocessing
            List<FFAccountingFailure__c> ffafs = new List<FFAccountingFailure__c>();
            for(String payload : payloadlist) {
                FFAccountingFailure__c ffaf = new FFAccountingFailure__c(
                    Payload__c = payload, SourceOrganizationName__c=org.Name, SourceOrganizationId__c=org.Id
                );
                String errmsg = emailException!=null ? emailException.getMessage() : '';
                if (errmsg!=null && errmsg.length()>128) errmsg = errmsg.substring(0,128);
                ffaf.ErrorMessage__c = errmsg;
                try {
                    AccountingEmailService.AccountingPayload a = (AccountingEmailService.AccountingPayload)JSON.deserializeStrict(payload, AccountingEmailService.AccountingPayload.class);
                    ffaf.SourceObjectId__c = a.recordId;
                    ffaf.Action__c = a.action;
                    if (!String.isBlank(ffaf.SourceObjectId__c)) ffaf.SourceObjectType__c = String.valueOf(((Id) ffaf.SourceObjectId__c).getSObjectType());
                } catch(Exception e2) {}
                ffafs.add(ffaf);
            }
            insert(ffafs);
            // BLL9a end
        } 
    }

	// BLL26
	public static EmailServicesAddress getFFAEmailServiceAddress() {
		if (ffaEmailAddress==null) {
        	ApexClass apexClass= [SELECT Id, Name FROM ApexClass where Name = 'AccountingEmailService' and NamespacePrefix = null limit 1];
        	EmailServicesFunction emailServicesFunction = [SELECT Id, FunctionName, IsActive, ApexClassId, ErrorRoutingAddress FROM EmailServicesFunction where ApexClassId=:apexClass.Id limit 1]; 
        	ffaEmailAddress = [SELECT LocalPart, EmailDomainName, Id, RunAsUserId, FunctionId FROM EmailServicesAddress where FunctionId=:emailServicesFunction.Id limit 1];
		}
		return ffaEmailAddress;
	}
	// BLL26 end

    //RT1
    public static void acceptVehiclePurchaseOrder(String recordId) {
        dealer__Purchase_Order__c po;
        dealer__Dealer_Location__c loc;
        Decimal chassisCost;
        Decimal conversionCost;
        //BLL8d User u = [Select Id, Division, Name from User where Id=:UserInfo.getUserId() limit 1];
        User u = CurrentUserSingleton.getInstance();    // BLL8a
        List<dealer__Purchase_Order__c> pos = [Select Id, Name, dealer__Company__c, dealer__StockNumber__c,dealer__Accepted_DateTime__c, dealer__Vehicle_Inventory__c,
                                                      dealer__Accepted_By__c, dealer__Company__r.Name, dealer__Invoice_Amount__c, dealer__Vendor__c, dealer__Freight__c, dealer__Invoice_Date__c, dealer__Invoice_Number__c,
                                                      Payable_Invoice__c, Payable_Invoice__r.Name, dealer__Vendor__r.Name, dealer__PO_Accounting_Name__c    // BLL4c, BLL6c (PO_Accounting_Name)  
														, dealer__Status__c // BLL25a
                                                      from dealer__Purchase_Order__c 
                                                      where Id=:recordId limit 1];
        if(pos.size()>0){
            po = pos[0];
        }

		// BLL25 - prevent double-acceptance of PO
		System.debug(po);
        if (po.dealer__Accepted_DateTime__c!=null && po.dealer__Accepted_By__c!=null && po.dealer__Status__c=='Accepted') {
           throw new FFAccountingException('PO ' + po.dealer__PO_Accounting_Name__c + ' has already been accepted. Cannot accept it again.');
		}
		// BLL25 end

        List<dealer__Dealer_Location__c> locQuery     = [Select Id, Name, Financial_Force_Dimension_1__c, Financial_Force_Dimension_1__r.Name, Company__c, Internal_Labor_Rate__c, Sales_Tax_Account__c 
                                                                from dealer__Dealer_Location__c 
                                                                where Id=:po.dealer__Company__c limit 1];
       if(locQuery.size()>0) {
           loc = locQuery[0]; 
       } else {
           throw new FFAccountingException('User has no dealer__Dealer_Location__c set');
       }

        // BLL6a - Account 2115 needs to use PO Accounting Name as the control#
        Map<Id, c2g__codaGeneralLedgerAccount__c> GLsWithPOctl = new Map<Id,c2g__codaGeneralLedgerAccount__c>([
            select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c in ('2115')
        ]);
        // BLL6a

        dealer__Vehicle_Inventory__c vehicleInv = createVehicle(po, chassisCost, conversionCost);
        
        if (vehicleInv != null){
             if(loc.Company__c==null) throw new FFAccountingException('Dealership Location does not have the Financial Force Company Set.');
            
            Id compId = getFFCompanyId(loc.Company__c);
            
            // Get Accounting Currency
            c2g__codaAccountingCurrency__c[] curl = [Select Id from c2g__codaAccountingCurrency__c where c2g__OwnerCompany__c =:compId limit 1];
            if(curl.size()==0) throw new FFAccountingException('Error : The Company Selected does not have an active currency set');
            c2g__codaAccountingCurrency__c cur = curl[0];
            // Get Period Data
            //BLL19c Get the correct record for *this company* *AND* get the open period, not a FUTURE open period!
            //BLL19d c2g__codaPeriod__c[] periodl =  [Select Id from c2g__codaPeriod__c where c2g__StartDate__c >=:Date.today() and c2g__Closed__c=false limit 1];
            // BLL19
            List<c2g__codaPeriod__c> periodl = [
            	Select Id 
            	from c2g__codaPeriod__c 
            	where c2g__OwnerCompany__c =:compId and c2g__Closed__c=false
            		and c2g__StartDate__c <=:Date.today() and c2g__EndDate__c >=:Date.today() 
            	limit 1
            ];
            // BLL19a end
            if(periodl.size()==0) throw new FFAccountingException('Error : Current Accounting Period not Open');
            c2g__codaPeriod__c period = periodl[0];
            // Add Error if Period is not open does not exist
            
            System.debug('Prep Create Journal');
            
            // Build the Journal
            c2g__codaJournal__c tJrnl       =     new c2g__codaJournal__c();
            tJrnl.c2g__OwnerCompany__c      =     compId;
            tJrnl.c2g__JournalCurrency__c   =     cur.Id;
            //BLL4d tJrnl.c2g__JournalDescription__c=     'Vehicle PO created by ' + u.Name; //????
            tJrnl.c2g__JournalDescription__c=     po.dealer__Vendor__r.Name + ': Vehicle PO created by ' + u.Name; // BLL4a
            tJrnl.c2g__JournalDate__c       =     Date.today();
            tJrnl.c2g__Reference__c         =     po.Name;
            tJrnl.c2g__Period__c            =     period.Id;
            tJrnl.Source__c                         =     'PUR';  //?????
            tJrnl.Stock_Number__c               =       po.dealer__StockNumber__c;
            tJrnl.Purchase_Order__c             =       po.Id;
            
            System.debug(tJrnl);
            
              
            List<dealer__Purchase_Order_Line__c> allPoLines = [Select Id, dealer__Account__c, General_Ledger_Account__c, dealer__Description__c, 
                                                               dealer__Amount__c, Add_to_Chassis__c, Add_to_Conversion__c, Dimension_1__c
                                                               from dealer__Purchase_Order_Line__c 
                                                               where dealer__Purchase_Order__c =:po.Id limit 2000];
            
            
            
            List<c2g__codaJournalLineItem__c> allJournalLines = new List<c2g__codaJournalLineItem__c>();
            
            if(allPoLines.size()>0) {
                chassisCost = 0;
                conversionCost = 0;         
                for (dealer__Purchase_Order_Line__c ln : allPoLines) {   
                    String controlnbr = GLsWithPOctl.containsKey(ln.General_Ledger_Account__c) ? po.dealer__PO_Accounting_Name__c : po.dealer__StockNumber__c;  // BLL6a
                    Id locId = (ln.Dimension_1__c!=null) ? ln.Dimension_1__c : loc.Financial_Force_Dimension_1__c;                     
                    c2g__codaJournalLineItem__c theLine = journalEntry( null, 
                                                                       locId, 
                                                                       ln.General_Ledger_Account__c, 
                                                                       'General Ledger Account', 
                                                                       ln.dealer__Description__c, ln.dealer__Amount__c,
                                                                       po.dealer__Vehicle_Inventory__c, 
                                                                       po,
                                                                       controlnbr   // BLL6a 
                                                                      );  
                    
                    if(ln.Add_to_Chassis__c==true) {
                        chassisCost += ln.dealer__Amount__c;
                    }
                    if(ln.Add_to_Conversion__c==true){
                        conversionCost += ln.dealer__Amount__c;
                    }
                    
                    allJournalLines.add(theLine);                    
                }
                
                //BLL25d try {
                    Id journalId = FinancialForce_MBW.createJournalApi(tJrnl, allJournalLines);
                    FFAccounting.postJournal(journalId);
                    FFAccounting.applyJournalToRegister(po.Id, journalId);
                    po.dealer__Accepted_DateTime__c = Date.today();
                    po.dealer__Accepted_By__c = UserInfo.getUserId();   
                    po.dealer__Status__c = 'Accepted';
                    
                    // Update the vehicle inventory record

                    // If the vehicle did not get created, and this is an update to an existing control#, set the Vehicle
                    if(vehicleInv == null) {
                      
                      vehicleInv = getVehicleInv(po);

                      if(vehicleInv.Id == null) {
                        throw new FFAccountingException('Unable to Accept PO, Vehicle Record does not exist.');
                      }
                    }
                    
                    //RT2
                    if(vehicleInv.dealer__Vehicle_Cost__c != null) chassisCost += vehicleInv.dealer__Vehicle_Cost__c;
                    if(vehicleInv.Conversion_Cost__c != null) conversionCost += vehicleInv.Conversion_Cost__c;
                    //end RT2
                    
                    update new dealer__Vehicle_Inventory__c(Id=vehicleInv.Id, dealer__Vehicle_Cost__c=chassisCost, Conversion_Cost__c=conversionCost);
                    update po;
					System.debug(po);
                //BLL25d }
                //BLL25d catch(Exception e) {}
            }
		// BLL25 - reset PO accepted date since this didn't run
        } else {
			if (po.dealer__Accepted_By__c==null) update(new dealer__Purchase_Order__c(Id=po.Id, dealer__Accepted_DateTime__c=null));
		// BLL25 end
		}
    }

    //RT1
    public static dealer__Vehicle_Inventory__c createVehicle(dealer__Purchase_Order__c po, Decimal chassisCost, Decimal conversionCost) {
		// BLL24
		dealer__Vehicle_Inventory__c rtnVeh = null;
		// BLL24 end
        List<dealer__Purchase_Order__c> poVehicle = [SELECT Name, dealer__Make__c, dealer__Model__c, dealer__StockNumber__c, dealer__Company__c,   
                                                     dealer__VIN__c, dealer__Year__c, dealer__Vehicle_Inventory__c, dealer__Vehicle_Status__c
                                                     FROM dealer__Purchase_Order__c WHERE Id=:po.Id limit 1];
        System.debug(poVehicle);
        if(poVehicle[0].dealer__Vehicle_Inventory__c!=null) {
            //RT2 - added cost + conversion
			// BLL24
        	//return [Select Id, Name, dealer__Year__c, dealer__Make__c, dealer__Model__c, dealer__VIN__c, dealer__Status_Code__c, dealer__Vehicle_Cost__c, Conversion_Cost__c from dealer__Vehicle_Inventory__c where Id=:poVehicle[0].dealer__Vehicle_Inventory__c limit 1];
			rtnVeh = [Select Id, Name, dealer__Year__c, dealer__Make__c, dealer__Model__c, dealer__VIN__c, dealer__Status_Code__c, dealer__Vehicle_Cost__c, Conversion_Cost__c from dealer__Vehicle_Inventory__c where Id=:poVehicle[0].dealer__Vehicle_Inventory__c limit 1];
			// BLL24 end
        }
        
        if (rtnVeh==null && (poVehicle[0].dealer__Year__c == null || poVehicle[0].dealer__Make__c == null || poVehicle[0].dealer__Model__c == null)) {
            if (ApexPages.currentPage() != null) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to Create Vehicle, Year, Make, Model are requied fields '));  // BLL6c - only do this if in a visualforce context
            //return null;
		// BLL24
		// }
        }  else  {                                                
        //JG: most of these fields are blank in the DB        
        // if (poVehicle.size()>0){
		// BLL24 end
            dealer__Purchase_Order__c pov = poVehicle[0];
            
            dealer__Vehicle_Inventory__c v = new dealer__Vehicle_Inventory__c();
            
            if (pov.dealer__Make__c == null) v.dealer__Make__c ='Unknown';
            else v.dealer__Make__c = pov.dealer__Make__c;

            if (pov.dealer__Model__c == null) v.dealer__Model__c ='Unknown';
            else v.dealer__Model__c = pov.dealer__Model__c;

            if (pov.dealer__Year__c == null) v.dealer__Year__c ='0000';
            else v.dealer__Year__c = pov.dealer__Year__c;  

            if (pov.dealer__StockNumber__c == null) v.dealer__Stock_Number__c ='0000';
            else v.dealer__Stock_Number__c = pov.dealer__StockNumber__c;  

            v.dealer__Vehicle_Cost__c = chassisCost;
            v.Conversion_Cost__c = conversionCost;
            
            if(pov.dealer__VIN__c==null || pov.dealer__VIN__c == '') v.dealer__VIN__c = pov.name;
            else v.dealer__VIN__c = pov.dealer__VIN__c;

            v.dealer__Status_Code__c = pov.dealer__Vehicle_Status__c;
            v.dealer__Store_Location__c = pov.dealer__Company__c;
            
            try {
                insert v;
                getvehicleInv(po);
				// BLL24
                // return v;
				rtnVeh = v;
            } catch(DmlException e) {
            }   
		// BLL24
        //} else {
        //    system.debug('poVehicle.size()!>0');
		// BLL24 end
        }
		// BLL24
		//return null;
		return rtnVeh;
		// BLL24 end
    }

    //RT1
    public static dealer__Vehicle_Inventory__c getvehicleInv(dealer__Purchase_Order__c po){
        //Check for existing vehicle
        List<dealer__Vehicle_Inventory__c> existingVehs = [SELECT Id, name, dealer__Stock_Number__c, dealer__Vehicle_Cost__c, Conversion_Cost__c //RT2 - added cost + conversion
                                                           FROM dealer__Vehicle_Inventory__c 
                                                           WHERE dealer__Stock_Number__c=:po.dealer__StockNumber__c limit 1];
        
        if(existingVehs.size()>0) return existingVehs[0];

        return null;                
    }

    //RT1
    public static c2g__codaJournalLineItem__c journalEntry(Id journal, Id locid, Id account, String type, String drcr, Decimal amount, Id vehicle, dealer__Purchase_Order__c po,
        String controlnbr /*bll6a*/) {
        c2g__codaJournalLineItem__c tempLine = new c2g__codaJournalLineItem__c();   
        tempLine.c2g__Journal__c                =   journal;
        tempLine.c2g__Dimension1__c             =   locid;
        tempLine.c2g__LineDescription__c        =   drcr;
        tempLine.c2g__GeneralLedgerAccount__c   =   account;
        tempLine.c2g__Value__c                  =   amount;
        tempLine.c2g__LineType__c               =   type;  //JG: Need confirmation on values here.
        tempLine.c2g__DebitCredit__c            =   amount > 0 ? 'Debit' : 'Credit';
        //BLL6d tempLine.Control__c                     =   po.dealer__StockNumber__c;
        tempLine.Control__c                     =   controlnbr; // BLL6a
        tempLine.Vehicle_Inventory__c           =   vehicle; // JVK  - Added per Jerry Augusts request on 11/11/15
        
        return tempLine;    
    }
    
    //RT1
    public static Id getFFCompanyId(String compid) {
        // Get FF Company Information
        c2g__codaCompany__c comp=null;
        if (compid!=null) {
            List<c2g__codaCompany__c> comps = [select Id, Name from c2g__codaCompany__c where Id=:compid];
            if (comps.size()>0) {
                comp = comps[0];
            } else {
                throw new FFAccountingException('Not authorized to the financial company');
            }
        } else {
            throw new FFAccountingException('Missing the financial company');
        }
        // Currently selected company
        List<ID> groupIds = new List<ID>();
        for(GroupMember member : [select GroupId from GroupMember where Group.Type = 'Queue' 
                                  and UserOrGroupId = :UserInfo.getUserId()]) {
                                      groupIds.add(member.GroupId);             
                                  } 
        
        System.debug('GROUP Ids'+groupIds);
        //BLL8d System.debug([SELECT Id, Division FROM User WHERE Id =:UserInfo.getUserId() ]);
        System.debug(CurrentUserSingleton.getInstance());   // BLL8a
        c2g__codaCompany__c[] companies = 
            [select RecordType.Name, Id, Name, c2g__TaxCode__c, c2g__CODABaseDate1__c, c2g__CODADaysOffset1__c 
             from c2g__codaCompany__c where OwnerId in :groupIds];
        // Ensure the user has a single current company
        if (companies.size() == 0) throw new FFAccountingException('Current company has not been set for this user');

        
        return comp.Id;
    }    

    public static void depreciateRental(Id companyId, String vehicleIds, String emailAddress){
        DateTime dT = System.now();
        String csvStr = 'Floorplan,Status,Vehicle,Year,Make,Model,Store Location,Vehicle Cost,Depreciation Exp,New Vehicle Cost,Insurance Start Date,Status\n';	// BLL3c add status
        //Date timestamp = date.newinstance(dT.year(), dT.month(), dT.day());
        c2g__codaJournal__c j = new c2g__codaJournal__c();
        j.c2g__JournalStatus__c = 'In Progress';
        j.c2g__Type__c = 'Manual Journal';
        j.c2g__OwnerCompany__c = companyId;
        j.c2g__JournalDate__c = date.today();
        j.c2g__Reference__c = 'Rental & Demo Depreciation';	// BLL15c
        j.c2g__JournalDescription__c = 'Rental & Demo Depreciation ' + dT.format('yyyy-MM-dd');	// BLL15c
        j.Source__c = 'GE';
        System.Debug('Company: ' + companyID);
        List<c2g__codaJournalLineItem__c> lines = new List<c2g__codaJournalLineItem__c>();
        
        String[] arrVehicleIdStrings = vehicleIds.split('\\+');
        List<Id> listVehicleIds = new List<Id>();
        for(String item : arrVehicleIdStrings){
            listVehicleIds.Add(item);
        }
        
        List<dealer__Vehicle_Inventory__c> vehicles = [SELECT Id
                , dealer__Status_Code__c
                , Name
                , dealer__Year__c
                , dealer__Make__c
                , dealer__Model__c
                , dealer__Store_Location__c
                , dealer__Store_Location__r.Name
                , Rental_Vehicle_Costs__c
                , Rental_Depreciation_Exp__c
                , Rental_New_Vehicle_Cost__c
                , Insurance_Start_Date__c
                , dealer__Store_Location__r.Company__r.Id
                , dealer__Store_Location__r.Financial_Force_Dimension_1__c
                , dealer__Stock_Number__c
                , Conversion_Cost__c
                , Chassis_Floorplan__c
                , Last_Depreciation_Date__c
            FROM dealer__Vehicle_Inventory__c
            WHERE Id IN :listVehicleIds];
        system.debug('veh ' + vehicles);
        // BLL14d
        // BLL14dId gl_1270 = [SELECT Id FROM c2g__codaGeneralLedgerAccount__c WHERE c2g__ReportingCode__c  = '1270'].Id;
        // BLL14dId gl_4855 = [SELECT Id FROM c2g__codaGeneralLedgerAccount__c WHERE c2g__ReportingCode__c  = '4855'].Id;
        // BLL14dId gl_8014 = [SELECT Id FROM c2g__codaGeneralLedgerAccount__c WHERE c2g__ReportingCode__c  = '8014'].Id;
        // BLL14dId gl_1242 = [SELECT Id FROM c2g__codaGeneralLedgerAccount__c WHERE c2g__ReportingCode__c  = '1242'].Id;
        // BLL14d end
		// BLL14a
    	Set<String> glAcctNbrs = new Set<String>{'1270','1271','1272','8014','4855'};
    	Map<String,c2g__codaGeneralLedgerAccount__c> glAcctMap = new Map<String,c2g__codaGeneralLedgerAccount__c>();
    	Map<Id,dealer__Vehicle_Inventory__c> vehMap = new Map<Id,dealer__Vehicle_Inventory__c>();	// BLL14a
        for(c2g__codaGeneralLedgerAccount__c gl : [
        	select Id, Name, c2g__ReportingCode__c 
        	from c2g__codaGeneralLedgerAccount__c 
        	where c2g__ReportingCode__c in :glAcctNbrs
        ]) glAcctMap.put(gl.c2g__ReportingCode__c,gl);
    	// BLL14a end
        
        Integer i = 0;
        for(dealer__Vehicle_Inventory__c item : vehicles){
            Id GLCode1;
            Id GLCode2;
            vehMap.put(item.Id, item);	// BLL14a
            
            if(item.dealer__Status_Code__c == 'Company Vehicle'){
                //BLL14d GLCode1 = gl_1242;
                //BLL14d GLCode2 = gl_8014;
                GLCode1 = glAcctMap.get('1271').Id;	// BLL14a
                GLCode2 = glAcctMap.get('8014').Id;	// BLL14a
            }
            else if(item.dealer__Status_Code__c!=null && item.dealer__Status_Code__c.startsWith('Demo')){	// BLL13a 
            	//BLL13d	if(item.dealer__Status_Code__c == 'Demo'){
                //BLL14d GLCode1 = gl_1270;
                //BLL14d GLCode2 = gl_8014;
                GLCode1 = glAcctMap.get('1272').Id;	// BLL14a
                GLCode2 = glAcctMap.get('8014').Id;	// BLL14a
            }
            else{
                //BLL14d GLCode1 = gl_1270;
                //BLL14d GLCode2 = gl_4855;
                GLCode1 = glAcctMap.get('1270').Id;	// BLL14a
                GLCode2 = glAcctMap.get('4855').Id;	// BLL14a
            }
            
            lines.add(new c2g__codaJournalLineItem__c());
            lines[i].c2g__LineType__c = 'General Ledger Account';
            lines[i].c2g__GeneralLedgerAccount__c = GLCode1;
            lines[i].c2g__Dimension1__c = item.dealer__Store_Location__r.Financial_Force_Dimension_1__c;
            lines[i].c2g__Value__c = 0 - item.Rental_Depreciation_Exp__c;
            lines[i].Control__c = item.dealer__Stock_Number__c;
            lines[i].Vehicle_Inventory__c = item.Id;
            lines[i].c2g__LineDescription__c = 'Rental Depreciation - ' + item.dealer__Stock_Number__c;
            i = i + 1;
            
            lines.add(new c2g__codaJournalLineItem__c());
            lines[i].c2g__LineType__c = 'General Ledger Account';
            lines[i].c2g__GeneralLedgerAccount__c = GLCode2;
            lines[i].c2g__Dimension1__c = item.dealer__Store_Location__r.Financial_Force_Dimension_1__c;
            lines[i].c2g__Value__c = item.Rental_Depreciation_Exp__c;
            lines[i].Control__c = item.dealer__Stock_Number__c;
            lines[i].Vehicle_Inventory__c = item.Id;
            lines[i].c2g__LineDescription__c = 'Rental Depreciation - ' + item.dealer__Stock_Number__c;           
            i = i + 1;
            
            item.Conversion_Cost__c = 0;
            item.dealer__Vehicle_Cost__c = item.Rental_New_Vehicle_Cost__c;
            item.Last_Depreciation_Date__c = date.today();
            
            csvStr = csvStr + item.Chassis_Floorplan__c + ',' 
                + item.dealer__Status_Code__c + ','	
                + item.Name + ',' + item.dealer__Year__c + ',' + item.dealer__Make__c + ',' + item.dealer__Model__c + ',' 
                + item.dealer__Store_Location__r.Name.replace(',','') + ',' + item.Rental_Vehicle_Costs__c + ',' + item.Rental_Depreciation_Exp__c + ',' + item.Rental_New_Vehicle_Cost__c + ',' + item.Insurance_Start_Date__c + ',Vehicle submitted for depreciation\n';
        }
        
        try{
            system.debug('journal ' + j);
            system.debug('lines ' + lines);
            
            Id journalId = FinancialForce_MBW.createJournalApi(j, lines);
        	system.debug('journalId ' + journalId);
        
            FFAccounting.postJournal(journalId);
        
        	// BLL14a
        	String errmsgs = '';
        	String updokay = '';
			Database.SaveResult[] saveresults = new List<Database.SaveResult>();
        	// BLL14a
            system.debug('vehicles upd: ' + vehicles);
            // BLL14d update vehicles;
            // BLL14a
			saveresults = Database.update(vehicles, false); 
			//System.debug(saveresults);
			System.debug('List of failed updates:');
			for(Integer n=0; n<saveresults.size(); n++) {
				Database.SaveResult sr = saveresults[n];
				dealer__Vehicle_Inventory__c v = (n<vehicles.size()) ? vehicles[n] : null;
				String vehName = v!=null ? v.Name : '';
				String vehId = v!=null ? v.Id : 'null';
				String depreciateBy = v!=null ? String.valueOf(v.Rental_Depreciation_Exp__c) : '?';
				if (!sr.isSuccess()) {
					System.debug(sr);
					errmsgs += vehId + ': ' + vehName + ' : Depreciate by : ' + depreciateBy + ' : ';
					for(Database.Error de : sr.getErrors()) {
						errmsgs += '[' + String.join(de.getFields(),', ') + '] '
							+ de.getMessage() + '\r';
					}
				} else {
					updokay += vehId + ': ' + vehName + ' : depreciated\r';
				}
			}
			// BLL14a end
            
            List <Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        
            Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
            Messaging.EmailFileAttachment csvAtt = new Messaging.EmailFileAttachment();
            Blob csvBlob = Blob.valueOf(csvStr);
            csvAtt.setFileName('DepreciationCSV.csv');
            csvAtt.setBody(csvBlob);
            String[] toAddresses = new String[] {emailAddress};
            //String[] ids = new String[] {csvStr};
            mail.setToAddresses(toAddresses);
            mail.setSubject('Depreciation Summary');
            String body = 'Excel download for depreciation journal entry.';
            if (!String.isBlank(errmsgs)) body += '\rErrors:\r\r' + errmsgs;
            mail.setPlainTextBody(body);
            //mail.setEntityAttachments(ids);
            mail.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAtt});
            emailList.add(mail);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
        catch(Exception ex){
            system.debug('ERROR -> Could not complete transaction' + ex);
        }
    }


	// BLL23a
	// createPayableInvoices
	public static void createPayableInvoices(String details, String emailRecipient) {
		List<dealer__Purchase_Order__c> polist = (List<dealer__Purchase_Order__c>) JSON.deserialize(details, List<dealer__Purchase_Order__c>.class);
		System.debug(polist);
		ConcurPayableProcess cpp = new ConcurPayableProcess();
		cpp.NotificationRecipients = new List<String>();
		cpp.NotificationRecipients.add(emailRecipient);
		cpp.ProcessPurchaseInvoices(polist);
	}
	// BLL23a end


    /**
    *   Exception overload
    *
    */
    public class FFAccountingException extends Exception{}
}