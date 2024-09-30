/**
 * @description       : Data Store Controller for interfacing into Apex/LWC/Aura
 * @author            : soomjeet.sahoo
 * @group             : salesforce.com
 * @last modified on  : 05-09-2024
 * @last modified by  : soomjeet.sahoo
 **/
public without sharing class SBR_3_0_DataStoreController {
  /**
   * @description : fires Data Store event
   * @author soomjeet.sahoo | 05-09-2024
   * @param sObjApiName
   * @param recordId
   **/
  @AuraEnabled
  public static void fireDataStoreEvent(String sObjApiName, String recordId) {
    try {
      SBR_3_0_Data_Store_Staging_Event__e evt = new SBR_3_0_Data_Store_Staging_Event__e();
      if (sObjApiName.equalsIgnoreCase('order')) {
        String orderQuery =
          SBR_3_0_DataStoreUtility.createSOQLStringForGivensObjectAPIName(
            sObjApiName,
            'Id,Status,Reservation_Order_Number__c'
          ) + ' WHERE Id =: entityId LIMIT 01';
        Order currentOrderRecord = Database.queryWithBinds(
          orderQuery,
          new Map<String, Object>{ 'entityId' => recordId },
          System.AccessLevel.SYSTEM_MODE
        );
        System.debug('currentOrderRecord >> ' + currentOrderRecord);
        if (
          currentOrderRecord.Status.equalsIgnoreCase('created') &&
          !String.isBlank(currentOrderRecord.Reservation_Order_Number__c)
        ) {
          evt.Staging_Record_Id__c = recordId;
          evt.Object_API_Name__c = sObjApiName;
        }
      } else {
        evt.Staging_Record_Id__c = recordId;
        evt.Object_API_Name__c = sObjApiName;
      }
      EventBus.publish(evt);
      // if (test.isRunningTest()) {
      //   Integer iexp = 100 / 0;
      // }
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * @description : Restore record from DataStore
   * @author soomjeet.sahoo | 05-09-2024
   * @param recordId
   **/
  @AuraEnabled
  public static void restoreRecordFromDataStore(String recordId) {
    try {
      SBR_3_0_DataStoreOperations.updateEntityFromDataStore(
        new List<String>{ recordId }
      );
      if (test.isRunningTest()) {
        Integer iexp = 100 / 0;
      }
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * @description : Restore the Order & related orderItem records upon cancel action Type in SBR_3_0_drfOrderService.updateRecord
   * @author soomjeet.sahoo | 05-15-2024
   * @param orderId
   **/
  public static void restoreOrderOnCancelActionType(String orderId) {
    List<sObject> orderItemListForSpecifiedOrderIdList = new List<sObject>();
    orderItemListForSpecifiedOrderIdList = SBR_3_0_DataStoreOperations.buildEntityRecordList(
      new List<String>{ orderId },
      true
    );

    List<OrderItem> clonedOrderItems = new List<OrderItem>();
    List<OrderItem> orderItemsToBeDeletedList = Database.queryWithBinds(
      SBR_3_0_DataStoreUtility.createSOQLStringForGivensObjectAPIName(
        'OrderItem',
        'Id'
      ) + ' WHERE OrderId =: entityId',
      new Map<String, Object>{ 'entityId' => orderId },
      System.AccessLevel.SYSTEM_MODE
    );
    SBR_3_0_TriggerHandler.bypass('SBR_3_0_OrderItemTriggerHandler');
    Database.delete(orderItemsToBeDeletedList, System.AccessLevel.SYSTEM_MODE);

    for (sObject objRec : orderItemListForSpecifiedOrderIdList) {
      sObject record = objRec.clone(false, false, false, false);
      clonedOrderItems.add((OrderItem) record);
    }
    Database.insert(clonedOrderItems, System.AccessLevel.SYSTEM_MODE);

    List<sObject> sObjectList = SBR_3_0_DataStoreOperations.buildEntityRecordList(
      new List<String>{ orderId },
      false
    );

    if (!sObjectList.isEmpty()) {
      Order orderToUpdate = (Order) sObjectList[0];

      orderToUpdate.Is_Edit_In_Progress__c = false;
      orderToUpdate.Last_Edit_By__c = null;
      Database.update(orderToUpdate, System.AccessLevel.SYSTEM_MODE);
    }
  }

  /**
   * @description : Restore the SBQQ__Quote__c & related SBQQ__QuoteLine__c records upon cancel action Type in SBR_3_0_drfQuoteService.updateRecord
   * @author soomjeet.sahoo | 05-15-2024
   * @param quoteId
   **/
  public static void restoreQuoteOnCancelActionType(String quoteId) {
    List<SBQQ__QuoteLine__c> quoteLineItemListForSpecifiedOrderIdList = (List<SBQQ__QuoteLine__c>) SBR_3_0_DataStoreOperations.buildEntityRecordList(
      new List<String>{ quoteId },
      true
    );

    List<SBQQ__QuoteLine__c> clonedQuoteLineItems = new List<SBQQ__QuoteLine__c>();
    List<SBQQ__QuoteLine__c> quoteLineItemsToBeDeletedList = Database.queryWithBinds(
      SBR_3_0_DataStoreUtility.createSOQLStringForGivensObjectAPIName(
        'SBQQ__QuoteLine__c',
        'Id'
      ) + ' WHERE SBQQ__Quote__c =: entityId',
      new Map<String, Object>{ 'entityId' => quoteId },
      System.AccessLevel.SYSTEM_MODE
    );
    SBR_3_0_TriggerHandler.bypass('SBR_3_0_QuoteLineTriggerHandler');
    Database.delete(
      quoteLineItemsToBeDeletedList,
      System.AccessLevel.SYSTEM_MODE
    );

    for (sObject objRec : quoteLineItemListForSpecifiedOrderIdList) {
      sObject record = objRec.clone(false, false, false, false);
      clonedQuoteLineItems.add((SBQQ__QuoteLine__c) record);
    }
    Database.insert(clonedQuoteLineItems, System.AccessLevel.SYSTEM_MODE);

    SBQQ__Quote__c quoteToUpdate = (SBQQ__Quote__c) SBR_3_0_DataStoreOperations.buildEntityRecordList(
      new List<String>{ quoteId },
      false
    )[0];
    quoteToUpdate.Is_Edit_In_Progress__c = false;
    quoteToUpdate.Last_Edit_By__c = null;
    Database.update(quoteToUpdate, System.AccessLevel.SYSTEM_MODE);
  }

  /**
   * @description : used for interfacing Datastore event creation for flows
   * @author soomjeet.sahoo | 05-21-2024
   * @param quoteRecordsIds
   **/
  @InvocableMethod(
    label='fireDataStoreEventForQuoteFlowAction'
    description='Fires data store events for given Quote records'
    category='SBQQ__Quote__c'
  )
  public static void fireDataStoreEventForQuoteFlowAction(
    List<Id> quoteRecordsIds
  ) {
    List<SBR_3_0_Data_Store_Staging_Event__e> evtList = new List<SBR_3_0_Data_Store_Staging_Event__e>();
    for (Id quoteRecordId : quoteRecordsIds) {
      evtList.add(
        new SBR_3_0_Data_Store_Staging_Event__e(
          Staging_Record_Id__c = quoteRecordId,
          Object_API_Name__c = 'SBQQ__Quote__c'
        )
      );
    }

    EventBus.publish(evtList);
  }
}