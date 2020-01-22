/**
* MobilityWorks (c) - 2018
*
* changeToBusinessAccountClassTest
*
* Created: 8/28/2018
* Developer: Alexander Miller
* Tested By: changeToBusinessAccountClassTest
*/
public with sharing class changeToBusinessAccountClass {

    @AuraEnabled
	public static void updateAccountToBusinessAccount(Id accountId)
    {
        System.debug('changeToBusinessAccountClass.updateAccountToPersonAccount: ' + accountId);

        AccountTools.convertToBusinessAccount(accountId);
    }
}