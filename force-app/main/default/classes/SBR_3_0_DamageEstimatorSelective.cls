/*********************************************************************************************************************
* Apex Class: SBR_3_0_DamageEstimatorSelective
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - To query records of damage estimator from the database of salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Meghna Vijay          2023-01-18            Initial version
    2.0         Piyush Jindal         2024-01-30            Added SF_PS_Invoice_Number__c field in the SOQL
    3.0         Piyush Jindal         2024-02-22            Removing SF_PS_Invoice_Number__c and updating the SF_PS_Invoice__c and SF_PS_Invoice_Sequence_Number__c fields on Damage Estimator record
*********************************************************************************************************************/

public with sharing class SBR_3_0_DamageEstimatorSelective {

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Method to fetch Damage Estimator records
    * Params: damageEstimatorId 
    *********************************************************************************************************************/
    public static SF_PS_Damage_Estimator__c getDamageEstimatorById(String damageEstimatorId) {
        return [SELECT 
                    SF_PS_Work_Order_Number__r.SF_PS_RM_WO_Number__c, 
                    SF_PS_Work_Order_Number__r.ServiceTerritory.Branch_Location_Number__c,
                    SF_PS_Work_Order_Number__r.OwnerId,
                    SF_PS_Work_Order_Number__r.CreatedBy.alias, 
                    SF_PS_Work_Order_Number__r.LastModifiedDate,
                    SF_PS_Work_Order_Number__r.SF_PS_Company_Code__c,
                    SF_PS_Contract_Number__r.SM_PS_RM_Contract_Order_Number__c,
                    SF_PS_WO_Equipment_Number__r.SM_PS_Equipment_Number__c,
                    SF_PS_Estimator_Reason_Code__c,
                    SF_PS_Estimated_Completion__c, 
                    SF_PS_Estimated_Cost_Labor__c, 
                    SF_PS_Estimated_Cost_Labor_Hours__c,
                    SF_PS_Estimated_Cost_Misc__c, 
                    SF_PS_Estimated_Cost_Parts__c, 
                    SF_PS_PO_Number__c, 
                    SF_PS_Retail_Estimate_Cost_Labor__c, 
                    SF_PS_Retail_Estimate_Cost_Misc__c,
                    SF_PS_Retail_Estimate_Cost_Parts__c,
                    SF_PS_Estimate_Comment__c,
                    SF_PS_Invoice__c,
                    SF_PS_Invoice_Sequence_Number__c,
                    SF_PS_Status__c,
                    SF_PS_Invoice_Comment1__c,
                    SF_PS_Invoice_Comment2__c, 
                    SF_PS_Invoice_Comment3__c,
                    SF_PS_Duplicate_Estimator__c, 
                    SF_PS_Customer_is_Invoiced__c,
                    SF_PS_Apply_RPP_Coverage__c
            FROM SF_PS_Damage_Estimator__c 
            WHERE Id =:damageEstimatorId WITH SECURITY_ENFORCED
        ];
    }
}