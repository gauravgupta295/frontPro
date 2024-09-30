/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_Consumables
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Outbound Consumables API to get rates for items which are non-rentables
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Hashem Abdul          2022-05-25            Initial version    
*********************************************************************************************************************/

public with sharing class SBR_3_0_API_Consumables {
    private static final String APINAME = 'Consumables_API';

    @AuraEnabled
    public static String getConsumableRates(String requestJson, String companyId){
        String returnPayload = '';
        companyId = String.valueOf(Integer.valueOf(companyId));
        returnPayload = SBR_3_0_Generic_Callout.callEndpoint(requestJson, APINAME, companyId);
        return returnPayload;
    }
}