/**
 * AccountTriggerHandler
 * Tested by: AccountTriggerHandler_TEST.cls
 *
 * * Coverage:
 * 2020-01-24	100%    (31/31)
 *
 * 2020-01-23 M. Chevalier MTC1 Implemented updateClosestStorePerCustomer
 */

public with sharing class AccountTriggerHandler {

    MW_TriggerControls__c accountCounty = MW_TriggerControls__c.getInstance('AccountCounty');	// BLL19a
    MW_TriggerControls__c accountRcdType = MW_TriggerControls__c.getInstance('AccountRcdType');	// BLL24a
    MW_TriggerControls__c accountRLCounts = MW_TriggerControls__c.getInstance('AccountRLCounts'); // BLL28

    public void handleBeforeInsert(List<Account> customersNew, Map<Id, Account> customersByIdOld) {
        AccountProcess.DefaultCompanyAssignment(customersNew);
        buildDefaultDataValuesValidationsSummaries (customersNew, customersByIdOld);
    }
    public void handleBeforeUpdate(List<Account> customersNew, Map<Id, Account> customersByIdOld) {
        AccountProcess.RestrictRecordTypeChanges(customersNew, customersByIdOld);
        buildDefaultDataValuesValidationsSummaries (customersNew, customersByIdOld);
    }
    private void buildDefaultDataValuesValidationsSummaries  (List<Account> customersNew, Map<Id, Account> customersByIdOld) {
        AccountProcess.AddInfluencerAssociation(customersNew);
        // upload location & owner by name rather than by Id
        MW_TriggerControls__c uploadHelper = MW_TriggerControls__c.getInstance('uploadAccountHelper');
        if (uploadHelper==null || uploadHelper.Enabled__c){ AccountProcess.UploadReferencesByName(customersNew);}
        AccountProcess.StandardizePersonName(customersNew);
        AccountProcess.SynchFFTaxFields(customersNew, customersByIdOld);
        AccountProcess.RequiredFieldDefaults(customersNew);
        AccountProcess.AppendNewStockNumber(customersNew, customersByIdOld);
        if (accountRcdType==null || accountRcdType.Enabled__c){ AccountProcess.SyncPersonAccountFields(customersNew, customersByIdOld);}
        AccountProcess.ClearFieldsOnAddressChange(customersNew, customersByIdOld);
        if (accountRLCounts==null || accountRLCounts.Enabled__c){ AccountProcess.RecordRelatedRcdCounts(customersNew);}
    }

    public void handleAfterUpdate (List<Account> customersNew, Map<Id, Account> customersByIdOld) {
        AccountProcess.UpdateRelatedObjectOwners(customersNew, customersByIdOld);
    }
    public void handleBeforeDelete (List<Account> customers) {
        System.debug(customers);
        AccountProcess.CleanUpInfluencerAssociations(customers);
    }
    public void handleAfterNotDelete (List<Account> customers) {
        if ((accountCounty==null || accountCounty.Enabled__c) && Trigger.new.size()<5 && !UserInfo.getName().contains('DealerTeam')) {
            AccountProcess.AssignCountyJurisdiction(customers);
        }
    }
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

    @TestVisible
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
    // MTC1 end

}