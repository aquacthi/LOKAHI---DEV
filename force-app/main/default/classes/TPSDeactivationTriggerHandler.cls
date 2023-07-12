public with sharing class TPSDeactivationTriggerHandler {

    public static void onAfterInsert(List<TPS_Deactivation__c> newList, Map<Id, TPS_Deactivation__c> newMap) { }

    public static void onAfterUpdate(Map<Id, TPS_Deactivation__c> newMap, Map<Id, TPS_Deactivation__c> oldMap) {
        // update account
        updateAccountStatus(newMap, oldMap);
    }

    public static void onBeforeInsert(List<TPS_Deactivation__c> newList) { }

    public static void onBeforeUpdate(List<TPS_Deactivation__c> newList, Map<Id, TPS_Deactivation__c> oldMap) { }

    public static void updateAccountStatus(Map<Id, TPS_Deactivation__c> newMap, Map<Id, TPS_Deactivation__c> oldMap) {

        // get accounts to update
        Set<Id> accountIds = new Set<Id>();

        for (TPS_Deactivation__c tpsDeactivation : newMap.values()) {
            if (tpsDeactivation.Status__c == 'Success' && 
                oldMap.get(tpsDeactivation.Id).Status__c != tpsDeactivation.Status__c &&
                tpsDeactivation.Response_Date__c == System.today()) {
                accountIds.add(tpsDeactivation.Account__c);
            }
        }

        List<Account> accountsToUpdate = new List<Account>();
        for (Account account : [SELECT Id, Stage__c FROM Account WHERE Id IN :accountIds]) {
            if (account.Stage__c != UtilityConsts.ACC_STAGE_INACTIVE) {
                account.Stage__c = UtilityConsts.ACC_STAGE_INACTIVE;
                accountsToUpdate.add(account);
            }
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }

    }
}