/*********************************************************************************************************************
* Apex Class: SBR_3_0_SchedulerUpdateDFSCountOnAsset
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - DO NOT SCHEDULE, WS EXPECTED TO KICK THIS BATCH
* - Schedule batch to update DFS count on ALL assets KM2023
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kedar Mudhalwadkar      2023-05-24           Initial version    
*********************************************************************************************************************/


// Apex class to schedule the batch job
public class SBR_3_0_SchedulerUpdateDFSCountOnAsset implements Schedulable {
    public void execute(SchedulableContext context) {
        SBR_3_0_BatchUpdateDFSCountOnAsset batchJob = new SBR_3_0_BatchUpdateDFSCountOnAsset();
        
        // Start the batch job
        Database.executeBatch(batchJob);
    }
}