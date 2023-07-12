@IsTest
private class BIM360StagingProjectTriggerHandlerTest {
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
    static void testBim360StagingProject() {
        BIM360_Staging_Project__c sp = new BIM360_Staging_Project__c();
        sp.csv_Address_Line_1__c = '123 test st';
        sp.csv_City__c = 'Seattle';
        sp.csv_Construction_Type__c = 'New Construction';
        sp.csv_Contract_Type__c = 'IPD';
        sp.csv_Country__c = 'United States';
        sp.csv_End_Date__c = '2022-02-01';
        sp.csv_Include_Companies__c = 'true';
        sp.csv_Include_Locations__c = 'true';
        sp.csv_Job_Number__c = '123';
        sp.csv_Project_Name__c = 'test';
        sp.csv_Postal_Code__c = '99999';
        sp.csv_Project_Currency__c = 'USD';
        sp.csv_Project_Type__c = 'Airport';
        sp.csv_Project_Value__c = '1';
        sp.csv_Row_Number__c = '1';
        sp.csv_Services__c = 'projectAdministration;documentManagement;insight';
        sp.csv_Start_Date__c = '2022-01-01';
        sp.csv_State_Province__c = 'WA';
        sp.csv_Template_Project_Id__c = '';
        sp.csv_Time_Zone__c = '';
        insert sp;

        sp.BIM360_Staging_Project_Status__c = 'Callout Initiated';
        sp.BIM360_Staging_Project_Type__c = 'Insert';
        update sp;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

        Test.startTest();
        sp.BIM360_Staging_Project_Type__c = 'Update';
        update sp;
        Test.stopTest();
    }
}