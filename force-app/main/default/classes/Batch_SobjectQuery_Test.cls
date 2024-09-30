/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-16-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class Batch_SobjectQuery_Test {
    @isTest
    static void queryBatchSObjectTest(){
        Integer numRecordsToProcess = 200;
        
        SBR_3_0_TriggerHandler.bypass('SBR_3_0_AccountTriggerHandler');
        List<Account> accts = SBR_3_0_TestDataFactory.createAccounts(numRecordsToProcess, true, 'Credit');

        String query = 'SELECT Id, Name, RecordTypeId, RecordType.Name FROM Account';
        
        Test.startTest();
        Id batchprocessid = Database.executeBatch(new Batch_SobjectQuery(query));
        Test.stopTest();
        
        System.assertEquals(numRecordsToProcess, [select count() from Account]);
    }
}