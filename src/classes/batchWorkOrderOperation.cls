/**
* MobilityWorks (c) - 2017
*
* batchTemplate
* Tested by: 
* Date: 
* Programmer: 
*
* Description: 
*/
global class batchWorkOrderOperation implements Database.Batchable<rstk__woordop__c>, Database.Stateful{

    // stateful global variable that will survive execution contexts
    global String foundSales;

    global List<rstk__woordop__c> listOfOps {get;set;}

    public batchWorkOrderOperation (){}

    public batchWorkOrderOperation (List<rstk__woordop__c> tempList)
    {
        listOfOps = tempList;
    }

    global Iterable<rstk__woordop__c> start(Database.BatchableContext BC) 
    {  
        return listOfOps;
    }

    global void execute(Database.BatchableContext BC, List<rstk__woordop__c> listTemp) {
        update listTemp;
    }   
     
    global void finish(Database.BatchableContext BC) {

    }
}