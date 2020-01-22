/**
 * WMK, LLC (c) - 2018 
 *
 * ContentLearningUtilityHelper
 * 
 * Created By:   Alexander Miller
 * Created Date: 11/15/2018 
 * Work Item:    W-000421
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 * Alexander Miller    AMM1        W-000601       2/25/2019  Update to handle changing the Title automatically
 * Alexander Miller    AMM2        IR-0053017     04/19/2019 Update to not present an error toast when Salesforce itself fails
 */
({
	// AMM1
	initializeNewContentCount : function(component, event, helper)
	{
		console.log('initializeNewContentCount start');

		var action = component.get("c.getNewContentCount");

		action.setParams({"listOfContent": component.get("v.ContenList")});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('initializeNewContentCount success');
				console.dir(response.getReturnValue());

				component.set("v.newContentCount", response.getReturnValue());

				var utilityAPI = component.find("utilitybar");

				utilityAPI.getAllUtilityInfo().then(function(response){

					if(typeof response !== "unedfined")
					{
						if(component.get("v.newContentCount") > 0)
						{
							utilityAPI.setUtilityLabel({label:"OLAF (" + component.get("v.newContentCount") + ")"});
							utilityAPI.setUtilityHighlighted({highlighted: true});
						}
						else
						{
							utilityAPI.setUtilityLabel({label:"OLAF"});
							utilityAPI.setUtilityHighlighted({highlighted: false});
						}
					}
				});
			}
			else if (state === "INCOMPLETE") 
			{
				console.log('initializeNewContentCount incomplete');
            }
			else if (state === "ERROR")
			{
				console.log('initializeNewContentCount error');

				console.log(response);

				console.log(response.getError());

				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'ContentListUtility: initializeNewContentCount: Error Message',
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

			console.log('initializeNewContentCount end');
		});
		
        $A.enqueueAction(action);
	},
	// AMM1
	initializeContentList : function(component, event, helper){
		
		var action = component.get("c.getContentlist");

		action.setParams({"recordId": component.get("v.recordId")});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('success');
				console.dir(response.getReturnValue());

				component.set("v.ContenList", response.getReturnValue());

				// AMM1
				component.checkNewContentCount();
				// AMM1
			}
			else if (state === "INCOMPLETE") 
			{
				console.log('incomplete');
            }
			else if (state === "ERROR")
			{
				// AMM2
				// console.log('error');
				//
				// console.log(response);
				//
				// console.log(response.getError());
				//
				// var toastEvent = $A.get("e.force:showToast");
				// toastEvent.setParams({
				// 	title : 'ContentListUtility: initializeContentList: Error Message',
				// 	message: response.getError(),
				// 	messageTemplate: response.getError(),
				// 	duration:' 5000',
				// 	key: 'info_alt',
				// 	type: 'error',
				// 	mode: 'pester'
				// });
				// toastEvent.fire();

				console.log('ContentListUtility: initializeContentList: error');

				console.log(response);

				console.log(response.getError());

				// AMM2
			}
			
			component.toggleLoadingEnd();

			console.log('end');
		});
		
        $A.enqueueAction(action);
	},
	initializeContentListPageName : function(component, event, helper){
		
		var action = component.get("c.getContentListPageName");

		action.setParams({"pageName": component.get("v.pageName")});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('success');
				console.dir(response.getReturnValue());

				component.set("v.ContenList", response.getReturnValue());

				// AMM1
				component.checkNewContentCount();
				// AMM1
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
					title : 'ContentListUtility: initializeContentListPageName: Error Message',
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
	initializeContentListNewRecord : function(component, event, helper){
		
		var action = component.get("c.getContentListNewRecord");

		action.setParams({"objectName": component.get("v.objectName")});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('success');
				console.dir(response.getReturnValue());

				component.set("v.ContenList", response.getReturnValue());

				// AMM1
				component.checkNewContentCount();
				// AMM1
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
					title : 'ContentListUtility: initializeContentListNewRecord: Error Message',
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
	}
})