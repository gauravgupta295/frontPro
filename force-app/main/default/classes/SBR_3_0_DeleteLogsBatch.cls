public class SBR_3_0_DeleteLogsBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    private Decimal retentionDays;
    private List<Exception_Log__c> failedRecords = new List<Exception_Log__c>();
    
    public SBR_3_0_DeleteLogsBatch() {
        LoggerSettings__c settings = LoggerSettings__c.getOrgDefaults();
        retentionDays = settings.DefaultNumberOfDaysToRetainLogs__c;
    }
    
    public Database.QueryLocator start(Database.BatchableContext context) {
        if(retentionDays == NULL){
            return null;
        }else{
            Integer retentionDaysInteger = retentionDays.intValue();
            
            // Query Exception_Log__c records to be deleted
            DateTime cutoffDate = System.now().addDays(6);
            
            return Database.getQueryLocator([
                SELECT Id,CreatedDate
                FROM Exception_Log__c
                WHERE CreatedDate <= :cutoffDate
            ]);
        }        
    }
    
    public void execute(Database.BatchableContext context, List<Exception_Log__c> scope) {
        List<Exception_Log__c> recordsToDelete = new List<Exception_Log__c>();        
        for (Exception_Log__c log : scope) {
            recordsToDelete.add(log);
        }
        system.debug('recordsToDelete::'+recordsToDelete[0]);
        if (!recordsToDelete.isEmpty()) {
            try {
                
                Database.DeleteResult[] deleteResults = Database.delete(recordsToDelete, false);
                
                // Check the results and add failed records to the failedRecords list
                for (Integer i = 0; i < deleteResults.size(); i++) {
                    if (!deleteResults[i].isSuccess()) {
                        failedRecords.add(recordsToDelete[i]);
                    }
                }
                
            } catch (Exception e) {
                SBR_3_0_Log.logException(e);
            }
            finally{
                SBR_3_0_Log.saveLog();
            }
        }
    }
    
    public void finish(Database.BatchableContext context) {
        String failedRecordsJSON;
        if(!failedRecords.isEmpty()){
            failedRecordsJSON = JSON.serialize(failedRecords);
        }
        try{
            if(!String.isBlank(failedRecordsJSON) && !String.isEmpty(failedRecordsJSON)){
                SBR_3_0_Log.logInfo(failedRecordsJSON);
            }
        }catch(Exception e){
            SBR_3_0_Log.logException(e);
        }finally{
            SBR_3_0_Log.saveLog();
        }
        
    }
}