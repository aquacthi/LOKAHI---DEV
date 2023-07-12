public with sharing class TokenFlexUsageTableController {
    public TokenFlexUsageTableController() {

    }

    @AuraEnabled(cacheable=true)
    public static List<String> getUsagePeriods() {
        return new List<String>(getData('Usage_Date__c', 'DESC'));
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getApprovers() {
        return new List<String>(getData('Approver_Name__c', 'ASC'));
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getUsers() {
        return new List<String>(getData('Email__c', 'ASC'));
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getBusinessUnits() {
        return new List<String>(getData('Business_Unit__c', 'ASC'));
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getProductNames() {
        return new List<String>(getData('Product_Name__c', 'ASC'));
    }

    public static Set<String> getData(String fieldToGroupBy, String order) {
        Set<String> result = new Set<String>();
        List<String> costCentersList = [SELECT Cost_Center_Access__c FROM User WHERE Id = :UserInfo.getUserID()].Cost_Center_Access__c.split(',');

        String queryString = ' SELECT ' + fieldToGroupBy + 
                             ' FROM Token_Flex_Usage__c ' + 
                             ' WHERE Cost_Center__c IN :costCentersList ' + 
                             ' GROUP BY ' + fieldToGroupBy +
                             ' ORDER BY ' + fieldToGroupBy + ' ' + order;

        for (AggregateResult tf : Database.query(queryString)) {
            String value = String.valueOf(tf.get(fieldToGroupBy));
            if (fieldToGroupBy == 'Usage_Date__c') {
                value = value.substring(0,7);
            }
            result.add(value);
        }
        return result;
    }

    
    @AuraEnabled(cacheable=true)
    public static List<String> getDeliverySummary(List<String> usageDates, 
                                                  List<String> costCenters,
                                                  List<String> approverNames,
                                                  List<String> users,
                                                  List<String> businessUnits,
                                                  List<String> productNames) {
        List<String> summary = new List<String>();

        String query = ' SELECT SUM(Tokens_Consumed__c) Tokens_Consumed__c, ' +
                       '        SUM(Token_Cost__c) Token_Cost__c ' +
                       ' FROM Token_Flex_Usage__c ';

        if (costCenters != null && !costCenters.isEmpty()) {
            query += 'WHERE Cost_Center__c IN :costCenters ';
        }

        if (approverNames != null && !approverNames.isEmpty()) {
            query += 'AND Approver_Name__c IN :approverNames ';
        }

        if (users != null && !users.isEmpty()) {
            query += 'AND Email__c IN :users ';
        }

        if (businessUnits != null && !businessUnits.isEmpty()) {
            query += 'AND Business_Unit__c IN :businessUnits ';
        }

        if (productNames != null && !productNames.isEmpty()) {
            query += 'AND Product_Name__c IN :productNames ';
        }

        if (usageDates != null && !usageDates.isEmpty()) {
            query += 'AND Usage_Billing_Period__c IN :usageDates ';
        }

        List<AggregateResult> tf = Database.query(query);
        summary.add(String.valueOf(tf[0].get('Tokens_Consumed__c')));
        summary.add(String.valueOf(tf[0].get('Token_Cost__c')));

        return summary;
    }

    @AuraEnabled(cacheable=true)
    public static List<Token_Flex_Usage__c> getTokenFlexUsage(List<String> usageDates, 
                                                  List<String> costCenters,
                                                  List<String> approverNames,
                                                  List<String> users,
                                                  List<String> businessUnits,
                                                  List<String> productNames) {
        List<Token_Flex_Usage__c> result = new List<Token_Flex_Usage__c>();

        try {
            String query = 'SELECT Id,'
                         + '       Type__c,'
                         + '       Usage_Date__c,'
                         + '       Usage_Billing_Period__c,'
                         + '       Cost_Center__c,'
                         + '       Approver_Name__c,'
                         + '       Email__c,'
                         + '       Business_Unit__c,'
                         + '       Product_Name__c,'
                         + '       Project_Name__c,'
                         + '       Company_Code__c,'
                         + '       Token_Cost__c,'                         
                         + '       Email_Domain__c,'
                         + '       Tokens_Consumed__c '
                         + 'FROM Token_Flex_Usage__c ';

            if (costCenters != null && !costCenters.isEmpty()) {
                query += 'WHERE Cost_Center__c IN :costCenters ';
            }

            if (approverNames != null && !approverNames.isEmpty()) {
                query += 'AND Approver_Name__c IN :approverNames ';
            }

            if (users != null && !users.isEmpty()) {
                query += 'AND Email__c IN :users ';
            }

            if (businessUnits != null && !businessUnits.isEmpty()) {
                query += 'AND Business_Unit__c IN :businessUnits ';
            }

            if (productNames != null && !productNames.isEmpty()) {
                query += 'AND Product_Name__c IN :productNames ';
            }

            if (usageDates != null && !usageDates.isEmpty()) {
                query += 'AND Usage_Billing_Period__c IN :usageDates ';
            }

            query += 'ORDER BY Usage_Date__c DESC, Cost_Center__c ';
            query += 'LIMIT 2000';
            result = Database.query(query);

        } catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }

        return result;
    }

}