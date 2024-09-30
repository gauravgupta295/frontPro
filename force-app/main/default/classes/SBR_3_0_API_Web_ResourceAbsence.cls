/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_Web_ResourceAbsence
* Created By: Shubham Tunkikar
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to create the rest end point for inbound Absence requests.
* - Endpoint URL Can be given as "/services/apexrest/ResourceAbsence/ApiCreate/v1"
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE               DETAIL FEATURES
    1.0          2023-09-01          Initial version
**********************************************************************************************************************************************/
@RestResource(urlMapping='/ResourceAbsence/ApiCreate/v1/*')
global with sharing class SBR_3_0_API_Web_ResourceAbsence {
    /**
     * @description: Http Post method, Getting called from external systems to create or update ResourceAbsence record.
     */
    @HttpPost
    global static void upsertAbsence()
    {
        Integer statusCode = 200;
        SBR_3_0_ResourceAbsenceRequestWrapper.ResultWrapper result = new SBR_3_0_ResourceAbsenceRequestWrapper.ResultWrapper (false, '', '');
        try
        {
            RestRequest request = RestContext.request;
            //Extract Request Body From request
            String requestBody = request.requestBody.toString();
            //Instentiate handler class
            SBR_3_0_ResourceAbsenceHandler objResourceHandler = new SBR_3_0_ResourceAbsenceHandler(requestBody);
            //Process Request.
            result = objResourceHandler.processRequest();
            //Set Response to be sent.
            SBR_3_0_HttpResponse.setRestResponse(result.getResponseMap(), statusCode);

        }
        catch (Exception error)
        {
            System.debug('error::'+error);
            result = new SBR_3_0_ResourceAbsenceRequestWrapper.ResultWrapper(false, error.getMessage(), error.getMessage() + ' | ' + error.getStackTraceString());
            statusCode = 500;
            SBR_3_0_HttpResponse.setRestResponse(result.getResponseMap(), statusCode);
        }
    }
}