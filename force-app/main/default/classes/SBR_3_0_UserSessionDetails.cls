public with sharing class SBR_3_0_UserSessionDetails {

    private static final String METADATAAPINAME = 'Okta_Password_Verification';
    
    /***************************************************************************************************************
    Author: Manu
    Method Name : fetchUserSessionId
    Purpose: Method to get User Session Id.
    ****************************************************************************************************************/ 
    @AuraEnabled(cacheable=false) 
    public static String fetchUserSessionId(){
        String sessionId = '';
        // Get the Session Id
        sessionId = UserInfo.getOrganizationId() + UserInfo.getSessionId().substring(15);
        // Return Session Id
        return sessionId;
    }

    /*********************************************************************************************************************
    ----------------------------------------------------------------------------------------------------------------------
    * Purpose/Methods:
    * - Send Password to Okta (via Mulesoft) for Password Verification
    ----------------------------------------------------------------------------------------------------------------------
    *********************************************************************************************************************/

    @AuraEnabled(cacheable=false) 
    public static String fetchUserEmailAddress(){
        String userEmail = '';
        // Get the logged in user email address
        userEmail = UserInfo.getUserEmail();
        return userEmail;
    }

    @AuraEnabled
    public static String oktaPasswordVerification(String pswddata) {
        String response = '';
        if(!Test.isRunningTest()){
            response = SBR_3_0_Generic_Callout.callEndpoint(pswddata, METADATAAPINAME).getbody();
        }
        return response;
    }
    
}