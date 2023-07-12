@IsTest
private class BCRequestTriggerHandlerTest {
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

        Profile p = [SELECT Id, name FROM profile WHERE name = 'BC_Partner Community User'];
        
        Account acc = new Account(
            Name = 'test-Name',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Internal').getRecordTypeId()
        );
        
        insert acc;

        Contact con = new Contact(
            AccountId = acc.Id,
            FirstName = 'New', 
            LastName = 'Seniorleader', 
            Email = 'seniorleader@amazon.com'
        );

        insert con;

        User u = new User(
            UserName ='newseniorleader@amazon.com',
            LastName ='Seniorleader',
            Email ='seniorleader@amazon.com', 
            Alias = 'new', 
            TimeZoneSidKey ='America/Los_Angeles',
            LocaleSidKey='en_US', 
            EmailEncodingKey='UTF-8', 
            ContactId = con.Id,
            ProfileId = p.Id, 
            LanguageLocaleKey='en_US'
        );

        insert u;

        Account acc1 = new Account(
            Name = 'test1-Name',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Internal').getRecordTypeId()
        );
        
        insert acc1;

        Contact con1 = new Contact(
            AccountId = acc1.Id,
            FirstName = 'Test', 
            LastName = 'Apoc', 
            Email = 'testapoc@amazon.com'
        );

        insert con1;

        User u1 = new User(
            UserName ='testapoc@amazon.com',
            LastName ='Apoc',
            Email ='testapoc@amazon.com', 
            Alias = 'Test', 
            TimeZoneSidKey ='America/Los_Angeles',
            LocaleSidKey='en_US', 
            EmailEncodingKey='UTF-8', 
            ContactId = con1.Id,
            ProfileId = p.Id, 
            LanguageLocaleKey='en_US'
        );

        insert u1;

        Account acc2 = new Account(
            Name = 'test2-Name',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('External').getRecordTypeId()
        );
        
        insert acc2;

        Contact con2 = new Contact(
            AccountId = acc2.Id,
            FirstName = 'Contract', 
            LastName = 'Holder', 
            Email = 'contactholder@contract.com'
        );

