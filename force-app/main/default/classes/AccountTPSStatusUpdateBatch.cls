/**
 * Batch used to reprocess TPS Status record that failed during processing
 * 
 */

global without sharing class AccountTPSStatusUpdateBatch implements Schedulable, Database.Batchable<sObject> {


    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT ID FROM TPS_Status__c WHERE Status__c = 'Reprocess']);
    }

    global void execute(Database.BatchableContext bc, List<TPS_Status__c> tpsStatusList) {

        TPSStatusTriggerHandler.updateAccountTPSFields(tpsStatusList);
        
    }

    global void finish(Database.BatchableContext bc) {
        
    }

    public void execute(SchedulableContext sc) {
        AccountTPSStatusUpdateBatch batchSceduler = new AccountTPSStatusUpdateBatch();
        Database.executeBatch(batchSceduler); 
    }
}