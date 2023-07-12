/*
    Description : Token_Flex_Usage__c 
    Author : danbik@fiduciarytech.com
    Date : 2022-07-22
*/
global without sharing class TokenFlexUsageSharingCreationBatch implements Database.Batchable<sObject> {

    String query;

    global Database.QueryLocator start(Database.BatchableContext tkf) {
        //대상을 쿼리함.
        query = 'SELECT Id, Cost_Center__c FROM Token_Flex_Usage__c';

        return Database.getQueryLocator(query);

    }

    global void execute(Database.BatchableContext tkf, List<Token_Flex_Usage__c> tkfList) {
        //쿼리 결과를 쪼개서 로직 수행

        List<Token_Flex_Usage__Share> TokenFlexUsageShareRecordsToInsert = new List<Token_Flex_Usage__Share>();

        Map<String, List<Token_Flex_Usage__c>> tokenFlexUsageListByCostCenter = new Map<String, List<Token_Flex_Usage__c>>();
        Set<Id> tokenIds = new Set<Id>();

        for (Token_Flex_Usage__c tf : tkfList) {
            if (tf.Cost_Center__c != null) {

                tokenIds.add(tf.Id);

                if (tokenFlexUsageListByCostCenter.containsKey(tf.Cost_Center__c)) {
                    tokenFlexUsageListByCostCenter.get(tf.Cost_Center__c).add(tf);
                } else {
                    tokenFlexUsageListByCostCenter.put(tf.Cost_Center__c, new List<Token_Flex_Usage__c>{tf});
                }
            }
        }

        if (tokenFlexUsageListByCostCenter.isEmpty()) {
            System.debug('===================No Record====================');
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

    global void finish(Database.BatchableContext tkf) {
        //마지막에 해야할거? 이메일 보내거나 하는거
    }
    
    private static Map<String, Group> getPublicGroup() {

        Map<String, Group> result = new Map<String, Group>();

        for (Group g : [SELECT Id, Name, DeveloperName, RelatedId, Type, Email, OwnerId, DoesSendEmailToMembers, DoesIncludeBosses, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp
                        FROM Group
                        WHERE Type = 'Regular']) {

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