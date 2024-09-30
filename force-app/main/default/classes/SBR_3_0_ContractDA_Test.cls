@isTest
public with sharing class SBR_3_0_ContractDA_Test {

    @TestSetup
    static void makeData(){
        SBR_3_0_TestDataFactory.createUsers(1, true);
    }
    
    @isTest
    public static void givenValidOwnerIdReturnValidContract(){
        User testUser = [SELECT Id FROM User LIMIT 1];
        List<Account> testAccounts = SBR_3_0_TestDataFactory.createAccounts(1, true);
        Contract contract = new Contract(ownerId = testUser.Id,AccountId=testAccounts[0].Id);
        insert contract;

        Test.startTest();
            List<Contract> contracts = SBR_3_0_ContractDA.getContractsByOwner(testUser.Id);
            System.assertEquals(contract.Id, contracts[0].Id);
        Test.stopTest();
    }
}