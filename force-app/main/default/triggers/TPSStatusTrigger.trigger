trigger TPSStatusTrigger on TPS_Status__c (after insert, after update, after delete, before insert, before update) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            TPSStatusTriggerHandler.onAfterInsert(Trigger.new, Trigger.newMap);
        }

        when AFTER_UPDATE {
            TPSStatusTriggerHandler.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
        }

        when BEFORE_INSERT {
            TPSStatusTriggerHandler.onBeforeInsert(Trigger.new);
        }

        when BEFORE_UPDATE {
            TPSStatusTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}