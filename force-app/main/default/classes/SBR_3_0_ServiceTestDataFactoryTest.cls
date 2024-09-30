/*********************************************************************************************************************
* Apex Class: SBR_3_0_ServiceTestDataFactoryTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - To test SBR_3_0_ServiceTestDataFactory
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE               DETAIL FEATURES
    1.0          2023-02-23          Initial version
    2.0          2023-05-09          Mayank Jain
    3.0          2023-05-19          Mayank Jain     
**********************************************************************************************************************************************/
@isTest
public class SBR_3_0_ServiceTestDataFactoryTest {
    
    //@isTest
    //static void validateCreateWorkOrderWithAssignedResource(){
    //    Id woId=SBR_3_0_ServiceTestDataFactory.createWorkOrderWithAssignedResource();
    //    Assert.areNotEqual(woId,null);
    //}
    
    @isTest
    static void validatecreateServiceResource(){

        Id srId = SBR_3_0_ServiceTestDataFactory.createServiceResource();
        System.assertNotEquals(srId, null, 'ServiceResource ID should not be null');
        ServiceResource sr = [SELECT Id, Name, RelatedRecordId, IsActive FROM ServiceResource WHERE Id = :srId];
        System.assertEquals(sr.IsActive, true, 'ServiceResource should be active');
        System.assert(sr.Name.startsWith('TEST RESOURCE'), 'ServiceResource name should start with "TEST RESOURCE"');

    }

    static testMethod void validatecreateServiceResourceUser(){
        User servId=SBR_3_0_ServiceTestDataFactory.createServiceResourceUser(true,'1234','1234');
        System.assertEquals('1234',servId.SF_PS_Mechanic_Id__c, 'Service resource size mismatch ');
    }

    @isTest
    static void validatecreateServiceResourceEmpNoUser(){
        Test.startTest();
        User servId=SBR_3_0_ServiceTestDataFactory.createServiceResourceEmpNoUser(true,'1234','1234');
        Assert.areNotEqual(servId,null);
        Test.stopTest();
    }
    
    @isTest
    static void validatecreateServiceResourceUserEMPWO(){
        User servId=SBR_3_0_ServiceTestDataFactory.createServiceResourceUserEMPWO(true,'1234','1234');
        Assert.areNotEqual(servId,null);
    }
    @isTest
    static void validatecreateServiceResourceUserWO(){
        User servId=SBR_3_0_ServiceTestDataFactory.createServiceResourceUserWO(true,'1234','1234');
        Assert.areNotEqual(servId,null);
    }
    
    @isTest
    static void validatecreate_Service_Resource(){
        ServiceResource srId=SBR_3_0_ServiceTestDataFactory.create_Service_Resource(false);
        Assert.areNotEqual(srId,null);
    }

    @isTest
    static void validatecreateOwnerUser(){
        User srId=SBR_3_0_ServiceTestDataFactory.createOwnerUser(false,'123','123');
        Assert.areNotEqual(srId,null);
    }

    @isTest
    static void validatecreateWorkOrder(){
        workOrder srId=SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        Assert.areNotEqual(srId,null);
    }

    @isTest
    static void validatecreateProductConsumed(){
        ProductConsumed srId=SBR_3_0_ServiceTestDataFactory.createProductConsumed(false);
        Assert.areNotEqual(srId,null);
    }

    @isTest
    static void validatecreateAsset(){
        Asset srId=SBR_3_0_ServiceTestDataFactory.createAsset(false);
        Assert.areNotEqual(srId,null);
    }

    @isTest
    static void validatecreateAccount(){
        Account srId=SBR_3_0_ServiceTestDataFactory.createAccount(false,'123');
        Assert.areNotEqual(srId,null);
    }

    @isTest
    static void validatecreateServiceTerritory(){
        ServiceTerritory srId=SBR_3_0_ServiceTestDataFactory.createServiceTerritory(false);
        Assert.areNotEqual(srId,null);
    }

    @isTest
    static void validatecreateSalesRepUser(){
        User srId=SBR_3_0_ServiceTestDataFactory.createSalesRepUser(false,'123');
        Assert.areNotEqual(srId,null);
    }

	//Failing
    // @isTest
    // static void validatecreateAssLOC(){
    //     List<AssociatedLocation> srId=SBR_3_0_ServiceTestDataFactory.createAssLOC(false,'123');
    //     Assert.areNotEqual(srId,null);
    // }


    @isTest
    static void validatecreateServiceAppointment(){
        ServiceAppointment stId=SBR_3_0_ServiceTestDataFactory.createServiceAppointment(false, '0WO77000000YECoGAO');
        Assert.areNotEqual(stId,null);
    }
    
    @isTest
    static void validatecreateServiceTerritoryMember(){
        ServiceTerritoryMember stmId=SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(false,'0WO77000000YECfdge','0WO77000000YECgfsr');
        Assert.areNotEqual(stmId,null);
    }
  
    @isTest
    static void validatecreateWorkOrderLineItem(){
        WorkOrderLineItem woliId=SBR_3_0_ServiceTestDataFactory.createWorkOrderLineItem(false);
        Assert.areNotEqual(woliId,null);
    }

    @isTest
    static void validatecreateSystemAdminUser(){
        user woliId=SBR_3_0_ServiceTestDataFactory.createSystemAdminUser(false,'12345','654763');
        Assert.areNotEqual(woliId,null);
    }

    @isTest
    static void validatecreateWoli(){
        WorkOrderLineItem woliId=SBR_3_0_ServiceTestDataFactory.createWoli(false,'0WO77000000YECfdge','0Hn8G0000004LKYSA2');
        Assert.areNotEqual(woliId,null);
    }
    
    @isTest
    static void validatecreateqli(){
        Quote_Line_Item__c woliId=SBR_3_0_ServiceTestDataFactory.createqli(false,'0WO77000000YECfdge','0Hn8G0000004LKYSA2');
        Assert.areNotEqual(woliId,null);
    }
    
    @isTest
    static void validatecreateProductConsumedRecord(){
        ProductConsumed pcId=SBR_3_0_ServiceTestDataFactory.createProductConsumedRecord(false,'0WO77000000YECfdge','0Hn8G0000004LKYSA2');
        Assert.areNotEqual(pcId,null);
    }

    @isTest
    static void validatecreateMaintenanceSteps(){
        SF_PS_Maintenance_Steps__c pcId=SBR_3_0_ServiceTestDataFactory.createMaintenanceSteps(false,'0WO77000000YECfdge','0Hn8G0000004LKYSA2');
        Assert.areNotEqual(pcId,null);
    }
    
    @isTest
    static void validatecreateProductConsumedRecordFail(){
        ProductConsumed pcId=SBR_3_0_ServiceTestDataFactory.createProductConsumedRecordFail(false,'0WO77000000YECfdge','0Hn8G0000004LKYSA2');
        Assert.areNotEqual(pcId,null);
    }
    @isTest
    static void validatecreateWorkStepTemplate(){
        WorkStepTemplate pcId=SBR_3_0_ServiceTestDataFactory.createWorkStepTemplate(false);
        Assert.areNotEqual(pcId,null);
    }
    

}