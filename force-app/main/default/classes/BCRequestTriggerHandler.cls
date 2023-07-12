public without sharing class BCRequestTriggerHandler {

    public static Id amazonianRecordTypeId {
        get {
            if(amazonianRecordTypeId == null) {
                amazonianRecordTypeId = Schema.SObjectType.BC_Request__c.getRecordTypeInfosByDeveloperName().get('BIM_360_Amazonian').getRecordTypeId();
            }
            return amazonianRecordTypeId;
        }
        set;
    }

    public static Id nonAmazonianRecordTypeId {
        get {
            if(nonAmazonianRecordTypeId == null) {
                nonAmazonianRecordTypeId = Schema.SObjectType.BC_Request__c.getRecordTypeInfosByDeveloperName().get('BIM_360_Non_Amazonian').getRecordTypeId();
            }
            return nonAmazonianRecordTypeId;
        }
        set;
    }

    public static Id tokenFlexRecordTypeId {
        get {
            if(tokenFlexRecordTypeId == null) {
                tokenFlexRecordTypeId = Schema.SObjectType.BC_Request__c.getRecordTypeInfosByDeveloperName().get('Token_Flex_License').getRecordTypeId();
            }
            return tokenFlexRecordTypeId;
        }
        set;
    }
    
    public static Boolean isFirstTime = true;

    public static void onAfterInsert(List<BC_Request__c> newList) {
        List<API_Log__c> apiLogsToInsert = new List<API_Log__c>();

        processAddUserToProjectIntegration(newList, null, apiLogsToInsert);
        processAmazonUserInfoIntegration(newList, apiLogsToInsert);

        if (!apiLogsToInsert.isEmpty()) {
            List<Database.SaveResult> sr = Database.insert(apiLogsToInsert, false);
        }
        
        // Flow API Name : BC_BC_Request_record_create_After_Save
        processSendEmail(newList);
    }

    public static void onAfterUpdate(List<BC_Request__c> newList, Map<Id, BC_Request__c> oldMap, Map<Id, BC_Request__c> newMap) {
        System.debug('------------onAfterUpdate----------------' + newList);
        // Flow API Name : BC_BC_Request_record_update_After_Save
        processUpdateAfterSave(newList, oldMap, newMap);

        // Flow API Name : BC_BC_Request_record_update_After_Save_Create_External_Group_and_Share
        processCreateExternalGroupShare(newList, oldMap, newMap);
        
        // Flow API Name : BC_BC_Request_record_update_After_Save_Create_BC_Request_Share
        processCreateBCRequestShare(newMap);  
        
        // Phase 3 Req 8 - method will handle related request projects based on request
        processRelatedRequestProject(newList, oldMap);
    }

    public static void onBeforeInsert(List<BC_Request__c> newList) {
        // Flow API Name : BC_BC_Request_record_create_update_Before_Save
        processCreateUpdate(newList);
    }

    public static void onBeforeUpdate(List<BC_Request__c> newList, Map<Id, BC_Request__c> oldMap, Map<Id, BC_Request__c> newMap) {
        // Flow API Name : BC_BC_Request_record_create_update_Before_Save
        processCreateUpdate(newList);
        // trigger invokes queueable and queueable updates BC_Request
        // prevent queueable from causing the trigger to run queueable again in an endless loop
        // batch check is being put in as a pre-caution
        if (!System.isQueueable() && !System.isBatch()) {

            List<API_Log__c> apiLogsToInsert = new List<API_Log__c>();
            
            processAddUserToProjectIntegration(newList, oldMap, apiLogsToInsert);
            processAmazonUserInfoIntegration(newList, apiLogsToInsert);

            if (!apiLogsToInsert.isEmpty()) {
                System.debug(apiLogsToInsert);
                List<Database.SaveResult> sr = Database.insert(apiLogsToInsert, false);
            }
        }  
         
    }

    // phase 2 req 1
    // phase 3 req 8 - creation of Request Project allows for multiple project selection
    private static void processAddUserToProjectIntegration(List<BC_Request__c> newList, 
                                                           Map<Id, BC_Request__c> oldMap, 
                                                           List<API_Log__c> apiLogsToInsert) {
        List<String> validRecordTypeIdList = getValidRecordTypeIdList();
        Set<Id> requestIdsToCreateAPILogs = new Set<Id>();
        for (BC_Request__c item : newList) {
            if (item.Stage__c == 'Fulfill Request' && 
                !item.Is_BIM360_Add_User_To_Project_Success__c &&
                validRecordTypeIdList.contains(item.RecordTypeId)) {
                requestIdsToCreateAPILogs.add(item.Id);
            }
        }
        
        if (!requestIdsToCreateAPILogs.isEmpty()) {
            List<Request_Project__c> requestProjectsToUpdate = new List<Request_Project__c>();
            for (Request_Project__c rp : [SELECT Id, Project_Record_Name__c, Request__c, Approval_Status__c
                                          FROM Request_Project__c
                                          WHERE Request__c IN :requestIdsToCreateAPILogs
                                          AND Approval_Status__c != 'Rejected']) {
                apiLogsToInsert.add(createGetProjectRolesApiLog(rp));

                if (rp.Approval_Status__c != 'Approved') {
                    rp.Approval_Status__c = 'Approved';
                    requestProjectsToUpdate.add(rp);
                }
            }
            if (!requestProjectsToUpdate.isEmpty()) {
                update requestProjectsToUpdate;
            }
        }        
    }

    // phase 2 req 4
    private static void processAmazonUserInfoIntegration(List<BC_Request__c> newList, 
                                                         List<API_Log__c> apiLogsToInsert) {
        
        List<String> validRecordTypeIdsAmazonUserInfoIntegration = getValidRecordTypeIdsAmazonUserInfoIntegration();
    
        for (BC_Request__c item : newList) {   
            if ((item.Stage__c == 'New') &&
                (!item.Is_Redshit_Get_User_Info_Success__c) &&
                (item.Recipient_Email__c != null || item.APOC_Email__c != null) &&
                (validRecordTypeIdsAmazonUserInfoIntegration.contains(item.RecordTypeId))) {
                apiLogsToInsert.add(createAmazonUserInfoApiLog(item));
            }
        }
    }

    /*
        * @ Author : danbik@fiduciarytech.com
        * @ Date : 6/17/2022
        * @ Flow Label : BC_BC_Request record create/update-Before Save
        * @ Flow API Name : BC_BC_Request_record_create_update_Before_Save
        * @ Trigger : Before Insert, Update
        * @ Desc : On BC_Request record creation, 
                        Assigns record owner. 
                        Sets Stage to Evaluate if BIM Project is blank.
                        Identifies duplicate requests if Status is 'Open'.
                    On BC_Request record update,
                        Update record related BIM Project if BIM Project was updated to a value and before update it was NULL and identifies duplicate requests.
                        Updates Status if Stage is updated.
    */ 
    private static void processCreateUpdate(List<BC_Request__c> newList) {
        // BIM Central Admin
        Id bimCentralAdmin = AccountTriggerHelper.userBIMCentralAdminId();

        for (BC_Request__c item : newList) {

            if (item.Disable_Automation__c == true) {
                continue;
            } 

            if (item.Id == null) {  // 1 New request
                // Assign default record values
                item.OwnerId = bimCentralAdmin;
                item.Requestor_Company_Entered__c = getRequestorCompany(item);
                item.Recipient_Company_Entered__c = getRecipientCompany(item);
                item.Is_Amazonian_Recipient_Email__c = getAmazonianEmail(item.Recipient_Email__c);
                item.Is_Amazonian_Requestor_Email__c = getAmazonianEmail(item.Requestor_Email__c);
                item.New_Request__c = true;
                item.Is_Contract_Holder_Amazon_Email__c = getContractHolderAmazonEmail(item);                               
            } else if (item.Stage__c == 'Resolved - Completed') { // 4 Stage moved to Resolved - Completed
                // Assign Status to Closed
                item.Status__c = UtilityConsts.BC_STATUS_CLOSED; // 'Closed'
            } else if (item.Stage__c == UtilityConsts.BC_STAGE_RESOLVED_NOT_COMPLETED) { // 5 Stage moved to Resolved - Not Completed
                // Assign Status to Closed
                item.Status__c = UtilityConsts.BC_STATUS_CLOSED; // 'Closed'r
            } else if (item.Stage__c == UtilityConsts.BC_STAGE_AUTODESK_ERROR) { // 6 Stage moved to Autodesk Error
                // Assign Ready Autodesk Error
                item.Ready_Autodesk_Error__c = true;                
            } else {
                // Do not anyting
            }
        }  
    }

    // Get requestor company name
    private static String getRequestorCompany(BC_Request__c bcRequest) {
        /*
            Email required
        */
        if (System.Label.BC_Amazon_Email_Domain.contains(getEmail(bcRequest.Requestor_Email__c, 'companyEmail'))) {
            return 'Amazon';
        }  

        return bcRequest.Requestor_Company_Entered__c;
    }

    // Get recipient company name
    private static String getRecipientCompany(BC_Request__c bcRequest) {
        /*
            Email required
        */
        if (System.Label.BC_Amazon_Email_Domain.contains(getEmail(bcRequest.Recipient_Email__c, 'companyEmail'))) {
            return 'Amazon';
        }  

        return bcRequest.Recipient_Company_Entered__c;
    }
    
    // Identifies Amazonian
    private static Boolean getAmazonianEmail(String email) {
        /*
            Email required
        */
        if (System.Label.BC_Amazon_Email_Domain.contains(getEmail(email, 'companyEmail'))) {
            return true;
        }  

        return false;
    }

    // Identifies that Contract Holder Amazon Email is Amazon
    private static Boolean getContractHolderAmazonEmail(BC_Request__c bcRequest) {
        String email;

        if (bcRequest.Contract_with_Amazon__c == true) {
            email = bcRequest.Recipient_Email__c;
        } else if (bcRequest.Contract_with_Amazon__c == false) {
            email = bcRequest.Contract_Holder_Contact_Email__c;
        }
        
        if (email != null) {
            if (System.Label.BC_Amazon_Email_Domain.contains(getEmail(email, 'companyEmail'))) {
                return true;
            } 
        }
        
        return false;        
    }

    /* ========== BC_BC_Request_record_create_update_Before_Save END ========== */


    /*  
        * @ Author : danbik@fiduciarytech.com
        * @ Date : 6/20/2022
        * @ Flow Label : BC_BC_Request record create-After Save
        * @ Flow API Name : BC_BC_Request_record_create_After_Save
        * @ Trigger : After Insert
        * @ Desc : On BC_Request record creation, Send mail to BC_Request Owner.
    */ 
    private static void processSendEmail(List<BC_Request__c> newList) {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        for (BC_Request__c item : newList) {
            if (item.Disable_Automation__c == true) {
                continue;
            } 

            // Send_new_request_confirmation_email - Subflow : BC_Email communication                
            emailsToSend.addAll(EmailCommunication.getEmailMessageList(item, 'New Request confirmation'));

            //Evaluate_if_request_is_not_completed
            if (item.Ready_Resolved_Not_Completed__c == true &&
            item.New_Request__c == true) { // 1 Resolved - Not Completed 
                // Send_Not_Completed_email_notification - Subflow : BC_Email communication
                emailsToSend.addAll(EmailCommunication.getEmailMessageList(item, 'Request Not Completed notification'));  
            } else {
                // Do not anything
            }
        }
        if (!emailsToSend.isEmpty()){
            Messaging.SendEmailResult[] sendResults = Messaging.sendEmail(emailsToSend, false);
        }
    }
    /* ========== BC_BC_Request_record_create_After_Save END ========== */


    /*  
        * @ Author : danbik@fiduciarytech.com
        * @ Date : 6/22/2022
        * @ Flow Label : BC_BC_Request record update-After Save
        * @ Flow API Name : BC_BC_Request_record_update_After_Save
        * @ Trigger : After Update
        * @ Desc : If the Senior Leader Email or Stage or APOC Approval is updated,
                    Email sent according to Stage And Update related record.
    */ 
    private static void processUpdateAfterSave(List<BC_Request__c> newList, 
                                                Map<Id, BC_Request__c> oldMap,
                                                Map<Id, BC_Request__c> newMap) {   
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();          

        // External Account id
        Set<Id> externalAccountIds = new Set<id>();

        // Create BC_User_Bill_To id
        List<Id> bcUserBillToIds = new List<id>();

        List<BC_Request__c> requestToUpdate = new List<BC_Request__c>();

        // BIM Project List
        List<BC_Request__c> requestBIMProjectList = new List<BC_Request__c>();
                                                
        // Internal Account id
        List<BC_Request__c> internalAccountList = new List<BC_Request__c>();
        Set<Id> internalAccountIds = new Set<Id>();
        if (!isFirstTime) {
            return;    
        }

        for (BC_Request__c item : newMap.values()) {
            BC_Request__c bcReqest = new BC_Request__c();
            
            if (item.Disable_Automation__c == false &&
            item.Pre_Approved__c == false) {
                isFirstTime = false;
                // Action
                if (item.New_Request__c == true &&
                (item.SL_Email__c != null || String.isNotEmpty(item.SL_Email__c))  &&
                (item.SL_Email__c != oldMap.get(item.id).SL_Email__c)) { // 1 Find Amazon partner team
                    // Update New Request
                    bcReqest.Id = item.Id;
                    bcReqest.New_Request__c = false;      

                    // Update Email Alias/Domain fields - Subflow : BC_Update Email Alias/Domain fields
                    bcReqest = processUpdateEmailAliasDomain(item);

                    // BIM Project List
                    requestBIMProjectList.add(item);        
                    requestToUpdate.add(bcReqest);                                
                }

                if (item.Stage__c == 'Autodesk Error' &&
                    item.Ready_Autodesk_Error__c == true) { // 2 Stage is Autodesk error
                    // Update Ready Autodesk Error
                    bcReqest.Id = item.Id;
                    bcReqest.Ready_Autodesk_Error__c = false;                    

                    // Send TFA Evaluate notification - Subflow : BC_Email communication
                    emailsToSend.addAll(EmailCommunication.getEmailMessageList(item, 'Action needed'));
                    requestToUpdate.add(bcReqest);

                }  else if (item.BIM_Project_Corrected__c == true &&
                        item.Is_Redshit_Get_User_Info_Success__c == true &&
                        (item.RecordTypeId == amazonianRecordTypeId || 
                        item.RecordTypeId == nonAmazonianRecordTypeId)) { // 3 BIM Project corrected
                    // Update BIM Project Corrected
                    bcReqest.Id = item.Id;
                    bcReqest.BIM_Project_Corrected__c = false;

                    // Update Email Alias/Domain fields - Subflow : BC_Update Email Alias/Domain fields
                    bcReqest = processUpdateEmailAliasDomain(item);

                    // BIM Project List
                    requestBIMProjectList.add(item);
                    requestToUpdate.add(bcReqest);  

                } else if (item.Is_BIM_Project_Blank__c == true &&
                    item.Stage__c == UtilityConsts.BC_STAGE_EVALUATE) { // 2 Evaluate
                    // Send_TFA_Evaluate_notification - Subflow : BC_Email communication
                    emailsToSend.addAll(EmailCommunication.getEmailMessageList(item, 'Action needed'));

                } else if (item.APOC_Approval__c == 'Approved' &&
                        item.Stage__c == 'Pending APOC Approval') { // 4 APOC approved
                    // Update APOC approval lock
                    bcReqest.APOC_Approval_Locked__c = true;
                    bcReqest.Id = item.Id;
                    internalAccountList.add(bcReqest);
                    internalAccountIds.add(item.id);

                    requestToUpdate.add(bcReqest);                 

                } else if (item.APOC_Approval__c == 'Rejected' &&
                        item.Stage__c == 'Pending APOC Approval') { // 5 APOC not approved
                    // Update Stage for APOC non-approval
                    bcReqest.Id = item.Id;
                    bcReqest.APOC_Approval_Locked__c = true;
                    bcReqest.Reason_Not_Completed__c = 'Not approved';
                    bcReqest.Stage__c = 'Resolved - Not Completed';
                    bcReqest.Status__c = 'Closed';

                    // Send Not Completed email notification - Subflow : BC_Email communication
                    emailsToSend.addAll(EmailCommunication.getEmailMessageList(item, 'Request Not Completed notification'));

                    requestToUpdate.add(bcReqest);

                } else if (item.Stage__c == 'Fulfill Request') { // 6 Stage is Fulfill Request        
                    // Manual fulfillment
                    if (item.RecordTypeId == tokenFlexRecordTypeId) { // 1 Token Flex License request
                        // Send Token Flex license fulfillment notification - Subflow : BC_Email communication
                        emailsToSend.addAll(EmailCommunication.getEmailMessageList(item, 'Fulfillment ready'));
                    } else {
                        // Do not anything
                    }

                } else if (item.Stage__c == 'Resolved - Completed') { // 7 Stage is Resolved - Completed
                    // Non-Amazonian request
                    if (item.Record_Type_ID_18_digit__c == nonAmazonianRecordTypeId) { // 1 Non-Amazonian request
                        // Update External Account - Subflow : BC_Update External Account record
                        externalAccountIds.add(item.id);
                    }

                    // Create BC_User Bill To record - Subflow : BC_Create BC_User Bill To record
                    bcUserBillToIds.add(item.id);

                    // Send completed request notification email - Subflow : BC_Email communication
                    emailsToSend.addAll(EmailCommunication.getEmailMessageList(item, 'Completed request notification'));

                } else if (item.Stage__c == 'Resolved - Not Completed') { // 8 Stage is Resolved - Not Completed
                    // Send Not Completed email notification - Subflow : BC_Email communication
                    emailsToSend.addAll(EmailCommunication.getEmailMessageList(item, 'Request Not Completed notification'));

                }

                // Run Asynchronously : Non-Amazonian Pre-Approval
                if (item.Pre_Approved__c == true &&
                (item.Record_Type_ID_18_digit__c == nonAmazonianRecordTypeId ||
                item.Record_Type_ID_18_digit__c == amazonianRecordTypeId)) { // 1 Pre-Approval
                    // Update BC_Request Stage
                    bcReqest.Id = item.Id;
                    bcReqest.Stage__c = 'Fulfill Request';
                    bcReqest.Status__c = 'Open';

                    requestToUpdate.add(bcReqest);
                }
            }
        }

        if (!requestToUpdate.isEmpty()) {
            update requestToUpdate;
        }
        
        // Evaluate if BIM Project is provided or a project name was manually entered by the Requestor
        if (!requestBIMProjectList.isEmpty()) {
            processReqestBIMProject(requestBIMProjectList);
        }

        // Evaluate Internal Account
        if (!internalAccountIds.isEmpty()) {
            processEvaluateInternalAccount(internalAccountIds);
        }

        // Update External Account - Subflow : BC_Update External Account record
        if (!externalAccountIds.isEmpty()) {
            processUpdateExternalAccount(externalAccountIds);
        }

        // Create BC_User Bill To record - Subflow : BC_Create BC_User Bill To record
        if (!bcUserBillToIds.isEmpty()) {
            processCreateBcUserBillToRecord(bcUserBillToIds);
        }

        if (!emailsToSend.isEmpty()){
            Messaging.SendEmailResult[] sendResults = Messaging.sendEmail(emailsToSend, false);
        }

    }


    // Update External Account
    @future
    private static void processUpdateExternalAccount(Set<Id> externalAccountIds){    
        // Update External Account - Subflow : BC_Update External Account record
        BCRequestTriggerHelper.updateExternalAccount(externalAccountIds);
    }

    // Create BC_User Bill To record
    @future
    private static void processCreateBcUserBillToRecord(List<Id> bcUserBillToIds){
        // Create BC_User Bill To record - Subflow : BC_Create BC_User Bill To record
        BCRequestTriggerHelper.createBcUserBillToRecord(bcUserBillToIds);
    }

    /*  
        * @ Author : danbik@fiduciarytech.com
        * @ Date : 6/22/2022
        * @ Flow Label : BC_Update Email Alias/Domain fields
        * @ Flow API Name : BC_Update_Email_Alias_Domain_fields
        * @ Type : SubFlow
        * @ Desc : Update email alias, domain with APOC, Contract Holder Contact, Recipient, Requester, Senior Leader email.
    */ 
    private static BC_Request__c processUpdateEmailAliasDomain(BC_Request__c bcRequest) {
        BC_Request__c bc = new BC_Request__c();
        bc.id = bcRequest.id;
        // Evaluate APOC Email Update
        if (!String.isBlank(bcRequest.APOC_Email__c)) { // Update APOC email
            // Assign APOC Email
            String email = bcRequest.APOC_Email__c;

            // Update APOC Alias and Domain
            bc.APOC_Email_Alias__c = getEmail(email, 'alias'); // forAlias
            bc.APOC_Email_Alias_2__c = getEmail(email, 'alias2'); // forAlias2
            bc.APOC_Email_Domain__c = getEmail(email, 'domain'); // forDomain
            bc.APOC_Email_Domain_2__c =  getEmail(email, 'domain2'); // forDomain2
            bc.APOC_Alias_Domain__c = getEmail(email, 'aliasDomain'); // forAliasDomain
            bc.APOC_Alias_Domain_2__c = getEmail(email, 'aliasDomain2'); // forAliasDomain2
        } 
        // Evaluate Contract Holder Email Update
        if (!String.isBlank(bcRequest.Contract_Holder_Contact_Email__c)) { // Update Contract Holder email
            // Assign Contract Holder Email
            String email = bcRequest.Contract_Holder_Contact_Email__c;

            // Update Contract Holder Domain
            bc.Contract_Holder_Email_Domain__c = getEmail(email, 'domain'); // forDomain
            bc.Contract_Holder_Email_Domain_2__c = getEmail(email, 'domain2'); // forDomain2
        } 

        // Evaluate Recipient Email Update
        if (!String.isBlank(bcRequest.Recipient_Email__c)) { // Update Recipient email
            // Assign Requestor Email
            String email = bcRequest.Recipient_Email__c;

            // Update Recipient Alias and Domain
            bc.Recipient_Email_Alias__c = getEmail(email, 'alias'); // forAlias
            bc.Recipient_Email_Alias_2__c = getEmail(email, 'alias2'); // forAlias2
            bc.Recipient_Email_Domain__c = getEmail(email, 'domain'); // forDomain
            bc.Recipient_Email_Domain_2__c = getEmail(email, 'domain2'); // forDomain2
            bc.Recipient_Alias_Domain__c = getEmail(email, 'aliasDomain'); // forAliasDomain
            bc.Recipient_Alias_Domain_2__c = getEmail(email, 'aliasDomain2'); // forAliasDomain2
        } 

        // Evaluate Requestor Email Update
        if (!String.isBlank(bcRequest.Requestor_Email__c)) { // Update Requestor email
            String email = bcRequest.Requestor_Email__c;

            bc.Requestor_Email_Alias__c = getEmail(email, 'alias'); // forAlias
            bc.Requestor_Email_Alias_2__c = getEmail(email, 'alias2'); // forAlias2
            bc.Requestor_Email_Domain__c = getEmail(email, 'domain'); // forDomain
            bc.Requestor_Email_Domain_2__c = getEmail(email, 'domain2'); // forDomain2
            bc.Requestor_Alias_Domain__c = getEmail(email, 'aliasDomain'); // forAliasDomain
            bc.Requestor_Alias_Domain_2__c = getEmail(email, 'aliasDomain2'); // forAliasDomain2
        }

        // Evaluate Senior Leader Email Update
        if (!String.isBlank(bcRequest.SL_Email__c)) { // Update Senior Leader email
            String email = bcRequest.SL_Email__c;

            bc.SL_Email_Alias__c = getEmail(email, 'alias'); // forAlias
            bc.SL_Email_Alias_2__c = getEmail(email, 'alias2'); // forAlias2
            bc.SL_Email_Domain__c = getEmail(email, 'domain'); // forDomain
            bc.SL_Email_Domain_2__c = getEmail(email, 'domain2'); // forDomain2
            bc.SL_Alias_Domain__c = getEmail(email, 'aliasDomain'); // forAliasDomain
            bc.SL_Alias_Domain_2__c = getEmail(email, 'aliasDomain2'); // forAliasDomain2
        }

        return bc;
    }
    /* ========== Subflow BC_Update Email Alias/Domain fields END ========== */

    // BIM 360 CC Request-BIM Project entered
    private static void processReqestBIMProject(List<BC_Request__c> bcRequestList) {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        // Find or create Senior Leader id
        Set<Id> seniorLeaderIds = new Set<Id>();

        // Find or create APOC id
        Set<Id> apocIds = new Set<Id>();

        // Find or create Amazonian Recipient id
        Set<Id> recipientIds = new Set<Id>();

        // Create BC_Request Share
        Set<Id> bcRequestShareIds = new Set<Id>();

        for (BC_Request__c bcRequest : bcRequestList) {
            if ((bcRequest.Record_Type_ID_18_digit__c == amazonianRecordTypeId ||
            bcRequest.Record_Type_ID_18_digit__c == nonAmazonianRecordTypeId) &&
            bcRequest.Is_BIM_Project_Blank__c == true) { //1) BIM Project blank
                // Send TFA Evaluate notification - Subflow : BC_Email communication
                emailsToSend.addAll(EmailCommunication.getEmailMessageList(bcRequest, 'Action needed'));
            } else {
                // Find or create Senior Leader - Subflow : BC_Get or create User record
                seniorLeaderIds.add(bcRequest.id);
                // Evaluate BIM 360 CC request type
                if (bcRequest.Record_Type_ID_18_digit__c == nonAmazonianRecordTypeId) { //1 BIM 360 CC Non-Amazonian
                    // Find or create APOC - Subflow : BC_Get or create User record
                    apocIds.add(bcRequest.id);
                } else {
                    // Find or create Amazonian Recipient - Subflow : BC_Get or create User record
                    recipientIds.add(bcRequest.id);
                }
                // Create BC_Request Share - Subflow : BC_Create BC_Request Share record
                bcRequestShareIds.add(bcRequest.id);                
            }
        }

        // Subflow : BC_Get or create User record.
        if (!seniorLeaderIds.isEmpty()) {

            if (!apocIds.isEmpty()) {
                processUpdateOrCreateFieldByRole(seniorLeaderIds, 'Senior Leader', apocIds, 'APOC', bcRequestShareIds);      
            }
    
            if (!recipientIds.isEmpty()) {
                processUpdateOrCreateFieldByRole(seniorLeaderIds, 'Senior Leader', recipientIds, 'Recipient', bcRequestShareIds);
            }
        }

        if (!emailsToSend.isEmpty()){
            Messaging.SendEmailResult[] sendResults = Messaging.sendEmail(emailsToSend, false);
        }
    }

    private static void processUpdateOrCreateFieldByRole(Set<Id> sLroleIds, String sLrole, Set<Id> roleIds, String role, Set<Id> bcRequestShareIds) {
        System.debug('');
        BCRequestTriggerHelper.updateOrCreateFieldByRole(sLroleIds, sLrole);
        System.debug('');
        BCRequestTriggerHelper.updateOrCreateFieldByRole(roleIds, role);
        System.debug('');
        if (!bcRequestShareIds.isEmpty()) {
            System.debug('');
            processBCRequestShare(bcRequestShareIds);
            processRequestType(bcRequestShareIds);
        }
    }

    /*  
        * @ Author : danbik@fiduciarytech.com
        * @ Date : 6/22/2022
        * @ Flow Label : BC_Create BC_Request Share record
        * @ Flow API Name : BC_Create_BC_Request_Share_record
        * @ Type : SubFlow
        * @ Desc : For Amazonian requests, create a Recipient BC_Request Share record.
                    For Non-Amazonian requests, create a APOC BC_Request Share record.
    */    
    private static void processBCRequestShare(Set<Id> bcRequestShareIds) {
        List<BC_Request__c> bcRequestList = [SELECT Id, Partner_Amazon_Team__c, Amazon_POC__c, Senior_Leader__c, Recipient_User_ID__c, Record_Type_ID_18_digit__c
                                            FROM BC_Request__c
                                            WHERE Id IN :bcRequestShareIds];
        // BC_Request__Share insert List
        List<BC_Request__Share> bcRequestShareToInsert = new List<BC_Request__Share>();

        // Get BC_Request Share records
        List<BC_Request__Share> bcRequestShareList = getBCReqestShare(bcRequestList);

        // Get Senior Leader User record
        List<User> seniorLeaderUserList = getSeniorLeaderUser(bcRequestList);

        // Get APOC User ID
        List<User> apocUser = getUser(bcRequestList);  

        for (BC_Request__c bcRequest : bcRequestList) {
            List<BC_Request__Share> bcRequestShares = new List<BC_Request__Share>();

            for (BC_Request__Share share : bcRequestShareList) {
                if (share.ParentId == bcRequest.Id &&
                share.UserOrGroupId == bcRequest.Partner_Amazon_Team__c) { // Get BC_Request Share records                    
                    bcRequestShares.add(share);
                    // Only the first record
                    break;
                }
            }

            // Partner Amazon Team share type
            if (bcRequestShares.isEmpty()) { // 1 Senior Leader
                BC_Request__Share bcRequestShare = new BC_Request__Share();
                for (User seniorLeader : seniorLeaderUserList) {
                    if (seniorLeader.ContactId == bcRequest.Senior_Leader__c) {
                            bcRequestShare.AccessLevel = 'Read';
                            bcRequestShare.RowCause = 'Manual';
                            bcRequestShare.UserOrGroupId = seniorLeader.Id;
                            bcRequestShare.ParentId = bcRequest.Id;

                        // BC_Request Record Type
                        if (bcRequest.Record_Type_ID_18_digit__c == tokenFlexRecordTypeId ||
                        bcRequest.Record_Type_ID_18_digit__c == amazonianRecordTypeId) { // 1 Amazonian request
                            // Assign Recipient
                                bcRequestShare.AccessLevel = 'Read';
                                bcRequestShare.RowCause = 'Manual';
                                bcRequestShare.UserOrGroupId = bcRequest.Recipient_User_ID__c;
                                bcRequestShare.ParentId = bcRequest.Id;

                        } else if (bcRequest.Record_Type_ID_18_digit__c == nonAmazonianRecordTypeId) { // 2 Non-Amazonian request
                            // Get APOC User ID
                            for (User user : apocUser) {
                                if (user.ContactId == bcRequest.Amazon_POC__c) {
                                    // Assign APOC
                                        bcRequestShare.AccessLevel = 'Edit';
                                        bcRequestShare.RowCause = 'Manual';
                                        bcRequestShare.UserOrGroupId = user.Id;
                                        bcRequestShare.ParentId = bcRequest.Id;

                                    // Only the first record
                                    break;
                                }
                            }               
                        }
                        else {
                            // Do not anything
                        }  
                        // Only the first record
                        break;
                    }
                }
                bcRequestShareToInsert.add(bcRequestShare);
            }       
        }

        // Create BC_Request Share Record
        if (!bcRequestShareToInsert.isEmpty()) {
            // turns off private sharing on BC_Request
            // insert bcRequestShareToInsert;
        }
    }
    /* ========== Subflow BC_Create BC_Request Share record END ========== */
   
    // Identifies BC_Request Record Type
    public static Boolean preApproved = false;
    public static Id userBillToRecordID;
    private static void processRequestType(Set<Id> bcRequestShareIds) {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        List<BC_Request__c> bcRequestList = new List<BC_Request__c>([SELECT Id, Partner_Amazon_Team__c, Partner_Amazon_Team__r.Stage__c, RecordTypeId, Name, APOC_Email__c, Requestor_Email__c, 
                                                                        Recipient_Email_Domain__c, Recipient_Email_Domain_2__c, Contract_Holder_Email_Domain__c, Contract_Holder_Email_Domain_2__c,
                                                                        BIM_Project__c, Record_Type_ID_18_digit__c, Contract_with_Amazon__c, Stage__c
                                                                    FROM BC_Request__c 
                                                                    WHERE Id IN :bcRequestShareIds]);

        List<BC_Request__c> bcRequestToUpdate = new List<BC_Request__c>();

        List<BC_Request__c> amazonianRequestList = new List<BC_Request__c>();

        List<BC_User_Bill_To__c> potentialUserBillList = getPotentialUserBill(bcRequestList);

        Map<Id, Request_Project__c> requestProjectById = getRequestProject(bcRequestShareIds);

        Map<Id, Account> accountById = new Map<Id, Account>([SELECT Id, Stage__c, Reason_for_Inactive_Status__c, Name
                                                            FROM Account]);

        // Find or create 3P vendors id
        List<Id> vendorIds = new List<Id>();
        
        for (BC_Request__c bcRequest : bcRequestList) {
            if (bcRequest.RecordTypeId == nonAmazonianRecordTypeId) { // 1 Non-Amazonian request type
                vendorIds.add(bcRequest.Id);

                String outputVendor;
                
                // Find or create 3P vendors - Subflow : BC_Find or create 3P vendor
                outputVendor = BCRequestTriggerHelper.getFindOrCreate3PVendor(vendorIds);
        
                JSONParser parser = JSON.createParser(outputVendor);

                String contractHolderContactAccountId;
                String accountResult;
                String recipientId;
                String recipientAccountId;

                while(parser.nextToken()!= null) {
                    if(parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                        parser.nextValue();
                        if(parser.getCurrentName() == 'contractHolderContactAccountId') {
                            contractHolderContactAccountId = parser.getText();                      
                            parser.nextValue();
                        } 
                        if (parser.getCurrentName() == 'accountResult') {
                            accountResult = parser.getText();
                            parser.nextValue();
                        } 
                        if (parser.getCurrentName() == 'recipientId') {
                            recipientId = parser.getText();
                            parser.nextValue();
                        } 
                        if (parser.getCurrentName() == 'recipientAccountId') {
                            recipientAccountId = parser.getText();
                        } 
                    }
                }

                List<Account> vendorOutput = [SELECT Id, Stage__c, Reason_for_Inactive_Status__c, Name
                                                FROM Account
                                                WHERE Id = :accountResult]; 
                


                Account vendorAccount = vendorOutput[0];

                BC_Request__c vendor = new BC_Request__c(); 

                vendor.id = bcRequest.id;

                if(contractHolderContactAccountId != '') {
                    vendor.Amazon_Contract_Holder_Vendor__c = contractHolderContactAccountId; // Find_or_create_3P_vendors.outputContractHolderContactAccountID
                }                
                vendor.Recipient_Company__c = recipientAccountId; // Find_or_create_3P_vendors.outputRecipientAccountID
                vendor.Recipient__c =  recipientId; // Find_or_create_3P_vendors.outputRecipientID

                // Evaluate contract holder status
                if (vendorAccount.Stage__c == 'Inactive' &&
                vendorAccount.Reason_for_Inactive_Status__c == 'No TPS') { // 1 Inactive - No TPS
                    // Assign 'Inactive' for other reason/Update Contract Holder Inactive Stage
                    vendor.Stage__c = 'Resolved - Not Completed';
                    vendor.Reason_Not_Completed__c = 'Not TPS compliant';
                    vendor.Status__c = 'Closed';

                    // Send Not Completed email notification - Subflow : BC_Email communication
                    emailsToSend.addAll(EmailCommunication.getEmailMessageList(vendor, 'Request Not Completed notification'));
                    
                } else if (vendorAccount.Stage__c == 'Inactive') { // 2 Inactive - Other
                    //Assign 'Inactive' for other reason/Update Contract Holder Inactive Stage
                    vendor.Stage__c = 'Resolved - Not Completed';
                    vendor.Reason_Not_Completed__c = 'Other';
                    vendor.Status__c = 'Closed';
                    vendor.Other_Reason_Not_Completed__c = 'Look up Primary Vendor Account ' + vendorAccount.Name; // forOtherMessage

                    // Send Not Completed email notification - Subflow : BC_Email communication
                    emailsToSend.addAll(EmailCommunication.getEmailMessageList(vendor, 'Request Not Completed notification'));

                } else {
                    // Evaluate Amazon Team status
                    if (bcRequest.Partner_Amazon_Team__r.Stage__c == 'Active') { // 2 Amazon Team is 'Active'
                        /* Contract Holder pre-approval check - Subflow : BC_Contract Holder pre-approval check */
                        String primaryVendorEmailDomain;
                        String primaryVendorEmailDomain2;

                        if (bcRequest.Contract_with_Amazon__c == true) {
                            primaryVendorEmailDomain = bcRequest.Recipient_Email_Domain__c;
                            primaryVendorEmailDomain2 = bcRequest.Recipient_Email_Domain_2__c;
                        } else {
                            primaryVendorEmailDomain = bcRequest.Contract_Holder_Email_Domain__c;
                            primaryVendorEmailDomain2 = bcRequest.Contract_Holder_Email_Domain_2__c;
                        }

                        for (BC_User_Bill_To__c userBillTo : potentialUserBillList) {
                            if (userBillTo.Amazon_Team__c == bcRequest.Partner_Amazon_Team__c &&
                            userBillTo.Active__c == true &&
                            userBillTo.Access_Type_ID__c == nonAmazonianRecordTypeId &&
                            userBillTo.BIM_360_Project__c == requestProjectById.get(bcRequest.Id).Project_Record_Name__c && 
                            // userBillTo.BIM_360_Project__c == bcRequest.BIM_Project__c && 
                            userBillTo.Primary_Vendor_Email_Domain_2__c == primaryVendorEmailDomain2) { // 1 Matching potential records found
                                if (userBillTo.Primary_Vendor_Email_Domain__c == primaryVendorEmailDomain &&
                                    (userBillTo.Amazon_Team__r.Stage__c == 'Active' ||
                                    userBillTo.Amazon_Team__r.Stage__c == 'Active-Contingent')) { // 1 Existing record found
                                    // Assign Pre-Approval Approved   
                                    preApproved = true;
                                    userBillToRecordID = userBillTo.Id;
                                    // Stop loop
                                    break;
                                } else { // After Last item                                    
                                    preApproved = false;
                                }
                            } else { // 2 No matching potential records found
                                preApproved = false;
                            }
                        }
                        /* ========== BC_Contract Holder pre-approval check END ========== */
                    }    
                    amazonianRequestList.add(bcRequest);
                }
                bcRequestToUpdate.add(vendor);
                
            } else {
                amazonianRequestList.add(bcRequest);
            }
        }

        // Create BC_Request Share Record
        if (!bcRequestToUpdate.isEmpty()) {
            update bcRequestToUpdate;
        }

        // Amazonian request
        if (!amazonianRequestList.isEmpty()) {
            processAmazonianRequest(amazonianRequestList);
        }

        if (!emailsToSend.isEmpty()){
            Messaging.SendEmailResult[] sendResults = Messaging.sendEmail(emailsToSend, false);
        }

        
    }

    // Amazonian request
    private static void processAmazonianRequest(List<BC_Request__c> bcRequestList) {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        // Amazonian request list
        List<BC_Request__c> amazonRequestList = new List<BC_Request__c>();
        Set<Id> amazonRequestIds = new Set<Id>();


        List<BC_Request__c> bcRequestToUpdate = new List<BC_Request__c>();
        
        for (BC_Request__c bcRequest : bcRequestList) {
            BC_Request__c item = new BC_Request__c();
            
            if (bcRequest.Record_Type_ID_18_digit__c == tokenFlexRecordTypeId ||
            bcRequest.Record_Type_ID_18_digit__c == amazonianRecordTypeId) { // 1 Amazonian request
                amazonRequestList.add(bcRequest);
                amazonRequestIds.add(bcRequest.id);

            } else if (bcRequest.Record_Type_ID_18_digit__c == nonAmazonianRecordTypeId &&
            preApproved == true) { // 2 Non-Amazonian request-Pre-Approval
                // Update Non-Amazonian Request-Pre-Approval
                item.id = bcRequest.id;
                item.Existing_Contract_Holder_Access__c = userBillToRecordID;
                item.Pre_Approved__c = true;

                bcRequestToUpdate.add(item);
            } else if (bcRequest.Record_Type_ID_18_digit__c == nonAmazonianRecordTypeId &&
                bcRequest.Partner_Amazon_Team__r.Stage__c == 'Inactive') { // 3 Non-Amazonian request-Team is Inactive
                // Update Stage for team non-approval
                item.id = bcRequest.id;
                item.Reason_Not_Completed__c = 'Not approved';
                item.Stage__c = 'Resolved - Not Completed';
                item.Status__c = 'Closed';

                bcRequestToUpdate.add(item);

                // Send Not Completed email notification - Subflow : BC_Email communication
                emailsToSend.addAll(EmailCommunication.getEmailMessageList(item, 'Request Not Completed notification'));
            } else {
                // Send initial APOC approval notification - Subflow : BC_Email communication
                emailsToSend.addAll(EmailCommunication.getEmailMessageList(bcRequest, 'APOC approval needed'));
                
                // Update Stage to 'Pending APOC Approval'
                item.id = bcRequest.id;
                item.APOC_Last_Approval_Sent__c = datetime.now();
                item.Stage__c = 'Pending APOC Approval';

                bcRequestToUpdate.add(item);
            }
        }

        if (!bcRequestToUpdate.isEmpty()) {
            update bcRequestToUpdate;
        }

        if (!amazonRequestIds.isEmpty()) {
            processEvaluateInternalAccount(amazonRequestIds);
        }    

        if (!emailsToSend.isEmpty()){
            Messaging.SendEmailResult[] sendResults = Messaging.sendEmail(emailsToSend, false);
        }

        
    }

    // Evaluate Internal Account
    private static void processInternalAccount(Set<Id> bcRequestIds) {
        // Evaluate Internal Account - Subflow : BC_Evaluate Internal Account
        BCRequestTriggerHelper.evaluateInternalAccount(bcRequestIds);
    }

    private static void processEvaluateInternalAccount(Set<Id> bcRequestIds) {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        List<BC_Request__c> bcRequestToUpdate = new List<BC_Request__c>();

        processInternalAccount(bcRequestIds);

        for (BC_Request__c bcRequest : [SELECT Id, Record_Type_ID_18_digit__c, RecordTypeId, Stage__c, Name, Requestor_Email__c , APOC_Email__c
                                        FROM BC_Request__c 
                                        WHERE Id IN :bcRequestIds]) {
            BC_Request__c item = new BC_Request__c();

            // BIM 360 Amazonian request
            if (bcRequest.Record_Type_ID_18_digit__c == amazonianRecordTypeId &&
                bcRequest.Stage__c == 'Fulfill Request') { // 1 BIM 360 Amazonian - Fulfill Request
                // Update Amazonian Request-Pre-Approval
                item.id = bcRequest.id;
                item.Pre_Approved__c = true;

                bcRequestToUpdate.add(item);
            } else {
                // Manual fulfillment
                if (bcRequest.RecordTypeId == tokenFlexRecordTypeId  &&
                    bcRequest.Stage__c == 'Fulfill Request') { // 1 Token Flex License request
                    // Send Token Flex license fulfillment notification - Subflow : BC_Email communication
                    emailsToSend.addAll(EmailCommunication.getEmailMessageList(bcRequest, 'Fulfillment ready'));
                }
            }
        }

        if (!bcRequestToUpdate.isEmpty()) {
            update bcRequestToUpdate;
        }
        
        if (!emailsToSend.isEmpty()){
            Messaging.SendEmailResult[] sendResults = Messaging.sendEmail(emailsToSend, false);
        }

        
    }

    // Get APOC user records from BC_User_Bill_To
    private static List<BC_User_Bill_To__c> getPotentialUserBill(List<BC_Request__c> bcRequestList) {
        Set<id> partnerIds = new Set<id>();
        Set<id> bimIds = new Set<id>();
        Set<String> primaryIds = new Set<String>();

        for (BC_Request__c bcRequest : bcRequestList){
            partnerIds.add(bcRequest.Partner_Amazon_Team__c);
            
            if (bcRequest.Contract_with_Amazon__c == true) {
                primaryIds.add(bcRequest.Recipient_Email_Domain_2__c);
            } else {
                primaryIds.add(bcRequest.Contract_Holder_Email_Domain_2__c);
            }
        }

        return [SELECT Id, 
                    Amazon_Team__c, 
                    Active__c, 
                    Access_Type_ID__c,
                    BIM_360_Project__c,
                    Primary_Vendor_Email_Domain_2__c,
                    Primary_Vendor_Email_Domain__c,
                    Amazon_Team__r.Stage__c
                FROM BC_User_Bill_To__c
                WHERE Amazon_Team__c = :partnerIds
                AND Active__c = true
                AND Access_Type_ID__c = :nonAmazonianRecordTypeId
                AND Primary_Vendor_Email_Domain_2__c = :primaryIds];
    }

    // Get APOC user records from BC_User_Bill_To
    private static Map<Id, Request_Project__c> getRequestProject(Set<Id> bcRequestIds) {
        Set<id> ids = new Set<id>();
        Map<Id, Request_Project__c> result = new Map<Id, Request_Project__c>();

        for (Request_Project__c requestProject : [SELECT Id, Request__c, Project_Record_Name__c
                                                  FROM Request_Project__c
                                                  WHERE Request__c IN :bcRequestIds]){
            result.put(requestProject.Request__c, requestProject);
        }

        return result;
    }

    private static List<BC_Request__Share> getBCReqestShare(List<BC_Request__c> newList) {
        Set<id> parentIds = new Set<id>();
        Set<id> userOrGroupIds = new Set<id>();

        for (BC_Request__c bcRequest : newList){
            parentIds.add(bcRequest.Id);
            userOrGroupIds.add(bcRequest.Partner_Amazon_Team__c);
        }

        return [SELECT ParentId, 
                        UserOrGroupId
                FROM BC_Request__Share
                WHERE ParentId = :parentIds
                AND UserOrGroupId = :userOrGroupIds
                AND IsDeleted = false];
    }

    // Get APOC user records from User
    private static List<User> getUser(List<BC_Request__c> newList) {
        Set<id> ids = new Set<id>();

        for (BC_Request__c bcRequest : newList){
            ids.add(bcRequest.Amazon_POC__c);
        }

        return [SELECT Id, 
                    ContactId
                FROM User
                WHERE ContactId IN :ids];
    }

    // Get Senior Leader user records from User
    private static List<User> getSeniorLeaderUser(List<BC_Request__c> newList) {
        Set<id> ids = new Set<id>();

        for (BC_Request__c bcRequest : newList){
            ids.add(bcRequest.Senior_Leader__c);
        }

        return [SELECT Id, 
                    ContactId
                FROM User
                WHERE ContactId IN :ids];
    }

    // ========== BC_BC_Request_record_update_After_Save END ==========


    /*  
        * @ Author : danbik@fiduciarytech.com
        * @ Date : 6/21/2022
        * @ Flow Label : BC_BC_Request record update-After Save-Create BC_Request Share
        * @ Flow API Name : BC_BC_Request_record_update_After_Save_Create_BC_Request_Share
        * @ Trigger : After Update
        * @ Desc : If status is open and pre approved
                    For Non-Amazonian requests, update Pre Approved, Stage BC_Request record.
                    For Amazonian requests, update a Pre Approved BC_Request record.
    */ 
    public static Boolean isFirst = true;
    private static void processCreateBCRequestShare(Map<Id, BC_Request__c> newMap) {
        Set<Id> bcRequestIds = new Set<Id>();
        List<BC_Request__c> bcRequestToUpdate = new List<BC_Request__c>(); 
        if (!isFirst) {
            return;
        }

        for (BC_Request__c bcRequest : newMap.values()) {
            if (bcRequest.Disable_automation__c == false && 
            bcRequest.Pre_Approved__c == true && 
            bcRequest.Status__c == 'Open') { 
                isFirst = false;
                bcRequestIds.add(bcRequest.Id);
            }
        }

        if (!bcRequestIds.isEmpty()) {
            processUpdateBCRequestStage(bcRequestIds);
        }
    }

    @future
    private static void processUpdateBCRequestStage(Set<Id> bcRequestIds) {
        List<BC_Request__c> bcRequestToUpdate = new List<BC_Request__c>(); 

        for (BC_Request__c bcRequest : [SELECT Id, Disable_automation__c, Pre_Approved__c, Status__c, RecordTypeId
                                        FROM BC_Request__c
                                        WHERE Id IN :bcRequestIds]) {
            
            BC_Request__c item = new BC_Request__c();

            // Non-Amazonian request
            if (bcRequest.RecordTypeId == nonAmazonianRecordTypeId) { // 1 Non-Amazonian request
                // Update BC_Request Non-Amazonian
                item.Id = bcRequest.Id;
                item.Pre_Approved__c = false;
                item.Stage__c = 'Fulfill Request';

                bcRequestToUpdate.add(item);
            } else if (bcRequest.RecordTypeId == amazonianRecordTypeId) { // 2 Amazonian request
                // Update BC_Request Amazonian
                item.Id = bcRequest.Id;
                item.Pre_Approved__c = false;

                bcRequestToUpdate.add(item);
            } else {
                // Do not anything
            }
            
        }
        
        if (!bcRequestToUpdate.isEmpty()) {
            update bcRequestToUpdate;
        }  
    }
    /* ========== BC_BC_Request_record_update_After_Save_Create_BC_Request_Share END ========== */


    /*  
        * @ Author : danbik@fiduciarytech.com
        * @ Date : 6/21/2022
        * @ Flow Label : BC_BC_Request record update-After Save-Create External Group and Share
        * @ Flow API Name : BC_BC_Request_record_update_After_Save_Create_External_Group_and_Share
        * @ Trigger : After Update
        * @ Desc : Identifies if the primary vendor on the BC_Request has an existing Group. 
                    If not, it creates a Group for the external (primary vendor) Account and creates an Account Share record. 
                    In a asynchronous transaction, the Amazon POC on the BC_Request is added to the Group. This provides the Amazon POC access to the External Account record.
    */ 
    public static Boolean isExternalGroupShareTime = true;
    private static void processCreateExternalGroupShare(List<BC_Request__c> newList, 
                                                        Map<Id, BC_Request__c> oldMap, 
                                                        Map<Id, BC_Request__c> newMap) {
        // Get contracted company records from Account 
        List<Account> contractAccountList = getAccount(newList);
        
        // Get contracted company group records from Group                                    
        List<Group> contractGroupList = getGroup(contractAccountList);

        // Get APOC user records from User
        List<User> apocUserList = getUser(newList);        
        
        // Create Account Group Member List
        List<String> externalGroupList = new List<String>();

        // Create Account Group and Share Id
        List<Id> accountIds = new List<Id>();

        // List that meets the condition
        List<BC_Request__c> requestList = new List<BC_Request__c>();
                                                        
        if (!isExternalGroupShareTime){
            return;
        }

        for (BC_Request__c item : newMap.values()) {            
            if (item.Disable_Automation__c == false && 
                item.Status__c == UtilityConsts.BC_STATUS_OPEN &&
                item.APOC_Approval__c != oldMap.get(item.id).APOC_Approval__c) { 
                
                isExternalGroupShareTime = false;

                requestList.add(item);

                Id contractHolderVendorID;

                if (item.Contract_with_Amazon__c == true) {
                    contractHolderVendorID = item.Recipient_Company__c;
                } else {
                    contractHolderVendorID = item.Amazon_Contract_Holder_Vendor__c;
                }

                // Get Account             
                for (Account account : contractAccountList) {
                    if (account.Id == contractHolderVendorID) {

                        // Get Group
                        List<Group> contractGroup = new List<Group>();
                        for (Group gr : contractGroupList) {
                            if (gr.id == account.Group_ID_18__c) {
                                contractGroup.add(gr);
                                // Only the first record
                                break;
                            }
                        }

                        if (!contractGroup.isEmpty()) { // 1 Group already exist
                            // Do not anything
                        } else {
                            // Create Account Group and Share - Subflow : BC_Create_Account_Group_and_Share
                            accountIds.add(account.id);
                        }                       

                        // Only the first record
                        break; 
                    }

                    // Only the first record
                    break; 
                }
            }            
        } 
        
        if (!accountIds.isEmpty()) {
            // Create Account Group and Share - Subflow : BC_Create_Account_Group_and_Share
            createAccountGroupShare(accountIds);
        } 
        
        // Get contracted company records from Account 
        List<Account> newContractAccountList = getAccount(requestList);

        // Get contracted company group member records from Group Member
        List<GroupMember> contractGroupMemberList = getGroupMember(apocUserList, newContractAccountList); 

        for (BC_Request__c item : requestList) {  

            Id contractHolderVendorID;

            if (item.Contract_with_Amazon__c == true) {
                contractHolderVendorID = item.Recipient_Company__c;
            } else {
                contractHolderVendorID = item.Amazon_Contract_Holder_Vendor__c;
            }

            // Get Account             
            for (Account account : newContractAccountList) {
                if (account.Id == contractHolderVendorID) {
                    // Get Group Member
                    List<GroupMember> contractGroupMember = new List<GroupMember>();

                    Map<Id, Id> userIdByPOCId = new Map<Id, Id>();

                    // Get User Record
                    for (User apocUser : apocUserList) {
                        if (apocUser.ContactId == item.Amazon_POC__c) {
                            
                            userIdByPOCId.put(item.Amazon_POC__c, apocUser.Id);

                            for (GroupMember gMember : contractGroupMemberList) {
                                if (gMember.UserOrGroupId == apocUser.id &&
                                    gMember.GroupId == account.Group_ID_18__c) {  

                                    contractGroupMember.add(gMember);

                                    // Only the first record
                                    break;
                                }
                            }                                
                        }                            
                        // Only the first record
                        break;
                    }

                    // Identifies group Member exist
                    if (!contractGroupMember.isEmpty()) { // 1 Group Member already exist
                        // Do not anything
                    } else {
                        // Assign APOC to External Group
                        if (userIdByPOCId.containsKey(item.Amazon_POC__c)) {
                            String groupMember = 
                                '{"GroupId": "' + account.Group_ID_18__c + '",' + 
                                '"UserOrGroupId": "' + userIdByPOCId.get(item.Amazon_POC__c) + '"}';
                            externalGroupList.add(groupMember);  
                        }   
                    }

                    // Only the first record
                    break;
                }

                // Only the first record
                break; 
            }
                     
        } 
        
        if (!externalGroupList.isEmpty()) {
             // Create Account Group Member
            createAccountGroupMember(externalGroupList);
        }  
    }
    
    // Create Account Group and Share - Subflow : BC_Create_Account_Group_and_Share
    private static void createAccountGroupShare(List<Id> accountIds){
        List<Account> accountGroupShareList = [SELECT Id, Name, Related_Request__c, Senior_Leader__c, Record_Type_ID_18__c, Vendor_Amazon_Partner__c
                                                FROM Account
                                                WHERE Id IN :accountIds];

        AccountTriggerHelper.createAccountGroupandShare(accountGroupShareList); 
    }

    // Create Account Group Member
    @future
    private static void createAccountGroupMember(List<String> externalGroupList){
        List<GroupMember> groupMemberToInsert = new List<GroupMember>();

        
        for (String externalGroup : externalGroupList) {
            JSONParser parser = JSON.createParser(externalGroup);
            GroupMember contractGroupMember= new GroupMember();

            while(parser.nextToken()!= null) {
                if(parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                    parser.nextValue();
                    if (parser.getText() == null) continue;

                    if(parser.getCurrentName() == 'GroupId') {
                        contractGroupMember.GroupId = parser.getText();
                        parser.nextValue();
                    } 
                    if (parser.getCurrentName() == 'UserOrGroupId') {
                        contractGroupMember.UserOrGroupId = parser.getText();
                    } 
                }
            }
            groupMemberToInsert.add(contractGroupMember);
        }

        if (!groupMemberToInsert.isEmpty()) {
            insert groupMemberToInsert;
        }
    }

    // Get contracted company records from Account 
    private static List<Account> getAccount(List<BC_Request__c> newList) {
        Set<id> ids = new Set<id>();

        for (BC_Request__c bcRequest : newList){
            if (bcRequest.Contract_with_Amazon__c == true) {
                ids.add(bcRequest.Recipient_Company__c);
            } else {
                ids.add(bcRequest.Amazon_Contract_Holder_Vendor__c);
            }
        }

        return [SELECT Id, 
                    Group_ID_18__c, 
                    Related_Request__c
                FROM Account
                WHERE Id IN :ids];
    }

    // Get contracted company group records from Group 
    private static List<Group> getGroup(List<Account> accountList) {
        Set<id> ids = new Set<id>();

        for (Account acc : accountList){
            ids.add(acc.Group_ID_18__c);
        }

        return [SELECT Id
                FROM Group
                WHERE Id IN :ids];
    }

    // Get contracted company group member records from Group Member
    private static List<GroupMember> getGroupMember(List<User> userList, List<Account> accountList) {
        Set<id> userIds = new Set<id>();
        Set<id> accountIds = new Set<id>();

        for (User user : userList){
            userIds.add(user.Id);
        }
        
        for (Account account : accountList){
            accountIds.add(account.Group_ID_18__c);
        }

        return [SELECT Id, 
                    UserOrGroupId,
                    GroupId
                FROM GroupMember
                WHERE UserOrGroupId = :userIds
                AND GroupId = :accountIds];
    }

    /* ========== BC_BC_Request_record_update_After_Save_Create_External_Group_and_Share END ========== */


    public static String getEmail(String email, String emailStringCondition) {
        /* 
            Email is a required value.
            Email Required Format : ***@***  
        */
        if (email != null) {
            String[] emailId = email.split('@');
            String emailDomain = email.subStringBetween('@' , '.'); 

            switch on emailStringCondition {
                when 'alias' { // forAlias
                    return emailId[0].toLowercase();
                }

                when 'alias2' { // forAlias2
                    return  emailId[0].toLowerCase().left(2);
                }

                when 'domain' { // forDomain
                    return ('@' + emailDomain + '.');
                }

                when 'domain2' { // forDomain2
                    return ('@' + emailDomain.left(2));
                }

                when 'aliasDomain' { // forAliasDomain
                    return (emailId[0].toLowerCase() + ';@' + emailDomain + '.');
                }

                when 'aliasDomain2' { // forAliasDomain2
                    return (emailId[0].toLowerCase().left(2) + ';@' + emailDomain.left(2));
                }

                when 'companyEmail' {
                    return ('@' + emailDomain.toLowerCase() + '.');
                }
    
                when 'emailAliasDomain' { // forEmailAliasDomain
                    return (emailId[0] + ';@' + emailDomain + '.');
                }

                when 'emailAliasDomain2' { // forEmailAliasDomain2   
                    return (emailId[0].left(2) + ';@' +  emailDomain.left(2));
                }
            }
        }
        
        return '';
    }
   

    private static List<String> getValidRecordTypeIdList() {
        List<String> result = new List<String>();

        for(String item : CalloutUtility.AUTODESK_BIM360.Valid_Record_Type__c.trim().split('\\s*,\\s*')) {
            result.add(Schema.SObjectType.BC_Request__c.getRecordTypeInfosByDeveloperName().get(item).getRecordTypeId());
        }

        return result;
    }

    private static List<Id> getValidRecordTypeIdsAmazonUserInfoIntegration() {
        List<Id> result = new List<String>();

        result.add(amazonianRecordTypeId);
        result.add(nonAmazonianRecordTypeId);
        result.add(tokenFlexRecordTypeId);

        return result;
    }

    private static API_Log__c createGetProjectInfoApiLog(Request_Project__c requestProject) {
        API_Log__c result = new API_Log__c();

        result.Status__c = 'Pending';
        result.BC_Request__c = requestProject.Request__c;
        result.BC_BIM_Project__c = requestProject.Project_Record_Name__c;
        result.Method_Name__c = 'getProjectInfo';
        result.Log_Type__c = 'Outbound';
        return result;
    }

    private static API_Log__c createGetProjectRolesApiLog(Request_Project__c requestProject) {
        API_Log__c result = new API_Log__c();

        result.Status__c = 'Pending';
        result.BC_Request__c = requestProject.Request__c;
        result.BC_BIM_Project__c = requestProject.Project_Record_Name__c;
        result.Method_Name__c = 'getProjectRoles';
        result.Log_Type__c = 'Outbound';

        return result;
    }

    private static API_Log__c createAmazonUserInfoApiLog(BC_Request__c bcRequest) {
        API_Log__c result = new API_Log__c();

        result.Status__c = 'Pending';
        result.BC_Request__c = bcRequest.Id;
        result.Method_Name__c = 'getAmazonUserInfo';
        result.Log_Type__c = 'Outbound';

        return result;
    }

    public static void processRelatedRequestProject(List<BC_Request__c> newList, Map<Id, BC_Request__c> oldMap) {

        Set<Id> requestsToAutoReject = new Set<Id>();
        for (BC_Request__c request : newList) {
            if (request.Stage__c == 'Resolved - Not Completed'    && oldMap.get(request.Id).Stage__c != request.Stage__c &&
                request.Status__c == 'Closed'                     && oldMap.get(request.Id).Status__c != request.Status__c &&
                request.Reason_Not_Completed__c == 'Not approved' && oldMap.get(request.Id).Reason_Not_Completed__c != request.Reason_Not_Completed__c) {
                requestsToAutoReject.add(request.Id);
            }
        }

        // no request projects to auto reject
        if (requestsToAutoReject.isEmpty()) return;

        // reject request projects
        List<Request_Project__c> requestProjects = [
            SELECT Id, Approval_Status__c
            FROM Request_Project__c
            WHERE Request__c IN :requestsToAutoReject
        ];

        for (Request_Project__c rp : requestProjects) {
            rp.Approval_Status__c = 'Rejected';
        }
        if(!requestProjects.isEmpty()) {
            update requestProjects;
        }

    }
}