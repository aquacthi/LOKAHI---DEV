public with sharing class AccountBatchScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        AccountBatch batchSceduler = new AccountBatch();
        database.executeBatch(batchSceduler); 
    }
}