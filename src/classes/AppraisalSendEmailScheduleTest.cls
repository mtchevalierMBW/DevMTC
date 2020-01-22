/*
**
* Date            |Developer            |Work#
* Notes
* --

*2016.08.04       |Sneha                |W-000461
*   Test class to cover the batch class for email alerts with no activity
*/

@isTest
public class AppraisalSendEmailScheduleTest{

    // unitTest  
    static testMethod void unitTest() {                
        
        //appraisal older then 30 days
        dealer__Appraisal__c appraisal = new dealer__Appraisal__c(dealer__Status__c='Pending');
        insert appraisal;
        Date date1 = Date.today()-30;
        Test.setCreatedDate(appraisal.Id, date1);
        
        //appraisal older then 27 days
        dealer__Appraisal__c appraisal1 = new dealer__Appraisal__c(dealer__Status__c='Pending');
        insert appraisal1;
        Date date2 = Date.today()-27;
        Test.setCreatedDate(appraisal1.Id, date1);
        
        List<dealer__Appraisal__c> listAppraisal = [select id,createddate from dealer__Appraisal__c];
        System.debug('list Appraisal - '+listAppraisal );
        
        String CRON_EXP = '0 0 0 15 3 ? 2022';
        
        Test.startTest();
        
        // Schedule the test job
        String jobId = System.schedule('ScheduleEmailTest',CRON_EXP, new AppraisalSendEmailSchedule());
        
        Test.stopTest();
    }
}