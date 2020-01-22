/**
 * WMK, LLC (c) - 2018 
 *
 * WorkOrderOperationTriggerHandlerTest
 * 
 * Created By:   Alexander Miller
 * Created Date: 10/3/2018 
 *
 * Modified By         Alias       Work Item       Date       Reason
 * -----------------------------------------------------------------
 * Alexander Miller    AMM1        IR-0050863     3/15/2019   Update to handle test class failure due to RS v19.6.2
 */

@isTest(SeeAllData=true)
public class WorkOrderOperationTriggerHandlerTest {

    public static testMethod void testInsertion()
    {
        rstk__rtproc__c process = [SELECT Id FROM rstk__rtproc__c WHERE rstk__rtproc_div__r.Name LIKE '%AK%' LIMIT 1];
        rstk__rtwctr__c workCenter = [SELECT Id FROM rstk__rtwctr__c WHERE rstk__rtwctr_div__r.Name LIKE '%AK%' LIMIT 1];
        rstk__rtlabgrd__c labGrade = [SELECT Id FROM rstk__rtlabgrd__c WHERE rstk__rtlabgrd_div__r.Name LIKE '%AK%' LIMIT 1];
        rstk__wocst__c workOrder = [SELECT Id FROM rstk__wocst__c WHERE rstk__wocst_div__r.Name LIKE '%AK%' LIMIT 1];
        
        // AMM 1
        List<rstk__woordop__c> listOfOperations = ([SELECT Id, rstk__woordop_oper__c FROM rstk__woordop__c WHERE rstk__woordop_ordno__c = :workOrder.Id]);

        Decimal lastOperation = 0.0;
        
        for(rstk__woordop__c tempOp : listOfOperations)
        {
            if(tempOp.rstk__woordop_oper__c > lastOperation)
            {
                lastOperation = tempOp.rstk__woordop_oper__c;
            }
        }

        lastOperation = lastOperation + 1;
        // AMM1

        rstk__woordop__c tempOp = new rstk__woordop__c();
        tempOp.rstk__woordop_ordno__c = workOrder.Id;
        tempOp.rstk__custpage_woordop_optype_pl__c = 'Standard Operation';
        // AMM1
        //tempOp.rstk__woordop_oper__c = 1000;
        tempOp.rstk__woordop_oper__c = lastOperation;
        // AMM1
        tempOp.rstk__woordop_procno__c = process.Id;
        tempOp.rstk__woordop_wctr__c = workCenter.Id;
        tempOp.rstk__woordop_labmachschtype_pl__c = 'Labor Only';
        tempOp.rstk__woordop_runtype_pl__c = 'Per Batch';
        tempOp.rstk__woordop_runlabgrd__c  = labGrade.Id;
        tempOp.rstk__woordop_runhrstd__c = 1;
        
        insert tempOp;
	}
}