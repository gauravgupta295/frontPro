/*********************************************************************************************************************
* Apex Class: SBR_3_0_RetrieveWOPDF
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Apex Class retrieve of WorkOrderInvoice PDF
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Akhil Tyagi             2023-10-31          Initial version
    2.0         Akhil Tyagi             2023-11-10          Added Error Handling
---------------------------------------------------------------------------------------------------------------------------------------
Note:-
* 
*********************************************************************************************************************/
public with sharing class SBR_3_0_RetrieveWOPDF {

    public class WrappedResponse{
        @InvocableVariable public String status;
        public String fileBody;
        public String fileName;
        public String errorMessage;
    }
    
    /*********************************************************************************************************************
    * Purpose/Methods:
    * Invocable method called from Flow 'SBR 3.0 Retrieve WorkOrder Invoice' and 
    *********************************************************************************************************************/
    @InvocableMethod(label='RetrievePDF' description='Do a callout to DocGen to retrive the pdf' callout=true)
    public static List<WrappedResponse> retrievePDF(List<List<String>> data){
        WrappedResponse response = new WrappedResponse();
        try {
            response = makeRequest(new Map<String, Object>{
                'repoId'        => data[0][0],
                'endPoint'      => data[0][1],
                'authToken'     => data[0][2],
                'workOrderId'   => data[0][3],
                'executionFrom' => SBR_3_0_GenerateWOPDFUtility.EXECUTION_TYPE_FLOW,
                'sendEmail'     => true
            });
            return new List<WrappedResponse>{ response };
        } catch (Exception ex) {
            SBR_3_0_GenerateWOPDFUtility.logException(new SBR_3_0_GenerateWOPDFUtility.ExceptionData(ex, 'SBR_3_0_RetrieveWOPDF', 'retrievePDF'));
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
        req.setHeader('companyId', SBR_3_0_GenerateWOPDFUtility.COMPANY_ID);
        req.setHeader('thresholdWaitTime', SBR_3_0_GenerateWOPDFUtility.THRESHOLD_WAIT_TIME);
        req.setHeader('X-Correlation-ID', SBR_3_0_GenerateWOPDFUtility.X_CORRELATION_ID);
        req.setTimeout(120000);
        
        HTTPResponse res = new Http().send(req);
        if( (res.getStatusCode() == 200 || res.getStatus() == 'OK') && res.getBody().startsWith('%PDF') ){
            response.status = SBR_3_0_GenerateWOPDFUtility.RESPONSE_STATUS_COMPLETE;
            WorkOrder wo = SBR_3_0_GenerateWOPDFUtility.getWorkOrder((String)dataMap.get('workOrderId'));
            if(executionFrom == SBR_3_0_GenerateWOPDFUtility.EXECUTION_TYPE_AURA){
                response.fileBody = EncodingUtil.base64encode(res.getBodyAsBlob());
                response.fileName = SBR_3_0_GenerateWOPDFUtility.getFileName(wo);
            }
            if((Boolean)dataMap.get('sendEmail')){
                String emailDeliveryStatus = SBR_3_0_GenerateWOPDFUtility.sendEmail(res.getBodyAsBlob(), wo);
                if(executionFrom == SBR_3_0_GenerateWOPDFUtility.EXECUTION_TYPE_AURA && emailDeliveryStatus == 'error'){
                    response.status       = SBR_3_0_GenerateWOPDFUtility.RESPONSE_STATUS_INCOMPLETE;
                    response.errorMessage = System.Label.WOInvoiceEmailFailError;
                }
            }
        } else if(res.getBody().contains('"status": "In Progress"')){
            response.status = SBR_3_0_GenerateWOPDFUtility.RESPONSE_STATUS_INPROGRESS;
            if(executionFrom == SBR_3_0_GenerateWOPDFUtility.EXECUTION_TYPE_FLOW){
                SBR_3_0_GenerateWOPDFUtility.logException(new SBR_3_0_GenerateWOPDFUtility.ExceptionData('SBR_3_0_RetrieveWOPDF', 'retrievePDF', System.Label.WOInvoiceGenerationTooLongError));
            }
        } else {
            response.status = SBR_3_0_GenerateWOPDFUtility.RESPONSE_STATUS_INCOMPLETE;
            if(executionFrom == SBR_3_0_GenerateWOPDFUtility.EXECUTION_TYPE_AURA){
                Map<String, Object> errorResponse = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                response.errorMessage = (String)((Map<String, Object>)errorResponse.get('error')).get('message');
            }
            SBR_3_0_GenerateWOPDFUtility.logException(new SBR_3_0_GenerateWOPDFUtility.ExceptionData(
                'SBR_3_0_GenerateWOPDF', 
                'generatePDF',
                (System.Label.WoInvoiceExceptionError + '\nResponse StatusCode ==> ' + res.getStatusCode() + '\nResonse Body ==>> ' + res.getBody())
            ));
        }
        return response;
    }
}