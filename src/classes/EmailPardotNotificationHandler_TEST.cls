/**
 * EmailPardotNotificationHandler_TEST
 * Tests: EmailPardotNofificationHandler for unconverted and converted lead
 *
 *	2015-10-15	B. Leaman	BLL1 - test obtaining rental coordinator for location
 *	2016-06-10	B. Leaman	BLL2 - additional test coverage.
 *	2016-09-23	B. Leaman	BLL3 - add new custom setting to improve code coverage
 */
@isTest
private class EmailPardotNotificationHandler_TEST {

    static testMethod void PardotFormSubmission() {
        TestHelper_MW th = new TestHelper_MW();
        th.suspendDupeCatcher();
        
        // BLL3a - new custom setting needed for code coverage
        MobilityForceSettings__c MobilityForce = MobilityForceSettings__c.getOrgDefaults();
        MobilityForce.PardotTaskAssignee__c = UserInfo.getName();
        MobilityForce.PardotRentalAssignee__c = UserInfo.getName();
        upsert(MobilityForce);
        // BLL3a end
        
        Lead l = new Lead(pi__url__c='http://pi.pardot.com/prospect/read?id=1234567890',
                          FirstName = 'Test', LastName='Pardot', Email='test.pardot@example.com',
                          Status='Qualified',
                          Company='Test account 123');
        insert(l);

        Contact c = new Contact(pi__url__c='http://pi.pardot.com/prospect/read?id=1234567891',
                          FirstName = 'Test', LastName='Pardot', Email='test1.pardot@example.com');
        insert(c);
        
        Test.startTest();
        
        EmailPardotNotificationHandler handler = new EmailPardotNotificationHandler();
        Messaging.InboundEmail email = new Messaging.Inboundemail();
        Messaging.Inboundenvelope env = new Messaging.Inboundenvelope();
        email.subject = 'Test Sub';
        email.fromname = 'From User'; 
        email.fromAddress = 'from@example.com'; // Braun Lead
        email.htmlBody= 'Pardot Form Notification https://pi.pardot.com/prospect/read/id/1234567891'   
              + '<table>'
              + '<tr><td>Pardot Form Notification View Prospect</td><td></td></tr>' 
              + '<tr><td>Form Submission</td><td>Sell Your Van test</td></tr>'
              + '<tr><td>Field</td><td>Value</td></tr>' 
              + '<tr><td>First Name</td><td>Bryan </td></tr>'
              + '<tr><td>Last Name</td><td>Leaman </td></tr>'
              + '<tr><td>Address One</td><td>5854 Sunland St </td></tr>'
              + '<tr><td>City</td><td>Louisville </td></tr>'
              + '<tr><td>State</td><td>OH </td></tr>'
              + '<tr><td>Zip</td><td>44641 </td></tr>'
              + '<tr><td>Phone</td><td>330-453-0150 </td></tr>'
              + '<tr><td> Email</td><td>blleaman@aol.com </td></tr>'
              + '<tr><td>Comments</td><td>Just testing form. </td></tr>'
              + '<tr><td>Van year</td><td>2000 </td></tr>'
              + '<tr><td>Van make</td><td>Toyota </td></tr>'
              + '<tr><td>Van model</td><td>Sienna </td></tr>'
              + '<tr><td>Van VIN</td><td>n/a </td></tr>'
              + '<tr><td>Currently own</td><td>Other </td></tr>'
              + '<tr><td>Contact availability</td><td>8-5 EST </td></tr>'
              + '<tr><td>Van odometer</td><td>153000 </td></tr>'
              + '</table>';

        //Test parser independent of email service
        handler.handleInboundEmail(email, env);

        // Now try with converted lead
        //RecordType acctRt = [select Id, Name 
        //          from RecordType 
        //          where SObjectType='Account' and isPersonType=false and isActive=true 
        //          limit 1];
        RecordType acctRt = th.getBusinessAccountRt();
        Account a = new Account(RecordTypeId=acctRt.Id, Name='Test account 123', BillingState='OH');
        dealer__Dealer_Location__c dl = th.getDealerLocation('1'); // BLL1a
        a.Store_Location__c = dl.Id; // BLL1a
        insert(a);

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(l.Id);
        LeadStatus convertStatus = [select Id, MasterLabel from LeadStatus where IsConverted=true limit 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        lc.setAccountId(a.Id);
        lc.setDoNotCreateOpportunity(true);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        
        handler.handleInboundEmail(email, env);

        // Now try with a contact only
        email.htmlBody= 'Pardot Form Notification https://pi.pardot.com/prospect/read/id/1234567890'   
              + '<table>'
              + '<tr><td>Pardot Form Notification View Prospect</td><td></td></tr>' 
              + '<tr><td>Form Submission</td><td>Sell Your Van test</td></tr>'
              + '<tr><td>Field</td><td>Value</td></tr>' 
              + '<tr><td>First Name</td><td>Bryan </td></tr>'
              + '<tr><td>Last Name</td><td>Leaman </td></tr>'
              + '<tr><td>Address One</td><td>5854 Sunland St </td></tr>'
              + '<tr><td>City</td><td>Louisville </td></tr>'
              + '<tr><td>State</td><td>OH </td></tr>'
              + '<tr><td>Zip</td><td>44641 </td></tr>'
              + '<tr><td>Phone</td><td>330-453-0150 </td></tr>'
              + '<tr><td> Email</td><td>blleaman@aol.com </td></tr>'
              + '<tr><td>Comments</td><td>Just testing form. </td></tr>'
              + '<tr><td>Van year</td><td>2000 </td></tr>'
              + '<tr><td>Van make</td><td>Toyota </td></tr>'
              + '<tr><td>Van model</td><td>Sienna </td></tr>'
              + '<tr><td>Van VIN</td><td>n/a </td></tr>'
              + '<tr><td>Rental pickup location</td><td>Akron</td></tr>' // BLL1a
              + '<tr><td>Currently own</td><td>Other </td></tr>'
              + '<tr><td>Contact availability</td><td>8-5 EST </td></tr>'
              + '<tr><td>Van odometer</td><td>153000 </td></tr>'
              + '</table>';
        //Test parser independent of email service
        handler.handleInboundEmail(email, env);
  
  		// BLL2a
  		boolean active = handler.isActiveUser((Id) UserInfo.getUserId());
  		Id ident = handler.getRentalCoordForObj(lcr.getContactId());
  		ident = handler.getGMForObj(lcr.getContactId());
  		// BLL2a end

        th.resumeDupeCatcher();
        
    }

}