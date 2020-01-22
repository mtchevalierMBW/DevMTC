/**
 * TransactionLineProcess
 * Tested by: TransactionReferences_TEST, ReversingJournal_TEST
 * Date: Mar 14, 2016
 * Programmer: Bryan Leaman
 *
 * Coverage:
 *	2019-09-13	89% (75/84)
 *
 *	2017-02-28	B. Leaman   BLL1 - Handle cancelling journals too.
 *	2019-09-13	B. Leaman	W-000754 BLL2 - fill in vehicle lookup from control# (for PIN/PCR) on vehicle GL accts.
 */
public class TransactionLineProcess {

    // constructor
    //---------------------------------------
    public TransactionLineProcess() {
    }


    // Check by newly set transaction document number for reversing journals that may need to have journal lines updated
    public static void checkReversingJournal(List<c2g__codaJournal__c> newList, Map<Id,c2g__codaJournal__c> oldMap) {
        Set<Id> jrnIds = new Set<Id>();
        //Set<Id> trnJrnIds = new Set<Id>();
        for(c2g__codaJournal__c j : newList) {
            c2g__codaJournal__c oldj = oldMap!=null ? oldMap.get(j.Id) : null; 
            if (j.c2g__Type__c=='Reversing Journal' && j.c2g__SourceJournal__c!=null && oldj!=null && oldj.c2g__SourceJournal__c!=j.c2g__SourceJournal__c)  // BLL1c
                jrnIds.add(j.Id);
            if (j.c2g__Type__c=='Cancelling Journal' && j.c2g__OriginalJournal__c!=null && oldj!=null && oldj.c2g__OriginalJournal__c!=j.c2g__OriginalJournal__c)   // BLL1c
                jrnIds.add(j.Id);
        }
        if (jrnIds.size()>0) TransactionLineProcess.FixReversingJournalLineRefs(jrnIds);
        //if (trnJrnIds.size()>0) TransactionLineProcess.FixReversingTransactionLineRefs(trnJrnIds);
    }


