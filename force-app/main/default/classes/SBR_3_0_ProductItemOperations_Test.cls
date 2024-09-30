/*********************************************************************************************************************
* Apex Class: SBR_3_0_ProductItemOperations_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test Class to manage handler logic for Product Items
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME      DATE            DETAIL FEATURES
    1.0         Alex DeVries        2022-11-15      Initial version (SAL-5640)
*********************************************************************************************************************/

@isTest
public with sharing class SBR_3_0_ProductItemOperations_Test
{
    @TestSetup
    static void makeData()
    {
        // if necessary, create Product Item outbox worker control record
        List<Outbox_MuleSoft_Worker_Control__c> prodItemWorkerControlList = [SELECT Id FROM Outbox_MuleSoft_Worker_Control__c
            WHERE Worker_Record_Type__c = 'ProductItem' AND Worker_Status__c = 'Active'];
        if(prodItemWorkerControlList.isEmpty())
        { insert new Outbox_MuleSoft_Worker_Control__c(Worker_Record_Type__c='ProductItem', Worker_Status__c='Active'); }
    }

    @isTest static void publishProductItemTest()
    {
        // create products
        List<Product2> prodList = SBR_3_0_TestDataFactory.createProducts(3, true);
        System.assertEquals(3, prodList.size());

        // create locations
       // List<Schema.Location> locList = SBR_3_0_TestDataFactory.createLocations(3, false, 'Branch');
        //for(Schema.Location loc : locList) { loc.IsInventoryLocation = true; }
        Schema.Location jobLocation = new Schema.Location();
        jobLocation.Name = 'Test Job Location';
        jobLocation.Street_Address__c = '12 Main Street';
        jobLocation.City__c = 'Toronto';
        jobLocation.Zip_Code__c = 'M7N7B3';
        jobLocation.State__c = 'ON';
        jobLocation.Country__c = 'CA';
        jobLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_JOB_RT_ID;
        jobLocation.OMS_Sourcing_Enabled__c = true;
        jobLocation.Distance_Multiplier__c = 50;
        jobLocation.Analysis_Region_Key__c = '001';
        jobLocation.Company_Code__c = '01';
        jobLocation.IsInventoryLocation = true;
        insert jobLocation;
        try{
        insert jobLocation;
        }
        catch(Exception e)
        {
           System.debug('The following exception has occurred:'+e.getMessage());
             Schema.Location jobLocation1 = new Schema.Location();
        jobLocation1.Name = 'Test Job Location';
        jobLocation1.Street_Address__c = '12 Main Street';
        jobLocation1.City__c = 'Toronto';
        jobLocation1.Zip_Code__c = 'M7N7B3';
        jobLocation1.State__c = 'ON';
        jobLocation1.Country__c = 'CA';
        jobLocation1.RecordTypeId = SBR_3_0_Constants.LOCATION_JOB_RT_ID;
        jobLocation1.OMS_Sourcing_Enabled__c = true;
        jobLocation1.Distance_Multiplier__c = 50;
        jobLocation1.Analysis_Region_Key__c = '001';
        jobLocation1.Company_Code__c = '01';
        jobLocation1.IsInventoryLocation = true;
        insert jobLocation1;
             System.debug('jobLocation:'+jobLocation1);
        }
        //System.assertEquals(3, jobLocation.size());
        
        // create product items
        List<ProductItem> prodItemList = new List<ProductItem>();
        for(Integer i = 0; i < prodList.size(); i++)
        { prodItemList.addAll(SBR_3_0_TestDataFactory.createProductItems(1, false, prodList.get(i).Id, jobLocation.Id)); }

        insert prodItemList;

        // update product items
        for(ProductItem prodItem : prodItemList)
        { prodItem.SM_PS_Quantity_Available__c = 1; }
        update prodItemList;

        // assert existence of outbox records
        Set<string> prodItemIdSet = new Set<string>();
        for(ProductItem prodItem : prodItemList) { prodItemIdSet.add(prodItem.Id); }

        List<Outbox__c> outboxRecordList = [SELECT Id FROM Outbox__c WHERE Record_Id__c IN :prodItemIdSet];
        system.assertEquals(prodItemList.size(), outboxRecordList.size());
    }
}