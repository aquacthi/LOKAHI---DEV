public without sharing class UserCostCenterMappingTriggerHandler {

    public static void onAfterInsert(Map<Id, User_Cost_Center_Mapping__c> newMap) {
        createPublicGroupRecord(newMap);
    }

    public static void onAfterUpdate(Map<Id, User_Cost_Center_Mapping__c> newMap, Map<Id, User_Cost_Center_Mapping__c> oldMap) {
        modifyOrDeleteGroupMemberRecord(newMap, oldMap);
    }

    public static void onAfterDelete( Map<Id, User_Cost_Center_Mapping__c> oldMap) {
        modifyOrDeleteGroupMemberRecord(null, oldMap);
    }

    public static void createPublicGroupRecord(Map<Id, User_Cost_Center_Mapping__c> newItems) {
        List<Group> GroupToInsert = new List<Group>();
        List<GroupMember> GroupMemberToInsert = new List<GroupMember>();

        Map<String, List<User_Cost_Center_Mapping__c>> userCostCenterMappingListByCostCenter = new Map<String, List<User_Cost_Center_Mapping__c>>();
        Set<Id> userCostCenterIds = new Set<Id>();

        for (User_Cost_Center_Mapping__c userCostCenter  : newItems.values()) {
            if (userCostCenter.Cost_Center__c != null) {

                //Used to create Group
                if (userCostCenterMappingListByCostCenter.containsKey(userCostCenter.Cost_Center__c)) {
                    userCostCenterMappingListByCostCenter.get(userCostCenter.Cost_Center__c).add(userCostCenter);
                } else {
                    userCostCenterMappingListByCostCenter.put(userCostCenter.Cost_Center__c, new List<User_Cost_Center_Mapping__c>{userCostCenter});
                }

                if (userCostCenter.User__c != null) {
                    //Used to create GroupMember
                    userCostCenterIds.add(userCostCenter.Id);
                }
            }
        }

        if (userCostCenterMappingListByCostCenter.isEmpty()) {
            return; //return if no record to process
        }

        Map<String, Group> groupByCostCenter = getPublicGroupByCostCenter(userCostCenterMappingListByCostCenter.keySet());      

        // insert Group
        for (String costCenter : userCostCenterMappingListByCostCenter.keySet()) {
            if (groupByCostCenter.containsKey(costCenter)) {
                continue;
            } else {
                Group g = new Group(
                    Name = 'Cost Center ' + costCenter,
                    DeveloperName = 'Cost_Center_' + costCenter,
                    Type = 'Regular'
                );

                GroupToInsert.add(g);
            }
        }

        if (!GroupToInsert.isEmpty()) {
            insert GroupToInsert;
        }

        createGroupMemberRecord(userCostCenterIds);
    }

    @future
    public static void createGroupMemberRecord(Set<Id> userCostCenterIds) {
        List<GroupMember> GroupMemberToInsert = new List<GroupMember>();        

        Map<String, List<User_Cost_Center_Mapping__c>> userCostCenterMappingListByCostCenter = new Map<String, List<User_Cost_Center_Mapping__c>>();

        for (User_Cost_Center_Mapping__c userCostCenter  : [SELECT Id, Name, User__c, Cost_Center__c
                                                            FROM User_Cost_Center_Mapping__c
                                                            WHERE Id = :userCostCenterIds]) {
            if (userCostCenter.Cost_Center__c != null && userCostCenter.User__c != null) {
                if (userCostCenterMappingListByCostCenter.containsKey(userCostCenter.Cost_Center__c)) {
                    userCostCenterMappingListByCostCenter.get(userCostCenter.Cost_Center__c).add(userCostCenter);
                } else {
                    userCostCenterMappingListByCostCenter.put(userCostCenter.Cost_Center__c, new List<User_Cost_Center_Mapping__c>{userCostCenter});
                }
            }
        }
        
        Map<String, Group> publicGroupByCostCenter = getPublicGroupByCostCenter(userCostCenterMappingListByCostCenter.keySet());
        Map<Id, Set<Id>> userIdByGroupId = getExistingGroupMemberByGroupId(userCostCenterMappingListByCostCenter.keySet());

        // insert GroupMember
        for (String costCenter : userCostCenterMappingListByCostCenter.keySet()) {
            Id publicGroupId = publicGroupByCostCenter.get(costCenter).Id;

            for (User_Cost_Center_Mapping__c userCostCenter : userCostCenterMappingListByCostCenter.get(costCenter)) {
                if (userIdByGroupId.get(publicGroupId) != null && userIdByGroupId.get(publicGroupId).contains(userCostCenter.User__c)) {
                    continue;
                } else {
                    GroupMember gm = new GroupMember(
                        GroupId = publicGroupId,
                        UserOrGroupId = userCostCenter.User__c
                    );
                    GroupMemberToInsert.add(gm);
                }
                
            }
        }

        if (!GroupMemberToInsert.isEmpty()) {
            insert GroupMemberToInsert;
        }
    }

    public static void modifyOrDeleteGroupMemberRecord(Map<Id, User_Cost_Center_Mapping__c> newItems, Map<Id, User_Cost_Center_Mapping__c> oldItems) {
        Set<Id> userCostCenterIds = new Set<Id>();
        Set<Id> groupMemberIds = new Set<Id>();

        Map<String, List<User_Cost_Center_Mapping__c>> userCostCenterMappingListByCostCenter = new Map<String, List<User_Cost_Center_Mapping__c>>();

        for (User_Cost_Center_Mapping__c userCostCenter  : oldItems.values()) {

            if (isMeetConditions(userCostCenter.Id)) {
                if (userCostCenterMappingListByCostCenter.containsKey(userCostCenter.Cost_Center__c)) {
                    userCostCenterMappingListByCostCenter.get(userCostCenter.Cost_Center__c).add(userCostCenter);
                } else {
                    userCostCenterMappingListByCostCenter.put(userCostCenter.Cost_Center__c, new List<User_Cost_Center_Mapping__c>{userCostCenter});
                }
            }
        }

        if (userCostCenterMappingListByCostCenter.isEmpty()) {
            return; //return if no record to process
        }

        Map<String, Set<Id>> userByCostCenter = getUserCostCenterMapping(userCostCenterMappingListByCostCenter.keySet());
        Map<String, Group> publicGroupByCostCenter = getPublicGroupByCostCenter(userCostCenterMappingListByCostCenter.keySet());        
        Map<Id, List<GroupMember>> groupMemberByGroupId = getGroupMemberByGroupId(userCostCenterMappingListByCostCenter.keySet());

        // find user
        for (String costCenter : userCostCenterMappingListByCostCenter.keySet()) {
            Id publicGroupId = publicGroupByCostCenter.get(costCenter).Id;

            for (User_Cost_Center_Mapping__c userCostCenter : userCostCenterMappingListByCostCenter.get(costCenter)) {
                if (userByCostCenter.get(costCenter) != null && userByCostCenter.get(costCenter).contains(userCostCenter.User__c)) {
                    // Do not anything                   
                } else {
                    if (groupMemberByGroupId.get(publicGroupId) != null) {
                        for (GroupMember gm : groupMemberByGroupId.get(publicGroupId)) {
                            if (gm.UserOrGroupId == userCostCenter.User__c) {
                                groupMemberIds.add(gm.Id);
                            }
                        }   
                    }                            
                }

                if (Trigger.isUpdate) {
                    userCostCenterIds.add(userCostCenter.Id);
                } 
            }
        }

        if (!groupMemberIds.isEmpty()) {
            deleteGroupMemberRecord(groupMemberIds);
        }

        Map<Id, User_Cost_Center_Mapping__c> userCostCenterById = new Map<Id, User_Cost_Center_Mapping__c>();
        if (Trigger.isUpdate) {
            for (User_Cost_Center_Mapping__c uc : newItems.values()) {
                if (userCostCenterIds.contains(uc.Id)) {
                    userCostCenterById.put(uc.Id, uc);
                }
            }
        }

        if (!userCostCenterById.isEmpty()) {
            createPublicGroupRecord(userCostCenterById);
        }     
    }

    @future
    public static void deleteGroupMemberRecord(Set<Id> groupMemberIds) {
        List<GroupMember> groupMemberToDelete = [SELECT Id, GroupId, UserOrGroupId, SystemModstamp
                                                 FROM GroupMember
                                                 WHERE Id IN :groupMemberIds];
        
        if (!groupMemberToDelete.isEmpty()) {
            delete groupMemberToDelete;
        }
    }

    private static Map<String, Group> getPublicGroupByCostCenter(Set<String> costCenterIds) {
        Map<String, Group> result = new Map<String, Group>();
        List<String> costCenterList = new List<String>();

        for (String costCenter : costCenterIds) {
            costCenterList.add('Cost_Center_' + costCenter);
        }

        for (Group g : [SELECT Id, Name, DeveloperName, RelatedId, Type, Email, OwnerId, DoesSendEmailToMembers, DoesIncludeBosses, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp
                        FROM Group
                        WHERE Type = 'Regular'
                        AND DeveloperName IN :costCenterList]) {

            List<String> tempString = g.DeveloperName.split('_');
            String costCenterFromGroup = tempString.get(tempString.size()-1);
            
            result.put(costCenterFromGroup, g);
        }

        return result;
    }

    private static Map<Id, Set<Id>> getExistingGroupMemberByGroupId(Set<String> costCenterIds) {
        Map<Id, Set<Id>> result = new Map<Id, Set<Id>>();
        List<String> costCenterList = new List<String>();

        for (String costCenter : costCenterIds) {
            costCenterList.add('Cost_Center_' + costCenter);
        }

        for (GroupMember gm : [SELECT Id, GroupId, UserOrGroupId, SystemModstamp
                               FROM GroupMember
                               WHERE Group.DeveloperName IN :costCenterList]) {
                                
            if (result.containsKey(gm.GroupId)) {
                result.get(gm.GroupId).add(gm.UserOrGroupId);
            } else {
                result.put(gm.GroupId, new Set<Id>{gm.UserOrGroupId});
            }
        }

        return result;
    }
    
    private static Map<Id, List<GroupMember>> getGroupMemberByGroupId(Set<String> costCenterIds) {
        Map<Id, List<GroupMember>> result = new Map<Id, List<GroupMember>>();

        List<String> costCenterList = new List<String>();

        for (String costCenter : costCenterIds) {
            costCenterList.add('Cost_Center_' + costCenter);
        }

        for (GroupMember gm : [SELECT Id, GroupId, UserOrGroupId, SystemModstamp
                               FROM GroupMember
                               WHERE Group.DeveloperName IN :costCenterList]) {
                                
            if (result.containsKey(gm.GroupId)) {
                result.get(gm.GroupId).add(gm);
            } else {
                result.put(gm.GroupId, new List<GroupMember>{gm});
            }
        }

        return result;
    }

    private static Map<String, Set<Id>> getUserCostCenterMapping(Set<String> costCenterIds) {
        Map<String, Set<Id>> result = new Map<String, Set<Id>>();

        for (User_Cost_Center_Mapping__c userCostCenter : [SELECT Id, User__c, Cost_Center__c
                                                           FROM User_Cost_Center_Mapping__c
                                                           WHERE Cost_Center__c = :costCenterIds]) {                             
            if (result.containsKey(userCostCenter.Cost_Center__c)) {
                result.get(userCostCenter.Cost_Center__c).add(userCostCenter.User__c);
            } else {
                result.put(userCostCenter.Cost_Center__c, new Set<Id>{userCostCenter.User__c});
            }
        }

        return result;
    }

    private static Boolean isMeetConditions(Id recordId) {
        Boolean result = false;

        if (Trigger.isUpdate && 
            (Trigger.newMap.get(recordId).get('Cost_Center__c') != Trigger.oldMap.get(recordId).get('Cost_Center__c') ||
             Trigger.newMap.get(recordId).get('User__c') != Trigger.oldMap.get(recordId).get('User__c'))) {

            result = true;
        } else if (Trigger.isDelete && Trigger.oldMap.get(recordId).get('Cost_Center__c') != null && Trigger.oldMap.get(recordId).get('User__c') != null) {
            result = true;
        }

        return result;
    }
}