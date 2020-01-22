/*
 * EmailLeadHandler
 * Tested by: Test_LeadClasses
 * 
 * Coverage:
 *	2018-04-23	85% (183/215)
 *	2018-04-24	85% (194/226)
 *	2018-08-16	86% (207/239)
 *  2019-12-13  78% (205/261)
 *
 * various   	B. Leaman   unmarked Add additional partner sources for emails
 * 2015-06-05	B. Leaman   BLL1 - Error notification recipients declared at the top for easy reference and adjustments;
 * 2015-08-17	B. Leaman   BLL2 - Remove doubled-up colons in case table cells already contain colons in the HTML body;
 * 2015-09-22	B. Leaman   BLL3 - Add Hascomed.com
 * 2016-01-11	B. Leaman	BLL4 - Added disableddealer.com, Hascomed ePrice Quote, PureChat, Uber, notification by group name.
 * 2016-01-19	B. Leaman	BLL5 - Better error logging using MonitorExecution class.
 * 2016-02-10	B. Leaman	BLL6 IT20089 - Just forward certain emails to ask@mobilityworks.com
 * 2016-02-15	B. Leaman	BLL7 - Crytico plaintextbody is not well formed. Use converted html body instead.
 * 2016-11-23	B. Leaman	BLL8 - BraunAbility leads to come from lead@braunability.com starting Dec. 1
 * 2017-06-12	B. Leaman	BLL9 - Don't report issues when "n ERRORS, m SUCCESSES" messages come from themobilityresource.
 *							Also don't send log email for chat box messages. These are already being entered manually before the
 *							email arrives. 
 * 2017-07-05	B. Leaman	BLL10 - handle <br> & </br> as well as <br /> and <br/> as new line indicator.
 * 2017-08-08	B. Leaman	BLL11 - AVA rentals don't have sufficient details - just forward email.
 * 2017-10-19	B. Leaman	BLL12 - log email service usage; use group emails for failure notifications.
 * 2017-11-21	B. Leaman	BLL13 - new AVA type of rental email -- free-format text reply to another email.
 * 2018-04-23	B. Leaman	BLL14 - skip purechat emails; handle MobilityWorks Online Store emails.
 * 2018-08-16	B. Leaman	BLL15 - forward harmar lead follow-ups directly to BDC reps.
 * 2019-05-20	B. Leaman	W-000698 BLL16 - Ava Rental Process updates - new layout of the email with sufficient data to generate the lead.
 * 2019-05-24	B. Leaman	W-000701 BLL17 - New leads from TheMobilityResource have blank plaintext bodies. Also standardize handling of whitespace before colons.
 * 2019-06-17	B. Leaman	W-000708 BLL18 Add MonitorExecution mon to parser
 * 2019-09-09	B. Leaman	W-000750 BLL19 - remove extra ':' from The MobilityResource data
 * 2019-12-13	B. Leaman	W-000803 BLL20 - Map LivePerson emails and forward problem rental emails (AVA) to rentals@mobilityworks.com
 * 2019-12-20	B. Leaman	BLL21 - forward emails that do not map to ask@mobilityworks.com instead of sending Ron a data dump email.
 */
