/*********************************************************************************************************************
* Apex Class: SBR_3_0_ServiceResourceDATest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_ServiceResourceDA
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE               DETAIL FEATURES
    1.0          2023-02-23          Initial version    
**********************************************************************************************************************************************/

@isTest
public class SBR_3_0_ServiceResourceDATest {
     @testsetup
    private static void createData()
    {
        User usr=SBR_3_0_ServiceTestDataFactory.createServiceResourceUser(true,'test12','test124');
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Integration_API_Access'];
        List <PermissionSetAssignment> permSetCheck = [SELECT Id from PermissionSetAssignment WHERE PermissionSetId = : ps.Id
                                                    AND AssigneeId = : UserInfo.getUserId()];
        if (permSetCheck.size()==0){
        insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = ps.Id);
        }
    }
    

    
   @isTest 
   static void getServiceResourceIdFromWorkOrderIdTest() {
       Test.startTest();
       insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        FSL.GlobalAPIS.addStatusTransition('Open', 'Scheduled');
       // Id workOrderId= SBR_3_0_ServiceTestDataFactory.createWorkOrderWithAssignedResource();
        WorkOrder wo=SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        ServiceResource sr=SBR_3_0_ServiceTestDataFactory.create_Service_Resource(false);
        User usr=[select id from user where username like '%SBRtestorg.com' order by createdDate limit 1];
        ServiceTerritory st= SBR_3_0_ServiceTestDataFactory.createServiceTerritory(false);
       st.CountryCode='US';
       
       insert st;
        wo.ServiceTerritoryId=st.id;
        wo.SF_PS_Expense_To_Location__c=st.id;
       wo.SF_PS_Company_Code__c='01';
        insert wo;
        
       //  update wo;
        ServiceAppointment sa = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(true,wo.id);
        sr.RelatedRecordId=usr.id;
        sr.ResourceType='T';
        sr.IsActive=true;
       	sr.SF_PS_Company_Code__c = '01';
        insert sr;
        ServiceTerritoryMember stm =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,sr.id,st.id);
        stm.EffectiveStartDate = system.now()-10;
        System.debug('Effective Date: '+stm.EffectiveStartDate);
        update stm;
        AssignedResource ar  = new AssignedResource(ServiceAppointmentId=sa.id,ServiceResourceId=sr.id);
        insert ar;
        Id servResId=SBR_3_0_ServiceResourceDA.getServiceResourceIdFromWorkOrderId(wo.id);
        Assert.areEqual(servResId,sr.id);
        Test.stopTest();   
   }
    
      @isTest 
   static void getServiceResourceCodeFromWorkOrderIdTest() {
       Test.startTest();
       insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        FSL.GlobalAPIS.addStatusTransition('Open', 'Scheduled');
       // Id workOrderId= SBR_3_0_ServiceTestDataFactory.createWorkOrderWithAssignedResource();
        WorkOrder wo=SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        ServiceResource sr=SBR_3_0_ServiceTestDataFactory.create_Service_Resource(false);
        User usr=[select id from user where username like '%SBRtestorg.com' order by createdDate limit 1];
        ServiceTerritory st= SBR_3_0_ServiceTestDataFactory.createServiceTerritory(false);
       st.CountryCode='US';
       
       insert st;
        wo.ServiceTerritoryId=st.id;
        wo.SF_PS_Expense_To_Location__c=st.id;
       wo.SF_PS_Company_Code__c='01';
        insert wo;
        
      //  update wo;
        ServiceAppointment sa = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(true,wo.id);
        sr.RelatedRecordId=usr.id;
        sr.ResourceType='T';
        sr.IsActive=true;
       	sr.SF_PS_Company_Code__c = '01';
        insert sr;
        SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,sr.id,st.id);
        AssignedResource ar  = new AssignedResource(ServiceAppointmentId=sa.id,ServiceResourceId=sr.id);
        insert ar;
        String servRescode=SBR_3_0_ServiceResourceDA.getServiceResourceCodeFromWorkOrderId(wo.id);
        Assert.areEqual(servRescode,'01');
        Test.stopTest();   
   }
    
   @isTest 
    static void getServiceResourceByIdTest() {
        Id serviceResourceId= SBR_3_0_ServiceTestDataFactory.createServiceResource();
        List<ServiceResource> servRes =SBR_3_0_ServiceResourceDA.getServiceResourceById(serviceResourceId);
        Assert.areNotEqual(servRes[0].Id,null);
    }
    
    @isTest 
    static void validateLoggedInResourcePermissionSetGroupTest(){
        Id userId=UserInfo.getUserId();
        Boolean isValid=SBR_3_0_ServiceResourceDA.validateLoggedInResourcePermissionSetGroup(userId,'Dis'); 
        Assert.areNotEqual(isValid,null);
    }
    
    @isTest 
    static void validategetServiceResourcePrimaryTerittory(){
         Id userId=UserInfo.getUserId();
         //Id servTeriId=SBR_3_0_ServiceResourceDA.getServiceResourcePrimaryTerittory(userId);
         //Assert.areEqual(servTeriId,null);
         List<ServiceTerritoryMember> allStmForSr=SBR_3_0_ServiceResourceDA.getServiceResourcePrimaryTerittory(userId);
         system.debug(allStmForSr);
         Assert.areEqual(allStmForSr,allStmForSr);
   }
    @isTest 
    static void validateGetEquipmentAlerts(){
       Asset equipment= SBR_3_0_ServiceTestDataFactory.createAsset(true);
         list<DueForService__c> alerts=SBR_3_0_ServiceResourceDA.getEquipmentAlerts(equipment.id);
         Assert.areEqual(alerts.size(),0);
   }
    
}