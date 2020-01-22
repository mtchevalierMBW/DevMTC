/**
 * SalesOrderHdrTriggerTest
 * Date: Nov 11, 2017
 * Programmer: Alexander Miller
 * Modified By         Alias       Work Item       Date         Reason
 * ---------------------------------------------------------------------
 *  2018-06-11  B. Leaman  BLL1a - new validation required field on opportunity.
 *  2018-06-13  A. Miller  AMILLER1 - Updated to cover whole class
 *  2018-09-24  A. Miller  W-00361 - AMILLER2 - Update to handle custom Opportunities 
 *  Alexander Miller (AMM3) 11.1.2018  - W-000464 - Update to handle Opportunity Allocation check
 *  Alexander Miller    AMM4        IR-0050229      3.6.2019     Test class failure due to related updates
 *  2019-10-16	B. Leaman	BLL2 - test failures due to "Scheduled Pick Date cannot be later than Scheduled Completion Date" error. 
 * 							testCheckIfChassisAllocationIsLegal & testCheckIfChassisIsUsedInAnotherOrder
 */
@isTest(SeeAllData=true)
public class SalesOrderHdrTriggerTest {

    public static testMethod void testConstructor(){
        
        Test.startTest();
        
        SalesOrderHdrTriggerHandler temphandler = new SalesOrderHdrTriggerHandler();

        SalesOrderHdrTriggerHandler temphandler2 = new SalesOrderHdrTriggerHandler(new List<rstk__sohdr__c>(), new List<rstk__sohdr__c>(), new Map<Id, rstk__sohdr__c>(), new Map<Id, rstk__sohdr__c>());
     
        System.assertNotEquals(null, temphandler.newList);
        System.assertNotEquals(null, temphandler.oldList);
        System.assertNotEquals(null, temphandler.newMap);
        System.assertNotEquals(null, temphandler.oldMap);

        Test.stopTest();
    }

    public static testMethod  void testRunOnce()
    {
        Test.startTest();

        SalesOrderHdrTriggerHandler temphandler = new SalesOrderHdrTriggerHandler();

        System.assertEquals(true, SalesOrderHdrTriggerHandler.runOnce());

        System.assertEquals(false, SalesOrderHdrTriggerHandler.runOnce());
     
        Test.stopTest();
    }

    public static testMethod void testRefreshAllFieldsNeeded()
    {
        Test.startTest();
        
        Map<Id, rstk__sohdr__c> tempMap = new Map<Id, rstk__sohdr__c>([SELECT Id, Chassis__c FROM rstk__sohdr__c WHERE rstk__sohdr_div__c = :RootStockDataFactory.getDivisionMaster('AK').Id LIMIT 1]);

        SalesOrderHdrTriggerHandler temphandler = new SalesOrderHdrTriggerHandler();
        temphandler.newMap = tempMap;
        temphandler.refreshAllFieldsNeeded();

        System.assertNotEquals(null, SalesOrderHdrTriggerHandler.refreshedNewList);
     
        Test.stopTest();
    }

    public static testMethod void testUpdateAllMaps()
    {
        Test.startTest();

        SalesOrderHdrTriggerHandler temphandler = new SalesOrderHdrTriggerHandler();
        temphandler.updateAllMaps();
     
        Test.stopTest();
    }

