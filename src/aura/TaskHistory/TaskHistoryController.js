/**
 * WMK, LLC (c) - 2018 
 *
 * TaskHistoryController
 * 
 * Created By:   Alexander Miller
 * Created Date: 12/12/2018 
 * Work Item:    W-000516
 *
 * Modified By         Alias       Work Item       Date        Reason
 * -----------------------------------------------------------------
 * Alexander Miller     AMM1       IR-0049339      2/19/2019   The date interpreted by JavaScript wasn't accounting for the user's time zone
 */
({
	doInit : function(component, event, helper)
	{
		// http://www.infallibletechie.com/2018/07/how-to-hyperlink-record-in.html
		component.set('v.columns', [
			{label: 'Subject', fieldName: 'linkName', type: 'url',
				typeAttributes: {label: {fieldName: 'Subject'}, target: '_blank'}},
			// AMM1
			// {label: 'Due Date', fieldName: 'ActivityDate', type: 'date'},
			{label: 'Due Date', fieldName: 'ActivityDate', type: 'date-local'},
			// AMM1
			{label: 'Assigned To', fieldName: 'Owner_Name', type: 'text'},
			{label: 'Related To', fieldName: 'What_Name', type: 'text'},
			{label: 'Description', fieldName: 'Description', type: 'text'},
			{label: 'Last Modified', fieldName: 'LastModifiedDate', type: 'date'}
		]);

		helper.initTaskData(component, event, helper);
	}
})