/*********************************************************************************************************************
* Apex Class: SBR_3_0_PSCItemTriggerTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for the ProductServiceCampaignItem trigger
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME           DATE                 DETAIL FEATURES
1.0             Chhavi Singhal           2023-11-27           Initial version
*********************************************************************************************************************/

@IsTest
private class SBR_3_0_PSCItemTriggerTest {
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
        pscRecord1.SM_PS_Est_Hrs_to_Complete__c = 4;
        pscRecord1.SM_PS_Search_Word__c = 'TEST';
        pscRecord1.SM_PS_Step_Number__c = '20000';
        pscRecord1.StartDate = Date.newInstance(2023, 11, 6);
        pscRecord1.Type = 'Mandatory Non-Safety';
        insert pscRecord1;
        
        ProductServiceCampaignItem pscItemRecord1 = new ProductServiceCampaignItem();
        pscItemRecord1.ProductServiceCampaignId = pscRecord1.Id;
        pscItemRecord1.SVMXA360__DeliveryMethod__c = 'WorkOrder';
        pscItemRecord1.Status = 'Draft';
        pscItemRecord1.SM_PS_HowtoMaintain__c = 'O';
        pscItemRecord1.AssetId = assets[0].Id;
        insert pscItemRecord1;
    }
    
    @IsTest
    static void recordSrcOfUpdate_Created() {
        ProductServiceCampaignItem pscItemRec = [SELECT Id FROM ProductServiceCampaignItem];
        Test.startTest();
        {
            pscItemRec.Status = 'OutputGenerated';
            update pscItemRec;
        }
        Test.stopTest();
        List<Outbox__c> results = getOutboxesByRecordIdAndSourceOfUpdate(
                pscItemRec.Id,
                SBR_3_0_PublishToOutboxWithoutQuery.CREATE_RECORD_SOURCE_OF_UPDATE
        );
        Assert.areEqual(1, results.size());
    }

    @IsTest
    static void beforeDelete() {
        ProductServiceCampaignItem pscItemRec = [SELECT Id FROM ProductServiceCampaignItem];
        pscItemRec.Status = 'OutputGenerated';
        update pscItemRec;
        Boolean encounteredException = false;
        Test.startTest();
        {
            try {
                delete pscItemRec;
            } catch (Exception e) {
                encounteredException = true;
            }
        }
        Test.stopTest();
        Assert.isTrue(encounteredException);
    }

    @IsTest
    static void afterDelete() {
        ProductServiceCampaignItem pscItemRec = [SELECT Id FROM ProductServiceCampaignItem];
        Test.startTest();
        {
            delete pscItemRec;
        }
        Test.stopTest();
        List<Outbox__c> results = getOutboxesByRecordIdAndSourceOfUpdate(
                pscItemRec.Id,
                SBR_3_0_PublishToOutboxWithoutQuery.DELETE_RECORD_SOURCE_OF_UPDATE
        );
        Assert.areEqual(0, results.size());
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