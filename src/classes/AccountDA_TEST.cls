/**
 * Created by Matthew.Chevalier on 1/29/2020.
 */

@IsTest
private class AccountDA_TEST {

    @IsTest
    static void getAccountsWithRAsAndROsFromAccountIds_givenIdSet_returnsAccountList () {
        AccountDA instance = new AccountDA();
        Test.startTest();
        {
            List<Account> res = instance.getAccountsWithRAsAndROsFromAccountIds(new Set<Id>());
            System.assertEquals(0, res.size());
        }
        Test.stopTest();
    }

    @IsTest
    static void callAllMockMethods () {
        AccountDAMock instance = new AccountDAMock();
        Test.startTest();
        {
            instance.getAccountsWithRAsAndROsFromAccountIds(new Set<Id>());
        }
        Test.stopTest();
    }
}