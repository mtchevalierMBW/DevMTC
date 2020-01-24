/**
 * AccountTriggerHandler
 * Tested by: AccountTriggerHandler_TEST.cls
 *
 * 2020-01-23 M. Chevalier
 */

public with sharing class AccountTriggerHandler {

    public void handleBeforeUpdate (List<Account> customers) {
        updateClosestStorePerCustomer (customers);
    }

    private void updateClosestStorePerCustomer (List<Account> customers) {
        List<dealer__Dealer_Location__c> storeLocations = getStoreLocations();
        for(Account customer : customers) {
            setClosestStore(customer, storeLocations);
        }
    }

    private List<dealer__Dealer_Location__c> getStoreLocations () {
        List<dealer__Dealer_Location__c> storeLocationsAll = invokeLocationSingletonToFetchAllLocations();
        List<dealer__Dealer_Location__c> storeLocationsValid = new List<dealer__Dealer_Location__c>();
        for(dealer__Dealer_Location__c loc : storeLocationsAll) {
            if(locationFulfillsBusinessRequirements(loc)) {
                storeLocationsValid.add(loc);
            }
        }
        return storeLocationsValid;
    }

    private Boolean locationFulfillsBusinessRequirements (dealer__Dealer_Location__c loc) {
        return loc.AutoAssignRetail__c == TRUE && loc.dealer__IsClosed__c == FALSE;
    }

    private List<dealer__Dealer_Location__c> invokeLocationSingletonToFetchAllLocations() {
        LocationsSingleton locationsSingletonInstance = LocationsSingleton.getInstance();
        locationsSingletonInstance.retrieveAllLocations();
        return locationsSingletonInstance.locationIdMap.values();
    }

    private void setClosestStore (Account customer, List<dealer__Dealer_Location__c> storeLocations) {
        Location customerLocation = Location.newInstance(customer.BillingLatitude, customer.BillingLongitude);
        customer.Closest_Store_Location__c = getClosestStoreId(customerLocation, storeLocations);
    }

    private Id getClosestStoreId(Location customerLocation, List<dealer__Dealer_Location__c> storeLocations) {
        Id closestStoreId = null;
        Double minimumDistance = null;
        for(dealer__Dealer_Location__c storeLocation : storeLocations) {
            Double distance = Location.getDistance(customerLocation, storeLocation.dealer__Physical_Location__c, 'mi');
            if(minimumDistance == null || distance < minimumDistance) {
                minimumDistance = distance;
                closestStoreId = storeLocation.Id;
            }
        }
        return closestStoreId;
    }
}