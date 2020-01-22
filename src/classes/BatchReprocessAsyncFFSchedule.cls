/**
 * BatchReprocessAsyncFFSchedule
 * Tested by: BatchReprocessAsyncFFSchedule_TEST
 * Date: Sep 26, 2016
 * Programmer: Bryan Leaman
 *
 * Schedule string format: "Seconds Minutes Hours Day_of_month Month Day_of_week Optional_year"
 * 	Hours 0-23 or , - * /
 * 	Day_of_month 1-31 or , - * ? / L W
 *	Month 1-12, JAN-DEC or , - * /
 *	Day_of_week 1-7, SUN-SAT or , - * ? / L #
 *	Optional_year null, 1970–2099 or , - * /
	 Special Character	Description
	,	Delimits values. For example, use JAN, MAR, APR to specify more than one month.
	-	Specifies a range. For example, use JAN-MAR to specify more than one month.
	*	Specifies all values. For example, if Month is specified as *, the job is scheduled for every month.
	?	Specifies no specific value. This is only available for Day_of_month and Day_of_week, and is generally used when specifying a value for one and not the other.
	/	Specifies increments. The number before the slash specifies when the intervals will begin, and the number after the slash is the interval amount. For example, if you specify 1/5 for Day_of_month, the Apex class runs every fifth day of the month, starting on the first of the month.
	L	Specifies the end of a range (last). This is only available for Day_of_month and Day_of_week. When used with Day of month, L always means the last day of the month, such as January 31, February 29 for leap years, and so on. When used with Day_of_week by itself, it always means 7 or SAT. When used with a Day_of_week value, it means the last of that type of day in the month. For example, if you specify 2L, you are specifying the last Monday of the month. Do not use a range of values with L as the results might be unexpected.
	W	Specifies the nearest weekday (Monday-Friday) of the given day. This is only available for Day_of_month. For example, if you specify 20W, and the 20th is a Saturday, the class runs on the 19th. If you specify 1W, and the first is a Saturday, the class does not run in the previous month, but on the third, which is the following Monday.

 Schedule it:
	BatchReprocessAsyncFFSchedule.scheduleMe();
 **/
global class BatchReprocessAsyncFFSchedule implements Schedulable {

	public static List<String> CRON_LIST = new List<String>{'0 0 20 * * ?'};	// Daily at 8:05 p.m. EST))

	global void execute(SchedulableContext ctx) {
   		//CronTrigger ct = [
   		//	SELECT Id, CronExpression, TimesTriggered, NextFireTime
		//	FROM CronTrigger 
		//	WHERE Id = :ctx.getTriggerId()
		//];
   	
		BatchReprocessAsyncFF b = new BatchReprocessAsyncFF(null, true);
		Database.executeBatch(b, 1);
	}

	// self-scheduler
	public static List<String> scheduleMe() {
		List<String> jobIds = new List<String>();
		BatchReprocessAsyncFFSchedule m = new BatchReprocessAsyncFFSchedule();
		Integer i = 0;
		for(String cron : BatchReprocessAsyncFFSchedule.CRON_LIST) {
			System.debug(cron);
			String jobname = 'BatchReprocessAsyncFFSchedule_' + String.valueOf(++i);
			if (Test.isRunningTest()) jobname += '_TEST';
			jobIds.add(System.schedule(jobname, cron, m));
		}
		return jobIds;
	}

}