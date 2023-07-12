/*
    Flow to apex
    Description: UtilityConsts for supporting related fields
    Date   : 2022-06-10
*/
public with sharing class UtilityConsts {
    public static final String BC_STAGE_REQUEST_ERROR = 'Request Error';
    public static final String BC_STAGE_AUTODESK_ERROR = 'Autodesk Error';
    public static final String BC_STAGE_POTENTIAL_DUPLICATE = 'Potential Duplicate';
    public static final String BC_STAGE_EVALUATE = 'Evaluate';
    public static final String BC_STAGE_NEW = 'New';
    public static final String BC_STAGE_PRE_APPROVAL_CHECK = 'Pre-Approval Check';
    public static final String BC_STAGE_PENDING_AMAZON_POINT_OF_CONTACT_APPROVAL = 'Pending APOC Approval';
    public static final String BC_STAGE_ENTER_SENIOR_LEADER = 'Enter SL';
    public static final String BC_STAGE_PENDING_APPROVAL = 'Pending Approval';
    public static final String BC_STAGE_FULFILL_REQUEST = 'Fulfill Request';
    public static final String BC_STAGE_RESOLVED_COMPLETED = 'Resolved - Completed';
    public static final String BC_STAGE_RESOLVED_NOT_COMPLETED = 'Resolved - Not Completed';
    public static final String BC_STATUS_OPEN = 'Open';
    public static final String BC_STATUS_CLOSED = 'Closed';
    public static final String BC_RECORD_TYPE_NAME_TOKEN_FLEX_LICENSE = 'Token Flex License';
    public static final String BC_RECORD_TYPE_NAME_BIM_360_AMAZONIAN = 'BIM 360 Amazonian';
    public static final String BC_RECORD_TYPE_NAME_BIM_360_NON_AMAZONIAN = 'BIM 360 Non-Amazonian';
    public static final String BC_REASON_NOT_COMPLETED_DUPLICATE_REQUEST = 'Duplicate request';
    public static final String BC_REASON_NOT_COMPLETED_INCORRECT_APOC_EMAIL = 'Incorrect APOC email';
    public static final String BC_REASON_NOT_COMPLETED_WRONG_APOC = 'Wrong APOC';
    public static final String BC_REASON_NOT_COMPLETED_NOT_APPROVED = 'Not approved';
    public static final String BC_REASON_NOT_COMPLETED_NO_RESPONSE = 'No response';
    public static final String BC_REASON_NOT_COMPLETED_NO_TPS_Compliant = 'Not TPS compliant';
    public static final String BC_REASON_NOT_COMPLETED_RECIPIENT_NOT_FOUND = 'Recipient not found';
    public static final String BC_REASON_NOT_COMPLETED_AMAZON_POC_NOT_FOUND = 'Amazon POC not found';
    public static final String BC_REASON_NOT_COMPLETED_OTHER = 'Other';
    public static final String BC_REASON_NOT_COMPLETED_NO_RESPONSE_FROM_SENIOR_LEADER = 'No response from Senior Leader';
    public static final String BC_REASON_NOT_COMPLETED_NO_RESPONSE_FROM_FINANCE_MANAGER = 'No response from Finance Manager';
    public static final String BC_OTHER_REASON_NOT_COMPLETED_APOC_APPROVAL_NOT_RECEIVED = 'APOCapproval not received after multiple attempts';

    public static final String ACC_STAGE_ACCOUNT_ERROR = 'Account Error';
    public static final String ACC_STAGE_NEW = 'New';
    public static final String ACC_STAGE_PENDING_SENIOR_LEADER_APPROVAL = 'Pending SL Approval';
    public static final String ACC_STAGE_ENTER_FINANCE_MANAGER = 'Enter Finance Manager';
    public static final String ACC_STAGE_PENDING_FINANCE_APPROVAL = 'Pending Finance Approval';
    public static final String ACC_STAGE_PENDING_RESPONSE = 'Pending Response';
    public static final String ACC_STAGE_PENDING_ACTIVE_CONTINGENT = 'Active-Contingent';
    public static final String ACC_STAGE_ACTIVE = 'Active';
    public static final String ACC_STAGE_INACTIVE = 'Inactive';
    public static final String ACC_APPROVAL_RESPONSE_APPROVED = 'Approved';
    public static final String ACC_APPROVAL_RESPONSE_REJECTED = 'Rejected';
    public static final String ACC_REASON_FOR_INACTIVE_STATUS_NO_RESPONSE = 'No response';
    public static final String ACC_REASON_FOR_INACTIVE_STATUS_NOT_APPROVED = 'Not approved';
    public static final String ACC_REASON_FOR_INACTIVE_STATUS_OTHER = 'Other';
    public static final String ACC_REASON_FOR_INACTIVE_STATUS_NO_TPS = 'No TPS';
    public static final String ACC_REASON_FOR_INACTIVE_STATUS_NO_NDA = 'No NDA';
    public static final String ACC_REASON_FOR_INACTIVE_STATUS_NO_RESPONSE_FROM_SENIOR_LEADER = 'No response from Senior Leader';
    public static final String ACC_REASON_FOR_INACTIVE_STATUS_NO_RESPONSE_FROM_FINANCE_MANAGER = 'No response from Finance Manager';

    public static final String OBJECT_NAME_BC_REQUEST = 'BC_Request';
    public static final String OBJECT_NAME_ACCOUNT = 'Account';
    
    public static final String RECORD_TYPE_NAME_INTERNAL = 'Internal';
    public static final String RECORD_TYPE_NAME_EXTERNAL = 'External';

    public static final String CONSTANT_VALUE_DEVELOPERNAME_MAX_APOC_APPROVAL_ATTEMPTS = 'Max_APOC_Approval_Request_Attempts';
    public static final String CONSTANT_VALUE_DEVELOPERNAME_MAX_SENIOR_LEADER_APPROVAL_ATTEMPTS = 'Max_Senior_Leader_Approval_Attempts';
    public static final String CONSTANT_VALUE_DEVELOPERNAME_MAX_FINANCE_MANAGER_APPROVAL_ATTEMPTS = 'Max_Finance_Manager_Approval_Attempts';

    public static final Integer MAX_AUTODESK_ERROR_STRING = 255;
    public static final Integer MAX_AUTODESK_RESPONSE_BODY_STRING = 131072;
}