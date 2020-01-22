/**
 * WMK, LLC (c) - 2018 
 *
 * WorkOrderComponentTriggerHandlerTest
 * 
 * Created By:   Alexander Miller
 * Created Date: 10/3/2018 
 *
 * Modified By         Alias       Work Item       Date       Reason
 * -----------------------------------------------------------------
 * Alexander Miller    AMM1        IR-0050863     3/15/2019   Update to handle test class failure due to RS v19.6.2
 * Bryan Leaman			BLL1		n/a				7/9/2019	Test failure in production.
 */
@isTest(SeeAllData=true)
public class WorkOrderComponentTriggerHandlerTest {

    public static testMethod void testInsertion()
    {
        // AMM1
        Test.StartTest();
        // AMM1

        // AMM1
        //rstk__icitem__c item = [SELECT Id FROM rstk__icitem__c WHERE rstk__icitem_div__r.Name LIKE '%AK%' LIMIT 1];
        //rstk__wocst__c workOrder = [SELECT Id FROM rstk__wocst__c WHERE rstk__wocst_div__r.Name LIKE '%AK%' LIMIT 1];
        rstk__icitem__c item = [SELECT Id, CreatedDate FROM rstk__icitem__c WHERE rstk__icitem_div__r.Name LIKE '%AK%' ORDER BY CreatedDate DESC LIMIT 1];
        // BLL1
		//rstk__wocst__c workOrder = [SELECT Id, CreatedDate FROM rstk__wocst__c WHERE rstk__wocst_div__r.Name LIKE '%AK%' ORDER BY CreatedDate DESC LIMIT 1];
		rstk__wocst__c workOrder = null;
		for(rstk__wocst__c wo : [
			SELECT Id, CreatedDate, rstk__wocst_schedpickdte__c, rstk__wocst_schdcompdate__c, rstk__wocst_duedte__c 
			FROM rstk__wocst__c 
			WHERE rstk__wocst_div__r.Name LIKE '%AK%' 
			ORDER BY CreatedDate DESC LIMIT 25
		]) {
			// try to find a valid one
			if (workOrder==null 
				|| workOrder.rstk__wocst_schedpickdte__c > workOrder.rstk__wocst_schdcompdate__c 
			    || workOrder.rstk__wocst_schedpickdte__c > workOrder.rstk__wocst_duedte__c)
				workOrder = wo;
		}
		// BLL1 end
        // AMM1

        rstk__woorddmd__c tempComponent = new rstk__woorddmd__c();
        tempComponent.rstk__woorddmd_ordno__c = workOrder.Id;
        tempComponent.rstk__woorddmd_compitem__c = item.Id;
        tempComponent.rstk__woorddmd_qtyper__c = 1;

        insert tempComponent;

        // AMM1
        Test.StopTest();
        // AMM1
	}
}