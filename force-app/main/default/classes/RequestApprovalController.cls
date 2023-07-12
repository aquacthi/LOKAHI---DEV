public without sharing class RequestApprovalController {
    public RequestApprovalController() {

    }

    public static String APPROVED = 'Approved';
    public static String REJECTED = 'Rejected';

    // Approve selected project request ids, and reject all other request projects that were not selected
    @AuraEnabled
    public static String updateRequestProject(String decision, String denialReason, String otherDenialReason, String projectRequestIds, String recordId){
        try {

            List<String> projectRequestString = projectRequestIds.split(',');
            Set<String> projectRequestIdSet = new Set<String>(projectRequestString);            
            
            List<Request_Project__c> requestProjectsToUpdate = [SELECT Id, Approval_Status__c FROM Request_Project__c WHERE Request__c = :recordId];
            for(Request_Project__c rp : requestProjectsToUpdate) {
                if(projectRequestIdSet.contains(rp.Id)) {
                    rp.Approval_Status__c = APPROVED;
                } else {
                    rp.Approval_Status__c = REJECTED;
                }
            }
            if (!requestProjectsToUpdate.isEmpty()) {
                update requestProjectsToUpdate;
            }

            // Update the request based on the decision
            BC_Request__c request = new BC_Request__c();
            request.Id = recordId;
            if (decision == APPROVED) {
                request.APOC_Approval__c = APPROVED;
            } else {
                request.APOC_Approval__c = REJECTED;
                request.Denial_Reason__c = denialReason;
                if (denialReason == 'Other') 
                    request.Other_Denial_Reason__c = otherDenialReason;
            }
            update request;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return 'success';
    }

    @AuraEnabled(cacheable=true)
    public static Boolean getRequestApprover(String requestId) {
        Boolean result = false;

        // get the request to fetch the amazon poc contact id
        List<BC_Request__c> bcRequest = [SELECT Id, Amazon_POC__c FROM BC_Request__c WHERE Id = :requestId];
        
        // get the apoc user based on the amazon poc contact id
        if(!bcRequest.isEmpty()) {
            List<User> apocUser = [SELECT Id FROM User WHERE ContactId = :bcRequest[0].Amazon_POC__c];
            if(!apocUser.isEmpty() && apocUser[0].Id == UserInfo.getUserId()) {
                result = true;
            }
        }
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<Request_Project__c> getRequestProjectList(String requestId) {
        // get the list of request projects to display 
        return [
            SELECT 
                // Id, 
                Approval_Status__c, 
                BIM_Project_Name__c, 
                Project_Name__c, 
                Project_Name_Entered__c, 
                // Project_Record_Name__c, 
                Request__c, 
                Role__c 
            FROM Request_Project__c
            WHERE Request__c = :requestId
        ];
    }
}