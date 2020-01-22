({
	/**
	 * cloneTemplateHelper
	 * 
	 * Connects to the Apex class 
	 */
	cloneTemplateHelper : function(component, event, helper) 
	{
		component.set('v.Spinner', true);

		var button = component.find('disablebuttonid');
		button.set('v.disabled', true);

		var action = component.get("c.cloneTemplate");

		var recordId = component.get('v.recordId');
		var vinValue = component.get("v.vinValue");
		console.log('record Id: ' + recordId);
		console.log('VIN: ' + vinValue);

		action.setParams({"vehicleId": recordId, "vin" : vinValue});
		
		// clear the error message if one exists
		var errorMesageTemp = component.get("v.errorMessage");

		if(errorMesageTemp !== undefined && errorMesageTemp !== null && errorMesageTemp.length > 0)
		{
			component.set("v.errorMessage", "");
		}

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			console.log(state);

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('success');
				
				// Trick to get an Apex Method's return value and then update the lightning component
				var vehicleId = response.getReturnValue();

				console.log(vehicleId);

				// redirect
				var urlEvent = $A.get("e.force:navigateToURL");
				urlEvent.setParams({
					"url": "/apex/dealer__VINDecodeStyleSelect?id=" + vehicleId,
					"isredirect": "true"
				});
				urlEvent.fire();

				$A.get("e.force:closeQuickAction").fire();
			}
			else if (state === "INCOMPLETE") 
			{
				console.log('incomplete');
            }
			else if (state === "ERROR")
			{
				console.log('error');

				var errors = response.getError();

				var finalErrorMessage;

				console.log(errors);
				console.log(errors[0].pageErrors[0].message);

				if (errors[0] && errors[0].pageErrors[0].message) 
				{
					console.log("Error message: " + errors[0].pageErrors[0].message);
					finalErrorMessage = errors[0].pageErrors[0].message;
				}
				else
				{
					finalErrorMessage = 'Unknown Error. Please contact your IT Department';
				}

				component.set('v.errorMessage', finalErrorMessage);

				console.log(component.get('v.errorMessage'));
			}

			console.log('end');

			var button = component.find('disablebuttonid');
			button.set('v.disabled', false);

			component.set("v.Spinner", false);
		});
		
        $A.enqueueAction(action);
	}
})