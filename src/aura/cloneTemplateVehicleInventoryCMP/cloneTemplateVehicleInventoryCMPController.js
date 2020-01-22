({
	doInit : function(component, event, helper){},
	// Make sure the VIN is 17 characters long before allowing submission
	keyCheckVin : function(component, event, helper)
	{		
		var vinValue = component.get("v.vinValue");

		var button = component.find('disablebuttonid');

		if(vinValue !== undefined && vinValue !== null && vinValue.length === 17)
		{
			button.set('v.disabled', false);
		}
		else
		{
			button.set('v.disabled', true);
		}
	},
	cloneTemplateController : function(component, event, helper)
	{
		helper.cloneTemplateHelper(component, event, helper);
	},
})