/**
 * JournalProcess
 * Tested by: JournalProcess_TEST
 * Date: May 12, 2017
 * Programmer: Bryan Leaman
 *
 * Code coverage:
 *	JournalProcess_TEST		100% (108/108)
 *
 *	2018-03-06	B. Leaman	BLL1 - RootstockSalesCreditReference routine to fill in c2g__Reference__c for SCRs.
 *	2019-07-09	B. Leaman	BLL2 - Fix transitworks company selection with new name (Driverge) and reduce soql queries
 */
public with sharing class JournalProcess {

	List<c2g__codaJournal__c> newList;
	Map<Id,c2g__codaJournal__c> oldMap;
	public static c2g__codaCompany__c TW;	// BLL2 add static designation
	
	// JournalProcess
	//---------------------------------------
	public JournalProcess(List<c2g__codaJournal__c> nList, Map<Id,c2g__codaJournal__c> oMap) {
		newList = nList;
		oldMap = oMap;
	}

	// Get TransitWorks company id to condition when to replace journal source code for Rootstock
	public c2g__codaCompany__c TransitWorksCompany() {
		if (TW!=null) return TW;
		TW = new c2g__codaCompany__c();
		try {
			// BLL2
			//TW = [select Id, Name from c2g__codaCompany__c where Name like '%TransitWorks%' limit 1];
			TW = [select Id, Name from c2g__codaCompany__c where c2g__ExternalId__c='TWK' limit 1];
			// BLL2
		} catch(Exception e) {}
		return TW;
	}

	public void RootstockSourceCode() {
		c2g__codaCompany__c twCompany = TransitWorksCompany();
		Map<String,String> srcCodeMap = new Map<String,String>{
			'ACCRUED AP'	=>	'PU',
			'ACTMTLOHDCLRING'	=>	'PU',
			'ACTMTLOHDCLRING'	=>	'PU',
			'CUMLESSSLPOWIP'	=>	'PU',
			'DIVDIVVAR'	=>	'VV',
			'INVDIVDIV'	=>	'VV',
			'INVLOCADD'	=>	'IA',
			'INVLOCADJ'	=>	'IA',
			'INVLOCSCRP'	=>	'IA',
			'INVLOCSCRPREV'	=>	'IA',
			'INVLOCLOC'	=>	'IA',
			'INVPROJPROJ'	=>	'IA',
			'INVSITESITE'	=>	'IA',
			'ODC'	=>	'PU',
			'OPMACH'	=>	'WO',
			'OPMACHR'	=>	'WO',
			'MTLOHDVAR'	=>	'WO',
			'OPLAB'	=>	'WO',
			'OPLABR'	=>	'WO',
			'POISS'	=>	'PU',
			'POISSR'	=>	'PU',
			'PORCPT TO INV'	=>	'PU',
			'PORCPTR TO INV'	=>	'PU',
			'PPV'	=>	'PV',
			'PPV-USAGE'	=>	'PV',
			'PORCPT'	=>	'PU',
			'PORCPTR'	=>	'PU',
			'POCLOSE'	=>	'PU',
			'POCLOSER'	=>	'PU',
			'POSUBWIPACCOUNT'	=>	'PU',
			'RMADISP'	=>	'IA',
			'RMADISP'	=>	'IA',
			'RMADISP'	=>	'IA',
			'RMARCPT'	=>	'IA',
			'RMARCPTR'	=>	'IA',
			'SOISS'	=>	'SI',
			'SOISSR'	=>	'SI',
			'SO Shipment'	=>	'SI',
			'SO SHIP REV'	=>	'SI',
			'STDSREVAL'	=>	'IA',
			'STDSREVAL'	=>	'IA',
			'WOCLOSE'	=>	'WO',
			'WOCLOSER'	=>	'WO',
			'WOISS'	=>	'WO',
			'WOISS'	=>	'WO',
			'WOISSR'	=>	'WO',
			'WOISSR'	=>	'WO',
			'WORCPT'	=>	'WO',
			'WORCPTR'	=>	'WO',
			// 'Cash Matching Journal' => 'CE',
			'Detail for Sales Credit Note'	=> 'SC', 
			'Invoice Detail for Sales Invoice'	=> 'SI'
		};
		
		for(c2g__codaJournal__c j : newList) {
			String newSource = srcCodeMap.get(j.c2g__JournalDescription__c);
			if (j.c2g__OwnerCompany__c==twCompany.Id && !String.isBlank(newSource)) j.Source__c = newSource;
		}
	}

	// BLL1a
	// RootstockSalesCreditReference
	public void RootstockSalesCreditReference() {
		Set<Id> ScrIds = new Set<Id>();
		for(c2g__codaJournal__c j : newList) { 
			if (j.Sales_Credit_Note__c!=null) ScrIds.add(j.Sales_Credit_Note__c);
		}
		Map<Id, c2g__codaCreditNote__c> scrMap = new Map<Id, c2g__codaCreditNote__c>();
		if (ScrIds.size()>0) scrMap = new Map<Id, c2g__codaCreditNote__c>([
			select Id, Name, c2g__Invoice__c, c2g__Invoice__r.Name from c2g__codaCreditNote__c where Id in :ScrIds
		]);
		for(c2g__codaJournal__c j : newList) {
			if (String.isBlank(j.c2g__Reference__c) && j.Sales_Credit_Note__c!=null) {
				c2g__codaCreditNote__c cn = scrMap.get(j.Sales_Credit_Note__c);
				if (cn!=null) j.c2g__Reference__c = cn.Name;
				if (cn!=null && cn.c2g__Invoice__r!=null) j.c2g__Reference__c += ' for ' +cn.c2g__Invoice__r.Name;
			}
		}
	}
	// BLL1a end

	public void ReversingJournal() {
		// List of source journals referenced by reversing journals
		Set<Id> srcJrnIds = new Set<Id>();
		for(c2g__codaJournal__c j : newList) {
			//c2g__codaJournal__c oldj = Trigger.isUpdate ?  Trigger.oldMap.get(j.Id) : null;
			if (j.c2g__Type__c == 'Reversing Journal' && j.c2g__SourceJournal__c != null) srcJrnIds.add(j.c2g__SourceJournal__c);
			if (j.c2g__Type__c == 'Cancelling Journal' && j.c2g__OriginalJournal__c != null) srcJrnIds.add(j.c2g__OriginalJournal__c);
		} // for newList
		
		// Map source journal id to object with custom fields 
		Map<Id,c2g__codaJournal__c> srcJrnMap = new Map<Id,c2g__codaJournal__c>();
		if (srcJrnIds.size()>0) {
			for( c2g__codaJournal__c j : [
				select Id, Name, Source__c, Customer__c, Finance_Company__c, Other_Payor__c, 
					Proposal__c, Purchase_Order__c, Rental_Agreement__c, Sales_Person__c, Repair_Order__c, Stock_Number__c, 
					Third_Party_Payor__c, Vendor__c, CommercialQuote__c		// BLL2c add CommercialQuote__c
				from c2g__codaJournal__c
				where Id in :srcJrnIds]) {
				srcJrnMap.put(j.Id, j);
				System.debug(j.Id);
				System.debug(j);
			} // for select source journals
		} // srcJrnIds.size()>0
		
		// For each new/updated reversing journal, map in custom values
		if (srcJrnMap.size()>0) {
			for(c2g__codaJournal__c j : newList) {
				//BLL3d if ((j.c2g__Type__c == 'Reversing Journal' || j.c2g__Type__c=='Cancelling Journal') && j.c2g__SourceJournal__c!=null) {	// BLL3c
					c2g__codaJournal__c src = null;	// BLL3c
					if (j.c2g__Type__c == 'Reversing Journal') src = srcJrnMap.get(j.c2g__SourceJournal__c);	// BLL3a
					if (j.c2g__Type__c == 'Cancelling Journal') src = srcJrnMap.get(j.c2g__OriginalJournal__c);	// BLL3a
					//System.debug(j.c2g__SourceJournal__c);
					System.debug(src);
					if (src!=null) {
						j.Source__c = src.Source__c;
						j.Customer__c = src.Customer__c;
						j.Finance_Company__c = src.Finance_Company__c;
						j.Other_Payor__c = src.Other_Payor__c;
						j.Proposal__c = src.Proposal__c;
						j.Purchase_Order__c = src.Purchase_Order__c;
						j.Rental_Agreement__c = src.Rental_Agreement__c;
						j.Sales_Person__c = src.Sales_Person__c;
						j.Repair_Order__c = src.Repair_Order__c;
						j.Stock_Number__c = src.Stock_Number__c;
						j.Third_Party_Payor__c = src.Third_Party_Payor__c;
						j.Vendor__c = src.Vendor__c;
						j.CommercialQuote__c = src.CommercialQuote__c;	// BLL2a
					} // src!=null
				//BLL3d } // reversing journal
			} // for newList
		} // srcJrnMap.size()>0
		
	}	// ReversingJournals

}