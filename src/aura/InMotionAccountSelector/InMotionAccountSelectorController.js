/**
 * WMK, LLC (c) - 2019
 *
 * InMotionAccountSelectorController
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
	doInit : function(component, event, helper) {},
	barcodeChange : function(component, event, helper)
	{
		var barcodeValue = component.get("v.barcodeValue");
		console.log("barcodeValue: "+barcodeValue);

		if(barcodeValue !== undefined && barcodeValue !== null &&
			barcodeValue != undefined && barcodeValue != null &&
			barcodeValue != '')
		{
			helper.barcodeChangeHelper(component, event, helper);
		}
	},
	globalEventAccountCampaign : function(component, event, helper)
	{
		// if both aren't null, then fire application update
		// to refresh questionnaire screen
		var campaign = component.get('v.campaignValue');
		var account = component.get('v.account');

		if(campaign !== undefined && account !== undefined && 
			campaign !== null && account !== null && 
			campaign != null && account != null && 
			campaign != '' && account != '')
		{
			var appEvent = $A.get("e.c:InMotionAccountCampaignEvent");
			appEvent.setParams({"inMotionAccount" : account.Id});
			appEvent.setParams({"inMotionCampaign" : campaign});
			appEvent.fire();
		}

		if(account !== undefined && account !== null && account != null)
		{
			helper.loadAccountInfo(component, event, helper);
		}
	},
	openAccount : function(component, event, helper)
	{
		var accountId = component.get('v.account').Id;

		console.log(accountId);

		var navEvt = $A.get("e.force:navigateToSObject");
		navEvt.setParams({
		  "recordId": accountId,
		  "slideDevName": "Detail"
		});
		navEvt.fire();
	}
})