    public static testMethod void testUpdateSalesRep()
    {
        Test.startTest();

        // User
        User usr = RootStockDataFactory.createSalesUser();
        // AMM4
        //insert usr;
        // AMM4

        // Customer Master 
        rstk__socust__c tempCustomer = [SELECT Id, 
                                            rstk__socust_sf_account__c 
                                        FROM rstk__socust__c 
                                        WHERE rstk__socust_sf_account__c != null 
                                        LIMIT 1];

        // Opportunity
        Opportunity tempOpp = RootStockDataFactory.createOpportunity('temp opp', 'Pending', 'MBW', System.Today(), usr.Id);
        tempOpp.AccountId = tempCustomer.rstk__socust_sf_account__c;
        System.debug(tempOpp);
        insert tempOpp; 

        // Sales Order Header
        rstk__sydiv__c tempDivision = RootStockDataFactory.getDivisionMaster('AK');
        rstk__syusr__c tempUser = RootStockDataFactory.getManufacturingUser(tempDivision.Id);
        rstk__soprod__c tempProduct = ([SELECT Id FROM rstk__soprod__c WHERE rstk__soprod_div__c = :tempDivision.Id LIMIT 1]);

        rstk__soapi__c testSO = RootStockDataFactory.createSOAPISalesOrderHeader(tempUser.Id, tempDivision.Id, tempCustomer.Id, tempProduct.Id);
        insert testSO;

        // Make sure it went through and the Sales Rep was assigned
        rstk__sohdr__c tempOrder = [SELECT Id,
                                    rstk__sohdr_custno__c,
                                    Sales_Rep__c
                                    FROM rstk__sohdr__c 
                                    ORDER BY CreatedDate DESC
                                    LIMIT 1];

        tempOrder.Opportunity__c = tempOpp.Id;
        update tempOrder;

        tempOrder = [SELECT Id,
                        Sales_Rep__c
                    FROM rstk__sohdr__c 
                    WHERE Id = :tempOrder.Id
                    LIMIT 1];
    
        Test.stopTest();
    }
    
    // public static testMethod void testUpdateRelatedWorkOrderIfChassisChanged()
    // {
    //     Test.startTest();

    //     List<rstk__wocst__c> listOfWorkOrdersConnectedToSales = ([SELECT Id, 
    //                                                                 rstk__wocst_soline__r.rstk__soline_sohdr__c 
    //                                                             FROM rstk__wocst__c 
    //                                                             WHERE rstk__wocst_div__c = :RootStockDataFactory.getDivisionMaster('AK').Id]);
    //     List<Id> listOfIds = new List<Id>();

    //     for(rstk__wocst__c tempWorkOrder : listOfWorkOrdersConnectedToSales)
    //     {
    //         listOfIds.add(tempWorkOrder.rstk__wocst_soline__r.rstk__soline_sohdr__c);
    //     }

    //     Map<Id, rstk__sohdr__c> tempMap = new Map<Id, rstk__sohdr__c>([SELECT Id, 
    //                                                                     Chassis__c 
    //                                                                 FROM rstk__sohdr__c 
    //                                                                 WHERE rstk__sohdr_cancelled__c = false AND
    //                                                                     rstk__sohdr_div__c = :RootStockDataFactory.getDivisionMaster('AK').Id AND 
    //                                                                     Id IN :listOfIds AND
    //                                                                     Chassis__r.Opportunity_Allocation__c != null
    //                                                                 LIMIT 1]);
        
    //     Chassis_Master__c tempChassis = RootStockDataFactory.createChassisMaster('2018', 
    //                                                 'Toyota', 
    //                                                 RootStockDataFactory.generateRandomString(17), 
    //                                                 RootStockDataFactory.generateRandomString(6), 
    //                                                 RootStockDataFactory.getDivisionMaster('AK').Id);
        
    //    	tempChassis.Status__c = 'In Production';
       
    //     insert tempChassis;
        
    //     for(Id tempSaleId : tempMap.KeySet())
    //     {
    //        tempMap.get(tempSaleId).Chassis__c = tempChassis.Id;
    //     }
        
    //     update tempMap.values();

    //     System.assertNotEquals(0, SalesOrderHdrTriggerHandler.workOrderMap.size());
     
    //     Test.stopTest();
    // }

