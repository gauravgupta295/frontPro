/*********************************************************************************************************************
* Apex Class: SBR_3_0_CustomMetadata_DA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Concrete class for Accessing Custom Metadata records
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Hashem Abdul          2022-07-14            Initial version    
*********************************************************************************************************************/

public with sharing class SBR_3_0_CustomMetadata_DA implements SBR_3_0_CustomMetadata_DAInterface{
    public static List<Outbox_Record_Id_Config__mdt> getOutboxSettings(String objectName) {
        List<Outbox_Record_Id_Config__mdt> settings = new List<Outbox_Record_Id_Config__mdt>();
        settings = [
            SELECT Id, Object_Name__c, Record_Id_Name__c, IsActive__c, Related_Fields__c 
            FROM Outbox_Record_Id_Config__mdt 
            WHERE Object_Name__c =: objectName AND IsActive__c = true LIMIT 1
        ];
        return settings;
    }

    public static API_ATP_Config__mdt getATPApiConfig(String configName){
        return API_ATP_Config__mdt.getInstance(configName);
    }
}