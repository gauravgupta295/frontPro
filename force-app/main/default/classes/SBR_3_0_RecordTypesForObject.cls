/*********************************************************************************************************************
* Apex Class: SBR_3_0_RecordTypesForObject
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to get a map of RecordType id's and its corresponding RecordType Names.
* - SAL-473
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION         DEVELOPER NAME                  DATE                DETAIL FEATURES
    1.0         Harry Rokad,Viren Patel           2022-03-15            Initial version    
*********************************************************************************************************************/

public with sharing class SBR_3_0_RecordTypesForObject {

    public static Map<Id,String> getRecordTypeIdsToName(String sObjType) {
        Map<Id,String> recordTypeIdsToName = new Map<Id,String> ();
        for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(sObjType).getDescribe().getRecordTypeInfosByName().values()){
            recordTypeIdsToName.put(recInfo.getRecordTypeId(),recInfo.getName());
        }
        //System.debug('\n rts =' + recordTypeIdsToName);
        return recordTypeIdsToName;
    }

    public static Map<String, Id> getRecordTypeNameToIds(String sObjType) {
        Map<String,Id> recordTypeNameToIds = new Map<String,Id>();
        for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(sObjType).getDescribe().getRecordTypeInfosByName().values()){
            recordTypeNameToIds.put(recInfo.getName(), recInfo.getRecordTypeId());
        }
        //System.debug('\n rts =' + recordTypeNameToIds);
        return recordTypeNameToIds;
    }
    public static Map<String, Id> getRecordTypeDevNameToIds(String sObjType) {
        Map<String,Id> recordTypeDevNameToIds = new Map<String,Id>();
        for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(sObjType).getDescribe().getRecordTypeInfosByName().values()){
            recordTypeDevNameToIds.put(recInfo.getDeveloperName(), recInfo.getRecordTypeId());
        }
        //System.debug('\n rts =' + recordTypeNameToIds);
        return recordTypeDevNameToIds;
    }
    
}