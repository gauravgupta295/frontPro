public class SBR_3_0_DeleteLogsBatchScheduler implements Schedulable{
    public void execute(SchedulableContext sc) {
        SBR_3_0_DeleteLogsBatch batch = new SBR_3_0_DeleteLogsBatch();
        if(!Test.isRunningTest()){
		Id batchId = Database.executeBatch(batch);
        system.debug('DeleteLogsBatch Batch Id: ' + batchId);
        }
    }
}