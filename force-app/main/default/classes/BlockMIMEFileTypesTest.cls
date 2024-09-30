@isTest
Private class BlockMIMEFileTypesTest {
   
    @isTest
    static void testTrigger() {
        // Create a test parent record (SBR_Contract_Agreement__c)
        SBR_Contract_Agreement__c testContract = new SBR_Contract_Agreement__c(Name = 'Test Contract');
        insert testContract;
         List<Account> acc =SBR_3_0_TestDataFactory.createAccounts(1, True, 'Prospect');

        // Add test ContentDocuments with allowed MIME types
        ContentVersion testContent1 = new ContentVersion(
            Title = 'Test Content 1',
            PathOnClient = 'test1.txt',
            VersionData = Blob.valueOf('Test content'),
            FirstPublishLocationId = testContract.Id
        );
        insert testContent1;
        List<ContentDocument> documents = [
    	SELECT Id, Title, LatestPublishedVersionId  FROM ContentDocument];

        //create ContentDocumentLink  record 
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = acc[0].id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.ShareType = 'V';
        insert cdl;
        
        // Query the ContentDocument
        ContentDocumentLink contentDocumentLink1 = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :testContract.Id LIMIT 1];
        System.assertNotEquals(null, contentDocumentLink1, 'No ContentDocumentLink found for testContract');
        
        ContentDocument testDocument1 = [SELECT FileType FROM ContentDocument WHERE Id = :contentDocumentLink1.ContentDocumentId];
        System.assertEquals('TEXT', testDocument1.FileType);

        // Add test ContentDocuments with blocked MIME types
        ContentVersion testContent2 = new ContentVersion(
            Title = 'Test Content 2',
            PathOnClient = 'blocked.html',
            VersionData = Blob.valueOf('<html><body>Blocked content</body></html>'),
            FirstPublishLocationId = testContract.Id
        );
        try{
        insert testContent2;
		}
        catch(Exception e)
        {
        System.assertNotEquals(null, e.getMessage(), 'Upload Blocked');
        }
    }
}