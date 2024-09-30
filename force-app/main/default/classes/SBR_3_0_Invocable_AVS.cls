/*********************************************************************************************************************
* Apex Class: SBR_3_0_Invocable_AVS
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Invocable class to get lat long for an address from a flow
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Konrad Haight           2022-10-18          Initial version
*********************************************************************************************************************/
public with sharing class SBR_3_0_Invocable_AVS {
    private static final String JOB_SITE_TYPE = 'delivery';
    private static final String LATITUDE = 'latitude';
    private static final String LONGITUDE = 'longitude';
    private static final String ADDRRESULT = 'result';
    private static final string ADDMESSAGE = 'message';
    @InvocableMethod(
      label='Validate Address'
      description='Call the AVS API'
    )
    public static List<AVSResponse> validateAddress(List<AVSRequest> requests) {
        SBR_3_0_API_AVS avs = new SBR_3_0_API_AVS();
        AVSResponse response = new AVSResponse();
        AVSRequest request = requests[0];
        SBR_3_0_AVSHelper avh = new SBR_3_0_AVSHelper();
        avh.address.line1 = request.streetOne;
        avh.address.line2 = '';
        avh.address.city = request.city;
        avh.address.state = request.state;
        avh.address.zip = request.zip;
        avh.address.type = JOB_SITE_TYPE;
        if (request.country == 'US' || request.country == 'United States') {
            avh.address.company = '1';
        }
        else if (request.country == 'CA' || request.country == 'Canada') {
            avh.address.company = '2';
        }
        else {
            avh.address.company = '0';
        }
        Map<String, String> avsResponse = avs.validateAddress(avh);

        if(avsResponse != null) {

            if(avsResponse.containsKey(ADDRRESULT)) {
                response.result = avsResponse.get(ADDRRESULT);
            }
            if(avsResponse.containsKey(ADDMESSAGE)) {
                response.message = avsResponse.get(ADDMESSAGE);
            }
            if(avsResponse.containsKey(LATITUDE)) {
                if (avsResponse.get(LATITUDE) != null) {
                    response.latitude = Decimal.valueOf(avsResponse.get(LATITUDE));
                }
            }
            if(avsResponse.containsKey(LONGITUDE)) {
                if (avsResponse.get(LONGITUDE) != null) {
                    response.longitude = Decimal.valueOf(avsResponse.get(LONGITUDE));
                }
            }
        }

        List<AVSResponse> responses = new List<AVSResponse>();
        responses.add(response);
        return responses;
    }

    public class AVSRequest {
        @InvocableVariable(label='Street' required=false)
        public String streetOne;
        @InvocableVariable(label='City' required=false)
        public String city;
        @InvocableVariable(label='State' required=false)
        public String state;
        @InvocableVariable(label='Zip' required=false)
        public String zip;
        @InvocableVariable(label='Country' required=false)
        public String country;
    }

    public class AVSResponse {
        @InvocableVariable(label='Validation Result' required=false)
        public String result;
        @InvocableVariable(label='Message' required=false)
        public String message;
        @InvocableVariable(label='Latitude' required=false)
        public Decimal latitude;
        @InvocableVariable(label='Longitude' required=false)
        public Decimal longitude;
        
    }
}