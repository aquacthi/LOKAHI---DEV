@isTest
private class ResetInactiveAccountBatchTest {
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

    @isTest
    static void testResetInactiveAccountBatch() {
        
        Account acc = new Account();
        acc.Name = 'test2-Name';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Internal').getRecordTypeId();
        insert acc;

        acc.Stage__c = 'Inactive';
        update acc;
        
        Date today = System.today();
        acc.Inactive_Date__c = today.addDays(-5);
        update acc;

        acc = [SELECT Id, Stage__c, Inactive_Date__c, New_Stage_Reset_Date__c FROM ACcount WHERE Id = :acc.Id];
        System.debug('Account before batch run ' + acc);

        Test.startTest();
            ResetInactiveAccountBatch s = new ResetInactiveAccountBatch();
            s.execute(null);            
        Test.stopTest();
        
        acc = [SELECT Id, Stage__c, Inactive_Date__c, New_Stage_Reset_Date__c FROM ACcount WHERE Id = :acc.Id];
        System.debug('Account after batch run' + acc);
    }
}