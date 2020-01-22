/**
 * VehicleInTransitToNFS
 * Tested by: VehicleInTransitToNFS_TEST
 * Date: Apr 3, 2018
 * Programmer: Bryan Leaman
 *
 * Code coverage:
 *  2018-04-03  88% (97/109)
 *  2018-04-16  87% (100/114)
 *
 * Modifications: 
 *  2018-04-16  B. Leaman   BLL1 - Also set inventory date to "today" when updating the status.
 *  2018-04-25  B. Leaman   BLL2 - Do not change commercial (division) vehicles; 
 *                          Also extend the timeframe for units with a source of “Purchase” or “MBW Buyer” to 14 days;
 * 
**/

/** Request from Steve Mendlik:
We would like the system to automatically set the status to ‘Not For Sale’ and 
the inventory date set to the date of status change for inventory records 
that have been in an ‘In Transit’ status for more than 5 business days. 
This automation would not apply to stock records which already have an 
inventory date or vehicles assigned to the locations of: 
‘BraunAbility’, ‘AMS’, ‘Vantage Mobility’, or ‘Transit Works’ (manufacturing locations).

4/12/2018
When this process changes the status to NFS could it also set the inventory date to the current date?
Steve Mendlik, Inventory Support Manager

**/

/* 
 * Run it now:
Database.executeBatch(new VehicleInTransitToNFS(null, true), 5);

 * Set standard schedule:
VehicleInTransitToNFS.scheduleMe();

 * Set custom schedule:
System.schedule('VehicleInTransitToNFS', 'sec min hr day mth wd year', new VehicleInTransitToNFS(null,true));
 
 */
