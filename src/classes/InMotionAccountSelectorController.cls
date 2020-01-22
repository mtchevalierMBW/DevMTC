/**
 * WMK, LLC (c) - 2019
 *
 * InMotionAccountSelectorController
 * 
 * Created By:   Alexander Miller
 * Created Date: 2/25/2018 
 * Work Item:    W-000603
 * Tested By:   InMotionAccountSelectorControllerTest
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 * Alexander Miller    AMM1       IR-0054177    05/09/2019  It was looking at the wrong client number field
 */
public class InMotionAccountSelectorController {

    @AuraEnabled
    public static Account getAccountByNumber(String accountNumber)
    {
        List<Account> listOfAccount = ([SELECT Id, 
                    Name,
                    Phone,
                    PersonOtherPhone,
                    PersonHomePhone,
                    BillingStreet,
                    BillingCity,
                    BillingState,
                    BillingPostalCode,
                    ShippingStreet,
                    ShippingCity,
                    ShippingState,
                    ShippingPostalCode,
                    PersonEmail
                FROM Account 
                // AMM1
                //WHERE ClientID__c = :accountNumber 
                WHERE ClientNumber__c = :accountNumber
                // AMM1
                LIMIT 1]); 

        if(listOfAccount != null && listOfAccount.size() > 0)
        {
            return listOfAccount.get(0);
        }
        else
        {
            return null;
        }
    }

    @AuraEnabled
    public static Account getAccountById(Id accountId)
    {
        List<Account> listOfAccount = ([SELECT Id, 
                    Name,
                    Phone,
                    PersonOtherPhone,
                    PersonHomePhone,
                    BillingStreet,
                    BillingCity,
                    BillingState,
                    BillingPostalCode,
                    ShippingStreet,
                    ShippingCity,
                    ShippingState,
                    ShippingPostalCode,
                    PersonEmail
                FROM Account 
                WHERE Id = :accountId 
                LIMIT 1]); 

        if(listOfAccount != null && listOfAccount.size() > 0)
        {
            return listOfAccount.get(0);
        }
        else
        {
            return null;
        }
    }
}