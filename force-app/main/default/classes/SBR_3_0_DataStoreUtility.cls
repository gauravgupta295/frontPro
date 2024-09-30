/**
 * @description       : Utility class for SBR_3_0_DataStoreOperations
 * @author            : soomjeet.sahoo
 * @group             : salesforce.com
 * @last modified on  : 05-10-2024
 * @last modified by  : soomjeet.sahoo
 **/
public with sharing class SBR_3_0_DataStoreUtility {
  public static Map<String, String> sObjectPINameToRespectiveFieldsToIgnoreCustomLabelMap = new Map<String, String>{
    'Order' => System.Label.sbr_3_0_DataStoreByPassFieldsForOrder,
    'OrderItem' => System.Label.sbr_3_0_DataStoreByPassFieldsForOrderItem,
    'SBQQ__Quote__c' => System.Label.sbr_3_0_DataStoreByPassFieldsForQuote,
    'SBQQ__QuoteLine__c' => System.Label.sbr_3_0_DataStoreByPassFieldsForQuoteLineItem,
    'default' => System.Label.sbr_3_0_DataStoreByPassFieldsDefault
  };

  public static Map<String, String> parentsObjectAPINameToChildSObjectAPINameMap = new Map<String, String>{
    'Order' => 'OrderItem',
    'SBQQ__Quote__c' => 'SBQQ__QuoteLine__c'
  };

  public static Map<String, String> childsObjectAPINameToRelatedEntityFieldNameMap = new Map<String, String>{
    'OrderItem' => 'OrderId',
    'SBQQ__QuoteLine__c' => 'SBQQ__Quote__c'
  };

  /**
   * @description : Create Child Datastores
   * @author soomjeet.sahoo | 05-10-2024
   * @param dataStoreRecordsToBeInserted
   * @return List<Data_Store__c>
   **/
  public static List<Data_Store__c> createChildDataStoresList(
    List<Data_Store__c> dataStoreRecordsToBeInserted
  ) {
    Map<Id, Id> entityIdToDataStoreIdMap = new Map<Id, Id>();
    Map<Id, Data_Store__c> dataStoreIdToDataStoreRecordMap = new Map<Id, Data_Store__c>();
    Map<String, Set<String>> parentsObjectAPINameToRelatedEntityIds = new Map<String, Set<String>>();
    Map<String, String> childsObjectAPINamesToSOQLStringMap = new Map<String, String>();
    Map<Id, sObject> childEntityIdToEntityRecordMap = new Map<Id, sObject>();
    Map<String, String> reversedParentsObjectAPINameToChildSObjectAPINameMap = new Map<String, String>();
    Map<String, String> childEntityWithParentDataStoreIdMap = new Map<String, String>();
    List<Data_Store__c> childDataStoreRecordsToBeInserted = new List<Data_Store__c>();
    try {
      for (
        String sObjectAPIName : parentsObjectAPINameToChildSObjectAPINameMap.KeySet()
      ) {
        reversedParentsObjectAPINameToChildSObjectAPINameMap.put(
          parentsObjectAPINameToChildSObjectAPINameMap.get(sObjectAPIName),
          sObjectAPIName
        );
      }

      for (Data_Store__c dsVar : dataStoreRecordsToBeInserted) {
        dataStoreIdToDataStoreRecordMap.put(dsVar.Id, dsVar);
        if (
          dsVar.Id != null &&
          parentsObjectAPINameToChildSObjectAPINameMap.containsKey(
            dsVar.Object_API_Name__c
          )
        ) {
          entityIdToDataStoreIdMap.put(dsVar.Entity_Id__c, dsVar.Id);
          String childSObjectAPIName = parentsObjectAPINameToChildSObjectAPINameMap.get(
            dsVar.Object_API_Name__c
          );
          // System.debug('@@@@ childSObjectAPIName >> ' + childSObjectAPIName);
          childsObjectAPINamesToSOQLStringMap.put(childSObjectAPIName, '');

          parentsObjectAPINameToRelatedEntityIds.putAll(
            updateSObjectAPINameWithEntityIdSetMap(
              Id.valueOf(dsVar.Entity_Id__c),
              dsVar.Object_API_Name__c
            )
          );
        }
      }

      if (!childsObjectAPINamesToSOQLStringMap.keySet().isEmpty()) {
        childsObjectAPINamesToSOQLStringMap = formulateSOQLStringMap(
          childsObjectAPINamesToSOQLStringMap.keySet()
        );
        for (
          String sObjectAPIName : childsObjectAPINamesToSOQLStringMap.keySet()
        ) {
          String parentsObjectAPIName = reversedParentsObjectAPINameToChildSObjectAPINameMap.get(
            sObjectAPIName
          );

          String queryString = childsObjectAPINamesToSOQLStringMap.get(
            sObjectAPIName
          );

          String linkedParentEntityField = childsObjectAPINameToRelatedEntityFieldNameMap
            ?.get(sObjectAPIName);
          String whereClause = linkedParentEntityField + ' IN: entityIdSet';

          Map<Id, sObject> sObjectRecordMap = createEntityIdTosObjectRecordEntries(
            queryString,
            whereClause,
            (Set<String>) parentsObjectAPINameToRelatedEntityIds.get(
              parentsObjectAPIName
            )
          );

          childEntityIdToEntityRecordMap.putAll(sObjectRecordMap);
          childEntityWithParentDataStoreIdMap.putAll(
            getMatchedChildEntityWithParentDataStore(
              entityIdToDataStoreIdMap,
              sObjectRecordMap,
              linkedParentEntityField
            )
          );
        }

        for (String childId : childEntityWithParentDataStoreIdMap.KeySet()) {
          String parentsObjectAPIName = dataStoreIdToDataStoreRecordMap.get(
              childEntityWithParentDataStoreIdMap.get(childId)
            )
            .Object_API_Name__c;
          String childSobjectAPIName = parentsObjectAPINameToChildSObjectAPINameMap.get(
            parentsObjectAPIName
          );
          childDataStoreRecordsToBeInserted.add(
            createDataStoreRecordForChild(
              childEntityIdToEntityRecordMap.get(childId),
              childEntityWithParentDataStoreIdMap.get(childId),
              childSobjectAPIName
            )
          );
        }

        System.debug(
          '$$$$$  childDataStoreRecordsToBeInserted >>> ' +
          childDataStoreRecordsToBeInserted
        );
      }
    } catch (Exception exp) {
      System.debug(
        '@@@ exp : ' + exp.getCause() + ' : ' + exp.getStackTraceString()
      );
    }

    return childDataStoreRecordsToBeInserted;
  }

  private static Data_Store__c createDataStoreRecordForChild(
    sObject record,
    String parentDataStoreId,
    String sObjectAPIName
  ) {
    Map<String, String> dataStoreInstanceMap = dataStoreInstanceMapWithGivenRecord(
      record,
      Integer.valueOf(SBR_3_0_DataStoreOperations.FIELD_SIZE_LIMIT)
    );
    dataStoreInstanceMap.put('Entity_Id__c', record.Id);
    dataStoreInstanceMap.put('Object_API_Name__c', sObjectAPIName);
    dataStoreInstanceMap.put('Parent_Data_Store__c', parentDataStoreId);

    return (Data_Store__c) JSON.deserialize(
      JSON.serialize(dataStoreInstanceMap),
      Data_Store__c.class
    );
  }

  /**
   * @description : get child Entity ids with parent's Data Store Id
   * @author soomjeet.sahoo | 05-14-2024
   * @param entityIdToDataStoreIdMap
   * @param childEntityIdToEntityRecordMap
   * @param linkedParentEntityField
   * @return Map<String, String>
   **/
  private static Map<String, String> getMatchedChildEntityWithParentDataStore(
    Map<Id, Id> entityIdToDataStoreIdMap,
    Map<Id, sObject> childEntityIdToEntityRecordMap,
    String linkedParentEntityField
  ) {
    Map<String, String> tmpChildEntityWithParentDataStoreIdMap = new Map<String, String>();
    for (sObject record : childEntityIdToEntityRecordMap.values()) {
      Map<String, Object> mappedsObjectRecord = (Map<String, Object>) JSON.deserializeUntyped(
        JSON.serialize(record)
      );

      Id parentEntityId = (Id) mappedsObjectRecord
        ?.get(linkedParentEntityField);
      Id parentDataStoreId = entityIdToDataStoreIdMap.get(parentEntityId);
      tmpChildEntityWithParentDataStoreIdMap.put(record.Id, parentDataStoreId);
    }
    return tmpChildEntityWithParentDataStoreIdMap;
  }
  /**
   * @description
   * @author soomjeet.sahoo | 05-07-2024
   * @param dataStoreRecord
   * @return String
   **/
  public static String getBackupEntityFromDataStore(
    Data_Store__c dataStoreRecord
  ) {
    String serializedRecord = '';
    Map<String, Object> dataSourceRecordMap = dataStoreRecord.getPopulatedFieldsAsMap()
      .clone();
    serializedRecord = getAllCombinedFieldStores(dataSourceRecordMap);
    return serializedRecord;
  }
  /**
   * @description
   * @author soomjeet.sahoo | 05-02-2024
   * @param dataSourceRecordMap
   * @return String
   **/
  public static String getAllCombinedFieldStores(
    Map<String, Object> dataSourceRecordMap
  ) {
    String finalSerializedRecord = '';
    for (String fieldKey : dataSourceRecordMap.KeySet()) {
      if (
        fieldKey.containsIgnoreCase('Field_Store_') &&
        fieldKey.endsWithIgnoreCase('__c')
      ) {
        finalSerializedRecord += (String) dataSourceRecordMap.get(fieldKey);
      }
    }
    return finalSerializedRecord;
  }

  /**
   * @description : queries all DataStores for given External Ids
   * @author soomjeet.sahoo | 05-02-2024
   * @param sObjectIds
   * @param isChildEntitiesRequired : if True, queries all the childs for the given entities else gets entities
   * @return List<Data_Store__c>
   **/
  public static List<Data_Store__c> getAllDataStores(
    List<String> sObjectIds,
    Boolean isChildEntitiesRequired
  ) {
    String finalQueryString =
      createSOQLStringForGivensObjectAPIName(
        String.valueOf(Data_Store__c.sObjectType),
        ''
      ) + ' WHERE ';
    // ' WHERE Entity_Id__c =: entityIdList OR Parent_Data_Store__r.Entity_Id__c =: entityIdList';
    finalQueryString = isChildEntitiesRequired
      ? finalQueryString + 'Parent_Data_Store__r.Entity_Id__c =: entityIdList'
      : finalQueryString + 'Entity_Id__c =: entityIdList';
    return Database.queryWithBinds(
      finalQueryString,
      new Map<String, Object>{ 'entityIdList' => sObjectIds },
      System.AccessLevel.SYSTEM_MODE
    );
  }

  // /**
  //  * @description
  //  * @author soomjeet.sahoo | 05-14-2024
  //  * @param isChildEntitiesRequired
  //  * @return String
  //  **/
  // private static String getFullQueryForDataStores(
  //   Boolean isChildEntitiesRequired
  // ) {
  //   String whereClause = (isChildEntitiesRequired)
  //     ? 'Parent_Data_Store__r.Entity_Id__c =: entityIdList'
  //     : 'Entity_Id__c =: entityIdList';
  //   return createSOQLStringForGivensObjectAPIName(
  //       String.valueOf(Data_Store__c.sObjectType),
  //       ''
  //     ) +
  //     ' WHERE ' +
  //     whereClause;
  // }

  /**
   * @description : Creates SOQL String for given sObject API Name
   * @author soomjeet.sahoo | 05-02-2024
   * @param sObjectApiName
   * @param commaSeparatedFields
   * @return String
   **/
  public static String createSOQLStringForGivensObjectAPIName(
    String sObjectApiName,
    String commaSeparatedFields
  ) {
    String strSOQL = 'SELECT {0} FROM {1}';
    List<String> replacementValues = new List<String>{
      String.isBlank(commaSeparatedFields)
        ? getAllCommaSeparatedFieldsForGivensObjectAPIName(sObjectApiName)
        : commaSeparatedFields,
      sObjectApiName
    };
    return String.format(strSOQL, replacementValues);
  }

  /**
   * @description : Divides the given String into chunks of given length
   * @author soomjeet.sahoo | 05-07-2024
   * @param serializedStr
   * @param chunkSize
   * @return List<String>
   **/
  public static List<String> getChunkedStringListBasedOnGivenLength(
    String serializedStr,
    Integer chunkSize
  ) {
    List<String> chunkedStringList = new List<String>();
    Integer currIdx = 0;
    while (currIdx < serializedStr.length()) {
      Integer endLen = ((currIdx + chunkSize) > serializedStr.length())
        ? currIdx + (serializedStr.length() - currIdx)
        : currIdx + chunkSize;

      String strSub = serializedStr.substring(currIdx, endLen);
      chunkedStringList.add(strSub);
      currIdx = currIdx + chunkSize;
    }
    return chunkedStringList;
  }

  /**
   * @description : Creates field Value map instance for Data store record.
   * @author soomjeet.sahoo | 05-02-2024
   * @param objRecord
   * @param fieldStoreLimit
   * @return Map<String, String>
   **/
  public static Map<String, String> dataStoreInstanceMapWithGivenRecord(
    sObject objRecord,
    Integer fieldStoreLimit
  ) {
    Map<String, String> dataStoreMap = new Map<String, String>();
    Integer fieldCounter = 1;
    String serializedRecord = (String) System.JSON.serialize(objRecord);
    List<String> chunkedSerializedString = SBR_3_0_DataStoreUtility.getChunkedStringListBasedOnGivenLength(
      serializedRecord,
      fieldStoreLimit
    );
    for (String chunkedStr : chunkedSerializedString) {
      String fieldKey = 'Field_Store_' + String.valueOf(fieldCounter) + '__c';
      dataStoreMap.put(fieldKey, chunkedStr);
      fieldCounter++;
    }
    return dataStoreMap;
  }

  /**
   * @description : formulates and passes Over the SOQL String Map for given Set of sObject API Names
   * @author soomjeet.sahoo | 05-13-2024
   * @param sObjectAPINames
   * @return Map<String, String>
   **/
  public static Map<String, String> formulateSOQLStringMap(
    Set<String> sObjectAPINames
  ) {
    Map<String, String> tmpsObjectAPINameToSOQLStringMap = new Map<String, String>();
    for (String sObjectAPIName : sObjectAPINames) {
      if (!tmpsObjectAPINameToSOQLStringMap.containsKey(sObjectAPIName)) {
        String stringSOQL = SBR_3_0_DataStoreUtility.createSOQLStringForGivensObjectAPIName(
          sObjectAPIName,
          ''
        );
        tmpsObjectAPINameToSOQLStringMap.put(sObjectAPIName, stringSOQL);
      }
    }

    return tmpsObjectAPINameToSOQLStringMap;
  }

  /**
   * @description : updates sObjectAPINameWithEntityIdSetMap with ObjectAPIName as Key and Entity Ids to the related Id Set
   * @author soomjeet.sahoo | 05-13-2024
   * @param entityId
   * @param sObjectAPIName
   * @return Map<String, Set<String>>
   **/
  public static Map<String, Set<String>> updateSObjectAPINameWithEntityIdSetMap(
    String entityId,
    String sObjectAPIName
  ) {
    Map<String, Set<String>> tmpsObjectAPINameWithEntityIdSetMap = new Map<String, Set<String>>();
    if (tmpsObjectAPINameWithEntityIdSetMap.containsKey(sObjectAPIName)) {
      Set<String> entityIdSet = tmpsObjectAPINameWithEntityIdSetMap.get(
        sObjectAPIName
      );
      entityIdSet.add(entityId);
      tmpsObjectAPINameWithEntityIdSetMap.put(sObjectAPIName, entityIdSet);
    } else {
      tmpsObjectAPINameWithEntityIdSetMap.put(
        sObjectAPIName,
        new Set<String>{ entityId }
      );
    }
    return tmpsObjectAPINameWithEntityIdSetMap;
  }

  /**
   * @description
   * @author soomjeet.sahoo | 05-13-2024
   * @param sObjectAPIName
   * @param queryString
   * @param whereClause
   * @param entitiesToQuery
   * @return Map<Id, sObject>
   **/
  public static Map<Id, sObject> createEntityIdTosObjectRecordEntries(
    String queryString,
    String whereClause,
    Set<String> entitiesToQuery
  ) {
    Map<Id, sObject> entityIdToentityRecordMap = new Map<Id, sObject>();
    String finalQueryString = queryString + ' WHERE ' + whereClause;
    Set<String> selectedEntityIdsToQuery = entitiesToQuery;

    for (
      sObject record : Database.queryWithBinds(
        finalQueryString,
        new Map<String, Object>{ 'entityIdSet' => selectedEntityIdsToQuery },
        System.AccessLevel.SYSTEM_MODE
      )
    ) {
      entityIdToentityRecordMap.put(record.Id, record);
    }
    return entityIdToentityRecordMap;
  }

  /**
   * @description : returns comma separated field API Names
   * @author soomjeet.sahoo | 04-29-2024
   * @param sObjectAPIName
   * @return String
   **/
  public static String getAllCommaSeparatedFieldsForGivensObjectAPIName(
    String sObjectAPIName
  ) {
    String commaSeparatedFieldAPINames = '';
    SObjectType sObjTypeInstance = ((SObject) Type.forName(sObjectAPIName)
        .newInstance())
      .getSObjectType();
    Map<String, SObjectField> fieldMap = sObjTypeInstance.getDescribe()
      .fields.getMap();

    String commaSeparatedFieldsFromCustomLabel = (sObjectPINameToRespectiveFieldsToIgnoreCustomLabelMap.containsKey(
        sObjectAPIName
      ))
      ? sObjectPINameToRespectiveFieldsToIgnoreCustomLabelMap
          ?.get(sObjectAPIName)
      : sObjectPINameToRespectiveFieldsToIgnoreCustomLabelMap.get('default');

    List<String> fieldsToIgnoreList = SBR_3_0_DataStoreOperations.convertCommaSeparatedStringIntoStringList(
      commaSeparatedFieldsFromCustomLabel
    );

    for (String fieldAPI : fieldMap.KeySet()) {
      // Considering only non formula fields
      Boolean isNotFormulaField = !fieldMap.get(fieldAPI)
        .getDescribe()
        .isCalculated();
      //Ignoring fields to be ignored for querying
      Boolean isIgnoredField = !fieldsToIgnoreList.contains(fieldAPI);

      if (isNotFormulaField && isIgnoredField) {
        commaSeparatedFieldAPINames =
          commaSeparatedFieldAPINames +
          fieldAPI +
          ',';
      }
    }
    return commaSeparatedFieldAPINames.removeEnd(',');
  }
}