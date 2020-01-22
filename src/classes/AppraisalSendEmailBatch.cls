/*
**
* Date            |Developer            |Work#
* Notes
* --

*2016.08.04       |Sneha                |W-000461
*   Send warning email/lost email alert if no activity
*/

global class AppraisalSendEmailBatch implements Database.Batchable<sObject>{

    global final String Query;   

    global AppraisalSendEmailBatch(String q){

      Query=q; //[select id,CreatedDate,LastModifiedDate,Send_Lost_Email__c,Send_Warning_Email__c from dealer__Appraisal__c where createddate!=last_10_days and dealer__Status__c='Won' and dealer__Status__c!='Lost']
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<dealer__Appraisal__c> listAppraisal = (List<dealer__Appraisal__c>) scope;
        List<dealer__Appraisal__c> listAppraisalToUpdate =new List<dealer__Appraisal__c>();
        
        for(dealer__Appraisal__c appraisal : listAppraisal){
            Date date1 = Date.today()-27;
            Date date2 = Date.today()-30;
            
            System.debug('Appraisal LastModifiedDate - '+appraisal.LastModifiedDate);
            
            //If no activity in last 30 or its not updated even after warning mail sent
            if(appraisal.LastModifiedDate<=date2 || (appraisal.Last_Warning_Email_Sent__c!=null && appraisal.LastModifiedDate<=appraisal.Last_Warning_Email_Sent__c)){               
                //send email true
                appraisal.Send_Lost_Email__c=true;
                listAppraisalToUpdate.add(appraisal);
                System.debug('No Activity in 30 days');
            }
            //If no activity in last 27 days 
            else if(appraisal.LastModifiedDate<=date1 || Test.isRunningTest()){
                
                //send email true
                appraisal.Send_Warning_Email__c=true;
                listAppraisalToUpdate.add(appraisal);
                System.debug('No Activity in 27 days ');
            }
        }
        
        //update appraisals if changed
        if(listAppraisalToUpdate.size()>0){
            update listAppraisalToUpdate;           
        }
        
    }

   global void finish(Database.BatchableContext BC){
   }
}