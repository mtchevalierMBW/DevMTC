/**
 * AvaTax_MBW
 * Tested by: AvaTax_MBW_TEST
 * Programmer: Bryan Leaman (with starting code from DealerTeam)
 * Date: 2015-11-06
 * 
 * Code coverage:
 *	2017-10-05	78% (1026/1313)
 *	2017-10-10	78% (1027/1316)
 *	2017-11-28	77% (1032/1332)
 *  2018-01-11	79% (1073/1353)
 *	2018-01-30	76% (1180/1552)
 *	2018-03-30	75% (1191/1573)
 *	2018-05-29	79% (1283/1615)
 *	2018-06-15	78% (1286/1630)
 *	2019-03-22	78%	(1327/1689)
 *	2019-09-13	78%	(1328/1699)
 *
 * Usage:
 *	AvaTax_MBW taxobj = new AvaTax_MBW();
 *	taxobj.getInstance{Object}Id(Id objid);
 *	taxobj.calculateTax();
 *	taxobj.save{Object}TaxDetail();
 *	taxobj.save{Object}TaxHeader();
 * Service estimates:
 *	AvaTax_MBW.TaxResults rslt = taxobj.summarizeTaxResults();
 *
 * NOTE: For vehicle sales, there's something odd about how the Avalara API works with Source/Destination  
 * codes at the line level. The "Destination" code is set to either Store or Customer to determine
 * the tax rate for the line. For equipment-only sales, both source and destination addresses are the store's
 * address, so it doesn't matter what the Destination Code says.
 *
 *	Date		Programmer	Mod# - Description 
 *	----------	----------	------------------------------------------------------------------------
 *	2015-11-13	B. Leaman   Written. 
 *	2015-12-30	B. Leaman   BLL1 - If posted prior to document date, update document date to today.
 *	2016-01-05	B. Leaman   BLL2 - Support for combining conversion and added equipment with chassis/conversion.
 *	2016-01-20	B. Leaman	BLL3 - Support for fair market value instead of chassis; service.taxexemptservice; // NO: deal.donotcollecttax;
 *	2016-01-30	B. Leaman	BLL4 - Support for chassis taxed at store (for Virginia w/ special vehicle sales tax rate);
 *					 		Chassis-less-trade for dealer tax; luxury item tax; also document fee at store for Virginia;
 *	2016-02-02	B. Leaman	BLL5 - Don't store tax results for jurisdictions with 0% or $0 taxable.
 *	2016-02-10	B. Leaman	BLL6 - Taxable amount in Avalara should be the total before taxes.
 *	2016-02-22	B. Leaman	BLL7 - Need to truncate customer name to 50 chars.
 *	2016-03-25	B. Leaman	BLL8 IT#22404 - Vehicle delivery at store (tax at store) flag on proposals for CA sales to AZ.
 *							Also submit all ROs, even if internal or warranty, but make those NT.
 *	2016-04-21	B. Leaman	BLL9 - Special handling of FMV for Georgia.
 *  2016-05-05	B. Leaman	BLL10 IT#24453 - Split labor on kits - Labor is always taxed at the store when split from parts.
 *	2016-05-05	B. Leaman	BLL11 - Support for SC maximum taxable
 *	2016-05-06	B. Leaman 	BLL12 - Equipment-only tax at store, not customer?
 *	2016-05-09	B. Leaman	BLL13 - Need to use store-level rules for store items, Customer rules for customer items.
 *							Also switch how origin/destination are set so it looks better in Avalara.
 *	2016-05-10	B. Leaman	BLL14 - combine added equipment with conversion and conversion with chassis when there is no conversion.
 *	2016-05-11	B. Leaman	BLL15 IT#23750 - return buyer county when available
 *	2016-05-18	B. Leaman	BLL16 - NMEDA fees handled separately
 *	2016-05-20	B. Leaman	BLL17 - Don't delete tax rows if you can't insert new ones (due to record lock on proposal). 
 *	2016-05-20	B. Leaman	BLL18 - getter for whether to show part/labor split or not.
 *	2016-05-24	B. Leaman	BLL19 IT#25047 - Document fee taxable only for New and Fleet vehicle New_Used_Other__c setting.
 *							* Will not work with "CombineDocFeeWithChassis" the way it's currently implemented. *
 *	2016-06-14	B. Leaman	BLL20 - Avalara identifies some states as origin-sourced (tax at store location instead of customer).
 *							Add "origin sourcing" flag to tax rules and if set, need to be setting OriginCode instead of DestinationCode to control tax calcs.
 *	2016-06-29	B. Leaman	BLL21 - Fleet vehicles are used because we have the titles. (Per Janeen & Deeanna)
 *	2016-06-30	B. Leaman	BLL22 additional debugging info, Fix issue when destination-sourced IT#27507
 *	2016-06-30	B. Leaman	BLL23 - combine conversion discount with conversion - always.
 *	2016-07-05	B. Leaman	BLL24 - Do not use yet - may not be valid: VA grant for conversion (1394) needs to reduce tax in Illinois (where conversion is taxed)
 *	2016-07-05	B. Leaman	BLL25 - IT#17795 - NY trade-in chassis value only reduces chassis. Not yet set up for conversion value reducing conv+added equip -- maybe unnecessary.
 *	2016-07-07	B. Leaman	BLL26 - IT#27891 - For Illinois - conversion at store and added equipment at store flags.
 *	2016-07-07	B. Leaman	BLL27 - IT#28034 - Flag to not tax out-of-state deals for states we have nexus in. 
 *							IT#27978 - Adjust special case for Georgia: Fair Market Value/New Price if Greater
 *	2016-07-08	B. Leaman	BLL28 IT#27853 - Indiana tax is based on a reciprocal agreement and depends on the store's state.
 *							Combining customer & store state in the out-of-state tax rule lookup so each combination
 *							(IL->IN, OH->IN, MI->IN).
 *	2016-07-14	B. Leaman	BLL29 - Include tax exemption number in hash (to determine if taxes need to be recalc'd).
 *	2016-07-18	B. Leaman	BLL30 IT#28594 - Michigan trade-in not allowed on out-of-state deals (non-Michigan dealers)
 *	2016-07-21	B. Leaman	BLL31 - Suport for protection products taxing differently when NOT part of a vehicle sale. (Ohio)
 *	2016-08-23	B. Leaman	BLL32 IT#30500 - "Do not collect out of state tax" flag was not always working
 *	2016-08-25	B. Leaman	BLL33 - Allow tax code override for specific misc charges
 *	2016-08-29	B. Leaman	BLL34 - Exemption flag for conversion & line items.
 *	2016-09-26	B. Leaman	BLL35 - Need to check proposal type for equipment only for override on ESC tax overrides!
 *	2016-09-27	B. Leaman	BLL36 - Don't just use first 2 chars of state name for customer/destination tax rules. We're getting
 *							Massachusetts (MA) when the state is Maine. Instead, split on dash character '-' (for IL-OH, IL-MI, etc support).
 *	2016-09-06	B. Leaman	BLL37 - Origin sourcing is fouling up the "Do Not Tax Out of State" flag. Change method - set customer tax rules to NT for out-of-state
 *							when "Do not collect out of state taxes" flag is set. Also eliminate try {} catch(Exception e) {throw new ___Exception();} constructs.
 *							No need to catch exception if the only reaction is to throw it again.
 *	2016-10-24	B. Leaman	BLL38 - half-adjust lines
 *	2016-11-21	B. Leaman	BLL39 - Do Not Collect Out Of State Taxes adjustment.
 *	2016-11-29	B. Leaman	BLL40 - Support for uncommitting ROs (or other documents) (uncomment the adjusttax routine).
 *	2016-12-20	B. Leaman	BLL41 - Record RO tax calc date/time even if there were no lines to calculate. Not filling in the date/time is preventing
 *							move to Cashier status.
 *	2016-12-29	B. Leaman	BLL42 - Replace custom lookups with managed versions (Deal obj)
 *	2017-01-24	B. Leaman	BLL43 - Don't pull customer rules if there is no customer state; use new dealerteam street field from location instead of address field.
 *	2017-02-21	B. Leaman	BLL44 - Combined commercial/retail proposal processes; use title address if specified;
 *	2017-03-21	B. Leaman	BLL45 - For DME/Other - prep to use Delivery information for tax jurisdiction;  
 *							Also handle "Tax At Store" flags properly when state is origin sourced.
 *	2017-04-21	B. Leaman	BLL46 - Protection products w/ origin sourcing was not working. 
 *	2017-06-02	B. Leaman	BLL47 - New protection products.
 * 	2017-06-09	B. Leaman	BLL48 - Lease sales tax to be paid monthly with lease option.
 *	2017-07-06	B. Leaman	BLL49 - reduce doc fee if trade exceeds chassis; segregate chassis & conversion tax summary
 *	2017-10-05	B. Leaman	BLL50 - Fix prices on aftermarket lines when qty>1 and handle qty<0 too.
 *	2017-10-10	B. Leaman	BLL51 - tax at store for protection products needs to use store's tax rules for them.
 *	2017-11-15	B. Leaman	BLL52 - Invalidate taxes calculated in a previous month in case of rate changes.
 *	2017-11-17	B. Leaman	BLL53 - Tax code override by proposal type.
 *	2017-11-28	B. Leaman	BLL54 - Don't send email notification on postServiceFuture error when doc cannot be found
 *							and amount is $0.
 *	2017-12-14	B. Leaman	BLL55 - When trade-in tax code doesn't match doc fee tax code, don't reduce doc fee taxable.
 *	2017-12-19	B. Leaman	BLL56 - Use proposal's drop-ship address instead of customer address (in case it's different).
 *	2017-12-21	B. Leaman	BLL57 - Use correct sales tax overrides for out-of-state sales (store's overrides)
 *							Don't indicate out-of-date tax calc if document date <= today (see BLL52).
 *	2018-01-19	B. Leaman	BLL58 - support for service estimates; fix misc chg override on ROs.
 *	2018-03-14	B. Leaman	BLL59 - handle 1394 with extra text after "1394";
 							// not yet: handle auto-grant in 3rd party payor line;
 *	2018-04-27	B. Leaman	BLL60 - Don't instantiate a valid tax request with no proposal id (new proposal).
 *	2018-05-25	B. Leaman	BLL61 - Support for required document/certification from client for tax reduction. 
 *	2018-07-25	B. Leaman	BLL62 - Do Not Tax flag (commercial or out-of-state consumer) not working on ESCs (and other overrides).
 *	2018-10-18	B. Leaman	BLL63 W-000461 - reduce SOQL queries by using singletons for unchanging data (organization).
 *	2019-03-22	B. Leaman	W-000626 BLL64 - Ability to switch labor tax code based on having *any* taxable parts on the RO;
 *							W-000628 - Do not collect out of state flag prevented tax on warranty (in-state)
 *	2019-09-13	B. Leaman	W-000753 BLL65 - Conversion on customer-owned chassis should be taxed like an equipment sale. (N. Carolina et al)
 *	2019-11-14	B. Leaman	W-000693 BLL66 - NC allows conversion price to be included with Chassis for trade-in limits
 *	2019-12-31	B. Leaman	BLL67 - FinancialProductsOnly override capability for ESCs
 * 
 * Notes:
 * To enable/disable automated calcs & trigger restrictions (can't push w/o tax calc): 
 * MW_Trigger_Controls AvataxDeal
 * MW_Trigger_Controls AvataxService
 * MW_Trigger_Controls AvataxRental
 * 
 * MW_TriggerControls__c AvataxDeal = MW_TriggerControls__c.getInstance('AvataxDeal');
 * if (AvataxDeal==null || AvataxDeal.Enabled__c) {
 *
 */

/** Testing via execute anonymous:
dealer__Deal__c deal = [
    select Id from dealer__Deal__c where Name='81'
    limit 1
];
AvaTax_MBW tax = AvaTax_MBW.getInstanceDealId(deal.Id);
tax.forceTestEndpoint=true;
tax.debugTaxRequestLines();
tax.summarizeRequestLines();
tax.debugRequestSummary();
System.debug(tax.getHash());
tax.calculateTax();
tax.summarizeTaxResult();
tax.debugTaxResultSummary();
System.debug(tax.gettaxRslt);
tax.saveDealTaxDetail();
tax.saveDealTaxHeader();
AvaTax_MBW.TaxResults rslt = tax.summarizeTaxResults();
String rsltStr = JSON.serialize(rslt);
System.debug(rsltStr);
AvaTax_MBW.TaxResults rslt2 = (AvaTax_MBW.TaxResults) JSON.deserialize(rsltStr, AvaTax_MBW.TaxResults.class);
System.debug(rslt2);
*/

// Notes:
// c2g__CODASalesTaxStatus__c, c2g__CODAExemptionCertificate__c - Taxable, Exempt, Exempt for Qualifying Products, tax exempt cert.
// use custom fields SalesTaxStatus__c & ExemptionCertificate__c instead -- for visibility w/out FF license.
// Avatax "Company" = 'WMK' but may need to be separate companies according to FF companies?

