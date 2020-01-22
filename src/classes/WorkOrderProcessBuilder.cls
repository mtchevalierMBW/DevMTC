/**
* TransitWorks (c) - 2018
*
* Tested By: WorkOrderProcessBuilderTest
* Created Date: 6/29/2018
* Developer: Alexander Miller
*
* Invocable method which closes a work order if the process builder criteria is met
*/
public class WorkOrderProcessBuilder {

    @InvocableMethod(label='Close Work Orders' description='Custom interface into RootStock API to close a Work Order')
    public static void closeWorkOrders(List<ID> ids) {
        
        List<rstk__sydata__c> listOfWoClosures = new List<rstk__sydata__c>();
        
        List<rstk__wocst__c> listOfWorkOrders = ([SELECT Id,
                                                  	rstk__wocst_div__c
                                                  FROM rstk__wocst__c 
                                                  WHERE Id IN: ids]);
        
        for(rstk__wocst__c tempWorkOrder : listOfWorkOrders)
        {
            rstk__sydata__c tempSyData = new rstk__sydata__c();
        
            tempSyData.rstk__sydata_txntype__c = 'WO Close';                        // Transaction Type
            tempSyData.rstk__sydata_sourcepgm__c = 'WorkOrderTriggerHandler';       // Source Program
            tempSyData.rstk__sydata_process__c = 'Ready';                           // Process immediately
            tempSyData.rstk__sydata_sydiv__c = tempWorkOrder.rstk__wocst_div__c;    // Division Master
            tempSyData.rstk__sydata_wocst__c = tempWorkOrder.Id;                    // Work Order
            
            listOfWoClosures.add(tempSyData);
		}
        
        insert listOfWoClosures;
    }
}