    public static testMethod void testupdateChassisTotalShipSale()
    {
        Test.startTest();

        rstk__soline__c tempLine = ([SELECT Id,
                                        rstk__searchindex__c,
                                        rstk__soline_sohdr__c,
                                        rstk__soline_sohdr__r.Chassis__c
                                    FROM rstk__soline__c 
                                    WHERE rstk__searchindex__c LIKE '%Vehicle Ship%' AND
                                        rstk__soline_price__c > 0 AND
                                        rstk__soline_sohdr__r.Chassis__c != null
                                    LIMIT 1]);

        Chassis_Master__c tempChassis = new Chassis_Master__c(Id=tempLine.rstk__soline_sohdr__r.Chassis__c, Outbound_Ship_Sale__c = 0);
        update tempChassis;

        tempChassis = ([SELECT Id,
                            Outbound_Ship_Sale__c
                        FROM Chassis_Master__c
                        WHERE Id = :tempLine.rstk__soline_sohdr__r.Chassis__c
                        LIMIT 1]);

        System.debug(tempChassis);

        SalesOrderHdrTriggerHandler tempHandler = new SalesOrderHdrTriggerHandler();

        tempHandler.newMap.put(tempLine.rstk__soline_sohdr__c, new rstk__sohdr__c(Id=tempLine.rstk__soline_sohdr__c));

        tempHandler.refreshAllFieldsNeeded();

        tempHandler.updateChassisTotalShipSale();

        tempHandler.updateAllMaps();

        tempChassis = ([SELECT Id,
                            Outbound_Ship_Sale__c
                        FROM Chassis_Master__c
                        WHERE Id = :tempLine.rstk__soline_sohdr__r.Chassis__c
                        LIMIT 1]);

        System.assertNotEquals(0, tempChassis.Outbound_Ship_Sale__c);

        Test.stopTest();
    }

    public static testMethod void testUpdateRelatedOpportunityTotalSoPriceNativeOpp()
    {
        Test.startTest();

        rstk__sohdr__c tempSalesOrder = ([SELECT Id,
                                            rstk__sohdr_opportunity__c
                                        FROM rstk__sohdr__c 
                                        WHERE rstk__sohdr_opportunity__c != null AND
                                            Intercompany_Excluded_Price__c > 0 AND
                                            rstk__sohdr_cancelled__c = false
                                        LIMIT 1]);

        Opportunity tempOpp = new Opportunity(Id=tempSalesOrder.rstk__sohdr_opportunity__c, Sales_Order_Total_Price__c = 0);
        update tempOpp;

        SalesOrderHdrTriggerHandler tempHandler = new SalesOrderHdrTriggerHandler();

        tempHandler.newMap.put(tempSalesOrder.Id, new rstk__sohdr__c(Id=tempSalesOrder.Id));

        tempHandler.refreshAllFieldsNeeded();

        tempHandler.updateRelatedOpportunityTotalSoPrice();

        tempHandler.updateAllMaps();

        tempOpp = ([SELECT Id,
                        Sales_Order_Total_Price__c
                    FROM Opportunity 
                    WHERE Id = :tempOpp.Id 
                    LIMIT 1]);

        Test.stopTest();
    }

    public static testMethod void testUpdateRelatedOpportunityTotalSoPriceCustomOpp()
    {
        Test.startTest();

        rstk__sohdr__c tempSalesOrder = ([SELECT Id,
                                            Opportunity__c
                                        FROM rstk__sohdr__c 
                                        WHERE Opportunity__c != null AND
                                            Intercompany_Excluded_Price__c > 0 AND
                                            rstk__sohdr_cancelled__c = false
                                        LIMIT 1]);

        Opportunity tempOpp = new Opportunity(Id=tempSalesOrder.Opportunity__c, Sales_Order_Total_Price__c = 0);
        update tempOpp;

        SalesOrderHdrTriggerHandler tempHandler = new SalesOrderHdrTriggerHandler();

        tempHandler.newMap.put(tempSalesOrder.Id, new rstk__sohdr__c(Id=tempSalesOrder.Id));

        tempHandler.refreshAllFieldsNeeded();

        tempHandler.updateRelatedOpportunityTotalSoPrice();

        tempHandler.updateAllMaps();

        tempOpp = ([SELECT Id,
                        Sales_Order_Total_Price__c
                    FROM Opportunity 
                    WHERE Id = :tempOpp.Id 
                    LIMIT 1]);
        
        Test.stopTest();
    }

