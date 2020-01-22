/**
 * GeneralLedgerAcctMW
 * Tested by: GeneralLedgerAcctMW_TEST
 * Programmer: Bryan Leaman
 * Date: 2015-11-02
 * Keep copy of GL accounts in sync.
 * 
 */
public with sharing class GeneralLedgerAcctMW {

	public static Integer deleteAccounts(List<c2g__codaGeneralLedgerAccount__c> dltFFGLs) {
		Set<String> dltFFRcs = new Set<String>();
		for(c2g__codaGeneralLedgerAccount__c ff : dltFFGLs) {
			dltFFRcs.add(ff.c2g__ReportingCode__c);
		}
		List<GeneralLedgerAcctMW__c> dltgl = [
			select Id from GeneralLedgerAcctMW__c where ReportingCode__c in :dltFFRcs
		];
   		if (dltgl.size()>0) {
   			delete(dltgl);
   		}
   		return dltgl.size();
	}

	public static Integer upsertAccounts(List<c2g__codaGeneralLedgerAccount__c> updFFGLs) {
    	List<GeneralLedgerAcctMW__c> updgl = new List<GeneralLedgerAcctMW__c>();
    	List<GeneralLedgerAcctMW__c> insgl = new List<GeneralLedgerAcctMW__c>();

		// List of FF GL ids upserted
		Set<Id> updFFIds = new Set<Id>();
		Set<String> updFFRcs = new Set<String>();
		for(c2g__codaGeneralLedgerAccount__c ff : updFFGLs) {
			updFFIds.add(ff.Id);
			updFFRcs.add(ff.c2g__ReportingCode__c);
		}
		
   		// map FF accounts to clone version
   		Map<Id,GeneralLedgerAcctMW__c> ffmwmap = new Map<Id,GeneralLedgerAcctMW__c>();
   		Map<String,GeneralLedgerAcctMW__c> ffmwmap2 = new Map<String,GeneralLedgerAcctMW__c>();
   		for(GeneralLedgerAcctMW__c mwa : [select Id, Name, ReportingCode__c, GeneralLedgerAccountFF__c, ExpenseAccount__c
   			from GeneralLedgerAcctMW__c where GeneralLedgerAccountFF__c in :updFFIds or ReportingCode__c in :updFFRcs]) {
   			ffmwmap.put(mwa.GeneralLedgerAccountFF__c, mwa);
   			ffmwmap2.put(mwa.ReportingCode__c, mwa);
   		}

   		// For each FinancialForce gl acct updated or inserted... determine if update or insert is needed 
   		for(c2g__codaGeneralLedgerAccount__c ff : updFFGLs) {
   			GeneralLedgerAcctMW__c mwg = ffmwmap.get(ff.Id);
   			GeneralLedgerAcctMW__c mwg2 = ffmwmap2.get(ff.c2g__ReportingCode__c);
   			if (mwg!=null) {  // Exists in clone acct obj
   				if (mwg.Name!=ff.Name || mwg.ReportingCode__c!=ff.c2g__ReportingCode__c || mwg.ExpenseAccount__c!=ff.Available_for_Service_PO__c) {
   					updgl.add(new GeneralLedgerAcctMW__c(Id=mwg.Id, 
   						Name=ff.Name,
   						ReportingCode__c = ff.c2g__ReportingCode__c,
   						GeneralLedgerAccountFF__c = ff.Id,
   						ExpenseAccount__c = ff.Available_for_Service_PO__c
   					));
   				}
   			} else if (mwg2!=null) {  // already exists for this reporting code 
				updgl.add(new GeneralLedgerAcctMW__c(Id=mwg2.Id, 
					Name=ff.Name,
					ReportingCode__c = ff.c2g__ReportingCode__c,
   					GeneralLedgerAccountFF__c = ff.Id,
   					ExpenseAccount__c = ff.Available_for_Service_PO__c
				));
   			} else {  // Does not exist in clone acct obj - also need to check by reporting code!
   				insgl.add(new GeneralLedgerAcctMW__c(Name=ff.Name,
   					ReportingCode__c = ff.c2g__ReportingCode__c,
   					GeneralLedgerAccountFF__c = ff.Id,
					ExpenseAccount__c = ff.Available_for_Service_PO__c
   				));
   			}
   		}
   		if (updgl.size()>0) { 
   			update(updgl);
   		}
   		if (insgl.size()>0) {
   			insert(insgl);
   		}
   		
   		return updgl.size() + insgl.size();
	}

}