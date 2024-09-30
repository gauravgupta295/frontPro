/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_FetchInventoryAtBranch
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Fetch Inventory at a specific Branch for all the Products
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Viren Patel          2022-09-06             Initial version    
*********************************************************************************************************************/
public with sharing class SBR_3_0_API_FetchInventoryAtBranch {
    private static final String APINAME = 'InventoryAtBranch_API';

    @AuraEnabled
    public static SBR_3_0_WrapInventoryAtBranch.ATPResponse getInventoryAtBranch(SBR_3_0_WrapInventoryAtBranch.ATPRequest req, String companyId){

        String resp = SBR_3_0_Generic_Callout.callEndpoint(JSON.serialize(req), APINAME, companyId);
        if(String.IsNotBlank(resp)){
            SBR_3_0_WrapInventoryAtBranch.ATPResponse realResponse = new SBR_3_0_WrapInventoryAtBranch.ATPResponse();
            system.debug('REAL' + resp);
            Map<String, Object> response = (Map<String,Object>) JSON.deserializeUntyped(resp);
            String test = JSON.serialize(response.get('data'));
            if(!test.contains('NO_INVENTORY_AVAILABLE')){
                return (SBR_3_0_WrapInventoryAtBranch.ATPResponse) JSON.deserialize(test,SBR_3_0_WrapInventoryAtBranch.ATPResponse.class);
            }
            else{
                return null;
            }
        }
        return null;
    }
}