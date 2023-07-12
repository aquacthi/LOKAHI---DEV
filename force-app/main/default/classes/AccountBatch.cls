/*
    Flow to apex
    
    Flow Label: BC_Internal Amazon approval reminder schedule
    Description: Send reminder mail to Senior Leader and Finanace Manager. number of attempts are 5.
                 If reached to attempts, update status and stage as no response and inactive.
                 If less than attpemts and stage is pendining approval, send reminder email and update sent date and number of attemtps.
    Author : jasons@fiduciarytech.com
    Date   : 2022-06-10
*/
global without sharing class AccountBatch implements Database.Batchable<sObject> {
    private Decimal maxNumSLApprovalAttempts;
    private Decimal maxNumFMApprovalAttempts;

    private static Map<String, Decimal> constantValueByDevloperName {
        get {
            if (constantValueByDevloperName == null) {
                constantValueByDevloperName = new Map<String, Decimal>();
                for (Constant_Value__mdt cv : [SELECT DeveloperName, Value__c FROM Constant_Value__mdt]) {
                    constantValueByDevloperName.put(cv.DeveloperName, cv.Value__c);
                }    
            }
            return constantValueByDevloperName;
        }
        set;
    }
    
    global AccountBatch() {
        maxNumSLApprovalAttempts = constantValueByDevloperName.get(UtilityConsts.CONSTANT_VALUE_DEVELOPERNAME_MAX_SENIOR_LEADER_APPROVAL_ATTEMPTS);
        maxNumFMApprovalAttempts = constantValueByDevloperName.get(UtilityConsts.CONSTANT_VALUE_DEVELOPERNAME_MAX_FINANCE_MANAGER_APPROVAL_ATTEMPTS);
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, Stage__c, Record_Type_Name__c, 
                                                Days_to_next_approval_reminder__c, IsDeleted, Approval_Response__c, 
                                                Billing_Codes_Entered__c, Senior_Leader_Approval_Attempts__c, FM_Email__c, 
                                                Last_SL_Approval_Sent__c, Reason_for_Inactive_Status__c,  
                                                Finance_Manager_Approval_Attempts__c, Last_FM_Approval_Sent__c, 
                                                Owner.email, Senior_Leader__r.Email, Name, 
                                                Related_Request__c, Related_Request__r.Recipient_Email__c, Related_Request__r.Requestor_Email__c
                                        FROM Account 
                                        WHERE ((Stage__c = :UtilityConsts.ACC_STAGE_PENDING_SENIOR_LEADER_APPROVAL AND Approval_Response__c = null) OR 
                                                (Stage__c = :UtilityConsts.ACC_STAGE_PENDING_FINANCE_APPROVAL AND Billing_Codes_Entered__c = false)) 
                                            AND Record_Type_Name__c = :UtilityConsts.RECORD_TYPE_NAME_INTERNAL  
                                            AND Days_to_next_approval_reminder__c = 0 
                                            AND IsDeleted = false]);
    }

    global void execute(Database.BatchableContext bc, List<Account> accList) {
        List<Account> accListToUpdate = new List<Account>();
        List<Messaging.SingleEmailMessage> emailsToSend  = new List<Messaging.SingleEmailMessage>();
        System.debug('-------execute batch---------');     
        for (Account acc : accList) {    
            if (acc.Stage__c == UtilityConsts.ACC_STAGE_PENDING_SENIOR_LEADER_APPROVAL) {
                if (acc.Senior_Leader_Approval_Attempts__c == maxNumSLApprovalAttempts) {
                    acc.Reason_for_Inactive_Status__c = UtilityConsts.ACC_REASON_FOR_INACTIVE_STATUS_NO_RESPONSE_FROM_SENIOR_LEADER;
                    acc.Stage__c = UtilityConsts.ACC_STAGE_INACTIVE;

                    accListToUpdate.add(acc);
                    System.debug('-------execute inactive---------');

                } else if (acc.Senior_Leader_Approval_Attempts__c < maxNumSLApprovalAttempts) {
                    Messaging.SingleEmailMessage emails = getEmailMessage(acc,'Reminder_Senior_Leader_Approval_Request_Notification'); 
                    emailsToSend.add(emails);
                    acc.Last_SL_Approval_Sent__c = Datetime.now();
                    acc.Senior_Leader_Approval_Attempts__c += 1;

                    accListToUpdate.add(acc);
                    System.debug('-------execute add attempts---------');
                }

            } else if (acc.Stage__c == UtilityConsts.ACC_STAGE_PENDING_FINANCE_APPROVAL) {
                if (acc.Finance_Manager_Approval_Attempts__c == MaxNumFMApprovalAttempts) {
                    acc.Reason_for_Inactive_Status__c = UtilityConsts.ACC_REASON_FOR_INACTIVE_STATUS_NO_RESPONSE_FROM_FINANCE_MANAGER;
                    acc.Stage__c = 'Inactive';
        
                    accListToUpdate.add(acc);

                } else if (acc.Finance_Manager_Approval_Attempts__c < MaxNumFMApprovalAttempts) {
                    Messaging.SingleEmailMessage emails = getEmailMessage(acc,'Reminder_Finance_Manager_Approval_Request_Notification'); 
                    emailsToSend.add(emails);
                    acc.Finance_Manager_Approval_Attempts__c += 1;
                    acc.Last_FM_Approval_Sent__c = Datetime.now();

                    accListToUpdate.add(acc);
                }
            }
        }

        if (!accListToUpdate.isEmpty()) {
            update accListToUpdate;
        }

        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend, false);
        }
    }

    global void finish(Database.BatchableContext bc) {
        AccountCreateGroupMemberBatch b = new AccountCreateGroupMemberBatch();
        database.executebatch(b); 
    }

    private static Messaging.SingleEmailMessage getEmailMessage(Account acc, String requestEmailType) {
        Messaging.SingleEmailMessage emailMsg = new Messaging.SingleEmailMessage();
        String subject;
        List<String> toAddresses = new List<String>();
        List<String> ccAddresses = new List<String>();
        Id emailTemplateId;
      
        if (requestEmailType == 'Reminder_Senior_Leader_Approval_Request_Notification') { // Email Alert : Senior Leader approval reminder
            subject = 'REMINDER RESPONSE REQUESTED: Autodesk Token Flex - Approval Requested ' + acc.Name;
            toAddresses.add(acc.Senior_Leader__r.Email);
            emailTemplateId = CalloutUtility.EMAIL_TEMPLATE_MAP.get(requestEmailType);          
        } else if (requestEmailType == 'Reminder_Finance_Manager_Approval_Request_Notification') { // Email Alert : Senior Leader approval reminder
            subject = 'REMINDER ACTION NEEDED: Autodesk Token Flex - Approval Requested ' + acc.Name;
            toAddresses.add(acc.Senior_Leader__r.Email);
            toAddresses.add(acc.FM_Email__c);
            emailTemplateId = CalloutUtility.EMAIL_TEMPLATE_MAP.get(requestEmailType); 
        }

        Boolean isRelatedRequestPopulated = acc.Related_Request__r != null;
        if (isRelatedRequestPopulated && String.IsNotBlank(acc.Related_Request__r.Recipient_Email__c)) {
            ccAddresses.add(acc.Related_Request__r.Recipient_Email__c);
        }
        if (isRelatedRequestPopulated && String.IsNotBlank(acc.Related_Request__r.Requestor_Email__c)) {
            ccAddresses.add(acc.Related_Request__r.Requestor_Email__c);
        }

        // get OWA to set 
        OrgWideEmailAddress orgWideAddress = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = :System.Label.BC_BIM_Central_Admin_Email LIMIT 1];
        emailMsg.setOrgWideEmailAddressId(orgWideAddress.id);
        emailMsg = Messaging.renderStoredEmailTemplate(emailTemplateId, null, acc.id);
        emailMsg.setSubject(subject);
        emailMsg.setToAddresses(toAddresses);
        emailMsg.setSenderDisplayName('No-Reply-BimCentral TokenFlex Admin');
        
        if (!ccAddresses.isEmpty()) {
            emailMsg.setCCAddresses(ccAddresses);
        }

        return emailMsg;
    }

}