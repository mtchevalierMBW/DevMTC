/**
 * WMK, LLC (c) - 2019
 *
 * InMotionCampaignQuestionnaireHelper
 * 
 * Created By:   Alexander Miller
 * Created Date: 2/28/2019 
 * Work Item:    W-000603
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 */
({
	loadListHelper : function(component, event, helper) {

		var action = component.get("c.getQuestions");

		action.setParams({"campaignId": component.get("v.campaignId")});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('loadListHelper success');
				console.dir(response.getReturnValue());

				component.set("v.QuestionList", response.getReturnValue());

				// load the initial JSON

				var tempJsonArray = [];

				var campaignId = component.get("v.campaignId");
				var accountId = component.get("v.accountId");

				for(var i = 0; i < response.getReturnValue().length; i++)
				{
					var currentItem = response.getReturnValue()[i];
					
					var jsonOBJECT = {};
					jsonOBJECT["questionId"] = currentItem["Id"];
					jsonOBJECT["campaignId"] = campaignId;
					jsonOBJECT["accountId"] = accountId;

					if(currentItem["Type__c"] == 'Text')
					{
						jsonOBJECT["questionString"] = "";
					}
					else if(currentItem["Type__c"] == 'Boolean')
					{
						jsonOBJECT["questionBoolean"] = false;
					}
                    
                    jsonOBJECT["options"] = [];
                    
                    for(var m = 0; m < currentItem["In_Motion_Option1__r"].length; m++)
                    {
                    	var currentOption = currentItem["In_Motion_Option1__r"][m];
                        
                        var jsonOBJECT_Option = {};
                        
                        jsonOBJECT_Option["optionId"] = currentOption.Id;
                        jsonOBJECT_Option["questionId"] = currentOption.In_Motion_Question__c;
                        jsonOBJECT_Option["value"] = currentOption.Value__c;
                        jsonOBJECT_Option["selected"] = false;
                        
                        jsonOBJECT["options"].push(jsonOBJECT_Option);
                    }

					tempJsonArray.push(jsonOBJECT);
				}

				console.dir(tempJsonArray);

				component.set('v.questionObjectJSON', JSON.stringify(tempJsonArray));
			}
			else if (state === "INCOMPLETE") 
			{
				console.log('loadListHelper incomplete');
            }
			else if (state === "ERROR")
			{
				console.log('loadListHelper error');

				console.log(response);

				console.log(response.getError());

				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'InMotionCampaignQuestionnaire: loadListHelper: Error Message',
					message: response.getError(),
					messageTemplate: response.getError(),
					duration:' 5000',
					key: 'info_alt',
					type: 'error',
					mode: 'pester'
				});
				toastEvent.fire();
			}

			console.log('loadListHelper end');
		});
		
        $A.enqueueAction(action);
	},
	submitQuestionnaire : function(component, event, helper)
	{
		var action = component.get("c.processResponses");
		var jsonResults = component.get("v.questionObjectJSON");

		console.dir(jsonResults);

		action.setParams({"jsonFeedback": jsonResults}); 
		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('submitQuestionnaire success');
				
				component.set('v.questionObjectJSON', null);
				component.set('v.showSubmitButton', false);

				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'Successfully submitted Questionnaire',
					message: "Please choose a new Account/Campaign to continue",
					messageTemplate: "Please choose a new Account/Campaign to continue",
					duration:'7000',
					key: 'info_alt',
					type: 'success',
					mode: 'pester'
				});
				toastEvent.fire();
			}
			else if (state === "INCOMPLETE") 
			{
				console.log('submitQuestionnaire incomplete');
            }
			else if (state === "ERROR")
			{
				console.log('submitQuestionnaire error');

				console.log(response);

				console.log(response.getError());

				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'InMotionCampaignQuestionnaire: submitQuestionnaire: Error Message',
					message: response.getError(),
					messageTemplate: response.getError(),
					duration:' 5000',
					key: 'info_alt',
					type: 'error',
					mode: 'pester'
				});
				toastEvent.fire();
			}

			console.log('submitQuestionnaire end');
		});
		
        $A.enqueueAction(action);
	}
})