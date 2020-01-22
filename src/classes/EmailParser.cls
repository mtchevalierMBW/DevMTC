/*
 * EmailParser
 * Tested by: Test_LeadClasses
 * 
 * Ad-hoc testing how it found a match:
 * EmailParser p = new EmailParser();
 * System.debug(p.findBestMatch(new Lead(
 *	 FirstName='Margaret', LastName='K.', Phone='6032796150', Email='noemail@noemail.com',
 *	 PostalCode='03253'
 * )));
 * 
 * Code coverage:
 * 	2017-10-31	82% (584/712)
 *	2018-04-23	82% (563/685)
 *	2018-04-24	82% (593/721)
 *	2019-10-11	82%	(705/852)
 *  2019-12-13  76% (740/972)
 * 
 * 	2015-06-10	B. Leaman 	BLL2 - If lead was not found via SOSL on phone & email, try SOQL
 *                         to help prevent duplicates sent back-to-back 
 *                         (SOSL takes a few seconds to update index).
 *	2015-09-22	B. Leaman	BLL3 - add Hasco and additional debug statements when running in sandbox
 * 	2016-01-11	B. Leaman	BLL4 - Store map key as lowercase, stop caring about case in mapping data.
 *							Add support for DisabledDealer, ePrice Quote, PureChat, Uber.
 *	2016-01-18	B. Leaman	BLL5 - strip html tags from inputs; additional format options for Harmar.
 *	2016-02-02	B. Leaman	BLL6 - WhoId on task should be contact, not account.
 *	2016-02-10	B. Leaman	BLL7 IT20089 - Braun leads with Source Service: CallSourcePhoneBraunNew should just go to ask@.
 *	2016-05-24	B. Leaman	BLL8 - Give task to location's GM if contact owner is an inactive employee.
 *	2016-06-09	B. Leaman	BLL9 Ignore BraunAbility leads with Call Source = CallSourcePhone (or CallSourcePhoneBraunNew)
 *	2016-11-23	B. Leaman	BLL10 - Ignore field values of '-:' too
 *  TODO items noted as TODO: to possibly improve ability to find matching leads.
 *	2017-06-12	B. Leaman	BLL11 - MobilityResource sending separate first & last name fields now.
 *	2017-07-28	B. Leaman	BLL12 - New AVA website formats lead emails differently.
 *  2017-10-20	B. Leaman	BLL13 - use group email for error notifications.
 *	2017-10-31	B. Leaman	BLL14 - add monitor execution & option to assign tasks to a named employee.
 *	2018-04-23	B. Leaman	BLL15 - eliminate purechat - these are already sent to the BDC; handle DME emails;
 *	2019-05-20	B. Leaman	W-000698 BLL16 - adjustments for AVA Rental leads.
 *	2019-06-17	B. Leaman	W-000708 BLL17 Add MonitorExecution mon to parser
 *	2019-06-24	B. Leaman	W-000701 BLL18 - better handling of email addresses, other values
 *	2019-09-09	B. Leaman	W-000750 BLL19 - remove extra ':' from The MobilityResource data
 *	2019-10-11	B. Leaman	W-000763 BLL20 - Better way to find matching lead/contact/account. Prevent matching on
 *							fake email addresses like "noemail@noemail.com" when it still exists in the text fields of the records (SOSL search IN ALL FIELDS).
 *	2019-10-22	B. Leaman	W-000770 BLL21 - handle AVA rental lead phone numbers (new label).
 *	2019-11-13	B. Leaman	W-000781 BLL22 - flag rental leads
 *	2019-12-13	B. Leaman	W-000803 BLL23 - LivePerson mapping & don't notify on error from AVA because EmailLeadHandler will forward it intact to rentals@mobilityworks.com
 *	2019-12-20	B. Leaman	BLL24 - don't send missing name email since EmailLeadHandler will forward original email when this happens.
 *							and remove unicode hard space (u/00A0).
 *
 * public boolean handleEmailLead(Lead l) -> uses sosl to search for leads, but not existing contacts or accounts
 * maybe that should change? 
 */
