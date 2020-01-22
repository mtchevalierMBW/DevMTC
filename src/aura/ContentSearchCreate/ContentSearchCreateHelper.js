/**
 * WMK, LLC (c) - 2018 
 *
 * ContentSearchCreateHelper
 * 
 * Created By:   Alexander Miller
 * Created Date: 11/26/2018 
 * Work Item:    W-000421
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 * Alexander Miller    AMM1        W-000578    03/29/2019   Update to handle the event firing better
 */
({
	// AMM1
	fireContentEvent : function(component, event, helper)
	{
		var appEvent = $A.get("e.c:ContentEvent");
		appEvent.setParams({"selectContent" : null});
		appEvent.fire();	
	},
	fireFilterEvent : function(component, event, helper)
	{
		var searchValue = component.get("v.searchText");
		console.log('fireFilterEvent: ' + searchValue);
		var appEvent = $A.get("e.c:ContentFilterEvent");
        appEvent.setParams({"contentFiler" : searchValue});	
		appEvent.fire();
	},
	// AMM1
	createParentContentRecord : function(component, event, helper) {
		
		var action = component.get("c.createContentRecord");

		var newTitle = component.get("v.contentTitle");
		var newDescription = component.get("v.contentDescription");

		console.log("createParentContentRecord: title: " + newTitle);
		console.log("createParentContentRecord: description: " + newDescription);

		action.setParams({
			"title": newTitle,
			"description": newDescription
		});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('createParentContentRecord: success');
				console.dir(response.getReturnValue());

				// fire the search functionality event to fake a refresh
				component.closeModal();

				var appEvent = $A.get("e.c:ContentFilterEvent");
        		appEvent.setParams({"contentFiler" : ""});
				appEvent.fire();

				// select the brand new content record
				var appEvent = $A.get("e.c:ContentEvent");
				appEvent.setParams({"selectContent" : response.getReturnValue()});
				appEvent.fire();
			}
			else if (state === "INCOMPLETE") 
			{
				console.log('createParentContentRecord: incomplete');
            }
			else if (state === "ERROR")
			{
				console.log('createParentContentRecord: error');

				console.log(response);

				console.log(response.getError());

				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'ContentSearchCreate: createParentContentRecord: Error Message',
					message: response.getError(),
					messageTemplate: response.getError(),
					duration:' 5000',
					key: 'info_alt',
					type: 'error',
					mode: 'pester'
				});
				toastEvent.fire();
			}
			
			console.log('end');
		});
		
        $A.enqueueAction(action);
	}
})