@IsTest
private class BIM360StagingUserTriggerHandlerTest {
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
    static void testBim360StagingUser() {
        BIM360_Staging_User__c su = new BIM360_Staging_User__c();
        su.csv_Company_Id__c = '';
        su.csv_Email__c = 'test@test.com';
        su.csv_Project_Id__c = '123';
        su.csv_Role_Ids__c = '';
        su.csv_Services__c = 'projectAdministration;documentManagement;insight';
        insert su;

        su.BIM360_Staging_User_Status__c = 'Callout Initiated';
        su.BIM360_Staging_User_Type__c = 'Insert';
        update su;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

        Test.startTest();
        su.BIM360_Staging_User_Type__c = 'Update';
        update su;
        Test.stopTest();
    }
}