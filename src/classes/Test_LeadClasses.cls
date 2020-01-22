/** Test_LeadClasses
 * Tests: EmailParser, EmailLeadHandler, ArcadiumWebService, LeadGeoProxy, Lead_QueueMonitor
 *        TaskTrigger_MW (record response times on leads)
 *	2015-05-14	B. Leaman	BLL1 - additional info in lead to be passed to Arcadium 
 *	2015-09-22	B. Leaman	BLL2 - adjust so we don't get duplicate lead error during test
 *	2016-01-11	B. Leaman	BLL3 - Add new email sources to test: DisabledDealer, ePrice Quote, PureChat, Uber;
 *							Add group email recipient support.
 *	2016-02-10	B. Leaman	BLL4 IT20089 - Test new notifyAskAt routine in email parser.
 *  2016-03-07  RedTeal     RT1  - Reworked Arcadium web service tests to use webservice callout mock.
 *	2018-04-23	B. Leaman	BLL5 - remove purechat parser - these emails already go to the BDC; handle eCommerce (DME)
 *	2018-08-16	B. Leaman	BLL6 - harmar lead followup
 *	2018-12-07	B. Leaman	W-000511 BLL7 - add tests for TaskProcess.assignSubtype;
 *	2019-05-21	B. Leaman	W-000698 BLL8 - test failures on duplicate leads;
 *	2019-10-11	B. Leaman	W-000763 BLL9 - increase coverage.
 *	2019-12-13	B. Leaman	W-000803 BLL10 - LivePerson tests.
 */
@isTest
private class Test_LeadClasses {

	@testSetup static void methodName() {
    	// Create a group
    	Group g = new Group(Name='EMAIL_LEAD_HANDLER_Test_Group_1', Type='Regular');
    	insert(g);
    	try {
    		GroupMember m = new GroupMember(GroupId=g.Id, userOrGroupId=UserInfo.getUserId());
    		insert(m);
    	} catch(Exception e) {}
	}

	@isTest static void testGroupRecipients() {
		EmailLeadHandler lh =new EmailLeadHandler();
		List<String> em = lh.getFailureRecipients('EMAIL_LEAD_HANDLER_Test_Group_1');
		Group g = null;
		try {
			g = [select Id, Name from Group where Type='Regular' limit 1];
		} catch(Exception e) {}
		if (g!=null) {
			em = lh.getFailureRecipients(g.Name);
		}
	}

