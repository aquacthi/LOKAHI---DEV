@IsTest
private class AccountTriggerHandlerTest {
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

    // @IsTest
    // static void testInsert() {
    //     Test.startTest();
    //     Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
    //     Account acc = new Account();
    //     acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Internal').getRecordTypeId();
    //     acc.Name = 'test-Name';
    //     acc.FM_Email__c = 'test@test.com';
    //     acc.Stage__c = 'Enter Finance Manager';
    //     insert acc;
    //     Test.stopTest();

    //     acc = [SELECT FM_First_Name__c,
    //                   FM_Last_Name__c,
    //                   FM_Email__c,
    //                   FM_Cost_Center__c
    //            FROM Account
    //            WHERE Id = :acc.Id];

    //     // System.assertEquals('Test', acc.FM_First_Name__c);
    //     // System.assertEquals('User', acc.FM_Last_Name__c);
    //     // System.assertEquals('user@test.com', acc.FM_Email__c);
    //     // System.assertEquals('1234', acc.FM_Cost_Center__c);
    // }



    @IsTest
    static void testStageSLRejected() {

        BC_Request__c req1 = new BC_Request__c();
        req1.Recipient_Email__c = 'test@amazon.com';
        req1.Recipient_First_Name__c = 'testrecipient'; 
        req1.Recipient_Last_Name__c = 'recipient';
        req1.Requestor_Email__c = 'testrequestor@amazon.com';
        req1.Requestor_First_Name__c = 'test';
        req1.Requestor_Last_Name__c = 'requestor';
        req1.Status__c = 'Open';
        req1.Stage__c = 'New';
        insert req1;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        API_Log__c source = new API_Log__c();
        source.BC_Request__c = req1.Id;
        source.BIM_360_Project_Role_Info__c = '{"id":"testRoleId","project_id":"projectId","name":"test","services":{"project_administration":{"access_level":"no_access"},"document_management":{"access_level":"user"},"project_management":{"access_level":"user"},"insight":{"access_level":"user"}},"member_group_id":"1234"}';
        source.BIM_360_User_Id__c = 'testUserId';
        source.BIM_360_Company_Id__c = 'testCompanyId';
        source.BIM_360_User_Status__c = 'Pending';

        API_Log__c apiLog = ApiLogTriggerHandler.createGetCompanyNameSearchApiLog(source);
        insert apiLog;


        Profile p = [SELECT Id, name FROM profile WHERE name = 'BC_Partner Community User'];

        Account acc = new Account();
        acc.Name = 'test2-Name';
        acc.Related_Request__c = req1.Id;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Internal').getRecordTypeId();
        insert acc;

        System.debug('acc insert');
        System.debug(acc);

        Contact con = new Contact(AccountId = acc.Id, 
                                FirstName = 'test', 
                                LastName = 'Testing', 
                                Email = 'test@amazon.com', 
                                Related_Request__c = req1.Id);
        insert con;

        User u = new User(Alias = 'newUser', Email='test@amazon.com', Cost_Center__c = '4080',
        EmailEncodingKey='UTF-8', FirstName = 'test', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id, ContactId = con.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='newuser@amazon.com');

        insert u;

        AccountTriggerHandler.g_do_not_run = false;
        req1.Partner_Amazon_Team__c = acc.Id;
        req1.Stage__c = 'Pending Approval';
        update req1;

 //    Test.startTest();

       AccountTriggerHandler.g_do_not_run = false;
       acc.Stage__c = 'Pending SL Approval';
       acc.Senior_Leader__c = u.Id;
       update acc;

        AccountTriggerHandler.g_do_not_run = false;
        acc.Approval_Response__c = 'Rejected';
        update acc;

        acc = [SELECT Id, Stage__c,
            Add_Account_Group_Members__c,
            Senior_Leader__c,
            Related_Request__c,
            Approval_Response__c,
            LastModifiedDate
        FROM Account
        WHERE Id = :acc.Id];

        System.assertEquals('Rejected', acc.Approval_Response__c);
        System.assertEquals('Inactive', acc.Stage__c);

        req1 = [SELECT Id, Stage__c, Status__c, Partner_Amazon_Team__c, IsDeleted 
                FROM BC_Request__c 
                WHERE Partner_Amazon_Team__c = :acc.Id];

        System.assertEquals('Resolved - Not Completed', req1.Stage__c);
        System.assertEquals('Closed', req1.Status__c);

      //  Test.stopTest();
    }

    @IsTest
    static void testStageSLApprove() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        BC_Request__c req2 = new BC_Request__c();
        req2.Recipient_Email__c = 'test@amazon.com';
        req2.Recipient_First_Name__c = 'testrecipient'; 
        req2.Recipient_Last_Name__c = 'recipient';
        req2.Requestor_Email__c = 'testrequestor@amazon.com';
        req2.Requestor_First_Name__c = 'test';
        req2.Requestor_Last_Name__c = 'requestor';
        req2.Status__c = 'Open';
        req2.Stage__c = 'New';
        insert req2;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        API_Log__c source = new API_Log__c();
        source.BC_Request__c = req2.Id;
        source.BIM_360_Project_Role_Info__c = '{"id":"testRoleId","project_id":"projectId","name":"test","services":{"project_administration":{"access_level":"no_access"},"document_management":{"access_level":"user"},"project_management":{"access_level":"user"},"insight":{"access_level":"user"}},"member_group_id":"1234"}';
        source.BIM_360_User_Id__c = 'testUserId';
        source.BIM_360_Company_Id__c = 'testCompanyId';
        source.BIM_360_User_Status__c = 'Pending';

