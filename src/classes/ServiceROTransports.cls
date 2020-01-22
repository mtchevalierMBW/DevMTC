/*
* Service RO Transport - Controls the repair order HTML5 Interactions
* Tested by: ServiceROTransports_Test	//, ServiceROTransports_TC  
*
* Coverage:
*	2018-05-11	76% (860/1135)
*	2018-05-16	77% (876/1136)
*	2019-12-30	76%	(919/1203)
*
*   2015-10-12  J.Kuljis        JVK1 - Rollback Protection on Failed DML
*   2015-12-31  D. Ray          DR1 - Always update Cause Extended since that is the displayed field. The front end with display the value of Cause__c if CauseExtended__c is null
*   2016-01-14  B. Leaman       BLL4 - Support for partType (New, Rebuilt, Reconditioned, Used)
*   2016-01-31  J. Kuljis       JVK2 - Prevent Obsolete Parts from rendering in the search dialog
*   2016-02-15  J. Kuljis       JVK3 - Update and Delete tech times not respecting the dealer__Actual_Time__c field on the job line.
*                                    - False error message when deleting technician time
*   2016-02-26  RedTeal         RT1  - Any requests to modify or create an RO line will be blocked if the RO doesn't have the status 'open' or 'cashier'
*   2016-03-02  J. Kuljis       JVK4 - Fix cost of part line totaling incorrectly.  Field mapping
*   2016-03-02  RedTeal         RT2  - Return cost of part with lookup
*   2016-03-05  J. Kuljis       JVK5 - Parts line deletion was creating a cancelling entry in the ledger, vs. backing out the lines associated.
*   2016-03-21  J. Kuljis       JVK6 - Multi-Quantity negative sales issue
*   2016-03-24  RedTeal         RT3  - Resolved issue of parts order not being deleted when a part line was deleted
*   2016-03-30  J. Kuljis       JVK7 - Allow removal of parts even if on orders, but do not delete order line if it was processed.
*   2016-04-01  RedTeal         RT4  - When deleting a part line, the associated part order should be changed to a 0 quantity ordered and the lookup to a po should be set to null
if a PO already exists for the part order, otherwise delete the part order
*   2016-04-20  J. Kuljis       JVK8 - Adjustment on the Ledger when sold negative and removed from invoice.
*   2016-04-28  RedTeal         RT5  - Changing labor types will now update part lines
*   2016-05-23  RedTeal         RT6  - Reworked recalculation after labor type change to reduce soql queries
*   2016-07-21  J. Kuljis       JVK9 - Add error handling on the lineTotalParts() to trap failures
*   2016-07-22  J. Kuljis       JVK10 - Quantity not taken into consideration when changing labor type
*   2016-07-27  J. Kuljis       JVK11 - When payment type is changed Misc total would fail
*   2016-07-29  B. Leaman       BLL5 - Use CurrentUserSingleton instead of SOQL
*   2016-08-02  J. Kuljis       JVK12 - Re-order throw new exception with Return Error.  The throw exception was not notifying the end user that there was a problem.
*   2016-08-11  D. Ray          DR2 - added dealer__Physical_OnHand__c to get part lookup
*   2016-08-24  J. Kuljis       JVK13 - Change condition of always creating Part Order when a Warrranty Labor Type is Present
*   2016-09-06  D. Ray          DR3 - Always delete part order lines, even if there is a PO opened.
*   2016-09-22  S. Utture       SU1 - Calculate part cost when Job Line pay type is updated from a Customer Pay to a Warranty Pay type 
*   2016-09-30  B. Leaman       BLL6 - Round all dollar calcs that can result in too many decimals.
*   2016-11-02  B. Leaman       BLL7 - Return friendlier error messages for display.
*   2016-11-03  D. Ray          DR4  - Return friendlier error messages for display for Misc Items.
*   2016-11-08  B. Leaman       BLL8 - RT6 LaborRateRecalculation is not respecting store overrides.
*   2016-12-28  B. Leaman       BLL9 - Adj. error message handling for new trigger errors on tech time.
*   2017-01-09  J. Kuljis       JVK14 - Allow removal of Accepted PO Parts Lines (Order is filled by CPT)
*   2017-01-30  A. Bangle       ACB1 - Added in line to get rid var from url of operations action.  Updated getOperationCodes function to remove inactive from list but allow for existing to remain
*	2017-02-09	J. Kuljis		JVK15- Allow override of logic if MW RO Protect custom setting is false
* 									 - After discussing the business rules, it might be plausible to allow chaning the labor rate on tech time over 15 days, and last month.
*	2017-03-03	B. Leaman		BLL10 - get list of technicians from managed Dealer_Location_User object.
*	2017-04-20	B. Leaman		BLL11 - allow exception in laborRateRecalculation to percolate back up & show on screen.
*	2017-05-18	B. Leaman		BLL12 - handle part search terms with blanks where trimmed value is less than 2 characters.
*	2017-07-11	B. Leaman		BLL13 IR-0009585 - Allow shop supplies for production work in Calif. 
*	2017-07-13	B. Leaman		BLL14 - improve error handling (don't report error when it worked).
*	2017-07-13	B. Leaman		BLL15 IR-0017038 Only active technicians.
* 	2017-08-03	J. Kuljis		JVK16 - Update the Transaction Note to be standard across managed and non-managed code.
*	2017-10-09	B. Leaman		BLL16 - wrong setting controling tech time date.
*	2018-05-07	B. Leaman		BLL17 - pull GL accounts for automatic freight line, rewrite Misc Chg Options access for efficiency.
*	2019-01-02	B. Leaman		W-000491 BLL18 Adopt DealerTeam updates to coincide with their next package update. (No actual effect at present - calculates order qty but does not use it)
*	2019-04-15	B. Leaman		W-000647 BLL19 - special permission to allow updating older tech time.
*	2019-08-05	B. Leaman		W-000728 BLL20 - trying to remove SOQL limit tests to ensure updates occur.
*	2019-09-17	B. Leaman		W-000730 BLL21 - DT 5.x requires location on parts invoice object records
*	2019-12-06	B. Leaman		W-000788 BLL22 - split book from actual time; shop supplies based on actual time
*								And move job line dealer__Labor_Charges__c calc to trigger -- always based on book time.
*/
public class ServiceROTransports {
    public String trans {get;set;} // What data is the transport expected to return
    public String roId  {get;set;}
    public String rid {get;set;}
    public String jobLineId {get;set;}
    public String ttId {get;set;}
    public String ttResult {get;set;} //JVK3
    public String updateResult {get;set;}
    public String lookupPartResult {get;set;}
    public String masterId {get;set;} // Parts Master Id
    public String locationId {get;set;} // Location Id
    public String search {get;set;}
    public String partLine;
    public dealer__Dealer_Location__c location {get;set;}
    public Boolean allowChanges {get; set;} //RT1

    public String error_string;

    public Map<String, String> urlParameters = new Map<String, String>();

    public String responseString {get;set;} // DR4
    
    public Boolean roProtectOff = false;

	private Map<String,Misc_Charge_Option__c> mcoMap;	// BLL17
	private Id mcoLocId;	// BLL17
	private String mcoLocAbbrev;	// BLL7a
	Set<String> ProductionWork = new Set<String>{'IEN','IEO','IEU','GRNV','GRUV','MCEO','IHA'};	// BLL13a, BLL22 moved

	
	// BLL17a
	public void LoadMiscChargeOptionsForLocId(Id locid) {
		if (mcoMap==null || mcoLocId!=locid) {
			mcoLocId = locid;
			mcoMap = new Map<String, Misc_Charge_Option__c>();
			for(Misc_Charge_Option__c mco : [
				select Id, Name, General_Ledger_Account__c, General_Ledger_Acct_MW__c, 
					General_Ledger_Acct_MW__r.GeneralLedgerAccountFF__c, Quantity__c, Rate__c,
					Location__c, Location__r.dealer__Company_Number__c
				from Misc_Charge_Option__c 
				where Location__c=:mcoLocId]
			) {
				mcoMap.put(mco.Name, mco);
				mcoLocAbbrev = mco.Location__r.dealer__Company_Number__c;
			}
		}
	}
	public void LoadMiscChargeOptionsForLocAbbrev(String abbrev) {
		if (mcoMap==null || mcoLocAbbrev!=abbrev) {
			mcoMap = new Map<String, Misc_Charge_Option__c>();
			mcoLocAbbrev = abbrev;
			for(Misc_Charge_Option__c mco : [
				select Id, Name, General_Ledger_Account__c, General_Ledger_Acct_MW__c, 
					General_Ledger_Acct_MW__r.GeneralLedgerAccountFF__c, Quantity__c, Rate__c,
					Location__c, Location__r.dealer__Company_Number__c
				from Misc_Charge_Option__c 
				where Location__r.dealer__Company_Number__c=:mcoLocAbbrev]
			) {
				mcoLocId = mco.Location__c;
				mcoMap.put(mco.Name, mco);
			}
		}
	}
	// BLL17a end

    public ServiceROTransports() {
        
        // JVK15
        //BLL16d wrong control! MW_TriggerControls__c roProtect = MW_TriggerControls__c.getInstance('RepairOrderProtect');
        MW_TriggerControls__c roProtect = MW_TriggerControls__c.getInstance('TechTimeDate');	// BLL16a
        roProtectOff = (roProtect!=null&&roProtect.Enabled__c==false);
        // End JVK15

        urlParameters = ApexPages.currentPage().getParameters();
        error_string  = null;
        trans = '';
        roId  = '';
        rid = '';

        if(ApexPages.currentPage().getParameters().get('action') == 'operations') {
            if( ApexPages.currentPage().getParameters().get('rid') != null ) rid = ApexPages.currentPage().getParameters().get('rid'); //ACB1
            trans='operations';
        }

        if(ApexPages.currentPage().getParameters().get('action')== 'payment_methods') {
            trans='payment_methods';
        }

        if(ApexPages.currentPage().getParameters().get('action')== 'techs') {
            trans='techs';

            if( ApexPages.currentPage().getParameters().get('roId')!=null ) roId = ApexPages.currentPage().getParameters().get('roId');
        }

        if(ApexPages.currentPage().getParameters().get('action')== 'misc_types') trans='misc_types';

        if(ApexPages.currentPage().getParameters().get('action')== 'stat') trans='stat';

        // Get Service Job Lines
        if(ApexPages.currentPage().getParameters().get('action')== 'rolines' && ApexPages.currentPage().getParameters().get('id')!=null) {
            trans='rolines';
            roId =ApexPages.currentPage().getParameters().get('id');
        }

        // Get second-level items
        if(urlParameters.get('action')=='read_tech_time') trans='read_tech_time';

        // Update / Create
        if(urlParameters.containsKey('attributes[type]')) trans='update_line';

        if(urlParameters.containsKey('action')&&String.valueOf(urlParameters.get('action'))=='create_line') trans='create_line';

        // Read Parts Rows
        if(urlParameters.containsKey('action')&&String.valueOf(urlParameters.get('action'))=='read_parts') {
            trans='read_parts';
            if(String.valueOf(urlParameters.get('lid'))!='') {
                jobLineId=String.valueOf(urlParameters.get('lid'));
                trans='read_parts';
            }
        }

        // Read Parts Rows
        if(urlParameters.containsKey('action')&&String.valueOf(urlParameters.get('action'))=='read_misc') trans='read_misc';

        // Searh Parts Rows
        if(String.valueOf(urlParameters.get('action'))=='search_parts') {
            search=String.valueOf(urlParameters.get('filter[filters][0][value]'));
            trans='search_parts';
        }

        if(String.valueOf(urlParameters.get('action'))=='global_inventory') {
            masterId = String.valueOf(urlParameters.get('mid'));
            trans='global_inventory';
        }

        //RT1
        Set<String> lockedActions = new Set<String>{
        	'create_line', 'update_line', 'delete_line', 
        	'create_tech_time', 'update_tech_time', 'delete_tech_time', 
        	'create_parts_line', 'update_parts_line', 'delete_parts_line',
            'create_misc', 'update_misc', 'delete_misc'
		};

		allowChanges = true;
        System.debug(String.valueOf(urlParameters.get('action')));
        System.debug(String.valueOf(urlParameters.get('roid')));
        if(lockedActions.contains(String.valueOf(urlParameters.get('action'))) && String.valueOf(urlParameters.get('roid')) != null) {
            dealer__Service_Repair_Order__c ro = [SELECT Id, dealer__Status__c FROM dealer__Service_Repair_Order__c WHERE Id = :ApexPages.currentPage().getParameters().get('roid')];
            allowChanges = ro.dealer__Status__c == 'Open' || ro.dealer__Status__c == 'Cashier';
        }
        //end RT1
    }

    public void saveAction() {	// BLL17 was returning PageReference, but all returns specified "null"
		System.debug('Begin SaveAction');
        // BLL17d Savepoint sp = Database.setSavepoint();
        /*
        if((urlParameters.containsKey('attributes[type]')
        &&  String.valueOf(urlParameters.containsKey('attributes[type]')) == 'dealer__Service_Job__c')
        || (urlParameters.containsKey('action')&&String.valueOf(urlParameters.get('action'))=='create')) {
        */

        //RT1
        if(!allowChanges) return; // BLL17d null;

		System.debug(urlParameters.get('action'));
        if(urlParameters.containsKey('action')&&String.valueOf(urlParameters.get('action'))=='create_line') {
            updateResult = updateLine();
            System.debug('created line');
        }

        if(urlParameters.containsKey('action')&&String.valueOf(urlParameters.get('action'))=='update_line') {
            updateResult = updateLine();
            System.debug('updated line');
        }

        if(urlParameters.containsKey('action') && String.valueOf(urlParameters.get('action')) == 'delete_line') {
			Savepoint sp = Database.setSavepoint();
            dealer__Service_Job__c j = [Select Id from dealer__Service_Job__c where Id=:urlParameters.get('Id') limit 1];
            try {
                updateResult = '{}';	// all a-okay!	// BLL14a
                delete j;
            } catch(Exception e) {
                //BLL9d updateResult='{"error":"'+e.getMessage()+'"}';
                //String msg = Utility.friendlyErrorMessage(e);   // BLL9a
                updateResult = '{ "error":"' + Utility.friendlyErrorMessage(e) + '"}';  // BLL9a
                Database.rollback(sp);
                //throw new ROException(e.getMessage());
            }

            //trans           =   'delete_line';
            //updateResult    =   getRoLines();
        }

        // Read Part Inventory (Moved to SaveAction in event a part must be added (DML not allowed in constructor))
        if(urlParameters.containsKey('action') && String.valueOf(urlParameters.get('action'))=='part') {
            masterId = String.valueOf(urlParameters.get('mid'));
            locationId = String.valueOf(urlParameters.get('lid'));
            trans='part';

            lookupPartResult = lookupPart();
        }

        // Create, Update, Delete Tech Time
        if(urlParameters.containsKey('action') && String.valueOf(urlParameters.get('action'))=='create_tech_time') {
            trans= 'create_tech_time';
            ttId = createTechTime();
        }
        if(urlParameters.containsKey('action') && String.valueOf(urlParameters.get('action'))=='update_tech_time') {
            trans= 'update_tech_time';
            ttId = updateTechTime();
        }
        if(urlParameters.containsKey('action') && String.valueOf(urlParameters.get('action'))=='delete_tech_time') {
            ttResult = deletTechTime();
            trans = 'delete_tech_time'; // JVK3
        }

        // Create Parts Line
        if(String.valueOf(urlParameters.get('action'))=='create_parts_line') {
            masterId = String.valueOf(urlParameters.get('mid'));
            trans='create_parts_line';
            partLine = createPartLine();
            updateResult = partLine;
        }

        // Delete Parts Line
        if(String.valueOf(urlParameters.get('action'))=='delete_parts_Line') {

            trans = 'delete_parts_Line';
            Id partlineId = urlParameters.get('Id');	// BLL17a
            deletePartLine(partlineId);	// BLL17a
        }

		System.debug(urlParameters.get('action'));

        // Update Parts Line
        if(String.valueOf(urlParameters.get('action'))=='update_parts_Line') {
            trans='update_parts_Line';
            partLine=String.valueOf(urlParameters.get('Id'));
            updateResult = updatePartLine();
        }

        // Create / Update MISC
        if(String.valueOf(urlParameters.get('action'))=='create_misc') {
            trans = 'create_misc';

            // Will be 'true' if success, or contain error message if failed
            responseString = createMisc();

            // return list of Misc Items on Success
            if(responseString == 'true') {
                responseString = getMiscItems();
            }
        }
        if(String.valueOf(urlParameters.get('action'))=='update_misc') {
            trans = 'update_misc';

            // Will be 'true' if success, or contain error message if failed
            responseString = updateMisc();

            // return list of Misc Items on Success
            if(responseString == 'true') {
                responseString = getMiscItems();
            }
        }
        if(String.valueOf(urlParameters.get('action'))=='delete_misc') {
            trans = 'delete_misc';
            deleteMisc();
        }

		System.debug('Return from SaveAction');
        //BLL17d return null;
    }


