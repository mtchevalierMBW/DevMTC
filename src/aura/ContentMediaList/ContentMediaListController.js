/**
 * WMK, LLC (c) - 2018 
 *
 * ContentMediaListController
 * 
 * Created By:   Alexander Miller
 * Created Date: 11/8/2018 
 * Work Item:    W-000421
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */
({
    doInit : function(component, event, helper){
        var url = location.href;  // entire url including querystring - also: window.location.href;
        var baseURL = url.substring(0, url.indexOf('/', 14));
    
        console.log(baseURL);

        component.set("v.sfBaseURL", baseURL + "/");
    },
    // Lightning event updates the chosen Content record
    handleContentEvent : function(component, event, helper){

        var message = event.getParam("selectContent");

        component.set("v.content", message);

        // fire off the tandem Media getter
        component.initMedia();
    },
    // Media record which is the child to the Content record
    initMediaRecord : function(component, event, helper){
        helper.initializeMediaRecord(component, event, helper);
    },
    // Content Document records tied to the Media record
    initContentDocumentList : function(component, event, helper){
        helper.initializeContentDocumentList(component, event, helper);
    },
    reInitContentDocumentList : function(component, event, helper)
    {
        helper.updateContentModified(component, event, helper);
    },
    urlChangeAction : function(component, event, helper)
    {
        component.set("v.mediaURL", component.find("urlInput").get("v.value"));
        helper.urlUpdateHelper(component, event, helper);
    }
})