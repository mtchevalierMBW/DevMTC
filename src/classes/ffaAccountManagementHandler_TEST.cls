/*=======================================================================================
Name            : ffaAccountManagementHandler_TEST
Author          : CLD
Created Date    : Jan 2017
Description     : Contains test classes covering the account management handler!
Test			: ffaAccountManagementHandler
	2017-11-01	B. Leaman	BLL1 - too many soql queries. 
=======================================================================================*/
@isTest public class ffaAccountManagementHandler_TEST {
	static c2g__codaCompany__c testCompany;
    static Account testAccount;
    static c2g__codaJournal__c testJournal1;
    static c2g__codaTransactionLineItem__c testTransLine1;
    static c2g__codaDimension1__c dim1;
    static c2g__codaGeneralLedgerAccount__c testGLA;
    static ffaAccountManagementController testController;

	// BLL1a
	@testSetup private static void setupAllTests() {
		setupTestData();		
		testJournal1 = setupTestJournalWithAccount();
	}
	// BLL1a end
	
    public static void setupTestData(){
        testCompany = ffaTestUtilities.createFFACompany('ApexTestCompany', true, 'USD');
        testCompany = [SELECT Id, ownerid, Name FROM c2g__codaCompany__c LIMIT 1];
        testGLA = ffaTestUtilities.create_IS_GLA();
        c2g__codaAccountingCurrency__c testcurr = [SELECT id from c2g__codaAccountingCurrency__c where c2g__ownerCompany__c = :testCompany.id limit 1];
        system.debug('\n\n ***** ffaUtilities_TEST - setupTestData - testCompany' + testCompany);
        testAccount = ffaTestUtilities.createAccount('testAccount', testGLA.id);      
        testController = getSubject(testAccount);
        dim1 = ffaTestUtilities.createTestDimension1();

    }
    private static c2g__codaJournal__c setupTestJournalWithAccount(){
        c2g__codaJournal__c tmpJNL = ffaTestUtilities.createJNL(Date.today(), testGLA.id, 100, testCompany, testAccount.id);
        postSingleJournal(tmpJNL.id);
        return tmpJNL;
    }
    private static ffaAccountManagementController getSubject() {
        return getSubject(null, null);
    }
    private static ffaAccountManagementController getSubject(Account acct) {
        return getSubject(acct, null);
    }
    private static ffaAccountManagementController getSubject(Account acct, String tabParam) {
        test.setCurrentPage(Page.ffaAccountManagement);
        ffaAccountManagementController ctr = null;
        if (acct != null){
            ApexPages.currentPage().getParameters().put('id', acct.id);
            ApexPages.currentPage().getParameters().put('tab', tabParam != null ? tabParam : 'license-fee');
            ApexPages.StandardController stdController = new ApexPages.StandardController(acct);
            ctr = new ffaAccountManagementController(stdController);
        }
        else
        {
            ctr = new ffaAccountManagementController();
        }
        return ctr;
    }
    private static ffaAccountManagementController.RecordModalHelper createModalHelper(c2g__codaTransactionLineItem__c transLine){
    	ffaAccountManagementController.RecordModalHelper helper = new ffaAccountManagementController.RecordModalHelper();
    	helper.inputDescription = 'test';
    	helper.selectedTransId = transLine.id;
    	helper.dateVal = date.today();
    	helper.inputAmountVal = 25;
    	helper.inputDateVal = date.today();
    	helper.sobjForAccountLookup = new c2g__codaJournalLineItem__c();
    	helper.sobjForAccountLookup.c2g__Account__c = testAccount.id;
    	return helper;
    }

