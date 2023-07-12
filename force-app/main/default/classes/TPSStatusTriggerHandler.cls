public with sharing class TPSStatusTriggerHandler {
    public TPSStatusTriggerHandler() {

    }

    public static void onAfterInsert(List<TPS_Status__c> newList, Map<Id, TPS_Status__c> newMap) { 

    }

    public static void onAfterUpdate(Map<Id, TPS_Status__c> newMap, Map<Id, TPS_Status__c> oldMap) { }

    public static void onBeforeInsert(List<TPS_Status__c> newList) {        
        // updates account fields
        updateAccountTPSFields(newList);
     }

    public static void onBeforeUpdate(List<TPS_Status__c> newList, Map<Id, TPS_Status__c> oldMap) { }


    public static void updateAccountTPSFields(List<TPS_Status__c> newList) {

        // store accound ids from tps status records
        Map<String, TPS_Status__c> tpsStatusesByAccountId = new Map<String, TPS_Status__c>();
        for(TPS_Status__c tps : newList) {
            tps.Status__c = 'Fail';
            tps.Error__c = 'Account not updated, please check the AccountId';
            tpsStatusesByAccountId.put(tps.Account_ID__c, tps);
        }

        // get all accounts in the tps status records
        List<Account> accounts = [SELECT Id, TPS_Status__c, TPS_Status_Needed__c FROM Account WHERE ID IN :tpsStatusesByAccountId.keySet()];
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();

        // mapping table to get the tps status value in Salesforce based on the tps status in TPS system
        Map<String, String> tpsStatusInSalesforceByTpsStatusInTPSSystem = getTPSStatusMapping();

        // Update list of accounts tps status based on tps status records
        for (Account account : accounts) {
            if (tpsStatusesByAccountId.containsKey(account.Id)) {
                // set the account to update fields
                Account accountToUpdate = new Account();
                accountToUpdate.Id = account.Id;
                accountToUpdate.TPS_Status__c = tpsStatusInSalesforceByTpsStatusInTPSSystem.get(tpsStatusesByAccountId.get(Account.Id).TPS_Status__c);
                
                if (accountToUpdate.TPS_Status__c == 'Approved' || accountToUpdate.TPS_Status__c == 'Not Approved') {
                    accountToUpdate.TPS_Status_Needed__c = false;
                }
                accountsToUpdate.put(accountToUpdate.Id, accountToUpdate);
            }
        }

        if (!accountsToUpdate.isEmpty()) {
            try {
                Database.SaveResult[] srList = Database.update(accountsToUpdate.values(), false);

                // Iterate through each returned result
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {
                        // Operation was successful, so get the ID of the record that was processed
                        System.debug('Successfully inserted account. Account ID: ' + sr.getId());
                        for(TPS_Status__c tps : newList) {
                            if (tps.Account_ID__c == sr.getId()) {
                                tps.Status__c = 'Success';
                                tps.Error__c = '';
                                break;
                            }
                        }
                    }
                    else {
                        // Operation failed, so get all errors                
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('The following error has occurred.');                    
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Account fields that affected this error: ' + err.getFields());
                        }
                    }
                }
            } catch (Exception e) {
                // log error in a table and send emails
            }
        }

    }

    public static Map<String, String> getTPSStatusMapping() {
        Map<String, String> tpsStatusMappings = new Map<String, String>();
        for (TPS_Status_Mapping__mdt record : TPS_Status_Mapping__mdt.getAll().values()) {
            tpsStatusMappings.put(record.TPS_Status_In_TPS_System__c, record.TPS_Status_in_Salesforce__c);
        }

        return tpsStatusMappings;
    }

}