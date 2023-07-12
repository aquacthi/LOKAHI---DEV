/****************************************************************************************
* File Name   : TPSEmailsBatch
* Description : This batch class will send out TPS notification emails on a cadence of:
                1. Initial External Account creation
                2. 90 days from due date
                3. 45 days from due date
                4. 0 days from due date

                Approved or Not Approved Emails are also sent based on TPS status.

                Manually execute with script below
                    TPSEmailsBatch b = new TPSEmailsBatch();
                    b.execute(null);

                Schedule Job 
                    Do this manually - Setup > Apex Class > Schedule Apex Class
                    Should run daily at 8AM PST
* Author      : Amazon
* Modification Log
* ===============================================================
* Ver  Date           Author          Modification
* ===============================================================
* 1.0  09/08/2022     Blong Thao      Created
****************************************************************************************/

global with sharing class TPSEmailsBatch implements Database.Batchable<sObject>, Schedulable {

    global OrgWideEmailAddress sender = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'bimcentral-tokenflex-admin@amazon.com'];

    global String SEND_TPS_NOTIFICATION = 'Send TPS notification';
    global String SEND_TPS_NOTIFICATION_REMAINDER = 'Send TPS notification remainder';
    global String SEND_TPS_NOTIFICATION_NO_RESPONSE = 'Send TPS notification no response';
    global String SEND_TPS_NOTIFICATION_RESPONSE_RECIEVED = 'Send TPS notification response received';
    global String STATUS_PENDING_RESPONSE = 'Pending Response';
    global String STATUS_NOT_APPROVED = 'Not Approved';
    global String STATUS_APPROVED = 'Approved';
    global String STATUS_NO_RESPONSE = 'No Response';
    global Integer REMINDER_EMAIL_1_DAYS = 90; 
    global Integer REMINDER_EMAIL_2_DAYS = 45; 
    global Integer REMINDER_EMAIL_3_DAYS = 0; 

    public TPSEmailsBatch() {

    }

    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Query for external accounts, additionally all requests and contacts?
        String strQuery = 'SELECT Id, Name, TPS_Status__c, TPS_Assessment__c, Vendor_Amazon_Partner_Email__c, ' +
                            ' X1st_TPS_Notification_Sent__c, ' +
                            ' X2nd_TPS_Notification_Sent__c, ' +
                            ' X3rd_TPS_Notification_Sent__c, ' +
                            ' TPS_Deactivation_Notification_Sent__c, ' +
                            ' TPS_Approved_Notification_Sent__c, ' +
                            ' TPS_Approved_Date__c, ' +
                            ' Days_till_TPS_due_date__c, ' +
                            // Requests1__r	- is the BC_Request__c.Recipient_Company__c lookup, should we be checking this? Need to confirm in Production
                            // ' (SELECT Id, Recipient__r.Email, Amazon_POC__r.Email, Senior_Leader__r.Email FROM Requests1__r),' +
                            // Requests2__r	- is the BC_Request__c.Amazon_Contract_Holder_Vendor__c lookup, we should be checking this? Need to confirm in Production
                            ' (SELECT Id, Recipient__r.Email, Amazon_POC__r.Email, Senior_Leader__r.Email, Contract_Holder_Contact_Email__c FROM Requests2__r)' +
                            // 4 different BC_Request related lists - but we only want the one from Requests2__r 
                            // because it is the BC_Request__c.Amazon_Contract_Holder_Vendor__c lookup
                          ' FROM Account WHERE RecordType.Name = \'External\'';
        return Database.getQueryLocator(strQuery);
    }

    /**
     * 0. Send Deactivation Notification on Not Approved
     * 0. Send Approved Notification on Approval
     * 1. Send Initial Email - on production deployment, will reset this for all external accounts
     * 2. Send Reminder Email on day 90 (from Due Date)
     * 3. Send Reminder Email on day 30 (from Due Date)
     * 4. Send final email on day 0 (from Due Date)
     */
    global void execute(Database.BatchableContext bc, List<Account> scope) {
        System.debug('-------execute TPSEmailbatch---------');   
        // should emails send only when all updates are done without failure?
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        List<Account> accountsToUpdate = new List<Account>();
        System.debug(scope);   

        for (Account acct : scope) {            
            // No requests for Amazon Contract Holder Vendors, then no emails need to be sent for this account?
            if (acct.Requests2__r.isEmpty()) continue;
            System.debug(acct);   
            Boolean updateAccount = false;
            Boolean firstEmailSent = acct.X1st_TPS_Notification_Sent__c != null; 
            Boolean secondEmailSent = firstEmailSent && acct.X2nd_TPS_Notification_Sent__c != null;
            Boolean thirdEmailSent = secondEmailSent && acct.X3rd_TPS_Notification_Sent__c != null;

            // send deactivation email
            // if account tps status is Not Approved and account tps deactivation notification sent is blank
            // then send tps notification no response email
            if (acct.TPS_Status__c == STATUS_NOT_APPROVED && 
                acct.TPS_Deactivation_Notification_Sent__c == null) {
                System.debug('-------deactivation email execute---------');   
                updateAccount = true;
                acct.TPS_Deactivation_Notification_Sent__c = DateTime.now();
                emailsToSend.addAll(EmailCommunication.getEmailMessageList(acct, SEND_TPS_NOTIFICATION_NO_RESPONSE));
            }            
            // send approved email
            // if account tps status is Approved and account tps approved notification sent is blank
            // then send tps notification response received email
            else if (
                acct.TPS_Status__c == STATUS_APPROVED && 
                acct.TPS_Approved_Notification_Sent__c == null) {
                System.debug('-------send approved email execute---------'); 
                updateAccount = true;
                acct.TPS_Approved_Notification_Sent__c = DateTime.now();
                emailsToSend.addAll(EmailCommunication.getEmailMessageList(acct, SEND_TPS_NOTIFICATION_RESPONSE_RECIEVED));
            }
            // else 
            // if account tps status is Pending Response
            else if(acct.TPS_Status__c == STATUS_PENDING_RESPONSE) { 
                System.debug('-------status pending response---------');
                // send initial email
                // if 1st tps notification sent is blank
                // then send initial tps notification email and set 1st tps notification sent to today's date
                if (acct.X1st_TPS_Notification_Sent__c == null) {
                    System.debug('-------send initial email execute---------');  
                    updateAccount = true;
                    emailsToSend.addAll(EmailCommunication.getEmailMessageList(acct, SEND_TPS_NOTIFICATION));
                    acct.X1st_TPS_Notification_Sent__c = DateTime.now();
                }
                // Send reminder email 1                
                // if account days till tps due date is 90 and first email was sent and 2nd tps notification sent is blank
                // then send tps reminder notification email  and set 2nd tps notification sent to today's date
                else if (acct.Days_till_TPS_due_date__c == REMINDER_EMAIL_1_DAYS &&
                    firstEmailSent && acct.X2nd_TPS_Notification_Sent__c == null) {
                    System.debug('-------Send reminder email 1 execute---------'); 
                    updateAccount = true;

                    emailsToSend.addAll(EmailCommunication.getEmailMessageList(acct, SEND_TPS_NOTIFICATION_REMAINDER));
                    acct.X2nd_TPS_Notification_Sent__c = DateTime.now();
                }
                // Send reminder email 2 
                // if account days till tps due date is 45 and first/second email was sent and 3rd tps notification sent is blank
                // then send tps reminder notification email and set 3rd tps notification sent to today's date
                else if (acct.Days_till_TPS_due_date__c == REMINDER_EMAIL_2_DAYS &&
                    secondEmailSent && acct.X3rd_TPS_Notification_Sent__c == null) {
                    System.debug('-------Send reminder email 2 execute---------');     
                    updateAccount = true;
                    emailsToSend.addAll(EmailCommunication.getEmailMessageList(acct, SEND_TPS_NOTIFICATION_REMAINDER));
                    acct.X3rd_TPS_Notification_Sent__c = DateTime.now();
                }
                // Send deactivation email 
                // if account days till tps due date is 0 and first/second/third email was sent and 4th tps notification sent is blank
                // then send tps no response notification email and set 4th tps notification sent to today's date
                //   and set the tps status to No Response
                else if (acct.Days_till_TPS_due_date__c == REMINDER_EMAIL_3_DAYS &&
                    thirdEmailSent && acct.TPS_Deactivation_Notification_Sent__c == null) {
                    System.debug('-------Send deactivation email execute---------');   
                    updateAccount = true;
                    emailsToSend.addAll(EmailCommunication.getEmailMessageList(acct, SEND_TPS_NOTIFICATION_NO_RESPONSE));
                    acct.TPS_Deactivation_Notification_Sent__c = DateTime.now();
                    acct.TPS_Status__c = STATUS_NO_RESPONSE;
                }
            }
            if (updateAccount) {
                accountsToUpdate.add(acct);
            }
        }
        try {
            if (!accountsToUpdate.isEmpty()) {
                update accountsToUpdate;
            }

            if (!emailsToSend.isEmpty()) {
                Messaging.sendEmail(emailsToSend, false);
            }                
        } catch (Exception e) {
            // update or email send failed            
            System.debug('-------Exception---------');   
            System.debug(e.getMessage());   
        }

    }

    global void finish(Database.BatchableContext BC) {

    }


    /**
     * @method name: void execute(SchedulableContext sc)
     * @description: calls the Database.executeBatch method to start processing the batches.
     * */
    global void execute(SchedulableContext sc) {
        // Start batch
        TPSEmailsBatch b = new TPSEmailsBatch();
        Database.executeBatch(b);
    }
}