    //============== TEST METHODS ====================
    @isTest static void testCashTransfer(){
        //BLL1d setupTestData();
		testAccount = ffaTestUtilities.getAccount('testAccount');	// BLL1a
		dim1 = ffaTestUtilities.getTestDimension1();	// BLL1a
Test.startTest();	// BLL1a

        testController = getSubject(); //test without account
        testController = getSubject(testAccount); //test without company

        //setup data
    	//BLL1d testJournal1 = setupTestJournalWithAccount();
    	testTransLine1 = [
        SELECT Id,
           Name,
           c2g__Account__c,
           c2g__AccountOutstandingValue__c,
           c2g__AccountValue__c,
           c2g__DocumentValue__c,
           c2g__DocumentOutstandingValue__c,
           c2g__LineDescription__c,
           c2g__LineNumber__c,
           c2g__MatchingStatus__c ,
           c2g__Transaction__c,
           c2g__LineReference__c,
           c2g__Dimension1__c,
           c2g__Dimension1__r.Name,
           c2g__transaction__r.Name,
           c2g__transaction__r.c2g__Period__c,
           c2g__transaction__r.c2g__Period__r.Name,
           c2g__transaction__r.c2g__TransactionDate__c,
           c2g__transaction__r.c2g__DocumentNumber__c,
           c2g__transaction__r.c2g__TransactionType__c,
           c2g__transaction__r.c2g__Year__c 
        FROM c2g__codaTransactionLineItem__c 
        WHERE c2g__linetype__c = 'Account' LIMIT 1];

        //various controller methods:
        testController.transferCreditTransactionModalFields = createModalHelper(testTransLine1);
        ffaAccountManagementController.TransLineItemWrapper testwrapper = new ffaAccountManagementController.TransLineItemWrapper(testTransLine1);
        testController.transferCreditTransactionModalFields.INPUT_AMOUNT = '1';
        testController.transferCreditTransactionModalFields.inputAmount = '1';
        testController.transferCreditTransactionModalFields.inputAmountVal = 1;
        testController.transferCreditTransactionModalFields.selectedTransId = testTransLine1.id;
        testController.transferCreditTransactionModalFields.sobjForAccountLookup.c2g__account__c = testAccount.id;
        testController.transferCreditTransactionModalFields.sobjForAccountLookup.c2g__dimension1__c = dim1.id;
    	List<ffaAccountManagementController.RecordModalHelper> testHelperList = new List<ffaAccountManagementController.RecordModalHelper>{testController.transferCreditTransactionModalFields};
        testController.saveNewTransfer();
        ffaAccountManagementController.TabControl tcontrol= new ffaAccountManagementController.TabControl();
        tcontrol.setReadMeTabSelected();
        tcontrol.setTransferCreditSelected();
        tcontrol.readMeTabItemClass = 'slds-active';
        tcontrol.transferCreditTabContentClass = 'slds-active';
        testController.showTransferCreditPanel();
        testController.addTransferCreditTransRow();
        testController.getPageController();
        testController.resetTransferCreditTransactionModalFieldList();
        testController.reLoadMoreTransferCreditTransactions();
        ffaAccountManagementController.RecordPaginator paginator = new ffaAccountManagementController.RecordPaginator();
        paginator.calcOffsets();

        //call the handler method:
    	ffaAccountManagementHandler.transferPayment(testHelperList, testTransLine1.id, 'ApexTestCompany');

        //testing getter /setters:
        testwrapper.id = '';
        System.debug(testwrapper.id);
        testwrapper.name = '';
        System.debug(testwrapper.name);
        testwrapper.transactionDate = date.today();
        System.debug(testwrapper.transactionDate);
        testwrapper.transactionStatus = '';
        System.debug(testwrapper.transactionStatus);
        testwrapper.checkNumber = '';
        System.debug(testwrapper.checkNumber);
        testwrapper.docNumber = '';
        System.debug(testwrapper.docNumber);
        testwrapper.dimension1Name = '';
        System.debug(testwrapper.dimension1Name);
        testwrapper.transactionId = '';
        System.debug(testwrapper.transactionId);
        testwrapper.transactionNumber = '';
        System.debug(testwrapper.transactionNumber);
        testwrapper.transactionAmount = 1;
        System.debug(testwrapper.transactionAmount);
        testwrapper.fullTransactionAmount = 1;
        System.debug(testwrapper.fullTransactionAmount);
        testwrapper.period = '';
        System.debug(testwrapper.period);
        testwrapper.periodName = '';
        System.debug(testwrapper.periodName);
        testwrapper.year = '';
        System.debug(testwrapper.year);
        testwrapper.lineDescription = '';
        System.debug(testwrapper.lineDescription);
        testwrapper.transactionOutstandingAmount = 1;
        System.debug(testwrapper.transactionOutstandingAmount);
Test.stopTest();	// BLL1a
    }

