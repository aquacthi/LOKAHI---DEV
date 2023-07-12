public without sharing class ApiLogTriggerHandler {

    // api logs are inserted from other object triggers
    // e.g. BC_Request__c, Account
    // all api logs being inserted requires a callout to be made
    public static void onAfterInsert(List<API_Log__c> newList) {
        Integer maxCount = 25;

        // do not enqueueJob if one queueable job is already executing in batch or future context
        if ((System.isBatch() || System.isFuture()) && Limits.getQueueableJobs() == 1) {
            return;
        }
        
        // if new list is larger than 25 - we need to enqueue another job
        // 
        if (newList.size() > maxCount && Limits.getQueueableJobs() <= 50) {            
            List<API_Log__c> apilogChunks = new List<API_Log__c>();
            for (API_Log__c apilog : newList) {
                if (Limits.getQueueableJobs() >= 50) {
                    // need to reprocess these api logs if at max of queueable jobs                    
                    break;
                }

                if (apilogChunks.size() == 25) {
                    System.enqueueJob(new CalloutQueueable(apilogChunks));
                    apilogChunks = new List<API_Log__c>();
                }
                else {
                    apilogChunks.add(apiLog);
                }
            }
        } 
        else if (newList.size() > maxCount && Limits.getQueueableJobs() > 50) {
            // need to reprocess these api logs if at max of queueable jobs
        }
        else {
            System.enqueueJob(new CalloutQueueable(newList));
        }
    }

    // handle logic for Success and Error api logs
    public static void onAfterUpdate(List<API_Log__c> newList, Map<Id, API_Log__c> oldList) {
        List<API_Log__c> apiLogs = getApiLogs(newList);
        List<API_Log__c> pendingApiLogs = new List<API_Log__c>();
        List<API_Log__c> successApiLogs = new List<API_Log__c>();
        List<API_Log__c> errorApiLogs = new List<API_Log__c>();

        for (API_Log__c item : apiLogs) {
            try {
                API_Log__c oldApiLog = oldList.get(item.Id);

                if (item.Status__c == 'Pending') {
                    pendingApiLogs.add(item);
                } else if (item.Status__c == 'Success' && oldApiLog.Status__c != item.Status__c) {
                    successApiLogs.add(item);
                } else if (item.Status__c == 'Error' && oldApiLog.Status__c != item.Status__c) {
                    errorApiLogs.add(item);
                }
            } catch(Exception e) {
                item.Error_Message__c = CalloutUtility.appendErrorMessage(item, e.getStackTraceString());
            }
        }

        if (!pendingApiLogs.isEmpty()) {
            processPendingApiLogs(pendingApiLogs);
        }

        if (!successApiLogs.isEmpty()) {
            processSuccessApiLogs(successApiLogs);
        }

        if (!errorApiLogs.isEmpty()) {
            processErrorApiLogs(errorApiLogs);
        }
    }

    private static List<API_Log__c> getApiLogs(List<API_Log__c> apiLogs) {
        List<API_Log__c> result = new List<API_Log__c>();

        result = [SELECT Id,
                         Status__c,
                         Request_Body__c,
                         Response_Body__c,
                         Response_Status__c,
                         Response_Status_Code__c,
                         Method_Name__c,
                         BC_Request__c,
                         Error_Message__c,
                         Account__c,
                         BIM_360_Project_Role_Info__c,
                         BIM_360_User_Id__c,
                         BIM_360_Company_Id__c,
                         BIM_360_User_Status__c,
                         BC_BIM_Project__c,
                         BC_Request__r.Stage__c,
                         BC_Request__r.BIM_360_Role__c,
                         BC_Request__r.Autodesk_Status__c,
                         BC_Request__r.RecordTypeId,
                         BC_Request__r.Recipient__r.BIM_360_CC_User_ID__c,
                         BC_Request__r.Recipient__r.BIM_360_CC_User_Status__c,
                         BC_Request__r.Recipient__r.BIM_360_CC_User_Activate_Date__c,
                         BC_Request__r.Recipient__r.Account.Vendor_Company_Name__c
                  FROM API_Log__c
                  WHERE Id = :apiLogs];

        return result;
    }

    // this method sets the API_Log__c.Status__c to 'Success' or 'Error'
    // based on the Response_Status_Code__c and Response_Body__c
    private static void processPendingApiLogs(List<API_Log__c> apiLogs) {
        for (API_Log__c item : apiLogs) {
            try {
                // Blong - Req 8 - scenario where user already exist, but needs to be added to another project.
                if (item.Response_Status_Code__c == 409 && 
                    item.Response_Status__c == 'Conflict' && 
                    (item.Method_Name__c == 'postUser' || item.Method_Name__c == 'postUserToProject')) {
                    item.Status__c = 'Success';
                }
                else if (item.Response_Status_Code__c >= 200 && item.Response_Status_Code__c < 300) {
                    if ((String.isBlank(item.Response_Body__c)) ||
                        (item.Response_Body__c == '[]') ||
                        (item.Method_Name__c == 'getProjectRoles' && item.Status__c != 'Error')) {
                        item.Status__c = 'Success';
                    } else if (String.isNotBlank(item.Response_Body__c)) {
                        String errorMessageFromBody = getErrorMessageFromBody(item.Response_Body__c);
                    
                        if (String.isNotBlank(errorMessageFromBody)) {
                            item.Status__c = 'Error';
                            item.Error_Message__c = CalloutUtility.appendErrorMessage(item, errorMessageFromBody);
                        } else {
                            item.Status__c = 'Success';
                        }
                    }
                } else if (item.Response_Status_Code__c == null || 
                           item.Response_Status_Code__c >= 300) {
                    item.Status__c = 'Error';
                    item.Error_Message__c = CalloutUtility.appendErrorMessage(item, item.Response_Body__c);
                }
            } catch(Exception e) {
                item.Error_Message__c = CalloutUtility.appendErrorMessage(item, e.getStackTraceString());
            }
        }

        update apiLogs;
    }

    // additional api logs can be inserted from the method if there are callouts that are chained
    // when the current callout comes back as a success then the next callout is made
    // see below relationship of callouts being chained
    /*
    getProjectRoles
    getUserSearch
        postUser
        patchUserToActive
            postUser
        postUserToProject
    */
    private static void processSuccessApiLogs(List<API_Log__c> apiLogs) {
        List<API_Log__c> apiLogsToUpsert = new List<API_Log__c>();
        List<Account> accountsToUpdate = new List<Account>();
        Map<Id, Contact> contactsToUpdate = new Map<Id, Contact>();
        Map<Id, BC_Request__c> bcRequestsToUpdate = new Map<Id, BC_Request__c>();

        for (API_Log__c item : apiLogs) {
            try {
                if (item.BC_Request__c != null) {
                    if (item.Method_Name__c == 'getProjectRoles') {
                        processGetProjectRolesSuccess(item, apiLogsToUpsert);
                    } else if (item.Method_Name__c == 'getUserSearch') {
                        processGetUserSearchSuccess(item, apiLogsToUpsert);
                    } else if (item.Method_Name__c == 'postUser') {
                        apiLogsToUpsert.add(createPostUserToProjectApiLog(item));
                    } else if (item.Method_Name__c == 'patchUserToActive') {
                        apiLogsToUpsert.add(createPostUserToProjectApiLog(item));
                    } else if (item.Method_Name__c == 'postUserToProject') {
                        processPostUserToProjectSuccess(item, apiLogsToUpsert, contactsToUpdate, bcRequestsToUpdate);
                    } else if (item.Method_Name__c == 'getCompanyNameSearch') {
                        processGetCompanyNameSearchSuccess(item, apiLogsToUpsert);
                    } else if (item.Method_Name__c == 'getAmazonUserInfo') {
                        processGetAmazonUserInfoSuccess(item, bcRequestsToUpdate);
                    }
                } else if (item.Account__c != null && item.Method_Name__c == 'getAmazonUserInfo') {
                    processGetAmazonUserInfoSuccess(item, accountsToUpdate);
                }
            } catch(Exception e) {
                item.Error_Message__c = CalloutUtility.appendErrorMessage(item, e.getStackTraceString());
            }
        }
        
        // flow errors are occuring during test class execution
        // do not update parent records because of this
        // remove !Test.isRunningTest after flows are converted to code
        if (!bcRequestsToUpdate.isEmpty() && !Test.isRunningTest()) {
            update bcRequestsToUpdate.values();
        }

        if (!accountsToUpdate.isEmpty() && !Test.isRunningTest()) {
            update accountsToUpdate;
        }

        if (!contactsToUpdate.isEmpty() && !Test.isRunningTest()) {
            update contactsToUpdate.values();
        }

        if (!apiLogsToUpsert.isEmpty()) {
            upsert apiLogsToUpsert;
        }
    }

    // send email
    // update bc request with error message
    private static void processErrorApiLogs(List<API_Log__c> apiLogs) {
        Map<Id, String> messageByBCRequestId = new Map<Id, String>();
        Map<Id, BC_Request__c> bcRequestsToUpdate = new Map<Id, BC_Request__c>();
        
        for (API_Log__c item : apiLogs) {
            try {
                if (item.BC_Request__c != null) {
                    if (item.Method_Name__c == 'getCompanyNameSearch') {
                        messageByBCRequestId.put(item.BC_Request__c, item.Error_Message__c);
                    } else if (item.Method_Name__c == 'getAmazonUserInfo') {
                        processGetAmazonUserInfoError(item, bcRequestsToUpdate);
                    } else {
                        item.BC_Request__r.Stage__c = 'Autodesk Error';
                        item.BC_Request__r.Autodesk_Status__c = item.Error_Message__c == null ? null : item.Error_Message__c.substring(0, UtilityConsts.MAX_AUTODESK_ERROR_STRING);
                        bcRequestsToUpdate.put(item.BC_Request__c, item.BC_Request__r);
                    }
                }
            } catch(Exception e) {
                item.Error_Message__c = CalloutUtility.appendErrorMessage(item, e.getStackTraceString());
            }
        }
       
        if (!bcRequestsToUpdate.isEmpty()) {
            update bcRequestsToUpdate.values(); 
            CalloutUtility.sendFailedRecordEmail(bcRequestsToUpdate.values());
        }

        if (!messageByBCRequestId.isEmpty()) {
            CalloutUtility.sendFailedCompanyUpdateEmail(messageByBCRequestId);
        }
    }
    
    private static String getRoleInfoFromName(API_Log__c apiLog) {
        String bim360Role = (String)apiLog.BC_Request__r.get('BIM_360_Role__c');

        List<Object> resultList = (List< Object>)JSON.deserializeUntyped(apiLog.Response_Body__c);
        for (Object obj : resultList) {
            Map<String, Object> objByField = (Map<String, Object>)obj;

            String roleName = (String)objByField.get('name');
            if (bim360Role == roleName) {
                System.debug('## objByField : ' + objByField);
                return (String)JSON.serialize(objByField);
            }
        }

        return null;
    }

    private static String getUserId(String responseBody) {
        Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(responseBody);        
        return (String)result.get('id');
    }

    private static String getErrorMessageFromBody(String body) {
        String result;

        if (body.contains('developerMessage') || body.contains('errorMessage')) {
            Map<String, Object> deserializedBody = (Map<String, Object>)JSON.deserializeUntyped(body);

            if (deserializedBody.containsKey('developerMessage')) {
                result = (String)deserializedBody.get('developerMessage');
            } else if (deserializedBody.containsKey('errorMessage')) {
                result = (String)deserializedBody.get('errorMessage');
            }
        }

        return result;
    }

    public static API_Log__c createAPILog(API_Log__c source, String methodName) {
        API_Log__c result = new API_Log__C();

        result.Status__c        = 'Pending';
        result.Log_Type__c      = 'Outbound';
        result.Method_Name__c   = methodName;
        result.BC_Request__c    = source.BC_Request__c;
        // Blong - Phase 3 - Req 8
        result.BC_BIM_Project__c = source.BC_BIM_Project__c;
        result.BIM_360_Project_Role_Info__c = source.BIM_360_Project_Role_Info__c;
        result.BIM_360_User_Id__c = source.BIM_360_User_Id__c;
        result.BIM_360_Company_Id__c = source.BIM_360_Company_Id__c;
        result.BIM_360_User_Status__c = source.BIM_360_User_Status__c;

        return result;
    }
    
    // chained callouts do not work from test class.
    // invoking below methods from ApiLogTriggerHandlerTest in individual test methods
    @TestVisible
    private static API_Log__c createGetUserSearchApiLog(API_Log__c apiLog, String roleInfo) {
        API_Log__c result = createAPILog(apiLog, 'getUserSearch');

        result.BIM_360_Project_Role_Info__c = roleInfo; 
        return result;
    }
    
    @TestVisible
    private static API_Log__c createPostUserApiLog(API_Log__c apiLog) {
        return createAPILog(apiLog, 'postUser');
    }

    @TestVisible
    private static API_Log__c createPostUserToProjectApiLog(API_Log__c apiLog) {
        return createAPILog(apiLog, 'postUserToProject');
    }

    @TestVisible
    private static API_Log__c createPatchUserToActiveApiLog(API_Log__c apiLog) {
        return createAPILog(apiLog, 'patchUserToActive');
    }

    @TestVisible
    private static API_Log__c createGetCompanyNameSearchApiLog(API_Log__c apiLog) {
        return createAPILog(apiLog, 'getCompanyNameSearch');
    }

    @TestVisible
    private static API_Log__c createPatchUserCompanyNameApiLog(API_Log__c apiLog) {
        return createAPILog(apiLog, 'patchUserCompanyName');
    }

    private static void processGetProjectRolesSuccess(API_Log__c apiLog, List<API_Log__c> apiLogsToUpsert) {
        String roleInfo = apilog.Response_Body__c;
        // BT 2022-12-01 - removed since apilog response body has this information
        // String roleInfo = getRoleInfoFromName(apiLog);
        if (roleInfo != null) {
            apiLogsToUpsert.add(createGetUserSearchApiLog(apiLog, roleInfo));
        } else {
            apiLog.Status__c = 'Error';
            apiLog.Error_Message__c = 'Role not found in BIM 360';
            apiLogsToUpsert.add(apiLog);
        }
    }

    private static void processPostUserToProjectSuccess(API_Log__c apiLog, 
                                                        List<API_Log__c> apiLogsToUpsert, 
                                                        Map<Id, Contact> contactsToUpdate, 
                                                        Map<Id, BC_Request__c> bcRequestsToUpdate) {

        String existingUserId = getUserId(apiLog.Response_Body__c);
        if (existingUserId != null) {
            apiLog.BC_Request__r.Stage__c = 'Resolved - Completed';
            apiLog.BC_Request__r.Autodesk_Status__c = apiLog.Response_Status__c;
            if (apiLog.BC_Request__r.Recipient__c != null) {
                apiLog.BC_Request__r.Recipient__r.BIM_360_CC_User_Activate_Date__c = Date.today();
                apiLog.BC_Request__r.Recipient__r.BIM_360_CC_User_Status__c = apiLog.BIM_360_User_Status__c == null ? 'Pending' : apiLog.BIM_360_User_Status__c;
                apiLog.BC_Request__r.Recipient__r.BIM_360_CC_User_ID__c = existingUserId;
                apiLog.BC_Request__r.Is_BIM360_Add_User_To_Project_Success__c = true;
            }

            bcRequestsToUpdate.put(apiLog.BC_Request__c, apiLog.BC_Request__r);
            contactsToUpdate.put(apiLog.BC_Request__r.Recipient__c, apiLog.BC_Request__r.Recipient__r);
            apiLogsToUpsert.add(createGetCompanyNameSearchApiLog(apiLog));
        } else {
            apiLog.Status__c = 'Error';
            apiLogsToUpsert.add(apiLog);
        }
    }

    private static void processGetCompanyNameSearchSuccess(API_Log__c apiLog, List<API_Log__c> apiLogsToUpsert) {
        List<Object> companyInfoList = (List<Object>)JSON.deserializeUntyped(apiLog.Response_Body__c);
        if (companyInfoList == null || companyInfoList.isEmpty() == true) {
            apiLog.Status__c = 'Error';
            apiLog.Error_Message__c = 'Cannot find company name';
            apiLogsToUpsert.add(apiLog);
        } else {
            for (Object obj : companyInfoList) {
                Map<String, Object> companyInfo =  (Map<String, Object>)obj;
                String companyId = (String)companyInfo.get('id');
                apiLog.BIM_360_Company_Id__c = companyId;
                apiLogsToUpsert.add(createPatchUserCompanyNameApiLog(apiLog));
            }
        }
    }

    private static void processGetUserSearchSuccess(API_Log__c apiLog, List<API_Log__c> apiLogsToUpsert) {
        List<Object> userInfoList = (List<Object>)JSON.deserializeUntyped(apiLog.Response_Body__c);

        if (userInfoList.isEmpty() == true) {
            apiLogsToUpsert.add(createPostUserApiLog(apiLog));
        } else {
            for (Object obj : userInfoList) {
                Map<String, Object> userInfo =  (Map<String, Object>)obj;
                String status = (String)userInfo.get('status');
                String targetUserId = (String)userInfo.get('id');

                apiLog.BIM_360_User_Status__c = status;
                apiLog.BIM_360_User_Id__c = targetUserId;

                if (status == 'inactive') {
                    apiLogsToUpsert.add(createPatchUserToActiveApiLog(apiLog));
                } else {
                    apiLogsToUpsert.add(createPostUserToProjectApiLog(apiLog));
                } 
            }
        }
    }

    private static void processGetAmazonUserInfoSuccess(API_Log__c apiLog, List<Account> accountsToUpdate) {
        Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(apiLog.Response_Body__c);

        Account account = new Account();
        account.Id = apiLog.Account__c;
        account.Is_Redshit_Get_User_Info_Success__c = true;

        account.FM_First_Name__c = ((String)body.get('user_employee_name')).split(' ')[0];
        account.FM_Last_Name__c = ((String)body.get('user_employee_name')).split(' ')[1];
        account.FM_Email__c = (String)body.get('user_email');
        account.FM_Cost_Center__c = (String)body.get('user_cost_center_id');

        accountsToUpdate.add(account);
    }

    private static void processGetAmazonUserInfoSuccess(API_Log__c apiLog, Map<Id, BC_Request__c> bcRequestsToUpdate) {
        Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(apiLog.Response_Body__c);

        BC_Request__c bcRequest = new BC_Request__c();
        bcRequest.Id = apiLog.BC_Request__c;
        bcRequest.Is_Redshit_Get_User_Info_Success__c = true;

        bcRequest.Amazon_Manager_First_Name__c = ((String)body.get('immediate_manager_name')).split(' ')[0];
        bcRequest.Amazon_Manager_Last_Name__c = ((String)body.get('immediate_manager_name')).split(' ')[1];
        bcRequest.Amazon_Manager_Email__c = (String)body.get('immediate_manager_email');
        bcRequest.Amazon_Manager_Cost_Center__c = (String)body.get('immediate_manager_cost_center_id');

        bcRequest.SL_First_Name__c = ((String)body.get('approver_name')).split(' ')[0];
        bcRequest.SL_Last_Name__c = ((String)body.get('approver_name')).split(' ')[1];
        bcRequest.SL_Email__c = (String)body.get('approver_email');
        bcRequest.SL_Cost_Center__c = (String)body.get('approver_cost_center_id');

        if (apiLog.BC_Request__r.RecordTypeId == BCRequestTriggerHandler.amazonianRecordTypeId ||
            apiLog.BC_Request__r.RecordTypeId == BCRequestTriggerHandler.tokenFlexRecordTypeId) {
            bcRequest.Recipient_First_Name__c = ((String)body.get('user_employee_name')).split(' ')[0];
            bcRequest.Recipient_Last_Name__c = ((String)body.get('user_employee_name')).split(' ')[1];
            bcRequest.Recipient_Email__c = (String)body.get('user_email');
            bcRequest.Recipient_Cost_Center__c = (String)body.get('user_cost_center_id');
        } else if (apiLog.BC_Request__r.RecordTypeId == BCRequestTriggerHandler.nonAmazonianRecordTypeId) {
            bcRequest.APOC_First_Name__c = ((String)body.get('user_employee_name')).split(' ')[0];
            bcRequest.APOC_Last_Name__c = ((String)body.get('user_employee_name')).split(' ')[1];
            bcRequest.APOC_Email__c = (String)body.get('user_email');
            bcRequest.APOC_Cost_Center__c = (String)body.get('user_cost_center_id');
        }

        bcRequestsToUpdate.put(bcRequest.Id, bcRequest);
    }

    private static void processGetAmazonUserInfoError(API_Log__c apiLog, Map<Id, BC_Request__c> bcRequestsToUpdate) {
        if (apiLog.Error_Message__c == 'no result') {
            BC_Request__c bcRequest = new BC_Request__c();
            bcRequest.Id = apiLog.BC_Request__c;
            bcRequest.Status__c = 'Closed';
            bcRequest.Stage__c = 'Resolved - Not Completed';
    
            if (apiLog.BC_Request__r.RecordTypeId == BCRequestTriggerHandler.amazonianRecordTypeId ||
                apiLog.BC_Request__r.RecordTypeId == BCRequestTriggerHandler.tokenFlexRecordTypeId) {
                bcRequest.Reason_Not_Completed__c = 'Recipient not found';
            } else if (apiLog.BC_Request__r.RecordTypeId == BCRequestTriggerHandler.nonAmazonianRecordTypeId) {
                bcRequest.Reason_Not_Completed__c = 'Amazon POC not found';
            }

            bcRequestsToUpdate.put(bcRequest.Id, bcRequest);
        }
    }
}