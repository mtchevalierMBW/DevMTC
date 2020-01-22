/**
 * PurchaseOrderEmailHandler
 * Tested by: PurchaseOrderEmailHandler_TEST
 * Date: May 5, 2017
 * Programmer: Bryan Leaman
 *
 * Code coverage log:
 * 	2017-09-11	81% (76/93)
 *	2018-01-03	85% (101/118)
 * 
 * Process incoming email attachments, find the DealerTeam PO that matches the PO number in the name, and 
 * attach each attachment to the corresponding PO header document.
 * 
 * Service managers (and others) can email one or more packing lists (or other related documents) by emailing
 * them to the email handler or even do so right at the copier/scanner by assigning a file name that contains the PO number.
 *
 *	2017-08-14	B. Leaman	BLL1 - better logging in return email. Also, copy admin.
 *	2017-08-31	B. Leaman	BLL2 - Hack: Don't send reply to it_admin@mobilityworks.com.
 *	2017-09-08	B. Leaman	BLL3 - Treat dashes as underscores (PO NWD115080-1_001.pdf is not PO 1150801, it's PO 115080.)
 *	2017-09-11	B. Leaman	BLL4 - improve handling of dashes and non-numerics. Convert all non-numeric to '_' and remove all leading '_'.
 *							The first numeric string must be the PO number.
 *	2017-10-19	B. Leaman	BLL5 - log email service usage.
 *	2017-12-14	B. Leaman	BLL6 - Skip image[0-9].jpg - company logo in signature. 
 *  2018-10-03  A. Miller   AMM7 - W-000413 - Update ot handle Lightning only file/attachment archicture for Lightning implementation 
 *  2018-11-14  A. Miller   AMM8 - IR-0043891 - Update so error messages don't sent with every email due to null value checking
 *	2019-08-15	B. Leaman	BLL7 - W-000740 - standardize printer name so correct location code can be determined.
 *	2019-09-30	B. Leaman	BLL8 - support for PO# in subject line instead of file name
 */