	// BLL17 - moved to its own routine
	// DeletePartline
	//-----------------------------------------
	public void deletePartLine(Id partLineId) {
		System.debug('deletePartLine');
		// BLL4a add Part_type__c
		dealer__Parts_Invoice_Line__c line = [
			select Id, Name, dealer__Quantity_Sold__c, dealer__Part__c, dealer__Job_Line__c,dealer__Quantity_Ordered__c, CreatedDate,  dealer__Cost__c, Part_type__c
			from dealer__Parts_Invoice_Line__c
			where Id=:partLineId limit 1
		];
		// JVK5
		List<dealer__Parts_Ledger__c> pendingLedgerList = [
			select Id, dealer__Quantity__c, dealer__Transaction_Note__c 
			from dealer__Parts_Ledger__c 
			where dealer__Parts_Sale_Line__c =:line.Id
		];
		dealer__Parts_Inventory__c inv = [
			select Id, dealer__On_Hand__c, dealer__On_Order__c
			from dealer__Parts_Inventory__c
			where Id=:line.dealer__Part__c 
			limit 1
		];
		String jobLineId = line.dealer__Job_Line__c;

		// Remove Misc Charges
		ServiceMiscCharges__c[] freightCharges = [Select Id from ServiceMiscCharges__c where Part_Line__c=:line.Id];


		//RT3 - moved this query to before the line deletion
		// Remove any order lines associated with this
		dealer__Parts_Order__c[] partsOrder = [
			select Id, Name, dealer__Purchase_Order__c, dealer__Quantity_Ordered__c,
				dealer__Purchase_Order__r.dealer__Status__c, dealer__Parts_Line__c, Purchase_Order_Status__c
			from dealer__Parts_Order__c
			where dealer__Parts_Line__c =:line.Id
			  and dealer__Parts_Inventory__c=:inv.Id
		];

		List<dealer__Parts_Order__c> pordersDelete = new List<dealer__Parts_Order__c>();
		List<dealer__Parts_Order__c> pordersUpdate = new List<dealer__Parts_Order__c>();
            
		System.debug('line id ' + line.id);
		System.debug(partsOrder);

		// BLL17d - don't catch & throw - rolling back a caught exception & throwing a new exception is redundant
		// BLL17d - also, the "updateResult" text isn't used on a delete_part_line action
		//BLL17d try {
			System.debug('DML delete->'+JSON.serialize(freightCharges));
			delete freightCharges;
			// Boolean lineUpdateReversed = dealer.PartInventoryControl.reversePartSale(line.Id);
			System.debug('DML delete->'+JSON.serialize(line));
			delete line;
		// BLL17d } catch(DmlException e) {
			//BLL9d updateResult='{"error":"'+e.getMessage()+'"}';
			//String msg = Utility.friendlyErrorMessage(e);   // BLL9a
			// Delete following, if just throwing a new exception
			//updateResult = '{ "error":"' + Utility.friendlyErrorMessage(e) + '"}';  // BLL9a
			//Database.rollback(sp);
			//throw new ROException(e.getMessage());
		//}

		// Update Inventory with QTY Removed
		if(inv.dealer__On_Hand__c==null) {inv.dealer__On_Hand__c=0;}
		if(inv.dealer__On_Order__c==null) {inv.dealer__On_Order__c=0;}
		if(line.dealer__Quantity_Ordered__c==null) {line.dealer__Quantity_Ordered__c=0;}
		if(line.dealer__Quantity_Sold__c==null) {line.dealer__Quantity_Sold__c=0;}

		// Set On Order as reduced value
		inv.dealer__On_Hand__c = inv.dealer__On_Hand__c+line.dealer__Quantity_Sold__c;
		inv.dealer__On_Order__c = inv.dealer__On_Order__c-line.dealer__Quantity_Ordered__c;
		if(inv.dealer__On_Order__c < 0) inv.dealer__On_Order__c = 0; // Sanity Check

		// Build the FIFO Entry
		//  JVK5 - Changed the method to remove where the line is a match v. creating a new and canceling entry
		//

            /* JVK5 - Commented Out
            List<dealer__Parts_Ledger__c> pLedger = new List<dealer__Parts_Ledger__c>();
            for(Decimal i = 1; i<=line.dealer__Quantity_Sold__c; i++) {
            pLedger.add(new dealer__Parts_Ledger__c(
            dealer__Entry_Date__c=Date.valueOf(line.CreatedDate),
            dealer__Part__c=line.dealer__Part__c,
            dealer__Quantity__c=1,
            dealer__Transaction_Note__c='Part Removed from Invoice '+line.Name,
            dealer__Item_Value__c=line.dealer__Cost__c
            )
            );
            }
            */

		List<dealer__Parts_Ledger__c> pLedger = new List<dealer__Parts_Ledger__c>();
		for(dealer__Parts_Ledger__c pupdate : pendingLedgerList) {
			if(pupdate.dealer__Transaction_Note__c==null) pupdate.dealer__Transaction_Note__c='';
			String tnote = (pupdate.dealer__Transaction_Note__c!=null && pupdate.dealer__Transaction_Note__c.right(1)!=';') ? pupdate.dealer__Transaction_Note__c +';Part removed from Invoice '+line.Name : pupdate.dealer__Transaction_Note__c +'Part removed from Invoice '+line.Name;
			Decimal adjustval = 1;// JVK8 4/20/2016 - Was 1, throwing discrepency
			if(pupdate.dealer__Quantity__c == -1) { adjustval = 0; }// JVK8 4/20/2016 - Was 1, throwing discrepency
			pupdate.dealer__Quantity__c=adjustval; // JVK8 4/20/2016 - Was 1, throwing discrepency
			pupdate.dealer__Transaction_Note__c=tnote;
			pLedger.add(pupdate);
		}
		System.debug('Deletion of Parts Line');
		System.debug(pLedger);

		/* JVK7 - PO status = Open throw error */
		for(dealer__Parts_Order__c pro : partsOrder) {
				/* // DR3
                if(pro.dealer__Purchase_Order__c!=null
                   && pro.dealer__Purchase_Order__r.dealer__Status__c == 'Open') {

                       //RT4
                       pro.dealer__Purchase_Order__c = null;
                       pro.dealer__Quantity_Ordered__c = 0;
                       pordersUpdate.add(pro);
                       //updateResult='{"error":"Open Purchase Order Exists for Part# '+inv.Name+'"}';
                       //Database.rollback(sp);

                       //throw new ROException('Open Purchase Order Exists for Part# '+inv.Name);
                   }
                else {
                */
                
			// Check to see if we have a filled order or not
			// JVK14
			if(pro.dealer__Parts_Line__c != null && 
				(pro.Purchase_Order_Status__c == 'Accepted' || pro.Purchase_Order_Status__c == 'Posted')) {
				pro.dealer__Parts_Line__c = null;
				pordersUpdate.add(pro);   
			} else {
				pordersDelete.add(pro);
			}
                // End JVK14
                /* } */ // DR3
		}

		// BLL17 don't catch, rollback & throw - that's redundant
		// BLL17d try {

                
			// JVK14
			System.debug('DML update->'+JSON.serialize(pordersUpdate));
			if(pordersUpdate.size()>0) update pordersUpdate; 
			// End JVK14
			System.debug('DML delete->'+JSON.serialize(pordersDelete));
			if(pordersDelete.size()>0) delete pordersDelete;
			//RT4
// ??? Duplicate update ???
			System.debug('DML update->'+JSON.serialize(pordersUpdate));
			if(pordersUpdate.size() > 0) update pordersUpdate;
// ??? Duplicate update end ???
			System.debug('DML update->'+JSON.serialize(inv));
			update inv;
			System.debug('DML update->'+JSON.serialize(pLedger));
			if(pLedger.size()>0) update pLedger;

		// BLL17d } catch(DmlException e) {

                //BLL9d updateResult='{"error":"'+e.getMessage()+'"}';
                //String msg = Utility.friendlyErrorMessage(e);   // BLL9a
                //BLL17d updateResult = '{ "error":"' + Utility.friendlyErrorMessage(e) + '"}';  // BLL9a
                //BLL17d Database.rollback(sp);
                //BLL17d throw new ROException(e.getMessage());
		// BLL17d}

		lineTotalMisc(jobLineId);
		lineTotalParts(jobLineId);
	}
	
		
    /*  Create / Update  */
    // BLL17 remove redundant try/catch/rollback/throw, as it's redundant
    public String createPartLine() {
		System.debug('createPartLine');

        // Set Rollback Point
        //BLL17d Savepoint sp = Database.setSavepoint();

        // Check for bad data input
        if(Decimal.valueOf(String.valueOf(urlParameters.get('QTY'))) < 0) {
            error_string = '{ "error" : "Part QTY may not be negative" }';
            return error_string;	// BLL17c was null
        }

        // Get RO Data from RID
        dealer__Service_Job__c job = [
        	select Id, Name, dealer__Service_Repair_Order__c, dealer__Line_Number__c, dealer__Labor_Type__c, Payment_Method__r.Name, Payment_Method__r.Freight_Rate__c
			from dealer__Service_Job__c
			where Id=:urlParameters.get('rid')
			limit 1
		];
        dealer__Service_Repair_Order__c ro = [
        	select Id, Name, dealer__Parts_Invoice__c, dealer__RO_Number__c,
				dealer__Company_Number__c,	// BLL21a
				dealer__Company__c, dealer__Company__r.Centralized_Purchasing_On_Off__c
			from dealer__Service_Repair_Order__c
			where Id=:job.dealer__Service_Repair_Order__c
			limit 1
		];
        System.debug('ro.dealer__Parts_Invoice__c ->'+ro.dealer__Parts_Invoice__c);
        dealer__Parts_Invoice__c pi = new dealer__Parts_Invoice__c();
        if(ro.dealer__Parts_Invoice__c==null){
            pi.Name = 'INV#'+ro.dealer__RO_Number__c;
            pi.dealer__Invoice_Number__c = ro.dealer__RO_Number__c;
            pi.dealer__Service_Repair_Order__c = ro.Id;
			// BLL21
			pi.dealer__Location__c = ro.dealer__Company__c;
			pi.dealer__Company_Number__c = ro.dealer__Company_Number__c;
			// BLL21

            //BLL17d try {
				System.debug('DML insert->'+JSON.serialize(pi));
                insert pi;
                ro.dealer__Parts_Invoice__c = pi.Id;
				System.debug('DML update->'+JSON.serialize(ro));
                update ro;
            //BLL17d } catch(DmlException e) {
            //BLL17d     Database.rollback(sp);
            //BLL17d     throw new ROException(e.getMessage());
                //return '{ "error" : "'+e.getMessage()+'" }';
                //BLL7a note: the above line will never run because of the thrown exception
            //BLL17d }

        } else {
            pi = [Select Id from dealer__Parts_Invoice__c where Id=:ro.dealer__Parts_Invoice__c limit 1];
        }

        //  Get the Selected Part
		// BLL18 - retrieve pack qty field too
        //dealer__Parts_Inventory__c inv = [
        //	select Id, Name, dealer__Description__c, dealer__List__c, dealer__Parts_Master__c,dealer__On_Hand__c,dealer__On_Order__c, dealer__Cost__c, dealer__Physical_OnHand__c, 
		//	from dealer__Parts_Inventory__c
		//	where Id=:String.valueOf(urlParameters.get('PartInventoryId'))
		//	limit 1
		//];
        dealer__Parts_Inventory__c inv = [
        	select Id, Name, dealer__Description__c, dealer__List__c, dealer__Parts_Master__c,dealer__On_Hand__c,dealer__On_Order__c, 
            		dealer__Cost__c, dealer__Physical_OnHand__c, 
            		dealer__Parts_Master__r.dealer__Pack_QTY__c
			from dealer__Parts_Inventory__c
			where Id=:String.valueOf(urlParameters.get('PartInventoryId'))
			limit 1
		];
		// BLL18 end
		System.debug(inv);

        Decimal qsold = Decimal.valueOf(String.valueOf(urlParameters.get('QTY')));
        Decimal cost  = (inv.dealer__Cost__c);
        // JVK9 Cost is updated when by FIFO Table removed *qsold on Cost
        // JVK6 When Selling Negative the cost was understated on multiple quantity sales.
        Decimal qAdd = 0;

        List<dealer__Parts_Ledger__c> insertLedger = new List<dealer__Parts_Ledger__c>();
        List<dealer__Parts_Ledger__c> updateLedger = new List<dealer__Parts_Ledger__c>();

        // Query FIFO, Derive cost and associate sale
        List<dealer__Parts_Ledger__c> fifoLedger = [
        	select Id, dealer__Quantity__c, dealer__Item_Value__c, dealer__Transaction_Note__c
			from dealer__Parts_Ledger__c
			where dealer__Parts_Sale_Line__c = NULL
			  and dealer__Part__c =:inv.Id
			  and dealer__Quantity__c > 0
			order by dealer__Entry_Date__c ASC
			limit :Integer.valueOf(qsold)
		];

        // check result size, if result size is larger or equal than requested amount satisfy from table, else satisfy what is in the table and add ledger entries
        if(fifoLedger.size()>=qsold) {
            cost = 0;
            for(Integer i=0; i<qsold; i++) {

                cost += fifoLedger[i].dealer__Item_Value__c;
				if(fifoLedger[i].dealer__Transaction_Note__c==null) {
					fifoLedger[i].dealer__Transaction_Note__c='';
				}

                updateLedger.add(new dealer__Parts_Ledger__c(
                    Id=fifoLedger[i].Id,
                    dealer__Quantity__c=0,
                    dealer__Transaction_Note__c=(fifoLedger[i].dealer__Transaction_Note__c!=null && fifoLedger[i].dealer__Transaction_Note__c.right(1)!=';') ? fifoLedger[i].dealer__Transaction_Note__c +';Sold on '+ro.Name : fifoLedger[i].dealer__Transaction_Note__c +'Sold on '+ro.Name //JVK16
                )
              );
            }
        }
        System.debug('fifoLedger.size()->'+fifoLedger.size());
        // If Results of FIFO are less than QTY Sold - Process cost for QTY sold and then the remaining value to come from part cost
        if(fifoLedger.size()<qsold && fifoLedger.size()!=0) {
            qAdd=qsold;
            cost = 0;
            for(Integer i=0; i<fifoLedger.size(); i++) {
                qAdd--;
                cost += fifoLedger[i].dealer__Item_Value__c;
                
				if(fifoLedger[i].dealer__Transaction_Note__c==null) {
					fifoLedger[i].dealer__Transaction_Note__c='';
				}
                
                updateLedger.add(new dealer__Parts_Ledger__c(
                    Id=fifoLedger[i].Id,
                    dealer__Quantity__c=0,
                    dealer__Transaction_Note__c=(fifoLedger[i].dealer__Transaction_Note__c!=null && fifoLedger[i].dealer__Transaction_Note__c.right(1)!=';') ? fifoLedger[i].dealer__Transaction_Note__c +';Sold on '+ro.Name : fifoLedger[i].dealer__Transaction_Note__c +'Sold on '+ro.Name //JVK16
                )
              );
            }

            // Update the cost of the part segments unfilled
            for(Decimal i=1; i<=qAdd; i++) cost += inv.dealer__Cost__c;
        }

        if(fifoLedger.size()==0) {
            qAdd = qsold;
            cost = qsold * cost;
            cost = cost.setScale(2, System.RoundingMode.HALF_UP);   // BLL6a
        }

        //  Add the invoice line
        dealer__Parts_Invoice_Line__c line = new dealer__Parts_Invoice_Line__c();

        // Set Cost and Price
        Decimal price = Decimal.valueOf(String.valueOf(urlParameters.get('SalePrice')));

        Decimal sqty  = Decimal.valueOf(String.valueOf(urlParameters.get('QTY')));
        Decimal ePrice = 0;
        Decimal eCost = 0;
        if(price == null) { price = 0; }
        if(cost == null) { cost = 0; }
        if(sqty == null) { sqty = 0; }
        ePrice = price * sqty;
        ePrice = ePrice.setScale(2, System.RoundingMode.HALF_UP);   // BLL6a
        
        //eCost = cost * sqty; // COmmented out in favor of 

        line.Name =  ro.Name+'-'+String.valueOf(job.dealer__Line_Number__c);
        line.dealer__Parts_Invoice__c = pi.Id;
        line.dealer__Quantity_Sold__c = sqty;
        line.dealer__Part__c = inv.Id;
        line.dealer__Part_Number__c = inv.Name;
        line.dealer__Part_Description__c = inv.dealer__Description__c;
        line.dealer__Pay_Type__c = job.dealer__Labor_Type__c;
        line.dealer__Sale_Date__c = Date.today();
        line.dealer__Price__c = price;
        line.dealer__Cost__c = cost;
        line.dealer__Job_Line__c = job.Id;
        line.dealer__List__c = inv.dealer__List__c;
        line.dealer__Service_Repair_Order__c = ro.Id;
        line.dealer__Sold_Via__c='Repair Order';
        line.dealer__Order_Type__c=String.valueOf(urlParameters.get('partOrderUrgency'));

        // BLL4a
        if (urlParameters.containsKey('partType')) line.Part_type__c = String.valueOf(urlParameters.get('partType'));
        if (line.Part_type__c==null) line.Part_type__c = 'N';
        // BLL4a


        // Conditional Warranty Sale of Parts
        if(job.dealer__Labor_Type__c != 'C' || job.dealer__Labor_Type__c == 'I') {
            line.dealer__Price__c = inv.dealer__Cost__c ;
        }

        // Update Inventory and line defaults
        if(inv.dealer__On_Hand__c==null) {inv.dealer__On_Hand__c=0;}
        if(inv.dealer__On_Order__c==null) {inv.dealer__On_Order__c=0;}
        if(line.dealer__Quantity_Ordered__c==null) {line.dealer__Quantity_Ordered__c=0;}
        if(line.dealer__Quantity_Sold__c==null) {line.dealer__Quantity_Sold__c=0;}

        // Create the subsequent order line
        //Decimal order_qty = Decimal.valueOf(String.valueOf(urlParameters.get('Order')));
        Decimal order_qty = 0;

        // Calculate Order Quantity
        if(sqty > inv.dealer__On_Hand__c) {
            if(inv.dealer__On_Hand__c >= 0) {
                order_qty = sqty - inv.dealer__On_Hand__c;
            } else {
                // We've got a negative on hand. So the order is the actual sold amount.
                order_qty = sqty;
            }

            // Set the order quantity.
            line.dealer__Quantity_Ordered__c=order_qty;    
        } 

        //BLL17d try {
			//System.debug(line);
			System.debug('DML insert->'+JSON.serialize(line));
            insert line;
            // dealer__Parts_Invoice_Line__c lineAfter = [Select Id, Name, dealer__Price__c, dealer__Total_Price__c from dealer__Parts_Invoice_Line__c where Id=:line.Id limit 1];
            // System.debug(lineAfter);
        //BLL17d } catch(DmlException e) {
        //BLL17d     Database.rollback(sp);
        //BLL17d     throw new ROException(e.getMessage());
            //return '{ "error" : "'+e.getMessage()+'" }';
            // BLL7a note: the above line will never run because of the thrown exception
        //BLL17d }

        // Inventory FIFO Relief
        if(updateLedger.size()>0) {
            for(dealer__Parts_Ledger__c plU : updateLedger) {
                plU.dealer__Sold_By__c=UserInfo.getFirstName()+' '+UserInfo.getLastName();
                plU.dealer__Parts_Sale_Line__c=line.Id;
            }
        }

        // Inventory FIFO Association or Entry
        if(qAdd>0) {
            for(Decimal i=1; i<=qAdd; i++) {
                insertLedger.add(new dealer__Parts_Ledger__c(
                    dealer__Entry_Date__c=Date.today(),
                    dealer__Part__c=inv.Id,
                    dealer__Parts_Sale_Line__c=line.Id,
                    dealer__Quantity__c=-1,
                    dealer__Sold_By__c=UserInfo.getFirstName()+' '+UserInfo.getLastName(),
                    dealer__Item_Value__c=inv.dealer__Cost__c,
                    dealer__Transaction_Note__c='Sold negative on '+ro.Name
                )
                                );
            }
        }


        //BLL17d try {
            if(insertLedger.size()>0) {
				System.debug('DML insert->'+JSON.serialize(insertLedger));
                insert insertLedger;
            }
			System.debug('DML update->'+JSON.serialize(updateLedger));
            if(updateLedger.size()>0) update updateLedger;
        //BLL17d } catch(DmlException e) {
            // System.debug(e.getMessage());
        //BLL17d     Database.rollback(sp);
        //BLL17d     throw new ROException(e.getMessage());
            //return '{ "error" : "'+e.getMessage()+'" }';
            //BLL7a note: the above line will never run because of the thrown exception
        //BLL17d }

        System.debug(job.dealer__Labor_Type__c);
        System.debug(ro.dealer__Company__r.Centralized_Purchasing_On_Off__c);
        System.debug(order_qty);

        // Default to quantity order 

        if(ro.dealer__Company__r.Centralized_Purchasing_On_Off__c && ((order_qty!=null && order_qty>0))) { // JVK13 Removed job.dealer__Labor_Type__c == 'W' See note below
            
            /*
             * Jarrett Kuljis | 2016-08-24
             * Per conversation with Ray and Christine Warranty Parts should not be treated any differently than non-warranty labor lines.  Although this was 
             * the procedure at time of writing, the procedure has since changed. 
             */

            // Set order quantity based on sales quantity if line pay type is Warranty
            // Deprecated See Note Above
            /*
            if(job.dealer__Labor_Type__c == 'W') {
                line.dealer__Quantity_Ordered__c=sqty;
            } else {
                line.dealer__Quantity_Ordered__c=order_qty;
            }
            */
            
            line.dealer__Quantity_Ordered__c=order_qty; // JVK13
            
            // Lookup StockOrder Entry Object
            dealer__Stock_Order__c so = new dealer__Stock_Order__c();
            dealer__Stock_Order__c[] so_exists =[Select Id from dealer__Stock_Order__c where dealer__Service_Repair_Order__c =: ro.Id limit 1];
            if(so_exists.size()==0) {
                so = new dealer__Stock_Order__c(
                    Name='CPT#'+ro.dealer__RO_Number__c,
                    dealer__Status__c='Incomplete',
                    dealer__Company__c=ro.dealer__Company__c,
                    dealer__Service_Repair_Order__c=ro.Id,
                    dealer__Date_Ordered__c=Date.Today(),
                    dealer__Order_Type__c='Special Order'
                );
                //BLL17d try {
					System.debug('DML insert->'+JSON.serialize(so));
                    insert so;
                //BLL17d } catch(DmlException e) {
                //BLL17d     Database.rollback(sp);
                //BLL17d     throw new ROException(e.getMessage());
                    //return '{ "error" :"'+e.getMessage()+'"}';
                    // BLL7a note: the above line will never run because of the thrown exception
                //BLL17d }
            } else {
                so = so_exists[0];
            }

            // Get the Queue to add these
            List<QueueSobject> q = [
            	select Id, QueueId 
            	from QueueSobject 
            	where SobjectType = 'dealer__Parts_Order__c' 
            	limit 1
            ];
            if(q.size() == 0) {
                //BLL17d Database.rollback(sp);
                throw new ROException('CPT Queue does not exist.  ');
            }

			// BLL18
            // Set the QTY Ordered based on the Pack Size
			Decimal qtyToOrder = line.dealer__Quantity_Ordered__c;
            if(inv.dealer__Parts_Master__r.dealer__Pack_QTY__c != null && inv.dealer__Parts_Master__r.dealer__Pack_QTY__c > 1) {
                qtyToOrder = qtyToOrder / inv.dealer__Parts_Master__r.dealer__Pack_QTY__c;
                qtyToOrder = qtyToOrder.round(System.RoundingMode.UP);
            }
			// BLL18 end

            // Add the Order Line
            dealer__Parts_Order__c orderLine = new dealer__Parts_Order__c(
                dealer__Order_Date__c=Date.today(),
                dealer__Order__c=so.Id,
                dealer__Parts_Inventory__c=inv.Id,
                dealer__Parts_Master__c=inv.dealer__Parts_Master__c,
                dealer__Quantity_Ordered__c = line.dealer__Quantity_Ordered__c , // DR - use line dealer__Quantity_Ordered__c from line
                dealer__Parts_Line__c=line.Id,
                OwnerId=q[0].QueueId
            );

            //BLL17d try {
				System.debug('DML insert->'+JSON.serialize(orderLine));
                insert orderLine;
            //BLL17d } catch(DmlException e) {
            //BLL17d     Database.rollback(sp);
            //BLL17d     throw new ROException(e.getMessage());
                //return '{ "error" :"'+e.getMessage()+'"}';
                // BLL7a note: the above line will never run because of the thrown exception
            //BLL17d }

            // System.debug(orderLine);

            if(orderLine.Id!=null) {

                line.Parts_Order__c = orderLine.Id;

                //BLL17d try{
					System.debug('DML update->'+JSON.serialize(line));
                    update line;
                //BLL17d } catch(DmlException e) {
                //BLL17d     Database.rollback(sp);
                //BLL17d     throw new ROException(e.getMessage());
                    //return '{ "error" :"'+e.getMessage()+'"}';
                    // BLL7a note: the above line will never run because of the thrown exception
                //BLL17d }

            }

        }

        // Calculate Freight and Charge to Line
        Decimal fRate = 0;
        if(job.Payment_Method__r.Freight_Rate__c!=null) fRate = (job.Payment_Method__r.Freight_Rate__c / 100);
		// BLL17a - get template for misc charge
		LoadMiscChargeOptionsForLocId(ro.dealer__Company__c);
		Misc_Charge_Option__c misc = mcoMap.get('Freight');
		// BLL7a end
        Decimal f_misc_amount = ((line.dealer__Price__c)*fRate); // Half mode rounding for dollar value., remove (line.dealer__Quantity_Sold__c) price already included

		List<ServiceMiscCharges__c> miscLines = new List<ServiceMiscCharges__c>();
		System.debug('Create freight misc chg');
		autoCreateMiscCharge(miscLines, job.Id, line.Id, 'Freight', f_misc_amount);
		
		/**
        ServiceMiscCharges__c miscCharge = new ServiceMiscCharges__c(
            Amount__c=f_misc_amount.setScale(2, System.RoundingMode.HALF_UP),
            Part_Line__c=line.Id,
            Service_Job_Line__c=job.Id,
			General_Ledger_Acct_MW__c = misc!=null ? misc.General_Ledger_Acct_MW__c : null,	// BLL17a
			General_Ledger_Account__c = misc!=null ? misc.General_Ledger_Acct_MW__r.GeneralLedgerAccountFF__c : null,	// BLL17a
            Type__c='Freight'
        );
        **/

        //BLL17d try {
            //insert miscCharge;
			ServiceROHandler.AddingMiscCharges = true;
			System.debug('DML insert->'+JSON.serialize(miscLines));
            insert(miscLines);
        //BLL17d } catch(DmlException e) {
        //BLL17d     Database.rollback(sp);
        //BLL17d     throw new ROException(e.getMessage());
            //return '{ "error" : "'+e.getMessage()+'" }';
            // BLL7a the above line will never run because of the thrown exception
        //BLL17d }

        inv.dealer__On_Hand__c = inv.dealer__On_Hand__c-line.dealer__Quantity_Sold__c;
        inv.dealer__On_Order__c= inv.dealer__On_Order__c+line.dealer__Quantity_Ordered__c;

        //BLL17d try {
			System.debug('DML update->'+JSON.serialize(inv));
            update inv;
        //BLL17d } Catch(DmlException e) {
        //BLL17d     Database.rollback(sp);
        //BLL17d     throw new ROException(e.getMessage());
            //return '{ "error" : "'+e.getMessage()+'" }';
            // BLL7a note: the above line will never run because of the thrown exception
        //BLL17d }

            /*
            dealer__Service_Job__c jobLog = [Select Id, Name, dealer__Parts_Total__c, dealer__Parts_Cost__c from dealer__service_job__c where Id =: job.Id limit 1];
            System.debug(jobLog);
            */
        if(!test.isRunningTest()){
            lineTotalParts(job.Id);
            lineTotalMisc(job.Id);
        }

                    /*
            dealer__Service_Job__c jobLogAfter = [Select Id, Name, dealer__Parts_Total__c, dealer__Parts_Cost__c from dealer__service_job__c where Id =: job.Id limit 1];
            System.debug(jobLogAfter);
            Database.rollback(sp);
            throw new ROException('Stop');
            */

        return line.Id;
    }


