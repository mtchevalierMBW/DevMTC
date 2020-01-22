/**
 * Email service for incoming form completions from Pardot on existing leads.
 * Find lead and if converted, the contact or account.
 * If no match (email & id=nnn from pardot url), forward to BDC & Admin.
 * Create open task with content of message.
 * Tested by: EmailPardotNotificationHandler_TEST
 * 	2015-06-08 	B. Leaman 	Written.
 * 	2015-10-15	B. Leaman	BLL1 IT15591 - Rental forms should go to the location's rental coordinator rather than account owner.
 *	2016-03-28	B. Leaman	BLL2 - add serialized objects to error notification email for debug purposes.
 *	2016-04-08	B. Leaman	BLL3 - If account owner is inactive, notify the store GM.
 *	2016-08-04	B. Leaman	BLL4 Determine rental request from subject
 *	2016-09-23	B. Leaman	BLL5 - Send all tasks to a single BDC rep - Jordan
 *	2017-10-19	B. Leaman	BLL6 - record usage; use group email for error notifications
 */
global class EmailPardotNotificationHandler implements Messaging.InboundEmailHandler {
    // List of recipients for failure notifications
    String[] failureRecipients = new String[] {'salesforce.developers@mobilityworks.com'}; // BLL6c {'bryan.leaman@mobilityworks.com'};

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

		new EmailServiceLog('EmailPardotNotificationHandler').increment();	// BLL6a

        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        result.success = true; // we'll always handle it here!
        
        String plainTextBody = email.plainTextBody;
        //System.debug('Plain body='+plainTextBody);

        String pardotId = null;
                
        // code to handle htmlBody if plainTextBody is missing
        // In this case, use custom build of plain text body all the time.
        if (email.htmlBody<>null) {
            pardotId = findPardotId(email.htmlBody);
        	String body = email.htmlBody;
        	// ensure there are newlines
        	body = body.replaceAll('\\s+', ' ').replace('</tr>', '</tr>{|}').replaceAll('</td>\\s+<td', ':</td><td');
        	//System.debug('Intermediate body='+body);
        	body =  body.stripHtmlTags();
        	//System.debug('Intermediate body='+body);
        	plainTextBody = body.replace('{|}','\n\r');
        	//System.debug('New body='+plainTextBody);
        } else {
        	pardotId = findPardotId(plainTextBody);
        }
        
        // Follow trail to Salesforce lead or contact for creating a task
        System.debug('Pardot prospect id=' + pardotId);
        if (pardotId!=null) {
            SObjectForPardotId obj = new SObjectForPardotId(pardotId);
            System.debug('Salesforce object type=' + obj.ObjectType + '; id=' + obj.ObjId);
            if (obj.ObjId!=null) {
            	 // BLL3a if owner is not active, use store GM instead
            	 Id taskOwner = obj.OwnerId;
            	 if (!isActiveUser(taskOwner)) taskOwner = getGMForObj(obj.ObjId);
            	 // BLL3a end
            	 // Create a task
            	 Task t = new Task(WhoId = obj.ObjId, OwnerId = taskOwner, // BLL3c OwnerId = obj.OwnerId,  
            	     ActivityDate = Date.today(), Status='Not started',
                     Subject='WebForm: ' + email.Subject, 
                     Source_type__c='Website',
                     Description=plainTextBody);
                 // BLL1a if a rental form, use the location's rental coordinator instead
                 // BLL5a - override task assignee based on setting (Custom settings)
                 MobilityForceSettings__c MobilityForce = MobilityForceSettings__c.getOrgDefaults();
                 if (MobilityForce!=null && !String.isBlank(MobilityForce.PardotTaskAssignee__c)) {
                 	List <User> pta = [
                 		select Id, Name 
                 		from User 
                 		where Name=:MobilityForce.PardotTaskAssignee__c and isActive=true
                 	];
                 	if (pta.size()>0) {
                 		t.OwnerId = pta[0].Id;
                 	}
                 }
                 // BLL5a end
                 //BLL4d if (plainTextBody.contains('Rental pickup')) {
                 if (email.Subject!=null && email.Subject.contains('Rental')) {	// BLL4a
                 	 System.debug('Find rental coordinator');
                 	 Id RentalCoordId = null;
               		 RentalCoordId = getRentalCoordForObj(obj.ObjId);
               		 System.debug('Rental Coordinator Id=' + RentalCoordId);
               		 if (RentalCoordId!=null) {
               		 	t.OwnerId = RentalCoordId;
               		 }
	                 // BLL5a end
	                 if (MobilityForce!=null && !String.isBlank(MobilityForce.PardotRentalAssignee__c)) {
	                 	List <User> rental = [
	                 		select Id, Name 
	                 		from User 
	                 		where Name=:MobilityForce.PardotRentalAssignee__c and isActive=true
	                 	];
	                 	if (rental.size()>0) {
	                 		t.OwnerId = rental[0].Id;
	                 	}
	                 }
	                 // BLL5a end
                 }
                 t.ResponsibleRep__c = t.OwnerId;	// BLL5a
                 // BLL1a
                 try {
                     insert(t);
                     System.debug(t); // BLL1a
                 } catch(Exception e) {
                 	 errorNotification('Cannot create task for Website form submission or Pardot automation (Pardot prospect id '+pardotId+')', e.getMessage() + '\n\r' + plainTextBody
                 	 	+ '\n\r' + 'Lead/acct=' + JSON.serialize(obj) + '\n\r' + 'Task=' + JSON.serialize(t));	// BLL2c add json serialize
                 }
            } else {
        	    //errorNotification('No Salesforce Lead for Pardot Prospect ' + pardotId, plainTextBody);
        	    System.debug('No salesforce Lead or Contact for Pardot prospect id ' + pardotId);
            }
        } else {
        	errorNotification('No Pardot Prospect Id found', plainTextBody);
        }
        
        return result;
    }
    
    // BLL3a
    // isActiveUser
    //------------------------------------
    public boolean isActiveUser(Id uid) {
    	boolean active = false;
    	List<User> us = [select Id, Name, isActive from User where Id=:uid];
		User u = us.size()>0 ? us[0] : null;
    	if (u!=null && u.isActive==true) {
    		UserLogin ul = [select Id, isFrozen from UserLogin where UserId=:u.Id];
    		active = (ul==null) || (ul.isFrozen!=true);
    	}
    	return active;
    }
    
	// BLL1a
    public Id getRentalCoordForObj(Id objId) {
    	Id RentalCoordId = null;
    	Id locId = null;
    	dealer__Dealer_Location__c loc = null;
		locId = getLocIdForObj(objId);
//BLL3d
//       	if (objId.getSObjectType()==Schema.Lead.SObjectType) {
//       		try {
//       			Lead l = [select Store_Location__c from Lead where Id=:objId];
//       			System.debug(l);
//       			if (l!=null && l.Store_Location__c!=null) {
//       				locId = l.Store_Location__c;
//       			}
//       		} catch(Exception e) {}
//       	} else if (objId.getSObjectType()==Schema.Contact.SObjectType) {
//       		try {
//       			Contact c = [select Account.Store_Location__c from Contact where Id=:objId];
//       			System.debug(c);
//       			if (c!=null && c.Account.Store_Location__c!=null) {
//       				locId = c.Account.Store_Location__c;
//       			}
//       		} catch(Exception e) {}
//       	}
       	if (locId!=null) {
       		try {
       			loc = [select Rental_Manager__c from dealer__Dealer_Location__c where Id=:locId limit 1];
       			//BLL3d System.debug(loc);
       		} catch(Exception e) {}
       	}
       	if (loc!=null) {
       		RentalCoordId = loc.Rental_Manager__c;
       		//BLL3dSystem.debug(RentalCoordId);
       	}
   		//BLL3d System.debug(RentalCoordId);
       	return RentalCoordId;
    }
	// BLL1a end
    
    
    // getGMForObj
    //------------------------------------
    public Id getGMForObj(Id objId) {
    	Id GMId = null;
    	Id locId = null;
    	dealer__Dealer_Location__c loc = null;
		locId = getLocIdForObj(objId);
       	if (locId!=null) {
       		try {
       			loc = [select dealer__General_Manager__c from dealer__Dealer_Location__c where Id=:locId limit 1];
       			//System.debug(loc);
       		} catch(Exception e) {}
       	}
       	if (loc!=null) {
       		GMId = loc.dealer__General_Manager__c;
       		//System.debug(GMId);
       	}
   		//System.debug(GMId);
       	return GMId;
    }
    
    // getLocIdForObj
    //-------------------------------------
    public Id getLocIdForObj(Id objId) {
    	Id locId = null;
       	if (objId.getSObjectType()==Schema.Lead.SObjectType) {
       		try {
       			Lead l = [select Store_Location__c from Lead where Id=:objId];
       			System.debug(l);
       			if (l!=null && l.Store_Location__c!=null) {
       				locId = l.Store_Location__c;
       			}
       		} catch(Exception e) {}
       	} else if (objId.getSObjectType()==Schema.Contact.SObjectType) {
       		try {
       			Contact c = [select Account.Store_Location__c from Contact where Id=:objId];
       			System.debug(c);
       			if (c!=null && c.Account.Store_Location__c!=null) {
       				locId = c.Account.Store_Location__c;
       			}
       		} catch(Exception e) {}
       	}
       	return locId;
    }
    // BLL3a end

    
    // Find the lead in salesforce for the Pardot prospect by email address and pardot id
    class SObjectForPardotId {
    	Id ObjId;
    	Id OwnerId;
    	String ObjectType;
    	
	    public SObjectForPardotId(String pardotId) {
            ObjId = null;
            OwnerId = null;
            ObjectType = null;
	    	String pardotIdString = '%id=' + pardotId;
	    	List<Lead> leads = [
	    	     select Id, Name, Email, pi__url__c, Status, isConverted, ConvertedAccountId, ConvertedContactId, OwnerId
	    	     from Lead
	    	     where pi__url__c like :pardotIdString
	    	     order by CreatedDate desc
	    	];
	    	if (leads.size()>0) {
	    		Lead l = leads[0];
	    		if (l.isConverted) {
	    			List<Contact> contacts = [ select Id, Name, Email, OwnerId
	    			        from Contact
	    			        where Id=:l.ConvertedContactId 
	    			        ];
	    			if (contacts.size()>0) {
	    				Contact c = contacts[0];
	    				ObjId = c.Id;
	    				OwnerId = c.OwnerId;
	    				ObjectType='Contact';
						System.debug('Found salesforce converted lead contact id ' + c.Id + ' for Pardot prospect id ' + pardotId);
	    			}
	    		} else
	    		  // Don't return the found lead if the lead is still new or being worked by the BDC
	    		  if (!String.isBlank(l.Status) && l.Status!='New') {
	    			ObjId = l.Id;
	    		    OwnerId = l.OwnerId;
	    		    ObjectType='Lead';
	    		    System.debug('Found salesforce lead id ' + l.Id + ' for Pardot prospect id ' + pardotId);
	    		} else {
        	        System.debug('Salesforce Lead has not yet been handled for Pardot prospect id ' + pardotId);
	    		}
	    	} else {
	    		// No lead: Try to find a contact
	    		List<Contact> contacts = [
	    	        select Id, FirstName, LastName, Email, pi__url__c, OwnerId
	    	        from Contact
	    	        where pi__url__c like :pardotIdString
	    	        order by CreatedDate desc
	    		];
	    	    if (contacts.size()>0) {
	    	    	Contact c = contacts[0];
	    	    	ObjId = c.Id;
	    	    	OwnerId = c.OwnerId;
	    	    	ObjectType = 'Contact';
					System.debug('Found salesforce contact id ' + c.Id + ' for Pardot prospect id ' + pardotId);
	    	    }
	    	}
	    }
    }
    
    // Look for the Pardot prospect ID number in the text (email body) and return it
    public static String findPardotId(String text) {
    	String pi_id = null;
    	Pattern p = Pattern.compile('pi\\.pardot\\.com/prospect/read/id/([0-9]*)');
        Matcher m = p.matcher(text);
        try {
	        m.find();
	        if (m.groupCount()>=1) {
	        	pi_id = m.group(1);
	        }
        } catch(Exception e) {
        	System.debug('Exception finding pardot id: ' + e.getMessage());
        }
    	return pi_id;
    } 

    // Forward email regarding unidentified prospect from Pardot
    public void errorNotification(String subject, String message) {
	    Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
	    mail.setToAddresses(failureRecipients);
	    mail.setSubject(subject + ' from Org : ' + UserInfo.getOrganizationName());
	    mail.setPlainTextBody(message);
	    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });		
	}
    
}