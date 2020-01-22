/**
* WMK (c) - 2019
*
* ReportExporterUtilityTW
* 
* Tested by: ReportExporterUtilityTWTest
* Programmer: Alexander Miller
* Date: 3/18/2019
* Work Item:  W-000623
* Copied from: ReportExporterUtility
*
* Modified By         Alias       Work Item       Date     Reason
* -----------------------------------------------------------------
*
*/
public class ReportExporterUtilityTW {
    
    @future(callout=true) 
    public static void sendReports()
    {   
        Set<String> reportNameSet = new Set<String>();
        List<String> toAddressList = Label.ReportEmailsTW.split(',');
        List<Messaging.EmailFileAttachment> EmailAttachments  = new List<Messaging.EmailFileAttachment>();
        
        //Trim report name to avoid exception
        for(String s: Label.ReportNamesTW.split(','))
        {
            reportNameSet.add(s.trim());
        }    

        List<Report> ReportList = new List<Report>();
        
        ReportList = [select id,name from Report where name In :reportNameSet ];

        if (Test.isRunningTest())
        {
            ReportList.add(new Report());
        }

        //Check if the report and email ids are mentioned in custom label
        if(reportNameSet!=null && reportNameSet.size()>0 && toAddressList!=null && toAddressList.size()>0)
        {
            for(Report objReport : ReportList)
            {
                ApexPages.PageReference report = new ApexPages.PageReference('/'+objReport.id+'?csv=1&exp=1&enc=UTF-8&isdtp=p1');

                //Attach the report         
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName(objReport.Name+'.csv');
                
                if(!Test.isRunningTest())
                {
                	attachment.setBody(report.getContent());
                }
                else
                {
                    attachment.setBody(Blob.valueOf('TEST BODY'));
                }
                attachment.setContentType('text/csv');
                EmailAttachments.add(attachment);           
            }
    
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setFileAttachments(EmailAttachments);
            message.setSubject(Label.ReportEmailSubject);
            message.setPlainTextBody(Label.ReportEmailBodyTW);
            message.setToAddresses( toAddressList );
            Messaging.sendEmail( new Messaging.SingleEmailMessage[] { message } );
        }
    }
}