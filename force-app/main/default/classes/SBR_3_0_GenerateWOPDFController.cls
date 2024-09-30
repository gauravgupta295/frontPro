/*********************************************************************************************************************
* Apex Class: SBR_3_0_GenerateWOPDFController
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Controller class for LWC component sbr_3_0_GenerateWOPDF
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Akhil Tyagi             2023-10-31          Initial version
    2.0         Akhil Tyagi             2023-11-17          Added functionality to control sendEmail
---------------------------------------------------------------------------------------------------------------------------------------
Note:-
* 
*********************************************************************************************************************/
public with sharing class SBR_3_0_GenerateWOPDFController {
    
    @AuraEnabled
    public static String generatePDF(String recordId, Boolean sendEmail){
        try {
            List<List<String>> data = new List<List<String>>();
            data.add(new List<String>{ recordId, SBR_3_0_GenerateWOPDFUtility.EXECUTION_TYPE_AURA, String.valueOf(sendEmail) });
            List<SBR_3_0_GenerateWOPDF.WrappedResponse> res = SBR_3_0_GenerateWOPDF.generatePDF(data);
            SBR_3_0_GenerateWOPDF.WrappedResponse response = res[0];
            return JSON.serialize(response);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String retrievePDF(String data){
        try {
            SBR_3_0_RetrieveWOPDF.WrappedResponse response = SBR_3_0_RetrieveWOPDF.makeRequest((Map<String, Object>)JSON.deserializeUntyped(data));
            return JSON.serialize(response);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}