/** JournalManager
 * Tested by: JournalManager_TC, JournalManager_TC2
 * Pages: PostingCreateJournal
 * Coverage:
 *	2019-09-26	78% (712/907)
 *
 * 2015-08-04   B. Leaman   Load new/used and stock# from proposal. Add Deposit.
 * 2015-08-27   B. Leaman   BLL2 - correct stock# as control#, add finance company
 * 2015-09-04   J. Kuljis   JVK3 - Set the commission totals to include all CMC's
 * 2015-09-21   B. Leaman   BLL3 - Third party pay & Finance Company need to be an "Account-Customer" transaction instead of GL Acct
 * 2015-09-24   B. Leaman   BLL4 - Clear out amounts on loaded template rules from Account Receivable, Finance Company when they do not apply!
 * 2015-09-28   B. Leaman   BLL5 - Make sure Rebates/Incentives is line type 'Account - Customer' in the journal.
 * 2015-10-01   B. Leaman   BLL6 - FF will derive period from proposed delivery date.
 * 2015-10-08   B. Leaman   BLL7 - Third party pay (and other pay) need to reference 3rd party/other account
 *                          Also, fix so additional lines are included in journal.
 *                          Fix Conversion Sales, Conversion Inventory, Trade-in Chassis, Additional Equipment Inventory.
 *                          Fix ESC, GAP, DiamondFusion, Roadside protection products.
 *                          Split commissions. Protect against double posting.
 * 2015-10-27   B. Leaman   BLL8 - Trade chassis should be Chassis_Amount (dflt to acv), 'Account Receivable' needs reduced by trade allowances;
 *                          Change template action control# to proposal# for Additional Equipment Inventory
 *MAYBE WRONG! 2015-11-05   B. Leaman   BLL9 - Store deal# as DocumentReference and vehicle on line description
 *
 * 2015-12-21  J. Kuljis    JVK2 - createJournal modified to use the FinancialForce_MBW.createJournalApi method, and throws an error if attempting to post with no journal lines.
 * 2016-04-12   B. Leaman   BLL10 IT#23367 - Create journal from commercial quotes
 * 2016-04-27   B. Leaman   BLL11 IT#23367 - Allow changing dimension1 on screen.
 * 2016-05-13   B. Leaman   BLL12 Use unit number as control# for quotes if there is no
 *                          vehicle inventory associated with the quote.
 * 2016-05-16   B. Leaman   BLL13 Change posting of quotes for customer-owned chassis.
 * 2016-05-18   RedTeal     RT1 - 
 * 2016-06-06   B. Leaman   BLL14 Handle missing values (treat as 0)
 * 2016-06-14   B. Leaman   BLL15 Support for Tire Fees, Conversion Discount (proposals), vehicle reference to trade-in ?
 * 2016-06-15   B. Leaman   BLL16 - Prevent posting if any ROs are open on the vehicle.
 * 2016-06-17   B. Leaman   BLL17 - Fix releasing dealer AR and posting template; 
 * 2016-06-20   B. Leaman   BLL18 - don't prevent post if open ROs is null; fix SOQL inside loop! 
 * 2016-07-05   B. Leaman   BLL19 - Add support for viewing and pulling vehicle GL costs into template.
 * 2016-07-13   B. Leaman   BLL20 - Stop posting if there are open ROs referencing the document (quote/proposal).
 * 2016-07-15   B. Leaman   BLL21 - Pull all related ROs, not just the one referenced by the proposal or quote.
 * 2016-07-21   B. Leaman   BLL22 - If releasing dealer collects taxes, don't include them in the GL.
 * 2016-07-22   B. Leaman   BLL23 - Need to account for trade-in overallowances. 
 * 2016-10-05   B. Leaman   BLL24 - Undo BLL5 per Jeremy S. Rebates/Incentives should not hit A/R Aging on the customer (or anyone).
 * 2016-11-02   B. Leaman   BLL25 - Remove Total_Vehicle_Package__c field reference.
 * 2016-11-08   B. Leaman   BLL26 - Inventory reserve support.
 * 2016-12-01   B. Leaman   BLL27 - Finance Company is messed up.
 * 2016-12-29   B. Leaman   BLL28 - Replace custom lookups with managed versions (Deal obj)
 * 2017-01-27	DealerTeam	BLL29 - Store memo field in line description.
 * 2017-02-21	B. Leaman	BLL30 - Changes for commercial proposals.
 * 2017-03-03	B. Leaman	BLL31 - MBW Rewards should be a debit, not a credit. Per John Wilson IR-0008475
 * 2017-04-07	B. Leaman	BLL32 - Additional adjustments for commercial releasing dealer processing.
 * 2017-04-10	B. Leaman	BLL33 - Don't post other fees either, for releasing dealer proposals.
 * 2017-04-20	B. Leaman	BLL34 - Don't include account 3305 in the GL gross profit calcs.
 * 2017-05-16	B. Leaman	BLL35 - Add account lookup to screen - assign when building jlines for display and use the screen value when building journal lines.
 * 2017-05-22	B. Leaman	BLL36 - Re-enable finance company logic so they don't have to key them in as other payors.
 * 2017-05-25	B. Leaman	BLL37 - Discovered issue with inventory reserve relieving more than the RO reserved when
 *                          RO lines had $0 charge for labor with hours.
 * 2017-06-02	B. Leaman	BLL38 - Handle new protection products, loan/lease acquisition cost/fee.
 * 2017-07-02	B. Leaman	BLL39 - Remove Invenotry Reserve support (BLL26), add linetype field to posting template entry rule soql.
 * 2017-09-11	B. Leaman	BLL40 - First lease pmt comes to us, and not the lease company.
 * 2017-11-29	B. Leaman	BLL41 - Only apply finance inst. (Loan/lease) if funding option is 'Financed'; add reimbursement amt to finance company (for GAP paid by BancLease)
 * 2018-07-11	B. Leaman	BLL42 - fix reimbursed GAP (reduce COGS); 
 * 2018-09-13	B. Leaman	BLL43 - fix customer A/R value;
 * 2018-10-16   B. Leaman   BLL44 IR-0042069 - don't reduce conversion sales by chassis mark-up any more;
 * 2018-11-26   B. Leaman   W-000391 BLL45 - consolidate A/R journal lines by account
 * 2019-01-16	B. Leaman	W-000482 BLL46 - Adjust journal-posting auto approval (moved auto-approve method to ApprovalProcessUtil class)
 *							to only approve the accounting step, never the delivery step.
 * 2019-05-22	B. Leaman	W-000575 BLL47 - set control# on A/R lines to document name for automated matching.
 * 2019-08-05	B. Leaman	W-000606 BLL48 - ESC Loan acquisition cost
 * 2019-08-27	B. Leaman	W-000332 BLL49 - GP Sharing allocation.
 */

