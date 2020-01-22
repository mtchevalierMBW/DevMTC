/**
 * WMK, LLC (c) - 2018 
 *
 * ChassisMasterTriggerHandler
 * 
 * Created By:   Alexander Miller
 * Created Date: 10/29/2018 
 * Tested By:    ChassisMasterTriggerHandlerTest
 * Work Item:    W-000464
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */
public class ChassisMasterTriggerHandler {

    public Map<Id, Opportunity__c> mapOfOpportunitiesToUpdate = new Map<Id, Opportunity__c>();

    public ChassisMasterTriggerHandler(){}

    /**
    * updateMaps
    *
    * Generic function which updates all of the Object Maps
    * which do not contain Chassis Master records 
    * for best practice.
    */
    public void updateMaps()
    {
        update mapOfOpportunitiesToUpdate.values();
    }
    
    /**
    * opportunityAllocationRollup
    *
    * Function which queries the system for related Chassis
    * records with the same Opportunity lookup id.
    * 
    * The Opportunity is incremented with the number of 
    * Chassis related to it at any given time.
    */
    public void opportunityAllocationRollup(List<Chassis_Master__c> listOfChassis)
    {
        List<Chassis_Master__c> listOfChass = getListOfChassisRelatedToOpportunities(listOfChassis);

        Map<Id, Integer> mapOfOpportunityRollups = new Map<Id, Integer>();

        // Figure out the counts
        for(Chassis_Master__c tempChassis : listOfChass)
        {
            if(mapOfOpportunityRollups.get(tempChassis.Opportunity_custom__c) == null)
            {
                mapOfOpportunityRollups.put(tempChassis.Opportunity_custom__c, 1);
            }
            else 
            {  
                Integer tempCount = mapOfOpportunityRollups.get(tempChassis.Opportunity_custom__c);

                tempCount = tempCount + 1;

                mapOfOpportunityRollups.put(tempChassis.Opportunity_custom__c, tempCount);
            }
        }

        // Create the Opportunity Mappings
        for(Id tempId : mapofOpportunityRollups.keySet())
        {
            if(mapOfOpportunitiesToUpdate.get(tempId) == null)
            {
                mapOfOpportunitiesToUpdate.put(tempId, new Opportunity__c(Id=tempId, Number_Of_Vehicles_Allocated__c = mapofOpportunityRollups.get(tempId)));
            }
        }
    }

    /**
    * getListOfChassisRelatedToOpportunities
    *
    * Function to get all the Chassis Master
    * records related to a series of Opportunities
    * found in the Chassis Master list
    *
    * @param listOfChassis - Likely to be Trigger.new
    */
    public List<Chassis_Master__c> getListOfChassisRelatedToOpportunities(List<Chassis_Master__c> listOfChassis)
    {
        List<Id> listOfOpportunityids = new List<Id>();

        for(Chassis_Master__c tempChassis : listOfChassis)
        {
            if(tempChassis.Opportunity_custom__c != null)
            {
                listOfOpportunityids.add(tempChassis.Opportunity_custom__c);
            }
        }

        return ([SELECT Id,
                    Opportunity_custom__c 
                FROM Chassis_Master__c
                WHERE Opportunity_custom__c IN :listOfOpportunityids]);
    }
}