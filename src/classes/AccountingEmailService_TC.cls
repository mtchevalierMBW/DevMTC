/**
 * AccountingEmailService_TC
 * Tests: AccountingEmailService
 *
 *  2016-03-22  B. Leaman   BLL1 - invoke the accounting email service
 *	2016-12-01	B. Leaman	BLL2 - Increase coverage by sending an invalid JSON payload.
 */
@isTest
public  class AccountingEmailService_TC{
public static  testmethod void MyunitTest(){
AccountingEmailService aes = new AccountingEmailService();
//aes.Messaging.InboundEmailHandler();
AccountingEmailService.AccountingPayload  aep = new AccountingEmailService.AccountingPayload();
//Test Method for main class
   
   
     // create a new email and envelope object
     
   Messaging.InboundEmail email = new Messaging.InboundEmail() ;
   Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

    // BLL1a
    Organization org = [select Id, Name from Organization limit 1];
    aep.action = 'no_action'; // ensure it goes through ALL the action conditionals
    aep.recordId = UserInfo.getUserId();    // invalid kind of Id for any actions
    aep.orgId = org.Id;
    aep.requestedby = UserInfo.getUserId();
    //FFAccounting.emailAsyncHandler(aep);
    email.plainTextBody = JSON.serialize(aep);
    email.subject = 'Test payload';
    aes.handleInboundEmail(email, env);
    // BLL1a end
   
/*
   // setup the data for the email
   
  email.subject = 'Test Job Applicant';
  email.fromAddress = 'someaddress@email.com';
  
  // add an Binary attachment
  
  Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
  attachment.body = blob.valueOf('my attachment text');
  attachment.fileName = 'textfileone.txt';
  attachment.mimeTypeSubType = 'text/plain';
  email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
 
  // add an Text atatchment
  
  Messaging.InboundEmail.TextAttachment attachmenttext = new Messaging.InboundEmail.TextAttachment();
  attachment.body = blob.valueOf('my attachment text');
  attachment.fileName = 'textfiletwo.txt';
  attachment.mimeTypeSubType = 'texttwo/plain';
  email.textAttachments =   new Messaging.inboundEmail.TextAttachment[] { attachmenttext };
 
  // call the email service class and test it with the data in the testMethod
  //inBoundEmail  testInbound=new inBoundEmail ();
  //testInbound.handleInboundEmail(email, env);
   // aes.handleInboundEmail(email, env);
   // create a contact data
   
    Contact testContact= new Contact();
    testContact.Email='someaddress@email.com';
    testContact.LastName='lastname';
    testContact.Phone='1234567234';
    testContact.Title='hello';
    insert testContact;
    
    system.debug('insertedcontact id===>' +testContact.Id);
   
   // Create Attachmenat data
   
  Attachment attachmnt =new Attachment();
  attachmnt.name='textfileone.txt';
  attachmnt.body =blob.valueOf('my attachment text');
  attachmnt.ParentId =testContact.Id;
  insert  attachmnt ;
*/   
   
   }
     public static  testmethod void DepreciationTest(){
    AccountingEmailService aes = new AccountingEmailService();
    //aes.Messaging.InboundEmailHandler();
    AccountingEmailService.AccountingPayload  aep = new AccountingEmailService.AccountingPayload();
    //Test Method for main class
       
       
         // create a new email and envelope object
         
       Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

      // BLL1a
      Organization org = [select Id, Name from Organization limit 1];
      aep.action = 'no_action'; // ensure it goes through ALL the action conditionals
      aep.recordId = UserInfo.getUserId();  // invalid kind of Id for any actions
      aep.orgId = org.Id;
      aep.requestedby = UserInfo.getUserId();
      //FFAccounting.emailAsyncHandler(aep);
      email.plainTextBody = JSON.serialize(aep);
      email.subject = 'Asyncnronous Processing Request - Depreciation';
      aes.handleInboundEmail(email, env);
      // BLL1a end
    }

	// BLL2a
	// Try an invalid JSON payload to generate an error (caught & logged to Error_Log__c)
	public static testmethod void InvalidPayload() {
		AccountingEmailService aes = new AccountingEmailService();
		// create a new email and envelope object
		Messaging.InboundEmail email = new Messaging.InboundEmail() ;
		Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
		email.plainTextBody = '{"x"="y";"x":"z";|}';	// invalid JSON
		email.subject = 'Asyncnronous Processing Request';
		aes.handleInboundEmail(email, env);
	}
	// BLL2a end
	
}