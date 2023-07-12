public without sharing class AccountTriggerHandler {
    @TestVisible
    static Boolean g_do_not_run = false;

    public static Id accountInternalRecordTypeId {
        get {
            if(accountInternalRecordTypeId == null) {
                accountInternalRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Internal').getRecordTypeId();
            }
            return accountInternalRecordTypeId;
        }
        set;
    }

    public static Id accountExternalRecordTypeId {
        get {
            if(accountExternalRecordTypeId == null) {
                accountExternalRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('External').getRecordTypeId();
            }
            return accountExternalRecordTypeId;
        }
        set;
    }

    public static void onAfterInsert(List<Account> newList, Map<Id, Account> newMap) {
        List<API_Log__c> apiLogsToInsert = new List<API_Log__c>();
        System.debug('===========Account - onAfterInsert==============');

        processAmazonUserInfoIntegration(newList, null, apiLogsToInsert);

        if (!apiLogsToInsert.isEmpty()) {
            List<Database.SaveResult> sr = Database.insert(apiLogsToInsert, false);
        }

        changeNameToNumberGenerator(newMap);
    }

    public static void onAfterUpdate(Map<Id, Account> newMap, Map<Id, Account> oldMap) {
        System.debug('=======================Account - onAfterUpdate=======================');
       if (g_do_not_run == false) {
            updateAccountsBasedOnStage(newMap, oldMap);
            createAPOCAccountShare(newMap, oldMap);
            createTPSDeactivationRecords(newMap, oldMap);
        }
         addAccountGroupMembers(newMap);
    }

    public static void onBeforeInsert(List<Account> newList) {
        System.debug('=======================Account - onBeforeInsert=======================');
        changeCurrentStage(newList, null);
        updateTPSStatus(newList, null);
    }

    public static void onBeforeUpdate(List<Account> newList, Map<Id, Account> oldMap) {       
        // trigger invokes queueable and queueable updates Account
        // prevent queueable from causing the trigger to run queueable again in an endless loop
        // batch check is being put in as a pre-caution
        System.debug('=======================Account - onBeforeUpdate ==================');

        changeCurrentStage(newList, oldMap);
        updateTPSStatus(newList, oldMap);

        if (!System.isQueueable() && !System.isBatch()) {

            List<API_Log__c> apiLogsToInsert = new List<API_Log__c>();
            System.debug('=======================Account - onBeforeUpdate apiLogsToInsert ==================');

            processAmazonUserInfoIntegration(newList, oldMap, apiLogsToInsert);

            if (!apiLogsToInsert.isEmpty()) {
                List<Database.SaveResult> sr = Database.insert(apiLogsToInsert, false);
            }
        }
    }

    public static void updateTPSStatus(List<Account> newList, Map<Id, Account> oldMap) {

        for (Account a : newList) {
            // by default the tps status needed is unchecked
            // if record type changes from external to internal, then update TPS_Status_Needed__c to unchecked
            if (oldMap != null && oldMap.get(a.Id).RecordTypeId != a.RecordTypeId &&
                a.RecordTypeId == accountInternalRecordTypeId) {
                a.TPS_Status_Needed__c = false;
            }
            // on insert if record type is external or
            // if record type changes from internal to external, then update TPS_Status_Needed__c to checked
            else if ((oldMap == null || 
                (oldMap != null && oldMap.get(a.Id).RecordTypeId != a.RecordTypeId)) &&
                a.RecordTypeId == accountExternalRecordTypeId) {
                a.TPS_Status_Needed__c = true;
            }
        }
    }

    // phase 2 req 4
    private static void processAmazonUserInfoIntegration(List<Account> newList, 
                                                         Map<Id, Account> oldMap, 
                                                         List<API_Log__c> apiLogsToInsert) {    
        for (Account item : newList) {            
            if ((item.Stage__c == 'Enter Finance Manager') &&
                (!item.Is_Redshit_Get_User_Info_Success__c) &&
                (item.FM_Email__c != null)) {
                apiLogsToInsert.add(createAmazonUserInfoApiLog(item));
            }
        }
    }
    private static API_Log__c createAmazonUserInfoApiLog(Account acc) {
        API_Log__c result = new API_Log__c();

        result.Status__c = 'Pending';
        result.Account__c = acc.Id;
        result.Method_Name__c = 'getAmazonUserInfo';
        result.Log_Type__c = 'Outbound';

        return result;
    }

    /**
        Flow to apex
        
        Flow Label: BC_Account record create-After Save
        Flow Name: BC_Account_record_create_After_Save

        Description:
        Changes Account Name to the autonumber value. If a new Internal Account, a new Group is created and an Account Share is created.

        Author : annkim@fiduciarytech.com
        Date   : 2022-05-26
    */

    private static void changeNameToNumberGenerator(Map<Id, Account> newMap) {
        List<Account> accountList = new List<Account>();

        for (Account acc: [SELECT Id, Disable_Automation__c, Record_Type_ID_18__c, Internal_Number_Generator__c, External_Number_Generator__c
                            FROM Account 
                            WHERE Id IN: newMap.keySet()
                            AND Disable_Automation__c = false]) {
            // Check if account internal or external                    
            if (acc.Record_Type_ID_18__c == accountInternalRecordTypeId) {
                acc.Name = acc.Internal_Number_Generator__c;
            } else if (acc.Record_Type_ID_18__c == accountExternalRecordTypeId) {
                acc.Name = acc.External_Number_Generator__c;
            }

            accountList.add(acc);
        }

        if (!accountList.isEmpty()) {
            update accountList;
        }
    }

    /**
        Flow to apex
        
        Flow Label: BC_Account record create/update-Before Save
        Flow Name: BC_Account_record_create_update_Before_Save

        Description: change to the next stage depending on the current stage.

        Author : annkim@fiduciarytech.com
        Date   : 2022-05-26        
    */

    private static void changeCurrentStage(List<Account> newList, Map<Id, Account> oldMap) {
        Id bimCentralAdminId = AccountTriggerHelper.userBIMCentralAdminId();

        for (Account acc : newList) {
            if (acc.Disable_Automation__c) {
                continue;
            } else if (acc.Id == null) { // Formula ISNEW()
                acc.OwnerId = bimCentralAdminId;
            } else if (acc.RecordTypeId == accountInternalRecordTypeId) {
                switch on acc.Stage__c {
                    when 'Pending SL Approval' {
                        if (acc.Approval_Response__c == UtilityConsts.ACC_APPROVAL_RESPONSE_APPROVED && !String.isBlank(acc.FM_Email__c)) {
                            acc.SL_Approval_Locked__c = true;
                            acc.Stage__c = UtilityConsts.ACC_STAGE_ENTER_FINANCE_MANAGER;
                        } else if (acc.Approval_Response__c == UtilityConsts.ACC_APPROVAL_RESPONSE_REJECTED) {
                            acc.Add_Account_Group_Members__c = true;
                            acc.Description = 'Request not approved';
                            acc.Reason_for_Inactive_Status__c = UtilityConsts.ACC_REASON_FOR_INACTIVE_STATUS_NOT_APPROVED;
                            acc.SL_Approval_Locked__c = true;
                            acc.Stage__c = UtilityConsts.ACC_STAGE_INACTIVE;
                        }
                    }
            
                    when 'Enter Finance Manager' {
                        if (
                            acc.FM_Email__c != null &&
                            acc.FM_First_Name__c != null &&
                            acc.FM_Last_Name__c != null &&
                            acc.FM_Cost_Center__c != null
                            ) {
                            acc.Finance_Manager_Information_Entered__c = true;
                        }
                    }

                    when 'Pending Finance Approval' {
                        if (
                            acc.Company_Code__c != null && 
                            acc.Location_Code__c != null && 
                            acc.Cost_Center__c != null && 
                            !acc.Billing_Code_Locked__c
                            ) {
                            acc.Billing_Codes_Entered__c = true;
                        }
                    }

                    // populate the inactive date to indicate date to reset the account
                    when 'Inactive' {  
                        if (oldMap.get(acc.Id).Stage__c != acc.Stage__c) {
                            acc.Inactive_Date__c = System.now();
                        }                      
                    }
                }
            }
        }
    }

    /**
        Flow to apex
        
        Flow Label: BC_Account record update-After Save-Create APOC Account Share
        Flow Name: BC_Account_record_update_After_Save_Create_APOC_Account_Share
        trigger: After update

        Author : annkim@fiduciarytech.com
        Date   : 2022-05-26
    */

    // after update
    // When the name is updated in the changeNameToNumberGenerator, the auto number value is inserted into the afterInsert,
    // but when creating a group object in the subflow of this method, the gorup.Name and group.DeveloperName insert name of account 
    // and require after update

    private static void createAPOCAccountShare(Map<Id, Account> newMap, Map<Id, Account> oldMap) {
        List<Account> accountList = new List<Account>();

        for (Account acc: newMap.values()) {
            Account oldAccount = oldMap.get(acc.Id);

            if (!acc.Disable_Automation__c &&
                acc.Vendor_Amazon_Partner__c != null &&
                acc.Vendor_Amazon_Partner__c != oldAccount.Vendor_Amazon_Partner__c) {
                accountList.add(acc);
            } else {
                continue;
            }
        }

        if (!accountList.isEmpty()) {
            g_do_not_run = true;
            AccountTriggerHelper.createAccountGroupandShare(accountList);
        }
    }

    /**
        Flow to apex
        
        Flow Label: BC_Account record update-After Save-Add Account Group Members
        Flow Name: BC_Account_record_update_After_Save_Add_Account_Group_Members

        Description: Adds Senior Leader and Finance Manager to a Group when a new Internal Account is created, has been approved by the Senior Leader, and the Finance Manager has been added to the Account.
        trigger: After update

        Author : annkim@fiduciarytech.com
        Date   : 2022-05-26
    */

    // after update
    // In AccountTriggerHelper.createGroupMember, the subflow of addAccountGroupMembers, groupMember.GroupId is inserted with account.Group_ID_18__c, 
    // but groupMember.GroupId can be inserted account.Group_ID_18__c if the group object must be created first, such as createAPOCAccountShare or AccountTriggerHelper.createAccountGroupandShare.
    // so require after update

    private static void addAccountGroupMembers(Map<Id, Account> newMap) {
        List<Account> accountToUpdate = new List<Account>();
        Map<Id,Account> accountById = new Map<Id,Account>();

        for (Account acc : newMap.values()) {
            if (!acc.Disable_Automation__c && acc.Add_Account_Group_Members__c) {
                Account newAcc = new Account();
                accountToUpdate.add(new Account(Id = acc.Id, 
                                                Add_Account_Group_Members__c = false,
                                                Group_ID_18__c = acc.Group_ID_18__c,
                                                Finance_Manager__c = acc.Finance_Manager__c,
                                                Senior_Leader__c = acc.Senior_Leader__c));
                newAcc.Id = acc.Id;
                newAcc.Add_Account_Group_Members__c = false;
                newAcc.Group_ID_18__c = acc.Group_ID_18__c;
                newAcc.Finance_Manager__c = acc.Finance_Manager__c;
                newAcc.Senior_Leader__c = acc.Senior_Leader__c;
                accountById.put(acc.Id, newAcc);
            } else {
                continue;
            }
        }

        if (!accountById.isEmpty()) {
            update accountById.values();
        }

        if (!accountById.isEmpty()) {
            if (System.isBatch()){
                //AccountTriggerHelper.createGroupMemberForBatch(accountById.keySet());
            } else {
                AccountTriggerHelper.createGroupMember(accountById.keySet());
            }
        }
    }

    /**
        Flow to apex
        
        Flow Label: BC_Account record update-After Save
        Flow Name: BC_Account_record_update_After_Save
        trigger: After update

        Author : annkim@fiduciarytech.com
        Date   : 2022-06-02
    */

    private static void updateAccountsBasedOnStage(Map<Id, Account> newMap, Map<Id, Account> oldMap) {
        List<Account> addGroupMemAccountList = new List<Account>();
        List<Account> fmInfoEnteredAccountList = new List<Account>();
        List<Account> createGroupAccountList = new List<Account>();
        List<Account> stageActiveOrInactiveAccountList = new List<Account>();
        Set<Id> accountSet = new Set<Id>();
        Set<String> accountInactiveReason = new Set<String>{UtilityConsts.ACC_REASON_FOR_INACTIVE_STATUS_NO_RESPONSE_FROM_SENIOR_LEADER,
                                                            UtilityConsts.ACC_REASON_FOR_INACTIVE_STATUS_NO_RESPONSE_FROM_FINANCE_MANAGER,
                                                            UtilityConsts.ACC_REASON_FOR_INACTIVE_STATUS_NO_TPS};

        List<Account> accountToUpdate = new List<Account>();
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        for (Account acc: newMap.values()) {
            Account newAcc = new Account();
            Account oldAccount = oldMap.get(acc.Id);
            Datetime oldLastModifiedDate = oldAccount.LastModifiedDate;

            if (acc.Disable_Automation__c) {
                continue;
            }

            if (acc.LastModifiedDate != Datetime.Now()) {
                // if senior manager rejected the account

                if ((acc.Approval_Response__c == UtilityConsts.ACC_APPROVAL_RESPONSE_REJECTED ||  accountInactiveReason.contains(acc.Reason_for_Inactive_Status__c)) && acc.Stage__c == UtilityConsts.ACC_STAGE_INACTIVE) {
                    // bc request status close, stage move to 'resolve - Not completed'
                    stageActiveOrInactiveAccountList.add(acc);
                } else if (acc.Finance_Manager_Information_Entered__c) {
                    newAcc.Id = acc.Id;
                    
                    // Call subflow
                    // BC_Update_Email_Alias_Domain_fields
                    if (!String.isBlank(acc.FM_Email__c)){
                        String email = acc.FM_Email__c;
                        newAcc.FM_Email_Alias__c = UtilityClass.getEmailAliasDomain(email, 'alias');
                        newAcc.FM_Alias_Domain__c = UtilityClass.getEmailAliasDomain(email, 'aliasDomain');
                        newAcc.FM_Alias_Domain_2__c = UtilityClass.getEmailAliasDomain(email, 'aliasDomain2');
                    }

                    // Call subflow
                    // BC_Email_communication
                    // inputRequestEmailType = 'Finance Manager response request';
                    emailsToSend.addAll(EmailCommunication.getEmailMessageList(acc, 'Finance Manager response request'));

                    newAcc.Add_Account_Group_Members__c = true;
                    newAcc.Finance_Manager_Approval_Attempts__c = 0;
                    newAcc.Finance_Manager_Information_Entered__c = false;
                    newAcc.Last_FM_Approval_Sent__c = Datetime.now();
                    newAcc.Stage__c = UtilityConsts.ACC_STAGE_PENDING_FINANCE_APPROVAL;
                    newAcc.Name = acc.Name;
                    newAcc.FM_Email__c = acc.FM_Email__c;
                    newAcc.FM_First_Name__c = acc.FM_First_Name__c;
                    newAcc.FM_Last_Name__c = acc.FM_Last_Name__c;
                    newAcc.Related_Request__c = acc.Related_Request__c;
                    newAcc.FM_Cost_Center__c = acc.FM_Cost_Center__c;
                    newAcc.Senior_Leader__c = acc.Senior_Leader__c;

                    // Call subflow
                    // BC_Get_or_create_User_record
                    // Call subflow
                    // Flow: BC_Create_Account_Group_and_Share
                    fmInfoEnteredAccountList.add(newAcc);
                    createGroupAccountList.add(acc);

                    accountToUpdate.add(newAcc);

                } else if (acc.Send_TPS_Notification__c) {
                    newAcc.Id = acc.Id;
                    newAcc.Stage__c = UtilityConsts.ACC_STAGE_PENDING_ACTIVE_CONTINGENT;
                    newAcc.TPS_Request_Initial_Date__c = Date.today(); 
                    newAcc.TPS_Status__c = UtilityConsts.ACC_STAGE_PENDING_RESPONSE;
                    newAcc.Send_TPS_Notification__c = false;
                    
                    if (!acc.Has_NDA__c) {
                        //Call subflow

                        // BC_Email_communication
                        // inputRequestEmailType = 'Send NDA notification';
                        emailsToSend.addAll(EmailCommunication.getEmailMessageList(acc, 'Send NDA notification'));

                        newAcc.Last_NDA_Notification_Sent__c = Datetime.now();
                        newAcc.NDA_notification_count__c = 0;
                        newAcc.Send_NDA_Notification__c = false;
                        newAcc.NDA_Request_Initial_Date__c = Date.today();
                        newAcc.Id = acc.Id;
                    }

                    accountToUpdate.add(newAcc);
                } else if (acc.Stage__c == UtilityConsts.ACC_STAGE_PENDING_FINANCE_APPROVAL) {
                    // if internal account and senior leader and finance manager exist, 
                    if (acc.Record_Type_ID_18__c == accountInternalRecordTypeId && 
                    acc.Senior_Leader__c != null && acc.Finance_Manager__c != null) {
                        // create account member;
                        accountSet.add(acc.Id);
                    }

                    if (acc.Billing_Codes_Entered__c) {
                        newAcc.Id = acc.Id;
                        newAcc.Add_Account_Group_Members__c = false;
                        newAcc.Billing_Code_Locked__c = true;
                        newAcc.Stage__c = UtilityConsts.ACC_STAGE_ACTIVE;
                        
                        accountToUpdate.add(newAcc);
    
                        // bc request stage move to 'resolve - completed'
                        stageActiveOrInactiveAccountList.add(newAcc);
                    } 
                }
            } else {
                continue;
            }
        }

        if (!emailsToSend.isEmpty()){
            Messaging.SendEmailResult[] sendResults = Messaging.sendEmail(emailsToSend, false);
        }

        if (!fmInfoEnteredAccountList.isEmpty()) {
            g_do_not_run = true;
            // BC_Get_or_create_User_record / sub flow Owner: Danbi
            AccountTriggerHelper.findFinanceManager(fmInfoEnteredAccountList);
            // Flow: BC_Create_Account_Group_and_Share
            AccountTriggerHelper.createAccountGroupandShare(createGroupAccountList);
        }

        if (!stageActiveOrInactiveAccountList.isEmpty()) {
           g_do_not_run = true;
            // Flow: BC_Update_Open_BC_Request_records
            AccountTriggerHelper.updateOpenBcRequestIfAccountActiveOrInactive(stageActiveOrInactiveAccountList);            
        }

        if (!accountSet.isEmpty()) {
            g_do_not_run = true;
            // Flow: BC_Create Group Member

            if (System.isBatch()){
                //AccountTriggerHelper.createGroupMemberForBatch(accountSet);
            } else {
                AccountTriggerHelper.createGroupMember(accountSet);            
            }
        }

        if (!accountToUpdate.isEmpty()) {
            g_do_not_run = true;
            update accountToUpdate;
        }
    }

    // Create TPS Deactivation Records when TPS Status changed to Not Approved and TPS Deactivation Notification Sent is today.
    public static void createTPSDeactivationRecords(Map<Id, Account> newMap, Map<Id, Account> oldMap) {

        List<TPS_Deactivation__c> tpsDeactivationToCreate = new List<TPS_Deactivation__c>();

        for (Account account : newMap.values()) {
            
            // if account tps status changes to 'Not Approved' and 
            //    deactivation notification was sent today
            // then create tps deactivation record
            if (account.TPS_Status__c == 'Not Approved' && 
                account.TPS_Status__c != oldMap.get(account.Id).TPS_Status__c //&& 
                // account.TPS_Deactivation_Notification_Sent__c != null &&
                // account.TPS_Deactivation_Notification_Sent__c == System.today()
                ) {
                // then create a TPS Deactivation record for it
                TPS_Deactivation__c tpsDeactivation = new TPS_Deactivation__c();
                tpsDeactivation.Account__c          = account.Id;
                tpsDeactivation.Status__c           = 'Pending';
                tpsDeactivation.Domain_Name__c      = account.Email_Domain__c;

                tpsDeactivationToCreate.add(tpsDeactivation);
                // When are these fields used?
                // tpsDeactivation.Response_Date__c    = 
                // tpsDeactivation.Response_Message__c = 
                // tpsDeactivation.Requestor__c        = 
                // tpsDeactivation.User_Email__c       = 
            }
        }
        if (!tpsDeactivationToCreate.isEmpty()) {
            insert tpsDeactivationToCreate;
        }
        
    }
}