/**
 * LightningFileUtilityTest
 * 
 * Created By: Alexander Miller
 * Created Date: 10/3/2018 
 * Work Item: W-000413
 */
@isTest
public class LightningFileUtilityTest {

    @testSetup
    public static void setup()
    {
        Account tempAccount = new Account();
        tempAccount.Name = 'LightningFileUtilityTest';
        insert tempAccount;

        LightningFileUtility tempHandler = new LightningFileUtility();

        tempHandler.addFile('Title', 'Body', tempAccount.Id, true, null);

        tempHandler.commitFiles();
    }

    public static testMethod void testGlobalParams()
    {   
        Test.startTest();        
        LightningFileUtility tempHandler = new LightningFileUtility();

        tempHandler.getErrorsHTML();

        tempHandler.getErrors();

        tempHandler.getListOfContentVersions();

        tempHandler.getListOfContentNotes();

        tempHandler.getListOfContentDocumentLinks();

        Test.stopTest();
    }

    public static testMethod void testRetrievalByParentNote()
    {   
        Test.startTest();        
        
        LightningFileUtility tempHandler = new LightningFileUtility();

        List<ContentNote> listOfNotes = tempHandler.getContentNotesByParentId([SELECT Id FROM Account LIMIT 1].Id);

        System.assertNotEquals(0, listOfNotes.size());

        Test.stopTest();
    }
}