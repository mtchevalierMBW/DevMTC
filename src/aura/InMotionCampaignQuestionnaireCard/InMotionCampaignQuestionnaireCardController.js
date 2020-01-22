/**
 * WMK, LLC (c) - 2019 
 *
 * InMotionCampaignQuestionnaireCardController
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

		var questionType = component.get("v.question").Type__c;

		if(questionType != null && questionType == 'Boolean')
		{
			component.set("v.questionBoolean", true);
		}
		else if(questionType != null && questionType == 'Text')
		{
			component.set("v.questionBoolean", false);

			component.set("v.questionTextBoolean", true);
		}
		else
		{
			component.set("v.questionTextBoolean", false);

			helper.initOptionsList(component, event, helper);
		}
	},
	questionAnswered : function(component, event, helper)
	{
		var questionType = component.get("v.questionBoolean");

		var appEvent = $A.get("e.c:InMotionQuestionAnsweredEvent");
		
		var questionId = component.get("v.question").Id;
		appEvent.setParams({"questionId" : questionId});

		// Boolean
		if(questionType == true)
		{
			var booleanResponse = component.get("v.questionBooleanValue");

			appEvent.setParams({"questionResultBoolean" : booleanResponse});			
		}
		// Text
		else
		{
			var textResponse = component.get("v.textResponseValue");

			appEvent.setParams({"questionResultText" : textResponse});
		}

		appEvent.fire();
	},
	checkboxOnchange : function(component, event, helper)
	{
		var capturedCheckboxValue = event.getSource().get("v.value");
        var checkboxLabel = event.getSource().get("v.label");
		var optionsList = component.get('v.questionOptions');
		
		for(var i = 0; i < optionsList.length; i++)
		{
			// option matched
			if(checkboxLabel == optionsList[i].Value__c)
			{
				var appEvent = $A.get("e.c:InMotionQuestionAnsweredEvent");
				var questionId = component.get("v.question").Id;
				
				appEvent.setParams({"questionId" : questionId});
				appEvent.setParams({"questionOptionId" : optionsList[i].Id});
				appEvent.setParams({"questionOptionState" : capturedCheckboxValue});

				appEvent.fire();
			}
		}
	}
})