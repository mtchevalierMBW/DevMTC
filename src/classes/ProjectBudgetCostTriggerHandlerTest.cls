/**
 * WMK, LLC (c) - 2018 
 * 
 * ProjectBudgetCostTriggerHandler
 * 
 * Created By:   Alexander Miller
 * Created Date: 11/22/2018 
 * Tested By:    ProjectBudgetCostTriggerHandlerTest
 * Work Item:    W-000498
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 * Alexander Miller    AMM1        IN00065050    6/17/2019   Fix test class failure
 */
 @isTest(SeeAllData=true)
public class ProjectBudgetCostTriggerHandlerTest {

    public static testMethod void testUpdateProjectPartSaleCost()
    {
        Test.StartTest();

        List<rstk__sytxncst__c> listOfCostTransaction = ([SELECT Id, 
                                                            rstk__sytxncst_proj__c 
                                                        FROM rstk__sytxncst__c 
                                                        WHERE rstk__sytxncst_txnid__c IN ('SOISS', 'SOISSR') AND
                                                              rstk__sytxncst_ordtype__c = '1' AND
                                                              rstk__sytxncst_proj__r.Name IN ('AK Home Project', 'KC Home Project', 'SC Home Project') AND 
                                                              (rstk__sytxncst_proj__r.LastModifiedDate = LAST_N_DAYS:120)
                                                        LIMIT 10]);

        listOfCostTransaction.addAll(([SELECT Id, 
                                            rstk__sytxncst_proj__c 
                                        FROM rstk__sytxncst__c 
                                        WHERE rstk__sytxncst_txnid__c = 'INVLOCADJ' AND
                                            (rstk__sytxncst_proj__r.LastModifiedDate = LAST_N_DAYS:120)
                                        LIMIT 10]));

        List<Id> listOfProjectIds = new List<Id>();

        for(rstk__sytxncst__c tempTransaction : listOfCostTransaction)
        {
            listOfProjectIds.add(tempTransaction.rstk__sytxncst_proj__c);
        }

        List<rstk__pjprojcst__c> listOfProjectBudgets = ([SELECT Id 
                                                        FROM rstk__pjprojcst__c 
                                                        WHERE rstk__pjprojcst_proj__c IN :listOfProjectIds]);

        System.debug(listOfProjectBudgets);

        update listOfProjectBudgets;

        Test.StopTest();
    }

    public static testMethod void testUpdateProjectFreightCost()
    {
        Test.StartTest();
        
        List<rstk__poline__c> listOfTransactions = ([SELECT Id,
                                                        rstk__poline_proj__c           // Project Master
                                                    FROM rstk__poline__c
                                                    WHERE rstk__poline_item__r.rstk__poitem_desc__c LIKE '%Vehicle Ship Charge%' AND
                                                        rstk__poline_ordsts__c IN ('7-Line Item Received', '8-All Line Items Received', '9-Closed')
                                                    LIMIT 10]);

        List<rstk__sohdr__c> listOfSalesOrders = ([SELECT Id,
                                                    rstk__sohdr_proj__c 
                                                FROM rstk__sohdr__c 
                                                WHERE rstk__sohdr_otype__r.Name LIKE '%Part Sale%' AND
                                                    Freight_Cost__c != null
                                                LIMIT 10]);

        List<Id> listOfProjectIds = new List<Id>();

        for(rstk__sohdr__c tempSales : listOfSalesOrders)
        {
            listOfProjectIds.add(tempSales.rstk__sohdr_proj__c);
        }

        for(rstk__poline__c tempPO : listOfTransactions)
        {
            listOfProjectIds.add(tempPO.rstk__poline_proj__c);
        }

        List<rstk__pjprojcst__c> listOfProjectBudgets = ([SELECT Id 
                                                        FROM rstk__pjprojcst__c 
                                                        WHERE rstk__pjprojcst_proj__c IN :listOfProjectIds]);

        System.debug(listOfProjectBudgets);

        update listOfProjectBudgets;

        Test.StopTest();
    }

    public static testMethod void testUpdateProjectFreightSale()
    {
        Test.StartTest();

        // AMM1
        // List<rstk__soinvline__c> listOfInvoiceLines =  ([SELECT Id,
        //                                                     rstk__soinvline_project__c                           
        //                                                 FROM rstk__soinvline__c
        //                                                 WHERE (Product_Name__c LIKE '%VEHICLE SHIP CHARGE%' OR
        //                                                     Product_Name__c LIKE '%Part Ship Charge%' OR
        //                                                     Product_Name__c LIKE '%Sales Tax%' OR 
        //                                                     Product_Name__c LIKE '%Inter-company%') AND
        //                                                     rstk__soinvline_invoice__r.rstk__soinv_transferred__c = true]);
        List<rstk__soinvline__c> listOfInvoiceLines = new List<rstk__soinvline__c>();
        // AMM1

        listOfInvoiceLines.addAll(([SELECT Id,
                                        rstk__soinvline_project__c                           
                                    FROM rstk__soinvline__c
                                    WHERE Product_Name__c LIKE '%VEHICLE SHIP CHARGE%' AND 
                                        rstk__soinvline_invoice__r.rstk__soinv_transferred__c = true 
                                    LIMIT 5]));

        listOfInvoiceLines.addAll(([SELECT Id,
                                        rstk__soinvline_project__c                           
                                    FROM rstk__soinvline__c
                                    WHERE Product_Name__c LIKE '%Part Ship Charge%' AND 
                                        rstk__soinvline_invoice__r.rstk__soinv_transferred__c = true 
                                    LIMIT 5]));
        
        listOfInvoiceLines.addAll(([SELECT Id,
                                        rstk__soinvline_project__c                           
                                    FROM rstk__soinvline__c
                                    WHERE Product_Name__c LIKE '%Sales Tax%'  AND 
                                        rstk__soinvline_invoice__r.rstk__soinv_transferred__c = true 
                                    LIMIT 5]));

        listOfInvoiceLines.addAll(([SELECT Id,
                                        rstk__soinvline_project__c                           
                                    FROM rstk__soinvline__c
                                    WHERE Product_Name__c LIKE '%Inter-company%' AND 
                                        rstk__soinvline_invoice__r.rstk__soinv_transferred__c = true 
                                    LIMIT 5]));

        List<Id> listOfProjectIds = new List<Id>();

        for(rstk__soinvline__c tempInvoice : listOfInvoiceLines)
        {
            listOfProjectIds.add(tempInvoice.rstk__soinvline_project__c);
        }

        List<rstk__pjprojcst__c> listOfProjectBudgets = ([SELECT Id 
                                                        FROM rstk__pjprojcst__c 
                                                        WHERE rstk__pjprojcst_proj__c IN :listOfProjectIds]);

        System.debug(listOfProjectBudgets);

        update listOfProjectBudgets;

        Test.StopTest();
    }
}