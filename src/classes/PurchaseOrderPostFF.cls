/**
 * PurchaseOrderPostFF
 * Tested by: PurchaseOrderPostFF_Test
 *
 * Coverage:
 * 2018-08-17	75% (448/595)
 * 2019-02-01	84%	(430/506)
 * 
 *     Date     Programmer  Description
 * ----------   ----------  -------------------------------------------------------------------------------------
 * 2015-08-??   B. Leaman   BLL1 - Upd how to handle FF company & store additional data in journal
 * 2015-08-27   B. Leaman   BLL2 - place PO number in Control__c field, use RO# for sublet POs
 * 2015-09-01   B. Leaman   BLL3 - Skip journal line if GL account missing - FF licensing issue causing test to fail.
 * 2015-09-03   J. Kuljis   JVK1 - c2g__codaPurchaseInvoice__c to set the dimmension copy forward value flag.
 * 2015-09-10   B. Leaman   BLL4 - The copy account values flag must be "FALSE" not true.
 * 2015-10-01   B. Leaman   BLL5 - Set journal date such that FF selects the correct period for the transaction.
 * 2015-10-15   J. Kuljis   JVK2 - Add support for Misc_Charge__c, impacts balance and posting
 * 2015-10-28   B. Leaman   BLL6 IT#15942 - If accepted date is in a closed period, use next open period
 *                          and set journal date to start date of period.
 * 2015-10-29   B. Leaman   BLL7 - Payable/Purchase Invoice control#.
 * 2015-12-04   RedTeal     RT1  - Allows for misc payments to be negative. Also will not automatically calculate
 *                                 unaccounted costs as 'Purchase Variance' for sublet/misc POs.
 * 2016-02-29   B. Leaman   BLL8 - AP account lines should use company's default payable dimesion.
 *                          Also use PO accounting name for control# for all POs (reverse part of BLL2).
 * NOTE: BLL Commented out "JVK 12-11-2015" change to auto-post the journal. Posting issue caused transaction to be rolled back & not run.
 *  2016-03-31  B. Leaman   BLL9 - reinstate auto-post, but handle errors differently so transaction doesn't roll back.
 *  2016-04-12  B. Leaman   BLL10 IT#23087 - need vendor name in MAS import, so add it to the journal description.
 *  2016-05-12  B. Leaman   BLL11 - Account 2115 matches via PO#, not RO#.
 *  2016-06-10  B. Leaman   BLL12 - PurchaseInvoice needs company dim1 in the header, store dim1 in the lines.
 *  2016-06-27  B. Lemaan   BLL13 - Prep for FF v14 changes moving ffap__ and ffgl__ to c2g__.
 *  2016-10-06  J. Kuljis   JVK3  - Post to Document Period - add method to post to the same document period
 *	2018-08-07	B. Leaman	BLL14 - Speed up by querying using relationship to PO rather than formula of PO id.
 *	2019-02-01	B. Leaman	W-000573 BLL15 - add save button for stores to save internal comments (and/or vendor invoice)
 *							to indicate paid by credit card. There already was an unused save action, but needed adjustments.
 *							Also clean up some code and increase coverage. Also allow FF company errors on startup, but
 *							still prevent posting & receiving w/o FF company set properly.
 *	Note: I believe the PostToFF routine is obsolete, but not removing just yet. (BLL)
 *  
 */
