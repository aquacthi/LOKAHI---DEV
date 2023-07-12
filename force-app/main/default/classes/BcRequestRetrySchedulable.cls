/*
// schedule every 15 minutes
System.schedule('BcRequestRetrySchedulable: at 00 mins', '0 0 * * * ?', new BcRequestRetrySchedulable(5));
System.schedule('BcRequestRetrySchedulable: at 15 mins', '0 15 * * * ?', new BcRequestRetrySchedulable(5));
System.schedule('BcRequestRetrySchedulable: at 30 mins', '0 30 * * * ?', new BcRequestRetrySchedulable(5));
System.schedule('BcRequestRetrySchedulable: at 45 mins', '0 45 * * * ?', new BcRequestRetrySchedulable(5));

// run now
BcRequestRetrySchedulable s = new BcRequestRetrySchedulable(5);
s.execute(null);
*/


global without sharing class BcRequestRetrySchedulable implements Schedulable {
      
    Integer queryLimit;

    public BcRequestRetrySchedulable(Integer queryLimit) {
        this.queryLimit = queryLimit;
    }

    public void execute(SchedulableContext sc) {
        List<BC_Request__c> bcRequestList = [
            SELECT Id, Status__c, Stage__c, Reprocessed_Date_Time__c,
                (SELECT Id FROM API_Logs__r)
            FROM BC_Request__c
            WHERE Status__c = 'Open'
                AND Stage__c  = 'New'
                AND Request_error_description__c = null
            ORDER BY Reprocessed_Date_Time__c ASC
            LIMIT :queryLimit];

        if (bcRequestList.isEmpty()) {
            return;
        } 
        else {
            // Update bc requests that are in the open status and new stage to retry the API Logs
            List<BC_Request__c> bcRequestsToUpdate = new List<BC_Request__c>();
            for (BC_Request__c bcRequest : bcRequestList) {
                if (!bcRequest.API_Logs__r.isEmpty()) {
                    bcRequest.Reprocessed_Date_Time__c = System.now();
                    bcRequestsToUpdate.add(bcRequest);
                }
            }
            Database.update(bcRequestsToUpdate, false);
        }
    }

}