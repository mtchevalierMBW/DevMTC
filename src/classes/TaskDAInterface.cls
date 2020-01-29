/**
 * Created by Matthew.Chevalier on 1/29/2020.
 */

public interface TaskDAInterface {

    List<Task> getIncompleteTasksFromAccountIds(Set<Id> accountIds);
}