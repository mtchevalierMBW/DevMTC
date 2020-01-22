@isTest(SeeAllData=true)
public class SOCONFIGTriggerHandlerTest {

    public static testMethod void testInsertion()
    {
       	rstk__soline__c line = [SELECT Id FROM rstk__soline__c WHERE rstk__soline_linestatustext__c = 'Planned' AND Origin_Sales_Order_Line__c = null LIMIT 1];
        rstk__icitem__c item = [SELECT Id FROM rstk__icitem__c WHERE rstk__icitem_div__r.Name LIKE '%AK%' LIMIT 1];
        
        rstk__soconfig__c tempConfig = new rstk__soconfig__c();
        tempConfig.rstk__soconfig_soline__c = line.Id;
        tempConfig.rstk__soconfig_icitem__c = item.Id;
        tempConfig.rstk__soconfig_qtyper__c = 1;
        tempConfig.rstk__soconfig_oper__c = 1;
        tempConfig.rstk__soconfig_price__c = 1;

        
        insert tempConfig;
	}

    public static testMethod void testGetProductMasterFromSelection()
    {
        Test.StartTest();
        
        List<rstk__confdcomp__c> listOfComponent = ([SELECT Id, rstk__confdcomp__c.rstk__confdcomp_itemtype__c, rstk__confdcomp__c.rstk__confdcomp_soprod__c FROM rstk__confdcomp__c WHERE rstk__confdcomp_itemtype__c  = 'Product' LIMIT 1]);

        SOCONFIGTriggerHandler tempHandler = new SOCONFIGTriggerHandler();

        tempHandler.getProductMasterFromSelection(listOfComponent);

        Test.StopTest();
    }

    public static testMethod void testGetInventoryAndProductsBrokenDownBySelection()
    {
        Test.StartTest();
        
        List<rstk__confdcomp__c> listOfComponent = ([SELECT Id, rstk__confdcomp__c.rstk__confdcomp_confdsel__c FROM rstk__confdcomp__c WHERE rstk__confdcomp_itemtype__c  = 'Product' LIMIT 1]);

        SOCONFIGTriggerHandler tempHandler = new SOCONFIGTriggerHandler();

        tempHandler.getInventoryAndProductsBrokenDownBySelection(listOfComponent);

        Test.StopTest();
    }
}