public without sharing class ContactTriggerHandler {
    // Label.BC_BIM_Central_Admin_User
    public static Id bimCentalUserId {
        get {
            if (bimCentalUserId == null) {
                bimCentalUserId = [SELECT Id FROM User WHERE Name = 'BIMCentral Admin'].Id;
            }
            return bimCentalUserId;
        }
        set;
    }

    public static void onBeforeInsert(List<Contact> contactList) {
         updateContactOwnerId(contactList);
         
    }

    public static void onAfterInsert(List<Contact> contactList) {
         updateEmailAliasDomain(contactList);
    }


     /*
        Flow to apex
        
        Flow Label: BC_Contact record create-Before Save

        Description: Assigns BIM Central Admin User as the owner of a new Contact record

        Author : jasons@fiduciarytech.com
        Date   : 2022-06-10
    */
    private static void updateContactOwnerId(List<Contact> contactList) {
        for (Contact cc : contactList) {
            cc.OwnerId = bimCentalUserId;
        }
    }


    /*
        Flow to apex
       
        Flow Label: BC_Contact record create-After Save

        Description: Get email and update in email/alias domain field as needed format 

        Author : jasons@fiduciarytech.com
        Date   : 2022-06-10
    */
    private static void updateEmailAliasDomain(List<Contact> contactList) {
        List<Contact> contactListToUpdate = new List<Contact>();
        for (Contact cc : contactList) {
            Contact newcc = new Contact();
            newcc.id = cc.id;
            newcc.Email_Alias__c       = UtilityClass.getEmailAliasDomain(cc.Email, 'alias');
            newcc.Email_Alias_2__c     = UtilityClass.getEmailAliasDomain(cc.Email, 'alias2');
            newcc.Email_Domain__c      = UtilityClass.getEmailAliasDomain(cc.Email, 'emailDomain');
            newcc.Email_Domain_2__c    = UtilityClass.getEmailAliasDomain(cc.Email, 'emailDomain2');
            newcc.Alias_Domain__c      = UtilityClass.getEmailAliasDomain(cc.Email, 'aliasDomain');
            newcc.Alias_Domain_2__c    = UtilityClass.getEmailAliasDomain(cc.Email, 'aliasDomain2');
            contactListToUpdate.add(newcc);
        }
        update contactListToUpdate;
    }
    
}