public with sharing class JournalManager {
    
    // Posting Entry
    public Posting_Entry__c entry {get;set;}
    public String entryId {get;set;}
    public dealer__Deal__c proposal {get;set;}
    //BLL10d public List<dealer__Dealer_Location__c> loc {get;set;}
    public dealer__Dealer_Location__c loc {get;set;}    // BLL10a
    public CommercialQuote__c cq {get;set;}     // BLL10a
    public c2g__codaDimension1__c dim1 {get;set;}
	public c2g__codaDimension1__c GPShareDim1 {get;set;} // BLL49
    public RecordType recordType {get;set;}
    public Decimal tBalance {get;set;}
    public Decimal invoice_total {get;set;}
    public String dim {get;set;}
    public List<PostingTemplateEntryRule__c> rules = new List<PostingTemplateEntryRule__c>();
    public List<lines> tLines = new List<lines>();
    public List<lines> getLines() {
        return tLines;
    }
    public String documentType = '';    // BLL10a   Proposal, CommercialQuote

    // BLL15d public AggregateResult[] sumTrade;
    public AggregateResult[] sumGap;
    private String templatename = '';  // BLL1a
    public String NewUsedOther {get; private set;} // BLL1a
    public Decimal vehOpenROs {get; private set;} // BLL16a

    // BLL19a - used for pulling GL vehicle costs into template
    dealer__Vehicle_Inventory__c veh;
    Map<Id, c2g__codaGeneralLedgerAccount__c> vehGLAcctMap;
    Set<Id> vehGLAcctIds;
    public Decimal SalesTotal {get;private set;}
    public Decimal COGSTotal {get;private set;}
    public Decimal GrossProfit {get;private set;}
    public List<c2g__codaTransactionLineItem__c> vehTranLines {get;private set;}
    public Decimal vehInvBal {get;private set;}
    public boolean haveLines {get {return tlines.size()>0;} private set;}
    public boolean haveInventory {get {return vehTranLines.size()>0;} private set;}
    public Decimal DealGP {get;private set;}    
    // BLL19a end

    //BLL39d private Decimal inventoryReserve {get;set;} // BLL26a


    public JournalManager(ApexPages.StandardController c) {
        Map<String, Schema.SObjectField> M = Schema.SObjectType.Posting_Entry__c.fields.getMap();
        List<String> af = new List<String>();
        Set<String> fieldnames = M.keySet(); 
        af.addAll(fieldnames);
        af.add('Proposal__r.Name');
        if(!Test.isRunningTest()) c.addFields(af);
        entry = (Posting_Entry__c) c.getRecord();

        if(dim1==null) {
            dim1 = new c2g__codaDimension1__c();
        }

        // BLL19a - load up Vehicle-related GL accounts
        vehGLAcctMap = new Map<Id,c2g__codaGeneralLedgerAccount__c>([
            select Id, Name, c2g__ReportingCode__c, VehicleRequired__c, VehicleComponent__c 
            from c2g__codaGeneralLedgerAccount__c
            where VehicleRequired__c=true and VehicleComponent__c!='Contra'
        ]);
        vehGLAcctIds = vehGLAcctMap.keySet();
        // BLL19a end

        vehOpenROs = 0; // BLL16a
        loadDocument(); // BLL10a
        //BLL10d loadProposalData();
        loadVeh();  // BLL16a

        System.debug('Load Template Rules');

        // BLL7d if(entry.Posting_Template__c!=null) {
        if(entry.Posting_Template__c!=null && tLines.size()==0) { // BLL7a do not clear out lines on save/reload
            lookupTemplateRules();
        } else {  // BLL7a
            calcLines();  // BLL7a
            setInitialControlNumbers();
        }

        System.debug('Load Location');

        // BLL10d - location is loaded in the load{document}Data() call above.
        // Set Dimmension based on Proposal Source
        //BLL10d loc = [Select Id, Financial_Force_Dimension_1__c, Company__c, Name 
        //BLL10d                                         from dealer__Dealer_Location__c 
        //BLL10d                                        where Id=:proposal.dealer__Store_Location__c limit 1];

        //BLL10d if(loc.size()!=1) {
        //BLL10d     throw new PostingException('Error: Proposal '+proposal.Name+' does not have a Store Location set.');
        //BLL10d }

        //BLL10d if(loc[0].Financial_Force_Dimension_1__c==null) {
        if (loc!=null && loc.Financial_Force_Dimension_1__c==null) {        // BLL10a
            throw new PostingException('Error: Please ensure that a Financial Force Dimmension is Set on Location '+loc.Name);  // BLL10c remove [0] subscript on loc
        }

        //BLL10d if(loc[0].Company__c==null) {
        if (loc!=null) {    // BLL10a
            if (loc.Company__c==null) {     // BLL10a
                throw new PostingException('Error: Please ensure that a Financial Force Company is Set on Location '+loc.Name); // BLL10c remove [0] subscript on loc
            } else {  // BLL1a
                try {
                    //BLL10d c2g__codaCompany__c comp = getFFCompany(loc[0].Company__c);  // BLL1a
                    c2g__codaCompany__c comp = getFFCompany(loc.Company__c);  // BLL10a
                } catch (Exception companyerr) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, companyerr.getMessage()));
                }
            }   
        }   // BLL10a

        invoice_total = 0;
        //BLL10d moved  invoice_total = roInvoiceTotal(proposal.dealer__DeliveryRepairOrder__c);    // BLL28c
    }


    // BLL16a
    public void loadVeh() {
        if (entry.Stock__c!=null) {
            try {
                veh = [
                    select Id, Name, New_Used_Other__c, Open_Service_Repair_Orders__c, dealer__Stock_Number__c, dealer__VIN__c  // BLL19c add StockNbr and VIN
                    from dealer__Vehicle_Inventory__c
                    where Id=:entry.Stock__c
                ];
                vehOpenROs = (veh.Open_Service_Repair_Orders__c!=null) ? veh.Open_Service_Repair_Orders__c : 0; // BLL18c
                NewUsedOther = veh.New_Used_Other__c;
            } catch(Exception e) {}
            getVehicleTransactions();   // BLL19a
        }
    }
    // BLL16a end

    // BLL10a
    public PageReference lookupTemplateRules() {
        // BLL16a
        loadVeh();
        if (vehOpenROs!=null && vehOpenROs!=0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Cannot post yet: Vehicle has ' + String.valueOf(vehOpenROs) + ' open repair orders.'));
        }
        // BLL16a
        // BLL20a - open ROs referencing document
        String docOpenROs = documentOpenROs();
        if (!String.isBlank(docOpenROs)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Cannot post yet: ' + documentType + ' has open repair orders: ' + String.valueOf(docOpenROs)));
            return null;            
        }
        // BLL20a end
        if (documentType=='Proposal')   
            lookupTemplateRulesDeal();
        else if (documentType=='Commercial Quote')  
            lookupTemplateRulesCQ(); 

        setInitialControlNumbers();
        calcLines();    // BLL19a

        return null;
    }


    // BLL10a
    // loadDocument
    //----------------------------------
    public void loadDocument() {
        if(entry.Proposal__c!=null) {
            System.debug('Loading proposal data');
            documentType = 'Proposal';  
            entry.CommercialQuote__c=null;
            loadProposalData();
        }

        // BLL10a
        if (entry.CommercialQuote__c!=null) {
            System.debug('Loading commercial quote data');
            documentType = 'Commercial Quote';
            entry.Proposal__c=null; 
            loadCommercialQuoteData();
        }
    }
    // BLL10a end

    
    public PageReference lookupTemplateRulesDeal() {    // BLL10c changed name, appended "Deal" 
        Decimal line_amount = 0;
        tBalance = 0;

        rules.clear();
        tLines.clear();
        //BLL21d invoice_total = roInvoiceTotal(proposal.dealer__DeliveryRepairOrder__c);   // BLL8a moved from constructor, BLL28c 
        invoice_total = roInvoiceTotal(proposal.Id);    // BLL21a
        //BLL39d inventoryReserve = roInvReserveTotal(proposal.Id);  // BLL26a

        System.debug('About to load the rules');
        // If no template is assigned set to blank
        if(entry.Posting_Template__c!=null) {

            // BLL1a - Get template name for use in journal description
            try {
                PostingTemplate__c pt = [select Id, Name from PostingTemplate__c where Id=:entry.Posting_Template__c limit 1];
                templatename = pt.Name;
            } catch(Exception e) {}
            // BLL1a - end

            rules = [
            	select Id, Name, Action__c, General_Ledger_Account__c, General_Ledger_Account__r.Name, Default_Memo__c, FieldName__c, ReverseValue__c	// BLL30c fieldname & reversevalue
            		, LineType__c	// BLL35a
            	from PostingTemplateEntryRule__c 
            	where Posting_Template__c=:entry.Posting_Template__c 
            	order by Page_Order__c ASC 
            	limit 150
            ];

            System.debug('Rules Loaded ');
            // Aggregate Results
            // Trade-In Section
            // BLL15d sumTrade = [
            // BLL15d   Select SUM(Chassis_Allowance__c) chassis, SUM(Conversion_Allowance__c) conversion, SUM(dealer__ACV__c) acv, SUM(dealer__Pay_Off_Amount__c) payoff,
            // BLL15d           SUM(dealer__Trade_Allowance__c) allowance   // BLL8a
            // BLL15d    FROM dealer__Trade_In__c where dealer__Car_Deal__c =: proposal.Id
            // BLL15d ];

            // BLL7a - Trade-ins
            List<dealer__Trade_In__c> trades = [
                select Id, Name, dealer__VIN__c, dealer__Stock_Number__c, Chassis_Allowance__c, Conversion_Allowance__c, dealer__ACV__c, dealer__Pay_Off_Amount__c,
                    Over_Under_Allowance__c, Chassis_ACV__c, Conversion_ACV__c,     // BLL23a
                    dealer__Inventory_Vehicle__c    // BLL15a 
                from dealer__Trade_In__c
                where dealer__Car_Deal__c = :proposal.Id
            ];

            // Gap 
            //BLL7d sumGap = [Select SUM(dealer__Sale_Price__c) gap_sale,
            //BLL7d                   SUM(dealer__Cost__c) gap_cost
            //BLL7d                      FROM dealer__Service_Contract__c where dealer__Car_Deal__c =: proposal.Id];
            // BLL7a - Protection products
            List<dealer__Service_Contract__c> protectionProd = [
                select Type__c, Vendor_Name__c, dealer__Sale_Price__c, dealer__Cost__c
                from dealer__Service_Contract__c
                where dealer__Car_Deal__c = :proposal.Id 
            ]; 
            // BLL38a
            Set<String> ppTypes = new Set<String>();
            for(dealer__Service_Contract__c pp : protectionProd) ppTypes.add(pp.Type__c);
            // BLL38a end

            // BLL18a
            Set<Id> ruleGLs = new Set<Id>();
            for(PostingTemplateEntryRule__c rule : rules) ruleGLs.add(rule.General_Ledger_Account__c);
            Map<Id,c2g__codaGeneralLedgerAccount__c> gls = new Map<Id,c2g__codaGeneralLedgerAccount__c>([
                select Id, Name 
                from c2g__codaGeneralLedgerAccount__c 
                where id in :ruleGLs 
            ]);
            // BLL18a end

			//BLL36a Finance company
			dealer__Finance_Company__c fincomp = null;
			if (proposal.dealer__Finance_Institution_Account__c!=null) {
				try {
					fincomp = [
						select Id, Name, FinanceAccount__c
						from dealer__Finance_Company__c
						where Id=:proposal.dealer__Finance_Institution_Account__c
						limit 1 
					];
				} catch(Exception e) {}
			}
			// Adjust in case finance company is entered as an "Other Payor"
			if (fincomp!=null && fincomp.FinanceAccount__c!=null && fincomp.FinanceAccount__c==proposal.Third_Party_Pay_3__c && proposal.Contract_Amount_Financed__c==proposal.dealer__Deferred_Down_3__c) {
				proposal.Total_Price__c += proposal.dealer__Deferred_Down_3__c;
				proposal.dealer__Deferred_Down_3__c = 0;
			} else if (fincomp!=null && fincomp.FinanceAccount__c!=null && fincomp.FinanceAccount__c==proposal.Third_Party_Pay_2__c && proposal.Contract_Amount_Financed__c==proposal.dealer__Deferred_Down_2__c) {
				proposal.Total_Price__c += proposal.dealer__Deferred_Down_2__c;
				proposal.dealer__Deferred_Down_2__c = 0;
			}
            // BLL36a end

            for(PostingTemplateEntryRule__c rule : rules) {

                System.debug('Rules Loop');
                System.debug(rule);

                //c2g__codaGeneralLedgerAccount__c[] gl = [Select Id, Name from c2g__codaGeneralLedgerAccount__c where id=:rule.General_Ledger_Account__c limit 1];
                c2g__codaGeneralLedgerAccount__c gl = gls.get(rule.General_Ledger_Account__c);
                //BLL18d if(gl.size()==0) {
                if (gl==null) { // BLL18a
                    throw new PostingException('Rule does not have an associated GL Account for '+rule.Action__c);
                } else {
                    // BLL7a handle trades individually
                    if (rule.Action__c.startsWithIgnoreCase('Trade-in')) {
                        System.debug('Trade-ins loop');
                        for(dealer__Trade_In__c trade : trades) {
                            line_amount = 0.00;
                            if (rule.Action__c=='Trade-in Chassis Amount')
                                //BLL23d if (trade.Chassis_Allowance__c!=null && trade.Chassis_Allowance__c>0) { // BLL8a
                                //BLL23d    line_amount = debit(trade.Chassis_Allowance__c);
                                //BLL23d }  else {
                                //BLL23d    line_amount = debit(trade.dealer__ACV__c); // BLL7a
                                //BLL23d }
                                    line_amount = (trade.Chassis_ACV__c!=null) ? debit(trade.Chassis_ACV__c) : debit(trade.dealer__ACV__c); // BLL23a
                            else if (rule.Action__c=='Trade-In Conversion Amount')
                                //BLL23d line_amount = debit(trade.Conversion_Allowance__c);
                                line_amount = debit(trade.Conversion_ACV__c);
                            else if (rule.Action__c=='Trade-in Payoff')
                                line_amount = credit(trade.dealer__Pay_Off_Amount__c);
                            // BLL23a
                            else if (rule.Action__c=='Trade-in Over-Allowance') {
                                line_amount = debit(trade.Over_Under_Allowance__c);
                            }
                            // BLL23a end
                            tBalance += line_amount;
    
                            lines line = new lines();
                            if (rule.LineType__c!=null) line.jline.c2g__LineType__c = rule.LineType__c;	// BLL38a
                            line.amount = line_amount;  // Associate the related data
                            line.memo = rule.Default_Memo__c;
                            line.action = rule.Action__c;
                            line.accountName = gl.Name; //BLL18c gl[0].Name;
                            line.account = gl;  //BLL18c  gl[0];
                            //BLL11d line.division = dim1.Name;
                            line.jline.c2g__Dimension1__c = dim1.Id;    // BLL11a
                            line.template = rule;
                            //if (rule.Action__c=='Trade-in Chassis Amount') {  // BLL8d
                                line.VIN = trade.dealer__VIN__c;
                                line.StockNbr = trade.dealer__Stock_Number__c; 
                            //}  // BLL8d 
                            line.Description = (trade.dealer__Stock_Number__c==null?'':'(' + trade.dealer__Stock_Number__c + ') ')
                                + trade.Name + ' - ' + rule.Action__c;  // BLL9a
                            line.Vehicle = trade.dealer__Inventory_Vehicle__c;  // BLL15a
                            tLines.add(line);
                        }
                    } else if (rule.Action__c.startsWithIgnoreCase('Extended Warranty')) {
                        processProtection(protectionProd, rule, 'Service Contract', gl);    // BLL18d gl[0]);
                    } else if (rule.Action__c.startsWithIgnoreCase('GAP Insurance')) {
                        processProtection(protectionProd, rule, 'GAP', gl); // BLL18d gl[0]);
                    } else if (rule.Action__c.startsWithIgnoreCase('Roadside Assistance')) {
                        processProtection(protectionProd, rule, 'Roadside Protection', gl); // BLL18d gl[0]);
                    } else if (rule.Action__c.startsWithIgnoreCase('Diamon Fusion') || rule.Action__c.startsWith('Diamond Fusion')) {
                        processProtection(protectionProd, rule, 'Diamond Fusion', gl);  // BLL18d gl[0]);
                    } else if (rulePpType(rule.Action__c, ppTypes)!=null) {	// BLL38a - other protection products
                    	processProtection(protectionProd, rule, rulePpType(rule.Action__c,ppTypes), gl);	// BLL38a
                    } else if (rule.Action__c=='Commission Accrual' ||rule.Action__c=='Commission Expense') {
                        processCommissions(rule, gl);   // BLL18d gl[0]);
                    } else {
                    // BLL7a end
						// BLL30a
						System.debug(rule.FieldName__c);
						if (!String.isBlank(rule.FieldName__c)) {
							line_amount = (Decimal) proposal.get(rule.FieldName__c.toLowerCase());
							if (line_amount==null) line_amount = 0.00;
							if (rule.ReverseValue__c) line_amount = -line_amount;
							if (line_amount!=null) line_amount = line_amount.setScale(2);
						} else {
						// BLL30a
                        	line_amount = actionTotal(rule.Action__c);
						}	// BLL30a
    
    					// BLL30a
    					if (rule.Action__c=='GPC - Government Price Concession (with code)' && proposal.ReleasingDealer__c!=null)
    						line_amount = 0;
    					// BLL30a end
    
                        tBalance += line_amount!=null ? line_amount : 0;
    
                        lines line = new lines();
						if (rule.LineType__c!=null) line.jline.c2g__LineType__c = rule.LineType__c;	// BLL38a
                        line.amount = line_amount;  // Associate the related data
                        line.memo = rule.Default_Memo__c;
                        line.action = rule.Action__c;
                        line.accountName = gl.Name; // BLL18d gl[0].Name;
                        line.account = gl;  // BLL18d gl[0];
                        //BLL11d line.division = dim1.Name;
                        line.jline.c2g__Dimension1__c = dim1.Id;    // BLL11a
						// BLL49
						if (rule.Action__c=='GP Sharing Vehicle Home' && GPShareDim1!=null) {
							line.jline.c2g__Dimension1__c = GPShareDim1.Id;
						}
						// BLL49 end
                        line.template = rule;
                        
                        // BLL35a Assign account lookup 
				        Id arId = null;
			            arId = proposal.dealer__Buyer__c;
            			if(proposal.ReleasingDealer__c!=null) arId=proposal.ReleasingDealer__c;

            			if(line.action == 'Account Receivable' || line.action=='Deposit' || line.action=='Downpayment') {
            			    line.jline.c2g__LineType__c   =   'Account - Customer';
            			    line.jline.c2g__Account__c = arId;
			            } 
            			if(line.action == 'Finance Company' && proposal.dealer__Finance_Institution_Account__c!=null && fincomp!=null && proposal.Funding_Option__c=='Financed') {	// BLL36c, BLL41c  
            				line.jline.c2g__LineType__c = 'Account - Customer';
 							//BLL36d try {
            				//BLL36d	dealer__Finance_Company__c fincomp = [select Id, Name, FinanceAccount__c
            				//BLL36d		from dealer__Finance_Company__c
            				//BLL36d		where Id=:proposal.dealer__Finance_Institution_Account__c
            				//BLL36d		limit 1 
            				//BLL36d	];
			                    line.jline.c2g__Account__c = fincomp.FinanceAccount__c; 
 							//BLL36d} catch(Exception e) {}
			            }
			            // Apply the 3rd party Payor to the line
            			if(line.action == '3rd Party/Government Receivable') {
                			line.jline.c2g__LineType__c = 'Account - Customer';  
			                line.jline.Third_Party_Payor__c = proposal.Third_Party_Pay_1__c;
            			    line.jline.c2g__Account__c = proposal.Third_Party_Pay_1__c;
          				}
			            // BLL7a - split funding sources to separate journal lines
            			if(line.action == 'Third Party 1') {
                			line.jline.c2g__LineType__c = 'Account - Customer';
                			line.jline.Third_Party_Payor__c = proposal.Third_Party_Pay_1__c;
                			line.jline.c2g__Account__c = proposal.Third_Party_Pay_1__c;
            			}
            			if(line.action == 'Third Party 2') {
                			line.jline.c2g__LineType__c = 'Account - Customer';
                			line.jline.Third_Party_Payor__c = proposal.Third_Party_Pay_2__c;
                			line.jline.c2g__Account__c = proposal.Third_Party_Pay_2__c;
            			}
			            if(line.action == 'Other Payor')   {
            			    line.jline.c2g__LineType__c = 'Account - Customer';
                    		line.jline.Third_Party_Payor__c = proposal.Third_Party_Pay_3__c;
            				line.jline.c2g__Account__c = proposal.Third_Party_Pay_3__c;
			            }
            			if(line.action == 'Government Receivable') {
            			    line.jline.c2g__LineType__c = 'Account - Customer';
            			    line.jline.Third_Party_Payor__c = proposal.dtmob__Auto_Grant_Payor__c;    // BLL28c proposal.Auto_Grant_Payee__c;
            			    line.jline.c2g__Account__c = proposal.dtmob__Auto_Grant_Payor__c;     // BLL28c proposal.Auto_Grant_Payee__c;
            			}
						// BLL35a end   
						// BLL38a
						if (rule.Action__c=='Loan Acquisition - Payable'  && proposal.Funding_Option__c=='Financed' && fincomp!=null) line.jline.c2g__Account__c = fincomp.FinanceAccount__c;
						if (rule.Action__c=='Lease Acquisition - Payable' && proposal.Funding_Option__c=='Financed' && fincomp!=null) line.jline.c2g__Account__c = fincomp.FinanceAccount__c;
						if (rule.Action__c=='Reimbursed GAP Cost' && proposal.Funding_Option__c=='Financed' && fincomp!=null) line.jline.c2g__Account__c = fincomp.FinanceAccount__c;	// BLL42a
						if (line.jline.c2g__LineType__c.startsWith('Account') && line.jline.c2g__Account__c==null)
							line.jline.c2g__Account__c = arId;	// BLL38a                      
                        
                        tLines.add(line);
                    } // BLL7a
                }
            }

        } else {
            rules = new List<PostingTemplateEntryRule__c>();
            tLines.add(new lines());
        }

        lines blank_line = new lines();
        //BLL11d blank_line.division =   dim1.name;
        blank_line.jline.c2g__Dimension1__c = dim1.Id;  // BLL11a
        blank_line.action   =   'Misc.';
        blank_line.template = new PostingTemplateEntryRule__c();
        tLines.add(blank_line);
        blank_line = new lines();
        //BLL11d blank_line.division =   dim1.name;
        blank_line.jline.c2g__Dimension1__c = dim1.Id;  // BLL11a
        blank_line.action   =   'Misc.';
        blank_line.template = new PostingTemplateEntryRule__c();
        tLines.add(blank_line);
        blank_line = new lines();
        //BLL11d blank_line.division =   dim1.name;
        blank_line.jline.c2g__Dimension1__c = dim1.Id;  // BLL11a
        blank_line.action   =   'Misc.';
        blank_line.template = new PostingTemplateEntryRule__c();
        tLines.add(blank_line);
        blank_line = new lines();
        //BLL11d blank_line.division =   dim1.name;
        blank_line.jline.c2g__Dimension1__c = dim1.Id;  // BLL11a
        blank_line.action   =   'Misc.';
        blank_line.template = new PostingTemplateEntryRule__c();
        tLines.add(blank_line);

        return null;
    }

    // BLL7a
    public void processCommissions(PostingTemplateEntryRule__c rule, c2g__codaGeneralLedgerAccount__c gl) {
        Decimal line_amount = null;
        
        if (proposal.Commission__c==null) proposal.Commission__c = 0.00;
        if (proposal.Commission_2__c==null) proposal.Commission_2__c = 0.00;
        if (proposal.Commission_3__c==null) proposal.Commission_3__c = 0.00;
        if (proposal.Commission_4__c==null) proposal.Commission_4__c = 0.00;

        if (proposal.Flat__c==null) proposal.Flat__c = 0.00;
        if (proposal.Commission_Flat_2__c==null) proposal.Commission_Flat_2__c = 0.00;
        if (proposal.Commission_Flat_3__c==null) proposal.Commission_Flat_3__c = 0.00;
        if (proposal.Commission_Flat_4__c==null) proposal.Commission_Flat_4__c = 0.00;

        if (proposal.Commission_FI_1__c==null) proposal.Commission_FI_1__c = 0.00;
        if (proposal.Commission_FI_2__c==null) proposal.Commission_FI_2__c = 0.00;
        if (proposal.Commission_FI_3__c==null) proposal.Commission_FI_3__c = 0.00;
        if (proposal.Commission_FI_4__c==null) proposal.Commission_FI_4__c = 0.00;

        Decimal commission1 = proposal.Commission__c + proposal.Flat__c + proposal.Commission_FI_1__c;
        Decimal commission2 = proposal.Commission_2__c + proposal.Commission_Flat_2__c + proposal.Commission_FI_2__c;
        Decimal commission3 = proposal.Commission_3__c + proposal.Commission_Flat_3__c + proposal.Commission_FI_3__c;
        Decimal commission4 = proposal.Commission_4__c + proposal.Commission_Flat_4__c + proposal.Commission_FI_4__c;

        // Commission 1
        if (commission1!=0) {
            line_amount = 0.00;
            if (rule.action__c=='Commission Accrual') {
                line_amount = credit(commission1);
            } else if (rule.Action__c=='Commission Expense') {
                line_amount = debit(commission1);
            }
            tBalance += line_amount;
            lines line = new lines();
			if (rule.LineType__c!=null) line.jline.c2g__LineType__c = rule.LineType__c;	// BLL38a
            line.amount = line_amount; 
            line.memo = rule.Default_Memo__c;
            line.action = rule.Action__c;
            line.accountName = gl.Name;
            line.account = gl;
            //BLL11d line.division =   dim1.name;
            line.jline.c2g__Dimension1__c = dim1.Id;    // BLL11a
            line.template = rule;
            line.Salesperson = proposal.Commission_Employee_1__c;
            System.debug('Commission 1 salesperson ' + line.Salesperson);
            tLines.add(line);
        }

        // Commission 2
        if (commission2!=0) {
            line_amount = 0.00;
            if (rule.action__c=='Commission Accrual') {
                line_amount = credit(commission2);
            } else if (rule.Action__c=='Commission Expense') {
                line_amount = debit(commission2);
            }
            tBalance += line_amount;
            lines line = new lines();
			if (rule.LineType__c!=null) line.jline.c2g__LineType__c = rule.LineType__c;	// BLL38a
            line.amount = line_amount; 
            line.memo = rule.Default_Memo__c;
            line.action = rule.Action__c;
            line.accountName = gl.Name;
            line.account = gl;
            //BLL11d line.division =   dim1.name;
            line.jline.c2g__Dimension1__c = dim1.Id;    // BLL11a
            line.template = rule;
            line.Salesperson = proposal.Commission_Employee_2__c;
            System.debug('Commission 2 salesperson ' + line.Salesperson);
            tLines.add(line);
        }


        // Commission 3
        if (commission3!=0) {
            line_amount = 0.00;
            if (rule.action__c=='Commission Accrual') {
                line_amount = credit(commission3);
            } else if (rule.Action__c=='Commission Expense') {
                line_amount = debit(commission3);
            }
            tBalance += line_amount;
            lines line = new lines();
			if (rule.LineType__c!=null) line.jline.c2g__LineType__c = rule.LineType__c;	// BLL38a
            line.amount = line_amount; 
            line.memo = rule.Default_Memo__c;
            line.action = rule.Action__c;
            line.accountName = gl.Name;
            line.account = gl;
            //BLL11d line.division =   dim1.name;
            line.jline.c2g__Dimension1__c = dim1.Id;    // BLL11a
            line.template = rule;
            line.Salesperson = proposal.Commission_Employee_3__c;
            System.debug('Commission 3 salesperson ' + line.Salesperson);
            tLines.add(line);
        }


        // Commission 4
        if (commission4!=0) {
            line_amount = 0.00;
            if (rule.action__c=='Commission Accrual') {
                line_amount = credit(commission4);
            } else if (rule.Action__c=='Commission Expense') {
                line_amount = debit(commission4);
            }
            tBalance += line_amount;
            lines line = new lines();
			if (rule.LineType__c!=null) line.jline.c2g__LineType__c = rule.LineType__c;	// BLL38a
            line.amount = line_amount; 
            line.memo = rule.Default_Memo__c;
            line.action = rule.Action__c;
            line.accountName = gl.Name;
            line.account = gl;
            //BLL11d line.division =   dim1.name;
            line.jline.c2g__Dimension1__c = dim1.Id;    // BLL11a
            line.template = rule;
            line.Salesperson = proposal.Commission_Employee_4__c;
            System.debug('Commission 4 salesperson ' + line.Salesperson);
            tLines.add(line);
        }
        
    }
    
    
    // BLL38a
    public String rulePpType(String actn, Set<String> ppTypes) {
    	String rtnType = null;
    	for(String ppt : new List<String>(ppTypes)) 
    		if (actn.startsWith(ppt)) rtnType = ppt;
    	return rtnType;
    }
    // BLL38a end
    
    public void processProtection(List<dealer__Service_Contract__c> protectionProd,
                PostingTemplateEntryRule__c rule, String type, c2g__codaGeneralLedgerAccount__c gl) {
        Decimal line_amount = null;
        System.debug('Protection products loop');
        //Vendor_Name__c, dealer__Sale_Price__c, dealer__Cost__c
        for(dealer__Service_Contract__c prot : protectionProd) {
            // Only do the ones that match this type
            if (prot.Type__c == type) {
                line_amount = 0.00;
                if (rule.Action__c.contains('Sales')) 
                    line_amount = credit(prot.dealer__Sale_Price__c); 
                else if (rule.Action__c.contains('COGS') || rule.Action__c.contains('GOGS')) {
                    line_amount = debit(prot.dealer__Cost__c);
                    if (type=='GAP' && proposal.Funding_Option__c=='Financed' && proposal.FinanceCompanyReimbursement__c!=null && proposal.FinanceCompanyReimbursement__c!=0) line_amount -= proposal.FinanceCompanyReimbursement__c;	// BLL42a
                } else if (rule.Action__c.contains('Payable'))
                    line_amount = credit(prot.dealer__Cost__c);
                tBalance += line_amount;
    
                lines line = new lines();
				if (rule.LineType__c!=null) line.jline.c2g__LineType__c = rule.LineType__c;	// BLL38a
                line.amount = line_amount;  
                line.memo = rule.Default_Memo__c;
                line.action = rule.Action__c;
                line.accountName = gl.Name;
                line.account = gl;
                //BLL11d line.division =   dim1.name;
                line.jline.c2g__Dimension1__c = dim1.Id;    // BLL11a
                line.template = rule;
                line.VendorId = prot.Vendor_Name__c;
                // BLL35a
            	if(line.VendorId != null) {
            	    line.jline.Vendor_Name__c = line.VendorId;
            	    line.jline.c2g__Account__c = line.VendorId;
            	    line.jline.c2g__LineType__c = 'Account - Vendor';
            	}
            	// BLL35a end
                
                tLines.add(line);
            }
        }
    }


    // BLL10a
    // DealerLocation
    //-------------------------------
    public dealer__Dealer_Location__c DealerLocation(Id locId) {
         dealer__Dealer_Location__c loc = null;
         try {
            loc = [
                Select Id, Name, Financial_Force_Dimension_1__c, Company__c, Company__r.Name
                from dealer__Dealer_Location__c
                where Id=:locId
                limit 1
            ];
         } catch(Exception e) {}
         return loc;
    }
    
    // Dimension1
    //--------------------------------
    public c2g__codaDimension1__c Dimension1(Id dim1Id) {
        c2g__codaDimension1__c dim1 = null;
        if (dim1Id!=null) {
            try {
                dim1 = [
                    select Id, Name from c2g__codaDimension1__c 
                    where Id=:dim1Id 
                    limit 1
                ];
            } catch(Exception e) { throw new PostingException('Location ' + ((loc!=null) ? loc.Name : '') + ' must have the Financial Force Dimmension 1 field set to before attempting to Post'); }
        }
        return dim1;
    }

    // loadCommercialQuoteData
    //-------------------------------
    public void loadCommercialQuoteData() {
        System.debug(entry.CommercialQuote__c);

        // Load all fields and a few others via reference from commercial quote
        Map<String, Schema.SObjectField> fieldMap =  Schema.CommercialQuote__c.SObjectType.getDescribe().fields.getMap();
        List<String> allfields = new List<String>();
        for(string f : fieldMap.keySet()) {
            if (fieldMap.get(f).getDescribe().isAccessible()) allfields.add(f);
        }
        String fieldString = String.join(allfields, ', ');
        String cqSOQL = 'select ' + fieldString + ', VehicleInventory__r.Name, VehicleInventory__r.New_Used_Other__c, VehicleInventory__r.dealer__Stock_Number__c, '
            + 'VehicleInventory__r.Open_Service_Repair_Orders__c, ' // BLL16a
            + 'LienHolder__r.FinanceAccount__c '
            + 'from CommercialQuote__c '
            + 'where Id=\'' + entry.CommercialQuote__c + '\' '
            + 'limit 1'; 
        cq = Database.query(cqSOQL);

        NewUsedOther = cq.VehicleInventory__r.New_Used_Other__c;
        vehOpenROs = (cq.VehicleInventory__r.Open_Service_Repair_Orders__c!=null) ? cq.VehicleInventory__r.Open_Service_Repair_Orders__c : 0;   // BLL16a
        if (entry.Stock__c==null) {entry.Stock__c = cq.VehicleInventory__c;}
        RecordType=null; 
        entry.Location__c = cq.Location__c; // BLL10a
        loc = DealerLocation(cq.Location__c);
        dim1 = loc!=null ? Dimension1(loc.Financial_Force_Dimension_1__c) : null;
        // Fix nulls
        if (cq.Deposit__c==null) cq.Deposit__c = 0.00;  // BLL14a
        DealGP = cq.Total_Gross_Profit__c; // BLL19a
    }
    
    // lookupTemplateRulesCQ
    //------------------------------------
    public PageReference lookupTemplateRulesCQ() {

        Decimal line_amount = null;
        tBalance = 0;
        rules.clear();
        tLines.clear();

        // Need summary of option costs/prices/discounts by whether it was locked or not
        List<AggregateResult> cqo = [
            select LockedOption__c, sum(Extended_Discount__c) sumdiscount, sum(Extended_Total__c) sumprice, sum(Extended_Cost__c) sumcost 
            from CommercialQuoteLine__c
            where Commercial_Quote__c=:cq.Id
            group by LockedOption__c
        ];
        Map<String,AggregateResult> cqomap = new Map<String,AggregateResult>();
        for(AggregateResult r : cqo) { 
            boolean locked = false;
            try {
                locked = (boolean) r.get('LockedOption__c');
            } catch(Exception e) {}
            if (locked==null) locked = false; 
            String key = locked ? '1' : '0'; 
            cqomap.put(key, r);
        }


        //BLL21d invoice_total = roInvoiceTotal(cq.ServiceRepairOrder__c);
        invoice_total = roInvoiceTotal(cq.Id);  // BLL21a
        //BLL39d inventoryReserve = roInvReserveTotal(cq.Id);    // BLL26a

        System.debug('About to load the rules');
        // If no template is assigned set to blank
        if(entry.Posting_Template__c!=null) {

            // Get template name for use in journal description
            try {
                PostingTemplate__c pt = [select Id, Name from PostingTemplate__c where Id=:entry.Posting_Template__c limit 1];
                templatename = pt.Name;
            } catch(Exception e) {}

            rules = [
                select Id, Name, Action__c, General_Ledger_Account__c, General_Ledger_Account__r.Name, 
                    Default_Memo__c, FieldName__c, ReverseValue__c, LineType__c	// BLL39a add linetype
                from PostingTemplateEntryRule__c 
                where Posting_Template__c=:entry.Posting_Template__c 
                order by Page_Order__c ASC 
                limit 150
            ];

            System.debug('Rules Loaded ');

            Set<Id> glAcctIds = new Set<Id>();
            for(PostingTemplateEntryRule__c rule : rules) {
                if (rule.General_Ledger_Account__c!=null) glAcctIds.add(rule.General_Ledger_Account__c);
            }
            Map<Id,c2g__codaGeneralLedgerAccount__c> glacctmap = new Map<Id,c2g__codaGeneralLedgerAccount__c>([
                select Id, Name, c2g__ReportingCode__c
                from c2g__codaGeneralLedgerAccount__c
                where Id in :glAcctIds
            ]);

            // StockVeh LockedOption__c=true for conversion; false for added equip
            // Non-stock LockedOption__c=false for conversion; n/a for added equip
            boolean stockveh = cq.VehicleInventory__c!=null;
            String ConvKey = stockveh ? '1' : '0';
            String AddedKey = stockveh ? '0' : '1';
            
            for(PostingTemplateEntryRule__c rule : rules) {

                System.debug('Rules Loop');
                System.debug(rule);
                line_amount = null;

                c2g__codaGeneralLedgerAccount__c gla = glacctmap.get(rule.General_Ledger_Account__c);
                if(gla==null) {
                    throw new PostingException('Rule does not have an associated GL Account for '+rule.Action__c);
                } else {
                    if (!String.isBlank(rule.FieldName__c))
                        line_amount = !String.isBlank(rule.FieldName__c) ? (Decimal) cq.get(rule.FieldName__c.toLowerCase()) : null;

                    // needs special coding...
                    if (line_amount==null) {
                        // Receivable
                        if (rule.Action__c=='Account Receivable' || rule.Action__c=='Other Payor') {
                            line_amount = cq.Total_After_Discounts_Rebates__c - cq.Deposit__c;
                            if (cq.TypeOfSale__c=='Customer Owned') line_amount -= cq.Chassis_Price__c; // BLL13a
                            if (rule.Action__c=='Other Payor' && cq.ReleasingDealer__c!=null)
                                //BLL17d line_amount = cq.Total__c - cq.Deposit__c - cq.Chassis_Price__c;
                                line_amount = cq.Total__c - cq.Deposit__c - cq.Chassis_Price__c + cq.Freight_Amount__c; // BLL17a 
                                //line_amount -= cq.Chassis_Price__c;
                            // chassis mark-up to releasing dealer
                            if (cq.TypeOfSale__c!='Customer Owned' && cq.ReleasingDealer__c!=null) {
                                line_amount += (cq.Chassis_Price__c - cq.Chassis_Cost__c);
                                if (cq.ReleasingDealerCollectsTax__c) line_amount -= cq.Tax__c; // BLL22a
                            }
                        }
                        
                        // Commercial units now owned (we don't collect chassis amt)
                        if (rule.Action__c=='Chassis Mark-UP' && cq.ReleasingDealer__c!=null) {
                            line_amount = -(cq.Chassis_Price__c - cq.Chassis_Cost__c);
                        }
                        if (rule.Action__c=='Chassis Mark-UP' && cq.TypeOfSale__c=='Customer Owned') line_amount = 0.00;    // BLL13a
                       
                        // Conversion...
                        if (rule.Action__c=='Conversion Sales') {
                            AggregateResult r = cqomap.get(ConvKey);
                            if (r!=null)
                                line_amount = (Decimal) r.get('sumprice');
                        }
                        if (rule.Action__c=='Conversion Cost') {
                            AggregateResult r = cqomap.get(ConvKey);
                            if (r!=null)
                                line_amount = (Decimal) r.get('sumcost');
                        }
                        if (rule.Action__c=='Conversion Inventory') {
                            AggregateResult r = cqomap.get(ConvKey);
                            if (r!=null)
                                line_amount = (Decimal) r.get('sumcost');
                        }

                        // Added to stock unit...
                        if (rule.Action__c=='Additional Equipment Sales') {
                            AggregateResult r = cqomap.get(AddedKey);
                            if (r!=null)
                                line_amount = (Decimal) r.get('sumprice');
                        }
                        if (rule.Action__c=='Additional Equipment Cost') {
                            AggregateResult r = cqomap.get(AddedKey);
                            if (r!=null) line_amount = invoice_total;
                                //line_amount = (Decimal) r.get('sumcost');
                        }
                        if (rule.Action__c=='Additional Equipment Inventory') {
                            AggregateResult r = cqomap.get(AddedKey);
                            if (r!=null) line_amount = invoice_total;
                                //line_amount = (Decimal) r.get('sumcost');
                        }
                    }

                    // Special cases where the amount goes on either one line or a different one (but not both/all)
                    if (rule.Action__c=='Account Receivable' && (cq.ReleasingDealer__c!=null || cq.LienHolder__c!=null)) line_amount = 0;
                    if (rule.Action__c=='Other Payor' && cq.ReleasingDealer__c==null && cq.LienHolder__c==null) line_amount = 0;

                    // If we don't own chassis, we don't collect the amount or book the cost
                    if ((rule.Action__c=='Chassis Sale' || rule.Action__c=='Chassis Cost' || rule.Action__c=='Chassis Inventory')
                        && cq.ReleasingDealer__c!=null) {
                        line_amount = 0;
                    }
                    // All rebates are chassis related and must be zeroed out if there is a releasing dealer
                    if ((rule.Action__c=='Additional MFG Rebate'  || rule.Action__c=='Rebates/Incentives' 
                        || rule.Action__c=='GPC - Government Price Concession (with code)'
                        || rule.Action__c=='Doc Fee')   // BLL17c add doc fee
                        && (cq.ReleasingDealer__c!=null || cq.TypeOfSale__c!='Used')) { // BLL13c add || cq.TypeOfSale__c!='Used'
                        line_amount = 0;
                    }

                    // BLL22a
                    if ((rule.Action__c=='Sales Tax Payable' && cq.ReleasingDealer__c!=null && cq.ReleasingDealerCollectsTax__c)) {
                        line_amount = 0;
                    }
                    // BLL22a end

					//BLL39d 
                    // BLL26a
                    //BLL39d if (rule.Action__c=='Inventory Reserve') {
                    //BLL39d     line_amount = inventoryReserve;
                    //BLL39d }
                    //BLL39d if (rule.Action__c=='Service Billing') {
                    //BLL39d     line_amount = -inventoryReserve;
                    //BLL39d }
                    // BLL26a end

                    if (line_amount==null) line_amount = 0.00;
                    if (rule.ReverseValue__c==true && line_amount!=null) line_amount = -line_amount;

                    tBalance += line_amount;
                    lines line = new lines();
                    line.amount = line_amount; 
                    line.memo = rule.Default_Memo__c;
                    line.action = rule.Action__c;
                    line.accountName = gla.Name;
                    line.account = gla;
                    //BLL11d line.division = dim1!=null ? dim1.Name : null;
                    line.jline.c2g__Dimension1__c = dim1.Id;    // BLL11a
                    line.template = rule;
                    tLines.add(line);
                }
            }

        } else {
            rules = new List<PostingTemplateEntryRule__c>();
            //tLines.add(new lines());
        }

        // Add 4 blank misc. lines to screen
        String dim1name = (dim1!=null) ? dim1.Name : null;
        for(Integer i = 0; i<4; ++i) tLines.add(new lines(dim1.Id /*dim1name*/, 'Misc.', new PostingTemplateEntryRule__c()));

        return null;
    }
    // BLL10a end



    public ApexPages.PageReference save() {
        // BLL10a
        loadDocument();
        entry.Location__c = loc!=null ? loc.Id : entry.Location__c; // BLL10a
        // BLL10a end
        loadVeh(); // BLL16a
        try {
            // Simulate standard controller's save method
            upsert(entry);
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
        return null;  // stay on page
    }
    // BLL7a end
    

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

    public void calcLines() {
        tBalance = 0;
        for(lines l : tLines) {
            tBalance+= (l.amount==null) ? 0.00 : l.amount;  // BLL - fix for null during test
        }
        calculateGP();  // BLL19a
    }

    // BLL21d
    //public Decimal roInvoiceTotal(String roId) {
    //    dealer__Service_Repair_Order__c[] ro = [Select Id, dealer__Internal_Charges__c from dealer__Service_Repair_Order__c where Id=:roId limit 1];
    //
    //    if(ro.size()==1) {
    //        if(ro[0].dealer__Internal_Charges__c != null) {
    //            return ro[0].dealer__Internal_Charges__c; 
    //        }
    //    }
    //
    //    return 0;
    //}
    // BLL21d end
    // BLL21a
    public Decimal roInvoiceTotal(Id docId) {
        Decimal total;
        List<AggregateResult> ar;
        // ROs referencing a deal
        if (Schema.dealer__Deal__c.SObjectType == docId.getSObjectType()) {
            ar = [
                select sum(dealer__Line_Total__c) linetotal
                from dealer__Service_Job__c
                where dealer__Service_Repair_Order__r.Deal__c = :docId
                  and Payment_Method__r.Payment_Type__c = 'I'
                  and Payment_Method__r.Name not in ('GRUV','GRNV','MCEO')
            ];
        }
        // ROs referencing a quote
        if (Schema.CommercialQuote__c.SObjectType == docId.getSObjectType()) {
            ar = [
                select sum(dealer__Line_Total__c) linetotal
                from dealer__Service_Job__c
                where dealer__Service_Repair_Order__r.CommercialQuote__c = :docId
                  and Payment_Method__r.Payment_Type__c = 'I'
                  and Payment_Method__r.Name not in ('GRUV','GRNV','MCEO')
            ];
        }
        // Total of internal charges (not get-ready (GRNV,GRUV) or MCEO)
        if (ar!=null && ar.size()>0) total=(Decimal) ar[0].get('linetotal');
        if (total==null) total = 0;
        return total;
    }
    // BLL21a end

    // BLL26a - get total inventory reserve
    //BLL39d public Decimal roInvReserveTotal(Id docId) {
    //BLL39d     Decimal total = 0.00;
    //BLL39d     Id vehId;
    //BLL39d     List<dealer__Service_Job__c> ar=new List<dealer__Service_Job__c>();
    //BLL39d     // Vehicle from Deal
    //BLL39d     if (Schema.dealer__Deal__c.SObjectType == docId.getSObjectType()) {
    //BLL39d         dealer__Deal__c d = [select Id, Name, dealer__Vehicle__c from dealer__Deal__c where Id=:docId];
    //BLL39d         vehId = d.dealer__Vehicle__c;
    //BLL39d     }
    //BLL39d     // Vehicle from Quote
    //BLL39d     if (Schema.CommercialQuote__c.SObjectType == docId.getSObjectType()) {
    //BLL39d         CommercialQuote__c q = [select Id, Name, VehicleInventory__c from CommercialQuote__c where Id=:docId];
    //BLL39d         vehId = q.VehicleInventory__c;
    //BLL39d     }
    //BLL39d     // ROs referencing this vehicle...
    //BLL39d     if (vehId!=null)
    //BLL39d         ar = [
    //BLL39d             select dealer__Service_Repair_Order__c, dealer__Service_Repair_Order__r.InternalLaborRate__c, dealer__Labor_Charges__c, dealer__Actual_Time__c
    //BLL39d             from dealer__Service_Job__c
    //BLL39d             where dealer__Service_Repair_Order__r.dealer__Vehicle_Inventory__c = :vehId     //dealer__Service_Repair_Order__r.Deal__c = :docId *or* dealer__Service_Repair_Order__r.CommercialQuote__c = :docId
    //BLL39d             and Payment_Method__r.Payment_Type__c = 'I'
    //BLL39d             and Payment_Method__r.Name in ('GRUV','GRNV')
    //BLL39d         ];
    //BLL39d     
    //BLL39d     for(dealer__Service_Job__c j : ar) {
    //BLL39d         Decimal incr = j.dealer__Labor_Charges__c != null ? j.dealer__Labor_Charges__c : 0.00;
    //BLL39d         if (incr!=0) {	// BLL37a
	//BLL39d             if (j.dealer__Actual_Time__c!=null && j.dealer__Service_Repair_Order__c!=null && j.dealer__Service_Repair_Order__r.InternalLaborRate__c!=null) incr -= (j.dealer__Actual_Time__c * j.dealer__Service_Repair_Order__r.InternalLaborRate__c);
    //BLL39d 	        if (j.dealer__Service_Repair_Order__r.InternalLaborRate__c!=null && j.dealer__Service_Repair_Order__r.InternalLaborRate__c!=0) total += incr.setScale(2);
    //BLL39d         }	// BLL37a
    //BLL39d     }
    //BLL39d     
    //BLL39d     return total;
    //BLL39d }
    // BLL26a end


    public Decimal actionTotal(String actionName) {	

        Decimal ret_val = 0;
		System.debug(actionName);
            // Get the RO data and place under additional equipment cost 4225 DR ('Additional Equipment Cost')
            if(actionName == 'Additional Equipment Cost' && proposal.dealer__DeliveryRepairOrder__c != null) {  // BLL28c
                ret_val = debit(invoice_total);
            }
            if(actionName == 'Additional Equipment Inventory' && proposal.dealer__DeliveryRepairOrder__c != null) { // BLL28c
                ret_val = credit(invoice_total);
            }            

            if(actionName == 'Account Receivable') { 
                //BLL27d ret_val = debit(proposal.Total_Price__c);
                // BLL43d ret_val = proposal.Total_Price__c;  // BLL27a
                ret_val = proposal.TotalDueUponDelivery__c;	// BLL43a
                // BLL8: Remove added code because now that the trade allowance field is updating, it's already
                // subtracted from Total_Price__c!
                // BLL8a - reduce by trade allowance (or acv if allowance is missing)
                //Decimal trade_allowance = credit((Decimal)sumTrade[0].get('allowance'));
                //Decimal trade_acv = credit((Decimal)sumTrade[0].get('acv'));
                //if (trade_allowance!=0) {
                //  ret_val += trade_allowance;
                //else {
                //  ret_val += trade_acv;
                //}
                // BLL8a end
                if (proposal.ReleasingDealer__c!=null) ret_val -= proposal.Chassis_Cost__c;	// BLL30a
                //if (proposal.ReleasingDealer__c!=null) ret_val -= proposal.dealer__Sales_Tax__c;	// BLL30a, BLL34d
                if (proposal.ReleasingDealer__c!=null) ret_val -= proposal.dealer__Total_Fees__c;	// BLL34a
				if (proposal.ReleasingDealer__c!=null) ret_val += proposal.Government_Price_Concession__c;
				if (proposal.ReleasingDealer__c!=null) ret_val += proposal.dealer__Rebate__c + proposal.Rebate_2__c + proposal.Rebate_3__c;	// BLL32a
            }
            if(actionName == '3rd Party/Government Receivable') { ret_val = debit(proposal.dealer__Deferred_Down_1__c) 
                                                                            +debit(proposal.dealer__Deferred_Down_2__c)
                                                                            +debit(proposal.dealer__Deferred_Down_3__c); }
            if(actionName == '3rd Party/Government Receivable') { ret_val = debit(proposal.Grants_Government_Assistance__c); }
            // BLL7a - Replacing the above
            if(actionName == 'Third Party 1') {ret_val = debit(proposal.dealer__Deferred_Down_1__c); }
            if(actionName == 'Third Party 2') {ret_val = debit(proposal.dealer__Deferred_Down_2__c); }
            if(actionName == 'Other Payor')   {ret_val = debit(proposal.dealer__Deferred_Down_3__c); }
            if(actionName == 'Government Receivable')   {ret_val = debit(proposal.AutoGrant__c); }
            // BLL7a end                                                                            
            if(actionName == 'Downpayment') { ret_val = debit(proposal.dealer__Down_Pymt__c); }
            if(actionName == 'Deposit') { ret_val = debit(proposal.dealer__Deposit__c); } // BLL1a

            if(actionName == 'Chassis Inventory') { ret_val = credit(proposal.Chassis_Cost__c); } // This might need to be a search field
            if(actionName == 'Chassis Sale') { ret_val = credit(proposal.Chassis_Price__c); }
            if(actionName == 'Chassis Cost') { ret_val = debit(proposal.Chassis_Cost__c); }

			// BLL30a
            if(actionName == 'Chassis Mark-UP') ret_val = -(proposal.Chassis_Price__c - proposal.Chassis_Cost__c);
            if(actionName == 'Chassis Mark-UP' && proposal.ReleasingDealer__c==null ) ret_val = 0;
            if((actionName=='Chassis Inventory' || actionName=='Chassis Sale' || actionName=='Chassis Cost')
            	&& proposal.ReleasingDealer__c!=null) ret_val = 0.00;	
            // BLL30a end

            //BLL31d if(actionName == 'MBW Rewards') { ret_val = credit(proposal.MBW_Rewards__c); }
            if(actionName == 'MBW Rewards') { ret_val = debit(proposal.MBW_Rewards__c); }	// BLL31a

            // JVK - Per Jerry August Corp Pack to be removed (8/25)
            if (proposal.dealer__Vehicle__c!=null) {
                if(proposal.dealer__Vehicle__r.dealer__Pack__c == null) { 
                    proposal.dealer__Vehicle__r.dealer__Pack__c=0;
                }
                // BLL7d if(actionName == 'Conversion Sales') { ret_val = credit(proposal.Conversion_Price__c - proposal.dealer__Vehicle__r.dealer__Pack__c); }
                if(actionName == 'Conversion Cost') { ret_val = debit(proposal.Conversion_Cost__c - proposal.dealer__Vehicle__r.dealer__Pack__c); }
                if(actionName == 'Conversion Inventory') { ret_val = credit(proposal.Conversion_Cost__c - proposal.dealer__Vehicle__r.dealer__Pack__c); } // This might need to be a search field  // BLL7a
            }
            if(actionName == 'Conversion Sales') { ret_val = credit(proposal.Conversion_Price__c); }  // BLL7a
            //BLL44d if(actionName == 'Conversion Sales' && proposal.Chassis_Price__c>proposal.Chassis_Cost__c && proposal.ReleasingDealer__c!=null ) { ret_val += (proposal.Chassis_Price__c - proposal.Chassis_Cost__c); }	// BLL30a
            if(actionName == 'Conversion Discount') { ret_val = debit(proposal.Conversion_Discount__c); } // BLL15a 
            
            // BLL7d if(actionName == 'Conversion Inventory') { ret_val = credit(proposal.Conversion_Cost__c); } // This might need to be a search field
            if(actionName == 'Doc Fee') { ret_val = credit(proposal.dealer__Doc_Fee__c); }
            if(actionName == 'Smog Fee') { ret_val = credit(proposal.Smog_Fee__c) + credit(proposal.Smog_Cert__c); }
            if(actionName == 'Title & Tag Fee') { ret_val = credit(proposal.Registration_Title_Fee__c) + credit(proposal.Electronic_Filing_Fee__c) + credit(proposal.GVW_GVWR__c) + credit(proposal.dealer__License_Fee__c); }
            if(actionName == 'Tire Fee') {ret_val = credit(proposal.Tire_Fee__c); } // BLL15a

            if(actionName == 'Additional Equipment Sales') { ret_val = credit(proposal.Total_Additional_Equipment__c); } 
            // if(actionName == 'Additional Equipment Cost') { ret_val = credit(proposal.Total_Internal_Local_Equipment__c); } // Comes from the Repair Order
            // BLL7d if(actionName == 'Additional Equipment Inventory') { ret_val = nonNull(0); } // 
            if(actionName == 'Sales Tax Payable') { ret_val = credit(proposal.dealer__Sales_Tax__c) ; } 
            if(actionName == 'Sales Tax Payable' && proposal.ReleasingDealer__c!=null) { ret_val = 0; }	// BLL32a 

			// BLL33a other fees not assessed by us
            if(actionName == 'Doc Fee' && proposal.ReleasingDealer__c!=null) { ret_val = 0; }	
            if(actionName == 'Title & Tag Fee' && proposal.ReleasingDealer__c!=null) { ret_val = 0; }	
            if(actionName == 'OLRS Fee' && proposal.ReleasingDealer__c!=null) { ret_val = 0; }	
            if(actionName == 'Smog Fee' && proposal.ReleasingDealer__c!=null) { ret_val = 0; }	
            if(actionName == 'Tire Fee' && proposal.ReleasingDealer__c!=null) { ret_val = 0; }	
            // BLL33a end 


            //BLL7d ESC, GAP, Diamond, Roadside moved to loop over related list
            // ESC - Contains only Service Contracts
            //BLL7d  if(actionName == 'Extended Warranty Sales') { ret_val = credit(proposal.Total_Protection_Products__c); }
            //BLL7d  if(actionName == 'Extended Warranty GOGS') { ret_val = debit(proposal.Warranty_Cost__c); }
            //BLL7d  if(actionName == 'Extended Warranty Payable') { ret_val = credit(proposal.Warranty_Cost__c); }
            
            // GAP
            //BLL7d  if(actionName == 'Gap Insurance') { ret_val = nonNull(0);}  // --> Get the gap total
            //BLL7d  if(actionName == 'Gap Insurance Sales') { ret_val = credit((Decimal)sumGap[0].get('gap_sale')); }
            //BLL7d  if(actionName == 'GAP Insurance Payable') {ret_val = credit((Decimal)sumGap[0].get('gap_cost')); }

            // Protection Production Extended
            //BLL7d  if(actionName == 'Roadside Assistance Sales - ADA') { ret_val = credit(0); }

            // Trade(s)
            //BLL7d if(actionName == 'Trade-in Chassis Amount') { ret_val = debit((Decimal)sumTrade[0].get('acv')); }
            //BLL7d if(actionName == 'Trade-In Conversion Amount') { ret_val = debit((Decimal)sumTrade[0].get('conversion')); }
            //BLL7d if(actionName == 'Trade-in Payoff') { ret_val = credit((Decimal)sumTrade[0].get('payoff')); }

            // JVK3
            // Per Ticket Case# 14257
            // The total of commissions should be a sum of the four possible total lines
            Decimal Commission = 0;

            // BLL7d - split commissions into separate lines too
            // CMC1
            //BLL7d Commission += debit(proposal.Commission__c);
            //BLL7d Commission += debit(proposal.Flat__c);
            //BLL7d Commission += debit(proposal.Commission_FI_1__c);

            // CMC2
            //BLL7d Commission += debit(proposal.Commission_2__c);
            //BLL7d Commission += debit(proposal.Commission_Flat_2__c);
            //BLL7d Commission += debit(proposal.Commission_FI_2__c);  
            
            // CMC3
            //BLL7d Commission += debit(proposal.Commission_3__c);
            //BLL7d Commission += debit(proposal.Commission_Flat_3__c);
            //BLL7d Commission += debit(proposal.Commission_FI_3__c);            
                      
            // CMC4
            //BLL7d Commission += debit(proposal.Commission_4__c);
            //BLL7d Commission += debit(proposal.Commission_Flat_4__c);
            //BLL7d Commission += debit(proposal.Commission_FI_4__c);
            // End JVK3

            //BLL7d - split commissions into separate lines
            //if(actionName == 'Commission Accrual') { ret_val = credit(Commission); } // Add second, third, fourth
            //if(actionName == 'Commission Expense') { ret_val = debit(Commission); }

            //if (actionName == 'Finance Company') { ret_val = debit(proposal.Contract_Amount_Financed__c); }  // BLL2a
            // BLL27d if (actionName == 'Finance Company') { ret_val = debit(proposal.Total_Price__c); }  // BLL2a
            if (actionName == 'Finance Company' && proposal.Funding_Option__c=='Financed') ret_val = proposal.Contract_Amount_Financed__c!=null ? proposal.Contract_Amount_Financed__c : 0.00;	// BLL36a
            if (actionName == 'Finance Company' && proposal.Funding_Option__c=='Financed' && proposal.Contract_Type__c == 'Lease' && proposal.Contract_Monthly_Payment__c!=null) ret_val -= proposal.Contract_Monthly_Payment__c;	// BLL40a
            //if (actionName == 'Finance Company' && proposal.Funding_Option__c=='Financed' && proposal.FinanceCompanyReimbursement__c!=null && proposal.FinanceCompanyReimbursement__c!=0) ret_val += proposal.FinanceCompanyReimbursement__c;	// BLL41a  
            if (actionName == 'Finance Company' && proposal.Funding_Option__c=='Financed' && proposal.dealer__Finance_Institution_Account__c==null) ret_val = 0.00;

            //BL36d if (actionName == 'Finance Company') { ret_val = 0.00; } // BLL27a They're keying finance company as an other payor
            //BLL36a Time to try this the right way
            if(actionName == 'Account Receivable' && proposal.dealer__Finance_Institution_Account__c!=null && proposal.Contract_Amount_Financed__c!=0 && proposal.Funding_Option__c=='Financed') {	//BLL41c 
                //ret_val = 0.00;
                ret_val -= proposal.Contract_Amount_Financed__c!=null ? proposal.Contract_Amount_Financed__c : 0;
	            if (proposal.Contract_Type__c == 'Lease' && proposal.Contract_Monthly_Payment__c!=null) ret_val += proposal.Contract_Monthly_Payment__c;	// BLL40a  
                if (ret_val<0) ret_val = 0;
            }

            // BLL4a - zero out Finance Company/Account receivable if it does not apply
            // BLL27d if(actionName == 'Account Receivable' && proposal.dealer__Finance_Institution_Account__c!=null) {
                //BLL27d ret_val = 0.00;
            // BLL27d }

            // BLL26a
            //BLL39d if (actionName=='Inventory Reserve') {
            //BLL39d     ret_val = inventoryReserve;
            //BLL39d }
            //BLL39d if (actionName=='Service Billing') {
            //BLL39d     ret_val = -inventoryReserve;
            //BLL39d }
            // BLL26a end

		System.debug(ret_val);
		if (ret_val==null) ret_val = 0;	// BLL38a
        return ret_val.setScale(2);
    }

    public Decimal nonNull(Decimal val) {
        if(val==null) {
            return 0;
        } 
        return val;
    }

    public PageReference loadProposalData() {

        System.debug(entry.Proposal__c);

        // BLL25d remove Total_Vehicle_Package__c, from below select clause
        // BLL28 replace Service_Vehicle__c with dealer__Service_Vehicle__c
        proposal = [SELECT dealer__Aftermarket_Gross__c, dealer__Amt_Financed__c, dealer__Auto_Insurance_Address__c, dealer__Auto_Insurance_Agent__c, dealer__Auto_Insurance_COL_Deductable__c, dealer__Auto_Insurance_COM_Deducatable__c, dealer__Auto_Insurance_City__c, dealer__Auto_Insurance_Company__c, dealer__Auto_Insurance_Contact__c, dealer__Auto_Insurance_Effective_Date__c, dealer__Auto_Insurance_Expiration_Date__c, dealer__Auto_Insurance_Phone__c, dealer__Auto_Insurance_Policy__c, dealer__Auto_Insurance_State__c, dealer__Auto_Insurance_Zip__c, dealer__Back_End_Gross__c, dealer__Back_End_Net__c, dealer__Broker_Address__c, dealer__Broker_City__c, dealer__Broker_Contracting_Name__c, dealer__Broker_County__c, dealer__Broker_Department__c, dealer__Broker_Postal_Code__c, dealer__Broker_State__c, dealer__Broker_Title__c, dealer__Broker__c, dealer__Business_Address__c, dealer__Business_City__c, dealer__Business_Contracting_Name__c, dealer__Business_County__c, dealer__Business_Department__c, dealer__Business_Phone__c, dealer__Business_Postal_Code__c, dealer__Business_State__c, dealer__Business_Title__c, dealer__Buyer_Address__c, dealer__Buyer_Birthdate__c, dealer__Buyer_City__c, dealer__Buyer_Contact__c, dealer__Buyer_County__c, dealer__Buyer_Drivers_License_Exp_Date__c, dealer__Buyer_Drivers_License__c, dealer__Buyer_Email__c, dealer__Buyer_First_Name__c, dealer__Buyer_Gender__c, dealer__Buyer_Home_Phone__c, dealer__Buyer_Last_Name__c, dealer__Buyer_Middle_Name__c, dealer__Buyer_Mobile_Phone__c, dealer__Buyer_Postal_Code__c, dealer__Buyer_Social_Security_Number__c, dealer__Buyer_State__c, dealer__Buyer_Work_Phone__c, dealer__Buyer__c, dealer__Co_Buyer_Address__c, dealer__Co_Buyer_Birth_Date__c, dealer__Co_Buyer_City__c, dealer__Co_Buyer_Contact__c, dealer__Co_Buyer_County__c, dealer__Co_Buyer_Drivers_License_Exp_Date__c, dealer__Co_Buyer_Drivers_License_Number__c, dealer__Co_Buyer_Email__c, dealer__Co_Buyer_First_Name__c, dealer__Co_Buyer_Gender__c, dealer__Co_Buyer_Home_Phone__c, dealer__Co_Buyer_Last_Name__c, dealer__Co_Buyer_Middle_Name__c, dealer__Co_Buyer_Mobile_Phone__c, dealer__Co_Buyer_Postal_Code__c, dealer__Co_Buyer_Social_Security_Number__c, dealer__Co_Buyer_State__c, dealer__Co_Buyer_Work_Phone__c, dealer__Co_Buyer__c, dealer__Comapny_Number__c, dealer__Company_Name__c, dealer__Company_Number__c, dealer__County_Rate__c, dealer__County__c, dealer__Customer_Key__c, dealer__Days__c, dealer__Days_in_Stock_f__c, dealer__Days_to_First__c, dealer__Deal_Category__c, dealer__Deal_Close_Date__c, dealer__Deal_Date__c, dealer__Deal_ID__c, dealer__Deal_Type__c, dealer__Deferred_1_Payee__c, dealer__Deferred_2_Payee__c, dealer__Deferred_3_Payee__c, dealer__Deferred_Date_1__c, dealer__Deferred_Date_2__c, dealer__Deferred_Date_3__c, dealer__Deferred_Down_1__c, dealer__Deferred_Down_2__c, dealer__Deferred_Down_3__c, dealer__Deferred_Note_1__c, dealer__Deferred_Note_2__c, dealer__Deferred_Note_3__c, dealer__Deferred_Reference_1__c, dealer__Deferred_Reference_2__c, dealer__Deferred_Reference_3__c, dealer__Deposit__c, dealer__Desk_Manager_Name__c, dealer__Desk_Manager_Number__c, dealer__Desk_Manager__c, dealer__Doc_Fee__c, dealer__Down_Pymt__c, dealer__Ext_Color__c, dealer__Ext_Warr_Gross__c, dealer__F_I_Manager_Name__c, dealer__F_I_Manager_Number__c, dealer__F_I_Manager__c, dealer__Finance_Gross__c, dealer__Finance_Institution_Account__c, dealer__Financial_Inst__c, dealer__First_Payment_Date__c, dealer__Front_End_Gross__c, dealer__Front_End_Net__c, dealer__GAP_Company__c, dealer__GAP_Gross__c, dealer__GAP_Premium__c, dealer__GAP_Term__c, dealer__Int_Color__c, dealer__Internet_Customer__c, dealer__Internet_Member__c, dealer__Last_Pymt_Date__c, dealer__Lead_Date__c, dealer__Lead_Source__c, dealer__Lender_Code__c, dealer__Licence__c, dealer__License_Expiration__c, dealer__License_Fee__c, dealer__List_Price__c, dealer__MQOptions__c, dealer__Maintenance_Premium__c, dealer__Make__c, dealer__Mileage__c, dealer__Model__c, dealer__Monthly_Pymt__c, dealer__Multi_Quote_Vehicle_1__c, dealer__Multi_Quote_Vehicle_2__c, dealer__Multi_Quote_Vehicle_3__c, dealer__NUO__c, dealer__Net_Cap_Cost__c, dealer__Non_Trade_Transfer_Plate_No__c, dealer__Non_Trade_Transfer_Title_No__c, dealer__Non_Trade_Transfer_VIN__c, dealer__Other_Gross__c, dealer__Other_Name__c, dealer__Payments_Per_Year__c, dealer__Pickup_or_Delivery__c, dealer__Rate__c, dealer__Rebate__c, dealer__Residual_Amt__c, dealer__Residuale_Rate__c, dealer__Sale_Cost__c, dealer__Sale_Price__c, dealer__Sale_Source__c, dealer__Sales_Lead__c, dealer__Sales_Tax__c, dealer__Salesperson_1_Name__c, dealer__Salesperson_1_Number__c, dealer__Salesperson_1__c, dealer__Salesperson_2_Name__c, dealer__Salesperson_2_Number__c, dealer__Salesperson_2__c, dealer__Salesperson_3__c, dealer__Salesperson_4__c, dealer__Split__c, dealer__Status__c, dealer__Still_Owned__c, dealer__Stock_Number__c, dealer__TAVT_Amount__c, dealer__Tax_Rate__c, dealer__Term__c, dealer__Total_Cash_Down__c, dealer__Total_Fees__c, dealer__Total_Gross__c, dealer__Total_Tax__c, dealer__Trade_Allowance__c, dealer__Trade_Payoff__c, dealer__VIN__c, dealer__ValueOfOne__c, dealer__Vehicle_Key__c, dealer__Vehicle__c, dealer__Warranty_Premium__c, dealer__Warranty__c, dealer__With_Recourse__c, dealer__Wrnty_End_Date__c, dealer__Wrnty_Mileage__c, dealer__Year__c, dealer__orig_lic_plate__c, MultiQuote_Payment_Grid__c, GVW_GVWR__c, Customer_Supplied_Body__c, Tire_Fee__c, Registration_Title_Fee__c, Smog_Fee__c, Smog_Cert__c, Electronic_Filing_Fee__c, Proposed_Delivery_Date__c, Chassis_Price__c, Conversion_Cost__c, Conversion_Price__c, Conversion_Discount__c, Conversion_Discount_Reason__c, Deposit_Notes__c, F_O_B__c, Chassis_QTY__c, dealer__Service_Vehicle__c, AutoGrant__c,  dtmob__Auto_Grant_Payor__c, Mobility_Rebate__c, MFG_Rebate__c, Government_Price_Concession__c, dealer__Store_Location__c, dealer__DeliveryRepairOrder__c, Wheelbase_Package_QTY_Long__c, Wheelbase_Package_Price_Long__c, Wheelbase_Package_Ext_Price_Long__c, Chassis_Cost__c, Conversion_Taxable__c, Dealer_Cash__c, Rebate_Description__c, Approved_Technical__c, Approved_GM__c, Vehicle_Status__c, WIP__c, Sales_Admin__c, dealer__DeliveryRepairOrderStatus__c, Chassis_Gross__c, Conversion_Gross__c, Total_Proposal_Gross__c, Commission_Rate__c, Flat__c, Commission__c, Pack__c, Total_Internal_Local_Equipment__c, MBW_Rewards__c, Vehicle_Sale_Price_EX__c, Total_Additional_Equipment__c, Total_Protection_Products__c, Warranty_Cost__c, Total_Price__c, Commissionable_Gross__c, Grants_Government_Assistance__c, Conversion_Description__c, Rebate_2__c, Rebate_2_Description__c, Rebate_3__c, Rebate_3_Description__c, Trade_ACV__c, Commission_2__c, Commission_Employee_1__c, Commission_3__c, Commission_Flat_2__c, Commission_Flat_3__c, Commission_Rate_2__c, Commission_Rate_3__c, Commission_Employee_2__c, Commission_Employee_3__c, dtmob__Service_Manager__c, Third_Party_Pay_1__c, Third_Party_Pay_2__c, Third_Party_Pay_3__c, Commission_Employee_4__c, Commission_Rate_4__c, Commission_4__c, Commission_Flat_4__c, Commission_FI_1__c, Commission_FI_2__c, Commission_FI_3__c, Commission_FI_4__c, Id, Name, RecordTypeId,    // BLL20c remove dealer__Closer__c, dealer__Team_Manager__c // BLL28c Auto_Grant_Payee__c, DeliveryRepairOrder__c, Service_Manager__c, DeliveryRepairOrderStatus__c, Location__c,
                        dealer__Vehicle__r.Name, dealer__Vehicle__r.New_Used_Other__c , dealer__Vehicle__r.dealer__Pack__c, dealer__Vehicle__r.dealer__Stock_Number__c,  // BLL7 removed Chassis__c, Wheelbase_Package_Long__c, Wheelbase_Package_Regular__c,  
                        dealer__Deal__c.Contract_Amount_Financed__c, ReleasingDealer__c,
                        DeliveryFreightAmount__c, DeliveryFreightCost__c, 	// BLL30a
                        LoanAcquisitionCost__c, LeaseAcquisitionFee__c, 	// BLL38a
                        Contract_Type__c, Contract_Monthly_Payment__c,		// BLL40a
                        Funding_Option__c, 									// BLL41a  
						FinanceCompanyReimbursement__c,	// BLL41a
                        dealer__Vehicle__r.Open_Service_Repair_Orders__c,    // BLL16a
						ESC_Loan_Cost__c, 	// BLL48
						GP_Sharing_Amount__c, GP_Sharing_Location__c, GP_Sharing_Location__r.Financial_Force_Dimension_1__c, // BLL49
                        TotalDueUponDelivery__c								// BLL43a
                        FROM dealer__Deal__c
                    Where Id=:entry.Proposal__c
                    limit 1];
		if (proposal.Government_Price_Concession__c==null) proposal.Government_Price_Concession__c = 0;
		if (proposal.dealer__Rebate__c==null) proposal.dealer__Rebate__c = 0;	// BLL30a 
		if (proposal.Rebate_2__c==null) proposal.Rebate_2__c = 0;	// BLL30a
		if (proposal.Rebate_3__c==null) proposal.Rebate_3__c = 0;	// BLL30a
		
        NewUsedOther = proposal.dealer__Vehicle__r.New_Used_Other__c; // BLL1a
        vehOpenROs = (proposal.dealer__Vehicle__r.Open_Service_Repair_Orders__c!=null) ? proposal.dealer__Vehicle__r.Open_Service_Repair_Orders__c : 0; // BLL16a
        if (entry.Stock__c==null) {entry.Stock__c = proposal.dealer__Vehicle__c;} // BLL1a
        
        recordType = [Select Name from RecordType where Id=:proposal.RecordTypeId limit 1];         

        // Set Location Based on Proposal
        entry.Location__c = proposal.dealer__Store_Location__c; // BLL10a
        loc = DealerLocation(proposal.dealer__Store_Location__c);   // BLL10a
        dim1 = Dimension1(loc.Financial_Force_Dimension_1__c);  // BLL10a
		GPShareDim1 = Dimension1(proposal.GP_Sharing_Location__r.Financial_Force_Dimension_1__c); // BLL49
        //BLL10d if(proposal.dealer__Store_Location__c!=null) {
        //BLL10d     dealer__Dealer_Location__c loc_c  =   [Select Id, Name, Financial_Force_Dimension_1__c 
        //BLL10d                                             from dealer__Dealer_Location__c 
        //BLL10d                                             where Id=:proposal.dealer__Store_Location__c limit 1];
        //BLL10d     entry.Location__c               =   loc_c.Id;

        //BLL10d     if(loc_c.Financial_Force_Dimension_1__c!=null) {
        //BLL10d     dim1                            =   [Select Id, Name from c2g__codaDimension1__c 
        //BLL10d                                             where Id=:loc_c.Financial_Force_Dimension_1__c limit 1];  
        //BLL10d     } else {
        //BLL10d         throw new PostingException('Location '+loc_c.Name+' must have the Financial Force Dimmension 1 field set to before attempting to Post');
        //BLL10d     }

        //BLL10d } else {
        //BLL10d     throw new PostingException('Proposal '+proposal.Name+' does not have a Store Location Set.  Please set a Store Location before attempting to Post');
        //BLL10d }

        DealGP = proposal.dealer__Total_Gross__c; // BLL19a

        return null;
    }



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
            } else {
                throw new PostingException('Not authorized to the financial company');
            }
        } else {
            throw new PostingException('Missing the financial company');
        }
        
        // Currently selected company
        List<ID> groupIds = new List<ID>();
        for(GroupMember member : [select GroupId from GroupMember where Group.Type = 'Queue' and UserOrGroupId = :UserInfo.getUserId()]) {
            groupIds.add(member.GroupId);               
        } 
        c2g__codaCompany__c[] companies = 
            [select RecordType.Name, Id, Name, c2g__TaxCode__c, c2g__CODABaseDate1__c, c2g__CODADaysOffset1__c from c2g__codaCompany__c where OwnerId in :groupIds];
        // Ensure the user has a single current company
        if (companies.size() == 0)
            throw new PostingException('Current company has not been set for this user');
        if (companies.size() > 1)
            throw new PostingException('This operation is not valid in multiple company mode'); 
        if (companies[0].Id!=comp.Id) 
            throw new PostingException('Your current company is ' + companies[0].Name + '. ' + 'Please select the transaction company ' + comp.Name + '.');

        return comp;
    }


    // BLL20a
    public String documentOpenROs() {
        List<String> openros = new List<String>();
        if (documentType=='Proposal') { 
            for(dealer__Service_Repair_Order__c ro : [
                    select Id, Name from dealer__Service_Repair_Order__c 
                    where Deal__c=:proposal.Id and dealer__Status__c not in ('Posted','Void')
                ]) {
                openros.add(ro.Name);
            }
        } else if (documentType=='Commercial Quote') {  
            for(dealer__Service_Repair_Order__c ro : [
                    select Id, Name from dealer__Service_Repair_Order__c 
                    where CommercialQuote__c=:cq.Id and dealer__Status__c not in ('Posted','Void')
                ]) {
                openros.add(ro.Name);
            }
        }
        return String.join(openros, ',');
    }
    // BLL20a


    /**
     * createJournal - Create a journal from the posting template
     * @return PageReference
     *
     * @notes : Updated to use the FinancialForce_MBW.createJournalAPI - 12/21/2015
     */
    public PageReference createJournal() {
        
        if(tBalance != 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Journal entries may not be created until the transaction is in balance.'));
            return null;            
        }

        // BLL16a
        loadVeh();
        if (vehOpenROs!=null && vehOpenROs!=0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Cannot post yet: Vehicle has ' + String.valueOf(vehOpenROs) + ' open repair orders.'));
            return null;            
        }
        // BLL16a

        // BLL20a - open ROs referencing document
        String docOpenROs = documentOpenROs();
        if (!String.isBlank(docOpenROs)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Cannot post yet: ' + documentType + ' has open repair orders: ' + String.valueOf(docOpenROs)));
            return null;            
        }
        // BLL20a end

        // BLL45 - used for combining all A/R lines by account
        MW_TriggerControls__c proposalCombineAR = MW_TriggerControls__c.getInstance('proposalCombineAR');
        if (proposalCombineAR==null) proposalCombineAR = new MW_TriggerControls__c(Enabled__c=true);
        Map<Id, c2g__codaJournalLineItem__c> arlinemap = new Map<Id, c2g__codaJournalLineItem__c>();
        // BLL45 end

        // BLL7a protect from double-posting if posting entry is showing on 2 screens/tabs        
        try {
            upsert(entry);
        } catch(DmlException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Posting entry no longer exists, possibly already posted.\n'+e.getMessage()));
            return null;
        }
        // BLL7a end
        
        
        // get company information
        //c2g__codaCompany__c comp  = [Select Id from c2g__codaCompany__c where Id =: loc[0].Company__c Limit 1];  // BLL1d
        c2g__codaCompany__c comp = null;
        try {
            comp = getFFCompany(loc.Company__c);  // BLL1a, BLL10c remove [0] on loc field
        } catch (Exception companyerr) { ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, companyerr.getMessage())); return null; }
        
        // Get Accounting Currency
        c2g__codaAccountingCurrency__c cur = [Select Id from c2g__codaAccountingCurrency__c where c2g__OwnerCompany__c =:comp.Id limit 1];
        // Get Period Data
        //BLL6d c2g__codaPeriod__c period = [Select Id from c2g__codaPeriod__c where c2g__StartDate__c >=:Date.today() and c2g__Closed__c=false limit 1];
        // Add Error if Period is not open does not exist


        // Build the Journal
        c2g__codaJournal__c tJrnl       =   new c2g__codaJournal__c();
        tJrnl.c2g__OwnerCompany__c      =   comp.Id;
        tJrnl.Source__c = 'SAL';
        tJrnl.c2g__JournalCurrency__c   =   cur.Id;

        // BLL10a
        String documentName = '';
        String vehicleName = '';
        String vehicleStock = '';
        Id vehicleId = null;
        Id customerId = null;
        Id arId = null;
        Id docId = null;
        if (documentType=='Proposal') {
            docId = proposal.Id;
            documentName = proposal.Name;
            vehicleName = (proposal.dealer__Vehicle__c!=null) ? proposal.dealer__Vehicle__r.Name : '';
            vehicleStock = (proposal.dealer__Vehicle__c!=null) ? proposal.dealer__Vehicle__r.dealer__Stock_Number__c : '';
            vehicleId = proposal.dealer__Vehicle__c;
            customerId = proposal.dealer__Buyer__c;
            arId = proposal.dealer__Buyer__c;
            tJrnl.c2g__JournalDescription__c = 'Proposal ' + proposal.Name + ': ' + templatename;  
            tJrnl.c2g__JournalDate__c       =   proposal.Proposed_Delivery_Date__c;
            tJrnl.c2g__Reference__c         =   proposal.Name;  
            tJrnl.Proposal__c               =   proposal.Id;
            tJrnl.CommercialQuote__c        =   null;
            tJrnl.Customer__c               =   proposal.dealer__Buyer__c;  
            tJrnl.Sales_Person__c           =   proposal.Commission_Employee_1__c; 
            if(proposal.ReleasingDealer__c!=null) arId=proposal.ReleasingDealer__c;
        } else if (documentType=='Commercial Quote') {
            docId = cq.Id;  
            documentName = cq.Name;
            vehicleName = (cq.VehicleInventory__c!=null) ? cq.VehicleInventory__r.Name : '';
            vehicleStock = (cq.VehicleInventory__c!=null) ? cq.VehicleInventory__r.dealer__Stock_Number__c : '';  
            if (String.isBlank(vehicleStock)) vehicleStock = cq.UnitNumber__c!=null ? cq.UnitNumber__c.toUpperCase().trim() : '';   // BLL12c use UnitNumber__c
            vehicleId = cq.VehicleInventory__c;
            customerId = cq.Customer__c;
            arId = cq.Customer__c;
            tJrnl.c2g__JournalDescription__c = 'Quote ' + cq.Name + ': ' + templatename;  
            tJrnl.c2g__JournalDate__c       =   cq.Delivery_Date__c;
            tJrnl.c2g__Reference__c         =   cq.Name;  
            tJrnl.Proposal__c               =   null;
            tJrnl.CommercialQuote__c        =   cq.Id;
            tJrnl.Customer__c               =   cq.Customer__c;  
            tJrnl.Sales_Person__c           =   cq.Salesperson__c; 
        }
        // BLL10a end

        // BLL10d
        //tJrnl.c2g__JournalDescription__c = 'Proposal ' + proposal.Name + ': ' + templatename;  // BLL1a
        //tJrnl.c2g__JournalDate__c       =   proposal.Proposed_Delivery_Date__c;
        //tJrnl.c2g__Reference__c           =   proposal.Name;  // BLL9a
        //tJrnl.Proposal__c               =   proposal.Id;
        //tJrnl.Customer__c               =   proposal.dealer__Buyer__c;  // BLL1a
        //tJrnl.Sales_Person__c           =   proposal.Commission_Employee_1__c; // BLL1a
        // BLL10d end

        /*
        try {
            // insert tJrnl;
            // Moved to Create Journal and Lines at the same time
        } catch(DmlException e) {
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to Create Journal '+e));
             return null; 
        }
        */

        // BLL2a - List of accounts to get link to vehicle inventory (12xx except 1220)
        Map<Id, c2g__codaGeneralLedgerAccount__c> vehGlAccts = new Map<Id, c2g__codaGeneralLedgerAccount__c>([
            select Id, c2g__ReportingCode__c 
            from c2g__codaGeneralLedgerAccount__c
            where c2g__ReportingCode__c like '12%' and c2g__ReportingCode__c != '1220' and c2g__ReportingCode__c != '1221'
        ]);
        // BLL2a end
 
        // Build the Line Items
        List<c2g__codaJournalLineItem__c> jLines = new List<c2g__codaJournalLineItem__c>();
        Integer i = 1;
        for(lines l : tLines) {

            // BLL7d if(l.amount != null && l.amount != 0 && l.account.Id != null) {
            System.debug(l); // BLL7a
            if(l.amount != null && l.amount != 0 && l.template.General_Ledger_Account__c != null) {  // BLL7a

            c2g__codaJournalLineItem__c tempLine = new c2g__codaJournalLineItem__c();
            tempLine.c2g__Journal__c                =   null;
            //BLL11d tempLine.c2g__Dimension1__c             =   dim1.Id;
            tempLine.c2g__Dimension1__c             =   l.jline.c2g__Dimension1__c; // BLL11a
            tempLine.c2g__LineNumber__c             =   i;
            // BLL9d tempLine.c2g__LineDescription__c        =   'Proposal ' + proposal.Name + ': ' + templateName + ' - ' + l.action;  // BLL1a
            //BLL10d tempLine.c2g__LineDescription__c       = ((proposal.dealer__Vehicle__c!=null) ? proposal.dealer__Vehicle__r.Name : 'Proposal ' + proposal.Name)
            //BLL10d    + ' - ' + l.action;  // BLL9a
            tempLine.c2g__LineDescription__c        = !String.isBlank(vehicleName) ? vehicleName : (documentType + ' ' + documentName); // BLL10a
            if (!String.isBlank(l.Description))  tempLine.c2g__LineDescription__c = l.Description;  // BLL9a
            if (!String.isBlank(l.memo)) tempLine.c2g__LineDescription__c += ' - '+l.memo;	// BLL29a
            // BLL7d  tempLine.c2g__GeneralLedgerAccount__c   =   l.account.Id;
            tempLine.c2g__GeneralLedgerAccount__c   =   l.template.General_Ledger_Account__c;  // BLL7a
            tempLine.c2g__Value__c                  =   l.amount;
			tempLine.c2g__LineType__c               =   'General Ledger Account'; // default line type 
            //tempLine.Control__c                     =  proposal.dealer__Vehicle__r.Name; // BLL2d
            //BLL10d tempLine.Control__c = (proposal.dealer__Stock_Number__c!=null) ? proposal.dealer__Stock_Number__c : proposal.Name; // BLL2a

            tempLine.Control__c                     =   l.controlNumber;//RT1 - control numbers are initialized with the same logic as below, but are set earlier
                                                                        //      to allow editing by users
            /*
            tempLine.Control__c = !String.isBlank(vehicleStock) ? vehicleStock : documentName;  // BLL10a
            // BLL8a - use proposal as control# for this entry (so it matches with the RO)
            if (l.action=='Additional Equipment Inventory') {
                tempLine.Control__c = documentName; // BLL10c was proposal.Name;
            }
            // BLL8a - end
            // BLL10a - additional control# overrides
            
            // BLL10a end
            // BLL7a (trade-in stock number)
            if (l.StockNbr!=null) {
                tempLine.Control__c = l.StockNbr;
            }
            */

            if (l.VIN!=null) {
                tempLine.c2g__LineDescription__c += ' ' + l.VIN;
            }
            tempLine.Customer_Name__c               =   customerId; // BLL10c was proposal.dealer__Buyer__c;  
            // BLL7a

            // BLL2a - add link to vehicle inventory
            if (vehGlAccts.containsKey(tempLine.c2g__GeneralLedgerAccount__c)) {
                tempLine.Vehicle_Inventory__c = vehicleId;  // BLL10c was proposal.dealer__Vehicle__c;
            } 
            // BLL2a - end

            if (tempLine.Vehicle_Inventory__c==null && l.Vehicle!=null) tempLine.Vehicle_Inventory__c = l.Vehicle;  // BLL15a

            // Set Line Type Based on Receivable Actions
            // BLL24d  DO NOT HIT CUSTOMER A/R AGING on Rebates/Incentives!!!if(l.action == 'Account Receivable' || l.action=='Rebates/Incentives'   // BLL5c added Rebates/Incentives

			// BLL35d 
            //BLL35d if(l.action == 'Account Receivable' // BLL24a
            //BLL35d    || l.action=='Deposit' || l.action=='Downpayment') {
            //BLL35d    tempLine.c2g__LineType__c           =   'Account - Customer';
            //BLL35d } 

            // BLL2a begin
            // Finance company
            //BLL35d if(l.action == 'Finance Company' && proposal.dealer__Finance_Institution_Account__c!=null) {  //dealer__Amt_Financed__c, Contract_Amount_Financed__c, dealer__Finance_Gross__c
            //BLL35d     tempLine.c2g__LineType__c = 'Account - Customer';
            //BLL35d     tempLine.Finance_Company__c = proposal.dealer__Finance_Institution_Account__c;
            //BLL35d     try {
            //BLL35d         dealer__Finance_Company__c fincomp = [select Id, Name, FinanceAccount__c
            //BLL35d             from dealer__Finance_Company__c
            //BLL35d             where Id=:proposal.dealer__Finance_Institution_Account__c
            //BLL35d             limit 1 
            //BLL35d         ];
            //BLL35d         tempLine.c2g__Account__c = fincomp.FinanceAccount__c; // BLL7a - needs to be a finance company account
            //BLL35d     } catch(Exception e) {
            //BLL35d         // Should never happen, but allow to fall through, which will assign customer account to this journal line.
            //BLL35d         // Accounting can fix before posting the journal.
            //BLL35d     }
            //BLL35d }
            // BLL2a end

            // Apply the 3rd party Payor to the line
            //BLL35d if(l.action == '3rd Party/Government Receivable') {
            //BLL35d     tempLine.c2g__LineType__c = 'Account - Customer';   // BLL3a - Third-party payor should be an "Account - Customer" line type
            //BLL35d     // tempLine.c2g__Account__c = proposal.Third_Party_Pay_1__c;
            //BLL35d     tempLine.Third_Party_Payor__c = proposal.Third_Party_Pay_1__c;
            //BLL35d     tempLine.c2g__Account__c = proposal.Third_Party_Pay_1__c;
            //BLL35d }

            //BLL35d // BLL7a - split funding sources to separate journal lines
            //BLL35d if(l.action == 'Third Party 1') {
            //BLL35d     tempLine.c2g__LineType__c = 'Account - Customer';
            //BLL35d     tempLine.Third_Party_Payor__c = proposal.Third_Party_Pay_1__c;
            //BLL35d     tempLine.c2g__Account__c = proposal.Third_Party_Pay_1__c;
            //BLL35d }
            //BLL35d if(l.action == 'Third Party 2') {
            //BLL35d     tempLine.c2g__LineType__c = 'Account - Customer';
            //BLL35d     tempLine.Third_Party_Payor__c = proposal.Third_Party_Pay_2__c;
            //BLL35d     tempLine.c2g__Account__c = proposal.Third_Party_Pay_2__c;
            //BLL35d }
            //BLL35d if(l.action == 'Other Payor')   {
            //BLL35d     tempLine.c2g__LineType__c = 'Account - Customer';
            //BLL35d     if (documentType=='Proposal') { // BLL10a
            //BLL35d         tempLine.Third_Party_Payor__c = proposal.Third_Party_Pay_3__c;
            //BLL35d         tempLine.c2g__Account__c = proposal.Third_Party_Pay_3__c;
            //BLL35d     } else if (documentType=='Commercial Quote') {  // BLL10a
            //BLL35d         if (cq.LienHolder__c==null || cq.LienHolder__r.FinanceAccount__c==null) {
            //BLL35d             tempLine.Third_Party_Payor__c = cq.ReleasingDealer__c;  // BLL10a
            //BLL35d             tempLine.c2g__Account__c = cq.ReleasingDealer__c;   // BLL10a
            //BLL35d         } else {
            //BLL35d             tempLine.Third_Party_Payor__c = cq.LienHolder__r.FinanceAccount__c; // BLL10a
            //BLL35d             tempLine.c2g__Account__c = cq.LienHolder__r.FinanceAccount__c;  // BLL10a
            //BLL35d         }
            //BLL35d     }   // BLL10a
            //BLL35d }
            //BLL35d if(l.action == 'Government Receivable') {
            //BLL35d     tempLine.c2g__LineType__c = 'Account - Customer';
            //BLL35d     tempLine.Third_Party_Payor__c = proposal.dtmob__Auto_Grant_Payor__c;    // BLL28c proposal.Auto_Grant_Payee__c;
            //BLL35d     tempLine.c2g__Account__c = proposal.dtmob__Auto_Grant_Payor__c;     // BLL28c proposal.Auto_Grant_Payee__c;
            //BLL35d }
            //BLL35d // BLL7a end
            //BLL35d // BLL7a protection product vendor
            //BLL35d if(l.VendorId != null) {
            //BLL35d     tempLine.Vendor_Name__c = l.VendorId;
            //BLL35d     tempLine.c2g__Account__c = l.VendorId;
            //BLL35d     tempLine.c2g__LineType__c = 'Account - Vendor';
            //BLL35d }
            //BLL35d // BLL7a end protection product vendor

			// BLL35a - specify additional details from screen settings
			if (l.jline.c2g__LineType__c!=null) tempLine.c2g__LineType__c = l.jline.c2g__LineType__c;
			if (l.jline.c2g__Account__c!=null) tempLine.c2g__Account__c = l.jline.c2g__Account__c;
			if (l.jline.Third_Party_Payor__c!=null) tempLine.Third_Party_Payor__c = l.jline.Third_Party_Payor__c;
			// BLL35a end

            // Commission Lines
            //if(l.action == 'Commission Accrual' || l.action == 'Commission Expense') {
            //    tempLine.Sales_Person__c = proposal.Commission_Employee_1__c;
            //}
            // BLL7a assign specific salesperson
            if (l.Salesperson!=null) {
                tempLine.Sales_Person__c = l.Salesperson;
            }

            if(l.amount > 0) {
                tempLine.c2g__DebitCredit__c = 'Debit';
            } else {
                tempLine.c2g__DebitCredit__c = 'Credit';
            }

            // Customer Receivable
            // BLL7d if(tempLine.c2g__LineType__c == 'Account - Customer') {
            if(tempLine.c2g__LineType__c == 'Account - Customer'
                && tempLine.c2g__Account__c==null) {  // BLL7a - default to customer if not specified
                tempLine.c2g__Account__c = arId;  // BLL10c was proposal.dealer__Buyer__c; BLL30c was customerId
            }

			// BLL38a
			// Vendor credit to receivable
            if(tempLine.c2g__LineType__c == 'Account - Vendor'
                && tempLine.c2g__Account__c==null) {  // BLL7a - default to customer if not specified
                tempLine.c2g__Account__c = arId;  // BLL10c was proposal.dealer__Buyer__c; BLL30c was customerId
            }
            // BLL38a end

            // BLL2a 
            //System.debug(l.action + ' ' + ((proposal.dealer__Finance_Institution_Account__c==null) ? 'Customer pay' : 'Financed'));
            //if(l.action == 'Account Receivable' && proposal.dealer__Finance_Institution_Account__c!=null) {
            //  tempLine = null;
            //  System.debug('Do not generate Accoutn Receivable');
            //}
            //if (l.action == 'Finance Company' && proposal.dealer__Finance_Institution_Account__c==null) { // added 9/24/2015
            //  templine = null;
            //  System.debug('Do not generate Finance Company');
            //}
            // BLL2a end

            // BLL45 consolidate AR lines
            if (proposalCombineAR.Enabled__c && tempLine!=null 
                && tempLine.c2g__LineType__c=='Account - Customer' && tempLine.c2g__Account__c!=null) {
                c2g__codaJournalLineItem__c arline = arlinemap.get(tempLine.c2g__Account__c);
                // add to existing ar line
                if (arline!=null) {
                    arline.c2g__Value__c += tempLine.c2g__Value__c;
                    arline.c2g__LineDescription__c += ((tempLine.c2g__Value__c>=0) ? ' +' : ' ') + String.valueOf(tempLine.c2g__Value__c);
                    tempLine = null;    // don't add new line, jLines reference was just updated with the above code
                    // shouldn't need to re-put it: arlinemap.put(arline.c2g__Account__c, arline);
                } else {    // set initial AR line and add to journal lines
                    tempLine.c2g__LineDescription__c += ': ' + String.valueOf(tempLine.c2g__Value__c);
                    arlinemap.put(tempLine.c2g__Account__c, tempLine);
                }
            }
            // BLL45 end

            if (tempLine!=null) { // BLL2a
                jLines.add(tempLine);
                i++;
            } // BLL2a

            }
        }

        /* Removed to make use of the FinancialForce_MBW.createJournalAPI() Method - JVK2 
        if(jLines.size()>0) {
            try {   
                insert jLines;
            } catch(DmlException e) { ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to Create Journal Lines '+e)); return null; }
        }
        */
       
       if(jLines.size()==0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'What? A Journal with No Lines.  I think you may want to review your posting template...'));
            return null;            
       }

        // Delete Posting Entry once Journal is Created
        // Per Jerry August 8/25
        // JVK
        try {
            Id journalId = FinancialForce_MBW.createJournalApi(tJrnl, jLines);
            FFAccounting.postJournal(journalId);
            delete entry;
            tJrnl = [select Id, Name from c2g__codaJournal__c where Id=:journalId]; // BLL10a
            try {   // BLL18a
                //BLL18 option: Set<String> autoApproveSteps = new Set<String>{'Accounting','Accounting_review'};
                // BLL46
				// BLL46d AutoApproveAccounting(docId, null); // BLL10a
				// BLL46 end
                // BLL18 option: AutoApproveAccounting(docId, autoApproveSteps);    // BLL18a
				// BLL46
				ApprovalProcessUtil.ApproveDocument(docId, 'Journal created and posted - Auto-approve request.', new Set<String>{'Accounting'});
				// BLL46 end
            } catch(Exception e) {  // BLL18a
                throw new PostingException('Cannot auto-approve quote. It\'s at the wrong step of approvals or it\'s an authorization issue.'); // BLL18a
            }   // BLL18a
        } catch(DmlException e) {
            throw new PostingException('Error creating journal or deleting the posting template.');
        }
        // End JVK

        PageReference jrnl = new ApexPages.StandardController(tJrnl).view();
        jrnl.setRedirect(true);
        return jrnl;
    }

