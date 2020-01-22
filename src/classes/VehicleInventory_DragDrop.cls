/**
* VehicleInventory_DragDrop
* Used in VehicleInventory_TitleDocUpload.vfp
* Tested by: VehicleInventory_DragDrop_Test
 *
*  Date        Programmer  Description
*  2016-10-04  A. Bangle   Copy and Pasted Code from http://www.jitendrazaa.com/blog/salesforce/salesforce-drag-and-drop-file-uploader-component-with-progress-bar-html5-and-pure-javascript-based/
*/

@RestResource(urlMapping='/DragAndDrop/v1/*')
global with sharing class VehicleInventory_DragDrop
{
    @HttpPost
    global static String attachDoc(){
        RestRequest req = RestContext.request;
        RestResponse res = Restcontext.response;
        
        String fName = req.params.get('FileName');
        String parId = req.params.get('parId');
        Blob postContent = req.requestBody; 
        
        Attachment a = new Attachment (ParentId = parId,
                                       Body = postContent,
                                       Name = fName);
        
        insert a;
        return a.Id;
    }
}