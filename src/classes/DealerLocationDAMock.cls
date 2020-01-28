/**
 * Created by Matthew.Chevalier on 1/28/2020.
 */

public with sharing class DealerLocationDAMock implements DealerLocationDAInterface{
    public List<dealer__Dealer_Location__c> getAllLocations() {
        return buildNonClosedLocationRecords();
    }
    public List<dealer__Dealer_Location__c> getConditionallyFilteredLocations(Set<Id> locationIds, Set<String> locationAbbrevs, Set<String> locationNames) {
        return buildNonClosedLocationRecords();
    }
    public List<dealer__Dealer_Location__c> getAllNonClosedLocations() {
        return buildNonClosedLocationRecords();
    }

    private List<dealer__Dealer_Location__c> buildNonClosedLocationRecords() {
        return new List<dealer__Dealer_Location__c> {
                (dealer__Dealer_Location__c)new sfab_FabricatedSObject(dealer__Dealer_Location__c.class)
                        .setField( dealer__Dealer_Location__c.dealer__Physical_Location__c, Location.newInstance(41.153520, -81.360890))
                        .setField( dealer__Dealer_Location__c.dealer__Company_Number__c, 'KFL')
                        .setField( dealer__Dealer_Location__c.Name, 'Kent Free Library')
                        .setField( dealer__Dealer_Location__c.AutoAssignRetail__c, true)
                        .setField( dealer__Dealer_Location__c.dealer__IsClosed__c, false)
                        .toSObject(),
                (dealer__Dealer_Location__c) new sfab_FabricatedSObject(dealer__Dealer_Location__c.class)
                        .setField( dealer__Dealer_Location__c.dealer__Physical_Location__c, Location.newInstance(41.160860, -81.441040))
                        .setField( dealer__Dealer_Location__c.dealer__Company_Number__c, 'SMFL')
                        .setField( dealer__Dealer_Location__c.Name, 'Stow Monroe Falls Library')
                        .setField( dealer__Dealer_Location__c.AutoAssignRetail__c, true)
                        .setField( dealer__Dealer_Location__c.dealer__IsClosed__c, false)
                        .toSObject()
        };
    }
}