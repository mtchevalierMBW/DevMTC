/**
 * Deal_MBW2
 * Tested by: Deal_MBW2_Test
 * Coverage:
 *  2017-11-07  75% (1471/1943)
 *  2018-01-03  76% (1507/1971)
 *	2018-04-24	76% (1531/2015)
 *	2018-08-28	75% (1562/2061)
 *	2018-08-30	75% (1569/2074)
 *	2018-12-11	76%	(1578/2076)
 *	2019-01-10	74% (1535/2048)
 *	2019-01-16	78% (1617/2054)
 *	2019-02-04	78%	(1624/2061)
 *	2019-09-23	77% (1690/2172)
 * 
 * 2015-08-18   B. Leaman   BLL1 - correct kit search - not limiting sub category from category & mfg;
 *                       Viewstate error on large results -- try limiting to 500; Fix open query on parts kits search;
 * 2015-08-21   B. Leaman   BLL2 - set dealer__Store_Location__c!
 * 2015-08-26   B. Leaman   BLL3 - clear sublet fields after succesful add to deal.
 * 2015-08-27   B. Leaman   BLL4 - protect against location=null; not seen in production, so not moved immediately;
 * 2015-09-14   J. Kuljis   JVK1 - Prevent Proposals from being saved if the attached solution opp does not have a firs appointment set. 
 * 2015-09-22   D. Ray      DR1 - Adding parts to proposal 
 * 2015-09-22   B. Leaman   BLL5 - Limit forms to applicable states; if none specified, it's available
 * 2015-09-23   B. Leaman   BLL6 - Change field used for suggested retail price
 * 2015-09-23   D. Ray      DR2 - IN PROGRESS - After Market totaling and Service Contract totaling logic moved to trigger
 * 2015-09-28   B. Leaman   BLL7 - Don't reference person account fields if it's not a person account.
 * 2015-09-29   B. Leaman   BLL8 - Allow any visit, not just a 'First Visit', with a result of 'Show'
 *                          Actually, at least temporarily, remove JVK1 restriction.
 * 2015-09-29   D. Ray      DR3 - Add friendly Error Message
 * 2015-10-13   B. Leaman   BLL9  IT#15497 Kathi N.: Allow conversion price to be overridden
 * 2015-10-15   B. Leaman   BLL10 IT#13638 Kathi N.: add null action function for new equipment search button on QuoteManager page.
 * 2015-10-16   B. Leaman   BLL11 Need vendor for protection products 
 * 2015-10-19   J. Kuljis   JVK1 - IT13640 : Labor rate for sale of equipment off proposals should be independent of CP Labor Rate
 * 2015-10-26   B. Leaman   BLL12 IT#14367 - Show needs analysis chair info. Also prevent saving new proposal on lost Solution Opp.
 *                          Also save trade summary fields if they've changed. 
 * 2015-11-9    RedTeal  RT1 - Altered Parts-Kit queries to only include kits marked as active. If a kit is deactivated after having
 *                          been added to a proposal, it will still appear. 
 * 2015-11-11   B. Leaman   BLL13 - Avalara Sales tax support; found customer address was getting removed if B2B.  Production 2015-11-19.
 * 2015-12-01   J. Kuljis   JVK3 - IT#16965 - Service contract start date should be proposed delivery date and Account should be linked.
 * 2015-12-02   D. Ray    DR4 - Commission rate is entered as a whole number and needs to be divided by 100 to make percentage
 * 2015-12-03   B. Leaman   BLL14 - auto-save after calculate tax button.
 * 2015-12-09   B. Leaman   BLL15 - Allow proposal type drop-down to control record type.
 * 2015-12-11   RedTeal  RT2   - Check if user has permission to view transactions
 * 2015-12-21   B. Leaman   BLL16 - Added Active__c flag to service contract templates.
 * 2016-01-08   B. Leaman   BLL17 IT18227 - Record service vehicle mileage on proposal (for printing)
 * 2016-01-11   B. Leaman   BLL18 - Catch error saving.
 * 2016-01-13   B. Leaman   BLL19 IT18516 - Allow chassis price to be set to 0.
 * 2016-01-14   J. Kuljis   JVK4  - Inclde Proposal_Labor_Cost__c for default labor cost on the QuoteAddService Page controlled by this controller
 * 2016-01-19   RedTeal  RT3   - Changed the part search to search on part master instead of inventory directly. After selecting a part master, 
 *                                 checks to see if the part inventory exists for the location of the deal and creates it if it does not. 
 * 2016-01-20   B. Leaman   BLL20 - Add condition for presenting fair market value and url; // not using DoNotCollectTax flag
 * 2016-02-02   B. Leaman   BLL21 IT#19271 - Add location's main fax#; IT#19584 - set part description when creating part inventory entry.
 * 2016-02-03   B. Leaman   BLL22 IT#19642 - Get Chassis price, Conversion price from new ChassisMSRP__c and ConversionMSRP__c fields.
 * 2016-02-08   B. Leaman   BLL23 Kathi N. needs count of service contracts for commission calcs (New 22).
 * 2016-02-23   B. Leaman   BLL24 Work phone not pulling from person account, then clearing Other phone from person account.
 *                          Default "Print on proposal" to "true" for parts.
 * 2016-03-02   B. Leaman   BLL25 Getting null error on trades with missing values.
 * 2016-03-25   B. Leaman   BLL26 - IT#22404 - Add DeliveryAtStore__c flag for taxing at the store (CA sales to AZ).
 * 2016-04-20   B. Leaman   BLL27 - Only show proposal forms on the forms selection list.
 * 2016-04-27   B. Leaman   BLL28 - Flat commission on ESC products; 
 *                          no commission calc on other (mostly handled in page's javascript)
 * 2016-04-28   B. Leaman   BLL29 - Don't allow a commercial vehicle on a proposal!
 * 2016-05-04   B. Leaman   BLL30 IT#24453 - Store labor on aftermarket (kits); Separate East/West price structures;
 * 2016-05-11   B. Leaman   BLL31 IT#23750 - Get buyer county from Chassis tax line results (if there was county tax -- otherwise Avalar won't return it).
 *                          Also catch error adding service contract, stay on page and issue error message.
 * 2016-05-17   RedTeal  RT4   - Small tweak to correct an occasional error when adding a service vehicle to an equipment proposal
 * 2016-05-19   B. Leaman   BLL32 - Need to handle labor portion of item when cost is changed!
 * 2016-05-19   B. Leaman   BLL33 - Got a null error in production when setting deal.dealer__Sale_Cost__c = deal.Chassis_Price__c + deal.Conversion_Price__c;
 * 2016-05-20   B. Leaman   BLL34 - conditionally show part/labor split on paperwork. 
 * 2016-06-22   J. Kuljis   JVK5  - Add store level setting to determine if a Trade-In should use the legacy trade-add or the Appraisal Dashboard.
 * 2016-07-01   B. Leaman   BLL35 - reduce contention on next proposal number by retrieving just prior to incrementing and inserting the proposal.
 * 2016-07-05   B. Leaman   BLL36 - support chassis & conversion allowance on trade.
 * 2016-07-08   J. Kuljis   JVK6  - Finish support for East/West Costing of Parts.
 * 2016-07-26   B. Leaman   BLL37 IT#29002 - dealer__Sale_Cost__c and Conversion_Cost__c reflecting vehicle values on equipment-only sale. 
 * 2016-07-28   B. Leaman   BLL38 - Fix return after adding part or labor; Update solution opp address rather than person account address (sol opp will cascade the update to the account).
 * 2016-07-29   B. Leaman   BLL39 IT#29177 - Show info message if account address has been updated and the proposal needs to be saved. Don't update address at all if posted.
 * 2016-08-26   B. Leaman   BLL40 Don't show inactive forms.
 * 2016-08-30   B. Leaman   BLL41 New "TaxExempt" flag on after-market items.
 * 2016-09-09   B. Leaman   BLL42 - Prefer user location over solution opportunity location.
 * 2016-09-15   B. Leaman   BLL43 - Return to proposal properly after adding a trade-in.
 * 2016-09-16   B. Leaman   BLL44 - Need a way to mark a proposal lost (even if solution opp is won due to another proposal).
 * 2016-09-16   Sneha            - Added pay off fields to the trade in query for impact forms
 * 2016-09-27   B. Leaman   BLL45 - Always use proposal location's manager names when saving a new proposal.
 * 2016-09-28   B. Leaman   BLL46 - Stub for using our own FDF routine instead of DealerTeam's.
 * 2016-11-01   B. Leaman   BLL47 - Special F&I update routine (god mode).
 * 2016-12-05   B. Leaman   BLL48 - Allow single quotes in search string (e.g. Q'Straint)
 * 2016-12-09   B. Leaman   BLL49 #IR-0004388 - Record last save date. To be used in trigger when pushed to "Delivered" status to ensure
 *                          proposal GP is up-to-date.
 * 2016-12-12   B. Leaman   BLL50 IR-0004461 - Sort kit categories.
 * 2016-12-29   B. Leaman   BLL51 - Replace custom lookups with managed versions (Deal obj)
 * 2017-01-26   B. Leaman   BLL52 - Commercial Proposal project.
 *                          (also change method name saveRetailProposal to saveProposal - unmarked mod)
 * 2017-01-31   B. Leaman   BLL53 - Add "buyer" variable like FDF forms provide for buyer account details.
 * 2017-04-05   B. Leaman   BLL54 - Allow manual conversion cost until costs show up on vehicle.
 * 2017-04-19   B. Leaman   BLL55 - Don't reset chassis & conversion sell prices when a vehicle is added.
 * 2017-04-28   B. Leaman   BLL56 - Copy CMC 1 to Commission Employee 1 (since commission employee field is no longer on-screen).
 *                          Also, BLL54 needs to allow for $0 conversion cost (diff from NULL conversion cost).
 * 2017-05-02   B. Leaman   BLL57 - Mark quote lost if proposal is lost.
 * 2017-05-12   B. Leaman   BLL58 - Pull in service vehicle VIN, Year, Make, Model if specified and no inventory vehicle.
 * 2017-05-23   B. Leaman   BLL59 - Additional service vehicle fields needed for emailing PDF -- need to add specifically to record retrieval when 
 *                          PDF is rendered using getContentAsPDF().
 * 2017-05-24   B. Leaman   BLL60 - selective recalc for deal screen based on status.
 * 2017-06-01   B. Leaman   BLL61 - new ESC type.
 * 2017-06-05   B. Leaman   BLL62 - conditional display of forms for a record.  
 * 2017-06-09   B. Leaman   BLL63 - Changes for BancLease, MobilityGuard Powertrain, sub-prime loan fee.
 * 2017-07-07   B. Leaman   BLL64 - Always retrieve all location fields, don't limit to 3 trade-ins.
 * 2017-08-11   B. Leaman   BLL65 - Integrate leasecalculator into proposals; Add tax override basis; IR-0018049 Exterior color veh not in stock
 *                          selectProduct - trap error upon insert & improve reporting of the error.
 * 2017-09-21   B. Leaman   BLL66 IR-0020088 Exclude obsolete parts in parts search, IR-0014608 active flag for "Kit Category".
 * 2017-10-06   B. Leaman   BLL67 IR- Only allow entry of sales tax override for leases. Also need to allow override if avalara result is $0 
 *                          for out-of-state sales taxes to be included in funding.
 * 2017-10-13   B. Leaman   BLL68 - Require loan/lease acquisition cost/fee if a value is specified on the finance company record.
 * 2017-11-01   B. Leaman   BLL69 - Update Exterior color on service veh.
 * 2017-11-17   B. Leaman   BLL70 - store part# on proposal added equipment (after market).
 * 2017-11-27   B. Leaman   BLL71 - reactivate protection against commercial veh on retail proposal. 
 * 2017-11-29   B. Leaman   BLL72 - only apply lease/loan acquisition fee/cost if deal is financed!; Allow re-opening lost proposal; reimbursed GAP
 * 2018-01-22   B. Leaman   BLL73 - service contract chgs (always select all fields);
 * 2018-02-15   B. Leaman   BLL74 - Billing email support for non-person accounts.
 * 2018-03-02   B. Leaman   BLL75 - Mark associated appraisals lost when proposal is lost; Include part supersedes fields when searching by part#/name.
 *                                  // Similar logic in BatchUpdateInactiveDeals, Deal_MBW2, DealProcess
 * 2018-03-30   B. Leaman   BLL76 - GP Sharing.
 * 2018-04-11	B. Leaman	BLL77 - Only look back through open or first completed transfer - not old transfers to this store.
 * 2018-04-24	B. Leaman	BLL78 - include commercial categories when searching kits from kits tab rather than from a proposal.
 * 2018-04-25	B. Leaman	BLL79 - no releasing dealer on retail proposals; reset mileage when vehicle is changed to another vehicle;
 *							Don't use Avatax until deal is saved (and has an Id);
 * 2018-05-11	B. Leaman	BLL80 - Remove GP Sharing on customer-owned vehicle; issue enforcing loan/lease acquisition costs on the salesperson
 *							who cannot maintain that value.
 *	2018-05-25	B. Leaman	BLL81 - Support for required document/certification for tax reduction.
 *	2018-07-24	B. Leaman	BLL82 - Remove GP sharing if vehicle is a prior rental.
 *	2018-08-15	B. Leaman	BLL83 - Require rebate description if rebate$ is filled in;
 *                          IR-0038939 Don't allow print on pg 2 for NMEDA fee;
 *	2018-08-22	B. Leaman	BLL84 - lightning: remoteactions not available from forms page; std new button doesn't pass in customer account (buyer)
 *							Also fix? conversion price reset on new vehicle selection;
 *							calculate total residual amt field(s); require finance amt if proposal is financed;
 *							error if leased and amt due<=0 and deposit=0 (first pmt added to financed amt)
 *	2018-09-26	B. Leaman	BLL85 - Make purchase agreement print available from front proposal screen.
 *  2018-10-18  A. Miller   AMM86 - W-000371 - Update to handle the Print Merging
 *  2018-10-08  A. Miller   AMM87 - W-000413 - Update to handle the new lightning file archictecture 
 *  2018-11-07  B. Leaman   W-000483    BLL86 - Fix store pack handling (reset to null instead of $0 for non-vehicle sales) 
 *                                      Open question about authority to update the store pack field; 
 *	2018-12-03	B. Leaman	W-000505 BLL87 - Bank of Amer charges loan acquisition fee in Ohio; need to support fee for loans as well as leases
 *	2018-12-04	B. Leaman	W-000509	BLL88 - don't prohibit printing NMEDA label on page 2, just leave that it defaults to page 1.
 *	2018-12-11	B. Leaman	W-000519 BLL89 - New Purchase Agreement form for Calif. (Mod to BLL85)
 *	2019-01-07	B. Leaman	W-000538 BLL90 - Need additional salesperson 1 name fields -- consolidate additional fields logic.
 *	2019-01-09	B. Leaman	W-000482 BLL91 - Approve/Revoke VA Paperwork;
 *	2019-01-16	B. Leaman	W-000553 BLL92 - clear out conversion description if it's not a vehicle sale.
 *	2019-02-04	B. Leaman	W-000576 BLL93 - when the vehicle violates the Commercial/Retail rules that the cost, conversion description and the Vin Make Model that automatically filled, be cleared;
 *							Also remove conversion discount on wholesale proposals (field is not displayed, but can hold a value if proposal type was changed);
 *							Also sequence kit search results by name; Remove releasing dealer if not a vehicle sale;
 *	2019-02-11	B. Leaman	W-000591 BLL94 - Support for default Loan acquisition fee (BoA in Ohio).
 *				NOTE!		This change requires moving the default subprime loan acquisition cost to the new acquisition cost field!
 *	2019-03-04	B. Leaman	W-000579 BLL95 new F&I process moved to lightning component.
 *	2019-03-19	B. Leaman	W-000624 BLL96 don't update account (buyer county) from Avalara result, as this could come from items taxed at the store 
 *							instead of at the buyer's address. Only write back to the account if the account's county is missing.
 *							Also fix sequence of events to "SetAssociatedVehicle" sees deal location instead of user location.
 *							Also reset GP Sharing date when vehicle is changed.
 *  2019-03-18  A. Miller   W-000582 AMM95 - Update to handle favorites
 *  2019-05-08  A. Miller   IR-0054081 AMM96 - Update to make sure the favorites don't automatically popup on Proposals
 *  2019-05-14  A. MIller   IR-0047640 AMM97 - Update to handle showing attachments on the DealEmail page
 *	2019-05-16	B. Leaman	IR-0033366 BLL97 - update commercial account market segment always, not only if won.
 *	2019-06-18	B. Leaman	W-000709 BLL98 - redirect to standard view page so lightning page displays after creating proposal.
 *	2019-07-22	B. Leaman	W-000719 BLL99 - allow MBW Buyer sourced vehicle for GP Sharing & allow prior rental as well.
 *	2019-07-23	B. Leaman	W-000606 BLL100 - Financial Products proposal ESC Loan costs to be applied against F&I GP instead of regular GP.
 *	2019-07-30	B. Leaman	W-000703 BLL101 - Use static price in favor of list, if it's specified.
 *	2019-08-08	B. Leaman	BLL102 - add new aftermarket items to the end of the list if it's been ordered at all.
 *	2019-08-08	B. Leaman	W-000719 BLL103 - GP sharing updates, (9/24) also only applies to used vehicles (not even new/used)
 *	2019-08-28	B. Leaman	W-000747 BLL104 - separate approvers & owner for home access proposals.
 *	2019-10-18	B. Leaman	W-000768 BLL105 - Do not set automatic doc fees on wholesale proposals (originally implemented on BLL52)
 *	2019-11-01	B. Leaman	W-000775 BLL106 - correct kit search - favorites only if no other criteria
 *	2019-11-25	B. Leaman	W-000795 BLL107 - Can't search on notes anymore, as they're increased past 256 characters.
 */ 
