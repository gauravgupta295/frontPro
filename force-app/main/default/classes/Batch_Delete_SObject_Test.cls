/**
 * @description       : 
 * @author            : Hamza B
 * @group             : SBR Sales team
 * @last modified on  : 11-16-2023
 * @last modified by  : Hamza B
**/
@isTest
public class Batch_Delete_SObject_Test {
    
    @isTest
    static void deleteRecordsTest(){
        Integer numRecordsToProcess = 200;
        
        SBR_3_0_TriggerHandler.bypass('SBR_3_0_AccountTriggerHandler');
        List<Account> accts = SBR_3_0_TestDataFactory.createAccounts(numRecordsToProcess, true);

        String query = 'SELECT Id, Name FROM Account';
        
        Test.startTest();
        Id batchprocessid = Database.executeBatch(new Batch_Delete_SObject(query));
        Test.stopTest();
        
         System.assertEquals(0, [select count() from Account]);
        
    }
}