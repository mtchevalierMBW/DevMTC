/**
 * DataFactory_MW
 * Tested by: DataFactory_MW_TEST
 * Date: Apr 27, 2018
 * Programmer: Bryan Leaman
 *
 */
@isTest
public with sharing class DataFactory_MW {

	private static DataFactory_MW df;
	
	// Record types
	Map<String, Schema.RecordTypeInfo> accountRcdTypes;
	Map<String, Schema.RecordTypeInfo> contactRcdTypes;

	// SObjects to create
	//List<SObject> objToCreate;
	
	// SObjects to create by object type
	public List<Account> accounts;
	public List<Contact> contacts;
	public List<dealer__Sales_Up__c> salesups;
	public List<dealer__Sales_Appointment__c> salesappointments;
	public List<c2g__codaDimension1__c> dimension1s;
	public List<dealer__Dealer_Location__c> dealerlocations;
	public List<c2g__codaGeneralLedgerAccount__c> generalledgeraccounts;
		

	// DataFactory_MW
	//---------------------------------------
	public DataFactory_MW() {
	}
	public static DataFactory_MW getInstance() {
		if (df==null) df = new DataFactory_MW();
		return df;
	}


	// RefreshData
	//-------------------------
	public void refreshData() {
		accounts = (List<Account>) readAllSObjects(Schema.Account.SObjectType);
		contacts = (List<Contact>) readAllSObjects(Schema.Contact.SObjectType);
		salesups = (List<dealer__Sales_Up__c>) readAllSObjects(Schema.dealer__Sales_Up__c.SObjectType);
		salesappointments = (List<dealer__Sales_Appointment__c>) readAllSObjects(Schema.dealer__Sales_Appointment__c.SObjectType);
	}

	// readAllSObjects
	//-------------------------
	public List<SObject> readAllSObjects(Schema.SObjectType objtype) {
		String soql = 'select ' + allFieldsForSOQL(objtype) + ' from ' + objtype.getDescribe().getLocalName() + ' order by Id ';
		return Database.query(soql);
	}

	// Create Data
	//-------------------------
	public void createData() {
		if (accounts!=null) Database.insert(accounts);

		if (contacts!=null) {
			// apply account references to contacts 1-to-1
			if (accounts!=null && accounts.size()>0) {
				for(Integer i=0; i<contacts.size(); ++i) 
					contacts[i].AccountId = accounts[Math.mod(i, accounts.size())].Id;
			}
			Database.insert(contacts);
		}

		if (salesups!=null) {
			if (accounts!=null && accounts.size()>0) {
				for(Integer i=0; i<salesups.size(); ++i) {
					Account a = accounts[Math.mod(i, accounts.size())];
					salesups[i].dealer__Customer_Account__c = a.Id;
					if (a.isPersonAccount) salesups[i].dealer__Buyer_Contact__c = a.PersonContactId;
					else if (contacts!=null && contacts.size()>0)
						salesups[i].dealer__Buyer_Contact__c = contacts[Math.mod(i, contacts.size())].Id;
				}
			}
			Database.insert(salesups);
		}		

		if (salesappointments!=null) {
			if (salesups!=null && salesups.size()>0) {
				for(Integer i=0; i<salesappointments.size(); ++i) {
					dealer__Sales_Up__c sup = salesups[Math.mod(i, salesups.size())];
					salesappointments[i].dealer__Sales_Up__c = sup.Id;
					salesappointments[i].dealer__Customer__c = sup.dealer__Buyer_Contact__c;
					salesappointments[i].dealer__Customer_Account__c = sup.dealer__Customer_Account__c;
				}
			}
			Database.insert(salesups);
		}
		
		if (dealerlocations!=null) Database.insert(dealerlocations);


	}
	

	// Accounts
	//---------------------------------------
	public Account newAccount(String rcdType, Map<String, Object> params) {
		if (rcdType!=null && accountRcdTypes==null) accountRcdTypes  = Schema.SObjectType.Account.getRecordTypeInfosByName();
		if (accounts==null) accounts = new List<Account>();
		Account a = new Account();
		if (!String.isBlank(rcdType)) a.RecordTypeId = accountRcdTypes.get(rcdType).getRecordTypeId();
		if (rcdType=='PersonAccount') {
				a.FirstName = 'Test' + String.valueOf(accounts.size()+1);
				a.LastName = 'Person' + String.valueOf(accounts.size()+1);
		} else {
				a.Name = 'Test Company' + String.valueOf(accounts.size()+1);
		}
		applySObjectProperties(a, params);
		accounts.add(a);
		return a;
	}

	// Contacts
	//---------------------------------------
	public Contact newContact(String rcdType, Map<String, Object> params) {
		if (rcdType!=null && contactRcdTypes==null) contactRcdTypes  = Schema.SObjectType.Contact.getRecordTypeInfosByName();
		if (contacts==null) contacts = new List<Contact>();
		Contact c = new Contact();
		c.FirstName = 'Test' + String.valueOf(contacts.size()+1);
		c.LastName = 'Contact' + String.valueOf(contacts.size()+1);
		applySObjectProperties(c, params);
		contacts.add(c);
		return c;
	}

	// Sales ups (SolutionOpportunity)
	//---------------------------------------
	public dealer__Sales_Up__c newSalesUp(String solneed, Map<String,Object> params) {
		if (salesups==null) salesups = new List<dealer__Sales_Up__c>();
		dealer__Sales_Up__c sup = new dealer__Sales_Up__c();
		sup.Solution_Type__c = solneed;
		sup.dealer__Lead_Status__c = 'Pending';
		applySObjectProperties(sup, params);
		salesups.add(sup);
		return sup;
	}

	// SalesAppointments
	//---------------------------------------
	public dealer__Sales_Appointment__c newSalesAppointment(Map<String,Object> params) {
		if (salesappointments==null) salesappointments = new List<dealer__Sales_Appointment__c>();
		dealer__Sales_Appointment__c sa = new dealer__Sales_Appointment__c();
		sa.dealer__Date__c = Date.today();
		sa.dealer__Time__c = '11:00 AM';
		sa.dealer__DateTime__c = DateTime.newInstance(Date.today(), Time.newInstance(11,00,00,0)); 	
		applySObjectProperties(sa, params);
		salesappointments.add(sa);
		return sa;
	}

	// DealerLocations
	//--------------------------------------
	public dealer__Dealer_Location__c newDealerLocation(Map<String,Object> params) {
		if (dealerlocations==null) dealerlocations = new List<dealer__Dealer_Location__c>();
		dealer__Dealer_Location__c dloc = new dealer__Dealer_Location__c();
		dloc.Name = 'Test_Loc_' + String.valueOf(dealerlocations.size()+1);
		dloc.dealer__Company_Number__c = 'TL' + String.valueOf(dealerlocations.size()+1);
		applySObjectProperties(dloc, params);
		dealerlocations.add(dloc);
		return dloc;
	}

	// DealerLocation Users (w/ Tech)
	//---------------------------------------

	// MiscChargeOptions
	//---------------------------------------

	// StandardOperationCodes
	//---------------------------------------
	
	// PaymentMethods
	//---------------------------------------

	// MiscChargeCodes
	//---------------------------------------


	// RepairOrders (lines counter), lines, (parts, labor, misc charges)

	// parts
	// kit categories
	// kits
	

	// FinancialForce basics
	//--------------------------------------
	// standard accounts, how many dimensions?, 1 user?


	// GeneralLedgerAccounts
	//--------------------------------------
	public c2g__codaGeneralLedgerAccount__c newGeneralLedgerAccount(String acct, Map<String,Object> params) {
		if (generalledgeraccounts==null) generalledgeraccounts = new List<c2g__codaGeneralLedgerAccount__c>();
		c2g__codaGeneralLedgerAccount__c gla = new c2g__codaGeneralLedgerAccount__c();
		gla.Name = 'GL ' + acct;
		gla.c2g__ReportingCode__c = acct;
		applySObjectProperties(gla, params);
		generalledgeraccounts.add(gla);
		return gla;
	}
	public void newGeneralLedgerAccounts() {
		List<String> autoGLAs = new List<String>{'1001', '1100', '2100', '2500', '2505', '2510', '2515'};
		newGeneralLedgerAccounts(autoGLAs);
	}
	public void newGeneralLedgerAccounts(List<String> autoGLAs) {
		for(String acct : autoGLAs) newGeneralLedgerAccount(acct, null);
	}

	// mapSObjectProperties
	private void applySObjectProperties(SObject o, Map<String, Object> properties) {
		if (properties!=null) {
			for(String f : properties.keySet()) {
				o.put(f, properties.get(f));
			}
		}
	}

	// allFieldsForSOQL
	//--------------------------
	private String allFieldsForSOQL(Schema.SObjectType sobjt) {
		Map<String, Schema.SObjectField> fieldMap =  sobjt.getDescribe().fields.getMap();
		List<String> fieldList = new List<String>();
		for(string f : fieldMap.keySet()) if (fieldMap.get(f).getDescribe().isAccessible()) fieldList.add(f);
		return String.join(fieldList,',');
	}


    // BLL3a FF routines
    // Usage:
    //    private static DataFactory_MW.FFATestData FFAdata = new DataFactory_MW.FFATestData(); // BLL1
    //    @testSetup
    //    static void setupFFA() {
    //      DataFactory_MW.createBaseFFAData(FFAdata);
    //    }
    // FFAdata.refresh();
    // System.runAs(FFAdata.TestUser) {
    // }
    
    public class FFATestData {
        public Account Account {get;set;}
        public c2g__codaCompany__c CurrentCompany {get;set;}
        public c2g__codaPeriod__c CurrentPeriod {get;set;}
        public c2g__codaDimension1__c Dimension1 {get;set;}
        public c2g__codaDimension1__c Dimension1b {get;set;}
        public c2g__codaAccountingCurrency__c HomeCurrency {get;set;}
        public Product2 Product {get;set;}
        public Map<String,c2g__codaGeneralLedgerAccount__c> GLAMap {get;set;}
        public User TestUser {get;set;}
        public dealer__Dealer_Location__c DealerLocation {get;set;}
        public void refresh() {
            this.TestUser = [Select Id From User Where Username = 'ffdeveloper@nowhere.com'];
            this.Account = [Select Id From Account where Name='Tony Stark Enterprises' limit 1];
            this.CurrentCompany = [Select Id, Name From c2g__codaCompany__c limit 1];
            this.HomeCurrency = [Select Id, Name From c2g__codaAccountingCurrency__c limit 1];
            this.Product = [Select Id, Name From Product2 limit 1];
            this.DealerLocation = [select Id, Name, dealer__Company_Number__c from dealer__Dealer_Location__c limit 1];  
            this.CurrentPeriod = [Select Id, Name From c2g__codaPeriod__c Where c2g__Description__c = 'Trading Period' And c2g__StartDate__c <= :System.today() And c2g__EndDate__c >= :System.today() limit 1];
            this.Dimension1 = [select Id, Name, c2g__ReportingCode__c From c2g__codaDimension1__c where c2g__ReportingCode__c='FFA1' limit 1];
            this.Dimension1b = [select Id, Name, c2g__ReportingCode__c from c2g__codaDimension1__c where c2g__ReportingCode__c='FFA1B' limit 1];
            this.GLAMap = new Map<String,c2g__codaGeneralLedgerAccount__c>();
            for(c2g__codaGeneralLedgerAccount__c g : [select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c]) this.GLAMap.put(g.c2g__ReportingCode__c, g);
        }
    }

    //@testSetup
    public static void createBaseFFAData(FFATestData testData)
    {
        testData.TestUser = createUser();
        testData.DealerLocation = createLocation(testData.TestUser);
        // Authorize user to location - BLL7a
        dealer__Dealer_Location_User__c dlu = new dealer__Dealer_Location_User__c(
        	dealer__User__c = testData.TestUser.Id,
        	dealer__Dealer_Location__c = testData.DealerLocation.Id
        );
        try { insert(dlu); } catch(Exception e) {}
        // BLL7a end

        System.runAs(testData.TestUser)
        {
            Test.startTest();                        
            // GLA's, Accounts and Products are not company aware, create them first
            testData.GLAMap = createGLAccounts();
            testData.Account = createAccount('Tony Stark Enterprises', testData.GLAMap.get('accountsReceivableControl').Id, testData.GLAMap.get('accountsPayableControl').Id);
            testData.Product = createProduct(testData.GLAMap.get('grossRevenue').Id, testData.GLAMap.get('cogs').Id);
     
            testData.Dimension1 = createDimension1();
            testData.Dimension1b = createDimension1b();
            
            // create all 'Company' aware data objects
            // Create the Queue and simulate activating the company
            testData.CurrentCompany = createFFACompany('FinancialForce', createFFAQueue(testData.TestUser.Id).Id);
            // Add a user Company
            createUserCompany(testData.CurrentCompany.Id, testData.TestUser.Id);
            // create other base data types...
            testData.HomeCurrency = createHomeCurrency('USD');        
            testData.CurrentPeriod = createYearPeriods();
            testData.DealerLocation.Company__c = testData.CurrentCompany.Id;
            testData.DealerLocation.Financial_Force_Dimension_1__c = testData.Dimension1.Id;
            update(testData.DealerLocation);
            Test.stopTest();
        }
    }

    static dealer__Dealer_Location__c createLocation(User u) {
            dealer__Dealer_Location__c loc = new dealer__Dealer_Location__c();
            loc.Name = 'Test FFA Location xyz';
            loc.dealer__Company_Number__c = 'FFA';
            loc.Region__c = '1';
            loc.dealer__General_Manager__c = u.Id;
            loc.Rental_Manager__c = u.Id; 
            loc.dealer__City__c = 'Richfield';
            loc.dealer__State__c = 'OH';
            loc.dealer__Postal_Code__c = '44286';
            loc.Service_Reporting_User__c = u.Id;	// BLL10a
            //c2g__codaCompany__c comp = getFFCompany(UserInfo.getUserId()); 
            //if (comp!=null) {
            //    loc.Company__c = comp.Id;
            //}
            insert(loc);

	        // Authorize user to location - BLL7a
    	    dealer__Dealer_Location_User__c dlu = new dealer__Dealer_Location_User__c(
        		dealer__User__c = UserInfo.getUserId(),
        		dealer__Dealer_Location__c = loc.Id
	        );
	        try { insert(dlu); } catch(Exception e) {}
	        // BLL7a end

            return loc;
    }

    static c2g__codaDimension1__c createDimension1() {
            c2g__codaDimension1__c dim1 = new c2g__codaDimension1__c();
            dim1.Name = 'Test FFA Dimension1';
            dim1.c2g__ReportingCode__c = 'FFA1';
            insert(dim1);
            return dim1;
    }

    static c2g__codaDimension1__c createDimension1b() {
            c2g__codaDimension1__c dim1b = new c2g__codaDimension1__c();
            dim1b.Name = 'Test FFA Dimension1b';
            dim1b.c2g__ReportingCode__c = 'FFA1B';
            insert(dim1b);
            return dim1b;
    }
    
    static User createUser()
    {
        Profile p = [select id from profile where name='System Administrator'];

        User u = new User();
        u.FirstName = 'FFA';
        u.LastName = 'User';
        u.Alias = 'FFAUSER';
        u.Username = 'ffdeveloper@nowhere.com';
        u.Email = 'ffdeveloper@nowhere.com';
        u.CommunityNickname = 'ffd';
        u.Phone = '555.555.5555';
        u.IsActive = true;
        u.ProfileId = p.Id;
        u.TimeZoneSidKey = 'America/New_York';
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'ISO-8859-1';
        u.LanguageLocaleKey = 'en_US';
        u.Title = 'The enlightened one';
        u.CompanyName = 'FF Test Company';
        u.Division = 'FFA';

        insert u;

        return u;
    }

    

    /**
        *   Create FFA Queue (FinancialForce)
        *   No @Parms required
    **/
    public static Group createFFAQueue(Id userId) 
    {
        //Create queue
        Group grp = new Group(Type = 'Queue', Name = 'FF FinancialForce');
        insert grp;

        //Create list of all FinancialForce Objctes
        List<String> queueObjectNames =  getQueueObjectNames();

        //Assign Objects to Queue
        List<QueueSObject> newQueueObjects = new List<QueueSObject>();
        for (String queueObjectName : queueObjectNames) 
        {
            newQueueObjects.add(new QueueSObject(QueueId = grp.id, SobjectType = queueObjectName));
        }
        insert newQueueObjects;

        //Assign group to a current user
        insert new GroupMember(GroupId = grp.id, UserOrGroupId = userId); 
        System.debug('COMPANY_GROUPMEMBER');
        System.debug(grp.id);
        System.debug(userId);

        return grp;   
    }
    /**
        *   Create FFA Company (FinancialForce Test Company)
        *   No @Parms required
    **/
    public static c2g__codaCompany__c createFFACompany(String name, Id queueMemberId) 
    {        
        c2g__codaCompany__c testCompany = new c2g__codaCompany__c();
        testCompany.put('Name', name);
        testCompany.put('OwnerId', queueMemberId);
        testCompany.put('c2g__Street__c', 'Cardale Park');
        testCompany.put('c2g__StateProvince__c', 'Beckwith Head Road');
        testCompany.put('c2g__City__c', 'Harrogate');
        testCompany.put('c2g__ZipPostCode__c', 'HG3 1RY');
        testCompany.put('c2g__Country__c', 'United Kingdom');
        testCompany.put('c2g__Phone__c', '+44 (0)1423 537728)');      
             
        insert  testCompany;  

        return testCompany;    

    }
    public static void createUserCompany(Id companyId, Id userId)
    {
        insert new c2g__codaUserCompany__c(c2g__Company__c = companyId, c2g__User__c = userId);        
    }
    /**
        *   Create FFA Currency (USD)
        *   No @Parms required
    **/
    public static c2g__codaAccountingCurrency__c createHomeCurrency(String name) 
    {
        c2g__codaAccountingCurrency__c testCurrency = new c2g__codaAccountingCurrency__c();
        testCurrency.put('Name', name);
        //testCurrency.put('c2g__UnitOfWork__c', 1);
        testCurrency.put('c2g__DecimalPlaces__c', 2);
        testCurrency.put('c2g__Home__c', true);
        testCurrency.put('c2g__Dual__c', true);

        insert testCurrency;

        return testCurrency;
    }

    public static c2g__codaPeriod__c createYearPeriods() 
    {
        String currentYear = String.valueOf(Date.today().year());  

        c2g__codaYear__c yr = new c2g__codaYear__c();
        yr.put('Name', currentYear);
        yr.put('c2g__NumberOfPeriods__c', 12);
        yr.put('c2g__AutomaticPeriodList__c', true);
        yr.put('c2g__StartDate__c', Date.valueOf(currentYear + '-01-01 00:00:00'));
        yr.put('c2g__EndDate__c', Date.valueOf(currentYear + '-12-31 00:00:00'));
        yr.put('c2g__PeriodCalculationBasis__c', 'Month End');

        insert yr;

        String currentMth = String.valueOf(Date.today().month());
        if(currentMth.length() == 1) 
            currentMth = '0' + currentMth;

        List<c2g__codaPeriod__c> periods = new List<c2g__codaPeriod__c>();        

        c2g__codaPeriod__c currentTestPeriod;
        List<String> monthNumbers = new List<String>{'01','02','03','04','05','06','07','08','09','10','11','12','01','12','12'};
        for (String monthNumber : monthNumbers) 
        {
            c2g__codaPeriod__c period = new c2g__codaPeriod__c();
            period.put('Name', currentYear + '/' + '0' + monthNumber);
            period.put('c2g__YearName__c', yr.id);
            period.put('c2g__PeriodNumber__c', '0' + monthNumber);
            period.put('c2g__Description__c', 'Trading Period');                   
            period.put('c2g__StartDate__c', Date.valueOf(currentYear + '-' + monthNumber + '-01 00:00:00'));
            period.put('c2g__EndDate__c', Date.valueOf(currentYear + '-' + monthNumber + '-01 00:00:00').addMonths(1).addDays(-1));
            periods.add(period);

            //returns current period
            if (monthNumber == currentMth) 
                currentTestPeriod = period; 
        }
        // fix the opening period
        periods[12].put('Name', currentYear + '/000');
        periods[12].put('c2g__PeriodNumber__c', '000');
        periods[12].put('c2g__Description__c', 'Opening (B/fwd)');
        periods[12].put('c2g__EndDate__c', periods[12].c2g__StartDate__c); 

        // fix the closing period
        periods[13].put('Name' , currentYear + '/101');
        periods[13].put('c2g__PeriodNumber__c', '101');
        periods[13].put('c2g__Description__c', 'Closing (C/fwd)');
        periods[13].put('c2g__StartDate__c', periods[13].c2g__EndDate__c);

        // fix the adjustment period
        periods[14].put('Name' , currentYear + '/100');
        periods[14].put('c2g__PeriodNumber__c', '100');
        periods[14].put('c2g__Description__c', 'Adjustment Period');
        periods[14].put('c2g__StartDate__c', periods[14].c2g__EndDate__c);
                    
        insert periods;
        
        return currentTestPeriod;
    }
    
    /**
    *   Create GLA Accounts
    *   No @Parms required
    **/
    public static Map<String,c2g__codaGeneralLedgerAccount__c> createGLAccounts()
    {    
        c2g__codaGeneralLedgerAccount__c accountsPayableControl, accountsReceivableControl, grossRevenue, bankAccCurUK, bankCharges, bankInterest, deferredIncome, salesTaxA, cogs;
        
        List<c2g__codaGeneralLedgerAccount__c> glaList;

        deferredIncome = new c2g__codaGeneralLedgerAccount__c();
        deferredIncome.put('Name' , '2200t - Deferred Income');
        deferredIncome.put('c2g__ReportingCode__c' , '2200t');
        deferredIncome.put('c2g__Type__c' , 'Balance Sheet');
        deferredIncome.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        deferredIncome.put('c2g__TrialBalance2__c' , 'Current Liabilities');
        deferredIncome.put('c2g__TrialBalance3__c' , 'Accruals and Deferred Income');
        deferredIncome.put('c2g__TrialBalance4__c' , '-');
        deferredIncome.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        deferredIncome.put('c2g__BalanceSheet2__c' , 'Current Liabilities');
        deferredIncome.put('c2g__BalanceSheet3__c' , 'Accruals and Deferred Income');

        accountsPayableControl = new c2g__codaGeneralLedgerAccount__c();
        accountsPayableControl.put('Name' , '2000t - Accounts Payable Control');
        accountsPayableControl.put('c2g__ReportingCode__c' , '2000t');
        accountsPayableControl.put('c2g__Type__c' , 'Balance Sheet');
        accountsPayableControl.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        accountsPayableControl.put('c2g__TrialBalance2__c' , 'Current Liabilities');
        accountsPayableControl.put('c2g__TrialBalance3__c' , 'Creditors');
        accountsPayableControl.put('c2g__TrialBalance4__c' , '-');
        accountsPayableControl.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        accountsPayableControl.put('c2g__BalanceSheet2__c' , 'Current Liabilities');
        accountsPayableControl.put('c2g__BalanceSheet3__c' , 'Creditors');

        accountsReceivableControl = new c2g__codaGeneralLedgerAccount__c();
        accountsReceivableControl.put('Name' , '1200t - Accounts Receivable Control');
        accountsReceivableControl.put('c2g__ReportingCode__c' , '1200t');
        accountsReceivableControl.put('c2g__Type__c' , 'Balance Sheet');
        accountsReceivableControl.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        accountsReceivableControl.put('c2g__TrialBalance2__c' , 'Current Assets');
        accountsReceivableControl.put('c2g__TrialBalance3__c' , 'Debtors');
        accountsReceivableControl.put('c2g__TrialBalance4__c' , '-');
        accountsReceivableControl.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        accountsReceivableControl.put('c2g__BalanceSheet2__c' , 'Current Assets');
        accountsReceivableControl.put('c2g__BalanceSheet3__c' , 'Debtors');

        grossRevenue = new c2g__codaGeneralLedgerAccount__c();
        grossRevenue.put('Name' , '4000t - Gross revenue');
        grossRevenue.put('c2g__ReportingCode__c' , '4000t');
        grossRevenue.put('c2g__Type__c' , 'Profit and Loss');
        grossRevenue.put('c2g__TrialBalance1__c' , 'Profit and Loss');
        grossRevenue.put('c2g__TrialBalance2__c' , 'Gross Profit');
        grossRevenue.put('c2g__TrialBalance3__c' , 'Sales Revenue');
        grossRevenue.put('c2g__TrialBalance4__c' , 'Sales - Direct');
        grossRevenue.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        grossRevenue.put('c2g__BalanceSheet2__c' , 'Profit and Loss');
        grossRevenue.put('c2g__BalanceSheet3__c' , '-');

        //Bank Account - Current UK
        bankAccCurUK = new c2g__codaGeneralLedgerAccount__c();
        bankAccCurUK.put('Name' , 'BNK001 UKt 24000 - Customer Prepaids (MPS)');
        bankAccCurUK.put('c2g__ReportingCode__c' , 'BNK001 UKt');
        bankAccCurUK.put('c2g__Type__c' , 'Balance Sheet');
        bankAccCurUK.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        bankAccCurUK.put('c2g__TrialBalance2__c' , 'Current Assets');
        bankAccCurUK.put('c2g__TrialBalance3__c' , 'Bank and Cash');
        bankAccCurUK.put('c2g__TrialBalance4__c' , '');
        bankAccCurUK.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        bankAccCurUK.put('c2g__BalanceSheet2__c' , 'Current Assets');
        bankAccCurUK.put('c2g__BalanceSheet3__c' , 'Bank and Cash');

        //Bank Charges
        bankCharges = new c2g__codaGeneralLedgerAccount__c();
        bankCharges.put('Name' , '61620 - Bank Charges');
        bankCharges.put('c2g__ReportingCode__c' , '61620');
        bankCharges.put('c2g__Type__c' , 'Profit and Loss');
        bankCharges.put('c2g__TrialBalance1__c' , 'Profit and Loss');
        bankCharges.put('c2g__TrialBalance2__c' , 'Operating Expenses');
        bankCharges.put('c2g__TrialBalance3__c' , 'Administration Costs');
        bankCharges.put('c2g__TrialBalance4__c' , '');
        bankCharges.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        bankCharges.put('c2g__BalanceSheet2__c' , 'Current Assets');
        bankCharges.put('c2g__BalanceSheet3__c' , 'Profit and Loss');

        //Bank Charges
        bankInterest = new c2g__codaGeneralLedgerAccount__c();
        bankInterest.put('Name' , '64740 - Bank Interest');
        bankInterest.put('c2g__ReportingCode__c' , '64740');
        bankInterest.put('c2g__Type__c' , 'Profit and Loss');
        bankInterest.put('c2g__TrialBalance1__c' , 'Profit and Loss');
        bankInterest.put('c2g__TrialBalance2__c' , 'Interest and Taxation');
        bankInterest.put('c2g__TrialBalance3__c' , 'Finance Costs');
        bankInterest.put('c2g__TrialBalance4__c' , '');
        bankInterest.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        bankInterest.put('c2g__BalanceSheet2__c' , 'Current Assets');
        bankInterest.put('c2g__BalanceSheet3__c' , 'Profit and Loss');

        //Tax Code
        salesTaxA = new c2g__codaGeneralLedgerAccount__c();
        salesTaxA.put('Name' , '2160t - Sales Tax A');
        salesTaxA.put('c2g__ReportingCode__c' , '2160t');
        salesTaxA.put('c2g__Type__c' , 'Balance Sheet');
        salesTaxA.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        salesTaxA.put('c2g__TrialBalance2__c' , 'Current Liabilities');
        salesTaxA.put('c2g__TrialBalance3__c' , 'Tax Liability');
        salesTaxA.put('c2g__TrialBalance4__c' , '');
        salesTaxA.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        salesTaxA.put('c2g__BalanceSheet2__c' , 'Current Liabilities');
        salesTaxA.put('c2g__BalanceSheet3__c' , 'Tax Liability');

        cogs = new c2g__codaGeneralLedgerAccount__c();
        cogs.put('Name' , '5100t - COGS - Materials');
        cogs.put('c2g__ReportingCode__c' , '5100t');
        cogs.put('c2g__Type__c' , 'Profit and Loss');
        cogs.put('c2g__TrialBalance1__c' , 'Profit and Loss');
        cogs.put('c2g__TrialBalance2__c' , 'Gross Profit');
        cogs.put('c2g__TrialBalance3__c' , 'Cost of Sales');
        cogs.put('c2g__TrialBalance4__c' , 'Cost of Sales - Direct');
        cogs.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        cogs.put('c2g__BalanceSheet2__c' , 'Profit and Loss');
        cogs.put('c2g__BalanceSheet3__c' , '');
        
        glaList = new List<c2g__codaGeneralLedgerAccount__c>{accountsPayableControl, accountsReceivableControl, grossRevenue, bankAccCurUK, bankCharges, bankInterest, deferredIncome, salesTaxA, cogs};
        insert glaList;
        
        return new Map<String,c2g__codaGeneralLedgerAccount__c>{
            'accountsPayableControl'=>accountsPayableControl,
            'accountsReceivableControl'=>accountsReceivableControl,
            'grossRevenue'=>grossRevenue,
            'bankAccCurUK'=>bankAccCurUK,
            'bankCharges'=>bankCharges,
            'bankInterest'=>bankInterest,
            'deferredIncome'=>deferredIncome,
            'salesTaxA'=>salesTaxA,
            'cogs'=>cogs
        };
        
    }

    /**
    *   Create or Insert Account
    *   No @Parms required
    **/
    public static Account createAccount(String name, Id accountsReceivableControlId, Id accountsPayableControlId)
    {
        Account productServices = new Account();
        productServices.put('Name', name);
        //productServices.put('CurrencyIsoCode', 'USD');
        productServices.put('Type', 'Customer - Direct');
        productServices.put('Industry', 'Apparel');
        productServices.put('AnnualRevenue', 350000000);
        productServices.put('Ownership', 'Public');
        productServices.put('Rating', 'Warm');
        productServices.put('Phone', '(336) 222-7000');
        productServices.put('Fax', '(336) 222-8000');
        productServices.put('Website', 'http://www.financialforce.com');
        productServices.put('TickerSymbol', 'BTXT');
        productServices.put('NumberOfEmployees', 9000);
        productServices.put('SIC', '546732');
        productServices.put('c2g__CODAReportingCode__c', 'ABC123t');
        productServices.put('c2g__CODAAccountsReceivableControl__c', accountsReceivableControlId);
        productServices.put('c2g__CODAAccountsPayableControl__c', accountsPayableControlId);
        productServices.put('c2g__CODASalesTaxStatus__c', 'Exempt');
        productServices.put('c2g__CODAVATStatus__c', 'EC Registered');
        productServices.put('c2g__CODAECCountryCode__c', 'FR');
        productServices.put('c2g__CODAVATRegistrationNumber__c', '123 43223 3');
        productServices.put('c2g__CODATaxCalculationMethod__c', 'Gross');
        productServices.put('c2g__CODAInvoiceEmail__c', 'productservices@financialforce.com');
        productServices.put('c2g__CODADescription1__c', 'Standard Terms');
        productServices.put('c2g__CODADaysOffset1__c', 30);
        productServices.put('c2g__CODABaseDate1__c', 'Invoice Date');
        productServices.put('c2g__CODADiscount1__c', 0);
        productServices.put('c2g__CODAAccountTradingCurrency__c', 'USD');

        insert productServices;

        return productServices;
    }   
    /**
        *   Create Product
        *   No @Parms required
    **/
    public static Product2 createProduct(Id cogsId, Id grossRevenueId)
    {
        Product2 prod = new Product2();
        prod.put('Name' , 'Titanium');
        prod.put('ProductCode' , 'TIT101');
        prod.put('IsActive' , true);
        prod.put('c2g__CODAPurchaseAnalysisAccount__c' , cogsId);
        prod.put('c2g__CODASalesRevenueAccount__c' , grossRevenueId);
        prod.put('c2g__CODASalesTaxStatus__c' , 'Taxable');

        insert prod;
        return prod;
    }
    /**
        *   Create PricebookEntry
        *   One Param required 
        *       - Id prodId - Product2 Id
    **/
    public static PricebookEntry createPriceBook(Id prodId)
    {
        // Get Pricebook
        Pricebook2 priceBook = Database.query('select id from Pricebook2 where IsStandard = true');
        priceBook.put('IsActive' , true);
        update priceBook;  

        PricebookEntry priceBookEntry = new PricebookEntry();
        priceBookEntry.put('Pricebook2Id' , priceBook.Id);
        priceBookEntry.put('Product2Id' , prodId); 
        priceBookEntry.put('UnitPrice' , 5000);
        priceBookEntry.put('IsActive' , true);
        priceBookEntry.put('UseStandardPrice' , false);

        insert priceBookEntry;

        return priceBookEntry;
    }
    /**
    *   Create Sales Invoice Header
    *   One Param required 
    *       - Id accId - Account Id
    **/
    //public static c2g__codaInvoice__c createSalesInvoice(Id accId, Id currencyId, Id periodId)
    //{
    //   c2g__codaInvoice__c invoice = new c2g__codaInvoice__c();
    //    invoice.put('c2g__Account__c' , accId);
    //    invoice.put('c2g__InvoiceDate__c' , System.today());
    //    invoice.put('c2g__InvoiceCurrency__c' , currencyId);
    //    invoice.put('c2g__Period__c' , periodId);
    //
    //    insert invoice;
    //    return invoice;
    //}
    /**
    *   Create Sales Invoice Line
    *   Two Param required 
    *       - Id prodId - Product2 Id
    *       - Id headerId - Sales Invoice Header Id
    **/
    //public static c2g__codaInvoiceLineItem__c createSalesInvoiceLine(Id headerId, Id prodId)
    //{
    //    c2g__codaInvoiceLineItem__c invoiceLine = new c2g__codaInvoiceLineItem__c();
    //    invoiceLine.put('c2g__Quantity__c' ,500);
    //    invoiceLine.put('c2g__LineDescription__c' , 'Testing123CoolDude123Income');
    //    invoiceLine.put('c2g__UnitPrice__c' , 1);
    //    invoiceLine.put('c2g__Product__c' , prodId);
    //    invoiceLine.put('c2g__DeriveUnitPriceFromProduct__c' , false);
    //    invoiceLine.put('c2g__Invoice__c' , headerId);
    //
    //    insert invoiceLine;
    //    return invoiceLine;
    //}
    
    /**
        *   Create List of Object Queue Names
        *   No @Parms required
    **/
    public static List<String> getQueueObjectNames()
    {
        List<String> objectNames = new List<String>();

        //Financial Objects
        objectNames.add('c2g__codaCompany__c');
        objectNames.add('c2g__codaYear__c');
        objectNames.add('c2g__codaCurrencyRevaluation__c');
        objectNames.add('c2g__ReportingBalance__c');
        objectNames.add('c2g__codaBudget__c');
        objectNames.add('c2g__codaBankAccount__c');
        objectNames.add('c2g__codaBankStatement__c');
        objectNames.add('c2g__codaPaymentMediaControl__c');
        objectNames.add('c2g__codaBankReconciliation__c');
        objectNames.add('c2g__codaPaymentMediaSummary__c');
        objectNames.add('c2g__codaMatchingReference__c');
        objectNames.add('c2g__codaAccountingCurrency__c');
        objectNames.add('c2g__codaGroupingReference__c');
        objectNames.add('c2g__codaPaymentTemplate__c');

        //Document Objects
        objectNames.add('c2g__codaTransaction__c');
        objectNames.add('c2g__codaInvoice__c');
        objectNames.add('c2g__codaJournal__c');
        objectNames.add('c2g__codaCreditNote__c');
        objectNames.add('c2g__codaCashEntry__c');
        objectNames.add('c2g__codaPurchaseInvoice__c');
        objectNames.add('c2g__codaPurchaseCreditNote__c');
        objectNames.add('c2g__codaPayment__c');
        //objectNames.add('c2g__CancelPayment__c');
        objectNames.add('c2g__codaCashMatchingHistory__c');

        //Random Objects
        objectNames.add('c2g__codaTextDefinition__c');
        objectNames.add('c2g__codaIntercompanyDefinition__c');
        //objectNames.add('c2g__AsOfAging__c');
        objectNames.add('c2g__codaIntercompanyTransfer__c');
        objectNames.add('c2g__codaYear__c');

        return objectNames;     
    }


}