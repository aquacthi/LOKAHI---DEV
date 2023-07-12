public without sharing class CalloutUtility {
    public static final Integer SUCCESS_CODE = 200;
    public static final Autodesk_Setting__c AUTODESK_BIM360 = Autodesk_Setting__c.getOrgDefaults();
    public static final String ACCOUNT_ID    = AUTODESK_BIM360.Account_Id__c;
    public static final String COMPANY_ID    = AUTODESK_BIM360.Company_Id__c;
    public static final String X_USER_ID     = AUTODESK_BIM360.X_User_Id__c;
    public static final String CLIENT_ID     = AUTODESK_BIM360.App_Id__c;
    public static final String CLIENT_SECRET = AUTODESK_BIM360.App_Secret__c;

    class LogHttp {
        void send(HttpRequest req, API_Log__c apiLog)
        {
            apiLog.Request_Body__c = req.getBody();
            
            // to avoid read timed out error
            req.setTimeout(120000);

            Http http = new Http();
            HttpResponse res = http.send(req);
            apiLog.Response_Status_Code__c = res.getStatusCode();
            apiLog.Response_Status__c = res.getStatus();

            // response is larger than field limit of 131,072 characters, store into an attachment
            if (apilog.Method_Name__c == 'getProjectRoles') {

                String bim360Role = (String)apiLog.BC_Request__r.get('BIM_360_Role__c');

                List<Object> resultList = (List< Object>)JSON.deserializeUntyped(res.getBody());
                for (Object obj : resultList) {
                    Map<String, Object> objByField = (Map<String, Object>)obj;
        
                    String roleName = (String)objByField.get('name');
                    if (bim360Role == roleName) {
                        System.debug('## objByField : ' + objByField);
                        apiLog.Response_Body__c = (String)JSON.serialize(objByField);
                        break;
                    }
                }
            } 
            else {
                apiLog.Response_Body__c = res.getBody();
            }
        }
    }

    class ServiceCls {
        Object serviceName;
        Object access;
    }

    private static List<String> errorEmailRecipientList = AUTODESK_BIM360.Error_Email_Recipients__c.split(',');
    
    public static OrgWideEmailAddress[] OWEA {
        get {
            if (OWEA == null) {
                OWEA = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'BIM Central Token Flex'];
            }
            return OWEA;
        }
        set;
    }
    
    public final static Map<String, String> EMAIL_TEMPLATE_MAP {
        get {
            if (EMAIL_TEMPLATE_MAP == null) {
                EMAIL_TEMPLATE_MAP = new Map<String, String>();
                for (EmailTemplate et : [SELECT Id, DeveloperName FROM EmailTemplate]) {
                    EMAIL_TEMPLATE_MAP.put(et.DeveloperName, et.Id);
                }
            }
            return EMAIL_TEMPLATE_MAP;
        }
        set;
    }

    public static void sendFailedRecordEmail(List<BC_Request__c> errorList) {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        for(BC_Request__c bcRequest : errorList) {

            String templateId = EMAIL_TEMPLATE_MAP.get('Notification_Autodesk_Error');
            Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(templateId, null, bcRequest.Id);
            email.setToAddresses(errorEmailRecipientList);
            email.saveAsActivity = false;
            email.setOrgWideEmailAddressId(OWEA.get(0).Id);
            emailsToSend.add(email);
        }

        if(emailsToSend.isEmpty() == false){
            Messaging.SendEmailResult[] sendResults = Messaging.sendEmail(emailsToSend, false);
        }
    }

    public static void sendFailedCompanyUpdateEmail(Map<Id, String> messageByBCRequestId) {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        for(Id bcRequestId : messageByBCRequestId.keySet()) {

            String ErrorMsg = messageByBCRequestId.get(bcRequestId);

            String templateId = EMAIL_TEMPLATE_MAP.get('Notification_Autodesk_Error_Company_Not_Found');
            Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(templateId, null, bcRequestId);
            String body = email.getPlainTextBody();
            body = body.replace('[ERROR_CODE]',ErrorMsg);
            email.setHtmlBody(body);
            email.setToAddresses(errorEmailRecipientList);
            email.saveAsActivity = false;
            email.setOrgWideEmailAddressId(OWEA.get(0).Id);
            emailsToSend.add(email);
        }

        if(emailsToSend.isEmpty() == false){
            Messaging.SendEmailResult[] sendResults = Messaging.sendEmail(emailsToSend, false);
        }
    }

    ////////////////////////////// START CALLOUT METHODS //////////////////////////////
    // https://forge.autodesk.com/en/docs/bim360/v1/reference/http/projects-project_id-industry_roles-GET/
    /*
    {"code":1004,"message":"this project doesn't exist."}
    [{"id":"1a400a0f-14df-46ce-bef4-79f574395d77","project_id":"27d5b3ed-0e9b-4c68-954a-b89b12257774","name":"Amazon India Operations","services":{"project_administration":{"access_level":"no_access"},"insight":{"access_level":"user"}},"member_group_id":"118898231"},{"id":"1ae01777-8e84-4226-8710-f7354
    */
    public static void getProjectRoles(API_Log__c apiLog, String token) {
        String projectId = apiLog.BC_BIM_Project__r.AD_ID__c;

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://developer.api.autodesk.com/hq/v2/accounts/'+ ACCOUNT_ID + '/projects/' + projectId + '/industry_roles');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');

        LogHttp http = new LogHttp();
        http.send(req, apiLog);
    }

    // 	https://developer.api.autodesk.com/hq/v1/accounts/:account_id/users/search-GET/
    public static void getUserSearch(API_Log__c apiLog, String token) {
        HttpRequest req = new HttpRequest();
        String query = 'email=' + apiLog.BC_Request__r.Recipient_Email__c;
        req.setEndpoint('https://developer.api.autodesk.com/hq/v1/accounts/' + ACCOUNT_ID + '/users/search?' + query);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + token);
        System.debug(';;;; getUserSearch query ' + query);
        LogHttp http = new LogHttp();
        http.send(req, apiLog);
    }

    // https://forge.autodesk.com/en/docs/bim360/v1/reference/http/users-:user_id-GET/
    /*
    {"code":1004,"message":"this user doesn't exist."}
    {"account_id":"2c7da0c8-d4b7-48d1-9976-1954aedf4bae","role":"account_admin","status":"active","company_id":"5e8c03c1-f770-4d08-8fa5-e2c9d1ac2659","company_name":"Amazon","last_sign_in":"2021-10-20T21:12:45.000Z","default_role":null,"default_role_id":null,"access_level":"account_admin","id":"cf86be2b-
    */
    public static void getUser(API_Log__c apiLog, String token) {
        String userId = apiLog.BC_Request__r.Recipient_Email_Alias__c;

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://developer.api.autodesk.com/hq/v1/accounts/' + ACCOUNT_ID + '/users/' + userId);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + token);

        LogHttp http = new LogHttp();
        http.send(req, apiLog);
    }

    public static void patchUserToActive(API_Log__c apiLog, String token) {
        String payload = getRequestBodyPatchUserToActive(apiLog);

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://developer.api.autodesk.com/hq/v1/accounts/' + ACCOUNT_ID + '/users/' + apiLog.BIM_360_User_Id__c);
        req.setMethod('PATCH');
        req.setBody(payload);
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');

        LogHttp http = new LogHttp();
        http.send(req, apiLog);
    }

    public static void patchUserCompanyName(API_Log__c apiLog, String token) {
        String payload = getRequestBodyPatchUserCompanyName(apiLog);

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://developer.api.autodesk.com/hq/v1/accounts/' + ACCOUNT_ID + '/users/' + apiLog.BIM_360_User_Id__c);
        req.setMethod('PATCH');
        req.setBody(payload);
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');

        LogHttp http = new LogHttp();
        http.send(req, apiLog);
    }

    public static void getCompanyNameSearch(API_Log__c apiLog, String token) {
        String query = 'name=';
        query += apiLog.BC_Request__r.RecordTypeId == BCRequestTriggerHandler.nonAmazonianRecordTypeId ? 
                 apiLog.BC_Request__r.Recipient__r.Account.Vendor_Company_Name__c : 
                 apiLog.BC_Request__r.Recipient_Company_Entered__c;
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://developer.api.autodesk.com/hq/v1/accounts/' + ACCOUNT_ID + '/companies/search?'+query);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');

        LogHttp http = new LogHttp();
        http.send(req, apiLog);
    }

    // https://forge.autodesk.com/en/docs/bim360/v1/reference/http/users-POST/
    public static void postUser(API_Log__c apiLog, String token) {
        HttpRequest req = new HttpRequest();
        String payload = getRequestBodyPostUser(apiLog);

        req.setEndpoint('https://developer.api.autodesk.com/hq/v1/accounts/' + ACCOUNT_ID + '/users');
        req.setMethod('POST');
        req.setBody(payload);
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');

        LogHttp http = new LogHttp();
        http.send(req, apiLog);
    }

    // https://forge.autodesk.com/en/docs/bim360/v1/reference/http/projects-project_id-users-import-POST/
    public static void postUserToProject(API_Log__c apiLog, String token) {
        String projectId = apiLog.BC_BIM_Project__r.AD_ID__c;

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://developer.api.autodesk.com/bim360/admin/v1/projects/' + projectId + '/users');
        req.setMethod('POST');
        req.setBody(getRequestBodyPostUserToProject(apiLog));
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('x-user-id', X_USER_ID);

        LogHttp http = new LogHttp();
        http.send(req, apiLog);
    }

    public static void getAmazonUserInfo(API_Log__c apiLog) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:api_gateway_dev/recipient');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(getRequestBodyAmazonUserInfo(apiLog));
        
        LogHttp http = new LogHttp();
        http.send(req, apiLog);
    }

    public static void getProjectInfo(API_Log__c apiLog, String token) {
        String projectId = apiLog.BC_BIM_Project__r.AD_ID__c;
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://developer.api.autodesk.com/bim360/admin/v1/projects/' + projectId);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('x-user-id', X_USER_ID);

        LogHttp http = new LogHttp();
        http.send(req, apiLog);
    }

    public static void postProjectBulk(API_Log__c apiLog, String token) {

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://developer.api.autodesk.com/bim360/admin/v1/accounts/' + ACCOUNT_ID + '/projects');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('User-Id', X_USER_ID);
        req.setBody(getRequestBodyPostProjectBulk(apiLog));

        LogHttp http = new LogHttp();
        http.send(req, apiLog);
    }

    public static void patchProjectBulk(API_Log__c apiLog, String token) {
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://developer.api.autodesk.com/bim360/admin/v1/projects/' + apiLog.BIM360_Staging_Project__r.Project_Id__c);
        req.setMethod('PATCH');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('User-Id', X_USER_ID);
        req.setBody(getRequestBodyPatchProjectBulk(apiLog));

        LogHttp http = new LogHttp();
        http.send(req, apiLog);
    }

    public static void postUserToProjectBulk(API_Log__c apiLog, String token) {
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://developer.api.autodesk.com/bim360/admin/v1/projects/' + apiLog.BIM360_Staging_User__r.Project_Id__c + '/users');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('User-Id', X_USER_ID);
        req.setBody(getRequestBodyPostUserToProjectBulk(apiLog));

        LogHttp http = new LogHttp();
        http.send(req, apiLog);
    }

    public static void patchUserInProjectBulk(API_Log__c apiLog, String token) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://developer.api.autodesk.com/bim360/admin/v1/projects/' + apiLog.BIM360_Staging_User__r.Project_Id__c + '/users/' + apiLog.BIM360_Staging_User__r.User_Id__c);
        req.setMethod('PATCH');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('User-Id', X_USER_ID);
        req.setBody(getRequestBodyPatchUserInProjectBulk(apiLog));

        LogHttp http = new LogHttp();
        http.send(req, apiLog);
    }
    ////////////////////////////// END CALLOUT METHODS //////////////////////////////


    ////////////////////////////// START CREATE REQUEST BODY METHODS //////////////////////////////
    private static String getRequestBodyPatchUserToActive(API_Log__c apiLog) {
        Map<String, Object> result = new Map<String, Object>();
        result.put('status', 'active');
        return JSON.serialize(result);
    }

    private static String getRequestBodyPatchUserCompanyName(API_Log__c apiLog) {
        Map<String, Object> result = new Map<String, Object>();
        result.put('status', 'active');
        return JSON.serialize(result);
    }

    private static String getRequestBodyPostUser(API_Log__c apiLog) {
        Map<String,Object> result = new Map<String,Object>();
        result.put('email', apiLog.BC_Request__r.Recipient_Email__c);
        result.put('nickname', '');
        result.put('first_name', apiLog.BC_Request__r.Recipient_First_Name__c);
        result.put('last_name', apiLog.BC_Request__r.Recipient_Last_Name__c);
        result.put('image_url', '');
        result.put('address_line_1', '');
        result.put('address_line_2', '');
        result.put('city', '');
        result.put('postal_code', '');
        result.put('state_or_province', '');
        result.put('country', '');
        result.put('phone', '');
        result.put('job_title', '');
        result.put('industry', '');
        result.put('about_me', '');

        // https://issues.amazon.com/issues/P88165101 must be an amazonian request to default the company name
        if (apiLog.BC_Request__r.RecordTypeId != BCRequestTriggerHandler.nonAmazonianRecordTypeId) {
            result.put('company', 'Amazon');
            result.put('company_id', '5e8c03c1-f770-4d08-8fa5-e2c9d1ac2659');
        } 

        return JSON.serialize(result);
    }

    /*
    @ Role Info
    {
		"id": "8144acd2-3214-45c3-b398-17df520081c9",
		"project_id": "44776f84-cc67-46a5-bc2f-9ca9e633ce01",
		"name": "Architect",
		"services": {
			"project_administration": {
				"access_level": "no_access"
			},
			"document_management": {
				"access_level": "user"
			},
			"project_management": {
				"access_level": "user"
			},
			"insight": {
				"access_level": "user"
			}
		},
		"member_group_id": "133645968"
	},

    @ Project Service Info
    "services": [
        {
            "serviceName": "documentManagement",
            "access": "member"
        },
        {
            "serviceName": "projectAdministration",
            "access": "none"
        }
    ],

    @ Desc : Use mapping because the name of the service information obtained from the role and the name of the service information used for the project are different.
    */
    private static String getRequestBodyPostUserToProject(API_Log__c apiLog) {

        Map<String, Object> result = new Map<String, Object>();
        result.put('email', apiLog.BC_Request__r.Recipient_Email__c);

        Map<String, Object> roleInfo = (Map<String, Object>)JSON.deserializeUntyped( apiLog.BIM_360_Project_Role_Info__c );
        
        List<Object> roleList = new List<Object>{roleInfo.get('id')};
        result.put('roleIds', roleList);

        Map<String, Object> serviceMap = (Map<String, Object>)roleInfo.get('services');
        List<ServiceCls> serviceList = new List<ServiceCls>();
        for(BIM_360_Service_Name_Mapping__mdt mapping : [SELECT Id, Label, DeveloperName FROM BIM_360_Service_Name_Mapping__mdt]) {
            if (serviceMap.containsKey(mapping.Label)) {

                Map<String, Object> access = (Map<String, Object>) serviceMap.get(mapping.Label);
                String roleAccessName = (String)access.get('access_level');

                ServiceCls service = new ServiceCls();
                service.serviceName = mapping.DeveloperName;
                service.access = getProjectAccessName(roleAccessName);

                serviceList.add(service);
            }
        }
        result.put('services', serviceList);

        return JSON.serialize(result);
    }

    private static String getProjectAccessName(String accessName) {
        if (accessName == 'user') {
            return 'member';
        } else if (accessName == 'no_access') {
            return 'none';
        } else if (accessName == 'admin') {
            return 'administrator';
        }
        return '';
    }

    private static String getRequestBodyAmazonUserInfo(API_Log__c apiLog) {
        Map<String, Object> result = new Map<String, Object>();

        if (apiLog.BC_Request__c != null) {
            if (apiLog.BC_Request__r.RecordTypeId == BCRequestTriggerHandler.amazonianRecordTypeId ||
                apiLog.BC_Request__r.RecordTypeId == BCRequestTriggerHandler.tokenFlexRecordTypeId) {
                result.put('alias', apiLog.BC_Request__r.Recipient_Email__c.split('@')[0]);
            } else if (apiLog.BC_Request__r.RecordTypeId == BCRequestTriggerHandler.nonAmazonianRecordTypeId) {
                result.put('alias', apiLog.BC_Request__r.APOC_Email__c.split('@')[0]);
            }   
        } else if (apiLog.Account__c != null) {
            result.put('alias', apiLog.Account__r.FM_Email__c.split('@')[0]);
        }
             
        return JSON.serialize(result);
    }

    private static String getRequestBodyPostProjectBulk(API_Log__c apiLog) {
        Map<String, Object> result = new Map<String, Object>();

        if (apiLog.BIM360_Staging_Project__c != null) {
            result.put('addressLine1', apiLog.BIM360_Staging_Project__r.Address_Line_1__c);
            result.put('addressLine2', apiLog.BIM360_Staging_Project__r.Address_Line_2__c);
            result.put('city', apiLog.BIM360_Staging_Project__r.City__c);
            result.put('constructionType', apiLog.BIM360_Staging_Project__r.Construction_Type__c);
            result.put('contractType', apiLog.BIM360_Staging_Project__r.Contract_Type__c);
            result.put('country', apiLog.BIM360_Staging_Project__r.Country__c);
            result.put('endDate', apiLog.BIM360_Staging_Project__r.End_Date__c);
            result.put('jobNumber', apiLog.BIM360_Staging_Project__r.Job_Number__c);
            result.put('name', apiLog.BIM360_Staging_Project__r.Project_Name__c);
            result.put('postalCode', apiLog.BIM360_Staging_Project__r.Postal_Code__c);
            result.put('type', apiLog.BIM360_Staging_Project__r.Project_Type__c);
            result.put('startDate', apiLog.BIM360_Staging_Project__r.Start_Date__c);
            result.put('stateOrProvince', apiLog.BIM360_Staging_Project__r.State_Province__c);
            result.put('timezone', apiLog.BIM360_Staging_Project__r.Time_Zone__c);

            /*
            "projectValue": {
                "value": 1650000,
                "currency": "USD"
            }
            */
            Map<String, Object> projectValue = new Map<String, Object>();
            projectValue.put('value', apiLog.BIM360_Staging_Project__r.Project_Value__c);
            projectValue.put('currency', apiLog.BIM360_Staging_Project__r.Project_Currency__c);
            result.put('projectValue', projectValue);

            /*
            "services": [
                {
                    "serviceName": "documentManagement"
                },
                {
                    "serviceName": "fieldManagement"
                }
            ]
            */
            if (String.isNotBlank(apiLog.BIM360_Staging_Project__r.Services__c)) {
                List<Object> services = new List<Object>();
                List<String> servicesSplit = apiLog.BIM360_Staging_Project__r.Services__c.split(';');
                for (String item : servicesSplit) {
                    Map<String, Object> itemMap = new Map<String, Object>();
                    itemMap.put('serviceName', item);
                    services.add(itemMap);
                }
                result.put('services', services);
            }

            /*
            "template": {
                "projectId": "bb1f77c8-b0fe-46d7-943b-5256337ecb26",
                "options": {
                    "field":{
                        "includeCompanies": false,
                        "includeLocations": false
                    }

                }
            }
            */
            else if (String.isNotBlank(apiLog.BIM360_Staging_Project__r.Template_Project_Id__c)) {
                Map<String, Object> template = new Map<String, Object>();
                template.put('projectId', apiLog.BIM360_Staging_Project__r.Template_Project_Id__c);

                Map<String, Object> field = new Map<String, Object>();
                field.put('includeCompanies', apiLog.BIM360_Staging_Project__r.Include_Companies__c);
                field.put('includeLocations', apiLog.BIM360_Staging_Project__r.Include_Locations__c);

                Map<String, Object> options = new Map<String, Object>();
                options.put('field', field);
                template.put('options', options);

                result.put('template', template);
            }
        }

        return JSON.serialize(result);
    }

    private static String getRequestBodyPatchProjectBulk(API_Log__c apiLog) {
        Map<String, Object> result = new Map<String, Object>();

        if (apiLog.BIM360_Staging_Project__c != null) {
            if (String.isNotBlank(apiLog.BIM360_Staging_Project__r.Address_Line_1__c)) {
                result.put('addressLine1', apiLog.BIM360_Staging_Project__r.Address_Line_1__c);
            }
            if (String.isNotBlank(apiLog.BIM360_Staging_Project__r.Address_Line_2__c)) {
                result.put('addressLine2', apiLog.BIM360_Staging_Project__r.Address_Line_2__c);
            }
            if (String.isNotBlank(apiLog.BIM360_Staging_Project__r.City__c)) {
                result.put('city', apiLog.BIM360_Staging_Project__r.City__c);
            }
            if (String.isNotBlank(apiLog.BIM360_Staging_Project__r.Construction_Type__c)) {
                result.put('constructionType', apiLog.BIM360_Staging_Project__r.Construction_Type__c);
            }
            if (String.isNotBlank(apiLog.BIM360_Staging_Project__r.Contract_Type__c)) {
                result.put('contractType', apiLog.BIM360_Staging_Project__r.Contract_Type__c);
            }
            if (String.isNotBlank(apiLog.BIM360_Staging_Project__r.Country__c)) {
                result.put('country', apiLog.BIM360_Staging_Project__r.Country__c);
            }
            if (apiLog.BIM360_Staging_Project__r.End_Date__c != null) {
                result.put('endDate', apiLog.BIM360_Staging_Project__r.End_Date__c);
            }
            if (String.isNotBlank(apiLog.BIM360_Staging_Project__r.Job_Number__c)) {
                result.put('jobNumber', apiLog.BIM360_Staging_Project__r.Job_Number__c);
            }
            if (String.isNotBlank(apiLog.BIM360_Staging_Project__r.Project_Name__c)) {
                result.put('name', apiLog.BIM360_Staging_Project__r.Project_Name__c);
            }
            if (String.isNotBlank(apiLog.BIM360_Staging_Project__r.Postal_Code__c)) {
                result.put('postalCode', apiLog.BIM360_Staging_Project__r.Postal_Code__c);
            }
            if (String.isNotBlank(apiLog.BIM360_Staging_Project__r.Project_Type__c)) {
                result.put('type', apiLog.BIM360_Staging_Project__r.Project_Type__c);
            }
            if (apiLog.BIM360_Staging_Project__r.Start_Date__c != null) {
                result.put('startDate', apiLog.BIM360_Staging_Project__r.Start_Date__c);
            }
            if (String.isNotBlank(apiLog.BIM360_Staging_Project__r.State_Province__c)) {
                result.put('stateOrProvince', apiLog.BIM360_Staging_Project__r.State_Province__c);
            }
            if (String.isNotBlank(apiLog.BIM360_Staging_Project__r.Time_Zone__c)) {
                result.put('timezone', apiLog.BIM360_Staging_Project__r.Time_Zone__c);
            }

            /*
            "projectValue": {
                "value": 1650000,
                "currency": "USD"
            }
            */
            if (apiLog.BIM360_Staging_Project__r.Project_Value__c != null &&
                String.isNotBlank(apiLog.BIM360_Staging_Project__r.Project_Currency__c)) {
                Map<String, Object> projectValue = new Map<String, Object>();
                projectValue.put('value', apiLog.BIM360_Staging_Project__r.Project_Value__c);
                projectValue.put('currency', apiLog.BIM360_Staging_Project__r.Project_Currency__c);
                result.put('projectValue', projectValue);
            }

            /*
            "services": [
                {
                    "serviceName": "documentManagement"
                },
                {
                    "serviceName": "fieldManagement"
                }
            ]
            */
            if (String.isNotBlank(apiLog.BIM360_Staging_Project__r.Services__c)) {
                List<Object> services = new List<Object>();
                List<String> servicesSplit = apiLog.BIM360_Staging_Project__r.Services__c.split(';');
                for (String item : servicesSplit) {
                    Map<String, Object> itemMap = new Map<String, Object>();
                    itemMap.put('serviceName', item);
                    services.add(itemMap);
                }
                result.put('services', services);
            }

            /*
            "template": {
                "projectId": "bb1f77c8-b0fe-46d7-943b-5256337ecb26",
                "options": {
                    "field":{
                        "includeCompanies": false,
                        "includeLocations": false
                    }

                }
            }
            */
            else if (String.isNotBlank(apiLog.BIM360_Staging_Project__r.Template_Project_Id__c)) {
                Map<String, Object> template = new Map<String, Object>();
                template.put('projectId', apiLog.BIM360_Staging_Project__r.Template_Project_Id__c);

                Map<String, Object> field = new Map<String, Object>();
                field.put('includeCompanies', apiLog.BIM360_Staging_Project__r.Include_Companies__c);
                field.put('includeLocations', apiLog.BIM360_Staging_Project__r.Include_Locations__c);

                Map<String, Object> options = new Map<String, Object>();
                options.put('field', field);
                template.put('options', options);

                result.put('template', template);
            }
        }

        System.debug(';;;; getRequestBodyPatchProjectBulk result ' + result);
        return JSON.serialize(result);
    }

    /*
    {
        "email": "chochon@amazon.com",
        "services": [
            {
                "serviceName": "documentManagement",
                "access": "member"
            },
            {
                "serviceName": "insight",
                "access": "member"
            },
            {
                "serviceName": "plan",
                "access": "none"
            },
            {
                "serviceName": "projectAdministration",
                "access": "none"
            },
            {
                "serviceName": "projectManagement",
                "access": "member"
            }
        ]
    }
    */
    private static String getRequestBodyPostUserToProjectBulk(API_Log__c apiLog) {
        Map<String, Object> result = new Map<String, Object>();

        result.put('email', apiLog.BIM360_Staging_User__r.Email__c);

        List<Object> services = new List<Object>();
        // split on csv_Services__c and csv_Accesses__c since it contains the raw csv value with duplicates and correct order
        List<String> serviceSplit = apiLog.BIM360_Staging_User__r.csv_Services__c.split(';');
        List<String> accessSplit = apiLog.BIM360_Staging_User__r.csv_Accesses__c.split(';');

        for (Integer i = 0; i < serviceSplit.size(); i++) {
            Map<String, Object> itemMap = new Map<String, Object>();
            itemMap.put('serviceName', serviceSplit[i]);
            itemMap.put('access', accessSplit[i]);
            services.add(itemMap);
        }

        result.put('services', services);

        return JSON.serialize(result);
    }

    private static String getRequestBodyPatchUserInProjectBulk(API_Log__c apiLog) {
        Map<String, Object> result = new Map<String, Object>();

        if (String.isNotBlank(apiLog.BIM360_Staging_User__r.Company_Id__c)) {
            result.put('companyId', apiLog.BIM360_Staging_User__r.Company_Id__c);
        }

        if (String.isNotBlank(apiLog.BIM360_Staging_User__r.Role_Ids__c)) {
            List<Object> roleIds = new List<Object>();
            List<String> roleIdsSplit = apiLog.BIM360_Staging_User__r.Role_Ids__c.split(';');

            for (Integer i = 0; i < roleIdsSplit.size(); i++) {
                roleIds.add(roleIdsSplit);
            }

            result.put('roleIds', roleIds);
        }

        List<Object> services = new List<Object>();
        // split on csv_Services__c and csv_Accesses__c since it contains the raw csv value with duplicates and correct order
        List<String> serviceSplit = apiLog.BIM360_Staging_User__r.csv_Services__c.split(';');
        List<String> accessSplit = apiLog.BIM360_Staging_User__r.csv_Accesses__c.split(';');

        for (Integer i = 0; i < serviceSplit.size(); i++) {
            Map<String, Object> itemMap = new Map<String, Object>();
            itemMap.put('serviceName', serviceSplit[i]);
            itemMap.put('access', accessSplit[i]);
            services.add(itemMap);
        }

        result.put('services', services);

        return JSON.serialize(result);
    }
    ////////////////////////////// END CREATE REQUEST BODY METHODS //////////////////////////////

    
    public static String getToken() {
        HttpRequest req = new HttpRequest();
	
        String body = 'client_id=' + CLIENT_ID +
                      '&client_secret=' + CLIENT_SECRET +
                      '&scope=user-profile:read user:read user:write viewables:read data:read data:write data:create data:search bucket:create bucket:read bucket:update bucket:delete code:all account:read account:write' +
                      '&grant_type=client_credentials';

        req.setEndpoint('https://developer.api.autodesk.com/authentication/v1/authenticate');
        req.setMethod('POST');
        req.setBody(body);
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setHeader('user-id', X_USER_ID);

        Http http = new Http();
        HTTPResponse res = http.send(req);

        if (Test.isRunningTest()) {
            return 'test_access_token';
        }

        Map< String, Object > deserializedBody = ( Map< String, Object > )JSON.deserializeUntyped( res.getBody() );

        return (String)deserializedBody.get('access_token');
    }

    public static String appendErrorMessage(API_Log__c apiLog, String msg) {
        String result = String.isBlank(apiLog.Error_Message__c) ? msg + '\n' : apiLog.Error_Message__c + msg + ';\n';

        return result;
    }
}