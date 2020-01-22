/**
 * WMK, LLC (c) - 2018 
 *
 * ContentMediaListHelper
 * 
 * Created By:   Alexander Miller
 * Created Date: 11/8/2018 
 * Work Item:    W-000421
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */
({
	initializeMediaRecord : function(component, event, helper){

		var action = component.get("c.getMediaRecord");

		action.setParams({"contentId": component.get('v.content.Id')});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('initializeMediaRecord: success');
				console.dir(response.getReturnValue());

				component.set("v.media", response.getReturnValue());

				var mediaRecord = component.get("v.media");

				console.dir(mediaRecord);

				component.set("v.mediaURL", mediaRecord.Video_URL__c);

				// call tandem Content Document query function in the component
				component.initContentDocuments();
			}
			else if (state === "INCOMPLETE") 
			{
				console.log('initializeMediaRecord: incomplete');
            }
			else if (state === "ERROR")
			{
				console.log('initializeMediaRecord: error');

				console.log(response);

				console.log(response.getError());

				component.set("v.media", null);
				component.set("v.contentDocumentList", null);

				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'ContentMediaList: initializeMediaRecord: Error Message',
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
	initializeContentDocumentList : function(component, event, helper){
		
		var action = component.get("c.getContentDocumentList");

		action.setParams({"contentMediaId": component.get('v.media.Id')});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('success');
				console.dir(response.getReturnValue());

				var listOfDocuments = response.getReturnValue();

				var activeElement = listOfDocuments.shift();

				component.set("v.contentDocumentActive", activeElement);

				component.set("v.contentDocumentList", listOfDocuments);
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

				component.set("v.contentDocumentList", null);

				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'ContentMediaList: initializeContentDocumentList: Error Message',
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
	updateContentModified : function(component, event, helper)
	{
		var action = component.get("c.updateContentForMostRecentEdit");

		action.setParams({"contentId": component.get('v.content.Id')});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('success');

				component.initContentDocuments();
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

				component.set("v.contentDocumentList", null);

				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'ContentMediaList: updateContentModified: Error Message',
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
	urlUpdateHelper : function(component, event, helper)
	{
		var action = component.get("c.updateMediaURL");

		var mediaURL = component.get("v.mediaURL");

		console.log("urlUpdateHelper in here");

		// code to make Microsoft Sharepoint Documents (Doc, PPXT) links work
		if(mediaURL.includes('sharepoint') && mediaURL.includes('sourcedoc'))
		{
			// break out the iframe paste into its true URL
			var splitStrings = mediaURL.split('"');

			for(var i = 0; i < splitStrings.length; i++)
			{
				if(splitStrings[i].includes('sharepoint'))
				{
					// replace the html "&amp;" to make the URLs work
					mediaURL = splitStrings[i].split('&amp;').join('&');
					break;
				}
			}

			console.log(mediaURL);

			component.set("v.mediaURL", mediaURL);
			component.find("urlInput").set("v.value", mediaURL);
		}
		// code to make Microsoft Sharepoint video links work
		else if(mediaURL.includes('sharepoint') && !mediaURL.endsWith('&download=1'))
		{
			mediaURL = mediaURL + '&download=1';
			component.set("v.mediaURL", mediaURL);
			component.find("urlInput").set("v.value", mediaURL);

			console.log("urlUpdateHelper: mediaURL: " + component.get("v.mediaURL"));
		} 
		// code to make YouTube video links work
		else if(mediaURL.includes('youtube') && !mediaURL.includes('embed'))
		{
			const urlParams = new URLSearchParams(mediaURL);
			const myParam = urlParams.get('v');

			console.log(myParam);

			mediaURL = 'https://www.youtube/embed/' + myParam;

			console.log(mediaURL);

			component.set("v.mediaURL", mediaURL);
			component.find("urlInput").set("v.value", mediaURL);
		}

		action.setParams({
			"mediaId": component.get('v.media.Id'),
			"urlParam" : mediaURL,
			"contentId": component.get('v.content.Id')
		});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('urlUpdateHelper: success');
				console.dir(response.getReturnValue());
			}
			else if (state === "INCOMPLETE") 
			{
				console.log('urlUpdateHelper: incomplete');
            }
			else if (state === "ERROR")
			{
				console.log('urlUpdateHelper: error');

				console.log(response);

				console.log(response.getError());

				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'ContentMediaList: urlUpdateHelper: Error Message',
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