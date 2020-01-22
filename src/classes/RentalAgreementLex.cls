/**
 * RentalAgreementLex
 * Tested by: RentalAgreementLex_TEST
 * 
 * Coverage:
 *	2018-09-27	100%	(28/28)
 *	2019-01-24	100%	(43/43)
 *
 * Modifications:
 * 	2019-01-24	W-000564 BLL1 Ignore exception on posttaxes (like classic did)
 *	2019-07-23	W-000723 BLL2 - remove return mileage updates, as they were not being maintained properly.
 *	2019-11-08	BLL3 - Flag rental when posting is submitted so it cannot be posted twice.
 */
public with sharing class RentalAgreementLex {

	@AuraEnabled
	public static void postRentalAgreement(Id rentalAgreementId) {

		// BLL3
		//dealer__Rental_Agreements__c rentalagreement = new dealer__Rental_Agreements__c(Id=rentalAgreementId);
		List<dealer__Rental_Agreements__c> rentalagreements = [
			select Id, dealer__Return_Mileage__c, Rental_Vehicle__c, Rental_Vehicle__r.dealer__Mileage__c,
				PostingSubmitted__c
			from dealer__Rental_Agreements__c 
			where Id=:rentalAgreementId
		];
		dealer__Rental_Agreements__c rentalagreement = rentalagreements.size()>0 ? rentalagreements[0] : new dealer__Rental_Agreements__c(Id=rentalAgreementId, Rental_Vehicle__c=null, dealer__Return_Mileage__c=null);
		if (rentalagreement!=null && rentalagreement.PostingSubmitted__c==true) {
			throw new RentalPostingException('Rental ' + rentalagreement.Name + ' has already been submitted for posting');
		}
		// BLL3

		// BLL1a
		try {
		// BLL1 end
			RentalAgreementLex.postTaxes(rentalAgreementId);
		// BLL1a
		} catch(Exception e) {
			System.debug(e);
		}
		// BLL1 end

		////dealer__Rental_Agreements__c rentalagreement = new dealer__Rental_Agreements__c(Id=rentalAgreementId);
		//List<dealer__Rental_Agreements__c> rentalagreements = [
		//	select Id, dealer__Return_Mileage__c, Rental_Vehicle__c, Rental_Vehicle__r.dealer__Mileage__c,
		//		PostingSubmitted__c
		//	from dealer__Rental_Agreements__c 
		//	where Id=:rentalAgreementId
		//];
		//dealer__Rental_Agreements__c rentalagreement = rentalagreements.size()>0 ? rentalagreements[0] : new dealer__Rental_Agreements__c(Id=rentalAgreementId, Rental_Vehicle__c=null, dealer__Return_Mileage__c=null);
		rentalagreement.dealer__Agreement_Status__c = 'Paid';
		rentalagreement.PostingSubmitted__c = true;	// BLL3
		rentalagreement.dealer__Rental_Vehicle__c = rentalagreement.Rental_Vehicle__c;
		update(rentalagreement);
		
		// It appeared that DealerTeam was updating the mileage in dev, but it's not happening in QA
		// So we'll update it here, only if it's an increase...
		// BLLx remove
		//if (rentalagreement.dealer__Rental_Vehicle__c!=null && rentalagreement.dealer__Return_Mileage__c!=null) {
		//	if (rentalagreement.dealer__Rental_Vehicle__r.dealer__Mileage__c==null || rentalagreement.dealer__Rental_Vehicle__r.dealer__Mileage__c<rentalagreement.dealer__Return_Mileage__c) {
		//		Database.update(new dealer__Vehicle_Inventory__c(
		//			Id=rentalagreement.dealer__Rental_Vehicle__c, 
		//			dealer__Mileage__c=rentalagreement.dealer__Return_Mileage__c), 
		//		false);
		//	}
		//}
		// BLLx end

   		Organization org = [select Id, Name from Organization limit 1];
   		String payload = '{"recordId":"' + rentalagreement.Id 
   			+ '","orgId":"' + org.Id + '","action":"rental_agreement_post","requestedBy":"' + UserInfo.getUserId() + '"}';
		FFAccounting.emailAsyncHandler(payload);	// BLL12a
	}
    
    public static void postTaxes(Id rentalAgreementId) {
    	dealer__Rental_Agreements__c rentalagreement = [
    		select Id, Total_Charges__c
    		from dealer__Rental_Agreements__c
    		where Id=:rentalAgreementId 
    	];
	    Avatax_MBW tax = Avatax_MBW.getInstanceRentalId(rentalAgreementId);
    	if (tax.AutomaticCalc) {
      		tax.calculateTax();
      		tax.debugTaxResultSummary();
      		tax.saveRentalTaxDetail();
      		tax.updRentalTaxHeader(rentalagreement);
      		update(rentalagreement);	// BLL12a - force update here before sending to Avalara
    	}
    	MW_TriggerControls__c postTax = MW_TriggerControls__c.getInstance('RentalPostTax');
    	System.debug(postTax);
      	if (postTax==null || postTax.Enabled__c) {
      		Avatax_MBW.postRentalFuture(new Set<Id>{rentalagreement.Id});	// BLL13a
      	}
    	
    }
    
    @AuraEnabled
    public static Id ContactForAccount(Id accountId) {
    	List<Account> alist = new List<Account>();
    	if (accountId!=null) alist = [select Id, PersonContactId, isPersonAccount from Account where Id=:accountId];
    	return alist.size()>0 ? alist[0].PersonContactId : null;
    }
    @AuraEnabled
    public static Id AccountForContact(Id contactId) {
    	List<Contact> clist = new List<Contact>();
    	if (contactId!=null) clist = [select Id, AccountId from Contact where Id=:contactId];
    	return clist.size()>0 ? clist[0].AccountId : null;
    }
    
    @AuraEnabled
    public static Id UsersDefaultLocation() {
    	User u = CurrentUserSingleton.getInstance();
    	List<dealer__Dealer_Location__c> locs = [select Id, Name from dealer__Dealer_Location__c where dealer__Company_Number__c=:u.Division];
    	return locs.size()>0 ? locs[0].Id : null;
    }

	// BLL3
	public class RentalPostingException extends Exception {}
	// BLL3

}