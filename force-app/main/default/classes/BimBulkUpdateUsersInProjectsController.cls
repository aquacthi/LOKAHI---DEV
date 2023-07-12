public with sharing class BimBulkUpdateUsersInProjectsController {

    // Used to convert json property names (csv column headers) to sobject fields
    private static final Map<String, String> CSV_FIELD_NAME_BY_COLUMN_NAME = new Map<String, String>{
        'Accesses' => 'csv_Accesses__c',
        'Company Id' => 'csv_Company_Id__c',
        'Project Id' => 'csv_Project_Id__c',
        'Role Ids' => 'csv_Role_Ids__c',
        'Services' => 'csv_Services__c',
        'User Id' => 'csv_User_Id__c'
    };

    // Used to convert sobject fields to json property names(csv column headers)
    private static final Map<String, String> COLUMN_NAME_BY_CSV_FIELD_NAME = new Map<String, String>{
        'csv_Accesses__c' => 'Accesses',
        'csv_Company_Id__c' => 'Company Id',
        'csv_Project_Id__c' => 'Project Id',
        'csv_Role_Ids__c' => 'Role Ids',
        'csv_Services__c' => 'Services',
        'csv_User_Id__c' => 'User Id'
    };

    private static final Map<String, Schema.SObjectField> FIELD_MAP = Schema.getGlobalDescribe().get('BIM360_Staging_User__c').getDescribe().fields.getMap();
    private static final List<String> DEFAULT_SERVICES = new List<String>{'projectAdministration', 'documentManagement', 'insight'};

    /*
    [
        {
            "Project Id": "db78e553-41d4-4af7-b67d-8c8100e5c486",
            "Email": "chochon@amazon.com",
            "Service": "documentManagement",
            "Access": "member"
        }
    ]
    */
    @AuraEnabled 
    public static String insertStagingRecords(List<Object> rows) {
        Id bim360JobId = insertBim360Job();

        List<BIM360_Staging_User__c> bim360StaingUsersToInsert = new List<BIM360_Staging_User__c>();

        for (Object row : rows) {
            Map<Object, Object> rowMap = (Map<Object, Object>)row;

            BIM360_Staging_User__c bim360StagingUser = new BIM360_Staging_User__c();
            bim360StagingUser.BIM360_Job__c = bim360JobId;
            bim360StagingUser.BIM360_Staging_User_Status__c = 'Inserted';
            bim360StagingUser.BIM360_Staging_User_Type__c = 'Update';

            for (String columnName : CSV_FIELD_NAME_BY_COLUMN_NAME.keySet()) {
                String fieldName = CSV_FIELD_NAME_BY_COLUMN_NAME.get(columnName);
                String fieldValue = (String)rowMap.get(columnName);
                bim360StagingUser.put(fieldName, fieldValue);
            }

            bim360StaingUsersToInsert.add(bim360StagingUser);
        }

        if (!bim360StaingUsersToInsert.isEmpty()) {
            insert bim360StaingUsersToInsert;
        }

        return bim360JobId;
    }

    // query to check valdiation errors
    // SELECT BIM360_Staging_User_Status__c, Error_Message__c, Email__c FROM BIM360_Staging_User__c
    @AuraEnabled 
    public static List<Object> validateStagingRecords(String jobId) {
        List<Object> validatedRows = new List<Object>();
        
        List<BIM360_Staging_User__c> bim360StagingUsersToValidate = getBim360StaingUsersToValidate(jobId);
        
        for (BIM360_Staging_User__c item : bim360StagingUsersToValidate) {
            // set default values - assume validation will be success. if there is an error the field will get updated
            item.BIM360_Staging_User_Status__c = 'Validation Success';

            if (String.isNotBlank(item.csv_Project_Id__c)) {
                item.Project_Id__c = item.csv_Project_Id__c;
            } else {
                appendErrorMessage(item, 'Project Id is required'); 
            }

            if (String.isNotBlank(item.csv_User_Id__c)) {
                item.User_Id__c = item.csv_User_Id__c;
            } else {
                appendErrorMessage(item, 'User Id is required'); 
            }

            if (String.isNotBlank(item.csv_Services__c) && String.isNotBlank(item.csv_Accesses__c)) {
                List<String> csvServices = item.csv_Services__c.split('\\s*;\\s*');
                List<String> csvAccesses = item.csv_Accesses__c.split('\\s*;\\s*');

                if (csvServices.size() != csvAccesses.size()) {
                    appendErrorMessage(item, 'Service and Access count does not match');
                }

                csvServices.addAll(DEFAULT_SERVICES);
                Set<String> csvServicesSet = new Set<String>(csvServices);
                item.Services__c = String.join(new List<String>(csvServicesSet), ';');

                Set<String> csvAccessesSet = new Set<String>(csvAccesses);
                item.Accesses__c = String.join(new List<String>(csvAccessesSet), ';');
            } else {
                if (String.isBlank(item.csv_Services__c)) {
                    appendErrorMessage(item, 'Service is required');
                }
                
                if (String.isBlank(item.csv_Accesses__c)) {
                    appendErrorMessage(item, 'Access is required');
                }
            }
        }

        List<Database.SaveResult> saveResult = Database.update(bim360StagingUsersToValidate, false);
        Map<BIM360_Staging_User__c, String> validationResultByBim360StagingUser = getValidationResultByBim360StagingUser(saveResult, bim360StagingUsersToValidate);
    
        for (BIM360_Staging_User__c bim360StagingUser : validationResultByBim360StagingUser.keySet()) {
            Map<String, Object> rowMap = new Map<String, Object>();
            rowMap.put('Validation Result', validationResultByBim360StagingUser.get(bim360StagingUser));

            for (String fieldName : COLUMN_NAME_BY_CSV_FIELD_NAME.keySet()) {
                String columnName = COLUMN_NAME_BY_CSV_FIELD_NAME.get(fieldName);
                Object fieldValue = bim360StagingUser.get(fieldName);
                rowMap.put(columnName, fieldValue);
            }

            validatedRows.add(rowMap);
        }

        return validatedRows;
    }

    @AuraEnabled 
    public static String calloutStagingRecords(String jobId) {
        List<BIM360_Staging_User__c> bim360StaingUsersToPost = getBim360StaingUsersToPost(jobId);

        for (BIM360_Staging_User__c item : bim360StaingUsersToPost) {
            item.BIM360_Staging_User_Status__c = 'Callout Initiated';
        }

        update bim360StaingUsersToPost;
        
        return null;
    }

    private static Id insertBim360Job() {
        BIM360_Job__c bim360Job = new BIM360_Job__c();
        insert bim360Job;

        return bim360Job.Id;
    }

    private static List<BIM360_Staging_User__c> getBim360StaingUsersToValidate(String jobId) {
        List<BIM360_Staging_User__c> result = new List<BIM360_Staging_User__c>();

        result = [SELECT csv_Accesses__c,
                         csv_Company_Id__c,
                         csv_Email__c,
                         csv_Project_Id__c,
                         csv_Role_Ids__c,
                         csv_Services__c,
                         csv_User_Id__c,
                         Error_Message__c
                  FROM BIM360_Staging_User__c
                  WHERE BIM360_Job__c = :jobId
                  ORDER BY Name ASC];

        return result;
    }

    private static List<BIM360_Staging_User__c> getBim360StaingUsersToPost(String jobId) {
        List<BIM360_Staging_User__c> result = new List<BIM360_Staging_User__c>();

        result = [SELECT BIM360_Staging_User_Status__c
                  FROM BIM360_Staging_User__c
                  WHERE BIM360_Job__c = :jobId
                  ORDER BY Name ASC];

        return result;
    }

    private static Map<BIM360_Staging_User__c, String> getValidationResultByBim360StagingUser(List<Database.SaveResult> saveResult,
                                                                                          List<BIM360_Staging_User__c> records) {
        Map<BIM360_Staging_User__c, String> result = new Map<BIM360_Staging_User__c, String>();

        for (Integer i = 0; i < saveResult.size(); i++) {
            BIM360_Staging_User__c item = records.get(i);

            if (saveResult.get(i).isSuccess()) {
                if (String.isBlank(item.Error_Message__c)) {
                    result.put(item, null);
                } else {
                    result.put(item, item.Error_Message__c);
                }
            } else {
                Database.Error error = saveResult.get(i).getErrors().get(0);
                String errorStatusCodeAndMessage = error.getStatusCode() + ' : ' + error.getMessage();
                if (String.isBlank(item.Error_Message__c)) {
                    result.put(item, errorStatusCodeAndMessage);
                } else {
                    result.put(item, errorStatusCodeAndMessage + '; ' + item.Error_Message__c);
                }
            }
        }

        return result;
    }

    private static void appendErrorMessage(BIM360_Staging_User__c stg, Exception e) {
        stg.BIM360_Staging_User_Status__c = 'Validation Error';
        stg.Error_Message__c = String.isBlank(stg.Error_Message__c) ? e + '; ' : stg.Error_Message__c + e + '; ';
    }

    private static void appendErrorMessage(BIM360_Staging_User__c stg, String e) {
        stg.BIM360_Staging_User_Status__c = 'Validation Error';
        stg.Error_Message__c = String.isBlank(stg.Error_Message__c) ? e + '; ' : stg.Error_Message__c + e + '; ';
    }
}