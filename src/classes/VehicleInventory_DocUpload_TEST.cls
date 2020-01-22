/**
* VehicleInventory_DocUpload_TEST
* Tests: VehicleInventory_DocUpload
* Date: 2019-01-15
* Programmer: Bryan Leaman
* Project: W-000517
* 
* Modifications:
*	2019-11-26	B.Leaman	W-000786 BLL1 - add test for settings method
*/
@isTest
private class VehicleInventory_DocUpload_TEST {

	 //private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	 @testSetup
	 static void setupData() {
		 //TestHelper_MW.createBaseFFAData(FFAdata);
		 //FFAdata.refresh(); 
		 //dealer.TestClassUtil tc = new dealer.TestClassUtil();
		 //tc.insertDMSSettings();
	 }

	 // unitTest
	 //---------------------------------------
	 static testMethod void unitTest() {
		 //FFAdata.refresh(); 
		 //System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();
			Account a = th.getPersonAccount('1');
			Attachment attachmnt =new Attachment(
				Name='textfileone.txt',
				Body = blob.valueOf('my attachment text'),
				ParentId = a.Id
			);
  			insert  attachmnt;
			ContentVersion cv = new ContentVersion(
				Title='textfiletwo.txt',
				VersionData = Blob.valueOf('this one is a file'),
				PathOnClient = '/'
			);
			insert(cv);
			List<ContentDocument> cdlist = [
				select Id, Title
				from ContentDocument
			];
			ContentDocumentLink cdl = new ContentDocumentLink(
				ContentDocumentId = cdlist[0].Id,
				LinkedEntityId = a.Id,
				ShareType = 'V',
				Visibility = 'AllUsers'
			);
			insert(cdl);

			ContentDocument cd = cdlist[0];
			List<Object> docs = VehicleInventory_DocUpload.ListOfDocuments(a.Id);
			Boolean ren = VehicleInventory_DocUpload.renameFile(cd.Id, 'textfilethree.txt');
			VehicleInventory_DocUpload.deleteFile('file', cd.Id);
			boolean canDelete = VehicleInventory_DocUpload.canDeleteVehicleFiles();
			// BLL1
			Object settings = VehicleInventory_DocUpload.settings();
			// BLL1 end
		 //}
	 }

}