/**
 * UploadReferenceHelper
 * Tested by: UploadReferenceHelper_TEST
 * 
 * Generic way to get Id references (and other fields) using a name or external key lookup
 * into another Salesforce object.
 *
 * usage example:
 *	// To find account reference
 *	trigger ExampleObjTrigger on MyObj (before insert) {
 *		// Lookup values of the MyObj.upload_Account__c field in the Account object field ExternId__c
 *		// and store the Account.Id to MyObj.Account__c
 *		UploadReferenceHelper urh = new UploadReferenceHelper('upload_Account__c', 'Account', 'ExternId__c', 
 *			new Map<String,String>{'Account__c'=>'Id'});
 *			// map indicates that the Account.Id field should be stored in the MyObj.Account__c field.
 *		urh.retainReferenceValues(new Set<String>({'upload_Account__c'}));  // Don't remove the upload_Account__c values
 *		urh.updAllReferences(Trigger.new);
 *	}
 */
public with sharing class UploadReferenceHelper {

	Map<String,String> fieldMap = null;
	String refField = null;
	String extField = null;
	String objectName = null;
	String whereClause = ''; 
	List<String> refList = new List<String>();
	Map<String,SObject> objMap = new Map<String,SObject>();
	public boolean retainReferenceValue = false;
	public boolean ignoreCaseOnLookup = true; 

	// constructor
	public UploadReferenceHelper(String refFld, String obj, String extFld, Map<String,String> fldMap) {
		refField = refFld;
		extField = extFld;
		objectName = obj;
		fieldMap = fldMap;
	}

	// addAllReferences
	// Collect list of lookup values specified 
	public void addAllReferences(List<SObject> objList) {
		if (objList.size()>0) System.debug(objList[0]);
		for(Sobject s : objList) {
			String ref = String.valueOf(s.get(refField));
			System.debug(ref);
			if (!String.isBlank(ref)) {
				refList.add(ref);
			}
		}
	}

	// setCustomCriteria
	// Used to add additional selection criteria when finding lookup values
	// particularly for things like record types where you have to limit the selection to
	// values for a specific object type.
	public void setCustomCriteria(String crit) {
		whereClause = crit;
	}

	// getReferenceData
	// Query the lookup object for rows matching the lookup values we need
	public void getReferenceData() {
		String soql = 'select ';
		// add the external lookup field and each mapped field to soql stmt
		soql += extField + ', ' + String.join(fieldMap.values(), ',');
		soql += ' from ' + objectName;
		// Just pull the records matching our current list of lookup values
		soql += ' where ';
		if (!String.isBlank(whereClause)) {
			soql += whereClause + ' and ';
		} 
		soql += ' ' + extField + ' in (\'' + String.join(refList, '\',\'') + '\') ' ;
		System.debug(soql);
		List<SObject> queryresults = Database.query(soql);
		for(SObject o : queryresults) {
			String key = ignoreCaseOnLookup ? String.valueOf(o.get(extField)).toLowerCase() : String.valueOf(o.get(extField)); 
			objMap.put(key, o);
		}
	}

	// updAllReferences
	// Update all reference fields from lookup objects
	public void updAllReferences(List<SObject> objList) {

		if (refList.size()==0) addAllReferences(objList);
		if (objMap.size()==0) getReferenceData();
		
		// Only bother if there's something to replace!
		if (objMap.size()>0) {
			for(SObject s : objList) {
				String key = ignoreCaseOnLookup ? String.valueOf(s.get(refField)).toLowerCase() : String.valueOf(s.get(refField));
				// Only bother if there is a value to lookup!
				if (!String.isBlank(key)) { 
					SObject o = objMap.get(key);
					// Only set the mapped fields if we found something
					if (o!=null) {
						for(String k : fieldMap.keySet()) {
							s.put(k, o.get(fieldMap.get(k)));
						}
					}
					// Clear out the lookup value unless set to retain
					// Clearing the value prevents future update from resetting these fields again to the reference originally set!
					if (!retainReferenceValue) s.put(refField, null);
				} // key is not blank
			} // for objList
		} // have values to map
	}

}