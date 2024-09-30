@isTest
private class PPA_ExportToERPController_Test {

    @isTest
    static void testGetItemsReadyForExport() {
        // Test method to test getItemsReadyForExport() in PPA_ExportToERPController
        // Create test data: Price List records with PPA_Export_Status__c = 'Ready'
        List <PPA_Price_List__c> testPriceLists = new List<PPA_price_List__C>();
        String RecordTypeId;
        
        RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'PPA_Price_List__c' AND DeveloperName='PPA_Extension'].Id;
        
        for (Integer i = 0; i < 5; i++) {
            PPA_Price_List__c pl = new PPA_Price_List__c(
            	RecordTypeId = RecordTypeId,
				Name = 'Test Price List ' + i,
            	PPA_Export_Status__c = 'Ready'
            );

            testPriceLists.add(pl);
        }

        insert testPriceLists;
        
        Test.startTest();
        List<PPA_Price_List__c> result = PPA_ExportToERPController.getItemsReadyForExport();
        Test.stopTest();
        
        // Assert that the correct number of records with PPA_Export_Status__c = 'Ready' is returned
        System.assertEquals(5, result.size());
    }

    @isTest
    static void testOverrideVerificationStatus() {
        // Test method to test overrideVerificationStatus() in PPA_ExportToERPController
        // Create test data: Price List record with PPA_Export_Status__c = 'Ready' and PPA_Verification_Status__c = 'Unverified'
        PPA_Price_List__c testPriceList = new PPA_Price_List__c(
            Name = 'Test Price List',
            PPA_Export_Status__c = 'Ready',
            PPA_Verification_Status__c = 'Unverified'
        );
        
        insert testPriceList;
        
        Test.startTest();
        PPA_ExportToERPController.overrideVerificationStatus(testPriceList.Id, 'Test Override Reason');
        Test.stopTest();
        
        // Retrieve the updated record and assert the changes
        PPA_Price_List__c updatedPriceList = [SELECT Id, PPA_Verification_Status__c, PPA_Export_Override_Comments__c
        										FROM PPA_Price_List__c
        									   WHERE Id = :testPriceList.Id];
        
        // Assert that the Verification Status is updated to 'Overridden'
        System.assertEquals('Overridden', updatedPriceList.PPA_Verification_Status__c, 'Verification Status should be Overridden');
        
        // Assert that the PPA_Export_Override_Comments__c field is updated with the correct value
        System.assertEquals('Test Override Reason', updatedPriceList.PPA_Export_Override_Comments__c, 'Comments were not populated as expected');
    }

    @isTest
    static void testOverrideVerificationStatus_PriceListNotFound() {
        // Test method to test handling when Price List is not found
        PPA_Price_List__c testPriceList = new PPA_Price_List__c(
            Name = 'Test Price List',
            PPA_Export_Status__c = 'Ready',
            PPA_Verification_Status__c = 'Unverified'
        );

        insert testPriceList;
        
        Test.startTest();
        PPA_ExportToERPController.overrideVerificationStatus('', 'Test Override Reason');
        Test.stopTest();
        
        // Retrieve the updated record and assert the changes
        PPA_Price_List__c updatedPriceList = [SELECT Id, PPA_Verification_Status__c, PPA_Export_Override_Comments__c
        										FROM PPA_Price_List__c
        									   WHERE Id = :testPriceList.Id];

        // Assert that the Verification Status is still 'Unverified'
        System.assertEquals('Unverified', updatedPriceList.PPA_Verification_Status__c, 'Verification Status should be Unverified');       
    }
}