/**
 * CreditApplicationProcess
 * Tested by: CreditApplicationProcess_TEST
 * Date: 2019-02-05
 * Programmer: Bryan Leaman
 * Project: W-000579
 *
 * Code Coverage:
 *	2019-03-04	100%	(87/87)
 *
 * Modifications: 
 *	2019-07-03	B. Leaman	BLL1 - handle Approved vs Countered sts
 *	2019-09-25	B. Leaman	W-000761 BLL2 - not auto-approving proposal anymore
**/
public with sharing class CreditApplicationProcess {

	// BLL1
	public static Set<String> ApprovedSts = new Set<String>{'Approved', 'Countered'};
	// BLL1

	/* ProposalCreditApplications - return list of applications for a proposal */
	//------------------------------------------------
	@AuraEnabled
	public static List<dealer__Credit_Application__c> ProposalCreditApplications(Id ProposalId) {
		return [
			select Id, Name, Application_Status__c, VIN__c, Finance_Company__c, Finance_Company__r.Name, Proposal__c, Solution_Opportunity__c, dealer__Store_Location__c,
				Application_Received__c, Credit_App_Submitted__c, Decision_Received__c,
				Items_Missing__c, Notes__c, Different_VIN__c, Application_initial_receipt__c
			from dealer__Credit_Application__c
			where Proposal__c = :ProposalId
			order by Different_VIN__c, VIN__c, Finance_Company__r.Name
		];
	}

	// deleteCreditAppRcd - delete a credit application 
	//------------------------------------------------
	@AuraEnabled
	public static void deleteCreditAppRcd(Id recordid) {
		delete(new dealer__Credit_Application__c(Id=recordid));
	}

	// submitCreditAppRcd - submit a credit application 
	//------------------------------------------------
	@AuraEnabled
	public static void submitCreditAppRcd(Id recordid) {
		dealer__Credit_Application__c ca = [
			select Id, Credit_App_Submitted__c, Decision_Received__c, Application_Status__c,
			Proposal__c, Proposal__r.dealer__VIN__c, VIN__c
			from dealer__Credit_Application__c 
			where Id=:recordId limit 1
		];
		ca.Credit_App_Submitted__c=DateTime.now();
		ca.Decision_Received__c=null;
		ca.Application_Status__c='Submitted';
		update(ca);
	}


	// markCreditAppReceived
	//------------------------------------------------
	@AuraEnabled
	public static void markCreditAppReceived(Id recordId) {
		//dealer__F_I_Manager__c,dealer__F_I_Manager__r.Name,Credit_Application_Received__c
		dealer__Deal__c deal = [
			select Id, Credit_Application_Received__c, dealer__F_I_Manager__c, dealer__VIN__c, Credit_App_Initial_Receipt__c
			from dealer__Deal__c 
			where Id=:recordid
		];
		deal.Credit_Application_Received__c=DateTime.now();
		if (deal.Credit_App_Initial_Receipt__c==null) deal.Credit_App_Initial_Receipt__c = deal.Credit_Application_Received__c;
		if (deal.dealer__F_I_Manager__c==null) deal.dealer__F_I_Manager__c = UserInfo.getUserId();
		update(deal);
		System.debug(deal);
		List<dealer__Credit_Application__c> creditapps = [
			select Id, Application_Received__c, VIN__c
			from dealer__Credit_Application__c
			where Proposal__c=:recordid
		];
		for(dealer__Credit_Application__c ca : creditapps) {
			ca.Application_Received__c = deal.Credit_Application_Received__c;
			ca.VIN__c = deal.dealer__VIN__c;
		}
		if (creditapps.size()>0) update(creditapps);
	}


	// acceptCreditAppRcd -- accept a credit application
	//------------------------------------------------
	@AuraEnabled
	public static void acceptCreditAppRcd(Id recordId) {
		dealer__Credit_Application__c ca = [
			select Id, Credit_App_Submitted__c, Decision_Received__c, Credit_Accepted__c, Application_Status__c,
			Proposal__c, Proposal__r.dealer__VIN__c, VIN__c, Application_initial_receipt__c, Recourse_Required__c, 
			Offer_Principle__c, Offer_Payment__c, Offer_Term__c, Counter_Offer__c, Offer_APR__c, Offer_Buy_Rate__c, Lease_Money_Factor__c
			from dealer__Credit_Application__c 
			where Id=:recordId 
			limit 1
		];
		ca.Credit_Accepted__c=DateTime.now();
		if (ca.Decision_Received__c==null) ca.Decision_Received__c = ca.Credit_Accepted__c;
		ca.Application_Status__c='Delivered';
		update(ca);
		// BLL2 approve step if waiting for F&I
		ApprovalProcessUtil.ApproveDocument(ca.Proposal__c, 'Financing approved', new Set<String>{'F&I Approval'});
		// BLL2 end
		// Deal update moved into trigger on credit app status change to delivered
		//dealer__Deal__c deal = new dealer__Deal__c(
		//	Id=ca.Proposal__c,
		//	Credit_Application_Status__c='Delivered',
		//	Contract_Amount_Financed__c = ca.Offer_Principle__c,
		//	Contract_Monthly_Payment__c = ca.Offer_Payment__c,
		//	Contract_Final_Payment__c = ca.Offer_Payment__c,
		//	Contract_Number_of_Payments__c = ca.Offer_Term__c,
		//	Contract_CounterOffer__c = ca.Counter_Offer__c,
		//	Contract_APR__c = ca.Offer_APR__c,
		//	Contract_Buy_Rate__c = ca.Offer_Buy_Rate__c,
		//	LeaseMoneyFactor__c = ca.Lease_Money_Factor__c
		//);
		//update(deal);
	}


	// updateCreditApplication
	//--------------------------------------------
	@AuraEnabled
	public static void updateCreditApplication(String jsonstr) {
		dealer__Credit_Application__c ca = (dealer__Credit_Application__c) Utility.jsonStringToSObject(jsonstr, dealer__Credit_Application__c.SObjectType);
		update(ca);
	}


	// Automatically update proposals' Credit_App_Incomplete__c flag based on changes to Credit_App_Missing_Items__c
	//--------------------------------------------
	public static void flagMissingItems(List<dealer__Deal__c> newList, Map<Id, dealer__Deal__c> oldMap) {
		// if missing items text was entered or removed, then automatically set or reset the credit app incomplete flag
		for(dealer__Deal__c d : newList) {
			dealer__Deal__c oldd = oldMap.get(d.Id);
			boolean missing_items_chgd = (oldd==null && !String.isBlank(d.Credit_App_Missing_Items__c))
				|| (oldd!=null && String.isBlank(d.Credit_App_Missing_Items__c)!=String.isBlank(oldd.Credit_App_Missing_Items__c));
			if (missing_items_chgd) d.Credit_App_Incomplete__c = !String.isBlank(d.Credit_App_Missing_Items__c);
		}
	}
	  

	// Update proposals' F&I/Credit application status
	// returns list of changed proposals to update, but also updates the passed in proposals
	// so it can easily be run from the proposal before update trigger too
	public static List<dealer__Deal__c> updateProposalFandIStatus(List<dealer__Deal__c> deals) {
		System.debug('updateProposalFandIStatus');

		List<String> stsProgression = new List<String>{'Not Submitted', 'Submitted', 'Declined', 'Countered', 'Approved', 'Delivered', 'Dead Deal'};	// BLL add Countered!
		List<dealer__Deal__c> upddeals = new List<dealer__Deal__c>();

		// List of referenced proposals
		Set<Id> dealIds = new Set<Id>();
		for(dealer__Deal__c d : deals) dealIds.add(d.Id);

		// Build map by deal Id to list of related credit applications
		Map<Id, List<dealer__Credit_Application__c>> camap = new Map<Id, List<dealer__Credit_Application__c>>();
		for(dealer__Credit_Application__c ca : [
			select Id, Proposal__c, Proposal__r.dealer__VIN__c, Application_Status__c, VIN__c, 
				Application_initial_receipt__c, Application_Received__c, Credit_App_Submitted__c, 
				Decision_Received__c, Credit_Accepted__c, Finance_Company__c, Recourse_Required__c, 
				Offer_Principle__c, Offer_Payment__c, Offer_Term__c, Counter_Offer__c,
				Offer_APR__c, Offer_Buy_Rate__c, Lease_Money_Factor__c
			from dealer__Credit_Application__c
			where Proposal__c in :dealIds
		]) {
			List<dealer__Credit_Application__c> crdapps = camap.get(ca.Proposal__c);
			if (crdapps==null) crdapps = new List<dealer__Credit_Application__c>();
			// only consider this application if it matches the deal's VIN (when specified)
			if (String.isBlank(ca.Proposal__r.dealer__VIN__c) || String.isBlank(ca.VIN__c) || ca.Proposal__r.dealer__VIN__c==ca.VIN__c) {
				crdapps.add(ca);
			}
			camap.put(ca.Proposal__c, crdapps);
		}

		// Determine status for each proposal based on the referenced credit applications
		for(dealer__Deal__c d : deals) {
			String newsts = null;
			DateTime newReceived = null;
			DateTime newSubmitted = null;
			DateTime newDecision = null;
			DateTime newAccepted = null;
			String decisionSts = null;
			Integer lastcaidx = -1;
			List<dealer__Credit_Application__c> capps = camap.get(d.Id);
			if (capps==null) capps = new List<dealer__Credit_Application__c>();

			// Skip posted deals that have no credit apps at all (preserve old metrics)
			if (d.dealer__Status__c!='Won - Posted' || capps.size()>0) {

				// deal to update
				dealer__Deal__c updDeal = new dealer__Deal__c(Id=d.Id);
				boolean dealChanged = false;
				dealer__Credit_Application__c deliveredCreditApp = null;

				for(dealer__Credit_Application__c ca : capps) {
					Integer caidx = stsProgression.indexOf(ca.Application_Status__c);
					if ( caidx > lastcaidx) {
						lastcaidx = caidx;
						newsts = ca.Application_Status__c;
					} 
					if (newReceived==null || newReceived>ca.Application_initial_receipt__c) newReceived = ca.Application_initial_receipt__c;
					if (newSubmitted==null || newSubmitted>ca.Credit_App_Submitted__c) newSubmitted = ca.Credit_App_Submitted__c;
					//BLL1
					//if (newDecision==null || newDecision>ca.Decision_Received__c || (decisionSts=='Declined' && ca.Application_Status__c=='Approved')) {
					if (newDecision==null || newDecision>ca.Decision_Received__c || (decisionSts=='Declined' && ApprovedSts.contains(ca.Application_Status__c))) {
					// BLL1 end
						newDecision = ca.Decision_Received__c;
						decisionSts = ca.Application_Status__c;
					}
					if (newAccepted==null || newAccepted>ca.Credit_Accepted__c) newAccepted = ca.Credit_Accepted__c;
					// update proposal from delivered credit app
					if (ca.Application_Status__c=='Delivered') {
						deliveredCreditApp = ca;
						System.debug('delivered credit app=');
						System.debug(ca);
					}
				}
				//if (newsts==null && d.Credit_Application_Received__c!=null) newsts = null;
				System.debug(d.Credit_Application_Status__c);
				// Determine if deal needs to be updated, update parm and list of changed deals
				if (d.Credit_Application_Status__c!=newsts) {
					d.Credit_Application_Status__c = newsts;
					updDeal.Credit_Application_Status__c=newsts;
					dealChanged = true;
					if (d.Credit_Application_Status__c=='Delivered' && deliveredCreditApp!=null) {
						d.Credit_Application__c = deliveredCreditApp.Id;
						d.dealer__Finance_Institution_Account__c = deliveredCreditApp.Finance_Company__c;
						d.Contract_Amount_Financed__c = deliveredCreditApp.Offer_Principle__c;
						d.Contract_Monthly_Payment__c = deliveredCreditApp.Offer_Payment__c;
						d.Contract_Final_Payment__c = deliveredCreditApp.Offer_Payment__c;
						d.Contract_Number_of_Payments__c = deliveredCreditApp.Offer_Term__c;
						d.Contract_CounterOffer__c = deliveredCreditApp.Counter_Offer__c;
						d.Contract_APR__c = deliveredCreditApp.Offer_APR__c;
						d.Contract_Buy_Rate__c = deliveredCreditApp.Offer_Buy_Rate__c;
						d.LeaseMoneyFactor__c = deliveredCreditApp.Lease_Money_Factor__c;
						d.Recourse_Required__c = deliveredCreditApp.Recourse_Required__c;
						updDeal.Credit_Application__c = deliveredCreditApp.Id;
						updDeal.dealer__Finance_Institution_Account__c = deliveredCreditApp.Finance_Company__c;
						updDeal.Contract_Amount_Financed__c = deliveredCreditApp.Offer_Principle__c;
						updDeal.Contract_Monthly_Payment__c = deliveredCreditApp.Offer_Payment__c;
						updDeal.Contract_Final_Payment__c = deliveredCreditApp.Offer_Payment__c;
						updDeal.Contract_Number_of_Payments__c = deliveredCreditApp.Offer_Term__c;
						updDeal.Contract_CounterOffer__c = deliveredCreditApp.Counter_Offer__c;
						updDeal.Contract_APR__c = deliveredCreditApp.Offer_APR__c;
						updDeal.Contract_Buy_Rate__c = deliveredCreditApp.Offer_Buy_Rate__c;
						updDeal.LeaseMoneyFactor__c = deliveredCreditApp.Lease_Money_Factor__c;
						updDeal.Recourse_Required__c = deliveredCreditApp.Recourse_Required__c;
					} else {
						d.Credit_Application__c = null;
						updDeal.Credit_Application__c = null;
					}
				}
				//if (capps.size()>0 && d.Credit_Application_Received__c!=newReceived) {
				//	d.Credit_Application_Received__c = newReceived;
				//	updDeal.Credit_Application_Received__c = newReceived;
				//	dealChanged = true;
				//}
				if (d.Credit_App_Submitted__c!=newSubmitted) {
					d.Credit_App_Submitted__c = newSubmitted;
					updDeal.Credit_App_Submitted__c = newSubmitted;
					dealChanged = true;
				}
				if (d.Credit_Decision_Received__c!=newDecision) {
					d.Credit_Decision_Received__c = newDecision;
					updDeal.Credit_Decision_Received__c = newDecision;
					dealChanged = true;
				}
				if (dealChanged) upddeals.add(updDeal);
			}
		}

		// return only those deals that need to be updated
		return upddeals;
	}


	// updateCreditAppProposalStatus
	// update related deals' credit status when a credit application is updated
	//--------------------------------------------
	public static void updateCreditAppProposalStatus(List<dealer__Credit_Application__c> creditApps) {
		System.debug('updateCreditAppProposalStatus');
		Set<Id> dealIds = new Set<Id>();
		for(dealer__Credit_Application__c ca : creditApps) {
			if (ca.Proposal__c!=null) dealIds.add(ca.Proposal__c);
		}
		List<dealer__Deal__c> proposals = new List<dealer__Deal__c>();
		if (dealIds.size()>0) proposals = [
			select Id, Name, dealer__Status__c, dealer__VIN__c, Credit_Application__c, Credit_Application_Status__c,
				Credit_App_Missing_Items__c, Credit_App_Incomplete__c,
				Credit_App_Initial_Receipt__c, Credit_Application_Received__c, Credit_App_Submitted__c,
				Credit_Decision_Received__c, Credit_Offer_Accepted__c
			from dealer__Deal__c
			where Id in :dealIds
		];
		List<dealer__Deal__c> updDeals = CreditApplicationProcess.updateProposalFandIStatus(proposals);
		System.debug(updDeals);
		update(updDeals);
	}


	// creditApplicationDefaults - on new record
	//--------------------------------------------
	public static void creditApplicationDefaults(List<dealer__Credit_Application__c> creditApps) {
		Set<Id> fincompIds = new Set<Id>();
		Set<Id> dealIds = new Set<Id>();
		for(dealer__Credit_Application__c ca : creditApps) {
			if (ca.Finance_Company__c!=null) fincompIds.add(ca.Finance_Company__c);
			if (ca.Proposal__c!=null) dealIds.add(ca.Proposal__c);
		}
		Map<Id,dealer__Finance_Company__c> fincompMap = new Map<Id,dealer__Finance_Company__c>([
			select Id, Name, ChargesAcquisitionFee__c, AcquisitionFee__c, AcquisitionCost__c, LeaseMoneyFactor__c
			from dealer__Finance_Company__c
			where Id in :fincompIds
		]);
		Map<Id,dealer__Deal__c> dealMap = new Map<Id,dealer__Deal__c>([
			select Id, Name, Contract_Amount_Financed__c, TotalDueUponDelivery__c, dealer__Store_Location__c
			from dealer__Deal__c
			where Id in :dealIds
		]);
		for(dealer__Credit_Application__c ca : creditApps) {
			dealer__Finance_Company__c fc = fincompMap.get(ca.Finance_Company__c);
			dealer__Deal__c d = dealMap.get(ca.Proposal__c);
			if (fc!=null) {
				ca.Lease_Money_Factor__c = fc.LeaseMoneyFactor__c;
				ca.Acquisition_fee__c = fc.AcquisitionFee__c;
				ca.Acquisition_COST__c = fc.AcquisitionCost__c;
			}
			if (d!=null) {
				ca.dealer__Store_Location__c = d.dealer__Store_Location__c;
				if (d.Contract_Amount_Financed__c!=null) ca.Offer_Principle__c = d.Contract_Amount_Financed__c;
				else if (d.TotalDueUponDelivery__c!=null) ca.Offer_Principle__c =d.TotalDueUponDelivery__c;
			}
		}
	}


	// BLL1
	// creditApplicationIntegrity
	//--------------------------------------------
	public static void creditApplicationIntegrity(List<dealer__Credit_Application__c> creditApps) {
		Set<Id> dealIds = new Set<Id>();
		for(dealer__Credit_Application__c ca : creditApps) {
			if (ca.Proposal__c!=null) dealIds.add(ca.Proposal__c);
		}
		Map<Id,dealer__Deal__c> proposalMap = new Map<Id,dealer__Deal__c>();
		if (dealIds.size()>0) proposalMap = new Map<Id, dealer__Deal__c>([
			select Id, Name, dealer__Status__c, dealer__VIN__c, Credit_Application__c, Credit_Application_Status__c,
				Credit_App_Initial_Receipt__c, Credit_Application_Received__c
			from dealer__Deal__c
			where Id in :dealIds
		]);
		for(dealer__Credit_Application__c ca : creditApps) {
			if (ca.Application_Status__c=='Approved' && ca.Counter_Offer__c==true) ca.Application_Status__c='Countered';
			if (ca.Application_Status__c=='Countered' && ca.Counter_Offer__c==false) ca.Application_Status__c='Approved';
			dealer__Deal__c deal = proposalMap.get(ca.Proposal__c);
			if (deal!=null && deal.Credit_Application_Received__c!=null && ca.Application_Received__c==null) {
				ca.Application_Received__c = deal.Credit_Application_Received__c;
				//if (ca.Application_Status__c==null || ca.Application_Status__c=='Not Submitted')
				//   ca.Application_Status__c = 'Application Received';
				if (ca.Application_Status__c==null) ca.Application_Status__c='Not Submitted';
			}
		}
	}
	// BLL1 end

}