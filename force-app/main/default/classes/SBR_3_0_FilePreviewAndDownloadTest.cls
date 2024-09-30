@isTest
private class SBR_3_0_FilePreviewAndDownloadTest {
    
    @isTest
    static void testGetRelatedFilesByRecordId() {
     
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        
        ContentVersion version = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'test.png',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert version;
        
        ContentDocumentLink docLink = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id].ContentDocumentId,
            LinkedEntityId = acc.Id,
            ShareType = 'V'
        );
        insert docLink;
        
       
        Test.startTest();
        Map<ID, String> result = SBR_3_0_filePreviewAndDownloadController.getRelatedFilesByRecordId(acc.Id);
        Test.stopTest();
        
    
        System.assertEquals(1, result.size(), 'There should be one related file');
        System.assertEquals('Test Document', result.get([SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id].ContentDocumentId), 'The file title should match');
    }
}