public class PartOnOrderUpdateSchedulable implements Schedulable {
	
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new batchUpdateOrderCount(), 10);
    }
}