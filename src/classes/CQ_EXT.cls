/* CQ_EXT - copied from QC_EXT
 * Tested by: CQ_EXT_TEST
 * 
 *  2015-03-30  BLL1    emailPDFDirect to allow for multiple email addresses separated by ';'
 *  2015-05-03  BLL3    GPC or Fleet Code & Tax Id now referenced from customer automatically.
 *  2015-08-20  BLL4    Try-catch block around emailDPFDirect for error handling.
 *  2015-12-01  BLL5    Don't allow creation w/out an opportunity. They're able to create from account related lists.
 *  2016-01-12  BLL6    IT18388 Function for marking a quote lost.
 *  2016-02-23  BLL7    Add ability to sell stock commercial vehicles, lock the stock installed options.
 *                      Also add keyword search to chassis options.
 *  2016-03-22  RT1     Added logic to deal with advanced vehicle search requests
 *  2016-04-13	BLL8	Support releasing dealer account lookup field; get report id for quote costs; update misc description;
 *	2016-04-10	BLL9	IT#23675 - Add location address to quote, clone should set status to pending.
 *	2016-04-25	BLL10	Set service manager and sales admin from location (if not set already)
 *  2016-04-27	BLL11	IT#24094 - Recap needs to show discount (was showing deposit)
 *	2016-04-28	BLL12	Changes to support paperwork.
 *	2016-05-09	BLL13	IT#24586 - When adding a stock unit to a quote, remove redundant options (previously not locked, now as a locked/stock option).
 *						Also, ignore error trying to update Quote_Emailed__c when quote is locked for editing.
 *	2016-05-12	BLL14	Remove reference to status__c from opportunity object in SOQL. Using only StageName.
 *	2016-05-12	BLL15	Need billing (account) name for bill-of-sale forms.
 *	2016-05-13	BLL16	Add type of sale field (Releasing Dealer, Used, Customer owned). If vehicle has a releasing
 *						dealer, set value to "Releasing Dealer" and protect it whenever there is a releasing dealer on the quote.
 *	2016-05-17	BLL17	Adjustments to not lose chassis when selecting a vehicle that isn't complete with comm quote options.
 *	2016-05-18	BLL18	IT#25172 - support for different emails (pdf to customer, invoice to releasing dealer)
 *	2016-05-20	BLL19	Need color from vehicle inventory object and ensure it's available on quote too.
 *  2016-06-06	BLL20	Adjust BLL13 to just change the commercial quote line "Locked__c" flag when vehicle added to quote.
 *	2016-06-07	BLL21	Add location's GM to the commercial quotes - for approval process.
 *	2016-06-09	BLL22	Default inbound freight cost to $500 on new quotes and protect field.
 *	2016-06-09	BLL23	Allow "doctype=i" parameter to print "Invoice" instead of "Quote" on the CQ PDF.
 *	2016-06-16	BLL24	When a vehicle is added, put the total conversion cost in the chassis option and zero out the other
 *						stock option costs. When non-posted quote is opened, check conversion cost of the vehicle and do the same.
 *	2016-06-21	BLL25	Don't clear out option costs; rather, switch GP & commissions from using options costs to conversion cost when
 *						quote is delivered (and has a vehicle on it). 
 *						Flag when unit gross changed in batch to trigger info message on next view (until cleared when saved).
 *	2016-07-14	BLL26	Undo BLL22 (default $500 freight & protect)
 * 	2016-07-19	BLL27	ReleasingDealerCollectsTax flag support, default Taxable flag to true, if customer is exempt, set taxable
 *						flag to false and protect it. If taxable flag is set, require tax estimate amount.
 *	2016-08-08	BLL28	B. Leaman IT#30469 - show sections on quote if there are items in the section even if there are
 *						no items that can be added (mfg & wheelbase have no items available). This is for when chassis changes
 *						and sections would disappear even though there are items still on the quote in those sections.
 *	2017-02-13	BLL29	Changes for commercial proposal - Quote will be used to configure vehicles for purchase only, not to sell them.
 *	2017-10-03	B. Leaman 	BLL30 changes for adv. veh search.
 *  2018-10-08  A. Miller   AMM31 - W-000413 - Update to handle the new lightning file archictecture
 *	2019-05-29	B. Leaman	W-000575 BLL32 - make remote actions global so they can be executed within a lightning component iframe.
 */
