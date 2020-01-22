/**
 * WMK, LLC (c) - 2019 
 *
 * ContentProfileSelectorController
 * 
 * Created By:    Alexander Miller
 * Created Date:  03/26/2019 
 * Work Item:     W-000578
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 */
({
	doInit : function(component, event, helper){

		component.set('v.columns', [
			{label: 'Selected Profile', fieldName: 'Profile_Name__c', type: 'text'}
		]);

		component.set('v.personColumns', [
			{label: 'User', fieldName: 'Name', type: 'text'}
		]);

		component.initAllProfiles();
	},
	initializeProfiles : function(component, event, helper)
	{
		helper.initActiveProfiles(component, event, helper);
	},
    // Lightning event updates the chosen Content record
    handleContentEvent : function(component, event, helper){

        var message = event.getParam("selectContent");

        component.set("v.content", message);

        // fire off the tandem Mapping Getter
        component.initCurrent();
	},
	handleCurrentMappings : function(component, event, helper)
	{
		helper.initCurrentMappings(component, event, helper);
    },
	profileSelectionAdd : function(component, event, helper){
		component.set('v.personList', null);
		helper.selectionAdd(component, event, helper);
	},
	profileSelectionRemove : function(component, event, helper){
		component.set("v.selectedProfilePersonSearch", null);
		component.set('v.personList', null);
		helper.selectionRemove(component, event, helper);
	},
    tableSelection : function(component, event, helper)
	{
		var selectedRows = event.getParam('selectedRows');

		component.set("v.selectedProfileMappings", selectedRows);
	},
	personProfileSearchChange : function(component, event, helper)	
	{	
		helper.personProfileSearch(component, event, helper);
	},
	personSearchSelected : function(component, event, helper)
	{
		var selectedRows = event.getParam('selectedRows');

		console.log(selectedRows);

		if(selectedRows !== undefined && selectedRows != undefined && selectedRows !== null && selectedRows != null && selectedRows != '')
		{
			helper.personSelectedProfileSet(component, event, helper);
		}
	},
	selectionChange : function(component, event, helper)
	{
		var selectedItem = component.find("a_opt").get("v.value");
		
		console.log(selectedItem);

		if(selectedItem !== undefined && selectedItem != undefined && selectedItem !== null && selectedItem != null && selectedItem != '')
		{
			helper.initUsersByProfileSelection(component, event, helper);
		}
	}
})