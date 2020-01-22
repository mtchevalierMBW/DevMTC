/**
* SalesOrderInvHdrTriggerHandlerTest
*
* Programmer: Alexander Miller
* Date: 11-20-2017
* 
* Modified By         Alias       Work Item       Date       Reason
* -----------------------------------------------------------------
* Alexander Miller    AMM1        IR-0050863     3/15/2019   Update to handle test class failure due to RS v19.6.2
*/
@isTest(SeeAllData=true)
public class SalesOrderInvHdrTriggerHandlerTest {

    public static testMethod void testUpdate()
    {
        Test.startTest();

        // AMM1 
        // rstk__soinv__c tempSoInvoice = ([SELECT Id
        //                                 FROM rstk__soinv__c 
        //                                 WHERE rstk__soinv_transferred__c = true AND 
        //                                  rstk__soinv_acctinvoice__c != null 
        //                                 LIMIT 1]);
        rstk__soinv__c tempSoInvoice = ([SELECT Id,
                                            CreatedDate 
                                        FROM rstk__soinv__c 
                                        WHERE rstk__soinv_transferred__c = true AND 
                                         rstk__soinv_acctinvoice__c != null 
                                        ORDER BY CreatedDate DESC
                                        LIMIT 1]);
        // AMM1

        update tempSoInvoice;
        
        Test.stopTest();
    }

    public static testMethod void testConsutructor()
    {
        Test.StartTest();
        SalesOrderInvoiceHeaderTriggerHandler tempHandler = new SalesOrderInvoiceHeaderTriggerHandler();
        Test.StopTest();
    }

    public static testMethod void testCountyUpdate()
    {
        Test.StartTest();

        rstk__soinv__c tempSoInvoice = ([SELECT Id 
                                        FROM rstk__soinv__c 
                                        WHERE rstk__soinv_transferred__c = false AND 
                                         rstk__soinv_acctinvoice__c != null AND
                                         County__c != null
                                        LIMIT 1]);

        tempSoInvoice.County__c = null;

        update tempSoInvoice;
        
        Test.StopTest();
    }
}