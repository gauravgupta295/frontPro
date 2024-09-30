/*********************************************************************************************************************
* Apex Class: SBR_3_0_WorkOrderTriggerHandler_Test
---------------------------------------------------------------------------------------------------------------------------------------
* @description
* - SERV-15700
* - Test class for WorkOrder Trigger Handler class.
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
1.0         Diksha Tiwari                       2024-05-29            Initial version
*********************************************************************************************************************/
@isTest  
public with sharing class SBR_3_0_WorkOrderTriggerHandler_Test {
    
    @TestSetup static void setupTestData() {

        User testUser = SBR_3_0_ServiceTestDataFactory.createServiceResourceUserWO(true,'1234','981291231');
        User testAdminUser = SBR_3_0_ServiceTestDataFactory.createSystemAdminUser(true,'8898','987644'); 
        PermissionSetGroup psg = [Select ID, DeveloperName from PermissionSetGroup where DeveloperName = 'SFS_Admin' ][0];
		PermissionSetAssignment assignment = new PermissionSetAssignment(PermissionSetGroupId = psg.Id,AssigneeId = testAdminUser.id);
		insert assignment;
        
    }
    
    @isTest    
    static void testSBR_3_0_WorkOrderTriggerHandlerIsClosedWithExc(){
        //create Asset
        Asset ass =  SBR_3_0_ServiceTestDataFactory.createAsset(true);
        
        //Create Exponce to Location
        ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
        
        //Create Service Territory 
        ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
        
        //create work order 
        workorder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        wo.SF_PS_RM_WO_Number__c = '01-1122900';
        wo.SF_PS_Expense_To_Location__c = testE2Loc.id;
        wo.AssetId = ass.id;
        wo.ServiceTerritoryId  = testST.id;
        wo.SF_PS_Is_Credited__c=false;
        wo.Status='C';
        insert wo;
        
        //workorder wo=[Select id from WorkOrder where SF_PS_RM_WO_Number__c='01-1122900'];
        wo.Status= 'Closed with Exception';
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];
        System.runAs(testAdminUser){
            try{
                Test.startTest();
                update wo;
                Test.stopTest();
            }
            catch(Exception e){
                Assert.isNotNull(e.getMessage());
            }
        }
    }
    
    
}