global class VehicleInTransitToNFS implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
    global final String query;
    global boolean doUpdate;
    global String errmsgs;
    global Map<Id,String> resultmap;
    public static final List<String> ProtectedRecordTypes = new List<String>{'Archived','Vehicle Template'};
    public static final List<String> CRON_LIST = new List<String>{
        '0 0 5 * * ? *'     // 5 a.m. daily
    };
    
    // VehicleInTransitToNFS constructor - generate query string & initialize
    global VehicleInTransitToNFS(String rcdlimit, boolean doUpd) {
        doUpdate = doUpd;
        String soql = 
            'select Id, Name, dealer__Stock_Number__c, dealer__Status_Code__c, dealer__Inventory_Date__c, Source__c, Days_In_Current_Status__c, '   // BLL2c
            + 'dealer__Store_Location__c, dealer__Store_Location__r.Name, dealer__Store_Location__r.ManufacturingLocation__c ' 
            + 'from dealer__Vehicle_Inventory__c '
            + 'where dealer__Status_Code__c like \'In Transit%\' ' 
            + ' and Division__c!=\'Commercial\' '   // BLL2a
            + ' and ('  // BLL2a
            +       ' (Days_In_Current_Status__c > 7  and Source__c NOT in (\'Purchase\', \'MBW Buyer\')) ' // BLL2c
            +       ' or (Days_In_Current_Status__c > 14  and Source__c in (\'Purchase\', \'MBW Buyer\')) ' // BLL2a
            + ') '      // BLL2a
            + ' and dealer__Inventory_Date__c=null '
            + ' and RecordType.Name NOT in :ProtectedRecordTypes '
            + ' and dealer__Store_Location__r.ManufacturingLocation__c=false ';

        //if (!Test.isRunningTest()) soql += 'and (condition) ';
        soql += 'Order by dealer__Stock_Number__c ';
        if (!String.isBlank(rcdlimit))  soql += 'Limit ' + rcdlimit + ' ';
        query = soql;
        errmsgs = '';
        resultmap = new Map<Id, String>();
    }


    // start - query the database
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }


    // execute for a batch of records
    global void execute(Database.BatchableContext bc, List<sObject> scope) {
        List<dealer__Vehicle_Inventory__c> objs = (List<dealer__Vehicle_Inventory__c>) scope;
        System.debug('Record count: ' + String.valueOf(objs.size()));

        // Update
        List<dealer__Vehicle_Inventory__c> updObjs =new List<dealer__Vehicle_Inventory__c>();
        for(dealer__Vehicle_Inventory__c o : objs) {
            updObjs.add(new dealer__Vehicle_Inventory__c(
                Id = o.Id, 
                dealer__Status_Code__c = 'Not For Sale',
                dealer__Status_Code_Assignment_Date__c = Date.today(),
                dealer__Inventory_Date__c = Date.today()    // BLL1a
            ));
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
                dealer__Vehicle_Inventory__c o = updObjs[i];
                String resultline = resultmap.get(o.Id);
                if (resultline==null) resultline = o.dealer__Stock_Number__c + ',' 
                    + o.dealer__Status_Code__c;
                String errmsg = '';
                Database.SaveResult sr = saveresults.size()>i ? saveresults[i] : null;
                if (sr!=null && !sr.isSuccess()) {
                    //System.debug(sr);
                    String errmsgline = o.Id + ',' + o.dealer__Stock_Number__c + ': ';
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
        if (Limits.getLimitHeapSize() - Limits.getHeapSize() < 1000000){  // if less that 1 meg left
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
        String csvheader = 'Stock Nbr,Status,Messages\n';
        List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
        List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> recipients = new List<String>{ UserInfo.getUserEmail() };
        if (!org.isSandbox) {
            recipients.clear();
            recipients.add('vehicle.inventory@mobilityworks.com');
        }
        mail.setToAddresses(recipients); 
        mail.setSubject('Vehicle Update In Transit to NFS complete - UPDATES');
        String body = 'Batch update of vehicles In Transit over 5 days to NFS has completed.\n\n';
        if (!doUpdate) body += 'Test only! NOT Updated!\n\n';
        mail.setPlainTextBody(body);
        
        Messaging.EmailFileAttachment resultcsv = new Messaging.EmailFileAttachment();
            resultcsv.setContentType('text/csv');
            resultcsv.setFileName('results.csv');
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
        //List<Object> runparams = new List<Object>();
        //if (!String.isBlank(bs.Parameters__c)) runparams = (List<Object>) JSON.deserializeUntyped(bs.Parameters__c);
        //for(Object o : runparams) {
        //  Map<String,Object> params = (Map<String,Object>) o; 
        //  String namespace = (String) params.get('Namespace');
        //  String classname = (String) params.get('Classname');
            VehicleInTransitToNFS b = new VehicleInTransitToNFS(maxrcds, true);
            Database.executeBatch(b, Integer.valueOf(bs.BatchSize__c));
        //}
    }

    // scheduleMe self-scheduler
    public static List<String> scheduleMe() {
        String thisClassName = VehicleInTransitToNFS.class.getName();
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
            for(String cron : VehicleInTransitToNFS.CRON_LIST) {
                //String params = '';
                //for(Integer j=0; j<CRON_NAMESPACE.size(); ++j) {
                //  if (!String.isBlank(params)) params += ',';
                //  params += '{"Namespace":"' + CRON_NAMESPACE[j] + '", '
                //          + '"Classname":"' + CRON_CLASSNAME[j] + '"},';
                //}
                String devname = thisClassName.left(37) + '_' + String.valueOf(i);
                bss.add(new BatchSchedule__c(
                    Name = devname,
                    ClassName__c = thisClassName,
                    CronSchedule__c = cron,
                    //Parameters__c = '['
                    //  + params 
                    //  + ']',
                    BatchSize__c = 5,
                    Active__c=true
                ));
                ++i;
            }
        }
        
        // Now schedule the jobs that are in the BatchSchedule list for this class
        List<String> jobIds = new List<String>();
        VehicleInTransitToNFS m = new VehicleInTransitToNFS(null, true);
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