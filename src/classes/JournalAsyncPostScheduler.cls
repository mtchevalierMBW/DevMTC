/*
 * 2016-03-25	RedTeal		RT1 - scheduler to post any missed ROs
 * 
 * 
 * 
*/
global class JournalAsyncPostScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
		Database.executeBatch(new JournalAsyncPostBatch(), 1);
            
	}
    
    public static void startJournalAysncPostScheduler() {
        System.schedule('Scheduled Job 1', '0 0 17 * ?', new JournalAsyncPostScheduler());
    }

    //just wanted to save email method
    public void executeViaEmail() {
        List<dealer__Service_Repair_Order__c> repairOrders = [SELECT Id FROM dealer__Service_Repair_Order__c WHERE dealer__Status__c = 'Posted' AND Journal__c = null];
        
        for(dealer__Service_Repair_Order__c repairOrder : repairOrders) {
            String accountingPayload = '{"recordId" : "'+repairOrder.Id+'", "orgId" : "'+UserInfo.getOrganizationId()+'", "requestedBy" : "'+UserInfo.getUserId()+'", "action" : "service_repair_order_post"}';
            FFAccounting.emailAsyncHandler(accountingPayload);
        }
    }

}