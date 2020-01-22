/**
* BatchLightningNoteMigrationTest
* Date: 10/2/2018
* Programmer: Alexander Miller
* Work Item: W-000413
* 
* Testing: BatchLightningNoteMigration
*/
@isTest
public class BatchLightningNoteMigrationTest {

    @testSetup
    public static void setup()
    {
        Account tempAccount = new Account();
        tempAccount.Name = 'BatchLightningNoteMigrationTest';
        insert tempAccount;

        Note tempNote = new Note();
        tempNote.Title = 'BatchLightningNoteMigrationTest';
        tempNote.ParentId = tempAccount.Id;
        tempNote.Body = 'Test Content';
        insert tempNote;
    }

    public static testMethod void testScheduler()
    {   
       Test.startTest();        
       BatchLightningNoteMigration sh1 = new BatchLightningNoteMigration('Account', System.now().addDays(-1));
       String sch = '0 0 23 * * ?'; 
       system.schedule('BatchLightningNoteMigration', sch, sh1);
       Test.stopTest();
    }
    
    public static testMethod void testBatch()
    {
        Test.startTest();
        
        BatchLightningNoteMigration sh1 = new BatchLightningNoteMigration('Account', System.now().addDays(-1));
        database.executeBatch(sh1, 1);
        Test.stopTest();
        
        // Ensure the files were created
        System.assertNotEquals(0, ([SELECT Id FROM ContentNote]).size());
    }
}