global class PurchaseOrderEmailHandler implements Messaging.InboundEmailHandler {

	// handleInboundEmail
	//---------------------------------------
	global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

		new EmailServiceLog('PurchaseOrderEmailHandler').increment();	// BLL5a

		Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
		
		String fromAddr = email.fromAddress;
		String results = '';
		String errors = '';
		String hostname = 'mbw.my.salesforce.com';
		// BLL8 - support for regex finding PO# in email subject line
		String re = '((^|[^0-9])([0-9]{5,8})($|[^0-9]))';
		Pattern p = Pattern.compile(re);
		// BLL8 end

		// AMM7
		LightningFileUtility tempUtility = new LightningFileUtility();
		// AMM7
		
		System.debug('Received from: ' + email.fromAddress);

		// sandbox?
		//Organization org = [select Id, Name, isSandbox from Organization limit 1];
		Organization org = OrganizationSingleton.getInstance();
		if (org.isSandbox) {
			hostname = 'test.salesforce.com'; 
			try {
				hostname = email.toAddresses[0].substringBeforeLast('.apex.sandbox.salesforce.com').substringAfterLast('.') + '.salesforce.com';
			} catch(Exception e) {}
		}
		
		// Sender's salesforce user record?
		User sender = null;
		try { sender = [select Id, Name, email from User where isActive=true and Email=:email.fromAddress limit 1]; }
		catch(Exception e) {}
		
		// Get binary attachments and try to find PO# in the names
		List<String> ponames = new List<String>();
		Integer pocount = 0;
		if (email.binaryAttachments==null) errors += 'No attachments to process\n';
		if (email.binaryAttachments!=null && email.binaryAttachments.size()>0) {
			for(Messaging.Inboundemail.BinaryAttachment att : email.binaryAttachments) {
				System.debug('Attachment: ' + att.fileName);
				String filename = att.fileName;
					String poname = filename.substringBeforeLast('.');
					// massage out characters, dashes, copy indicators e.g. (2)
					//BLL4d poname = poname.replaceAll('\\-','_');	// BLL3a
					//BLL4d poname = poname.replaceAll('[A-Za-z#]','');	// BLL3c
					//BLL4d poname = poname.replaceAll('\\([0-9_]*\\)','');	// BLL3c
					poname = poname.replaceAll('[^0-9]',' ');	// BLL4a
					poname = poname.trim();	// BLL4a
					//BLL4d if (poname.contains('_')) poname = poname.substringBefore('_');
					if (poname.contains(' ')) poname = poname.substringBefore(' ');	// BLL4a
					//BLL4d poname = poname.trim();
					if (poname.length()<6) {
						poname = '000000' + poname;
						poname = poname.right(6);
					}
					// BLL8
					// if all zeros, try the email subject instead
					if (poname=='000000') {
						Matcher m = p.matcher(email.subject);
						if (m.find()) poname = m.group(m.groupCount()-1);
					}
					// BLL8 end
					ponames.add('PO#'+poname);
					if(!String.isBlank(poname)) pocount++;
			}
		}
		if (pocount==0) errors += 'No PO numbers found in attachments\n'; 
		
		// Map of POs by name
		System.debug(ponames);
		Map<String,dealer__Purchase_Order__c> pomap = new Map<String,dealer__Purchase_Order__c>();
		for(dealer__Purchase_Order__c po : [
			select Id, Name, dealer__PO_Accounting_Name__c
			from dealer__Purchase_Order__c
			where Name in :ponames
		]) pomap.put(po.Name, po); 
		
		// Now assign parent Ids, log matches/mis-matches and save
		List<Attachment> attList = new List<Attachment>();
		if (email.binaryAttachments!=null && email.binaryAttachments.size()>0) {
			for(Integer i=0; i<email.binaryAttachments.size(); i++) {
				Messaging.Inboundemail.BinaryAttachment att = email.binaryAttachments[i];
				String po = ponames[i];

				System.debug('Attachment: ' + att.fileName);	// BLL6a
				String filename = att.fileName;	// BLL6a

				// BLL6a
				if (filename!=null && filename.startswith('image') && filename.endswith('.jpg')) {
					System.debug('Skip company logo in signature: ' + filename);
				} else {
				// BLL6a end
	
					dealer__Purchase_Order__c dtpo = pomap.get(po);
					if (dtpo!=null) {
						// AMM7
						// Attachment attachment = new Attachment(
						// 	Name = att.fileName, Body = att.body, ParentId = dtpo.Id, ContentType=att.mimeTypeSubType
						// );
						// Try to specify sender as the creator of the attachment
						// if (sender!=null) attachment.CreatedById=sender.Id;
						// attList.add(attachment);
						// String attSts = att.fileName + ' : ' + '<a href="https://' + hostname + '/' + dtpo.Id + '">' + dtpo.dealer__PO_Accounting_Name__c  + '</a>';
						// System.debug(attSts);
						Id ownerId = null;
						if (sender!=null) ownerId=sender.Id;
						tempUtility.addFile(att.fileName, EncodingUtil.base64Encode(att.body), dtpo.Id, false, ownerId);
						String attSts = att.fileName + ' : ' + '<a href="https://' + hostname + '/' + dtpo.Id + '">' + dtpo.dealer__PO_Accounting_Name__c  + '</a>';
						System.debug(attSts);
						// AMM7

						results += attSts + '<br/>';
						
					} else {
						System.debug(att.fileName + ' PO not found');
						if (String.valueOf(po)=='PO#000000') errors += att.fileName + ' : Error : PO number not found in attachment name' + '<br/>';
						else errors += att.fileName + ' : Error : Purchase order ' + String.valueOf(po) + ' not found' + '<br/>';
					}

			/** files
		List<ContentVersion> cvlist = new List<ContentVersion>();
		List<ContentDocumentLink> cdllist = new List<ContentDocumentLink>();
		ContentVersion cv = new ContentVersion(
			ContentDocumentId = null, 	// new file
			ContentLocation = 'S',		// vs. E=External
			Title = att.fileName,
			FileType = att.mimeTypeSubType,
			Description = att.fileName;
			//cv.VersionData = att.body;
			VersionData = EncodingUtil.base64Encode(att.Body),
			FileExtension = att.fileName.afterLast('.'),
			//pathOnClient = null,
			//cv.Origin='C',	// dft 'C' = user's personal library; vs 'H' = Chatter.
			SharingOption = 'Allowed' 	//| 'Restricted';
		);
		cvlist.add(vc);

		ContentDocumentLink cdl = new ContentDocumentLink(
			//ContentDocumentId = cv.Id, // need to wait for attachment id
			LinkedEntityId = dtpo.Id,
			ShareType = 'V'
		);
		cdllist.add(cdl);

		files end **/		


				}	// BLL6a

			}
		}
		// AMM7
		//List<Database.SaveResult> saveresults = Database.insert(attList);
		tempUtility.commitFiles();
		// AMM7

		/** files 
		List<Database.SaveResult> saveresults = Database.insert(cvlist);
		for(Integer i=0; i<cvlist.size(); ++i) cdllist[i].ContentDocumentId = cvlist[i].Id;
		List<Database.SaveResult> saveresults2 = Database.insert(cdllist);
		files end **/
		
		//for(Database.SaveResult sr : saveresults) {
		// AMM7
		// for(Integer i=0; i<saveresults.size(); i++) {
		// 	Database.SaveResult sr = saveresults[i];
		// 	Attachment a = attList[i];
		// 	// ContentVersion a = cvlist[i];	// Files
		// 	System.debug(sr);
		// 	if (!sr.isSuccess()) {
		// 		errors += sr.getId() + ': ';
		// 		for(Database.Error de : sr.getErrors()) errors += a.Name + ' Error : ' + de.getMessage() + '[' + String.join(de.getFields(),', ') + '] ' + '<br/>';
		// 	}
		// }
		// AMM8
 		// errors = tempUtility.getErrorsHTML();
 		if( (errors == null || String.isEmpty(errors)) && (tempUtility.getErrorsHTML() == null || String.isEmpty(tempUtility.getErrorsHTML() ) ) )
 		{
 			errors = '';
 		}		
 		//AMM8
		// AMM7

		emailResults(email, results, errors);
		
		return result;
	}
	
	
	public void emailResults(Messaging.InboundEmail email, String results, String errors) {
		List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
		//List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();
		boolean AlwaysSendReply = true;
		String body = '';

		String replyTo = email.fromAddress;
		Map<String,dealer__Dealer_Location__c> locmap = locationMap();
		
		// get printer name from sender address or subject
		String printername = '';
		List<String> words = new List<String>();
		if (email.fromAddress.toUpperCase().contains('-PTR-')) words.addAll(email.fromAddress.toUpperCase().split(' '));
		if (email.subject.toUpperCase().contains('-PTR-')) words.addAll(email.subject.toUpperCase().split(' '));
		for(String w : words) if ( String.isBlank(printername) && w.contains('-PTR-')) printername = w;
		// BLL7 - standardize printer name, remove everything except alphanumeric and dash
		if (!String.isBlank(printername)) printername = printername.replaceAll('[^A-Z0-9\\-]','');
		// BLL7 end
		if (!String.isBlank(printername)) body += '<p>Printer name: ' + printername + '</p>';

		//String coNbr = email.fromAddress.toUpperCase().substringBefore('-PTR-');
		String coNbr = '';
		if (!String.isBlank(printername)) coNbr = printername.substringBefore('-PTR-');
		if (locmap.containsKey(coNbr)) {
			dealer__Dealer_Location__c loc = locmap.get(coNbr);
			if (loc!=null && loc.dealer__Service_Director__c!=null && !String.isBlank(loc.dealer__Service_Director__r.Email)) {
				replyTo = loc.dealer__Service_Director__r.Email;
				AlwaysSendReply = false;
			}
		}
		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		//mail.setToAddresses(new String[] { UserInfo.getUserEmail() });
		// BLL1d mail.setToAddresses(new String[] { replyTo });
		// BLL1a
		List<String> toaddresses = new List<String>();	// BLL2c
		if (replyTo!='it_admin@mobilityworks.com' && replyTo!='mbwrelay@mobilityworks.com' 
			&& !replyTo.toUpperCase().contains('-PTR-')) toaddresses.add(replyTo);	// BLL2a	
		MonitorExecution mon = new MonitorExecution('PurchaseOrderEmailHandler');
		User u = mon.getAdmin();
		if (u!=null && (mon.AlwaysNotify || !String.isBlank(errors))) toaddresses.add(u.Email);
		if (toaddresses.size()>0) mail.setToAddresses(toaddresses);	// BLL2c	
		// BLL1a end 
		
		mail.setSubject('Results for: ' + email.subject);
		body += '<p>email received from ' + email.fromAddress + '</p>';	// BLL1a
		body += '<p>PO attachments processed:</p>';
		body += String.isBlank(results) ? 'none' : results;
		if (!String.isBlank(errors)) {
			body += '<p>Errors:</p>' + errors;
		}
		// BLL1a for debugging
		body += '<div style="display:none;">' + email.plainTextBody + '</div>\n';
		mail.setHTMLBody(body);
		
		// duplicate all attachments!
		MW_TriggerControls__c PurchaseOrderEmailHandlerAtt = MW_TriggerControls__c.getInstance('PurchaseOrderEmailHandlerAtt');
		if (PurchaseOrderEmailHandlerAtt!=null && PurchaseOrderEmailHandlerAtt.Enabled__c) {
			List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();
			if (email.binaryAttachments!=null && email.binaryAttachments.size()>0) {
				for(Integer i=0; i<email.binaryAttachments.size(); i++) {
					Messaging.InboundEmail.BinaryAttachment att = email.binaryAttachments[i];
					Messaging.EmailFileAttachment newatt = new Messaging.EmailFileAttachment();
					newatt.contenttype=att.mimeTypeSubType;
					newatt.body=att.body;
					newatt.filename=att.fileName;
					newatt.inline=false;
					listOfAttachments.add(newatt);
				}
			}
			mail.setFileAttachments(listOfAttachments);
		}
		//Messaging.EmailFileAttachment resultcsv = new Messaging.EmailFileAttachment();
		//	resultcsv.setContentType('text/plain');
		//	resultcsv.setFileName('results.txt');
		//	resultcsv.setInline(false);
		//	resultcsv.Body = Blob.valueOf(results);
		//	if (!String.isBlank(results)) listOfAttachments.add(resultcsv);
		//Messaging.EmailFileAttachment upderrors = new Messaging.EmailFileAttachment();
		//	upderrors.setContentType('text/plain');
		//	upderrors.setFileName('UpdateErrors.txt');
		//	upderrors.setInline(false);
		//	upderrors.Body = Blob.valueOf(errmsgs);
		//	if (!String.isBlank(errmsgs)) listOfAttachments.add(upderrors);
		//mail.setFileAttachments(listOfAttachments);
		
		if (toaddresses.size()>0) emailMsgs.add(mail);	// BLL2a

		// Try to send an email confirmation -- will succeed if sent after the salesforce limit resets at midnight GMT
		try {
			if (AlwaysSendReply || !String.isBlank(errors) && emailMsgs.size()>0) Messaging.sendEmail(emailMsgs);	// BLL2a
		} catch(Exception e) {}
		
	}
	
	
	public Map<String,dealer__Dealer_Location__c> locationMap() {
		List<dealer__Dealer_Location__c> locs = [
			select Id, Name, dealer__Company_Number__c, 
				dealer__BDC_Director__c, dealer__BDC_Director__r.Name, dealer__BDC_Director__r.Email,
				Commercial_Sales_Admin__c, Commercial_Sales_Admin__r.Name, Commercial_Sales_Admin__r.Email,
				F_I_Manager__c, F_I_Manager__r.Name, F_I_Manager__r.Email,
				dealer__General_Manager__c, dealer__General_Manager__r.Name, dealer__General_Manager__r.Email,
				Rental_Manager__c, Rental_Manager__r.Name, Rental_Manager__r.Email,
				Sales_Admin__c, Sales_Admin__r.Name, Sales_Admin__r.Email,
				dealer__Service_Director__c, dealer__Service_Director__r.Name, dealer__Service_Director__r.Email
				from dealer__Dealer_Location__c
		];
		Map<String,dealer__Dealer_Location__c> locmap = new Map<String, dealer__Dealer_Location__c>();
		for(dealer__Dealer_Location__c l : locs) locmap.put(l.dealer__Company_Number__c,l);
		return locmap;
	} 	
}