global with sharing class Deal_MBW2 {

    // BLL52a - page references
    // If needed, use the new PageReference('/apex/pagename') syntax to avoid catch-22s
    private PageReference self = Page.DealMBW2;                     // new PageReference('/apex/DealMBW2');                         
    private PageReference vehsearch = Page.VehicleSearchAdvanced;   // new PageReference('/apex/VehicleSearchAdvanced'); 
    private PageReference addServicePage = Page.Deal_AddService2;   // new PageReference('/apex/Deal_AddService2'); 
    private PageReference addSubletPage = Page.Deal_AddSublet2;     // new PageReference('/apex/Deal_AddSublet2'); 
    private PageReference addPartPage = Page.Deal_AddPart2;         // new PageReference('/apex/Deal_AddPart2'); 
    private PageReference svcContractPage = Page.Deal_SvcContract2; // new PageReference('/apex/Deal_SvcContract2'); 
    private PageReference tradeInPage = Page.Deal_TradeIn2;         // new PageReference('/apex/Deal_TradeIn2'); 
    private PageReference commercialQuote = Page.CQ2;               // new PageReference('/apex/CQ2'); 
    private PageReference clonePage = Page.ProposalClone;           // new PageReference('/apex/ProposalClone'); 
    private PageReference emailPage = Page.DealEmail;               // new PageReference('/apex/DealEmail');
    // BLL52a end
	private PageReference formManagerPage = Page.FormManager;
    // AMM86
    private PageReference formManagerPagePrintMerge = Page.FormManagerPrinting;
    // AMM86	
	// BLL85a
	public dealer__Form__c purAgreement { get {
		// BLL89
		//List<dealer__Form__c> purAgree = [
		//	select Id, Name, dealer__DocumentContentId__c, dealer__Form_ID__c, dealer__Active__c, dealer__Flatten__c 
		//	from dealer__Form__c 
		//	where dealer__Form_ID__c='PUR-AGREE' and dealer__Active__c=true limit 1
		List<dealer__Form__c> purAgree = [
			select Id, Name, dealer__DocumentContentId__c, dealer__Form_ID__c, dealer__Active__c, dealer__Flatten__c 
			from dealer__Form__c 
			where dealer__Form_ID__c like 'PUR-AGREE%' and dealer__Active__c=true 
			  and (States_Available__c=null or States_Available__c includes(:location.dealer__State__c))
			limit 1
		];
		// BLL89 end
		return purAgree.size()>0 ? purAgree[0] : null;
	}}
	// BLL85a end

    /* Declarations */ 
    public dealer__Deal__c deal {get;set;}
    public dealer__Vehicle_Inventory__c vehicle {get;set;}  // BLL52c
    public Decimal vehOptionsPrice  {get; set;} // BLL52a
    public dealer__Trade_In__c tradeData {get;set;}
    public String deleteEquipmentId {get;set;}
    public transient boolean autoSaveDeal {get;private set;} // BLL12a, BLL52c chg from AutoSaveTrade 
    public boolean viewTransactions {get; private set;}//RT2
    public boolean useFMV {get;private set;} // BLL20a
    public String fmvURL {get;private set;} // BLL20a
    public String TaxCertificateRequired {get;private set;} // BLL81a
    public boolean showChassisTaxableBox {get;private set;} // BLL20a
    public boolean showPartLaborSplit {get;private set;} // BLL34a
    public boolean BuyerDetailsChanged {get;private set;} // BLL39a
    // BLL52a
    public string tabstyle {get;private set;} 
    private Set<String> vehicleSaleTypes = new Set<String>{'Retail Vehicle Sale','Wholesale','Chassis/Conversion'};
    public boolean isVehicleSale {get { return vehicleSaleTypes.contains(deal.dealer__Deal_Type__c);}} 
    private Set<String> customerVehicleSaleTypes = new Set<String>{'Equipment Only','Equipment Only Sale','Financial Products'};
    public boolean isCustomerVehicle {get { return customerVehicleSaleTypes.contains(deal.dealer__Deal_Type__c) || deal.Vehicle_Source__c=='Customer Owned';}}
    public CommercialQuote__c oem {get;private set;}
    public Decimal oemOptionsPrice  {get;set;} // BLL52a
    public boolean showRebates {get;private set;}
    public String ConversionDetailSource {get;private set;}
    private Map<String,String> dealTypeMap = new Map<String,String>{
            'Chassis/Conversion'=>'Chassis/Conversion', 'Chassis_Conversion'=>'Chassis/Conversion', 
            'Equipment'=>'Equipment Only', 'Equipment Only'=>'Equipment Only', 'Rental'=>'Chassis/Conversion', 
            'Service'=>'Chassis/Conversion', 'No Contact'=>'Chassis/Conversion', 'Wholesale'=>'Wholesale', 
			'Home Access'=>'Home Access',	// BLL104
            'DME/Other'=>'DME/Other','DME_Other'=>'DME/Other', 'Financial Products'=>'Financial Products'}; 
    private dealer__Sales_Up__c sup;    // BLL52a
    public boolean vehHasCommercialOptions {get;private set;}

    // Email Settings
    public String toAddress {get;set;}
    public String subject {get;set;}
    public String body {get;set;}
    public String emailTo   {get;set;} 
    public String emailPageName {get;set;}  
    public Attachment attachment;
    public Blob aBody {get;set;}
    public String aContentType {get;set;}
    public String aFileName {get;set;}
    public List<Id> attachmentList = new List<Id>();
    private Map<String,String> dftProposalPDF = new Map<String,String>{
        'Retail'=>'Form_ProposalPreview', 'Commercial'=>'Form_ProposalCommercial',
        'Retail Vehicle Sale'=>'Form_ProposalPreview', 'Equipment Only Sale'=>'Form_ProposalPreview'
    };
    private Map<String,String> dftReleasingDealerPDF = new Map<String,String>{
        'Retail'=>'Form_ProposalPreview', 'Commercial'=>'Form_ReleasingDealerInvoice'
    };
    public String defaultPDF {get;set;}
    // BLL52a end
    
    // BLL53a
    public Account buyer {get; private set;}
    public Account cobuyer {get; private set;}
    // BLL53a end

    // Storing Settings for future use.
    public RetailDefaults__c userConfig { get; set; }
 
    public List<dealer__Trade_In__c> tradeInList {
    
        get {
            if(deal.Id!=null) {
            return [SELECT dealer__Car_Deal__c, dealer__ACV__c, dealer__Appraisal_Date__c, dealer__Appraised_By__c, dealer__Black_Book_Retail__c,    
                        dealer__Black_Book_Wholesale__c, dealer__K_B_B_Retail__c, dealer__K_B_B_Wholesale_Value__c, dealer__Lost_Trade__c, 
                        dealer__Make__c, dealer__Model__c, dealer__NADA_Retail__c, dealer__NADA_Wholesale__c, dealer__Odometer_at_Trade_In__c, 
                        dealer__Pay_Off_Amount__c, dealer__Pay_Off_Expiration_Date__c, dealer__Pay_Off_To__c, dealer__Position__c, 
                        dealer__Stock_Number__c, dealer__Trade_Allowance__c, dealer__VIN__c, dealer__Year__c, Gross_Trade_In_Value__c, 
                        Over_Under_Allowance__c,  Lien_Holder_Address__c, Trade_In_Notes__c, dealer__Pay_Off_Account_Number__c,
                        Payoff_Quoted_Date__c ,Payoff_Phone__c ,Payoff_Contact__c,
                        Unit_Type__c, Type__c, Sale_Type__c, Id, Name, Mobility_Equiped__c, Net_Value__c,
                        (select Id, Name from dtmob__Appraisals__r) 
                        FROM dealer__Trade_In__c
                        Where dealer__Car_Deal__c=:deal.Id
                        ]; /* limit 3 */
            } else {
                return new List<dealer__Trade_In__c>();
            }
        }
        set;
    }
    public Decimal tradeValue {
        get {
            if(deal.Id!=null) {
                AggregateResult[] sumTrade = [Select SUM(Net_Value__c) tsum FROM dealer__Trade_In__c where dealer__Car_Deal__c =: deal.Id];
                return (decimal) sumTrade[0].get('tsum');   
            } else return 0;
        }
        set;
    }
    
    // public CommercialDefaults__c commercialDefaults = CommercialDefaults__c.getOrgDefaults();
    public RetailDefaults__c retailDefaults = RetailDefaults__c.getOrgDefaults();
    public List<dealer__Parts_Master__c> partMasterResults = new List<dealer__Parts_Master__c>();
    public List<dealer__Parts_Inventory__c> partResults = new List<dealer__Parts_Inventory__c>();
    //RT3
    public List<dealer__Parts_Master__c> getPartsResults() { return partMasterResults; }
    public String escDescription {get;set;}
    public String escCode {get;set;}
    public String escType {get;set;}
    public String escMileage {get;set;}
    public String escSelectedId {get;set;}
    public List<dealer__Service_Contract__c> escResults {get;set;}
    public String deleteProductId {get;set;}
    // BLL63a
    public boolean hasMobilityGuardPowertrain {
        get {
                if(deal.Id!=null) {
                    return [select Id, Name, Type__c from dealer__Service_Contract__c 
                            where dealer__Car_Deal__c =: deal.Id and Type__c='MobilityGuard Powertrain'].size()>0;
                } else {return false;}
        }
    }
    // BLL63a end
    public List<dealer__Service_Contract__c> soldOnProposal {
        get {
            if(deal.Id!=null) {
                return [SELECT dealer__Contract_Template__c, dealer__Cost__c,    
                                            dealer__Customer_Contact__c, dealer__Customer__c, dealer__Deductable__c, dealer__Description__c, 
                                            dealer__End_Date__c, dealer__Expiration_Mileage__c, dealer__Expiration_Months__c,
                                            dealer__Plan_Code__c, dealer__Product_Code__c, dealer__Sale_Price__c, dealer__Service_Vehicle__c,
                                            dealer__Start_Date__c, dealer__Vehicle_Inventory__c, Type__c, Name, Id 
                                            FROM dealer__Service_Contract__c 
                                            Where dealer__Car_Deal__c =: deal.Id
                                            Limit 100];          
            } else {
                return new List<dealer__Service_Contract__c>();
            }
        }
        set;
    }

    // BLL62 Used for impact form printing
    public List<dealer__Service_Contract__c> soldOnProposalSC {
        get {
            if(deal.Id!=null) {
                return [SELECT dealer__Contract_Template__c, dealer__Cost__c, 
                                            dealer__Customer_Contact__c, dealer__Customer__c, dealer__Deductable__c, dealer__Description__c, 
                                            dealer__End_Date__c, dealer__Expiration_Mileage__c, dealer__Expiration_Months__c,
                                            dealer__Plan_Code__c, dealer__Product_Code__c, dealer__Sale_Price__c, dealer__Service_Vehicle__c, 
                                            dealer__Start_Date__c, dealer__Vehicle_Inventory__c, Type__c, Name, Id 
                                            FROM dealer__Service_Contract__c 
                                            Where dealer__Car_Deal__c =: deal.Id
                                            AND (Type__c = 'Service Contract' OR Type__c = 'Roadside Protection')
                                            Limit 100];          
            } else return new List<dealer__Service_Contract__c>();
        }
        set;
    }
    
    public List<dealer__Service_Contract__c> soldOnProposalGAP {
        get {
            if(deal.Id!=null) {
                return [SELECT dealer__Contract_Template__c, dealer__Cost__c,  
                                            dealer__Customer_Contact__c, dealer__Customer__c, dealer__Deductable__c, dealer__Description__c, 
                                            dealer__End_Date__c, dealer__Expiration_Mileage__c, dealer__Expiration_Months__c,
                                            dealer__Plan_Code__c, dealer__Product_Code__c, dealer__Sale_Price__c, dealer__Service_Vehicle__c, 
                                            dealer__Start_Date__c, dealer__Vehicle_Inventory__c, Type__c, Name, Id 
                                            FROM dealer__Service_Contract__c 
                                            Where dealer__Car_Deal__c =: deal.Id
                                            AND Type__c = 'GAP'
                                            Limit 100];          
            } else return new List<dealer__Service_Contract__c>();
        }
        set;
    }
    
    public List<dealer__Service_Contract__c> soldOnProposalDF {
        get {
            if(deal.Id!=null) {
                return [SELECT dealer__Contract_Template__c, dealer__Cost__c,    
                                            dealer__Customer_Contact__c, dealer__Customer__c, dealer__Deductable__c, dealer__Description__c, 
                                            dealer__End_Date__c, dealer__Expiration_Mileage__c, dealer__Expiration_Months__c,
                                            dealer__Plan_Code__c, dealer__Product_Code__c, dealer__Sale_Price__c, dealer__Service_Vehicle__c, 
                                            dealer__Start_Date__c, dealer__Vehicle_Inventory__c, Type__c, Name, Id 
                                            FROM dealer__Service_Contract__c 
                                            Where dealer__Car_Deal__c =: deal.Id
                                            AND Type__c = 'Diamond Fusion'
                                            Limit 100];          
            } else return new List<dealer__Service_Contract__c>();
        }
        set;
    }
    
    public List<dealer__Service_Contract__c> soldOnProposalRoad {
        get {
            if(deal.Id!=null) {
                return [SELECT dealer__Contract_Template__c, dealer__Cost__c, 
                                            dealer__Customer_Contact__c, dealer__Customer__c, dealer__Deductable__c, dealer__Description__c, 
                                            dealer__End_Date__c, dealer__Expiration_Mileage__c, dealer__Expiration_Months__c,
                                            dealer__Plan_Code__c, dealer__Product_Code__c, dealer__Sale_Price__c, dealer__Service_Vehicle__c, 
                                            dealer__Start_Date__c, dealer__Vehicle_Inventory__c, Type__c, Name, Id 
                                            FROM dealer__Service_Contract__c 
                                            Where dealer__Car_Deal__c =: deal.Id
                                            AND Type__c = 'Roadside Protection'
                                            Limit 100];          
            } else return new List<dealer__Service_Contract__c>();
        }
        set;
    }
    // BLL64a
    public List<dealer__Service_Contract__c> soldOnProposalMGP {
        get {
            if(deal.Id!=null) {
                return [SELECT dealer__Contract_Template__c, dealer__Cost__c, 
                                            dealer__Customer_Contact__c, dealer__Customer__c, dealer__Deductable__c, dealer__Description__c, 
                                            dealer__End_Date__c, dealer__Expiration_Mileage__c, dealer__Expiration_Months__c,
                                            dealer__Plan_Code__c, dealer__Product_Code__c, dealer__Sale_Price__c, dealer__Service_Vehicle__c, 
                                            dealer__Start_Date__c, dealer__Vehicle_Inventory__c, Type__c, Name, Id 
                                            FROM dealer__Service_Contract__c 
                                            Where dealer__Car_Deal__c =: deal.Id
                                            AND (Type__c = 'Mobility Guard Powertrain')
                                            Limit 100];          
            } else return new List<dealer__Service_Contract__c>();
        }
        set;
    }
    // BLL64a end
    
    // BLL62d end unused

    public String thumbnailURL {get;set;}
    public String selectCategory { get; set; }
    public String selectMFG { get; set; }
    public String selectSubCat { get; set; }
    public List<cPartsKit> aKits { get; set; }
    public List<cPartsKit> cParts { get; set; }
    public List<dealer__After_Market__c> selectedKits {
        get {
            if(deal.Id != null) {
                List<dealer__After_Market__c> items = [SELECT Id, Name, dealer__Quantity__c, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, dealer__Car_Deal__c, // BLL52c add quantity 
                dealer__Company_Number__c, dealer__Cost__c, dealer__Description__c, dealer__Labor_Sale__c, dealer__List_Price__c, 
                dealer__Parts_Kit__c, dealer__Parts_Sale__c, dealer__Sale_Price__c, dealer__Vendor__c, Labor_Hours__c, Taxable__c,Page_Order__c, Print_on_Proposal__c,
                ExtendedCost__c, ExtendedPrice__c, ExtendedGross__c, ExtendedLaborPrice__c, dealer__Part_Cost__c,   // BLL52a
                TaxExempt__c    
                FROM dealer__After_Market__c
                Where dealer__Car_Deal__c =: deal.Id 
                and dealer__Car_Deal__c != null
                Order By Page_Order__c ASC
                Limit 500];
                // BLL41a added TaxExempt__c above
                // BLL52a - adjust for lines that don't have qty -- assume 1 and adjust unit sale & cost
                for(dealer__After_Market__c item : items) {
                    if (item.dealer__Parts_Sale__c==null) item.dealer__Parts_Sale__c=0;
                    if (item.dealer__Part_Cost__c==null) item.dealer__Part_Cost__c=0;
                    if (item.dealer__Labor_Sale__c==null) item.dealer__Labor_Sale__c=0;
                    if (item.dealer__Quantity__c==null) {
                        item.dealer__Quantity__c=1;
                    //  item.dealer__Part_Cost__c = dealer__Cost__c - dealer__Labor_Cost__c;
                    //  if (item.Labor_Hours__c!=null && item.Labor_Hours__c>0) {
                    //      item.dealer__Parts_Sale__c = item.dealer__Sale_Price__c - item.dealer__Labor_Sale__c;
                    //      if (item.dealer__Parts_Sale__c<0) { 
                    //          item.dealer__Parts_Sale__c = 0;
                    //          item.dealer__Labor_Sale__c = dealer__Sale_Price__c;
                    //      }
                    //  } else {
                    //      item.dealer__Parts_Sale__c = item.dealer__Sale_Price__c;
                    //  }
                    }
                }
                // BLL52a end
                return items;
            } else {
                return new List<dealer__After_Market__c>();
            }
        }
        set;
    }
    public Decimal afterMarketTotal {
        get {
            if(deal.Id!=null) {
                //BLL52d AggregateResult[] sumAftermarket = [Select SUM(dealer__Sale_Price__c) amsum FROM dealer__After_Market__c where dealer__Car_Deal__c =: deal.Id];
                AggregateResult[] sumAftermarket = [    
                    select SUM(ExtendedPrice__c) amsum 
                    from dealer__After_Market__c 
                    where dealer__Car_Deal__c =: deal.Id
                ];	// BLL52a
                Decimal sum = (decimal) sumAftermarket[0].get('amsum');
                if(sum==null) 
                    sum=0.00;
                return sum;
            } else {
                return 0;
            }
        }   
        set;
    }

    // BLL30a
    public Decimal afterMarketLbrTotal {
        get {
            if(deal.Id!=null) {
                //BLL52d AggregateResult[] sumAftermarket = [Select SUM(dealer__Labor_Sale__c) amsum FROM dealer__After_Market__c where dealer__Car_Deal__c =: deal.Id];
                AggregateResult[] sumAftermarket = [    // BLL52a
                    select SUM(ExtendedLaborPrice__c) amsum 
                    from dealer__After_Market__c 
                    where dealer__Car_Deal__c =: deal.Id
                ];
                Decimal sum = (decimal) sumAftermarket[0].get('amsum');
                if(sum==null) sum=0.00;
                //BLL52d AggregateResult[] sumAddedLabor = [Select SUM(dealer__Sale_Price__c) amsum FROM dealer__After_Market__c where dealer__Car_Deal__c =: deal.Id and dealer__Parts_Kit__c=null and (Labor_Hours__c>0 or Name like 'Service %')];
                AggregateResult[] sumAddedLabor = [ // BLL52a
                    select SUM(ExtendedPrice__c) amsum 
                    from dealer__After_Market__c 
                    where dealer__Car_Deal__c =: deal.Id and dealer__Parts_Kit__c=null 
                      and (Labor_Hours__c>0 or Name like 'Service %')
                ];
                Decimal sum2 = (decimal) sumAddedLabor[0].get('amsum');
                if (sum2!=null) sum += sum2;
                System.debug(sum);
                return sum;
            } else {
                return 0;
            }
        }   
        set;
    }
    // BLL30a end
    public Decimal serviceContractTotal {
        get {
                if(deal.Id != null) {
                    AggregateResult[] sumESC = [Select SUM(dealer__Sale_Price__c) amsum FROM dealer__Service_Contract__c where dealer__Car_Deal__c =: deal.Id];
                    return (decimal) sumESC[0].get('amsum');                
                } else {
                    return 0;
                }
            }
            set;
    }

    public String addKitId {
            get;
            set {
                addKitId = value;
            }
    }

    public String subletDescription {get;set;}
    public Decimal subletCost {get;set;}
    public Decimal subletSale {get;set;}
    public String searchByPartNumber {get;set;}
    public Id selectedPartNumber {get;set;}
    public String searchByDescription {get;set;}
    public String searchByNotes {get;set;}
    public wMultiQuote multiquote {get;set;}
    public String recordTypeName {get;set;}
    public String recordTypeLabel {get;set;}
    //BLL52d public List<RecordType> recordTypes {
    //BLL52d     get {
    //BLL52d         return [SELECT Name, Id, DeveloperName, SobjectType FROM RecordType where SobjectType='dealer__Deal__c' limit 10];
    //BLL52d     }
    //BLL52d     set;
    //BLL52d }

    public List<dealer__Form__c> formList {
        // BLL5 - add Where clause for States_Available__c = null or location's state
        get {
            return [
            SELECT dealer__Active__c, dealer__Form_ID__c, dealer__Impact_Code__c, dealer__Library__c, dealer__Page_Name__c, dealer__Print_Type__c, dealer__Proofed_by__c, 
                dealer__Revision_Date__c, dealer__Sequence__c, Name, Id, dealer__Flatten__c, dealer__DocumentContentId__c,
                AvailabilityExpression__c   
            FROM dealer__Form__c
            where (DocumentType__c=null or DocumentType__c includes ('Proposal')) 
              and (States_Available__c=null or States_Available__c includes (:deal.dealer__Buyer_State__c) or States_Available__c includes(:location.dealer__State__c))
              and dealer__Active__c=true    
            Order by dealer__Sequence__c ASC 
            limit 500];
			// BLL62a add AvailabilityExpression__c 
			// BLL40a dealer__Active__c=true
			// BLL27c DocumentType__c=null or DocumentType__c includes ('Proposal')
            // Updated SOQL to include the State of the Buyer, not the selling Dealer.
        }
    }

    public dealer__Dealer_Location__c location { get;set; }

    public User cmc {get;set;}

    public Account accountInfo {get; private set;} // BLL12a 
    // BLL13a
    private AvaTax_MBW dealTaxation; 
    public list<DealTaxes__c> Taxes;
    public Decimal TaxTotal {
        get {
            Decimal total = 0.00;
            if (Taxes==null) getTaxes();
            if (Taxes!=null) {
                for (DealTaxes__c t : Taxes) total += t.Tax__c;
            }
            return total;
        }
        private set;
    }
    // BLL13a end
    
    // AMM95
    public Boolean showFavorites {get;set;}
    // AMM95
    
    // BLL62a
    public Component.Apex.outputPanel getFormsTableRows() {
        Component.Apex.outputPanel op = new Component.Apex.outputPanel();
        op.childComponents.add(new Component.Apex.outputText(escape=false,
            value='<table class="table table-hover"><tr><th>Name</th><th>Form ID</th><th>Revision Date</th><th>Action</th></tr>'
        ));
        //List<Component.Apex.outputText> ftrows = new List<Component.Apex.outputText>();
        // BLL62a add AvailabilityExpression__c
        // BLL27c add DocumentType__c=null or DocumentType__c includes ('Proposal')
        // BLL40a dealer__Active__c=true
        for(dealer__Form__c f : [
                SELECT dealer__Active__c, dealer__Form_ID__c, dealer__Impact_Code__c, dealer__Library__c, dealer__Page_Name__c, dealer__Print_Type__c, dealer__Proofed_by__c, 
                    dealer__Revision_Date__c, dealer__Sequence__c, Name, Id, dealer__Flatten__c, dealer__DocumentContentId__c,
                    AvailabilityExpression__c   
                FROM dealer__Form__c
                where (DocumentType__c=null or DocumentType__c includes ('Proposal'))  
                  and (States_Available__c=null or States_Available__c includes (:deal.dealer__Buyer_State__c) or States_Available__c includes(:location.dealer__State__c))
                  and dealer__Active__c=true    
                Order by dealer__Sequence__c ASC 
                limit 500]) {
            Component.Apex.outputText ot = new Component.Apex.outputText();
            ot.escape=false;
            if (!String.isBlank(f.AvailabilityExpression__c)) {
                ot.expressions.rendered=f.AvailabilityExpression__c;
            } else {
                ot.rendered=true;
            }
            String button = '';
            if (f.dealer__Print_Type__c=='Laser') {
                button += '<button class="btn btn-primary btn-xs" onclick="window.open(\'/apex/' + f.dealer__Page_Name__c + '?id=' + deal.Id + '\')">Print Laser Document</button>';
            }
            if (f.dealer__Print_Type__c=='Impact') {
                button += '<button class="btn btn-primary btn-xs" onclick="printImpactForm(\'' + f.Id + '\')">Print Impact Form</button>';
            }
            if (f.dealer__Print_Type__c=='FDF') {
                button += '<button type="button" id="printPDFButton" onclick="printPDF_FDF(\'' + f.Id + '\', \'' + f.dealer__DocumentContentId__c + '\', \'' + f.dealer__Flatten__c + '\', \'' + f.Name + '\')" '   
                    + ' class="btn btn-primary btn-xs">Print Laser Form</button>';
            }
            
            ot.value='<tr>'  
                + '<td>' + f.Name + '</td>'
                + '<td>' + (f.dealer__Form_ID__c!=null?f.dealer__Form_ID__c:'') + '</td>'
                + '<td>' + (f.dealer__Revision_Date__c!=null?f.dealer__Revision_Date__c.format():'') + '</td>'
                + '<td>' + button + '</td>'
                + '</tr>';
            op.childComponents.add(ot);
        }
        //System.debug(ftrows.size());
        //op.childComponents.add(ftrows);
        op.childComponents.add(new Component.Apex.outputText(escape=false, value='</table>'));
        return op;
    }
    // BLL62a end
    
    // BLL65a
    public LeaseCalculator lease {get;private set;}
    public boolean ShowTradeRecordLink {get; set;}
    // BLL65a end
    private dealer__Finance_Company__c fia; // BLL68a
    
    // AMM95
    public Map<Id, Boolean> mapOfFavoritedPartKits {get;set;}
    // AMM95
     
    /* Controller */
    public Deal_MBW2(ApexPages.StandardController controller) {

        // AMM95
        showFavorites = true; // init to true on load
        // AMM95

        // Get all the custom field for use in the VF UI
        // BLL90
        //Map<String, Schema.SObjectField> M = Schema.SObjectType.dealer__Deal__c.fields.getMap();
		//List<String> af = new List<String>();
		// BLL90
		/* BLL90
        Set<String> fieldnames = M.keySet(); 
        af.add('dealer__Vehicle__r.dealer__VIN__c');
        af.add('dealer__Vehicle__r.Conversion__c');
        af.add('dealer__Vehicle__r.Conversion__r.dealer__Description__c');
        af.add('dealer__Vehicle__r.New_Used_Other__c');
        af.add('dealer__Vehicle__r.Unit_Type__c');
        af.add('dealer__Vehicle__r.dealer__Body_Type__c');
        af.add('dealer__Vehicle__r.dealer__Fuel_Type__c');
        af.add('dealer__Vehicle__r.dealer__VIN__c');
        af.add('dealer__Vehicle__r.dealer__Mileage__c');
        af.add('dealer__Vehicle__r.Name');
        af.add('dealer__Finance_Institution_Account__r.Name');
        af.add('dealer__Finance_Institution_Account__r.dealer__Bank_Address__c');
        af.add('dealer__Finance_Institution_Account__r.dealer__Bank_City__c');
        af.add('dealer__Finance_Institution_Account__r.dealer__Bank_State__c');
        af.add('dealer__Finance_Institution_Account__r.dealer__Bank_Zip__c');
        af.add('dealer__Finance_Institution_Account__r.FinanceAccount__c');
        af.add('dealer__Co_Buyer__r.FirstName');
        af.add('dealer__Co_Buyer__r.MiddleName');
        af.add('dealer__Co_Buyer__r.LastName');
        af.add('TaxHash__c'); // BLL13a
        af.add('dealer__Service_Vehicle__c'); // BLL17a, BLL51c
        af.add('dealer__Service_Vehicle__r.dealer__Last_Odometer__c'); // BLL17a, BLL51c
        af.add('dealer__Vehicle__r.dealer__Vehicle_Cost__c'); // BLL19a
        af.add('dealer__Vehicle__r.Conversion_Cost__c'); // BLL19a
        //af.add('dealer__Vehicle__r.HomeLocation__c');     // BLL76a
        //af.add('dealer__Vehicle__r.HomeLocation__r.Name');        // BLL76a
        af.add('FairMarketValue__c'); // BLL20a
        af.add('DeliveryAtStore__c');   // BLL26a
        af.add('RecordTypeId'); // BLL52a
        af.add('dealer__Service_Vehicle__r.dealer__Make__c');       // BLL59a
        af.add('dealer__Service_Vehicle__r.dealer__Carline__c');    // BLL59a
        af.add('dealer__Service_Vehicle__r.dealer__Trim_Level__c'); // BLL59a
        af.add('dealer__Service_Vehicle__r.dealer__Year__c');       // BLL59a
        af.add('dealer__Service_Vehicle__r.dealer__Ext_Color__c');  // BLL59a
        af.add('dealer__Service_Vehicle__r.dealer__Body_Type__c');  // BLL59a
        af.add('dealer__Service_Vehicle__r.dealer__VIN__c');        // BLL59a
        af.add('Market_Segment__c');    // BLL75a
		// BLL90
		af.add( 'dealer__Salesperson_1__r.Name' );	
		af.add( 'dealer__Salesperson_1__r.FirstName' );	
		af.add( 'dealer__Salesperson_1__r.LastName' );	
		//af.add( 'dealer__Salesperson_1__r.Email' );	
		// BLL90 end
        af.addAll(fieldnames);
        if(!Test.isRunningTest()) controller.addFields(af);
		BLL90 end */
		// BLL90
		Set<String> af = DealProcess.DealFieldsToRetrieve();
		if(!Test.isRunningTest()) controller.addFields(new List<String>(af));
		// BLL90

        // Set Location
        // 
        //BLL38d User u = [Select Id, Division from User where Id=:UserInfo.getUserId() limit 1];
        User u = CurrentUserSingleton.getInstance();    // BLL38a
        // BLL64d - use new routine to get all fields from the location object
        //dealer__Dealer_Location__c[] loc = [SELECT Id, Name, County__c , dealer__Company_Number__c, PackLocal__c, dealer__General_Manager__c, Sales_Admin__c, dealer__Service_Director__c, Tax_Equipment__c, dealer__Address__c, dealer__Street__c, dealer__City__c, Use_Appraisal_Dashboard__c,
        //  Commercial_Sales_Admin__c, F_I_Manager__c, // BLL52a
        //  Customer_Pay_Labor_Rate__c, Internal_Labor_Rate__c, dealer__Main_Phone__c, dealer__State__c, dealer__Postal_Code__c , DealerNumber__c, Proposal_Labor_Rate__c, Proposal_Labor_Cost__c,
        //  DftChassisFees__c, Doc_Fee__c, Electronic_Filing_Fee__c, Smog_Certification_Fee__c, Smog_Fee__c, Tag_Fee__c, Title_Fee__c,  // BLL52a
        //  NoLogoOnForms__c,   // BLL62a
        //  MainFax__c, Tax_Id__c, Dealer_License_Name__c, Kit_Cost_Structure__c  // BLL21a, BLL25c kitcoststructure 
        //      FROM dealer__Dealer_Location__c 
        //      where dealer__Company_Number__c =:u.Division limit 1]; // JVK4 add Proposal_Labor_Cost__c to SOQL
        //if(loc.size()!=1) {
        //  ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must be logged into to a Location before working within a proposal.  Please select a Dealership Location as your Default.'));
        //} else {
        //   location = loc[0];
        //}   
        // BLL64a
        location = getDealerLocation('dealer__Company_Number__c=\'' + u.Division + '\' ');
        if (location==null) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must be logged into to a Location before working within a proposal.  Please select a Dealership Location as your Default.'));
        
        deal=(dealer__Deal__c)controller.getRecord();

        autoSaveDeal = false;

		// BLL96a
		if (location!=null && deal.dealer__Store_Location__c!=null && deal.dealer__Store_Location__c != location.Id) {
            location = getDealerLocation('Id=\'' + deal.dealer__Store_Location__c + '\' ');
        }
		// BLL96a end

        // BLL52a - Get Sales Up 
        if(deal.dealer__Sales_Lead__c==null && ApexPages.currentPage().getParameters().get('s')!='' && ApexPages.currentPage().getParameters().get('s')!=null) {
            deal.dealer__Sales_Lead__c = ApexPages.currentPage().getParameters().get('s');
            //System.debug(ApexPages.currentPage().getParameters());
        }
        if (deal.dealer__Sales_Lead__c!=null) sup = [
            select Id, Company__c, dealer__Company_Number__c, RecordType.Name, Solution_Type__c, dtmob__Solution_Type__c,
            	dealer__Customer_Account__c, 
                dealer__First_Store_Visit_Date__c, dealer__Lead_Status__c, dealer__Email__c
            from dealer__Sales_Up__c 
            where Id=:deal.dealer__Sales_Lead__c 
            limit 1
        ];
        // BLL84a add dealer__Customer_Account__c
        System.debug(sup);
        if (sup!=null) System.debug(sup.RecordType.Name);
        if (sup!=null) System.debug(sup.Solution_Type__c);
        if (sup!=null && deal.dealer__Buyer__c==null && sup.dealer__Customer_Account__c!=null) deal.dealer__Buyer__c = sup.dealer__Customer_Account__c;	// BLL84a
        
        // Set deal type from solution opp
        if (deal.dealer__Deal_Type__c==null && sup!=null) deal.dealer__Deal_Type__c = dealTypeMap.get(sup.Solution_Type__c);
		if (deal.dealer__Deal_Type__c==null && sup!=null) deal.dealer__Deal_Type__c = sup.Solution_Type__c;	// BLL104
        System.debug(deal.dealer__Deal_Type__c);
        RecordType rtinfo = null;
        Map<Id,RecordType> DealRcdTypeIdMap = new Map<Id,RecordType>([
            select Name, Id, DeveloperName, SobjectType 
            from RecordType 
            where SobjectType='dealer__Deal__c' 
        ]);
        Map<String,RecordType> DealRcdTypeMap = new Map<String,RecordType>();
        for(RecordType r : DealRcdTypeIdMap.values()) DealRcdTypeMap.put(r.Name,r);
        if (ApexPages.currentPage().getParameters().containsKey('RecordType') && ApexPages.currentPage().getParameters().get('RecordType')!=null)
            deal.RecordTypeId=ApexPages.currentPage().getParameters().get('RecordType');
        // Get record type from solution opportunity if this is a new proposal
        // BLL52a end
        
        
        // Check Record Type (Custom Button)
        if(deal.Id==null && deal.RecordTypeId==null) {

            String rtype = null;
            if (sup!=null) rtype = sup.RecordType.Name; // BLL52a
            //BLL52d (rType is the solution type, not record type) if(ApexPages.currentPage().getParameters().get('rType')!=null) { rtype=ApexPages.currentPage().getParameters().get('rType'); }
            if(ApexPages.currentPage().getParameters().get('RecordType')!=null) { rtype=ApexPages.currentPage().getParameters().get('RecordType'); }
            if(rtype!=null) {
                // BLL52a
                System.debug(rtype);
                Id dealRt = null;
                if (rtype=='Commercial') rtinfo = DealRcdTypeMap.get('Commercial');
                else rtinfo = DealRcdTypeMap.get('Retail');
                // BLL52a end
                //BLL52d for(RecordType r : recordTypes) {
                //BLL52d     
                //BLL52d     if(rtype==r.DeveloperName || rtype==String.valueOf(r.Id)) {
                //BLL52d         deal.RecordTypeId=r.Id;
                //BLL52d         recordTypeName = r.DeveloperName;
                //BLL52d         recordTypeLabel= r.Name;
                //BLL52d         deal.dealer__Deal_Type__c=r.Name;
                //BLL52d     }
                //BLL52d 
                //BLL52d }
            }
        //BLL52d } else {
            //BLL52d for(RecordType r : recordTypes) {
            //BLL52d     if(deal.RecordTypeId==r.Id) {
            //BLL52d         recordTypeName=r.DeveloperName;
            //BLL52d         recordTypeLabel=r.Name;
            //BLL52d         deal.dealer__Deal_Type__c=r.Name;
            //BLL52d     }
            //BLL52d }
        }
        
        // BLL52a
        System.debug(rtinfo);
        if (rtinfo==null && deal.RecordTypeId!=null) rtinfo = DealRcdTypeIdMap.get(deal.RecordTypeId);
        if (rtinfo!=null && deal.RecordTypeId==null) deal.RecordTypeId = rtinfo.Id;
        recordTypeName = rtinfo!=null ? rtinfo.DeveloperName : '';
        recordTypeLabel = rtinfo!=null ? rtinfo.Name : '';
        showRebates=true;
        if (deal.dealer__Deal_Type__c=='Wholesale') showRebates = false;
        //showRebates = recordTypeName!='Commercial' || releasingDealer;
        //if (deal.dealer__Rebate__c!=null && deal.dealer__Rebate__c!=0) showRebates = true;
        //if (deal.Rebate_2__c!=null && deal.Rebate_2__c!=0) showRebates = true;
        //if (deal.Rebate_3__c!=null && deal.Rebate_3__c!=0) showRebates = true;
        // Maybe turn off for commercial sale & no releasing dealer?
        defaultPDF = dftProposalPDF.get(RecordTypeName);
        if (defaultPDF==null) defaultPDF = 'Form_ProposalPreview';
        // BLL52a end   

        tabstyle = (recordTypeName=='Commercial') ? 'CommercialQuote__c' : 'dealer__Deal__c';   // BLL52a

        cParts = new List<cPartsKit>();

        // Defaults
        // BLL52a
        if (deal.Id==null && deal.dealer__Deal_Type__c=='Wholesale') deal.Vehicle_Source__c='Inventory';
        // BLL52a end
        if(deal.dealer__Salesperson_1__c==null) deal.dealer__Salesperson_1__c=UserInfo.getUserId();
        if(deal.Commission_Employee_1__c==null) deal.Commission_Employee_1__c=deal.dealer__Salesperson_1__c;

		// BLL104
		if (deal.dealer__Deal_Type__c=='Home Access' && location!=null) {
			if (location.HA_General_Manager__c!=null && deal.dealer__Desk_Manager__c==null) deal.dealer__Desk_Manager__c = location.HA_General_Manager__c;
			if (location.HA_Sales_Admin__c!=null && deal.Sales_Admin__c==null) deal.Sales_Admin__c = location.HA_Sales_Admin__c;
			if (location.HA_Service_Manager__c!=null && deal.dtmob__Service_Manager__c==null) deal.dtmob__Service_Manager__c = location.HA_Service_Manager__c;
		}
		// BLL104 end

        if(deal.dealer__Desk_Manager__c==null && location!=null && location.dealer__General_Manager__c!=null) deal.dealer__Desk_Manager__c=location.dealer__General_Manager__c;
        if(deal.dtmob__service_manager__c==null && location!=null && location.dealer__Service_Director__c!=null) deal.dtmob__service_manager__c = location.dealer__Service_Director__c; // BLL51c

        if(RecordTypeName!='Commercial' && deal.Sales_Admin__c==null && location!=null && location.Sales_Admin__c!=null) deal.Sales_Admin__c = location.Sales_Admin__c; // BLL52c
        if(RecordTypeName=='Commercial' && deal.Sales_Admin__c==null && location!=null && location.Commercial_Sales_Admin__c!=null) deal.Sales_Admin__c = location.Commercial_Sales_Admin__c;   // BLL52a
        if(deal.dealer__F_I_Manager__c==null && location!=null && location.F_I_Manager__c!=null) deal.dealer__F_I_Manager__c = location.F_I_Manager__c; // BLL52a

        // BLL52a
        oemOptionsPrice = 0;
        oem = getCommercialQuote(deal.Commercial_Quote__c); 
        if (oem!=null) {    // force chassis cost & price, conversion cost & price from quote
            deal.OEM_Chassis_Cost__c = oem.Chassis_Cost__c;
            deal.OEM_Conversion_Cost__c = (oem.Total_Options_Cost__c + oem.Freight_Cost__c) / oem.Chassis_QTY__c; 
            deal.OEM_Chassis_Price__c = oem.Chassis_Price__c;
            deal.OEM_Conversion_Price__c = (oem.Total_Options_Price__c + oem.Freight_Amount__c) / oem.Chassis_QTY__c;
            if (deal.dealer__Vehicle__c==null) {
                //if (deal.Chassis_Cost__c!=deal.OEM_Chassis_Cost__c || deal.Conversion_Cost__c!=deal.OEM_Conversion_Cost__c) {
                    deal.Chassis_Cost__c = oem.Chassis_Cost__c;
                    deal.Chassis_Price__c = oem.Chassis_Price__c;
                    deal.Conversion_Cost__c = (oem.Total_Options_Cost__c + oem.Freight_Cost__c) / oem.Chassis_QTY__c;
                    deal.Conversion_Price__c = (oem.Total_Options_Price__c + oem.Freight_Amount__c) / oem.Chassis_QTY__c;
                    deal.Conversion_Cost__c = deal.Conversion_Cost__c.setScale(2);
                    deal.Conversion_Price__c = deal.Conversion_Price__c.setScale(2);
                //}
            } 
            // Always replace description with CommercialQuote conversion/equipment descriptions until vehicle is 
            // added to the proposal. (BLL29 3/2/2017)
            //if (String.isBlank(deal.Conversion_Description__c)) {
                String oemconversion = '';
                for(CommercialQuoteLine__c cql : oem.Commercial_Quote_Lines__r) {
                    oemconversion += (String.isBlank(oemconversion) ? '' : '\n')
                        + ((cql.Quantity__c>1) ? '('+String.valueOf(cql.Quantity__c)+')' : '') + cql.Description__c;
                }
                deal.Conversion_Description__c = oemconversion;
            //}
        }
        // BLL52a end

        if(deal.dealer__Vehicle__c!=null) {
            // Set Thumbnail
            dealer__Inventory_Images__c[] img = [SELECT Id, Name, dealer__Thumbnail_URL__c, dealer__Vehicle_Inventory__c 
                                                FROM dealer__Inventory_Images__c
                                                WHERE dealer__Vehicle_Inventory__c =: deal.dealer__Vehicle__c
                                                Order by dealer__Sequence_Number__c ASC
                                                LIMIT 1];
            thumbnailURL = (img.size()==1) ? img[0].dealer__Thumbnail_URL__c : '';

        }

        // Instantiate TradeData
        tradeData=new dealer__Trade_In__c();

        // Get Buyer Information
        //BLL39d if(deal.dealer__Buyer__c!=null) {
        BuyerDetailsChanged = false; 
        System.debug(BuyerDetailsChanged);
        if(deal.dealer__Buyer__c!=null && deal.dealer__Status__c!='Won - Posted') appendBuyerDetails(deal.dealer__Buyer__c);    // BLL39a

		// BLL84a note: no longer used in lightning, getting this from the solution opportunity instead
        if(ApexPages.currentPage().getParameters().get('b')!=null) appendBuyerDetails(ApexPages.currentPage().getParameters().get('b'));

        // BLL39a 
        System.debug(BuyerDetailsChanged);
        if (BuyerDetailsChanged && deal.Id!=null) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Buyer account information has changed -- Please SAVE the proposal!'));
        // BLL39a end

        vehOptionsPrice = 0;    // BLL52a
        // Get Vehicle Infomration
        if(deal.dealer__Vehicle__c!=null) {
            setAssociatedVehicle(deal.dealer__Vehicle__c);
        }
        //vehicle = getVehicleData(); // BLL52a

        System.debug(deal.Chassis_Price__c);
        System.debug(deal.Conversion_Price__c);
        System.debug(ApexPages.currentPage().getParameters().get('v'));
        if(!String.isBlank(ApexPages.currentPage().getParameters().get('v'))) {
            // BLL6a parm passed when another vehicle is selected, reset sale cost
            if (RecordTypeName!='Commercial') { // BLL55a
                deal.dealer__Sale_Cost__c = null;
                deal.Chassis_Price__c = null;    // BLL20a
                deal.Conversion_Price__c = null; // BLL20a
            }   // BLL55a
            setAssociatedVehicle(ApexPages.currentPage().getParameters().get('v'));
        }
        System.debug(deal.Chassis_Price__c);
        System.debug(deal.Conversion_Price__c);
        vehicle = getVehicleData(); // BLL52a

        // Get Sales Up and Set if Blank
        //BLL52d if(ApexPages.currentPage().getParameters().get('s')!='' && ApexPages.currentPage().getParameters().get('s')!=null) {
        //BLL52d     deal.dealer__Sales_Lead__c = ApexPages.currentPage().getParameters().get('s');
        //BLL52d }

        // BLL2a - add block set location based on Sol Opp or (if not set) where the user is logged in
        if (deal.Id==null && deal.dealer__Store_Location__c==null && location!=null) {  // BLL42c move above next section -- make user location primary source
            deal.dealer__Store_Location__c = location.Id;
            deal.dealer__Company_Number__c = location.dealer__Company_Number__c;
        }
        if (deal.Id==null && deal.dealer__Store_Location__C==null && deal.dealer__Sales_Lead__c!=null) {
            //BLL52d dealer__Sales_Up__c sup = [select Id, Company__c, dealer__Company_Number__c from dealer__Sales_Up__c where Id=:deal.dealer__Sales_Lead__c limit 1];
            deal.dealer__Store_Location__c = sup.Company__c;
            deal.dealer__Company_Number__c = sup.dealer__Company_Number__c;
        }
        // Set location from proposal, not current user assignment!
        //BLL96d if (location!=null && deal.dealer__Store_Location__c!=null && deal.dealer__Store_Location__c != location.Id) {
            // BLL64d - use std routine to pull all location fields
            //dealer__Dealer_Location__c[] dealloc = [
            //  SELECT Id, Name, County__c ,dealer__Company_Number__c, PackLocal__c, dealer__General_Manager__c, Sales_Admin__c, dealer__Service_Director__c, Tax_Equipment__c, dealer__Address__c, dealer__Street__c, dealer__City__c, Use_Appraisal_Dashboard__c,
            //         Commercial_Sales_Admin__c, F_I_Manager__c,   // BLL52a
            //         Customer_Pay_Labor_Rate__c, Internal_Labor_Rate__c, dealer__Main_Phone__c, dealer__State__c, dealer__Postal_Code__c , DealerNumber__c,
            //         Proposal_Labor_Rate__c, Proposal_Labor_Cost__c,
            //         DftChassisFees__c, Doc_Fee__c, Electronic_Filing_Fee__c, Smog_Certification_Fee__c, Smog_Fee__c, Tag_Fee__c, Title_Fee__c,   // BLL52a
            //         NoLogoOnForms__c,    // BLL
            //         MainFax__c, Tax_Id__c, Dealer_License_Name__c, Kit_Cost_Structure__c // BLL21a, BLL30c Kit_Cost_Structure__c
            //  FROM dealer__Dealer_Location__c 
            //  WHERE Id=:deal.dealer__Store_Location__c limit 1
            //];
            //if (dealloc.size()==1) {
            //     location = dealloc[0];
            //}
            // BLL96d location = getDealerLocation('Id=\'' + deal.dealer__Store_Location__c + '\' ');
        // BLL96d }
        // BLL64a end
        // BLL2a - end block

        // Set Default Terms/rate/days
        if(deal.dealer__Term__c == null) {
            deal.dealer__Term__c = 84;
            deal.dealer__Rate__c = 5.99;
            deal.dealer__Days_to_First__c = 30;
            deal.dealer__Payments_Per_Year__c = 12;
        }

        if(deal.dealer__Deal_Date__c == null) deal.dealer__Deal_Date__c=Date.Today();

        if(deal.MultiQuote_Payment_Grid__c!=null) multiquote = new wMultiQuote(deal.MultiQuote_Payment_Grid__c);

        // BLL12a
        Decimal oldpayoff = deal.dealer__Trade_Payoff__c;
        Decimal oldallowance = deal.dealer__Trade_Allowance__c;
        Decimal oldacv = deal.Trade_ACV__c;
        // BLL12a end

        // Set the Trade Values from the related data
        List<dealer__Trade_In__c> trades = [Select Id, dealer__ACV__c, dealer__Trade_Allowance__c, dealer__Pay_Off_Amount__c
                                                From dealer__Trade_In__c 
                                                Where dealer__Car_Deal__c =: deal.Id
                                                and dealer__Car_Deal__c != null
                                                ];
		/* limit 3 */
        // BLL60a Don't recalc trade values once posted
        // Change in trade record after deal posting is changing how the deal looks on-screen
        if (deal.dealer__Status__c!='Won - Posted') {   // BLL60a
            deal.dealer__Trade_Payoff__c    =   0;
            deal.dealer__Trade_Allowance__c =   0;
            deal.Trade_ACV__c              =   0;

            for(dealer__Trade_In__c t : trades) {
                deal.dealer__Trade_Payoff__c += (t.dealer__Pay_Off_Amount__c!=null) ? t.dealer__Pay_Off_Amount__c : 0.00;   // BLL25c
                deal.dealer__Trade_Allowance__c += (t.dealer__Trade_Allowance__c!=null) ? t.dealer__Trade_Allowance__c : 0.00;  // BLL25c
                deal.Trade_ACV__c += (t.dealer__ACV__c!=null) ? t.dealer__ACV__c : 0.00;    // BLL25c
            }
            deal.dealer__Trade_Payoff__c = deal.dealer__Trade_Payoff__c.setScale(2);    // BLL65a
            deal.dealer__Trade_Allowance__c = deal.dealer__Trade_Allowance__c.setScale(2);  // BLL65a
            deal.Trade_ACV__c = deal.Trade_ACV__c.setScale(2);  // BLL65a
        }   //BLL60a

        // Commission related calculations
        if(deal.Commission_Rate__c==null) {
            deal.Commission_Rate__c = 0.25;
            deal.Commission_Rate__c = 0.00; //BLL28a - leave alone if set (old deals), otherwise it's now 0%
        }

        if(deal.Total_Price__c==null) {
            deal.Total_Price__c = 0;
        }

        if(deal.Commission_Rate__c==null) deal.Commission_Rate__c=0;

        // DR4
        if(deal.Commissionable_Gross__c == null) {
            deal.Commissionable_Gross__c=0;
        }
        // /DR4

        deal.Commission__c = deal.Commissionable_Gross__c * (deal.Commission_Rate__c / 100); // DR4

        // BLL12a - get account (for needs analysis info)
        if (deal.Id!=null && deal.dealer__Buyer__c!=null) {
            accountInfo = [
                select Id, dtffa__A__c, dtffa__B__c, dtffa__Actual_Estimate__c, dtffa__C__c, dtffa__Chair_Brand__c, dtffa__Chair_Model__c, 
                    Claim_Number__c, dtffa__Client_In_Chair_Weight__c, dtffa__End_User__c, 
                    dtffa__Physical_Challenge__c, dtffa__AnalysisDate__c, dtffa__PlannedChanges__c, NeedsAssessmentRecordedBy__c, NeedsAssessmentRecordedBy__r.Name,
                    Market_Segment__c, // BLL75a
                    RecordType.Name // BLL52a
                From Account where Id=:deal.dealer__Buyer__c limit 1];
            if (RecordTypeName=='Commercial' && deal.Market_Segment__c==null && accountInfo!=null && accountInfo.Market_Segment__c!=null) deal.Market_Segment__c = accountInfo.Market_Segment__c;   // BLL75a
        }
        // BLL12a end
        
        userConfig = RetailDefaults__c.getValues(UserInfo.getUserId());

        // BLL12a
        // BLL65a - handle rounding discrepancies so we don't get into an auto-save loop when too many decimals are keyed
        if (oldpayoff!=null) oldpayoff = oldpayoff.setScale(2);
        if (oldallowance!=null) oldallowance = oldallowance.setScale(2);
        if (oldacv!=null) oldacv = oldacv.setScale(2);
        if (deal.Id!=null && (oldpayoff!=deal.dealer__Trade_Payoff__c || oldallowance!=deal.dealer__Trade_Allowance__c || oldacv!=deal.Trade_ACV__c)) {
            if (deal.dealer__Status__c!='Won - Posted' && deal.dealer__Sales_Lead__c!=null) {   // BLLa
                autoSaveDeal = true;
            }   // BLLa
        }
        // BLL12a end

        setServiceODO(); // BLL17a
        
        //RT2       
        //viewTransactions = Schema.sObjectType.c2g__codaTransaction__c.isAccessible();

        // BLL20a
        if (deal.Id!=null) dealTaxation = AvaTax_MBW.getInstanceDeal(deal);
        if (dealTaxation!=null) {	// BLL79a
        	useFMV = dealTaxation.useFairMarketValue(); 
        	fmvURL = dealTaxation.getFairMarketValueURL();
        	showPartLaborSplit = dealTaxation.getShowPartLaborSplit();  // BLL34a
        	showChassisTaxableBox = dealTaxation.showChassisTaxableSelection();
        	TaxCertificateRequired = dealTaxation.getTaxDocumentRequired();	// BLL81a
        } 	// BLL79a 
        //BLL20a end

        ConversionDetailSource = 'Description';
        if (oem!=null && oem.Commercial_Quote_Lines__r.size()>0) ConversionDetailSource = 'Build';
        if (vehicle!=null && vehicle.Vehicle_Commercial_Options__r.size()>0) ConversionDetailSource = 'Vehicle';
        vehHasCommercialOptions = false;
        if (vehicle!=null && vehicle.Vehicle_Commercial_Options__r.size()>0) vehHasCommercialOptions = true;
        

        if (ApexPages.hasMessages()) autoSaveDeal = false;  // BLL52a - do not get into a save/cannot_save loop!
        // BLL52a - warnings
        if (deal.dealer__Status__c!='Won - Posted') issueWarningMsgs();
        // BLL52a end

        // BLL65a
        if (deal.Contract_Type__c=='Lease') initLease();    
        MobilityForceSettings__c mfs = MobilityForceSettings__c.getOrgDefaults();
        ShowTradeRecordLink = (mfs!=null && mfs.ShowTradeRecordLink__c==true);
        // BLL65a end

        // BLL84a - special lease "error" messages (don't prevent saving, but always issue message)
        // these are enforced in DealProcess.class when deal is pushed to delivered
        ApexPages.Severity financeseverity = (deal.dealer__Status__c=='Won - Delivery' || deal.dealer__Status__c=='Won - Delivered') ? ApexPages.Severity.ERROR : ApexPages.Severity.WARNING;
        if (deal.Funding_option__c=='Financed' && (deal.Contract_Amount_Financed__c==0 || deal.Contract_Amount_Financed__c==null)) {
			ApexPages.addMessage(new ApexPages.Message(financeseverity, 'Funding option is "Financed" but amount financed is $0'));
        }
        if (deal.Funding_option__c=='Financed' && deal.Contract_Type__c=='Lease' && (deal.Contract_Monthly_Payment__c==null || deal.Contract_Monthly_Payment__c==0)) {
			ApexPages.addMessage(new ApexPages.Message(financeseverity, 'Proposal is Financed under a lease, but the contract monthly payment is $0'));
        }
        System.debug(deal.dealer__Deposit__c);
        System.debug(deal.TotalDueUponDelivery__c);
        if (deal.Funding_option__c=='Financed' && deal.Contract_Type__c=='Lease'
        	&& (deal.dealer__Deposit__c==0 || deal.dealer__Deposit__c==null)
        	&& (deal.TotalDueUponDelivery__c<=0)) {
			ApexPages.addMessage(new ApexPages.Message(financeseverity, 'Lease first payment (deposit) is $0, but amount due is $0 or less (adj cap cost is too high)'));
        }
        // BLL84a end
        
    }

    // BLL65a
    public void initLease() {
        lease = new LeaseCalculator(deal);
    }
    public boolean validateLeaseData() {
        System.debug('validateLeaseData');
        boolean okay = true;
        if (deal.ChassisResidualPct__c!=null && deal.ChassisMSRP__c!=null) {
            deal.ChassisResidualAmt__c = deal.ChassisResidualPct__c/100 * deal.ChassisMSRP__c;
            deal.ChassisResidualAmt__c = deal.ChassisResidualAmt__c.setScale(2);
        } else {
            ApexPages.Message err1 = new ApexPages.Message(ApexPages.Severity.ERROR,
                'Chassis MSRP & Residual% are required before calculating lease pmt');
            ApexPages.addMessage(err1);
            okay = false;
        }        
        if (deal.ConversionResidualPct__c!=null && deal.ConversionMSRP__c!=null) {
            deal.ConversionResidualAmt__c = deal.ConversionResidualPct__c/100 * deal.ConversionMSRP__c;
            deal.ConversionResidualAmt__c = deal.ConversionResidualAmt__c.setScale(2);
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                'Conversion MSRP & Residual% are required before calculating lease pmt'));
            okay = false;
        }        
    
        if (deal.LeaseMoneyFactor__c==null || deal.LeaseMoneyFactor__c==0) {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
            //    'Lease Money Factor is required before calculating the lease pmt'));
            deal.LeaseMoneyFactor__c.addError('Lease Money Factor is required before calculating the lease pmt');
            okay = false;
        }
        if (deal.Contract_Number_of_Payments__c==null || deal.Contract_Number_of_Payments__c==0) {
            //ApexPages.Message err4 = new ApexPages.Message(ApexPages.Severity.ERROR,
            //    'Lease term (number of months/payments) is required before calculating the lease pmt');
            deal.Contract_Number_of_Payments__c.addError('Lease term (number of months/payments) is required before calculating the lease pmt');
            //ApexPages.addMessage(err4);
            okay = false;
        }
        return okay;
    }
    public void FinancialInstitutionDefaults() {
        System.debug('FinancialInstitutionDefaults');
		// BLL100
        //if (deal.dealer__Finance_Institution_Account__c!=null 
        //    && (deal.LeaseMoneyFactor__c==null || deal.LeaseAcquisitionFee__c==null || deal.LoanAcquisitionCost__c==null)) {
        if (deal.dealer__Finance_Institution_Account__c!=null 
            && (deal.LeaseMoneyFactor__c==null || deal.LeaseAcquisitionFee__c==null || (deal.LoanAcquisitionCost__c==null && deal.ESC_Loan_Cost__c==null) )) {
		// BLL100 end
            // BLL68c changed selection fields, // BLL94a - add AcquisitionCost__c
            List<dealer__Finance_Company__c> fias = [
                select Name, AcquisitionFee__c, dealer__New_Vehicle_Rate__c, dealer__Used_Vehicle_Rate__c, LeaseMoneyFactor__c, ChargesAcquisitionFee__c,
					AcquisitionCost__c	
                from dealer__Finance_Company__c
                where Id=:deal.dealer__Finance_Institution_Account__c
            ];
            fia = fias.size()>0 ? fias[0] : null;   // BLL68c
            if (deal.Contract_Type__c=='Lease' && fia!=null && deal.LeaseMoneyFactor__c==null && vehicle!=null) deal.LeaseMoneyFactor__c=fia.LeaseMoneyFactor__c;
            // BLL94
			//if (deal.Contract_Type__c=='Lease' && fia!=null && deal.LeaseAcquisitionFee__c==null) {
            if ((deal.Contract_Type__c=='Loan' || deal.Contract_Type__c=='Lease')
				&& fia!=null && deal.LeaseAcquisitionFee__c==null) {
			// BLL94 end
                    deal.LeaseAcquisitionFee__c=fia.AcquisitionFee__c;
                    if (deal.dealer__Total_Fees__c==null) deal.dealer__Total_Fees__c=0;
                    if (fia.AcquisitionFee__c!=null) deal.dealer__Total_Fees__c += fia.AcquisitionFee__c;
            }
            // BLL94
			//if (deal.Contract_Type__c=='Loan' && fia!=null && deal.LoanAcquisitionCost__c==null) deal.LoanAcquisitionCost__c=fia.AcquisitionFee__c;
			if (deal.Contract_Type__c=='Loan' && fia!=null && deal.LoanAcquisitionCost__c==null) deal.LoanAcquisitionCost__c=fia.AcquisitionCost__c;
			// BLL94 end
        }
        if (deal.Contract_Type__c=='Lease') deal.LoanAcquisitionCost__c = null;
		// BLL100
		if (deal.Contract_Type__c=='Lease') deal.ESC_Loan_Cost__c = null;
		// BLL100 end
        // BLL87
		//if (deal.Contract_Type__c=='Lease' && deal.LeaseAcquisitionFee__c==null) deal.LeaseAcquisitionFee__c = 0;
		if (deal.Contract_Type__c!=null && deal.LeaseAcquisitionFee__c==null) deal.LeaseAcquisitionFee__c = 0;
		// BLL87 end
        if (deal.Contract_Type__c=='Loan') {
            // BLL87d deal.LeaseAcquisitionFee__c = null;
            deal.LeaseMilesIncluded__c = null;
            deal.LeaseMonthlySalesTax__c = null;
            deal.LeaseMilesOverageRate__c = null;
            deal.ChassisResidualAmt__c = null;
            deal.ConversionResidualAmt__c = null;
            deal.Contract_ResidualValue__c = null;	// BLL84d ??
            deal.dealer__Residual_Amt__c = null;	// BLL84a
        }
        // BLL72a check for no-price GAP & assume it's paid by the finance institution
        Decimal ReimbursedESC = 0.00;
        for(dealer__Service_Contract__c gap : soldonproposalGAP) {
            if (gap.dealer__Sale_Price__c==0) ReimbursedESC += gap.dealer__Cost__c;
            System.debug(gap);
        }
        System.debug(ReimbursedESC);
        // Always calculate for now.  if (ReimbursedESC>0) //not yet && deal.FinanceInstitutionReimbursement__c==null)
            deal.FinanceCompanyReimbursement__c = ReimbursedESC;
        // BLL72a end
		// BLL100
		if (deal.dealer__Deal_Type__c=='Financial Products' && deal.LoanAcquisitionCost__c!=null && deal.LoanAcquisitionCost__c!=0) {
			deal.ESC_Loan_Cost__c = deal.LoanAcquisitionCost__c;
			deal.LoanAcquisitionCost__c = null;
		}
		if (deal.dealer__Deal_Type__c!='Financial Products' && deal.ESC_Loan_Cost__c!=null && deal.ESC_Loan_Cost__c!=0) {
			deal.LoanAcquisitionCost__c = deal.ESC_Loan_Cost__c;
			deal.ESC_Loan_Cost__c = null;
		}
		// BLL100 end
	}


    public void calculateLeasePmt() {
        System.debug('calculateLeasePmt');
        FinancialInstitutionDefaults();
        if (validateLeaseData()) {
            lease = new LeaseCalculator(deal);
            lease.calculate();
            lease.debugLog();
            saveLeaseResults();
        }
    }
    
    public void saveLeaseResults() {
        if (deal.dealer__Down_Pymt__c != lease.DownPayment)
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.Severity.INFO, 
                    'Adjusted Down Payment from ' + String.valueOf(deal.dealer__Down_Pymt__c) + ' to ' + String.valueOf(lease.DownPayment)
                )
            );
        
        deal.dealer__Down_Pymt__c = lease.DownPayment;
		if (deal.ChassisResidualAmt__c==null) deal.ChassisResidualAmt__c=0.00;	// BLL84a
		if (deal.ConversionResidualAmt__c==null) deal.ConversionResidualAmt__c=0.00;	// BLL84a
        deal.Contract_ResidualValue__c = deal.ChassisResidualAmt__c + deal.ConversionResidualAmt__c;	// BLL84d??
        deal.dealer__Residual_Amt__c = deal.ChassisResidualAmt__c + deal.ConversionResidualAmt__c;	// BLL84a
        deal.Contract_Monthly_Payment__c = lease.MonthlyPayment;
        deal.Contract_Final_Payment__c = lease.MonthlyPayment;
        deal.Contract_Finance_Charge__c = lease.TotalRentCharge;
        deal.Contract_Total_of_Payments__c = lease.TotalOfPayments + lease.DispositionFee;
            // lease.Disposition == deal.LeaseDispositionFee__c
        deal.LeaseMonthlySalesTax__c = lease.MonthlySalesTax;
        deal.LeaseUpfrontSalesTax__c = lease.UpfrontSalesTax;
        if (lease.SalesTaxMethod=='Up-front') {
            // do nothing -- the Avalara amount is used (or manual override)
            //BLL67a not sure if needed: deal.SalesTaxOverrideAmt__c = null;    // BLL67a
        }
        if (lease.SalesTaxMethod=='Monthly Up-front') {
            deal.SalesTaxOverrideAmt__c = lease.UpfrontSalesTax;
            deal.SalesTaxOverrideReason__c = 'Lease with up-front sales tax (' + String.valueOf(lease.SalesTaxPct) + '% * ' + String.valueOf(lease.TotalOfPaymentsBeforeTax) + ')';
            deal.SalesTaxOverrideBasis__c = lease.TotalOfPayments + lease.DownPayment + lease.Deposit + lease.OutsideFunding;
        }
        if (lease.SalesTaxMethod=='Monthly') {
            deal.SalesTaxOverrideAmt__c = 0;
            deal.SalesTaxOverrideReason__c = 'Sales tax on monthly payment';
            deal.SalesTaxOverrideBasis__c = lease.MonthlyPmtBeforeTax;
        }
        deal.LeasePmtBeforeTax__c = lease.MonthlyPmtBeforeTax;
        deal.Contract_Amount_Financed__c = lease.AdjustedCapCost;
        deal.TotalUpfrontCash__c = lease.TotalUpfrontCash;
    }

    public void LeaseDesiredUpfrontCash() {
        if (deal.DesiredUpfrontCash__c==null || deal.DesiredUpfrontCash__c<0) {
            ApexPages.Message err = new ApexPages.Message(ApexPages.Severity.ERROR, 
                'You must supply the desired up-front cash amount');
            ApexPages.addMessage(err);
            //deal.DesiredUpfrontCash.addMessage(err); not an SObject field (yet at least)
            return;
        }
    
        if (validateLeaseData()) {
            try {
                lease = new LeaseCalculator(deal);
                lease.setTotalUpFrontCash(deal.DesiredUpfrontCash__c);
                if (lease.DownPayment<0) {
                    String msg = 'Cannot achieve desired up-front cash ';
                    if (deal.dealer__Deposit__c>0) msg += 'when Deposit is ' + String.valueOf(deal.dealer__Deposit__c); 
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg));
                    lease.DownPayment = 0;
                    lease.calculate();
                }
                saveLeaseResults();
                lease.debugLog();
            } catch(Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()));
            }
        }
    }
    // BLL65a end

    // BLL64a - keep in sync with FormControlVehicleInventory
    public dealer__Dealer_Location__c getDealerLocation(String wherecondition) {
        DescribeSObjectResult descDL = dealer__Dealer_Location__c.getSObjectType().getDescribe();
        Set<String> locFields = new Set<String>(descDL.fields.getMap().keySet());
        System.debug(locFields);
        
        // Add selected user fields for each user reference
        List<String> userfields = new List<String>{'Name','FirstName','LastName','Email','Phone'};
        List<String> userrefs = new List<String>{'dealer__General_Manager__r','Sales_Admin__r','dealer__Service_Director__r',
            'F_I_Manager__r','Rental_Manager__r','Commercial_Sales_Admin__r'};
        List<String> userreffields = new List<String>();
        for(String ur : userrefs) {
            for(String uf : userfields) {
                userreffields.add(ur+'.'+uf);
            }
        }
        System.debug(userreffields);
        locFields.addAll(userreffields);
                
        String soql = 'select ' + String.join(new List<String>(locFields), ',')
                + ' from dealer__Dealer_Location__c '
                + ' where ' + wherecondition 
                + ' limit 1 ';
        //System.debug(soql);
        List<dealer__Dealer_Location__c> locs = Database.query(soql);
        return (locs.size()>0) ? locs[0] : null;
    }
    // BLL64a end

    // BLL52a
    public void issueWarningMsgs() {
        //if (deal.dealer__Vehicle__c!=null && deal.Vehicle_Status__c!='Ready for Sale') 
        //  ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Vehicle is NOT Ready for Sale'));
        if (deal.dealer__Vehicle__c!=null && deal.Vehicle_Status__c!='Ready for Sale' && deal.Vehicle_Status__c!='Sold - Not Delivered') 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Vehicle is NOT Ready for Sale'));
        if (deal.dealer__Vehicle__c!=null && deal.Vehicle_Status__c=='Sold - Not Delivered' && deal.dealer__Status__c!=null && !deal.dealer__Status__c.startsWith('Won'))
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Vehicle is NOT Ready for Sale'));
        if (deal.Open_Service_Repair_Orders__c!=null && deal.Open_Service_Repair_Orders__c!=0)
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Open Work in Process - Chassis Cost might be understated'));
        if (accountInfo!=null && accountInfo.RecordType.Name=='Commercial' && RecordTypeName!='Commercial')
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, RecordTypeLabel + ' sale to a Commercial customer'));
        if (accountInfo!=null && accountInfo.RecordType.Name!='Commercial' && RecordTypeName=='Commercial')
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, RecordTypeLabel + ' sale to a Retail customer'));
        // BLL63a
        if (vehicle!=null && vehicle.Qualifies_for_MobilityGuard_Pwrtrain__c==true && hasMobilityGuardPowertrain==false)
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, vehicle.Name + ' qualifies for the MobilityGuard Powertrain ESC!'));
        // BLL63a end
    }
    
    public PageReference gotoClonePage() {
        clonePage.getParameters().put('id',deal.Id);
        return clonePage;
    }
    
    // BLL84a
    public PageReference gotoFormsPage() {

        // AMM86
    	//PageReference fp = formManagerPage;
    	//fp.getParameters().put('id',deal.id);

        // 1. get the custom setting 
        MobilityForceSettings__c printMergePageBoolean = MobilityForceSettings__c.getInstance();
        
        System.debug(printMergePageBoolean);

        PageReference fp = null;

        if (printMergePageBoolean == null || printMergePageBoolean.DealMBW2Printing__c) 
        {
            fp = formManagerPagePrintMerge;
        }
        else 
        {
            fp = formManagerPage;
        }

        fp.getParameters().put('id',deal.id);

        // AMM86
    	return fp;
    }
    // BLL84a end

    // BLL63 total for each protection product type
    public Decimal getESCAmountByType(String type) {
        AggregateResult[] sumESC = [
            select SUM(dealer__Sale_Price__c) amsum 
            from dealer__Service_Contract__c 
            where dealer__Car_Deal__c = :deal.Id and Type__c=:type
        ];
        Decimal val = (sumESC.size()>0) ? (Decimal) sumESC[0].get('amsum') : 0;
        if (val==null) val = 0;
        return val.setScale(2);
    }
    public Decimal getGapAmount() {
        return getESCAmountByType('GAP');
    }
    public Decimal getServiceContractAmount() {
        return getESCAmountByType('Service Contract');
    }
    public Decimal getRoadsideAmount() {
        return getESCAmountByType('Roadside Protection');
    }
    public dealer__Service_Contract__c getESCPolicy(String type) {
        List<dealer__Service_Contract__c> esc = [
            select Id, Name, dealer__Sale_Price__c, dealer__Expiration_Months__c, dealer__Expiration_Mileage__c, 
                dealer__Description__c, Vendor_Name__c, Vendor_Name__r.Name 
            from dealer__Service_Contract__c 
            where dealer__Car_Deal__c = :deal.Id and Type__c=:type
        ];
        if (esc.size()>0) return esc[0];
        else return new dealer__Service_Contract__c(); // all null values?
    }
    public dealer__Service_Contract__c getGapPolicy() {
        return getESCPolicy('GAP');
    }
    public dealer__Service_Contract__c getServiceContractPolicy() {
        return getESCPolicy('Service Contract');
    }
    public dealer__Service_Contract__c getRoadsidePolicy() {
        return getESCPolicy('Roadside Protection');
    }
    // BLL63a end
    
    public CommercialQuote__c getCommercialQuote(Id cqid) {
        CommercialQuote__c cq = null;
        try {
        	// BLL63a add selection of related proposals NOT lost
            List<CommercialQuote__c> cqlist = [
                select Id, Name, Chassis__c, Chassis_MFG__c, Chassis_Platform__c, Chassis_Platform_Wheelbase__c, Chassis_Description__c, Chassis_Qty__c,
                     Chassis_Cost__c, Chassis_Price__c, Total_Options_Cost__c, Total_Options_Price__c, Freight_Cost__c, Freight_Amount__c, Status__c,
                     VIN__c, UnitNumber__c, VehicleInventory__c, Proposal__c, // BLL63a
                    ( select Id, Name, Quantity__c, Commercial_Quote_Options__c, Description__c, RecordTypeName__c, Extended_Total__c 
                      from Commercial_Quote_Lines__r
                      order by SectionSequence__c
                    ),
                    ( select Id, Name, dealer__Status__c    
                      from Proposals__r
                      where dealer__Status__c!='Lost'
                    )
                from CommercialQuote__c
                where Id=:cqid
            ];
            if (cqlist.size()>0) cq = cqlist[0];
            if (cq!=null && cq.Chassis_QTY__c==null) cq.Chassis_QTY__c = 1;
            if (cq!=null && cq.Chassis_Cost__c==null) cq.Chassis_Cost__c = 0;
            if (cq!=null && cq.Chassis_Price__c==null) cq.Chassis_Price__c = 0;
            if (cq!=null && cq.Freight_Cost__c==null) cq.Freight_Cost__c=0;
            if (cq!=null && cq.Freight_Amount__c==null) cq.Freight_Amount__c=0;
            // adjust line qty to appear as "per unit/per chassis"
            oemOptionsPrice = 0;
            if (cq!=null) {
                for(CommercialQuoteLine__c l : cq.Commercial_Quote_Lines__r) {
                    l.Quantity__c = (Math.mod(Integer.valueOf(l.Quantity__c), Integer.valueOf(cq.Chassis_Qty__c))==0)
                                  ? l.Quantity__c/cq.Chassis_Qty__c  :  l.Quantity__c;
                    oemOptionsPrice += l.Extended_Total__c;
                }
            }
        } catch(Exception e) {}
        return cq;
    }

    public PageReference emailPDF() {
        emailTo = 'Customer';
        toAddress = deal.dealer__Buyer_Email__c;
        emailPageName = dftProposalPDF.get(RecordTypeName);
        if (String.isBlank(emailPageName)) emailPageName = 'Form_ProposalPreview';  
        return emailPage;
    }

    public PageReference emailReleasingDealer() {
        emailTo = 'Releasing Dealer';
        Account rd = null;
        List<Account> rdlist = [select dealer__Billing_Email__c from Account where Id=:deal.ReleasingDealer__c];
        if (rdlist.size()>0) rd = rdlist[0];
        toAddress = rd!=null ? rd.dealer__Billing_Email__c : UserInfo.getUserEmail();
        emailPageName = dftReleasingDealerPDF.get(RecordTypeName);
        if (String.isBlank(emailPageName)) emailPageName = 'Form_ProposalPreview';  
        return emailPage;
    }

    // removeVehicle
    //----------------------------
    public void removeVehicle() {
        // BLL93
		//deal.dealer__Vehicle__c = null;
		removeVehicleBeforeSave();
		// BLL93
        saveProposal();
    }
	// BLL93
	public void removeVehicleBeforeSave() {
		deal.dealer__Vehicle__c = null;
		deal.Chassis_Cost__c = 0.00;
		deal.Conversion_Cost__c = 0.00;
		deal.Conversion_Description__c = null;
		deal.dealer__VIN__c = null;
		deal.dealer__Year__c = null;
		deal.dealer__Make__c = null;
		deal.dealer__Model__c = null;
		deal.dealer__Exterior_Color__c = null;
	}
	// BLL93 end
    
    // removeCommercialQuote
    //----------------------------
    public void removeCommercialQuote() {
        deal.Commercial_Quote__c = null;
    }

    // createCommercialQuote
    //----------------------------
    public PageReference createCommercialQuote() { 
        if(saveProposal()==null) return null;   // first save any changes, redisplay if there were errors
        commercialQuote.getParameters().put('proposalId', deal.Id);
        commercialQuote.getParameters().put('solutionOppId', deal.dealer__Sales_Lead__c);
        commercialQuote.setRedirect(true);
        return commercialQuote;
    }

    // chgDealType
    //----------------------------
    public void chgDealType() {
		// BLL104
		System.debug('chgDealType');
		System.debug(deal.dealer__Deal_Type__c);
		//location = getDealerLocation('Id=\'' + deal.dealer__Store_Location__c + '\' ');
		System.debug(location);
		if (deal.dealer__Deal_Type__c=='Home Access' && location!=null) {
			if (location.HA_General_Manager__c!=null) deal.dealer__Desk_Manager__c = location.HA_General_Manager__c;
			if (location.HA_Sales_Admin__c!=null) deal.Sales_Admin__c = location.HA_Sales_Admin__c;
			if (location.HA_Service_Manager__c!=null) deal.dtmob__Service_Manager__c = location.HA_Service_Manager__c;
			System.debug('Changed to HA managers');
		} else {
	        if(location!=null && location.dealer__General_Manager__c!=null) deal.dealer__Desk_Manager__c=location.dealer__General_Manager__c;
	        if(location!=null && location.dealer__Service_Director__c!=null) deal.dtmob__service_manager__c = location.dealer__Service_Director__c; // BLL51c
	        if(RecordTypeName!='Commercial' && location!=null && location.Sales_Admin__c!=null) deal.Sales_Admin__c = location.Sales_Admin__c; // BLL52c
	        if(RecordTypeName=='Commercial' && location!=null && location.Commercial_Sales_Admin__c!=null) deal.Sales_Admin__c = location.Commercial_Sales_Admin__c;   // BLL52a
			System.debug('Changed to non-HA managers');
		}
        if(deal.dealer__F_I_Manager__c==null && location!=null && location.F_I_Manager__c!=null) deal.dealer__F_I_Manager__c = location.F_I_Manager__c; // BLL52a
		// BLL104 end

        if (deal.dealer__Deal_Type__c=='Wholesale') deal.Vehicle_Source__c='Inventory';
        if (deal.dealer__Deal_Type__c=='Equipment Only') deal.Vehicle_Source__c='Customer Owned';
        if (deal.dealer__Vehicle__c!=null && deal.dealer__Deal_Type__c=='Wholesale' && vehicle!=null && vehicle.New_Used_Other__c!='Wholesale') {
			// BLL93
            //deal.dealer__Vehicle__c = null;
			removeVehicleBeforeSave();
			// BLL93 end
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Non-wholesale vehicle was removed from the proposal, please save proposal.'));
        }
        if (deal.dealer__Vehicle__c!=null && deal.dealer__Deal_Type__c!='Wholesale' && vehicle!=null && vehicle.New_Used_Other__c=='Wholesale') {
			// BLL93
            //deal.dealer__Vehicle__c = null;
			removeVehicleBeforeSave();
			// BLL93 end
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Wholesale vehicle was removed from the proposal, please save proposal.'));
        }
    }
    // BLL52a end

    // BLL13a 
    // getTaxes
    //-----------------------------
    public list<DealTaxes__c> getTaxes() {
        if (Taxes==null && deal.Id!=null) {
            Taxes = [
                select Id, Name, TaxType__c, JurisType__c, JurisName__c, Taxable__c, TaxRate__c, Tax__c
                from DealTaxes__c
                where Deal__c=:deal.Id
            ];
        }
        return Taxes;
    }
    // pageCalcTax
    //-----------------------------
    public void pageCalcTax() {
        if (deal.dealer__Status__c!='Won - Delivered' && deal.dealer__Status__c!='Won - Posted') {
            try {
                calcTax();
                dealTaxation.saveDealTaxDetail();
                dealTaxation.saveDealTaxHeader(); // BLL14a
            } catch(Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Taxes are not recalculated after delivery.'));
        }
    }
    // calcTax
    //-----------------------------
    public void calcTax() {
        System.debug('calcTax');
        //dealTaxation = AvaTax_MBW.getInstanceDealId(deal.Id);
        if (deal.Id!=null) dealTaxation = AvaTax_MBW.getInstanceDeal(deal);	// BLL79c
        if (dealTaxation!=null) {	// BLL79a
        	useFMV = dealTaxation.useFairMarketValue(); // BLL20a
        	fmvURL = dealTaxation.getFairMarketValueURL(); // BLL20a
        	showChassisTaxableBox = dealTaxation.showChassisTaxableSelection(); 
        	TaxCertificateRequired = dealTaxation.getTaxDocumentRequired();	// BLL81a
        	String hash = dealTaxation.getHash();
        	//if (deal.DoNotCollectTax__c!=true) { // BLL20a
            dealTaxation.calculateTax();
        	// BLL20a
        	//} else {
        	//  try {
        	//      dealTaxation.cancelTax('Unspecified');
        	//  } catch(Exception e) {}
        	//} 
        	// BLL20a end
        	System.debug(dealTaxation.County);  // BLL31a
        
        	// BLL52d if (recordTypeName!=null && !recordTypeName.startsWith('Equipment') && String.isBlank(deal.dealer__Buyer_County__c) && !String.isBlank(dealTaxation.County)) deal.dealer__Buyer_County__c=dealTaxation.County;    // BLL31a
        	// Save county from results if it's a vehicle deal -- BLL52a 
        	//if (deal.dealer__Deal_Type__c!=null && (deal.dealer__Deal_Type__c.contains('Vehicle') || deal.dealer__Deal_Type__c.contains('Chassis') || deal.dealer__Deal_Type__c.contains('Wholesale')))
        	// BLL96 - only replace buyer county if it's blank - issue is buyer's county is not taxed, but store's county is
			// this will update the buyer's county incorrectly. (ugh) (Service products are generally taxed at the store location, creating this issue)
			//if (isVehicleSale) deal.dealer__Buyer_County__c=dealTaxation.County;    // BLL52c
			if (isVehicleSale && String.isBlank(deal.dealer__Buyer_County__c)) deal.dealer__Buyer_County__c=dealTaxation.County;
			// BLL96 end
              
        	dealTaxation.updDealTaxHeader(deal);
        	Taxes = null;
        }	// BLL79a
        // refresh/reload page
        //Apex.PageReference cq = Page.quotemanager;
        //cq.getParameters().put('id', deal.Id);
        ////cq.setAnchor('sec_fees');
        //cq.setRedirect(true);
        //return cq;
    }
    // getNeedToRecalcTax
    //-----------------------------
    public boolean getNeedToRecalcTax() {
        String hash = null; 
        if (dealTaxation==null && deal.Id!=null) {
            //dealTaxation=AvaTax_MBW.getInstanceDeal(deal.Id);
            dealTaxation = AvaTax_MBW.getInstanceDeal(deal);
            useFMV = dealTaxation.useFairMarketValue(); // BLL20a
            fmvURL = dealTaxation.getFairMarketValueURL(); // BLL20a
            showChassisTaxableBox = dealTaxation.showChassisTaxableSelection(); 
        	TaxCertificateRequired = dealTaxation.getTaxDocumentRequired();	// BLL81a
        }
        if (dealTaxation!=null) {
            hash = dealTaxation.getHash();
        }
        // BLL20a
        boolean needtocalc = (hash!=deal.TaxHash__c  
            || (TaxTotal!=deal.dealer__Sales_Tax__c && deal.dealer__Sales_Tax__c!=deal.SalesTaxOverrideAmt__c));  // BLL20c deal.DoNotCollectTax__c!=true && 
        //if (deal.DoNotCollectTax__c==true) {
        //  needtocalc = TaxTotal!=0.00;
        //}
        // BLL20a
        return needtocalc;  // BLL20c
    }
    // BLL13a end

    public void appendBuyerDetails(String aId) {
        System.debug('AppendBuyerDetails');
        // BLL13a add selection fields (Billing...)
        // BLL74a add selection field dealer__Billing_Email__c
        Account a = [Select Id, FirstName, LastName,MiddleName, PersonHomePhone, PersonMobilePhone, PersonMailingStreet, PersonMailingState, PersonMailingCity,  
                        PersonMailingCounty__c, PersonMailingPostalCode, PersonEmail, PersonOtherPhone, BillingStreet, isPersonAccount,
                        Phone, BillingCity, BillingState, BillingPostalCode, 
                        dealer__Billing_Email__c  
                    from Account where Id =:aId
                    limit 1]; 
                deal.dealer__Buyer__c   =   a.Id;
        System.debug(a);
        System.debug(deal.dealer__Buyer_County__c);
        System.debug(a.PersonMailingCounty__c);
        System.debug(deal.dealer__Buyer_County__c!=a.PersonMailingCounty__c);
            if (a.isPersonAccount) {  // BLL13a
                // BLL39a
                BuyerDetailsChanged = deal.dealer__Buyer_First_Name__c!=a.FirstName || deal.dealer__Buyer_Last_Name__c!=a.LastName 
                    || deal.dealer__Buyer_Middle_Name__c!=a.MiddleName || deal.dealer__Buyer_Home_Phone__c!=a.PersonHomePhone 
                    || deal.dealer__Buyer_Work_Phone__c!=a.PersonOtherPhone || deal.dealer__Buyer_Mobile_Phone__c!=a.PersonMobilePhone 
                    || deal.dealer__Buyer_Address__c!=a.PersonMailingStreet || deal.dealer__Buyer_City__c!=a.PersonMailingCity 
                    || deal.dealer__Buyer_State__c!=a.PersonMailingState || deal.dealer__Buyer_Postal_Code__c!=a.PersonMailingPostalCode 
                    || deal.dealer__Buyer_Email__c!=a.PersonEmail;
                if (!String.isBlank(a.PersonMailingCounty__c) && deal.dealer__Buyer_County__c!=a.PersonMailingCounty__c) BuyerDetailsChanged = true; 
                // BLL39a end
                deal.dealer__Buyer_First_Name__c=   a.FirstName;
                deal.dealer__Buyer_Last_Name__c =   a.LastName;
                deal.dealer__Buyer_Middle_Name__c = a.MiddleName;
                deal.dealer__Buyer_Home_Phone__c=   a.PersonHomePhone;
                deal.dealer__Buyer_Work_Phone__c =  a.PersonOtherPhone; // BLL24a
                deal.dealer__Buyer_Mobile_Phone__c= a.PersonMobilePhone;
                deal.dealer__Buyer_Address__c   =   a.PersonMailingStreet;
                deal.dealer__Buyer_City__c    =   a.PersonMailingCity;
                deal.dealer__Buyer_State__c  =   a.PersonMailingState;
                if (!String.isBlank(a.PersonMailingCounty__c)) deal.dealer__Buyer_County__c =   a.PersonMailingCounty__c;
                deal.dealer__Buyer_Postal_Code__c=  a.PersonMailingPostalCode;
                deal.dealer__Buyer_Email__c  =   a.PersonEmail;
            } else if (deal.dealer__Buyer_Home_Phone__c==null && deal.dealer__Buyer_Address__c==null && deal.dealer__Buyer_City__c==null
                && deal.dealer__Buyer_State__c==null && deal.dealer__Buyer_Postal_Code__c==null){
                String billingemail = deal.dealer__Buyer_Email__c;  // BLL74a
                if (String.isBlank(billingemail) && sup!=null && !String.isBlank(sup.dealer__Email__c)) billingemail = sup.dealer__Email__c;    // BLL74a
                // BLL39a
                BuyerDetailsChanged =  deal.dealer__Buyer_Home_Phone__c!=a.Phone || deal.dealer__Buyer_Address__c!=a.BillingStreet 
                    || deal.dealer__Buyer_City__c!=a.BillingCity || deal.dealer__Buyer_State__c!=a.BillingState
                    || deal.dealer__Buyer_Email__c!=billingemail    // BLL74a
                    || deal.dealer__Buyer_Postal_Code__c!=a.BillingPostalCode;
                // BLL39a end
                deal.dealer__Buyer_Home_Phone__c=   a.Phone;
                deal.dealer__Buyer_Address__c   =   a.BillingStreet;
                deal.dealer__Buyer_City__c    =   a.BillingCity;
                deal.dealer__Buyer_State__c  =   a.BillingState;
                //deal.dealer__Buyer_County__c  =   a.PersonMailingCounty__c;
                deal.dealer__Buyer_Postal_Code__c=  a.BillingPostalCode;
                //deal.dealer__Buyer_Email__c    =   a.PersonEmail;
                if (!String.isBlank(billingemail)) deal.dealer__Buyer_Email__c = billingemail;  // BLL74a
            } // BLL13a
    }

    public List<SelectOption> getCategories() {

        List<SelectOption> categoryItems = new List<SelectOption>();
        // BLL66c add selection Active__c=true
        List<Kit_Category__c> kit_Category = [
            select Id, Name, Type__c 
            from Kit_Category__c 
            where Type__c = 'Category' and Active__c=true      
            order by Order__c ASC, Name ASC limit 5000
        ];
        if (recordTypeName!='Commercial')  categoryItems.add(new SelectOption('', '---'));  // BLL52c add if not commercial
        for(Kit_Category__c k : kit_Category) {
            if (deal.Id==null	// BLL78c
            	|| (recordTypeName!='Commercial' && k.Name!=null && !k.Name.startsWith('Commercial')) 
                || (recordTypeName=='Commercial' && k.Name!=null && k.Name.startsWith('Commercial')))   // BLL52a
                categoryItems.add(new SelectOption(k.Id, k.Name));
        }

        return categoryItems;
    }

    public List<SelectOption> getequipmentMFG() {

        List<SelectOption> mfgItems = new List<SelectOption>();
        List<Kit_Category__c> kit_MFG = new List<Kit_Category__c>();
        List<dealer__Parts_Kit__c> kitList = new List<dealer__Parts_Kit__c>();
        mfgItems.add(new SelectOption('', '---'));

        if(selectCategory!=null) {
            //RT 1
            // BLL66a add selection Active__c=true
            kitList = [
                select Id, Manufacturer__r.Name, Manufacturer__c 
                from dealer__Parts_Kit__c 
                where Category__c =: selectCategory AND Active__c = true 
                      and Manufacturer__r.Active__c=true    
                order by Manufacturer__r.Name limit 1000
            ];   // BLL50c add order by
            System.debug(kitList.size());
            Set<Id> mfg = new Set<Id>(); // BLL1a - ensure uniqueness
            for(dealer__Parts_Kit__c pk : kitList) {
                if (pk.Manufacturer__c!=null && !mfg.contains(pk.Manufacturer__c)) {  // BLL1a
                    mfgItems.add(new SelectOption(pk.Manufacturer__c, pk.Manufacturer__r.Name));
                    mfg.add(pk.Manufacturer__c); // BLL1a
                } // BLL1a 
            }
        } else {
        	// BLL66c add selection Active__c=true
            kit_MFG = [
                select Id, Name 
                from Kit_Category__c 
                where Type__c = 'Manufacturer' and Active__c=true    
                order by Order__c ASC, Name ASC limit 5000
            ]; //BLL50c
            for(Kit_Category__c kmfg : kit_MFG) {
                mfgItems.add(new SelectOption(kmfg.Id, kmfg.Name));
            }      
        }

        Set<SelectOption> uniques = new Set<SelectOption>(mfgItems);

        return new List<SelectOption>(uniques);
    }

    public List<SelectOption> getsubcat() {
        List<SelectOption> subItems = new List<SelectOption>();
        List<Kit_Category__c> kit_MFG = new List<Kit_Category__c>();
        List<dealer__Parts_Kit__c> kitList = new List<dealer__Parts_Kit__c>();
        subItems.add(new SelectOption('', '---'));
  
        // BLL1a - limit sub-category by both category & manufacturer, if specified
        String subset = '';
        String junct = ' WHERE ';
        if (selectCategory!=null && selectCategory!='') {
            subset += junct + ' Category__c=\'' + selectCategory + '\' ';
            junct = ' AND ';
        }
        if (selectMFG!=null && selectMFG!='') {
            subset += junct + ' Manufacturer__c=\'' + selectMFG + '\' ';
            junct = ' AND ';
        }
        String qry = 'Select Id, Sub_Category__r.Name, Sub_Category__c from dealer__Parts_Kit__c '
                   + subset + ' AND Active__c = true ' //RT1
                   + ' and Sub_Category__r.Active__c=true ' // BLL66a
                   + ' order by Sub_Category__r.Name ASC limit 1000';   //BLL50c change order by from just "name" of the parts kit to the name of the sub-category
        if (subset>'') {
            kitList = database.query(qry);
            Set<Id> subc = new Set<Id>();
            for(dealer__Parts_Kit__c pk : kitList) {
                if (pk.Sub_Category__c!=null) {
                    if (!subc.contains(pk.Sub_Category__c)) {
                        subItems.add(new SelectOption(pk.Sub_Category__c, pk.Sub_Category__r.Name));
                        subc.add(pk.Sub_Category__c);
                    }
                }
            }
        // if(selectMFG!=null) {
        //  kitList = [Select Id, Sub_Category__r.Name, Sub_Category__c from dealer__Parts_Kit__c where Manufacturer__c =: selectMFG order by name ASC limit 1000];
        //  for(dealer__Parts_Kit__c pk : kitList) {
        //      if(pk.Sub_Category__c!=null) {
        //          subItems.add(new SelectOption(pk.Sub_Category__c, pk.Sub_Category__r.Name));
        //      }
        //  }
        // BLLa - end change block

        } else {
            // BLL66c add selection Active__c=true
            kit_MFG = [
                select Id, Name 
                from Kit_Category__c 
                where Type__c = 'Sub-category' and Active__c=true   
                order by Order__c ASC, Name ASC limit 5000
            ]; // BLL50c
            for(Kit_Category__c kmfg : kit_MFG) {
                subItems.add(new SelectOption(kmfg.Id, kmfg.Name));
            }          
        }

        return subItems;
    }

	// BLL106
    public void SearchAvailablePartsKits() {
		cParts = getAvailablePartsKits();
	}
	// BLL106

    // Method to Build Table for Kits Available
    public List<cPartsKit> getAvailablePartsKits() {
		System.debug('getAvailablePartsKits');
        cParts.clear();
        // BLL1 replace test for open query

        // AMM95
        List<Id> listOfPartIds = new List<Id>();
        
        List<Parts_Kit_Favorite__c> listOfFavs = ([SELECT Id,
                                                        Parts_Kit__c
                                                    FROM Parts_Kit_Favorite__c
                                                    WHERE Store_Location__c = :location.Id AND 
                                                        User__c = :UserInfo.getUserId()]);

        for(Parts_Kit_Favorite__c tempFav : listOfFavs)
        {
            listOfPartIds.add(tempFav.Parts_Kit__c);
        }
        // AMM95
		System.debug('Number of favorites: ' + String.valueOf(listOfPartIds.size()));

        // AMM96
        Id recordId = ApexPages.currentPage().getParameters().get('id');
		// BLL106
        //String objectType = recordId != null ? String.valueOf(recordId).substring(0,3) : 'none'; 
		// BLL106
        // AMM96

        // if ((selectCategory != null || selectMFG != null || selectSubCat != null || searchByDescription != null || searchByPartNumber != null || searchByNotes != null)
        //  && (selectCategory != '' || selectMFG != '' || selectSubCat != '' || searchByDescription != '' || searchByPartNumber != '' || searchByNotes != ''))  {
		// BLL106
        //if ((selectCategory != null && selectCategory.trim()!='') || (selectMFG != null && selectMFG.trim()!='') || (selectSubCat != null && selectSubCat.trim()!='') 
        //    || (searchByDescription != null && searchByDescription.trim()!='') || (searchByPartNumber != null  && searchByPartNumber.trim()!='') || (searchByNotes != null && searchByNotes.trim()!='')) {
		// BLL106 end
        // BLL1a end replacement
            System.debug('cat='+selectCategory+'; mfg=' + selectMFG + '; subcat=' + selectSubCat); // BLL1a
            System.debug('desc=' + searchByDescription + '; part=' + searchByPartNumber + '; notes=' + searchByNotes); // BLL1a
            
            // Begin the quary string
            String queryStart = 'SELECT dealer__Description__c, dealer__Kit_Gross_Margin__c, dealer__Kit_Price__c, dealer__Labor_Cost__c, dealer__Labor_Sale__c, dealer__Manufacturer__c, dealer__Sell_on_Deals__c, dealer__Item_Count__c, dealer__Kit_Cost__c, dealer__Kit_List__c, Category__c, Manufacturer__c, Sub_Category__c, Kit_Notes__c, Inventory_Price__c, Labor_Hours__c, CMC_Price__c, Retail_Price__c, Name, Id, Cost_West__c, Cost_East__c, Cost_Method__c,Price_West__c,Price_East__c, '    // BLL30c
                + 'LaborSaleEast__c, LaborSaleWest__c ' // BLL30a
                + 'FROM dealer__Parts_Kit__c '; // BLL30c

            // Make a list for the Query Parts.
            List<String> qBits = new List<String>();

            //RT1   
            qBits.add(' Active__c = true ');    
                
            // Search by Category - selectCategory
            if( selectCategory != null ) { 
                qBits.add(' Category__c = \''+selectCategory+'\' ');
            }

            // Search by MFG - selectMFG
            if(selectMFG != null) { 
                qBits.add(' Manufacturer__c = \''+selectMFG+'\' ');
            }

            // Search by Sub Category - selectSubCat
            if(selectSubCat != null) { 
                qBits.add(' Sub_Category__c = \''+selectSubCat+'\' ');
            }

            // Search by Description - searchByDescription
            if( searchByDescription != null  && searchByDescription != '' ) { 
                //BLL48d qBits.add(' dealer__Description__c LIKE \'%' +searchByDescription+ '%\'' );
                qBits.add(' dealer__Description__c LIKE \'%' + String.escapeSingleQuotes(searchByDescription) + '%\''); // BLL48a
            }

            // Search by Part Number - searchByPartNumber
            if( searchByPartNumber != null && searchByPartNumber != '' ) { 
                //BLL48d qBits.add(' Name LIKE \'%' +searchByPartNumber+ '%\'' );
                qBits.add(' Name LIKE \'%' + String.escapeSingleQuotes(searchByPartNumber) + '%\'' );   // BLL48a
            }

			// BLL107 - Kit_Notes__c is going to be increased past 256 chars and too large to search
            // Search by Note - searchByNotes
            //if( searchByNotes != null && searchByNotes != '' ) { 
                //BLL48d qBits.add(' Kit_Notes__c LIKE \'%' +searchByNotes+ '%\'' );
                //BLL107 qBits.add(' Kit_Notes__c LIKE \'%' + String.escapeSingleQuotes(searchByNotes) + '%\'' );    // BLL48a
				//qBits.add(' dealer__Kit_Notes__c LIKE \'%' + String.escapeSingleQuotes(searchByNotes) + '%\'' );    // BLL48a
            //}
			// BLL107 end

            // Start building Query
            String query = queryStart;

			// BLL106d
            // Then build the query string from the Bits.
            //for(Integer a = 0; a < qBits.size(); a++){
			//
            //    // Prefix the bits with some query operators
            //    // AMM95
            //    //if (a == 0) {
            //    //     query += ' WHERE ( ';
            //    //}
            //    if (a == 0 && showFavorites && qBits.size() == 1) {
            //         query += ' WHERE ( ';
            //    }
            //    else if (a == 0 && ( !showFavorites || qBits.size() > 1)) {
            //         query += ' WHERE ';
            //    }
            //    // AMM95
            //    if (a > 0) {
            //        query += ' AND ';
            //    }
            //    // Concatenate the bits
            //    query += qBits.get(a);
            //}

            // AMM95
            //if(showFavorites && qBits.size() == 1)
            //{
            //    query += ' ) OR ( Id IN  (\'' + String.join(listOfPartIds,'\',\'') +'\') )';
            //}              
			// AMM95
			// BLL106d end

			// BLL106
			if (qBits.size()==1 && showFavorites && listOfPartIds.size()>0) qBits.add(' Id in (\'' + String.join(listOfPartIds,'\',\'') + '\') ');
			query += ' WHERE ' + String.join(qBits, ' AND ');
			// BLL106 end

			// BLL93
			query += ' ORDER BY Name ';
			// BLL93 end

            //query += 'LIMIT 1000';
            query += ' LIMIT 500 '; // BLL1 - getting view state errors with open query, try limiting results

            System.debug(query);

            List<dealer__Parts_Kit__c> cPKit = Database.query( query );     

            // AMM95
            cPKit = getPartFavorites(cPKit);
            // AMM95
            
            for(dealer__Parts_Kit__c kit : cPKit) {
                // AMM95
                //cParts.add(new cPartsKit(kit, true, 0, ((location!=null)?location.Tax_Equipment__c:true))); // BLL4c location==null?
                cParts.add(new cPartsKit(kit, true, 0, ((location!=null)?location.Tax_Equipment__c:true), ((mapOfFavoritedPartKits.get(kit.Id) != null)?mapOfFavoritedPartKits.get(kit.Id):false))); // BLL4c location==null?
                // AMM95
            }   

        // BLL106
		//}
		// BLL106 end
        // AMM96
        //else if(showFavorites)
		// BLL106
        //else if(showFavorites && objectType != 'a1Y')
        //{
		// BLL106
        // AMM96
        //    String query = 'SELECT dealer__Description__c, dealer__Kit_Gross_Margin__c, dealer__Kit_Price__c, dealer__Labor_Cost__c, dealer__Labor_Sale__c, dealer__Manufacturer__c, dealer__Sell_on_Deals__c, dealer__Item_Count__c, dealer__Kit_Cost__c, dealer__Kit_List__c, Category__c, Manufacturer__c, Sub_Category__c, Kit_Notes__c, Inventory_Price__c, Labor_Hours__c, CMC_Price__c, Retail_Price__c, Name, Id, Cost_West__c, Cost_East__c, Cost_Method__c,Price_West__c,Price_East__c, '    // BLL30c
        //        + 'LaborSaleEast__c, LaborSaleWest__c ' // BLL30a
        //        + 'FROM dealer__Parts_Kit__c '
        //        + 'WHERE Id IN  (\'' + String.join(listOfPartIds,'\',\'') +'\') ' 
		//		+ 'ORDER BY Name '
        //        + 'LIMIT 500';
		//
        //    List<dealer__Parts_Kit__c> cPKit = Database.query( query );     
		//
        //    cPKit = getPartFavorites(cPKit);
		//
        //    for(dealer__Parts_Kit__c kit : cPKit) {
		//
        //        // AMM95
        //        //cParts.add(new cPartsKit(kit, true, 0, ((location!=null)?location.Tax_Equipment__c:true))); // BLL4c location==null?
        //        cParts.add(new cPartsKit(kit, true, 0, ((location!=null)?location.Tax_Equipment__c:true), ((mapOfFavoritedPartKits.get(kit.Id) != null)?mapOfFavoritedPartKits.get(kit.Id):false))); // BLL4c location==null?
        //        // AMM95
        //    }  
        //}
		// BLL106
        // AMM95

        return cParts;
    }


     // AMM95
    /**
    * getPartFavorites
    *
    * Function which takes the existing Parts Kits 
    * and sorts them based on favorites. The order is
    * User -> Store -> unfavorited
    *
    * @param listOfPartKits - List<dealer__Parts_Kit__c>
    * @return List<dealer__Parts_Kit__c> - sorted by user and location
    */
    public List<dealer__Parts_Kit__c> getPartFavorites(List<dealer__Parts_Kit__c> listOfPartKits)
    {
        mapOfFavoritedPartKits = new Map<Id, Boolean>();

        // 1. Contain the map of Part Kits for later
        Map<Id, dealer__Parts_Kit__c> mapOfPartKits = new Map<Id, dealer__Parts_Kit__c>();
        List<dealer__Parts_Kit__c> sortedPartList = new List<dealer__Parts_Kit__c>();

        // 2. Get the favorites right off the bat from either the user or the location
        Map<Id, Parts_Kit_Favorite__c> mapOfFavorites = new Map<Id, Parts_Kit_Favorite__c>([SELECT Id,
                                                                                                Parts_Kit__c,
                                                                                                Store_Location__c,
                                                                                                User__c
                                                                                            FROM Parts_Kit_Favorite__c
                                                                                            WHERE Store_Location__c = :location.Id AND 
                                                                                                User__c = :UserInfo.getUserId()]);

        // 3. Make sure they match
        for(dealer__Parts_Kit__c tempPart : listOfPartKits)
        {
            for(Parts_Kit_Favorite__c tempFav : mapOfFavorites.values())
            {
                if(showFavorites && 
                    tempFav.Parts_Kit__c != null && tempFav.Parts_Kit__c == tempPart.Id && 
                    tempFav.User__c != null && tempFav.User__c == UserInfo.getUserId() &&
                    tempFav.Store_Location__c != null && tempFav.Store_Location__c == location.Id &&
                    mapOfPartKits.get(tempPart.Id) == null)
                {
                    sortedPartList.add(tempPart);
                    mapOfPartKits.put(tempPart.Id, tempPart);
                    mapOfFavoritedPartKits.put(tempPart.Id, true);
                }
            }
        }

        // 4. The rest of the parts
        for(dealer__Parts_Kit__c tempPart : listOfPartKits)
        {
            if(mapOfPartKits.get(tempPart.Id) == null)
            {
                sortedPartList.add(tempPart);
                mapOfFavoritedPartKits.put(tempPart.Id, false);
            }
        }
        
        return sortedPartList;
    }

    /**
    * favoriteClick
    *
    * Apex onclick listener for the stars on the page
    * to interact with the database and show the view 
    * respectively
    *
    * @partkitId - Id of the part kit favorited in this transaction
    */
    @RemoteAction
    global static void favoriteClick(Id partkitId, Boolean boolFlag, Id locationId, Boolean showFavorites)
    {   
        if(showFavorites)
        {
            if(boolFlag)
            {
                Parts_Kit_Favorite__c tempFavorite = new Parts_Kit_Favorite__c();
                    
                tempFavorite.User__c = UserInfo.getUserId();
                tempFavorite.Parts_Kit__c = partkitId;
                tempFavorite.Store_Location__c = locationId;
                
                insert tempFavorite;
            }
            else
            {
                List<Parts_Kit_Favorite__c> listOfFavorites = ([SELECT Id 
                                                                    FROM Parts_Kit_Favorite__c 
                                                                    WHERE Parts_Kit__c = :partkitId AND 
                                                                        User__c = :UserInfo.getUserId()]);

                if(listOfFavorites.size() > 0)
                {
                    delete listOfFavorites;
                }
            }
        }
    }

    // AMM95


//RT3   
    public PageReference searchParts() {

        if(searchByPartNumber!=null && searchByPartNumber!='') {
            String likeSearch = '%'+searchByPartNumber+'%';
            // BLL75c add or Supersedes like search
            // BLL66c omit obsolete status
            partMasterResults = [
                select Id, Name, dealer__Part_Description__c, dealer__Cost__c, dealer__Retail_Price__c, Static_price__c
                from dealer__Parts_Master__c 
                where (Name LIKE :likeSearch or Supersedes__c like :likeSearch)      
                  and dealer__Status__c!='Obsolete' 
                limit 100
            ];
            // BLL75c add or Supersedes like search
            // BLL66c omit obsolete status
            partResults = [
                select Name, dealer__Description__c, dealer__On_Hand__c,dealer__Cost__c,dealer__List__c, dealer__Static_Price__c
                from dealer__Parts_Inventory__c 
                where (Name like :likeSearch or dealer__Supersedes__c like :likeSearch)  
                  and dealer__Status__c!='Obsolete' 
                limit 100
            ];
            return null;
        }

        if(searchByDescription!=null && searchByDescription!='') {
            String likeSearch = '%'+searchByDescription+'%';
            // BLL66c omit obsolete status
            partMasterResults = [
                select Id, Name, dealer__Part_Description__c, dealer__Cost__c, dealer__Retail_Price__c, Static_price__c
                from dealer__Parts_Master__c 
                where dealer__Part_Description__c LIKE :likeSearch and dealer__Status__c!='Obsolete'    
                limit 100
            ];
            // BLL66c omit obsolete status
            partResults = [
                    select Name, dealer__Description__c, dealer__On_Hand__c,dealer__Cost__c,dealer__List__c, dealer__Static_Price__c
                    from dealer__Parts_Inventory__c 
                    where dealer__Description__c like :likeSearch and dealer__Status__c!='Obsolete' 
                    limit 100
                ];
            return null;
        }

        return null;
    }

    public Integer getcPartsSize() {
        return cParts.size();
    }

    public class cPartsKit {
        // AMM95
        public Boolean favorited {get;set;}
        // AMM95
        public dealer__Parts_Kit__c kit {get;set;}
        public boolean selectKit {get;set;}
        public Decimal sellFor {get;set;}
        public Boolean taxable {get;set;}
        // AMM95
        // public cPartsKit(dealer__Parts_Kit__c p, boolean tf, Decimal sf, boolean t) {
        public cPartsKit(dealer__Parts_Kit__c p, boolean tf, Decimal sf, boolean t, Boolean fav) {
        // AMM95
            kit      =   p;
            selectKit   =   tf;
            sellFor  =   sf;
            taxable  =   t;
            // AMM95
            favorited = fav;
            // AMM95
        }
    }

    // BLL17a - Service vehicle mileage
    public void setServiceODO() {
        System.debug(deal.dealer__Mileage__c);
        System.debug(deal.dealer__Vehicle__c);
        System.debug(deal.dealer__Service_Vehicle__c);  // BLL51c
        System.debug(deal.dealer__Service_Vehicle__r.dealer__Last_Odometer__c); // BLL51c
        if ((deal.dealer__Mileage__c==null || deal.dealer__Mileage__c==0) 
            //BLL52d && recordTypeName!=null && recordTypeName.startsWith('Equipment')
            && deal.dealer__Deal_Type__c!=null && (deal.dealer__Deal_Type__c.startsWith('Equipment') || deal.dealer__Deal_Type__c.startsWith('Financial'))  // BLL52a 
            && deal.dealer__Service_Vehicle__c!=null    // BLL51c 
            && deal.dealer__Service_Vehicle__r.dealer__Last_Odometer__c!=null) {    // BLL51c
            deal.dealer__Mileage__c = deal.dealer__Service_Vehicle__r.dealer__Last_Odometer__c; // BLL51c
        }
    }
    // BLL17a end

    // BLL44a
    public void markLost() {
        MW_TriggerControls__c AppraisalsMarkLost = MW_TriggerControls__c.getInstance('AppraisalsMarkLost');
        boolean markAppraisalsLost = AppraisalsMarkLost==null || AppraisalsMarkLost.Enabled__c==true;
        if (deal.dealer__Status__c=='Pending') {
            // BLL75a - mark related appraisals lost (so trigger doesn't have to)
            // Similar logic in BatchUpdateInactiveDeals, Deal_MBW2, DealProcess
            if (markAppraisalsLost && deal.dealer__Deal_Type__c=='Chassis/Conversion' && deal.Vehicle_Source__c=='Inventory') {
                List<dealer__Appraisal__c> appr = [select Id, Name, dealer__Status__c, Lost_Reason__c from dealer__Appraisal__c where dtmob__Deal__c=:deal.id and dealer__Status__c='Pending'];
                for(dealer__Appraisal__c a : appr) {
                    a.dealer__Status__c = 'Lost';
                    a.Lost_Reason__c = String.isBlank(a.Lost_Reason__c) ? 'No Activity on Appraisal' : a.Lost_Reason__c;
                }
                Database.update(appr, false);
            }   
            // BLL75a end
            deal.dealer__Status__c = 'Lost';
            inplaceSaveProposal();
            // BLL57a
            if (deal.Commercial_Quote__c!=null && oem!=null && oem.Status__c=='Pending') {
                try { update(new CommercialQuote__c(Id=deal.Commercial_Quote__c,Status__c='Lost')); }
                catch(Exception e) {}
            }
            // BLL57a
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Only pending proposals can be marked lost. Recall or reject won proposals first.'));
        } 
    }
    // BLL44a end
    // BLL72a
    public PageReference markPending() {
        if (deal.dealer__Status__c=='Lost') {
            //deal.dealer__Status__c = 'Pending';
            //inplaceSaveProposal();
            dealer__Sales_Up__c sup;
            if (deal.dealer__Sales_Lead__c!=null) sup = [select Id, Name, dealer__Lead_Status__c from dealer__Sales_Up__c where Id=:deal.dealer__Sales_Lead__c limit 1];
            if (sup!=null && sup.dealer__Lead_Status__c=='Lost') Database.update(new dealer__Sales_Up__c(Id=deal.dealer__Sales_Lead__c, dealer__Lead_Status__c='Pending'));
            Database.update(new dealer__Deal__c(Id=deal.Id, dealer__Status__c='Pending'));
            if (deal.Commercial_Quote__c!=null && oem!=null && oem.Status__c=='Lost') {
                try { update(new CommercialQuote__c(Id=deal.Commercial_Quote__c,Status__c='Pending')); }
                catch(Exception e) {}
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Only lost proposals can be re-opened to pending.'));
            return null;
        } 
        PageReference pr = self; // BLL52c Page.quotemanager;
        pr.getParameters().put('id', deal.Id);
        pr.setRedirect(true);
        return pr;    
    }
    // BLL72a end

    // BLL12a
    public void inplaceSaveProposal() {
        if (deal.dealer__Status__c!='Won - Posted' && deal.dealer__Sales_Lead__c!=null) {  // BLLa
            try {   // BLL18a
            saveProposal();
            } catch(Exception e) {  // BLL18a
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Unable to save proposal: ' + e.getMessage()));  // BLL18a
            }   // BLL18a
        }   // BLLa
    }
    // BLL12a end


    // BLL52a
    public void chgDeliverTo() {
        if (deal.Deliver_to__c=='Customer') {
            deal.dealer__Delivery_Street__c = deal.dealer__Buyer_Address__c;
            deal.dealer__Delivery_City__c = deal.dealer__Buyer_City__c;
            deal.dealer__Delivery_State__c = deal.dealer__Buyer_State__c;
            deal.DeliveryPostalCode__c = deal.dealer__Buyer_Postal_Code__c;
            //deal.dealer__Delivery_Postal_Code__c = Decimal.valueOf(deal.dealer__Buyer_Postal_Code__c);
        }
        if (deal.Deliver_to__c=='Releasing Dealer') {
            try {
                Account rd = [select Id, BillingStreet, BillingCity, BillingState, BillingPostalCode from Account where Id=:deal.ReleasingDealer__c];
                deal.dealer__Delivery_Street__c = rd.BillingStreet;
                deal.dealer__Delivery_City__c = rd.BillingCity;
                deal.dealer__Delivery_State__c = rd.BillingState;
                deal.DeliveryPostalCode__c = rd.BillingPostalCode;
                //deal.dealer__Delivery_Postal_Code__c = Decimal.valueOf(rd.BillingPostalCode);
            } catch(Exception e) {}
        }
        if (deal.Deliver_to__c=='Store') {
            if (deal.Delivery_Store__c==null) deal.Delivery_Store__c = deal.dealer__Store_Location__c;
            dealer__Dealer_Location__c loc = new dealer__Dealer_Location__c(dealer__Street__c=null, dealer__City__c=null, dealer__State__c=null, dealer__Postal_Code__c=null);
            try {
                loc = [select Id, dealer__Street__c, dealer__City__c, dealer__State__c, dealer__Postal_Code__c from dealer__Dealer_Location__c where Id=:deal.Delivery_Store__c limit 1];
            } catch(Exception e) {}
            deal.dealer__Delivery_Street__c = loc.dealer__Street__c;
            deal.dealer__Delivery_City__c = loc.dealer__City__c;
            deal.dealer__Delivery_State__c = loc.dealer__State__c;
            deal.DeliveryPostalCode__c = loc.dealer__Postal_Code__c;
            //try {
            //deal.dealer__Delivery_Postal_Code__c = loc.dealer__Postal_Code__c==null ? null : Decimal.valueOf(loc.dealer__Postal_Code__c);
            //} catch(Exception e) {}
        } else {
            deal.Delivery_Store__c = null;
        }
    }

    public void setDefaultFees() {
            if (location.Doc_Fee__c!=null) deal.dealer__Doc_Fee__c  = location.Doc_Fee__c;
            if (location.Electronic_Filing_Fee__c!=null) deal.Electronic_Filing_Fee__c  = location.Electronic_Filing_Fee__c;
            //if (location.Electronic_Filing_Fee__c!=null) deal.dealer__Electronic_Filing_Fee__c    = location.Electronic_Filing_Fee__c;
            if (location.Smog_Certification_Fee__c!=null) deal.Smog_Cert__c = location.Smog_Certification_Fee__c;
            //if (location.Smog_Certification_Fee__c!=null) deal.dealer__Smog_Cert__c   = location.Smog_Certification_Fee__c;
            if (location.Smog_Fee__c!=null) deal.Smog_Fee__c    = location.Smog_Fee__c;
            //if (location.Smog_Fee__c!=null) deal.dtmob__Smog_Fee__c   = location.Smog_Fee__c;
            if (location.Tag_Fee__c!=null) deal.dealer__License_Fee__c  = location.Tag_Fee__c;
            if (location.Title_Fee__c!=null) deal.Registration_Title_Fee__c = location.Title_Fee__c;
            //if (location.Title_Fee__c!=null) deal.dealer__Registration_Title_Fee__c   = location.Title_Fee__c;
            // Tire_Fee__c, dealer__Tire_Fee__c
    }
    // BLL52a end 
    
    
    public PageReference saveProposal() {
System.debug('saveProposal');
        autoSaveDeal = false;   // BLL52a reset!

        // JVK1
        // Check to see if there is a First Appointment Set.
        if(deal.dealer__Sales_Lead__c==null && deal.dealer__Status__c!='Won - Posted') throw new DealException('Must be created from a Solution Opportunity');

        // BLL8d dealer__Sales_Appointment__c[] sList = [SELECT dealer__Show__c,dealer__Appointment_Type__c, dealer__Sales_Up__c, dealer__Appointment_Result__c, Id FROM dealer__Sales_Appointment__c where dealer__Sales_Up__c =:deal.dealer__Sales_Lead__c and dealer__Appointment_Type__c = 'First Visit' and dealer__Appointment_Result__c = 'Show' limit 10];
        // BLL8a - new query - any kind of appointment with a result of 'Show'
        //dealer__Sales_Appointment__c[] sList = [
        //  select dealer__Show__c,dealer__Appointment_Type__c, dealer__Sales_Up__c, dealer__Appointment_Result__c, Id 
        //  from dealer__Sales_Appointment__c 
        //  where dealer__Sales_Up__c =:deal.dealer__Sales_Lead__c and dealer__Appointment_Result__c = 'Show' 
        //  limit 10
        //];
        // BLL8a - end

        //if(sList.size()==0) {
        //  throw new DealException('Error: Solution Opportunity must have had a First Appointment with result of Show.');
        //}
        //JVK1

        // BLL12a don't allow new proposal on lost solution opportunity
        dealer__Sales_Up__c sup = [select Id, dealer__Lead_Status__c from dealer__Sales_Up__c where Id=:deal.dealer__Sales_Lead__c limit 1];
        if (deal.Id==null && sup.dealer__Lead_Status__c=='Lost') throw new DealException('You cannot create a new proposal on a lost solution opportunity.');
        // BLL12a end

        // BLL52a defaults
        if (deal.Id==null && recordTypeName=='Retail' && deal.dealer__Deal_Type__c=='Chassis/Conversion') deal.Vehicle_Source__c = 'Inventory';
        if (deal.Id==null && deal.dealer__Deal_Type__c=='Wholesale') deal.Vehicle_Source__c = 'Inventory';
        // BLL52a end

        // BLL37a - don't save stock vehicle info if this is an equipment only deal!
        //BLL52d if (recordTypeName!=null && recordTypeName.startsWith('Equipment')) {
        if (!isVehicleSale) { // BLL52a
			// BLL93
            //deal.dealer__Vehicle__c = null;
            //deal.Chassis_Cost__c = 0;
            //deal.Conversion_Cost__c = 0;
			removeVehicleBeforeSave();
			// BLL93 end
            deal.Chassis_Price__c = 0;
            deal.Conversion_Price__c = 0;
            deal.dealer__Stock_Number__c = null;
            deal.dealer__Sale_Price__c = 0;
            deal.Vehicle_Source__c = null;
            deal.Commercial_Quote__c = null;    // BLL55a
            // BLL86
            //deal.Pack__c = 0;   // BLL55a
            deal.Pack__c = null;
            // BLL86 end
			// BLL92
			// BLL93d deal.Conversion_Description__c = null;
			// BLL92 end
			// BLL93 - remove releasing dealer for non-vehicle sales
			deal.ReleasingDealer__c = null;
			// BLL93 end
        }
        if (!isCustomerVehicle) deal.dealer__Service_Vehicle__c = null; // BLL52a remove customer vehicle if not used (hidden & not editable, so remove it)
        // No chassis until cloned for qty=1 (BLL93 -- do not clear out other fields removed by "removeVehicleBeforeSave" routine)
        if (isVehicleSale && deal.Chassis_QTY__c>1) deal.dealer__Vehicle__c = null;
        // BLL37a end

        // BLL52a misc additional set/reset fields
        if (recordTypeName!='Commercial' && isVehicleSale) deal.Chassis_QTY__c = 1;
        if (deal.Chassis_QTY__c==null) deal.Chassis_QTY__c = 1;

		// BLL81a - reset flag if it doesn't apply so it doesn't hang around from before if
		// buyer state or tax requirements are updated
		if (String.isBlank(TaxCertificateRequired)) deal.HaveRequiredTaxCert__c = false;
		// BLL81a end

        if (oem!=null) {    // force chassis cost & price, conversion cost & price from quote
            if(deal.Chassis_Cost__c==null) deal.Chassis_Cost__c = oem.Chassis_Cost__c;
            if(deal.Chassis_Price__c==null) deal.Chassis_Price__c = oem.Chassis_Price__c;
            if(deal.Conversion_Cost__c==null) deal.Conversion_Cost__c = (oem.Total_Options_Cost__c + oem.Freight_Cost__c) / oem.Chassis_QTY__c;
            if(deal.Conversion_Price__c==null) deal.Conversion_Price__c = (oem.Total_Options_Price__c + oem.Freight_Amount__c) / oem.Chassis_QTY__c;
            deal.Conversion_Cost__c = deal.Conversion_Cost__c.setScale(2);
            deal.Conversion_Price__c = deal.Conversion_Price__c.setScale(2);
        }
        chgDeliverTo();
        // BLL52a end

        // Set zero value on dollar value fields
        if(deal.Chassis_Price__c==null && deal.dealer__Vehicle__c!=null) deal.Chassis_Price__c = deal.dealer__Vehicle__r.dealer__Vehicle_Cost__c; // BLL19a
        if(deal.Chassis_Price__c==null) {deal.Chassis_Price__c=0;}
        //if(deal.Conversion_Price__c==null && deal.dealer__Vehicle__c!=null) deal.Conversion_Price__c = deal.dealer__Vehicle__r.Conversion_Cost__c; // BLL19a
        if(deal.Conversion_Price__c==null) {deal.Conversion_Price__c=0;}
        if(deal.Total_Additional_Equipment__c==null) {deal.Total_Additional_Equipment__c=0;}
        if(deal.TotalAdditionalEquipLabor__c==null) {deal.TotalAdditionalEquipLabor__c=0;}  // BLL30a
        if(deal.Total_Protection_Products__c==null) {deal.Total_Protection_Products__c=0;}
        if(deal.dealer__Doc_Fee__c==null) {deal.dealer__Doc_Fee__c=0;}
        if(deal.dealer__License_Fee__c==null) {deal.dealer__License_Fee__c=0;}
        if(deal.Registration_Title_Fee__c==null) {deal.Registration_Title_Fee__c=0;}
        if(deal.Smog_Cert__c==null) {deal.Smog_Cert__c=0;}
        if(deal.Smog_Fee__c==null) {deal.Smog_Fee__c=0;}
        if(deal.Tire_Fee__c==null) {deal.Tire_Fee__c=0;}
        if(deal.Electronic_Filing_Fee__c==null) {deal.Electronic_Filing_Fee__c=0;}
        if(deal.dealer__Sales_Tax__c==null) {deal.dealer__Sales_Tax__c=0;}

        if(deal.Mobility_Rebate__c==null) {deal.Mobility_Rebate__c=0;}
        if(deal.MFG_Rebate__c==null) {deal.MFG_Rebate__c=0;}
        if(deal.dealer__Deferred_Down_2__c==null){deal.dealer__Deferred_Down_2__c=0;}
        if(deal.dealer__Deferred_Down_3__c==null){deal.dealer__Deferred_Down_3__c=0;}
        if(deal.dealer__Deposit__c==null) {deal.dealer__Deposit__c=0;}
        if(deal.dealer__Down_Pymt__c==null) {deal.dealer__Down_Pymt__c=0;}

        if(deal.Conversion_Discount__c==null) {deal.Conversion_Discount__c=0;}
        if(deal.MBW_Rewards__c==null) {deal.MBW_Rewards__c=0;}

        if(deal.dealer__Deferred_Down_1__c==null) {deal.dealer__Deferred_Down_1__c=0;}

        if(deal.dealer__Rebate__c==null) { deal.dealer__Rebate__c = 0; }
        if(deal.Rebate_2__c==null) { deal.Rebate_2__c = 0; }
        if(deal.Rebate_3__c==null) { deal.Rebate_3__c = 0; }
        if(deal.dealer__Deferred_Down_2__c==null) {deal.dealer__Deferred_Down_2__c = 0;}
        if(deal.dealer__Deferred_Down_3__c==null) {deal.dealer__Deferred_Down_3__c = 0;}

        if(deal.AutoGrant__c==null) {deal.AutoGrant__c = 0;}

        // BLL52a
        if(deal.Government_Price_Concession__c==null) {deal.Government_Price_Concession__c = 0;}
        if (deal.Chassis_Price__c==null && deal.Conversion_Price__c==null) deal.dealer__Sale_Cost__c = null;
        if (deal.Chassis_Price__c==null) deal.Chassis_Price__c = 0.00;  // BLL33a
        if (deal.Conversion_Price__c==null) deal.Conversion_Price__c = 0.00;    // BLL33a
        deal.dealer__Sale_Cost__c      =   deal.Chassis_Price__c + deal.Conversion_Price__c;
        if (recordTypeName!='Commercial' || deal.DeliveryFreightCost__c==null) deal.DeliveryFreightCost__c = 0;
        if (recordTypeName!='Commercial' || deal.DeliveryFreightAmount__c==null) deal.DeliveryFreightAmount__c = 0; 
        // BLL52a end

		// BLL84a
		// calc total due (used in validateProposal)
		deal.TotalOutsideFunding__c = nullAsZero(deal.Grants_Government_Assistance__c) + nullAsZero(deal.dealer__Deferred_Down_1__c) + nullAsZero(deal.dealer__Deferred_Down_2__c) + nullAsZero(deal.dealer__Deferred_Down_3__c);
		deal.GrossCapitalizedCost__c = nullAsZero(deal.Total_Price__c) - (nullAsZero(deal.dealer__Down_Pymt__c) + nullAsZero(deal.dealer__Deposit__c)) - nullAsZero(deal.TotalOutsideFunding__c); 
		deal.TotalDueUponDelivery__c = nullAsZero(deal.Total_Price__c) - nullAsZero(deal.TotalOutsideFunding__c) - nullAsZero(deal.Contract_Amount_Financed__c)
			- nullAsZero(deal.dealer__Deposit__c) - nullAsZero(deal.dealer__Down_Pymt__c) - nullAsZero(deal.dealer__Trade_Allowance__c);
		if (deal.Funding_option__c=='Financed' && deal.Contract_Type__c=='Lease' && deal.Contract_Monthly_Payment__c!=null) deal.TotalDueUponDelivery__c += deal.Contract_Monthly_Payment__c;
		System.debug(deal.Total_Price__c);
		System.debug(deal.TotalOutsideFunding__c);
		System.debug(deal.Contract_Amount_Financed__c);
		System.debug(deal.dealer__Deposit__c);
		System.debug(deal.dealer__Down_Pymt__c);
		System.debug(deal.dealer__Trade_Allowance__c);
		System.debug(deal.Contract_Monthly_Payment__c);
		System.debug(deal.TotalDueUponDelivery__c);
		// BLL84a end

        // Check store location and set based on the Sol Op Location
        if(deal.dealer__Store_Location__c == null) {
            if(deal.dealer__Sales_Lead__c != null) {
                dealer__Sales_Up__c up = [Select Id, Company__c from dealer__Sales_Up__c where Id=:deal.dealer__Sales_Lead__c limit 1];
                deal.dealer__Store_Location__c = up.Company__c; // BLL2a (just in case not set at creation) 
            }
        }

        // BLL2a - set Company number from location
        if (deal.dealer__Store_Location__c!=null) {
        	// BLL52a  add commercial_sales_admin__c, F_I_Manager__c
            dealer__Dealer_Location__c l = [
                select Id, dealer__Company_Number__c, County__c, dealer__General_Manager__c, Sales_Admin__c, dealer__Service_Director__c,   // BLL45c
                    Commercial_Sales_Admin__c, F_I_Manager__c   
                from dealer__Dealer_Location__c 
                where Id=:deal.dealer__Store_Location__c 
                limit 1
            ];
            deal.dealer__Company_Number__c = l.dealer__Company_Number__c;
            // BLL45a - use lcoation's managers when first saved
            //if(deal.Id==null) {
            if (l!=null && deal.dealer__Store_Location__c!=location.Id) {   // Test: Any time the location has changed?
                if(l!=null && l.dealer__General_Manager__c!=null) deal.dealer__Desk_Manager__c=l.dealer__General_Manager__c;
                if(l!=null && l.dealer__Service_Director__c!=null) deal.dtmob__service_manager__c = l.dealer__Service_Director__c;  // BLl51c
                //BLL52d if(l!=null && l.Sales_Admin__c!=null) deal.Sales_Admin__c = l.Sales_Admin__c;
                if(RecordTypeName!='Commercial' && deal.Sales_Admin__c==null && l!=null && l.Sales_Admin__c!=null) deal.Sales_Admin__c = l.Sales_Admin__c;  // BLL52a
                if(RecordTypeName=='Commercial' && deal.Sales_Admin__c==null && l!=null && l.Commercial_Sales_Admin__c!=null) deal.Sales_Admin__c = l.Commercial_Sales_Admin__c;    // BLL52a
                if(deal.dealer__F_I_Manager__c==null && location.F_I_Manager__c!=null) deal.dealer__F_I_Manager__c = location.F_I_Manager__c;   // BLL52a
            }
            // BLL45a
        }
        // BLL2a - end block

        // Commission Employee is no longer maintained on-screen, so copy CMC 1 to this field
        deal.Commission_Employee_1__c=deal.dealer__Salesperson_1__c;    // BLL56a

        // BLL58a - If there's a service vehicle and no inventory vehicle, set vin, year, make, model
        if (deal.dealer__Service_Vehicle__c!=null && (deal.dealer__Vehicle__c==null || deal.Vehicle_Source__c=='Customer Owned')) {
            try {
            	// BLL69a add dealer__Sales_Inventory__c
                dealer__Service_Vehicle__c sv = [
                    select dealer__VIN__c, dealer__Year__c, dealer__Make__c, dealer__Carline__c, dealer__Model_Code__c, dealer__Ext_Color__c,   // BLL65c 
                        dealer__Sales_Inventory__c  
                    from dealer__Service_Vehicle__c
                    where Id=:deal.dealer__Service_Vehicle__c
                ];
                deal.dealer__Year__c            =   sv.dealer__Year__c;
                deal.dealer__Make__c            =   sv.dealer__Make__c;
                deal.dealer__Model__c          =   sv.dealer__Carline__c;
                if (String.isBlank(deal.dealer__Exterior_Color__c) || (deal.dealer__VIN__c!=sv.dealer__VIN__c)) deal.dealer__Exterior_Color__c = sv.dealer__Ext_Color__c;   // BLL65a, BLL69c
                deal.dealer__VIN__c          =   sv.dealer__VIN__c;
                // BLL69a
                if (sv.dealer__Ext_Color__c!=deal.dealer__Exterior_Color__c && !String.isBlank(deal.dealer__Exterior_Color__c)) {
                    if (sv.dealer__Sales_Inventory__c!=null) update(new dealer__Vehicle_Inventory__c(Id=sv.dealer__Sales_Inventory__c, dealer__Exterior_Color__c=deal.dealer__Exterior_Color__c));
                    update(new dealer__Service_Vehicle__c(Id=sv.Id, dealer__Ext_Color__c=deal.dealer__Exterior_Color__c));
                }
                // BLL69a end
            } catch(Exception e) {}
        }
        // BLL58a end
        
        // BLL63a
        if (deal.Contract_Type__c!=null && deal.Funding_option__c=='Financed') FinancialInstitutionDefaults();  // BLL72c
        if (deal.Funding_option__c=='Cash') deal.LeaseAcquisitionFee__c=null;   // BLL72a
        if (deal.Funding_option__c=='Cash') deal.LoanAcquisitionCost__c=null;   // BLL72a
        // BLL63a end

        // BLL52a
        if (!validateProposal()) {
        	System.debug('validateProposal found errors');
            return null;
        }
        // BLL52a end

        // BLL13a - recalc taxes
        boolean saveTaxDetail = false;
        if (dealTaxation!=null && dealTaxation.AutomaticCalc==true) {
            dealTaxation = null; // force review
            try {
                if (getNeedToRecalcTax()==true) {
                    calcTax(); 
                    saveTaxDetail = true;
                }
            } catch(Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            }
        }
        // BLL13a end

        // Tax override?, tax on cost reduction if using monthly tax pmts BLL63a
        // SalesTaxOverrideAmt__c, SalesTaxOverrideReason__c
        if (deal.SalesTaxOverrideAmt__c!=null && deal.SalesTaxOverrideAmt__c>=0 && !String.isBlank(deal.SalesTaxOverrideReason__c)
            && deal.SalesTaxOverrideBasis__c>=0) {
            deal.dealer__Sales_Tax__c = deal.SalesTaxOverrideAmt__c;
        }
        // BLL63a end

		calcGPSharing(deal, vehicle);	// BLL80a

        // BLL52a - run calcs here (also run in trigger, but we need the updated values?)
        List<dealer__Deal__c> deallist = new List<dealer__Deal__c>();
        Map<id,dealer__Deal__c> dealmap = new Map<Id,dealer__Deal__c>();
        deallist.add(deal);
        if (deal.id!=null) dealmap.put(deal.id, deal);
        DealProcess dp = new DealProcess(deallist, dealmap);
        dp.ProposalCalculations();
        // BLL52a end

        // BLL15a drop-down should change record type
        //BLL52d if (deal.dealer__Deal_Type__c!=recordTypeName && deal.dealer__Deal_Type__c!=recordTypeLabel
        //BLL52d    && !String.isBlank(deal.dealer__Status__c) && deal.dealer__Status__c!='Pending') {
        //BLL52d    throw new DealException('Can only change proposal type when in Pending status');
        //BLL52d }
        // BLL52d - separate type (Chassis/Conversion, Equipment, F&I, NVE, Wholesale) from record type (Commercial, Retail)
        //BLL52d if (deal.dealer__Deal_Type__c!=null) { 
        //BLL52d    for(RecordType r : recordTypes) {
        //BLL52d        if (deal.dealer__Deal_Type__c==r.Name || deal.dealer__Deal_Type__c==r.DeveloperName) {
        //BLL52d            deal.RecordTypeId = r.Id;
        //BLL52d             recordTypeName=r.DeveloperName;
        //BLL52d             recordTypeLabel=r.Name;
        //BLL52d        }
        //BLL52d    }
        //BLL52d }
        // BLL15a end

        // BLL52a - store flags of vehicle commerical options to NOT print with proposal
        if (vehicle!=null && deal.dealer__Vehicle__c!=null) deal.VehOptionsNotPrinted__c = getVehOptionsPrintFlag(vehicle);
        else deal.VehOptionsNotPrinted__c = null;
        // BLL52a end

        setServiceODO(); // BLL17a
        //BLL62d deal.ServiceContract1__c = soldOnProposalSC.size()>0 ? 1 : 0; // BLL23a
        deal.ServiceContract1__c = soldOnProposal.size()>0 ? 1 : 0; // BLL62a
		// BLL98
		boolean isnew = deal.Id==null;
		// BLL98 end

        try {

            if(deal.Id==null) {
                // BLL52a - default in fees from location object?
				// BLL105 - wholesale (unconverted sales) do not automatically charge doc fees
                //if (location!=null && location.DftChassisFees__c==true && recordTypeName!='Commercial' && (deal.dealer__Deal_Type__c=='Chassis/Conversion' || deal.dealer__Deal_Type__c=='Wholesale')) setDefaultFees();    
				if (location!=null && location.DftChassisFees__c==true && recordTypeName!='Commercial' && (deal.dealer__Deal_Type__c=='Chassis/Conversion')) setDefaultFees();    
				// BLL105 end
                // BLL52a - end
                retailDefaults = RetailDefaults__c.getOrgDefaults();    // BLL35a
                deal.dealer__Deal_ID__c = String.valueOf(Integer.valueOf(retailDefaults.ProposalNumber__c));
                deal.Name = deal.dealer__Deal_ID__c;
                if (RecordTypeName=='Commercial') deal.Name = 'Q' + deal.dealer__Deal_ID__c;    // BLL52a
                retailDefaults.ProposalNumber__c++;
                update retailDefaults;
                insert deal;
            } else {

                // Get System Calculated Gross Values
                deal.Total_Additional_Equipment__c = afterMarketTotal;
                deal.TotalAdditionalEquipLabor__c = afterMarketLbrTotal;    // BLL30a

                // BLL52a - preserve some fields (dealer__Status__c)!
                List<dealer__Deal__c> saveflds = [select dealer__Status__c from dealer__Deal__c where Id=:deal.Id];
                if (saveflds.size()>0) {
                    System.debug('Preserve status ' + saveflds[0].dealer__Status__c + ' (' + deal.dealer__Status__c + ')');
                    if (deal.dealer__Status__c!='Lost') deal.dealer__Status__c = saveflds[0].dealer__Status__c;
                }
                // BLL52a

                // BLL49a - record timestamp - used to ensure proposal was saved to
                // reflect any changes in GP prior to being marked as Delivered.
                deal.LastSavedDT__c = Datetime.now();
                
                update deal;
            }

            // BLL57a - attach quote if not yet attached
            if (deal.Commercial_Quote__c!=null && oem==null) {
                try { update(new CommercialQuote__c(Id=deal.Commercial_Quote__c,Proposal__c=deal.Id)); }
                catch(Exception e) {}
            }
            // BLL57a
            // BLL63a - update conversion build's VIN if it changed & only if there's only 1 non-lost proposal for it
            if (oem!=null && oem.Proposals__r.size()==1 && oem.Proposal__c==deal.Id) {
                if (oem.VIN__c!=deal.dealer__VIN__c || oem.UnitNumber__c!=deal.dealer__Stock_Number__c || oem.VehicleInventory__c!=deal.dealer__Vehicle__c ) {
                    try {
                        update(new CommercialQuote__c(Id=oem.Id, VIN__c=deal.dealer__VIN__c, UnitNumber__c=deal.dealer__Stock_Number__c, VehicleInventory__c=deal.dealer__Vehicle__c ));
                    } catch(Exception e) {}
                }
            }
            // BLL63a end

            // Save Related Data - Buyer, Co-Buyer, Etc.
            if(deal.dealer__Buyer__c!=null) saveBuyerFields();
            if(deal.dealer__Co_Buyer__c!=null) saveCoBuyerFields();
            if(deal.dealer__Vehicle__c!=null) setAssociatedVehicle(deal.dealer__Vehicle__c);

        } catch(Exception e) {  // BLL52a was DmlException
            ApexPages.addMessages(e);
            autoSaveDeal = false;   // BLL52a
            return null;    
        }

        // BLL13a 
        if (saveTaxDetail==true && dealTaxation!=null) {
            dealTaxation.saveDealTaxDetail();
        }
        // BLL13a end

        totalAftermarketItems();

		PageReference cq = self; // BLL52c Page.quotemanager;
        cq.getParameters().put('id', deal.Id);
        cq.setRedirect(true);
        // BLL98
		if (isnew) {
			ApexPages.StandardController sc = new ApexPages.StandardController(deal);
			cq = sc.view();
			cq.setRedirect(true);
		}
		// BLL98 end
        return cq;    
    }


    // BLL47a

	// BLL84a
	public Decimal nullaszero(Decimal amt) {
		return amt==null ? 0.00 : amt;
	}
	// BLL84a end

    // BLL52a
    // ValidateProposal - perform basic validations prior to save
    public boolean validateProposal() {
    	System.debug('validateProposal');
        boolean rtn = true;
        
        // Retail Chassis/Conversion, Equipment Only, DME/Other require an appointment
        if (RecordTypeName!='Commercial' && deal.dealer__Deal_Type__c!='Financial Products' && deal.dealer__Deal_Type__c!='DME/Other'
            && sup.dealer__First_Store_Visit_Date__c==null && sup.dealer__Lead_Status__c!='Quote') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must have a confirmed and shown appointment before creating a proposal.'));
            rtn = false;
        }
        
        // Customer owned vehicle never uses a releasing dealer
        if (deal.Vehicle_Source__c=='Customer Owned' && deal.ReleasingDealer__c!=null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Customer Owned chassis cannot use a Releasing Dealer.'));
            rtn = false;
        }
        
        // Releasing dealer must match inventory record *if* inventory record specifies the releasing dealer
        if (vehicle!=null && vehicle.Releasing_Dealer__c!=null && deal.ReleasingDealer__c!=null && vehicle.Releasing_Dealer__c!=deal.ReleasingDealer__c) {
            if (RecordTypeName=='Commercial') {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Vehicle Inventory releasing dealer does not match proposal\'s releasing dealer.'));
                rtn = false;
            }
        }
        
        // BLL63a
        //if (deal.LeaseAcquisitionFee__c==null && dealTaxation!=null && dealTaxation.getLeaseSalesTaxInPmt()=='Require') {
        //  ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Vehicle registration state requires sales tax with lease pmt.'));
        //  rtn = false;
        //}
        if (deal.SalesTaxOverrideAmt__c!=null && deal.SalesTaxOverrideAmt__c<0) {
            deal.SalesTaxOverrideAmt__c = null;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'You cannot use the manual tax override to set the tax to less than $0'));
            rtn = false;
        }
        // Commercial where customer pays will be $0
        //if (deal.SalesTaxOverrideAmt__c!=null && deal.SalesTaxOverrideAmt__c==0 && deal.Contract_Type__c!='Lease') {
        //    deal.SalesTaxOverrideAmt__c = null;
        //    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'You cannot override taxes to $0 except on a lease'));
        //    rtn = false;
        //}
        if (deal.SalesTaxOverrideAmt__c!=null && (String.isBlank(deal.SalesTaxOverrideReason__c) || deal.SalesTaxOverrideBasis__c==null)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must provide the tax bases and an explanation why you are overriding the sales tax'));
            rtn = false;
        }
        // BLL63a end

        // require loan/lease acquisition cost/fee  - BLL68a
        if (deal.Funding_option__c=='Financed' && deal.dealer__Status__c!=null && deal.dealer__Status__c.startsWith('Won')) {   // BLL72a, BLL80c
			// BLL87
            // if (fia!=null && deal.Contract_Type__c=='Loan' && fia.ChargesAcquisitionFee__c==true && deal.LoanAcquisitionCost__c==null) {
            //     ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Loan acquisition cost is required for ' + fia.Name));
            //     rtn = false;
            // }
            // if (fia!=null && deal.Contract_Type__c=='Lease' && fia.ChargesAcquisitionFee__c==true && deal.LeaseAcquisitionFee__c==null) {	// BLL80c 
            //     ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Lease acquisition fee is required for ' + fia.Name));
            //     rtn = false;
            //}
			// BLL100
            //if (fia!=null && deal.Contract_Type__c!=null && fia.ChargesAcquisitionFee__c==true && deal.LoanAcquisitionCost__c==null && deal.LeaseAcquisitionFee__c==null) {
            if (fia!=null && deal.Contract_Type__c!=null && fia.ChargesAcquisitionFee__c==true && deal.LoanAcquisitionCost__c==null && deal.LeaseAcquisitionFee__c==null && deal.ESC_Loan_Cost__C==null) {
			// BLL100 end
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Acquisition cost or fee is required for ' + fia.Name));
                rtn = false;
            }
			// BLL87 end
        }   // BLL72a
        // BLL68a end

        // BLL71a - reactivate the validation - it was already fixed to check record types - don't allow commercial vehicle
        MW_TriggerControls__c NoCommVehOnDeal = MW_TriggerControls__c.getInstance('NoCommVehOnDeal');
        if (NoCommVehOnDeal == null || NoCommVehOnDeal.Enabled__c) { 
            if (vehicle!=null && vehicle.Division__c=='Commercial' && RecordTypeName!='Commercial' && deal.dealer__Status__c!='Won - Posted') { // BLL52c RecordTypeName
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You cannot sell a commercial vehicle (' + vehicle.Name + ') using a retail proposal. Vehicle has been removed.'));
				// BLL93
                //deal.dealer__Vehicle__c = null;
				removeVehicleBeforeSave();
				// BLL93 end
                vehicle = null;
                rtn = false;
            }
        }
        // And no retail veh on commercial proposal
        if (NoCommVehOnDeal == null || NoCommVehOnDeal.Enabled__c) { 
            if (vehicle!=null && vehicle.Division__c!='Commercial' && RecordTypeName=='Commercial' && deal.dealer__Status__c!='Won - Posted') { // BLL52c RecordTypeName
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You cannot sell a consumer/retail vehicle (' + vehicle.Name + ') using a commercial proposal. Vehicle has been removed.'));
				// BLL93
                // deal.dealer__Vehicle__c = null;
				removeVehicleBeforeSave();
				// BLL93 end
                vehicle = null;
                rtn = false;
            }
        }
        // BLL71a end

		// BLL83a
		System.debug(deal.dealer__Rebate__c);
		System.debug(deal.Rebate_Description__c);
        if (deal.dealer__Rebate__c!=null && deal.dealer__Rebate__c!=0 && String.isBlank(deal.Rebate_Description__c)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must provide a rebate 1 description to use the rebate 1 amount'));
            rtn = false;
        }
		System.debug(deal.Rebate_2__c);
		System.debug(deal.Rebate_2_Description__c);
        if (deal.Rebate_2__c!=null && deal.Rebate_2__c!=0 && String.isBlank(deal.Rebate_2_Description__c)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must provide a rebate 2 description to use the rebate 2 amount'));
            rtn = false;
        }
		System.debug(deal.Rebate_3__c);
		System.debug(deal.Rebate_3_Description__c);
        if (deal.Rebate_3__c!=null && deal.Rebate_3__c!=0 && String.isBlank(deal.Rebate_3_Description__c)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must provide a rebate 3 description to use the rebate 3 amount'));
            rtn = false;
        }
		// BLL83a end
	
        return rtn;
    }
    public String getLeaseSalesTaxMethod() {
        return dealTaxation.getLeaseTaxMethod();    //TaxRuleSetting__c.Lease_sales_tax_method__c;
    }
    // BLL52a end

