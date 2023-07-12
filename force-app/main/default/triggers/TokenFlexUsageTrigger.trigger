trigger TokenFlexUsageTrigger on Token_Flex_Usage__c (after insert, after update) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            TokenFlexUsageTriggerHandler.onAfterInsert(Trigger.newMap);
        }

        when AFTER_UPDATE {
            TokenFlexUsageTriggerHandler.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
        }
    }
}