        API_Log__c apiLog = ApiLogTriggerHandler.createGetCompanyNameSearchApiLog(source);
        insert apiLog;


        Profile p = [SELECT Id, name FROM profile WHERE name = 'BC_Partner Community User'];

        Account acc = new Account();
        acc.Name = 'test2-Name';
        acc.Related_Request__c = req2.Id;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Internal').getRecordTypeId();
        insert acc;

        Contact con = new Contact(AccountId = acc.Id, 
                                FirstName = 'test', 
                                LastName = 'Testing', 
                                Email = 'test@amazon.com', 
                                Related_Request__c = req2.Id);
        insert con;

        User u = new User(Alias = 'newUser', Email='test@amazon.com', Cost_Center__c = '4080',
        EmailEncodingKey='UTF-8', FirstName = 'test', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id, ContactId = con.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='newuser@amazon.com');

        insert u;

        req2.Partner_Amazon_Team__c = acc.Id;
        req2.Stage__c = 'Pending Approval';
        update req2;

        req2 = [SELECT Id, Stage__c, Status__c, Partner_Amazon_Team__c, IsDeleted 
                FROM BC_Request__c 
                WHERE Partner_Amazon_Team__c = :acc.Id];

        AccountTriggerHandler.g_do_not_run = false;
        acc.Stage__c = 'Pending SL Approval';
        acc.Senior_Leader__c = u.Id;
        update acc;

   // Test.startTest();
        AccountTriggerHandler.g_do_not_run = false;
        acc.FM_Email__c = 'test123@amazon.com';
        acc.Approval_Response__c = 'Approved';
        update acc;

        acc = [SELECT Id, FM_First_Name__c,
                FM_Last_Name__c,
                LastModifiedDate,
                FM_Email__c,
                FM_Cost_Center__c,
                Finance_Manager_Information_Entered__c,
                Billing_Codes_Entered__c,
                Add_Account_Group_Members__c,
                Billing_Code_Locked__c,
                Stage__c,
                Finance_Manager__c,
                Finance_Manager_Approval_Attempts__c,
                Last_FM_Approval_Sent__c,
                Related_Request__c,
                Company_Code__c,
                Location_Code__c,
                Cost_Center__c,
                Record_Type_ID_18__c,
                RecordTypeId,
                Senior_Leader__c,
                Group_ID_18__c,
                FM_Email_Alias__c,
                FM_Alias_Domain__c,
                FM_Alias_Domain_2__c
                FROM Account
                WHERE Id = :acc.Id];

            AccountTriggerHandler.g_do_not_run = false;
            acc.FM_First_Name__c = 'Hee';
            acc.FM_Last_Name__c = 'Yoon';
            acc.FM_Cost_Center__c = '8676';
            update acc;

        acc = [SELECT Id, FM_First_Name__c,
                    FM_Last_Name__c,
                    LastModifiedDate,
                    FM_Email__c,
                    FM_Cost_Center__c,
                    Finance_Manager_Information_Entered__c,
                    Billing_Codes_Entered__c,
                    Add_Account_Group_Members__c,
                    Billing_Code_Locked__c,
                    Stage__c,
                    Finance_Manager__c,
                    Finance_Manager_Approval_Attempts__c,
                    Last_FM_Approval_Sent__c,
                    Related_Request__c,
                    Company_Code__c,
                    Location_Code__c,
                    Cost_Center__c,
                    Record_Type_ID_18__c,
                    RecordTypeId,
                    Senior_Leader__c,
                    Group_ID_18__c,
                    FM_Email_Alias__c,
                    FM_Alias_Domain__c,
                    FM_Alias_Domain_2__c
                FROM Account
                WHERE Id = :acc.Id];
        
        AccountTriggerHandler.g_do_not_run = false;
        acc.Company_Code__c = '2D';
        acc.Location_Code__c = '2321';
        acc.Cost_Center__c = '3421';
        update acc;

        acc = [SELECT Id, FM_First_Name__c,
                    LastModifiedDate,
                    FM_Last_Name__c,
                    FM_Email__c,
                    FM_Cost_Center__c,
                    Finance_Manager_Information_Entered__c,
                    Billing_Codes_Entered__c,
                    Add_Account_Group_Members__c,
                    Billing_Code_Locked__c,
                    Stage__c,
                    Finance_Manager__c,
                    Finance_Manager_Approval_Attempts__c,
                    Last_FM_Approval_Sent__c,
                    Related_Request__c,
                    Company_Code__c,
                    Location_Code__c,
                    Cost_Center__c,
                    Record_Type_ID_18__c,
                    RecordTypeId,
                    Senior_Leader__c,
                    Group_ID_18__c,
                    FM_Email_Alias__c,
                    FM_Alias_Domain__c,
                    FM_Alias_Domain_2__c
                FROM Account
                WHERE Id = :acc.Id];

        if (acc.Stage__c == 'Active') {
            req2 = [SELECT Id, Stage__c, Status__c, Partner_Amazon_Team__c, IsDeleted 
                    FROM BC_Request__c 
                    WHERE Partner_Amazon_Team__c = :acc.Id];

            System.assertEquals('Fulfill Request', req2.Stage__c); 
        }

 //   Test.stopTest();
    }
}