public with sharing class BIM360ProjectTriggerHandler {
    
    public static void onAfterInsert(List<BIM360_Project__c> newList, Map<Id, BIM360_Project__c> newMap) {
        upsertBCBIMProject(newList, null);
    }

    public static void onAfterUpdate(List<BIM360_Project__c> newList, Map<Id, BIM360_Project__c> oldMap) { 
        upsertBCBIMProject(newList, oldMap);
    }

    public static void onBeforeInsert(List<BIM360_Project__c> newList) { }

    public static void onBeforeUpdate(List<BIM360_Project__c> newList, Map<Id, BIM360_Project__c> oldMap) { }

    public static void upsertBCBIMProject(List<BIM360_Project__c> newList, Map<Id, BIM360_Project__c> oldMap) {
        // upsert on BC_BIM_Project__c.AD_ID__c
        List<BC_BIM_Project__c> projectsToUpsert = new List<BC_BIM_Project__c>();

        for (BIM360_Project__c bim360Project : newList) {

            // this is on update of BIM360 Projects
            if (oldMap != null) {
                // check if name or status changed, if not, then skip any updates on the BC_BIM_Project__c record
                BIM360_Project__c bim360ProjectPreviousValues = oldMap.get(bim360Project.Id);
                if (bim360Project.Name      == bim360ProjectPreviousValues.Name &&
                    bim360Project.Status__c == bim360ProjectPreviousValues.Status__c) {
                    continue;
                }
            }

            // stores name since its used often 
            String bim360ProjectName = bim360Project.Name;
            // create BC_BIM_Project__c to upsert
            BC_BIM_Project__c sfProject = new BC_BIM_Project__c();
            sfProject.Project_Name__c   = bim360ProjectName;
            sfProject.AD_ID__c          = bim360Project.Project_Id__c;
            
            // status can be Active, Inactive, or Archived; only set Active__c to true when value is 'Active'
            if (bim360Project.Status__c == 'active') {
                sfProject.Active__c = true;
            } else {
                sfProject.Active__c = false;
            }

            // determines the project type and facility name based on the project name
            if (bim360ProjectName.contains('_') && !bim360ProjectName.containsIgnoreCase('template')) {
                sfProject.Project_Type__c = 'Site-Specific';
                sfProject.Facility_Name__c = bim360ProjectName.right(4); // needs to be more robust to get the correct Facility Name, not really used and may remove later.
            } else {
                sfProject.Project_Type__c = 'Template';
            }

            // upsert the project records to the BC_BIM_Project__c
            projectsToUpsert.add(sfProject);
        }

        Database.upsert(projectsToUpsert, BC_BIM_Project__c.AD_ID__c, false);
        
    }

}