/********************************************************************************************************************************************
* Apex Class: SBR_3_0_PublishRecordsToOutbox
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to publish records to Outbox object without querying for the most up to date values
* - Allows for sending data that doesn't completely match what's in the database when required
* - Only fields passed to the constructor will be passed to the Outbox object
* - Based heavily on SBR_3_0_PublishRecordsToOutbox
* - Currently does not implement anything with the Related_Fields__c field
----------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                    DATE              DETAIL FEATURES
    1.0         Evan Kuminski (Salesforce)        2023-08-18        Initial version
    2.0         Evan Kuminski (Salesforce)        2023-10-05        Updated so that all Outboxes for a transaction
                                                                    can be created with a single DML statement
    3.0         Evan Kuminski (Salesforce)        2023-10-19        Can now override the value for Record_Type_Name__c
                                                                    Moved a few constants here to have them in a single location
    4.0         Chhavi Singhal (Salesforce)       2023-11-20        Can now override the value for Object API Name and modified 
                                                                    generateMapsFromSObjects() method
*********************************************************************************************************************************************/

public with sharing class SBR_3_0_PublishToOutboxWithoutQuery {
    private List<SObject> sObjs;
    @TestVisible private SObjectType sObjType;
    private Set<SObjectField> additionalMatchingFields;
    private List<Map<String, Object>> mapsForOutboxGeneration;
    private String recordSourceOfUpdate;
    private String recordTypeOverride;
    private String objectAPINameOverride;
    private Map<Id,String> recordTypeIdsToName;

    private static final String SOURCE_OF_UPDATE = 'Source_Of_Update__c';

    private static List<Outbox__c> outboxesToUpsert = new List<Outbox__c>();

    public static final String CREATE_RECORD_SOURCE_OF_UPDATE = 'C';
    public static final String UPDATE_RECORD_SOURCE_OF_UPDATE = 'U';
    public static final String DELETE_RECORD_SOURCE_OF_UPDATE = 'D';

    // additionalMatchingFields is a set of fields that must match in addition to the recordId in order for an existing
    // Outbox record to be considered a match when checking for Outbox records to update
    public SBR_3_0_PublishToOutboxWithoutQuery(
            List<SObject> sObjs, SObjectType sObjType, Set<SObjectField> additionalMatchingFields, String recordSourceOrUpdate
    ) {
        try {
            this.sObjs = sObjs;
            this.sObjType = sObjType;
            this.additionalMatchingFields = additionalMatchingFields;
            this.recordTypeIdsToName = SBR_3_0_RecordTypesForObject.getRecordTypeIdsToName(String.valueOf(this.sObjType));
            this.recordSourceOfUpdate = recordSourceOrUpdate;
        } catch (Exception ex) {
            System.debug(ex.getStackTraceString());
            System.debug(ex.getMessage());
            throw ex;
        }
    }

    public SBR_3_0_PublishToOutboxWithoutQuery(List<SObject> sObjs, SObjectType sObjType) {
        this(sObjs, sObjType, new Set<SObjectField>(), null);
    }


    public SBR_3_0_PublishToOutboxWithoutQuery(
            List<SObject> sObjs, String sObjType, Set<SObjectField> additionalMatchingFields, String recordSourceOrUpdate
    ) {
        this(sObjs, Schema.getGlobalDescribe().get(sObjType), additionalMatchingFields, recordSourceOrUpdate);
    }

    public SBR_3_0_PublishToOutboxWithoutQuery(List<SObject> sObjs, String sObjType) {
        this(sObjs, Schema.getGlobalDescribe().get(sObjType), new Set<SObjectField>(), null);
    }

    public void stageOutboxChanges() {
        if(this.sObjs.isEmpty()) {
            return;
        }
        generateMapsFromSObjects();
        Map<Id, List<OutboxWrapper>> potentialMatchesBySObjId = findPotentialOutboxMatches();
        for (Map<String, Object> sObjMap : this.mapsForOutboxGeneration) {
            Id sObjId = (Id)sObjMap.get('Id');
            Outbox__c existingOutbox;
            if(potentialMatchesBySObjId.containsKey(sObjId)) {
                existingOutbox = findExistingOutbox(sObjMap, potentialMatchesBySObjId.get(sObjId));
            }
            if(existingOutbox == null) {
                SBR_3_0_PublishToOutboxWithoutQuery.outboxesToUpsert.add(getOutboxForInsert(sObjMap, this.sObjType));
            } else {
                Outbox__c outboxForUpdate = getOutboxForUpdate(sObjMap, this.sObjType, existingOutbox.Id);
                if(outboxForUpdate.Record_JSON__c != existingOutbox.Record_JSON__c) {
                    SBR_3_0_PublishToOutboxWithoutQuery.outboxesToUpsert.add(getOutboxForUpdate(sObjMap, this.sObjType, existingOutbox.Id));
                }
            }
        }
    }

    public void setRecordSourceOfUpdate(String recordSourceOfUpdate) {
        this.recordSourceOfUpdate = recordSourceOfUpdate;
    }

    public void setRecordTypeOverride(String recordType) {
        this.recordTypeOverride = recordType;
    }
    
    public void setObjectAPINameOverride(String objectAPIName) {
        this.objectAPINameOverride = objectAPIName;
    }

    public static void publishAllOutboxes() {
        if(!outboxesToUpsert.isEmpty()) {
            upsert outboxesToUpsert;
            outboxesToUpsert.clear();
        }
    }

    private void generateMapsFromSObjects() {
        /* Maps will be used for generating the JSON data instead of directly using SObjects because there doesn't
           appear to be a way to clear a field on an SObject that keeps it out of the resulting JSON. */
		// Get field names filtering out long text area
        List<String> filteredFieldNames = new List<String>();
        for (SObjectField sObjField : this.sObjType.getDescribe().fields.getMap().values()) {
            //Includes all non-null fields except long text fields
            if(sObjField.getDescribe().isFilterable()) {
                filteredFieldNames.add(String.valueOf(sObjField));
            }
        }
        
        this.mapsForOutboxGeneration = new List<Map<String, Object>>();
        for (SObject sObj : this.sObjs) {
            Map<String, Object> fieldsToValueObjMap = sObj.getPopulatedFieldsAsMap(); //non-null values
            Map<String, Object> fieldsToValueObjMapForOutbox = new Map<String, Object>(); //Final Map
    
            //get all the non-null values and put in the fieldsToValueObjMapForOutbox map (doesn't include long text area)
            for(String fieldName: filteredFieldNames) {   
                if(!(fieldsToValueObjMap.get(fieldName) instanceof SObject) && fieldsToValueObjMap.get(fieldName) != null)       
                    fieldsToValueObjMapForOutbox.put(fieldName, fieldsToValueObjMap.get(fieldName));
            }   
            this.mapsForOutboxGeneration.add(fieldsToValueObjMapForOutbox);
        }
    }

    private Map<Id, List<OutboxWrapper>> findPotentialOutboxMatches() {
        Set<Id> recordIds = new Set<Id>();
        for (SObject sObj : this.sObjs) {
            recordIds.add(sObj.Id);
        }
        List<Outbox__c> outboxes = [
                SELECT
                        Id, Record_Id__c, Record_JSON__c
                FROM
                        Outbox__c
                WHERE
                        Record_Id__c IN :recordIds AND
                        Publish_Status__c = 'N'
                ORDER BY
                        CreatedDate DESC
        ];
        Map<Id, List<OutboxWrapper>> results = new Map<Id, List<OutboxWrapper>>();
        for (Outbox__c outbox : outboxes) {
            if(results.containsKey(outbox.Record_Id__c)) {
                results.get(outbox.Record_Id__c).add(new OutboxWrapper(outbox));
            } else {
                results.put(outbox.Record_Id__c, new List<OutboxWrapper>{new OutboxWrapper(outbox)});
            }
        }
        return results;
    }

    private Outbox__c getOutboxForInsert(Map<String, Object> sObjMap, SObjectType sObjType) {
        Outbox__c result = new Outbox__c(
                Record_JSON__c = JSON.serialize(sObjMap),
                Record_Id__c = (Id)sObjMap.get('Id'),
                Record_Last_Modified__c = (Datetime)sObjMap.get('LastModifiedDate')
        );

        if(String.isNotBlank(this.objectAPINameOverride)) {
            result.Object_API_Name__c = this.objectAPINameOverride;
        } else {
            result.Object_API_Name__c = String.valueOf(this.sObjType);
        }
        
        if(String.isNotBlank(this.recordSourceOfUpdate)) {
            result.Record_Source_Of_Update__c = this.recordSourceOfUpdate;
        } else if(sObjMap.containsKey(SOURCE_OF_UPDATE)) {
            result.Record_Source_Of_Update__c = (String)sObjMap.get(SOURCE_OF_UPDATE);
        } else {
            result.Record_Source_Of_Update__c = '';
        }

        if(String.isNotBlank(this.recordTypeOverride)) {
            result.Record_Type_Name__c = this.recordTypeOverride;
        } else if(this.recordTypeIdsToName?.containsKey((Id)sObjMap.get('RecordTypeId')) == true) {
            result.Record_Type_Name__c = this.recordTypeIdsToName.get((Id)sObjMap.get('RecordTypeId'));
        } else {
            result.Record_Type_Name__c = String.valueOf(this.sObjType);
        }

        return result;
    }

    private Outbox__c getOutboxForUpdate(Map<String, Object> sObjMap, SObjectType sObjType, Id existingOutboxId) {
        Outbox__c result = getOutboxForInsert(sObjMap, sObjType);
        result.Id = existingOutboxId;
        return result;
    }

    private Outbox__c findExistingOutbox(Map<String, Object> sObjMap, List<OutboxWrapper> potentialMatches) {
        Outbox__c existingOutbox;
        if(this.additionalMatchingFields.isEmpty()) {
            existingOutbox = potentialMatches[0].record;
        } else {
            for (OutboxWrapper outboxWrapper : potentialMatches) {
                Boolean allFieldsMatch = true;
                for (SObjectField additionalMatchingField : additionalMatchingFields) {
                    if(outboxWrapper.parsedJSON.get(String.valueOf(additionalMatchingField)) != sObjMap.get(String.valueOf(additionalMatchingField))) {
                        allFieldsMatch = false;
                        break;
                    }
                }
                if(allFieldsMatch) {
                    existingOutbox = outboxWrapper.record;
                    break;
                }
            }
        }
        return existingOutbox;
    }

    private class OutboxWrapper {
        Outbox__c record;
        Map<String, Object> parsedJSON;

        OutboxWrapper(Outbox__c record) {
            this.record = record;
            this.parsedJSON = (Map<String, Object>)JSON.deserializeUntyped(record.Record_JSON__c);
        }
    }
}