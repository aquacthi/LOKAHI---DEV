@IsTest
private with sharing class RequestApprovalControllerTest {
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
    static void test_getRequestApprover() {
                
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

        RequestApprovalController.getRequestApprover(req.Id);
    }

    @IsTest
    static void test_getRequestProjectList() {
        
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

        RequestApprovalController.getRequestProjectList(req.Id);
    }


    @IsTest
    static void test_updateRequestProject() {
                
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

        String projId = proj.Id;
        RequestApprovalController.updateRequestProject(RequestApprovalController.APPROVED, '', '', projId, String.valueOf(req.Id));
        RequestApprovalController.updateRequestProject(RequestApprovalController.REJECTED, 'Other', 'Not a valid request', projId, String.valueOf(req.Id));
    }

}