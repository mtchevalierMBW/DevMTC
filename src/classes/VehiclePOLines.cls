/*
Questions:
- The "accepted purchase order" section of the PO doesn't show in the UI. Is this for later invoices?
- createVehicle will error with duplicate stock numbers, but the Journal process can succeed.  Is that ok or should the whole process stop?
- Bug: in the parent page "Status" picklist is empty.
- See line 388.  Not sure how "Accepted" status affects this field.
- See line 418.  The existing vehicle fields are mostly blank, and the fields exist on the parent page...
- See line 557.  Need confirmation of journalEntry fields; some were guesses.

Tested by: VehiclePOLines_TC

Coverage:
	2018-06-28	70% (253/358)
	2018-07-16	81% (282/346) Woohoo!
	
Notes:
- Future enhancement: could add more messages to the validateForm method...
- Technical Debt: saveLines could technically delete existing rows, then fail to insert the new copies.

23-11-2015 RedTeal		RT1 - Updated query to fix several issues with accepting a PO
02-12-2015 RedTeal    RT2 - Conversion and Chasis costs will now sum instead of overwriting old values
14-12-2015 RedTeal    RT3 - Added a warning if balance != invoice amount
17-02-2016 RedTeal		RT4 - Made changes to support alternative general ledger objects so vehicle po's can
							              be done by non-FF users
2016-02-19 RedTeal    RT5 - Accept Vehilce POs now done asynchronously
2016-06-07 RedTeal    RT6 - Added support for creating a new vehicle from a vehicle template  
2016-07-29	B. Leaman	BLL1 Use CurrentUserSingleton instead of SOQL.
2016-12-06	B. Leaman	BLL2 - fix test error when division isn't set right on the testing user.
2018-06-12	B. Leaman	BLL3 - set dimension1 default based on location; fix gl acct handline (bulkify);
2018-07-16	B. Leaman	BLL4 - increasing code coverage.
2019-06-11	B. Leaman	W-000706 BLL5 - prevent duplication of the accept PO function.
2019-11-06	B. Leaman	W-000777 BLL6 - fix po line dimension1 not being saved.
*/
public with sharing class VehiclePOLines {
    //Properties for PO Lines
    public List<lineWrap> lines {get;set;}
    public String division {get;set;}
    public Decimal balance {get;set;}
    //BLL1d public User u = [Select Id, Name, Division from User where Id=:UserInfo.getUserId() limit 1];
    public User u {get; private set;}	// BLL1a
    public dealer__Purchase_Order__c po {get;set;}
    public Integer indexCount {get;set;}
    //Properties for Vehicle
    public dealer__Vehicle_Inventory__c vehicleInv {get;set;}
    public Decimal chassisCost {get;set;}
    public Decimal conversionCost {get;set;}
    //Properties for Journal
    public dealer__Dealer_Location__c loc {get;set;}
    public c2g__codaDimension1__c dim1 {get;set;}
    public List<c2g__codaJournal__c> journalHeaders {get;set;}
    // Constructor
    public VehiclePOLines() {
    	u = CurrentUserSingleton.getInstance();	// BLL1a
        // Should have created a controller extension
        if(ApexPages.currentPage().getParameters().get('id')!=null && 
           ApexPages.currentPage().getParameters().get('id')!='') {      	
               //RT1 - small query update
               List<dealer__Purchase_Order__c> pos = [Select Id, Name, dealer__Company__c, dealer__StockNumber__c,dealer__Accepted_DateTime__c, dealer__Vehicle_Inventory__c,
                                                      dealer__Accepted_By__c, dealer__Company__r.Name, dealer__Invoice_Amount__c, dealer__Vendor__c, dealer__Freight__c, dealer__Invoice_Date__c, dealer__Invoice_Number__c,
                                                      Payable_Invoice__c, Payable_Invoice__r.Name, Vehicle_Inventory_Template__c, dealer__VIN__c
                                                      from dealer__Purchase_Order__c 
                                                      where Id=:ApexPages.currentPage().getParameters().get('id') limit 1];
               if(pos.size()>0){
                   po = pos[0];
               }
               
               balance = 0;
               indexCount = 0;
               chassisCost = 0;
               conversionCost = 0;
               //BLL1d User u = [Select Id, Division from User where Id=:UserInfo.getUserId() limit 1];
               
               //Get Location Information
               List<dealer__Dealer_Location__c> locQuery     = [Select Id, Name, Financial_Force_Dimension_1__c, Financial_Force_Dimension_1__r.Name, Company__c, Internal_Labor_Rate__c, Sales_Tax_Account__c 
                                                                from dealer__Dealer_Location__c 
                                                                where Id=:po.dealer__Company__c limit 1];
               if(locQuery.size()>0) {
                   loc = locQuery[0]; 
               } else {
                   throw new POException('User has no dealer__Dealer_Location__c set');
               }
               if(loc.Financial_Force_Dimension_1__c != null) {
                   dim1  =   [Select Id, Name from c2g__codaDimension1__c 
                              where Id=:loc.Financial_Force_Dimension_1__c limit 1];  
               } else {
                   throw new POException('Location '+loc.Name+' must have the Financial Force Dimension 1 field set to before attempting to Post');
               }
               
               //Check for existing vehicle
               getVehicleInv();
               
               //Check if existing Journal Header
               List<c2g__codaJournal__c> jHead = [SELECT Id, c2g__codaJournal__c.Name, c2g__JournalDescription__c, c2g__JournalDate__c 
                                                  FROM c2g__codaJournal__c 
                                                  where Purchase_Order__c=:po.id limit 100];
               if(jHead.size()>0) journalHeaders = jHead;
			   
               // Get existing PO lines
               lines = new List<lineWrap>();
               List<dealer__Purchase_Order_Line__c> oldLines = [Select Id, dealer__Amount__c, dealer__Description__c, 
                                                                Add_to_Chassis__c, Add_to_Conversion__c, General_Ledger_Account__c, Dimension_1__c 
                                                                from dealer__Purchase_Order_Line__c where dealer__Purchase_Order__c =:po.Id limit 500];
			   // BLL3a
			   // Get GL accounts for lines
			   Set<Id> GL_Accts = new Set<Id>();	
               for (dealer__Purchase_Order_Line__c l : oldLines) {
               		GL_Accts.add(l.General_Ledger_Account__c);
               }
               Map<Id, GeneralLedgerAcctMW__c> GLAMap = new Map<Id, GeneralLedgerAcctMW__c>();
               for(GeneralLedgerAcctMW__c glamw : [select Id,Name, GeneralLedgerAccountFF__c from GeneralLedgerAcctMW__c where GeneralLedgerAccountFF__c in :GL_Accts]) {
               		GLAMap.put(glamw.GeneralLedgerAccountFF__c, glamw);
           	   }
               // BLL3a
               
               if(po.Id!=null && oldLines.size()>0) {
                   for(dealer__Purchase_Order_Line__c pol : oldLines) {
                       //This catches existing PO lines that are missing their GL account association
                       
                       //RT4
                       //BLL3d List<GeneralLedgerAcctMW__c> glLookup = [Select Id,Name, GeneralLedgerAccountFF__c from GeneralLedgerAcctMW__c 
                       //BLL3d                                              where GeneralLedgerAccountFF__c=:pol.General_Ledger_Account__c limit 1];
                       GeneralLedgerAcctMW__c glAcct;
                       //BLL3d if(glLookup.size()>0){
                       //BLL3d     glAcct=glLookup[0];
                       //BLL3d } else {
                       //BLL3d     glAcct = new GeneralLedgerAcctMW__c();
                       //BLL3d }
                       glAcct = GLAMap.containsKey(pol.General_Ledger_Account__c) ? GLAMap.get(pol.General_Ledger_Account__c) : new GeneralLedgerAcctMW__c(); // BLL3a
                       /*
                       c2g__codaGeneralLedgerAccount__c[] glQuery = [Select Id,Name from c2g__codaGeneralLedgerAccount__c 
                                                                     where id=:pol.General_Ledger_Account__r.id limit 1];
                       c2g__codaGeneralLedgerAccount__c aAcct;
                       if(glQuery.size()>0){
                           aAcct=glQuery[0];
                       } else {
                           new c2g__codaGeneralLedgerAccount__c();
                       }
						*/
                       //end RT4
                       
                       indexCount++;
                       // Set the lines
                       lines.add(new lineWrap(
                           pol.dealer__Description__c,
                           pol.dealer__Amount__c,
                           //aAcct,
                           glAcct,
                           new PostingTemplateEntryRule__c(Dimension_1__c=pol.Dimension_1__c),
                           pol.Dimension_1__c,
                           pol.Add_to_Chassis__c,
                           pol.Add_to_Conversion__c,
                           indexCount
                       ));                
                   }
               }
               if(indexCount == 0){
                   indexCount++;
                   //RT4
                   // BLL3 set dimension1 on new line based on location
                   lines.add(new lineWrap('',0, new GeneralLedgerAcctMW__c(), 
                   	new PostingTemplateEntryRule__c(Dimension_1__c=(loc!=null ? loc.Financial_Force_Dimension_1__c:null)),	// BLL3a 
                   	getDivisionInfo(u), false, false,indexCount));	
               }
               getBalance();
               
           } else {
               //throw new POException('Unable to access page without purchase order ID.');
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 
                                                          'Unable to add PO lines page without purchase order ID.  If you are creating a new PO, please save and then lines will show.'));
           }        
    }
    
    /*
|   Class - lineWrap
|   Description : This wrapper class acts as the definition of a new line in the add lines page block table.
*/    
    public class lineWrap {
        public String lineDescription {get;set;}
        public Decimal amount {get;set;}
        //RT4
        //public c2g__codaGeneralLedgerAccount__c account {get;set;}
        public GeneralLedgerAcctMW__c glAccount {get; set;}
        
        public PostingTemplateEntryRule__c template {get;set;}
        public String division {get {return division;} set;}
        public Boolean addToChassis {get;set;}
        public Boolean addToConversion {get;set;}
        public Integer indexCount {get;set;}
        public Id dim1 {get;set;}
        
        public lineWrap(String descr, Decimal am,  GeneralLedgerAcctMW__c glAcct, PostingTemplateEntryRule__c tpl, 
                        String dvs, Boolean aChas, Boolean aConv, Integer iCount) {
			lineDescription     =   descr;
			amount              =   am;
			//account             =   act; RT4
			glAccount           =   glAcct;
			template            =   tpl;  
			division            =   dvs;
			addToChassis        =   aChas;
			addToConversion     =   aConv;
			indexCount			    = 	iCount;
			if (glAccount!=null && glAccount.Id!=null) template.General_Ledger_Acct__c = glAccount.Id;
			if (glAccount!=null && glAccount.GeneralLedgerAccountFF__c!=null) template.General_Ledger_Account__c = glAccount.GeneralLedgerAccountFF__c;
			System.debug(glAcct);
			System.debug(this);
		}
    }
    
    /*
	|
    |   Method getDivisionInfo
    |       @param User
    |       @result String:  Dimension 1 Name
    |       
    |       Description: This method determines the assigned financial force dimension 1 based on the user record
    */
    public String getDivisionInfo(User u) {
    	String dim1name = null;	// BLL2a
    	try {	// BLL2a
        dealer__Dealer_Location__c loc_c  =   [Select Id, Name, Financial_Force_Dimension_1__c 
                                               from dealer__Dealer_Location__c 
                                               where dealer__Company_Number__c =:u.Division limit 1];
        c2g__codaDimension1__c dim1   =   [Select Id, Name from c2g__codaDimension1__c 
                                           where Id=:loc_c.Financial_Force_Dimension_1__c limit 1];
		dim1name = dim1.Name;	// BLL2a
    	} catch(Exception e) {} 	// BLL2a
        //BLL2d return dim1.Name;
        return dim1name;	// BLL2a
    }
    
