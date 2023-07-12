@isTest
private with sharing class BIM360ProjectSyncBatchTest {

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

        BC_BIM_Project__c project = new BC_BIM_Project__c();
        project.Project_Name__c = 'Test Project';
        project.AD_ID__c = 'random-autodesk-id';
        project.Active__c = true;
        project.Project_Type__c = 'Site-Specific';
        project.Facility_Name__c = 'Test';
        insert project;
    }

    @isTest
    static void testBIM360ProjectSyncBatch() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        Test.startTest();
        BIM360ProjectSyncBatch s = new BIM360ProjectSyncBatch();
        s.execute(null);
        Test.stopTest();
    }

}