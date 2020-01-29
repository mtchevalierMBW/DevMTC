/**
 * Created by Matthew.Chevalier on 1/29/2020.
 */

public inherited sharing class TaskDA implements TaskDAInterface{
    public List<Task> getIncompleteTasksFromAccountIds(Set<Id> accountIds) {
        return [
                SELECT  Id,
                        Subject,
                        OwnerId,
                        WhatId
                FROM Task
                WHERE WhatId IN :accountIds
                AND Status!='Completed'
        ];
    }
}