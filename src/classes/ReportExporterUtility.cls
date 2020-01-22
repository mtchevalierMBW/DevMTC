/*
  ReportExporterUtility
  Tested by: ReportExporterUtilityTest
  Written by: DealerTeam

  Coverage:
  2018-11-26    96%   (24/25)

  Modification Log:
  2016-11-02  S. Utture   SSU1 - created utility class to avoid callouts in schedule class(ReportExporterSchedule) exception     
  2018-11-26  B. Leaman     W-000503 BLL1 - apply update from DealerTeam to fix issue when user forced into lightning by SF;
                                     Allow to run without seealldata=true
*/
global class ReportExporterUtility 
{
    @future(callout=true) 
    public static void sendReports()
    {   
        Set<String> reportNameSet = new Set<String>();
        List<String> toAddressList = Label.ReportEmails.split(',');
        List<Messaging.EmailFileAttachment> EmailAttachments  = new List<Messaging.EmailFileAttachment>();
        
        //Trim report name to avoid exception
        for(String s: Label.ReportNames.split(',')){
            reportNameSet.add(s.trim());
        }    
        List<Report> ReportList = new List<Report>();
        //if(Test.isRunningTest()){
        //    ReportList = [select id,name from Report limit 1 ];           
       // }
       // else{
        	ReportList = [select id,name from Report where name In :reportNameSet ];
            // BLL1
            if (Test.isRunningTest()) ReportList.add(new Report());
            // BLL1 end
        //}
        //Check if the report and email ids are mentioned in custom label
        if(reportNameSet!=null && reportNameSet.size()>0 && toAddressList!=null && toAddressList.size()>0){
            for(Report objReport : ReportList){

                // BLL1
                //ApexPages.PageReference report = new ApexPages.PageReference('/'+objReport.id+'?csv=1');
                ApexPages.PageReference report = new ApexPages.PageReference('/'+objReport.id+'?csv=1&exp=1&enc=UTF-8&isdtp=p1');
                // BLL1 end
                //Attach the report         
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName(objReport.Name+'.csv');
                if(!Test.isRunningTest()){
                	attachment.setBody(report.getContent());
                }
                else{
                    attachment.setBody(Blob.valueOf('TEST BODY'));
                }
                attachment.setContentType('text/csv');
                EmailAttachments.add(attachment);           
            }
    
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setFileAttachments(EmailAttachments);
            message.setSubject(Label.ReportEmailSubject);
            message.setPlainTextBody(Label.ReportEmailBody);
            message.setToAddresses( toAddressList );
            Messaging.sendEmail( new Messaging.SingleEmailMessage[] { message } );
        }
    }

}