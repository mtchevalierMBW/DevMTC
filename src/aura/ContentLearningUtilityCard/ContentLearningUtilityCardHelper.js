/**
 * WMK, LLC (c) - 2018 
 *
 * ContentLearningUtilityCardHelper
 * 
 * Created By:   Alexander Miller
 * Created Date: 11/15/2018 
 * Work Item:    W-000421
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 * Alexander Miller    AMM1        W-000607      2/28/2019   Recording when a user views a Content record
 */
({
	initializeVideo : function(component, event, helper){

		var action = component.get("c.getVideoId");

		action.setParams({"contentId": component.get('v.content.Id')});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('initializeVideo: success');
				console.dir(response.getReturnValue());
			
				var myResponse = response.getReturnValue();

				if(myResponse.includes(";") && !myResponse.includes("sharepoint"))
				{
					var splitString = myResponse.split(";");

					component.set("v.videoSource", splitString[0]);
					component.set("v.contentDocumentId", splitString[1]);
				}
				else
				{
					component.set("v.videoSource", myResponse);
				}

				component.newContentMethod();
			}
			else if (state === "INCOMPLETE") 
			{
				console.log('initializeVideo: incomplete');
            }
			else if (state === "ERROR")
			{
				console.log('initializeVideo: error');

				console.log(response);

				console.log(response.getError());

				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'ContentListUtilityCard: initializeVideo: Error Message',
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
	initMediaType : function(component, event, helper)
	{
		var action2 = component.get("c.getMediaRecord");

		action2.setParams({"contentId": component.get('v.content.Id')});

		action2.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('initMediaType: success');
				console.dir(response.getReturnValue());

				var mediaReturned = response.getReturnValue();

				if(mediaReturned.Media_Type__c == 'mp4')
				{
					component.set("v.salesforceFileVideo", true);
				}
				else
				{
					component.set("v.salesforceFileVideo", false);
				}

				component.handleShowModal();
			}
			else if (state === "INCOMPLETE") 
			{
				console.log('initMediaType: incomplete');
			}
			else if (state === "ERROR")
			{
				console.log('initMediaType: error');

				console.log(response);

				console.log(response.getError());

				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'ContentListUtilityCard: initMediaType: Error Message',
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

		$A.enqueueAction(action2);
	},
	isNewContentFunction : function(component, event, helper)
	{
		var action = component.get("c.isContentNew");

		action.setParams({"contentId": component.get('v.content.Id')});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('isNewContentFunction: success');
				console.dir(response.getReturnValue()); 

				component.set("v.isNewContent", response.getReturnValue());
			}
			else if (state === "INCOMPLETE") 
			{
				console.log('isNewContentFunction: incomplete');
			}
			else if (state === "ERROR")
			{
				console.log('isNewContentFunction: error');

				console.log(response);

				console.log(response.getError());

				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'ContentListUtilityCard: isNewContentFunction: Error Message',
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
	// AMM1
	helperRecordContentView : function(component, event, helper)
	{
		var action = component.get("c.recordContentView");

		action.setParams({"ContentId": component.get('v.content.Id')});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('helperRecordContentView: success');
				console.dir(response.getReturnValue()); 
			}
			else if (state === "INCOMPLETE") 
			{
				console.log('helperRecordContentView: incomplete');
			}
			else if (state === "ERROR")
			{
				console.log('helperRecordContentView: error');

				console.log(response);

				console.log(response.getError());

				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'ContentListUtilityCard: helperRecordContentView: Error Message',
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
	// AMM1
})