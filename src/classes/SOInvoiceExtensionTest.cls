@isTest(SeeAllData=true)
public class SOInvoiceExtensionTest {
    
    public static testMethod void testConstuctor()
    {
        Test.startTest();
        
        rstk__soinv__c temp = ([SELECT Id FROM rstk__soinv__c WHERE rstk__soinv_printed__c = true LIMIT 1]);
        EmailTemplate tempTemplate = ([SELECT Id FROM EmailTemplate WHERE Name LIKE 'SOInvoiceTemplate%' LIMIT 1]);
                
        Test.setCurrentPageReference(new PageReference('Page.SOInvPrint')); 
        System.currentPageReference().getParameters().put('id', temp.Id);
        System.currentPageReference().getParameters().put('t', tempTemplate.Id);
        
        SOInvoiceExtension tempController = new SOInvoiceExtension ();
        
        Test.stopTest();
    }
}