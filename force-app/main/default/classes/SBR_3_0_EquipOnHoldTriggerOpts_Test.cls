@isTest
private class SBR_3_0_EquipOnHoldTriggerOpts_Test {
    @isTest
    static void testUpdateContractOrderApplied() {
        // Create a company code and a contract order number
        String companyCode = 'TC';
        String contractOrderNumber = '12345';
        
        // Create an order record with the above company code and contract order number
        Order testOrder = new Order();
        testOrder.Company_Code__c = companyCode;
        testOrder.Contract_Order_Number__c = contractOrderNumber;
       // testOrder.RecordTypeId = Test.getRecordTypeId(RecordType.SObjectType, 'Order.Contract_Order');
        insert testOrder;
        
        // Create an equipment on hold record with the above company code and contract order number
        Equipment_on_Hold__c testEquipOnHold = new Equipment_on_Hold__c(SM_PS_Company_Code__c = companyCode, SM_PS_Contract_Applied__c = contractOrderNumber, SM_PS_Status__c = 'Filled');
        insert testEquipOnHold;
        
        // Call the updateContractOrderApplied method with the new and old maps
        Map<Id, Equipment_on_Hold__c> oldMap = new Map<Id, Equipment_on_Hold__c>();
        oldMap.put(testEquipOnHold.Id, new Equipment_on_Hold__c());
        Map<Id, Equipment_on_Hold__c> newMap = new Map<Id, Equipment_on_Hold__c>();
        newMap.put(testEquipOnHold.Id, testEquipOnHold);
        List<Equipment_on_Hold__c> newList = new List<Equipment_on_Hold__c>{testEquipOnHold};
        SBR_3_0_EquipOnHoldTriggerOperations.updateContractOrderApplied(oldMap, newMap, newList, true);
        
        // Verify that the equipment on hold record has the correct contract order ID
        testEquipOnHold = [SELECT SM_PS_Contract_Order_Applied__c FROM Equipment_on_Hold__c WHERE Id = :testEquipOnHold.Id];
        System.assertEquals(testOrder.Id, testEquipOnHold.SM_PS_Contract_Order_Applied__c, 'The contract order ID on the Equipment_on_Hold__c record was not set correctly');
    }
}