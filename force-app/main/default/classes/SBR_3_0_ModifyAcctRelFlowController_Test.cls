@isTest
private class SBR_3_0_ModifyAcctRelFlowController_Test {
    
    @TestSetup
    static void makeData(){        
        List<Account> accountList = SBR_3_0_TestDataFactory.createAccounts(2, true, SBR_3_0_Constants.ACCOUNT_REC_TYPE_PROSPECT);       
    }
    
    @isTest
    static void modifyAcctRelFlowControllerTest() {
        
        String accountId = [Select Id,Name from account LIMIT 1].Id;
        
        List<Account_Relationship__c> testAccountRelationships = new List<Account_Relationship__c>();
        for (Integer i = 0; i < 5; i++) {
            testAccountRelationships.add(new Account_Relationship__c(Name = 'Test Relationship ' + i, Account_ID__c= accountId));
        }
        insert testAccountRelationships;
        
        List<Account_Relationship__c> selectedRecords = [SELECT Id,Name FROM Account_Relationship__c LIMIT 3];
        
        ApexPages.StandardSetController standardSetController = new ApexPages.StandardSetController(testAccountRelationships);
        standardSetController.setSelected(selectedRecords);
        
        SBR_3_0_ModifyAcctRelFlowController controller = new SBR_3_0_ModifyAcctRelFlowController(standardSetController);
        
        List<Id> arIds = controller.arIds;
        System.assertEquals(3, arIds.size(), 'Unexpected number of arIds');
        for (Account_Relationship__c selectedRecord : selectedRecords) {
            System.assert(arIds.contains(selectedRecord.Id), 'arIds does not contain the expected record');
        }
    }
}