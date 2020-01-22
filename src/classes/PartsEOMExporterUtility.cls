global class PartsEOMExporterUtility
{
    @future(callout=true)
    public static void sendReports()
    {   
        List<String> toAddressList = Label.PartsEOMEmails.split(',');
        List<Messaging.EmailFileAttachment> EmailAttachments  = new List<Messaging.EmailFileAttachment>();
        
           
        
        //Check if the report and email ids are mentioned in custom label
               
            ApexPages.PageReference report = new ApexPages.PageReference('/apex/PartsEOMAnalysisExport');
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName('PartsEOM.xls');
            if(!Test.isRunningTest()){
                attachment.setBody(report.getContent());
            }
            else{
                attachment.setBody(Blob.valueOf('TEST BODY'));
            }
            //attachment.setContentType('text/csv');
            EmailAttachments.add(attachment);
    
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setFileAttachments(EmailAttachments);
            message.setSubject(Label.PartsEOMEmailSubject);
            message.setPlainTextBody(Label.PartsEOMEmailBody);
            message.setToAddresses( toAddressList );
            Messaging.sendEmail( new Messaging.SingleEmailMessage[] { message } );
       }
}