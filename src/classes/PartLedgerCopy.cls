public class PartLedgerCopy {

	public static void mv(Id partId) {

		// Old Ledger
		List<dealer__Parts_Ledger__c> oldLedger = PartLedgerCopy.getLedger(partId);
		
		// New Ledger
		List<PartLedgerReporting__c> newLedger = PartLedgerCopy.getReportingLedger(partId);

		// Delete Routine
		PartLedgerCopy.deleteLedgers(oldLedger, newLedger);

		// Replace
		PartLedgerCopy.copyToNew(oldLedger, newLedger);

	}

	public static void copyToNew(List<dealer__Parts_Ledger__c> oldLedger, List<PartLedgerReporting__c> newLedger) {
		List<PartLedgerReporting__c> insertNew = new List<PartLedgerReporting__c>();
		List<dealer__Parts_Ledger__c> insertOld = new List<dealer__Parts_Ledger__c>();

		// Iterate the List and set values
		for(dealer__Parts_Ledger__c ol : oldLedger) {
			insertNew.add(new PartLedgerReporting__c(
				Part__c=ol.dealer__Part__c,
				Entry_Date__c=ol.dealer__Entry_Date__c,
				Item_Value__c=ol.dealer__Item_Value__c,
				Parts_Sale_Line__c=ol.dealer__Parts_Sale_Line__c,
				Purchase_Order__c=ol.dealer__Purchase_Order__c,
				Purchased_By__c=ol.dealer__Purchased_By__c,
				Quantity__c=ol.dealer__Quantity__c,
				Repair_Order_Line__c=ol.dealer__Repair_Order_Line__c,
				Sold_By__c=ol.dealer__Sold_By__c,
				Transaction_Note__c=ol.dealer__Transaction_Note__c
			));
		}

		// Iterate the list of new reporting ledgerand set to the oldLedger
		for(PartLedgerReporting__c rl : newLedger) {
			insertOld.add(new dealer__Parts_Ledger__c(
				dealer__Part__c=rl.Part__c,
				dealer__Entry_Date__c=rl.Entry_Date__c,
				dealer__Item_Value__c=rl.Item_Value__c,
				dealer__Parts_Sale_Line__c=rl.Parts_Sale_Line__c,
				dealer__Purchase_Order__c=rl.Purchase_Order__c,
				dealer__Purchased_By__c=rl.Purchase_Order__c,
				dealer__Quantity__c=rl.Quantity__c,
				dealer__Repair_Order_Line__c=rl.Repair_Order_Line__c,
				dealer__Sold_By__c=rl.Sold_By__c,
				dealer__Transaction_Note__c=rl.Transaction_Note__c
			));
		}

		if(!insertNew.isEmpty() && !insertOld.isEmpty()) {
			try {
				insert insertNew;
				insert insertOld;
			} Catch(DmlException e) {
				throw new PartLedgerCopyException(e.getMessage());
			}
		}
	}

	public static void deleteLedgers(List<dealer__Parts_Ledger__c> oldLedger, List<PartLedgerReporting__c> newLedger) {
		// Delete Old
		List<dealer__Parts_Ledger__c> delete_old_set = new List<dealer__Parts_Ledger__c>();
		for(dealer__Parts_Ledger__c pl : oldLedger) {
			delete_old_set.add(pl);
		}
		try { 
			delete delete_old_set;
		} Catch(DmlException e) {
			throw new PartLedgerCopyException(e.getMessage());
		}

		// Delete new
		List<PartLedgerReporting__c> delete_new_set = new List<PartLedgerReporting__c>();
		for(PartLedgerReporting__c pl : newLedger) {
			delete_new_set.add(pl);
		}
		try { 
			delete delete_new_set;
		} Catch(DmlException e) {
			throw new PartLedgerCopyException(e.getMessage());
		}		
	}

	public static List<PartLedgerReporting__c> getReportingLedger(Id partId) {
		return [SELECT Part__c, Current_Value__c, Entry_Date__c, Item_Value__c, Parts_Sale_Line__c,
				 	Purchase_Order__c, Purchased_By__c, Quantity__c, Repair_Order_Line__c,
				 	Sold_By__c, Transaction_Note__c, Value_of_One__c, Relieved_Date__c, SN__c, 
				 	Name, Id 
				 FROM PartLedgerReporting__c
				 WHERE Part__c =:partId];
	}

	public static List<dealer__Parts_Ledger__c> getLedger(Id partId) {
		return [SELECT dealer__Part__c, dealer__Current_Value__c, dealer__Entry_Date__c, 
					dealer__Item_Value__c, dealer__Parts_Sale_Line__c, dealer__Purchase_Order__c, 
					dealer__Purchased_By__c, dealer__Quantity__c, dealer__Repair_Order_Line__c, 
					dealer__Sold_By__c, dealer__Transaction_Note__c, Value_of_One__c, Name, Id 
					FROM dealer__Parts_Ledger__c
					WHERE dealer__Part__c =:partId];
	}

	public class PartLedgerCopyException extends Exception {}
}