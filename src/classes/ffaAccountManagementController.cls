/*=======================================================================================
Name            : ffaAccountManagementController
Author          : CLD
Created Date    : August 2016
Description     : Contains server side logic for managing ffa accounts
=======================================================================================*/
public with sharing class ffaAccountManagementController
{
    public Account account {get; set;}
    public Boolean hasAccount {get; set;}

    // --- number of items pulled back by default, the user can increase/decrease per tabbed results
    public static final Integer DEFAULT_PAGING_LIMIT = 25;

    // Support notifications; these are used to render error or success elements on the page
    public Boolean hasPageError {get; set;}
    public String pageErrorMessage {get; set;}
    public Boolean hasPageSuccess {get; set;}
    public String pageSuccessMessage {get; set;}
    public String companyName {get; set;}

    // ----- Transfer Credit Payment Transactions Attributes --
    public RecordPaginator transferCreditTransactionPaginator {get; set;}
    public RecordModalHelper transferCreditTransactionModalFields {get; set;}
    public List<RecordModalHelper> transferCreditTransactionModalFieldList {get; set;}

    // ----- Transfer Debit Payment Transactions Attributes --
    public RecordPaginator transferDebitTransactionPaginator {get; set;}
    public RecordModalHelper transferDebitTransactionModalFields {get; set;}
    public List<RecordModalHelper> transferDebitTransactionModalFieldList {get; set;}

    // ------------------------------------------------------------------------
    // # Default constructor
    // # (support pages defined as a controller)
    // ------------------------------------------------------------------------
    public ffaAccountManagementController()
    {
        initialize();
    }

    // ------------------------------------------------------------------------
    // # Constructor for extending
    // # stdController - ApexPages.StandardController to extend
    // # (support pages defined as a standard controller extension)
    // ------------------------------------------------------------------------
    public ffaAccountManagementController(ApexPages.StandardController stdController)
    {
        initialize();
    }

    // ------------------------------------------------------------------------
    // sets everything up
    // ------------------------------------------------------------------------
    private void initialize()
    {
        hasPageSuccess = false;
        hasAccount = false;
        hasPageError = false;
        pageErrorMessage = '';
        pageSuccessMessage = '';
        companyName = '';

        // grab the account from the page param...
        String strAccountId = ApexPages.currentPage().getParameters().get('id');
        if (String.isEmpty(strAccountId))
        {
            addPageErrorMessage('Missing required account Id ');
            return ;
        }
        else
        {
            this.account = [select id, name from account where id =:strAccountId];
        }

        hasAccount = account != null;

        //check to make sure a single company is selected:
        List<c2g__codaCompany__c> companies = ffaUtilities.getCurrentCompanies();
        if(companies.isEmpty()){
        	addPageErrorMessage('Please select a current company before continuing');
            return ;
        }
        else if(companies.size()>1){
        	addPageErrorMessage('Payment transfers can only occur between a single company, please select a single current company to continue.');
            return;
        }
        else{
        	companyName = companies[0].Name;
        }

        // when we have an account, initialize our paginating lists, modal fields....
        if (hasAccount)
        {
            // setup tabs - based on page params..
            initializeTabControl();

            // instantiate our modal / popup container fields
            transferCreditTransactionModalFields = new RecordModalHelper(true);
            transferDebitTransactionModalFields = new RecordModalHelper(true);

            // instantiate and load our initial lists            
            loadMoreTransferCreditTransactions();
            loadMoreTransferDebitTransactions();

            //instantiate our transfer payment list and add a default line
            transferCreditTransactionModalFieldList = new List<RecordModalHelper>(); 
            transferCreditTransactionModalFieldList.add(transferCreditTransactionModalFields); 
            transferDebitTransactionModalFieldList = new List<RecordModalHelper>(); 
            transferDebitTransactionModalFieldList.add(transferDebitTransactionModalFields); 

        }
    }

    // ------------------------------------------------------------------------
    // Allows us to share this controller, and methods with apex components
    //
    // returns self
    // ------------------------------------------------------------------------
    public ffaAccountManagementController getPageController()
    {
        return this;
    }

    // contains logic for initializing rendering tabs in ui
    public TabControl tabPageControl {get; set;}

    // --
    // initializes the tab object
    // evaluates page parameters to determine
    // which tab to activate and show
    //
    // when page parameters includes tab (&tab=<value>)
    // - evaluates the value
    //      when its pay-trans activate pay trans tab
    // -
    private void initializeTabControl()
    {
        tabPageControl = new TabControl();

        try
        {
            String strTabVal = ApexPages.currentPage().getParameters().get('tab');

            if (String.isNotEmpty(strTabVal))
            {
                if (strTabVal == 'read-me')          { tabPageControl.setReadMeTabSelected(); }
                if (strTabVal == 'transfer-credit') { tabPageControl.setTransferCreditSelected(); }
                if (strTabVal == 'transfer-debit') { tabPageControl.setTransferCreditSelected(); }
            }
        }
        catch(Exception e)
        {
            system.debug('err ' + e);
        }

    }

    // --- define the option to allow for listing per page....
    public SelectOption[] listPerPageOptions {get{
        if (listPerPageOptions == null)
        {
            listPerPageOptions = new SelectOption[]{};
            for (String perOptVal : new String[]{
                '5',
                '10',
                '25',
                '50',
                '100'})
            {
                listPerPageOptions.add(new SelectOption(perOptVal, perOptVal));
            }
        }
        return listPerPageOptions;
        } set;}

    //// ----- Transfer Credit Transactions Attributes --
    public void loadMoreTransferCreditTransactions()
    {
        clearModalSettings();
        try

        {
            if (account != null && account.id != null)
            {
                // filter status
                Set<String> transferStatus = new Set<String>{
                    //'Matched',
                    'Available'
                };

                // get or instantiate our transfer transaction pagintaor
                transferCreditTransactionPaginator = transferCreditTransactionPaginator != null ? transferCreditTransactionPaginator : new RecordPaginator();

                // retrieve the write off transactions
                c2g__codaTransactionLineItem__c[] transItems = [
                    select Id,
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
                      from c2g__codaTransactionLineItem__c
                    where c2g__Account__c = :account.Id
                      and c2g__MatchingStatus__c in :transferStatus
                      and c2g__LineType__c = 'Account'
                      and c2g__Transaction__r.c2g__OwnerCompany__r.Name = :companyName
                      and Payment_Transferred__c = false
                      and c2g__AccountOutstandingValue__c < 0 //check to ensure only credits are returned
                    order by c2g__transaction__r.c2g__TransactionDate__c desc
                    limit :transferCreditTransactionPaginator.pagingLimit
                    offset :transferCreditTransactionPaginator.nextOffset
                ];

                // --- attempt to load total number when grabbing for first time...
                if (transItems != null &&
                    transferCreditTransactionPaginator.nextOffset == 0)
                {
                    // when we pull back less than paing limit, count is the number of records
                    if (transferCreditTransactionPaginator.pagingLimit >= transItems.size())
                    {
                        transferCreditTransactionPaginator.totalPaginationCount =   transItems.size();
                    }
                    // otherwise count the totals
                    else
                    {
                        // select count
                        AggregateResult[] countAr = [
                            select count(id)
                            from c2g__codaTransactionLineItem__c
                            where c2g__Account__c = :account.Id
                            and c2g__MatchingStatus__c in :transferStatus
                            and c2g__LineType__c = 'Account'
                            and Payment_Transferred__c = false];

                        if (countAr != null && countAr.size() > 0){
                            transferCreditTransactionPaginator.totalPaginationCount = Integer.valueOf(countAr[0].get('expr0'));
                        }
                    }
                }

                // - set the retrieved write off transactions
                transferCreditTransactionPaginator.marshalRecords(transItems);
            }
        }
        catch(Exception e)
        {
            addPageErrorMessage(e.getMessage());
        }
    }

    //// ----- Transfer Credit Transactions Attributes --
    public void loadMoreTransferDebitTransactions()
    {
        clearModalSettings();
        try

        {
            if (account != null && account.id != null)
            {
                // filter status
                Set<String> transferStatus = new Set<String>{
                    //'Matched',
                    'Available'
                };

                // get or instantiate our transfer transaction pagintaor
                transferDebitTransactionPaginator = transferDebitTransactionPaginator != null ? transferDebitTransactionPaginator : new RecordPaginator();

                // retrieve the write off transactions
                c2g__codaTransactionLineItem__c[] transItems = [
                    select Id,
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
                      from c2g__codaTransactionLineItem__c
                    where c2g__Account__c = :account.Id
                      and c2g__MatchingStatus__c in :transferStatus
                      and c2g__LineType__c = 'Account'
                      and c2g__Transaction__r.c2g__OwnerCompany__r.Name = :companyName
                      and Payment_Transferred__c = false
                      and c2g__AccountOutstandingValue__c > 0 //check to ensure only credits are returned
                    order by c2g__transaction__r.c2g__TransactionDate__c desc
                    limit :transferDebitTransactionPaginator.pagingLimit
                    offset :transferDebitTransactionPaginator.nextOffset
                ];

                // --- attempt to load total number when grabbing for first time...
                if (transItems != null &&
                    transferDebitTransactionPaginator.nextOffset == 0)
                {
                    // when we pull back less than paing limit, count is the number of records
                    if (transferDebitTransactionPaginator.pagingLimit >= transItems.size())
                    {
                        transferDebitTransactionPaginator.totalPaginationCount =   transItems.size();
                    }
                    // otherwise count the totals
                    else
                    {
                        // select count
                        AggregateResult[] countAr = [
                            select count(id)
                            from c2g__codaTransactionLineItem__c
                            where c2g__Account__c = :account.Id
                            and c2g__MatchingStatus__c in :transferStatus
                            and c2g__LineType__c = 'Account'
                            and Payment_Transferred__c = false];

                        if (countAr != null && countAr.size() > 0){
                            transferDebitTransactionPaginator.totalPaginationCount = Integer.valueOf(countAr[0].get('expr0'));
                        }
                    }
                }

                // - set the retrieved write off transactions
                transferDebitTransactionPaginator.marshalRecords(transItems);
            }
        }
        catch(Exception e)
        {
            addPageErrorMessage(e.getMessage());
        }
    }

    // ---------------------------------------------------------------
    // - reloads transfer credit transactions
    // - by specifying the page should reload the current offset!
    // ---------------------------------------------------------------
    public void reLoadMoreTransferCreditTransactions()
    {
      if (transferCreditTransactionPaginator != null)
      {
        // * set the next offset to the current offset to reload current offset listing
        transferCreditTransactionPaginator.nextOffset = transferCreditTransactionPaginator.currentOffset;

        // * reload
        loadMoreTransferCreditTransactions();
      }
    }

    // ---------------------------------------------------------------
    // - reloads transfer debit transactions
    // - by specifying the page should reload the current offset!
    // ---------------------------------------------------------------
    public void reLoadMoreTransferDebitTransactions()
    {
      if (transferDebitTransactionPaginator != null)
      {
        // * set the next offset to the current offset to reload current offset listing
        transferDebitTransactionPaginator.nextOffset = transferDebitTransactionPaginator.currentOffset;

        // * reload
        loadMoreTransferDebitTransactions();
      }
    }

// --- transfer credit transactions ---

    // ------------------------------------------------------------------------
    // - Action function when clicking the transfer button on the transfer
    //   payment transaction tab
    //
    // - Note page passes transId parameter of transferCreditTransactionModalFields container
    public void showTransferCreditPanel()
    {
        // clear any page errors
        clearPageErrorMessage();


        // initialize modal input fields and render modal window
        transferCreditTransactionModalFields.resetAndShow();
    }

    // ------------------------------------------------------------------------
    // - Action function when saving a new transfer payment
    //
    // - Note page passes transferCreditTransactionModalFields:
    // -        Input date
    // -        Input License Policy
    public void saveNewTransfer()
    {
        System.debug('ffaAccountManagementController.saveNewTransferPayment HIT!'); 
        System.debug('transferCreditTransactionModalFields.selectedTransId: ' + transferCreditTransactionModalFields.selectedTransId); 
        System.debug('transferCreditTransactionModalFields: ' + transferCreditTransactionModalFields); 
        System.debug('ffaAccountManagementController.transferCreditTransactionModalFieldList: ' + transferCreditTransactionModalFieldList); 

        // define the fields that should have user input
        Set<String> requiredNewCreditTransferFields = new Set<String>{
            transferCreditTransactionModalFields.INPUT_DATE,
            transferCreditTransactionModalFields.INPUT_ACCOUNT,
            transferCreditTransactionModalFields.INPUT_DIMENSION1
        };

        System.debug('ffaAccountManagementController.saveNewTransferPayment HIT!'); 

        // when the new transfer payment input data is valid, try to save a journal....
        if (transferCreditTransactionModalFields.isValid(requiredNewCreditTransferFields))
        {
            //Remove any rows from the transferCreditTransactionModalFields collection where amount is 0 or blank
            List<RecordModalHelper> finalModalList = new List<RecordModalHelper>(); 
            for (RecordModalHelper mh: transferCreditTransactionModalFieldList)
            {
                Decimal inputAmount = (mh.inputAmount == '' || mh.inputAmount == null) ? 0.00 : Decimal.valueOf(mh.inputAmount); 
                if (inputAmount != 0.00)
                {
                    finalModalList.add(mh); 
                }
            }

            Savepoint sp = Database.setSavepoint();
            try
            {
                //If for some reason we have an empty list of modal helper records to process, simply skip the transfer operation, hide the modal, and reload the transfer transactions
                if (!finalModalList.isEmpty())
                {
                    ffaAccountManagementHandler.transferPayment(finalModalList, transferCreditTransactionModalFields.selectedTransId, companyName);

                    // NOTE: Once journal successfully saved:
                    //       * close modal
                    //       * render page level success:
                    transferCreditTransactionModalFields.showModal = false;

                    // ** reload transfer transactions
                    loadMoreTransferCreditTransactions();

                    // add page success message
                    addPageSuccessMessage('Success: Cash Payment has been transferred');
                }
                else 
                {
                    System.debug('NO RECORDS WERE TRANSFERRED!'); 
                    transferCreditTransactionModalFields.showModal = false; 
                    reLoadMoreTransferCreditTransactions(); 
                }
            }
            catch(Exception e)
            {
                transferCreditTransactionModalFields.addModalError(e.getMessage());
                Database.rollback(sp);
                System.debug('ERROR = '+ e.getMessage()); 
                //ffaUtilities.createErrorLog(Datetime.now(), e.getMessage() + e.getStackTraceString(), 'Pending', null, 'ffaAccountManagementController - saveNewTransferPayment');
            }
        }
    }

    // ------------------------------------------------------------------------
    // - Action function when clicking the transfer button on the transfer
    //   debit transaction tab
    //
    // - Note page passes transId parameter of transferCreditTransactionModalFields container
    public void showTransferDebitPanel()
    {
        // clear any page errors
        clearPageErrorMessage();

        // initialize modal input fields and render modal window
        transferDebitTransactionModalFields.resetAndShow();
        System.debug('transferDebitTransactionModalFields - show modal = ' + transferDebitTransactionModalFields.showModal);
    }

    // ------------------------------------------------------------------------
    // - Action function when saving a new transfer payment
    //
    // - Note page passes transferCreditTransactionModalFields:
    // -        Input date
    // -        Input License Policy
    public void saveNewTransferDebit()
    {
        System.debug('ffaAccountManagementController.saveNewTransferDebit HIT!'); 
        System.debug('transferDebitTransactionModalFields.selectedTransId: ' + transferDebitTransactionModalFields.selectedTransId); 
        System.debug('transferDebitTransactionModalFields: ' + transferDebitTransactionModalFields); 
        System.debug('ffaAccountManagementController.transferCreditTransactionModalFieldList: ' + transferDebitTransactionModalFieldList); 

        // define the fields that should have user input
        Set<String> requiredNewDebitTransferFields = new Set<String>{
            transferDebitTransactionModalFields.INPUT_DATE,
            transferDebitTransactionModalFields.INPUT_ACCOUNT,
            transferDebitTransactionModalFields.INPUT_DIMENSION1
        };

        System.debug('ffaAccountManagementController.saveNewTransferDebit HIT!'); 

        // when the new transfer payment input data is valid, try to save a journal....
        if (transferDebitTransactionModalFields.isValid(requiredNewDebitTransferFields)){
            //Remove any rows from the transferDebitTransactionModalFields collection where amount is 0 or blank
            List<RecordModalHelper> finalModalList = new List<RecordModalHelper>(); 
            for (RecordModalHelper mh: transferDebitTransactionModalFieldList){
                Decimal inputAmount = (mh.inputAmount == '' || mh.inputAmount == null) ? 0.00 : Decimal.valueOf(mh.inputAmount); 
                if (inputAmount != 0.00){
                    finalModalList.add(mh); 
                }
            }

            Savepoint sp = Database.setSavepoint();
            try
            {
                //If for some reason we have an empty list of modal helper records to process, simply skip the transfer operation, hide the modal, and reload the transfer transactions
                if (!finalModalList.isEmpty())
                {
                    ffaAccountManagementHandler.transferPayment(finalModalList, transferDebitTransactionModalFields.selectedTransId, companyName);

                    // NOTE: Once journal successfully saved:
                    //       * close modal
                    //       * render page level success:
                    transferDebitTransactionModalFields.showModal = false;

                    // ** reload transfer transactions
                    loadMoreTransferDebitTransactions();

                    // add page success message
                    addPageSuccessMessage('Success: Debit Transaction has been transferred');
                }
                else 
                {
                    System.debug('NO RECORDS WERE TRANSFERRED!'); 
                    transferDebitTransactionModalFields.showModal = false; 
                    reLoadMoreTransferDebitTransactions(); 
                }
            }
            catch(Exception e)
            {
                transferDebitTransactionModalFields.addModalError(e.getMessage());
                Database.rollback(sp);
                System.debug('ERROR = '+ e.getMessage()); 
            }
        }
    }
  
    // ------------------------------------------------------------------------
    // - Action function when clicking the create credit button on the license
    //   fees tab
    //
    // - Note page passes transId parameter of credit modal container

    public void addTransferCreditTransRow()
    {
        RecordModalHelper newWrapper = new RecordModalHelper(true);
        transferCreditTransactionModalFieldList.add(newWrapper); 
    }

    public void resetTransferCreditTransactionModalFieldList()
    {
        System.debug('ffaAccountManagementController.resetTransferCreditTransactionModalFieldList HIT!'); 
        transferCreditTransactionModalFieldList = new List<RecordModalHelper>(); 
        RecordModalHelper newWrapper = new RecordModalHelper(true);
        transferCreditTransactionModalFieldList.add(newWrapper); 
    }

    // ------------------------------------------------------------------------
    // - Action function when clicking the create credit button on the license
    //   fees tab
    //
    // - Note page passes transId parameter of credit modal container

    public void addTransferDebitTransRow()
    {
        RecordModalHelper newWrapper = new RecordModalHelper(true);
        transferDebitTransactionModalFieldList.add(newWrapper); 
    }

    public void resetTransferDebitTransactionModalFieldList()
    {
        System.debug('ffaAccountManagementController.resetTransferDebitTransactionModalFieldList HIT!'); 
        transferDebitTransactionModalFieldList = new List<RecordModalHelper>(); 
        RecordModalHelper newWrapper = new RecordModalHelper(true);
        transferDebitTransactionModalFieldList.add(newWrapper); 
    }

    // # ------------------------------------------------------------------------
    // # resets all modal settings/pops to false/hidden
    private void clearModalSettings(){
        transferCreditTransactionModalFields.clearModal();
        transferDebitTransactionModalFields.clearModal();
    }

    // -- page alerts
    private void clearPageErrorMessage()
    {
        hasPageError = false;
        pageErrorMessage = '';

        hasPageSuccess = false;
        pageSuccessMessage = '';
    }

    private void addPageErrorMessage(String msg)
    {
        hasPageError = true;
        pageErrorMessage = msg;
    }

    private void addPageSuccessMessage(String msg)
    {
        hasPageSuccess = true;
        pageSuccessMessage = msg;
    }

    // --------
    // -- wrappers and helpers and field input containers....

    // ----------------------------------------------------------------------
    // # assist with paginating through results
    // # maintains records, offsets, paging limits.....
    // ----------------------------------------------------------------------
    public class RecordPaginator
    {
        // underlying records were paginating...
        //public List<Object> records {get; set;}

        public TransLineItemWrapper[] records {get;set;}

        public Boolean hasRecords {get{
                return records != null && records.size() > 0;
            } private set;}

        public Integer totalRecordsSize {get{
                return records != null ? records.size() : 0;
            } private set;}

        //ListOfMaps = (List<Object>)Json.deserializeUntyped(Json.serialize(listOfObjects));

        public Integer pagingLimit {get; set;}
        public Integer nextOffset {get; set;}
        public Integer lastOffset {get; set;}
        public Integer totalPaginationCount {get; set;}
        public Boolean hasMoreRecords {get; set;}
        public Boolean isFirst {get; set;}

        // define current offset based on next, last, paging limit....
        public Integer currentOffset { get{
            if (currentOffset == null) {
                currentOffset = (nextOffset > pagingLimit) ? nextOffset - pagingLimit : 0;
                currentOffset = currentOffset > 0 ? currentOffset : 0;
            }
            return currentOffset;
            } private set;}

        public RecordPaginator()
        {
            pagingLimit = DEFAULT_PAGING_LIMIT;

            nextOffset = 0;
            lastOffset = 0;
            totalPaginationCount = 0;
            hasMoreRecords = false;
            isFirst = true;

            records = new TransLineItemWrapper[]{};
        }

        // ----------------------------------------------------------------------
        // # Convenient method to write c2g__codaTransactionLineItem__c as
        // # recordpaginator records
        // #
        // ----------------------------------------------------------------------
        public void marshalRecords(c2g__codaTransactionLineItem__c[] transItems)
        {
            // reset
            records = new TransLineItemWrapper[]{};

            // determine if were looking at the first bunch
            // this will help drive the enable/disable logic of the next/last pagination buttons
            this.isFirst = this.nextOffset == 0;

            if (transItems != null && transItems.size() >0)
            {
                //records = (List<Object>)Json.deserializeUntyped(Json.serialize(sobjects));
                for (c2g__codaTransactionLineItem__c fee : transItems)
                {

                    records.add(new TransLineItemWrapper(fee));

                }

                // setup more record indicator, next and last offsets...
                this.calcOffsets();
            }
            else
            {
                this.hasMoreRecords = false;
            }
        }

        // ---
        // - sets indicator for more records, next, and last offsets
        public void calcOffsets()
        {
            if (this.nextOffset > 0)
            {
                this.lastOffset = this.nextOffset - this.pagingLimit;

                // no need to look up negative ones....you know....
                this.lastOffset  = lastOffset >= 0 ? lastOffset : 0;
            }

            this.nextOffset += records.size();
            this.hasMoreRecords = (records.size() == this.pagingLimit);
        }
    }

    // ------------------------------
    // - represents the data to display
    // -
    public class TransLineItemWrapper
    {
        public Boolean selected {get;set;}
        public c2g__codaTransactionLineItem__c lineItem {get; set;}

        // convenient for rendering on screens
        public String id {
            get {return lineItem != null ? lineItem.id : null;  } public set;
        }
        public String name {
            get {return lineItem != null ? lineItem.name : null;} public set;
        }
        public Date transactionDate {
            get{return lineItem != null ? lineItem.c2g__transaction__r.c2g__TransactionDate__c : null;} public set;
        }
        public String transactionDateFormatted {
            get{return getFormatDate(transactionDate);} public set;
        }
        public String transactionStatus {
            get{return lineItem != null ? lineItem.c2g__MatchingStatus__c : null;} public set;
        }
        public String checkNumber {
            get{return lineItem != null ? lineItem.c2g__LineReference__c : null;} public set;
        }
        public String docNumber {
            get{return lineItem != null ? lineItem.c2g__transaction__r.c2g__DocumentNumber__c : null;} public set;
        }
        public String dimension1Name {
            get{return lineItem != null ? lineItem.c2g__Dimension1__r.Name : null;} public set;
        }
        public String transactionId { get{
            return lineItem != null ? lineItem.c2g__Transaction__c : null;} public set;
        }
        public String transactionNumber {
            get{return lineItem != null ? lineItem.c2g__transaction__r.Name : null;} public set;
        }
        public Decimal transactionAmount {
            get{return lineItem != null ? lineItem.c2g__DocumentOutstandingValue__c : null;} public set;
        }
        public Decimal fullTransactionAmount {
            get{return lineItem != null ? lineItem.c2g__DocumentValue__c : null;} public set;
        }
        public String period {
            get{return lineItem != null ? lineItem.c2g__transaction__r.c2g__Period__c : null;} public set;
        }
        public String periodName {
            get{return lineItem != null ? lineItem.c2g__transaction__r.c2g__Period__r.Name : null;} public set;
        }
        public String year {
            get{return lineItem != null ? lineItem.c2g__transaction__r.c2g__Year__c : null;} public set;
        }
        public String lineDescription {
            get{ return lineItem != null ? lineItem.c2g__LineDescription__c : null;} public set;
        }
        public Decimal transactionOutstandingAmount {
            get{ return lineItem != null ? lineItem.c2g__AccountOutstandingValue__c : null;} public set;
        }

        public TransLineItemWrapper(c2g__codaTransactionLineItem__c input)
        {
            this.selected = false;
            this.lineItem = input;
        }

        private String getFormatDate(Date transDate)
        {
            transDate = transDate == null ? null : transDate;
            if(transDate!= null){
                return DateTime.newInstance(transDate.year(),transDate.month(),transDate.day()).format('MMM d, yyyy');    
            }
            else{
                return null;
            }
        }


    }
/*
    public class RecordModalHelper

    new RecordModalHelper(new Set<String>{RecordModalHelper.INPUT_DESCRIPTION, 'inputDate', 'inputPeriod'})


*/
    public class RecordModalHelper
    {
        // used for defining required fields on isValid...
        // when required field set contains one, it will be required
        public String INPUT_DESCRIPTION       = 'inputDescription';
        public String INPUT_DATE              = 'inputDate';
        public String INPUT_AMOUNT            = 'inputAmount';
        public String INPUT_PERIOD            = 'inputPeriod';

        public String INPUT_ORIG_TRANS_NUMBER = 'originalTransactionNumber';
        public String INPUT_ACCOUNT           = 'inputAccount';
        public String INPUT_DIMENSION1        = 'inputDimension1';



        // - this is the field the ui will pass when clicking the create credit button
        // - and when saving
        public String selectedTransId {get; set;}
        public Decimal selectedTransAmount {get; set;}
        public String selectedTransLineReference {get; set;}

        // -- These are the fields used by various UI modal popup forms,
        public String inputDescription {get; set;}
        public String inputDate {get; set;}
        public String inputAmount {get; set;}

        public String inputPeriod {get; set;}

        // -- These are the fields the UI will pass when creating transfer
        public String originalTransactionNumber {get; set;}

        // this will be used to lookup an Account
        public c2g__codaJournalLineItem__c sobjForAccountLookup {get; set;}

        // -- transformed...
        public Date dateVal {get; set;}
        public Decimal amountVal {get; set;}

        // --- attributes for maintaining the new credit memo popup
        public Boolean showModal  {get; set;}
        public Boolean hasModalError {get; set;}
        public String modalErrMsg    {get; set;}

        public RecordModalHelper()
        {
            this.selectedTransId = '';
            this.selectedTransAmount = 0.00; 
            this.selectedTransLineReference = ''; 
            this.reset(false);
        }

        // triggers rendering a helper with sobjForAccountLookup defined.
        public RecordModalHelper(boolean advanced)
        {
            supportsSobj = advanced;

            this.selectedTransId = '';
            this.selectedTransAmount = 0.00; 
            this.selectedTransLineReference = ''; 
            this.reset(false);
        }

        // determines if we should initialize and reset various sobjs for input
        private boolean supportsSobj = false;

        // reset various fields used for input
        public void reset(Boolean andShow)
        {
            this.showModal        = andShow;
            this.hasModalError    = false;
            this.modalErrMsg      = '';

            //transDate = transDate == null ? Date.today() : transDate;
            //

            this.inputDescription = '';
            //this.inputDate        = '' + Date.today();

            setInputDate(Date.today());

            this.inputAmount      = '0';
            this.inputPeriod      = '';

            if (this.supportsSobj)
            {
                //this.sobjForAccountLookup      = new Payment_Transaction_Detail__c(Account__c = null);
                this.sobjForAccountLookup      = new c2g__codaJournalLineItem__c(c2g__Account__c = null);
                this.originalTransactionNumber = '';
            }
        }

        // --- convenient method for setting the input date
        public void setInputDate(Date dateIn)
        {
          if (dateIn != null)
          {
            inputDate = DateTime.newInstance(dateIn.year(),dateIn.month(),dateIn.day()).format('yyyy-MM-dd');
          }
        }

        public void clearModal()
        {
            reset(false);
        }

        public void resetAndShow()
        {
            reset(true);
        }

        // sets the modal error message to display
        public void addModalError(String errMsg)
        {
            this.hasModalError = true;
            this.modalErrMsg = errMsg;
        }

        // parsed input date
        public Date inputDateVal {get; set;}

        // parse input amount
        public Decimal inputAmountVal{get; set;}

/*
    isValid(new <Set>String{RecordModalHelper.inputDescription})

    requiredFields.containsKey('inputDescription')
*/
        //--
        // determines if the record is valid
        // requiredFields - collection of fields names that should be set
        //
        public boolean isValid(Set<String> requiredFields)
        {
            AccountManagmentHelper helper = new AccountManagmentHelper();

            // clear the panel error hanling
            this.hasModalError = false;
            this.modalErrMsg = '';

            inputDateVal = inputDate != null && inputDate != '' ? helper.getValueOfSafeDate(inputDate) : null;
            inputAmountVal = inputAmount != null && inputAmount != '' ? helper.getValueOfSafeDecimal(inputAmount) : null;

            // verify we have a selected trans id...
            if (String.isEmpty(selectedTransId))
            {
                modalErrMsg += ' Missing required license fee id. ';
            }

            // verify required fields are present
            if (requiredFields.contains(INPUT_DESCRIPTION) && String.isEmpty(inputDescription))
            {
                modalErrMsg += ' Missing required input description. ';
            }
            if (requiredFields.contains(INPUT_DATE) && inputDateVal == null)
            {
                modalErrMsg += ' Missing required input date. ';
            }
            if (requiredFields.contains(INPUT_PERIOD) && String.isEmpty(inputPeriod))
            {
                modalErrMsg += ' Missing required input period. ';
            }

            if (requiredFields.contains(INPUT_AMOUNT) && inputAmountVal == null)
            {
                modalErrMsg += ' Missing required input amount. ';
            }

            if (requiredFields.contains(INPUT_AMOUNT) && inputAmountVal == 0)
            {
                modalErrMsg += ' Input Amount cannot be zero. ';
            }

            // verify we have an account selected
            /*if (requiredFields.contains(INPUT_ACCOUNT) &&
                (sobjForAccountLookup == null || sobjForAccountLookup.c2g__Account__c == null))
            {
                modalErrMsg += ' Missing required Account. ';
            }

            // verify we have a license policy selected
           	if (requiredFields.contains(INPUT_DIMENSION1) &&
                (sobjForAccountLookup == null || sobjForAccountLookup.c2g__Dimension1__c == null))
            {
                modalErrMsg += ' Missing required Dimension 1';
            }*/
            

            // original transaction number
            if (requiredFields.contains(INPUT_ORIG_TRANS_NUMBER) && String.isEmpty(originalTransactionNumber))
            {
                modalErrMsg += ' Missing required original transaction number. ';
            }


            this.hasModalError = String.isNotEmpty(modalErrMsg);

            // valid when no modal errors
            return !hasModalError;
        }
    }

    // --
    //  Contains helper methods for parsing values from strings
    public class AccountManagmentHelper
    {
        // --- convenient method to attempt to parse a date string like 'YYYY-MM-DD'
        public Date getValueOfSafeDate(String inputDate)
        {
            try
            {
                return Date.valueOf(inputDate);
            }
            catch(Exception e)
            {
                system.debug('err ??' + e);
                return null;
            }
        }

        // --- convenient method to attempt to parse a string into a decimal
        public Decimal getValueOfSafeDecimal(String inputDecimal)
        {
            try
            {
                return Decimal.valueOf(inputDecimal);
            }
            catch(Exception e)
            {
                system.debug('err ??' + e + 'stack trace' + e.getStackTraceString() + 'input value = '+inputDecimal);
                return null;
            }
        }
    }

    // ---
    // - contains convenient logic for rendering selected tabs and what not
    public class TabControl
    {
        // read me
        public boolean readMeTabSelected {get; set;}
        public String readMeTabItemClass {get{return readMeTabSelected ? 'slds-active' : '';} set;}
        public String readMeTabContentClass {get{return readMeTabSelected ? 'slds-show' : 'slds-hide'; } set;}

        // transfer credit trans
        public boolean transferCreditTabSelected {get; set;}
        public String transferCreditTabItemClass {get{return transferCreditTabSelected ? 'slds-active' : '';} set;}
        public String transferCreditTabContentClass {get{return transferCreditTabSelected ? 'slds-show' : 'slds-hide'; } set;}

        // transfer debit trans
        public boolean transferDebitTabSelected {get; set;}
        public String transferDebitTabItemClass {get{return transferDebitTabSelected ? 'slds-active' : '';} set;}
        public String transferDebitTabContentClass {get{return transferDebitTabSelected ? 'slds-show' : 'slds-hide'; } set;}

        public TabControl()
        {
            readMeTabSelected      = true;
            transferCreditTabSelected = false;
            transferDebitTabSelected = false;
        }

        public void setReadMeTabSelected()
        {
            closeAllTabs();
            readMeTabSelected = true;
        }

        public void setTransferCreditSelected()
        {
            closeAllTabs();
            transferCreditTabSelected = true;
        }
        public void setTransferDebitSelected()
        {
            closeAllTabs();
            transferDebitTabSelected = true;
        }

        // convient method to indicate all tabs are closed when setting a specific tab
        private void closeAllTabs()
        {
            readMeTabSelected      = false;
            transferCreditTabSelected = false;
            transferDebitTabSelected = false;
        }
    }
}