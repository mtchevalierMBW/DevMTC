/**
 * AccountScheduleControlProcess
 * Tested by: AccountScheduleControlProcess_TEST
 * Date: May 26, 2017
 * Programmer: Bryan Leaman
 *
 *	Date		Developer	Description
 *	----------	----------	-------------------------------------------------------------------------------
 *	2017-06-19	B. Leaman	BLL1 - Add routines to fix a control record or set of control records.
 *	2017-07-10	B. Leaman	BLL2 - routine to fix flagged control records.
 */
global with sharing class AccountScheduleControlProcess {

	public Set<Id> ScheduledAccts;

	// AccountScheduleControlProcess
	//---------------------------------------
	public AccountScheduleControlProcess() {
		//ScheduledAccts = ScheduledGLAccountIds();
	}


	// constructControlKey
	//--------------------------------------
	public String constructControlKey(Id gla, Id dim1, String ctl) {
		String glaid = (gla!=null) ? String.valueOf(gla).substring(0,15) : '';
		String dim1id = (dim1!=null) ? String.valueOf(dim1).substring(0,15) : '';
		String ctlstr = (ctl!=null) ? ctl.toUpperCase() : '';
		if (ScheduledAccts==null) ScheduledAccts = ScheduledGLAccountIds();
		return ScheduledAccts.contains(gla) ? (glaid + ':' + dim1id + ':' + ctlstr) : null;
	}


	// ScheduledGLAccountIds
	//---------------------------------------
	public Set<Id> ScheduledGLAccountIds() {
		Set<Id> ids = new Set<Id>();
		for(c2g__codaGeneralLedgerAccount__c gla : [
			select Id
			from c2g__codaGeneralLedgerAccount__c
			where ScheduledAccount__c=true
		]) ids.add(gla.Id);
		return ids;
	}


	// updateTransactionControls
	//---------------------------------------
	public void updateTransactionControls(List<c2g__codaTransactionLineItem__c> newList, Map<Id,c2g__codaTransactionLineItem__c> oldMap) {
		
		if (ScheduledAccts==null) ScheduledAccts = ScheduledGLAccountIds();

		// Build list of control keys in this batch of transactions (GL Acct Id + ':' + Dimension1 Id + ':' + Control#)
		Set<String> controlKeys = new Set<String>();
		Set<Id> newIds = new Set<Id>();
		if (newList!=null && newList.size()>0) {
			for(c2g__codaTransactionLineItem__c tl : newList) {
				if (tl.Id!=null) newIds.add(tl.Id);
				String newkey = constructControlKey(tl.c2g__GeneralLedgerAccount__c, tl.c2g__Dimension1__c, tl.Control__c);
				System.debug(tl.Control__c);
				System.debug(newkey);
				if (newkey!=null && ScheduledAccts.contains(tl.c2g__GeneralLedgerAccount__c)) controlKeys.add(newkey);
			} // end for newlist
		} // end if newlist!=null

		// old map also affects control rcds
		if (oldMap!=null && oldMap.size()>0) {
			for(c2g__codaTransactionLineItem__c tl : oldMap.values()) {
				String oldkey = constructControlKey(tl.c2g__GeneralLedgerAccount__c, tl.c2g__Dimension1__c, tl.Control__c);
				System.debug(oldkey);
				if (oldkey!=null && ScheduledAccts.contains(tl.c2g__GeneralLedgerAccount__c)) controlKeys.add(oldkey);
			} // end for oldMap.values()
		} // end if oldMap!=null
		
		// Affected control numbers
		System.debug(controlKeys);
		Map<String,AccountScheduleControl__c> controlMap = new Map<String,AccountScheduleControl__c>();
		for(AccountScheduleControl__c ctl : [
				select Id, GeneralLedgerAccount__c, Dimension1__c, Control__c, BeginDate__c, EndDate__c, Balance__c, ScheduleKey__c
				from AccountScheduleControl__c
				where ScheduleKey__c in :controlKeys
			]) {
			controlMap.put(ctl.ScheduleKey__c, ctl);
			System.debug('Existing control key: ' + ctl.ScheduleKey__c);
		} // end for ctl
		
		// Build list of new account schedule controls and updated ones
		Map<String,AccountScheduleControl__c> addCtls = new Map<String,AccountScheduleControl__c>();
		Map<Id,AccountScheduleControl__c> updCtls = new Map<Id,AccountScheduleControl__c>();
		if (newList!=null && newList.size()>0) {
			for(c2g__codaTransactionLineItem__c tl : newList) {
				String newkey = constructControlKey(tl.c2g__GeneralLedgerAccount__c, tl.c2g__Dimension1__c, tl.Control__c);
				System.debug(tl.Control__c);
				System.debug(newkey);
				c2g__codaTransactionLineItem__c oldtl = oldMap!=null ? oldMap.get(tl.Id) : null;
				String oldkey = (oldtl!=null) ? constructControlKey(oldtl.c2g__GeneralLedgerAccount__c, oldtl.c2g__Dimension1__c, oldtl.Control__c) : null;
			
				AccountScheduleControl__c newctl = newkey!=null ? controlMap.get(newkey) : null;
				AccountScheduleControl__c oldctl = oldkey!=null ? controlMap.get(oldkey) : null;
				if (newctl==null && newkey!=null) {
					newctl = new AccountScheduleControl__c(
						Control__c = tl.Control__c!=null ? tl.Control__c.toUpperCase() : '' , 
						GeneralLedgerAccount__c = tl.c2g__GeneralLedgerAccount__c,
						Dimension1__c = tl.c2g__Dimension1__c,
						BeginDate__c = tl.Transaction_Date__c,
						EndDate__c = tl.Transaction_Date__c,
						Balance__c = tl.c2g__HomeValue__c,
						ScheduleKey__c = newkey
					);
					addCtls.put(newkey, newctl);
					controlMap.put(newkey, newctl);
				} else if (newctl!=null && (oldctl==null || oldctl.Id!=newctl.Id)) {
					if (newctl.BeginDate__c==null || tl.Transaction_Date__c < newctl.BeginDate__c) newctl.BeginDate__c = tl.Transaction_Date__c;
					if (newctl.EndDate__c==null || tl.Transaction_Date__c > newctl.EndDate__c) newctl.EndDate__c = tl.Transaction_Date__c;
					newctl.Balance__c += tl.c2g__HomeValue__c;
					if (newctl.Id!=null) updCtls.put(newctl.Id,newctl);
				} else if (oldctl!=null && newctl!=null && oldctl.Id==newctl.Id && tl.c2g__HomeValue__c!=oldtl.c2g__HomeValue__c) {
					newctl.Balance__c += (tl.c2g__HomeValue__c - oldtl.c2g__HomeValue__c);
					if (newctl.Id!=null) updCtls.put(newctl.Id,newctl);
				}
		
				// Remove value from old control#
				if (oldctl!=null && newctl!=null && oldctl.Id!=newctl.Id) {
					oldctl.Balance__c -= tl.c2g__HomeValue__c;
					updCtls.put(oldctl.Id, oldctl);
					// This will leave begin & end dates alone, which may be wrong. Use full rebuild batch to correct this periodically.
				} // end if oldctl!=null
				 
			} // end for newlist
		} // end if newlist!=null

		// handle transaction deletes? (only if FF adds a purge capability or is fixing a booboo)
		if (newList==null) { // only during a delete trigger 
			for(c2g__codaTransactionLineItem__c tl : oldMap.values()) {
				String oldkey = constructControlKey(tl.c2g__GeneralLedgerAccount__c, tl.c2g__Dimension1__c, tl.Control__c);
				AccountScheduleControl__c oldctl = oldkey!=null ? controlMap.get(oldkey) : null;
				oldctl.Balance__c -= tl.c2g__HomeValue__c;
				updCtls.put(oldctl.Id, oldctl);
			}
		}
		
		// insert & update control records!
		if (!addCtls.isEmpty()) Database.insert(addCtls.values());
		if (!updCtls.isEmpty()) Database.update(updCtls.values());
		
		// Link transaction lines to account schedule control record
		if (newList!=null && newList.size()>0) {
			for(c2g__codaTransactionLineItem__c tl : newList) {
				String ctlkey = constructControlKey(tl.c2g__GeneralLedgerAccount__c, tl.c2g__Dimension1__c, tl.Control__c);
				tl.AccountScheduleControl__c = controlMap.containsKey(ctlkey) ? controlMap.get(ctlkey).Id : null;
			} // end for newlist
		} // end if newlist!=null
	
	} // end updateTransactionControls
	
	// BLL2a
	public void updateRequestedControlTotals(List<AccountScheduleControl__c> newList) {
		Set<Id> ctlIds = new Set<Id>();
		for(AccountScheduleControl__c a : newList) {
			if (a.RecalcControlTotal__c) ctlIds.add(a.Id);
			a.RecalcControlTotal__c = false;
		}
		Map<Id,AccountScheduleControl__c> ctls = new Map<Id,AccountScheduleControl__c>([
			select Id, Name, Control__c, GeneralLedgerAccount__c, Dimension1__c, Balance__c, BeginDate__c, EndDate__c, 
				( select Id, Name, c2g__Transaction__c, c2g__LineNumber__c, Transaction_Date__c, c2g__HomeValue__c
				  from Transaction_Line_Items__r
				)
			from AccountScheduleControl__c
			where Id in :ctlIds
		]);
		for(AccountScheduleControl__c a : newList) {
			Decimal total = 0;
			Date mindate = null;
			Date maxdate = null;
			AccountScheduleControl__c ctl = ctls.get(a.Id);
			if (ctl!=null) {
				for(c2g__codaTransactionLineItem__c tli : ctl.Transaction_Line_Items__r) {
					total += tli.c2g__HomeValue__c;
					if (mindate==null || tli.Transaction_Date__c<mindate) mindate = tli.Transaction_Date__c;
					if (maxdate==null || tli.Transaction_Date__c>maxdate) maxdate = tli.Transaction_Date__c;
				}
				if (total!=ctl.Balance__c) {
					a.Balance__c=total;
					a.BeginDate__c=mindate;
					a.EndDate__c=maxdate;
				}
			}
		}
	}
	// BLL2a end
	
	// BLL1a 
	webservice static boolean updateControlTotal_ws(Id ctlid) {
		new AccountScheduleControlProcess().updateControlTotal(ctlid);
		return true;
	}
	public void updateControlTotal(Id ctlid) {
		updateControlTotal(new List<Id>{ctlid});
	}
	public void updateControlTotal(List<Id> ctlids) {
		List<AccountScheduleControl__c> updctls = new List<AccountScheduleControl__c>();
		List<AccountScheduleControl__c> ctls = [
			select Id, Name, Control__c, GeneralLedgerAccount__c, Dimension1__c, Balance__c, BeginDate__c, EndDate__c, 
				( select Id, Name, c2g__Transaction__c, c2g__LineNumber__c, Transaction_Date__c, c2g__HomeValue__c
				  from Transaction_Line_Items__r
				)
			from AccountScheduleControl__c
			where Id in :ctlids
		];
		for(AccountScheduleControl__c ctl : ctls) {
			Decimal total = 0;
			Date mindate = null;
			Date maxdate = null;
			for(c2g__codaTransactionLineItem__c tli : ctl.Transaction_Line_Items__r) {
				total += tli.c2g__HomeValue__c;
				if (mindate==null || tli.Transaction_Date__c<mindate) mindate = tli.Transaction_Date__c;
				if (maxdate==null || tli.Transaction_Date__c>maxdate) maxdate = tli.Transaction_Date__c;
			}
			if (total!=ctl.Balance__c) {
				updctls.add(new AccountScheduleControl__c(Id=ctl.Id, Balance__c=total, BeginDate__c=mindate, EndDate__c=maxdate));
			}
		}
		if (updctls.size()>0) Database.update(updctls,false);
	}
	// BLL1a end

} // end class