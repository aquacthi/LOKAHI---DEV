public with sharing class BimBulkAddUsersToProjectsControllerTest {
    // @TestSetup
    // static void setup() {
    //     Autodesk_Setting__c cs = new Autodesk_Setting__c();
    //     cs.Account_Id__c = 'test_account_id';
    //     cs.Company_Id__c = 'test_company_id';
    //     cs.X_User_Id__c = 'test_x_user_id';
    //     cs.App_Id__c = 'test_app_id';
    //     cs.App_Secret__c = 'test_app_secret';
    //     cs.Error_Email_Recipients__c = 'errorEmailRecipient@test.com';
    //     cs.Valid_Record_Type__c = 'BIM_360_Amazonian, BIM_360_Non_Amazonian';
    //     insert cs;
    // }

    // @IsTest
    // static void testUpdateProcessBlankProjectAmazonUser() {
    //     BC_BIM_Project__c proj = new BC_BIM_Project__c(
    //         Project_Name__c = 'Test Project',
    //         Facility_Name__c = 'Test Project',
    //         Active__c = true
    //     );
    //     insert proj;

    //     BC_Request__c req = new BC_Request__c();
    //     req.RecordTypeId = Schema.SObjectType.BC_Request__c.getRecordTypeInfosByDeveloperName().get('BIM_360_Amazonian').getRecordTypeId();
    //     req.Recipient_Email__c = 'test@amazon.com';
    //     req.Recipient_First_Name__c = 'testrecipient'; 
    //     req.Recipient_Last_Name__c = 'recipient';
    //     req.Requestor_Email__c = 'testrequestor@amazon.com';
    //     req.Requestor_First_Name__c = 'test';
    //     req.Requestor_Last_Name__c = 'requestor';
    //     insert req;

    //     Request_Project__c requestProj = new Request_Project__c();
    //     requestProj.Request__c = req.Id;
    //     requestProj.Project_Name_Entered__c = 'test project';
    //     insert requestProj;

    //     Test.startTest();
    //     Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

    //     requestProj.Project_Record_Name__c = proj.Id;
    //     update requestProj;

    //     API_Log__c apiLog = new API_Log__c();
    //     apiLog.BC_Request__c = req.Id;
    //     apiLog.BIM_360_Project_Role_Info__c = '{"id":"testRoleId","project_id":"projectId","name":"test","services":{"project_administration":{"access_level":"no_access"},"document_management":{"access_level":"user"},"project_management":{"access_level":"user"},"insight":{"access_level":"user"}},"member_group_id":"1234"}';
    //     apiLog.BIM_360_User_Id__c = 'testUserId';
    //     apiLog.BIM_360_Company_Id__c = 'testCompanyId';
    //     apiLog.BIM_360_User_Status__c = 'Pending';

    //     insert apiLog;

    //     Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

    //     req.Is_Redshit_Get_User_Info_Success__c = true;
    //     update req;      

    //     Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

    //     Test.stopTest();

        
    //     req = [SELECT Id, Is_BIM_Project_Blank__c, BIM_Project_Corrected__c, Stage__c
    //            FROM BC_Request__c
    //            WHERE Id = :req.Id];
    // }
}