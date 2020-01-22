/**
 * ManagementDashboard
 * Tested by: ManagementDashboard_TC
 *
 * Code coverage summary:
 *	2017-08-25	79%	(481/612)
 *	2017-09-29	93% (310/332)
 *  2018-06-29	77% (293/377)
 *	2019-07-03	78%	(312/398)
 *
 *  2015-10-20  B. Leaman   BLL1 - Show all pending solution opportunities unless they have a "won" proposal.
 *                          Won proposals (not yet delivered) show in the top portion of the dashboard already.
 *  2015-12-29  B. Leaman   BLL2 - Show future proposals too (>=currentYear if no reportYear specified)
 *  2016-1-15   D. Ray      DR1 - Added Total_Before_Payments__c field
 *  2016-03-30  B. Leaman   BLL3 - Handle new commercial and retail salespeople (and managers)
 *  2016-05-03  B. Leaman   BLL4 - Don't limit results to 2000 -- not being returned as a list anyway; rather a string.
 *  2016-05-04  J. Kuljis   JVK1 - Removed Task SOQL filter Status='Not Started'
 *  2016-05-20  D. Ray      DR2 - Adding Commercial Quote info
 *  2016-05-20  D. Ray      DR2 - Adding Commercial Quote info
 *  2017-05-03  S. Travarca	MTEK - Opened query for mgmt dashboard to include commercial proposals
 *	2017-05-19	B. Leaman	BLL5 IR-0012412 - Default to Vehicle only GP.
 *	2017-08-24	B. Leaman	BLL6 Sales flash hitting max heap size; restructure code for budgets too.
 *	2017-09-28	B. Leaman	BLL7 - Heap issue again. Trying out summarizing anything not in current quarter.
 *  2017-12-21	B. Leaman	BLL8 - More selection criteria (DME/Other, Financial, Wholesale, Chassis/Conversion, Equipment);
 *							and include budgets as separate rows of data so that stores show up even if they have no proposals;
 *	2018-06-29	B. Leaman	BLL9 - fix heap size limitation - was reading prior month deals and not displaying them on management dashboard
 *	2018-08-23	B. Leaman	BLL10 - include "quote" solution opportunities on-screen (Management Dashboard page)
 *	2018-12-05	B. Leaman	W-000510	BLL11 - allow next year selection beginning in Q3
 *	2019-01-08	B. Leaman	W-000534 BLL12 - Don't show system administrator or corporate tasks.
 *	2019-01-08	B. Leaman	W-000714 BLL13 - Add "Home Access" to proposal type picklist
 */
