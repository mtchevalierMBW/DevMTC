/**
* MobilityWorks (c) - 2018
*
* changeToAccountClass
*
* Created: 8/28/2018
* Developer: Alexander Miller
* Tested By: 
*/
public with sharing class changeToAccountClass {

    @AuraEnabled
	public static void updateAccountToPersonAccount(Id accountId)
    {
        System.debug('changeToPersonAccountClass.updateAccountToPersonAccount: ' + accountId);

        AccountTools.convertToPersonAccount(accountId);
    }

    @AuraEnabled
    public static List<String> validateAccountToPersonAccount(Id accountId)
    {
        List<String> listOfErrors = new List<String>();

        List<Contact> listOfRelatedContacts = ([SELECT Id,
                                                    Name,
                                                    OwnerId,
                                                    Owner.Name,
                                                    AccountId
                                                FROM Contact 
                                                WHERE AccountId = :accountId]);

        Account tempAccount = [SELECT Id,
                                    OwnerId,
                                    Owner.Name,
                                    ParentId
                                FROM Account 
                                WHERE Id = :accountId
                                LIMIT 1];

        // a. For each intended Person Account, one (and only one) Contact record exists under the Account record.

        if(listOfRelatedContacts.size() > 1)
        {
            listOfErrors.add('Only one contact may exist under this account. This account has ' + listOfRelatedContacts.size() +' contacts.');
        }

        // b. The Account and Contact have the same record owner.

        for(Contact con : listOfRelatedContacts)
        {
            if(tempAccount.OwnerId != con.OwnerId)
            {
                listOfErrors.add('Contact ' + con.Name + ' has a different owner ' + con.Owner.Name + ' than the one listed on the Account ' + tempAccount.Owner.Name);
            }
        }

        // c. The Account and Contact have the same currency values (if applicable).
        // d. The Parent Account field on the Account and the Reports To field of the Contact are both blank.
        
        // e. The Account is not set as the Parent Account of any other Account records.
        if(tempAccount.ParentId != null)
        {
            listOfErrors.add('The Account record has a Parent Account.');
        }

        // f. The Contact is not set as the Reports To of any other Contact records.
        
        return listOfErrors;
    }

    @AuraEnabled
	public static void updateAccountToBusinessAccount(Id accountId)
    {
        System.debug('changeToBusinessAccountClass.updateAccountToPersonAccount: ' + accountId);

        AccountTools.convertToBusinessAccount(accountId);
    }
}