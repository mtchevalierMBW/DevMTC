/**
 * SalesUpTriggerHandler
 * Tested by: SalesUpMBW_TC
 * 
 * Functions:
 *  - when status changes to "Lost", prevent update if any associated deals are "Won", update any "Pending" deals to "Lost"
 *  - default Company (AKR, OAK, etc) to user's division if missing from record
 *  - set company number (AKR, OAK, etc) from specified location record id
 *  - enforce only 1 open (not won/lost) chassis solution opportunity per customer (currently includes co-buyer in this restriction)
 *  - enforce account and co-buyer account cannot be a vendor or 3rd party payor
 *  - set BDC Created flag and CCC rep name when created by the BDC
 *  - update person account or account contact info from this record (source, phones, email, address) (only if single-record update!)
 *  - Change related open tasks and appointments if CMC1 is changed
 *  - fill in account and owner if upload_Account and/or upload_Owner are provided (and function is enabled via MW Trigger Controls settings)
 * 
 * Coverage:
 *  2018-10-18  82% (242/292)
 *	2019-04-25	83%	(252/301)
 *
 * Modifications:
 * 2015-06-22   B. Leaman   Change to Update contact instead of person account fields if it's not a person account.
 * 2015-06-30   B. Leaman   BLL2 Add code to save BDC Rep name when created by the BDC.
 * 2015-07-16   B. Leaman   BLL3 Don't replace solution opportunity name if it's already specified.
 * 2015-07-17   B. Leaman   BLL4 Only 1 open chassis solution opportunity per account at a time.
 * 2015-08-05   B. Leaman   BLL5 No vendors or 3rdParty for customer or cobuyer.
 * 2015-08-10   J. Kuljis   JVK1 Set the Company Field (Lookup vs. txt3) based on end users selected location
 * 2015-08-13   B. Leaman   BLL6 reduce queries if default location not needed
 * 2015-09-02   B. Leaman   BLL7 - fix SO name
 * 2015-09-28   B. Leaman   BLL8 - if not authorized to update contact or account, don't blow up. Also, only update
 *                          contact info (contact or person account) if it changed.
 * 2015-12-1    RedTeal     RT1 - If the CMC1 (Salesperson_1) of the solution opportunity changes, all open tasks and
 *                                sales appointments will also change. 
 * 2015-10-23   B. Leaman   BLL9 - if marked lost, update pending proposals to lost. Don't allow if proposal is won.
 * 2015-11-05   B. Leaman   BLL10 - Keep company number and company in sync (company drives company number)
 * 2015-12-10   B. Leaman   BLL11 - support for upload_Account and upload_Owner fields.
 *                          Also add upload_BDC__c field for bdc rep to dealer__CCC_Rep__c & default to bdc manager.
 * 2015-12-31   B. Leaman   BLL12 - Change YYYY to yyyy on naming solution opp.
 * 2016-01-11   B. Leaman   BLL13 - Only update task owner & sales appt assignee if it has changed.
 * 2016-01-12   B. Leaman   BLL14 - Implement setting to disable update of account/contact info from Sol Opp.
 * NOTE: Can probably just remove all code being skipped due to BLL14 setting set to not enabled. It seems
 *       the updates are occuring elsewhere (DealerTeam managed package?)
 * 2016-02-21   B. Leaman   BLL15 - Lost solution opportunity logic for commercial quotes.
 * 2016-03-07   B. Leaman   BLL16 - Only update tasks owned by the OLD owner - leave others alone!
 * 2016-03-15   RedTeal     RT2   - Moved logic out of SalesUpMBWContact trigger to this handler class. 
 * 2016-04-06   B. Leaman   BLL17 IT#17570 - Set salesperson 1 along with owner from upload_Owner__c.
 * 2016-07-29   B. Leaman   BLL18 Use CurrentUserSingleton instead of SOQL.
 * 2016-12-05   B. Leaman   BLL19 Don't allow marking 'Won' unless there is a Won proposal.
 * 2017-01-02   B. Leaman   BLL20 Condition quote/deal validations.
 * 2017-01-16   B. Leaman   BLL21 IR-0006054 Rental and service solution opportunities can be "Won" without a proposal.
 * 2017-02-13   B. Leaman   BLL22 - Allow multiple chassis solution opportunities for commercial customers (and commercial solution opps).
 * 2017-05-07   B. Leaman   BLL23 - Conditionally update solution opp name to standard SO: acct_name yyyy-mm format.
 * 2017-04-27   B. Leaman   BLL24 - check solopp record type id for open retail chassis count.
 * 2017-07-11   B. Leaman   BLL25 - Eliminate simple workflows (don't use workflow because it causes triggers to run twice)
 * 2018-01-26   B. Leaman   BLL26 - New custom settings for BDC so individual can override settings.
 * 2018-05-07   B. Leaman   BLL27 - Record pardot score from contact (prospect) when solution opp is created and when won or lost.
 * 2018-10-18   B. Leaman   BLL28 - Improve efficiency with location singleton
 * 2019-04-25	B. Leaman	W-000662 BLL29 - fix loopholes in solution opportunity status & status change date!
 * 2019-07-19	B. Leaman	W-000720 BLL30 - copy GCLID__c (Google click Id) from contact.
 * 2019-08-16	B. Leaman	W-000738 BLL31 - Price_point__c support
 */
