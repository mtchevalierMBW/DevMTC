/**
 * Created by Matthew.Chevalier on 1/28/2020.
 */

public interface DealerLocationDAInterface {
    List<dealer__Dealer_Location__c> getConditionallyFilteredLocations(Set<Id> locationIds, Set<String> locationAbbrevs, Set<String> locationNames);
    List<dealer__Dealer_Location__c> getAllLocations();
    List<dealer__Dealer_Location__c> getAllNonClosedLocations();
}