// BLL46 moved to ApprovalProcessUtil class
//    // BLL10a - autoapprove document
//    // AutoApproveAccounting - approve current step when posted
//    //-------------------------------------
//    private void AutoApproveAccounting(Id docId, Set<String> nodes) {
//        // Pending approvals
//        List<ProcessInstance> pilist = [
//            Select TargetObjectId, Status, ProcessDefinitionId, Id, 
//                (Select Id, ProcessInstanceId, OriginalActorId, ActorId, ElapsedTimeInDays, ElapsedTimeInHours, ElapsedTimeInMinutes, IsDeleted, CreatedDate, CreatedById, SystemModstamp From Workitems), 
//                (Select Id, ProcessInstanceId, StepStatus, OriginalActorId, ActorId, Comments, StepNodeId, ElapsedTimeInDays, ElapsedTimeInHours, ElapsedTimeInMinutes, CreatedDate, CreatedById, SystemModstamp From Steps), 
//                (Select Id, IsDeleted, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, ProcessInstanceId, ProcessNodeId, NodeStatus, CompletedDate, LastActorId, ProcessNodeName, ProcessNode.DeveloperName, ElapsedTimeInDays, ElapsedTimeInHours, ElapsedTimeInMinutes From Nodes Where NodeStatus='Pending') 
//            From ProcessInstance 
//            Where Status='Pending' and TargetObjectId = :docId
//        ];
//        if (pilist.size()>0 && pilist[0].WorkItems.size()>0) {
//            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
//            req.setComments('Journal created and posted - Auto-approve request.');
//            req.setAction('Approve');
//            Id uid = UserInfo.getUserId();
//            req.setNextApproverIds(new Id[] {uid});
//
//            // Find matching work item (if there is one that matches the current user, else default to 0)
//            Integer wi = 0;
//            for(Integer i=0; i<pilist[0].WorkItems.size(); ++i) {
//                if (pilist[0].WorkItems[i].ActorId==uid) wi = i;
//            }
//            
//            // Use the ID from the newly created item to specify the item to be worked
//            req.setWorkitemId(pilist[0].WorkItems[wi].Id);
//            
//            if (nodes==null || nodes.size()==0 
//                || nodes.contains(pilist[0].Nodes[0].ProcessNode.Name) || nodes.contains(pilist[0].Nodes[0].ProcessNode.DeveloperName)) {
//                // Submit the request for approval
//                Approval.ProcessResult result =  Approval.process(req);
//                if (result.isSuccess()) System.debug('Automatic approval succeeded');
//                else System.debug('Automatic approval failed: ' + JSON.serialize(result));
//            } else System.debug('No matching node - do not auto-approve');
//        } else System.debug('No pending approval for document: ' + docId);
//    }
//    // BLL10a end
// BLL46 end

    public void setInitialControlNumbers() {
        String documentName = '';
        String vehicleName = '';
        String vehicleStock = '';
        Id vehicleId = null;
        Id customerId = null;
        Id docId = null;
        if (documentType=='Proposal') {            
            documentName = proposal.Name;
            vehicleName = (proposal.dealer__Vehicle__c!=null) ? proposal.dealer__Vehicle__r.Name : '';
            vehicleStock = (proposal.dealer__Vehicle__c!=null) ? proposal.dealer__Vehicle__r.dealer__Stock_Number__c : '';
          
        } else if (documentType=='Commercial Quote') { 
            documentName = cq.Name;
            vehicleName = (cq.VehicleInventory__c!=null) ? cq.VehicleInventory__r.Name : '';
            vehicleStock = (cq.VehicleInventory__c!=null) ? cq.VehicleInventory__r.dealer__Stock_Number__c : '';  
            if (String.isBlank(vehicleStock)) vehicleStock = cq.UnitNumber__c!=null ? cq.UnitNumber__c.toUpperCase().trim() : '';   // BLL12c use UnitNumber__c
                     
        }
        for(lines journalLine : tLines) {
            journalLine.controlNumber = !String.isBlank(vehicleStock) ? vehicleStock : documentName;  // BLL10a
            // BLL8a - use proposal as control# for this entry (so it matches with the RO)
            if (journalLine.action=='Additional Equipment Inventory') {
                journalLine.controlNumber = documentName; // BLL10c was proposal.Name;
            }
            // BLL8a - end
            // BLL10a - additional control# overrides
            
            // BLL10a end
            // BLL7a (trade-in stock number)
            if (journalLine.StockNbr!=null) {
                journalLine.controlNumber = journalLine.StockNbr;
            }

			// BLL47 - AR should reference documentName instead (for automated matching)
			if (journalLine.jline.c2g__LineType__c=='Account - Customer') journalLine.controlNumber = documentName;
			// BLL47 end

        }
    }


    // BLL19a
    // getVehicleTransactions - for processing and for displaying on-screen
    //------------------------------------------
    public List<c2g__codaTransactionLineItem__c> getVehicleTransactions() {
        
        vehTranLines = [
            select Id, Name, c2g__GeneralLedgerAccount__c, c2g__HomeValue__c, Control__c, Vehicle_Inventory__c,
                c2g__Transaction__r.Name, c2g__LineNumber__c, c2g__Dimension1__c, c2g__Dimension1__r.Name
            from c2g__codaTransactionLineItem__c
            where c2g__GeneralLedgerAccount__c in :vehGLAcctIds 
              and (Control__c=:veh.dealer__Stock_Number__c or Vehicle_Inventory__c=:veh.Id)
        ];
        vehInvBal = 0.00;
        for(c2g__codaTransactionLineItem__c l : vehTranLines) vehInvBal += l.c2g__HomeValue__c;

        return vehTranLines;
    
    }

    // pullVehicleInventoryFromGL - update posting template from actual inventory values
    //------------------------------------------
    public void pullVehicleInventoryFromGL() {
        // Summary of GL amounts by account...  
        Map<Id, Decimal> acctValues = new Map<Id, Decimal>();
        // Summary of GL amounts by vehicle component (Chassis, Conversion)
        Map<String, Decimal> componentValues = new Map<String, Decimal>();

        if (tlines==null || tlines.size()==0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'You must lookup the template rules before switching to GL inventory values.'));
        }
        if (vehTranLines==null || vehTranLines.size()==0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'There are no Vehicle Inventory GL transactions to use.'));
        }
    
        // Accumulate vehicle transactions lines by account and by component (Chassis/Conversion)
        Decimal totalValue = 0.00;
        for(c2g__codaTransactionLineItem__c t : vehTranLines) {
            totalValue += t.c2g__HomeValue__c;
    
            // Accumulate amount by GL account
            Decimal val = acctValues.get(t.c2g__GeneralLedgerAccount__c);
            if (val==null) val = 0.00;
            val += t.c2g__HomeValue__c;
            acctValues.put(t.c2g__GeneralLedgerAccount__c, val);
    
            // Accumulate amount by vehicle component (Chassis, Conversion)
            c2g__codaGeneralLedgerAccount__c acct = vehGLAcctMap.get(t.c2g__GeneralLedgerAccount__c);
            Decimal compval = componentValues.get(acct.VehicleComponent__c);
            if (compval==null) compval = 0.00;
            compval += t.c2g__HomeValue__c;
            componentValues.put(acct.VehicleComponent__c, compval);
        }
    
    
        // If we have a value in the General Ledger for this vehicle,
        // use it in place of the posting template entries for Chassis/Conversion Inventory and Chassis/Conversion Cost
        Set<String> vehTemplateActions = new Set<String>{'Chassis Inventory', 'Conversion Inventory'};
        Map<String,String> vehCOGSActionMap = new Map<String,String>{'Chassis Cost'=>'Chassis', 'Conversion Cost'=>'Conversion'};
        if (totalValue!=0) {
            for(lines l : tLines) {
                // Wipe out vehicle and conversion amounts from template
                if (vehTemplateActions.contains(l.action)) {
                    l.amount = 0;
                }
                // Set Chassis Cost and Conversion Cost lines from GL
                if (vehCOGSActionMap.containsKey(l.action)) {
                    Decimal val = componentValues.get(vehCOGSActionMap.get(l.action));
                    if (val==null) val = 0.00;
                    l.amount = val;
                }
            }
            // Create new lines that match the vehicle/conversion GL entries
            List<lines> vehLines = new List<lines>();
            for(Id acctId : acctValues.keySet()) {
                PostingTemplateEntryRule__c rule = new PostingTemplateEntryRule__c(General_Ledger_Account__c=acctId);
                c2g__codaJournalLineItem__c jline = new c2g__codaJournalLineItem__c(c2g__Dimension1__c=dim1.Id);
                lines line = new lines();
                line.amount = -acctValues.get(acctId);
                line.account = vehGLAcctMap.get(acctId);
                line.jline = jline; 
                line.action = vehGLAcctMap.get(acctId).VehicleComponent__c + ' from GL';
                line.Description = '';
                line.accountName = vehGLAcctMap.get(acctId).Name;
                line.template = rule;
                line.VIN = veh.dealer__VIN__c;
                line.StockNbr = veh.dealer__Stock_Number__c;
                line.Vehicle = veh.Id;
                line.controlNumber = veh.dealer__Stock_Number__c;
                vehLines.add(line);
            }
            // Now insert the vehicle lines at the beginning of the template...
            Integer node = 0;
            for(lines l : vehLines) {
                tlines.add(node++, l);
            }
            // Alternative to add them at the end...
            // tlines.addAll(vehLines);
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Vehicle and Conversion have no inventory value in the GL'));
        }
        calcLines();
    }


    // CalculateGP - Calculate GL gross profit by subtracting the COGS accounts (4xxx) from the Sales accounts (3xxx)
    //-------------------------------------------
    public void CalculateGP() {
        SalesTotal = 0.00;
        COGSTotal = 0.00;
        GrossProfit = 0.00;
    
        Set<Id> glIds = new Set<Id>();
        for(lines l : tLines) {
            if (l.account!=null) glIds.add(l.account.Id);
        }
        Map<Id, c2g__codaGeneralLedgerAccount__c> glMap = new Map<Id, c2g__codaGeneralLedgerAccount__c>([
            select Id, Name, c2g__ReportingCode__c
            from c2g__codaGeneralLedgerAccount__c
            where Id in :glIds
        ]);
    
        for(lines l : tLines) {
            if (l.account!=null) {
                c2g__codaGeneralLedgerAccount__c gla = glMap.get(l.account.Id);
                String acctnbr = (gla!=null && gla.c2g__ReportingCode__c!=null) ? gla.c2g__ReportingCode__c : '';
                if (!String.isBlank(acctnbr) && acctnbr.startsWith('3') && !acctnbr.startsWith('37') && !acctnbr.startsWith('3305')) {	// BLL34c not 3305
                    SalesTotal += l.amount;
                }
                if (!String.isBlank(acctnbr) && acctnbr.startsWith('4') && !acctnbr.startsWith('47')) {
                    COGSTotal += l.amount;
                }
            }
        }
        GrossProfit = -(COGSTotal + SalesTotal);    // Sales are credits, COGS are debits
        System.debug('COGS='+String.valueOf(COGSTotal));
        System.debug('Sales='+String.valueOf(SalesTotal));
        System.debug('GP='+String.valueOf(GrossProfit));
    }
    // BLL19a end


    public class lines {
        public Decimal amount {get;set;}
        public String memo {get;set;}
        public String action {get;set;}
        public String accountName {get;set;}
        public c2g__codaGeneralLedgerAccount__c account {get;set;}
        //BLL?d public String division {get;set;}
        //public c2g__codaDimension1__c dim1 {get;set;} // BLL11a
        public c2g__codaJournalLineItem__c jline {get;set;} // BLL11a
        public PostingTemplateEntryRule__c template {get;set;}
        public String VIN {get;set;}
        public String StockNbr {get;set;}
        public Id VendorId {get;set;} 
        public Id Salesperson {get;set;} 
        public String Description {get;set;} 
        public String controlNumber {get; set;}
        public Id Vehicle {get;set;}    // BLL15a
        
        public lines() {
            jline = new c2g__codaJournalLineItem__c(c2g__LineType__c='General Ledger Account');  // BLL11a
        }
        public lines(Id dim1 /*String div*/, String act, PostingTemplateEntryRule__c tmpl) {
            //BLL11d division = div;
            //dim1Id = dim1;    // BLL11a
            jline = new c2g__codaJournalLineItem__c(c2g__Dimension1__c=dim1, 
            	c2g__LineType__c='General Ledger Account');   // BLL11a
            action = act;
            template = tmpl;
        }
    }

    public class PostingException extends Exception{}
}