	// updatePartLine
    public String updatePartLine() {
		System.debug('updatePartLine');

        SavePoint sp = Database.setSavepoint();

        if(Decimal.valueOf(String.valueOf(urlParameters.get('QTY'))) < 1) {
            error_string = '{ "error" : "Part QTY may not be less than 1" }';
            return error_string;	// BLL17c was null
        }

        // BLL4a added Part_type__c
        dealer__Parts_Invoice_Line__c line = [
        	select dealer__Parts_Invoice__c, dealer__Bin__c, dealer__Core__c, dealer__Cost__c, dealer__Counterman_No__c,
				dealer__Counterman__c, dealer__Currently_Available__c,dealer__Part__r.dealer__Physical_OnHand__c, dealer__Drop_Ship__c, dealer__Extended_Price__c,
				dealer__Gross_Margin__c, dealer__Job_Line__c, dealer__List__c, dealer__MFG__c, dealer__Net_Price__c,
				dealer__Net__c, dealer__Order_Type__c, dealer__Part_Description__c, dealer__Part_Number__c,
				dealer__Part__c, dealer__Pay_Type__c, dealer__Price_Level_Strategy__c, dealer__Price_Level__c,
				dealer__Price__c, dealer__Quantity_Ordered__c, dealer__Quantity_Sold__c, dealer__Sale_Date__c,
				dealer__Service_Job_Line_Number__c, dealer__Service_Line_Payment_Method__c,
				dealer__Service_Repair_Order__c, dealer__Sold_Via__c, dealer__Source__c, dealer__Stocking_Group__c,
				dealer__Total_Price__c, dealer__Total_Tax__c, dealer__Transaction_Code__c, Part_Master_Record__c,
				Currently_On_Order__c, Negative_QTY__c, PO_ETA__c, PO_Tracking__c, PO_Name__c, Name, Id, Part_type__c,
				dealer__Service_Repair_Order__r.Name,
				dealer__Purchase_Order_Line__c, dealer__Purchase_Order_Line__r.dealer__Part_Quantity__c, dealer__Purchase_Order_Line__r.dealer__Amount__c
			from dealer__Parts_Invoice_Line__c 
			where Id=:String.valueOf(urlParameters.get('Id')) 
			limit 1
		];

        // JVK 8/8/2017 
        // When discussing updating Quantity with Jeremy he identified that a part can be added to an RO of QTY 2, PO can be issued for QTY 2 and then RO Line can be reduced to QTY 1, re-issued at QTY 2.
        //  At that time the Dealer Net value is used both in the ledger and on the Parts Invoice Line.
        //  Solution: At the time of update if we have a PO Line associated and the QTY is greater than or equal to the updated QTY Sold derive value (Cost) from the Purchase Order Line
        Decimal poLineQuantity = (line.dealer__Purchase_Order_Line__c!=null) ? line.dealer__Purchase_Order_Line__r.dealer__Part_Quantity__c : 0;
        Decimal poLineValue = (line.dealer__Purchase_Order_Line__c != null) ? line.dealer__Purchase_Order_Line__r.dealer__Amount__c : 0;
        Decimal poLineUnitValue = (line.dealer__Purchase_Order_Line__c != null) ? (line.dealer__Purchase_Order_Line__r.dealer__Amount__c / line.dealer__Purchase_Order_Line__r.dealer__Part_Quantity__c) : 0;


        // Get the associated Inventory Record
        dealer__Parts_Inventory__c inv = [
        	select Id, dealer__On_Hand__c, dealer__On_Order__c, dealer__Cost__c
			from dealer__Parts_Inventory__c
			where Id=:line.dealer__Part__c 
			limit 1
		];

        // Reset Totals
        if(line.dealer__Quantity_Sold__c==null) {line.dealer__Quantity_Sold__c=0;}
        if(line.dealer__Quantity_Ordered__c==null) {line.dealer__Quantity_Ordered__c=0;}
        if(inv.dealer__On_Hand__c==null) {inv.dealer__On_Hand__c=0;}
        if(inv.dealer__On_Order__c==null) {inv.dealer__On_Order__c=0;}
        if(inv.dealer__On_Order__c<0) {inv.dealer__On_Order__c=0;} // catch any negatives on order

        // Adjust the FIFO table up or down based on QTY requested
        Decimal newQTY = Decimal.valueOf(String.valueOf(urlParameters.get('QTY')));
        Decimal difference = newQTY - line.dealer__Quantity_Sold__c;

        // Handle net increase in sales
        List<dealer__Parts_Ledger__c> ledgerList = new List<dealer__Parts_Ledger__c>();
        List<dealer__Parts_Ledger__c> ledgerNew = new List<dealer__Parts_Ledger__c>();
        List<dealer__Parts_Ledger__c> ledgerReduce = new List<dealer__Parts_Ledger__c>();

        Decimal costAdd = 0;

        // find matching part orders 
        dealer__Parts_Order__c[] matching_orders = [
        	select Id, dealer__Quantity_Ordered__c 
        	from dealer__Parts_Order__c
			where dealer__Parts_Inventory__c =:inv.Id
			  and dealer__Order__r.dealer__Service_Repair_Order__c =:line.dealer__Service_Repair_Order__c
			  and dealer__Purchase_Order__c=null
			limit 1
		];

        // Setup some utility vars to use later
        Decimal inverseDifference = difference * -1;
        Decimal totalOrdered = 0;

        Boolean destroyOrder = false;

        // If there are mathing part orders for this RO
        Decimal originalOrder = 0;
        if(matching_orders.size()==1 && matching_orders[0].dealer__Quantity_Ordered__c != null) {
            originalOrder = matching_orders[0].dealer__Quantity_Ordered__c;
        } else {
            originalOrder = line.dealer__Quantity_Ordered__c;
        }

        // reset the on Order amount of the Inventory record removing the previous order amount. - There is some error catching here, but if the on order amount is set to zero it means there was an error in the system elsewhere.
        inv.dealer__On_Order__c = ( (inv.dealer__On_Order__c - originalOrder)>0 ) ? inv.dealer__On_Order__c - originalOrder : 0;

        System.debug('Difference -------> ' + difference);
        
        // inventory QTY ordered handling...
        // Now that the order amount is calculated increase the on order amount
        if(difference!=0){
            if(difference>0) { inv.dealer__On_Hand__c -= difference; }
            if(difference<0) { inv.dealer__On_Hand__c += Math.abs(difference); }
            inv.dealer__On_Order__c = inv.dealer__On_Order__c + totalOrdered;
        }

        if(difference>0) {
            // New Sales - new FIFO Transaction
            List<dealer__Parts_Ledger__c> fifoLedger = [
            	select Id, dealer__Quantity__c, dealer__Item_Value__c, dealer__Transaction_Note__c
				from dealer__Parts_Ledger__c
				where dealer__Parts_Sale_Line__c = NULL
				  and dealer__Part__c =:inv.Id
				  and dealer__Quantity__c > 0
				order by dealer__Entry_Date__c ASC
				limit :Integer.valueOf(difference)
			];

            for(dealer__Parts_Ledger__c pl : fifoLedger) {
                
                if(pl.dealer__Transaction_Note__c==null) pl.dealer__Transaction_Note__c='';

				String tnote = (pl.dealer__Transaction_Note__c!=null && pl.dealer__Transaction_Note__c.right(1)!=';') ? pl.dealer__Transaction_Note__c +';Sold on '+line.dealer__Service_Repair_Order__r.Name : pl.dealer__Transaction_Note__c +'Sold on '+line.dealer__Service_Repair_Order__r.Name;
                
                costAdd+=pl.dealer__Item_Value__c;
                ledgerList.add(new dealer__Parts_Ledger__c(
                    Id=pl.Id,
                    dealer__Quantity__c=0,
                    dealer__Sold_By__c=UserInfo.getFirstName()+' '+UserInfo.getLastName(),
                    dealer__Parts_Sale_Line__c=line.Id,
                    dealer__Transaction_Note__c=tnote
                )
               );
            }

            if(difference>fifoLedger.size()) {
                for(Integer i=1; i<=(difference-fifoLedger.size()); i++) {
                    costAdd+=inv.dealer__Cost__c;
                    ledgerNew.add(new dealer__Parts_Ledger__c(
                        dealer__Quantity__c=-1,
                        dealer__Sold_By__c=UserInfo.getFirstName()+' '+UserInfo.getLastName(),
                        dealer__Parts_Sale_Line__c=line.Id,
                        dealer__Part__c=inv.Id,
                        dealer__Transaction_Note__c='Sold negative on '+line.dealer__Service_Repair_Order__r.Name, //JVK16
                        dealer__Item_Value__c=inv.dealer__Cost__c, //This is pulling dealer net.  If we have a PO Line and QTY does not exceed the PO Line QTY, derive value from there... (poLineQuantity!=0 && line.dealer__Quantity_Sold__c !=0 && poLineQuantity>=line.dealer__Quantity_Sold__c) ? poLineUnitValue : inv.dealer__Cost__c
                        dealer__Entry_Date__c=Date.today()
                    )
                                 );
                }
            }

            // We have matching orders and we increase the order
            if(matching_orders.size()==1 && matching_orders[0].dealer__Quantity_Ordered__c != null) {
                totalOrdered = matching_orders[0].dealer__Quantity_Ordered__c + difference;
            } else {
                // No Matching orders and we need to order
                if(difference > inv.dealer__On_Hand__c) {
                    totalOrdered = (inv.dealer__On_Hand__c>0)? difference - inv.dealer__On_Hand__c : difference;
                }
            }

        } else if(difference<0) {
            // Reduction - Update existing reduction
			Integer reduction = (Integer)Math.abs(difference);
            List<dealer__Parts_Ledger__c> ledgerTransactions = [
            	select Id, dealer__Entry_date__c, dealer__Purchase_Order__c, dealer__Part__c, 
					dealer__Item_Value__c, dealer__Quantity__c, dealer__Transaction_Note__c
				from dealer__Parts_Ledger__c
				where dealer__Parts_Sale_Line__c =:line.Id
				order by dealer__Entry_date__c DESC
				limit :reduction	 // No Limit	(JVK15 was  Order by CreatedDate DESC)
			];
            for(Integer i=0; i<reduction; i++) {
                
				costAdd-=ledgerTransactions[i].dealer__Item_Value__c;
				ledgerTransactions[i].dealer__Parts_Sale_Line__c = null;
                
				if(ledgerTransactions[i].dealer__Quantity__c < 0) ledgerTransactions[i].dealer__Quantity__c = 0;
				else ledgerTransactions[i].dealer__Quantity__c = 1;
                
                if(ledgerTransactions[i].dealer__Transaction_Note__c==null) ledgerTransactions[i].dealer__Transaction_Note__c='';

                String tnote = (ledgerTransactions[i].dealer__Transaction_Note__c!=null && ledgerTransactions[i].dealer__Transaction_Note__c.right(1)!=';') ? ledgerTransactions[i].dealer__Transaction_Note__c +';Restored from '+line.dealer__Service_Repair_Order__r.Name : ledgerTransactions[i].dealer__Transaction_Note__c +'Restored from '+line.dealer__Service_Repair_Order__r.Name;
                ledgerTransactions[i].dealer__Transaction_Note__c = tnote;
                ledgerReduce.add(ledgerTransactions[i]);
            }           
            // get calculated total ordered amount
            if(matching_orders.size()==1 && matching_orders[0].dealer__Quantity_Ordered__c != null) {
                totalOrdered = matching_orders[0].dealer__Quantity_Ordered__c - reduction;
            }
            // Delete the order since we decreased under threshhold?
            if(totalOrdered<=0) {
                // remove order
                destroyOrder = true;
                totalOrdered = 0; // catch negative numbers
            }
        } 

        if(matching_orders.size()==1 && matching_orders[0].dealer__Quantity_Ordered__c != null) {
            System.debug('matching_orders[0] -------> ' + matching_orders[0]);
        }
        System.debug('totalOrdered -------> ' + totalOrdered);
        System.debug('destroyOrder -------> ' + destroyOrder);

        try {
			System.debug('DML update->'+JSON.serialize(inv));
            update inv; // handled by the managed trigger // testing

			System.debug('DML update->'+JSON.serialize(ledgerList));
            if(ledgerList.size()>0) update ledgerList;

            if(ledgerNew.size()>0) {
				System.debug('DML insert->'+JSON.serialize(ledgerNew));
                insert ledgerNew;
            }

			System.debug('DML update->'+JSON.serialize(ledgerReduce));
            if(ledgerReduce.size()>0) update ledgerReduce;	// JVK15 was delete

        } Catch(DmlException e) {
            System.debug(e.getMessage());
            Database.rollback(sp);
            //BLL7d return '{ "error" : "'+e.getMessage()+'" }';
            // throw new ROException(e.getMessage()); //JVK12
            String msg = Utility.friendlyErrorMessage(e);   // BLL7a
            return '{ "error":"' + msg + '"}';  // BLL7a
        }

        System.debug('difference ->'+difference);
        System.debug('inv.dealer__On_Hand__c ->'+inv.dealer__On_Hand__c);
        System.debug('matching_orders.size() ->'+matching_orders.size());
        // QTY Changed AND WE need to Order AND there are not matching orders. We increased enough and need to create an order.
        if(difference>0 && difference > inv.dealer__On_Hand__c && matching_orders.size()==0) {
            // Get RO Data from RID
             System.debug('Inside diff ->');
            dealer__Service_Job__c job = [Select Id, Name,dealer__Service_Repair_Order__c, dealer__Line_Number__c, dealer__Labor_Type__c, Payment_Method__r.Name, Payment_Method__r.Freight_Rate__c
                                          from dealer__Service_Job__c
                                              where Id=:line.dealer__Job_Line__c
                                          limit 1];
            System.debug('job ->'+job);
            dealer__Service_Repair_Order__c ro = [Select Id, Name, dealer__Parts_Invoice__c, dealer__RO_Number__c,
                                                  dealer__Company__c, dealer__Company__r.Centralized_Purchasing_On_Off__c
                                                  from dealer__Service_Repair_Order__c
                                                  Where Id=:job.dealer__Service_Repair_Order__c
                                                  limit 1];


            if(ro.dealer__Company__r.Centralized_Purchasing_On_Off__c && totalOrdered!=null && totalOrdered > 0 ) {

                /*
                 * Jarrett Kuljis | 2016-08-24
                 * Per conversation with Ray and Christine Warranty Parts should not be treated any differently than non-warranty labor lines.
                 */

                line.dealer__Quantity_Ordered__c=totalOrdered; // JVK13

                // Lookup StockOrder Entry Object
                dealer__Stock_Order__c so = new dealer__Stock_Order__c();
                dealer__Stock_Order__c[] so_exists =[Select Id from dealer__Stock_Order__c where dealer__Service_Repair_Order__c =: ro.Id limit 1];
                if(so_exists.size()==0) {
                    so = new dealer__Stock_Order__c(
                        Name='CPT#'+ro.dealer__RO_Number__c,
                        dealer__Status__c='Incomplete',
                        dealer__Company__c=ro.dealer__Company__c,
                        dealer__Service_Repair_Order__c=ro.Id,
                        dealer__Date_Ordered__c=Date.Today(),
                        dealer__Order_Type__c='Special Order'
                    );
                    try {
						System.debug('DML insert->'+JSON.serialize(so));
                        insert so;
                    } catch(DmlException e) {
                        Database.rollback(sp);
                        throw new ROException(e.getMessage());
                        //return '{ "error" :"'+e.getMessage()+'"}';
                        // BLL7a the above line will never run because of the thrown exception
                    }
                } else {
                    so = so_exists[0];
                }

                // Get the Queue to add these
                List<QueueSobject> q = [SELECT Id, QueueId FROM QueueSobject where SobjectType = 'dealer__Parts_Order__c' limit 1];
                if(q.size() == 0) {
                    Database.rollback(sp);
                    throw new ROException('CPT Queue does not exist.  ');
                }

                // Add the Order Line
                dealer__Parts_Order__c orderLine = new dealer__Parts_Order__c(
                    dealer__Order_Date__c=Date.today(),
                    dealer__Order__c=so.Id,
                    dealer__Parts_Inventory__c=inv.Id,
                    dealer__Parts_Master__c=inv.dealer__Parts_Master__c,
                    dealer__Quantity_Ordered__c=line.dealer__Quantity_Ordered__c, // - DR - Use line total ordered 
                    dealer__Parts_Line__c=line.Id,
                    OwnerId=q[0].QueueId
                );

                try {
					System.debug('DML insert->'+JSON.serialize(orderLine));
                    insert orderLine;

                } catch(DmlException e) {
                    Database.rollback(sp);
                    throw new ROException(e.getMessage());
                    //return '{ "error" :"'+e.getMessage()+'"}';
                    // BLL7a note: the above line will never run because of the thrown exception
                }

                // System.debug(orderLine);

                if(orderLine.Id!=null) {
                    line.Parts_Order__c = orderLine.Id;
                }

            }
        }

        // Set new Line Level Values
        Decimal price = Decimal.valueOf(String.valueOf(urlParameters.get('SalePrice')));
        Decimal cost  = line.dealer__Cost__c + costAdd;
        Decimal sqty  = Decimal.valueOf(String.valueOf(urlParameters.get('QTY')));
        Decimal ePrice = 0;
        Decimal eCost = 0;
        if(price == null) { price = 0; }
        if(cost == null) { cost = 0; }
        if(sqty == null) { sqty = 0; }
        ePrice = price * sqty;
        eCost = cost * sqty;

        ePrice = ePrice.setScale(2, System.RoundingMode.HALF_UP);   // BLL6a
        eCost = eCost.setScale(2, System.RoundingMode.HALF_UP); // BLL6a

        line.dealer__Quantity_Sold__c       =   Decimal.valueOf(String.valueOf(urlParameters.get('QTY')));

        // use calculated order amount.
        if(difference != 0) {
            line.dealer__Quantity_Ordered__c    =   totalOrdered; // DR2 - Need calculated amount
        }
        //line.dealer__Quantity_Ordered__c  =   Decimal.valueOf(String.valueOf(urlParameters.get('Order'))); // DR2
        
        line.dealer__Price__c               =   price;
        line.dealer__Cost__c                =   cost;
        line.dealer__Order_Type__c          =   String.valueOf(urlParameters.get('partOrderUrgency'));
        // BLL4a
        if (urlParameters.containsKey('partType')) line.Part_type__c = String.valueOf(urlParameters.get('partType'));
        if (line.Part_type__c==null) line.Part_type__c = 'N';
        // BLL4a

        // Catch Zero Sale
        if(line.dealer__Quantity_Sold__c == 0) {
          //  line.dealer__Price__c   =   0;
          //  line.dealer__Cost__c    =   0;
        }

        // Update RO line if changed.
        String newLine = String.valueOf(urlParameters.get('ServiceJobId'));
        String oldLine = line.dealer__Job_Line__c;
        if( newLine != null  && newLine != oldLine) line.dealer__Job_Line__c = newLine;

        try {
			System.debug('DML update->'+JSON.serialize(line));
            update line;

            // Debug - Clear Out
            //System.debug('Job Line Update Part Line : ');
            //System.debug(line);

        } catch(DmlException e) {

            System.debug(e.getMessage());
            Database.rollback(sp);
            // throw new ROException(e.getMessage()); //JVK12
            //BLL7d return '{ "error" : "'+e.getMessage()+'" }';
            String msg = Utility.friendlyErrorMessage(e);   // BLL7a
            return '{ "error":"' + msg + '"}';  // BLL7a
        }

        // Reconcile previous line orders and Update the Order Line QTY - dealer__Parts_Order__c
        if(matching_orders.size()==1) {
            if(destroyOrder) {
                System.debug('destroyOrder so we destroyOrder -------> ' + destroyOrder);

                try {
					System.debug('DML delete->'+JSON.serialize(matching_orders));
                    delete matching_orders;
                } Catch(DmlException e) {
                    System.debug(e.getMessage());
                    Database.rollback(sp);
                    // throw new ROException(e.getMessage()); //JVK12
                    //BLL7d return '{ "error" : "'+e.getMessage()+'" }';
                    String msg = Utility.friendlyErrorMessage(e);   // BLL7a
                    return '{ "error":"' + msg + '"}';  // BLL7a
                }
                System.debug('Should be destroyed: matching_orders -------> ' + matching_orders);

            } else {
                System.debug(' matching_orders updated for some reason -------> ' + matching_orders);

                matching_orders[0].dealer__Quantity_Ordered__c=line.dealer__Quantity_Ordered__c;                
                try {
					System.debug('DML delete->'+JSON.serialize(matching_orders));
                    update matching_orders;
                } Catch(DmlException e) {
                    System.debug(e.getMessage());
                    Database.rollback(sp);
                    // throw new ROException(e.getMessage()); //JVK12
                    //BLL7d return '{ "error" : "'+e.getMessage()+'" }';
                    //String msg = Utility.friendlyErrorMessage(e);   // BLL7a
                    return '{ "error":"' + Utility.friendlyErrorMessage(e) + '"}';  // BLL7a
                }
            }
        }

        // Update Freight
        dealer__Service_Job__c job = [Select Id, Payment_Method__r.Freight_Rate__c from dealer__Service_Job__c where Id=:line.dealer__Job_Line__c limit 1];
        ServiceMiscCharges__c[] mCharges = [Select Id from ServiceMiscCharges__c where Part_Line__c=:line.Id limit 1];
        Decimal fRate = 0;
        if(job.Payment_Method__r.Freight_Rate__c!=null) { fRate = (job.Payment_Method__r.Freight_Rate__c / 100); }
        if(mCharges.size()==1) {
            mCharges[0].Amount__c = (line.dealer__Price__c) * fRate; // Remove line.dealer__Quantity_Sold__c, already in dealer__Price__c
            mCharges[0].Amount__c = mCharges[0].Amount__c.setScale(2, System.RoundingMode.HALF_UP);
            // Update misc freight if line number is changed
            if( newLine != null && newLine != oldLine) mCharges[0].Service_Job_Line__c = newLine;
        }

        try {
			System.debug('DML update->'+JSON.serialize(mCharges));
            update mCharges;
        } catch(DmlException e) {
            System.debug(e.getMessage());
            Database.rollback(sp);
            // throw new ROException(e.getMessage());  // JVK12
            //BLL7d return '{ "error" : "'+e.getMessage()+'" }';
            //String msg = Utility.friendlyErrorMessage(e);   // BLL7a
            return '{ "error":"' + Utility.friendlyErrorMessage(e) + '"}';  // BLL7a
        }

        // Re-total lines
        lineTotalMisc(job.Id);
        lineTotalParts(line.dealer__Job_Line__c);
        // Total parts and misc for old line
        if( newLine != null && newLine != oldLine) {
            lineTotalParts(oldLine);
            lineTotalMisc(oldLine);
        }


        return JSON.serializePretty(new PartRow(line));
    }

