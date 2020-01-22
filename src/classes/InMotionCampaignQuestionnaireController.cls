/**
 * WMK, LLC (c) - 2019 
 *
 * InMotionCampaignQuestionnaireController
 * 
 * Created By:   Alexander Miller
 * Created Date: 2/28/2019 
 * Work Item:    W-000603
 * Tested By: InMotionCampaignQuestionnaireTest
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 */
public with sharing class InMotionCampaignQuestionnaireController {
	
    @AuraEnabled
    public static List<In_Motion_Question__c> getQuestions(Id campaignId)
    {
        return ([SELECT Id,
                    Name,
                    Question__c,
                    Type__c,
                    Campaign__c,
                    Order__c,
                    (SELECT Id, 
                      Name, 
                      In_Motion_Question__c,
                      Value__c  
                      FROM In_Motion_Option1__r)
                FROM In_Motion_Question__c
                WHERE Campaign__c = :campaignId
                ORDER BY Order__c ASC]);
    }

    @AuraEnabled
    public static void processResponses(String jsonFeedback)
    {
        List<Id> listOfOptionIds = new List<Id>();

        List<JSON2Apex> listOfParsedResponses = new List<JSON2Apex>();

        Map<Id, JSON2Apex.Options> mapOfParsedResponses = new Map<Id, JSON2Apex.Options>();

        Map<Id, JSON2Apex> mapOfQuestionToOptions = new Map<Id, JSON2Apex>();

        JSONParser parser = JSON.createParser(jsonFeedback);

        List<JSON2Apex> r;

        try {

            r = JSON2Apex.parse(jsonFeedback); 

            Map<Integer, Integer> myMap = new Map<Integer, Integer>();

        } catch (System.CalloutException e) {
            System.debug(e.getMessage());
        }

        // Gather the question Ids and then query the respective actions
        for(JSON2Apex tempQuestion : r)
        {
            mapOfQuestionToOptions.put(tempQuestion.questionId, tempQuestion);

            if(tempQuestion.Options != null)
            {
                for(JSON2Apex.Options tempOption : tempQuestion.Options)
                {
                    if(tempOption != null && tempOption.optionId != null)
                    {
                        listOfOptionIds.add(tempOption.optionId);

                        System.debug(tempOption);

                        mapOfParsedResponses.put(tempOption.optionId, tempOption);
                    }
                }
            }
        }

        System.debug(mapOfQuestionToOptions);
        System.debug(listOfOptionIds);
        
        List<In_Motion_Action__c> listOfActions = ([SELECT Id,
                                                        Name,
                                                        In_Motion_Option__c,
                                                        In_Motion_Option__r.In_Motion_Question__c,
                                                        Mode__c,
                                                        Override_Owner__c
                                                    FROM In_Motion_Action__c 
                                                    WHERE In_Motion_Option__c IN :listOfOptionIds]);

        List<In_Motion_Response__c> listOfResponses = new List<In_Motion_Response__c>();

        String modeType = '';

        for(In_Motion_Action__c tempAction : listOfActions)
        {
            if(mapOfParsedResponses.get(tempAction.In_Motion_Option__c) != null && mapOfQuestionToOptions.get(tempAction.In_Motion_Option__r.In_Motion_Question__c) != null)
            {    
                String accountId = mapOfQuestionToOptions.get(tempAction.In_Motion_Option__r.In_Motion_Question__c).accountId;

                JSON2Apex.Options tempOption = mapOfParsedResponses.get(tempAction.In_Motion_Option__c);
                
                String response = tempOption.value;
                Boolean selectedValue = tempOption.selected;

                if(selectedValue == true)
                {
                    System.debug(tempAction.In_Motion_Option__r.In_Motion_Question__c);
                    System.debug(tempAction.Id);
                    System.debug(response);
                    System.debug(accountId);
                    listOfResponses.add(new In_Motion_Response__c(
                        In_Motion_Question__c = tempAction.In_Motion_Option__r.In_Motion_Question__c,
                        In_Motion_Action__c = tempAction.Id,
                        Answer__c = response,
                        Account__c = accountId
                    ));
                }   
            }
        }

        System.debug(listOfResponses);

        insert listOfResponses;
    }

}