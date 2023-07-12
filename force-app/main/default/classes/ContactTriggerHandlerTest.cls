@IsTest

public with sharing class ContactTriggerHandlerTest {
    @isTest
    static void testupdateContactOwnerId() {
        Contact cc = new Contact();
        cc.LastName = 'test';
        cc.Email = 'test@amazon.com';
        Id bimCentalUserId = [SELECT Id FROM User WHERE Name = 'BIMCentral Admin'].Id;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        insert cc;

        cc.Ownerid = bimCentalUserId;
        update cc;
        System.assertEquals('0055Y00000HM72FQAT', cc.Ownerid);
    }

    @isTest
    static void testupdateEmailAliasDomain() {
        Contact cc = new Contact();
        cc.LastName = 'test';
        cc.Email = 'test@amazon.com';

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        insert cc;

        cc.Email_Alias__c       = UtilityClass.getEmailAliasDomain(cc.Email, 'alias');
        cc.Email_Alias_2__c     = UtilityClass.getEmailAliasDomain(cc.Email, 'alias2');
        cc.Email_Domain__c      = UtilityClass.getEmailAliasDomain(cc.Email, 'emailDomain');
        cc.Email_Domain_2__c    = UtilityClass.getEmailAliasDomain(cc.Email, 'emailDomain2');
        cc.Alias_Domain__c      = UtilityClass.getEmailAliasDomain(cc.Email, 'aliasDomain');
        cc.Alias_Domain_2__c    = UtilityClass.getEmailAliasDomain(cc.Email, 'aliasDomain2');
        update cc;

        System.debug(cc);
        System.debug(cc.Email);
        System.debug(cc.Email_Domain__c);
        System.debug(cc.Alias_Domain__c);
        System.assertEquals('test', cc.Email_Alias__c);
        System.assertEquals('te', cc.Email_Alias_2__c);
        System.assertEquals('@amazon.', cc.Email_Domain__c);
        System.assertEquals('@am', cc.Email_Domain_2__c);
        System.assertEquals('test;@amazon.', cc.Alias_Domain__c);
        System.assertEquals('te;@am', cc.Alias_Domain_2__c);
    }
}