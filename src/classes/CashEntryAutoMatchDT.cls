/**
 CashEntryAutoMatchDT
 Tested by: CashEntryAutoMatchDT_TEST
 Date: 2019-04-09
 Programmer: Bryan Leaman
 Project: W-000575
 
 Description:
 Find all open, auto-matchable cash entry lines by customer and document (Account & Dimension1 & Control#)
 Search for all open A/R matching the customer & document (Account & Dimension1 & Control#).
 (magic) Perform cash match on the lines:
  - Allow for automatic write-offs
  - If there are multiple cash entries, net them out -- they may be refunds/reversals that simply
    clear off without a change to A/R.
Report via emailed csv on matching:
	Matching Reference, Matching History, Transaction Line, Dimension1, Account, Amount

 Coverage:
 2019-05-02	94% (242/256)
 
 Modifications: 
	2019-06-19	W-000575 impl BLL1 - need to separate matching requests by GL account as well as control#, account & dimension1
	2019-07-23	W-000724 BLL2 - adjust reset account dimension1 for writeoff to set back to null.

 Run it now:
Database.executeBatch(new CashEntryAutoMatchDT(null, true, null, null, null, null),1);

Set standard schedule:
CashEntryAutoMatchDT.scheduleMe();

Set custom schedule:
System.schedule('CashEntryAutoMatchDT', 'sec min hr day mth wd year', new CashEntryAutoMatchDT(null,true, null, null, null, null));

 */
 global class CashEntryAutoMatchDT implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

	global boolean doUpdate;
	global String recordLimit;
	global Map<Integer,String> errormap;
	global Map<Integer,String> resultmap;
	public static final List<String> CRON_LIST = new List<String>{
		'0 0 5 * * ? *' 	// 5 a.m. daily
	};
	global MobilityForceSettings__c mfs;
	global c2g__codaGeneralLedgerAccount__c writeoffGL;

	global Id currentcompany;
	global List<Id> remainingCompanyIds;
	global Map<Id, List<String>> storeMatchingReport;
	global Organization org;
	// BLL1
	global Integer matchingGroupNbr;
	// BLL1

	// CashEntryAutoMatchDT constructor - generate query string & initialize
	global CashEntryAutoMatchDT(String rcdlimit, boolean doUpd, List<Id> companyidlist, Map<Integer, String> results, Map<Integer, String> errors, Map<Id,List<String>> storerpt) {
		System.debug('CashEntryAutoMatchDT.constructor');
		mfs = MobilityForceSettings__c.getOrgDefaults();
		if (mfs!=null && !String.isBlank(mfs.Writeoff_GL_Acct__c) && mfs.Writeoff_Overpayment__c!=null && mfs.Writeoff_Underpayment__c!=null) {
			writeoffGL = [select Id, Name, c2g__ReportingCode__c, c2g__ExternalId__c from c2g__codaGeneralLedgerAccount__c where c2g__ExternalId__c=:mfs.Writeoff_GL_Acct__c limit 1];
		}
		doUpdate = doUpd;

		recordLimit = rcdlimit;
		errormap = new Map<Integer, String>();
		resultmap = new Map<Integer, String>();
		storeMatchingReport = new Map<Id, List<String>>();
		if (storerpt!=null) storeMatchingReport = storerpt;
		// BLL1
		matchingGroupNbr = 0;
		for(List<String> smr : storeMatchingReport.values()) matchingGroupNbr += smr.size();
		// BLL1 end

		// continuing from last batch instance ...
		if (errors!=null) errormap = errors;
		if (results!=null) resultmap = results;

		// starting fresh for all companies or continuing on?
		if (companyidlist==null) {
			remainingCompanyIds = new List<String>();
			for(AggregateResult ar : [
				Select c2g__OwnerCompany__c
				from c2g__codaTransactionLineItem__c 
				where c2g__LineType__c = 'Account'
				  and c2g__AccountOutstandingValue__c!=0 
				  and c2g__MatchingStatus__c='Available' 
				  and c2g__Transaction__r.c2g__CashEntry__c!=null 
				  and c2g__Transaction__r.c2g__CashEntry__r.AutoMatchCash__c=true 
				group by c2g__OwnerCompany__c
			]) {
				System.debug(ar);
				remainingCompanyIds.add((Id) ar.get('c2g__OwnerCompany__c'));
			}
		} else {
			remainingCompanyIds = new List<Id>(companyidlist);
		}

		System.debug(remainingCompanyIds.size());
		if (remainingCompanyIds.size()>0) currentcompany = remainingCompanyIds.remove(0);
		System.debug(currentcompany);
		System.debug(remainingCompanyIds.size());

	}


	// start - query the database
	//global Database.QueryLocator start(Database.BatchableContext bc) {
	//	System.debug(query);
	//	return Database.getQueryLocator(query);
	//}
	global Iterable<sObject> start(Database.BatchableContext bc) {
		System.debug('CashEntryAutoMatchDT.start');
		List<AggregateResult> rcds = new List<AggregateResult>();
		if (currentcompany!=null) {
			System.debug('selectCompany: ' + currentcompany);
			FinancialForce_MBW.selectCompany(currentcompany);
			System.debug('selectCompany: ' + currentcompany + ' completed');
			// Query open, auto-matchable cash entries by Company, Account, Dimension, Document (Control#)
			String soql = 
				'Select c2g__OwnerCompany__c, c2g__Account__c, c2g__Dimension1__c, Control__c, c2g__GeneralLedgerAccount__c, '	// BLL1c
				+ '	count(Id) cnt, sum(c2g__AccountOutstandingValue__c) opennval '
				+ 'from c2g__codaTransactionLineItem__c '
				+ 'where c2g__LineType__c = \'Account\' '
				+ '  and c2g__AccountOutstandingValue__c!=0 '
				+ '  and c2g__MatchingStatus__c=\'Available\' '
				+ '  and c2g__Transaction__r.c2g__CashEntry__c!=null '
				+ '  and c2g__Transaction__r.c2g__CashEntry__r.AutoMatchCash__c=true '
				+ '  and c2g__OwnerCompany__c=\'' + currentcompany + '\' '	
				+ 'group by c2g__OwnerCompany__c, c2g__Account__c, c2g__Dimension1__c, Control__c, c2g__GeneralLedgerAccount__c ';	// BLL1c
			if (!String.isBlank(recordLimit)) soql += ' Limit ' + recordLimit + ' ';
			rcds = Database.query(soql);
			System.debug(rcds.size());
		}
		return rcds;
	}


	// execute for a batch of records
	global void execute(Database.BatchableContext bc, List<sObject> scope) {
		System.debug('CashEntryAutoMatchDT.execute');
		List<AggregateResult> objs = (List<AggregateResult>) scope;
		for(AggregateResult obj : objs) {
			System.debug(obj);
			Id companyId = (Id) obj.get('c2g__OwnerCompany__c');
			Id accountId = (Id) obj.get('c2g__Account__c');
			Id dimension1Id = (Id) obj.get('c2g__Dimension1__c');
			String control = (String) obj.get('Control__c');
			// BLL1
			Id glacctid = (Id) obj.get('c2g__GeneralLedgerAccount__c');
			// BLL1 end

			// Get matching transaction lines, cash entries first, then oldest to newest
			System.debug(companyId);
			System.debug(accountId);
  			System.debug(dimension1Id);
			System.debug(control);
			// BLL1
			System.debug(glacctid);
			// BLL1 end

			String soql ='Select Id, Name, c2g__LineNumber__c, c2g__LineReference__c, Control__c, Credit__c, Debit__c, '
				+ '	c2g__MatchingStatus__c, c2g__TransactionDate__c, '
				+ '	c2g__AccountValue__c, c2g__AccountOutstandingValue__c,  '
				+ '	c2g__Transaction__c, c2g__Transaction__r.Name, c2g__Transaction__r.c2g__CashEntry__c, c2g__Transaction__r.c2g__CashEntry__r.AutoMatchCash__c, '
				+ '	c2g__Transaction__r.c2g__OwnerCompany__c, c2g__Transaction__r.c2g__OwnerCompany__r.Name, '
				+ '	c2g__Account__c, c2g__Account__r.Name, '
				+ '	c2g__Dimension1__c, c2g__Dimension1__r.Name,  '
				+ '	c2g__DocumentCurrency__c, c2g__DocumentCurrency__r.Name,  '
				+ '	DocumentReference__c, Document_Number__c, LastModifiedDate '
				+ 'from c2g__codaTransactionLineItem__c  '
				+ 'where c2g__LineType__c = \'Account\'  '
				+ '  and c2g__AccountOutstandingValue__c!=0  '
				+ '  and c2g__MatchingStatus__c=\'Available\' '
				+ '  and c2g__OwnerCompany__c=\'' + companyId + '\' '
				+ '  and c2g__Account__c=\'' + accountId + '\' '
  				+ '  and c2g__Dimension1__c=\'' + dimension1Id + '\' '
				//+ '  and Control__c=\'' + control + '\' '
				+ '  and (Control__c=\'' + control + '\' or DocumentReference__c=\'' + control + '\') '
				+ '  and c2g__GeneralLedgerAccount__c=\'' + glacctid + '\' '	// BLL1a
				+ 'order by c2g__Transaction__r.c2g__CashEntry__c NULLS LAST, CreatedDate';
			System.debug(soql);
			List<c2g__codaTransactionLineItem__c> trnlines = Database.query(soql);
			// and (c2g__Transaction__r.c2g__CashEntry__c=null or c2g__Transaction__r.c2g__CashEntry__r.AutoMatchCash__c=true) 

			List<c2g__codaTransactionLineItem__c> matchlines = new List<c2g__codaTransactionLineItem__c>();
			List<c2g__codaTransactionLineItem__c> creditlines = new List<c2g__codaTransactionLineItem__c>();
			List<c2g__codaTransactionLineItem__c> debitlines = new List<c2g__codaTransactionLineItem__c>();

			// Just match up to first transaction that can't be fully matched
			Decimal balance = 0.00;
			Decimal credits = 0.00;
			Decimal debits = 0.00;
			// Processing 
			// separate credits from debits
			for(c2g__codaTransactionLineItem__c tl : trnlines) {
				if (tl.c2g__AccountOutstandingValue__c<0) creditlines.add(tl);
				if (tl.c2g__AccountOutstandingValue__c>0) debitlines.add(tl);
			}
			System.debug(creditlines.size());
			System.debug(debitlines.size());
			System.debug((creditlines.size()>0 && debitlines.size()>0 ? 'Have something to match for ':'Nothing to match for ')+control);

			// Start with credits, then add credits when (balance>0) or debits (balance<0) 
			// until we've exhausted the credits or debits, depending on the balance
			boolean doneSelecting = creditlines.size()==0 || debitlines.size()==0;
			while (!doneSelecting) {
				// done if there's no more credits or debits to select for matching
				doneSelecting = creditlines.size()==0 && debitlines.size()==0;

				// balance is 0 -- add next credit *if* there is another debit
				System.debug(balance);
				if (balance==0) {
					System.debug('Balance is 0');
					if (creditlines.size()>0 && debitlines.size()>0) {
						System.debug('Add credit line');
						c2g__codaTransactionLineItem__c line = creditlines.remove(0);
						matchlines.add(line);
						credits += line.c2g__AccountOutstandingValue__c;
						balance = debits + credits;
					} else {
						System.debug('Balance is 0, but no more credits and debits to match');
						doneSelecting = true;
					}
				}

				// If a debit balance, add next credit
				System.debug(balance);
				if (balance>0) {
					System.debug('Balance > 0');
					if (creditlines.size()>0) {
						System.debug('Add credit line');
						c2g__codaTransactionLineItem__c line = creditlines.remove(0);
						matchlines.add(line);
						credits += line.c2g__AccountOutstandingValue__c;
						balance = debits + credits;
					} else {
						System.debug('No more credits to apply');
						doneSelecting = true;
					}
				}

				// if a credit balance, add next debit
				System.debug(balance);
				if (balance<0) {
					System.debug('Balance < 0');
					if (debitlines.size()>0) {
						System.debug('Add debit line');
						c2g__codaTransactionLineItem__c line = debitlines.remove(0);
						matchlines.add(line);
						debits += line.c2g__AccountOutstandingValue__c;
						balance = debits + credits;
					} else {
						System.debug('No more debits to apply');
						doneSelecting = true;
					}
				}
			}
			//for(c2g__codaTransactionLineItem__c tl : trnlines) {
			//	System.debug(tl);
			//	// have transaction lines to include and we haven't exceeded the debits yet
			//	if (matchlines.size()<2 || (credits<0 && balance<=0)) {	
			//		matchlines.add(tl);
			//		System.debug('Added to match: ' + tl.Name);
			//		balance += tl.c2g__AccountOutstandingValue__c;
			//		credits += tl.c2g__AccountOutstandingValue__c<0 ? tl.c2g__AccountOutstandingValue__c : 0;
			//		debits += tl.c2g__AccountOutstandingValue__c>0 ? tl.c2g__AccountOutstandingValue__c : 0;
			//	}
			//}
			System.debug('[[[ Balance ]]]');
			System.debug(balance);
			System.debug(credits);
			System.debug(debits);

			// Match them
			c2g.CODAAPICommon.Reference ref = null;
			System.debug(matchlines.size());
			if (matchlines.size()>1 && credits!=0 && debits!=0) ref = matchTransactionLines(matchlines, creditlines.size()>0, debitlines.size()>0);
			System.debug(ref);

		}

		// Reset results & error messages if getting too large
		if (Limits.getLimitHeapSize() - Limits.getHeapSize() < 1000000){  // if less that 1 meg left
			sendEmail();
		}

	}
	
	
	// matchTransactionLines
	//------------------------------------------------------
	public c2g.CODAAPICommon.Reference matchTransactionLines(List<c2g__codaTransactionLineItem__c> trnlines, boolean moreCredits, boolean moreDebits) {
			System.debug('CashEntryAutoMatchDT.matchTransactionLines');

			c2g__codaCompany__c company = [select id, Name from c2g__codaCompany__c where Id=:trnlines[0].c2g__Transaction__r.c2g__OwnerCompany__c limit 1];
			Account acct = [select Id, Name, c2g__CODADimension1__c from Account where Id=:trnlines[0].c2g__Account__c limit 1];
			Map<Id, c2g__codaTransactionLineItem__c> trnlinemap = new Map<Id, c2g__codaTransactionLineItem__c>();
			c2g__codaDimension1__c dim1 = [select Id, Name from c2g__codaDimension1__c where Id=:trnlines[0].c2g__Dimension1__c limit 1];
			Account setAccountDim1 = new Account(Id=acct.Id, c2g__CODADimension1__c=dim1.Id);
			// BLL2
			//Account resetAccountDim1 = new Account(Id=acct.Id, c2g__CODADimension1__c=acct.c2g__CODADimension1__c);
			Account resetAccountDim1 = new Account(Id=acct.Id, c2g__CODADimension1__c=null);
			// BLL2 end

			// Determine matching date & period
			Date matchingDate = null;
			for(c2g__codaTransactionLineItem__c tl : trnlines) {
				if (matchingDate==null || matchingDate<tl.c2g__TransactionDate__c) matchingDate = tl.c2g__TransactionDate__c;
				trnlinemap.put(tl.Id, tl);
			}
			//if (matchingDate < Date.today().addDays(-1)) matchingDate = Date.today().addDays(-1);
			c2g__codaPeriod__c period = FinancialForce_MBW.getOpenPeriod(company, matchingDate);
			if (period.c2g__Closed__c==true || period.c2g__Cash__c==true || period.c2g__AR__c==true) {
				matchingDate = Date.today();
				period = FinancialForce_MBW.getOpenPeriod(company, matchingDate);
			}
			if (matchingDate < period.c2g__StartDate__c) matchingDate = period.c2g__StartDate__c;
			if (matchingDate > period.c2g__EndDate__c) matchingDate = period.c2g__EndDate__c;

			// Match transaction & cash
			c2g.CODAAPICommon_8_0.Context ctx = new c2g.CODAAPICommon_8_0.Context();
			ctx.CompanyName = company.Name;
		
			c2g.CODAAPICashMatchingTypes_8_0.Configuration config = new c2g.CODAAPICashMatchingTypes_8_0.Configuration();
			config.Account = c2g.CODAAPICommon.Reference.getRef(acct.Id, acct.Name);
			config.MatchingCurrencyMode = c2g.CODAAPICashMatchingTypes_8_0.enumMatchingCurrencyMode.Document; 
			config.MatchingDate = matchingDate;
			config.MatchingPeriod = c2g.CODAAPICommon.Reference.getRef(period.Id, period.Name);
		
			Decimal balance = 0.00;
			Decimal credits = 0.00;
			Decimal debits = 0.00;
			List<c2g.CODAAPICashMatchingTypes_8_0.Item> items = new List<c2g.CODAAPICashMatchingTypes_8_0.Item>();
			c2g.CODAAPICashMatchingTypes_8_0.Item item;
			for(c2g__codaTransactionLineItem__c tli : trnlines) {
				balance += tli.c2g__AccountOutstandingValue__c;
				credits += tli.Credit__c;
				debits += tli.Debit__c;
				item = new c2g.CODAAPICashMatchingTypes_8_0.Item();
				item.TransactionLineItem = c2g.CODAAPICommon.Reference.getRef(tli.Id, tli.Name);
				item.Paid = tli.c2g__AccountOutstandingValue__c;
				item.Discount = 0.00;
				item.WriteOff = 0.00;
				item.TransactionLineItemSystemModStamp = tli.LastModifiedDate;
				items.add(item);
				System.debug(item);
			}
			System.debug('[[[ Balance before writeoffs ]]]');
			System.debug(balance);
			System.debug(credits);
			System.debug(debits);

			// Handle any automatic writeoffs
			Decimal balanceBeforeWriteoff = balance;
			AutomaticWriteoffs(balance, items, moreCredits, moreDebits);
			Decimal balanceAfterWriteoff = balance;

			System.debug('[[[ Balance before adjustments ]]]');
			System.debug(balance);
			System.debug(credits);
			System.debug(debits);

			// Adjust for any remaining balance under the writeoff threshholds
			AdjustForOverOrUnderPayment(balance, items);

			System.debug('[[[ Balance after adjustments ]]]');
			System.debug(balance);
	
			// Setup analysis - no discounts or writeoffs needed for this

			// Automatic write-offs ?
			c2g.CODAAPICashMatchingTypes_8_0.Analysis analysis = new c2g.CODAAPICashMatchingTypes_8_0.Analysis();
			analysis.DiscountGLA = null;
			if (WriteoffGL!=null) {
				analysis.WriteOffGLA = c2g.CODAAPICommon.Reference.getRef(WriteoffGL.Id, WriteoffGL.Name);
				analysis.WriteOffDimension1 = c2g.CODAAPICommon.Reference.getRef(dim1.Id, dim1.Name);
				//analysis.CurrencyWriteOffGLA = c2g.CODAAPICommon.Reference.getRef(WriteoffGL.Id, WriteoffGL.Name);
				//analysis.CurrencyWriteOffDimension1 = c2g.CODAAPICommon.Reference.getRef(dim1.Id, dim1.Name);
			}

			// Setup results by item index

			// Call API! (or not)
			c2g.CODAAPICommon.Reference ref = null;
			c2g__codaMatchingReference__c mref = null;
			String stsmsg = '';
			try {
				matchingGroupNbr++;
				System.debug('[[[ MATCH ]]]');
				if (doUpdate && balanceBeforeWriteoff!=balanceAfterWriteoff) update(setAccountDim1);
				if (doUpdate) ref = c2g.CODAAPICashMatching_8_0.Match(ctx, config, items, analysis);
				stsmsg = 'Matched';
				if (!doUpdate) stsmsg = 'Test only';
				if (doUpdate) mref = [select Id, Name from c2g__codaMatchingReference__c where Id=:ref.Id limit 1];
				if (doUpdate && balanceBeforeWriteoff!=balanceAfterWriteoff) update(resetAccountDim1);
			} catch(Exception e) {
				stsmsg = e.getMessage();
			}
			System.debug('[[[ ' + stsmsg + ' ]]]');
			System.debug(ref);
			System.debug(mref);
			System.debug(stsmsg);

			// log 	Matching Reference & Name, Company, Transaction, Transaction Line, Dimension1, Account, Amount, sts
			System.debug('[[[ Matched Transaction Lines ]]]');
			Integer idx = 0;
			for(c2g.CODAAPICashMatchingTypes_8_0.Item it : items) {
				// transaction line item reference gets corrupted by matching process, use that as default,
				// but try getting the transaction line by sequence number instead...
				c2g__codaTransactionLineItem__c tli = trnlinemap.get(item.TransactionLineItem.Id);
				if (idx<trnlines.size()) tli = trnlines[idx];
				
				List<String> csvlinedata = new List<String>{
					'"' + tli.c2g__Transaction__r.c2g__OwnerCompany__r.Name + '"', 
					tli.c2g__Transaction__r.Name, 
					tli.Name, 
					tli.c2g__Dimension1__r.Name,
					tli.Control__c,
					tli.DocumentReference__c,
					String.valueOf(matchingGroupNbr),	// BLL1
					MatchingDate.format(), // BLL1
					'"' + tli.c2g__Account__r.Name + '"',
					String.valueOf(tli.c2g__AccountOutstandingValue__c),
					String.valueOf(it.Paid),
					'"' + stsmsg + '"'
				};
				System.debug('csv: ' + String.join(csvlinedata,', '));
				if (ref!=null && ref.Id!=null) resultmap.put(resultmap.size(), String.join(csvlinedata, ','));
				else errormap.put(errormap.size(), String.join(csvlinedata, ','));

				// store results
				if (ref!=null && ref.Id!=null) {
					if (storeMatchingReport==null) storeMatchingReport = new Map<Id, List<String>>();
					List<String> tmpresults = storeMatchingReport.get(dim1.Id);
					if (tmpresults==null) tmpresults = new List<String>();
					tmpresults.add(String.join(csvlinedata, ','));
					storeMatchingReport.put(dim1.Id, tmpresults);
				}

				idx++;
			}
			System.debug('[[[ END Matched Transaction Lines ]]]');

			return ref;

	}


	// AutomaticWriteoffs
	//---------------------------------------
	private void AutomaticWriteoffs(Decimal balance, List<c2g.CODAAPICashMatchingTypes_8_0.Item> items, boolean moreCredits, boolean moreDebits) {
		System.debug('CashEntryAutoMatchDT.AutomaticWriteoffs');
		
		// Automatic overpayment writeoff (credits)
		System.debug(mfs);
		System.debug(balance);
		System.debug(writeoffGL);
		System.debug(moreCredits);
		if (writeoffGL!=null && balance<0 && !moreCredits && balance>=(-mfs.Writeoff_Overpayment__c)) {
			Integer itemidx = items.size()-1;
			while(balance<0 && itemidx>=0 && itemidx<items.size()) {
				System.debug('Balance<0: adjust items[' + String.valueOf(itemidx) + '] ' + String.valueOf(balance));
				System.debug(items[itemidx]);
				if (items[itemidx].Paid<0) {
					items[itemidx].Writeoff = Math.max(items[itemidx].Paid, balance);
					balance -= items[itemidx].Writeoff;
					System.debug(items[itemidx]);
				} else {
					System.debug('Skipped items[' +  String.valueOf(itemidx) + ']');
				}
				--itemidx;
			}
		}

		// Automatic underpayment writeoff (debits)
		System.debug(balance);
		System.debug(writeoffGL);
		System.debug(moreDebits);
		if (writeoffGL!=null && balance>0 && !moreDebits && balance<=mfs.Writeoff_Underpayment__c) {
			Integer itemidx = items.size()-1;
			while(balance>0 && itemidx>=0 && itemidx<items.size()) {
				System.debug('Balance>0: adjust items[' + String.valueOf(itemidx) + '] ' + String.valueOf(balance));
				System.debug(items[itemidx]);
				if (items[itemidx].Paid>0) {
					items[itemidx].Writeoff = Math.min(items[itemidx].Paid, balance);
					balance -= items[itemidx].Writeoff;
					System.debug(items[itemidx]);
				} else {
					System.debug('Skipped items[' +  String.valueOf(itemidx) + ']');
				}
				--itemidx;
			}
		}
	}



	// AdjustForOverOrUnderPayment
	//---------------------------------------
	private void AdjustForOverOrUnderPayment(Decimal balance, List<c2g.CODAAPICashMatchingTypes_8_0.Item> items) {
			System.debug('CashEntryAutoMatchDT.AdjustForOverOrUnderPayment');

			// left-over credits (overpayment) - back up & reduce last credit amt(s)
			Integer itemidx = items.size()-1;
			System.debug(balance);
			while(balance<0 && itemidx>=0 && itemidx<items.size()) {
				System.debug('Balance<0: adjust items[' + String.valueOf(itemidx) + '] ' + String.valueOf(balance));
				System.debug(items[itemidx]);
				if (items[itemidx].Paid<0) {
					items[itemidx].Paid -= balance;	// subtract a negative reduces the amount of credit applied
					balance = 0;
					// if the balance exceeded the credit, reset to 0 & re-apply balance to next (prior) entry
					if (items[itemidx].Paid > 0) {
						balance = -items[itemidx].Paid;
						items[itemidx].Paid = 0;
					}
					System.debug(items[itemidx]);
				} else {
					System.debug('Skipped items[' +  String.valueOf(itemidx) + ']');
				}
				--itemidx;
			}
			// remaining debits (underpayment) - back up & reduce last A/R debit amt(s)
			itemidx = items.size()-1;
			System.debug(balance);
			while(balance>0 && itemidx>=0 && itemidx<items.size()) {
				System.debug('Balance>0: adjust items[' + String.valueOf(itemidx) + '] ' + String.valueOf(balance));
				System.debug(items[itemidx]);
				if (items[itemidx].Paid>0) {
					items[itemidx].Paid -= balance;	// reduce the amount of credit applied
					balance = 0;
					// If balance exceeded the last debit, set to 0 and re-apply remaining balance to next (prior) entry
					if (items[itemidx].Paid < 0) {
						balance = -items[itemidx].Paid;	
						items[itemidx].Paid = 0;
					}
					System.debug(items[itemidx]);
				} else {
					System.debug('Skipped items[' +  String.valueOf(itemidx) + ']');
				}
				--itemidx;
			}
	}


	// finish - send results via email
	global void finish(Database.BatchableContext bc) {
		System.debug('CashEntryAutoMatchDT.finish');
		if (remainingCompanyIds.size()>0) {
			CashEntryAutoMatchDT b = new CashEntryAutoMatchDT(recordLimit, doUpdate, remainingCompanyIds, resultmap, errormap, storeMatchingReport);
			Database.executeBatch(b,1);
		} else {
			sendEmail();
		}
	}


	// sendEmail of the results
	global void sendEmail() {
		System.debug('CashEntryAutoMatchDT.sendEmail');
		org = [select Id, Name, isSandbox from Organization limit 1];
		String body = 'Cash Entry Matching has completed.\n';
		String todaystr = DateTime.now().format('yyyy-MM-dd');

		// First, send individual store emails
		try {
			emailStoreContacts();
		} catch(Exception e) {
			body += 'Error sending details to store admins: ' + e.getMessage() + '\n\n';
		}

		// BLL1d String csvheader = 'Company, Transaction, Line, Dimension1, Document Control, Document Reference, Account, Outstanding Value, Applied Value, Status\n';
		String csvheader = 'Company, Transaction, Line, Dimension1, Document Control, Document Reference, MatchingGroup, Matching Date, Account, Outstanding Value, Applied Value, Status\n';	// BLL1a
		List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
		List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();
		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		//List<String> recipients = new List<String>{ UserInfo.getUserEmail() };
		List<String> recipients = new List<String>(Utility.getGroupMbrUserEmails('CashEntryAutoMatchDT'));
		if (org.isSandbox) recipients = new List<String>{UserInfo.getUserEmail()};
		if (recipients.size()==0) recipients.add(UserInfo.getUserEmail());

		//if (!org.isSandbox) recipients.add('another.email@mobilityworks.com');
		mail.setToAddresses(recipients); 
		mail.setSubject('Cash Entry Matching completed - UPDATES');
		if (!doUpdate) body += 'Test only! NOT Updated!\n';
		mail.setPlainTextBody(body);

		Messaging.EmailFileAttachment resultcsv = new Messaging.EmailFileAttachment();
			resultcsv.setContentType('text/csv');
			resultcsv.setFileName('AutomaticMatching ' + todaystr + '.csv');
			resultcsv.setInline(false);
			resultcsv.Body = Blob.valueOf(csvheader + String.join(resultmap.values(),'\n'));
			if (resultmap.size()>0) listOfAttachments.add(resultcsv);
		Messaging.EmailFileAttachment upderrors = new Messaging.EmailFileAttachment();
			upderrors.setContentType('text/csv');
			upderrors.setFileName('MatchingErrors' + todaystr + '.csv');
			upderrors.setInline(false);
			upderrors.Body = Blob.valueOf(csvheader + String.join(errormap.values(),'\n'));
			if (errormap.size()>0) listOfAttachments.add(upderrors);
		mail.setFileAttachments(listOfAttachments);
		emailMsgs.add(mail);

		// Only send if records were selected for processing...
		if (resultmap.size()>0 || errormap.size()>0) Messaging.sendEmail(emailMsgs);
		
		// Reset to clear HEAP
		resultmap = new Map<Integer,String>();
		errormap  = new Map<Integer,String>();
		
	}


	// Schedulable context
	global void execute(SchedulableContext ctx) {
		System.debug('CashEntryAutoMatchDT.execute (schedule)');
		String maxrcds = Test.isRunningTest() ? '1' : null;
		List<BatchSchedule__c> bss = [
			select Name, ClassName__c, CronSchedule__c, Parameters__c, ScheduledJobId__c, Active__c, BatchSize__c
			from BatchSchedule__c
			where ScheduledJobId__c=:ctx.getTriggerId()
		];
		BatchSchedule__c bs = bss.size()>0 ? bss[0] : new BatchSchedule__c(Parameters__c='', Active__c=true);

		// default run params (no dynamic params specified)
		List<Object> runparams = new List<Object>();
		ScheduleParameters sp = new ScheduleParameters(maxrcds);
		runparams.add(sp);

		if (!String.isBlank(bs.Parameters__c)) runparams = (List<Object>) JSON.deserializeUntyped(bs.Parameters__c);
		else runparams.add(new Map<String,Object>());	// default to 1 empty map to run once with default params!
		for(Object o : runparams) {
			Map<String,Object> params = (Map<String,Object>) o; 
			maxrcds = (String) params.get('RcdLimit');
			if (bs==null || bs.Active__c) {
				CashEntryAutoMatchDT b = new CashEntryAutoMatchDT(maxrcds, true, null, null, null, null);
				Database.executeBatch(b, Integer.valueOf(bs.BatchSize__c));
			}
		}
	}

	// scheduleMe self-scheduler
	public static List<String> scheduleMe() {
		System.debug('CashEntryAutoMatchDT.scheduleMe');
		String thisClassName = CashEntryAutoMatchDT.class.getName();
		// from schedule custom settings
		List<BatchSchedule__c> bss = [
			select Name, ClassName__c, CronSchedule__c, Parameters__c, ScheduledJobId__c, Active__c, BatchSize__c
			from BatchSchedule__c 
			where ClassName__c=:thisClassName
		];
		
		// First remove existing scheduled jobs from the existing schedule custom settings... 
		for(BatchSchedule__c bs : bss) {
			try {
				if (!String.isBlank(bs.ScheduledJobId__c)) System.abortJob((Id) bs.ScheduledJobId__c);
			} catch(Exception e) {System.debug(e);}
		}

		// set default schedule if none found
		Integer i = 0;
		if (bss.size()==0) {
			for(String cron : CashEntryAutoMatchDT.CRON_LIST) {
				String params = '';
				if (!String.isBlank(params)) params += ',';
				params += '{'
					+ '"RcdLimit":""'
					+ '}';
				String devname = thisClassName.left(37) + '_' + String.valueOf(i+1);
				bss.add(new BatchSchedule__c(
					Name = devname,
					ClassName__c = thisClassName,
					CronSchedule__c = cron,
					Parameters__c = '['
						+ params 
						+ ']',
					BatchSize__c = 1,
					Active__c=true
				));
				++i;
			}
		}
		
		// Now (re-)schedule the jobs that are in the BatchSchedule list for this class
		List<String> jobIds = new List<String>();
		CashEntryAutoMatchDT m = new CashEntryAutoMatchDT(null, true, null, null, null, null);
		for(BatchSchedule__c bs : bss) {
			System.debug(bs.CronSchedule__c);
			String jobname = bs.Name;
			if (Test.isRunningTest()) jobname += '_TEST';
			if (bs.Active__c) {
				Id jobId = System.schedule(jobname, bs.CronSchedule__c, m);
				bs.ScheduledJobId__c = jobId;
				jobIds.add(jobId);
			}
		}
		upsert(bss);
		return jobIds;
	}

	class ScheduleParameters {
		public String RcdLimit {get;set;}
		public ScheduleParameters(String maxrcds) {
			RcdLimit = maxrcds;
		}
	}

	// emailStoreContacts
	//-----------------------------------
	public void emailStoreContacts() {
		System.debug('CashEntryAutoMatchDT.emailStoreContacts');
		String csvheader = 'Company,Transaction,TransLine,Dimension,Document Control,Document Reference,Account,Open Amt,Applied,Result\n';
		List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
		
		// get all locations and their sales admin email addresses
		LocationsSingleton ls = LocationsSingleton.getInstance();
		ls.retrieveAllLocations();

		// map from dimension1 to store
		Map<Id,dealer__Dealer_Location__c> dimStoreMap = new Map<Id,dealer__Dealer_Location__c>();
		// map of sales admin Ids to their email addresses
		Map<Id,String> salesAdminEmailMap = new Map<Id,String>();
		for(dealer__Dealer_Location__c l : ls.locationIdMap.values()) {
			if (l.Sales_Admin__c!=null) salesAdminEmailMap.put(l.Sales_Admin__c,'');
			if (l.Commercial_Sales_Admin__c!=null) salesAdminEmailMap.put(l.Commercial_Sales_Admin__c,'');
			if (l.Financial_Force_Dimension_1__c!=null && (l.AutoAssignRetail__c || !dimStoreMap.containsKey(l.Financial_Force_Dimension_1__c))) {
				dimStoreMap.put(l.Financial_Force_Dimension_1__c, l);
			}
		}
		Set<Id> slsAdminIds = salesAdminEmailMap.keySet();
		for(User u : [select Id, Email from User where Id in :slsAdminIds]) salesAdminEmailMap.put(u.Id, u.Email);

		// build an email message for each store
		if (storeMatchingReport==null) storeMatchingReport = new Map<Id, List<String>>();
		for(Id dimid : storeMatchingReport.keySet()) {
			List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();

			List<String> reportData = storeMatchingReport.get(dimid);

			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			List<String> recipients = new List<String>();

			//dealer__Dealer_Location__c loc = ls.getLocationById(storeid);
			dealer__Dealer_Location__c loc = dimStoreMap.get(dimid);
			if (loc==null) loc = new dealer__Dealer_Location__c(Name=dimid + ' not found', Sales_Admin__c=null, Commercial_Sales_Admin__c=null); 
			String slsAdminEmail = salesAdminEmailMap.get(loc.Sales_Admin__c);
			String commSlsAdminEmail = salesAdminEmailMap.get(loc.Commercial_Sales_Admin__c);
			
			if (!String.isBlank(slsAdminEmail)) recipients.add(slsAdminEmail);
			if (!String.isBlank(commSlsAdminEmail) && slsAdminEmail!=commSlsAdminEmail) recipients.add(commSlsAdminEmail);
			if (org.isSandbox) recipients = new List<String>{UserInfo.getUserEmail()};
			if (recipients.size()==0) recipients.add(UserInfo.getUserEmail());
	
			mail.setToAddresses(recipients); 
			mail.setSubject('Cash Matching for ' + loc.Name);
			String body = 'Cash Matching creation has completed.\n';
			if (!doUpdate) body += 'Test only! NOT Updated!\n';
			mail.setPlainTextBody(body);
	
			Messaging.EmailFileAttachment resultcsv = new Messaging.EmailFileAttachment();
				resultcsv.setContentType('text/csv');
				resultcsv.setFileName('CashMatching-' + loc.Name + '.csv');
				resultcsv.setInline(false);
				resultcsv.Body = Blob.valueOf(csvheader + String.join(reportData,'\n'));
				if (reportData.size()>0) listOfAttachments.add(resultcsv);
			mail.setFileAttachments(listOfAttachments);
			if (reportData.size()>0) emailMsgs.add(mail);
	
		}

		// Only send if records were selected for processing...
		if (emailMsgs.size()>0) Messaging.sendEmail(emailMsgs);

		// clear heap
		storeMatchingReport = new Map<Id,List<String>>();
	}

}