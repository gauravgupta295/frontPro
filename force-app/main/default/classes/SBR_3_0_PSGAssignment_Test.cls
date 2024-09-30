@isTest
public class SBR_3_0_PSGAssignment_Test {
      


   /* @testSetup
    public static void dataSetup(){
        String permissionSetGroupId = '0PG8L000000L0KbWAK';
        
        Id userId = UserInfo.getUserId();
        
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.PermissionSetGroupId = permissionSetGroupId;
        psa.AssigneeId	 = userId;
        
        insert psa;
    }
    */
    @isTest
    public static void test_CheckPermissionSetGroup(){
        Boolean val = SBR_3_0_PermissionSetGroupAssignment.checkPermissionSetGroup('Testing_Group');
        //System.assertEquals(true, val, 'Add');
        
        //remove();
        
        //Boolean val2 =  SBR_3_0_PermissionSetGroupAssignment.checkPermissionSetGroup('Testing_Group');
        //System.assertEquals(false, val, 'Delete');
        
        
        
    }
    /*
    public static void remove(){
        String permissionSetGroupId = '0PG8L000000L0KbWAK';
		Id userId = UserInfo.getUserId();
        List<PermissionSetAssignment> assignmentsToDelete = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :userId AND PermissionSetGroupId = :permissionSetGroupId];
		System.debug('Delete' + assignmentsToDelete);
        delete assignmentsToDelete;
    }*/
    
    
        

}