    @isTest
    static void testEmailService1() {
        TestHelper_MW th = new TestHelper_MW();
        th.suspendDupeCatcher();
        
        Test.startTest();
        
        EmailParser parser = new EmailParser();
        EmailLeadHandler lh = new EmailLeadHandler();
        Messaging.InboundEmail email = new Messaging.Inboundemail();
        Messaging.Inboundenvelope env = new Messaging.Inboundenvelope();
        email.subject = 'Test Sub';
        email.fromname = 'From User'; 
        email.fromAddress = 'from@braunlift.com'; // Braun Lead
        email.plainTextBody= 'Lead Created: 2/17/2015 - 10:29 PM MST  \n'+
                                'Type: Sales \n'+
                                'Source: BraunAbility.com Website \n'+
                                'Contact: TestBraunFN TestBraunLN \n'+
                                'Contact Address: - \n'+
                                'Contact Address: \n'+
                                'Contact City: - \n'+
                                'Contact State: - \n'+
                                'Contact Zip: 47353 \n'+
                                'Contact Phone: 1112223333 \n'+
                                'Contact Email: testbraunfn.testbraunln@example.com \n'+
                                'Wheelchair User: \n'+
                                'User Age: \n'+
                                'Will Ride: \n'+
                                'Will Travel: \n'+
                                'Able To Transfer: \n'+
                                'Wheelchair Type: \n'+
                                'Wheelchair Make: \n'+
                                'Conversion Interest: \n'+
                                'Current Transportation: \n'+
                                'In-Floor/Foldout: \n'+
                                'Chassis Preference: \n'+
                                'Nature of Disability: \n'+
                                ' \n'+
                                'Referral Code: 2015-0217-0106894 \n'+
                                '';

        //Test parser independent of email service
        parser.processBraunPayload(email.plainTextBody);

        // Test w/o LastName
        email.plainTextBody= 'Lead Created: 2/17/2015 - 10:29 PM MST  \n'+
                                'Type: Sales \n'+
                                'Source: BraunAbility.com Website \n'+
                                'Contact: TestLeadFn\n'+
                                'Contact Address: - \n'+
                                'Contact Address: \n'+
                                'Contact City: - \n'+
                                'Contact State: - \n'+
                                'Contact Zip: 47354 \n'+
                                'Contact Phone: 1112223344 \n'+
                                'Contact Email: TestBraunFn2.noln@example.com\n'+
                                'Wheelchair User: \n'+
                                'User Age: \n'+
                                'Will Ride: \n'+
                                'Will Travel: \n'+    
                                'Able To Transfer: \n'+
                                'Wheelchair Type: \n'+
                                'Wheelchair Make: \n'+
                                'Conversion Interest: \n'+
                                'Current Transportation: \n'+
                                'In-Floor/Foldout: \n'+
                                'Chassis Preference: \n'+
                                'Nature of Disability: \n'+
                                ' \n'+
                                'Referral Code: 2015-0217-0106895 \n'+
                                ''; 
        parser.processBraunPayload(email.plainTextBody);        

        // Test w/o Contact information
        email.plainTextBody= 'Lead Created: 2/17/2015 - 10:29 PM MST  \n'+
                                'Type: Sales \n'+
                                'Source: BraunAbility.com Website \n'+
                                'Contact: \n'+
                                'Contact Address: - \n'+
                                'Contact Address: \n'+
                                'Contact City: - \n'+
                                'Contact State: - \n'+
                                'Contact Zip: 47355 \n'+
                                'Contact Phone: 1112223355 \n'+
                                'Contact Email: Test_ba_evelyn@example.com\n'+
                                'Wheelchair User: \n'+
                                'User Age: \n'+
                                'Will Ride: \n'+
                                'Will Travel: \n'+
                                'Able To Transfer: \n'+
                                'Wheelchair Type: \n'+
                                'Wheelchair Make: \n'+
                                'Conversion Interest: \n'+
                                'Current Transportation: \n'+
                                'In-Floor/Foldout: \n'+
                                'Chassis Preference: \n'+
                                'Nature of Disability: \n'+
                                ' \n'+
                                'Referral Code: 2015-0217-0106896 \n'+
                                ''; 
        //BLL8d parser.processBraunPayload(email.plainTextBody);

        //Test email service
        lh.handleInboundEmail(email, env);

        // Test Bruno
        email.subject = 'Test from {Bruno}';
        email.fromname = 'From User'; 
        email.fromAddress = 'from@brunopartner.com'; // Braun Lead
        email.plainTextBody='Dear Valued Bruno Dealer:\n'
                        +'The following customer has requested information on Bruno products. We have routed this request/inquiry to your dealership so that you can follow up this customer directly.\n\n'
                        +'Thank you!\n\n'
                        +'Customer Care Dept.\n\n'
                        +'Bruno Independent Living Aids, Inc.\n'
                        +'Name:  TestBruno TestBrunoLn\n'
                        +'Email: BrunoFirstLast@example.com\n'
                        +'Company: \n'
                        +'Address: \n'
                        +'City: \n'
                        +'State: \n'
                        +'Zip: 16830\n'
                        +'Day Phone: 111-222-3336\n'
                        +'Evening Phone: \n'
                        +'Product: VL\n'
                        +'Comments: \n\n'
                        +'';
        lh.handleInboundEmail(email, env);


        parser.notifyOnFailure('Bad Lead', 'Test Message');
        parser.notifyAskAt('FWD to Ask@', 'Test message');  // BLLa
        lh.notifyUnrecognizedEmail('Running apex tests', 'Unrecognized email sender');


        // MobilityResource
        email.subject = 'Test from {MobilityResource}';
        email.fromname = 'From User'; 
        email.fromAddress = 'from@themobilityresource.com';
        email.plainTextBody = 'Below is a New Lead from The Mobility Resource Marketing Program.  This lead was transferred directly to your store during the call.  Please confirm that someone is following up with this customer.  Once contact has been made, or as the status changes, please update this lead at http://dealer.themobilityresource.com\n\n'
                       + 'Name: Mr. TMR TMRLast Jr\n'
                       + 'Address:  \n'
                       + 'City: ALMA\n'
                       + 'State:  MI\n'
                       + 'Zip:  48801\n'
                       + 'Phone:  (333)444-5555\n'
                       + 'Email: TMR.TMRLast@example.com\n'
                       + 'Best Time to Call:\n'
                       + 'Promo Code:  Internet Search\n'
                       + 'Product Interest:  Vans\n'
                       + 'Comments:  NEEDS A VAN.\n\n\n'
                       + 'Thanks and good luck!\n'
                       + ''; 
		// BLL9
        //lh.handleInboundEmail(email, env);
		parser.processMobilityResourcePayload(email.plainTextBody);
		parser.similarEnough(
			new Lead(FirstName='TMR', LastName='TMRLast', Phone='(330) 555-1212', Email='nobody@example.com'),
				'TMR', 'TMRLast', '3305551212', 'somebody@example.com'
		);
		parser.similarEnough(
			new Account(Name='TMR TMRLast', Phone='(330) 555-1212', Email__c='nobody@example.com'),
				'TMR', 'TMRLast', '3305551212', 'somebody@example.com'
		);
		parser.similarEnough(
			new Contact(FirstName='TMR', LastName='TMRLast', Phone='(330) 555-1212', Email='nobody@example.com'),
				'TMR', 'TMRLast', '3305551212', 'somebody@example.com'
		);
		// BLL9 end

        Test.stopTest();
        th.resumeDupeCatcher();
        
    }

