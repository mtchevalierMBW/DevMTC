/**
 * SalesOrderInvoiceLineTriggerHandlerTest
 * Date: August 18th, 2018
 * Programmer: Alexander Miller
 */
@isTest(SeeAllData=true)
public class SalesOrderInvoiceLineTriggerHandlerTest {

    public static testMethod void testConstructor(){
        
        Test.startTest();
        
        SalesOrderInvoiceLineTriggerHandler temphandler = new SalesOrderInvoiceLineTriggerHandler();

        SalesOrderInvoiceLineTriggerHandler temphandler2 = new SalesOrderInvoiceLineTriggerHandler(new List<rstk__soinvline__c>(), new List<rstk__soinvline__c>(), new Map<Id, rstk__soinvline__c>(), new Map<Id, rstk__soinvline__c>());
     
        System.assertNotEquals(null, temphandler.newList);
        System.assertNotEquals(null, temphandler.oldList);
        System.assertNotEquals(null, temphandler.newMap);
        System.assertNotEquals(null, temphandler.oldMap);

        Test.stopTest();
    }

    public static testMethod void testRefreshAllFieldsNeeded(){
        
        Test.startTest();

        SalesOrderInvoiceLineTriggerHandler temphandler = new SalesOrderInvoiceLineTriggerHandler();
     
        System.assertNotEquals(null, temphandler.refreshAllFieldsNeeded(([SELECT Id FROM rstk__soinvline__c LIMIT 1]))); 

        Test.stopTest();
    }

    public static testMethod void testSalesOrderLineProductNamePasting(){
        
        Test.startTest();

        SalesOrderInvoiceLineTriggerHandler temphandler = new SalesOrderInvoiceLineTriggerHandler();

        // Grab a list of lines to test with
        List<rstk__soinvline__c> listOfLines = ([SELECT Id, 
                                                Product_Name__c, 
                                                rstk__soinvline_prod__c,
                                                rstk__soinvline_prod__r.Name
                                            FROM rstk__soinvline__c
                                            WHERE rstk__soinvline_prod__c != null
                                            LIMIT 1]);

        // ensure the custom product name is cleared out
        for(rstk__soinvline__c tempLine : listOfLines)
        {
            tempLine.Product_Name__c = null;
        }

        System.debug(listOfLines);

        update listOfLines;

        Test.stopTest();
    }
}