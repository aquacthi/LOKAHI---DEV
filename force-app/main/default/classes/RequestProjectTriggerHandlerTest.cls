@IsTest
private with sharing class RequestProjectTriggerHandlerTest {
    @TestSetup
    static void setup() {
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
    static void test_onInsert() {
        BC_BIM_Project__c proj = new BC_BIM_Project__c();
        insert proj;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        BC_Request__c req = new BC_Request__c();
        req.RecordTypeId = Schema.SObjectType.BC_Request__c.getRecordTypeInfosByDeveloperName().get('BIM_360_Amazonian').getRecordTypeId();
        req.Recipient_Email__c = 'recipient@amazon.com';
        req.Recipient_First_Name__c = 'recipient'; 
        req.Recipient_Last_Name__c = 'test';
        req.Requestor_Email__c = 'requestor@amazon.com';
        req.Requestor_First_Name__c = 'requestor';
        req.Requestor_Last_Name__c = 'test';  
        req.Enter_Project_Name__c = false;  
        req.BIM_Project__c = proj.Id;    
        insert req;

        Request_Project__c rp = new Request_Project__c();
        rp.Request__c = req.Id;
        rp.Project_Record_Name__c = proj.Id;
        insert rp;

        // test duplicate request
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        BC_Request__c req2 = new BC_Request__c();
        req2.RecordTypeId = Schema.SObjectType.BC_Request__c.getRecordTypeInfosByDeveloperName().get('BIM_360_Amazonian').getRecordTypeId();
        req2.Recipient_Email__c = 'recipient@amazon.com';
        req2.Recipient_First_Name__c = 'recipient'; 
        req2.Recipient_Last_Name__c = 'test';
        req2.Requestor_Email__c = 'requestor@amazon.com';
        req2.Requestor_First_Name__c = 'requestor';
        req2.Requestor_Last_Name__c = 'test';  
        req2.Enter_Project_Name__c = false;  
        req2.BIM_Project__c = proj.Id;    
        insert req2;

        Test.stopTest();

        Request_Project__c rp2 = new Request_Project__c();
        rp2.Request__c = req2.Id;
        rp2.Project_Record_Name__c = proj.Id;
        insert rp2;
    }

    @isTest
    static void test_onUpdate() {
        BC_BIM_Project__c proj = new BC_BIM_Project__c();
        insert proj;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        BC_Request__c req = new BC_Request__c();
        req.RecordTypeId = Schema.SObjectType.BC_Request__c.getRecordTypeInfosByDeveloperName().get('BIM_360_Amazonian').getRecordTypeId();
        req.Recipient_Email__c = 'recipient@amazon.com';
        req.Recipient_First_Name__c = 'recipient'; 
        req.Recipient_Last_Name__c = 'test';
        req.Requestor_Email__c = 'requestor@amazon.com';
        req.Requestor_First_Name__c = 'requestor';
        req.Requestor_Last_Name__c = 'test';  
        req.Enter_Project_Name__c = false;  
        req.BIM_Project__c = proj.Id;    
        insert req;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

        Test.stopTest();

        Request_Project__c rp = new Request_Project__c();
        rp.Request__c = req.Id;
        rp.Project_Name_Entered__c = 'TEST PROJECT';
        insert rp;

        Request_Project__c rp2 = new Request_Project__c();
        rp2.Request__c = req.Id;
        rp2.Project_Name_Entered__c = 'TEST PROJECT2';
        insert rp2;

        rp.Project_Record_Name__c = proj.Id;
        update rp;

        rp2.Project_Record_Name__c = proj.Id;
        update rp2;

        
    }


}