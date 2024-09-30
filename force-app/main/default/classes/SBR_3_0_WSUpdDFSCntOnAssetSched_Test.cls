/*********************************************************************************************************************
* Apex Class: SBR_3_0_WSUpdDFSCntOnAssetSched_Test
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - test class for 
----------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kedar Mudhalwadkar                          Initial version    
*********************************************************************************************************************/
@IsTest
private class SBR_3_0_WSUpdDFSCntOnAssetSched_Test 
{
    @IsTest
    static void testStartBatchJob() 
    {
               
        // Call the webservice
        Test.startTest();
        String response = SBR_3_0_WSUpdateDFSCountOnAssetScheduler.startBatchJob();
        Test.stopTest();
        
        // Verify that the batch job was not started again
        List<AsyncApexJob> batchJobs = [SELECT Id, Status FROM AsyncApexJob WHERE JobType = 'BatchApex' AND ApexClass.Name = 'SBR_3_0_BatchUpdateDFSCountOnAsset'];
        System.assertEquals(1, batchJobs.size());
        //System.assertEquals('Processing', batchJobs[0].Status);
    }
    
    @IsTest
    static void testStartBatchJob_NoRunningJobs() {
        // Call the webservice when no running batch jobs exist
        Test.startTest();
        String response = SBR_3_0_WSUpdateDFSCountOnAssetScheduler.startBatchJob();
        Test.stopTest();
        
        // Verify the response
        System.assertEquals('Batch job started successfully.', response);
        
        // Verify that the batch job was started
        List<AsyncApexJob> batchJobs = [SELECT Id, Status FROM AsyncApexJob WHERE JobType = 'BatchApex' AND ApexClass.Name = 'SBR_3_0_BatchUpdateDFSCountOnAsset'];
        System.assertEquals(1, batchJobs.size());
        //System.assertEquals('Queued', batchJobs[0].Status);
    }
}