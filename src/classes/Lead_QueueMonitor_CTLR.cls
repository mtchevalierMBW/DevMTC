// Lead_QueueMonitor_CTLR
// Used in VF page Lead_QueueMonitor
// Tested by Test_LeadClasses 
// Displays the count of leads issigned to a given queue
// Setting hierarchy:
// MW Queue Monitor (MW_QueueMonitor__c) Queue_name__c, Refresh_seconds__c
public with sharing class Lead_QueueMonitor_CTLR {

    public Integer LeadsInQueueCount {get; private set;}
    public DateTime NewestDateTime {get; private set;}
    public Integer RefreshSeconds {get; private set;}
    public String QueueName {get; private set;}
    public String CountColor {get; private set;}
    public String ListViewURL {get; private set;}
    public boolean HasURL {get; private set;}

    private DateTime lastDateTime;
    private String queueId;
    private List<String> leadStatuses;
    private String ListViewName=null;

    /**
     * constructor
     */
    public Lead_QueueMonitor_CTLR() {
    	LeadsInQueueCount = null;
    	NewestDateTime = null;
    	queueId = null;
    	lastDateTime = null;
		CountColor = '#333333';
    	
    	// Default settings...
    	RefreshSeconds = 120;
    	QueueName = 'BDC';
    	
    	// now try loading from Custom Settings
    	MW_QueueMonitor__c queueSettings = MW_QueueMonitor__c.getInstance();
    	if (queueSettings==null) {
    		queueSettings = MW_QueueMonitor__c.getOrgDefaults();
    	}
    	if (queueSettings!=null) {
    		QueueName = (queueSettings.Queue_Name__c != null) ? queueSettings.Queue_name__c : QueueName;
    		RefreshSeconds = (queueSettings.Refresh_seconds__c != null) ? (Integer) queueSettings.Refresh_seconds__c : RefreshSeconds;
    		if (queueSettings.Lead_Statuses__c != null) {
    		    leadStatuses = queueSettings.Lead_Statuses__c.split(',');
    		} else {
    			leadStatuses = new List<String>();
    			leadStatuses.add('New');
    		}
    	}
    	
    	// Grab the queue Id once on page load...
    	List<Group> queue = [
    		SELECT Id, Name, Type, DeveloperName 
			FROM Group
			WHERE Type='Queue' and Name=:QueueName
		];
		if (queue!=null && queue.size()>0) {
			queueId = queue[0].Id;
		}
		
		if (ApexPages.currentPage().getCookies().containsKey(QueueName+'_url')) {
    	   ListViewURL = ApexPages.currentPage().getCookies().get(QueueName+'_url').getValue();
    	   if (String.isBlank(ListViewURL)) {
    	   	   ListViewURL = null;
    	   }
		}
		if (ListViewURL==null) {
    	// Generate URL to jump to list view, if view name provided
    	   ListViewURL = generateListViewURL('Lead', queueSettings.List_view_name__c);
    	   if (ListViewURL != null) {
    	   	   Cookie listurlcookie = new Cookie(QueueName+'_url', ListViewURL, null, -1, true);
    	   	   ApexPages.currentPage().setCookies(new Cookie[] {listurlcookie});
    	   }
		}
    	HasURL = (ListViewURL != null);

    	// Get the current info for display!
    	updateCount();
    	lastDateTime = NewestDateTime;
    	
    }

    /**
     * generateListViewURL
     */
	public String generateListViewURL(String obj, String viewName) {
		String ListViewId=null;
		String ListViewURL=null;
		Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
		Schema.DescribeSObjectResult r =  gd.get(obj).getDescribe();
		String pfx = r.getKeyPrefix();
		//System.debug(pfx);
		String q = 'SELECT Id, Name FROM ' + Obj + ' LIMIT 1';
		ApexPages.StandardSetController ACC = new ApexPages.StandardSetController(Database.getQueryLocator(q));
		//System.debug('StandardSetController=' + ACC);
		List<SelectOption> ListViews = ACC.getListViewOptions();
		//System.debug('Count of list views=' + ListViews.size());
		for(SelectOption w : ListViews ){
			//System.debug('Equal? ' + w.getLabel() + '=?' + viewName);
		    if(w.getLabel()==viewName){
		        ListViewId = w.getValue().left(15);
		        ListViewURL='/'+pfx+'?fcf='+ListViewId;
		    }
		}
		//System.debug('ListViewURL=' + ListViewURL);
		return ListViewURL;
	}

    /**
     * updateCount
     */
    public void updateCount() {
    	leadsInQueueCount=null; 
		if (queueId!=null || Test.isRunningTest()) {
			AggregateResult[] r = [select count(Id) cnt, max(CreatedDate) newestdate 
			                       from Lead 
			                       where OwnerId=:queueId and Status in :leadStatuses];
			if (r != null && r.size()>0) {
				LeadsInQueueCount = (Integer) r[0].get('cnt');
				NewestDateTime = (DateTime) r[0].get('newestdate');
				if (lastDateTime!=null && NewestDateTime>lastDateTime) {
					CountColor = '#aa0000';
				} else {
					CountColor = '#333333';
				}
			}
		}
		
    }

}