    // Check by newly set transaction document number for reversing journals that may need to have transaction lines updated
    public static void checkReversingTransaction(List<c2g__codaTransaction__c> newList, Map<Id,c2g__codaTransaction__c> oldMap) {
        Set<String> jrnNames = new Set<String>();
        for(c2g__codaTransaction__c t : newList) {
            c2g__codaTransaction__c oldt = oldMap!=null ? oldMap.get(t.Id) : null; 
            if (t.c2g__DocumentNumber__c!=null && oldt!=null && oldt.c2g__DocumentNumber__c!=t.c2g__DocumentNumber__c)
                 jrnNames.add(t.c2g__DocumentNumber__c);
        }
        Set<Id> jrnIds = new Set<Id>();
        for(c2g__codaJournal__c j : [
            select Id, Name, c2g__Type__c
            from c2g__codaJournal__c
            where c2g__Type__c in ('Reversing Journal', 'Cancelling Journal') and Name in :jrnNames     // BLL1c
                and c2g__Transaction__c!=null 
        ]) {
            jrnIds.add(j.Id);
        }
        //if (jrnIds.size()>0) TransactionLineProcess.FixReversingJournalLineRefs(jrnIds);
        if (jrnIds.size()>0) TransactionLineProcess.FixReversingTransactionLineRefs(jrnIds);
    }

    
    @future public static void FixReversingTransactionLineRefs(Set<Id> jrnIds) {
        // map of transaction id to related journal id & vice versa
        //Map<Id,Id> trnJrnId = new Map<Id,Id>();
        Map<Id,Id> jrnTrnId = new Map<Id,Id>();
        for(c2g__codaJournal__c j : [select Id, c2g__Transaction__c, c2g__SourceJournal__c, c2g__OriginalJournal__c from c2g__codaJournal__c where Id in :jrnIds]) {
            //trnJrnId.put(j.c2g__Transaction__c, j.c2g__SourceJournal__c);
            if (j.c2g__SourceJournal__c!=null) jrnTrnId.put(j.c2g__SourceJournal__c, j.c2g__Transaction__c);	// BLL1c
            if (j.c2g__OriginalJournal__c!=null) jrnTrnId.put(j.c2g__OriginalJournal__c, j.c2g__Transaction__c);	// BLL1a
        }
        // journal line custom reference fields
        Map<String,c2g__codaJournalLineItem__c> lineMap = new Map<String,c2g__codaJournalLineItem__c>();
        for(c2g__codaJournalLineItem__c jl : [
            select Id, Name, c2g__LineNumber__c, c2g__Journal__c, 
                    Control__c, Customer_Name__c, Finance_Company__c, 
                    Sales_Person__c, Stock_Number__c, Third_Party_Payor__c, Vehicle_Inventory__c, Vendor_Name__c
            from c2g__codaJournalLineItem__c
            where c2g__Journal__c in :jrnTrnId.keySet()
        ]) {
            String key = jrnTrnId.get(jl.c2g__Journal__c) + '-' + String.valueOf(Integer.valueOf(jl.c2g__LineNumber__c));
            lineMap.put(key,jl);
        }
        // transaction line updates
        List<c2g__codaTransactionLineItem__c> updTrnLines = new List<c2g__codaTransactionLineItem__c>();
        for(c2g__codaTransactionLineItem__c tl : [
            select Id, Name, c2g__Transaction__c, c2g__LineNumber__c
            from c2g__codaTransactionLineItem__c
            where c2g__Transaction__c in :jrnTrnId.values()
        ]) {
            String key = tl.c2g__Transaction__c + '-' + String.valueOf(Integer.valueOf(tl.c2g__LineNumber__c));
            c2g__codaJournalLineItem__c jline = lineMap.get(key);
            if (jline!=null) {
                updTrnLines.add(new c2g__codaTransactionLineItem__c(Id=tl.Id, Control__c = jline.Control__c, Customer_Name__c = jline.Customer_Name__c, Finance_Company__c = jline.Finance_Company__c,
                    Salesperson__c = jline.Sales_Person__c, Third_Party_Payor_TL__c = jline.Third_Party_Payor__c, Vehicle_Inventory__c = jline.Vehicle_Inventory__c, Vendor_Name__c = jline.Vendor_Name__c
                ));
            } 
        }
        
        // update transaction lines!
        if (updTrnLines.size()>0) Database.update(updTrnLines, false);
            
    }


    @future public static void FixReversingJournalLineRefs(Set<Id> jrnIds) {
        // map of journal id to source journal id
        Map<Id,Id> jrnSrcId = new Map<Id,Id>();
        for(c2g__codaJournal__c j : [select Id, c2g__SourceJournal__c, c2g__OriginalJournal__c from c2g__codaJournal__c where Id in :jrnIds]) {
            if (j.c2g__SourceJournal__c!=null) jrnSrcId.put(j.c2g__SourceJournal__c, j.Id); // BLL1c
            if (j.c2g__OriginalJournal__c!=null) jrnSrcId.put(j.c2g__OriginalJournal__c, j.Id); // BLL1a
        }
        // journal line custom reference fields from source journal
        Map<String,c2g__codaJournalLineItem__c> lineMap = new Map<String,c2g__codaJournalLineItem__c>();
        for(c2g__codaJournalLineItem__c jl : [
            select Id, Name, c2g__LineNumber__c, c2g__Journal__c, 
                    Control__c, Customer_Name__c, Finance_Company__c, 
                    Sales_Person__c, Stock_Number__c, Third_Party_Payor__c, Vehicle_Inventory__c, Vendor_Name__c
            from c2g__codaJournalLineItem__c
            where c2g__Journal__c in :jrnSrcId.keySet()
        ]) {
            String key = jrnSrcId.get(jl.c2g__Journal__c) + '-' + String.valueOf(Integer.valueOf(jl.c2g__LineNumber__c));
            lineMap.put(key,jl);
        }
        // journal line updates
        List<c2g__codaJournalLineItem__c> updJrnLines = new List<c2g__codaJournalLineItem__c>();
        for(c2g__codaJournalLineItem__c l : [
            select Id, Name, c2g__Journal__c, c2g__LineNumber__c
            from c2g__codaJournalLineItem__c
            where c2g__Journal__c in :jrnSrcId.values()
        ]) {
            String key = l.c2g__Journal__c + '-' + String.valueOf(Integer.valueOf(l.c2g__LineNumber__c));
            c2g__codaJournalLineItem__c jline = lineMap.get(key);
            if (jline!=null) {
                updJrnLines.add(new c2g__codaJournalLineItem__c(Id=l.Id, Control__c = jline.Control__c, Customer_Name__c = jline.Customer_Name__c, Finance_Company__c = jline.Finance_Company__c,
                    Sales_Person__c = jline.Sales_Person__c, Third_Party_Payor__c = jline.Third_Party_Payor__c, Vehicle_Inventory__c = jline.Vehicle_Inventory__c, Vendor_Name__c = jline.Vendor_Name__c, Stock_Number__c = jline.Stock_Number__c
                ));
            } 
        }
        
        // update journal lines!
        if (updJrnLines.size()>0) Database.update(updJrnLines, false);
            
    }

