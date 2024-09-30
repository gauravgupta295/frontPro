/*********************************************************************************************************************
* Apex Class: SBR_3_0_GenerateWOPDF
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Apex Class generation of WorkOrderInvoice PDF
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Akhil Tyagi             2023-10-31          Initial version
    2.0         Akhil Tyagi             2023-11-10          Added Error Handling
---------------------------------------------------------------------------------------------------------------------------------------
Note:-
* 
*********************************************************************************************************************/
public with sharing class SBR_3_0_GenerateWOPDF {
    
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
    * - Flow 'SBR 3.0 Generate WorkOrder Invoice' and 
    * - Apex Class 'SBR_3_0_GenerateWOPDFController' 
    *********************************************************************************************************************/
    @InvocableMethod(label='GeneratePDF' description='Do a callout to DocGen to generate the pdf' callout=true)
    public static List<WrappedResponse> generatePDF(List<List<String>> data){
        WrappedResponse response = new WrappedResponse();

        String workOrderId 	 = data[0][0];
        String executionFrom = data[0][1];
        Boolean sendEmail    = (executionFrom == SBR_3_0_GenerateWOPDFUtility.EXECUTION_TYPE_AURA ? Boolean.valueOf(data[0][2]) : true);
        try {
            WorkOrder wo = SBR_3_0_GenerateWOPDFUtility.getWorkOrder(workOrderId);

            // Return error when email needs to be send and no customer email address is present
            if(sendEmail && (String.isBlank(wo.AccountId) || String.isBlank(wo.Account.E_mail_Address__c))){
                response.status       = 'InComplete';
                response.errorMessage = System.Label.WOInvoiceEmailError;
                SBR_3_0_GenerateWOPDFUtility.logException(new SBR_3_0_GenerateWOPDFUtility.ExceptionData('SBR_3_0_GenerateWOPDF', 'generatePDF', System.Label.WOInvoiceEmailError));
                return new List<WrappedResponse>{ response };
            }
            
            // Create Payload Wrapper
            DocGenRequestWrapper docGenReqWrap = new DocGenRequestWrapper();
            docGenReqWrap.templateId   = SBR_3_0_GenerateWOPDFUtility.getTemplateId(wo.RecordType.DeveloperName);
            docGenReqWrap.inputPayload = SBR_3_0_GenerateWOPDFUtility.getWorkOrderMap(wo);
         
            //Create Callout 
            SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(SBR_3_0_GenerateWOPDFUtility.APINAME);
            httpCallout.setHeadersMap(getHeadersMap);
            httpCallout.setRequestBody(JSON.serializePretty(docGenReqWrap));
            System.debug('@@@@ Request Body ==>> ' + JSON.serializePretty(docGenReqWrap));
            
            HttpResponse res = httpCallout.sendRequest();
            if(res.getBody().contains('"status": "In Progress"')){
                response.status   = 'In Progress';
                response.repoId   = res.getHeader('x-request-id');
                response.endpoint = httpCallout.getRequest().getEndpoint();
                response.accToken = httpCallout.getRequest().getHeader('Authorization');
                
                if(executionFrom == SBR_3_0_GenerateWOPDFUtility.EXECUTION_TYPE_FLOW){
                    invokeRetrieveFlow(response.repoId, response.endpoint, response.accToken, workOrderId);
                }
            } else if(res.getHeader('Content-Type').contains('application/octet-stream')){
                response.status = 'Complete';
                if(executionFrom == SBR_3_0_GenerateWOPDFUtility.EXECUTION_TYPE_AURA){
                    response.fileBody = EncodingUtil.base64encode(res.getBodyAsBlob());
                    response.fileName = SBR_3_0_GenerateWOPDFUtility.getFileName(wo);
                }
                if(sendEmail){
                    String emailDeliveryStatus = SBR_3_0_GenerateWOPDFUtility.sendEmail(res.getBodyAsBlob(), wo);
                    if(executionFrom == SBR_3_0_GenerateWOPDFUtility.EXECUTION_TYPE_AURA && emailDeliveryStatus == 'error'){
                        response.status       = SBR_3_0_GenerateWOPDFUtility.RESPONSE_STATUS_INCOMPLETE;
                        response.errorMessage = System.Label.WOInvoiceEmailFailError;
                    }
                }
            } else{
                response.status = 'InComplete';
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
            
            return new List<WrappedResponse>{ response };
        } catch (Exception ex) {
            SBR_3_0_GenerateWOPDFUtility.logException(new SBR_3_0_GenerateWOPDFUtility.ExceptionData(ex, 'SBR_3_0_GenerateWOPDF', 'generatePDF'));
            response.status = 'InComplete';
            if(executionFrom == SBR_3_0_GenerateWOPDFUtility.EXECUTION_TYPE_AURA){
                response.errorMessage = ex.getMessage();
            }
            return new List<WrappedResponse>{ response };
        }
    }

    public static Map<String, String> getHeadersMap{
        get{
            if(getHeadersMap == null){
                getHeadersMap = new Map<String, String>{
                    'companyId'         => SBR_3_0_GenerateWOPDFUtility.COMPANY_ID,
                    'Content-Type'      => SBR_3_0_GenerateWOPDFUtility.CONTENT_TYPE_JSON,
                    'thresholdWaitTime' => SBR_3_0_GenerateWOPDFUtility.THRESHOLD_WAIT_TIME,
                    'X-Correlation-ID'  => SBR_3_0_GenerateWOPDFUtility.X_CORRELATION_ID,
                    'source'            => SBR_3_0_GenerateWOPDFUtility.SOURCE_SF
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
    public static void invokeRetrieveFlow(String repoId, String endPoint, String accToken, String workOrderId){
        Flow.Interview.SBR_3_0_Retrieve_WorkOrder_Invoice retPDFFlow = new Flow.Interview.SBR_3_0_Retrieve_WorkOrder_Invoice(new Map<String, Object>{
            'repoId'      => repoId,
            'endpoint'    => endpoint,
            'accToken'    => accToken,
            'workOrderId' => workOrderId
        });
        //Invoke Flow
        retPDFFlow.start();
    }
}