/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_Inspection_Appointments
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose:
* - RM hits the ApiUpdateApointment API with the Payload, which gets deserialized and updates the Service Resource Record 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Mayank Jain 			2023-04-12			Initial version  
*********************************************************************************************************************/
@RestResource(urlMapping='/WorkOder/ApiUpdateApointment/v1')
global with sharing class SBR_3_0_API_Inspection_Appointments {
    @HttpPost
    global static void create(){
        System.debug('In API ' + RestContext.request.requestBody.toString());

        String req = RestContext.request.requestBody.toString();
        //Savepoint sp = Database.setSavepoint();
        try {
            SBR_3_0_CustomUpdateWorkOrder co = new SBR_3_0_CustomUpdateWorkOrder(req);
            String returnVal = co.syncWorkOrderToSF();
            Map<String,String> respMap = new Map<String,String>();
            Integer statusCode;
            respMap.put('Status', 'Success');
            respMap.put('Message', returnVal);
            statusCode = 200;      
            SBR_3_0_HttpResponse.setRestResponse(respMap, statusCode);
            
        }catch (Exception error) {
            //Database.rollback(sp);
            
            Map<String,String> respMap = new Map<String,String>();
            respMap.put('Status', 'Error');
            respMap.put('Message', error.getMessage() + ' | ' + error.getStackTraceString());
            Integer statusCode = 400;
            SBR_3_0_HttpResponse.setRestResponse(respMap, statusCode);

            try {
                SBR_3_0_LogException.LogIt(error, '', req);
            }
            catch(Exception ex) {
/*              if(req.length()>131072) {
                    SBR_3_0_LogException.LogIt(ex, '', req.substring(0, req.length()-1));
                }
                else {
                    SBR_3_0_LogException.LogIt(ex);
                }
*/
                logException(ex);
            }
        }
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Log Exception - Create a record of Exception Log Object.
    *********************************************************************************************************************/
    @TestVisible private static void logException(Exception ex) {
        // Handle any exceptions that occur during the update process.
        Map<String,String> exceptionParams = new Map<String,String>();
        exceptionParams.put('ClassName', 'SBR_3_0_API_Inspection_Appointments');
        exceptionParams.put('MethodName', 'create');
        exceptionParams.put('Type', ex.getTypeName());
        exceptionParams.put('LineNumber', String.valueOf(ex.getLineNumber()));
        exceptionParams.put('StackTrace', ex.getStackTraceString());
        exceptionParams.put('Message', ex.getMessage());
        PPA_ExceptionLogHandler.createExceptionLog(exceptionParams);
    }
}