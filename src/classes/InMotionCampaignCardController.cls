/**
 * WMK, LLC (c) - 2019 
 *
 * InMotionCampaignCardController
 * 
 * Created By:   Alexander Miller
 * Created Date: 3/8/2019 
 * Work Item:    W-000603
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 */
public class InMotionCampaignCardController {

    @AuraEnabled
    public static List<In_Motion_Option__c> getListOfOptions(Id questionId)
    {
        List<In_Motion_Option__c> listOfOptions = new List<In_Motion_Option__c>();
        
        listOfOptions.addAll(([SELECT Id, 
                 	Name, 
                 	In_Motion_Question__c,
                 	Value__c 
                 FROM In_Motion_Option__c 
                 WHERE In_Motion_Question__c = :questionId]));
        
     	return listOfOptions;
	}
}