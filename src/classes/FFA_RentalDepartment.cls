/**
 * FFA_RentalDepartment
 * Tested by: FFA_RentalDepartment_TEST
 * Date: Dec 31, 2015
 * Programmer: Bryan Leaman
 * 
 * Moved logic from RentalAgreementMW_EXT controller to here.
 *	2017-02-17	B. Leaman	BLL1a - Just ignore rental posting requests that have no lines.
 *	2019-06-27	B. Leaman	BLL5 - Other payor vs Third party pay
 *	2019-07-03	B. Leaman	W-000716 BLL6 - Use account's AR Control from Account rcd.
 * 
 */
public without sharing class FFA_RentalDepartment {

	// postToGL
	// called from async posting (AccountingEmailService), body was formerly in the "post" routine
	//-----------------------------------------------------------
	public static void postRental(Id raId) {
		// Select all fields from object
		Map<String, Schema.SObjectField> fieldMap =  Schema.dealer__Rental_Agreements__c.SObjectType.getDescribe().fields.getMap();
		String allfields = '';
		String sep = '';
		for(string f : fieldMap.keySet()) {
			if (fieldMap.get(f).getDescribe().isAccessible()) { allfields += sep + f; sep = ','; }
		}
		String soql = 'select ' + allfields + ' from dealer__Rental_Agreements__c where Id=:raId ';    
		System.debug(soql);
		List<dealer__Rental_Agreements__c> rentalagreements = Database.query(soql);
		dealer__Rental_Agreements__c rentalagreement = rentalagreements[0];
		
		// Prepare mappings for generic create journal routine...
    	Id custacctId = rentalagreement.Account__c;
    	//BLL5d
		//if (rentalagreement.Other_payor__c!=null) {
    	//	custacctId = rentalagreement.Other_Payor__c;
    	//}
		//BLL5d end
    	Map<String, Id> customerpaymap = new Map<String, Id>{
    		   'dealer__Customer_Pay_Amount__c'=>custacctId, 
    		   'Payor_Pay_Amount__c'=>rentalagreement.ThirdPartyPayor__c};
    	Map<String, Id> referencemap = new Map<String, Id>{
    		   'RentalAgreement'=>rentalagreement.Id,
    		   'Customer'=>rentalagreement.Account__c,
    		   'ThirdPartyPayor'=>rentalagreement.ThirdPartyPayor__c,
    		   'OtherPayor'=>rentalagreement.Other_payor__c,
    		   'Vendor'=>null, 
    		   'Location'=>rentalagreement.Location__c
    	};
    	Map<String, String> journalmap = new Map<String, String>{
    		   'Control'=>'Name', 
    		   'JournalDate'=>'dealer__Return_Date__c'
    	};
    	
    	// Create and post journal
    	FFA_RentalDepartment.createAndPostJournal('REN', journalmap, rentalagreement, customerpaymap, referencemap);
	}    
    
    // BLL4 changed to static method, removed return value c2g__codaJournal__c
    // createJournal
    // Create journal entries for any object with a posting template & tied to a location
    //------------------------------------------------------------------------------------
    public static void createAndPostJournal(String sourceReference, Map<String, String> journalmap, SObject obj, Map<String, Id> customerpaymap, Map<String, Id> referencemap) {
        String objlabel = obj.getSObjectType().getDescribe().getLabel();
   		String soql = 'select Id, Name, Active__c, Object_Name__c from PostingTemplate__c '
   		            + 'where Active__c=true and Object_Name__c = \'' + objLabel + '\' ';
   		// TODO: optional selector for different types of transaction processes on a single object
   		// if (selector!=null) {
   			// soql += ' and TemplateSelector__c=\'' + selector + '\' ';
   		// }

		// BLL6
		Map<Id, Account> acctmap = new Map<Id,Account>([
			select Id, c2g__CODAAccountsReceivableControl__c, c2g__CODAAccountsPayableControl__c 
			from Account 
			where Id in :referencemap.values()
		]);
		// BLL6 end

        PostingTemplate__c template = null;
   		List<PostingTemplate__c> templates = Database.query(soql);
   		if (templates.size()!=1) {
   			throw new PostingTemplateException('Did not find a unique posting template for object ' + obj.getSObjectType() );
   		} else {
   			template = templates[0];
   		}
    	
    	// Get posting template rules (account mapping)
    	List<PostingTemplateEntryRule__c> rules = [
    	    select Id, Name, Action__c, Default_Memo__c, General_Ledger_Account__c, Posting_Template__c, Page_Order__c,
    	           FieldName__c, ReverseValue__c, LineType__c
    	    from PostingTemplateEntryRule__c
    	    where Posting_Template__c = :template.Id
    	    order by Page_Order__c
    	];
    	if (rules.size()==0) {
   			throw new PostingTemplateException('No posting template entry rules found');
    	}
    	
        // Get FF dimensions
        // Store Location of transaction
        Id locId = referencemap.get('Location');
        dealer__Dealer_Location__c loc=null;
        c2g__codaDimension1__c dim1;
		if(locId != null) {
			loc = [
			    Select Id, Name, Financial_Force_Dimension_1__c, Company__c 
				from dealer__Dealer_Location__c 
				where Id=:locId
				limit 1
			];
			dim1 = [
			    Select Id, Name 
			    from c2g__codaDimension1__c 
			    where Id=:loc.Financial_Force_Dimension_1__c 
			    limit 1
			];	
		}

        //BLL4d c2g__codaCompany__c comp = getFFCompany(loc.Company__c); 
        
    	// Create journal header
    	c2g__codaJournal__c journal = new c2g__codaJournal__c();
        journal.c2g__OwnerCompany__c = loc.Company__c; // BLL4c comp.Id;
        journal.Source__c = sourceReference;
        journal.c2g__JournalDescription__c = template.name + ' ' + (String) obj.get('Name');
        journal.c2g__Reference__c = (String) obj.get(journalMap.get('Control'));
        journal.c2g__JournalDate__c = (Date) obj.get(journalmap.get('JournalDate')); 
        if (journal.c2g__JournalDate__c == null) {
            journal.c2g__JournalDate__c = Date.today();
            System.debug('Using today for journal date');
        } 
        
		// BLL3a - next open period ending after transaction date
		c2g__codaPeriod__c period = [
			select Id, c2g__StartDate__c, c2g__EndDate__c, c2g__AP__c, c2g__Closed__c 
			from c2g__codaPeriod__c
			where c2g__OwnerCompany__c=:loc.Company__c and c2g__EndDate__c>=:journal.c2g__JournalDate__c  // BLL4c comp.Id
			  and c2g__Closed__c!=true and c2g__AR__c!=true
			order by c2g__StartDate__c
			limit 1
		];
		// If the period starts after the transaction date (posting next month), force current period & chg date
		if (period.c2g__StartDate__c > journal.c2g__JournalDate__c) {
			journal.c2g__Period__c = period.Id;
			journal.ffgl__DerivePeriod__c = false;
			journal.c2g__JournalDate__c = period.c2g__StartDate__c;
		} else {  // Otherwise, let FF determine period
			journal.ffgl__DerivePeriod__c = true;			
		}
		// BLL3a end determine period/date
        
        journal.Customer__c = referencemap.get('Customer');
        journal.Third_Party_Payor__c = referencemap.get('ThirdPartyPayor');
        journal.Other_Payor__c = referencemap.get('OtherPayor');
        journal.Vendor__c = referencemap.get('Vendor');
        journal.Sales_Person__c = referencemap.get('Salesperson');
        journal.Proposal__c = referencemap.get('Proposal');
        journal.Rental_Agreement__c = referencemap.get('RentalAgreement');
        journal.Repair_Order__c = referencemap.get('RepairOrder');
        journal.Purchase_Order__c = referencemap.get('PurchaseOrder');

		// Get Accounting Currency (or set ffgl__DeriveCurrency__c=true (dft))
        c2g__codaAccountingCurrency__c curr=null;
        List<c2g__codaAccountingCurrency__c> currs = [
	         Select Id, Name 
	         from c2g__codaAccountingCurrency__c 
	         where Name='USD' and c2g__OwnerCompany__c =:journal.c2g__OwnerCompany__c 
   	    ];
   	    if (currs.size()>0) {
   	        curr = currs[0];
   	        System.debug('Currency ' + curr.Name);
            journal.c2g__JournalCurrency__c = curr.Id;
   	    } else {
		    throw new PostingException('Could not find USD currency for company');
   	    }

        journal.ffgl__DerivePeriod__c=true;   // was false;  // BLL1a 

    	// Process rules to create journal entries
    	List<c2g__codaJournalLineItem__c> lines = new List<c2g__codaJournalLineItem__c>();
    	Integer i=1;
    	for(PostingTemplateEntryRule__c rule : rules) {
    		System.debug(rule);
    		c2g__codaJournalLineItem__c line = new c2g__codaJournalLineItem__c();

    		if (dim1!=null) {
               line.c2g__Dimension1__c = dim1.Id;
    		} 
            line.c2g__LineNumber__c = i++;
            line.c2g__LineDescription__c = template.name + ' - ' + String.valueOf(rule.Action__c) + ': ' + (String) obj.get('Name');
            line.c2g__GeneralLedgerAccount__c = rule.General_Ledger_Account__c;
            line.Control__c = (String) obj.get(journalMap.get('Control'));
            
            line.c2g__LineType__c = (rule.LineType__c!=null) ? rule.LineType__c : 'General Ledger Account';   // Deposit & AR s/b 'Account - Customer'
            if (line.c2g__LineType__c=='Account - Customer') {
                line.c2g__Account__c = (customerpaymap.containsKey(rule.FieldName__c)) ? customerpaymap.get(rule.FieldName__c) : referencemap.get('Customer'); 
				// BLL5 - other payor
				if (line.c2g__Account__c==null && rule.FieldName__c=='Payor_Pay_Amount__c') line.c2g__Account__c = referencemap.get('OtherPayor');
				// BLL5 end
				// BLL6 override GL account for AR
				Account a = acctmap.get(line.c2g__Account__c);
				if (a!=null && a.c2g__CODAAccountsReceivableControl__c!=null) line.c2g__GeneralLedgerAccount__c = a.c2g__CODAAccountsReceivableControl__c;
				// BLL6 end
            }
            if (line.c2g__LineType__c=='Account - Vendor') {
               line.c2g__Account__c = referencemap.get('Vendor');
				// BLL6 override GL account for AP
				Account a = acctmap.get(line.c2g__Account__c);
				if (a!=null && a.c2g__CODAAccountsPayableControl__c!=null) line.c2g__GeneralLedgerAccount__c = a.c2g__CODAAccountsPayableControl__c;
				// BLL6 end
    	    } 

            line.Customer_Name__c = referencemap.get('Customer');  // BLL2c re-activate 

            try {
                line.c2g__Value__c = (Decimal) obj.get(rule.FieldName__c);
            } catch(Exception fielderr) {
            	throw new PostingTemplateException('Unable to access field ' + rule.FieldName__c + ' in rule ' + rule.Action__c);
            }

            if (line.c2g__Value__c!=null && rule.ReverseValue__c!=null && rule.ReverseValue__c==true) {
            	line.c2g__Value__c = -line.c2g__Value__c;
            }
            if (line.c2g__Value__c != null && line.c2g__Value__c!=0) {
    		   lines.add(line);
    		   System.debug(line);
            } 
    	}
    	
    	//BLL4d try {  // BLL1a
        	//BLL4d insert(journal);
        	//BLL4d // now add journal id reference to lines
        	//BLL4d for(c2g__codaJournalLineItem__c line : lines) {
        	//BLL4d 	line.c2g__Journal__c = journal.Id;
        	//BLL4d }
    		//BLL4d insert(lines);
    	//BLL4d } catch(Exception e) { // BLL1a
    		//BLL4d journal = null;  // BLL1a
    		//BLL4d throw new PostingException('Unable to post. Error is ' + e.getMessage());  // BLL1a
    	//BLL4d } // BLL1a

		// BLL4a use new journal creation method
		SavePoint sp = Database.setSavePoint();

		// Process Journal Lines
        try {

			if (lines.size()>0) {	// BLL1a
        	 Id journalId = FinancialForce_MBW.createJournalApi(journal, lines);
        	 FFAccounting.postJournal(journalId);
        	 FFAccounting.applyJournalToRegister((Id) obj.get('Id'), journalId);
			}	// BLL1a

        } Catch(DmlException e) {
        	Database.rollback(sp);
        	throw new PostingException('Unable to create the journal lines '+e.getMessage());
        }		
		// BLL4a end
		
    	//BLL4d return journal;
    }
    
        // Custom exception class
    public class PostingTemplateException extends Exception {}
    public class PostingException extends Exception {}
    
}