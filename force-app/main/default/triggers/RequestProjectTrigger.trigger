trigger RequestProjectTrigger on Request_Project__c (after insert, before insert, after update, before update) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            RequestProjectTriggerHandler.onAfterInsert(Trigger.new);
        }
        when AFTER_UPDATE {
            RequestProjectTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap, Trigger.newMap);
        }
        when BEFORE_INSERT {
            RequestProjectTriggerHandler.onBeforeInsert(Trigger.new);
        }
        when BEFORE_UPDATE {
            //RequestProjectTriggerHandler.onBeforeUpdate(Trigger.new,Trigger.oldMap, Trigger.newMap);
        }
    }
}