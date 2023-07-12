@isTest
public with sharing class UserCostCenterMappingTriggerHandlerTest {
    @isTest
    static void testInsertUserCostCenterMapping() {
        Profile p = [SELECT Id, name FROM profile WHERE name = 'BC_Partner Community User'];
        
        Account acc = new Account(
            Name = 'test2-Name',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Internal').getRecordTypeId()
        );
        
        insert acc;

        Contact con = new Contact(
            AccountId = acc.Id,
            FirstName = 'test', 
            LastName = 'Testing', 
            Email = 'test@amazon.com'
        );

        insert con;

        User u = new User(
            UserName ='newuser@amazon.com',
            LastName='Testing',
            Email='test@amazon.com', 
            Alias = 'newUser', 
            TimeZoneSidKey ='America/Los_Angeles',
            LocaleSidKey='en_US', 
            EmailEncodingKey='UTF-8', 
            ContactId = con.Id,
            ProfileId = p.Id, 
            LanguageLocaleKey='en_US'
        );

        insert u;

        Test.startTest();

        User_Cost_Center_Mapping__c userCostCenter = new User_Cost_Center_Mapping__c(
            Cost_Center__c = '0000',
            User__c = u.Id
        );

        insert userCostCenter;

        Test.stopTest();

        String developerName = 'Cost_Center_' + userCostCenter.Cost_Center__c;

        List<Group> groupList = [SELECT Id, Name, DeveloperName, RelatedId, Type, Email, OwnerId, DoesSendEmailToMembers, DoesIncludeBosses, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp
                                 FROM Group
                                 WHERE Type = 'Regular'
                                 AND DeveloperName = :developerName];
        
        System.assertEquals(1, groupList.size());

        GroupMember gm = [SELECT Id, GroupId, UserOrGroupId, SystemModstamp
                          FROM GroupMember
                          WHERE GroupId = :groupList[0].Id
                          AND UserOrGroupId = :u.Id];

        System.assertEquals(gm.UserOrGroupId, userCostCenter.User__c);
    }

    @isTest
    static void testUpdateUserCostCenterMapping() {
        Profile p = [SELECT Id, name FROM profile WHERE name = 'BC_Partner Community User'];
        
        Account acc = new Account(
            Name = 'test2-Name',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Internal').getRecordTypeId()
        );
        
        insert acc;

        Contact con = new Contact(
            AccountId = acc.Id,
            FirstName = 'test', 
            LastName = 'Testing', 
            Email = 'test@amazon.com'
        );

        insert con;

        User u = new User(
            UserName ='newuser@amazon.com',
            LastName='Testing',
            Email='test@amazon.com', 
            Alias = 'newUser', 
            TimeZoneSidKey ='America/Los_Angeles',
            LocaleSidKey='en_US', 
            EmailEncodingKey='UTF-8', 
            ContactId = con.Id,
            ProfileId = p.Id, 
            LanguageLocaleKey='en_US'
        );

        insert u;
                  
        User_Cost_Center_Mapping__c userCostCenter = new User_Cost_Center_Mapping__c(
            Cost_Center__c = '0000',
            User__c = u.Id
        );

        insert userCostCenter;

        Test.startTest();

        userCostCenter.Cost_Center__c = '0001';
        update userCostCenter;

        Test.stopTest();

        String developerName = 'Cost_Center_' + userCostCenter.Cost_Center__c;

        List<Group> groupList = [SELECT Id, Name, DeveloperName, RelatedId, Type, Email, OwnerId, DoesSendEmailToMembers, DoesIncludeBosses, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp
                                 FROM Group
                                 WHERE Type = 'Regular'
                                 AND DeveloperName = :developerName];
        
        System.assertEquals(1, groupList.size());

        GroupMember gm = [SELECT Id, GroupId, UserOrGroupId, SystemModstamp
                          FROM GroupMember
                          WHERE GroupId = :groupList[0].Id
                          AND UserOrGroupId = :u.Id];

        System.assertEquals(gm.UserOrGroupId, userCostCenter.User__c);
    }

    @isTest
    static void testDeleteUserCostCenterMapping() {
        Profile p = [SELECT Id, name FROM profile WHERE name = 'BC_Partner Community User'];
        
        Account acc = new Account(
            Name = 'test2-Name',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Internal').getRecordTypeId()
        );
        
        insert acc;

        Contact con = new Contact(
            AccountId = acc.Id,
            FirstName = 'test', 
            LastName = 'Testing', 
            Email = 'test@amazon.com'
        );

        insert con;

        User u = new User(
            UserName ='newuser@amazon.com',
            LastName='Testing',
            Email='test@amazon.com', 
            Alias = 'newUser', 
            TimeZoneSidKey ='America/Los_Angeles',
            LocaleSidKey='en_US', 
            EmailEncodingKey='UTF-8', 
            ContactId = con.Id,
            ProfileId = p.Id, 
            LanguageLocaleKey='en_US'
        );

        insert u;
                  
        User_Cost_Center_Mapping__c userCostCenter = new User_Cost_Center_Mapping__c(
            Cost_Center__c = '0000',
            User__c = u.Id
        );

        insert userCostCenter;

        Test.startTest();

        User_Cost_Center_Mapping__c userCostCenterId = new User_Cost_Center_Mapping__c();
        userCostCenterId.Id = userCostCenter.Id;
        delete userCostCenterId;

        Test.stopTest();

        String developerName = 'Cost_Center_' + userCostCenter.Cost_Center__c;

        List<Group> groupList = [SELECT Id, Name, DeveloperName, RelatedId, Type, Email, OwnerId, DoesSendEmailToMembers, DoesIncludeBosses, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp
                                 FROM Group
                                 WHERE Type = 'Regular'
                                 AND DeveloperName = :developerName];
        
        System.assertEquals(1, groupList.size());

        List<GroupMember> groupMemeberList = [SELECT Id, GroupId, UserOrGroupId, SystemModstamp
                                              FROM GroupMember
                                              WHERE GroupId = :groupList[0].Id
                                              AND UserOrGroupId = :u.Id];

        System.assert(groupMemeberList.isEmpty());
    }
}