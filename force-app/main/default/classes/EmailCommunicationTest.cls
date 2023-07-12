@IsTest
public with sharing class EmailCommunicationTest {

    @TestSetup
    static void makeData(){
        Autodesk_Setting__c cs = new Autodesk_Setting__c();
        cs.Account_Id__c        = 'test_account_id';
        cs.Company_Id__c        = 'test_company_id';
        cs.X_User_Id__c         = 'test_x_user_id';
        cs.App_Id__c            = 'test_app_id';
        cs.App_Secret__c        = 'test_app_secret';
        cs.Valid_Record_Type__c = 'BIM_360_Amazonian, BIM_360_Non_Amazonian';
        cs.Error_Email_Recipients__c = 'errorEmailRecipient@test.com';
        insert cs;
    }

    @IsTest
    static void BCRequestEmailCommunicationTest() {
        BC_BIM_Project__c proj = new BC_BIM_Project__c();
        insert proj;

        BC_Request__c req = new BC_Request__c();
        req.RecordTypeId = Schema.SObjectType.BC_Request__c.getRecordTypeInfosByDeveloperName().get('BIM_360_Amazonian').getRecordTypeId();
        req.Recipient_Email__c = 'recipient@amazon.com';
        req.Recipient_First_Name__c = 'recipient'; 
        req.Recipient_Last_Name__c = 'test';
        req.Requestor_Email__c = 'requestor@amazon.com';
        req.Requestor_First_Name__c = 'requestor';
        req.Requestor_Last_Name__c = 'test';    
        req.BIM_Project__c = proj.Id;    
        req.APOC_Email__c = 'apoc@test.com';
        insert req;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

        EmailCommunication.getEmailMessageList(req, 'New Request confirmation');
        EmailCommunication.getEmailMessageList(req, 'Request Not Completed notification');
        EmailCommunication.getEmailMessageList(req, 'Pending Team Approval notification');
        EmailCommunication.getEmailMessageList(req, 'Completed request notification');
        EmailCommunication.getEmailMessageList(req, 'Action needed');
        EmailCommunication.getEmailMessageList(req, 'APOC approval needed');
        EmailCommunication.getEmailMessageList(req, 'Fulfillment ready');
        
    }

    @IsTest
    static void TokenFlexEmailCommunicationTest() {
        BC_BIM_Project__c proj = new BC_BIM_Project__c();
        insert proj;
       
        BC_Request__c req = new BC_Request__c();
        req.RecordTypeId = Schema.SObjectType.BC_Request__c.getRecordTypeInfosByDeveloperName().get('Token_Flex_License').getRecordTypeId();
        req.Recipient_Email__c = 'recipient@amazon.com';
        req.Recipient_First_Name__c = 'recipient'; 
        req.Recipient_Last_Name__c = 'test';
        req.Requestor_Email__c = 'requestor@amazon.com';
        req.Requestor_First_Name__c = 'requestor';
        req.Requestor_Last_Name__c = 'test';    
        req.BIM_Project__c = proj.Id;    
        req.APOC_Email__c = 'apoc@test.com';
        System.debug('## req : ' + req);
        System.debug('## req : ' + req.RecordType.Name);
        insert req;

        Account acc = new Account();
        acc.Name = 'test2-Name';
        acc.Related_Request__c = req.Id;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Internal').getRecordTypeId();
        insert acc;

        req.Partner_Amazon_Team__c = acc.Id;
        req.Stage__c = 'Resolved - Completed';
        update req;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
    }

    @IsTest
    static void NonAmazonianEmailCommunicationTest() {
        BC_BIM_Project__c proj = new BC_BIM_Project__c();
        insert proj;
       
        BC_Request__c req = new BC_Request__c();
        req.RecordTypeId = Schema.SObjectType.BC_Request__c.getRecordTypeInfosByDeveloperName().get('BIM_360_Non_Amazonian').getRecordTypeId();
        req.Recipient_Email__c = 'recipient@nonamazon.com';
        req.Recipient_First_Name__c = 'recipient'; 
        req.Recipient_Last_Name__c = 'test';
        req.Recipient_Company_Entered__c = 'nonamazon';
        req.Requestor_Email__c = 'requestor@nonamazon.com';
        req.Requestor_First_Name__c = 'requestor';
        req.Requestor_Last_Name__c = 'test';
        req.Requestor_Company_Entered__c = 'nonamazon';
        req.Contract_with_Amazon__c = true;
        req.Vendor_Has_NDA__c = true;
        req.APOC_Email__c = 'apoc@amazon.com';
        req.APOC_First_Name__c = 'apoc';
        req.APOC_Last_Name__c = 'test';
        req.Amazon_Contract_Holder_Entered__c = 'amazon';   
        req.BIM_Project__c = proj.Id;    
        insert req;
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        
        req.Reason_Not_Completed__c = 'No response';
        req.Stage__c = 'Resolved - Not Completed';
        update req;

        req.Reason_Not_Completed__c = 'Amazon POC not found';
        update req;
    }

    @IsTest
    static void AccountEmailCommunicationTest() {
        
        BC_BIM_Project__c proj = new BC_BIM_Project__c();
        insert proj;
       
        BC_Request__c req = new BC_Request__c();
        req.RecordTypeId = Schema.SObjectType.BC_Request__c.getRecordTypeInfosByDeveloperName().get('BIM_360_Non_Amazonian').getRecordTypeId();
        req.Recipient_Email__c = 'recipient@nonamazon.com';
        req.Recipient_First_Name__c = 'recipient'; 
        req.Recipient_Last_Name__c = 'test';
        req.Recipient_Company_Entered__c = 'nonamazon';
        req.Requestor_Email__c = 'requestor@nonamazon.com';
        req.Requestor_First_Name__c = 'requestor';
        req.Requestor_Last_Name__c = 'test';
        req.Requestor_Company_Entered__c = 'nonamazon';
        req.Contract_with_Amazon__c = true;
        req.Vendor_Has_NDA__c = true;
        req.APOC_Email__c = 'apoc@amazon.com';
        req.APOC_First_Name__c = 'apoc';
        req.APOC_Last_Name__c = 'test';
        req.Amazon_Contract_Holder_Entered__c = 'amazon';   
        req.BIM_Project__c = proj.Id;    
        insert req;
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

        Profile p = [SELECT Id, name FROM profile WHERE name = 'BC_Partner Community User'];

        Account acc = new Account();
        acc.Name = 'test2-Name';
        acc.Related_Request__c = req.Id;
        acc.FM_Email__c = 'testfmemail@email.com';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Internal').getRecordTypeId();
        insert acc;

        System.debug('acc insert');
        System.debug(acc);

        Contact con = new Contact(AccountId = acc.Id, 
                                FirstName = 'test', 
                                LastName = 'Testing', 
                                Email = 'test@amazon.com', 
                                Related_Request__c = req.Id);
        insert con;


        User u = new User(Alias = 'newUser', Email='test@amazon.com', Cost_Center__c = '4080',
        EmailEncodingKey='UTF-8', FirstName = 'test', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id, ContactId = con.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='newuser@amazon.com');

        insert u;
        AccountTriggerHandler.g_do_not_run = false;
        acc.Stage__c = 'Pending SL Approval';
        acc.Senior_Leader__c = u.Id;
        acc.Vendor_Amazon_Partner__c = u.Id;
        update acc;
        
        Account updatedAcc = [SELECT Id, Name, RecordTypeId, Senior_Leader_Email__c, FM_Email__c, Vendor_Amazon_Partner_Email__c FROM Account WHERE Id =: acc.Id];

        EmailCommunication.getEmailMessageList(updatedAcc, 'Senior Leader approval');
        EmailCommunication.getEmailMessageList(updatedAcc, 'Finance Manager response request');
        EmailCommunication.getEmailMessageList(updatedAcc, 'Send TPS notification');
        EmailCommunication.getEmailMessageList(updatedAcc, 'Send NDA notification');
    }
}