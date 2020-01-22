/**
 * 
 * 2016-02-09   RedTeal     RT1  - Edited queries to include proposal number
 * 2016-03-02	Jarrett		JVK2 - Reduced the SOQL limit statement to fix the viewstate error
 * 2016-08-02	J. Kuljis	JVK3 - Add line urgency = null to filter criteria
 */
public with sharing class CentralizedParts {

	List<dealer__Dealer_Location__c> locations = new List<dealer__Dealer_Location__c>();
	Id queueId {get;set;}

	public Map<String,List<String>> userSetMap = new Map<String,List<String>>();
	//public String userSettings {get;set;}

	public List<String> getMasterMFGList {get;set;}
	public Boolean otherSelected {get;set;}
	public List<String> otherList {get;set;}

	public Id acceptedId {get;set;}

	public CentralizedParts() {
		
		// Other Selected defaulted to OFF
		otherSelected = false;
		otherList = new List<String>();

		// Get Open Locations
		locations = [select Id, Name,  dealer__Address__c, dealer__City__c, dealer__State__c,
                                   dealer__Postal_Code__c, Country__c, 
                                   dealer__Physical_Location__Latitude__s, dealer__Physical_Location__Longitude__s
                            from  dealer__Dealer_Location__c where Centralized_Purchasing_On_Off__c = true order by Name ASC];		

		// Get the Queue
		List<QueueSobject> q = [SELECT Id, QueueId FROM QueueSobject where SobjectType = 'dealer__Parts_Order__c' limit 1];
		if(q.size() == 0) {
			throw new CPTException('CPT Queue does not exist.');
		}

		queueId=q[0].QueueId;

		List<String> retString = new List<String>();
		/*
		List<AggregateResult> masterMFGList = [Select dealer__Manufacturer__c from dealer__Parts_Master__c group by dealer__Manufacturer__c limit 10000];
		for(AggregateResult ar : masterMFGList) {
			retString.add((String)ar.get('dealer__Manufacturer__c'));
		}
		*/
		retString.add('Other');

		retString.add('AMF');
		retString.add('ADC');
		retString.add('ADAPT');
		retString.add('BRA');
		retString.add('BRU');
		retString.add('BD');
		retString.add('CRES');
		retString.add('DM');
		retString.add('ELD');
		retString.add('EMC');
		retString.add('EZL');
		retString.add('FRE');
		retString.add('HM');
		retString.add('HVL');
		retString.add('INT');
		retString.add('INTER');
		retString.add('MBW');
		retString.add('MPD');
		retString.add('MPS');
		retString.add('PRI');
		retString.add('QST');
		retString.add('SL');
		retString.add('TWKS');
		retString.add('VMI');

		getMasterMFGList = retString;

		// *** Let's get the User serrting and process it into an easy to consume Map (Map<String,List<String>>)
		setupUserSettingMap();

	}

	/**
	 * Set "userSetMap". Needed to prevent too many queries via lazy loading
	 */
	private void setupUserSettingMap() {
		// Retreive current user settings
		CentralizedPartsSettings__c[] sett = [SELECT Id, User__c, Settings__c FROM CentralizedPartsSettings__c WHERE User__c =: UserInfo.getUserId() LIMIT 1 ];

		if( sett.size()>0 && sett[0].Settings__c != null && sett[0].Settings__c != '' ){

			// Parse the settings object
			Map<String, Object> pMap = (Map<String, Object>) JSON.deserializeUntyped(sett[0].Settings__c);
			//String userId = String.valueOf( pMap.get('userId') ) // placeholder 

			//stores
			userSetMap.put('stores', parseListObject( pMap, 'stores' ) );
			//manufacturers
			userSetMap.put('manufacturers', parseListObject( pMap, 'manufacturers' ) );
			//urgencies
			userSetMap.put('urgencies', parseListObject( pMap, 'urgencies' ) );

		} else {

			//Set Empty Lists to prevent Errors
			//stores
			userSetMap.put('stores', new List<String>() );
			//manufacturers
			userSetMap.put('manufacturers', new List<String>() );
			//urgencies
			userSetMap.put('urgencies', new List<String>() );
		}
	}

	/**
	 * Populate the other list with all the names of the manufacturers selected
	 * @param No Arguments
	 * @return Populates the List<String> of the selected Manufacturers
	 */
	private void otherAntiFilter() {

		// Check to see if other is Selected
		Boolean isSet = false;
		Set<String> mfgSet = new Set<String>();

		for(String s : getMasterMFGList) {
			if(s=='Other') {
				isSet=true;
			}

			mfgSet.add(s);
		}

		if(isSet==true) {

		Schema.DescribeFieldResult fieldResult = dealer__Parts_Master__c.dealer__Manufacturer__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

		   for( Schema.PicklistEntry f : ple) {
		   		if(!mfgSet.contains(f.getValue())) {
		      		otherList.add(f.getValue());
		      	}
		   }
		}
	}

	/**
	 * Takes the results of the user settings stored as JSON and sends them back in a List<String>
	 * @param  pMap [A Map that was pulled from the Database of user settings.]
	 * @return      [A list of strings.]
	 */
	private List<String> parseListObject(Map<String, Object> pMap, String listKey ){

		// Make sure "listKey" is a property of pMap
		if( pMap.containsKey(listKey) ) {
			// Cast Sub list from JSON
			List<object> tList = (List<object>) pMap.get( listKey );

			// Force to be a List of Strings for a cleaner Return
			List<String> daList = new List<String>();
			for(Object s : tList ) {
				daList.add( String.valueOf( s ) );
			}
			return daList;
		} else {
			return new List<String>();
		}

	}
	/**
	*
	*	Accept the Order 
	*
	*/
	public PageReference accept() {
		// Assign this order to the user who selected the Order
		dealer__Stock_Order__c so = [Select Id from dealer__Stock_Order__c where Id=:acceptedId limit 1];
		so.Accepted_Date__c=Datetime.now();
		so.dealer__Status__c='Incomplete';
		so.OwnerId=UserInfo.getUserId();

		List<dealer__Parts_Order__c> lines = [Select Id, OwnerId from dealer__Parts_Order__c where dealer__Order__c =: so.Id];
		for(dealer__Parts_Order__c ll : lines) {
			ll.OwnerId=UserInfo.getUserId();
		}

		try {
			
			update so;
			update lines;

		} catch(DmlException e) {
			throw new CPTException(e.getMessage());
			return null;
		}

		return new ApexPages.StandardController(so).view();
	}

	public List<dealer__Dealer_Location__c> getLocations() {

		return locations;
	}

	/*
		
		Order Priority - Order Date, Manufacturer.

		Parts Purchase Order button to be controlled by the store level configuration

	*/

	public List<dealer__Parts_Order__c> getOpenOrders() {

		otherAntiFilter();

		System.debug('getOpenOrders()');
		System.debug(userSetMap.get('manufacturers'));
		System.debug(otherList);

		// Removed and dealer__Parts_Line__c != null
		//RT1 - added proposal name and id to query

		return [SELECT dealer__Order_Date__c, dealer__Order_Status__c, dealer__Order__c, dealer__Order__r.Name, dealer__Parts_Inventory__c,	dealer__Parts_Inventory__r.Name, dealer__Order__r.dealer__Company__c,
						dealer__Parts_Line__c, dealer__Purchase_Order__c, dealer__Quantity_Ordered__c, dealer__Parts_Line__r.Name, dealer__Parts_Line__r.dealer__Pay_Type__c,
						Line_Urgency__c, Manufacturer__c, Owner.Name, Repair_Order_ID__c, Name, Id, dealer__Parts_Line__r.dealer__Job_Line__r.dealer__Service_Repair_Order__r.Deal__r.Name,
						dealer__Parts_Line__r.dealer__Job_Line__r.dealer__Service_Repair_Order__r.Deal__c, dealer__Purchase_Order__r.Name, Purchase_Order_Status__c 
						FROM dealer__Parts_Order__c 
						WHERE dealer__Purchase_Order__c = null 
						and OwnerId=:queueId
						
						AND dealer__Order__r.dealer__Company__c  in:  userSetMap.get('stores')
						AND ( Line_Urgency__c in:  userSetMap.get('urgencies') OR Line_Urgency__c = NULL ) //JVK3
						order by dealer__Order_Date__c ASC, Manufacturer__c ASC, dealer__Order__r.dealer__Company__c ASC
						limit 1000];

	}
	// AND ( Manufacturer__c in: userSetMap.get('manufacturers') or Manufacturer__c in : otherList ) // commented out of above query 8/31/2016 Dealerteam

	public List<dealer__Parts_Order__c> getIncomplete() {

		otherAntiFilter();

		System.debug('getIncomplete()');
		//RT1 - added proposal name and id to query
		return [SELECT dealer__Order_Date__c, dealer__Order_Status__c, dealer__Order__c, dealer__Order__r.Name, dealer__Parts_Inventory__c,	dealer__Parts_Inventory__r.Name, dealer__Order__r.dealer__Company__c,
						dealer__Parts_Line__c, dealer__Purchase_Order__c, dealer__Quantity_Ordered__c, dealer__Parts_Line__r.Name, dealer__Parts_Line__r.dealer__Pay_Type__c,
						Line_Urgency__c, Manufacturer__c, Owner.Name, Repair_Order_ID__c, Name, Id, dealer__Parts_Line__r.dealer__Job_Line__r.dealer__Service_Repair_Order__r.Deal__r.Name,
						dealer__Parts_Line__r.dealer__Job_Line__r.dealer__Service_Repair_Order__r.Deal__c, dealer__Purchase_Order__r.Name, Purchase_Order_Status__c  
						FROM dealer__Parts_Order__c 
						WHERE dealer__Purchase_Order__c = null 
						
						AND dealer__Order__r.dealer__Company__c  in:  userSetMap.get('stores')
						AND ( Line_Urgency__c in:  userSetMap.get('urgencies') OR Line_Urgency__c = NULL ) //JVK3
						AND OwnerId !=:queueId
						order by dealer__Order_Date__c ASC, Manufacturer__c ASC
						limit 1000];

	}	
	// AND ( Manufacturer__c in: userSetMap.get('manufacturers') or Manufacturer__c in : otherList ) // commented out of above query 8/31/2016 Dealerteam

	public List<dealer__Parts_Order__c> getInProcessOrders() {

		otherAntiFilter();

		System.debug('getInProcessOrders()');
		//RT1 - added proposal name and id to query

		return [SELECT dealer__Order_Date__c, dealer__Order_Status__c, dealer__Order__c, dealer__Order__r.Name, dealer__Parts_Inventory__c,	dealer__Parts_Inventory__r.Name, dealer__Order__r.dealer__Company__c,
						dealer__Parts_Line__c, dealer__Purchase_Order__c, dealer__Quantity_Ordered__c, dealer__Parts_Line__r.Name, dealer__Parts_Line__r.dealer__Pay_Type__c,
						Line_Urgency__c, Manufacturer__c, Owner.Name, Repair_Order_ID__c, Name, Id, dealer__Parts_Line__r.dealer__Job_Line__r.dealer__Service_Repair_Order__r.Deal__r.Name,
						dealer__Parts_Line__r.dealer__Job_Line__r.dealer__Service_Repair_Order__r.Deal__c, dealer__Purchase_Order__r.Name, Purchase_Order_Status__c 
						FROM dealer__Parts_Order__c 
						WHERE dealer__Purchase_Order__c != null 
						
						AND dealer__Order__r.dealer__Company__c  in:  userSetMap.get('stores')
						AND ( Line_Urgency__c in:  userSetMap.get('urgencies') OR Line_Urgency__c = null ) //JVK3
						and dealer__Parts_Line__c != null
						AND dealer__Purchase_Order__r.dealer__Accepted_DateTime__c = null
						order by dealer__Order_Date__c DESC, Manufacturer__c ASC
						limit 100];

	}
	// AND ( Manufacturer__c in: userSetMap.get('manufacturers') or Manufacturer__c in : otherList ) // commented out of above query - 8/31/2016 Dealerteam	

	public List<dealer__Parts_Order__c> getReceived() {

		otherAntiFilter();
		//RT1 - added proposal name and id to query

		return [SELECT dealer__Order_Date__c, dealer__Order_Status__c, dealer__Order__c, dealer__Order__r.Name, dealer__Parts_Inventory__c,	dealer__Parts_Inventory__r.Name, dealer__Order__r.dealer__Company__c,
						dealer__Parts_Line__c, dealer__Purchase_Order__c, dealer__Quantity_Ordered__c, dealer__Parts_Line__r.Name, dealer__Parts_Line__r.dealer__Pay_Type__c,
						Line_Urgency__c, Manufacturer__c, Owner.Name, Repair_Order_ID__c, Name, Id, dealer__Parts_Line__r.dealer__Job_Line__r.dealer__Service_Repair_Order__r.Deal__r.Name,
						dealer__Parts_Line__r.dealer__Job_Line__r.dealer__Service_Repair_Order__r.Deal__c, dealer__Purchase_Order__r.Name, Purchase_Order_Status__c 
						FROM dealer__Parts_Order__c 
						WHERE dealer__Purchase_Order__c != null
						
						AND ( Line_Urgency__c in:  userSetMap.get('urgencies')  OR Line_Urgency__c = null ) //JVK3
						AND dealer__Order__r.dealer__Company__c  in:  userSetMap.get('stores')
						AND dealer__Purchase_Order__r.dealer__Accepted_DateTime__c != null
						order by dealer__Order_Date__c ASC, Manufacturer__c ASC
						limit 30];
	}
	// AND ( Manufacturer__c in: userSetMap.get('manufacturers') or Manufacturer__c in : otherList ) // commented out of above query 8/31/2016 Dealerteam


	public List<dealer__Parts_Order__c> getMyOrders() {
		//RT1 - added proposal name and id to query

		return [SELECT dealer__Order_Date__c, dealer__Order_Status__c, dealer__Order__c, dealer__Order__r.Name, dealer__Parts_Inventory__c,	dealer__Parts_Inventory__r.Name, dealer__Order__r.dealer__Company__c,
						dealer__Parts_Line__c, dealer__Purchase_Order__c, dealer__Quantity_Ordered__c, dealer__Parts_Line__r.Name, dealer__Parts_Line__r.dealer__Pay_Type__c,
						Line_Urgency__c, Manufacturer__c, Owner.Name, Repair_Order_ID__c, Name, Id, dealer__Parts_Line__r.dealer__Job_Line__r.dealer__Service_Repair_Order__r.Deal__r.Name,
						dealer__Parts_Line__r.dealer__Job_Line__r.dealer__Service_Repair_Order__r.Deal__c, dealer__Purchase_Order__r.Name , Purchase_Order_Status__c
						FROM dealer__Parts_Order__c 
						WHERE dealer__Purchase_Order__c != null
						and OwnerId=:UserInfo.getUserId()
						order by dealer__Order_Date__c DESC, Manufacturer__c ASC
						limit 30];
	}	

	public List<String> getMasterMFG() {

		return getMasterMFGList;
	}	

	public String getuserSettings() {
		CentralizedPartsSettings__c[] sett = [SELECT Id, User__c, Settings__c FROM CentralizedPartsSettings__c WHERE User__c =: UserInfo.getUserId() LIMIT 1 ];

		if( sett.size()>0  && sett[0].Settings__c != null && sett[0].Settings__c != '' ){
			return sett[0].Settings__c;
		} else {
			return '{  "urgencies" : [ "Ground", "3 Day", "2 Day", "Overnight", "Saturday", "Saturday Overnight", "N/A", "Drop-Ship", "Vendor", "Transfer" ],  "manufacturers" : [ "Other", "AMF", "ADC", "ADAPT", "BRA", "MPD", "MPS", "QST", "SL", "VMI" ],  "stores" : [],  "tab" : "open"}'; // Return an empty JSON object string to prevent JS errors in View
		}
	}

    public PageReference refresh() {
    	// Update the User Settings Map before the tables are refreshed.
    	setupUserSettingMap();
    	return null;
    }

	@RemoteAction
	public static Boolean saveUserSelection(String oJson) {

		Map<String, Object> pMap = (Map<String, Object>) JSON.deserializeUntyped(oJson);
		String userId = String.valueOf( pMap.get('userId') );

		CentralizedPartsSettings__c[] sett = [SELECT Id, User__c, Settings__c FROM CentralizedPartsSettings__c WHERE User__c =: userId LIMIT 1 ];

		pMap.remove('userId');

		if( sett.size()>0 ){
			sett[0].Settings__c = JSON.serializePretty( pMap );
			update sett;

		} else {
			CentralizedPartsSettings__c cSett = new CentralizedPartsSettings__c(
				Settings__c = JSON.serialize( pMap ),
				User__c = userId
			);
			insert cSett;
		}

        return true;
    }

    
    /*
    Deprecated prior to release
     */
	//@RemoteAction
	//public static String mergeOrders(String oJson) {
	//	// PARSE JSON
	//	List<object> oList = (List<object>) JSON.deserializeUntyped(oJson);
	//	List<String> sList = new List<String>();
	//	for (object o : oList) {
	//		sList.add( (String) o  );
	//	}

	//	dealer__Parts_Order__c[] orders = [SELECT dealer__Back_Ordered__c, dealer__Depot__c, dealer__Line_Posted__c, dealer__Order_Date__c, dealer__Order_Status__c, dealer__Order__c, dealer__Order__r.Name, dealer__Parts_Inventory__c,
	//					dealer__Parts_Inventory__r.Name, dealer__Parts_Invoice__c, 
	//					dealer__Parts_Line__c, dealer__Purchase_Order__c, dealer__Quantity_Ordered__c, dealer__Received__c, dealer__Requested_By__c, dealer__Scan_Time__c, dealer__Value__c, 
	//					dealer__Parts_Master__c, dealer__Service_Job_Line__c, dealer__Parts_Line__r.Name, Line_Urgency__c, Manufacturer__c, Owner.Name, Repair_Order_ID__c, Name, Id 
	//					FROM dealer__Parts_Order__c 
	//					WHERE Id in: sList
	//					ORDER BY Manufacturer__c ASC, dealer__Parts_Line__r.Name ASC, CreatedDate DESC
	//					limit 3];

	//	List<dealer__Parts_Order__c> dups = new List<dealer__Parts_Order__c>();

	//	if(orders.size()==2){
	//		dups.add(orders[1]);
	//	} else if (orders.size()==3) {
	//		dups.add(orders[1]);
	//		dups.add(orders[2]);
	//	}

	//	// Merge accounts into the first returned
	//	try {
	//	    Database.merge(orders[0], dups);
	//	} catch (DmlException e) {
	//	    // Process exception
	//	    System.debug('An error occurred in mergeOrders: ' + e.getMessage()); 
 //       return '{"result":false,"error":"' + e.getMessage() + '"}';

	//	}

	//	/*
		
	//		if(orders.size()==2){

	//			try {
	//			    merge orders[0] orders[1];
	//			} catch (DmlException e) {
	//			    // Process exception
	//			    System.debug('An unexpected error has occurred: ' + e.getMessage()); 
	//			}

	//		} else if (orders.size()==3) {
	//			try {
	//			    merge orders[0] orders[1] orders[2];
	//			} catch (DmlException e) {
	//			    // Process exception
	//			    System.debug('An unexpected error has occurred: ' + e.getMessage()); 
	//			}

	//		}
	//	*/

 //       return '{"result":false,"error":"There was an Unknown Error."}';
 //   }


	public class CPTException extends Exception {}

}