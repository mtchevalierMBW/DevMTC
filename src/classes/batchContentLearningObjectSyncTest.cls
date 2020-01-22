/**
 * WMK, LLC (c) - 2018 
 *
 * batchContentLearningObjectSync
 * 
 * Created By:   Alexander Miller
 * Created Date: 12/5/2018   
 * Work Item:    W-000421
 *
 * Modified By         Alias       Work Item       Date      Reason
 * -----------------------------------------------------------------
 */
@isTest
public class batchContentLearningObjectSyncTest {
    
    public static testMethod void testingBatchRun()
    {
        Test.startTest();

        batchContentLearningObjectSync thisBatch = new batchContentLearningObjectSync();
        database.executeBatch(thisBatch, 1); 

        Test.stopTest();
	}
    
    public static testMethod void testingBatchScheduleRun()
    {
        Test.startTest();

        batchContentLearningObjectSync sh1 = new batchContentLearningObjectSync();
        String sch = '0 0 23 * * ?'; 
        System.schedule('batchContentLearningObjectSyncTest', sch, sh1); 
        
        Test.stopTest();
	}
}