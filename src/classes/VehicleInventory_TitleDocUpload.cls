/**
 * VehicleInventory_TitleDocUpload
 * Tested by: VehicleInventory_TitleDocUpload_Test
 *
 *	Coverage:
 *	2018-08-27	92%	(63/68)
 *
 *  2016-11-09  A. Bangle   Created Class to add custom logic to the TitleDocUpload VFP
 *  2016-12-01  A. Bangle   Created Test Class
 *  2017-02-21  A. Bangle   Added updateDocLinks method to be triggered by javascript on VF page
 *	2018-08-27	B. Leaman	BLL1 - don't update vehicle record on load of widget if nothing changed.
 *							In lightning this prevented ALL record updates from the screen by the user.
 */

public class VehicleInventory_TitleDocUpload {
    
    // Set dropdown var
    String titleDocItems {get;set;}
    
    // Build Document Dropdown
    public PageReference docSelection() {
        return null;
    }
    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','Select Document to Upload'));
        options.add(new SelectOption('lien-release.pdf','Lien Release'));
        options.add(new SelectOption('power-of-attorney.pdf','Power of Attorney'));
        options.add(new SelectOption('mso-title.pdf','MSO/Title'));
        options.add(new SelectOption('proof-payment-trade.pdf','Payment/Trade'));
        options.add(new SelectOption('invoice.pdf','Invoice'));
        options.add(new SelectOption('rental-registration.pdf','Rental Registration'));
        options.add(new SelectOption('rental-insurance.pdf','Rental Insurance'));
        return options;
    }
    public String getTitleDocItems() {
        return titleDocItems;
    }
    public void setTitleDocItems(String titleDocItems) {
        this.titleDocItems = titleDocItems;
    }  
    

    
    // Set document name variables
    public String lienRelease {get;set;}
    public String powerofAttorney {get;set;}
    public String msoTitle {get;set;}
    public String proofPaymentTrade {get;set;}
    public String invoice {get;set;}
    public String rentalRegistration {get;set;}
    public String rentalInsurance {get;set;}
    public String stockNum {get;set;}
    // Set the document check box variables
    public Boolean lienReleaseCheck {get;set;}
    public Boolean powerofAttorneyCheck {get;set;}
    public Boolean msoTitleCheck {get;set;}
    public Boolean proofPaymentTradeCheck {get;set;}
    
    public dealer__Vehicle_Inventory__c veh {get; private set;}
    
    // Test vehicle Id
    //String vehicleId = vehicle.Id;
    
        public VehicleInventory_TitleDocUpload(ApexPages.StandardController controller) {
            veh = (dealer__Vehicle_Inventory__c) controller.getRecord();
            //BLL1d stockNum = [SELECT dealer__Stock_Number__c FROM dealer__Vehicle_Inventory__c WHERE Id = :veh.Id LIMIT 1].dealer__Stock_Number__c;
            if (veh.Id!=null) veh = [SELECT Id, Name, dealer__Stock_Number__c, Lien_Release__c, Power_of_Attorney__c, MSO_Title__c, Proof_of_Payment_Trade__c FROM dealer__Vehicle_Inventory__c WHERE Id = :veh.Id LIMIT 1];	// BLL1a
            stockNum = veh.dealer__Stock_Number__c;	// BLL1a
            System.debug(veh.Id);
            updateDocLinks();
        } 

        public void updateDocLinks() {
            List<Attachment> allAttachments = [SELECT Id, ParentId, OwnerId, Name, LastModifiedDate, LastModifiedById, Description, CreatedDate FROM Attachment WHERE ParentId = :veh.Id];
            for (Attachment file : allAttachments) {
                if (file.Name == stockNum+'-lien-release.pdf') {lienRelease = file.Id;}
                if (file.Name == stockNum+'-power-of-attorney.pdf') {powerOfAttorney = file.Id;}
                if (file.Name == stockNum+'-mso-title.pdf') {msoTitle = file.Id;}
                if (file.Name == stockNum+'-proof-payment-trade.pdf') {proofPaymentTrade = file.Id;}
                if (file.Name == stockNum+'-invoice.pdf') {invoice = file.Id;}
                if (file.Name == stockNum+'-rental-registration.pdf') {rentalRegistration = file.Id;}
                if (file.Name == stockNum+'-rental-insurance.pdf') {rentalInsurance = file.Id;}
            }
        }
    
    	public void updateFlags() {
            lienReleaseCheck = false;
            powerOfAttorneyCheck = false;
            msoTitleCheck = false;
            proofPaymentTradeCheck = false;
        	List<Attachment> allAttachments = [SELECT Id, ParentId, OwnerId, Name, LastModifiedDate, LastModifiedById, Description, CreatedDate FROM Attachment WHERE ParentId = :veh.Id];
            for (Attachment file : allAttachments) {
                if (file.Name == stockNum+'-lien-release.pdf') {lienReleaseCheck = true;}
                if (file.Name == stockNum+'-power-of-attorney.pdf') {powerOfAttorneyCheck = true;}
                if (file.Name == stockNum+'-mso-title.pdf') {msoTitleCheck = true;}
                if (file.Name == stockNum+'-proof-payment-trade.pdf') {proofPaymentTradeCheck = true;}
            }
            try {
            	// BLL1a in lightning, this update was causing the vehicle record to be updated every tim
            	// it was viewed, also preventing ALL edits on-screen because the record had 
            	// been updated since it was loaded
            	boolean doUpdate = veh.Lien_Release__c != lienReleaseCheck 
            		|| veh.Power_of_Attorney__c != powerOfAttorneyCheck
            		|| veh.MSO_Title__c != msoTitleCheck
            		|| veh.Proof_of_Payment_Trade__c != proofPaymentTradeCheck;
                veh.Lien_Release__c = lienReleaseCheck;
                veh.Power_of_Attorney__c = powerOfAttorneyCheck;
                veh.MSO_Title__c = msoTitleCheck;
                veh.Proof_of_Payment_Trade__c = proofPaymentTradeCheck;
                if (doUpdate) update veh;	// BLL1c
            } catch (DmlException e) {
                System.debug('An unexpected error has occurred: ' + e.getMessage());
            }
    	}

}