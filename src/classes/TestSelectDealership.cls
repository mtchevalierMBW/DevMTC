@isTest
private class TestSelectDealership {
    static testmethod void TestSelectDealershipController() {
        
        // Load a new location
        dealer__Dealer_Location__c location = new dealer__Dealer_Location__c();
        location.Name = 'Jones Fort';
        location.dealer__Company_Number__c = '1';
        location.dealer__City__c = 'San Jose';
        location.dealer__Postal_Code__c = '944509';
        location.dealer__State__c = 'CA';

        insert location;

        SelectDealership s = new SelectDealership();
        
        s.getmyDealerships();
        s.chooseDealership(); // Test for no dealership chosen

        s.selectedDealershipId = location.Id;
        s.chooseDealership(); // Test for Dealership chosen

        
    }
}