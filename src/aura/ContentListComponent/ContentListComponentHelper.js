/**
 * WMK, LLC (c) - 2018 
 *
 * ContentListComponentHelper
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
	initContentList : function(component, event, helper)
	{
		var action = component.get("c.getContentlist");

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('success');
				console.dir(response.getReturnValue());

				component.set("v.ContenList", response.getReturnValue());
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
					title : 'ContentList: initContentList: Error Message',
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
	searchKeyEventFilter : function(component, event, helper){

		var searchVal = component.get("v.searchValue");

		console.log('searchKeyEventFilter: ' + searchVal);

		var action = component.get("c.getFilteredContentList");

		action.setParams({"keyTerm": searchVal});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('success');
				console.dir(response.getReturnValue());

				component.set("v.ContenList", response.getReturnValue());
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
					title : 'ContentList: searchKeyEventFilter: Error Message',
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