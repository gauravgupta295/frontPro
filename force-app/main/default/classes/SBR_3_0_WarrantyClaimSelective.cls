/*********************************************************************************************************************
* Apex Class: SBR_3_0_DamageEstimatorSelective
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - To query records of work orer for warranty claim from the database of salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Meghna Vijay          2023-01-18            Initial version
*********************************************************************************************************************/

public with sharing class SBR_3_0_WarrantyClaimSelective {
     /*********************************************************************************************************************
    * Purpose/Methods:
    * Method to fetch Damage Estimator records
    * Params: damageEstimatorIdSet (Set<String>)
    *********************************************************************************************************************/
    public static WorkOrder getWOClaimFieldsById(String workOrderRecId) {
        return [SELECT SF_PS_Primary_Part_Number__c,SF_PS_Claim_Labor_Code__c,SF_PS_Claim_Comments1__c,
                SF_PS_Claim_Comments2__c,SF_PS_Claim_Comments3__c, SF_PS_RM_WO_Number__c,LastModifiedDate,
                SF_PS_Company_Code__c,OwnerId,ServiceTerritory.Branch_Location_Number__c,CreatedBy.alias,SF_PS_Claim_Num__c
                FROM WorkOrder 
                WHERE Id=: workOrderRecId
                WITH SECURITY_ENFORCED];
    }
}