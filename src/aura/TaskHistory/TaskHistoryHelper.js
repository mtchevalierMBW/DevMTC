/**
 * WMK, LLC (c) - 2018 
 *
 * TaskHistoryHelper
 * 
 * Created By:   Alexander Miller
 * Created Date: 12/12/2018 
 * Work Item:    W-000516
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */
({
	initTaskData : function(component, event, helper) {
		
		var action = component.get("c.getTasksByParentId");

		action.setParams({"parentId": component.get('v.recordId')});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('TaskHistory: success');
				console.dir(response.getReturnValue());

				var tempResponse = response.getReturnValue();
				
				tempResponse.forEach(function(record){
                    record.linkName = '/'+record.Id;
                });

				const theResponse = tempResponse;
				theResponse.forEach(row => 
				{
						for (const col in row) 
						{
							const curCol = row[col];

							if (typeof curCol === 'object') 
							{
								const newVal = curCol.Id ? ('/' + curCol.Id) : null;
								flattenStructure(row, col + '_', curCol);
								if (newVal === null) 
								{
									delete row[col];
								} 
								else 
								{
									row[col] = newVal;
								}
							}
						}
				});

				function flattenStructure(topObject, prefix, toBeFlattened) 
				{
					for (const prop in toBeFlattened) 
					{
						const curVal = toBeFlattened[prop];
						
						if (typeof curVal === 'object') 
						{
							flattenStructure(topObject, prefix + prop + '_', curVal);
						} 
						else 
						{
							topObject[prefix + prop] = curVal;
					  	}
					}
				}

				component.set("v.data", theResponse);
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
					title : 'TaskHistory: initTaskData: Error Message',
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