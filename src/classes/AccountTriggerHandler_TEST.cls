/**
 * AccountTriggerHandler_TEST.cls
 *
 * 2020-01-24 M. Chevalier MTC1 wrote tests for handleBeforeUpdate method
 */

@IsTest(seeAllData = false)
private class AccountTriggerHandler_TEST {
    // MTC1 start
    @TestSetup
    static void setup() {
        dealer__Dealer_Location__c location1 = new dealer__Dealer_Location__c(
                Name = 'Kent Free Library',
                dealer__Physical_Location__Latitude__s = 41.153520,
                dealer__Physical_Location__Longitude__s = -81.360890,
                dealer__City__c = 'Kent',
                dealer__Company_Number__c = 'KFL',
                dealer__State__c = 'OH',
                dealer__Postal_Code__c = '44240',
                AutoAssignRetail__c = true
        );
        insert location1;
        dealer__Dealer_Location__c location2 = new dealer__Dealer_Location__c(
                Name = 'Stow Munroe Falls Library',
                dealer__Physical_Location__Latitude__s = 41.160860,
                dealer__Physical_Location__Longitude__s = -81.441040,
                dealer__City__c = 'Stow',
                dealer__Company_Number__c = 'SMFL',
                dealer__State__c = 'OH',
                dealer__Postal_Code__c = '44224',
                AutoAssignRetail__c = true
        );
        insert  location2;
        Account customer = new Account(
                Name = 'Drake Chevalier',
                BillingLatitude = 41.155330,
                BillingLongitude = -81.420850,
                Store_Location__c = location1.Id
        );
        insert customer;
    }

    @IsTest
    static void testHandleBeforeUpdate_givenEmptyList_returnsVoid() {
        AccountTriggerHandler instance = new AccountTriggerHandler();
        Test.startTest();
            instance.handleBeforeUpdate(new List<Account>());
        Test.stopTest();
    }

    @IsTest
    static void testHandleBeforeUpdate_givenSingleCustomer_returnsVoid() {
        AccountTriggerHandler instance = new AccountTriggerHandler();
        List<Account> customers = [SELECT BillingAddress, BillingLatitude, BillingLongitude, Store_Location__c FROM Account LIMIT 1];
        Test.startTest();
            instance.handleBeforeUpdate(customers);
        Test.stopTest();
    }
    // MTC1 end
}