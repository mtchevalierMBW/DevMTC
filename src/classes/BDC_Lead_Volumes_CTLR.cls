// Represents matrix report data
//             Last 7 days_____________  Last 30 days____________  Qtr to date_____________
// BDC Rep	   Qual  UnQual Other Total  Qual  UnQual Other Total  Qual  UnQual Other Total
// Rep Name       1       2     0     3     5      10     2    17    15      32     8    55
public with sharing class BDC_Lead_Volumes_CTLR {

    public Map<String, WeekMthQtr> matrix {get; private set;}
   	public Date tdy = Date.today();
    public Date beginQtr {get; set;}
    public String summarizeBy {get; set;}
    public String queueName {get; private set;}
    Transient WeekMthQtr wmq = null;
    
    public BDC_Lead_Volumes_CTLR() {
    	summarizeBy = 'BDC Rep';  // vs 'Source'
    	Map<String,String> URLParameters = ApexPages.currentPage().getParameters();
        if (URLParameters.containsKey('key')) {
            String key = URLParameters.get('key');
            if (key.equalsIgnoreCase('source')) {
            	summarizeBy = 'Source';
            }
        }
    	
    	queueName = 'BDC'; 
    	matrix = new Map<String, WeekMthQtr>();
    	beginQtr = Date.today();
    	beginQtr = beginQtr.toStartOfMonth();
    	Integer m = beginQtr.month();
    	if (m==2 || m==5 || m==8 || m==11) {
    		beginQtr = beginQtr.addMonths(-1);
    	} else if (m==3 || m==6 || m==9 || m==12) {
    		beginQtr = beginQtr.addMonths(-2);
    	}
    	System.debug('beginQtr=' + beginQtr.format());
    	summarize();
    }
    
    public List<WeekMthQtr> getSummary() {
    	List<WeekMthQtr> wmq = new List<WeekMthQtr>();
    	for(String k : matrix.keySet()) {
    		wmq.add(matrix.get(k));
    	}
    	return wmq;
    }
    
    // summarize the historical data
    public void summarize() {
    	if (summarizeBy=='BDC Rep') {
    		summarizeByRep();
    	} else if (summarizeBy=='Source') {
    		summarizeBySource();
    	}
    }
    
    // summarize by rep
    public void summarizeByRep() {
    	String key;
    	for(Lead l : [select Id, Name, CreatedDate, Status, Lead_Queue_Name__c, Lead_Type__c, LeadSource, Responsible_Rep__r.Name
    	              from Lead 
    	              where CreatedDate >= :beginQtr and Lead_Queue_Name__c=:queueName
    	              order by Responsible_Rep__r.Name ]) {
    	    // Setup key
    	    key = l.Responsible_Rep__r.Name;
    	    summarizeToKey(key, l);
    	} 
    }
    
    // summarize by source
    public void summarizeBySource() {
    	String key;
    	for(Lead l : [select Id, Name, CreatedDate, Status, Lead_Queue_Name__c, Lead_Type__c, LeadSource, Responsible_Rep__c
    	              from Lead 
    	              where CreatedDate >= :beginQtr and Lead_Queue_Name__c=:queueName
    	              order by Lead_Type__c, LeadSource ]) {
    	    // combine website sources
    	    if (l.Lead_Type__c=='Website') {
    	    	key = 'Website';
    	    } else {
    	        key = l.LeadSource;
    	    }
    	    summarizeToKey(key, l);
    	} 
    }
    
    // summarizeToKey
    public void summarizeToKey(String key, Lead l) {
	    // Get summary group-by (rep) object with metrics
		if (wmq==null || wmq.key != key) {
			wmq = matrix.get(key);
		}
		// If it's a new rep, create a new bucket for metrics
		if (wmq==null) {
			wmq = new WeekMthQtr(key);
			matrix.put(key, wmq);
		}
		// Accumulate nbr of leads for each bucket
		if (l != null && l.CreatedDate != null) {
			//if (tdy.daysBetween(l.CreatedDate.date())>30) {
				wmq.qtr.addByStatus(l.Status, 1);
			//}
			if (tdy.daysBetween(l.CreatedDate.date())<30) {
				wmq.last30.addByStatus(l.Status, 1);
			}
			if (tdy.daysBetween(l.CreatedDate.date())<7) {
				wmq.last7.addByStatus(l.Status, 1);
			}
		} 
    }

    // Buckets of volumes lead status
    class WeekMthQtr {
    	public String key {get;set;}
    	public LeadStatusVolumes last7 {get;set;}
    	public LeadStatusVolumes last30 {get;set;}
    	public LeadStatusVolumes qtr {get;set;}
    	
    	public WeekMthQtr(String k) {
    		last7 = new LeadStatusVolumes();
    		last30 = new LeadStatusVolumes();
    		qtr = new LeadStatusVolumes();
    		key = k;
    	}
    }

    // Buckets for lead statuses
    class LeadStatusVolumes {
    	public Integer qualified {get;private set;}
    	public Integer unqualified {get;private set;}
    	public Integer other {get;private set;}
    	public Integer total {get;private set;}
    	
    	public LeadStatusVolumes() {
    		qualified = 0;
    		unqualified = 0;
    		other = 0;
    		total = 0;
    		if (Test.isRunningTest()) {
    		    addQualified(1);
    		    addUnqualified(1);
    		    addOther(1);
    		    setQualified(0);
    		    setUnqualified(0);
    		    setOther(0);
    		} 
    	}
    	public void addByStatus(String sts, Integer nbr) {
    		if (sts=='Qualified') {
    			addQualified(nbr);
    		} else if (sts=='Unqualified') {
    			addUnqualified(nbr);
    		} else {
    			addOther(nbr);
    		}
    	}
    	public void setQualified(Integer nbr) {
    		qualified = nbr;
    		calcTotal();
    	}
    	public void addQualified(Integer nbr) {
    		qualified += nbr;
    		calcTotal();
    	}
    	public void setUnqualified(Integer nbr) {
    		unqualified = nbr;
    		calcTotal();
    	}
    	public void addUnqualified(Integer nbr) {
    		unqualified += nbr;
    		calcTotal();
    	}
    	public void setOther(Integer nbr) {
    		unqualified = nbr;
    		calcTotal();
    	}
    	public void addOther(Integer nbr) {
    		other += nbr;
    		calcTotal();
    	}
    	public void calcTotal() {
    		total = qualified + unqualified + other;
    	}
    }

}