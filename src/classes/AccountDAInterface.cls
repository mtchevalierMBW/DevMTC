/**
 * Created by Matthew.Chevalier on 1/29/2020.
 */

public interface AccountDAInterface {
    List<Account> getAccountsWithRAsAndROsFromAccountIds (Set<Id> acctIds);
}