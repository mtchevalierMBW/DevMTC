/**
* WMK (c) - 2019
*
* ReportExporterScheduleTWTest
* 
* Programmer: Alexander Miller
* Date: 3/18/2019
* Work Item:  W-000623
*
* Modified By         Alias       Work Item       Date     Reason
* -----------------------------------------------------------------
*
*/
@isTest(SeeAllData='true')
public class ReportExporterScheduleTWTest {
       
    public static String CRON_EXP = '0 0 0 15 3 ? 2022';

    static testmethod void test() 
    {
        Test.startTest();                    
        
        // Schedule the test job
        String jobId = System.schedule('ScheduleApexClassTWTest',
                        CRON_EXP,
                        new ReportExporterScheduleTW());
            
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered,
            NextFireTime
            FROM CronTrigger WHERE id = :jobId];
    
        // Verify the expressions are the same
        System.assertEquals(CRON_EXP,
            ct.CronExpression);
    
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
    
        // Verify the next time the job will run
        System.assertEquals('2022-03-15 00:00:00',
            String.valueOf(ct.NextFireTime));
        Test.stopTest();
    
    }
}