    // AMILLER2
    public static testMethod void testUpdateCustomOpportunityLink()
    {
        Test.startTest();

        rstk__sohdr__c tempSalesOrder = ([SELECT Id,
                                            Opportunity__c
                                        FROM rstk__sohdr__c 
                                        WHERE Opportunity__c != null AND
                                            Intercompany_Excluded_Price__c > 0 AND
                                            rstk__sohdr_cancelled__c = false
                                        LIMIT 1]);

        // TODO update with custom opp insert to cover the new code

        Opportunity tempOpp = new Opportunity(Id=tempSalesOrder.Opportunity__c, Sales_Order_Total_Price__c = 0);
        update tempOpp;

        SalesOrderHdrTriggerHandler tempHandler = new SalesOrderHdrTriggerHandler();

        tempHandler.newMap.put(tempSalesOrder.Id, new rstk__sohdr__c(Id=tempSalesOrder.Id));

        tempHandler.refreshAllFieldsNeeded();

        tempHandler.updateRelatedOpportunityTotalSoPrice();

        tempHandler.updateAllMaps();

        tempOpp = ([SELECT Id,
                        Sales_Order_Total_Price__c
                    FROM Opportunity 
                    WHERE Id = :tempOpp.Id 
                    LIMIT 1]);
        
        Test.stopTest();
    }
    // AMILLER2

    // AMM3
    public static testMethod void testCheckIfChassisAllocationIsLegal()
    {
        Test.startTest();

        // BLL2
        //rstk__sohdr__c tempSalesOrder = ([SELECT Id,
        //                                    Opportunity_custom__c
        //                                FROM rstk__sohdr__c 
        //                                WHERE Opportunity_custom__c != null AND
        //                                    rstk__sohdr_cancelled__c = false AND
        //                                    Chassis__c != null
        //                                LIMIT 1]);
        // Look for sales order headers that don't reference invalid wocst records
        Set<Id> sohdrIds = new Set<Id>();
        for(rstk__wocst__c wocst : [
            select Id, rstk__wocst_soline__c, rstk__wocst_soline__r.rstk__soline_sohdr__c,
            rstk__wocst_schedpickdte__c, rstk__wocst_schdcompdate__c
            from rstk__wocst__c
			where rstk__wocst_soline__c!=null
            order by rstk__wocst_schedpickdte__c desc
            limit 200
        ]) {
            if (wocst.rstk__wocst_soline__c!=null 
                && wocst.rstk__wocst_schedpickdte__c < wocst.rstk__wocst_schdcompdate__c) {
                sohdrIds.add(wocst.rstk__wocst_soline__r.rstk__soline_sohdr__c);
            }
        }
        List<rstk__sohdr__c> slsorders = [
            select Id, Opportunity_custom__c
            from rstk__sohdr__c
            where Opportunity_custom__c!=null 
              and rstk__sohdr_cancelled__c=false 
              and Chassis__c!=null
              and Id in :sohdrIds
            limit 1
        ];
		rstk__sohdr__c tempSalesOrder = slsorders.size()>0 ? slsorders[0] : null;
        // BLL2 end

        tempSalesOrder.Chassis__c = null;
        update tempSalesOrder;

        Opportunity__c tempOpp = new Opportunity__c(Id=tempSalesOrder.Opportunity_custom__c);

        String VIN = RootStockDataFactory.generateRandomString(17);

        Chassis_Master__c tempChassis = RootStockDataFactory.createChassisMaster('2017', 'Ford', VIN, VIN.substring(0,6), RootStockDataFactory.getDivisionMaster('AK').Id);
        tempChassis.Opportunity_Allocation__c = tempOpp.Id;
        insert tempChassis;

        tempSalesOrder.Chassis__c = tempChassis.Id;
        update tempSalesOrder;
        
        Test.stopTest();
    }

