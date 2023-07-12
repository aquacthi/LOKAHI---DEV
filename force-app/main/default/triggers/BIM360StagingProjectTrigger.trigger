trigger BIM360StagingProjectTrigger on BIM360_Staging_Project__c (before update) {
    switch on Trigger.operationType {
        when BEFORE_UPDATE {
            BIM360StagingProjectTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}