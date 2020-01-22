/**
 * GeneralLedgerAcctMW_TEST
 * Tests: GeneralLedgerAcctMW
 * 
 * 2016-06-28 : Updated to pass test by creating a company and including ourselves in the company
 */
@isTest
private class GeneralLedgerAcctMW_TEST {
    
	private static TestData testData = new TestData();    

    static testMethod void testGLAcctTrigger() {
        testData.refresh();
        System.runAs(testData.TestUser)
        {        
            c2g__codaGeneralLedgerAccount__c g = new c2g__codaGeneralLedgerAccount__c(
                Name='ABCD-Test account', c2g__ReportingCode__c='ABCD', c2g__Type__c='Balance Sheet'
            );
            insert(g);
            GeneralLedgerAcctMW__c gmw = [
                select Id, Name, ReportingCode__c, GeneralLedgerAccountFF__c
                from GeneralLedgerAcctMW__c
                where ReportingCode__c=:g.c2g__ReportingCode__c
            ];
            System.assert(gmw.GeneralLedgerAccountFF__c==g.Id, 'New GL account was not found in clone object');
    
            g.c2g__ReportingCode__c = 'ABCE';
            update(g);
            GeneralLedgerAcctMW__c gmw2 = [
                select Id, Name, ReportingCode__c, GeneralLedgerAccountFF__c
                from GeneralLedgerAcctMW__c
                where ReportingCode__c=:g.c2g__ReportingCode__c
            ];
            System.assert(gmw2.GeneralLedgerAccountFF__c==g.Id, 'Updated GL reporting code was not found in clone object');
            
            Exception expected;
            delete(g);
            try {
            GeneralLedgerAcctMW__c gmw3 = [
                select Id, Name, ReportingCode__c, GeneralLedgerAccountFF__c
                from GeneralLedgerAcctMW__c
                where ReportingCode__c=:g.c2g__ReportingCode__c
            ];
            } catch(Exception e) {
                expected = e;
            }
            System.assert(expected!=null, 'Deleted GL was not removed from clone object');
        }
    }
    
	
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
    *   Create Dimension 
    */
    public static c2g__codaDimension1__c createDimension() {
        
        c2g__codaDimension1__c cgd1 = new c2g__codaDimension1__c();
    
        cgd1.c2g__ExternalId__c='Company 1';
        cgd1.c2g__ReportingCode__c='Company 1';
        cgd1.c2g__UnitOfWork__c =12;

        insert cgd1;

        return cgd1;
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
        u.Division = 'AKR';

		insert u;

		return u;
	}    
    
