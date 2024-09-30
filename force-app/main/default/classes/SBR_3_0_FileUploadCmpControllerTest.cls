/********************************************************************************************************************
* Apex Class: SBR_3_0_FileUploadCmpControllerTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_FileUploadCmpController
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Piyush Jindal         2024-03-3            Initial version
*********************************************************************************************************************/
@isTest
public class SBR_3_0_FileUploadCmpControllerTest {
    
    @TestSetup
    static void createData() {
        Account testAcc =  SBR_3_0_ServiceTestDataFactory.createAccount(true,'33333');

        String randomString = generateRandomString(15);
        String name = randomString + '_1';
        Contact con = new Contact(
            FirstName = name,
            LastName = name,
            AccountId = testAcc.Id,
            Title = 'Test Title',
            Email = name.deleteWhitespace() + '@salesforce.com',
            MailingCity = name,
            MailingStreet = randomString,
            MailingState = 'CA',
            MailingCountry = 'US',
            Phone = randomString,
            MailingPostalCode = randomString
          );
        insert con;
        
        ContentVersion cv = new ContentVersion(
        	Title = 'Test',
            PathOnClient = 'Test',
            VersionData = EncodingUtil.base64Decode('Test'),
            IsMajorVersion = FALSE
        );
        insert cv;
    }

	@isTest
    public static void encrypted_test() {
        String key = SBR_3_0_FileUploadCmpController.getKey();

        Contact con = [SELECT Id FROM Contact];
        ContentVersion cv = [SELECT Id, Guest_Record_fileupload__c, ContentDocument.Title, ContentDocumentId, VersionData FROM ContentVersion LIMIT 1];
        cv.Guest_Record_fileupload__c = SBR_3_0_FileUploadCmpController.encrypt(con.Id,key);
        update cv;
        
        Test.startTest();
            SBR_3_0_FileUploadCmpController.createContentDocLink(new List<String>{cv.Id},key,true);
        Test.stopTest();


        List<ContentDocumentLink> cdl = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :con.Id];
        System.assertEquals(1, cdl.size());
    }

    @isTest
    public static void get_existing_files() {
        String key = SBR_3_0_FileUploadCmpController.getKey();

        Contact con = [SELECT Id FROM Contact];
        ContentVersion cv = [SELECT Id, Guest_Record_fileupload__c, ContentDocument.Title, ContentDocumentId, VersionData FROM ContentVersion LIMIT 1];
        cv.Guest_Record_fileupload__c = SBR_3_0_FileUploadCmpController.encrypt(con.Id,key);
        update cv;
        
        Test.startTest();
        SBR_3_0_FileUploadCmpController.createContentDocLink(new List<String>{cv.Id},key,false);
        List<SBR_3_0_FileUploadCmpController.objFiles> objFiles = SBR_3_0_FileUploadCmpController.getExistingFiles(con.Id); 
        Test.stopTest();

        System.assertEquals(1, objFiles.size());
    }

    @isTest
    public static void change_file_name() {
        ContentVersion cv = [SELECT Id, Guest_Record_fileupload__c, ContentDocument.Title, ContentDocumentId, VersionData FROM ContentVersion LIMIT 1];
        String fileName = 'Update_File_Name';

        Test.startTest();
        SBR_3_0_FileUploadCmpController.updateFileName(new List<String>{cv.Id}, fileName);
        Test.stopTest();

        cv = [SELECT Id, Guest_Record_fileupload__c, ContentDocument.Title, ContentDocumentId, VersionData FROM ContentVersion LIMIT 1];
        System.assertEquals(fileName, cv.ContentDocument.Title);
    }

    @isTest
    public static void delete_test() {
        ContentDocument cd = [SELECT Id FROM ContentDocument LIMIT 1];

        Test.startTest();
        SBR_3_0_FileUploadCmpController.deleteContentDoc(cd.Id);
        Test.stopTest();
        
        List<ContentDocument> cdRecList = [SELECT Id FROM ContentDocument];
        System.assertEquals(true, cdRecList.isEmpty());
    }

    @isTest
    public static void create_contentversion() {
        String encodedKey = SBR_3_0_FileUploadCmpController.getKey();
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        String encodedRecordId = SBR_3_0_FileUploadCmpController.encrypt(con.Id, encodedKey);

        String beforeString = 'File Upload';
        Blob beforeBlob = Blob.valueOf(beforeString);
        String newVersionData = EncodingUtil.base64Encode(beforeblob);

        List<String> fileNames = new List<String>{'SBR_3_0_FileUploadCmpController.txt'};
        List<Id> versIds = new List<Id>();
        Test.startTest();   
        List<SBR_3_0_FileUploadCmpController.objFiles> objFiles = SBR_3_0_FileUploadCmpController.createContentVers(fileNames, encodedRecordId);

        for(SBR_3_0_FileUploadCmpController.objFiles objFile : objFiles) {
            versIds.add(objFile.contentVersionId);
            SBR_3_0_FileUploadCmpController.appendDataToContentVersion(objFile.contentVersionId, newVersionData);
        }
        Test.stopTest();

        for(ContentVersion vers : [SELECT VersionData, Guest_Record_fileupload__c FROM ContentVersion WHERE Id IN :versIds]) {
            System.assertEquals(encodedRecordId, vers.Guest_Record_fileupload__c);
        }
    }

    @isTest
    public static void append_to_contentversion_version_has_data() {
        ContentVersion cv = [SELECT Id, Guest_Record_fileupload__c, ContentDocument.Title, ContentDocumentId, VersionData FROM ContentVersion LIMIT 1];

        String currentVersionData = EncodingUtil.base64Encode(cv.VersionData);

        String beforeString = 'File Upload';
        Blob beforeBlob = Blob.valueOf(beforeString);
        String newVersionData = EncodingUtil.base64Encode(beforeblob);
        
        Test.startTest();
        SBR_3_0_FileUploadCmpController.appendDataToContentVersion(cv.Id, newVersionData);
        Test.stopTest();

    }

    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randomStr = '';
        while (randomStr.length() < len) {
          Integer idx = Math.mod(
            Math.abs(Crypto.getRandomInteger()),
            chars.length()
          );
          randomStr += chars.substring(idx, idx + 1);
        }

        return randomStr;
	}
}