global class EmailLeadHandler implements Messaging.InboundEmailHandler {
    // List of recipients for failure notifications
    String[] failureRecipients = new String[] {'salesforce.developers@mobilityworks.com'}; //BLL12c  {'jarrett@dealerteam.com', 'bryan.leaman@mobilityworks.com'};
    String failureGroup = 'LeadEmailFailure';
    List<String> rentalRecipients = new List<String>{'rentals@mobilityworks.com'};	// BLL11a
    String HarmarLeadFollowupRecipients = 'bdc@mobilityworks.com;stan.bailey@mobilityworks.com';	// BLL15a
    
	static boolean isSandbox = [SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox;
    Boolean lead_parsed_successfully = true;  // BLL5a default to true so we don't get 2 error emails if parser not found

	MonitorExecution mon; // BLL5a

	// BLL4a
	public EmailLeadHandler() {
		getFailureRecipients(failureGroup);
		mon = new MonitorExecution('EmailLeadHandler'); // BLL5a
	}
	
	public List<String> getFailureRecipients(String groupname) {
		Id failureGroupId = null;
		try {
			Group g = [select Id, Name from Group where Type='Regular' and DeveloperName=:groupname limit 1];
			failureGroupId = g.Id;
		} catch(Exception e) {}
		String[] recipients = getGroupEmails(failureGroupId);
		if (recipients.size()>0) {
			failureRecipients = new List<String>();
			failureRecipients.addAll(recipients);
		}
		return recipients;
	}
	

	// getGroupEmails - Return list of email addresses for all public group members
	public List<String> getGroupEmails(Id groupid) {
		List<String> emails = new List<String>();
		Set<Id> mbrIds = new Set<Id>();
		for(GroupMember gm : [select Id, userOrGroupId from GroupMember where GroupId=:groupid]) mbrIds.add(gm.userOrGroupId);
        for(User u : [select Email from User where Id in :mbrIds]) {
        	if (u.Email!=null) emails.add(u.Email);
        }
        // does not handle roles or roles and subordinates
        for(Group subGroup : [select Id, Name from Group where Id in :mbrIds]) {
        	emails.addAll(getGroupEmails(subGroup.Id));
        }
		return emails;		
	}

	// BLL4a end

    /* Email Parser */
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

		new EmailServiceLog('EmailLeadHandler').increment();	// BLL12a

        Messaging.Inboundemailresult result = new Messaging.Inboundemailresult();       
        if(result.success) {
        	if (mon!=null) mon.log('From: ' + email.fromAddress + '; Subject=' + email.Subject);
        	if (mon!=null) mon.log('plainTextBody='+showWhitespace(email.plainTextBody));  // BLL5a
        	if (mon!=null) mon.log('htmlBody='+showWhitespace(email.htmlBody));  // BLL5a
            String plainTextBody = email.plainTextBody;
            String convertedBody = null;
            if (email.htmlBody!=null) convertedBody = convertToPlainText(email.htmlBody);
            //System.debug('Plain body='+plainTextBody);
            // code to handle htmlBody if plainTextBody is missing?
            if (String.isBlank(plainTextBody) && convertedBody<>null) {
                plainTextBody = convertedBody;
                //System.debug('New body='+plainTextBody);
	            if (mon!=null) mon.log('convertToPlainText='+showWhitespace(convertedBody));  // BLL5a
            }
            if (isSandbox) System.debug(plainTextBody);

            if(!String.isBlank(plainTextBody)) {
                try {
                    // Alternate Parsers based on lead source
                    // BLL18
					//EmailParser p = new EmailParser();
					EmailParser p = new EmailParser(mon);
					// BLL18 end
     
     				System.debug(email.fromAddress);  // BLL4a
     				System.debug(email.Subject);  // BLL4a
     
     				// BLL11a
     				//System.debug(email.htmlBody);
     				//System.debug(email.htmlBody.contains('ava.mobilitypluscrm.com'));
     				if ((email.subject.containsIgnoreCase('AVA Rental Request') && email.htmlBody!=null && email.htmlBody.contains('ava.mobilitypluscrm.com'))
     					|| (email.subject.containsIgnoreCase('Rental Lead') && email.fromAddress.contains('accessiblevans.com'))
     					|| (email.subject.containsIgnoreCase('Rental Question') && email.fromAddress.contains('accessiblevans.com'))
     					|| (email.subject.containsIgnoreCase('Reservation') && email.subject.contains('Accessible Vans Of America'))	// BLL13a
						|| (email.fromAddress.containsIgnoreCase('accessiblevans.com')) // BLL20
     					|| (email.subject.containsIgnoreCase('Accessible Vans') && email.subject.contains('Accessible Vans Of America'))	// BLL20
     					|| (email.subject.containsIgnoreCase('Rental Quote') && email.subject.contains('Accessible Vans Of America'))	// BLL20
     					) {	// BLL11a
						// BLL16a
     					//forwardRental(email, envelope);
						convertedBody = convertToPlainText4(email.htmlBody);	
						convertedBody = convertedBody.replaceAll('(\n)+','\n');	
						if (mon!=null) mon.log('AVA converted body='+showWhitespace(convertedBody));
						lead_parsed_successfully = p.processAvaPayload(convertedBody);
						// BLL16
						// BLL20
						if (!lead_parsed_successfully) {
							forwardRental(email, envelope);
							lead_parsed_successfully = true;	// don't handle as an error
						}
						// BLL20 end
     				} else
     				// BLL11a
     
     				// BLL6a
     				if (email.subject.containsIgnoreCase('CallSource Scheduled Report (CDR)')) {
     					notifyAskAt(email);
     					lead_parsed_successfully = true;
     				} else
     				// BLL6a end
     
                    //braunlift.com
                    if(email.fromAddress.containsIgnoreCase('braunlift.com') 
                       || email.fromAddress.containsIgnoreCase('braunability') 
                       || email.subject.containsIgnoreCase('Braun') 
                       || email.subject.containsIgnoreCase(' AbilityLead ')) {	// BLL8c add braunability
                        System.debug('email from braunlift');
                        if (mon!=null) mon.log('processBraunPayload');  // BLL5a
                        lead_parsed_successfully = p.processBraunPayload(plainTextBody); 
                    } else 
                      // bruno
                      if(email.fromAddress.contains('brunopartner.com') || email.subject.contains('Bruno')) {
                        System.debug('email from brunopartner');
                        if (mon!=null) mon.log('processBrunoPayload');  // BLL5a
                        lead_parsed_successfully = p.processBrunoPayload(plainTextBody);
                    } else
                      // mobility resource 
                      if(email.fromAddress.containsIgnoreCase('themobilityresource.com') 
                      	|| email.subject.containsIgnoreCase('The Mobility Resource') 
                      	|| email.subject.containsIgnoreCase('TheMobilityResource')) {
                        System.debug('email from themobilityresource');
                        if (mon!=null) mon.log('processMobilityResourcePayload'); // BLL5a
                        plainTextBody = plainTextBody.replace('*',' '); // BLL5a started getting *INTEREST:* instead of INTEREST:
                        // BLL9a - skip ERRORS SUCCESSES emails
                        String line1 = plainTextBody.left(plainTextBody.indexOf('\n'));
                        if (!String.isBlank(line1) && line1.contains('ERRORS') && line1.contains('SUCCESSES')) {
                        	lead_parsed_successfully = true;
                        } else {
                        // BLL9a end
							// BLL17 labels and data on different rows!
							//if (!String.isBlank(email.htmlBody)) plainTextBody = convertToPlainText4(email.htmlBody);	
							//if (!String.isBlank(html)) plainTextBody = convertToPlainText4(html);	
							//plainTextBody = plainTextBody.replaceAll('(\n)+','\n');	
							// BLL17 end
							// BLL17
							String html = email.htmlBody;
							html = html.replace('</strong>', '</strong>:');
							html = html.replaceAll('<[^>]*>','');  // my strip tags
							html = html.replaceAll('\\s+&nbsp;\\s+','');	// bring data row up to label row
							html = html.replaceAll(':\\s+:', ':');	// collapse multiple colons
							html = html.replaceAll('::',':');	// BLL19a
							plainTextBody = html;
							if (mon!=null) mon.log('TheMobilityResource converted body='+showWhitespace(plainTextBody));
							// BLL17 end
                        	lead_parsed_successfully = p.processMobilityResourcePayload(plainTextBody);
                        }	// BLL9a
                    } else
                      // VMI 
                      if(email.fromAddress.containsIgnoreCase('gate6.com') || email.fromAddress.contains('VantageMobility.com') 
                         || email.subject.containsIgnoreCase('SDN')  
                         || email.subject.containsIgnoreCase('VMI')  
                         || email.subject.containsIgnoreCase('Dare to Compare')) {
                        System.debug('email from VMI (gate6.com)');
                        if (mon!=null) mon.log('processVMIPayload');  // BLL5a
                        lead_parsed_successfully = p.processVMIPayload(plainTextBody);
                    } else
                      // MobilitySales
                      if(email.fromAddress.containsIgnoreCase('mobilitysales.com')  
                         || email.subject.containsIgnoreCase('Mobility Works Form')) {
                        System.debug('email from MobilitySales (mobilitysales.com)');
                        if (mon!=null) mon.log('processMobilitySalesPayload');  // BLL5a
                        lead_parsed_successfully = p.processMobilitySalesPayload(plainTextBody);
                    } else
                      // MobilityVanSales
                      if(email.fromAddress.containsIgnoreCase('mobilityvansales.com')  
                         || plainTextBody.containsIgnoreCase('mobilityvansales.com')) {
                        System.debug('email from MobilityVanSales (mobilityvansales.com)');
                        if (mon!=null) mon.log('processMobilityVanSalesPayload');  // BLL5a
                        lead_parsed_successfully = p.processMobilityVanSalesPayload(plainTextBody);
                    } else
                      // UnitedAccess
                      if(email.fromAddress.containsIgnoreCase('unitedaccess.com')  
                         || email.subject.containsIgnoreCase('United Access')) {
                        System.debug('email from UnitedAccess (unitedaccess.com)');
                        if (mon!=null) mon.log('processUnitedAccessPayload');  // BLL5a
                        lead_parsed_successfully = p.processUnitedAccessPayload(plainTextBody);
					// BLL20d
                    //} else
                    //  // AccessibleVans (AVA)
                    //  if(email.fromAddress.containsIgnoreCase('accessiblevans.com')  
                    //     || email.subject.containsIgnoreCase('Ava lead')
                    //     || email.subject.containsIgnoreCase('Accessible Vans')) {
                    //    System.debug('email from AccessibleVans (accessiblevans.com)');
                    //    if (mon!=null) mon.log('processAvaPayload');  // BLL5a
                    //    lead_parsed_successfully = p.processAvaPayload(plainTextBody);
					//	// BLL20
					//	if (!lead_parsed_successfully) {
					//		forwardRental(email, envelope);
					//		lead_parsed_successfully = true;	// don't handle as an error
					//	}
					//	// BLL20 end
					// BLL20 end
                    } else
                      // Harmar :: Lead Follow-Up -> forward to BDC
                      if(email.subject.containsIgnoreCase('Harmar :: Lead Follow-Up')) {
                        System.debug('Lead followup email from Harmar');
                        if (mon!=null) mon.log('forward to BDC');  // BLL5a
     					forwardTo(email, envelope, HarmarLeadFollowupRecipients);
                    } else
                      // Harmar
                      if(email.fromAddress.containsIgnoreCase('harmar-mailer')  
                         || email.subject.containsIgnoreCase('from Harmar')
                         || email.subject.containsIgnoreCase('[HARMAR]')) {
                        System.debug('email from Harmar (harmar.mailer)');
                        if (mon!=null) mon.log('processHarmarPayload');  // BLL5a
                        lead_parsed_successfully = p.processHarmarPayload(plainTextBody);
                    } else
                      // Crytico
                      if(email.fromAddress.containsIgnoreCase('mandrillapp.com')
                         || email.fromAddress.containsIgnoreCase('crytico.com')  
                         || email.subject.containsIgnoreCase('Crytico')) {
                        System.debug('email from Crytico (mandrillapp.com)');
                        if (mon!=null) mon.log('processCryticoPayload');  // BLL5a
                        // BLL7c - use converted body instead of plain text body, if available
                        if (!String.isBlank(convertedBody)) lead_parsed_successfully = p.processCryticoPayload(convertedBody);
                        else lead_parsed_successfully = p.processCryticoPayload(plainTextBody);
                    } else // BLL4a
                      // ePrice Quote - BLL4a
                      if(email.fromAddress.containsIgnoreCase('web@hascomed.com')
                      	 || email.subject.containsIgnoreCase('ePrice Quote')) {
                      	 System.debug('email from ePrice Quote web@hascomed.com');
                      	 convertedBody = convertToPlainText4(email.htmlBody);
                         if (isSandbox) System.debug(convertedBody);
                      	 if (mon!=null) mon.log('convertToPlainText4=' + showWhitespace(convertedBody));
                         if (mon!=null) mon.log('processEPriceQuotePayload');  // BLL5a
                      	 lead_parsed_successfully = p.processEPriceQuotePayload(convertedBody);
                    } else
                      // Hascomed (BLL3a) - always use converted HTML body
                      if(email.fromAddress.containsIgnoreCase('hascomed.com')
                         || email.fromAddress.containsIgnoreCase('Hascomed.com')  
                         || email.subject.contains('HASCO')) {
                        System.debug('email from Hasco (hascomed.com)');
                        convertedBody = convertToPlainText2(email.htmlBody);
                        if (isSandbox) System.debug(convertedBody);
                     	if (mon!=null) mon.log('convertToPlainText2=' + showWhitespace(convertedBody));
                        if (mon!=null) mon.log('processHascoPayload');  // BLL5a
                        lead_parsed_successfully = p.processHascoPayload(convertedBody);
                    } else // BLL4a
                      // disableddealer.com - BLL4a
                      if(email.fromAddress.containsIgnoreCase('disableddealer.com')
                      	 || email.subject.contains('Free Copy Request')) {
                      	 System.debug('email from disableddealer.com');
                         if (mon!=null) mon.log('processDisabledDealerPayload');  // BLL5a
                      	 lead_parsed_successfully = p.processDisabledDealerPayload(plainTextBody);
                    } else // BLL4a
                      // PureChat - BLL4a
                      if(email.fromAddress.containsIgnoreCase('PureChat.com')	// BLL14c
                      	 || email.subject.containsIgnoreCase('Ride-Away widget')) {	// BLL14c 
                      	 System.debug('email from PureChat -- skipped');
                         if (mon!=null) mon.log('processPureChatPayload');  // BLL5a
                      	 // BLL14d lead_parsed_successfully = p.processPureChatPayload(plainTextBody);
                    } else // BLL4a
                      // Uber - BLL4a
                      if(email.fromAddress.containsIgnoreCase('wufoo.com')
                      	 || email.subject.contains('Uber ')) {
                      	 System.debug('email from Uber');
                      	 convertedBody = convertPlainText3(plainTextBody);
                         if (isSandbox) System.debug(convertedBody);
                     	 if (mon!=null) mon.log('convertToPlainText3=' + showWhitespace(convertedBody));
                         if (mon!=null) mon.log('processUberPayload');  // BLL5a
                      	 lead_parsed_successfully = p.processUberPayload(convertedBody);
					// BLL20
					} else if (email.subject.containsIgnoreCase('ContactAtOnce')) { 
						System.debug('email from LivePerson');
						if (isSandbox) System.debug(plainTextBody);
						if (mon!=null) mon.log('plainTextBody=' + showWhitespace(plainTextBody));
						if (plainTextBody.startswith('<?xml ')) {
							if (mon!=null) mon.log('processLivePersonPayloadXML');
							lead_parsed_successfully = p.processLivePersonPayloadXML(plainTextBody);
						} else {
							if (mon!=null) mon.log('processLivePersonPayload');
							lead_parsed_successfully = p.processLivePersonPayload(plainTextBody);
						}
					// BLL20 end
                    // BLL14a
                    } else 
                      if (email.subject.containsIgnoreCase('[MobilityWorks Online Store]')) {
                      	 convertedBody = plainTextBody;
                         if (isSandbox) System.debug(convertedBody);
                     	 if (mon!=null) mon.log('convertToPlainText=' + showWhitespace(convertedBody));
                         if (mon!=null) mon.log('processUberPayload');  // BLL5a
                      	 lead_parsed_successfully = p.processECommerce(convertedBody);
                    } else {
                    	if (mon!=null) mon.log('Unable to determine email process to use');  // BLL5a
		               	// BLL9a - ignore messages from MobilityWorks chat box
		               	if (!email.subject.startsWith('Question from ') || !email.subject.endsWith(' chat box.'))	// BLL9a
			               	if (mon!=null) mon.notifyAdmin(); // BLL5a
                        //notifyUnrecognizedEmail('Lead Email not expected',
                        //   'From: ' + email.fromAddress + ' Subject: ' + email.subject + '\n\n' + plainTextBody);
		               	if (!email.subject.startsWith('Question from ') || !email.subject.endsWith(' chat box.'))	// BLL9a
							notifyAskAt(email);
                    }
                    // If not parsed, notify Bryan L
                    if (!lead_parsed_successfully) {
                    	if (mon!=null) mon.log('Email parser returned false (unsuccessful)');  // BLL5a
                    	if (mon!=null) mon.log('ValueMap=' + JSON.serialize(p.valueMap));
		               	if (mon!=null) mon.notifyAdmin(); // BLL5a
                    	notifyUnrecognizedEmail('Error parsing email from ' + email.fromAddress,
                    	   email.htmlBody);
						// BLL21
     					notifyAskAt(email);
						// BLL21 end
                    }
                } catch(Exception e) {
                	if (mon!=null) mon.log('Exception: ' + e.getMessage() + '\r' + e.getStackTraceString()); // BLL5a
	               	if (mon!=null) mon.notifyAdmin(); // BLL5a
                    notifyUnrecognizedEmail('Error processing email',
                       'Error: ' + e.getMessage() + '\r' + e.getStackTraceString() + '\n' +
                       'From: ' + email.fromAddress + ' Subject: ' + email.subject + '\n\n' + plainTextBody);
					// BLL21
   					notifyAskAt(email);
					// BLL21 end
                }
            } else {
               	if (mon!=null) mon.log('Unable to obtain body of email'); // BLL5a
               	if (mon!=null) mon.notifyAdmin(); // BLL5a
                notifyUnrecognizedEmail('Lead Email has no plain text body',
                       'From: ' + email.fromAddress + ' Subject: ' + email.subject + '\n\n' + email.htmlBody);
				// BLL21
				notifyAskAt(email);
				// BLL21 end
            }
        }
        if (mon!=null && mon.AlwaysNotify) mon.notifyAdmin(); // BLL5a
        return result;
    }
    /*
    global String fromDomain(Messaging.InboundEmail.Header emailHeaders) {
        String rfc2822_from_address;
        for(Messaging.InboundEmail.Haeder : emailHeaders) {
            if()
        }
    }
    */

	public void notifyAskAt(Messaging.InboundEmail email) {
        Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
        List<String> toAddresses = new List<String>();
        toAddresses.add(isSandbox ? UserInfo.getUserEmail() : 'ask@mobilityworks.com');
        mail.setToAddresses(toAddresses);
        mail.setSubject(email.subject);
        mail.setPlainTextBody(email.plainTextBody);
        mail.setHTMLBody(email.htmlBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });      
	}

	// BLL11a
	public void forwardRental(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
        List<String> toAddresses = new List<String>();
        toAddresses.addAll(isSandbox ? new List<String>{ UserInfo.getUserEmail() } : rentalRecipients);
        mail.setToAddresses(toAddresses);
        mail.setSubject('FW: ' + email.subject);
        mail.setPlainTextBody(email.plainTextBody);
        mail.setHTMLBody(email.htmlBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });      
	}
	// BLL11a

	// BLLa
	public void forwardTo(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope, String recipients) {
        Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
        List<String> toAddresses = new List<String>();
        toAddresses.addAll(isSandbox ? new List<String>{ UserInfo.getUserEmail() } : recipients.split(';'));
        mail.setToAddresses(toAddresses);
        mail.setSubject('FW: ' + email.subject);
        mail.setPlainTextBody(email.plainTextBody);
        mail.setHTMLBody(email.htmlBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });      
	}
	// BLLa end

    public String convertToPlainText(String html) {
        String body = html;
        // Remove style block
        body = body.replaceAll('<head>.*</head>','');
        // ensure there are newlines
        //body = body.replace('Â','');  // BLL3a
        body = body.replace('</tr>', '</tr>\n').replace('</p>','</p>\n').replaceAll('</td>\\s+<td', ':</td><td');
        body = body.replace('::', ':'); // BLL2a
        body = body.replace('<br />','\n').replace('<br/>','\n').replace('<br>','\n').replace('</br>','\n'); // BLL5a, BLL10c 
        body = body.replace('\n','{|}').stripHtmlTags().replace('{|}','\n').replaceAll(':\\s*:', ':');
        //BLL5 now that we've done the special stuff ...
        //body = body.stripHtmlTags(); // BLL5 don't use this, it removes new lines too. Ugh!
        body = body.replaceAll('<[^>]*>','');  // my strip tags 
		body = body.replaceAll('\\s+:', ':');	// eliminate white space in front of colons BLL17
        System.debug(body.left(1024));
        return body;
    }


    public String convertToPlainText2(String html) {
        String body = html;
        // Remove style block
        body = body.replaceAll('<head>.*</head>','');
        // ensure there are newlines
        body = body.replaceAll('[^a-zA-Z0-9\\p{Punct}\\p{Space}]','');  // BLL3a - remove non-ascii
        body = body.replace('</tr>', '</tr>{|}').replaceAll('</td>\\s+<td', ':</td><td');
        body = body.replace('{&#124;}',' ').replace('&nbsp;',' ');
        //System.debug(body);
        //body = body.stripHtmlTags();
        body = body.replace('<br />','\n').replace('<br/>','\n'); // BLL5a 
        body = body.replaceAll('<[^>]*>','');  // my strip tags
        body = body.replace('{|}','\n').replaceAll(':\\s+:', ':').replaceAll('\\s+:', ':');
        System.debug(body.left(1024));
        return body;
    }

	// BLL4a
    public String convertPlainText3(String text) {
    	String body = text;
    	body = body.replaceAll('\\*\\s',':');
    	body = body.replaceAll('(\\n)*:',':').replaceAll('(\\r)*:',':');
    	body = body.replaceAll(':(\\n)*',':').replaceAll(':(\\r)*',':');
		body = body.replaceAll('\\s+:', ':');	// eliminate white space in front of colons BLLx
    	System.debug(body.left(1024));
    	return body;
    }


    public String convertToPlainText4(String html) {
        String body = html;
        // Remove style block
        body = body.replaceAll('<head>.*</head>','');
        // ensure there are newlines
        body = body.replaceAll('[^a-zA-Z0-9\\p{Punct}\\p{Space}]','');  // BLL3a - remove non-ascii
        body = body.replace('</tr>', '</tr>{|}').replaceAll('</td>\\s+<td', ':</td><td');
        body = body.replace('{&#124;}',' ').replace('&nbsp;',' ');
        //System.debug(body);
        //body = body.stripHtmlTags();
        body = body.replace('<br />','\n').replace('<br/>','\n'); // BLL5a 
        body = body.replaceAll('<[^>]*>','');  // my strip tags
        body = body.replace('{|}','\n').replaceAll(':\\s+:', ':').replaceAll('\\s+:', ':');
        System.debug(body.left(1024));
        //body = convertPlainText3(body);
		body = body.replaceAll('\\s+:', ':');	// eliminate white space in front of colons BLLx
        System.debug(body.left(1024));
        return body;
    }

    // BLL4a end
    
    // BLL5a
    public String showWhitespace(String s) {
    	//return s.replace('\r','\\r\r').replace('\n','\\n\n').replace('\t','\\t\t');
    	return s==null ? '' : s.escapeJava();
    }
    // BLL5a end
    
    public void notifyUnrecognizedEmail(String subject, String message) {
             Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
             String[] toAddresses = new String[] {'bdc.automation@mobilityworks.com','bdc@mobilityworks.com'}; //BLL14c		// BLL12c {'bryan.leaman@mobilityworks.com', 'nathan.ahrens@mobilityworks.com'};
             //mail.setToAddresses(toAddresses); // BLLd
             mail.setToAddresses(failureRecipients);  // BLLa
             mail.setSubject(subject + ' from Org : ' + UserInfo.getOrganizationName());
             mail.setPlainTextBody(message);
             // BLL21d Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });      
    }
    
}