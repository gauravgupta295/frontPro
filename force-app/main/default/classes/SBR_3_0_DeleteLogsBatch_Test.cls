@isTest
private class SBR_3_0_DeleteLogsBatch_Test {
    
    static testMethod void testLoadBatch() {
        
        List<Exception_Log__c> logs = new List<Exception_Log__c>();
        DateTime olderDate = System.now().addDays(-10); 
        for (Integer i = 0; i < 200; i++) {
            logs.add(new Exception_Log__c(CreatedDate = olderDate));
        }
        insert logs;
        
        // Create the custom setting for LoggerSettings__c record
        LoggerSettings__c logSettings = new LoggerSettings__c(DefaultNumberOfDaysToRetainLogs__c = 5);
        insert logSettings;
        
        SBR_3_0_DeleteLogsBatch batch = new SBR_3_0_DeleteLogsBatch();
        Test.startTest();
        Database.executeBatch(batch, 200); 
        Test.stopTest();
        
        Integer deletedRecordCount = [SELECT COUNT() FROM Exception_Log__c WHERE CreatedDate < :olderDate];
        System.assertEquals(0, deletedRecordCount, 'All records older than 5 days should be deleted');
    }
        
        static testMethod void testScheduler() {
            
            SBR_3_0_DeleteLogsBatchScheduler scheduler = new SBR_3_0_DeleteLogsBatchScheduler();
            
            // Schedule the job
            Test.startTest();
            String jobId = System.schedule('Test DeleteLogsBatchScheduler', '0 0 1 * * ? *', scheduler);
            Test.stopTest();
            
            CronTrigger scheduledJob = [SELECT Id FROM CronTrigger WHERE Id = :jobId LIMIT 1];
            System.assertNotEquals(null, scheduledJob, 'Scheduler job should be scheduled');
        }   
}