	@isTest
	static void testEmailService4() {
        TestHelper_MW th = new TestHelper_MW();
        th.suspendDupeCatcher();
        
        Test.startTest();
        
        EmailParser parser = new EmailParser();
        EmailLeadHandler lh = new EmailLeadHandler();
        Messaging.InboundEmail email = new Messaging.Inboundemail();
        Messaging.Inboundenvelope env = new Messaging.Inboundenvelope();

        // VMI - try an html body
        email.subject = 'Test from SDN Web Lead';
        email.fromname = 'From User'; 
        email.fromAddress = 'from@VantageMobility.com';
        email.plainTextBody = null; // ''
             // + 'Message: Best price?\n'
             // + 'Name: Barbara Novak\n'
             // + 'Email: oaktlh@gmail.com\n'
             // + 'Phone: 615-394-4476\n'
             // + 'Zip Code: 37066\n'
             // + 'Lead Source: http://nashville-4434.vmidealers.com/\n'
             // + 'Lead Form: Inventory\n'
             // + 'Dealer Location Number: 4434\n'
             // + 'Dealer Location: MobilityWorks (Gallatin)\n'
             // + 'Date: Sat, 02 May 2015 03:36:27\n'
             // + 'VIN: FR638222\n'
             // + '';
        email.htmlBody = ''
           + '<p class=MsoNormal><span>SDN Web Lead From MobilityWorks (Gallatin)<o:p></o:p></span></p>'
           + '<p class=MsoNormal><o:p>&nbsp;</o:p></p>'
           + '<div align=center>'
           + '<table class=MsoNormalTable border=0 cellspacing=0 cellpadding=0 width="80%" style="width:80.0%">'
           + '<tr>'
           + '  <td width=200 style="width:150.0pt;padding:3.0pt 3.0pt 3.0pt 3.0pt"><p class=MsoNormal><b><span style="color:#444444">Message:<o:p></o:p></span></b></p></td>'
           + '  <td style="padding:3.0pt 3.0pt 3.0pt 3.0pt"><p class=MsoNormal><span style="color:#444444">Best price?<o:p></o:p></span></p></td>'
           + '</tr><tr>'
           + '  <td style="background:#E8E8E8;padding:3.0pt 3.0pt 3.0pt 3.0pt"><p class=MsoNormal><b><span style="color:#444444">Name:<o:p></o:p></span></b></p></td>'
           + '  <td style="background:#E8E8E8;padding:3.0pt 3.0pt 3.0pt 3.0pt"><p class=MsoNormal><span style="color:#444444">Barbara Novak<o:p></o:p></span></p></td>'
           + '</tr><tr>'
           + '  <td style="padding:3.0pt 3.0pt 3.0pt 3.0pt"><p class=MsoNormal><b><span style="color:#444444">Email:<o:p></o:p></span></b></p></td>'
           + '  <td style="padding:3.0pt 3.0pt 3.0pt 3.0pt"><p class=MsoNormal><span style="color:#444444"><a href="mailto:bar.nov@example.com">bar.nov@gmail.com</a><o:p></o:p></span></p></td>'
           + '</tr><tr>'
           + '  <td style="background:#E8E8E8;padding:3.0pt 3.0pt 3.0pt 3.0pt"><p class=MsoNormal><b><span style="color:#444444">Phone:<o:p></o:p></span></b></p></td>'
           + '  <td style="background:#E8E8E8;padding:3.0pt 3.0pt 3.0pt 3.0pt"><p class=MsoNormal><span style="color:#444444">555-666-7777<o:p></o:p></span></p></td>'
           + '</tr><tr>'
           + '  <td style="padding:3.0pt 3.0pt 3.0pt 3.0pt"><p class=MsoNormal><b><span style="color:#444444">Zip Code:<o:p></o:p></span></b></p></td>'
           + '  <td style="padding:3.0pt 3.0pt 3.0pt 3.0pt"><p class=MsoNormal><span style="color:#444444">37066<o:p></o:p></span></p></td>'
           + '</tr><tr>'
           + '  <td style="background:#E8E8E8;padding:3.0pt 3.0pt 3.0pt 3.0pt"><p class=MsoNormal><b><span style="color:#444444">Lead Source:<o:p></o:p></span></b></p></td>'
           + '  <td style="background:#E8E8E8;padding:3.0pt 3.0pt 3.0pt 3.0pt"><p class=MsoNormal><span style="color:#444444"><a href="http://nashville-4434.vmidealers.com/">http://nashville-4434.vmidealers.com/</a><o:p></o:p></span></p></td>'
           + '</tr><tr>'
           + '  <td style="background:#E8E8E8;padding:3.0pt 3.0pt 3.0pt 3.0pt"><p class=MsoNormal><b><span style="color:#444444">Lead Form:<o:p></o:p></span></b></p></td>'
           + '  <td style="background:#E8E8E8;padding:3.0pt 3.0pt 3.0pt 3.0pt"><p class=MsoNormal><span style="color:#444444">Inventory<o:p></o:p></span></p></td>'
           + '</tr><tr>'
           + '  <td style="padding:3.0pt 3.0pt 3.0pt 3.0pt"><p class=MsoNormal><b><span style="color:#444444">Dealer Location Number:<o:p></o:p></span></b></p></td>'
           + '  <td style="padding:3.0pt 3.0pt 3.0pt 3.0pt"><p class=MsoNormal><span style="color:#444444">4434<o:p></o:p></span></p></td>'
           + '</tr><tr>'
           + '  <td style="background:#E8E8E8;padding:3.0pt 3.0pt 3.0pt 3.0pt"><p class=MsoNormal><b><span style="color:#444444">Dealer Location:<o:p></o:p></span></b></p></td>'
           + '  <td style="background:#E8E8E8;padding:3.0pt 3.0pt 3.0pt 3.0pt"><p class=MsoNormal><span style="color:#444444">MobilityWorks (Gallatin)<o:p></o:p></span></p></td>'
           + '</tr><tr>'
           + '  <td style="padding:3.0pt 3.0pt 3.0pt 3.0pt"><p class=MsoNormal><b><span style="color:#444444">Date:<o:p></o:p></span></b></p></td>'
           + '  <td style="padding:3.0pt 3.0pt 3.0pt 3.0pt"><p class=MsoNormal><span style="color:#444444">Sat, 02 May 2015 03:36:27<o:p></o:p></span></p></td>'
           + '</tr><tr>'
           + '  <td style="background:#E8E8E8;padding:3.0pt 3.0pt 3.0pt 3.0pt"><p class=MsoNormal><b><span style="color:#444444">VIN:<o:p></o:p></span></b></p></td>'
           + '  <td style="padding:3.0pt 3.0pt 3.0pt 3.0pt"><p class=MsoNormal><span style="color:#444444">FR638222<o:p></o:p></span></p></td>'
           + '</tr>'
           + '</table>'
           + '</div>'; 
        lh.handleInboundEmail(email, env);
        String convertedBody = lh.convertToPlainText(email.htmlBody);
        //BLL8d parser.processVMIPayload(convertedBody);

        // MobilitySales
        email.subject = 'Mobility Works Form Details';
        email.fromname = 'From User'; 
        email.fromAddress = 'from@mobilitysales.com';
        email.plainTextBody = ''
           + '[IMP Lead] Mobility Works - Contact Form Details Page \n'
           + 'Message: interestedinwhite14 xle\n'
           + 'First Name: craiggy\n'
           + 'Last Name: boy\n'
           + 'Address: \n'
           + 'City:\n'
           + 'State:\n'
           + 'Email: \n'
           + 'Phone: 6667778888\n'
           + 'Location:\n'
           + 'ZIP Code:\n'
           + 'Vehicle-VIN: 5TDYK3DC6ES495683 \n'
           + 'Vehicle-Stock#: 1555B \n'
           + 'Time Sent: 2015-05-05 02:12:45\n'
           + 'Lead Source: IMP\n'
           + '\n';  
        lh.handleInboundEmail(email, env);
        //BLL8d parser.processMobilitySalesPayload(email.plainTextBody);

        Test.stopTest();
        th.resumeDupeCatcher();
	}


