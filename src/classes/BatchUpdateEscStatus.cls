/**
 * BatchUpdateEscStatus
 * Tested by: BatchUpdateEscStatus_TEST
 * Date: Dec 19, 2017
 * Programmer: Bryan Leaman
 * Code coverage:
 *  2017-12-20  92% (83/90)
 *  2018-05-03  85% (106/124)
 *
 * Description:
 * Correct the contract status (null, Active, Expired) for these ESCs:
 *   Set contract status to active for: Service contracts sold on a delivered (or posted) proposal with no contract status
 *   Set contract status to NOT active for: Service contracts on a Non-delivered (or posted) proposal
 *   Re-evaluate active status for contracts that are Active (evaluate for expiration).
 *   Don't re-activate (status) if marked inactive (flag) or & owner is different from proposal client.
 * 
 * Run it now:
Database.executeBatch(new BatchUpdateEscStatus(null, true));

 * Set standard schedule:
BatchUpdateEscStatus.scheduleMe();

 * Set custom schedule:
System.schedule('BatchUpdateEscStatus', 'sec min hr day mth wd year', new BatchUpdateEscStatus(null,true));
 
 */
global class BatchUpdateEscStatus implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
    global final String query;
    global boolean doUpdate;
    global String errmsgs;
    //global String results;
    global Map<Id,String> resultmap;
    public static final List<String> CRON_LIST = new List<String>{
        '0 0 7 * * ? *'     // 7 a.m. daily
    };
    
    

    // BatchUpdateEscStatus constructor - generate query string & initialize
    global BatchUpdateEscStatus(String rcdlimit, boolean doUpd) {
        doUpdate = doUpd;
        String soql = 
            'Select Id, Name, Active__c, dealer__Service_Vehicle__c, dealer__Start_Date__c, dealer__End_Date__c, dealer__Odometer_at_Sale__c, dealer__Status__c, dealer__Customer__c, '
            + 'Minimum_MIleage__c, Maximum_MIleage__c, dealer__Expiration_Mileage__c, dealer__Expiration_Months__c, '
            + 'Exp_Miles_Add_to_Odometer__c, '
            + 'dealer__Service_Vehicle__r.dealer__Last_Odometer__c, dealer__Service_Vehicle__r.dealer__Veh_Owner__c, dealer__Service_Vehicle__r.dealer__Last_Service__c, ' 
            + 'dealer__Car_Deal__c, dealer__Car_Deal__r.dealer__Status__c, '
            + 'dealer__Car_Deal__r.dealer__Mileage__c, dealer__Car_Deal__r.dealer__Buyer__c, '
            + 'dealer__Car_Deal__r.dealer__Vehicle__c, dealer__Car_Deal__r.dealer__Vehicle__r.dealer__Service_Vehicle__c, dealer__Car_Deal__r.dealer__Service_Vehicle__c '
            + 'From dealer__Service_Contract__c '
            + 'Where (dealer__Status__c=null and dealer__Car_Deal__c!=null and dealer__Car_Deal__r.dealer__Status__c in (\'Won - Delivered\', \'Won - Posted\') )'  // sold on a delivered deal
            + ' or (dealer__Status__c!=null and dealer__Car_Deal__c!=null and dealer__Car_Deal__r.dealer__Status__c != \'Won - Delivered\' and dealer__Car_Deal__r.dealer__Status__c != \'Won - Posted\')'  // not sold on a deliverd deal
            + ' or dealer__Status__c=\'Active\' ';  // re-evaluate active ones for expiration!
        //if (!Test.isRunningTest()) soql += 'and (condition) ';
        //soql += 'Order by CreatedDate desc ';
        if (!String.isBlank(rcdlimit))  soql += 'Limit ' + rcdlimit + ' ';
        query = soql;
        errmsgs = '';
        //results = '';
        resultmap = new Map<Id,String>();
    }


    // start - query the database
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }


    // execute for a batch of records
    global void execute(Database.BatchableContext bc, List<sObject> scope) {
        List<dealer__Service_Contract__c> objs = (List<dealer__Service_Contract__c>) scope;
        System.debug('Record count: ' + String.valueOf(objs.size()));
        Date today = Date.today();

        //Set<Id> srvVehIds = new Set<Id>();
        //for(dealer__Service_Contract__c o : objs) {
        //  
        //}
        
        //Map<Id,String> dealEscSts = new Map<Id, String>();
        //for(dealer__Service_Contract__c o : objs) {
        //  
        //}

        // Update
        List<dealer__Service_Contract__c> updObjs =new List<dealer__Service_Contract__c>();
        for(dealer__Service_Contract__c o : objs) {
            String newstatus = null;
            Boolean newActive = o.Active__c;
            Decimal newmileage = o.dealer__Odometer_at_Sale__c;
            Decimal expmiles_absolute = o.dealer__Expiration_Mileage__c!=null ? o.dealer__Expiration_Mileage__c : null;
            if (expmiles_absolute!=null && o.Exp_Miles_Add_to_Odometer__c==true && o.dealer__Odometer_at_Sale__c!=null) expmiles_absolute += o.dealer__Odometer_at_Sale__c;

            // mileage at sale
            if (newmileage==null && o.dealer__Car_Deal__r!=null && o.dealer__Car_Deal__r.dealer__Mileage__c!=null
                && o.dealer__Car_Deal__r.dealer__Mileage__c!=0) newmileage = o.dealer__Car_Deal__r.dealer__Mileage__c;  

            // determine status
            if (o.dealer__Car_Deal__r.dealer__Status__c=='Won - Delivered' || o.dealer__Car_Deal__r.dealer__Status__c=='Won - Posted') newstatus = 'Active';

            // apply expiration data
            if (o.dealer__Start_Date__c!=null && o.dealer__Start_Date__c>today) newstatus = null;
            if (o.dealer__End_Date__c!=null && o.dealer__End_Date__c<today && newstatus=='Active') newstatus='Expired';
            if (expmiles_absolute<o.dealer__Service_Vehicle__r.dealer__Last_Odometer__c && newstatus=='Active') newstatus='Expired';
             
            // Forced inactive or different owner -- don't touch status (allowing manual override/setting)
            if (o.Active__c==false || o.dealer__Service_Vehicle__r.dealer__Veh_Owner__c!=o.dealer__Customer__c) newstatus = null;
            
            dealer__Service_Contract__c updrcd = new dealer__Service_Contract__c(Id=o.Id); 
            if ((newstatus!=null && newstatus!=o.dealer__Status__c) || 
                (newmileage!=null && newmileage!=o.dealer__Odometer_at_Sale__c)) {
                updrcd.dealer__Status__c = newstatus!=null ? newstatus : o.dealer__Status__c;
                updrcd.dealer__Odometer_at_Sale__c = newmileage!=null ? newmileage : o.dealer__Odometer_at_Sale__c;
                updObjs.add(updrcd);
                resultmap.put(o.Id, o.Id + ',' + o.Name + ',' + updrcd.dealer__Status__c + ',' + updrcd.dealer__Odometer_at_Sale__c
                    + ',' + o.dealer__Customer__c );
            }
        }
        
        System.debug('Number of records to update: ' + String.valueOf(updObjs.size()));
        
        // Do updates!
        if (updObjs.size()>0)  {
            Database.SaveResult[] saveresults = new List<Database.SaveResult>();
            if (doUpdate) saveresults = Database.update(updObjs, false); 
            //System.debug(saveresults);
            System.debug('List of failed updates:');
            //for(Database.SaveResult sr : saveresults) {
            for(Integer i=0; i<updObjs.size(); i++) {
                dealer__Service_Contract__c o = updObjs[i];
                Database.SaveResult sr = saveresults.size()>i ? saveresults[i] : null;
                if (sr!=null && !sr.isSuccess()) {
                    String resultline = resultmap.get(o.Id);
                    String errmsg = '';
                    String errmsgline = o.Id + ',' 
                    + (o.dealer__Start_Date__c!=null ? DateTime.newInstance(o.dealer__Start_Date__c, Time.newInstance(0,0,0,0)).format('yyyy-MM-dd') : '' ) + ',' 
                    + o.dealer__Odometer_at_Sale__c + ',';
                    for(Database.Error de : sr.getErrors()) {
                        errmsgline += '[' + String.join(de.getFields(), ', ') + '] '
                            + de.getMessage() + '\r';
                        errmsg += de.getMessage() + '; ';
                    }
                    System.debug(errmsgline);
                    errmsgs += errmsgline;
                    errmsg = errmsg.replaceAll('\\s',' ');
                    if (o.Id!=null && resultline!=null) resultmap.put(o.Id,resultline+',"Error:'+errmsg+'"');
                }
            }
            System.debug('List complete.');
        }

        // Reset results & error messages if getting too large
        if (Limits.getLimitHeapSize() - Limits.getHeapSize() < 5000000){  // if less that 1 meg left
            sendEmail();
        }

    }
    
    
    // finish - send results via email
    global void finish(Database.BatchableContext bc) {
        sendEmail();
    }


    // sendEmail of the results 
    global void sendEmail() {
        Organization org = [select Id, Name, isSandbox from Organization limit 1];
        String csvheader = 'ESC Id, Name, Status, Odometer, Customer Id\n';
        List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
        List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> recipients = new List<String>{ UserInfo.getUserEmail() };
        //if (!org.isSandbox) recipients.add('another.email@mobilityworks.com');
        mail.setToAddresses(recipients); 
        mail.setSubject('Batch update ESC status complete - UPDATES');
        String body = 'Batch update ESC status has completed.\n\n';
        if (!doUpdate) body += 'Test only! NOT Updated!\n\n';
        mail.setPlainTextBody(body);
        
        Messaging.EmailFileAttachment resultcsv = new Messaging.EmailFileAttachment();
            String results = String.join(resultmap.values(),'\n');
            resultcsv.setContentType('text/csv');
            resultcsv.setFileName('SvcContractResults.csv');
            resultcsv.setInline(false);
            resultcsv.Body = Blob.valueOf(csvheader + String.join(resultmap.values(),'\n'));
            if (resultmap.size()>0) listOfAttachments.add(resultcsv);
        Messaging.EmailFileAttachment upderrors = new Messaging.EmailFileAttachment();
            upderrors.setContentType('text/plain');
            upderrors.setFileName('UpdateErrors.txt');
            upderrors.setInline(false);
            upderrors.Body = Blob.valueOf(errmsgs);
            if (!String.isBlank(errmsgs)) listOfAttachments.add(upderrors);
        mail.setFileAttachments(listOfAttachments);
        emailMsgs.add(mail);

        // Only send if records were selected for processing...
        if (resultmap.size()>0 || !String.isBlank(errmsgs)) Messaging.sendEmail(emailMsgs);
        
        // Reset to clear HEAP
        resultmap = new Map<Id,String>();
        errmsgs = '';
        
    }


    // Schedulable context
    global void execute(SchedulableContext ctx) {
        String maxrcds = Test.isRunningTest() ? '1' : null;
        BatchSchedule__c bs = [
            select Name, ClassName__c, CronSchedule__c, Parameters__c, ScheduledJobId__c, Active__c, BatchSize__c
            from BatchSchedule__c
            where ScheduledJobId__c=:ctx.getTriggerId()
        ];
    
        BatchUpdateEscStatus b = new BatchUpdateEscStatus(maxrcds, true);
        Database.executeBatch(b, (bs!=null ? (Integer) bs.BatchSize__c : 10));
    }

    // scheduleMe self-scheduler
    public static List<String> scheduleMe() {
        String thisClassName = BatchUpdateEscStatus.class.getName();
        // from schedule custom settings
        List<BatchSchedule__c> bss = [
            select Name, ClassName__c, CronSchedule__c, Parameters__c, ScheduledJobId__c, Active__c, BatchSize__c
            from BatchSchedule__c 
            where ClassName__c=:thisClassName
        ];
        // First remove existing scheduled jobs ... 
        for(BatchSchedule__c bs : bss) {
            try {
                if (!String.isBlank(bs.ScheduledJobId__c)) System.abortJob((Id) bs.ScheduledJobId__c);
            } catch(Exception e) {System.debug(e);}
        }

        // set default schedule if none found
        Integer i = 0;
        if (bss.size()==0) {
            for(String cron : BatchUpdateEscStatus.CRON_LIST) {
                String devname = thisClassName.left(37) + '_' + String.valueOf(i);
                bss.add(new BatchSchedule__c(
                    Name = devname,
                    ClassName__c = thisClassName,
                    CronSchedule__c = cron,
                    BatchSize__c = 10,
                    Active__c=true
                ));
                ++i;
            }
        }
        
        // Now schedule the jobs that are in the BatchSchedule list for this class
        List<String> jobIds = new List<String>();
        BatchUpdateEscStatus m = new BatchUpdateEscStatus(null, true);
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


}