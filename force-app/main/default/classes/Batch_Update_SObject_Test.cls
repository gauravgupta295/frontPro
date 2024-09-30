@isTest
public class Batch_Update_SObject_Test {

    @isTest
    static void testBatch_Update_SObject() {
       List<Outbox__c> testOutboxes = new List<Outbox__c>();
        for (Integer i = 0; i < 10; i++) {
            Outbox__c o = new Outbox__c(Name='Test Outbox');
            testOutboxes.add(o);
        }
        insert testOutboxes;
		String query = 'SELECT Id FROM Outbox__c WHERE CreatedDate = LAST_N_DAYS:30';
		Test.startTest();
        Batch_Update_SObject batchUpdateSObject = new Batch_Update_SObject(query);
        Database.executeBatch(batchUpdateSObject);
        Test.stopTest();
		List<Outbox__c> remainingOutboxes = [SELECT Id FROM Outbox__c];
        System.assertEquals(0, remainingOutboxes.size(), 'Records were not deleted as expected');
    }
}