/*********************************************************************************************************************
* Apex Class: SBR_3_0_UpsertPO
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Custom API call to Create/Update Purchase Order and Purchase Order Line item in Salesforce from incoming JSON payload from RM
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME            DATE                   DETAIL FEATURES
1.0             Yashwee Nemmani           2024-03-28             Updated version
*********************************************************************************************************************/

@RestResource(urlMapping='/Purchase_Order__c/ApiCreate/v1/*') 
global with sharing class SBR_3_0_API_Web_PurchaseOrder {
    private static Integer statusCode;

    @HttpPost
    global static void createOrder() {
        String req = RestContext.request.requestBody.toString();
        Savepoint sp = Database.setSavepoint();
        Integer attempts = 0;
        String recordUnavailableMsg ='Record Currently Unavailable';
        String recordLockedMsg = 'UNABLE_TO_LOCK_ROW';

        while (true) {
            Savepoint sp1 = Database.setSavepoint();

            try {
                SBR_3_0_UpsertPO.handlePO(req);

                Map<String, String> respMap = new Map<String, String>();         
                respMap.put('Status', 'Success');
                respMap.put('Message', 'Successfully Completed');
                statusCode = 200;
                SBR_3_0_HttpResponse.setRestResponse(respMap, statusCode);
                break;

            } catch (Exception error) {
                if (error.getMessage().containsIgnoreCase(recordLockedMsg) || error.getMessage().containsIgnoreCase(recordUnavailableMsg)) {
                    Database.rollback(sp1);
                    attempts++;
                    if (attempts > 20) {
                        break;
                    }
                } else {
                    Database.rollback(sp);
                    system.debug('Complete Error..' + error);
                    system.debug('error.getStackTraceString()..' + error.getStackTraceString());
                    Map<String, String> respMap = new Map<String, String>();
                    respMap.put('Status', 'Error');
                    respMap.put('Message', error.getMessage() + ' | ' + error.getStackTraceString());
                    if (error instanceOf QueryException && error.getMessage().contains('Invalid value')) {
                        statusCode = 404;
                    } else {
                        statusCode = 400;
                    }
                    SBR_3_0_HttpResponse.setRestResponse(respMap, statusCode);

                    try {
                        SBR_3_0_LogException.LogIt(error, '', req);
                    } catch (Exception ex) {
                        if (req.length() > 131072) {
                            SBR_3_0_LogException.LogIt(ex, '', req.substring(0, req.length() - 1));
                        } else {
                            SBR_3_0_LogException.LogIt(ex);
                        }
                    }
                    break;
                }
            }
        }
    }
}