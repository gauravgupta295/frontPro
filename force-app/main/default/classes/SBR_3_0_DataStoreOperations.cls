/*********************************************************************************************************************
* Apex Class: SBR_3_0_DataStoreOperations
---------------------------------------------------------------------------------------------------------------------------------------
* @description Class to manage any insert/updates that needs to be done on Data_Store__c as part of trigger 
--------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Soomjeet Sahoo         2024-04-30          Initial version

*********************************************************************************************************************/
// @SuppressWarnings('PMD.ExcessiveClassLength, PMD.CyclomaticComplexity')
public with sharing class SBR_3_0_DataStoreOperations {
  public static final Long FIELD_SIZE_LIMIT = 131062; // Reduced from 131072 to 131062 for giving buffer of some characters

  private static Map<String, String> sObjectAPINameToSOQLStringMap = new Map<String, String>();
  private static Map<Id, sObject> entityIdTosObjectRecordMap = new Map<Id, sObject>();
  private static Map<String, Set<String>> sObjectAPINameWithEntityIdSetMap = new Map<String, Set<String>>();
  private static Map<Id, String> entityIdTosObjectAPINameMap = new Map<Id, String>();

  private static List<String> triggerHandlersToByPass = new List<String>{
    'SBR_3_0_OrderTriggerHandler',
    'SBR_3_0_QuoteTriggerHandler',
    'SBR_3_0_OrderItemTriggerHandler',
    'SBR_3_0_QuoteLineTriggerHandler'
  };

  /**
   * @description : Data Store Entry Logic
   * @author soomjeet.sahoo | 05-02-2024
   * @param evtList
   **/
  public static void initiateDataStoreEntries(
    List<SBR_3_0_Data_Store_Staging_Event__e> evtList
  ) {
    List<Data_Store__c> dataStoreRecordsToBeInserted = new List<Data_Store__c>();
    // Update sObjectAPINameWithEntityIdSetMap with sObjectAPIName and EntityIds with similar sObjectType
    for (SBR_3_0_Data_Store_Staging_Event__e evt : evtList) {
      String entityId = evt.Staging_Record_Id__c;
      String sObjectAPIName = !String.isBlank(evt.Object_API_Name__c)
        ? evt.Object_API_Name__c
        : getsObjectAPINameFromEntityId(entityId);

      sObjectAPINameWithEntityIdSetMap.putAll(
        SBR_3_0_DataStoreUtility.updateSObjectAPINameWithEntityIdSetMap(
          entityId,
          sObjectAPIName
        )
      );
      entityIdTosObjectAPINameMap.put(Id.ValueOf(entityId), sObjectAPIName);
    }

    deleteRelatedDataStoreEntries(entityIdTosObjectAPINameMap.keySet());

    //Creating Map of sObject API Names and comma separated non-formula fields
    sObjectAPINameToSOQLStringMap = SBR_3_0_DataStoreUtility.formulateSOQLStringMap(
      sObjectAPINameWithEntityIdSetMap.keySet()
    );

    //Querying for each sObject Entries one by one to make sure all the records are queried irrespective of their object type.
    for (String sObjectAPIName : sObjectAPINameToSOQLStringMap.KeySet()) {
      entityIdTosObjectRecordMap.putAll(
        SBR_3_0_DataStoreUtility.createEntityIdTosObjectRecordEntries(
          sObjectAPINameToSOQLStringMap.get(sObjectAPIName),
          'Id IN: entityIdSet',
          sObjectAPINameWithEntityIdSetMap.get(sObjectAPIName)
        )
      );
    }

    for (String objRecordId : entityIdTosObjectRecordMap.KeySet()) {
      dataStoreRecordsToBeInserted.add(createDataStoreInstance(objRecordId));
    }

    Database.upsert(
      dataStoreRecordsToBeInserted,
      Data_Store__c.Fields.Entity_Id__c,
      true,
      System.AccessLevel.SYSTEM_MODE
    );

    List<Data_Store__c> childDataStores = SBR_3_0_DataStoreUtility.createChildDataStoresList(
      dataStoreRecordsToBeInserted
    );

    Database.upsert(
      childDataStores,
      Data_Store__c.Fields.Entity_Id__c,
      true,
      System.AccessLevel.SYSTEM_MODE
    );
  }

  /**
   * @description
   * @author soomjeet.sahoo | 05-07-2024
   * @param externalIds
   **/
  public static void updateEntityFromDataStore(List<String> externalIds) {
    List<sObject> sObjectListToBeUpsertedForChilds = buildEntityRecordList(
      externalIds,
      true
    );

    setByPassTriggerHandlers();

    if (!sObjectListToBeUpsertedForChilds.isEmpty()) {
      Database.update(
        sObjectListToBeUpsertedForChilds,
        true,
        System.AccessLevel.SYSTEM_MODE
      );
    }

    List<sObject> sObjectListToBeUpsertedForParents = buildEntityRecordList(
      externalIds,
      false
    );

    Database.update(
      sObjectListToBeUpsertedForParents,
      true,
      System.AccessLevel.SYSTEM_MODE
    );
  }

  /**
   * @description : build Entity Records List for operation
   * @author soomjeet.sahoo | 05-09-2024
   * @param recordIds
   * @param isChildEntitiesRequired
   * @return List<sObject>
   **/
  public static List<sObject> buildEntityRecordList(
    List<String> recordIds,
    Boolean isChildEntitiesRequired
  ) {
    List<Data_Store__c> dataStoreRecords = SBR_3_0_DataStoreUtility.getAllDataStores(
      recordIds,
      isChildEntitiesRequired
    );
    Map<String, String> sObjectId2SerializedRecordMap = new Map<String, String>();
    Map<String, String> sObjectId2sObjectAPINameMap = new Map<String, String>();
    List<sObject> sObjectListToBeUpserted = new List<sObject>();
    for (Data_Store__c dataStoreRecord : dataStoreRecords) {
      //Storing EntityId With DataStore Serialised
      sObjectId2SerializedRecordMap.put(
        dataStoreRecord.Entity_Id__c,
        SBR_3_0_DataStoreUtility.getBackupEntityFromDataStore(dataStoreRecord)
      );

      sObjectId2sObjectAPINameMap.put(
        dataStoreRecord.Entity_Id__c,
        dataStoreRecord.Object_API_Name__c
      );
    }

    for (String objRecordId : sObjectId2sObjectAPINameMap.keySet()) {
      if (sObjectId2SerializedRecordMap.containsKey(objRecordId)) {
        String serializedRecord = sObjectId2SerializedRecordMap.get(
          objRecordId
        );

        System.Type sObjTypeInstance = Type.forName(
          sObjectId2sObjectAPINameMap.get(objRecordId)
        );

        sObjectListToBeUpserted.add(
          (sObject) JSON.deserialize(serializedRecord, sObjTypeInstance)
        );
      }
    }
    return sObjectListToBeUpserted;
  }

  /**
   * @description : Creates List<String> from comma separated string supplied
   * @author soomjeet.sahoo | 05-06-2024
   * @param commaSeparatedStrings
   * @return List<String>
   **/
  public static List<String> convertCommaSeparatedStringIntoStringList(
    String commaSeparatedStrings
  ) {
    return !String.isBlank(commaSeparatedStrings)
      ? commaSeparatedStrings.toLowerCase().split(',')
      : new List<String>();
  }

  /**
   * @description : Gets sObject API Name from the given Entity Id
   * @author soomjeet.sahoo | 04-29-2024
   * @param entityId
   * @return String
   **/
  private static String getsObjectAPINameFromEntityId(String entityId) {
    return Id.valueOf(entityId).getSObjectType().getDescribe().getName();
  }

  /**
   * @description : Creates an instance of sObject with the given record properties
   * and sObject API Name
   * @author soomjeet.sahoo | 07-02-2024
   * @param recordProps
   * @param sObjectAPIName
   * @return sObject
   **/
  private static sObject getsObjectInstanceWithGivensObjectName(
    Map<String, Object> recordProps,
    String sObjectAPIName
  ) {
    sObject sObj = (SObject) Type.forName(sObjectAPIName).newInstance();
    for (String field : recordProps.keySet()) {
      sObj.put(field, recordProps.get(field));
    }
    return sObj;
  }

  /**
   * @description : Makes the sObject map from sObject List
   * @author soomjeet.sahoo | 07-02-2024
   * @param sObjectList
   * @return Map<Id, sObject>
   **/
  private static Map<Id, sObject> createsObjectMapFromsObjectList(
    List<sObject> sObjectList
  ) {
    Map<Id, sObject> sObjectMap = new Map<Id, sObject>();
    for (sObject record : sObjectList) {
      sObjectMap.put(record.Id, record);
    }
    return sObjectMap;
  }

  /**
   * @description : Creates DataStore Record Instance with given entity Id
   * @author soomjeet.sahoo | 05-02-2024
   * @param entityId
   * @return Data_Store__c
   **/
  private static Data_Store__c createDataStoreInstance(String entityId) {
    String sObjectApiName = entityIdTosObjectAPINameMap.get(entityId);
    Map<String, String> dataStoreInstanceMap = SBR_3_0_DataStoreUtility.dataStoreInstanceMapWithGivenRecord(
      entityIdTosObjectRecordMap.get(entityId),
      Integer.valueOf(FIELD_SIZE_LIMIT)
    );
    dataStoreInstanceMap.put('Entity_Id__c', entityId);
    dataStoreInstanceMap.put('Object_API_Name__c', sObjectApiName);

    return (Data_Store__c) JSON.deserialize(
      JSON.serialize(dataStoreInstanceMap),
      Data_Store__c.class
    );
  }

  /**
   * @description : used to set Bypass trigger context
   * @author soomjeet.sahoo | 05-07-2024
   **/
  @testVisible
  private static void setByPassTriggerHandlers() {
    for (String triggerHandler : triggerHandlersToByPass) {
      SBR_3_0_TriggerHandler.bypass(triggerHandler);
    }
  }

  /**
   * @description : deletes the related data store entries passed
   * @author soomjeet.sahoo | 07-12-2024
   * @param entityIds
   **/
  public static void deleteRelatedDataStoreEntries(Set<Id> entityIds) {
    String dataStoreQuery =
      SBR_3_0_DataStoreUtility.createSOQLStringForGivensObjectAPIName(
        'Data_Store__c',
        'Id'
      ) +
      ' WHERE Entity_Id__c IN: entityId OR Parent_Data_Store__r.Entity_Id__c IN: entityId';

    List<Data_Store__c> dataStoreRecordsToBeDeletedList = Database.queryWithBinds(
      dataStoreQuery,
      new Map<String, Object>{ 'entityId' => entityIds },
      System.AccessLevel.SYSTEM_MODE
    );

    Database.delete(
      dataStoreRecordsToBeDeletedList,
      System.AccessLevel.SYSTEM_MODE
    );
  }
}