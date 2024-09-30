/*********************************************************************************************************************
* Apex Class: SBR_3_0_PublishRecordsToOutbox
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to publish records to Outbox object
* - SAL-473
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Harry Rokad, Viren Patel           2022-03-15            Initial version
    1.1         Hashem Abdul                       2022-07-14            Get Dynamic External Record Id field from custom metadata (SAL-4692)
*********************************************************************************************************************/
public without sharing class SBR_3_0_PublishRecordsToOutbox {

    private Map<Id,Sobject> idsToSobject;
    private String sObjType;
    private String recordSourceOfUpdate; // SAL-19740 - Hashem A - 5/15/2023
    private Map<Id,String> recordTypeIdsToName;
    private set<String> validRecTypes;
    private List<Outbox_Record_Id_Config__mdt> outboxSettings;

    private static final String RECORD_TYPE_ID = 'RecordTypeId';
    private static final String SOURCE_OF_UPDATE = 'Source_Of_Update__c';
    private static final String LAST_MODIFIED_DATE = 'LastModifiedDate';

    private List<String> apiLongTextAreasFields = new List<String>();

    public SBR_3_0_PublishRecordsToOutbox(Map<Id,Sobject> idsToSobject, String sObjType) {
        this(idsToSobject, sObjType, new Set<String>{''});
    }

    public SBR_3_0_PublishRecordsToOutbox(Map<Id,Sobject> idsToSobject, String sObjType, Set<String> validRecTypes) {
        try {
            this.sObjType = sObjType;
            this.idsToSobject = new Map<Id,Sobject>();
            this.idsToSobject.putAll(idsToSobject);
            this.sObjType = sObjType;
            this.validRecTypes = validRecTypes;
            this.recordTypeIdsToName = SBR_3_0_RecordTypesForObject.getRecordTypeIdsToName(this.sObjType);
            this.outboxSettings = SBR_3_0_CustomMetadata_DA.getOutboxSettings(this.sObjType);
        } catch (Exception ex) {
            system.debug(ex.getStackTraceString());
            system.debug(ex.getMessage());
            throw ex;
        }
    }
    
    //For Comment_c, include long text area fields
    public SBR_3_0_PublishRecordsToOutbox(Map<Id,Sobject> idsToSobject, String sObjType, Set<String> validRecTypes, List<String> apiLongTextAreas) {
        try {
            this(idsToSobject,sObjType,validRecTypes);
            this.apiLongTextAreasFields.addAll(apiLongTextAreas);
        } catch (Exception ex) {
            system.debug(ex.getStackTraceString());
            system.debug(ex.getMessage());
            throw ex;
        }
    }


    // SAL-19740 - Hashem A - 5/15/2023
    public void setRecordSourceOfUpdate(String srcOfUptValue){
        this.recordSourceOfUpdate = srcOfUptValue;
    }

    public void publish() {
        try {

            // Get field names filtering out long text area
            List<String> filteredFieldNames = getFilteredFieldNames(); 

            //Get Records for Object fields
            List<SObject> records = getObjectRecords(filteredFieldNames);

            //Get Records for Related fields
            Map<Id,SObject> relatedRecords = new Map<Id,SObject> (getRelatedRecords());

            //List<Outbox__c> publish = new List<Outbox__c>();
            Map<String, Outbox__c> publish = new Map<String, Outbox__c>();

            Set<String> ids = new Set<String>();  // record Ids or external Ids

            for (SObject s: records) {
                Map<String, Object> fieldsToValueObjMap = s.getPopulatedFieldsAsMap(); //non-null values
                Map<string,string> fieldsToValue= new Map<string,string>();

                //get all the non-null values and put in the fieldsToValue map (does this include long text area???-test)
                for(String strKey: fieldsToValueObjMap.keyset()) {           
                    fieldsToValue.put(strKey, String.valueof(fieldsToValueObjMap.get(strKey)));
                }   

                //get all fields that are needed (filteredFieldNames), and put blank for null values in the map
                for(String fieldName : filteredFieldNames) {
                    if(!fieldsToValueObjMap.containsKey(fieldName)) {
                        fieldsToValue.put(String.valueOf(fieldName),'');
                    }
                } 

                String jsonRecord = JSON.serialize(fieldsToValue);
                Map<String, Object> recObjUntyped = (Map<String, Object>) JSON.deserializeUntyped(jsonRecord);
                String sourceOfUpdate = '';

                if(String.isNotBlank(recordSourceOfUpdate)){
                    sourceOfUpdate = recordSourceOfUpdate; // SAL-19740 - Hashem A - 5/15/2023
                } else {
                    //Get Source of Update value = this is SF when record is modified by internal SF users
                    sourceOfUpdate = filteredFieldNames.contains(SOURCE_OF_UPDATE) ? (String)s.get(SOURCE_OF_UPDATE) : '';
                }

                //get External ID field name & value
                String extIdName = getExternalIdForObject();
                String extIdValue = filteredFieldNames.contains(extIdName) ? (String)s.get(extIdName) : null;

                //Create record to publish
                Outbox__c ob = new Outbox__c();
                ob.Record_JSON__c = jsonRecord;
                ob.Object_API_Name__c = this.sObjType;
                //ob.Record_Id__c =(extIdValue!=null) ? extIdValue : s.Id; // Record Id is External Id specified in Custom Metadata, otherwise it's the SF Record Id
                ob.Record_Id__c = s.Id;
                ob.Record_Type_Name__c = getRecordTypeName(s); 
                ob.Record_Last_Modified__c = (DateTime)s.get(LAST_MODIFIED_DATE);
                ob.Record_Source_Of_Update__c = sourceOfUpdate;
                ob.Related_Data__c = getRelatedFieldsJSON(relatedRecords.get(s.Id));

                //publish.add(ob);
                ids.add(ob.Record_Id__c);
                publish.put(ob.Record_Id__c, ob);
                
            }
            //Publish record to Outbox__c
            //if the external Id in the outbox is not in published status, then update
            //otherwise insert a new record
            Map<String,String> existingIds = hasExistingUnpublishedRecord(ids);
            
            List<Outbox__c> toInsert = new List<Outbox__c>() ;
            List<Outbox__c> toUpdate = new List<Outbox__c>() ;

            for(String id : publish.keySet()) {
                if(existingIds.containsKey(id)) {
                    Outbox__c ob = publish.get(id);
                    ob.id = existingIds.get(id); 
                    toUpdate.add(ob);
                }
                else {
                    toInsert.add(publish.get(id));
                }
            }
           
            if(toUpdate.size()>0) {
                update toUpdate;
            }

            if(toInsert.size()>0) {
                insert toInsert;
            }
            
        } catch (Exception ex) {
            system.debug('Error in Publish: ');
            system.debug(ex.getStackTraceString());
            system.debug(ex.getMessage());
            throw ex;
        }
    }

    //get list of filtered field names excluding unwanted field types
    private List<String> getFilteredFieldNames() {
        
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get(this.sObjType);
        Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();

        //Filetered list 
        List<String> filteredFieldNames = new list<String>(); 
        //get all the fields Names for Account Object
        for (Schema.SObjectField fname: fieldMap.values()){
            String fieldName =  String.valueOf(fname);
            Schema.DisplayType fielddataType = fieldMap.get(fieldName).getDescribe().getType();
            if (
                fieldMap.get(fieldName).getDescribe().isFilterable()|| this.apiLongTextAreasFields.contains(fieldName)
                 // ensures no long text area field is added or also include any specified/required long text area fields
            ) 
            {
                    filteredFieldNames.add(fieldName);
            }
        }
        System.debug('Total fields'+filteredFieldNames.size());
        return filteredFieldNames;
    }

    private String getExternalIdForObject() {
        if(!this.outboxSettings.IsEmpty() ){
            return outboxSettings[0].Record_Id_Name__c;
        }
        return null;
    }

    private String getRecordTypeName(SObject record) {
        //System.debug('\n vp - recordTypeIdsToName ' + recordTypeIdsToName);
        try{
            String rtId = (String)record.get('RecordTypeId');
            if( String.IsNotBlank(rtId) && 
                recordTypeIdsToName!=null && 
                !recordTypeIdsToName.isEmpty() && 
                recordTypeIdsToName.containsKey(rtId)) {
                    return recordTypeIdsToName.get(rtId);
                }
            }
        catch (Exception ex) {
            //recordtypeId field may not exist for objects which may not be 
            return this.sObjType;
        }    
        return this.sObjType;
    }

    private List<SObject> getObjectRecords(List<String> filteredFieldNames) {
        List<Id> recIds = new List<Id>(idsToSobject.keySet());
        String query=
                ' SELECT ' 
                + String.escapeSingleQuotes(String.join(filteredFieldNames, ',' )) 
                +' FROM '+ String.escapeSingleQuotes(this.sObjType) 
                +' WHERE'+' id IN :recIds ';
        return Database.query(query);
    } 

    private List<SObject> getRelatedRecords() {
        String relatedFields = getRelatedFieldsForObject();
        if(!String.IsBlank(relatedFields)) {
            List<Id> recIds = new List<Id>(idsToSobject.keySet());
            System.debug('\n vp = getRelatedFieldsForObject' + relatedFields) ;
            String query=
                    ' SELECT ' 
                    + String.escapeSingleQuotes(relatedFields) //add any related fields specified in the custom metadata for the object
                    +' FROM '+ String.escapeSingleQuotes(this.sObjType) 
                    +' WHERE'+' id IN :recIds ';
            return Database.query(query);
        }
        return new List<SObject>();
    }

    private String getRelatedFieldsJSON(SObject s) {
        String relatedFields = getRelatedFieldsForObject();
        if(!String.IsBlank(relatedFields)) {
            List<String> relatedFldList = relatedFields.split(',');
            System.debug('\nvp: relatedFlList = ' + relatedFldList);
            Map<String, String> relatedMap = new Map<String, String>();
            
            for(String fld : relatedFldList) {
                List<String> objAndFldName = new List<String>();
                objAndFldName = fld.split('\\.');
                if(!objAndFldName.IsEmpty() && objAndFldName.size()==2) {
                    try {
                        String val = String.valueOf(s.getSobject(objAndFldName[0].trim()).get(objAndFldName[1].trim()));
                    if( !String.IsBlank(val) ) {
                        relatedMap.put(objAndFldName[1].trim(), val);
                    } 
                    else {
                        relatedMap.put(objAndFldName[1].trim(), '');
                    }
                }
                    catch (Exception ex) {
                        //do nothing for now;
                        System.debug('\n failed objAndFldName = ' + objAndFldName);
                    }
                }
            }
            return JSON.Serialize(relatedMap);
        }
        return '';
    }

    private String getRelatedFieldsForObject() {
        //System.debug('\n outboxSettings = ' + outboxSettings);
        if(!this.outboxSettings.IsEmpty() && !String.IsBlank(this.outboxSettings[0].Related_Fields__c) ){
            System.debug('\n vp related Fields = ' + outboxSettings[0].Related_Fields__c);
            return outboxSettings[0].Related_Fields__c;
        }
        return '';
    }

    private Map<String,String> hasExistingUnpublishedRecord(Set<String> ids) {
        List<Outbox__c> recs = new List<Outbox__c>();
        Map<String,String> existing = new Map<String,String>();
        recs = [SELECT Id, Record_Id__c from Outbox__c WHERE Record_Id__c IN :ids AND Publish_Status__c = 'N' Order by CreatedDate Desc];
        for(Outbox__c o : recs) {
            existing.put(o.Record_Id__c, o.Id);
        }
        return existing;
    }
}