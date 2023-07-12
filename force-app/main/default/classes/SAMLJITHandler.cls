global without sharing class SAMLJITHandler implements Auth.SamlJitHandler {
    private class JitException extends Exception {
    }

    private void handleUser(Boolean create,
                            User u, 
                            Map<String, String> attributes, 
                            String federationIdentifier, 
                            Boolean isStandard) 
    {
        System.debug('>>>> handleUser');
        String domainName = 'bim';
        String email;
        String firstName;
        String lastname;
        
        if (attributes.containsKey('EMAIL')) {
            email = attributes.get('EMAIL');
        }
        if (attributes.containsKey('GIVEN_NAME')) {
            firstName = attributes.get('GIVEN_NAME');
        }
        if (attributes.containsKey('FAMILY_NAME')) {
            lastName = attributes.get('FAMILY_NAME');
        }
        
        u.Email = email;
        u.FirstName = firstname;
        u.LastName = lastname;
            
        if (create) {
            Organization org = [SELECT Id, isSandbox FROM Organization LIMIT 1];

            u.FederationIdentifier = federationIdentifier;
            u.CommunityNickname = returnAlias(email) + '.' + domainName;
            u.Username = email + '.' + domainName; //emailaddress.mydoamin
            if (org.isSandbox) {
                String hashString = '1000' + String.valueOf(Datetime.now().formatGMT('yyyy-MM-dd HH:mm:ss.SSS'));
                Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(hashString));
                String hexDigest = EncodingUtil.convertToHex(hash);
                u.Username += '.'  + hexDigest.substring(0, 3);
            }
            u.TimeZoneSidKey = 'America/Los_Angeles'; // Required PST
            u.LocaleSidKey = 'en_US'; // Required
            u.EmailEncodingKey = 'ISO-8859-1'; // Required
            u.LanguageLocaleKey = 'en_US'; // Required
            u.Manually_Provisioned__c = false;
            u.Alias = returnAlias(email);
     
            //get profile Id associated to ldapgroup
            Id profileId = retunrProfieId('BC_Partner Community User');
            u.ProfileId = profileId;
        }

        System.debug('>>>> u ' + u);
        if (!create) {
            if(!u.Manually_Provisioned__c) {
                update(u);
            }
        }
        else {
            insert u;
        }
    }
    // @future
    private static void handleContact(boolean create, 
                                      String accountId,
                                      User u, 
                                      Map < String, String > attributes, 
                                      String federationIdentifier) {    
        if (create) {
            String email, firstName, lastName;
            if (attributes.containsKey('EMAIL')) {
                email = attributes.get('EMAIL');
            }
            if (attributes.containsKey('GIVEN_NAME')) {
                firstName = attributes.get('GIVEN_NAME');
            }
            if (attributes.containsKey('FAMILY_NAME')) {
                lastName = attributes.get('FAMILY_NAME');
            }
            Contact c = new Contact();
            c.FirstName = firstName;
            c.LastName = lastname;
            c.Email = email;
            c.Employee_Id__c = federationIdentifier;
            c.AccountId = accountId;
            c.Amazonian__c = true;
            insert (c);

            u.ContactId = c.Id;

        }
    }

    private String handleAccount(boolean create, 
                                 User u, 
                                 Map < String, String > attributes) {
        Account a = [SELECT Id FROM Account WHERE Name = 'Amazon'];
        return a.Id;
    }


    private void handleJit(Boolean create, 
                           User u, 
                           Id samlSsoProviderId, 
                           Id communityId, 
                           Id portalId,
                           String federationIdentifier, 
                           Map<String, String> attributes, 
                           String assertion) 
    {
        System.debug('>>>> handleJit' + attributes);
        if (communityId != null || portalId != null || Test.IsRunningTest()) {
            String account = handleAccount(create, u, attributes);
            handleContact(create, account, u, attributes, federationIdentifier);
            handleUser(create, u, attributes, federationIdentifier, false);
        }
        else {
            handleUser(create, u, attributes, federationIdentifier, true);
        }
    }


    global User createUser(Id samlSsoProviderId, 
                           Id communityId, 
                           Id portalId,
                           String federationIdentifier, 
                           Map<String, String> attributes, 
                           String assertion) 
    {
        System.debug('>>>> createUser');
        User u = new User();
        handleJit(true, u, samlSsoProviderId, communityId, portalId, federationIdentifier, attributes, assertion);
        return u;
    }

    //This section updates the user.  Josh, why would we want to update the user, except for what I think happens behind the scenes with Salesforce insterted login times?  Comment from Ted

    global void updateUser(Id userId, 
                           Id samlSsoProviderId, 
                           Id communityId, 
                           Id portalId,
                           String federationIdentifier, 
                           Map<String, String> attributes, 
                           String assertion) 
    {
        System.debug('>>>> updateUser');
        User u = new User();
        if( Schema.sObjectType.User.fields.Manually_Provisioned__c.isAccessible() &&
            Schema.sObjectType.User.fields.FirstName.isAccessible() &&
            Schema.sObjectType.User.fields.ContactId.isAccessible() ) 
        {
            u = [SELECT Id, Manually_Provisioned__c, FirstName, ContactId FROM User WHERE Id = :userId];
        }

        if(!u.Manually_Provisioned__c)
        {
            handleJit(false, u, samlSsoProviderId, communityId, portalId, federationIdentifier, attributes, assertion);
        }
    }

    private static String returnAlias(String Email) 
    {
        System.debug('>>>> returnAlias');
        String alias = Email.split('@')[0];
        if (alias.length() > 8) {
            alias = alias.substring(0, 8);
        }
        List<User> userRecordList = new List<User>();
        if( Schema.sObjectType.User.fields.Name.isAccessible() &&
            Schema.sObjectType.User.fields.Alias.isAccessible() ) 
        {
            userRecordList = [Select Id, Name, Alias from User where Alias = :alias];
        }

        if (userRecordList != null && userRecordList.size() > 0) {
            String hashString = '1000' + String.valueOf(Datetime.now().formatGMT('yyyy-MM-dd HH:mm:ss.SSS'));
            Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(hashString));
            String hexDigest = EncodingUtil.convertToHex(hash);
            alias = alias.substring(0, 3) + hexDigest.substring(0, 3);
        }
        return alias;
    }

    /****************************************************************************************
    *   @description    return Profile Id
    *   @params         String (Profile Name)
    *   @returns        Id (ProfileId)
    ****************************************************************************************/
    private static Id retunrProfieId(String profileName) 
    {
        System.debug('>>>> retunrProfieId');
        List<Profile> profileList = new List<Profile>();
        // if( Schema.sObjectType.profile.fields.name.isAccessible() ) 
        // {
            profileList = [select id, name from profile where name = :profileName];
        // }

        if (profileList.size() == 1) {
            System.debug('>>>> retunrProfieId = ' + profileList[0].id);

            return profileList[0].id;
        } else {
            //Need exception
        }
        return null;

    }

    /****************************************************************************************
    *   @description    return User Role Id
    *   @params         String (UserROle Name)
    *   @returns        Id (UserRoelId)
    ****************************************************************************************/
    private static Id retunrUserRoleId(String userRoleName) 
    {
        System.debug('>>>> retunrUserRoleId');
        List<userRole> userRoleList = new List<userRole>();
        if( Schema.sObjectType.userRole.fields.name.isAccessible() ) 
        {
            userRoleList = [select id, name from userRole where name = :userRoleName];
        }

        if (userRoleList.size() == 1) {
            return userRoleList[0].id;
        } else {
            //Need exception
        }
        return null;

    }
}