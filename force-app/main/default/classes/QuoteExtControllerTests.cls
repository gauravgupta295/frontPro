@isTest
private class QuoteExtControllerTests {
    
    	@isTest
    	static void testSubmit() {
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.Account_Record_Type_Txt__c='Credit';
        insert quote;
        
        Test.startTest();
        QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(quote));
        con.onSubmit();
        quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        Test.stopTest();
        
        System.assertEquals('Approved', quote.ApprovalStatus__c,'Assertion error');
    }
    
    	@isTest
    	static void testRecall() {
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.Account_Record_Type_Txt__c='Credit';
        insert quote;
        
        Test.startTest();
        QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(quote));
        con.onRecall();
        quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        Test.stopTest();
        
        System.assertEquals('Recalled', quote.ApprovalStatus__c,'Assertion Error');
    }
}