/**
 * WMK, LLC (c) - 2019 
 *
 * partsKitFavoriteTriggerControllerTest
 * 
 * Created By:   Alexander Miller
 * Created Date: 03/26/2019
 * Work Item:    W-000582
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */
 @isTest
public class partsKitFavoriteTriggerControllerTest {

    private static TestHelper_MW th = new TestHelper_MW(); 

    @TestSetup
    static void makeData()
    {
        // 1. Make a Parts Kit
        dealer__Parts_Kit__c tempPartsKit = new dealer__Parts_Kit__c();
        tempPartsKit.dealer__Description__c = 'Favorite';
        insert tempPartsKit;

        // 2. Make a location
        dealer__Dealer_Location__c tempLocation = th.getDealerLocation('1');

        // 3. Make a Part Kit favorite using the running user
        Parts_Kit_Favorite__c tempFavorite = new Parts_Kit_Favorite__c();

        tempFavorite.User__c = UserInfo.getUserId();
        tempFavorite.Parts_Kit__c = tempPartsKit.Id;
        tempFavorite.Store_Location__c = tempLocation.Id;

        insert tempFavorite;
    }

    public static testMethod void testDuplicateChecker()
    {    
        Test.startTest();
        
        dealer__Parts_Kit__c tempPartsKit = [SELECT Id FROM dealer__Parts_Kit__c LIMIT 1];

        dealer__Dealer_Location__c tempLocation = [SELECT Id FROM dealer__Dealer_Location__c LIMIT 1];

        Parts_Kit_Favorite__c tempFavorite = new Parts_Kit_Favorite__c();

        tempFavorite.User__c = UserInfo.getUserId();
        tempFavorite.Parts_Kit__c = tempPartsKit.Id;
        tempFavorite.Store_Location__c = tempLocation.Id;

        try{
            insert tempFavorite;
        } catch (Exception e){}

        Test.stopTest();
    }
}