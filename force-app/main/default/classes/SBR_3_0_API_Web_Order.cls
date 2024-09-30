/**
 * @description This class implements a custom order API with the endpoint of
 * /Order/Api/Create/V1.
 * The Apex REST service takes a order wrapper, with line items, line item details, etc.
 * and attempts to create the order record in salesforce.
 * If an exception occurs, the exception is logged to Exception_Log__c, unless the exception
 * is uncatchable. (e.g. it's a row lock error).
 */
@RestResource(urlMapping='/Order/ApiCreate/v1/*')
global with sharing class SBR_3_0_API_Web_Order {

    /**
     * @description Handles any Http POST calls to /Order/Api/Create/v1
     */
    @HttpPost
    global static void createOrder(){
        String req = RestContext.request.requestBody.toString();
        
        try {
            SBR_3_0_CreateOrder co = new SBR_3_0_CreateOrder(req);
            
            String returnVal = co.syncOrderToSF();
            
            SBR_3_0_HttpResponse.setRestResponse(
                new Map<String,String>{
                    'Status' => 'Success',
                    'Message' => returnVal
                },
                200
            );
        }catch(SBR_3_0_CustomException error){
            handleException(req, error.relatedId, error);
        }catch(Exception error){
            handleException(req, '', error);
        }
    }
    
    /**
     * @description helper method for handling create order exceptions
     */
    private static void handleException(String req, String relatedId, Exception error){
        // SG:05032024:PS-5769:Added 500 return code for Mule to retry in case of Unable to Lock Row exceptions
        Integer statusCode;
        if (error.getMessage().contains('UNABLE_TO_LOCK_ROW') || error.getMessage().containsIgnoreCase('Record Currently Unavailable')) {
            statusCode= 500;
        }else{
            statusCode= 400;
        }
        SBR_3_0_HttpResponse.setRestResponse(
            new Map<String,String>{
                'Status' => 'Error',
                'Message' => (error.getMessage() + ' | ' + error.getStackTraceString())
            },
            statusCode
        );
        
        try {
            SBR_3_0_LogException.LogIt(error, relatedId, req);
        }catch(Exception ex){ //NOPMD
            //NOPMD
            //Ignore this exception
        }
    }
}