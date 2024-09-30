/*********************************************************************************************************************
* Apex Class: SBR_3_0_PSCTriggerTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description - Test class for the ProductServiceCampaign trigger
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME           DATE                 DETAIL FEATURES
*   1.0         Chhavi Singhal           2023-11-16           Initial version
*   2.0			Chhavi Singhal           2024-06-10           Added sendToRentalManDeletePSC() test method    
*********************************************************************************************************************/

@IsTest
private class SBR_3_0_PSCTriggerTest {
	@TestSetup
    static void dataSetup() {
        List<Account> accounts = SBR_3_0_TestDataFactory.createAccounts(1, true);
        List<Contact> contacts = SBR_3_0_TestDataFactory.createContacts(1, accounts[0].Id, true);
        List<Schema.Location> locs = SBR_3_0_TestDataFactory.createInventoryLocations(1, false, 'Branch');
        locs[0].Name = 'Test Location 2';
        insert locs;
        List<Asset> assets = SBR_3_0_TestDataFactory.createAssets(1, false, accounts[0].Id, contacts[0].Id, locs[0].Id);
        assets[0].SM_PS_Updated_in_SF__c = true;
        insert assets;
        
        ProductServiceCampaign pscRecord1 = new ProductServiceCampaign(ProductServiceCampaignName = 'TEST 1 PRODUCT SERVICE CAMPAIGN');
        pscRecord1.SM_PS_Company_Code__c = '01';
        pscRecord1.SM_PS_Labor_Code__c = '1234';
        pscRecord1.SM_PS_Maintenance_Step_Y_N__c = 'N';
        pscRecord1.Status = 'Draft';
        pscRecord1.SM_PS_Search_Word__c = 'TEST';
        pscRecord1.SM_PS_Step_Number__c = '20000';
        pscRecord1.StartDate = Date.newInstance(2023, 11, 6);
        pscRecord1.Type = 'Mandatory Non-Safety';
        insert pscRecord1;
        
        ProductServiceCampaign pscRecord2 = new ProductServiceCampaign(ProductServiceCampaignName = 'TEST 2 PRODUCT SERVICE CAMPAIGN');
        pscRecord2.SM_PS_Company_Code__c = '02';
        pscRecord2.SM_PS_Labor_Code__c = '5678';
        pscRecord2.SM_PS_Maintenance_Step_Y_N__c = 'N';
        pscRecord2.Status = 'Draft';
        pscRecord2.SM_PS_Search_Word__c = 'TEST2';
        pscRecord2.SM_PS_Step_Number__c = '20001';
        pscRecord2.StartDate = Date.newInstance(2024, 06, 10);
        pscRecord2.Type = 'Mandatory Non-Safety';
        insert pscRecord2;
        
        ProductServiceCampaignItem pscItemRecord1 = new ProductServiceCampaignItem();
        pscItemRecord1.ProductServiceCampaignId = pscRecord1.Id;
        pscItemRecord1.SVMXA360__DeliveryMethod__c = 'WorkOrder';
        pscItemRecord1.Status = 'Draft';
        pscItemRecord1.SM_PS_HowtoMaintain__c = 'O';
        pscItemRecord1.AssetId = assets[0].Id;
        insert pscItemRecord1;
    }

    @IsTest
    static void sendToRentalManWithSingleCompanyCode() {
        ProductServiceCampaign pscRec = [SELECT Id FROM ProductServiceCampaign WHERE ProductServiceCampaignName = 'TEST 1 PRODUCT SERVICE CAMPAIGN'];
        Test.startTest();
        {
            pscRec.SM_PS_Send_to_RM__c = true;
            pscRec.Status = 'New';
            update pscRec;
        }
        Test.stopTest();
        List<Outbox__c> results = getOutboxesByRecordIdAndSourceOfUpdate(
                pscRec.Id,
                SBR_3_0_PublishToOutboxWithoutQuery.CREATE_RECORD_SOURCE_OF_UPDATE
        );
        Assert.areEqual(1, results.size(), 'Outbox generated list size is not as expected.');
    }

