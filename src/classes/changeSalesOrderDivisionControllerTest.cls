/**
* changeSalesOrderDivisionControllerTest
*
* MobilityWorks (c) - 2018
*
* Developer: Alexander Miller
* Date 11/15/2017
*
*/
@isTest(SeeAllData = true) 
public class changeSalesOrderDivisionControllerTest {

    public static testMethod void constructor()
    {
        Test.StartTest();
        changeSalesOrderDivisionController tempController = new changeSalesOrderDivisionController();
        Test.StopTest();
    }
}