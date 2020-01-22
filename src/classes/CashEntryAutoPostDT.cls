/**
 * CashEntryAutoPostDT
 * Tested by: CashEntryAutoPostDT_TEST
 * Date: 2019-04-09
 * Programmer: Bryan Leaman
 * Project: W-000575
 *
 * Coverage:
 * 2019-05-02	91% (137/150)
 *
 * Modifications: 
 *	2019-06-14	W-000575 impl - BLL1 ensure accounts have AR Control# (1100)
 *
 * Run it now:
Database.executeBatch(new CashEntryAutoPostDT(null, true, null, '< TODAY', null, null));

 * Set standard schedule:
CashEntryAutoPostDT.scheduleMe();

 * Set custom schedule:
System.schedule('CashEntryAutoPostDT', 'sec min hr day mth wd year', new CashEntryAutoPostDT(null,true,null,null,null,null));

 */
 global class CashEntryAutoPostDT implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

	global final String query;
	global boolean doUpdate;
	global String dateParam;
	global String recordLimit;
	global String dateselection;
	global Id currentcompany;
	global Map<Id,String> resultmap;
	global Map<Id,String> errormap;
	public static final List<String> CRON_LIST = new List<String>{
		'0 0 1 * * ? *' 	// 1 a.m. daily
	};
	public static final List<String> CRON_SELECTOR = new List<String>{
		' < TODAY '
	};
	global List<Id> remainingCompanyIds;
	global c2g__codaGeneralLedgerAccount__c acctRecGL;	// BLL1a

	// CashEntryAutoPostDT constructor - generate query string & initialize
	global CashEntryAutoPostDT(String rcdlimit, boolean doUpd, List<Id> companyidlist, 
		String todaystr, Map<Id,String> results, Map<Id,String> errors) {
		System.debug('CashEntryAutoPostDT.constructor');

		dateParam = todaystr;
		if (String.isBlank(todaystr)) todaystr = ' < ' + DateTime.now().format('yyyy-MM-dd');
		dateselection = todaystr;
		// special value replacements: TODAY, YESTERDAY, TOMORROW
		dateselection = dateselection.replace('TODAY', DateTime.now().format('yyyy-MM-dd'));
		dateselection = dateselection.replace('YESTERDAY', DateTime.now().addDays(-1).format('yyyy-MM-dd'));
		dateselection = dateselection.replace('TOMORROW', DateTime.now().addDays(1).format('yyyy-MM-dd'));

		// starting fresh for all companies or continuing on?
		if (companyidlist==null) {
			remainingCompanyIds = new List<String>();
			//for(c2g__codaCompany__c c : [select Id, Name from c2g__codaCompany__c where BatchCashPosting__c=true]) {
			//	System.debug(c);
			//	remainingCompanyIds.add(c.Id);
			//}
			String qry = 'select c2g__OwnerCompany__c '
				+ 'from c2g__codaCashEntry__c '
				+ 'where c2g__Status__c=\'In Progress\' '
				+ ' and c2g__Date__c ' + dateselection + ' '
				+ ' and Automated_Entry__c=true '
				+ 'group by c2g__OwnerCompany__c ';
			for (AggregateResult ar : Database.query(qry)) {
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
		// end determining which companies have cash entries to post

		recordLimit = rcdlimit;
		doUpdate = doUpd;
		String soql = 
			'Select Id, Name, c2g__OwnerCompany__c, c2g__OwnerCompany__r.Name, c2g__Date__c, '
			+ 'c2g__PaymentMethod__c, c2g__ChargesGLADimension1__c, c2g__ChargesGLADimension1__r.Name, '
			+ 'c2g__Period__c, c2g__Period__r.Name, c2g__Reference__c, c2g__Type__c, c2g__Value__c '
			+ 'From c2g__codaCashEntry__c '
			+ 'Where c2g__Status__c=\'In Progress\' '
			+ ' and c2g__Date__c ' + dateselection + ' '
			+ ' and Automated_Entry__c=true ';

		// select a single company
		//if (!String.isBlank(currentcompany)) { // allow null, which will never select any records
			soql += ' and c2g__OwnerCompany__c = :currentcompany ';
		//} 
		//System.assert(currentcompany!=null,'No companies are set up to auto-post cash entries');

		soql += 'Order by c2g__OwnerCompany__c, CreatedDate desc ';
		if (!String.isBlank(rcdlimit)) soql += 'Limit ' + rcdlimit + ' ';
		query = soql;

		errormap = new Map<Id, String>();
		resultmap = new Map<Id, String>();
		// continuing from last batch instance ...
		if (errors!=null) errormap = errors;
		if (results!=null) resultmap = results;

	}


	// start - query the database
	global Database.QueryLocator start(Database.BatchableContext bc) {
		System.debug('CashEntryAutoPostDT.start');
		System.debug('Set current company to Id: ' + currentcompany);
		if (!String.isBlank(currentcompany)) FinancialForce_MBW.selectCompany(currentcompany);
		// BLL1
		acctRecGL = [select Id from c2g__codaGeneralLedgerAccount__c where c2g__ExternalId__c='1100' limit 1];	
		// BLL1 end
		System.debug(query);
		return Database.getQueryLocator(query);
	}


	// execute for a batch of records
	global void execute(Database.BatchableContext bc, List<sObject> scope) {
		System.debug('CashEntryAutoPostDT.execute');
		List<c2g__codaCashEntry__c> objs = (List<c2g__codaCashEntry__c>) scope;
		System.debug('Record count: ' + String.valueOf(objs.size()));
		List<c2g__codaCashEntry__c> updCashEntries = new List<c2g__codaCashEntry__c>();

		// BLL1 - set up Acct Rec Ctl for any accounts missing it
		Map<Id,Account> setARCtl = new Map<Id,Account>();
		//Map<Id,Account> resetARCtl = new Map<Id,Account>();
		Set<Id> ceIds = new Set<Id>();
		for(c2g__codaCashEntry__c o : objs) ceIds.add(o.Id);
		for(c2g__codaCashEntryLineItem__c cel : [select Id, c2g__Account__c, c2g__Account__r.c2g__CODAAccountsReceivableControl__c from c2g__codaCashEntryLineItem__c where c2g__CashEntry__c in :ceIds ]) {
			if (cel.c2g__Account__r.c2g__CODAAccountsReceivableControl__c==null) {
				setARCtl.put(cel.c2g__Account__c, new Account(Id=cel.c2g__Account__c, c2g__CODAAccountsReceivableControl__c=acctRecGL.Id));
				//resetARCtl.put(cel.c2g__Account__c, new Account(Id=cel.c2g__Account__c, c2g__CODAAccountsReceivableControl__c=null));
				System.debug('setARCtl for ' + cel.c2g__Account__c);
				System.debug(cel);
				System.debug(acctRecGL);
			}
		}
		System.debug(setARCtl);
		try {
			if (setARCtl.size()>0) Database.update(setARCtl.values(),false);
		} catch(Exception e) {}
		// BLL1 end

		// Update
		List<c2g__codaCashEntry__c> updObjs =new List<c2g__codaCashEntry__c>();
		for(c2g__codaCashEntry__c o : objs) {
			// FinancialForce_MBW.selectCompany(o.c2g__OwnerCompany__c);
			System.debug(o);
			// post cash entry
			String resultstring = String.join(new List<String>{
				o.Name, 
				DateTime.newInstance(o.c2g__Date__c.year(), 
				o.c2g__Date__c.month(), 
				o.c2g__Date__c.day(),0,0,0).format('yyyy-MM-dd'), 
				o.c2g__Type__c,
				o.c2g__PaymentMethod__c, 
				String.valueOf(o.c2g__Value__c),
				'"' + o.c2g__OwnerCompany__r.Name + '"', 
				'"' + o.c2g__Period__r.Name + '"',
				'"' + o.c2g__Reference__c + '"'
			}, ',');
			String sts = 'Posted';
			try {
				System.debug('Ready to post');
				if (doUpdate) FFAccounting.PostCashEntry(o.Id);
				else sts='Test only';
				System.debug('Done posting');
				resultMap.put(o.Id, resultstring + ',Complete,' + sts);
			} catch(Exception e) {
				sts = e.getMessage();
				String errormsg =  resultstring + ',error,"' + sts + '"';
				errormap.put(o.Id, errormsg);
			}
			updCashEntries.add(new c2g__codaCashEntry__c(Id=o.Id, AutomatedPostSts__c=sts));
		}
		try {
			// BLL1 - ensure all updated accounts have AR control GL# removed (not needed per Michele S)
			//if (resetARCtl.size()>0) update(resetARCtl.values());
			// BLL1 end
			if (updCashEntries.size()>0) update(updCashEntries);
		} catch(Exception e) {}

		// Reset results & error messages if getting too large
		if (Limits.getLimitHeapSize() - Limits.getHeapSize() < 1000000){  // if less that 1 meg left
			sendEmail();
		}

	}
	
	
	// finish - send results via email
	global void finish(Database.BatchableContext bc) {
		System.debug('CashEntryAutoPostDT.finish');
		if (remainingCompanyIds.size()>0) {
			CashEntryAutoPostDT b = new CashEntryAutoPostDT(recordLimit, doUpdate, remainingCompanyIds, dateParam, resultmap, errormap);
			Database.executeBatch(b,1);
		} else {
			sendEmail();
		}
	}


	// sendEmail of the results
	global void sendEmail() {
		System.debug('CashEntryAutoPostDT.sendEmail');
		Organization org = [select Id, Name, isSandbox from Organization limit 1];
		String csvheader = 'Cash entry, Date, Type, Payment method, Value, Company, Period, Reference, Status, Message\n';
		String todaystr = DateTime.now().format('yyyy-MM-dd');
		List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
		List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();
		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		//List<String> recipients = new List<String>{ UserInfo.getUserEmail() };
		List<String> recipients = new List<String>(Utility.getGroupMbrUserEmails('CashEntryAutoPostDT'));
		if (org.isSandbox) recipients = new List<String>{UserInfo.getUserEmail()};
		if (recipients.size()==0) recipients.add(UserInfo.getUserEmail());

		//if (!org.isSandbox) recipients.add('another.email@mobilityworks.com');
		mail.setToAddresses(recipients); 
		mail.setSubject('Cash Entry posting complete - UPDATES');
		String body = 'Cash Entry posting has completed.\n';
		if (!doUpdate) body += 'Test only! NOT Updated!\n';
		mail.setPlainTextBody(body);

		Messaging.EmailFileAttachment resultcsv = new Messaging.EmailFileAttachment();
			resultcsv.setContentType('text/csv');
			resultcsv.setFileName('CashPosting ' + todaystr + '.csv');
			resultcsv.setInline(false);
			resultcsv.Body = Blob.valueOf(csvheader + String.join(resultmap.values(),'\n'));
			if (resultmap.size()>0) listOfAttachments.add(resultcsv);
		Messaging.EmailFileAttachment upderrors = new Messaging.EmailFileAttachment();
			upderrors.setContentType('text/csv');
			upderrors.setFileName('PostingErrors ' + todaystr + '.csv');
			upderrors.setInline(false);
			upderrors.Body = Blob.valueOf(csvheader + String.join(errormap.values(), '\n'));
			if (errormap.size()>0) listOfAttachments.add(upderrors);
		mail.setFileAttachments(listOfAttachments);
		emailMsgs.add(mail);

		// Only send if records were selected for processing...
		if (resultmap.size()>0 || errormap.size()>0) Messaging.sendEmail(emailMsgs);
		
		// Reset to clear HEAP
		resultmap = new Map<Id,String>();
		errormap = new Map<Id,String>();
		
	}


	// Schedulable context
	global void execute(SchedulableContext ctx) {
		System.debug('CashEntryAutoPostDT.execute (schedule)');
		String maxrcds = Test.isRunningTest() ? '1' : null;
		List<BatchSchedule__c> bss = [
			select Name, ClassName__c, CronSchedule__c, Parameters__c, ScheduledJobId__c, Active__c, BatchSize__c
			from BatchSchedule__c
			where ScheduledJobId__c=:ctx.getTriggerId()
		];
		BatchSchedule__c bs = bss.size()>0 ? bss[0] : new BatchSchedule__c(Parameters__c='',Active__c=true);
		List<Object> runparams = new List<Object>();
		// default run params (no dynamic params specified)
		ScheduleParameters sp = new ScheduleParameters('< TODAY');
		runparams.add(sp);
		if (!String.isBlank(bs.Parameters__c)) runparams = (List<Object>) JSON.deserializeUntyped(bs.Parameters__c);
		else runparams.add(new Map<String,Object>());	// default to 1 empty map to run once with default params!
		for(Object o : runparams) {
			Map<String,Object> params = (Map<String,Object>) o; 
			String dateselector = (String) params.get('DateSelector');
			if (bs==null || bs.Active__c) {
				CashEntryAutoPostDT b = new CashEntryAutoPostDT(maxrcds, true, null, dateselector, null, null);
				Database.executeBatch(b, 1);
			}
		}
	}

	// scheduleMe self-scheduler
	public static List<String> scheduleMe() {
		System.debug('CashEntryAutoPostDT.scheduleMe');
		String thisClassName = CashEntryAutoPostDT.class.getName();
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
			for(String cron : CashEntryAutoPostDT.CRON_LIST) {
				String params = '';
				if (!String.isBlank(params)) params += ',';
				params += '{'
					+ '"DateSelector":"' + CRON_SELECTOR[i]  + '"'
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
		CashEntryAutoPostDT m = new CashEntryAutoPostDT(null, true, null, null, null, null);
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

	// ScheduleParameters
	public class ScheduleParameters {
		public String DateSelector {get;set;}
		public ScheduleParameters(String ds) {
			DateSelector = ds;
		}
	}

}