/** BLL95 to delete **/    
    // MemberOfFIteam()
    public boolean getMemberOfFIteam() {
        Map<Id,Group> groupmap = Utility.MemberOfGroups(UserInfo.getUserId());
        for(Group g : groupmap.values()) if (g.Name=='F&I Team (MW)') return true;
        return false;
    }
    
    // saveFandI
    // routine uses "god" mode to get around the fact that the proposal may be locked 
    // in an approval process.
    public PageReference btnSaveFandI() {
    	// validations first	
    	boolean valid = true;	// BLL80a
    	// BLL80a copied in from proposal save
        // require loan/lease acquisition cost/fee  - BLL68a
        if (deal.Funding_option__c=='Financed' && deal.dealer__Status__c!=null && deal.dealer__Status__c.startsWith('Won')) {   // BLL72a, BLL80c
			// BLL87
            // if (fia!=null && deal.Contract_Type__c=='Loan' && fia.ChargesAcquisitionFee__c==true && deal.LoanAcquisitionCost__c==null) {
            //     ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Loan acquisition cost is required for ' + fia.Name));
            //     valid = false;
            // }
            // if (fia!=null && deal.Contract_Type__c=='Lease' && fia.ChargesAcquisitionFee__c==true && deal.LeaseAcquisitionFee__c==null) {	// BLL80c 
            //     ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Lease acquisition fee is required for ' + fia.Name));
            //     valid = false;
            // }
			// BLL100
            //if (fia!=null && deal.Contract_Type__c!=null && fia.ChargesAcquisitionFee__c==true && deal.LoanAcquisitionCost__c==null && deal.LeaseAcquisitionFee__c==null) {
            if (fia!=null && deal.Contract_Type__c!=null && fia.ChargesAcquisitionFee__c==true && deal.LoanAcquisitionCost__c==null && deal.LeaseAcquisitionFee__c==null && deal.ESC_Loan_Cost__c==null) {
			// BLL100
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Acquisition cost or fee is required for ' + fia.Name));
                valid = false;
            }
			// BLL87 end
        }   // BLL72a
        // BLL68a end
    	
        if (valid) saveFandI();	// BLL80c
        return null;
    }
    
	public boolean saveFandI() {
        boolean okay = true;
        if (deal.dealer__F_I_Manager__c==null) deal.dealer__F_I_Manager__c = UserInfo.getUserId();
        if (deal.Contract_Status__c=='Approved' && deal.dealer__Finance_Institution_Account__c==null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Financial Institution is required for an approved loan or lease'));
            okay = false;
        }
        if (okay) Deal_UpdateControl.updateFandIData(deal);
        return okay;
    }
	
    public PageReference applicationReceived() {
        PageReference pg = null;
        //pg = ApexPages.currentPage();
        //pg.getParameters().put('id',deal.id);
        //pg.setRedirect(true);
        if (deal.Credit_Application_Received__c==null) deal.Credit_Application_Received__c = DateTime.now();
        if (deal.dealer__F_I_Manager__c==null) deal.dealer__F_I_Manager__c = UserInfo.getUserId();
        deal.Contract_Status__c = 'Application Received';
        saveFandI();
        return pg;
    }
	
    public PageReference applicationBackToStore() {
        PageReference pg = null;
        //pg = ApexPages.currentPage();
        //pg.getParameters().put('id',deal.id);
        //pg.setRedirect(true);
        if (deal.Credit_BackToStore__c==null) deal.Credit_BackToStore__c = DateTime.now();
        if (deal.dealer__F_I_Manager__c==null) deal.dealer__F_I_Manager__c = UserInfo.getUserId();
        deal.Contract_Status__c = 'Pending Store Action';
        if (saveFandI()) Utility.ProcessApprovalStep(deal.Id, 'Reject', new Set<String>{'F&I Approval'}, 'Sent back to the store');
        // else pg=null;
        return pg;
    }
	
    public PageReference applicationApproved() {
        PageReference pg = null;
        //pg = ApexPages.currentPage();
        //pg.getParameters().put('id',deal.id);
        //pg.setRedirect(true);
        if (deal.Credit_Decision_Received__c==null) deal.Credit_Decision_Received__c = DateTime.now();
        if (deal.dealer__F_I_Manager__c==null) deal.dealer__F_I_Manager__c = UserInfo.getUserId();
        deal.Contract_Status__c = 'Approved';
        if (saveFandI()) Utility.ProcessApprovalStep(deal.Id, 'Approve', new Set<String>{'F&I Approval'}, 'Financing approved');
        else pg = null;
        return pg;
    }
	
    public PageReference applicationRejected() {
        PageReference pg = null;
        //pg = ApexPages.currentPage();
        //pg.getParameters().put('id',deal.id);
        //pg.setRedirect(true);
        if (deal.Credit_Decision_Received__c==null) deal.Credit_Decision_Received__c = DateTime.now();
        if (deal.dealer__F_I_Manager__c==null) deal.dealer__F_I_Manager__c = UserInfo.getUserId();
        deal.Contract_Status__c = 'Declined';
        if (saveFandI()) Utility.ProcessApprovalStep(deal.Id, 'Reject', new Set<String>{'F&I Approval'}, 'Financing denied');
        // else pg = null;
        return pg;
    }
    // BLL47a end
