/**
 * GeneralLedgerAccountsSingleton
 * Tested by: FFATests  // ? GeneralLedgerAccountsSingleton_TEST
 * Date: Apr 14, 2019
 * Programmer: Bryan Leaman
 *
 */
public with sharing class GeneralLedgerAccountsSingleton {

    public static GeneralLedgerAccountsSingleton single;
    public Set<Id> ids;
    public Map<Id,c2g__codaGeneralLedgerAccount__c> idMap;
	public Set<String> reportingCodes;
    public Map<String,c2g__codaGeneralLedgerAccount__c> reportingCodeMap;

    // GeneralLedgerAccountsSingleton
    //---------------------------------------
    public GeneralLedgerAccountsSingleton() {
        ids = new Set<Id>();
        reportingCodes = new Set<String>();
    }

    public static GeneralLedgerAccountsSingleton getInstance() {
        if (single==null) single = new GeneralLedgerAccountsSingleton();
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
    
    public void addReportingCodes(List<String> codes) {
      addReportingCodes(new Set<String>(codes)); 
    }
    
    public void addReportingCodes(Set<String> codes) {
      System.debug(codes);
      if (reportingCodeMap!=null && !reportingCodeMap.keySet().containsAll(codes)) idMap = null;
      reportingCodes.addAll(codes);
      System.debug(idMap);
      System.debug(reportingCodes);
    }

    public void retrieveGLAccounts() {
        System.debug('retrieveGLAccounts');
        System.debug(ids);
        ids.remove(null);
        System.debug(reportingCodes);
        reportingCodes.remove(null);
        if (idMap==null) {
            // Select all fields from c2g__codaGeneralLedgerAccount__c
            Map<String, Schema.SObjectField> objFieldMap =  Schema.c2g__codaGeneralLedgerAccount__c.SObjectType.getDescribe().fields.getMap();
            List<String> objFieldList = new List<String>();
            for(string f : objFieldMap.keySet()) /* if (objFieldMap.get(f).getDescribe().isAccessible()) */ objFieldList.add(f);
            if (Schema.SObjectType.c2g__codaGeneralLedgerAccount__c.getRecordTypeInfosByName().size()>1) {
                objFieldList.add('recordtype.name');
            }
            String objfields = String.join(objFieldList,',');

            String soql = 'select ' + objfields + ' from c2g__codaGeneralLedgerAccount__c ';
            String junct = ' WHERE ';
            if (ids.size()>0) {
                System.debug(ids);
                soql += junct + ' Id in :ids ';
                junct = ' or ';
            }
            if (reportingCodes.size()>0) {
              System.debug(reportingCodes);
              soql += junct + ' c2g__ReportingCode__c in :reportingCodes ';
              junct = ' or ';
            }

            System.debug('retrieveGLAccounts: (soql) ' + soql);
            List<c2g__codaGeneralLedgerAccount__c> objlist = Database.query(soql);
            System.debug(objlist);
            idMap = new Map<Id,c2g__codaGeneralLedgerAccount__c>();
            reportingCodeMap = new Map<String,c2g__codaGeneralLedgerAccount__c>();
            for(c2g__codaGeneralLedgerAccount__c obj : objlist) { 
                idMap.put(obj.Id, obj);
                reportingCodeMap.put(obj.c2g__ReportingCode__c, obj);
            } 
            ids.addAll(idMap.keySet());
            reportingCodes.addAll(reportingCodeMap.keySet());
            System.debug(idMap);
            System.debug(reportingCodeMap);
        }
    }

    public void retrieveAllGLAccounts() {
        System.debug('retrieveAllGLAccounts');
        if (idMap==null) {
            // Select all fields from c2g__codaGeneralLedgerAccount__c
            Map<String, Schema.SObjectField> objFieldMap =  Schema.c2g__codaGeneralLedgerAccount__c.SObjectType.getDescribe().fields.getMap();
            List<String> objFieldList = new List<String>();
            for(string f : objFieldMap.keySet()) /* if (objFieldMap.get(f).getDescribe().isAccessible()) */ objFieldList.add(f);
            if (Schema.SObjectType.c2g__codaGeneralLedgerAccount__c.getRecordTypeInfosByName().size()>1) {
                objFieldList.add('recordtype.name');
            }
            String objfields = String.join(objFieldList,',');

            String soql = 'select ' + objfields + ' from c2g__codaGeneralLedgerAccount__c ';
            System.debug('retrieveGLAccounts: (soql) ' + soql);
            List<c2g__codaGeneralLedgerAccount__c> objlist = Database.query(soql);
            System.debug(objlist);
            idMap = new Map<Id,c2g__codaGeneralLedgerAccount__c>();
            reportingCodeMap = new Map<String,c2g__codaGeneralLedgerAccount__c>();
            for(c2g__codaGeneralLedgerAccount__c obj : objlist) { 
                idMap.put(obj.Id, obj);
                reportingCodeMap.put(obj.c2g__ReportingCode__c, obj);
            } 
            ids.addAll(idMap.keySet());
            reportingCodes.addAll(reportingCodeMap.keySet());
        }
    }


    public c2g__codaGeneralLedgerAccount__c getById(Id objid) {
        if (idMap==null) retrieveGLAccounts();
        System.debug(objid); System.debug(idMap.get(objid));
        return idMap.get(objid);
    }

    public c2g__codaGeneralLedgerAccount__c getByReportingCodeId(String code) {
      if (idMap==null) retrieveGLAccounts();    // the id map controls whether retrieval has run & is up-to-date 
      System.debug(code); System.debug(reportingCodeMap.get(code));
      return reportingCodeMap.get(code);
    }

}