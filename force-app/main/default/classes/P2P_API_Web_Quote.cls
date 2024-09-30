/*********************************************************************************************************************
* Apex Class: P2P_API_Web_Quote
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Custom API to give P2P Users Ability to Create Quote In SF
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Delvin Riley			2023-10-12			Initial version    
*********************************************************************************************************************/

@RestResource(urlMapping='/P2P/Quote/ApiCreate/v1/*')
global with sharing class P2P_API_Web_Quote {

    @HttpPost
    global static void create(){
                 
      system.debug('p2p create start ' + system.now());

        String req = RestContext.request.requestBody.toString();
        Savepoint sp = Database.setSavepoint();
        try {
            P2P_CustomCreateQuote co = new P2P_CustomCreateQuote(req);
			SObject returnVal = co.upsertQuoteToSF();

            Map<String,SObject> respMap = new Map<String,SObject>();         
            respMap.put('Message', returnVal);
            Integer statusCode = 200;
            SBR_3_0_HttpResponse.p2pSetRestResponse(respMap, statusCode);
            
            system.debug('p2p create end ' + system.now());
            
        }catch (Exception error) {
            Database.rollback(sp);
            
            Map<String,String> respMap = new Map<String,String>();
            respMap.put('Status', 'Error');
            respMap.put('Message', error.getMessage() + ' | ' + error.getStackTraceString());
            Integer statusCode = 400;
            SBR_3_0_HttpResponse.setRestResponse(respMap, statusCode);

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