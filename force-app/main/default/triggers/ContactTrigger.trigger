trigger ContactTrigger on Contact  (before insert, after insert) {
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            ContactTriggerHandler.onBeforeInsert(Trigger.new);
        }
        when AFTER_INSERT {
            ContactTriggerHandler.onAfterInsert(Trigger.new);
        }
    }
}