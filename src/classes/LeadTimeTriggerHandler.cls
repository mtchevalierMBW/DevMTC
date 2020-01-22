/**
* TransitWorks (c) - 2018
*
* LeadTimeTriggerHandler
*
* Created By: Alexander Miller
* Created Date: 8/20/2018
* Tested By: LeadTimeTriggerHandlerTest
*/
public class LeadTimeTriggerHandler {

    public List<Lead_Time__c> newList = new List<Lead_Time__c>();
    public List<Lead_Time__c> oldList = new List<Lead_Time__c>();
    public Map<Id, Lead_Time__c> newMap = new Map<Id, Lead_Time__c>();
    public Map<Id, Lead_Time__c> oldMap = new Map<Id, Lead_Time__c>();

    public LeadTimeTriggerHandler(){}

    public LeadTimeTriggerHandler(Lead_Time__c[] newArray, Lead_Time__c[] oldArray, Map<Id, Lead_Time__c> newHashMap, Map<Id, Lead_Time__c> oldHashMap){
        newList = newArray;
        oldList = oldArray;
        newMap = newHashMap;
        oldMap = oldHashMap;
    }

    /**
    * flagIfIdenticalLeadTimeExists
    *
    * Function which flags the trigger context if the 
    * record is identical to another record in the system
    * in the following way:
    *
    * - Make__c
    * - Model__c
    * - Model_Ext__c
    * - Floor_Style__c
    * - Frame__c
    * - Division_Master__c
    */
    public void flagIfIdenticalLeadTimeExists(List<Lead_Time__c> tempList)
    {
        List<Lead_Time__c> listOfCurrentLeadTimes = new List<Lead_Time__c>([SELECT Id,
                                                                                Name,
                                                                                Make__c,
                                                                                Model__c,
                                                                                Model_Ext__c,
                                                                                Floor_Style__c,
                                                                                Frame__c,
                                                                                Division_Master__c
                                                                            FROM Lead_Time__c]);

        for(Lead_Time__c tempLead : tempList)
        {
            for(Lead_Time__c currentLead : listOfCurrentLeadTimes)
            {
                if((tempLead.Id == null || currentLead.Id != tempLead.Id) &&
                    (tempLead.Make__c == currentLead.Make__c) &&
                    (tempLead.Model__c == currentLead.Model__c) &&
                    (tempLead.Model_Ext__c == currentLead.Model_Ext__c) &&
                    (tempLead.Floor_Style__c == currentLead.Floor_Style__c) &&
                    (tempLead.Frame__c == currentLead.Frame__c) &&
                    (tempLead.Division_Master__c == currentLead.Division_Master__c)
                )
                {
                    tempLead.addError('This lead time is identical to another one: ' + tempLead.Id + ' Name: ' + tempLead.Name + ' and is therefore not allowed.');
                }
            }
        } 
    }
}