/*********************************************************************************************************************
* Apex Class: SBR_3_0_GeneratePOPDF
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Apex Class generation of Purchase Order PDF
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES

---------------------------------------------------------------------------------------------------------------------------------------
Note:-
* 
*********************************************************************************************************************/
public with sharing class SBR_3_0_GeneratePOPDF {
    
    public class DocGenRequestWrapper{
        public Map<String,Object> inputPayload;
        public String templateId;
    }

    public class WrappedResponse{
        @InvocableVariable public String status;
        @InvocableVariable public String repoId;
        @InvocableVariable public String endpoint;
        @InvocableVariable public String accToken;
        public String fileBody;
        public String fileName;
        public String errorMessage;
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Invocable method called from 
    * - Flow 'SBR 3.0 Generate PO PDF' and 
    * - Apex Class 'SBR_3_0_GeneratePOPDFController' 
    *********************************************************************************************************************/
    @InvocableMethod(label='GeneratePOPDF' description='Do a callout to DocGen to generate the purchase order pdf' callout=true)
    public static List<WrappedResponse> generatePDF(List<List<String>> data){
        WrappedResponse response = new WrappedResponse();

        String purchaseOrderId 	 = data[0][0];
        String executionFrom = data[0][1];
        Boolean sendEmail    = (executionFrom == SBR_3_0_GeneratePOPDFUtility.EXECUTION_TYPE_AURA ? Boolean.valueOf(data[0][2]) : true);
        try {
            Purchase_Order__c po = SBR_3_0_GeneratePOPDFUtility.getPurchaseOrder(purchaseOrderId);

            // Return error when email needs to be send and no customer email address is present
            if(sendEmail&&(String.isBlank(po.Vendor__c) || String.isBlank(po.Vendor__r.Email__c))){
                response.status       = 'InComplete';
                response.errorMessage = System.Label.SBR_3_0_POPDFEmailError;
                SBR_3_0_GeneratePOPDFUtility.logException(new SBR_3_0_GeneratePOPDFUtility.ExceptionData('SBR_3_0_GeneratePOPDF', 'generatePOPDF', System.Label.SBR_3_0_POPDFEmailError));
                return new List<WrappedResponse>{ response };
            }
         
            // Create Payload Wrapper
            DocGenRequestWrapper docGenReqWrap = new DocGenRequestWrapper();
            docGenReqWrap.templateId   = SBR_3_0_GeneratePOPDFUtility.getTemplateId();
            docGenReqWrap.inputPayload = SBR_3_0_GeneratePOPDFUtility.getPurchaseOrderMap(po);
         
            //Create Callout 
            SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(SBR_3_0_GeneratePOPDFUtility.APINAME);
            httpCallout.setHeadersMap(getHeadersMap);
            httpCallout.setRequestBody(JSON.serializePretty(docGenReqWrap));
            System.debug('@@@@ Request Body ==>> ' + JSON.serializePretty(docGenReqWrap));
            
            HttpResponse res = httpCallout.sendRequest();
            if(res.getBody().contains('"status": "In Progress"')){
                response.status   = 'In Progress';
                response.repoId   = res.getHeader('x-request-id');
                response.endpoint = httpCallout.getRequest().getEndpoint();
                response.accToken = httpCallout.getRequest().getHeader('Authorization');
                
                if(executionFrom == SBR_3_0_GeneratePOPDFUtility.EXECUTION_TYPE_FLOW){
                    invokeRetrieveFlow(response.repoId, response.endpoint, response.accToken, purchaseOrderId);
                }
            } else if(res.getHeader('Content-Type').contains('application/octet-stream')){
                response.status = 'Complete';
                if(executionFrom == SBR_3_0_GeneratePOPDFUtility.EXECUTION_TYPE_AURA){
                    response.fileBody = EncodingUtil.base64encode(res.getBodyAsBlob());
                    response.fileName = SBR_3_0_GeneratePOPDFUtility.getFileName(po);
                }
                if(sendEmail){
                    String emailDeliveryStatus = SBR_3_0_GeneratePOPDFUtility.sendPOEmail(res.getBodyAsBlob(), po);
                    if(executionFrom == SBR_3_0_GeneratePOPDFUtility.EXECUTION_TYPE_AURA && emailDeliveryStatus == 'error'){
                        response.status       = SBR_3_0_GeneratePOPDFUtility.RESPONSE_STATUS_INCOMPLETE;
                        response.errorMessage = System.Label.SBR_3_0_POPDFEmailFatalError;
                    }
                }
            } else{
                response.status = 'InComplete';
                if(executionFrom == SBR_3_0_GeneratePOPDFUtility.EXECUTION_TYPE_AURA){
                    Map<String, Object> errorResponse = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                    response.errorMessage = (String)((Map<String, Object>)errorResponse.get('error')).get('message');
                }
                SBR_3_0_GeneratePOPDFUtility.logException(new SBR_3_0_GeneratePOPDFUtility.ExceptionData(
                    'SBR_3_0_GeneratePOPDF', 
                    'generatePOPDF',
                    (System.Label.SBR_3_0_POPDFExceptionError + '\nResponse StatusCode ==> ' + res.getStatusCode() + '\nResonse Body ==>> ' + res.getBody())
                ));
            }
            
            return new List<WrappedResponse>{ response };
        } catch (Exception ex) {
            SBR_3_0_GeneratePOPDFUtility.logException(new SBR_3_0_GeneratePOPDFUtility.ExceptionData(ex, 'SBR_3_0_GeneratePOPDF', 'generatePOPDF'));
            response.status = 'InComplete';
            if(executionFrom == SBR_3_0_GeneratePOPDFUtility.EXECUTION_TYPE_AURA){
                response.errorMessage = ex.getMessage();
            }
            return new List<WrappedResponse>{ response };
        }
    }

    public static Map<String, String> getHeadersMap{
        get{
            if(getHeadersMap == null){
                getHeadersMap = new Map<String, String>{
                    'companyId'         => SBR_3_0_GeneratePOPDFUtility.COMPANY_ID,
                    'Content-Type'      => SBR_3_0_GeneratePOPDFUtility.CONTENT_TYPE_JSON,
                    'thresholdWaitTime' => SBR_3_0_GeneratePOPDFUtility.THRESHOLD_WAIT_TIME,
                    'X-Correlation-ID'  => SBR_3_0_GeneratePOPDFUtility.X_CORRELATION_ID,
                    'source'            => SBR_3_0_GeneratePOPDFUtility.SOURCE_SF
                };
            }
            return getHeadersMap;
        }
        set;
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Invoke another autolaunched flow to retrieve the generated PDF
    *********************************************************************************************************************/
    public static void invokeRetrieveFlow(String repoId, String endPoint, String accToken, String purchaseOrderId){
        Flow.Interview.SBR_3_0_Retrieve_PO_PDF retPDFFlow = new Flow.Interview.SBR_3_0_Retrieve_PO_PDF(new Map<String, Object>{
            'repoId'      => repoId,
            'endpoint'    => endpoint,
            'accToken'    => accToken,
            'purchaseOrderId' => purchaseOrderId
        });
        //Invoke Flow
        retPDFFlow.start();
    }
}