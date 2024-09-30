/*********************************************************************************************************************
* Apex Class: SBR_3_0_AMCROperations
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to manage Account Management Change Request Automatic Approve Request
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME      DATE            DETAIL FEATURES
    1.0         Manish Taneja        2023-10-07      Initial version (SF-309)
*********************************************************************************************************************/
public class SBR_3_0_AMCROperations {
    private static final String BUSINESS_ADMIN_CUSTOM_PERMISSION = 'Business_Admin';
    private static final String BRANCH_MANAGER_CUSTOM_PERMISSION = 'Branch_Manager';
    private static final String REGIONAL_SALES_DIRECTOR_CUSTOM_PERMISSION = 'Regional_Sales_Director';
    private static final String COMMISSIONS_TEAM_CUSTOM_PERMISSION = 'Commissions_Team';
    private static final String SALES_MANAGER_CUSTOM_PERMISSION = 'Sales_Management';
    // public static void CheckAMCRUser(List<Account_Management_Change_Request__c> listAMCRNew) {
    //     for (Account_Management_Change_Request__c record : listAMCRNew) {
    //         Id SalesRepUser;
    //         string NewSalesRepID;
    //         string ApprovalStatus = 'Approval_Status__c';
    //         string Userdccount = 'User_Account__c';
    //         string SalesRepID = 'Sales_Rep_ID__c';
    //         Account_Relationship__c AccountRelationRecord = new Account_Relationship__c(Id = record.Account_Relationship__c);
    //         Account_Management_Change_Request__c AMCRRecord = new Account_Management_Change_Request__c(Id = record.Id);
    //         SalesRepUser = record.Sales_Rep__c;
    //         NewSalesRepID = record.New_Sales_Rep_ID__c;
    //         string createdByUserId = record.CreatedById;
    //         System.debug('createdByUserId' + createdByUserId);
    //         String UserProfileName = getUserProfileName(createdByUserId);
    //         System.debug('UserProfileName' + UserProfileName);
    //         Boolean IsUserBusinessAdmin = IsUserInPermissionSet(createdByUserId, 'Business_Admin');
    //         System.debug('IsUserBusinessAdmin' + IsUserBusinessAdmin);
    //         Boolean IsUserCommissionTeamMember = IsUserInPermissionSet(createdByUserId, 'Commissions_Team');
    //         System.debug('IsUserCommissionTeamMember' + IsUserCommissionTeamMember);
    //         //  If(UserProfileName == 'System Administrator' ||  IsUserBusinessAdmin || IsUserCommissionTeamMember){
    //         //      AMCRRecord.put(ApprovalStatus,'Approved');
    //         //      update AMCRRecord;
    //         //      /*AccountRelationRecord.put(UserAccount,SalesRepUser);
    //         //      AccountRelationRecord.put(SalesRepID,Integer.ValueOf(NewSalesRepID));
    //         //      update AccountRelationRecord; */
    //         //  }
    //     }
    // }

    @InvocableMethod(label='Check User Permissions For AMC Creation')
    public static List<String> checkUserPermissionsForAMCCreation(List<String> usersIds) {
        List<String> userCreationPermissionList = new List<String>();
        Map<Id, String> userProfileMap = getUserProfileNames(usersIds);
        for (String userId : usersIds) {
            String UserProfileName = userProfileMap.get(userId);
            Boolean hasBusinessAdminCustomPermission = FeatureManagement.checkPermission(BUSINESS_ADMIN_CUSTOM_PERMISSION);
            Boolean hasBranchManagerCustomPermission = FeatureManagement.checkPermission(BRANCH_MANAGER_CUSTOM_PERMISSION);
            Boolean hasRegionalSalesDirecotrCustomPermission = FeatureManagement.checkPermission(REGIONAL_SALES_DIRECTOR_CUSTOM_PERMISSION);
            Boolean hasCommissionTeamCustomPermission = FeatureManagement.checkPermission(COMMISSIONS_TEAM_CUSTOM_PERMISSION);
            Boolean hasSalesManagerCustomPermission = FeatureManagement.checkPermission(SALES_MANAGER_CUSTOM_PERMISSION);

            if (hasCommissionTeamCustomPermission) {
                userCreationPermissionList.add('Auto_Approve');
            } else if (UserProfileName == 'System Administrator' || hasBusinessAdminCustomPermission || hasBranchManagerCustomPermission || hasRegionalSalesDirecotrCustomPermission || hasSalesManagerCustomPermission) {
                userCreationPermissionList.add('User_Allowed');
            } else {
                userCreationPermissionList.add('User_Not_Allowed');
            }
        }

        return userCreationPermissionList;
    }

    // public static Boolean IsUserInPermissionSet(String userId, String permissionSetName) {
    //     try {
    //         // Query the PermissionSetAssignment object to check if the user has the specified permission set
    //         Integer count = [
    //             SELECT COUNT()
    //             FROM PermissionSetAssignment
    //             WHERE AssigneeId = :userId AND PermissionSet.Name = :permissionSetName
    //         ];

    //         // If the count is greater than zero, the user is in the permission set
    //         return count > 0;
    //     } catch (Exception e) {
    //         return false;
    //     }
    // }

    public static Map<Id, String> getUserProfileNames(List<Id> userIds) {
        Map<Id, String> userProfileMap = new Map<Id, String>();

        try {
            List<User> users = [SELECT Id, Profile.Name FROM User WHERE Id IN :userIds];

            for (User userInfo : users) {
                if (userInfo.Profile != null) {
                    userProfileMap.put(userInfo.Id, userInfo.Profile.Name);
                } else {
                    userProfileMap.put(userInfo.Id, 'Profile not found');
                }
            }
        } catch (Exception e) {
            // Handle the exception, log it, or rethrow it as needed
            System.debug('An error occurred: ' + e.getMessage());
        }

        return userProfileMap;
    }

    // public static String getUserProfileName(String userId) {
    //     try {
    //         User userInfo = [SELECT Profile.Name FROM User WHERE Id = :userId LIMIT 1];

    //         if (userInfo != null && userInfo.Profile != null) {
    //             String profileName = userInfo.Profile.Name;
    //             return profileName;
    //         } else {
    //             return 'User or Profile not found';
    //         }
    //     } catch (Exception e) {
    //         return 'An error occurred: ' + e.getMessage();
    //     }
    // }
}