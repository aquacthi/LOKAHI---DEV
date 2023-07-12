trigger AccountTrigger on Account (after insert, after update, after delete, before insert, before update) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            AccountTriggerHandler.onAfterInsert(Trigger.new, Trigger.newMap);
        }

        when AFTER_UPDATE {
            AccountTriggerHandler.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
        }

        when BEFORE_INSERT {
            AccountTriggerHandler.onBeforeInsert(Trigger.new);
        }

        when BEFORE_UPDATE {
            AccountTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}