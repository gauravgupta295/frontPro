/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_Web_WorkOrder
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to create the rest end point for inbound work orders.
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE               DETAIL FEATURES
    1.0          2023-02-23          Initial version 
    2.0          2023-05-10          Harry Rokad   
**********************************************************************************************************************************************/


@RestResource(urlMapping='/WorkOrder/ApiCreate/v1/*')
global with sharing class SBR_3_0_API_Web_WorkOrder {

    @HttpPost
    global static void create(){
        System.debug('In API ' + RestContext.request.requestBody.toString());

        String req = RestContext.request.requestBody.toString();
        Savepoint sp = Database.setSavepoint();
        try {
            SBR_3_0_CustomCreateWorkOrder co = new SBR_3_0_CustomCreateWorkOrder(req);
            String returnVal = co.syncWorkOrderToSF();

            Map<String,String> respMap = new Map<String,String>();         
            respMap.put('Status', 'Success');
            respMap.put('Message', returnVal);
            Integer statusCode = 200;
            SBR_3_0_HttpResponse.setRestResponse(respMap, statusCode);
            
        }catch (Exception error) {
            Database.rollback(sp);
            
            Map<String,String> respMap = new Map<String,String>();
            if (error.getMessage().contains('Asset')){
            respMap.put('Status', 'Error');
            respMap.put('Message', error.getMessage() + ' | ' + error.getStackTraceString());
                Integer statusCode = 501;
                SBR_3_0_HttpResponse.setRestResponse(respMap, statusCode);
            }
            else{
                respMap.put('Status', 'Error');
                respMap.put('Message', error.getMessage() + ' | ' + error.getStackTraceString());
            Integer statusCode = 400;
            SBR_3_0_HttpResponse.setRestResponse(respMap, statusCode);
            }

            try {
                SBR_3_0_LogException.LogIt(error, '', req);
            }
            catch(Exception ex) {
                if(req.length()>131072) {
                    SBR_3_0_LogException.LogIt(ex, '', req.substring(0, req.length()-1));
                }
                else {
                    SBR_3_0_LogException.LogIt(ex);
                }

            }
        }
    }
}