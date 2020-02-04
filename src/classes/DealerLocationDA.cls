/**
* DealerLocationDA
* Tested by: DealerLocationDA_TEST
* Date: Jan 28, 2020
* Programmer: Matthew Chevalier
*
* Code Coverage:
*   2020-01-28  86% (23/26)
*
*   2020-01-28  M. Chevalier W-000813 MTC1 - Ported DealerLocation queries out of LocationsSingleton into this class
*/
public with sharing class DealerLocationDA implements DealerLocationDAInterface{

    public List<dealer__Dealer_Location__c> getSelectedLocations(Set<Id> locationIds, Set<String> locationAbbrevs, Set<String> locationNames) {
        //Per the SOLID principle of single responsibility, this query should do one thing: query a subset of records based on the passed in parameters
        //but due to the structure of the query, if all of the passed in parameters are empty, then the query would return all records
        //Therefore if all of the parameters are empty, this query will return an empty list
        Boolean queryWillReturnAllLocations = true;
        String soql = 'select ' + buildDealerLocationFieldsString() + ' from dealer__Dealer_Location__c ';
        String junct = ' WHERE ';
        if (locationIds.size()>0) {
            queryWillReturnAllLocations = false;
            soql += junct + ' Id in :locationIds ';
            junct = ' or ';
        }
        if (locationAbbrevs.size()>0) {
            queryWillReturnAllLocations = false;
            soql += junct + ' dealer__Company_Number__c in :locationAbbrevs ';
            junct = ' or ';
        }
        if (locationNames.size()>0) {
            queryWillReturnAllLocations = false;
            soql += junct + ' Name in :locationNames ';
            junct = ' or ';
        }
        return (queryWillReturnAllLocations ? new List<dealer__Dealer_Location__c>() : Database.query(soql));
    }

    public List<dealer__Dealer_Location__c> getAllLocations() {
        String soql = 'select ' + buildDealerLocationFieldsString() + ' from dealer__Dealer_Location__c ';
        return Database.query(soql);
    }

    public List<dealer__Dealer_Location__c> getAllNonClosedLocations() {
        String soql = 'select ' + buildDealerLocationFieldsString() + ' from dealer__Dealer_Location__c where dealer__IsClosed__c=false ';
        return Database.query(soql);
    }

    private String buildDealerLocationFieldsString() {
        Map<String, Schema.SObjectField> dlFieldMap = Schema.dealer__Dealer_Location__c.SObjectType.getDescribe().fields.getMap();
        return String.join(new List<String>(dlFieldMap.keySet()),',');
    }

}