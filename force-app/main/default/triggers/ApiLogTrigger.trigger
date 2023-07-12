trigger ApiLogTrigger on API_Log__c (after insert, after update) {
    switch on Trigger.operationType {        
        when AFTER_INSERT {
            ApiLogTriggerHandler.onAfterInsert(Trigger.new);
        }
        when AFTER_UPDATE {
            ApiLogTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}