public without sharing class BIMNewRequestForm {
    
    public static final String DUPLICATE_ERROR = 'This has been identified as a duplicate request; record was not saved';
    
    @AuraEnabled
    public static String createRequest(BC_Request__c objRecquest) {
        system.debug('objRecquest===='+objRecquest);
        String result = '';

        try{
            insert objRecquest;
            result = 'success';
        } catch (DMLException objException){
            String errorMsg = '';
            Integer numDMLErrors = objException.getNumDml();
            for (Integer i = 0; i < numDMLErrors; i++) {
                // Process exception here
                errorMsg += objException.getDmlMessage(i);
                if (numDMLErrors != i) {
                    errorMsg += '\n';
                } 
            }
            throw new AuraHandledException(errorMsg); 
            
        }
        return result;
    }

    @AuraEnabled
    public static String createRequestForMultipleProjects(BC_Request__c objRecquest, List<Map<String, Object>> projects, List<Map<String, Object>> newProjects) {
        system.debug('objRecquest ==== ' + objRecquest);
        system.debug('projects ==== ' + projects);
        system.debug('newProjects ==== ' + newProjects);
        String result = '';

        try{
            // create request
            insert objRecquest;

            List<Request_Project__c> requestProjectsToCreate = new List<Request_Project__c>();
            // create request project records
            for (Map<String, Object> project : projects) {
                Request_Project__c requestProject = new Request_Project__c();
                requestProject.Request__c = objRecquest.Id;
                requestProject.Project_Record_Name__c = String.valueOf(project.get('value'));
                // add more fields...

                requestProjectsToCreate.add(requestProject);
            }
            
            for (Map<String, Object> newProject : newProjects) {
                Request_Project__c requestProject = new Request_Project__c();                
                requestProject.Request__c = objRecquest.Id;
                requestProject.Project_Name_Entered__c = String.valueOf(newProject.get('value'));
                // add more fields...

                requestProjectsToCreate.add(requestProject);
            }
            insert requestProjectsToCreate;

            result = 'success';
        } catch (DMLException objException){
            String errorMsg = '';
            Integer numDMLErrors = objException.getNumDml();
            for (Integer i = 0; i < numDMLErrors; i++) {
                // Process exception here
                errorMsg += objException.getDmlMessage(i);
                if (numDMLErrors != i) {
                    errorMsg += '\n';
                } 
            }
            if (errorMsg.contains(DUPLICATE_ERROR)) {
                errorMsg = DUPLICATE_ERROR;
            } 
            throw new AuraHandledException(errorMsg);             
        }
        return result;
    }

    @AuraEnabled (cacheable=true)
    public static List<BC_BIM_Project__c> getBIMProjects(){
        return [
            SELECT Id,Name,Facility_Name__c 
            FROM BC_BIM_Project__c 
            WHERE Project_Type__c = 'Site-Specific' 
            AND Facility_Name__c != null
            AND Active__c = true
            ORDER BY Facility_Name__c ASC
        ];
    }
    
    @AuraEnabled (cacheable=true)
    public static List<BC_BIM_Project__c> getBIMTemplateProjects(){
        return [
            SELECT Id,Name,Project_Name__c 
            FROM BC_BIM_Project__c 
            WHERE Project_Type__c = 'Template'
            AND Project_Name__c != null
            AND Active__c = true
            ORDER BY Project_Name__c ASC
        ];
    }    
}