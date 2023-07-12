@IsTest
private with sharing class MultiSelectLookupControllerTest {
    @TestSetup
    static void setup() {
        
    }
    @isTest
    static void test_RetrieveRecords() {
        BC_BIM_Project__c proj = new BC_BIM_Project__c();
        proj.Project_Name__c = 'TEST PROJECT';
        proj.Facility_Name__c = 'TSP';
        insert proj;

        MultiSelectLookupController.retrieveRecords('BC_BIM_Project__c',
                                                    'Id,Project_Name__c',
                                                    'Project_Name__c',
                                                    'TEST',
                                                    'Site-Specific');
    }

}