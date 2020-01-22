/**
 * BatchSchedule
 * Tested by: BatchRunTests__TEST, 	// not needed yet: BatchSchedule_TEST
 * Date: Mar 29, 2018
 * Programmer: Bryan Leaman
 *
 * Code coverage:
 *	2018-03-28	82% (46/56) 
 *
 */
 
 /** example usage - replace {mybatchclassname} with actual batch class name

 	// execute - Schedulable interface
	global void execute(SchedulableContext ctx) {
		BatchSchedule bs = new BatchSchedule(ctx);
		String parmstr = bs.JobParameterString;
		// optional: parse parameter string into several parameters for more complex solutions
		BatchRunTests b = new {mybatchclassname}(parmstr);
		if (bs.Active) Database.executeBatch(b, bs.BatchSize);
	}


	// scheduleMe self-scheduler to assist in creating a new schedule or rescheduling jobs based on the batch schedule custom setting
	public static List<Id> scheduleMe() {
		String thisClassName = {mybatchclassname}.class.getName();
		BatchSchedule bs = new BatchSchedule(thisClassName);
		
		// First remove existing scheduled jobs that are recorded in the BatchSchedule__c custom setting ... 
		bs.removeScheduledJobs(thisClassName);

		// set default schedule if none found
		if (bs.scheduleEntries.size()==0) {
			bs.newJob('0 0 7 * * ? *', 'parmstr', 200);	// daily at 7 a.m., no parameters, batch size=200
			bs.newJob('0 30 13 * ? MON-FRI *', 'parmstr', 200);	// M-F at 1:30 p.m., no parameters, batch size=200
		}
		
		// Now schedule the jobs that are in the BatchSchedule list for this class
		{myclassname} bc = new {myclassname}();
		return bs.createScheduleEntries(bc);
	}
 
 **/
 
public with sharing class BatchSchedule {

	private String className=null;
	public BatchSchedule__c scheduleEntry {get;set;}
	public String JobParameterString {get;private set;}
	public Integer BatchSize {get;private set;}
	public boolean Active {get;private set;}
	public List<BatchSchedule__c> scheduleEntries {get;set;}

	// BatchSchedule constructor from class name
	//---------------------------------------
	public BatchSchedule(String cn) {
		className = cn;
		scheduleEntries = jobEntries(className);
	}
	
	// BatchSchedule constructor from running scheduled job 
	public BatchSchedule(SchedulableContext ctx) {
		scheduleEntry = runningJobSpec(ctx);
		JobParameterString = scheduleEntry.Parameters__c;
		BatchSize = Integer.valueOf(scheduleEntry.BatchSize__c);
		Active = scheduleEntry.Active__c;
		className = scheduleEntry.ClassName__c;
		// should not be needed: scheduleEntries = jobEntries(className);
	}
	
	// getRunningJobSpec
	private BatchSchedule__c runningJobSpec(SchedulableContext ctx) {
		return [
			select Name, ClassName__c, CronSchedule__c, Parameters__c, ScheduledJobId__c, Active__c, BatchSize__c
			from BatchSchedule__c
			where ScheduledJobId__c=:ctx.getTriggerId()
			limit 1
		];
	}
	
	// getJobEntries
	private List<BatchSchedule__c> jobEntries(String cn) {
		return [
			select Name, ClassName__c, CronSchedule__c, Parameters__c, ScheduledJobId__c, Active__c, BatchSize__c
			from BatchSchedule__c 
			where ClassName__c=:ClassName
		];
	}

	// removeScheduledJobs
	public Integer removeScheduledJobs(String classname) {
		Integer i=0;
		for(BatchSchedule__c bs : scheduleEntries) {
			try {
				if (!String.isBlank(bs.ScheduledJobId__c)) System.abortJob((Id) bs.ScheduledJobId__c);
				++i;
			} catch(Exception e) {System.debug(e);}
		}
		return i;
	}

	// newJob - add a new scheduled job entry to the list
	// this won't save the enty - you have to call "createScheduleEntries" for that
	public void newJob(String cron, String params) {
		newJob(cron, params, 200, true);
	}
	public void newJob(String cron, String params, Integer batchsize) {
		newJob(cron, params, batchsize, true);
	}
	public void newJob(String cron, String params, Integer batchsize, boolean active) {
		String nbr = String.valueOf(scheduleEntries.size()+1);
		String name = className.left(39-nbr.length()) + '_' + nbr;
		BatchSchedule__c job = new BatchSchedule__c(
			Name = name,
			ClassName__c = className,
			CronSchedule__c = cron,
			Parameters__c = params,
			Active__c = true
		);
		scheduleEntries.add(job);
	}
	
	// createScheduleEntries
	public List<Id> createScheduleEntries(Schedulable schedulableclass) {
		List<String> jobIds = new List<String>();
		for(BatchSchedule__c bs : scheduleEntries) {
			System.debug(bs.CronSchedule__c);
			String jobname = bs.Name;
			if (Test.isRunningTest()) jobname += '_TEST';
			if (bs.Active__c) {
				Id jobId = System.schedule(jobname, bs.CronSchedule__c, schedulableclass);
				bs.ScheduledJobId__c = jobId;
				jobIds.add(jobId);
			}
		}
		upsert(scheduleEntries);
		return jobIds;
	}

	// save
	public void save() {
		upsert(scheduleEntries);
	}
}