public with sharing class PurchaseOrderPostFF {
    
    public dealer__Purchase_Order__c po {get;set;}
    public dealer__Dealer_Location__c loc {get;set;}
    public List<c2g__codaJournalLineItem__c> jLines = new List<c2g__codaJournalLineItem__c>();
    public List<c2g__codaJournalLineItem__c> lines = new List<c2g__codaJournalLineItem__c>();
    public c2g__codaDimension1__c dim1 {get;set;}
    public c2g__codaDimension1__c apdim1 {get;set;}     // BLL8a
    public List<c2g__codaJournalLineItem__c> existing_journal = new List<c2g__codaJournalLineItem__c>();
    public boolean received {get;set;}
    public Decimal balance {get;set;}
    public String poid { get { return po.Id; } set; }
    private Account vendor; // BLL10a

    public PurchaseOrderPostFF(ApexPages.StandardController sc) {
        Map<String, Schema.SObjectField> M = Schema.SObjectType.dealer__Purchase_Order__c.fields.getMap();
        List<String> af = new List<String>();
        Set<String> fieldnames = M.keySet(); 
        af.addAll(fieldnames);
        af.add('dealer__Vendor__r.Name');
        af.add('NMEDA_Fee__c');
        af.add('dealer__Service_Repair_Order__r.Name'); // BLL2a

        if(!Test.isRunningTest()) sc.addFields(af);
        po = (dealer__Purchase_Order__c)sc.getRecord();         

        vendor = null;
        if (po.dealer__Vendor__c!=null) vendor = [select Id, Name from Account where Id=:po.dealer__Vendor__c]; // BLL10a

        loc = getDealerLocation();
        if(loc.Financial_Force_Dimension_1__c==null) { throw new POException('Location must have the Financial Force Dimmension Set'); }
        dim1 = [Select Id, Name from c2g__codaDimension1__c where Id=:loc.Financial_Force_Dimension_1__c limit 1];
        // BLL8a
		// BLL15
		c2g__codaCompany__c company;
		try {
        	company = getFFCompany(loc.Company__c);
		} catch(Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, e.getMessage()));
		}
		// BLL15 end
        apdim1 = dim1; // BLL8 - default 
        try {
            apdim1 = [select Id, Name from c2g__codaDimension1__c where Id=:company.DefaultPayableDimension1__c limit 1];
        } catch(Exception e) {}
        // BLL8a

        // Lookup Journals with Control Number of Purchase Order
        balance = 0;
        received = false;
        //BLL14d existing_journal = [Select Id, Name, c2g__Journal__c, c2g__GeneralLedgerAccount__c, c2g__LineNumber__c, c2g__Value__c, c2g__LineType__c, c2g__Account__c from c2g__codaJournalLineItem__c where Control_Id__c = :po.Id and Control_Id__c!=null];
		// BLL14a: querying by formula to header is *much* slower than querying by the relationship
        existing_journal = new List<c2g__codaJournalLineItem__c>();
        if (po.Id!=null) existing_journal = [
        	select Id, Name, c2g__Journal__c, c2g__GeneralLedgerAccount__c, c2g__LineNumber__c, c2g__Value__c, c2g__LineType__c, c2g__Account__c 
        	from c2g__codaJournalLineItem__c 
        	where c2g__Journal__r.Purchase_Order__c=:po.Id
       	];

        if(existing_journal.size()>0) received=true;
		else {

            System.debug(po.dealer__Type__c);

            // Parts Purchases
			System.debug(po.dealer__Type__c);
            if(po.dealer__Type__c == 'Parts Purchase') receivePartsLines();

            // Sublet Sales
            if(po.dealer__Type__c == 'Sublet') genSubletLines();

            // Misc
            if(po.dealer__Type__c == 'Miscellaneous') genMiscLines();

        }     
    }

    public List<c2g__codaJournalLineItem__c> getExistingLines() {
        return existing_journal;
    }

    public PageReference save() {
        // BLl15d po.dealer__Post_Date_Time__c = Datetime.Now();
        update po;
		// BLL15
        // PageReference p = Page.PO_PostFF;
		PageReference p = new ApexPages.StandardController(po).view();
		// BLL15 end
        p.setRedirect(true);
        return p;
    }

    public void genSubletLines() {
        Map<String, c2g__codaGeneralLedgerAccount__c> gl_accounts = new Map<String, c2g__codaGeneralLedgerAccount__c>();
        Set<String> rc = new Set<String>{'2115','3325','4325','1274'};
        for(c2g__codaGeneralLedgerAccount__c gl : [Select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c IN:rc limit 10]) {
            gl_accounts.put(gl.c2g__ReportingCode__c, gl);
        }
        /*
        // Credit Sales of Internal Sublet
        jLines.add(new c2g__codaJournalLineItem__c(
                c2g__Dimension1__c=dim1.Id,
                c2g__LineNumber__c=1,
                c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('3325').Id,
                c2g__Value__c=(po.dealer__PO_Amount__c *-1),
                c2g__LineType__c='General Ledger Account'
            )
        );

        // Debit 
        jLines.add(new c2g__codaJournalLineItem__c(
                c2g__Dimension1__c=dim1.Id,
                c2g__LineNumber__c=2,
                c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('4325').Id,
                c2g__Value__c=po.dealer__PO_Amount__c,
                c2g__LineType__c='General Ledger Account'
            )
        );  
        */

        String vendorName = vendor!=null ? vendor.name : '';

        // Credit Unbilled Purchases
        jLines.add(new c2g__codaJournalLineItem__c(
                c2g__Dimension1__c=dim1.Id,
                c2g__LineNumber__c=1,
                //BLL10d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                c2g__LineDescription__c=vendorName + ': ' + po.dealer__PO_Accounting_Name__c,   // BLL10a 
                c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('2115').Id,
                c2g__Value__c=(po.dealer__PO_Amount__c *-1),
                Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                c2g__LineType__c='General Ledger Account'
            )
        );

        // Debit Sublet Pre-Paid
        jLines.add(new c2g__codaJournalLineItem__c(
                c2g__Dimension1__c=dim1.Id,
                c2g__LineNumber__c=2,
                //BLL10d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                c2g__LineDescription__c=vendorName + ': ' + po.dealer__PO_Accounting_Name__c, // BLL10a
                c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('1274').Id,
                c2g__Value__c=po.dealer__PO_Amount__c,
                Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                c2g__LineType__c='General Ledger Account'
            )
        );          
    }

    public void receivePartsLines() {
        Map<String, c2g__codaGeneralLedgerAccount__c> gl_accounts = new Map<String, c2g__codaGeneralLedgerAccount__c>();
        Set<String> rc = new Set<String>{'1220','2115'};
        for(c2g__codaGeneralLedgerAccount__c gl : [Select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c IN:rc limit 10]) {
            gl_accounts.put(gl.c2g__ReportingCode__c, gl);
        }       

        String vendorName = vendor!=null ? vendor.name : '';

        jLines.add(new c2g__codaJournalLineItem__c(
                c2g__Dimension1__c=dim1.Id,
                c2g__LineNumber__c=1,
                //BLL10d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                c2g__LineDescription__c=vendorName + ': ' + po.dealer__PO_Accounting_Name__c, // BLL10a
                c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('2115').Id,
                c2g__Value__c=(po.dealer__PO_Amount__c *-1),
                Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                c2g__LineType__c='General Ledger Account'
            )
        ); 

        jLines.add(new c2g__codaJournalLineItem__c(
                c2g__Dimension1__c=dim1.Id,
                c2g__LineNumber__c=2,
                //BLL10d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                c2g__LineDescription__c=vendorName + ': ' + po.dealer__PO_Accounting_Name__c, // BLL10a
                c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('1220').Id,
                c2g__Value__c=(po.dealer__PO_Amount__c),
                Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                c2g__LineType__c='General Ledger Account'
            )
        ); 

        System.debug(jLines);       

    }

    public List<c2g__codaJournalLineItem__c> gettLines() {
        balance=0;
        lines.clear();
        Map<String, c2g__codaGeneralLedgerAccount__c> gl_accounts = new Map<String, c2g__codaGeneralLedgerAccount__c>();
        Set<String> rc = new Set<String>{'1220','2115','2100','4905','5304','4950'};
        for(c2g__codaGeneralLedgerAccount__c gl : [Select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c IN:rc limit 10]) {
            gl_accounts.put(gl.c2g__ReportingCode__c, gl);
        }  

        if(po.dealer__Invoice_Amount__c == null) {po.dealer__Invoice_Amount__c=0;}
        if(po.Parts_Amount__c == null) {po.Parts_Amount__c=0;}
        if(po.dealer__Freight__c == null) {po.dealer__Freight__c=0;}
        if(po.NMEDA_Fee__c == null) {po.NMEDA_Fee__c=0;}

        String vendorName = vendor!=null ? vendor.name : '';

        if(po.dealer__Invoice_Amount__c > 0) {
            lines.add(new c2g__codaJournalLineItem__c(
                    // BLL8d c2g__Dimension1__c=dim1.Id,
                    c2g__Dimension1__c=apdim1.Id,   // BLL8a
                    c2g__LineNumber__c=6,
                    //BLL10d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                    c2g__LineDescription__c=vendorName + ': ' + po.dealer__PO_Accounting_Name__c, // BLL10a
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('2100').Id,
                    c2g__Value__c=(po.dealer__Invoice_Amount__c * -1),
                    c2g__LineType__c='Account - Vendor',
                    Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                    c2g__Account__c=po.dealer__Vendor__c
                )
            );
            balance+=(po.dealer__Invoice_Amount__c * -1);
        }

        /*
            Sublet Lines
        */
        if(po.dealer__Type__c == 'Sublet') {
            // DR unbilled purchase by amount of origional PO
            lines.add(new c2g__codaJournalLineItem__c(
                    c2g__Dimension1__c=dim1.Id,
                    c2g__LineNumber__c=6,
                    //BLL10d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                    c2g__LineDescription__c=vendorName + ': ' + po.dealer__PO_Accounting_Name__c, // BLL10a
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('2115').Id,
                    c2g__Value__c=(po.dealer__PO_Amount__c),
                    c2g__LineType__c='General Ledger Account',
                    Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                    c2g__Account__c=po.dealer__Vendor__c
                )
            );
            balance+=po.dealer__PO_Amount__c;   
            
            // Check for DIFF in PO Amount and apply to purchase variance account       
            // RT1 - don't calculate purchase variance for sublet/misc 
             /* 
            if(po.dealer__PO_Amount__c != po.dealer__Invoice_Amount__c ) {
                lines.add(new c2g__codaJournalLineItem__c(
                        c2g__Dimension1__c=dim1.Id,
                        c2g__LineNumber__c=6,
                        c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                        c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('4950').Id,
                        c2g__Value__c=(po.dealer__Invoice_Amount__c - po.dealer__PO_Amount__c),
                        c2g__LineType__c='General Ledger Account',
                        Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                        c2g__Account__c=po.dealer__Vendor__c
                    )
                );
                balance+=(po.dealer__Invoice_Amount__c - po.dealer__PO_Amount__c);                
            } 
            */
        }

        /*
            MISC Purchase Orders
        */
        if(po.dealer__Type__c == 'Miscellaneous') {

            // DR unbilled purchase by amount of origional PO
            lines.add(new c2g__codaJournalLineItem__c(
                    c2g__Dimension1__c=dim1.Id,
                    c2g__LineNumber__c=6,
                    //BLL10d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                    c2g__LineDescription__c=vendorName + ': ' + po.dealer__PO_Accounting_Name__c, // BLL10a
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('2115').Id,
                    c2g__Value__c=(po.dealer__PO_Amount__c),
                    c2g__LineType__c='General Ledger Account',
                    Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                    c2g__Account__c=po.dealer__Vendor__c
                )
            );
            balance+=po.dealer__PO_Amount__c;   
            
            // Check for DIFF in PO Amount and apply to purchase variance account  
             // RT1 - don't calculate purchase variance for sublet/misc 
             /*        
            if(po.dealer__PO_Amount__c != po.dealer__Invoice_Amount__c ) {
                lines.add(new c2g__codaJournalLineItem__c(
                        c2g__Dimension1__c=dim1.Id,
                        c2g__LineNumber__c=6,
                        c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                        c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('4950').Id,
                        c2g__Value__c=(po.dealer__Invoice_Amount__c - po.dealer__PO_Amount__c),
                        c2g__LineType__c='General Ledger Account',
                        Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                        c2g__Account__c=po.dealer__Vendor__c
                    )
                );
                balance+=(po.dealer__Invoice_Amount__c - po.dealer__PO_Amount__c);                
            }
            */
        }

        /*
            Used for Managing Parts Purchases
        */
        if(po.Parts_Amount__c > 0 && po.Parts_Amount__c != po.dealer__PO_Amount__c) {
            // Overage
            lines.add(new c2g__codaJournalLineItem__c(
                    c2g__Dimension1__c=dim1.Id,
                    c2g__LineNumber__c=6,
                    //BLL10d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                    c2g__LineDescription__c=vendorName + ': ' + po.dealer__PO_Accounting_Name__c, // BLL10a
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('4950').Id,
                    c2g__Value__c=(po.Parts_Amount__c - po.dealer__PO_Amount__c),
                    c2g__LineType__c='General Ledger Account',
                    Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                    c2g__Account__c=po.dealer__Vendor__c
                )
            );
            balance+=(po.Parts_Amount__c - po.dealer__PO_Amount__c);
        }     

        // Dr unbilled purchases
        if(po.Parts_Amount__c > 0) {
            lines.add(new c2g__codaJournalLineItem__c(
                    c2g__Dimension1__c=dim1.Id,
                    c2g__LineNumber__c=6,
                    //BLL10d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                    c2g__LineDescription__c=vendorName + ': ' + po.dealer__PO_Accounting_Name__c, // BLL10a
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('2115').Id,
                    c2g__Value__c=(po.Parts_Amount__c),
                    c2g__LineType__c='General Ledger Account',
                    Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                    c2g__Account__c=po.dealer__Vendor__c
                )
            );
            balance+=po.Parts_Amount__c;
        }  

        // If PA & PO != Apply Difference to Clear Entry
        if(po.Parts_Amount__c > 0 && (po.dealer__PO_Amount__c != po.Parts_Amount__c)) {
            lines.add(new c2g__codaJournalLineItem__c(
                    c2g__Dimension1__c=dim1.Id,
                    c2g__LineNumber__c=6,
                    //BLL10d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                    c2g__LineDescription__c=vendorName + ': ' + po.dealer__PO_Accounting_Name__c, // BLL10a
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('2115').Id,
                    c2g__Value__c=(po.dealer__PO_Amount__c - po.Parts_Amount__c),
                    c2g__LineType__c='General Ledger Account',
                    Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                    c2g__Account__c=po.dealer__Vendor__c
                )
            );
            balance+=po.dealer__PO_Amount__c - po.Parts_Amount__c;
        }        

        if(po.dealer__Freight__c != null && po.dealer__Freight__c > 0) {
            lines.add(new c2g__codaJournalLineItem__c(
                    c2g__Dimension1__c=dim1.Id,
                    c2g__LineNumber__c=5,
                    //BLL10d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                    c2g__LineDescription__c=vendorName + ': ' + po.dealer__PO_Accounting_Name__c, // BLL10a
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('4905').Id,
                    c2g__Value__c=(po.dealer__Freight__c),
                    c2g__LineType__c='General Ledger Account',
                    Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                    c2g__Account__c=po.dealer__Vendor__c
                )
            );
            balance+=po.dealer__Freight__c;
        } 

        // If NMEDA Fee
        if(po.NMEDA_Fee__c != null && po.NMEDA_Fee__c > 0) {
            lines.add(new c2g__codaJournalLineItem__c(
                    c2g__Dimension1__c=dim1.Id,
                    c2g__LineNumber__c=6,
                    //BLL10d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                    c2g__LineDescription__c=vendorName + ': ' + po.dealer__PO_Accounting_Name__c, // BLL10a
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('5304').Id,
                    c2g__Value__c=(po.NMEDA_Fee__c),
                    c2g__LineType__c='General Ledger Account',
                    Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                    c2g__Account__c=po.dealer__Vendor__c
                )
            );
            balance+=po.NMEDA_Fee__c;
        } 

        // If Misc Charge
        // RT1 - misc can be less than 0
        if(po.Misc_Charge__c!= null && po.Misc_Charge__c != 0) {    
            lines.add(new c2g__codaJournalLineItem__c(
                    c2g__Dimension1__c=dim1.Id,
                    c2g__LineNumber__c=7,
                    //BLL10d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                    c2g__LineDescription__c=vendorName + ': ' + po.dealer__PO_Accounting_Name__c, // BLL10a
                    c2g__GeneralLedgerAccount__c=po.GeneralLedgerAccount__c,
                    c2g__Value__c=(po.Misc_Charge__c),
                    c2g__LineType__c='General Ledger Account',
                    Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                    c2g__Account__c=po.dealer__Vendor__c
                )
            );
            balance+=po.Misc_Charge__c;
        }

        /*
            END - Parts Purchase Orders
        */

        return lines;
    }

    public void genPartsLines() {
        Map<String, c2g__codaGeneralLedgerAccount__c> gl_accounts = new Map<String, c2g__codaGeneralLedgerAccount__c>();
        Set<String> rc = new Set<String>{'1220','2115','2100','4905','5304','4950'};
        for(c2g__codaGeneralLedgerAccount__c gl : [Select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c IN:rc limit 10]) {
            gl_accounts.put(gl.c2g__ReportingCode__c, gl);
        }  

        if(po.dealer__Invoice_Amount__c == null) {po.dealer__Invoice_Amount__c=0;}
        if(po.dealer__Freight__c == null) {po.dealer__Freight__c=0;}
        if(po.NMEDA_Fee__c == null) {po.NMEDA_Fee__c=0;}
        if(po.Misc_Charge__c == null) { po.Misc_Charge__c=0; }

        String vendorName = vendor!=null ? vendor.name : '';
        
        // If PO Amount == Invoice Amount
        if(po.dealer__PO_Amount__c == po.dealer__Invoice_Amount__c) {
            jLines.add(new c2g__codaJournalLineItem__c(
                    c2g__Dimension1__c=dim1.Id,
                    c2g__LineNumber__c=1,
                    //BLL10d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                    c2g__LineDescription__c=vendorName + ': ' + po.dealer__PO_Accounting_Name__c, // BLL10a
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('2115').Id,
                    c2g__Value__c=(po.dealer__PO_Amount__c *-1),
                    Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                    c2g__LineType__c='General Ledger Account'
                )
            ); 

            jLines.add(new c2g__codaJournalLineItem__c(
                    c2g__Dimension1__c=dim1.Id,
                    c2g__LineNumber__c=2,
                    //BLL10d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                    c2g__LineDescription__c=vendorName + ': ' + po.dealer__PO_Accounting_Name__c, // BLL10a
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('1220').Id,
                    c2g__Value__c=(po.dealer__PO_Amount__c),
                    Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                    c2g__LineType__c='General Ledger Account'
                )
            );         
        }

        if(po.dealer__PO_Amount__c != po.dealer__Invoice_Amount__c) {
            jLines.add(new c2g__codaJournalLineItem__c(
                    c2g__Dimension1__c=dim1.Id,
                    c2g__LineNumber__c=1,
                    //BLL10d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                    c2g__LineDescription__c=vendorName + ': ' + po.dealer__PO_Accounting_Name__c, // BLL10a
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('2115').Id,
                    c2g__Value__c=(po.dealer__PO_Amount__c *-1),
                    Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                    c2g__LineType__c='General Ledger Account'
                )
            ); 

            jLines.add(new c2g__codaJournalLineItem__c(
                    c2g__Dimension1__c=dim1.Id,
                    c2g__LineNumber__c=2,
                    //BLL10d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                    c2g__LineDescription__c=vendorName + ': ' + po.dealer__PO_Accounting_Name__c, // BLL10a
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('1220').Id,
                    c2g__Value__c=(po.dealer__PO_Amount__c),
                    Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                    c2g__LineType__c='General Ledger Account'
                )
            );

            jLines.add(new c2g__codaJournalLineItem__c(
                    // BLL8d c2g__Dimension1__c=dim1.Id,
                    c2g__Dimension1__c=apdim1.Id, // BLL8a
                    c2g__LineNumber__c=3,
                    //BLL10d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                    c2g__LineDescription__c=vendorName + ': ' + po.dealer__PO_Accounting_Name__c, // BLL10a
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('2100').Id,
                    c2g__Value__c=(po.dealer__Invoice_Amount__c * -1),
                    Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                    c2g__LineType__c='General Ledger Account'
                )
            ); 

            jLines.add(new c2g__codaJournalLineItem__c(
                    c2g__Dimension1__c=dim1.Id,
                    c2g__LineNumber__c=4,
                    //BLL10d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                    c2g__LineDescription__c=vendorName + ': ' + po.dealer__PO_Accounting_Name__c, // BLL10a
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('2115').Id,
                    c2g__Value__c=(po.dealer__PO_Amount__c),
                    Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                    c2g__LineType__c='General Ledger Account'
                )
            ); 

            jLines.add(new c2g__codaJournalLineItem__c(
                    c2g__Dimension1__c=dim1.Id,
                    c2g__LineNumber__c=5,
                    //BLL10d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                    c2g__LineDescription__c=vendorName + ': ' + po.dealer__PO_Accounting_Name__c, // BLL10a
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('4905').Id,
                    c2g__Value__c=(po.dealer__Freight__c),
                    Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                    c2g__LineType__c='General Ledger Account'
                )
            ); 

            jLines.add(new c2g__codaJournalLineItem__c(
                    c2g__Dimension1__c=dim1.Id,
                    c2g__LineNumber__c=6,
                    //BLL10d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                    c2g__LineDescription__c=vendorName + ': ' + po.dealer__PO_Accounting_Name__c, // BLL10a
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('5304').Id,
                    c2g__Value__c=(po.NMEDA_Fee__c),
                    Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                    c2g__LineType__c='General Ledger Account'
                )
            );

            //RT1 misc can be less than 0
            if(po.Misc_Charge__c!=null && po.Misc_Charge__c!= 0) {
                jLines.add(new c2g__codaJournalLineItem__c(
                        c2g__Dimension1__c=dim1.Id,
                        c2g__LineNumber__c=7,
                        //BLL10d c2g__LineDescription__c=po.Misc_Description__c,
                        c2g__LineDescription__c=vendorName + ': ' + po.dealer__PO_Accounting_Name__c, // BLL10a
                        c2g__GeneralLedgerAccount__c=po.GeneralLedgerAccount__c,
                        c2g__Value__c=(po.Misc_Charge__c),
                        Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                        c2g__LineType__c='General Ledger Account'
                    )
                );    
            }        
           
            jLines.add(new c2g__codaJournalLineItem__c(
                    c2g__Dimension1__c=dim1.Id,
                    c2g__LineNumber__c=8,
                    //BLL10d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                    c2g__LineDescription__c=vendorName + ': ' + po.dealer__PO_Accounting_Name__c, // BLL10a
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('4950').Id,
                    c2g__Value__c=(po.dealer__Invoice_Amount__c 
                                   - po.dealer__PO_Amount__c 
                                   - po.dealer__Freight__c 
                                   - po.NMEDA_Fee__c
                                   - po.Misc_Charge__c),
                    Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                    c2g__LineType__c='General Ledger Account'
                )
            );
            
            System.debug(jLines);                                                             
        }
    }

    public void genMiscLines() {
        String vendorName = vendor!=null ? vendor.name : '';

        Map<String, c2g__codaGeneralLedgerAccount__c> gl_accounts = new Map<String, c2g__codaGeneralLedgerAccount__c>();
        // From the GL Lookup
        Set<String> rc = new Set<String>{'2115','2100','4905'};
        for(c2g__codaGeneralLedgerAccount__c gl : [Select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c IN:rc limit 10]) {
            gl_accounts.put(gl.c2g__ReportingCode__c, gl);
        }

        dealer__Purchase_Order_Line__c pl = [Select Id, General_Ledger_Account__c 
                                                from dealer__Purchase_Order_Line__c 
                                                where dealer__Purchase_Order__c =: po.Id limit 1];

        if(po.dealer__Invoice_Amount__c == null) { po.dealer__Invoice_Amount__c = po.dealer__PO_Amount__c; }                                        

        if(po.dealer__PO_Amount__c == po.dealer__Invoice_Amount__c) {
            if (pl.General_Ledger_Account__c!=null) {  // BLL3a - Skip if missing GL Account (test issue) 
            jLines.add(new c2g__codaJournalLineItem__c(
                    c2g__Dimension1__c=dim1.Id,
                    c2g__LineNumber__c=1,
                    //BLL10d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                    c2g__LineDescription__c=vendorName + ': ' + po.dealer__PO_Accounting_Name__c, // BLL10a
                    c2g__GeneralLedgerAccount__c=pl.General_Ledger_Account__c,
                    c2g__Value__c=po.dealer__PO_Amount__c,
                    Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                    c2g__LineType__c='General Ledger Account'
                )
            );
            } // BLL3a 

            jLines.add(new c2g__codaJournalLineItem__c(
                    c2g__Dimension1__c=dim1.Id,
                    c2g__LineNumber__c=2,
                    //BLL10d c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                    c2g__LineDescription__c=vendorName + ': ' + po.dealer__PO_Accounting_Name__c, // BLL10a
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('2115').Id,
                    c2g__Value__c=(po.dealer__PO_Amount__c * -1),
                    Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                    c2g__LineType__c='General Ledger Account'
                )
            ); 
        } 

        /*
        if(po.dealer__PO_Amount__c != po.dealer__Invoice_Amount__c) {
            jLines.add(new c2g__codaJournalLineItem__c(
                    c2g__Dimension1__c=dim1.Id,
                    c2g__LineNumber__c=1,
                    c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                    c2g__GeneralLedgerAccount__c=pl.General_Ledger_Account__c,
                    c2g__Value__c=po.dealer__PO_Amount__c,
                    Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                    c2g__LineType__c='General Ledger Account'
                )
            );

            jLines.add(new c2g__codaJournalLineItem__c(
                    c2g__Dimension1__c=dim1.Id,
                    c2g__LineNumber__c=2,
                    c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('2115').Id,
                    c2g__Value__c=(po.dealer__PO_Amount__c * -1),
                    Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                    c2g__LineType__c='General Ledger Account'
                )
            ); 

            jLines.add(new c2g__codaJournalLineItem__c(
                    c2g__Dimension1__c=dim1.Id,
                    c2g__LineNumber__c=3,
                    c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('2100').Id,
                    c2g__Value__c=(po.dealer__Invoice_Amount__c * -1),
                    Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                    c2g__LineType__c='General Ledger Account'
                )
            ); 

            jLines.add(new c2g__codaJournalLineItem__c(
                    c2g__Dimension1__c=dim1.Id,
                    c2g__LineNumber__c=4,
                    c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('2115').Id,
                    c2g__Value__c=(po.dealer__PO_Amount__c),
                    Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                    c2g__LineType__c='General Ledger Account'
                )
            );

            jLines.add(new c2g__codaJournalLineItem__c(
                    c2g__Dimension1__c=dim1.Id,
                    c2g__LineNumber__c=5,
                    c2g__LineDescription__c=po.dealer__PO_Accounting_Name__c,
                    c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('4905').Id,
                    c2g__Value__c=(po.dealer__Freight__c),
                    Vendor_Name__c=po.dealer__Vendor__c,    // BLL10a
                    c2g__LineType__c='General Ledger Account'
                )
            );              
            System.debug(jLines);
        } 
        */       
    }

    public List<c2g__codaJournalLineItem__c> getjLines() {
        return jLines;
    }

    public PageReference postToFF() {

        // BLL8a
        Map<Id,c2g__codaGeneralLedgerAccount__c> GLsMatchViaPO = new Map<Id,c2g__codaGeneralLedgerAccount__c>([
            select Id, Name, c2g__ReportingCode__c
            from c2g__codaGeneralLedgerAccount__c
            where c2g__ReportingCode__c in ('2115')
        ]);
        // BLL8a end

        if(po.Misc_Charge__c==null) { po.Misc_Charge__c=0;}

        // BLL2a  - get sublet record type
        Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Purchase_Order__c.getRecordTypeInfosByName();
        Schema.RecordTypeInfo rtInfo = RcdTypes.get('Sublet');
        Id subletRtId = rtInfo.getRecordTypeId();
        // BLL2a end

        Id jId = createJournal();
        List<c2g__codaJournalLineItem__c> lUpdate = new List<c2g__codaJournalLineItem__c>();
        List<c2g__codaJournalLineItem__c> lines = getjLines();
        
        // BLL2a begin
        String controlnbr = po.dealer__PO_Accounting_Name__c;
        String poControlNbr = controlnbr; // BLL8a 
        if (po.RecordTypeId==subletRtId && po.dealer__Service_Repair_Order__r.Name!=null) {
            controlnbr = po.dealer__Service_Repair_Order__r.Name; 
        }
        // BLL2a end
        
        for(c2g__codaJournalLineItem__c jli : lines) {
            jli.c2g__Journal__c = jId;
            jli.Control__c = controlnbr; // BLL2a
            // BLL8a
            if (GLsMatchViaPO.containsKey(jli.c2g__GeneralLedgerAccount__c)) jli.Control__c = poControlNbr;
            // BLL8a end
            lUpdate.add(jli);
        }

        System.debug(lUpdate);

        try {
            insert lUpdate;
        } Catch(DmlException e) {
            throw new POException('Unable to create Journal Lines '+e.getMessage());
        }

        // JVK 12-11-2015 
        // Transaction POST - Reinstated by BLL9
        try {
            FFAccounting.postJournal(jId);
        } Catch(DmlException e) {
            // throw new POException('Unable to Post '+e.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Journal did not post: ' + e.getMessage()));
            return null;    // BLL9a
        } Catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Journal did not post: ' + e.getMessage()));
            // throw new POException('Unable to Post '+e.getMessage());
            return null;    // BLL9a
        }


        // return new ApexPages.StandardController(po).view();
        PageReference pr = Page.PO_PostFF;
        pr.getParameters().put('id', po.Id);
        pr.setRedirect(true);
        return pr;
    }

    /*
    *
    *   applyVendorInvoice 
    *       creates the payable invoice with the expense lines to match.
    *       returns the user to the payable invoice
    *
    */
    public PageReference applyVendorInvoice() {

        // BLL7a  - get sublet record type
        Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Purchase_Order__c.getRecordTypeInfosByName();
        Schema.RecordTypeInfo rtInfo = RcdTypes.get('Sublet');
        Id subletRtId = rtInfo.getRecordTypeId();
        // BLL7a end

        // BLL11a
        Map<Id,c2g__codaGeneralLedgerAccount__c> GLsMatchViaPO = new Map<Id,c2g__codaGeneralLedgerAccount__c>([
            select Id, Name, c2g__ReportingCode__c
            from c2g__codaGeneralLedgerAccount__c
            where c2g__ReportingCode__c in ('2115')
        ]);
        // BLL11a end

        // Do not allow if a Payable invoice exists
        if(po.Payable_Invoice__c!=null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Purchase Order already related to Payable Invoice'));
            return null;            
        }

        // Check Misc GL Account if Misc Charge is specified
        // RT1
        if((po.Misc_Charge__c!=null&&po.Misc_Charge__c!=0) && po.GeneralLedgerAccount__c==null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Miscellaneous Amount requires a General Ledger Account '));
            return null;            
        }

        // Check values before proceeding.
        if(po.dealer__Invoice_Amount__c == null || po.dealer__Invoice_Amount__c == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invoice Amount Required'));
            return null;
        }

        if(po.dealer__Invoice_Date__c == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invoice Date Required'));
            return null;            
        }

        //Parts Requirements 
        if(po.dealer__Type__c == 'Parts Purchase') {
            if(po.Parts_Amount__c == null || po.Parts_Amount__c == 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Parts Amount Required'));
                return null;            
            }

            if(po.dealer__Freight__c == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Freight must not be blank, if there is no Freight make $0'));
                return null;
            }
        }

        if(balance!=0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Transaction must be in Balance'));
            return null;
        }

        try {

            Id payableInvoice = createPayableInvoice();

            // Iterate TLines for the Expense Lines to be placed on a Purchase Order
            List<c2g__codaPurchaseInvoiceExpenseLineItem__c> pl = new List<c2g__codaPurchaseInvoiceExpenseLineItem__c>();
            for(c2g__codaJournalLineItem__c j : lines) {
                // Exclude AP
                if(j.c2g__LineType__c == 'General Ledger Account') {
                    // BLL7a
                    String controlnbr = po.dealer__PO_Accounting_Name__c; 
                    if (po.RecordTypeId==subletRtId && po.dealer__Service_Repair_Order__r.Name!=null
                        && !GLsMatchViaPO.containsKey(j.c2g__GeneralLedgerAccount__c)) {    // BLL11c
                        controlnbr = po.dealer__Service_Repair_Order__r.Name; 
                    }
                    // BLL7a end
                    pl.add(new c2g__codaPurchaseInvoiceExpenseLineItem__c(
                            c2g__PurchaseInvoice__c=payableInvoice,
                            c2g__NetValue__c=j.c2g__Value__c,
                            c2g__LineDescription__c=j.c2g__LineDescription__c,
                            c2g__Dimension1__c=j.c2g__Dimension1__c,
                            ffap__SetGLAToDefault__c=false,
                            c2g__SetGLAToDefault__c=false,  // BLL13a
                            c2g__GeneralLedgerAccount__c=j.c2g__GeneralLedgerAccount__c,
                            Control__c=controlnbr  // BLL7a
                        )
                    );
                }
            }

            // Try an insert the payable lines
            if(pl.size()>0) insert pl;

            // Update the purchase order to show the relevant information
            po.dealer__Post_Date_Time__c = Datetime.now();
            po.Payable_Invoice__c = payableInvoice;
            update po;

            PageReference pref = new PageReference('/'+payableInvoice);
            pref.setRedirect(true);
            return pref;

        } Catch(DmlException e) {
            throw new POException('Unable to create the payable invoice for this purchase order '+e.getMessage());
        }

        //return null;
    }

    public PageReference returnToPurchaseOrder() {
        return new ApexPages.StandardController(po).view();
    }

    public dealer__Dealer_Location__c getDealerLocation() {
        return [Select Id, Name, Company__c, Financial_Force_Dimension_1__c from dealer__Dealer_Location__c where Id=:po.dealer__Company__c limit 1];
    }

    // BLL1a begin
    // getLocationFFCompany
    //----------------------------------------------------
    public c2g__codaCompany__c getFFCompany(Id compid) {
        // Get FF Company Information - TODO: Based on location this is for!
        c2g__codaCompany__c comp=null;
        if (compid!=null) {
            List<c2g__codaCompany__c> comps = [
                select Id, Name, DefaultPayableDimension1__c    // BLL8c 
                from c2g__codaCompany__c where Id=:compid
            ];
            if (comps.size()>0) {
                comp = comps[0];
                System.debug('Using company ' + comp.Name);
            } else {
                throw new PostingTemplateException('Not authorized to the financial company');
            }
        } else {
            throw new PostingTemplateException('Missing the financial company');
        }
        
        // Currently selected company
        List<ID> groupIds = new List<ID>();
        for(GroupMember member : [select GroupId from GroupMember where Group.Type = 'Queue' and UserOrGroupId = :UserInfo.getUserId()]) {
            groupIds.add(member.GroupId);               
        } 
        c2g__codaCompany__c[] companies = 
            [select RecordType.Name, Id, Name, c2g__TaxCode__c, c2g__CODABaseDate1__c, c2g__CODADaysOffset1__c from c2g__codaCompany__c where OwnerId in :groupIds];
        // Ensure the user has a single current company
        if (companies.size() == 0) throw new PostingTemplateException('Current company has not been set for this user');
        if (companies.size() > 1) throw new PostingTemplateException('This operation is not valid in multiple company mode'); 
        if (companies[0].Id!=comp.Id) throw new PostingTemplateException('Your current company is ' + companies[0].Name + '. '
                  + 'Please select the transaction company ' + comp.Name + '.');

        return comp;
    }
    // BLL1a end


    /*
    *
    *   CreatePayableInvoice - 
    *       Creates the header record for a payable invoice.  The payable invoice is generated once Accounting applys a Vendor Invoice to a Purchase Order
    */
    public Id createPayableInvoice() {

        try {

            c2g__codaCompany__c comp = getFFCompany(loc.Company__c);
            // Get Accounting Currency
            c2g__codaAccountingCurrency__c cur = [Select Id from c2g__codaAccountingCurrency__c where c2g__OwnerCompany__c =:comp.Id limit 1];
            // Get Period Data
            // c2g__codaPeriod__c period = [Select Id from c2g__codaPeriod__c where c2g__StartDate__c >=:Date.today() and c2g__Closed__c=false limit 1];

            // BLL12a
            apdim1 = dim1;  
            try {
                apdim1 = [select Id, Name from c2g__codaDimension1__c where Id=:comp.DefaultPayableDimension1__c limit 1];
            } catch(Exception e) {}
            // BLL12a

            c2g__codaPurchaseInvoice__c p = new c2g__codaPurchaseInvoice__c();
            p.c2g__Account__c       =   po.dealer__Vendor__c;
            p.c2g__OwnerCompany__c  =   comp.Id;
            //BLL12d p.c2g__Dimension1__c   =   dim1.Id;
            p.c2g__Dimension1__c = apdim1.Id;   // BLL12a
            p.ffap__DeriveDueDate__c=   true;
            p.ffap__DerivePeriod__c =   true;
            p.c2g__DeriveDueDate__c=    true;   // BLL13a
            p.c2g__DerivePeriod__c =    true;   // BLL13a 
            p.c2g__InvoiceDate__c   =   po.dealer__Invoice_Date__c;
            p.c2g__InvoiceCurrency__c   =   cur.Id;
            p.c2g__InvoiceDescription__c=   po.dealer__PO_Accounting_Name__c;
            p.c2g__AccountInvoiceNumber__c= po.dealer__Invoice_Number__c;
            p.c2g__InvoiceStatus__c = 'In Progress';
            p.ffap__CopyAccountValues__c = false;    //  JVK1   // BLL4c
            p.c2g__CopyAccountValues__c = false;     //  JVK1   // BLL4c
            p.Source__c = 'PB'; // BLL7a

            insert p;
            return p.Id;

        } catch(DmlException e) {
            throw new POException('Error Creating Payable Invoice from Purchase Order '+e.getMessage());
        }

        //return null;
    }

    /**
     * [postPurchaseOrderToDocumentPeriod description]
     * @return Boolean
     * @notes added to allow support for same period posting on purchase orders on the accounting system screen
     *        added on 10/06/2016 - Jarrett Kuljis
     */
