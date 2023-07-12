@isTest
public with sharing class TokenFlexUsageTriggerHandlerTest {
    @isTest
    static void testInsertTokenFlexUsage() {
        Test.startTest();

        Token_Flex_Usage__c tokenFlexUsage = new Token_Flex_Usage__c(
            Cost_Center__c = '1057'
        );

        insert tokenFlexUsage;

        Test.stopTest();

        List<Token_Flex_Usage__Share> shareList = [SELECT Id, UserOrGroupId 
                                                    FROM Token_Flex_Usage__Share
                                                    WHERE RowCause = 'Manual'];
        
        System.assertEquals(1, shareList.size());

        Group g = [SELECT Id, DeveloperName 
                    FROM Group
                    WHERE Id = :shareList[0].UserOrGroupId];

        System.assert(g.DeveloperName.contains('1057'));
    }

    @isTest
    static void testUpdateTokenFlexUsage() {
        Token_Flex_Usage__c tokenFlexUsage = new Token_Flex_Usage__c(
            Cost_Center__c = '1057'
        );

        insert tokenFlexUsage;

        Test.startTest();

        tokenFlexUsage.Cost_Center__c = '7793';
        update tokenFlexUsage;

        Test.stopTest();

        List<Token_Flex_Usage__Share> shareList = [SELECT Id, UserOrGroupId
                                                    FROM Token_Flex_Usage__Share
                                                    WHERE RowCause = 'Manual'];                                                     
        
        System.assertEquals(1, shareList.size());

        Group g = [SELECT Id, DeveloperName 
                    FROM Group
                    WHERE Id = :shareList[0].UserOrGroupId];

        System.assert(g.DeveloperName.contains('7793'));
    }
}