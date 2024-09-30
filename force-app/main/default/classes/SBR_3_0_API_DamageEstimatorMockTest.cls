/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_DamageEstimatorMockTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Mock class for SBR_3_0_API_CreateDamageEstimatorTest
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Piyush Jindal           2024-02-27          Initial version
    2.0         Meghna Vijay            2024-03-05          Added @isTest as this mock is used for test class only
---------------------------------------------------------------------------------------------------------------------------------------
Note:-
* 
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_API_DamageEstimatorMockTest Implements HttpCalloutMock {

    /*********************************************************************************************************************
    * Purpose/Methods:
    * This is used to create the mock response
    *********************************************************************************************************************/
    public HTTPResponse respond(HTTPRequest req) {
        SBR_3_0_API_CreateDamageEstimator.DamageEstimatorSuccessResponseWrapper responseWrapper = new SBR_3_0_API_CreateDamageEstimator.DamageEstimatorSuccessResponseWrapper();
        responseWrapper.damageInvoiceNumber = 12345;
        responseWrapper.sequenceNumber = 02;
        responseWrapper.mode = '243697';
        responseWrapper.message = '243697';
        responseWrapper.body = 'body';
        responseWrapper.headers = new List<String>{'header'};

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        res.setHeader('companyId', '1');

        if(req.getEndpoint().endsWithIgnoreCase('token')) {
            res.setHeader('Content-Type','application/octet-stream');
            res.setBody('{"access_token":"test"}');
            res.setStatusCode(200);
        } else if(req.getEndpoint().contains('invoice')) {
            SBR_3_0_API_CreateDamageEstimator.DamageEstimatorInvoiceParentReqWrapper parentWrapperResponse = new SBR_3_0_API_CreateDamageEstimator.DamageEstimatorInvoiceParentReqWrapper();
            parentWrapperResponse = (SBR_3_0_API_CreateDamageEstimator.DamageEstimatorInvoiceParentReqWrapper)JSON.deserializeStrict(req.getBody(), SBR_3_0_API_CreateDamageEstimator.DamageEstimatorInvoiceParentReqWrapper.class);

            SBR_3_0_API_CreateDamageEstimator.DamageEstimatorInvoiceWrapper wrapperResponse = new SBR_3_0_API_CreateDamageEstimator.DamageEstimatorInvoiceWrapper();
            wrapperResponse = parentWrapperResponse.damageEstimatorInvoice[0];
            
            if(String.isBlank(wrapperResponse.invoiceComments1)) {
                SBR_3_0_API_CreateDamageEstimator.DamageEstimatorErrorResponseWrapper damageEstimatorErrResponseWrpr = new SBR_3_0_API_CreateDamageEstimator.DamageEstimatorErrorResponseWrapper();
                SBR_3_0_API_CreateDamageEstimator.ErrorResponseWrapper errorResponseWrapper = new SBR_3_0_API_CreateDamageEstimator.ErrorResponseWrapper();
                
                errorResponseWrapper.errorCode = '009';
                errorResponseWrapper.errorKey = 'error';
                errorResponseWrapper.message = 'error';
                damageEstimatorErrResponseWrpr.error = errorResponseWrapper;
                res.setBody(JSON.serialize(damageEstimatorErrResponseWrpr));
                res.setStatusCode(400);
                res.setStatus('error');

                return res;
            }
            
            res.setBody(JSON.serialize(responseWrapper));
            res.setStatusCode(200);
        }

        return res;
    }
}