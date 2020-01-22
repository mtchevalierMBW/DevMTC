/**
 * MonitorExecution
 * Tested by: MonitorExecution_TEST
 * Programmer: Bryan Leaman
 * Date: 2015-10-27
 * Custom setting: MonitorExecution__c
 * 
 * Mechanism for notifications of problems when they occur.
 * 
 * 	2016-01-08	B. Leaman	BLL1 - add capability to email a group.
 * 	2016-07-29	B. Leaman	BLL2 - Use CurrentUserSingleton instead of SOQL.
 * 
 */
public class MonitorExecution {

    private List<LogEntry> logentries = null;
    private User admin = null;
    private String monitorname;
    private MonitorExecution__c settings;
    private boolean enabled = false;
    public boolean AlwaysNotify = false;

	// Constructor
    public MonitorExecution(String logname) {
        logentries = new List<LogEntry>();
        monitorname = logname;
        settings = MonitorExecution__c.getInstance(logname);
        if (settings!=null && settings.Enabled__c==true) {
            enabled = true;
        }
        if (settings!=null && settings.AlwaysNotify__c==true) {
            AlwaysNotify = true;
        }
    }
    
    // log - add a log entry (as a string, use JSON.serialize(obj) to log an object)
    public void log(String s) {
        if (enabled) logentries.add(new LogEntry(s));
    }

	// getSubject - construct email or task subject as name of monitor and organization
    public String getSubject() {
        String s = monitorname + ' from Org: ' + UserInfo.getOrganizationName();
        return s;
    }
    
    // getLogText - concatenate log entries into message body
    public String getLogText() {
        String l = '';
        for (LogEntry e : logentries) {
            l += e.timestamp.format('yyyy-MM-dd HH:mm:ss') + ' : ' + e.text + '\r';
        }
        return l;
    }

	// getUserAndOrg - return user name and organization name
    public String getUserAndOrg() {
        return UserInfo.getName() + ' / ' + UserInfo.getOrganizationName() + '\r\r';
    }

	// notifyAdmin - notify admin (and group, if specified)
    public void notifyAdmin() {
        if (enabled) {
            if (settings!=null && settings.NotificationType__c=='Task') {
                createLogTask();
            } else {
                sendLogEmail();
            }
            // BLL1a
            if (settings!=null && settings.GroupEmail__c!=null) {
            	sendLogEmail(settings.GroupEmail__c);
            }
            // BLL1a
        }
    }

	// sendLogEmail - send the entire log as an email message to the admin
    public void sendLogEmail() {
        if (!enabled || logentries.size()==0) return;
        User u = getAdmin();
        Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {u.Email};
        mail.setToAddresses(toAddresses); 
        mail.setSubject(getSubject());
        mail.setPlainTextBody(getUserAndOrg() + getLogText());
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } catch(Exception e) {}      
    }
    
	// sendLogEmail to a group
    public void sendLogEmail(String groupname) {
        if (!enabled || logentries.size()==0) return;
        Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
        String[] toAddresses = new List<String>();
        Group g = [select Id, Name from Group where Type='Regular' and Name=:groupname limit 1];

		toAddresses.addAll(getGroupEmails(g.Id));
		System.debug(toAddresses);

        if (toAddresses.size()>0) {
        	mail.setToAddresses(toAddresses); 
        	mail.setSubject(getSubject());
        	mail.setPlainTextBody(getUserAndOrg() + getLogText());
        	try {
	        	System.debug('Sending email');
    	   	    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        		System.debug(mail);
        	} catch(Exception e) {System.debug('Unable to send email'); System.debug(e);}      
    	}
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
    
    // createLogTask - create a task with the log info in the description
    public void createLogTask() {
        if (!enabled || logentries.size()==0) return;
        User u = getAdmin();
        Task t = new Task(
            OwnerId = u.Id,
            ActivityDate = Date.today(),
            Subject = getSubject(),
            Description = getUserAndOrg() + getLogText(),  
            Status='Not started'            
        );
        try {
            insert(t);
        } catch(Exception e) {}
    }
    
    // getAdmin - return the user specified as the Admin for this monitor
    public User getAdmin() {
        if (admin==null) {
            try {
                admin = [select Id, Name, Email from User where Name = :settings.AdminName__c limit 1];
            } catch(Exception e) {
                //BLL2d admin = [select Id, Name, Email from User where Id=:UserInfo.getUserId() limit 1];
                admin = CurrentUserSingleton.getInstance();	// BLL2a
            }
        }
        return admin;
    }
    
    // LogEntry - wrapper class for log entries - adds date/time to the log entry
    class LogEntry {
        public Datetime timestamp;
        public String text;
        public LogEntry(String s) {
            timestamp = Datetime.now();
            text = s;
        }
    }
    
}