//BLL32
//public with sharing class CQ_EXT {
global with sharing class CQ_EXT {
    
    public CommercialQuote__c quoteInstance {get;set;}

	// BLL29a
	private PageReference self = Page.CQ2;
	private PageReference recapPage = Page.CQRecap;
	private PageReference emailPage = Page.CQEmail;
	private PageReference vehSearchPage = Page.VehicleSearchAdvanced;
	private PageReference proposalPage = Page.DealMBW2;
	private PageReference mfgOrderPDF = Page.CQ_MfgOrder_PDF;
	// BLL29a

    // List of public Id's for sections
    public String optionId {get;set;}
    public String itemToRemove {get;set;}
    public String oppKey;
    public Id oppId {get;set;}	// BLL29c was String
    public Id slopId {get;set;}	// BLL29a
    public Id propId {get;set;} // BLL29a
    
    // Options Sizes
    public Integer Wheelbase_size {get;set;}
    public Integer AdditionalSeating_size {get;set;}
    public Integer Fabric_size {get;set;}
    public Integer WheelchairRestraint_size {get;set;}
    public Integer InteriorOptions_size {get;set;}
    public Integer Stant_size {get;set;}
    public Integer Ext_size {get;set;}
    public Integer ChairStorage_size {get;set;}
    public Integer Safety_size {get;set;}

    // Define variables for other misc inputs
    public Decimal otherQTY {get;set;}
    public String otherName {get;set;}
    public Decimal otherPrice {get;set;}
    public Decimal otherCost {get;set;}
    public String chassis {get;set;}
    public String wheelbase {get;set;}

    // Email Settings
    public String toAddress {get;set;}
    public String subject {get;set;}
    public String body {get;set;}
    public String emailTo	{get;set;} // BLL18a
    public String emailPageName {get;set;}	// BLL18a 

    public Attachment attachment;
    public Blob aBody {get;set;}
    public String aContentType {get;set;}
    public String aFileName {get;set;}
    public List<Id> attachmentList = new List<Id>();

    // BLL7a
    public String keyword1 {get;set;}
    public String keyword2 {get;set;}
    public String keyword3 {get;set;}
    public boolean saveNewVehicle {get; private set;}
    public String vehicleStatus {get; private set;}
    public dealer__Vehicle_Inventory__c veh {get; private set;}
    // BLL7a end

	// BLL12a
	public Contact buyer {get;private set;}
	// BLL12a end

    // Task
    public Task newTask {get;set;}

    // Defaults Org and User Specific
    public CommercialDefaults__c applictionDefaults; 

    public Id currentVehicleId {get; private set;} // BLL7a
    public dealer__Dealer_Location__c location {get;private set;} // BLL7a 
    public Id costReportId {get; private set;} // BLL8a

	private String doctype = 'o';	// BLL29c 'q';	// BLL23a
	public String doctypename {get;private set;} // BLL23a
	private Set<String> NoCnvCstUpdSts = new Set<String>{'Lost', 'Booked', 'Won - Posted'};	// BLL24a
	
    /* Controller */
    public CQ_EXT(ApexPages.StandardController controller) {
        Map<String, Schema.SObjectField> M = Schema.SObjectType.CommercialQuote__c.fields.getMap();
        List<String> af = new List<String>();
        Set<String> fieldnames = M.keySet(); 
        af.addAll(fieldnames);
        af.add('Salesperson__r.Name');
        af.add('Salesperson__r.Title');	// BLL18a
        af.add('Salesperson__r.Phone');	// BLL18a
        af.add('Salesperson__r.Fax');	// BLL18a
        af.add('Salesperson__r.Email');	// BLL18a
        af.add('Chassis__r.Name');
        af.add('Chassis__r.Description__c');
        af.add('VehicleInventory__c'); // BLL7a
        af.add('Location__c'); // BLL7a
        af.add('StockVehChassisCost__c'); // BLL6a
        af.add('StockVehConversionCost__c'); // BLL6a
        af.add('InboundFreightCost__c'); // BLL6a 
        af.add('InboundFreightAmount__c'); // BLL6a 
        af.add('DeliveryFreightCost__c'); // BLL6a 
        af.add('DeliveryFreightAmount__c'); // BLL6a 
        af.add('ExteriorColor__c');	// BLL19a
		// BLL12a
        af.add('LienHolder__r.Name');
        af.add('LienHolder__r.dealer__Bank_Address__c');
        af.add('LienHolder__r.dealer__Bank_City__c');
        af.add('LienHolder__r.dealer__Bank_State__c');
        af.add('LienHolder__r.dealer__Bank_Zip__c');
		// BLL12a end
		af.add('Customer__r.Name'); // BLL15a add billing name for bill-of-sale forms
        af.add('Customer__r.ClientID__c');	// BLL18a
        // BLL18a - need to bring in releasing dealer info for emailed invoice
        af.add('ReleasingDealer__r.Name');
        af.add('ReleasingDealer__r.BillingStreet');
        af.add('ReleasingDealer__r.BillingCity');
        af.add('ReleasingDealer__r.BillingState');
        af.add('ReleasingDealer__r.BillingPostalCode');
        af.add('ReleasingDealer__r.Phone');
        af.add('ReleasingDealer__r.Fax');
        // BLL18a end
        af.add('Proposal__c');	// BLL29a
        af.add('Customer__r.SalesTaxStatus__c');
        af.add('Opportunity__c');	// BLL30a
		
        if(!Test.isRunningTest()) {             
            controller.addFields(af);
        }

        // Iniate a task - BLL7a moved up from further down
        if(newTask==null) {
            newTask=new Task();
        }

        //RT1
        if(ApexPages.currentPage().getParameters().get('id') != null || ApexPages.currentPage().getCookies().get('quote') == null) {
            //use standard controller lookup if the page was given an id or there is no cookie 
            quoteInstance = (CommercialQuote__c)controller.getRecord();
            
        } else {
			quoteInstance = getQuoteFromCookie((CommercialQuote__c)controller.getRecord(), newTask);	// BLL7c add newTask
            oppId = quoteInstance.Opportunity__c;
            slopId = quoteInstance.SolutionOpportunity__c;	// BLL29a
        }

		//BLL10a
        User u = [select ManagerId from User where Id=:UserInfo.getUserId() limit 1];
        if (quoteInstance.Manager__c==null) quoteInstance.Manager__c = u.ManagerId;
        if (quoteInstance.Manager__c==null) quoteInstance.Manager__c = UserInfo.getUserId();
		//BLL10a end

		// BLL29a
		if (quoteInstance.TypeOfSale__c==null && quoteInstance.SolutionOpportunity__c==null && quoteInstance.Opportunity__c==null) 
			quoteInstance.TypeOfSale__c = 'Build for Stock';
		if (quoteInstance.TypeOfSale__c==null) 
			quoteInstance.TypeOfSale__c = 'Build for Customer';
		// BLL29a end
			

        currentVehicleId = quoteInstance.VehicleInventory__c; // BLL7a
        saveNewVehicle=false; // BLL7a 
        //BLL30d if(ApexPages.currentPage().getParameters().get('vehicleId') != null) {
        if (ApexPages.currentPage().getParameters().get('v') != null) {	// BLL30a
            // currentVehicleId = ApexPages.currentPage().getParameters().get('vehicleId');
            //BLL30d Id vehId = ApexPages.currentPage().getParameters().get('vehicleId');
            Id vehId = ApexPages.currentPage().getParameters().get('v');	// BLL30a
            //addCommercialVehicle(vehId);
            // BLL7a
            if (quoteInstance.VehicleInventory__c!=vehId) {	
            	quoteInstance.VehicleInventory__c = vehId;
            	currentVehicleId = null; 
            	List<VehicleInventory_CommercialOption__c> options = [
		            select Id, Name, OptionType__c, CommercialQuoteOption__c, Description__c, SellingPrice__c, Cost__c,
        	            Quantity__c, ExtendedCost__c, ExtendedPrice__c, Notes__c
            		from VehicleInventory_CommercialOption__c
        		    where VehicleInventory__c=:vehId and OptionType__c='Chassis Options'
		        ];
            	saveNewVehicle = options.size()>0;
            	if (options.size()==0) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Stock vehicle does not have a chassis assigned'));	
            }
            // BLL7a end
/**	
             dealer__Vehicle_Inventory__c veh = [SELECT Id, Name, New_Used_Other__c, dealer__Status_Code__c, dealer__Vehicle_Cost__c, dealer__Stock_Number__c, dealer__VIN__c
                from dealer__Vehicle_Inventory__c where Id=:currentVehicleId];
                 rmvCommercialVehicleNoUpdate();
            quoteInstance.VehicleInventory__c = veh.Id;
            quoteInstance.UnitNumber__c = veh.dealer__Stock_Number__c;
            quoteInstance.VIN__c = veh.dealer__VIN__c;
            quoteInstance.Chassis_Cost__c = veh.dealer__Vehicle_Cost__c;
            quoteInstance.Chassis_Price__c = veh.dealer__Vehicle_Cost__c;
**/
        } 

		// BLL29a
		if (quoteInstance.Id==null && ApexPages.currentPage().getParameters().containsKey('proposalId')) {
			propid = ApexPages.currentPage().getParameters().get('proposalId');
		}
		if (quoteInstance.Id==null && ApexPages.currentPage().getParameters().containsKey('solutionOppId')) {
			slopid = ApexPages.currentPage().getParameters().get('solutionOppId');
		}
		// BLL29a end

		// BLL23a - doctype=Invoice to change how CQPDF2 prints	
        if (ApexPages.currentPage().getParameters().containsKey('dt')) {
        	doctype = ApexPages.currentPage().getParameters().get('dt');
        }
       	if (doctype=='i') doctypename='Invoice';
       	else {doctypename='Order'; doctype='o';} //BLL29c {doctypename='Quote'; doctype='q';}
        // BLL23a end

		// BLL6a
		adjFreight();	// BLL6a
		getVehicleInfo();
		openRoWarning();
		// BLL6a

		// BLL24a 
		// If quote is NOT Lost, Booked, Won-Posted, check vehicle conversion cost & apply  
		if (veh!=null && veh.Conversion_Cost__c!=null && !NoCnvCstUpdSts.contains(quoteInstance.Status__c)) {
			//BLL25d List<CommercialQuoteLine__c> needUpd = getConversionCostsToUpdate();	
			//BLL25d if (needUpd.size()>0) {
			
			//BLL25d 	String msg = 'Vehicle conversion and option costs are out-of-date. Please save quote!';
				if (veh.Conversion_Cost__c!=quoteInstance.StockVehConversionCost__c) {
					String msg = 'Vehicle conversion cost is out-of-date. Please save the quote!'; 
					msg += ' (changed from ' + String.valueOf(quoteInstance.StockVehConversionCost__c) 
						+ ' to ' + String.valueOf(veh.Conversion_Cost__c) + ')';
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, msg));
				} // BLL25a
				//BLL25d for(CommercialQuoteLine__c cql : needUpd) System.debug(cql);
			//BLL25d }
		}
		// BLL24a end

		// BLL25a
		if (quoteInstance.UnitGrossChanged__c) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Gross margin has changed since last save'));
		}
		// BLL25a end

        // else {
        //}
        //end RT1
        
        // Set Default Consultant
        if(quoteInstance.Salesperson__c==null) {
            quoteInstance.Salesperson__c=UserInfo.getUserId();
        }

        // Get Defaults for User/Org
        if(CommercialDefaults__c.getValues(quoteInstance.Salesperson__c)==null){
            applictionDefaults = CommercialDefaults__c.getOrgDefaults();
        } else {
            applictionDefaults = CommercialDefaults__c.getInstance();
        }

        // Set Default Values for Recap
        quoteInstance.Commission_Rate__c=applictionDefaults.Commission_Rate__c;

        setLocationInfo(); // BLL7a

        // Iniate a task
        //BLL7d if(newTask==null) {
        //BLL7d     newTask=new Task();
        //BLL7d }

        Wheelbase_size          =   0;
        AdditionalSeating_size  =   0;
        Fabric_size             =   0;
        WheelchairRestraint_size=   0;
        InteriorOptions_size    =   0;
        Stant_size              =   0;
        Ext_size                =   0;
        ChairStorage_size       =   0;
        Safety_size             =   0;
        calcOptionsSizes();
        // If an OPP ID is Passed to the Controller lookup the relevant account and account details.
        Map<String,String> params =  ApexPages.currentPage().getParameters();
        Set<String> keys = params.keySet();
        for(String k : keys) {
            if(k.contains('_lkid')) {
                oppKey = k;
                Id testId  = (Id) String.valueOf(params.get(oppKey));	// BLL29c (Id testId)
                //BLL29d if(quoteInstance.Id==null) {
                //BLL29d     startQuoteFromOpp(oppId);
                //BLL29d }
                // BLL29a
                if (Schema.Opportunity.SObjectType==testId.getSObjectType()) oppid = testId;
                if (Schema.dealer__Sales_Up__c.SObjectType==testId.getSObjectType()) slopid = testId;
                if (Schema.dealer__Deal__c.SObjectType==testId.getSObjectType()) propid = testId;
                // BLL29a end
            }
        }
		// BLL29a
		if(quoteInstance.Id==null && propId!=null) startQuoteFromProposal(propId);
		else if(quoteInstance.Id==null && slopId!=null) startQuoteFromSolOpp(slopId);
		else if(quoteInstance.Id==null && oppId!=null) startQuoteFromOpp(oppId);
		// BLL29a end
        

		//BLL26d if (quoteinstance.Id==null) quoteinstance.InboundFreightCost__c = 500.00; // BLL22a
        if (quoteinstance.Id==null) quoteinstance.Chassis_Taxable__c=true;	// BLL27a
        
        // BLL27a
        if (quoteinstance.Customer__r.SalesTaxStatus__c=='Exempt') {
        	quoteinstance.Chassis_Taxable__c=false;
        }
        // BLL27a end
        
        // BLL12a
        buyer = new Contact();
        List<String> Names = new List<String>{'',''};
        Names = !String.isBlank(quoteInstance.Contact__c) ? quoteInstance.Contact__c.split(' ') : Names;
        buyer.FirstName = Names.size()>0 ? Names[0] : '';
        buyer.LastName = Names.size()>0 ? Names[Names.size()-1] : '';
        // BLL12a end
        
        // BLL8a
		List<Report> reportList = [
			select Id, Name, DeveloperName 
			from Report 
			where DeveloperName = 'Detailed_Quote'
		];
    	if (reportList.size()>0) costReportId = (Id) reportList.get(0).get('Id');
    	// BLL8a
        
    }


	public void convertToProposal() {
		//CommQuoteConversion ba = new CommQuoteConversion('Where Id=\'' + quoteinstance.Id + '\' ', '1');
		//Database.executeBatch(ba,1);
		//ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Converting quote ' + quoteinstance.Name + ' to a commercial Proposal. Please wait for email confirmation and then refresh your screen.'));
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Conversion is no longer supported. Contact IT Help.'));
	}

    /* General Methods */
    public void startQuoteFromOpp(String id) {
        Opportunity[] o = [SELECT Financing_Type__c, Financing_Company__c, Financing_Terms__c, Lost_Reason__c, 	// BLL27c rmv geopointe__Geocode__c,  
                            Vehicle_Type__c, Full_Size_Type__c, Minivan_Entry__c, Minivan_Size__c, Minivan_Type__c, Special_Needs_Options__c, 
                            Vehicle_Quantity__c, Total_Amount__c, Description, StageName, AccountId, Id, Name, Type, LeadSource, 
                            NextStep, IsWon, IsClosed, OwnerId,	// bll14 remove status__c
                                (SELECT Id, OpportunityId, ContactId, Role, IsPrimary, CreatedDate, CreatedById FROM OpportunityContactRoles)
                            FROM Opportunity
                            Where Id =:id
                            limit 1];
        if(o.size()==0) {
            id=null;    // BLL5a
            oppId=null; // BLL5a
            return;
        }

        // We have an Opp, lets start the build out of the Quote
        Account a = CQ_EXT.lookupCustomerRecord(o[0].AccountId);
        quoteInstance.Customer__c   =   a.Id;
        quoteInstance.Street__c     =   a.BillingStreet;
        quoteInstance.City__c       =   a.BillingCity;
        quoteInstance.State__c      =   a.BillingState;
        quoteInstance.Zip__c        =   a.BillingPostalCode;
        quoteInstance.Salesperson__c=   o[0].OwnerId;
        quoteInstance.Phone__c      =   a.Phone;
        quoteInstance.Fax__c        =   a.Fax;
        quoteInstance.Opportunity__c=   o[0].Id;

        // Lookup the Associated contact role and associate with the Contact in the quote.
        for(OpportunityContactRole orole : o[0].OpportunityContactRoles) {
            if(orole.IsPrimary==true) {
                Contact oppContact = [Select Id, FirstName, LastName, Phone, Fax, MobilePhone, Email from Contact where Id=:orole.ContactId limit 1];
                quoteInstance.Contact__c = oppContact.FirstName+' '+oppContact.LastName;
                quoteInstance.Mobile__c  = oppContact.MobilePhone;
                quoteInstance.Email_Address__c = oppContact.Email;
            }
        }

    }

    public Opportunity getOpportunity() {
        if(quoteInstance.Opportunity__c!=null) {
            Opportunity[] oo = [SELECT Financing_Type__c, Financing_Company__c, Financing_Terms__c, Lost_Reason__c,	// BLL27c rmv geopointe__Geocode__c,  
                            Vehicle_Type__c, Full_Size_Type__c, Minivan_Entry__c, Minivan_Size__c, Minivan_Type__c, Special_Needs_Options__c, 
                            Vehicle_Quantity__c, Total_Amount__c, Description, StageName, AccountId, Id, Name, Type, LeadSource, 
                            NextStep, IsWon, IsClosed, OwnerId, // BLL14 remove status__c
                                (SELECT Id, OpportunityId, ContactId, Role, IsPrimary, CreatedDate, CreatedById FROM OpportunityContactRoles)
                            FROM Opportunity
                            Where Id =:quoteInstance.Opportunity__c
                            limit 1];
            if(oo.size()==1) {
                return oo[0];
            } else {
                return new Opportunity();
            }
        }
        return new Opportunity();
    }


	// BLL29a
	public void noaction() {}
	
	public PageReference returnToProposal() {
		proposalPage.getParameters().put('Id',quoteInstance.Proposal__c);
		if (save()!=null) return proposalPage;
		return null;
	}
	
    public void startQuoteFromProposal(Id propid) {
    	dealer__Deal__c deal = [
    		select Id, Name, dealer__Sales_Lead__c, Commercial_Quote__c 
    		from dealer__Deal__c
    		where Id=:propid
    	];
    	startQuoteFromSolOpp(deal.dealer__Sales_Lead__c);
    	quoteInstance.Proposal__c = propid;
    	quoteInstance.TypeOfSale__c = 'Build for Customer';
    }
    public void startQuoteFromSolOpp(Id slopid) {
		quoteInstance.SolutionOpportunity__c = slopId;
		dealer__Sales_Up__c sup = getSolutionOpp();
        if(sup==null || sup.Id==null) {
            oppId=null; 
            slopId=null;
            quoteInstance.SolutionOpportunity__c=null;
            return;
        }

        // We have an Opp, lets start the build out of the Quote
        Account a = CQ_EXT.lookupCustomerRecord(sup.dealer__Customer_Account__c);
        quoteInstance.Customer__c   =   a.Id;
        quoteInstance.Street__c     =   a.BillingStreet;
        quoteInstance.City__c       =   a.BillingCity;
        quoteInstance.State__c      =   a.BillingState;
        quoteInstance.Zip__c        =   a.BillingPostalCode;
        quoteInstance.Salesperson__c=   sup.OwnerId;
        quoteInstance.Phone__c      =   a.Phone;
        quoteInstance.Fax__c        =   a.Fax;
        quoteInstance.Opportunity__c=   null;
        quoteInstance.SolutionOpportunity__c = sup.Id;
    	quoteInstance.TypeOfSale__c = 'Build for Customer';	// BLL29?

        // Lookup the Associated contact role and associate with the Contact in the quote.
		if (a.isPersonAccount) {
			Contact oppContact = [
				select Id, FirstName, LastName, Phone, Fax, MobilePhone, Email 
				from Contact 
				where Id=:a.PersonContactId 
				limit 1
			];
			quoteInstance.Contact__c = oppContact.FirstName+' '+oppContact.LastName;
			quoteInstance.Mobile__c  = oppContact.MobilePhone;
			quoteInstance.Email_Address__c = oppContact.Email;
		}

    }

    public dealer__Sales_Up__c getSolutionOpp() {
        if(quoteInstance.SolutionOpportunity__c!=null) {
            dealer__Sales_Up__c[] oo = [
            	select Id, Name, OwnerId, dealer__Customer_Account__c, 
            			Vehicle_Type__c, Full_Size_Type__c, Minivan_Entry__c, Minivan_Size__c, Minivan_Type__c, 
						Vehicle_Quantity__c, Amount__c
				from dealer__Sales_Up__c
				where Id =:quoteInstance.SolutionOpportunity__c
				limit 1];
            if(oo.size()==1) {
                return oo[0];
            }
        }
        return new dealer__Sales_Up__c();
    }
	// BLL29a end

    // BLL7a
    private void setLocationInfo() {
        if (quoteInstance.Location__c==null) {
            try {
                User u = [select Id, Division from User where Id=:quoteInstance.Salesperson__c];
                dealer__Dealer_Location__c loc = [
                    select Id, Name, dealer__Company_Number__c, Legacy_systems__c 
                    FROM dealer__Dealer_Location__c 
                    where dealer__Company_Number__c =:u.Division 
                    limit 1
                ];
                quoteInstance.Location__c = loc.Id;
            } catch(Exception e) {}
        } 
        if (quoteInstance.Location__c!=null) {
            try {
                location = [
                    select Id, Name, dealer__Company_Number__c, Legacy_systems__c, dealer__Service_Director__c, Sales_Admin__c, dealer__General_Manager__c, // BLL21c add GM
                    	DealerNumber__c, MainFax__c, dealer__Main_Phone__c, Tax_ID__c, 	// BLL12a 
                    	Dealer_License_Name__c, dealer__Street__c, dealer__Address__c,	dealer__City__c, dealer__State__c, dealer__Postal_Code__c 	// BLL9a
                    from dealer__Dealer_Location__c
                    where Id=:quoteInstance.Location__c
                ];
            } catch(Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to determine location'));
            }
        }
        // BLL10a
        if (quoteInstance.ServiceManager__c==null && location!=null) quoteInstance.ServiceManager__c = location.dealer__Service_Director__c;
        if (quoteInstance.SalesAdministrator__c==null && location!=null) quoteInstance.SalesAdministrator__c = location.Sales_Admin__c;
        // BLL10a end
        if (quoteInstance.GeneralManager__c==null && location!=null) quoteInstance.GeneralManager__c = location.dealer__General_Manager__c;	// BLL21a
    }
    // BLL7a end 

    /* Calculate Size of Options per RecordType for Display of PageBlockSection */
    private void calcOptionsSizes() {
        List<Commercial_Quote_Options__c> opts = getOptionsTableSkinny();
        for(Commercial_Quote_Options__c o : opts) {
            if(o.RecordTypeName__c  ==  'Wheelbase Options') { Wheelbase_size++; }
            if(o.RecordTypeName__c  ==  'Seating Options') { AdditionalSeating_size++; }
            if(o.RecordTypeName__c  ==  'Fabric Options') { Fabric_size++; }
            if(o.RecordTypeName__c  ==  'Wheelchair Restraint Options') { WheelchairRestraint_size++; }
            if(o.RecordTypeName__c  ==  'Interior Upgrades') { InteriorOptions_size++; }
            if(o.RecordTypeName__c  ==  'Stanchion Poles') { Stant_size++; }
            if(o.RecordTypeName__c  ==  'Exterior Upgrades') { Ext_size++; }
            if(o.RecordTypeName__c  ==  'Wheelchair Storage Options') { ChairStorage_size++; }          
            if(o.RecordTypeName__c  ==  'Additional Safety Options') { Safety_size++; }
        }
        // BLL28a
		// Also look at options already on the quote so sections don't disappear just because
		// there are no *new* options that can be added to it.
    	List<CommercialQuoteLine__c> items = getAllItems();
    	for(CommercialQuoteLine__c o : items) {
            if(o.RecordTypeName__c  ==  'Wheelbase Options') { Wheelbase_size++; }
            if(o.RecordTypeName__c  ==  'Seating Options') { AdditionalSeating_size++; }
            if(o.RecordTypeName__c  ==  'Fabric Options') { Fabric_size++; }
            if(o.RecordTypeName__c  ==  'Wheelchair Restraint Options') { WheelchairRestraint_size++; }
            if(o.RecordTypeName__c  ==  'Interior Upgrades') { InteriorOptions_size++; }
            if(o.RecordTypeName__c  ==  'Stanchion Poles') { Stant_size++; }
            if(o.RecordTypeName__c  ==  'Exterior Upgrades') { Ext_size++; }
            if(o.RecordTypeName__c  ==  'Wheelchair Storage Options') { ChairStorage_size++; }          
            if(o.RecordTypeName__c  ==  'Additional Safety Options') { Safety_size++; }
    	}
		// BLL28a end
    }

    /* Getters */
    public List<CommercialQuoteLine__c> getWheelBaseSelectedItems() {
        return selectTableItems('Wheelbase Options');
    }

    public List<CommercialQuoteLine__c> getLongWheelBaseSelectedItems() {
        return selectTableItems('Wheelbase Options');
    }   

    public List<CommercialQuoteLine__c> getAdditionalSeatingItems() {
        return selectTableItems('Seating Options');
    }

    public List<CommercialQuoteLine__c> getFabricItems() {
        return selectTableItems('Fabric Options');
    }   

    public List<CommercialQuoteLine__c> getWheelChairRestraints() {
        return selectTableItems('Wheelchair Restraint Options');
    }

    public List<CommercialQuoteLine__c> getInteriorOptions() {
        return selectTableItems('Interior Upgrades');
    }   

    public List<CommercialQuoteLine__c> getStantItems() {
        return selectTableItems('Stanchion Poles');
    }

    public List<CommercialQuoteLine__c> getExtItems() {
        return selectTableItems('Exterior Upgrades');
    }

    public List<CommercialQuoteLine__c> getChairStorageItems() {
        return selectTableItems('Wheelchair Storage Options');
    }

    public List<CommercialQuoteLine__c> getSafetyItems() {
        return selectTableItems('Additional Safety Options');
    }

    public List<CommercialQuoteLine__c> getMiscItems() {
        return [SELECT Commercial_Quote__c, Commercial_Quote_Options__c, Quantity__c, Description__c, Location__c, Selling_Price__c, 
                    Line_Type__c, Extended_Total__c, Notes__c, Name, Id, Commercial_Quote_Options__r.Name, Cost__c, Discount__c, 
                    LockedOption__c, Extended_Cost__c // BLL7a, BLL29c 
                    FROM CommercialQuoteLine__c 
                    Where Commercial_Quote__c =:quoteInstance.id
                    AND Line_Type__c = 'Misc'
                    Limit 500];
    }

    public List<CommercialQuoteLine__c> getAllItems() {
        return [SELECT Commercial_Quote__c, Commercial_Quote_Options__c, Quantity__c, Description__c, Location__c, Selling_Price__c, 
                    Line_Type__c, Extended_Total__c, Notes__c, Name, Id, Commercial_Quote_Options__r.Name, Cost__c, RecordTypeName__c, Discount__c, 
                    LockedOption__c, Extended_Cost__c // BLL7a, BLL29c 
                    FROM CommercialQuoteLine__c 
                    Where Commercial_Quote__c =:quoteInstance.id
                    Order by Selling_Price__c DESC
                    Limit 500];
    }

    // BLL7a separate getter for chassis to include keyword search
    /* modal dialog getter for chassis with keyword search */
    public List<Commercial_Quote_Options__c> getChassisList() {
        List<Commercial_Quote_Options__c> opts = new List<Commercial_Quote_Options__c>();

        String fieldlist = 'Active__c, Location__c, Selling_Price__c, Description__c, Internal_Note__c, Wheelbase__c, Supplier_URL__c, ' 
                         + 'Vehicle_Manufacturer__c, Cost__c, Id, Name, RecordTypeId, RecordTypeName__c'; 
        String fromobj = 'Commercial_Quote_Options__c ';
        String selection = 'where Active__c=true ';

        String orderby = 'order by Name';
        String limits = 'limit 1000 '; 

        String keywordString = '';
        System.debug(keyword1);
        System.debug(keyword2);
        System.debug(keyword3);
        if (!String.isBlank(keyword1)) keywordString += '"' + keyword1.trim() + '" ';
        if (!String.isBlank(keyword2)) keywordString += '"' + keyword2.trim() + '" ';
        if (!String.isBlank(keyword3)) keywordString += '"' + keyword3.trim() + '" ';
        if (String.isBlank(keywordString)) {
            // SOQL 
            String soql = 'select ' + fieldlist + ' from ' + fromobj + ' ' + selection + ' ' + orderby + ' ' + limits;
            System.debug(soql);
            try {
                opts = Database.query(soql);
            } catch(Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            }
        } else {
            // SOSL
            String sosl = 'FIND \'' + String.escapeSingleQuotes(keywordString.trim()) + '\' IN ALL FIELDS '
                + 'RETURNING ' + fromobj + '(' + fieldlist + ' '
                + selection + ' ' + orderby + ' ' + limits + ') ';
            System.debug(sosl);
            try {
                List<List<SObject>> soslrs = search.query(sosl);
                if (soslrs.size()>0) opts = (List<Commercial_Quote_Options__c>) soslrs[0];
            } catch(Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            }
        }
        return opts;
    }
    // BLL7a end

    /* modal dialog getter */
    public List<Commercial_Quote_Options__c> getChassisOptions() {
        return [SELECT Active__c, Location__c, Selling_Price__c, Description__c, Internal_Note__c, Wheelbase__c, Supplier_URL__c, 
                        Vehicle_Manufacturer__c, Cost__c, Id, Name, RecordTypeId, RecordTypeName__c 
                        FROM Commercial_Quote_Options__c
                        WHERE Active__c = true 
                        Order by Name ASC limit 1000];
    }

    public List<Commercial_Quote_Options__c> getModalTable() {
        List<Commercial_Quote_Options__c> modalData = [SELECT Active__c, Location__c, Selling_Price__c, Description__c, Internal_Note__c, Wheelbase__c, Supplier_URL__c, 
                        Vehicle_Manufacturer__c, Cost__c, Id, Name, RecordTypeId, RecordTypeName__c 
                        FROM Commercial_Quote_Options__c
                        WHERE 
                            ( Vehicle_Manufacturer__c =: quoteInstance.Chassis_Platform__c OR Vehicle_Manufacturer__c = null )
                            AND
                            ( Wheelbase__c =: quoteInstance.Chassis_Platform_Wheelbase__c OR Wheelbase__c = null )
                        AND Active__c = true 
                        Order by Name ASC limit 1000];

        //System.debug(modalData);
        
        return modalData;
    }
    
    // BLL4 add
    public List<MultiselectModalTable> getMultiselectModalTable() {
        System.debug('getting multiselect modal table');
        Set<Id> selectedoptions = new set<Id>();
        List<MultiselectModalTable> mmt = new List<MultiselectModalTable>();
        for(CommercialQuoteLine__c cqo : 
            [ select Id, Name, Commercial_Quote_Options__c
              from CommercialQuoteLine__c 
              where Commercial_Quote__c =:quoteInstance.id and LockedOption__c=false  
            ]) { // BLL7c don't prevent new instances of locked options from being added
            selectedoptions.add(cqo.Commercial_Quote_Options__c);
            System.debug('On quote: ' + cqo.Name);
        }
        for(Commercial_Quote_Options__c cqo : 
            [ select Active__c, Location__c, Selling_Price__c, Description__c, Internal_Note__c, Wheelbase__c, Supplier_URL__c, 
                     Vehicle_Manufacturer__c, Cost__c, Id, Name, RecordTypeId, RecordTypeName__c 
              from Commercial_Quote_Options__c
              where ( Vehicle_Manufacturer__c =: quoteInstance.Chassis_Platform__c OR Vehicle_Manufacturer__c = null )
                and ( Wheelbase__c =: quoteInstance.Chassis_Platform_Wheelbase__c OR Wheelbase__c = null )
                and Active__c = true 
              order by Name ASC limit 1000] ) {
            mmt.add(new MultiselectModalTable(cqo, selectedoptions.contains(cqo.Id)));
        }
        return mmt;
    }
    class MultiselectModalTable {
        public boolean selected {get; set;}
        public Commercial_Quote_Options__c option {get; private set;}
        public MultiselectModalTable(Commercial_Quote_Options__c cqo, boolean onQuote) {
            selected = onQuote;
            option = cqo;
        }
    }
    // BLL4 end
    
    // Used to Calc Size by Options
    private List<Commercial_Quote_Options__c> getOptionsTableSkinny() {
        return [SELECT RecordTypeName__c 
                        FROM Commercial_Quote_Options__c
                        WHERE 
                            ( Vehicle_Manufacturer__c =: quoteInstance.Chassis_Platform__c OR Vehicle_Manufacturer__c = null )
                            AND
                            ( Wheelbase__c =: quoteInstance.Chassis_Platform_Wheelbase__c OR Wheelbase__c = null )
                        AND Active__c = true 
                        Order by Name ASC limit 1000];
    }

    /* Quote Lines SOQL */
    public List<CommercialQuoteLine__c> selectTableItems(String rType) {
        List<CommercialQuoteLine__c> rtnlist = [SELECT Commercial_Quote__c, Commercial_Quote_Options__c, Quantity__c, Description__c, Location__c, Selling_Price__c, 
                    Line_Type__c, Extended_Total__c, Notes__c, Name, Id, Commercial_Quote_Options__r.Name, Discount__c,
                    Cost__c, LockedOption__c, Extended_Cost__c // BLL7a, BLL29c
                    FROM CommercialQuoteLine__c 
                    Where Commercial_Quote__c =:quoteInstance.id
                    AND RecordTypeName__c =:rType
                    Order By LockedOption__c DESC, Commercial_Quote_Options__r.Name
                    Limit 500];
		if (rtnList.size()>0) System.debug(rtnList[0]);
		return rtnList;
    }

    /* Quote Builder SOQL */
    public List<Commercial_Quote_Options__c> getQuoteOptions() {
        List<Commercial_Quote_Options__c> newOptionList = new List<Commercial_Quote_Options__c>();
        newOptionList = [SELECT Active__c, Location__c, Selling_Price__c, Description__c, Internal_Note__c, Wheelbase__c, Supplier_URL__c, 
                            Vehicle_Manufacturer__c, Cost__c, Name, Id 
                            FROM Commercial_Quote_Options__c
                            Where Active__c = true
                            limit 1000];
        return  newOptionList;                      
    }

    public User getquoteAuthor() {
        return [SELECT Id, Username, LastName, FirstName, Name, CompanyName, Division, Department, Title, Street, City, State, 
                    PostalCode, Address, Email, Signature, Phone, Fax, MobilePhone, IsActive, FullPhotoUrl, SmallPhotoUrl 
                    FROM User
                    Where Id=:quoteInstance.Salesperson__c
                    limit 1];
    }

    public List<Attachment> getreferenceAttachments() {
        return [Select Id, Name from Attachment where Id IN:attachmentList limit 20];
    }

    /* Page Reference Actions */
    public PageReference addOptionToQuote() {
        System.debug('Add option to quote selected');
        System.debug(optionId);
        // get the option Id
        if(optionId!=null && optionId!='') {
            // Generate new line item and save to object
            Commercial_Quote_Options__c cqo = [SELECT Active__c, Location__c, Selling_Price__c, Description__c, Internal_Note__c, Wheelbase__c, 
                                                Supplier_URL__c, Vehicle_Manufacturer__c, Cost__c, Name, Id 
                                                FROM Commercial_Quote_Options__c
                                                Where Id =:optionId
                                                limit 1];
            CommercialQuoteLine__c cql = new CommercialQuoteLine__c();
            cql.Commercial_Quote__c         =   quoteInstance.Id;
            cql.Commercial_Quote_Options__c =   cqo.Id;
            cql.Description__c              =   cqo.Description__c;
            cql.Quantity__c                 =   1;
            cql.Cost__c                     =   cqo.Cost__c;
            cql.Selling_Price__c            =   cqo.Selling_Price__c;

            insert cql; 

            // Set OptionId to null for next search
            optionId = null;                                            
        }

        return null;
    }


    /* Page Reference Actions */
    public PageReference addOptionsToQuote() {
        System.debug('Add options to quote selected');
        
        // get the option Id
        if(optionId!=null && optionId!='') {
            // Generate new line item and save to object
            Commercial_Quote_Options__c cqo = [SELECT Active__c, Location__c, Selling_Price__c, Description__c, Internal_Note__c, Wheelbase__c, 
                                                Supplier_URL__c, Vehicle_Manufacturer__c, Cost__c, Name, Id 
                                                FROM Commercial_Quote_Options__c
                                                Where Id =:optionId
                                                limit 1];
            CommercialQuoteLine__c cql = new CommercialQuoteLine__c();
            cql.Commercial_Quote__c         =   quoteInstance.Id;
            cql.Commercial_Quote_Options__c =   cqo.Id;
            cql.Description__c              =   cqo.Description__c;
            cql.Quantity__c                 =   1;
            cql.Cost__c                     =   cqo.Cost__c;
            cql.Selling_Price__c            =   cqo.Selling_Price__c;

            insert cql; 

            // Set OptionId to null for next search
            optionId = null;                                            
        }

        return null;
    }

    public PageReference removeItem() {
        if(itemToRemove!=''&&itemToRemove!=null) {
        	try {	// BLL7a (ignore error - probably from double-click)
            	CommercialQuoteLine__c l = [
            	    Select Id, LockedOption__c // BLL7c 
            	    from CommercialQuoteLine__c Where id=:itemToRemove limit 1
            	];
            	if (l.LockedOption__c==false) // BLL7a
            	    delete l;
            	else ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Cannot remove options installed on inventory vehicle'));  // BLL7a
        	} catch(Exception e) {} // BLL7a
        }   
        return null;
    }

    public PageReference addOtherOption() {
        // Check to see if the required option fields are set.
        System.debug('addOtherOption Called');
        if(otherQTY!=null 
                && otherName!='' && otherName!=null 
                && otherPrice!=null 
                && otherCost!=null) {

            /*---------------------------------------------------*/
            CommercialQuoteLine__c cl = new CommercialQuoteLine__c();
            cl.Commercial_Quote__c  =   quoteInstance.Id;
            cl.Line_Type__c         =   'Misc';
            cl.Quantity__c          =   otherQTY;
            cl.Description__c       =   otherName;
            cl.Selling_Price__c     =   otherPrice; 
            cl.Cost__c              =   otherCost;

            try {

                insert cl;

                otherQTY = null;
                otherName= null;
                otherPrice=null;
                otherCost =null;

            } catch(DmlException e) {
                System.debug(e);
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Unable to save Optional Item : '+e));
                return null;
            }

        } else {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'All fields are required when adding optional items.'));
            system.debug('Other option failed to meet criteria');
            return null;
        }
        return null;
    }   

    public PageReference saveCommercialQuote() {
        // Action not in use at this time.
        //BLL29d PageReference cq = Page.CQ;
        PageReference cq = self;	// BLL29a
        cq.getParameters().put('id', quoteInstance.Id);
        cq.setRedirect(true);
        return cq;
    }

    public PageReference doRecap() {
        //BLL29d return Page.CQRecap;
        return recapPage;
    }

    public PageReference save() {
   	    quoteInstance.Freight_Cost__c = nullZero(quoteInstance.InboundFreightCost__c) + nullZero(quoteInstance.DeliveryFreightCost__c); 
   	    quoteInstance.Freight_Amount__c = nullZero(quoteInstance.InboundFreightAmount__c) + nullZero(quoteInstance.DeliveryFreightAmount__c); 
    	quoteInstance.UnitGrossChanged__c = false;	// BLL25a reset. Batch/trigger update turns it on. 
		if (quoteInstance.TypeOfSale__c!=null && quoteInstance.TypeOfSale__c!='Build for Customer') quoteInstance.Proposal__c=null;	// BLL29a
		
        // Check to see if a Task is created
        if(quoteInstance.Id==null) {
            if(newTask.subject!=null) {
                newTask.Priority = 'High';
            }

            // Get from the account relevant information
            if(quoteInstance.Customer__c!=null) {
                Account a = [Select Id, Market_Segment__c, Preferred_Releasing_Dealer__c, Tax_ID_Number__c, GPC_or_Fleet_Code__c, PreferredReleasingDealer__c // BLL8c 
                                FROM Account where Id=:quoteInstance.Customer__c
                                limit 1];

                quoteInstance.Market_Segment__c = a.Market_Segment__c;
                quoteInstance.Preferred_Releasing_Dealer__c = a.Preferred_Releasing_Dealer__c;
                quoteInstance.ReleasingDealer__c = a.PreferredReleasingDealer__c;	// BLL8a
                //quoteInstance.Fleet_GPC__c = a.GPC_or_Fleet_Code__c;
                //quoteInstance.Tax_ID__c = a.Tax_ID_Number__c;
            }
            if (quoteInstance.ReleasingDealer__c!=null) quoteInstance.TypeOfSale__c='Releasing Dealer';	// BLL16a
            // Insert the quote
            insert quoteInstance;

            newTask.WhatId = quoteInstance.Id;
            if (newTask.Subject!=null && newTask.ActivityDate!=null) insert newTask;	// BLL29c only if a subject or date
			// BLL7a
            if (quoteInstance.VehicleInventory__c!=null) {
                if (!addCommercialVehicle(quoteInstance.VehicleInventory__c)) return null; // Don't save & reload page if vehicle wasn't added!
            }
            // BLL7a end

        } else {
            // BLL7a if vehicle changed, remove/add installed options
            if (currentVehicleId!=quoteInstance.VehicleInventory__c) {
                if (!addCommercialVehicle(quoteInstance.VehicleInventory__c)) return null; // Don't save & reload page if vehicle wasn't added!
            }
            
            // BLL24a - update conversion cost from vehicle & stock option costs if necessary
	   	    quoteInstance.StockVehConversionCost__c = (veh!=null && veh.Conversion_Cost__c!=null) ? veh.Conversion_Cost__c : 0;
			//BLL25d List<CommercialQuoteLine__c> updLines = getConversionCostsToUpdate();	
			//BLL25d if (updLines.size()>0) update(updLines);
			// BLL24a end
			
            if (quoteInstance.ReleasingDealer__c!=null) quoteInstance.TypeOfSale__c='Releasing Dealer';	// BLL16a
			try {	// BLL16a
            update quoteInstance;
            // BLL16a
			} catch(Exception e) { return null; }
			// BLL16a
        }
        
        // BLL29a - link proposal back to this quote
        if (quoteInstance.Proposal__c!=null) {
        	dealer__Deal__c d = [select Id, dealer__Status__c, Commercial_Quote__c from dealer__Deal__c where Id=:quoteInstance.Proposal__c limit 1];
        	if (d==null) d = new dealer__Deal__c(Id=quoteInstance.Proposal__c, Commercial_Quote__c=null);
        	if (d!=null && d.dealer__Status__c!='Won - Posted' && d.Commercial_Quote__c==null) {
        		d.Commercial_Quote__c = quoteInstance.Id;
        		try {
        			update(d);
        		} catch(Exception e) {}
        	}
        }
        // BLL29a

        //BLL29d PageReference cq = Page.CQ;
        PageReference cq = self;	// BLL29a
        cq.getParameters().put('id', quoteInstance.Id);
        cq.setRedirect(true);
        return cq;      
    }

    public PageReference printPDF() {
        return null;
    }

    public PageReference doNothing() {
        return null;
    }

    public PageReference emailPDF() {
    	emailTo = 'Customer';	// BLL18a
        toAddress = quoteInstance.Email_Address__c;
    	emailPageName = 'CQ_PDF2';	// BLL18a
        //BLL29d return Page.CQEmail;
        return emailPage;	// BLL29d
    }

	// BLL18a
    public PageReference emailReleasingDealerInvoice() {
    	emailTo = 'Releasing Dealer';
    	Account rd = [select dealer__Billing_Email__c from Account where Id=:quoteinstance.ReleasingDealer__c];
    	toAddress =	rd!=null ? rd.dealer__Billing_Email__c : UserInfo.getUserEmail();
    	emailPageName = 'CQ_ReleasingDealerInvoice';
        //BLL29d return Page.CQEmail;
        return emailPage;
    }
    // BLL18a

    public PageReference emailPDFDirect() {

        Messaging.EmailFileAttachment attach;
        Blob pdf = getQuoteAsPDFBlob();	
        //Messaging.EmailFileAttachment attach = AttachPDF();
        if (pdf!=null) {
            attach = AttachPDF(pdf);
        }
        
        // BLL1a start: get list of send-to addresses
        String[] sendToAddresses = toAddress.replace(',', ';').split(';');  
        // Remove any empty strings (like from trailing semi-colons)
        for(Integer i=sendToAddresses.size()-1; i>=0; i-- ) {
            if (sendToAddresses[i].trim().length()==0) {
                sendToAddresses.remove(i);
            }
        } 
        // Simple error-checking: if no addresses, it's an error!
        PageReference toPage = new ApexPages.standardcontroller(quoteInstance).view();
        if (sendToAddresses.size() < 1) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error: Missing send-to email address'));
            toPage = null;
        }
        // BLL1a end: get list of send-to addresses
     
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();
        mail.setUseSignature(false);
        //mail.setToAddresses(new String[] { toAddress }); // BLL1d updated to allow multiple send-to addresses
        mail.setToAddresses(sendToAddresses); // BLL1a use list of addresses
        mail.setSubject(subject);
        mail.setHtmlBody(body);
        if (attach!=null) {
           listOfAttachments.add(attach);
        }

        // Additional Attachments
        if(attachmentList.size()>0) {
            // AMM31
            // for(Attachment a : [Select Id, Name, Body, ContentType, BodyLength from Attachment where Id IN :attachmentList]) {
            //     Messaging.EmailFileAttachment m_attachment = new Messaging.EmailFileAttachment();
            //     m_attachment.setBody(a.Body);
            //     m_attachment.setContentType(a.ContentType);
            //     m_attachment.setFileName(a.Name);
            //     m_attachment.setinline(false);
            //     listOfAttachments.add(m_attachment);
            // }

            for(ContentVersion a : [SELECT Id, Title, FileType, VersionData FROM ContentVersion WHERE Id IN :attachmentList]) 
            {
                Messaging.EmailFileAttachment m_attachment = new Messaging.EmailFileAttachment();
                m_attachment.setBody(a.VersionData);
                m_attachment.setContentType(a.FileType);
                m_attachment.setFileName(a.Title);
                m_attachment.setinline(false);
                listOfAttachments.add(m_attachment);
            }
            // AMM82
        }
      
        mail.setFileAttachments(listOfAttachments);
           
        // Only send if no error messages
        if (!ApexPages.hasMessages(ApexPages.Severity.ERROR) || Test.isRunningTest()) {  // BLL1a
           // Send the email
           try { // BLL4 add try-catch error handling
               Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Email with Commercial Proposal was sent to '));
            
               // Record Activity
               Task t = new Task( Subject='Emailed Commercial Proposal to '+emailTo + ' at ' + toAddress,	// BLL18c add emailTo + ' at '
                               ActivityDate=Date.today(),
                               WhatId=quoteInstance.Id,
                               Status='Completed');
               insert t;             
               
               // Attach PDF to task - BLL
               // AMM31
            //    Attachment att = new Attachment();
            //    if (pdf!=null) {
            //       att.Body = pdf;
            //    } else {
            //       att.Body = Blob.valueOf('No attachment');
            //    }
            //    att.ContentType = 'application/pdf';
            //    att.Name = quoteInstance.Name+'.pdf';
            //    att.ParentId = t.Id;
            //    insert att;

                LightningFileUtility tempUtility = new LightningFileUtility(); // reset all the context
                if (pdf!=null) 
                {
                    tempUtility.addFile('Proposal_'+quoteInstance.Name+'.pdf', EncodingUtil.base64Encode(pdf), t.Id, false, null); // Attachment
                } 
                else
                {
                    tempUtility.addFile('Proposal_'+quoteInstance.Name+'.pdf', 'No attachment', t.Id, false, null); // Attachment
                }
                tempUtility.commitFiles();
                // AMM31

    		   try {	// BLL13a
               quoteInstance.Quote_Emailed__c = true;
               update quoteInstance;
    		   } catch(Exception err) {}	// BLL13a
           // BLL4 add error handling              
           } catch(Exception e) {  
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to send email: ' + e.getMessage()));
               toPage = null;
           }
           // BLL4 end block
        } // BLL1a end if any error messages
        
        //return new ApexPages.standardcontroller(quoteInstance).view();
        return toPage;  // BLL1a so toPage can be set to null if there are errors
    }   

    public PageReference addAttachment() {
        // Insert Attachment and Store ID for send
        if(aBody!=null&&aFileName!=null){
            // AMM31
            // attachment = new Attachment(
            //     Body=aBody,
            //     ContentType=aContentType,
            //     Name=aFileName,
            //     ParentId=quoteInstance.Id
            // );
        
            // insert attachment;
            // attachmentList.add(attachment.Id);

            LightningFileUtility tempUtility = new LightningFileUtility();
            tempUtility.addFile(aFileName, EncodingUtil.base64Encode(aBody), quoteInstance.Id, false, null); // Attachment
            tempUtility.commitFiles();
            for(ContentVersion tempCV : tempUtility.getListofContentVersions())
            {
                attachmentList.add(tempCV.Id);
            }

            // AMM31
            attachment = null;
        }

        aBody=null;
        aContentType=null;
        aFileName=null;

        return null;
    }

    public PageReference cloneQuote() {

        Savepoint sp = Database.setSavepoint();
        CommercialQuote__c cq;

        try {
 
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Map<String, Schema.SObjectField> fieldMap = schemaMap.get('CommercialQuote__c').getDescribe().fields.getMap();
            String commaSepratedFields = '';
            for(String fieldName : fieldMap.keyset()){
                if(commaSepratedFields == null || commaSepratedFields == ''){
                    commaSepratedFields = fieldName;
                }else{
                    commaSepratedFields = commaSepratedFields + ', ' + String.escapeSingleQuotes(fieldName);
                }
            }

            String query = 'select ' + commaSepratedFields + ' from CommercialQuote__c where id = \'' + String.escapeSingleQuotes(quoteInstance.Id) + '\' limit 1';
     
            cq = Database.query(query); 

            cq = quoteInstance.clone(false);
            
            // BLL9a Always set new quote to "Pending"
            cq.Status__c = 'Pending';
            
            
            insert cq;

            List<CommercialQuoteLine__c> cql = new List<CommercialQuoteLine__c>();
            List<CommercialQuoteLine__c> cqlActual = new List<CommercialQuoteLine__c>();
            Map<String, Schema.SObjectType> schemaMap2 = Schema.getGlobalDescribe();
            Map<String, Schema.SObjectField> fieldMap2 = schemaMap2.get('CommercialQuoteLine__c').getDescribe().fields.getMap();
            commaSepratedFields = '';
            for(String fieldName : fieldMap2.keyset()){
                if(commaSepratedFields == null || commaSepratedFields == ''){
                    commaSepratedFields = fieldName;
                }else{
                    commaSepratedFields = commaSepratedFields + ', ' + String.escapeSingleQuotes(fieldName);
                }
            }
            query='';
            query = 'select ' + commaSepratedFields + ' from CommercialQuoteLine__c where Commercial_Quote__c = \'' + String.escapeSingleQuotes(quoteInstance.Id) + '\' limit 100';
     
            cqlActual = Database.query(query); 

            for(CommercialQuoteLine__c items : cqlActual) {
                CommercialQuoteLine__c newLine = items.clone(false);
                newLine.Commercial_Quote__c = cq.Id;
                cql.add(newLine);
            }

            insert cql;

        } catch (Exception e) {
            Database.rollback(sp);
            ApexPages.addMessages(e);
            return null;
        }

        return new PageReference('/'+cq.Id+'/e?retURL=%2F'+cq.Id);
    }

    /* Submit Approval Process */
    /* BLL3 note - this routine is not being used -- only the native submit for approval button is used at present */
    public PageReference placeOrder() {

        // Update Account with GPC/Preferred
        Account a = [Select Id from Account where Id=:quoteInstance.Customer__c limit 1];
        //a.GPC_or_Fleet_Code__c = quoteInstance.Fleet_GPC__c;  // BLL3d 
        //a.Tax_ID_Number__c = quoteInstance.Tax_ID__c;         // BLL3d 
        //BLL8d a.Preferred_Releasing_Dealer__c = quoteInstance.Preferred_Releasing_Dealer__c;
        a.Market_Segment__c = quoteInstance.Market_Segment__c;
        update a;

        // Check to see if delivery date is set
        if(quoteInstance.Delivery_Date__c==null) {
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Delivery Date must be set'));
            return null;
        }

        // Get the active approval process
        ProcessDefinition p = [Select Id, DeveloperName from ProcessDefinition where TableEnumOrId = 'CommercialQuote__c' and State = 'Active' and Type='Approval' limit 1];

        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Placing won order for review');
        req.setObjectId(quoteInstance.Id);
        req.setSubmitterId(UserInfo.getUserId());
        if(!Test.isRunningTest()) {
            Approval.ProcessResult result = Approval.process(req);
        }

        return null;
    }

    /* Remote Actions */
    @RemoteAction
	// BLL32
    //public static Account lookupCustomerRecord(String accountId) {
    global static Account lookupCustomerRecord(String accountId) {
        Account[] a = [
        	select Id, Phone, Fax, BillingCity, BillingStreet, BillingPostalCode, BillingState, 
        		isPersonAccount, PersonContactId	// BLL29a 
        	from Account 
        	where Id=:accountId 
        	limit 1
        ];
        if(a.size()==1) {
            return a[0];
        } else {
            return null;
        }
    }   

    @RemoteAction
    // BLL32
	//public static Commercial_Quote_Options__c lookupOption(String cqoId) {
    global static Commercial_Quote_Options__c lookupOption(String cqoId) {
        Commercial_Quote_Options__c[] c = [
        	select Active__c, Location__c, Cost__c, Selling_Price__c, Description__c, Internal_Note__c, 
					Wheelbase__c, Supplier_URL__c, Vehicle_Manufacturer__c, Id, Name, RecordTypeId 
			from Commercial_Quote_Options__c 
			where Id=:cqoId 
			limit 1
		];
        if(c.size()==1) {
            return c[0];
        } else {
            return null;
        }
    }   

    @RemoteAction
	// BLL32
    //public static boolean setLineDetails(String linedata) {
    global static boolean setLineDetails(String linedata) {
        String[] s = linedata.split('~', 0);
        /*
            0 = Record Id
            1 = QTY
            2 = Price
            3 = Cost (optional)	BLL7a
        */
        if(s.size()!=3 && s.size()!=4) {	// BLL7c optional 4th parm is cost
            return false;
        }

        CommercialQuoteLine__c cql = [Select Id, Selling_Price__c, Quantity__c, Cost__c from CommercialQuoteLine__c where Id=:s[0]];
        cql.Selling_Price__c = Double.valueOf(s[2]);
        cql.Quantity__c = Double.valueOf(s[1]);
        if (s.size()==4) cql.Cost__c = Double.valueOf(s[3]);	// BLL7a 
        update cql;

        return true;
    }

	// BLL8a
    @RemoteAction
	// BLL32
    //public static boolean setMiscLineDescription(String linedata) {
    global static boolean setMiscLineDescription(String linedata) {
        String[] s = linedata.split('~', 0);
        /*
            0 = Record Id
            1 = Description
        */
        if(s.size()!=2) {
            return false;
        }

        CommercialQuoteLine__c cql = [Select Id, Description__c from CommercialQuoteLine__c where Id=:s[0]];
        cql.Description__c = s[1];
        update cql;

        return true;
    }
    // BLL8a end

    @RemoteAction
	// BLL32
    //public static boolean saveField(String fieldData) {
    global static boolean saveField(String fieldData) {
        String[] s = fieldData.split('~', 0);
        /*
            0 = Record Id
            1 = Field
            2 = Value
        */    
        String val=null;  
        if(s.size()==3) {
            val = s[2];
        }

        CommercialQuote__c q = [Select Id from CommercialQuote__c where Id =:s[0] limit 1];
        // Get Field Mapping
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.CommercialQuote__c.fields.getMap();
        Boolean contains = fieldMap.containsKey(String.valueOf(s[1]).remove('dealer__'));

        if(!contains) {
            system.debug('Failed to map field.');
            return false;
        }

        // Get Field Type so we can cast as the correct type for the database.
        Schema.SObjectType               t = Schema.getGlobalDescribe().get('CommercialQuote__c');
        Schema.DescribeSObjectResult     r = t.getDescribe();
        Schema.DescribeFieldResult       f = r.fields.getMap().get(String.valueOf(s[1])).getDescribe();

        //System.debug(f);

        if(f.getType() == Schema.DisplayType.Date) {
            q.put(fieldMap.get(s[1]), Date.parse(val.trim() /*s[2]*/ ));  // BLL3 add .trim()
        } else if(f.getType() == Schema.DisplayType.Currency) {
            System.debug(s[1]);
            System.debug('Currency -' + val /* s[2] */ );
            if(val==null || val.trim().length()==0 /* s[2] == '' */){
                q.put(fieldMap.get(s[1]), null);
            } else {
                q.put(fieldMap.get(s[1]), Decimal.valueOf( String.valueOf( val.trim() /* s[2] */ ).replace(',','') ) ); // BLL3 add .trim()
            }
            //q.put(fieldMap.get(s[1]), Double.valueOf(s[2]));
        } else if(f.getType() == Schema.DisplayType.Double) {
            q.put(fieldMap.get(s[1]), Decimal.valueOf(val.trim() /* s[2] */));  // BLL3 add .trim()
        } else if(f.getType() == Schema.DisplayType.Percent) {
            q.put(fieldMap.get(s[1]), Decimal.valueOf(val.trim() /* s[2] */));  // BLL3 add .trim()
        } else if(f.getType() == Schema.DisplayType.Boolean) {
            q.put(fieldMap.get(s[1]), Boolean.valueOf(val.trim() /* s[2] */));  // BLL3 add .trim()
        } else {
            q.put(fieldMap.get(s[1]), val /* s[2] */);
        }
        try {
        	q.ScreenFieldUpdate__c = true;	// BLL25a Used to skip auto-recalc GP & Commissions
            update q;
        } catch(Exception e) {
            return false;   
        }

        return true;
    }

    // BLL6a
    public void markQuoteLost() {
        quoteinstance.Status__c = 'Lost';
        //saveCommercialQuote();
        save();
    }
    // BLL6a end

    @RemoteAction
	// BLL32
    //public static Commercial_Quote_Options__c setFreight(String state) {
    global static Commercial_Quote_Options__c setFreight(String state) {
        return [Select Id, Cost__c, Freight__c from Commercial_Quote_Options__c where State__c =:state limit 1];
    }

    @RemoteAction
	// BLL32
    //public static CommercialQuote__c recapTotals(String quoteId) {
    global static CommercialQuote__c recapTotals(String quoteId) {
        CommercialQuote__c rtncq = [Select Id, Total_Options_Price__c, Total_Options_Cost__c, Chassis_Price__c, Chassis_Cost__c, Chassis_QTY__c, Freight_Cost__c, 
                     Commercial_Rebate__c, Freight_Amount__c, Accepted_Date__c, Delivery_Date__c, Total__c, CreatedDate, Commission_Rate__c, Commission__c, Discount__c,	// BLL11c added Discount__c
                     StockVehConversionCost__c, Status__c	// BLL24a add StockVehConversionCost__c, BLL25c add status
                From CommercialQuote__c where Id=:quoteId
                Limit 1];
		// BLL11a - recalculate discount
		Decimal discount = 0.00;
		for(CommercialQuoteLine__c cql : [
			select Id, Quantity__c, Discount__c
			from CommercialQuoteLine__c
			where Commercial_Quote__c =:quoteId
		]) {
			discount += (cql.Quantity__c * cql.Discount__c);
		}
		rtncq.Discount__c = discount;
		if (rtncq!=null && rtncq.StockVehConversionCost__c==null) rtncq.StockVehConversionCost__c = 0;	// BLL24a
        return rtncq;
    }

    @RemoteAction
    //BLL32
	//public static Boolean clearSelectedOptions(String quoteId) {
    global static Boolean clearSelectedOptions(String quoteId) {
        List<CommercialQuoteLine__c> lines = [Select Id from CommercialQuoteLine__c where Commercial_Quote__c=:quoteId limit 500];
        if(lines.size()>0) {
            try {
                delete lines;
            } catch (DMLException e) {
                return false;
            }
        }

        return true;
    }

    /* Get PDF as blob */
    public Blob getQuoteAsPDFBlob() {
        PageReference pdf = new PageReference('/apex/' + emailPageName);	// BLL18c change from CQ_PDF2 to emailPageName
        pdf.getParameters().put('id', string.valueOf(quoteInstance.Id));
     
        // the contents of the attachment from the pdf
        Blob body;
        
        try {
          // returns the output of the page as a PDF
          body = pdf.getContentAsPDF();
          
        } catch (VisualforceException e) {
          body = null;
        }
        return body;
    }
    
    /* Supporting Methods */
    public Messaging.EmailFileAttachment AttachPDF(Blob body) {
                
        //PageReference pdf = new PageReference('/apex/CQ_PDF2');
        //pdf.getParameters().put('id', string.valueOf(quoteInstance.Id));
     
        // the contents of the attachment from the pdf
        //Blob body;
        
        //try {
          // returns the output of the page as a PDF
        //  body = pdf.getContentAsPDF();
        //  
        //} catch (VisualforceException e) {
        //  body = Blob.valueOf('Error Generating Attachment');
        //}
     
        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        attach.setContentType('application/pdf');
        attach.setFileName(quoteInstance.Name+'.pdf');
        attach.setInline(false);
        attach.Body = body;
        
        return attach;
    }   
    
    // nullZero - BLL6a
    //----------------------------------
    public Decimal nullZero(Decimal d) {
    	return d==null ? 0.00 : d;
    }
    
    // adjFreight -- BLL6a
    // If freight isn't split between inbound & delivery, assume it is all inbound freight.
    //--------------------------------
    public void adjFreight() {
    	if (quoteInstance.Freight_Cost__c!=null && quoteInstance.InboundFreightCost__c==null && quoteInstance.DeliveryFreightCost__c==null) {
    		quoteInstance.InboundFreightCost__c = quoteInstance.Freight_Cost__c;
    	}
    	if (quoteInstance.Freight_Amount__c!=null && quoteInstance.InboundFreightAmount__c==null && quoteInstance.DeliveryFreightAmount__c==null) {
    		quoteInstance.InboundFreightAmount__c = quoteInstance.Freight_Amount__c;
    	}
    }
    
    // getVehicleInfo -- BLL6a
    //--------------------------------
    public void getVehicleInfo() {
		vehicleStatus=null;
        if (currentVehicleId!=null) {
           	try {
				veh = [
					SELECT Id, Name, New_Used_Other__c, dealer__Status_Code__c, dealer__Vehicle_Cost__c, dealer__Stock_Number__c, dealer__VIN__c,
					    dealer__Year__c,dealer__Make__c,dealer__Model__c,    // JRP1a
					    Conversion_Cost__c,	// BLL24a
					    dealer__Body_Type__c, dealer__Fuel_Type__c, // BLL12a
					    dealer__Exterior_Color__c, dealer__Interior_Color__c, // BLL19a
						dealer__Mileage__c, Division__c, // BLL19a 
						Releasing_Dealer__c, Releasing_Dealer__r.Name		// BLL8a
               		from dealer__Vehicle_Inventory__c 
               		where Id=:currentVehicleId
               	];
               	vehicleStatus=veh.dealer__Status_Code__c;   
               	System.debug('Vehicle status: ' + vehicleStatus);
           	} catch(Exception e) {}         	
        }
    }
    
    // openRoWarning -- BLL6a
    //-----------------------------------
    public void openRoWarning() {
    	if (currentVehicleId!=null && quoteInstance.Status__c=='Pending') {
    		List<dealer__Service_Repair_Order__c> openros = [
    			select Id, Name, dealer__Status__c
    			from dealer__Service_Repair_Order__c
    			where dealer__Status__c not in ('Void','Posted')
    			  and ( dealer__Vehicle_Inventory__c=:currentVehicleId or dealer__Vehicle__r.dealer__Sales_Inventory__c=:currentVehicleId )
    			limit 5
    		];
    		if (openros.size()>0) {
    			String RONames = '';
    			List<String> rolist = new List<String>();
    			for(dealer__Service_Repair_Order__c ro : openros) rolist.add(ro.Name);
    			RONames = String.join(rolist, ', ');
    			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Open ROs exist for this vehicle. Cost may be understated! (' + RONames + ')'));
    		}
    	}    	
    }
    
    // BLL7a - new routines for adding/removing inventory commercial vehicle
    // BLL13a - if current vehicle is null, remove existing (non-stock) options that are on the new vehicle.
    // addCommercialVehicle
    //---------------------------------------------
    public boolean addCommercialVehicle(Id vehId) {
        // Make sure vehicle exists and is a commercial vehicle
        dealer__Vehicle_Inventory__c veh = null;
        try {
            veh = [
                select Id, Name, New_Used_Other__c, dealer__Status_Code__c, dealer__Vehicle_Cost__c,
                	dealer__Stock_Number__c, dealer__VIN__c, Conversion_Cost__c, InboundFreightCost__c,
                	Releasing_Dealer__c, Releasing_Dealer__r.Name,	// BLL8a 
				    dealer__Body_Type__c, dealer__Fuel_Type__c, // BLL12a
				    dealer__Exterior_Color__c, dealer__Interior_Color__c, // BLL19a
                	dealer__Mileage__c, Division__c // BLL8a
                from dealer__Vehicle_Inventory__c
                where Id=:vehId
            ];
            if (veh!=null && veh.Division__c!='Commercial') { 	// BLL8c chg veh.New_Used_Other__c!='Commercial') {
                quoteInstance.VehicleInventory__c = currentVehicleId;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Selected vehicle is not a Commercial vehicle'));
                return false;
            }
        } catch(Exception e) {
            quoteInstance.VehicleInventory__c = currentVehicleId;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Stock vehicle was not found'));
            return false;
        }
        
        // BLL13a - list of existing, non-locked options
        //BLL20d List<CommercialQuoteLine__c> rmvNonStock = new List<CommercialQuoteLine__c>();
        List<CommercialQuoteLine__c> updToStock = new List<CommercialQuoteLine__c>();	// BLL20a 
        Map<String,CommercialQuoteLine__c> nonstockmap = new Map<String,CommercialQuoteLine__c>();
        if (currentVehicleId==null) {
	        for(CommercialQuoteLine__c cql : [ 
        		select Id, Commercial_Quote_Options__c, Quantity__c
        		from CommercialQuoteLine__c
        		where Commercial_Quote__c=:quoteInstance.Id and LockedOption__c=false 
        	]) {
        		String key = cql.Commercial_Quote_Options__c + '-' + String.valueOf(cql.Quantity__c);
        		nonstockmap.put(key, cql);
        	}
        }
        // BLL13a end
        
        String CQOptionRecordType='Chassis Options';
        Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.Commercial_Quote_Options__c.getRecordTypeInfosByName();

		CommercialQuote__c backup = quoteinstance.clone();	// BLL17a
        rmvCommercialVehicleNoUpdate();
        // BLL17c marker for code moved from here further down
        
        List<VehicleInventory_CommercialOption__c> vehOptions = [
            select Id, Name, OptionType__c, Quantity__c, Cost__c, SellingPrice__c, Description__c, 
                CommercialQuoteOption__c, CommercialQuoteOption__r.Name, CommercialQuoteOption__r.Description__c, 
                CommercialQuoteOption__r.Vehicle_Manufacturer__c, CommercialQuoteOption__r.Wheelbase__c  
            from VehicleInventory_CommercialOption__c
            where VehicleInventory__c=:vehId
        ];
        System.debug('Number of options: ' + String.valueOf(vehOptions.size()));
        List<CommercialQuoteLine__c> newcqls = new List<CommercialQuoteLine__c>();
        for(VehicleInventory_CommercialOption__c vico : vehOptions) {
            System.debug(vico.OptionType__c);
            // BLL13a - list of non-stock items to be removed (found on newly-added stock vehicle)
            String key = vico.CommercialQuoteOption__c + '-' + String.valueOf(vico.Quantity__c);
			if (nonstockmap.containskey(key)) {
				//BLL20d rmvNonStock.add(nonstockmap.get(key));
				// BLL20a
				CommercialQuoteLine__c cql = nonstockmap.get(key); 
				cql.LockedOption__c = true;
				//cql.Cost__c = vico.Cost__c;
				//BLL25d cql.Cost__c = 0;
				updToStock.add(cql);	
				// BLL20a end
			} else {	// BLL20c add else
			// BLL13a end
            if (vico.OptionType__c=='Chassis Options') {
                //quoteInstance.Chassis_Cost__c = vico.Cost__c;
                //quoteInstance.Chassis_Price__c = vico.SellingPrice__c;
                if (veh.dealer__Vehicle_Cost__c!=null && veh.dealer__Vehicle_Cost__c!=0) {
                	quoteInstance.Chassis_Cost__c = veh.dealer__Vehicle_Cost__c;
                	quoteInstance.Chassis_Price__c = veh.dealer__Vehicle_Cost__c;
                }
                if(backup.Chassis_Price__c!=null && backup.Chassis_Price__c>0) quoteInstance.Chassis_Price__c=backup.Chassis_Price__c;	// BLL20a 
                quoteInstance.Chassis_Platform__c = vico.CommercialQuoteOption__r.Vehicle_Manufacturer__c;
                quoteInstance.Chassis_Platform_Wheelbase__c = vico.CommercialQuoteOption__r.Wheelbase__c;
                quoteInstance.Chassis__c = vico.CommercialQuoteOption__c;
                quoteInstance.Chassis_QTY__c = vico.Quantity__c;
                //BLL16d update quoteInstance;
            } else {
                CommercialQuoteLine__c cql = new CommercialQuoteLine__c(
                    Commercial_Quote__c         =   quoteInstance.Id,
                    Commercial_Quote_Options__c =   vico.CommercialQuoteOption__c,
                    Description__c              =   vico.Description__c,
                    Quantity__c                 =   vico.Quantity__c,
                    Cost__c                     =   vico.Cost__c,	// BLL25 reinstate
                    //BLL25d Cost__c						= 	0,
                    Selling_Price__c            =   vico.SellingPrice__c,
                    LockedOption__c             =   true
                );
                // Description__c = vico.CommercialQuoteOption__r.Description__c;
                newcqls.add(cql);
            }
			}	// BLL20a
        }
        if (quoteInstance.Chassis__c==null) {
            quoteInstance.VehicleInventory__c = null;
            currentVehicleId = null;
			//BLL17d quoteInstance.UnitNumber__c = null;
    	    //BLL17d quoteInstance.VIN__c = null;
    	    // BLL17a
        	quoteInstance.Chassis__c = backup.Chassis__c;
        	quoteInstance.Chassis_QTY__c = backup.Chassis_QTY__c;
        	quoteInstance.Chassis_Cost__c = backup.Chassis_Cost__c;
        	quoteInstance.Chassis_Price__c = backup.Chassis_Price__c;
        	quoteInstance.Chassis_Platform__c = backup.Chassis_Platform__c;
        	quoteInstance.Chassis_Platform_Wheelbase__c = backup.Chassis_Platform_Wheelbase__c;
			quoteInstance.UnitNumber__c = backup.UnitNumber__c;
        	quoteInstance.VIN__c = backup.VIN__c;
        	quoteInstance.ExteriorColor__c = backup.ExteriorColor__c;
        	quoteInstance.Mileage__c = backup.Mileage__c;
        	quoteInstance.StockVehChassisCost__c=backup.StockVehChassisCost__c;
        	quoteInstance.StockVehConversionCost__c=backup.StockVehConversionCost__c;
        	// BLL17a end 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Stock vehicle does not have a chassis assigned'));
            return false;
        }

		// BLL17c moved from right after rmvCommercialVehicleNoUpdate();
        quoteInstance.VehicleInventory__c = vehId;
		quoteInstance.UnitNumber__c = veh.dealer__Stock_Number__c;
        quoteInstance.VIN__c = veh.dealer__VIN__c;
        quoteInstance.StockVehChassisCost__c=veh.dealer__Vehicle_Cost__c;
   	    quoteInstance.StockVehConversionCost__c=veh.Conversion_Cost__c;
   	    //quoteInstance.InboundFreightCost__c=veh.InboundFreightCost__c;
   	    //quoteInstance.InboundFreightAmount__c = veh.InboundFreightCost__c;
   	    //quoteInstance.Freight_Cost__c = nullZero(quoteInstance.InboundFreightCost__c) + nullZero(quoteInstance.DeliveryFreightCost__c); 
   	    //quoteInstance.Freight_Amount__c = nullZero(quoteInstance.InboundFreightAmount__c) + nullZero(quoteInstance.DeliveryFreightAmount__c); 
	    currentVehicleId = quoteInstance.VehicleInventory__c;
		quoteInstance.ExteriorColor__c = veh.dealer__Exterior_Color__c;
		quoteInstance.Mileage__c = veh.dealer__Mileage__c;
		if (veh.Releasing_Dealer__c!=null) quoteInstance.ReleasingDealer__c = veh.Releasing_Dealer__c;	// BLL16a
		if (veh.Releasing_Dealer__c!=null) quoteInstance.TypeOfSale__c = 'Releasing Dealer';	// BLl16a
		// BLL17c end move

		getVehicleInfo();
        if (newcqls.size()>0) insert(newcqls);  
        //BLL20d if (rmvnonstock.size()>0) delete(rmvnonstock);	// BLL13a
        // BLL20a
        if (updToStock.size()>0) {
        	update(updToStock);
        }
        // BLL20a
		update quoteInstance;	// BLL16a

        return true;
    }

    // rmvCommercialVehicleNoUpdate
    //---------------------------------------------
    public void rmvCommercialVehicleNoUpdate() {
        //BLL24d List<CommercialQuoteLine__c> prevOptions = [
        //BLL24d    select Id 
        //BLL24d    from CommercialQuoteLine__c
        //BLL24d    where Commercial_Quote__c=:quoteInstance.Id and LockedOption__c=true 
        //BLL24d];
        //BLL24d if (prevOptions.size()>0) delete(prevOptions);	// BLLxd Just reset lockedoption flag instead
        // BLL24a
        //for(CommercialQuoteLine__c l : prevOptions) l.LockedOption__c=false;
        //if (prevOptions.size()>0) update(prevOptions);
        // BLL24a end
        quoteInstance.VehicleInventory__c = null;
        quoteInstance.Chassis__c = null;
        quoteInstance.Chassis_QTY__c = 1;
        //quoteInstance.Chassis_Cost__c = null;
        //quoteInstance.Chassis_Price__c = null;
        quoteInstance.Chassis_Platform__c = null;
        quoteInstance.Chassis_Platform_Wheelbase__c = null;
		quoteInstance.UnitNumber__c = null;
        quoteInstance.VIN__c = null;
        quoteInstance.ExteriorColor__c = null;
        quoteInstance.Mileage__c = null;
        quoteInstance.StockVehChassisCost__c=null;
        quoteInstance.StockVehConversionCost__c=null; 
        currentVehicleId = null;
        veh = null;
    }

    // rmvCommercialVehicle
    //---------------------------------------------
    public ApexPages.PageReference rmvCommercialVehicle() {
        ApexPages.PageReference rtnPage = ApexPages.currentPage();
        // RT1d rtnPage.setRedirect(true);
        // RT1a
        if(quoteInstance.Id != null) {
            rtnPage.getParameters().put('id', quoteInstance.Id);
        }
        rtnPage.setRedirect(false);
        // RT1a end
        rmvCommercialVehicleNoUpdate();
        update quoteInstance;
        // BLL24a remove stock option (LockedOption__c) flag
        List<CommercialQuoteLine__c> prevOptions = [
           select Id 
           from CommercialQuoteLine__c
           where Commercial_Quote__c=:quoteInstance.Id and LockedOption__c=true 
        ];
        for(CommercialQuoteLine__c l : prevOptions) l.LockedOption__c=false;
        if (prevOptions.size()>0) update(prevOptions);
        // BLL24a end
        return rtnPage;
    }
    // BLL7a end
    
    // BLL24a - Vehicle conversion cost will be used, so zero out 
    // costs for all stock options on the quote.
    // Need to save quote options after if any costs changed!
    //BLL25d - no longer needed
    //private List<CommercialQuoteLine__c> getConversionCostsToUpdate() {
    //	Decimal vehicleConversionCost = (veh!=null) ? veh.Conversion_Cost__c : 0;
    //	List<CommercialQuoteLine__c> allLines = getAllItems();
    //	List<CommercialQuoteLine__c> updLines = new List<CommercialQuoteLine__c>();
    //	for(CommercialQuoteLine__c cql : allLines) {
    //		// Will assign entire conversion cost to first option (they are sorted by highest price first)
    //		if (cql.LockedOption__c==true && vehicleConversionCost!=0) {
   	//			if (cql.Cost__c!=vehicleConversionCost) updLines.add(new CommercialQuoteLine__c(Id=cql.Id,Cost__c=vehicleConversionCost));
   	//			vehicleConversionCost = 0;
    //		} else if (cql.LockedOption__c==true && cql.Cost__c!=0) {
   	//			updLines.add(new CommercialQuoteLine__c(Id=cql.Id,Cost__c=0));
    //		}
    //	}
    //	return updLines;
    //}
    //BLL25d end
    // BLL24a end

    //RT1 - redirect to advanced search page, pass quote id if the record is saved, create cookie otherwise
    public PageReference advancedVehicleSearch() {
        PageReference searchPage = vehSearchPage;	//BLL29c new PageReference('/apex/VehicleSearchAdvanced');
        searchPage.getParameters().put('division','Commercial'); 	// BLL7a
        
        if(quoteInstance.Id != null) {
            update quoteInstance;
            //BLL30d searchPage.getParameters().put('quoteId', quoteInstance.Id);
            searchPage.getParameters().put('proposalId', quoteInstance.Id);	// BLL30a
        }
        else {
            
            QuoteWrapper wrapper = new QuoteWrapper(quoteInstance, newTask);	// BLL7c add newTask 
            String quoteJSON = JSON.serialize(wrapper);
            Cookie quoteCookie = new Cookie('quote', quoteJSON, null, -1, false);
            ApexPages.currentPage().setCookies(new Cookie[]{quoteCookie});
        }        
        
        
        searchPage.getParameters().put('cq', 'true');
        return searchPage;   
    }
    
    //RT1 - repopulate quote fields from cookie
    public CommercialQuote__c getQuoteFromCookie(CommercialQuote__c quote, Task newTask) {	// BLL7a add newTask
        //CommercialQuote__c quote = new CommercialQuote__c();
        Cookie quoteCookie = ApexPages.currentPage().getCookies().get('quote');
        System.debug(quoteCookie.getValue());
        System.debug((QuoteWrapper)JSON.deserialize(quoteCookie.getValue(), QuoteWrapper.class));
        QuoteWrapper wrapper = (QuoteWrapper)JSON.deserialize(quoteCookie.getValue(), QuoteWrapper.class);

    	System.debug('Compare quote id with cookie quote id ' + quote.Id + ' ? ' + wrapper.quoteId);	// BLL7a

        quote.Customer__c = wrapper.customerId;
        quote.Contact__c = wrapper.contact;
        quote.Salesperson__c = wrapper.salespersonId;
        quote.Email_Address__c = wrapper.email;
        quote.Location__c = wrapper.locationId;
        quote.Phone__c = wrapper.phoneNumber;
        quote.Mobile__c = wrapper.mobileNumber;
        quote.Street__c = wrapper.streetAddress;
        quote.City__c = wrapper.city;
        quote.County__c = wrapper.county;
        quote.State__c = wrapper.state;
        quote.F_O_B__c = wrapper.fob;
        quote.Zip__c = wrapper.zipCode;
        quote.Customer_Purchase_Order__c = wrapper.customerPO;
        quote.Opportunity__c = wrapper.oppId;
        quote.Accepted_Date__c = wrapper.acceptedDate;
        quote.Delivery_Date__c = wrapper.deliveryDate;
        quote.Terms__c = wrapper.terms;
        quote.Delivery_Notes__c = wrapper.deliveryNotes;
        quote.Job_Reference__c = wrapper.jobReference;
        quote.Delivery_Location__c = wrapper.deliveryLocation;
        quote.UnitNumber__c = wrapper.unitNumber;
        quote.VIN__c = wrapper.vin;
        quote.ServiceRepairOrder__c = wrapper.repairOrderId;
        quote.TypeOfSale__c = wrapper.typeOfSale;	// BLL16a

		// BLL7a
		newTask.Subject = wrapper.taskSubject;
		newTask.ActivityDate = wrapper.taskDate;
		// BLL7a end
        
        quoteCookie = new Cookie('quote', '', null, 0, false);
        ApexPages.currentPage().setCookies(new Cookie[]{quoteCookie});

        return quote;
    }

    //RT1 - wrapper for quotes to serialize/deserialize JSON
    public class QuoteWrapper {
        public String quoteId {get; set;}
        public String customerId {get; set;}
        public String contact {get; set;}
        public String salespersonId {get; set;}
        public String email {get; set;}
        public String locationId {get; set;}
        public String phoneNumber {get; set;}
        public String mobileNumber {get; set;}
        public String streetAddress {get; set;}
        public String city {get; set;}
        public String county {get; set;}
        public String state {get; set;}
        public String fob {get; set;}
        public String zipCode {get; set;}
        public String customerPO {get; set;}
        public String oppId {get; set;}
        public Date acceptedDate {get; set;}
        public Date deliveryDate {get; set;}
        public String terms {get; set;}
        public String deliveryNotes {get; set;}
        public String jobReference {get; set;}
        public String deliveryLocation {get; set;}
        public String unitNumber {get; set;}
        public String vin {get; set;}
        public String repairOrderId {get; set;}
        public String typeOfSale {get;set;}	// BLL16a
        // BLL7a
        public String taskSubject {get;set;}
        public Date taskDate {get;set;}
        // BLL7a end

        public QuoteWrapper(CommercialQuote__c quote, Task newTask) {	// BLL7c add newTask
            quoteId = quote.Id;
            customerId = quote.Customer__c;
            contact = quote.Contact__c;
            salespersonId = quote.Salesperson__c;
            email = quote.Email_Address__c;
            locationId = quote.Location__c;
            phoneNumber = quote.Phone__c;
            mobileNumber = quote.Mobile__c;
            streetAddress = quote.Street__c;
            city = quote.City__c;
            county = quote.County__c;
            state = quote.State__c;
            fob = quote.F_O_B__c;
            zipCode = quote.Zip__c;
            customerPO = quote.Customer_Purchase_Order__c;
            oppId = quote.Opportunity__c;
            acceptedDate = quote.Accepted_Date__c;
            deliveryDate = quote.Delivery_Date__c;
            terms = quote.Terms__c;
            deliveryNotes = quote.Delivery_Notes__c;
            jobReference = quote.Job_Reference__c;
            deliveryLocation = quote.Delivery_Location__c;
            unitNumber = quote.UnitNumber__c;
            vin = quote.VIN__c;
            repairOrderId = quote.ServiceRepairOrder__c;
            typeOfSale = quote.TypeOfSale__c;	// BLL16a
			// BLL7a
			taskSubject = newTask.Subject;
			taskDate = newTask.ActivityDate;
			// BLL7a end
        }
    } 

    @RemoteAction 
	// BLL32
    //public static String compileFDF(String fd) {
    global static String compileFDF(String fd) {

        Map<String, Object> js = (Map<String, Object>)JSON.deserializeUntyped(fd);
        String formId = (String)js.get('form');
        String objId = (String)js.get('obj');
        String urlPR = '/apex/FormFDF_CQ?id='+objId+'&fid='+formId;

        PageReference p = new PageReference(urlPR);
        Blob uContetent = p.getContent();

        return uContetent.toString();
    }


}