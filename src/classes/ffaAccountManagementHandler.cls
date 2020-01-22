/*=======================================================================================
Name            : ffaAccountManagementHandler
Author          : CLD
Created Date    : August 2016
Description     : Contains the methods for processing records from the ffaAccountManagementController
=======================================================================================*/
public class ffaAccountManagementHandler {
	
	/*=======================================================================================
	Name            : transferPayment
	Description     : Optionally unmatches a cash transaction, creates and posts a transfer, then re-matches the transfer
	Param           : RecordModalHelper from the ffaAccountManagerController
	=======================================================================================*/	
	public static void transferPayment(List<ffaAccountManagementController.RecordModalHelper> pageModals, Id sourceTLIID, String companyName){
		system.debug('\n\n ****** ffaAccountManagementHandler - transferPayment - pageModals = '+pageModals);
		Id targetAccountId = null;
		Date processDate;

		Final String COMPANY_NAME = Test.isRunningTest() == false ? companyName : 'ApexTestCompany';

		List<c2g__codaJournalLineItem__c> jnlLineList = new List<c2g__codaJournalLineItem__c>();
		Map<String, c2g__codaJournal__c> journalMap = new Map<String, c2g__codaJournal__c>(); //key is the journal date string

		c2g.CODAAPICommon_8_0.Context companyWrapper = new c2g.CODAAPICommon_8_0.Context();
		companyWrapper.CompanyName = COMPANY_NAME;

		c2g__codaTransactionLineItem__c sourceTLI;
		if(sourceTLIID != null){
			sourceTLI = [SELECT Id,
				c2g__Account__c,
				c2g__HomeValue__c,
				c2g__DocumentValue__c,
				c2g__LineReference__c,
				c2g__GeneralLedgerAccount__c,
				c2g__Dimension1__c,
				c2g__Transaction__r.c2g__ownerCompany__c,
				c2g__Transaction__r.c2g__ownerCompany__r.ownerid,
				c2g__DocumentCurrency__c,
				c2g__MatchingStatus__c,
				SystemModStamp,
				(SELECT id,
					c2g__MatchingReference__c
					FROM c2g__CashMatchingHistories__r
					WHERE c2g__MatchingReference__c != null
					AND c2g__Action__c = 'Match'
					AND c2g__UndoMatchingReference__c = null)
			FROM c2g__codaTransactionLineItem__c
			WHERE id = :sourceTLIID];
		}

		//Step 1: Undo an existing matches:
		/*if(sourceTLI.c2g__CashMatchingHistories__r.size()>0){

			//setup the cash matching wrappers:
			Map<Date,Id> periodMap = ffaUtilities.getAccountingPeriods(COMPANY_NAME);
			c2g.CODAAPICashMatchingTypes_8_0.Configuration unmatchConfig = new c2g.CODAAPICashMatchingTypes_8_0.Configuration();
			unmatchConfig.MatchingDate = Date.today();
			unmatchConfig.MatchingCurrencyMode = c2g.CODAAPICashMatchingTypes_8_0.enumMatchingCurrencyMode.Document;
			
			c2g.CODAAPICommon.Reference accountWrapper = new c2g.CODAAPICommon.Reference();
			accountWrapper.id = sourceTLI.c2g__Account__c;
			unmatchConfig.Account = accountWrapper;

			c2g.CODAAPICommon.Reference periodWrapper = new c2g.CODAAPICommon.Reference();
			periodWrapper.id = periodMap.get(Date.today().tostartofmonth());
			unmatchConfig.MatchingPeriod = periodWrapper;

			for(c2g__codaCashMatchingHistory__c cmh : sourceTLI.c2g__CashMatchingHistories__r){
				c2g.CODAAPICommon.Reference unmatchWrapper = new c2g.CODAAPICommon.Reference();
				unmatchWrapper.id = cmh.c2g__MatchingReference__c;

				c2g.CODAAPICommon.Reference output = c2g.CODAAPICashMatching_8_0.Unmatch(companyWrapper, unmatchConfig, unmatchWrapper,c2g.CODAAPICashMatchingTypes_8_0.enumUndoReason.RemittanceAdviceIncorrect);
			}
		}*/


		//Step 2: Create and post the Transfer Journals:
		for(ffaAccountManagementController.RecordModalHelper pageModal : pageModals){
			processDate = pageModal.inputDateVal != null ? pageModal.inputDateVal : Date.today();
			String journalMapKey = pageModal.inputDateVal != null ? pageModal.inputDateVal.format() : Date.today().format();
			Decimal pageValue = Decimal.valueOf(pageModal.inputAmount).setScale(2);
			Decimal negPageValue = pageValue*-1;
			String transferType = sourceTLI.c2g__DocumentValue__c > 0 ? 'Debit' : 'Credit';

			if(!journalMap.containsKey(journalMapKey)){
				c2g__codaJournal__c newJournal = new c2g__codaJournal__c(
			 	ownerid = sourceTLI.c2g__Transaction__r.c2g__ownerCompany__r.ownerid,
			 	c2g__Reference__c = transferType == 'Debit' ? 'Invoice Transfer' : 'Payment Transfer',
				c2g__ownerCompany__c = sourceTLI.c2g__Transaction__r.c2g__ownerCompany__c,
				c2g__JournalDescription__c = pageModal.inputDescription != null ? pageModal.inputDescription: null,
				c2g__JournalDate__c = pageModal.inputDateVal != null ? pageModal.inputDateVal : Date.today(),
				c2g__JournalCurrency__c = sourceTLI.c2g__DocumentCurrency__c,
				c2g__DerivePeriod__c = true);
				journalMap.put(journalMapKey, newJournal);
			}
			
			//this is the write off of the existing jnl
			c2g__codaJournalLineItem__c jnlLine1 = new c2g__codaJournalLineItem__c(
				c2g__LineType__c = 'Account - Customer',
				c2g__Account__c = sourceTLI.c2g__Account__c,
				Utility_Id__c = journalMapKey,
				c2g__Value__c = transferType == 'Debit' ? negPageValue : pageValue,
				c2g__LineDescription__c = pageModal.inputDescription != null ? pageModal.inputDescription: null,
				c2g__GeneralLedgerAccount__c = sourceTLI.c2g__GeneralLedgerAccount__c,
				c2g__Dimension1__c = sourceTLI.c2g__Dimension1__c != null ? sourceTLI.c2g__Dimension1__c : null,
				c2g__DeriveLineNumber__c = true);
			jnlLineList.add(jnlLine1);

			//this is the transfer to new Account
			c2g__codaJournalLineItem__c jnlLine2 = new c2g__codaJournalLineItem__c(
				c2g__LineType__c = 'Account - Customer',
				c2g__Account__c = pageModal.sobjForAccountLookup.c2g__Account__c,
				Transferred_From_Account__c = sourceTLI.c2g__Account__c != null ? sourceTLI.c2g__Account__c : null,
				Transferred_From_Transaction__c = sourceTLI.Id != null ? sourceTLI.Id : null,
				Utility_Id__c = journalMapKey,
				c2g__Value__c = transferType == 'Debit' ? pageValue : negPageValue,
				c2g__LineDescription__c = pageModal.inputDescription != null ? pageModal.inputDescription: null,				
				c2g__GeneralLedgerAccount__c = sourceTLI.c2g__GeneralLedgerAccount__c,
				c2g__Dimension1__c = pageModal.sobjForAccountLookup.c2g__Dimension1__c != null ? pageModal.sobjForAccountLookup.c2g__Dimension1__c : null,
				c2g__DeriveLineNumber__c = true);
			jnlLineList.add(jnlLine2);
		}

		//DML - Error handling is done at the controller level
		insert journalMap.values();
		for(c2g__codaJournalLineItem__c jnlLine : jnlLineList){
			jnlLine.c2g__Journal__c = journalMap.containsKey(jnlLine.Utility_Id__c) ? journalMap.get(jnlLine.Utility_Id__c).id : null;
		}
		insert jnlLineList;
		List<Id> jnlIdList = new List<Id>();
		for(c2g__codaJournal__c jnl : journalMap.values()){
			jnlIdList.add(jnl.Id);
		}
		ffaUtilities.postJournals(jnlIdList);

		//Step 3: Match the old transferred transactions together:
		List<c2g.CODAAPICashMatchingTypes_8_0.Item> matchingItemList = new List<c2g.CODAAPICashMatchingTypes_8_0.Item>();
		List<c2g__codaTransactionLineItem__c> jnlTransLines = [SELECT Id, c2g__AccountOutstandingValue__c, SystemModStamp, c2g__Transaction__r.c2g__TransactionDate__c
            FROM c2g__codaTransactionLineItem__c
            WHERE c2g__Transaction__r.c2g__Journal__c in :jnlIdList
            AND c2g__Account__c = :sourceTLI.c2g__Account__c
            AND c2g__Dimension1__c = :sourceTLI.c2g__Dimension1__c
            AND c2g__LineType__c = 'Account'];

        Decimal totalMatchOffset = 0;

        for(c2g__codaTransactionLineItem__c jnlTransLine : jnlTransLines){
        	//get the appropriate amount to match from either lesser of the two amounts.
	        Decimal amountToMatch = jnlTransLine.c2g__AccountOutstandingValue__c;

			//create matching wrapper for the transaction line item from the JNL
			c2g.CODAAPICommon.Reference jnlTransWrapper = new c2g.CODAAPICommon.Reference();
	        jnlTransWrapper.Id = jnlTransLine.id;

	        c2g.CODAAPICashMatchingTypes_8_0.Item jnlWrapper = new c2g.CODAAPICashMatchingTypes_8_0.Item();
	        jnlWrapper.Paid = amountToMatch;
	        jnlWrapper.TransactionLineItem = jnlTransWrapper;
	        jnlWrapper.TransactionLineItemSystemModStamp = jnlTransLine.SystemModStamp;
	        matchingItemList.add(jnlWrapper);

	        totalMatchOffset += amountToMatch;
        }
    
        c2g.CODAAPICommon.Reference sourceTransWrapper = new c2g.CODAAPICommon.Reference();
        sourceTransWrapper.Id = sourceTLI.id;

        c2g.CODAAPICashMatchingTypes_8_0.Item sourceWrapper = new c2g.CODAAPICashMatchingTypes_8_0.Item();
        sourceWrapper.Paid = totalMatchOffset*-1; //the sum of all the lines needs to match.
        sourceWrapper.TransactionLineItem = sourceTransWrapper;
        sourceWrapper.TransactionLineItemSystemModStamp = sourceTLI.SystemModStamp;
        matchingItemList.add(sourceWrapper);
        
        system.debug('\n\n ****** ffaAccountManagementHandler - transferPayment - matchingItemList = '+matchingItemList);
        system.debug('\n\n ****** ffaAccountManagementHandler - transferPayment - matchingItemList size = '+matchingItemList.size());

        //create the remaining api wrappers as necessary per FF documentation
        c2g.CODAAPICommon_8_0.Context companyContext = new c2g.CODAAPICommon_8_0.Context();
        companyContext.CompanyName = COMPANY_NAME;

        c2g.CODAAPICommon.Reference accountWrapper = new c2g.CODAAPICommon.Reference();
        accountWrapper.Id = sourceTLI.c2g__Account__c;

        c2g.CODAAPICashMatchingTypes_8_0.Configuration matchingConfig = new c2g.CODAAPICashMatchingTypes_8_0.Configuration();
        matchingConfig.Account = accountWrapper;
        matchingConfig.MatchingCurrencyMode = c2g.CODAAPICashMatchingTypes_8_0.enumMatchingCurrencyMode.Document;
        matchingConfig.MatchingDate = processDate;

        c2g.CODAAPICashMatchingTypes_8_0.Analysis matchingAnalysis = new c2g.CODAAPICashMatchingTypes_8_0.Analysis(); //not expecting any write offs or discounts.

        //DML
        if(!matchingItemList.isEmpty()){
	        system.debug(' ***ffaAccountManagementHandler*** VARIABLES BEFORE MATCH *******');
	        system.debug(' ***ffaAccountManagementHandler***  companyContext = '+companyContext);
	        system.debug(' ***ffaAccountManagementHandler***  matchingConfig = '+matchingConfig);
	        system.debug(' ***ffaAccountManagementHandler***  matchingItemList = '+matchingItemList);
	        system.debug(' ***ffaAccountManagementHandler***  matchingAnalysis = '+matchingAnalysis);
	        system.debug(' ***ffaAccountManagementHandler*** VARIABLES BEFORE MATCH *******');
	        c2g.CODAAPICommon.Reference outputMatchingRef = Test.isRunningTest() == false ? c2g.CODAAPICashMatching_8_0.Match(companyContext,matchingConfig,matchingItemList,matchingAnalysis) : null;
        }

        //Step 4: Update the source transaction line item to mark Payment Transferred = TRUE - Only if it's been fully matched
        sourceTLI = [SELECT Id,
        		Payment_Transferred__c,
				c2g__MatchingStatus__c			
			FROM c2g__codaTransactionLineItem__c
			WHERE id = :sourceTLIID];

        sourceTLI.Payment_Transferred__c = sourceTLI.c2g__MatchingStatus__c == 'Matched' ? true : false;
        update sourceTLI;
	}

}