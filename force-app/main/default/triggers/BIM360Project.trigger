trigger BIM360Project on BIM360_Project__c (after insert, after update, after delete, before insert, before update) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            BIM360ProjectTriggerHandler.onAfterInsert(Trigger.new, Trigger.newMap);
        }

        when AFTER_UPDATE {
            BIM360ProjectTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
        }

        when BEFORE_INSERT {
            BIM360ProjectTriggerHandler.onBeforeInsert(Trigger.new);
        }

        when BEFORE_UPDATE {
            BIM360ProjectTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}