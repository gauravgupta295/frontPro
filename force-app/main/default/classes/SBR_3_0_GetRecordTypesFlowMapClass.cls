/*********************************************************************************************************************
* Apex Class: SBR_3_0_GetRecordTypesFlowMapClass
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to create an apex-defined variable type for storing maps for SBR_3_0_Get_RecordType_ID_Subflow Flow
* - SAL-852
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Avinash Rao           2022-02-16            Initial version   
    2.0         Harry Rokad           2022-06-21            Commented out the constructor * Apex PMD *
*********************************************************************************************************************/
public without sharing class SBR_3_0_GetRecordTypesFlowMapClass {
    @AuraEnabled
    public string key; //Map key
    
    @AuraEnabled
    public string value; //Map value
    
    // public SBR_3_0_GetRecordTypesFlowMapClass(){}
}