    @isTest
    static void testEmailService2() {
        TestHelper_MW th = new TestHelper_MW();
        th.suspendDupeCatcher();
        
        Test.startTest();
        
        EmailParser parser = new EmailParser();
        EmailLeadHandler lh = new EmailLeadHandler();
        Messaging.InboundEmail email = new Messaging.Inboundemail();
        Messaging.Inboundenvelope env = new Messaging.Inboundenvelope();

        // UnitedAccess
        email.subject = 'United Access';
        email.fromname = 'From User'; 
        email.fromAddress = 'from@unitedaccess.com';
        email.plainTextBody = ''
           + 'Here is a lead for your Burlingame, CA team.\n'
           + 'Thanks!\n\n' 
           + 'MyFirst MyLast\n\n'
           + 'MyFirst (Middle) MyLast\n'
           + 'United Access\n'
           + 'Business Development Center Manager\n'
           + 'Phone: (777) 888-9999, Cell: (777) 888-9990\n'
           + 'www.unitedaccess.com\n'
           + 'We Happily Accept Your Kind Referrals!  Just Hit Reply or Email referrals to:  info@unitedaccess.com.\n\n' 
           + '- DISCLAIMER --\n'
           + 'This message contains information, which may be confidential or privileged, and is intended only for the individual or entity named above. It is prohibited for anyone else to disclose, copy, distribute or use the contents of this message. All personal messages express views solely of the sender, which are not to be attributed to the sender\'s company, and may not be distributed without this disclaimer. If you received this message in error, please notify sender immediately.\n\n' 
           + 'United Access - Contact Form Details Page\n'
           + 'Message:  For betha from www.unitedaccess.com/inventory/wheelchair-accessible-vehicle.php?productid=1304120&default=0&price=$7,000\n\n'
           + 'First Name:\n UAFIrst\n'
           + 'Last Name:\n  UALast\n'
           + 'Address:\n\n' 
           + 'City:\n\n'
           + 'State:\n\n'
           + 'Email:\n ua.email@example.com\n\n'
           + 'Phone:\n7074306014\n'
           + 'ZIP Code:\n94590\n'
           + 'Vehicle-VIN:\n1GBFG15R2Y1216249\n'
           + 'Vehicle-Stock#:\nVIN-Y1216249\n'
           + 'Time Sent:\n2015-05-04 18:10:01\n'
           + 'Lead Source:\nInventory Details\n'
           + '';
        lh.handleInboundEmail(email, env);

        // AccessibleVans (AVA)
        email.subject = 'Ava lead ';
        email.fromname = 'From User'; 
        email.fromAddress = 'from@accessiblevans.com';
        email.plainTextBody = ''
           + 'Maybe we can help\n\n\n'
           + 'Accessible Vans - Contact Form Details Page\n\n'
           + 'Message:\n\n'
           + 'Do you have transportation to and from Atlanta GA Airport? Are you open on Sunday for pickup? I need to rent a van drive to Anniston AL area pick up my father who is wheel chair bound and take him to doctor visit in Birmingham. Trying to work out logistics if i fly into Atlanta\n\n'
           + 'First Name:\n\n'
           + 'AvaFirst\n\n'
           + 'Last Name:\n\n'
           + 'AvaLast\n\n'
           + 'Address:\n\n'
           + '717 Cheaky dr\n\n'
           + 'City:\n\n'
           + 'Flourr Mountain\n\n'
           + 'State:\n\n'
           + 'Oklahoma\n\n'
           + 'Email:\n\n'
           + 'Ava.Last@gmail.com\n\n'
           + 'Phone:\n\n'
           + '3345567778\n\n'
           + 'Location:\n\n'
           + 'ZIP Code:\n\n'
           + '55028\n\n'
           + 'Time Sent:\n\n'
           + '2014-03-10 19:13:37\n\n'
           + 'Lead Source:\n\n'
           + 'Our Site\n\n'
           + '\n';
        lh.handleInboundEmail(email, env);

        // MobilityVanSales
        email.subject = 'Customer Lead - Test';
        email.fromname = 'From User'; 
        email.fromAddress = 'from@mobilityvansales.com';
        email.plainTextBody = ''
           + 'Dear MVSContactFN MVSContactLN,\n'
           + 'MVSFIrst is interested in your 2012 Chevrolet Silverado 1500 Wheelchair Truck for sale and has requested to get in contact with you.\n'
           + 'This inquiry is in regard to your Chevrolet Silverado 1500 for sale at http://www.mobilityvansales.com/buy/USED-2012-CHEVROLET-SILVERADO 1500-HANDICAP-TRUCK-FOR-SALE-WALL-PENNSYLVANIA-162910.htm\n'
           + 'Following are the details and comments of the interested buyer:\n'
           + 'Name: MVSFirst\n'
           + 'Email: mvs_first@example.com\n'
           + 'Phone: (567) 891-2345\n'
           + '\n'
           + 'Buyers Comments\n'
           + 'How much is this handicap accessible truck? Ad ID = 162910. Does a power wheelchair fit into this truck?\n'
           + '\n'
           + 'Thank you for using Mobility Van Sales Dealer Program,\n'
           + 'Mobility Van Sales\n'
           + 'info@mobilityvansales.com\n'
           + 'http://www.mobilityvansales.com\n'
           + '\n';
        lh.handleInboundEmail(email, env);

        // Harmar
        email.subject = '[HARMAR] lead ';
        email.fromname = 'From User'; 
        email.fromAddress = 'harmar.mailer@gmail.com';
        email.plainTextBody = ''
           + 'First Name: JayLee \n'
           + 'Last Name: Santiago \n'
           + 'Email: jlee@example.com\n' 
           + 'ZIP: 90701 \n'
           + 'City: PalmPlace\n' 
           + 'State: CA \n'
           + 'Company: \n'
           + 'Phone: 5673459876 \n'
           + 'Message: I\'m interested in a Harmar A100 lift. Purchase and installed\n'
           + '\n';
        lh.handleInboundEmail(email, env);

		// BLL6a - Harmar lead followup
        email.subject = 'Harmar :: Lead Follow-Up';
        email.fromname = 'From User'; 
        email.fromAddress = 'noreply@example.com';
        email.plainTextBody = ''
           + 'First Name: JayLee \n'
           + 'Last Name: Santiago \n'
           + 'Email: jlee@example.com\n' 
           + 'ZIP: 90701 \n'
           + 'City: PalmPlace\n' 
           + 'State: CA \n'
           + 'Company: \n'
           + 'Phone: 5673459876 \n'
           + 'Message: I\'m interested in a Harmar A100 lift. Purchase and installed\n'
           + '\n';
        lh.handleInboundEmail(email, env);

        // Crytico
        email.subject = 'Crytico lead ';
        email.fromname = 'From User'; 
        email.fromAddress = 'someone@mandrillapp.com';
        email.plainTextBody = ''
           + 'First Name: JayLee2\n'
           + 'Last Name: Santiago2\n'
           + 'Phone Number: 5673459876 \n'
           + 'Email: jlee2@example.com\n' 
           + 'ZIP: 90701 \n'
           + 'Product: n/a\n'
           + 'Manufacturer: n/a\n'
           + 'Dealer Name: Mobility Works\n'
           + 'Dealer City: Akron\n'
           + 'Message: I\'m interested in a Harmar A100 lift. Purchase and installed\n'
           + '\n';
        lh.handleInboundEmail(email, env);
		lh.convertToPlainText2('Email body\r &#124;<table><tr><td>Field:</td><td>value</td></tr>\r</table');
		lh.convertPlainText3('Email body\r &#124;Field * value\rField2 * value2');
		lh.convertToPlainText4('Email body\r &#124;<table><tr><td>Field:</td><td>value</td></tr>\r</table');

        Test.stopTest();

        th.resumeDupeCatcher();

    }

