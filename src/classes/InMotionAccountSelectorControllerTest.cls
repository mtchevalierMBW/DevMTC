/**
 * WMK, LLC (c) - 2019 
 *
 * InMotionAccountSelectorControllerTest
 * 
 * Created By:   Alexander Miller
 * Created Date: 2/28/2019 
 * Work Item:    W-000603
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 */
@isTest
public class InMotionAccountSelectorControllerTest {

    @TestSetup
    public static void setup()
    {
        Account tempAccount = new Account();
        tempAccount.Name = 'InMotionAccountSelectorControllerTest';
        insert tempAccount;
    }

    public static testMethod void testGetAccountByNumber()
    {
        Test.StartTest();

        Account tempAccount = [SELECT Id, 
                                ClientID__c 
                              FROM Account 
                              LIMIT 1];


        System.assertEquals(InMotionAccountSelectorController.getAccountByNumber(tempAccount.ClientID__c).Id, tempAccount.Id);

        Test.StopTest();
    }
}