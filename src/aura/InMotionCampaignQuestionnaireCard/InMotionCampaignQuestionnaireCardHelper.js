/**
 * WMK, LLC (c) - 2019 
 *
 * InMotionCampaignQuestionnaireCardHelper
 * 
 * Created By:   Alexander Miller
 * Created Date: 2/28/2019 
 * Work Item:    W-000603
 *
 * Modified By         Alias       Work Item       Date     Reason
 * ----------------------------------------------------------------- 
 */
({
	initOptionsList : function(component, event, helper) 
	{
		var action = component.get("c.getListOfOptions");

		action.setParams({"questionId": component.get("v.question").Id});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('initOptionsList success');
				console.dir(response.getReturnValue());
                
                component.set("v.questionOptions", response.getReturnValue());
			}
			else if (state === "INCOMPLETE") 
			{
				console.log('initOptionsList incomplete');
            }
			else if (state === "ERROR")
			{
				console.log('initOptionsList error');

				console.log(response);

				console.log(response.getError());

				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'InMotionCampaignQuestionnaireCard: initOptionsList: Error Message',
					message: response.getError(),
					messageTemplate: response.getError(),
					duration:' 5000',
					key: 'info_alt',
					type: 'error',
					mode: 'pester'
				});
				toastEvent.fire();
			}

			console.log('initOptionsList end');
		});
		
        $A.enqueueAction(action);
	}
})