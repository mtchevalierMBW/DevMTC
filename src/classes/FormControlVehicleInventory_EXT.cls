/**
 * FormControlVehicleInventory_EXT
 * Tested by: FormControlVehicleInventory_EXT_TEST
 *
 */

public with sharing class FormControlVehicleInventory_EXT {
    private ApexPages.StandardController stdController;
    public dealer__Vehicle_Inventory__c vehicle {get;private set;}
    public dealer__Dealer_Location__c location {get;private set;}
    public dealer__Deal__c deal {get;private set;}	// used to allow "deal" forms for vehicles
    
    public FormControlVehicleInventory_EXT(ApexPages.StandardController ctlr) {
		List<String> fields = new List<String>();
		DescribeSObjectResult descVI = dealer__Vehicle_Inventory__c.getSObjectType().getDescribe();
		fields.addAll(descVI.fields.getMap().keySet());
		if(!Test.isRunningTest() && fields.size()>0) ctlr.addFields(fields);

		vehicle = (dealer__Vehicle_Inventory__c) ctlr.getRecord();
		System.debug(vehicle);
		stdController = ctlr;

		location = loadVehicleLocation(vehicle);
		deal = transientDeal(vehicle);	    

	}
	
	// create a dummy deal object so any form references to "deal." will not fail, but won't return any data
	private dealer__Deal__c transientDeal(dealer__Vehicle_Inventory__c v) {
		dealer__Deal__c d = new dealer__Deal__c(dealer__Mileage__c=null);
		d.dealer__Vehicle__c = v.Id;
		return d;
	}
	
	
	// get the full list of fields from the location object associated with this vehicle
	private dealer__Dealer_Location__c loadVehicleLocation(dealer__Vehicle_Inventory__c v) {
		Id locId = v.dealer__Store_Location__c;
		System.debug(locId);
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
				+ ' where Id=\'' + locId + '\' '
				+ ' limit 1 ';
		System.debug(soql);
		return Database.query(soql);
	}
	
	@RemoteAction 
    public static String compileFDF(String fd) {
    	System.debug(fd);
		Map<String, Object> js = (Map<String, Object>)JSON.deserializeUntyped(fd);
		System.debug(js);
		String formId = (String)js.get('form');
		System.debug(formId);
		String objId = (String)js.get('obj');
		System.debug(objId);
		String urlPR = '/apex/FormFDFVehicle?id='+objId+'&fid='+formId;

		PageReference p = new PageReference(urlPR);
		Blob uContetent = p.getContent();

		return uContetent.toString();
	}
	
}