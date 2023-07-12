@IsTest
private class ApiLogTriggerHandlerTest {
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

    @IsTest
    static void testGetUserSearch() {
        BC_Request__c req = new BC_Request__c();
        req.Recipient_Email__c = 'test@amazon.com';
        req.Recipient_First_Name__c = 'testrecipient'; 
        req.Recipient_Last_Name__c = 'recipient';
        req.Requestor_Email__c = 'testrequestor@amazon.com';
        req.Requestor_First_Name__c = 'test';
        req.Requestor_Last_Name__c = 'requestor';
        insert req;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        API_Log__c source = new API_Log__c();
        source.BC_Request__c = req.Id;
        source.BIM_360_Project_Role_Info__c = '{"id":"testRoleId","project_id":"projectId","name":"test","services":{"project_administration":{"access_level":"no_access"},"document_management":{"access_level":"user"},"project_management":{"access_level":"user"},"insight":{"access_level":"user"}},"member_group_id":"1234"}';
        source.BIM_360_User_Id__c = 'testUserId';
        source.BIM_360_Company_Id__c = 'testCompanyId';
        source.BIM_360_User_Status__c = 'Pending';

        API_Log__c apiLog = ApiLogTriggerHandler.createGetUserSearchApiLog(source, 'test');
        insert apiLog;
        Test.stopTest();
    }

    @IsTest
    static void testPatchUserToActive() {
        BC_Request__c req = new BC_Request__c();
        req.Recipient_Email__c = 'test@amazon.com';
        req.Recipient_First_Name__c = 'testrecipient'; 
        req.Recipient_Last_Name__c = 'recipient';
        req.Requestor_Email__c = 'testrequestor@amazon.com';
        req.Requestor_First_Name__c = 'test';
        req.Requestor_Last_Name__c = 'requestor';
        insert req;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        API_Log__c source = new API_Log__c();
        source.BC_Request__c = req.Id;
        source.BIM_360_Project_Role_Info__c = '{"id":"testRoleId","project_id":"projectId","name":"test","services":{"project_administration":{"access_level":"no_access"},"document_management":{"access_level":"user"},"project_management":{"access_level":"user"},"insight":{"access_level":"user"}},"member_group_id":"1234"}';
        source.BIM_360_User_Id__c = 'testUserId';
        source.BIM_360_Company_Id__c = 'testCompanyId';
        source.BIM_360_User_Status__c = 'Pending';

        API_Log__c apiLog = ApiLogTriggerHandler.createPatchUserToActiveApiLog(source);
        insert apiLog;
        Test.stopTest();
    }

    @IsTest
    static void testGetCompanyNameSearch() {
        BC_Request__c req = new BC_Request__c();
        req.Recipient_Email__c = 'test@amazon.com';
        req.Recipient_First_Name__c = 'testrecipient'; 
        req.Recipient_Last_Name__c = 'recipient';
        req.Requestor_Email__c = 'testrequestor@amazon.com';
        req.Requestor_First_Name__c = 'test';
        req.Requestor_Last_Name__c = 'requestor';
        insert req;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        API_Log__c source = new API_Log__c();
        source.BC_Request__c = req.Id;
        source.BIM_360_Project_Role_Info__c = '{"id":"testRoleId","project_id":"projectId","name":"test","services":{"project_administration":{"access_level":"no_access"},"document_management":{"access_level":"user"},"project_management":{"access_level":"user"},"insight":{"access_level":"user"}},"member_group_id":"1234"}';
        source.BIM_360_User_Id__c = 'testUserId';
        source.BIM_360_Company_Id__c = 'testCompanyId';
        source.BIM_360_User_Status__c = 'Pending';

        API_Log__c apiLog = ApiLogTriggerHandler.createGetCompanyNameSearchApiLog(source);
        insert apiLog;
        Test.stopTest();
    }

    @IsTest
    static void testPatchUserCompanyName() {
        BC_Request__c req = new BC_Request__c();
        req.Recipient_Email__c = 'test@amazon.com';
        req.Recipient_First_Name__c = 'testrecipient'; 
        req.Recipient_Last_Name__c = 'recipient';
        req.Requestor_Email__c = 'testrequestor@amazon.com';
        req.Requestor_First_Name__c = 'test';
        req.Requestor_Last_Name__c = 'requestor';
        insert req;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        API_Log__c source = new API_Log__c();
        source.BC_Request__c = req.Id;
        source.BIM_360_Project_Role_Info__c = '{"id":"testRoleId","project_id":"projectId","name":"test","services":{"project_administration":{"access_level":"no_access"},"document_management":{"access_level":"user"},"project_management":{"access_level":"user"},"insight":{"access_level":"user"}},"member_group_id":"1234"}';
        source.BIM_360_User_Id__c = 'testUserId';
        source.BIM_360_Company_Id__c = 'testCompanyId';
        source.BIM_360_User_Status__c = 'Pending';

        API_Log__c apiLog = ApiLogTriggerHandler.createPatchUserCompanyNameApiLog(source);
        insert apiLog;
        Test.stopTest();
    }

    @IsTest
    static void testPostUser() {
        BC_Request__c req = new BC_Request__c();
        req.Recipient_Email__c = 'test@amazon.com';
        req.Recipient_First_Name__c = 'testrecipient'; 
        req.Recipient_Last_Name__c = 'recipient';
        req.Requestor_Email__c = 'testrequestor@amazon.com';
        req.Requestor_First_Name__c = 'test';
        req.Requestor_Last_Name__c = 'requestor';
        insert req;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        API_Log__c source = new API_Log__c();
        source.BC_Request__c = req.Id;
        source.BIM_360_Project_Role_Info__c = '{"id":"testRoleId","project_id":"projectId","name":"test","services":{"project_administration":{"access_level":"no_access"},"document_management":{"access_level":"user"},"project_management":{"access_level":"user"},"insight":{"access_level":"user"}},"member_group_id":"1234"}';
        source.BIM_360_User_Id__c = 'testUserId';
        source.BIM_360_Company_Id__c = 'testCompanyId';
        source.BIM_360_User_Status__c = 'Pending';

        API_Log__c apiLog = ApiLogTriggerHandler.createPostUserApiLog(source);
        insert apiLog;
        Test.stopTest();
    }

    @IsTest
    static void testPostUserToProject() {
        BC_Request__c req = new BC_Request__c();
        req.Recipient_Email__c = 'test@amazon.com';
        req.Recipient_First_Name__c = 'testrecipient'; 
        req.Recipient_Last_Name__c = 'recipient';
        req.Requestor_Email__c = 'testrequestor@amazon.com';
        req.Requestor_First_Name__c = 'test';
        req.Requestor_Last_Name__c = 'requestor';
        insert req;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        API_Log__c source = new API_Log__c();
        source.BC_Request__c = req.Id;
        source.BIM_360_Project_Role_Info__c = '{"id":"testRoleId","project_id":"projectId","name":"test","services":{"project_administration":{"access_level":"no_access"},"document_management":{"access_level":"user"},"project_management":{"access_level":"user"},"insight":{"access_level":"user"}},"member_group_id":"1234"}';
        source.BIM_360_User_Id__c = 'testUserId';
        source.BIM_360_Company_Id__c = 'testCompanyId';
        source.BIM_360_User_Status__c = 'Pending';

        API_Log__c apiLog = ApiLogTriggerHandler.createPostUserToProjectApiLog(source);
        insert apiLog;
        Test.stopTest();
    }
}