/**
 * TransactionDownload_CTLR
 * Tested by: TransactionDownloadBatch_TEST
 * 
 * 	2016-03-15	B. Leaman	BLL1 - Load through a specific period only.
 *							When period changes, add "or period='yyyy/ppp'" to soql to get whole period.
 */
public with sharing class TransactionDownload_CTLR {

	public String sinceTransaction {get; set;}
	public String untilTransaction {get; set;}
	public boolean saveLastTransaction {get; set;}
	public String lastSubmittedDT {get; private set;}
	public String lastCompletedDT {get; private set;}
	public boolean overrideSelection {get; set;}
	public String throughPeriodName {get;set;}	// BLL1a
	public boolean wholePeriod {get;set;}	// BLL1a

	public boolean isAdmin {get;private set;}
	public DownloadTransactionsControl__c lastDownload {get;private set;}
	
	public boolean Completed {get; private set;}
	private boolean saveEndPoint;
	
	public TransactionDownload_CTLR() {
		lastDownload = DownloadTransactionsControl__c.getOrgDefaults();
		sinceTransaction = lastDownload.LastTransactionName__c;
		Completed = true;
		if (lastDownload.LastSubmitted__c!=null 
			&& (LastDownload.lastCompleted__c==null || lastDownload.LastSubmitted__c>lastDownload.lastCompleted__c)) {
			Completed = false;
		}
		lastSubmittedDT = '';
		lastCompletedDT = '';
		if (lastDownload.LastSubmitted__c!=null) {
			lastSubmittedDT = lastDownload.LastSubmitted__c.format('MM/dd/yyyy hh:mm:ss a');
		}
		if (lastDownload.LastCompleted__c!=null) {
			lastCompletedDT = lastDownload.LastCompleted__c.format('MM/dd/yyyy hh:mm:ss a');
		}
		// BLL1a
		throughPeriodName = lastDownload.ThroughPeriodName__c!=null ? lastDownload.ThroughPeriodName__c : '';
		wholePeriod = false;
		// BLL1a end
		
		// Admin gets additional info
		Profile p = [
            select Id, Name, PermissionsModifyAllData 
            from Profile 
            where Id=:UserInfo.getProfileID() 
            limit 1
        ];
		isAdmin = (p!=null && (p.Name.contains('Admin') || p.PermissionsModifyAllData==true));
		if (isAdmin) Completed=true; // allow admin to download anyway
		// Will always save
		saveLastTransaction=false;
		saveEndpoint = true;
	}
	
	
	public void dummyProc() {}
	
	public boolean validateRequest() {
		boolean okay = true;
		if (wholePeriod && String.isBlank(throughPeriodName)) {
			okay = false;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Period name is required if selecting all transactions in the period'));
		}
		return okay;
	}
	
	public void chgPeriod() {
		String lastThruPeriod = lastDownload.ThroughPeriodName__c!=null ? lastDownload.ThroughPeriodName__c : '';
		wholePeriod = !String.isBlank(throughPeriodName) && throughPeriodName!=lastThruPeriod;
	}
	
	public void logSubmit() {
		if (saveEndPoint) {
			lastDownload.LastSubmitted__c = Datetime.now();
			lastDownload.LastSubmittedBy__c = UserInfo.getName();
			upsert(lastDownload);
			Completed = false;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'New Transactions download submitted'));
		} else {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Admin download submitted'));
		}
	}
	
	public void submitDownload() {
		if (validateRequest()) {
			saveEndPoint = true;
			if (isAdmin && overrideSelection && !saveLastTransaction) saveEndPoint = false;
			TransactionDownloadBatch download = new TransactionDownloadBatch(sinceTransaction, untilTransaction, saveEndPoint, throughPeriodName, wholePeriod);	// BLL1c add throughPeriod, wholePeriod
			Id batchprocessid = Database.executeBatch(download, 200);
			logSubmit();
		}
	}
	
}