@isTest
private class BIMNewRequestFormTest {
    @TestSetup
    static void makeData(){
        Autodesk_Setting__c cs = new Autodesk_Setting__c();
        cs.Account_Id__c = 'test_account_id';
        cs.Company_Id__c = 'test_company_id';
        cs.X_User_Id__c = 'test_x_user_id';
        cs.App_Id__c = 'test_app_id';
        cs.App_Secret__c = 'test_app_secret';
        cs.Error_Email_Recipients__c = 'errorEmailRecipient@test.com';
        cs.Valid_Record_Type__c = 'BIM_360_Amazonian, BIM_360_Non_Amazonian';
        insert cs;

        BC_BIM_Project__c siteSpecificProject = new BC_BIM_Project__c();
        siteSpecificProject.Project_Name__c = 'projTest1';
        siteSpecificProject.Facility_Name__c = 'facTest1';
        siteSpecificProject.Project_Type__c = 'Site-Specific';
        insert siteSpecificProject; 

        BC_BIM_Project__c templateProject = new BC_BIM_Project__c();
        templateProject.Project_Name__c = 'projTest2';
        templateProject.Facility_Name__c = 'facTest2';
        templateProject.Project_Type__c = 'Template';
        insert templateProject;
    }

    @isTest
    static void testCreateRequest() {
        BC_Request__c request = new BC_Request__c();
        request.RecordTypeId = Schema.SObjectType.BC_Request__c.getRecordTypeInfosByDeveloperName().get('BIM_360_Amazonian').getRecordTypeId();
        request.Requestor_Email__c = 'testemail@emailtest.com';
        request.Requestor_First_Name__c = 'Test';
        request.Requestor_Last_Name__c = 'Test';
        request.Requestor_Company_Entered__c = 'Amazon';
        request.Recipient_Email__c = 'testemail@emailtest.com';
        request.Recipient_First_Name__c = 'Test';
        request.Recipient_Last_Name__c = 'Test';
        request.Recipient_Company_Entered__c = 'Amazon';
        request.Recipient_Cost_Center__c = '1234';
        request.Project_Name__c = '';
        request.BIM_360_Role__c = '';
        request.Contract_with_Amazon__c = true;
        request.Amazon_Contract_Holder_Entered__c = 'Yes';
        request.APOC_Email__c = '';
        // request.BIM_Project__c = [SELECT Id FROM BC_BIM_Project__c WHERE Project_Type__c ='Template' LIMIT 1].Id;
        request.Contract_Holder_Contact_Email__c = '';
        request.Contract_Holder_Contact_First_Name__c = '';
        request.Contract_Holder_Contact_Last_Name__c = '';
        request.Vendor_Has_NDA__c = true;
        request.Enter_Project_Name__c = true;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        try {
            BIMNewRequestForm.createRequest(request);
        } catch (Exception e) {
            request.Requestor_Email__c = 'testemail@amazon.com';
            request.Recipient_Email__c = 'testemail@amazon.com';
            BIMNewRequestForm.createRequest(request);
            // error
        }
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

        Test.stopTest();
    }

    @isTest
    static void testcreateRequestForMultipleProjects() {
        BC_Request__c request = new BC_Request__c();
        request.RecordTypeId = Schema.SObjectType.BC_Request__c.getRecordTypeInfosByDeveloperName().get('BIM_360_Amazonian').getRecordTypeId();
        request.Requestor_Email__c = 'testemail@emailtest.com';
        request.Requestor_First_Name__c = 'Test';
        request.Requestor_Last_Name__c = 'Test';
        request.Requestor_Company_Entered__c = 'Amazon';
        request.Recipient_Email__c = 'testemail@emailtest.com';
        request.Recipient_First_Name__c = 'Test';
        request.Recipient_Last_Name__c = 'Test';
        request.Recipient_Company_Entered__c = 'Amazon';
        request.Recipient_Cost_Center__c = '1234';
        request.Project_Name__c = '';
        request.BIM_360_Role__c = '';
        request.Contract_with_Amazon__c = true;
        request.Amazon_Contract_Holder_Entered__c = 'Yes';
        request.APOC_Email__c = '';
        // request.BIM_Project__c = [SELECT Id FROM BC_BIM_Project__c WHERE Project_Type__c ='Template' LIMIT 1].Id;
        request.Contract_Holder_Contact_Email__c = '';
        request.Contract_Holder_Contact_First_Name__c = '';
        request.Contract_Holder_Contact_Last_Name__c = '';
        request.Vendor_Has_NDA__c = true;
        request.Enter_Project_Name__c = true;

        List<Map<String, Object>> projects = new List<Map<String, Object>>();
        BC_BIM_Project__c proj = new BC_BIM_Project__c();
        insert proj;

        Map<String, Object> projectValues = new Map<String, Object>();
        projectValues.put('value', proj.Id);
        projects.add(projectValues);

        List<Map<String, Object>> newProjects = new List<Map<String, Object>>();
        Map<String, Object> newProjectValues = new Map<String, Object>();
        newProjectValues.put('value', 'test project');
        newProjects.add(newProjectValues);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        try {
            BIMNewRequestForm.createRequestForMultipleProjects(request, projects, newProjects);
        } catch (Exception e) {
            request.Requestor_Email__c = 'testemail@amazon.com';
            request.Recipient_Email__c = 'testemail@amazon.com';
            BIMNewRequestForm.createRequestForMultipleProjects(request, projects, newProjects);
            // error
        }
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

        Test.stopTest();
    }

    @isTest
    static void testGetBIMProjects() {
        BIMNewRequestForm.getBIMProjects();
    }
    
    @isTest
    static void testGetBIMTemplateProjects() {
        BIMNewRequestForm.getBIMTemplateProjects();
    }

}