/** BLL15
    public PageReference postPurchaseOrderToDocumentPeriod() {


       // Lookup the Parts Purchase Order
        dealer__Purchase_Order__c po = [Select Id, Name, Part_Quantity_Outstanding__c, dealer__PO_Accounting_Name__c, dealer__PO_Amount__c, 
                                                dealer__Company__c, dealer__Accepted_DateTime__c, 
                                                dealer__Accepted_By__c, dealer__Status__c, LastModifiedById,
                                                dealer__Vendor__c, dealer__Vendor__r.Name, // BLL3a & BLL4a 
                                                dealer__Service_Repair_Order__c, dealer__Service_Repair_Order__r.Name // BLL2a
                                            from dealer__Purchase_Order__c where Id=:po.Id 
                                            limit 1];

        if(po.dealer__Accepted_DateTime__c==null) {
            throw new POException('Please ensure the Purchase Order is Accepted');
        }
        
        if(po.dealer__PO_Amount__c==null || po.dealer__PO_Amount__c==0) {
            throw new POException('Error receiving part, the value to apply is 0 ');
        }

        Decimal partVal = po.dealer__PO_Amount__c;

        // Select Sum of all Transactions posted to ensure there is not an overposting sittuation
        Decimal transactionAmount = (Decimal) [Select SUM(c2g__DualDebits__c) totalValue from c2g__codaTransaction__c where Purchase_Order__c =:po.Id][0].get('totalValue');
        if(transactionAmount==null) { transactionAmount=0;}

        if(transactionAmount>=po.dealer__PO_Amount__c) {
            //WTF?
            throw new POException('Error: GL Transactions can not excede purchase order values for this PO.');
        }

        // Get the location record
        dealer__Dealer_Location__c loc = FFAccounting.getDealerLocation(po.dealer__Company__c); 

        // Sanity Check
        if(loc.Financial_Force_Dimension_1__c==null) {
            throw new POException('Financial Force Dimension 1 not set for Location '+po.dealer__Company__c);
        }               

        Map<String, c2g__codaGeneralLedgerAccount__c> gl_accounts = new Map<String, c2g__codaGeneralLedgerAccount__c>();
        Set<String> rc = new Set<String>{'1220','2115'};
        for(c2g__codaGeneralLedgerAccount__c gl : [Select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c IN:rc limit 10]) {
            gl_accounts.put(gl.c2g__ReportingCode__c, gl);
        }

        // Set Transaction Control
        SavePoint sp = Database.setSavePoint();

        // Create the Journal
        //
        //Id journal = FFAccounting.createJournal(po.dealer__Company__c, 'Purchase Order '+po.Name, po.Name, po.Name, 'PUR', Date.valueOf(po.dealer__Accepted_DateTime__c));
        //
        
        Id journalId = null;
        Date jdate = po.dealer__Accepted_DateTime__c.date();

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
            Database.rollback(sp);
            throw new POException('Unable to create the journal lines '+e.getMessage());
        }

        // Update Accepted Date on Purchase Order - only if the po is completely received.
        if(po.Part_Quantity_Outstanding__c == 0 && po.dealer__Status__c == 'Open') {
            try {
                po.dealer__Accepted_By__c = po.LastModifiedById;
                po.dealer__Accepted_DateTime__c = DateTime.now();
                po.dealer__Status__c = 'Accepted';

                update po;

            }  Catch(DmlException e) {
                Database.rollback(sp);
                throw new POException('Failed to update purchase order accepted status');
            }
        }
    
        // return new ApexPages.StandardController(po).view();
        PageReference pr = Page.PO_PostFF;
        pr.getParameters().put('id', po.Id);
        pr.setRedirect(true);
        return pr;
    }
BLL15 end **/

    public Id createJournal() {
        String vendorName = vendor!=null ? vendor.name : '';
        // get company information
        try {
            //c2g__codaCompany__c comp  = [Select Id from c2g__codaCompany__c where Id =: loc.Company__c Limit 1];  // BLL1d
            c2g__codaCompany__c comp = getFFCompany(loc.Company__c);  // BLL1a
            
            // Get Accounting Currency
            c2g__codaAccountingCurrency__c cur = [Select Id from c2g__codaAccountingCurrency__c where c2g__OwnerCompany__c =:comp.Id limit 1];
            // Get Period Data
            //BLL5d c2g__codaPeriod__c period = [Select Id from c2g__codaPeriod__c where c2g__StartDate__c >=:Date.today() and c2g__Closed__c=false limit 1];

            // Build the Journal
            c2g__codaJournal__c tJrnl       =   new c2g__codaJournal__c();
            tJrnl.c2g__OwnerCompany__c      =   comp.Id;
            tJrnl.c2g__JournalCurrency__c   =   cur.Id;
            //tJrnl.c2g__JournalDescription__c=   'Created by Purchase Order Posting';  // <- Store# 112 or AKR ? Then Proposal Number // BLL1d
            //BLL3d tJrnl.c2g__JournalDescription__c = 'Purchase Order ' + po.dealer__PO_Accounting_Name__c;  // BLL1a
            tJrnl.c2g__JournalDescription__c = vendorName + ': Purchase Order ' + po.dealer__PO_Accounting_Name__c;  // BLL3a, BLL10c   
            // BLL5d tJrnl.c2g__JournalDate__c       =   Date.today();
            // BLL6d tJrnl.c2g__JournalDate__c      =   jdate;  // BLL5a
            tJrnl.c2g__Reference__c         =   po.dealer__PO_Accounting_Name__c;
            // BLL5d tJrnl.c2g__Period__c            =   period.Id;
            tJrnl.Source__c = 'PUR';  // BLL1a
            tJrnl.Purchase_Order__c = po.Id;  // BLL1a
            tJrnl.Vendor__c = po.dealer__Vendor__c;  // BLL1a

            Date jdate = Date.today(); // BLL5a
            if (po.dealer__Accepted_DateTime__c!=null) jdate = po.dealer__Accepted_DateTime__c.date(); // BLL5a
            // BLL6a - next open period ending after transaction date
            c2g__codaPeriod__c period = [
                select Id, c2g__StartDate__c, c2g__EndDate__c, c2g__AP__c, c2g__Closed__c 
                from c2g__codaPeriod__c
                where c2g__OwnerCompany__c=:comp.Id and c2g__EndDate__c>:jdate
                  and c2g__Closed__c!=true and c2g__AP__c!=true
                order by c2g__StartDate__c
                limit 1
            ];
            // If the period starts after the transaction date (posting next month), force current period & chg date
            if (period.c2g__StartDate__c > jdate) {
                tJrnl.c2g__Period__c = period.Id;
                tJrnl.ffgl__DerivePeriod__c = false;
                tJrnl.c2g__DerivePeriod__c = false; // BLL13a
                tJrnl.c2g__JournalDate__c = period.c2g__StartDate__c;
            } else {  // Otherwise, let FF determine period
                tJrnl.c2g__JournalDate__c = jdate;
                tJrnl.ffgl__DerivePeriod__c = true;         
                tJrnl.c2g__DerivePeriod__c = true;  // BLL13a           
            }
            // BLL6a end determine period/date

            insert tJrnl;
            return tJrnl.Id;

        } catch(DmlException e) {
             throw new POException('Failed to create Journal '+e);
        } catch(SObjectException e) {
            throw new POException('Failed to create Journal '+e);
        } catch(Exception e) {
            throw new POException('Failed to create Journal '+e);
        }

        //return null;
    }

    /*
    *
    *   Positive Value - Generic Helper Function
    *
    */
    public Decimal pos(Decimal v) {
        
		// BLL15
        //if(v==null) {
        //    return 0;
        //}
		if (v==null) v=0;
		// BLL15 end

        if(v<0) {
            v=v*-1;
            v=v.setScale(2);
            // BLL15d return v;
        }

        return v.setScale(2);
    }


    public class POException extends Exception {}
    public class PostingTemplateException extends Exception {}
    
}