/**
 * VehicleInventory_DocUpload
 * Tested by: VehicleInventory_DocUpload_TEST
 * Date: 2019-01-15
 * Programmer: Bryan Leaman
 * Project: W-000517
 *
 * Coverage:
 *	2019-03-28	97%	(41/42)
 *
 * Modifications:
 *	2019-11-26	W-000786 BLL1 - get settings (title location picklist options)
 *
**/
public with sharing class VehicleInventory_DocUpload {

	@AuraEnabled
	public static List<DocumentInfo> ListOfDocuments(Id vehicleId) {
		List<DocumentInfo> vehDocuments = new List<DocumentInfo>();

		for(ContentDocumentLink doclink : [
			select Id, LinkedEntity.Name, LinkedEntityid,
				ContentDocumentId, ContentDocument.Title, ContentDocument.FileType, ContentDocument.FileExtension,
				ContentDocument.OwnerId
			from ContentDocumentLink 
			where LinkedEntityid = :vehicleId
		]) {
			DocumentInfo di = new DocumentInfo();
			di.DocId = docLink.ContentDocumentId;
			di.Type = 'file';
			di.FileName = doclink.ContentDocument.Title + '.' + doclink.ContentDocument.FileExtension;
			di.MyUpload = doclink.ContentDocument.OwnerId==UserInfo.getUserId();
			vehDocuments.add(di);
			System.debug(di);
		}
		for(Attachment att : [
			select Id, Name, ContentType, OwnerId
			from Attachment
			where ParentId = :vehicleId
		]) {
			DocumentInfo di = new DocumentInfo();
			di.DocId = att.Id;
			di.Type = 'attachment';
			di.FileName = att.Name;
			di.MyUpload = att.OwnerId==UserInfo.getUserId();
			vehDocuments.add(di);
			System.debug(di);
		}
		System.debug(vehDocuments);
		return vehDocuments;
	}

	@AuraEnabled
	public static boolean renameFile(String documentId, String newFileName) {
		boolean rtnOk = false;
		try {
			update(new ContentDocument(Id=documentId, Title=newFileName));
			rtnOk = true;
		} catch(Exception e) {}
		return rtnOk;
	}

	@AuraEnabled
	public static void deleteFile(String filetype, Id fileid) {
		VehicleInventory_DocUploadHelper.deleteFile(filetype, fileid);
	}

	@AuraEnabled
	public static boolean canDeleteVehicleFiles(){
		return Schema.dealer__Vehicle_Inventory__c.SObjectType.getDescribe().isCreateable();
	}

	public class DocumentInfo {
		@AuraEnabled public Id DocId {get;set;}
		@AuraEnabled public String Type {get;set;}
		@AuraEnabled public String FileName {get;set;}
		@AuraEnabled public boolean MyUpload {get;set;}
	}

	@AuraEnabled
	public static Object settings(){
		List<String> objprops = new List<String>();
		List<String> titlelocs = new List<String>();
		Schema.DescribeFieldResult dfr = dealer__Vehicle_Inventory__c.Title_Location__c.getDescribe();
		List<Schema.PicklistEntry> plvs = dfr.getPicklistValues();
		for(Schema.PicklistEntry p : plvs) titlelocs.add(p.getLabel());	// p.getValue()
		objprops.add('"titlelocations":' + '["' + String.join(titlelocs, '","') + '"]');
		boolean canDelete = VehicleInventory_DocUpload.canDeleteVehicleFiles();
		objprops.add('"candeletefiles":' + (canDelete?'true':'false'));
		System.debug(objprops);
		return JSON.deserializeUntyped('{' + String.join(objprops, ',') + '}');
	}

}