public with sharing class ManagementDashboard {
    public String action {get;set;} 
    public Boolean showDashboard {get;set;}
    private Decimal splitat = 50000;	// BLL6a
	private transient MobilityForceSettings__c mfs;	// BLL10

    public static Integer reportYear {get;set;}
    public static String reportYear_str {
    	get {return String.valueOf(reportYear);} 
    	set {reportYear=Integer.valueOf(value);}
    }
    public static Integer reportMonth {get; set;}
    public static String reportMonth_str {
    	get {return String.valueOf(reportMonth);} 
    	set {reportMonth=Integer.valueOf(value);}
    }
    private String reportStyle {get;set;}
    public List<String> selReportStyles {get; set;}	// BLL8a
    private String reportKind {get;set;}
    public List<String> selReportKinds {get; set;}	// BLL8a
    private String reportType {get;set;}	// BLL8a
    public List<String> selReportTypes {get; set;}	// BLL8a

    private String userLocKey {get;set;}
    private String userId {get;set;}

    public Boolean isCMC = false; 

    public dealer__Dealer_Location__c location {get;set;}

    public List<dealer__Dealer_Location__c> locationList {get;set;}

    public String readResponse {get; set; }   
    public List<SelectOption> recentYears {get;private set;}	// BLL8a
	// BLL12
	public List<String> CorporateRoles {get;private set;}
	// BLL12
    
    public ManagementDashboard() {
		System.debug('constructor');	// BLL6a
		
        // DO USER STUFF
        this.userId = UserInfo.getUserId();

        User activeUser = [Select Id, Name, UserRole.Name, Profile.Name, Division FROM User WHERE Id =: userId LIMIT 1];

        //BLL3d if (activeUser.Profile.Name == 'MW Sales People CMC') {
        //BLL3d     isCMC = true;
        //BLL3d }
        isCMC = activeUser.Profile.Name.contains('CMC');  // BLL3a

		// BLL12
		MobilityForceSettings__c mfs = MobilityForceSettings__c.getOrgDefaults();
		CorporateRoles = new List<String>();
		if (!String.isBlank(mfs.Corporate_Roles__c))
			for(String s : mfs.Corporate_Roles__c.split(','))
				CorporateRoles.add(s.trim());
		// BLL12 end

        // Setup user location for filtering
        userLocKey = activeUser.Division;

        if(userLocKey==null) userLocKey = 'AKR';    // BLL3c - reformat to 1 line
        
        location = [SELECT Id, Name, dealer__Company_Number__c, Region__c, Commercial_Region__c, Division__c FROM dealer__Dealer_Location__c WHERE dealer__Company_Number__c =: userLocKey LIMIT 1];

        String userRole =  activeUser.UserRole==null ? '' : activeUser.UserRole.Name;   // BLL3c handle null role during tests

        if( userRole.contains('Region') ) {
            //String userRegion = activeUser.UserRole.Name.replace('Region ','');
            if(reportKind != null && !reportKind.contains('retail') && !reportKind.contains('double')){ // reportKind == 'commercialkind' 
               locationList = [SELECT Id, Name FROM dealer__Dealer_Location__c WHERE Commercial_Region__c =: location.Commercial_Region__c];
            }else{
               locationList = [SELECT Id, Name FROM dealer__Dealer_Location__c WHERE Region__c =: location.Region__c];
            }
        } else  if ( userRole.contains('Store'))  {
            locationList = [SELECT Id, Name FROM dealer__Dealer_Location__c WHERE dealer__Company_Number__c =: userLocKey];
            //locationList = [SELECT Id, Name FROM dealer__Dealer_Location__c];
        } else {
            locationList = [SELECT Id, Name FROM dealer__Dealer_Location__c];
        }

        /** Report Year */
        recentYears = new List<SelectOption>();
		// BLL11
		if (Date.today().month()>9) {
			String y = String.valueOf(Date.today().year()+1);
			recentYears.add(new SelectOption(y,y));
		}
		// BLL11 end
        for(Integer i=0; i<6; i++) {
        	String y = String.valueOf(Date.today().year()-i);
        	recentYears.add(new SelectOption(y, y));
        }

		if (ApexPages.currentPage()!=null) System.debug(ApexPages.currentPage().getParameters());

        //BLL8d if(ApexPages.currentPage()!=null && ApexPages.currentPage().getParameters().get('reportYear')!= null) reportYear = Integer.valueOf( ApexPages.currentPage().getParameters().get('reportYear') ); 
        if(ApexPages.currentPage()!=null && ApexPages.currentPage().getParameters().get('reportYear')!= null) reportYear_str = ApexPages.currentPage().getParameters().get('reportYear');
        else reportYear = Date.today().year();
        
        /** Report Month */
        //BLL8d if(ApexPages.currentPage()!=null && ApexPages.currentPage().getParameters().get('reportMonth')!= null) reportMonth = Integer.valueOf( ApexPages.currentPage().getParameters().get('reportMonth') ); 
        if(ApexPages.currentPage()!=null && ApexPages.currentPage().getParameters().get('reportMonth')!= null) reportMonth_str = ApexPages.currentPage().getParameters().get('reportMonth');	// BLL8a
        else reportMonth = Date.today().month();	// BLL8a


        /** Report Style */
        //if(ApexPages.currentPage().getParameters().get('reportStyle') != null) {
        //    this.reportStyle = String.valueOf( ApexPages.currentPage().getParameters().get('reportStyle') ); 
        //} else {
        //    // Current Year is default
        //    //BLL5d this.reportStyle = 'All GP';
        //    this.reportStyle = 'VEH Only GP';	// BLL5a
        //}
        // BLL6a
        // this.reportStyle = 'conversion,equipment';
        if (ApexPages.currentPage()!=null) this.reportStyle = String.valueOf(ApexPages.currentPage().getParameters().get('reportStyle'));
        if (String.isBlank(this.reportStyle)) this.reportStyle='veh';
		selectReportStyles(this.reportStyle);

        /** Report Kind DR2 */
        //if(ApexPages.currentPage().getParameters().get('reportKind') != null) {
        //    this.reportKind = String.valueOf( ApexPages.currentPage().getParameters().get('reportKind') ); 
        //} else {
        //    // Current Year is default
        //    this.reportKind = 'retailkind';
        //}
        // BLL6a
        // this.reportKind = 'retail';
        if (ApexPages.currentPage()!=null) this.reportKind = String.valueOf( ApexPages.currentPage().getParameters().get('reportKind') );
        if (String.isBlank(this.reportKind)) this.reportKind = 'retail';
        selectReportKinds(this.reportKind);
        //  /DR2

        if (ApexPages.currentPage()!=null) this.reportType = String.valueOf(ApexPages.currentPage().getParameters().get('reportType'));
		// BLL13
        //if (String.isBlank(this.reportType)) this.reportType='conversion,equipment,financial,dme,wholesale';
		if (String.isBlank(this.reportType)) this.reportType='conversion,equipment,financial,dme,homeaccess,wholesale';
		// BLL13
		selectReportTypes(this.reportType);


        /*** ACTION KEYS ***/

        //if(ApexPages.currentPage().getParameters().get('action')== 'read_deals') action='read_deals';   // BLL3c reformat

        //if(ApexPages.currentPage().getParameters().get('action')== 'read_cdeals') action='read_cdeals'; // BLL3c reformat

        //if(ApexPages.currentPage().getParameters().get('action')== 'read_sales_ups') action='read_sales_ups';   // BLL3c reformat

        //if(ApexPages.currentPage().getParameters().get('action')== 'read_tasks') action='read_tasks';   // BLL3c reformat

        //if(ApexPages.currentPage().getParameters().get('action')== 'read_cdeals_new') action='read_cdeals_new';   // BLL3c reformat
		action = '';
		if (ApexPages.currentPage()!=null) action = ApexPages.currentPage().getParameters().get('action');

        /** Show dashboard check */
        //if(ApexPages.currentPage().getParameters().get('type')== 'dashboard') {
        //    this.showDashboard = true;
        //} else {
        //    this.showDashboard = false;
        //}
        // BLL6a
        this.showDashboard = false;
        if (ApexPages.currentPage()!=null) this.showDashboard = (ApexPages.currentPage().getParameters().get('type')== 'dashboard');
        
        // BLL6a - get split location from setting
        mfs = MobilityForceSettings__c.getOrgDefaults();
        if (mfs!=null && mfs.Sales_Flash_split_deals__c!=null && mfs.Sales_Flash_split_deals__c>0) splitat = mfs.Sales_Flash_split_deals__c;
    }

    //public PageReference goAction() {
        //return null;
    //}

	private void selectReportStyles(String styles) {
		if (String.isBlank(styles)) styles='veh';
		selReportStyles = styles.split(',');
	}
	private void selectReportKinds(String kinds) {
		if (String.isBlank(kinds)) kinds='retail';
		selReportKinds = kinds.split(',');
	}
	private void selectReportTypes(String types) {
		// BLL13
		//if (String.isBlank(types)) types='conversion,equipment,financial,dme,wholesale';
		if (String.isBlank(types)) types='conversion,equipment,financial,dme,homeaccess,wholesale';
		// BLL13
		selReportTypes = types.split(',');
	}


	// Used by ManagementDashboard
	// BLL9a - limit to current & future month deliveries (json string exceeding heap size)
    public List<dealer__Deal__c> getDealList() {
		System.debug('getDealList');
		//MTEK - Removed RecordType.Name != Commercial to add all Proposals to Mgmt Dashboard
        String queryStart = 'SELECT Id, Name, dealer__Salesperson_1__c, dealer__Salesperson_1__r.Name, dealer__Salesperson_1_Name__c, dealer__Deal_Type__c, '
        	+ ' dealer__Store_Location__c,dealer__Store_Location__r.Name, dealer__Model__c, dealer__Buyer__c, dealer__Buyer__r.Name, ' 
        	+ ' dealer__Sale_Price__c, Total_Price__c, Total_Before_Payments__c, '
        	+ ' dealer__Total_Gross__c, Commissionable_Gross__c, dealer__Front_End_Gross__c, '
        	+ ' Proposed_Delivery_Month__c, Proposed_Delivery_Date__c, dealer__Status__c ' 
        	+ ' FROM dealer__Deal__c ' 
        	+ ' WHERE dealer__Status__c LIKE \'Won%\' ';
        //dealer__Status__c != \'Lost\' AND dealer__Status__c != \'Pending\'

        String queryMiddle = ' AND dealer__Store_Location__c in: locationList ';

        if (isCMC) queryMiddle += ' AND dealer__Salesperson_1__c =: userId ';

		// BLL9 - reportYear is already set to current year if not specified, and ManagementDashboard only ever runs
		// using current year and only displays current and future month data, so no need to return prior month deals.
        //BLL9d if (reportYear!=null) queryMiddle += ' AND CALENDAR_YEAR(Proposed_Delivery_Date__c) =: reportYear '; 
        //BLL9d else { // BLL2a
            //BLL2d queryMiddle += ' AND CALENDAR_YEAR(Proposed_Delivery_Date__c) >= ' + String.valueOf(Date.today().year()) + ' '; // BLL2a
            // Include prior years if not Won - Posted
            String bom = String.valueOf(Date.newInstance(Date.today().year(),Date.today().month(),1));
            queryMiddle += ' AND (Proposed_Delivery_Date__c >= ' + bom + ' '; // BLL2a
            queryMiddle += ')';	// BLL9a - UI was ignoring deals prior to reporting month (current month)
            //BLL9d queryMiddle +=      ' OR (dealer__Status__c != \'Won - Posted\' AND Proposed_Delivery_Date__c < ' + bom + ')) '; // BLL2a
        //BLL9d }

		Set<String> types = new Set<String>();
		if (reportType!=null && reportType.contains('conversion'))
			types.addAll(new Set<String>{'Chassis/Conversion','Retail Vehicle Sale'});
		if (reportType!=null && reportType.contains('equipment'))
			types.addAll(new Set<String>{'Equipment Only','Equipment Only Sale'});
		if (reportType!=null && reportType.contains('financial'))
			types.add('Financial Products');
		if (reportType!=null && reportType.contains('dme'))
			types.add('DME/Other');
		// BLL13
		if (reportType!=null && reportType.contains('homeaccess'))
			types.add('Home Access');
		// BLL13
		if (reportType!=null && reportType.contains('wholesale'))
			types.add('Wholesale');
		// BLL13
		//if (types.size()==0) types.addAll(new Set<String>{'Chassis/Conversion','Retail Vehicle Sale','Equipment Only','Equipment Only Sale','Financial Products','DME/Other'});
		if (types.size()==0) types.addAll(new Set<String>{'Chassis/Conversion','Retail Vehicle Sale','Equipment Only','Equipment Only Sale','Financial Products','DME/Other','Home Access'});
		// BLL13
		if (types.size()>0)
			queryMiddle += ' AND dealer__Deal_Type__c in :types '; 
		
        String queryEnd = 'ORDER BY Proposed_Delivery_Date__c ASC'; // BLL4d ' limit 2000';

        /*List<dealer__Deal__c> deals = [SELECT Id, Name, dealer__Salesperson_1__c, dealer__Salesperson_1__r.Name, dealer__Salesperson_1_Name__c , dealer__Store_Location__c,dealer__Store_Location__r.Name, dealer__Model__c, dealer__Buyer__c, dealer__Buyer__r.Name, dealer__Sale_Price__c, Total_Price__c, dealer__Total_Gross__c, Commissionable_Gross__c, Proposed_Delivery_Month__c, Proposed_Delivery_Date__c, dealer__Status__c
            FROM dealer__Deal__c 
            WHERE dealer__Status__c != 'Lost'
                AND dealer__Status__c != 'Pending'
                AND dealer__Store_Location__c in: locationList
            ORDER BY Proposed_Delivery_Date__c ASC limit 2000];*/

        //return deals;
        //
        System.debug(queryStart+ queryMiddle + queryEnd);
        return Database.query( queryStart + queryMiddle + queryEnd );
    }

    //AND dealer__Status__c != 'Won - Delivered'
    //AND dealer__Status__c != 'Won - Posted'

    // Access via action
    // Used by ManagementDashboard
    public String getDealsListJSON() {
		System.debug('getDealsListJSON');

        return JSON.serializePretty(getDealList());
    }

	// Used by ManagementDashboard
    public String getTaskList() {
		System.debug('getTaskList');

        // Get User Ids
        // BLL12
		//List<User> users = [SELECT Id FROM User WHERE Division =:userLocKey];
        List<User> users = [
			SELECT Id 
			FROM User 
			WHERE Division =:userLocKey
			  AND UserRole.Name NOT IN :CorporateRoles
		];
		// BLL12 end
        List<Id> Ids = new List<Id>();

        if (isCMC) Ids.add(userId); // BLL3c reformat
        else for (User u: users) Ids.add(u.Id); // BLL3c reformat

        // Get tasks by user
        List<Task> tasks = [SELECT Id, Owner.Name, Who.Name,What.Name, Subject, ActivityDate, Status 
                FROM Task 
                WHERE ActivityDate <= :Date.today() 
                    AND Owner.Id in:Ids
                    AND isClosed = false
                ORDER BY ActivityDate ASC
                LIMIT 1000];

                // JVK1

        return JSON.serializePretty(tasks);
    }

	// Used by ManagementDashboard
    public String getSalesUpList() {
		System.debug('getSalesUpList');
		// BLL10a
		mfs = MobilityForceSettings__c.getOrgDefaults();
		if (mfs==null) mfs = new MobilityForceSettings__c();
		if (String.isBlank(mfs.Dashboard_Sol_Opp_Status__c)) mfs.Dashboard_Sol_Opp_Status__c='Pending';
		List<String> sosts = mfs.Dashboard_Sol_Opp_Status__c.split(',');
		if (sosts.size()<1) sosts.add('Pending');	// Default value

        // BLL1d String queryStart = 'SELECT Id, Name, dealer__Customer_Account__c, dealer__Customer_Account__r.Name, dealer__Salesperson_1__c, dealer__Salesperson_1__r.Name, dealer__Source__c, Decision_Date__c, Company__c FROM dealer__Sales_Up__c WHERE dealer__Car_Deal__c = null AND dealer__Lead_Status__c = \'Pending\' AND Company__c  in: locationList ';
        // BLL1a - new query - don't bother checking for a proposal (deal)
        //BLL10d String queryStart = 'SELECT Id, Name, dealer__Customer_Account__c, dealer__Customer_Account__r.Name, dealer__Salesperson_1__c, dealer__Salesperson_1__r.Name, dealer__Source__c, Decision_Date__c, Company__c FROM dealer__Sales_Up__c WHERE dealer__Lead_Status__c = \'Pending\' AND Company__c  in: locationList ';
        String queryStart = 'SELECT Id, Name, dealer__Customer_Account__c, dealer__Customer_Account__r.Name, dealer__Salesperson_1__c, dealer__Salesperson_1__r.Name, dealer__Source__c, Decision_Date__c, Company__c FROM dealer__Sales_Up__c WHERE dealer__Lead_Status__c in :sosts AND Company__c  in :locationList ';
		// BLL10a end

        if (isCMC) queryStart += ' AND dealer__Salesperson_1__c =: userId ';

        String queryTail = ' ORDER BY Name ASC limit 2000';

        /*
        List<dealer__Sales_Up__c> sups = [SELECT Id, Name, dealer__Customer_Account__c, dealer__Customer_Account__r.Name, dealer__Salesperson_1__c, dealer__Salesperson_1__r.Name, dealer__Source__c, Decision_Date__c, Company__c
            FROM dealer__Sales_Up__c
            WHERE dealer__Car_Deal__c = null
                AND dealer__Lead_Status__c = 'Pending'
                AND Company__c  in: locationList
                
            ORDER BY Name ASC limit 2000];
        */
        
        // BLL1d List<dealer__Sales_Up__c> sups = Database.query( queryStart + queryTail );
        // BLL1a remove any that have won deals
        Map<Id, dealer__Sales_Up__c> supmap = new Map<Id, dealer__Sales_Up__c>((List<dealer__Sales_Up__c>) Database.query(queryStart + queryTail ));
        Set<Id> supIds = supmap.keySet();
        List<dealer__Deal__c> wondeals = [select Id, Name, dealer__Sales_Lead__c from dealer__Deal__c where dealer__Sales_Lead__c in :supIds and dealer__Status__c like 'Won%'];
        for (dealer__Deal__c d : wondeals) if (supmap.containsKey(d.dealer__Sales_Lead__c)) supmap.remove(d.dealer__Sales_Lead__c);
        List<dealer__Sales_Up__c> sups = supmap.values();
        // BLL1a end

        return JSON.serializePretty(sups);
    }
    
	//BLL8d public static Set<String> budgetLocList = new Set<String>();
    //BLL8d public static List<Budget__c> dealBudgetlist = [Select Id, Name, Month_Abbr__c, Month__c, Year__c, Budget_Id__c, Budget_Type__c, Dollars__c From Budget__c Where Budget_Type__c = 'Retail'];
    //BLL8d public static List<Budget__c> commBudgetlist = [Select Id, Name, Month_Abbr__c, Month__c, Year__c, Budget_Id__c, Budget_Type__c, Dollars__c From Budget__c Where Budget_Type__c = 'Commercial'];
    public Set<Integer> Q1 = new Set<Integer>{1,2,3};
    public Set<Integer> Q2 = new Set<Integer>{4,5,6};
    public Set<Integer> Q3 = new Set<Integer>{7,8,9};
    public Set<Integer> Q4 = new Set<Integer>{10,11,12};
    public static Set<String> qMonths = new Set<String>();
    public static Set<String> yMonths = new Set<String>();
    public Set<Integer> CurrQ = null;	// BLL8a
    
    public class cDeal {
        private transient String reportStyle {get;set;}
        private transient String reportKind {get; set;}
        public Boolean isComQuote{get; set;}
        public String currentMonthi {get; set;}
        public String currentYeari {get; set;}
        
        public String Id {get; set;}
        public String locId {get; set;}
        public String locName {get; set; }
        public String Name {get; set; }
        public String salesPersonId {get; set; }
        public String salesPersonName {get; set; }
        public String buyerId {get; set; }
        public String buyerName {get; set; }
        public String status {get; set; }
        public String model {get; set; }
        public String deliveryMonth {get; set; }
        public String region {get; set; }
        public String division {get; set;}

        public Date deliveryDate {get; set; }
        //public Decimal salePrice {get; set; } //DR2
        public Decimal totalPrice {get; set; }
        public Decimal totalGross {get; set; }
        //public Decimal totalPropGross {get; set; } //DR2
        public Decimal totalESCGross {get; set; }
        public Decimal grandTotalGross {get; set; }
        
        public Boolean isCurrentMonth {get;set;}
        public Boolean isQuarterly {get; set;}
        public Boolean isYearly {get; set;}
        public Boolean useBudget {get; set;}
        public Decimal budgetPercentage {get; set;}
        public Decimal quarterPercentage {get; set;}
        public Decimal yearPercentage {get; set;}
        
        //private dealer__Dealer_Location__c loc {get; set ;}
		
        private transient Map<Integer, String> monthsMap = new Map<Integer, String>{
            1 => 'JAN', 2 => 'FEB', 3 => 'MAR', 4 => 'APR', 
            5 => 'MAY', 6 => 'JUN', 7 => 'JUL', 8 => 'AUG', 
            9 => 'SEP', 10 => 'OCT', 11 => 'NOV', 12 => 'DEC'
        };
		
        // DR2a
        //BLL7d cDeal(dealer__Deal__c deal, CommercialQuote__c quote, String reportStyle){
        //BLL7d     this.reportStyle = reportStyle;
        //BLL7d     this.reportKind = reportKind;
        //BLL7d     this.isCurrentMonth = false;
        //BLL7d     this.isQuarterly = false;
        //BLL7d     this.isYearly = false;
        //BLL7d     this.useBudget = false;
        //BLL7d     this.isComQuote = false;
            // is this a commercial quote?
            //BLL7d if(quote != null && deal == null) {
            //BLL7d    processCommercialQuote(quote);
            // Deal as Default
            //BLL7d } else {
        //BLL7d         processStandardDeal(deal);
            //BLL7d }
        //BLL7d }
		
        //cDeal Overload method for Flash Sales page
        cDeal(dealer__Deal__c deal, CommercialQuote__c quote, String reportStyle, String reportKind,
              							Boolean currMonth, Boolean Qrtly, Boolean Yrly, Boolean isCommercialQuote){
            this.reportStyle = reportStyle;
            this.reportKind = reportKind;
            this.isCurrentMonth = currMonth;
            this.isQuarterly = Qrtly;
			this.isYearly = Yrly;
            this.useBudget = true;
            this.isComQuote = isCommercialQuote;
            // is this a commercial quote?
            //BLL7d if(quote != null && deal == null) {
            //BLL7d     processCommercialQuote(quote);
            // Deal as Default
            //BLL7d } else {
                processStandardDeal(deal);
                //getDealBudget(deal);
            //BLL7d }
            
        }
        
        // BLL8a add budget amt
        cDeal(Budget__c budget, String reportStyle,String reportKind, Decimal amt, Boolean currMonth, Boolean Qrtly, Boolean Yrly) {
        	System.debug('cDeal:budget');
            this.reportStyle = reportStyle;
            this.reportKind = reportKind;
            this.isCurrentMonth = currMonth;
            this.isQuarterly = Qrtly;
			this.isYearly = Yrly;
            this.useBudget = true;
            this.Name = 'Budget';
            
			this.budgetPercentage = (this.isCurrentMonth) ? amt : 0;
            this.quarterPercentage = (this.isQuarterly) ? amt :  0;
            this.yearPercentage = (this.isYearly) ? amt : 0;
            this.currentMonthi = monthsMap.get( reportMonth );
      		this.currentYeari = string.valueOf(reportYear); 
            
            this.Id             = null;
            this.locId          = budget.Location__c;
            this.locName        = budget.Location__r.Name;
            this.region         = budget.Location__r.Region__c;
            this.division 		= budget.Location__r.Division__c;
            
            this.Name           = budget.Name;
            //this.salesPersonId  = deal.dealer__Salesperson_1__c;
            //this.salesPersonName = deal.dealer__Salesperson_1__r.Name;
            //this.buyerId        = deal.dealer__Buyer__c;
            //this.buyerName      = deal.dealer__Buyer__r.Name;
            //this.status         = deal.dealer__Status__c;
            //this.model          = deal.dealer__Model__c;
            //this.deliveryMonth  = deal.Proposed_Delivery_Month__c;
            //this.deliveryDate   = deal.Proposed_Delivery_Date__c;
            this.deliveryMonth	= budget.Month_Abbr__c + '_' +  String.valueOf(budget.Year__c);
            this.deliveryDate	= Date.newInstance(Integer.valueOf(budget.Year__c), Integer.valueOf(budget.Month__c), 1);
            //this.totalPrice     = nullZero(deal.Total_Before_Payments__c);
            //this.totalGross     = nullZero(deal.Commissionable_Gross__c);
            //this.totalESCGross = nullZero(deal.dealer__Total_service_Contracts_Gross__c);
			this.totalPrice = 0;
			this.totalGross = 0;
			this.totalESCGross = 0;

            // repurpose grandTotalGross
            //if(this.reportStyle == 'F&I GP') this.grandTotalGross  = nullZero(this.totalESCGross);
            //else if (this.reportStyle == 'VEH Only GP') this.grandTotalGross  = nullZero(this.totalGross);
            //else this.grandTotalGross  = (this.totalESCGross != null ? this.totalESCGross : 0) + (this.totalGross != null ? this.totalGross : 0);
			this.grandTotalGross = 0;

            //-    Show F&I GP only = totalESCGross
            //-    Show vehicle GP only = totalGross
            //-    Show all GP (default value) = grandTotalGross

        }
        // BLL8a end

        // BLL7a - used to accumulate to a summary entry for older posted proposals
        public void addStandardDeal(dealer__Deal__c deal) {
        	System.debug('addStandardDeal: ' + deal.Name);
            //this.locId          = deal.dealer__Store_Location__c;
            //this.locName        = deal.dealer__Store_Location__r.Name;
            //this.region         = deal.dealer__Store_Location__r.Region__c;
            //this.division 		= deal.dealer__Store_Location__r.Division__c;
            this.Name           = 'Summary';	// deal.Name;
            //this.salesPersonId  = deal.dealer__Salesperson_1__c;
            //this.salesPersonName = deal.dealer__Salesperson_1__r.Name;
            //this.buyerId        = deal.dealer__Buyer__c;
            this.buyerName      = 'various';	// deal.dealer__Buyer__r.Name;
            //this.status         = deal.dealer__Status__c;
            this.model          = 'various';	//deal.dealer__Model__c;
            //this.deliveryMonth  = deal.Proposed_Delivery_Month__c;
            //this.deliveryDate   = deal.Proposed_Delivery_Date__c;
            this.totalPrice     += nullZero(deal.Total_Before_Payments__c);
            this.totalGross     += nullZero(deal.Commissionable_Gross__c);
            this.totalESCGross += nullZero(deal.dealer__Total_service_Contracts_Gross__c);
            // repurpose grandTotalGross
            //if(this.reportStyle == 'F&I GP') {
            //    this.grandTotalGross  = nullZero(this.totalESCGross);
            //} else if (this.reportStyle == 'VEH Only GP') {
            //    this.grandTotalGross  = nullZero(this.totalGross);
            //} else {
            //    // Default
            //    this.grandTotalGross  = (this.totalESCGross != null ? this.totalESCGross : 0) + (this.totalGross != null ? this.totalGross : 0);
            //}
            this.grandTotalGross = 0;
            if (this.reportStyle!=null && this.reportStyle.contains('veh'))
            	this.grandTotalGross += nullZero(this.totalGross);
            if (this.reportStyle!=null && this.reportStyle.contains('esc'))
            	this.grandTotalGross += nullZero(this.totalESCGross);
            //-    Show F&I GP only = totalESCGross
            //-    Show vehicle GP only = totalGross
            //-    Show all GP (default value) = grandTotalGross
            //this.currentMonthi = monthsMap.get( reportMonth );
      		//this.currentYeari = string.valueOf(reportYear); 
        }
        public Decimal nullZero(Decimal d) {
        	return d==null ? 0 : d;
        }
        public void processStandardDeal(dealer__Deal__c deal){
        	System.debug('processStandardDeal: ' + deal.Name);
            this.Id             = deal.Id;
            this.locId          = deal.dealer__Store_Location__c;
            this.locName        = deal.dealer__Store_Location__r.Name;
            this.region         = deal.dealer__Store_Location__r.Region__c;
            this.division 		= deal.dealer__Store_Location__r.Division__c;
            this.Name           = deal.Name;
            this.salesPersonId  = deal.dealer__Salesperson_1__c;
            this.salesPersonName = deal.dealer__Salesperson_1__r.Name;
            this.buyerId        = deal.dealer__Buyer__c;
            this.buyerName      = deal.dealer__Buyer__r.Name;
            this.status         = deal.dealer__Status__c;
            this.model          = deal.dealer__Model__c;
            this.deliveryMonth  = deal.Proposed_Delivery_Month__c;
            this.deliveryDate   = deal.Proposed_Delivery_Date__c;
            this.totalPrice     = nullZero(deal.Total_Before_Payments__c);
            this.totalGross     = nullZero(deal.Commissionable_Gross__c);
            //this.totalGross     = deal.dealer__Total_Gross__c;
            //this.totalGross     = deal.dealer__Front_End_Gross__c;

            // calculate Protection Product gross
            /*
                if(deal.Total_Protection_Products__c != null && deal.Warranty_Cost__c != null) {
                    this.totalESCGross  = deal.Total_Protection_Products__c - deal.Warranty_Cost__c;
                } else {
                    this.totalESCGross = 0;
                }
            */
        
            this.totalESCGross = nullZero(deal.dealer__Total_service_Contracts_Gross__c);

            // repurpose grandTotalGross

            //if(this.reportStyle == 'F&I GP') this.grandTotalGross  = nullZero(this.totalESCGross);
            //else if (this.reportStyle == 'VEH Only GP') this.grandTotalGross  = nullZero(this.totalGross);
            //else this.grandTotalGross  = (this.totalESCGross != null ? this.totalESCGross : 0) + (this.totalGross != null ? this.totalGross : 0);
            this.grandTotalGross = 0;
            if (this.reportStyle!=null && this.reportStyle.contains('veh'))
            	this.grandTotalGross += nullZero(this.totalGross);
            if (this.reportStyle!=null && this.reportStyle.contains('esc'))
            	this.grandTotalGross += nullZero(this.totalESCGross);

            //-    Show F&I GP only = totalESCGross
            //-    Show vehicle GP only = totalGross
            //-    Show all GP (default value) = grandTotalGross
			this.budgetPercentage = 0;
            this.quarterPercentage = 0;
            this.yearPercentage = 0;
            this.currentMonthi = monthsMap.get( reportMonth );
      		this.currentYeari = string.valueOf(reportYear); 
            //this.salePrice    = deal.dealer__Sale_Price__c; // deprecated
            // budgets will be added later 
        }

        //BLL7d public void processCommercialQuote(CommercialQuote__c quote) {
		//BLL7d 
        //BLL7d     this.Id             = quote.Id;
        //BLL7d     this.Name           = quote.Name;
        //BLL7d     this.locId          = quote.Location__c;
        //BLL7d     this.locName        = quote.Location__r.Name;
        //BLL7d     this.region         = (this.reportKind == 'commercialkind' ? quote.Location__r.Commercial_Region__c : quote.Location__r.Region__c);
        //BLL7d     this.division			= quote.Location__r.Division__c;
        //BLL7d     this.salesPersonId  = quote.Salesperson__c;
        //BLL7d     this.salesPersonName = quote.Salesperson__r.Name;
        //BLL7d     this.buyerId        = quote.Customer__c;
        //BLL7d     this.buyerName      = quote.Customer__r.Name;
        //BLL7d     this.status         = (quote.Status__c == 'Booked') ? 'Won - Posted' : quote.Status__c;
        //BLL7d     //this.status         = quote.Status__c;
        //BLL7d     this.deliveryDate   = quote.Delivery_Date__c;
        //BLL7d     this.deliveryMonth  = monthsMap.get( quote.Delivery_Date__c.month() )+'_'+quote.Delivery_Date__c.year();
        //BLL7d     this.totalPrice     = quote.Total__c;
        //BLL7d     this.totalGross     = quote.Total_Gross_Profit__c;
        //BLL7d     //this.model          = quote.dealer__Model__c;
		//BLL7d 
		//BLL7d     this.totalESCGross = 0; // There is no ESC for Commercial
		//BLL7d 
        //BLL7d     if(this.reportStyle == 'F&I GP') {
        //BLL7d         this.grandTotalGross  = 0;
        //BLL7d     } else if (this.reportStyle == 'VEH Only GP') {
        //BLL7d         this.grandTotalGross  = this.totalGross;
        //BLL7d     } else {
        //BLL7d         // Default
        //BLL7d         this.grandTotalGross  = this.totalESCGross + this.totalGross;
        //BLL7d     }
        //BLL7d     this.budgetPercentage = 0;
		//BLL7d 	this.quarterPercentage = 0;
        //BLL7d     this.yearPercentage = 0;
        //BLL7d     this.currentMonthi = monthsMap.get( reportMonth );
      	//BLL7d 	this.currentYeari = string.valueOf(reportYear); 
        //BLL7d }
        // /DR2a
    }

	// Used by ?
    //BLL7d public List<cDeal> getcDealList() {
	//BLL7d 	System.debug('getcDealList');
	//BLL7d 	//BLL7d if (offs==null) offs=0;	// BLL6a
	//BLL7d 	//BLL7d if (lim==null) lim=50000;	// BLL6a
	//BLL7d 
    //BLL7d     List<cDeal> cDealList = new List<cDeal>();
	//BLL7d 
    //BLL7d     String queryStart = 'SELECT Id, Name, dealer__Salesperson_1__c, dealer__Salesperson_1__r.Name, dealer__Salesperson_1_Name__c , dealer__Store_Location__c,dealer__Store_Location__r.Name,dealer__Store_Location__r.Region__c,dealer__Store_Location__r.Division__c, dealer__Model__c, dealer__Buyer__c, dealer__Buyer__r.Name, dealer__Sale_Price__c, Total_Price__c, Total_Before_Payments__c, dealer__Total_Gross__c,Commissionable_Gross__c,dealer__Front_End_Gross__c, Proposed_Delivery_Month__c, Proposed_Delivery_Date__c, dealer__Status__c, Total_Protection_Products__c, Warranty_Cost__c, dealer__Total_service_Contracts_Gross__c FROM dealer__Deal__c  WHERE RecordType.Name != \'Commercial\' AND dealer__Status__c LIKE \'Won%\' ';
	//BLL7d 
    //BLL7d     String queryMiddle = '';
    //BLL7d     
    //BLL7d     if (reportYear!=null) {
    //BLL7d         queryMiddle += ' AND CALENDAR_YEAR(Proposed_Delivery_Date__c) =: reportYear '; 
    //BLL7d     } else {  // BLL2a
    //BLL7d         //BLL2d queryMiddle += ' AND CALENDAR_YEAR(Proposed_Delivery_Date__c) >= ' + String.valueOf(Date.today().year()) + ' '; // BLL2a
    //BLL7d         // Include prior years if not Won - Posted
    //BLL7d         String bom = String.valueOf(Date.newInstance(Date.today().year(),Date.today().month(),1));
    //BLL7d         System.debug('BOM: ' + bom);
    //BLL7d         queryMiddle += ' AND (Proposed_Delivery_Date__c >= ' + bom + ' '; // BLL2a
    //BLL7d         queryMiddle +=      ' OR (dealer__Status__c != \'Won - Posted\' AND Proposed_Delivery_Date__c < ' + bom + ')) '; // BLL2a
    //BLL7d     }
	//BLL7d 
    //BLL7d     String queryTail = ' ORDER BY Proposed_Delivery_Date__c ASC';
    //BLL7d     
    //BLL7d     List<dealer__Deal__c> dealList = Database.query( queryStart+ queryMiddle + queryTail );
	//BLL7d 
    //BLL7d     System.debug('Deallist: ' + dealList);
	//BLL7d 
    //BLL7d     if(dealList.size() > 0) {
    //BLL7d         //for ( dealer__Deal__c deal : dealList ) {
    //BLL7d         //    cDealList.add( new cDeal(deal,null, this.reportStyle) ); // DR2b
    //BLL7d         //}
    //BLL7d         // BLL6a
	//BLL7d 		Integer i = 0;
    //BLL7d         for(dealer__Deal__c deal : dealList) {
    //BLL7d         	//BLL7d if (++i>offs && cDealList.size()<lim) 
    //BLL7d         	cDealList.add(new cDeal(deal, null, this.reportStyle));
    //BLL7d         }
    //BLL7d         // BLL6a end
    //BLL7d     }
    //BLL7d     return cDealList;
    //BLL7d }
    // BLL6a
    
    // BLL7 - one routine to return all deals, retail and commerial, according to reportkind setting
    // Used by Management_SoldDeals (old) via action=read_cdeals_split2
 	public String getselectedcDeals() {	// BLL7a
		System.debug('getselectedcdeals');
		List<cDeal> cDeals = new List<cDeal>();
		//BLL7d if (reportKind!='commercialkind') 
		cDeals = getcDealListNew(false);	// BLL7c no budget info needed
        System.debug('Number of deals: ' + String.valueOf(cDeals.size()) + ' heap size: ' + String.valueOf(Limits.getHeapSize())
            	+ ' heap limit: ' + String.valueOf(Limits.getLimitHeapSize()));
		return JSON.serialize(cDeals); // BLL7c .removeEnd(']');
	}
	//BLL7dpublic String getRetail_cDeals1() {
 	//BLL7d public String getselected_cDeals1() {	// BLL7a
	//BLL7d 	System.debug('getRetail_cDeals1');
	//BLL7d 	List<cDeal> cDeals = new List<cDeal>();
	//BLL7d 	if (reportKind!='commercialkind') cDeals = getcDealListNew(0, splitat);
    //BLL7d     System.debug('Number of deals: ' + String.valueOf(cDeals.size()) + ' heap size: ' + String.valueOf(Limits.getHeapSize())
    //BLL7d         	+ ' heap limit: ' + String.valueOf(Limits.getLimitHeapSize()));
	//BLL7d 	return JSON.serialize(cDeals).removeEnd(']');
	//BLL7d }
	//BLL7d public String getRetail_cDeals2() {
	//BLL7d 	System.debug('getRetail_cDeals2');
	//BLL7d 	Set<String> commercialrptkinds = new Set<String>{'commercialkind','doublekind'};	// BLL7a
	//BLL7d 	Set<String> retailrptkinds = new Set<String>{'retailkind','doublekind'};	// BLL7a
	//BLL7d 	List<cDeal> cDeals = new List<cDeal>();
	//BLL7d 	if (reportKind!='commercialkind') cDeals = getcDealListNew(splitat, splitat);
    //BLL7d     System.debug('Number of deals: ' + String.valueOf(cDeals.size()) + ' heap size: ' + String.valueOf(Limits.getHeapSize())
    //BLL7d         	+ ' heap limit: ' + String.valueOf(Limits.getLimitHeapSize()));
	//BLL7d 	return ((cDeals.size()>0) ? ',':'') + JSON.serialize(cDeals).removeStart('[').removeEnd(']');
	//BLL7d }
	//BLL7d public String getCommercial_cDeals() {
	//BLL7d 	System.debug('getCommercial_cDeals');
	//BLL7d 	List<cDeal> cDeals = new List<cDeal>();
	//BLL7d 	if (reportKind=='commercialkind' || reportKind=='doublekind') cDeals = getcommCDealListNew(null, null);
    //BLL7d     System.debug('Number of deals: ' + String.valueOf(cDeals.size()) + ' heap size: ' + String.valueOf(Limits.getHeapSize())
    //BLL7d         	+ ' heap limit: ' + String.valueOf(Limits.getLimitHeapSize()));
	//BLL7d 	return ((cDeals.size()>0 && reportKind=='doublekind') ? ',':'') + JSON.serialize(cDeals).removeStart('[');
	//BLL7d }
    // BLL6a end

    public List<cDeal> getcDealListNew(boolean useBudgets) {	// BLL7c use budgets
		//Set<String> commercialrptkinds = new Set<String>{'commercialkind','doublekind'};	// BLL7a
		//Set<String> retailrptkinds = new Set<String>{'retailkind','doublekind'};	// BLL7a
		Map<Integer,String> monthsMap = new Map<Integer,String>{
			1=>'JAN', 2=>'FEB', 3=>'MAR', 4=>'APR',
			5=>'MAY', 6=>'JUN', 7=>'JUL', 8=>'AUG',
			9=>'SEP', 10=>'OCT', 11=>'NOV', 12=>'DEC'
		};
		System.debug('getcDealListNew');
		//BLL7d if (offs==null) offs=0;	// BLL6a
		//BLL7d if (lim==null) lim=50000;	// BLL6a
		Date currentDate = Date.today();
        Integer currentMonth = (reportMonth != null ? reportMonth : currentDate.month());
        Integer currentYear = (reportYear != null ? reportYear : currentDate.year());
        Integer currentQ = ((currentMonth-1)/3) + 1;
        System.debug(currentYear);
        System.debug(reportYear);
        
        boolean priorYear = reportYear < currentDate.year(); 
        if (priorYear && reportMonth==null) currentQ = 4;	// show detail deals for end of prior year
        
        System.debug('currentMonth='+String.valueOf(currentMonth));
        System.debug('Current Q' + CurrentQ);
        System.debug('Prior year: ' + prioryear);
        if (prioryear && reportMonth==null) currentMonth = 12;	// end of year for past years
        
        Date bom = Date.newInstance(Date.today().year(),Date.today().month(),1);

		for(Integer m = 1; m<=12; m++) {
			if(prioryear || (currentMonth >= m)) yMonths.add(monthsMap.get(m));
			//System.debug('qtr? month='+string.valueof(m)+' qtr='+String.valueOf(Integer.valueOf((m-1)/3)+1));
			if((Integer.valueOf((m-1)/3)+1)==currentQ) qMonths.add(monthsMap.get(m));
		}
        
        System.debug(qMonths);
        System.debug(yMonths);
        List<cDeal> cDealList = new List<cDeal>();
        // Use map to only include 1 record per store & month for any deal that is NOT
        // current month -- those that will not be listed separately with salesperson 
		Map<String, cDeal> qtrcDealMap = new Map<String, cDeal>();	// bll7a
		Map<String, cDeal> ytdcDealMap = new Map<String, cDeal>();	// bll7a
		Map<String, cDeal> othcDealMap = new Map<String, cDeal>();	// bll7a
	
		// new logic 
		CurrQ = Q1; 
		if (currentQ==2) CurrQ = Q2; 
		if (currentQ==3) CurrQ = Q3; 
		if (currentQ==4) CurrQ = Q4; 

		Set<String> types = new Set<String>();
		if (reportType!=null && reportType.contains('conversion')) 
			types.addAll(new Set<String>{'Chassis/Conversion','Retail Vehicle Sale'});
		if (reportType!=null && reportType.contains('equipment')) 
			types.addAll(new Set<String>{'Equipment Only','Equipment Only Sale'});
		if (reportType!=null && reportType.contains('financial'))
			types.add('Financial Products');
		if (reportType!=null && reportType.contains('dme'))
			types.add('DME/Other');
		// BLL13
		if (reportType!=null && reportType.contains('homeaccess'))
			types.add('Home Access');
		// BLL13
		if (reportType!=null && reportType.contains('wholesale'))
			types.add('Wholesale');
		// BLL13
		//if (types.size()==0) types.addAll(new Set<String>{'Chassis/Conversion','Retail Vehicle Sale','Equipment Only','Equipment Only Sale','Financial Products','DME/Other'});
		if (types.size()==0) types.addAll(new Set<String>{'Chassis/Conversion','Retail Vehicle Sale','Equipment Only','Equipment Only Sale','Financial Products','DME/Other','Home Access'});
		// BLL13
 
		Integer lastMonth = currentMonth>1 ? currentMonth-1 : 12;
               
		Integer i=0;
		System.debug(reportMonth);
		System.debug(reportYear);
		System.debug(reportStyle);
		System.debug(selReportStyles);
		System.debug(reportKind);
		System.debug(selReportKinds);
		System.debug(reportType);
		System.debug(selReportTypes);
		System.debug('currentYear = ' + String.valueOf(currentYear));
		System.debug('Deal types = ' + String.valueOf(types));
        for(dealer__Deal__c deal : [SELECT Id , Name, dealer__Salesperson_1__c, dealer__Salesperson_1__r.Name, dealer__Salesperson_1_Name__c, dealer__Deal_Type__c,  
        	 dealer__Store_Location__c, dealer__Store_Location__r.Name, dealer__Store_Location__r.Region__c, dealer__Store_Location__r.Division__c, 
        	 dealer__Store_Location__r.Commercial_Region__c, dealer__Store_Location__r.dealer__Company_Number__c, dealer__Model__c, 
        	 dealer__Buyer__c, dealer__Buyer__r.Name, dealer__Sale_Price__c, Total_Price__c, Total_Before_Payments__c, dealer__Total_Gross__c, 
        	 Commissionable_Gross__c, dealer__Front_End_Gross__c, Proposed_Delivery_Month__c, Proposed_Delivery_Date__c, dealer__Status__c,
        	 RecordType.Name, 	// BLL7a 
        	 dealer__Total_service_Contracts_Gross__c  
			 FROM dealer__Deal__c 
			 WHERE  dealer__Status__c LIKE 'Won%'	// BLL7c rmv RecordType.Name != 'Commercial' AND  
			   AND CALENDAR_YEAR(Proposed_Delivery_Date__c) = :currentYear
			   AND dealer__Deal_Type__c in :types
			 ORDER BY dealer__Store_Location__r.Name ASC, Proposed_Delivery_Date__c ASC
        	]) {
        	boolean isCommercial = deal.RecordType.Name=='Commercial';	// BLL7a
            if(deal.Proposed_Delivery_Date__c != null 
            	&& ((!isCommercial && reportkind!=null && reportkind.contains('retail') )	// BLL7a		retailrptkinds.contains(reportkind)
            		|| (isCommercial && reportkind!=null && reportkind.contains('commercial') ))	// BLL7a	commercialrptkinds.contains(reportkind)
            	){
            	String key = deal.dealer__Store_Location__c + ':' + deal.dealer__Salesperson_1__c + ':' + deal.Proposed_Delivery_Month__c + ':' + deal.dealer__Status__c;	// BLL8a
                Integer dealMonth = deal.Proposed_Delivery_Date__c.month();

                //System.debug('Current mth=' + String.valueOf(currentMonth) + ', deal month=' + String.valueOf(dealMonth));
                //Make Current Month Deals list
                if(dealMonth == (currentMonth)){
					// currentMonthDeals.add(YearlyDeals[x]);
	                //if (++i>offs && cDealList.size()<lim) cDealList.add( new cDeal(deal,null, this.reportStyle, this.reportKind, true, false, false, false) ); 
	                cDealList.add( new cDeal(deal,null, this.reportStyle, this.reportKind, true, false, false, isCommercial) );	// BLL7c
                } else {
                    if(CurrQ.contains(dealMonth) && dealMonth <= currentMonth){
                        System.debug('Current qtr contains deal month ' + String.valueOf(dealMonth) + ' deal ' + String.valueOf(deal.Name));
                        //QrtlyDeals.add(YearlyDeals[x]);
		                //BLL7d if (++i>offs && cDealList.size()<lim) 
		                cDealList.add( new cDeal(deal,null, this.reportStyle, this.reportKind, false, true, false, isCommercial) );	// BLL7c
		                // for now, show all current quarter deals individually in results
		                //cDeal qtrcDeal = qtrcDealMap.get(key);
                        //if (qtrcDeal==null) {
                        //	qtrcDeal =  new cDeal(deal, null, this.reportStyle, this.reportKind, false, true, false, false);
		                //	cDealList.add( qtrcDeal );
		                //	qtrcDealMap.put(key,qtrcDeal);
                        //} else {
                        //	qtrcDeal.addStandardDeal(deal);
                        //}
                    } else if(deal.Proposed_Delivery_Date__c.month() <= currentMonth){
                        //YrToDate.add(YearlyDeals[x]);
		                //BLL7d if (++i>offs && cDealList.size()<lim) cDealList.add( new cDeal(deal,null, this.reportStyle, this.reportKind, false, false, true, false) );
		                // BLL7a - summarize all (except prior month) to a single line by store, salesperson, month & status
		                cDeal ytdcDeal = (deal.Proposed_Delivery_Date__c.month() < lastMonth) ? ytdcDealMap.get(key) : null;
                        if (ytdcDeal==null) {
                        	ytdcDeal =  new cDeal(deal, null, this.reportStyle, this.reportKind, false, false, true, isCommercial );	// BLL7c
		                	cDealList.add( ytdcDeal );
		                	ytdcDealMap.put(key, ytdcDeal);
                        } else {
                        	ytdcDeal.addStandardDeal(deal);
                        }
                    } else if(dealMonth > currentMonth){
                        //otherMonthDeals.add(YearlyDeals[x]);
		                //BLL7d if (++i>offs && cDealList.size()<lim) cDealList.add( new cDeal(deal,null, this.reportStyle, this.reportKind, false, false, false, false) ); 
		                // BLL7a - summarize all future deals unless still open (not posted) to a single line by store, salesperson, month & status 
		                cDeal othcDeal = (deal.dealer__Status__c=='Won - Posted') ? othcDealMap.get(key) : null;
                        if (othcDeal==null) {
                        	othcDeal =  new cDeal(deal,null, this.reportStyle, this.reportKind, false, false, false, isCommercial );	// BLL7c
		                	cDealList.add( othcDeal );
		                	othcDealMap.put(key, othcDeal);
                        } else {
                        	othcDeal.addStandardDeal(deal);
                        }
                    }
                } // current month else
            } // proposed deliv date != null 
        } // for soql

		//BLL7d addBudgets(cDealList, 'Retail');
		if (useBudgets) addBudgets(cDealList, reportkind);	// BLL7a

        return cDealList;
    }
    
    // Used by ? (not used?)
    //BLL7d public String getcDealListJSON() {
	//BLL7d 	System.debug('getcDealListJSON');
    //BLL7d     // DR2c
    //BLL7d     List<cDeal> cDeals= new List<cDeal>();
	//BLL7d 
    //BLL7d     System.debug(reportKind);
	//BLL7d 
    //BLL7d     if(reportKind == 'retailkind'){
    //BLL7d         cDeals.addAll( getcDealList() );
    //BLL7d     } else if(reportKind == 'commercialkind') {
    //BLL7d         cDeals.addAll( getcommCDealList() );
    //BLL7d     // reportKind == 'doublekind';
    //BLL7d     } else if (reportKind == 'doublekind'){ // Default to Combined.
    //BLL7d         cDeals.addAll( getcDealList() );
    //BLL7d         cDeals.addAll( getcommCDealList() );
    //BLL7d     } else {
    //BLL7d         // default to retail only.
    //BLL7d         cDeals.addAll( getcDealList() );
    //BLL7d     }
	//BLL7d 
    //BLL7d      readResponse = JSON.serializePretty( cDeals );
    //BLL7d     return readResponse;
    //BLL7d     // /DR2c
    //BLL7d }

    public Boolean getisCMC() {
		System.debug('getisCMC');
        return this.isCMC;
    }

    //BLL7d public PageReference readCDeals() {
	//BLL7d 	System.debug('readCDeals');
    //BLL7d     // CRUD Actions
    //BLL7d     List<cDeal> cDeals= new List<cDeal>();
	//BLL7d 	System.debug(reportKind);	// BLL6a
	//BLL7d 
    //BLL7d     if(action=='read_cdeals') {
    //BLL7d         // DR2d
    //BLL7d         //readResponse = JSON.serializePretty(getcDealList() );
	//BLL7d 
	//BLL7d         System.debug(reportKind);
	//BLL7d             
    //BLL7d         if(reportKind == 'retailkind'){
    //BLL7d             cDeals.addAll( getcDealList(null, null) );
    //BLL7d         } else if(reportKind == 'commercialkind') {
    //BLL7d             cDeals.addAll( getcommCDealList(null, null) );
    //BLL7d         // reportKind == 'doublekind';
    //BLL7d         } else if (reportKind == 'doublekind'){ // Default to Combined.
    //BLL7d             cDeals.addAll( getcDealList(null, null) );
    //BLL7d             cDeals.addAll( getcommCDealList(null, null) );
    //BLL7d         } else {
    //BLL7d             // default to retail only.
    //BLL7d             cDeals.addAll( getcDealList(null, null) );
    //BLL7d         }
	//BLL7d 
    //BLL7d         readResponse = JSON.serializePretty( cDeals );
    //BLL7d         // /DR2d
	//BLL7d 
    //BLL7d     }
    //BLL7d     else if(action=='read_cdeals_new') {
    //BLL7d         // DR2d
    //BLL7d         //readResponse = JSON.serializePretty(getcDealList() );
    //BLL7d         System.debug('Report: ' + reportKind);
    //BLL7d         
    //BLL7d         if(reportKind == 'retailkind'){
    //BLL7d             cDeals.addAll( getcDealListNew(null, null) );
    //BLL7d         } else if(reportKind == 'commercialkind') {
    //BLL7d             cDeals.addAll( getcommCDealListNew(null, null) );
    //BLL7d         } else if (reportKind == 'doublekind'){ // Default to Combined.
    //BLL7d             cDeals.addAll( getcDealListNew(null, null) );
    //BLL7d             cDeals.addAll( getcommCDealListNew(null, null) );
    //BLL7d         } else {
    //BLL7d             // default to retail only.
    //BLL7d             cDeals.addAll( getcDealListNew(null, null) );
    //BLL7d         }
	//BLL7d 
    //BLL7d         System.debug('Number of deals: ' + String.valueOf(cDeals.size()) + ' heap size: ' + String.valueOf(Limits.getHeapSize())
    //BLL7d         	+ ' heap limit: ' + String.valueOf(Limits.getLimitHeapSize()));
    //BLL7d         readResponse = JSON.serialize( cDeals ).removeEnd(']');
    //BLL7d         // BLL6a try building while removing elements to reduce heap size - probably will take too long to build JSON
    //BLL7d         System.debug('Number of deals: ' + String.valueOf(cDeals.size()) + ' heap size: ' + String.valueOf(Limits.getHeapSize())
    //BLL7d         	+ ' heap limit: ' + String.valueOf(Limits.getLimitHeapSize()));
    //BLL7d     }
    //BLL7d     return null;
    //BLL7d }

	// BLL6a
	//BLL7d public String getRetailDeals() {
	public String getSelectedDeals() {	// BLL7a
		System.debug('getSelectedDeals');
		List<cDeal> cDeals = new List<cDeal>();
		//BLL7d if (reportKind!='commercialkind') 
		cDeals.addAll(getcDealListNew(true));	// BLL7c use budgets
        System.debug('Number of deals: ' + String.valueOf(cDeals.size()) + ' heap size: ' + String.valueOf(Limits.getHeapSize())
            	+ ' heap limit: ' + String.valueOf(Limits.getLimitHeapSize()));
		//BLL7d return JSON.serialize(cDeals).removeEnd(']');
		return JSON.serialize(cDeals);	// BLL7a
	}
	//BLL7d public String getRetailDeals1() {
	//BLL7d 	System.debug('getRetailDeals1');
	//BLL7d 	List<cDeal> cDeals = new List<cDeal>();
	//BLL7d 	if (reportKind!='commercialkind') cDeals.addAll(getcDealListNew(0, splitat));
    //BLL7d     System.debug('Number of deals: ' + String.valueOf(cDeals.size()) + ' heap size: ' + String.valueOf(Limits.getHeapSize())
    //BLL7d         	+ ' heap limit: ' + String.valueOf(Limits.getLimitHeapSize()));
	//BLL7d 	return JSON.serialize(cDeals).removeEnd(']');
	//BLL7d }
	//BLL7d public String getRetailDeals2() {
	//BLL7d 	System.debug('getRetailDeals2');
	//BLL7d 	List<cDeal> cDeals = new List<cDeal>();
	//BLL7d 	if (reportKind!='commercialkind') cDeals.addAll(getcDealListNew(splitat, splitat));
    //BLL7d     System.debug('Number of deals: ' + String.valueOf(cDeals.size()) + ' heap size: ' + String.valueOf(Limits.getHeapSize())
    //BLL7d         	+ ' heap limit: ' + String.valueOf(Limits.getLimitHeapSize()));
	//BLL7d 	return ((cDeals.size()>0) ? ',':'') + JSON.serialize(cDeals).removeStart('[').removeEnd(']');
	//BLL7d }
	//BLL7d public String getCommercialDeals() {
	//BLL7d 	System.debug('getCommercialDeals');
	//BLL7d 	List<cDeal> cDeals = new List<cDeal>();
	//BLL7d 	if (reportKind=='commercialkind' || reportKind=='doublekind') cDeals.addAll(getcommCDealListNew(null, null));
    //BLL7d     System.debug('Number of deals: ' + String.valueOf(cDeals.size()) + ' heap size: ' + String.valueOf(Limits.getHeapSize())
    //BLL7d         	+ ' heap limit: ' + String.valueOf(Limits.getLimitHeapSize()));
	//BLL7d 	return ((cDeals.size()>0 && reportKind=='doublekind') ? ',':'') + JSON.serialize(cDeals).removeStart('[');
	//BLL7d }
	// BLL6a end

    //public String getreadResponse(){
    //    return readResponse;
    //}

    /*** Commercial Quote Methods ***/ // /DR2e
    // Used by ?
    //BLL7d public List<cDeal> getcommCDealList(Decimal offs, Decimal lim) {
	//BLL7d 	if (offs==null) offs=0;	// BLL6a
	//BLL7d 	if (lim==null) lim=50000;	// BLL6a
	//BLL7d 
    //BLL7d     List<cDeal> cDealList = new List<cDeal>();
	//BLL7d 
        //BLL7d String queryStart = 'SELECT Salesperson__c, Location__c, Mileage__c, Year_Make_Model__c, Year_Make__c, Customer__c, Delivery_Date__c, Total_Gross_Profit__c, Status__c, Name, Id,Total__c, Location__r.Name, Location__r.Region__c,Location__r.Division__c, Salesperson__r.Name, Customer__r.Name, Proposal__c FROM CommercialQuote__c  WHERE Status__c LIKE \'Won%\' AND Proposal__c = null';
        //BLL7d // WHERE Status__c != \'Lost\' AND Status__c != \'Pending\' AND Status__c != \'Cloned\' AND Status__c != \'Proposal\'
		//BLL7d 
        //BLL7d String queryMiddle = '';
        //BLL7d 
        //BLL7d if (reportYear!=null) {
        //BLL7d     queryMiddle += ' AND CALENDAR_YEAR(Delivery_Date__c) =: reportYear '; 
        //BLL7d } else { 
        //BLL7d     String bom = String.valueOf(Date.newInstance(Date.today().year(),Date.today().month(),1));
        //BLL7d     queryMiddle += ' AND (Delivery_Date__c >= ' + bom + ' '; // BLL2a
        //BLL7d     queryMiddle +=      ' OR (Status__c != \'Won - Posted\' AND Delivery_Date__c < ' + bom + ')) '; // BLL2a
        //BLL7d }
		//BLL7d 
        //BLL7d String queryTail = ' ORDER BY Delivery_Date__c ASC';
		//BLL7d //if (lim!=null) queryTail += ' LIMIT ' + String.valueOf(lim);	// BLL6a
		//BLL7d //if (offs!=null) queryTail += ' OFFSET ' + String.valueOf(offs) ;	// BLL6a
  		//BLL7d 
        //BLL7d List<CommercialQuote__c> dealList = Database.query( queryStart+ queryMiddle + queryTail );
		//BLL7d 
        //BLL7d System.debug(queryStart+ queryMiddle + queryTail);
		//BLL7d 
        //BLL7d System.debug(dealList);
        
        //MarinerTek 
        //Commercial Quotes from dealer__Deal__c
        
    //BLL7d     List<dealer__Deal__c> comDeals = new List<dealer__Deal__c>();
    //BLL7d     String soql = 'SELECT Id, Name, dealer__Salesperson_1__c, dealer__Salesperson_1__r.Name, dealer__Salesperson_1_Name__c, ' 
	//BLL7d 		+ 'dealer__Store_Location__c, dealer__Store_Location__r.Name, dealer__Store_Location__r.Region__c, dealer__Store_Location__r.Commercial_Region__c, '
	//BLL7d 		+ 'dealer__Store_Location__r.Division__c, dealer__Store_Location__r.dealer__Company_Number__c, dealer__Model__c,' 
	//BLL7d 		+ 'dealer__Buyer__c, dealer__Buyer__r.Name, dealer__Sale_Price__c, Total_Price__c, Total_Before_Payments__c, '
	//BLL7d 		+ 'dealer__Total_Gross__c, Commissionable_Gross__c, dealer__Front_End_Gross__c, Proposed_Delivery_Month__c, Proposed_Delivery_Date__c, '
	//BLL7d 		+ 'dealer__Status__c, dealer__Total_Service_Contracts_Premium__c, dealer__Total_Service_Contracts_Cost__c, dealer__Total_service_Contracts_Gross__c ' 
	//BLL7d 		+ ' FROM dealer__Deal__c '  
	//BLL7d 		+ ' WHERE RecordType.Name = \'Commercial\' AND dealer__Status__c LIKE \'Won%\' '
	//BLL7d 		+ ' AND CALENDAR_YEAR(Proposed_Delivery_Date__c) = ' + String.valueOf(reportYear) 
	//BLL7d 		+ ' ORDER BY dealer__Store_Location__r.Name ASC, Proposed_Delivery_Date__c ASC ';
                                             	 //AND dealer__Status__c != 'Lost' 
                                                 //AND dealer__Status__c != 'Pending' 
                                                 //AND dealer__Status__c != 'Proposal'
                                                 //AND dealer__Status__c != 'Cloned'  

    //BLL7d     comDeals = Database.query(soql);
	//BLL7d 
	//BLL7d 	Integer i=0;        
    //BLL7d     if(comDeals.size() > 0){
    //BLL7d         for ( dealer__Deal__c deal : comDeals ) {
    //BLL7d             if (++i>offs && cDealList.size()<lim) cDealList.add( new cDeal(deal,null, this.reportStyle) ); 
    //BLL7d         }
    //BLL7d     }
        
        //BLL7d if(dealList.size() > 0) {
        //BLL7d     for ( CommercialQuote__c quote : dealList ) {
        //BLL7d         if (++i>offs && cDealList.size()<lim) cDealList.add( new cDeal(null,quote, this.reportStyle) );
        //BLL7d     }
        //BLL7d }
        
    //BLL7d     return cDealList;
    //BLL7d } // /DR2e
    
    //BLL7d public List<cDeal> getcommCDealListNew(Decimal offs, Decimal lim) {	// BLL6c
	//BLL7d 	System.debug('getcommCDealListNew');
	//BLL7d 	if (offs==null) offs=0;	// BLL6a
	//BLL7d 	if (lim==null) lim=50000;	// BLL6a
	//BLL7d 
    //BLL7d     List<cDeal> cDealList = new List<cDeal>();
	//BLL7d 	Date currentDate = Date.today();
    //BLL7d     Integer currentMonth = (reportMonth != null ? reportMonth : currentDate.month());
    //BLL7d     Integer currentYear = (reportYear != null ? reportYear : currentDate.year());
    //BLL7d     Integer currentQ =((currentMonth-1)/3) + 1;
	//BLL7d 
	//BLL7d 	// new logic 
	//BLL7d 	CurrQ = Q1; 
	//BLL7d 	if (currentQ==2) CurrQ = Q2; 
	//BLL7d 	if (currentQ==3) CurrQ = Q3; 
	//BLL7d 	if (currentQ==4) CurrQ = Q4; 
	//BLL7d 	
    //BLL7d     //Add CommercialQuote__c objects to cDeal List
    //BLL7d     List<CommercialQuote__c> comCurrentMonthDeals = new List<CommercialQuote__c>();
    //BLL7d     List<CommercialQuote__c> comOtherMonthDeals = new List<CommercialQuote__c>();
    //BLL7d     List<CommercialQuote__c> comQrtlyDeals = new List<CommercialQuote__c>();
    //BLL7d     List<CommercialQuote__c> comYrToDate = new List<CommercialQuote__c>();
    //BLL7d     		
    //BLL7d     List<CommercialQuote__c> comYearlyDeals = new List<CommercialQuote__c>();
    //BLL7d     String soql = 'SELECT Salesperson__c, Location__c, Location__r.dealer__Company_Number__c, Mileage__c, Year_Make_Model__c, '
	//BLL7d 		+ ' Year_Make__c, Customer__c, Delivery_Date__c, Total_Gross_Profit__c, Status__c, Name, Id, Total__c,' 
	//BLL7d 		+ ' Location__r.Name, Location__r.Region__c, Location__r.Commercial_Region__c, Location__r.Division__c, Salesperson__r.Name, '
	//BLL7d 		+ ' Proposal__c, Customer__r.Name ' 
	//BLL7d 		+ ' FROM CommercialQuote__c '  
	//BLL7d 		+ ' WHERE Status__c LIKE \'Won%\' AND Proposal__c = null '
	//BLL7d 		+ ' AND CALENDAR_YEAR(Delivery_Date__c) = ' + String.valueOf(currentYear)
	//BLL7d 		+ ' ORDER BY Location__r.Name ASC, Delivery_Date__c ASC ';
    //BLL7d                         //Status__c != 'Lost' 
	//BLL7d 						//AND Status__c != 'Pending' 
    //BLL7d                         //AND Status__c != 'Proposal'
	//BLL7d 						//AND Status__c != 'Cloned'  
	//BLL7d 
	//BLL7d		comYearlyDeals = Database.query(soql); // BLL6a	
	//BLL7d 
	//BLL7d 	for(Integer x=0;x<comYearlyDeals.size();x++){
    //BLL7d         if(comYearlyDeals[x].Delivery_Date__c != null){
    //BLL7d             Integer dealMonth = comYearlyDeals[x].Delivery_Date__c.month();
    //BLL7d             //System.debug(dealMonth);
    //BLL7d             //System.debug(currentMonth);
    //BLL7d             //Make Current Month Deals list
    //BLL7d             if(dealMonth == (currentMonth)){
    //BLL7d                 comCurrentMonthDeals.add(comYearlyDeals[x]);
    //BLL7d             } else {
    //BLL7d                 //if(currentQ == 1){
    //BLL7d                     //if(Q1.contains(dealMonth) && dealMonth <= currentMonth){
    //BLL7d                     if (CurrQ.contains(dealMonth) && dealMonth <= currentMonth) {
    //BLL7d                         comQrtlyDeals.add(comYearlyDeals[x]);
    //BLL7d                     }else if(comYearlyDeals[x].Delivery_Date__c.month() < currentMonth){
    //BLL7d                         comYrToDate.add(comYearlyDeals[x]);
    //BLL7d                     }else if(dealMonth > currentMonth){
    //BLL7d                         comOtherMonthDeals.add(comYearlyDeals[x]);
    //BLL7d                     }
    //BLL7d                 //}else if(currentQ == 2){
    //BLL7d                 //    if(Q2.contains(dealMonth) && dealMonth <= currentMonth){
    //BLL7d                 //        comQrtlyDeals.add(comYearlyDeals[x]);
    //BLL7d                 //    }else if(comYearlyDeals[x].Delivery_Date__c.month() < currentMonth){
    //BLL7d                 //        comYrToDate.add(comYearlyDeals[x]);
    //BLL7d                 //    }else if(dealMonth > currentMonth){
    //BLL7d                 //        comOtherMonthDeals.add(comYearlyDeals[x]);
    //BLL7d                 //    }
    //BLL7d                 //}else if(currentQ == 3){
    //BLL7d                 //    if(Q3.contains(dealMonth) && dealMonth <= currentMonth){
    //BLL7d                 //        comQrtlyDeals.add(comYearlyDeals[x]);
    //BLL7d                 //    }else if(comYearlyDeals[x].Delivery_Date__c.month() < currentMonth){
    //BLL7d                 //        comYrToDate.add(comYearlyDeals[x]);
    //BLL7d                 //    }else if(dealMonth > currentMonth){
    //BLL7d                 //        comOtherMonthDeals.add(comYearlyDeals[x]);
    //BLL7d                 //    }
    //BLL7d                 //}else if(currentQ == 4){
    //BLL7d                 //    if(Q4.contains(dealMonth) && dealMonth <= currentMonth){
    //BLL7d                 //        comQrtlyDeals.add(comYearlyDeals[x]);
    //BLL7d                 //    }else if(comYearlyDeals[x].Delivery_Date__c.month() < currentMonth){
    //BLL7d                 //        comYrToDate.add(comYearlyDeals[x]);
    //BLL7d                 //    }else if(dealMonth > currentMonth){
    //BLL7d                 //        comOtherMonthDeals.add(comYearlyDeals[x]);
    //BLL7d                 //    }
    //BLL7d                 //}
    //BLL7d             }
    //BLL7d         }
    //BLL7d     }
	//BLL7d 
    //BLL7d     List<dealer__Deal__c> currentMonthDeals = new List<dealer__Deal__c>();
    //BLL7d     List<dealer__Deal__c> otherMonthDeals = new List<dealer__Deal__c>();
    //BLL7d     List<dealer__Deal__c> QrtlyDeals = new List<dealer__Deal__c>();
    //BLL7d     List<dealer__Deal__c> YrToDate = new List<dealer__Deal__c>();
    //BLL7d     
    //BLL7d     //Add Deals where Status = Commercial
    //BLL7d     List<dealer__Deal__c> YearlyDeals = new List<dealer__Deal__c> ();
    //BLL7d     String soql2 = 'SELECT Id, Name, dealer__Salesperson_1__c, dealer__Salesperson_1__r.Name, dealer__Salesperson_1_Name__c, ' 
	//BLL7d 		+ ' dealer__Store_Location__c, dealer__Store_Location__r.Name, dealer__Store_Location__r.Region__c, dealer__Store_Location__r.Commercial_Region__c, '
	//BLL7d 		+ ' dealer__Store_Location__r.Division__c, dealer__Store_Location__r.dealer__Company_Number__c, dealer__Model__c, '
	//BLL7d 		+ ' dealer__Buyer__c, dealer__Buyer__r.Name, dealer__Sale_Price__c, Total_Price__c, Total_Before_Payments__c, '
	//BLL7d 		+ ' dealer__Total_Gross__c, Commissionable_Gross__c, dealer__Front_End_Gross__c, Proposed_Delivery_Month__c, '
	//BLL7d 		+ ' Proposed_Delivery_Date__c, dealer__Status__c, dealer__Total_Service_Contracts_Premium__c, dealer__Total_Service_Contracts_Cost__c, ' 
	//BLL7d 		+ ' dealer__Total_service_Contracts_Gross__c ' 
	//BLL7d 		+ ' FROM dealer__Deal__c '  
	//BLL7d 		+ ' WHERE RecordType.Name = \'Commercial\' AND dealer__Status__c LIKE \'Won%\' '
	//BLL7d 		+ ' AND CALENDAR_YEAR(Proposed_Delivery_Date__c) = ' + String.valueOf(currentYear)
	//BLL7d 		+ ' ORDER BY dealer__Store_Location__r.Name ASC, Proposed_Delivery_Date__c ASC ';
    //BLL7d                                          	 //AND dealer__Status__c != 'Lost' 
    //BLL7d                                              //AND dealer__Status__c != 'Pending' 
    //BLL7d                                              //AND dealer__Status__c != 'Proposal'
    //BLL7d                                              //AND dealer__Status__c != 'Cloned'  
	//BLL7d 
	//BLL7d 	//if (lim!=null) soql2 += ' LIMIT ' + String.valueOf(lim);	// BLL6a
	//BLL7d 	//if (offs!=null) soql2 += ' OFFSET ' + String.valueOf(offs) ;	// BLL6a
	//BLL7d 	YearlyDeals = Database.query(soql2);	// BLL6a
	//BLL7d 
	//BLL7d 	for(Integer x=0;x<YearlyDeals.size();x++){
    //BLL7d         if(YearlyDeals[x].Proposed_Delivery_Date__c != null){
    //BLL7d             Integer dealMonth = YearlyDeals[x].Proposed_Delivery_Date__c.month();
    //BLL7d             //Make Current Month Deals list
    //BLL7d             if(dealMonth == (currentMonth)){
    //BLL7d                 currentMonthDeals.add(YearlyDeals[x]);
    //BLL7d             }else{
    //BLL7d                 //if(currentQ == 1){
    //BLL7d                     //if(Q1.contains(dealMonth) && dealMonth <= currentMonth){
    //BLL7d                     if(currQ.contains(dealMonth) && dealMonth <= currentMonth){
    //BLL7d                         QrtlyDeals.add(YearlyDeals[x]);
    //BLL7d                     }else if(YearlyDeals[x].Proposed_Delivery_Date__c.month() < currentMonth){
    //BLL7d                         YrToDate.add(YearlyDeals[x]);
    //BLL7d                     }else if(dealMonth > currentMonth){
    //BLL7d                         otherMonthDeals.add(YearlyDeals[x]);
    //BLL7d                     }
    //BLL7d                 //}else if(currentQ == 2){
    //BLL7d                 //    if(Q2.contains(dealMonth) && dealMonth <= currentMonth){
    //BLL7d                 //        QrtlyDeals.add(YearlyDeals[x]);
    //BLL7d                 //    }else if(YearlyDeals[x].Proposed_Delivery_Date__c.month() < currentMonth){
    //BLL7d                 //        YrToDate.add(YearlyDeals[x]);
    //BLL7d                 //    }else if(dealMonth > currentMonth){
    //BLL7d                 //        otherMonthDeals.add(YearlyDeals[x]);
    //BLL7d                 //    }
    //BLL7d                 //}else if(currentQ == 3){
    //BLL7d                 //    if(Q3.contains(dealMonth) && dealMonth <= currentMonth){
    //BLL7d                 //        QrtlyDeals.add(YearlyDeals[x]);
    //BLL7d                 //    }else if(YearlyDeals[x].Proposed_Delivery_Date__c.month() < currentMonth){
    //BLL7d                 //        YrToDate.add(YearlyDeals[x]);
    //BLL7d                 //    }else if(dealMonth > currentMonth){
    //BLL7d                 //        otherMonthDeals.add(YearlyDeals[x]);
    //BLL7d                 //    }
    //BLL7d                 //}else if(currentQ == 4){
    //BLL7d                 //    if(Q4.contains(dealMonth) && dealMonth <= currentMonth){
    //BLL7d                 //        QrtlyDeals.add(YearlyDeals[x]);
    //BLL7d                 //    }else if(YearlyDeals[x].Proposed_Delivery_Date__c.month() < currentMonth){
    //BLL7d                 //        YrToDate.add(YearlyDeals[x]);
    //BLL7d                 //    }else if(dealMonth > currentMonth){
    //BLL7d                 //        otherMonthDeals.add(YearlyDeals[x]);
    //BLL7d                 //    }
    //BLL7d             	//}
    //BLL7d             }
    //BLL7d         }
    //BLL7d     }
	//BLL7d 
	//BLL7d 	Integer i=0;
    //BLL7d     if(currentMonthDeals.size() > 0) {
    //BLL7d         for ( dealer__Deal__c deal : currentMonthDeals ) {
    //BLL7d             if (++i>offs && cDealList.size()<lim) cDealList.add( new cDeal(deal,null, this.reportStyle, this.reportKind, true, false, false, true) ); 
    //BLL7d         }
    //BLL7d     }
    //BLL7d     
    //BLL7d     if(comCurrentMonthDeals.size() > 0) {
    //BLL7d         for ( CommercialQuote__c quote : comCurrentMonthDeals ) {
    //BLL7d             if (++i>offs && cDealList.size()<lim) cDealList.add( new cDeal(null,quote, this.reportStyle, this.reportKind, true, false, false, true) ); 
    //BLL7d         }
    //BLL7d     }
    //BLL7d     
    //BLL7d     if(otherMonthDeals.size() > 0){
    //BLL7d         for ( dealer__Deal__c deal : otherMonthDeals ) {
    //BLL7d             if (++i>offs && cDealList.size()<lim) cDealList.add( new cDeal(deal,null, this.reportStyle, this.reportKind, false, false, false, true) ); 
    //BLL7d         }
    //BLL7d     }
    //BLL7d     
    //BLL7d     if(comOtherMonthDeals.size() > 0){
    //BLL7d         for ( CommercialQuote__c quote : comOtherMonthDeals ) {
    //BLL7d             if (++i>offs && cDealList.size()<lim) cDealList.add( new cDeal(null,quote, this.reportStyle, this.reportKind, false, false, false, true) ); 
    //BLL7d         }
    //BLL7d     }
    //BLL7d     
    //BLL7d     if(QrtlyDeals.size() > 0){
    //BLL7d         for ( dealer__Deal__c deal : QrtlyDeals ) {
    //BLL7d             if (++i>offs && cDealList.size()<lim) cDealList.add( new cDeal(deal,null, this.reportStyle, this.reportKind, false, true, false, true) ); 
    //BLL7d         }
    //BLL7d     }
    //BLL7d     
    //BLL7d     if(comQrtlyDeals.size() > 0){
    //BLL7d         for ( CommercialQuote__c quote : comQrtlyDeals ) {
    //BLL7d             if (++i>offs && cDealList.size()<lim) cDealList.add( new cDeal(null,quote, this.reportStyle, this.reportKind, false, true, false, true) ); 
    //BLL7d         }
    //BLL7d     }
    //BLL7d     
    //BLL7d     if(YrToDate.size() > 0){
    //BLL7d         for ( dealer__Deal__c deal : YrToDate ) {
    //BLL7d             if (++i>offs && cDealList.size()<lim) cDealList.add( new cDeal(deal,null, this.reportStyle, this.reportKind, false, false, true, true) ); 
    //BLL7d         }
    //BLL7d     }
    //BLL7d             
    //BLL7d     if(comYrToDate.size() > 0){
    //BLL7d         for ( CommercialQuote__c quote : comYrToDate ) {
    //BLL7d             if (++i>offs && cDealList.size()<lim) cDealList.add( new cDeal(null,quote, this.reportStyle, this.reportKind, false, false, true, true) ); 
    //BLL7d         }
    //BLL7d     }
	//BLL7d 
	//BLL7d addBudgets(cDealList, 'Commercial');
	//BLL7d 	
    //BLL7d     return cDealList;
    //BLL7d }

    public void isTest(){
        reportYear = 2016;
        reportMonth = 11;
        List<Budget__c> dealBudgetlist = [Select Id, Name, Month_Abbr__c, Budget_Id__c, Budget_Type__c, Dollars__c From Budget__c Where Budget_Type__c = 'Retail'];
    	List<Budget__c> commBudgetlist = [Select Id, Name, Month_Abbr__c, Budget_Id__c, Budget_Type__c, Dollars__c From Budget__c Where Budget_Type__c = 'Commercial'];
        System.assertequals(1, commBudgetlist.size());
		List<cDeal> cDeals= new List<cDeal>();            
                //BLL7d cDeals.addAll( getcDealList(null, null) );
                //BLL7d cDeals.addAll( getcommCDealList(null, null) );
                cDeals.addAll( getcDealListNew(true) );
                //BLL7d cDeals.addAll( getcommCDealListNew(null, null) );           
    }

	// Add month, qtr & year budget numbers by store (to the first record for each store)
	public void addBudgets(List<cDeal> cDealList, String kind) {
		// BLL7a
		Set<String> kinds = new Set<String>();
		if (kind=='retailkind' || kind=='doublekind') kinds.add('Retail');
		if (kind=='commercialkind' || kind=='doublekind') kinds.add('Commercial');
		System.debug(kind);
		System.debug(kinds);
		// BLL7a end
		
		Date currentDate = Date.today();
        Integer currentYear = (reportYear != null ? reportYear : currentDate.year());
        Integer currentMonth = reportMonth!=null ? reportMonth : Date.today().month();
		Integer currQtr = Integer.valueOf((currentMonth-1)/3)+1;
		System.debug('addBudgets current qtr=' + String.valueOf(currQtr));
		
	    List<Budget__c> dealBudgetlist = [
	    	select Id, Name, Location__c, Month__c, Month_Abbr__c, Year__c, Budget_Id__c, Budget_Type__c, Dollars__c,
	    		Location__r.Name, Location__r.Region__c, Location__r.Division__c 
	    	from Budget__c 
	    	where Budget_Type__c in :kinds and Year__c=:currentYear
	    ];
	    
	    // BLL8a
	    // Write budgets as separate entries in the result data
	    for(Budget__c b : dealBudgetList) {
			Decimal budgQtr = Integer.valueOf((b.Month__c-1)/3) + 1;
			
	    	boolean iscurrmonth = b.Month__c==currentMonth;
	    	boolean iscurrqtr = budgQtr==currQtr && b.Month__c<=currentMonth;
	    	boolean iscurryear = b.Month__c<=currentMonth;
	    	Decimal amt = b.Dollars__c==null ? 0 : b.Dollars__c;
	    	cDeal dealbudget = new cDeal(b, this.reportStyle, this.reportKind, amt, iscurrmonth, iscurrqtr, iscurryear);
			cDealList.add(dealbudget);
	    }
	    // BLL8a end 
	    
	    // BLL8d
		//Map<Id,Decimal> mthBudgetMap = new Map<Id,Decimal>();
		//Map<Id,Decimal> qtrBudgetMap = new Map<Id,Decimal>();
		//Map<Id,Decimal> yrBudgetMap = new Map<Id,Decimal>();
		//for(Budget__c b : dealBudgetList) {
		//	Decimal budgQtr = Integer.valueOf((b.Month__c-1)/3) + 1;
		//	Decimal mthbudget = mthBudgetMap.get(b.Location__c);
		//	if (mthbudget==null) mthbudget = 0;
		//	Decimal qtrbudget = qtrBudgetMap.get(b.Location__c);
		//	if (qtrbudget==null) qtrbudget = 0;
		//	Decimal yrbudget = yrBudgetMap.get(b.Location__c);
		//	if (yrbudget==null) yrbudget = 0;
		//
		//	if (b.Month__c==currentMonth) mthbudget += b.Dollars__c;
		//	if (budgQtr==currQtr && b.Month__c<=currentMonth) qtrbudget += b.Dollars__c;
		//	if (b.Month__c<=currentMonth) yrbudget += b.Dollars__c;
		//	mthBudgetMap.put(b.Location__c,mthbudget);
		//	qtrBudgetMap.put(b.Location__c,qtrbudget);
		//	yrBudgetMap.put(b.Location__c,yrbudget);
		//}
		//System.debug(mthBudgetMap);
		//System.debug(qtrBudgetMap);
		//System.debug(yrBudgetMap);

		// retrieve budgets by location & update cDealList
		//Id LastLocation = null;
		//Decimal currBudg = 0;
		//Decimal qtrBudg = 0;
		//Decimal yrBudg = 0;
		//for(cDeal cd : cDealList) {
		//	// total budgets
		//	if (LastLocation!=cd.locId) {
		//		LastLocation = cd.locId;
		//		currBudg = mthBudgetMap.get(LastLocation);
		//		if (currBudg==null) currBudg = 0;
		//		qtrBudg = qtrBudgetMap.get(LastLocation);
		//		if (qtrBudg==null) qtrBudg = 0;
		//		yrBudg = yrBudgetMap.get(LastLocation);
		//		if (yrBudg==null) yrBudg = 0;
		//		
		//		//for(Budget__c b : dealBudgetList) {
		//			//if (b.Location__c==LastLocation) {
		//				//if (currentMonth==b.Month__c) currBudg += b.Dollars__c;
		//				//if (b.Month__c<=currentMonth) yrBudg += b.Dollars__c;
		//				//Decimal budgQtr = Integer.valueOf((b.Month__c-1)/3) + 1; 
		//				//if (budgQtr == currQtr && b.Month__c<=currentMonth) qtrBudg += b.Dollars__c;
		//			//}
		//		//}
		//		System.debug('Quarterly budget for ' + cd.locName + ' is ' + String.valueOf(qtrBudg));
		//	}	// end if change in location
		//
		//	// assign budget numbers
		//	if (cd.isCurrentMonth) System.debug(cd.Name + ' is current month');
		//	if (cd.isQuarterly) System.debug(cd.Name + ' is quarterly ' + String.valueOf(qtrBudg));
		//	if (currBudg!=0) System.debug('Assigning budgets to record: ' + JSON.serialize(cd));
		//	if (currBudg!=0) System.debug(cd.locName + ' ' + kind + ' Assign budget currBudg = ' + String.valueOf(currBudg));
		//	if ((cd.isCurrentMonth || cd.isQuarterly) && qtrBudg!=0) System.debug(cd.locName + ' ' + kind + ' Assign budget qtrBudg = ' + String.valueOf(qtrBudg));
		//	if ((cd.isCurrentMonth || cd.isQuarterly || cd.isYearly) && yrBudg!=0) System.debug(cd.locName + ' ' + kind + ' Assign budget yrBudg = ' + String.valueOf(yrBudg));
		//	
		//	//cd.budgetPercentage += currBudg; currBudg = 0;
		//	//if (cd.isCurrentMonth || cd.isQuarterly) { cd.quarterPercentage += qtrBudg; qtrBudg = 0; }
		//	//if (cd.isCurrentMonth || cd.isQuarterly || cd.isYearly) { cd.yearPercentage += yrBudg; yrBudg = 0; }
		//	cd.budgetPercentage += currBudg;
		//	currBudg = 0;
		//	mthBudgetMap.put(LastLocation,currBudg);
		//	if (cd.isCurrentMonth || cd.isQuarterly) {
		//		cd.quarterPercentage += qtrBudg;
		//		qtrBudg = 0;
		//		qtrBudgetMap.put(LastLocation,qtrBudg);
		//	}
		//	if (cd.isCurrentMonth || cd.isQuarterly || cd.isYearly) {
		//		cd.yearPercentage += yrBudg;
		//		yrBudg = 0;
		//		yrBudgetMap.put(LastLocation,yrBudg);
		//	}
		//}	// end for cDealList
	    // BLL8d end
	    
	}	// end addBudgets    

    
    public List<cDeal> getTestcDealListNew(String testwhereclause) {
		Map<Integer,String> monthsMap = new Map<Integer,String>{
			1=>'JAN', 2=>'FEB', 3=>'MAR', 4=>'APR',
			5=>'MAY', 6=>'JUN', 7=>'JUL', 8=>'AUG',
			9=>'SEP', 10=>'OCT', 11=>'NOV', 12=>'DEC'
		};
		Decimal offs;
		Decimal lim;
		System.debug('getTestcDealListNew');
		if (offs==null) offs=0;	// BLL6a
		if (lim==null) lim=50000;	// BLL6a
		Date currentDate = Date.today();
        Integer currentMonth = (reportMonth != null ? reportMonth : currentDate.month());
        Integer currentYear = (reportYear != null ? reportYear : currentDate.year());
        Integer currentQ = ((currentMonth-1)/3) + 1;
        System.debug('reporttMonth='+String.valueOf(currentMonth));
        System.debug('currentMonth='+String.valueOf(currentMonth));
        System.debug('Current Q' + CurrentQ);
        Date bom = Date.newInstance(Date.today().year(),Date.today().month(),1);
		for(Integer m = 1; m<=12; m++) {
			if(currentMonth >= m) yMonths.add(monthsMap.get(m));
			//System.debug('qtr? month='+string.valueof(m)+' qtr='+String.valueOf(Integer.valueOf((m-1)/3)+1));
			if((Integer.valueOf((m-1)/3)+1)==currentQ) qMonths.add(monthsMap.get(m));
		}
        
        System.debug(qMonths);
        System.debug(yMonths);
        List<cDeal> cDealList = new List<cDeal>();
	
	// new logic
		CurrQ = Q1;
		if (currentQ==2) CurrQ = Q2;
		if (currentQ==3) CurrQ = Q3;
		if (currentQ==4) CurrQ = Q4;
		
		Integer i=0;
		String soql = 'SELECT Id , Name, dealer__Salesperson_1__c, dealer__Salesperson_1__r.Name, dealer__Salesperson_1_Name__c, ' 
        	 + ' dealer__Store_Location__c, dealer__Store_Location__r.Name, dealer__Store_Location__r.Region__c, dealer__Store_Location__r.Division__c, ' 
        	 + ' dealer__Store_Location__r.Commercial_Region__c, dealer__Store_Location__r.dealer__Company_Number__c, dealer__Model__c, '
        	 + ' dealer__Buyer__c, dealer__Buyer__r.Name, dealer__Sale_Price__c, Total_Price__c, Total_Before_Payments__c, dealer__Total_Gross__c, ' 
        	 + ' Commissionable_Gross__c, dealer__Front_End_Gross__c, Proposed_Delivery_Month__c, Proposed_Delivery_Date__c, dealer__Status__c, '
        	 + ' dealer__Total_service_Contracts_Gross__c  '
			 + ' FROM dealer__Deal__c '
			 + ' WHERE RecordType.Name != \'Commercial\' AND dealer__Status__c LIKE \'Won%\' '  
			 + ' AND CALENDAR_YEAR(Proposed_Delivery_Date__c) = ' + String.valueOf(currentYear) ;
		if (!String.isBlank(testwhereclause)) soql += ' AND ' + testwhereclause;
		soql += ' ORDER BY dealer__Store_Location__r.Name ASC, Proposed_Delivery_Date__c ASC ';
		List<dealer__Deal__c> deallist = Database.query(soql);
        for(dealer__Deal__c deal : deallist) {
            if(deal.Proposed_Delivery_Date__c != null){
                Integer dealMonth = deal.Proposed_Delivery_Date__c.month();
                System.debug('Current mth=' + String.valueOf(currentMonth) + ', deal month=' + String.valueOf(dealMonth));
                //Make Current Month Deals list
                if(dealMonth == (currentMonth)){
					// currentMonthDeals.add(YearlyDeals[x]);
	                if (++i>offs && cDealList.size()<lim) cDealList.add( new cDeal(deal,null, this.reportStyle, this.reportKind, true, false, false, false) ); 
                } else {
                    if(CurrQ.contains(dealMonth) && dealMonth <= currentMonth){
                       System.debug('Current qtr contains deal month ' + String.valueOf(dealMonth) + ' deal ' + String.valueOf(deal.Name));
		               if (++i>offs && cDealList.size()<lim) cDealList.add( new cDeal(deal,null, this.reportStyle, this.reportKind, false, true, false, false) ); 
                    } else if(deal.Proposed_Delivery_Date__c.month() < currentMonth){
		               if (++i>offs && cDealList.size()<lim) cDealList.add( new cDeal(deal,null, this.reportStyle, this.reportKind, false, false, true, false) ); 
                    } else if(dealMonth > currentMonth){
		               if (++i>offs && cDealList.size()<lim) cDealList.add( new cDeal(deal,null, this.reportStyle, this.reportKind, false, false, false, false) ); 
                    }
                } // current month else
            } // proposed deliv date != null 
        } // for soql

		// set qtd, ytd, budget numbers
		addBudgets(cDealList, 'Retail');

        return cDealList;
    }
    
    
}