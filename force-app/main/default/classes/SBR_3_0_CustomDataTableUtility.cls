/*********************************************************************************************************************
 * Apex Class: CustomDataTableUtility
 *********************************************************************************************************************/
public with sharing class SBR_3_0_CustomDataTableUtility {
    /**
     * description       : getColumns from CustomDataTableCmpColumn metadata
     * author            : Arpita Agarwal
     * MethodName        : getColumns
     **/
    @AuraEnabled(cacheable=true)
    public static List<CustomDataTableCmpColumn__mdt> getColumns(String context) {
        return [
        SELECT
            ID,
            MasterLabel,
            Context__c,
            Label,
            Field_Name__c,
            fixedWidth__c,
            IsEditable__c,
            IsSortable__c,
            Order__c,
            Parent_Object__c,
            Type__c,
            Width_Unit__c
        FROM CustomDataTableCmpColumn__mdt
        WHERE Context__c = :context
        ];
    }
}