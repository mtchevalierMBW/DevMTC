/**
 * WMK, LLC (c) - 2019 
 *
 * ContentProfileSelectorController
 * 
 * Created By:    Alexander Miller
 * Created Date:  03/26/2019 
 * Work Item:     W-000578
 * Tested By: 
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 */
public class ContentProfileSelectorController {

    @AuraEnabled
    public static List<String> getActiveProfiles(Id contentId){

        List<String> listOfProfileNames = new List<String>();

        for(Profile tempProfile : ([SELECT Id, 
                                    Name, 
                                    Description 
                                    FROM Profile
                                    WHERE Id IN (SELECT ProfileId 
                                                FROM User 
                                                WHERE isActive = True) 
                                    ORDER BY Name ASC]))
        {
            listOfProfileNames.add(tempProfile.Name);
        }
        
        return listOfProfileNames;
    }

    @AuraEnabled
    public static List<Content_Profile__c> getCurrentContentProfiles(Id contentId){

        return ([SELECT Id, 
                    Name, 
                    Content__c, 
                    Profile_Id__c, 
                    Profile_Name__c 
                FROM Content_Profile__c 
                WHERE Content__c = :contentId]);
    }

    @AuraEnabled
    public static void insertContentProfile(Id contentId, String profileName){
        
        System.debug(profileName);

        Id profileId = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1].Id;

        Content_Profile__c tempContentProfile = new Content_Profile__c();

        tempContentProfile.Content__c = contentId;
        tempContentProfile.Profile_Id__c = profileId;
        tempContentProfile.Profile_Name__c = profileName;

        insert tempContentProfile;
    }

    @AuraEnabled
    public static void removeContentProfile(List<Content_Profile__c> listOfProfileNames){
        
        delete listOfProfileNames;
    }

    @AuraEnabled
    public static List<User> getUsersByProfile(String profileName){
        
        return ([SELECT Id, 
                    Name 
                FROM User 
                WHERE Profile.Name = :profileName]);
    }

    @AuraEnabled
    public static String getProfileNameByUser(Id userId){
        
        System.debug(userId);

        return [SELECT Id, 
                    Name 
                FROM Profile 
                WHERE Id IN (SELECT ProfileId 
                            FROM User 
                            WHERE Id = :userId) 
                LIMIT 1].Name;        
    }

    @AuraEnabled
    public static List<User> getUsersByName(String name){

        String queriableName = '%' + name + '%';

        return ([SELECT Id, Name FROM User WHERE IsActive = true AND Name LIKE :queriableName]);
    }
}