/**
 * Created by Matthew.Chevalier on 1/29/2020.
 */

@IsTest
private class TaskDA_TEST {
    @IsTest
    static void getIncompleteTasksFromAccountIds_givenIdSet_returnsTaskList () {
        TaskDA instance = new TaskDA();
        Test.startTest();
        {
            List<Task> res = instance.getIncompleteTasksFromAccountIds(new Set<Id>());
            System.assertEquals(0, res.size());
        }
        Test.stopTest();
    }

    @IsTest
    static void callAllMockMethods () {
        TaskDAMock instance = new TaskDAMock();
        Test.startTest();
        {
            instance.getIncompleteTasksFromAccountIds(new Set<Id>());
        }
        Test.stopTest();
    }
}