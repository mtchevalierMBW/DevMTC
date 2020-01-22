/**
 * WMK, LLC (c) - 2018 
 *
 * ContentCardController
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
	updateContentEvent : function(component, event, helper){

		var contentRecord = component.get("v.content");

		var appEvent = $A.get("e.c:ContentEvent");
        appEvent.setParams({"selectContent" : contentRecord});
		appEvent.fire();
	}
})