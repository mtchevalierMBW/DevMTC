/**
 * WMK, LLC (c) - 2018 
 *
 * ContentTagComponentHelper
 * 
 * Created By:   Alexander Miller
 * Created Date: 11/13/2018 
 * Work Item:    W-000421
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */
({
	initializeContentTagSelected : function(component, event, helper){
		
		var action = component.get("c.getContentTags");

		action.setParams({"contentId": component.get('v.content.Id')});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('initializeContentTagSelected: success');
				console.dir(response.getReturnValue());

				component.set("v.contentTags", response.getReturnValue());

				// call tandem Tag query function in the component
				component.initContentTags();
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

				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'ContentTagComponent: initializeContentTagSelected: Error Message',
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
	},
	initializeContentTagUnselected : function(component, event, helper){
		
		var action = component.get("c.getTags");

		action.setParams({"contentId": component.get('v.content.Id')});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('initializeContentTagUnselected: success');
				console.dir(response.getReturnValue());

				component.set("v.tags", response.getReturnValue());
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

				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'ContentTagComponent: initializeContentTagUnselected: Error Message',
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
	},
	selectionAdd : function(component, event, helper){
		
		// Id of the Tag selected
		var selectedItem = component.find("a_opt").get("v.value");

		console.log(selectedItem);

		var action = component.get("c.updateSelectedTags");

		action.setParams({
			"contentId": component.get('v.content.Id'),
			"tagId": selectedItem
		});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('selectionAdd: success');

				// Refresh everything
				component.initTags();
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

				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'ContentTagComponent: selectionAdd: Error Message',
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
	},
	selectionRemove : function(component, event, helper){
		
		// Id of the Tag selected
		var selectedItems = component.get("v.selectedTagMappings");

		var action = component.get("c.removeSelectedTags");

		action.setParams({"tempList" : selectedItems});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('selectionRemove: success');

				// Refresh everything
				component.initTags();
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

				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'ContentTagComponent: selectionRemove: Error Message',
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