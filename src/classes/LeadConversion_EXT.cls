/**
 * LeadConversion_EXT
 * Controller extension for LeadConversion page
 * Tested by: LeadConversion_TEST
 *
 * Coverage:
 *	2017-11-20	80% (732/910)
 *	2018-07-09	77% (763/982)
 *	2019-08-27	78% (774/983)
 * 
 * ISSUES: Billing state not coming across for TW (et al?)
 * [x] Commercial: Show store
 * [x] Add activity history of emails sent
 * [x] Use assigned user's time-zone for appt time
 * [x] Don't require required fields when "Do not create ..." flag is set
 * IDEA: Edit lead version of screen (hide Convert button until saved)
 * INTERIM: Add "Mark Qualified" button for lead.
 *
 * 2015-07-21	B. Leaman	Created PardotFieldsToText for standard text representation of Pardot form data
 *                       	Create activity history with email lead info & another for pardot form data.
 *                       	Update lead status to qualified first so time-based workflow gets cancelled. 
 * 2015-08-04	B. Leaman	BLL2 - Fill in Solution Opportunity Comments field; allow selection of new acct owner.
 * 2015-08-06	B. Leaman	BLL3 - Supply Who & What Ids on tasks.
 * 2015-08-25	B. Leaman	BLL4 - Log activity of email sent on lead for Arcadium process
 * 2015-08-26	B. Leaman	BLL5 - Provide "Send Email Only" button for leads NOT being sent
 *                       	to Arcadium for legacy stores (e.g. rentals).
 * 2015-08-31	B. Leaman	BLL6 - Add pardot comments to email, log recipients in email activity
 * 2015-09-02	B. Leaman	BLL7 - replace repetitive code with "setNames()" call
 * 2015-09-09	B. Leaman	BLL8 - Add rental discount code
 * 2015-10-21	B. Leaman	BLL9 - Correct BDC_Created flag, add SentToArcadium__c flag.
 * 2016-01-15	B. Leaman	BLL10 IT18618 - Add "Do not create solution opportunity" checkbox; set solopp salesperson 1.
 * 2016-03-08	B. Leaman	BLL11 - Ability to attach lead to existing person account.
 *							Also show similar accounts.
 * 2016-04-26	B. Leaman	BLL12 IT#23973 - Set account source on new accounts.
 * 2016-05-24	B. Leaman	BLL13 Set sales appt dealer__set_by__c to current user.
 * 2016-05-31	B. Leaman	BLL14 IT#25780 - Treat "No Contact" (no solution type) as an equipment sale.
 * 2016-08-31	B. Leaman	BLL15 remove references to ArcadiumRefs__c object.
 * 2016-09-21	B. Leaman	BLL16 - Copy lead influencer associations to the account.
 * 2016-10-05	B. Leaman	BLL17 - Allow creation of a solution opportunity for other solution types (like No Contact).
 * 2016-10-19	B. Leaman	BLL18 - Allow creation of task on chassis sales - sometimes they are handed off without an appt.
 * 2017-02-10	B. Leaman	BLL19 - use managed dealer location user object.
 * 2017-02-22	B. Leaman	BLL20 - Add 30 days to create default decision date.
 * 2017-02-28	B. Leaman	BLL21 - Commercial changing to solution opportunities (and proposals).
 * 2017-08-28	B. Leaman	BLL22 - TransitWorks should not create solution opportunities.
 * 2017-11-20	B. Leaman	BLL23 - Add override for duplicate matching rule violations.
 * 2018-01-05	B. Leaman	BLL24 - Add contact lookup (to work like account lookup).
 * 2018-01-26	B. Leaman	BLL26 - Soft-code BDC settings so there can be exceptions by user; change private set to set;
 * 2018-02-06	B. Leaman	BLL27 - monitor process & email log to admin.
 * 2018-06-08	B. Leaman	BLL28 - Standardize lead record type (remove space from 'Transit Works')
 * 2018-07-09	B. Leaman	BLL29 - New influencer association object replacing old one.
 * 2018-10-24   B. Leaman   W-000469 BLL30 - Limit list of location users by eliminating inactive users and corporate/admin roles.
 * 2019-07-27   A. Miller   AMM1  - W-000552 Appointment_location__c picklist
 * 2019-08-27	B. Leaman	W-000738 BLL31 copy price point from lead into solution opp (lead conversion mapping handles account and contact)
 * 							Also increase code coverage;
 */
