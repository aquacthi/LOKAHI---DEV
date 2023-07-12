public without sharing class BCRequestTriggerHelper {
    /*
        Flow to apex
        
        Flow Label: BC_Create BC_User Bill To record
      
        Description: This subflow is use for Created BC_User Bill To record when request is completed.
                     When BCRequest stage is 'resolved- complete' and whether amazonian/non amazonian request, 
                     create BC_User_Bill info and send completed request notification.
        Author : jasons@fiduciarytech.com
        Date   : 2022-06-10
    */
    public static void createBcUserBillToRecord (List<Id> bcUserBillToIds) {
        List<BC_User_Bill_To__c> bcUserBillToInsert = new List<BC_User_Bill_To__c>();

        List<BC_Request__c> bcRequestList = getRequestsForUserBillTo(bcUserBillToIds);
        
        for (BC_Request__c bc : bcRequestList) {
            for (Request_Project__c rp : bc.Request_Projects__r) {
                bcUserBillToInsert.add(createBCUserBillTo(bc, rp));
            }
        }

        if (!bcUserBillToInsert.isEmpty()) {
           insert bcUserBillToInsert;
        }
    }


      /*
        Flow to apex
        
        Flow Label: BC_Update External Account record
      
        Description: This subflow is use for When BcRequest stage is 'resolved-complete' and non-amazonian requst, 
                     assign TPS and NDA on External Account records and Update.
        Author : jasons@fiduciarytech.com
        Date   : 2022-06-10
    */

    public static void updateExternalAccount(Set<Id> externalAccountIds) {
        List<Account> accListToUpdate = new List<Account>();
        
        List<BC_Request__c> bcRequestList = [SELECT Id, Contract_with_Amazon__c, Recipient_Company__r.stage__c, Recipient_Company__c, Vendor_Has_NDA__c, APOC_User_ID__c, Amazon_Contract_Holder_Vendor__r.Stage__c, Amazon_Contract_Holder_Vendor__c
        FROM Bc_Request__c
        WHERE Id IN: externalAccountIds];

        for (BC_Request__c bc : bcRequestList) {
            if (bc.Contract_with_Amazon__c == true && 
                bc.Recipient_Company__r.stage__c == 'New' &&  
                bc.Recipient_Company__c != null) {
                Account acc = new Account (
                    id = bc.Recipient_Company__c,
                    Has_NDA__c = bc.Vendor_Has_NDA__c,
                    Has_Amazon_Contract__c = true,
                    Send_TPS_Notification__c = true,                    
                    Vendor_Amazon_Partner__c = bc.APOC_User_ID__c
                );

                accListToUpdate.add(acc);
                    
            } else if (bc.Contract_with_Amazon__c == false) {
                if (bc.Amazon_Contract_Holder_Vendor__r.Stage__c == 'New' && 
                bc.Amazon_Contract_Holder_Vendor__c != null) {
                    Account acc = new Account (
                        id = bc.Amazon_Contract_Holder_Vendor__c,
                        Has_NDA__c = bc.Vendor_Has_NDA__c,
                        Has_Amazon_Contract__c = true,
                        Send_TPS_Notification__c = true,
                        Vendor_Amazon_Partner__c = bc.APOC_User_ID__c
                    );

                    Account acc2 = new Account (
                        id = bc.Recipient_Company__c,
                        Has_NDA__c = false,
                        Send_TPS_Notification__c = false,
                        Has_Amazon_Contract__c = false,               
                        Vendor_Amazon_Partner__c = bc.APOC_User_ID__c,
                        Stage__c = 'Active'
                    );
                
                    accListToUpdate.add(acc);
                    accListToUpdate.add(acc2);
                    
                } else if (bc.Recipient_Company__r.stage__c == 'New' &&  
                bc.Recipient_Company__c != null) {
                    
                    Account acc = new Account (
                        id = bc.Recipient_Company__c,
                        Has_NDA__c = false,
                        Has_Amazon_Contract__c = false,
                        Send_TPS_Notification__c = false,                    
                        Vendor_Amazon_Partner__c = bc.APOC_User_ID__c,
                        Stage__c = 'Active'
                    ); 
                    
                    Account acc2 = new Account(
                        id = bc.Amazon_Contract_Holder_Vendor__c,
                        Has_NDA__c = bc.Vendor_Has_NDA__c,
                        Has_Amazon_Contract__c = true,
                        Send_TPS_Notification__c = true,
                        Vendor_Amazon_Partner__c = bc.APOC_User_ID__c                 
                    );

                    accListToUpdate.add(acc);
                    accListToUpdate.add(acc2);
                }
            }
        }
        
        if (!accListToUpdate.isEmpty()) {
            update accListToUpdate;
        }
    }

     /*
        Flow to apex
        
        Flow Label: BC_Find or create 3P vendor
      
        Description: This subflow is use for when BC_RequestRecord Type is Non-Amazonian record , 
                     search record whether vendor is 'Recipient' or 'Contract Holder' then assign to External Account records.
                     To assign mutiple values, use Wrapper Class.
        Author : jasons@fiduciarytech.com
        Date   : 2022-06-10
    */

    public static String getFindOrCreate3PVendor(List<id> VendorIds) {
        Map<String, String> VendorValues = new Map<String,String>();
        String contractHolderContactAccountId;
        String accountResult;
        String recipientId;
        String recipientAccountId;
        Id ExternalRecordTypeId = AccountTriggerHandler.accountExternalRecordTypeId;

        List<BC_Request__c> bcReuqestListManageVendor = new List<BC_Request__c>(); 
        List<Bc_Request__c> bcRequestList = [SELECT Id, Contract_with_Amazon__c 
                                             FROM Bc_Request__c
                                             WHERE Id IN: VendorIds];

        Map<Id,String> bcRequestMapRecipientCompany = new Map<Id,String>();
        Map<Id,String> bcRequestMapManageVendor = new Map<Id,String>();

        for (Bc_Request__c bc : bcRequestList) {
            bcRequestMapRecipientCompany.put(bc.Id,'Recipient');
        }
        
        List<Contact> contactList = searchContact(bcRequestMapRecipientCompany,'Recipient'); 

        List<Account> externalRecipientAccList = [SELECT Id, Stage__c, Reason_for_Inactive_Status__c, RecordTypeId 
                                                FROM Account 
                                                WHERE RecordTypeId = :ExternalRecordTypeId];

        for (Bc_Request__c bc : bcRequestList) {
           
            for (Contact cc : contactList) {
                recipientId = cc.Id;
                recipientAccountId = cc.AccountId;

                if (bc.Contract_with_Amazon__c == true) {  // Recipient company
                    for (Account acc : externalRecipientAccList) {
                        if (acc.Id == recipientAccountId) {
                            accountResult = acc.Id;
                            break;                    
                        } else {
                            
                        }
                    } 
                } else { // Manage vendor company
                    bcRequestMapManageVendor.put(bc.Id,'Contract Holder');
                    bcReuqestListManageVendor.add(bc);
                }    
            }
        } 

        if(!bcRequestMapManageVendor.isEmpty()) {
            List<Contact> contactContractHolder = searchContact(bcRequestMapManageVendor,'Contract Holder');
            List<Account> externalContractHolderAccList = [SELECT Id, Stage__c, Reason_for_Inactive_Status__c, RecordTypeId FROM Account WHERE RecordTypeId = :ExternalRecordTypeId];
            for (Bc_Request__c bc : bcReuqestListManageVendor) {
                String outputContractHolderContactId = contactContractHolder[0].Id; // outputContactID
                String outputContractHolderContactAccountId = contactContractHolder[0].AccountId;// outputContactAccountID
                contractHolderContactAccountId = outputContractHolderContactAccountId;
                for (Account acc : externalContractHolderAccList) {
                    if (acc.Id == outputContractHolderContactAccountId) {
                        accountResult = acc.Id;
                        
                        break;                    
                    }
                }   
            } 
        }

        contractHolderContactAccountId = contractHolderContactAccountId == null ?  '' : contractHolderContactAccountId; 

        return '{"contractHolderContactAccountId": "' + contractHolderContactAccountId + '",' +
        '"accountResult": "' + accountResult + '",' + 
        '"recipientId": "' + recipientId + '",' +
        '"recipientAccountId": "' + recipientAccountId + '"}';
    }

    /*
        Flow Label: BC_Get or create Contact record
        Flow Name: BC_Get_or_create_Contact_record
        Flow Type: Subflow called by other flows

        Author : annkim@fiduciarytech.com
        Date   : 2022-06-08
    */

    // ex) Map<Id,String> -> Map<BC_Request__c.Id,inputVendor>;
    public static List<Contact> searchContact(Map<Id,String> vendorByBcRequestId, String inputVendor) {
        Map<Id,BC_Request__c> bcRequestById = new Map<Id,BC_Request__c>([SELECT Id, Contract_Holder_Alias_Domain__c, Contract_Holder_Alias_Domain_2__c, Contract_Holder_Contact_Email__c, Contract_Holder_Contact_First_Name__c, Contract_Holder_Contact_Last_Name__c, Contract_Holder_Email_Domain__c, Contract_Holder_Email_Domain_2__c,  Recipient_Alias_Domain__c, Recipient_Alias_Domain_2__c, Recipient_Email__c, Recipient_First_Name__c, Recipient_Last_Name__c, Recipient_Email_Domain__c, Recipient_Email_Domain_2__c
                                                                        FROM BC_Request__c 
                                                                        WHERE Id IN: vendorByBcRequestId.keyset()]);

        Map<String, Set<String>> emailDomainByVendor = getAliasDomainByVendor(bcRequestById.values(), vendorByBcRequestId);     
    
        List<Contact> contactToInsert = new List<Contact>();
        List<Contact> result = new List<Contact>();
        Map<Id,String> vendorByBcRequestIdToSearch = new Map<Id,String>();
        
        Map<String, List<Contact>> contactListByRecipient = getContactByAliasDomain(emailDomainByVendor.get('Recipient'));
        Map<String, List<Contact>> contactListByContractHolder = getContactByAliasDomain(emailDomainByVendor.get('Contract Holder'));

        for (BC_Request__c bcRequest : bcRequestById.values()) {
            String vendor = vendorByBcRequestId.get(bcRequest.Id);
            Map<String,String> userInfo = AccountTriggerHelper.getExtenalUserInfo(vendor, bcRequest);
            String aliasDomain = userInfo.get('aliasDomain');
            String aliasDomain2 = userInfo.get('aliasDomain2');

            List<Contact> contactList = vendor == 'Contract Holder' ? contactListByContractHolder.get(aliasDomain2) : contactListByRecipient.get(aliasDomain2);

            if (contactList == null) {
                vendorByBcRequestIdToSearch.put(bcRequest.Id, vendor);
                continue;
            } else {
                String ctAliasDomain;

                for (Contact ct : contactList) {
                    if (ct.Alias_Domain__c == aliasDomain) {
                        ctAliasDomain = ct.Alias_Domain__c;
                        result.add(ct);
                        break;
                    }
                }

                if (String.isBlank(ctAliasDomain)) {
                    vendorByBcRequestIdToSearch.put(bcRequest.Id, vendor);
                    ctAliasDomain = '';
                }
            }
        }

        Map<Id,Account> accountById = AccountTriggerHelper.searchAccount(vendorByBcRequestIdToSearch);

        Set<Id> bcRequestSet = new Set<Id>();

        for (Account acc : accountById.values()) {
            bcRequestSet.add(acc.Related_Request__c);
        }

        bcRequestSet.addAll(vendorByBcRequestId.keyset());

        List<BC_Request__c> searchBcrequestList = new List<BC_Request__c>([SELECT Id, Contract_Holder_Alias_Domain__c, Contract_Holder_Alias_Domain_2__c, Contract_Holder_Contact_Email__c, Contract_Holder_Contact_First_Name__c, Contract_Holder_Contact_Last_Name__c, Contract_Holder_Email_Domain__c, Contract_Holder_Email_Domain_2__c,  Recipient_Alias_Domain__c, Recipient_Alias_Domain_2__c, Recipient_Email__c, Recipient_First_Name__c, Recipient_Last_Name__c, Recipient_Email_Domain__c, Recipient_Email_Domain_2__c
                                                                        FROM BC_Request__c 
                                                                        WHERE Id IN: bcRequestSet]);

        Map<Id,BC_Request__c> bcRequestByRelatedRequest = new Map<Id,BC_Request__c>(searchBcrequestList);

        for (Account acc : accountById.values()) {
            // String vendor = vendorByBcRequestId.get(acc.Related_Request__c);
            BC_Request__c bcRequest = bcRequestByRelatedRequest.get(acc.Related_Request__c);

            if (bcRequest != null) {
                Map<String,String> userInfo = AccountTriggerHelper.getExtenalUserInfo(inputVendor, bcRequest);

                String vendorEmail = userInfo.get('email');
                String vendorFirstName = userInfo.get('firstName');
                String vendorLastName = userInfo.get('lastName');

                contactToInsert.add(new Contact(AccountId = acc.Id,
                                                Email = vendorEmail,
                                                FirstName = vendorFirstName,
                                                LastName = vendorLastName,
                                                Related_Request__c = bcRequest.Id));                
            }
        }

        if (!contactToInsert.isEmpty()) {
            insert contactToInsert;
        }

        result.addAll(contactToInsert);  

        return result;
    }

    private static Map<String, List<Contact>> getContactByAliasDomain(Set<String> aliasDomainSet) {
        Map<String, List<Contact>> contactByAliasDomain = new Map<String, List<Contact>>();
        
        for (Contact ct: [SELECT Id, Alias_Domain__c, Alias_Domain_2__c, AccountId, Related_Request__c
                          FROM Contact 
                          WHERE Alias_Domain_2__c = :aliasDomainSet]) {

            String aliasDomain2 = ct.Alias_Domain_2__c;           
            Boolean isContainKey = contactByAliasDomain.containsKey(aliasDomain2);

            if (aliasDomain2 != null) {
                if (!isContainKey) {
                    List<Contact> contactList = new List<Contact>{ct};

                    contactByAliasDomain.put(aliasDomain2, contactList);
                } else {
                    List<Contact> exsitContactList = contactByAliasDomain.get(aliasDomain2);
                                
                    exsitContactList.add(ct);
                    contactByAliasDomain.put(aliasDomain2, exsitContactList);
                }                
            } else {
                continue;
            }
        }

        return contactByAliasDomain;
    }

    private static Map<String, Set<String>> getAliasDomainByVendor(List<BC_Request__c> bcRequestList, Map<Id,String> vendorByBcRequestId) {    
        Map<String, Set<String>> aliasDomainByVendor = new Map<String, Set<String>>();
        
        for (BC_Request__c bcRequest : bcRequestList) {
       
            String vendor = vendorByBcRequestId.get(bcRequest.Id);
            Boolean isContainKey = aliasDomainByVendor.containsKey('Recipient') || aliasDomainByVendor.containsKey('Contract Holder');

            Map<String,String> userInfo = AccountTriggerHelper.getExtenalUserInfo(vendor, bcRequest);
            String aliasDomain2 = userInfo.get('aliasDomain2');

            if (!isContainKey) {
                Set<String> aliasDomainSet = new Set<String>{aliasDomain2};

                aliasDomainByVendor.put(vendor, aliasDomainSet);
            } else {
                Set<String> aliasDomainSet = aliasDomainByVendor.get(vendor);
                            
                aliasDomainSet.add(aliasDomain2);
                aliasDomainByVendor.put(vendor, aliasDomainSet);
            }
        }
        
        return aliasDomainByVendor;
    }

    /*
        Flow to apex
        
        Flow Label: BC_Evaluate Internal Account
      
        Description:  This subflow is use for when BC_Request records put in, 
                      depending on each account stage, assign and update related Account/BC_Request records. 
        Author : jasons@fiduciarytech.com
        Date   : 2022-06-10
    */

    public static void evaluateInternalAccount(Set<Id> bcRequestSet) {
        List<Messaging.SingleEmailMessage> emailsToSend  = new List<Messaging.SingleEmailMessage>();  
        List<BC_Request__c> bcRequestListToUpdate = new List<BC_Request__c>();
        List<Account> accListToUpdate = new List<Account>();
        
        List<BC_Request__c> bcRequestList = [SELECT Stage__c, Reason_Not_Completed__c, Other_Reason_Not_Completed__c, Status__c, Request_error_description__c, Partner_Amazon_Team__c
        FROM Bc_Request__c
        WHERE Id IN: bcRequestSet];

        List<Account> externalAccList = getExternalAccount(bcRequestList);
 
        for (BC_Request__c item: bcRequestList) {
            BC_Request__c bc = new BC_Request__c();
            bc.id = item.id;

            Id inputAccountID = item.Partner_Amazon_Team__c;

            Account acc = new Account();
            for (Account externalAcc : externalAccList) {
                if (externalAcc.Id == inputAccountID) {
                    acc = externalAcc;
                    break;
                }
            }

            if (acc.Stage__c == 'New') { //1. New
                Account newacc = new Account();
                newacc.Stage__c = 'Pending SL Approval';
                newacc.Id = inputAccountID;
                newacc.Last_SL_Approval_Sent__c = Datetime.now();
                newacc.Group_Created__c = !String.isBlank(acc.Group_ID_18__c);

                emailsToSend.addAll(EmailCommunication.getEmailMessageList(acc, 'Senior Leader approval'));
                bc.Stage__c = 'Pending Approval';

                accListToUpdate.add(newacc);
                emailsToSend.addAll(EmailCommunication.getEmailMessageList(bc, 'Pending Team Approval notification'));
               
            } else if (acc.Stage__c == 'Pending SL Approval' || 
                        acc.Stage__c == 'Pending Finance Approval') { //2. Pending Approval
                bc.Stage__c = 'Pending Approval';
 
                emailsToSend = EmailCommunication.getEmailMessageList(bc, 'Pending Team Approval notification');
             
            } else if (acc.Stage__c == 'Active') { //3. Active 
                bc.Stage__c = 'Fulfill Request'; 
         
            } else if (acc.Stage__c == 'Inactive') { //4. Inactive
                // Remove auto deactivation logic 
                if (acc.Reason_for_Inactive_Status__c == 'No response from Senior Leader') { // 4-1 No response from Senior Leader
                    bc.Reason_Not_Completed__c = 'No response from Senior Leader';     
                } else if (acc.Reason_for_Inactive_Status__c == 'Not approved') { // 4-2 Not approved
                    bc.Reason_Not_Completed__c = 'Not approved';             
                } else if (acc.Reason_for_Inactive_Status__c == 'No response from Finance Manager') { // 4-4 No response from Finance Manager
                    bc.Reason_Not_Completed__c = 'No response from Finance Manager';         
                } else { // 4-3 Other , 5.Default Outcome
                    bc.Reason_Not_Completed__c = 'Other';           
                    if (!String.isBlank(acc.Other_Reason_Inactive__c) == true) { // forOtherReason
                        bc.Other_Reason_Not_Completed__c = 'No identified reason provided; see Account ';
                    } else {
                        bc.Other_Reason_Not_Completed__c = acc.Other_Reason_Inactive__c;
                    }
                } 
                bc.Stage__c = 'Resolved - Not Completed';
                bc.Status__c = 'Closed';

                emailsToSend.addAll(EmailCommunication.getEmailMessageList(bc, 'Request Not Completed notification'));        

            } else { // 5. Default OutCome
                bc.Request_error_description__c = 'Check Account Stage';
            }        
            bcRequestListToUpdate.add(bc);
        }

        if(!accListToUpdate.isEmpty()) {
            update accListToUpdate;
        }

        if (!bcRequestListToUpdate.isEmpty()) {
            update bcRequestListToUpdate;
        }

        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend, false);
        }
     }
        

    private static String getPrimaryVendorEmailDomain(BC_Request__c bc) {
        if (bc.Contract_with_Amazon__c == true) {
            return bc.Recipient_Email_Domain__c;
        } else {
            return bc.Contract_Holder_Email_Domain__c;
        }

    }

    private static String getPrimaryVendorEmailDomain2(BC_Request__c bc) {
        if (bc.Contract_with_Amazon__c == true) {
            return bc.Recipient_Email_Domain_2__c;
        } else {
            return bc.Contract_Holder_Email_Domain_2__c;
        }
    }

    private static List<Account> getExternalAccount(List<BC_Request__c> bcRequestList) {
        Set<Id> inputAccountIds = new Set<Id>();

        for (BC_Request__c bc: bcRequestList) {
            inputAccountIds.add(bc.Partner_Amazon_Team__c);
        }

        return [SELECT Name, stage__c, Id, Senior_Leader_Email__c,
                       Last_SL_Approval_Sent__c, Group_Created__c, RecordTypeId,
                       Reason_for_Inactive_Status__c, Other_Reason_Inactive__c, Group_ID_18__c
                FROM Account 
                WHERE ID IN: inputAccountIds];
    }

   /*
        Flow Label: BC_Get or create User record
        Flow Name: BC_Get_or_create_User_record

        Author : annkim@fiduciarytech.com
        Date   : 2022-06-08
    */

    public static void updateOrCreateFieldByRole(Set<Id> bcRequestSet, String userRole) {

        List<BC_Request__c> bcRequestToUpdate = new List<BC_Request__c>();        
        List<BC_Request__c> userNotFoundBcRequestList = new List<BC_Request__c>();
        List<BC_Request__c> bcRequestList = Database.query(getQuery(bcRequestSet));
        List<BC_Request__c> defaultTeamAccountIdBcRequestList = new List<BC_Request__c>();

        Map<String, List<User>> userByAlias = getUserByAlias(bcRequestList,userRole);
        Map<Id,User> userBybcRequestId = new Map<Id,User>();
        Id bcDefaultTeamAccountId = AccountTriggerHelper.retunrbcDefaultTeamAccountId('Amazon');

        for (BC_Request__c item : bcRequestList) {
            Map<String,String> userInfo = getUserInfoByRole(userRole, item);
            List<User> existingUserList = userByAlias.get(userInfo.get('emailAlias'));
            BC_Request__c bcRequest = new BC_Request__c();

            if (existingUserList == null){
                userNotFoundBcRequestList.add(item);
            } else {
                for (User u : existingUserList) {
                    if (u.UserType != 'PowerPartner') {
                        bcRequest.Id = item.Id;
                        bcRequest.Stage__c = 'Request error';
                        bcRequest.Request_error_description__c = 'User record found but not a Partner user type';
                        
                        bcRequestToUpdate.add(bcRequest);
                    } else {
                        if (userRole == 'Senior Leader' && 
                            u.Contact.AccountId == bcDefaultTeamAccountId) {
                            defaultTeamAccountIdBcRequestList.add(item);
                        }

                        userBybcRequestId.put(item.Id, u);
                    }
                }
            }
        }

        if (!userNotFoundBcRequestList.isEmpty()) {
            bcRequestToUpdate.addAll(updateUserNotExsiting(userRole, userNotFoundBcRequestList));
        }

        if (!userBybcRequestId.isEmpty()) {
            bcRequestToUpdate.addAll(updateUserExiting(userRole, userBybcRequestId, defaultTeamAccountIdBcRequestList));
        }

        if (!bcRequestToUpdate.isEmpty()) {
            update bcRequestToUpdate;
        }
    }

    private static String getQuery(Set<Id> bcRequestSet)
    {
        Schema.SObjectType object_type = Schema.getGlobalDescribe().get('BC_Request__c');
        
        DescribeSObjectResult describe_result = object_type.getDescribe();
        
        List<String> allfields = new List<String>(describe_result.fields.getMap().keySet());
        String selectAllQuery;
        
        selectAllQuery = ' SELECT ' + String.join(allfields, ',' ) + ' FROM BC_Request__c' + ' WHERE Id IN :bcRequestSet';
        return selectAllQuery;
    }

    private static Map<String, List<User>> getUserByAlias(List<BC_Request__c> bcRequestList, String userRole) {
        Set<String> bcRequestAliasSet = new Set<String>();
        
        for (BC_Request__c bcRequest : bcRequestList) {
            Map<String,String> userInfo = getUserInfoByRole(userRole, bcRequest);
            bcRequestAliasSet.add(userInfo.get('emailAlias'));
        }

        Map<String, List<User>> groupUsers = new Map<String, List<User>>();
        
        for (User u: [SELECT Id, IsActive, ContactID, UserType, FederationIdentifier, Contact.Id, Contact.AccountId
                      FROM User 
                      WHERE FederationIdentifier = :bcRequestAliasSet
                      AND IsActive = true]) {

            String userAlias = u.FederationIdentifier;
            Id userId = u.Id;            
            Boolean isContainKey = groupUsers.containsKey(userAlias);

            if (!isContainKey) {
                List<User> userList = new List<User>{u};

                groupUsers.put(userAlias, userList);
            } else {
                List<User> exsitUserList = groupUsers.get(userAlias);
                            
                exsitUserList.add(u);
                groupUsers.put(userAlias, exsitUserList);
            }
        }
        
        return groupUsers;
    }

    public static Map<String,String> getUserInfoByRole(String userRole, BC_Request__c bcRequest) {
        Map<String, String> userInfo = new Map<String,String>();

        String firstName;
        String lastName;
        String email;
        String emailAlias;
        String costCenter;

        switch on userRole {
            when 'Senior Leader' {
                firstName = bcRequest.SL_First_Name__c;
                lastName = bcRequest.SL_Last_Name__c;
                email = bcRequest.SL_Email__c;
                emailAlias = bcRequest.SL_Email_Alias__c;
                costCenter = bcRequest.SL_Cost_Center__c;
            }

            when 'Recipient' {
                firstName = bcRequest.Recipient_First_Name__c;
                lastName = bcRequest.Recipient_Last_Name__c;
                email = bcRequest.Recipient_Email__c;
                emailAlias = bcRequest.Recipient_Email_Alias__c;
                costCenter = bcRequest.Recipient_Cost_Center__c;
            }           
            
            when 'APOC' {
                firstName = bcRequest.APOC_First_Name__c;
                lastName = bcRequest.APOC_Last_Name__c;
                email = bcRequest.APOC_Email__c;
                emailAlias = bcRequest.APOC_Email_Alias__c;
                costCenter = bcRequest.APOC_Cost_Center__c;
            }
        }

        userInfo.put('firstName', firstName);
        userInfo.put('lastName', lastName);
        userInfo.put('email', email);
        userInfo.put('emailAlias', emailAlias);
        userInfo.put('costCenter', costCenter);

        return userInfo;
    }

    private static List<BC_Request__c> updateUserNotExsiting(String userRole, List<BC_Request__c> bcRequestList) {
        Map<Id,BC_Request__c> bcRequestById = new Map<Id,BC_Request__c>(bcRequestList);
        List<Contact> contactToInsert = new List<Contact>();
        List<Account> accountSeniorLeaderListToUpdate = new List<Account>();

        switch on userRole {
            when 'Senior Leader' {
                // sub flow
                // BC_Get or create Account record
                List<Account> accountList = AccountTriggerHelper.createAccount(bcRequestList);

                if (!accountList.isEmpty()) {
                    insert accountList;
                }
                
                for (Account item : accountList) {
                    BC_Request__c bcRequest = bcRequestById.get(item.Related_Request__c);
                    // sub flow
                    // BC_Get or create Contact record
                    contactToInsert.add(createContact(userRole, bcRequest, item));                
                }
            }

            when 'Recipient', 'APOC' {
                for (BC_Request__c item : bcRequestById.values()) {
                    // sub flow
                    // BC_Get or create Contact record
                    contactToInsert.add(createContact(userRole, item, null));
                }
            }
        }

        if (!contactToInsert.isEmpty()) {
            insert contactToInsert;
        }

        List<User> userToInsert = createUserList(userRole, contactToInsert, bcRequestById);
        
        if (!userToInsert.isEmpty()) {
            insert userToInsert;
        }

        if (userRole == 'Senior Leader') {
            List<Account> accountToUpdate = new List<Account>();
            Map<Id, Contact> contactById = new Map<Id, Contact>(contactToInsert);

            for (User item : userToInsert) {
                Account acc = new Account();
                Contact ct = contactById.get(item.ContactId);
                if (ct.AccountId != null){
                    acc.Id = ct.AccountId;
                } 

                acc.Senior_Leader__c = item.Id;

                accountToUpdate.add(acc);
            }

            if (!accountToUpdate.isEmpty()) {
                update accountToUpdate;
            }            
        }

        List<BC_Request__c> bcRequestToUpdate = new List<BC_Request__c>();
        Map<String,BC_Request__c> bcRequestByAlias = new Map<String,BC_Request__c>();

        for (BC_Request__c item : bcRequestList) {
            Map<String,String> userInfo = getUserInfoByRole(userRole, item);
            bcRequestByAlias.put(userInfo.get('emailAlias').toLowercase(), item);
        }

        Map<Id, Contact> contactById = new Map<Id, Contact>(contactToInsert);

        for (User item : userToInsert) {
            BC_Request__c bcRequest = bcRequestByAlias.get(item.FederationIdentifier);

            Contact ct = contactById.get(item.ContactId);
            if (ct.AccountId != null) {
                bcRequestToUpdate.add(createBcRequest(UserRole, bcRequest, ct, item));
            }
        }

        return bcRequestToUpdate;
    }

    private static List<BC_Request__c> updateUserExiting(String userRole, Map<Id,User> userBybcRequestId, List<BC_Request__c> defaultTeamAccountIdBcRequestList) {
        List<BC_Request__c> bcRequestList = [SELECT Id, SL_Email_Domain__c, SL_Email_Domain_2__c, Amazon_Manager_Email__c, Amazon_Manager_First_Name__c, Amazon_Manager_Last_Name__c, Amazon_POC__c, APOC_User_ID__c, Recipient_User_ID__c, Recipient_Company__c, Recipient__c, Senior_Leader__c, Partner_Amazon_Team__c
                                            FROM BC_Request__c 
                                            WHERE Id IN: userBybcRequestId.keySet()];
        switch on userRole {
            when 'Senior Leader' {
                if (!defaultTeamAccountIdBcRequestList.isEmpty()){
                    // sub flow
                    // BC_Get or create Account record
                    List<Account> accountList = AccountTriggerHelper.createAccount(defaultTeamAccountIdBcRequestList);

                    if (!accountList.isEmpty()) {
                        insert accountList;
                    }

                    List<Contact> contactToUpdate = new List<Contact>();
                    List<Account> accountToUpdate = new List<Account>();

                    for (Account item : accountList) {
                        User u = userBybcRequestId.get(item.Related_Request__c);
                        Account acc = new Account();

                        contactToUpdate.add(new Contact(Id = u.ContactId, 
                                                        AccountId = item.Id));

                        accountToUpdate.add(new Account(Id = item.Id,
                                                        // isPartner = true,
                                                        Senior_Leader__c = u.Id));
                    }

                    if (!contactToUpdate.isEmpty()) {
                        update contactToUpdate;
                    }

                    if (!accountToUpdate.isEmpty()) {
                        update accountToUpdate;
                    }
                }
            }

            when 'Recipient', 'APOC' {
                // sub flow
                // BC_Get or create Account record
                AccountTriggerHelper.checkContactAccount(userBybcRequestId);
            }
        }

        List<BC_Request__c> bcRequestToUpdate = new List<BC_Request__c>();

        Set<Id> contactSet = new Set<Id>();

        for (Id bcRequestId : userBybcRequestId.keySet()) {
            User u = userBybcRequestId.get(bcRequestId);

            if (u.ContactId != null) {
                contactSet.add(u.ContactId);
            } else {
                continue;
            }
        }

        Map<Id,Contact> contactById = new Map<Id,Contact>([SELECT Id, AccountId 
                                                          FROM Contact 
                                                          WHERE Id IN: contactSet]);

        for (BC_Request__c item : bcRequestList) {
            User u = userBybcRequestId.get(item.Id);
            Contact ct = contactById.get(u.ContactId);

            if (ct.AccountId != null) {
                bcRequestToUpdate.add(createBcRequest(userRole, item, ct, u));
            }
        }

        return bcRequestToUpdate;
    }

    /*
        Flow Label: BC_Get or create Contact record
        Flow Name: BC_Get_or_create_Contact_record
        Flow Type: Subflow called by other flows

        Author : annkim@fiduciarytech.com
        Date   : 2022-06-08
    */

    private static Contact createContact(String userRole, BC_Request__c bcRequest, Account acc) {
        Contact ct = new Contact();

        ct.Related_Request__c = bcRequest.Id;

        switch on userRole {
            when  'Senior Leader' {
                if (acc != null) {
                    ct.AccountId = acc.Id;
                }

                ct.Email = bcRequest.SL_Email__c;
                ct.FirstName = bcRequest.SL_First_Name__c;
                ct.LastName = bcRequest.SL_Last_Name__c;
            }

            when  'Recipient' {
                ct.AccountId = bcRequest.Partner_Amazon_Team__c;
                ct.Email = bcRequest.Recipient_Email__c;
                ct.FirstName = bcRequest.Recipient_First_Name__c;
                ct.LastName = bcRequest.Recipient_Last_Name__c;             
            }

            when  'APOC' {
                ct.AccountId = bcRequest.Partner_Amazon_Team__c;
                ct.Email = bcRequest.APOC_Email__c;
                ct.FirstName = bcRequest.APOC_First_Name__c;
                ct.LastName = bcRequest.APOC_Last_Name__c;             
            }
        }

        return ct;
    }

    private static List<User> createUserList(String userRole, List<Contact> contactList,Map<Id,BC_Request__c> bcRequestById) {
        List<User> result = new List<User>();
        List<Organization> org = getOrganization();

        for (Contact item : contactList) {
            BC_Request__c bcRequest = bcRequestById.get(item.Related_Request__c);

            Map<String,String> userInfo = getUserInfoByRole(userRole, bcRequest);
            String firstName = userInfo.get('firstName');
            String lastName = userInfo.get('lastName');
            String email = userInfo.get('email');
            String emailAlias = userInfo.get('emailAlias');
            String costCenter = userInfo.get('costCenter');

            User u = new User();

            u.Alias = firstName.substring(0, 1).trim() + lastName.substring(0, lastName.length() < 5 ? lastName.length() : 5).trim();
            u.ProfileId = AccountTriggerHelper.retunrProfieId('BC_Partner Community User');
            u.Email = org[0].IsSandbox ? email + '.invalid' : email;
            u.EmailEncodingKey = 'ISO-8859-1';
            u.FirstName = firstName;
            u.LastName = lastName;

            u.LanguageLocaleKey = 'en_US';
            u.LocaleSidKey = 'en_US';
            u.TimeZoneSidKey = 'America/Los_Angeles';
            u.FederationIdentifier = emailAlias.toLowercase();
            u.ContactId = item.Id;
            u.Username = email + System.Label.BC_Username_Suffix;
            u.Cost_Center__c = costCenter;
            u.Team_Administrator__c = true;

            result.add(u);
        }

        return result;
    }

    private static BC_Request__c createBcRequest(String UserRole, BC_Request__c bcRequest, Contact ct, User u) {
        BC_Request__c result = new BC_Request__c();

        Id userId = u.Id;
        Id accountId = ct.AccountId;
        Id contactId = ct.Id;

        result.Id = bcRequest.Id;

        switch on UserRole {
            when 'Senior Leader' {
                result.Senior_Leader__c = contactId;
                result.Partner_Amazon_Team__c = accountId;
            }

            when 'Recipient' {
                result.Recipient_User_ID__c = userId;
                result.Recipient_Company__c = accountId;
                result.Recipient__c = contactId;
            }           
            
            when 'APOC' {
                result.Amazon_POC__c = contactId;
                result.APOC_User_ID__c = userId;
            }
        }

        return result;
    }


    // Get Organization Details
    private static List<Organization> getOrganization() {
        return [SELECT Id, IsSandbox
                FROM Organization
                LIMIT 1];
    }

    public static BC_User_Bill_To__c createBCUserBillTo(BC_Request__c bc, Request_Project__c requestProject) {
        String vendorId = bc.Contract_with_Amazon__c ? bc.Recipient_Company__c : bc.Amazon_Contract_Holder_Vendor__c;
        return new BC_User_Bill_To__c(            
            Active__c                                = true,
            Related_Request__c                       = bc.Id,
            Amazon_Team__c                           = bc.Partner_Amazon_Team__c,
            Member_Account__c                        = bc.Recipient_Company__c,
            Amazon_Contract_Holder_Vendor__c         = bc.Amazon_Contract_Holder_Vendor__c,
            Access_Type_ID__c                        = bc.Record_Type_ID_18_digit__c,
            Access_Type_Name__c                      = bc.Record_Type_Name__c,
            Amazon_Contract_Holder_Email_Domain__c   = bc.Contract_Holder_Email_Domain__c,
            Amazon_Contract_Holder_Email_Domain_2__c = bc.Contract_Holder_Email_Domain_2__c,
            BIM_360_Project__c                       = requestProject.Project_Record_Name__c,
            BIM_360_Project_ID__c                    = requestProject.Project_Record_Name__c,
            Member__c                                = bc.Recipient__c,
            Member_Account_Domain__c                 = bc.Recipient_Company__r.Email_Domain__c,
            Member_Account_Domain_2__c               = bc.Recipient_Company__r.Email_Domain_2__c,
            Member_Email_Alias_Domain__c             = bc.Recipient__r.Alias_Domain__c,
            Member_Email_Alias_Domain_2__c           = bc.Recipient__r.Alias_Domain_2__c,
            Primary_Vendor_Account_ID__c             = vendorId,
            Request_Name__c                          = bc.Existing_Contract_Holder_Access__r.Request_Name__c,
            Primary_Vendor_Email_Domain__c           = getPrimaryVendorEmailDomain(bc),
            Primary_Vendor_Email_Domain_2__c         = getPrimaryVendorEmailDomain2(bc),
            Member_Email__c                          = bc.Recipient_Email__c
        );                       
    }


    public static List<BC_Request__c> getRequestsForUserBillTo(List<Id> bcUserBillToIds) {
        return [
            SELECT Id, 
                Contract_with_Amazon__c, 
                Partner_Amazon_Team__c, 
                Recipient_Company__c, 
                Amazon_Contract_Holder_Vendor__c,  
                Record_Type_ID_18_digit__c, 
                Record_Type_Name__c, 
                Contract_Holder_Email_Domain__c, 
                Contract_Holder_Email_Domain_2__c,
                // BLONG - Commented out since we're not using anymore
                // BIM_Project__c, 
                // BIM_Project__r.Id, 
                Recipient__c, 
                Recipient_Company__r.Email_Domain__c, 
                Recipient_Company__r.Email_Domain_2__c, 
                Recipient__r.Alias_Domain__c, 
                Recipient__r.Alias_Domain_2__c, 
                Existing_Contract_Holder_Access__r.Request_Name__c, 
                Recipient_Email__c, 
                Recipient_Email_Domain__c, 
                Recipient_Email_Domain_2__c,
                (
                    SELECT Id, 
                        Project_Record_Name__c
                    FROM Request_Projects__r
                ) 
            FROM Bc_Request__c
            WHERE Id IN: bcUserBillToIds];
    }

}