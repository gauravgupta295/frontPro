/*********************************************************************************************************************
* Apex Class: SBR_3_0_BatchUpdateDFSCountOnAsset_Test
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - test class for SBR_3_0_BatchUpdateDFSCountOnAsset
----------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kedar Mudhalwadkar      2023-05-24           Initial version    
*********************************************************************************************************************/

@IsTest
private class SBR_3_0_BatchUpdateDFSCountOnAsset_Test {
    @testSetup
    static void createAssetData(){
        //Create test data - Asset records
        
        List<Account> testAccount = SBR_3_0_TestDataFactory.createAccounts(1, true);
        List<Contact> testContact = SBR_3_0_TestDataFactory.createContacts(1, testAccount[0].Id, true);
        List<Schema.Location> branch = SBR_3_0_TestDataFactory.createInventoryLocations(1,true,'Branch');
        branch[0].Branch_Location_Number__c = '0101';
        update branch;
        List<Asset> testAsset = SBR_3_0_TestDataFactory.createAssets(1,true,testAccount[0].Id,testContact[0].Id,branch[0].Id);
        testAsset[0].SM_PS_Cat_Class__c = '0020080';
        testAsset[0].SM_PS_Steps_Due_for_Service__c = null;
        update testAsset;
        
        // Create test data - DueForService__c records
        List<DueForService__c> dfsList = new List<DueForService__c>();
        for (Integer i = 1; i <= 5; i++) {
            DueForService__c dfs = new DueForService__c();
            dfs.SM_PS_Equipment_Number__c = testAsset[0].Id;
            dfsList.add(dfs);
        }
        insert dfsList;
    }

    @IsTest
    static void testBatchJob() {        
        // Run the batch job
        Test.startTest();
        SBR_3_0_BatchUpdateDFSCountOnAsset batchJob = new SBR_3_0_BatchUpdateDFSCountOnAsset();
        Database.executeBatch(batchJob);
        Test.stopTest();
        // Verify the asset records were updated correctly
        List<Asset> updatedAssets = [SELECT Id, SM_PS_Steps_Due_for_Service__c FROM Asset];
        System.assertEquals(1, updatedAssets.size());
        System.assertEquals(5, updatedAssets[0].SM_PS_Steps_Due_for_Service__c);

        // Verify the error  was sent
        List<EmailMessage> sentEmails = [SELECT Id, Subject, TextBody FROM EmailMessage];
        System.assertEquals(1, sentEmails.size());
        System.assertEquals('Completed execution SBR_3_0_BatchUpdateDFSCountOnAsset', sentEmails[0].Subject);
        
        // Verify the message in the email body
        System.assert((sentEmails[0].textBody).contains('SBR_3_0_BatchUpdateDFSCountOnAsset batch job completed successfully'));
        
    }
}