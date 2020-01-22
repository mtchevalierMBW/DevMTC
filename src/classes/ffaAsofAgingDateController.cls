public class ffaAsofAgingDateController {
	public c2g__AsOfAgingReportSettings__c agingSettings {get;set;}
	public Contact dummyContact1 {get;set;}
	public Contact dummyContact2 {get;set;}

	public ffaAsofAgingDateController() {
		agingSettings = c2g__AsOfAgingReportSettings__c.getOrgDefaults();
		dummyContact1 = new Contact(
			Birthdate = agingSettings.Statement_Start_Date__c);
		dummyContact2 = new Contact(
			Birthdate = agingSettings.Custom_As_of_Age_Date__c);
	}

	public void doSave(){
		system.debug('Aging Settings = '+agingSettings);
        try{
        	agingSettings.Start_Date_TEXT__c = dummyContact1.Birthdate != null ? dummyContact1.Birthdate.year()+'-'+dummyContact1.Birthdate.month().format().leftPad(2, '0')+'-'+dummyContact1.Birthdate.day().format().leftPad(2, '0') : null;
        	agingSettings.Statement_Start_Date__c = dummyContact1.Birthdate != null ? dummyContact1.Birthdate : null;
        	agingSettings.End_Date_TEXT__c = dummyContact2.Birthdate != null ? dummyContact2.Birthdate.year()+'-'+dummyContact2.Birthdate.month().format().leftPad(2, '0')+'-'+dummyContact2.Birthdate.day().format().leftPad(2, '0') : Date.today().year()+'-'+Date.today().month().format().leftPad(2, '0')+'-'+Date.today().day().format().leftPad(2, '0');
        	agingSettings.Custom_As_of_Age_Date__c = dummyContact2.Birthdate != null ? dummyContact2.Birthdate : null;
	        update agingSettings;
	        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM,
	            'Save Successful!'));  
	    }
	    catch (Exception e){
	        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,e.getMessage())); 
	        system.debug('ERRor in save = '+e.getMessage() + e.getCause() +  e.getStackTraceString());
	    }   
    }
  
    public PageReference doCancel(){
        PageReference ref = new PageReference('/home/home.jsp'); 
        ref.setRedirect(true);
        return ref; 
    }

}