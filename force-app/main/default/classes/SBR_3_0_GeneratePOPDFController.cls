/*********************************************************************************************************************
* Apex Class: SBR_3_0_GeneratePOPDFController
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Controller class for LWC component sbr_3_0_GeneratePOPDF
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES

---------------------------------------------------------------------------------------------------------------------------------------
Note:- Adapted From PO Process
* 
*********************************************************************************************************************/
public with sharing class SBR_3_0_GeneratePOPDFController {
    
    @AuraEnabled
    public static String generatePDF(String recordId, Boolean sendEmail){
        try {
            List<List<String>> data = new List<List<String>>();
            data.add(new List<String>{ recordId, SBR_3_0_GeneratePOPDFUtility.EXECUTION_TYPE_AURA, String.valueOf(sendEmail) });
            List<SBR_3_0_GeneratePOPDF.WrappedResponse> res = SBR_3_0_GeneratePOPDF.generatePDF(data);
            SBR_3_0_GeneratePOPDF.WrappedResponse response = res[0];
            return JSON.serialize(response);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String retrievePDF(String data){
        try {
            system.debug('Input Data is= '+data);
            system.debug('Deserialized Data is= '+(Map<String, Object>)JSON.deserializeUntyped(data));
            SBR_3_0_RetrievePOPDF.WrappedResponse response = SBR_3_0_RetrievePOPDF.makeRequest((Map<String, Object>)JSON.deserializeUntyped(data));
            return JSON.serialize(response);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}