	// BLL3a
	@isTest
    static void testEmailService3() {
        TestHelper_MW th = new TestHelper_MW();
        th.suspendDupeCatcher();
        
        Test.startTest();
        
        EmailParser parser = new EmailParser();
        EmailLeadHandler lh = new EmailLeadHandler();
        Messaging.InboundEmail email = new Messaging.Inboundemail();
        Messaging.Inboundenvelope env = new Messaging.Inboundenvelope();

        // DisabledDealer
        email.subject = 'Free Copy Request test';
        email.fromname = 'From User'; 
        email.fromAddress = 'from@disableddealer.com';
        email.plainTextBody = ''
           + 'name: TEST DISABLED\n'
           + 'email: disableddealer.email@example.com\n'
           + 'phone:\n555-430-6015\n'
           + 'street: 123 disabled way\n' 
           + 'city:wilmington\n'
           + 'state:\n'
           + 'zipcode:\n19808\n'
           + 'disabled:0\n'
           + 'interest:/Vehicle/Wheelchair/Other\n'
           + 'organization:\n'
           + 'comment:2005 toyota sienna converted\nquantum 6 edge power wheelchair\nsurehands ceiling lift system\n'
           + 'country:USA\n'
           + '';
        lh.handleInboundEmail(email, env);

        // Hasco Quote
        email.subject = 'test Hasco lead';
        email.fromname = 'From User'; 
        email.fromAddress = 'other@hascomed.com <web@hascomed.com>';
        email.plainTextBody = ''
           + 'Name: TestEPrice Quote\n\n'
           + 'Email: eprice@example.com\n\n'
           + 'Zip Code: 12345\n\n'
           + 'Phone: 555-333-1111\n\n'
           + 'VIN:STK#1234\n\n'
           + 'URL:http://www.ride-away.com/wheelchair-vans-for-sale\n\n'
           + 'What would you like from us?: n/a'
           + 'Questions?: n/a'
           + '\n';
        //BLL8d lh.handleInboundEmail(email, env);
		parser.processHascoPayload(email.plainTextBody);


        // ePrice Quote
        email.subject = 'test ePrice Quote';
        email.fromname = 'From User'; 
        email.fromAddress = 'web@hascomed.com <web@hascomed.com>';
        email.plainTextBody = ''
           + 'Name: TestEPrice Quote\n\n'
           + 'Email: eprice@example.com\n\n'
           + 'Zip Code: 12345\n\n'
           + 'VIN:STK#1234\n\n'
           + 'URL:http://www.ride-away.com/wheelchair-vans-for-sale\n\n'
           + '\n';
        //BLL8d lh.handleInboundEmail(email, env);
		parser.processEPriceQuotePayload(email.plainTextBody);
		
        // PureChat
        email.subject = 'Test using Ride-Away widget';
        email.fromname = 'From User'; 
        email.fromAddress = 'from@PureChat.com';
        email.plainTextBody = ''
           + 'You received a question while you were away.\n\n'
           + 'Name: PureChat Test\n'
           + 'Email: purechat@example.com\n'
           + 'Initial Page: http://www.mobilityvansales.com\n'
           + 'Question:'
           + 'I would like to get the link to the rideaway office in Norfolk.\n'
           + '\n'
           + '\n';
        lh.handleInboundEmail(email, env);
        //BLL5d parser.processPureChatPayload(email.plainTextBody);

        // Uber
        email.subject = 'Uber test lead information';
        email.fromname = 'From User'; 
        email.fromAddress = 'ubertest@wufoo.com';
        email.htmlBody = ''
           + '<table>'
           + '<tr><td>Name *</td><td>Test Uber</td></tr>\n'
           + '<tr><td>Phone Number*</td><td>(555) 345-9876</td></tr>\n'
           + '<tr><td>Email *</td><td>ubertest@example.com</td></tr>\n'
           + '</table>' 
           + '\n';
        //BLL8d lh.handleInboundEmail(email, env);
        parser.processUberPayload(email.plainTextBody);

        Test.stopTest();

        th.resumeDupeCatcher();

    }

