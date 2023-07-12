trigger UserCostCenterMappingTrigger on User_Cost_Center_Mapping__c (after insert, after update, after delete) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            UserCostCenterMappingTriggerHandler.onAfterInsert(Trigger.newMap);
        }

        when AFTER_UPDATE {
            UserCostCenterMappingTriggerHandler.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
        }

        when AFTER_DELETE {
            UserCostCenterMappingTriggerHandler.onAfterDelete(Trigger.oldMap);
        }
    }
}