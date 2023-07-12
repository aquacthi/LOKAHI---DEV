/*
    * Flow to Apex
    * Utility Class for supporting related flow and subflow functions
    * 
    */

public with sharing class UtilityClass {

    /*
    * Flow to Apex
    * Related Flow Label: BC_Update Email Alias/Domain 
    * Subflow
    *  emailStringCondition
        when 'alias' -> Email_Alias__c;
        when 'alias2' -> Email_Alias_2__c;
        when 'aliasDomain' -> Alias_Domain__c;
        when 'aliasDomain2' -> Alias_Domain_2__c;
        when 'emailDomain' -> Email_Domain__c;
        when 'emailDomain2' -> Email_Domain_2__c; 
    */
    

    public static String getEmailAliasDomain(String email, String emailStringCondition) {
        List<String> emailString = email.split('@');
        String emailDomainString = email.subStringBetween('@' , '.');

        if (emailString[0] != null) {
            switch on emailStringCondition {
                when 'alias' {
                    return emailString[0].toLowercase();
                }

                when 'alias2' {
                    return  emailString[0].subString(0,2);
                }

                when 'aliasDomain' {
                    return (emailString[0].toLowercase()) + ';' + ('@' + emailDomainString + '.');
                }

                when 'aliasDomain2' {
                    return (emailString[0].subString(0,2)) + ';' + ('@' + emailString[1].subString(0,2));
                }

                when 'emailDomain' {
                    return '@' + emailDomainString + '.';
                }

                when 'emailDomain2' {
                    return '@' + emailString[1].subString(0,2);
                }
            }
        }

        return '';
    }
}