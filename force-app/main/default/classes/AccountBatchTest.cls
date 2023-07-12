@IsTest
public with sharing class AccountBatchTest {
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
    static void AccountBatchTest() {
        List<Account> accountListToUpdate = new List<Account>();
        List<Messaging.SingleEmailMessage> emailsToSend  = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage emailMsg = new Messaging.SingleEmailMessage();
        
        Account acc = new Account(Name = 'Test AccountBatch',
            Stage__c = 'Pending SL Approval',
            Approval_Response__c = null,
            Billing_Codes_Entered__c = false,
            Senior_Leader_Approval_Attempts__c = (Decimal)0,
            FM_Email__c = 'testfmemail@email.com',
            Last_SL_Approval_Sent__c = DateTime.Now().AddDays(-2),
            Reason_for_Inactive_Status__c = '',
            Last_FM_Approval_Sent__c = DateTime.Now().AddDays(-2));
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Internal').getRecordTypeId();
        insert acc;

        String [] toAddresses = (acc.Owner.Email + ',' + acc.Senior_Leader__r.Email).split(',');
        emailMsg = Messaging.renderStoredEmailTemplate(CalloutUtility.EMAIL_TEMPLATE_MAP.get('Reminder_Senior_Leader_Approval_Request_Notification'), null, acc.id);
        emailMsg.setSubject('REMINDER RESPONSE REQUESTED: Autodesk Token Flex - Approval Requested ' + acc.Name);
        emailMsg.setToAddresses(toAddresses);
        emailMsg.saveAsActivity = false;
        emailMsg.setSenderDisplayName('No-Reply-BimCentral TokenFlex Admin');
        emailMsg.setReplyTo(System.Label.BC_BIM_Central_Admin_Email);
        emailsToSend.add(emailMsg);

        Account acc2 = new Account(Name = 'Test AccountBatch2',
            Stage__c = 'Pending SL Approval',
            Approval_Response__c = null,
            Billing_Codes_Entered__c = false,
            Senior_Leader_Approval_Attempts__c = (Decimal)5,
            FM_Email__c = 'testfmemail2@email.com',
            Last_SL_Approval_Sent__c = DateTime.Now().AddDays(-2),
            Reason_for_Inactive_Status__c = '',
            Finance_Manager_Approval_Attempts__c = (Decimal)0,
            Last_FM_Approval_Sent__c = DateTime.Now().AddDays(-2));
        acc2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Internal').getRecordTypeId();
        insert acc2;

        Account acc3 = new Account(Name = 'Test AccountBatch3',
        Stage__c = 'Pending Finance Approval',
        Approval_Response__c = null,
        Billing_Codes_Entered__c = false,
        Finance_Manager_Approval_Attempts__c = (Decimal)0,
        FM_Email__c = 'testfmemail3@email.com',
        Reason_for_Inactive_Status__c = '',
        Last_FM_Approval_Sent__c = DateTime.Now().AddDays(-2));
        acc3.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Internal').getRecordTypeId();
        insert acc3;

        Account acc4 = new Account(Name = 'Test AccountBatch4',
        Stage__c = 'Pending Finance Approval',
        Approval_Response__c = null,
        Billing_Codes_Entered__c = false,
        Finance_Manager_Approval_Attempts__c = (Decimal)5,
        FM_Email__c = 'testfmemail4@email.com',
        Reason_for_Inactive_Status__c = '',
        Last_FM_Approval_Sent__c = DateTime.Now().AddDays(-2));
        acc4.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Internal').getRecordTypeId();
        insert acc4;

        accountListToUpdate.add(acc);
        accountListToUpdate.add(acc2);
        accountListToUpdate.add(acc3);
        accountListToUpdate.add(acc4);

        if (!accountListToUpdate.isEmpty()) {
            update accountListToUpdate;
        }

        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend, false);
        }

       Test.startTest();
            AccountBatch ac = new AccountBatch();
            Database.executeBatch(ac);
        Test.stopTest();

        acc = [SELECT Id, Last_SL_Approval_Sent__c, Senior_Leader_Approval_Attempts__c
               FROM Account
               WHERE Id = :acc.Id];
        //System.assertEquals(Datetime.now(), acc.Last_SL_Approval_Sent__c);
        // System.assertEquals(1, acc.Senior_Leader_Approval_Attempts__c);
  

        acc2 = [SELECT Id, Stage__c, Reason_for_Inactive_Status__c
                FROM Account
                WHERE Id = :acc2.Id];
        // System.assertEquals('Inactive', acc2.Stage__c);
        // System.assertEquals('No response from Senior Leader', acc2.Reason_for_Inactive_Status__c);

        acc3 = [SELECT Id, Last_FM_Approval_Sent__c, Finance_Manager_Approval_Attempts__c
        FROM Account
        WHERE Id = :acc3.Id];
        //System.assertEquals(Datetime.now(), acc3.Last_FM_Approval_Sent__c);
        // System.assertEquals(1, acc3.Finance_Manager_Approval_Attempts__c);

        
        acc4 = [SELECT Id, Stage__c, Reason_for_Inactive_Status__c
        FROM Account
        WHERE Id = :acc4.Id];
        // System.assertEquals('Inactive', acc4.Stage__c);
        // System.assertEquals('No response from Finance Manager', acc4.Reason_for_Inactive_Status__c);

    }
}