/*********************************************************************************************************************
* Apex Class: SBR_3_0_CustomMetadata_DAInterface
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Interface class for Custom Metadata Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Hashem Abdul          2022-07-14            Initial version 
    1.1         Hashem Abdul          2023-05-26            Added getATPApiConfig 
*********************************************************************************************************************/
public interface SBR_3_0_CustomMetadata_DAInterface {
    List<Outbox_Record_Id_Config__mdt> getOutboxSettings(String objectName);
    API_ATP_Config__mdt getATPApiConfig(String configName);
}