	@isTest
    static void testUnrecognizedEmail() {
        Test.startTest();
        
        EmailParser parser = new EmailParser();
        EmailLeadHandler lh = new EmailLeadHandler();
        Messaging.InboundEmail email = new Messaging.Inboundemail();
        Messaging.Inboundenvelope env = new Messaging.Inboundenvelope();

        // Nobody we know
        email.subject = 'No match';
        email.fromname = 'From User'; 
        email.fromAddress = 'from.nobody@example.com';
        email.plainTextBody = ''
           + 'Does not matter what is in the body of this message.\n'
           + '';
        lh.handleInboundEmail(email, env);

        Test.stopTest();

    }

	@isTest
    static void testEmptyEmail() {
        Test.startTest();
        
        EmailParser parser = new EmailParser();
        EmailLeadHandler lh = new EmailLeadHandler();
        Messaging.InboundEmail email = new Messaging.Inboundemail();
        Messaging.Inboundenvelope env = new Messaging.Inboundenvelope();

        // Nobody we know
        email.subject = 'Empty';
        email.fromname = 'From User'; 
        email.fromAddress = 'empty.body@example.com';
        email.plainTextBody = '';
        lh.handleInboundEmail(email, env);

        Test.stopTest();

    }

	// BLL3a end


	// BLLa
	@isTest
    static void testAvaRental() {
        Test.startTest();
        
        EmailParser parser = new EmailParser();
        EmailLeadHandler lh = new EmailLeadHandler();
        Messaging.InboundEmail email = new Messaging.Inboundemail();
        Messaging.Inboundenvelope env = new Messaging.Inboundenvelope();

        // Nobody we know
        email.subject = 'AVA Rental Request - test';
        email.fromname = 'From User'; 
        email.fromAddress = 'empty.body@example.com';
        email.plainTextBody = 'This is a test email';
        email.htmlBody = '<h1>This is a test email</h1><br/><a href="http:////ava.mobilitypluscrm.com//notfound">Open Rental Request Details</a><br/>';
        lh.handleInboundEmail(email, env);

        Test.stopTest();

    }
    // BLLa end

// BLL5a
	@isTest
    static void testECommerce() {
        Test.startTest();
        
        EmailParser parser = new EmailParser();
        EmailLeadHandler lh = new EmailLeadHandler();
        Messaging.InboundEmail email = new Messaging.Inboundemail();
        Messaging.Inboundenvelope env = new Messaging.Inboundenvelope();

        // Nobody we know
        email.subject = '[MobilityWorks Online Store] - test';
        email.fromname = 'From User'; 
        email.fromAddress = 'empty.body@example.com';
        email.plainTextBody = 'first_name: TestFirst\nlast_name: TestLast\naddress_1: 123 TesAddress\ncity: testCity\nstate: TS\npostcode: 123456\nphone:330-555-1212\nemail:testDME@example.com\n';
        email.htmlBody = '<p>' + email.plainTextBody + '</p>';
        lh.handleInboundEmail(email, env);

        Test.stopTest();

    }

// BLL5a end 


    @isTest static void testGeoLocation() {
        
        Lead lead = new Lead();
        lead.FirstName = 'Jarrett';
        lead.LastName = 'Kuljis';
        lead.PostalCode = '96001';
        lead.State = 'CA';
        insert lead;
dealer__Dealer_Location__c ddl = new dealer__Dealer_Location__c();
        ddl.Name ='Test';
        ddl.dealer__City__c ='Test';
        ddl.dealer__Postal_Code__c='301352';
        ddl.dealer__State__c='Te';
        ddl.dealer__Company_Number__c='12345';
        ddl.dealer__Service_Director__c =Userinfo.getuserid();
        insert ddl;
        ApexPages.StandardController s = new ApexPages.StandardController(lead);
        LeadGeoProxy l = new LeadGeoProxy(s);
        l.latitude  = 41.107065;
        l.longitude = -81.485952;
        l.getLocationsByDistance();
        l.latlon();
        l.lookupSuccess=True;
         //ApexPages.StandardController s1 = new ApexPages.StandardController(ddl);
        LeadGeoProxy.LocationWrapperObj lg = new LeadGeoProxy.LocationWrapperObj(ddl,1);
        //lg.LocationWrapperObj(ddl.id);

    }
	
    //RT1
    @isTest static void testArcadiumWebService() {
        ArcadiumWebService a = new ArcadiumWebService();
        ArcadiumWebService.CreateLeadRecordWithCouponResponse_element a1 = new ArcadiumWebService.CreateLeadRecordWithCouponResponse_element();
        ArcadiumWebService.CreateLeadRecordWithCoupon_element aCLRWC = new ArcadiumWebService.CreateLeadRecordWithCoupon_element();
        ArcadiumWebService.MailData aMD = new ArcadiumWebService.MailData();
        ArcadiumWebService.MailResponse_element mre = new ArcadiumWebService.MailResponse_element();
        ArcadiumWebService.CreateLeadRecordResponse_element lre = new ArcadiumWebService.CreateLeadRecordResponse_element();
        ArcadiumWebService.CreateLeadRecord_element clre = new ArcadiumWebService.CreateLeadRecord_element();
        ArcadiumWebService.ArrayOfMailData amda = new ArcadiumWebService.ArrayOfMailData();
        ArcadiumWebService.MailResponseResponse_element mrre = new ArcadiumWebService.MailResponseResponse_element();
    }
    
