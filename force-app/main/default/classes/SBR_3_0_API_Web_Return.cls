@RestResource(urlMapping='/Order/ApiReturn/v1/*')
global with sharing class SBR_3_0_API_Web_Return {

    @HttpPost
    global static void createReturn(){
        System.debug('In API ' + RestContext.request.requestBody.toString());

        String req = RestContext.request.requestBody.toString();
        Savepoint sp = Database.setSavepoint();
        try {
            SBR_3_0_CreateReturn ret = new SBR_3_0_CreateReturn(req);
            String returnVal = ret.syncReturnToSF();

            Map<String,String> respMap = new Map<String,String>();         
            respMap.put('Status', 'Success');
            respMap.put('Message', returnVal);
            Integer statusCode = 200;
            SBR_3_0_HttpResponse.setRestResponse(respMap, statusCode);
            
        }catch (Exception error) {
            Database.rollback(sp);
            SBR_3_0_LogException.LogIt(error, '', req);
			System.debug('error mk: '+error);
            Map<String,String> respMap = new Map<String,String>();
            respMap.put('Status', 'Error');
            respMap.put('Message', error.getMessage() + ' | ' + error.getStackTraceString());
            // SG:05032024:PS-5769:Added 500 return code for Mule to retry in case of Unable to Lock Row exceptions
            Integer statusCode;
            if (error.getMessage().contains('UNABLE_TO_LOCK_ROW') || error.getMessage().containsIgnoreCase('Record Currently Unavailable')) {
                statusCode= 500;
            }else{
                statusCode= 400;
            }
            SBR_3_0_HttpResponse.setRestResponse(respMap, statusCode);
        }
    }
}