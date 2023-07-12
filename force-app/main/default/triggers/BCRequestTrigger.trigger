trigger BCRequestTrigger on BC_Request__c (after insert, after update, before insert, before update) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            BCRequestTriggerHandler.onAfterInsert(Trigger.new);
        }
        when AFTER_UPDATE {
            BCRequestTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap, Trigger.newMap);
        }
        when BEFORE_INSERT {
            BCRequestTriggerHandler.onBeforeInsert(Trigger.new);
        }
        when BEFORE_UPDATE {
            BCRequestTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap, Trigger.newMap);
        }
    }
}