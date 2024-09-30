@isTest
private class SBR_3_0_PurchaseOrderIntCommCntrl_Test {

    @testSetup
    private static void setup() {
        // Create a test Purchase Order record
        Purchase_Order__c testPO = new Purchase_Order__c(
            Name = 'Test PO'
        );
        insert testPO;
    }

    @isTest
    private static void testGetInternalComments() {
        Purchase_Order__c testPO = [SELECT Id FROM Purchase_Order__c WHERE NAME = 'Test PO'];
        
        // Call the controller method
        Test.startTest();
        List<PO_Internal_Comments__c> commentsList = SBR_3_0_PurchaseOrderIntCommCntrl.getInternalComments(testPO.Id);
        Test.stopTest();

        // Add assertion statements
    }

    @isTest
    private static void testCreatePOInternalComments() {
        Purchase_Order__c testPO = [SELECT Id FROM Purchase_Order__c WHERE NAME = 'Test PO' LIMIT 1];
        // Create an existing comment near the maximum length
        String newComment1 = 'New Test Comment 1';
        String newComment2 = 'New Test Comment 2';
        Date commentDate = Date.today();
        
        // Call the controller method
        Test.startTest();
        SBR_3_0_PurchaseOrderIntCommCntrl.createOrUpdatePOInternalComments(testPO.Id, null, null, newComment1, null, null);
        SBR_3_0_PurchaseOrderIntCommCntrl.createOrUpdatePOInternalComments(testPO.Id, null, null, newComment1, commentDate, null);
        SBR_3_0_PurchaseOrderIntCommCntrl.createOrUpdatePOInternalComments(testPO.Id, null, null, newComment2, commentDate, null);
        Id selectedCommentIds = [SELECT Id FROM PO_Internal_Comments__c WHERE Purchase_Order__c = :testPO.Id AND Created_By__c = 'DEPLOY' LIMIT 1].Id;
        SBR_3_0_PurchaseOrderIntCommCntrl.createOrUpdatePOInternalComments(testPO.Id, selectedCommentIds, newComment1, newComment2, commentDate, null);
        Test.stopTest();

        // Add assertion statements
    }

    @isTest
    private static void testCreateOrUpdatePOInternalComments_WithMaxLength() {
        Purchase_Order__c testPO = [SELECT Id FROM Purchase_Order__c WHERE NAME = 'Test PO' LIMIT 1];
        String newComment1 = 'New Test Comment 1';
        String newComment2 = 'New Test Comment 2';
        String existingComment = '';
        Date commentDate = Date.today();
        
        // Create an existing comment near the maximum length
        Integer maxLength = 1960;
        while (existingComment.length() < maxLength) {
            existingComment += 'x';
        }
        
        // Call the controller method with a new comment that exceeds the maximum length
        Test.startTest();
        SBR_3_0_PurchaseOrderIntCommCntrl.createOrUpdatePOInternalComments(testPO.Id, null, '', existingComment, commentDate, null);
        SBR_3_0_PurchaseOrderIntCommCntrl.createOrUpdatePOInternalComments(testPO.Id, null, newComment1, newComment2, commentDate, null);
        Test.stopTest();
        
        // Add assertion statements
        // You can add assertions here to verify that a new comment was created
    }

}