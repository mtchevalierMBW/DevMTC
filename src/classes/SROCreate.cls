/**
 * SROCreate
 * Tested by: SROCreate_TC
 *
 * 2015-08-18	B. Leaman	BLL1 - get account by contact Id *or* account Id! It's not always a person account!
 * 2015-09-19	J. Kuljis	JVK1 - Link inventory recoed if not selected but is related to a service vehicle.
 * 2015-09-25   B. Leaman   BLL2 - error handling to provide info when parms are not valid ids - commented out for now
 * 2016-10-12	D. Ray    	DR1  - Render a lookup then this is a B2B account
 * 2016-01-27   J. Kuljis   JVK2 - Code set to use the managed RO Index from the custom setting.
 * 2016-04-12	B. Leaman	BLL3 IT#18207 - Allow creation of an RO from the vehicle (inventory or service)
 * 2016-07-29	B. Leaman	BLL4 Use CurrentUserSingleton instead of SOQL.
 * 2016-11-23	B. Leaman	BLL5 - Allow creation of RO from service vehicle page even if there is no owner on the vehicle.
 * 2016-12-21	B. Leaman	BLL6 - Don't generate RO number - it's now in a DealerTeam managed trigger.
 * 2017-07-13	B. Leaman	BLL7 - Fix saving new RO after changing company (in another tab).
 * 2019-09-20	B. Leaman	W-000730 BLL8 - DT 5.x upgrade
 */