    public String getPartLine() {

        // Error Trapping passed back in the form of JSON
        if(error_string!=null) return error_string;

        if(partLine==null || partLine =='') return '{ "error" : "Part Line not specified, please contact support" }';

        // BLL4a add Part_type__c
        dealer__Parts_Invoice_Line__c line = [
        	select dealer__Parts_Invoice__c, dealer__Bin__c, dealer__Core__c, dealer__Cost__c, dealer__Counterman_No__c, dealer__Counterman__c, dealer__Currently_Available__c,dealer__Part__r.dealer__Physical_OnHand__c, dealer__Drop_Ship__c, dealer__Extended_Price__c, dealer__Gross_Margin__c, dealer__Job_Line__c, dealer__List__c, dealer__MFG__c, dealer__Net_Price__c, dealer__Net__c, dealer__Order_Type__c, dealer__Part_Description__c, dealer__Part_Number__c, dealer__Part__c, dealer__Pay_Type__c, dealer__Price_Level_Strategy__c, dealer__Price_Level__c, dealer__Price__c, dealer__Quantity_Ordered__c, dealer__Quantity_Sold__c, dealer__Sale_Date__c, dealer__Service_Job_Line_Number__c, dealer__Service_Line_Payment_Method__c, dealer__Service_Repair_Order__c, dealer__Sold_Via__c, dealer__Source__c, dealer__Stocking_Group__c, dealer__Total_Price__c, dealer__Total_Tax__c, dealer__Transaction_Code__c, Part_Master_Record__c, Currently_On_Order__c, Negative_QTY__c, Name, Id, Parts_Order__c, Parts_Order__r.Name, PO_ETA__c, PO_Name__c, PO_Tracking__c, Part_type__c 
        	from dealer__Parts_Invoice_Line__c 
        	where Id=:partLine 
        	limit 1
        ];
        return JSON.serializePretty(new PartRow(line));
    }

    public String updateLine() {
		System.debug('updateLine');	

        SavePoint sp = Database.setSavepoint();

        System.debug('all params ' + urlParameters);
        // If Payment Type is not Set throw error
        if(urlParameters.get('Payment_Method__c') == null || urlParameters.get('Payment_Method__c') == '') {
            return '{ "error" : "Line requires the Labor Type be set" }';
        }

        // Job Line Instance
        dealer__Service_Job__c j = new dealer__Service_Job__c();
        if(urlParameters.get('Id')!=null && urlParameters.get('Id')!='') {
            j = [
				Select Id, dealer__Service_Repair_Order__c, Payment_Method__c, dealer__Labor_Charges__c
				from dealer__Service_Job__c where Id=:urlParameters.get('Id') 
				limit 1
			];
            jobLineId = String.valueOf(urlParameters.get('Id'));
        }
		// BLL22
		roId = urlParameters.containsKey('rid') ? String.valueOf(urlParameters.get('rid')) : j.dealer__Service_Repair_Order__c;
		dealer__Service_Repair_Order__c ro = [select Id, dealer__Company__c from dealer__Service_Repair_Order__c where Id=:roId limit 1];
		// BLL22 end

        // Deconstruct payload to update the respective row
        j.dealer__CustomerConcern__c = String.valueOf(urlParameters.get('dealer__CustomerConcern__c'));
        if(String.valueOf(urlParameters.get('dealer__CauseExtended__c'))!=null) {
            j.dealer__Cause__c   = String.valueOf(urlParameters.get('dealer__CauseExtended__c')).abbreviate(250); // DR1
        }
        j.dealer__CauseExtended__c   = String.valueOf(urlParameters.get('dealer__CauseExtended__c'));
        j.dealer__Correction__c = String.valueOf(urlParameters.get('dealer__Correction__c'));
        j.dealer__Standard_Operation_Code__c = String.valueOf(urlParameters.get('dealer__Standard_Operation_Code__c'));
        j.dealer__Stat__c = String.valueOf(urlParameters.get('dealer__Stat__c'));

        // Store Old payment methid to campare later
        String ogPaymentMethod = j.Payment_Method__c;
        j.Payment_Method__c = String.valueOf(urlParameters.get('Payment_Method__c'));

        // Get defauls from the payment method
		// BLL22 add Shop_Supplies_Rate__c & Name
        ServicePaymentType__c pm = [Select Id, Name, Default_Labor_Rate__c, Payment_Type__c, Shop_Supplies_Rate__c
                                    from ServicePaymentType__c
                                    where Id=:j.Payment_Method__c];
        j.dealer__Labor_Type__c = pm.Payment_Type__c;
        
        system.debug(j.dealer__Labor_Type__c +' >> '+String.valueOf(urlParameters.get('Payment_Method__r[Name]')));
		System.debug(pm);	// BLL22

        /*@@ dealer__StandardOpCode__c opcode = [Select Id, Name from dealer__StandardOpCode__c
                                            where Id=:j.dealer__Standard_Operation_Code__c
                                            limit 1];*/
        j.dealer__Op_Code__c    =   urlParameters.get('dealer__Standard_Operation_Code__r.Name');
        
		// BLL22
		dealer__StandardOpCode__c opcode = null;
		if (j.Id==null) { 
			List<dealer__StandardOpCode__c> opcodes = [select Id, dealer__Book_Time__c from dealer__StandardOpCode__c where Id=:j.dealer__Standard_Operation_Code__c];
			if (opcodes.size()>0) opcode = opcodes[0];
		}
		if (!String.isBlank(urlParameters.get('dealer__Book_Time__c'))) {
			j.dealer__Book_Time__c = Decimal.valueOf(urlParameters.get('dealer__Book_Time__c'));
			System.debug('Got book time from url parameter');
		}
		System.debug(j.dealer__Book_Time__c);
		if (location==null && roId!=null) {
			location = [select Id, Name, dealer__State__c, LaborBookEqualsActualTime__c from dealer__Dealer_Location__c where Id=:ro.dealer__Company__c limit 1];
		}
		System.debug(location);
		// BLL22 end

        // Handle the Creates
        if(urlParameters.get('action')=='create_line') {
            roId = String.valueOf(urlParameters.get('rid'));
            j.dealer__Service_Repair_Order__c = roId;

            // Get Job Line as Incrimental Number
            dealer__Service_Job__c[] job_line_counter = [Select dealer__Line_Number__c from dealer__Service_Job__c where dealer__Service_Repair_Order__c =:roId order by dealer__Line_Number__c desc limit 1];
            if(job_line_counter.size()==0) {
                j.dealer__Line_Number__c = 1;
            } else {
                if(job_line_counter[0].dealer__Line_Number__c==null) { job_line_counter[0].dealer__Line_Number__c = 0; }
                j.dealer__Line_Number__c = job_line_counter[0].dealer__Line_Number__c + 1;
            }

            /* - Remove due to bug, if line deleted you end up with multiple line#s
            Integer count = database.countQuery('Select count() from dealer__Service_Job__c where dealer__Service_Repair_Order__c = \''+roId+'\'');
            count=count+1;
            j.dealer__Line_Number__c = count;
            */

            dealer__Service_Repair_Order__c rodata = [Select Name from dealer__Service_Repair_Order__c where Id=:roId limit 1];
            j.Name = rodata.Name +'-'+ j.dealer__Line_Number__c;
			// BLL22
			if (location==null || location.LaborBookEqualsActualTime__c==false ) {
				if (opcode!=null && opcode.dealer__Book_Time__c!=null && j.dealer__Book_Time__c==0) j.dealer__Book_Time__c = opcode.dealer__Book_Time__c;
			}
			System.debug(j.dealer__Book_Time__c);
			// BLL22 end
        } else {
            roId = Id.valueOf(String.valueOf(urlParameters.get('dealer__Repair_Order_Id__c')));
        }

		// BLL22
		Decimal laborrate = calculateLaborRatePay(roId, j.Payment_Method__c);
		System.debug(laborrate);
		if (!location.LaborBookEqualsActualTime__c) {
			j.dealer__Labor_Charges__c=(j.dealer__Book_Time__c==null ? 0.00 : j.dealer__Book_Time__c) * laborrate;
		}
		System.debug(j.dealer__Book_Time__c);
		System.debug(j.dealer__Labor_Charges__c);
		// BLL22 end

        try {
            if(j.Id!=null) {
                //update j;
            } else {
				System.debug('DML insert->'+JSON.serialize(j));
                insert j;
            }
        } catch(DmlException e) {
            Database.rollback(sp);
            //BLL7d return '{ "error" : "'+e.getMessage()+'" }';
            //String msg = Utility.friendlyErrorMessage(e);   // BLL7a
            return '{ "error":"' + Utility.friendlyErrorMessage(e) + '"}';  // BLL7a
        }

        jobLineId = j.Id;

        // Check if Payment Method was set from previous DB call on existing Job Line
        System.debug('og ' + ogPaymentMethod + ', Labor - '+j.dealer__Labor_Type__c);
        System.debug('new ' + String.valueOf(urlParameters.get('Payment_Method__c')));
        boolean isRunRecalculation = false;
        if ( j.Id!=null && ogPaymentMethod != null ) {
            // Did payment Method change?
            if ( ogPaymentMethod != String.valueOf(urlParameters.get('Payment_Method__c')) ) {
                // Payment method changed, we need to re-calculate Labor and misc charges
                // Update lines
                //RT6 - reworking recalculation to reduce soql queries
                isRunRecalculation = true;
                try{	// JVK15a
                laborRateRecalculation(j.Id, j);
				System.debug(j);
                //lineTotalMisc(j.Id); // @@ Same calculations are there in laborRateRecalculation method
                // JVK15a 
                }catch(DmlException e) {
                    Database.rollback(sp);
                    //BLL7d return '{ "error" : "'+e.getMessage()+'" }';
                    //String msg = Utility.friendlyErrorMessage(e);   // BLL7a
                    return '{ "error":"' + Utility.friendlyErrorMessage(e) + '"}';  // BLL7a
                }
                // JVK15a end
            }
        }

		// Update existing line
        if(isRunRecalculation == false && j.id != null)
        {
            try{	// JVK15a?
				System.debug('DML update->'+JSON.serialize(j));
                update j;
            // JVK15a?
            }
            catch(DmlException e) {
                Database.rollback(sp);
                //BLL7d return '{ "error" : "'+e.getMessage()+'" }';
                //String msg = Utility.friendlyErrorMessage(e);   // BLL7a
                return '{ "error":"' + Utility.friendlyErrorMessage(e) + '"}';  // BLL7a
            }
            // JVK15a end ?
        }

		// BLL22 default shop supplies when using book time
		if (location==null || location.LaborBookEqualsActualTime__c==false ) {
			// re-read job line with new labor rate
            //j = [
			//	Select Id, dealer__Service_Repair_Order__c, dealer__Book_Time__c, Payment_Method__c, dealer__Labor_Charges__c
			//	from dealer__Service_Job__c where Id=:j.Id
			//	limit 1
			//];

			// Current shop supplies total except for this job line
			Decimal totalShopSupplies = 0.00;
			Id shopsuppliesid = null;
			List<ServiceMiscCharges__c> smcDelete = new List<ServiceMiscCharges__c>();

			for(ServiceMiscCharges__c misc : [
				select Id, Name, Service_Job_Line__c, Amount__c, Other_Creator_Id__c, Technician_Job_Time_Creator__c
				from ServiceMiscCharges__c
				where Type__c='Shop Supplies' 
				  and Service_Job_Line__r.dealer__Service_Repair_Order__c=:roId
			]) {
				// need total *other* shop supplies so we won't auto-generate charges over $25
				if (misc.Service_Job_Line__c!=j.Id) totalShopSupplies += misc.Amount__c;
				// replace or delete auto-generated shop supplies for this job line
				if (misc.Service_Job_Line__c==j.Id && (misc.Other_Creator_Id__c==j.Id || misc.Technician_Job_Time_Creator__c!=null)) {
					if (shopsuppliesid==null) shopsuppliesid = misc.Id;
					else smcDelete.add(misc);	// redundant shop supplies
				} 
			}
			System.debug(totalShopSupplies);
			System.debug(shopsuppliesid);
			System.debug(smcDelete);
			System.debug(j.dealer__Book_Time__c);
			System.debug('dealer__Labor_Charges__c=' + String.valueOf(j.dealer__Labor_Charges__c));
			System.debug(pm.Shop_Supplies_Rate__c);
			if (pm.Shop_Supplies_Rate__c==null) pm.Shop_Supplies_Rate__c = 0.00;
            // Labor Charges times Rate
            Decimal shop_supplies = (j.dealer__Labor_Charges__c==null ? 0.00: j.dealer__Labor_Charges__c) 
				* (pm.Shop_Supplies_Rate__c / 100);
            shop_supplies = shop_supplies.setScale(2, System.RoundingMode.HALF_UP); // BLL6a
			System.debug('shop supplies charge=' + String.valueOf(shop_supplies));

            // Check to see if we are in CA, also enforce $25 limit on shop supplies
            //TODO: Select MISC Item From Database and get account if type equals HAZMAT
            if(location!=null && (location.dealer__State__c != 'CA' || ProductionWork.contains(pm.Name))) {	// BLL13a allow on IE* and GR*V for Calif. {
				LoadMiscChargeOptionsForLocId(location.Id);
				List<ServiceMiscCharges__c> miscLines = new List<ServiceMiscCharges__c>();
                if(totalShopSupplies + shop_supplies > 25.00) {
                    shop_supplies = 25.00 - totalShopSupplies;
					if (shop_supplies<0) shop_supplies = 0.00;
					System.debug('adjusted shop supplies=' + String.valueOf(shop_supplies));
                }
				System.debug('Create shop supplies misc chg');
				System.debug(shop_supplies);
				if (mcoMap.get('Shop Supplies')!=null) {
        			autoCreateMiscCharge(miscLines, j.Id, j.Id, 'Shop Supplies', shop_supplies.setScale(2, System.RoundingMode.HALF_UP));
					if (miscLines.size()>0 && shopsuppliesid!=null) {
						miscLines[0].Id = shopsuppliesid;
					}
					System.debug(miscLines);
					System.debug(smcDelete);
					if (smcDelete.size()>0) delete(smcDelete);
					ServiceROHandler.AddingMiscCharges = true;
					System.debug('DML upsert->'+JSON.serialize(miscLines));
					upsert(miscLines);
				}
			}
		}
		// BLL22 end

		// BLL22 - recalc misc charges (shop supplies depend on book time now)
		lineTotalMisc((String) j.Id);
		// BLL22 end

        return getRoLines();
    }


