/**
 * Created by Matthew.Chevalier on 1/29/2020.
 */

public inherited sharing class AccountDAMock implements AccountDAInterface{

    public List<Account> getAccountsWithRAsAndROsFromAccountIds (Set<Id> acctIds) {
        return new List<Account>();
    }
}