	// BLL2
	public static void LookupVehicleFromControl (List<c2g__codaTransactionLineItem__c> newlist) {
		// get sets of referenced GL accounts and control numbers (stock numbers for veh accts)
		Set<Id> glAcctSet = new Set<Id>();
		Set<String> stocknbrSet = new Set<String>();
		for(c2g__codaTransactionLineItem__c tl : newlist) {
			if (tl.Vehicle_Inventory__c==null && tl.Document_Number__c!=null
				&& (tl.Document_Number__c.startsWith('PIN') || tl.Document_Number__c.startsWith('PCR'))) {
				if (tl.c2g__GeneralLedgerAccount__c!=null) glAcctSet.add(tl.c2g__GeneralLedgerAccount__c);
				if (!String.isBlank(tl.Control__c)) stocknbrSet.add(tl.Control__c);
			}
		}

		// Setup required GL accounts
		GeneralLedgerAccountsSingleton gls = GeneralLedgerAccountsSingleton.getInstance();
		gls.addIds(glAcctSet);
		// map of stock# to vehicles for all needed stock numbers
		Map<String, dealer__Vehicle_Inventory__c> vehMap = new Map<String, dealer__Vehicle_Inventory__c>();
		if (stocknbrSet.size()>0) {
			for(dealer__Vehicle_Inventory__c v : [
				select Id, dealer__Stock_Number__c 
				from dealer__Vehicle_Inventory__c 
				where dealer__Stock_Number__c in :stocknbrSet
			]) {
				if (!String.isBlank(v.dealer__Stock_Number__c)) vehMap.put(v.dealer__Stock_Number__c.toLowerCase(), v);
			}
		}

		// Assign vehicle lookup to transaction line item (if required and missing)
		for(c2g__codaTransactionLineItem__c tl : newlist) {
			if (vehMap.size()>0 && tl.Vehicle_Inventory__c==null && !String.isBlank(tl.Document_Number__c)
				&& (tl.Document_Number__c.startsWith('PIN') || tl.Document_Number__c.startsWith('PCR'))) {
				c2g__codaGeneralLedgerAccount__c gla = gls.getById(tl.c2g__GeneralLedgerAccount__c);
				dealer__Vehicle_Inventory__c veh = !String.isBlank(tl.Control__c) ? vehMap.get(tl.Control__c.toLowerCase()) : null;
				if (gla!=null && gla.VehicleRequired__c && veh!=null) {
					tl.Vehicle_Inventory__c = veh.Id;
				}
			}
		}
	}
	// BLL2 end

}