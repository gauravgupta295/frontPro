/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_AVS
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to create request and handle response for validating addresses
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Konrad Haight           2022-03-15          Initial version    
*********************************************************************************************************************/
public without sharing class SBR_3_0_API_AVS extends SBR_3_0_HttpCallout {
	private static final String APINAME = 'AVS_Check';
    private static final String DATA = 'data';
    private static final String ADDRESSINFO = 'addressInfo';
    private static final String ADDRRESULT = 'result';
    private static final string ADDMESSAGE = 'message';
    private static final String LATITUDE = 'latitude';
    private static final String LONGITUDE = 'longitude';
    private static final String ERROR = 'error';
    private SBR_3_0_AVSHelper addressValidationFields;
    public Object responseAddMessage;
    
   	public SBR_3_0_API_AVS(){
        super(APINAME);
    }
    
    private Object getResponseBody() {

        setHeader('companyId', addressValidationFields.address.company);
        setHeader('Content-Type', SBR_3_0_Constants.APP_JSON);
       	setRequestBody(createRequestBody());

       	HttpResponse res = sendRequest();
	    try{
            return JSON.deserializeUntyped(res.getBody());	
        } catch(Exception e){
            System.debug('Response body not in correct format for JSON.deseralizeUntyped, error message: ' + e.getMessage());
            return null;
        }
    }
    
    private String createRequestBody() {
       	String body = JSON.serialize(addressValidationFields);
       	return body;
    }
    
    
    public Map<String, String> validateAddress(SBR_3_0_AVSHelper avh){
        Map<String, String> returnValue = new Map<String, String>();
        addressValidationFields = avh;
        Object result = getResponseBody();
        if (result != null && result instanceof Map<String, Object>) {
            Map<String, Object> resultMap = (Map<String, Object>)result;
            
            if(resultMap.containsKey(DATA) && resultMap.get(DATA) instanceof Map<String, Object>){
                Map<String, Object> data = (Map<String, Object>)resultMap.get(DATA);
                if(data.containsKey(ADDRESSINFO)){
                	Map<String, Object> addressInfo = (Map<String, Object>)data.get(ADDRESSINFO);
                    system.debug('Address info: ' + addressInfo);
                    if(addressInfo.containsKey(ADDMESSAGE)){
                        returnValue.put(ADDMESSAGE, JSON.serialize(addressInfo.get(ADDMESSAGE)));
                    }
                    if(addressInfo.containsKey(ADDRRESULT)){
               			if(addressInfo.get(ADDRRESULT) == '0'){
                			returnValue.put(ADDRRESULT, SBR_3_0_Constants.STATUS_VALID);
            			}
            			else {
                		    returnValue.put(ADDRRESULT, SBR_3_0_Constants.STATUS_INVALID);
                        }
                    }
                    else{
                        System.debug('addressInfo does not contain addrResult key');
                        return null;
                    }
                    if(addressInfo.containsKey(LATITUDE)) {
                        returnValue.put(LATITUDE, String.valueOf(addressInfo.get(LATITUDE)));
                    }
                    if(addressInfo.containsKey(LONGITUDE)) {
                        returnValue.put(LONGITUDE, String.valueOf(addressInfo.get(LONGITUDE)));
                    }
              	}
                else{
                    System.debug('data does not contain addressInfo key');
                    return null;
                }
            }
            else{
                System.debug('result map does not contain data key');
                if(resultMap.containsKey(ERROR)) {
                    Map<String, Object> error = (Map<String, Object>)resultMap.get(ERROR);
                    if(error.containsKey(ADDMESSAGE)) {
                        returnValue.put(ADDMESSAGE, String.valueOf(error.get(ADDMESSAGE)));
                        returnValue.put(ADDRRESULT, SBR_3_0_Constants.STATUS_INVALID);
                    }
                }
            }
        }
        else {
            //The code may not be able to get here because it will throw an error at JSON.deseralizeUntyped if it's not in an acceptable format//
            System.debug('result Map not in expected format error');
            returnValue.put(ADDMESSAGE, 'Address validation not available at this time.');
        }
        return returnValue;
    }
}