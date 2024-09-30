/*********************************************************************************************************************
* Apex Class: SBR_3_0_EqpMaintenanceStepDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Methods for accessing Eqp Maintenance Step records
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-10-19           Initial version
*********************************************************************************************************************/

public with sharing class SBR_3_0_EqpMaintenanceStepDA implements SBR_3_0_EqpMaintenanceStepDAI {
    public List<SM_PS_Eqp_Maintenance_Step__c> getAllFieldsByInspectionTemplateIds(Iterable<Id> inspectionTemplateIds) {
        return (List<SM_PS_Eqp_Maintenance_Step__c>)Database.query(
                String.format(
                        'SELECT {0} FROM {1} WHERE SM_PS_Inspection_Template__c IN :inspectionTemplateIds',
                        new List<Object>{getAllFieldsString(), SM_PS_Eqp_Maintenance_Step__c.SObjectType}
                )
        );
    }

    @TestVisible
    private static String getAllFieldsString() {
        List<SObjectField> fieldsList = SM_PS_Eqp_Maintenance_Step__c.SObjectType.getDescribe().fields.getMap().values();
        String fieldsString = '';
        for(Integer i = 0 ; i < fieldsList.size() - 1; i++) {
            fieldsString += fieldsList[i] + ',';
        }
        fieldsString += fieldsList[fieldsList.size() - 1];
        return fieldsString;
    }
}