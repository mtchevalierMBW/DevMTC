/**
* TransitWorks (c) - 2018
*
* TWPOAutoCloseTest
*
* Programmer: Alexander Miller
* Date: 2018-07-17
*/
@isTest(SeeAllData = true)
public class TWPOAutoCloseTest {

    public static TestMethod void testClosePOs()
    {
        rstk__pohdr__c tempOrder = [SELECT Id
                                        FROM rstk__pohdr__c 
                                        WHERE rstk__pohdr_linesnot8__c = 0
                                        LIMIT 1];

        List<Id> listOfOrderIds = new List<Id>();
        listOfOrderIds.add(tempOrder.Id);

        Test.StartTest();

        // Run the logic
        TWPOAutoClose.closePOs(listOfOrderIds);

        Test.StopTest();
    }
}