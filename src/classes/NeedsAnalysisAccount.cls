public with sharing class NeedsAnalysisAccount {
    public dealer__Sales_Up__c sup;
    public Account NeedsAnalysis {get;set;}
    public NeedsAnalysisAccount(ApexPages.StandardController controller) {
        Map<String, Schema.SObjectField> M = Schema.SObjectType.dealer__Sales_Up__c.fields.getMap();
        List<String> af = new List<String>();
        Set<String> fieldnames = M.keySet(); 
        af.addAll(fieldnames);
        if(!Test.isRunningTest()) {             
            controller.addFields(af);
        }       
        sup = (dealer__Sales_Up__c)controller.getRecord();

        if(sup.dealer__Customer_Account__c != null) {
            NeedsAnalysis = [Select Id, dtffa__A__c, dtffa__B__c, dtffa__Actual_Estimate__c, dtffa__C__c, dtffa__Chair_Brand__c, dtffa__Chair_Dimensions_Diagram__c, dtffa__Chair_Model__c, Claim_Number__c, dtffa__Client_In_Chair_Weight__c, dtffa__End_User__c, dtffa__Physical_Challenge__c,dtffa__AnalysisDate__c,dtffa__PlannedChanges__c,NeedsAssessmentRecordedBy__c,NeedsAssessmentRecordedBy__r.Name
                From Account where Id=:sup.dealer__Customer_Account__c 
                Limit 1];           
        }
    }

    public PageReference performNewNeedsAssesment() {
        return Page.NeedsAssesmentNew;
    }

    public PageReference saveNeedsAssesment() {
        NeedsAnalysis.NeedsAssessmentRecordedBy__c=UserInfo.getUserId();
        NeedsAnalysis.dtffa__AnalysisDate__c=Date.Today();
        update NeedsAnalysis;
        return Page.NeedsAssesmentPersonsAccount;
    }
}