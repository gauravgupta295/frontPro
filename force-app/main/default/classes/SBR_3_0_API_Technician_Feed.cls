/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_Technician_Feed
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose:
* - RM hits the Technician Feed API with the Payload, which gets deserialized and updates the Service Resource Record 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Mayank Jain 			2023-04-28			Initial version  
*********************************************************************************************************************/
@RestResource(urlMapping='/ServiceResource/ApiUpdateResource/v1/*')
global with sharing class SBR_3_0_API_Technician_Feed {
    @HttpPost
    global static void updateServiceResource(){
        RestResponse res = RestContext.response;
        System.debug('In API ' + RestContext.request.requestBody.toString());

        String req = RestContext.request.requestBody.toString();
        Savepoint sp = Database.setSavepoint();
        try{
            SBR_3_0_UpdateTechnicianFeed co = new SBR_3_0_UpdateTechnicianFeed(req);
            String resultMsg = co.syncServiceResourceToSF();
            Map<String,String> respMap = new Map<String,String>();         
            Integer statusCode;
            if(resultMsg == 'Success'){
                statusCode = 200;
                respMap.put('Status', 'Success');
                respMap.put('Message',resultMsg );
            }else{
                respMap.put('Status', 'Error');
                respMap.put('Message',resultMsg );
                statusCode = 400;
            }
            res.responseBody = Blob.valueOf(JSON.serialize(respMap));
            res.statusCode = statusCode;
            //SBR_3_0_HttpResponse.setRestResponse(respMap, statusCode);56
        }catch (Exception error){
            Database.rollback(sp);
            
            Map<String,String> respMap = new Map<String,String>();
            respMap.put('Status', 'Error');
            respMap.put('Message', error.getMessage() + ' | ' + error.getStackTraceString());
            Integer statusCode = 400;
            SBR_3_0_HttpResponse.setRestResponse(respMap, statusCode);
        }
    }
}