/**
 * AccountTriggerHandler_TEST.cls
 *
 * 2020-01-24 M. Chevalier MTC1 wrote tests for handleBeforeUpdate method
 * 2020-01-28 M. Chevalier MTC2 rewrote tests using SObjectFabricator utility
 */

@IsTest(seeAllData = false)
private class AccountTriggerHandler_TEST {

    static AccountTriggerHandler setupInstance () {
        AccountTriggerHandler instance = new AccountTriggerHandler();
        instance.accountsOld    = new List<Account>();
        instance.accountsNew    = new List<Account>();
        instance.accountsOldMap = new Map<Id, Account>();
        instance.accountsNewMap = new Map<Id, Account>();
        return instance;
    }

    @IsTest
    static void beforeInsert_givenVoid_returnsVoid () {
        AccountTriggerHandler instance = setupInstance();
        Test.startTest();
        {
            instance.beforeInsert();
        }
        Test.stopTest();
        //System.debug('expected', 'actual');
    }

    @IsTest
    static void beforeUpdate_givenVoid_returnsVoid () {
        AccountTriggerHandler instance = setupInstance();
        Test.startTest();
        {
            instance.beforeUpdate();
        }
        Test.stopTest();
        //System.debug('expected', 'actual');
    }

    @IsTest
    static void beforeDelete_givenVoid_returnsVoid () {
        AccountTriggerHandler instance = setupInstance();
        Test.startTest();
        {
            instance.beforeDelete();
        }
        Test.stopTest();
        //System.debug('expected', 'actual');
    }

    @IsTest
    static void afterInsert_givenVoid_returnsVoid () {
        AccountTriggerHandler instance = setupInstance();
        Test.startTest();
        {
            instance.afterInsert();
        }
        Test.stopTest();
        //System.debug('expected', 'actual');
    }

    @IsTest
    static void afterUpdate_givenVoid_returnsVoid () {
        AccountTriggerHandler instance = setupInstance();
        Test.startTest();
        {
            instance.afterUpdate();
        }
        Test.stopTest();
        //System.debug('expected', 'actual');
    }

}