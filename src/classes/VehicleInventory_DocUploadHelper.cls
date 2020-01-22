/**
 * VehicleInventory_DocUploadHelper
 * Tested by: VehicleInventory_DocUpload_TEST
 * Date: 2019-03-28
 * Programmer: Bryan Leaman
 * Project: W-000517
 * Allow for deleting attachments or files on vehicles.
 *
 * Coverage:
 *	2019-03-28	100%	(11/11)
 *
 * Modifications: 
 *
**/
public without sharing class VehicleInventory_DocUploadHelper {

	public static void deleteFile(String filetype, Id fileid) {
		if (filetype=='attachment') delete(new Attachment(Id=fileid));
		else delete(new ContentDocument(Id=fileid));
	}

}