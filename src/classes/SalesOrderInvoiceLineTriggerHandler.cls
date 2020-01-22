/**
 * SalesOrderInvoiceLineTriggerHandler
 * Tested by: SalesOrderInvoiceLineTriggerHandlerTest
 * Date: August 18th, 2018
 * Programmer: Alexander Miller
 */
public class SalesOrderInvoiceLineTriggerHandler {

    public List<rstk__soinvline__c > newList = new List<rstk__soinvline__c >();
    public List<rstk__soinvline__c > oldList = new List<rstk__soinvline__c >();
    public Map<Id, rstk__soinvline__c> newMap = new Map<Id, rstk__soinvline__c >();
    public Map<Id, rstk__soinvline__c > oldMap = new Map<Id, rstk__soinvline__c >();

    public SalesOrderInvoiceLineTriggerHandler(){}

    public SalesOrderInvoiceLineTriggerHandler(rstk__soinvline__c [] newArray, rstk__soinvline__c [] oldArray, Map<Id, rstk__soinvline__c > newHashMap, Map<Id, rstk__soinvline__c > oldHashMap){
        newList = newArray;
        oldList = oldArray;
        newMap = newHashMap;
        oldMap = oldHashMap;
    }

    /**
    * refreshAllFieldsNeeded
    *
    * function which grabs every connected field possible at the very
    * beginning so minimal SOQL queries are used since RootStock
    * has recursive trigger logic built in. 
    */
    public List<rstk__soinvline__c> refreshAllFieldsNeeded(List<rstk__soinvline__c> newList)
    {
        return ([SELECT Id,
                    rstk__soinvline_prod__c,
                    rstk__soinvline_prod__r.Name,
                    Product_Name__c
                FROM rstk__soinvline__c
                WHERE Id IN :newList]);
    }

    /**
    * updateAllMaps
    *
    * function which is called at the end of each after trigger and 
    * updates all of the maps used in the entire process at once.
    * This is to help prevent multiple DMLs/Triggers on the same 
    * object as much as possible in a manageable way.
    */
    //public void updateAllMaps(){}

    /**
    * salesOrderLineProductNamePasting
    *
    * Function which pastes the Product Name of the line
    * to the custom Product name field for reporting purposes.
    *
    * This should be done in a before context to help prevent collision
    * with RootStock trigger processes.
    *
    * @param newList - List of before context lines being evaluated
    */
    public void salesOrderInvoiceLineProductNamePasting(List<rstk__soinvline__c> newList)
    {
        for(rstk__soinvline__c tempLine : newList)
        {
            if(tempLine.Product_Name__c != tempLine.Product_Name_Formula__c)
            {
                tempLine.Product_Name__c = tempLine.Product_Name_Formula__c;
            }
        }
    }
}