public with sharing class AvaTax_MBW {

    public boolean forceTestEndpoint = false;
    public boolean AutomaticCalc = true;
    public Decimal TotalTax=0.00;
    public Decimal TaxableAmt=0.00;
    public String County;	// BLL15a

	// BLL49a
	Decimal ChassisTaxable = 0.00;
	Decimal ChassisRate = 0.00;
	Decimal ChassisTax = 0.00;
	Decimal ConversionTaxable = 0.00;
	Decimal ConversionRate = 0.00;
	Decimal ConversionTax = 0.00;
	// For Alabama (maybe others) sum up county taxes
	Decimal CountyRate = 0.00;
	Decimal CountyTaxable = 0.00;
	Decimal CountyTax = 0.00;
	// BLL49a end
	
	public boolean dealsplitlabor = false;	// BLL10a
	public boolean useTitleAddress = false;	// BLL48a
	public boolean useDropShipAddress = false;	// BLL56a

    String objectType;
    Id objectId;
    AvaTax__c avatax_settings = AvaTax__c.getOrgDefaults();
    public TaxSvc.GetTaxRequest gettaxReq;
    Organization org = null;
    public TaxSvc.GetTaxResult gettaxRslt = null;
    TaxRuleSetting__c taxrules = null;
    TaxRuleSetting__c storerules = null;	// BLL13a
    TaxRuleSetting__c customerrules = null;	// BLL13a - only different from storerules if out-of-state vehicle sale
     
    Map<String,TaxRuleOpCodeSetting__c> taxRuleOpCodeMap = new Map<String,TaxRuleOpCodeSetting__c>();
    Map<String,TaxRuleOverride__c> taxRuleOverrides = new Map<String,TaxRuleOverride__c>();
    Map<String,TaxRuleOverride__c> storeRuleOverrides = new Map<String,TaxRuleOverride__c>();	// BLL13a

    Map<String,TaxResultSummary> taxSummary = new Map<String,TaxResultSummary>();  // BLL3c
    Map<String,Decimal> reqSummary = null;
    public TaxSvc.CommitTaxRequest committaxReq;
    public TaxSvc.CommitTaxResult committaxRslt;
    public TaxSvc.CancelTaxRequest canceltaxReq;
    public TaxSvc.CancelTaxResult canceltaxRslt;
    public TaxSvc.AdjustTaxRequest adjusttaxReq;
    public TaxSvc.AdjustTaxResult adjusttaxRslt;    
    public TaxSvc.PostTaxRequest posttaxReq;
    public TaxSvc.PostTaxResult posttaxRslt;
    Set<String> NewVehicleCodes = new Set<String>{'New'};	// BLL21c remove Fleet - we have title, so they're used
    Set<String> MakesAlwaysUsed = new Set<String>{'Toyota','Honda'};

    //TODO: Separate companies like financial force?
    private String AVATAX_COMPANY = 'WMK';

    dealer__Dealer_Location__c store; 
    StreetAddress custaddr; 
    StreetAddress storeaddr;

	// BLL44a 
	private Set<String> vehicleSaleTypes = new Set<String>{'Retail Vehicle Sale','Wholesale','Chassis/Conversion'};
	public boolean isVehicleSale {get;private set;}
	public boolean isCommercial {get;private set;}
	// BLL44a end 


    // constructor
    //-----------------------------
    public AvaTax_MBW() {
    	System.debug('*** AvaTax_MBW ***');	// BLL43a
        AVATAX_COMPANY = avatax_settings.CompanyCode__c!=null ? avatax_settings.CompanyCode__c : AVATAX_COMPANY;
        if (isSandbox() || forceTestEndpoint) {
            AVATAX_COMPANY = avatax_settings.Test_CompanyCode__c!=null ? avatax_settings.Test_CompanyCode__c : AVATAX_COMPANY;
        //} else {
        }       
    }
    
    
    // getInstanceDealId
    //-----------------------------
    public static AvaTax_MBW getInstanceDealId(Id dealId) {
        AvaTax_MBW cls = new AvaTax_MBW();
        //BLL37d try {
            if (dealId!=null) cls.setupFromDealId(dealId);	// BLL60c
        //BLL37d } catch(Exception e) { cls = null;  throw new AVATaxException(e.getMessage());  }
        
        return cls;
    }
    // getInstanceDeal
    //-----------------------------
    public static AvaTax_MBW getInstanceDeal(dealer__Deal__c deal) {
        AvaTax_MBW cls = new AvaTax_MBW();
        //BLL37d try {
            if (deal.Id!=null) cls.setupFromDealObj(deal);	// BLL60c
        //BLL37d } catch(Exception e) { cls = null;  throw new AVATaxException(e.getMessage());  }
        
        return cls;
    }


    // getInstanceSROId
    //-----------------------------
    public static AvaTax_MBW getInstanceSROId(Id sroId) {
        AvaTax_MBW cls = new AvaTax_MBW();
        //BLL37d try {
            cls.setupFromRepairOrderId(sroId);
        //BLL37d } catch(Exception e) { cls = null;  throw new AVATaxException(e.getMessage());  }
        return cls;
    }
    
    // getInstanceSRO
    //-----------------------------
    public static AvaTax_MBW getInstanceSRO(dealer__Service_Repair_Order__c sro) {
        AvaTax_MBW cls = new AvaTax_MBW();
        //BLL37d try {
            cls.setupFromRepairOrderObj(sro);
        //BLL37d } catch(Exception e) {  cls = null;  throw new AVATaxException(e.getMessage());  }
        return cls;
    }
    
      
    // getInstanceRentalId
    //-----------------------------
    public static AvaTax_MBW getInstanceRentalId(Id raId) {
        AvaTax_MBW cls = new AvaTax_MBW();
        //BLL37d try {
            cls.setupFromRentalId(raId);
        //BLL37d } catch(Exception e) {  cls = null;  throw new AVATaxException(e.getMessage());  }
        return cls;
    }

    // getInstanceRental
    //-----------------------------
    public static AvaTax_MBW getInstanceRental(dealer__Rental_Agreements__c ra) {
        AvaTax_MBW cls = new AvaTax_MBW();
        //BLL37d try {
            cls.setupFromRentalObj(ra);
        //BLL37d } catch(Exception e) {  cls = null;  throw new AVATaxException(e.getMessage());  }
        return cls;
    }


    // setupDeal
    //--------------------------------
    public void setupFromDealId(Id dealId) {
        dealer__Deal__c deal = [
            select Id, Name, RecordTypeId, dealer__Store_Location__c, dealer__Buyer__c, dealer__Buyer__r.Name, 
                dealer__Buyer_Address__c, dealer__Buyer_City__c, dealer__Buyer_State__c, dealer__Buyer_Postal_Code__c,
                dealer__Vehicle__c, dealer__Vehicle__r.Name, dealer__Vehicle__r.New_Used_Other__c, dealer__Vehicle__r.dealer__Make__c,  
                Proposed_Delivery_Date__c,
                Chassis_Price__c, ChassisTaxable__c, Conversion_Taxable__c, Conversion_Price__c, FairMarketValue__c, // BLL3c
                GVW_GVWR__c, Tire_Fee__c, Smog_Fee__c, Electronic_Filing_Fee__c, dealer__Doc_Fee__c, dealer__License_Fee__c,
                Registration_Title_Fee__c, Smog_Cert__c, Government_Price_Concession__c, // BLL44c GPC 
                dealer__Rebate__c, Rebate_Description__c, Rebate_2__c, Rebate_2_Description__c, Rebate_3__c, Rebate_3_Description__c,
                MBW_Rewards__c, Conversion_Discount__c, AutoGrant__c, dtmob__Auto_Grant_Payor__c, 	// BLL42c Auto_Grant_Payee__c, 
                Third_Party_Pay_1__c, dealer__Deferred_Note_1__c, dealer__Deferred_Down_1__c,	// BLL24a
                Third_Party_Pay_2__c, dealer__Deferred_Note_2__c, dealer__Deferred_Down_2__c,	// BLL24a
                Third_Party_Pay_3__c, dealer__Deferred_Note_3__c, dealer__Deferred_Down_3__c,	// BLLa
                dealer__Sales_Tax__c, Total_Price__c, // BLL3c , DoNotCollectTax__c
                DeliveryAtStore__c, dealer__Deal_Type__c,	// BLL8a, BLL11c dealer__Deal_Type__c
                ConversionExempt__c, // BLL34a
                dealer__Delivery_Street__c, dealer__Delivery_City__c, dealer__Delivery_State__c, DeliveryPostalCode__c,	// BLL45a
                dealer__Business_Address__c, dealer__Business_City__c, dealer__Business_State__c, dealer__Business_Postal_Code__c,   // BLL44a
				Vehicle_Source__c, // BLL65
                DoNotCollectTax__c, HaveRequiredTaxCert__c	// BLL27a, BLL61c
            from dealer__Deal__c
            where Id=:dealId
        ];
        setupFromDealObj(deal);
    }
    
    // setupFromDealObj
    // assumes all required fields have been retrieved!
    //-------------------------------
    public void setupFromDealObj(dealer__Deal__c deal) {
        objectType = deal.getSObjectType().getDescribe().getName();
        objectId = deal.Id;
        Account a=null;
        try {
            a = [
            select BillingStreet, BillingCity, BillingState, BillingPostalCode,
                SalesTaxStatus__c, ExemptionCertificate__c  // c2g__CODASalesTaxStatus__c, c2g__CODAExemptionCertificate__c
            from Account
            where Id=:deal.dealer__Buyer__c
            limit 1 
        ];
        } catch(Exception e) {}

        setStore(deal.dealer__Store_Location__c);

		// BLL65
		String dealType = deal.dealer__Deal_Type__c;
		if (!String.isBlank(deal.Vehicle_Source__c) && deal.Vehicle_Source__c=='Customer Owned') {
			dealType = 'Equipment Only';
		}
		// BLL65 end
		// BLL44a
        // BLL65
		// isVehicleSale = vehicleSaleTypes.contains(deal.dealer__Deal_Type__c);
		isVehicleSale = vehicleSaleTypes.contains(dealType);
		// BLL65 end
		Map<String, Schema.RecordTypeInfo> DealRcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();
		Schema.RecordTypeInfo CommRtInfo = DealRcdTypes.get('Commercial');
		Id commRtId = CommRtInfo!=null ? CommRtInfo.getRecordTypeId() : null;
		isCommercial = deal.RecordTypeId==CommRtId;
		// BLL44a
        
        // Only use customer address for Vehicle sales
        //BLL44d Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();
        //System.debug(RcdTypes);
        
        String OutOfState = null;
        boolean OutOfStateSale = false;	// BLL30a
        
        //BLL44d Schema.RecordTypeInfo vehicleSaleRt = RcdTypes.get('Retail Vehicle Sale');
        //BLL44d Schema.RecordTypeInfo wholesaleRt = RcdTypes.get('Wholesale');
        //BLL44d if ((vehicleSaleRt!=null && deal.RecordTypeId==vehicleSaleRt.getRecordTypeId())
        //BLL44d     || (wholesaleRt!=null && deal.RecordTypeId==wholesaleRt.getRecordTypeId())) {
		useTitleAddress = !String.isBlank(deal.dealer__Business_Address__c)
			&& !String.isBlank(deal.dealer__Business_City__c)
			&& !String.isBlank(deal.dealer__Business_State__c)
			&& !String.isBlank(deal.dealer__Business_Postal_Code__c);   // BLL44a
		useDropShipAddress = deal.dealer__Deal_Type__c=='DME/Other' 
			&& !String.isBlank(deal.dealer__Delivery_Street__c)
			&& !String.isBlank(deal.dealer__Delivery_City__c)
			&& !String.isBlank(deal.dealer__Delivery_State__c)
			&& !String.isBlank(deal.DeliveryPostalCode__c);   // BLL56a
		
        if (isVehicleSale) {	// BLL44a
            if (deal.DeliveryAtStore__c==false) {	// BLL8a
            	if (useDropShipAddress) {	// BLL56a
            		setCustAddr(new StreetAddress(deal.dealer__Delivery_Street__c, deal.dealer__Delivery_City__c, deal.dealer__Delivery_State__c, deal.DeliveryPostalCode__c));	// BLL56a	
            	} else if (useTitleAddress) {	// BLL44a
            		setCustAddr(new StreetAddress(deal.dealer__Business_Address__c, deal.dealer__Business_City__c, deal.dealer__Business_State__c, deal.dealer__Business_Postal_Code__c));	// BLL44a	
            	} else {	// BLL44a
        	    	setCustAddr(new StreetAddress(deal.dealer__Buyer_Address__c, deal.dealer__Buyer_City__c, deal.dealer__Buyer_State__c, deal.dealer__Buyer_Postal_Code__c));
            	}	// BLL44a
				try {
	        	    // BLL28d OutOfState = (custaddr!=null && custaddr.State!=null && custaddr.State!=storeaddr.State) ? custaddr.State : null;
	        	    OutOfState = (custaddr!=null && custaddr.State!=null && custaddr.State!=storeaddr.State) ? custaddr.State+'-'+storeaddr.State : null;	// BLL28a
	        	    System.debug('Out of state designation = ' + OutOfState);
				} catch(Exception e) {}
            }	// BLL8a
        }
        
        // BLL45a
        if (deal.dealer__Deal_Type__c=='DME/Other' && deal.dealer__Delivery_Street__c!=null && deal.dealer__Delivery_City__c!=null && deal.dealer__Delivery_State__c!=null & deal.DeliveryPostalCode__c!=null) {
			setCustAddr(new StreetAddress(deal.dealer__Delivery_Street__c, deal.dealer__Delivery_City__c, deal.dealer__Delivery_State__c, deal.DeliveryPostalCode__c));
			OutOfState = (custaddr!=null && custaddr.State!=null && custaddr.State!=storeaddr.State) ? custaddr.State+'-'+storeaddr.State : null;
        }

        // Load up tax rules
        customerrules = getTaxRules(deal.dealer__Store_Location__c, OutOfState);	// BLL13c was taxrules
		OutOfStateSale = customerrules!=null && storerules!=null && customerrules.Id!=storerules.Id;	// BLL30a

		//BLL37a if not collecting out-of-state taxes, then set all fields on out-of-state rules to 'NT'
		// No need to change overrides, as the only ones are for equipment-only deals, which are never out-of-state
		if (isVehicleSale && deal.DoNotCollectTax__c==true && (OutOfState!=null || isCommercial) ) {	//BLL44c deal.dealer__Deal_Type__c!='Equipment Only Sale') {
		 	System.debug('*** NOT COLLECTING TAX ON OUT-OF-STATE DEAL ***');
			customerrules.Chassis__c='NT'; 
			customerrules.ChassisTX__c='NT';
			customerrules.Conversion__c='NT'; 
			customerrules.ConversionTX__c='NT';
			customerrules.AdaptiveEquipment__c='NT'; 
			customerrules.AdaptiveEquipmentTX__c='NT';
			customerrules.AdaptiveEquipLabor__c='NT'; 
			customerrules.AdaptiveEquipLaborTX__c='NT';
			customerrules.AdaptiveEquipSublet__c='NT'; 
			customerrules.AdaptiveEquipSubletTX__c='NT';
			customerrules.NMEDA__c='NT'; 
			customerrules.NMEDA_TX__c='NT';
			customerrules.ServiceContract__c='NT'; 
			customerrules.GAP__c='NT'; 
			customerrules.RoadsideProtection__c='NT'; 
			customerrules.TireWheel__c='NT';	// BLL45a 
			customerrules.DiamondFusion__c='NT'; 
			customerrules.AutoGrant__c='NT'; 
			customerrules.Rebate__c='NT'; 
			customerrules.MobilityWorksRebate__c='NT'; 
			customerrules.ChassisDiscount__c='NT';
			customerrules.ConversionGrant__c='NT'; 
			customerrules.DocumentFee__c='NT'; 
			customerrules.ElectronicFilingFee__c='NT';
			customerrules.GVW_GVWR__c='NT'; 
			customerrules.LicenseFee__c='NT'; 
			customerrules.RegistrationFee__c='NT';
			customerrules.SmogCertificate__c='NT'; 
			customerrules.SmogFee__c='NT'; 
			customerrules.TireFee__c='NT';
			customerrules.TradeIn__c='NT';  
			customerrules.ChassisLessTrade__c='NT';
			customerrules.GPC__c='NT';	// BLL44a
			// BLL39d This is causing Tennesee taxes on Georgia sale if "Do not collect out of state taxes" is checked.
			// Not sure why I did this ... Just because out of state says tax is calculated at the store doesn't
			// mean store's state treats it that way.
			//if (storerules!=null) {
			//	customerrules.ServiceContract_AtStore__c=storerules.ServiceContract_AtStore__c;	
			//	customerrules.GAP_AtStore__c=storerules.GAP_AtStore__c;
			//	customerrules.RoadsideProt_AtStore__c=storerules.RoadsideProt_AtStore__c;	
			//	customerrules.DiamondFusion_AtStore__c=storerules.DiamondFusion_AtStore__c;  
			//	customerrules.Chassis_AtStore__c=storerules.Chassis_AtStore__c; 
			//	customerrules.ChassisLessTrade_AtStore__c=storerules.ChassisLessTrade_AtStore__c; 
			//	customerrules.DocumentFee_AtStore__c=storerules.DocumentFee_AtStore__c;
			//	customerrules.Conversion_AtStore__c=storerules.Conversion_AtStore__c; 
			//	customerrules.AddedEquipment_AtStore__c=storerules.AddedEquipment_AtStore__c;
			//}
			// BLL39d end
			
			// BLL62a handle the overrides too
			for(TaxRuleOverride__c ovr : taxruleoverrides.values()) {
				ovr.TaxCodeTX__c = 'NT';
            	ovr.TaxCode__c = 'NT';
            	ovr.TaxCodeWithCert__c = 'NT';	
			}
			// BLL64 - only commercial can mark everything non-taxable, for retail, in-state rules still apply
			if (isCommercial) {
			// BLL64 end
				for(TaxRuleOverride__c ovr : storeruleoverrides.values()) {
					ovr.TaxCodeTX__c = 'NT';
	            	ovr.TaxCode__c = 'NT';
	            	ovr.TaxCodeWithCert__c = 'NT';	
				}
			// BLL64
			}
			// BLL64 end
			// BLL62a end
		}
		// BLL37a end

        taxrules = customerrules!=null ? customerrules : storerules;	// BLL13a
		if (customerrules==null) taxruleoverrides = storeruleoverrides;	// BLL57a 
        System.debug(customerrules); // BLL13a
        System.debug(storerules);	// BLL13a
        
        boolean newVehicle = false;
        if (deal.dealer__Vehicle__c!=null && NewVehicleCodes.contains(deal.dealer__Vehicle__r.New_Used_Other__c)) newVehicle = true;
        if (MakesAlwaysUsed.contains(deal.dealer__Vehicle__r.dealer__Make__c)) newVehicle = false;
		System.debug('New vehicle = ' + (newVehicle?'true':'false'));

        // Build header for tax request
        Date txnDate = deal.Proposed_Delivery_Date__c;
        if (txnDate==null) txnDate = Date.today();  // Default to today if delivery date is missing
        gettaxReq = getAvataxRequest(
            AVATAX_COMPANY,         // company
            'Proposal ' + deal.Name,    // document name
            (String) deal.dealer__Buyer__r.Name,    // customer name
            txnDate,    // document date
            deal.dealer__Buyer__c       // reference#?
        );
        gettaxReq.LocationCode = store!=null ? store.dealer__Company_Number__c : null;
        if (taxrules.OriginSourced__c) gettaxReq.OriginCode = 'Store';	// BLL22a
        // BLL12a
        //BLL44d if (deal.dealer__Deal_Type__c=='Equipment Only Sale') {

        // BLL45a sales with delivery to customer address
		if (deal.dealer__Deal_Type__c=='DME/Other' && deal.dealer__Delivery_Street__c!=null && deal.dealer__Delivery_City__c!=null && deal.dealer__Delivery_State__c!=null & deal.DeliveryPostalCode__c!=null) {
            gettaxReq.OriginCode = 'Customer';
            gettaxReq.DestinationCode = 'Customer';
		} else {
		// BLL45a end
	        if (!isVehicleSale) {	// BLL44a
	            gettaxReq.OriginCode = 'Store';
	            gettaxReq.DestinationCode = 'Store';
	            // BLL13a
	            if (storerules!=null) {
	            	customerrules = storerules;	
	            	taxrules = storerules;
	            	taxRuleOverrides = storeRuleOverrides;
	            } else { customerrules = taxrules; }
	            // BLL13a end 	
	        }
        }	// BLL45a
        // BLL12a
        if (a!=null && a.SalesTaxStatus__c=='Exempt') {
            if (a.ExemptionCertificate__c!=null) {
                gettaxReq.ExemptionNo = a.ExemptionCertificate__c;
            } else {
                gettaxReq.ExemptionNo = 'OnFile';
            }
        }

        // Gather additional info needed
        // Trades
        List<dealer__Trade_In__c> trades = [
            select Id, Name, dealer__Trade_Allowance__c, dealer__ACV__c, dealer__Pay_Off_Amount__c, Net_Value__c,
            	Chassis_Allowance__c, Conversion_Allowance__c, Mobility_Equiped__c	// BLL25a
            from dealer__Trade_In__c
            where dealer__Car_Deal__c=:deal.Id
        ];
        
        // If no trade-ins allowed for out-of-state, eliminate trades information
        if (taxrules.NoTradeOutOfState__c && OutOfStateSale) trades.clear();	// BLL30a
         
        Decimal totalTrade = 0.00;
        Decimal totalTradeChassis = 0.00;	// BLL25a
        Decimal tradeChassisValueRemaining = 0.00;	// BLL49a
        Decimal totalTradeConversion = 0.00;	// BLL25a
        String tradeDescr = '';
        String sep = '';
        for (dealer__Trade_In__c t : trades) {
            tradeDescr += sep + t.Name;
            sep = '; ';
            totalTrade += t.dealer__Trade_Allowance__c;
            // BLL25a
            if (taxrules.SeparateChassisConversionAllowance__c && t.Chassis_Allowance__c!=null && t.Mobility_Equiped__c!='No') {
            	totalTradeChassis += t.Chassis_Allowance__c;
            } else {
            	totalTradeChassis += t.dealer__Trade_Allowance__c;
            }
            if (!taxrules.SeparateChassisConversionAllowance__c && t.Mobility_Equiped__c=='Yes' && t.Conversion_Allowance__c!=null) {
            	totalTradeConversion += t.Conversion_Allowance__c;
            }
            // BLL25a end
        }
        tradeChassisValueRemaining = totalTradeChassis;	// BLL49a
        System.debug('tradeChassisValueRemaining='+String.valueOf(tradeChassisValueRemaining));	// BLL66
        // aftermarket items
        List<dealer__After_Market__c> items = [
            select Name, dealer__Description__c, Taxable__c, dealer__Sale_Price__c, dealer__Labor_Hours__c, Labor_Hours__c, dealer__Labor_Sale__c,	// BLL10c dealer__Labor_Hours__c, dealer__Labor_Sale__c
            	dealer__Quantity__c, ExtendedPrice__c, ExtendedLaborPrice__c,	// BLL50a
            	dealer__Parts_Kit__c, TaxExempt__c,	// BLL34c add TaxExempt__c
            	dealer__Part__c, dealer__Part__r.dealer__Parts_Master__c, dealer__Part__r.dealer__Parts_Master__r.TaxCodeOvr__c, dealer__Part__r.dealer__Parts_Master__r.TaxCodeOvrTX__c,	// BLL54a
            	dealer__Part__r.dealer__Parts_Master__r.TaxCodeOvrWithCert__c,	// BLl61a
            	dealer__Parts_Kit__r.TaxCodeOvr__c,	dealer__Parts_Kit__r.TaxCodeOvrTX__c, dealer__Parts_Kit__r.TaxCodeOvrWithCert__c, 	// BLL61c 
            	dealer__Parts_Kit__r.Category__c, dealer__Parts_Kit__r.Category__r.TaxCodeOvr__c, dealer__Parts_Kit__r.Category__r.TaxCodeOvrTX__c, // BLL54a
            	dealer__Parts_Kit__r.Category__r.TaxCodeOvrWithCert__c	// BLL61a
            from dealer__After_Market__c
            where dealer__Car_Deal__c=:deal.Id
        ];

        // Begin generating tax request lines
        Decimal NTSaleAdjAmt = 0.00;	// BLL49a
        Decimal chassisAmt = 0.00;
        Integer lineNbr = 10;
        // Build lines for tax request
        gettaxReq.Lines = new TaxSvc.ArrayOfLine();
        gettaxReq.Lines.Line = new List<TaxSvc.Line>();
        TaxSvc.Line chassisLine; // BLL2a
        if (deal.Chassis_Price__c>0) {
            // BLL2d TaxSvc.Line line = new TaxSvc.Line();
            chassisLine = new TaxSvc.Line();
            chassisLine.TaxCode = deal.ChassisTaxable__c ? taxrules.ChassisTX__c : taxrules.Chassis__c; // BLL49a moved up from further down
            // BLL54a rearrange with default and then override if at-store
   		    chassisLine.DestinationCode = 'Customer';	// BLL13a
   		    taxrules = customerrules;	// BLL13a
            if (taxrules.Chassis_AtStore__c) {  // BLL4a
	            chassisLine.DestinationCode = 'Store';  // BLL4a
	            taxrules = storerules;	// BLL13a
            //BLL54d } else {  // BLL4a
    		    // BLL13d chassisLine.OriginCode = 'Customer';
    		    //BLL54d chassisLine.DestinationCode = 'Customer';	// BLL13a
    		    //BLL54d taxrules = customerrules;	// BLL13a
            }  // BLL4a
            if (taxrules.OriginSourced__c) {chassisLine.OriginCode=chassisLine.DestinationCode; /* blld chassisLine.DestinationCode=null;*/ }	// BLL20a
            chassisLine.No = String.valueOf(lineNbr++);
            //chassisLine.DestinationCode = gettaxReq.DestinationCode;
            chassisLine.ItemCode = 'Chassis' + ' (' + deal.dealer__Vehicle__r.New_Used_Other__c + ') ';	// BLL19c add new/used/other
            chassisLine.Description = deal.dealer__Vehicle__r.Name; 
            //BLL3d chassisLine.Amount = deal.Chassis_Price__c;
            //BLL3d chassisAmt = deal.Chassis_Price__c;
            // BLL3a

			// Fair Market Value logic
            //BLL9d chassisAmt = (taxrules.ChassisFairMarketValue__c==true && deal.FairMarketValue__c!=null) ? deal.FairMarketValue__c : deal.Chassis_Price__c;
            chassisAmt = deal.Chassis_Price__c;	// BLL9a
            System.debug('Chassis amount set to price: ' + String.valueOf(chassisAmt));
            if (taxrules.CombineDocFeeWithChassis__c && deal.dealer__Doc_Fee__c!=null && deal.dealer__Doc_Fee__c>0) { 
            	chassisAmt += deal.dealer__Doc_Fee__c;	// BLL9a
            	System.debug('Chassis amount including doc fee: ' + String.valueOf(chassisAmt)); 
            }
            if (taxrules.ChassisPriceSource__c=='Fair Market Value' && deal.FairMarketValue__c!=null) {
            	NTSaleAdjAmt += (chassisAmt-deal.FairMarketValue__c);	// BLL49a 
            	chassisAmt = deal.FairMarketValue__c;	// BLL9a
            	System.debug('Chassis amount set to Fair Market Value: ' + String.valueOf(chassisAmt));
            }
            if (taxrules.ChassisPriceSource__c=='Greater of Price or FMV' && deal.FairMarketValue__c!=null && deal.FairMarketValue__c>chassisAmt) {
            	NTSaleAdjAmt += (chassisAmt-deal.FairMarketValue__c);	// BLL49a 
            	chassisAmt = deal.FairMarketValue__c;	// BLL9a
            	System.debug('Chassis amount set to Fair Market Value (greater amt): ' + String.valueOf(chassisAmt)); 
            }
            // BLL27a
            if (taxrules.ChassisPriceSource__c=='FMV or New Sale Price if Greater' && deal.FairMarketValue__c!=null) {
				if (!newVehicle || deal.FairMarketValue__c>chassisAmt) {
	            	NTSaleAdjAmt += (chassisAmt-deal.FairMarketValue__c);	// BLL49a 
            		chassisAmt = deal.FairMarketValue__c;	// BLL9a
            		System.debug('Chassis amount set to Fair Market Value (greater amt): ' + String.valueOf(chassisAmt));
				} 
            }
            // BLL27a end

			// BLL59a - handle auto grant (4502) in 3rd party payor line
			//if (deal.AutoGrant__c==null || deal.AutoGrant__c==0) {
			//	if (deal.dealer__Deferred_Down_1__c!=null && deal.dealer__Deferred_Note_1__c!=null && deal.dealer__Deferred_Note_1__c.startsWith('4502') && deal.Third_Party_Pay_1__c!=null) {
			//		deal.AutoGrant__c = deal.dealer__Deferred_Down_1__c;
			//		deal.dtmob__Auto_Grant_Payor__c = deal.Third_Party_Pay_1__c;
			//	}
			//	if (deal.dealer__Deferred_Down_2__c!=null && deal.dealer__Deferred_Note_2__c!=null && deal.dealer__Deferred_Note_2__c.startsWith('4502') && deal.Third_Party_Pay_2__c!=null) {
			//		deal.AutoGrant__c = deal.dealer__Deferred_Down_2__c;
			//		deal.dtmob__Auto_Grant_Payor__c = deal.Third_Party_Pay_2__c;
			//	}
			//	if (deal.dealer__Deferred_Down_3__c!=null && deal.dealer__Deferred_Note_3__c!=null && deal.dealer__Deferred_Note_3__c.startsWith('4502') && deal.Third_Party_Pay_3__c!=null) {
			//		deal.AutoGrant__c = deal.dealer__Deferred_Down_3__c;
			//		deal.dtmob__Auto_Grant_Payor__c = deal.Third_Party_Pay_3__c;
			//	}
			//}	
			// BLL59a end

            chassisLine.Amount = chassisAmt;
            // BLL3a end
            // Combine 4502 into chassis because of special considerations
            if (deal.AutoGrant__c!=null && deal.AutoGrant__c!=0  && taxrules.AutoGrant_NetChassis__c==true) {
                chassisLine.Amount -= deal.AutoGrant__c;
                chassisLine.ItemCode += ' - 4502';
                chassisLine.Description += '; Grant payor id ' + deal.dtmob__Auto_Grant_Payor__c;	// BLL42c deal.Auto_Grant_Payee__c;
                if (chassisLine.Amount<0.00) NTSaleAdjAmt -= chassisLine.Amount;	// BLL49a
                if (chassisLine.Amount<0.00) chassisLine.Amount = 0.00;
                chassisAmt = chassisLine.Amount;
            	System.debug('Chassis amount reduced by 4502: ' + String.valueOf(chassisAmt)); 
            }
            // Combine GPC into chassis because of special considerations
            if (deal.Government_Price_Concession__c!=null && deal.Government_Price_Concession__c!=0  && taxrules.GPC_NetChassis__c==true) {
                chassisLine.Amount -= deal.Government_Price_Concession__c;
                chassisLine.ItemCode += ' - GPC';
                chassisLine.Description += '; GPC';
                if (chassisLine.Amount<0.00) NTSaleAdjAmt -= chassisLine.Amount;	// BLL49a
                if (chassisLine.Amount<0.00) chassisLine.Amount = 0.00;
                chassisAmt = chassisLine.Amount;
            	System.debug('Chassis amount reduced by GPC: ' + String.valueOf(chassisAmt)); 
            }

            // Combine MBW Chassis Discount into chassis because of special considerations
            //if (deal.ChassisDiscount__c!=null && deal.ChassisDiscount__c!=0  && taxrules.ChassisDiscount_NetChassis__c==true) {
            //  chassisLine.Amount -= deal.ChassisDiscount__c;
            //  chassisLine.ItemCode += ' - Discount';
            //  chassisLine.Description += '; Chassis Discount';
            //  if (chassisLine.Amount<0.00) chassisLine.Amount = 0.00;
            //  chassisAmt = chassisLine.Amount;
            //}
            
			// BLL66
            // Trade-in cannot exceed adjusted chassis amount
            //if (totalTradeChassis > chassisAmt) {	// BLL25c change to use chassis portion of trade allowance
            //    //BLL49a NTSaleAdjAmt += totalTradeChassis-chassisAmt;	// BLL49a
            //    totalTradeChassis = chassisAmt;
            //    System.debug('Trade-in value capped at remaining chassis amount: ' + String.valueOf(totalTradeChassis));
            //}
			Decimal tradeAdjLimit = chassisAmt;
            System.debug('tradeAdjLimit='+String.valueOf(tradeAdjLimit)); 
			if (taxrules.IncludeConversion_TradeIn_Limit__c && deal.Conversion_Price__c>0) {
				tradeAdjLimit += deal.Conversion_Price__c;
                System.debug('Include conversion price in trade limit');
			}
            System.debug('tradeAdjLimit='+String.valueOf(tradeAdjLimit));
            System.debug('totalTradeChassis='+String.valueOf(totalTradeChassis));
			if (totalTradeChassis > tradeAdjLimit) {
				totalTradeChassis = tradeAdjLimit;
                System.debug('Trade-in value capped at remaining chassis amount: ' + String.valueOf(totalTradeChassis));
			}
			// BLL66
	
            // Combine Trade allowances into chassis because of special considerations
            if (totalTradeChassis!=0  && taxrules.Trade_NetChassis__c==true) {	// BLL25c change to chassis portion of trade-in
            	// Apply trade-in limits even when reducing chassis!
            	if (newVehicle && taxrules.TradeLimitNew__c!=null && taxrules.TradeLimitNew__c<totalTradeChassis) {
                	totalTradeChassis = taxrules.TradeLimitNew__c;
                	tradeChassisValueRemaining = totalTradeChassis;	// BLL49a
	                System.debug('Trade limit new enforced: ' + String.valueOf(taxrules.TradeLimitNew__c));
            	}
            	if (!newVehicle && taxrules.TradeLimitUsed__c!=null && taxrules.TradeLimitUsed__c<totalTradeChassis) {
	                totalTradeChassis = taxrules.TradeLimitUsed__c;
                	tradeChassisValueRemaining = totalTradeChassis;	// BLL49a
	                System.debug('Trade limit used enforced: ' + String.valueOf(taxrules.TradeLimitUsed__c));
            	}
            	
                //BLL25d chassisLine.Amount -= totalTrade;
                tradeChassisValueRemaining -= Math.min(totalTradeChassis,chassisLine.Amount);	// BLL49a
                NTSaleAdjAmt += totalTradeChassis;	// BLL49a
                chassisLine.Amount -= totalTradeChassis;	// BLL25a
                chassisLine.ItemCode += ' - Trade(s)';
                chassisLine.Description += '; Trade-in Allowances';
                if (chassisLine.Amount<0.00) NTSaleAdjAmt-=chassisLine.Amount;	// BLL49a 
                if (chassisLine.Amount<0.00) chassisLine.Amount = 0.00;
                System.debug('Chassis amount reduced by trade-in value: ' + String.valueOf(chassisLine.Amount));
                // BLL4d moved to after ChassisLessTrade: chassisAmt = chassisLine.Amount;
            }
            //chassisLine.TaxCode = taxrules.Chassis__c;  // dealer__Rebate__c, Rebate_2__c, Rebate_3__c, Discounted?
            //BLL49d move up chassisLine.TaxCode = deal.ChassisTaxable__c ? taxrules.ChassisTX__c : taxrules.Chassis__c; // BLL3a
			if (taxrules.ChassisMinTaxable__c!=null && taxrules.ChassisMinTaxable__c>0.00
				&& chassisLine.Amount<taxrules.ChassisMinTaxable__c) {
				NTSaleAdjAmt += chassisLine.Amount - taxrules.ChassisMinTaxable__c; // BLL49a
				chassisLine.Amount = taxrules.ChassisMinTaxable__c; // BLL4a
			}

            //if (taxrules.Chassis_AtStore__c) chassisLine.DestinationCode = 'Store';	// BLL4a

            // BLL2d gettaxReq.Lines.Line.add(line);
            System.debug(chassisLine);	// BLL11a
            gettaxReq.Lines.Line.add(chassisLine); // BLL2a
        
        	taxrules = customerrules;	// BLL13a - reset
        }       
        
        // BLL4a Special Dealer tax (Virginia) chassis less trade value
        if (taxrules.ChassisLessTrade__c!=null && chassisAmt>totalTradeChassis) {	// BLL25c change to chassis portion of trade allowance
        	TaxSvc.Line line = new TaxSvc.Line();
        	line.DestinationCode = taxrules.ChassisLessTrade_AtStore__c ? 'Store' : 'Customer';
            if (taxrules.OriginSourced__c) {line.OriginCode=line.DestinationCode; /* bll57d line.DestinationCode=null;*/ }	// BLL20a
        	line.No = String.valueOf(lineNbr++);
            line.ItemCode = 'Chassis less trade';
            line.Description = deal.Name;
            //BLL25d line.Amount = chassisAmt - totalTrade;
            line.Amount = chassisAmt - totalTradeChassis;	// BLL25a
            NTSaleAdjAmt -= chassisAmt - totalTradeChassis; // BLL49a	not a net increase in sale amt
            // BLL13d line.TaxCode = taxrules.ChassisLessTrade__c; 
            line.TaxCode = taxrules.ChassisLessTrade_AtStore__c ? storerules.ChassisLessTrade__c : taxrules.ChassisLessTrade__c;	// BLL13a
            if (line.TaxCode!=null) gettaxReq.Lines.Line.add(line); // BLL2a, BLL13c add condition line.TaxCode!=null 
        }
        chassisAmt = chassisLine!=null ? chassisLine.Amount : 0.00; // moved from trade_netchassis section
        // BLL4a end
        
        // BLL change - 4502 is included in chassis price *if* their tax codes are the same!
        // This should probably *always* be the situation, but is not forced.
        if (deal.AutoGrant__c!=null && deal.AutoGrant__c!=0 && taxrules.AutoGrant_NetChassis__c!=true) {
            TaxSvc.Line line = new TaxSvc.Line();
            // BLL13d line.OriginCode = 'Customer';
            line.DestinationCode = 'Customer';	// BLL13a
            if (taxrules.OriginSourced__c) {line.OriginCode=line.DestinationCode; /* blld line.DestinationCode=null; */ }	// BLL20a
            line.No = String.valueOf(lineNbr++);
            //line.DestinationCode = gettaxReq.DestinationCode;
            line.ItemCode = 'Auto grant (4502)';
            line.Description = 'Grant payor id ' + deal.dtmob__Auto_Grant_Payor__c;		// BLL42c deal.Auto_Grant_Payee__c;    
            line.Amount = -deal.AutoGrant__c;
            chassisAmt -= deal.AutoGrant__c;
            System.debug('Working chassis amount reduced by 4502 (on sep line): ' + String.valueOf(chassisAmt)); 
            line.TaxCode = taxrules.AutoGrant__c;
            gettaxReq.Lines.Line.add(line);
        }
        // New MBW Discount when not combined with chassis
        //if (deal.ChassisDiscount__c!=null && deal.ChassisDiscount__c!=0 && taxrules.ChassisDiscount_NetChassis__c!=true) {
        //  TaxSvc.Line line = new TaxSvc.Line();
         //   line.OriginCode = 'Customer';
        //  line.No = String.valueOf(lineNbr++);
        //  //line.DestinationCode = gettaxReq.DestinationCode;
        //  line.ItemCode = 'MBW Chassis Discount';
        //  line.Description = 'MBW Chassis Discount';  
        //  line.Amount = -deal.ChassisDiscount__c;
        //  chassisAmt -= deal.ChassisDiscount__c; 
        //  line.TaxCode = taxrules.ChassisDiscount__c;
        //  gettaxReq.Lines.Line.add(line);
        //}

        // BLL44 change - GPC is included in chassis price *if* their tax codes are the same!
        // This should probably *always* be the situation, but is not forced.
        if (deal.Government_Price_Concession__c!=null && deal.Government_Price_Concession__c!=0 && taxrules.GPC_NetChassis__c!=true) {
            TaxSvc.Line line = new TaxSvc.Line();
            // BLL13d line.OriginCode = 'Customer';
            line.DestinationCode = 'Customer';	// BLL13a
            if (taxrules.OriginSourced__c) {line.OriginCode=line.DestinationCode; /* blld line.DestinationCode=null; */ }	// BLL20a
            line.No = String.valueOf(lineNbr++);
            //line.DestinationCode = gettaxReq.DestinationCode;
            line.ItemCode = 'GPC';
            line.Description = 'Government Price Concession';    
            line.Amount = -deal.Government_Price_Concession__c;
            chassisAmt -= deal.Government_Price_Concession__c;
            System.debug('Working chassis amount reduced by GPC (on sep line): ' + String.valueOf(chassisAmt)); 
            line.TaxCode = taxrules.GPC__c;
            gettaxReq.Lines.Line.add(line);
        }


		// BLL24a
		// Check for a 1394 grant amount in other payors
		Decimal grant1394 = 0.00;
		// BLL59d - replace " = '1394'" with "startsWith('1394')"
		//if (deal.dealer__Deferred_Down_1__c!=null && deal.dealer__Deferred_Note_1__c!=null && deal.dealer__Deferred_Note_1__c=='1394' && deal.Third_Party_Pay_1__c!=null) grant1394 += deal.dealer__Deferred_Down_1__c;
		//if (deal.dealer__Deferred_Down_2__c!=null && deal.dealer__Deferred_Note_2__c!=null && deal.dealer__Deferred_Note_2__c=='1394' && deal.Third_Party_Pay_2__c!=null) grant1394 += deal.dealer__Deferred_Down_2__c;
		// BLL24a end
		//if (deal.dealer__Deferred_Down_3__c!=null && deal.dealer__Deferred_Note_3__c!=null && deal.dealer__Deferred_Note_3__c=='1394' && deal.Third_Party_Pay_3__c!=null) grant1394 += deal.dealer__Deferred_Down_3__c;	// BLLa might as well do em all

		// BLL59a startsWith 1394 instead of equals exactly
		if (deal.dealer__Deferred_Down_1__c!=null && deal.dealer__Deferred_Note_1__c!=null && deal.dealer__Deferred_Note_1__c.startsWith('1394') && deal.Third_Party_Pay_1__c!=null) grant1394 += deal.dealer__Deferred_Down_1__c;
		if (deal.dealer__Deferred_Down_2__c!=null && deal.dealer__Deferred_Note_2__c!=null && deal.dealer__Deferred_Note_2__c.startsWith('1394') && deal.Third_Party_Pay_2__c!=null) grant1394 += deal.dealer__Deferred_Down_2__c;
		// BLL24a end
		if (deal.dealer__Deferred_Down_3__c!=null && deal.dealer__Deferred_Note_3__c!=null && deal.dealer__Deferred_Note_3__c.startsWith('1394') && deal.Third_Party_Pay_3__c!=null) grant1394 += deal.dealer__Deferred_Down_3__c;	// BLLa might as well do em all


        if (lineNbr<15) lineNbr = 15;
        TaxSvc.Line conversionLine; // BLL2a
        if (deal.Conversion_Price__c>0) {
            // BLL2d TaxSvc.Line line = new TaxSvc.Line();
            conversionLine = new TaxSvc.Line(); // BLL2a
            //BLL13d conversionLine.OriginCode = 'Customer';
            conversionLine.DestinationCode = 'Customer';	// BLL13a
            if (taxrules.Conversion_AtStore__c) conversionLine.DestinationCode = 'Store';	// BLL26a
            if (taxrules.OriginSourced__c) {conversionLine.OriginCode=conversionLine.DestinationCode; /* blld conversionLine.DestinationCode=null; */ }	// BLL20a
            conversionLine.No = String.valueOf(lineNbr++);
            //conversionLine.DestinationCode = gettaxReq.DestinationCode;
            conversionLine.ItemCode = 'Conversion';
            conversionLine.Description = deal.dealer__Vehicle__r.Name;  
            conversionLine.Amount = deal.Conversion_Price__c; 
            //BLL61d conversionLine.TaxCode = (deal.Conversion_Taxable__c) ? taxrules.ConversionTX__c : taxrules.Conversion__c;
            // BLL61a
            conversionLine.TaxCode = taxrules.Conversion__c;	
            if (!String.isBlank(taxrules.TaxDocumentRequired__c) && deal.HaveRequiredTaxCert__c) conversionLine.TaxCode = taxrules.ConversionWithCert__c;	
			System.debug(taxrules.TaxDocumentRequired__c);
			System.debug(deal.HaveRequiredTaxCert__c);
			System.debug(conversionLine);
			// BLL65 - conversion on customer-owned vehicle is really just "added equipment"
			if (!isVehicleSale) {
				conversionLine.TaxCode = taxrules.AdaptiveEquipment__c;
				if (deal.Conversion_Taxable__c) conversionLine.TaxCode = taxrules.AdaptiveEquipmentTX__c;
            	if (!String.isBlank(taxrules.TaxDocumentRequired__c) && deal.HaveRequiredTaxCert__c) conversionLine.TaxCode = taxrules.AdaptiveEquipWithCert__c;	
				// check for equipment-only override
	            TaxRuleOverride__c ovr = taxRuleOverrides.get('AddedEquipmentParts:EquipmentOnlyDeal');
				if (ovr!=null) {
	            	conversionLine.TaxCode = ovr.TaxCode__c;
	            	if (deal.Conversion_Taxable__c) conversionLine.TaxCode = ovr.TaxCodeTX__c;
		            if (!String.isBlank(taxrules.TaxDocumentRequired__c) && deal.HaveRequiredTaxCert__c) conversionLine.TaxCode = ovr.TaxCodeWithCert__c;	
				}
			}
			// BLL65 end
            if (deal.Conversion_Taxable__c) conversionLine.TaxCode = taxrules.ConversionTX__c;	
			System.debug(conversionLine);
            // BLL61a end
            if (deal.ConversionExempt__c==true) conversionLine.TaxCode = 'NT';	// BLL34a
			// BLL23a Conversion discount
			if (deal.Conversion_Discount__c!=null && deal.Conversion_Discount__c!=0) { 
				conversionLine.Amount -= deal.Conversion_Discount__c;
				conversionLine.Description += ' less Discount';
			}
			// BLL23a end
            // BLL2a
            System.debug(taxrules.CombineConversionWithChassis__c);
            System.debug(chassisLine);
            System.debug(conversionLine);
            if (taxrules.CombineConversionWithChassis__c==true && chassisLine!=null && conversionLine.TaxCode==chassisLine.TaxCode) {
                // Adjust pre-existing line for chassis
                conversionLine = chassisLine;
                conversionLine.Description += '; Conversion';
                conversionLine.Amount += deal.Conversion_Price__c;
            } else {
                gettaxReq.Lines.Line.add(conversionLine);
            }
			// BLL66
			if (taxrules!=null && conversionLine!=null 
				&& taxrules.CombineConversionWithChassis__c==true && tradeChassisValueRemaining>0 
				&& conversionLine==chassisLine) {
            	System.debug('Reduce conversion taxable amount by trade-in excess');
				System.debug(tradeChassisValueRemaining);
				System.debug(conversionLine.Amount);
            	NTSaleAdjAmt += Math.min(tradeChassisValueRemaining, conversionLine.Amount);
				conversionLine.Amount -= Math.min(tradeChassisValueRemaining, conversionLine.Amount);
			}
			// BLL66 end
        }

		// BLL24a - conversion grant
		TaxSvc.line line1394;
		if (grant1394!=0 && taxrules.ConversionGrant__c!=null) {
			line1394 = new TaxSvc.Line();
			line1394.DestinationCode = 'Customer';
            if (taxrules.OriginSourced__c) {line1394.OriginCode=line1394.DestinationCode; /* blld line1394.DestinationCode=null; */ }
            line1394.No = String.valueOf(lineNbr++);
            line1394.ItemCode = '1394 Grant';
            line1394.Description = deal.dealer__Vehicle__r.Name;
            line1394.Amount = -grant1394;
            NTSaleAdjAmt += grant1394;	// BLL49a
			line1394.TaxCode = taxrules.ConversionGrant__c;
			// BLL61a use conversion with documentation tax code for grant *IF* regular tax codes match for the two
			// (instead of needing a separate 1394 tax code combined with prescription (or other docs))
			if (taxrules.ConversionGrant__c==taxrules.Conversion__c && !String.isBlank(taxrules.TaxDocumentRequired__c) && deal.HaveRequiredTaxCert__c)	// BLL61a
				line1394.TaxCode = taxrules.ConversionWithCert__c;	// BLL61a
			if (taxrules.ConvGrantReducesConv__c==true && conversionLine!=null && conversionLine.TaxCode==line1394.TaxCode) { // combine with conversion
				conversionLine.Description += '; 1394 grant';
				conversionLine.Amount += line1394.Amount;
				line1394 = null;	// BLL34 - not a separate line
			} else {
				gettaxReq.Lines.Line.add(line1394);
			}
		} 
		// BLL24a end
        
        // BLL4a Change chassis tax code if luxury tax applies (do it after conversion in case 
        // conversion needs to be added into the same line before we change over the tax code.
        if (taxrules.LuxuryVehicle__c!=null && taxrules.LuxuryValue__c!=null && taxrules.LuxuryValue__c<=deal.Chassis_Price__c) chassisLine.TaxCode = taxrules.LuxuryVehicle__c;
        // BLL4a end

        // Aftermarket items 
        //AggregateResult[] items = [
        //  select Name, dealer__Description__c, Taxable__c, sum(dealer__Sale_Price__c) price, count(Id) qty
        //  from dealer__After_Market__c
        //  where dealer__Deal__c=:deal.Id
        //  group by Name, dealer__Description__c, Taxable__c
        //];
        //BLL10d Decimal kit = 0.00;
        //BLL10d Decimal kitNT = 0.00;
        //BLL10d Decimal lbr = 0.00;
        //BLL10d Decimal lbrNT = 0.00;
        //BLL10d Decimal misc = 0.00;
        //BLL10d Decimal miscNT = 0.00;
        if (lineNbr<20) lineNbr = 20;
        boolean addedToConversionLine = false;
        
		// BLL11a
        // Setup overrides for equipment only deals (BLL13 note: equipment only deals only use store rules!)
        if (taxRuleOverrides.containsKey('AddedEquipmentParts:EquipmentOnlyDeal') && !isVehicleSale) {	//BLL44c deal.dealer__Deal_Type__c=='Equipment Only Sale') {
            TaxRuleOverride__c ovr = taxRuleOverrides.get('AddedEquipmentParts:EquipmentOnlyDeal');
            taxrules.AdaptiveEquipmentTX__c = ovr.TaxCodeTX__c;
            taxrules.AdaptiveEquipment__c = ovr.TaxCode__c;
			taxrules.AddedEquipment_AtStore__c = ovr.Tax_AtStore__c;	// BLL54a just use parts for this flag
			taxrules.AdaptiveEquipWithCert__c = ovr.TaxCodeWithCert__c;	// BLL61a
        }
        if (taxRuleOverrides.containsKey('AddedEquipmentSublet:EquipmentOnlyDeal') && !isVehicleSale) {	//BLL44c deal.dealer__Deal_Type__c=='Equipment Only Sale') {
            TaxRuleOverride__c ovr = taxRuleOverrides.get('AddedEquipmentSublet:EquipmentOnlyDeal');
            taxrules.AdaptiveEquipSubletTX__c = ovr.TaxCodeTX__c;
            taxrules.AdaptiveEquipSublet__c = ovr.TaxCode__c;
            taxrules.AdaptiveEquipSubletWithCert__c = ovr.TaxCodeWithCert__c;	// BLL61a
        }
        if (taxRuleOverrides.containsKey('AddedEquipmentLabor:EquipmentOnlyDeal') && !isVehicleSale) {	//BLL44c deal.dealer__Deal_Type__c=='Equipment Only Sale') {
            TaxRuleOverride__c ovr = taxRuleOverrides.get('AddedEquipmentLabor:EquipmentOnlyDeal');
            taxrules.AdaptiveEquipLaborTX__c = ovr.TaxCodeTX__c;
            taxrules.AdaptiveEquipLabor__c = ovr.TaxCode__c;
            taxrules.AdaptiveEquipLaborWithCert__c = ovr.TaxCodeWithCert__c;	// BLL61a
        }
        // BLL11a end
        
        // BLL53a DME override (by proposal type)
        if (taxRuleOverrides.containsKey('AddedEquipmentParts:'+deal.dealer__Deal_Type__c)) {
            TaxRuleOverride__c ovr = taxRuleOverrides.get('AddedEquipmentParts:'+deal.dealer__Deal_Type__c);
            taxrules.AdaptiveEquipmentTX__c = ovr.TaxCodeTX__c;
            taxrules.AdaptiveEquipment__c = ovr.TaxCode__c;
			taxrules.AddedEquipment_AtStore__c = ovr.Tax_AtStore__c;	// BLL54a just use parts for this flag
			taxrules.AdaptiveEquipWithCert__c = ovr.TaxCodeWithCert__c;	// BLL61a
        }
        if (taxRuleOverrides.containsKey('AddedEquipmentSublet:'+deal.dealer__Deal_Type__c)) {
            TaxRuleOverride__c ovr = taxRuleOverrides.get('AddedEquipmentSublet:'+deal.dealer__Deal_Type__c);
            taxrules.AdaptiveEquipSubletTX__c = ovr.TaxCodeTX__c;
            taxrules.AdaptiveEquipSublet__c = ovr.TaxCode__c;
            taxrules.AdaptiveEquipSubletWithCert__c = ovr.TaxCodeWithCert__c;	// BLL61a
        }
        if (taxRuleOverrides.containsKey('AddedEquipmentLabor:'+deal.dealer__Deal_Type__c)) {
            TaxRuleOverride__c ovr = taxRuleOverrides.get('AddedEquipmentLabor:'+deal.dealer__Deal_Type__c);
            taxrules.AdaptiveEquipLaborTX__c = ovr.TaxCodeTX__c;
            taxrules.AdaptiveEquipLabor__c = ovr.TaxCode__c;
            taxrules.AdaptiveEquipLaborWithCert__c = ovr.TaxCodeWithCert__c;	// BLL61a
        }
        // BLL53a end

		// BLL14a If combining conversion with chassis and no conversion line, set to chassis line in case of combining others into conversion!
        if (taxrules.CombineConversionWithChassis__c==true && chassisLine!=null && conversionLine==null) {
        	conversionLine = chassisLine;
        }
        // BLL14a end
        Decimal TotalMobilityEquip = 0.00;	// BLL49a
        
        for (dealer__After_Market__c am : items) {
        	//BLL50d if (!am.Taxable__c) TotalMobilityEquip += am.dealer__Sale_Price__c;	// BLL49a
        	if (!am.Taxable__c) TotalMobilityEquip += am.ExtendedPrice__c;	// BLL50a
        	
			// BLL10a
           	//BLL50d if (am.dealer__Sale_Price__c==null) am.dealer__Sale_Price__c = 0.00; 
           	//BLL50d if (am.dealer__Labor_Sale__c==null) am.dealer__Labor_Sale__c = 0.00; 
           	//BLL50d Decimal parts = am.dealer__Sale_Price__c;
           	Decimal ExtendedPrice = (am.ExtendedPrice__c!=null) ? am.ExtendedPrice__c : 0;	// BLL50a
           	Decimal ExtendedLaborPrice = (am.ExtendedLaborPrice__c!=null) ? am.ExtendedLaborPrice__c : 0;	// BLL50a
           	Decimal parts = ExtendedPrice;	// BLL50a
           	Decimal labor = 0.00;
           	if (dealsplitlabor) { 
           		// handle negatives & max the amounts to the sale price
           		//BLL50d parts -= am.dealer__Sale_Price__c>0 ? math.min(am.dealer__Labor_Sale__c,am.dealer__Sale_Price__c) : math.max(am.dealer__Labor_Sale__c,am.dealer__Sale_Price__c);  
           		//BLL50d labor = am.dealer__Sale_Price__c>0 ? math.min(am.dealer__Labor_Sale__c,am.dealer__Sale_Price__c) : math.max(am.dealer__Labor_Sale__c,am.dealer__Sale_Price__c);
           		parts -= ExtendedPrice>0 ? math.min(ExtendedLaborPrice, ExtendedPrice) : math.max(ExtendedLaborPrice, ExtendedPrice);  	// BLL50a
           		labor = ExtendedPrice>0 ? math.min(ExtendedLaborPrice, ExtendedPrice) : math.max(ExtendedLaborPrice, ExtendedPrice);	// BLL50a
           		System.debug(am.Labor_Hours__c);
           		System.debug(am.dealer__Parts_Kit__c);
           		//BLL50d System.debug(am.dealer__Sale_Price__c);
           		System.debug(ExtendedPrice);	// BLL50a
           		//BLL50d if (am.Labor_Hours__c!=null && am.Labor_Hours__c>0 && am.dealer__Parts_Kit__c==null && am.dealer__Sale_Price__c!=null && am.dealer__Sale_Price__c!=0) { // added labor
           		if (am.Labor_Hours__c!=null && am.Labor_Hours__c>0 && am.dealer__Parts_Kit__c==null && am.dealer__Sale_Price__c!=null && ExtendedPrice!=0) { // added labor	//BLL50a
           			parts = 0.00;
           			//BLL50d labor = am.dealer__Sale_Price__c;
           			labor = ExtendedPrice;	// BLL50a
           		}
           	}
           	//BLL50d if (parts<0 && am.dealer__Sale_Price__c>0) parts=0;	// Don't allow negative - should never happen!
           	if (parts<0 && ExtendedPrice>0) parts=0;	// BLL50a
           	// BLL10a end
            TaxSvc.Line line = new TaxSvc.Line();
            //BLL13d line.OriginCode = 'Customer';
            line.DestinationCode = 'Customer';	// BLL13a
            if (taxrules.AddedEquipment_AtStore__c) line.DestinationCode = 'Store';	// BLL26a
            if (taxrules.OriginSourced__c) {line.OriginCode=line.DestinationCode; /* blld line.DestinationCode=null; */ }	// BLL20a
            //line.DestinationCode = gettaxReq.DestinationCode;
            line.itemCode = am.Name; 
            line.Description = am.dealer__Description__c;
            line.Amount = parts;	//BLL10c am.dealer__Sale_Price__c;
            
            TaxSvc.Line line2 = null;	// BLL10a for splitting out labor
            
            // Assign appropriate tax code... 
            if (am.Name=='Misc') {	// (treat Misc like parts)
                //BLL10d if (am.Taxable__c) misc += am.dealer__Sale_Price__c;
                //BLL10d else miscNT += am.dealer__Sale_Price__c;
                line.itemCode = 'Misc' + '-' + String.valueOf(LineNbr);
                //BLL61d line.TaxCode = am.Taxable__c ? taxrules.AdaptiveEquipmentTX__c : taxrules.AdaptiveEquipment__c;
                line.TaxCode = taxrules.AdaptiveEquipment__c;	// BLL61a
            	if (!String.isBlank(taxrules.TaxDocumentRequired__c) && deal.HaveRequiredTaxCert__c) line.TaxCode = taxrules.AdaptiveEquipWithCert__c;	// BLL61a
            	if (am.Taxable__c) line.TaxCode = taxrules.AdaptiveEquipmentTX__c;	// BLL61a
            } else if (am.Name=='Sublet ' + deal.Name) {
                //BLL10d if (am.Taxable__c) lbr += am.dealer__Sale_Price__c;
                //BLL10d else lbrNT += am.dealer__Sale_Price__c;
                line.itemCode = 'Sublet ' + deal.Name  + '-' + String.valueOf(LineNbr);
                //BLL61d line.TaxCode = am.Taxable__c ? taxrules.AdaptiveEquipSubletTX__c : taxrules.AdaptiveEquipSublet__c;
                line.TaxCode = taxrules.AdaptiveEquipSublet__c;	// BLL61a
            	if (!String.isBlank(taxrules.TaxDocumentRequired__c) && deal.HaveRequiredTaxCert__c) line.TaxCode = taxrules.AdaptiveEquipSubletWithCert__c;	// BLL61a
            	if (am.Taxable__c) line.TaxCode = taxrules.AdaptiveEquipSubletTX__c;	// BLL61a
            } else {
                //BLL10d if (am.Taxable__c) kit += am.dealer__Sale_Price__c;
                //BLL10d else kitNT += am.dealer__Sale_Price__c;
                //BLL61d line.TaxCode = am.Taxable__c ? taxrules.AdaptiveEquipmentTX__c : taxrules.AdaptiveEquipment__c;
                line.TaxCode = taxrules.AdaptiveEquipment__c;	// BLL61a
            	if (!String.isBlank(taxrules.TaxDocumentRequired__c) && deal.HaveRequiredTaxCert__c) line.TaxCode = taxrules.AdaptiveEquipWithCert__c;	// BLL61a
            	if (am.Taxable__c) line.TaxCode = taxrules.AdaptiveEquipmentTX__c;	// BLL61a
                // BLL54a kit & part overrides
                if (am.dealer__Parts_Kit__c!=null && am.dealer__Parts_Kit__r.Category__c!=null) {
                	System.debug('Applying kit category overrides ' + am.dealer__Parts_Kit__r.Category__r.TaxCodeOvr__c + ', ' + am.dealer__Parts_Kit__r.Category__r.TaxCodeOvrTX__c + ', ' + am.dealer__Parts_Kit__r.Category__r.TaxCodeOvrWithCert__c);	// BLL61c  
                	if (am.Taxable__c && !String.isBlank(am.dealer__Parts_Kit__r.Category__r.TaxCodeOvrTX__c)) line.TaxCode = am.dealer__Parts_Kit__r.Category__r.TaxCodeOvrTX__c;  
                	if (!am.Taxable__c && !String.isBlank(am.dealer__Parts_Kit__r.Category__r.TaxCodeOvr__c)) line.TaxCode = am.dealer__Parts_Kit__r.Category__r.TaxCodeOvr__c;
                	if (!am.Taxable__c && !String.isBlank(am.dealer__Parts_Kit__r.Category__r.TaxCodeOvrWithCert__c) && !String.isBlank(taxrules.TaxDocumentRequired__c) && deal.HaveRequiredTaxCert__c)
                		line.TaxCode = am.dealer__Parts_Kit__r.Category__r.TaxCodeOvrWithCert__c;	// BLL61a
                }
                if (am.dealer__Parts_Kit__c!=null) {
                	System.debug('Applying kit overrides ' + am.dealer__Parts_Kit__r.TaxCodeOvr__c + ', ' + am.dealer__Parts_Kit__r.TaxCodeOvrTX__c);  
                	if (am.Taxable__c && !String.isBlank(am.dealer__Parts_Kit__r.TaxCodeOvrTX__c)) line.TaxCode = am.dealer__Parts_Kit__r.TaxCodeOvrTX__c;  
                	if (!am.Taxable__c && !String.isBlank(am.dealer__Parts_Kit__r.TaxCodeOvr__c)) line.TaxCode = am.dealer__Parts_Kit__r.TaxCodeOvr__c;  
                	if (!am.Taxable__c && !String.isBlank(am.dealer__Parts_Kit__r.TaxCodeOvrWithCert__c) && !String.isBlank(taxrules.TaxDocumentRequired__c) && deal.HaveRequiredTaxCert__c)
                		line.TaxCode = am.dealer__Parts_Kit__r.TaxCodeOvrWithCert__c;	// BLL61a
                }
                if (am.dealer__Part__c!=null && am.dealer__Part__r.dealer__Parts_Master__c!=null) {
                	System.debug('Applying part overrides ' + am.dealer__Part__r.dealer__Parts_Master__r.TaxCodeOvr__c + ', ' + am.dealer__Part__r.dealer__Parts_Master__r.TaxCodeOvrTX__c);  
                	if (am.Taxable__c && !String.isBlank(am.dealer__Part__r.dealer__Parts_Master__r.TaxCodeOvrTX__c)) line.TaxCode = am.dealer__Part__r.dealer__Parts_Master__r.TaxCodeOvrTX__c;  
                	if (!am.Taxable__c && !String.isBlank(am.dealer__Part__r.dealer__Parts_Master__r.TaxCodeOvr__c)) line.TaxCode = am.dealer__Part__r.dealer__Parts_Master__r.TaxCodeOvr__c;  
                	if (!am.Taxable__c && !String.isBlank(am.dealer__Part__r.dealer__Parts_Master__r.TaxCodeOvrWithCert__c) && !String.isBlank(taxrules.TaxDocumentRequired__c) && deal.HaveRequiredTaxCert__c)
                		line.TaxCode = am.dealer__Part__r.dealer__Parts_Master__r.TaxCodeOvrWithCert__c;	// BLL61a
                }
                // BLL54a end
                // BLL10a
				if (labor!=null && labor!=0.00) {
					line2 = new TaxSvc.Line();
	            	//line2.OriginCode = 'Customer';
	            	line2.DestinationCode = 'Store';
	            	line2.itemCode = am.Name + '-Labor';
	            	line2.Description = 'Labor for: ' + am.dealer__Description__c;
	            	line2.Amount = labor;
 	                //BLL61d line2.TaxCode = am.Taxable__c ? taxrules.AdaptiveEquipLaborTX__c : taxrules.AdaptiveEquipLabor__c;
 	                line2.TaxCode = taxrules.AdaptiveEquipLabor__c;	// BLL61a
	            	if (!String.isBlank(taxrules.TaxDocumentRequired__c) && deal.HaveRequiredTaxCert__c) line.TaxCode = taxrules.AdaptiveEquipLaborWithCert__c;	// BLL61a
 	                if (am.Taxable__c) line2.TaxCode = taxrules.AdaptiveEquipLaborTX__c;	// BLL61a
				}
				// BLL10a end
            }
            
			// BLL34a - handle new tax exempt flag
            if (line!=null && am.TaxExempt__c==true) line.TaxCode = 'NT';	// BLL34a
            if (line2!=null && am.TaxExempt__c==true) line2.TaxCode = 'NT';	// BLL34a
            
			// BLL16a
            // special NMEDA handling - full amount (no part/labor split) usually NT (non-taxable)
            if (taxrules.NMEDA__c!=null && am.dealer__Description__c!=null && am.dealer__Description__c.contains('NMEDA ')) {
	        	if (!am.Taxable__c) TotalMobilityEquip -= am.dealer__Sale_Price__c;	// BLL49a (remove NMEDA charge from taxable mobility total) 
            	line.TaxCode = (am.Taxable__c && taxrules.NMEDA_TX__C!=null) ? taxrules.NMEDA_TX__c : taxrules.NMEDA__c;
            	line.Amount = am.dealer__Sale_Price__c;	// NMEDA label is all 1 charge
            	if (taxrules.NMEDA_AtStore__c==true) line.DestinationCode = 'Store';
	            if (taxrules.OriginSourced__c) {line.OriginCode=line.DestinationCode; /* bll57d line.DestinationCode=null; */ }	// BLL20a

	            // option: separate tax code for NMEDA labor instead of setting line2=null
	            //line2.TaxCode = (am.Taxable__c && taxrules.NMEDA_Lbr_TX__C!=null) ? taxrules.NMEDA_Lbr_TX__c : taxrules.NMEDA_Lbr__c;
	            // above... comment out: line.Amount = am.dealer__Sale_Price__c;
            	//if (taxrules.NMEDA_AtStore__c==true) line2.DestinationCode = 'Store';
	            //if (taxrules.OriginSourced__c) {line2.OriginCode=line2.DestinationCode; /* bll57d line2.DestinationCode=null; */ }	

            	line2 = null;	// Don't split
            }
            // BLL16a end
            
            line.No = String.valueOf(lineNbr++);
            if (line.itemCode.length()>50) line.itemCode = line.itemCode.substring(0,50);
            
            // BLL2a
            System.debug(taxrules.CombineEquipmentWithConversion__c);
            System.debug(conversionLine);
            System.debug(line);
            if (line.Amount!=0) {	// BLL10a
            	if (taxrules.CombineEquipmentWithConversion__c && conversionLine!=null && line.TaxCode==conversionLine.TaxCode) {
            	    // Adjust pre-existing line for conversion/chassis
            	    conversionLine.Description += addedToConversionLine ? '' : '; Additional equipment';
            	    addedToConversionLine = true;
            	    conversionLine.Amount += line.Amount;
            	    TotalMobilityEquip -= line.Amount;	// BLL49a
            	} else {
            	    gettaxReq.Lines.Line.add(line);
            	}
            }	// BLL10a
            
            // BLL10a - Line 2 for split out labor on kits
            if (line2!=null && line2.Amount!=0) {
	            line2.No = String.valueOf(lineNbr++);
	            if (line2.itemCode.length()>50) line2.itemCode = line2.itemCode.substring(0,50);
            	if (taxrules.CombineEquipmentWithConversion__c && conversionLine!=null && line2.TaxCode==conversionLine.TaxCode) {
            	    // Adjust pre-existing line for conversion/chassis labor
            	    conversionLine.Amount += line.Amount;
            	    TotalMobilityEquip -= line.Amount;	// BLL49a
            	} else {
   	        	    gettaxReq.Lines.Line.add(line2);
   	        	}
            }
            // BLL10a end
        } 

		// BLL49a - Don't let 1394 grant exceed conversion line amt
		// Note: NTSaleAdjAmt was already adjusted by the 1394 that drove this negative, so don't adjust again
		if (conversionLine!=null && conversionLine.Amount < 0) {
			NTSaleAdjAmt += conversionLine.Amount;	// BLL49a
			conversionLine.Amount = 0;
		}
		if (line1394!=null && conversionLine!=null && (conversionLine.Amount+TotalMobilityEquip) < -line1394.Amount) {
			NTSaleAdjAmt -= line1394.Amount - (conversionLine.Amount+TotalMobilityEquip);	// BLL49a
			line1394.Amount = -(conversionLine.Amount+TotalMobilityEquip);
		}
		// BLL49a end

        // Fees
        if (lineNbr<60) lineNbr = 60;
        if (deal.GVW_GVWR__c!=null && deal.GVW_GVWR__c!=0) {
            TaxSvc.Line line = new TaxSvc.Line();
            //BLL13d line.OriginCode = 'Customer';
            line.DestinationCode = 'Customer';	// BLL13a
            if (taxrules.OriginSourced__c) {line.OriginCode=line.DestinationCode; /* bll57d line.DestinationCode=null; */ }	// BLL20a
            line.No = String.valueOf(lineNbr++);
            //line.DestinationCode = gettaxReq.DestinationCode;
            line.ItemCode = 'GVW/GVWR';
            line.Description = deal.dealer__Vehicle__r.Name;    
            line.Amount = deal.GVW_GVWR__c; 
            line.TaxCode = taxrules.GVW_GVWR__c;
            gettaxReq.Lines.Line.add(line);
        }
        if (deal.Tire_Fee__c!=null && deal.Tire_Fee__c!=0) {
            TaxSvc.Line line = new TaxSvc.Line();
            //BLL13d line.OriginCode = 'Customer';
            line.DestinationCode = 'Customer';	// BLL13a
            if (taxrules.OriginSourced__c) {line.OriginCode=line.DestinationCode; /* bll57d line.DestinationCode=null; */ }	// BLL20a
            line.No = String.valueOf(lineNbr++);
            //line.DestinationCode = gettaxReq.DestinationCode;
            line.ItemCode = 'Tire fee';
            line.Description = deal.dealer__Vehicle__r.Name;    
            line.Amount = deal.Tire_Fee__c; 
            line.TaxCode = taxrules.TireFee__c;
            gettaxReq.Lines.Line.add(line);
        }
        if (deal.Smog_Fee__c!=null && deal.Smog_Fee__c!=0) {
            TaxSvc.Line line = new TaxSvc.Line();
            //BLL13d line.OriginCode = 'Customer';
            line.DestinationCode = 'Customer';	// BLL13a
            if (taxrules.OriginSourced__c) {line.OriginCode=line.DestinationCode; /* BLL57d line.DestinationCode=null; */ }	// BLL20a
            line.No = String.valueOf(lineNbr++);
            //line.DestinationCode = gettaxReq.DestinationCode;
            line.ItemCode = 'Smog fee';
            line.Description = deal.dealer__Vehicle__r.Name;    
            line.Amount = deal.Smog_Fee__c; 
            line.TaxCode = taxrules.SmogFee__c;
            gettaxReq.Lines.Line.add(line);
        }
        if (deal.Electronic_Filing_Fee__c!=null && deal.Electronic_Filing_Fee__c!=0) {
            TaxSvc.Line line = new TaxSvc.Line();
            //BLL13d line.OriginCode = 'Customer';
            line.DestinationCode = 'Customer';	// BLL13a
            if (taxrules.OriginSourced__c) {line.OriginCode=line.DestinationCode; /* bll57d line.DestinationCode=null; */ }	// BLL20a
            line.No = String.valueOf(lineNbr++);
            //line.DestinationCode = gettaxReq.DestinationCode;
            line.ItemCode = 'Electronic filing fee';
            line.Description = deal.dealer__Vehicle__r.Name;    
            line.Amount = deal.Electronic_Filing_Fee__c; 
            line.TaxCode = taxrules.ElectronicFilingFee__c;
            gettaxReq.Lines.Line.add(line);
        }
        if (deal.dealer__Doc_Fee__c!=null && deal.dealer__Doc_Fee__c!=0 && taxrules.CombineDocFeeWithChassis__c!=true) {	// BLL9c add CombineDocFeeWithChassis
        	Map<String,TaxRuleOverride__c> ruleoverrides = taxRuleOverrides;	// BLL13a - select which overrides to use - customer or store tax rules
            TaxSvc.Line line = new TaxSvc.Line();
            System.debug(taxrules.Name + ' ' + (taxrules.DocumentFee_AtStore__c?'true':'false'));	// BLL13a
            if (taxrules.DocumentFee_AtStore__c) {  // BLL4a
	            line.DestinationCode = 'Store';  // BLL4a
	            taxrules = storerules;	// BLL13a
	            ruleoverrides = storeRuleOverrides;	// BLL13a
            } else {  // BLL4a
    		    //BLL13d line.OriginCode = 'Customer';
    		    line.DestinationCode = 'Customer';	// BLL13a fix
	            taxrules = customerrules;	// BLL13a
	            ruleoverrides = taxRuleOverrides;	// BLL13a
            }  // BLL4a
            if (taxrules.OriginSourced__c) {line.OriginCode=line.DestinationCode; /* bll57d line.DestinationCode=null; */ }	// BLL20a
            line.No = String.valueOf(lineNbr++);
            //line.DestinationCode = gettaxReq.DestinationCode;
            line.ItemCode = 'Documents fee';
            line.Description = deal.dealer__Vehicle__r.Name;    
            line.Amount = deal.dealer__Doc_Fee__c; 
            line.TaxCode = taxrules.DocumentFee__c;
			// BLL13d if (taxRuleOverrides.containsKey('DocumentFee:Financed') && deal.dealer__Finance_Institution_Account__c!=null) {
				//BLL13d TaxRuleOverride__c ovr = taxRuleOverrides.get('DocumentFee:Financed');
            if (ruleOverrides.containsKey('DocumentFee:Financed') && deal.dealer__Finance_Institution_Account__c!=null) {	// BLL13a
                TaxRuleOverride__c ovr = ruleOverrides.get('DocumentFee:Financed');	// BLL13a
                line.TaxCode = ovr.TaxCode__c; 
            }
			// BLL19a - override for new, new/used, fleet
			String docfeenuo = 'DocumentFeeNUO:' + deal.dealer__Vehicle__r.New_Used_Other__c;
			if (ruleOverrides.containsKey(docfeenuo)) {
				TaxRuleOverride__c ovr = ruleOverrides.get(docfeenuo);
				line.TaxCode = ovr.TaxCode__c;
				line.ItemCode += '-' + deal.dealer__Vehicle__r.New_Used_Other__c;
			}
			// BLL19a end
            // BLL49a if trade exceeds chassis and doc fees are NOT combined with chassis, reduce doc fee taxable amt
            System.debug(totalTradeChassis);
            System.debug(tradeChassisValueRemaining);
            System.debug(chassisAmt);
            if (taxrules!=null) System.debug(taxrules.CombineDocFeeWithChassis__c);
            if (taxrules!=null) System.debug(taxrules.DocumentFee__c);
            if (chassisLine!=null) System.debug(chassisLine.TaxCode);
            if (taxrules!=null && chassisLine!=null && taxrules.DocumentFee__c==taxrules.TradeIn__c	// BLL55c
            	&& tradeChassisValueRemaining>0 && taxrules.CombineDocFeeWithChassis__c==false
            	&& taxrules.DocumentFee__c==chassisLine.TaxCode) {
            	System.debug('Reduce doc fee taxable amount by trade-in excess');
            	NTSaleAdjAmt += Math.min(tradeChassisValueRemaining, line.Amount);
            	line.Amount -= Math.min(tradeChassisValueRemaining, line.Amount);
            }
            System.debug(line);	// BLL13a
            gettaxReq.Lines.Line.add(line);
            taxrules = customerrules;	// BLL13a reset
        }
        if (deal.dealer__License_Fee__c!=null && deal.dealer__License_Fee__c!=0) {
            TaxSvc.Line line = new TaxSvc.Line();
            //BLL13d line.OriginCode = 'Customer';
            line.DestinationCode = 'Customer';	// BLL13a
            if (taxrules.OriginSourced__c) {line.OriginCode=line.DestinationCode; /* bll57d line.DestinationCode=null; */ }	// BLL20a
            line.No = String.valueOf(lineNbr++);
            //line.DestinationCode = gettaxReq.DestinationCode;
            line.ItemCode = 'License fee';
            line.Description = deal.dealer__Vehicle__r.Name;    
            line.Amount = deal.dealer__License_Fee__c; 
            line.TaxCode = taxrules.LicenseFee__c;
            gettaxReq.Lines.Line.add(line);
        }
        if (deal.Registration_Title_Fee__c!=null && deal.Registration_Title_Fee__c!=0) {
            TaxSvc.Line line = new TaxSvc.Line();
            //BLL13d line.OriginCode = 'Customer';
            line.DestinationCode = 'Customer';	// BLL13a
            if (taxrules.OriginSourced__c) {line.OriginCode=line.DestinationCode; /* bll57d line.DestinationCode=null; */ }	// BLL20a
            line.No = String.valueOf(lineNbr++);
            //line.DestinationCode = gettaxReq.DestinationCode;
            line.ItemCode = 'Registration title fee';
            line.Description = deal.dealer__Vehicle__r.Name;    
            line.Amount = deal.Registration_Title_Fee__c; 
            line.TaxCode = taxrules.RegistrationFee__c;
            gettaxReq.Lines.Line.add(line);
        }
        if (deal.Smog_Cert__c!=null && deal.Smog_Cert__c!=0) {
            TaxSvc.Line line = new TaxSvc.Line();
            //BLL13d line.OriginCode = 'Customer';
            line.DestinationCode = 'Customer';	// BLL13a
            if (taxrules.OriginSourced__c) {line.OriginCode=line.DestinationCode; /* bll57d line.DestinationCode=null; */ }	// BLL20a
            line.No = String.valueOf(lineNbr++);
            //line.DestinationCode = gettaxReq.DestinationCode;
            line.ItemCode = 'Smog certificate';
            line.Description = deal.dealer__Vehicle__r.Name;    
            line.Amount = deal.Smog_Cert__c; 
            line.TaxCode = taxrules.SmogCertificate__c;
            gettaxReq.Lines.Line.add(line);
        }
            
        // Protection products
        List<dealer__Service_Contract__c> escs = [
            select Id, Name, dealer__Description__c, dealer__Product_Code__c, dealer__Sale_Price__c, Type__c 
            from dealer__Service_Contract__c 
               where dealer__Car_Deal__c = :deal.Id
                 and dealer__Contract_Template__c = false
        ];
        if (lineNbr<70) lineNbr = 70;
        for(dealer__Service_Contract__c sc : escs) {
        	System.debug(sc);
            TaxSvc.Line line = new TaxSvc.Line();
            //line.OriginCode = 'Customer';
            line.No = String.valueOf(lineNbr++);
            //BLL46d line.DestinationCode = gettaxReq.DestinationCode;
            line.DestinationCode = 'Customer';	// BLL46a
            line.itemCode = sc.Type__c + ' ' + sc.Name;
            line.Description = sc.dealer__Description__c;
            line.Amount = sc.dealer__Sale_Price__c;
            //BLL47d if (sc.Type__c=='Diamond Fusion')  {
            //BLL47d     //BLL13d line.TaxCode = taxrules.DiamondFusion__c;
            //BLL47d     line.TaxCode = (taxrules.DiamondFusion_AtStore__c) ? storerules.DiamondFusion__c : taxrules.DiamondFusion__c;	// BLL13a
            //BLL47d     if (taxrules.DiamondFusion_AtStore__c) line.DestinationCode = 'Store';
            //BLL47d } else if (sc.Type__c=='GAP') {
            //BLL47d     //BLL13d line.TaxCode = taxrules.GAP__c;
            //BLL47d     line.TaxCode = (taxrules.GAP_AtStore__c) ? storerules.GAP__c : taxrules.GAP__c;	// BLL13a
            //BLL47d     if (taxrules.GAP_AtStore__c) line.DestinationCode = 'Store';
            //BLL47d } else if (sc.Type__c=='Roadside Protection') {
            //BLL47d     //BLL13d line.TaxCode = taxrules.RoadsideProtection__c;
            //BLL47d     line.TaxCode = (taxrules.RoadsideProt_AtStore__c) ? storerules.RoadsideProtection__c : taxrules.RoadsideProtection__c;	// BLL13a
            //BLL47d     if (taxrules.RoadsideProt_AtStore__c) line.DestinationCode = 'Store';
            //BLL47d } else if (sc.Type__c=='Tire+Wheel') {	// BLL45 add section
            //BLL47d     line.TaxCode = (taxrules.TireWheel_AtStore__c) ? storerules.TireWheel__c : taxrules.TireWheel__c;
            //BLL47d     if (taxrules.TireWheel_AtStore__c) line.DestinationCode = 'Store';
            //BLL47d } else {
	            // BLL47a
	            System.debug(sc.Type__c+':ESC');
				if (taxRuleOverrides.containsKey(sc.Type__c + ':ESC')) {	//BLL44c deal.dealer__Deal_Type__c=='Equipment Only Sale') {	// BLL35c check deal type!
					TaxRuleOverride__c ovr = taxRuleOverrides.get(sc.Type__c + ':ESC');
					TaxRuleOverride__c storeovr = storeRuleOverrides.get(sc.Type__c + ':ESC');	// BLL51a
					line.TaxCode = ovr.TaxCode__c; 
	            	if (ovr.Tax_AtStore__c) line.DestinationCode = 'Store';
	            	if (storeovr!=null && storeovr.Tax_AtStore__c) line.TaxCode = storeovr.TaxCode__c;	// BLL51a
				// BLL47a end
				// BLL47 default service contract rule:
				} else {
                //BLL13d line.TaxCode = taxrules.ServiceContract__c;
                	line.TaxCode = (taxrules.ServiceContract_AtStore__c) ? storerules.ServiceContract__c : taxrules.ServiceContract__c;	// BLL13a
                	if (taxrules.ServiceContract_AtStore__c) line.DestinationCode = 'Store';
				}
				System.debug(line);
            //BLL47d }
            // BLL31a
			if (taxRuleOverrides.containsKey(sc.Type__c + ':EquipmentOnlyDeal') && !isVehicleSale) {	//BLL44c deal.dealer__Deal_Type__c=='Equipment Only Sale') {	// BLL35c check deal type!
				System.debug(sc.Type__c+':EquipmentOnlyDeal');
				TaxRuleOverride__c ovr = taxRuleOverrides.get(sc.Type__c + ':EquipmentOnlyDeal');
				line.TaxCode = ovr.TaxCode__c; 
			}

			// BLL67
			if (taxRuleOverrides.containsKey(sc.Type__c + ':FinancialProductsOnly') && deal.dealer__Deal_Type__c=='Financial Products') {	
				System.debug(sc.Type__c+':FinancialProductsOnly');
				TaxRuleOverride__c ovr = taxRuleOverrides.get(sc.Type__c + ':FinancialProductsOnly');
				line.TaxCode = ovr.TaxCode__c; 
			}
			// BLL67 end

            if (taxrules.OriginSourced__c) {line.OriginCode=line.DestinationCode; /* bll57d line.DestinationCode=null; */}	// BLL45a

			// BLL31a end
            if (line.itemCode.length()>50) line.itemCode = line.itemCode.substring(0,50);
            System.debug(line);
            gettaxReq.Lines.Line.add(line);
        }
        
        // Trades when listed separately
        if (lineNbr<80) lineNbr = 80;
        if (totalTradeChassis > chassisAmt) {	// BLL25c change to chassis portion of trade-in allowance
            totalTradeChassis = chassisAmt;
            System.debug('Trade-in capped at chassis amt (sep line): ' + String.valueOf(totalTradeChassis));
        }
        if (totalTradeChassis>0 && taxrules.Trade_NetChassis__c!=true) {	// BLL25c change to chassis portion of trade allowance
            // Don't ever exceed chassis amount (for now at least) 
            // Chassis amount is adjusted by the 4502!
            TaxSvc.Line line = new TaxSvc.Line();
            //BLL13d line.OriginCode = 'Customer';
            line.DestinationCode = 'Customer';	// BLL13a
            if (taxrules.OriginSourced__c) {line.OriginCode=line.DestinationCode; /* bll57d line.DestinationCode=null; */ }	// BLL20a
            line.No = String.valueOf(lineNbr++);
            //line.DestinationCode = gettaxReq.DestinationCode;
            line.itemCode = 'Trade-in(s)';
            line.Description = tradeDescr;
            line.Amount = -totalTradeChassis;	// BLL25c change to chassis portion of trade allowance
            if (newVehicle && taxrules.TradeLimitNew__c!=null && taxrules.TradeLimitNew__c<totalTradeChassis) {
                line.Amount = -taxrules.TradeLimitNew__c;
                NTSaleAdjAmt -= totalTradeChassis - taxrules.TradeLimitNew__c; // BLL49a
            }
            if (!newVehicle && taxrules.TradeLimitUsed__c!=null && taxrules.TradeLimitUsed__c<totalTradeChassis) {
                line.Amount = -taxrules.TradeLimitUsed__c;
                NTSaleAdjAmt -= totalTradeChassis - taxrules.TradeLimitUsed__c; // BLL49a
            }
            line.TaxCode = taxrules.TradeIn__c;
            //if (line.Amount!=0.00) {
                gettaxReq.Lines.Line.add(line);
            //}
        }

        // Rebates & discounts
        if (lineNbr<90) lineNbr = 90;
        // BLL49a - combine rebates & handle overage from chassis less trade
        Decimal totalRebate = 0.00;	
        if (deal.dealer__Rebate__c!=null && deal.dealer__Rebate__c!=0) totalRebate += deal.dealer__Rebate__c;
        if (deal.Rebate_2__c!=null && deal.Rebate_2__c!=0) totalRebate += deal.Rebate_2__c;
        if (deal.Rebate_3__c!=null && deal.Rebate_3__c!=0) totalRebate += deal.Rebate_3__c;
		if (totalRebate!=0 && totalRebate>chassisAmt) {
			NTSaleAdjAmt -= totalRebate-chassisAmt;
			totalRebate -= chassisAmt;
		}
		String rebateDescriptions = '';
		if (!String.isBlank(deal.Rebate_Description__c)) rebateDescriptions += deal.Rebate_Description__c;
		if (!String.isBlank(deal.Rebate_2_Description__c)) rebateDescriptions += '; ' + deal.Rebate_2_Description__c;
		if (!String.isBlank(deal.Rebate_3_Description__c)) rebateDescriptions += '; ' + deal.Rebate_3_Description__c;
		
        // BLL49d if (deal.dealer__Rebate__c!=null && deal.dealer__Rebate__c!=0) {
        if (totalRebate!=0) {	// BLL49a 
            TaxSvc.Line line = new TaxSvc.Line();
            //BLL13d line.OriginCode = 'Customer';
            line.DestinationCode = 'Customer';	// BLL13a
            if (taxrules.OriginSourced__c) {line.OriginCode=line.DestinationCode; /* BLL57d line.DestinationCode=null; */ }	// BLL20a
            line.No = String.valueOf(lineNbr++);
            //line.DestinationCode = gettaxReq.DestinationCode;
            line.ItemCode = 'Rebate';
            //BLL49d line.Description = deal.Rebate_Description__c;  
            //BLL49d line.Amount = -deal.dealer__Rebate__c;
            line.Description = rebateDescriptions;
            line.Amount = -totalRebate;
            line.TaxCode = taxrules.Rebate__c;
            gettaxReq.Lines.Line.add(line);
        }
        //if (deal.Rebate_2__c!=null && deal.Rebate_2__c!=0) {
        //    TaxSvc.Line line = new TaxSvc.Line();
        //    //BLL13d line.OriginCode = 'Customer';
        //    line.DestinationCode = 'Customer';	// BLL13a
        //    if (taxrules.OriginSourced__c) {line.OriginCode=line.DestinationCode; /* bll57d line.DestinationCode=null; */ }	// BLL20a
        //    line.No = String.valueOf(lineNbr++);
        //    //line.DestinationCode = gettaxReq.DestinationCode;
        //    line.ItemCode = 'Rebate';
        //    line.Description = deal.Rebate_2_Description__c;    
        //    line.Amount = -deal.Rebate_2__c; 
        //    line.TaxCode = taxrules.Rebate__c;
        //    gettaxReq.Lines.Line.add(line);
        //}
        //if (deal.Rebate_3__c!=null && deal.Rebate_3__c!=0) {
        //    TaxSvc.Line line = new TaxSvc.Line();
        //    //BLL13d line.OriginCode = 'Customer';
        //    line.DestinationCode = 'Customer';	// BLL13a
        //    if (taxrules.OriginSourced__c) {line.OriginCode=line.DestinationCode; /* bll57d line.DestinationCode=null; */ }	// BLL20a
        //    line.No = String.valueOf(lineNbr++);
        //    //line.DestinationCode = gettaxReq.DestinationCode;
        //    line.ItemCode = 'Rebate';
        //    line.Description = deal.Rebate_3_Description__c;    
        //    line.Amount = -deal.Rebate_3__c; 
        //    line.TaxCode = taxrules.Rebate__c;
        //    gettaxReq.Lines.Line.add(line);
        //}
        if (deal.MBW_Rewards__c!=null && deal.MBW_Rewards__c!=0) {
            TaxSvc.Line line = new TaxSvc.Line();
            //BLL13d line.OriginCode = 'Customer';
            line.DestinationCode = 'Customer';	// BLL13a
            if (taxrules.OriginSourced__c) {line.OriginCode=line.DestinationCode; /* bll57d line.DestinationCode=null; */ }	// BLL20a
            line.No = String.valueOf(lineNbr++);
            //line.DestinationCode = gettaxReq.DestinationCode;
            line.ItemCode = 'MBW Rewards';
            line.Description = 'MBW Rewards';   
            line.Amount = -deal.MBW_Rewards__c; 
            line.TaxCode = taxrules.MobilityWorksRebate__c;
            gettaxReq.Lines.Line.add(line);
        }
        // BLL23d
        //if (deal.Conversion_Discount__c!=null && deal.Conversion_Discount__c!=0) {
        //    TaxSvc.Line line = new TaxSvc.Line();
        //    //BLL13d line.OriginCode = 'Customer';
        //    line.DestinationCode = 'Customer';	// BLL13a
        //    if (taxrules.OriginSourced__c) {line.OriginCode=line.DestinationCode; /* bll57d line.DestinationCode=null; */ }	// BLL20a
        //    line.No = String.valueOf(lineNbr++);
        //    //line.DestinationCode = gettaxReq.DestinationCode;
        //    line.ItemCode = 'Conversion discount';
        //    line.Description = 'Conversion discount';   
        //    line.Amount = -deal.Conversion_Discount__c; 
        //    //line.TaxCode = taxrules.ConversionDiscount__c; Use same code as used for conversion!
        //    line.TaxCode = (deal.Conversion_Taxable__c) ? taxrules.ConversionTX__c : taxrules.Conversion__c;
        //    gettaxReq.Lines.Line.add(line);
        //}
        // BLL23d end
        
        if (chassisLine!=null && taxrules.ChassisMaxTaxable__c!=null && taxrules.ChassisMaxTaxable__c>0.00
				&& chassisLine.Amount>taxrules.ChassisMaxTaxable__c) {
			NTSaleAdjAmt += chassisLine.Amount-taxrules.ChassisMaxTaxable__c; // BLL49a
			chassisLine.Amount = taxrules.ChassisMaxTaxable__c; // BLL11a
		}
        
		// BLL27a - if not taxing out-of-state, then change all tax codes to 'NT'
		//BLL37d if (OutOfState!=null && deal.DoNotCollectTax__c==true && deal.dealer__Deal_Type__c!='Equipment Only Sale') {
		//BLL37d 	for(TaxSvc.Line l : gettaxReq.Lines.Line) {
		//BLL37d 		System.debug(l.DestinationCode);
		//BLL37d 		System.debug(l.OriginCode);
		//BLL37d 		//BLL32d if (l.DestinationCode!=null && l.DestinationCode!='Store') l.TaxCode = 'NT';
		//BLL37d 		if ((l.DestinationCode!=null && l.DestinationCode!='Store')	
		//BLL37d 		 	|| (l.DestinationCode==null && l.OriginCode!=null && l.OriginCode!='Store')) l.TaxCode = 'NT';	// BLL32a
		//BLL37d 	}
		//BLL37d 	System.debug('*** NOT COLLECTING TAX ON OUT-OF-STATE DEAL ***');
		//BLL37d }
		// BLL27a end
		
		// BLL49a non-taxable adjustment so Avalara has the correct total sale price
        if (NTSaleAdjAmt!=0) {
            TaxSvc.Line line = new TaxSvc.Line();
            //BLL13d line.OriginCode = 'Customer';
            line.DestinationCode = 'Customer';	// BLL13a
            line.No = String.valueOf(lineNbr++);
            //line.DestinationCode = gettaxReq.DestinationCode;
            line.ItemCode = 'NT adjustments';
            line.Description = 'Nontaxable adjustments';   
            line.Amount = NTSaleAdjAmt; 
            line.TaxCode = 'NT';
            gettaxReq.Lines.Line.add(line);
        }
		

        // Wholesale - all NT
        //Schema.RecordTypeInfo wholesaleRt = RcdTypes.get('Wholesale');
        //if (wholesaleRt!=null && deal.RecordTypeId==wholesaleRt.getRecordTypeId()) {
        //  for (TaxSvc.Line l : gettaxReq.Lines.Line) {
        //      l.TaxCode = 'NT';
        //      l.Description = 'Wholesale: ' + l.Description;
        //  }
        //}

        if (gettaxReq!=null && gettaxReq.Lines!=null) {
            debugTaxRequestLines();
            // Fix any null tax codes - plug with P0000000
            for (TaxSvc.Line l : gettaxReq.Lines.Line) {
                if (l.TaxCode==null) l.TaxCode = 'P0000000';
            }
        }

    }

	// BLL48a
	// getLeaseSalesTaxInPmt
	//public String getLeaseSalesTaxInPmt() {
	//	//return customerrules.SalesTaxWithLeasePmt__c;
	//	return customerrules.IncludeInMonthlyLeasePmt__c;
	//}
	public String getLeaseTaxMethod() {
		return customerrules!=null ? customerrules.Lease_sales_tax_method__c : null;	// BLL60c
	}
	// BLL48a end


    // setupRepairOrderId 
    //-----------------------------
    public void setupFromRepairOrderId(Id sroId) {
        objectId = sroId;
        dealer__Service_Repair_Order__c sro = [
            select Id, Name, dealer__Company__c, dealer__Customer__c, dealer__Customer__r.Name,  
                    dealer__Taxable__c, MobilityTaxable__c, HaveRequiredTaxCert__c, 	// BLL61c
                    dealer__Customer_Contact__c, dealer__Posted_Date_Time__c, TaxExemptService__c // BLL3c
            from dealer__Service_Repair_Order__c
            where Id=:sroId
        ];
        setupFromRepairOrderObj(sro);
    }
    
    // setupRepairOrderObj 
    //-----------------------------
    public void setupFromRepairOrderObj(dealer__Service_Repair_Order__c sro) {
        
        objectType = sro.getSObjectType().getDescribe().getName();
        setStore(sro.dealer__Company__c);

        // Load up tax rules
        taxrules = getTaxRules(sro.dealer__Company__c);

        if (sro.dealer__Customer__c!=null) {

            System.debug('Repair order customer id=' + sro.dealer__Customer__c);

            Account a=null;
            try {
                a = [
                select BillingStreet, BillingCity, BillingState, BillingPostalCode, 
                    SalesTaxStatus__c, ExemptionCertificate__c  // c2g__CODASalesTaxStatus__c, c2g__CODAExemptionCertificate__c
                from Account
                where Id=:sro.dealer__Customer__c
                limit 1 
            ];
            } catch(Exception e) {}
                
            // Generate request
            Date docdate = Date.today();
            if (sro.dealer__Posted_Date_Time__c!=null) docdate = sro.dealer__Posted_Date_Time__c.date();
            gettaxReq = getAvataxRequest(
                AVATAX_COMPANY, 
                sro.Name, 
                (String) sro.dealer__Customer__r.Name, 
                docdate,
                sro.dealer__Customer__c
            );
            gettaxReq.LocationCode = store!=null ? store.dealer__Company_Number__c : null;

            if (a!=null && a.SalesTaxStatus__c=='Exempt') {
                if (a.ExemptionCertificate__c!=null) {
                    gettaxReq.ExemptionNo = a.ExemptionCertificate__c;
                } else {
                    gettaxReq.ExemptionNo = 'OnFile';
                }
            // BLL3a - if RO is exempt tell Avalara it's exempt (usually for ROs paid by the VA or similar)
            } else {
            	if (sro.TaxExemptService__c == true) gettaxReq.ExemptionNo = 'ExemptRO';
            // BLL3a end
            }

            // Generate lines
            // Sum by SIC code? By Line? by Part?
                
            // Lines (labor, part, sublet)
            List<dealer__Service_Job__c> jobLines = [ 
                select dealer__Line_Number__c, dealer__Standard_Operation_Code__r.OperationTaxType__c,
                    dealer__Labor_Charges__c, dealer__Parts_Total__c, dealer__Sublet_Total__c,
					dealer__Labor_Type__c // BLL8a
                from dealer__Service_Job__c 
                where dealer__Service_Repair_Order__c =:sro.Id 
                  //BLL8d and dealer__Labor_Type__c='C' 
            ];

            // Misc charges (Customer-pay only), use std op code's avatax SIC id
            List<AggregateResult> miscChgs = [
                select Service_Job_Line__c, Type__c, max(Service_Job_Line__r.dealer__Line_Number__c) LineNo,
                    Service_Job_Line__r.dealer__Standard_Operation_Code__r.OperationTaxType__c TaxType,
					Service_Job_Line__r.dealer__Labor_Type__c LaborType, // BLL8a
                    sum(Amount__c) Amount
                from ServiceMiscCharges__c
                where Service_Job_Line__r.dealer__Service_Repair_Order__c=:sro.Id
                  //BLL8d and Service_Job_Line__r.dealer__Labor_Type__c='C'
                group by Service_Job_Line__c, Type__c, Service_Job_Line__r.dealer__Standard_Operation_Code__r.OperationTaxType__c,
                	Service_Job_Line__r.dealer__Labor_Type__c // BLL8a
            ];
            //BLL58d Set<Decimal> LineMiscChg = new Set<Decimal>();
            //BLL58d for(AggregateResult msc : miscChgs) {
            //BLL58d     if (((Decimal) msc.get('Amount'))>0.00) {
            //BLL58d         LineMiscChg.add((Decimal) msc.get('LineNo'));
            //BLL58d     }
            //BLL58d }

            // Build lines for tax request
            gettaxReq.Lines = new TaxSvc.ArrayOfLine();
            gettaxReq.Lines.Line = new List<TaxSvc.Line>();

            Map<Decimal,Decimal> lineTaxableMiscAmt = new Map<Decimal,Decimal>();	// BLL33a
            // BLL33a move misc charges above other line processes because of need to know if any are taxable (not NT)
            // How to assign "Shop Supplies", "Hazardous Materials", "Freight", "Other"???
            // Miscellaneous charges
            for(AggregateResult m : miscChgs) {
                TaxRuleOpCodeSetting__c op = taxRuleOpCodeMap.get((String) m.get('TaxType'));
                //BLL61d String miscSIC = sro.MobilityTaxable__c ? taxrules.RepairMiscTX__c : taxrules.RepairMisc__c;
                // BLL61a
                String miscSIC = taxrules.RepairMisc__c;
                if (!String.isBlank(taxrules.TaxDocumentRequired__c) && sro.HaveRequiredTaxCert__c) miscSIC = taxrules.RepairMiscWithCert__c;
                if (sro.MobilityTaxable__c) miscSIC = taxrules.RepairMiscTX__c;
                // BLL61a end
                if (op!=null) miscSIC = sro.MobilityTaxable__c ? op.MiscTX__c : op.Misc__c;
                // BLL33a - override by type
                String taxtype = (String) m.get('TaxType');
                if (taxtype==null) taxtype='Non-mobility';
                String miscChgOvr =  ((String) m.get('Type__c')) + ':' + taxtype;
                if (taxRuleOverrides.containsKey(miscChgOvr)) {
                    TaxRuleOverride__c ovr = taxRuleOverrides.get(miscChgOvr);
                    //BLL58d miscSIC = ovr.TaxCode__c;
					//BLL61d miscSIC = sro.MobilityTaxable__c ? ovr.TaxCodeTX__c : ovr.TaxCode__c;	// BLL58a
					miscSIC = ovr.TaxCode__c;	// BLL61a
					if (!String.isBlank(taxrules.TaxDocumentRequired__c) && sro.HaveRequiredTaxCert__c) miscSIC = ovr.TaxCodeWithCert__c;	// BLL61a
					if (sro.MobilityTaxable__c) miscSIC = ovr.TaxCodeTX__c;	// BLL61a
                    System.debug('Override tax code (' + miscChgOvr + ') : ' + miscSIC);
                }
                // BLL33a end
                if (m.get('LaborType')=='I' && taxrules.InternalOverride__c!=null) miscSIC = taxrules.InternalOverride__c; 
                if (m.get('LaborType')=='W' && taxrules.WarrantyOverride__c!=null) miscSIC = taxrules.WarrantyOverride__c; 
                // Misc
                Decimal misc = m.get('Amount')!=null ? ((Decimal) m.get('Amount')).setScale(2) : 0.00;
                if (misc!=null && misc!=0) {
                    TaxSvc.Line line = new TaxSvc.Line();
                    //line.No = String.valueOf(lineNbr++);
                    line.No = String.valueOf(m.get('LineNo')) + ': Misc ' + m.get('Type__c') + ' (' + m.get('LaborType') + ')';
                    line.ItemCode = String.valueOf(m.get('LineNo')) + ': Misc ' + m.get('Type__c') + ' (' + m.get('LaborType') + ')';
                    line.Description = line.ItemCode;   
                    line.Amount = misc; 
                    line.TaxCode = miscSIC;
                    gettaxReq.Lines.Line.add(line);
                    // BLL33a
                   	Decimal linenbr = (Decimal) m.get('LineNo');
                   	if (linenbr==null) linenbr = 0;
                   	linenbr = linenbr.round();
                   	Decimal amt = lineTaxableMiscAmt.get(linenbr);
                   	if (amt==null) amt=0.00;
                   	if (line.Amount!=0 && line.TaxCode!='NT') amt += line.Amount;
                   	if (linenbr!=null && amt!=null) lineTaxableMiscAmt.put(linenbr, amt); 
                    // BLL33a end
                }
            } // end for misc


			// BLL64
			boolean PartsOrSubletTaxable = false;
			Set<String> NonTaxableCodes = new Set<String>{'PH050302','NT'};
			Set<String> LaborOnlyCodes = new Set<String>{'SI020200'};
			// BLL64 end

            //Integer lineNbr = 1;
            for(dealer__Service_Job__c j : jobLines) {
                TaxRuleOpCodeSetting__c op = taxRuleOpCodeMap.get(j.dealer__Standard_Operation_Code__r.OperationTaxType__c);
                //BLL61d String partsSIC = sro.MobilityTaxable__c ? taxrules.RepairPartsTX__c : taxrules.RepairParts__c;
                //BLL61d String laborSIC = sro.MobilityTaxable__c ? taxrules.RepairLaborTX__c : taxrules.RepairLabor__c;
                //BLL61d String subletSIC = sro.MobilityTaxable__c ? taxrules.RepairSubletTX__c : taxrules.RepairSublet__c;
                // BLL61a
                String partsSIC = taxrules.RepairParts__c;	
                String laborSIC = taxrules.RepairLabor__c;
                String subletSIC = taxrules.RepairSublet__c;
                if (!String.isBlank(taxrules.TaxDocumentRequired__c) && sro.HaveRequiredTaxCert__c) {
                	if (!String.isBlank(taxrules.RepairPartsWithCert__c)) partsSIC = taxrules.RepairPartsWithCert__c;
                	if (!String.isBlank(taxrules.RepairLaborWithCert__c)) laborSIC = taxrules.RepairLaborWithCert__c;
                	if (!String.isBlank(taxrules.RepairSubletWithCert__c)) subletSIC = taxrules.RepairSubletWithCert__c;
                }
                // BLL61a end
                if (op!=null) {
                    //BLL61d partsSIC = sro.MobilityTaxable__c ? op.PartsTX__c : op.Parts__c;
                    //BLL61d laborSIC = sro.MobilityTaxable__c ? op.LaborTX__c : op.Labor__c;
                    //BLL61d subletSIC = sro.MobilityTaxable__c ? op.SubletTX__c : op.Sublet__c;
                    // BLL61a
                    if (!String.isBlank(op.Parts__c) && !sro.MobilityTaxable__c) partsSIC = op.Parts__c;
                    if (!String.isBlank(op.Labor__c) && !sro.MobilityTaxable__c) laborSIC = op.Labor__c;
                    if (!String.isBlank(op.Sublet__c) && !sro.MobilityTaxable__c) subletSIC = op.Sublet__c;
	                if (!String.isBlank(taxrules.TaxDocumentRequired__c) && sro.HaveRequiredTaxCert__c) {
                    	if (!String.isBlank(op.PartsWithCert__c) && !sro.MobilityTaxable__c) partsSIC = op.PartsWithCert__c;
                    	if (!String.isBlank(op.LaborWithCert__c) && !sro.MobilityTaxable__c) laborSIC = op.LaborWithCert__c;
                    	if (!String.isBlank(op.SubletWithCert__c) && !sro.MobilityTaxable__c) subletSIC = op.SubletWithCert__c;
	                }
	                if (!String.isBlank(op.PartsTX__c) && sro.MobilityTaxable__c) partsSIC = op.PartsTX__c;
	                if (!String.isBlank(op.LaborTX__c) && sro.MobilityTaxable__c) laborSIC = op.LaborTX__c;
	                if (!String.isBlank(op.SubletTX__c) && sro.MobilityTaxable__c) subletSIC = op.SubletTX__c;
	                // BLL61a end
                }
                if (j.dealer__Labor_Type__c=='I' && taxrules.InternalOverride__c!=null) {
                	partsSIC = taxrules.InternalOverride__c;
                	laborSIC = taxrules.InternalOverride__c;
                	subletSIC = taxrules.InternalOverride__c;
                } 
                if (j.dealer__Labor_Type__c=='W' && taxrules.WarrantyOverride__c!=null) {
                	partsSIC = taxrules.WarrantyOverride__c; 
                	laborSIC = taxrules.WarrantyOverride__c; 
                	subletSIC = taxrules.WarrantyOverride__c; 
                } 

                Decimal labor = j.dealer__Labor_Charges__c!=null ? j.dealer__Labor_Charges__c.setScale(2) : 0.00;
                Decimal parts = j.dealer__Parts_Total__c!=null ? j.dealer__Parts_Total__c.setScale(2) : 0.00;
                Decimal sublet = j.dealer__Sublet_Total__c!=null ? j.dealer__Sublet_Total__c.setScale(2) : 0.00;
                //boolean haveMisc = LineMiscChg.contains(j.dealer__Line_Number__c);  // misc chgs are generally not taxable per Janeen P. 12/4/2015
                
                // Parts
                if (parts!=null && parts>0) {
                    TaxSvc.Line line = new TaxSvc.Line();
                    //line.No = String.valueOf(lineNbr++);
                    line.No = String.valueOf(j.dealer__Line_Number__c) + ': Parts' + ' (' + j.dealer__Labor_Type__c + ')';
                    line.ItemCode = String.valueOf(j.dealer__Line_Number__c) + ': Parts' + ' (' + j.dealer__Labor_Type__c + ')';
                    line.Description = line.ItemCode;   
                    line.Amount = parts; 
                    line.TaxCode = partsSIC;
                    gettaxReq.Lines.Line.add(line);
					// BLL64
					PartsOrSubletTaxable = PartsOrSubletTaxable || !NonTaxableCodes.contains(line.TaxCode);
					System.debug(line.TaxCode);
					System.debug(PartsOrSubletTaxable);
					// BLL64 end
                }
                // Sublet
                if (sublet!=null && sublet>0) {
                    TaxSvc.Line line = new TaxSvc.Line();
                    //line.No = String.valueOf(lineNbr++);
                    line.No = String.valueOf(j.dealer__Line_Number__c) + ': Sublet' + ' (' + j.dealer__Labor_Type__c + ')';
                    line.ItemCode = String.valueOf(j.dealer__Line_Number__c) + ': Sublet' + ' (' + j.dealer__Labor_Type__c + ')';
                    line.Description = line.ItemCode;   
                    line.Amount = sublet; 
                    line.TaxCode = subletSIC;
                    gettaxReq.Lines.Line.add(line);
					// BLL64
					PartsOrSubletTaxable = PartsOrSubletTaxable || !NonTaxableCodes.contains(line.TaxCode);
					System.debug(line.TaxCode);
					System.debug(PartsOrSubletTaxable);
					// BLL64 end
                }
                // BLL33c move labor to last
                // Labor
                if (labor!=null && labor>0) {
                    TaxSvc.Line line = new TaxSvc.Line();
                    //line.No = String.valueOf(lineNbr++);
                    line.No = String.valueOf(j.dealer__Line_Number__c) + ': Labor' + ' (' + j.dealer__Labor_Type__c + ')';
                    line.ItemCode = String.valueOf(j.dealer__Line_Number__c) + ': Labor' + ' (' + j.dealer__Labor_Type__c + ')';
                    line.Description = line.ItemCode;   
                    line.Amount = labor; 
                    line.TaxCode = laborSIC;
					// BLL33a
                   	Decimal linenbr = j.dealer__Line_Number__c!=null ? j.dealer__Line_Number__c : 0;
                   	linenbr = linenbr.round();
                   	Decimal taxablemiscamt = lineTaxableMiscAmt.get(linenbr);
                   	// BLL33a
                    if (taxRuleOverrides.containsKey('Labor:NoPartOrSublet') && parts==0 && sublet==0) {
                        TaxRuleOverride__c ovr = taxRuleOverrides.get('Labor:NoPartOrSublet');
                        line.TaxCode = ovr.TaxCode__c; 
                    }
                    // BLL33a
                    if (taxRuleOverrides.containsKey('Labor:NoPartSubletMisc') && parts==0 && sublet==0 && taxablemiscamt==0) {
                        TaxRuleOverride__c ovr = taxRuleOverrides.get('Labor:NoPartSubletMisc');
                        line.TaxCode = ovr.TaxCode__c; 
                    }
                    // BLL33a end
                    gettaxReq.Lines.Line.add(line);
                }
            } // end for sumlines

			// BLL64 - go back through labor if Labor:NoTaxablePartSubletMiscOnRO
			// Change stand-alone-labor tax code with Labor with parts tax code
			TaxRuleOverride__c spclovr = taxRuleOverrides.get('Labor:NoTaxablePartSubletMiscOnRO');
			System.debug(spclovr);
			if (spclovr!=null && PartsOrSubletTaxable) {
				for(TaxSvc.Line l : gettaxReq.Lines.Line) {
					if (l.ItemCode !=null && l.ItemCode.contains(': Labor') && LaborOnlyCodes.contains(l.TaxCode)) {
						l.TaxCode = spclovr.TaxCode__c;
						System.debug(l);
					}
				}
			}
			// BLL64 end

        } // end if customer!=null 
        
        if (gettaxReq!=null && gettaxReq.Lines!=null) {
            debugTaxRequestLines();
            // Fix any null tax codes - plug with P0000000
            for (TaxSvc.Line l : gettaxReq.Lines.Line) {
                if (l.TaxCode==null) l.TaxCode = 'P0000000';
            }
        }

    } // end setupFromRepairOrderObj

    
    // setupFromRentalId
    //-----------------------------
    public void setupFromRentalId(Id raId) {
        dealer__Rental_Agreements__c ra = [
            select Id, Name, Location__c, Account__c, dealer__Contact__c, dealer__Contact__r.Name,
                Rentcentric_Contract__c, dealer__Return_Date__c, Total_Charges__c,
                Rental_fee__c, Pickup_Delivery_Fee__c, Excess_Miles_Charge__c, dealer__Refueling_Fee__c,
                dealer__Adjustment_Charges__c, dealer__Discount__c, 
                Sales_Tax__c, CountySalesTax__c, CitySalesTax__c, ThirdTierRentalTax__c 
            from dealer__Rental_Agreements__c
            where Id=:raId
        ];
        setupFromRentalObj(ra);
    }
    // setupFromRentalObj
    //-----------------------------
    public void setupFromRentalObj(dealer__Rental_Agreements__c ra) {
        objectType = ra.getSObjectType().getDescribe().getName();
        objectId = ra.Id;
        
        if (ra.Sales_Tax__c==null) ra.Sales_Tax__c = 0.00;
        if (ra.CountySalesTax__c==null) ra.CountySalesTax__c = 0.00;
        if (ra.CitySalesTax__c==null) ra.CitySalesTax__c = 0.00;
        if (ra.ThirdTierRentalTax__c==null) ra.ThirdTierRentalTax__c = 0.00;
        Decimal TotalCharges = (ra.Total_Charges__c==null) ? 0.00 : ra.Total_Charges__c; // BLL6a
        
        Account a = [
            select BillingStreet, BillingCity, BillingState, BillingPostalCode, 
                SalesTaxStatus__c, ExemptionCertificate__c  // c2g__CODASalesTaxStatus__c, c2g__CODAExemptionCertificate__c
            from Account
            where Id=:ra.Account__c
            limit 1 
        ];
        setStore(ra.Location__c);
        // Always charge with store as the destination
        StreetAddress o = storeaddr;
        String street = o.Street1;
        if (!String.isBlank(o.Street2)) street += '\n' + o.Street2;
        if (!String.isBlank(o.Street3)) street += '\n' + o.Street3;
        // assume for rentals the customer address for taxing is the same as the 
        // dealership location they rented from
        // setCustAddr(new StreetAddress(street, o.City, o.State, o.PostalCode));

        taxrules = getTaxRules(ra.Location__c);

        // Generate request & lines for a Rental
        // Generate request
        Date docdate = Date.today();
        if (ra.dealer__Return_Date__c!=null) docdate = ra.dealer__Return_Date__c;
        gettaxReq = getAvataxRequest(
            AVATAX_COMPANY, 
            ra.Name, 
            (String) ra.dealer__Contact__r.Name, 
            docdate,
            ra.Account__c
        );
        gettaxReq.LocationCode = store!=null ? store.dealer__Company_Number__c : null;
        if (a!=null && a.SalesTaxStatus__c=='Exempt') {
            if (a.ExemptionCertificate__c!=null) {
                gettaxReq.ExemptionNo = a.ExemptionCertificate__c;
            } else {
                gettaxReq.ExemptionNo = 'OnFile';
            }
        }

        // Generate lines
        gettaxReq.Lines = new TaxSvc.ArrayOfLine();
        gettaxReq.Lines.Line = new List<TaxSvc.Line>();
        Integer lineNbr = 0;
        Decimal TotalTax = ra.Sales_Tax__c + ra.CountySalesTax__c + ra.CitySalesTax__c + ra.ThirdTierRentalTax__c;	// BLL6a
        Decimal TotalSale = TotalCharges - TotalTax;	// BLL6a

        // Option 1: One line for rental
        //-------------------------------------
            TaxSvc.Line line = new TaxSvc.Line();
            line.No = String.valueOf(lineNbr++);
            line.ItemCode = 'Rental';
            line.Description = line.ItemCode + ' ' + ra.Rentcentric_Contract__c;    
            // BLL6d line.Amount = ra.Total_Charges__c;
            line.Amount = TotalSale; 	// BLL6a 
            line.TaxCode = taxrules.RentalFee__c;
            gettaxReq.Lines.Line.add(line);

        // Override total tax (already calculated by Rentcentric)
            gettaxReq.TaxOverride = new TaxSvc.TaxOverride();
            gettaxReq.TaxOverride.TaxOverrideType = 'TaxAmount';
            // BLL6d gettaxReq.TaxOverride.TaxAmount = ra.Sales_Tax__c + ra.CountySalesTax__c + ra.CitySalesTax__c + ra.ThirdTierRentalTax__c;
            gettaxReq.TaxOverride.TaxAmount = TotalTax;	// BLL6a   
            gettaxReq.TaxOverride.TaxDate = gettaxReq.DocDate;
            gettaxReq.TaxOverride.Reason = 'Rentcentric contract ' + ra.Rentcentric_Contract__c;
            
        // Option 2: One line for each tax jurisdiction (state, city, county, third tier)
        //-------------------------------------
            //Integer TaxLines = 1;
            //if (ra.CountySalesTax__c!=null && ra.CountySalesTax__c!=0) TaxLines++;
            //if (ra.CitySalesTax__c!=null && ra.CitySalesTax__c!=0) TaxLines++;
            //if (ra.ThirdTierRentalTax__c!=null && ra.ThirdTierRentalTax__c!=0) TaxLines++;
            
            //Decimal ChargePerLine = ra.Total_Charges__c / TaxLines;
            //ChargePerLine = ChargePerLine.setScale(2);
            //Decimal Charge = ra.Total_Charges__c - (ChargePerLine * (TaxLines-1));
            
            // Option 2: One line for each kind of tax, override tax at the line level      
            //-------------------------------------
            // Sales_Tax__c, CountySalesTax__c, CitySalesTax__c, ThirdTierRentalTax__c
            //if (ra.Sales_Tax__c!=null && ra.Sales_Tax__c!=0) { 
            //  TaxSvc.Line line = new TaxSvc.Line();
            //  line.No = String.valueOf(lineNbr++);
            //  line.ItemCode = 'Rental Sales Tax';
            //  line.Description = line.ItemCode + ' ' + ra.Rentcentric_Contract__c;    
            //  line.Amount = Charge;
            //  Charge = ChargePerLine; 
            //  line.TaxCode = taxrules.RentalFee__c;
            //  line.TaxOverride = new TaxSvc.TaxOverride();
            //  line.TaxOverride.TaxOverrideType = 'TaxAmount';
            //  line.TaxOverride.TaxAmount = ra.Sales_Tax__c;   
            //  line.TaxOverride.TaxDate = gettaxReq.DocDate;
            //  line.TaxOverride.Reason = 'Sales Tax from Rentcentric ' + ra.Rentcentric_Contract__c;
            //  gettaxReq.Lines.Line.add(line);
            //}
            //if (ra.CountySalesTax__c!=null && ra.CountySalesTax__c!=0) { 
            //  TaxSvc.Line line = new TaxSvc.Line();
            //  line.No = String.valueOf(lineNbr++);
            //  line.ItemCode = 'Rental County Tax';
            //  line.Description = line.ItemCode + ' ' + ra.Rentcentric_Contract__c;    
            //  line.Amount = Charge;
            //  Charge = ChargePerLine; 
            //  line.TaxCode = taxrules.RentalFee__c;
            //  line.TaxOverride = new TaxSvc.TaxOverride();
            //  line.TaxOverride.TaxOverrideType = 'TaxAmount';
            //  line.TaxOverride.TaxAmount = ra.CountySalesTax__c;  
            //  line.TaxOverride.TaxDate = gettaxReq.DocDate;
            //  line.TaxOverride.Reason = 'County Tax from Rentcentric ' + ra.Rentcentric_Contract__c;
            //  gettaxReq.Lines.Line.add(line);
            //}
            //if (ra.CitySalesTax__c!=null && ra.CitySalesTax__c!=0) { 
            //  TaxSvc.Line line = new TaxSvc.Line();
            //  line.No = String.valueOf(lineNbr++);
            //  line.ItemCode = 'Rental City Tax';
            //  line.Description = line.ItemCode + ' ' + ra.Rentcentric_Contract__c;    
            //  line.Amount = Charge;
            //  Charge = ChargePerLine; 
            //  line.TaxCode = taxrules.RentalFee__c;
            //  line.TaxOverride = new TaxSvc.TaxOverride();
            //  line.TaxOverride.TaxOverrideType = 'TaxAmount';
            //  line.TaxOverride.TaxAmount = ra.CitySalesTax__c;    
            //  line.TaxOverride.TaxDate = gettaxReq.DocDate;
            //  line.TaxOverride.Reason = 'City Tax from Rentcentric ' + ra.Rentcentric_Contract__c;
            //  gettaxReq.Lines.Line.add(line);
            //}
            //if (ra.ThirdTierRentalTax__c!=null && ra.ThirdTierRentalTax__c!=0) { 
            //  TaxSvc.Line line = new TaxSvc.Line();
            //  line.No = String.valueOf(lineNbr++);
            //  line.ItemCode = 'Rental Third Tier Tax';
            //  line.Description = line.ItemCode + ' ' + ra.Rentcentric_Contract__c;    
            //  line.Amount = Charge;
            //  Charge = ChargePerLine; 
            //  line.TaxCode = taxrules.RentalFee__c;
            //  line.TaxOverride = new TaxSvc.TaxOverride();
            //  line.TaxOverride.TaxOverrideType = 'TaxAmount';
            //  line.TaxOverride.TaxAmount = ra.ThirdTierRentalTax__c;  
            //  line.TaxOverride.TaxDate = gettaxReq.DocDate;
            //  line.TaxOverride.Reason = 'Third Tier Tax from Rentcentric ' + ra.Rentcentric_Contract__c;
            //  gettaxReq.Lines.Line.add(line);
            //}

        if (gettaxReq!=null && gettaxReq.Lines!=null) {
            debugTaxRequestLines();
            // Fix any null tax codes - plug with P0000000
            for (TaxSvc.Line l : gettaxReq.Lines.Line) {
                if (l.TaxCode==null) l.TaxCode = 'P0000000';
            }
        }

    }
    

    // calculateTax
    //-----------------------------
    public void calculateTax() {
		System.debug('calculateTax');
		
		// Debugging
		debugGetTaxRequest();	// BLL22a

        // Call out to get tax
        gettaxRslt = null;
        String resultText = '';
        Decimal tax = 0;
        if (gettaxReq!=null && gettaxReq.Lines!=null && gettaxReq.Lines.Line!=null && gettaxReq.Lines.Line.size()>0) {
            TaxSvc.TaxSvcSoap client = getAvataxClient();
            try {     
                gettaxRslt = client.GetTax(gettaxReq); // call AvaTax
                if(gettaxRslt.ResultCode == 'Success') {
                     resultText = 'GetTax Succeeded - Total Tax: ' + gettaxRslt.TotalTax;
                     tax = gettaxRslt.TotalTax;
                } else {
                     resultText = 'GetTax ' + gettaxRslt.ResultCode + ': ' +
                         gettaxRslt.Messages.Message[0].Name + ' : ' + gettaxRslt.Messages.Message[0].Summary; 
                     throw new AvaTaxException(resultText);
                }
            } catch(Exception ex) {
                resultText = ex.getMessage();
                if (!resultText.startsWith('GetTax')) resultText = 'GetTax ' + resultText;
                throw new AVATaxException(resultText);
            }
        } else {
            resultText = 'Nothing to tax';
        }
        summarizeTaxResult();
        TotalTax = tax;
        System.debug('*** ' + resultText + ' ***');
    }


    // summarizeRequestLines
    //-----------------------------
    public void summarizeRequestLines() {
        reqSummary = new Map<String,Decimal>();
        if (gettaxReq!=null && gettaxReq.Lines!=null) {
            for(TaxSvc.Line l : gettaxReq.Lines.Line) {
                Decimal amt = reqSummary.get(l.TaxCode);
                System.debug(l.TaxCode);
                System.debug(amt);
                if (amt==null) {
                    amt = 0.00;
                }
                amt += l.Amount==null ? 0.00 : l.Amount;
                reqSummary.put(l.TaxCode,amt);
            }
        }
    }
    

    // debugRequestSummary
    //----------------------------
    public void debugRequestSummary() {
        for(String k : reqSummary.keySet()) {
            System.debug(k + ': ' + String.valueOf(reqSummary.get(k)));
        }
    }


	// BLL22a
	// debugGetTaxRequest
	public void debugGetTaxRequest() {
		System.debug('*** GetTaxRequest ***');
		if (gettaxReq!=null) {
			System.debug('DocCode: ' + gettaxReq.DocCode + '  DocType: ' + gettaxReq.DocType + '  DocDate: ' + gettaxReq.DocDate);
			System.debug('CompanyCode: ' + gettaxReq.CompanyCode + '  CustomerCode: ' + gettaxReq.CustomerCode);
			System.debug('DetailLevel: ' + gettaxReq.DetailLevel + '  Commit_x: ' + gettaxReq.Commit_x + '  ReferenceCode: ' + gettaxReq.ReferenceCode);
			for(TaxSvc.BaseAddress add : gettaxReq.Addresses.BaseAddress) { 
				System.debug('Address: ' + add.AddressCode + ' = ' + add.Line1 + ', ' + add.City + ', ' + add.Region + ' ' + add.PostalCode);
			}
			System.debug('LocationCode: ' + gettaxReq.LocationCode + '  OriginCode: ' + gettaxReq.OriginCode + '  DestinationCode: ' + gettaxReq.DestinationCode);
			System.debug('ExemptionNo: ' + gettaxReq.ExemptionNo);
            for(TaxSvc.Line l : gettaxReq.Lines.Line) {
            	System.debug('Line ' + l.No + ': ' + l.ItemCode + ' ' + l.Description + ' ' + l.TaxCode + ' ' + String.ValueOf(l.Amount));
            	System.debug('       OriginCode=' + l.OriginCode + ', DestinationCode=' + l.DestinationCode);
            }
		}
	}    
	// BLL22a 
    
    // getHash
    //------------------------------
    public String getHash() {
        //String hashdata = JSON.serialize(gettaxReq); // extremely sensitive to changes
        //String jsondata = gettaxReq.DocDate.format() + JSON.serialize(storeaddr) + JSON.serialize(custaddr) + JSON.serialize(gettaxReq.Lines); // very sensitive to changes
        summarizeRequestLines();
        // If hash changes, we probably need to recalculate taxes
        //String hashdata = gettaxReq.DocDate.format() + JSON.serialize(storeaddr) + JSON.serialize(custaddr) + JSON.serialize(reqSummary);
        // Only consider month & year for document date
        Date docDate = Date.today();
        if (gettaxReq!=null && gettaxReq.DocDate!=null) {
            docDate = gettaxReq.DocDate;
        }
        String thismth = DateTime.now().format('MM-yyyy');	// BLL52a
        String exemptionNbr = (gettaxReq!=null && gettaxReq.ExemptionNo != null) ? gettaxReq.ExemptionNo : '';	// BLL29a
        String mmyyyy = Datetime.newInstance(docDate, Time.newInstance(0,0,0,0)).format('MM-yyyy');
        System.debug('DocDate MM-yyyy='+mmyyyy);
        if (docDate<=Date.today()) thismth = mmyyyy;	// BLL57a
        String hashdata = thismth + mmyyyy + exemptionNbr;  // BLL29c add exemptionNbr, BLL52c
        System.debug(storeaddr);
        System.debug(custaddr);
        System.debug(reqSummary);
        hashdata += JSON.serialize(storeaddr);
        hashdata += JSON.serialize(custaddr);
        hashdata += JSON.serialize(reqSummary);	
        Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(hashdata));
        String b64 = EncodingUtil.base64Encode(hash);
        return b64;     
    }

  
    // setStore address for tax calc
    //-----------------------------
    public void setStore(Id locId) {
    	try {
        store = [
            Select Name, dealer__Street__c, dealer__City__c, dealer__State__c, dealer__Postal_Code__c, TaxRuleSetting__c, dealer__Company_Number__c	// BLL43c
            From dealer__Dealer_Location__c
            Where Id=:locId
        ]; 
        //BLL43d setStoreAddr(new StreetAddress(store.dealer__Address__c, store.dealer__City__c, store.dealer__State__c, store.dealer__Postal_Code__c));
        setStoreAddr(new StreetAddress(store.dealer__Street__c, store.dealer__City__c, store.dealer__State__c, store.dealer__Postal_Code__c));	// BLL43a
    	} catch(Exception e) {}
    }

    
    // setStoreAddr
    //-----------------------------
    public void setStoreAddr(StreetAddress d) {
        storeaddr = d;
    }

  
    // setCustAddr
    //-----------------------------
    public void setCustAddr(StreetAddress d) {
        custaddr = d;
    }
 
 
     // Determine if running in a sandbox (to force test env. credentials)
    //-----------------------------
    public boolean isSandbox() {
        //BLL63d if (org==null) {
        //BLL63d    org = [select Id, Name, isSandbox from organization limit 1];
        //BLL63d }
        if (org==null) org=OrganizationSingleton.getInstance(); // BLL63a
        return org.isSandbox;
    }


    // return an Avatax Client (for SOAP calls)
    //-----------------------------
    public TaxSvc.TaxSvcSoap getAvataxClient() {
        TaxSvc.TaxSvcSoap taxSvc = null;
        String atEndpoint =  avatax_settings.SOAP_Endpoint__c;
        String atAccount = avatax_settings.Account__c;
        String atLicenseKey = avatax_settings.LicenseKey__c;

        if (isSandbox() || forceTestEndpoint) {
            atEndpoint = avatax_settings.Test_SOAP_Endpoint__c;
            atAccount = avatax_settings.Test_Account__c;
            atLicenseKey = avatax_settings.Test_LicenseKey__c;
        }
        
        taxSvc = new TaxSvc.TaxSvcSoap(atEndpoint);
        taxSvc.Security = new TaxSvc.Security();
        taxSvc.Security.UsernameToken.Username = atAccount;
        taxSvc.Security.UsernameToken.Password = atLicenseKey;
        taxSvc.Profile = new TaxSvc.Profile();
        taxSvc.Profile.Client = 'MobilityWorks,1,0';

        return taxSvc;
    }


    // return an Avatax Request (SOAP request object)
    //-----------------------------
    public TaxSvc.GetTaxRequest getAvataxRequest(String company, String document, String customerCode, Date documentDate, String referenceNo) {
        // Prepare GetTaxRequest
        TaxSvc.GetTaxRequest gtreq = new TaxSvc.GetTaxRequest();
        gtreq.DocCode = document;
        gtreq.DocType = 'SalesInvoice';
        gtreq.CustomerCode = customerCode;
        if (gtreq.CustomerCode!=null && gtreq.CustomerCode.length()>50) gtreq.CustomerCode = gtreq.CustomerCode.substring(0,50);	// BLL7a
        gtreq.CompanyCode = company;
        gtreq.DetailLevel = 'Tax';      
        gtreq.DocDate = documentDate;
        gtreq.Commit_x=false;
        gtreq.ReferenceCode = referenceNo;

        // Set addresses
        gtreq.Addresses = new TaxSvc.ArrayOfBaseAddress();
        gtreq.Addresses.BaseAddress = new List<TaxSvc.BaseAddress>();
        //if (custaddr!=null) {
        //    gtreq.Addresses.BaseAddress = new TaxSvc.BaseAddress[2];
        //} else {
        //    gtreq.Addresses.BaseAddress = new TaxSvc.BaseAddress[1];
        //}
        //gtreq.Addresses.BaseAddress[0] = getAvataxAddress('Origin', storeaddr);
        //gtreq.DestinationCode = gtreq.Addresses.BaseAddress[0].AddressCode;       
        gtreq.Addresses.BaseAddress.add(getAvataxAddress('Store', storeaddr));
        //gtreq.OriginCode = 'Store';
        //gtreq.DestinationCode = 'Store';
        
        // If we have a customer address
        if (custaddr!=null) {	
            //gtreq.Addresses.BaseAddress[1] = getAvataxAddress('Destination', custaddr);
            //gtreq.OriginCode = gtreq.Addresses.BaseAddress[1].AddressCode;
            gtreq.Addresses.BaseAddress.add(getAvataxAddress('Customer', custaddr));
            gtreq.DestinationCode = 'Customer';
            //BLL22d gtreq.OriginCode = 'Store'; Seems to be overriding things?
        } else {
            gtreq.OriginCode = 'Store';
            gtreq.DestinationCode = 'Store';
        }

        return gtreq;
    }
 
  
    // return an Avatax address object
    //-----------------------------
    public TaxSvc.BaseAddress getAvataxAddress(String type, StreetAddress addr) {
        //if(type!='Origin' && type != 'Destination') {
        //  throw new AVATaxException('Address Type must be Origin or Destination');
        //}

        TaxSvc.BaseAddress ataddr = new TaxSvc.BaseAddress();
        ataddr.AddressCode = type;
        if (addr!=null) {
        	ataddr.Line1 = addr.Street1;
        	if (!String.isBlank(addr.Street2)) ataddr.Line2 = addr.Street2;
        	if (!String.isBlank(addr.Street3)) ataddr.Line3 = addr.Street3;
        	ataddr.City = addr.City;
        	ataddr.Region = addr.State;
        	ataddr.PostalCode = addr.PostalCode;
        }

        return ataddr;
    }

 
    // StreetAddress (destination address)
    //-----------------------------
    public class StreetAddress {
        public String Street1=null;
        public String Street2=null;
        public String Street3=null;
        public String City=null;
        public String State=null;
        public String PostalCode=null;
        public StreetAddress(String s, String c, String st, String zip) {
            if (!String.isBlank(s)) {
                List<String> lines = s.split('\n');
                if (lines.size()>0) Street1 = lines[0];
                if (lines.size()>1) Street2 = lines[1];
                if (lines.size()>2) Street3 = lines[2];
            } else {
                Street1 = '';
            }
            City = String.isBlank(c) ? '' : c;
            State = String.isBlank(st) ? '' : st;
            PostalCode = String.isBlank(zip) ? '' :zip;
        }
    }  


    // getTaxRules
    //-----------------------------
    public TaxRuleSetting__c getTaxRules(Id locId) {
        return getTaxRules(locId, null);
    }
    public TaxRuleSetting__c getTaxRules(Id locId, String OutOfState) {
    	
    	// BLL48a - make query more dynamic
    	// Select all fields from TaxRuleSetting__c
		Map<String, Schema.SObjectField> trsFieldMap =  Schema.TaxRuleSetting__c.SObjectType.getDescribe().fields.getMap();
		List<String> trsFieldList = new List<String>();
		for(string f : trsFieldMap.keySet()) /* if (trsFieldMap.get(f).getDescribe().isAccessible()) */ trsFieldList.add(f);
		String trsfields = String.join(trsFieldList,',');

    	// Select all fields from TaxRuleOpCodeSetting__c
		Map<String, Schema.SObjectField> trosFieldMap =  Schema.TaxRuleOpCodeSetting__c.SObjectType.getDescribe().fields.getMap();
		List<String> trosFieldList = new List<String>();
		for(string f : trosFieldMap.keySet()) /* if (trosFieldMap.get(f).getDescribe().isAccessible()) */ trosFieldList.add(f);
		String trosfields = String.join(trosFieldList,',');

    	// Select all fields from TaxRuleSetting__c
		Map<String, Schema.SObjectField> troFieldMap =  Schema.TaxRuleOverride__c.SObjectType.getDescribe().fields.getMap();
		List<String> troFieldList = new List<String>();
		for(string f : troFieldMap.keySet()) /* if (troFieldMap.get(f).getDescribe().isAccessible()) */ troFieldList.add(f);
		String trofields = String.join(troFieldList,',');

        TaxRuleSetting__c rules = null;
        String soql = ' select ' + trsfields 
        		+ ', (select ' + trosfields + ' from Tax_Rule_Operation_Settings__r ) '
        		+ ', (select ' + trofields + ' from Tax_Rule_Overrides__r ) '
        		+ ' from TaxRuleSetting__c ';
        System.debug(soql); 
        try {
        	rules = Database.query(soql + ' where Id=\'' + store.TaxRuleSetting__c + '\' limit 1 ');
        } catch(Exception e1) {}
        try {
        	if (rules==null) {
        		rules = Database.query(soql + ' where Name=\'Default\' limit 1 ');
        	}
        } catch(Exception e2) {}
		// BLL48a end
		// BLL48d begin
        //try {
            //rules = [
            //    select Name, ProposalAutomaticCalc__c, Chassis__c, ChassisTX__c, Conversion__c, ConversionTX__c, AdaptiveEquipment__c, AdaptiveEquipmentTX__c,
            //        AdaptiveEquipLabor__c, AdaptiveEquipLaborTX__c, AdaptiveEquipSublet__c, AdaptiveEquipSubletTX__c,
            //        NMEDA__c, NMEDA_TX__c, 	// BLL16a
            //        ServiceContract__c, GAP__c, RoadsideProtection__c, DiamondFusion__c, TireWheel__c, 	// BLL45c
            //        ServiceContract_AtStore__c, GAP_AtStore__c, RoadsideProt_AtStore__c, DiamondFusion_AtStore__c, TireWheel_AtStore__c, 	// BLL45c  
            //        AutoGrant__c, Rebate__c, MobilityWorksRebate__c, ChassisDiscount__c,
            //        GPC__c, GPC_NetChassis__c,	// BLL44a
            //        ConversionGrant__c, ConvGrantReducesConv__c, 	// BLL24a 
            //        DocumentFee__c, ElectronicFilingFee__c, GVW_GVWR__c, LicenseFee__c, RegistrationFee__c,
            //        SmogCertificate__c, SmogFee__c, TireFee__c,
            //        TradeIn__c, TradeLimitNew__c, TradeLimitUsed__c, 
            //        Chassis_AtStore__c, ChassisMinTaxable__c, ChassisLessTrade__c, ChassisLessTrade_AtStore__c, // BLL4a
            //        DocumentFee_AtStore__c, // BLL13a (doc fee at store)
            //        LuxuryValue__c, LuxuryVehicle__c, ChassisMaxTaxable__c, // BLL4a, BLL11c max taxable
            //        AutoGrant_NetChassis__c, ChassisDiscount_NetChassis__c, Trade_NetChassis__c, ChassisFairMarketValue__c, FairMarketValueURL__c, // BLL3c
            //        CombineConversionWithChassis__c, CombineEquipmentWithConversion__c,  // BLL2a
            //        SeparateChassisConversionAllowance__c, Conversion_AtStore__c, AddedEquipment_AtStore__c, // BLL25a & BLL26a
            //        ChassisPriceSource__c, CombineDocFeeWithChassis__c, // BLL9a
            //        NoTradeOutOfState__c, // BLL30a
            //        RepairAutomaticCalc__c, RepairParts__c, RepairPartsTX__c, RepairLabor__c, RepairLaborTX__c, RepairSublet__c, RepairSubletTX__c, RepairMisc__c, RepairMiscTX__c,
            //        InternalOverride__c, WarrantyOverride__c, // BLL8a
            //        RentalAutomaticCalc__c,
            //        RentalFee__c, PickupDeliveryFee__c, ExcessMilesChg__c, RefuelingFee__c, AdjustmentCharges__c, RentalDiscount__c,
            //        OriginSourced__c, SalesTaxWithLeasePmt__c, // BLL20a, BLL48c
            //            ( select Id, OperationTaxType__c, Parts__c, PartsTX__c, Labor__c, LaborTX__c, Sublet__c, SubletTX__c, Misc__c, MiscTX__c
            //              from Tax_Rule_Operation_Settings__r   ), 
            //            ( select Id, Name, FieldName__c, Condition__c, TaxCode__c, TaxCodeTX__c, Tax_AtStore__c	// BLL47c add atstore
            //              from Tax_Rule_Overrides__r    )
            //    from TaxRuleSetting__c
            //    where Id=:store.TaxRuleSetting__c
            //    limit 1
            //];
        //} catch(Exception e) { 
        //    try {
        //        rules = [
        //            select Name, ProposalAutomaticCalc__c, Chassis__c, ChassisTX__c, Conversion__c, ConversionTX__c, AdaptiveEquipment__c, AdaptiveEquipmentTX__c,
        //                AdaptiveEquipLabor__c, AdaptiveEquipLaborTX__c, AdaptiveEquipSublet__c, AdaptiveEquipSubletTX__c,
	    //                NMEDA__c, NMEDA_TX__c, 	// BLL16a
        //                ServiceContract__c, GAP__c, RoadsideProtection__c, DiamondFusion__c, TireWheel__c, // BLL45c 
        //                ServiceContract_AtStore__c, GAP_AtStore__c, RoadsideProt_AtStore__c, DiamondFusion_AtStore__c,	TireWheel_AtStore__c, // BLL45c  
        //                AutoGrant__c, Rebate__c, MobilityWorksRebate__c, ChassisDiscount__c,
	    //                GPC__c, GPC_NetChassis__c,	// BLL44a
	    //                ConversionGrant__c, ConvGrantReducesConv__c, 	// BLL24a 
        //                DocumentFee__c, ElectronicFilingFee__c, GVW_GVWR__c, LicenseFee__c, RegistrationFee__c,
        //                SmogCertificate__c, SmogFee__c, TireFee__c,
        //                TradeIn__c, TradeLimitNew__c, TradeLimitUsed__c,  
	    //                Chassis_AtStore__c, ChassisMinTaxable__c, ChassisLessTrade__c, ChassisLessTrade_AtStore__c, // BLL4a
	    //                DocumentFee_AtStore__c, // BLL13a
	    //                LuxuryValue__c, LuxuryVehicle__c, ChassisMaxTaxable__c, // BLL4a, BLL11c max taxable
        //                AutoGrant_NetChassis__c, ChassisDiscount_NetChassis__c, Trade_NetChassis__c, ChassisFairMarketValue__c, FairMarketValueURL__c,  // BLL3c
        //                CombineConversionWithChassis__c, CombineEquipmentWithConversion__c,  // BLL2a 
	    //                SeparateChassisConversionAllowance__c, Conversion_AtStore__c, AddedEquipment_AtStore__c, // BLL25a & BLL26a
	    //                ChassisPriceSource__c, CombineDocFeeWithChassis__c, // BLL9a
	    //                NoTradeOutOfState__c, // BLL30a
        //                RepairAutomaticCalc__c, RepairParts__c, RepairPartsTX__c, RepairLabor__c, RepairLaborTX__c, RepairSublet__c, RepairSubletTX__c, RepairMisc__c, RepairMiscTX__c, 
	    //                InternalOverride__c, WarrantyOverride__c, // BLL8a
        //                RentalAutomaticCalc__c,
        //                RentalFee__c, PickupDeliveryFee__c, ExcessMilesChg__c, RefuelingFee__c, AdjustmentCharges__c, RentalDiscount__c, 
	    //                OriginSourced__c, SalesTaxWithLeasePmt__c, // BLL20a, BLL48c
        //                ( select Id, OperationTaxType__c, Parts__c, PartsTX__c, Labor__c, LaborTX__c, Sublet__c, SubletTX__c, Misc__c, MiscTX__c
        //                  from Tax_Rule_Operation_Settings__r   ), 
        //                ( select Id, Name, FieldName__c, Condition__c, TaxCode__c, TaxCodeTX__c, Tax_AtStore__c // BLL47c add atstore
        //                  from Tax_Rule_Overrides__r    )
        //            from TaxRuleSetting__c
        //            where Name='Default' 
        //            limit 1
        //        ];
        //    } catch(Exception e2) {}
        //}
		// BLL48d end

		storerules = rules;	// BLL? prep for change
		        
        // Out of state override
        if (!String.isBlank(OutOfState)) {	// BLL?c  was OutOfState!=null
        	OutOfState = OutOfState.toUpperCase();	// BLL13a
        	//BLL36d String FirstTwo = OutOfState.left(2);	// BLL28a
        	List<String> oos_split = OutOfState.split('-');	// BLL36a
        	String FirstTwo = oos_split[0];	// BLL36a
        	System.debug('Search for out of state rules for "' + OutOfState + '"');
        	//BLL48d begin
            //List<TaxRuleSetting__c> stateovr = [
            //        select Name, ProposalAutomaticCalc__c, Chassis__c, ChassisTX__c, Conversion__c, ConversionTX__c, AdaptiveEquipment__c, AdaptiveEquipmentTX__c,
            //            AdaptiveEquipLabor__c, AdaptiveEquipLaborTX__c, AdaptiveEquipSublet__c, AdaptiveEquipSubletTX__c,
	        //            NMEDA__c, NMEDA_TX__c, 	// BLL16a
            //            ServiceContract__c, GAP__c, RoadsideProtection__c, DiamondFusion__c, TireWheel__c, // BLL45c 
            //            ServiceContract_AtStore__c, GAP_AtStore__c, RoadsideProt_AtStore__c, DiamondFusion_AtStore__c, TireWheel_AtStore__c, // BLL45c  
            //            AutoGrant__c, Rebate__c, MobilityWorksRebate__c, ChassisDiscount__c,
	        //            GPC__c, GPC_NetChassis__c,	// BLL44a
	        //            ConversionGrant__c, ConvGrantReducesConv__c, 	// BLL24a 
            //            DocumentFee__c, ElectronicFilingFee__c, GVW_GVWR__c, LicenseFee__c, RegistrationFee__c,
            //            SmogCertificate__c, SmogFee__c, TireFee__c,
            //            TradeIn__c, TradeLimitNew__c, TradeLimitUsed__c,  
	        //            Chassis_AtStore__c, ChassisMinTaxable__c, ChassisLessTrade__c, ChassisLessTrade_AtStore__c, // BLL4a
	        //            DocumentFee_AtStore__c, // BLL13a
	        //            LuxuryValue__c, LuxuryVehicle__c, ChassisMaxTaxable__c, // BLL4a, BLL11c max taxable
            //            AutoGrant_NetChassis__c, ChassisDiscount_NetChassis__c, Trade_NetChassis__c,  ChassisFairMarketValue__c, FairMarketValueURL__c,  // BLL3c
            //            CombineConversionWithChassis__c, CombineEquipmentWithConversion__c,  // BLL2a
	        //            SeparateChassisConversionAllowance__c, Conversion_AtStore__c, AddedEquipment_AtStore__c, // BLL25a & BLL26a
	        //            ChassisPriceSource__c, CombineDocFeeWithChassis__c, // BLL9a
	        //            NoTradeOutOfState__c, // BLL30a
            //            RepairAutomaticCalc__c, RepairParts__c, RepairPartsTX__c, RepairLabor__c, RepairLaborTX__c, RepairSublet__c, RepairSubletTX__c, RepairMisc__c, RepairMiscTX__c, 
	        //            InternalOverride__c, WarrantyOverride__c, // BLL8a
            //            RentalAutomaticCalc__c,
            //            RentalFee__c, PickupDeliveryFee__c, ExcessMilesChg__c, RefuelingFee__c, AdjustmentCharges__c, RentalDiscount__c, 
	        //            OriginSourced__c, SalesTaxWithLeasePmt__c, // BLL20a, BLL48c
            //            ( select Id, OperationTaxType__c, Parts__c, PartsTX__c, Labor__c, LaborTX__c, Sublet__c, SubletTX__c, Misc__c, MiscTX__c
            //              from Tax_Rule_Operation_Settings__r   ), 
            //            ( select Id, Name, FieldName__c, Condition__c, TaxCode__c, TaxCodeTX__c, Tax_AtStore__c	// BLL47c add atstore
            //              from Tax_Rule_Overrides__r    )
            //        from TaxRuleSetting__c
            //        where StateDefault__c=:OutOfState
            //           or StateDefault__c=:FirstTwo	// BLL28a
            //        order by StateDefault__c desc	// BLL28a
            //];
        	//BLL48d end
        	// BLL48a begin
            List<TaxRuleSetting__c> stateovr = Database.query(soql 
            	+ ' where StateDefault__c!=null and (StateDefault__c=\'' + OutOfState + '\' or StateDefault__c=\'' + FirstTwo + '\') order by StateDefault__c desc '); 
            if (stateovr.size()>0) {
                rules = stateovr[0];
                System.debug('Out of state override using "' + rules.name + '"');
            }
        	// BLL48a end
        }
        
        if (rules==null) {
            rules = new TaxRuleSetting__c(Name='missing defaults', ProposalAutomaticCalc__c=false,
            RepairAutomaticCalc__c=false, RentalAutomaticCalc__c=false,
            OriginSourced__c=false);	// BLL20c
        }
        if (objectType=='dealer__Deal__c') {
            //MW_TriggerControls__c AvataxDeal = MW_TriggerControls__c.getInstance('AvataxDeal');
            //if (rules.ProposalAutomaticCalc__c==false || (AvataxDeal!=null && AvataxDeal.Enabled__c==false)) {
            if (rules.ProposalAutomaticCalc__c==false) AutomaticCalc = false;
        }
        if (objectType=='dealer__Service_Repair_Order__c' || objectType=='dealer__Service_Estimate__c') {	// BLL58c
            //MW_TriggerControls__c AvataxService = MW_TriggerControls__c.getInstance('AvataxService');
            //if (rules.RepairAutomaticCalc__c==false || (AvataxService!=null && AvataxService.Enabled__c==false)) {
            if (rules.RepairAutomaticCalc__c==false) AutomaticCalc = false;
        }
        if (objectType=='dealer__Rental_Agreements__c') {
            //MW_TriggerControls__c AvataxRental = MW_TriggerControls__c.getInstance('AvataxRental');
            //if (rules.RentalAutomaticCalc__c==false || (AvataxRental!=null && AvataxRental.Enabled__c==false)) {
            if (rules.RentalAutomaticCalc__c==false) AutomaticCalc = false;
        }
        
        // Proposal defaults for missing tax codes
        if (String.isBlank(rules.Chassis__c)) rules.Chassis__c='P0000000';
        if (String.isBlank(rules.ChassisTX__c)) rules.ChassisTX__c = rules.Chassis__c; // BLL3a
        if (String.isBlank(rules.ChassisDiscount__c)) rules.ChassisDiscount__c='P0000000';
        if (String.isBlank(rules.Conversion__c)) rules.Conversion__c='PH050302';
        if (String.isBlank(rules.ConversionTX__c)) rules.ConversionTX__c='P0000000';
        if (String.isBlank(rules.AdaptiveEquipment__c)) rules.AdaptiveEquipment__c='PH050302';
        if (String.isBlank(rules.AdaptiveEquipmentTX__c)) rules.AdaptiveEquipmentTX__c='P0000000';
        if (String.isBlank(rules.AdaptiveEquipLabor__c)) rules.AdaptiveEquipLabor__c='PH050302';
        if (String.isBlank(rules.AdaptiveEquipLaborTX__c)) rules.AdaptiveEquipLaborTX__c='P0000000';
        if (String.isBlank(rules.AdaptiveEquipSublet__c)) rules.AdaptiveEquipSublet__c='PH050302';
        if (String.isBlank(rules.AdaptiveEquipSubletTX__c)) rules.AdaptiveEquipSubletTX__c='P0000000';
        if (String.isBlank(rules.ServiceContract__c)) rules.ServiceContract__c='NT';
        if (String.isBlank(rules.GAP__c)) rules.GAP__c='NT';
        if (String.isBlank(rules.RoadsideProtection__c)) rules.RoadsideProtection__c='NT';
        if (String.isBlank(rules.TireWheel__c)) rules.TireWheel__c='NT';
        if (String.isBlank(rules.DiamondFusion__c)) rules.DiamondFusion__c='NT';
        if (String.isBlank(rules.Rebate__c)) rules.Rebate__c='P0000000';
        if (String.isBlank(rules.MobilityWorksRebate__c)) rules.MobilityWorksRebate__c='P0000000';
        //if (String.isBlank(rules.ConversionDiscount__c)) rules.ConversionDiscount__c='PH050302';
        if (String.isBlank(rules.DocumentFee__c)) rules.DocumentFee__c='P0000000';
        if (String.isBlank(rules.ElectronicFilingFee__c)) rules.ElectronicFilingFee__c='NT';
        if (String.isBlank(rules.GVW_GVWR__c)) rules.GVW_GVWR__c='NT';
        if (String.isBlank(rules.LicenseFee__c)) rules.LicenseFee__c='NT';
        if (String.isBlank(rules.RegistrationFee__c)) rules.RegistrationFee__c='NT';
        if (String.isBlank(rules.SmogCertificate__c)) rules.SmogCertificate__c='NT';
        if (String.isBlank(rules.SmogFee__c)) rules.SmogFee__c='P0000000';
        if (String.isBlank(rules.TireFee__c)) rules.TireFee__c='NT';
        if (String.isBlank(rules.TradeIn__c)) rules.TradeIn__c='P0000000';
        if (String.isBlank(rules.AutoGrant__c)) rules.TradeIn__c='P0000000';
        if (String.isBlank(rules.GPC__c)) rules.TradeIn__c='NT';	// BLL44a
        if (String.isBlank(rules.ChassisPriceSource__c)) rules.ChassisPriceSource__c='Selling price';	// BLL9a
        if (rules.CombineDocFeeWithChassis__c==null) rules.CombineDocFeeWithChassis__c=false;	// BLL9a
        
        if (String.isBlank(rules.RepairParts__c)) rules.RepairParts__c = 'P0000000';
        if (String.isBlank(rules.RepairPartsTX__c)) rules.RepairPartsTX__c = 'P0000000';
        if (String.isBlank(rules.RepairLabor__c)) rules.RepairParts__c = 'NT';
        if (String.isBlank(rules.RepairLaborTX__c)) rules.RepairPartsTX__c = 'NT';
        if (String.isBlank(rules.RepairSublet__c)) rules.RepairParts__c = 'P0000000';
        if (String.isBlank(rules.RepairSubletTX__c)) rules.RepairPartsTX__c = 'P0000000';
        if (String.isBlank(rules.RepairMisc__c)) rules.RepairParts__c = 'P0000000';
        if (String.isBlank(rules.RepairMiscTX__c)) rules.RepairPartsTX__c = 'P0000000';

        // newer fields
        if (String.isBlank(rules.RepairLaborWithCert__c)) rules.RepairLaborWithCert__c = 'P0000000';
        if (String.isBlank(rules.RepairMiscWithCert__c)) rules.RepairMiscWithCert__c = 'P0000000';
        if (String.isBlank(rules.RepairPartsWithCert__c)) rules.RepairPartsWithCert__c = 'P0000000';
        if (String.isBlank(rules.RepairSubletWithCert__c)) rules.RepairSubletWithCert__c = 'P0000000';

        if (String.isBlank(rules.RentalFee__c)) rules.RentalFee__c = 'P0000000';
        if (String.isBlank(rules.PickupDeliveryFee__c)) rules.PickupDeliveryFee__c = 'P0000000';
        if (String.isBlank(rules.ExcessMilesChg__c)) rules.ExcessMilesChg__c = 'P0000000';
        if (String.isBlank(rules.RefuelingFee__c)) rules.RefuelingFee__c = 'P0000000';
        if (String.isBlank(rules.AdjustmentCharges__c)) rules.AdjustmentCharges__c = 'P0000000';
        if (String.isBlank(rules.RentalDiscount__c)) rules.RentalDiscount__c = 'P0000000';
        
        taxRuleOpCodeMap = new Map<String,TaxRuleOpCodeSetting__c>();
        if (rules.Tax_Rule_Operation_Settings__r!=null) {
            for(TaxRuleOpCodeSetting__c op : rules.Tax_Rule_Operation_Settings__r) {
                if (String.isBlank(op.Parts__c)) op.Parts__c = 'P0000000';
                if (String.isBlank(op.PartsTX__c)) op.PartsTX__c = 'P0000000';
                if (String.isBlank(op.Labor__c)) op.Parts__c = 'NT';
                if (String.isBlank(op.LaborTX__c)) op.PartsTX__c = 'NT';
                if (String.isBlank(op.Sublet__c)) op.Parts__c = 'P0000000';
                if (String.isBlank(op.SubletTX__c)) op.PartsTX__c = 'P0000000';
                if (String.isBlank(op.Misc__c)) op.Parts__c = 'NT';
                if (String.isBlank(op.MiscTX__c)) op.PartsTX__c = 'NT';
                taxRuleOpCodeMap.put(op.OperationTaxType__c, op);
            }
        }
        
        taxRuleOverrides = new Map<String,TaxRuleOverride__c>();
        if (rules.Tax_Rule_Overrides__r!=null) {
            for(TaxRuleOverride__c ovr : rules.Tax_Rule_Overrides__r) {
                if (String.isBlank(ovr.TaxCode__c)) ovr.TaxCode__c = 'P0000000';
                if (String.isBlank(ovr.TaxCodeTX__c)) ovr.TaxCodeTX__c = 'P0000000';
                String key = ovr.FieldName__c + ':' + ovr.Condition__c; 
                taxRuleOverrides.put(key, ovr);
            }
        }

        // BLL13a  
        storeRuleOverrides = new Map<String,TaxRuleOverride__c>();
        if (storerules!=null && storerules.Tax_Rule_Overrides__r!=null) {
            for(TaxRuleOverride__c ovr : storerules.Tax_Rule_Overrides__r) {
                if (String.isBlank(ovr.TaxCode__c)) ovr.TaxCode__c = 'P0000000';
                if (String.isBlank(ovr.TaxCodeTX__c)) ovr.TaxCodeTX__c = 'P0000000';
                String key = ovr.FieldName__c + ':' + ovr.Condition__c; 
                storeRuleOverrides.put(key, ovr);
            }
        }
        // BLL13a end 

        System.debug('Have ' + String.valueOf(taxRuleOverrides.size()) + ' tax rule overrides');
        System.debug(taxRuleOverrides);
    
    	dealsplitlabor = rules.AdaptiveEquipment__c!=rules.AdaptiveEquipLabor__c 
    			|| rules.AdaptiveEquipmentTX__c!=rules.AdaptiveEquipLaborTX__c;	// BLL10a 
    
        return rules;
        
    }


    // saveDealTaxDetail
    //------------------------------
    public void saveDealTaxDetail() {
		System.debug('saveDealTaxDetail');
        if (objectType!='dealer__Deal__c') {
            throw new TaxException('Cannot save to proposal when object type is ' + objectType);
        }
        List<DealTaxes__c> oldtaxes = [
            select Name, JurisType__c, JurisName__c, Tax__c, Taxable__c, TaxBase__c, TaxRate__c, TaxType__c
            from DealTaxes__c
            where Deal__c = :objectId 
        ];
        //Decimal totalTax = 0.00;
        totalTax = 0.00;
        List<DealTaxes__c> newtaxes = new List<DealTaxes__c>();
        for(TaxResultSummary t : taxSummary.values()) {
            t.JurisName = t.JurisName.left(80);
            if (t.TaxCalculated!=0) {	// BLL5a - don't store/show 0% tax
            	newtaxes.add(new DealTaxes__c(Deal__c=objectId,
            	    Name=t.TaxName, TaxType__c=t.TaxType, JurisType__c=t.JurisType, JurisName__c=t.JurisName,
            	    TaxRate__c=t.TaxRate, Tax__c=t.TaxCalculated, TaxBase__c=t.Base, Taxable__c=t.Taxable
            	));
            }	// BLL5a
            totalTax += t.TaxCalculated;
        }
       	SavePoint sp = Database.setSavepoint();	// BLL17a
        try {	// BLL17a
        	if (oldtaxes.size()>0) delete(oldtaxes);
        	if (newtaxes.size()>0) insert(newtaxes);
       	    System.debug('deal tax detail saved');
        // BLL17a
        } catch(Exception e) {
        	Database.rollback(sp);
        	throw new TaxException('Unable to update taxes. Perhaps the proposal is locked in an approval process. New tax should be ' + String.valueOf(totalTax));
        }
        // BLL17a
    }
    
    // saveDealTaxHeader
    //-------------------------------
    public void saveDealTaxHeader() {
		System.debug('saveDealTaxHeader');
        dealer__Deal__c upddeal = new dealer__Deal__c(Id=objectId);
        updDealTaxHeader(upddeal);
        update(upddeal);
		System.debug('deal updated');
    }
    
    // updDealTaxHeader
    //-------------------------------
    public void updDealTaxHeader(dealer__Deal__c upddeal) {
		System.debug('updDealTaxHeader');
        upddeal.dealer__Sales_Tax__c=TotalTax;
        upddeal.TaxHash__c=getHash();
		System.debug(gettaxRslt);
		if (gettaxRslt!=null) System.debug(gettaxRslt.Timestamp);
        if (gettaxRslt!=null && gettaxRslt.Timestamp!=null) {
            upddeal.TaxCalcDT__c=gettaxRslt.Timestamp;
        } else {
            upddeal.TaxCalcDT__c=DateTime.now();    // BLL41
        }
        System.debug(upddeal.TaxCalcDT__c);
        // BLL49a
        upddeal.Chassis_taxable_amt__c = ChassisTaxable;
		upddeal.Chassis_tax_rate__c = ChassisRate*100;
		upddeal.Chassis_tax__c = ChassisTax;
		upddeal.Conversion_taxable_amt__c = ConversionTaxable;
		upddeal.Conversion_tax_rate__c = ConversionRate*100;
		upddeal.Conversion_tax__c = ConversionTax;
		System.debug(ChassisTaxable);
		System.debug(ChassisRate);
		System.debug(ChassisTax);
		System.debug(ConversionTaxable);
		System.debug(ConversionRate);
		System.debug(ConversionTax);
		// For Alabama
		upddeal.County_tax_rate__c = CountyRate*100;
		upddeal.County_taxable_amt__c = CountyTaxable;
		upddeal.County_tax__c = CountyTax;
		System.debug(CountyTaxable);
		System.debug(CountyRate);
		System.debug(CountyTax);
    	// BLL49a end 
    }

	// BLL61a
    // getTaxDocumentRequired
    //--------------------------------
    public String getTaxDocumentRequired() {
    	String rtn = null;
    	if (taxrules!=null && !String.isBlank(taxrules.TaxDocumentRequired__c)) {
    		rtn = taxrules.TaxDocumentRequired__c;
    	}
    	return rtn;
    }
	// BLL61a end
    
    // BLL3a
    // useFairMarketValue
    //--------------------------------
    public boolean useFairMarketValue() {
    	boolean rtn = false;
    	if (taxrules!=null && taxrules.ChassisFairMarketValue__c==true) rtn = true;
    	return rtn;
    }
    
    // getFairMarketValueURL
    //--------------------------------
    public String getFairMarketValueURL() {
    	String url = taxrules==null ? null : taxrules.FairMarketValueURL__c;
    	return url;
    }
    
    // BLL18a
    // getShowPartLaborSplit
    //---------------------------------
    public boolean getShowPartLaborSplit() {
    	return dealsplitlabor;
    }
    // BLL18a end
    
    // showChassisTaxableSelection
    //--------------------------------
    public boolean showChassisTaxableSelection() {
    	return taxrules!=null ? taxrules.Chassis__c!=taxrules.ChassisTX__c : false;	// BLL60c
    }
    // BLL3a end

    // debugTaxRequestLines
    //------------------------------
    public void debugTaxRequestLines() {
		if(gettaxReq!=null && getTaxReq.Lines!=null) {	// BLL60a
 	       for(TaxSvc.Line l : gettaxReq.Lines.Line) {
 	       	System.debug(l);
 	           System.debug(String.valueOf(l.No) + ': ' + String.valueOf(l.ItemCode) + ' ( ' + String.valueOf(l.TaxCode) + ') ' + String.valueOf(l.Amount));
 	           System.debug('Origin/Destination: ' + String.valueOf(l.OriginCode) + '/' + String.valueOf(l.DestinationCode));
 	       }
		}	// BLL60a
    }


    // summarizeTaxResult
    //-----------------------------
    public void summarizeTaxResult() {
        System.debug('summarizeTaxResult');
    	boolean FirstLine = true; // BLL15a (first line is the chassis on vehicle sale)
    	String CountyName = null;	// BLL15a
        taxSummary = new Map<String,TaxResultSummary>();
        TotalTax = 0.00;
        TaxableAmt = 0.00;

		ChassisTaxable = 0.00;
		ChassisRate = 0.00;
		ChassisTax = 0.00;
		ConversionTaxable = 0.00;
		ConversionRate = 0.00;
		ConversionTax = 0.00;
		CountyRate = 0.00;
		CountyTaxable = 0.00;
		CountyTax = 0.00;
        
        if (gettaxRslt!=null && gettaxRslt.TaxLines!=null && gettaxRslt.TaxLines.TaxLine!=null  
            && gettaxRslt.TaxLines.TaxLine.size()>0) {
            for(TaxSvc.TaxLine t : gettaxRslt.TaxLines.TaxLine) {
                TaxableAmt += t.Taxable;
                System.debug('>'+t.No+'<');
                System.debug(t);
                if (t.No=='10') ChassisTaxable += t.Taxable;	// BLL49a
				if (t.No=='10') ChassisRate = t.Rate;	// BLL49a
                if (t.No=='15') ConversionTaxable += t.Taxable;	// BLL49a
				if (t.No=='15') ConversionRate = t.Rate;	// BLL49a
                if (t.No=='10') CountyTaxable += t.Taxable;		// BLL49a	(county chassis tax?)
                for(TaxSvc.TaxDetail d : t.TaxDetails.TaxDetail) {
                	System.debug(d);	// BLL49a
                	if (FirstLine && CountyName==null && d.JurisType=='County') CountyName = d.JurisName;	// BLL15a
                    String key = d.TaxType + ':' + d.TaxName + ':' + d.JurisType + ':' + d.JurisName + ':' 
                        + String.valueOf(d.Rate);
                    TaxResultSummary s;
                    s = taxSummary.get(key);
                    if (s==null) { 
                        s = new TaxResultSummary();
                        s.TaxType = d.TaxType;
                        s.TaxName = d.TaxName;
                        s.JurisType = d.JurisType;
                        s.JurisName = d.JurisName;
                        s.TaxRate = d.Rate;
                        s.TaxCalculated = 0.00;
                        s.Base = 0.00;
                        s.Taxable = 0.00;
                    }
                    s.TaxCalculated += d.TaxCalculated;
                    s.Base += d.Base;
                    s.Taxable += d.Taxable;
                    taxSummary.put(key, s);
                    TotalTax += d.TaxCalculated;
	                //if (t.No=='10') ChassisRate += d.Rate;	// BLL49a
	                if (t.No=='10') ChassisTax += d.TaxCalculated;	// BLL49a
    	            //if (t.No=='15') ConversionRate += d.Rate;	// BLL49a
    	            if (t.No=='15') ConversionTax += d.TaxCalculated;	// BLL49a
	                if (t.No=='10' && d.JurisType=='County') CountyRate += d.Rate;	// BLL49a
	                if (t.No=='10' && d.JurisType=='County') CountyTax += d.TaxCalculated;	// BLL49a
                }
                FirstLine = false;	// BLL15a
            }
        }
        System.debug(taxSummary);
        County = CountyName;	// BLL15a
    }


    // summarizeTaxByRepairLine
    //-----------------------------
    public Map<String,Decimal> summarizeTaxByRepairLine() {
        Map<String,Decimal> taxSummary = new Map<String,Decimal>();
        if (gettaxRslt!=null && gettaxRslt.TaxLines!=null && gettaxRslt.TaxLines.TaxLine!=null  
            && gettaxRslt.TaxLines.TaxLine.size()>0) {
            for(TaxSvc.TaxLine t : gettaxRslt.TaxLines.TaxLine) {
                String[] k = t.No.split(':');
                if (k.size()>0) {
                    Decimal tax = taxSummary.containsKey(k[0]) ? taxSummary.get(k[0]) : 0.00;
                    tax += t.TaxCalculated;
                    taxSummary.put(k[0], tax);
                }
            }
        }
        System.debug(taxSummary);
        return taxSummary;
    }



    // saveServiceTaxDetail
    //------------------------------
    public void saveServiceTaxDetail() {
        if (objectType!='dealer__Service_Repair_Order__c') {
            throw new TaxException('Cannot save to repair order when object type is ' + objectType);
        }
        List<ServiceTaxes__c> oldtaxes = [
            select Name, JurisType__c, JurisName__c, Tax__c, Taxable__c, TaxBase__c, TaxRate__c, TaxType__c
            from ServiceTaxes__c
            where ServiceRepairOrder__c = :objectId 
        ];
        List<ServiceTaxes__c> newtaxes = new List<ServiceTaxes__c>();
        for(TaxResultSummary t : taxSummary.values()) {
            t.JurisName = t.JurisName.left(80);
            if (t.TaxCalculated!=0) {	// BLL5a - don't store/show 0% tax
	            newtaxes.add(new ServiceTaxes__c(ServiceRepairOrder__c=objectId,
	                Name=t.TaxName, TaxType__c=t.TaxType, JurisType__c=t.JurisType, JurisName__c=t.JurisName,
	                TaxRate__c=t.TaxRate, Tax__c=t.TaxCalculated, TaxBase__c=t.Base, Taxable__c=t.Taxable
	            ));
            } // BLL5a
        }
        if (oldtaxes.size()>0) delete(oldtaxes);
        if (newtaxes.size()>0) insert(newtaxes);
    }

    // saveServiceTaxHeader
    //-------------------------------
    public void saveServiceTaxHeader() {
        dealer__Service_Repair_Order__c updservice = new dealer__Service_Repair_Order__c(Id=objectId);
        updServiceTaxHeader(updservice);
        System.debug(updservice);
        update(updservice);
        System.debug(updservice);
    }

    // updServiceTaxHeader
    //-------------------------------
    public void updServiceTaxHeader(dealer__Service_Repair_Order__c updservice) {
        updservice.dealer__Customer_Tax__c=TotalTax;
        updservice.TaxHash__c=getHash();
        if ((gettaxRslt!=null && gettaxRslt.Timestamp!=null)) {
            updservice.TaxCalcDT__c = gettaxRslt.Timestamp;
        } else if (gettaxReq!=null && gettaxReq.Lines!=null && gettaxReq.Lines.Line!=null && gettaxReq.Lines.Line.size()==0) {	// BLL41a
        	updservice.TaxCalcDT__c = DateTime.now();	// BLL41a
        }
    }


    // saveRentalTaxDetail
    //------------------------------
    public void saveRentalTaxDetail() {
        // Not saving detail, since we're strictly saving our existing tax charges to Avalara
        //if (objectType!='dealer__Rental_Agreements__c') {
        //  throw new TaxException('Cannot save to rental when object type is ' + objectType);
        //}
        //List<ServiceTaxes__c> oldtaxes = [
        //  select Name, JurisType__c, JurisName__c, Tax__c, Taxable__c, TaxBase__c, TaxRate__c, TaxType__c
        //  from RentalTaxes__c
        //  where RentalAgreement__c = :objectId 
        //];
        //List<ServiceTaxes__c> newtaxes = new List<ServiceTaxes__c>();
        //for(TaxResultSummary t : taxSummary.values()) {
        //  if (t.JurisName.length>80) t.JurisName = t.JurisName.substring(0,80);
        //    if (t.TaxCalculated!=0) {	// BLL5a - don't store/show 0% tax
        //	  newtaxes.add(new ServiceTaxes__c(ServiceRepairOrder__c=objectId,
        //	      Name=t.TaxName, TaxType__c=t.TaxType, JurisType__c=t.JurisType, JurisName__c=t.JurisName,
        //	      TaxRate__c=t.TaxRate, Tax__c=t.TaxCalculated, TaxBase__c=t.Base, Taxable__c=t.Taxable
        //	  ));
        //	} // BLL5a
        //}
        //if (oldtaxes.size()>0) {
        //  delete(oldtaxes);
        //}
        //if (newtaxes.size()>0) {
        //  insert(newtaxes);
        //}
    }

    // saveRentalTaxHeader
    //-------------------------------
    public void saveRentalTaxHeader() {
        // Not saving header since we're simply storing rentcentric tax value in Avalara
        //dealer__Rental_Agreements__c updrental = new dealer__Rental_Agreements__c(Id=objectId);
        //updRentalTaxHeader(updrental);
        //System.debug(updrental);
        //update(updrental);
        //System.debug(updrental);
    }

    // updRentalTaxHeader
    //-------------------------------
    public void updRentalTaxHeader(dealer__Rental_Agreements__c updrental) {
        // Not saving taxes on header, they're being manually keyed in from Rentcentric
        //updrental.Sales_Tax__c=?;
        //updrental.CountySalesTax__c=?;
        //updrental.CitySalesTax__c=?; 
        //updrental.ThirdTierRentalTax__c=?;
        updrental.TaxHash__c=getHash();
        if (gettaxRslt!=null && gettaxRslt.Timestamp!=null) updrental.TaxCalcDT__c=gettaxRslt.Timestamp;
        else updrental.TaxCalcDT__c=DateTime.now(); // BLL41
    }


    // debugTaxResultSummary
    //-----------------------------
    public void debugTaxResultSummary() {
        for(TaxResultSummary t : taxSummary.values()) {
            System.debug(t.TaxName + ': ' + t.Taxable + ' @ ' + String.valueOf(t.TaxRate) + ' = ' + String.valueOf(t.TaxCalculated));
        }
    }
    
    
    // TaxResultSummary
    //-----------------------------
    public class TaxResultSummary {
        public String TaxType   {get;set;}
        public String TaxName   {get;set;}
        public String JurisType {get;set;}
        public String JurisName {get;set;}
        public Decimal TaxRate  {get;set;}
        public Decimal TaxCalculated {get;set;}
        public Decimal Base     {get;set;}
        public Decimal Taxable  {get;set;}
    }


    // CommitTax
    //-----------------------------
    //public void commitTax() {
    //  String resultText;
    //  // Prepare Request
    //  committaxReq = new TaxSvc.CommitTaxRequest();
    //  committaxReq.CompanyCode = gettaxReq.CompanyCode;
    //  committaxReq.DocType = gettaxReq.DocType;
    //  committaxReq.DocCode = gettaxReq.DocCode;
    //  TaxSvc.TaxSvcSoap client = getAvataxClient();
    //  try {
    //      committaxRslt = client.CommitTax(committaxReq);
    //      if(committaxRslt.ResultCode == 'Success') {
    //           resultText = 'CommitTax Succeeded';
    //      } else {
    //          System.debug(committaxRslt);
    //          resultText = 'CommitTax ' + committaxRslt.ResultCode + ' : ' +
    //              committaxRslt.Messages.Message[0].Name + ' : ' + committaxRslt.Messages.Message[0].Summary; 
    //          throw new AvaTaxException(resultText);
    //      }
    //  } catch(Exception e) {
    //      resultText = e.getMessage();
    //      if (!resultText.startsWith('CommitTax')) resultText = 'CommitTax ' + resultText;
    //      throw new AvaTaxException(resultText);
    //  }
    //}
    
    //@future(callout=true)
    //public static void commitDealsFuture(Set<Id> dealIds) {
    //  String errorMessages = '';
    //  List<dealer__Deal__c> updDeals = new List<dealer__Deal__c>();
    //  for(Id dId : dealIds) {
    //      AvaTax_MBW dealTaxation = AvaTax_MBW.getInstanceDealId(dId);
    //      try {
    //          dealTaxation.commitTax();
    //          updDeals.add(new dealer__Deal__c(Id=dId, TaxCommitDT__c=Datetime.now()) );
    //      } catch (Exception e) {
    //          errorMessages += e.getMessage() + '\r\n';
    //      }
    //  }
    //  if (updDeals.size()>0) {
    //      try {  // incase deal is not updatable (aka posted deals cannot be updated)
    //          update(updDeals);
    //      } catch(Exception e) {}
    //  }
    //  if (errorMessages.length()>0) {
    //      // ToDo: need to alert someone? Or let them review in Avalara & commit there?
    //  }
    //}
    

    // CancelTax
    //-----------------------------
    public void cancelTax(String reason) {
    	String resultText;
     	Set<String> validReasons = new Set<String>{'Unspecified','PostFailed','DocDeleted','DocVoided','AdjustmentCancelled'};
    	
    	// Prepare Request
    	canceltaxReq = new TaxSvc.CancelTaxRequest();
    	canceltaxReq.CompanyCode = gettaxReq.CompanyCode;
    	canceltaxReq.DocType = gettaxReq.DocType;
    	canceltaxReq.DocCode = gettaxReq.DocCode;
    	if (reason!=null && validReasons.contains(reason)) {
    	    canceltaxReq.CancelCode = reason;
    	}
    	TaxSvc.TaxSvcSoap client = getAvataxClient();
    	try {
    	    canceltaxRslt = client.CancelTax(canceltaxReq);
    	    if(canceltaxRslt.ResultCode == 'Success') {
    	         resultText = 'CancelTax Succeeded';
    	    } else {
    	         resultText = 'CancelTax ' + canceltaxRslt.ResultCode + ' : ' +
    	             canceltaxRslt.Messages.Message[0].Name + ' : ' + canceltaxRslt.Messages.Message[0].Summary; 
    	         throw new AvaTaxException(resultText);
    	    }
    	} catch(Exception e) {
    	    resultText = e.getMessage();
    	    if (!resultText.startsWith('CancelTax')) resultText = 'CancelTax ' + resultText;
    	    throw new AvaTaxException(resultText);
    	}
    }

    
    //@future(callout=true)
    //public static void cancelDealsFuture(Set<Id> dealIds, string Reason) {
    //  String errorMessages = '';
    //  List<dealer__Deal__c> updDeals = new List<dealer__Deal__c>();
    //  for(Id dId : dealIds) {
    //      AvaTax_MBW dealTaxation = AvaTax_MBW.getInstanceDealId(dId);
    //      try {
    //          dealTaxation.cancelTax(Reason);
    //          updDeals.add(new dealer__Deal__c(Id=dId, TaxCancelDT__c=Datetime.now()) );
    //      } catch (Exception e) {
    //          errorMessages += e.getMessage() + '\r\n';
    //      }
    //  }
    //  if (updDeals.size()>0) {
    //      try {  // incase deal is not updatable (aka posted deals cannot be updated)
    //          update(updDeals);
    //      } catch(Exception e) {}
    //  }
    //  if (errorMessages.length()>0) {
    //      // ToDo: need to alert someone? Or let them review in Avalara & commit there?
    //  }
    //}


    // AdjustTax - activated BLL40
    //-----------------------------
    public void adjustTax(Integer reasoncode, String description) {
    	// Be sure to set gettaxReq.Commit_x = {false | true} prior to calling this routine
        // Reason codes:
        // 0 - Not Adjusted
        // 1 - Sourcing Issue
        // 2 - Reconciled with General Ledger
        // 3 - Exemption Certificate Applied
        // 4 - Price or Quantity Adjusted
        // 5 - Item Returned
        // 6 - Item Exchanged
        // 7 - Bad Debt
        // 8 - Other (Explain) Must provide AdjustmentDescription
      String resultText;
      // Prepare Request
      adjusttaxReq = new TaxSvc.AdjustTaxRequest();
      adjusttaxReq.AdjustmentReason = reasoncode;
      adjusttaxReq.AdjustmentDescription = description;
      adjusttaxReq.GetTaxRequest = gettaxReq; 
      TaxSvc.TaxSvcSoap client = getAvataxClient();
      try {
          adjusttaxRslt = client.AdjustTax(adjusttaxReq);
          if(adjusttaxRslt.ResultCode == 'Success') {
               resultText = 'AdjustTax Succeeded';
          } else {
               resultText = 'AdjustTax ' + adjusttaxRslt.ResultCode + ' : ' +
                   adjusttaxRslt.Messages.Message[0].Name + ' : ' + adjusttaxRslt.Messages.Message[0].Summary; 
               throw new AvaTaxException(resultText);
          }
      } catch(Exception e) {
          resultText = e.getMessage();
          if (!resultText.startsWith('AdjustTax')) resultText = 'AdjustTax ' + resultText;
          throw new AvaTaxException(resultText);
      }
    }
        
    
    // PostTax
    //-----------------------------
    public void postTax(Decimal TotalAmt, Decimal tax, boolean doCommit) {
        String resultText;
        posttaxReq = new TaxSvc.PostTaxRequest();
        posttaxReq.Commit_x = doCommit;
        posttaxReq.CompanyCode = gettaxReq.CompanyCode;
        posttaxReq.DocType = gettaxReq.DocType;
        posttaxReq.DocCode = gettaxReq.DocCode;
        posttaxReq.DocDate = gettaxReq.DocDate;
        if (posttaxReq.DocDate>Date.today()) posttaxReq.DocDate = Date.today(); // BLL1a
        posttaxReq.TotalAmount = TotalAmt==null ? 0.00 : TotalAmt;
        posttaxReq.TotalTax = tax==null ? 0.00 : tax;
        //posttaxReq.NewDocCode = 'SalesInvoice';  // if getTax changed to SalesOrder, change it here!
        TaxSvc.TaxSvcSoap client = getAvataxClient();
        try {
            posttaxRslt = client.PostTax(posttaxReq);
            if(posttaxRslt.ResultCode == 'Success') {
                 resultText = 'PostTax Succeeded';
            } else {
                 resultText = 'PostTax ' + posttaxRslt.ResultCode + ' : ' +
                     posttaxRslt.Messages.Message[0].Name + ' : ' + posttaxRslt.Messages.Message[0].Summary; 
                 throw new AvaTaxException(resultText);
            }
        } catch(Exception e) {
            resultText = e.getMessage();
            if (!resultText.startsWith('PostTax')) resultText = 'PostTax ' + resultText;
            throw new AvaTaxException(resultText);
        }
        
    }


    @future(callout=true)
    public static void postDealsFuture(Set<Id> dealIds) {
    	Avatax_MBW.postDeals(dealIds);
    }
    public static void postDeals(Set<Id> dealIds) {
        String errorMessages = '';
        List<dealer__Deal__c> deals = new List<dealer__Deal__c>([select Id, Total_Price__c, dealer__Sales_Tax__c from dealer__Deal__c where Id in :dealIds]);
        List<dealer__Deal__c> upddeals = new List<dealer__Deal__c>();
        for(dealer__Deal__c deal : deals) {
            AvaTax_MBW dealTaxation = AvaTax_MBW.getInstanceDealId(deal.Id);
            Decimal TotalAmt = 0.00;
            // Hack: Add up all lines not marked NT, PH05* - this may not be accurate, but can be adjusted in Avalara!
            try {
                for(TaxSvc.Line l : dealTaxation.gettaxReq.Lines.Line) {
                	Decimal lineamt = l.Amount!=null ? l.Amount : 0.00;	// BLL38a
                    TotalAmt += lineamt.setScale(2, System.RoundingMode.HALF_UP);	// BLL38c
                }
                dealTaxation.postTax(TotalAmt, deal.dealer__Sales_Tax__c, true);
                //Datetime rightNow = Datetime.now();
                //updDeals.add(new dealer__Deal__c(Id=deal.Id, TaxPostDT__c=rightNow, TaxCommitDT__c=rightNow) );
            } catch (Exception e) {
                errorMessages += e.getMessage() + '\rTotal: ' + String.valueOf(TotalAmt) + '\tTax: ' + String.valueOf(deal.dealer__Sales_Tax__c) + '\r\n';
            }
            Datetime rightNow = Datetime.now();
            updDeals.add(new dealer__Deal__c(Id=deal.Id, TaxPostDT__c=rightNow, TaxCommitDT__c=rightNow) );
        }
        if (updDeals.size()>0) {
            try {  // incase deal is not updatable (aka posted deals cannot be updated)
                Database.update(updDeals, false);
            } catch(Exception e) {}
        }
        if (errorMessages.length()>0) {
            MonitorExecution mon = new MonitorExecution('AvaTax_MBW');
            mon.log('postDealsFuture errors:\r\n' + errorMessages);
            mon.log('deal Ids: ' + JSON.serialize(dealIds));
            mon.notifyAdmin();
        }
    }


    @future(callout=true)
    public static void postServiceFuture(Set<Id> serviceIds) {
    	Avatax_MBW.postService(serviceIds);
    }
    public static void postService(Set<Id> serviceIds) {
        String errorMessages = '';
        boolean reportError = false;	// BLL54a
        List<dealer__Service_Repair_Order__c> sros = new List<dealer__Service_Repair_Order__c>([select Id, Name, dealer__Customer_Tax__c, TaxCalcDT__c, dealer__Customer_Charges__c from dealer__Service_Repair_Order__c where Id in :serviceIds]);
        List<dealer__Service_Repair_Order__c> updsros = new List<dealer__Service_Repair_Order__c>();
        for(dealer__Service_Repair_Order__c sro : sros) {
            AvaTax_MBW serviceTaxation = AvaTax_MBW.getInstanceSROId(sro.Id);
            Decimal TotalAmt = 0.00;
            // Hack: Add up all lines not marked NT, PH05* - this may not be accurate, but can be adjusted in Avalara!
            try {
                if (serviceTaxation!=null && serviceTaxation.gettaxReq!=null && serviceTaxation.gettaxReq.Lines!=null) {
                    for(TaxSvc.Line l : serviceTaxation.gettaxReq.Lines.Line) {
	                	Decimal lineamt = l.Amount!=null ? l.Amount : 0.00;	// BLL38a
    	                TotalAmt += lineamt.setScale(2, System.RoundingMode.HALF_UP);	// BLL38c
                    }
                    if (sro.TaxCalcDT__c!=null) { // && sro.dealer__Customer_Tax__c!=0) {
                        serviceTaxation.postTax(TotalAmt, sro.dealer__Customer_Tax__c, true);
                    }
                } 
            } catch (Exception e) {
                errorMessages += e.getMessage() + '\rTotal: ' + String.valueOf(TotalAmt) + '\tTax: ' + String.valueOf(sro.dealer__Customer_Tax__c) 
                	+ ' RO:' + sro.Name + ' (' + sro.Id + ')' + '\r\n';
				// BLL54a Don't report unless amount is not $0 or error is not DocumentNotFound
				// aka. ignore DocumentNotFoundError when amount *is* $0.
                reportError = reportError || TotalAmt!=0 || !e.getMessage().contains('DocumentNotFoundError');	// BLL54a
            }
            if (sro.TaxCalcDT__c!=null) { // && sro.dealer__Customer_Tax__c!=0) {
            	Datetime rightNow = Datetime.now();
            	updsros.add(new dealer__Service_Repair_Order__c(Id=sro.Id, TaxPostDT__c=rightNow, TaxCommitDT__c=rightNow) );
            }
        }
        if (updsros.size()>0) {
            try {  // in case deal is not updatable (aka posted ROs cannot be updated error)
                Database.update(updsros,false);
            } catch(Exception e) {}
        }
        if (!String.isBlank(errorMessages)) {
            MonitorExecution mon = new MonitorExecution('AvaTax_MBW');
            mon.log('postServiceFuture errors:\r\n' + errorMessages);
            mon.log('Repair Order Ids: ' + JSON.serialize(serviceIds));
            if (reportError || mon.AlwaysNotify) mon.notifyAdmin();
        }
    }


    @future(callout=true)
    public static void postRentalFuture(Set<Id> rentalIds) {
    	Avatax_MBW.postRental(rentalIds);
    }
    public static void postRental(Set<Id> rentalIds) {
        String errorMessages = '';
        List<dealer__Rental_Agreements__c> rentals = new List<dealer__Rental_Agreements__c>([select Id, Total_charges__c, Sales_Tax__c, CountySalesTax__c, CitySalesTax__c, ThirdTierRentalTax__c from dealer__Rental_Agreements__c where Id in :rentalIds]);
        List<dealer__Rental_Agreements__c> updrentals = new List<dealer__Rental_Agreements__c>();
        for(dealer__Rental_Agreements__c rental : rentals) {
            AvaTax_MBW rentalTaxation = AvaTax_MBW.getInstanceRentalId(rental.Id);
            Decimal TotalAmt = 0.00;
            Decimal TotalTax = 0.00;
            // Hack: Add up all lines not marked NT, PH05* - this may not be accurate, but can be adjusted in Avalara!
            try {
                //for(TaxSvc.Line l : rentalTaxation.gettaxReq.Lines.Line) {
                //  TotalAmt += l.Amount;
                //}
                TotalAmt = rental.Total_charges__c;
                TotalTax = rental.Sales_Tax__c + rental.CountySalesTax__c + rental.CitySalesTax__c + rental.ThirdTierRentalTax__c;
                TotalAmt -= TotalTax;	// BLL6a - reduce total amount by the taxes 
                rentalTaxation.postTax(TotalAmt, TotalTax, true);
            } catch (Exception e) {
                errorMessages += e.getMessage() + '\rTotal: ' + String.valueOf(TotalAmt) + '\tTax: ' + String.valueOf(TotalTax) + '\r\n';
            }
            Datetime rightNow = Datetime.now();
            updrentals.add(new dealer__Rental_Agreements__c(Id=rental.Id, TaxPostDT__c=rightNow, TaxCommitDT__c=rightNow) );
        }
        if (updrentals.size()>0) {
            try {  // incase deal is not updatable (aka posted deals cannot be updated)
                Database.update(updrentals, false);
            } catch(Exception e) {}
        }
        if (errorMessages.length()>0) {
            MonitorExecution mon = new MonitorExecution('AvaTax_MBW');
            mon.log('postRentalFuture errors:\r\n' + errorMessages);
            mon.log('Rental Ids: ' + JSON.serialize(rentalIds));
            mon.notifyAdmin();
        }
    }


	// BLL58a
	// Service estimate taxes


    // getInstanceServiceEstimateId
    //-----------------------------
    public static AvaTax_MBW getInstanceServiceEstimateId(Id estId) {
        AvaTax_MBW cls = new AvaTax_MBW();
        cls.setupFromServiceEstimateId(estId);
        return cls;
    }
    
    // getInstanceServiceEstimate
    //-----------------------------
    public static AvaTax_MBW getInstanceServiceEstimate(dealer__Service_Estimate__c est) {
        AvaTax_MBW cls = new AvaTax_MBW();
        cls.setupFromServiceEstimateObj(est);
        return cls;
    }
    

    // setupFromServiceEstimateId 
    //-----------------------------
    public void setupFromServiceEstimateId(Id estId) {
        objectId = estId;
        dealer__Service_Estimate__c est = [
            select Id, Name, dealer__Store_Location__c, dealer__Customer__c, dealer__Customer__r.Name,  
                    dealer__Taxable__c, MobilityTaxable__c,  
                    dealer__Customer_Contact__c, TaxExemptService__c, HaveRequiredTaxCert__c 
            from dealer__Service_Estimate__c
            where Id=:estId
        ];
        setupFromServiceEstimateObj(est);
    }
    
    // setupFromServiceEstimateObj 
    //-----------------------------
    public void setupFromServiceEstimateObj(dealer__Service_Estimate__c est) {
		objectType = est.getSObjectType().getDescribe().getName();        

        setStore(est.dealer__Store_Location__c);

        // Load up tax rules
        taxrules = getTaxRules(est.dealer__Store_Location__c);

        if (est.dealer__Customer__c!=null) {

            System.debug('Service Estimate customer id=' + est.dealer__Customer__c);

            Account a=null;
            try {
                a = [
                select BillingStreet, BillingCity, BillingState, BillingPostalCode, 
                    SalesTaxStatus__c, ExemptionCertificate__c  // c2g__CODASalesTaxStatus__c, c2g__CODAExemptionCertificate__c
                from Account
                where Id=:est.dealer__Customer__c
                limit 1 
            ];
            } catch(Exception e) {}
                
            // Generate request
            Date docdate = Date.today();
            //BLL58d if (sro.dealer__Posted_Date_Time__c!=null) docdate = sro.dealer__Posted_Date_Time__c.date();
            gettaxReq = getAvataxRequest(
                AVATAX_COMPANY, 
                est.Name, 
                (String) est.dealer__Customer__r.Name, 
                docdate,
                est.dealer__Customer__c
            );
			gettaxReq.DocType = 'SalesOrder';
            gettaxReq.LocationCode = store!=null ? store.dealer__Company_Number__c : null;

            if (a!=null && a.SalesTaxStatus__c=='Exempt') {
                if (a.ExemptionCertificate__c!=null) {
                    gettaxReq.ExemptionNo = a.ExemptionCertificate__c;
                } else {
                    gettaxReq.ExemptionNo = 'OnFile';
                }
            // BLL3a - if RO is exempt tell Avalara it's exempt (usually for ROs paid by the VA or similar)
            } else {
            	if (est.TaxExemptService__c == true) gettaxReq.ExemptionNo = 'ExemptRO';
            // BLL3a end
            }

            // Generate lines
            // Sum by SIC code? By Line? by Part?
                
            // Lines (labor, part, sublet)
            Map<Id,dealer__Service_Estimate_Line__c> estLineMap = new Map<Id, dealer__Service_Estimate_Line__c>([ 
                select dealer__Line_Number__c, 
                	dealer__Labor_Operation__c, 
                	//BLL58d dealer__Standard_Operation_Code__r.OperationTaxType__c,
                    //BLL58d dealer__Labor_Charges__c, dealer__Parts_Total__c, dealer__Sublet_Total__c,
					//BLL58d dealer__Labor_Type__c // BLL8a
                	dealer__Labor_Operation__r.OperationTaxType__c, 	// BLL58a
                	dealer__Labor__c, dealer__Parts__c, dealer__Sublet_Charges__c, 
                	dealer__Labor_Type__c, dealer__Misc_Charges__c
                from dealer__Service_Estimate_Line__c 
                where dealer__Service_Estimate__c =:est.Id 
                order by Name
            ]);
            
            // Determine C/I/W designation by labor type
            Set<String> labortypes = new Set<String>();
            Map<String,String> labortypemap =new Map<String,String>();
            for(dealer__Service_Estimate_Line__c l : estLineMap.values()) labortypes.add(l.dealer__Labor_Type__c);
			for(ServicePaymentType__c spt: [
				select Id, Name, Payment_Type__c
				from ServicePaymentType__c
				where Name in :labortypes
			]) {
				labortypemap.put(spt.Name, spt.Payment_Type__c);					
			}
			
            // number the lines
            Integer nbr = 0;
            for(dealer__Service_Estimate_Line__c sel : estLineMap.values()) sel.dealer__Line_Number__c = ++nbr;
            System.debug('estLineMap');
			System.debug(estLineMap);

            // Misc charges (Customer-pay only), use std op code's avatax SIC id
            //BLL58d List<AggregateResult> miscChgs = [
            //BLL58d     select Service_Job_Line__c, Type__c, max(Service_Job_Line__r.dealer__Line_Number__c) LineNo,
            //BLL58d         Service_Job_Line__r.dealer__Standard_Operation_Code__r.OperationTaxType__c TaxType,
			//BLL58d 		Service_Job_Line__r.dealer__Labor_Type__c LaborType, // BLL8a
            //BLL58d         sum(Amount__c) Amount
            //BLL58d     from ServiceMiscCharges__c
            //BLL58d     where Service_Job_Line__r.dealer__Service_Repair_Order__c=:sro.Id
            //BLL58d       //BLL8d and Service_Job_Line__r.dealer__Labor_Type__c='C'
            //BLL58d     group by Service_Job_Line__c, Type__c, Service_Job_Line__r.dealer__Standard_Operation_Code__r.OperationTaxType__c,
            //BLL58d     	Service_Job_Line__r.dealer__Labor_Type__c // BLL8a
            //BLL58d ];
            //BLL58d Set<Decimal> LineMiscChg = new Set<Decimal>();
            //BLL58d for(AggregateResult msc : miscChgs) {
            //BLL58d     if (((Decimal) msc.get('Amount'))>0.00) {
            //BLL58d         LineMiscChg.add((Decimal) msc.get('LineNo'));
            //BLL58d     }
            //BLL58d }
            // BLL58a misc charge sublines
            List<AggregateResult> miscChgs = [
            	select dealer__Misc_Charge_Code__c, dealer__Line_Type__c, 
	            	dealer__Service_Estimate_Line__c, max(dealer__Service_Estimate_Line__r.dealer__Line_Number__c) LineNo,
					dealer__Service_Estimate_Line__r.dealer__Labor_Operation__r.OperationTaxType__c TaxType,
					dealer__Service_Estimate_Line__r.dealer__Labor_Type__c LaborType,
					sum(dealer__Misc_Charge_Amount__c) Amount
            	from dealer__Service_Estimate_SubLine__c
            	where dealer__Service_Estimate_Line__r.dealer__Service_Estimate__c=:est.Id
            	  and dealer__Misc_Charge_Amount__c !=null and dealer__Misc_Charge_Amount__c !=0
            	group by dealer__Service_Estimate_Line__c, 
            		dealer__Misc_Charge_Code__c, dealer__Line_Type__c, 
            		dealer__Service_Estimate_Line__r.dealer__Labor_Operation__r.OperationTaxType__c,
            		dealer__Service_Estimate_Line__r.dealer__Labor_Type__c
            ];
            // BLL58a end

            // Build lines for tax request
            gettaxReq.Lines = new TaxSvc.ArrayOfLine();
            gettaxReq.Lines.Line = new List<TaxSvc.Line>();

            Map<Decimal,Decimal> lineTaxableMiscAmt = new Map<Decimal,Decimal>();	// BLL33a
            Map<Decimal,Decimal> lineSubletAmt = new Map<Decimal,Decimal>();	// BLL33a
            // BLL33a move misc charges above other line processes because of need to know if any are taxable (not NT)
            // How to assign "Shop Supplies", "Hazardous Materials", "Freight", "Other"???
            // Miscellaneous charges
            for(AggregateResult m : miscChgs) {
                Id lineId = (Id) m.get('dealer__Service_Estimate_Line__c');
                System.debug('line id=' + lineId);
                System.debug(estLineMap.get(lineId));
                Decimal lineNumber =  estLineMap.get(lineId).dealer__Line_Number__c;
                System.debug('line number=' + String.valueOf(lineNumber));
                String lineNumberStr = String.valueOf(lineNumber);
               	if (lineNumber==null) lineNumber = 0;
               	lineNumber = lineNumber.round();

				String miscchgcode = (String) m.get('dealer__Misc_Charge_Code__c');
				if (miscchgcode==null) miscchgcode = '';
				
            	// skip sublets
            	if (miscchgcode=='Sublet') {
            		Decimal subletamt =m.get('Amount')!=null ? ((Decimal) m.get('Amount')).setScale(2) : 0.00; 
            		Decimal existingamt = lineSubletAmt.get(linenumber);
            		if (existingamt==null) existingamt = 0.00;
					lineSubletAmt.put(linenumber, subletamt + existingamt);

            	} else {	// not sublets

                TaxRuleOpCodeSetting__c op = taxRuleOpCodeMap.get((String) m.get('TaxType'));
                System.debug(est.MobilityTaxable__c);
                //BLL61d String miscSIC = est.MobilityTaxable__c ? taxrules.RepairMiscTX__c : taxrules.RepairMisc__c;
                // BLL61a
                String miscSIC = taxrules.RepairMisc__c;
                if (!String.isBlank(taxrules.TaxDocumentRequired__c) && est.HaveRequiredTaxCert__c) miscSIC = taxrules.RepairMiscWithCert__c;
                if (est.MobilityTaxable__c) miscSIC = taxrules.RepairMiscTX__c;
                // BLL61a end
                System.debug(miscSIC);
                System.debug(op);
                if (op!=null) miscSIC = est.MobilityTaxable__c ? op.MiscTX__c : op.Misc__c;
                System.debug(miscSIC);
                // BLL33a - override by type
                String taxtype = (String) m.get('TaxType');
                if (taxtype==null) taxtype='Non-mobility';
                String miscChgOvr =  ((String) m.get('dealer__Misc_Charge_Code__c')) + ':' + taxtype;
                if (taxRuleOverrides.containsKey(miscChgOvr)) {
                   TaxRuleOverride__c ovr = taxRuleOverrides.get(miscChgOvr);
                   //BLL61d miscSIC = est.MobilityTaxable__c ? ovr.TaxCodeTX__c : ovr.TaxCode__c; 
					miscSIC = ovr.TaxCode__c;	// BLL61a
					if (!String.isBlank(taxrules.TaxDocumentRequired__c) && est.HaveRequiredTaxCert__c) miscSIC = ovr.TaxCodeWithCert__c;	// BLL61a
					if (est.MobilityTaxable__c) miscSIC = ovr.TaxCodeTX__c;	// BLL61a
 	               System.debug('Override tax code (' + miscChgOvr + '): ' + miscSIC);
                }
                // BLL33a end
                String labortype = (String) m.get('LaborType');
                String laborclass = labortype;
                if (labortypemap.containsKey(labortype)) laborclass = labortypemap.get(labortype);	// get C/I/W code for labor type
                if (laborclass=='I' && taxrules.InternalOverride__c!=null) miscSIC = taxrules.InternalOverride__c; 
                if (laborclass=='W' && taxrules.WarrantyOverride__c!=null) miscSIC = taxrules.WarrantyOverride__c;
                System.debug('LaborType ' + m.get('LaborType') + '(' + laborclass + ')' + ' : ' + miscSIC);
                 
                // Misc
                Decimal misc = m.get('Amount')!=null ? ((Decimal) m.get('Amount')).setScale(2) : 0.00;
                if (misc!=null && misc!=0) {
                    TaxSvc.Line line = new TaxSvc.Line();
                    //line.No = String.valueOf(lineNbr++);
                    line.No = lineNumberStr + ': Misc ' + m.get('dealer__Misc_Charge_Code__c') + ' (' + m.get('LaborType') + ')';
                    line.ItemCode = lineNumberStr + ': Misc ' + m.get('dealer__Misc_Charge_Code__c') + ' (' + m.get('LaborType') + ')';
                    line.Description = line.ItemCode;   
                    line.Amount = misc; 
                    line.TaxCode = miscSIC;
                    gettaxReq.Lines.Line.add(line);
                    // BLL33a - Aggregate all misc charges to one line item in Avalara
                   	Decimal amt = lineTaxableMiscAmt.get(lineNumber);
                   	if (amt==null) amt=0.00;
                   	if (line.Amount!=0 && line.TaxCode!='NT') amt += line.Amount;
                   	if (lineNumber!=null && amt!=null) lineTaxableMiscAmt.put(lineNumber, amt); 
                    // BLL33a end
                }
            	} // end sublets else
            } // end for misc

			// BLL64
			boolean PartsOrSubletTaxable = false;
			Set<String> NonTaxableCodes = new Set<String>{'PH050302','NT'};
			Map<String,String> TaxableLaborMap = new Map<String,String>{'SI020200'=>'SI020100'};
			// BLL64 end

            //Integer lineNbr = 1;
            for(dealer__Service_Estimate_Line__c l : estLineMap.values()) {
                TaxRuleOpCodeSetting__c op = taxRuleOpCodeMap.get(l.dealer__Labor_Operation__r.OperationTaxType__c);
	            //String partsSIC = est.MobilityTaxable__c ? taxrules.RepairPartsTX__c : taxrules.RepairParts__c;
                //String laborSIC = est.MobilityTaxable__c ? taxrules.RepairLaborTX__c : taxrules.RepairLabor__c;
                //String subletSIC = est.MobilityTaxable__c ? taxrules.RepairSubletTX__c : taxrules.RepairSublet__c;
                String laborclass = l.dealer__Labor_Type__c;
                if (labortypemap.containsKey(l.dealer__Labor_Type__c)) laborclass = labortypemap.get(l.dealer__Labor_Type__c);	// get C/I/W code for labor type
                //if (op!=null) {
                //    partsSIC = est.MobilityTaxable__c ? op.PartsTX__c : op.Parts__c;
                //    laborSIC = est.MobilityTaxable__c ? op.LaborTX__c : op.Labor__c;
                //    subletSIC = est.MobilityTaxable__c ? op.SubletTX__c : op.Sublet__c;
                //} 
                //BLL61d String partsSIC = sro.MobilityTaxable__c ? taxrules.RepairPartsTX__c : taxrules.RepairParts__c;
                //BLL61d String laborSIC = sro.MobilityTaxable__c ? taxrules.RepairLaborTX__c : taxrules.RepairLabor__c;
                //BLL61d String subletSIC = sro.MobilityTaxable__c ? taxrules.RepairSubletTX__c : taxrules.RepairSublet__c;
                // BLL61a
                String partsSIC = taxrules.RepairParts__c;	
                String laborSIC = taxrules.RepairLabor__c;
                String subletSIC = taxrules.RepairSublet__c;
                if (!String.isBlank(taxrules.TaxDocumentRequired__c) && est.HaveRequiredTaxCert__c) {
                	if (!String.isBlank(taxrules.RepairPartsWithCert__c)) partsSIC = taxrules.RepairPartsWithCert__c;
                	if (!String.isBlank(taxrules.RepairLaborWithCert__c)) laborSIC = taxrules.RepairLaborWithCert__c;
                	if (!String.isBlank(taxrules.RepairSubletWithCert__c)) subletSIC = taxrules.RepairSubletWithCert__c;
                }
                if (op!=null) {
                    if (!String.isBlank(op.Parts__c) && !est.MobilityTaxable__c) partsSIC = op.Parts__c;
                    if (!String.isBlank(op.Labor__c) && !est.MobilityTaxable__c) laborSIC = op.Labor__c;
                    if (!String.isBlank(op.Sublet__c) && !est.MobilityTaxable__c) subletSIC = op.Sublet__c;
	                if (!String.isBlank(taxrules.TaxDocumentRequired__c) && est.HaveRequiredTaxCert__c) {
                    	if (!String.isBlank(op.PartsWithCert__c) && !est.MobilityTaxable__c) partsSIC = op.PartsWithCert__c;
                    	if (!String.isBlank(op.LaborWithCert__c) && !est.MobilityTaxable__c) laborSIC = op.LaborWithCert__c;
                    	if (!String.isBlank(op.SubletWithCert__c) && !est.MobilityTaxable__c) subletSIC = op.SubletWithCert__c;
	                }
	                if (!String.isBlank(op.PartsTX__c) && est.MobilityTaxable__c) partsSIC = op.PartsTX__c;
	                if (!String.isBlank(op.LaborTX__c) && est.MobilityTaxable__c) laborSIC = op.LaborTX__c;
	                if (!String.isBlank(op.SubletTX__c) && est.MobilityTaxable__c) subletSIC = op.SubletTX__c;
	                // BLL61a end
                }

                if (laborclass=='I' && taxrules.InternalOverride__c!=null) {
                	partsSIC = taxrules.InternalOverride__c;
                	laborSIC = taxrules.InternalOverride__c;
                	subletSIC = taxrules.InternalOverride__c;
                } 
                if (laborclass=='W' && taxrules.WarrantyOverride__c!=null) {
                	partsSIC = taxrules.WarrantyOverride__c; 
                	laborSIC = taxrules.WarrantyOverride__c; 
                	subletSIC = taxrules.WarrantyOverride__c; 
                } 

                Decimal labor = l.dealer__Labor__c!=null ? l.dealer__Labor__c.setScale(2) : 0.00;
                Decimal parts = l.dealer__Parts__c!=null ? l.dealer__Parts__c.setScale(2) : 0.00;
                //Decimal sublet = l.dealer__Sublet_Charges__c!=null ? l.dealer__Sublet_Charges__c.setScale(2) : 0.00;
           		Decimal sublet = lineSubletAmt.get(l.dealer__Line_Number__c);
            	if (sublet==null) sublet = 0.00;
                
                //boolean haveMisc = LineMiscChg.contains(j.dealer__Line_Number__c);  // misc chgs are generally not taxable per Janeen P. 12/4/2015
                
                // Parts
                if (parts!=null && parts>0) {
                    TaxSvc.Line line = new TaxSvc.Line();
                    //line.No = String.valueOf(lineNbr++);
                    line.No = String.valueOf(l.dealer__Line_Number__c) + ': Parts' + ' (' + l.dealer__Labor_Type__c + ')';
                    line.ItemCode = String.valueOf(l.dealer__Line_Number__c) + ': Parts' + ' (' + l.dealer__Labor_Type__c + ')';
                    line.Description = line.ItemCode;   
                    line.Amount = parts; 
                    line.TaxCode = partsSIC;
                    gettaxReq.Lines.Line.add(line);
					// BLL64
					PartsOrSubletTaxable = PartsOrSubletTaxable || !NonTaxableCodes.contains(line.TaxCode);
					// BLL64 end
                }
                // Sublet
                if (sublet!=null && sublet>0) {
                    TaxSvc.Line line = new TaxSvc.Line();
                    //line.No = String.valueOf(lineNbr++);
                    line.No = String.valueOf(l.dealer__Line_Number__c) + ': Sublet' + ' (' + l.dealer__Labor_Type__c + ')';
                    line.ItemCode = String.valueOf(l.dealer__Line_Number__c) + ': Sublet' + ' (' + l.dealer__Labor_Type__c + ')';
                    line.Description = line.ItemCode;   
                    line.Amount = sublet; 
                    line.TaxCode = subletSIC;
                    gettaxReq.Lines.Line.add(line);
					// BLL64
					PartsOrSubletTaxable = PartsOrSubletTaxable || !NonTaxableCodes.contains(line.TaxCode);
					// BLL64 end
                }
                // BLL33c move labor to last
                // Labor
                if (labor!=null && labor>0) {
                    TaxSvc.Line line = new TaxSvc.Line();
                    //line.No = String.valueOf(lineNbr++);
                    line.No = String.valueOf(l.dealer__Line_Number__c) + ': Labor' + ' (' + l.dealer__Labor_Type__c + ')';
                    line.ItemCode = String.valueOf(l.dealer__Line_Number__c) + ': Labor' + ' (' + l.dealer__Labor_Type__c + ')';
                    line.Description = line.ItemCode;   
                    line.Amount = labor; 
                    line.TaxCode = laborSIC;
					// BLL33a
                   	Decimal linenbr = l.dealer__Line_Number__c!=null ? l.dealer__Line_Number__c : 0;
                   	linenbr = linenbr.round();
                   	Decimal taxablemiscamt = lineTaxableMiscAmt.get(linenbr);
                   	// BLL33a
                    if (taxRuleOverrides.containsKey('Labor:NoPartOrSublet') && parts==0 && sublet==0) {
                        TaxRuleOverride__c ovr = taxRuleOverrides.get('Labor:NoPartOrSublet');
                        line.TaxCode = ovr.TaxCode__c; 
                    }
                    // BLL33a
                    if (taxRuleOverrides.containsKey('Labor:NoPartSubletMisc') && parts==0 && sublet==0 && taxablemiscamt==0) {
                        TaxRuleOverride__c ovr = taxRuleOverrides.get('Labor:NoPartSubletMisc');
                        line.TaxCode = ovr.TaxCode__c; 
                    }
                    // BLL33a end
                    gettaxReq.Lines.Line.add(line);
                }
            } // end for sumlines

			// BLL64 - go back through labor if Labor:NoTaxablePartSubletMiscOnRO
			// Change stand-alone-labor tax code with Labor with parts tax code
			TaxRuleOverride__c spclovr = taxRuleOverrides.get('Labor:NoTaxablePartSubletMiscOnRO');
			if (spclovr!=null) {
				for(TaxSvc.Line l : gettaxReq.Lines.Line) {
					if (l.ItemCode !=null && l.ItemCode.contains(': Labor') && TaxableLaborMap.containsKey(l.TaxCode)) {
						l.TaxCode = TaxableLaborMap.get(l.TaxCode);
					}
				}
			}
			// BLL64 end

        } // end if customer!=null 

        if (gettaxReq!=null && gettaxReq.Lines!=null) {
            debugTaxRequestLines();
            // Fix any null tax codes - plug with P0000000
            for (TaxSvc.Line l : gettaxReq.Lines.Line) {
                if (l.TaxCode==null) l.TaxCode = 'P0000000';
            }
        }

    } // end setupFromServiceEstimateObj

    // saveEstimateTaxDetail
    //------------------------------
    public void saveEstimateTaxDetail() {
        if (objectType!='dealer__Service_Estimate__c') {
            throw new TaxException('Cannot save to service estimate when object type is ' + objectType);
        }

        dealer__Service_Estimate__c updservice = new dealer__Service_Estimate__c(Id=objectId);
        updservice.TaxCalcDT__c = DateTime.now();
        updservice.TaxHash__c = getHash();
        TaxResults resultSmry = summarizeTaxResults();
        updservice.TaxResults_JSON__c = JSON.serialize(resultSmry);
        update(updservice);
        System.debug(updservice);

        // line taxes
		Map<Id,dealer__Service_Estimate_Line__c> estLineMap = new Map<Id, dealer__Service_Estimate_Line__c>([ 
			select dealer__Line_Number__c, 
				dealer__Labor_Operation__c, 
				dealer__Labor_Operation__r.OperationTaxType__c, 
				dealer__Labor__c, dealer__Parts__c, dealer__Sublet_Charges__c, 
				dealer__Labor_Type__c, dealer__Misc_Charges__c
			from dealer__Service_Estimate_Line__c 
			where dealer__Service_Estimate__c =:objectId 
			order by Name
		]);
		
		// Map of line summary by line
		Map<Integer,TaxResultLine> byLineNbr = new Map<Integer,TaxResultLine>();
		if (resultSmry!=null && resultSmry.byLine!=null) {
			for(TaxResultLine trl : resultSmry.byLine) {
				Integer lnbr = Integer.valueOf(trl.LineNo);
				byLineNbr.put(lnbr,trl);
			}
		}
		System.debug(byLineNbr);
		
		// number the lines & assign tax results
		Integer nbr = 0;
		for(dealer__Service_Estimate_Line__c sel : estLineMap.values()) {
			sel.dealer__Line_Number__c = ++nbr;
			TaxResultLine trl = byLineNbr.get(nbr);
			if (trl!=null) {
				sel.dealer__Tax__c = trl.Tax;
			} 
		}
		update(estLineMap.values());
    }

	// summarizeTaxResults
	//-------------------------------
	public TaxResults summarizeTaxResults() {
		TaxResults rslt = new TaxResults();
		if (gettaxRslt!=null && gettaxRslt.TaxLines!=null && gettaxRslt.TaxLines.TaxLine!=null  
			&& gettaxRslt.TaxLines.TaxLine.size()>0) {

			rslt.DocumentName = gettaxRslt.DocCode;
        	rslt.TotalAmt = gettaxRslt.TotalAmount;
			rslt.TotalDiscount = gettaxRslt.TotalDiscount;
			rslt.TotalExemption = gettaxRslt.TotalExemption;
			rslt.TaxableAmt = gettaxRslt.TotalTaxable;
			rslt.Tax = gettaxRslt.TotalTax;

			Map<String,TaxResultJuris> jurismap = new Map<String,TaxResultJuris>();
			Map<String,TaxResultLine> linemap = new Map<String,TaxResultLine>();

			for(TaxSvc.TaxLine t : gettaxRslt.TaxLines.TaxLine) {
				System.debug(t);
				// line summary
				String[] k = t.No.split(':');
				if (k.size()>0) System.debug('Line no: ' + k[0]);
				else System.debug('No line number');
				if (k.size()>0) {
					String linekey = k[0];
					TaxResultLine l = linemap.get(linekey);
					if (l==null) l = new TaxResultLine();
					l.TaxableAmt += t.Taxable;
					l.Tax += t.Tax;
					l.LineNo = linekey;
					linemap.put(linekey,l);
                }
				// jurisdiction/rate summary
				for(TaxSvc.TaxDetail d :  t.TaxDetails.TaxDetail) {
					String jurratekey = d.JurisCode + ':' + String.valueOf(t.Rate);
					TaxResultJuris trj = jurismap.get(jurratekey);
					if (trj==null) trj = new TaxResultJuris();
					trj.Jurisdiction = d.JurisName;
					trj.JurisdictionCode = d.JurisCode;
					trj.JurisdictionType = d.JurisType;
					trj.TaxType = d.TaxType;
					trj.TaxRate = d.Rate;
					trj.TaxableAmt += d.Taxable;
					trj.Tax += d.Tax;
					jurismap.put(jurratekey, trj);
				}

            }
			rslt.byJurisdiction = jurismap.values();
			rslt.byLine = linemap.values();
		}
		return rslt;
	}

	public class TaxResults {
		public String DocumentName;
		public Decimal TotalAmt;
		public Decimal TotalDiscount;
		public Decimal TotalExemption;
		public Decimal TaxableAmt;
		public Decimal Tax;
		public List<TaxResultJuris> byJurisdiction;
		public List<TaxResultLine> byLine;
	}
	public class TaxResultJuris {
		public String TaxType;
		public Decimal TaxableAmt;
		public String Jurisdiction;
		public String JurisdictionCode;
		public String JurisdictionType;
		public Decimal TaxRate;
		public Decimal Tax;
		public TaxResultJuris() {
			TaxType = '';
			TaxableAmt = 0.00;
			Jurisdiction = '';
			JurisdictionCode = '';
			JurisdictionType = '';
			TaxRate = 0.00;
			Tax = 0.00;
		}
	}
	public class TaxResultLine {
		public String LineNo;
		public Decimal TaxableAmt;
		public Decimal Tax;
		public TaxResultLine() {
			LineNo = '';
			TaxableAmt = 0.00;
			Tax = 0.00;
		}
	}
	
	// BLL58a end

    //-----------------------------
    public class TaxException extends Exception{}
    
    //-----------------------------
    public class AvaTaxException extends Exception{}
 
}