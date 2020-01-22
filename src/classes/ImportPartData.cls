/**
*
*	Import new store data to the Part Object and Parts Inventory History Objects
*
*/
public class ImportPartData {

	public Integer historySize {get;set;}
	
	public ImportPartData() {
		historySize		=	0;
		csvFileLines 	= 	new String[]{};
	}

	public Blob csvFileBody{get;set;}
	public string csvAsString{get;set;}
	public String[] csvFileLines{get;set;}
	public List<List<string>> csvLines {get;set;}
	public dealer__Dealer_Location__c location {get;set;}

	// Part Data
	public List<dealer__Parts_Ledger__c> ledgerLines = new List<dealer__Parts_Ledger__c>();
	public List<dealer__Parts_Ledger__c> getLedgerLines() { return ledgerLines; }

	public List<SelectOption> locationList() {
		List<SelectOption> locations = new List<SelectOption>();
		for(dealer__Dealer_Location__c d : [Select Id, Name from dealer__Dealer_Location__c]) {
			locations.add(new SelectOption(d.Id, d.Name));
		}

		return locations;
	}

	public void importCSV(){
	   try{
	       csvAsString = csvFileBody.toString();
	       csvLines = CSVReader.parse(csvFileBody.toString()); 

	    }
	    catch (Exception e)
	    {
	        ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured while importin data Please make sure input csv file is correct');
	        ApexPages.addMessage(errorMessage);
	    }  
	}

	public void buildPartsInventory() {

		importCSV();

		// Read File and Create an upsert of Parts
		List<dealer__Parts_Inventory__c> inventory = new List<dealer__Parts_Inventory__c>();

	    Integer rowCount = 0;
		for(List<String> s : csvLines) {

			System.debug(s);

			if(rowCount>0) {
				dealer__Parts_Inventory__c p = new dealer__Parts_Inventory__c();
				p.Name = s[1];
				p.dealer__Part_No__c  = s[7]+':'+s[6]+':'+s[1];
				p.dealer__Description__c = s[2];
				p.dealer__MFG__c = s[6];
				p.dealer__Cost__c= Decimal.valueOf(s[5]);
				p.dealer__List__c= Decimal.valueOf(s[4]);
				p.dealer__Pack_QTY__c = 1;
				p.dealer__Company_Number__c = s[6];
				p.dealer__On_Hand__c=Decimal.valueOf(s[3]);
				p.dealer__Status__c = 'Active';			

				inventory.add(p);
			}

			rowCount++;
		}	

		System.debug(inventory);	
	}

	public void buildLedger() {

		importCSV();

		Set<String> pName = new Set<String>();
		Map<String, dealer__Parts_Inventory__c> pList = new Map<String, dealer__Parts_Inventory__c>();

		for(List<String> s : csvLines){ // 1 = Skip Header
	        pName.add(s[0]);
	    }

	    // Get Parts assciated
	    List<dealer__Parts_Inventory__c> parts = [Select Id, Name, dealer__Part_No__c from dealer__Parts_Inventory__c where dealer__Part_No__c IN:pName limit 10000];
	    for(dealer__Parts_Inventory__c p : parts) {
	    	pList.put(p.dealer__Part_No__c, p);
	    }

	    System.debug(parts.size());

	    Integer rowCount = 0;
		for(List<String> s : csvLines) {
			// Build Lines, if QTY contains more than one create a ledger entry for each

		    if(rowCount>0) {

		   	   System.debug(rowCount);

		   	   System.debug(pList);

	           Decimal lineQTY = Decimal.valueOf(s[1]);
	           for(Decimal r=1; r<=lineQTY; r++) {

	           		if(pList.get(s[0])==null) {
	           			throw new ImportException(s[0]+' not found in the store level inventory');
	           		}

		           ledgerLines.add(new dealer__Parts_Ledger__c(
		           					dealer__Entry_Date__c=Date.valueOf(s[5]),
		           					dealer__Quantity__c=1,
		           					dealer__Item_Value__c=Decimal.valueOf(s[2]),
		           					dealer__Transaction_Note__c=String.valueOf(s[4]),
		           					dealer__Part__c=pList.get(s[0]).Id
		           				)
		           );
	       		}
       		}

       		rowCount++;
       	}

       	historySize = ledgerLines.size();
	}

	public PageReference createHistory() {
		if(historySize>0) {

			try {
				insert ledgerLines;
			} Catch(DmlException e) {
				ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage());
				ApexPages.addMessage(errorMsg);	
				return null;			
			}
		}

		ApexPages.Message successMessage = new ApexPages.Message(ApexPages.Severity.INFO, 'Success: Created '+ledgerLines.size()+' history records');
		ApexPages.addMessage(successMessage);	

		return null;
	}

	public class ImportException extends Exception{}
}