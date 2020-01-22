/**
 * SalesOrderLinTriggerHandlerTest
 * Date: August 18th, 2018
 * Programmer: Alexander Miller
 * 
 * Modified By         Alias       Work Item       Date       Reason
 * -----------------------------------------------------------------
 * Alexander Miller    AMM1        IR-0050863     3/15/2019   Update to handle test class failure due to RS v19.6.2
 */
@isTest(SeeAllData=true)
public class SalesOrderLinTriggerHandlerTest {

    public static testMethod void testConstructor(){
        
        Test.startTest();
        
        SalesOrderLinTriggerHandler temphandler = new SalesOrderLinTriggerHandler();

        SalesOrderLinTriggerHandler temphandler2 = new SalesOrderLinTriggerHandler(new List<rstk__soline__c>(), new List<rstk__soline__c>(), new Map<Id, rstk__soline__c>(), new Map<Id, rstk__soline__c>());
     
        System.assertNotEquals(null, temphandler.newList);
        System.assertNotEquals(null, temphandler.oldList);
        System.assertNotEquals(null, temphandler.newMap);
        System.assertNotEquals(null, temphandler.oldMap);

        Test.stopTest();
    }

    public static testMethod void testRefreshAllFieldsNeeded(){
        
        Test.startTest();

        SalesOrderLinTriggerHandler temphandler = new SalesOrderLinTriggerHandler();
     
        System.assertNotEquals(null, temphandler.refreshAllFieldsNeeded(([SELECT Id FROM rstk__soline__c LIMIT 1]))); 

        Test.stopTest();
    }

    public static testMethod void testSalesOrderLineProductNamePasting(){
        
        Test.startTest();

        SalesOrderLinTriggerHandler temphandler = new SalesOrderLinTriggerHandler();

        // Grab a list of lines to test with
        List<rstk__soline__c> listOfLines = ([SELECT Id, 
                                                Product_Name__c, 
                                                rstk__soline_prod__c,
                                                rstk__soline_prod__r.Name
                                            FROM rstk__soline__c
                                            WHERE rstk__soline_prod__c != null
                                            LIMIT 1]);

        // ensure the custom product name is cleared out
        for(rstk__soline__c tempLine : listOfLines)
        {
            tempLine.Product_Name__c = null;
        }

        System.debug(listOfLines);

        update listOfLines;

        Test.stopTest();
    }

    public static testMethod void testSalesOrderLineConfigurationSessionNamePasting(){
        
        Test.startTest();

        SalesOrderLinTriggerHandler temphandler = new SalesOrderLinTriggerHandler();

        // Grab a list of lines to test with
        List<rstk__soline__c> listOfLines = new List<rstk__soline__c>();

        listOfLines.addAll(([SELECT Id, 
                                Configuration_Session_Name__c, 
                                rstk__soline_confsess__c,
                                Origin_Sales_Order_Line__c,
                                Origin_Sales_Order_Line__r.rstk__soline_confsess__c
                            FROM rstk__soline__c
                            WHERE Origin_Sales_Order_Line__c != null
                            LIMIT 1]));
                                            
        listOfLines.addAll(([SELECT Id, 
                                Configuration_Session_Name__c, 
                                rstk__soline_confsess__c,
                                Origin_Sales_Order_Line__c,
                                Origin_Sales_Order_Line__r.rstk__soline_confsess__c
                            FROM rstk__soline__c
                            WHERE rstk__soline_confsess__c != null
                            LIMIT 1]));     

        // ensure the custom product name is cleared out
        for(rstk__soline__c tempLine : listOfLines)
        {
            tempLine.Configuration_Session_Name__c = null;
        }

        System.debug(listOfLines);

        update listOfLines;

        Test.stopTest();
    }

    public static testMethod void testSalesOrderLineCopyDim1ToHeader(){
        
        Test.startTest();

        SalesOrderLinTriggerHandler temphandler = new SalesOrderLinTriggerHandler();

        // Grab a list of lines to test with
        // AMM1
        // List<rstk__soline__c> listOfLines = ([SELECT Id, 
        //                                         rstk__formula_dimval1__c,
        //                                         rstk__soline_sohdr__c,
        //                                         rstk__soline_sohdr__r.Dimension__c
        //                                     FROM rstk__soline__c
        //                                     WHERE rstk__formula_dimval1__c != null
        //                                     LIMIT 1]);
        List<rstk__soline__c> listOfLines = ([SELECT Id, 
                                                rstk__formula_dimval1__c,
                                                rstk__soline_sohdr__c,
                                                rstk__soline_sohdr__r.Dimension__c,
                                                CreatedDate
                                            FROM rstk__soline__c
                                            WHERE rstk__formula_dimval1__c != null
                                            ORDER BY CreatedDate DESC
                                            LIMIT 1]);
        // AMM1

        // Update the header    
        List<rstk__sohdr__c> tempHeaderList = new List<rstk__sohdr__c>();

        for(rstk__soline__c tempLine : listOfLines)
        {
            tempHeaderList.add(new rstk__sohdr__c(Id = tempLine.rstk__soline_sohdr__c, Dimension__c = null));
        }

        update tempHeaderList;

        update listOfLines;

        Test.stopTest();
    }
}