public with sharing class SROCreate {
    public Boolean showContact {get; set;}  // /DR1a

    public dealer__Service_Repair_Order__c sro {get;set;}
    public Map<String, String> urlParameters = new Map<String, String>();
    public SROCreate(ApexPages.StandardController sc) {

        showContact = false; // DR1b - dont show contact by default

        sro = (dealer__Service_Repair_Order__c)sc.getRecord();

        // Set the company
        //BLL4d User u = [Select Id, Division from User where Id=:UserInfo.getUserId() limit 1];
        User u = CurrentUserSingleton.getInstance();	// BLL4a

        system.debug(u.Division);
        system.debug(database.query('Select Id, Name, dealer__Company_Number__c from dealer__Dealer_Location__c'));

        dealer__Dealer_Location__c loc = [Select Id, Name, dealer__Company_Number__c from dealer__Dealer_Location__c where dealer__Company_Number__c =:u.Division limit 1];
        sro.dealer__Company__c = loc.Id;
        sro.dealer__Company_Number__c = loc.dealer__Company_Number__c;
        sro.dealer__Service_Advisor__c = UserInfo.getUserId();
        //BLL8 sro.dealer__RO_Number__c = 'TEMP';

        if(ApexPages.currentPage()!=null) {
        	//try { // BLL2a
	            urlParameters = ApexPages.currentPage().getParameters();
	            for(String p : urlParameters.keySet()) {
	                // Allow for Customer and Vehicle to be passed as ID's
	                if(p=='customer') {
	                    if (!String.isBLank(urlParameters.get(p))) sro.dealer__Customer__c = urlParameters.get(p);	// BLL5a check for missing id
	                }
	                if(p=='vehicle') {
	                    sro.dealer__Vehicle__c = urlParameters.get(p);
	                }
	                if(p.contains('_lkid')) {
	                	Id refId = urlParameters.get(p);
	                	if (Schema.Account.SObjectType==refId.getSObjectType() || Schema.Contact.SObjectType==refId.getSObjectType()) {	// BLL3a
		                    sro.dealer__Customer__c = lookupPersonsAccountId(urlParameters.get(p));
	                        // DR1d
	                        if( sro.dealer__Customer__c != null && sro.dealer__Customer__r.isPersonAccount != null && sro.dealer__Customer__r.isPersonAccount == false){
	                            showContact = true;
	                        }
	                        // DR1d
						}	// BLL3a
						// BLL3a
						if (Schema.dealer__Vehicle_Inventory__c.SObjectType==refId.getSObjectType()) {
							VehicleInventoryReferences(refId);
						}
						if (Schema.dealer__Service_Vehicle__c.SObjectType==refId.getSObjectType()) {
							ServiceVehicleReferences(refId);
						}
						// BLL3a
	                }
	            }
	        // BLL2a begin
        	//} catch(Exception e) {
        	//	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        	//	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, ApexPages.CurrentPage().getUrl()));
        	//	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, ApexPages.CurrentPage().getHeaders().get('Referrer')));
        	//}
        	// BLL2a end
        }
    }

    public PageReference save() {

		// BLL6d
        //dealer__FixedOperationsSettings__c fixedOpsSettings = dealer__FixedOperationsSettings__c.getOrgDefaults();
        //Decimal roIndexCurrent = fixedOpsSettings.dealer__Repair_Order_Index__c.setScale(0);
        //roIndexCurrent++;
        //sro.dealer__RO_Number__c = String.valueOf(roIndexCurrent);  //JVK2

        // Issue with index curruption, check for the next available sequence
        // We believe the end user is clicking the save button twice and this results in two RO Creation processes.
        // Save button is dissabled after click
        //dealer__Service_Repair_Order__c[] indexCheck = [Select Id from dealer__Service_Repair_Order__c where dealer__RO_Number__c =: sro.dealer__RO_Number__c limit 1];
        //if(indexCheck.size()>0) {
        //    roIndexCurrent++;
        //    sro.dealer__RO_Number__c = String.valueOf(roIndexCurrent);
        //}
        // BLL6d

		// BLL7a - need to reset company number in case company changed in another tab
		// If we don't then the RO name will reflect the original company number but the
		// location will reflect the new one.
        User u = CurrentUserSingleton.getInstance();
        dealer__Dealer_Location__c loc=null;
        if (sro.dealer__Company__c!=null) loc = [Select Id, Name, dealer__Company_Number__c from dealer__Dealer_Location__c where Id =:sro.dealer__Company__c limit 1];
        if (loc!=null) sro.dealer__Company_Number__c = loc.dealer__Company_Number__c;
        else sro.dealer__Company_Number__c = null;
        if (String.isBlank(sro.dealer__Company_Number__c)) sro.dealer__Company_Number__c = u.Division;
        System.debug(u);
        System.debug(sro.dealer__Company_Number__c);
        System.debug(sro.dealer__Company__c);
        // BLL7a end

        sro.Name = 'RO#'+sro.dealer__Company_Number__c+'-';		// BLL6c +sro.dealer__RO_Number__c;
        sro.dealer__Taxable__c = false;

        // If Vehicle Inventory is Present, auto set the Service Vehicle
        if(sro.dealer__Vehicle_Inventory__c != null && sro.dealer__Vehicle__c == null) {
            dealer__Service_Vehicle__c[] sv = [Select Id, dealer__Last_Odometer__c from dealer__Service_Vehicle__c where dealer__Sales_Inventory__c =:sro.dealer__Vehicle_Inventory__c limit 1];
            if(sv.size()==1) {
                sro.dealer__Vehicle__c = sv[0].Id;
                if(sro.dealer__Mileage_In__c == null || sro.dealer__Mileage_In__c == 0) {
                    sro.dealer__Mileage_In__c = sv[0].dealer__Last_Odometer__c;
                }
            }
        }

        // JVK1
        // If Service Vehicle Is Present, check for the Vehicle Inventory Record
        if(sro.dealer__Vehicle_Inventory__c == null && sro.dealer__Vehicle__c != null) {
            dealer__Service_Vehicle__c[] invC = [Select Id, dealer__Sales_Inventory__c from dealer__Service_Vehicle__c where Id=:sro.dealer__Vehicle__c limit 1];
            if(invC.size()>0) {
                sro.dealer__Vehicle_Inventory__c=invC[0].dealer__Sales_Inventory__c;
            }
        }
        // JVK1

        try {
            insert sro;
        //BLL6d    fixedOpsSettings.dealer__Repair_Order_Index__c = roIndexCurrent; //JVK2
        //BLL6d    update fixedOpsSettings;
        } catch(DmlException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;            
        }

        PageReference roPage = new ApexPages.StandardController(sro).view();
        roPage.setRedirect(true);
        return roPage;
    }

    public Id lookupPersonsAccountId(Id i) {
    	// BLL1a handle either account Id *or* contact Id and don't require it to be a person account
    	Account[] a = new List<Account>();
    	if (Schema.Account.SObjectType == i.getSObjectType()) {
    		a = [select Id from Account where Id=:i limit 1];
    	} else if (Schema.Contact.SObjectType == i.getSObjectType()) {
    		try {
    		    Contact c = [select Id, AccountId from Contact where Id=:i limit 1];
    		    a = [select Id from Account where Id=:c.AccountId limit 1];
    		} catch(Exception e) {}
    	}
    	// BLL1a end block
        //Account[] a = [Select Id from Account where PersonContactId =:i or Id=:i limit 1];  // BLL1d
        if(a.size()==0) {
            throw new ROCreateException('Customer Account not found');
        }
        return a[0].Id;
    }  

	// BLL3a
	// VehicleInventoryReferences
	public void VehicleInventoryReferences(Id vehId) {
		try {
			dealer__Vehicle_Inventory__c veh = [
				select Id, dealer__In_Stock__c, dealer__Mileage__c
				from dealer__Vehicle_Inventory__c
				where Id=:vehId
			];
			sro.dealer__Vehicle_Inventory__c = veh.Id;
			List<dealer__Service_Vehicle__c> srvVehs = [
				select Id 
				from dealer__Service_Vehicle__c
				where dealer__Sales_Inventory__c=:veh.Id
				order by dealer__Last_Odometer__c desc
			];
			if (srvVehs.size()>0) ServiceVehicleReferences(srvVehs[0].Id);
		} catch(Exception e) {
			throw new ROCreateException('Could not find inventory vehicle');
		}
	}
	
	// ServiceVehicleReferences
	public void ServiceVehicleReferences(Id svId) {
		try {
			dealer__Service_Vehicle__c srvVeh = [
				select Id, dealer__Sales_Inventory__c, dealer__Veh_Owner__c, dealer__Veh_Owner_Contact__c
				from dealer__Service_Vehicle__c
				where Id=:svId
			];
			sro.dealer__Customer__c = srvVeh.dealer__Veh_Owner__c;
			sro.dealer__Customer_Contact__c = srvVeh.dealer__Veh_Owner_Contact__c;
			sro.dealer__Vehicle__c = srvVeh.Id;
			sro.dealer__Vehicle_Inventory__c = srvVeh.dealer__Sales_Inventory__c;
		} catch(Exception e) {
			throw new ROCreateException('Could not find service vehicle');
		}
	}
	// BLL3a end

    // DR1c - Show contact field if this is a B2B RO
    public void accountSelected() {

        List<Account> aList = [SELECT Id, isPersonAccount FROM Account WHERE Id =: sro.dealer__Customer__c LIMIT 1];
        if(aList.size() > 0) {
            System.debug(aList[0]);
            if( aList[0].isPersonAccount == false){
                showContact = true;
            }
        }   

    }
    // /DR1c

    public class ROCreateException extends Exception{}     
}