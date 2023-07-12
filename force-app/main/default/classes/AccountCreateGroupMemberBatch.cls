global without sharing class AccountCreateGroupMemberBatch implements Database.Batchable<sObject> {
 
    //private Id internalAccountId;

    private static Id accountInternalRecordTypeId {
        get {
            if(accountInternalRecordTypeId == null) {
                accountInternalRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Internal').getRecordTypeId();
            }
            return accountInternalRecordTypeId;
        }
        set;
    }

    // global AccountCreateGroupMemberBatch() {
    //     internalAccountId = accountInternalRecordTypeId;
    // }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, Finance_Manager__c, Senior_Leader__c, Group_ID_18__c  
                                         FROM Account 
                                         WHERE Stage__c = :UtilityConsts.ACC_STAGE_PENDING_FINANCE_APPROVAL
                                         AND Record_Type_ID_18__c = :accountInternalRecordTypeId 
                                         AND Senior_Leader__c != null
                                         AND Finance_Manager__c != null]); 
    }

    global void execute(Database.BatchableContext bc, List<Account> accList) {
        System.debug('--------execute CreateGroupMemberBatch--------');
        List<GroupMember> groupMemberToInsert = new List<GroupMember>();

        for (Account acc : accList) {
            if (acc.Group_ID_18__c != null) {

                GroupMember groupMem = new GroupMember();
                groupMem.GroupId = acc.Group_ID_18__c;

                // first, check finance manager exist, insert field
                if (!String.isBlank(acc.Finance_Manager__c)) {
                    groupMem.UserOrGroupId = acc.Finance_Manager__c;

                // second, check senior manager exist, insert field
                } else if (!String.isBlank(acc.Senior_Leader__c)) {
                    groupMem.UserOrGroupId = acc.Senior_Leader__c;
                }

                groupMemberToInsert.add(groupMem);
            }
        }
        System.debug('--------groupMemberToInsert--------');
        System.debug(groupMemberToInsert);
        if (!groupMemberToInsert.isEmpty()) {
            insert groupMemberToInsert;
        }
    }

    global void finish(Database.BatchableContext bc) {
        
    }
}