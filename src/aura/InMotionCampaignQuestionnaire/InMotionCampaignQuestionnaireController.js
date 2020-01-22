/**
 * WMK, LLC (c) - 2019 
 *
 * InMotionCampaignQuestionnaireController
 * 
 * Created By:   Alexander Miller
 * Created Date: 2/28/2019 
 * Work Item:    W-000603
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 */
({
	doInit : function(component, event, helper) {
		
	},
	campaignChosenEvent : function(component, event, helper)
	{
		var campaign = event.getParam("inMotionCampaign");
		var account = event.getParam("inMotionAccount");

		console.log("account: " + account);

		if(campaign !== 'undefined' && campaign != null)
		{
			component.set("v.campaignId", campaign[0]);
		}

		if(account !== 'undefined' && account != null)
		{
			component.set("v.accountId", account);
		}

		if(component.get("v.accountId") != null && component.get("v.campaignId") != null)
		{
			component.loadQuestionList();
		}
	},
	loadList : function(component, event, helper)
	{
		component.set('v.showSubmitButton', true);

		helper.loadListHelper(component, event, helper);
	},
	onSubmit : function(component, event, helper)
	{
		helper.submitQuestionnaire(component, event, helper);
	},
    optionsAnswer : function(component, event, helper)
    {
		
    },
	questionAnswered : function(component, event, helper)
	{
		var questionId = event.getParam("questionId"); 
		var questionOptionId = event.getParam("questionOptionId");
		var questionOptionState = event.getParam("questionOptionState");

		var campaign = component.get("v.campaignId");
		var account = component.get("v.accountId");  

		console.log(campaign);
		console.log(account);
		console.log(account[0]);
		
		var jsonOBJECT = {};
		jsonOBJECT["questionId"] = questionId;
		jsonOBJECT["campaignId"] = campaign;
		jsonOBJECT["accountId"] = account[0];

		// cycle through the array of JSON objects to upsert the event 
		var currentJSON = component.get('v.questionObjectJSON');
		var jsonArray = [];
	
		jsonArray = JSON.parse(currentJSON);

		for(var i = 0; i < jsonArray.length; i++)
		{
			if(jsonArray[i]["questionId"] == questionId) 
			{
				var optionsList = jsonArray[i]["options"];
				
				for(var k = 0; k < optionsList.length; k++)
				{
					if(optionsList[k].optionId == questionOptionId)
					{		
						optionsList[k].selected = questionOptionState;
					}
				}
			}	
		}

		component.set("v.questionObjectJSON", JSON.stringify(jsonArray));
	}
})