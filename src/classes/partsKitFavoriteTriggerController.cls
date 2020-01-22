/**
 * WMK, LLC (c) - 2019 
 *
 * partsKitFavoriteTriggerController
 * 
 * Created By:   Alexander Miller
 * Created Date: 03/26/2019
 * Tested By:    partsKitFavoriteTriggerControllerTest
 * Work Item:    W-000582
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */
public class partsKitFavoriteTriggerController {

    public partsKitFavoriteTriggerController(){}

    public void checkDuplicate(List<Parts_Kit_Favorite__c> newList)
    {
        List<Id> partIdList = new List<Id>();

        List<Id> locationIdList = new List<Id>();
        
        List<Id> userIdList = new List<Id>();

        for(Parts_Kit_Favorite__c tempFavorite : newList)
        {
            if(tempFavorite.Parts_Kit__c != null)
            {
                partIdList.add(tempFavorite.Parts_Kit__c);
            }

            if(tempFavorite.Store_Location__c != null)
            {
                locationIdList.add(tempFavorite.Store_Location__c);
            }


            if(tempFavorite.User__c != null)
            {
                userIdList.add(tempFavorite.User__c);
            }
        }

        List<Parts_Kit_Favorite__c> listOfParts = ([SELECT Id, 
                                                        Parts_Kit__c, 
                                                        Store_Location__c, 
                                                        User__c 
                                                    FROM Parts_Kit_Favorite__c 
                                                    WHERE Parts_Kit__c IN :partIdList AND
                                                        Store_Location__c IN :locationIdList AND
                                                        User__c IN :userIdList]);

        for(Parts_Kit_Favorite__c tempFavorite : newList)
        {
            for(Parts_Kit_Favorite__c currentPart : listOfParts)
            {
                if(tempFavorite.User__c == currentPart.User__c &&
                    tempFavorite.Store_Location__c == currentPart.Store_Location__c && 
                    tempFavorite.Parts_Kit__c == currentPart.Parts_Kit__c)
                {
                    tempFavorite.addError('Part is a duplicate');
                }   
            }
        }
    }
}