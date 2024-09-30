public with sharing class SBR_3_0_PermissionSetGroupAssignment{

    @AuraEnabled(cacheable=true)    
    public static Boolean checkPermissionSetGroup(String permissionSetGroupName) {
        String userId = UserInfo.getUserId();
        List<String> pmsGroups = new List<String>();
        for (PermissionSetAssignment assignment : [SELECT PermissionSetGroup.DeveloperName FROM PermissionSetAssignment WHERE AssigneeId = :userId]) {
            pmsGroups.add(assignment.PermissionSetGroup.DeveloperName);
        }

        if(pmsGroups.contains(permissionSetGroupName)){
            return true;
        }
        return false;
    }
}