/********************************************************************************************************************
* Apex Class: SBR_3_0_FileUploadCmpController
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Upload files
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Piyush Jindal         2024-03-28            Initial version
*********************************************************************************************************************/
public with sharing class SBR_3_0_FileUploadCmpController {
    
    /*********************************************************************************************************************
    * Purpose/Methods:
    * Method: Generates an Advanced Encryption Standard (AES) key
    * Params:
    *********************************************************************************************************************/
    @AuraEnabled(cacheable = true)
    public static String getKey() {
        Blob key = Crypto.generateAesKey(256);
        String encodedKey = EncodingUtil.base64Encode(key);
        return encodedKey;
    }
    
    /*********************************************************************************************************************
    * Purpose/Methods:
    * Method: encrypt the content with the encodedKey
    * Params: String (recordId), String (encodedKey)
    *********************************************************************************************************************/
    @AuraEnabled(cacheable = true)
    public static String encrypt(String recordId, String encodedKey) {
        Blob key = EncodingUtil.base64Decode(encodedKey);
        Blob value = Crypto.encryptWithManagedIV('AES256', key, Blob.valueOf(recordId));
        String encodedValue = EncodingUtil.base64Encode(value);
        return encodedValue;
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Method: Creates content version records
    * Params: List<String> (fileNames), String (encodedRecordId)
    *********************************************************************************************************************/
    @AuraEnabled 
    public static List<objFiles> createContentVers(List<String> fileNames, String encodedRecordId) {
        List<ContentVersion> versions = new List<ContentVersion>();
        for(String fileName : fileNames){
            Integer startOfExtension = fileName.lastIndexOf('.');
            ContentVersion version = new ContentVersion(
                Title = fileName.Substring(0,startOfExtension),
                PathOnClient = '/'+fileName,
                VersionData = Blob.valueOf(' '),
                IsMajorVersion = FALSE,
                Guest_Record_fileupload__c = encodedRecordId
            );
            versions.add(version);
        }

        List<Database.SaveResult> results = Database.insert(versions);

        List<Id> versionIds = new List<Id>();
        for(Database.SaveResult result : results){
            versionIds.add(result.getId());
        }

        Boolean isStandardUser = UserInfo.getUserType() == 'Standard';
        List<objFiles> objFiles = new List<objFiles>();
        for(ContentVersion version : [SELECT Id, ContentDocumentId, ContentDocument.Title, ContentDocument.FileExtension FROM ContentVersion WHERE Id IN :versionIds ORDER BY Id]){
            objFiles objFile = new objFiles();
            objFile.name = version.ContentDocument.Title +'.'+ version.ContentDocument.FileExtension;
            objFile.contentVersionId = version.Id;

            if(isStandardUser){
                objFile.documentId = version.ContentDocumentId;
            }
            
            objFiles.add(objFile);
        }

        return objFiles;
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Method: The content is saved in chunks therefore it is merged if there is an existing content version else a new version is created.
    * Params: String (versionId), String (base64Data)
    *********************************************************************************************************************/
    @AuraEnabled 
    public static void appendDataToContentVersion(String versionId, String base64Data) {
        ContentVersion vers = [SELECT Id, VersionData FROM ContentVersion WHERE Id = :versionId];
        String existingVersionData = EncodingUtil.base64Encode(vers.VersionData);

        if(existingVersionData == 'IA=='){
            vers.VersionData = EncodingUtil.base64Decode(base64Data);
        } else {
            vers.VersionData = EncodingUtil.base64Decode(existingVersionData + base64Data);
        }
        update vers;
    }
    
    /*********************************************************************************************************************
    * Purpose/Methods:
    * Method: Document Link is created so that the docs are publicly available.
    * Params: List<String> (versIds), String (encodedKey), Boolean (visibleToAllUsers)
    *********************************************************************************************************************/
    @AuraEnabled
    public static void createContentDocLink(List<String> versIds, String encodedKey, Boolean visibleToAllUsers) {
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for(ContentVersion vers : [SELECT Id, ContentDocumentId, Guest_Record_fileupload__c FROM ContentVersion WHERE Id IN :versIds]){
            ContentDocumentLink link = new ContentDocumentLink(
            	ContentDocumentId = vers.ContentDocumentId,
                LinkedEntityId = decrypt(vers.Guest_Record_fileupload__c, encodedKey)
        	);
            if(visibleToAllUsers != null){
                if(visibleToAllUsers){
                    link.Visibility = 'AllUsers';
                }
            }
            links.add(link);
        }
        if(!links.isEmpty()){
            insert links;
        }
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Method: Update the file name. 
    * Params: List<String> (versIds), String (fileName)
    *********************************************************************************************************************/
    @AuraEnabled
    public static void updateFileName(List<String> versIds, String fileName) {
        List<ContentDocument> docs = new List<ContentDocument>();
        for(ContentVersion vers : [SELECT Id, ContentDocumentId, ContentDocument.Title FROM ContentVersion WHERE Id IN :versIds]){
            if(vers.ContentDocument.Title != fileName){
                ContentDocument doc = new ContentDocument(
                    Id = vers.ContentDocumentId,
                    Title = fileName
                );
                docs.add(doc);
            }
        }
        if(!docs.isEmpty()){
            update docs;
        }
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Method: Deletion of Content Document 
    * Params: String (docId)
    *********************************************************************************************************************/
    @AuraEnabled
    public static void deleteContentDoc(String docId) {
        List<ContentDocument> cdRecList = [SELECT Id FROM ContentDocument WHERE Id = :docId];

        if(cdRecList != null && !cdRecList.isEmpty()) {
            try {
                delete cdRecList;
            } catch(Exception exc) {
                throw new AuraHandledException(exc.getMessage());
            }
        }
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Method: Get existing files related the a record
    * Params: String (recordId)
    *********************************************************************************************************************/
   @AuraEnabled
    public static List<objFiles> getExistingFiles(String recordId) {
        Boolean isStandardUser = UserInfo.getUserType() == 'Standard';
        Map<Id,objFiles> objFiles = new Map<Id,objFiles>();
        for(ContentDocumentLink link : [SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.FileExtension FROM ContentDocumentLink WHERE LinkedEntityId = :recordId]){
            objFiles files = new objFiles();
            files.name = link.ContentDocument.Title +'.'+ link.ContentDocument.FileExtension;
            if(isStandardUser){
                files.documentId = link.ContentDocumentId;
            }
            objFiles.put(link.ContentDocumentId,files);
        }
        for(ContentVersion vers : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN :objFiles.keyset() AND IsLatest = TRUE]){
            objFiles.get(vers.ContentDocumentId).contentVersionId = vers.Id;
        }
        return objFiles.values();
    }

    /*********************************************************************************************************************
    * Purpose: Wrapper class.
    *********************************************************************************************************************/
    public class objFiles {
        @AuraEnabled
        public string name;

        @AuraEnabled
        public string documentId;

        @AuraEnabled
        public string contentVersionId;
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Method: Decrypt the data (blob) using the encoded key.
    * Params: String (encodedValue), String (encodedKey)
    *********************************************************************************************************************/
    private static String decrypt(String encodedValue, String encodedKey) {
        Blob key = EncodingUtil.base64Decode(encodedKey);
        Blob value = EncodingUtil.base64Decode(encodedValue);
    	Blob decryptedBlob = Crypto.decryptWithManagedIV('AES256', key, value);
    	String recordId = decryptedBlob.toString();
        return recordId;
    }
}