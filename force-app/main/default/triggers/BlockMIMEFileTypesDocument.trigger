trigger BlockMIMEFileTypesDocument on ContentDocumentLink (after insert) {
    //(.pdf, jpg,txt)
    //Block double extension - example.html.jpg
    //
    // Define the API name of the parent object
    String parentObjectName = 'SBR_Contract_Agreement__c';
    Schema.SObjectType parentObjectType = Schema.getGlobalDescribe().get(parentObjectName);
        Set<Id> setCntDocIds = new set<Id>();
        set<Id> setAgmtIds = new set<Id>();
    	//Set<String> blockedMimeTypes = new Set<String>{'html', 'application/octet-stream', 'application/x-shockwave-flash','htt','mht','svg','swf','thtml','xhtml'};
    	// Allowed file extensions and their size limits
            Map<String, Integer> allowedFileExtensions = new Map<String, Integer>{
                'pdf' => 10485760, // 10 MB
                'jpg' => 1048576, // 1 MB
                'txt' => 10485760 // 10 MB 
              };
        try{
            for(ContentDocumentLink clIterator : Trigger.new) {
                if(clIterator.linkedEntityId.getSObjectType() == parentObjectType) {
                    system.debug('clIterator.linkedEntityId.getSObjectType()'+clIterator.linkedEntityId.getSObjectType());
                    setCntDocIds.add(clIterator.ContentDocumentId);
                    setAgmtIds.add(clIterator.LinkedEntityId);
                }
            }
            if(setCntDocIds.size() > 0 && setAgmtIds.size() > 0 ) {           
                    map<Id, ContentDocument> mapContentDocuments = new map<Id, ContentDocument>([SELECT Id, Title, FileExtension,ContentSize FROM ContentDocument WHERE Id IN :setCntDocIds]);
                    list<ContentDocument> lstCntDocsToUpdate = new list<ContentDocument>();        
                    for(ContentDocumentLink cdlIterator : Trigger.new) {
                        ContentDocument objCntDoc = mapContentDocuments.get(cdlIterator.ContentDocumentId);
                        // Check if the content MIME type is in the list of blocked types
                       // if (objCntDoc.FileExtension != null && blockedMimeTypes.contains(objCntDoc.FileExtension.toLowerCase())) {
                        // OLD LOGIC
                      /* 	Boolean isDoubleExtension = objCntDoc.Title.contains('.');
                        if ((objCntDoc.FileExtension != null && !allowedMimeTypes.contains(objCntDoc.FileExtension.toLowerCase())) || isDoubleExtension) {
                            cdlIterator.addError('Attachments with MIME type---> ' + objCntDoc.FileExtension + ' is not allowed.');
                        } */

				Boolean isDoubleExtension = objCntDoc.Title.contains('.');
                        system.debug('isDoubleExtension and objCntDoc.Title '+objCntDoc.Title +isDoubleExtension);
                // Check if the file extension is allowed and within size limit
                if ((objCntDoc.FileExtension != null 
                    && allowedFileExtensions.containsKey(objCntDoc.FileExtension.toLowerCase())
                    && objCntDoc.ContentSize > 0 // Ensure file size is not 0
                    && objCntDoc.ContentSize <= allowedFileExtensions.get(objCntDoc.FileExtension.toLowerCase())) && !isDoubleExtension) {
                } else {
                    cdlIterator.addError('Attachment with MIME type ' + objCntDoc.FileExtension + ' either has invalid extension or exceeds allowed size limit.');
                }
                    }  
                }
        }
        Catch (Exception ex){
            system.debug('Exception in BlockMIMEFileTypesDocument :' + ex.getMessage());
        }
}