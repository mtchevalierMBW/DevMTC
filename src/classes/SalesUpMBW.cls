/**
 * SalesUpMBW
 * Tested by: SalesUpMBW_TC 
 *
 * Coverage:
 *	2018-08-30	81% (93/114)
 *
 * Modifications:
 *	2015-08-12	B. Leaman	BLL1  Location missing from new sol. opps except when created via
 *           				lead conversion. Add to screen, default from account, then logged-in user.
 *	2015-09-04	B. Leaman	BLL2 updateCustInfo method and other support for B2B; auto-fill-in contact info for B2B.
 *	2016-03-09   RedTeal     RT1  - Set a default value for decision dates
 *	2016-07-29	B. Leaman	BLL3 use CurrentUserSingleton.
 *	2017-02-13	B. Leaman	BLL4 - recognize RecordType parameter and set based on customer type. Also new Buyer Contact field.
 */
public with sharing class SalesUpMBW {
    public dealer__Sales_Up__c sup;
    public Map<String, String> urlParameters = new Map<String, String>();
    public String personsAccountReference;
    public Id accountId = null; // BLL2a
    public Id contactId = null; // BLL2a
    public Id contactAcctId = null; // BLL2a
    private ApexPages.standardController ctlr = null;
	// BLL4a
	transient Map<String, Schema.RecordTypeInfo> SupRcdTypes;
	transient Schema.RecordTypeInfo RetailSupRt;
	transient Schema.RecordTypeInfo CommercialSupRt;
	private Id RetailRtId;
	private Id CommercialRtId;
	// BLL4a end
    
    public SalesUpMBW(ApexPages.standardController controller) {
    	ctlr = controller;
        sup = (dealer__Sales_Up__c)controller.getRecord();
        Account a = null;

        // BLL4a
	 	SupRcdTypes = Schema.SObjectType.dealer__Sales_Up__c.getRecordTypeInfosByName();
	 	System.debug(SupRcdTypes);
		RetailSupRt = SupRcdTypes.get('Retail');
		System.debug(RetailSupRt);
		CommercialSupRt = SupRcdTypes.get('Commercial');
		System.debug(CommercialSupRt);
		if (RetailSupRt!=null) RetailRtId = RetailSupRt.getRecordTypeId();
		if (CommercialSupRt!=null) CommercialRtId = CommercialSupRt.getRecordTypeId();
		if (sup.Id==null) sup.dealer__Lead_Status__c = 'Pending';	// Default on new solution opportunities
		// BLL4a end 
		
        // Check Apex Get Variables and Assign Account
        if(ApexPages.currentPage()!=null) {
            urlParameters = ApexPages.currentPage().getParameters();
            for(String p : urlParameters.keySet()) {
                if(p.contains('_lkid')) {
                    personsAccountReference = urlParameters.get(p);
                    // BLL4d Account a = new Account();
                    String idKey = null;
                    if (!String.isBlank(personsAccountReference)) idKey=personsAccountReference.substring(0,3);
                    if(idKey=='003') {
                        //a = personsAccountContact(personsAccountReference);
                        a = accountFromContact(personsAccountReference);
                    } else if (idKey=='001') {
                        a = personsAccount(personsAccountReference);
                    }
                    if (a!=null) {  // BLL2a
	                    sup.dealer__Customer_Account__c=a.Id;
	                    //sup.dealer__Home_Phone__c = a.PersonHomePhone;  // BLL2d moved to updateCustInfo
	                    //sup.dealer__Mobile__c = a.PersonMobilePhone;    // BLL2d moved to updateCustInfo
	                    //sup.dealer__Email__c = a.PersonEmail;           // BLL2d moved to updateCustInfo
	                    sup.Company__c = a.Store_Location__c;  // BLL1a
                    } // BLL2a
                }
            }
        }

		// BLL4a
		if (a!=null && a.RecordType.Name=='Commercial') sup.RecordTypeId = CommercialRtId;
		else sup.RecordTypeId = RetailRtId;
		if (urlParameters.containsKey('RecordType')) {
			sup.RecordTypeId = urlParameters.get('RecordType');
		}
		// BLL4a end
		
        
        //RT1
        if(sup.Decision_Date__c == null) {
            sup.Decision_Date__c = Date.today().addDays(30);
        }

        sup.dealer__Salesperson_1__c = UserInfo.getUserId();
        // BLL1a begin if no location set, use current user's location
        if (sup.Company__c==null) {
        	//BLL3d User u = [select Id, Division from User where Id=:UserInfo.getUserId() limit 1];
        	User u = CurrentUserSingleton.getInstance();	// BLL3a
        	if (u.Division!=null) {
        		List<dealer__Dealer_Location__c> locs = [
        		    select Id, Name
        		    from dealer__Dealer_Location__c
        		    where dealer__Company_Number__c=:u.Division
        		];
        		if (locs.size()>0) {
        			sup.Company__c = locs[0].Id;
        		}
        	}
        }
        // BLL1a end block
        updateCustInfo(); // BLL2a
    }

    // BLL2 - replace personsAccountContact with accountFromContact - works for both B2B & B2C
    //public Account personsAccountContact(Id i) {
    //    return [ Select Id, FirstName, LastName, PersonHomePhone, PersonMobilePhone, PersonEmail, Store_Location__c 
    //             from Account where PersonContactId=:i limit 1];
    //}
    // BLL2a begin
    public Account accountFromContact(Id i) {
    	Id acctId = [select AccountId from Contact where Id=:i ].AccountId;
    	List<Account> accts =  [select Id, Name, FirstName, LastName, PersonHomePhone, PersonMobilePhone, PersonEmail, Store_Location__c,
    				RecordTypeId, RecordType.Name	// BLL4a
    	        from Account where Id=:acctId];
    	if (accts.size()==1) {
    		return accts[0];
    	}
    	return null;
    }
    // BLL2a end

    public Account personsAccount(Id i) {
        return [ Select Id, FirstName, LastName, PersonHomePhone, PersonMobilePhone, PersonEmail, Store_Location__c, 
    				RecordTypeId, RecordType.Name	// BLL4a
                 from Account where Id=:i limit 1];
    }   

    public Id lookupPersonsAccountId(Id i) {
        return [Select Id from Account where PersonContactId =:i ].Id;
    }

   
    // BLL2a begin
    public void updateCustInfo() {
    	Account a = null;
    	List<Contact> cs = new List<Contact>();
    	Contact c = null;
    	
    	try {
	    	if (sup.dealer__Customer_Account__c!=null) {
	    		System.debug('Lookup account');
	    		a = [
	    		    select Id, Name, isPersonAccount, personContactId, PersonEmail, PersonHomePhone, PersonMobilePhone
	    		    from Account where Id=:sup.dealer__Customer_Account__c
	    		    limit 1
	    		];
	    		System.debug(a);
	    	}
    	} catch(Exception erracct) {}

    	if (a!=null && accountId!=a.Id) { // change in account
    		if (c!=null && c.AccountId!=a.Id) {  // Clear out contact if account changed and isn't the contact's acct
    			sup.dealer__Buyer_Contact__c = null;
    			sup.BuyerContact__c = null;	// BLL4a
    		}
    		// Default contact if account changed and only has 1 contact
    		cs = [select Id, Name, AccountId from Contact where AccountId=:a.Id];
    		if (cs.size()==1) {
                System.debug('Set default contact');
    			sup.dealer__Buyer_Contact__c = cs[0].Id;
    			sup.BuyerContact__c = cs[0].Id;	// BLL4a
    			System.debug(cs[0]);
    		}
    	}

    	try{
	    	//BLL4d if (sup.dealer__Buyer_Contact__c!=null) {
            //BLL4d     System.debug('Get contact for ' + sup.dealer__Buyer_Contact__c);
	    	//BLL4d 	c = [
	    	//BLL4d 	    select Id, FirstName, LastName, Phone, Email, MobilePhone, AccountId
	    	//BLL4d 	    from Contact
	    	//BLL4d 	    where Id=:sup.dealer__Buyer_Contact__c
	    	//BLL4d 	];
	    	//BLL4d 	System.debug(c);
	    	//BLL4d }
	    	if (sup.BuyerContact__c!=null) {
                System.debug('Get contact for ' + sup.BuyerContact__c);
	    		c = [
	    		    select Id, FirstName, LastName, Phone, Email, MobilePhone, AccountId
	    		    from Contact
	    		    where Id=:sup.BuyerContact__c
	    		];
	    		System.debug(c);
	    	}
    	} catch(Exception errCont) {}
    	System.debug('ContactId='+contactId);
    	if (c!=null) System.debug('c.id='+c.Id);
    	if (c!=null && (contactId==null || contactId != c.Id)) { // change in contact
    		System.debug('c.AccountId='+c.AccountId);
    		if (a!=null) System.debug('a.Id='+a.Id);
    	    if (a==null || c.AccountId!=a.Id) {  // Reset account from contact
    	    	sup.dealer__Customer_Account__c = c.AccountId;
                System.debug('Assign customer account to account ' + c.AccountId);
    	    }
    	    sup.dealer__Email__c = c.Email;
    	    sup.dealer__Home_Phone__c = c.Phone;
    	    sup.dealer__Mobile__c = c.MobilePhone;
    	}
        accountId = sup.dealer__Customer_Account__c;
        //BLL4d contactId = sup.dealer__Buyer_Contact__c;
        contactId = sup.BuyerContact__c;
        contactAcctId = (c!=null) ? c.AccountId : null;
    }
    
    public boolean validRecord() {
    	boolean valid=true;
    	updateCustInfo();
    	if (contactId==null) {
    	   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Buyer Contact is required'));
    	   valid = false;
    	} else if (accountId==null && contactId!=null) {
    	   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Buyer Contact does not belong to an Account'));
    	   valid = false;
    	} else if (contactAcctId!=accountId) {
    	   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Buyer Contact does not belong to the selected Account'));
    	   valid = false;
    	}
    	return valid;
    }
    
    public ApexPages.PageReference save() {
    	// BLL4a - Fill in record type Id
    	Account a = null;
    	if (sup.RecordTypeId==null || sup.Id==null) {	// always auto-assign record type on first save
    		try {
    			a = [select Id, RecordTypeId, RecordType.Name from Account where Id=:sup.dealer__Customer_Account__c limit 1];
    			if (CommercialRtId!=null && a.RecordType.Name=='Commercial') sup.RecordTypeId = CommercialRtId;
	    		else if (RetailRtId!=null) sup.RecordTypeId = RetailRtId;
    		} catch(Exception e) { }
    	}
    	// BLL4a
    	if (validRecord()) {
			sup.dealer__Buyer_Contact__c = sup.BuyerContact__c;	// BLL4a
    		return ctlr.save();
    	} else {
    		return null;
    	}
    }
    // BLL2a end
    
}