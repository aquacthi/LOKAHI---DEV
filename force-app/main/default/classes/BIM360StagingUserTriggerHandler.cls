public without sharing class BIM360StagingUserTriggerHandler {
    public static void onBeforeUpdate(List<BIM360_Staging_User__c> newList, Map<Id, BIM360_Staging_User__c> oldMap) {
        List<API_Log__c> apiLogsToInsert = new List<API_Log__c>();

        for (BIM360_Staging_User__c item : newList) {
            if (item.BIM360_Staging_User_Status__c == 'Callout Initiated' &&
                item.BIM360_Staging_User_Status__c != oldMap.get(item.Id).BIM360_Staging_User_Status__c) {
                API_Log__c apiLog = new API_Log__c();
                apiLog.BIM360_Staging_User__c = item.Id;
                apiLog.Status__c = 'Pending';
                apiLog.Log_Type__c = 'Outbound';

                if (item.BIM360_Staging_User_Type__c == 'Insert') {
                    apiLog.Method_Name__c = 'postUserToProjectBulk';
                } else if (item.BIM360_Staging_User_Type__c == 'Update') {
                    apiLog.Method_Name__c = 'patchUserInProjectBulk';
                }
                
                apiLogsToInsert.add(apiLog);
            }
        }

        if (!apiLogsToInsert.isEmpty()) {
            insert apiLogsToInsert;
        }
    }
}