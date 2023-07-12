/*
    Requirement 10 - Rejection and Approval Cycle for New Users
    
    Description: Resets the Stage__c, Approval_Response__c, Last_SL_Approval_Sent__c, and Senior_Leader_Approval_Attempts__c values
    Author : blong@fiduciarytech.com
    Date   : 2023-01-10

    Script to run on demand
    ResetInactiveAccountBatch b = new ResetInactiveAccountBatch();
    Database.executeBatch(b);
*/

global without sharing class ResetInactiveAccountBatch implements Database.Batchable<sObject>, Schedulable {

    String query;

    public ResetInactiveAccountBatch() {
        query = ' SELECT Id, Stage__c, Approval_Response__c, Last_SL_Approval_Sent__c, Senior_Leader_Approval_Attempts__c ' +
                ' FROM Account ' +
                ' WHERE New_Stage_Reset_Date__c <= TODAY ' +
                '   AND Stage__c = \'Inactive\' ';
    }

    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);        
    }

    global void execute(Database.BatchableContext bc, List<Account> accList) {
        
        // no accounts, then end batch here
        if (accList.isEmpty()) {
            return;
        }

        // reset account by setting stage to new and clearing below fields
        for (Account a : accList) {
            a.Stage__c = 'New';
            a.Approval_Response__c = null;
            a.Last_SL_Approval_Sent__c = null;
            a.Last_FM_Approval_Sent__c = null;
            a.Senior_Leader_Approval_Attempts__c = 0;
            a.Finance_Manager_Approval_Attempts__c = 0;
            a.Reason_for_Inactive_Status__c = null;
            // causing validation rule to fire
            a.SL_Approval_Locked__c = false;
            a.Description = null;
            
            // clear out inactive date to ensure job does not pick up again
            a.Inactive_Date__c = null;
        }

        // update all accounts 
        Database.update(accList, false);

    }

    global void finish(Database.BatchableContext bc) {

    }

    public void execute(SchedulableContext sc) {
        ResetInactiveAccountBatch batch = new ResetInactiveAccountBatch();
        Database.executeBatch(batch); 
    }
}