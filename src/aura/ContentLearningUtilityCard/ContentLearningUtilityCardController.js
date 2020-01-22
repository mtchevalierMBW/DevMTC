/**
 * WMK, LLC (c) - 2018 
 *
 * ContentLearningUtilityCardController
 * 
 * Created By:   Alexander Miller
 * Created Date: 11/15/2018 
 * Work Item:    W-000421
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 * Alexander Miller    AMM1        W-000607      2/28/2019   Recording when a user views a Content record
 */
({
	doInit : function(component, event, helper) {
		helper.initializeVideo(component, event, helper);
    },
    defineIfNewContent : function(component, event, helper)
    {
        helper.isNewContentFunction(component, event, helper);
    },
    defineMediaType : function(component, event, helper)
    {
        helper.initMediaType(component, event, helper);
    },
    handleShowModal: function(component, event, helper) {

        var modalBody;

        var contentRecord = component.get("v.content");
        var videoId = component.get("v.videoSource");
        var isSalesforceVideo = component.get("v.salesforceFileVideo");

        console.dir(contentRecord);
        console.log("videoId: " + videoId);
        console.log("isSalesforceVideo: " + isSalesforceVideo);

        // Video player modal
        if(isSalesforceVideo == true && (videoId.length == 15 || videoId.length == 18))
        {
            console.log("ContentLearningUtilityCard: video player option");

            var videoId = "https://" + window.location.hostname + '/sfc/servlet.shepherd/version/download/' + videoId;

            console.log(videoId);

            $A.createComponent("c:ContentVideoPlayer",
            {
                "content": contentRecord,
                "videoSource" : videoId
            },
            function(content, status) 
            {
                if (status === "SUCCESS") 
                {
                    modalBody = content;
                    component.find('overlayLib').showCustomModal({
                        header: component.get("v.content.Title__c"),
                        body: modalBody, 
                        showCloseButton: true,
                        cssClass: "mymodal",
                        closeCallback: function() {}
                    })
                }                               
            });
        }
        // share link iframe
        else if(videoId.length > 18)
        {
            console.log("ContentLearningUtilityCard: share link");

            console.log(videoId);

            $A.createComponent("c:ContentDocumentModal",
            {
                "fileSource" : videoId
            },
            function(content, status) 
            {
                if (status === "SUCCESS") 
                {
                    modalBody = content;
                    component.find('overlayLib').showCustomModal({
                        header: component.get("v.content.Title__c"),
                        body: modalBody, 
                        showCloseButton: true,
                        cssClass: "mymodal",
                        closeCallback: function() {}
                    })
                }                               
            });
        }
        // just open natively file viewer from Salesforce
        else if(isSalesforceVideo == false && (videoId.length == 15 || videoId.length == 18))
        {
            console.log("ContentLearningUtilityCard: open file");

            var contentDocumentId = component.get("v.contentDocumentId");

            console.log(contentDocumentId);

            $A.get('e.lightning:openFiles').fire({
                recordIds: [contentDocumentId]
            }); 
        }

        // AMM1
        helper.helperRecordContentView(component, event, helper);
        // AMM1
    }
})