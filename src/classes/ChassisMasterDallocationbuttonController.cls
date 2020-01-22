/**
 * WMK, LLC (c) - 2018 
 *
 * ChassisMasterDallocationbuttonController
 * 
 * Created By:   Alexander Miller
 * Created Date: 11/1/2018 
 * Tested By:    ChassisMasterDallocationbuttonTest
 * Work Item:    W-000464
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */
global class ChassisMasterDallocationbuttonController {
    
    webservice static void opportunityDeallocate(List<Id> listOfIds)
    {        
        User u = CurrentUserSingleton.getInstance();
        
        List<Chassis_Master__c> listOfChassisToUpdate = new List<Chassis_Master__c>();
        	
        for(Id tempId : listOfIds)
        {
            listOfChassisToUpdate.add(new Chassis_Master__c(Id=tempId, Opportunity_Allocation__c = null, Customer__c = null));
		}
        
        //if(u.Profile.Name.contains('Order Entry'))
        //{

            update listOfChassisToUpdate;
        //}
    }
}