trigger BIM360StagingUserTrigger on BIM360_Staging_User__c (before update) {
    switch on Trigger.operationType {
        when BEFORE_UPDATE {
            BIM360StagingUserTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}