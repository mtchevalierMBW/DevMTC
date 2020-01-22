/**
 * WMK, LLC (c) - 2018 
 *
 * ContnetobjectFieldMappingComponentController
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
		component.toggleLoadingStart();

		component.set('v.columns', [
			{label: 'New', fieldName: 'New_Record_Page__c', type: 'boolean'},
			{label: 'Page', fieldName: 'Page_Name__c', type: 'text'},
			{label: 'Name', fieldName: 'Object_Name__c', type: 'text'},
			{label: 'Field', fieldName: 'Object_Field_Name__c', type: 'text'},
			{label: 'Operator', fieldName: 'Operator__c', type: 'text'},
			{label: 'Value', fieldName: 'Value__c', type: 'text'}
		]);

		helper.initializeObjectList(component, event, helper);
	},
    // Lightning event updates the chosen Content record
    handleContentEvent : function(component, event, helper){

        var message = event.getParam("selectContent");

		component.set("v.content", message);

		component.initMapping();
	},
	initOperatorList : function(component, event, helper){
		helper.initializeOperatorList(component, event, helper);
	},
	initFieldList : function(component, event, helper){

		// Set the input to disabled for visual feedback
		component.find("b_opt").set("v.disabled", true);
		component.find("c_opt").set("v.disabled", true);
		component.set("v.objectFieldInputDisabled", true); 

		helper.initializeObjectFieldList(component, event, helper);
	},
	objectSelectionChange : function(component, event, helper){

		component.toggleLoadingStart();

		var objectValue = component.find("a_opt").get("v.value");

		console.log('objectValue: ' + objectValue);

		component.set("v.currentObject", objectValue);

		console.log(component.get("v.currentObject"));

		component.initFields();
	},
	mappingSelectionAdd : function(component, event, helper){
		helper.mapSelectionAdd(component, event, helper);
	},
	mappingSelectionNewRecordAdd : function(component, event, helper){
		helper.mapSelectionNewRecordAdd(component, event, helper);
	},
	mappingSelectionPageAdd : function(component, event, helper){
		helper.mapSelectionPageAdd(component, event, helper);
	},
	mappingSelectionRemove : function(component, event, helper){

		component.toggleLoadingStart();

		helper.mapSelectionRemove(component, event, helper);
	},
	initializeObjectField : function(component, event, helper){
		
		component.toggleLoadingStart();

		helper.objectFieldInit(component, event, helper);
	},
	change : function(component, event, helper){},
	updateSelectedText : function (component, event, helper) {
        var selectedRows = event.getParam('selectedRows'); 
        for (var i = 0; i < selectedRows.length; i++){
            console.log(selectedRows[i].Id);          
        }
	},
	addRule : function(component, event, helper){

		component.toggleLoadingStart();

		// check which checkbox is selected
		var radioViewType = component.get("v.radioViewType");

		var radioObjectType = component.get("v.radioObject");

		var radioPageType = component.get("v.radioPage");

		// send it off to be processed appropriately
		if(radioViewType === radioObjectType)
		{
			// check if new record or regular mapping
			var isNewRecordMarking = component.get("v.newRecordBool");

			console.log(isNewRecordMarking);

			if(isNewRecordMarking === true)
			{
				component.addNewObejctMapping();
			}
			else
			{
				component.addObjectMapping();
			}
		}
		else if(radioViewType === radioPageType)
		{
			component.addPageMapping();
		}
	},
	newRecordCheckboxSelected : function(component, event, helper){
		
		// disable the field, operator, and value section 
		var checkboxVal = event.getSource().get("v.value");

		console.log(checkboxVal);
		
		if(checkboxVal)
		{
			component.find("b_opt").set("v.disabled", true);
			component.find("c_opt").set("v.disabled", true);
			component.set("v.objectFieldInputDisabled", true); 
			component.set("v.newRecordBool", true);
		}
		else
		{
			component.find("b_opt").set("v.disabled", false);
			component.find("c_opt").set("v.disabled", false);
			component.set("v.objectFieldInputDisabled", false); 
			component.set("v.newRecordBool", false);
		}
	},
	toggleLoadingStart : function(component, event, helper)
	{
		component.set("v.showLoading", true);
	},
	toggleLoadingEnd : function(component, event, helper)
	{
		component.set("v.showLoading", false);
	},
	tableSelection : function(component, event, helper)
	{
		var selectedRows = event.getParam('selectedRows');

		component.set("v.selectedObjectMappings", selectedRows);

		var tempList = component.get("v.selectedObjectMappings");

		// Display that fieldName of the selected rows
		for (var i = 0; i < tempList.length; i++){
			console.dir(tempList[i]);
		}
	}
})