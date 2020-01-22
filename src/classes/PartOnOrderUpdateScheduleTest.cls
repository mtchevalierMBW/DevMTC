@isTest
private class PartOnOrderUpdateScheduleTest {

    /** test the Schedulable interface **/
    static testMethod void unitTest() {

            Test.startTest();
        
                String CRON_EXP = '0 0 0 1 1 ? 2025';  
                String jobId = System.schedule('testPurchaseOrderUpdateApex', CRON_EXP, new PartOnOrderUpdateSchedulable() );
                
                CronTrigger ct = [select id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where id = :jobId];
                
                System.assertEquals(CRON_EXP, ct.CronExpression); 
                System.assertEquals(0, ct.TimesTriggered);
                System.assertEquals('2025-01-01 00:00:00', String.valueOf(ct.NextFireTime));

            Test.stopTest();
    }
}