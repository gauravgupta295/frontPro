/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_WarrantyClaimMockTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Mock class for SBR_3_0_API_CreateWarrantyClaim
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Meghna Vijay			2024-03-11			Initlal version
---------------------------------------------------------------------------------------------------------------------------------------
Note:-
* 
*********************************************************************************************************************/
@isTest
public class SBR_3_0_API_WarrantyClaimMockTest Implements HttpCalloutMock {
	
    /*********************************************************************************************************************
    * Purpose/Methods:
    * This is used to create the mock response
    *********************************************************************************************************************/
    public HTTPResponse respond(HTTPRequest req) {
        SBR_3_0_API_CreateWarrantyClaim.WorkOrderClaimSuccessResponseWrapper responseWrapper = new SBR_3_0_API_CreateWarrantyClaim.WorkOrderClaimSuccessResponseWrapper();
        SBR_3_0_API_CreateWarrantyClaim.WorkOrderClaimDataResponseWrapper claimDataWrapper = new SBR_3_0_API_CreateWarrantyClaim.WorkOrderClaimDataResponseWrapper();
        claimDataWrapper.warrantyClaimNumber = 12345;
        claimDataWrapper.message = 'Warranty claim has been successfully processed';
		responseWrapper.data = claimDataWrapper;
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        res.setHeader('companyId', '01');

        if(req.getEndpoint().endsWithIgnoreCase('token')) {
            res.setHeader('Content-Type','application/octet-stream');
            res.setBody('{"access_token":"test"}');
            res.setStatusCode(200);
        } 
        
        else if(req.getEndpoint().contains('claim')) {
            SBR_3_0_API_CreateWarrantyClaim.WorkOrderClaimParentReqWrapper parentWrapperResponse = new SBR_3_0_API_CreateWarrantyClaim.WorkOrderClaimParentReqWrapper();
            parentWrapperResponse = (SBR_3_0_API_CreateWarrantyClaim.WorkOrderClaimParentReqWrapper)JSON.deserializeStrict(req.getBody(), SBR_3_0_API_CreateWarrantyClaim.WorkOrderClaimParentReqWrapper.class);

            SBR_3_0_API_CreateWarrantyClaim.WorkOrderClaimRequestWrapper claimRequestWrapperResp = new SBR_3_0_API_CreateWarrantyClaim.WorkOrderClaimRequestWrapper();
            claimRequestWrapperResp = parentWrapperResponse.workOrderClaim[0];
            
            SBR_3_0_API_CreateWarrantyClaim.ClaimDetailsWrapper claimDetailWrapper = new SBR_3_0_API_CreateWarrantyClaim.ClaimDetailsWrapper();
            claimDetailWrapper = claimRequestWrapperResp.claimDetails[0];
            
            if(String.isBlank(claimDetailWrapper.comment1)) {
                SBR_3_0_API_CreateWarrantyClaim.WorkOrderClaimErrorResponseWrapper workOrderClaimErrorWrapper = new SBR_3_0_API_CreateWarrantyClaim.WorkOrderClaimErrorResponseWrapper();
                SBR_3_0_API_CreateWarrantyClaim.ErrorResponseWrapper errorResponseWrapper = new SBR_3_0_API_CreateWarrantyClaim.ErrorResponseWrapper();
                
                errorResponseWrapper.errorCode = '009';
                errorResponseWrapper.errorKey = 'error';
                errorResponseWrapper.message = 'error';
                workOrderClaimErrorWrapper.error = errorResponseWrapper;
                res.setBody(JSON.serialize(workOrderClaimErrorWrapper));
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