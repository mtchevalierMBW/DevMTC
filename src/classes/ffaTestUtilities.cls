/**
	2017-11-01	B. Leaman	BLL1 - don't start & stop testing here. Do it in the test classes, not the support utils.
**/
@isTest
global class ffaTestUtilities  {
 
    /**************************************************************************
    ** Create Test Company and periods
    **************************************************************************/
    public static c2g__codaCompany__c createFFACompany(String companyName, Boolean setAsCurrent, String homeCurrencyIso) {
        // Setup Company and User association within runAs to avoid mixed DML restriction
        Group companyGroup = null;
        GroupMember gm = null;
        c2g__codaCompany__c company;
        System.runAs([select Id from User where Id = :UserInfo.getUserId()][0]) {
            //BLL1d Test.startTest();
            // Create Company
            company = new c2g__codaCompany__c();
            company.Name = companyName;
            company.RecordTypeId = Schema.SObjectType.c2g__codaCompany__c.RecordTypeInfosByName.get('VAT').RecordTypeId;
            insert company;
            // Create Company Queue
            c2g.CODACompanyWebService.createQueue(company.Id, 'USD', company.Name);
            // Activate the Company
            c2g.CODAYearWebService.calculatePeriods(null); // Workaround to bug in company API's, safe to remain once fixed
            c2g.CODACompanyWebService.activateCompany(company.Id, 'USD', company.Name);       
            // Assign the User to the Company
            c2g__codaUserCompany__c userCompany = new c2g__codaUserCompany__c();
            userCompany.c2g__Company__c = company.Id;
            userCompany.c2g__User__c = UserInfo.getUserId();
            insert userCompany;     
            String queueName = 'FF ' + company.Name;
            system.debug('\n\n ***** ffaTestUtilities - createFFACompany - queueName' + queueName);
            companyGroup = [select Id from Group where Name = :queueName And Type = 'Queue']; 
            // Assign the User to the Company Queue
            gm = new GroupMember( GroupId = companyGroup.Id, UseroRGroupId = UserInfo.getUserId());
            insert gm;
            // Assert user logged into the company
            System.assertEquals(companyName, c2g.CODAAPICompany_2_0.GetCurrentCompanies(null)[0]);
            //BLL1d Test.stopTest();
        }
        
        // Create Year and Periods
        c2g__codaYear__c yr = new c2g__codaYear__c();
        yr.Name = String.valueOf(Date.today().year());
        yr.OwnerId = companyGroup.Id;
        yr.c2g__NumberOfPeriods__c = 12;
        yr.c2g__OwnerCompany__c = company.id;
        yr.c2g__AutomaticPeriodList__c = true;
        yr.c2g__StartDate__c = Date.valueOf(Date.today().year() + '-01-01 00:00:00');
        yr.c2g__EndDate__c = Date.valueOf(Date.today().year() + '-12-31 00:00:00');
        yr.c2g__PeriodCalculationBasis__c = 'Month End';
        insert yr;
        c2g.CODAYearWebService.calculatePeriods(yr.Id);
        // Create Accounting Currency?
        if(UserInfo.isMultiCurrencyOrganization()) {
            c2g__codaAccountingCurrency__c testCurrency = new c2g__codaAccountingCurrency__c();
            testCurrency.Name = homeCurrencyIso;
            testCurrency.c2g__DecimalPlaces__c = 2;
            testCurrency.c2g__Home__c = true;
            testCurrency.c2g__Dual__c = true;
            insert testCurrency;                   
        }
        return company;
   }
 
   /**************************************************************************
    ** Create Test Company and periods
    **************************************************************************/
    public static c2g__codaAccountingCurrency__c createFFACurrency(String isoCode, Boolean isHome, Boolean isDual)
    {
        c2g__codaAccountingCurrency__c testCurrency;
        if(UserInfo.isMultiCurrencyOrganization()) {
            testCurrency = new c2g__codaAccountingCurrency__c();
            testCurrency.Name = isoCode;
            testCurrency.c2g__DecimalPlaces__c = 6;
            testCurrency.c2g__Home__c = isHome;
            testCurrency.c2g__Dual__c = isDual;
            insert testCurrency;                   
        }
        return testCurrency;
    }
 
    /**************************************************************************
    ** Clear all current companies
    **************************************************************************/
    public static void clearCurrentCompany(Id userId) {            
        System.runAs([select Id from User where Id = :UserInfo.getUserId()][0]) {
            List<GroupMember> currentCompanies = [SELECT Id FROM GroupMember WHERE UseroRGroupId = :userId];
            system.debug('\n\n ***** clearCurrentCompany - currentCompanies before delete' + currentCompanies);
            if(!currentCompanies.isEmpty()){
                Delete currentCompanies;
            }
        }
    }
 
    /**************************************************************************
    ** Set current company
    **************************************************************************/
    public static void setCurrentCompany(Id userId, Id companyId) {
        clearCurrentCompany(userId);
        System.runAs([select Id from User where Id = :UserInfo.getUserId()][0]){
            Id groupId = [select ownerid from c2g__codaCompany__c where id = :companyId].ownerid;
            insert new GroupMember(GroupId = groupId, UseroRGroupId = userId);
        }
    }
 
    /**************************************************************************
    ** Clear all current companies
    **************************************************************************/
    public static void createIntercoDefinition(Id glaId, Id relatedCompanyId) {
        c2g__codaIntercompanyDefinition__c intercoDef = new c2g__codaIntercompanyDefinition__c(
            c2g__ReceivingControlAccount__c = glaId,
            c2g__SendingControlAccount__c = glaId,
            c2g__RelatedCompany__c = relatedCompanyId);
        insert intercoDef;
    }
 
    // --> Dimension 1  
    public static c2g__codaDimension1__c createTestDimension1()
    {
        c2g__codaDimension1__c dim1 = new c2g__codaDimension1__c(
            Name = 'TEST',
            c2g__ReportingCode__c = 'TEST'
            );
        insert dim1;
        return dim1;
    }
    // BLL1a
    public static c2g__codaDimension1__c getTestDimension1() {
    	List<c2g__codaDimension1__c> dim1s = [select Id, Name, c2g__ReportingCode__c from c2g__codaDimension1__c where Name='TEST'];
    	return (dim1s.size()>0) ? dim1s[0] : null;
    }
    // BLL1a end
    // --> Dimension 2
    public static c2g__codaDimension2__c createTestDimension2()
    {
        c2g__codaDimension2__c dim2 = new c2g__codaDimension2__c(
            Name = 'TEST',
            c2g__ReportingCode__c = 'TEST'
            );
        insert dim2;
        return dim2;
    }
    // --> Dimension 3
    public static c2g__codaDimension3__c createTestDimension3()
    {
        c2g__codaDimension3__c dim3 = new c2g__codaDimension3__c(
            Name = 'TEST',
            c2g__ReportingCode__c = 'TEST'
            );
        insert dim3;
        return dim3;
    }
    // --> Dimension 4
    public static c2g__codaDimension4__c createTestDimension4()
    {
        c2g__codaDimension4__c dim4 = new c2g__codaDimension4__c(
            Name = 'TEST',
            c2g__ReportingCode__c = 'TEST'
            );
        insert dim4;
        return dim4;
    }
 
    // --> GLA Accounts
    public static c2g__codaGeneralLedgerAccount__c create_BS_GLA()
    {
        c2g__codaGeneralLedgerAccount__c bs_acct = new c2g__codaGeneralLedgerAccount__c
        (
            Name = '2000 - Accounts Payable',
            c2g__ReportingCode__c = '10000000',
            c2g__Type__c = 'Balance Sheet'
        );
        insert bs_acct;
        return bs_acct;
    }
    // --> GLA Accounts
    public static c2g__codaGeneralLedgerAccount__c create_BS_GLA(String glaName)
    {
        c2g__codaGeneralLedgerAccount__c bs_acct = new c2g__codaGeneralLedgerAccount__c
        (
            Name = glaName,
            c2g__ReportingCode__c = '10000000',
            c2g__Type__c = 'Balance Sheet'
        );
        insert bs_acct;
        return bs_acct;
    }
 
    // --> GLA Accounts:
    public static c2g__codaGeneralLedgerAccount__c create_IS_GLA()
    {
        c2g__codaGeneralLedgerAccount__c is_acct = new c2g__codaGeneralLedgerAccount__c
        (
            Name = 'Income Statement Account',
            c2g__ReportingCode__c = '400000000',
            c2g__Type__c = 'Income Statement'
        );
        insert is_acct;
        return is_acct;
    }
     // --> GLA Accounts:
    public static c2g__codaGeneralLedgerAccount__c create_IS_GLA(String glaName)
    {
        c2g__codaGeneralLedgerAccount__c is_acct = new c2g__codaGeneralLedgerAccount__c
        (
            Name = glaName,
            c2g__ReportingCode__c = '400000000',
            c2g__Type__c = 'Income Statement'
        );
        insert is_acct;
        return is_acct;
    }
 
    //======== Sales Invoice - with Dimensions =============:
    public static c2g__codaInvoice__c createSIN(Account account, Date invoice_date, Id productID, Decimal amount)
    {
        c2g__codaInvoice__c sin = new c2g__codaInvoice__c(
            c2g__Account__c = account.id,
            c2g__InvoiceDate__c = invoice_date,
            c2g__DeriveDueDate__c = TRUE,
            c2g__DeriveCurrency__c = TRUE,
            c2g__DerivePeriod__c = TRUE);
        insert sin;
        createSIN_Line(productId, amount, sin);
        return sin;
    }
 
        public static void createSIN_Line(Id productId, Decimal amount, c2g__codaInvoice__c sin)
        {
            c2g__codaInvoiceLineItem__c line = new c2g__codaInvoiceLineItem__c(
                c2g__Invoice__c = sin.id,
                c2g__Product__c = productId,
                c2g__UnitPrice__c = amount,
                c2g__LineNumber__c = 1,
                c2g__DeriveUnitPriceFromProduct__c = FALSE);
            insert line;
        }
    //=======================================
     
    //======== Sales Invoice - with Dimensions =============::
    public static c2g__codaInvoice__c createSIN_with_Dimensions(Account account, Date invoice_date, Id productID, Decimal amount, Id dim1, Id dim2, Id dim3)
    {
        c2g__codaInvoice__c sin = new c2g__codaInvoice__c(
            c2g__Account__c = account.id,
            c2g__InvoiceDate__c = invoice_date,
            c2g__DeriveDueDate__c = TRUE,
            c2g__DeriveCurrency__c = TRUE,
            c2g__DerivePeriod__c = TRUE,
            c2g__Dimension1__c = dim1,
            c2g__Dimension2__c = dim2,
            c2g__Dimension3__c = dim3
            );
        insert sin;
        createSIN_Line_with_Dimensions(productId, amount, sin, dim1, dim2, dim3);
        return sin;
    }
 
        public static void createSIN_Line_with_Dimensions(Id productId, Decimal amount, c2g__codaInvoice__c sin, Id dim1, Id dim2, Id dim3)
        {
            c2g__codaInvoiceLineItem__c line = new c2g__codaInvoiceLineItem__c(
                c2g__Invoice__c = sin.id,
                c2g__Product__c = productId,
                c2g__UnitPrice__c = amount,
                c2g__LineNumber__c = 1,
                c2g__Dimension1__c = dim1,
                c2g__Dimension2__c = dim2,
                c2g__Dimension3__c = dim3,
                c2g__DeriveUnitPriceFromProduct__c = FALSE);
            insert line;
        }
    //===============================
 
    //======== Sales Credit Note =============::
    public static c2g__codaCreditNote__c createSCN(Account account, Date invoice_date, Id productID, Decimal amount, Id invoiceID)
    {
        c2g__codaCreditNote__c scn = new c2g__codaCreditNote__c(
            c2g__Account__c = account.id,
            c2g__Invoice__c = (invoiceID != null ? invoiceID : null),
            c2g__InvoiceDate__c = invoice_date,
            c2g__DeriveDueDate__c = TRUE,
            c2g__DeriveCurrency__c = TRUE,
            c2g__DerivePeriod__c = TRUE);
        insert scn;
        createSCN_Line(productId, amount, scn);
        return scn;
    }
 
        public static void createSCN_Line(Id productId, Decimal amount, c2g__codaCreditNote__c scn)
        {
            c2g__codaCreditNoteLineItem__c line = new c2g__codaCreditNoteLineItem__c(
                c2g__CreditNote__c = scn.id,
                c2g__Product__c = productId,
                c2g__UnitPrice__c = amount,
                c2g__LineNumber__c = 1,
                c2g__DeriveUnitPriceFromProduct__c = FALSE);
            insert line;
        }
    //=====================:
 
    //======== Sales Credit Note - with Dimensions =============::
    public static c2g__codaCreditNote__c createSCN_with_Dimension(Account account, Date invoice_date, Id productID, Decimal amount, Id invoiceID, Id dim1, Id dim2, Id dim3)
    {
        c2g__codaCreditNote__c scn = new c2g__codaCreditNote__c(
            c2g__Account__c = account.id,
            c2g__Invoice__c = (invoiceID != null ? invoiceID : null),
            c2g__InvoiceDate__c = invoice_date,
            c2g__DeriveDueDate__c = TRUE,
            c2g__DeriveCurrency__c = TRUE,
            c2g__Dimension1__c = dim1,
            c2g__Dimension2__c = dim2,
            c2g__Dimension3__c = dim3,
            c2g__DerivePeriod__c = TRUE);
        insert scn;
        createSCN_Line_with_Dimension(productId, amount, scn, dim1, dim2, dim3);
        return scn;
    }
 
        public static void createSCN_Line_with_Dimension(Id productId, Decimal amount, c2g__codaCreditNote__c scn, Id dim1, Id dim2, Id dim3)
        {
            c2g__codaCreditNoteLineItem__c line = new c2g__codaCreditNoteLineItem__c(
                c2g__CreditNote__c = scn.id,
                c2g__Product__c = productId,
                c2g__UnitPrice__c = amount,
                c2g__Dimension1__c = dim1,
                c2g__LineNumber__c = 1,
                c2g__Dimension2__c = dim2,
                c2g__Dimension3__c = dim3,
                c2g__DeriveUnitPriceFromProduct__c = FALSE);
            insert line;
        }
    //=====================:
 
    // --> Payable Invoice:
    public static c2g__codaPurchaseInvoice__c createPIN(Account account, Date invoice_date, Id glaID, Decimal amount)
    {
        c2g__codaPurchaseInvoice__c pin = new c2g__codaPurchaseInvoice__c(
            c2g__Account__c = account.id,
            c2g__InvoiceDate__c = invoice_date,
            ffap__DeriveDueDate__c = TRUE,
            ffap__DeriveCurrency__c = TRUE,
            ffap__DerivePeriod__c = TRUE,
            c2g__AccountInvoiceNumber__c = 'TEST');
        insert pin;
        createPIN_Line(glaID, amount, pin);
        return pin;
    }
 
        public static void createPIN_Line(Id glaID, Decimal amount, c2g__codaPurchaseInvoice__c pin)
        {
            c2g__codaPurchaseInvoiceExpenseLineItem__c line = new c2g__codaPurchaseInvoiceExpenseLineItem__c(
                c2g__PurchaseInvoice__c = pin.id,
                c2g__GeneralLedgerAccount__c = glaID,
                c2g__NetValue__c = amount,
                ffap__SetGLAToDefault__c = FALSE);
            insert line;
        }
    //=====================:
 
    //===== Payable Credit Note ======:
    public static c2g__codaPurchaseCreditNote__c createPCN(Account account, Date invoice_date, Id glaID, Decimal amount, Id dim1ID)
    {
        c2g__codaPurchaseCreditNote__c pcn = new c2g__codaPurchaseCreditNote__c(
            c2g__Account__c = account.id,
            c2g__InvoiceDate__c = invoice_date,
            ffap__DeriveDueDate__c = TRUE,
            ffap__DeriveCurrency__c = TRUE,
            ffap__DerivePeriod__c = TRUE,
            c2g__CreditNoteReason__c = 'TEST',
            c2g__AccountCreditNoteNumber__c = 'TEST123');
        insert pcn;
        createPCN_Line(glaID, amount, pcn, dim1ID);
        return pcn;
    }
 
        public static void createPCN_Line(Id glaID, Decimal amount, c2g__codaPurchaseCreditNote__c pcn, Id dim1ID)
        {
            c2g__codaPurchaseCreditNoteExpLineItem__c line = new c2g__codaPurchaseCreditNoteExpLineItem__c(
                c2g__PurchaseCreditNote__c = pcn.id,
                c2g__GeneralLedgerAccount__c = glaID,
                c2g__NetValue__c = amount,
                c2g__Dimension1__c = dim1ID,
                ffap__SetGLAToDefault__c = FALSE);
            insert line;
        }
    //=====================:
 
    //===== Journals ======:
    public static c2g__codaJournal__c createJNL(Date invoice_date, Id glaID, Decimal amount)
    {
        c2g__codaJournal__c jnl = new c2g__codaJournal__c(
            c2g__journalDate__c = Date.today(),
            ffgl__DeriveCurrency__c = TRUE,
            ffgl__DerivePeriod__c = TRUE,
            c2g__Type__c = 'Manual Journal');
        insert jnl;
        createJNL_Lines(glaID, amount, jnl);
        return jnl;
    }
 
        public static void createJNL_Lines(Id glaID, Decimal amount, c2g__codaJournal__c jnl)
        {
            c2g__codaJournalLineItem__c line1 = new c2g__codaJournalLineItem__c(
                c2g__Journal__c = jnl.id,
                c2g__GeneralLedgerAccount__c = glaID,
                c2g__Value__c = amount,
                c2g__LineType__c = 'General Ledger Account');
            insert line1;
            c2g__codaJournalLineItem__c line2 = new c2g__codaJournalLineItem__c(
                c2g__Journal__c = jnl.id,
                c2g__GeneralLedgerAccount__c = glaID,
                c2g__Value__c = -amount,
                c2g__LineType__c = 'General Ledger Account');
            insert line2;
        }
    //=======================:

    //===== Journals with AccountLine ======:
    public static c2g__codaJournal__c createJNL(Date invoice_date, Id glaID, Decimal amount, c2g__codaCompany__c comp, Id acctId)
    {
        c2g__codaJournal__c jnl = new c2g__codaJournal__c(
            c2g__journalDate__c = Date.today(),
            c2g__OwnerCompany__c = comp.id,
            OwnerId = comp.ownerId,
            ffgl__DeriveCurrency__c = TRUE,
            ffgl__DerivePeriod__c = TRUE,
            c2g__Type__c = 'Manual Journal');
        insert jnl;
        createJNL_Lines_withAccount(glaID, amount, jnl, acctId);
        return jnl;
    }
 
        public static void createJNL_Lines_withAccount(Id glaID, Decimal amount, c2g__codaJournal__c jnl, Id acctId)
        {
            c2g__codaJournalLineItem__c line1 = new c2g__codaJournalLineItem__c(
                c2g__Journal__c = jnl.id,
                c2g__GeneralLedgerAccount__c = glaID,
                c2g__Account__c = acctId,
                c2g__Value__c = amount,
                c2g__LineType__c = 'Account - Customer');
            insert line1;
            c2g__codaJournalLineItem__c line2 = new c2g__codaJournalLineItem__c(
                c2g__Journal__c = jnl.id,
                c2g__GeneralLedgerAccount__c = glaID,
                c2g__Value__c = -amount,
                c2g__LineType__c = 'General Ledger Account');
            insert line2;
        }
    //=======================:
 
    //===== Journals - Intercompany ======:
    public static c2g__codaJournal__c createJNL_Intercompany(Date invoice_date, Id glaID, Decimal amount, Id destinationCo)
    {
        c2g__codaJournal__c jnl = new c2g__codaJournal__c(
            c2g__journalDate__c = Date.today(),
            ffgl__DeriveCurrency__c = TRUE,
            ffgl__DerivePeriod__c = TRUE,
            c2g__Type__c = 'Manual Journal');
        insert jnl;
        createJNL_Lines(glaID, amount, jnl);
        return jnl;
    }
        public static void createJNL_Lines(Id glaID, Decimal amount, c2g__codaJournal__c jnl, Id destinationCo)
        {
            c2g__codaJournalLineItem__c line1 = new c2g__codaJournalLineItem__c(
                c2g__Journal__c = jnl.id,
                c2g__GeneralLedgerAccount__c = glaID,
                c2g__Value__c = amount,
                c2g__LineType__c = 'General Ledger Account');
            insert line1;
            c2g__codaJournalLineItem__c line2 = new c2g__codaJournalLineItem__c(
                c2g__Journal__c = jnl.id,
                c2g__GeneralLedgerAccount__c = glaID,
                c2g__Value__c = -amount,
                c2g__DestinationCompany__c = destinationCo,
                c2g__LineType__c = 'Intercompany');
            insert line2;
        }
    //=======================:
 
    //===== Cash Entry ======:
    public static c2g__codaCashEntry__c createCSHreceipt(Account account, Id bankaccountId, Decimal amount)
    {
        c2g__codaCashEntry__c csh = new c2g__codaCashEntry__c(
            c2g__Type__c = 'Receipt',
            c2g__BankAccount__c = bankaccountId,
            c2g__Date__c = date.today());
        insert csh;
        createcsh_Line(account.id, amount, csh);
        return csh;
    }
        public static void createCSH_Line(Id accountId, Decimal amount, c2g__codaCashEntry__c csh)
        {
            c2g__codaCashEntryLineItem__c line = new c2g__codaCashEntryLineItem__c(
                c2g__CashEntry__c = csh.id,
                c2g__CashEntryValue__c = amount,
                c2g__Account__c = accountId);
            insert line;
        }
    //=======================:
     
     
//=========================================================================
// Generic SFDC methods
//=========================================================================
     
    // --> Account
    global static Account createAccount(String name, Id gla_id)
    {
        Account account  = new Account();
        account.name = name;
        account.c2g__CODAAccountsReceivableControl__c = (gla_id != null ? gla_id : null);
        account.c2g__CODAAccountsPayableControl__c = (gla_id != null ? gla_id : null);
        account.c2g__CODAAccountTradingCurrency__c = 'USD';
        account.c2g__CODABaseDate1__c = 'Invoice Date';
        account.c2g__CODADaysOffset1__c = 30;
        account.c2g__CODADescription1__c = 'net 30';
        account.c2g__CODADiscount1__c = 0;
        account.c2g__CODASalesTaxStatus__c = 'Exempt';
        insert account;
        return account;
    }
    // --> Contact
    global static Contact createTestContact (String firstname, String email)
    {
        Contact c = new Contact(
            email = email,
            lastName = 'TEST',
            firstname = firstname,
            MailingStreet = '10000 Sample St.',
            MailingCity = 'Sample City',
            MailingState = 'VA',
            MailingPostalCode = '23238',
            MailingCountry = 'USA');
        insert c;
        return c;
    }
    // BLL1a
    global static Account getAccount(String name) {
    	List<Account> accts = [
    		select Id, Name, c2g__CODAAccountsReceivableControl__c, c2g__CODAAccountsPayableControl__c, c2g__CODAAccountTradingCurrency__c,
    			c2g__CODABaseDate1__c, c2g__CODADaysOffset1__c, c2g__CODADescription1__c, c2g__CODADiscount1__c, c2g__CODASalesTaxStatus__c
    		from Account
    		where Name=:name
    	];
    	return (accts.size()>0) ? accts[0] : null; 
    }
    // BLL1a end
}