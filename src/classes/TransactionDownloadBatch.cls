/**
 * TransactionDownloadBatch
 * Tested by: TransactionDownloadBatch_TEST
 * 
 * Note: Database.Stateful serializes the object with each call. Not sure this will be good 
 *       when the csv gets large.
 *
 * Code Coverage:
 *	2018-04-16	93% (108/115)
 *	2018-06-28	92% (118/127)
 *	2018-07-02	92% (124/134)
 *	2018-12-06	94%	(126/134)
 *
 * Modification log:
 *	2016-03-15	B. Leaman	BLL1 - Add through period name option.
 *	2016-06-22	B. Leaman	BLL2 - Update completion date/time even if no transactions were downloaded.
 *	2016-10-11	B. Leaman	BLL3 - Change tansaction date to always be within the period start/stop dates
 *							because MAS import uses the month from the date, not the period.
 *	2018-04-16	B. Leaman	BLL4 - send emails when approaching heap limits
 *	2018-06-21	B. Leaman	BLL5 - fix handling double-quote in the data
 *	2018-06-27	B. Leaman	W-000615 BLL6 - per Judy B. Use line description instead of transaction description; 
 *	2018-06-28	B. Leaman	BLL7 - comment out BLL6 for now, emergency fix to handle transaction# over 1 million.
 *	2018-12-06	B. Leaman	W-000512 BLL8 - only select transactions within the last 90 days
 */
 
/** Test script:  
TransactionDownloadBatch download = new TransactionDownloadBatch('TRN003800');
Id batchprocessid = Database.executeBatch(download, 200);
System.debug(batchprocessid);
AsyncApexJob aaj = [
    SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors
    FROM AsyncApexJob WHERE ID =: batchprocessid 
];
System.debug(aaj);
*/
/**	LastTransactionName__c lastTxn = LastTransactionName__c.getOrgDefaults();
*/
 
