/**
 * WMK, LLC (c) - 2018 
 *
 * ContentListComponentController
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
	doInit : function(component, event, helper)
	{
		helper.initContentList(component, event, helper);
	},
	searchKeyChange: function(component, event, helper) {
		
		var message = event.getParam("contentFiler");

		console.log("searchKeyChange: " + message);

		if(message && message.length > 1)
		{
			component.set("v.searchValue", message);

			helper.searchKeyEventFilter(component, event, helper);
		}
		else
		{
			helper.initContentList(component, event, helper);
		}
    }
})