    @IsTest
    static void sendToRentalManWithMultipleCompanyCodes() {
        ProductServiceCampaign pscRec = [SELECT Id FROM ProductServiceCampaign WHERE ProductServiceCampaignName = 'TEST 1 PRODUCT SERVICE CAMPAIGN'];
        Test.startTest();
        {
            pscRec.SM_PS_Company_Code__c = '02';
            pscRec.SM_PS_Send_to_RM__c = true;
            pscRec.Status = 'New';
            update pscRec;
        }
        Test.stopTest();
        List<Outbox__c> newOutboxes = getOutboxesByRecordIdAndSourceOfUpdate(
                pscRec.Id,
                SBR_3_0_PublishToOutboxWithoutQuery.CREATE_RECORD_SOURCE_OF_UPDATE
        );
        List<Outbox__c> deleteOutboxes = getOutboxesByRecordIdAndSourceOfUpdate(
                pscRec.Id,
                SBR_3_0_PublishToOutboxWithoutQuery.DELETE_RECORD_SOURCE_OF_UPDATE
        );
        Assert.areEqual(1, newOutboxes.size(), 'Outbox generated list size is not as expected.');
        Assert.areEqual(1, deleteOutboxes.size(), 'Outbox deleted list size is not as expected.');
        Assert.isTrue(newOutboxes[0].Record_JSON__c.contains('"SM_PS_Company_Code__c":"02"'), 'newOutboxes does not contain Company Code 02');
        Assert.isTrue(deleteOutboxes[0].Record_JSON__c.contains('"SM_PS_Company_Code__c":"01"'), 'deleteOutboxes does not contain Company Code 01');
    }

    @IsTest
    static void sendToRentalManDeletePSC() {
        ProductServiceCampaign pscRec = [SELECT Id FROM ProductServiceCampaign WHERE ProductServiceCampaignName = 'TEST 2 PRODUCT SERVICE CAMPAIGN'];
        pscRec.SM_PS_Send_to_RM__c = true;
        pscRec.Status = 'New';
        update pscRec;
        Test.startTest();
        {
        	delete pscRec;
        }
        Test.stopTest();
        List<Outbox__c> results = getOutboxesByRecordIdAndSourceOfUpdate(
                pscRec.Id,
                SBR_3_0_PublishToOutboxWithoutQuery.DELETE_RECORD_SOURCE_OF_UPDATE
        );
        Assert.areEqual(1, results.size(), 'Result size is not as expected.');
    }

    @IsTest
    static void pscRecAfterUpdateScenario() {
        ProductServiceCampaign pscRec = [SELECT Id FROM ProductServiceCampaign WHERE ProductServiceCampaignName = 'TEST 1 PRODUCT SERVICE CAMPAIGN'];
        pscRec.SM_PS_Send_to_RM__c = true;
        pscRec.Status = 'New';
        update pscRec;
        
        ProductServiceCampaignItem pscItemRec = [SELECT Id FROM ProductServiceCampaignItem];
        pscItemRec.Status = 'OutputGenerated';
        update pscItemRec;
        
        Test.startTest();
        {
            pscRec.SM_PS_Est_Hrs_to_Complete__c = 8;
            update pscRec;
        }
        Test.stopTest();
        List<Outbox__c> results = getOutboxesByRecordIdAndSourceOfUpdate(
                pscItemRec.Id,
                SBR_3_0_PublishToOutboxWithoutQuery.UPDATE_RECORD_SOURCE_OF_UPDATE
        );
		
        Assert.areEqual(1, results.size(), 'Result size is not as expected.');
        Assert.isTrue(results[0].Record_JSON__c.contains('"SM_PS_EstHrstoComplete__c":8.00'), 'newOutboxes does not contain SM_PS_EstHrstoComplete__c : 8.00');
    }
    
    private static List<Outbox__c> getOutboxesByRecordIdAndSourceOfUpdate(Id recordId, String recordSourceOfUpdate) {
        return [
                SELECT
                        Id, Record_JSON__c, Record_Source_Of_Update__c
                FROM
                        Outbox__c
                WHERE
                        Record_Id__c = :recordId AND
                        Record_Source_Of_Update__c = :recordSourceOfUpdate
        ];
    }
}