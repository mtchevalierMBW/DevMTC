/**
 * WMK, LLC (c) - 2018 
 *
 * ContentLearningUtilityController
 * 
 * Created By:   Alexander Miller
 * Created Date: 11/15/2018 
 * Work Item:    W-000421
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 * Alexander Miller    AMM1        W-000568       2/04/2019  Update to handle all page routing in simplest form
 * Alexander Miller    AMM2        W-000601       2/25/2019  Update to handle changing the Title automatically
 * Alexander Miller    AMM3        W-000592       2/28/2019  Update to make it home-page friendly
 * Alexander Miller    AMM4        IR-0053017     04/19/2019 Update to not present an error toast when Salesforce itself fails
 */
({
    doInit : function(component, event, helper){
        
        // AMM4
        component.set('v.userURL', window.location.href);
        component.set('v.errorMessage', 'test error message');
        // AMM4

        component.toggleLoadingStart();

        // AMM2
        component.checkNewContentCount();
        // AMM2
    },
    // AMM2
    initNewCount : function(component, event, helper)
    {
        if(component.get("v.ContenList") != null && component.get("v.ContenList").length > 0)
        {   
            helper.initializeNewContentCount(component, event, helper);
        }
    },
    // AMM2
    // AMM1
    update : function (component, event, helper) {
        // Get the new hash from the event
        
        var newRecordId = component.get("v.recordId");
        
        console.log("recordId: " + newRecordId);

        console.log(window.location.href);

        console.log(window.location.pathname);

        component.set("v.ContenList", null);

        // 1. Record Id is not null so load a list
        if(newRecordId)
        {
            helper.initializeContentList(component, event, helper);
        }
        // 2. Its a page
        else
        {
            var pageSplit = window.location.pathname.split("/");

            var pageType = pageSplit[2];

            var urlValue = pageSplit[3];

            console.log(pageType);
            console.log(pageSplit);
            console.log(urlValue);

            // 2.1 its a new record page
            if(pageType === "o" )
            {
                component.set("v.objectName", urlValue);
                helper.initializeContentListNewRecord(component, event, helper);
            }
            // 2.2 its a VF page
            // AMM3
            //else if(pageType === "n")
            else if(pageType === "n" || urlValue === "home")
            // AMM3
            {
                component.set("v.pageName", urlValue);
                helper.initializeContentListPageName(component, event, helper);
            }          
        }
    },
    // AMM1
    onRecordIdChange : function(component, event, helper) {
        
        var newRecordId = component.get("v.recordId");
        
        console.log("recordId: " + newRecordId);

        console.log(window.location.href);

        console.log(window.location.pathname);

        component.set("v.ContenList", null);

        // 1. Record Id is not null so load a list
        if(newRecordId)
        {
            helper.initializeContentList(component, event, helper);
        }
        // 2. Its a page
        else
        {
            var pageSplit = window.location.pathname.split("/");

            var pageType = pageSplit[2];

            var urlValue = pageSplit[3];

            console.log(pageType);
            console.log(pageSplit);
            console.log(urlValue);

            // 2.1 its a new record page
            if(pageType === "o" )
            {
                component.set("v.objectName", urlValue);
                helper.initializeContentListNewRecord(component, event, helper);
            }
            // 2.2 its a VF page
            else if(pageType === "n")
            {
                component.set("v.pageName", urlValue);
                helper.initializeContentListPageName(component, event, helper);
            }            
        }
    },
    toggleLoadingStart : function(component, event, helper)
	{
		component.set("v.showLoading", true);
	},
	toggleLoadingEnd : function(component, event, helper)
	{
		component.set("v.showLoading", false);
	}
})