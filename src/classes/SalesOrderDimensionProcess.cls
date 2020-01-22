/**
 * SalesOrderDimensionProcess
 * Tested by: SalesOrderDimensionProcess_TEST
 * Date: July 7, 2017
 * Programmer: Bryan Leaman
 * 
**/
public with sharing class SalesOrderDimensionProcess {

	List<rstk__sohdr__c> newhdr;
	Map<Id,rstk__sohdr__c> oldhdrMap;
	Map<Id,rstk__sohdr__c> affectedhdrMap;

	List<rstk__soline__c> newlin;
	Map<Id,rstk__soline__c> oldlinMap;
	List<rstk__soline__c> affectedlines;

	public SalesOrderDimensionProcess(List<rstk__sohdr__c> newh, Map<Id,rstk__sohdr__c> oldhMap) {
		newhdr = newh;
		oldhdrMap = oldhMap;
		Set<Id> hdrIds = new Set<Id>();
		for(rstk__sohdr__c h : newhdr) hdrIds.add(h.Id);
		if (hdrIds.size()>0) affectedhdrMap = new Map<Id,rstk__sohdr__c>([
			select Id, Name, rstk__sohdr_otype__c, rstk__sohdr_otype__r.Name
			from rstk__sohdr__c
			where Id in :hdrIds
		]);
		if (hdrIds.size()>0) affectedlines = [
			select Id, Name, rstk__soline_sohdr__c, rstk__soline_dimvals__c, rstk__soline_dimvals__r.rstk__dimval1__c
			from rstk__soline__c
			where rstk__soline_sohdr__c in :hdrIds
		];
	}

	public SalesOrderDimensionProcess(List<rstk__soline__c> newl, Map<Id,rstk__soline__c> oldlMap) {
		newlin = newl;
		oldlinMap = oldlMap;
		Set<Id> hdrIds = new Set<Id>();
		Set<Id> linIds = new Set<Id>();
		for(rstk__soline__c l : newlin) {
			hdrIds.add(l.rstk__soline_sohdr__c);
			linIds.add(l.Id);
		}
		if (hdrIds.size()>0) affectedhdrMap = new Map<Id,rstk__sohdr__c>([
			select Id, Name, rstk__sohdr_otype__c, rstk__sohdr_otype__r.Name
			from rstk__sohdr__c
			where Id in :hdrIds
		]);
		if (linIds.size()>0) affectedlines = [
			select Id, Name, rstk__soline_sohdr__c, rstk__soline_dimvals__c, rstk__soline_dimvals__r.rstk__dimval1__c
			from rstk__soline__c
			where Id in :linIds
		];
	}


	public void updateLineDimensions() {
		Map<Id,rstk__dimvals__c> upddimsMap = new Map<Id,rstk__dimvals__c>();
		for(rstk__soline__c l : affectedlines) {
			rstk__sohdr__c hdr = affectedhdrMap.get(l.rstk__soline_sohdr__c);
			String dim1 = (hdr.rstk__sohdr_otype__c!=null && hdr.rstk__sohdr_otype__r.Name.contains('TAXI')) ?
				'194' : '160';
			if (l.rstk__soline_dimvals__c!=null && dim1!=l.rstk__soline_dimvals__r.rstk__dimval1__c) {
				upddimsMap.put(l.rstk__soline_dimvals__c, new rstk__dimvals__c(
					Id=l.rstk__soline_dimvals__c, rstk__dimval1__c=dim1
				));
			}
		}
		if (upddimsMap.size()>0) update(upddimsMap.values()); 
	}

}