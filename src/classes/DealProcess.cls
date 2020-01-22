/**
 * DealProcess
 * Tested by: DealProcess_TEST
 * Use MW Invoice - Auto Grant proposal form to test?
 * Date: Aug 5, 2016
 * Programmer: Bryan Leaman
 *
 * Code coverage:
 *	2017-09-21	82% (460/559)
 *	2017-10-02	81% (462/565)
 *	2017-10-19	80% (475/589)
 *	2018-01-03	79% (519/649)
 *	2018-01-04	87% (560/647)       
 *	2018-01-23	82%	(597/726)        
 *	2018-03-07	80% (641/797)  
 *	2018-03-19	81% (659/808) 
 *	2018-04-03	79% (662/830)   
 *	2018-06-29	78% (658/837)
 *	2018-08-28	78% (660/842)
 *	2018-09-12	78% (663/850)
 *	2018-10-03	82%	(703/855)
 *	2019-01-22	84% (821/975)
 *	2019-01-31	84%	(837/994)
 *	2019-02-27	84%	(834/990)
 *
 * MW_TriggerControls__c	Routine(s) where used
 *	ProtectPostedDeal		ProposalIntegrity
 *	DealBuyerAccount		ProposalIntegrity (buyer cannot be 3rd party payor account type)
 *	DealStatusValidation	StatusChangeValidation
 *	DealQuoteValidation		StatusChangeValidation
 *	DealPayorValidation		StatusChangeValidation
 *	AvataxDeal				StatusChangeValidation
 *	DealCopyFields			SyncManagedFields
 *	DlvVehUnavailable		RmvDlvVehFromPendingDeals
 *	AppraisalsMarkLost		CloseAlternativeProposals
 *
 *  
 * Mod marks are for reference from original triggers the code was pulled from to consolidate and clean up the process.
 *	2016-08-26	B. Leaman	BLL9 Improve test for moving to the delivery stage (for open ro check). Was testing old status was Production & new status is Delivery, but a new step had been introduced to the process (GM Approval)
 *	2016-09-21	B. Leaman	BLL1 - Add method to synchronize managed package fields with custom fields that have the same name.
 *	2016-10-24	B. Leaman	BLL13 - Post tax when proposal is posted instead of when delivered because this prevents pulling proposal back
 *							after delivery for corrections and re-approving for delivery.
 *	2016-10-31	B. Leaman	BLL14 - allow f&i field updates after posting; fix Won - Delivery w/ open ROs test to allow rejection from Delivered;
 *							Reset contract status when entering F&I step.
 *	2016-11-18	B. Leaman	BLL15 #IR-0003241 - Don't allow vehicle to be delivered if the location doesn't match the proposal store.
 *	2016-11-29	B. Leaman	BLL16 #IR-0003953 - Require vehicle before delivery of retail or wholesale vehicle sale.
 *	2016-12-05	B. Leaman	BLL17 #IR-0003714 - Don't allow won proposal on 'Quote' Solution opp
 *	2016-12-09	B. Leaman	BLL18 #IR-0004388 - When pushed to delivery, ensure "LastSavedDT__c" is as recent (within a second or so) of LastModifiedDate.
 *							This is to ensure the latest costs & GP calculations are up-to-date!
 *	2016-12-19	B. Leaman	BLL19 - Test method was causing a failure. 
 *	2016-12-29	B. Leaman	BLL20 - Replace custom lookups with managed versions (Deal obj), allow disable of validations for mass updates.
 *	2017-01-03	B. Leaman	BLL21 - Update to use Funding_option__c instead of "Contract_CustomerArranged__c".
 *	2017-02-10	B. Leaman	BLL22 - Commercial Proposal chgs: Enforce calculations for proposals & add AdministrativeUpdate flag/feature to bypass some validations
 * 							when history is being updated by an Admin/developer. Doesn't bypass validations & actions imposed on status changes!
 *	2017-02-20	B. Leaman	BLL23 - Mark appraisals won when proposal is posted.
 *	2017-05-03	B. Leaman	BLL24 - Set owner according to location's service reporting user.
 *	2017-05-05	B. Leaman	BLL25 - Protect "Delivered" status on a vehicle from being updated back to "Sold not Delivered". 
 *	2017-05-15	B. Leaman	BLL26 - Relax requirement of a conversion build for retail for now.
 *	2017-05-17	B. Leaman	BLL27 - Protect additional vehicle statuses from being updated to Sold - Not Delivered.
 *	2017-05-09	B. Leaman	BLL28 - BancLease fee & sub-prime loan cost support.
 *	2017-07-17	B. Leaman	BLL29 - skip over order step if there's no commercial quote (retail).
 *	2017-07-31	B. Leaman	BLL30 - enforce approver in approver list for ordering & receiving vehicles; 
 *							fill in default appraiser if missing when marking appraisals won.
 *	2017-09-06	B. Leaman	BLL31 - update service contracts with service vehicle when vehicle is delivered (remove is changed from Won to not Won)
 *	2017-09-18	B. Leaman	BLL32 IR-0016771 - remove parts notification *after* production is complete.
 *							Supply vehicle owner if missing (using buyer on proposal)
 *	2017-10-17	B. Leaman	BLL33 - Also need to update service vehicle owner acct if missing; 
 *							fix initial trade & appraisal insert to properly connect service vehicle;
 *	2017-11-13	B. Leaman	BLL34 - Prevent multiple won, chassis/sale proposals from inventory or ordered for the same stock record.
 *	2017-12-01	B. Leaman	BLL35 - Part removal alert should show cost, not price.
 * 	2017-12-01	B. Leaman	BLL36 - vehicle map needs to not be null.
 *	2017-12-04	B. Leaman	BLL37 - When won, require payor amount if payor specified & vice versa. Not done in a validation
 *							rule because they aren't enforced during approval steps.
 *	2017-12-19	B. Leaman	BLL38 - DME & Financial approval process status change sequences differ from other proposals.
 *	2018-01-22	B. Leaman	BLL39 - ESC status & references update upon delivery of vehicle; udpate vehicle owner account for sold veh and trade-ins;
 *							improve efficiency with singletons; monitor execution;
 *	2018-01-26	B. Leaman	BLL40 - Require service vehicle on Financial Products proposals
 *	2018-02-26	B. Leaman	BLL41 - Remove trade-in ownership change (part of BLL39).
 *	2018-03-02	B. Leaman	BLL42 - Close alternative deals for a newly won solution opp;
 *							Mark all "Lost" proposals' trade-in appraisals as "Lost";
 *							Update other proposals on delivered vehicles to "Lost";
 *							Update veh status from Sold - Not Delivered to Not For Sale if proposal becomes un-won;
 *							// Similar Appraisal logic in BatchUpdateInactiveDeals, Deal_MBW2, DealProcess
 *							Set vehicle status assignment date when status is changed; Include misc description on remove parts alert;
 *	2018-04-03	B. Leaman	BLL43 - Implement GP Sharing rule.
 *	2018-04-25	B. Leaman	BLL44 - Don't prevent rejection back to Pending due to not having financing option filled in.
 *	2018-05-01	B. Leaman	BLL45 - Don't allow pushing a proposal through the "Won" steps with negative sales tax;
 *							allow dealerteam to update new summary fields on proposal (other gross, other premium);
 *							trigger control for preventing same stock unit on multiple won proposals: DealDuplicateStockSale;
 *	2018-06-29	B. Leaman	BLL46 - adjust parts removal alert to NOT resend alert when pulled back from posted to delivery.
 *	2018-07-17	B. Leaman	BLL47 - don't replace sales tax override unless the subordinate fields are filled in. 
 *	2018-07-25	B. Leaman	BLL48 - Don't allow GM to approve the F&I step.
 *	2018-08-22	B. Leaman	BLL49 - totalUnitPrice should not include deposit or downpayment.
 *	2018-08-22	B. Leaman	BLL50 - Allow customer-owned vehicle to be used on chassis/conversion deal when stock# was sold on another proposal;
 *							fill in residual amount on leases;
 *	2018-09-05	B. Leaman	BLL51 - prevent delivery of leases if financed amt is missing or first pmt (deposit) and amt due both $0.
 *	2018-09-13	B. Leaman	BLL52 - government assistance and 3rd party/other payors were doubling up.
 *	2018-09-21	B. Leaman	BLL53 IR-0040776 - If user is authorized to have set the administrative update checkbox, bypass test for named approvers.
 *	2018-09-24	B. Leaman	BLL54 W-000439 - allow system to update "TaxPostDT__c" & "TaxCommitDT__c" after proposal is in Won - Posted status,
 *							because that's when the avalara records are committed.
 *	2018-11-07	B. Leaman	W-000482 BLL55 Set VA Approver and Approval DateTime when VA Paperwork Approved flag is changed.
 *							W-000466 Allow FICO score (and above VA paperwork approver info) to change after posting.
 *							W-000538 Consolidate "addfields" to a static method for reuse.
 *	2019-01-17	B. Leaman	W-000482 // not implemented: BLL56 new step for VA paperwork approval.
 *	2019-01-22	B. Leaman	W-000562 BLL57 move validation rules to trigger so that AdministrativeUpdate can be checked;
 *									 (trigger resets flag before validation rule fires).
 *	2019-01-31	B. Leaman	W-000535 BLL58 Don't allow past-due delivery dates on pushed proposals (until delivery & posting steps); 
 *							Also don't allow future dates over 1 year out, to prevent some typos on the year.
 *	2019-02-18	B. Leaman	W-000579 BLL59 Set overall credit application status (if financed);
 *									 Allow more F&I fields to be updated after posting;
 *									 Remove a few more fields -- we went over the 20000 character query limit.
 *									 Skip F&I approval if credit application status is delivered.
 *	2019-03-01	B. Leaman	W-000610 BLL60 - prevent recalling proposal from delivered (back to pending); make the store contact Deeanna's team to reject it first
 *							that way Deeanna's team can make a determination as to what the vehicle status should be set to.
 *	2019-03-18	B. Leaman	W-000538 BLL61 - Jeff P. added a new field from the buyer to the proposal pdfs.
 *	2019-05-09	B. Leaman	W-000575 BLL62 - allow update of new field total_collected__c.
 *	2019-07-23	B. Leaman	W-000606, W-000702 BLL63 - Store financing skips F&I step; Financial Products loan cost to not hit regular GP;
 *	2019-07-24	B. Leaman	W-000726 BLL64 - Don't create a new posting entry just because delivered proposal was updated
 *							unless the status was updated and not moving backwards from Won - Posted.
 *	2019-08-12	B. Leaman	W-000736 BLL65 Cannot update old ESC because buyer now violates newer rule (or account type was updated to vendor);
 *	2019-08-22	B. Leaman	W-000744 BLL66 - record date proposal first enters approval process
 *	2019-08-23	B. Leaman	W-000674 BLL67 - protect additional vehicle statuses from changes to NFS
 *	2019-08-28	B. Leaman	W-000747 BLL68 - separate approvers & owner for home access proposals.
 *	2019-09-27	B. Leaman	W-000730 BLL69 - remove additional fields from query for DT v5.x. 
 *							*** Should revisit and switch away from DTMOB and custom fields where there is duplication. ***
 *	2019-12-12	B. Leaman	W-000802 BLL70 - remove more unnecessary fields from SOQL over dealer__Deal__c
 *	2919-12-20	B. Leaman	W-000788 BLL71 - new DT field needs to be updatable on posted proposals
 */
