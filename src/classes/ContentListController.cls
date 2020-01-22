/**
 * WMK, LLC (c) - 2018 
 *
 * ContentListController
 * 
 * Created By:   Alexander Miller
 * Created Date: 12/7/2018 
 * Tested By: ContentListControllerTest
 * Work Item:    W-000421
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 * Alexander Miller    AMM1         W-000578    03/26/2019   Unrelated but wanted to clean up the card since it looked a littly ugly
 */
public with sharing class ContentListController {

    @AuraEnabled
	public static List<Content__c> getContentlist()
    {
        return ([SELECT Id,
                    Name,
                    OwnerId,
                    Owner.Name,
                    Group__c,
                    Title__c,
                    Description__c,
                    // AMM1 
                    LastModifiedDate,
                    // AMM1
                    Sub_Group__c
                FROM Content__c
                ORDER By My_Content__c DESC]);
    }

    @AuraEnabled
    public static List<Content__c> getFilteredContentList(String keyTerm)
    {
        // AMM1
        // List<List<SObject>> searchList = [FIND :keyTerm IN ALL FIELDS RETURNING Content__c (Id, Name, Title__c, Group__c, Sub_Group__c, Description__c, OwnerId, Owner.Name)];
        List<List<SObject>> searchList = [FIND :keyTerm IN ALL FIELDS RETURNING Content__c (Id, Name, Title__c, Group__c, Sub_Group__c, Description__c, OwnerId, Owner.Name, LastModifiedDate)];
        // AMM1

        return ((List<Content__c>) searchList[0]);
    } 
}