    @isTest
    static void testArcadiumMailResponse() {
        Test.setMock(WebServiceMock.class, new WebServiceCalloutMock(new ArcadiumWebService.MailResponseResponse_element()));
        ArcadiumWebService.Service1Soap ss = new ArcadiumWebService.Service1Soap();  
        ArcadiumWebService.ArrayOfMailData amda = new ArcadiumWebService.ArrayOfMailData();
        test.startTest();
        ss.MailResponse(123, 'test@test.com', amda);
        test.stopTest();
    } 
    
    @isTest
    static void testArcadiumCreateLeadRecordWithCoupon() {
        Test.setMock(WebServiceMock.class, new WebServiceCalloutMock(new ArcadiumWebService.CreateLeadRecordWithCouponResponse_element()));
        ArcadiumWebService.Service1Soap ss = new ArcadiumWebService.Service1Soap();        
        test.startTest();
        ss.CreateLeadRecordWithCoupon('MBW', 'Jarrett', 'Kuljis', '300 E. Cypress', 'Redding', 
                            'CA',
                            '96001', 
                            '5305109891',
                            'jarrett@dealerteam.com',
                            'Detail',
                            0,
                            'stockNum',
                            'coupon',
                            '121B');
        test.stopTest();
    }
    
    @isTest
    static void testArcadiumCreateLeadRecord() {
        Test.setMock(WebServiceMock.class, new WebServiceCalloutMock(new ArcadiumWebService.CreateLeadRecordResponse_element()));

        ArcadiumWebService.Service1Soap ss = new ArcadiumWebService.Service1Soap();
        
        //ss.CreateLeadRecordWithCoupon('MBW', 'Jarrett', 'Kuljis', )
        test.startTest();
        ss.CreateLeadRecord('MBW', 'Jarrett', 'Kuljis', '300 E. Cypress', 'Redding', 
                            'CA',
                            '96001', 
                            '5305109891',
                            'jarrett@dealerteam.com',
                            'Detail',
                            0,
                            '121B');
        test.stopTest();
    }
    //end RT1



    //@isTest static void testLeadConversion() {
    //  Lead lead = new Lead();
    //  lead.FirstName = 'Jarrett';
    //  lead.LastName = 'Kuljis';
    //  lead.PostalCode = '96001';
    //  lead.State = 'CA';
    //  // BLL1 additional info to be passed to Arcadium
    //  lead.Desired_Vehicles__c = '1234B';
    //  lead.Vehicle_preference__c = 'Toyota Sienna';
    //  lead.Rental_pickup_location__c = 'Akron';
    //  lead.Rental_pick_up__c = Date.today();
    //  lead.Rental_drop_off__c = Date.today();
    //  lead.Van_year__c = '2000';
    //  lead.Van_make__c = 'Toyota';
    //  lead.Van_model__c = 'Sienaa';
    //  lead.Van_VIN__c = '123456789ABCDEFGH';
    //  lead.Currently_own__c = 'n/a';
    //  lead.Contact_availability__c = 'M-F 8-5';
    //  lead.Vehicle_information__c = 'My van';
    //  lead.Van_odometer__c = '153000';
    //  lead.Nearest_location__c = 'Akron';
    //  lead.Referral_method__c = 'Friend';
    //  lead.Visited_a_store__c = 'Yes';
    //  // BLL1 end additional info
    //  insert lead;

    //  PageReference pgRef = Page.LeadConvertSalesUp; 
    //  Test.setCurrentPage(pgRef); //Set the page for Test Method
    //  ApexPages.currentPage().getParameters().put('leadId', lead.id);

    //  LeadConversion l = new LeadConversion();
    //  l.insertIntoArcadium();
    //  l.convertLead();

    //}

    // Test Lead_QueueMonitor_CTLR controller class for Lead_QueueMonitor VF page
    @isTest private static void LeadQueueMonitor() {
        Lead_QueueMonitor_CTLR ctl = new Lead_QueueMonitor_CTLR();
        Integer nbr = ctl.LeadsInQueueCount;
        DateTime dt = ctl.NewestDateTime;
        String que = ctl.QueueName;
        String clr = ctl.CountColor; 
        String url = ctl.ListViewURL;
        boolean has = ctl.HasURL;
    }

   @isTest private static void LeadOriginalQueueAndRep() {
        // Get a queue 
        Group g = [select Id, Name from Group where Type='Queue' limit 1];

        Lead l = new Lead();
        l.FirstName = 'Test';
        l.LastName = 'BDC Lead';
        l.PostalCode = '28277';
        l.State = 'NC';
        l.OwnerId = g.Id;
        insert l;
        l.OwnerId = UserInfo.getUserId();
        update(l);
        Test.startTest();
        
        Lead newlead = [select Id, Name, Lead_Queue_Name__c, Responsible_Rep__c from Lead where Id=:l.Id limit 1];
        System.assert(!String.isBlank(newlead.Lead_Queue_Name__c), 'Did not assign lead queue name');
        System.assert(!String.isBlank(newlead.Responsible_Rep__c), 'Did not assign responsible rep');

        // Assign task - cause calc of response time
        Task t = new Task(WhoId = l.Id, ActivityDate = Date.today(),
                  Description = l.Description, Subject='Email received', 
                  Status='Completed');
        insert(t);
        Test.stopTest();
        Lead newlead2 = [select Id, Name, Lead_Queue_Name__c, Responsible_Rep__c, 
                                Time_In_Queue__c, BusHrs_Time_In_Queue__c,
                                Response_Time_BDC__c, BusHrs_Response_Time_BDC__c 
                         from Lead 
                         where Id=:l.Id 
                         limit 1];
        System.assert(newlead2.Time_In_Queue__c!=null, 'Did not calculate time in queue!');
        System.assert(newlead2.BusHrs_Time_In_Queue__c!=null, 'Did not calculate time in queue (business hrs)!');
        System.assert(newlead2.Response_Time_BDC__c!=null, 'Did not calculate response time!');
        System.assert(newlead2.BusHrs_Response_Time_BDC__c!=null, 'Did not calculate response time (business hrs)!');
   }

