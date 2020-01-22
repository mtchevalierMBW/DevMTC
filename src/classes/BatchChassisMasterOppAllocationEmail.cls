/**
 * BatchLightningNoteMigration
 * 
 * Created By: Alexander Miller
 * Created Date: 10/2/2018 
 * Tested By: BatchChassisMasterOppAllocationEmailTest
 * Work Item: W-000464
 *
 * Batch class which scans over the system for any Chassis which 
 * is 
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 * Alexander Miller    AMM1        IR-0044980    12/4/2018   This email logic should exclude deals that are essentially fully won or lost
 * Alexander Miller    AMM2        IR-0055065    05/23/2019  Update for new Opportunities Statuses
 */
global class BatchChassisMasterOppAllocationEmail implements Database.Batchable<sObject>, Schedulable, Database.Stateful {

    public static Id emailId;

    public BatchChassisMasterOppAllocationEmail(){}

	global void execute(SchedulableContext SC) 
    {        
        BatchChassisMasterOppAllocationEmail thisBatch = new BatchChassisMasterOppAllocationEmail();
        database.executeBatch(thisBatch, 1); 
    }

 	global Database.QueryLocator start(Database.BatchableContext BC) 
    {
        // Go-Live Query
        //String query = 'SELECT Id, OwnerId, Owner.Email FROM Chassis_Master__c WHERE Opportunity_Allocation__c != null AND Opportunity_Allocation_Date__c = ' + getSOQLDateConverter(getNumberOfDays());

        // Dev Query
        // AMM1
        //String query = 'SELECT Id, OwnerId, Owner.Email FROM Chassis_Master__c WHERE Opportunity_Allocation__c != null AND Opportunity_Allocation_Date__c = ' + getSOQLDateConverter(getNumberOfDays()); 
        // AMM2
        //String query = 'SELECT Id, OwnerId, Owner.Email FROM Chassis_Master__c WHERE Opportunity_Allocation__c != null AND Opportunity_Allocation__r.Status__c != \'Won\' AND Opportunity_Allocation__r.Status__c != \'Pending - Order Entry Review\' AND Opportunity_Allocation__r.Status__c != \'Lost\' AND Opportunity_Allocation_Date__c = ' + getSOQLDateConverter(getNumberOfDays()); 
        String query = 'SELECT Id, OwnerId, Owner.Email FROM Chassis_Master__c WHERE Opportunity_Allocation__c != null AND Opportunity_Allocation__r.Status__c != \'Won\' AND Opportunity_Allocation__r.Status__c != \'Order Submitted to Order Entry\' AND Opportunity_Allocation__r.Status__c != \'Order Written Waiting Proofed\' AND Opportunity_Allocation__r.Status__c != \'Lost\' AND Opportunity_Allocation_Date__c = ' + getSOQLDateConverter(getNumberOfDays());    
        // AMM2
        // AMM1

        System.debug(query);

        if(Test.IsRunningTest())
        {
            // AMM1
            //query = 'SELECT Id, OwnerId, Owner.Email FROM Chassis_Master__c WHERE Opportunity_Allocation__c != null AND Opportunity_Allocation_Date__c != null LIMIT 1' ;  
            // AMM2
            // query = 'SELECT Id, OwnerId, Owner.Email FROM Chassis_Master__c WHERE Opportunity_Allocation__c != null AND Opportunity_Allocation__r.Status__c != \'Won\' AND Opportunity_Allocation__r.Status__c != \'Pending - Order Entry Review\' AND Opportunity_Allocation__r.Status__c != \'Lost\' AND Opportunity_Allocation_Date__c != null LIMIT 1';
            query = 'SELECT Id, OwnerId, Owner.Email FROM Chassis_Master__c WHERE Opportunity_Allocation__c != null AND Opportunity_Allocation__r.Status__c != \'Won\' AND Opportunity_Allocation__r.Status__c != \'Order Submitted to Order Entry\' AND Opportunity_Allocation__r.Status__c != \'Order Written Waiting Proofed\' AND Opportunity_Allocation__r.Status__c != \'Lost\' AND Opportunity_Allocation_Date__c != null LIMIT 1';
            // AMM2
            // AMM1
        }
        
        return Database.getQueryLocator(query);
    }

	global void execute(Database.BatchableContext BC, List<Chassis_Master__c> chassisList)
    {
        if(emailId == null)
        {
            emailId = getTemplateId();
        }

        List<Messaging.SingleEmailMessage> listOfEmailRecords = new List<Messaging.SingleEmailMessage>();

        for(Chassis_Master__c tempChassis : chassisList)
        {
            // 1. Get CC emails
            List<String> listOfEmails = getListOfCcEmails();

            // 2. Compile the emails
            listOfEmailRecords.add(getEmailRecord(listOfEmails, tempChassis.OwnerId, tempChassis.Id,emailId));
        }

        // 3. Send the emails in on block
        Messaging.SendEmailResult[] r = Messaging.sendEmail(listOfEmailRecords);
        
        for(Messaging.SendEmailResult tempResult : r)
        {
            System.debug(tempResult.getErrors());
		}
    }

	global void finish(Database.BatchableContext BC) {}

    /**
    * getNumberOfDays
    *
    * Function which looks at the custom setting for the number of days
    * which the batch class should wait before firing. The count
    * is number of days
    */
    public Integer getNumberOfDays()
    {
        TransitForceSettings__c OpportunityAllocation = TransitForceSettings__c.getInstance();
        
        System.debug(OpportunityAllocation);

        return Integer.valueOf(OpportunityAllocation.Opp_Allocation_Days__c);
    }

    /**
    * getSOQLDateConverter
    *
    * Function which converts the number of days into
    * a SOQL-friendly format based on the day this batch runs.
    *
    * For example: if the date was 1/8/2018 when the batch ran 
    * and the numberOfDays parameter was set to "2", then
    * the String would return: 2018-1-06T00:00:00Z
    */
    public String getSOQLDateConverter(Integer numberOfDays)
    {
        Date tempDateTime = Date.Today();

        Integer actualDayReduction = numberOfDays * -1;

        tempDateTime = tempDateTime.addDays(actualDayReduction);  

        System.debug(tempDateTime);

        return String.valueOf(tempDateTime);
    }

    /**
    * getListOfCcEmails
    *
    * Function which looks at the custom setting for the coma
    * separated list of emails to be included on all emails 
    * coming from this batch class
    */
    public List<String> getListOfCcEmails()
    {
        TransitForceSettings__c OpportunityAllocation = TransitForceSettings__c.getInstance();

        List<String> listOfEmails = new List<String>();

        for(String temp : OpportunityAllocation.Chassis_Opp_Email_CC_List__c.split(','))
        {
            listOfEmails.add(temp);
        }

        return listOfEmails;
    }

    /**
    * getTemplateId
    *
    * Function which looks at the custom setting for the API
    * name of the email template to be used so one query is 
    * consumed in the batch class for better processing.
    *
    * Then the function grabs the Id of the template through a query
    */
    public Id getTemplateId()
    {
        TransitForceSettings__c OpportunityAllocation = TransitForceSettings__c.getInstance();
        
        System.debug(OpportunityAllocation);

        return [SELECT Id 
                FROM EmailTemplate 
                WHERE developername = : String.valueOf(OpportunityAllocation.Chassis_Opp_Email_Template__c)].id;
    }

    /**
    * getEmailRecord 
    *
    * Function which creates the email 
    * using the emails for To and CC
    * along with the record and user
    * intended for the email. 
    */
    public Messaging.SingleEmailMessage getEmailRecord(String[] ccRecipients, Id userId, Id whatId, Id templateId)
    {
        Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(templateId, userId, whatId);

        String emailSubject = email.getSubject();
        String emailTextBody = email.getPlainTextBody();

        email.setTargetObjectId(userId);
        email.setCcAddresses(ccRecipients);
        email.setSubject(emailSubject);
        email.setPlainTextBody(emailTextBody);
        email.saveAsActivity = false;

        return email;
    }
}