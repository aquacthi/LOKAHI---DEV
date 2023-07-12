/*
 * (Summary)    An apex controller for Token Flex Usage dashboard
 * (Copyright)  WWD
 * (Author)     kimdanbi
 * (Email)      kimdanbi@amazon.com

 * (Change Log)
 * Date       | Author                                   | Version | Comments
 * ------------------------------------------------------------------------------------------------
 * 2022-09-16 | kimdanbi                                 | 1.0     | Initial Design
 * 
 * 
 * * @todo See individual method todos.
 * 
 */

public without sharing class TokenFlexDashboardController {

    /**
    * Gets Token_Flex_Usage__c list
    *
    */
    @AuraEnabled(cacheable=true)
    public static List<Token_Flex_Usage__c> getTokenFlexUsage(List<String> usageDates, 
                                                  List<String> costCenters,
                                                  List<String> approverNames,
                                                  List<String> users,
                                                  List<String> businessUnits,
                                                  List<String> productNames) {
        List<Token_Flex_Usage__c> result = new List<Token_Flex_Usage__c>();

        try {
            List<String> costCenter = getCostCenterGroup();

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
            } else {
                query += 'WHERE Cost_Center__c IN :costCenter ';
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

            query += 'ORDER BY Usage_Date__c, Cost_Center__c';
            
            if (usageDates != null && !usageDates.isEmpty()) {            
                for (Token_Flex_Usage__c tf : Database.query(query)) {   
                    for (String u : usageDates) {                    
                        String tokenUsageDate = String.valueOf(tf.Usage_Date__c).substring(0,7);

                        if (u == tokenUsageDate) {
                            result.add(tf);
                        }                        
                    }
                } 
            }else {
                for (Token_Flex_Usage__c tf : Database.query(query)) {   
                    result.add(tf);
                } 
            }


        } catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }

        return result;
    }

    /**
    * Gets options value 
    *
    */
    @AuraEnabled(cacheable=true)
    public static TokenFlexUsageOptions getTokenFlexUsageOption(){
        TokenFlexUsageOptions result = new TokenFlexUsageOptions();

        try {
            List<String> costCenters = getCostCenterGroup(); 

            Set<String> usageDates = new Set<String>();
            Set<String> approverNames = new Set<String>();
            Set<String> users = new Set<String>();
            Set<String> businessUnits = new Set<String>();
            Set<String> productNames = new Set<String>();

            List<Token_Flex_Usage__c> tokenFlexUsageList= [SELECT Usage_Date__c,
                                                                  Approver_Name__c,
                                                                  Email__c,
                                                                  Business_Unit__c,
                                                                  Product_Name__c
                                                           FROM Token_Flex_Usage__c
                                                           WHERE Cost_Center__c IN :costCenters
                                                           ORDER BY Usage_Date__c DESC, Approver_Name__c, Email__c, Business_Unit__c, Product_Name__c
                                                           LIMIT 10000
                                                           ];
            for (Token_Flex_Usage__c tf : tokenFlexUsageList) {

                if (tf.Usage_Date__c != null) {
                    String tokenUsageDate = String.valueOf(tf.Usage_Date__c).substring(0,7);
                    usageDates.add(tokenUsageDate);
                }
                
                if (tf.Approver_Name__c != null) {
                    approverNames.add(tf.Approver_Name__c);
                }

                if (tf.Email__c != null) {   
                    users.add(tf.Email__c);
                }

                if (tf.Business_Unit__c != null) { 
                    businessUnits.add(tf.Business_Unit__c);
                }

                if (tf.Product_Name__c != null) { 
                    productNames.add(tf.Product_Name__c);
                }
            }

            if (!costCenters.isEmpty()) {
                result.costCenterList = new List<String>(costCenters);
            }

            if (!usageDates.isEmpty()) {
                result.usageDateList = new List<String>(usageDates);
            }

            if (!approverNames.isEmpty()) {
                result.approverNameList = new List<String>(approverNames);
            }

            if (!users.isEmpty()) {
                result.userList = new List<String>(users);
            }

            if (!businessUnits.isEmpty()) {
                result.businessUnitList = new List<String>(businessUnits);
            }

            if (!productNames.isEmpty()) {
                result.productNameList = new List<String>(productNames);
            }


        } catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }

        return result;
    }

    /**
    * Gets tokens consumed by product name value 
    *
    */
    @AuraEnabled(cacheable=true)
    public static Map<String, Decimal> getTokensConsumedByProduct(){      
        Map<String, Decimal> result = new Map<String, Decimal>();

        try {
            List<String> costCenterList = getCostCenterGroup(); 

            List<AggregateResult> tokenFlexUsageList = [SELECT Product_Name__c, 
                                                               SUM(Tokens_Consumed__c) tokenSum
                                                        FROM Token_Flex_Usage__c
                                                        WHERE Cost_Center__c IN :costCenterList
                                                        GROUP BY Product_Name__c
                                                        ORDER BY SUM(Tokens_Consumed__c) DESC, Product_Name__c];

            Integer countLegend = 1;

            for (AggregateResult aggr : tokenFlexUsageList) {                
                if (countLegend <= 5) {
                    result.put(String.valueOf(aggr.get('Product_Name__c')), Decimal.valueOf(String.valueOf(aggr.get('tokenSum'))));
                } else {

                    if (result.containsKey('Others')) {
                        Decimal existingValue = result.get('Others') + Decimal.valueOf(String.valueOf(aggr.get('tokenSum')));
                        result.put('Others', existingValue);
                    } else {
                        result.put('Others', Decimal.valueOf(String.valueOf(aggr.get('tokenSum'))));
                    }
                }
                
                countLegend++;                               
            }    

        } catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }

        return result;
    }

    /**
    * Gets tokens consumed by company value 
    *
    */
    @AuraEnabled(cacheable=true)
    public static Map<String, Decimal> getTokensConsumedByCompany(){      
        Map<String, Decimal> result = new Map<String, Decimal>();

        try {
            List<String> costCenterList = getCostCenterGroup();

            List<Token_Flex_Usage__c> tokenFlexUsageList = [SELECT Id, 
                                                                   Email_Domain__c, 
                                                                   Tokens_Consumed__c
                                                            FROM Token_Flex_Usage__c
                                                            WHERE Cost_Center__c IN :costCenterList];

            for (Token_Flex_Usage__c tokenFlex : tokenFlexUsageList) {

                if (tokenFlex.Email_Domain__c != null) {
                    String compnayName = '';
                    if (tokenFlex.Email_Domain__c == 'amazon') {
                        compnayName = 'Amazon';
                    } else {
                        compnayName = '3rd Party Vendors';
                    }

                    if (result.containsKey(compnayName)) {
                        Decimal count = result.get(compnayName) + tokenFlex.Tokens_Consumed__c;
                        result.put(compnayName, count);
                    } else {
                        result.put(compnayName, tokenFlex.Tokens_Consumed__c);
                    }

                }                                              
            }    

        } catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }

        return result;
    }

    /**
    * Gets tokens consumed by period value 
    *
    */
    @AuraEnabled(cacheable=true)
    public static Map<String, Map<String,Decimal>> getTokensConsumedByPeriod(String period){      
        Map<String, Map<String,Decimal>> result = new Map<String, Map<String,Decimal>>();

        try {
            List<String> costCenterList = getCostCenterGroup(); 

            List<AggregateResult> aggrList = [SELECT Cost_Center__c , 
                                                     Usage_Date__c,
                                                     SUM(Tokens_Consumed__c) Tokens_Consumed__c
                                              FROM Token_Flex_Usage__c
                                              WHERE Cost_Center__c IN :costCenterList
                                              AND Usage_Billing_Period__c > :period
                                              GROUP BY Cost_Center__c , Usage_Date__c];

            for (AggregateResult aggr : aggrList) {

                if (aggr.get('Cost_Center__c') != null) {
                    String contCenter = String.valueOf(aggr.get('Cost_Center__c'));
                    String tokenUsageDate = String.valueOf(aggr.get('Usage_Date__c')).substring(0,7); 
                    Decimal tokenConsumed = (Decimal) aggr.get('Tokens_Consumed__c');

                    if (result.containsKey(contCenter)) {                         

                        if (result.get(contCenter).containsKey(tokenUsageDate)) {
                            Decimal consumed = result.get(contCenter).get(tokenUsageDate) + tokenConsumed;
                            result.get(contCenter).put(tokenUsageDate, consumed);

                        } else{
                            result.get(contCenter).put(tokenUsageDate, tokenConsumed);
                        }
                        
                    } else {
                        result.put(contCenter, new Map<String, Decimal>{tokenUsageDate => tokenConsumed});
                    }
                }                                              
            }    

        } catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }

        return result;
    }

    @AuraEnabled
    public static Map<String, String> getCSVHeaderNames() {
        Map<String, String> result = new Map<String, String>();

        for (Token_Flex_Usage_Dashboard_Export_Header__c header : Token_Flex_Usage_Dashboard_Export_Header__c.getAll().values()) {
            if (header.IsActive__c) {
                result.put(header.Field_API__c, header.Header_Label__c);
            }
        }

        return result;
    }

    private static List<String> getCostCenterGroup() {
        List<String> result = new List<String>();
        Set<Id> groupMemberIds = new Set<Id>();

        List<GroupMember> groupMemberList = [SELECT GroupId
                                             FROM GroupMember
                                             WHERE UserOrGroupId = :Userinfo.getUserId()];

        for (GroupMember gm : groupMemberList) {            
            groupMemberIds.add(gm.GroupId);
        }

        List<Group> groupList = [SELECT Id, Name, DeveloperName, RelatedId, Type
                                 FROM Group
                                 WHERE Type = 'Regular'
                                 AND DeveloperName LIKE '%Cost_Center%'
                                 AND Id IN :groupMemberIds
                                 ORDER BY DeveloperName];

        for (Group g : groupList) {
            List<String> tempString = g.DeveloperName.split('_');
            String costCenter = tempString.get(tempString.size()-1);
            
            result.add(costCenter);
        }  

        return result;
    }

    public class TokenFlexUsageOptions {

        @AuraEnabled
        public List<String> costCenterList;

        @AuraEnabled
        public List<String> usageDateList;

        @AuraEnabled
        public List<String> approverNameList;

        @AuraEnabled
        public List<String> userList;
    
        @AuraEnabled
        public List<String> businessUnitList;

        @AuraEnabled
        public List<String> productNameList;

        public TokenFlexUsageOptions() {
            this.costCenterList = new List<String>();
            this.usageDateList = new List<String>();
            this.approverNameList = new List<String>();
            this.userList = new List<String>();
            this.businessUnitList = new List<String>();
            this.productNameList = new List<String>();
        }
    }
}