public with sharing class DealProcess {

	List<dealer__Deal__c> newlist;
	Map<Id,dealer__Deal__c> oldMap;
	Map<Id,dealer__Vehicle_Inventory__c> vehMap;	// BLL34a
	Map<Id,dealer__Finance_Company__c> FinanceCompMap = new Map<Id,dealer__Finance_Company__c>();	// BLL63
	Map<Id,dealer__Deal__c> dealTradesMap;	// BLL39a
	Set<String> deliveredStatus = new Set<String>{'Won - Delivered', 'Won - Posted'};
	// BLL58
	List<String> StatusProgression = new List<String>{'Lost', 'Pending', 'Won - Deposit', 'Won - Tech Approval',
		'Won - GM Approval', 'Won - Order', 'Won - Ordered', 
		'Won - F&I', 'Won - Production', 'Won - Delivery', 'Won - Delivered', 'Won - Posted'};
	// BLL58 end

	// DealProcess
	//---------------------------------------
	public DealProcess(List<dealer__Deal__c> nlist, Map<Id,dealer__Deal__c> omap) {
		newlist = nlist;
		oldMap = omap;
	}

	// BLL63
	// Get list of finance companies
	private Map<Id,dealer__Finance_Company__c> getFinanceCompanyMap() {
		Set<Id> fiaIds = new Set<Id>();
		for(dealer__Deal__c deal : newList) {
			if (deal.dealer__Finance_Institution_Account__c!=null) fiaIds.add(deal.dealer__Finance_Institution_Account__c); // BLL63
		}
		if (fiaIds.size()>0) FinanceCompMap = new Map<Id,dealer__Finance_Company__c>([
			select Id, Name, Store_Financing__c, FinanceAccount__c, AcquisitionCost__c, AcquisitionFee__c, ChargesAcquisitionFee__c
			from dealer__Finance_Company__c
			where Id in :fiaIds
		]);
		return FinanceCompMap;
	}
	// BLL63 end


	// BLL34a
	// Obtain list of all referenced stock vehicles on the proposals
	private Map<Id,dealer__Vehicle_Inventory__c> getVehicleInvMap() {
		if (vehMap!=null) return vehMap;
		Set<Id> vehIds = new Set<Id>();
		for(dealer__Deal__c d : newList) {
			if (d.dealer__Vehicle__c!=null) vehIds.add(d.dealer__Vehicle__c);
		}
		vehMap = new Map<Id,dealer__Vehicle_Inventory__c>();	// Needs to not be null! BLL36a
		if (vehIds.size()>0) vehMap = new  Map<Id,dealer__Vehicle_Inventory__c>([
			select Id, Name, dealer__Store_Location__c, dealer__Store_Location__r.Name,
				New_Used_Other__c, // BLL57a
				dealer__Mileage__c,	// BLL38a
				dealer__Service_Vehicle__c, // BLL39a
				( select Id, Name, dealer__Status__c, dealer__Store_Location__c, dealer__Store_Location__r.Name,
					Proposed_Delivery_Date__c, Vehicle_Source__c, // BLL50c
					dealer__Salesperson_1__c, dealer__Salesperson_1__r.Name,
					dealer__Vehicle__c, dealer__Vehicle__r.Name
					from dealer__R00N70000002II35EAG__r
				) 
			from dealer__Vehicle_Inventory__c 
			where Id in :vehIds
		]);
		return vehMap;
	}	
	// BLL34a end
	

	//--------------------------------------------------
	public void ProposalIntegrity() {

        MW_TriggerControls__c protectPostedDeal = MW_TriggerControls__c.getInstance('ProtectPostedDeal'); // BLL3a
		User u = CurrentUserSingleton.getInstance(); //BLL5c [Select Id, Division from User where Id=:UserInfo.getUserId() limit 1];
		LocationsSingleton ls = LocationsSingleton.getInstance();	// BL38a
		AccountsSingleton accounts = AccountsSingleton.getInstance();	// BLL38a

		// BLL2a - add reference to location object too
		Set<String> locset = new Set<String>();
		if (u.Division!=null && !String.isBlank(u.Division)) locset.add(u.Division);
		// BLL2a end block add ref to location obj

		// BLL24a
    	Set<Id> locIds = new Set<Id>();
    	//BLL39d Map<Id, dealer__Dealer_Location__c> locmap2 = new Map<Id, dealer__Dealer_Location__c>();
    	// BLL24a end

		// BLL1a begin
		Set<Id> includedAccounts = new Set<Id>();
		for(dealer__Deal__c d : newList) {
			if(d.dealer__Buyer__c!=null) includedAccounts.add(d.dealer__Buyer__c);
			if(d.dealer__Co_Buyer__c!=null) includedAccounts.add(d.dealer__Co_Buyer__c);
			// BLL55 - also include AutoGrant, third party and other payors in accounts to examine
			for(Id acctId : new List<Id>{d.dtmob__Auto_Grant_Payor__c, d.dealer__Deferred_1_Payee__c, d.dealer__Deferred_2_Payee__c, d.dealer__Deferred_3_Payee__c,
				d.Third_Party_Pay_1__c, d.Third_Party_Pay_2__c, d.Third_Party_Pay_3__c}) {
				if (acctId!=null) includedAccounts.add(acctId);
			}
			// BLL55 end

			// BLL2a begin
			if (d.dealer__Company_Number__c!=null && !String.isBlank(d.dealer__Company_Number__c)) {
				locset.add(d.dealer__Company_Number__c);
			}
			// BLL2a end
			if (d.dealer__Store_Location__c!=null) locIds.add(d.dealer__Store_Location__c);	// BLL24a
		}
		System.debug(locset);
		System.debug(locIds);
		ls.addLocationAbbrevs(locset);	// BLL39a
		ls.addLocationIds(locIds);	// BLL39a
		System.debug('Ready to retrieve locations');
		ls.retrieveLocations();
		System.debug(includedAccounts);	// BLL39a
		accounts.addIds(includedAccounts);	// BLL39a
		System.debug(includedAccounts);	// BLL39a
		//BLL39d Map<Id, Account> accounts = new Map<Id, Account>([Select Id, Name, FirstName, LastName, PersonContactId, isPersonAccount, RecordType.Name from Account where Id IN:includedAccounts limit 2000]);
		// BLL1a end

		// BLL2a begin map of location company numbers to ids
		//BLL39 LocationsSingleton will handle this part
		//BLL39d Map<String, Id> locmap = new Map<String, Id>();
		//BLL39d if (locset.size()>0) {
		//BLL39d 	for(dealer__Dealer_Location__c loc : [select Id, dealer__Company_Number__c, Service_Reporting_User__c from dealer__Dealer_Location__c where dealer__Company_Number__c in :locset or Id in :locIds]) {	// BLL24c add service reporting user and "or Id in :locids"
		//BLL39d 		locmap.put(loc.dealer__Company_Number__c, loc.Id);
		//BLL39d 		locmap2.put(loc.Id, loc);	// BLL24a
		//BLL39d 	}
		//BLL39d }
		// BLL2a end map
		
		// BLL14a
		Set<String> allowedfieldupdates = new Set<String>{
			'lastmodifieddate', 'lastmodifiedbyid', 'ownerid', 
			'dealer__f_i_manager__c', 'dealer__finance_institution_account__c', 'funding_option__c', 	// BLL21c 
			'contract_status__c', 'contract_customerarranged__c', 'customer_financing_source__c', 'contract_counteroffer__c',
			'contract_type__c', 'contract_residualvalue__c', 'dealer__residual_amt__c', 'contract_leaseenddate__c',	// BLL50c
			'contract_amount_financed__c', 'contract_apr__c', 'contract_final_payment__c', 'contract_finance_charge__c',
			'contract_monthly_payment__c', 'contract_number_of_payments__c', 'contract_total_of_payments__c',
			'finance_reserve__c','credit_application_received__c','credit_backtostore__c','credit_decision_received__c',
			'leaseacquisitionfee__c', 'leasemilesincluded__c', 'leasemonthlysalestax__c', 'leasemileoveragerate__c', 'loanacquisitioncost__c',	// BLL28a 
			'esc_loan_cost__c',	// BLL63
			'leasepmtduedom__c', 'dealer__first_payment_date__c', 'taxoncostreduction__c',	// BLL28a
			'leasetotalfeesandtaxes__c','leaselatepmtfee__c', 'leasedispositionfee__c', 'leaseearlyterminationfee__c', // BLL28a
			'leasesalestaxhandling__c', 'leasedocfeehandling__c', 'leaseacquisitionfeehandling__c', 'leasetitlefeehandling__c',	// BLL28a
		    'leasemoneyfactor__c', 'leasepmtbeforetax__c', 'leaseupfrontsalestax__c', 'totalupfrontcash__c', 'desiredupfrontcash__c', 
		    'chassismsrp__c', 'chassisresidualpct__c', 'chassisresidualamt__c',
		    'conversionmsrp__c', 'conversionresidualpct__c', 'conversionresidualamt__c',
		    'dealer__other_premium__c', 'dealer__other_gross__c', 	// BLL45a
		    'taxpostdt__c', 'taxcommitdt__c', 	// BLL54a
			'total_collected__c', 'dealer__totaltaxableamount__c', 	// BLL62a, // BLL71a
			'fico_score__c','va_paperwork_approved__c','va_paperwork_approver__c','va_paperwork_approvaldt__c',	// BLL55a
			'credit_application_status__c','contract_buy_rate__c','cit_reviewed_archive__c', 'cit_lender_funded__c', // BLL59
			'credit_application__c', 'credit_app_missing_items__c', 'credit_app_incomplete__c', 'credit_application_notes__c',  // BLL59a
		    'lastsaveddt__c', 'servicecontract__c'
		};
		
		MW_TriggerControls__c DealBuyerAccount = MW_TriggerControls__c.getInstance('DealBuyerAccount'); // BLL20a

		System.debug('Ready to process deals');

		// BLL55
		accounts.retrieveAccounts();
		// BLL55 end

		// BLL57
        MW_TriggerControls__c wholesaleProtections = MW_TriggerControls__c.getInstance('WholesaleProtections'); // BLL3a
		Map<Id,dealer__Vehicle_Inventory__c> vMap = getVehicleInvMap();
		// BLL57 end

		// BLL14a
		for(dealer__Deal__c d : newList) {
	        // BLL3a - do not allow updates to posted deals (controlled by flag to allow disabling quickly)
            dealer__Deal__c oldd = oldMap!=null ? oldMap.get(d.Id) : null;
	        if (oldd!=null && (protectPostedDeal==null || protectPostedDeal.Enabled__c)
	            && oldd.dealer__Status__c=='Won - Posted') {
				if (!d.AdministrativeUpdate__c && !SObjectChangedFields.OnlyAllowedFieldsChanged(d, oldd, allowedfieldupdates)) {	// BLL14a, BLL22c AdministrativeUpdate__c
		        	d.addError('Posted proposals cannot be updated ('
						+ JSON.serialize(SObjectChangedFields.getChangedFieldList(d, oldd)) +')');	// BLL14c
				}
	        }
	        // BLL3a end

			// BLL60
			if (oldd!=null && oldd.dealer__Status__c=='Won - Delivered' && d.dealer__Status__c=='Pending') {
		        	d.addError('Delivered proposals cannot be recalled. Contact Inventory Accounting to have the proposal rejected first.');
			}
			// BLL60 end

			// BLL55 - VA flags and paperwork approval
			System.debug(d.Name);
			System.debug(d.VA_Deal__c);
			System.debug(d.VA_Paperwork_Approved__c);
			processVA(d, oldd, accounts.idMap);
			System.debug(d.VA_Deal__c);
			System.debug(d.VA_Paperwork_Approved__c);
			// BLL55 end

			System.debug(d.dealer__Company_Number__c);
			System.debug(d.dealer__Store_Location__c);
			if(d.dealer__Company_Number__c=='' || d.dealer__Company_Number__c==null
				|| (d.dealer__Store_Location__c==null && d.dealer__Company_Number__c!=null && !ls.locationAbbrevMap.containsKey(d.dealer__Company_Number__c))) {	// BLL39c
				d.dealer__Company_Number__c=u.Division;
			}

			// BLL2a begin - fill in store location too
			//BLL39d if (d.dealer__Store_Location__c==null) d.dealer__Store_Location__c=locmap.get(d.dealer__Company_Number__c);
			if (d.dealer__Store_Location__c==null) {
				dealer__Dealer_Location__c loc = ls.getLocationByAbbrev(d.dealer__Company_Number__c);	// BLL39a 
				d.dealer__Store_Location__c = loc!=null ? loc.Id : null;	// BLL39a
			}
			// BLL2a end

			// DR1 sync DT field
			if (d.Total_Price__c!=null) {
				d.dealer__Sale_Price__c = d.Total_Price__c;
			}
			// end DR1

            // BLL1a begin
            //BL39d if(accounts.get(d.dealer__Buyer__c)!=null) {
            if (accounts.getById(d.dealer__Buyer__c)!=null) {	// BLL39a
			    Account c = accounts.getById(d.dealer__Buyer__c);
				if (c.RecordType.Name=='Vendor' || c.RecordType.Name=='Third Party Payor') 	{
					if (!d.AdministrativeUpdate__c && (DealBuyerAccount==null || DealBuyerAccount.Enabled__c==true)) {
						// BLL65 - allow updates to old deals where accounts have since been changed
						if (oldd==null || (oldd!=null && oldd.dealer__Status__c!='Won - Posted')) {
							d.addError('Buyer account cannot be a vendor or 3rd party payor');	// BLL20c, BLL22c AdministrativeUpdate__c
						}
					}
				}
		    }
            //BLL39d if(accounts.get(d.dealer__Co_Buyer__c)!=null) {
            if (accounts.getById(d.dealer__Co_Buyer__c)!=null) {	// BLL39a
			    Account cb = accounts.getById(d.dealer__Co_Buyer__c);
				if (cb.RecordType.Name=='Vendor' || cb.RecordType.Name=='Third Party Payor') { 
					if (!d.AdministrativeUpdate__c && (DealBuyerAccount==null || DealBuyerAccount.Enabled__c==true)) d.addError('Co-Buyer account cannot be a vendor or 3rd party payor');	// BLL20c, BLL22c AdministrativeUpdate__c
				}
		    }
            // BLL1a end
            // BLL24a set location-specific owner
            //BLL39d dealer__Dealer_Location__c loc = locmap2.get(d.dealer__Store_Location__c);
            dealer__Dealer_Location__c loc = ls.getLocationById(d.dealer__Store_Location__c);	// BLL39a
			// BLL68
			if (d.dealer__Deal_Type__c=='Home Access') {
				if (loc!=null && loc.HA_Service_Reporting_User__c!=null && d.OwnerId!=loc.HA_Service_Reporting_User__c) 
					d.OwnerId = loc.HA_Service_Reporting_User__c;
			} else {
			// BLL68 end
            	if (loc!=null && loc.Service_Reporting_User__c!=null && d.OwnerId!=loc.Service_Reporting_User__c)
            		d.OwnerId = loc.Service_Reporting_User__c;
            // BLL24a end
			// BLL68
			}
			// BLL68 end
            
			// BLL57 - cannot sell wholesale veh on non-wholesale proposal & vice versa
			if (d.AdministrativeUpdate__c==false && d.dealer__Vehicle__c!=null && d.dealer__Status__c!='Lost' && d.dealer__Status__c!='Won - Posted') {
	       		dealer__Vehicle_Inventory__c veh = d.dealer__Vehicle__c!=null ? vMap.get(d.dealer__Vehicle__c) : null; 
				if (veh!=null && veh.New_Used_Other__c!='Wholesale' && d.dealer__Deal_Type__c=='Wholesale') {
					if (wholesaleProtections==null || wholesaleProtections.Enabled__c) d.addError('Only a wholesale vehicle can be sold on a wholesale proposal');
				}
				if (veh!=null && veh.New_Used_Other__c=='Wholesale' && d.dealer__Deal_Type__c!='Wholesale') {
					if (wholesaleProtections==null || wholesaleProtections.Enabled__c) d.addError('A wholesale vehicle can only be sold on a wholesale proposal');
				}
			}
			// BLL57
		}		
	}

	// BLL55
	// processVA - set/reset VA flags & paperwork approval info
	//-------------------------------------------------------------------
	public void processVA(dealer__Deal__c d, dealer__Deal__c oldd, Map<Id, Account> accountsMap) {

		System.debug('processVA');
		System.debug(accountsMap.size());
		if (accountsMap==null) accountsMap = new Map<Id,Account>();

		boolean isVADeal = false;
		// Determine if this is still a VA deal (any payor is a va agency)
		for(Id acctId : new List<Id>{d.dtmob__Auto_Grant_Payor__c, d.dealer__Deferred_1_Payee__c, d.dealer__Deferred_2_Payee__c, d.dealer__Deferred_3_Payee__c,
			d.Third_Party_Pay_1__c, d.Third_Party_Pay_2__c, d.Third_Party_Pay_3__c}) {
			if (acctId!=null) {
				Account a = accountsMap.get(acctId);
				System.debug(a);
				if (a!=null) System.debug(a.VA_Agency__c);
				if (a!=null && a.VA_Agency__c) isVADeal = true;
			}
		}
		d.VA_Deal__c = isVADeal;
 
		// Reset VA Paperwork Approved flag if it's no longer a VA deal 
		// or *any* of the VA payor amounts has changed
		if (!d.VA_Deal__c) d.VA_Paperwork_Approved__c = false;

		// only need to reset paperwork approved flag if it's already set, otherwise don't even look!
		// NOTE: this code will only work properly if the same VA agency can only be listed once on a proposal!
		// Otherwise it'll keep automatically resetting the approved flag because one of the amounts won't match the other.
		if (d.VA_Paperwork_Approved__c) {
			Map<Id,Decimal> oldVaAmts = new Map<Id,Decimal>();
			if (oldd.dtmob__Auto_Grant_Payor__c!=null && accountsMap.get(oldd.dtmob__Auto_Grant_Payor__c).VA_Agency__c) {
				oldVaAmts.put(oldd.dtmob__Auto_Grant_Payor__c, oldd.AutoGrant__c);
			}
			if (oldd.Third_Party_Pay_1__c!=null && accountsMap.get(oldd.Third_Party_Pay_1__c).VA_Agency__c) {
				oldVaAmts.put(oldd.Third_Party_Pay_1__c, oldd.dealer__Deferred_Down_1__c);
			}
			if (oldd.Third_Party_Pay_2__c!=null && accountsMap.get(oldd.Third_Party_Pay_2__c).VA_Agency__c) {
				oldVaAmts.put(oldd.Third_Party_Pay_2__c, oldd.dealer__Deferred_Down_2__c);
			}
			if (oldd.Third_Party_Pay_3__c!=null && accountsMap.get(oldd.Third_Party_Pay_3__c).VA_Agency__c) {
				oldVaAmts.put(oldd.Third_Party_Pay_3__c, oldd.dealer__Deferred_Down_3__c);
			}
			System.debug(oldVaAmts);

			// Reset approved flag if any payor amounts changed
			if (d.dtmob__Auto_Grant_Payor__c!=null && accountsMap.get(d.dtmob__Auto_Grant_Payor__c).VA_Agency__c
				&& oldVaAmts.get(d.dtmob__Auto_Grant_Payor__c)!=d.AutoGrant__c) {
				d.VA_Paperwork_Approved__c = false;
			}
			if (d.Third_Party_Pay_1__c!=null && accountsMap.get(d.Third_Party_Pay_1__c).VA_Agency__c
				&& oldVaAmts.get(d.Third_Party_Pay_1__c)!=d.dealer__Deferred_Down_1__c) {
				d.VA_Paperwork_Approved__c = false;
			}
			if (d.Third_Party_Pay_2__c!=null && accountsMap.get(d.Third_Party_Pay_2__c).VA_Agency__c
				&& oldVaAmts.get(d.Third_Party_Pay_2__c)!=d.dealer__Deferred_Down_2__c) {
				d.VA_Paperwork_Approved__c = false;
			}
			if (d.Third_Party_Pay_3__c!=null && accountsMap.get(d.Third_Party_Pay_3__c).VA_Agency__c
				&& oldVaAmts.get(d.Third_Party_Pay_3__c)!=d.dealer__Deferred_Down_3__c) {
				d.VA_Paperwork_Approved__c = false;
			}
			System.debug(d.VA_Paperwork_Approved__c);
		}

		// If the VA Paperwork Approved flag has changed for any reason, set who & when
		if ((oldd!=null && oldd.VA_Paperwork_Approved__c!=d.VA_Paperwork_Approved__c)
			|| (oldd==null && d.VA_Paperwork_Approved__c==true)) {
			d.VA_Paperwork_Approver__c = UserInfo.getUserId();
			d.VA_Paperwork_ApprovalDT__c = DateTime.now();
			System.debug(d.VA_Paperwork_ApprovalDT__c);
		}

	}
	// BLL55 end

	public Decimal nullAsZero(Decimal v) { 
		return v==null ? 0 : v;
	}

	// BLL22a
	//-------------------------------------------------
	public void ProposalCalculations() {
		
		Set<String> VehicleSale = new Set<String>{'Retail Vehicle Sale', 'Chassis/Conversion', 'Wholesale'};

		Map<String, Schema.RecordTypeInfo> DealRcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();
		Schema.RecordTypeInfo CommercialRtInfo = DealRcdTypes.get('Commercial');
		Id CommercialRtId = CommercialRtInfo.getRecordTypeId();

		for(dealer__Deal__c d : newList) {
			// BLL28 - ensure certain fields have values (non-null)
			if (d.dealer__Deposit__c==null) d.dealer__Deposit__c=0;
			if (d.dealer__Down_Pymt__c==null) d.dealer__Down_Pymt__c=0;
			// BLL28a end
			
			// Recalc total fees
			d.dealer__Total_Fees__c = nullAsZero(d.GVW_GVWR__c) + nullAsZero(d.Tire_Fee__c)
				+ nullAsZero(d.Smog_Fee__c) + nullAsZero(d.Smog_Cert__c)
				+ nullAsZero(d.Electronic_Filing_Fee__c) + nullAsZero(d.dealer__Doc_Fee__c)
				+ nullAsZero(d.dealer__License_Fee__c) + nullAsZero(d.Registration_Title_Fee__c)
				+ nullAsZero(d.LeaseAcquisitionFee__c) // BLL28a
				+ nullAsZero(d.dealer__Sales_Tax__c);

			if (d.Chassis_QTY__c==null || d.Chassis_QTY__c==0) d.Chassis_QTY__c = 1;
			// don't skip these! if (!d.AdministrativeUpdate__c) {
			Decimal OutsideFundingMoney = 
					  nullAsZero(d.AutoGrant__c)
					+ nullAsZero(d.dealer__Deferred_Down_1__c)
					+ nullAsZero(d.dealer__Deferred_Down_2__c)
					+ nullAsZero(d.dealer__Deferred_Down_3__c);
			Decimal TradeOA = nullAsZero(d.dealer__Trade_Allowance__c) - nullAsZero(d.Trade_ACV__c);
            Decimal totalSalePrice = 
            		  nullAsZero(d.Chassis_Price__c) + nullAsZero(d.Conversion_Price__c)  
					+ nullAsZero(d.Total_Additional_Equipment__c) 
					+ nullAsZero(d.dealer__Total_Fees__c) 
					+ nullAsZero(d.Total_Protection_Products__c) 
					+ nullAsZero(d.DeliveryFreightAmount__c)
					// BLL49d - (nullAsZero(d.dealer__Trade_Allowance__c) - nullAsZero(d.dealer__Trade_Payoff__c)) 
					- nullAsZero(d.Government_Price_Concession__c)
					- (nullAsZero(d.dealer__Rebate__c) + nullAsZero(d.Rebate_2__c) + nullAsZero(d.Rebate_3__c)) 
					// BLL49d - nullAsZero(d.dealer__Deposit__c) 
					// BLL49d - nullAsZero(d.dealer__Down_Pymt__c)  
					- nullAsZero(d.MBW_Rewards__c)  
					//BLL49d - OutsideFundingMoney 
					- nullAsZero(d.Conversion_Discount__c);
			Decimal totalOEMSalePrice = 
            		  nullAsZero(d.OEM_Chassis_Price__c) + nullAsZero(d.OEM_Conversion_Price__c)  
					+ nullAsZero(d.Total_Additional_Equipment__c) 
					+ nullAsZero(d.dealer__Total_Fees__c) 
					+ nullAsZero(d.Total_Protection_Products__c) 
					+ nullAsZero(d.DeliveryFreightAmount__c)
					// BLL49d - (nullAsZero(d.dealer__Trade_Allowance__c) - nullAsZero(d.dealer__Trade_Payoff__c)) 
					- nullAsZero(d.Government_Price_Concession__c)
					- (nullAsZero(d.dealer__Rebate__c) + nullAsZero(d.Rebate_2__c) + nullAsZero(d.Rebate_3__c)) 
					//BLL49d - nullAsZero(d.dealer__Deposit__c) 
					//BLL49d - nullAsZero(d.dealer__Down_Pymt__c)  
					- nullAsZero(d.MBW_Rewards__c)  
					//BLL49d - OutsideFundingMoney 
					- nullAsZero(d.Conversion_Discount__c);
			Decimal chassisGross =	nullAsZero(d.Chassis_Price__c) - nullAsZero(d.Chassis_Cost__c); 
			//if (d.ReleasingDealer__c!=null) chassisGross = 0;
			System.debug('chassisGross=' + String.valueOf(chassisGross));
            Decimal unitGross =
            		chassisGross 
					+ nullAsZero(d.Conversion_Price__c) -nullAsZero(d.Conversion_Cost__c) 
					+ nullAsZero(d.Total_Additional_Equipment__c) - nullAsZero(d.Total_Internal_Local_Equipment__c)
					+ nullAsZero(d.DeliveryFreightAmount__c) - nullAsZero(d.DeliveryFreightCost__c)
					- nullAsZero(d.GP_Sharing_Amount__c)	// BLL43a
					- nullAsZero(d.Conversion_Discount__c)  
					- nullAsZero(d.LoanAcquisitionCost__c)	// BLL28a
					- TradeOA;
			System.debug('unitGross = Conversion_Price__c('+String.valueOf(d.Conversion_Price__c)+') - Conversion_Cost__c('+String.valueOf(d.Conversion_Cost__c)+')'
					+ ' + Chassis_Price__c('+String.valueOf(d.Chassis_Price__c)+') - Chassis_Cost__c('+String.valueOf(d.Chassis_Cost__c)+')'
					+ ' + Total_Additional_Equipment__c('+String.valueOf(d.Total_Additional_Equipment__c)+') - Total_Internal_Local_Equipment__c('+String.valueOf(d.Total_Internal_Local_Equipment__c)+')'
					+ ' + DeliveryFreightAmount__c('+String.valueOf(d.DeliveryFreightAmount__c)+') - DeliveryFreightCost__c('+String.valueOf(d.DeliveryFreightCost__c)+')'
					+ ' - Conversion_Discount__c('+String.valueOf(d.Conversion_Discount__c)+') - TradeOA('+String.valueOf(TradeOA)+')');
            Decimal unitSalesGross = 
					  chassisGross
            		+ nullAsZero(d.Conversion_Price__c) - nullAsZero(d.Conversion_Cost__c) 
					+ nullAsZero(d.Total_Additional_Equipment__c) - nullAsZero(d.Total_Internal_Local_Equipment__c) 
					+ nullAsZero(d.DeliveryFreightAmount__c) - nullAsZero(d.DeliveryFreightCost__c)  
					- nullAsZero(d.Pack__c)
					- nullAsZero(d.GP_Sharing_Amount__c)	// BLL43a
					- nullAsZero(d.Conversion_Discount__c)  
					- nullAsZero(d.LoanAcquisitionCost__c)	// BLL28a
					- TradeOA;
			System.debug('unitSalesGross is unitGross less pack(' + String.valueOf(d.Pack__c) + ')');
			Decimal oemChassisGross = nullAsZero(d.OEM_Chassis_Price__c) - nullAsZero(d.OEM_Chassis_Cost__c);
			if (d.ReleasingDealer__c!=null) oemChassisGross = 0;
			System.debug('oemChassisGross = ' + String.valueOf(oemChassisGross));
            Decimal oemUnitSalesGross =
            		oemChassisGross 
            		+ nullAsZero(d.OEM_Conversion_Price__c) - nullAsZero(d.OEM_Conversion_Cost__c) 
					+ nullAsZero(d.Total_Additional_Equipment__c) - nullAsZero(d.Total_Internal_Local_Equipment__c) 
					+ nullAsZero(d.DeliveryFreightAmount__c) - nullAsZero(d.DeliveryFreightCost__c)  
					- nullAsZero(d.Pack__c)
					- nullAsZero(d.GP_Sharing_Amount__c)	// BLL43a
					- nullAsZero(d.Conversion_Discount__c)  
					- nullAsZero(d.LoanAcquisitionCost__c)	// BLL28a
					- TradeOA;
			System.debug('oemUnitSalesGross = OEM_Conversion_Price__c('+String.valueOf(d.OEM_Conversion_Price__c)+') - OEM_Conversion_Cost__c('+String.valueOf(d.OEM_Conversion_Cost__c)+')'
					+ ' + OEM_Chassis_Price__c('+String.valueOf(d.OEM_Chassis_Price__c)+') - OEM_Chassis_Cost__c('+String.valueOf(d.OEM_Chassis_Cost__c)+')'
					+ ' + Total_Additional_Equipment__c('+String.valueOf(d.Total_Additional_Equipment__c)+') - Total_Internal_Local_Equipment__c('+String.valueOf(d.Total_Internal_Local_Equipment__c)+')'
					+ ' + DeliveryFreightAmount__c('+String.valueOf(d.DeliveryFreightAmount__c)+') - DeliveryFreightCost__c('+String.valueOf(d.DeliveryFreightCost__c)+')'
					+ ' - Pack('+String.valueOf(d.Pack__c)+')'
					+ ' - GP Sharing('+String.valueOf(d.GP_Sharing_Amount__c)+')'
					+ ' - Conversion_Discount__c('+String.valueOf(d.Conversion_Discount__c)+') - TradeOA('+String.valueOf(TradeOA)+')');

            Decimal tGross = unitGross * d.Chassis_QTY__c;
            tGross = tGross.setScale(2);
            Decimal salesGross = unitSalesGross * d.Chassis_QTY__c;
            salesGross = salesGross.setScale(2);
            Decimal oemSalesGross = oemUnitSalesGross * d.Chassis_QTY__c;
            oemSalesGross = oemSalesGross.setScale(2);

			d.TotalUnitPrice__c = totalSalePrice.setScale(2);
			d.Total_Price__c = d.TotalUnitPrice__c * d.Chassis_QTY__c; 

			// BLLa Skip GP replacement for posted proposals
			if (d.dealer__Status__c!='Won - Posted') {
				d.Total_Proposal_Gross__c = tGross;
            	d.dealer__Front_End_Gross__c = tGross;
            	d.dealer__Back_End_Gross__c = 0;
            	d.dealer__Finance_Gross__c = 0;
            	d.Conversion_Gross__c = nullAsZero(d.Conversion_Price__c) - nullAsZero(d.Conversion_Cost__c);
            	d.Commissionable_Gross__c = salesGross;
            	d.Chassis_Gross__c = nullAsZero(d.Chassis_Price__c) - nullAsZero(d.Chassis_Cost__c);
            //if (d.ReleasingDealer__c!=null) d.Chassis_Gross__c = 0;
            	d.dealer__Aftermarket_Gross__c = nullAsZero(d.Total_Additional_Equipment__c) - nullAsZero(d.Total_Internal_Local_Equipment__c);
            	d.Quoted_Commissionable_GP__c = oemSalesGross;
			}

			// BLL28a lease calcs
			FinanceCalculations(d); 

			// commissions???
			if (d.RecordTypeId==commercialRtId) {
				if (VehicleSale.contains(d.dealer__Deal_Type__c)) CommercialVehicleCommission(d);
				if (!VehicleSale.contains(d.dealer__Deal_Type__c)) NonVehicleCommission(d);
			} else {
				if (VehicleSale.contains(d.dealer__Deal_Type__c)) RetailVehicleCommission(d);
				if (!VehicleSale.contains(d.dealer__Deal_Type__c)) NonVehicleCommission(d);
			}
			
			
			// }
		}
	}
	
	// BLL29a
	public void FinanceCalculations(dealer__Deal__c d) {
        if (d.ChassisResidualPct__c!=null && d.ChassisMSRP__c!=null) {
            d.ChassisResidualAmt__c = d.ChassisResidualPct__c/100 * d.ChassisMSRP__c;
            d.ChassisResidualAmt__c = d.ChassisResidualAmt__c.setScale(2);
        }        
        if (d.ConversionResidualPct__c!=null && d.ConversionMSRP__c!=null) {
            d.ConversionResidualAmt__c = d.ConversionResidualPct__c/100 * d.ConversionMSRP__c;
            d.ConversionResidualAmt__c = d.ConversionResidualAmt__c.setScale(2);
        }        

		// BLL50a
		if (d.ChassisResidualAmt__c==null) d.ChassisResidualAmt__c=0.00;
		if (d.ConversionResidualAmt__c==null) d.ConversionResidualAmt__c=0.00;
		d.Contract_ResidualValue__c = d.ChassisResidualAmt__c + d.ConversionResidualAmt__c;
		d.dealer__Residual_Amt__c = d.ChassisResidualAmt__c + d.ConversionResidualAmt__c;
		// BLL50a end
	
		if (d.TaxOnCostReduction__c==null) d.TaxOnCostReduction__c=0;
		d.TotalOutsideFunding__c = nullAsZero(d.Grants_Government_Assistance__c); // BLL52d + nullAsZero(d.dealer__Deferred_Down_1__c) + nullAsZero(d.dealer__Deferred_Down_2__c) + nullAsZero(d.dealer__Deferred_Down_3__c);
		//BLL49d d.GrossCapitalizedCost__c = nullAsZero(d.Total_Price__c) - (nullAsZero(d.dealer__Down_Pymt__c) + nullAsZero(d.dealer__Deposit__c)) - nullAsZero(d.TotalOutsideFunding__c); 
		d.GrossCapitalizedCost__c = nullAsZero(d.Total_Price__c) - nullAsZero(d.dealer__Down_Pymt__c) - nullAsZero(d.TotalOutsideFunding__c);	// BLL49a
		d.TotalDueUponDelivery__c = nullAsZero(d.Total_Price__c) - nullAsZero(d.TotalOutsideFunding__c)
			- nullAsZero(d.dealer__Deposit__c) - nullAsZero(d.dealer__Down_Pymt__c) 
			- nullAsZero(d.dealer__Trade_Allowance__c) + nullAsZero(d.dealer__Trade_Payoff__c);	// BLLc adj by payoff too
		if (d.Funding_option__c=='Financed') d.TotalDueUponDelivery__c -= nullAsZero(d.Contract_Amount_Financed__c);
		if (d.Funding_option__c=='Financed' && d.Contract_Type__c=='Lease' && d.Contract_Monthly_Payment__c!=null) d.TotalDueUponDelivery__c += d.Contract_Monthly_Payment__c;
		if (d.Contract_Total_of_Payments__c==null && d.Contract_Number_of_Payments__c!=null && d.Contract_Monthly_Payment__c!=null)
			d.Contract_Total_of_Payments__c = d.Contract_Number_of_Payments__c * d.Contract_Monthly_Payment__c;
		d.TotalUpFrontFees__c = nullAsZero(d.dealer__Total_Fees__c);
		//if (d.Contract_Type__c=='Lease') {
			if (d.LeaseAcquisitionFeeHandling__c==null) d.LeaseAcquisitionFeeHandling__c = 'Capitalized';
			if (d.LeaseDocFeeHandling__c==null) d.LeaseDocFeeHandling__c = 'Capitalized';
			if (d.LeaseSalesTaxHandling__c==null) d.LeaseSalesTaxHandling__c = 'Capitalized';
			if (d.LeaseTitleFeeHandling__c==null) d.LeaseTitleFeeHandling__c = 'Capitalized';
			//d.TotalDown__c = ;
			if (d.LeaseSalesTaxHandling__c=='Monthly'	//BLL47c (below additional criteria)
				&& d.TaxOnCostReduction__c!=null && d.LeaseMonthlySalesTax__c!=null) d.dealer__Sales_Tax__c = nullAsZero(d.TaxOnCostReduction__c) + nullAsZero(d.LeaseMonthlySalesTax__c);	// not reported or paid by us
			if (d.LeaseDocFeeHandling__c=='Capitalized') {
				d.TotalUpFrontFees__c -= (nullAsZero(d.Smog_Fee__c) + nullAsZero(d.Smog_Cert__c)
					+ nullAsZero(d.Electronic_Filing_Fee__c) + nullAsZero(d.dealer__Doc_Fee__c)
					+ nullAsZero(d.dealer__License_Fee__c) + nullAsZero(d.Registration_Title_Fee__c)
					);
			}
			if (d.LeaseAcquisitionFeeHandling__c=='Capitalized') d.TotalUpFrontFees__c -= nullAsZero(d.LeaseAcquisitionFee__c);
			if (d.LeaseSalesTaxHandling__c=='Capitalized') d.TotalUpFrontFees__c -= nullAsZero(d.dealer__Sales_Tax__c);
		//} 
		// TaxOnCostReduction__c
		// SalesTaxOverrideAmt__c, SalesTaxOverrideReason__c
	}
	// BLL28a end

	public void CommercialVehicleCommission(dealer__Deal__c deal) {

	}

	public void RetailVehicleCommission(dealer__Deal__c deal) {
		// No more retail vehicle commission calculations
		//Date may_1_2016 = Date.newInstance(2016,5,1);
		//if (deal.Proposed_Delivery_Date__c >= may_1_2016) {
		//	
		//}
	}

	public void NonVehicleCommission(dealer__Deal__c deal) {
		Date may_1_2016 = Date.newInstance(2016,5,1);
		
		Decimal equipMarkup = deal.Total_Additional_Equipment__c!=0 ? (deal.Total_Additional_Equipment__c - deal.Total_Internal_Local_Equipment__c) / deal.Total_Additional_Equipment__c : 0;
		deal.Commission_Rate__c = equipMarkup > 0.3333 ? 20 : 15;
		if (deal.Proposed_Delivery_Date__c >= may_1_2016) deal.Commission_Rate__c = 0;
	}
	// BLL22a end


	//--------------------------------------------------
	public void CreateTradeFromSalesUp() {
		Set<Id> DealUps = new Set<Id>();
		for(dealer__Deal__c d : newList) if (d.dealer__Sales_Lead__c!=null) DealUps.add(d.dealer__Sales_Lead__c);

		User u = CurrentUserSingleton.getInstance();	// BLL39a
		LocationsSingleton ls = LocationsSingleton.getInstance();	// BLL39a
		if (!String.isBlank(u.Division)) ls.addLocationAbbrevs(new Set<String>{u.Division});	// BLL39a

		// BLL22a 
		Set<Id> LocIds = new Set<Id>();
		//BLL39d Map<Id,dealer__Dealer_Location__c> locMap = new Map<Id,dealer__Dealer_Location__c>();
		for(dealer__Deal__c d : newList) if (d.dealer__Store_Location__c!=null) LocIds.add(d.dealer__Store_Location__c);
		// BLL22a end
		ls.addLocationIds(locIds);	// BLL39a
		
		// Add the Trade In to the Proposal
		Map<Id,dealer__Sales_Up__c> salesUps = new Map<Id,dealer__Sales_Up__c>([
			select Id, dealer__Trade_Appraised_Value__c, dealer__Trade_Body_Type__c, dealer__Trade_Comments__c, 
				dealer__Trade_Make__c, dealer__Trade_Mileage__c, dealer__Trade_Model__c, dealer__Trade_Trim_Level__c, 
				dealer__Trade_VIN__c, dealer__Trade_Year__c 
			from dealer__Sales_Up__c 
			where Id in :dealUps
		]);
		//List<dealer__Trade_In__c> tradeIns = new List<dealer__Trade_In__c>();
		Map<Id,dealer__Trade_In__c> trademap = new Map<Id,dealer__Trade_In__c>();	// BLL22a
		Map<Id,dealer__Appraisal__c> aprMap = new Map<Id,dealer__Appraisal__c>();	// BLL22a
		Map<String,dealer__Service_Vehicle__c> svcMap = new Map<String,dealer__Service_Vehicle__c>();	// BLL22a
		// BLL33a
		Set<String> svcVINs = new Set<String>();
		Map<String,dealer__Service_Vehicle__c> svcVINMap = new Map<String,dealer__Service_Vehicle__c>();
		for(dealer__Sales_Up__c sup : salesUps.values()) {
			if (!String.isBlank(sup.dealer__Trade_VIN__c)) svcVINs.add(sup.dealer__Trade_VIN__c);
		}
		for (dealer__Service_Vehicle__c sv : [select Id, dealer__VIN__c from dealer__Service_Vehicle__c where dealer__VIN__c in :svcVINs]) svcVINMap.put(sv.dealer__VIN__c, sv);
		// BLL33a end 
	
		// BLL22a - location map
		//BLL39 location map is handled by LocationsSingleton now
		//BLL39dlocMap = new Map<Id,dealer__Dealer_Location__c>([select Id, Name, Use_Appraisal_Dashboard__c from dealer__Dealer_Location__c where Id in :locIds]);
	
		for(dealer__Deal__c d : newList) {
			dealer__Sales_Up__c up = salesUps.get(d.dealer__Sales_Lead__c);
			//System.debug(up);
		    // Create Trade Record
		    if(up!=null && up.dealer__Trade_Year__c!=null && up.dealer__Trade_Make__c!=null && up.dealer__Trade_Model__c!=null) {
		    	String tradename = up.dealer__Trade_Year__C + ' ' + up.dealer__Trade_Make__c + ' ' + up.dealer__Trade_Model__c;
		    	System.debug(tradename);
			    dealer__Trade_In__c trade = new dealer__Trade_In__c(
			    	dealer__Year__c = up.dealer__Trade_Year__c,
			    	dealer__Make__c = up.dealer__Trade_Make__c,
			    	dealer__Model__c = up.dealer__Trade_Model__c,
			    	dealer__VIN__c = up.dealer__Trade_VIN__c,
			    	dealer__Trade_Allowance__c = 0,
			    	dealer__ACV__c = 0,
			    	Trade_In_Notes__c = up.dealer__Trade_Comments__c,
			    	dealer__Pay_Off_Amount__c = 0,
			    	Name = tradename,
			    	dealer__Odometer_at_Trade_In__c = up.dealer__Trade_Mileage__c,
			    	dealer__Car_Deal__c = d.Id
			    );
			    //insert trade;
			    //BLL22d tradeIns.add(trade);
			    trademap.put(d.Id,trade); 
			    // BLL22a Create appraisal record
			    dealer__Appraisal__c apr = new dealer__Appraisal__c(
			    	dtmob__Deal__c = d.Id,
			    	dtmob__Requested_By__c = UserInfo.getUserId(),
			    	dealer__Sales_Up__c = up.Id,
			    	dealer__Store_Location__c = d.dealer__Store_Location__c,
			    	dealer__Vehicle_Owner__c = d.dealer__Buyer__c
			    );
			    // BLL33a
				dealer__Service_Vehicle__c existingSV = svcVINMap.get(up.dealer__Trade_VIN__c);
				if (existingSV!=null) trade.dealer__Service_Vehicle__c = existingSV.Id;
				else {
				// BLL33a end	
				    dealer__Service_Vehicle__c svc = new dealer__Service_Vehicle__c(
				    	dealer__Veh_Owner__c=d.dealer__Buyer__c,
				    	dealer__Veh_Owner_Contact__c = d.dealer__Buyer_Contact__c,
				    	dealer__VIN__c = up.dealer__Trade_VIN__c,
				    	dealer__Make__c = up.dealer__Trade_Make__c,
				    	dealer__Carline__c = up.dealer__Trade_Model__c,
				    	dealer__Year__c = up.dealer__Trade_Year__c
				    );
				    if (!String.isBlank(svc.dealer__VIN__c)) svcMap.put(d.Id, svc);
				}	// BLL33a
			    //BLL39a dealer__Dealer_Location__c l = locMap.get(d.dealer__Store_Location__c);
			    dealer__Dealer_Location__c l = ls.getLocationById(d.dealer__Store_Location__c);	// BLL39a
			    if (l!=null && l.Use_Appraisal_Dashboard__c) aprMap.put(d.Id, apr);
			    // BLL22a end
			}
		}
		// BLL22d if (tradeIns.size()>0) insert(tradeIns);
		// BLL22a 
		if (svcMap.values().size()>0) Database.insert(svcMap.values(), false);
		// BLL33a - link service vehicle to trade records
		for(dealer__Deal__c d : newList) {
			dealer__Sales_Up__c up = salesUps.get(d.dealer__Sales_Lead__c);
			dealer__Service_Vehicle__c sv = up!=null ? svcVINMap.get(up.dealer__Trade_VIN__c) : null;	
			//System.debug(sv);
			if (sv==null) sv = (svcMap.containsKey(d.Id)) ? svcMap.get(d.Id) : null; 
			//System.debug(sv);
			if (sv!=null && trademap.containsKey(d.Id)) {
				dealer__Trade_In__c t = trademap.get(d.Id);
				if (t!=null && sv!=null) t.dealer__Service_Vehicle__c = sv.Id;
				//System.debug(t);
			}
		}
		// BLL33a
		//System.debug(trademap);
		if (trademap.values().size()>0) insert(trademap.values());
		List<dealer__Appraisal__c> appraisals = new List<dealer__Appraisal__c>();
		for (dealer__Deal__c d : newlist) {
			dealer__Trade_In__c t = trademap.get(d.Id);
			//BLL33d unnecessary - use trade rcd: dealer__Service_Vehicle__c s = svcMap.get(d.Id);
			dealer__Appraisal__c a = aprmap.get(d.Id);
			if (t!=null && a!=null) {
				a.dtmob__Trade_In__c = t.Id;
				a.dealer__Service_Vehicle__c = t.dealer__Service_Vehicle__c;	// BLL33c 
				appraisals.add(a);
			}
		}
		if (appraisals.size()>0) insert(appraisals);
		// BLL22a end
	}

	//--------------------------------------------------
	public void DeleteProtection() {
		User u = CurrentUserSingleton.getInstance();
		for(dealer__Deal__c deal : oldMap.values()) {
			if (u.Profile.Name!='System Administrator') deal.addError('Only System Administrators can delete proposals.');
		}
	}

	// ProcessStatusChange() -- unused
	public void ProcessStatusChange(){}
	
	// BLL39a
	// ProposalESCStatus - update ESC status based on proposal being delivered (or backed out)
	//---------------------------------------------------
	public void ProposalESCStatus() {
		MonitorExecution mon = new MonitorExecution('ProposalESCStatus');	// BLL39a
		System.debug('ProposalESCStatus');	// BLL39a
		Set<Id> DealEscActive = new Set<Id>(); 
		Set<Id> DealEscInactive = new Set<Id>();

		Map<Id,dealer__Vehicle_Inventory__c> vMap = getVehicleInvMap();	// BLL34a

		for(dealer__Deal__c deal : newList) {
			dealer__Deal__c olddeal = oldMap!=null ? oldMap.get(deal.Id) : null;
			boolean statuschgd = olddeal!=null && deal.dealer__Status__c!=olddeal.dealer__Status__c;

       		dealer__Vehicle_Inventory__c veh = deal.dealer__Vehicle__c!=null ? vMap.get(deal.dealer__Vehicle__c) : null; 
			
			if (statuschgd && deliveredStatus.contains(deal.dealer__Status__c)) DealEscActive.add(deal.Id);
			else if (statuschgd && !deliveredStatus.contains(deal.dealer__Status__c)) DealEscInactive.add(deal.Id); 
		}
		mon.log('Delivered proposals: ' + JSON.serialize(DealEscActive));			
		mon.log('Undelivered proposals: ' + JSON.serialize(DealEscInactive));			
		
		// Update ESC status, customer, start date, odometer
		List<dealer__Service_Contract__c> updescs = new List<dealer__Service_Contract__c>();
		Set<Id> dealids = new Set<Id>();
		dealids.addAll(DealEscActive);
		dealids.addAll(DealEscInactive);
		for(dealer__Service_Contract__c esc : [
			select Id, dealer__Status__c, dealer__Car_Deal__c, dealer__Car_Deal__r.Proposed_Delivery_Date__c, 
				dealer__Car_Deal__r.dealer__Mileage__c, dealer__Car_Deal__r.dealer__Buyer__c,  
				dealer__Odometer_at_Sale__c, dealer__Expiration_Mileage__c, dealer__Expiration_Months__c,
				dealer__Car_Deal__r.dealer__Vehicle__c, dealer__Car_Deal__r.dealer__Vehicle__r.dealer__Service_Vehicle__c, 
				dealer__Car_Deal__r.dealer__Service_Vehicle__c
			from dealer__Service_Contract__c
			where (dealer__Car_Deal__c in :DealEscActive and dealer__Status__c!='Active')
			   or (dealer__Car_Deal__c in :DealEscInactive and dealer__Status__c='Active')
		]) {
			Id srvVehId = null;
        	if (esc.dealer__Car_Deal__r.dealer__Vehicle__c!=null && esc.dealer__Car_Deal__r.dealer__Vehicle__r.dealer__Service_Vehicle__c!=null) srvVehId = esc.dealer__Car_Deal__r.dealer__Vehicle__r.dealer__Service_Vehicle__c;	// BLL39a
        	if (esc.dealer__Car_Deal__r.dealer__Vehicle__c==null && esc.dealer__Car_Deal__r.dealer__Service_Vehicle__c!=null) srvVehId = esc.dealer__Car_Deal__r.dealer__Service_Vehicle__c;	// BLL39a
			dealer__Service_Contract__c updesc = new dealer__Service_Contract__c(
				Id=esc.Id,
				dealer__Status__c=(DealEscActive.contains(esc.dealer__Car_Deal__c) ? 'Active' : null),
				dealer__Odometer_at_Sale__c = esc.dealer__Car_Deal__r.dealer__Mileage__c,
				dealer__Customer__c = esc.dealer__Car_Deal__r.dealer__Buyer__c,
				dealer__Start_Date__c = esc.dealer__Car_Deal__r.Proposed_Delivery_Date__c,
				dealer__Service_Vehicle__c = srvVehId	// BLL39a
			);
			updescs.add(updesc);
			mon.log('Update ESC: ' + JSON.serialize(updesc));	// BLL39a
			System.debug(updesc);	// BLL39a
		}
		if (updescs.size()>0) update(updescs);
		if (mon.AlwaysNotify) mon.notifyAdmin();
	}

	// Update service vehicle ownership based on proposal being delivered (or backed out)
	//-------------------------------------------------------
	public void ProposalVehicleOwner() {
		MonitorExecution mon = new MonitorExecution('ProposalVehicleOwner');	// BLL39a
		mon.log('ProposalVehicleOwner');	// BLL39a
		System.debug('ProposalVehicleOwner');	// BLL39a
		//Set<Id> DealDelivered = new Set<Id>(); 
		//Set<Id> DealUnDelivered = new Set<Id>();
		Map<Id, dealer__Service_Vehicle__c> updsrvvehmap = new Map<Id,dealer__Service_Vehicle__c>();

		Map<Id,dealer__Vehicle_Inventory__c> vMap = getVehicleInvMap();	
		Map<Id,dealer__Deal__c> dealtrademap = getDealTradeInsAndOwners();	

		for(dealer__Deal__c d : dealtrademap.values()) {
			// only do this if the deal status changed
			dealer__Deal__c olddeal = oldMap!=null ? oldMap.get(d.Id) : null;
			boolean statuschgd = olddeal!=null && d.dealer__Status__c!=olddeal.dealer__Status__c;
			
			if (statuschgd
				&& (deliveredStatus.contains(d.dealer__Status__c) || deliveredStatus.contains(olddeal.dealer__Status__c))) {

				mon.log('Delivered status changed for deal ' + d.Name);	//BLL 39a
				System.debug('Delivered status changed for deal ' + d.Name);	//BLL 39a
			
				// change owner of service vehicle related to proposal
				// delivered vehicle becomes owned by buyer 
				if (deliveredStatus.contains(d.dealer__Status__c)
					&& !deliveredStatus.contains(olddeal.dealer__Status__c) 
					&& d.dealer__Service_Vehicle__c!=null 
					&& d.dealer__Service_Vehicle__r.dealer__Veh_Owner__c!=d.dealer__Buyer__c) {
					dealer__Service_Vehicle__c updsv = new dealer__Service_Vehicle__c(
						Id=d.dealer__Service_Vehicle__c,
						dealer__Veh_Owner__c = d.dealer__Buyer__c,
						dealer__Veh_Owner_Contact__c = d.dealer__Buyer_Contact__c
					);
					updsrvvehmap.put(d.dealer__Service_Vehicle__c, updsv);
					mon.log('Delivered -- set proposal vehicle owner to client: ' + JSON.serialize(updsv));	// BLL39a
					System.debug('Delivered -- set proposal vehicle owner to client: ' + d.Name);	// BLL39a
				}
				// undelivered deal becomes owned by MW store
				if (!deliveredStatus.contains(d.dealer__Status__c)
					&& deliveredStatus.contains(olddeal.dealer__Status__c) 
					&& d.dealer__Service_Vehicle__c!=null 
					&& d.dealer__Service_Vehicle__r.dealer__Veh_Owner__c!=d.dealer__Store_Location__r.dealer__Location_Account__c) {
					dealer__Service_Vehicle__c updsv = new dealer__Service_Vehicle__c(
						Id=d.dealer__Service_Vehicle__c,
						dealer__Veh_Owner__c = d.dealer__Store_Location__r.dealer__Location_Account__c,
						dealer__Veh_Owner_Contact__c = null
					);					
					updsrvvehmap.put(d.dealer__Service_Vehicle__c, updsv);
					mon.log('Undelivered -- set proposal vehicle owner to store: ' + JSON.serialize(updsv));	// BLL39a
					System.debug('Undelivered -- set proposal vehicle owner to store: ' + d.Name);	// BLL39a
				}
			
				// update trade-in owners
				//BLL41d for(dealer__Trade_In__c t : d.dealer__Trade_Ins__r) {
				//BLL41d 	// change owner of service vehicle related to proposal
				//BLL41d 	// delivered vehicle becomes owned by MW 
				//BLL41d 	if (t.dealer__Service_Vehicle__c!=null 
				//BLL41d 		&& deliveredStatus.contains(d.dealer__Status__c)
				//BLL41d 		&& !deliveredStatus.contains(olddeal.dealer__Status__c) 
				//BLL41d 		&& t.dealer__Service_Vehicle__c!=null) {
				//BLL41d 		dealer__Service_Vehicle__c updsv = new dealer__Service_Vehicle__c(
				//BLL41d 			Id=t.dealer__Service_Vehicle__c,
				//BLL41d 			dealer__Veh_Owner__c = d.dealer__Store_Location__r.dealer__Location_Account__c,
				//BLL41d 			dealer__Veh_Owner_Contact__c = null
				//BLL41d 		);
				//BLL41d 		updsrvvehmap.put(t.dealer__Service_Vehicle__c, updsv);
				//BLL41d 		mon.log('Delivered -- set trade-in owner to store: ' + JSON.serialize(updsv));	// BLL39a
				//BLL41d 		System.debug('Delivered -- set trade-in owner to store: ' + d.Name);	// BLL39a
				//BLL41d 	}
				//BLL41d 	// undelivered deal becomes owned by Buyer
				//BLL41d 	if (t.dealer__Service_Vehicle__c!=null 
				//BLL41d 		&& !deliveredStatus.contains(d.dealer__Status__c)
				//BLL41d 		&& deliveredStatus.contains(olddeal.dealer__Status__c) 
				//BLL41d 		&& d.dealer__Service_Vehicle__c!=null) {
				//BLL41d 		dealer__Service_Vehicle__c updsv = new dealer__Service_Vehicle__c(
				//BLL41d 			Id=t.dealer__Service_Vehicle__c,
				//BLL41d 			dealer__Veh_Owner__c = d.dealer__Buyer__c,
				//BLL41d 			dealer__Veh_Owner_Contact__c = d.dealer__Buyer_Contact__c
				//BLL41d 		);
				//BLL41d 		updsrvvehmap.put(t.dealer__Service_Vehicle__c, updsv);
				//BLL41d 		mon.log('Undelivered -- set trade-in vehicle owner to client: ' + JSON.serialize(updsv));	// BLL39a
				//BLL41d 		System.debug('Undelivered -- set trade-in owner to client: ' + d.Name);	// BLL39a
				//BLL41d 	}
				//BLL41d }
				
			} 
			
		}			
		
		// Update ESC status, customer, start date, odometer
		System.debug('Updating service vehicle owners');
		if (updsrvvehmap.size()>0) update(updsrvvehmap.values());
		mon.log('Service vehicle update: ' + JSON.serialize(updsrvvehmap));
		if (mon.AlwaysNotify) mon.notifyAdmin();		
	}
	
	// Get trade-ins and associated service vehicles for deals
	//-------------------------------------------------------
	Map<Id,dealer__Deal__c> getDealTradeInsAndOwners() {
		if (dealTradesMap!=null) return dealTradesMap;	// no need to query multiple times in one request cycle
		
		Set<Id> dealIds = new Set<Id>();
		for(dealer__Deal__c d : newlist) dealIds.add(d.Id);
		
		// Map of deals with all associated trade-ins
		Map<Id,dealer__Deal__c> dealMap = new Map<Id,dealer__Deal__c>([
			select Id, Name, dealer__Status__c, dealer__Buyer__c, dealer__Buyer_Contact__c,  
				dealer__Store_Location__c, dealer__Store_Location__r.dealer__Location_Account__c,  
				dealer__Vehicle__c, dealer__Vehicle__r.dealer__Service_Vehicle__c,
				dealer__Vehicle__r.dealer__Service_Vehicle__r.dealer__Veh_Owner__c, dealer__Vehicle__r.dealer__Service_Vehicle__r.dealer__Veh_Owner_Contact__c, 
				dealer__Service_Vehicle__c, dealer__Service_Vehicle__r.dealer__Veh_Owner__c, dealer__Service_Vehicle__r.dealer__Veh_Owner_Contact__c, 
				(	select Id, Name, dealer__VIN__c, dealer__Service_Vehicle__c
					from dealer__Trade_Ins__r
				)
			from dealer__Deal__c 
			where Id in :dealIds
		]);
		
		// Get list of trade-in VINs (used to get related service vehicles)
		Set<String> tradeVINs = new Set<String>();
		for(dealer__Deal__c d : dealMap.values()) {
			for(dealer__Trade_In__c t : d.dealer__Trade_Ins__r) tradeVINs.add(t.dealer__VIN__c);
		}
		
		// Get referenced service vehicles
		Map<String, dealer__Service_Vehicle__c> srvVinMap = new Map<String,dealer__Service_Vehicle__c>();
		for(dealer__Service_Vehicle__c sv : [
			select Id, Name, dealer__VIN__c 
			from dealer__Service_Vehicle__c 
			where dealer__VIN__c in :tradeVINs
		]) srvVinMap.put(sv.dealer__VIN__c, sv);		
		
		// Fill in service vehicle reference on trade-ins for proposals & generate dealTradesMap
		dealTradesMap = new Map<Id,dealer__Deal__c>();
		for(dealer__Deal__c d : dealMap.values()) {
			// fill in trade-in related service vehicles (only transient, not updating the trade-in records)
			for(dealer__Trade_In__c t : d.dealer__Trade_Ins__r) {
				dealer__Service_Vehicle__c sv = srvVinMap.get(t.dealer__VIN__c);
				if (sv!=null) t.dealer__Service_Vehicle__c = sv.Id;
			}
			// fill in missing service vehicle link (only transient, not updating the proposal with this)
			if (d.dealer__Service_Vehicle__c==null && d.dealer__Vehicle__c!=null && d.dealer__Vehicle__r.dealer__Service_Vehicle__c!=null)
				d.dealer__Service_Vehicle__c = d.dealer__Vehicle__r.dealer__Service_Vehicle__c;
			dealtradesMap.put(d.Id, d);
		}
		
		return dealTradesMap;
	}	
	// BLL39a end 

	//--------------------------------------------------
	public void StatusChangeValidation() {
		MW_TriggerControls__c DealStatusValidation = MW_TriggerControls__c.getInstance('DealStatusValidation');	// BLL20a
		MW_TriggerControls__c DealQuoteValidation = MW_TriggerControls__c.getInstance('DealQuoteValidation');	// BLL20a
		MW_TriggerControls__c DealPayorValidation = MW_TriggerControls__c.getInstance('DealPayorValidation');	// BLL37a
		MW_TriggerControls__c DealDuplicateStockSale = MW_TriggerControls__c.getInstance('DealDuplicateStockSale');	// BLL45a
		
		Set<String> closedRoSts = new Set<String>{'Posted', 'Void'};  // BLL3a	BLL8c only Posted & Void (rmv Invoiced & Cashier)
		Set<String> vehicleSaleTypes = new Set<String>{'Retail Vehicle Sale', 'Wholesale', 'Chassis/Conversion'};  // BLL16a, BLL22c add Chassis/Conversion
		Set<String> serviceVehSaleTypes = new Set<String>{'Financial Products'};	// BLL40a
		Set<String> vehicleRequiredSts = new Set<String>{'Won - F&I', 'Won - Production', 'Won - Delivery', 'Won - Delivered'};	// BLL16a
		Set<String> noApptNeeded = new Set<String>{'DME/Other', 'DME_Other', 'Financial Products', 'Financial_Products'};
		Set<Id> LostDeaLIds = new Set<Id>();	// BLL42a
		boolean isCommercial = false;
		Map<Id, Schema.RecordTypeInfo> DealRcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosById();
		Set<Id> wonSolOpps = new Set<Id>();	// BLL17a

		// BLL15a
		//BLL34d Set<Id> vehIds = new Set<Id>();
		for(dealer__Deal__c deal : newList) {
			//BLL34d if (deal.dealer__Status__c!=null && deal.dealer__Status__c=='Won - Delivered' && deal.dealer__Vehicle__c!=null) vehIds.add(deal.dealer__Vehicle__c);
			if (deal.dealer__Status__c!=null && deal.dealer__Status__c.startsWith('Won') && deal.dealer__Sales_Lead__c!=null) wonSolOpps.add(deal.dealer__Sales_Lead__c);	// BLL17a
		}
		//BLL34d Map<Id,dealer__Vehicle_Inventory__c> vehMap = new Map<Id,dealer__Vehicle_Inventory__c>();
		//BLL34d if (vehIds.size()>0) vehMap = new  Map<Id,dealer__Vehicle_Inventory__c>([select Id, Name, dealer__Store_Location__c, dealer__Store_Location__r.Name from dealer__Vehicle_Inventory__c where Id in :vehIds]);
		Map<Id,dealer__Vehicle_Inventory__c> vMap = getVehicleInvMap();	// BLL34a
		Map<Id,dealer__Finance_Company__c> FinCompMap = getFinanceCompanyMap();	// BLL63

		// BLL15a end
		// BLL17a
		Map<Id,dealer__Sales_Up__c> soloppMap = new Map<Id,dealer__Sales_Up__c>();
		if (wonsolOpps.size()>0) soloppMap = new Map<Id,dealer__Sales_Up__c>([select Id, dealer__Lead_Status__c, dealer__First_Store_Visit_Date__c, dealer__In_Store__c from dealer__Sales_Up__c where Id in :wonsolOpps]);
		// BLL17a end	

		for(dealer__Deal__c deal : newList) {
			dealer__Deal__c olddeal = oldMap!=null ? oldMap.get(deal.Id) : null;
			boolean statuschgd = olddeal!=null && deal.dealer__Status__c!=olddeal.dealer__Status__c;

			System.debug(deal.RecordTypeId);	// BLL22a
			Schema.RecordTypeInfo dealRtInfo = DealRcdTypes.get(deal.RecordTypeId);	// BLL22a
			isCommercial = dealRtInfo!=null && dealRtInfo.getName()=='Commercial';	// BLL22a
			System.debug(dealRtInfo);	// BLL22a

			// BLL45a
			if (statuschgd && deal.dealer__Status__c!=null && deal.dealer__Status__c.startsWith('Won')
				&& deal.dealer__Sales_Tax__c<0) {
				deal.addError('You cannot approve a proposal with negative sales tax.');
			}
			// BLL45a end

			// BLL66
			if (statuschgd && deal.dealer__Status__c=='Won - Deposit' && deal.Submit_Date__c==null)  {
				deal.Submit_Date__c = Date.today();
			}
			// BLL66 end

			// BLL42a - Lost proposals
			if (deal.dealer__Status__c=='Lost' && olddeal!=null && statuschgd) LostDealIds.add(deal.Id);
			// BLL42a end

			// BLL21a - Require Funding_option 
			if (statuschgd && olddeal.dealer__Status__c=='Won - GM Approval' && deal.dealer__Status__c!='Pending') {	// BLL44c - allow rejection w/out funding option
				if (deal.Funding_option__c==null) deal.addError('Funding Option is required before GM approval'); 
			}
			// BLL21a end 
			
			// BLL37a
			// BLL62 - also exclude won-deposit due to error not being displayed on submitting the proposal for approval but
			// does work when approving.
			//if (deal.dealer__Status__c!=null && deal.dealer__Status__c.startsWith('Won') && deal.dealer__Status__c!='Won - Posted' 
			if (deal.dealer__Status__c!=null && deal.dealer__Status__c.startsWith('Won') && deal.dealer__Status__c!='Won - Posted' && deal.dealer__Status__c!='Won - Deposit'
				&& (DealPayorValidation==null || DealPayorValidation.Enabled__c==true) && !deal.AdministrativeUpdate__c) {
				if (deal.dtmob__Auto_Grant_Payor__c==null && deal.AutoGrant__c!=null && deal.AutoGrant__c!=0) 
					deal.addError('Auto Grant payor is required if there is an amount specified.');
				if (deal.dtmob__Auto_Grant_Payor__c!=null && (deal.AutoGrant__c==null || deal.AutoGrant__c==0)) 
					deal.addError('Auto Grant amount is required if there is a payor specified.');

				if (deal.Third_Party_Pay_1__c==null && deal.dealer__Deferred_Down_1__c!=null && deal.dealer__Deferred_Down_1__c!=0) 
					deal.addError('Third party payor is required if there is an amount specified.');
				if (deal.Third_Party_Pay_1__c!=null && (deal.dealer__Deferred_Down_1__c==null || deal.dealer__Deferred_Down_1__c==0)) 
					deal.addError('Third party/Other amount is required if there is a payor specified.');

				if (deal.Third_Party_Pay_2__c==null && deal.dealer__Deferred_Down_2__c!=null && deal.dealer__Deferred_Down_2__c!=0) 
					deal.addError('Third party/Other payor is required if there is an amount specified.');
				if (deal.Third_Party_Pay_2__c!=null && (deal.dealer__Deferred_Down_2__c==null || deal.dealer__Deferred_Down_2__c==0)) 
					deal.addError('Third party/Other amount is required if there is a payor specified.');

				if (deal.Third_Party_Pay_3__c==null && deal.dealer__Deferred_Down_3__c!=null && deal.dealer__Deferred_Down_3__c!=0) 
					deal.addError('Third party payor is required if there is an amount specified.');
				if (deal.Third_Party_Pay_3__c!=null && (deal.dealer__Deferred_Down_3__c==null || deal.dealer__Deferred_Down_3__c==0)) 
					deal.addError('Third party/Other amount is required if there is a payor specified.');
			}
			// BLL37a end

			// BLL59d
			// BLL14a reset F&I contract status when entering step
			//if (deal.dealer__Status__c=='Won - F&I' && olddeal!=null && olddeal.dealer__Status__c=='Won - GM Approval') 
			//	deal.Contract_Status__c = (deal.Credit_Application_Received__c==null) ? null : 'Application Received'; 
			// BLL59d end

			// BLL22a - Order required if ordering a conversion build
			if (deal.dealer__Deal_Type__c=='Chassis/Conversion' && deal.dealer__Status__c!='Pending' && deal.dealer__Status__c!='Lost' 
				&& deal.Commercial_Quote__c==null && deal.Vehicle_Source__c!='Inventory')
					if (isCommercial)	// BLL26a relax restriction on retail (not using conversion builds yet)
	    				deal.addError('Conversion build order is required if not selling from existing inventory');	// BLL20c
				
			// BLL22a - Push past order status automatically (if not ordering a chassis/conversion)
			//if (deal.dealer__Status__c=='Won - Order' && olddeal!=null && olddeal.dealer__Status__c!=deal.dealer__Status__c)
			//	if (deal.dealer__Deal_Type__c!='Chassis/Conversion' || (deal.Vehicle_Source__c!='Order' && deal.Vehicle_Source__c!='Customer Owned')) deal.dealer__Status__c='Won - F&I';
			//if (deal.dealer__Status__c=='Won - Ordered' && olddeal!=null && olddeal.dealer__Status__c!=deal.dealer__Status__c)
			//	if (deal.dealer__Deal_Type__c!='Chassis/Conversion' || (deal.Vehicle_Source__c!='Order' && deal.Vehicle_Source__c!='Customer Owned')) deal.dealer__Status__c='Won - F&I';
			if (statuschgd && deal.dealer__Status__c=='Won - Order')
				if (deal.dealer__Deal_Type__c!='Chassis/Conversion' || deal.Vehicle_Source__c=='Inventory' || deal.Commercial_Quote__c==null) deal.dealer__Status__c='Won - F&I';
			if (statuschgd && deal.dealer__Status__c=='Won - Ordered')
				if (deal.dealer__Deal_Type__c!='Chassis/Conversion' || deal.Vehicle_Source__c=='Inventory' || deal.Commercial_Quote__c==null) deal.dealer__Status__c='Won - F&I';

			// Push past F&I automatically
			if (deal.dealer__Status__c=='Won - F&I' && olddeal!=null /* BLL22d && olddeal.dealer__Status__c=='Won - GM Approval' */)  {
				if (deal.Funding_option__c!='Financed') deal.dealer__Status__c='Won - Production';	// BLL21a
				//BLL21d if (deal.Contract_CustomerArranged__c==true || deal.dealer__Deal_Type__c!='Retail Vehicle Sale') deal.dealer__Status__c='Won - Production';
				if (deal.Credit_Application_Status__c=='Delivered') deal.dealer__Status__c='Won - Production';	// BLL59
				// BLL63
				if (deal.dealer__Finance_Institution_Account__c!=null) {
					dealer__Finance_Company__c fia = FinCompMap.get(deal.dealer__Finance_Institution_Account__c);
					if (fia!=null && fia.Store_Financing__c==true) deal.dealer__Status__c='Won - Production';
				}
				// BLL63 end
			}

			// BLL59d
			// BLL14a set approval date/time if moving on & has a finance institution and not client-supplied
			//if (deal.dealer__Status__c=='Won - Production' && olddeal!=null && (olddeal.dealer__Status__c=='Won - F&I' || olddeal.dealer__Status__c=='Won - GM Approval')) 
			//	deal.Contract_Status__c = (deal.dealer__Finance_Institution_Account__c==null || deal.Credit_Application_Received__c==null || deal.Funding_option__c=='Cash') ? deal.Contract_Status__c : 'Approved'; 
				// BLL21d deal.Contract_Status__c = (deal.dealer__Finance_Institution_Account__c==null || deal.Credit_Application_Received__c==null || deal.Contract_CustomerArranged__c) ? deal.Contract_Status__c : 'Approved';
			// BLL59d end

			// BLL38a - skip delivery confirmation if drop-shipped to customer/other recipient
			//System.debug(deal.dealer__Status__c);
			//if (olddeal!=null) System.debug(olddeal.dealer__Status__c);
			//System.debug(deal.dealer__Deal_Type__c);
			//System.debug(deal.Deliver_to__c);
			if (deal.dealer__Status__c=='Won - Delivery' && olddeal!=null && olddeal.dealer__Status__c!='Won - Delivered'
				&& deal.dealer__Deal_Type__c=='DME/Other' && deal.Deliver_to__c!=null && (deal.Deliver_to__c=='Customer' || deal.Deliver_to__c=='Other address')) {
				deal.dealer__Status__c = 'Won - Delivered';
			}
			if (deal.dealer__Status__c=='Won - Delivery' && olddeal!=null && olddeal.dealer__Status__c=='Won - Delivered'
				&& deal.dealer__Deal_Type__c=='DME/Other' && deal.Deliver_to__c!=null && (deal.Deliver_to__c=='Customer' || deal.Deliver_to__c=='Other address')) {
				deal.dealer__Status__c = 'Won - Production';
			}
			
			// Protections against moving forward when all our ducks aren't in a row yet!
        	// Prevent Won - Delivered if related RO is not closed!
        	if (deal.dealer__Status__c == 'Won - Delivery' && olddeal!=null && olddeal.dealer__Status__c != 'Won - Delivery' && olddeal.dealer__Status__c!='Won - Delivered') {	// BLL9c, BLL14c Won-Delivered
        		System.debug('old deal=' + olddeal.dealer__Status__c + '; new=' + deal.dealer__Status__c + '; drosts=' + deal.dealer__DeliveryRepairOrderStatus__c);	// BLL20c
        		if (deal.dealer__DeliveryRepairOrder__c!=null && !closedRoSts.contains(deal.dealer__DeliveryRepairOrderStatus__c)) deal.addError('Delivery Repair Order must be closed before moving from production to delivery');	// BLL9c, BLL20c
        	     //RT1            
        	    else if(deal.Open_Service_Repair_Orders__c != 0) deal.addError('The vehicle for this proposal has an open repair order');
        	}

			// BLL56 - If a VA deal is approved from production and VA paperwork hasn't been approved, pause for va paperwork approval
			//if (deal.dealer__Status__c == 'Won - Delivery' && deal.VA_Deal__c && !deal.VA_Paperwork_Approved__c) {
			//	deal.dealer__Status__c = 'Won - VA Paperwork';
			//}
			// BLL56 end

			// BLL58a - prevent pushing deals with delivery over 180 days old or over 330 days future
			// exception is to allow a vehicle to be delivered & posted after-the-fact
			if (olddeal!=null && olddeal.dealer__Status__c!=deal.dealer__Status__c 
				&& deal.dealer__Status__c.startsWith('Won') && isMovingForward(olddeal.dealer__Status__c, deal.dealer__Status__c)) {
				if (deal.Proposed_Delivery_Date__c<Date.today().addDays(-180) && !deal.AdministrativeUpdate__c) {
					  deal.addError('Cannot push a proposal this far past due. Check your proposed delivery date: ' + deal.Proposed_Delivery_Date__c.format()+'!');
				}
				if (deal.Proposed_Delivery_Date__c>Date.today().addDays(330) && !deal.AdministrativeUpdate__c) {
					  deal.addError('Cannot push a proposal nearly a year in the future. Check your proposed delivery date: ' + deal.Proposed_Delivery_Date__c.format()+'!');
				}
			}
			// BLL58 end

        	// BLL5a - prevent changing status to 'Won-*' if tax hasn't been calculated yet
        	if (deal.dealer__Status__c!=null && deal.dealer__Status__c.startsWith('Won') && olddeal!=null && olddeal.dealer__Status__c!=null && !olddeal.dealer__Status__c.startsWith('Won')) {
			 	MW_TriggerControls__c AvataxDeal = MW_TriggerControls__c.getInstance('AvataxDeal');  // BLL5a
        		if (deal.TaxCalcDT__c==null && (AvataxDeal==null || AvataxDeal.Enabled__c)) deal.addError('Tax calculation has not been run for this deal yet');
        	}
        	// BLL5a end
    		// BLL16a - require a vehicle for retail vehicle sales and wholesale
    		if (vehicleSaleTypes.contains(deal.dealer__Deal_Type__c) && deal.dealer__Vehicle__c==null && vehicleRequiredSts.contains(deal.dealer__Status__c)) {
    			if ((DealStatusValidation==null || DealStatusValidation.Enabled__c) && !deal.AdministrativeUpdate__c) 
    				deal.addError('You must assign a vehicle inventory record to Retail and wholesale proposals prior to F&I, production and delivery');	// BLL20c
    		}
	   		// BLL16a end
    		// BLL40a - require a service vehicle for financial products sales
    		if (serviceVehSaleTypes.contains(deal.dealer__Deal_Type__c) && deal.dealer__Service_Vehicle__c==null && vehicleRequiredSts.contains(deal.dealer__Status__c)) {
    			if ((DealStatusValidation==null || DealStatusValidation.Enabled__c) && !deal.AdministrativeUpdate__c) 
    				deal.addError('You must assign a customer vehicle record to the proposal prior to F&I, production and delivery');
    		}
	   		// BLL40a end
   			// BLL22a - chassis qty must be 1 at this point too!
   			if (vehicleSaleTypes.contains(deal.dealer__Deal_Type__c) && vehicleRequiredSts.contains(deal.dealer__Status__c) && deal.Chassis_QTY__c!=null && deal.Chassis_QTY__c!=1
   				 && !deal.AdministrativeUpdate__c)
   				deal.addError('Proposal must be for a SINGLE unit (Qty=1) before pushing to production');	
   			// BLL22a end
			// BLL18a - ensure proposal was saved prior to being pushed to Delivered status (at least within last 10 seconds)
			if (deal.dealer__Status__c=='Won - Delivered' && olddeal!=null && olddeal.dealer__Status__c!=deal.dealer__Status__c && olddeal.dealer__Status__c!='Won - Posted') {
				// BLL22 - record commissionable GP at time of delivery
				deal.Delivered_Commissionable_GP__c = deal.Commissionable_Gross__c;	// BLL22a
				Long TooManySeconds = 8000;	// 8 seconds = 8000 milliseconds
				Long ls = deal.LastSavedDT__c!=null ? deal.LastSavedDT__c.getTime() : 0;
				Long lm = deal.LastModifiedDate!=null ? deal.LastModifiedDate.getTime() : ls;	// BLL19c
				// Ignore single seconds difference - maybe between setting LastSavedDT__c in the controller and the final database commit could take a fraction of a second
				if (lm-ls > TooManySeconds  && !deal.AdministrativeUpdate__c) {	
					deal.addError('You must SAVE the proposal before pushing to delivered status to ensure all GP calculations are up-to-date.');
				}
				// BLL51a
		        if (deal.Funding_option__c=='Financed' && (deal.Contract_Amount_Financed__c==0 || deal.Contract_Amount_Financed__c==null)) {
					deal.addError('Funding option is "Financed" but amount financed is $0');
        		}
		        if (deal.Funding_option__c=='Financed' && deal.Contract_Type__c=='Lease' && (deal.Contract_Monthly_Payment__c==null || deal.Contract_Monthly_Payment__c==0)) {
					deal.addError('Proposal is Financed under a lease, but the contract monthly payment is $0');
        		}
        		if (deal.Funding_option__c=='Financed' && deal.dealer__Finance_Institution_Account__c==null) {
					deal.addError('Proposal is Financed, but no Lender (financial institution) is specified in the F&I section.');
        		}
		        if (deal.Funding_option__c=='Financed' && deal.Contract_Type__c=='Lease'
		        	&& (deal.dealer__Deposit__c==0 || deal.dealer__Deposit__c==null)
        			&& (deal.TotalDueUponDelivery__c<=0)) {
					deal.addError('Lease first payment (deposit) is $0, but amount due is $0 or less (adj cap cost is too high)');
        		}
				// BLL51a end
			} 
			// BLL18a end
        	// Won-delivered
        	if (deal.dealer__Status__c=='Won - Delivered') {
        		// BLL15a - Don't allow delivery if the vehicle location doesn't match the proposal.
        		dealer__Vehicle_Inventory__c veh = deal.dealer__Vehicle__c!=null ? vMap.get(deal.dealer__Vehicle__c) : null;	// BLL34c 
        		if (veh!=null && veh.dealer__Store_Location__c!=deal.dealer__Store_Location__c) {
        			if (!deal.AdministrativeUpdate__c && (DealStatusValidation==null || DealStatusValidation.Enabled__c)) deal.addError('You cannot deliver the vehicle until it is transferred from ' + veh.dealer__Store_Location__r.Name);	// BLL22c AdministrativeUpdate__c
        		}
        		// BLL15a end
				System.debug(deal.TaxPostDT__c);
        	    // BLL10a
        	    if (deal.Proposed_Delivery_Date__c>Date.today()) deal.addError('The delivery date cannot be a future date! Please correct it.');
			}
			// BLL17a - Don't allow won proposal on a "quote" solution opportunity
			if (deal.dealer__Status__c!=null && deal.dealer__Status__c.startsWith('Won') && deal.dealer__Sales_Lead__c!=null) {
				dealer__Sales_Up__c sup = solOppMap.get(deal.dealer__Sales_Lead__c);
				if (sup!=null && (sup.dealer__Lead_Status__c=='Quote' || sup.dealer__First_Store_Visit_Date__c==null)) {
					// no appt needed for DME & Financial Products nor Commercial
					if (!noApptNeeded.contains(deal.dealer__Deal_Type__c) && !isCommercial) {
						if (!deal.AdministrativeUpdate__c && (DealQuoteValidation==null || DealQuoteValidation.Enabled__c)) deal.addError('The solution opportunity is not ready for a won proposal. Change the Solution Opportunity status to pending and make sure you have a shown appt.');	// BLL22c AdministrativeUpdate__c
					}
				}
			}
			// BLL17a end
			
		}
			
		// BLL34 - check for multiple won proposals
		for(dealer__Deal__c d : newList) {
			dealer__Vehicle_Inventory__c v;
			String msg = '';
			if (d.dealer__Vehicle__c!=null) v = vMap.get(d.dealer__Vehicle__c);
			if (v!=null && d.dealer__Status__c!=null && d.dealer__Status__c.startsWith('Won')
				&& d.Vehicle_Source__c!='Customer Owned') {	// BLL50c
				for(dealer__Deal__c otherdeal : v.dealer__R00N70000002II35EAG__r) {
					if (otherdeal.Name!=d.Name && otherdeal.dealer__Status__c!=null && otherdeal.dealer__Status__c.startsWith('Won')
						&& otherdeal.Vehicle_Source__c!='Customer Owned') {	// BLL50c
						String deliverydate = otherdeal.Proposed_Delivery_Date__c!=null ? otherdeal.Proposed_Delivery_Date__c.format() : ' not set ';
						msg += otherdeal.dealer__Store_Location__r.Name 
							+ ' proposal# ' + otherdeal.Name
							+ ' is already Won (' + otherdeal.dealer__Status__c + ') '
							+ ' for stock# ' + v.Name 
							+ ' (salesperson ' + otherdeal.dealer__Salesperson_1__r.Name 
							+ ', delivery ' + deliverydate + ')\n'; 
					}
				}
				if (!String.isBlank(msg)) {
					if (DealDuplicateStockSale==null || DealDuplicateStockSale.Enabled__c) d.addError(msg);	// BLL45c
				}
			}				
		}
		// BLL34a end
		
		// BLL42a - lost deals
		if (LostDealIds.size()>0) MarkProposalsAppraisalsLost(LostDealIds); 
		
	}


	// BLL58
	// isMovingForward - is the proposal status moving forward in the process?
	public boolean isMovingForward(String oldsts, String newsts) {
		// BLL59 improve efficiency
		//Integer oldidx = 0;
		//Integer newidx = 0;
		//if (oldsts!=newsts) {
		//	for(Integer i=0; i<StatusProgression.size(); i++) {
		//		if (StatusProgression[i]==oldsts) oldidx = i;
		//		if (StatusProgression[i]==newsts) newidx = i;
		//	}
		//}
		Integer oldidx = StatusProgression.indexOf(oldsts);
		Integer newidx = StatusProgression.indexOf(newsts);
		// BLL59 end
		return newidx>oldidx;
	}
	// BLL58 end

	// BLL22a - update status of orders (CommercialQuote__c)
	public void ConversionOrderStatus() {
		List<CommercialQuote__c> updCQ = new List<CommercialQuote__c>();	// quotes to update

		// Deals that move through the order process need related quotes updated to ordered or received
		Map<Id,CommercialQuote__c> chgdCQ = new Map<Id,CommercialQuote__c>();
		for(dealer__Deal__c deal : newList) {
			dealer__Deal__c olddeal = oldMap!=null ? oldMap.get(deal.Id) : null;
			if (deal.Commercial_Quote__c!=null && deal.dealer__Status__c=='Won - Ordered' && (olddeal==null || olddeal.dealer__Status__c!=deal.dealer__Status__c))
				chgdCQ.put(deal.Commercial_Quote__c, new CommercialQuote__c(Id=deal.Commercial_Quote__c, Status__c='Ordered'));  
			if (deal.Commercial_Quote__c!=null && deal.dealer__Status__c=='Won - F&I' && (olddeal==null || olddeal.dealer__Status__c!=deal.dealer__Status__c))
				chgdCQ.put(deal.Commercial_Quote__c, new CommercialQuote__c(Id=deal.Commercial_Quote__c, Status__c='Received'));  
			if (deal.Commercial_Quote__c!=null && deal.dealer__Status__c=='Won - Production' && (olddeal==null || olddeal.dealer__Status__c!=deal.dealer__Status__c))
				chgdCQ.put(deal.Commercial_Quote__c, new CommercialQuote__c(Id=deal.Commercial_Quote__c, Status__c='Received'));  
		}
		// list of current status for all these commercial quotes
		List<CommercialQuote__c> cqlist = new List<CommercialQuote__c>([
			select Id, Status__c from CommercialQuote__c
			where Id in :chgdCQ.keySet()
		]);
		// Only add quotes to the list for updating if the status is actually changing 
		for(CommercialQuote__c cq : cqlist) {
			CommercialQuote__c newcqsts = chgdCQ.get(cq.Id);
			if (newcqsts!=null && newcqsts.Status__c!=cq.Status__c)
				updCQ.add(newcqsts);
		}
		// do updates
		if (updCQ.size()>0) {
			update(updCQ);
		}
	}

	// BLL23a
	//--------------------------------------------------
	public void WonAppraisals() {

		Set<Id> deliveredProposals = new Set<Id>();
		for(dealer__Deal__c deal : newList) {
			dealer__Deal__c olddeal = oldMap!=null ? oldMap.get(deal.Id) : null;
			// Won appraisals - only if status changed in this update!
			//BLL39d if (deal.dealer__Status__c=='Won - Posted' && (olddeal==null || olddeal.dealer__Status__c!=deal.dealer__Status__c))  
			if (deal.dealer__Status__c=='Won - Delivered' && (olddeal==null || olddeal.dealer__Status__c!=deal.dealer__Status__c))	// BLL39a
					deliveredProposals.add(deal.Id);
		}
		List<dealer__Appraisal__c> wonapps = new List<dealer__Appraisal__c>();
		Map<Id,dealer__Service_Vehicle__c> updSrvVehOwn = new Map<Id,dealer__Service_Vehicle__c>();	// BLL33a
		if (deliveredProposals.size()>0) wonapps = [
			select Id, Name, dealer__Status__c, dtmob__Deal__c, dealer__Appraised_By__c, dealer__Vehicle_Owner__c,	// BLL32c 
				dealer__Sales_Up__r.dealer__Salesperson_1__c, dealer__Sales_Up__r.dealer__Customer_Account__c,  // BLL32c
				dtmob__Deal__r.dealer__Salesperson_1__c, dtmob__Deal__r.dealer__Buyer__c,
				dealer__Service_Vehicle__c, dealer__Service_Vehicle__r.dealer__Veh_Owner__c, dealer__Service_Vehicle__r.dealer__Last_Odometer__c,	// BLL33a
					dealer__Service_Vehicle__r.Name, dealer__Store_Location__r.dealer__Location_Account__c, 	// BLL33a 
				dtmob__Trade_In__c, dtmob__Trade_In__r.dealer__Odometer_at_Trade_In__c	// BLL33a
			from dealer__Appraisal__c 
			where dtmob__Deal__c in :deliveredProposals
			  and dealer__Status__c <> 'Won' 
		]; 
		for(dealer__Appraisal__c a : wonapps) {
			System.debug('Marking appraisal won: ' + a.Name);
			a.dealer__Status__c = 'Won';
			// BLL30a
			if (a.dealer__Appraised_By__c==null && a.dtmob__Deal__c!=null && a.dtmob__Deal__r.dealer__Salesperson_1__c!=null) a.dealer__Appraised_By__c = a.dtmob__Deal__r.dealer__Salesperson_1__c;	// BLL32c (was using sales up)
			if (a.dealer__Appraised_By__c==null && a.dealer__Sales_Up__c!=null && a.dealer__Sales_Up__r.dealer__Salesperson_1__c!=null) a.dealer__Appraised_By__c = a.dealer__Sales_Up__r.dealer__Salesperson_1__c;
			if (a.dealer__Vehicle_Owner__c==null && a.dtmob__Deal__c!=null && a.dtmob__Deal__r.dealer__Buyer__c!=null) a.dealer__Vehicle_Owner__c = a.dtmob__Deal__r.dealer__Buyer__c;	// BLL32a
			if (a.dealer__Vehicle_Owner__c==null && a.dealer__Sales_Up__c!=null && a.dealer__Sales_Up__r.dealer__Customer_Account__c!=null) a.dealer__Vehicle_Owner__c = a.dealer__Sales_Up__r.dealer__Customer_Account__c;	// BLL32a
			// BLL30a end
			// BLL33a
			dealer__Service_Vehicle__c sv = new dealer__Service_Vehicle__c(Id=a.dealer__Service_Vehicle__c);
			if (a.dealer__Service_Vehicle__c!=null && a.dealer__Service_Vehicle__r.dealer__Veh_Owner__c==null) {
				//sv.dealer__Veh_Owner__c=a.dealer__Store_Location__r.dealer__Location_Account__c;
				sv.dealer__Veh_Owner__c=a.dealer__Vehicle_Owner__c;
				System.debug('Update owner of service veh: ' + a.dealer__Service_Vehicle__r.Name);	// BLL33a
				updSrvVehOwn.put(a.dealer__Service_Vehicle__c, sv);
			}
			if (a.dealer__Service_Vehicle__c!=null && a.dealer__Service_Vehicle__r.dealer__Last_Odometer__c==null) {
				sv.dealer__Last_Odometer__c = a.dtmob__Trade_In__r.dealer__Odometer_at_Trade_In__c;
				System.debug('Update last odometer service veh: ' + a.dealer__Service_Vehicle__r.Name);	// BLL33a
				updSrvVehOwn.put(a.dealer__Service_Vehicle__c, sv);
			}
			// BLL33a end
		}
		try {
			if (updSrvVehOwn.size()>0) update(updSrvVehOwn.values());	// BLL33a
			if (wonapps.size()>0) update(wonapps);
		} catch(Exception e) {
			MonitorExecution mon = new MonitorExecution('WonAppraisals');
			mon.log('Unable to update appraisals to "Won"');
           	mon.log('EXCEPTION: ' + e.getTypeName() + '; ' + e.getMessage() + '; ' + e.getCause() + '; line ' + String.valueOf(e.getLineNumber()) + ';\n' + e.getStackTraceString()); 
			mon.log(JSON.serialize(wonapps)); 
			mon.notifyAdmin();
		}
	}
	// BLL23a end

	//--------------------------------------------------
	public void WonSolutionOpportunities() {
	    Set<Id> wonSolOppIds = new Set<Id>(); 
	    Set<Id> newlyWonSolOppIds = new Set<Id>();	// BLL42a
	    List<dealer__Sales_Up__c> wonSolOpps = new List<dealer__Sales_Up__c>();
	    
		for(dealer__Deal__c deal : newList) {
			dealer__Deal__c olddeal = oldMap!=null ? oldMap.get(deal.Id) : null;
			// Won solution opportunities - only if status changed in this update!
			if (deal.dealer__Status__c.startsWith('Won')) {
				if (deal.dealer__Sales_Lead__c!=null && (olddeal==null || olddeal.dealer__Status__c!=deal.dealer__Status__c)){ 
					wonSolOppIds.add(deal.dealer__Sales_Lead__c);
				}
			}
		}
		// Won solution opps
		if (wonSolOppIds.size()>0) {
			wonSolOpps = [
			   select Id, dealer__Lead_Status__c, dealer__Sold__c
			   from dealer__Sales_Up__c
			   where Id in :wonSolOppIds and (dealer__Sold__c!=true or dealer__Lead_Status__c!='Won') 
			];
			if (wonSolOpps.size()>0) {
				for(dealer__Sales_Up__c sup : wonSolOpps) {
					sup.dealer__Lead_Status__c = 'Won';
					sup.dealer__Sold__c = true;
					newlyWonSolOppIds.add(sup.Id);	// BLL42a
				}
				update(wonSolOpps);
			}
			if (newlyWonSolOppIds.size()>0) DealProcess.CloseAlternativeProposals(newlyWonSolOppIds);	// BLL42a
		}
		// BLL4a
    }
     

	//--------------------------------------------------
	public void PostSalesTax() {
	    Set<Id> postTaxDealIds = new Set<Id>(); // BLL5a
	    
		for(dealer__Deal__c deal : newList) {
			dealer__Deal__c olddeal = oldMap!=null ? oldMap.get(deal.Id) : null;
			//BLL13d if (deal.dealer__Status__c=='Won - Delivered' && olddeal!=null && olddeal.dealer__Status__c!=deal.dealer__Status__c) { 
			if (deal.dealer__Status__c=='Won - Posted' && olddeal!=null && olddeal.dealer__Status__c!=deal.dealer__Status__c) {	// BLL13a 
				// BLL5a
				if (deal.TaxPostDT__c==null && (olddeal==null || olddeal.dealer__Status__c!=deal.dealer__Status__c)) {
					if (deal.TaxCalcDT__c!=null) {	// ? and deal.TaxCommitDT__c!=null ?
						System.debug('Post tax for deal ' + deal.Id);
		    			postTaxDealIds.add(deal.Id);
					}
				}
				// BLL5a end
			}
		}
	    // BLL5a - commit/post sales tax to avalara
    	System.debug(postTaxDealIds);
    	if (postTaxDealIds.size()>0) Avatax_MBW.postDealsFuture(postTaxDealIds);
	    // BLL5a end
		
	}
			

	// BLL42a
	// VehiclesNotSoldAnymore()	
	//--------------------------------------------------
	public void VehiclesNotSoldAnymore() {
		// BLL67
		//Set<String> protectVehicleSts = new Set<String>{'Delivered','Order','Order - Sold Not Delivered','In Transit - Sold Not Delivered', 'Rental', 'Rental - Not for sale', 'Ready For Sale'};	// BLL25a, BLL27c
		Set<String> protectVehicleSts = new Set<String>{'Delivered', 'Order', 'Order - Sold Not Delivered', 'Rental', 'Rental - Not for sale', 'Ready For Sale',
			'Company Vehicle', 'Demo', 'Demo - Not For Sale'};
		// BLL67 end
	    Set<Id> vehNotSoldIds = new Set<Id>(); 
	    List<dealer__Vehicle_Inventory__c> vehNotSold = new List<dealer__Vehicle_Inventory__c>();
	     
		for(dealer__Deal__c deal : newList) {
			dealer__Deal__c olddeal = oldMap!=null ? oldMap.get(deal.Id) : null;
			// Vehicles sold not delivered - only if status changed in this update!
			if (deal.dealer__Status__c==null || !deal.dealer__Status__c.startsWith('Won')) {	// no longer "Won"
				if (deal.dealer__Vehicle__c!=null && olddeal!=null && olddeal.dealer__Status__c.startsWith('Won')) {
					vehNotSoldIds.add(deal.dealer__Vehicle__c);
				}
			}
		}
		// Vehicles sold not delivered
		if (vehNotSoldIds.size()>0) {
			vehNotSold = [
			   select Id, dealer__Status_Code__c,
			   	( select Id, Name, dealer__Status__c 
			   	  from dealer__R00N70000002II35EAG__r // deals
			   	  where dealer__Status__c like 'Won%' and dealer__Status__c!='Won - Posted'
			   	)
			   from dealer__Vehicle_Inventory__c
			   where Id in :vehNotSoldIds	
			     and dealer__Status_Code__c not in :protectVehicleSts	// BLL25a
			];
			if (vehNotSold.size()>0) {
				for(dealer__Vehicle_Inventory__c v : vehNotSold) {
					if (v.dealer__R00N70000002II35EAG__r.size()==0) {	// don't update status if there are other won proposals on this vehicle
						if (v.dealer__Status_Code__c!='Not For Sale') v.dealer__Status_Code_Assignment_Date__c = Date.today();	// BLL42a
						v.dealer__Status_Code__c = 'Not For Sale';
					}
				}
				update(vehNotSold);
			}
		}
	}
	// BLL42a end	
	
	//--------------------------------------------------
	public void VehiclesSoldNotDelivered() {
		Set<String> protectVehicleSts = new Set<String>{'Sold - Not Delivered','Delivered','Order','Order - Sold Not Delivered','In Transit - Sold Not Delivered'};	// BLL25a, BLL27c
	    Set<Id> vehSNDIds = new Set<Id>(); 
	    List<dealer__Vehicle_Inventory__c> vehSoldNotDlv = new List<dealer__Vehicle_Inventory__c>();
	     
		for(dealer__Deal__c deal : newList) {
			dealer__Deal__c olddeal = oldMap!=null ? oldMap.get(deal.Id) : null;
			// Vehicles sold not delivered - only if status changed in this update!
			if (deal.dealer__Status__c == 'Won - Production' || deal.dealer__Status__c == 'Won - Deposit') {  // BLL6c add Won - Deposit status
				if (deal.dealer__Vehicle__c!=null && (olddeal==null || olddeal.dealer__Status__c!=deal.dealer__Status__c)) {
					vehSNDIds.add(deal.dealer__Vehicle__c);
				}
			}
		}
		// Vehicles sold not delivered
		if (vehSNDIds.size()>0) {
			vehSoldNotDlv = [
			   select Id, dealer__Status_Code__c
			   from dealer__Vehicle_Inventory__c
			   where Id in :vehSNDIds // BLL25d  and dealer__Status_Code__c <> 'Sold - Not Delivered'	
			     and dealer__Status_Code__c not in :protectVehicleSts	// BLL25a
			];
			if (vehSoldNotDlv.size()>0) {
				for(dealer__Vehicle_Inventory__c v : vehSoldNotDlv) {
	                if (v.dealer__Status_Code__c!='Sold - Not Delivered') v.dealer__Status_Code_Assignment_Date__c = Date.today();	// BLL42a
					v.dealer__Status_Code__c = 'Sold - Not Delivered';
				}
				update(vehSoldNotDlv);
			}
		}
	}
		

	//--------------------------------------------------
	//public void ServiceContractVehicles() {
	//	List<String> deliveredSts = new List<String>{'Won - Delivered'};
    //	List<dealer__Service_Contract__c> updescs = new List<dealer__Service_Contract__c>();	// BLLa
	//
	//	// List of delivered deals (or moving from won to not won) to update service vehicle on ESCs
	//	Set<Id> dealIds = new Set<Id>();
	//	for(dealer__Deal__c deal : newList) {
	//		dealer__Deal__c olddeal = oldMap!=null ? oldMap.get(deal.Id) : null;
	//		if (olddeal!=null && olddeal.dealer__Status__c!=deal.dealer__Status__c && deliveredSts.contains(deal.dealer__Status__c)) dealIds.add(deal.Id);
	//		if (olddeal!=null && olddeal.dealer__Status__c!=null && olddeal.dealer__Status__c.startsWith('Won') && deal.dealer__Status__c!=null && !deal.dealer__Status__c.startsWith('Won'))) dealIds.add(deal.Id);
	//	}
	//	
	//	// get list of deals with related ESCs
	//	List<dealer__Deal__c> deals = new List<dealer__Deal__c>();
	//	if (dealIds.size()>0) deals = [
	//		select Id, Name, dealer__Status__c,
	//			(select Id, Name, dealer__Deal__c from dealer__Service_Contracts__r)
	//		from dealer__Deal__c
	//		where Id in :dealIds
	//	];
	//	
	//	// determine which escs need updated
	//	for(dealer__Deal__c d : deals) {
	//		// add service vehicle
	//		if (deliveredSts.contains(deal.dealer__Status__c)) {
	//			for(dealer__Service_Contract__c esc : d.dealer__Service_Contracts__r) {
	//				if (esc.dealer__Deal__c!=d.Id) updescs.add(new dealer__Service_Contract__c(Id=esc.Id, dealer__Service_Vehicle__c=d.dealer__Service_Vehicle__c));
	//			}
	//		}
	//		// remove service vehicle
	//		if (!deliveredSts.contains(deal.dealer__Status__c)) {
	//			for(dealer__Service_Contract__c esc : d.dealer__Service_Contracts__r) {
	//				if (esc.dealer__Deal__c!=null) updescs.add(new dealer__Service_Contract__c(Id=esc.Id, dealer__Service_Vehicle__c=null));
	//			}
	//		}
	//	}
	//	
	//	if (updescs.size()>0) update(updescs);
	//	
	//}
		
	//--------------------------------------------------
	public void VehiclesDelivered() {
	    Set<Id> vehDlvIds = new Set<Id>(); 
	    List<dealer__Vehicle_Inventory__c> vehDelivered = new List<dealer__Vehicle_Inventory__c>();
	    Map<Id, Date> vehicleSaleDates = new Map<Id, Date>(); // JVK3
    	Map<Id, Integer> vehicleSaleDueDays = new Map<Id, Integer>(); // BLL7a
    	Map<Id, Id> DlvVehDealMap = new Map<Id, Id>();	// BLL42a
	     
		for(dealer__Deal__c deal : newList) {
			dealer__Deal__c olddeal = oldMap!=null ? oldMap.get(deal.Id) : null;

			// Vehicles delivered - only if status changed in this update!
			if (deal.dealer__Status__c == 'Won - Delivered') {
				if (deal.dealer__Vehicle__c!=null && (olddeal==null || olddeal.dealer__Status__c!=deal.dealer__Status__c)) {
					vehDlvIds.add(deal.dealer__Vehicle__c);
	                //BLL7d vehicleSaleDates.put(deal.dealer__Vehicle__c, deal.Proposed_Delivery_Date__c);
	                DlvVehDealMap.put(deal.dealer__Vehicle__c, deal.Id);	// BLL42a
				}
				// BLL7a
				if (deal.dealer__Vehicle__c!=null 
					&& (olddeal==null 
						|| olddeal.Proposed_Delivery_Date__c!=deal.Proposed_Delivery_Date__c
						|| olddeal.dealer__Status__c!=deal.dealer__Status__c)) {	// BLL11c
					vehDlvIds.add(deal.dealer__Vehicle__c);  // also update if needing to change sale date!
	                vehicleSaleDates.put(deal.dealer__Vehicle__c, deal.Proposed_Delivery_Date__c);
	                Integer duedays = (deal.dealer__Finance_Institution_Account__c!=null) ? 5 : 1;  
	                vehicleSaleDueDays.put(deal.dealer__Vehicle__c, duedays); 
				}
				// BLL7a end
			}
		}
		// Vehicles delivered
		if (vehDlvIds.size()>0) {
			vehDelivered = [
			   select Id, dealer__Status_Code__c
			   from dealer__Vehicle_Inventory__c
			   where Id in :vehDlvIds // BLL7d (may be updating sale date only) and dealer__Status_Code__c != 'Delivered' 
			];
			if (vehDelivered.size()>0) {
				for(dealer__Vehicle_Inventory__c v : vehDelivered) {
	                if (v.dealer__Status_Code__c!='Delivered') v.dealer__Status_Code_Assignment_Date__c = Date.today();	// BLL42a
					v.dealer__Status_Code__c = 'Delivered';
	
	                if(vehicleSaleDates.get(v.Id)!=null) { //JVK3
	                    v.dealer__Sale_Date__c = (Date)vehicleSaleDates.get(v.Id);
	                    v.PaymentDueDays__c = vehicleSaleDueDays.get(v.Id); // BLL7a
	                    v.PurchaseFinanceMethod__c = v.PaymentDueDays__c>1 ? 'Financed' : 'Cash'; // BLL7a
	                }
				}
				update(vehDelivered);
			}
		}
		System.debug(DlvVehDealMap);	// BLL42a
		if (DlvVehDealMap.size()>0)	RmvDlvVehFromPendingDeals(DlvVehDealMap);	// BLL42a
	}


	//--------------------------------------------------
	public void DeliveryRepairOrders() {
	     
   		// Create Delivery Repair Order once a deal achieves the status of Service Apporoval
   		if(newList.size() == 1) {
			for(dealer__Deal__c d : newList) {
				dealer__Deal__c oldd = oldMap!=null ? oldMap.get(d.Id) : null;

        		// Create the custom repair order for the deal
        	    if(d.dealer__Status__c == 'Won - Production') {
        	        // JVK1
        	        // create the associated delivery repair order
        	        CustomInvoice c = new CustomInvoice();
	
	                if(d.dealer__DeliveryRepairOrder__c == null) {	// BLL20c
	                    dealer__Service_Repair_Order__c newRO = c.createROFromDeal(d);
	                    d.dealer__DeliveryRepairOrder__c = newRO.Id;	// BLL20c
	                } else {
	                	/* BLL4d temporarily remove until vetted & approved
	                    dealer__Service_Repair_Order__c ro = [Select Id, Name from dealer__Service_Repair_Order__c where Id=:d.dealer__DeliveryRepairOrder__c limit 1];	// BLL20c
	                    c.createLines(ro, d);
	                    */
	                }
	                //JVK1 End
	            }
	        } // end for Deal : newList
	    } // end if newList.size==1
	    
	}
    
    
	// BLL32a - vehicle is ready for delivery 
	//--------------------------------------------------
	public void ReadyForDelivery() {
		String subject = '';
		Set<String> proposalNames = new Set<String>();
		String emailBody = '';
		Set<Id> proposalIds = new Set<Id>();
		String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
	     
   		// Create Delivery Repair Order once a deal achieves the status of Service Apporoval
		for(dealer__Deal__c d : newList) {
			dealer__Deal__c oldd = oldMap!=null ? oldMap.get(d.Id) : null;
       		// Create the custom repair order for the deal
       	    if(d.dealer__Status__c == 'Won - Delivery' && oldd.dealer__Status__c!=d.dealer__Status__c
       	    	&& oldd.dealer__Status__c!='Won - Posted') {	// BLL46a
				proposalIds.add(d.Id);
            }
        } // end for Deal : newList
        
        // re-query proposal Ids with aftermarket to build emails
        if (proposalIds.size()>0) {
        	for(dealer__Deal__c d : [select Id, Name, dealer__Status__c,
        			( select Name, dealer__Quantity__c, dealer__Sale_Price__c, dealer__Cost__c,
        			  		dealer__Description__c, dealer__Parts_Kit__c, dealer__Parts_Kit__r.Name,
        			  		dealer__Part__c, dealer__Part__r.Name
        			  from dealer__After_Market_Items__r ) 
	        	from dealer__Deal__c where Id in :proposalIds]) {
	        	String proposalhdg = '<p>Proposal <a href="' + baseUrl + '/' + d.Id + '">' + d.Name + '</a>:\n';
				for(dealer__After_Market__c am : d.dealer__After_Market_Items__r) {
					if (am.dealer__Quantity__c<0) {
						proposalNames.add(d.Name);
						//BLL35d emailBody += proposalhdg + '<br/>Qty:' + am.dealer__Quantity__c + ', Part: ' + am.Name + ', Price ' + am.dealer__Sale_Price__c  + '\n';
						emailBody += proposalhdg + '<br/>Qty:' + am.dealer__Quantity__c + ', ' + am.Name + ', Cost ' + am.dealer__Cost__c
							+ ' ' + (am.dealer__Part__c==null ? '('+am.dealer__Description__c+')' : '')	// BLL42a  
							+ '\n';	// BLL35a
						proposalhdg = '';	// only add this once for all removed parts on the proposal
					}
	        	}	// end for dealer__After_Market_Items__r        		
	        	if (String.isBlank(proposalhdg)) emailBody += '</p>\n';	// space between proposals
        	}	// end for dealer__Deal__c
        }	// end if proposalIds.size>0

		subject = String.join(new List<String>(proposalNames),', ');        
	    if (!String.isBlank(emailBody)) sendEmailNotification(subject, emailBody);
	}
	
    public void sendEmailNotification(String subject, String emailBody) {
        List<String> emailGroup = new List<String>(Utility.getGroupMbrUserEmails('Part Removal Notification'));
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(emailGroup);

        Organization org = [select Id, isSandbox from Organization limit 1];
        if (org.isSandbox) emailBody = '<p>Sandbox NOT sending to: ' + String.join(emailGroup,', ') + '</p>\n' + emailBody;
        if (org.isSandbox) mail.setToAddresses(new List<String>{UserInfo.getUserEmail()});

        mail.setSubject(subject + ' to remove parts Alert');
        mail.setHTMLBody(emailBody);
        if (emailGroup.size()>0) Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        
    }
    // BLL32a end



	//--------------------------------------------------
	public void PostingEntries() {
	     
   		// Create Delivery Repair Order once a deal achieves the status of Service Apporoval
   		if(newList.size()==1) {
			for(dealer__Deal__c d : newList) {
				dealer__Deal__c oldd = oldMap!=null ? oldMap.get(d.Id) : null;

	            // Create the posting template based on the status Won - Delivered
				// BLL64
	            //if(d.dealer__Status__c == 'Won - Delivered') {
	            if(d.dealer__Status__c == 'Won - Delivered' && oldd!=null 
					&& oldd.dealer__Status__c!= d.dealer__Status__c && oldd.dealer__Status__c!= 'Won - Posted') {
				// BLL64 end 
	            	// Look to see that there is not an entry for this record
	            	Posting_Entry__c[] pe_list = [Select Id from Posting_Entry__c where Proposal__c=:d.Id limit 1];
	            	if(pe_list.size()==0) {
	            		// Create Record
	            		Posting_Entry__c p = new Posting_Entry__c(
            									Location__c=d.dealer__Store_Location__c,
            									Proposal__c=d.Id,
            									Stock__c=d.dealer__Vehicle__c
						);
	            		try {
            				insert p;
            			} catch(DmlException e) {
            				d.addError('Error: DML Exception '+e.getMessage());
            			}
            		}

                
	            } // end if Won-Delivered

				// BLL12a
    	        // DELETE the posting entry if the status goes back to status Won - Delivered
    	        if((d.dealer__Status__c=='Won - Delivery' || d.dealer__Status__c=='Pending')  
    	        	&& oldd!=null && oldd.dealer__Status__c=='Won - Delivered') {
    	        	// Look to see that there is not an entry for this record
    	        	Posting_Entry__c[] pe_list = [Select Id from Posting_Entry__c where Proposal__c=:d.Id ];
    	        	if(pe_list.size()>0) {
    	        		// Delete Record
    	        		try {
    	        			delete pe_list;
    	        		} catch(DmlException e) {
    	        			d.addError('Error: Unable to remove posting entry: ' + e.getMessage());
    	        		}
    	        	}
    	        }	
        	    // BLL12a end
			}
		}
	}
		

	//--------------------------------------------------
	// PostingProposals *was* only verifying the approver upon posting, but now is
	// verifying the approver upon conversion order & receive.
	public void PostingProposals() {
		RequireNamedApprover();
	}
	public void RequireNamedApprover() {
	
		// Approvals that change status to "Won - Posted" -- make sure user is an authorized approver!
		// (Protect from GM or someone else with ModifyAll on Deals from approving for accounting.)
	
		Set<Id> approvedDeals = new Set<Id>();
	
		// Only run if trigger size is 1 (approvals are always one-at-a-time), 
		// but code is bulkified anyway.
		if (oldMap!=null && newList.size()==1) {
			
			// Get list of approved deals (changing to Won - Posted status)
	    	for (dealer__Deal__c d : newList) {
	    	    dealer__Deal__c olddeal = oldMap!=null ? oldMap.get(d.Id) : null;
	    	    if (d.dealer__Status__c=='Won - Posted' && olddeal.dealer__Status__c!='Won - Posted') {
	    	        if (!d.AdministrativeUpdate__c) approvedDeals.add(d.Id);	// BLL53c
	    	    } 
	    	    // BLL30a - also verify who is approving for ordering and receiving the conversion.
	    	    if ((d.dealer__Status__c=='Won - Order' || d.dealer__Status__c=='Won - Ordered') 
	    	    	&& olddeal.dealer__Status__c!=d.dealer__Status__c) {
	    	        if (!d.AdministrativeUpdate__c) approvedDeals.add(d.Id);	// BLL53c
	    	    } 
	    	    // BLL30a
	    	    // BLL48a - also don't allow GM to approve F&I's step
	    	    if (d.dealer__Status__c=='Won - Production' && olddeal.dealer__Status__c=='Won - F&I') {
	    	    	if (!d.AdministrativeUpdate__c) approvedDeals.add(d.Id);	// BLL53c
	    	    }
	    	    // BLL48a end
	    	}

			// Only continue if there are any posted deals
			if (approvedDeals.size()>0) {

				// Get list of approvers for a set of object ids
				ApprovalProcessUtil apu = new ApprovalProcessUtil(approvedDeals);
				Map<Id,Set<Id>> approverMap = apu.getObjectApproverMap(); 

				// Get current user profile (if they are an Admin (modifyalldata=true) allow approval
				Profile prof = [
					select Id, Name, PermissionsModifyAllData 
					from Profile 
					where Id=:UserInfo.getProfileID() 
					limit 1
				];
		

		    	for(dealer__Deal__c deal : newList) {
		    		// List of approvers for the deal
		    	    Set<Id> authUsers = (Set<Id>) approverMap.get(deal.Id);
		    	    // If not on list, don't allow!
		    	    if (authUsers==null || !authUsers.contains(UserInfo.getUserId())) {
						if (prof.PermissionsModifyAllData != true ) {  // also allow Sys Admins
							deal.addError('You are not one of the assigned approvers for this step');
						}
		    	    }
		    	}
			}

		}
	}

	// SyncManagedFields - copy custom fields to managed fields of the same name
	public void SyncManagedFields() {
		// Custom fields drive the process (for now) - just copy custom field to managed version
		for (dealer__Deal__c d : newList) {
			//d.dealer__x__c = d.x__c;
			//BLL20d d.dealer__DeliveryRepairOrder__c = d.DeliveryRepairOrder__c;
			// (formula field) d.dealer__DeliveryRepairOrderStatus__c = d.DeliveryRepairOrderStatus__c;
			d.dealer__Electronic_Filing_Fee__c = d.Electronic_Filing_Fee__c;
			d.dealer__Registration_Title_Fee__c = d.Registration_Title_Fee__c;
			//d.dealer__Service_Vehicle__c = d.dealer__Service_Vehicle__c;	// BLL20c
			d.dealer__Smog_Cert__c = d.Smog_Cert__c;
			d.dealer__Tire_Fee__c = d.Tire_Fee__c;
			d.dealer__Total_Additional_Equipment__c = d.Total_Additional_Equipment__c;
			d.dealer__Total_Internal_Local_Equipment__c = d.Total_Internal_Local_Equipment__c;
			d.dealer__Warranty_Cost__c = d.Warranty_Cost__c;
			// BLL55a
			d.dealer__Deferred_1_Payee__c = d.Third_Party_Pay_1__c;
			d.dealer__Deferred_2_Payee__c = d.Third_Party_Pay_2__c;
			d.dealer__Deferred_3_Payee__c = d.Third_Party_Pay_3__c;
			// BLL55a end
		}
		
    	MW_TriggerControls__c DealCopyFields = MW_TriggerControls__c.getInstance('DealCopyFields');
    	if (DealCopyFields==null || DealCopyFields.Enabled__c==true) {
        	for (dealer__Deal__c deal: newList){
	            if (deal.Conversion_Price__c==null) deal.Conversion_Price__c = 0;	// BLL3a
	            if (deal.Chassis_Price__c==null) deal.Chassis_Price__c = 0;	// BLL3a
	            if (deal.Conversion_Cost__c==null) deal.Conversion_Cost__c = 0;	// BLL3a
	            if (deal.Chassis_Cost__c==null) deal.Chassis_Cost__c = 0;	// BLL3a
	            deal.dtmob__AutoGrant__c = deal.AutoGrant__c;
	            deal.dtmob__Vehicle_Chassis_Gross__c = deal.Chassis_Gross__c;
	            deal.dtmob__Chassis_Price__c = deal.Chassis_Price__c;	// BLL1d, BLL3 put back
	            deal.dealer__Vehicle_Price__c = deal.Chassis_Price__c + deal.Conversion_Price__c;	// BLL1a, BLL3c (incl conv price)
	            deal.dtmob__Conversion_Description__c = deal.Conversion_Description__c;
	            deal.dtmob__Conversion_Discount__c = deal.Conversion_Discount__c;
	            deal.dtmob__Vehicle_Conversion_Gross__c = deal.Conversion_Gross__c;
	            deal.dtmob__Conversion_Price__c = deal.Conversion_Price__c;
	            //deal.dealer__Electronic_Filing_Fee__c = deal.Electronic_Filing_Fee__c;
	            deal.dtmob__isChassisTax__c = deal.ChassisTaxable__c;
	            deal.dtmob__isConvertionTax__c = deal.Conversion_Taxable__c;
	            //deal.dealer__Smog_Cert__c = deal.Smog_Cert__c;
	            deal.dtmob__Smog_Fee__c = deal.Smog_Fee__c;
	            //deal.dealer__Tire_Fee__c = deal.Tire_Fee__c;
	            //deal.dealer__Total_Additional_Equipment__c = deal.Total_Additional_Equipment__c;
	            deal.dealer__Deposit_Note__c = deal.Deposit_Notes__c;
	            deal.dealer__GVWR__c = deal.GVW_GVWR__c;
	            //BLL2d deal.dealer__vehicle_gross__c = deal.VehicleGross__c;
	            
	            // Added these 1/17/2017 BLL1
	            //deal.dealer__Total_Internal_Local_Equipment__c = deal.Total_Internal_Local_Equipment__c;
				//deal.dealer__Registration_Title_Fee__c = deal.Registration_Title_Fee__c;
				//deal.dealer__Warranty_Cost__c = deal.Warranty_Cost__c;
				
				// More added 1/20/2016 BLL2
				deal.dealer__Total_Service_Contracts_Cost__c = deal.Warranty_Cost__c;
				deal.dealer__Total_Service_Contracts_Premium__c = deal.Total_Protection_Products__c;
				deal.dealer__Total_Service_Contracts_Gross__c = deal.Protection_Product_Gross__c;
				if (deal.dealer__Vehicle_Price__c==null) deal.dealer__Vehicle_Price__c = 0;
				deal.dealer__Vehicle_Cost__c = deal.Chassis_Cost__c + deal.Conversion_Cost__c;	// BLL3c incl conv cost
				if (deal.dealer__Vehicle_Cost__c==null) deal.dealer__Vehicle_Cost__c = 0;
				deal.dealer__Vehicle_Gross__c = deal.VehicleGross__c; // BLL3c deal.dealer__Vehicle_Price__c - deal.dealer__Vehicle_Cost__c;
				
	        }
	    }

	}

	// BLL42a
	// CloseAlternativeProposals - param is list of affected solution opportunities (sales ups)
	// For every newly-won, retail, chassis/conversion proposal, mark other
	// pending, retail, chassis/conversion proposals on the same solution opportunity "Lost"
	// also mark any related trade-ins Appraisals "Lost" (conditional so we can turn off if DT allows appraisals on multiple proposals)
	@future public static void CloseAlternativeProposals(Set<Id> supIds) {
		MW_TriggerControls__c AppraisalsMarkLost = MW_TriggerControls__c.getInstance('AppraisalsMarkLost');
		boolean markAppraisalsLost = AppraisalsMarkLost==null || AppraisalsMarkLost.Enabled__c==true;

		List<dealer__Deal__c> updDeals = new List<dealer__Deal__c>();
		List<dealer__Appraisal__c> updAppr = new List<dealer__Appraisal__c>();
		for(dealer__Deal__c d : [select Id, Name, dealer__Status__c, dealer__Deal_Type__c, RecordTypeId, RecordType.Name,
				dealer__Sales_Lead__c, dealer__Sales_Lead__r.Name,
				dealer__Buyer__c, dealer__Buyer__r.Name,
				dealer__Salesperson_1__c, dealer__Salesperson_1__r.Name, dealer__Salesperson_1__r.Email,
				(select Id, Name from dealer__Trade_Ins__r),
				(select Id, Name, dealer__Status__c, Lost_Reason__c, dtmob__Trade_In__c, dtmob__Trade_In__r.Name from dtmob__Appraisals__r where dealer__Status__c!='Lost')
			from dealer__Deal__c
			where dealer__Sales_Lead__c in :supIds
			  and RecordType.Name='Retail'
			  and dealer__Status__c='Pending' 
			  and dealer__Deal_Type__c = 'Chassis/Conversion'
			  and (Vehicle_Source__c=null or Vehicle_Source__c='Inventory')
		]) {
			updDeals.add(new dealer__Deal__c(
				Id=d.Id,
				dealer__Status__c = 'Lost'
			));
			// Similar Appraisal logic in BatchUpdateInactiveDeals, Deal_MBW2, DealProcess
			for(dealer__Appraisal__c a  : d.dtmob__Appraisals__r) {
				if (a.dealer__Status__c=='Pending') {
					updAppr.add(new dealer__Appraisal__c(
						Id = a.Id,
						dealer__Status__c = 'Lost',
						Lost_Reason__c = String.isBlank(a.Lost_Reason__c) ? 'No Activity on Appraisal' : a.Lost_Reason__c
					));
				}
			}
		}
		if (markAppraisalsLost) Database.update(updAppr, false);
		Database.update(updDeals, false);
	}


	// BLL42a
	// For any delivered vehicles, find other deals for the same vehicle and mark lost
	@future public static void RmvDlvVehFromPendingDeals(Map<Id,Id> DlvVehDealMap) {
		System.debug('RmvDlvVehFromPendingDeals');
		MW_TriggerControls__c DlvVehUnavailable = MW_TriggerControls__c.getInstance('DlvVehUnavailable');
		boolean rmvDlvdVehicle = DlvVehUnavailable==null || DlvVehUnavailable.Enabled__c==true;

		//MW_TriggerControls__c AppraisalsMarkLost = MW_TriggerControls__c.getInstance('AppraisalsMarkLost');
		//boolean markAppraisalsLost = AppraisalsMarkLost==null || AppraisalsMarkLost.Enabled__c==true;

		List<dealer__Deal__c> updDeals = new List<dealer__Deal__c>();
		List<dealer__Appraisal__c> updAppr = new List<dealer__Appraisal__c>();
		for(dealer__Deal__c d : [select Id, Name, dealer__Status__c, dealer__Deal_Type__c, RecordTypeId, RecordType.Name,
				dealer__Sales_Lead__c, dealer__Sales_Lead__r.Name, dealer__Vehicle__c, 
				dealer__Buyer__c, dealer__Buyer__r.Name,
				dealer__Salesperson_1__c, dealer__Salesperson_1__r.Name, dealer__Salesperson_1__r.Email
				//(select Id, Name from dealer__Trade_Ins__r),
				//(select Id, Name, dealer__Status__c, Lost_Reason__c, dtmob__Trade_In__c, dtmob__Trade_In__r.Name from dtmob__Appraisals__r where dealer__Status__c!='Lost')
			from dealer__Deal__c
			where dealer__Vehicle__c in :DlvVehDealMap.keySet() 
			  and RecordType.Name='Retail'
			  and dealer__Status__c='Pending' 
			  and dealer__Deal_Type__c in ('Chassis/Conversion', 'Wholesale')
			  and (Vehicle_Source__c=null or Vehicle_Source__c='Inventory')
		]) {
			if (d.Id!=DlvVehDealMap.get(d.dealer__Vehicle__c)) {
				updDeals.add(new dealer__Deal__c(
					Id=d.Id,
					//dealer__Status__c = 'Lost'	// remove vehicle instead of marking lost
					dealer__Vehicle__c = null
				));
				// only needed if marking proposals lost instead of removing vehicle:
				//for(dealer__Appraisal__c a  : d.dtmob__Appraisals__r) {
				//	if (a.dealer__Status__c=='Pending') {
				//		updAppr.add(new dealer__Appraisal__c(
				//			Id = a.Id,
				//			dealer__Status__c = 'Lost',
				//			Lost_Reason__c = String.isBlank(a.Lost_Reason__c) ? 'No Activity on Appraisal' : a.Lost_Reason__c
				//		));
				//	}
				//}
			}
		}
		//if (markAppraisalsLost) Database.update(updAppr, false);
		if (rmvDlvdVehicle) Database.update(updDeals, false);
	}


	@future public static void RecalcGPSharing(Set<Id> dealIds) {
		List<dealer__Deal__c> updDeals = new List<dealer__Deal__c>();
		Set<Id> vehIds = new Set<Id>();
		List<dealer__Deal__c> deals = [
			select Id, Name, RecordTypeId, dealer__Deal_Type__c, Vehicle_Source__c, dealer__Status__c, 
				GP_Sharing_Amount__c, GP_Sharing_Location__c, GP_Sharing_Date__c, New_Used_Other__c, 
				dealer__Vehicle__c
			from dealer__Deal__c
			where Id in :dealIds
		]; 
		for(dealer__Deal__c d : deals) vehIds.add(d.dealer__Vehicle__c);
		Map<Id, dealer__Vehicle_Inventory__c> vehMap = new Map<Id, dealer__Vehicle_Inventory__c>([
			select Id, Name, dealer__Inventory_Date__c, HomeLocation__c, New_Used_Other__c, 
				( select Id, Name, RequestedDate__c, dealer__Outbound_Location__c, dealer__Store_Location__c  // BLL76a
				  from dealer__Dealer_Trades__r
				  where dealer__Transfer_Status__c not in ('Not Submitted','Declined')
				  order by RequestedDate__c desc
				 )
			from dealer__Vehicle_Inventory__c
			where Id in :vehIds
		]);
		for(dealer__Deal__c d : deals) {
			dealer__Vehicle_Inventory__c v = vehMap.get(d.dealer__Vehicle__c);
			Decimal oldGPSharingAmt = d.GP_Sharing_Amount__c;
			if (v!=null) Deal_MBW2.calcGPSharing(d, v);
			if (oldGPSharingAmt!=d.GP_Sharing_Amount__c) updDeals.add(new dealer__Deal__c(
				Id = d.Id, GP_Sharing_Amount__c = d.GP_Sharing_Amount__c,
				GP_Sharing_Date__c = d.GP_Sharing_Date__c,
				GP_Sharing_Location__c = v.HomeLocation__c  
			));
		}
		// Updating GP_Sharing_Amount__c will cause trigger to recalculate proposal GP
		if (updDeals.size()>0) Database.update(updDeals, false);
	}
	

	// MarkProposalAppraisalsLost
	// For any lost deals, mark related proposals lost as well
	public static void MarkProposalsAppraisalsLost(Set<Id> dealIds) {
		MW_TriggerControls__c AppraisalsMarkLost = MW_TriggerControls__c.getInstance('AppraisalsMarkLost');
		boolean markAppraisalsLost = AppraisalsMarkLost==null || AppraisalsMarkLost.Enabled__c==true;

		List<dealer__Appraisal__c> updAppr = new List<dealer__Appraisal__c>();
		for(dealer__Deal__c d : [select Id, Name, dealer__Status__c, dealer__Deal_Type__c, RecordTypeId, RecordType.Name,
				dealer__Sales_Lead__c, dealer__Sales_Lead__r.Name, 
				dealer__Buyer__c, dealer__Buyer__r.Name,
				dealer__Salesperson_1__c, dealer__Salesperson_1__r.Name, dealer__Salesperson_1__r.Email,
				(select Id, Name from dealer__Trade_Ins__r),
				(select Id, Name, dealer__Status__c, Lost_Reason__c, dtmob__Trade_In__c, dtmob__Trade_In__r.Name from dtmob__Appraisals__r where dealer__Status__c!='Lost')
			from dealer__Deal__c
			where Id in :dealIds
		]) {
			for(dealer__Appraisal__c a  : d.dtmob__Appraisals__r) {
				if (a.dealer__Status__c=='Pending') {
					updAppr.add(new dealer__Appraisal__c(
						Id = a.Id,
						dealer__Status__c = 'Lost',
						Lost_Reason__c = String.isBlank(a.Lost_Reason__c) ? 'No Activity on Appraisal' : a.Lost_Reason__c
					));
				}
			}
		}
		if (markAppraisalsLost) Database.update(updAppr, false);
	}
	// BLL42a end

	// BLL55
	// all fields needed for proposal screen, printing, etc.
	public static Set<String> DealFieldsToRetrieve() {
		Set<String> fields = new Set<String>();
		//fields.addAll(dealer__Deal__c.getSObjectType().getDescribe().fields.getMap().keySet());	// BLL1a
		Map<String,Schema.SObjectField> fm = dealer__Deal__c.getSObjectType().getDescribe().fields.getMap();
		for(String f : fm.keySet()) {
			Schema.DescribeFieldResult fd = fm.get(f).getDescribe();
			if(fd.isAccessible() && !fd.isDeprecatedAndHidden()) fields.add(f);
		}

		// fields that cause problems... not sure why, but query says they're not part of the object
		List<String> problemFields = new List<String>{
			'dtmob__gap_gross_percent__c', 'dtmob__maintenance_gross_percent__c',
			'dtmob__other_gross_percent__c', 'dtmob__vehicle_gross_percent__c',
			'dtmob__warranty_gross_percent__c'
			// BLL70
			, 'dtmob__autogrant__c', 'dtmob__buyer_drivers_lic_state__c', 'dtmob__chassis_cost__c'
			, 'dtmob__Chassis_Discount__c', 'dtmob__Chassis_Gross_Percent__c', 'dtmob__Chassis_Price__c'
			, 'dtmob__Chassis_Retail_Price__c', 'dtmob__ClientNotes__c', 'dtmob__Co_Buyer_Drivers_Lic_State__c'
			, 'dtmob__Conversion_Cost__c', 'dtmob__Conversion_Description__c', 'dtmob__Conversion_Discount__c'
			, 'dtmob__Conversion_Gross_Percent__c', 'dtmob__Conversion_Manufacturer__c', 'dtmob__Conversion_Model__c'
			, 'dtmob__Conversion_Price__c'
			// BLL70 end
		};
		for(String f : problemFields) fields.remove(f.toLowerCase());
		// end of fields that cause problems

		// remove unnecessary fields to keep us under the 20K soql limit
		List<String> removeFields = new List<String>{
			'Approved_GM__c', 'Approved_Technical__c', 'Approved_Won_Deposit__c', 'Approved_Won_Depsoit__c',
			'dtmob__Auto_Grant_Payor__c', 'dealer__Buy_Rate__c', 
			'dealer__Maintenance_Cost__c', 'dealer__Maintenance_Gross__c', 'dtmob__Maintenance_Gross_Percent__c',
			'dealer__Maintenance_Gross_Percent__c', 'dealer__Maintenance_Premium__c',
			'dealer__Buyer_Birthdate__c', 'dealer__Co_Buyer_Birth_Date__c',	// BLL59a
			'dealer__Buyer_Social_Security_Number__c', 'dealer__Co_Buyer_Social_Security_Number__c', // BLL59a
			'LastActivityDate', 'LastViewedDate', 'LastReferencedDate', 'isDeleted'	// BLL59a
			// BLL69 remove more unneeded fields
			,'AdministrativeUpdate__c', 'CAT_Tax_Amt__c', 'Chass_Conv_Sell__c', 'Cloned_Proposal__c'
			,'Combined_Value__c'
			// BLL dealer namespace conversion fields 
			,'dealer__Conversion_Description__c', 'dealer__Conversion_Discount__c', 'dealer__Conversion_Gross_Percent__c', 'dealer__Conversion_Manufacturer__c', 'dealer__Conversion_Model__c', 'dealer__Conversion_Price__c', 'dealer__ConversionCost__c'
			// BLL69
			// BLL70
			, 'Wheelbase_Package_Ext_Price_Long__c', 'Wheelbase_Package_Price_Long__c', 'Wheelbase_Package_QTY_Long__c'
			// BLL70 end
		};
		for(String f : removeFields) fields.remove(f.toLowerCase());
		for(String f : fields) if (f.startsWith('dealer__auto_insurance')) fields.remove(f);
		for(String f : fields) if (f.startsWith('dealer__broker')) fields.remove(f);
		for(String f : fields) if (f.startsWith('dtmob__guarantor')) fields.remove(f);
		for(String f : fields) if (f.startsWith('dtmob__co_guarantor')) fields.remove(f);
		for(String f : fields) if (f.startsWith('dealer__gap_')) fields.remove(f);
		for(String f : fields) if (f.startsWith('dtmob_gap_')) fields.remove(f);
		for(String f : fields) if (f.startsWith('dealer__warranty_')) fields.remove(f);
		for(String f : fields) if (f.startsWith('dtmob_warranty_')) fields.remove(f);
		// end removing unnecessary fields for printing

		fields.add('dealer__Desk_Manager__r.Name');
		fields.add('dealer__Store_Location__r.dealer__Postal_Code__c');
		fields.add('dealer__Store_Location__r.Dealer_License_Name__c');
		fields.add('dealer__Store_Location__r.dealer__State__c');
		fields.add('dealer__Store_Location__r.dealer__Address__c');
		fields.add('dealer__Store_Location__r.dealer__Street__c');
		fields.add('dealer__Store_Location__r.dealer__City__c');
		
		Set<String> accountFields = new Set<String>{'Name','FirstName','LastName','BillingStreet',
		'BillingCity','BillingState','BillingPostalCode','Phone','PersonHomePhone','PersonMobilePhone',
		'PersonEmail','BusinessMobilePhone__c','dealer__Billing_Email__c', 'Fax', 'SSLast4__pc'};	// BLL61a
		// BLL61
		for(String s : accountFields) fields.add('dealer__Buyer__r.'+s);
		for(String s : accountFields) fields.add('dealer__Co_Buyer__r.'+s);
		// BLL61 end
		// BLL59
		Set<String> payorAccountFields = new Set<String>{'Name','FirstName','LastName',
		'BillingStreet','BillingCity','BillingState','BillingPostalCode','Phone',
		'BusinessMobilePhone__c','dealer__Billing_Email__c', 'Fax'};
		for(String s : payorAccountFields) fields.add('Third_Party_Pay_1__r.'+s);
		for(String s : payorAccountFields) fields.add('Third_Party_Pay_2__r.'+s);
		for(String s : payorAccountFields) fields.add('Third_Party_Pay_3__r.'+s);
		for(String s : payorAccountFields) fields.add('ReleasingDealer__r.'+s);

		// Inventory/stock vehicle
		List<String> viFields = new List<String>{'Name',
			'dealer__VIN__c','Conversion__c','Conversion__r.dealer__Description__c',
			'New_Used_Other__c', 'Unit_Type__c', 'dealer__Body_Type__c', 'dealer__Fuel_Type__c', 
			'dealer__Mileage__c', 'dealer__Vehicle_Cost__c', 'Conversion_Cost__c',
			'RecordType.Name'
		};
		for (String fName : viFields) fields.add('dealer__Vehicle__r.'+fName);

		// Service vehicle
		List<String> svFields = new List<String>{'Name',
			'dealer__VIN__c','dealer__Make__c','dealer__Carline__c',
			'dealer__Trim_Level__c', 'dealer__Year__c', 'dealer__Ext_Color__c', 'dealer__Body_Type__c', 
			'dealer__Last_Odometer__c'
		};
		for (String fName : svFields) fields.add('dealer__Service_Vehicle__r.'+fName);

		// Location
		List<String> locFields = new List<String>{'Name'};
		for (String fName : locFields) fields.add('dealer__Store_Location__r.'+fName);

		// User fields for each user reference
		List<String> userfields = new List<String>{'Name','FirstName','LastName','Email','Phone'};
		List<String> userrefs = new List<String>{'dealer__Store_Location__r.dealer__General_Manager__r',
			'dealer__Store_Location__r.Sales_Admin__r','dealer__Store_Location__r.dealer__Service_Director__r',
			'dealer__Store_Location__r.Commercial_Sales_Admin__r', 'dealer__Salesperson_1__r'};
		List<String> userreffields = new List<String>();
		for(String ur : userrefs) {
			for(String uf : userfields) fields.add(ur+'.'+uf);
		}
		// BLL59a
		List<String> userfields2 = new List<String>{'Name','FirstName','LastName'};
		List<String> userrefs2 = new List<String>{'dealer__Store_Location__r.F_I_Manager__r',
		'dealer__Store_Location__r.Rental_Manager__r'};
		for(String ur : userrefs2) {
			for(String uf : userfields2) fields.add(ur+'.'+uf);
		}
		// BLL59a end

		// Finance Company
        List<String> fiFields = new List<String>{'Name',
        	'dealer__Bank_Address__c', 'dealer__Bank_City__c', 'dealer__Bank_State__c', 
        	'dealer__Bank_Zip__c', 'FinanceAccount__c' 
		};
		for (String fName : fiFields) fields.add('dealer__Finance_Institution_Account__r.'+fName);
		System.debug(String.join(new List<String>(fields), ',').length());

		return fields;

	}
	// BLL55 end

}