    public static testMethod void testCheckIfChassisIsUsedInAnotherOrder()
    {
        Test.startTest();

        // BLL2
        //rstk__sohdr__c tempSalesOrder = ([SELECT Id,
        //                                    Opportunity_custom__c
        //                                FROM rstk__sohdr__c 
        //                                WHERE Opportunity_custom__c != null AND
        //                                    rstk__sohdr_cancelled__c = false AND
        //                                    Chassis__c != null
        //                                LIMIT 1]);
        // Try up to 50 sales order headers to find one that is valid to test with
        // Look for sales order headers that don't reference invalid wocst records
        Set<Id> sohdrIds = new Set<Id>();
        for(rstk__wocst__c wocst : [
            select Id, rstk__wocst_soline__c, rstk__wocst_soline__r.rstk__soline_sohdr__c,
            rstk__wocst_schedpickdte__c, rstk__wocst_schdcompdate__c
            from rstk__wocst__c
			where rstk__wocst_soline__c!=null
            order by rstk__wocst_schedpickdte__c desc
            limit 200
        ]) {
            if (wocst.rstk__wocst_soline__c!=null 
                && wocst.rstk__wocst_schedpickdte__c < wocst.rstk__wocst_schdcompdate__c) {
                sohdrIds.add(wocst.rstk__wocst_soline__r.rstk__soline_sohdr__c);
            }
        }
        List<rstk__sohdr__c> slsorders = [
            select Id, Opportunity_custom__c
            from rstk__sohdr__c
            where Opportunity_custom__c!=null 
              and rstk__sohdr_cancelled__c=false 
              and Chassis__c!=null
              and Id in :sohdrIds
            limit 1
        ];
		rstk__sohdr__c tempSalesOrder = slsorders.size()>0 ? slsorders[0] : null;
		// BLL2
		
        tempSalesOrder.Chassis__c = null;
        update tempSalesOrder;

        Opportunity__c tempOpp = new Opportunity__c(Id=tempSalesOrder.Opportunity_custom__c);

        String VIN = RootStockDataFactory.generateRandomString(17);

        Chassis_Master__c tempChassis = RootStockDataFactory.createChassisMaster('2017', 'Ford', VIN, VIN.substring(0,6), RootStockDataFactory.getDivisionMaster('AK').Id);
        tempChassis.Opportunity_Allocation__c = tempOpp.Id;
        insert tempChassis;

        tempSalesOrder.Chassis__c = tempChassis.Id;
        update tempSalesOrder;

        rstk__sohdr__c tempSalesOrder2 = ([SELECT Id,
                                            Opportunity_custom__c
                                        FROM rstk__sohdr__c 
                                        WHERE Opportunity_custom__c != null AND
                                            rstk__sohdr_cancelled__c = false AND
                                            Chassis__c != null AND Id != :tempSalesOrder.Id
                                        LIMIT 1]);
        
        tempSalesOrder2.Opportunity_custom__c = tempOpp.Id;
        update tempSalesOrder2;

        VIN = RootStockDataFactory.generateRandomString(17);

        Chassis_Master__c tempChassis2 = RootStockDataFactory.createChassisMaster('2017', 'Ford', VIN, VIN.substring(0,6), RootStockDataFactory.getDivisionMaster('AK').Id);
        tempChassis2.Opportunity_Allocation__c = tempOpp.Id;
        insert tempChassis2;

        tempSalesOrder2.Chassis__c = tempChassis2.Id;

        try{
            update tempSalesOrder2;
        } catch(Exception e)
        {
            Boolean expectedExceptionThrown =  e.getMessage().contains('assigned to multiple Sales Orders') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        
        Test.stopTest();
    }

    public static testMethod void testUpdateCustomOpportunityLink2()
    {
        Test.startTest();

        List<rstk__sohdr__c> listOfSalesOrders = ([SELECT Id
                                                    FROM rstk__sohdr__c 
                                                    WHERE rstk__sohdr_opportunity__c != null
                                                    LIMIT 2]);

        for(rstk__sohdr__c tempSale : listOfSalesOrders)
        {
            tempSale.Opportunity_custom__c = null;
        }

        List<rstk__sohdr__c> listOfSalesOrdersUpdate = new List<rstk__sohdr__c>();

        listOfSalesOrdersUpdate.addAll(listOfSalesOrders);

        update listOfSalesOrdersUpdate;
       
        Test.stopTest();
    } 
    // AMM3
}