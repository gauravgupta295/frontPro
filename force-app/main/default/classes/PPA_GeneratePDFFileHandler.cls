public with sharing class PPA_GeneratePDFFileHandler {

    public static Map<String,String> linkDocumentToPriceList(String priceListId, String customerName, Boolean draftTemplate, Blob pdfBody) {
        Map<String,String> returnVals = new Map<String,String>();
		String fileName;
        
        try {
            Datetime myDateTime = DateTime.now();
            String dtString = myDateTime.format('MM-dd-yyyy h:mm a');

            ContentVersion cv = new ContentVersion();
            cv.ContentLocation = 'S';
            cv.VersionData = pdfBody;
            
            if(draftTemplate) {
                fileName = 'Rates PDF(Draft) - ' + customerName + ' - ' + dtString;
            }
            else {
                fileName = 'Rates PDF - ' + customerName + ' - ' + dtString;                
            }

            cv.Title = fileName;
            cv.PathOnClient = fileName + '.pdf';
            insert cv;

            ContentVersion newCV = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = newCV.ContentDocumentId;
            cdl.LinkedEntityId = priceListId;
            cdl.ShareType = 'V';
            insert cdl;

            returnVals.put('errorCode', '0');
            returnVals.put('status', 'Completed');
        } catch (Exception e) {
            // Log the exception details
            Map<String, String> exceptionParams = new Map<String, String>();
            exceptionParams.put('ClassName', 'PPA_GeneratePDFFileHandler');
            exceptionParams.put('MethodName', 'linkDocumentToPriceList');
            exceptionParams.put('Type', e.getTypeName());
            exceptionParams.put('LineNumber', String.valueOf(e.getLineNumber()));
            exceptionParams.put('StackTrace', e.getStackTraceString());
            exceptionParams.put('Message', e.getMessage());

            returnVals.put('errorCode', '-1');
            returnVals.put('errorMessage', e.getMessage());
        }

        return returnVals;
    }
}