public with sharing class SalesUpTriggerHandler {
    public static boolean allowTrigger = true;


    public static Map<String, Schema.RecordTypeInfo> SlopRcdTypes = Schema.SObjectType.dealer__Sales_Up__c.getRecordTypeInfosByName();  // BLL22a (moved later)

    public static void afterUpdateHandler(List<dealer__Sales_Up__c> newList, Map<Id, dealer__Sales_Up__c> newMap, Map<Id, dealer__Sales_Up__c> oldMap, Integer size) {
        

        markProposalsLost(newList, newMap, oldMap);
        updateSalesAppointments(newList, newMap, oldMap);
        if(size == 1) {
            updateContactInformation(newList, newMap, oldMap);
        }

    }

    public static void beforeHandler(List<dealer__Sales_Up__c> newList, Map<Id, dealer__Sales_Up__c> newMap, Map<Id, dealer__Sales_Up__c> oldMap, Boolean isInsert) {
 
        MW_TriggerControls__c uploadHelper = MW_TriggerControls__c.getInstance('upload_SalesUp_Helper'); // BLL11a
        MW_TriggerControls__c OpenChassis = MW_TriggerControls__c.getInstance('Solution_Opp_Open_Chassis'); // BLL4a
        MW_BDC_Settings__c bdcSettings = MW_BDC_Settings__c.getInstance();  // BLL26a

        // BLL22a
        Schema.RecordTypeInfo CommSlopRtInfo = SlopRcdTypes.get('Commercial');
        Id CommSlopId = CommSlopRtInfo!=null ? CommSlopRtInfo.getRecordTypeId() : null;
        // BLL22a

        //BLL26d Id pId = userInfo.getProfileId(); // BLL2a
        //BLL26d Profile p = [select Id, Name from Profile where Id=:pId]; // BLL2a
        
        Id defaultLocId = null; // JVK1
        User u = null; // BLL6a - and moved retrieval of default location
        u = CurrentUserSingleton.getInstance(); // BLL28a
        Set<Id> includedLocIds = new Set<Id>();  // BLL10a 

        Set<Id> includedAccounts = new Set<Id>();
        Set<Id> includedContacts = new Set<Id>(); // BLL3a
        Set<Id> includedSolOpps = new Set<Id>();  // BLL4a
        List<String> usernames = new List<String>();  // BLL11a
        List<String> accountcds = new List<String>(); // BLL11a
    
        // collect lists of ids, upload strings, etc. needed to run queries in bulk
        for(dealer__Sales_Up__c s : newList) {

            // BLL22a
            if (s.BuyerContact__c==null) s.BuyerContact__c = s.dealer__Buyer_Contact__c;
            if (s.dealer__Buyer_Contact__c!=s.BuyerContact__c) s.dealer__Buyer_Contact__c = s.BuyerContact__c;
            // BLL22a end
                        
            // BLL11a - list of owners and accounts
            if (uploadHelper==null || uploadHelper.Enabled__c || Test.isRunningTest()) {
                String o = s.upload_Owner__c;
                if (!String.isBlank(o)) {
                    usernames.add(o);
                }
                //System.debug(usernames);
                String ref = s.upload_Account__c;
                if (!String.isBlank(ref)) {
                    accountcds.add(ref);
                }
                String rep = s.upload_BDC__c;
                if (!String.isBlank(rep)) {
                    usernames.add(rep);
                }
            }
            // BLL11a end
            
            if(s.dealer__Customer_Account__c!=null) includedAccounts.add(s.dealer__Customer_Account__c);
            //BLL4a
            if (s.dealer__Co_Buyer__c!=null) includedAccounts.add(s.dealer__Co_Buyer__c);
            //BLL4a end
            // BLL3a
            if(s.dealer__Buyer_Contact__c!=null) includedContacts.add(s.dealer__Buyer_Contact__c);
            // BLL3a end
            // BLL4a - list of included solution opportunities
            if (s.Id!=null) includedSolOpps.add(s.Id);
            // BLL4a - end 

            // BL28d - moved logic to improve efficiency
            // assign default store location (if missing)
            //if(s.Company__c == null) {
            //    // BLL6a - moved code here to run only if needed & only run once
            //    if (u==null) {
            //       //BLL18d u = [Select Id, Division from User where Id=:UserInfo.getUserId() limit 1]; //JVK1
            //       u = CurrentUserSingleton.getInstance();  // BLL18a
            //       if (u != null && u.Division != null) {
            //           List<dealer__Dealer_Location__c> loc = [select Id from dealer__Dealer_Location__c where dealer__Company_Number__c=:u.Division];
            //           if (loc.size()>0) { defaultLocId = loc[0].Id; }
            //       } // JVK1 - End      
            //    }
            //    s.Company__c = defaultLocId; 
            //} // JVK1 

            // BLL10a
            //if (s.Company__c!=null) includedLocIds.add(s.Company__c);
            // BLL10a end
            // BLL28d end
            
        }

        // Bulk queries ...
        Map<Id, Account> accounts = new Map<Id, Account>([Select Id, Name, FirstName, LastName, PersonContactId, isPersonAccount, RecordType.Name, Price_point__c, Price_point__pc from Account where Id IN:includedAccounts limit 2000]);	// BLL31c
        // BLL31
		//Map<Id, Contact> contacts = new Map<Id, Contact>([Select Id, FirstName, LastName, pi__score__c from Contact where Id IN :includedContacts limit 2000]); // BLL27c add pi__score__c
		Map<Id, Contact> contacts = new Map<Id, Contact>([
			Select Id, FirstName, LastName, pi__score__c, GCLID__c, Price_point__c	// BLL31c
			from Contact 
			where Id IN :includedContacts limit 2000
		]); // BLL27c add pi__score__c
		System.debug(contacts);
		// BLL31 end
        //BLL28d Map<Id, dealer__Dealer_Location__c> locations = new Map<Id,dealer__Dealer_Location__c>([select Id, dealer__Company_Number__c from dealer__Dealer_Location__c where Id in :includedLocIds]); // BLL10a
        // BLL28a
        LocationsSingleton ls = LocationsSingleton.getInstance();
        ls.addLocationIds(includedLocIds);
        ls.addLocationAbbrevs(new List<String>{u.Division});
        // BLL28a end

        // BLL4a - Which accounts (used by this list of SolOpps) have open Chassis Solution Opportunities NOT in this list?
        Map<Id, Integer> opensolopp = new Map<Id, Integer>();
        if (OpenChassis==null || OpenChassis.Enabled__c || Test.isRunningTest()) {
            for(AggregateResult rs : [
                     select dealer__Customer_Account__c, count(Id) nbr 
                     from dealer__Sales_Up__c 
                     where dealer__Customer_Account__c in :includedAccounts
                       and Id NOT in :includedSolopps
                       and dealer__Lead_Status__c NOT in ('Won', 'Lost')
                       and Solution_Type__c like 'Chassis%'
                       and RecordType.Name!='Commercial'    // BLL22a
                     group by dealer__Customer_Account__c
                 ]) {
                 opensolopp.put((Id) rs.get('dealer__Customer_Account__c'), (Integer) rs.get('nbr'));   
            }
            System.debug('Open chassis solOpp counts...');
            System.debug(opensolopp);
        }
        // BLL4a - end

        // BLL11a - create maps of owners and accounts
        Map<String, Id> usermap = new Map<String, Id>();
        Map<String, Account> acctmap = new Map<String, Account>();
        Map<Id, Id> acctStoreMap = new Map<Id, Id>();
        List<Id> storelocs = new List<Id>();
        Map<Id, Id> storegm = new Map<Id, Id>();

        if (uploadHelper==null || uploadHelper.Enabled__c==true) {
            // generate Map to users by Id
            if (usernames.size()>0) {
                for(User us: [select Id, Name, isActive From User
                             where Name in :usernames and isActive=true ]) {
                usermap.put(us.Name.toLowerCase(), us.Id);
                } // end for User
            }
            
            // generate Map to accounts by dealer__External_ID__c and list of locations for the accounts
            if (accountcds.size()>0) {
                for(Account a: [select Id, Name, dealer__External_ID__c, Store_Location__c, isPersonAccount, PersonContactId 
                             From Account
                             where dealer__External_ID__c in :accountcds ]) {
                    acctmap.put(a.dealer__External_ID__c, a);
                    if (a.Store_Location__c != null) {
                        storelocs.add(a.Store_Location__c);
                        acctStoreMap.put(a.Id, a.Store_Location__c);
                        System.debug('Account id=' + a.Id + ', externalid=' + a.dealer__External_ID__c + ', store id=' + a.Store_Location__c);
                    } 
                }
            }
            // generate Map to General Managers by Location Id
            if (storelocs.size()>0) {
                ls.addLocationIds(storelocs);
                // BLL28d
                //for(dealer__Dealer_Location__c loc : [select Id, Name, dealer__General_Manager__c
                //              from dealer__Dealer_Location__c 
                //              where Id in :storelocs ]) {
                //   storegm.put(loc.Id, loc.dealer__General_Manager__c);
                //   //System.debug('Location ' + loc.Name + ' has gm id ' + loc.dealer__General_Manager__c);
                //}
                // BLL28d end
            } // end if storelocs.size()>0
        }
        // BLL11a end
        // BLL28a
        ls.retrieveLocations();
        for(dealer__Dealer_Location__c loc : ls.locationIdMap.values()) {  
            if (loc!=null) storegm.put(loc.Id, loc.dealer__General_Manager__c);
        }
        if (u.Division!=null && ls.locationAbbrevMap.containsKey(u.Division)) {
			dealer__Dealer_Location__c loc = ls.locationAbbrevMap.get(u.Division);
			if (loc!=null) defaultLocId = loc.Id;
		}
        // BLL28a end

        // BLL19a
        Set<Id> supWonDeal = new Set<Id>();
		// BLL29
		Set<Id> supLostDeal = new Set<Id>();
		Set<Id> supPendingDeal = new Set<Id>();
		//        if (!IsInsert) for(AggregateResult r : [select dealer__Sales_Lead__c, count(Id) from dealer__Deal__c where dealer__Status__c like 'Won%' and dealer__Sales_Lead__c in :Trigger.newMap.keySet() group by dealer__Sales_Lead__c]) {
		//            supWonDeal.add((Id) r.get('dealer__Sales_Lead__c'));
		//        }
		if (!isInsert) {
			for(dealer__Deal__c d : [select Id, Name, dealer__Sales_Lead__c, dealer__Status__c from dealer__Deal__c where dealer__Sales_Lead__c in :newMap.keySet()]) {
				if (!String.isBlank(d.dealer__Status__c) && d.dealer__Status__c.startsWith('Won')) supWonDeal.add(d.dealer__Sales_Lead__c);
				else if (!String.isBlank(d.dealer__Status__c) && d.dealer__Status__c.startsWith('Lost')) supLostDeal.add(d.dealer__Sales_Lead__c);
				else supPendingDeal.add(d.dealer__Sales_Lead__c);
			}
		}
		// BLL29 end
        Set<Id> supAppts = new Set<Id>();
        if (!IsInsert) for(AggregateResult r : [select dealer__Sales_Up__c, count(Id) from dealer__Sales_Appointment__c where dealer__Sales_Up__c in :newMap.keySet() group by dealer__Sales_Up__c]) {
            supAppts.add((Id) r.get('dealer__Sales_Up__c'));
        }
        // BLL19a end
        
        MW_TriggerControls__c DealBuyerAccount = MW_TriggerControls__c.getInstance('DealBuyerAccount'); // BLL20a
        MW_TriggerControls__c SolutionOppDeals = MW_TriggerControls__c.getInstance('SolutionOppDeals'); // BLL20a
        
        
        // process insert/update records
        //--------------------------------------------
        for(dealer__Sales_Up__c s : newList) {

            // BLL28a set default location if missing
            if (s.Company__c == null) s.Company__c = defaultLocId;
            // BLL28a end

            //BLL4a don't allow vendor or 3rdParty for co-buyer account 
            if(accounts.get(s.dealer__Co_Buyer__c)!=null) {
                Account cb = accounts.get(s.dealer__Co_Buyer__c);
                if (cb.RecordType.Name=='Vendor' || cb.RecordType.Name=='Third Party Payor') {
                    if (DealBuyerAccount==null || DealBuyerAccount.Enabled__c==true) s.addError('Customer account cannot be a vendor or 3rd party payor');  // BLL20c
                }
             }
             //BLL4a end

            dealer__Sales_Up__c olds = (oldMap!=null) ? oldMap.get(s.Id) : null;
            
            // BLL25a Record status change date
			// BLL29 move status change date to after automated changes to the status...
			//if (olds!=null && s.dealer__Lead_Status__c!=olds.dealer__Lead_Status__c) s.StatusChangeDate__c = Date.today();
			// BLL29 end
            if (String.isBlank(s.Initial_solution_type__c) && !String.isBlank(s.Solution_Type__c)) s.Initial_solution_type__c=s.Solution_Type__c;
            // BLL25a end

            // BLL19a - Don't allow a change to a 'Won' solution opp if there are no won proposals
            // BLL29 - also enforce on new records!
			//if (olds!=null && s.dealer__Lead_Status__c!=olds.dealer__Lead_Status__c
            if ((olds==null || (olds!=null && s.dealer__Lead_Status__c!=olds.dealer__Lead_Status__c))
			// BLL29 end
                && (s.Solution_Type__c!='Rental' && s.Solution_Type__c!='Service') // BLL21a
                && s.dealer__Lead_Status__c=='Won' && !supWonDeal.contains(s.Id)) 
                if (SolutionOppDeals==null || SolutionOppDeals.Enabled__c==true) s.addError('Cannot mark a solution opportunity won without a won proposal.');  // BLL20c
			// BLL29 - also enforce on new records!
            //if (olds!=null && s.dealer__Lead_Status__c!=olds.dealer__Lead_Status__c 
            if ((olds==null || (olds!=null && s.dealer__Lead_Status__c!=olds.dealer__Lead_Status__c))
			// BLL29 end 
                && s.dealer__Lead_Status__c=='Quote' && (supWonDeal.contains(s.Id) || supAppts.contains(s.Id))) 
                if (SolutionOppDeals==null || SolutionOppDeals.Enabled__c==true) s.addError('Cannot return a solution opportunity to "Quote" status when it has a Won proposal or a sales appointment.');   // BLL20c
            // BLL19a end

// Cannot use this without cleaning up old stuff. There are quite a few "Won" solution opportunities without any "Won" proposals.
// But when a new solution opportunity is edited, it causes a ripple effect of updating old solution opportunities,
// which tries to re-open those old ones to "Pending" but that's not allowed (for Chassis/Conversion solutions).
			// BLL29 - if status is 'Won' and there are no won deals, force to either 'Lost' or 'Pending' based on other deals
			// (except on rental or service solutions)
			//if (s.dealer__Lead_Status__c=='Won' && !supWonDeal.contains(s.Id) && (s.Solution_Type__c!='Rental' && s.Solution_Type__c!='Service')) {
			//	// No won or pending deals, but there are lost deals (all are lost) take from 'Won' to lost, 
			//	//but allow pending to remain in case they are creating a new deal
			//	if (!supPendingDeal.contains(s.Id) && supLostDeal.contains(s.Id) && s.dealer__Lead_Status__c=='Won') s.dealer__Lead_Status__c = 'Lost';
			//	else s.dealer__Lead_Status__c = 'Pending';
			//}

			// Set status change date...
			if (olds!=null && s.dealer__Lead_Status__c!=olds.dealer__Lead_Status__c) s.StatusChangeDate__c = Date.today();
			// if new and status is not blank or pending, set the date anyway
			if (olds==null && s.StatusChangeDate__c==null && !String.isBlank(s.dealer__Lead_Status__c) && s.dealer__Lead_Status__c!='Pending') s.StatusChangeDate__c = Date.today();
			// BLL29 end

			// BLL31
            //if(accounts.get(s.dealer__Customer_Account__c)!=null) {
            Account a = accounts.get(s.dealer__Customer_Account__c);
			Contact c = contacts.get(s.dealer__Buyer_Contact__c);
			System.debug(a);
			System.debug(c);
			if (a!=null) {
			// BLL31 end

                //BLL4a don't allow vendor or 3rdParty for account 
				// BLL31
                //Account a = accounts.get(s.dealer__Customer_Account__c);
				// BLL31 end
                if (a.RecordType.Name=='Vendor' || a.RecordType.Name=='Third Party Payor') {
                    if (DealBuyerAccount==null || DealBuyerAccount.Enabled__c==true) s.addError('Customer account cannot be a vendor or 3rd party payor');  // BLL20c
                }
                //BLL4a end

                // Associate Persons Contact Record (for person accounts)
                if(accounts.get(s.dealer__Customer_Account__c).PersonContactId!=null) {
                    s.dealer__Buyer_Contact__c=accounts.get(s.dealer__Customer_Account__c).PersonContactId;
                }

                SalesUpTriggerHandler.setSolutionOpportunityName(s, olds, accounts, contacts);  // BLL27a
                
                // BLL4a - Enforce only 1 open 'Chassis' SolOpp per account
                // If it was changed *to* Chassis, this will be treated as a new Chassis SolOpp
                // If it was changed *from* Chassis to something else, then it wasn't included in the count
                // anyway, because we didn't include SolOpps being processed by the trigger.
                if (OpenChassis==null || OpenChassis.Enabled__c) {
                    if (s.Solution_Type__c!=null && s.Solution_Type__c.startsWith('Chassis')) {
                        Integer cnt = opensolopp.get(s.dealer__Customer_Account__c);
                        if (cnt==null) cnt=0;
                        dealer__Sales_Up__c old = null;
                        if (s.Id!=null) oldMap.get(s.Id);
                        System.debug('SolOpp id='+s.Id);
                        System.debug('SolOpp status='+s.dealer__Lead_Status__c);
                        System.debug('SolOpp solution type='+s.Solution_Type__c);
                        // Already have one or more open solution opportunities and this one is open?
                        if (cnt>0 && s.RecordTypeId!=CommSlopId && (s.dealer__Lead_Status__c==null    // BLL24c recordtypeid 
                                    || (s.dealer__Lead_Status__c!='Won' && s.dealer__Lead_Status__c!='Lost'))) {
                            if (SolutionOppDeals==null || SolutionOppDeals.Enabled__c==true) s.addError('Only one open Retail Chassis solution opportunity is allowed for an account'); // BLL20c, BLL22c (specify "retail" account)
                        } else
                          // Adding an open solution opportunity - update count for this account 
                          // (If this one is open it's always adding to the count because the Trigger.new SolOpps were not counted!)
                          if (s.dealer__Lead_Status__c==null 
                              || (s.dealer__Lead_Status__c!='Won' && s.dealer__Lead_Status__c!='Lost')) {
                            if (s.RecordTypeId!=CommSlopId) cnt += 1; // BLL24c recordtypeid
                            opensolopp.put(s.dealer__Customer_Account__c, cnt);
                        } else 
                          // Removing an open solution opportunity (not an update or no longer open) - update count for this account
                          if ( ( old!=null && ( old.dealer__Lead_Status__c==null || old.dealer__Lead_Status__c!='Won' || old.dealer__Lead_Status__c!='Lost' ) ) 
                               && ( s.dealer__Lead_Status__c!=null && s.dealer__Lead_Status__c=='Won' && s.dealer__Lead_Status__c=='Lost') ) {
                            if (s.RecordTypeId!=CommSlopId) cnt -= 1; // BLL24c recordtypeid
                            if (cnt<0) cnt=0;
                            opensolopp.put(s.dealer__Customer_Account__c, cnt);
                        }
                    }
                }
                // BLL4a - end
            }

			// BLL31 - Contact or Account pricepoint
			if (s!=null) System.debug(s.Price_point__c);
			if (c!=null && c.Price_point__c!=null && s.Price_point__c==null) {
				s.Price_point__c = c.Price_point__c;
			}
			if (a!=null && a.Price_point__c!=null && s.Price_point__c==null) {
				s.Price_point__c = a.Price_point__c;
			}
			if (c!=null) System.debug(c.Price_point__c);
			if (a!=null) System.debug(a.Price_point__c);
			if (s!=null) System.debug(s.Price_point__c);
			// BLL31 end

            // BDC flags -- BLL2a
            if (isInsert) {
                //BLL26d if (p.Name.contains('BDC') || (s.BDC_Created__c!=null && s.BDC_Created__c==true)) {
                if (bdcSettings.BDC_Created_SolutionOpp__c || (s.BDC_Created__c!=null && s.BDC_Created__c==true)) { // BLL26c
                    s.BDC_Created__c = true;   // Let this remain in workflow BDCAuditSalesUp, but set here too
                    if (s.dealer__CCC_Rep__c==null) s.dealer__CCC_Rep__c = UserInfo.getUserId();
                }
            }
            // BLL2a end
            
            // BLL10a
            //BLL28d dealer__Dealer_Location__c dloc = locations.get(s.Company__c);
            dealer__Dealer_Location__c dloc = ls.getLocationById(s.Company__c); // BLL28a
            if (dloc!=null && s.dealer__Company_Number__c != dloc.dealer__Company_Number__c) {
                s.dealer__Company_Number__c = dloc.dealer__Company_Number__c;
            }
            // BLL10a end
         
         
        } // end for Trigger.new

        // BLL11a fill in referenced account & owner
        if (uploadHelper==null || uploadHelper.Enabled__c) 
            SalesUpTriggerHandler.uploadByNameHelper(newList, acctmap, userMap, storegm);
        // BLL11a end
       
        // set Marketing (pardot) score
        SalesUpTriggerHandler.setMarketingScores(contacts, newList, oldMap, isInsert);  // BLL27a
    }

    // BLL27a
    // set the default solution opportunity name based on account/contact and date
    //--------------------------------------------
    public static void setSolutionOpportunityName(dealer__Sales_Up__c s, dealer__Sales_Up__c olds, Map<Id, Account> accounts, Map<Id, Contact> contacts) {
        // BLL22a
        Schema.RecordTypeInfo CommSlopRtInfo = SlopRcdTypes.get('Commercial');
        Id CommSlopId = CommSlopRtInfo!=null ? CommSlopRtInfo.getRecordTypeId() : null;
        // BLL22a

        // set default name of solution opportunity
        String yyyymm = DateTime.now().format('yyyy-MM'); // BLL3a
        if (s.dealer__Lead_Date__c!=null) yyyymm = s.dealer__Lead_Date__c.year() + '-' 
            + String.valueOf(s.dealer__Lead_Date__c.month()).leftPad(2).replace(' ','0');
        String sname = '';  // BLL7a
        if (contacts.get(s.dealer__Buyer_Contact__c)!=null && s.RecordTypeId!=CommSlopId) { // BLL22c add NOT CommSlopId test
            s.dealer__FirstName__c = contacts.get(s.dealer__Buyer_Contact__c).FirstName;
            s.dealer__LastName__c = contacts.get(s.dealer__Buyer_Contact__c).LastName;
            //s.Name = 'SO: ' + s.dealer__FirstName__c + ' ' + s.dealer__LastName__c + ' ' + yyyymm;
            sname = 'SO: ' + ((s.dealer__FirstName__c!=null)?s.dealer__FirstName__c:'') + ' ' + s.dealer__LastName__c;
            if (sname.length()>72) sname = sname.substring(0,72);
            sname = sname + ' ' + yyyymm;
            //BLL23d s.Name = sname; 
        } else {
            //s.Name = 'SO: ' + accounts.get(s.dealer__Customer_Account__c).Name + ' ' + yyyymm;    
            sname = 'SO: ' + accounts.get(s.dealer__Customer_Account__c).Name;
            if (sname.length()>72) sname = sname.substring(0,72);
            sname = sname + ' ' + yyyymm;
            //BLL23d s.Name = sname; 
        } 
        if (accounts.get(s.dealer__Customer_Account__c).isPersonAccount) { // BLL3a 
            s.dealer__FirstName__c = accounts.get(s.dealer__Customer_Account__c).FirstName;
            s.dealer__LastName__c = accounts.get(s.dealer__Customer_Account__c).LastName;
            //s.Name = 'SO: '+s.dealer__FirstName__c +' '+s.dealer__LastName__c + ' ' + yyyymm;
            sname = 'SO: ' + accounts.get(s.dealer__Customer_Account__c).Name;
            if (sname.length()>72) sname = sname.substring(0,72);
            sname = sname + ' ' + yyyymm;
            //BLL23d s.Name = sname; 
        }
        // BLL23a - force retail Slop name, only set if missin for commercial?
        if (olds!=null) System.debug('OLD SLOP NAME: "'+olds.Name);
        System.debug('Change SLOP name from "' + s.Name + '" to "'+sname+'"');
        s.Name=sname;
        //if ((String.isBlank(s.Name) || s.RecordTypeId!=CommSlopId) && !String.isBlank(sname)) s.name=sname;
        
    }
    
    // uploadUserHelper - set user and account references by user name or account external id
    //--------------------------------------
    public static void uploadByNameHelper(List<dealer__Sales_Up__c> newList, Map<String, Account> acctmap, Map<String, Id> usermap, Map<Id, Id> storegm) {
        // BLL11a BDC GM if BDC rep is not found
        Id BDC_ManagerId = null;
        // BLL11a end

        for(dealer__Sales_Up__c s : newList) {
            // Get location and set location ID
            if (!String.isBlank(s.Upload_Account__c)) {
                if (acctmap.containsKey(s.upload_Account__c)) {
                    Account ca = acctmap.get(s.upload_Account__c);
                    s.dealer__Customer_Account__c = ca.Id;
                    if (ca.isPersonAccount) s.dealer__Buyer_Contact__c = ca.PersonContactId;
                    System.debug('Assigning account to salesup for external Id ' + s.upload_Account__c + ', id=' + s.dealer__Customer_Account__c);
                }
                s.upload_Account__c = null; // reset upload field
            } // end if using upload_account__c
    
            // Get owner code (external ID) and set location ID
            if (!String.isBlank(s.upload_Owner__c)) {
                String lcname = s.upload_Owner__c.toLowercase();
                if (usermap.containsKey(lcname)) {
                    Id uid = usermap.get(lcname);
                    s.OwnerId = uid;
                    s.dealer__Salesperson_1__c = s.OwnerId; // BLL17a
                    System.debug('Assigning ID for owner ' + lcname + '=' + uid);
                } else if (s.Company__c != null) {
                    Id gmid = storegm.get(s.Company__c);         // gm for this location
                    System.debug('Location id ' + s.Company__c + ' has general manager id ' + gmid);
                    if (gmid<>null) {
                        s.OwnerId = gmid;
                        s.dealer__Salesperson_1__c = s.OwnerId; // BLL17a
                    } // end if-else gmid
               } // end if usermap else-if whatid
               s.dealer__Salesperson_1__c = s.OwnerId; // BLL13a
               s.upload_Owner__c = null;
            }  // end if using upload_owner__c
            
            if (!String.isBlank(s.upload_BDC__c)) {
                String repname = s.upload_BDC__c.toLowercase();
                if (usermap.containsKey(repname)) {
                    Id repid = usermap.get(repname);
                    s.dealer__CCC_Rep__c = repid;
                    System.debug('Assigning BDC Id ' + repname + '=' + repid);
                } 
                //BLL11a - default BDC rep to BDC manager (if found on BDC location), else current user
                else {
                    if (BDC_ManagerId==null) {
                        dealer__Dealer_Location__c bdc;
                        try {bdc = [select Id, dealer__General_Manager__c from dealer__Dealer_Location__c where dealer__Company_Number__c='BDC' limit 1];}
                        catch(Exception e) {}
                        if (bdc!=null && bdc.dealer__General_Manager__c!=null) BDC_ManagerId = bdc.dealer__General_Manager__c;
                        else BDC_ManagerId = UserInfo.getUserId();
                    }
                    s.dealer__CCC_Rep__c = BDC_ManagerId;
                    System.debug('Assigned BDC Id to BDC Manager Id ' + BDC_ManagerId);
                } // BLL11a end BDC manager logic
                s.upload_BDC__c = null;
            }   // end upload BDC is blank
            
        }   // end for newlist
        
    }
    
    
    // setMarketingScores : store create and close (win/lose) Marketing scores
    //---------------------------------
    public static void setMarketingScores(Map<Id, Contact> contactMap, List<dealer__Sales_Up__c> newList, Map<Id, dealer__Sales_Up__c> oldMap, boolean isInsert) {
		System.debug('setMarketingScores');
        Set<String> closedStatus = new Set<String>{'Won', 'Lost'};
        for(dealer__Sales_Up__c sup : newList) {
            dealer__Sales_Up__c oldSup = isInsert ? null : oldMap.get(sup.Id);
            boolean StatusChanged = oldSup!=null && sup.dealer__Lead_Status__c!=oldSup.dealer__Lead_Status__c;
            Contact c;
            if (sup.dealer__Buyer_Contact__c!=null && contactMap.containsKey(sup.dealer__Buyer_Contact__c)) c = contactMap.get(sup.dealer__Buyer_Contact__c);
            if (c!=null && isInsert) sup.MarketingScoreStart__c = c.pi__Score__c;
            if (c!=null && !isInsert && oldSup!=null && sup.dealer__Buyer_Contact__c!=oldSup.dealer__Buyer_Contact__c) sup.MarketingScoreStart__c = c.pi__Score__c;
            if (c!=null && StatusChanged && closedStatus.contains(sup.dealer__Lead_Status__c)) sup.MarketingScoreEnd__c = c.pi__score__c; 
			// BLL30 - only copy in Google Click ID if solution opp was recently created and is still pending
			// this is because creating the solution opp during lead conversion is not seeing the GCLID__c value
			// in the account if it is coming from the converted lead mapping rules.
			if (sup.Status__c=='Pending' && sup.CreatedDate.date().daysBetween(Date.today())<7 
				&& c!=null && c.GCLID__c!=null) sup.GCLID__c = c.GCLID__c;
			System.debug(c);
			System.debug(sup);
			// BLL30 end
        }
    }
    // BLL27a end
    

    public static void beforeInsertHandler(List<dealer__Sales_Up__c> newList, Map<Id, dealer__Sales_Up__c> newMap, Map<Id, dealer__Sales_Up__c> oldMap) {

    }



    /*
     * Helper methods to keep logic that was separate in the old trigger (separated by various if statements) separate here as well. 
     *
     */

    public static void markProposalsLost(List<dealer__Sales_Up__c> newList, Map<Id, dealer__Sales_Up__c> newMap, Map<Id, dealer__Sales_Up__c> oldMap) {

        MW_TriggerControls__c SolutionOppDeals = MW_TriggerControls__c.getInstance('SolutionOppDeals'); // BLL20a

        // BLL9a - mark pending proposals lost   
        Set<Id> lostSolOppIds = new Set<Id>(); 
        for(dealer__Sales_Up__c s : newList) {
            dealer__Sales_Up__c oldSolOpp = oldMap.get(s.Id); 
            if (s.dealer__Lead_Status__c=='Lost' && (oldSolOpp!=null && oldSolOpp.dealer__Lead_Status__c!='Lost')) {
                lostSolOppIds.add(s.Id);
            }
        }
        // get lists of LOST solution opps with won deals (not allowed) and pending deals (upd to lost)
        Set<Id> LostSopWithWonDeals = new Set<Id>();
        List<dealer__Deal__c> LostSopPendingDeals = new List<dealer__Deal__c>();
        if (lostSolOppIds.size()>0) {
            for (dealer__Deal__c d : [select Id, dealer__Status__c, dealer__Sales_Lead__c from dealer__Deal__c where dealer__Sales_Lead__c in :lostSolOppIds]) {
                if (d.dealer__Status__c.startsWith('Won')) {
                    LostSopWithWonDeals.add(d.dealer__Sales_Lead__c);
                }
                if (d.dealer__Status__c.startsWith('Pending')) {
                    LostSopPendingDeals.add(new dealer__Deal__c(Id=d.Id, dealer__Status__c='Lost'));
                }
            }
            // Update pending deals to lost  // possibly move to an after trigger?
            if (LostSopPendingDeals.size()>0) update(LostSopPendingDeals);  
        }  // end counts of pending and won deals
        //  don't allow marking SolOpp lost if there is a won deal on it
        for(dealer__Sales_Up__c s : newList) {
            if (lostSopWithWonDeals.contains(s.Id)) {
                if (SolutionOppDeals==null || SolutionOppDeals.Enabled__c==true) s.addError('Cannot mark lost since there are won proposals for this solution opportunity');
            }
        }  // end prevent lost solopp with won deal 
        // BLL9a end
    }

    public static void updateSalesAppointments(List<dealer__Sales_Up__c> newList, Map<Id, dealer__Sales_Up__c> newMap, Map<Id, dealer__Sales_Up__c> oldMap) {
        //RT1   
        List<Task> updTasks = new List<Task>(); // BLL13a
        List<dealer__Sales_Appointment__c> updSlsAppt = new List<dealer__Sales_Appointment__c>(); // BLL13a
        List<String> oppIds = new List<String>();
        for(dealer__Sales_Up__c solutionOpp : newList) {
            dealer__Sales_Up__c oldSolutionOpp = oldMap.get(solutionOpp.Id);
            if(solutionOpp.dealer__Salesperson_1__c != null && solutionOpp.dealer__Salesperson_1__c != oldSolutionOpp.dealer__Salesperson_1__c && solutionOpp.Solution_Type__c != 'Rental' && solutionOpp.Solution_Type__c != 'Service') {
                oppIds.add(solutionOpp.Id);
            }
        }

        if(!oppIds.isEmpty()) {
            SalesUpTriggerHandler.allowTrigger = false;
            List<Task> openTasks = [SELECT Id, OwnerId, WhatId, Status FROM Task WHERE Status != 'Completed' AND WhatId IN :oppIds];
            List<dealer__Sales_Appointment__c> openAppointments = [SELECT Id, dealer__Appointment_Result__c, dealer__Assigned_To__c, dealer__Sales_Up__c FROM dealer__Sales_Appointment__c WHERE dealer__Appointment_Result__c = 'Open' AND dealer__Sales_Up__c IN :oppIds];

            for(Task openTask : openTasks) {
                // BLL13d openTask.OwnerId = Trigger.newMap.get(openTask.WhatId).dealer__Salesperson_1__c;
                // BLL13a
                Id newOwner = newMap.get(openTask.WhatId).dealer__Salesperson_1__c; 
                Id oldOwner = oldMap.get(openTask.WhatId).dealer__Salesperson_1__c; // BLL16a
                System.debug('Change owner ' + oldOwner + ' to ' + newOwner + '? Task owner='+openTask.OwnerId);
                // BLL16 - only update task owner if it was the same as the previous SalesUp owner
                //BLL16d if (newOwner!=openTask.OwnerId) {
                if (newOwner!=openTask.OwnerId && oldOwner==openTask.OwnerId) { // BLL16a
                    System.debug('Changing owner');
                    updTasks.add(new Task(Id=openTask.Id, OwnerId=newOwner));
                } 
                // BLL13a
            }
            
            for(dealer__Sales_Appointment__c appointment : openAppointments) {
                // BLL13d appointment.dealer__Assigned_To__c = Trigger.newMap.get(appointment.dealer__Sales_Up__c).dealer__Salesperson_1__c;
                Id assignee = newMap.get(appointment.dealer__Sales_Up__c).dealer__Salesperson_1__c;
                if (assignee!=appointment.dealer__Assigned_To__c) {
                    updSlsAppt.add(new dealer__Sales_Appointment__c(Id=appointment.Id, dealer__Assigned_To__c=assignee));
                }
            }
            
            // BLL13d update openTasks;
            // BLL13d update openAppointments;
            // BLL13a
            if (updTasks.size()>0) update(updTasks);
            if (updSlsAppt.size()>0) update(updSlsAppt); 
            // BLL13a end
        }
    }

    public static void updateContactInformation(List<dealer__Sales_Up__c> newList, Map<Id, dealer__Sales_Up__c> newMap, Map<Id, dealer__Sales_Up__c> oldMap) {
        MW_TriggerControls__c updateContactInfo = MW_TriggerControls__c.getInstance('SalesUpUpdateContactInfo'); // BLL14a
        if (updateContactInfo==null || updateContactInfo.Enabled__c) { // BLL14a
        
            for(dealer__Sales_Up__c s : newList) {
                System.debug('Here');
                boolean contactChanged = false; // BLL8a
                if(s.dealer__Customer_Account__c!=null) {
                    Account a = [Select Id, AccountSource, isPersonAccount,
                                 PersonMobilePhone, PersonHomePhone, PersonEmail, PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode 
                                 from Account where Id=:s.dealer__Customer_Account__c limit 1];
                    if(a.AccountSource==null) {
                        a.AccountSource = s.dealer__Source__c;
                        if (a.isPersonAccount) a.PersonLeadSource = s.dealer__Source__c;
                    }
                    
                    if (a.isPersonAccount) {
                        contactChanged = a.PersonMobilePhone!=s.dealer__Mobile__c || a.PersonHomePhone!=s.dealer__Home_Phone__c
                            || a.PersonEmail!=s.dealer__Email__c || a.PersonMailingStreet!=s.dealer__Mailing_Street__c
                            || a.PersonMailingCity!=s.dealer__Mailing_City__c || a.PersonMailingState!=s.dealer__Mailing_State__c
                            || a.PersonMailingPostalCode!=s.dealer__Mailing_Zip__c;  // BLL8a
                       a.PersonMobilePhone= s.dealer__Mobile__c;
                       a.PersonHomePhone = s.dealer__Home_Phone__c;
                       a.PersonEmail = s.dealer__Email__c;
                       a.PersonMailingStreet = s.dealer__Mailing_Street__c;
                       a.PersonMailingCity = s.dealer__Mailing_City__c;
                       a.PersonMailingState = s.dealer__Mailing_State__c;
                       a.PersonMailingPostalCode = s.dealer__Mailing_Zip__c;
                    } else if (s.dealer__Buyer_Contact__c!=null) {
                        Contact c = [select Id, LeadSource,
                            HomePhone, MobilePhone, Email, MailingStreet, MailingCity, MailingState, MailingPostalCode 
                            from Contact where Id=:s.dealer__Buyer_Contact__c limit 1];
                        contactChanged = c.LeadSource!=s.dealer__Source__c 
                            || c.MobilePhone!=s.dealer__Mobile__c || c.HomePhone!=s.dealer__Home_Phone__c
                            || c.Email!=s.dealer__Email__c || c.MailingStreet!=s.dealer__Mailing_Street__c
                            || c.MailingCity!=s.dealer__Mailing_City__c || c.MailingState!=s.dealer__Mailing_State__c
                            || c.MailingPostalCode!=s.dealer__Mailing_Zip__c;  // BLL8a
                        c.LeadSource = s.dealer__Source__c;
                        c.HomePhone = s.dealer__Home_Phone__c;
                        c.MobilePhone = s.dealer__Mobile__c;
                        c.Email = s.dealer__Email__c;
                        c.MailingStreet = s.dealer__Mailing_Street__c;
                        c.MailingCity = s.dealer__Mailing_City__c;
                        c.MailingState = s.dealer__Mailing_State__c;
                        c.MailingPostalCode = s.dealer__Mailing_Zip__c;
                        try {   // BLL8a
                            if (contactChanged) {   // BLL8a 
                                update(c);
                            }   //BLL8a
                        } catch(Exception econtact) { System.debug('Error updating contact: ' + econtact.getMessage()); }  // BLL8a
                    }
                    try {   // BLL8a
                        if (contactChanged) {   // BLL8a
                            update a;
                        }   // BLL8a
                    } catch(Exception eaccount) { System.debug('Error updating account: ' + eaccount.getMessage()); }  // BLL8a
                }
                
            } // end for trigger.new        
        } // BLL14a end if updateContactInfo enabled     
    }
    
}