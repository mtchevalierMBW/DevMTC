/**
 * SelectDealership
 * Tested by: SelectDealership_TC
 * 
 *	2016-05-02	B. Leaman	BLL1 - Sort locations by name so they're easier to find.
 *	2016-07-29	B. Leaman	BLL2 Use CurrentUserSingleton instead of SOQL.
 *	2017-02-09	B. Leaman	BLL3 - comment out use of the general_manager__c and service_manager__c fields on the user object.
 *  2017-02-13  J. Pritt    JRP1 - change sql to extract street rater than address for location
 */
public without sharing class SelectDealership {

    public String selectedDealershipId {get;set;}
    public Integer numberOfLocations {get;set;}

    public SelectDealership() {
        // Get number of dealerships available to the user in this context
        //BLL3d numberOfLocations = [Select Count() from Dealer_Location_Users__c Where User__c=:UserInfo.getUserId()];
        numberOfLocations = [Select Count() from dealer__Dealer_Location_User__c Where dealer__User__c=:UserInfo.getUserId()];	// BLL3a
    }

    public List<dealer__Dealer_Location__c> getmyDealerships() {
        List<dealer__Dealer_Location__c> dealershipList = new List<dealer__Dealer_Location__c>();
        //BLL3d List<Dealer_Location_Users__c> availableLocations = [select Id, Dealer_Location__c from Dealer_Location_Users__c where User__c=:UserInfo.getUserId() limit 500];
        List<dealer__Dealer_Location_User__c> availableLocations = [select Id, dealer__Dealer_Location__c from dealer__Dealer_Location_User__c where dealer__User__c=:UserInfo.getUserId() limit 500];	// BLL3a
        Set<Id> dealershipLocationIds = new Set<Id>();

        //BLL3d for(Dealer_Location_Users__c dl : availableLocations) {
        //BLL3d     dealershipLocationIds.add(dl.Dealer_Location__c);
        //BLL3d }
        for(dealer__Dealer_Location_User__c dl : availableLocations) dealershipLocationIds.add(dl.dealer__Dealer_Location__c);	// BLL3a

        if(dealershipLocationIds.size()>0) {
            dealershipList = [SELECT dealer__Street__c, dealer__City__c, dealer__Company_Number__c, dealer__Email__c, dealer__General_Manager__c,
                                 dealer__Main_Phone__c, dealer__Physical_Location__Latitude__s, dealer__Physical_Location__Longitude__s, 
                                 dealer__Physical_Location__c, dealer__Postal_Code__c, dealer__Service_Director__c, dealer__State__c, 
                                 dealer__Website__c, Tax_Labor__c, Tax_Parts__c, Tax_Rate_Default__c, Customer_Pay_Labor_Rate__c, 
                                 Internal_Labor_Rate__c, Doc_Fee__c, Title_Fee__c, Tag_Fee__c, Electronic_Filing_Fee__c, Sales_Admin__c, 
                                 Id, Name 
                                FROM dealer__Dealer_Location__c
                                Where Id IN:dealershipLocationIds
                                Order by Name	// BLL1a
                                Limit 500];
        } else {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'You are not associated with Any Dealerships, Contact your Systems Administrator(s)');//Same old drama 
            ApexPages.addMessage(myMsg);
            return null;            
        }

        return dealershipList;
    }

    public PageReference chooseDealership() {
        if(selectedDealershipId==null) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'The Selected ID is NULL');//Same old drama 
            ApexPages.addMessage(myMsg);
            return null;            
        }   

        dealer__Dealer_Location__c d = [
        	select Id, Name, dealer__Company_Number__c	// BLL3d , dealer__General_Manager__c, dealer__Service_Director__c 
        	from dealer__Dealer_Location__c where Id=:selectedDealershipId limit 1
        ];
        //BLL2d User me = [Select Id, Division from User where Id=:UserInfo.getUserId() limit 1];
        User me = CurrentUserSingleton.getInstance();	// BLL2a

        me.Division                 =   d.dealer__Company_Number__c;
        me.Dealership_Location__c   =   d.Name; 

		// BLL3d
        //if(d.dealer__Service_Director__c!=UserInfo.getUserId()) {
        //    me.service_manager__c = d.dealer__Service_Director__c;
        //} 

        //if(d.dealer__General_Manager__c!=UserInfo.getUserId()) {
        //    me.General_Manager__c = d.dealer__General_Manager__c;
        //}
        // BLL3d end
        
        update me;

        PageReference sd = Page.SelectDealership;
        sd.setRedirect(true);
        return sd;
    }
}