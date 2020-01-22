/**
 * AccountsSingleton
 * Tested by: DealProcess_TEST  // ? AccountsSingleton_TEST
 * Date: Jan 25, 2018
 * Programmer: Bryan Leaman
 *
 * Disable external id (Client Id) as it's not used and would likely be a non-selective query
 * as ClientId isn't indexed because it's a formula. Might need to reference the source fields
 * of the formula instead. Ensure selective query (doesn't include null in lookup ids).
 */
public with sharing class AccountsSingleton {

    public static AccountsSingleton single;
    public Set<Id> ids;
    //public Set<String> externalIds;
    public Map<Id,Account> idMap;
    //public Map<String,Account> externalIdMap;

    // AccountsSingleton
    //---------------------------------------
    public AccountsSingleton() {
        ids = new Set<Id>();
        //externalIds = new Set<String>();
    }

    public static AccountsSingleton getInstance() {
        if (single==null) single = new AccountsSingleton();
        return single;
    }

    public void addIds(List<Id> idlist) {
        addIds(new Set<Id>(idlist));
    }

    public void addIds(Set<Id> idset) {
        System.debug(idset);
		System.debug(idMap);
        if (idMap!=null && !idMap.keySet().containsAll(idset)) {
			System.debug('Reset idMap');
			idMap=null;
		}
        ids.addAll(idset);
        System.debug(idMap);
        System.debug(ids);
    }
    
    //public void addExternalIds(List<String> extidlist) {
    //  addExternalIds(new Set<String>(extidlist)); 
    //}
    
    //public void addExternalIds(Set<String> extidset) {
    //  System.debug(extidset);
    //  if (externalIdMap!=null && !externalIdMap.keySet().containsAll(extidset)) idMap = null;
    //  externalIds.addAll(extidset);
    //  System.debug(idMap);
    //  System.debug(externalIds);
    //}

    public void retrieveAccounts() {
        System.debug('retrieveAccounts');
        System.debug(ids);
        ids.remove(null);
        //System.debug(externalIds);
        //externalIds.remove(null);
        if (idMap==null) {
            // Select all fields from Account
            Map<String, Schema.SObjectField> objFieldMap =  Schema.Account.SObjectType.getDescribe().fields.getMap();
            List<String> objFieldList = new List<String>();
            for(string f : objFieldMap.keySet()) /* if (objFieldMap.get(f).getDescribe().isAccessible()) */ objFieldList.add(f);
            if (Schema.SObjectType.Account.getRecordTypeInfosByName().size()>1) {
                objFieldList.add('recordtype.name');
            }
            String objfields = String.join(objFieldList,',');

            String soql = 'select ' + objfields + ' from Account ';
            String junct = ' WHERE ';
            if (ids.size()>0) {
                System.debug(ids);
                soql += junct + ' Id in :ids ';
                junct = ' or ';
            } 
            //if (externalIds.size()>0) {
            //  System.debug(externalIds);
            //  soql += junct + ' ClientId__c in :externalIds ';
            //  junct = ' or ';
            //}
			List<Account> objlist = new List<Account>();
            if (ids.size()>0) {
				System.debug('retrieveAccounts: (soql) ' + soql);
				objlist = Database.query(soql);
			}
            System.debug(objlist);
            idMap = new Map<Id,Account>();
            //externalIdMap = new Map<String,Account>();
            for(Account obj : objlist) { 
                idMap.put(obj.Id, obj);
                //externalIdMap.put(obj.ClientId__c, obj);
            } 
            ids.addAll(idMap.keySet());
            //externalIds.addAll(externalIdMap.keySet());
            System.debug(idMap);
            //System.debug(externalIdMap);
        }
    }

    public Account getById(Id objid) {
        if (idMap==null) retrieveAccounts();
        System.debug(objid); System.debug(idMap.get(objid));
        return idMap.get(objid);
    }

    //public Account getByExternalId(String extid) {
    //  if (idMap==null) retrieveAccounts();    // the id map controls whether retrieval has run & is up-to-date 
    //  System.debug(extid); System.debug(externalIdMap.get(extid));
    //  return externalIdMap.get(extid);
    //}

}