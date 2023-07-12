public without sharing class AccountTriggerHelper {

    public static Id retunrProfieId(String profileName) 
    {
        List<Profile> profileList = [SELECT Id, name FROM profile WHERE name = :profileName];

        if (profileList.size() == 1) {
            return profileList[0].id;
        } else {
            //Need exception
        }
        return null;
    }

    public static Id retunrbcDefaultTeamAccountId(String accountName) 
    {
        List<Profile> profileList = [SELECT Id, name FROM profile WHERE name = :accountName];

        if (profileList.size() == 1) {
            return profileList[0].id;
        } else {
            //Need exception
        }
        return null;
    }

    /*
        Flow Label: BC_Create Group Member
        Flow Name: BC_Create_Group_Member

        Description:
        It is called from the "BC_Account_record_update_After_Save_Add_Account_Group_Members" and "BC_Account_record_update_After_Save" and creates Senior Leader and Finance Manager as a group member.

        Author : annkim@fiduciarytech.com
        Date   : 2022-05-30
    */

    @future
    public static void createGroupMember(Set<Id> accountSet) {
        List<GroupMember> groupMemberToInsert = new List<GroupMember>();

        for (Account acc: [SELECT Id, Finance_Manager__c, Senior_Leader__c, Group_ID_18__c  
                          FROM Account 
                          WHERE Id IN: accountSet]) {

            if (acc.Group_ID_18__c != null) {
                GroupMember groupMem = new GroupMember();
                groupMem.GroupId = acc.Group_ID_18__c;

                // first, check finance manager exist, insert field
                if (!String.isBlank(acc.Finance_Manager__c)) {
                    groupMem.UserOrGroupId = acc.Finance_Manager__c;

                // second, check senior manager exist, insert field
                } else if (!String.isBlank(acc.Senior_Leader__c)) {
                    groupMem.UserOrGroupId = acc.Senior_Leader__c;
                }

                groupMemberToInsert.add(groupMem);
            }
        }

        System.debug('----------createGroupmember accountSet---------');
        System.debug(accountSet);
        if (!groupMemberToInsert.isEmpty()) {
            System.debug('----------insert createGroupmember---------');
            System.debug(groupMemberToInsert);
            insert groupMemberToInsert;
        }
    }

    public static void createGroupMemberForBatch(Set<Id> accountSet) {
        List<GroupMember> groupMemberToInsert = new List<GroupMember>();

        for (Account acc: [SELECT Id, Finance_Manager__c, Senior_Leader__c, Group_ID_18__c  
                          FROM Account 
                          WHERE Id IN: accountSet]) {

            if (acc.Group_ID_18__c != null) {
                GroupMember groupMem = new GroupMember();
                groupMem.GroupId = acc.Group_ID_18__c;

                // first, check finance manager exist, insert field
                if (!String.isBlank(acc.Finance_Manager__c)) {
                    groupMem.UserOrGroupId = acc.Finance_Manager__c;

                // second, check senior manager exist, insert field
                } else if (!String.isBlank(acc.Senior_Leader__c)) {
                    groupMem.UserOrGroupId = acc.Senior_Leader__c;
                }

                groupMemberToInsert.add(groupMem);
            }
        }

        if (!groupMemberToInsert.isEmpty()) {
            insert groupMemberToInsert;
        }
    }

    public static Id userBIMCentralAdminId() {
        return [SELECT Id FROM User WHERE Name = 'BIMCentral Admin' LIMIT 1].Id;
    }

    /** 
        Flow to apex
        
        Flow Label: BC_Create Account Group and Share
        Flow Name: BC_Create_Account_Group_and_Share

        Description: Segment one flow into multiple methods(createGroup, updateAccountAndCreateShareField, deleteBcRequstShare)

        Author : annkim@fiduciarytech.com
        Date   : 2022-05-31
    */

    public static void createAccountGroupandShare(List<Account> accountList) {
        Map<String, Group> groupByName = createGroup(accountList);
        
        updateAccountAndCreateShareField(accountList, groupByName);
        deleteBcRequstShare(accountList);
    }

    @Testvisible
    private static Map<String, Group> createGroup(List<Account> accountList) {
        List<Group> groupToInsert = new List<Group>();
        Set<String> accountNameSet = new Set<String>();
        Map<String, Group> groupByName = new Map<String, Group>();

        for (Account acc: accountList) {
            String devName = acc.Name.replace('-', '_');
            accountNameSet.add(devName);
        }

        Map<String, Group> groupByDevName = getGroupByDevName(accountNameSet);

        for (Account acc: accountList) {

            String accName = acc.Name;

            // check default account name is right or not
            if (!String.isBlank(accName) && accName.replace('-', '_') != accName) {
                String devName = accName.replace('-', '_');
                
                Group g = new Group();
                g.DeveloperName = devName;
                // g.OwnerId = userBIMCentralAdminId();
                g.Name = accName;

                // Check account is external
                if (devName.contains('EX_')) {
                    Group existingGroup = groupByDevName.get(acc.Name);

                    if (existingGroup != null) {
                        groupByName.put(existingGroup.Name, existingGroup);
                        continue;
                    }
                }

                groupToInsert.add(g);
            } else {
                continue;
            }
        }

        if (!groupToInsert.isEmpty()) {
            insert groupToInsert;
        }

        for (Group g: groupToInsert) {
            groupByName.put(g.Name, g);
        }
        
        return groupByName;
    }

    private static Map<String, Group> getGroupByDevName(Set<String> accountNameSet) {
        Map<String, Group> groupByName = new Map<String, Group>();

        for (Group g: [SELECT Id, Name, DeveloperName
                       FROM Group
                       WHERE DeveloperName = :accountNameSet]) {
            groupByName.put(g.Name, g);
        }

        return groupByName;
    }

    @Testvisible
    private static void updateAccountAndCreateShareField(List<Account> accountList, Map<String, Group> groupByName) {
        List<Account> accountToUpdate = new List<Account>();
        List<AccountShare> accountShareToInsert = new List<AccountShare>();
        List<BC_Request__Share> bcRequestShareToInsert = new List<BC_Request__Share>();

        for (Account acc: accountList) {
            Group g = groupByName.get(acc.Name);
            Id groupOrUserId = getUserOrGroupId(acc, g);

            if (groupOrUserId != null) {
                accountToUpdate.add(new Account(Id = acc.Id, 
                                                Group_ID_18__c = groupOrUserId));

                accountShareToInsert.add(new AccountShare(AccountAccessLevel = 'Edit', 
                                                        AccountId = acc.Id, 
                                                        CaseAccessLevel = 'None',
                                                        // ContactAccessLevel = 'Read',
                                                        OpportunityAccessLevel = 'None',
                                                        UserOrGroupId = groupOrUserId));

                bcRequestShareToInsert.add(new BC_Request__Share(ParentId = acc.Related_Request__c, 
                                                                UserOrGroupId = g.Id, 
                                                                AccessLevel = 'Read'));                
            }
        }

        if (!accountToUpdate.isEmpty()) {
            update accountToUpdate;
        }

        if (!accountShareToInsert.isEmpty()) {
            insert accountShareToInsert;
        }

        if (!bcRequestShareToInsert.isEmpty()) {
            // insert bcRequestShareToInsert;
        }
    }

    @Testvisible
    private static void deleteBcRequstShare(List<Account> accountList) {
        Map<Id, Account> accountsByRelatedRequest = new Map<Id, Account>();

        for (Account acc: accountList) {
            accountsByRelatedRequest.put(acc.Related_Request__c, acc);
        }

        List<BC_Request__Share> bcRequestShareToDelete = new List<BC_Request__Share>();

        for (BC_Request__Share bcRequestShare : [SELECT Id, IsDeleted, ParentId, UserOrGroupId
                                                FROM BC_Request__Share 
                                                WHERE ParentId IN: accountsByRelatedRequest.keySet()
                                                AND IsDeleted = false]) {

            Account acc = accountsByRelatedRequest.get(bcRequestShare.ParentId);

            if (acc.Senior_Leader__c == bcRequestShare.UserOrGroupId) {
                bcRequestShareToDelete.add(bcRequestShare);
            } else {
                continue;
            }
        }

        if (!bcRequestShareToDelete.isEmpty()) {
            delete bcRequestShareToDelete;
        }
    }

    @Testvisible
    private static Id getUserOrGroupId (Account acc, Group g) {
        if (acc.Record_Type_ID_18__c == AccountTriggerHandler.accountInternalRecordTypeId) {
            return  g.Id;
        }
        
        if (acc.Record_Type_ID_18__c == AccountTriggerHandler.accountExternalRecordTypeId) {
            return g.Id;
        } else {
            return acc.Vendor_Amazon_Partner__c;
        }
    }

    // Flow Name: BC_Create_Account_Group_and_Share End

        /**
        Flow to apex
        
        Flow Label: BC_Update Open BC_Request records
        Flow Name: BC_Update_Open_BC_Request_records

        Description: Updates Request records when an Accounts stage has changed to "Inactive" or "Active".

        Author : annkim@fiduciarytech.com
        Date   : 2022-06-02
    */

    public static void updateOpenBcRequestIfAccountActiveOrInactive(List<Account> accountList) {
        Map<Id,Account> accountById = new Map<Id,Account>(accountList);
        List<BC_Request__c> bcRequestToUpdate = new List<BC_Request__c>();
        
        for (BC_Request__c bcRequest : [SELECT Id, Partner_Amazon_Team__c, Status__c, IsDeleted
                                        FROM BC_Request__c 
                                        WHERE Partner_Amazon_Team__c IN: accountById.keySet()
                                        AND Status__c = :UtilityConsts.BC_STATUS_OPEN
                                        AND IsDeleted = false]) {
            Account acc = accountById.get(bcRequest.Partner_Amazon_Team__c);
            BC_Request__c newBcRequest = new BC_Request__c();

            newBcRequest.Id = bcRequest.Id;
            // Change bc request status by account stage.
            switch on acc.Stage__c {
                when 'Active' {
                    newBcRequest.Stage__c = UtilityConsts.BC_STAGE_FULFILL_REQUEST;
                    newBcRequest.Status__c = UtilityConsts.BC_STATUS_OPEN;

                    bcRequestToUpdate.add(newBcRequest);
                }

                when 'Inactive' {
                    newBcRequest.Stage__c = UtilityConsts.BC_STAGE_RESOLVED_NOT_COMPLETED;
                    newBcRequest.Status__c = UtilityConsts.BC_STATUS_CLOSED;

                    if (acc.Reason_for_Inactive_Status__c == UtilityConsts.ACC_REASON_FOR_INACTIVE_STATUS_NO_RESPONSE_FROM_SENIOR_LEADER) {
                        newBcRequest.Reason_Not_Completed__c = UtilityConsts.BC_REASON_NOT_COMPLETED_NO_RESPONSE_FROM_SENIOR_LEADER;
                    } else if (acc.Reason_for_Inactive_Status__c == UtilityConsts.ACC_REASON_FOR_INACTIVE_STATUS_NO_RESPONSE_FROM_FINANCE_MANAGER){
                        newBcRequest.Reason_Not_Completed__c = UtilityConsts.BC_REASON_NOT_COMPLETED_NO_RESPONSE_FROM_FINANCE_MANAGER;
                    } else {
                        newBcRequest.Reason_Not_Completed__c = UtilityConsts.ACC_REASON_FOR_INACTIVE_STATUS_NOT_APPROVED;
                    }

                    bcRequestToUpdate.add(newBcRequest);
                }
            }           
        }

        if (!bcRequestToUpdate.isEmpty()) { 
            update bcRequestToUpdate;
        }
    }

    /*
        Flow Label: BC_Get or create Account record
        Flow Name: BC_Get_or_create_Account_record
        Flow Type: Subflow called by other flows

        Author : annkim@fiduciarytech.com
        Date   : 2022-06-08
    */

    public static List<Account> createAccount(List<BC_Request__c> bcRequestList) {
        List<Account> accountList = new List<Account>();
        Id bimCentralAdminId = userBIMCentralAdminId();

        for (BC_Request__c item : bcRequestList) {
            Account acc = new Account();

            acc.Related_Request__c = item.Id;
            acc.RecordTypeId = AccountTriggerHandler.accountInternalRecordTypeId;
            acc.Stage__c = UtilityConsts.ACC_STAGE_NEW;
            acc.Email_Domain__c = item.SL_Email_Domain__c;
            acc.Email_Domain_2__c = item.SL_Email_Domain_2__c;
            acc.Name = 'Amazon Account-' + item.Name;
            acc.Amazon_User_Manager_Email__c = item.Amazon_Manager_Email__c;
            acc.Amazon_User_Manager_First_Name__c = item.Amazon_Manager_First_Name__c;
            acc.Amazon_User_Manager_Last_Name__c = item.Amazon_Manager_Last_Name__c;
            acc.OwnerId = bimCentralAdminId;
            // acc.IsPartner = true;

            accountList.add(acc);
        }

        return accountList;
    }

    /*
        Flow Label: BC_Get or create Account record
        Flow Name: BC_Get_or_create_Account_record
        Flow Type: Subflow called by other flows

        Author : annkim@fiduciarytech.com
        Date   : 2022-06-08
    */

    // Map<Id,User> -> Map<BC_Request__c.Id, User>
    public static void checkContactAccount(Map<Id,User> userBybcRequestId) {
        List<Contact> contactToUpdate = new List<Contact>();

        for (BC_Request__c bcRequest : [SELECT Id, Partner_Amazon_Team__c
                                  FROM BC_Request__c 
                                  WHERE Id IN: userBybcRequestId.keySet()]) {
            User u = userBybcRequestId.get(bcRequest.Id);

            if (bcRequest.Partner_Amazon_Team__c != u.Contact.AccountId){
                contactToUpdate.add(new Contact(Id = u.ContactId, 
                                                AccountId = bcRequest.Partner_Amazon_Team__c));
            } else {
                continue;
            }
        }

        if (!contactToUpdate.isEmpty()) {
            update contactToUpdate;
        }
    }

    /*
        Flow Label: BC_Get or create Account record
        Flow Name: BC_Get_or_create_Account_record
        Flow Type: Subflow called by other flows

        Author : annkim@fiduciarytech.com
        Date   : 2022-06-08
    */

    // Map<Id,String> -> Map<BC_Request__c.Id, InputVendor>
    public static Map<Id,Account> searchAccount(Map<Id,String> vendorByBcRequestId) {
        List<BC_Request__c> bcRequestList = [SELECT Id, Recipient_Email_Domain__c, Recipient_Email_Domain_2__c, Recipient_Company_Entered__c, RecordTypeId, Contract_Holder_Email_Domain__c, Contract_Holder_Email_Domain_2__c, Recipient_First_Name__c, Recipient_Last_Name__c, Recipient_Email__c, Recipient_Alias_Domain__c, Recipient_Alias_Domain_2__c, Name, Contract_Holder_Contact_First_Name__c, Contract_Holder_Contact_Last_Name__c, Contract_Holder_Contact_Email__c, Amazon_Contract_Holder_Entered__c, Contract_Holder_Alias_Domain__c, Contract_Holder_Alias_Domain_2__c
                                            FROM BC_Request__c 
                                            WHERE Id IN: vendorByBcRequestId.keySet()];
        
        Map<String, Set<String>> emailDomainByVendor = getEmailDomainByVendor(bcRequestList, vendorByBcRequestId);
        Id bimCentralAdmin = AccountTriggerHelper.userBIMCentralAdminId();
    
        List<Account> accountToInsert = new List<Account>();

        Map<String, List<Account>> AccountListByRecipient = getAccountByEmailDomain(emailDomainByVendor.get('Recipient'));
        Map<String, List<Account>> AccountListByContractHolder = getAccountByEmailDomain(emailDomainByVendor.get('Contract Holder'));
        Map<Id,Account> accountByBcRequestId = new Map<Id,Account>();

        Id amazonianTypeId = BCRequestTriggerHandler.amazonianRecordTypeId;
        Id nonAmazonianTypeId = BCRequestTriggerHandler.nonAmazonianRecordTypeId;
        Id tokenFlexTypeId = BCRequestTriggerHandler.tokenFlexRecordTypeId;

        for (BC_Request__c bcRequest : bcRequestList) {
            Id recordTypeId = bcRequest.RecordTypeId;
            Boolean isAmazonian = recordTypeId == amazonianTypeId || recordTypeId == tokenFlexTypeId;
            Boolean nonAmazonian = recordTypeId == nonAmazonianTypeId;

            String vendor = vendorByBcRequestId.get(bcRequest.Id);
            Map<String,String> userInfo = getExtenalUserInfo(vendor, bcRequest);
            String emailDomain = userInfo.get('emailDomain');
            String emailDomain2 = userInfo.get('emailDomain2');

            List<Account> accountList = isAmazonian || nonAmazonian && vendor == 'Recipient' ? AccountListByRecipient.get(emailDomain2) : AccountListByContractHolder.get(emailDomain2);
            String accountVendor = isAmazonian ? '' : vendor;

            if (accountList == null) {
                accountToInsert.add(createVendorAccount(bcRequest, accountVendor, bimCentralAdmin));
                continue;
            } else {
                String accountEmailDomain;

                for (Account acc : accountList) {
                    if (emailDomain == acc.Email_Domain__c) {
                        accountEmailDomain = acc.Email_Domain__c;
                        accountByBcRequestId.put(bcRequest.Id, acc);
                        break;
                    } else {
                        continue;
                    }
                }

                if (String.isBlank(accountEmailDomain)) {
                    accountToInsert.add(createVendorAccount(bcRequest, accountVendor, bimCentralAdmin));
                    accountEmailDomain = '';
                }
            }
        }

        if (!accountToInsert.isEmpty()){
            insert accountToInsert;

            for (Account acc : accountToInsert) {
                accountByBcRequestId.put(acc.Related_Request__c, acc);
            }            
        }

        return accountByBcRequestId;
    }

    private static Map<String, Set<String>> getEmailDomainByVendor(List<BC_Request__c> bcRequestList, Map<Id,String> vendorByBcRequestId) {    
        Map<String, Set<String>> emailDomainByVendor = new Map<String, Set<String>>();
        
        for (BC_Request__c bcRequest : bcRequestList) {
       
            String vendor = vendorByBcRequestId.get(bcRequest.Id);
            Boolean isContainKey = emailDomainByVendor.containsKey('Recipient') || emailDomainByVendor.containsKey('Contract Holder');
            Map<String,String> userInfo = getExtenalUserInfo(vendor, bcRequest);
            String emailDomain2 = userInfo.get('emailDomain2');

            if (!isContainKey) {
                Set<String> emailDomain2Set = new Set<String>{emailDomain2};

                emailDomainByVendor.put(vendor, emailDomain2Set);
            } else {
                Set<String> emailDomain2Set = emailDomainByVendor.get(vendor);
                            
                emailDomain2Set.add(emailDomain2);
                emailDomainByVendor.put(vendor, emailDomain2Set);
            }
        }
        
        return emailDomainByVendor;
    }

    private static Account createVendorAccount(BC_Request__c bcRequest, String vendor, Id bimCentralAdmin) {
        Account acc = new Account();

        acc.Related_Request__c = bcRequest.Id;
        acc.RecordTypeId = AccountTriggerHandler.accountExternalRecordTypeId;
        acc.Email_Domain__c = bcRequest.Recipient_Email_Domain__c;
        acc.Email_Domain_2__c = bcRequest.Recipient_Email_Domain_2__c;
        acc.Name = 'Vendor Account-' + bcRequest.Name;
        acc.OwnerId = bimCentralAdmin;
        // acc.IsPartner = true;

        if (vendor == 'Recipient') {
            acc.Vendor_Company_Name__c = bcRequest.Recipient_Company_Entered__c;
        }

        if (vendor == 'Contract Holder') {
            acc.Email_Domain__c = bcRequest.Contract_Holder_Email_Domain__c;
            acc.Email_Domain_2__c = bcRequest.Contract_Holder_Email_Domain_2__c;
            acc.Vendor_Company_Name__c = bcRequest.Amazon_Contract_Holder_Entered__c;
        }

        return acc;
    }

    public static Map<String, String> getExtenalUserInfo(String vendor, BC_Request__c bcRequest) {
        Map<String, String> userInfo = new Map<String,String>();

        String firstName;
        String lastName;
        String email;
        String emailDomain;
        String emailDomain2;
        String aliasDomain;
        String aliasDomain2;

        switch on vendor {
            when 'Contract Holder' {
                firstName = bcRequest?.Contract_Holder_Contact_First_Name__c;
                lastName = bcRequest?.Contract_Holder_Contact_Last_Name__c;
                email = bcRequest?.Contract_Holder_Contact_Email__c;
                emailDomain = bcRequest?.Contract_Holder_Email_Domain__c;
                emailDomain2 = bcRequest?.Contract_Holder_Email_Domain_2__c;
                aliasDomain = bcRequest?.Contract_Holder_Alias_Domain__c;
                aliasDomain2 = bcRequest?.Contract_Holder_Alias_Domain_2__c;
            }

            when 'Recipient', '' {
                firstName = bcRequest?.Recipient_First_Name__c;
                lastName = bcRequest?.Recipient_Last_Name__c;
                email = bcRequest?.Recipient_Email__c;
                emailDomain = bcRequest?.Recipient_Email_Domain__c;
                emailDomain2 = bcRequest?.Recipient_Email_Domain_2__c;
                aliasDomain = bcRequest?.Recipient_Alias_Domain__c;
                aliasDomain2 = bcRequest?.Recipient_Alias_Domain_2__c;
            }
        }

        userInfo.put('firstName', firstName);
        userInfo.put('lastName', lastName);
        userInfo.put('email', email);
        userInfo.put('emailDomain', emailDomain);
        userInfo.put('emailDomain2', emailDomain2);
        userInfo.put('aliasDomain', aliasDomain);
        userInfo.put('aliasDomain2', aliasDomain2);

        return userInfo;      
    }

    private static Map<String, List<Account>> getAccountByEmailDomain(Set<String> emailDomainSet) {
        Map<String, List<Account>> accountByEmailDomain = new Map<String, List<Account>>();
        
        for (Account acc: [SELECT Id, Email_Domain__c, Email_Domain_2__c, Related_Request__c
                           FROM Account 
                           WHERE Email_Domain_2__c = :emailDomainSet]) {

            String emailDomain2 = acc.Email_Domain_2__c;           
            Boolean isContainKey = accountByEmailDomain.containsKey(emailDomain2);

            if (emailDomain2 != null) {
                if (!isContainKey) {
                    List<Account> accountList = new List<Account>{acc};

                    accountByEmailDomain.put(emailDomain2, accountList);
                } else {
                    List<Account> exsitAccountList = accountByEmailDomain.get(emailDomain2);
                                
                    exsitAccountList.add(acc);
                    accountByEmailDomain.put(emailDomain2, exsitAccountList);
                }
            } else {
                continue;
            }
        }
        return accountByEmailDomain;
    }

    /*  
        * @ Author : danbik@fiduciarytech.com
        * @ Date : 6/21/2022
        * @ Flow Label : BC_Get or create User record
        * @ Flow Name : BC_Get_or_create_User_record
        * @ Type : Subflow
        * @ Desc : Create Contact, User and Update Account if Amazon User Role is Finance Manager.
    */ 
    public static void findFinanceManager(List<Account> accountList) { 
        List<Contact> contactToInsert = new List<Contact>();
        List<Account> accountToUpeate = new List<Account>();

        Map<Id, Account> accountById = new Map<Id, Account>();
        Map<Id, Contact> contactById = new Map<Id, Contact>();

        // Get User records
        List<User> userFinanceManagerList = getFinanceManagerUser(accountList);

        for (Account item : accountList) {
            List<User> userFinanceManager = new List<User>();

            for (User user  : userFinanceManagerList) {
                if (item.FM_Email_Alias__c != null) {
                    if (user.FederationIdentifier == item.FM_Email_Alias__c.toLowerCase()) {
                        userFinanceManager.add(user);
                    }
                }
            }

            // Number of User records returned
            if (!userFinanceManager.isEmpty()) { // 2 One or more User records
                User existingUser = new User();
                for (User fm : userFinanceManager) {
                    if (fm.UserType == 'PowerPartner') {
                        Account acc = new Account();

                        acc.Finance_Manager__c = fm.Id;
                        acc.Id = item.Id;

                        accountToUpeate.add(acc);
                                
                    } else {
                        // ========== Subflow : BC_Get or create Contact record ==========
                        // Store new Contact values
                        Contact con = new Contact(
                            AccountId = item.Id,
                            Email = item.FM_Email__c,
                            FirstName = item.FM_First_Name__c,
                            LastName = item.FM_Last_Name__c,
                            Related_Request__c = item.Related_Request__c
                        );

                        contactToInsert.add(con);

                        accountById.put(item.Id, item); // outputContactAccountID = con.AccountId
                        // ========== BC_Get or create Contact record END ==========        
                    }
                }
            } else { // 1 No existing User record
               // Do not anything

                // ========== Subflow : BC_Get or create Contact record ==========
                // Store new Contact values
                Contact con = new Contact(
                    AccountId = item.Id,
                    Email = item.FM_Email__c,
                    FirstName = item.FM_First_Name__c,
                    LastName = item.FM_Last_Name__c,
                    Related_Request__c = item.Related_Request__c
                );

                contactToInsert.add(con);

                accountById.put(item.Id, item); // outputContactAccountID = con.AccountId
                // ========== BC_Get or create Contact record END ========== 
            }
        }

        // Update Account records
        if (!accountToUpeate.isEmpty()) {
            update accountToUpeate;
        }   
         
        // Create Contact records
        if (!contactToInsert.isEmpty()) {
            insert contactToInsert;
        }

        for (Contact ct : contactToInsert) {
            contactById.put(ct.AccountId, ct);
        }

        processCreateUser(accountById, contactById);
    }

    @Testvisible
    private static void processCreateUser(Map<Id, Account> accountById, Map<Id, Contact> contactByAccountId) {
        List<User> userToInsert = new List<User>();

        // Get Organization Details
        List<Organization> org = getOrganization();

        for (Account item : accountById.values()){
            User newUser = new User();

            Contact ct = contactByAccountId.get(item.id);

            // Assign Finance Manager info
            Id varContactID = ct.Id;
            String varFName = item.FM_First_Name__c;
            String varLName = item.FM_Last_Name__c;
            String varEmail = item.FM_Email__c;
            String varCostCenter = item.FM_Cost_Center__c;

            // Assign Team Administrator User Record
            newUser.Alias = varFName.left(1).trim() + varLName.left(5).trim(); // forUserAlias
            newUser.ProfileId = retunrProfieId('BC_Partner Community User');
            newUser.Email = org[0].IsSandbox ? varEmail + '.invalid' : varEmail; // forEmail
            newUser.EmailEncodingKey = 'ISO-8859-1';
            newUser.FirstName = varFName;
            newUser.LastName = varLName;
            newUser.LanguageLocaleKey = 'en_US';
            newUser.LocaleSidKey = 'en_US';
            newUser.TimeZoneSidKey = 'America/Los_Angeles';
            newUser.FederationIdentifier = item.FM_Email_Alias__c.toLowerCase(); // forFederationID,
            newUser.ContactId = varContactID;
            newUser.Username = varEmail + System.Label.BC_Username_Suffix; // forUserName
            newUser.Cost_Center__c = varCostCenter;
            newUser.Team_Administrator__c = true;

            userToInsert.add(newUser);
        }

        // Create User records
        if (!userToInsert.isEmpty()) {
            insert userToInsert;
        }

        processUpdateNewFinanceManager(userToInsert, contactByAccountId);
    }

    // Update new Finance Manager
    @Testvisible
    private static void processUpdateNewFinanceManager(List<User> user, Map<Id, Contact> contactByAccountId) {
        List<Account> accountToUpate = new List<Account>();
        Map<Id, Contact> contactById = new Map<Id, Contact>(contactByAccountId.values());

        for (user item : user){
            Contact ct = contactById.get(item.ContactId);
            Account acc = new Account();
            if (ct.AccountId != null){
                acc.Id = ct.AccountId;
            }            
            acc.Finance_Manager__c = item.Id;

            accountToUpate.add(acc);
        }

        // Update Account record
        if (!accountToUpate.isEmpty()) {
            update accountToUpate;
        }
    }

    // Get records that Identifier is Finance Manager from User
    private static List<User> getFinanceManagerUser(List<Account> account) {
        Set<String> accountNameSet = new Set<String>();

        for (Account item: account) {
            accountNameSet.add(item.FM_Email_Alias__c);
        }

        return [SELECT Id, IsActive, ContactId, UserType, FederationIdentifier
                FROM User 
                WHERE FederationIdentifier IN: accountNameSet];
    }

    // Get Organization Details
    private static List<Organization> getOrganization() {
        return [SELECT Id, IsSandbox
                FROM Organization
                LIMIT 1];
    }
}