global with sharing class BIM360ProjectSyncBatch implements Schedulable, Database.Batchable <sObject>, Database.Stateful, Database.AllowsCallouts {

    String query;
    String token;
    Integer limitNum = 100;    // limit of records we can pull
    Integer offset = 100;      // increments the query offset  
    Integer maxIteration = Test.IsRunningTest() ? 1 : 10; // max iterations made in one batch
    Integer currentOffSet = 0; // tracks the offset

    List<BC_BIM_Project__c> allProjects = new List<BC_BIM_Project__c>();

    global BIM360ProjectSyncBatch() {    
        allProjects = [SELECT Id FROM BC_BIM_Project__c];
    }

    global Iterable<sObject> start(Database.BatchableContext bc) {          
        if (!Test.isRunningTest()) {
            token = CalloutUtility.getToken();
        }  
        return allProjects;
    }

    global void execute(Database.BatchableContext bc, Iterable<sObject> projects) {
        Boolean abortJob = false;
        // on execute create an API Log?
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');

        Http http = new Http();

        List<BIM360_Project__c> bim360ProjectsToUpsert = new List<BIM360_Project__c>();

        for(Integer i = 0; i < maxIteration; i++) {
            
            req.setEndpoint('https://developer.api.autodesk.com/hq/v1/accounts/'+ CalloutUtility.ACCOUNT_ID + '/projects?limit=' + limitNum + '&offset=' + currentOffSet + '&sort=name');
            
            HttpResponse res = http.send(req);
        
            List<JSON2Apex> apexObjects = JSON2Apex.parse(String.valueOf(res.getBody()));

            for (JSON2Apex ja : apexObjects) {
                bim360ProjectsToUpsert.add(createBIM360Project(ja));
            }
    
            System.debug('>>>> json2apex.size() ' + apexObjects.size());
            if (apexObjects.isEmpty()) {
                // complete execution
                abortJob = true;
                break;
            }
            currentOffSet += offset;
        }

        if (!bim360ProjectsToUpsert.isEmpty()) {
            Database.upsert(bim360ProjectsToUpsert, BIM360_Project__c.Project_Id__c, true);
        }

        if (abortJob) {
            for(AsyncApexJob job : [SELECT Id FROM AsyncApexJob WHERE (ApexClass.Name LIKE 'BIM360ProjectSync%') AND Status NOT IN ('Failed', 'Completed','Aborted','Queued')]) {
                System.abortJob(job.Id);
            }
        }
    }

    global void finish(Database.BatchableContext bc) {

    }    

    global void execute(SchedulableContext sc) {
        BIM360ProjectSyncBatch b = new BIM360ProjectSyncBatch();
        Database.executeBatch(b);
    }

    public BIM360_Project__c createBIM360Project(JSON2Apex ja) {
        BIM360_Project__c  project = new BIM360_Project__c ();
        project.Project_Id__c           = ja.id;        
        project.Account_Id__c           = ja.account_id;      
        project.Name                    = ja.name;  
        project.Start_Date__c           = ja.start_date;        
        project.End_Date__c             = ja.end_date;    
        // project.Type__c // TODO - delete this field
        project.Status__c               = ja.status;    
        project.Value__c                = String.valueOf(ja.value);
        project.Currency__c             = ja.currency_Z;    
        project.Job_Number__c           = ja.job_number;        
        project.Address_Line_1__c       = ja.address_line_1;            
        project.Address_Line_2__c       = ja.address_line_2;            
        project.City__c                 = ja.city;
        project.State_Or_Province__c    = ja.state_or_province;                
        project.Postal_Code__c          = ja.postal_code;        
        project.Country__c              = ja.country;    
        project.Business_Unit_ID__c     = String.valueOf(ja.business_unit_id);            
        project.Created_At__c           = ja.created_at;        
        project.Updated_At__c           = ja.updated_at;        
        project.Project_Type__c         = ja.project_type;        
        project.Language__c             = ja.language;    
        project.Construction_Type__c    = ja.construction_type;                
        project.Contract_Type__c        = ja.contract_type;            
        project.Last_Sign_In__c         = ja.last_sign_in;
        return project;
    }

}