	// BLL7
	// Ensure task subtypes are being assigned
	static testmethod void taskSubtype() {
		List<TaskSubtypeRule__c> rules = new List<TaskSubtypeRule__c>();
		rules.add(new TaskSubtypeRule__c(
			Name = 'Test 1', TypePattern__c = '.*', SubjectPattern__c = '(?i)Pardot.*Email.*', Subtype__c='ListEmail', Sequence__c=1
		));
		rules.add(new TaskSubtypeRule__c(
			Name = 'Test 2', TypePattern__c = '.*', SubjectPattern__c = '(?i)Call.*', Subtype__c='Call', Sequence__c=2
		));
		rules.add(new TaskSubtypeRule__c(
			Name = 'Test 3', TypePattern__c = '.*', SubjectPattern__c = '(?i)Email.*', Subtype__c='Email', Sequence__c=3
		));
		insert(rules);

		Test.startTest();
		List<Task> tasks = new List<Task>();
		for(String s : new List<String>{'Pardot Email:','Call client','E-mail followup','Something else'}) {
			tasks.add(new Task(
				Subject = s,
				ActivityDate = Date.today(),
				Status = 'Completed'
			));
		}
		insert(tasks);
		Test.stopTest();

		List<AggregateResult> ars = [select TaskSubtype, count(Id) from Task where ActivityDate=TODAY group by TaskSubtype];
		System.debug(ars.size());
		for(AggregateResult ar : ars) System.debug(ar);
		System.assert(ars.size()>1, 'Did not find task subtypes assigned other than the default');
	}
	// BLL7 end

	// BLL10
	@isTest
    static void testLivePerson() {
        TestHelper_MW th = new TestHelper_MW();
        th.suspendDupeCatcher();
        
        Test.startTest();
        
        EmailParser parser = new EmailParser();
        EmailLeadHandler lh = new EmailLeadHandler();
        Messaging.InboundEmail email = new Messaging.Inboundemail();
        Messaging.Inboundenvelope env = new Messaging.Inboundenvelope();
        email.subject = 'ContactAtOnce! Test';
        email.fromname = 'From User'; 
        email.fromAddress = 'from@liveperson.com'; 
        email.plainTextBody= '<?xml version="1.0" encoding="utf-8"?><?adf version=1.0?>'
			+'<adf>' 
			+ '  <prospect>'
			+'<id sequence="1" source="ContactAtOnce">359298290</id>'
			+'    <requestdate>2019-12-11T18:58:31</requestdate>'
			+'    <vehicle interest="buy" status="used">'
			+'      <year>2018</year>'
			+'      <make>CHEVROLET</make>'
			+'      <model>2500 Van</model>'
			+'      <stock>ABC123</stock>'
			+'    </vehicle>'
			+'    <customer>'
			+'      <contact>'
			+'        <name part="first">Mickey</name>'
			+'        <name part="last">Mouse</name>'
			+'        <name part="full">Mickey Mouse</name>'
			+'        <email>mickey@mouse.com</email>'
			+'        <phone type="Cell">8885551212</phone>'
			+'        <address>'
			+'          <postalcode></postalcode>'
			+'        </address>'
			+'      </contact>'
			+'      <comments>.</comments>'
			+'    </customer>'
			+'    <vendor>'
			+'      <vendorname>Chad Motors</vendorname>'
			+'      <contact>'
			+'        <name part="full">Chad Motors</name>'
			+'        <email></email>'
			+'      </contact>'
			+'    </vendor>'
			+'    <provider>'
			+'      <id source=""></id>'
			+'      <name part="full">Chad Motors</name>'
			+'      <service>ContactAtOnce! Chat</service>'
			+'    </provider>'
			+'  </prospect>'
			+'</adf>';

        //Test parser independent of email service
		lh.handleInboundEmail(email, env);
        parser.processLivePersonPayloadXML(email.plainTextBody);

        Messaging.InboundEmail email2 = new Messaging.Inboundemail();
        Messaging.Inboundenvelope env2 = new Messaging.Inboundenvelope();
        email2.subject = 'ContactAtOnce! Test';
        email2.fromname = 'From User'; 
        email2.fromAddress = 'from@liveperson.com'; 
        email2.plainTextBody=''
			+ 'Hello. Here is a new lead for you: \n'
			+ 'Advertiser Name: Chad Motors \n'
			+ 'Notes: Note(chudson.2074090@im.contactatonce.com): Additional notes about the van \n'
			+ 'Name: Darth Vader \n'
			+ 'Phone: 18881234567 \n'
			+ 'Email: darth@vader.com \n'
			+ 'Contact Preference: Phone \n'
			+ 'Question: \n'
			+ 'Starting Time : 11-Dec-2019 2:43:14 PM Eastern Standard Time \n'
			+ 'Agent: Chad Hudson \n'
			+ 'VisitId: 359311020 \n'
			+ 'Origination: https://chadmotors.weebly.com/ \n'
			+ 'Transcript: [2:41:37 PM]CDK Called for customer data [2:41:39 PM]Agent Chad Hudson has accepted the conversation [2:41:46 PM]Test2 [2:41:50 PM]Gotcha [2:41:56 PM]More conversation [2:42:03 PM]Sounds good \n'
			+ 'View Conversation in Portal: https://portal.livepersonautomotive.com/CustomerPortal360.aspx?Load=/ReportModules/ConversationDetail/Index/359311020 \n'
			+ 'Thanks! \n'
			+ 'Kind regards, \n'
			+ 'Contact At Once! team. \n'
			+ 'Do not reply to this message. Emails sent to this email address are not monitored. \n'
		;
        //Test parser independent of email service
        parser.processLivePersonPayload(email2.plainTextBody);

	}
	// BLL10 end

}