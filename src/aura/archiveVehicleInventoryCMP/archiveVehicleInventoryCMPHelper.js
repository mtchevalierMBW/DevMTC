({
	/**
	 * archiveVehicle
	 * 
	 * Connects to the Apex class 
	 */
	archiveVehicle : function(component, event, helper) {
		
		var action = component.get("c.arvhiceVehicle");

        console.log(component.get('v.recordId'));

        action.setParams({"vehicleId": component.get('v.recordId')});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
                console.log('success');

                // force a refresh
				$A.get('e.force:refreshView').fire(); 
				
				// https://webkul.com/blog/forceshowtoast-in-lightning/
				// toast for UX
				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'Success Message',
					message: 'Mode is pester ,duration is 5sec and this is normal Message',
					messageTemplate: 'Record {0} created! See it {1}!',
					duration:' 5000',
					key: 'info_alt',
					type: 'success',
					mode: 'pester'
				});
				toastEvent.fire();

				$A.get("e.force:closeQuickAction").fire();
			}
			else if (state === "INCOMPLETE") 
			{
				console.log('incomplete');
            }
			else if (state === "ERROR")
			{
				console.log('error');

				console.log(response);

				console.log(response.getError());

				var errors = response.getError();

				var finalErrorMessage;

				if (errors) 
				{
					if (errors[0] && errors[0].message) 
					{
						console.log("Error message: " + errors[0].message);
						finalErrorMessage = errors[0].message;
                    }
				} else {
					console.log("Unknown error");

					console.dir(errors);

					finalErrorMessage = "Unknown error";
				}
				
				// toast for UX
				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'Error Message',
					message: 'Mode is pester ,duration is 5sec and this is normal Message',
					messageTemplate: finalErrorMessage,
					duration:' 5000',
					key: 'info_alt',
					type: 'error',
					mode: 'pester'
				});
				toastEvent.fire();

				$A.get("e.force:closeQuickAction").fire();
			}
			
			console.log('end');
		});
		
        $A.enqueueAction(action);
	}
})