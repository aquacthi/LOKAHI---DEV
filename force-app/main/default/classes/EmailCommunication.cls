/*
* @ Subject : Req8 - Flow to Apex
* @ Author : jed@fiduciarytech.com
* @ Date : 6/7/2022
* @ Desc : Flow Label - BC_Email communication
*/
public without sharing class EmailCommunication {
    
    private static Boolean sendToTokenFlexInstructions      = false;
    private static Boolean notCompletedBIM360NonAmazonian   = false;

    // This is the main logic
    // Using SObject to prevent SOQL query
    // It only serves to create and return SingleEmailMessage list. 
    // To send an email, you must write code outside of the method. - Messaging.sendEmail() 
    public static List<Messaging.SingleEmailMessage> getEmailMessageList(SObject sobj, String requestEmailType) {

        sendToTokenFlexInstructions    = false;
        notCompletedBIM360NonAmazonian = false;

        List<Messaging.SingleEmailMessage> emailMsgList = new List<Messaging.SingleEmailMessage>();

        String objectName = sobj.getSObjectType().getDescribe().getName();
        if (objectName == 'BC_Request__c') {
            Messaging.SingleEmailMessage email1 = bcRequestProcess((BC_Request__c)sobj, requestEmailType);
            if (email1 != null) {
                emailMsgList.add(email1);
            }
            Messaging.SingleEmailMessage email2 = checkTokenFlexLicenseRequest((BC_Request__c)sobj);
            if (email2 != null) {
                emailMsgList.add(email2);
            }
        } else if (objectName == 'Account') {
            Messaging.SingleEmailMessage email1 = accountProcess((Account)sobj, requestEmailType);
            if (email1 !=null) {
                emailMsgList.add(email1);
            }
        }

        return emailMsgList;
    }

    private static Messaging.SingleEmailMessage checkTokenFlexLicenseRequest(BC_Request__c bcRequest) {
        if (bcRequest.RecordTypeId == BCRequestTriggerHandler.tokenFlexRecordTypeId 
         && bcRequest.Stage__c == 'Resolved - Completed'
         && sendToTokenFlexInstructions) {

             // Ext_notification_Token_Flex_Request_completed_successfully_Recipient
            String subject = 'Request Completed Successfully ' + bcRequest.Name;
            sendToTokenFlexInstructions = false;          
            return createEmailMessage('Notification_Token_Flex_Request_Completed_Successfully',     // emailTemplateName
                                         bcRequest.Id,                                              // relatedToId
                                         subject,                                                   // subject
                                         bcRequest.Requestor_Email__c                               // toAddress
                                         );

        } else if (bcRequest.RecordTypeId == BCRequestTriggerHandler.nonAmazonianRecordTypeId 
                && bcRequest.Stage__c == 'Resolved - Not Completed'
                && notCompletedBIM360NonAmazonian) {

            // Ext_notification_Not_Completed_NonAmazonian_Requestor
            String subject = 'BIM 360 Access Request Status: Not Completed for ' + bcRequest.Name;
            notCompletedBIM360NonAmazonian = false;
            return createEmailMessage('Notification_Not_Completed_Non_Amazonian_Requestor',     // emailTemplateName
                                         bcRequest.Id,                                          // relatedToId
                                         subject,                                               // subject
                                         bcRequest.Requestor_Email__c                           // toAddress
                                         );
        }

        return null;
    }

    // BC Request Main Logic
    private static Messaging.SingleEmailMessage bcRequestProcess(BC_Request__c bcRequest, String requestEmailType) {

        if (requestEmailType == 'New Request confirmation') {
            return handleNewRequestConfirmation(bcRequest);

        } else if (requestEmailType == 'Request Not Completed notification') {
            return handleRequestNotCompletedNotification(bcRequest);

        } else if (requestEmailType == 'Pending Team Approval notification') {
            return handlePendingTeamApprovalNotification(bcRequest);

        } else if (requestEmailType == 'Completed request notification') {
            return handleCompletedRequestNotification(bcRequest);

        } else if (requestEmailType == 'Action needed') {
            return handleActionNeeded(bcRequest);

        } else if (requestEmailType == 'APOC approval needed') {
            return handleAPOCApprovalNeeded(bcRequest);

        } else if (requestEmailType == 'Fulfillment ready') {
            return handleFulfillmentReady(bcRequest);
        }
        return null;
    }

    // Decision : BC Request Order 1
    private static Messaging.SingleEmailMessage handleNewRequestConfirmation(BC_Request__c bcRequest) {
        if (bcRequest.RecordTypeId == BCRequestTriggerHandler.tokenFlexRecordTypeId) {

            // Email Alert - Ext confirmation-New Token Flex License Request
            String subject = bcRequest.Name + ' Request for Token Flex License received';            
            return createEmailMessage('Confirmation_New_Token_Flex_License_Requestor',    // emailTemplateName
                                         bcRequest.Id,                                    // relatedToId
                                         subject,                                         // subject
                                         bcRequest.Requestor_Email__c                     // toAddress
                                         );

        } else if (bcRequest.RecordTypeId == BCRequestTriggerHandler.amazonianRecordTypeId
                || bcRequest.RecordTypeId == BCRequestTriggerHandler.nonAmazonianRecordTypeId) {

            // Eamil Alert - Ext_confirmation_New_BIM_360_Member_Request_Received
            String subject = bcRequest.Name + ' Request for BIM 360 Construction Cloud received';            
            return createEmailMessage('Confirmation_New_BIM_360_Cloud_Construction_Access_Requestor',    // emailTemplateName
                                         bcRequest.Id,                                                   // relatedToId
                                         subject,                                                        // subject
                                         bcRequest.Requestor_Email__c                                    // toAddress
                                         );
        }

        return null;
    }

    // Decision : BC Request Order 2
    private static Messaging.SingleEmailMessage handleRequestNotCompletedNotification(BC_Request__c bcRequest) {
        String emailTemplateName = 'Notification_Not_Completed_Amazonian';
        if (bcRequest.Reason_Not_Completed__c == 'Not approved') {
            emailTemplateName = 'Senior_Leader_Rejection_Email';
        }
        else if (String.IsNotBlank(bcRequest.Reason_Not_Completed__c) && 
                 bcRequest.Reason_Not_Completed__c.contains('No response')) {
            emailTemplateName = 'Pending_Response_Rejection_Email';
        }

        if (bcRequest.RecordTypeId == BCRequestTriggerHandler.tokenFlexRecordTypeId
        || bcRequest.RecordTypeId == BCRequestTriggerHandler.amazonianRecordTypeId) {

            // Ext_notification_Not_Completed_Amazonian_Requestor
            String subject = bcRequest.Request_Type_Short_Name__c + ' Access Request Status: Not Completed for ' + bcRequest.Name;            
            return createEmailMessage(emailTemplateName,         // emailTemplateName
                                         bcRequest.Id,                                // relatedToId
                                         subject,                                     // subject
                                         bcRequest.Requestor_Email__c                 // toAddress
                                         );

        } else if (bcRequest.RecordTypeId == BCRequestTriggerHandler.nonAmazonianRecordTypeId) {
            if (bcRequest.Reason_Not_Completed__c == 'Amazon POC not found') {
                notCompletedBIM360NonAmazonian  = true;
                return checkTokenFlexLicenseRequest(bcRequest);

            } else {
                // Ext_notification_Not_Completed_APOC
                notCompletedBIM360NonAmazonian = true;
                String subject = 'BIM 360 Access Request Status: Not Completed for ' + bcRequest.Name;            
                return createEmailMessage(emailTemplateName,         // emailTemplateName
                                             bcRequest.Id,                                // relatedToId
                                             subject,                                     // subject
                                             bcRequest.APOC_Email__c                      // toAddress
                                             );
            }
        }
        return null;
    }

    // Decision : BC Request Order 3
    private static Messaging.SingleEmailMessage handlePendingTeamApprovalNotification(BC_Request__c bcRequest) {

        if (bcRequest.RecordTypeId == BCRequestTriggerHandler.tokenFlexRecordTypeId
        || bcRequest.RecordTypeId == BCRequestTriggerHandler.amazonianRecordTypeId) {
            // Ext_notification_Team_Approval_Needed_Amazonian_Requestor
            String subject = bcRequest.Name + ' Token Flex request status: Amazon Team Approval Needed';
            return createEmailMessage('Notification_Team_Approval_Needed_Amazonian',      // emailTemplateName
                                         bcRequest.Id,                                    // relatedToId
                                         subject,                                         // subject
                                         bcRequest.Requestor_Email__c                     // toAddress
                                         );


        } else if (bcRequest.RecordTypeId == BCRequestTriggerHandler.nonAmazonianRecordTypeId) {
            // Ext_notification_Team_Approval_Needed_APOC
            String subject = bcRequest.Name + ' Token Flex request status: Amazon Team Approval Needed';
            return createEmailMessage('Notification_Team_Approval_Needed_Amazonian',      // emailTemplateName
                                         bcRequest.Id,                                    // relatedToId
                                         subject,                                         // subject
                                         bcRequest.APOC_Email__c                          // toAddress
                                         );
        }

        return null;
    }

    // Decision : BC Request Order 4
    private static Messaging.SingleEmailMessage handleCompletedRequestNotification(BC_Request__c bcRequest) {
        if (bcRequest.RecordTypeId == BCRequestTriggerHandler.tokenFlexRecordTypeId
        || bcRequest.RecordTypeId == BCRequestTriggerHandler.amazonianRecordTypeId) {

            // Ext_notification_Request_completed_successfully
            sendToTokenFlexInstructions = true;
            String subject = bcRequest.Name + ' Token Flex request status: Request Completed Successfully';
            return createEmailMessage('Notification_Completed_Successfully',              // emailTemplateName
                                         bcRequest.Id,                                    // relatedToId
                                         subject,                                         // subject
                                         bcRequest.Requestor_Email__c                     // toAddress
                                         );

        } else if (bcRequest.RecordTypeId == BCRequestTriggerHandler.nonAmazonianRecordTypeId) {

            // Ext_notification_Request_completed_successfully_APOC_Requestor
            String subject = bcRequest.Name + ' Token Flex request status: Request Completed Successfully';
            return createEmailMessage('Notification_Completed_Successfully',                              // emailTemplateName
                                         bcRequest.Id,                                                    // relatedToId
                                         subject,                                                         // subject
                                         bcRequest.APOC_Email__c + ',' + bcRequest.Requestor_Email__c     // toAddress
                                         );
        }

        return null;
    }

    // Decision : BC Request Order 5
    private static Messaging.SingleEmailMessage handleActionNeeded(BC_Request__c bcRequest) {
        // Admin notification-Action needed
        String subject = 'TOKEN FLEX REQUEST: Additional information needed on Request ' + bcRequest.Name;
        return createEmailMessage('Admin_Need_more_information_notification',         // emailTemplateName
                                     bcRequest.Id,                                    // relatedToId
                                     subject,                                         // subject
                                     System.Label.BC_BIM_Central_Admin_Email          // toAddress
                                     );
    }

    // Decision : BC Request Order 6
    private static Messaging.SingleEmailMessage handleAPOCApprovalNeeded(BC_Request__c bcRequest) {
        // Ext notification-Initial: APOC Approval Request
        String subject = 'RESPONSE REQUESTED: BIM 360 Construction Cloud - 3rd Party Vendor Approval Requested ' + bcRequest.Name;
        return createEmailMessage('Initial_APOC_Approval_Request_Notification',       // emailTemplateName
                                     bcRequest.Id,                                    // relatedToId
                                     subject,                                         // subject
                                     bcRequest.APOC_Email__c                          // toAddress
                                     );
    }

    // Decision : BC Request Order 7
    private static Messaging.SingleEmailMessage handleFulfillmentReady(BC_Request__c bcRequest) {
        // Admin notification-Request ready for fulfillment
        String subject = 'TOKEN FLEX REQUEST: Additional information needed on Request ' + bcRequest.Name;
        return createEmailMessage('Admin_Request_ready_for_Autodesk_entry',           // emailTemplateName
                                     bcRequest.Id,                                    // relatedToId
                                     subject,                                         // subject
                                     System.Label.BC_BIM_Central_Admin_Email          // toAddress
                                     );

    }

    // Account Process Main Logic
    private static Messaging.SingleEmailMessage accountProcess(Account acc, String requestEmailType) {

        if (requestEmailType == 'Senior Leader approval' 
         && acc.RecordTypeId == AccountTriggerHandler.accountInternalRecordTypeId) {
            return handleSeniorLeaderApproval(acc);

        } else if (requestEmailType == 'Finance Manager response request'
                && acc.RecordTypeId == AccountTriggerHandler.accountInternalRecordTypeId) {
            return handleFinanceManagerResponseRequest(acc);

        } else if (requestEmailType == 'Send TPS notification') {
            return handleSendTPSNotification(acc);

        } else if (requestEmailType == 'Send TPS notification remainder') {
            return handleSendTPSReminderNotification(acc);

        } else if (requestEmailType == 'Send TPS notification no response') {
            return handleSendTPSNoResponseNotification(acc);

        } else if (requestEmailType == 'Send TPS notification response received') {
            return handleSendTPSResponseReceivedNotification(acc);

        } else if (requestEmailType == 'Send NDA notification') {
            return handleSendNDANotification(acc);

        }
        return null;
    }

    // Decision : Account Order 1
    private static Messaging.SingleEmailMessage handleSeniorLeaderApproval(Account acc) {
        // Ext_notification_Initial_Senior_Leader_Approval_Request
        String subject = 'RESPONSE REQUESTED: Autodesk Token Flex - Approval Requested ' + acc.Name;
        return createEmailMessage('Initial_Senior_Leader_Approval_Request_Notification',      // emailTemplateName
                                     acc.Id,                                                  // relatedToId
                                     subject,                                                 // subject
                                     acc.Senior_Leader_Email__c                               // toAddress
                                     );

    }

    // Decision : Account Order 2
    private static Messaging.SingleEmailMessage handleFinanceManagerResponseRequest(Account acc) {
        // Ext_notification_Initial_Finance_Manager_Approval_Request
        String subject = 'ACTION NEEDED: Autodesk Token Flex - Approval Requested ' + acc.Name;
        return createEmailMessage('Initial_Finance_Manager_Approval_Request_Notification',    // emailTemplateName
                                     acc.Id,                                                  // relatedToId
                                     subject,                                                 // subject
                                     acc.FM_Email__c                                          // toAddress
                                     );
    }

    // Decision : Account Order 3
    private static Messaging.SingleEmailMessage handleSendTPSNotification(Account acc) {
        // Ext_notification_Initial_TPS_Assessment_VPA
        String subject = 'Token Flex Account Status: BIM 360 Construction Cloud New Vendor - TPS Assessment [' + acc.Name + ']';
        String emailRecipients = getEmailRecipients(acc);

        return createEmailMessage('Initial_TPS_Assessment_Requested',                     // emailTemplateName
                                     acc.Id,                                              // relatedToId
                                     subject,                                             // subject
                                     emailRecipients                                      // toAddress
                                     );
    }

    // For TPS Reminder Emails
    private static Messaging.SingleEmailMessage handleSendTPSReminderNotification(Account acc) {
        // Ext_notification_Initial_TPS_Assessment_VPA
        String subject = 'REMINDER RESPONSE REQUESTED: BIM 360 Construction Cloud New Vendor - TPS Assessment [' + acc.Name + ']';
        String emailRecipients = getEmailRecipients(acc);

        return createEmailMessage('Reminder_TPS_Assessment_Requested',                     // emailTemplateName
                                        acc.Id,                                              // relatedToId
                                        subject,                                             // subject
                                        emailRecipients                   // toAddress
                                        );
    }

    // For TPS No Response
    private static Messaging.SingleEmailMessage handleSendTPSNoResponseNotification(Account acc) {
        // Ext_notification_Initial_TPS_Assessment_VPA
        String subject = 'Token Flex Team Account Status: TPS Non-Compliance for 3rd Party [' + acc.Name + ']';
        String emailRecipients = getEmailRecipients(acc);

        return createEmailMessage('Confirmation_TPS_No_Response_Received_VPA',                     // emailTemplateName
                                        acc.Id,                                              // relatedToId
                                        subject,                                             // subject
                                        emailRecipients                   // toAddress
                                        );
    }

    // For TPS Response Received
    private static Messaging.SingleEmailMessage handleSendTPSResponseReceivedNotification(Account acc) {
        // Ext_notification_Initial_TPS_Assessment_VPA
        String subject = 'Token Flex Team Status: Your approval response added';
        String emailRecipients = getEmailRecipients(acc);

        return createEmailMessage('Confirmation_TPS_Response_Received_Vendor_Amazon_Partner',               // emailTemplateName
                                        acc.Id,                                              // relatedToId
                                        subject,                                             // subject
                                        emailRecipients                  // toAddress
                                        );
    }

    // Decision : Account Order 4
    private static Messaging.SingleEmailMessage handleSendNDANotification(Account acc) {
        // Ext notification-Initial: NDA Assessment-VPA
        String subject = 'RESPONSE REQUESTED: BIM 360 Construction Cloud New Vendor - NDA response';
        return createEmailMessage('Initial_NDA_Requested',                                // emailTemplateName
                                     acc.Id,                                              // relatedToId
                                     subject,                                             // subject
                                     acc.Vendor_Amazon_Partner_Email__c                   // toAddress
                                     );
    }

    // @ Author : jed@fiduciarytech.com
    // @ Date : 6/7/2022
    // @ Desc : All decision calls this.
    //          It can basically get information in renderStoredEmailTemplate, 
    //          but there is something a little different from the function of Flow, so I reset it. 
    //          But if we can use only the email template as it is later, we can remove the setting part
    private static Messaging.SingleEmailMessage createEmailMessage(String emailTemplateName,
                                                                      String relatedToId,
                                                                      String subject,
                                                                      String toAddress) {
        

        String [] toAddresses = toAddress.split(',');
        Id emailTemplateId = CalloutUtility.EMAIL_TEMPLATE_MAP.get(emailTemplateName);
        Messaging.SingleEmailMessage emailMsg = Messaging.renderStoredEmailTemplate(emailTemplateId, null, relatedToId);
        emailMsg.setSubject(subject);
        emailMsg.setToAddresses(toAddresses);
        emailMsg.setSenderDisplayName('No-Reply-BimCentral TokenFlex Admin');
        emailMsg.setReplyTo(System.Label.BC_BIM_Central_Admin_Email);
        return emailMsg;
    }

    private static Messaging.SingleEmailMessage createEmailMessage(String emailTemplateName,
                                                                    String relatedToId,
                                                                    String subject,
                                                                    String toAddress,
                                                                    String ccAddress) {


        String [] toAddresses = toAddress.split(',');
        String [] ccAddresses = toAddress.split(',');
        Id emailTemplateId = CalloutUtility.EMAIL_TEMPLATE_MAP.get(emailTemplateName);
        Messaging.SingleEmailMessage emailMsg = Messaging.renderStoredEmailTemplate(emailTemplateId, null, relatedToId);
        // get OWA to set 
        OrgWideEmailAddress orgWideAddress = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = :System.Label.BC_BIM_Central_Admin_Email LIMIT 1];
        emailMsg.setOrgWideEmailAddressId(orgWideAddress.id);
        emailMsg.setSubject(subject);
        emailMsg.setToAddresses(toAddresses);
        if (!ccAddresses.isEmpty()) {
            emailMsg.setCCAddresses(toAddresses);
        }
        emailMsg.setSenderDisplayName('No-Reply-BimCentral TokenFlex Admin');
        
        return emailMsg;
    }

    private static String getEmailRecipients(Account acc) {
        Set<String> emailRecipients = new Set<String>();
        System.debug('-------------- getEmailRecipients ----------------');

        for (BC_Request__c bcRequest : acc.Requests2__r) {
            String recipientEmail      = bcRequest.Recipient__r.Email;
            String contractHolderEmail = bcRequest.Contract_Holder_Contact_Email__c;
            String apocEmail           = bcRequest.Amazon_POC__r.Email;

            if (String.IsNotBlank(recipientEmail)) {
                emailRecipients.add(recipientEmail);
            }
            if (String.IsNotBlank(contractHolderEmail)) {
                emailRecipients.add(contractHolderEmail);
            }
            if (String.IsNotBlank(apocEmail)) {
                emailRecipients.add(apocEmail);
            }
        }

        if(emailRecipients.isEmpty()) {
            return '';
        } else {
            return String.join(new List<String>(emailRecipients), ', ');
        }
    }
}