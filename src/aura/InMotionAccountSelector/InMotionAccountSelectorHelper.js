/**
 * WMK, LLC (c) - 2019
 *
 * InMotionAccountSelectorHelper
 * 
 * Created By:   Alexander Miller
 * Created Date: 2/25/2018 
 * Work Item:    W-000603
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */
({
	barcodeChangeHelper : function(component, event, helper) 
	{
		var action = component.get("c.getAccountByNumber");

		action.setParams({"accountNumber": component.get("v.barcodeValue")});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('success');
				console.dir(response.getReturnValue());

				if(response.getReturnValue() != null)
				{
					component.set("v.account", response.getReturnValue());
					component.find("accountLookup").set("v.value", response.getReturnValue().Id);

					component.accountCampiagnModified();
				}
				else
				{
					var toastEvent = $A.get("e.force:showToast");
					toastEvent.setParams({
						title : 'Warning: No Accounts Found by Barcode',
						message: 'No Accounts Found by Barcode',
						messageTemplate: 'No Accounts Found by Barcode',
						duration:' 5000',
						key: 'info_alt',
						type: 'warning',
						mode: 'pester'
					});
					toastEvent.fire();
				}
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
					title : 'InMotionAccountSelectorHelper: barcodeChangeHelper: Error Message',
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
	loadAccountInfo : function(component, event, helper)
	{
		var action = component.get("c.getAccountById");

		var accountId = component.get("v.account").Id;

		action.setParams({"accountId": accountId});

		action.setCallback(this, function(response) 
		{
			var state = response.getState();

			if(component.isValid() && state == "SUCCESS")
			{
				console.log('success');
				console.dir(response.getReturnValue());

				component.set("v.account", response.getReturnValue());
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
					title : 'InMotionAccountSelectorHelper: loadAccountInfo: Error Message',
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