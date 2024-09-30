/*********************************************************************************************************************
* Apex Class: SBR_3_0_APISettings_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_APISettings
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Konrad Haight           2022-03-08          Initial version    
*********************************************************************************************************************/
@isTest public class SBR_3_0_APISettings_Test {
    
    static testMethod void testGetCred(){
        
        List<Credential__c> credentials = SBR_3_0_TestDataFactory.createCredentials(1, true);
        SBR_3_0_APISettings aPISettings = new SBR_3_0_APISettings();
        
        Credential__c credential = SBR_3_0_APISettings.getCredentials(credentials[0].Name);
        
        System.assertEquals(credentials[0].Name, credential.Name, 'Credential name mismatch');
        
    }
    
    static testMethod void testGetAPIDetails(){
        Map<String, Global_API_Settings__mdt> apiMap = SBR_3_0_APISettings.getAPIMap();
        System.debug(apiMap);
        Global_API_Settings__mdt globalAPI = SBR_3_0_APISettings.getAPIDetails('AVS_Check');
        System.assertEquals(apiMap.get('AVS_Check'), globalAPI, 'API mismatch');
    }
    
    static testMethod void testApiDataClassConstructor(){
        Global_API_Settings__mdt globalAPI = SBR_3_0_APISettings.getAPIDetails('AVS_Check');
        List<Credential__c> credentials = SBR_3_0_TestDataFactory.createCredentials(1, true);
        Credential__c credential = SBR_3_0_APISettings.getCredentials(credentials[0].Name);
        SBR_3_0_APISettings.ApiData apiData = new SBR_3_0_APISettings.ApiData(globalAPI, credential);
    }
}