/**
 * BatchRunTests
 * Tested by: BatchRunTests_TEST
 * Date: Mar 15, 2018
 * Programmer: Bryan Leaman
 * 
 * Run it now:
Database.executeBatch(new BatchRunTests(null, true));

 * Set standard schedule:
BatchRunTests.scheduleMe();

 * Set custom schedule:
System.schedule('BatchRunTests', 'sec min hr day mth wd year', new BatchRunTests(null,true));
 
 * Code coverage:
 *	2018-03-15	100% (33/33)
 *	2018-03-29	100% (60/60)
 *	
 */
global class BatchRunTests implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
	//global final String query;
	global boolean doUpdate;
	global String NamespacePfx;
	global String NamePattern;
    global String errmsgs;
    global String results;

    public static final List<String> CRON_LIST = new List<String>{
    	'0 30 6 ? * MON-FRI *'		// 7 a.m. daily, M-F
    };

	// Run multiple selections of namespace & class name patterns
	public static final List<String> CRON_NAMESPACE = new List<String>{
		'c2g', 'rstk', ''
	};
	public static final List<String> CRON_CLASSNAME = new List<String>{
		'CODAAPI%Test%', 'TestF%', '%'
	};
    

	// BatchRunTests constructor - generate query string & initialize
	global BatchRunTests(String rcdlimit, boolean doUpd) {
		this(null, '%', rcdlimit, doUpd);
	}
	global BatchRunTests(String namespace, String classname, String rcdlimit, boolean doUpd) {
		doUpdate = doUpd;
		NamespacePfx = namespace;
		NamePattern = classname;
		//String soql = 
		//	'Select Id, Name, NamespacePrefix '
		//	+ 'From ApexClass '
		//	+ 'Where NamespacePrefix=null and (Name like \'%_TEST\' or Name like \'%_TC\') ';
		//if (!String.isBlank(rcdlimit))	soql += 'Limit ' + rcdlimit + ' ';
		//query = soql;
		errmsgs = '';
		results = '';
	}


	// start - query the database
	//global Database.QueryLocator start(Database.BatchableContext bc) {
	//	return Database.getQueryLocator(query);
	//}

	global Iterable<sObject> start(Database.BatchableContext bc) {
		List<ApexClass> objs = new List<ApexClass>();
		if (String.isBlank(NamespacePfx)) {
			String sosl = 'FIND \'@isTest\' in ALL FIELDS '
				+ 'RETURNING ApexClass (' 
				+ 'Id, Name, NamespacePrefix ' 
				+ 'WHERE Name like \'' + NamePattern + '\' '  
				+ ')';
			List<List<sObject>> objlist = Search.query(sosl);
			objs = objlist[0];
		} else {
			String soql = 'select Id, Name, NamespacePrefix '
				+ 'from ApexClass '
				+ 'where NamespacePrefix=\'' + NamespacePfx + '\' and Name like \'' + NamePattern + '\' ';
			objs = Database.query(soql);	
		}
		return objs;
	}

	// execute for a batch of records
	global void execute(Database.BatchableContext bc, List<sObject> scope) {
		List<ApexClass> objs = (List<ApexClass>) scope;
		System.debug('Record count: ' + String.valueOf(objs.size()));
		List<ApexTestQueueItem> queueItems = new List<ApexTestQueueItem>();

		// Run tests
		for(ApexClass o : objs) {
				queueItems.add(new ApexTestQueueItem(
					ApexClassId=o.Id
				));
		}
		
		System.debug('Number of test classes to run: ' + String.valueOf(queueItems.size()));
		
		// Queue tests
		if (queueItems.size()>0 && !Test.isRunningTest()) Database.insert(queueItems);

	}
	
	// finish - send results via email
	global void finish(Database.BatchableContext bc) {
	}

	
	// schedulable interface
	//==========================

	// execute
	global void execute(SchedulableContext ctx) {
		String maxrcds = Test.isRunningTest() ? '1' : null;
		BatchSchedule bs = new BatchSchedule(ctx);
		String parmstr = bs.JobParameterString;
		System.debug(parmstr);
		List<Object> runparams = new List<Object>();
		if (!String.isBlank(parmstr)) runparams = (List<Object>) JSON.deserializeUntyped(parmstr);
		for(Object o : runparams) {
			Map<String,Object> params = (Map<String,Object>) o; 
			String namespace = (String) params.get('Namespace');
			String classname = (String) params.get('Classname');
			BatchRunTests b = new BatchRunTests(namespace, classname, maxrcds, true);
			if (bs.Active) Database.executeBatch(b, bs.BatchSize);
		}
	}


	// scheduleMe self-scheduler
	public static List<Id> scheduleMe() {
		String thisClassName = BatchRunTests.class.getName();
		BatchSchedule bs = new BatchSchedule(thisClassName);
		
		// First remove existing scheduled jobs ... 
		bs.removeScheduledJobs(thisClassName);

		// set default schedule if none found
		if (bs.scheduleEntries.size()==0) {
			for(String cron : BatchRunTests.CRON_LIST) {
				String params = '';
				for(Integer j=0; j<CRON_NAMESPACE.size(); ++j) {
					if (!String.isBlank(params)) params += ',';
					params += '{"Namespace":"' + CRON_NAMESPACE[j] + '", '
							+ '"Classname":"' + CRON_CLASSNAME[j] + '"}';
				}
				params = '[' + params + ']';
				bs.newJob(cron, params, 500, true);
			}
		}
		
		// Now schedule the jobs that are in the BatchSchedule list for this class based on an instance of the class
		BatchRunTests m = new BatchRunTests(null, true);
		return bs.createScheduleEntries(m);
	}


}