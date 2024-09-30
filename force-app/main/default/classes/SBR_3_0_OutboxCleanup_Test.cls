/**
 * Apex Class: SBR_3_0_OutboxCleanupTest
 * @description Test class for SBR_3_0_OutboxCleanup apex class
*/
@isTest
private class SBR_3_0_OutboxCleanup_Test{

    /**
     * @description - testing the Execute method
     */
    @isTest
    static void testExecute() {
        List<Outbox__c> testOutboxes = new List<Outbox__c>();
        for (Integer i = 0; i < 10; i++) {
            testOutboxes.add(new Outbox__c(Name='Test Outbox'));
        }

        insert testOutboxes;
        for(Outbox__c rec: [SELECT Id FROM Outbox__c WHERE Name='Test Outbox' LIMIT 10]){
            Test.setCreatedDate(rec.Id, DateTime.newInstance(2024,1,1));
        }
        Test.startTest();
        SBR_3_0_OutboxCleanup cleanUpBatch = new SBR_3_0_OutboxCleanup();
        //System.schedule('testSBR_3_0_OutboxCleanupScheduledApex', cronExpression, cleanUpBatch);
        cleanUpBatch.execute(null);
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM Outbox__c WHERE Name='Test Outbox'], 'Found unexpected outbox records');
    }
}