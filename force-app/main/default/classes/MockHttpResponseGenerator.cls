@IsTest
public class MockHttpResponseGenerator implements HttpCalloutMock {

    protected Integer statusCode;

    public MockHttpResponseGenerator(Integer statusCode) {
        this.statusCode = statusCode;
    }

    // todo - using the same responseBody for most endpoints. use custom responseBody if needed
    public HttpResponse respond(HttpRequest request) {
        String endpoint = request.getEndpoint().toLowerCase();
        String method = request.getMethod();
        String requestBody = request.getBody();
        String responseBody = '';

        // getProjectRoles
        if (endpoint.contains('/industry_roles') && method == 'GET') {
            if (statusCode == 200) {
                responseBody = '[{"id":"e83a3827-fa9b-41fb-ba3e-7e17981dfb8f","project_id":"b51cfc4c-2e8a-40fd-9e16-8b8069f1e0f9","name":"Amazon India Operations","services":{"project_administration":{"access_level":"no_access"},"document_management":{"access_level":"user"},"insight":{"access_level":"no_access"},"project_management":{"access_level":"no_access"}},"member_group_id":"133635148"},{"id":"8144acd2-3214-45c3-b398-17df520081c9","project_id":"b51cfc4c-2e8a-40fd-9e16-8b8069f1e0f9","name":"Architect","services":{"project_administration":{"access_level":"no_access"},"insight":{"access_level":"no_access"},"document_management":{"access_level":"user"},"project_management":{"access_level":"user"}},"member_group_id":"133362395"},{"id":"a6932244-1b9b-4673-8cfa-886a27e8ae47","project_id":"b51cfc4c-2e8a-40fd-9e16-8b8069f1e0f9","name":"BIM Manager","services":{"project_administration":{"access_level":"admin"},"insight":{"access_level":"admin"},"document_management":{"access_level":"admin"},"project_management":{"access_level":"no_access"}},"member_group_id":"133362400"},{"id":"071f2632-254d-48ee-a7b0-8b7c661836a5","project_id":"b51cfc4c-2e8a-40fd-9e16-8b8069f1e0f9","name":"Construction Manager","services":{"project_administration":{"access_level":"admin"},"insight":{"access_level":"admin"},"document_management":{"access_level":"admin"},"project_management":{"access_level":"admin"}},"member_group_id":"133362390"},{"id":"807bc2de-478e-4a2b-aa58-ff88816120d9","project_id":"b51cfc4c-2e8a-40fd-9e16-8b8069f1e0f9","name":"Developer","services":{"project_administration":{"access_level":"no_access"},"document_management":{"access_level":"user"},"insight":{"access_level":"no_access"},"project_management":{"access_level":"user"}},"member_group_id":"137924344"},{"id":"a0acd942-4de5-4af3-ae59-0c6faebeb4a0","project_id":"b51cfc4c-2e8a-40fd-9e16-8b8069f1e0f9","name":"Document Manager","services":{"project_administration":{"access_level":"admin"},"insight":{"access_level":"admin"},"document_management":{"access_level":"admin"},"project_management":{"access_level":"admin"}},"member_group_id":"133362393"},{"id":"a23d6ea4-ce47-47fd-b620-5557fe8ad602","project_id":"b51cfc4c-2e8a-40fd-9e16-8b8069f1e0f9","name":"Engineer","services":{"project_administration":{"access_level":"no_access"},"insight":{"access_level":"no_access"},"document_management":{"access_level":"user"},"project_management":{"access_level":"user"}},"member_group_id":"133362397"},{"id":"5ca79ace-567e-4fad-ad08-2f2ca6d55505","project_id":"b51cfc4c-2e8a-40fd-9e16-8b8069f1e0f9","name":"Estimator","services":{"project_administration":{"access_level":"no_access"},"insight":{"access_level":"user"},"document_management":{"access_level":"user"},"project_management":{"access_level":"user"}},"member_group_id":"133362396"},{"id":"a0aa33a3-0c3f-4bd8-91f0-fabc68221d51","project_id":"b51cfc4c-2e8a-40fd-9e16-8b8069f1e0f9","name":"Executive","services":{"project_administration":{"access_level":"no_access"},"insight":{"access_level":"user"},"document_management":{"access_level":"no_access"},"project_management":{"access_level":"no_access"}},"member_group_id":"133362389"},{"id":"df3bc330-5888-4960-a0a1-8027891bab34","project_id":"b51cfc4c-2e8a-40fd-9e16-8b8069f1e0f9","name":"Foreman","services":{"project_administration":{"access_level":"no_access"},"insight":{"access_level":"no_access"},"document_management":{"access_level":"user"},"project_management":{"access_level":"user"}},"member_group_id":"133362399"},{"id":"3fb41d09-0c3a-4cb9-bfad-0f046bf0126a","project_id":"b51cfc4c-2e8a-40fd-9e16-8b8069f1e0f9","name":"IT","services":{"project_administration":{"access_level":"admin"},"insight":{"access_level":"no_access"},"document_management":{"access_level":"no_access"},"project_management":{"access_level":"no_access"}},"member_group_id":"133362392"},{"id":"49de24fd-5684-46ce-82bd-0fdbeaf1e647","project_id":"b51cfc4c-2e8a-40fd-9e16-8b8069f1e0f9","name":"Project Engineer","services":{"project_administration":{"access_level":"admin"},"insight":{"access_level":"admin"},"document_management":{"access_level":"admin"},"project_management":{"access_level":"admin"}},"member_group_id":"133362394"},{"id":"1eda6fab-920b-4de7-9cd4-78c5eaad6be8","project_id":"b51cfc4c-2e8a-40fd-9e16-8b8069f1e0f9","name":"Project Manager","services":{"project_administration":{"access_level":"admin"},"insight":{"access_level":"admin"},"document_management":{"access_level":"admin"},"project_management":{"access_level":"admin"}},"member_group_id":"133362386"},{"id":"5d93a78d-039f-4538-8c82-aafe1286204f","project_id":"b51cfc4c-2e8a-40fd-9e16-8b8069f1e0f9","name":"Superintendent","services":{"project_administration":{"access_level":"admin"},"insight":{"access_level":"admin"},"document_management":{"access_level":"admin"},"project_management":{"access_level":"admin"}},"member_group_id":"133362388"},{"id":"e8158abe-3241-429e-84f4-fa4f51b8db2c","project_id":"b51cfc4c-2e8a-40fd-9e16-8b8069f1e0f9","name":"Test","services":{"project_administration":{"access_level":"no_access"},"document_management":{"access_level":"user"},"insight":{"access_level":"no_access"},"project_management":{"access_level":"no_access"}},"member_group_id":"133362387"},{"id":"a82dbe54-edad-4041-b872-2345df410714","project_id":"b51cfc4c-2e8a-40fd-9e16-8b8069f1e0f9","name":"Test2","services":{"project_administration":{"access_level":"no_access"},"document_management":{"access_level":"user"},"insight":{"access_level":"no_access"},"project_management":{"access_level":"no_access"}},"member_group_id":"133362391"},{"id":"c66d4d75-27ae-4e53-9363-aa2b9e69d9d2","project_id":"b51cfc4c-2e8a-40fd-9e16-8b8069f1e0f9","name":"VDC Manager","services":{"project_administration":{"access_level":"admin"},"insight":{"access_level":"admin"},"document_management":{"access_level":"admin"},"project_management":{"access_level":"no_access"}},"member_group_id":"133362398"}]';
            } else {
                responseBody = '{"code":1004,"message":"this project doesn\'t exist."}';
            }
        } 
        // getUserSearch
        else if (endpoint.contains('/users/search') && method == 'GET') {
            responseBody = '[{"id":"cf86be2b-fd73-45c6-ac9d-59bcc9ee7c99","email":"sesakuma@amazon.com","name":"Sean Sakuma","nickname":"sesakuma","first_name":"Sean","last_name":"Sakuma","uid":"ADCKKJ2J8WJM","image_url":"https://images.profile.autodesk.com/default/user_X50.png","address_line_1":"","address_line_2":"","city":"","postal_code":"96740","state_or_province":"","country":"United States","phone":null,"company":"Amazon","job_title":"System Admin","industry":"","about_me":"","created_at":"2020-10-29T16:07:12.379Z","updated_at":"2022-01-22T00:22:23.097Z","account_id":"f925a3ca-05dd-41f7-b7ae-abbdb2fbc695","role":"account_admin","status":"active","company_id":"57b4957f-e5fa-4c43-9501-2861fd4a3bfe","company_name":"Amazon Test","last_sign_in":"2022-01-22T00:22:31.000Z","default_role":null,"default_role_id":null,"access_level":"account_admin"}]';
        } 
        // getUser
        else if (endpoint.contains('/users') && !endpoint.contains('/search') && method == 'GET') {
            responseBody = '{"status":"success"}';
        }
        // patchUserToActive
        // patchUserCompanyName
        else if (endpoint.contains('/users') && method == 'PATCH') {
            responseBody = '{"status":"success"}';
        }  
        // getCompanyNameSearch
        else if (endpoint.contains('/companies/search') && method == 'GET') {
            responseBody = '[{"id":"438143e6-ad7d-45bf-8beb-cc7a1008d5f0","account_id":"f925a3ca-05dd-41f7-b7ae-abbdb2fbc695","name":"FTS","trade":"Architecture","address_line_1":"","address_line_2":"","city":"","postal_code":"","state_or_province":"","country":"United States","phone":"","website_url":"","description":"","created_at":"2021-12-21T22:28:26.088Z","updated_at":"2022-01-18T08:10:32.534Z","erp_id":"","tax_id":""}]';
        } 
        // postUser
        else if (endpoint.contains('/users') && !endpoint.contains('/import') && method == 'POST') {
            responseBody = '{"account_id":"f925a3ca-05dd-41f7-b7ae-abbdb2fbc695","role":"account_user","status":"not_invited","company_id":null,"company_name":null,"last_sign_in":null,"default_role":null,"default_role_id":null,"access_level":"account_user","id":"1400f6ff-95f2-46c9-8f03-41f4a5a42734","email":"kevin3@fiduciarytech.com","name":"kevin3 yoon","nickname":"","first_name":"kevin3","last_name":"yoon","uid":null,"image_url":"","address_line_1":"","address_line_2":"","city":"","postal_code":"","state_or_province":"","country":"United States","phone":null,"company":"Amazon","job_title":"","industry":"","about_me":"","created_at":"2022-02-10T11:54:30.266Z","updated_at":"2022-02-10T11:54:30.266Z"}';
        } 
        // postUserToProject
        else if (endpoint.contains('/users/import') && method == 'POST') {
            responseBody = '{"failure":0,"success":1,"success_items":[{"services":{"document_management":{"access_level":"user"}},"industry_roles":["8144acd2-3214-45c3-b398-17df520081c9"],"email":"mendrodn@amazon.lu","first_name":"Mendonca","last_name":"Rodney","user_id":"6d69c76a-e31f-4ed3-b27b-6e6f7f77d0aa","project_id":"b51cfc4c-2e8a-40fd-9e16-8b8069f1e0f9","account_id":"f925a3ca-05dd-41f7-b7ae-abbdb2fbc695"}],"failure_items":[]}';
        } 
        // getAmazonUserInfo
        else if (endpoint.contains('/recipient') && method == 'POST') {
            if (statusCode == 200) {
                responseBody = '{"user_alias": "user", "user_eid": "921955", "user_employee_name": "Test User", "user_email": "user@test.com", "user_preferred_email": true, "user_cost_center_id": "1234", "user_cost_center_name": "User Cost Center", "user_job_level": 6, "user_company_code": "2D", "user_location_code": "6037", "user_cost_center_override_curr": "1234", "immediate_manager_alias": "manager", "manger_eid": "123456", "immediate_manager_name": "Test Manager", "immediate_manager_cost_center_id": "manager@test.com", "immediate_manager_preferred_email": true, "immediate_manager_cost_center_id": "1234", "immediate_manager_cost_center_name": "Test Cost Center", "immediate_manager_job_level": 7, "immediate_manager_company_code": "2D", "immediate_manager_location_code": "2345", "immediate_manager_cost_center_override_curr": "1234", "approver_alias": "approver", "approver_eid": "010796", "approver_name": "Approver User", "approver_email": "approver@test.com", "approver_cost_center_id": "1234", "approver_cost_center_name": "Approver Cost Center", "approver_job_level": 8, "approver_preferred_email": true, "approver_company_code": "2D", "approver_location_code": "6037", "approver_cost_center_override_curr": "1234", "email_domain_type": "AMZ"}';
            } else {
                responseBody = 'no result';
            }
        } 
        // gets all projects
        else if (endpoint.contains('/projects')) {
            responseBody = '[{\"id\":\"44776f84-cc67-46a5-bc2f-9ca9e633ce01\",\"account_id\":\"f925a3ca-05dd-41f7-b7ae-abbdb2fbc695\",\"name\":\"00_FTS_Test_3\",\"start_date\":null,\"end_date\":null,\"value\":null,\"currency\":\"USD\",\"status\":\"active\",\"job_number\":\"\",\"address_line_1\":\"\",\"address_line_2\":\"\",\"city\":\"\",\"state_or_province\":\"\",\"postal_code\":\"\",\"country\":\"United States\",\"business_unit_id\":null,\"created_at\":\"2021-12-22T01:17:29.457Z\",\"updated_at\":\"2022-09-06T02:29:02.922Z\",\"project_type\":\"Convention Center\",\"timezone\":\"America/New_York\",\"language\":\"en\",\"construction_type\":null,\"contract_type\":null,\"last_sign_in\":\"2022-04-14T06:45:25.237Z\"}]';
        } 


        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json; charset=utf-8');
        response.setStatusCode(this.statusCode);
        response.setBody(responseBody);

        return response;
    }
}