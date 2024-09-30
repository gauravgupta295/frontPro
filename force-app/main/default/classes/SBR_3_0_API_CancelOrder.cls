/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_CancelOrder
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* Send Cancel Order request to Rentalman (via Mulesoft) 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kishore Meesala        2023-18-10             Initial version    
*********************************************************************************************************************/
public class SBR_3_0_API_CancelOrder 
{
    private static final String APINAME_ORDER_CANCEL = 'SBR_3_0_API_CancelOrder';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);

    @AuraEnabled
    public static String cancelOrder(String orderId, String reasonCode) {

        System.debug('Cancel API Start');
        try{
            boolean isSuccess = callCancelOrderApi(orderId, reasonCode);
            if(isSuccess)
            {
                return 'Success';
            }else
            {
                return 'Failed';
            }
            
        }catch(Exception e){
            System.debug(e);
            return 'Failed';
        }
    }

    public static boolean callCancelOrderApi(String orderId, String reasonCode)
    {

        Order orderRecord = getOrder(orderId);
        User loggedInUser = getUserById(UserInfo.getUserId());
        Schema.Location sourceBranch = getLocation(orderRecord.Sourcing_Branch__c);
        SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME_ORDER_CANCEL);
        httpCallout.setHeader('companyId', orderRecord.Company_Code__c);
        httpCallout.setHeader('rentalmanUser', loggedInUser.Wynne_User_Name__c);
        httpCallout.setHeader('location', sourceBranch.Branch_Location_Number__c);
        httpCallout.setHeader('x-correlation-id', X_CORRELATION_ID);
        httpCallout.setHeader('cancellationReasonCode', reasonCode);
        httpCallout.setHeader('accept', 'application/json');
        system.debug('X_CORRELATION_ID:' +X_CORRELATION_ID);
        List<String> pathParams = new List<String>();
        pathParams.add(orderRecord.Reservation_Order_Number__c);
        httpCallout.setPathParams(pathParams);

        HttpRequest req = httpCallout.getRequest();
        system.debug(req.getEndpoint());
        req.setEndpoint(req.getEndpoint());

        Http http = new Http();
        HTTPResponse res = http.send(req);
        String returnPayload = res.getBody();
        System.debug ('body--** '+res.getBody());
        System.debug ('returnPayload** '+returnPayload);
        System.debug ('returnPayload** '+res.getStatusCode());
        if (res.getStatusCode() == 200){
            return true;
        }else{
            insert new Exception_Log__c(Exception_Message__c = returnPayload, Class_Name__c = 'SBR_3_0_API_CancelOrder',
                                        Stack_Trace__c = 'Failed Payload : '+ req);
            return false;
        }

    } 

    public static Order getOrder(String orderId) {
        return [SELECT Id, OwnerId, Company_Code__c, Contingency_Order__c, Seasonal_Order__c, Shift_Order__c, Apply_Standby_Rates__c, Branch__r.Branch_Location_Number__c, Sourcing_Branch__c, Reservation_Order_Number__c FROM Order WHERE Id = :orderId];
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