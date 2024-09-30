/*********************************************************************************************************************
* Apex Class: SBR_3_0_SfsGenericLookupControllerTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_SfsGenericLookupController
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE               DETAIL FEATURES
1.0          2023-02-23          Initial version    
**********************************************************************************************************************************************/

@isTest
public class SBR_3_0_SfsGenericLookupControllerTest {
    
    @isTest
    static void fetchLookupDataTest(){
        Id serviceResourceId= SBR_3_0_ServiceTestDataFactory.createServiceResource();
        list<sObject> rec=SBR_3_0_SfsGenericLookupController.fetchLookupData('test','ServiceResource',' And IsActive=true','');
        list<sObject> recWithNoneFilter=SBR_3_0_SfsGenericLookupController.fetchLookupData('test','ServiceResource','None','');
        Assert.areNotEqual(rec[0].Id,null);
    }
    
    @isTest
    static void fetchDefaultRecordTest(){
        Id serviceResourceId= SBR_3_0_ServiceTestDataFactory.createServiceResource();
        sObject rec=SBR_3_0_SfsGenericLookupController.fetchDefaultRecord(serviceResourceId,'ServiceResource');
        Assert.areNotEqual(rec.Id,null);
    }
   
     @isTest
    static void fetchLookupDataProductItemTest(){
        Id serviceResourceId= SBR_3_0_ServiceTestDataFactory.createServiceResource();
 
        ServiceTerritory st= SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
        st.Branch_Location_Number__c='0693';
        test.startTest();
      
        list<sObject> rec=SBR_3_0_SfsGenericLookupController.fetchLookupData('','ProductItem',' and Location.Company_Code__c=\'test\' ','');
             
        Assert.areEqual(rec.size(),0);
        Test.stopTest();
        
    }
    
    @isTest
    static void fetchLookupDataProductItemTest2(){
        Id serviceResourceId= SBR_3_0_ServiceTestDataFactory.createServiceResource();
 
        ServiceTerritory st= SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
        st.Branch_Location_Number__c='0693';
        test.startTest();
      
        list<sObject> rec=SBR_3_0_SfsGenericLookupController.fetchLookupData('test','ProductItem','Location.Company_Code__c=\'test\' ','SM_PS_Item_Number__c');
             
        Assert.areEqual(rec.size(),0);
        Test.stopTest();
        
    }
    
    @isTest
    static void fetchLookupDataProductTest2(){
        Id serviceResourceId= SBR_3_0_ServiceTestDataFactory.createServiceResource();
 
        ServiceTerritory st= SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
        st.Branch_Location_Number__c='0693';
        test.startTest();
        // Need to null as parameter
        list<sObject> rec=SBR_3_0_SfsGenericLookupController.fetchLookupData('test','Product2','None','SM_PS_Item_number__c');
             
        Assert.areEqual(rec.size(),0);
        Test.stopTest();
        
    }
     @isTest
    static void fetchLookupDataProductTest3(){
        Id serviceResourceId= SBR_3_0_ServiceTestDataFactory.createServiceResource();
 
        ServiceTerritory st= SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
        st.Branch_Location_Number__c='0693';
        test.startTest();
        // Need to null as parameter
        list<sObject> rec=SBR_3_0_SfsGenericLookupController.fetchLookupData('test','Product2',' Product2.Product_Type__c like \'%MISC%\'','SM_PS_Item_number__c');
             
        Assert.areEqual(rec.size(),0);
        Test.stopTest();
        
    }
    
    @isTest
    static void fetchLookupDataAssetTest2(){
        Id serviceResourceId= SBR_3_0_ServiceTestDataFactory.createServiceResource();
 
        ServiceTerritory st= SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
        st.Branch_Location_Number__c='0693';
        test.startTest();
      
        list<sObject> rec=SBR_3_0_SfsGenericLookupController.fetchLookupData('test','Asset','','SM_PS_Item_number__c');
             
        Assert.areEqual(rec.size(),0);
        Test.stopTest();
        
    }
    
    @isTest
    static void fetchLookupDataAssetTest2None(){
        Id serviceResourceId= SBR_3_0_ServiceTestDataFactory.createServiceResource();
 
        ServiceTerritory st= SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
        st.Branch_Location_Number__c='0693';
        test.startTest();
      
        list<sObject> rec=SBR_3_0_SfsGenericLookupController.fetchLookupData('test','Asset','None','SM_PS_Item_number__c');
             
        Assert.areEqual(rec.size(),0);
        Test.stopTest();
        
    }
}