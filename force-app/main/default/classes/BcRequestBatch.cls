/*
    Flow to apex
    
    Flow Label: BC_APOC 3rd Party approval reminder schedule
    Description: Send reminder mail to Apoc. number of attempts are 4.
                 If reached to attempts, update status and stage as no response and not completed. 
                 If less than attemtps, send email and update field date to now and increase number of attempts.
    Author : jasons@fiduciarytech.com
    Date   : 2022-06-10
*/
global without sharing class BcRequestBatch implements Database.Batchable<sObject> {
    private Decimal maxNumAPOCApprovalAttempts;

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

    global BcRequestBatch() {
        maxNumAPOCApprovalAttempts = constantValueByDevloperName.get('Max_APOC_Approval_Request_Attempts'); 
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, Stage__c, Days_to_next_approval_reminder__c, 
                                                Record_Type_Name__c, IsDeleted, 
                                                APOC_Approval__c, APOC_Reminder_Notification_Count__c, 
                                                Other_Reason_Not_Completed__c, Reason_Not_Completed__c, 
                                                APOC_Last_Approval_Sent__c, owner.email, Amazon_POC__r.Email, Name   
                                        FROM BC_Request__c 
                                        WHERE Stage__c = 'Pending APOC Approval' 
                                        AND Days_to_next_approval_reminder__c = 0 
                                        AND Record_Type_Name__c = 'BIM 360 Non-Amazonian' 
                                        AND IsDeleted = false
                                        AND APOC_Approval__c = null]);
    }
    
    global void execute(Database.BatchableContext bc, List<BC_Request__c> bcRequestList) {  
        List<BC_Request__c> bcRequestListToUpdate = new List<BC_Request__c>();
        List<Messaging.SingleEmailMessage> emailsToSend  = new List<Messaging.SingleEmailMessage>();

        for (BC_Request__c bcr : bcRequestList) {
            if (bcr.APOC_Reminder_Notification_Count__c == maxNumAPOCApprovalAttempts) {
                bcr.Other_Reason_Not_Completed__c = 'APOCapproval not received after multiple attempts';
                bcr.Reason_Not_Completed__c = 'No Response';
                bcr.Stage__c = 'Resolved - Not Completed';

                bcRequestListToUpdate.add(bcr);        

            } else if (bcr.APOC_Reminder_Notification_Count__c < maxNumAPOCApprovalAttempts && 
                       bcr.APOC_Last_Approval_Sent__c != Date.today()) {      
                Messaging.SingleEmailMessage emails = getReminderAPOCApprovalEmailMessage(bcr);
                emailsToSend.add(emails);
                bcr.APOC_Last_Approval_Sent__c = Datetime.now();
                bcr.APOC_Reminder_Notification_Count__c += 1;

                bcRequestListToUpdate.add(bcr);          
            }         
        } 

        if (!bcRequestListToUpdate.isEmpty()) {
            update bcRequestListToUpdate;
        }

        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend, false);
            System.debug(emailsToSend);
        }
    }

    global void finish(Database.BatchableContext bc) {
        
    }

    private static Messaging.SingleEmailMessage getReminderAPOCApprovalEmailMessage(BC_Request__c bcr) {
        Messaging.SingleEmailMessage emailMsg = new Messaging.SingleEmailMessage();

        String subject = 'REMINDER RESPONSE REQUESTED: BIM 360 Construction Cloud - 3rd Party Vendor Approval Requested ' + bcr.Name;
        String toAddress = bcr.Owner.Email + ',' + bcr.Amazon_POC__r.Email;
        String [] toAddresses = toAddress.split(',');
        Id emailTemplateId = CalloutUtility.EMAIL_TEMPLATE_MAP.get('Reminder_APOC_Approval_Request_Notification');
        emailMsg = Messaging.renderStoredEmailTemplate(emailTemplateId, null, bcr.id);
        emailMsg.setSubject(subject);
        emailMsg.setToAddresses(toAddresses);
        emailMsg.setSenderDisplayName('No-Reply-BimCentral TokenFlex Admin');
        emailMsg.setReplyTo(System.Label.BC_BIM_Central_Admin_Email);

        return emailMsg;
    }

}