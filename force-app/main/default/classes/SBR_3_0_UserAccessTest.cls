@isTest
public with sharing class SBR_3_0_UserAccessTest {
    @TestSetup
    static void makeData(){
        // Create Price Book
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;
        
        Order testOrder = SBR_3_0_TestDataFactory.createOrder(false, 'test', SBR_3_0_Constants.ORDER_REC_TYPE_CONTRACT_ORDER_ID);
        testOrder.Name = 'Test Order';
        insert testOrder;
        
        User testUser = SBR_3_0_TestDataFactory.createUsers(1, false)[0];
        testUser.FirstName = 'Test';
        testUser.LastName = 'User';
        insert testUser;
    }
    
    @isTest
    static void validateSubmitReservationTest() {
        List<Order> orders = [SELECT Id FROM Order WHERE Name = 'Test Order'];
        List<Id> orderIds = new List<Id>();
        orderIds.add(orders[0].Id);
        User u = [SELECT Id FROM User WHERE Name = 'Test User' LIMIT 1][0];
        List<Boolean> results;
        Boolean validateUser;
        System.runAs(u) {
            Test.startTest();
                results = SBR_3_0_UserAccess.validateSubmitReservation(orderIds);
            	validateUser = SBR_3_0_UserAccess.validateUserAccess(orderIds[0]);
            Test.stopTest();
        }
        System.assertEquals(false, results[0], 'Result did not return false');
        System.assertEquals(false, validateUser, 'Result did not return false for User Access');
    }
}