public without sharing class TokenFlexUsageTriggerHandler {

    public static void onAfterInsert(Map<Id, Token_Flex_Usage__c> newMap) {
        createShareRecord(newMap, null);
    }

    public static void onAfterUpdate(Map<Id, Token_Flex_Usage__c> newMap, Map<Id, Token_Flex_Usage__c> oldMap) {
        createShareRecord(newMap, oldMap);
    }

    //Token_Flex_Usage__c record
    public static void createShareRecord(Map<Id, Token_Flex_Usage__c> newItems, Map<Id, Token_Flex_Usage__c> oldItems) {

        List<Token_Flex_Usage__Share> TokenFlexUsageShareRecordsToInsert = new List<Token_Flex_Usage__Share>();
        //List<Token_Flex_Usage__c> TokenFlexUsageShareRecordsToDelete = new List<Token_Flex_Usage__c>();

        Map<String, List<Token_Flex_Usage__c>> tokenFlexUsageListByCostCenter = new Map<String, List<Token_Flex_Usage__c>>();
        Set<Id> tokenIds = new Set<Id>();

        for (Token_Flex_Usage__c tf : newItems.values()) {
            if ((Trigger.isInsert && tf.Cost_Center__c != null) ||
                (Trigger.isUpdate && tf.Cost_Center__c != null && tf.Cost_Center__c != (String)oldItems.get(tf.Id).get('Cost_Center__c'))) {

                tokenIds.add(tf.Id);

                if (tokenFlexUsageListByCostCenter.containsKey(tf.Cost_Center__c)) {
                    tokenFlexUsageListByCostCenter.get(tf.Cost_Center__c).add(tf);
                } else {
                    tokenFlexUsageListByCostCenter.put(tf.Cost_Center__c, new List<Token_Flex_Usage__c>{tf});
                }
            }
        }

        if (tokenFlexUsageListByCostCenter.isEmpty()) {
            return; //return if no record to process
        }
                                        
        Map<String, Group> publicGroupByCostCenter = getPublicGroup();

        List<Token_Flex_Usage__Share> existingShareRecordsByParentId = getExistingShareRecordsByParentId(tokenIds);

        if (!existingShareRecordsByParentId.isEmpty()) {
            delete existingShareRecordsByParentId;
        }

        // insert 
        for (String costCenter : tokenFlexUsageListByCostCenter.keySet()) {
            if (!publicGroupByCostCenter.containsKey(costCenter)) {
                continue;
            }

            Id publicGroupId = publicGroupByCostCenter.get(costCenter).Id;

            for (Token_Flex_Usage__c tf : tokenFlexUsageListByCostCenter.get(costCenter)) {
                Token_Flex_Usage__Share newShare = new Token_Flex_Usage__Share(
                    UserOrGroupId = publicGroupId,
                    AccessLevel = 'Edit',
                    ParentId = tf.Id
                );

                TokenFlexUsageShareRecordsToInsert.add(newShare);
            }
        }

        if (!TokenFlexUsageShareRecordsToInsert.isEmpty()) {
            insert TokenFlexUsageShareRecordsToInsert;
        }
    }

    private static Map<String, Group> getPublicGroup() {

        Map<String, Group> result = new Map<String, Group>();

        for (Group g : [SELECT Id, Name, DeveloperName, RelatedId, Type, Email, OwnerId, DoesSendEmailToMembers, DoesIncludeBosses, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp
                        FROM Group
                        WHERE Type = 'Regular'
                        AND DeveloperName LIKE 'Cost_Center_%']) {

            List<String> tempString = g.DeveloperName.split('_');
            String costCenterFromGroup = tempString.get(tempString.size()-1);
            
            result.put(costCenterFromGroup, g);
        }

        return result;
    }

    private static List<Token_Flex_Usage__Share> getExistingShareRecordsByParentId(Set<Id> tokenFlexUsageIds) {

        List<Token_Flex_Usage__Share> result= [SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause, LastModifiedDate, LastModifiedById, IsDeleted 
                                                FROM Token_Flex_Usage__Share
                                                WHERE ParentId IN :tokenFlexUsageIds 
                                                AND RowCause = 'Manual'];
        
        return result;
    }

}