    @isTest static void testDebitTransfer(){
        //BLL1d setupTestData();
		testAccount = ffaTestUtilities.getAccount('testAccount');	// BLL1a
		dim1 = ffaTestUtilities.getTestDimension1();	// BLL1a
Test.startTest();	// BLL1a

        testController = getSubject(); //test without account
        testController = getSubject(testAccount); //test without company

        //setup data
        //BLL1d testJournal1 = setupTestJournalWithAccount();
        testTransLine1 = [
        SELECT Id,
           Name,
           c2g__Account__c,
           c2g__AccountOutstandingValue__c,
           c2g__AccountValue__c,
           c2g__DocumentValue__c,
           c2g__DocumentOutstandingValue__c,
           c2g__LineDescription__c,
           c2g__LineNumber__c,
           c2g__MatchingStatus__c ,
           c2g__Transaction__c,
           c2g__LineReference__c,
           c2g__Dimension1__c,
           c2g__Dimension1__r.Name,
           c2g__transaction__r.Name,
           c2g__transaction__r.c2g__Period__c,
           c2g__transaction__r.c2g__Period__r.Name,
           c2g__transaction__r.c2g__TransactionDate__c,
           c2g__transaction__r.c2g__DocumentNumber__c,
           c2g__transaction__r.c2g__TransactionType__c,
           c2g__transaction__r.c2g__Year__c 
        FROM c2g__codaTransactionLineItem__c 
        WHERE c2g__linetype__c = 'Account' LIMIT 1];

        //various controller methods:
        testController.transferDebitTransactionModalFields = createModalHelper(testTransLine1);
        ffaAccountManagementController.TransLineItemWrapper testwrapper = new ffaAccountManagementController.TransLineItemWrapper(testTransLine1);
        testController.transferDebitTransactionModalFields.INPUT_AMOUNT = '1';
        testController.transferDebitTransactionModalFields.inputAmount = '1';
        testController.transferDebitTransactionModalFields.inputAmountVal = 1;
        testController.transferDebitTransactionModalFields.selectedTransId = testTransLine1.id;
        testController.transferDebitTransactionModalFields.sobjForAccountLookup.c2g__account__c = testAccount.id;
        testController.transferDebitTransactionModalFields.sobjForAccountLookup.c2g__dimension1__c = dim1.id;
        List<ffaAccountManagementController.RecordModalHelper> testHelperList = new List<ffaAccountManagementController.RecordModalHelper>{testController.transferDebitTransactionModalFields};
        testController.saveNewTransferDebit();
        ffaAccountManagementController.TabControl tcontrol= new ffaAccountManagementController.TabControl();
        tcontrol.setReadMeTabSelected();
        tcontrol.setTransferDebitSelected();
        tcontrol.readMeTabItemClass = 'slds-active';
        tcontrol.transferDebitTabContentClass = 'slds-active';
        testController.showTransferDebitPanel();
        testController.addTransferDebitTransRow();
        testController.getPageController();
        testController.resetTransferDebitTransactionModalFieldList();
        testController.reLoadMoreTransferDebitTransactions();
        ffaAccountManagementController.RecordPaginator paginator = new ffaAccountManagementController.RecordPaginator();
        paginator.calcOffsets();

        //call the handler method:
        ffaAccountManagementHandler.transferPayment(testHelperList, testTransLine1.id, 'ApexTestCompany');

        //testing getter /setters:
        testwrapper.id = '';
        System.debug(testwrapper.id);
        testwrapper.name = '';
        System.debug(testwrapper.name);
        testwrapper.transactionDate = date.today();
        System.debug(testwrapper.transactionDate);
        testwrapper.transactionStatus = '';
        System.debug(testwrapper.transactionStatus);
        testwrapper.checkNumber = '';
        System.debug(testwrapper.checkNumber);
        testwrapper.docNumber = '';
        System.debug(testwrapper.docNumber);
        testwrapper.dimension1Name = '';
        System.debug(testwrapper.dimension1Name);
        testwrapper.transactionId = '';
        System.debug(testwrapper.transactionId);
        testwrapper.transactionNumber = '';
        System.debug(testwrapper.transactionNumber);
        testwrapper.transactionAmount = 1;
        System.debug(testwrapper.transactionAmount);
        testwrapper.fullTransactionAmount = 1;
        System.debug(testwrapper.fullTransactionAmount);
        testwrapper.period = '';
        System.debug(testwrapper.period);
        testwrapper.periodName = '';
        System.debug(testwrapper.periodName);
        testwrapper.year = '';
        System.debug(testwrapper.year);
        testwrapper.lineDescription = '';
        System.debug(testwrapper.lineDescription);
        testwrapper.transactionOutstandingAmount = 1;
        System.debug(testwrapper.transactionOutstandingAmount);

Test.stopTest();	// BLL1a

    }

    //============== HELPER METHODS ====================

    /*====================================================================
   	Method to post Journals - Note the journals should only relate to a single company
    ====================================================================*/
    public static List<c2g__codaJournal__c> postSingleJournal(Id journalid)
    {
        List<c2g__codaJournal__c> jnlList = [select id, c2g__OwnerCompany__r.name from c2g__codaJournal__c where id = :journalid];
        for(c2g__codaJournal__c jnl : jnlList)
        {
            c2g.CODAAPICommon_10_0.Context company = new c2g.CODAAPICommon_10_0.Context(); 
            company.CompanyName = jnl.c2g__OwnerCompany__r.name;
            company.Token = null;
            c2g.CODAAPICommon.Reference jnlRef = new c2g.CODAAPICommon.Reference();
            jnlRef.id = jnl.id;
            c2g.CODAAPIJournal_12_0.PostJournal(company, jnlRef); 
        }
        return jnlList;
    }
}