    @testSetup
    static void createBaseFFAData()
    {
        testData.TestUser = createUser();       

        System.runAs(testData.TestUser)
        {
            Test.startTest();                        
            // GLA's, Accounts and Products are not company aware, create them first
            testData.GLAMap = createGLAccounts();
            testData.Account = createAccount('Tony Stark Enterprises', testData.GLAMap.get('accountsReceivableControl').Id, testData.GLAMap.get('accountsPayableControl').Id);
            // testData.Product = createProduct(testData.GLAMap.get('grossRevenue').Id, testData.GLAMap.get('cogs').Id);
            
            // create all 'Company' aware data objects
            // Create the Queue and simulate activating the company
            testData.CurrentCompany = createFFACompany('FinancialForce', createFFAQueue(testData.TestUser.Id).Id);
            // Add a user Company
            createUserCompany(testData.CurrentCompany.Id, testData.TestUser.Id);
            // create other base data types...
            testData.HomeCurrency = createHomeCurrency('USD');        
            testData.CurrentPeriod = createYearPeriods();

            Test.stopTest();
        }
    }  

    
    /**
    *   Create or Insert Account
    *   No @Parms required
    **/
    public static Account createAccount(String name, Id accountsReceivableControlId, Id accountsPayableControlId)
    {
        Account productServices = new Account();
        productServices.put('Name', name);
        // productServices.put('CurrencyIsoCode', 'USD');
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
    *   Create GLA Accounts
    *   No @Parms required
    **/
    public static Map<String,c2g__codaGeneralLedgerAccount__c> createGLAccounts()
    {    
	    c2g__codaGeneralLedgerAccount__c accountsPayableControl, accountsReceivableControl, grossRevenue, bankAccCurUK, bankCharges, bankInterest, deferredIncome, salesTaxA, cogs, unbilledPurchases, partsInventory, prePaidExpenses;
        
        List<c2g__codaGeneralLedgerAccount__c> glaList;

        deferredIncome = new c2g__codaGeneralLedgerAccount__c();
        deferredIncome.put('Name' , '2200 - Deferred Income');
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
        accountsPayableControl.put('Name' , '2000 - Accounts Payable Control');
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
        accountsReceivableControl.put('Name' , '1200 - Accounts Receivable Control');
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
        grossRevenue.put('Name' , '4000 - Gross revenue');
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
        bankAccCurUK.put('Name' , '24000 - Customer Prepaids (MPS)');
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
        bankCharges.put('Name' , 'Bank Charges');
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
        bankInterest.put('Name' , 'Bank Interest');
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
        salesTaxA.put('Name' , '2160 - Sales Tax A');
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
        cogs.put('Name' , '5100 - COGS - Materials');
        cogs.put('c2g__ReportingCode__c' , '5100t');
        cogs.put('c2g__Type__c' , 'Profit and Loss');
        cogs.put('c2g__TrialBalance1__c' , 'Profit and Loss');
        cogs.put('c2g__TrialBalance2__c' , 'Gross Profit');
        cogs.put('c2g__TrialBalance3__c' , 'Cost of Sales');
        cogs.put('c2g__TrialBalance4__c' , 'Cost of Sales - Direct');
        cogs.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        cogs.put('c2g__BalanceSheet2__c' , 'Profit and Loss');
        cogs.put('c2g__BalanceSheet3__c' , '');

        unbilledPurchases = new c2g__codaGeneralLedgerAccount__c();
        unbilledPurchases.put('Name' , '2115 - Unbilled Purchases');
        unbilledPurchases.put('c2g__ReportingCode__c' , '2115');
        unbilledPurchases.put('c2g__Type__c' , 'Balance Sheet');
        unbilledPurchases.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        unbilledPurchases.put('c2g__TrialBalance2__c' , 'Current Liabilities');
        unbilledPurchases.put('c2g__TrialBalance3__c' , 'Cost of Sales');
        unbilledPurchases.put('c2g__TrialBalance4__c' , 'Cost of Sales - Direct');
        unbilledPurchases.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        unbilledPurchases.put('c2g__BalanceSheet2__c' , 'Profit and Loss');
        unbilledPurchases.put('c2g__BalanceSheet3__c' , '');

        partsInventory = new c2g__codaGeneralLedgerAccount__c();
        partsInventory.put('Name' , '1220 - Unbilled Purchases');
        partsInventory.put('c2g__ReportingCode__c' , '1220');
        partsInventory.put('c2g__Type__c' , 'Balance Sheet');
        partsInventory.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        partsInventory.put('c2g__TrialBalance2__c' , 'Current Liabilities');
        partsInventory.put('c2g__TrialBalance3__c' , 'Cost of Sales');
        partsInventory.put('c2g__TrialBalance4__c' , 'Cost of Sales - Direct');
        partsInventory.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        partsInventory.put('c2g__BalanceSheet2__c' , 'Profit and Loss');
        partsInventory.put('c2g__BalanceSheet3__c' , '');  

        prePaidExpenses = new c2g__codaGeneralLedgerAccount__c();
        prePaidExpenses.put('Name' , '1274 - Unbilled Purchases');
        prePaidExpenses.put('c2g__ReportingCode__c' , '1274');
        prePaidExpenses.put('c2g__Type__c' , 'Balance Sheet');
        prePaidExpenses.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        prePaidExpenses.put('c2g__TrialBalance2__c' , 'Current Liabilities');
        prePaidExpenses.put('c2g__TrialBalance3__c' , 'Cost of Sales');
        prePaidExpenses.put('c2g__TrialBalance4__c' , 'Cost of Sales - Direct');
        prePaidExpenses.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        prePaidExpenses.put('c2g__BalanceSheet2__c' , 'Profit and Loss');
        prePaidExpenses.put('c2g__BalanceSheet3__c' , '');                  
        
        glaList = new List<c2g__codaGeneralLedgerAccount__c>{accountsPayableControl, accountsReceivableControl, grossRevenue, bankAccCurUK, bankCharges, bankInterest, deferredIncome, salesTaxA, cogs, unbilledPurchases, partsInventory, prePaidExpenses};
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
            'cogs'=>cogs,
            'unbilledPurchases'=>unbilledPurchases,
            'partsInventory'=>partsInventory,
            'prePaidExpenses'=>prePaidExpenses
        };
        
    }  
    
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
    
	public class TestData
	{
		public Account Account {get;set;}
        public c2g__codaCompany__c CurrentCompany {get;set;}
		public c2g__codaPeriod__c CurrentPeriod {get;set;}
		public c2g__codaAccountingCurrency__c HomeCurrency {get;set;}
        // public Product2 Product {get;set;}
        public Map<String,c2g__codaGeneralLedgerAccount__c> GLAMap {get;set;}
		public User TestUser {get;set;}
        public void refresh()
        {
            this.TestUser = [Select Id From User Where Username = 'ffdeveloper@nowhere.com'];
            this.Account = [Select Id From Account limit 1];
            this.CurrentCompany = [Select Id From c2g__codaCompany__c];
            this.HomeCurrency = [Select Id From c2g__codaAccountingCurrency__c];
            // this.Product = [Select Id From Product2];
                       
            this.CurrentPeriod = [Select Id From c2g__codaPeriod__c Where c2g__Description__c = 'Trading Period' And c2g__StartDate__c <= :System.today() And c2g__EndDate__c >= :System.today() limit 1];
        }
	}      
}