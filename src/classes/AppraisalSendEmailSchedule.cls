/*
**
* Date            |Developer            |Work#
* Notes
* --

*2016.08.04       |Sneha                |W-000461
*   Send warning email/lost email alert if no activity
*2017-01-25			|Jarrett			|IR 6579
* Dont send lost email if related to a deal
*/
global class AppraisalSendEmailSchedule implements Schedulable {
   global void execute(SchedulableContext sc) {
   
      String query = 'select id,CreatedDate,LastModifiedDate,Last_Warning_Email_Sent__c,Send_Lost_Email__c,Send_Warning_Email__c from dealer__Appraisal__c where createddate!=LAST_N_DAYS:25 and dealer__Status__c!=\'Won\' and dealer__Status__c!=\'Lost\' and dtmob__Deal__c=null';
      
      AppraisalSendEmailBatch b = new AppraisalSendEmailBatch(query); 
      database.executebatch(b);
   }
}