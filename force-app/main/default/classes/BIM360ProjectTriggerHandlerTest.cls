@isTest
private class BIM360ProjectTriggerHandlerTest {

    @isTest
    static void testBIM360ProjectTriggerHandler() {
		String json = '[{\"id\":\"44776f84-cc67-46a5-bc2f-9ca9e633ce01\",\"account_id\":\"f925a3ca-05dd-41f7-b7ae-abbdb2fbc695\",\"name\":\"00_FTS_Test_3\",\"start_date\":null,\"end_date\":null,\"value\":null,\"currency\":\"USD\",\"status\":\"active\",\"job_number\":\"\",\"address_line_1\":\"\",\"address_line_2\":\"\",\"city\":\"\",\"state_or_province\":\"\",\"postal_code\":\"\",\"country\":\"United States\",\"business_unit_id\":null,\"created_at\":\"2021-12-22T01:17:29.457Z\",\"updated_at\":\"2022-09-06T02:29:02.922Z\",\"project_type\":\"Convention Center\",\"timezone\":\"America/New_York\",\"language\":\"en\",\"construction_type\":null,\"contract_type\":null,\"last_sign_in\":\"2022-04-14T06:45:25.237Z\"}]';
        List<JSON2Apex> apexObjects = JSON2Apex.parse(json);

        List<BIM360_Project__c> bim360ProjectsToUpsert = new List<BIM360_Project__c>();
        BIM360ProjectSyncBatch b = new BIM360ProjectSyncBatch();
        for (JSON2Apex ja : apexObjects) {
            bim360ProjectsToUpsert.add(b.createBIM360Project(ja));
        }

        if (!bim360ProjectsToUpsert.isEmpty()) {
            Database.upsert(bim360ProjectsToUpsert, BIM360_Project__c.Project_Id__c, true);
        }
        // changed name and status
        bim360ProjectsToUpsert[0].Name = '00 FTS Test 3A';
        bim360ProjectsToUpsert[0].Status__c = 'inactive';
        update bim360ProjectsToUpsert[0];

        // no change on name/status
        bim360ProjectsToUpsert[0].Business_Unit_ID__c = 'GES';
        update bim360ProjectsToUpsert[0];
    }

}