    public String createMisc() {
		System.debug('createMisc');
        //RT1
        //
        SavePoint sp = Database.setSavepoint(); //JVK12

        GeneralLedgerAcctMW__c ledgerAccount = [SELECT Id FROM GeneralLedgerAcctMW__c WHERE GeneralLedgerAccountFF__c = :String.valueOf(String.valueOf(urlParameters.get('General_Ledger_Account__c')))];

        ServiceMiscCharges__c m =   new ServiceMiscCharges__c();
        m.Service_Job_Line__c   =   String.valueOf(urlParameters.get('lid'));
        m.Type__c               =   String.valueOf(urlParameters.get('Type__c'));
        m.Quantity__c           =   Decimal.valueOf(urlParameters.get('Quantity__c'));
        m.Amount__c             =   Decimal.valueOf(String.valueOf(urlParameters.get('Amount__c')));
        m.Amount__c             =   m.Amount__c.setScale(2, System.RoundingMode.HALF_UP);  //JVK - Rounding Issue (1/27/2016)
        m.General_Ledger_Acct_MW__c = ledgerAccount.Id;
        m.General_Ledger_Account__c  =  String.valueOf(String.valueOf(urlParameters.get('General_Ledger_Account__c')));

        try {
			System.debug('DML insert->'+JSON.serialize(m));
            insert m;
        } catch(DmlException e) {
            Database.rollback(sp);
            //DR4return '{ "error" : "'+e.getMessage()+'" }';

            //String msg = Utility.friendlyErrorMessage(e);   // DR4
            return '{ "error":"' + Utility.friendlyErrorMessage(e) + '"}';  // DR4
        }

        lineTotalMisc(String.valueOf(urlParameters.get('lid')));
        System.debug('NEW CHARGE: ' + m);
        // Update RO
        dealer__Service_Repair_Order__c ro = [Select Id from dealer__Service_Repair_Order__c where Id=:String.valueOf(urlParameters.get('rid')) limit 1];

        try {
			System.debug('DML update->'+JSON.serialize(ro));
            update ro;
        } Catch(DmlException e) {
            Database.rollback(sp);
            //DR4return '{ "error" : "'+e.getMessage()+'" }';

            //String msg = Utility.friendlyErrorMessage(e);   // DR4
            return '{ "error":"' + Utility.friendlyErrorMessage(e) + '"}';  // DR4
        }

        return 'true';
    }

    public String updateMisc() {
		System.debug('updateMisc');
        //RT1
        GeneralLedgerAcctMW__c ledgerAccount = [SELECT Id FROM GeneralLedgerAcctMW__c WHERE GeneralLedgerAccountFF__c = :String.valueOf(String.valueOf(urlParameters.get('General_Ledger_Account__c')))];

        SavePoint sp = Database.setSavepoint(); //JVK12

        ServiceMiscCharges__c m = [Select Id from ServiceMiscCharges__c where Id=:urlParameters.get('Id') limit 1];
        m.Amount__c = Decimal.valueOf(String.valueOf(urlParameters.get('Amount__c')));
        m.Amount__c = m.Amount__c.setScale(2, System.RoundingMode.HALF_UP);  //JVK - Rounding Issue (1/27/2016)
        m.Quantity__c               =   Decimal.valueOf(urlParameters.get('Quantity__c'));
        m.Type__c = String.valueOf(urlParameters.get('Type__c'));
        m.General_Ledger_Acct_MW__c = ledgerAccount.Id;
        m.General_Ledger_Account__c  =  String.valueOf(String.valueOf(urlParameters.get('General_Ledger_Account__c')));

        // Is there a new line being set?
        if( urlParameters.get('newLineId') != null ) m.Service_Job_Line__c =  String.valueOf(urlParameters.get('newLineId'));

        try {
			System.debug('DML update->'+JSON.serialize(m));
            update m;
        } catch(DmlException e) {
            Database.rollback(sp); // JVK12
            //BLL9d return '{ "error" : "'+e.getMessage()+'" }';
            //String msg = Utility.friendlyErrorMessage(e);   // BLL9a
            return '{ "error":"' + Utility.friendlyErrorMessage(e) + '"}';  // BLL9a
        }

        // Total Line - Service_Job_Line__c is the original line even if a new line is sent in the payout
        lineTotalMisc(String.valueOf(urlParameters.get('Service_Job_Line__c')));

        // calculate the new line totals
        if( urlParameters.get('newLineId') != null ) lineTotalMisc(String.valueOf(urlParameters.get('newLineId')));

        // Update RO
        dealer__Service_Repair_Order__c ro = [Select Id from dealer__Service_Repair_Order__c where Id=:String.valueOf(urlParameters.get('rid')) limit 1];

        try {
			System.debug('DML update->'+JSON.serialize(ro));
            update ro;
        } Catch(DmlException e) {
            Database.rollback(sp); //JVK12
            //BLL9d return '{ "error" : "'+e.getMessage()+'" }';
            //String msg = Utility.friendlyErrorMessage(e);   // BLL9a
            return '{ "error":"' + Utility.friendlyErrorMessage(e) + '"}';  // BLL9a
        }

        return 'true';
    }

    public String deleteMisc() {
        SavePoint sp = Database.setSavepoint(); //JVK12
        try {
        ServiceMiscCharges__c m = [Select Id from ServiceMiscCharges__c where Id=:urlParameters.get('Id') limit 1];
			System.debug('DML delete->'+JSON.serialize(m));
            delete m;
        } catch (Exception e) {
            //BLL9d return '{ "error" : "'+e.getMessage()+'" }';
            //String msg = Utility.friendlyErrorMessage(e);   // BLL9a
            return '{ "error":"' + Utility.friendlyErrorMessage(e) + '"}';  // BLL9a
        }

        lineTotalMisc(String.valueOf(urlParameters.get('Service_Job_Line__c')));

        // Update RO
        try {
            dealer__Service_Repair_Order__c ro = [Select Id from dealer__Service_Repair_Order__c where Id=:String.valueOf(urlParameters.get('rid')) limit 1];
			System.debug('DML update->'+JSON.serialize(ro));
            update ro;
        } Catch(Exception e) {
            Database.rollback(sp); //JVK12
            //BLL9d return '{ "error" : "'+e.getMessage()+'" }';
            //String msg = Utility.friendlyErrorMessage(e);   // BLL9a
            return '{ "error":"' + Utility.friendlyErrorMessage(e) + '"}';  // BLL9a
        }


        return 'true';
    }

    public void lineTotalMisc(String jobId) {
		System.debug('lineTotalMisc');

        SavePoint sp = Database.setSavepoint();

        AggregateResult[] sumLine = [Select SUM(Amount__c) line
                                     FROM ServiceMiscCharges__c
                                     where Service_Job_Line__c =:jobId];

        AggregateResult[] sumTime = [Select SUM(dealer__Actual_Time_Entry__c) time,
                                     SUM(Labor_Total__c) lineTotal,
                                     SUM(Labor_Cost__c) lineCost
                                     FROM dealer__Technician_Job_Time__c
                                     Where dealer__Service_Job_Line__c=:jobId];

        Decimal sum = (decimal) sumLine[0].get('line');
        if(sum==null) { sum = 0; }
        //BLL22 
		//dealer__Service_Job__c job  = [Select Id, dealer__Service_Repair_Order__c from dealer__Service_Job__c where Id=:jobId limit 1];
		dealer__Service_Job__c job  = [Select Id, dealer__Book_Time__c, dealer__Service_Repair_Order__c, dealer__Service_Repair_Order__r.dealer__Company__c from dealer__Service_Job__c where Id=:jobId limit 1];
		System.debug(location);
		if (location==null && job!=null && job.dealer__Service_Repair_Order__r.dealer__Company__c!=null) {
			location = [select Id, Name, dealer__State__c, LaborBookEqualsActualTime__c from dealer__Dealer_Location__c where Id=:job.dealer__Service_Repair_Order__r.dealer__Company__c limit 1];
		}
		System.debug(location);
		// BLL22 end
        job.dealer__Misc_Charges__c = sum.setScale(2, System.RoundingMode.HALF_UP);
        job.dealer__Actual_Time__c  = (Decimal)sumTime[0].get('time');
        // BLL22
		//job.dealer__Book_Time__c    = (Decimal)sumTime[0].get('time');
//		Decimal laborrate = calculateLaborRate(job.Id);
//		System.debug(laborrate);
//		if (laborrate==null) laborrate = 0;
		if (location.LaborBookEqualsActualTime__c) {
			job.dealer__Book_Time__c    = (Decimal)sumTime[0].get('time');
			job.dealer__Labor_Charges__c= (Decimal)sumTime[0].get('lineTotal');
			System.debug('dealer__Labor_Charges__c=' + String.valueOf(job.dealer__Labor_Charges__c));
		}
        // job.dealer__Labor_Charges__c= (Decimal)sumTime[0].get('lineTotal');
// BLL22
//		if (job.dealer__Book_Time__c!=null) {
//			job.dealer__Labor_Charges__c=job.dealer__Book_Time__c * laborrate;
//		}
// BLL22 end
		System.debug(job.dealer__Book_Time__c);
//		System.debug(job.dealer__Labor_Charges__c);
		// BLL22 end
        job.dealer__Technician_Cost__c = (Decimal)sumTime[0].get('lineCost');

        try { //JVK12 added catch block
			System.debug('DML update->'+JSON.serialize(job));
            update job;

            System.debug('Job Line Update - Line Total Misc');
            system.debug(job);
            
            // Commented to prevent Too many SOQL - Abhishek - 24 Jan 2017
            //dealer__Service_Repair_Order__c ro = [Select Id from dealer__Service_Repair_Order__c where Id=:job.dealer__Service_Repair_Order__c limit 1];
            //update ro;

        } Catch(DmlException e) {
            Database.rollback(sp); //JVK12
        }
    }

    public void lineTotalParts(String jobId) {
		System.debug('lineTotalParts');

        SavePoint sp = Database.setSavepoint(); //JVK12

        // JVK4 (remove SUM(Extended_Cost__c) replace SUM(dealer__Cost__c)), SUM(dealer__Price__c)
        AggregateResult[] sumLine = [Select SUM(dealer__Extended_Price__c) line, SUM(dealer__Cost__c) cost
                                     FROM  dealer__Parts_Invoice_Line__c
                                     where dealer__Job_Line__c =:jobId];
        if(sumLine.size() > 0) {


            Decimal sum = (decimal) sumLine[0].get('line');
            Decimal cost = (decimal) sumLine[0].get('cost');
            dealer__Service_Job__c job  = [Select Id from dealer__Service_Job__c where Id=:jobId limit 1];  // JVK8
            job.dealer__Parts_Total__c = sum;
            job.dealer__Parts_Cost__c = cost;

            try {
				System.debug('DML update->'+JSON.serialize(job));
                update job;
                //System.debug('Job Line Update - lineTotalParts');
                //System.debug(job);
            } Catch(DmlException e) {
                Database.rollback(sp);
            }
        }

    }

    public void lineTotalLabor(String jobId) {
		System.debug('lineTotalLabor');
        AggregateResult[] sumLine = [Select SUM(Labor_Total__c) line, SUM(Labor_Cost__c) cost
                                     FROM  dealer__Technician_Job_Time__c
                                     where dealer__Service_Job_Line__c =:jobId];

        if(sumLine.size() > 0) {
            Decimal sum = (Decimal) sumLine[0].get('line');
            Decimal cost= (Decimal) sumLine[0].get('cost');

            // BLL22
			//dealer__Service_Job__c job  = [Select Id from dealer__Service_Job__c where Id=:jobId limit 1];
            //job.dealer__Labor_Charges__c    = sum;
			dealer__Service_Job__c job  = [Select Id, Payment_Method__c, Payment_Method__r.Default_Labor_Rate__c, dealer__Book_Time__c from dealer__Service_Job__c where Id=:jobId limit 1];
			// get labor rate from payment method/location tables
//			Decimal laborrate = calculateLaborRate(job.Id);
//			System.debug(laborrate);
//			job.dealer__Labor_Charges__c    = job.dealer__Book_Time__c * laborrate;
			System.debug(job.dealer__Book_Time__c);
//			System.debug(job.dealer__Labor_Charges__c);
			// BLL22
            job.dealer__Technician_Cost__c  = cost;

            try {
				ServiceProcess.ReloadROLines = true;	// BLL22
				System.debug('DML update->'+JSON.serialize(job));
                update job;

                System.debug('Job Line Update - lineTotalLabor');
                system.debug(job);

			// no need to differentiate between exception types, we're just throwing a new exception
            //} Catch(DmlException e) {
            //    throw new ROException('DML Exception '+e);
            //} Catch(SObjectException e) {
            //    throw new ROException('SObject Exception '+e);
            } Catch(Exception e) {
                throw new ROException('Exception '+e);
            }
        }

    }

    public String createTechTime() {
		System.debug('createTechTime');
        /*
        Initialize Technician Time
        */
        dealer__Technician_Job_Time__c tt = new dealer__Technician_Job_Time__c();
        tt.dealer__Service_Job_Line__c  =   String.valueOf(urlParameters.get('lid'));
        tt.dealer__Technician__c        =   String.valueOf(urlParameters.get('dealer__Technician__c[Id]'));
        tt.dealer__Actual_Time_Entry__c =   Decimal.valueOf(String.valueOf(urlParameters.get('dealer__Actual_Time_Entry__c')));
        tt.Labor_Total__c               =   Decimal.valueOf(String.valueOf(urlParameters.get('Labor_Total__c')));
        tt.dealer__Date__c              =   Date.parse(String.valueOf(urlParameters.get('dealer__Date__c')));


        // Check for Zero as in input on labor_total (UI Sets this value)
        if(String.valueOf(urlParameters.get('Labor_Total__c'))=='0') tt.Labor_Total__c=null;

        // Location based labor cost.
        tt.Payment_Method_Labor_Rate__c =   calculateLaborRate (tt.dealer__Service_Job_Line__c);
        tt.Labor_Cost__c                =   calculateLaborCost (tt.dealer__Service_Job_Line__c);

        if(tt.Labor_Total__c==null) tt.Labor_Total__c = tt.Payment_Method_Labor_Rate__c * tt.dealer__Actual_Time_Entry__c;

        if (tt!=null && tt.Labor_Total__c!=null) tt.Labor_Total__c = tt.Labor_Total__c.setScale(2, System.RoundingMode.HALF_UP);    // BLL6a

        //BLL9d try {
			System.debug('DML insert->'+JSON.serialize(tt));
        	insert tt;
        //BLL9d } catch(DmlException e) {
        //BLL9d    return '{"error":"'+e.getMessage()+'"}';
        //BLL9d}

        // Create Misc Items
        createTechMisc(tt, tt.dealer__Service_Job_Line__c);

        // Re-total misc items
        lineTotalMisc(tt.dealer__Service_Job_Line__c);

        return tt.Id;
    }

    public void createTechMisc(dealer__Technician_Job_Time__c tt_pc, String jobLineID) {
		System.debug('createTechMisc');
		// BLL9
		//ProductionWork.add('IHA');	// Home Access
		// BLL9 end
        dealer__Service_Job__c jobline = [
        	Select Id, Name, Payment_Method__c, Payment_Method__r.Shop_Supplies_Rate__c,
        		Payment_Method__r.Name, 	// BLL13a
				dealer__Service_Repair_Order__r.dealer__Company__r.LaborBookEqualsActualTime__c, dealer__Book_Time__c, // BLL22
				Payment_Method__r.Hazmat_Fee__c, dealer__Service_Repair_Order__r.dealer__Company__r.dealer__State__c, dealer__Service_Repair_Order__r.dealer__Company__c, dealer__Service_Repair_Order__r.Shop_Supplies_Charges__c
				FROM dealer__Service_Job__c WHERE Id=:jobLineID
				LIMIT 1
		];

        // add misc Hazmat line if applicable
        List<ServiceMiscCharges__c> miscLines = new List<ServiceMiscCharges__c>();
        //RT1 hazmat also needs to check if in CA
        System.debug('jobline.Payment_Method__r.Hazmat_Fee__c ->'+jobline.Payment_Method__r.Hazmat_Fee__c);
        System.debug('jobline.dealer__Service_Repair_Order__r.dealer__Company__r.dealer__State__c ->'+jobline.dealer__Service_Repair_Order__r.dealer__Company__r.dealer__State__c);

		// ensure location's misc charges are loaded up...
		LoadMiscChargeOptionsForLocId(jobline.dealer__Service_Repair_Order__r.dealer__Company__c);	// BLL7a
        
        if(jobline.Payment_Method__r.Hazmat_Fee__c!=null && jobline.Payment_Method__r.Hazmat_Fee__c!=0 && jobline.dealer__Service_Repair_Order__r.dealer__Company__r.dealer__State__c != 'CA') {
            List<ServiceMiscCharges__c> hazmatCharge = [SELECT Id, Service_Job_Line__c FROM ServiceMiscCharges__c WHERE Service_Job_Line__c = :jobline.Id and Type__c='Hazardous Materials'];	// BLL17c
            if(hazmatCharge.size() == 0) { //RT1 Only one hazmat charge per line
                System.debug(jobline.dealer__Service_Repair_Order__r.dealer__Company__c);
				System.debug('Create hazmat misc chg');
        		autoCreateMiscCharge(miscLines, jobline.Id, tt_pc.Id, 'Hazardous Materials', null);

/**
                //TODO: Select MISC OPtions Item From Database and get account is type equals HAZMAT
                //RT1
                //BLL7d Misc_Charge_Option__c[] misc = [SELECT Id,Name, General_Ledger_Acct_MW__c, General_Ledger_Acct_MW__r.GeneralLedgerAccountFF__c, General_Ledger_Account__c,Quantity__c,Rate__c FROM Misc_Charge_Option__c WHERE Name LIKE 'Hazardous Materials' AND Location__c =: jobline.dealer__Service_Repair_Order__r.dealer__Company__c LIMIT 1];
                LoadMiscChargeOptionsForLocId(jobline.dealer__Service_Repair_Order__r.dealer__Company__c);	// BLL7a
				Misc_Charge_Option__c misc = mcoMap.get('Hazardous Materials');	// BLL7a
                

                // BLL7d if(misc.size()>0) {
                if (misc!=null) {	// BLL7a
                    // stuff
                    System.debug('****** MISC: ' + misc);

                    // Add Misc Line
                    miscLines.add(new ServiceMiscCharges__c(
                        Service_Job_Line__c     =   jobline.Id,
                        Type__c                 =   misc.Name,
                        General_Ledger_Acct_MW__c = misc.General_Ledger_Acct_MW__c,
                        General_Ledger_Account__c = misc.General_Ledger_Acct_MW__r.GeneralLedgerAccountFF__c,
                        Quantity__c             =   misc.Quantity__c,
                        Amount__c               =   misc.Rate__c.setScale(2, System.RoundingMode.HALF_UP),  //JVK - Rounding Issue (1/27/2016),
                        Technician_Job_Time_Creator__c = tt_pc.Id)
                                 );

                } else {
                    throw new ROException('Misc. Charge Type of "Hazardous Materials" has not been configured for this location.');
                    //return '{"error":\'Misc. Charge Type of "Hazardous Materials" has not been configured for this location.\'}';
                }
**/
            }

        }

        // add misc Supplies line if applicable
		// BLL22 end
        //if(jobline.Payment_Method__r.Shop_Supplies_Rate__c!=null&&jobline.Payment_Method__r.Shop_Supplies_Rate__c!=0) {
		if(jobline.Payment_Method__r.Shop_Supplies_Rate__c!=null && jobline.Payment_Method__r.Shop_Supplies_Rate__c!=0
			&& 	jobline.dealer__Service_Repair_Order__r.dealer__Company__r.LaborBookEqualsActualTime__c==true) {
		// BLL22 end
            // Labor Charges times Rate
            Decimal shop_supplies = tt_pc.Labor_Total__c * (jobLine.Payment_Method__r.Shop_Supplies_Rate__c / 100);
            shop_supplies = shop_supplies.setScale(2, System.RoundingMode.HALF_UP); // BLL6a

            // Check to see if we are in CA
            //TODO: Select MISC Item From Database and get account is type equals HAZMAT
            if((jobline.dealer__Service_Repair_Order__r.dealer__Company__r.dealer__State__c != 'CA' || ProductionWork.contains(jobline.Payment_Method__r.Name))	// BLL13a allow on IE* and GR*V for Calif.
               && jobline.dealer__Service_Repair_Order__r.Shop_Supplies_Charges__c < 25.00) {

                if(shop_supplies + jobline.dealer__Service_Repair_Order__r.Shop_Supplies_Charges__c > 25.00) {
                    shop_supplies = 25 - jobline.dealer__Service_Repair_Order__r.Shop_Supplies_Charges__c;
                }
				System.debug('Create shop supplies misc chg');
        		autoCreateMiscCharge(miscLines, jobline.Id, tt_pc.Id, 'Shop Supplies', shop_supplies.setScale(2, System.RoundingMode.HALF_UP));

/**
                //RT1
                //Misc_Charge_Option__c[] misc = [SELECT Id,Name, General_Ledger_Acct_MW__c, General_Ledger_Acct_MW__r.GeneralLedgerAccountFF__c, General_Ledger_Account__c, Quantity__c,Rate__c FROM Misc_Charge_Option__c WHERE Name LIKE 'Shop Supplies' AND Location__c =: jobline.dealer__Service_Repair_Order__r.dealer__Company__c LIMIT 1];
                LoadMiscChargeOptionsForLocId(jobline.dealer__Service_Repair_Order__r.dealer__Company__c);	// BLL7a
				Misc_Charge_Option__c misc = mcoMap.get('Shop Supplies');	// BLL7a
                
                if(shop_supplies + jobline.dealer__Service_Repair_Order__r.Shop_Supplies_Charges__c > 25.00) {
                    shop_supplies = 25 - jobline.dealer__Service_Repair_Order__r.Shop_Supplies_Charges__c;
                }
                // BLL7d if(misc.size()>0) {
                if (misc!=null) { 	// BLL7a
                    // stuff
                    System.debug('****** MISC: ' + misc);

                    // Add Misc Line
                    miscLines.add(new ServiceMiscCharges__c(
                        Service_Job_Line__c     =   jobline.Id,
                        Type__c                 =   misc.Name,
                        General_Ledger_Acct_MW__c = misc.General_Ledger_Acct_MW__c,
                        General_Ledger_Account__c = misc.General_Ledger_Acct_MW__r.GeneralLedgerAccountFF__c,
                        Quantity__c             =   misc.Quantity__c,
                        Amount__c               =   shop_supplies.setScale(2, System.RoundingMode.HALF_UP),
                        Technician_Job_Time_Creator__c = tt_pc.Id,
                        Tech_Time_Charge__c = true
                     ));

                } else {
                    throw new ROException('Misc. Charge Type of "Shop Supplies" has not been configured for this location.');
                    //return '{"error":\'Misc. Charge Type of "Hazardous Materials" has not been configured for this location.\'}';
                }
**/
            }
        }

        if(miscLines.size()>0) {
			ServiceROHandler.AddingMiscCharges = true;
			System.debug('DML insert->'+JSON.serialize(miscLines));
			insert miscLines;
            // System.debug(miscLines);
		}

        // lineTotalMisc( jobline.Id ); JVK - Method Duplicated
    }

