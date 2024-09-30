/*********************************************************************************************************************
* Apex Class: SBR_3_0_APISettings
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to initialize parameters for API calls
* - SAL
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Viren Patel           2022-02-07           Initial version    
    2.0         Harry Rokad           2022-06-21           Commented out the constructor. * Apex PMD *
*********************************************************************************************************************/

public without sharing class SBR_3_0_APISettings {
    //private static Boolean isSandbox = [SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox;
    //private static String thisEnvironment = (isSandbox) ?  SBR_3_0_Constants.SANDBOX : SBR_3_0_Constants.PRODUCTION;

    public static Map<String, Global_API_Settings__mdt> apiMap {
        get {
            if(apiMap==null || (apiMap!=null && apiMap.size()==0)) {
                apiMap = new Map<String, Global_API_Settings__mdt>();
                for(Global_API_Settings__mdt api : 
                    [SELECT 
                        Id, Developername, Protocol__c, Host__c, Resource__c, Path_Params__c, Method__c, 
                        Named_Credential_API_Name__c, Timeout__c, Environment__c, Credential_Name__c, Is_JWT_Enabled__c 
                        FROM Global_API_Settings__mdt
                        //WHERE Environment__c = :thisEnvironment
                    ]) {
                            apiMap.put(api.Developername, api);                                
                }
            }
            System.debug('\n apiMap = ' + apiMap);
            return apiMap;
        }
        set;
    }

    public static Map<String, Credential__c> credsMap {
        get{
            if(credsMap == null) {
                credsMap = new  Map<String, Credential__c>();
                for (Credential__c cred : [SELECT Id, Name, Key_Id__c, Secret__c 
                        FROM Credential__c 
                        //WHERE Environment__c = :thisEnvironment
                        ]) {
                    credsMap.put(cred.Name, cred);
                }
            }
            System.debug('\n credsMap = ' + credsMap);
            return credsMap;
        }
        set;
    }
    
    // public SBR_3_0_APISettings() {}

    public static Map<String, Global_API_Settings__mdt> getAPIMap() {
        return apiMap;
    }

    public static Map<String,Credential__c> getCredsMap() {
        return credsMap;
    }

    public static Global_API_Settings__mdt getAPIDetails(String settingAPIName) {
        return apiMap.get(settingAPIName);
    }    

    public static Credential__c getCredentials(String credName) {
        return credsMap.get(credName);
    }

    public class ApiData {
        public Global_API_Settings__mdt apiDetails {get;set;}
        public Credential__c creds {get;set;}

        public ApiData(Global_API_Settings__mdt apiDetails, Credential__c creds) {
            this.apiDetails = apiDetails;
            this.creds = creds;
        }
    }

    public class APIException extends Exception{}
}