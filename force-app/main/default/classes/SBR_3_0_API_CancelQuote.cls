/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_CancelQuote
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* Send Cancel Quote request to Rentalman (via Mulesoft) 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Shriya Sharma        2023-07-12             Initial version    
*********************************************************************************************************************/
public class SBR_3_0_API_CancelQuote {
    private static final String APINAME_QUOTE_CANCEL = 'Sbr_3_0_Quote_Cancel_API';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    public static Map<Integer,String> responseCode = new Map<Integer,String>();
    public static Integer[] codeArray  = new Integer[] {400,422,200,405};
 @AuraEnabled
    public static String cancelQuote(String quoteId) {

        System.debug('Quote API Start');
        Map<Integer,String> resMap = new Map<Integer,String>();
        try{
          resMap =  callCancelQuoteApi(quoteId);
            String message = '';
            for(Integer keyval: resMap.keyset()){
                if(codeArray.contains(keyval)){
                if(keyval == 200){
                    message = 'Success';
                    
                }
                else {
                    message = resMap.get(keyval);
                }
                
            }
                else {
                    message = 'Failed';
                }
            }
            
            return message;
            
        }catch(Exception e){
            System.debug(e);
             return 'Failed';
        }
    }

    public static Map<Integer,String> callCancelQuoteApi(String quoteId)
    {

        SBQQ__Quote__c  quoteRecord =  getQuote(quoteId);
        User loggedInUser = getUserById(UserInfo.getUserId());
        Schema.Location sourceBranch = getLocation(quoteRecord.Sourcing_Branch__c);
        SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME_QUOTE_CANCEL);
        httpCallout.setHeader('companyId', quoteRecord.Company_Code__c);
        httpCallout.setHeader('rentalmanUser', loggedInUser.Wynne_User_Name__c);
        httpCallout.setHeader('location', sourceBranch.Branch_Location_Number__c);
        httpCallout.setHeader('x-correlation-id', X_CORRELATION_ID);
        httpCallout.setHeader('accept', 'application/json');
        List<String> pathParams = new List<String>();
        pathParams.add(quoteRecord.Rentalman_Quote_Id__c);
        httpCallout.setPathParams(pathParams);

        HttpRequest req = httpCallout.getRequest();
        system.debug(req.getEndpoint());
        req.setEndpoint(req.getEndpoint());

        Http http = new Http();
        HTTPResponse res = http.send(req);
        String returnPayload = res.getBody();
        System.debug ('body--** '+res.getBody());
        String respMsg = '';
        if(res.getStatusCode()!=200){
         Map<String, Object> responseBodyMap = (Map<String, Object>) JSON.deserializeUntyped(returnPayload);
         Map<String, Object> data = (Map<String, Object>) responseBodyMap.get('error');
         respMsg = (String) data.get('message');
        }
         System.debug ('returnPayload** '+returnPayload);
         System.debug ('returnPayload** '+res.getStatusCode());
		 responseCode.put(res.getStatusCode(),respMsg);
         if (res.getStatusCode()!= 200){
           insert new Exception_Log__c(Exception_Message__c = returnPayload, Class_Name__c = 'SBR_3_0_API_CancelQuote',
                                        Stack_Trace__c = 'Failed Payload : '+ req);
        }
        return responseCode;
       

    } 

    public static SBQQ__Quote__c  getQuote(String quoteId) {
        return [SELECT Id, OwnerId, Company_Code__c, Branch__r.Branch_Location_Number__c, Sourcing_Branch__c, Rentalman_Quote_Id__c FROM SBQQ__Quote__c WHERE Id = :quoteId];
    }

    public static User getUserById(Id userId) {
        return [SELECT ID, FirstName, LastName, Name, ProfileId,TimeZoneSidKey, profile.Name, Tech_Rep_Type__c, 
                UserRole.Name, CompanyName, Branch__c, Department, Rep_Type__c, Analysis_Region_Key__c, 
                Wynne_User_Name__c 
                FROM User WHERE Id =: userId];
    }

    public static Schema.Location getLocation(Id locId){
    	return [SELECT Id, Branch_Location_Number__c, Latitude_Longitude__Latitude__s, Latitude_Longitude__Longitude__s,Time_Zone_Id__c
                FROM Location 
                WHERE Id = :locId ];
    }
}