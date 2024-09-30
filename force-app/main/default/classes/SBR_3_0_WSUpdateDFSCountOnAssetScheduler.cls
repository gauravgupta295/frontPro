/*********************************************************************************************************************
* Apex Class: SBR_3_0_WSUpdateDFSCountOnAssetScheduler
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Webservice to kick off the batch to update DFS count on ALL assets KM2023
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kedar Mudhalwadkar      2023-05-24           Initial version    
*********************************************************************************************************************/

//The webservice can be accessed using the following URL: {yourSalesforceInstance}/services/apexrest/startBatchJobAssetDFSCounter
// Apex Web Service to kick off the Batch Job
@RestResource(urlMapping='/startBatchJobAssetDFSCounter')
global class SBR_3_0_WSUpdateDFSCountOnAssetScheduler {
    @HttpGet
    //@HttpPost
    global static String startBatchJob() {
        // Check if the batch job is already running
        Boolean isBatchRunning = isBatchJobRunning();
        
        if (isBatchRunning) {
            return 'Batch job is already running. It will not be queued or retriggered.';
        } else {
            // Start the Batch Job
            SBR_3_0_BatchUpdateDFSCountOnAsset batchJob = new SBR_3_0_BatchUpdateDFSCountOnAsset();
            Database.executeBatch(batchJob);
        
            return 'Batch job started successfully.';
        }
    }
    
    // Method to check if the batch job is running
    private static Boolean isBatchJobRunning() {
        // Query the AsyncApexJob object to check if the batch job is in progress
        Integer runningBatchJobs = [SELECT count() FROM AsyncApexJob WHERE JobType = 'BatchApex' AND ApexClass.Name = 'SBR_3_0_BatchUpdateDFSCountOnAsset' AND Status IN ('Queued', 'Processing')];
        return (runningBatchJobs > 0);
    }
}