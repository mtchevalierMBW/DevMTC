/**
 * WMK, LLC (c) - 2019 
 *
 * ContentProfileSelectorHelper
 * 
 * Created By:    Alexander Miller
 * Created Date:  03/26/2019 
 * Work Item:     W-000578
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 */
({
	initCurrentMappings : function(component, event, helper) {
		
		var action = component.get("c.getCurrentContentProfiles");

		action.setParams({"contentId": component.get("v.content").Id});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('initCurrentMappings: success');
				console.dir(response.getReturnValue());

				component.set("v.currentProfiles", response.getReturnValue());

				// remove it from the available list
				var currentList = component.get("v.profiles");

				for(var i = 0; i < response.getReturnValue().length; i++)
				{
					var index = currentList.indexOf(response.getReturnValue()[i].Profile_Name__c);
					if (index > -1) {
						currentList.splice(index, 1);
					}
				}
				
				console.log('initCurrentMappings : testing removals');
				console.dir(currentList);
				
				component.set("v.profiles", currentList);
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
					title : 'ContentProfileSelectorHelper: initCurrentMappings: Error Message',
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
	initActiveProfiles : function(component, event, helper)
	{
		var action = component.get("c.getActiveProfiles");

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('initActiveProfiles: success');
				console.dir(response.getReturnValue());
				
				var availableProfiles = response.getReturnValue();
				
				component.set("v.profiles", availableProfiles);

				component.initCurrent();
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
					title : 'ContentProfileSelectorHelper: initActiveProfiles: Error Message',
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

		var selectedItemSearch = component.get("v.selectedProfilePersonSearch");

		console.log(selectedItemSearch);

		var finalValue;

		if(selectedItem == null || selectedItem == '')
		{
			finalValue = selectedItemSearch;
		}
		else
		{
			finalValue = selectedItem;
		}

		console.log(finalValue);

		var action = component.get("c.insertContentProfile");

		action.setParams({
			"contentId": component.get('v.content.Id'),
			"profileName": finalValue
		});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('selectionAdd: success');

				component.set("v.selectedProfilePersonSearch", null);

				// remove it from the available list
				component.initAllProfiles();
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
					title : 'ContentProfileSelector: selectionAdd: Error Message',
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
		var selectedItems = component.get("v.selectedProfileMappings");

		var action = component.get("c.removeContentProfile");

		action.setParams({
			"listOfProfileNames" : selectedItems
		});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('selectionRemove: success');

				// Refresh everything
				component.initAllProfiles();
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
					title : 'ContentProfileSelector: selectionRemove: Error Message',
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
	personProfileSearch : function(component, event, helper)
	{
		var personValue = component.get("v.personTypeText");

		console.log(personValue);

		var action = component.get("c.getUsersByName");

		action.setParams({
			"name" : personValue
		});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('personProfileSearch: success');

				// Refresh everything
				component.set('v.personList', response.getReturnValue());
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
					title : 'ContentProfileSelector: personProfileSearch: Error Message',
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
	personSelectedProfileSet : function(component, event, helper)
	{
		var selectedRows = event.getParam('selectedRows');

		var action = component.get("c.getProfileNameByUser");

		action.setParams({
			"userId" : selectedRows[0].Id
		});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('personSelectedProfileSet: success');

				// Refresh everything
				component.set("v.selectedProfilePersonSearch", response.getReturnValue());
				console.log(component.get("v.selectedProfilePersonSearch"));
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
					title : 'ContentProfileSelector: personSelectedProfileSet: Error Message',
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
	initUsersByProfileSelection : function(component, event, helper)
	{
		var selectedItem = component.find("a_opt").get("v.value");
		
		console.log(selectedItem);

		var action = component.get("c.getUsersByProfile");

		action.setParams({
			"profileName" : selectedItem
		});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('initUsersByProfileSelection: success');

				// Refresh everything
				component.set("v.personList", response.getReturnValue());
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
					title : 'ContentProfileSelector: initUsersByProfileSelection: Error Message',
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