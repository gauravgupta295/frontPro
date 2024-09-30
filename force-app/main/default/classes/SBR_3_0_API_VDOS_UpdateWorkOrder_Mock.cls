/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_VDOS_UpdateWorkOrder_Mock
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Mock class for SBR_3_0_API_VDOS_UpdateWorkOrder_Test
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Shubham Tunkikar        2023-10-31          Initial version
    2.0         Piyush Jindal           2023-12-01          Added class and method description
    3.0         Piyush Jindal           2023-12-05          Added new Request Wrapper attributes
    4.0         Piyush Jindal           2023-12-07          Modified logic as there was a change in Response.
---------------------------------------------------------------------------------------------------------------------------------------
Note:-
* 
*********************************************************************************************************************/
public with sharing class SBR_3_0_API_VDOS_UpdateWorkOrder_Mock Implements HttpCalloutMock {

    /*********************************************************************************************************************
    * Purpose/Methods:
    * This is used to create mock response
    *********************************************************************************************************************/
    public HTTPResponse respond(HTTPRequest req) {
        SBR_3_0_VDOS_UpdateWorkOrderWrapper.ResponseWrapper responseWrapper = new SBR_3_0_VDOS_UpdateWorkOrderWrapper.ResponseWrapper();
        SBR_3_0_VDOS_UpdateWorkOrderWrapper.UpdateWorkOrderWrapperResponse workOrderWrapperResponse = new SBR_3_0_VDOS_UpdateWorkOrderWrapper.UpdateWorkOrderWrapperResponse();
        workOrderWrapperResponse.vdosId = '12345';
        workOrderWrapperResponse.companyId = '02';
        workOrderWrapperResponse.rmWorkOrderId = '243697';
        workOrderWrapperResponse.sfWorkOrderId = '243697';
        
		responseWrapper.data = workOrderWrapperResponse;

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        res.setHeader('companyId', '1');

        if(req.getEndpoint().endsWithIgnoreCase('token')) {
            res.setHeader('Content-Type','application/octet-stream');
            res.setBody('{"access_token":"test"}');
            res.setStatusCode(200);
        } else if(req.getEndpoint().contains('woassignment')) {
            Map<String,Object> objFieldMap = (Map<String,Object>)JSON.deserializeUntyped(req.getBody());

            if(String.isBlank((String)objFieldMap.get('rmWorkOrderId'))) {
                res.setStatusCode(500);
                res.setStatus('ERROR');

                return res;
            }            
            
            res.setBody(JSON.serialize(responseWrapper));
            res.setStatusCode(200);
        }

        return res;
    }
}