// used to make callouts to various apis. all callouts are originated from the insert of API_Log__c records
// bim360, aws api gateway, autodesk (future work)
public without sharing class CalloutQueueable implements Queueable, Database.AllowsCallouts{
    // need to reduce chunking to 25 from 100 due to timeout errors
    private final Integer MAX_COUNT = 100;
    private List<API_Log__c> newList;
    private List<API_Log__c> nextListToProcess;

    public CalloutQueueable(List<API_Log__c> newList) {
        this.newList = newList;
    }
    
    public void execute(QueueableContext context) {
        List<API_Log__c> currentList = new List<API_Log__c>();
        List<API_Log__c> nextListToProcess = new List<API_Log__c>();
        if (newList.size() > MAX_COUNT) {
            for (Integer i = 0; i < MAX_COUNT; i++) {
                currentList.add(newList[i]);
                // Commenting out due to the Collection is read-only error	
                // newList.remove(i);
            }
            // for processing next list of API Logs
            for (Integer i = MAX_COUNT; i < newList.size(); i++) {
                nextListToProcess.add(newList[i]);
            }
        } else {
            currentList = newList;
        }

        List<API_Log__c> apiLogs = getApiLogs(currentList);
        String token = CalloutUtility.getToken();

        for (API_Log__c item : apiLogs) {
            try {
                if (item.Status__c != 'Pending') {
                    continue;
                }
    
                if (item.BC_Request__c != null) {
                    if (item.Method_Name__c == 'getProjectRoles') {
                        CalloutUtility.getProjectRoles(item, token);
                    } else if (item.Method_Name__c == 'getUserSearch') {
                        CalloutUtility.getUserSearch(item, token);
                    } else if (item.Method_Name__c == 'patchUserToActive') {
                        CalloutUtility.patchUserToActive(item, token);
                    } else if (item.Method_Name__c == 'getCompanyNameSearch') {
                        CalloutUtility.getCompanyNameSearch(item, token);
                    } else if (item.Method_Name__c == 'patchUserCompanyName') {
                        CalloutUtility.patchUserCompanyName(item, token);
                    } else if (item.Method_Name__c == 'postUser') {
                        CalloutUtility.postUser(item, token);
                    } else if (item.Method_Name__c == 'postUserToProject') {
                        CalloutUtility.postUserToProject(item, token);
                    } else if (item.Method_Name__c == 'getAmazonUserInfo') {
                        CalloutUtility.getAmazonUserInfo(item);
                    }
                } else if (item.Account__c != null) {
                    if (item.Method_Name__c == 'getAmazonUserInfo') {
                        CalloutUtility.getAmazonUserInfo(item);
                    }
                } else if (item.BIM360_Staging_Project__c != null) {
                    if (item.Method_Name__c == 'postProjectBulk') {
                        CalloutUtility.postProjectBulk(item, token);
                    } else if (item.Method_Name__c == 'patchProjectBulk') {
                        CalloutUtility.patchProjectBulk(item, token);
                    }
                } else if (item.BIM360_Staging_User__c != null) {
                    if (item.Method_Name__c == 'postUserToProjectBulk') {
                        CalloutUtility.postUserToProjectBulk(item, token);
                    } else if (item.Method_Name__c == 'patchUserInProjectBulk') {
                        CalloutUtility.patchUserInProjectBulk(item, token);
                    }
                }
            } catch(Exception e) {
                String errorMessage = e.getMessage() + '\n\n' + e.getStackTraceString();
                item.Error_Message__c = CalloutUtility.appendErrorMessage(item, errorMessage);
            }
        }

        update apiLogs;

        // Cannot call due to more than 1 queueable job in queue error.
        // if (!nextListToProcess.isEmpty()) {
        //     System.enqueueJob(new CalloutQueueable(nextListToProcess));
        // }
    }

    private List<API_Log__c> getApiLogs(List<API_Log__c> currentList) {
        return [SELECT  Method_Name__c,
                        Status__c,
                        Error_Message__c,
                        BIM_360_User_Id__c,
                        BIM_360_Project_Role_Info__c,
                        BIM_360_Company_Id__c,
                        BC_Request__c,
                        BC_Request__r.Stage__c, 
                        BC_Request__r.RecordTypeId,
                        BC_Request__r.BIM_360_Role__c, 
                        // BLONG - added BIM Project lookup                     
                        BC_BIM_Project__r.AD_ID__c,
                        BC_Request__r.Recipient_Email__c, 
                        BC_Request__r.Recipient_Email_Alias__c,
                        BC_Request__r.Recipient_First_Name__c, 
                        BC_Request__r.Recipient_Last_Name__c, 
                        BC_Request__r.Recipient__r.BIM_360_CC_User_Activate_Date__c, 
                        BC_Request__r.Recipient__r.BIM_360_CC_User_ID__c, 
                        BC_Request__r.Recipient__r.BIM_360_CC_User_Status__c,
                        BC_Request__r.Recipient__r.Account.Vendor_Company_Name__c,
                        BC_Request__r.APOC_Email__c,
                        Account__r.FM_Email__c,
                        BIM360_Staging_Project__c,
                        BIM360_Staging_Project__r.Address_Line_1__c,
                        BIM360_Staging_Project__r.Address_Line_2__c,
                        BIM360_Staging_Project__r.City__c,
                        BIM360_Staging_Project__r.Construction_Type__c,
                        BIM360_Staging_Project__r.Contract_Type__c,
                        BIM360_Staging_Project__r.Country__c,
                        BIM360_Staging_Project__r.End_Date__c,
                        BIM360_Staging_Project__r.Job_Number__c,
                        BIM360_Staging_Project__r.Include_Companies__c,
                        BIM360_Staging_Project__r.Include_Locations__c,
                        BIM360_Staging_Project__r.Project_Id__c,
                        BIM360_Staging_Project__r.Project_Name__c,
                        BIM360_Staging_Project__r.Postal_Code__c,
                        BIM360_Staging_Project__r.Project_Currency__c,
                        BIM360_Staging_Project__r.Project_Type__c,
                        BIM360_Staging_Project__r.Project_Value__c,
                        BIM360_Staging_Project__r.Services__c,
                        BIM360_Staging_Project__r.Start_Date__c,
                        BIM360_Staging_Project__r.State_Province__c,
                        BIM360_Staging_Project__r.Template_Project_Id__c,
                        BIM360_Staging_Project__r.Time_Zone__c,
                        BIM360_Staging_User__r.Company_Id__c,
                        BIM360_Staging_User__r.csv_Accesses__c,
                        BIM360_Staging_User__r.csv_Company_Id__c,
                        BIM360_Staging_User__r.csv_Email__c,
                        BIM360_Staging_User__r.csv_Project_Id__c,
                        BIM360_Staging_User__r.csv_Role_Ids__c,
                        BIM360_Staging_User__r.csv_Services__c,
                        BIM360_Staging_User__r.csv_User_Id__c,
                        BIM360_Staging_User__r.Email__c,
                        BIM360_Staging_User__r.Project_Id__c,
                        BIM360_Staging_User__r.Role_Ids__c,
                        BIM360_Staging_User__r.Services__c,
                        BIM360_Staging_User__r.User_Id__c
                FROM API_Log__c
                WHERE Id IN: currentList];
    }
}