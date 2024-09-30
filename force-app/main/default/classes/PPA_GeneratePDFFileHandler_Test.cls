@isTest
private class PPA_GeneratePDFFileHandler_Test {

    @TestSetup
    static void testSetup(){
        PPA_GeneratePDFUtility_Test.makeData();    
    }

    @isTest
    static void linkDocumentToPriceListTest() {
        PPA_Price_List__c priceList = [SELECT Id FROM PPA_Price_List__c LIMIT 1];        

        // Create a test PDF body
        Blob pdfBody = Blob.valueOf('Test PDF Content');
        
        // Call the method being tested
        Test.startTest();
        Map<String, String> result = PPA_GeneratePDFFileHandler.linkDocumentToPriceList(priceList.Id, 'TEST', true, pdfBody);
        Test.stopTest();
        
        // Assertions
        System.assertEquals('0', result.get('errorCode'), 'Expected errorCode to be 0');
        System.assertEquals('Completed', result.get('status'), 'Expected status to be Completed');        
    }
    
    @isTest
    static void linkDocumentToPriceListTestException() {
        // Create a test PDF body
        Blob pdfBody = Blob.valueOf('Test PDF Content');
        
        // Simulate an exception during ContentVersion insertion
        Test.startTest();
        Map<String, String> result = PPA_GeneratePDFFileHandler.linkDocumentToPriceList('TEST', 'TEST', true, pdfBody);
        Test.stopTest();
        
        // Assertions
        System.assertEquals('-1', result.get('errorCode'), 'Expected errorCode to be -1');
    }    
}