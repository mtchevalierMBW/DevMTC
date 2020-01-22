global class batchCleanseWorkOrderLineUpdate implements Database.Batchable<rstk__woorddmd__c>, Database.Stateful{

    global List<rstk__woorddmd__c> listOfComponents;

    public batchCleanseWorkOrderLineUpdate(){}

    public batchCleanseWorkOrderLineUpdate(List<rstk__woorddmd__c> listToUpdate)
    {
        this.listOfComponents = listToUpdate;
    }

    global Iterable<rstk__woorddmd__c> start(Database.BatchableContext BC) {  
        return listOfComponents;
    }

    global void execute(Database.BatchableContext BC, List<sObject> listTemp) 
    {
        update listTemp.get(0);
    }
     
    global void finish(Database.BatchableContext BC) {}
}