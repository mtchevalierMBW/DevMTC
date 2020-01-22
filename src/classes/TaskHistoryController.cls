/**
 * WMK, LLC (c) - 2018 
 *
 * TaskHistoryController
 * 
 * Created By:   Alexander Miller
 * Created Date: 12/12/2018 
 * Tested By: TaskHistoryControllerTest
 * Work Item:    W-000516
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */
public class TaskHistoryController {

    @AuraEnabled
    public static List<Task> getTasksByParentId(Id parentId)
    {
        List<Task> listOfTasks = ([SELECT Id,
                                    Subject,
                                    ActivityDate,
                                    OwnerId,
                                    Owner.Name,
                                    Description,
                                    LastModifiedDate,
                                    CreatedDate
                                FROM Task
                                WHERE WhatId = :parentId AND
                                    (NOT Subject LIKE '%Pardot%')
                                ORDER BY CreatedDate DESC]);

        return listOfTasks;
    }
}