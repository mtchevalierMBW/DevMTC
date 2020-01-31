/**
 * Created by Matthew.Chevalier on 1/29/2020.
 */

public inherited sharing class AccountDA implements AccountDAInterface{

    public List<Account> getAccountsWithRAsAndROsFromAccountIds (Set<Id> acctIds) {
        return [
                SELECT  Id,
                        Name,
                        (
                            SELECT  Id,
                                    Name,
                                    Account__c,
                                    dealer__Agreement_Status__c,
                                    dealer__Return_Date__c
                            FROM Rental_Agreements2__r
                            WHERE dealer__Agreement_Status__c='Paid'
                            ORDER BY dealer__Return_Date__c
                        ),
                        (
                            SELECT  Id,
                                    Name,
                                    dealer__Customer__c,
                                    dealer__Status__c,
                                    dealer__Posted_Date_Time__c
                            FROM dealer__Service_Repair_Orders__r
                            WHERE dealer__Customer_Charges__c>0
                            AND dealer__Status__c='Posted'
                        )
                FROM Account
                WHERE Id IN :acctIds
        ];
    }
}