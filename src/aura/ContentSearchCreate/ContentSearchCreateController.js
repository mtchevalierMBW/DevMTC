/**
 * WMK, LLC (c) - 2018 
 *
 * ContentSearchCreateController
 * 
 * Created By:   Alexander Miller
 * Created Date: 11/26/2018 
 * Work Item:    W-000421
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */
({
	setAttritbuteAction : function(component, event, helper)
	{
		component.set("v.contentTitle", component.find("titleInput").get("v.value"));
		component.set("v.contentDescription", component.find("descriptionInput").get("v.value"));
	},
	searchAction : function(component, event, helper)
	{		
		helper.fireFilterEvent(component, event, helper);	
		helper.fireContentEvent(component, event, helper);
	},
	newRecordAction : function(component, event, helper){
		component.set("v.isOpen", true);
	},   
	closeModel: function(component, event, helper) {
		component.set("v.isOpen", false);
	},
	closeModelAndCreateRecords : function(component, event, helper)
	{
		helper.createParentContentRecord(component, event, helper);
	}
})