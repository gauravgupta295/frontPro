/*********************************************************************************************************************
* Apex Class: SBR_3_0_HttpResponse
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Provides a processing method to parse an HTTPResponse object for given keys to find values. 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Tyler Niggel			2022-03-21			Initial version  
    1.2         Nate Kanyok                                 Added getValueFromXMLTags
    1.3         Viren Patel             2022-09-06          Added setResponseMessages
    1.4         Bhavesh Dhamecha        2023-01-27			Bug Fix SAL-12619
	1.5			Delvin Riley			2023-10-12			P2P Adding Features
*********************************************************************************************************************/
public with sharing virtual class SBR_3_0_HttpResponse {
    protected HttpResponse response;

    public static Object getValueForKey(HttpResponse res, String key) {
        Map<String, Object> resMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());

        if (resMap.containsKey(key)) {
            Object token = resMap.get(key);
            return token;
        }
        else {
            return null;
        }
    }

    public static Object getValueFromXMLTags(HttpResponse res, String xmlTag) {
        String delimiter = '<'+xmlTag+'>';
        String afterDelimiter = res.getBody().substringAfter(delimiter);
        String val = afterDelimiter.substringBefore('</'+xmlTag+'>');
        return val;
    }

    public static Object setResponseMessage (String msg, String status) {
         Object responseMessage = new ResponseMessage(msg, status);
         return responseMessage;
    }

    public class ResponseMessage {
        public String message { get; set; }
        public String status { get; set; }

        public ResponseMessage(String message, String status) {
            this.message = message;
            this.status = status;
        } 
    }

    public static RestResponse setRestResponse(Map<String,String> respMap, Integer statusCode) {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        for(String key : respMap.keySet()) {
            gen.writeStringField(key, respMap.get(key));
        }
        gen.writeEndObject();
        // Fix for SAL-12619
        RestResponse restRes;
        if(!Test.isRunningTest())
        {
             restRes = RestContext.response;
        }
        else{
           		restRes = new RestResponse();
        }
         // Fix end 
        system.debug('this is json '
+gen.getAsString());
        restRes.responseBody = Blob.valueOf(gen.getAsString());
        restRes.statusCode = statusCode;
        restRes.headers.put('Content-Type', 'application/json');
        return restRes;
    }
    
  public static RestResponse p2pSetRestResponse(Map<String,SObject> respMap, Integer statusCode){
          JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        for(String key : respMap.keySet()) {
            //potential p2p change
            
            gen.writeObjectField(key, respMap.get(key));
        }
        gen.writeEndObject();
        // Fix for SAL-12619
        RestResponse restRes;
        if(!Test.isRunningTest())
        {
             restRes = RestContext.response;
        }
        else{
           		restRes = new RestResponse();
        }
         // Fix end 
        system.debug('this is json '
+gen.getAsString());
        restRes.responseBody = Blob.valueOf(gen.getAsString());   
        restRes.statusCode = statusCode;
      	restRes.headers.put('Content-Type', 'application/json');
        return restRes;
    }
}