	// autoCreateMiscCharge
	//-------------------------------------
	public void autoCreateMiscCharge(List<ServiceMiscCharges__c> miscLines, Id jobId, Id creatorId, String misctype, Decimal amount) {
		Misc_Charge_Option__c misc = mcoMap.get(misctype);	// BLL7a
		System.debug('****** MISC: ' + misc);
		System.debug(jobId); 
		System.debug(creatorId);
		System.debug(misctype);
		System.debug(amount);
		ServiceMiscCharges__c newmisc = new ServiceMiscCharges__c(
			Service_Job_Line__c     =   jobId
		);
		if (creatorId!=null && creatorId.getSObjectType()==Schema.dealer__Technician_Job_Time__c.SObjectType) newmisc.Technician_Job_Time_Creator__c = creatorId;
		else if (creatorId!=null && creatorId.getSObjectType()==Schema.dealer__Parts_Invoice_Line__c.SObjectType) newmisc.Part_Line__c = creatorId;
		else if (creatorId!=null) newmisc.Other_Creator_Id__c = creatorId;	// BLL22
		if (misc!=null) {
			newmisc.Type__c = misc.Name;
			newmisc.Quantity__c = misc.Quantity__c;
			newmisc.General_Ledger_Acct_MW__c = misc.General_Ledger_Acct_MW__c;
			newmisc.General_Ledger_Account__c = misc.General_Ledger_Acct_MW__r.GeneralLedgerAccountFF__c;
			newmisc.Amount__c = amount!=null ? amount : misc.Rate__c;
		} else {
			throw new ROException('Misc. Charge Type of "' + misctype + '" has not been configured for this location.');
		}
		if (newmisc.Amount__c!=null) newmisc.Amount__c = newmisc.Amount__c.setScale(2, System.RoundingMode.HALF_UP);
		miscLines.add(newmisc);
	}

    // Overload for null parameters
    public String updateTechTime() {
		System.debug('updateTechTime no parms');
        // Default Id
        return updateTechTime(
            String.valueOf( urlParameters.get('Id') ) ,
            Decimal.valueOf(String.valueOf(urlParameters.get('dealer__Actual_Time_Entry__c'))),
            Date.parse(String.valueOf(urlParameters.get('dealer__Date__c')))
        );
    }
    public String updateTechTime(String ttimeId, Decimal ttTime, Date ttDate ) {
		System.debug('updateTechTime');
		// BLL19
		boolean RepairOrderTechTimeDate = FeatureManagement.checkPermission('RepairOrderTechTimeDate');
		// BLL19

        // JVK3
        SavePoint sp = Database.setSavepoint();

        // BLL20d if(Limits.getQueries() > 85) return '';

        dealer__Technician_Job_Time__c tt = [Select Id,dealer__Service_Job_Line__c, Payment_Method_Labor_Rate__c ,dealer__Actual_Time_Entry__c,dealer__Date__c, Labor_Total__c from dealer__Technician_Job_Time__c
                                             where Id=:ttimeId
                                             limit 1];
        
		if(urlParameters.get('dealer__Technician__c[Id]')!=null && urlParameters.get('dealer__Technician__c[Id]')!='') {
        	tt.dealer__Technician__c = (Id)urlParameters.get('dealer__Technician__c[Id]');
        } else {
			tt.dealer__Technician__c = (Id)urlParameters.get('dealer__Technician__c'); 
        }        

        // use the time form the URL parameters otherwise use the time from the database.
        tt.dealer__Actual_Time_Entry__c = (ttTime != null) ? ttTime : tt.dealer__Actual_Time_Entry__c;

        // Use the date form the URL parameters otherwise use the time from the database.
        tt.dealer__Date__c  = (ttDate != null) ? ttDate : tt.dealer__Date__c;

        // Check to see if Date is more than 15 Days back of Current Date
        if((tt.dealer__Date__c < Date.today().addDays(-15)) && roProtectOff==false)  {	// JVK15c
            System.debug('DATE ERROR ' + tt.dealer__Date__c + ' ' +  Date.today().addDays(-15));
            //BLL9d return '{"error":\'Days may not be more than 15 days less than today.\'}';
			// BLL19
            //throw new ROException('Days may not be more than 15 days less than today.');    //BLL9a
			if (!RepairOrderTechTimeDate) throw new ROException('Days may not be more than 15 days less than today.');    //BLL9a
			// BLL19  
        }


        // Store Original tt.Labor_Total__c before override
        Decimal laborOg = tt.Labor_Total__c;

        tt.Payment_Method_Labor_Rate__c = calculateLaborRate (tt.dealer__Service_Job_Line__c);
        // Calculeate labor total
        if(tt.Payment_Method_Labor_Rate__c == null) { tt.Payment_Method_Labor_Rate__c = 0; }
        tt.Labor_Total__c = tt.Payment_Method_Labor_Rate__c * tt.dealer__Actual_Time_Entry__c;
        tt.Labor_Total__c = tt.Labor_Total__c.setScale(2, System.RoundingMode.HALF_UP); // BLL6a

        // Is there a new job line being set? OR did the labor total change?
        //BLL20
		// if( (urlParameters.get('newLineId') != null || (tt.Labor_Total__c != laborOg)) && Limits.getQueries() < 88 ) {
		if( (urlParameters.get('newLineId') != null || (tt.Labor_Total__c != laborOg))) {
		// BLL20 end

            // Process original Job Line before re-assigning

            // delete lines related to the original job line
            List<ServiceMiscCharges__c> currMiscLines = [Select Id from ServiceMiscCharges__c where Technician_Job_Time_Creator__c =: tt.Id Limit 500];
            if(currMiscLines.size()>0){
				System.debug('DML delete->'+JSON.serialize(currMiscLines));
                Delete currMiscLines;

                // re-total lines on Original Job Line
                lineTotalMisc( tt.dealer__Service_Job_Line__c );
            }

            // ** Set the Job Line to the new Line Id. **
            if(urlParameters.get('newLineId') != null){
                tt.dealer__Service_Job_Line__c = String.valueOf(urlParameters.get('newLineId'));
            }

            try {

                // Create Misc lines for newly assigned Job Line
                createTechMisc(tt, tt.dealer__Service_Job_Line__c);
                lineTotalMisc( tt.dealer__Service_Job_Line__c );

            } Catch(DmlException e) {
                Database.rollback(sp);
                //BLL9d return '{"error":"'+e.getMessage()+'"}';
                //String msg = Utility.friendlyErrorMessage(e);   // BLL9a
                return '{ "error":"' + Utility.friendlyErrorMessage(e) + '"}';  // BLL9a
            }

        }

        //BLL9d try {
			System.debug('DML update->'+JSON.serialize(tt));
            update tt;
            System.debug('UpdateTechTime finished');

        //BLL9d } catch(DmlException e) {
        //BLL9d     Database.rollback(sp);
        //BLL9d     return '{"error":"'+e.getMessage()+'"}';
        //BLL9d }

        // JVK3 - Set the actual time on the RO Job Line
        dealer__Service_Job__c jUp  = [Select Id from dealer__Service_Job__c where Id=:tt.dealer__Service_Job_Line__c limit 1];
        AggregateResult[] sumActual = [Select SUM(dealer__Actual_Time_Entry__c) actual
                                       FROM  dealer__Technician_Job_Time__c
                                       where dealer__Service_Job_Line__c =:tt.dealer__Service_Job_Line__c];

        Decimal atime = Decimal.valueOf(String.valueOf(sumActual[0].get('actual')));

        try {
            jUp.dealer__Actual_Time__c = atime;
			ServiceProcess.ReloadROLines = true;	// BLL22
			System.debug('DML update->'+JSON.serialize(jUp));
            update jUp;
        } Catch(DmlException e) {
            Database.rollback(sp);
            //BLL9d return '{"error":"'+e.getMessage()+'"}';
            //String msg = Utility.friendlyErrorMessage(e);   // BLL9a
            return '{ "error":"' + Utility.friendlyErrorMessage(e) + '"}';  // BLL9a
        }

        //// Re-total labor for parent line
        //if(Limits.getQueries() < 88) {
        //  //lineTotalLabor(tt.dealer__Service_Job_Line__c); // Happening in trigger
        //}


        return tt.Id;
    }

    /**
    * Calculate the labor rate based on payment methos.
    * @param  jlId Service Job IdLine Id
    * @return      Labor Rate
    */
    public Decimal calculateLaborRate(String jlId) {
        // BLL22
		//Decimal laborRate = 0;
		// BLL22 end
        // Get the line
        dealer__Service_Job__c jobLine = [SELECT Id, Name, Payment_Method__c, Payment_Method__r.Name, dealer__Service_Repair_Order__c FROM dealer__Service_Job__c WHERE Id =: jlId LIMIT 1];

		// BLL22
		return calculateLaborRatePay(jobline.dealer__Service_Repair_Order__c, jobline.Payment_Method__c);
        //// Get RO
        //dealer__Service_Repair_Order__c repairOrder = [SELECT Id, Name, dealer__Company__c, dealer__Location__c FROM dealer__Service_Repair_Order__c WHERE Id =: jobLine.dealer__Service_Repair_Order__c LIMIT 1];
		//
        //// Get location of repair order.
        //List<ServicePaymentType__c> payType = [SELECT Id, Default_Labor_Rate__c, (SELECT Labor_Rate__c FROM LaborRateDefaults__r WHERE Location__c =: repairOrder.dealer__Company__c) defRate FROM ServicePaymentType__c WHERE Id =: jobLine.Payment_Method__c];
		//
        //if(payType.size() > 0) {
		//
        //    if( payType[0].LaborRateDefaults__r.size() > 0 ) {
        //        laborRate = payType[0].LaborRateDefaults__r[0].Labor_Rate__c;
        //    } else {
        //        laborRate = payType[0].Default_Labor_Rate__c;
        //    }
        //}
		//
	    //return laborRate;
		// BLL22 end
    }

	// BLL22
    public Decimal calculateLaborRatePay(String roId, String pmId) {
        Decimal laborRate = 0;

        // Get RO
        dealer__Service_Repair_Order__c repairOrder = [
			SELECT Id, Name, dealer__Company__c, dealer__Location__c 
			FROM dealer__Service_Repair_Order__c 
			WHERE Id =:roId LIMIT 1
		];

        // Get location of repair order.
        List<ServicePaymentType__c> payType = [
			SELECT Id, Default_Labor_Rate__c, 
				(SELECT Labor_Rate__c 
				 FROM LaborRateDefaults__r 
				 WHERE Location__c =:repairOrder.dealer__Company__c) defRate 
			FROM ServicePaymentType__c 
			WHERE Id =:pmId];

        if(payType.size() > 0) {

            if( payType[0].LaborRateDefaults__r.size() > 0 ) {
                laborRate = payType[0].LaborRateDefaults__r[0].Labor_Rate__c;
            } else {
                laborRate = payType[0].Default_Labor_Rate__c;
            }
        }

        return laborRate;
    }
	// BLL22 end

    /**
    *
    *   Calculate Labor Cost
    *
    */
    public Decimal calculateLaborCost(String jlId) {
        Decimal rtnRate = 0;    // BLL4a
        
        // Get the location Id from the Service Job Line
        Id locationId = [Select Id, Location_Id__c from dealer__Service_Job__c where Id=:jlId].Location_Id__c;

        // Get the Internal Labor Rate from the Company the Repair Order is Associated with.
        dealer__Dealer_Location__c[] loc = [Select Internal_Labor_Rate__c from dealer__Dealer_Location__c where Id=:locationId limit 1];

        //BLL4d if(loc.size()==1) {
            //BLL4d return loc[0].Internal_Labor_Rate__c;
        //BLL4d}
        if(loc.size()==1) rtnRate = loc[0].Internal_Labor_Rate__c;  // BLL4a

        //BLL4d return 0;
        return rtnRate; // BLL4a
    }

    public String deletTechTime() {
		System.debug('deletTechTime');

        SavePoint sp = Database.setSavepoint();

        dealer__Technician_Job_Time__c tt = [Select Id, dealer__Repair_Order_Name__c, dealer__Service_Job_Line__c
                                             from dealer__Technician_Job_Time__c where Id =:urlParameters.get('Id') limit 1];
        ServiceMiscCharges__c[] assCharges = [Select Id, Repair_Order_ID__c from ServiceMiscCharges__c where Technician_Job_Time_Creator__c =:urlParameters.get('Id') limit 100];

        try {
			System.debug('DML delete->'+JSON.serialize(assCharges));
            delete assCharges;
			System.debug('DML delete->'+JSON.serialize(tt));
            delete tt;
        } catch (DmlException e) {
            Database.rollback(sp);
            //BLL9d return '{"error":"'+e.getMessage()+'"}';
            //String msg = Utility.friendlyErrorMessage(e);   // BLL9a
            return '{ "error":"' + Utility.friendlyErrorMessage(e) + '"}';  // BLL9a
        }

        lineTotalLabor(tt.dealer__Service_Job_Line__c);
        lineTotalMisc(tt.dealer__Service_Job_Line__c);
        // Update RO To Re-Calc Line
        dealer__Service_Repair_Order__c ro = [Select Id from dealer__Service_Repair_Order__c
                                              where Name=:tt.dealer__Repair_Order_Name__c limit 1];

        try {
			System.debug('DML update->'+JSON.serialize(ro));
            update ro;
        } Catch(DmlException e) {
            Database.rollback(sp);
            //BLL9d return '{"error":"'+e.getMessage()+'"}';
            //String msg = Utility.friendlyErrorMessage(e);   // BLL9a
            return '{ "error":"' + Utility.friendlyErrorMessage(e) + '"}';  // BLL9a
        }

        return 'true';
    }

    public String getTechRow() {
        dealer__Technician_Job_Time__c tt = [SELECT dealer__Service_Job_Line__c, dealer__Actual_Time__c, dealer__Available_Flat_Rate_Time__c, dealer__Book_Time__c, dealer__Diag_Repair__c, dealer__Efficiency__c, dealer__Elapsed_Time_Minutes__c, dealer__End_Time__c, dealer__Flat_Rate_Time__c, dealer__Job_Name__c, dealer__Job_Status__c, dealer__Labor_Type__c, dealer__Repair_Order_Name__c, dealer__Repair_Order_Number__c, dealer__Start_Time__c, dealer__Technician__c, dealer__Time_Punch_Notes__c, Time_Clock_Entry__c, dealer__Actual_Time_Entry__c, dealer__Date__c, dealer__Time_Clock__c, Payment_Method_Labor_Rate__c, Labor_Total__c, Name, Id,
                                             dealer__Technician__r.Name, Job_Line_Number__c FROM dealer__Technician_Job_Time__c where Id=:ttId limit 1];
        return JSON.serializePretty(tt);
    }

    // Access via "operations"
	// BLL22 reformat SOQL queries to multi-line
    public String getOperationCodes() {
        List<dealer__Service_Job__c> roLines = [
			SELECT dealer__Standard_Operation_Code__c 
			FROM dealer__Service_Job__c 
			WHERE dealer__Service_Repair_Order__c = :rid
		]; //ACB1
        Set<Id> roCodes = new Set<Id>(); //ACB1
        for(dealer__Service_Job__c l : roLines) roCodes.add(l.dealer__Standard_Operation_Code__c); //ACB1
        List<dealer__StandardOpCode__c> lops = [
			SELECT Name, dealer__Active__c, dealer__Associated_Marketing_Template__c, 
				dealer__Book_Time__c, dealer__Cause__c, dealer__Company_Number__c, dealer__Concern__c,
				dealer__Correction__c, dealer__Default__c, dealer__Dispatch_Code__c, dealer__Estimate__c, 
				dealer__Labor_Estimate__c, dealer__Make__c, dealer__Op_Code_Description__c, 
				dealer__Op_Code__c, dealer__Operation_Notes__c, dealer__Parts_Estimate__c, 
				dealer__Pay_Type__c, dealer__Primary_Category__c, dealer__Recommended_Service_Code__c, 
				dealer__RecordId__c, dealer__Remarketing_Default_Delay__c, dealer__Service_Type__c, 
				Labor_Rate__c, dealer__Service_Group__c, Default_Payment_Method__c, Id 
			FROM dealer__StandardOpCode__c 
			WHERE dealer__Active__c = true OR Id IN :roCodes 
			ORDER BY Name ASC limit 2000
		]; //ACB1
        return JSON.serializePretty(lops);
    }

    public String getPaymentMethods() {
        List<ServicePaymentType__c> pm = [
        	select Id, Name, Default_Labor_Rate__c
        	from ServicePaymentType__c
        	where Active__c=true	// BLL18a 
        	order by Name ASC 
        	limit 2000
        ];
        return JSON.serializePretty(pm);
    }

