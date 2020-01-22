/**
 * WMK, LLC (c) - 2018 
 *
 * ContentTagComponentController
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
	doInit : function(component, event, helper)
	{
		component.set('v.columns', [
			{label: 'Selected Tag', fieldName: 'Tag_Name__c', type: 'text'}
		]);
	},
    // Lightning event updates the chosen Content record
    handleContentEvent : function(component, event, helper){

        var message = event.getParam("selectContent");

		component.set("v.content", message);
		
		component.initTags();
	},
	initContentTagSelected : function(component, event, helper){
		helper.initializeContentTagSelected(component, event, helper);
	},
	initContentTagUnselected : function(component, event, helper){
		helper.initializeContentTagUnselected(component, event, helper);
	},
	tagSelectionAdd : function(component, event, helper){
		helper.selectionAdd(component, event, helper);
	},
	tagSelectionRemove : function(component, event, helper){
		helper.selectionRemove(component, event, helper);
	},
	change : function(component, event, helper)
	{

	},
	tableSelection : function(component, event, helper)
	{
		var selectedRows = event.getParam('selectedRows');

		component.set("v.selectedTagMappings", selectedRows);

		var tempList = component.get("v.selectedTagMappings");

		// Display that fieldName of the selected rows
		for (var i = 0; i < tempList.length; i++){
			console.dir(tempList[i]);
		}
	}
})