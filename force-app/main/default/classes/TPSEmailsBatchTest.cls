@IsTest
public with sharing class TPSEmailsBatchTest {

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
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('External').getRecordTypeId();
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
        acc.Stage__c = 'Pending Response';
        acc.Senior_Leader__c = u.Id;
        acc.Vendor_Amazon_Partner__c = u.Id;        
        update acc;
    
        req.Amazon_Contract_Holder_Vendor__c = acc.Id;
        update req;
    }

    @IsTest
    static void initialEmailTest() {
        Account acc = [SELECT Id, TPS_Status__c FROM Account WHERE Name = 'test2-Name' LIMIT 1];
        TPSEmailsBatch b = new TPSEmailsBatch();
        acc.TPS_Status__c = b.STATUS_PENDING_RESPONSE;
        update acc;
        b.execute(null);
    }

    @IsTest
    static void approvedEmailTest() {
        Account acc = [SELECT Id, TPS_Status__c FROM Account WHERE Name = 'test2-Name' LIMIT 1];
        TPSEmailsBatch b = new TPSEmailsBatch();
        acc.TPS_Status__c = b.STATUS_APPROVED;
        update acc;
        // First reminder email
        b.execute(null);
    }

    @IsTest
    static void notApprovedEmailTest() {
        Account acc = [SELECT Id, TPS_Status__c FROM Account WHERE Name = 'test2-Name' LIMIT 1];
        TPSEmailsBatch b = new TPSEmailsBatch();
        acc.TPS_Status__c = b.STATUS_NOT_APPROVED;
        update acc;
        // First reminder email
        b.execute(null);
    }

}