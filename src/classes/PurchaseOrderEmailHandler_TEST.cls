/**
 * PurchaseOrderEmailHandler_TEST
 * Tested by: PurchaseOrderEmailHandler
 * Date: May 5, 2017
 * Programmer: Bryan Leaman
 *
 */

@isTest
public  class PurchaseOrderEmailHandler_TEST {
	
	public static testmethod void MyUnitTest(){
		MW_TriggerControls__c PurchaseOrderEmailHandlerAtt = new MW_TriggerControls__c(Name='PurchaseOrderEmailHandlerAtt', Enabled__c=true);
		insert(PurchaseOrderEmailHandlerAtt);
		
		PurchaseOrderEmailHandler handler = new PurchaseOrderEmailHandler();
   
		// create a new email and envelope object
		Messaging.InboundEmail email = new Messaging.InboundEmail() ;
		Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

		Organization org = [select Id, Name from Organization limit 1];
		email.plainTextBody = 'Testing PO auto-attachment.\n';
		email.subject = 'Test payload xyz-ptr-99';
		email.fromAddress = 'someaddress@email.com';
  
		// add an Binary attachment
		Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
		attachment.body = blob.valueOf('my attachment text');
		attachment.fileName = '12345.txt';
		attachment.mimeTypeSubType = 'text/plain';
		email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
 
		// add an Text atatchment
		//Messaging.InboundEmail.TextAttachment attachmenttext = new Messaging.InboundEmail.TextAttachment();
		//attachmenttext.body = 'my attachment text';
		//attachmenttext.fileName = '123456.txt';
		//attachmenttext.mimeTypeSubType = 'text/plain';
		//email.textAttachments =   new Messaging.inboundEmail.TextAttachment[] { attachmenttext };

		Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);
   
	}
   
}