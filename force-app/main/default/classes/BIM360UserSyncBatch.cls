// Integer limitNum = 1;    // limit of records we can pull
// Integer offset = 1;      // increments the query offset  
// Integer maxIteration = 1; // max iterations made in one batch
// Integer currentOffSet = 0; // tracks the offset
   
//     String token = CalloutUtility.getToken();

//     // on execute create an API Log?
//     HttpRequest req = new HttpRequest();
//     req.setMethod('GET');
//     req.setHeader('Authorization', 'Bearer ' + token);
//     req.setHeader('Content-Type', 'application/json');

//     Http http = new Http();


//     for(Integer i = 0; i < maxIteration; i++) {

//         req.setEndpoint('https://developer.api.autodesk.com/hq/v1/accounts/'+ CalloutUtility.ACCOUNT_ID + '/users?limit=' + limitNum + '&offset=' + currentOffSet + '&sort=name');
//         HttpResponse res = http.send(req);
    
//          System.debug('>>>> res ' + res);
//          System.debug('>>>> res.getBody() ' + res.getBody());
    

//         currentOffSet += offset;
//     }

// Run batch on demand
// BIM360UserSyncBatch batchable = new BIM360UserSyncBatch();
// Database.executeBatch(batchable,1);

global with sharing class BIM360UserSyncBatch implements Schedulable, Database.Batchable <sObject>, Database.Stateful, Database.AllowsCallouts {

    String query;
    String token;
    Integer limitNum = 100;    // limit of records we can pull
    Integer offset = 100;      // increments the query offset  
    Integer maxIteration = Test.IsRunningTest() ? 1 : 10; // max iterations made in one batch
    Integer currentOffSet = 0; // tracks the offset

    List<User> allUsers = new List<User>();

    global BIM360UserSyncBatch() {    
        allUsers = [SELECT Id FROM User];
    }

    global Iterable<sObject> start(Database.BatchableContext bc) {          
        if (!Test.isRunningTest()) {
            token = CalloutUtility.getToken();
        }  
        return allUsers;
    }

    global void execute(Database.BatchableContext bc, Iterable<sObject> projects) {
        Boolean abortJob = false;
        // on execute create an API Log?
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');

        Http http = new Http();

        List<BIM360_User__c> bim360UsersToUpsert = new List<BIM360_User__c>();

        for(Integer i = 0; i < maxIteration; i++) {
            
            req.setEndpoint('https://developer.api.autodesk.com/hq/v1/accounts/'+ CalloutUtility.ACCOUNT_ID + '/users?limit=' + limitNum + '&offset=' + currentOffSet + '&sort=name');
            
            HttpResponse res = http.send(req);
        
            List<BIM360UserJSON2Apex> apexObjects = BIM360UserJSON2Apex.parse(String.valueOf(res.getBody()));

            for (BIM360UserJSON2Apex bim360userJ2A : apexObjects) {
                bim360UsersToUpsert.add(createBIM360User(bim360userJ2A));
            }
    
            System.debug('>>>> BIM360UserJSON2Apex.size() ' + apexObjects.size());
            if (apexObjects.isEmpty()) {
                // complete execution
                abortJob = true;
                break;
            }
            currentOffSet += offset;
        }

        if (!bim360UsersToUpsert.isEmpty()) {
            Database.upsert(bim360UsersToUpsert, BIM360_User__c.Autodesk_ID__c, true);
        }

        if (abortJob) {
            for(AsyncApexJob job : [SELECT Id FROM AsyncApexJob WHERE (ApexClass.Name LIKE 'BIM360UserSync%') AND Status NOT IN ('Failed', 'Completed','Aborted','Queued')]) {
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

    public BIM360_User__c createBIM360User(BIM360UserJSON2Apex bim360userJ2A) {
        BIM360_User__c  user = new BIM360_User__c ();
        // user.Access_Level_Account_Admin__c = bim360userJ2A.
        // user.Access_Level_Executive__c = bim360userJ2A.
        // user.Access_Level_Project_Admin__c = bim360userJ2A.
        user.Access_Level__c        = bim360userJ2A.access_level;
        user.Address_Line_1__c      = bim360userJ2A.address_line_1;
        user.Address_Line_2__c      = bim360userJ2A.address_line_2;
        user.Autodesk_ID__c         = bim360userJ2A.id;
        user.BIM360_Account_ID__c   = bim360userJ2A.account_id;
        user.City__c                = bim360userJ2A.city;
        user.Country__c             = bim360userJ2A.country;
        user.Created_At__c          = bim360userJ2A.created_at;
        // user.Deactivation_Date__c = bim360userJ2A.
        user.Default_Company_ID__c  = bim360userJ2A.company_id;
        user.Default_Role_ID__c     = bim360userJ2A.default_role_id;
        user.Email__c               = bim360userJ2A.email;
        user.First_Name__c          = bim360userJ2A.first_name;
        user.Job_Title__c           = bim360userJ2A.job_title;
        user.Last_Name__c           = bim360userJ2A.last_name;
        user.Last_Sign_in_Date__c   = bim360userJ2A.last_sign_in == null ? null : (DateTime)JSON.deserialize('"' + bim360userJ2A.last_sign_in + '"', DateTime.class);
        user.Name__c                = bim360userJ2A.name;
        user.Phone_Number__c        = bim360userJ2A.phone;
        user.Postal_Code__c         = bim360userJ2A.postal_code;
        user.State__c               = bim360userJ2A.state_or_province;
        user.Status__c              = bim360userJ2A.status;
        // user.Status_Reason__c = bim360userJ2A.
        user.Updated_At__c          = bim360userJ2A.updated_at;

        return user;
    }

}