/*
|
|   Method getAccountInfo
|       @param PostingTemplateEntryRule
|       @result String: account Id 
|   
|       Description: Takes the template field and looks up a GL id for the Account field    
*/
    //RT4
    public GeneralLedgerAcctMW__c getAccountInfo(PostingTemplateEntryRule__c t) {
        if(t == null) {
            system.debug('new POException(\'Unable to find a ledger account for this entry.\'');
            return null;
        } else {
            GeneralLedgerAcctMW__c theAcct = [select Id, Name, GeneralLedgerAccountFF__c from GeneralLedgerAcctMW__c where Id=:t.General_Ledger_Acct__c limit 1];
            return theAcct;            
        }
    }
    
    /*
    public c2g__codaGeneralLedgerAccount__c getAccountInfo(PostingTemplateEntryRule__c t) {
        if(t == null) {
            system.debug('new POException(\'Unable to find a ledger account for this entry.\'');
            return null;
        } else {
            c2g__codaGeneralLedgerAccount__c theAcct = [select name from c2g__codaGeneralLedgerAccount__c where id=:t.General_Ledger_Account__c limit 1];
            return theAcct;            
        }
    }
    */
    //end RT4
    
    /*
|   Method getBalance
|       @param None
|       @result String: Decimal balance 
|       Description: Resets the balance after a row is added/removed    
*/
    public Decimal getBalance() {
        balance =  0;
        for(lineWrap l : lines) {
            balance += l.amount;    
        }
        return balance;
    }
    
    /*
|
|   Method addLine
|       @param 
|       @result PageReference
|
|       Description: This method provides a new line in the user interface for vehicle purchase order lines
*/
    public PageReference addLine() {
        //BLL3d for(lineWrap l : lines) {
        //BLL3d     //RT4 Use MW object
        //BLL3d     if(l.glAccount.id == null) {
        //BLL3d         l.glAccount = getAccountInfo(l.template);
        //BLL3d         //l.account = getAccountInfo(l.template);             
        //BLL3d     } else {
        //BLL3d         
        //BLL3d         //system.debug(l.template); //null!
        //BLL3d         //system.debug(l.template.General_Ledger_Account__c);
        //BLL3d         //system.debug(lines.get(lines.size()-1));
        //BLL3d     }
        //BLL3d }
        //Get last row -   system.debug(lines.get(lines.size()-1));
        //Get all rows -   system.debug(lines);
        indexCount++;
        getBalance();
        lines.add(new lineWrap(
            '', 
            0, 
            //new c2g__codaGeneralLedgerAccount__c(), 
            new GeneralLedgerAcctMW__c(),
            new PostingTemplateEntryRule__c(Dimension_1__c=(loc!=null ? loc.Financial_Force_Dimension_1__c:null)),	// BLL3a 
            getDivisionInfo(u), 
            false, 
            false,
            indexCount
		));
        resetRowCount();
        return null;
    }
    
    /*
|
|   Method saveLines
|       @param 
|       @result PageReference of the purchase order
|
|       Description : Saves the transaction lines as purchase order lines.  These lines will be committed to GL
*/
    public PageReference saveLines() {
        getBalance();
	
		// BLL3a
		Map<Id,GeneralLedgerAcctMW__c> GLAMap = new Map<Id,GeneralLedgerAcctMW__c>();
		Set<Id> GLAIds = new Set<Id>();
		for(lineWrap d : lines) {
			GLAIds.add(d.template.General_Ledger_Acct__c);
		} 
		System.debug(GLAIds);
		for(GeneralLedgerAcctMW__c glamw : [
				select Id, Name, GeneralLedgerAccountFF__c from GeneralLedgerAcctMW__c
				where Id in :GLAIds
			]) {
			GLAMap.put(glamw.Id, glamw);
		}
		System.debug(GLAMap);
		// BLL3a

		// BLL2a
		for(Integer i=0; i<lines.size(); i++) {
			if (lines[i].amount==0 && lines[i].lineDescription=='') {
				lines.remove(i);
				--indexCount;
			}
		}
		resetRowCount();
		// BLL2a end

        for(lineWrap d : lines) {//Clean up the empty form rows.
            //BLLxd cannot modify a collection while it is being iterated
            //BLLxd if(d.amount==0 && d.lineDescription=='') {
            //BLLxd     deleteLine();
            //BLLxd }
            //Get valid GL Accounts
            //RT4
            //BLLd else {	// BLL3d always refresh from screen's lookup! if(d.glAccount.id == null) {
                System.debug(d.template);
                //BLL3d d.glAccount = getAccountInfo(d.template);
                //d.account = getAccountInfo(d.template);   
                System.debug(d.glAccount);
                System.debug(d.template);
                d.glAccount = GLAMap.get(d.template.General_Ledger_Acct__c);	// BLL3a
                d.template.General_Ledger_Account__c = (d.glAccount!=null) ? d.glAccount.GeneralLedgerAccountFF__c : null;	// BLL3a
                System.debug(d.glAccount);
            //BLLd }
        }

        if(po.Id == null) throw new POException('Unable to save purchase order lines, no Purchase Order exists yet.');

        // Remove Existing Lines to allow the user to update
        List<dealer__Purchase_Order_Line__c> poLinesExisting = [Select Id from dealer__Purchase_Order_Line__c 
                                                                where dealer__Purchase_Order__c =:po.Id limit 2000];
        if(poLinesExisting.size()>0) {        
            try {
                delete poLinesExisting;
            } catch(DmlException e) {
                throw new POException('Unable to reset purchase order lines before saving new lines.  Error '+e.getMessage());
            }
        }    
        
        List<dealer__Purchase_Order_Line__c> poLines = new List<dealer__Purchase_Order_Line__c>();
        for(lineWrap l : lines) {
			System.debug(l);
			System.debug(l.template);
            Decimal chassis;
            Decimal conversion;
            if(l.amount!=null && l.template!=null && l.template.General_Ledger_Account__c!=null ) {	// BLL3c
				// BLL6 
                // BLL6 poLines.add(new dealer__Purchase_Order_Line__c(
				dealer__Purchase_Order_Line__c pol = new dealer__Purchase_Order_Line__c(
				// BLL6 end
                    dealer__Purchase_Order__c=po.Id,
                    dealer__Amount__c=l.amount,
                    General_Ledger_Account__c=l.template.General_Ledger_Account__c, //RT4, BLL3c
                    dealer__Description__c=l.lineDescription,
                    Add_to_Chassis__c=l.addToChassis,
                    Add_to_Conversion__c=l.addToConversion,
                    Dimension_1__c=l.template.Dimension_1__c
				// BLL6
                //));       
				);
				if (pol.Dimension_1__c==null && loc!=null) pol.Dimension_1__c = loc.Financial_Force_Dimension_1__c;
				// BLL6
				poLines.add(pol);
                
            } else {         
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'All lines must contain an amount and general ledger account to be saved.'));
            }
        }
        if(poLines.size()>0) {
            try {
                insert poLines; 
            } catch(DmlException e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error trying to save purchase order lines '+e.getMessage()));
            }
        }
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Lines Saved'));
        
        return null;
    }
    
    /*
|
|   Method deleteLine
|       @param Id dId
|       @result PageReference
|   
|       Description : Using a row indexCount value, remove an object from lines collection. 
|
*/
    public PageReference deleteLine() {
        //system.debug('Deleting row '+indexCount);       
        lines.remove(indexCount-1); //JG: Only removed from List. Save method will handle DML delete.
        indexCount--;
        resetRowCount();
        getBalance();
        return null;
    }
    
    /*		Method resetRowCount
|       @param none
|       @result PageReference
|       Description : Helper method to reset row index after item is added or deleted
*/    
    public PageReference resetRowCount(){
        Integer newcount = 1;
        for (lineWrap l : lines) {
            l.indexCount = newcount;
            newcount++;
        }        
        return null;        
    }
    
    /*		Method validateForm
|       @param none
|       @result PageReference
|       Description : Helper method to validate form
*/    
    public Boolean validateForm(){
		// BLL5
		boolean passed = true;
		// BLL5 end
        Decimal bal = getBalance();
        if(bal!=0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Balance must be zero. Use debits and credits to balance to zero'));
            //BLL5
			//return false;   	
			passed = false;
			// BLL5 end
        }
		// BLL5
		List<dealer__Purchase_Order__c> checkpos = [select Id, dealer__Accepted_DateTime__c from dealer__Purchase_Order__c where Id=:po.Id limit 1];
		if (checkpos.size()!=1) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Internal error: Could not find PO ' + po.Name + ':' + po.Id));
			passed = false;
		}
		if (checkpos.size()>=1 && checkpos[0].dealer__Accepted_DateTime__c!=null) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'PO ' + po.Name + ' has already been accepted'));
			passed = false;
		}
        //return true;        
		return passed;
		// BLL5 end
    }    
    
    
    /*
|
|   Method acceptPO
|       @param 
|       @result PageReference
        RT5
|
*/
    public PageReference acceptPO() {
        
        Boolean status = validateForm();
        if (status == false) { 
            return null;
        }
        
        saveLines();
        
        dealer__Vehicle_Inventory__c vInc = createVehicle();
        String accountingPayload = '{"recordId" : "'+po.Id+'", "orgId" : "'+UserInfo.getOrganizationId()+'", "requestedBy" : "'+UserInfo.getUserId()+'", "action" : "accept_purchase_order"}';

		if (vInc!=null) {	// BLL5
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Purchase Order Accepted'));
        	FFAccounting.emailAsyncHandler(accountingPayload);
			// BLL5 - set value so button will re-render as disabled
			po.dealer__Accepted_DateTime__c = DateTime.now();
			// disable accept button!
			update(new dealer__Purchase_Order__c(Id=po.Id, dealer__Accepted_DateTime__c=po.dealer__Accepted_DateTime__c));
		}
		// BLL5 end
        return null;
        //RT5
        /*
        if (vehicleInv != null){
            Id jId = createJournalHeader();
            
            List<dealer__Purchase_Order_Line__c> allPoLines = [Select Id, dealer__Account__c, General_Ledger_Account__c, dealer__Description__c, 
                                                               dealer__Amount__c, Add_to_Chassis__c, Add_to_Conversion__c
                                                               from dealer__Purchase_Order_Line__c 
                                                               where dealer__Purchase_Order__c =:po.Id limit 2000];
            
            
            
            List<c2g__codaJournalLineItem__c> allJournalLines = new List<c2g__codaJournalLineItem__c>();
            
            if(allPoLines.size()>0) {
                chassisCost = 0;
                conversionCost = 0;         
                for (dealer__Purchase_Order_Line__c ln : allPoLines) {              
                    c2g__codaJournalLineItem__c theLine = journalEntry( jId, 
                                                                       loc.Financial_Force_Dimension_1__c, 
                                                                       ln.General_Ledger_Account__c, 
                                                                       'General Ledger Account', 
                                                                       ln.dealer__Description__c, ln.dealer__Amount__c,
                                                                       po.dealer__Vehicle_Inventory__c
                                                                      );  
                    
                    if(ln.Add_to_Chassis__c==true) {
                        chassisCost += ln.dealer__Amount__c;
                    }
                    if(ln.Add_to_Conversion__c==true){
                        conversionCost += ln.dealer__Amount__c;
                    }
                    
                    allJournalLines.add(theLine);                    
                }
                
                try {
                    insert allJournalLines;
                    po.dealer__Accepted_DateTime__c = Date.today();
                    po.dealer__Accepted_By__c = UserInfo.getUserId();   
                    po.dealer__Status__c = 'Accepted';
                    
                    // Update the vehicle inventory record

                    // If the vehicle did not get created, and this is an update to an existing control#, set the Vehicle
                    if(vInc == null) {
                      
                      vInc = getVehicleInv();

                      if(vInc.Id == null) {
                        throw new POException('Unable to Accept PO, Vehicle Record does not exist.');
                      }
                    }
                    
                    //RT2
                    if(vInc.dealer__Vehicle_Cost__c != null) {
                        chassisCost += vInc.dealer__Vehicle_Cost__c;
                    }
                    if(vInc.Conversion_Cost__c != null) {
                        conversionCost += vInc.Conversion_Cost__c;
                    }
                    //end RT2
                    
                    update new dealer__Vehicle_Inventory__c(Id=vInc.Id, dealer__Vehicle_Cost__c=chassisCost, Conversion_Cost__c=conversionCost);
                    update po;
                } catch(DmlException e) {
                    //System.debug(e.getMessage());
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to Create Journal Line '+e));
                    return null; 
                } 
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Purchase Order Accepted'));
            //Grab Journal Header for ui
            List<c2g__codaJournal__c> jHead = [SELECT Id, c2g__codaJournal__c.Name, c2g__JournalDescription__c, c2g__JournalDate__c 
                                               FROM c2g__codaJournal__c 
                                               where Purchase_Order__c=:po.id limit 100];
            if(jHead.size()>0) {
                journalHeaders = jHead;
            }       
            return null;    
            
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No vehicle is saved on this PO. Unable to create journal'));
            return null;
        }
        */
        
    }
       
    
    
    
    /*      Method getvehicleInv
    |       @param null
    |       @result : Vehicle property is set 
    */
    public dealer__Vehicle_Inventory__c getvehicleInv(){
        //Check for existing vehicle
        List<dealer__Vehicle_Inventory__c> existingVehs = [SELECT Id, name, dealer__Stock_Number__c, dealer__Vehicle_Cost__c, Conversion_Cost__c //RT2 - added cost + conversion
                                                           FROM dealer__Vehicle_Inventory__c 
                                                           WHERE dealer__Stock_Number__c=:po.dealer__StockNumber__c limit 1];
        
        if(existingVehs.size()>0) {
            vehicleInv = existingVehs[0];
        }
        return null;                
    }
    
    
    
    /*		Method createVehicle
    |       @param null
    |       @result : Vehicle Inventory 
    |       Description: This method creates a new vehicle inventory record when a PO is accepted
    */
    public dealer__Vehicle_Inventory__c createVehicle() {
        List<dealer__Purchase_Order__c> poVehicle = [SELECT Name, dealer__Make__c, dealer__Model__c, dealer__StockNumber__c, dealer__Company__c,   
                                                     dealer__VIN__c, dealer__Year__c, dealer__Vehicle_Inventory__c, dealer__Vehicle_Status__c
                                                     FROM dealer__Purchase_Order__c WHERE Id=:po.Id limit 1];

        if(poVehicle[0].dealer__Vehicle_Inventory__c!=null) {
            //RT2 - added cost + conversion
          return [Select Id, Name, dealer__Year__c, dealer__Make__c, dealer__Model__c, dealer__VIN__c, dealer__Status_Code__c, dealer__Vehicle_Cost__c, Conversion_Cost__c from dealer__Vehicle_Inventory__c where Id=:poVehicle[0].dealer__Vehicle_Inventory__c limit 1];
        }
        
        if (poVehicle[0].dealer__Year__c == null || poVehicle[0].dealer__Make__c == null || poVehicle[0].dealer__Model__c == null || poVehicle[0].dealer__StockNumber__c==null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to Create Vehicle: Year, Make, Model and Stock nbr are requied fields '));
            return null;
        }                                                        
        //JG: most of these fields are blank in the DB        
        if (poVehicle.size()>0){
            dealer__Purchase_Order__c pov = poVehicle[0];
            
            dealer__Vehicle_Inventory__c v = new dealer__Vehicle_Inventory__c();
            
            if (pov.dealer__Make__c == null) v.dealer__Make__c ='Unknown';
            else v.dealer__Make__c = pov.dealer__Make__c;
            if (pov.dealer__Model__c == null) v.dealer__Model__c ='Unknown';
            else v.dealer__Model__c = pov.dealer__Model__c;
            if (pov.dealer__Year__c == null) v.dealer__Year__c ='0000';
            else v.dealer__Year__c = pov.dealer__Year__c;  
            if (pov.dealer__StockNumber__c == null) v.dealer__Stock_Number__c ='0000';
            else v.dealer__Stock_Number__c = pov.dealer__StockNumber__c;  
            v.dealer__Vehicle_Cost__c = chassisCost;
            v.Conversion_Cost__c = conversionCost;
            
            if(pov.dealer__VIN__c==null || pov.dealer__VIN__c == '') v.dealer__VIN__c = pov.name;
            else v.dealer__VIN__c = pov.dealer__VIN__c;

            v.dealer__Status_Code__c = pov.dealer__Vehicle_Status__c;
            v.dealer__Store_Location__c = pov.dealer__Company__c;
            
            try {
                insert v;
                getvehicleInv();
                return v;
            } catch(DmlException e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to Create Vehicle '+e));
                vehicleInv = null;
                return null; 
            }   
        } else {
            system.debug('poVehicle.size()!>0');
        }
        return null;
    }
    
    
    /* 		Method getLocationFFCompany
    |       @param Id compid
    |       @result : company 
    |       Description: This methods creates a new vehicle inventory record when a PO is accepted
    */
    public c2g__codaCompany__c getFFCompany(Id compid) {
        // Get FF Company Information
        c2g__codaCompany__c comp=null;
        if (compid!=null) {
            List<c2g__codaCompany__c> comps = [select Id, Name from c2g__codaCompany__c where Id=:compid];
            if (comps.size()>0) {
                comp = comps[0];
            } else {
                throw new POException('Not authorized to the financial company');
            }
        } else {
            throw new POException('Missing the financial company');
        }
        // Currently selected company
        List<ID> groupIds = new List<ID>();
        for(GroupMember member : [select GroupId from GroupMember where Group.Type = 'Queue' 
                                  and UserOrGroupId = :UserInfo.getUserId()]) {
                                      groupIds.add(member.GroupId);				
                                  } 
        
        System.debug('GROUP Ids'+groupIds);
        // BLL1d System.debug([SELECT Id, Division FROM User WHERE Id =:UserInfo.getUserId() ]);
        System.debug(u);	// BLL1a
        c2g__codaCompany__c[] companies = 
            [select RecordType.Name, Id, Name, c2g__TaxCode__c, c2g__CODABaseDate1__c, c2g__CODADaysOffset1__c 
             from c2g__codaCompany__c where OwnerId in :groupIds];
        // Ensure the user has a single current company
        if (companies.size() == 0) throw new POException('Current company has not been set for this user');
        if (companies.size() > 1) throw new POException('This operation is not valid in multiple company mode'); 
        if (companies[0].Id!=comp.Id) 
            throw new POException('Your current company is ' + companies[0].Name + '. '
                                  + 'Please select the transaction company ' + comp.Name + '.');
        
        return comp;
    }    
    
    /*
    |   Method createJournal
    |       @param null
    |       @result : Journal Id
    |       Description: This methods creates a new journal record.
    */
    public Id createJournalHeader() {
        system.debug('Starting createJournal()');
        // Generate Journal Items for Posting
        if(loc.Company__c==null) throw new POException('Dealership Location does not have the Financial Force Company Set.');
        
        c2g__codaCompany__c comp = getFFCompany(loc.Company__c);
        
        // Get Accounting Currency
        c2g__codaAccountingCurrency__c[] curl = [Select Id from c2g__codaAccountingCurrency__c where c2g__OwnerCompany__c =:comp.Id limit 1];
        if(curl.size()==0) throw new POException('Error : The Company Selected does not have an active currency set');

        c2g__codaAccountingCurrency__c cur = curl[0];
        // Get Period Data
        c2g__codaPeriod__c[] periodl =  [Select Id from c2g__codaPeriod__c where c2g__StartDate__c >=:Date.today() and c2g__Closed__c=false limit 1];
        if(periodl.size()==0) throw new POException('Error : Current Accounting Period not Open');

        c2g__codaPeriod__c period = periodl[0];
        // Add Error if Period is not open does not exist
        
        System.debug('Prep Create Journal');
        
        // Build the Journal
        c2g__codaJournal__c tJrnl       =     new c2g__codaJournal__c();
        tJrnl.c2g__OwnerCompany__c      =     comp.Id;
        tJrnl.c2g__JournalCurrency__c   =     cur.Id;
        tJrnl.c2g__JournalDescription__c=     'Vehicle PO created by ' + u.Name; //????
        tJrnl.c2g__JournalDate__c       =     Date.today();
        tJrnl.c2g__Reference__c         =     po.Name;
        tJrnl.c2g__Period__c            =     period.Id;
        tJrnl.Source__c 				        = 	  'PUR';  //?????
        tJrnl.Stock_Number__c 			    =	    po.dealer__StockNumber__c;
        tJrnl.Purchase_Order__c			    =	    po.Id;
        
        System.debug(tJrnl);
        
        try {
            insert tJrnl;
        } catch(DmlException e) {
            System.debug(e.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to Create Journal '+e));
            return null; 
        }   
        
        return tJrnl.Id;   
    } 
    
    
       /* 
        * Create Payable Invoice
        * 
        * 
        *
        */   
    public PageReference createPayableInvoice() {
        
        if(po.dealer__Company__c==null) throw new POException('Purchase Orders must have a Company set before creating a payable invoice.');
        
        if(po.dealer__Vendor__c==null) throw new POException('Purchase Orders must have a Vendor set before creating a payable invoice.');
        
        if(po.dealer__Invoice_Date__c==null || po.dealer__Invoice_Amount__c==null || po.dealer__Invoice_Number__c==null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Purchase Order Invoice Amount, Invoice Date and Invoice Number must be set before creating a payable invoice.'));
            return null;             
        }
        
        if(po.dealer__Invoice_Amount__c != getBalance()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Purchase Order Invoice Amount does not equal the balance amount.'));
            return null;      
        }
        
        List<dealer__Purchase_Order_Line__c> poLines = [Select Id, Name, General_Ledger_Account__c, dealer__Amount__c , dealer__Description__c, Add_to_Chassis__c, Add_to_Conversion__c, Dimension_1__c
                                                        from dealer__Purchase_Order_Line__c where dealer__Purchase_Order__c =:po.Id];
        
        if(poLines.size()==0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Purchase Order must have lines to create a payble invoice'));
            return null;             
        }
        
        try {
            
            // Create the Payable Invoice Header
            c2g__codaPurchaseInvoice__c payableInvoice = FFAccounting.createPayableInvoice( po.dealer__Company__c ,
                                                                                           loc.Financial_Force_Dimension_1__c, 
                                                                                           po.dealer__Vendor__c, 
                                                                                           po.dealer__Invoice_Date__c, 
                                                                                           'Vehicle Purchase', 
                                                                                           po.dealer__Invoice_Number__c
                                                                                          );
            
            System.debug(payableInvoice);
            insert payableInvoice;
            
            // Add The payable Lines
            List<c2g__codaPurchaseInvoiceExpenseLineItem__c> payableLines = FFAccounting.createPayableInvoiceLines(payableInvoice.Id, loc.Financial_Force_Dimension_1__c, poLines);
            
            System.debug(payableLines);
            insert payableLines;
            
            po.Payable_Invoice__c = payableInvoice.Id;
            update po;
            
            // Update Vehicle Chassis / Conversion cost from the Purchase Order
            dealer__Vehicle_Inventory__c v = FFAccounting.addsToCost(po.Id, poLines);
            update v;
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Payable Invoice Created Successfully'));
            return null;
            
        } Catch(DmlException e) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error creating the payable invoice '+e.getMessage()));
            return null;  
            
        } Catch(SObjectException e) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error creating the payable invoice '+e.getMessage()));
            return null;  
            
        } Catch(Exception e) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error creating the payable invoice '+e.getMessage()));
            return null;  
        }   
        
        return null;
    }
    
    public c2g__codaJournalLineItem__c journalEntry(Id journal, Id locid, Id account, String type, String drcr, Decimal amount, Id vehicle) {
        c2g__codaJournalLineItem__c tempLine = new c2g__codaJournalLineItem__c();   
        tempLine.c2g__Journal__c                =   journal;
        tempLine.c2g__Dimension1__c             =   locid;
        tempLine.c2g__LineDescription__c        =   drcr;
        tempLine.c2g__GeneralLedgerAccount__c   =   account;
        tempLine.c2g__Value__c                  =   amount;
        tempLine.c2g__LineType__c               =   type;  //JG: Need confirmation on values here.
        tempLine.c2g__DebitCredit__c			=	getCreditDebit(amount);
        tempLine.Control__c                     =   po.dealer__StockNumber__c;
        tempLine.Vehicle_Inventory__c           =   vehicle; // JVK  - Added per Jerry Augusts request on 11/11/15
        
        return tempLine;    
    }
    
    public String getCreditDebit(Decimal d) {
        if(d==null) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to Create Journal. Amount is null.'));
        if(d<0) {
            return 'Credit';
        } else {
            return 'Debit';
        }
    }    

    //RT6
    public void savePO() {
      update po;      
    }

    //RT6
    public void createVehicleFromTemplate() {
      Id id = VehicleInventoryTemplateClone.createVehicleFromTemplate(po.Vehicle_Inventory_Template__c, po.dealer__VIN__c, po.dealer__StockNumber__c);
      po.dealer__Vehicle_Inventory__c = id;
      update po;
    }
    
    // Standard Exception extend
    public class POException extends Exception{
    }
    
    
}