/**
 * WMK, LLC (c) - 2018 
 *
 * ContentObjectFieldMappingComponentHelper
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
	initializeOperatorList : function(component, event, helper) {
		
		var action = component.get("c.getObjectFieldOperators");

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('initializeOperatorList: success');
				console.dir(response.getReturnValue());

				component.set("v.operatorList", response.getReturnValue());
			}
			else if (state === "INCOMPLETE") 
			{
				console.log('initializeOperatorList: incomplete');
            }
			else if (state === "ERROR")
			{
				console.log('initializeOperatorList: error');

				console.log(response);

				console.log(response.getError());

				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'ContentObjectFieldMapping: initializeOperatorList: Error Message',
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
	initializeObjectList : function(component, event, helper) {
		
		var action = component.get("c.getObjectNames");

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('initializeObjectList: success');
				console.dir(response.getReturnValue());

				component.set("v.objectList", response.getReturnValue());

				component.initOperators();
			}
			else if (state === "INCOMPLETE") 
			{
				console.log('initializeObjectList: incomplete');
            }
			else if (state === "ERROR")
			{
				console.log('initializeObjectList: error');

				console.log(response);

				console.log(response.getError());

				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'ContentObjectFieldMapping: initializeObjectList: Error Message',
					message: response.getError(),
					messageTemplate: response.getError(),
					duration:' 5000',
					key: 'info_alt',
					type: 'error',
					mode: 'pester'
				});
				toastEvent.fire();
			}
			
			component.toggleLoadingEnd();

			console.log('end');
		});
		
        $A.enqueueAction(action);
	},
	initializeObjectFieldList : function(component, event, helper) {
		
		var nullList = [];
		component.set("v.fieldList", nullList);

		var action = component.get("c.getObjectFields");

		console.log(component.get('v.currentObject'));

		action.setParams({"objectName": component.get('v.currentObject')});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('initializeObjectFieldList: success');
				console.dir(response.getReturnValue());

				component.set("v.fieldList", response.getReturnValue());
			}
			else if (state === "INCOMPLETE") 
			{
				console.log('initializeObjectFieldList: incomplete');
            }
			else if (state === "ERROR")
			{
				console.log('initializeObjectFieldList: error');

				console.log(response);

				console.log(response.getError());

				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'ContentObjectFieldMapping: initializeObjectFieldList: Error Message',
					message: response.getError(),
					messageTemplate: response.getError(),
					duration:' 5000',
					key: 'info_alt',
					type: 'error',
					mode: 'pester'
				});
				toastEvent.fire();
			}

			component.find("b_opt").set("v.disabled", false);
			component.find("c_opt").set("v.disabled", false);
			component.set("v.objectFieldInputDisabled", false); 

			component.toggleLoadingEnd();

			console.log('end');
		});
		
        $A.enqueueAction(action);
	},
	mapSelectionAdd : function(component, event, helper) {
		
		var action = component.get("c.createContentObjectMapping");

		var objectField = component.find("b_opt").get("v.value");
		var objectFieldOperator = component.find("c_opt").get("v.value");
		var objectFieldValue = component.get("v.fieldValueInput");
		console.log("object: " + component.get('v.currentObject'));
		console.log("objectFieldValue: " + objectFieldValue);

		action.setParams({
			"contentId": component.get('v.content.Id'),
			"objectName": component.get('v.currentObject'),
			"objectFieldName": objectField,
			"objectOperator": objectFieldOperator,
			"operatorValue": objectFieldValue
		});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('mappSelectionAdd: success');
				console.dir(response.getReturnValue());

				component.set("v.fieldList", response.getReturnValue());

				component.initMapping();
			}
			else if (state === "INCOMPLETE") 
			{
				console.log('mappSelectionAdd: incomplete');
            }
			else if (state === "ERROR")
			{
				console.log('mappSelectionAdd: error');

				console.log(response);

				console.log(response.getError());

				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'ContentObjectFieldMapping: mapSelectionAdd: Error Message',
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
	mapSelectionPageAdd : function(component, event, helper) {
		
		var action = component.get("c.createContentObjectPageMapping");

		action.setParams({
			"contentId": component.get('v.content.Id'),
			"pageName": component.get('v.pageValueInput')
		});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('mapSelectionPageAdd: success');
				console.dir(response.getReturnValue());

				component.set("v.fieldList", response.getReturnValue());

				component.initMapping();
			}
			else if (state === "INCOMPLETE") 
			{
				console.log('mapSelectionPageAdd: incomplete');
            }
			else if (state === "ERROR")
			{
				console.log('mapSelectionPageAdd: error');

				console.log(response);

				console.log(response.getError());

				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'ContentObjectFieldMapping: mapSelectionPageAdd: Error Message',
					message: response.getError(),
					messageTemplate: response.getError(),
					duration:' 5000',
					key: 'info_alt',
					type: 'error',
					mode: 'pester'
				});
				toastEvent.fire();
			}

			component.toggleLoadingEnd();
			
			console.log('end');
		});
		
        $A.enqueueAction(action);
	},
	mapSelectionNewRecordAdd : function(component, event, helper) {
		
		var action = component.get("c.createContentObjectNewRecordMapping");

		var objectName = component.get("v.currentObject");

		var contentId = component.get('v.content.Id');

		console.log('mapSelectionNewRecordAdd: Object Name ' + objectName);
		
		action.setParams({
			"contentId": contentId,
			"objectName": objectName
		});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('mapSelectionNewRecordAdd: success');
				console.dir(response.getReturnValue());

				component.set("v.fieldList", response.getReturnValue());

				component.initMapping();
			}
			else if (state === "INCOMPLETE") 
			{
				console.log('mapSelectionNewRecordAdd: incomplete');
            }
			else if (state === "ERROR")
			{
				console.log('mapSelectionNewRecordAdd: error');

				console.log(response);

				console.log(response.getError());

				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'ContentObjectFieldMapping: mapSelectionNewRecordAdd: Error Message',
					message: response.getError(),
					messageTemplate: response.getError(),
					duration:' 5000',
					key: 'info_alt',
					type: 'error',
					mode: 'pester'
				});
				toastEvent.fire();
			}

			component.toggleLoadingEnd();
			
			console.log('end');
		});
		
        $A.enqueueAction(action);
	},
	mapSelectionRemove : function(component, event, helper) {
		
		var action = component.get("c.deleteContentObjectMapping");

		var listOfObjectDeletions = component.get("v.selectedObjectMappings");

		console.dir(listOfObjectDeletions);

		action.setParams({"listContentObjectFieldId": listOfObjectDeletions});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('mapSelectionRemove: success');
				console.dir(response.getReturnValue());

				component.initMapping();
			}
			else if (state === "INCOMPLETE") 
			{
				console.log('mapSelectionRemove: incomplete');
            }
			else if (state === "ERROR")
			{
				console.log('mapSelectionRemove: error');

				console.log(response);

				console.log(response.getError());

				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'ContentObjectFieldMapping: mapSelectionRemove: Error Message',
					message: response.getError(),
					messageTemplate: response.getError(),
					duration:' 5000',
					key: 'info_alt',
					type: 'error',
					mode: 'pester'
				});
				toastEvent.fire();
			}
			
			component.toggleLoadingEnd();

			console.log('end');
		});
		
        $A.enqueueAction(action);
	},
	objectFieldInit : function(component, event, helper) {

		var action = component.get("c.getContentObjectFieldList");

		action.setParams({"contentId": component.get('v.content.Id')});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('objectFieldInit: success');
				console.dir(response.getReturnValue());

				component.set("v.contentObjectFieldList", response.getReturnValue());
			}
			else if (state === "INCOMPLETE") 
			{
				console.log('objectFieldInit: incomplete');
            }
			else if (state === "ERROR")
			{
				console.log('objectFieldInit: error');

				console.log(response);

				console.log(response.getError());

				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'ContentObjectFieldMapping: objectFieldInit: Error Message',
					message: response.getError(),
					messageTemplate: response.getError(),
					duration:' 5000',
					key: 'info_alt',
					type: 'error',
					mode: 'pester'
				});
				toastEvent.fire();
			}
			
			component.toggleLoadingEnd();

			console.log('end');
		});
		
        $A.enqueueAction(action);
	},
})