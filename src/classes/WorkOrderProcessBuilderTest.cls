/**
* TransitWorks (c) - 2018
*
* Tested By: WorkOrderProcessBuilderTest
* Created Date: 6/29/2018
* Developer: Alexander Miller
*
* Invocable method which closes a work order if the process builder criteria is met
*/
@isTest(SeeAllData=true)
public class WorkOrderProcessBuilderTest {

    public static testMethod void testWoClose()
    {
        rstk__wocst__c tempWorkOrder = [SELECT Id FROM rstk__wocst__c LIMIT 1];
        
        List<Id> listOfId = new List<Id>();
        
        listOfId.add(tempWorkOrder.Id);
        
        WorkOrderProcessBuilder.closeWorkOrders(listOfId);
    }
}