	// BLL22 reformat SOQL
    public String getRoLines() {
        List<dealer__Service_Job__c> lines = [
			SELECT ID, Name, Sublet_Sum__c, dealer__Service_Repair_Order__c, dealer__Actual_Time__c, 
				dealer__Book_Time__c, dealer__Cause__c, dealer__CauseExtended__c, dealer__Concern__c, 
				dealer__Correction__c, dealer__Customer_Id__c, dealer__Estimate__c, dealer__Gross_Profit__c, 
				dealer__Job_Added_Date__c, dealer__Job_ELR__c, dealer__Job_Finish__c, dealer__Job_Line_Id__c, 
				dealer__Job_Start__c, dealer__Labor_Charges__c, dealer__Labor_Rate__c, dealer__Labor_Type__c, 
				dealer__Line_Number__c, dealer__Line_Total__c, dealer__Op_Code__c, dealer__Operation_Code_Description__c, 
				dealer__Parent_Record__c, dealer__Parts_Cost__c, dealer__Parts_Invoice_Id__c, dealer__Parts_Line__c, 
				dealer__Parts_Total__c, dealer__RO_Invoice_Date_Time__c, dealer__RO_Number__c, dealer__RO_Status__c, 
				dealer__Repair_Order_Id__c, dealer__Repair_Order__c, dealer__Service_Type__c, dealer__Service_Vehicle_Id__c, 
				dealer__Standard_Operation_Code__c, dealer__Stat__c, dealer__Sublet_Total__c, dealer__Technician_Cost__c, 
				dealer__Technician__c, dealer__Currently_Active__c, dealer__Sum_of_Billed_Hours__c, Payment_Notes__c, 
				dealer__Add_On__c, dealer__Misc_Charges__c, dealer__Op_Description__c, dealer__Technician_ID__c, 
				dealer__CustomerConcern__c, dealer__RO_Open_Date_Time__c, dealer__Claim__c, dealer__Paid_By__c, 
				Payment_Method__c, Payment_Method__r.Name,
				(SELECT dealer__Parts_Invoice__c, dealer__Bin__c, dealer__Core__c, dealer__Cost__c, dealer__Counterman_No__c, dealer__Counterman__c, dealer__Currently_Available__c,dealer__Part__r.dealer__Physical_OnHand__c, dealer__Drop_Ship__c, dealer__Extended_Price__c, dealer__Gross_Margin__c, dealer__Job_Line__c, dealer__List__c, dealer__MFG__c, dealer__Net_Price__c, dealer__Net__c, dealer__Order_Type__c, dealer__Part_Description__c, dealer__Part_Number__c, dealer__Part__c, dealer__Pay_Type__c, dealer__Price_Level_Strategy__c, dealer__Price_Level__c, dealer__Price__c, dealer__Quantity_Ordered__c, dealer__Quantity_Sold__c, dealer__Sale_Date__c, dealer__Service_Job_Line_Number__c, dealer__Service_Line_Payment_Method__c, dealer__Service_Repair_Order__c, dealer__Sold_Via__c, dealer__Source__c, dealer__Stocking_Group__c, dealer__Total_Price__c, dealer__Total_Tax__c, dealer__Transaction_Code__c, Name, Id FROM dealer__Parts_Lines__r),
				(SELECT dealer__Service_Job_Line__c, dealer__Actual_Time__c, dealer__Available_Flat_Rate_Time__c, dealer__Book_Time__c, dealer__Diag_Repair__c, dealer__Efficiency__c, dealer__Elapsed_Time_Minutes__c, dealer__End_Time__c, dealer__Flat_Rate_Time__c, dealer__Job_Name__c, dealer__Job_Status__c, dealer__Labor_Type__c, dealer__Repair_Order_Name__c, dealer__Repair_Order_Number__c, dealer__Start_Time__c, dealer__Technician__c, dealer__Technician__r.Name, dealer__Time_Punch_Notes__c, Time_Clock_Entry__c, dealer__Actual_Time_Entry__c, dealer__Date__c, dealer__Time_Clock__c, Name, Id, Payment_Method_Labor_Rate__c FROM dealer__Technician_Job_Times__r),
				(SELECT dealer__Purchase_Order__c, dealer__Purchase_Order__r.Name, dealer__Account__c, dealer__Amount__c, dealer__Description__c, dealer__Drop_Ship_Address__c, dealer__Drop_Ship_To__c, dealer__Part_Quantity__c, dealer__Part__c, dealer__Parts_Invoice__c, dealer__Special_Instructions__c, General_Ledger_Account__c, dealer__Service_Job_Line__c, Name, Id FROM dealer__Purchase_Order_Line__r),
				(SELECT Id, Name, Amount__c, Service_Job_Line__c, Type__c from Service_Misc_Charge__r),
				dealer__Standard_Operation_Code__r.Name, dealer__Standard_Operation_Code__r.Id
			FROM dealer__Service_Job__c 
			WHERE dealer__Service_Repair_Order__c =:roId 
			ORDER BY dealer__Line_Number__c ASC LIMIT 2000
		];

        // If We are returning a single job line, only return that one record (Updates and Creates)
        List<dealer__Service_Job__c> line_jonbonly = new List<dealer__Service_Job__c>();
        if(jobLineId!=null) {
            for(dealer__Service_Job__c j : lines) {
                if(j.Id==jobLineId) {
                    line_jonbonly.add(j);
                }
            }

            if(line_jonbonly.size()>0) {
                lines = line_jonbonly;
            }
        }

        return JSON.serializePretty(lines);
    }

    public String getTechTimes() {
        List<dealer__Technician_Job_Time__c> tt = [SELECT dealer__Service_Job_Line__c, dealer__Actual_Time__c, dealer__Available_Flat_Rate_Time__c, dealer__Book_Time__c, dealer__Diag_Repair__c, dealer__Efficiency__c, dealer__Elapsed_Time_Minutes__c, dealer__End_Time__c, dealer__Flat_Rate_Time__c, dealer__Job_Name__c, dealer__Job_Status__c, dealer__Labor_Type__c, dealer__Repair_Order_Name__c, dealer__Repair_Order_Number__c, dealer__Start_Time__c, dealer__Technician__c, dealer__Technician__r.Name, dealer__Time_Punch_Notes__c, Time_Clock_Entry__c, dealer__Actual_Time_Entry__c, dealer__Date__c, dealer__Time_Clock__c, Name, Id, Payment_Method_Labor_Rate__c, Job_Line_Number__c, Labor_Total__c FROM dealer__Technician_Job_Time__c where dealer__Service_Job_Line__c=:urlParameters.get('lid') limit 500];

        return JSON.serializePretty(tt);
    }

    public String getMiscItems() {
        List<ServiceMiscCharges__c> ml = [SELECT Id, Name, Amount__c, General_Ledger_Account__c, Type__c, Service_Job_Line__c, Quantity__c, Service_Job_Line__r.dealer__Line_Number__c FROM ServiceMiscCharges__c WHERE Service_Job_Line__c =:urlParameters.get('lid') limit 500];

        return JSON.serializePretty(ml);
    }

    public String getTechnicians() {
        System.debug('ROID: '+roId);

        String companyKey = '';

        if(roId != null && roId != '') {
            // Get the Company Number from the RO
            companyKey = [SELECT dealer__Company__r.dealer__Company_Number__c FROM dealer__Service_Repair_Order__c where Id=:roId LIMIT 1].dealer__Company__r.dealer__Company_Number__c;
        } else {
            // Get Users Current Location
            //BLL5d User u = [Select Id, Division from User where Id=:UserInfo.getUserId() limit 1];
            User u = CurrentUserSingleton.getInstance();    // BLL5a
            companyKey = u.Division;
        }

        // Get users by division using COmpany Number
        //BLL10d List<User> techList = [Select Id, FirstName, LastName, Name from User where dealer__Technician__c = true and Division =:companyKey limit 500];
        // BLL10a
        System.debug(companyKey);
        Set<Id> techUserIds = new Set<Id>();
        for(dealer__Dealer_Location_User__c st : [
        		select dealer__User__c
        		from dealer__Dealer_Location_User__c
    	    	where dealer__Dealer_Location__r.dealer__Company_Number__c=:companyKey
    	    	  and dealer__Technician__c=true and dealer__User__r.IsActive=true	// BLL15a
	        ]) {
	       	techUserIds.add(st.dealer__User__c);
	       	System.debug(st);
	    }
        List<User> techList = [Select Id, FirstName, LastName, Name from User where Id in :techUserIds limit 500];
        // BLL10a end

        return JSON.serializePretty(techList);
    }

    public String getstatusCodes() {

        Schema.DescribeFieldResult fieldResult = dealer__Service_Job__c.dealer__Stat__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        List<Object> statList = new List<Object>();
        for( Schema.PicklistEntry f : ple) {
            //List<Object> statMap = new List<Object>();
            Map<String, String> statMap = new Map<String, String>();

            statMap.put('label', f.getLabel());
            statMap.put('value', f.getValue());

            statList.add(statMap);
        }

        return JSON.serializePretty(statList);
    }

    /** Conversion Fields */
    public String getMiscTypes() {

        if(ApexPages.currentPage().getParameters().get('coNum') != null) {

            String coNum = ApexPages.currentPage().getParameters().get('coNum');

            //List<Misc_Charge_Option__c> opts = [SELECT Name, Quantity__c, Rate__c, General_Ledger_Account__c
            //                                    FROM Misc_Charge_Option__c WHERE Location__r.dealer__Company_Number__c =: coNum ];
            LoadMiscChargeOptionsForLocAbbrev(coNum);	// BLL7a
			List<Misc_Charge_Option__c> opts = mcoMap.values();	// BLL7a

            System.debug(opts);

            List<cMiscOption> cOpts = new List<cMiscOption>();

            if( opts.size() > 0 ) {
                for (Misc_Charge_Option__c o : opts ) {
                    cOpts.add( new cMiscOption(o) );
                }
            }

            return JSON.serializePretty(cOpts);
        }

        /* // Deprecated to allow location nased Misc Charge options

        List<String> options = new List<String>();

        Schema.DescribeFieldResult fieldResult =
        ServiceMiscCharges__c.Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry f : ple) {
        options.add( f.getValue() );
        }

        return JSON.serializePretty(options);
        */

        //for(User a : u) {
        //  adv.writeStartObject();
        //    adv.writeStringField('text', a.FirstName+' '+a.LastName);
        //    adv.writeStringField('value', a.Id);
        //    adv.writeStringField('color', '#6eb3fa');
        //  adv.writeEndObject();
        //}
        //adv.writeEndArray();
        //return adv.getAsString();

        // Return an Emptry array as fallback.
        return '[]';
    }

    public class cMiscOption {

        String name { get;set; }
        Decimal qty { get;set; }
        Decimal rate { get;set; }
        String acct { get; set; }

        public cMiscOption(Misc_Charge_Option__c opt) {
            this.name = opt.Name;
            this.qty = opt.Quantity__c;
            this.rate = opt.Rate__c;
            this.acct = opt.General_Ledger_Account__c;
        }
    }


    /*----------------------------------------------------*/
    /*      PARTS RELATED METHODS
    /*----------------------------------------------------*/

    public String getReadParts() {
        List<PartRow> plines = new List<PartRow>();
        if(jobLineId!=null&&jobLineId!='') {
            // BLL4a add Part_type__c
            for(dealer__Parts_Invoice_Line__c p : [SELECT dealer__Parts_Invoice__c, dealer__Bin__c, dealer__Core__c, dealer__Cost__c, dealer__Counterman_No__c, dealer__Counterman__c, dealer__Currently_Available__c,dealer__Part__r.dealer__Physical_OnHand__c, dealer__Drop_Ship__c, dealer__Extended_Price__c, dealer__Gross_Margin__c, dealer__Job_Line__c, dealer__List__c, dealer__MFG__c, dealer__Net_Price__c, dealer__Net__c, dealer__Order_Type__c, dealer__Part_Description__c, dealer__Part_Number__c, dealer__Part__c, dealer__Pay_Type__c, dealer__Price_Level_Strategy__c, dealer__Price_Level__c, dealer__Price__c, dealer__Quantity_Ordered__c, dealer__Quantity_Sold__c, dealer__Sale_Date__c, dealer__Service_Job_Line_Number__c, dealer__Service_Line_Payment_Method__c, dealer__Service_Repair_Order__c, dealer__Sold_Via__c, dealer__Source__c, dealer__Stocking_Group__c, dealer__Total_Price__c, dealer__Total_Tax__c, dealer__Transaction_Code__c, Part_Master_Record__c, Currently_On_Order__c, Negative_QTY__c, Name, Id, Parts_Order__r.Name, Parts_Order__c, PO_ETA__c, PO_Tracking__c, PO_Name__c, Part_type__c FROM dealer__Parts_Invoice_Line__c where dealer__Job_Line__c =: jobLineId limit 500]) {
                plines.add(new PartRow(p));
            }
        }


        if(plines.size() > 0) return JSON.serializePretty(plines);
        else return '[]';
    }

    /**
    * getSearchParts performs an SOSL Search on the parts master for a list of parts.
    * @return String - JSON Parts List
    * @notes Jarrett Kuljis - 1/31/16 - added filter to remove obsolete parts
    */
    public String getSearchParts() {

        //BLL12d if(search.length()<2) return '';
        if (search.trim().length()<2) return '[]';	// BLL12a

        List<List<sObject>> search_results = [FIND :search IN ALL FIELDS Returning dealer__Parts_Master__c (Id, Name, dealer__Part_Description__c, dealer__Manufacturer__c, dealer__Status__c WHERE dealer__Status__c != 'Obsolete') LIMIT 25];

        List<dealer__Parts_Master__c> plines = (List<dealer__Parts_Master__c>)search_results[0];
        List<PartSearch> p_result = new List<PartSearch>();
        for(dealer__Parts_Master__c p : plines) p_result.add(new PartSearch(p));

        return JSON.serializePretty(p_result);
    }

    public class PartSearch {
        public String PartName {get;set;}
        public String PartDescription {get;set;}
        public Id PartMasterId {get;set;}
        public String PartMFG {get;set;}
        public String search_display {get;set;}
        public PartSearch(dealer__Parts_Master__c p) {
            PartMasterId    =   p.Id;
            PartName        =   p.Name;
            PartDescription =   p.dealer__Part_Description__c;
            PartMFG         =   p.dealer__Manufacturer__c;
            search_display  =   p.Name+' '+p.dealer__Part_Description__c+' '+p.dealer__Manufacturer__c;
        }
    }

    // JVK2 - Filtered out obsolete
    public String getStoreInventory() {
        List<StoreInventory> inv = new List<StoreInventory>();

        // To-Do : Add Geo Location to User

        for(dealer__Parts_Inventory__c p : [Select Id, Name, dealer__Location__c, dealer__Location__r.Name, dealer__On_Hand__c
                                            from dealer__Parts_Inventory__c
                                            where dealer__Parts_Master__c =:masterId
                                            and dealer__Location__r.Name != null
                                            and dealer__On_Hand__c > 0
                                            and ( dealer__Status__c != 'Obsolete' )
                                            order by dealer__On_Hand__c DESC
                                            limit 10])
        {
            inv.add(new StoreInventory(p.dealer__Location__r.Name, p.dealer__On_Hand__c.intValue()));
        }

        return JSON.serializePretty(inv);
    }

    public class StoreInventory {
        public String store {get;set;}
        public Integer qty {get;set;}
        public StoreInventory(String s, Integer q) {
            store   =   s;
            qty     =   q;
        }
    }

    public class PartRow {
        public Id ServiceJobId {get;set;}
        public Id Id {get;set;}
        public Id PartMasterId {get;set;}
        public Id PartInventoryId {get;set;}
        public String PartName {get;set;}
        public String PartDescription {get;set;}
        public Integer OnHand {get;set;}
        public Integer OnOrder {get;set;}
        public Decimal ListPrice {get;set;}
        public Decimal SalePrice {get;set;}
        public Integer QTY {get;set;}
        public Integer Order {get;set;}
        public Integer Negative {get;set;}
        public Decimal ExtendedTotal {get;set;}
        public String partOrderUrgency {get;set;}
        public String orderLine {get;set;}
        public String poTracking {get;set;}
        public DateTime poETA {get;set;}
        public String poName {get;set;}
        public String partType {get;set;} // BLL4a
        public Decimal PhysicalOnHand {get;set;}


        public PartRow(dealer__Parts_Invoice_Line__c p) {
            ServiceJobId    =   p.dealer__Job_Line__c;
            Id              =   p.Id;
            PartMasterId    =   p.Part_Master_Record__c;
            PartInventoryId =   p.dealer__Part__c;
            PartName        =   p.dealer__Part_Number__c;
            PartDescription =   p.dealer__Part_Description__c;
            OnHand          =   p.dealer__Currently_Available__c.intValue();
            OnOrder         =   p.Currently_On_Order__c.intValue();
            ListPrice       =   p.dealer__List__c;
            SalePrice       =   p.dealer__Price__c;
            QTY             =   p.dealer__Quantity_Sold__c.intValue();
            Order           =   p.dealer__Quantity_Ordered__c.intValue();
            Negative        =   p.Negative_QTY__c.intValue();
            ExtendedTotal   =   p.dealer__Extended_Price__c;
            partOrderUrgency=   p.dealer__Order_Type__c;
            orderLine       =   p.Parts_Order__r.Name;
            poETA           =   p.PO_ETA__c;
            poTRacking      =   p.PO_Tracking__c;
            poName          =   p.PO_Name__c;
            partType        =   (p.Part_type__c==null) ? 'N' : p.Part_type__c; // BLL4a

            if(partOrderUrgency==null) {
                partOrderUrgency='';
            }

            if(orderLine==null) {
                orderLine='';
            }

            if(partType==null) partType = 'N'; // BLL4a

            if(p.dealer__Part__r != null && p.dealer__Part__r.dealer__Physical_OnHand__c != null) {
                PhysicalOnHand = p.dealer__Part__r.dealer__Physical_OnHand__c;
            }
        }
    }


    public String lookupPart() {

        /*
        Get the Part searched by Dialog belonging to the company number assigned to the individual
        If no part exists in that stores inventory clone from the Master and Create
        */

        // DR2 added dealer__Physical_OnHand__c
        dealer__Parts_Inventory__c[] p = [SELECT dealer__Best_Stocking_Level__c, dealer__Bin_2__c, dealer__Bin__c, dealer__Comments__c,
                                          dealer__Comp__c, dealer__Company_Number__c, dealer__Core__c, dealer__Cost__c, dealer__Description__c,
                                          dealer__Detail__c, dealer__Entry_Date__c, dealer__Extended_Description__c, dealer__Extra_Days__c,
                                          dealer__Gross_Margin__c, dealer__Group__c, dealer__High_Days__c, dealer__High_Year__c,
                                          dealer__Illustration__c, dealer__Jobber__c, dealer__Kit__c, dealer__Last_Sale_Date__c, dealer__List__c,
                                          dealer__Low_Days__c, dealer__Low_Year__c, dealer__MFG__c, dealer__Max__c, dealer__Min__c,
                                          dealer__Minimum_Margin__c, dealer__On_Back_Order__c, dealer__On_Hand__c, dealer__On_Order__c,
                                          dealer__On_Special_Order__c, dealer__Online_Store_Id__c, dealer__PNC__c, dealer__Pack_QTY__c,
                                          dealer__Part_No__c, dealer__Parts_Master__c, dealer__Price_Update__c, dealer__Raw_Part_Number__c,
                                          dealer__Re_Order_Point__c, dealer__Remarks__c, dealer__Reserved__c, dealer__Return_Code__c,
                                          dealer__Source_List__c, dealer__Source__c, dealer__Static_Price__c, dealer__Status__c,
                                          dealer__Stocking_Group__c, dealer__Tax_Exempt__c, dealer__Trade__c, dealer__UPC__c, dealer__Warranty__c,
                                          dealer__Weight__c, dealer__Location__c, dealer__Part_Number__c, Id, Name, dealer__Physical_OnHand__c
                                          FROM dealer__Parts_Inventory__c
                                          where dealer__Parts_Master__c =:masterId
                                          and dealer__Location__c=:locationId
                                          limit 1];

        if(p.size()==0) {
            // Add new Part to Location Based on Search from Master
            dealer__Parts_Master__c pm = [SELECT dealer__Applications__c, dealer__Core_Required__c, dealer__Core_Value__c, dealer__Cost__c, dealer__Height__c, dealer__Jobber_Price__c, dealer__Labor_Time__c, dealer__Length__c, dealer__MAP__c, dealer__MFG_Comments__c, dealer__Manufacturer__c, dealer__Pack_QTY__c, dealer__Part_Description__c, dealer__Part_No_Display__c, dealer__Part_No__c, dealer__Price_Tape_Date__c, dealer__Raw_Part_Number__c, dealer__Retail_Price__c, dealer__Return_Code__c, dealer__UPC__c, dealer__Warranty_Price__c, dealer__Weight__c, dealer__Width__c, dealer__Catalog_Image__c, Id, Name FROM dealer__Parts_Master__c where Id=:masterId limit 1];

            dealer__Parts_Inventory__c newP = new dealer__Parts_Inventory__c(
                dealer__Parts_Master__c=pm.Id,
                dealer__Location__c=locationId,
                dealer__Part_No__c=pm.dealer__Part_No__c,
                dealer__Description__c=pm.dealer__Part_Description__c,
                dealer__MFG__c=pm.dealer__Manufacturer__c,
                dealer__Cost__c=pm.dealer__Cost__c,
                dealer__List__c=pm.dealer__Retail_Price__c,
                dealer__Pack_QTY__c=pm.dealer__Pack_QTY__c
            );
            try{
                insert newP;
            }catch(DMLException e){
                return '{ "error" : "'+e.getMessage()+'" }';
            }
            Id prtId = newP.Id;
            // DR2 added dealer__Physical_OnHand__c
            newp = [SELECT dealer__Best_Stocking_Level__c, dealer__Bin_2__c, dealer__Bin__c, dealer__Comments__c, dealer__Comp__c, dealer__Company_Number__c, dealer__Core__c, dealer__Cost__c, dealer__Description__c, dealer__Detail__c, dealer__Entry_Date__c, dealer__Extended_Description__c, dealer__Extra_Days__c, dealer__Gross_Margin__c, dealer__Group__c, dealer__High_Days__c, dealer__High_Year__c, dealer__Illustration__c, dealer__Jobber__c, dealer__Kit__c, dealer__Last_Sale_Date__c, dealer__List__c, dealer__Low_Days__c, dealer__Low_Year__c, dealer__MFG__c, dealer__Max__c, dealer__Min__c, dealer__Minimum_Margin__c, dealer__On_Back_Order__c, dealer__On_Hand__c, dealer__On_Order__c, dealer__On_Special_Order__c, dealer__Online_Store_Id__c, dealer__PNC__c, dealer__Pack_QTY__c, dealer__Part_No__c, dealer__Parts_Master__c, dealer__Price_Update__c, dealer__Raw_Part_Number__c, dealer__Re_Order_Point__c, dealer__Remarks__c, dealer__Reserved__c, dealer__Return_Code__c, dealer__Source_List__c, dealer__Source__c, dealer__Static_Price__c, dealer__Status__c, dealer__Stocking_Group__c, dealer__Tax_Exempt__c, dealer__Trade__c, dealer__UPC__c, dealer__Warranty__c, dealer__Weight__c, dealer__Location__c, dealer__Part_Number__c, Id, Name, dealer__Physical_OnHand__c FROM dealer__Parts_Inventory__c where Id=:prtId limit 1];

            p.clear();
            p.add(newP);
        }

        if(p[0].dealer__Status__c != null && (p[0].dealer__Status__c == 'Obsolete w/ Inventory' || p[0].dealer__Status__c == 'Active')) {
            return JSON.serializePretty(new PartRowInventory(p[0]));
        }

        return null;
    }