global class TransactionDownloadBatch implements Database.Batchable<sObject>, Database.Stateful {

	global final String sinceTransaction;
	global final String untilTransaction;
	global final boolean saveLastTransaction;
	// BLL1a
	global final String throughPeriodName;
	global final boolean fullPeriod;
	// BLL1a end
	global final String query;
	global String lastTransaction;
	global Decimal lastTrnNbr;	// BLL7a
	
	global DownloadTransactionsControl__c lastTxn;
	global Map<String,TransactionExport> csvMap;

	global Decimal sinceTrnNbr;	// BLL7a 
	global Decimal untilTrnNbr; // BLL7a

	global TransactionDownloadBatch(String sinceTrn, String untilTrn, boolean saveLastTrn, String thruPeriodName, boolean wholePeriod) {
		sinceTransaction = sinceTrn;
		untilTransaction = untilTrn;
		saveLastTransaction = saveLastTrn;
		lastTxn = DownloadTransactionsControl__c.getOrgDefaults();
		if (sinceTransaction==null) {
			sinceTransaction = lastTxn.LastTransactionName__c;
		}
		lastTransaction = lastTxn.LastTransactionName__c;	// BLL2a
		// BLL1a
		throughPeriodName = thruPeriodName;
		fullPeriod = wholePeriod;
		// BLL1a

		// BLL8
		DateTime createdSince = null;
		if (!String.isBLank(sinceTransaction)) {
			List<c2g__codaTransaction__c> sinceTrns = [select Id, CreatedDate from c2g__codaTransaction__c where Name=:sinceTransaction];
			if (sinceTrns.size()>0) createdSince = sinceTrns[0].CreatedDate;
			if (createdSince!=null) createdSince = createdSince.addDays(-60);
		}
		// BLL8 end

		// BLL7a
		sinceTrnNbr = 0;
		if (!String.isBlank(sinceTransaction)) sinceTrnNbr = Decimal.valueOf(sinceTransaction.replaceAll('[A-Z]',''));
		untilTrnNbr = 0; 
		if (!String.isBlank(untilTransaction)) untilTrnNbr = Decimal.valueOf(untilTransaction.replaceAll('[A-Z]',''));
		// BLL7a end
		
		String soql = 'select '
			+ 'Name, c2g__Transaction__c, '	// BLL4a
			+ 'c2g__GeneralLedgerAccount__r.Name, '
			+ 'c2g__Dimension1__r.Name, '
			+ 'c2g__Transaction__r.c2g__TransactionDate__c, '
			+ 'c2g__Account__r.Name, '
			+ 'Customer_Name__r.Name, '
			+ 'Third_Party_Payor_TL__r.Name, '
			+ 'Finance_Company__r.Name, '
			+ 'DocumentReference__c, '
			+ 'c2g__LineDescription__c, '	// BLL6a
			+ 'c2g__LineReference__c, '	// BLL6a
			+ 'c2g__HomeValue__c, '
			+ 'c2g__Transaction__r.Name, '
			+ 'c2g__Transaction__r.Source__c, '
			+ 'c2g__Transaction__r.c2g__TransactionType__c, '
			+ 'c2g__Transaction__r.c2g__VendorDocumentNumber__c, '
			+ 'c2g__Transaction__r.c2g__DocumentNumber__c, '
			+ 'c2g__Transaction__r.c2g__DocumentDescription__c, '
			+ 'c2g__Transaction__r.c2g__Period__r.c2g__StartDate__c, '	// BLL3a
			+ 'c2g__Transaction__r.c2g__Period__r.c2g__EndDate__c, '	// BLL3a
			+ 'c2g__Transaction__r.c2g__Period__r.Name '
			+ 'from c2g__codaTransactionLineItem__c ';
		String junction = '';	// BLL1c
		String criteria = ''; 	// BLL1a
		// BLL7d
		//if(sinceTransaction!=null) {
		//	criteria += junction + ' c2g__Transaction__r.Name > ' + '\'' + String.escapeSingleQuotes(sinceTransaction) + '\'';
		//	junction = ' and ';
		//}
		//if (untilTransaction!=null && !String.isBlank(untilTransaction)) {
		//	criteria += junction + ' c2g__Transaction__r.Name <= ' + '\'' + String.escapeSingleQuotes(untilTransaction) + '\'';
		//	junction = ' and ';
		//}
		// BLL1a
		// BLL7d end
		// BLL7a
		if (!String.isBlank(sinceTransaction)) {
			criteria += junction + ' c2g__Transaction__r.Transaction_Sequence__c > ' + String.valueOf(sinceTrnNbr) + ' ';
			junction = ' and '; 
			// BLL8
			if (createdSince!=null) criteria += junction + ' CreatedDate >= ' + createdSince.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
			junction = ' and '; 
			// BLL8 end
		}
		if (!String.isBlank(untilTransaction)) {
			criteria += junction + ' c2g__Transaction__r.Transaction_Sequence__c <= ' + String.valueOf(untilTrnNbr) + ' ';
			junction = ' and '; 
		}
		// BLL7a
		if (!String.isBlank(throughPeriodName)) {
			criteria += junction + ' (c2g__Transaction__r.c2g__Period__r.Name < \'' + throughPeriodName
				+ '\' or c2g__Transaction__r.c2g__Period__r.Name like \'' + throughPeriodName + '%\') ';
		}
		if (!String.isBlank(throughPeriodName) && fullPeriod==true) {
			if (!string.isBlank(criteria)) criteria = '(' + criteria + ')';
			criteria += ' or c2g__Transaction__r.c2g__Period__r.Name like \'' + throughPeriodName + '%\' ';
		}
		if (!String.isBlank(criteria)) soql += ' where ' + criteria + ' ';
		// BLL1a
		soql += ' order by c2g__Transaction__c, Name ';	// BLL4a
		query = soql;
		csvMap = new Map<String,TransactionExport>();
	}

	global Database.QueryLocator start(Database.BatchableContext bc) {
		System.debug(query);
		return Database.getQueryLocator(query);
	}
   
	global void execute(Database.BatchableContext bc, List<sObject> scope) {
		System.debug('Scope');
		System.debug(scope);
		List<c2g__codaTransactionLineItem__c> trnlines = (List<c2g__codaTransactionLineItem__c>) scope;
		System.debug(trnlines.size());
		Id lastTransactionId = trnlines.size()>0 ? trnlines[0].c2g__Transaction__c : null;	// BLL4a
		boolean sentEmail = false;
		for(c2g__codaTransactionLineItem__c t : trnlines) {

			// BLL4a
			// if getting close to limits, send off what we've got so far
			if (!sentEmail && (Limits.getLimitHeapSize() - Limits.getHeapSize()) < 3000000 && t.c2g__Transaction__c!=lastTransactionId) {  // if less that 1 meg left
				emailcsv();
		 		csvMap.clear();
				sentEmail = true;
			}
			lastTransactionId = t.c2g__Transaction__c;
			// BLL4a end

			// BLL7a
			Decimal TrnNbr = 0;
			if (!String.isBlank(t.c2g__Transaction__r.Name)) TrnNbr = Decimal.valueOf(t.c2g__Transaction__r.Name.replaceAll('[A-Z]',''));
			// BLL7a end

			//BLL7d if (lastTransaction==null || t.c2g__Transaction__r.Name > lastTransaction) lastTransaction = t.c2g__Transaction__r.Name;
			// BLL7a
			if (lastTrnNbr==null || (TrnNbr!=null && TrnNbr!=0 && TrnNbr>lastTrnNbr)) {
				lastTrnNbr = TrnNbr;
				lastTransaction = t.c2g__Transaction__r.Name;
			}
			// BLL7a end
			String s = csvLine(t);
			System.debug(s);

			TransactionExport texp = csvMap.get(t.c2g__Transaction__r.c2g__Period__r.Name);
			if (texp==null) {
				texp = new TransactionExport(csvHeader());
				System.debug('Created new transaction export for period ' + t.c2g__Transaction__r.c2g__Period__r.Name);
			}
			texp.csv += s;
			
			//BLL7d if (texp.firstTransaction==null || t.c2g__Transaction__r.Name < texp.firstTransaction) texp.firstTransaction = t.c2g__Transaction__r.Name;
			//BLL7d if (texp.lastTransaction==null || t.c2g__Transaction__r.Name > texp.lastTransaction) texp.lastTransaction = t.c2g__Transaction__r.Name;
			// BLL7a
			if (texp.firstTrnNbr==null || TrnNbr<=texp.firstTrnNbr) {
				texp.firstTransaction = t.c2g__Transaction__r.Name;
				texp.firstTrnNbr = TrnNbr;
			}
			if (texp.lastTrnNbr==null || TrnNbr<=texp.lastTrnNbr) {
				texp.lastTransaction = t.c2g__Transaction__r.Name;
				texp.lastTrnNbr = TrnNbr;
			}
			// BLL7a end
			
			csvMap.put(t.c2g__Transaction__r.c2g__Period__r.Name, texp);
		}

		
	}
	
 	global void finish(Database.BatchableContext bc) {
 		emailcsv();
 		csvMap.clear();

		// save new last transaction number
		if (saveLastTransaction) { //BLL2d && !String.isBlank(lastTransaction)) {
			lastTxn = DownloadTransactionsControl__c.getOrgDefaults();
			
			//BLL7d if (!String.isBlank(lastTransaction) && (lastTransaction>lastTxn.LastTransactionName__c || lastTxn.LastTransactionName__c==null || !String.isBlank(untilTransaction)))  	// BLL2c not blank lastTransaction
			//BLL7d 	lastTxn.LastTransactionName__c = lastTransaction;
			System.debug(LastTrnNbr);
			System.debug(lastTransaction);
			if (LastTrnNbr!=0 && !String.isBlank(lastTransaction)) lastTxn.LastTransactionName__c = lastTransaction;	// BLL7a
			lastTxn.LastCompleted__c = Datetime.now();
			lastTxn.ThroughPeriodName__c = String.isBlank(throughPeriodName) ? null : throughPeriodName;	// BLL1a
			System.debug(lastTxn);
			upsert(lastTxn);
		}
		
 	}
 	
 	
	// bll4d global void finish(Database.BatchableContext bc) {
	global void emailcsv() {
		// email csv
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();
		mail.setUseSignature(false);
		mail.setToAddresses(new String[] { UserInfo.getUserEmail() }); 
		//mail.setToAddresses(sendToAddresses); // use list of addresses
		String subject = 'Transactions after ' + sinceTransaction;
		if (untilTransaction!=null && !String.isBlank(untilTransaction)) {
			subject += ' through ' + untilTransaction;
		}
		if (!String.isBlank(throughPeriodName)) {
			subject += (fullPeriod ? ' and all period ' : ' through period ') + throughPeriodName;
		}
		mail.setSubject(subject);
		String body = 'Your transaction download is ready.\r\nSee the attached csv file.\r\n';
		if (csvMap.size()==0) {
			body = 'There were no transactions to download.\r\n';
		}
		
		// Admin gets additional info
		//Profile p = [
        //    select Id, Name, PermissionsModifyAllData 
        //    from Profile 
        //    where Id=:UserInfo.getProfileID() 
        //    limit 1
        //];
		//boolean isAdmin = (p!=null && (p.Name.contains('Admin') || p.PermissionsModifyAllData==true));
		//if (isAdmin) {
		//	body += '\nsoql:\n' + query;
		//}
		
		// sandbox gets copy of soql
		Organization org = [select Id, Name, isSandbox from Organization limit 1];
		if (org.isSandbox) {
			body += '\rsoql:\r' + query + '\r';
		}
		
		mail.setHtmlBody(body);
		
		System.debug(csvMap.keySet());
		List<String> keys = new List<String>(csvMap.keySet());
		keys.sort();
		for(String k : keys) {
			TransactionExport texp = csvMap.get(k);
			Messaging.EmailFileAttachment emailAttach = new Messaging.EmailFileAttachment();
			emailAttach.setContentType('text/csv');
			emailAttach.setFileName('Pd_' + k.replace('/','-') + '_Txn_' + texp.firstTransaction + '-' + texp.LastTransaction + '.csv');
			emailAttach.setInline(false);
			emailAttach.Body = Blob.valueOf(texp.csv);
			listOfAttachments.add(emailAttach);
		} 
		
		mail.setFileAttachments(listOfAttachments);
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

	}
   
	public String csvHeader() {
		return 'GL Account,Dimension 1,Trn Date,Receivable Acct,Third Party Payor,'
			+ 'Source,Doc Reference,Vendor Doc Nbr,Value,Transaction,Doc Number,Trn Type,' 
			+ 'Doc Description,Period,'
			+ 'Finance Company,Customer\n';
	}
   
	//-----------------------------------
	public String stdString(String s) {
	   if (s==null) return '';
	   String csvdata = s;
	   csvdata = s.replace('"', '""').replace('\n',' ').replace('\r',' ');
	   csvdata = '"' + csvdata + '"';
	   return csvdata;
	}
	
	//-----------------------------------
	public String csvLine(c2g__codaTransactionLineItem__c t) {
	   String s = '';
	   Time zerotime = Time.newInstance(0,0,0,0);	// BLL3a
	   DateTime dt = Datetime.newInstance(t.c2g__Transaction__r.c2g__TransactionDate__c, zerotime);	// BLL3c 
	   // BLL3a - adjust date to be within the period
	   if (dt.date()<t.c2g__Transaction__r.c2g__Period__r.c2g__StartDate__c) dt=Datetime.newInstance(t.c2g__Transaction__r.c2g__Period__r.c2g__StartDate__c,zerotime);
	   if (dt.date()>t.c2g__Transaction__r.c2g__Period__r.c2g__EndDate__c) dt=Datetime.newInstance(t.c2g__Transaction__r.c2g__Period__r.c2g__EndDate__c,zerotime);
	   // BLL6a
	   String description = t.c2g__LineDescription__c;
	   if (String.isBlank(description)) description = t.c2g__Transaction__r.c2g__DocumentDescription__c;
	   // BLL6a
	   // BLL3a end
	   s = stdString(t.c2g__GeneralLedgerAccount__r.Name) + ','
	     + stdString(t.c2g__Dimension1__r.Name) + ','
	     + '"' + dt.format('yyyy-MM-dd') + '",'
	     + stdString(t.c2g__Account__r.Name) + ','
	     + stdString(t.Third_Party_Payor_TL__r.Name) + ','
	     + stdString(t.c2g__Transaction__r.Source__c) + ','
	     + stdString(t.DocumentReference__c) + ','
	     + stdString(t.c2g__Transaction__r.c2g__VendorDocumentNumber__c) + ','
	     + String.valueOf(t.c2g__HomeValue__c.setScale(2)) + ','
	     + t.c2g__Transaction__r.Name + ','
	     + stdString(t.c2g__Transaction__r.c2g__DocumentNumber__c) + ','
	     + stdString(t.c2g__Transaction__r.c2g__TransactionType__c) + ','
	     //BLL6d + stdString(t.c2g__Transaction__r.c2g__DocumentDescription__c) + ','	// to be commented out for bll6
	     + stdString(description) + ',' // BLL6a
	     + '"' + t.c2g__Transaction__r.c2g__Period__r.Name + '",'	// BLL6c
	     + stdString(t.Finance_Company__r.Name) + ','
	     + stdString(t.Customer_Name__r.Name) + '\n';

	   return s;
	}

    // TransactionExport contains first & last transaction names and the csv export data w/ headers
	class TransactionExport {
		public String csv;
		public String firstTransaction;
		public String lastTransaction;
		public Decimal firstTrnNbr;	// BLL7a
		public Decimal lastTrnNbr;	// BLL7a
		
		public TransactionExport(String s) {
			csv = s;
		}
	}
   
}