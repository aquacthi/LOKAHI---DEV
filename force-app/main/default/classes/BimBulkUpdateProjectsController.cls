public with sharing class BimBulkUpdateProjectsController {

    // Used to convert json property names (csv column headers) to sobject fields
    private static final Map<String, String> CSV_FIELD_NAME_BY_COLUMN_NAME = new Map<String, String>{
        'Address Line 1' => 'csv_Address_Line_1__c',
        'Address Line 2' => 'csv_Address_Line_2__c',
        'City' => 'csv_City__c',
        'Construction Type' => 'csv_Construction_Type__c',
        'Contract Type' => 'csv_Contract_Type__c',
        'Country' => 'csv_Country__c',
        'End Date' => 'csv_End_Date__c',
        'Include Companies' => 'csv_Include_Companies__c',
        'Include Locations' => 'csv_Include_Locations__c',
        'Job Number' => 'csv_Job_Number__c',
        'Project Id' => 'csv_Project_Id__c',
        'Project Name' => 'csv_Project_Name__c',
        'Postal Code' => 'csv_Postal_Code__c',
        'Project Currency' => 'csv_Project_Currency__c',
        'Project Type' => 'csv_Project_Type__c',
        'Project Value' => 'csv_Project_Value__c',
        'Row Number' => 'csv_Row_Number__c',
        'Services' => 'csv_Services__c',
        'Start Date' => 'csv_Start_Date__c',
        'State' => 'csv_State_Province__c',
        'Template Project Id' => 'csv_Template_Project_Id__c',
        'Time Zone' => 'csv_Time_Zone__c'
    };

    // Used to convert sobject fields to json property names(csv column headers)
    private static final Map<String, String> COLUMN_NAME_BY_CSV_FIELD_NAME = new Map<String, String>{
        'csv_Address_Line_1__c' => 'Address Line 1',
        'csv_Address_Line_2__c' => 'Address Line 2',
        'csv_City__c' => 'City',
        'csv_Construction_Type__c' => 'Construction Type',
        'csv_Contract_Type__c' => 'Contract Type',
        'csv_Country__c' => 'Country',
        'csv_End_Date__c' => 'End Date',
        'csv_Job_Number__c' => 'Job Number',
        'csv_Project_Id__c' => 'Project Id',
        'csv_Project_Name__c' => 'Project Name',
        'csv_Postal_Code__c' => 'Postal Code',
        'csv_Project_Currency__c' => 'Project Currency',
        'csv_Project_Type__c' => 'Project Type',
        'csv_Project_Value__c' => 'Project Value',
        'csv_Row_Number__c' => 'Row Number',
        'csv_Services__c' => 'Services',
        'csv_Start_Date__c' => 'Start Date',
        'csv_State_Province__c' => 'State',
        'csv_Template_Project_Id__c' => 'Template Project Id',
        'csv_Time_Zone__c' => 'Time Zone'
    };

    private static final Map<String, Schema.SObjectField> FIELD_MAP = Schema.getGlobalDescribe().get('BIM360_Staging_Project__c').getDescribe().fields.getMap();
    private static final List<String> DEFAULT_SERVICES = new List<String>{'projectAdministration', 'documentManagement', 'insight'};

    /*
    [
        {
            "Project Id": "Tae Test 1",
            "Project Name": "Tae Test 1",
            "Services": "test",
            "Start Date": "test",
            "End Date": "2020-09-19",
            "Project Type": "Data Center",
            "Project Value": "970000",
            "Currency": "USD",
            "Job Number": "IF001",
            "Address Line 1": "123 Test Street",
            "Address Line 2": "",
            "City": "Seattle",
            "State": "Washington",
            "Postal Code": "99999",
            "Country": "United States",
            "Time Zone": "America/Los_Angeles",
            "Construction Type": "New Construction",
            "Contract Type": "",
            "Tempate Project Id": "",
            "Row Number": 1
        }
    ]
    */
    @AuraEnabled 
    public static String insertStagingRecords(List<Object> rows) {
        Id bim360JobId = insertBim360Job();

        List<BIM360_Staging_Project__c> bim360StaingProjectsToInsert = new List<BIM360_Staging_Project__c>();

        for (Object row : rows) {
            Map<Object, Object> rowMap = (Map<Object, Object>)row;

            BIM360_Staging_Project__c bim360StagingProject = new BIM360_Staging_Project__c();
            bim360StagingProject.BIM360_Job__c = bim360JobId;
            bim360StagingProject.BIM360_Staging_Project_Status__c = 'Inserted';
            bim360StagingProject.BIM360_Staging_Project_Type__c = 'Update';

            for (String columnName : CSV_FIELD_NAME_BY_COLUMN_NAME.keySet()) {
                String fieldName = CSV_FIELD_NAME_BY_COLUMN_NAME.get(columnName);
                String fieldValue = (String)rowMap.get(columnName);
                bim360StagingProject.put(fieldName, fieldValue);
            }

            bim360StaingProjectsToInsert.add(bim360StagingProject);
        }

        if (!bim360StaingProjectsToInsert.isEmpty()) {
            insert bim360StaingProjectsToInsert;
        }

        return bim360JobId;
    }

    // query to check valdiation errors
    // SELECT BIM360_Staging_Project_Status__c, Error_Message__c, Start_Date__c, End_Date__c, Project_Value__c FROM BIM360_Staging_Project__c
    @AuraEnabled 
    public static List<Object> validateStagingRecords(String jobId) {
        List<Object> validatedRows = new List<Object>();
        
        List<BIM360_Staging_Project__c> bim360StagingProjectsToValidate = getBim360StaingProjectsToValidate(jobId);
        
        for (BIM360_Staging_Project__c item : bim360StagingProjectsToValidate) {
            // set default values - assume validation will be success. if there is an error the field will get updated
            item.BIM360_Staging_Project_Status__c = 'Validation Success';

            item.Address_Line_1__c = item.csv_Address_Line_1__c;
            item.Address_Line_2__c = item.csv_Address_Line_2__c;
            item.City__c = item.csv_City__c;
            item.Construction_Type__c = item.csv_Construction_Type__c;
            item.Contract_Type__c = item.csv_Contract_Type__c;
            item.Country__c = item.csv_Country__c;
            item.Job_Number__c = item.csv_Job_Number__c;
            item.Postal_Code__c = item.csv_Postal_Code__c;
            item.Project_Currency__c = item.csv_Project_Currency__c;
            item.Project_Name__c = item.csv_Project_Name__c;
            item.Project_Type__c = item.csv_Project_Type__c;
            item.State_Province__c = item.csv_State_Province__c;
            item.Template_Project_Id__c = item.csv_Template_Project_Id__c;
            item.Time_Zone__c = item.csv_Time_Zone__c;

            if (String.isNotBlank(item.csv_Project_Id__c)) {
                item.Project_Id__c = item.csv_Project_Id__c;
            } else {
                appendErrorMessage(item, 'Project Id is required');
            }

            // set converted values
            try {
                item.Start_Date__c = Date.parse(item.csv_Start_Date__c);
            } catch(Exception exc) {
                try {
                    item.Start_Date__c = Date.valueOf(item.csv_Start_Date__c);
                } catch(Exception e) {
                    appendErrorMessage(item, e); 
                }
            }
            
            try {
                item.End_Date__c = Date.parse(item.csv_End_Date__c);
            } catch(Exception exc) {
                try {
                    item.End_Date__c = Date.valueOf(item.csv_End_Date__c);
                } catch(Exception e) {
                    appendErrorMessage(item, e); 
                }
            }
            
            try {
                item.Project_Value__c = Integer.valueOf(item.csv_Project_Value__c);
            } catch(Exception e) {
                appendErrorMessage(item, e); 
            }


            // custom error message Include_Companies__c and csv_Include_Locations__c 
            // Boolean.valueOf returns true for 'true' otherwise always false which we don't want
            // e.g. if the value of csv_Include_Companies__c = 'hello' then Boolean.valueOf returns false
            if (String.isBlank(item.csv_Include_Companies__c) ||
                item.csv_Include_Companies__c == 'true' || 
                item.csv_Include_Companies__c == 'false') {
                item.Include_Companies__c = Boolean.valueOf(item.csv_Include_Companies__c == null ? '' : item.csv_Include_Companies__c);
            } else {
                appendErrorMessage(item, 'System.TypeException: Invalid boolean: ' + item.csv_Include_Companies__c); 
            }

            if (String.isBlank(item.csv_Include_Locations__c) || 
                item.csv_Include_Locations__c == 'true' || 
                item.csv_Include_Locations__c == 'false') {
                item.Include_Locations__c = Boolean.valueOf(item.csv_Include_Locations__c == null ? '' : item.csv_Include_Locations__c);
            } else {
                appendErrorMessage(item, 'System.TypeException: Invalid boolean: ' + item.csv_Include_Locations__c); 
            }

            if (String.isNotBlank(item.csv_Services__c)) {
                List<String> csvServices = item.csv_Services__c.split('\\s*;\\s*');
                csvServices.addAll(DEFAULT_SERVICES);
                Set<String> csvServicesSet = new Set<String>(csvServices);
                item.Services__c = String.join(new List<String>(csvServicesSet), ';');
            }
        }

        List<Database.SaveResult> saveResult = Database.update(bim360StagingProjectsToValidate, false);
        Map<BIM360_Staging_Project__c, String> validationResultByBim360StagingProject = getValidationResultByBim360StagingProject(saveResult, bim360StagingProjectsToValidate);
    
        for (BIM360_Staging_Project__c bim360StagingProject : validationResultByBim360StagingProject.keySet()) {
            Map<String, Object> rowMap = new Map<String, Object>();
            rowMap.put('Validation Result', validationResultByBim360StagingProject.get(bim360StagingProject));

            for (String fieldName : COLUMN_NAME_BY_CSV_FIELD_NAME.keySet()) {
                String columnName = COLUMN_NAME_BY_CSV_FIELD_NAME.get(fieldName);
                Object fieldValue = bim360StagingProject.get(fieldName);
                rowMap.put(columnName, fieldValue);
            }

            validatedRows.add(rowMap);
        }

        return validatedRows;
    }

    @AuraEnabled 
    public static String calloutStagingRecords(String jobId) {
        List<BIM360_Staging_Project__c> bim360StaingProjectsToPatch = getBim360StaingProjectsToPatch(jobId);

        for (BIM360_Staging_Project__c item : bim360StaingProjectsToPatch) {
            item.BIM360_Staging_Project_Status__c = 'Callout Initiated';
        }

        update bim360StaingProjectsToPatch;
        
        return null;
    }

    private static Id insertBim360Job() {
        BIM360_Job__c bim360Job = new BIM360_Job__c();
        insert bim360Job;

        return bim360Job.Id;
    }

    private static List<BIM360_Staging_Project__c> getBim360StaingProjectsToValidate(String jobId) {
        List<BIM360_Staging_Project__c> result = new List<BIM360_Staging_Project__c>();

        result = [SELECT csv_Address_Line_1__c,
                         csv_Address_Line_2__c,
                         csv_City__c,
                         csv_Construction_Type__c,
                         csv_Contract_Type__c,
                         csv_Country__c,
                         csv_End_Date__c,
                         csv_Job_Number__c,
                         csv_Include_Companies__c,
                         csv_Include_Locations__c,
                         csv_Postal_Code__c,
                         csv_Project_Currency__c,
                         csv_Project_Id__c,
                         csv_Project_Name__c,
                         csv_Project_Type__c,
                         csv_Project_Value__c,
                         csv_Row_Number__c,
                         csv_Services__c,
                         csv_Start_Date__c,
                         csv_State_Province__c,
                         csv_Template_Project_Id__c,
                         csv_Time_Zone__c,
                         Error_Message__c
                  FROM BIM360_Staging_Project__c
                  WHERE BIM360_Job__c = :jobId
                  ORDER BY Name ASC];

        return result;
    }

    private static List<BIM360_Staging_Project__c> getBim360StaingProjectsToPatch(String jobId) {
        List<BIM360_Staging_Project__c> result = new List<BIM360_Staging_Project__c>();

        result = [SELECT BIM360_Staging_Project_Status__c
                  FROM BIM360_Staging_Project__c
                  WHERE BIM360_Job__c = :jobId
                  ORDER BY Name ASC];

        return result;
    }

    private static Map<BIM360_Staging_Project__c, String> getValidationResultByBim360StagingProject(List<Database.SaveResult> saveResult,
                                                                                          List<BIM360_Staging_Project__c> records) {
        Map<BIM360_Staging_Project__c, String> result = new Map<BIM360_Staging_Project__c, String>();

        for (Integer i = 0; i < saveResult.size(); i++) {
            BIM360_Staging_Project__c item = records.get(i);

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

    private static void appendErrorMessage(BIM360_Staging_Project__c stg, Exception e) {
        stg.BIM360_Staging_Project_Status__c = 'Validation Error';
        stg.Error_Message__c = String.isBlank(stg.Error_Message__c) ? e + '; ' : stg.Error_Message__c + e + '; ';
    }

    private static void appendErrorMessage(BIM360_Staging_Project__c stg, String e) {
        stg.BIM360_Staging_Project_Status__c = 'Validation Error';
        stg.Error_Message__c = String.isBlank(stg.Error_Message__c) ? e + '; ' : stg.Error_Message__c + e + '; ';
    }
}