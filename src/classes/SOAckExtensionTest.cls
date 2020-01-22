@isTest(SeeAllData=true)
public class SOAckExtensionTest {
    
    public static testMethod void testConstuctor()
    {
        Test.startTest();
        
        rstk__sohdr__c temp = ([SELECT Id FROM rstk__sohdr__c WHERE Id IN 
                                	(SELECT rstk__soline_sohdr__c
                                	FROM rstk__soline__c
                            		WHERE rstk__soline_prod__r.Name LIKE '%Discount%') 
                                LIMIT 1]);
        EmailTemplate tempTemplate = ([SELECT Id FROM EmailTemplate WHERE Name LIKE 'Sales Order Acknowledgement (WMATA)%' LIMIT 1]);
                
        Test.setCurrentPageReference(new PageReference('Page.SOAckPrint')); 
        System.currentPageReference().getParameters().put('id', temp.Id);
        System.currentPageReference().getParameters().put('t', tempTemplate.Id);
        
        SOAckExtension tempController = new SOAckExtension();
        
        Test.stopTest();
    }
}