/** BLL95 end of to delete **/

    public void saveBuyerFields() {
        //Account 
        //BLL38d Account a = [Select Id, isPersonAccount from Account where Id=:deal.dealer__Buyer__c limit 1];  // BLL7c add isPersonAccount
        //BLL38d if (a.isPersonAccount) {  // BLL7a
        //BLL38d     a.PersonHomePhone   =   deal.dealer__Buyer_Home_Phone__c;
        //BLL38d     a.PersonMobilePhone =   deal.dealer__Buyer_Mobile_Phone__c;
        //BLL38d     a.PersonOtherPhone  =   deal.dealer__Buyer_Work_Phone__c;
        //BLL38d     a.PersonEmail     =   deal.dealer__Buyer_Email__c;
        //BLL38d     a.PersonMailingStreet     =   deal.dealer__Buyer_Address__c;
        //BLL38d     a.PersonMailingCity         =   deal.dealer__Buyer_City__c;
        //BLL38d     a.PersonMailingCounty__c   =   deal.dealer__Buyer_County__c;
        //BLL38d     a.PersonMailingState       =   deal.dealer__Buyer_State__c;
        //BLL38d     a.PersonMailingPostalCode   =   deal.dealer__Buyer_Postal_Code__c;
        //BLL38d     update a;
        //BLL38d } // BLL7a
        // BLL39a
        Account a = [Select Id, isPersonAccount, PersonMailingCounty__c, Market_Segment__c from Account where Id=:deal.dealer__Buyer__c limit 1];
        boolean updateAcct = false;
        if (a.isPersonAccount) {
            if (!String.isBlank(deal.dealer__Buyer_County__c) && a.PersonMailingCounty__c!=deal.dealer__Buyer_County__c) { updateAcct=true; a.PersonMailingCounty__c=deal.dealer__Buyer_County__c; }    // BLL74c
        }
        // BLL75a
        if (recordTypeName=='Commercial') {
            //BLL97
			//if (deal.Market_Segment__c!=null && deal.dealer__Status__c!=null && deal.dealer__Status__c.startsWith('Won')) {  updateAcct=true; a.Market_Segment__c = deal.Market_Segment__c; }   // BLL75a
			if (deal.Market_Segment__c!=null && deal.dealer__Status__c!=null) {  updateAcct=true; a.Market_Segment__c = deal.Market_Segment__c; } 
			// BLL97 end
        }
        // BLL75a
        if (updateAcct) update(a);
        // BLL39a
        // BLL38a
        // Solution Opportunity
        if (deal.dealer__Sales_Lead__c!=null) {
            boolean updateSLOP = false;
            dealer__Sales_Up__c solopp = [
                select Id, Name, dealer__Mailing_Street__c, dealer__Mailing_City__c, dealer__Mailing_State__c, dealer__Mailing_Zip__c,
                    dealer__Phone__c, dealer__Mobile__c, dealer__Email__c
                from dealer__Sales_Up__c
                where Id=:deal.dealer__Sales_Lead__c
            ];
            if (solopp.dealer__Mailing_Street__c != deal.dealer__Buyer_Address__c) { updateSLOP=true; solopp.dealer__Mailing_Street__c = deal.dealer__Buyer_Address__c; }
            if (solopp.dealer__Mailing_City__c != deal.dealer__Buyer_City__c) { updateSLOP=true; solopp.dealer__Mailing_City__c = deal.dealer__Buyer_City__c; }
            if (solopp.dealer__Mailing_State__c != deal.dealer__Buyer_State__c) {updateSLOP=true; solopp.dealer__Mailing_State__c = deal.dealer__Buyer_State__c; }
            if (solopp.dealer__Mailing_Zip__c != deal.dealer__Buyer_Postal_Code__c) {updateSLOP=true; solopp.dealer__Mailing_Zip__c = deal.dealer__Buyer_Postal_Code__c; }
            if (solopp.dealer__Phone__c != deal.dealer__Buyer_Home_Phone__c && deal.dealer__Buyer_Home_Phone__c!=null) {updateSLOP=true; solopp.dealer__Phone__c = deal.dealer__Buyer_Home_Phone__c; }
            if (solopp.dealer__Mobile__c != deal.dealer__Buyer_Mobile_Phone__c && deal.dealer__Buyer_Mobile_Phone__c!=null) {updateSLOP=true; solopp.dealer__Mobile__c = deal.dealer__Buyer_Mobile_Phone__c; }
            if (solopp.dealer__Email__c != deal.dealer__Buyer_Email__c && deal.dealer__Buyer_Email__c!=null) {updateSLOP=true; solopp.dealer__Email__c = deal.dealer__Buyer_Email__c; } 
            if (updateSLOP) update(solopp);
        }
        // BLL38a
    }

    public void saveCoBuyerFields() {
        Account a = [select Id, isPersonAccount, PersonHomePhone,PersonMobilePhone, PersonEmail, PersonMailingStreet,
            PersonMailingCity, PersonMailingCounty__c, PersonMailingState, PersonMailingPostalCode
          from Account where Id=:deal.dealer__Co_Buyer__c limit 1];  // BLL7c add isPersonAccount
        if (a.isPersonAccount) {  // BLL7a
            boolean updateAcct = false; // BLL39a
            // BLL39c added conditions & flag to update only if changed!
            if (a.PersonHomePhone!=deal.dealer__Co_Buyer_Home_Phone__c) { updateAcct=true; a.PersonHomePhone   =   deal.dealer__Co_Buyer_Home_Phone__c; }
            if (a.PersonMobilePhone!=deal.dealer__Co_Buyer_Mobile_Phone__c) { updateAcct=true; a.PersonMobilePhone =   deal.dealer__Co_Buyer_Mobile_Phone__c; }
            if (a.PersonEmail!=deal.dealer__Co_Buyer_Email__c) { updateAcct=true; a.PersonEmail    =   deal.dealer__Co_Buyer_Email__c; }
            if (a.PersonMailingStreet!=deal.dealer__Co_Buyer_Address__c) { updateAcct=true; a.PersonMailingStreet      =   deal.dealer__Co_Buyer_Address__c; }
            if (a.PersonMailingCity!=deal.dealer__Co_Buyer_City__c) { updateAcct=true; a.PersonMailingCity       =   deal.dealer__Co_Buyer_City__c; }
            if (a.PersonMailingCounty__c!=deal.dealer__Co_Buyer_County__c) { updateAcct=true; a.PersonMailingCounty__c  =   deal.dealer__Co_Buyer_County__c; }
            if (a.PersonMailingState!=deal.dealer__Co_Buyer_State__c) { updateAcct=true; a.PersonMailingState       =   deal.dealer__Co_Buyer_State__c; }
            if (a.PersonMailingPostalCode!=deal.dealer__Co_Buyer_Postal_Code__c) { updateAcct=true; a.PersonMailingPostalCode   =   deal.dealer__Co_Buyer_Postal_Code__c; }
            if (updateAcct) update a;
        } // BLL7a
    }

    public PageReference navigateAdvancedSearch() {
        //BLL52d PageReference p = Page.VehicleSearchAdvanced;
        //BLL52d p.getParameters().put('proposalId', deal.Id);
        //BLL52d p.setRedirect(true);
        //BLL52d return p;
        try {
            saveProposal();
        } catch(Exception e) {}     // ignore -- it wasn't saving before anyway
        vehsearch.getParameters().put('proposalId', deal.Id);
        if (recordTypeName=='Commercial') vehsearch.getParameters().put('division','Commercial');   // BLL52a
        else vehsearch.getParameters().remove('division');  // BLL52a
        vehsearch.setRedirect(true);
        return vehsearch;
    }


    // BLL52a
    // Save & restore a string of comma-separated Ids in the deal object indicating which vehicle options
    // should not print (because they're being removed and/or replaced at the store with the commercial proposal)
    private void setVehOptionsPrintFlag(dealer__Vehicle_Inventory__c v, String donotprint) {
        Set<String> doNotPrintIds = new Set<String>();
        if (!String.isBlank(donotprint)) doNotPrintIds.addAll(donotprint.split(','));
        for(VehicleInventory_CommercialOption__c vico : v.Vehicle_Commercial_Options__r) vico.Flag1__c = !doNotPrintIds.contains(vico.Id);      
    }
    
    private String getVehOptionsPrintFlag(dealer__Vehicle_Inventory__c v) {
        String rtnIdList = '';
        List<String> doNotPrintIds = new List<String>();
        for(VehicleInventory_CommercialOption__c vico : v.Vehicle_Commercial_Options__r) if (!vico.Flag1__c) doNotPrintIds.add(vico.Id);
        rtnIdList = String.join(doNotPrintIds, ',');
        return rtnIdList;
    }
    // BLL52a end

    public void setAssociatedVehicle(String vehicleId) {
            boolean saveVeh = false;    // BLL52a
            System.debug('*** setAssociatedVehicle *** ' + vehicleId);
            // BLL22a add ChassisMSRP__c, ConversionMSRP__c,
            // BLL29c add division__c
            // BLL65c add dealer__Year__c, dealer__Make__c, dealer__Model__c, dealer__Pack__c, dealer__Exterior_Color__c,
            // BLL52a, BLL82a add Releasing_Dealer__c, PriorRental__c,
            // BLL52a add subselect Vehicle_Commercial_Options__r 
            // BLL76a add HomeLocation__c, HomeLocation__r.Name, dealer__Inventory_Date__c, Source__c,
            // BLL76a add related dealerTrades
            Id locationId = location!=null ? location.Id : null;    // BLL86a
            dealer__Vehicle_Inventory__c v = [
                Select Id, Name, dealer__Mileage__c, dealer__Vehicle_Cost__c, Conversion_Cost__c, 
                    dealer__Purchase_Price__c, dealer__Retail_Price__c, Suggested_Retail_Price__c, SuggestedRetailPrice__c, 
                    dealer__Year__c, dealer__Make__c, dealer__Model__c, dealer__Pack__c, dealer__Exterior_Color__c,     
                    dealer__Work_in_Process__c, Conversion__c, dealer__Status_Code__c, 
                    ChassisMSRP__c, ConversionMSRP__c,
					New_Used_Other__c, // BLL103a
                    dealer__Stock_Number__c, dealer__VIN__c, Division__c,  
                    Releasing_Dealer__c, PriorRental__c,   
                    HomeLocation__c, HomeLocation__r.Name, dealer__Inventory_Date__c, Source__c,    
                    ( select Id, Name, RequestedDate__c, dealer__Outbound_Location__c, dealer__Store_Location__c, dealer__Transfer_Status__c 
                      from dealer__Dealer_Trades__r
                      where dealer__Store_Location__c=:locationId
                        and dealer__Transfer_Status__c not in ('Not Submitted','Declined')
                      order by RequestedDate__c desc
                    ),  
                    ( select Id, Name, Quantity__c, CommercialQuoteOption__c, Description__c, OptionType__c, Flag1__c, ExtendedPrice__c  
                      from Vehicle_Commercial_Options__r 
                      where OptionType__c<>'Chassis Options'
                      order by SectionSequence__c 
                    )
                From dealer__Vehicle_Inventory__c
                where Id =:vehicleId
                Limit 1
            ];

            System.debug(deal.Chassis_Cost__c);
            System.debug(deal.Chassis_Price__c);
            System.debug(deal.Conversion_Cost__c);
            System.debug(deal.Conversion_Price__c);
            System.debug(deal.dealer__Sale_Price__c);
            System.debug(v.Conversion_Cost__c);
            System.debug(v.dealer__Vehicle_Cost__c);
            System.debug(v.ChassisMSRP__c);
            System.debug(v.ConversionMSRP__c);

            //BLL52d // BLL29a - don't allow commercial vehicle
            //BLL52d MW_TriggerControls__c NoCommVehOnDeal = MW_TriggerControls__c.getInstance('NoCommVehOnDeal');
            //BLL52d if(NoCommVehOnDeal == null || NoCommVehOnDeal.Enabled__c) { 
            //BLL52d    if (v!=null && v.Division__c=='Commercial' && RecordTypeName!='Commercial' && deal.dealer__Status__c!='Won - Posted') { // BLL52c RecordTypeName
            //BLL52d        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You cannot sell a commercial vehicle (' + v.Name + ') using a retail proposal.'));
            //BLL52d        deal.dealer__Vehicle__c = null;
            //BLL52d        return;
            //BLL52d    }
            //BLL52d }
            //BLL52d // BLL29a end
            // BLL71 - re-activated the above in the "saveProposal" routine 

            System.debug(deal.dealer__Vehicle__c);  // BLL52a
            System.debug(v.Id); // BLL52a
            saveVeh = deal.dealer__Vehicle__c!=v.Id;    // BLL52a

            if(v.dealer__Vehicle_Cost__c==null) v.dealer__Vehicle_Cost__c=0;
            //BLL56d if(v.Conversion_Cost__c==null) v.Conversion_Cost__c=0;
            if(v.dealer__Pack__c==null) v.dealer__Pack__c=0;
            if(v.dealer__Mileage__c==null) v.dealer__Mileage__c=0;
            
            // BLL52a force some items to refresh when the vehicle changes on the proposal!
            System.debug(deal.Chassis_Price__c);    
            if (saveVeh) {
                System.debug('Reset chassis/conv costs and prices for vehicle');
                if (v.Conversion__c!=null) deal.Conversion_Description__c=null;
                deal.Chassis_Cost__c=null;
                //BLL55d deal.Chassis_Price__c=null;
                //BLL56d if (v.Conversion_Cost__c!=0) deal.Conversion_Cost__c=null; // BLL54c
                if (v.Conversion_Cost__c == null) deal.Conversion_Cost__c=null; // BLL56a
                deal.Conversion_Price__c=null;
                //BLL55d deal.dealer__Sale_Cost__c=null;
                if (v.dealer__Mileage__c!=null) deal.dealer__Mileage__c = v.dealer__Mileage__c;	// BLL79a
				deal.GP_Sharing_Date__c = null;	// BLL103
            }   
            System.debug(deal.Chassis_Price__c);    
            
            if(v.Conversion__c!=null && deal.Conversion_Description__c == null) {
                deal.Conversion_Description__c = [Select Id, Long_Description__c 
                                                    From dealer__Parts_Kit__c 
                                                    where Id=:v.Conversion__c limit 1].Long_Description__c;
            }                           

            // BLL52a
            String oemconversion = '';
            for(VehicleInventory_CommercialOption__c vico : v.Vehicle_Commercial_Options__r) {
                oemconversion += ((String.isBlank(oemconversion)) ? '' : '\n' )
                        + ((vico.Quantity__c>1) ? '('+String.valueOf(vico.Quantity__c)+')' : '')
                        + vico.Description__c;
            }
            if (String.isBlank(deal.Conversion_Description__c)) deal.Conversion_Description__c = oemconversion;
            // BLL52a end

            
            deal.dealer__Stock_Number__c = v.dealer__Stock_Number__c;
            System.debug(deal.dealer__Vehicle__c);  // BLL52a
            deal.dealer__Vehicle__c =   v.Id;
            if(deal.dealer__Vehicle__r.Name!=null)  deal.dealer__Vehicle__r.Name    =   v.Name;

            if(deal.dealer__Mileage__c == null) deal.dealer__Mileage__c  =  v.dealer__Mileage__c;

            // BLL52a Message that vehicle chassis cost has changed
            if (!saveVeh && v.dealer__Vehicle_Cost__c!=null && v.dealer__Vehicle_Cost__c!=0 && v.dealer__Vehicle_Cost__c!=deal.Chassis_Cost__c) 
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Vehicle costs changed and have updated your proposal chassis cost'));
            // BLL52a end

            if(v.dealer__Vehicle_Cost__c!=null && v.dealer__Vehicle_Cost__c!=0) deal.Chassis_Cost__c = v.dealer__Vehicle_Cost__c;
            if(deal.Chassis_Price__c == null) { // BLL19d  || deal.Chassis_Price__c == 0) {
                // BLL22d deal.Chassis_Price__c        =   v.dealer__Vehicle_Cost__c;
                deal.Chassis_Price__c = v.ChassisMSRP__c; // BLL22a
            }
            // BLL52a - if using a releasing dealer, set cost to match price - no per Jesse L. 3/15/2017
            // if (deal.ReleasingDealer__c!=null) deal.Chassis_Cost__c = deal.Chassis_Price__c;
            // BLL52a end
            //BLL56d if (v.Conversion_Cost__c>0) deal.Conversion_Cost__c = v.Conversion_Cost__c + v.dealer__Pack__c;    // BLL54c
            if (v.Conversion_Cost__c!=null) deal.Conversion_Cost__c = v.Conversion_Cost__c + v.dealer__Pack__c; // BLL56a

            // BLL6a  use suggested retail price initially
            if (deal.Chassis_Price__c==null) deal.Chassis_Price__c = 0.00;
            if (deal.dealer__Sale_Cost__c==null || deal.dealer__Sale_Cost__c==0.00) {
                deal.dealer__Sale_Cost__c = (v.SuggestedRetailPrice__c==null) ? 0.00 : v.SuggestedRetailPrice__c;
            }
            // BLL6a end

            System.debug(deal.Chassis_Cost__c);
            System.debug(deal.Chassis_Price__c);
            System.debug(deal.Conversion_Cost__c);
            System.debug(deal.Conversion_Price__c);
            System.debug(deal.dealer__Sale_Price__c);
            System.debug(v.Conversion_Cost__c);
            System.debug(v.dealer__Vehicle_Cost__c);
            System.debug(v.ChassisMSRP__c);
            System.debug(v.ConversionMSRP__c);

            // BLL9a
            if (deal.Conversion_Price__c==null || deal.Conversion_Price__c==0.00) { // BLL9a allow value to be overridden
            	// BLL84d 
                //if (deal.Conversion_Cost__c==null || deal.Conversion_Cost__c==0.00) { 
                //    deal.Conversion_Price__c = 0.00; 
                //} else if (deal.dealer__Sale_Cost__c >= deal.Chassis_Price__c) {  
                //    deal.Conversion_Price__c = deal.dealer__Sale_Cost__c - deal.Chassis_Price__c;
                //} else { 
                //    // BLL22d deal.Conversion_Price__c = v.Conversion_Cost__c + 8500;
                //    deal.Conversion_Price__c = v.ConversionMSRP__c; // BLL22a 
                //} 
                // BLL84d end
                // BLL84a some vehicles have full cost on chassis only with a conversion & conversion msrp
               	if (saveVeh && v.ConversionMSRP__c!=null && v.ConversionMSRP__c!=0.00) {
               		deal.Conversion_Price__c = v.ConversionMSRP__c;
               	} else if (deal.Conversion_Cost__c==null || deal.Conversion_Cost__c==0.00) {
               		deal.Conversion_Price__c = 0.00;
               	} else if (deal.dealer__Sale_Cost__c >= deal.Chassis_Price__c) {
               		deal.Conversion_Price__c = deal.dealer__Sale_Cost__c - deal.Chassis_Price__c;
               	}
                // BLL84a end
            } 
            // BLL9a - end
            // BLL9d begin
            //if((deal.Conversion_Price__c == null || deal.Conversion_Price__c == 0)) {
            //  deal.Conversion_Price__c        =   v.Conversion_Cost__c + 8500;
            //}
            // BLL9d end
            if (deal.Chassis_Price__c==null) deal.Chassis_Price__c = 0.00;  // BLL33a
            if (deal.Conversion_Price__c==null) deal.Conversion_Price__c = 0.00;    // BLL33a

            deal.dealer__Sale_Cost__c      =   deal.Chassis_Price__c + deal.Conversion_Price__c;

            if(location!=null && location.PackLocal__c==null) location.PackLocal__c=0;

            if(deal.Pack__c == null && location!=null) {      // To-Do Future : Pack can only be overridden by the GM or Higher
                deal.Pack__c                    =   location.PackLocal__c;  
                if (RecordTypeName=='Commercial') deal.Pack__c = 0; // BLL52a
                if (deal.dealer__Deal_Type__c=='Wholesale') deal.Pack__c = null;    // BLL52a
                if (!isVehicleSale) deal.Pack__c = null;    // BLL86a
            }
			// BLL93
			if (deal.dealer__Deal_Type__c=='Wholesale') deal.Conversion_Discount__c = 0.00;
			// BLL93 end

            deal.Total_Internal_Local_Equipment__c  =   Deal_MBW2.equipmentCost(deal.Id);
            deal.Total_Additional_Equipment__c    =   Deal_MBW2.equipmentSale(deal.Id);
            deal.TotalAdditionalEquipLabor__c       =   Deal_MBW2.equipmentLabor(deal.Id);  // BLL30a 
            
            deal.Warranty_Cost__c                  =   Deal_MBW2.serviceContractCost(deal.Id);
            deal.Total_Protection_Products__c      =   Deal_MBW2.serviceContractSale(deal.Id);

            deal.dealer__Year__c            =   v.dealer__Year__c;
            deal.dealer__Make__c            =   v.dealer__Make__c;
            deal.dealer__Model__c          =   v.dealer__Model__c;
            deal.dealer__VIN__c          =   v.dealer__VIN__c;
            if (!String.isBlank(v.dealer__Exterior_Color__c)) deal.dealer__Exterior_Color__c = v.dealer__Exterior_Color__c; // BLL65a
            if (deal.Vehicle_Source__c!='Customer Owned' && deal.ReleasingDealer__c==null && v.Releasing_Dealer__c!=null) deal.ReleasingDealer__c=v.Releasing_Dealer__c;    // BLL52a
            // BLL79a non-commercial deals don't use releasing dealers
            if (recordTypeName!='Commercial') deal.ReleasingDealer__c = null;	// BLL79a
            
            if (saveVeh) autoSaveDeal = true;   // BLL52a

            Deal_MBW2.calcGPSharing(deal, v);   // BLL76a

            //System.debug(deal.Chassis_Cost__c);
            //System.debug(deal.Chassis_Price__c);
            //System.debug(deal.Conversion_Cost__c);
            //System.debug(deal.Conversion_Price__c);
            //System.debug(deal.dealer__Sale_Price__c);
    }

    // calcGPSharing - BLL76a
    public static void calcGPSharing(dealer__Deal__c d, dealer__Vehicle_Inventory__c v) {
		// BLL103
		Set<String> GPSharingDealVehSource = new Set<String>{'Inventory'};
		Set<String> GPSharingVehicleNUO = new Set<String>{'Used'};	// BLL103a

		// BLL103
        // dealer__Deal__c requires: dealer__Status__c, GP_Sharing_Amount__c, GP_Sharing_Date, GP_Sharing_Location__c
        // dealer__Vehicle_Inventory__c requries: dealer__Inventory_Date__c, HomeLocation__c
        //                           dealer__Dealer_Trades__r: RequestedDate__c, dealer__Transfer_Status__c, dealer__Store_Location__c
        List<String> IgnoreTransferStatus = new List<String>{'Not Submitted','Declined'};
        Set<String> GPSharingVehSource = new Set<String>{'Purchase','Trade','MBW Buyer', 'Order', 'Order - Sold'};	// Added Order & Order - Sold because of rentals

		System.debug(d.RecordTypeId);
		Map<Id,Schema.RecordTypeInfo> rtMapById = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosById();
		Schema.RecordTypeInfo rtinfo = rtMapById.get(d.RecordTypeId);
		System.debug(rtinfo);
		String recordTypeName = rtinfo.getName();
        
        System.debug(d.dealer__Status__c);
        if (d.dealer__Status__c!='Won - Posted' && d.dealer__Status__c!='Won - Delivered') {
			// only retail chassis/conversion sales out of stock
			// BLL99
			//if (recordTypeName!='Commercial' && (d.dealer__Deal_Type__c=='Chassis/Conversion' || d.dealer__Deal_Type__c=='Retail Vehicle Sale') 
			//	&& d.Vehicle_Source__c=='Inventory' && v!=null && v.PriorRental__c!=true) {	// BLL82c (prior rental)
			if (recordTypeName!='Commercial' && (d.dealer__Deal_Type__c=='Chassis/Conversion' || d.dealer__Deal_Type__c=='Retail Vehicle Sale') 
				&& v!=null && GPSharingVehicleNUO.contains(v.New_Used_Other__c) 	// BLL103a
				&& GPSharingDealVehSource.contains(d.Vehicle_Source__c) ) {
			// BLL99
	            d.GP_Sharing_Amount__c = null;
	            // Date refDate = d.GP_Sharing_Date__c;
	            Date refDate = null;
	            if (v!=null) System.debug(v.dealer__Inventory_Date__c);
	            if (v!=null && v.dealer__Inventory_Date__c!=null) {
					for(dealer__Dealer_Trade__c t : v.dealer__Dealer_Trades__r) {
						// following condition should have already been done in the dealer__Dealer_Trades__r soql ...
						if (t.dealer__Store_Location__c==d.dealer__Store_Location__c && !IgnoreTransferStatus.contains(t.dealer__Transfer_Status__c)) {
							if (refDate==null && t.RequestedDate__c!=null) {
								d.GP_Sharing_Date__c = t.RequestedDate__c;
								refDate = t.RequestedDate__c;
							}
						} else if (t.dealer__Transfer_Status__c=='Complete' && t.dealer__Store_Location__c!=d.dealer__Store_Location__c) refdate = Date.today();	// BLL77a
					}
	            	System.debug(refDate);
					if (refDate==null && d.GP_Sharing_Date__c!=null) refDate = d.GP_Sharing_Date__c;
	            	System.debug(refDate);
					if (refdate==null) refdate = Date.today();
   	             	System.debug(v.HomeLocation__c);
   	             	System.debug(d.dealer__Store_Location__c);
   	             	Integer daysathome = v.dealer__Inventory_Date__c.daysBetween(refDate);
   	             	System.debug(daysathome);
   	             	if (v.HomeLocation__c!=null && v.HomeLocation__c!=d.dealer__Store_Location__c && GPSharingVehSource.contains(v.Source__c)) {
   	                	if (daysathome<=30) d.GP_Sharing_Amount__c = 3000;
   	                	if (daysathome>30 && daysathome<=60) d.GP_Sharing_Amount__c = 2000;
                    	if (daysathome>60 && daysathome<=120) d.GP_Sharing_Amount__c = 0;
                    	if (daysathome>120 && daysathome<=180) d.GP_Sharing_Amount__c = -1000;
                    	if (daysathome>180) d.GP_Sharing_Amount__c = -3000;
                    	d.GP_Sharing_Location__c = v.HomeLocation__c;
                    	System.debug(d.GP_Sharing_Location__c);
                    	System.debug(d.GP_Sharing_Amount__c);
                	}
            	}
			} else {	// not 'Commercial') && not 'Wholesale' && Source='Inventory'
				// not a chassis/conversion OR not from inventory or NOT retail - no GP sharing 
				d.GP_Sharing_Amount__c = null;
				d.GP_Sharing_Location__c = null;
				d.GP_Sharing_Date__c = null;
			}	// end recordTypeName!='Commercial') && deal.dealer__Deal_Type__c!='Wholesale' && deal.Vehicle_Source__c='Inventory'
        }
    }
    // BLL76a end

    /*
    public PageReference saveCommercialQuote() {

        if(deal.Id==null) {
            // Lookup Next Deal Number
            deal.dealer__Deal_ID__c = String.valueOf(Integer.valueOf(commercialDefaults.QuoteNumber__c));
            deal.Name = 'P#'+deal.dealer__Deal_ID__c;
            commercialDefaults.QuoteNumber__c++;
            update commercialDefaults;
            insert deal;
        } else {
            update deal;
        }

        PageReference cq = Page.CommercialQuote;
        cq.getParameters().put('id', deal.Id);
        cq.setRedirect(true);
        return cq;

        return null;
    }
    */

    public PageReference deleteEquipment() {
        if(deleteEquipmentId!=null) {
            dealer__After_Market__c ae = [Select Id from dealer__After_Market__c where Id=:deleteEquipmentId limit 1];
            delete ae;
        }      
        return null;
    }

    public PageReference printPDF() {
        return null;
    }

    /*
    *
    *   Tax Hook
    *
    */

    /*
    public PageReference calcTax() {
        // Call AvaTax 
        deal.dealer__Sales_Tax__c = AvataxProposal.TaxCalcProposal(deal);
        return null;
    }

    public PageReference commitTax() {
        if(!AvataxProposal.commitTax(deal.Name)) {
            throw new DealException('Unable to commit Tax Transaction');
        }
        return null;
    }

    public PageReference postTax() {
        if(!AvataxProposal.postTax(deal)) {
            throw new DealException('Unable to Post Transaction');
        }
        return null;
    }   
    */
    
    /////////////////////////////////////////////////////////////////////////////
    /*
    |
    |   Multi-Quote Wrapper
    |
    */
    /////////////////////////////////////////////////////////////////////////////   
    public class wMultiQuote {
        public Integer term1 {get;set;}
        public Integer term2 {get;set;} 
        public Integer term3 {get;set;} 
        
        public Decimal rate1 {get;set;}
        public Decimal rate2 {get;set;}
        public Decimal rate3 {get;set;}
        
        public Decimal down1 {get;set;}
        public Decimal down2 {get;set;}
        public Decimal down3 {get;set;}

        public Decimal payment1_1 {get;set;}
        public Decimal payment1_2 {get;set;}
        public Decimal payment1_3 {get;set;}

        public Decimal payment2_1 {get;set;}
        public Decimal payment2_2 {get;set;}
        public Decimal payment2_3 {get;set;}

        public Decimal payment3_1 {get;set;}
        public Decimal payment3_2 {get;set;}
        public Decimal payment3_3 {get;set;}
        
        public Decimal balloon {get;set;}   // BLL52a

        public wMultiQuote(String jsondata) {
            Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(jsondata);


            if(m.get('Term1')!=null) {
            term1=Deal_MBW2.isInteger(String.valueOf(m.get('Term1')));
            term2=Deal_MBW2.isInteger(String.valueOf(m.get('Term2')));
            term3=Deal_MBW2.isInteger(String.valueOf(m.get('Term3')));
            rate1=Deal_MBW2.isDecimal(String.valueOf(m.get('Rate1')));
            rate2=Deal_MBW2.isDecimal(String.valueOf(m.get('Rate2')));
            rate3=Deal_MBW2.isDecimal(String.valueOf(m.get('Rate3')));
            }

            if(m.get('Down1')!=null && m.get('Down1')!='')  down1=Deal_MBW2.isDecimal(String.valueOf(m.get('Down1'))); 
            if(m.get('Down2')!=null && m.get('Down2')!='')  down2=Deal_MBW2.isDecimal(String.valueOf(m.get('Down2'))); 
            if(m.get('Down3')!=null && m.get('Down3')!='')  down3=Deal_MBW2.isDecimal(String.valueOf(m.get('Down3'))); 

            if(m.get('Row1_1')!=null && m.get('Row1_1')!='')  payment1_1=Deal_MBW2.isDecimal(String.valueOf(m.get('Row1_1'))); 
            if(m.get('Row1_2')!=null && m.get('Row1_2')!='')  payment1_2=Deal_MBW2.isDecimal(String.valueOf(m.get('Row1_2'))); 
            if(m.get('Row1_3')!=null && m.get('Row1_3')!='')  payment1_3=Deal_MBW2.isDecimal(String.valueOf(m.get('Row1_3'))); 

            if(m.get('Row2_1')!=null && m.get('Row2_1')!='')   payment2_1=Deal_MBW2.isDecimal(String.valueOf(m.get('Row2_1'))); 
            if(m.get('Row2_2')!=null && m.get('Row2_2')!='')   payment2_2=Deal_MBW2.isDecimal(String.valueOf(m.get('Row2_2'))); 
            if(m.get('Row2_3')!=null && m.get('Row2_3')!='')   payment2_3=Deal_MBW2.isDecimal(String.valueOf(m.get('Row2_3'))); 

            if(m.get('Row3_1')!=null && m.get('Row3_1')!='')  payment3_1=Deal_MBW2.isDecimal(String.valueOf(m.get('Row3_1'))); 
            if(m.get('Row3_2')!=null && m.get('Row3_2')!='')  payment3_2=Deal_MBW2.isDecimal(String.valueOf(m.get('Row3_2'))); 
            if(m.get('Row3_3')!=null && m.get('Row3_3')!='')  payment3_3=Deal_MBW2.isDecimal(String.valueOf(m.get('Row3_3'))); 

            if(m.get('Balloon')!=null && m.get('Balloon')!='') balloon=Deal_MBW2.isDecimal(String.valueOf(m.get('Balloon')));   // BLL52a

        }
    }
    // JVK3
    public static Decimal isDecimal(String s) {
        Decimal r = 0;
        try {
            r = Decimal.valueOf(s);
            //BLL62d return r;
        } catch (Exception e) {
            //
        }
        return r;
    }

    public static Integer isInteger(String s) {
        Integer i = 0;
        try { 
            i = Integer.valueOf(s);
            //BLL62d return i;
        } catch(Exception e) {
            // 
        }
        return i;
    }
    // End JVK3
    /////////////////////////////////////////////////////////////////////////////
    /*
    |
    |   Service and Parts Sales 
    |
    */
    /////////////////////////////////////////////////////////////////////////////
    public PageReference addService() {
        serviceItem = new addService();
        //BLL52d return Page.QuoteAddService;
        return addServicePage;  // BLL52a
    }

    public PageReference addSublet(){
        //BLL52d return Page.QuoteAddSublet;
        return addSubletPage;   // BLL52a
    }

    public PageReference addPart() {
        partItem = new addParts();
        //BLL52d return Page.QuoteAddPart;
        return addPartPage; // BLL52a
    }

    public PageReference saveSublet() {

        // Check for required values
        if(subletDescription==null || subletCost == null || subletSale == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'All fields are required to add Sublet to Proposal'));
            return null;
        }

        dealer__After_Market__c am  =   new dealer__After_Market__c();
        am.dealer__Car_Deal__c    =   deal.Id;
        am.Name                  =   'Misc';
        am.dealer__Cost__c        =   subletCost;
        am.dealer__Sale_Price__c    =   subletSale;
        // BLL52a
        am.dealer__Quantity__c      =   1;
        am.dealer__Part_Cost__c     =   subletCost;
        am.dealer__Parts_Sale__c    =   subletSale;
        // BLL52a end   
        am.dealer__Description__c   =   subletDescription;
        am.Print_on_Proposal__c  =   true;
        am.dealer__Labor_Sale__c    =   0.00;   // BLL30a
        am.Page_Order__c = nextAfterMarketSeq(deal.id);	// BLL102

        try { 
            
            insert am;
            //totalAftermarketItems(); // DR2
            PageReference dealPage  = self; // BLL52c  Page.QuoteManager;
            dealPage.getParameters().put('id', deal.Id);
            // BLL3 add - clear entry fields
            subletDescription = null;
            subletCost = null;
            subletSale = null;
            // BLL3 end block
            return dealPage;

        } Catch(DmlException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while saving Sublet '+e.getMessage()));
            //BLL62d return null;           
        }

        return null;
    }

	// BLL102
	public Decimal nextAfterMarketSeq(Id dealid) {
		AggregateResult maxam = [select max(Page_Order__c) maxseq from dealer__After_Market__c where dealer__Car_Deal__c=:dealid];
		Decimal maxseq = (Decimal) maxam.get('maxseq');
		return maxseq==null ? maxseq : maxseq+1;
	}
	// BLL102

    public PageReference savePart() {
        dealer__After_Market__c am  =   new dealer__After_Market__c();
        am.dealer__Car_Deal__c    =   deal.Id;
        am.Name                  =   '';

        //BLL38d return Page.QuoteManager;
        // BLL38a
        PageReference dealPage  = self; // BLL52c  Page.QuoteManager;
        dealPage.getParameters().put('id', deal.Id);
        return dealPage;
        // BLL38a end
    }

    // DR1
    public PageReference savePartOnProposal() {
        //RT3
        //dealer__Parts_Inventory__c pi = [SELECT Id, Name, dealer__Description__c, dealer__Cost__c, dealer__List__c,dealer__On_Hand__c FROM dealer__Parts_Inventory__c WHERE Id =:selectedPartNumber limit 1];
        dealer__Parts_Master__c partMaster = [SELECT Id, Name, dealer__Part_Description__c, dealer__Cost__c, dealer__Retail_Price__c, dealer__Manufacturer__c, Static_price__c, 
                                (select Name, dealer__Description__c, dealer__On_Hand__c,dealer__Cost__c,dealer__List__c, dealer__Static_Price__c from dealer__Parts_Inventories__r WHERE dealer__Location__c = :deal.dealer__Store_Location__c) 
                                FROM dealer__Parts_Master__c WHERE ID = :selectedPartNumber];
        
        dealer__Parts_Inventory__c pi;

        // TODO: Add part properties here
        //partItem = new addParts(); 

        if(partMaster.dealer__Parts_Inventories__r.size() > 0) {
            pi = partMaster.dealer__Parts_Inventories__r[0];
        }
        else {
            pi = new dealer__Parts_Inventory__c();
            pi.Name = partMaster.dealer__Manufacturer__c + ':' + partMaster.Name;
            pi.dealer__Parts_Master__c = partMaster.Id;
            pi.dealer__MFG__c = partMaster.dealer__Manufacturer__c;
            pi.dealer__Location__c = deal.dealer__Store_Location__c;
            pi.dealer__Cost__c = partMaster.dealer__Cost__c;
            pi.dealer__List__c = partMaster.dealer__Retail_Price__c;
            pi.dealer__Description__c = partMaster.dealer__Part_Description__c;  // BLL21a
			pi.dealer__Static_price__c = partMaster.Static_price__c; 	// BLL101a
            insert pi;
        }
        //end RT3
        if (pi != null) {

            // Use part master description if part inventory is missing one
            if (String.isBlank(pi.dealer__Description__c)) pi.dealer__Description__c = partMaster.dealer__Part_Description__c; // BLL21a

            // Build AM object to attach to
            dealer__After_Market__c am  =   new dealer__After_Market__c();
            am.dealer__Car_Deal__c    =   deal.Id;
            am.Name                  =   pi.Name;
            am.dealer__Description__c   =   pi.dealer__Description__c!=null ? pi.dealer__Description__c : '';
            am.dealer__Cost__c        =   pi.dealer__Cost__c;
            am.dealer__Sale_Price__c    =   pi.dealer__List__c; // Set Sale Price to List Price
            //BLL53d am.Print_on_Proposal__c     =   true; // BLL24a
			// BLL101
			if (pi.dealer__Static_Price__c!=null && pi.dealer__Static_Price__c!=0) am.dealer__Sale_Price__c = pi.dealer__Static_Price__c;	// BLL101a
			// BLL101
            am.Print_on_Proposal__c = !am.dealer__Description__c.contains('NMEDA ');	// BLL83a
            am.dealer__Labor_Sale__c    =   0.00;   // BLL30a
            // BLL52a
            am.dealer__Part_Cost__c = am.dealer__Cost__c;
            am.dealer__Parts_Sale__c = am.dealer__Sale_Price__c;    
            am.dealer__Quantity__c = 1;
            // BLL52a end
            am.dealer__Part__c = pi.Id; // BLL70a
            am.Page_Order__c = nextAfterMarketSeq(deal.id);	// BLL102

            try {
                insert am;
                //totalAftermarketItems(); // DR2 commented out
            } catch (DmlException e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to save the Part item.  Error: '+e));
                return null;            
            }

        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to save the Part item.  Error: No results returned with ID:'+selectedPartNumber));

        }

        //Allow Multiple parts to be added
        //if(partItem.selectMultiple) {
        //  return null;
        //} else {
            // BLL38d return Page.QuoteManager;
        // BLL38a
        PageReference dealPage  = self; // BLL52c  Page.QuoteManager;
        dealPage.getParameters().put('id', deal.Id);
        return dealPage;
        // BLL38a end
        //}
    }

    // end DR1

    public PageReference saveService() {
        
        dealer__After_Market__c am = new dealer__After_Market__c();
        am.dealer__Car_Deal__c    =   deal.Id;
        am.Name                  =   'Service '+deal.Name;
        am.dealer__Description__c   =   serviceItem.description;
        am.Labor_Hours__c          =   serviceItem.booktime;
        am.dealer__Cost__c        =   serviceItem.cost;
        am.dealer__Sale_Price__c    =   serviceItem.saleprice;
        am.Print_on_Proposal__c  =   true;
        //BLL52d am.dealer__Labor_Sale__c   =   0.00;   // BLL30a (saveservice is not used, this may be WRONG!)
        // BLL52a
        //am.dealer__Part_Cost__c = 0;
        //am.dealer__Parts_Sale__c = 0;
        //am.dealer__Labor_Sale__c = am.dealer__Sale_Price__c;
        //am.dealer__Labor_Cost__c = am.dealer__Cost__c;    
        am.dealer__Quantity__c = 1;
        // BLL52a end
        am.Page_Order__c = nextAfterMarketSeq(deal.id);	// BLL102

        try {
            insert am;
            //totalAftermarketItems(); // DR2 commented out
        } catch (DmlException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to save the service item.  Error: '+e));
            return null;            
        }

        // BLL38d return Page.QuoteManager;
        // BLL38a
        PageReference dealPage  = self; // BLL52c  Page.QuoteManager;
        dealPage.getParameters().put('id', deal.Id);
        return dealPage;
        // BLL38a end
    }

    public void totalAftermarketItems() {
        Decimal ae_cost = equipmentCost(deal.Id);
        Decimal ae_sale = equipmentSale(deal.Id);
        Decimal ae_labor = equipmentLabor(deal.Id); // BLL30a
        Decimal sc_cost = serviceContractCost(deal.Id);
        Decimal sc_sale = serviceContractSale(deal.Id);

        deal.Total_Internal_Local_Equipment__c  =   ae_cost;
        deal.Total_Additional_Equipment__c    =   ae_sale;
        deal.TotalAdditionalEquipLabor__c       =   ae_labor;   // BLL30a
        deal.Warranty_Cost__c                  =   sc_cost;
        deal.Total_Protection_Products__c      =   sc_sale;
        System.debug(deal.TotalAdditionalEquipLabor__c);    // BLL30a
        
        try {
            // BLL49 - not updating LastSavedDT__c because GP hasn't been recalculated in this routine!
            // BLL91
			//update deal;
			update(new dealer__Deal__c(Id=deal.Id, 
				Total_Internal_Local_Equipment__c=deal.Total_Internal_Local_Equipment__c,
				Total_Additional_Equipment__c=deal.Total_Additional_Equipment__c,
				TotalAdditionalEquipLabor__c=deal.TotalAdditionalEquipLabor__c,
				Warranty_Cost__c=deal.Warranty_Cost__c,
				Total_Protection_Products__c=deal.Total_Protection_Products__c 
			));
			// BLL91 end
        } catch(DmlException e) {
            throw new DealException('Error updating Aftermarket Totals '+e.getMessage());
        }
    }
    
    // DR2
    public static void totalAllAMItems(String dealId) {
    	// BLL23a add subselect of service contracts
        dealer__Deal__c deal = [SELECT Id, Conversion_Price__c, Conversion_Cost__c, Chassis_Price__c, Chassis_Cost__c, Total_Additional_Equipment__c, Total_Internal_Local_Equipment__c, Conversion_Discount__c, dealer__Trade_Allowance__c, Trade_ACV__c,
        TotalAdditionalEquipLabor__c, dealer__Total_Gross__c, // BLL30a
        (select Id, Name, Type__c from dealer__Service_Contracts__r where Type__c='Service Contract')  
        FROM dealer__Deal__c WHERE Id =: dealId LIMIT 1];

        if(deal != null){

            Decimal ae_cost = equipmentCost(dealId);
            Decimal ae_sale = equipmentSale(dealId);
            Decimal ae_labor = equipmentLabor(dealId);  // BLL30a
            Decimal sc_cost = serviceContractCost(dealId);
            Decimal sc_sale = serviceContractSale(dealId);

            deal.Total_Internal_Local_Equipment__c  =   ae_cost;
            deal.Total_Additional_Equipment__c    =   ae_sale;
            deal.TotalAdditionalEquipLabor__c       =   ae_labor;   // BLL30a
            deal.Warranty_Cost__c                  =   sc_cost;
            deal.Total_Protection_Products__c      =   sc_sale;

            if(deal.Conversion_Price__c == null) { deal.Conversion_Price__c = 0;}
            if(deal.Conversion_Cost__c == null) { deal.Conversion_Cost__c = 0;}
            if(deal.Chassis_Price__c==null && deal.dealer__Vehicle__c!=null) deal.Chassis_Price__c = deal.dealer__Vehicle__r.dealer__Vehicle_Cost__c; // BLL19a
            if(deal.Chassis_Price__c == null) { deal.Chassis_Price__c = 0;}
            if(deal.Chassis_Cost__c == null) { deal.Chassis_Cost__c = 0;}
            if(deal.Total_Additional_Equipment__c == null) { deal.Total_Additional_Equipment__c = 0;}
            if(deal.TotalAdditionalEquipLabor__c == null) {deal.TotalAdditionalEquipLabor__c = 0;}  // BLL30a
            if(deal.Total_Internal_Local_Equipment__c == null) { deal.Total_Internal_Local_Equipment__c = 0;}
            if(deal.Conversion_Discount__c == null) { deal.Conversion_Discount__c = 0;}
            if(deal.dealer__Trade_Allowance__c == null) { deal.dealer__Trade_Allowance__c = 0;}
            if(deal.Trade_ACV__c == null) { deal.Trade_ACV__c = 0;}

            // Calculate Deal Total Gross not including ESC
            deal.dealer__Front_End_Gross__c = ((deal.Conversion_Price__c - deal.Conversion_Cost__c) +
            (deal.Chassis_Price__c - deal.Chassis_Cost__c) +
            (deal.Total_Additional_Equipment__c - deal.Total_Internal_Local_Equipment__c) -
            deal.Conversion_Discount__c - 
            (deal.dealer__Trade_Allowance__c - deal.Trade_ACV__c) );

            deal.Total_Proposal_Gross__c = deal.dealer__Front_End_Gross__c;

            deal.ServiceContract1__c = deal.dealer__Service_Contracts__r.size()>0 ? 1 : 0;  // BLL23a

            System.debug('TOTAL GROSS: '+deal.dealer__Total_Gross__c);
            System.debug('TOTAL Proposal GROSS: '+deal.Total_Proposal_Gross__c);
            System.debug('FRONT END GROSS: '+deal.dealer__Front_End_Gross__c);

            System.debug(deal.TotalAdditionalEquipLabor__c);    // BLL30a

            try {

                // BLL49a - record timestamp - used to ensure proposal was saved to
                // reflect any changes in GP prior to being marked as Delivered.
                deal.LastSavedDT__c = Datetime.now();
                update deal;
            } catch(DmlException e) {
                throw new DealException('Error updating Aftermarket Totals '+e.getMessage());
            }
        } else throw new DealException('Error updating Aftermarket Totals. The Deal ID:'+dealId+' was not found. Method: totalAllAMItems()');
    }
    // /DR2

    public addService serviceItem {get;set;}
    public class addService {
        public String description {get;set;}
        public Decimal booktime {get;set;}
        public Decimal cost {get;set;}
        public Decimal saleprice {get;set;}
        public boolean taxable {get;set;}      
    }

    public addParts partItem {get;set;}
    public class addParts {
        public dealer__Parts_Inventory__c part {get;set;}
        public String partNumber {get;set;}
        public String description {get;set;}
        public Integer partQTY {get;set;}
        public Decimal cost {get;set;}
        public Decimal saleprice {get;set;}

        // DR1
        public Boolean selectMultiple {get;set;}
        // end DR1
    } 


    /////////////////////////////////////////////////////////////////////////////
    /*
    |
    |   Service Contract Related Methods
    |
    */
    /////////////////////////////////////////////////////////////////////////////
    // BLL61a
    public List<String> getEscTypes() {
        List<String> rtnTypes = new List<String>();
        List<AggregateResult> ars = [
            select Type__c, count(Id) cnt
            from dealer__Service_Contract__c
            where Active__c=true and dealer__Contract_Template__c = true
            group by Type__c
            order by Type__c
        ];
        for(AggregateResult ar : ars) rtnTypes.add((String) ar.get('Type__c'));
        return rtnTypes;        
    }
    // BLL61a
    
    public PageReference newServiceContract() {
        if (ApexPages.currentPage().getParameters().containsKey('escType')) escType = ApexPages.currentPage().getParameters().get('escType');   // BLL61a
        System.debug(escType);
        // BLL16a add where active__c=true
        escResults = [SELECT dealer__Contract_Template__c, dealer__Cost__c, 
                        dealer__Customer_Contact__c, dealer__Customer__c, dealer__Deductable__c, dealer__Description__c, 
                        dealer__End_Date__c, dealer__Expiration_Mileage__c, dealer__Expiration_Months__c,
                        dealer__Plan_Code__c, dealer__Product_Code__c, dealer__Sale_Price__c, dealer__Service_Vehicle__c, 
                        dealer__Start_Date__c, dealer__Vehicle_Inventory__c, Type__c, Name, Id 
                        FROM dealer__Service_Contract__c 
                        Where Type__c =:escType
                          and dealer__Contract_Template__c = true
                          and Active__c = true  
                        LIMIT 25];

        //BLL52d PageReference svc = Page.SellServiceContract;
        //BLL52d svc.setRedirect(false);
        //BLL52d return svc;
        svcContractPage.setRedirect(false); // BLL52a
        return svcContractPage; // BLL52a
    }

    public PageReference searchESC() {

        if(escDescription!=''&&escDescription!=null) {

        escResults = Database.query('SELECT dealer__Contract_Template__c, dealer__Cost__c, dealer__Customer_Contact__c, dealer__Customer__c, dealer__Deductable__c, dealer__Description__c, dealer__End_Date__c, dealer__Expiration_Mileage__c, dealer__Expiration_Months__c,dealer__Plan_Code__c, dealer__Product_Code__c, dealer__Sale_Price__c, dealer__Service_Vehicle__c, dealer__Start_Date__c, dealer__Vehicle_Inventory__c, Type__c, Name, Id FROM dealer__Service_Contract__c Where Type__c = \''+ escType +'\' and dealer__Contract_Template__c = true and Active__c=true and dealer__Description__c like \'%' + escDescription + '%\' LIMIT 500'); // BLL16c
        } else if(escCode!='' && escCode != null) {
        
        escResults = Database.query('SELECT dealer__Contract_Template__c, dealer__Cost__c, dealer__Customer_Contact__c, dealer__Customer__c, dealer__Deductable__c, dealer__Description__c, dealer__End_Date__c, dealer__Expiration_Mileage__c, dealer__Expiration_Months__c,dealer__Plan_Code__c, dealer__Product_Code__c, dealer__Sale_Price__c, dealer__Service_Vehicle__c, dealer__Start_Date__c, dealer__Vehicle_Inventory__c, Type__c, Name, Id FROM dealer__Service_Contract__c Where Type__c = \''+ escType +'\' and dealer__Contract_Template__c = true and Active__c=true and dealer__Plan_Code__c like \'%' + escCode + '%\' LIMIT 500');  // BLL16c
        } else {
            escResults = new List<dealer__Service_Contract__c>();
        }              

        return null;
    }

    public PageReference selectProduct() {
        // Add Product to deal
        if(escSelectedId==null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid Service Contract ID, unable to Save to Proposal'));
            return null;
        }

        dealer__Service_Contract__c sc; // BLL31a
        // BLL73a all fields
        Map<String, Schema.SObjectField> escFieldMap =  Schema.dealer__Service_Contract__c.SObjectType.getDescribe().fields.getMap();
        List<String> escFieldList = new List<String>();
        for(String f : escFieldMap.keySet()) {
            Schema.DescribeFieldResult escfield = escFieldMap.get(f).getDescribe();
            if (escfield.isCreateable()) escFieldList.add(escfield.getName());
        }
        String escFields = String.join(escFieldList, ',');        
        System.debug(escFieldList);
        System.debug(escFields);
        // BLL73a end
        try {   // BLL31a
            //BLL73d sc = [SELECT dealer__Contract_Template__c, dealer__Cost__c, // BLL31c declare outside new try-catch block 
            //BLL73d             Vendor_Name__c, // BLL11a
            //BLL73d             dealer__Customer_Contact__c, dealer__Customer__c, dealer__Deductable__c, dealer__Description__c, 
            //BLL73d             dealer__End_Date__c, dealer__Expiration_Mileage__c, dealer__Expiration_Months__c,
            //BLL73d             dealer__Plan_Code__c, dealer__Product_Code__c, dealer__Sale_Price__c, dealer__Service_Vehicle__c, 
            //BLL73d             dealer__Start_Date__c, dealer__Vehicle_Inventory__c, Type__c, Name, Id,
            //BLL73d             FlatCommission__c   // BLL28a 
            //BLL73d             FROM dealer__Service_Contract__c
            //BLL73d             WHERE Id=:escSelectedId
            //BLL73d             LIMIT 1];
            sc = Database.query('select ' + escFields + ' from dealer__Service_Contract__c where Id=:escSelectedId LIMIT 1');
        // BLL31a
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Could not add selected service contract to proposal. Error: '+e.getMessage()));
            return null;
        }
        // BLL31a end
    
        //BLL73d dealer__Service_Contract__c addToDeal = new dealer__Service_Contract__c();
        //BLL73d addToDeal.dealer__Car_Deal__c = deal.Id;
        //BLL73d addToDeal.dealer__Start_Date__c=deal.Proposed_Delivery_Date__c; // JVK3 IT#16965 - start date should be the proposed delivery date.
        //BLL73d addToDeal.dealer__Expiration_Months__c = sc.dealer__Expiration_Months__c;
        //BLL73d addToDeal.dealer__Expiration_Mileage__c = sc.dealer__Expiration_Mileage__c;
        //BLL73d addToDeal.dealer__Plan_Code__c = sc.dealer__Plan_Code__c;
        //BLL73d addToDeal.dealer__Product_Code__c = sc.dealer__Product_Code__c;
        //BLL73d addToDeal.dealer__Sale_Price__c = sc.dealer__Sale_Price__c;
        //BLL73d addToDeal.dealer__Customer_Contact__c = deal.dealer__Buyer_Contact__c;
        //BLL73d addToDeal.dealer__Description__c = sc.dealer__Description__c;
        //BLL73d addtoDeal.dealer__Cost__c = sc.dealer__Cost__c;
        //BLL73d if(deal.dealer__Buyer__c!=null) {
        //BLL73d     addToDeal.dealer__Customer__c = deal.dealer__Buyer__c; // JVK3 IT16965 - Account should be linked
        //BLL73d }

        // DR added type selection 8-13-2015
        //BLL73d addtoDeal.type__c = sc.type__c;
        //BLL73d addToDeal.Vendor_Name__c = sc.Vendor_Name__c; // BLL11a
        //BLL73d addToDeal.FlatCommission__c = sc.FlatCommission__c; // BLL28a
        // BLL73a
        dealer__Service_Contract__c addToDeal = sc.clone(false);    // Will be adding as a new service contract!
        addToDeal.OwnerId = deal.OwnerId;   // default owner
        addToDeal.dealer__Contract_Template__c = false;
        addToDeal.dealer__Car_Deal__c = deal.Id;
        addToDeal.dealer__Start_Date__c = deal.Proposed_Delivery_Date__c; 
        
        //BLL65d try {
        List<dealer__Service_Vehicle__c> vehicle = [Select Id from dealer__Service_Vehicle__c where dealer__Sales_Inventory__c =: deal.dealer__Vehicle__c limit 1];
        //BLL73d if (vehicle.size()>0) addToDeal.dealer__Service_Vehicle__c = vehicle[0].Id;
        if (deal.dealer__Vehicle__c!=null && vehicle.size()>0) addToDeal.dealer__Service_Vehicle__c = vehicle[0].Id;    // BLL73a
        if (deal.dealer__Vehicle__c==null && deal.dealer__Service_Vehicle__c!=null) addToDeal.dealer__Service_Vehicle__c = deal.dealer__Service_Vehicle__c; // BLL73a
        if (addToDeal.dealer__Service_Vehicle__c==null) 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must have a service vehicle listed on the proposal before adding protection products'));
        try {
            insert addToDeal;
        } catch(Exception e) {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must have a service vehicle listed on the proposal before adding protection products'));
            ApexPages.addMessage(new ApexPages.Message(APexPages.Severity.ERROR, 'Unable to add protection product: ' + e.getMessage()));   // BLL65a
            return null;
        }

        //BLL52d String url = '/apex/QuoteManager?id='+deal.Id+'#sec_esc';
        //BLL52d PageReference svc = new PageReference(url);
        PageReference svc = self;   // BLL52a
        svc.getParameters().put('id', deal.Id); // BLL52a
        svc.setAnchor('sec_esc');   // BLL52a
        svc.setRedirect(true);
        return svc; 
    }

    public PageReference deleteProduct() {
        System.debug(deleteProductId);
        if(deleteProductId!=null) {
            dealer__Service_Contract__c svc = [Select Id from dealer__Service_Contract__c where Id=:deleteProductId limit 1];
            try {
                delete svc;
                //totalAftermarketItems(); // DR2 commented out
            } catch (DmlException e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error removing product from proposal'));
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No product Id to remove from proposal'));
        }

        return null;
    }

    public PageReference returnToDeal() {
        //BLL52d String url = '/apex/QuoteManager?id='+deal.Id+'#sec_esc';
        //BLL52d PageReference svc = new PageReference(url);
        PageReference pg = self;    // BLL52a
        pg.getParameters().put('id', deal.Id);  // BLL52a
        pg.setAnchor('sec_esc');    // BLL52a
        pg.setRedirect(true);
        return pg;   
    }

    /////////////////////////////////////////////////////////////////////////////
    /*
    |
    |   Trade-In Related Methods / Class and Remotes
    |
    */
    /////////////////////////////////////////////////////////////////////////////   

    public PageReference newTrade() {
        // JVK5
        if(location!=null && location.Use_Appraisal_Dashboard__c==true) {       // BLL35c handle when location is null
            String url = '/apex/dtmob__MobilityAppraisal?did='+deal.Id;
            PageReference ma = new PageReference(url);
            ma.getParameters().put('did', deal.Id);
            ma.setRedirect(true);
            return ma;
        } // else {
        //BLL52d PageReference t = Page.QuoteTradePurchase;
        //BLL52d t.setRedirect(false);
        //BLL52d return t;
        tradeInPage.setRedirect(false); // BLL52a
        return tradeInPage; // BLL52a
    	//}
        // End JVK5
        //return null;
    }

    public PageReference saveTrade() {
        // Save Trade to Deal Object
        system.debug(tradeData);
        if(tradeData.dealer__Year__c!=null&&tradeData.dealer__Make__c!=null&&tradeData.dealer__Model__c!=null) {
            dealer__Trade_In__c trade = tradeData;
            trade.dealer__Car_Deal__c = deal.Id;
            trade.Name = trade.dealer__Year__c+' '+trade.dealer__Make__c+' '+trade.dealer__Model__c;
            // BLL36a
            Decimal trade_alw = trade.dealer__Trade_Allowance__c==null ? 0 : trade.dealer__Trade_Allowance__c;
            Decimal chassis_alw = trade.Chassis_Allowance__c==null ? 0 : trade.Chassis_Allowance__c;
            Decimal conversion_alw = trade.Conversion_Allowance__c==null ? 0 : trade.Conversion_Allowance__c;
            if (trade.Chassis_Allowance__c==null) trade.Chassis_Allowance__c = trade_alw - conversion_alw; 
            // BLL36a end
            try {
                insert trade;
            } catch (DmlException e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0)));
                return null;
            }
            tradeData = new dealer__Trade_In__c();
            PageReference dealPage = self;  // BLL52c Page.QuoteManager;
            dealPage.getParameters().put('id', deal.Id);    // BLL43a
            dealPage.setRedirect(false);
            return dealPage;
        } 
        return null;
    }

    /*
    public Messaging.EmailFileAttachment AttachPDF() {

        //PageReference pdf = new PageReference('/apex/CommercialQuote');
        PageReference pdf = new PageReference('/'+deal.Id);
        // add parent id to the parameters for standardcontroller
        pdf.getParameters().put('id', string.valueOf(deal.Id));
     
        // the contents of the attachment from the pdf
        Blob body;
        
        try {
          // returns the output of the page as a PDF
          body = pdf.getContent();
          
        } catch (VisualforceException e) {
          body = Blob.valueOf('Error Generating Attachment');
        }
     
        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        attach.setContentType('application/pdf');
        attach.setFileName(deal.Name+'-CommercialQuote.pdf');
        attach.setInline(false);
        attach.Body = body;
        
        return attach;
    } 
    */  

    public PageReference addKitToProposal() {

        selectMFG          =   null;
        selectCategory    =   null;
        selectSubCat        =   null;

        // Adding Kit to Proposal
        if(addKitId!=null) {

            // selling parts outside of kits.
            // CMC should have the ability to sell a part, lookup, choose labor and sell

            for(cPartsKit p : cParts) {
                if(p.Kit.Id == addKitId) {

                dealer__After_Market__c aftermarketItem = new dealer__After_Market__c();
                aftermarketItem.dealer__Car_Deal__c  =   deal.Id;
                aftermarketItem.dealer__Description__c  =   p.Kit.dealer__Description__c!=null ? p.Kit.dealer__Description__c : ''; 
                aftermarketItem.Labor_Hours__c        =   p.Kit.Labor_Hours__c;
                //BLL30d aftermarketItem.dealer__Sale_Price__c   =   p.Kit.Price_West__c;
                aftermarketItem.dealer__Sale_Price__c   =   location.Kit_Cost_Structure__c=='East' ? p.Kit.Price_East__c : p.Kit.Price_West__c; // BLL30a
                aftermarketItem.dealer__Labor_Sale__c   =   location.Kit_Cost_Structure__c=='East' ? p.Kit.LaborSaleEast__c : p.Kit.LaborSaleWest__c;   // BLL30a
                aftermarketItem.dealer__Cost__c      =   location.Kit_Cost_Structure__c=='East' ? p.Kit.Cost_East__c : p.Kit.Cost_West__c; // JVK6
                aftermarketItem.dealer__Parts_Kit__c    =   p.Kit.Id;
                aftermarketItem.Taxable__c            =   p.taxable;
                aftermarketItem.Name                    =   p.Kit.Name;
                //BLL53d aftermarketItem.Print_on_Proposal__c    =   true;
                aftermarketItem.Print_on_Proposal__c = !aftermarketItem.dealer__Description__c.contains('NMEDA ');	// BLL53a
                
                aftermarketItem.TaxExempt__c            =   false;  // BLL41a - Need to change on proposal after adding if exempt 
                // BLL32a
                if (math.abs(aftermarketItem.dealer__Labor_Sale__c)>math.abs(aftermarketitem.dealer__Sale_Price__c)) 
                    aftermarketItem.dealer__Labor_Sale__c = aftermarketitem.dealer__Sale_Price__c;
                // BLL32a end
                // BLL52a
                //aftermarketItem.dealer__Part_Cost__c = am.dealer__Cost__c = aftermarketItem.dealer__Cost__c;
                //aftermarketItem.dealer__Parts_Sale__c = am.dealer__Sale_Price__c - aftermarketItem.dealer__Labor_Sale__c; 
                aftermarketItem.dealer__Quantity__c = 1;
                // BLL52a end
	            aftermarketItem.Page_Order__c = nextAfterMarketSeq(deal.id);	// BLL102
                
                insert aftermarketItem;

                }
            }          

        } 

        cParts.clear();
        
        return null;
    }

    //BLL52d public dealer__Vehicle_Inventory__c getVehicle() {
    public dealer__Vehicle_Inventory__c getVehicleData() {

        // If Vehicle Not present on the deal, return null
        if(deal.dealer__Vehicle__c==null) {
            return null;
        }

        List<dealer__Vehicle_Inventory__c> v = new List<dealer__Vehicle_Inventory__c>();
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get('dealer__Vehicle_Inventory__c').getDescribe().fields.getMap();
 
        String commaSeparatedFields = '';
        for(String fieldName : fieldMap.keyset()){
            if(commaSeparatedFields == null || commaSeparatedFields == ''){
                commaSeparatedFields = fieldName;
            }else{
                commaSeparatedFields = commaSeparatedFields + ', ' + String.escapeSingleQuotes(fieldName);
            }
        }
        // BLL52a
        commaSeparatedFields += ', (select Id, Name, Quantity__c, CommercialQuoteOption__c, Description__c, OptionType__c, Flag1__c, ExtendedPrice__c ' 
            + ' from Vehicle_Commercial_Options__r where OptionType__c<>\'Chassis Options\' order by SectionSequence__c )';
        // BLL52a end
        String query = 'select ' + commaSeparatedFields + ' from dealer__Vehicle_Inventory__c where id = \'' + deal.dealer__Vehicle__c + '\' limit 1';
 
        v = Database.query(query);        
        vehOptionsPrice = 0;

        if(v.size()==1) {
            setVehOptionsPrintFlag(v[0], deal.VehOptionsNotPrinted__c);
            for(VehicleInventory_CommercialOption__c vico : v[0].Vehicle_Commercial_Options__r ) {
                vehOptionsPrice += vico.ExtendedPrice__c;
            }
            return v[0];
        } else {
            return null;
        }
    }

    /////////////////////////////////////////////////////////////////////////////
    /*
    |
    |   Form Logic
    |
    */
    /////////////////////////////////////////////////////////////////////////////   
    public string getxmlTag() {
        return '<?xml version="1.0" encoding="UTF-8"?>';
    }
    public dealer__Form__c form = new dealer__Form__c();
    public String form_id {get;set;}
    public PageReference selectImpactForm() {
        if(form_id!=null &&form_id!='') {
            form = [Select Id, dealer__Impact_Code__c from dealer__Form__c where Id=:form_id limit 1];
        }
        return null;
    }

    public Component.Apex.OutputText getcompiled_form () {
        // BLL53a
        if (buyer==null && deal!=null && deal.dealer__Buyer__c!=null) {
            buyer = [
                Select Id, Name, Salutation, FirstName, LastName, MiddleName, Suffix, PersonHomePhone, PersonMobilePhone, PersonMailingStreet, PersonMailingState, PersonMailingCity,   
                    PersonMailingCounty__c, PersonMailingPostalCode, PersonEmail, PersonOtherPhone, BillingStreet, isPersonAccount,
                    Phone, BillingCity, BillingState, BillingPostalCode
                from Account 
                where Id =:deal.dealer__Buyer__c
                limit 1
            ]; 
        }
        if (cobuyer==null && deal!=null && deal.dealer__Co_Buyer__c!=null) {
            cobuyer = [
                Select Id, Name, Salutation, FirstName, LastName, MiddleName, Suffix, PersonHomePhone, PersonMobilePhone, PersonMailingStreet, PersonMailingState, PersonMailingCity,   
                    PersonMailingCounty__c, PersonMailingPostalCode, PersonEmail, PersonOtherPhone, BillingStreet, isPersonAccount,
                    Phone, BillingCity, BillingState, BillingPostalCode
                from Account 
                where Id =:deal.dealer__Co_Buyer__c
                limit 1
            ]; 
        }
        // BLL53a end

        Component.Apex.OutputText ot = new Component.Apex.OutputText();
        if(form.dealer__Impact_Code__c != null) {
            ot.expressions.value = base64Decode(form.dealer__Impact_Code__c);
            ot.escape=false;
        }
        return ot ;
    }   

    public String base64Decode(String s) {
        if (s==null && s=='')  return '';

        Blob decodeBlob = EncodingUtil.base64Decode(s);
        String decodeString = decodeBlob.toString();
        if(!decodeString.contains('{!')) return '';

        return decodeString;
    }   
    /////////////////////////////////////////////////////////////////////////////
    /*
    |
    |   Remotes of all shapes and sizes :)
    |
    */
    /////////////////////////////////////////////////////////////////////////////   


    /* Remote Actions */
    @RemoteAction
    global static Account lookupCustomerRecord(String accountId, String contactId) {
        Account[] a = [Select Id, Phone, BillingCity, BillingStreet, BillingPostalCode, BillingState, PersonEmail, PersonHomePhone,
                        PersonMailingState, PersonMailingStreet, PersonMailingCity, PersonMailingPostalCode, PersonMobilePhone,
                        PersonOtherPhone, isPersonAccount from Account where Id=:accountId limit 1];
        List<Contact> c = new List<Contact>();
        if (!String.isBlank(contactId)) {
            c = [
                select Id, Phone, MailingStreet, MailingCity, MailingState, MailingPostalCode, MobilePhone, Email
                from Contact
                where Id=:contactId 
                limit 1
            ];
            if (c.size()>0) {   // use contact info instead of account address
                a[0].PersonMailingStreet = c[0].MailingStreet;
                a[0].PersonMailingCity = c[0].MailingCity;
                a[0].PersonMailingState = c[0].MailingState;
                a[0].PersonMailingPostalCode= c[0].MailingPostalCode;
                a[0].PersonHomePhone = c[0].Phone;
                a[0].PersonEmail = c[0].Email;
            }
        }
        if(a.size()==1) {
            return a[0];
        } else {
            return null;
        }
    }

    /*
    @RemoteAction
    public static Commercial_Quote_Options__c lookupOption(String cqoId) {
        Commercial_Quote_Options__c[] c = [SELECT Active__c, Location__c, Cost__c, Selling_Price__c, Internal_Note__c, 
                                            Wheelbase__c, Supplier_URL__c, Vehicle_Manufacturer__c, Id, Name, RecordTypeId 
                                            FROM Commercial_Quote_Options__c where Id=:cqoId limit 1];
        if(c.size()==1) {
            return c[0];
        } else {
            return null;
        }
    }
    */

    // BLL49 note: These remote actions aren't saving the results of any GP calcs, so they
    // should NOT update the new LastSavedDT__c field!

    //BLL62d @RemoteAction
    //BLL62d public static boolean saveDealStatus(String dealStatus) {
    //BLL62d    String[] s = dealStatus.split('~', 0);
    //BLL62d    dealer__Deal__c deal = [Select Id, dealer__Status__c from dealer__Deal__c where Id=:s[0] limit 1];
    //BLL62d 
    //BLL62d    if(s[1]!='') {
    //BLL62d        deal.dealer__Status__c = s[1];
    //BLL62d        update deal;
    //BLL62d        return true;
    //BLL62d    }
    //BLL62d    return false;
    //BLL62d }

    @RemoteAction 
    global static Decimal dealGrossSVC(String dealId) {
        Decimal svc = 0.00;
        AggregateResult[] svcContractTotal = [Select SUM(Gross__c) from dealer__Service_Contract__c where dealer__Car_Deal__c=:dealId];
        if(svcContractTotal.size()==1 && svcContractTotal[0].get('expr0')!=null) {
         svc = Decimal.valueOf(String.valueOf(svcContractTotal[0].get('expr0')));
        }
        return svc;
    }

    @RemoteAction 
    global static Decimal dealGrossEquipment(String dealId) {
        Decimal e = 0.00;
        //BLL52d AggregateResult[] eTotal = [Select SUM(Gross__c) from dealer__After_Market__c where dealer__Car_Deal__c=:dealId];
		// BLL52a 
        AggregateResult[] eTotal = [    
            select SUM(ExtendedGross__c) 
            from dealer__After_Market__c 
            where dealer__Car_Deal__c=:dealId
        ];
        if(eTotal.size()==1 && eTotal[0].get('expr0')!=null) {
         e = Decimal.valueOf(String.valueOf(eTotal[0].get('expr0')));
        }
        return e;
    } 

    @RemoteAction
    global static Decimal equipmentCost(String dealId) {
        Decimal e = 0.00;
        //BLL52d AggregateResult[] eTotal = [Select SUM(dealer__Cost__c) from dealer__After_Market__c where dealer__Car_Deal__c=:dealId];
		// BLL52a
        AggregateResult[] eTotal = [     
            select SUM(ExtendedCost__c) 
            from dealer__After_Market__c 
            where dealer__Car_Deal__c=:dealId
        ];
        if(eTotal.size()==1 && eTotal[0].get('expr0')!=null) {
         e = Decimal.valueOf(String.valueOf(eTotal[0].get('expr0')));
        }
        return e;      
    }   

    @RemoteAction
    global static Decimal equipmentSale(String dealId) {
        Decimal e = 0.00;
        //BLL52d AggregateResult[] eTotal = [Select SUM(dealer__Sale_Price__c) from dealer__After_Market__c where dealer__Car_Deal__c=:dealId];
        AggregateResult[] eTotal = [    // BLL52a
            select SUM(ExtendedPrice__c) 
            from dealer__After_Market__c 
            where dealer__Car_Deal__c=:dealId
        ];
        if(eTotal.size()==1 && eTotal[0].get('expr0')!=null) {
         e = Decimal.valueOf(String.valueOf(eTotal[0].get('expr0')));
        }
        return e;      
    }  

    // BLL30a
    //@RemoteAction
    public static Decimal equipmentLabor(String dealId) {
        Decimal e = 0.00;
        //BLL52d AggregateResult[] eTotal = [Select SUM(dealer__Labor_Sale__c) from dealer__After_Market__c where dealer__Car_Deal__c=:dealId];
        //BLL52d AggregateResult[] eTotal2 = [Select SUM(dealer__Sale_Price__c) sumlbr from dealer__After_Market__c where dealer__Car_Deal__c=:dealId and dealer__Parts_Kit__c=null and (Labor_Hours__c>0 or Name like 'Service %')];
		// BLL52a
        AggregateResult[] eTotal = [    
            select SUM(ExtendedLaborPrice__c) 
            from dealer__After_Market__c 
            where dealer__Car_Deal__c=:dealId
        ];
        AggregateResult[] eTotal2 = [
            select SUM(ExtendedPrice__c) sumlbr 
            from dealer__After_Market__c 
            where dealer__Car_Deal__c=:dealId and dealer__Parts_Kit__c=null and (Labor_Hours__c>0 or Name like 'Service %')
        ];
        if(eTotal.size()==1 && eTotal[0].get('expr0')!=null) {
            e = Decimal.valueOf(String.valueOf(eTotal[0].get('expr0')));
        } else { e = 0.00; }
        if (eTotal2.size()==1 && eTotal2[0].get('sumlbr')!=null) {
            e += Decimal.valueOf(String.valueOf(eTotal2[0].get('sumlbr')));
            System.debug(e); 
        }
        return e;      
    }  
    // BLL30a end

    @RemoteAction 
    global static Decimal serviceContractCost(String dealId) {
        Decimal svc = 0.00;
        AggregateResult[] svcContractTotal = [Select SUM(dealer__Cost__c) from dealer__Service_Contract__c where dealer__Car_Deal__c=:dealId];
        if(svcContractTotal.size()==1 && svcContractTotal[0].get('expr0')!=null) {
         svc = Decimal.valueOf(String.valueOf(svcContractTotal[0].get('expr0')));
        }
        return svc;
    } 

    @RemoteAction 
    global static Decimal serviceContractSale(String dealId) {
        Decimal svc = 0.00;
        AggregateResult[] svcContractTotal = [Select SUM(dealer__Sale_Price__c) from dealer__Service_Contract__c where dealer__Car_Deal__c=:dealId];
        if(svcContractTotal.size()==1 && svcContractTotal[0].get('expr0')!=null) {
         svc = Decimal.valueOf(String.valueOf(svcContractTotal[0].get('expr0')));
        }
        return svc;
    }  

    @RemoteAction
    global static Boolean updateServiceContractSale(String scSale) {
        String[] p = scSale.split('~');
        if(p.size()!=2) {
            return false;
        }

        dealer__Service_Contract__c[] sc = [Select Id from dealer__Service_Contract__c where Id=:p[0] limit 1];
        if(sc.size()==0) {
            return false;
        }

        sc[0].dealer__Sale_Price__c = Decimal.valueOf(p[1]);

        try {
            update sc;
        } Catch(DmlException e) {
            return false;
        }

        return true;

    }

    @RemoteAction
    global static boolean updateEquipmentSale(String eqSaleAmount) {
        String[] p = eqSaleAmount.split('~');
        if(p.size()!=2) {
            return false;
        }

        // 2 Parts, RowId and Amount
        //BLL32d dealer__After_Market__c[] am = [Select Id from dealer__After_Market__c where Id=:p[0] limit 1];
        // BLL32a
		// BLL52c add quantity
		// BLL52a dealer__Part_Cost__c, dealer__Labor_Cost__c, ExtendedCost__c, ExtendedPrice__c, ExtendedGross__c, ExtendedLaborPrice__c
        dealer__After_Market__c[] am = [
            select Id, dealer__Quantity__c, Labor_Hours__c, dealer__Sale_Price__c, dealer__Parts_Sale__c, dealer__Labor_Sale__c,    
                dealer__Parts_Kit__r.LaborSaleEast__c, dealer__Parts_Kit__r.LaborSaleWest__c, 
                dealer__Car_Deal__r.dealer__Store_Location__r.Kit_Cost_Structure__c,
                dealer__Part_Cost__c, dealer__Labor_Cost__c, ExtendedCost__c, ExtendedPrice__c, ExtendedGross__c, ExtendedLaborPrice__c 
            from dealer__After_Market__c 
            where Id=:p[0] 
            limit 1
        ];
        //BLL51d removed dealer__Car_Deal__r.Location__r.Kit_Cost_Structure__c 
        // BLL32a
        if(am.size()==0) {
            return false;
        }

        am[0].dealer__Sale_Price__c = Decimal.valueOf(p[1]);
        //am[0].dealer__Parts_Sale__c = Decimal.valueOf(p[1]) - am[0].dealer__Labor_Sale__c;    // BLL52a
        
        // BLL32a   
        try{
            //BLL51d am[0].dealer__Labor_Sale__c = am[0].dealer__Car_Deal__r.Location__r.Kit_Cost_Structure__c =='East' ? am[0].dealer__Parts_Kit__r.LaborSaleEast__c : am[0].dealer__Parts_Kit__r.LaborSaleWest__c;    // BLL32a
            am[0].dealer__Labor_Sale__c = am[0].dealer__Car_Deal__r.dealer__Store_Location__r.Kit_Cost_Structure__c =='East' ? am[0].dealer__Parts_Kit__r.LaborSaleEast__c : am[0].dealer__Parts_Kit__r.LaborSaleWest__c;   // BLL51a
        } catch(Exception e) {}
        if (am[0].dealer__Labor_Sale__c!=null && am[0].dealer__Sale_Price__c!=null 
            && math.abs(am[0].dealer__Labor_Sale__c)>math.abs(am[0].dealer__Sale_Price__c)) 
            am[0].dealer__Labor_Sale__c = am[0].dealer__Sale_Price__c;
        // BLL32a end

        // BLL52a       
        if (am[0].dealer__Quantity__c==null) am[0].dealer__Quantity__c = 1;
        //am[0].dealer__Sale_Price__c = am[0].dealer__Quantity__c * (am[0].dealer__Parts_Sale__c+am[0].dealer__Labor_Sale__c);
        //am[0].dealer__Cost__c = am[0].dealer__Quantity__c * (am[0].dealer__Part_Cost__c + am[0].dealer__Labor_Cost__c);
        // BLL52a end
        
        try {
            update am;
        } Catch(DmlException e) {
            return false;
        }

        return true;
    }


    // BLL52a 
    @RemoteAction
    global static boolean updateEquipmentQty(String eqQty) {
        boolean updateOkay = true;
        String[] p = eqQty.split('~');
        if(p.size()!=2) updateOkay = false;

        // 2 Parts, RowId and Quantity
        // BLL52a add ExtendedCost__c, ExtendedPrice__c, ExtendedGross__c, ExtendedLaborPrice__c
        dealer__After_Market__c[] am = [
            select Id, dealer__Quantity__c, Labor_Hours__c, dealer__Sale_Price__c, dealer__Parts_Sale__c, dealer__Labor_Sale__c,
                dealer__Parts_Kit__r.LaborSaleEast__c, dealer__Parts_Kit__r.LaborSaleWest__c, 
                dealer__Car_Deal__r.dealer__Store_Location__r.Kit_Cost_Structure__c,
                dealer__Part_Cost__c, dealer__Labor_Cost__c,
                ExtendedCost__c, ExtendedPrice__c, ExtendedGross__c, ExtendedLaborPrice__c  
            from dealer__After_Market__c 
            where Id=:p[0] 
            limit 1
        ];
        if(am.size()==0) updateOkay = false;

        am[0].dealer__Quantity__c = Decimal.valueOf(p[1]);
        if (am[0].dealer__Quantity__c==null) am[0].dealer__Quantity__c=1;
        //am[0].dealer__Sale_Price__c = am[0].dealer__Quantity__c * (am[0].dealer__Parts_Sale__c+am[0].dealer__Labor_Sale__c);
        //am[0].dealer__Cost__c = am[0].dealer__Quantity__c * (am[0].dealer__Part_Cost__c + am[0].dealer__Labor_Cost__c);
        
        //try{
        //  am[0].dealer__Labor_Sale__c = am[0].dealer__Car_Deal__r.dealer__Store_Location__r.Kit_Cost_Structure__c =='East' ? am[0].dealer__Parts_Kit__r.LaborSaleEast__c : am[0].dealer__Parts_Kit__r.LaborSaleWest__c;   // BLL51a
        //} catch(Exception e) {}
        //if (am[0].dealer__Labor_Sale__c!=null && am[0].dealer__Sale_Price__c!=null 
        //  && math.abs(am[0].dealer__Labor_Sale__c)>math.abs(am[0].dealer__Sale_Price__c)) 
        //  am[0].dealer__Labor_Sale__c = am[0].dealer__Sale_Price__c;
        
        try {
            if (updateOkay) update am;
        } Catch(DmlException e) {
            updateOkay = false;
        }

        return updateOkay;
    }
    // BLL52a end

    @RemoteAction
    global static boolean toggleTax(String t) {
        String[] rp = t.split(':');
        if(rp.size()!=2) {
            return null;
        }

        dealer__After_Market__c a = [Select Id from dealer__After_Market__c where Id=:rp[0] limit 1];

        if(rp[1]=='true') {
            a.Taxable__c = true;
        } else {
            a.Taxable__c = false;
        }

        try {
            update a;
        } Catch(DmlException e) {
            return false;
        }

        return true;
    }  

    // BLL41a
    @RemoteAction
    global static boolean toggleTaxExempt(String t) {
        String[] rp = t.split(':');
        if(rp.size()!=2) {
            return null;
        }

        dealer__After_Market__c a = [Select Id from dealer__After_Market__c where Id=:rp[0] limit 1];

        if(rp[1]=='true') {
            a.TaxExempt__c = true;
        } else {
            a.TaxExempt__c = false;
        }

        try {
            update a;
        } Catch(DmlException e) {
            return false;
        }

        return true;
    }  
    // BLL41a end

    @RemoteAction
    global static boolean togglePrint(String t) {
        String[] rp = t.split(':');
        if(rp.size()!=2) {
            return null;
        }

        dealer__After_Market__c a = [Select Id, dealer__Description__c from dealer__After_Market__c where Id=:rp[0] limit 1];

        if(rp[1]=='true') {
            a.Print_on_Proposal__c = true;
        } else {
            a.Print_on_Proposal__c = false;
        }

		// BLL83a
		// BLL88d
		//if (a.dealer__Description__c.contains('NMEDA ') && a.Print_on_Proposal__c==true) {
		//	System.debug('Cannot print NMEDA fee on page 2!');
		//	return false;
		//}
		// BLL88d end
		// BLL83a end

        try {
            update a;
        } Catch(DmlException e) {
            return false;
        }

        return true;
    }  

    @RemoteAction 
    global static boolean saveDealDate(String dealDate) {
        String[] s = dealDate.split('~');
     
        dealer__Deal__c deal = [Select Id, dealer__Deal_Date__c, Proposed_Delivery_Date__c from dealer__Deal__c where Id=:s[0] limit 1];
        if(s[1]!='' && s[2]=='dd') {
            deal.dealer__Deal_Date__c = Date.parse(s[1]);
            update deal;
            return true;
        }
     
        if(s[1]!='' && s[2]=='pd') {
            deal.Proposed_Delivery_Date__c=Date.parse(s[1]);
            update deal;
            return true;
        }
        return false;
     }

    /*
     * selectStockNumber() ARG: VehicleID
     */
    @RemoteAction
    global static List<dealer__Vehicle_Inventory__c> selectStockNumber(String stkid) {
        List<dealer__Vehicle_Inventory__c> inventory = [Select dealer__Year__c, dealer__Vehicle_Type__c, dealer__Vehicle_Size__c, dealer__Trim_Level__c,
                                                                dealer__Vehicle_Cost__c, dealer__VIN__c, dealer__Stock_Number__c, dealer__Status_Code__c, 
                                                                dealer__Sale_Date__c, dealer__Retail_Price__c, dealer__Reserve_Price__c, dealer__New_Tires__c, SuggestedRetailPrice__c,  
                                                                dealer__NUO__c, dealer__Model__c, dealer__Model_Code__c, dealer__Mileage__c, 
                                                                dealer__Memo_Two__c, dealer__Memo_One__c, dealer__Make__c, dealer__Location__c, 
                                                                dealer__License__c, dealer__License_Exp__c, dealer__Inventory_Date__c, 
                                                                dealer__In_Stock__c, dealer__Holdback__c, dealer__Days_in_Stock__c, dealer__Coded_Cost__c, 
                                                                dealer__Body_Type__c, dealer__Keyless_Entry_Code__c, dealer__Demo_Indicator__c, 
                                                                dealer__Ignition_Key_Code__c, dealer__MSRP__c, dealer__Pack__c, 
                                                                dealer__Exterior_Color__c, dealer__Title_Type__c, dealer__Fuel_Type__c, dealer__Work_in_Process__c,
                                                                dealer__Invoice_Price__c, dealer__Engine_Description__c, dealer__Transmission_Type__c, Conversion_Cost__c 
                                                                From dealer__Vehicle_Inventory__c 
                                                                where Id = :stkid
                                                                and IsDeleted=false 
                                                                Limit 1];

        return inventory;
    }   


    /*

        @method : saveField is a static method that accepts a string containing fieldname, value and element to perform DML update to
        @param  : RecordId~FieldName__c~Value (Split inside the static method, Remotes only accept one parameter)   

    */
   @RemoteAction
    global static boolean saveField(String fieldData) {
        String[] s = fieldData.split('~', 0);
        /*
            0 = Record Id
            1 = Field
            2 = Value
        */    
        if(s.size()!=3) {
            return false;
        }

        dealer__Deal__c q = [Select Id from dealer__Deal__c where Id =:s[0] limit 1];
        // Get Field Mapping
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.dealer__Deal__c.fields.getMap();
        Boolean contains = fieldMap.containsKey(String.valueOf(s[1]).remove('dealer__'));

        if(!contains) {
            system.debug('Failed to map field.');
            return false;
        }

        // Get Field Type so we can cast as the correct type for the database.
        Schema.SObjectType             t = Schema.getGlobalDescribe().get('dealer__Deal__c');
        Schema.DescribeSObjectResult     r = t.getDescribe();
        Schema.DescribeFieldResult     f = r.fields.getMap().get(String.valueOf(s[1])).getDescribe();

        System.debug(f);

        if(f.getType() == Schema.DisplayType.Date) {
            q.put(fieldMap.get(s[1]), Date.parse(s[2]));
        } else if(f.getType() == Schema.DisplayType.Currency) {
            q.put(fieldMap.get(s[1]), Double.valueOf(s[2]));
        } else if(f.getType() == Schema.DisplayType.Double) {
            q.put(fieldMap.get(s[1]), Decimal.valueOf(s[2]));
        } else if(f.getType() == Schema.DisplayType.Percent) {
            q.put(fieldMap.get(s[1]), Decimal.valueOf(s[2]));
        } else {
            q.put(fieldMap.get(s[1]), s[2]);
        }
        try {
            update q;
        } catch(DMLException e) {
            return false;   
        }

        return true;
    } 

    /*
        @method : return a list of AfterMarket items saved to this deal 
        @param : dealId = Record Id of the corresponding deal
    */

    @RemoteAction
    global static List<dealer__After_Market__c> aftermarketItems(String dealId) {
    	// BLL30c dealer__Labor_Sale__c, BLL52c quantity
    	// BLL52a add dealer__Labor_Cost__c, dealer__Part_Cost__c, dealer__Parts_Sale__c, 
        // BLL52a add  ExtendedCost__c, ExtendedPrice__c, ExtendedGross__c, ExtendedLaborPrice__c  
        return [SELECT dealer__Quantity__c, dealer__Cost__c, dealer__Sale_Price__c, dealer__Labor_Sale__c,   
                    dealer__Labor_Cost__c, dealer__Part_Cost__c, dealer__Parts_Sale__c, 
                    ExtendedCost__c, ExtendedPrice__c, ExtendedGross__c, ExtendedLaborPrice__c  
                FROM dealer__After_Market__c
                Where dealer__Car_Deal__c =:dealId
                and dealer__Car_Deal__c != null
                Limit 50];
    } 

    @RemoteAction
    global static List<dealer__Service_Contract__c> serviceContractItems(String dealId) {
        return [SELECT dealer__Cost__c, dealer__Sale_Price__c
                    FROM dealer__Service_Contract__c 
                    Where dealer__Car_Deal__c =: dealId
                    and dealer__Car_Deal__c != null
                    Limit 10];
    }

    /*
        @method : set order of aftermarket parts sold on a deal
        @param : json string containing record Id and order
    */
    @RemoteAction
    global static boolean setAfterMarketOrder(String orderJson) {
        // Read JSON Payload into Aftermarket Equipment Object
        List<dealer__After_Market__c> amList = new List<dealer__After_Market__c>();
        Set<String> idSet = new Set<String>();
        Map<String, Object> eListItem = (Map<String, Object>)JSON.deserializeUntyped(orderJson);
        List<Object> items = (List<Object>)eListItem.get('items');
        List<orderResponse> eOrder = new List<orderResponse>();

        for(Object i : items) {
            Map<String, Object> m = (Map<String, Object>)i;
            orderResponse o = new orderResponse();
            o.RecordId = String.valueOf(m.get('RecordId'));
            o.PageOrder= Decimal.valueOf(String.valueOf(m.get('PageOrder')));
            eOrder.add(o);
        }

        for(orderResponse m : eOrder) {
            idSet.add(m.RecordId);
        }
        
        // Get the related records for update
        Map<Id, dealer__After_Market__c> amTemp = new Map<Id, dealer__After_Market__c>([Select Id from dealer__After_Market__c where Id IN:idSet limit 2000]);
        for(orderResponse m : eOrder) {
            dealer__After_Market__c lUpdate = amTemp.get(Id.valueOf(String.valueOf(m.RecordId)));
            if(lUpdate!=null) {
                lUpdate.Page_Order__c = m.PageOrder;
                amList.add(lUpdate);
            }
        }

        try {
            update amList;
        } catch(DmlException e) {
            return false;
        }

        return true;
    } 

    @RemoteAction
    global static dealer__Service_Vehicle__c addServiceVehicle(String svc) {

        Map<String, Object> vehicle = (Map<String, Object>)JSON.deserializeUntyped(svc);
        dealer__Service_Vehicle__c v = new dealer__Service_Vehicle__c();
        
        v.dealer__VIN__c = String.valueOf(vehicle.get('VIN'));
        v.dealer__Year__c = String.valueOf(vehicle.get('Year'));
        v.dealer__Make__c= String.valueOf(vehicle.get('Make'));
        v.dealer__Carline__c= String.valueOf(vehicle.get('Model'));
        v.dealer__Search_Names__c = String.valueOf(vehicle.get('OwnerName'));
        v.dealer__Veh_Owner__c = String.valueOf(vehicle.get('OwnerId'));
        v.dealer__Ext_Color__c = String.valueOf(vehicle.get('ExteriorColor'));  // BLL69a
        
        String odom = String.valueOf(vehicle.get('Odometer'));
        if(odom=='') {
            odom = '0';
        }

        v.dealer__Last_Odometer__c = Decimal.valueOf(odom);

        System.debug(v);
        
        try {
            insert v;
        } catch(DmlException e) {
            throw new DealException('Error creating record '+e.getMessage()); // DR3
            //return null;
        }

        //RT4
        dealer__Service_Vehicle__c newV = [SELECT Name, Id, dealer__VIN__c, dealer__Year__c, dealer__Make__c, dealer__Carline__c, dealer__Search_Names__c, dealer__Veh_Owner__c
                                            FROM dealer__Service_Vehicle__c WHERE Id = :v.Id];
        return newV;

    }

    @RemoteAction 
    global static String compileFDF(String fd) {

        Map<String, Object> js = (Map<String, Object>)JSON.deserializeUntyped(fd);
        String formId = (String)js.get('form');
        String dealId = (String)js.get('deal');
        
        MW_TriggerControls__c dealCustomFDF = MW_TriggerControls__c.getInstance('DealCustomFDF');
        
        // BLL46a - override to custom FDF handler if enabled
        String urlPR = '/apex/dealer__FormFDFData?fid='+formId+'&did='+dealId;
        if (dealCustomFDF!=null && dealCustomFDF.Enabled__c) urlPR = '/apex/FormFDFDataDeal?fid='+formId+'&id='+dealId;
        System.debug(urlPR);
        // BLL46a end

        PageReference p = new PageReference(urlPR);
        
        p = Page.dealer__FormFDFData;
        p.getParameters().put('fid',formId);
        p.getParameters().put('did',dealId);
        
        if (dealCustomFDF!=null && dealCustomFDF.Enabled__c) {
        	p = Page.FormFDFDataDeal;
        	p.getParameters().put('fid',formId);
        	p.getParameters().put('id',dealId);
        }
        System.debug(p.getURL());
        
        Blob uContetent = p.getContent();

        return uContetent.toString();
    }

    // BLL10a added null function for search button that simply re-renders the search results
    public void noAction() {
        return;
    }

    // Response Class for the Order 
    public class orderResponse {
        public String RecordId {get;set;}
        public Decimal PageOrder {get;set;}
    } 

    public class DealException extends Exception {}



    // BLL52a - routines for emailing PDFs
    public PageReference emailPDFDirect() {

        Messaging.EmailFileAttachment attach;
        Blob pdf = getQuoteAsPDFBlob(); 
        //Messaging.EmailFileAttachment attach = AttachPDF();
        if (pdf!=null) {
            attach = AttachPDF(pdf);
        }
        
        // BLL1a start: get list of send-to addresses
        String[] sendToAddresses = toAddress.replace(',', ';').split(';');  
        // Remove any empty strings (like from trailing semi-colons)
        for(Integer i=sendToAddresses.size()-1; i>=0; i-- ) {
            if (sendToAddresses[i].trim().length()==0) {
                sendToAddresses.remove(i);
            }
        } 
        // Simple error-checking: if no addresses, it's an error!
        PageReference toPage = self;
        toPage.getParameters().put('id',deal.Id);
        if (sendToAddresses.size() < 1) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error: Missing send-to email address'));
            toPage = null;
        }
     
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();
        mail.setUseSignature(false);
        mail.setToAddresses(sendToAddresses); 
        mail.setSubject(subject);
        mail.setHtmlBody(body);
        if (attach!=null) {
           listOfAttachments.add(attach);
        }

        // Additional Attachments
        if(attachmentList.size()>0) {
            // AMM87
            // for(Attachment a : [Select Id, Name, Body, ContentType, BodyLength from Attachment where Id IN :attachmentList]) {
            //     Messaging.EmailFileAttachment m_attachment = new Messaging.EmailFileAttachment();
            //     m_attachment.setBody(a.Body);
            //     m_attachment.setContentType(a.ContentType);
            //     m_attachment.setFileName(a.Name);
            //     m_attachment.setinline(false);
            //     listOfAttachments.add(m_attachment);
            // }

            for(ContentVersion a : [SELECT Id, Title, FileType, VersionData FROM ContentVersion WHERE Id IN :attachmentList]) 
            {
                Messaging.EmailFileAttachment m_attachment = new Messaging.EmailFileAttachment();
                m_attachment.setBody(a.VersionData);
                // AMM97
                //m_attachment.setContentType(a.FileType);
                if(a.FileType == 'PDF')
                {
                    m_attachment.setContentType('application/pdf');
                }
                else 
                {
                    m_attachment.setContentType(a.FileType);
                }
                // AMM97
                m_attachment.setFileName(a.Title);
                m_attachment.setinline(false);
                listOfAttachments.add(m_attachment);
            }
            // AMM87
        }
      
        mail.setFileAttachments(listOfAttachments);
           
        // Only send if no error messages
        if (!ApexPages.hasMessages(ApexPages.Severity.ERROR) || Test.isRunningTest()) {  
           // Send the email
           try { 
               Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Email with Commercial Proposal was sent to '));
            
               // Record Activity
               Task t = new Task( Subject='Emailed Commercial Proposal to '+emailTo + ' at ' + toAddress, 
                               ActivityDate=Date.today(),
                               WhatId=deal.Id,
                               Status='Completed');
               insert t;             
               
               // Attach PDF to task  
               // AMM87
            //    Attachment att = new Attachment();
            //    if (pdf!=null) {
            //       att.Body = pdf;
            //    } else {
            //       att.Body = Blob.valueOf('No attachment');
            //    }
            //    att.ContentType = 'application/pdf';
            //    att.Name = 'Proposal_'+deal.Name+'.pdf';
            //    att.ParentId = t.Id;
            //    insert att;
    
                LightningFileUtility tempUtility = new LightningFileUtility(); // reset all the context
                if (pdf!=null) 
                {
                    tempUtility.addFile('Proposal_'+deal.Name+'.pdf', EncodingUtil.base64Encode(pdf), t.Id, false, null); // Attachment
                } 
                else
                {
                    tempUtility.addFile('Proposal_'+deal.Name+'.pdf', 'No attachment', t.Id, false,null); // Attachment
                }
                tempUtility.commitFiles();
                // AMM87
    
               try {    
                   deal.Quote_Emailed__c = true;
                   update deal;
               } catch(Exception err) {}    // end try-catch updating deal

           } catch(Exception e) {  
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to send email: ' + e.getMessage()));
               toPage = null;
           } // end try-catch sending email

        } // end if hasMessages
        
        return toPage;  // BLL1a so toPage can be set to null if there are errors
    }   

    /* addAttachment */
    public PageReference addAttachment() {
        // Insert Attachment and Store ID for send
        if(aBody!=null&&aFileName!=null){
            // AMM87
            // attachment = new Attachment(
            //     Body=aBody,
            //     ContentType=aContentType,
            //     Name=aFileName,
            //     ParentId=deal.Id
            // );
        
            // insert attachment;

            // attachmentList.add(attachment.Id);
            // attachment = null;

            LightningFileUtility tempUtility = new LightningFileUtility();
            tempUtility.addFile(aFileName, EncodingUtil.base64Encode(aBody), deal.Id, false, null); // Attachment
            tempUtility.commitFiles();
            for(ContentVersion tempCV : tempUtility.getListofContentVersions())
            {
                attachmentList.add(tempCV.Id);
            }
            //AMM87
            attachment = null;
        }

        aBody=null;
        aContentType=null;
        aFileName=null;

        return null;
    }

    /* Get PDF as blob */
    public Blob getQuoteAsPDFBlob() {
        PageReference pdf = new PageReference('/apex/' + emailPageName);    // BLL18c change from CQ_PDF2 to emailPageName
        pdf.getParameters().put('id', string.valueOf(deal.Id));
     
        // the contents of the attachment from the pdf
        Blob body;
        
        try {
          // returns the output of the page as a PDF
          body = pdf.getContentAsPDF();
          
        } catch (VisualforceException e) {
          body = null;
        }
        return body;
    }
    
    /* Supporting Methods */
    public Messaging.EmailFileAttachment AttachPDF(Blob body) {
        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        attach.setContentType('application/pdf');
        attach.setFileName('Proposal_'+deal.Name+'.pdf');
        attach.setInline(false);
        attach.Body = body;
        
        return attach;
    }   

        // AMM97
    //public List<Attachment> getreferenceAttachments() {
        //return [Select Id, Name from Attachment where Id IN:attachmentList limit 20];
    public List<ContentVersion> getreferenceAttachments() {
        return [SELECT Id, Title, FileType, VersionData FROM ContentVersion WHERE Id IN :attachmentList LIMIT 20];
        // AMM97
    }
    // BLL52a end

	// BLL91
	public void approveVA() {
		System.debug('approveVA');
		deal.VA_Paperwork_Approved__c = true;
		deal.VA_Paperwork_ApprovalDT__c = DateTime.now();
		deal.VA_Paperwork_Approver__c = UserInfo.getUserId();
        Deal_UpdateControl.updateVAApproval(deal);
	}
	public void revokeVA(){ 
		System.debug('revokeVA');
		deal.VA_Paperwork_Approved__c = false;
		deal.VA_Paperwork_ApprovalDT__c = DateTime.now();
		deal.VA_Paperwork_Approver__c = UserInfo.getUserId();
        Deal_UpdateControl.updateVAApproval(deal);
	}
	// BLL91 end

}