        insert con2;
    }

    @IsTest
    static void testInsertProcessAmazonUser() {
        BC_BIM_Project__c proj = new BC_BIM_Project__c();
        insert proj;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

        BC_Request__c req = new BC_Request__c();
        req.RecordTypeId = Schema.SObjectType.BC_Request__c.getRecordTypeInfosByDeveloperName().get('BIM_360_Amazonian').getRecordTypeId();
        req.Recipient_Email__c = 'test@amazon.com';
        req.Recipient_First_Name__c = 'testrecipient'; 
        req.Recipient_Last_Name__c = 'recipient';
        req.Requestor_Email__c = 'testrequestor@amazon.com';
        req.Requestor_First_Name__c = 'test';
        req.Requestor_Last_Name__c = 'requestor';
        insert req;

        Request_Project__c requestProj = new Request_Project__c();
        requestProj.Request__c = req.Id;
        insert requestProj;

        Test.stopTest();

        req = [SELECT Id, Is_BIM_Project_Blank__c
               FROM BC_Request__c
               WHERE Id = :req.Id];

        System.assert(req.Is_BIM_Project_Blank__c);
        // tc todo - add asserts
    }

    @IsTest
    static void testUpdateProcessBlankProjectAmazonUser() {
        BC_BIM_Project__c proj = new BC_BIM_Project__c(
            Project_Name__c = 'Test Project',
            Facility_Name__c = 'Test Project',
            Active__c = true
        );
        insert proj;

        BC_Request__c req = new BC_Request__c();
        req.RecordTypeId = Schema.SObjectType.BC_Request__c.getRecordTypeInfosByDeveloperName().get('BIM_360_Amazonian').getRecordTypeId();
        req.Recipient_Email__c = 'test@amazon.com';
        req.Recipient_First_Name__c = 'testrecipient'; 
        req.Recipient_Last_Name__c = 'recipient';
        req.Requestor_Email__c = 'testrequestor@amazon.com';
        req.Requestor_First_Name__c = 'test';
        req.Requestor_Last_Name__c = 'requestor';
        insert req;

        Request_Project__c requestProj = new Request_Project__c();
        requestProj.Request__c = req.Id;
        requestProj.Project_Name_Entered__c = 'test project';
        insert requestProj;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

        requestProj.Project_Record_Name__c = proj.Id;
        update requestProj;

        API_Log__c apiLog = new API_Log__c();
        apiLog.BC_Request__c = req.Id;
        apiLog.BIM_360_Project_Role_Info__c = '{"id":"testRoleId","project_id":"projectId","name":"test","services":{"project_administration":{"access_level":"no_access"},"document_management":{"access_level":"user"},"project_management":{"access_level":"user"},"insight":{"access_level":"user"}},"member_group_id":"1234"}';
        apiLog.BIM_360_User_Id__c = 'testUserId';
        apiLog.BIM_360_Company_Id__c = 'testCompanyId';
        apiLog.BIM_360_User_Status__c = 'Pending';

        insert apiLog;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

        req.Is_Redshit_Get_User_Info_Success__c = true;
        update req;      

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

        Test.stopTest();

        
        req = [SELECT Id, Is_BIM_Project_Blank__c, BIM_Project_Corrected__c, Stage__c
               FROM BC_Request__c
               WHERE Id = :req.Id];
    }

    @IsTest
    static void testUpdateProcessProjectAmazonUser() {
        Profile p = [SELECT Id, name FROM profile WHERE name = 'BC_Partner Community User'];
        
        Account acc = new Account(
            Name = 'Internal-Name',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Internal').getRecordTypeId()
        );
        
        insert acc;

        Contact con = new Contact(
            AccountId = acc.Id,
            FirstName = 'New', 
            LastName = 'Senior', 
            Email = 'newsenior@amazon.com'
        );

        insert con;

        User u = new User(
            UserName ='newsenior@amazon.com',
            LastName ='Senior',
            Email ='newsenior@amazon.com', 
            Alias = 'new', 
            TimeZoneSidKey ='America/Los_Angeles',
            LocaleSidKey='en_US', 
            EmailEncodingKey='UTF-8', 
            ContactId = con.Id,
            ProfileId = p.Id, 
            LanguageLocaleKey='en_US'
        );

        insert u;

        BC_BIM_Project__c proj = new BC_BIM_Project__c(
            Project_Name__c = 'Test Project',
            Facility_Name__c = 'Test Project',
            Active__c = true
        );
        insert proj;

        BC_Request__c req = new BC_Request__c();
        req.RecordTypeId = Schema.SObjectType.BC_Request__c.getRecordTypeInfosByDeveloperName().get('BIM_360_Amazonian').getRecordTypeId();
        req.Recipient_Email__c = 'test@amazon.com';
        req.Recipient_First_Name__c = 'testrecipient'; 
        req.Recipient_Last_Name__c = 'recipient';
        req.Requestor_Email__c = 'testrequestor@amazon.com';
        req.Requestor_First_Name__c = 'test';
        req.Requestor_Last_Name__c = 'requestor';
        insert req;

        Request_Project__c requestProj = new Request_Project__c();
        requestProj.Project_Record_Name__c = proj.Id;
        requestProj.Request__c = req.Id;
        insert requestProj;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

        API_Log__c apiLog = new API_Log__c();
        apiLog.BC_Request__c = req.Id;
        apiLog.BIM_360_Project_Role_Info__c = '{"id":"testRoleId","project_id":"projectId","name":"test","services":{"project_administration":{"access_level":"no_access"},"document_management":{"access_level":"user"},"project_management":{"access_level":"user"},"insight":{"access_level":"user"}},"member_group_id":"1234"}';
        apiLog.BIM_360_User_Id__c = 'testUserId';
        apiLog.BIM_360_Company_Id__c = 'testCompanyId';
        apiLog.BIM_360_User_Status__c = 'Pending';

        insert apiLog;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
    
        BCRequestTriggerHandler.isFirstTime = true;

        req.Partner_Amazon_Team__c = acc.Id;
        req.Is_Redshit_Get_User_Info_Success__c = true;  
        req.SL_Email__c = 'newsenior@amazon.com'; 
        req.SL_First_Name__c = 'New';
        req.SL_Last_Name__c = 'Senior'; 
        update req;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

        Test.stopTest();

        
        req = [SELECT Id, Is_BIM_Project_Blank__c, BIM_Project_Corrected__c, Stage__c
               FROM BC_Request__c
               WHERE Id = :req.Id];
    }

    /*    
    @IsTest
    static void testUpdateProcessApprovalNonAmazonUser() {
        Profile p = [SELECT Id, name FROM profile WHERE name = 'BC_Partner Community User'];
        
        Account acc = new Account(
            Name = 'Internal-Name',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Internal').getRecordTypeId()
        );
        
        insert acc;

        Contact con = new Contact(
            AccountId = acc.Id,
            FirstName = 'New', 
            LastName = 'Senior', 
            Email = 'newsenior@amazon.com'
        );

        insert con;

        User u = new User(
            UserName ='newsenior@amazon.com',
            LastName ='Senior',
            Email ='newsenior@amazon.com', 
            Alias = 'new', 
            TimeZoneSidKey ='America/Los_Angeles',
            LocaleSidKey='en_US', 
            EmailEncodingKey='UTF-8', 
            ContactId = con.Id,
            ProfileId = p.Id, 
            LanguageLocaleKey='en_US'
        );

        insert u;

        BC_BIM_Project__c proj = new BC_BIM_Project__c(
            Project_Name__c = 'Test Project',
            Facility_Name__c = 'Test Project',
            Active__c = true
        );
        insert proj;

        BC_Request__c req = new BC_Request__c();
        req.RecordTypeId = Schema.SObjectType.BC_Request__c.getRecordTypeInfosByDeveloperName().get('BIM_360_Non_Amazonian').getRecordTypeId();
        req.Recipient_Email__c = 'testrecipient@nonamazon.com';
        req.Recipient_First_Name__c = 'Recipient'; 
        req.Recipient_Last_Name__c = 'Test';
        req.Recipient_Company_Entered__c = 'nonamazon';
        req.Requestor_Email__c = 'testrequestor@nonamazon.com';
        req.Requestor_First_Name__c = 'Requestor';
        req.Requestor_Last_Name__c = 'Test';
        req.Requestor_Company_Entered__c = 'nonamazon';
        req.Contract_with_Amazon__c = true;
        req.Vendor_Has_NDA__c = true;
        req.APOC_Email__c = 'testapoc@amazon.com';
        req.APOC_First_Name__c = 'Test';
        req.APOC_Last_Name__c = 'Apoc';
        req.Amazon_Contract_Holder_Entered__c = 'Amazon';
        insert req;

        Request_Project__c requestProj = new Request_Project__c();
        requestProj.Project_Record_Name__c = proj.Id;
        requestProj.Request__c = req.Id;
        insert requestProj;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

        API_Log__c apiLog = new API_Log__c();
        apiLog.BC_Request__c = req.Id;
        apiLog.BIM_360_Project_Role_Info__c = '{"id":"testRoleId","project_id":"projectId","name":"test","services":{"project_administration":{"access_level":"no_access"},"document_management":{"access_level":"user"},"project_management":{"access_level":"user"},"insight":{"access_level":"user"}},"member_group_id":"1234"}';
        apiLog.BIM_360_User_Id__c = 'testUserId';
        apiLog.BIM_360_Company_Id__c = 'testCompanyId';
        apiLog.BIM_360_User_Status__c = 'Pending';

        insert apiLog;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

        acc.Related_Request__c = req.Id;
        acc.Senior_Leader__c = u.Id;
        update acc;

        req.Is_Redshit_Get_User_Info_Success__c = true;  
        req.Partner_Amazon_Team__c = acc.Id;
        req.SL_Email__c = 'newsenior@amazon.com'; 
        req.SL_First_Name__c = 'New';
        req.SL_Last_Name__c = 'Senior';          
        req.Stage__c = 'Pending APOC Approval';    
        update req;      

        BCRequestTriggerHandler.isFirstTime = true;

        req.APOC_Approval__c = 'Approved';    
        update req;

        AccountTriggerHandler.g_do_not_run = false;
        
        acc.Stage__c = 'Pending SL Approval';
        update acc;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

        Test.stopTest();

        
        req = [SELECT Id, Is_BIM_Project_Blank__c, BIM_Project_Corrected__c, Stage__c
               FROM BC_Request__c
               WHERE Id = :req.Id];
    }
    */

    @IsTest
    static void testUpdateProcessRejectedNonAmazonUser() {
        BC_BIM_Project__c proj = new BC_BIM_Project__c(
            Project_Name__c = 'Test Project',
            Facility_Name__c = 'Test Project',
            Active__c = true
        );
        insert proj;

        BC_Request__c req = new BC_Request__c();
        req.RecordTypeId = Schema.SObjectType.BC_Request__c.getRecordTypeInfosByDeveloperName().get('BIM_360_Non_Amazonian').getRecordTypeId();
        req.Recipient_Email__c = 'testrecipient@nonamazon.com';
        req.Recipient_First_Name__c = 'Recipient'; 
        req.Recipient_Last_Name__c = 'Test';
        req.Recipient_Company_Entered__c = 'nonamazon';
        req.Requestor_Email__c = 'testrequestor@nonamazon.com';
        req.Requestor_First_Name__c = 'Requestor';
        req.Requestor_Last_Name__c = 'Test';
        req.Requestor_Company_Entered__c = 'nonamazon';
        req.Contract_with_Amazon__c = true;
        req.Vendor_Has_NDA__c = true;
        req.APOC_Email__c = 'testapoc@amazon.com';
        req.APOC_First_Name__c = 'Test';
        req.APOC_Last_Name__c = 'Apoc';
        req.Amazon_Contract_Holder_Entered__c = 'Amazon';
        insert req;

        Request_Project__c requestProj = new Request_Project__c();
        requestProj.Project_Record_Name__c = proj.Id;
        requestProj.Request__c = req.Id;
        insert requestProj;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

        API_Log__c apiLog = new API_Log__c();
        apiLog.BC_Request__c = req.Id;
        apiLog.BIM_360_Project_Role_Info__c = '{"id":"testRoleId","project_id":"projectId","name":"test","services":{"project_administration":{"access_level":"no_access"},"document_management":{"access_level":"user"},"project_management":{"access_level":"user"},"insight":{"access_level":"user"}},"member_group_id":"1234"}';
        apiLog.BIM_360_User_Id__c = 'testUserId';
        apiLog.BIM_360_Company_Id__c = 'testCompanyId';
        apiLog.BIM_360_User_Status__c = 'Pending';

        insert apiLog;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

        req.Is_Redshit_Get_User_Info_Success__c = true;  
        req.SL_Email__c = 'seniorleader@amazon.com'; 
        req.SL_First_Name__c = 'New';
        req.SL_Last_Name__c = 'Seniorleader';      
        update req;      

        BCRequestTriggerHandler.isFirstTime = true;
        
        req.APOC_Approval__c = 'Rejected';  
        req.Stage__c = 'Pending APOC Approval';    
        update req;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

        Test.stopTest();

        
        req = [SELECT Id, Is_BIM_Project_Blank__c, BIM_Project_Corrected__c, Stage__c
               FROM BC_Request__c
               WHERE Id = :req.Id];
    }

    /*
    @IsTest
    static void testUpdateProcessNonAmazonUserContractHolder() {
        BC_BIM_Project__c proj = new BC_BIM_Project__c(
            Project_Name__c = 'Test Project',
            Facility_Name__c = 'Test Project',
            Active__c = true
        );
        insert proj;

        BC_Request__c req = new BC_Request__c();
        req.RecordTypeId = Schema.SObjectType.BC_Request__c.getRecordTypeInfosByDeveloperName().get('BIM_360_Non_Amazonian').getRecordTypeId();
        req.Recipient_Email__c = 'testrecipient@nonamazon.com';
        req.Recipient_First_Name__c = 'Recipient'; 
        req.Recipient_Last_Name__c = 'Test';
        req.Recipient_Company_Entered__c = 'nonamazon';
        req.Requestor_Email__c = 'testrequestor@nonamazon.com';
        req.Requestor_First_Name__c = 'Requestor';
        req.Requestor_Last_Name__c = 'Test';
        req.Requestor_Company_Entered__c = 'nonamazon';
        req.Contract_with_Amazon__c = false;
        req.Contract_Holder_Contact_Email__c = 'testcontract@contract.com';
        req.Contract_Holder_Contact_First_Name__c ='Test';
        req.Contract_Holder_Contact_Last_Name__c = 'Contract';
        req.Vendor_Has_NDA__c = true;
        req.APOC_Email__c = 'testapoc@amazon.com';
        req.APOC_First_Name__c = 'Test';
        req.APOC_Last_Name__c = 'Apoc';
        req.Amazon_Contract_Holder_Entered__c = 'Amazon';  
           
        insert req;

        Request_Project__c requestProj = new Request_Project__c();
        requestProj.Project_Record_Name__c = proj.Id;
        requestProj.Request__c = req.Id;
        insert requestProj;

        API_Log__c apiLog = new API_Log__c();
        apiLog.BC_Request__c = req.Id;
        apiLog.BIM_360_Project_Role_Info__c = '{"id":"testRoleId","project_id":"projectId","name":"test","services":{"project_administration":{"access_level":"no_access"},"document_management":{"access_level":"user"},"project_management":{"access_level":"user"},"insight":{"access_level":"user"}},"member_group_id":"1234"}';
        apiLog.BIM_360_User_Id__c = 'testUserId';
        apiLog.BIM_360_Company_Id__c = 'testCompanyId';
        apiLog.BIM_360_User_Status__c = 'Pending';

        insert apiLog;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

        req.Is_Redshit_Get_User_Info_Success__c = true;  
        req.SL_Email__c = 'seniorleader@amazon.com'; 
        req.SL_First_Name__c = 'New';
        req.SL_Last_Name__c = 'Seniorleader';      
        update req;    

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

        BCRequestTriggerHandler.isFirstTime = true;

        req.Stage__c = 'Resolved - Completed';
        update req;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

        Test.stopTest();

        
        req = [SELECT Id, Is_BIM_Project_Blank__c, BIM_Project_Corrected__c, Stage__c
               FROM BC_Request__c
               WHERE Id = :req.Id];
    }
    */

    @IsTest
    static void testUpdateProcessStageToFulfillRequest() {
        BC_BIM_Project__c proj = new BC_BIM_Project__c(
            Project_Name__c = 'Test Project',
            Facility_Name__c = 'Test Project',
            Active__c = true
        );
        insert proj;

        BC_Request__c req = new BC_Request__c();
        req.RecordTypeId = Schema.SObjectType.BC_Request__c.getRecordTypeInfosByDeveloperName().get('BIM_360_Amazonian').getRecordTypeId();
        req.Recipient_Email__c = 'test@amazon.com';
        req.Recipient_First_Name__c = 'testrecipient'; 
        req.Recipient_Last_Name__c = 'recipient';
        req.Requestor_Email__c = 'testrequestor@amazon.com';
        req.Requestor_First_Name__c = 'test';
        req.Requestor_Last_Name__c = 'requestor';
        insert req;

        Request_Project__c requestProj = new Request_Project__c();
        requestProj.Project_Record_Name__c = proj.Id;
        requestProj.Request__c = req.Id;
        insert requestProj;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

        req.Stage__c = 'Fulfill Request';
        update req;

        Test.stopTest();

        req = [SELECT Id
               FROM BC_Request__c
               WHERE Id = :req.Id];
    }

    @IsTest
    static void testUpdateProcessStageToResolvedCompleted() {
        BC_BIM_Project__c proj = new BC_BIM_Project__c(
            Project_Name__c = 'Test Project',
            Facility_Name__c = 'Test Project',
            Active__c = true
        );
        insert proj;

        BC_Request__c req = new BC_Request__c();
        req.RecordTypeId = Schema.SObjectType.BC_Request__c.getRecordTypeInfosByDeveloperName().get('BIM_360_Non_Amazonian').getRecordTypeId();
        req.Recipient_Email__c = 'testrecipient@nonamazon.com';
        req.Recipient_First_Name__c = 'Recipient'; 
        req.Recipient_Last_Name__c = 'Test';
        req.Recipient_Company_Entered__c = 'nonamazon';
        req.Requestor_Email__c = 'testrequestor@nonamazon.com';
        req.Requestor_First_Name__c = 'Requestor';
        req.Requestor_Last_Name__c = 'Test';
        req.Requestor_Company_Entered__c = 'nonamazon';
        req.Contract_with_Amazon__c = true;
        req.Vendor_Has_NDA__c = true;
        req.APOC_Email__c = 'testapoc@amazon.com';
        req.APOC_First_Name__c = 'Test';
        req.APOC_Last_Name__c = 'Apoc';
        req.Amazon_Contract_Holder_Entered__c = 'Amazon';
        insert req;

        Request_Project__c requestProj = new Request_Project__c();
        requestProj.Project_Record_Name__c = proj.Id;
        requestProj.Request__c = req.Id;
        insert requestProj;

        API_Log__c apiLog = new API_Log__c();
        apiLog.BC_Request__c = req.Id;
        apiLog.BIM_360_Project_Role_Info__c = '{"id":"testRoleId","project_id":"projectId","name":"test","services":{"project_administration":{"access_level":"no_access"},"document_management":{"access_level":"user"},"project_management":{"access_level":"user"},"insight":{"access_level":"user"}},"member_group_id":"1234"}';
        apiLog.BIM_360_User_Id__c = 'testUserId';
        apiLog.BIM_360_Company_Id__c = 'testCompanyId';
        apiLog.BIM_360_User_Status__c = 'Pending';

        insert apiLog;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

        req.Is_Redshit_Get_User_Info_Success__c = true;  
        req.SL_Email__c = 'seniorleader@amazon.com'; 
        req.SL_First_Name__c = 'New';
        req.SL_Last_Name__c = 'Seniorleader';      
        update req;    

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

        BCRequestTriggerHandler.isFirstTime = true;

        req.Stage__c = 'Resolved - Completed';
        update req;

        Test.stopTest();

        req = [SELECT Id
               FROM BC_Request__c
               WHERE Id = :req.Id];
    }


    @IsTest
    static void testUpdateProcessStageToResolvedNotCompleted() {
        BC_BIM_Project__c proj = new BC_BIM_Project__c(
            Project_Name__c = 'Test Project',
            Facility_Name__c = 'Test Project',
            Active__c = true
        );
        insert proj;

        BC_Request__c req = new BC_Request__c();
        req.RecordTypeId = Schema.SObjectType.BC_Request__c.getRecordTypeInfosByDeveloperName().get('BIM_360_Amazonian').getRecordTypeId();
        req.Recipient_Email__c = 'test@amazon.com';
        req.Recipient_First_Name__c = 'testrecipient'; 
        req.Recipient_Last_Name__c = 'recipient';
        req.Requestor_Email__c = 'testrequestor@amazon.com';
        req.Requestor_First_Name__c = 'test';
        req.Requestor_Last_Name__c = 'requestor';
        insert req;

        Request_Project__c requestProj = new Request_Project__c();
        requestProj.Project_Record_Name__c = proj.Id;
        requestProj.Request__c = req.Id;
        insert requestProj;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

        BCRequestTriggerHandler.isFirstTime = true;

        req.Stage__c = 'Resolved - Not Completed';
        req.Reason_Not_Completed__c = 'Not approved';
        update req;

        Test.stopTest();

        req = [SELECT Id
               FROM BC_Request__c
               WHERE Id = :req.Id];
    }

    @IsTest
    static void testUpdateProcessStageToAutodeskError() {
        BC_BIM_Project__c proj = new BC_BIM_Project__c(
            Project_Name__c = 'Test Project',
            Facility_Name__c = 'Test Project',
            Active__c = true
        );
        insert proj;

        BC_Request__c req = new BC_Request__c();
        req.RecordTypeId = Schema.SObjectType.BC_Request__c.getRecordTypeInfosByDeveloperName().get('BIM_360_Amazonian').getRecordTypeId();
        req.Recipient_Email__c = 'test@amazon.com';
        req.Recipient_First_Name__c = 'testrecipient'; 
        req.Recipient_Last_Name__c = 'recipient';
        req.Requestor_Email__c = 'testrequestor@amazon.com';
        req.Requestor_First_Name__c = 'test';
        req.Requestor_Last_Name__c = 'requestor';
        insert req;

        Request_Project__c requestProj = new Request_Project__c();
        requestProj.Project_Record_Name__c = proj.Id;
        requestProj.Request__c = req.Id;
        insert requestProj;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200)); 

        req.Stage__c = 'Autodesk Error'; 
        update req;        

        Test.stopTest();

        req = [SELECT Id
               FROM BC_Request__c
               WHERE Id = :req.Id];
    }

    // @IsTest
    // static void testInsertProcessSendEmail() {
    //     Test.startTest();
    //     Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        
    //     BC_Request__c req = new BC_Request__c();
    //     req.New_Request__c = true;
    //     req.Recipient_Email__c = 'testrecipient@amazon.com';
    //     req.Recipient_First_Name__c = 'recipient'; 
    //     req.Recipient_Last_Name__c = 'test';
    //     req.Requestor_Email__c = 'testrequestor@amazon.com';
    //     req.Requestor_First_Name__c = 'requestor';
    //     req.Requestor_Last_Name__c = 'test';
    //     req.Ready_Resolved_Not_Completed__c = true;
    //     insert req;

    //     Test.stopTest();

    //     req = [SELECT Id
    //            FROM BC_Request__c
    //            WHERE Id = :req.Id];

        // tc todo - add asserts
    // }
}