public class EmailParser {
    Database.DMLOptions dmo;
    public Map<String,String> valueMap = new Map<String,String>();
	static boolean isSandbox = [SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox;
	MonitorExecution mon; // BLL17a

    public EmailParser() {
		this(null);
	}
    public EmailParser(MonitorExecution monitor) {
		mon = monitor;	// BLL17
        dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;         // use leadAssignment rules when updating
    }

    /*
    |   Process Braun Leads.  At time of writing they arrived as a plain text email with colon seperated key value pairs
    |   @param String - email plain text body
    |   @result Boolean - Success / Failure
    */
    public boolean processBraunPayload(String emailBody) {
		Map<String,Set<String>> SendToAskAt = new Map<String,Set<String>>{'source service'=>new Set<String>{'CallSourcePhoneBraunNew','CallSourcePhone'}}; // BLL7a, BLL9c	
		//System.debug(SendToAskAt); // BLL7a
		
        valueMap = leadDetails(lineSplit(emailBody));
		if (mon!=null) mon.log(JSON.serialize(valueMap));	// BLL17
        if(valueMap==null) throw new ParseException('Error parsing Braun lead.  No value returned');

		// BLL7a - See if email should instead just be forwarded to ask@mobilityworks.com
		//for(String k : valueMap.keySet()) {
		//	System.debug(k + ':' + valueMap.get(k));
		//}
		for(String k : SendToAskAt.keySet()) {
			//System.debug(k);
			//BLL9d if (valueMap.containsKey(k) && valueMap.get(k)==SendToAskAt.get(k)) {
			if (valueMap.containsKey(k) && SendToAskAt.get(k).contains(valueMap.get(k))) {	// BLL9a
				//BLL9d notifyAskAt('Braun ' + SendToAskAt.get(k) + ' notification', emailBody);
				return true;
			}
		}
		// BLL7a end

        Lead l = new Lead();

        // Client Block
        //String contactName = String.valueOf(valueMap.get('Contact'));
        //String[] nameParts = contactName.split(' ',0);
        //String firstName;
        //String lastName;
        //if(nameParts.size()==1) {
        //  firstName   =   nameParts[0].capitalize();
        //  lastName    =   'Not Provided';
        //} else if(nameParts.size()==2) {
        //  firstName   =   nameParts[0].capitalize();
        //  lastName    =   nameParts[1].capitalize();
        //} else {
        //  // Not sure what the other scenarios are but I gurantee they exist.  Note to Bryan.
        //  notifyOnFailure('Bruan lead contact details contains more than two parts.', emailBody);
        //}
        String contactName = (valueMap.get('contact')!=null) ? String.valueOf(valueMap.get('contact')) : '';
        String firstName;
        String lastName;
        SplitName sn = new SplitName(contactName);
        firstname = sn.FirstName;
        lastname = sn.LastName;

        l.FirstName =   firstName.capitalize();
        l.LastName  =   lastName.capitalize();
        l.Lead_Type__c= 'email';

        //addressBlock
        l.Street    =   (valueMap.get('contact address')!=null) ? String.valueOf(valueMap.get('contact address')) : null;
        l.City      =   (valueMap.get('contact city')!=null) ? String.valueOf(valueMap.get('contact city')) : null;
        l.State     =   (valueMap.get('contact state')!=null) ? String.valueOf(valueMap.get('contact state')) : null;
        l.PostalCode=   (valueMap.get('contact zip')!=null) ? String.valueOf(valueMap.get('contact zip')) : null;
        
        //communicationBlock
        l.Phone     =   (valueMap.get('contact phone')!=null) ? String.valueOf(valueMap.get('contact phone')) : null;
		// Improve email handling
		// BLL18
        //l.Email     =   (valueMap.get('contact email')!=null) ? String.valueOf(valueMap.get('contact email')) : null;
		String emailstr = (valueMap.get('contact email')!=null) ? String.valueOf(valueMap.get('contact email')) : null;
		l.Email = extractEmail(emailstr);
		// BLL18

        // Type casting
        l.LeadSource='BraunAbility'; // (valueMap.get('Source')!=null) ? String.valueOf(valueMap.get('Source')) : null; 
        if(valueMap.get('type')!=null) {
            if(String.valueOf(valueMap.get('type'))=='Sales') { l.Solution_Type__c = 'Chassis/Conversion'; }
        }

        l.End_User__c= (valueMap.get('wheelchair user')!=null) ? String.valueOf(valueMap.get('wheelchair user')) : null;
        l.Chair_Brand__c= (valueMap.get('wheelchair make')!=null) ? String.valueOf(valueMap.get('wheelchair make')) : null;
        l.Chair_Model__c= (valueMap.get('wheelchair type')!=null) ? String.valueOf(valueMap.get('wheelchair type')) : null;
        l.Referral_Code__c = (valueMap.get('referral code')!=null) ? String.valueOf(valueMap.get('referral code')) : null;  
        
        l.Email_Lead_Content__c = emailBody;

        // BLL5d if (!String.isBlank(l.FirstName) || !String.isBlank(l.LastName)) {
        if ((!String.isBlank(l.FirstName) && l.FirstName!='-not provided-') 
        	|| (!String.isBlank(l.LastName) && l.LastName!='-not provided-')) {  // BLL5a
            try {
                //insert l;
                handleEmailLead(l);
            } catch (DmlException e) {
                notifyOnFailure('Braun Lead Parse Fail', e.getMessage() + '\n' + emailBody);
                return false;
            }
        } else {
            notifyOnFailure('Braun lead missing name', emailBody);
            return false;
        }

        return true;
    }


    /* 
    |   Bruno Lead Parser
    |   @param string text body of email
    |   @result boolean success/failure of lead creation
    */
    public boolean processBrunoPayload(String emailBody) {

        valueMap = leadDetails(lineSplit(emailBody));
		if (mon!=null) mon.log(JSON.serialize(valueMap));	// BLL17
        if(valueMap==null) throw new ParseException('Error parsing Bruno lead.  No value returned');
        Lead l = new Lead();

        // Client Block
        String contactName = (valueMap.get('name')!=null) ? String.valueOf(valueMap.get('name')) : '';
        String firstName;
        String lastName;
        SplitName sn = new SplitName(contactName);
        firstname = sn.FirstName;
        lastname = sn.LastName;

        l.FirstName =   firstName.capitalize();
        l.LastName  =   lastName.capitalize();
        l.Lead_Type__c= 'email';

        //addressBlock
        l.Street    =   (valueMap.get('address')!=null) ? String.valueOf(valueMap.get('address')) : null;
        l.City      =   (valueMap.get('city')!=null) ? String.valueOf(valueMap.get('city')) : null;
        l.State     =   (valueMap.get('state')!=null) ? String.valueOf(valueMap.get('state')) : null;
        l.PostalCode=   (valueMap.get('zip')!=null) ? String.valueOf(valueMap.get('zip')) : null;
        
        //communicationBlock
        l.Phone       = (valueMap.get('day phone')!=null) ? String.valueOf(valueMap.get('day phone')) : null;
        l.MobilePhone = (valueMap.get('evening phone')!=null) ? String.valueOf(valueMap.get('evening phone')) : null;
        String em     = (valueMap.get('email')!=null) ? String.valueOf(valueMap.get('email')) : null;
        l.Email       = extractEmail(em);

        l.Description = (valueMap.get('comments')!=null) ? String.valueOf(valueMap.get('comments')) : null;

        l.Email_Lead_Content__c = emailBody;
        l.LeadSource = 'Bruno';
        
        String product = (valueMap.get('product')!=null) ? String.valueOf(valueMap.get('product')) : null;
        // TODO: No place to put this, possibly realated to type of solution desired?  

        // BLL5d if (!String.isBlank(l.FirstName) || !String.isBlank(l.LastName)) {
        if ((!String.isBlank(l.FirstName) && l.FirstName!='-not provided-') 
        	|| (!String.isBlank(l.LastName) && l.LastName!='-not provided-')) {  // BLL5a
            try {
                //insert l;
                handleEmailLead(l);
            } catch (DmlException e) {
                notifyOnFailure('Bruno Lead Parse Fail', e.getMessage() + '\n' + emailBody);
                return false;
            }
        } else {
            notifyOnFailure('Bruno lead missing name', emailBody);
            return false;
        }
  
        return true;
    } 


    /* 
    |   MobilityResource Lead Parser
    |   @param string text body of email
    |   @result boolean success/failure of lead creation
    */
    public boolean processMobilityResourcePayload(String emailBody) {
 
        valueMap = leadDetails(lineSplit(emailBody));
		if (mon!=null) mon.log(JSON.serialize(valueMap));	// BLL17
        if(valueMap==null) throw new ParseException('Error parsing TheMobilityResource lead.  No value returned');
        Lead l = new Lead();

        // Client Block
        String contactName = (valueMap.get('name')!=null) ? String.valueOf(valueMap.get('name')) : '';
        String firstName;
        String lastName;
        SplitName sn = new SplitName(contactName);
        firstname = sn.FirstName;
        lastname = sn.LastName;
        // BLL11a - if no "name" then try first & last name separately
        if (String.isBlank(contactName)) {
        	firstname = (valueMap.containsKey('first name')!=null) ? String.valueOf(valueMap.get('first name')) : '';
        	lastname = (valueMap.containsKey('last name')!=null) ? String.valueOf(valueMap.get('last name')) : '';
        }
        // BLL11a end

        l.FirstName =   firstName!=null ? firstName.capitalize() : '';
        l.LastName  =   lastName!=null ? lastName.capitalize() : '';
        l.Lead_Type__c= 'email';

        //addressBlock
        l.Street    =   (valueMap.get('address')!=null) ? String.valueOf(valueMap.get('address')) : null;
        l.City      =   (valueMap.get('city')!=null) ? String.valueOf(valueMap.get('city')) : null;
        l.State     =   (valueMap.get('state')!=null) ? String.valueOf(valueMap.get('state')) : null;
        l.PostalCode=   (valueMap.get('zip')!=null) ? String.valueOf(valueMap.get('zip')) : null;
        l.PostalCode=   (valueMap.get('zip code')!=null) ? String.valueOf(valueMap.get('zip code')) : l.PostalCode;	// BLL11a

        
        //communicationBlock
        l.Phone       = (valueMap.get('phone')!=null) ? String.valueOf(valueMap.get('phone')) : null;
        String em     = (valueMap.get('email')!=null) ? String.valueOf(valueMap.get('email')) : null;
        l.Email       = extractEmail(em);

        String qc = (valueMap.get('questions/comments')!=null) ? String.valueOf(valueMap.get('questions/comments')) : null;
        String comm = (valueMap.get('comments')!=null) ? String.valueOf(valueMap.get('comments')) : null;
        l.Description = qc;
        if (comm != null) {
            if (l.Description==null) {
                l.Description = comm;
            } else {
                l.Description = l.Description + '\n' + comm;
            }
        }

        l.Email_Lead_Content__c = emailBody;
        l.LeadSource = 'TheMobilityResource';
        
        // BLL5d if (!String.isBlank(l.FirstName) || !String.isBlank(l.LastName)) {
        if ((!String.isBlank(l.FirstName) && l.FirstName!='-not provided-') 
        	|| (!String.isBlank(l.LastName) && l.LastName!='-not provided-')) {  // BLL5a
            try {
                //insert l;
                handleEmailLead(l);
            } catch (DmlException e) {
                notifyOnFailure('MobilityResource Lead Parse Fail', e.getMessage() + '\n' + emailBody);
                return false;
            }
        } else {
            notifyOnFailure('MobilityResource lead missing name', emailBody);
            return false;
        }
  
        return true;
    } 

    /* 
    |   VMI Lead Parser
    |   @param string text body of email
    |   @result boolean success/failure of lead creation
    */
    public boolean processVMIPayload(String emailBody) {
        valueMap = leadDetails(lineSplit(emailBody));
		if (mon!=null) mon.log(JSON.serialize(valueMap));	// BLL17

        if(valueMap==null) throw new ParseException('Error parsing VMI lead.  No value returned');
        Lead l = new Lead();

        l.Email_Lead_Content__c = emailBody;

        // Dare to Compare or other?
        //Marketing Campaign or Source Campaign or Lead Form = 'Dare to Compare'
        String campaign=null;
        campaign = (valueMap.get('marketing campaign')!=null) ? String.valueOf(valueMap.get('marketing campaign')) : null;
        if (campaign==null) {
            campaign = (valueMap.get('source campaign')!=null) ? String.valueOf(valueMap.get('source campaign')) : null;
        }
        if (campaign==null) {
            campaign = (valueMap.get('lead form')!=null) ? String.valueOf(valueMap.get('lead form')) : null; 
        }
        if (campaign==null) {
           campaign = '';
        } 
        
        // Client Block
        String contactName = (valueMap.get('name')!=null) ? String.valueOf(valueMap.get('name')) : null;
        if (String.isBlank(contactName)) {
            contactName = (valueMap.get('customer name')!=null) ? String.valueOf(valueMap.get('customer name')) : null;
        }
        String firstName;
        String lastName;
        SplitName sn = new SplitName(contactName);
        firstname = sn.FirstName;
        lastname = sn.LastName;

        l.FirstName =   firstName.capitalize();
        l.LastName  =   lastName.capitalize();
        l.Lead_Type__c = 'Email';
        l.LeadSource = 'VMI'; // + ' ' + campaign;
        
        //addressBlock
        String postalcode = (valueMap.get('zip')!=null) ? String.valueOf(valueMap.get('zip')) : null;
        if (postalcode==null) postalcode = (valueMap.get('zip code')!=null) ? String.valueOf(valueMap.get('zip code')) : null;
        if (postalcode==null) postalcode = (valueMap.get('zip/postal code')!=null) ? String.valueOf(valueMap.get('zip/postal code')) : null;
        l.PostalCode = postalcode;
        
        // BLL11a additional possible fields (VMI HOT LEAD)
        l.Street = valueMap.containsKey('address') ? String.valueOf(valueMap.get('address')) : null;
        l.City = valueMap.containsKey('city') ? String.valueOf(valueMap.get('city')) : null;
        l.State = valueMap.containsKey('state') ? String.valueOf(valueMap.get('state')) : null;
        // BLL11a end
        
        //communicationBlock
        l.Phone       = (valueMap.get('phone')!=null) ? String.valueOf(valueMap.get('phone')) : null;
		if (l.Phone==null && valueMap.containsKey('phone #')) l.Phone = valueMap.get('phone #');
        String em     = (valueMap.get('email')!=null) ? String.valueOf(valueMap.get('email')) : null;
        l.Email       = extractEmail(em);
        l.Description = String.valueOf(valueMap.get('message'));
        
        // Misc
        // 'Is Customer a Veteran'

        // BLL5d if (!String.isBlank(l.FirstName) || !String.isBlank(l.LastName)) {
        if ((!String.isBlank(l.FirstName) && l.FirstName!='-not provided-') 
        	|| (!String.isBlank(l.LastName) && l.LastName!='-not provided-')) {  // BLL5a
            try {
                //insert l;
                handleEmailLead(l);
            } catch (DmlException e) {
                notifyOnFailure('VMI ' + campaign + ' Lead Parse Fail', e.getMessage() + '\n' + emailBody);
                return false;
            }
        } else {
            notifyOnFailure('VMI lead missing name', emailBody);
            return false;
        }
        
        return true;
    } 

    /* 
    |   MobilitySales Lead Parser
    |   @param string text body of email
    |   @result boolean success/failure of lead creation
    */
    public boolean processMobilitySalesPayload(String emailBody) {
        valueMap = leadDetails(lineSplit(emailBody));
		if (mon!=null) mon.log(JSON.serialize(valueMap));	// BLL17
        if(valueMap==null) throw new ParseException('Error parsing MobilitySales lead.  No value returned');
        Lead l = new Lead();

        l.Email_Lead_Content__c = emailBody;

        // Client Block
        String firstName = (valueMap.get('first name')!=null) ? standardizeName(String.valueOf(valueMap.get('first name'))) : null;
        String lastName = (valueMap.get('last name')!=null) ? standardizeName(String.valueOf(valueMap.get('last name'))) : null;
        l.FirstName =   firstName;
        l.LastName  =   lastName;
        l.Lead_Type__c = 'Email';
        String campaign = (valueMap.get('lead source')!=null) ? String.valueOf(valueMap.get('lead source')) : '';
        l.LeadSource = 'MobilitySales'; // + ' ' + campaign;
        
        //addressBlock
        l.Street    =   (valueMap.get('address')!=null) ? String.valueOf(valueMap.get('address')) : null;
        l.City      =   (valueMap.get('city')!=null) ? String.valueOf(valueMap.get('city')) : null;
        l.State     =   (valueMap.get('state')!=null) ? String.valueOf(valueMap.get('state')) : null;
        String postalcode = (valueMap.get('zip code')!=null) ? String.valueOf(valueMap.get('zip code')) : null;
        l.PostalCode = postalcode;
        
        //communicationBlock
        l.Phone       = (valueMap.get('phone')!=null) ? String.valueOf(valueMap.get('phone')) : null;
        String em     = (valueMap.get('email')!=null) ? String.valueOf(valueMap.get('email')) : null;
        l.Email       = extractEmail(em);
        l.Description = (valueMap.get('message')!=null) ? String.valueOf(valueMap.get('message')) : null;
        
        // Misc
        // 'Is Customer a Veteran'

        // BLL5d if (!String.isBlank(l.FirstName) || !String.isBlank(l.LastName)) {
        if ((!String.isBlank(l.FirstName) && l.FirstName!='-not provided-') 
        	|| (!String.isBlank(l.LastName) && l.LastName!='-not provided-')) {  // BLL5a
            try {
                //insert l;
                handleEmailLead(l);
            } catch (DmlException e) {
                notifyOnFailure('MobilitySales ' + campaign + ' Lead Parse Fail', e.getMessage() + '\n' + emailBody);
                return false;
            }
        } else {
            notifyOnFailure('MobilitySales lead missing name', emailBody);
            return false;
        }
        
        return true;
    } 


    /* 
    |   MobilityVanSales Lead Parser
    |   @param string text body of email
    |   @result boolean success/failure of lead creation
    */
    public boolean processMobilityVanSalesPayload(String emailBody) {
        valueMap = leadDetails(lineSplit(emailBody));
		if (mon!=null) mon.log(JSON.serialize(valueMap));	// BLL17
        if(valueMap==null) throw new ParseException('Error parsing MobilityVanSales lead.  No value returned');
        Lead l = new Lead();

        l.Email_Lead_Content__c = emailBody;

        // Client Block
        String contactName = (valueMap.get('name')!=null) ? String.valueOf(valueMap.get('name')) : '';
        String firstName;
        String lastName;
        SplitName sn = new SplitName(contactName);
        firstname = sn.FirstName;
        lastname = sn.LastName;

        l.FirstName =   firstName.capitalize();
        l.LastName  =   lastName.capitalize();
        l.Lead_Type__c = 'Email';
        l.LeadSource = 'Mobility Van Sales';
        
        //addressBlock
        //l.Street  =   (valueMap.get('Address')!=null) ? String.valueOf(valueMap.get('Address')) : null;
        //l.City        =   (valueMap.get('City')!=null) ? String.valueOf(valueMap.get('City')) : null;
        //l.State   =   (valueMap.get('State')!=null) ? String.valueOf(valueMap.get('State')) : null;
        //String postalcode = (valueMap.get('ZIP Code')!=null) ? String.valueOf(valueMap.get('ZIP Code')) : null;
        //l.PostalCode = postalcode;
        
        //communicationBlock
        l.Phone       = (valueMap.get('phone')!=null) ? String.valueOf(valueMap.get('phone')) : null;
        String em     = (valueMap.get('email')!=null) ? String.valueOf(valueMap.get('email')) : null;
        l.Email       = extractEmail(em);
        //l.Description = (valueMap.get('Message')!=null) ? String.valueOf(valueMap.get('Message')) : null;
        
        // Misc

        // BLL5d if (!String.isBlank(l.FirstName) || !String.isBlank(l.LastName)) {
        if ((!String.isBlank(l.FirstName) && l.FirstName!='-not provided-') 
        	|| (!String.isBlank(l.LastName) && l.LastName!='-not provided-')) {  // BLL5a
            try {
                //insert l;
                handleEmailLead(l);
            } catch (DmlException e) {
                notifyOnFailure('MobilityVanSales Lead Parse Fail', e.getMessage() + '\n' + emailBody);
                return false;
            }
        } else {
            notifyOnFailure('MobilityVanSales lead missing name', emailBody);
            return false;
        }
        
        return true;
    } 


    /* 
    |   UnitedAccess Lead Parser
    |   @param string text body of email
    |   @result boolean success/failure of lead creation
    */
    public boolean processUnitedAccessPayload(String emailBody) {
        valueMap = leadDetails(lineSplit(emailBody));
		if (mon!=null) mon.log(JSON.serialize(valueMap));	// BLL17
        if(valueMap==null) throw new ParseException('Error parsing UnitedAccess lead.  No value returned');
        Lead l = new Lead();

        l.Email_Lead_Content__c = emailBody;

        // Client Block
        String firstName = (valueMap.get('first name')!=null) ? standardizeName(String.valueOf(valueMap.get('first name'))) : null;
        String lastName = (valueMap.get('last name')!=null) ? standardizeName(String.valueOf(valueMap.get('last name'))) : null;
        l.FirstName =   firstName;
        l.LastName  =   lastName;
        l.Lead_Type__c = 'Email';
        String campaign = (valueMap.get('lead source')!=null) ? String.valueOf(valueMap.get('lead source')) : '';
        l.LeadSource = 'UnitedAccess'; // + ' ' + campaign;
        
        //addressBlock
        l.Street    =   (valueMap.get('address')!=null) ? String.valueOf(valueMap.get('address')) : null;
        l.City      =   (valueMap.get('city')!=null) ? String.valueOf(valueMap.get('city')) : null;
        l.State     =   (valueMap.get('state')!=null) ? String.valueOf(valueMap.get('state')) : null;
        String postalcode = (valueMap.get('zip code')!=null) ? String.valueOf(valueMap.get('zip code')) : null;
        l.PostalCode = postalcode;
        
        //communicationBlock
        l.Phone       = (valueMap.get('phone')!=null) ? String.valueOf(valueMap.get('phone')) : null;
        String em     = (valueMap.get('email')!=null) ? String.valueOf(valueMap.get('email')) : null;
        l.Email       = extractEmail(em);
        l.Description = (valueMap.get('message')!=null) ? String.valueOf(valueMap.get('message')) : null;
        
        // Misc
        // 'Is Customer a Veteran'

        // BLL5d if (!String.isBlank(l.FirstName) || !String.isBlank(l.LastName)) {
        if ((!String.isBlank(l.FirstName) && l.FirstName!='-not provided-') 
        	|| (!String.isBlank(l.LastName) && l.LastName!='-not provided-')) {  // BLL5a
            try {
                //insert l;
                handleEmailLead(l);
            } catch (DmlException e) {
                notifyOnFailure('UnitedAccess ' + campaign + ' Lead Parse Fail', e.getMessage() + '\n' + emailBody);
                return false;
            }
        } else {
            notifyOnFailure('UnitedAccess lead missing name', emailBody);
            return false;
        }
        
        return true;
    } 


    /* 
    |   AccessibleVans Lead Parser
    |   @param string text body of email
    |   @result boolean success/failure of lead creation
    */
    public boolean processAvaPayload(String emailBody) {
		// BLL16
        //valueMap = leadDetails(lineSplit(emailBody));
		valueMap = leadDetails(lineSplit(emailBody), false);	// do not append duplicate key values
		// BLL16 end
		if (mon!=null) mon.log(JSON.serialize(valueMap));	// BLL17
        if(valueMap==null) throw new ParseException('Error parsing Ava lead.  No value returned');
        Lead l = new Lead();

		//for(String k : valueMap.keySet()) System.debug(k + ' => ' + String.valueOf(valueMap.get(k)));

        l.Email_Lead_Content__c = emailBody;

        // Client Block
        //String firstName = (valueMap.get('first name')!=null) ? standardizeName(String.valueOf(valueMap.get('first name'))) : null;
        //String lastName = (valueMap.get('last name')!=null) ? standardizeName(String.valueOf(valueMap.get('last name'))) : null;
        // BLL12a - try name as one field first, then separate first and last name
        String contactName = (valueMap.get('name')!=null) ? String.valueOf(valueMap.get('name')) : '';
        String firstName;
        String lastName;
        SplitName sn = new SplitName(contactName);
        firstName = sn.FirstName;
        lastName = sn.LastName;
        // if no "name" then try first & last name separately
        if (String.isBlank(contactName)) {
        	firstName = (valueMap.containsKey('first name')!=null) ? String.valueOf(valueMap.get('first name')) : '';
        	lastName = (valueMap.containsKey('last name')!=null) ? String.valueOf(valueMap.get('last name')) : '';
        }
        // BLL12a end
        l.FirstName =   firstName;
        l.LastName  =   lastName;
        
        l.Lead_Type__c = 'Email';
        String campaign = (valueMap.get('lead source')!=null) ? String.valueOf(valueMap.get('lead source')) : '';
        l.LeadSource = 'Ava'; // + ' ' + campaign;
        
        //addressBlock
        l.Street    =   (valueMap.get('address')!=null) ? String.valueOf(valueMap.get('address')) : null;
        l.City      =   (valueMap.get('city')!=null) ? String.valueOf(valueMap.get('city')) : null;
        l.State     =   (valueMap.get('state')!=null) ? String.valueOf(valueMap.get('state')) : null;
        String postalcode = (valueMap.get('zip code')!=null) ? String.valueOf(valueMap.get('zip code')) : null;
        l.PostalCode = postalcode;
        
        //communicationBlock
        // BLL21d l.Phone       = (valueMap.get('phone')!=null) ? String.valueOf(valueMap.get('phone')) : null;
        String em     = (valueMap.get('email')!=null) ? String.valueOf(valueMap.get('email')) : null;
        l.Email       = extractEmail(em);
        l.Description = (valueMap.get('message')!=null) ? String.valueOf(valueMap.get('message')) : null;
		// BLL12a
		// BLL21
		l.Phone = valueMap.get('phone (home)');
		l.MobilePhone = valueMap.get('phone (cell)');
		System.debug(l.Phone);
		System.debug(l.MobilePhone);
		// BLL21 end
        l.Phone       = (l.Phone==null && valueMap.get('homephone')!=null) ? String.valueOf(valueMap.get('homephone')) : l.Phone;
        l.MobilePhone = (l.MobilePhone==null && valueMap.get('cellphone')!=null) ? String.valueOf(valueMap.get('cellphone')) : l.MobilePhone;
        // BLL12a end
		System.debug(l.Phone);
		System.debug(l.MobilePhone);
        
		// BLL22 - Rental?
		if (!String.isBlank(valueMap.get('Pickup Date')) || emailbody.contains('Rental Request')) l.Solution_Type__c='Rental';

        // Misc
        // 'Is Customer a Veteran'

        // BLL5d if (!String.isBlank(l.FirstName) || !String.isBlank(l.LastName)) {
        if ((!String.isBlank(l.FirstName) && l.FirstName!='-not provided-') 
        	|| (!String.isBlank(l.LastName) && l.LastName!='-not provided-')) {  // BLL5a
            try {
                //insert l;
                handleEmailLead(l);
            } catch (DmlException e) {
                //BLL23 notifyOnFailure('AccessibleVans ' + campaign + ' Lead Parse Fail', e.getMessage() + '\n' + emailBody);
                return false;
            }
        } else {
            //BLL23 notifyOnFailure('AccessibleVans lead missing name', emailBody);
            return false;
        }
        
        return true;
    } 


    /* 
    |   Harmar Lead Parser
    |   @param string text body of email
    |   @result boolean success/failure of lead creation
    */
    public boolean processHarmarPayload(String emailBody) {
        valueMap = leadDetails(lineSplit(emailBody));
		if (mon!=null) mon.log(JSON.serialize(valueMap));	// BLL17
        if(valueMap==null) throw new ParseException('Error parsing Harmar lead.  No value returned');
        Lead l = new Lead();

        l.Email_Lead_Content__c = emailBody;

        // Client Block
        String firstName = (valueMap.get('first name')!=null) ? standardizeName(String.valueOf(valueMap.get('first name'))) : null;
        String lastName = (valueMap.get('last name')!=null) ? standardizeName(String.valueOf(valueMap.get('last name'))) : null;
		// BLL5a - sometimes it says "Customer name"
        if (firstname==null && lastname==null) {
	        String contactName = (valueMap.get('customer name')!=null) ? String.valueOf(valueMap.get('customer name')) : '';
	        SplitName sn = new SplitName(contactName);
	        firstName = sn.FirstName;
	        lastName = sn.LastName;
        } 
        // BLL5a end
        l.FirstName =   firstName;
        l.LastName  =   lastName;
        l.Lead_Type__c = 'Email';
        String campaign = (valueMap.get('lead source')!=null) ? String.valueOf(valueMap.get('lead source')) : '';
        l.LeadSource = 'Harmar'; // + ' ' + campaign;
        l.Company = (valueMap.get('company')!=null) ? String.valueOf(valueMap.get('company')) : null;
        
        //addressBlock
        //l.Street  =   (valueMap.get('Address')!=null) ? String.valueOf(valueMap.get('Address')) : null;
        l.City      =   (valueMap.get('city')!=null) ? String.valueOf(valueMap.get('city')) : null;
        l.State     =   (valueMap.get('state')!=null) ? String.valueOf(valueMap.get('state')) : null;
        String postalcode = (valueMap.get('zip')!=null) ? String.valueOf(valueMap.get('zip')) : null;
        l.PostalCode = postalcode;
        
        //communicationBlock
        l.Phone       = (valueMap.get('phone')!=null) ? String.valueOf(valueMap.get('phone')) : null;
		// BLL5a
        if (l.Phone==null) l.Phone = (valueMap.get('phone number')!=null) ? String.valueOf(valueMap.get('phone number')) : null;
        String em     = (valueMap.get('email')!=null) ? String.valueOf(valueMap.get('email')) : null;
        l.Email       = extractEmail(em);
        l.Description = (valueMap.get('message')!=null) ? String.valueOf(valueMap.get('message')) : null;
        
        // Misc
        // 'Is Customer a Veteran'

        // BLL5d if (!String.isBlank(l.FirstName) || !String.isBlank(l.LastName)) {
        if ((!String.isBlank(l.FirstName) && l.FirstName!='-not provided-') 
        	|| (!String.isBlank(l.LastName) && l.LastName!='-not provided-')) {  // BLL5a
            try {
                //insert l;
                handleEmailLead(l);
            } catch (DmlException e) {
                notifyOnFailure('Harmar Lead Parse Fail', e.getMessage() + '\n' + emailBody);
                return false;
            }
        } else {
            notifyOnFailure('Harmar lead missing name', emailBody);
            return false;
        }
        
        return true;
    } 


    /* 
    |   Crytico Lead Parser
    |   @param string text body of email
    |   @result boolean success/failure of lead creation
    */
    public boolean processCryticoPayload(String emailBody) {
        valueMap = leadDetails(lineSplit(emailBody));
		if (mon!=null) mon.log(JSON.serialize(valueMap));	// BLL17
        if(valueMap==null) throw new ParseException('Error parsing Crytico lead.  No value returned');
        Lead l = new Lead();

        l.Email_Lead_Content__c = emailBody;

        // Client Block
        String firstName = (valueMap.get('first name')!=null) ? standardizeName(String.valueOf(valueMap.get('first name'))) : null;
        String lastName = (valueMap.get('last name')!=null) ? standardizeName(String.valueOf(valueMap.get('last name'))) : null;
        l.FirstName =   firstName;
        l.LastName  =   lastName;
        l.Lead_Type__c = 'Email';
        //String campaign = (valueMap.get('Lead Source')!=null) ? String.valueOf(valueMap.get('Lead Source')) : '';
        l.LeadSource = 'Crytico'; 
        
        //addressBlock
        //l.Street  =   (valueMap.get('Address')!=null) ? String.valueOf(valueMap.get('Address')) : null;
        //l.City        =   (valueMap.get('City')!=null) ? String.valueOf(valueMap.get('City')) : null;
        //l.State   =   (valueMap.get('State')!=null) ? String.valueOf(valueMap.get('State')) : null;
        String postalcode = (valueMap.get('zip code')!=null) ? String.valueOf(valueMap.get('zip code')) : null;
        l.PostalCode = postalcode;
        
        //communicationBlock
        l.Phone       = (valueMap.get('phone number')!=null) ? String.valueOf(valueMap.get('phone number')) : null;
        String em     = (valueMap.get('email')!=null) ? String.valueOf(valueMap.get('email')) : null;
        l.Email       = extractEmail(em);
        l.Description = (valueMap.get('message')!=null) ? String.valueOf(valueMap.get('message')) : null;
        
        // Misc
        // 'Product', 'Manufacturer', 'Dealer Name', 'Dealer City'

        // BLL5d if (!String.isBlank(l.FirstName) || !String.isBlank(l.LastName)) {
        if ((!String.isBlank(l.FirstName) && l.FirstName!='-not provided-') 
        	|| (!String.isBlank(l.LastName) && l.LastName!='-not provided-')) {  // BLL5a
            try {
                //insert l;
                handleEmailLead(l);
            } catch (DmlException e) {
                notifyOnFailure('Crytico Lead Parse Fail', e.getMessage() + '\n' + emailBody);
                return false;
            }
        } else {
            notifyOnFailure('Crytico lead missing name', emailBody);
            return false;
        }
        
        return true;
    } 




    /* 
    |   Hasco Lead Parser
    |   @param string text body of email
    |   @result boolean success/failure of lead creation
    */
    public boolean processHascoPayload(String emailBody) {
        valueMap = leadDetails(lineSplit(emailBody));
		if (mon!=null) mon.log(JSON.serialize(valueMap));	// BLL17
        if(valueMap==null) throw new ParseException('Error parsing Hasco lead.  No value returned');
        Lead l = new Lead();

        l.Email_Lead_Content__c = emailBody;

        // Client Block
        String contactName = (valueMap.get('name')!=null) ? String.valueOf(valueMap.get('name')) : '';
        String firstName;
        String lastName;
        SplitName sn = new SplitName(contactName);
        firstname = sn.FirstName;
        lastname = sn.LastName;
        l.FirstName =   firstName.capitalize();
        l.LastName  =   lastName.capitalize();

        l.Lead_Type__c = 'Email';
        //String campaign = (valueMap.get('Lead Source')!=null) ? String.valueOf(valueMap.get('Lead Source')) : '';
        l.LeadSource = 'Hasco'; 
        
        //addressBlock
        //l.Street  =   (valueMap.get('Address')!=null) ? String.valueOf(valueMap.get('Address')) : null;
        //l.City        =   (valueMap.get('City')!=null) ? String.valueOf(valueMap.get('City')) : null;
        //l.State   =   (valueMap.get('State')!=null) ? String.valueOf(valueMap.get('State')) : null;
        String postalcode = (valueMap.get('zip code')!=null) ? String.valueOf(valueMap.get('zip code')) : null;
        l.PostalCode = postalcode;
        
        //communicationBlock
        l.Phone       = (valueMap.get('phone')!=null) ? String.valueOf(valueMap.get('phone')) : null;
        String em     = (valueMap.get('email')!=null) ? String.valueOf(valueMap.get('email')) : null;
        l.Email       = extractEmail(em);

        String description = '';
        description += (valueMap.get('what would you like from us?')!=null) ? String.valueOf(valueMap.get('what would you like from us?'))+'\n' : '';
        description += (valueMap.get('questions?')!=null) ? String.valueOf(valueMap.get('questions?'))+'\n' : '';
        l.Description = description;
        
        // Misc
        // 'Product', 'Manufacturer', 'Dealer Name', 'Dealer City'

        // BLL5d if (!String.isBlank(l.FirstName) || !String.isBlank(l.LastName)) {
        if ((!String.isBlank(l.FirstName) && l.FirstName!='-not provided-') 
        	|| (!String.isBlank(l.LastName) && l.LastName!='-not provided-')) {  // BLL5a
            try {
                //insert l;
                handleEmailLead(l);
            } catch (DmlException e) {
                notifyOnFailure('Hasco Lead Parse Fail', e.getMessage() + '\n' + emailBody);
                return false;
            }
        } else {
            notifyOnFailure('Hasco lead missing name', emailBody);
            return false;
        }
        
        return true;
    } 


	// BLL4a
    /* 
    |   DisabledDealer
    |   @param string text body of email
    |   @result boolean success/failure of lead creation
    */
    public boolean processDisabledDealerPayload(String emailBody) {

        valueMap = leadDetails(lineSplit(emailBody));
		if (mon!=null) mon.log(JSON.serialize(valueMap));	// BLL17
        if(valueMap==null) throw new ParseException('Error parsing DisabledDealer lead.  No value returned');
        Lead l = new Lead();

        // Client Block
        String contactName = (valueMap.get('name')!=null) ? String.valueOf(valueMap.get('name')) : '';
        String firstName;
        String lastName;
        SplitName sn = new SplitName(contactName);
        firstname = sn.FirstName;
        lastname = sn.LastName;

        l.FirstName =   firstName.capitalize();
        l.LastName  =   lastName.capitalize();
        l.Lead_Type__c= 'Email';

        //addressBlock
        l.Street    =   (valueMap.get('street')!=null) ? String.valueOf(valueMap.get('street')) : null;
        l.City      =   (valueMap.get('city')!=null) ? String.valueOf(valueMap.get('city')) : null;
        l.State     =   (valueMap.get('state')!=null) ? String.valueOf(valueMap.get('state')) : null;
        l.PostalCode=   (valueMap.get('zipcode')!=null) ? String.valueOf(valueMap.get('zipcode')) : null;
        
        //communicationBlock
        l.Phone       = (valueMap.get('phone')!=null) ? String.valueOf(valueMap.get('phone')) : null;
        String em     = (valueMap.get('email')!=null) ? String.valueOf(valueMap.get('email')) : null;
        l.Email       = extractEmail(em);

        l.Description = (valueMap.get('comment')!=null) ? String.valueOf(valueMap.get('comment')) : null;

        l.Email_Lead_Content__c = emailBody;
        l.LeadSource = 'DisabledDealer';
        
        String product = (valueMap.get('interest')!=null) ? String.valueOf(valueMap.get('interest')) : null;
        // TODO: No place to put this, possibly realated to type of solution desired?  

        // BLL5d if (!String.isBlank(l.FirstName) || !String.isBlank(l.LastName)) {
        if ((!String.isBlank(l.FirstName) && l.FirstName!='-not provided-') 
        	|| (!String.isBlank(l.LastName) && l.LastName!='-not provided-')) {  // BLL5a
            try {
                //insert l;
                handleEmailLead(l);
            } catch (DmlException e) {
                notifyOnFailure('DisabledDealer Lead Parse Fail', e.getMessage() + '\n' + emailBody);
                return false;
            }
        } else {
            notifyOnFailure('DisabledDealer lead missing name', emailBody);
            return false;
        }
  
        return true;
    } 


    /* 
    |   ePrice Quote
    |   @param string text body of email
    |   @result boolean success/failure of lead creation
    */
    public boolean processEPriceQuotePayload(String emailBody) {

        valueMap = leadDetails(lineSplit(emailBody));
		if (mon!=null) mon.log(JSON.serialize(valueMap));	// BLL17
        if(valueMap==null) throw new ParseException('Error parsing ePrice Quote lead.  No value returned');
        Lead l = new Lead();

        // Client Block
        String contactName = (valueMap.get('name')!=null) ? String.valueOf(valueMap.get('name')) : '';
        String firstName;
        String lastName;
        SplitName sn = new SplitName(contactName);
        firstname = sn.FirstName;
        lastname = sn.LastName;

        l.FirstName =   firstName.capitalize();
        l.LastName  =   lastName.capitalize();
        l.Lead_Type__c= 'Email';

        //addressBlock
        //l.Street    =   (valueMap.get('street')!=null) ? String.valueOf(valueMap.get('street')) : null;
        //l.City      =   (valueMap.get('city')!=null) ? String.valueOf(valueMap.get('city')) : null;
        //l.State     =   (valueMap.get('state')!=null) ? String.valueOf(valueMap.get('state')) : null;
        l.PostalCode=   (valueMap.get('zip code')!=null) ? String.valueOf(valueMap.get('zip code')) : null;
        
        //communicationBlock
        //l.Phone       = (valueMap.get('phone')!=null) ? String.valueOf(valueMap.get('phone')) : null;
        String em     = (valueMap.get('email')!=null) ? String.valueOf(valueMap.get('email')) : null;
        l.Email       = extractEmail(em);

        l.Description = (valueMap.get('vin')!=null) ? 'Interested in: ' + String.valueOf(valueMap.get('vin')) : null;

        l.Email_Lead_Content__c = emailBody;
        l.LeadSource = 'ePrice Quote';
        
        //String product = (valueMap.get('interest')!=null) ? String.valueOf(valueMap.get('interest')) : null;

        // BLL5d if (!String.isBlank(l.FirstName) || !String.isBlank(l.LastName)) {
        if ((!String.isBlank(l.FirstName) && l.FirstName!='-not provided-') 
        	|| (!String.isBlank(l.LastName) && l.LastName!='-not provided-')) {  // BLL5a
            try {
                //insert l;
                handleEmailLead(l);
            } catch (DmlException e) {
                notifyOnFailure('ePrice Quote Lead Parse Fail', e.getMessage() + '\n' + emailBody);
                return false;
            }
        } else {
            notifyOnFailure('ePrice Quote lead missing name', emailBody);
            return false;
        }
  
        return true;
    } 



    /* BLL15a
    |   DME notification
    */
    public boolean processECommerce(String emailBody) {

        valueMap = leadDetails(lineSplit(emailBody));
		if (mon!=null) mon.log(JSON.serialize(valueMap));	// BLL17
        if(valueMap==null) throw new ParseException('Error parsing DME notification.  No value returned');
        Lead l = new Lead();

        // Client Block
        String firstName = (valueMap.get('first_name')!=null) ? standardizeName(String.valueOf(valueMap.get('first_name'))) : null;
        String lastName = (valueMap.get('last_name')!=null) ? standardizeName(String.valueOf(valueMap.get('last_name'))) : null;
        l.FirstName =   firstName;
        l.LastName  =   lastName;

        l.FirstName =   firstName.capitalize();
        l.LastName  =   lastName.capitalize();

        //addressBlock
        l.Street    =   (valueMap.get('address_1')!=null) ? String.valueOf(valueMap.get('address_1')) : '';
        if (valueMap.containsKey('address_2')) l.Street += '\n' + String.valueOf(valueMap.get('address_2'));
        l.City      =   (valueMap.get('city')!=null) ? String.valueOf(valueMap.get('city')) : null;
        l.State     =   (valueMap.get('state')!=null) ? String.valueOf(valueMap.get('state')) : null;
        l.PostalCode=   (valueMap.get('postcode')!=null) ? String.valueOf(valueMap.get('postcode')) : null;
        
        //communicationBlock
        l.Phone       = (valueMap.get('phone')!=null) ? String.valueOf(valueMap.get('phone')) : null;
        String em     = (valueMap.get('email')!=null) ? String.valueOf(valueMap.get('email')) : null;
        l.Email       = extractEmail(em);

        l.Description = (valueMap.get('vin')!=null) ? 'Interested in: ' + String.valueOf(valueMap.get('vin')) : null;

        l.Email_Lead_Content__c = emailBody;
        l.Lead_Type__c= 'Website';
        l.LeadSource = 'eCommerce';
        
        //String product = (valueMap.get('interest')!=null) ? String.valueOf(valueMap.get('interest')) : null;

        // BLL5d if (!String.isBlank(l.FirstName) || !String.isBlank(l.LastName)) {
        if ((!String.isBlank(l.FirstName) && l.FirstName!='-not provided-') 
        	|| (!String.isBlank(l.LastName) && l.LastName!='-not provided-')) {  // BLL5a
            try {
                //insert l;
                handleEmailLead(l, false);	// don't create open follow-up task
            } catch (DmlException e) {
                notifyOnFailure('eCommerce (DME) Lead Parse Fail', e.getMessage() + '\n' + emailBody);
                return false;
            }
        } else {
            notifyOnFailure('eCommerce (DME) lead missing name', emailBody);
            return false;
        }
  
        return true;
    } 
	// BLL15a end

    /* 
    |   PureChat
    |   @param string text body of email
    |   @result boolean success/failure of lead creation
    */
    /** BLL15d 
    public boolean processPureChatPayload(String emailBody) {

        valueMap = leadDetails(lineSplit(emailBody));
		if (mon!=null) mon.log(JSON.serialize(valueMap));	// BLL17
        if(valueMap==null) throw new ParseException('Error parsing PureChat lead.  No value returned');
        Lead l = new Lead();

        // Client Block
        String contactName = (valueMap.get('name')!=null) ? String.valueOf(valueMap.get('name')) : '';
        String firstName;
        String lastName;
        SplitName sn = new SplitName(contactName);
        firstname = sn.FirstName;
        lastname = sn.LastName;

        l.FirstName =   firstName.capitalize();
        l.LastName  =   lastName.capitalize();
        l.Lead_Type__c= 'Email';

        //addressBlock
        //l.Street    =   (valueMap.get('street')!=null) ? String.valueOf(valueMap.get('street')) : null;
        //l.City      =   (valueMap.get('city')!=null) ? String.valueOf(valueMap.get('city')) : null;
        //l.State     =   (valueMap.get('state')!=null) ? String.valueOf(valueMap.get('state')) : null;
        //l.PostalCode=   (valueMap.get('zip code')!=null) ? String.valueOf(valueMap.get('zip code')) : null;
        
        //communicationBlock
        //l.Phone       = (valueMap.get('phone')!=null) ? String.valueOf(valueMap.get('phone')) : null;
        String em     = (valueMap.get('email')!=null) ? String.valueOf(valueMap.get('email')) : null;
        l.Email       = extractEmail(em);

        l.Description = (valueMap.get('question')!=null) ? String.valueOf(valueMap.get('question')) : null;

        l.Email_Lead_Content__c = emailBody;
        l.LeadSource = 'PureChat';
        
        //String product = (valueMap.get('interest')!=null) ? String.valueOf(valueMap.get('interest')) : null;

        // BLL5d if (!String.isBlank(l.FirstName) || !String.isBlank(l.LastName)) {
        if ((!String.isBlank(l.FirstName) && l.FirstName!='-not provided-') 
        	|| (!String.isBlank(l.LastName) && l.LastName!='-not provided-')) {  // BLL5a
            try {
                //insert l;
                handleEmailLead(l);
            } catch (DmlException e) {
                notifyOnFailure('PureChat Lead Parse Fail', e.getMessage() + '\n' + emailBody);
                return false;
            }
        } else {
            notifyOnFailure('PureChat lead missing name', emailBody);
            return false;
        }
  
        return true;
    } 
    BLL15d end **/


    /* 
    |   Uber
    |   @param string text body of email
    |   @result boolean success/failure of lead creation
    */
    public boolean processUberPayload(String emailBody) {

        valueMap = leadDetails(lineSplit(emailBody));
		if (mon!=null) mon.log(JSON.serialize(valueMap));	// BLL17
        if(valueMap==null) throw new ParseException('Error parsing Uber lead.  No value returned');
        Lead l = new Lead();

        // Client Block
        String contactName = (valueMap.get('name')!=null) ? String.valueOf(valueMap.get('name')) : '';
        String firstName;
        String lastName;
        SplitName sn = new SplitName(contactName);
        firstname = sn.FirstName;
        lastname = sn.LastName;

        l.FirstName =   firstName.capitalize();
        l.LastName  =   lastName.capitalize();
        l.Lead_Type__c= 'Email';

        //addressBlock
        //l.Street    =   (valueMap.get('street')!=null) ? String.valueOf(valueMap.get('street')) : null;
        //l.City      =   (valueMap.get('city')!=null) ? String.valueOf(valueMap.get('city')) : null;
        //l.State     =   (valueMap.get('state')!=null) ? String.valueOf(valueMap.get('state')) : null;
        //l.PostalCode=   (valueMap.get('zip code')!=null) ? String.valueOf(valueMap.get('zip code')) : null;
        
        //communicationBlock
        l.Phone       = (valueMap.get('phone number')!=null) ? String.valueOf(valueMap.get('phone number')) : null;
        String em     = (valueMap.get('email')!=null) ? String.valueOf(valueMap.get('email')) : null;
        l.Email       = extractEmail(em);

        //l.Description = (valueMap.get('question')!=null) ? String.valueOf(valueMap.get('question')) : null;

        l.Email_Lead_Content__c = emailBody;
        l.LeadSource = 'Uber';
        
        //String product = (valueMap.get('interest')!=null) ? String.valueOf(valueMap.get('interest')) : null;

        // BLL5d if (!String.isBlank(l.FirstName) || !String.isBlank(l.LastName)) {
        if ((!String.isBlank(l.FirstName) && l.FirstName!='-not provided-') 
        	|| (!String.isBlank(l.LastName) && l.LastName!='-not provided-')) {  // BLL5a
            try {
                //insert l;
                handleEmailLead(l);
            } catch (DmlException e) {
                notifyOnFailure('Uber Lead Parse Fail', e.getMessage() + '\n' + emailBody);
                return false;
            }
        } else {
            notifyOnFailure('Uber lead missing name', emailBody);
            return false;
        }
  
        return true;
    } 

	// BLL4a end

    /**
     * extractEmail
     * tries to pull email from various representations:
     *  - name@company.com
     *  - First Last <First.Last@company.com>
     *  - email@exmample.com<mailto:email2@example.com> 
     */
    public static String extractEmail(String emaddr) {
        String email=null;
        Integer b, e;
        System.debug(emaddr);
        if (emaddr!=null) {
           email = emaddr.trim();
           b=email.indexOf('<');
           if (b>0) {
              e = email.lastIndexOf('>');
              String tmp;
              tmp = email.substring(b+1, e).trim();
              //System.debug(tmp);
              if (tmp.startsWith('mailto:')) email = tmp.substring(7).trim();
           }
        }
        if (!String.isBlank(email) && b>0) email = email.left(b);
		// BLL18
		if (!String.isBlank(email)) email = email.replaceAll('\\s+','');
		if (!String.isBlank(email)) email = email.removeStart('mailto:');
		if (!String.isBlank(email)) email = email.removeStart(':');
		if (!String.isBlank(email)) email = email.removeEnd(':');
		// BLL18 end
		System.debug(email);
        return email;
    }

    /*
    |   lineSplit takes @param String and returns an array of lines split by line break
    |   @param String - text run-on with lines expecting to be split
    |   @result Array - lines split by new line
    */
    public List<String> lineSplit(String s) {
	
        // Plain text has "Label:<newline><newline>value<newline><newline>" - replace with "Label: value<newline>"
        s = s.replace('\n\n', '\n');
        s = s.replace('\n\n', '\n');
        if (isSandbox) {
        	System.debug(s.left(1024));
        }
        List<String> lines = new List<String>();
        lines = s.split('\n',0);
        if(lines.size()==0) throw new ParseException('Email unable to be parsed. The plain body does not contain line breaks. ');

		// BLL5 strip mailto tag from email
		//for(String l : lines) System.debug(l);
		for(String l : lines) l = l.stripHtmlTags(); 
		//for(String l : lines) System.debug(l);
		//BLL15d for(String l : lines) l = l.replaceAll('<mailto:[^>]*>', '');
		// BLL15a prev line wasn't actually affecting the "lines" collection
		for(Integer i=0; i<lines.size(); ++i) {
			if (!String.isBlank(lines[i]))
				lines[i] = lines[i].replaceAll('<mailto:[^>]*>', '');
		}
		// BLL15a end
		//for(String l : lines) System.debug(l);

        // combine next line with this one if this one ends in ':' and next one doesn't
        // aka, when value is on the next line instead of the same one as the label text
        List<String> ls2 = new List<String>();
        for(Integer i=0; i<lines.size(); ) {
			System.debug(String.valueOf(i) + ': ' + lines[i]);
            if (i<lines.size()-1) {
                if (lines[i].trim().endsWith(':') && !lines[i+1].trim().contains(':')) {
					System.debug('Combine "' + lines[i] + '" with "' + lines[i+1] + '"');
                    ls2.add(lines[i] + lines[i+1]);
                    i++;  // an extra increment to skip the combined line
                } else {
                    ls2.add(lines[i]);
                }
            } else {
                ls2.add(lines[i]);
            }
            i++;
        }

        if (isSandbox) {  // BLL3a additional debugging
        	for(String str : ls2) {
        		System.debug(str);
        	}
        }

        return ls2;
    }


    /*
    |   leadDetails returns a key value pair of data 
    |   @param Array - array of strings
    |   @result Map - key value pairs determined by split in the line based on the colon character
    |   2015-05-21 BLL - Allow colons in value part of line, just split on first colon only.
    | 	2016-01-11	BLL4 - Store map key as lowercase, stop caring about case in mapping data.
    */
    public Map<String, String> leadDetails(List<String> lines) {
// BLL16a
		return leadDetails(lines, true);
	}
    public Map<String, String> leadDetails(List<String> lines, boolean appendDuplicates) {
// BLL16a end
        Map<String, String> returnMap = new Map<String,String>();
        for(String s : lines) {
        	System.debug(s);
			s=s.replaceAll('\u00A0',' ');	// BLL24 remove unicode hard space
            // Split on Colon
            if(s.indexOf(':')!=-1) {
                //String[] parts = s.split(':',0);
                String[] parts = s.split(':',2);
                if(parts.size()==2) {
                    if(!String.isBlank(parts[1].replaceAll('[:-]','')) ) { // Treat the '-' as null // BLL10 also '-:'
                        // TO-DO : Possible same name on Contact Address, check if exists and modify key name
                        String key = parts[0].trim().tolowercase(); // BLL4a
						// BLL18
						String val = parts[1].trim().removeStart(':').removeEnd(':');
						// BLL18 end
                        if (returnMap.containsKey(key)) {
                            String oldval = returnMap.get(key).trim();
                            if (oldval.length()>0) {
								// BLL16
                                //returnMap.put(key, returnMap.get(key) + '\n' + parts[1].trim());
								// BLL18
								//if (appendDuplicates) returnMap.put(key, returnMap.get(key) + '\n' + parts[1].trim());
								if (appendDuplicates) returnMap.put(key, oldval + '\n' + val);
								// BLL18 end
								// BLL16 end
                            } else {
								// BLL18
                                //returnMap.put(key, parts[1].trim());
								returnMap.put(key, val);
								// BLL18 end
                            }
                        } else {
							// BLL18
                            //returnMap.put(key, parts[1].trim());
							returnMap.put(key, val);
							System.debug('EmailData[[' + key + '="' + val + '"]]');	// BLL19
							// BLL18 end
                        }
                    }
                }
            }
        }

        // Check size to see if we have the expected results 
        if(returnMap.size()==0) throw new ParseException('Email was not in a recognized format (colon-separated values), no lead will be created');
        
        if (isSandbox) {  // BLL3a additional debugging
			System.debug('[[Return Map]]');	// BLL19
        	for(String s : returnMap.keySet()) {
        		System.debug(s + ' : ' + returnMap.get(s));
        	}
        }
        
        return returnMap;       
    }

    /* Exception Notification */
    public void notifyOnFailure(String subject, String message) {
             Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
             String[] toAddresses = new String[] {'bdc.automation@mobilityworks.com', 'salesforce.developers@mobilityworks.com'}; //BLL13c {'bryan.leaman@mobilityworks.com', 'nathan.ahrens@mobilityworks.com'};
             if (isSandbox) toAddresses = new String[] {UserInfo.getUserEmail()}; 
             mail.setToAddresses(toAddresses);
             mail.setSubject(subject + ' from Org : ' + UserInfo.getOrganizationName());
             mail.setPlainTextBody(message);
             // BLL24d Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });      
    }

	// BLL7a
	// Special handling for emails that shouldn't create a lead 
	// (usually because it's just confirmation of a lead already received, like a forwarded phone call)
	public void notifyAskAt(String subject, String message) {
        Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
        List<String> toAddresses = new List<String>();
        toAddresses.add(isSandbox ? UserInfo.getUserEmail() : 'ask@mobilityworks.com');
        mail.setToAddresses(toAddresses);
        mail.setSubject(subject + ' from Org : ' + UserInfo.getOrganizationName());
        mail.setPlainTextBody(message);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });      
	}
	// BLL7a end

    /* Exception Handler */
    public class ParseException extends Exception {}
    
    
    /** Handle lead 
     * Look for existing Retail Lead by email or phone, exclude unqualified leads
     * If NOT found, create lead (BDC will handle from there)
     * If FOUND and store is live in salesforce, create activity (task) on Lead or Account.
     */
    public boolean handleEmailLead(Lead l) {
// BLL15a
    	return handleEmailLead(l, true);	// generate followup task by default
    }
    public boolean handleEmailLead(Lead l, boolean followuptask) {
// BLL15a end
        boolean handled = false;
        
        if (mon==null) mon = new MonitorExecution('EmailParser');	// BLL14a
        mon.log('Searching for: ' + JSON.serialize(l));	// BLL14a
        boolean possibleIssue = false;	// BLL14a

		// BLL19 - standardize zip?
		if (l.PostalCode!=null && l.PostalCode.length()>10) {
			l.PostalCode = l.PostalCode.left(10);
		}
		// BLL19

        // See if retail lead already exists for this email and/or phone#
        //BLL20 
		//RecordType rt = [select Id, Name from RecordType where SObjectType='Lead' and Name like 'Retail%'];
        //String rtid = rt.Id;

        //String srch = '';
        //if (!String.isBlank(l.Email) && l.Email.indexOf('@')>0) {
        //    if (!String.isBlank(srch) && l.Email.trim().length()>5) {
        //        srch = srch + ' or ';
        //    }
        //    srch = srch + l.Email.replaceAll('\\s+', '');
        //}
        //if (!String.isBlank(l.Phone) && l.Phone.trim().length()>9) {
        //    if (!String.isBlank(srch)) {
        //        srch = srch + ' or ';
        //    }
        //    srch = srch + l.Phone.replaceAll('\\s+', '');
        //    // TODO: remove all non-numerics?
        //}
        //String soql = 'FIND \'' + srch + '\' IN ALL FIELDS '
        //            + 'RETURNING Lead(Id, Name, Email, Phone, Status, OwnerId, isConverted, ConvertedAccountId, ConvertedContactId, Store_Location__c '	// BLL6c, BLL8c add Store_Location__c
        //            + 'Where RecordTypeId=\'' + rtid + '\' and Status<>\'Unqualified\' '
        //            + 'Order by LastActivityDate desc )';
        //List<Lead> leadResults = new List<Lead>();        
        //if (!String.isBlank(srch)) {
        //    List<List<SObject>> sr = search.query(soql);
        //    leadResults = (List<Lead>) sr[0];        
        //}
		//
		//// BLL14a
		//mon.log('sosl='+soql);
		//Integer i=0;
		//for(Lead r : leadResults) mon.log('Result ' + ++i + ': ' + JSON.serialize(r));
		//// BLL14a end
		SObject foundRcd = findBestMatch(l);
		System.debug(foundRcd);
		mon.log('Found Rcd:' + JSON.serialize(foundRcd));
		// BLL20 end

        // BLL2 begin: If not found by sosl, try simple soql TODO: Maybe email *or* phone?
        // BLL20
		//if (leadResults.size()==0) {
		if (foundRcd==null) {
			System.debug('Did not find match using SOSL');
			List<Lead> leadResults = new List<Lead>();        
		// BLL20 end
            String whereclause = '';
            if (!String.isBlank(l.Email) && l.Email.length()>=10) {
                whereclause += 'and (Email=\'' + l.Email + '\') ';
            }
            if (!String.isBlank(l.Phone) && l.Phone.length()>=10) {
            	// TODO: Maybe remove non-numerics? will it find the match that way?
                whereclause += 'and (Phone=\'' + l.Phone + '\') ';
            }
            if (whereclause.length()>0) {
                String qry = 'select Id, Name, Email, Phone, Status, OwnerId, isConverted, ConvertedAccountId, ConvertedContactId, Store_Location__c '	// BLL6c, BLL8c add Store_Location__c
                           + 'from Lead '
                           //+ 'where RecordTypeId=\'' + rtid + '\' and Status!=\'Unqualified\' '	// BLL20d
						   + 'where RecordType.Name like \'Retail%\' and Status!=\'Unqualified\' '	// BLL20a
                           + whereclause
                           + 'order by LastActivityDate desc '
						   + 'limit 20';	// BLL20a
                leadResults = database.query(qry);

				// BLL14a
				System.debug(qry);
				mon.log('soql='+qry);
				Integer i=0;
				for(Lead r : leadResults) {System.debug(r); mon.log('Result ' + ++i + ': ' + JSON.serialize(r));}
				// BLL14a end

                if (leadResults.size()>0) {
					// BLL20
					String fname = l.FirstName!=null ? l.FirstName.toLowerCase() : '';
					String lname = l.LastName!=null ? l.LastName.toLowerCase() : '';
					String phone = l.Phone!=null ? justDigits(l.Phone) : '';
					String email = l.Email!=null ? l.Email.toLowerCase() : '';
					if (SimilarEnough(leadResults[0], fname, lname, phone, email)) {	
	                    System.debug('SOSL did not find lead, but SOQL did.');
						mon.log('SOSL did not find lead, but SOQL did');
						foundRcd = leadResults[0];
					} else {
						System.debug('SOQL query did not find a good match');
						mon.log('SOQL query found a match, but it was not a good match');
					}
					// BLL20 end
                }
            }
        } // BLL2 end foundRcd==null	// was leadResults.size()==0  
        
        // Add task to existing lead or create new lead
		// BLL20
		//if (leadResults.size()>0) {
        //    Lead foundLead = leadResults[0];
		if (foundRcd!=null) {
			Task t = createTask(foundRcd, l.Email_Lead_Content__c);
            //Task t = new Task(ActivityDate = Date.today(),
            //                      Subject='Email received', 
            //                      Status='Not started',
            //                      Source_type__c='Email',
            //                      Description = l.Email_Lead_Content__c);
            // BLL20 end
			if (followuptask==false) t.Status='Completed';	// BLL15a
            // BLL20
			//if (foundLead.isConverted) {
            //    // Generate an activity (task) on the Contact
            //    //BLL6d t.WhoId = foundLead.ConvertedAccountId;
            //    t.WhoId = foundLead.ConvertedContactId; // BLL6a
            //    // BLL8a - use contact owner
            //    try {
            //    	Contact c = [select Id, Name, OwnerId from Contact where Id=:t.WhoId limit 1];
            //    	Account a = [select Id, Name, Store_Location__c from Account where Id=:foundLead.ConvertedAccountId limit 1];
            //    	foundLead.OwnerId = c.OwnerId;
            //    	foundLead.Store_Location__c = a.Store_Location__c;
	        //        System.debug('Found converted lead ' + foundLead.Id);
	        //        mon.log('Lead was converted to account: ' + JSON.serialize(a));
	        //        mon.log('Lead was converted to contact: ' + JSON.serialize(c));
            //    } catch(Exception e) {}
            //    // BLL8a end
            //} else {
            //    // Generate an activity (task) on the Lead
            //    t.WhoId = foundLead.Id;
            //    System.debug('Found lead ' + foundLead.Id);
            //}
			// BLL20 end
			//
            //// Don't try to assign a task to a queue!
            //Id owner = foundLead.OwnerId;
            //Schema.sObjectType entityType = owner.getSObjectType();
            ////System.assert(entityType == Opportunity.sObjectType);
            //if (entityType!=Group.SObjectType) {
			//	// BLL8a - inactive owner? Use location's general manager
			//	User u = [select Id, Name, isActive from User where Id=:foundLead.OwnerId limit 1];
			//	if (u.isActive==false) {
			//		List<dealer__Dealer_Location__c> dl = new List<dealer__Dealer_Location__c>();
			//		if (foundLead.Store_Location__c!=null) {
			//			dl = [select Id, dealer__General_Manager__c from dealer__Dealer_Location__c where Id=:foundLead.Store_Location__c ];
			//			if (dl.size()>0 && dl[0].dealer__General_Manager__c!=null) {
			//				u = [select Id, Name from User where Id=:dl[0].dealer__General_Manager__c limit 1];
			//				foundLead.OwnerId = u.Id;
			//			}
			//		}
			//	}
			//	// BLL8a end
            //    t.OwnerId = foundLead.OwnerId;	// BLL15c only assign owner if this is an open task
            //}

			// BLL14a
			// emails exist but do not match
			//possibleIssue = possibleIssue || (!String.isBlank(foundLead.Email) && !String.isBlank(l.Email) && foundLead.Email!=l.Email);
			//possibleIssue = possibleIssue || (!String.isBlank(foundLead.Phone) && !String.isBlank(l.Phone) && justDigits(foundLead.Phone)!=justDigits(l.Phone));
			//if (possibleIssue) mon.log('Email or Phone does not match');
			// BLL20 end

            MobilityForceSettings__c MobilityForce = MobilityForceSettings__c.getOrgDefaults();
            if (MobilityForce!=null && !String.isBlank(MobilityForce.EmailTaskAssignee__c)) {
            	List <User> pta = [
             		select Id, Name 
             		from User 
             		where Name=:MobilityForce.EmailTaskAssignee__c and isActive=true
             	];
             	if (pta.size()>0) {
             		t.OwnerId = pta[0].Id;
             	}
            }
            // BLL14a end

			if (followuptask==false) t.OwnerId = UserInfo.getUserId();	// BLL15a - don't assign to user if it's not an open task 
            insert(t);
            System.debug('Created new task id=' + t.Id);
            mon.log('Created new task id=' + t.id);	// BLL14a
            //BLL20 if (possibleIssue || mon.AlwaysNotify) mon.notifyAdmin();	// BLL14a
            
        } else {   // new lead! (or no email & no phone)-- BDC will take it from here
            try {
                l.setOptions(dmo);
                insert(l);
                handled = true;
                System.debug('Generated new lead ' + l.Id);
				mon.log('Generated new lead ' + l.Id);
            } catch(Exception e) {
                System.debug('Unable to insert lead for ' + l.Name); 
				mon.log('Unable to insert lead for ' + l.Name);
                throw new ParseException('Unable to create lead in salesforce: ' + e.getMessage());
            }
            
        }
        
        return handled; 
    }

	public String justDigits(String phn) {
		return phn!=null ? phn.replaceAll('[^0-9]', '') : '';
	}
    
    // standardize name (capitalization)
    public String standardizeName(String n) {
       if (n.isAllUpperCase()) 		n = n.toLowerCase().capitalize();
       else if(n.isAllLowerCase())	n = n.capitalize();
       return n;
    }
    
    // Class to generate two-part name from a name string
    public class SplitName {
        public String FirstName='';
        public String LastName='';
        public SplitName(String fullname) {
            String[] parts = new List<String>();
            String[] nameParts = new List<String>();
            String prefix = '';
            String suffix = '';
            
            // 
            if (fullname<>null) {
                // split & standardize capitalization
                parts = fullname.split(' ',0);
                for(Integer i = 0; i<parts.size(); i++) {
			       	if (parts[i].isAllUpperCase()) 	parts[i] = parts[i].toLowerCase().capitalize();
       				else if(parts[i].isAllLowerCase())	parts[i] = parts[i].capitalize();
                }
                
                // Find & save standard prefixes and suffixes
                Set<String> pref = new Set<String>(new List<String> {'mr', 'mr.', 'mrs', 'mrs.', 'ms', 'ms.', 'miss' });
                Set<String> suff = new Set<String>(new List<String> {'jr', 'jr.', 'sr', 'sr.', 'ii', 'iii', 'iv', '2nd', '3rd', '4th'}); 
                for(Integer i=0; i<parts.size(); i++) {
                   if (pref.contains(parts[i].toLowerCase())) {
                       prefix = prefix + parts[i] + ' '; 
                   } else if (suff.contains(parts[i].toLowerCase())) {
                       suffix = suffix + parts[i] + ' '; 
                   } else {
                      nameParts.add(parts[i]);
                   }
                }
                
                // Divide into first & lastnames
                if (nameParts.size()==1) {
                    FirstName = nameParts[0];
                    LastName = '-not provided-';
                } else {
                    FirstName = nameParts[0];
                    LastName = '';
                    for(Integer i=1; i<nameParts.size()-1; i++) {
                        if (i<3) FirstName = FirstName + ' ' + nameParts[i];
                        else LastName = LastName + nameParts[i] + ' ';
                    }
                    LastName = LastName + nameParts[nameParts.size()-1];
                }
                FirstName = (prefix + ' '  + FirstName).trim();
                LastName = (LastName + ' ' + suffix).trim();
                
            }           
        }
    }

	// BLL20
	// findBestMatch
	// Search Leads, Contacts, Accounts by email in email fields, phone in phone fields, name in name fields
	// Then combine results by object Id and pick the best object with the most matches.
	public SObject findBestMatch(Lead leadRcd) {
		// result!
		SObject matchRcd = null;

		if (mon!=null) mon.log('findBestMatch for: ' + JSON.serialize(leadRcd));

		// search criteria
		String firstname = leadRcd.FirstName;
		String lastname = leadRcd.LastName;
		String email = leadRcd.Email;
		String phone = justDigits(leadRcd.Phone);
		if (email!=null) email = email.toLowerCase();
		if (firstname!=null) firstname = firstname.toLowerCase();
		if (lastname!=null) lastname = lastname.toLowerCase();
		String fullname = firstname + ' ' + lastname;
		fullname = fullname.trim();
		// only consider the numeric digits in phone#
		if (!String.isBlank(email) && !email.contains('@')) email=null;

		// only consider retail leads in lead results
		Id retailLeadRT = null;
		Map<Id, Schema.RecordTypeInfo> LeadRcdTypes = Schema.SObjectType.Lead.getRecordTypeInfosById();
		for(Schema.RecordTypeInfo rtInfo : LeadRcdTypes.values()) {
			if (rtInfo.isActive() && rtInfo.getName().startsWith('Retail')) retailLeadRT = rtInfo.getRecordTypeId();
		}

		// SOSL queries for email, phone, name
		List<List<SObject>> sosl1 = new List<List<SObject>>();	// email
		List<List<SObject>> sosl2 = new List<List<SObject>>();	// phone
		List<List<SObject>> sosl3 = new List<List<SObject>>();	// name
		System.debug('Searching email='+email);
		if (!String.isBlank(email)) sosl1 = [
		    FIND :email in EMAIL FIELDS 
		    Returning Lead(Id, Name, FirstName, LastName, Email, Phone, Status, OwnerId, isConverted, ConvertedAccountId, ConvertedContactId, Store_Location__c Where RecordTypeId=:retailLeadRT),
		    		  Account(Id, Name, Email__c, Phone, OwnerId, isPersonAccount, PersonContactId, Store_Location__c),
		    		  Contact(Id, FirstName, LastName, Email, Phone, OwnerId, AccountId, Account.isPersonAccount, Account.Store_Location__c)
		];
		System.debug('Searching phone='+phone);
		if (!String.isBlank(phone)) sosl2 = [
		    FIND :phone in PHONE FIELDS 
		    Returning Lead(Id, Name, FirstName, LastName, Email, Phone, Status, OwnerId, isConverted, ConvertedAccountId, ConvertedContactId, Store_Location__c Where RecordTypeId=:retailLeadRT),
		    		  Account(Id, Name, Email__c, Phone, OwnerId, isPersonAccount, PersonContactId, Store_Location__c),
		    		  Contact(Id, FirstName, LastName, Email, Phone, OwnerId, AccountId, Account.isPersonAccount, Account.Store_Location__c)
		];
		System.debug('Searching name='+fullname);
		if (!String.isBlank(fullname)) sosl3 = [
		    FIND :fullname in NAME FIELDS 
		    Returning Lead(Id, Name, FirstName, LastName, Email, Phone, Status, OwnerId, isConverted, ConvertedAccountId, ConvertedContactId, Store_Location__c Where RecordTypeId=:retailLeadRT),
		    		  Account(Id, Name, Email__c, Phone, OwnerId, isPersonAccount, PersonContactId, Store_Location__c),
		    		  Contact(Id, FirstName, LastName, Email, Phone, OwnerId, AccountId, Account.isPersonAccount, Account.Store_Location__c)
		];

		System.debug('Email matches: ' + email);
		System.debug(sosl1);
		System.debug('Phone matches: ' + phone);
		System.debug(sosl2);
		System.debug('Name matches: ' + fullname);
		System.debug(sosl3);
		if (mon!=null) {
			mon.log('Email matches: ' + email);
			mon.log(JSON.serialize(sosl1));
			mon.log('Phone matches: ' + phone);
			mon.log(JSON.serialize(sosl1));
			mon.log('Name matches: ' + fullname);
			mon.log(JSON.serialize(sosl1));
		}

		// combine all results
		List<Lead> leads = new List<Lead>();
		List<Account> accts = new List<Account>();
		List<Contact> conts = new List<Contact>();
		if (sosl1.size()>0) {
			leads.addAll((List<Lead>) sosl1[0]);
			accts.addAll((List<Account>) sosl1[1]);
			conts.addAll((List<Contact>) sosl1[2]);
		}
		if (sosl2.size()>0) {
			leads.addAll((List<Lead>) sosl2[0]);
			accts.addAll((List<Account>) sosl2[1]);
			conts.addAll((List<Contact>) sosl2[2]);
		}
		if (sosl3.size()>0) {
			leads.addAll((List<Lead>) sosl3[0]);
			accts.addAll((List<Account>) sosl3[1]);
			conts.addAll((List<Contact>) sosl3[2]);
		}

		// Count up all results by result record Ids
		Map<Id, Integer> matchCounts = new Map<Id, Integer>();
		Map<Id, SObject> allMap = new Map<Id, SObject>();

		for(Lead l : leads) { 
		    //System.debug(l); 
		    allMap.put(l.Id, l); 
			if (SimilarEnough(l, firstname, lastname, phone, email)) {
				// count converted leads as if they were account & contact matches rather than lead matches!
		    	if (!l.isConverted) matchCounts.put(l.Id, matchCounts.containsKey(l.Id)?matchCounts.get(l.Id)+1:1);
		    	else {
		    	    if (l.ConvertedAccountId!=null) matchCounts.put(l.ConvertedAccountId, matchCounts.containsKey(l.ConvertedAccountId)?matchCounts.get(l.ConvertedAccountId)+1:1);
		    	    if (l.ConvertedContactId!=null) matchCounts.put(l.ConvertedContactId, matchCounts.containsKey(l.ConvertedContactId)?matchCounts.get(l.ConvertedContactId)+1:1);
		    	}
			}
		}
		for(Account a : accts) {
		    //System.debug(a);
		    allMap.put(a.Id, a); 
			if (SimilarEnough(a, firstname, lastname, phone, email)) {
			    matchCounts.put(a.Id, matchCounts.containsKey(a.Id)?matchCounts.get(a.Id)+1:1);
			}
		}
		for(Contact c : conts) {
		    //System.debug(c);
		    if (!c.Account.isPersonAccount) {
		    	allMap.put(c.Id, c); 
				if (SimilarEnough(c, firstname, lastname, phone, email)) {
		    		matchCounts.put(c.Id, matchCounts.containsKey(c.Id)?matchCounts.get(c.Id)+1:1);
				}
		    }
		}
		System.debug(matchcounts);
		if (mon!=null) mon.log(JSON.serialize(matchcounts));

		// Debug results
		System.debug('[match counts by record id]');
		if (mon!=null) mon.log('Match counts by record id:');
		for(Id rcdid : matchCounts.keySet()) {
		    System.debug(matchCounts.get(rcdid) + ' : ' + rcdid + ' : ' + allMap.get(rcdid));
			if (mon!=null) mon.log(matchCounts.get(rcdid) + ' : ' + rcdid + ' : ' + allMap.get(rcdid));
		}

		// Pick the best match - first highest count
		// Note that leads 00Q come before Accounts 001 come before Contacts 003
		Integer weight = 0;
		for(Id rcdid : matchCounts.keySet()) {
			Integer wgt = matchCounts.get(rcdid);
			// choose larger weight *or* unconverted lead if otherwise a match in weight
			String idStr = String.valueOf(rcdid);
			String matchIdStr = matchRcd!=null ? String.valueOf(matchRcd.Id) : '';
		    if (wgt>weight 
				|| (wgt==weight && matchRcd!=null && matchIdStr!=null && idStr.startsWith('00Q') && !matchIdStr.startsWith('00Q')) ) {
		        weight = wgt;
		        matchRcd = allMap.get(rcdid);
		    }
		}
		System.debug('Best match:');
		System.debug(weight + ' : ' + matchRcd);
		if (mon!=null) mon.log('Best match: ' + weight + ' : ' + matchRcd);
		return matchRcd;
	}

	// stringContainsAny
	// Search for series of strings inside target string
	// return true if string contains any from the list
	public boolean stringContainsAny(String s, Set<String> compareto) {
		boolean result = false;
		for(String c : compareto) {
			if (s.contains(c)) {
				result = true;
				break;
			}
		}
		return result;
	}

	// SimilarEnough
	// Try to determine if a lead/account/contact matches name, phone & email enough to be considered a match
	// This is an attempt to NOT match people who use fake email addresses like "noemail@noemail.com" and the email is the only thing that matches
	public boolean SimilarEnough(SObject obj, String fname, String lname, String phonenbr, String emailaddr) {
		boolean similarphone = false;
		boolean similaremail = false;
		boolean similarlastname = false;
		boolean similarfirstname = false;
		Integer rank = 0;
		Integer targetrank = 3;

		if (emailaddr==null) emailaddr = '';
		if (phonenbr==null) phonenbr = '';
		if (fname==null) fname = '';
		if (lname==null) lname = '';

		Set<String> suspectEmailAddr = new Set<String>{'noemail','noreply','fake','nobody','example.com','test@braun'};
		System.debug('Similar enough?');
		System.debug(obj);
		System.debug(obj.getSObjectType());
		if (mon!=null) mon.log('SimilarEnough check');
		if (mon!=null) mon.log(JSON.serialize(obj));

		String phone = '';
		if (obj.isSet('Phone')) phone = (String) obj.get('Phone');
		if (phone==null) phone = '';
		phone = justDigits(phone);
		similarphone = phone.getLevenshteinDistance(phonenbr)<=1;
		System.debug(phone + ' ?=? ' + phonenbr);
		if (mon!=null) mon.log(phone + ' ?=? ' + phonenbr);
		boolean suspectedBadPhone = phone.mid(0,3)=='555' || phone.mid(3,3)=='555';

		String email = '';
		if (obj.getSObjectType()==Schema.Account.SObjectType) {
			if (obj.isSet('Email__c')) email = (String) obj.get('Email__c');
		} else {
			if (obj.isSet('Email')) email = (String) obj.get('Email');
		}
		if (email==null) email = '';
		email = email.toLowerCase();
		similaremail = email.getLevenshteinDistance(emailaddr.toLowerCase())<=2;
		System.debug(email + ' ?=? ' + emailaddr);
		if (mon!=null) mon.log(email + ' ?=? ' + emailaddr);
		boolean suspectedBadEmail = stringContainsAny(email, suspectEmailAddr);

		String lastname = '';
		if (obj.getSObjectType()==Schema.Account.SObjectType) {
			if (obj.isSet('Name')) lastname = (String) obj.get('Name');
		} else {
			if (obj.isSet('LastName')) lastname = (String) obj.get('LastName');
		}
		if (lastname==null) lastname = '';
		lastname = lastname.toLowerCase();

		String firstname = '';
		if (obj.getSObjectType()==Schema.Account.SObjectType) {
			if (obj.isSet('Name')) firstname = (String) obj.get('Name');
		} else {
			if (obj.isSet('FirstName')) firstname = (String) obj.get('FirstName');
		}
		if (firstname==null) firstname = '';
		firstname = firstname.toLowerCase();
		if (String.isBlank(firstname)) {
			List<String> names = lastname.split(' ');
			if (names.size()==2) {
				firstname = names[0];
				lastname = names[1];
			}
		}
		similarlastname = (lastname.length()>4 && lastname.getLevenshteinDistance(lname.toLowerCase())<=2)
			|| (lastname.equalsIgnoreCase(lname.toLowerCase()));
		System.debug(lastname + ' ?=? ' + lname);
		if (mon!=null) mon.log(lastname + ' ?=? ' + lname);
		System.debug(similarlastname);
		
		similarfirstname = (firstname.length()>4 && firstname.getLevenshteinDistance(fname.toLowerCase())<=2)
			|| (firstname.equalsIgnoreCase(fname.toLowerCase()));
		System.debug(firstname + ' ?=? ' + fname);
		if (mon!=null) mon.log(firstname + ' ?=? ' + fname);
		System.debug(similarfirstname);

		if (similarphone && !suspectedBadPhone) rank += 1;
		if (similaremail && !suspectedBadEmail) rank += 2;
		if (similarlastname) rank += 2;
		if (similarfirstname) rank += 1;

		System.debug('Rank=' + rank + ' for ' + JSON.serialize(obj));
		if (mon!=null) mon.log('Rank=' + rank + ' for ' + JSON.serialize(obj));
		return rank>=targetrank && (similarphone || similaremail);
	}

	// createTask for Lead/Account/Contact
	public Task createTask(SObject foundRcd, String description) {
		if (mon!=null) mon.log('createTask');
        Task t = new Task(
			ActivityDate = Date.today(),
			Subject='Email received', 
			Status='Not started',
			Source_type__c='Email',
			Description = description
		);
		Id storeId = null;
		if (foundRcd.getSObjectType()==Schema.Account.SObjectType) {
			Account a = (Account) foundRcd;
			if (a.isPersonAccount) t.WhoId = a.PersonContactId;
			t.OwnerId = a.OwnerId;
			storeId = a.Store_Location__c;
		} else if (foundRcd.getSObjectType()==Schema.Contact.SObjectType) {
			Contact c = (Contact) foundRcd;
			t.WhoId = c.Id;
			t.OwnerId = c.OwnerId;
			if (c.AccountId!=null) storeId = c.Account.Store_Location__c;
		} else if (foundRcd.getSObjectType()==Schema.Lead.SObjectType) {
			Lead l = (Lead) foundRcd;
			t.WhoId = l.Id;
			t.OwnerId = l.OwnerId;
			storeId = l.Store_Location__c;
			if (l.isConverted) {
                // Generate an activity (task) on the Contact
                t.WhoId = l.ConvertedContactId; // BLL6a
                // use contact owner
                try {
                	Contact c = [select Id, Name, OwnerId from Contact where Id=:t.WhoId limit 1];
                	Account a = [select Id, Name, Store_Location__c from Account where Id=:l.ConvertedAccountId limit 1];
                	if (c!=null && c.OwnerId!=null) l.OwnerId = c.OwnerId;
                	if (a!=null && a.Store_Location__c!=null) l.Store_Location__c = a.Store_Location__c;
				} catch(Exception e) { }
			}
		}

        // Don't try to assign a task to a queue!
		Schema.sObjectType entityType = t.OwnerId.getSObjectType();
        if (entityType==Group.SObjectType) t.OwnerId = null;
		// If no owner, try the store's GM
		if (t.OwnerId==null && storeId!=null) {
			LocationsSingleton ls = LocationsSingleton.getInstance();
			ls.addLocationIds(new Set<Id>{storeId});
			dealer__Dealer_Location__c loc = ls.getLocationById(storeId);
			t.OwnerId = loc.dealer__General_Manager__c;
		}
		// If no owner, use current user
		if (t.OwnerId==null) t.OwnerId = UserInfo.getUserId();
		if (mon!=null) mon.log(JSON.serialize(t));

		return t;
	}
	// BLL20 end

	// BLL23
	public boolean processLivePersonPayloadXML(String emailBody) {

		Lead l = new Lead();
        l.Lead_Type__c= 'Email';
        l.LeadSource = 'LivePerson';
		l.Email_Lead_Content__c = emailBody;
		String contactName = '';
        String firstName = '';
        String lastName = '';

		try {
			Dom.Document doc = new Dom.Document();
			doc.load(emailBody);
			System.debug(doc.getRootElement());
			for (Dom.XmlNode node : doc.getRootElement().getChildElements()) {
			    System.debug(node.getName());
			    for(Dom.XmlNode subnode : node.getChildElements()) {
			        System.debug(subnode.getName());
					if (subnode.getName()=='vehicle') {
						for(Dom.XmlNode veh : subnode.getChildElements()) {
							System.debug(veh.getName()+'='+veh.getText());
						}
			            System.debug(subnode.getName() + ' end');
					} else if (subnode.getName()=='customer') {
						for(Dom.XmlNode cust : subnode.getChildElements()) {
							System.debug(cust.getName());
							if (cust.getName()=='contact') {
								for(Dom.XmlNode cont : cust.getChildElements()) {
			                        String name=cont.getName();
									String attr='';
			                        if (cont.getAttribute('part', null)!=null) attr = cont.getAttributeValue('part', null);
									System.debug(name + ' ' + attr + '=' + cont.getText());
									if (name=='name' && attr=='first') firstname = cont.getText();
									if (name=='name' && attr=='last') lastname = cont.getText();
									if (name=='name' && attr=='full') contactName=cont.getText();
									if (name=='email') l.Email = cont.getText();
									if (name=='phone') l.Phone = cont.getText();
								}
							}
						}
			            System.debug(subnode.getName() + ' end');
					}
			    }
			}
		} catch(Exception e) {}

		if (String.isBlank(firstname) && String.isBlank(lastname)) {
			SplitName sn = new SplitName(contactName);
        	firstname = sn.FirstName;
        	lastname = sn.LastName;
		}
		l.FirstName =   firstName.capitalize();
        l.LastName  =   lastName.capitalize();			

		if ((!String.isBlank(l.FirstName) && l.FirstName!='-not provided-') 
        	|| (!String.isBlank(l.LastName) && l.LastName!='-not provided-')) {  // BLL5a
            try {
                handleEmailLead(l);
            } catch (DmlException e) {
                notifyOnFailure('LivePerson XML Lead Parse Fail', e.getMessage() + '\n' + emailBody);
                return false;
            }
        } else {
            notifyOnFailure('LivePerson XML lead missing name', emailBody);
            return false;
        }
  
        return true;
	}


	public boolean processLivePersonPayload(String emailBody) {
        valueMap = leadDetails(lineSplit(emailBody));
		if (mon!=null) mon.log(JSON.serialize(valueMap));	// BLL17
        if(valueMap==null) throw new ParseException('Error parsing Uber lead.  No value returned');
        Lead l = new Lead();

        // Client Block
        String contactName = (valueMap.get('name')!=null) ? String.valueOf(valueMap.get('name')) : '';
        String firstName;
        String lastName;
        SplitName sn = new SplitName(contactName);
        firstname = sn.FirstName;
        lastname = sn.LastName;

        l.FirstName =   firstName.capitalize();
        l.LastName  =   lastName.capitalize();
        l.Lead_Type__c= 'Email';

        //communicationBlock
        l.Phone       = (valueMap.get('phone')!=null) ? String.valueOf(valueMap.get('phone')) : null;
        String em     = (valueMap.get('email')!=null) ? String.valueOf(valueMap.get('email')) : null;
        l.Email       = extractEmail(em);

        //l.Description = (valueMap.get('question')!=null) ? String.valueOf(valueMap.get('question')) : null;

        l.Email_Lead_Content__c = emailBody;
        l.LeadSource = 'LivePerson';
        
        //String product = (valueMap.get('interest')!=null) ? String.valueOf(valueMap.get('interest')) : null;

        // BLL5d if (!String.isBlank(l.FirstName) || !String.isBlank(l.LastName)) {
        if ((!String.isBlank(l.FirstName) && l.FirstName!='-not provided-') 
        	|| (!String.isBlank(l.LastName) && l.LastName!='-not provided-')) {  // BLL5a
            try {
                //insert l;
                handleEmailLead(l);
            } catch (DmlException e) {
                notifyOnFailure('Uber Lead Parse Fail', e.getMessage() + '\n' + emailBody);
                return false;
            }
        } else {
            notifyOnFailure('Uber lead missing name', emailBody);
            return false;
        }
  
        return true;
	}
	// BLL23 end

}