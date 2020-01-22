public class PartMigrateOnHand_EXT {
    public dealer__Parts_Master__c oldMaster {get;set;}
    public dealer__Parts_Master__c newMaster {get;set;}
    public dealer__Parts_Inventory__c newInvMaster {get;set;}
    public PartMigrateOnHand_EXT(ApexPages.StandardController sc) {
        oldMaster = (dealer__Parts_Master__c)sc.getRecord();
        newInvMaster = new dealer__Parts_Inventory__c();
    }
    
    public pageReference movePart() {
        try {
            PartSupportAPI.migrateOnHand(oldMaster.Id, newInvMaster.dealer__Parts_Master__c);
        } Catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,e.getMessage()));
            return null;            
        }
        
     	PageReference pr = new PageReference('/'+newInvMaster.dealer__Parts_Master__c);
        pr.setRedirect(true);
		return pr;
    }
}