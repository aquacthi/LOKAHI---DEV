@IsTest

public with sharing class BcRequestBatchTest {
    @TestSetup
    static void makeData() {
        Autodesk_Setting__c cs = new Autodesk_Setting__c();
        cs.Account_Id__c = 'test_account_id';
        cs.Company_Id__c = 'test_company_id';
        cs.X_User_Id__c = 'test_x_user_id';
        cs.App_Id__c = 'test_app_id';
        cs.App_Secret__c = 'test_app_secret';
        cs.Error_Email_Recipients__c = 'errorEmailRecipient@test.com';
        cs.Valid_Record_Type__c = 'BIM_360_Amazonian, BIM_360_Non_Amazonian';
        insert cs;

    }
  
    @isTest
    static void bcRequestBatchTest() {
        List<BC_Request__c> bcRequestListToUpdate = new List<BC_Request__c>();
        List<Messaging.SingleEmailMessage> emailsToSend  = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage emailMsg = new Messaging.SingleEmailMessage();

        BC_Request__c bcq = new BC_Request__c(
            Recipient_Email__c = 'recipient@nonamazon.com',
            Recipient_First_Name__c = 'recipient',
            Recipient_Last_Name__c = 'test',
            Recipient_Company_Entered__c = 'recipientcompanynonamazon',
            Requestor_Email__c = 'requestor@nonamazon.com',
            Requestor_First_Name__c = 'requestor',
            Requestor_Last_Name__c = 'test',
            Requestor_Company_Entered__c = 'requestorcompanynonamazon',
            Stage__c = 'Pending APOC Approval',
            APOC_Email__c = 'apoc@amazon.com',
            APOC_Last_Approval_Sent__c = DateTime.Now().AddDays(-2),
            APOC_Approval__c = null,
            APOC_Reminder_Notification_Count__c =(Decimal)0,
            Other_Reason_Not_Completed__c ='',
            Reason_Not_Completed__c ='',
            Amazon_Contract_Holder_Entered__c = 'amazoncontractholder');
        bcq.RecordTypeId = Schema.SObjectType.BC_Request__c.getRecordTypeInfosByDeveloperName().get('BIM_360_Non_Amazonian').getRecordTypeId();            
        insert bcq;


        String [] toAddresses = (bcq.Owner.Email + ',' + bcq.Amazon_POC__r.Email).split(',');
        emailMsg = Messaging.renderStoredEmailTemplate(CalloutUtility.EMAIL_TEMPLATE_MAP.get('Reminder_APOC_Approval_Request_Notification'), null, bcq.id);
        emailMsg.setSubject('REMINDER RESPONSE REQUESTED: BIM 360 Construction Cloud - 3rd Party Vendor Approval Requested ' + bcq.Name);
        emailMsg.setToAddresses(toAddresses);
        emailMsg.saveAsActivity = false;
        emailMsg.setSenderDisplayName('No-Reply-BimCentral TokenFlex Admin');
        emailMsg.setReplyTo(System.Label.BC_BIM_Central_Admin_Email);
        emailsToSend.add(emailMsg);

        BC_Request__c bcq2 = new BC_Request__c(
            Recipient_Email__c = 'recipient2@nonamazon.com',
            Recipient_First_Name__c = 'recipient2',
            Recipient_Last_Name__c = 'test2',
            Recipient_Company_Entered__c = 'recipientcompanynonamazon2',
            Requestor_Email__c = 'requestor2@nonamazon.com',
            Requestor_First_Name__c = 'requestor2',
            Requestor_Last_Name__c = 'test2',
            Requestor_Company_Entered__c = 'requestorcompanynonamazon2',
            Stage__c = 'Pending APOC Approval',
            APOC_Email__c = 'apoc2@amazon.com',
            APOC_Last_Approval_Sent__c = DateTime.Now().AddDays(-2),
            APOC_Approval__c = null,
            APOC_Reminder_Notification_Count__c = (Decimal)4,
            Other_Reason_Not_Completed__c ='',
            Reason_Not_Completed__c ='',
            Amazon_Contract_Holder_Entered__c = 'amazoncontractholder2');
        bcq2.RecordTypeId = Schema.SObjectType.BC_Request__c.getRecordTypeInfosByDeveloperName().get('BIM_360_Non_Amazonian').getRecordTypeId();            
        insert bcq2;

        bcRequestListToUpdate.add(bcq);
        bcRequestListToUpdate.add(bcq2);

        if(!bcRequestListToUpdate.isEmpty()) {
            update bcRequestListToUpdate;
        } 

        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend, false);
        }

        Test.startTest();
            BcRequestBatch bc = new BcRequestBatch();
            Database.executeBatch(bc);
        Test.stopTest();

        bcq = [SELECT Id, APOC_Last_Approval_Sent__c, APOC_Reminder_Notification_Count__c  
               FROM BC_Request__c
               WHERE Id =: bcq.Id];
        System.assertEquals(1, bcq.APOC_Reminder_Notification_Count__c);
        
        bcq2 = [SELECT Id, Other_Reason_Not_Completed__c , Reason_Not_Completed__c, Stage__c
                FROM BC_Request__c
                WHERE Id =: bcq2.Id];
        System.assertEquals('APOCapproval not received after multiple attempts', bcq2.Other_Reason_Not_Completed__c);
        System.assertEquals('No response', bcq2.Reason_Not_Completed__c);
        System.assertEquals('Resolved - Not Completed', bcq2.Stage__c);
    }
}