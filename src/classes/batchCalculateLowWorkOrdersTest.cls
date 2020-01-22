/*
* batchClassTest
* Date: 10/18/2017
* Programmer: Alexander Miller
*
* Testing: batchCalculateLowWorkOrders
*/
@isTest(SeeAllData=true)
public class batchCalculateLowWorkOrdersTest {

    //public static testMethod void testScheduler(){
    //    Test.startTest();
    //    batchCalculateLowWorkOrders sh1 = new batchCalculateLowWorkOrders();
    //    String sch = '0 0 23 * * ?'; 
    //    system.schedule('batchCalculateLowWorkOrders', sch, sh1);
    //    Test.stopTest();
    //}
    
    public static testMethod void testBatch(){
        Test.startTest();
        batchCalculateLowWorkOrders sh1 = new batchCalculateLowWorkOrders();
        database.executeBatch(sh1, 1);
        Test.stopTest();
    }
}