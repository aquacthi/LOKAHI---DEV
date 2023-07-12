@isTest
public class TokenFlexDashboardControllerTest {
    @isTest
    static void testGetTokenFlexUsage() {
        Token_Flex_Usage__c tokenFlexUsage = new Token_Flex_Usage__c(
            Cost_Center__c = '1057',
            Email__c = 'test@test.com',
            Product_Name__c = 'testProduct',
            Usage_Date__c = system.today(),
            Approver_Name__c = 'test',
            Business_Unit__c = ''
        );

        insert tokenFlexUsage;

        Test.startTest();

        List<String> usageDates = new List<String>();
        List<String> costCenters = new List<String>(); 
        List<String> approverNames = new List<String>();
        List<String> emails = new List<String>();
        List<String> businessUnits = new List<String>();
        List<String> productNames = new List<String>();

        for (Token_Flex_Usage__c tf : [SELECT Cost_Center__c,
                                              Usage_Billing_Period__c,
                                              Usage_Date__c,
                                              Approver_Name__c,
                                              Email_Alias__c,
                                              Business_Unit__c,
                                              Product_Name__c
                                       FROM Token_Flex_Usage__c]) {
            usageDates.add(tf.Usage_Billing_Period__c);
            costCenters.add(tf.Cost_Center__c);  
            approverNames.add(tf.Approver_Name__c); 
            emails.add(tf.Email_Alias__c); 
            businessUnits.add(tf.Business_Unit__c); 
            productNames.add(tf.Product_Name__c); 

        }  

        TokenFlexDashboardController.getTokenFlexUsage(usageDates, costCenters, approverNames, emails, businessUnits, productNames);

        Test.stopTest();

    }

    @isTest
    static void testGetTokenFlexUsageOption() {
        Token_Flex_Usage__c tokenFlexUsage = new Token_Flex_Usage__c(
            Cost_Center__c = '1057',
            Email__c = 'test@test.com',
            Product_Name__c = 'testProduct',
            Usage_Date__c = system.today(),
            Approver_Name__c = 'test',
            Business_Unit__c = ''
        );

        insert tokenFlexUsage;

        Test.startTest();

        TokenFlexDashboardController.getTokenFlexUsageOption();

        Test.stopTest();

    }

    @isTest
    static void testGetTokensConsumedByProduct() {
        Token_Flex_Usage__c tokenFlexUsage = new Token_Flex_Usage__c(
            Cost_Center__c = '1057',
            Email__c = 'test@test.com',
            Product_Name__c = 'testProduct',
            Usage_Date__c = system.today(),
            Tokens_Consumed__c = 0
        );

        insert tokenFlexUsage;

        Test.startTest();

        TokenFlexDashboardController.getTokensConsumedByProduct();

        Test.stopTest();

    }

    @isTest
    static void testGetTokensConsumedByCompany() {
        Token_Flex_Usage__c tokenFlexUsage = new Token_Flex_Usage__c(
            Cost_Center__c = '1057',
            Email__c = 'test@test.com',
            Product_Name__c = 'testProduct',
            Usage_Date__c = system.today(),
            Tokens_Consumed__c = 0
        );

        insert tokenFlexUsage;

        Test.startTest();

        TokenFlexDashboardController.getTokensConsumedByCompany();

        Test.stopTest();

    }

    @isTest
    static void testGetTokensConsumedByPeriod() {
        Token_Flex_Usage__c tokenFlexUsage = new Token_Flex_Usage__c(
            Cost_Center__c = '1057',
            Email__c = 'test@test.com',
            Product_Name__c = 'testProduct',
            Usage_Date__c = system.today(),
            Tokens_Consumed__c = 0
        );

        insert tokenFlexUsage;

        Test.startTest();

        TokenFlexDashboardController.getTokensConsumedByPeriod('2021-10');

        Test.stopTest();

    }

    @isTest
    static void testGetCSVHeaderNames() {

        Test.startTest();

        TokenFlexDashboardController.getCSVHeaderNames();

        Test.stopTest();

    }
}