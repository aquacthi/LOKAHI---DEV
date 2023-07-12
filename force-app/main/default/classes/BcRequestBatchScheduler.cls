public with sharing class BcRequestBatchScheduler implements schedulable {
    public void execute(SchedulableContext sc) {
        BcRequestBatch batchScheduler = new BcRequestBatch();
        database.executebatch(batchScheduler);
    }
}