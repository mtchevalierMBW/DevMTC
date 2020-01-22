/**
 * AccountTools
 * Tested by: AccountTools_TEST
 * Programmer: Bryan Leaman
 * Date: Feb 5, 2016
 * 
 *	2019-09-18	B. Leaman	W-000730 BLL1 - conversion tests failing with Winter 20 and DT 5.x
 */
public with sharing class AccountTools {
    
    // convertToBusinessAccount
    //----------------------------------------------------
	public static void convertToBusinessAccount(Id acctId) {
		Account a = [
		    select Id, RecordTypeId, OwnerId, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode,
		    	Email__c, dealer__Billing_Email__c, Phone, BusinessMobilePhone__c
		    from Account 
		    where Id=:acctId
		    limit 1
		];
		System.debug(a);	// BLL1a
		
		Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.Account.getRecordTypeInfosByName();
		System.debug(RcdTypes);
		Id personRtId = RcdTypes.get('PersonAccount').getRecordTypeId();
		Id businessRtId = RcdTypes.get('Business Account').getRecordTypeId();
		Id commercialRtId = RcdTypes.get('Commercial').getRecordTypeId();
		System.debug(personRtId);	// BLL1a
		System.debug(businessRtId);	// BLL1a
		System.debug(commercialRtId);	// BLL1a

		if (a.RecordTypeId==personRtId) {
		   Account upda = new Account(Id=a.Id, RecordTypeId=businessRtId);
		   update(upda);
		} else {
			throw new AccountException('Account ' + a.Name + ' (' + acctId + ') is already a business account.');
		}		
	}
	

    // convertToCommercialAccount
    //----------------------------------------------------
	public static void convertToCommercialAccount(Id acctId) {
		Account a = [
		    select Id, RecordTypeId, OwnerId, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode,
		    	Email__c, dealer__Billing_Email__c, Phone, BusinessMobilePhone__c
		    from Account 
		    where Id=:acctId
		    limit 1
		];
		System.debug(a);	// BLL1a
		
		Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.Account.getRecordTypeInfosByName();
		System.debug(RcdTypes);
		Id personRtId = RcdTypes.get('PersonAccount').getRecordTypeId();
		Id businessRtId = RcdTypes.get('Business Account').getRecordTypeId();
		Id commercialRtId = RcdTypes.get('Commercial').getRecordTypeId();
		System.debug(personRtId);	// BLL1a
		System.debug(businessRtId);	// BLL1a
		System.debug(commercialRtId);	// BLL1a
		
		if (a.RecordTypeId!=commercialRtId) {
		   Account upda = new Account(Id=a.Id, RecordTypeId=commercialRtId);
		   update(upda);
		} else {
			throw new AccountException('Account ' + a.Name + ' (' + acctId + ') is already a commercial account.');
		}		
	}
	
	
    // convertToPersonAccount
    //----------------------------------------------------
    public static void convertToPersonAccount(Id acctId) {
		Account a = [
		    select Id, RecordTypeId, OwnerId, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode,
		    	Email__c, dealer__Billing_Email__c, Phone, BusinessMobilePhone__c
		    from Account 
		    where Id=:acctId
		    limit 1
		];
		System.debug(a);	// BLL1a
		
		Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.Account.getRecordTypeInfosByName();
		System.debug(RcdTypes);
		Id personRtId = RcdTypes.get('PersonAccount').getRecordTypeId();
		Id businessRtId = RcdTypes.get('Business Account').getRecordTypeId();
		Id commercialRtId = RcdTypes.get('Commercial').getRecordTypeId();
		System.debug(personRtId);	// BLL1a
		System.debug(businessRtId);	// BLL1a
		System.debug(commercialRtId);	// BLL1a
		
		if(a.RecordTypeId==personRtId) {
			throw new AccountException('Account ' + a.Name + '(' + acctId + ') is already a person account.');
		}

		List<Contact> c = [select Id, FirstName, LastName, OwnerId from Contact where AccountId=:a.Id];
		if (c.size()>1) {
			System.debug('Wrong number of contacts: ' + String.valueOf(c.size()));
			throw new AccountException('Wrong number of contacts: ' + String.valueOf(c.size()));
		} else {
			if (c.size()==0) { // create a new contact
	       		// standardize name & guess at first/last split
	       		FullName fn = new FullName(a.Name);
	
				String eml = (String.isBlank(a.Email__c)!=true) ? a.Email__c : a.dealer__Billing_Email__c; 
	
	        	c.add(new Contact(
	           		AccountId=a.Id, OwnerId=a.OwnerId, FirstName=fn.FirstName, LastName=fn.LastName, 
	           		MailingStreet=a.BillingStreet, MailingCity=a.BillingCity, MailingState=a.BillingState, MailingPostalCode=a.BillingPostalCode,
	           		HomePhone=a.Phone, MobilePhone=a.BusinessMobilePhone__c, Email=eml
	        	));
	        	insert(c[0]);
	       }
	       if (c[0].OwnerId != a.OwnerId) {
	       		c[0].OwnerId = a.OwnerId;
	       		update(c[0]);
	       }
	       Account updacct = new Account(Id=a.Id, RecordTypeId=personRtId);
	       update(updacct);
	   }

    }

    
	// FullName
	//---------------------
    public class FullName {
    	String FirstName;
    	String LastName;
    	String MiddleName;
    	
    	public FullName(String name) {
			String fName = '';
			String lName = '';
		    String[] parts = new List<String>();
		    String[] nameParts = new List<String>();
	   	   	String prefix = '';
	   		String suffix = '';

			if (name!=null && name.length()>0) {
				parts = name.split(' ',0);
			}
	
	        for(Integer i = 0; i<parts.size(); i++) {
				if (parts[i].isAllUpperCase()) 	parts[i] = parts[i].toLowerCase().capitalize();
	       		else if(parts[i].isAllLowerCase())	parts[i] = parts[i].capitalize();
	        }
	                
	        // Find & save standard prefixes and suffixes
	        Set<String> pref = new Set<String>(new List<String> {'mr', 'mr.', 'mrs', 'mrs.', 'ms', 'ms.', 'miss' });
	        Set<String> suff = new Set<String>(new List<String> {'jr', 'jr.', 'sr', 'sr.', 'ii', 'iii', 'iv', '2nd', '3rd', '4th'}); 
	        for(Integer i=0; i<parts.size(); i++) {
	           if (pref.contains(parts[i].toLowerCase())) {
	               prefix = prefix + parts[i] + ' '; 
	           } else if (suff.contains(parts[i].toLowerCase())) {
	               suffix = suffix + parts[i] + ' '; 
	           } else {
	              nameParts.add(parts[i]);
	           }
	        }
	        System.debug(parts);
	        System.debug(nameParts);
	                
	        // Divide into first & lastnames
			if (nameParts.size()>0) {
		        if (nameParts.size()==1) {
		            fName = nameParts[0];
		            lName = null;
		        } else {
		            fName = nameParts[0];
		            lName = '';
		            for(Integer i=1; i<nameParts.size()-1; i++) {
		                if (i<3) fName += ' ' + nameParts[i];
		                else lName += nameParts[i] + ' ';
		            }
		            lName += nameParts[nameParts.size()-1];
		        }
		        fName = (prefix + ' '  + fName).trim();
		        lName = (lName + ' ' + suffix).trim();
		        FirstName = fName;
		        LastName = lName;
		        MiddleName = null;
			}
    	}
    }
    
	public class AccountException extends Exception {}

}