public without sharing class RequestProjectTriggerHandler {
 
    public static void onAfterInsert(List<Request_Project__c> newList) {
        System.debug('==================Request_Project onAfterInsert========================');

        // validate project exists
        checkProject(newList);
    }

    public static void onBeforeInsert(List<Request_Project__c> newList) {
        System.debug('==================Request_Project onBeforeInsert========================');
        
        // validate duplciate project request does not exists
        duplicateProjectCheck(newList);
    }

    public static void onAfterUpdate(List<Request_Project__c> newList, Map<Id, Request_Project__c> oldMap, Map<Id, Request_Project__c> newMap) {
        System.debug('==================Request_Project onBeforeInsert========================');
        
        // validate duplciate project request does not exists
        missingBIMProjectCorrected(newList, oldMap);

        // validate duplciate project request does not exists
        duplicateProjectCheck(newList);
    }

    public static void missingBIMProjectCorrected(List<Request_Project__c> newList, Map<Id, Request_Project__c> oldMap) {

        // Get all requests that had project populated
        Set<Id> requestsToCheck = new Set<Id>();
        for (Request_Project__c rp : newList) {
            if (oldMap.get(rp.Id).Project_Record_Name__c == null && 
                rp.Project_Name_Entered__c != null &&
                rp.Project_Record_Name__c != null) {
                requestsToCheck.add(rp.Request__c);
            }
        }
        // no requests to update
        if (requestsToCheck.isEmpty()) {
            return;
        }

        List<BC_Request__c> requestsToUpdate = new List<BC_Request__c>();
        for(BC_Request__c request : [SELECT Id, Stage__c, RecordTypeId, Is_BIM_Project_Blank__c, BIM_Project_Corrected__c,
                                    (
                                        SELECT Id, Project_Record_Name__c 
                                        FROM Request_Projects__r
                                        WHERE Id NOT IN :newList
                                    ) 
                                    FROM BC_Request__c 
                                    WHERE Id IN :requestsToCheck]) {
            Boolean updateBCRequest = false;
            
            // if there are no other request projects, update request
            if (request.Request_Projects__r.isEmpty()) {
                updateBCRequest = true;
            }
            // if other request projects still have blank project, then do not update request yet 
            else {
                for (Request_Project__c rp : request.Request_Projects__r) {
                    if (rp.Project_Record_Name__c == null) {
                        updateBCRequest = false;
                        break;
                    } else {
                        updateBCRequest = true;
                    }
                }
            }

            // Update BC Request to run automations again
            if (updateBCRequest && request.Stage__c == 'Evaluate' && request.Is_BIM_Project_Blank__c == true && (
                request.RecordTypeId == BCRequestTriggerHandler.amazonianRecordTypeId || 
                request.RecordTypeId == BCRequestTriggerHandler.nonAmazonianRecordTypeId
            )) {               
                request.Stage__c = 'New';
                request.Is_BIM_Project_Blank__c = false;
                request.BIM_Project_Corrected__c = true;

                requestsToUpdate.add(request);
            }
        }
        if (!requestsToUpdate.isEmpty()) {
            update requestsToUpdate;
        }

    }

    // Phase 3 Req 8 - Moved to Request Project - 1 BIM 360 CC request-no BIM Project
    public static void checkProject(List<Request_Project__c> newList) {

        Map<Id, BC_Request__c> requestsToUpdate = new Map<Id, BC_Request__c>();
        for(Request_Project__c rp : newList) {
            if(rp.Project_Record_Name__c == null) {
                requestsToUpdate.put(rp.Request__c,
                    new BC_Request__c(
                        Id = rp.Request__c, 
                        Stage__c = 'Evaluate',
                        Is_BIM_Project_Blank__c = true
                    )
                );
            }
        }

        if (!requestsToUpdate.isEmpty()) {
            update requestsToUpdate.values();
        }
    }

    // Phase 3 Req 8 - Moved to Request Project - 2 Missing BIM Project corrected


    // Duplicate Project check refactored from BCRequestTriggerHandler.processDuplicateRequest method
    public static void duplicateProjectCheck(List<Request_Project__c> newList) {

        if (System.Label.BC_Request_Bypass_Duplicate_Request_Method == 'Yes') return;

        Set<Id> requestIdsToCheck = new Set<Id>();
        Set<Id> projectIdsToCheck = new Set<Id>();
        for (Request_Project__c rp : newList) {
            requestIdsToCheck.add(rp.Request__c);
            projectIdsToCheck.add(rp.Project_Record_Name__c);
        }

        Map<Id, BC_Request__c> bcRequestList = getRequestList(requestIdsToCheck);
        processDuplicateRequest(newList, bcRequestList, projectIdsToCheck);

    }

    private static Map<Id, BC_Request__c> getRequestList(Set<Id> bcRequestIds) {
        return new Map<Id,BC_Request__c>([
            SELECT Id,
                RecordTypeId,
                Recipient_Email__c,
                Recipient_Alias_Domain_2__c,
                Duplicate_Request__c,
                Stage__c
            FROM BC_Request__c
            WHERE Id IN :bcRequestIds
        ]);
    }

    // Identifies Duplicate Request
    public static void processDuplicateRequest(List<Request_Project__c> newList, Map<Id, BC_Request__c> bcRequestList, Set<Id> projectIdsToCheck) {
        // Get BC_Request records
        List<BC_Request__c> requestDuplicateList = getBCRequest(bcRequestList.values(), projectIdsToCheck);

        //Get BC_User_Bill_To records
        List<BC_User_Bill_To__c> userBillToDuplicateList = getBCUserBillTo(bcRequestList.values(), projectIdsToCheck);

        Map<Id, BC_Request__c> bcRequestsToUpdate = new Map<Id, BC_Request__c>();
        Boolean updateBCRequest;
        Boolean containsProject;

        for (Request_Project__c rp : newList) {
            updateBCRequest = false;            
            // Get BC_Request records
            for (BC_Request__c request : requestDuplicateList) {

                // variable to check if new request project contains existing request project based on project  
                containsProject = false; 

                for (Request_Project__c existingRP : request.Request_Projects__r) {
                    if(existingRP.Project_Record_Name__c == rp.Project_Record_Name__c) {
                        containsProject = true;                        
                        break;
                    }
                }

                if (request.Record_Type_ID_18_digit__c == bcRequestList.get(rp.Request__c).RecordTypeId &&
                    containsProject && // request.BIM_Project__c == item.BIM_Project__c &&
                    request.Recipient_Alias_Domain_2__c == BCRequestTriggerHandler.getEmail(bcRequestList.get(rp.Request__c).Recipient_Email__c, 'emailAliasDomain2') &&
                    request.Id != bcRequestList.get(rp.Request__c).Id) { // Open BC_Request records exist
                    // Open BC_Request match
                    if (request.Recipient_Alias_Domain__c == BCRequestTriggerHandler.getEmail(bcRequestList.get(rp.Request__c).Recipient_Email__c, 'emailAliasDomain')) { // BC_Request match 
                        Id recordTypeID18 = request.RecordTypeId;
                        // Match type
                        if (recordTypeID18 == BCRequestTriggerHandler.tokenFlexRecordTypeId) { // 1 Token Flex License match
                            bcRequestList.get(rp.Request__c).Duplicate_Request__c = true;
                            updateBCRequest = true;
                            break;
                        } else if ((recordTypeID18 == BCRequestTriggerHandler.amazonianRecordTypeId ||
                                    recordTypeID18 == BCRequestTriggerHandler.nonAmazonianRecordTypeId) //&&
                                    // request.BIM_Project__c != null // this check seems repetitive
                                    ) { // 2 BIM 360 match
                            bcRequestList.get(rp.Request__c).Duplicate_Request__c = true;  
                            updateBCRequest = true;
                            break;
                        }
                    }
                }
            }
            // No open BC_Request records
            for (BC_User_Bill_To__c  userBill : userBillToDuplicateList) {
                // BC_User_Bill_To record return
                if (userBill.BIM_360_Project_ID__c == rp.Project_Record_Name__c &&
                    userBill.Access_Type_ID__c == bcRequestList.get(rp.Request__c).RecordTypeId &&
                    userBill.Member_Email_Alias_Domain_2__c == BCRequestTriggerHandler.getEmail(bcRequestList.get(rp.Request__c).Recipient_Email__c, 'emailAliasDomain2')) { // 3 BC_User Bill To record exist
                    // BC_User_Bill_To_match
                    if (userBill.Member_Email_Alias_Domain__c == BCRequestTriggerHandler.getEmail(bcRequestList.get(rp.Request__c).Recipient_Email__c, 'emailAliasDomain')) {  
                        bcRequestList.get(rp.Request__c).Duplicate_Request__c = true; 
                        updateBCRequest = true;
                        break;
                    }
                }
            }
            if (updateBCRequest) {
                bcRequestsToUpdate.put(bcRequestList.get(rp.Request__c).Id, bcRequestList.get(rp.Request__c));
            }
        }

        if (!bcRequestsToUpdate.isEmpty()) {
            update bcRequestsToUpdate.values();
        }
    }

    // Get records for duplicate request identification from BC_Request
    private static List<BC_Request__c> getBCRequest(List<BC_Request__c> bcRequestList, Set<Id> projectIdsToCheck) {
        Set<id> recordTypeIds = new Set<Id>();
        Set<String> recipientIds = new Set<String>();

        for (BC_Request__c bc : bcRequestList) {
            recordTypeIds.add(bc.RecordTypeId);
            recipientIds.add(BCRequestTriggerHandler.getEmail(bc.Recipient_Email__c, 'emailAliasDomain2'));
        }

        return [SELECT Id, 
                    Recipient_Alias_Domain__c, 
                    Recipient_Alias_Domain_2__c, 
                    Enter_Project_Name__c, 
                    Recipient__c, 
                    Record_Type_ID_18_digit__c,
                    RecordTypeId,                    
                    (
                        SELECT Id, Project_Record_Name__c
                        FROM Request_Projects__r
                        WHERE Project_Record_Name__c IN :projectIdsToCheck
                    )
                FROM BC_Request__c
                WHERE Status__c = :UtilityConsts.BC_STATUS_OPEN // 'Open'
                AND Record_Type_ID_18_digit__c IN :recordTypeIds
                AND Recipient_Alias_Domain_2__c IN :recipientIds
                AND IsDeleted = false];        
    }

    // Get records for duplicate request identification from BC_User_Bill_To
    private static List<BC_User_Bill_To__c> getBCUserBillTo(List<BC_Request__c> bcRequestList, Set<Id> projectIdsToCheck) {
        Set<id> accessTypeIds = new Set<Id>();
        Set<String> memberEmailIds = new Set<String>();

        for (BC_Request__c bc : bcRequestList) {
            accessTypeIds.add(bc.RecordTypeId);
            memberEmailIds.add(BCRequestTriggerHandler.getEmail(bc.Recipient_Email__c, 'emailAliasDomain2'));
        }
        
        return [SELECT Id, 
                    Member_Email_Alias_Domain__c,
                    Member_Email_Alias_Domain_2__c,
                    BIM_360_Project_ID__c, 
                    Access_Type_ID__c
                FROM BC_User_Bill_To__c
                WHERE Active__c = true
                AND BIM_360_Project_ID__c IN :projectIdsToCheck
                AND Access_Type_ID__c IN :accessTypeIds
                AND Member_Email_Alias_Domain_2__c IN :memberEmailIds
                AND IsDeleted = false];
    }

}