/*********************************************************************************************************************
* Apex Class: SBR_3_0_RetrievePOPDF
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Apex Class retrieve of Purchase Order PDF
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES

---------------------------------------------------------------------------------------------------------------------------------------
Note:- Modified from Akhil Tyagi's class
* 
*********************************************************************************************************************/
public with sharing class SBR_3_0_RetrievePOPDF {

    public class WrappedResponse{
        @InvocableVariable public String status;
        public String fileBody;
        public String fileName;
        public String errorMessage;
    }
    
    /*********************************************************************************************************************
    * Purpose/Methods:
    * Invocable method called from Flow 'SBR 3.0 Retrieve Purchase Order PDF'
    *********************************************************************************************************************/
    @InvocableMethod(label='RetrievePOPDF' description='Do a callout to DocGen to retrive the Purchase Order pdf' callout=true)
    public static List<WrappedResponse> retrievePDF(List<List<String>> data){
        WrappedResponse response = new WrappedResponse();
        try {
            response = makeRequest(new Map<String, Object>{
                'repoId'        => data[0][0],
                'endPoint'      => data[0][1],
                'authToken'     => data[0][2],
                'purchaseOrderId'   => data[0][3],
                'executionFrom' => SBR_3_0_GeneratePOPDFUtility.EXECUTION_TYPE_FLOW,
                //'executionFrom' => SBR_3_0_GeneratePOPDFUtility.EXECUTION_TYPE_AURA,
                'sendEmail'     => true
                //'sendEmail'     => false
            });
            return new List<WrappedResponse>{ response };
        } catch (Exception ex) {
            SBR_3_0_GeneratePOPDFUtility.logException(new SBR_3_0_GeneratePOPDFUtility.ExceptionData(ex, 'SBR_3_0_RetrievePOPDF', 'retrievePDF'));
            response.status = 'InComplete';
            return new List<WrappedResponse>{ response };
        }
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Method to retrieve the pdf
    *********************************************************************************************************************/
    public static WrappedResponse makeRequest(Map<String, Object> dataMap){
        WrappedResponse response = new WrappedResponse();
        String executionFrom = (String)dataMap.get('executionFrom');
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint((String)dataMap.get('endPoint') + '/' + (String)dataMap.get('repoId'));
        req.setHeader('Authorization', (String)dataMap.get('authToken'));
        req.setHeader('companyId', SBR_3_0_GeneratePOPDFUtility.COMPANY_ID);
        req.setHeader('thresholdWaitTime', SBR_3_0_GeneratePOPDFUtility.THRESHOLD_WAIT_TIME);
        req.setHeader('X-Correlation-ID', SBR_3_0_GeneratePOPDFUtility.X_CORRELATION_ID);
        req.setTimeout(120000);        
        HTTPResponse res = new Http().send(req);
        
        if( (res.getStatusCode() == 200 || res.getStatus() == 'OK') && res.getBody().startsWith('%PDF') ){
            response.status = SBR_3_0_GeneratePOPDFUtility.RESPONSE_STATUS_COMPLETE;
            Purchase_Order__c po = SBR_3_0_GeneratePOPDFUtility.getPurchaseOrder((String)dataMap.get('purchaseOrderId'));
            if(executionFrom == SBR_3_0_GeneratePOPDFUtility.EXECUTION_TYPE_AURA){
                response.fileBody = EncodingUtil.base64encode(res.getBodyAsBlob());
                response.fileName = SBR_3_0_GeneratePOPDFUtility.getFileName(po);
                system.debug('The file content is: '+response.fileBody);
                system.debug('The file content before is: '+res.getBodyAsBlob());
            }
            if((Boolean)dataMap.get('sendEmail')){
                String emailDeliveryStatus = SBR_3_0_GeneratePOPDFUtility.sendPOEmail(res.getBodyAsBlob(), po);
                if(executionFrom == SBR_3_0_GeneratePOPDFUtility.EXECUTION_TYPE_AURA && emailDeliveryStatus == 'error'){
                    response.status       = SBR_3_0_GeneratePOPDFUtility.RESPONSE_STATUS_INCOMPLETE;
                    response.errorMessage = System.Label.SBR_3_0_POPDFEmailFatalError;
                }
            }
        } else if(res.getBody().contains('"status": "In Progress"')){
            response.status = SBR_3_0_GeneratePOPDFUtility.RESPONSE_STATUS_INPROGRESS;
            if(executionFrom == SBR_3_0_GeneratePOPDFUtility.EXECUTION_TYPE_FLOW){
                SBR_3_0_GeneratePOPDFUtility.logException(new SBR_3_0_GeneratePOPDFUtility.ExceptionData('SBR_3_0_RetrievePOPDF', 'retrievePDF', System.Label.SBR_3_0_POPDFGenerationTooLongError));
            }
        } else {
            response.status = SBR_3_0_GeneratePOPDFUtility.RESPONSE_STATUS_INCOMPLETE;
            if(executionFrom == SBR_3_0_GeneratePOPDFUtility.EXECUTION_TYPE_AURA){
                Map<String, Object> errorResponse = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                response.errorMessage = (String)((Map<String, Object>)errorResponse.get('error')).get('message');
            }
            SBR_3_0_GeneratePOPDFUtility.logException(new SBR_3_0_GeneratePOPDFUtility.ExceptionData(
                'SBR_3_0_GeneratePOPDF', 
                'generatePDF',
                (System.Label.SBR_3_0_POPDFExceptionError + '\nResponse StatusCode ==> ' + res.getStatusCode() + '\nResonse Body ==>> ' + res.getBody())
            ));
        }
        return response;
    }
}