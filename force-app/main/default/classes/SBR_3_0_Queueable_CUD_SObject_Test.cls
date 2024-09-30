/**
 * @description       : Test for Creating, Updating, and Deleting SObjects
 * @author            : Hashem Abdul
 * @group             : 
 * @last modified on  : 02-02-2024
 * @last modified by  : Hashem Abdul
**/
@isTest
public with sharing class SBR_3_0_Queueable_CUD_SObject_Test {
    /**
    * @description Test if SObject is being created
    * @author Hashem Abdul | 02-02-2024 
    **/
    @isTest
    public static void testQueueableCreate(){
        Account testAccount = SBR_3_0_TestDataFactory.createAccounts(1, false, 'Credit')[0];
        Test.startTest();
        System.enqueueJob(new SBR_3_0_Queueable_CUD_SObject(new List<SObject>{testAccount}, 'Create'));
        Test.stopTest();
        List<Account> accountCreated = [SELECT ID FROM Account];
        Assert.areEqual(1, accountCreated.size(), 'Account is not created');
    }
    /**
    * @description Test if SObject is being updated
    * @author Hashem Abdul | 02-02-2024 
    **/
    @isTest
    public static void testQueueableUpdate(){
        Account testAccount = SBR_3_0_TestDataFactory.createAccounts(1, true, 'Credit')[0];
        testAccount.Name = 'TestAccount';
        Test.startTest();
        System.enqueueJob(new SBR_3_0_Queueable_CUD_SObject(new List<SObject>{testAccount}, 'Update'));
        Test.stopTest();
        List<Account> accountUpdated = [SELECT ID, Name FROM Account];
        Assert.areEqual('TestAccount', accountUpdated[0].Name, 'Account is not updated');
    }
     /**
    * @description Test if SObject is being deleted
    * @author Hashem Abdul | 02-02-2024 
    **/
    @isTest
    public static void testQueueableDelete(){
        Account testAccount = SBR_3_0_TestDataFactory.createAccounts(1, true, 'Credit')[0];
        Test.startTest();
        System.enqueueJob(new SBR_3_0_Queueable_CUD_SObject(new List<SObject>{testAccount}, 'Delete'));
        Test.stopTest();
        List<Account> accountUpdated = [SELECT ID, Name FROM Account];
        Assert.areEqual(True, accountUpdated.isEmpty(), 'Account is not Deleted');
    }
}