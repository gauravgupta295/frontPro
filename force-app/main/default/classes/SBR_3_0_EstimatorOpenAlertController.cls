public with sharing class SBR_3_0_EstimatorOpenAlertController {

    @AuraEnabled(cacheable=true)
    public static Decimal getEstimatorOpenDays(Id woOrDERecordId) {
        String openStatus = 'OPEN';
        String damageEstimatorRecQuery = 'SELECT Id, SF_PS_Estimator_Open_Days__c FROM SF_PS_Damage_Estimator__c WHERE SF_PS_Status__c =: openStatus';

        if(String.valueOf(woOrDERecordId).startsWith('0WO')) {
            damageEstimatorRecQuery += ' AND SF_PS_Work_Order_Number__c =: woOrDERecordId';
        }
        else {
            damageEstimatorRecQuery += ' AND Id =: woOrDERecordId';
        }
        List<SF_PS_Damage_Estimator__c> retrievedDamageEstimatorList = 
                                        (List<SF_PS_Damage_Estimator__c>)Database.query(String.escapeSingleQuotes(damageEstimatorRecQuery));
        if(!retrievedDamageEstimatorList.isEmpty()) {
            return retrievedDamageEstimatorList.get(0).SF_PS_Estimator_Open_Days__c;
        }
        return null;
    }
}