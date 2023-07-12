trigger TPSDeactivation on TPS_Deactivation__c (after insert, after update, after delete, before insert, before update) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            TPSDeactivationTriggerHandler.onAfterInsert(Trigger.new, Trigger.newMap);
        }

        when AFTER_UPDATE {
            TPSDeactivationTriggerHandler.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
        }

        when BEFORE_INSERT {
            TPSDeactivationTriggerHandler.onBeforeInsert(Trigger.new);
        }

        when BEFORE_UPDATE {
            TPSDeactivationTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}