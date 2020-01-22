/*
* BatchLightningAttachmentMigrationTest
* Date: 9/21/2018
* Programmer: Alexander Miller
* Work Item: W-000413
* 
* Testing: BatchLightningAttachmentMigration
*/
@isTest
public class BatchLightningAttachmentMigrationTest {

    @testSetup
    public static void setup()
    {
        Account tempAccount = new Account();
        tempAccount.Name = 'BatchLightningAttachmentMigrationTest';
        insert tempAccount;

        Attachment tempAttachment = new Attachment();   
        tempAttachment.Name = 'testAttachment:BatchLightningAttachmentMigrationTest';
        tempAttachment.ParentId = tempAccount.Id;
        tempAttachment.Body = Blob.valueOf('Test Content');
        insert tempAttachment;
    }

    public static testMethod void testScheduler()
    {   
       Test.startTest();        
       BatchLightningAttachmentMigration sh1 = new BatchLightningAttachmentMigration('Account', System.now().addDays(-1));
       String sch = '0 0 23 * * ?'; 
       system.schedule('BatchLightningAttachmentMigration', sch, sh1);
       Test.stopTest();
    }
    
    public static testMethod void testBatch()
    {
        Test.startTest();
        
        System.assertEquals(0, ([SELECT Id FROM ContentVersion]).size());
        
        BatchLightningAttachmentMigration sh1 = new BatchLightningAttachmentMigration('Account', System.now().addDays(-1));
        database.executeBatch(sh1, 1);
        Test.stopTest();
        
        // Ensure the files were created
        System.assertNotEquals(0, ([SELECT Id FROM ContentVersion]).size());
    }
}