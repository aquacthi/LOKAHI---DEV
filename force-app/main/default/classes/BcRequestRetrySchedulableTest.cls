@IsTest
private class BcRequestRetrySchedulableTest {

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

    @IsTest
    static void testRetry() {
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

        bcq.Status__c = 'Open';
        bcq.Stage__c = 'New';
        bcq.Disable_Automation__c = true;
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        update bcq;

        Test.startTest();
            BcRequestRetrySchedulable bc = new BcRequestRetrySchedulable(1);
            bc.execute(null);
        Test.stopTest();

    }
}