public with sharing class LeadConversion_EXT {

    ApexPages.StandardController standardCtlr;
    Lead lead;

    public String mode {get; private set;} 
    public Id locId;
    public dealer__Dealer_Location__c location {get; set;}	// rmv private set
    private Id lastLocId;
    private String lastSolType;
    public boolean legacyStore {get; set;}
    public boolean validLead {get; set;}
    //public boolean toArcadium {get; private set;}
    public List<AccountWrapper> similarAccounts {get;set;}	// BLL11a
    public boolean foundSimilarAccounts {get;set;} // BLL11a
    public boolean overrideDuplicateMatching {get; set;} // BLL23a

    public String editLeadUrl {get; set;}
    public String viewLeadUrl {get; set;}

    public User owner {get; set;}
    public String timezonename {get; set;}
    public User newowner {get; set;} // BLL2a
    public Id newownerId {get; set;} // BLL2a
    private String retURL;
    private User currentUser; // BLL9a
    private User leadOwnerUser; // BLL9a
    
    // private default processes
    private Map<String, String> processes;
    // retail: PersonAccount, Business Account, Influencer, Third party payer
    // commercial: Commercial
    // transitworks: TransitWorks
    public List<SelectOption> procRcdTypes {get; set;}
    public Id procRcdTypeId {get; set;}
    private String processName;
    public boolean toPersonAccount {get; set;}
    public boolean toTransitWorks {get; set;}
    public boolean toCommercial {get; set;}
    public boolean toRetail {get; set;}
    public Map<Id, String> procRcdTypeMap;
    private String dftPersonAccount = 'PersonAccount';
    private String dftBusinessAccount = 'Business Account';
    
    // Lead
    public String leadId {get; set;}
    public Lead leadRcd {get; set;}
    public String leadRcdTypeName {get; set;}    
    public Id leadRcdTypeId {get; set;}
    //public List<SelectOption> leadRcdTypes {get; set;}
    public boolean isConverted {get; set;}
    public String leadAddress {get; set;}
    public boolean retailCustomer {get; set;}

    // Account
    public Account account {get; set;}
    //public String acctRcdTypeName {get; set;}    
    //public Id acctRcdTypeId {get; set;}
    //public List<SelectOption> acctRcdTypes {get; set;}
    public List<SelectOption> acctNameOptions {get{
	        List<SelectOption> opts = new List<SelectOption>();
	        opts.add(new SelectOption('', 'New account: ' + newAcctName));
        	if (solOpp.dealer__Customer_Account__c!=null) {	// BLL11a
	       	    try {
               		Account a = [ select Id, Name, Store_Location__c 
                    	 from Account 
                     	 where Id=:solOpp.dealer__Customer_Account__c  
                     	 limit 1
               		];
					opts.add(new SelectOption(a.Id, 'Attach to: ' + a.Name));
            	} catch(Exception e) { }
        	}
	        return opts;
    } set;}	// rmv private set
    public String accountSelection {get; set;}
    private String newAcctName = '';
    
    // BLL24a
    public List<SelectOption> contNameOptions {get{
	        List<SelectOption> opts = new List<SelectOption>();
	        opts.add(new SelectOption('', 'New contact: ' + newContName));
        	if (solOpp.BuyerContact__c!=null) {	// BLL11a
	       	    try {
               		Contact c = [ select Id, Name 
                    	 from Contact
                     	 where Id=:solOpp.BuyerContact__c  
                     	 limit 1
               		];
					opts.add(new SelectOption(c.Id, 'Attach to: ' + c.Name));
            	} catch(Exception e) { }
        	}
	        return opts;
    } set;}	// rmv private set
    public String contactSelection {get; set;}
    private String newContName = '';
    // BLL24a end

    // Contact 
    public Contact contact {get; set;}	// rmv private set
    
    // Household?

    // Solution Opportunity
    public dealer__Sales_Up__c solOpp {get; set;}
    public boolean doNotCreateSolutionOpportunity {get; set;} // BLL10a
    
    // Opportunity
    public Opportunity opportunity {get; set;}
    public boolean doNotCreateOpportunity {get; set;}
    public String OppFieldsRequired { get { return (doNotCreateOpportunity?'false':'true');} set; }
    
    // Sales Appointment
    public dealer__Sales_Appointment__c salesAppointment {get; set;}
    public boolean doNotCreateSalesAppointment {get; set;}
    public String SlsApptFieldsRequired { get { return (doNotCreateSalesAppointment?'false':'true');} set; }
    public Time salesAppointmentTime {get; set;}
    
    // Task
    public Task task {get; set;}
    public boolean doNotCreateTask {get; set;}
    public String TaskFieldsRequired { get { return (doNotCreateTask?'false':'true');} set; }
    
    // Email
    public String recipients {get; set;}
    public String subject {get; set;}
    public String message {get; set;}
    public String EmailFieldsRequired { get { return (doNotSendEmail?'false':'true');} set; }
    
    // Arcadium?
    //BLL15d public List<ArcadiumRef__c> arcadiumMatches {get; private set;}

    // various flags for types of objects this conversion pgm can create
    public boolean crtAccount {get; set;}
    public boolean crtContact {get; set;}
    public boolean crtTask {get; set;}
    public boolean crtOpportunity {get; set;}
    public boolean crtSolutionOpportunity {get; set;}
    public boolean crtSalesAppointment {get; set;}
    public boolean sndEmail {get; set;}
    public boolean doNotSendEmail {get; set;}
    public String ownerType {get; set;}
    public String emailRecipientType {get; set;}
     
    // constructor
    //------------------------------------------------------------------
    public LeadConversion_EXT(ApexPages.StandardController ctlr) {
    	standardCtlr = ctlr;
        lead = (Lead) standardCtlr.getRecord();

		overrideDuplicateMatching = false;
        mode = 'edit';
        legacyStore = false;
        //toArcadium = false;
        validLead = true;

        // Get default return-to URL
        getReturnURL();
        editLeadUrl = '';
        viewLeadUrl = '';
        
        // Lead record type to corresponding Account record type mapping
        processes = new Map<String, String>();
        processes.put('Retail', 'PersonAccount,Business Account,Influencer' ); 
        processes.put('Commercial', 'Commercial' );
        processes.put('Transit Works', 'TransitWorks,Transit Works' );
        processes.put('TransitWorks', 'TransitWorks' );	// BLL28a - may be standardizing lead record type
        
        procRcdTypes = new List<SelectOption>();
        procRcdTypeId = null;
        processName = '';  // procRcdTypeName = null;
        procRcdTypeMap = new Map<Id, String>();
        owner = null;
        ownerType = 'Lead owner';
        leadRcd = null;
        leadRcdTypeName = '';
        leadRcdTypeId = null;
        retailCustomer = false;
        toRetail = false;
        //leadRcdTypes = new List<SelectOption>();
        isConverted = false; // initial value until lead is retrieved!
        leadAddress = '';
        
        //acct = new Account();
        //acctRcdTypeName = null;
        //acctRcdTypeId = null;
        //acctRcdTypes = new List<SelectOption>();

        recipients = '';

        contact = new Contact();
        account = new Account();
        accountSelection = '';
        solOpp = new dealer__Sales_Up__c();
        doNotCreateSolutionOpportunity = false; // BLL10a
        opportunity = new Opportunity();
        doNotCreateOpportunity = false;
        task = new Task();
        doNotCreateTask = false;
        salesAppointment = new dealer__Sales_Appointment__c();
        salesAppointment.dealer__Appointment_Type__c = 'First Visit';
        DateTime now = DateTime.now();
        // Adjust time to nearest 10 minute mark
        DateTime adj = DateTime.newInstance(now.year(), now.month(), now.day(), now.hour(), now.minute()-Math.mod(now.minute(), 10), 0);
        //salesAppointment.dealer__Date__c = adj.date();
        salesAppointment.dealer__Time__c = adj.format('hh:mm a');
        salesAppointmentTime = adj.time();
        if (solOpp!=null && solOpp.Solution_Type__c!=null) {
            salesAppointment.dealer__Notes__c = 'Appointment for ' + solOpp.Solution_Type__c;
        } 
        doNotCreateSalesAppointment = false;
        doNotSendEmail = false;
        
        Id leadId = null;

        // defaults
        // default location
        currentUser = [Select Id, Division, Profile.Name from User where Id=:UserInfo.getUserId() limit 1]; // BLL9c
        dealer__Dealer_Location__c[] loc = [
                SELECT Id, Name, dealer__General_Manager__c, dealer__Service_Director__c, Rental_Manager__c,  
                       Legacy_systems__c, dealer__Company_Number__c 
                FROM dealer__Dealer_Location__c 
                where dealer__Company_Number__c =:currentUser.Division 
                limit 1
        ];
        if(loc.size()==1) {
            location = loc[0];
            locId = location.Id;
        }
        account.Store_Location__c = locId;
        
        // Lead record types 
        //leadRcdTypeId = loadRecordTypeOptions(Lead.getsObjectType().getDescribe(), leadRcdTypes);
        // Account record types 
        //acctRcdTypeId = loadRecordTypeOptions(Account.getsObjectType().getDescribe(), acctRcdTypes);

        // if lead Id comes in ... (TODO: if user authorized to leads?) 
        try {
            loadLead();
        } catch(Exception e) { }
        
        if (leadRcd==null || leadRcd.Id==null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                      'No lead specified. Use the Convert button from the Lead Detail page.'));
            validLead = false;
        } else {	// BLL11a
        	findSimilarAccounts();	// BLL11a
        }	// BLL11a
        
        // Can't convert lead that is owned by a queue 
        try {
            leadOwnerUser = [
                 SELECT Id, Name, TimeZoneSidKey, Profile.Name 
                 FROM User
                 WHERE Id=:leadRcd.OwnerId 
                 LIMIT 1
            ];
            timezonename = TimeZone.getTimeZone(leadOwnerUser.TimeZoneSidKey).getDisplayName(); // BLL9c 
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Lead is not yet assigned to a valid owner'));
            validLead = false;
        }

        // Set up process selection
        procRcdTypeId = loadProcessRecordTypeOptions(Account.getSobjectType().getDescribe(), procRcdTypes, procRcdTypeMap);
        System.debug('Default Process rcd type id='+procRcdTypeId);
        try {
            if (procRcdTypes.size()>0) {
                processName = sNull(procRcdTypeMap.get(procRcdTypeId));
                System.debug('Lead Rcd Type=' + leadRcdTypeName + '; Process name=' + processName);
                toPersonAccount = processName.startsWith('Person');
                toTransitWorks = processName.startsWith('Transit');
                toCommercial = processName.startsWith('Commercial');
                toRetail = !toTransitWorks && !toCommercial;
                retailCustomer = leadRcdTypeName=='Retail' && (processName.startsWith('Person') || processName.startsWith('Business'));
                System.debug('retailCustomer = ' + (retailCustomer?'true':'false'));
            } else if (leadRcdTypeName.length()==0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Lead does not have a record type'));
                validLead = false;
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Not authorized to lead type ' + leadRcdTypeName ));
                validLead = false;
            }
        } catch (Exception e) {
            System.debug('Unable to get process name for id');
            for(Id i : procRcdTypeMap.keySet()) {
                System.debug('Key ' + i + '=' + procRcdTypeMap.get(i));
            } 
            validLead = false;
        }

        if (leadRcd!=null && leadRcd.Id!=null) {
	        setSelectedStore();
	        //setProcess(); // moved inside setSelectedStore()
	
	        // find possible matches in Arcadium
	        //BLL15d findInArcadium();
	        
	        
	        //acctNameOptions = new List<SelectOption>();
	        //acctNameOptions.add(new SelectOption('', 'New account: ' + newAcctName));
	        //System.debug('New account option = ' + acctNameOptions.get(0).getLabel());
	        
	        // BLL24a
	        //contNameOptions = new List<SelectOption>();
	        //contNameOptions.add(new SelectOption('', 'New contact: ' + newContName));
	        //System.debug('New contact option = ' + contNameOptions.get(0).getLabel());
	        // BLL24a end
        }     	
    }


    // getReturnURL
    //------------------------------------------------------------------
    public void getReturnURL() {
        Map<String,String> URLParameters = ApexPages.currentPage().getParameters();
        if (retURL==null) {
            if (URLParameters.containsKey('retURL')) {
                  retURL = URLParameters.get('retURL');
            } else {
                  retURL = ApexPages.currentPage().getHeaders().get('Referer');
            }
        }
    }


    // setSelectedStore
    //------------------------------------------------------------------
    public void setSelectedStore() {
    	if (account!=null && account.Store_Location__c!=null) {
            System.debug('Selected location id=' + account.Store_Location__c);
    	}
        if (toRetail) {
            if (account.Store_Location__c!=null) {
               location = [SELECT Id, Name, dealer__General_Manager__c, dealer__Service_Director__c, Rental_Manager__c,  
                           Legacy_systems__c, dealer__Company_Number__c
                    FROM dealer__Dealer_Location__c 
                    where Id = :account.Store_Location__c 
                    limit 1
               ];
               legacyStore = location.Legacy_systems__c;
               System.debug('setSelectedStore setting legacy store = '+(legacyStore?'true':'false') + ' for ' + location.Name);
            } else {
                account.Store_Location__c.addError('Store is required');
            }
        } else {
            legacyStore = false;
        }
        setProcess();
    }
    
    // markQualified
    // mark lead as qualified to remove pending time-dependent workflow
    //------------------------------------------------------------------
    public void markQualified() {
        leadRcd.Status = 'Qualified';
        update(leadRcd);
    }
    
    // defaultEmailMessage
    //-------------------------------------------------
    public String defaultEmailMessage() {
        String message = '';
        if (solOpp!=null && solOpp.Solution_Type__c!=null) {
	        message += 'You have a request for ' + solOpp.Solution_Type__c+ '\n';
        }
        if (leadRcd!=null) {
        	message += 'Contact: ' + leadRcd.FirstName + ' ' + leadRcd.LastName;
        	if (leadRcd.Company!=null && !String.isBlank(leadRcd.Company)) {
        		message += ', ' + leadRcd.Company;
        	}
        	if (leadRcd.Phone!=null && !String.isBlank(leadRcd.Phone)) {
        		message += '; Phone: ' + leadRcd.Phone;
        	}
        	if (leadRcd.Email!=null && !String.isBlank(leadRcd.Email)) {
        		message += '; Email: ' + leadRcd.Email;  
        	}
            // BLL5a begin
            if (leadAddress!=null && !String.isBlank(leadAddress)) {
            	message += '\nAddress: ' + leadAddress.replaceAll('\n\r', ', ');  
            }
            message += '\n\n';
            // BLL5a end        	
        }
        
        // BLL6a
        if (leadRcd.pi__comments__c!=null && !String.isBlank(leadRcd.pi__comments__c)) {
        	message += leadRcd.pi__comments__c + '\n\n';
        }
        // BLL6a end
        
        // BLL5a
        String pardotdata = PardotFieldsToText(leadRcd.Id);
        if (pardotdata!=null && !String.isBlank(pardotdata)) {
        	message += pardotdata + '\n\n';
        }
        // BLL5a end
        if (leadRcd.Description!=null) {
            message += leadRcd.Description + '\n\n'; 
        }
        if (leadRcd.Email_Lead_Content__c!=null) {
            message += leadRcd.Email_Lead_Content__c + '\n\n';
        }
        return message;
    }


    // getLocationUsers - BLL2a
    //------------------------------------------------------------------
    public List<SelectOption> getLocationUsers() {
    	List<SelectOption> opts = new List<SelectOption>();
    	boolean includesOwner = false;
    	// BLL19d
        //for(Dealer_Location_Users__c dlu : [
        //       select Id, Name, User__r.Id, User__r.Name 
        //       from Dealer_Location_Users__c 
        //       where Dealer_Location__c=:account.Store_Location__c
        //       order by User__r.Name]) {
        //    opts.add(new SelectOption(dlu.User__r.Id, dlu.User__r.Name));
        //    if (owner!=null && dlu.User__r.Id==owner.Id) includesOwner = true;
        //}
        // BLL19d end
        // BLL19a 
            // BLL30 -added to the SOQL where clause for active users not in corporate or admin roles
        for(dealer__Dealer_Location_User__c dlu : [
		       select Id, Name, dealer__User__c, dealer__User__r.Name 
		       from dealer__Dealer_Location_User__c
		       where dealer__Dealer_Location__c=:account.Store_Location__c
                 and dealer__User__r.IsActive=true 
                 and dealer__User__r.UserRole.Name!='Admin' and dealer__User__r.UserRole.Name!='WMK Corporate' and dealer__User__r.UserRole.Name!='MobilityWorks' 
		       order by dealer__User__r.Name ]) {
			if (dlu.dealer__User__c!=null) opts.add(new SelectOption(dlu.dealer__User__c, dlu.dealer__User__r.Name));
			if (owner!=null && dlu.dealer__User__c==owner.Id) includesOwner = true;
    	}
    	// BLL19a end
        if (!includesOwner &&  owner!=null) {
        	opts.add(new SelectOption(owner.Id, owner.Name));
        }   	
        return opts;
    } 
    // BLL2a end

    // setNames - BLL7a
    // --------------------------------------------------------
    public String setNames(String solType, String newAcctName) {
        String sname = '';
        String yyyymm = DateTime.now().format('yyyy-MM');
        if (solType!=null && !String.isBlank(solType)) {
        	sname += solOpp.Solution_Type__c + ' for ';
        }
        sname += newAcctName;
        if (sname.length()>72) sname = sname.substring(0,72);
        sname += ' ' + yyyymm;
        opportunity.Name = sname;
        task.Subject = sname;
        subject = sname;
        String slopname = newAcctName;	// BLL adj
        if (slopname.length()>68) slopname = slopname.substring(0,68);
        solOpp.Name = 'SO: ' + slopname + ' ' + yyyymm;

        return sname;
    }    

    // setSolutionType
    //------------------------------------------------------------------
    public void setProcess() {
        processName = sNull(procRcdTypeMap.get(procRcdTypeId));
        toPersonAccount = processName.startsWith('Person');
        toTransitWorks = processName.startsWith('Transit');
        retailCustomer = leadRcdTypeName=='Retail' && (processName.startsWith('Person') || processName.startsWith('Business'));
        System.debug('Retail customer='+(retailCustomer?'true':'false'));
        System.debug('Using process ' + processName + ' (id='+procRcdTypeId+')');
        System.debug('Solution type='+solOpp.Solution_Type__c);

        //newowner = null;
        //newownerId=null;

        // Only send to arcadium if it's a legacy store AND NOT Equipment or Chassis sale
        //if (!legacyStore) {
        //  toArcadium=false;
        //} else {
        //  toArcadium = retailCustomer && (solOpp.Solution_Type__c.startsWith('Rental') || solOpp.Solution_Type__c.startsWith('Service'));
        //}
        if (solOpp.Solution_Type__c != null) {
            subject = setNames(null, newAcctName);
        }
        
        // default email message
        message = defaultEmailMessage();

        if (solOpp!=null && solOpp.Solution_Type__c!=null) {
            salesAppointment.dealer__Notes__c = 'Appointment for ' + solOpp.Solution_Type__c;
        } 
        
        if (!legacyStore && (processName.startsWith('Person') || processName.startsWith('Business'))) {
            if (solOpp.Solution_Type__c!=null && (solOpp.Solution_Type__c.startsWith('Chassis') || solOpp.Solution_Type__c.startsWith('Conversion'))) {
                crtAccount=true && !legacyStore;
                crtSolutionOpportunity=true && !legacyStore;
                crtSalesAppointment=true && !legacyStore;
                //BLL18d crtTask = false;
                crtTask = true && !legacyStore;	// BLL18a
                ownerType = 'General Manager';
                sndEmail = true;
                crtContact = false;
                crtOpportunity = false;
            // BLL14d } else if (solOpp.Solution_Type__c!=null && solOpp.Solution_Type__c.startsWith('Equip')) {
            } else if (solOpp.Solution_Type__c==null || solOpp.Solution_Type__c.startsWith('Equip')) {	// BLL14a
                crtAccount=true && !legacyStore;
                crtSolutionOpportunity=true && !legacyStore;
                //crtSalesAppointment=false;
                crtSalesAppointment=true;	// BLLa 2018-02-19
                crtTask = true && !legacyStore;
                ownerType = 'General Manager';
                sndEmail = true;
                crtContact = false;
                crtOpportunity = false;
            } else if (solOpp.Solution_Type__c!=null && solOpp.Solution_Type__c.startsWith('Rent')) {
                crtAccount=true && !legacyStore;
                crtSolutionOpportunity=true && !legacyStore;
                crtSalesAppointment=false;
                crtTask = false;
                ownerType = 'Rental Manager';
                sndEmail = true;
                crtContact = false;
                crtOpportunity = false;
            } else if (solOpp.Solution_Type__c!=null && solOpp.Solution_Type__c.startsWith('Service')) {
                crtAccount = true && !legacyStore;
                crtSolutionOpportunity=true;
                crtSalesAppointment=false;
                crtTask = true && !legacyStore;
                ownerType = 'Service Manager';
                sndEmail = true;
                crtContact = false;
                crtOpportunity = false;
            } else {  // unknown type
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Unrecognized solution type ' + solOpp.Solution_Type__c));
                System.debug('Unrecognized solution type ' + solOpp.Solution_Type__c);
                crtAccount = true && !legacyStore;
                crtContact = true && !legacyStore;
                //BLL17d crtSolutionOpportunity = false;
                crtSolutionOpportunity = true;	// BLL17a
                crtSalesAppointment = false;
                //BLL17d crtTask = false;
                crtTask = true;	// BLL17a
                //BLL17d ownerType = 'Lead owner';
                ownerType = 'General Manager';	// BLL17a
                sndEmail = true;
                crtOpportunity = false;
            }
        } else if (processName.startsWith('Commercial') || processName.startsWith('Transit')) {
            crtAccount = true;
            crtContact = true;
            crtTask = true;
            ownerType = 'Lead owner';
            //BLL21d crtOpportunity = true;
            //BLL21d crtSolutionOpportunity = false;
            //BLL22d crtOpportunity = false;	// BLL21a
            //BLL22d crtSolutionOpportunity = true;	// BLL21a
            crtOpportunity = processName.startsWith('Transit');	// BLL22a
            crtSolutionOpportunity = !crtOpportunity;	// BLL22a
            crtSalesAppointment = false;
            sndEmail = true;
            if (processName.startsWith('Commercial') && solOpp!=null && solOpp.Solution_Type__c!=null
               && (solOpp.Solution_Type__c.startsWith('Service') || solOpp.Solution_Type__c.startsWith('Rental'))) {
            	sndEmail = true;
            }
        } else {
            crtAccount = !legacyStore;
            crtContact = !legacyStore;
            crtTask = !legacyStore;
            ownerType = 'Lead owner';
            crtOpportunity = false;
            crtSolutionOpportunity = false;
            crtSalesAppointment = false;
            sndEmail = true;
        }

        // Get list of managers
        User GenMgr=null;
        User SvcMgr=null;
        User RntMgr=null;
        if (location!=null && location.dealer__General_Manager__c!=null) {
        	try {
        	    GenMgr = [select Id, Name, TimeZoneSidKey, Email, Profile.Name, isActive, ManagerId from User where Id=:location.dealer__General_Manager__c limit 1];
        	} catch(Exception GMErr) { }
        }
        if (location!=null && location.dealer__Service_Director__c!=null) {
        	try {
        	    SvcMgr = [select Id, Name, TimeZoneSidKey, Email, Profile.Name, isActive, ManagerId from User where Id=:location.dealer__Service_Director__c limit 1];
        	} catch(Exception SMErr) { }
        }
        if (location!=null && location.Rental_Manager__c!=null) {
        	try {
        	   RntMgr = [select Id, Name, TimeZoneSidKey, Email, Profile.Name, isActive, ManagerId from User where Id=:location.Rental_Manager__c limit 1];
        	} catch(Exception RMErr) { }
        }
        // Default to GM if missing
        if (SvcMgr==null) SvcMgr = GenMgr;
        if (RntMgr==null) RntMgr = GenMgr;

        // Find correct owner 
        Id ownerId = leadRcd.OwnerId;     // Current lead owner
        owner=null;
        if (ownerType.startsWith('G') && GenMgr!=null) {  // General Manager
            owner = GenMgr;
        }
        if (ownerType.startsWith('S') && SvcMgr!=null) {  // Service Manager
            owner = SvcMgr;
        }
        if (ownerType.startsWith('R') && RntMgr!=null) {  // Rental Manager
            owner = RntMgr;
        }
        if (owner==null) {
           try {
               owner = [select Id, Name, TimeZoneSidKey, Email, Profile.Name, isActive, ManagerId from User where Id=:leadRcd.ownerId limit 1];
               if (owner.isActive==false && owner.ManagerId!=null) {
                   owner = [select Id, Name, TimeZoneSidKey, Email, Profile.Name, isActive, ManagerId from User where Id=:owner.ManagerId limit 1];
               }
           } catch(Exception e) {
               System.debug('Unable to obtain owner information -- probably assigned to a queue');
               owner = GenMgr;
           }
        }
        if (owner==null) {  // default to current user
            owner = [select Id, Name, TimeZoneSidKey, Email, Profile.Name, isActive, ManagerId from User where Id=:UserInfo.getUserId() limit 1];
        }
        ownerId=owner.Id;
        if (lastLocId==null || lastSolType==null || lastLocId!=location.Id || lastSolType!=solOpp.Solution_Type__c) {
        	newownerId = ownerId;
        }
        if (location!=null && location.Id!=null) {
            lastLocId = location.Id;
        } else {
        	lastLocId = null;
        }
        lastSolType = solOpp.Solution_Type__c;
        
        //timezonename = TimeZone.getTimeZone(owner.TimeZoneSidKey).getDisplayName();
        newowner = [select Id, Name, TimeZoneSidKey, Email, Profile.Name, isActive, ManagerId from User where Id=:newownerId limit 1];
        System.debug('Set new owner to ' + newowner.Name);
        timezonename = TimeZone.getTimeZone(newowner.TimeZoneSidKey).getDisplayName();
        
        // Email recipients
        // Store-based recipient
        User recipientUser = null;
        
        if (toRetail && solOpp!=null && solOpp.Solution_Type__c!=null && (solOpp.Solution_Type__c.startsWith('Chassis') || solOpp.Solution_Type__c.startsWith('Conversion'))) {
        	emailRecipientType = 'General Manager';
        	recipientUser = GenMgr;
        } else if (toRetail && solOpp!=null && solOpp.Solution_Type__c!=null && solOpp.Solution_Type__c.startsWith('Equip')) {
        	emailRecipientType = 'General Manager';
        	recipientUser = GenMgr;
        } else if (solOpp!=null && solOpp.Solution_Type__c!=null && solOpp.Solution_Type__c.startsWith('Rent')) {
        	emailRecipientType = 'Rental Manager';
        	recipientUser = RntMgr;
        } else if (solOpp!=null && solOpp.Solution_Type__c!=null && solOpp.Solution_Type__c.startsWith('Service')) {
        	emailRecipientType = 'Service Manager';
        	recipientUser = SvcMgr;
        } else {
        	emailRecipientType = 'Lead owner';
        	recipientUser = newowner;
        }
        Id recipientId = null;
        if (recipientUser!=null) {
        	recipientId = recipientUser.Id;
            if (recipientUser.Email!=null) {
                recipients = recipientUser.Email;
            } 
        }
        
        // additional recipients...
        // New account owner
        System.debug('Recipient id=' + recipientId + '; new owner id=' + newowner.Id);
        if (recipientId!=newowner.Id 
            && newowner!=null && newowner.Email!=null && !recipients.contains(newowner.Email)) {
      	    recipients = recipients + ';' + newowner.Email;
      	    System.debug(recipients);
        }
        // Copy the gm
        if (toRetail && GenMgr!=null && recipientId!=GenMgr.Id && GenMgr.Email!=null
            && !recipients.contains(GenMgr.Email)) {
        	recipients = recipients + ';' + GenMgr.Email;
      	    System.debug(recipients);
        }

        salesAppointment.OwnerId = newowner.Id;
        salesAppointment.dealer__Assigned_To__c = newowner.Id;

        // Failsave for converted lead
        isConverted = leadRcd.isConverted;
        if (leadRcd.isConverted) {
            // Comment out -- not needed, and improves code coverage% because this is not in the test script
            //crtAccount = false;
            //crtContact = false;
            //crtOpportunity = false;
            //crtSolutionOpportunity = false;
            //crtSalesAppointment = false;
            //crtTask = false;
            //sndEmail = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Lead has already been converted'));
        }

        System.debug('Process owner: ' + ownerType + ' ' +
                     (legacyStore?'Arcadium':'') + ' ' +
                     (crtAccount?'Account ':'') + (crtContact?'Contact ':'') +
                     (crtOpportunity?'Opportunity ':'') + (crtSolutionOpportunity?'Solution Opportunity ':'') +
                     (crtSalesAppointment?'Sales Appointment':'') + (crtTask?'Task ':'') +
                     (sndEmail?'Email notification ':''));
        //return null;
    }


    // loadProcessRecordTypeOptions
    //------------------------------------------------------------------
    private Id loadProcessRecordTypeOptions(Schema.DescribeSObjectResult dsr, List<SelectOption> rcdTypeOptions,
                 Map<Id, String> rcdTypeMap) {   
        Id rtnId = null;
        String dftRcdTypeName = null;
        Id firstId = null;

        String proclist = processes.get(leadRcdTypeName);
        if (proclist==null) proclist='';
        
        Set<String> prc = new Set<String>(proclist.split(','));
        System.debug('Lead record type name='+leadRcdTypeName);
        dftRcdTypeName = null;
        if (leadRcdTypeName=='Retail') {
            if (leadRcd != null && String.isBlank(leadRcd.Company)) {
                dftRcdTypeName = dftPersonAccount;
                System.debug('Default to person account');
            } else {
                dftRcdTypeName = dftBusinessAccount;
                System.debug('Default to business account');
            }
        } 
        System.debug('Default record type name=' + sNull(dftRcdTypeName));  
        for(Schema.RecordTypeInfo rti : dsr.getRecordTypeInfos()) {
            if (rti.isAvailable() && prc.contains(rti.getName())) {
                if (firstId==null) { 
                    firstId = rti.getRecordTypeId();
                    System.debug('First id=' + firstId + ' ' + rti.getName());
                }
                System.debug('Available process = ' + rti.getName());
                rcdTypeMap.put(rti.getRecordTypeId(), rti.getName());
                rcdTypeOptions.add(new SelectOption(rti.getRecordTypeId(), rti.getName()));
                if (dftRcdTypeName==null && rti.isDefaultRecordTypeMapping()) {
                    dftRcdTypeName = rti.getName();
                    System.debug('Setting default record type='+dftRcdTypeName);
                }
            } else {
                System.debug(rti.getName() + ' is not available or not in process list (' + proclist + ')');
            }
            if (dftRcdTypeName == rti.getName()) {
                rtnId = rti.getRecordTypeId();
                System.debug('Setting default record type id='+rtnId);
            }
        }
        if (rtnId==null && firstId!=null && rcdTypeMap.size()>0) {
            rtnId = firstId;
            System.debug('Use first option as default record type id (' + rtnId + ')');
        }
        return rtnId;
    } 


    // Load Lead info 
    //------------------------------------------------------------------
    private void loadLead() {
	   	MW_BDC_Settings__c bdcSettings = MW_BDC_Settings__c.getInstance();	// BLL26a
        Map<String,String> URLParameters = ApexPages.currentPage().getParameters();
        // Get lead Id (if not specifed, using this for walk-in type process)
        //if (URLParameters.containsKey('id')) {
        //    leadId = URLParameters.get('id');
        //}
        leadId = lead.Id;
        if (leadId!=null) {
            viewLeadUrl = '/' + leadId;
            editLeadUrl = '/' + leadId + '/e' + '?retURL=' + EncodingUtil.urlEncode(ApexPages.currentPage().getURL(),'UTF-8');
            try {
                leadRcd = [ select Id, Name, FirstName, LastName, Phone, MobilePhone, Email, Company, 
                                   RecordType.Name, RecordTypeId, CreatedBy.Name, CreatedDate, 
                                   Street, City, State, PostalCode, Country,  
                                   Owner.Name, isConverted, ConvertedAccountId, ConvertedContactId,
                                   Store_Location__c, Solution_Type__c, Email_Lead_Content__c, 
                                   LeadSource, Description, Lead_Type__c, Status, OwnerId,
                                   Chair_Brand__c, Chair_Model__c, End_User__c, Physical_Challenge__c,
                                   Decision_Maker__c, Veteran__c,   
								   Price_point__c, // BLL31
                                   pi__campaign__c, pi__comments__c, pi__conversion_date__c,
                                   pi__conversion_object_name__c, pi__conversion_object_type__c,
                                   pi__created_date__c, pi__first_activity__c, pi__first_touch_url__c,
                                   pi__first_search_term__c, pi__first_search_type__c, pi__grade__c,
                                   pi__last_activity__c, pi__notes__c, pi__score__c, pi__url__c
                            from Lead 
                            where Id=:leadId
                            limit 1
                          ];
                if (leadRcd!=null) {
                    try {
                        //System.debug('Loaded lead');
                        //System.debug(leadRcd);
                        leadAddress = sNull(leadRcd.Street) + '\n\r' + sNull(leadRcd.City) + '  ' 
                                    + sNull(leadRcd.State) + '  ' + sNull(leadRcd.PostalCode);
    
                        if (leadRcd.RecordType!=null) {
                            leadRcdTypeId = leadRcd.RecordTypeId;
                            leadRcdTypeName = leadRcd.RecordType.Name;
                        } else {
                            leadRcdTypeId=null;
                            leadRcdTypeName='';
                        } 
        
                        if (leadRcd.Store_Location__c!=null) {
                            account.Store_Location__c = leadRcd.Store_Location__c;
                        }
                        if (leadRcd.Solution_Type__c!=null) {
                            solOpp.Solution_Type__c = leadRcd.Solution_Type__c;
                        } else if (leadRcd.Status=='No Contact') {	// BLL14a
                        	solOpp.Solution_Type__c = 'Equipment';	// BLL14a
                        } else {
                        	solOpp.Solution_Type__c = 'Chassis/Conversion';
                        }
                        
                        // BLL?a standardize Solution_Type__c
                        if (solOpp.Solution_Type__c!=null && solOpp.Solution_Type__c.startsWith('Equipment')) solOpp.Solution_Type__c='Equipment';	
                        // BLL?a end
                        
                        // BLL24a
                        String cn = sNull(leadRcd.FirstName) + ' ' + sNull(leadRcd.LastName);
                        newContName = cn.trim();
                        // BLL24a end
                        
                        if (String.isBlank(leadRcd.Company)) {
                            String n = sNull(leadRcd.FirstName) + ' ' + sNull(leadRcd.LastName);
                            newAcctName = n.trim();
                        } else {
                            newAcctName = sNull(leadRcd.Company);
                        }
                        //String yyyymm = DateTime.now().format('yyyy-MM');
                        //solOpp.Name = 'SO: ' + newAcctName + ' ' + yyyymm;
                        //opportunity.Name = newAcctName + ' ' +  yyyymm;
                        Date tdy = Date.today();
                        opportunity.CloseDate = tdy.addMonths(1);
                        opportunity.StageName = 'Pending';
                        //task.Subject = newAcctName + ' ' + yyyymm;
                        task.ActivityDate = tdy;
                        setNames(null, newAcctName);
                        
                        //BLL9d Id pId = userInfo.getProfileId();
                        //BLL9d Profile p = [select Id, Name from Profile where Id=:pId];
                        //BLL9d if (p.Name.contains('BDC')) {
                        //BLL26d if (currentUser.Profile.Name.contains('BDC') || (leadOwnerUser!=null && leadOwnerUser.Profile.Name.contains('BDC'))) { // BLL9a
                        if (bdcSettings.BDC_Created_SolutionOpp__c) {	// BLL26a
                           solOpp.BDC_Created__c = true;
                           solOpp.dealer__CCC_Rep__c = UserInfo.getUserId();
                        }
                               
                        solOpp.dealer__Source__c = leadRcd.LeadSource;
                        solOpp.dealer__Comments__c = leadRcd.Description;
                        // default email message
                        message = defaultEmailMessage();
                    } catch(Exception e2) {
                        System.debug('Error with lead: ' + e2.getMessage());
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Lead has invalid data: ' + e2.getMessage()));
                    }
                } 
            } catch(Exception e) {
                System.debug('Error fetching lead: ' + e.getMessage());
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Specified lead was not found'));
            }
        }
    }

	// BLL24a
	// selectAccount
	//public void selectAccount() {
	//	System.debug('selectAccount ' + accountSelection);
	//	System.debug(solOpp.dealer__Customer_Account__c);
	//	solOpp.dealer__Customer_Account__c = accountSelection;
	//	System.debug(solOpp.dealer__Customer_Account__c);
	//}
	// BLL24a end

    // assignAccount
    //------------------------------------------------------------------
    public PageReference assignAccount() {
        //BLL11d System.debug('assignAccount' + contact.AccountId);
        System.debug('assignAccount ' + solOpp.dealer__Customer_Account__c);	// BLL11a
        PageReference pageref = null;
        if (solOpp.dealer__Customer_Account__c==null) return pageref;
        //while (acctNameOptions.size()>1) {
        //   acctNameOptions.remove(acctNameOptions.size()-1);
        //}
        Account a = null;
        //BLL11d if (contact.AccountId != null) {
        if (solOpp.dealer__Customer_Account__c!=null) {	// BLL11a
            try {
               a = [ select Id, Name, Store_Location__c 
                     from Account 
                     where Id=:solOpp.dealer__Customer_Account__c //BLL11c contact.AccountId 
                     limit 1
               ];
            } catch(Exception e) { }
            if (a != null) {
               //acctNameOptions.add(new SelectOption(a.Id, 'Attach to: ' + a.Name));
               System.debug('Adding existing account option for ' + a.Name);
               accountSelection = a.Id;
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Account lookup error'));
            }
        }
        return pageref;
    }



    // assignContact
    //------------------------------------------------------------------
    public PageReference assignContact() {
        //BLL11d System.debug('assignContact' + contact.AccountId);
        System.debug('assignContact ' + solOpp.BuyerContact__c);	
        System.debug('assignContact account ' + solOpp.dealer__Customer_Account__c);	
        PageReference pageref = null;
        if (solOpp.BuyerContact__c==null) return pageref;
        //while (contNameOptions.size()>1) {
        ////   contNameOptions.remove(acctNameOptions.size()-1);
        //   contNameOptions.remove(contNameOptions.size()-1);
        //}
        Contact c = null;
        //BLL11d if (contact.AccountId != null) {
        if (solOpp.BuyerContact__c!=null) {
            try {
               c = [ select Id, Name, AccountId 
                     from Contact 
                     where Id=:solOpp.BuyerContact__c 
                     limit 1
               ];
            } catch(Exception e) { }
            if (c != null) {
               contNameOptions.add(new SelectOption(c.Id, 'Attach to: ' + c.Name));
               System.debug('Adding existing contact option for ' + c.Name);
               contactSelection = c.Id;
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Contact lookup error'));
            }
        }
        return pageref;
    }



    // validConversionRequest
    // edit-check page variables!
    //------------------------------------------------------------------
    public boolean validConversionRequest() {
        boolean rtn = true;
        processName = sNull(procRcdTypeMap.get(procRcdTypeId));
        
        System.debug('leadRcdTypeName=' + leadRcdTypeName + '; processName=' + processName);
        
        // Retail customers must have a solution type specified & Business accounts need a lead company name
        if ( leadRcdTypeName=='Retail' && (processName.startsWith('Person') || processName.startsWith('Business'))) {
            if (solOpp.Solution_Type__c==null || solOpp.Solution_Type__c=='') {
                rtn = false;
                solOpp.Solution_Type__c.addError('Solution type is required for retail customers');
            }
        }
        
        // BLL11a
        if (accountSelection!=null) {
			try {
        		account = [select Id, Name, Store_Location__c, isPersonAccount, PersonContactId from Account where Id=:accountSelection];
			} catch(Exception e) {}
        }
        // BLL11a end
        
        // Non-person accounts: Lead must have company name specified
        if (processName.startsWith('Person')) {
            // even if saying it's a person account, if another account is selected, it has to be another person acct
            if (accountSelection!=null && accountSelection.length()>0) {
                if (!account.isPersonAccount) {
                	System.debug(account);
                    rtn = false;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Business account selected for the Person Account process'));
                }
            }
        } else {
            if (String.isBlank(leadRcd.Company)) {
                rtn = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Lead must have a company name for a business account'));
            }
        }
        
        // opportunity
        if (crtOpportunity && !doNotCreateOpportunity) {
            if (opportunity.Name==null || opportunity.Name.trim().length()==0) {
                rtn = false;
                opportunity.Name.addError('Opportunity name is required');
            } else if (opportunity.Name.trim().length()<10) {
                rtn = false;
                opportunity.Name.addError('Opportunity name is too short (10)');
            }
        }
        
        // solution opportunity
        // BLL10d if (crtSolutionOpportunity) {
        if (crtSolutionOpportunity && !doNotCreateSolutionOpportunity) { // BLL10a
            if (solOpp.Name.trim().length()==0) {
                rtn = false;
                solOpp.Name.addError('Solution Opportunity name is required');
            } else if (solOpp.Name.trim().length()<10) {
                rtn = false;
                solOpp.Name.addError('Solution Opportunity name is too short (10)');
            }
        }

        // sales appointment
        if (crtSalesAppointment && !doNotCreateSalesAppointment) {
        	// BLL10a
        	if (doNotCreateSolutionOpportunity) {
        		rtn = false;
                salesAppointment.dealer__Appointment_Type__c.addError('Solution opportunity is required for a sales appointment');
        	}
        	// BLL10a end
            if (salesAppointment.dealer__Appointment_Type__c==null || salesAppointment.dealer__Appointment_Type__c=='') {
                rtn = false;
                salesAppointment.dealer__Appointment_Type__c.addError('Apointment type must be specified');
            }
            // AMM1 
            if (salesAppointment.Appointment_location__c ==null || salesAppointment.Appointment_location__c =='') {
                rtn = false;
                salesAppointment.Appointment_location__c .addError('Apointment Location must be specified');
            }
            // AMM1
            if (salesAppointment.dealer__Date__c==null) {
                rtn = false;
                salesAppointment.dealer__Date__c.addError('Appointment date is required');
            }
            if (salesAppointment.dealer__Time__c==null || salesAppointment.dealer__Time__c.trim().length()==0) {
                rtn = false;
                salesAppointment.dealer__Time__c.addError('Appointment time is required');
            }
            //if (salesAppointment.dealer__Notes__c.trim().length()==0) {
            //  rtn = false;
            //  salesAppointment.dealer__Notes__c.addError('Appointment notes are required');
            //}
        }
        
        // task
        if (crtTask && !doNotCreateTask) {
            if (task.Subject==null || task.Subject.trim().length()==0) {
                rtn = false;
                task.Subject.addError('Subject is required');
            }
            if (task.ActivityDate==null) {
                rtn = false;
                task.Subject.addError('Date is required');
            }
        }
        
        // email notification
        if (sndEmail && !doNotSendEmail) {
            if (recipients==null || recipients.trim().length()==0) {
                rtn = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Recipient email address is required'));
            }
            if (subject==null || subject.trim().length()==0) {
                rtn = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Email subject is required'));
            }
            if (message==null || message.trim().length()==0) {
                rtn = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Email message is required'));
            }
        }
        
        System.debug('Valid conversion request = ' + ((rtn)?'true':'false'));
        return rtn;
    }
    

    // convert
    // converts a lead, creating one or more of the following:
    //    account, contact, opportunity, solution opportunity, sales appointment, open task, email notification
    //------------------------------------------------------------------
    public PageReference convert() {
    	MonitorExecution mon = new MonitorExecution('LeadConversion');	// BLL27a
		mon.log('Convert lead: ' + leadRcd.Name + ' (' + leadRcd.Id + ')');
    	
        PageReference pageref = null;
        List<String> recipientList = new List<String>();
        boolean isPersonAcct = procRcdTypeMap.get(procRcdTypeId)=='PersonAccount';
        Account acct = null; 

        System.debug('Convert()');
        //System.debug(leadRcd);
		System.debug(acctNameOptions);
		System.debug(accountSelection);

        // if edit-checks don't pass, stay on page!
        if (!validConversionRequest()) {
            return pageref;
        }

        Savepoint sp1 = Database.setSavepoint();

		Database.DMLOptions dml = new Database.DMLOptions();
		if (overrideDuplicateMatching) dml.DuplicateRuleHeader.AllowSave = true; 
		mon.log('Override Duplicate Matching: ' + (overrideDuplicateMatching ? 'true':'false'));

        try { // big block to catch any errors & echo on-screen 
            
            // In the event a lead is still owned by a queue, re-assign
            // Watch out! updating a lead can cause a workflow to start, which will prevent the conversion!
            //if (leadRcd.OwnerId!=owner.Id) {
            //    leadRcd.OwnerId = owner.Id;
            //    update(leadRcd);
            //}
            if (leadRcd.Status!='Qualified') {
                leadRcd.Status = 'Qualified';
                if (isPersonAcct && leadRcd.Company!=null) {
                	leadRcd.Company=null;
                }
                update(leadRcd);
                mon.log('Lead updated to Qualified: ' + leadRcd.Id);	// BLL27a
            } 
            
            // future TODO: use lead mapping definition?
            
            // Create (or assign to) an account (all)
            //if (crtAccount) {
                System.debug('Account selection = ' + accountSelection);
                mon.log('Account selection = ' + accountSelection);	// BLL27a
                if (accountSelection==null || accountSelection.length()==0) {
                    account.Phone = leadRcd.Phone;
                    account.RecordTypeId = procRcdTypeId;
                    account.OwnerId = newowner.Id;
                    if (isPersonAcct) {  
                        System.debug('Person account');
                        isPersonAcct = true;
                        account.FirstName = leadRcd.FirstName;
                        account.LastName = leadRcd.LastName;
                        account.PersonHomePhone = leadRcd.Phone;
                        account.PersonMobilePhone = leadRcd.MobilePhone;
                        account.PersonLeadSource = leadRcd.LeadSource;
                        account.AccountSource = leadRcd.LeadSource;	// BLL12a
                        account.PersonMailingStreet = leadRcd.Street;
                        account.PersonMailingCity = leadRcd.City;
                        account.PersonMailingState = leadRcd.State;
                        account.PersonMailingPostalCode = leadRcd.PostalCode;
                        account.PersonMailingCountry = leadRcd.Country;
                        account.pi__campaign__pc = leadRcd.pi__campaign__c;
                        account.pi__comments__pc = leadRcd.pi__comments__c;
                        account.pi__conversion_date__pc = leadRcd.pi__conversion_date__c;
                        account.pi__conversion_object_name__pc = leadRcd.pi__conversion_object_name__c;
                        account.pi__conversion_object_type__pc = leadRcd.pi__conversion_object_type__c;
                        account.pi__created_date__pc = leadRcd.pi__created_date__c;
                        account.pi__first_activity__pc = leadRcd.pi__first_activity__c;
                        account.pi__first_touch_url__pc = leadRcd.pi__first_touch_url__c;
                        account.pi__first_search_term__pc = leadRcd.pi__first_search_term__c;
                        account.pi__first_search_type__pc = leadRcd.pi__first_search_type__c;
                        account.pi__grade__pc = leadRcd.pi__grade__c;
                        account.pi__last_activity__pc = leadRcd.pi__last_activity__c;
                        account.pi__notes__pc = leadRcd.pi__notes__c;
                        account.pi__score__pc = leadRcd.pi__score__c;
                        account.pi__url__pc = leadRcd.pi__url__c;
                    } else {
                        System.debug('NOT Person account');
                        if (leadRcd.Company!=null && leadRcd.Company.length()>0) {
                            account.Name = leadRcd.Company;
                        } else {
                            account.Name = newAcctName;
                        }
                        account.AccountSource = leadRcd.LeadSource;	// BLL12a
                        account.BillingStreet = leadRcd.Street;
                        account.BillingCity = leadRcd.City;
                        account.BillingState = leadRcd.State;
                        //System.debug('leadRcd state='+leadRcd.State);
                        //System.debug('Set billing state to ' + account.BillingState);
                        account.BillingPostalCode = leadRcd.PostalCode;
                        account.BillingCountry = leadRcd.Country;
                    }
                    account.dtffa__Chair_Brand__c = leadRcd.Chair_Brand__c;
                    account.dtffa__Chair_Model__c = leadRcd.Chair_Model__c;
                    account.dtffa__End_User__c = leadRcd.End_User__c;
                    account.dtffa__Physical_Challenge__c = leadRcd.Physical_Challenge__c;
	                account.Veteran__c = leadRcd.Veteran__c;
                    //System.debug(account);
                    //BLL23d insert(account);
                    // BLL23a
					Database.SaveResult sr = Database.insert(account, dml);	// BLL20c
					mon.log('Account created: ' + account.Id);	// BLL27a
					for(Database.Error e : sr.getErrors()) {	
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                        mon.log('Error creating account: ' + e.getMessage());	// BLL27a
                        throw new LeadConversionException( 'Unable to create account -- possibly a duplicate.');
					}
					// BLL23a end
                    
                    
                    // Re-read account
                    acct = [ select Id, Name, Store_Location__c, isPersonAccount, PersonContactId, RecordType.Name	// BLL21c add recordtype.name 
                          from Account 
                          where Id=:account.Id 
                          limit 1
                    ];
                    
                } else {
                    try {
                        acct = [ select Id, Name, Store_Location__c, isPersonAccount, PersonContactId, RecordType.Name	// BLL21c add recordtype.name 
                                    from Account 
                                    where Id=:accountSelection
                        ];
                    } catch(Exception e) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid account selection'));
                        return null;
                    }
                    mon.log('Account: ' + JSON.serialize(acct));	// BLL27a
                }
            //}
            
            System.debug(acct);

            // Create contact (unless it's a person account--retail)
            if (crtAccount && !isPersonAcct) {
                contact = new Contact();
                contact.AccountId = acct.Id;
                contact.OwnerId = newowner.Id;
                contact.FirstName = leadRcd.FirstName;
                contact.LastName = leadRcd.LastName;
                contact.HomePhone = leadRcd.Phone;
                contact.MobilePhone = leadRcd.MobilePhone;
                contact.LeadSource = leadRcd.LeadSource;
                contact.MailingStreet = leadRcd.Street;
                contact.MailingCity = leadRcd.City;
                contact.MailingState = leadRcd.State;
                contact.MailingPostalCode = leadRcd.PostalCode;
                contact.MailingCountry = leadRcd.Country;
                contact.pi__campaign__c = leadRcd.pi__campaign__c;
                contact.pi__comments__c = leadRcd.pi__comments__c;
                contact.pi__conversion_date__c = leadRcd.pi__conversion_date__c;
                contact.pi__conversion_object_name__c = leadRcd.pi__conversion_object_name__c;
                contact.pi__conversion_object_type__c = leadRcd.pi__conversion_object_type__c;
                contact.pi__created_date__c = leadRcd.pi__created_date__c;
                contact.pi__first_activity__c = leadRcd.pi__first_activity__c;
                contact.pi__first_touch_url__c = leadRcd.pi__first_touch_url__c;
                contact.pi__first_search_term__c = leadRcd.pi__first_search_term__c;
                contact.pi__first_search_type__c = leadRcd.pi__first_search_type__c;
                contact.pi__grade__c = leadRcd.pi__grade__c;
                contact.pi__last_activity__c = leadRcd.pi__last_activity__c;
                contact.pi__notes__c = leadRcd.pi__notes__c;
                contact.pi__score__c = leadRcd.pi__score__c;
                contact.pi__url__c = leadRcd.pi__url__c;

                contact.Decision_Maker__c = leadRcd.Decision_Maker__c;
                
                //leadRcd.Client_in_Chair_Weight__c;
                //leadRcd.Claim__c;

				if (String.isBlank(contactSelection))	{ // BLL24a create new contact                
                	//insert(contact);
                    // BLL23a
					Database.SaveResult sr2 = Database.insert(contact, dml);	// BLL20c
					mon.log('Contact created: ' + contact.Id);	// BLL27a
					for(Database.Error e : sr2.getErrors()) {	
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                        mon.log('Error creating contact: ' + e.getMessage());	// BLL27a
                        throw new LeadConversionException( 'Unable to create contact -- possibly a duplicate.');
					}
					// BLL23a end
				} else {	// BLL24a
					contact.Id = contactSelection;	// BLL24a use selected contact instead
				}	// BLL24a
				mon.log('Contact id: ' + contact.Id); // BLL27a                
            }
            
            // Insert note (if any)
            Task webnotes = null;
            String pardotdata = PardotFieldsToText(leadRcd.Id);
            if (pardotdata.trim().length()>0) {
            	webnotes = new Task();
            	webnotes.ActivityDate = Date.today();
            	webnotes.Status = 'Completed';
            	webnotes.Subject = 'Website form information';
            	webnotes.OwnerId = newowner.Id;
                webnotes.Description = pardotdata;
                if (isPersonAcct) {
                	webnotes.WhoId = acct.PersonContactId;
                } else {
                	webnotes.WhoId = contact.Id;
                }
            	insert(webnotes);
            }
            // Email lead content
            Task emailnotes = null;
            if (!String.isBlank(leadRcd.Email_Lead_Content__c)) {
            	emailnotes = new Task();
            	emailnotes.ActivityDate = Date.today();
            	emailnotes.Status = 'Completed';
            	emailnotes.Subject = 'Email lead information';
            	emailnotes.OwnerId = newowner.Id;
                emailnotes.Description = leadRcd.Email_Lead_Content__c;
                if (isPersonAcct) {
                	emailnotes.WhoId = acct.PersonContactId;
                } else {
                	emailnotes.WhoId = contact.Id;
                }
            	insert(emailnotes);
            }
            
            // Solution opportunity (retail)
            // BLL10d if (crtSolutionOpportunity) {
            if (crtSolutionOpportunity && !doNotCreateSolutionOpportunity) {  // BLL10a
                System.debug('Solution opportunity name='+solOpp.Name);

    			Map<String, Schema.RecordTypeInfo> SlopRcdTypes = Schema.SObjectType.dealer__Sales_Up__c.getRecordTypeInfosByName();	// BLL21a
				solOpp.RecordTypeId = SlopRcdTypes.get('Retail').getRecordTypeId();	// BLL21a
				if (acct.RecordType.Name=='Commercial') solOpp.RecordTypeId = SlopRcdTypes.get('Commercial').getRecordTypeId();	// BLL21a

                solOpp.OwnerId = newowner.Id;
                solOpp.dealer__Salesperson_1__c = newowner.Id; // BLL10a
                //BLL9d solOpp.BDC_Created__c = owner.Profile.Name.contains('BDC');
                //BLL9d if (solOpp.BDC_Created__c) {
				if (currentUser.Profile.Name.contains('BDC') || (leadOwnerUser!=null && leadOwnerUser.Profile.Name.contains('BDC'))) { // BLL9a
                	solOpp.BDC_Created__c = true; // BLL9a
                    solOpp.dealer__CCC_Rep__c = UserInfo.getUserId(); 
                }
                
                solOpp.dealer__Customer_Account__c = acct.Id;
                solOpp.dealer__Source__c = leadRcd.LeadSource;
                solOpp.dealer__Comments__c = sNull(leadRcd.Description);
                solOpp.Company__c = location.Id;
                solOpp.dealer__Company_Number__c = location.dealer__Company_Number__c;
                // BLL2a
                if (leadRcd.Email_Lead_Content__c!=null) {
                    solOpp.dealer__Comments__c += '\n' + sNull(leadRcd.Email_Lead_Content__c);
                } 
                if (pardotdata.trim().length()>0) {
                    solOpp.dealer__Comments__c += '\n' + pardotdata;
                }
                // BLL2a end
                solOpp.dealer__Lead_Type__c = leadRcd.Lead_Type__c;
                solOpp.dealer__Lead_Status__c = 'Pending';
                if (acct.personContactId!=null) {
                	solOpp.dealer__Buyer_Contact__c = acct.personContactId;
                	solOpp.BuyerContact__c = acct.personContactId;
                } else {
                    solOpp.dealer__Buyer_Contact__c = contact.Id;
                    solOpp.BuyerContact__c = contact.Id;
                }
				// BLL31
				solOpp.Price_point__c = leadRcd.Price_point__c;
				// BLL31
                // Default decision date +30 days
                SolOpp.Decision_Date__c = Date.today().addDays(30);	// BLL20a
                insert(SolOpp);
                mon.log('Created solution opportunity: ' + JSON.serialize(Solopp));	// BLL27a
            }
    
            // Sales appointment for solution opportunity (retail)
            //BLL10d if (crtSolutionOpportunity && crtSalesAppointment && !doNotCreateSalesAppointment) {
            if (crtSolutionOpportunity && !doNotCreateSolutionOpportunity  
                && crtSalesAppointment && !doNotCreateSalesAppointment) {  // BLL10a
                salesAppointment.OwnerId = newowner.Id;
                salesAppointment.dealer__Assigned_To__c = newowner.Id;
                salesAppointment.dealer__Sales_Up__c = solOpp.Id;
                
                Timezone currenttz = UserInfo.getTimeZone();
                Timezone targettz = Timezone.getTimeZone(owner.TimeZoneSidKey);
                System.debug('Owner timezone=' + owner.TimeZoneSidKey);
                DateTime dt = DateTime.newInstance(salesAppointment.dealer__Date__c, salesAppointmentTime);
                System.debug('DateTime=' + dt.format('yyyy-MM-dd HH:mm:ss z'));
                System.debug('Timezone=' + currenttz.getID() + ' offset seconds=' + String.valueOf(currenttz.getOffset(dt)/1000));
                System.debug('Timezone=' + targettz.getID() + ' offset seconds=' + String.valueOf(targettz.getOffset(dt)/1000));
                dt = dt.AddSeconds((currenttz.getOffset(dt)-targettz.getOffset(dt))/1000);
                //dt = DateTime.newInstanceGMT(dt.yearGMT(), dt.monthGMT(), dt.dayGMT(), dt.hourGMT(), dt.minuteGMT(), dt.secondGMT());
                System.debug('DateTime=' + dt.format('yyyy-MM-dd HH:mm:ss z'));
                
                salesAppointment.dealer__Time__c = dt.format('hh:mm a', targettz.getID());
                salesAppointment.dealer__DateTime__c = dt;
                salesAppointment.dealer__Customer__c = contact.Id;
                salesAppointment.dealer__Set_By__c = UserInfo.getUserId();	// BLL13a
                if (isPersonAcct) {
                    salesAppointment.dealer__Customer__c = acct.PersonContactId;
                }
                System.debug(salesAppointment);
                insert(salesAppointment);
                mon.log('Created sales appointment: ' + JSON.serialize(salesAppointment));	// BLL27a
            }
    
            // Opportunity (Commercial & TransitWorks)
            if (crtOpportunity && !doNotCreateOpportunity) {
                System.debug('Opportunity name='+opportunity.Name);
                opportunity.AccountId = acct.Id;
                opportunity.Description = leadRcd.Description;
                opportunity.LeadSource = leadRcd.LeadSource;
                opportunity.OwnerId = newowner.Id;
                insert(opportunity);
                mon.log('Created opportunity: ' + JSON.serialize(opportunity));	// BLL27a
            }
    
            // Task (followup task - commercial & TransitWorks)        
            if (crtTask && !doNotCreateTask) {
            	// BLL3 begin supply Who & What on task
                if (isPersonAcct) {
                	task.WhoId = acct.PersonContactId;
                } else {
                	task.WhoId = contact.Id;
                }
                //BLL10d if (crtSolutionOpportunity) {
                if (crtSolutionOpportunity && !doNotCreateSolutionOpportunity) {  // BLL10a
                	task.WhatId = solOpp.Id;
                } else if (crtOpportunity && !doNotCreateOpportunity) {
                	task.WhatId = opportunity.Id;
                }
            	// BLL3 end supply Who & What on task
                task.OwnerId = newowner.Id;
                insert(task);
                mon.log('Created follow up task ' + JSON.serialize(task));	// BLL27a
            }
    
            // Email notification prep
            if (sndEmail && !doNotSendEmail) {
                recipientList = recipients.split(';');
            }
    
            // Convert lead!
            // If converting to a business account, must first update lead with company name!
            // This is a problem because it launches workflows that prevent the conversion process.
            // Creating a new save point seems to allow the conversion to succeed without generating 
            // an "Unable to obtain exclusive use of a record" error. 
            Savepoint sp2 = Database.setSavepoint();
            try {
                System.debug('Account id=' + account.Id + '; contact id=' + contact.Id + '; contact parent id=' + contact.AccountId);
				System.debug('Acct id='+acct.Id);
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(leadRcd.Id);
                LeadStatus convertStatus = [select Id, MasterLabel from LeadStatus where IsConverted=true limit 1];
                lc.setConvertedStatus(convertStatus.MasterLabel);
                lc.setAccountId(acct.Id);
                if (isPersonAcct) {
                	System.debug('Person contact='+acct.PersonContactId);
                    lc.setContactId(acct.PersonContactId);
                } else {
                	System.debug('Contact='+acct.PersonContactId);
                    lc.setContactId(contact.Id);
                }
                //lc.setDoNotCreateOpportunity(!crtOpportunity);  // Already created manually, so don't create here!
                //if (!crtOpportunity || doNotCreateOpportunity) lc.setDoNotCreateOpportunity(true);  // Already created manually, so don't create here!
                lc.setDoNotCreateOpportunity(true);	// handled manually
                Database.LeadConvertResult lcr = Database.convertLead(lc, dml);	// BLL23c
				System.debug(lcr);

/*Database.LeadConvertResult[
getAccountId=null;getContactId=null;
getErrors=(Database.Error[
getFields=();
getMessage=We can't convert this lead because some values are restricted on the contact, account, or opportunity. Ask your admin to check the field mappings.;
getStatusCode=INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST;
]);
getLeadId=00Q5000001JfnH5EAJ;getOpportunityId=null;isSuccess=false;]
*/
				// Handle lead conversion process errors & echo back error message
				List<Database.Error> lcerrs = lcr.getErrors();
				if (lcerrs!=null && lcerrs.size()>0) {
					String errmsgs = '';
					for(Database.Error err : lcerrs) {
						errmsgs += err.getStatusCode() + ' : ' + err.getMessage() + ' [' + String.join(err.getFields(), ',') + ']; ';
					}
					throw new LeadConversionException( 'Unable to convert lead: ' + errmsgs);
				}

				// BLL16a - copy influencer records! 
				// BLL29c change InfluencerAssociation__c to InfluencerAssociation2__c and account/contact field names
				Map<String, Schema.RecordTypeInfo> IARcdTypes = Schema.SObjectType.InfluencerAssociation2__c.getRecordTypeInfosByName();
				Schema.RecordTypeInfo LeadIaRti = IARcdTypes.get('Lead');
				Schema.RecordTypeInfo AcctIaRti = IARcdTypes.get('Account');
				Id LeadIaRtId = LeadIaRti.getRecordTypeId();
				Id AcctIaRtId = AcctIaRti.getRecordTypeId();
				List<InfluencerAssociation2__c> ialist = new List<InfluencerAssociation2__c>();
				if (lcr.getAccountId()!=null) ialist = [
					select Id, RecordTypeId, InfluencedLead__c, InfluencerAccount__c, InfluencerContact__c
					from InfluencerAssociation2__c
					where RecordTypeId=:LeadIaRtId and InfluencedLead__c=:leadRcd.Id	// was :lcr.getAccountId()
				];
				System.debug(ialist);
				List<InfluencerAssociation2__c> newialist = new List<InfluencerAssociation2__c>();
				for(InfluencerAssociation2__c ia : ialist) {
					newialist.add(new InfluencerAssociation2__c(
						RecordTypeId=AcctIaRtId, 
						InfluencedAccount__c=acct.Id,	// Influenced account
						InfluencerAccount__c=ia.InfluencerAccount__c,	// influencer Account
						InfluencerContact__c=ia.InfluencerContact__c	// influencer Contact
					));
				}
				System.debug(newialist);
				//Database.insert(newialist);
				Database.insert(newialist, false);
				// BLL16a end

                // Email notification (retail Rental, Commercial, TransitWorks)
                if (sndEmail && !doNotSendEmail) {
                    System.debug('Recipients: ' + String.join(recipientList, ','));
                    String sentto = 'Sent to: ' + String.join(recipientList, ';');  // BLL6a
                    sendNotification(recipientList, subject, message);
	                mon.log('Sent email (' + subject + ') to: ' + JSON.serialize(recipientList));	// BLL27a
                    // log email sent
                    Task t = new Task(ActivityDate = Date.today(), WhoId=lc.getContactId(),
                         Subject='Email sent ' + subject, 
                         Description = sentto + '\n\n' + message,  // BLL6c
                         Status='Completed');
                    insert(t);
	                mon.log('Created task about sending an email: ' + JSON.serialize(t));	// BLL27a
                }

                // Normal completion
                pageref = new ApexPages.StandardController(account).view();
                pageref.setRedirect(true);

            } catch(Exception e2) {
                Database.rollback(sp1); // undo ALL changes!
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to convert lead ' 
                                     + e2.getTypeName() + ': ' + e2.getMessage()));
                pageref = null;  // abnormal completion
                mon.log('Error: ' + e2.getMessage());	// BLL27a
            }

        } catch(Exception e) {
            Database.rollback(sp1); // undo any changes!
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to create required objects ' 
                                 + e.getTypeName() + ': ' + e.getMessage()));
            pageref = null;  // abnormal completion
            mon.log('Error: ' + e.getMessage());	// BLL27a
        }
        if (mon.AlwaysNotify) mon.notifyAdmin();	// BLL27a
        
        // end transaction
        return pageref;
    }


    // Send the notification email
    //------------------------------------------------------------------
    public void sendNotification(List<String> recipientList, String subject, String message) {
    	try {
	        Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
	        mail.setToAddresses(recipientList);
	        mail.setSubject(subject);
	        mail.setPlainTextBody(message);
	        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    	} catch(Exception emailErr) {
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
    		     'Unable to send email. Please notify the ITHelp: ' + emailErr.getMessage()));
    	}       
    }


    // BLL15d findInArcadium
    //------------------------------------------------------------------
    //private void findInArcadium() {
    //    String searchCriteria = '';
    //    String cat = '';
    //    String searchName = '';
    //    String searchPhone = '';
    //    String searchEmail = '';
    //    
    //    if (leadRcd!=null) {
    //        if (!String.isBlank(leadRcd.Name)) {
    //            searchName = leadRcd.Name;
    //        }
    //        if (!String.isBlank(leadRcd.Phone)) {
    //            searchPhone = leadRcd.Phone.replaceAll( '\\s+', '').replaceAll('[\\(\\)-]', '');
    //        }
    //        if (!String.isBlank(leadRcd.MobilePhone)) {
    //            if (!String.isBlank(searchPhone)) {
    //                searchPhone += ' or ';
    //            }
    //            searchPhone = leadRcd.MobilePhone.replaceAll( '\\s+', '').replaceAll('[\\(\\)-]', '');
    //        }
    //        if (!String.isBlank(leadRcd.Email)) {
    //            searchEmail = leadRcd.Email.trim();
    //        }
    //    }
    //    if (!String.isBlank(searchName)) {
    //        searchCriteria += cat + searchName;
    //        cat = ' or ';
    //    }
    //    if (!String.isBlank(searchPhone)) {
    //        searchCriteria += cat + searchPhone;
    //        cat = ' or ';
    //    }
    //    if (!String.isBlank(searchEmail)) {
    //        searchCriteria += cat + searchEmail;
    //        cat = ' or ';
    //    }
    //    
    //    List<List<sObject>> soslResults = [FIND :searchCriteria IN ALL FIELDS 
    //         RETURNING ArcadiumRef__c (Alternate_email__c, Name, Cell_phone__c, Email__c, Home_phone__c, 
    //                                   Work_phone__c, Arcadium_key__c, MW_Id__c) 
    //         LIMIT 50];
    //    arcadiumMatches = (List<ArcadiumRef__c>)soslResults[0];
    //}

    // BLL5a add block
    // Send Email Only
    //------------------------------------------------------------------
    public PageReference sendEmailOnly() {
        PageReference pageref = null;
        List<String> recipientList = new List<String>();

        // Email notification prep
        if (sndEmail && !doNotSendEmail) {
            recipientList = recipients.split(';');
        }
    
        // Don't send to Arcadium! insertIntoArcadium(leadRcd);
        // lead is qualified, but not converted
        leadRcd.Status = 'Qualified';
        update(leadRcd);
        //pageref = new PageReference(retURL);
        //pageref.setRedirect(true);

        // Email notification (retail Rental, Commercial, TransitWorks)
        if (sndEmail && !doNotSendEmail) {
            System.debug('Recipients: ' + String.join(recipientList, ','));
            String sentto = 'Sent to: ' + String.join(recipientList, ';');  // BLL6a
            sendNotification(recipientList, subject, message);
            // BLL4a begin
            // log email sent 
            Task t = new Task(ActivityDate = Date.today(), WhoId=leadRcd.Id, 
                    Subject='Email sent ' + subject, 
                    Description = sentto + '\n\n' + message,   // BLL6c
                    Status='Completed');
            insert(t);
            // BLL4a end
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
    		     'Email sent and logged.'));
        } else {
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
    		     'No message to send'));
        }

        return pageref;
    }
    // BLL5a end block

    // Send to Arcadium
    //------------------------------------------------------------------
    public PageReference sendToArcadium() {
        PageReference pageref = null;
        List<String> recipientList = new List<String>();

        // Email notification prep
        if (sndEmail && !doNotSendEmail) {
            recipientList = recipients.split(';');
        }
    
        insertIntoArcadium(leadRcd);
        // lead is qualified, but not converted
        leadRcd.Status = 'Qualified';
        leadRcd.SentToArcadium__c = true; // BLL9a
        update(leadRcd);
        //pageref = new PageReference(retURL);
        //pageref.setRedirect(true);

        // Email notification (retail Rental, Commercial, TransitWorks)
        if (sndEmail && !doNotSendEmail) {
            System.debug('Recipients: ' + String.join(recipientList, ','));
            String sentto = 'Sent to: ' + String.join(recipientList, ';');  // BLL6a
            sendNotification(recipientList, subject, message);
            // BLL4a begin
            // log email sent 
            Task t = new Task(ActivityDate = Date.today(), WhoId=leadRcd.Id, 
                    Subject='Email sent ' + subject, 
                    Description = sentto + '\n\n' + message,  // BLL6c
                    Status='Completed');
            insert(t);
            // BLL4a end
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
    		     'Email sent and logged.')); // BLL5a 
        }

        return pageref;
    }


    // Copied from original LeadConversion.cls
    //------------------------------------------------------------------
    public PageReference insertIntoArcadium(Lead l) {
        Lead leadRecord = null;
        leadRecord = [
             select Id, Name, FirstName, LastName, Street, City, State, PostalCode, 
                    Phone, MobilePhone, Email, Description, LeadSource, Desired_Vehicles__c, Vehicle_Preference__c, 
                    Rental_pickup_location__c, Rental_pick_up__c, Rental_drop_off__c, RentalDiscountCode__c,  
                    Van_year__c, Van_make__c, Van_model__c, Van_VIN__c, Van_odometer__c,
                    Currently_own__c, Contact_availability__c, Vehicle_information__c, 
                    Nearest_Location__c, Referral_method__c, Visited_a_store__c, Email_Lead_Content__c
             from Lead
             where Id=:l.Id
             limit 1
        ];  
        // BLL1 begin
        String phone = normalizePhoneNbr(sNull(leadRecord.Phone));
        String details = '';
        details = sNull(leadRecord.Description) + '\n';
        details += PardotFieldsToText(leadRecord.Id) + '\n';
        if (leadRecord.Email_Lead_Content__c!=null && leadRecord.Email_Lead_Content__c.length()>0) {
        	details += leadRecord.Email_Lead_Content__c;
        }
        // BLL1 end
        
        // Send to Arcadium, but NOT when running from a sandbox!
        String response=null;
        Organization org = [select Id, IsSandbox from Organization limit 1];
        if (!org.isSandbox && !Test.isRunningTest()) {
            ArcadiumWebService.Service1Soap aws = new ArcadiumWebService.Service1Soap();
            response = aws.CreateLeadRecord( 
                     sNull(leadRecord.LeadSource), sNull(leadRecord.FirstName), sNull(leadRecord.LastName), sNull(leadRecord.Street), 
                     sNull(leadRecord.City), sNull(leadRecord.State), sNull(leadRecord.PostalCode), phone, sNull(leadRecord.Email),
                     details, 0, sNull(leadRecord.Desired_Vehicles__c));  
        } else {
            response = 'success';
        }
        if(response=='success') {
            if (org.isSandbox) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Sandbox does not send to Arcadium'));
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Saved to Arcadium'));
            }
            //return null;
            Task t = new Task( WhoId = leadRecord.Id, ActivityDate = Date.today(),
                               Subject='Sent to Arcadium', 
                               Status='Completed' );
            insert(t);
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
    		     'Lead sent to Arcadium.')); // BLL5a
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to Save to Arcadium : '+response));
        }       
        return null;
    }


    // BLL1 add normalize phone
    //------------------------------------------------------------------
    public String normalizePhoneNbr(String phone) {
        String p = phone.deleteWhitespace();
        String tmp = p.replaceAll('[\\(\\)-\\.]','');
        if (tmp.length()==10) {
           p = '(' + tmp.substring(0,3) + ')' + tmp.substring(3,6) + '-' + tmp.substring(6);
        }
        return p;       
    }
    // BLL1 end


    // Simplify converting null strings to empty strings
    //------------------------------------------------------------------
    public static String sNull(String s) {
        return (s==null) ? '' : s;
    }
    
    
    // dummyFunction
    // no action, used to activate rerender of screen when checkboxes
    // are clicked
    //------------------------------------------------------------------
    public void dummyFunction() { }
        
    // PardotFieldsToText
    //------------------------------------------------------------------
    public static String PardotFieldsToText(Id leadId) {
        String s = '';
        Lead l = null;
        try {
	    	l = [select Vehicle_preference__c, Rental_pickup_location__c, Rental_pick_up__c, Rental_drop_off__c, RentalDiscountCode__c,  
	    	            Desired_Vehicles__c,
	    	            Van_year__c, Van_make__c, Van_model__c, Van_VIN__c, Van_odometer__c, Currently_own__c, Contact_availability__c, 
	    	            Nearest_location__c, Referral_method__c, Visited_a_store__c, Vehicle_information__c
	    	     from Lead
	    	     where Id=:leadId
	    	     limit 1
	    	];
        } catch(Exception leadErr) {}
 
        /* Buy */
        if (l.Desired_Vehicles__c!=null) {
        	s += 'Interested in stock number(s): ' + l.Desired_Vehicles__c + '\n\n';
        }
        
        /* Rent */
        if (l.Rental_pick_up__c != null) {
        	s += 'Rent: ' + sNull(l.Vehicle_preference__c) + ' from location ' + sNull(l.Rental_pickup_location__c) + '; '
        	   + 'pick up ' + ((l.Rental_pick_up__c!=null) ? l.Rental_pick_up__c.format() : '') + ' '  
        	   + 'drop off ' + ((l.Rental_drop_off__c!=null) ? l.Rental_drop_off__c.format() : '') + ' '
        	   + (!String.isBlank(l.RentalDiscountCode__c) ? ('Discount code: ' + l.RentalDiscountCode__c) : '') + ' '  // BLL8a
        	   + '\n\n';
        }
        
        /* Sell */
        if (l.Van_year__c!=null) {
        	s += 'Sell: ' + l.Van_year__c + ' '  + sNull(l.Van_make__c) + ' ' + sNull(l.Van_model__c) + ' '
        	   + 'VIN ' + sNull(l.Van_VIN__c) + '; ' + sNull(l.Van_odometer__c) + ' miles; '
        	   + 'Currently own ' + sNull(l.Currently_own__c) + '; '
        	   + 'Contact availability ' + sNull(l.Contact_availability__c) + '\n\n';
        }
        
        /* Trade */
        if (l.Nearest_location__c!=null) {
        	s += 'Trade: ' + ' Close to ' + sNull(l.Nearest_location__c) + ' store; ' + 'Referred by ' + sNull(l.Referral_method__c) + '; '
        	   + 'Visited a store ' + sNull(l.Visited_a_store__c) + '; ' +
        	   + 'Vehicle information ' + sNull(l.Vehicle_information__c) + '; ' + sNull(l.Van_odometer__c) + ' miles ' + '\n\n';  
        }
        
        /* Toyota Spring Sale */
        if (l.Vehicle_preference__c != null && l.Rental_pick_up__c == null) {
        	s += 'Toyota Spring Sales Event: ' + l.Vehicle_preference__c + '\n\n';
        }
        	
        return s;
    }

	// BLL11a
	// getSimilarAccounts
	public void findSimilarAccounts() {
		List<Account> accts = new List<Account>();
		List<String> keywords = new List<String>();
		if (leadRcd.Phone!=null) keywords.add(leadRcd.Phone);
		if (leadRcd.Email!=null) keywords.add(leadRcd.Email);
		String joinstr = ' OR ';
		if (keywords.size()==0) {
			if (leadRcd.FirstName!=null) keywords.add(leadRcd.FirstName);
			if (leadRcd.LastName!=null) keywords.add(leadRcd.LastName);
		}
		String findstr = String.join(keywords, joinstr);
		String sosl = 'FIND \'' + String.escapeSingleQuotes(findstr.trim()) + '\' IN ALL FIELDS '
			+ ' RETURNING Account(Id, Name, RecordType.Name, Phone, dealer__PersonMobilePhone__c, dealer__PersonEmail__c, BillingStreet, BillingCity, BillingState, BillingPostalCode) '
			+ ' LIMIT 7 ';
		System.debug(sosl);
		try {
			List<List<SObject>> soslrs = search.query(sosl);
			if (soslrs.size()>0) accts = (List<Account>) soslrs[0];
		} catch(Exception e) { }
		similarAccounts = new List<AccountWrapper>();
		for(Account a : accts) similarAccounts.add(new AccountWrapper(a));
		foundSimilarAccounts = similarAccounts.size()>0;
	}
	
	public class AccountWrapper {
		public Id AccountId {get;set;}
		public String Name {get;set;}
		public String RecordTypeName {get;set;}
		public String Phone {get;set;}
		public String MobilePhone {get;set;}
		public String Email {get;set;}
		public String Street {get;set;}
		public String City {get;set;}
		public String State {get;set;}
		public String PostalCode {get;set;}
		public AccountWrapper(Account a) {
			AccountId = a.Id;
			Name = a.Name;
			RecordTypeName = a.RecordType.Name;
			Phone = a.Phone;
			MobilePhone = a.dealer__PersonMobilePhone__c;
			Email = a.dealer__PersonEmail__c;
			Street = a.BillingStreet;
			City = a.BillingCity;
			State = a.BillingState;
			PostalCode = a.BillingPostalCode;
		}
	}
	// BLL11a end

	public class LeadConversionException extends Exception {}

}