    //RT6
    public void laborRateRecalculation(Id jobLineId, dealer__Service_Job__c j) {
		System.debug('laborRateRecalculation');
		System.debug(j);
        dealer__Service_Job__c jobline = [
			Select Id, Name, Payment_Method__c, Payment_Method__r.Shop_Supplies_Rate__c, Payment_Method__r.Default_Labor_Rate__c,dealer__Labor_Type__c,//SU1 - Added Labor Type field
				Payment_Method__r.Hazmat_Fee__c, dealer__Service_Repair_Order__r.dealer__Company__r.dealer__State__c, dealer__Service_Repair_Order__r.dealer__Company__c, dealer__Service_Repair_Order__r.Shop_Supplies_Charges__c, dealer__Misc_Charges__c,
				dealer__Actual_Time__c,dealer__Book_Time__c, dealer__Labor_Charges__c, dealer__Technician_Cost__c,
				dealer__CustomerConcern__c, dealer__CauseExtended__c, dealer__Cause__c, dealer__Correction__c, dealer__Standard_Operation_Code__c, dealer__Stat__c
			FROM dealer__Service_Job__c WHERE Id=:jobLineId
			LIMIT 1
		];
		System.debug('@@Jobline>>'+jobline);
                                          
    	ServicePaymentType__c spt = [Select id, name, Shop_Supplies_Rate__c, Default_Labor_Rate__c, Hazmat_Fee__c from ServicePaymentType__c where id = :String.valueOf(urlParameters.get('Payment_Method__c'))]; 
    	jobline.dealer__Labor_Type__c = j.dealer__Labor_Type__c;
    	jobline.Payment_Method__c = String.valueOf(urlParameters.get('Payment_Method__c'));

    	// Deconstruct payload to update the respective row
        jobline.dealer__CustomerConcern__c = String.valueOf(urlParameters.get('dealer__CustomerConcern__c'));
        if(String.valueOf(urlParameters.get('dealer__CauseExtended__c'))!=null) {
            jobline.dealer__Cause__c   = String.valueOf(urlParameters.get('dealer__CauseExtended__c')).abbreviate(250); // DR1
        }
        jobline.dealer__CauseExtended__c   = String.valueOf(urlParameters.get('dealer__CauseExtended__c'));
        jobline.dealer__Correction__c = String.valueOf(urlParameters.get('dealer__Correction__c'));
        jobline.dealer__Standard_Operation_Code__c = String.valueOf(urlParameters.get('dealer__Standard_Operation_Code__c'));
        jobline.dealer__Stat__c = String.valueOf(urlParameters.get('dealer__Stat__c'));

    
    	system.debug('@@Jobline>>'+jobline);
    
        // BLL8a
        List<ServicePaymentType__c> payType = [
        	SELECT Id, Default_Labor_Rate__c, 
        		   (SELECT Labor_Rate__c 
        			FROM LaborRateDefaults__r 
        			WHERE Location__c =:jobline.dealer__Service_Repair_Order__r.dealer__Company__c) defRate 
        		FROM ServicePaymentType__c 
        		WHERE Id =: jobLine.Payment_Method__c
        ];

        //update tech time and associated misc charges
        List<dealer__Technician_Job_Time__c> tts = [
        	SELECT Id,dealer__Service_Job_Line__c, Payment_Method_Labor_Rate__c ,dealer__Actual_Time_Entry__c, Labor_Total__c, 
        				(SELECT Id FROM Service_Misc_Charge__r)
			FROM dealer__Technician_Job_Time__c
			WHERE dealer__Service_Job_Line__c=:jobLine.Id
		];

        List<ServiceMiscCharges__c> hazmatCharge = [SELECT Id, Service_Job_Line__c FROM ServiceMiscCharges__c WHERE Service_Job_Line__c = :jobline.Id];
        // BLL7d Misc_Charge_Option__c[] hazmatMisc = [SELECT Id,Name, General_Ledger_Acct_MW__c, General_Ledger_Acct_MW__r.GeneralLedgerAccountFF__c, General_Ledger_Account__c,Quantity__c,Rate__c FROM Misc_Charge_Option__c WHERE Name LIKE 'Hazardous Materials' AND Location__c =: jobline.dealer__Service_Repair_Order__r.dealer__Company__c LIMIT 1];
        // BLL7d Misc_Charge_Option__c[] shopMisc = [SELECT Id,Name, General_Ledger_Acct_MW__c, General_Ledger_Acct_MW__r.GeneralLedgerAccountFF__c, General_Ledger_Account__c, Quantity__c,Rate__c FROM Misc_Charge_Option__c WHERE Name LIKE 'Shop Supplies' AND Location__c =: jobline.dealer__Service_Repair_Order__r.dealer__Company__c LIMIT 1];
        // BLL7a
		LoadMiscChargeOptionsForLocId(jobline.dealer__Service_Repair_Order__r.dealer__Company__c);
//        Misc_Charge_Option__c hazmatMisc = mcoMap.get('Hazardous Materials');
//        Misc_Charge_Option__c shopMisc = mcoMap.get('Shop Supplies');
        // BLL7a

        List<ServiceMiscCharges__c> miscLines = new List<ServiceMiscCharges__c>();
        List<ServiceMiscCharges__c> currMiscLines = new List<ServiceMiscCharges__c>();

		Decimal laborrate = spt.Default_Labor_Rate__c;
		// BLL8a - don't forget store override rates!
		if( payType.size()>0 && payType[0].LaborRateDefaults__r.size() > 0 ) 
			laborrate = payType[0].LaborRateDefaults__r[0].Labor_Rate__c;
		if (laborrate == null) laborrate = 0.00;
		// BLL8a end
		System.debug(payType);
		System.debug(laborrate);

        for(dealer__Technician_Job_Time__c tt : tts){
            Decimal laborOg = tt.Labor_Total__c;
			tt.Payment_Method_Labor_Rate__c = laborrate;	// BLL22

            // Calculeate labor total
            if(tt.Payment_Method_Labor_Rate__c == null) { tt.Payment_Method_Labor_Rate__c = 0; }
            tt.Labor_Total__c = tt.Payment_Method_Labor_Rate__c * tt.dealer__Actual_Time_Entry__c;
            tt.Labor_Total__c = tt.Labor_Total__c.setScale(2, System.RoundingMode.HALF_UP); // BLL6a
            if(tt.Labor_Total__c != laborOg) {

                // Process original Job Line before re-assigning

                // delete lines related to the original job line
                //List<ServiceMiscCharges__c> currMiscLines = [Select Id from ServiceMiscCharges__c where Technician_Job_Time_Creator__c =: tt.Id Limit 500];
                if(tt.Service_Misc_Charge__r.size()>0){
                    System.debug('DELETE');
                    currMiscLines.add(tt.Service_Misc_Charge__r);
                    //Delete currMiscLines;

                    // re-total lines on Original Job Line
                    //lineTotalMisc( tt.dealer__Service_Job_Line__c );
                }

                // ** Set the Job Line to the new Line Id. **
                if(urlParameters.get('newLineId') != null){
                    tt.dealer__Service_Job_Line__c = String.valueOf(urlParameters.get('newLineId'));
                }
                //RT1 hazmat also needs to check if in CA
                if(spt.Hazmat_Fee__c!=null && spt.Hazmat_Fee__c!=0 && jobline.dealer__Service_Repair_Order__r.dealer__Company__r.dealer__State__c != 'CA') {
                    if(hazmatCharge.size() == 0) { //RT1 Only one hazmat charge per line
                        System.debug(jobline.dealer__Service_Repair_Order__r.dealer__Company__c);

                        //TODO: Select MISC OPtions Item From Database and get account is type equals HAZMAT
                        //RT1

                        // BLL7d if(hazmatMisc.size()>0) {
                        //if (hazmatMisc!=null) {	// BLL7a
                            // stuff

							System.debug('Create hazmat misc chg');	// BLL17a
							autoCreateMiscCharge(miscLines, jobline.Id, tt.Id, 'Hazardous Materials', null);	// BLL17a
                            // Add Misc Line
//BLL17d
//                            miscLines.add(new ServiceMiscCharges__c(
//                                Service_Job_Line__c     =   jobline.Id,
//                                Type__c                 =   hazmatMisc.Name,
//                                General_Ledger_Acct_MW__c = hazmatMisc.General_Ledger_Acct_MW__c,
//                                General_Ledger_Account__c = hazmatMisc.General_Ledger_Acct_MW__r.GeneralLedgerAccountFF__c,
//                                Quantity__c             =   hazmatMisc.Quantity__c,
//                                Amount__c               =   hazmatMisc.Rate__c.setScale(2, System.RoundingMode.HALF_UP),  //JVK - Rounding Issue (1/27/2016),
//                                Technician_Job_Time_Creator__c = tt.Id
//                            ));

                        //} else {
                        //    throw new ROException('Misc. Charge Type of "Hazardous Materials" has not been configured for this location.');
                        //    //return '{"error":\'Misc. Charge Type of "Hazardous Materials" has not been configured for this location.\'}';
                        //}
                    }

                }

                // add misc Supplies line if applicable
                if(spt.Shop_Supplies_Rate__c!=null&&spt.Shop_Supplies_Rate__c!=0) {
                    // Labor Charges times Rate
                    Decimal shop_supplies = tt.Labor_Total__c * (spt.Shop_Supplies_Rate__c / 100);
                    shop_supplies = shop_supplies.setScale(2, System.RoundingMode.HALF_UP); // BLL6a

                    // Check to see if we are in CA
                    //TODO: Select MISC Item From Database and get account is type equals HAZMAT
                    if(jobline.dealer__Service_Repair_Order__r.dealer__Company__r.dealer__State__c != 'CA' && jobline.dealer__Service_Repair_Order__r.Shop_Supplies_Charges__c < 25.00) {
                        //RT1
                        if(shop_supplies + jobline.dealer__Service_Repair_Order__r.Shop_Supplies_Charges__c > 25.00) {
                            shop_supplies = 25 - jobline.dealer__Service_Repair_Order__r.Shop_Supplies_Charges__c;
                        }
                        // BLL7d if(shopMisc.size()>0) {
                        //if (shopMisc!=null) {	// BLL7a
                            // stuff
                            //System.debug('****** MISC: ' + misc[0]);

                            // Add Misc Line
							autoCreateMiscCharge(miscLines, jobline.Id, tt.Id, 'Shop Supplies', shop_supplies);	// BLL17a
//BLL17d
//                            miscLines.add(new ServiceMiscCharges__c(
//                                Service_Job_Line__c     =   jobline.Id,
//                                Type__c                 =   shopMisc.Name,
//                                General_Ledger_Acct_MW__c = shopMisc.General_Ledger_Acct_MW__c,
//                                General_Ledger_Account__c = shopMisc.General_Ledger_Acct_MW__r.GeneralLedgerAccountFF__c,
//                                Quantity__c             =   shopMisc.Quantity__c,
//                                Amount__c               =   shop_supplies.setScale(2, System.RoundingMode.HALF_UP),
//                                Technician_Job_Time_Creator__c = tt.Id,
//                                Tech_Time_Charge__c = true
//							));

                        //} else {
                        //    throw new ROException('Misc. Charge Type of "Shop Supplies" has not been configured for this location.');
                        //    //return '{"error":\'Misc. Charge Type of "Hazardous Materials" has not been configured for this location.\'}';
                        //}
                    }
                }
            }
        }

        update tts;

        if(currMiscLines.size() > 0) delete currMiscLines;
        // System.debug(miscLines);
        if(miscLines.size()>0) insert miscLines;

        AggregateResult[] sumLine = [Select SUM(Amount__c) line
                                     FROM ServiceMiscCharges__c
                                     where Service_Job_Line__c =:jobLine.Id];

        AggregateResult[] sumTime = [Select SUM(dealer__Actual_Time_Entry__c) time,
                                     SUM(Labor_Total__c) lineTotal,
                                     SUM(Labor_Cost__c) lineCost
                                     FROM dealer__Technician_Job_Time__c
                                     Where dealer__Service_Job_Line__c=:jobLine.Id];

        Decimal sumLabor = (decimal) sumLine[0].get('line');
        if(sumLabor==null) { sumLabor = 0; }
        jobline.dealer__Misc_Charges__c = sumLabor.setScale(2, System.RoundingMode.HALF_UP);
        jobline.dealer__Actual_Time__c  = (Decimal)sumTime[0].get('time');
        // BLL22
		if (location==null && roId!=null) {
			location = [select Id, Name, dealer__State__c, LaborBookEqualsActualTime__c from dealer__Dealer_Location__c where Id=:jobline.dealer__Service_Repair_Order__r.dealer__Company__c limit 1];
		}
		//jobLine.dealer__Book_Time__c    = (Decimal)sumTime[0].get('time');
		if (location.LaborBookEqualsActualTime__c) {
			jobline.dealer__Book_Time__c    = (Decimal)sumTime[0].get('time');
			jobline.dealer__Labor_Charges__c= (Decimal)sumTime[0].get('lineTotal');
			System.debug('dealer__Labor_Charges__c=' + String.valueOf(jobLine.dealer__Labor_Charges__c));
		}
		jobline.dealer__Labor_Charges__c = jobLine.dealer__Book_Time__c==null ? null : jobLine.dealer__Book_Time__c * laborrate;
		System.debug('dealer__Labor_Charges__c=' + String.valueOf(jobLine.dealer__Labor_Charges__c));

		// BLL22 end
        //jobLine.dealer__Labor_Charges__c= (Decimal)sumTime[0].get('lineTotal');
        jobline.dealer__Technician_Cost__c = (Decimal)sumTime[0].get('lineCost');

        //update part totals
        List<dealer__Parts_Invoice_Line__c> partLines = [SELECT Id, dealer__Price__c, dealer__Quantity_Sold__c, dealer__Part__r.dealer__Cost__c, dealer__Part__r.dealer__List__c FROM dealer__Parts_Invoice_Line__c WHERE dealer__Job_Line__c = :jobLine.id];

        // Quantity not taken into consideration :/
        // JVK10 - added multiplication of quantity sold
        for(dealer__Parts_Invoice_Line__c partLine : partLines) {
            System.debug('**************'+jobLine.dealer__Labor_Type__c);
            partLine.dealer__Pay_Type__c  = jobLine.dealer__Labor_Type__c;
            if(jobLine.dealer__Labor_Type__c == 'W' || jobLine.dealer__Labor_Type__c == 'I') {
                partLine.dealer__Price__c = partLine.dealer__Part__r.dealer__Cost__c;
            }
            else {
                partLine.dealer__Price__c = partLine.dealer__Part__r.dealer__List__c;
            }
        }
        
        System.debug(partLines);
        update partLines;

        //lineTotalParts(jobLine.Id);
        //adding method code here itself - Not using function
        System.debug('jobLine 3>>'+jobLine);
        //BLL11d SavePoint spk = Database.setSavepoint(); //JVK12

        // JVK4 (remove SUM(Extended_Cost__c) replace SUM(dealer__Cost__c)), SUM(dealer__Price__c)
        AggregateResult[] sumLine2 = [Select SUM(dealer__Extended_Price__c) line, SUM(dealer__Cost__c) cost
                                     FROM  dealer__Parts_Invoice_Line__c
                                     where dealer__Job_Line__c =:jobline.Id];
        if(sumLine2.size() > 0) {


            Decimal sum = (decimal) sumLine2[0].get('line');
            Decimal cost = (decimal) sumLine2[0].get('cost');
            jobline.dealer__Parts_Total__c = sum;
            jobline.dealer__Parts_Cost__c = cost;
        }

		ServiceProcess.ReloadROLines=true;

        //BLL11d try {
            update jobline;
            System.debug('Job Line Update - lineTotalParts');
            System.debug('jobLine  4 >>'+jobLine);
        //BLL11d } Catch(DmlException e) {
        //BLL11d     Database.rollback(spk);
        //BLL11d }        
		// reflect changes to parameter job line
		j.dealer__Labor_Charges__c = jobLine.dealer__Labor_Charges__c;
		System.debug('dealer__Labor_Charges__c=' + String.valueOf(j.dealer__Labor_Charges__c));
		j.dealer__Labor_Type__c = jobLine.dealer__Labor_Type__c;
		if (jobline.Payment_Method__c!=null) j.Payment_Method__c = jobline.Payment_Method__c;
    }

    public class PartRowInventory {
        public Id ServiceJobId {get;set;}
        public Id Id {get;set;}
        public Id PartMasterId {get;set;}
        public Id PartInventoryId {get;set;}
        public String PartName {get;set;}
        public String PartDescription {get;set;}
        public Integer OnHand {get;set;}
        public Integer OnOrder {get;set;}
        public Decimal ListPrice {get;set;}
        public Decimal SalePrice {get;set;}
        public Integer QTY {get;set;}
        public Integer Order {get;set;}
        public Integer Negative {get;set;}
        public Decimal ExtendedTotal {get;set;}
        public Decimal Cost {get;set;} //RT2
        public Decimal PhysicalOnHand {get;set;} //DR2

        public PartRowInventory(dealer__Parts_Inventory__c p) {

            if(p.dealer__On_Hand__c==null) p.dealer__On_Hand__c=0;

            if(p.dealer__On_Order__c==null) p.dealer__On_Order__c=0;

            ServiceJobId    =   null;
            Id              =   null;
            PartMasterId    =   p.dealer__Parts_Master__c;
            PartInventoryId =   p.Id;
            PartName        =   p.Name;
            PartDescription =   p.dealer__Description__c;
            OnHand          =   p.dealer__On_Hand__c.intValue();
            OnOrder         =   p.dealer__On_Order__c.intValue();
            ListPrice       =   p.dealer__List__c;
            QTY             =   1;
            Order           =   0;
            Negative        =   0;

            SalePrice = p.dealer__List__c;
            if(p.dealer__Static_Price__c!=null && p.dealer__Static_Price__c!=0) SalePrice=p.dealer__Static_Price__c;

            Cost = p.dealer__Cost__c; //RT2

            PhysicalOnHand = p.dealer__Physical_OnHand__c; // DR2

            ExtendedTotal   =   (SalePrice * QTY);
            ExtendedTotal = ExtendedTotal.setScale(2, System.RoundingMode.HALF_UP); // BLL6a
        }
    }

    public class ROException extends Exception{}
}