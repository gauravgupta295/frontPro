/**
 * @description       : DML handler for Order
 * @author            : salesforce.com
 **/
public without sharing class SBR_3_0_drfOrderService implements SBR_3_0_drfDMLOpsInterface {
  /**
   * @description : Updates the record on view based on action type passed
   * @author salesforce.com
   * @param fields
   * @param actionType
   * @return Database.SaveResult
   **/
  public static Database.SaveResult updateRecord(
    SObject fields,
    String actionType
  ) {
    Database.SaveResult srVar;

    if (actionType.equalsIgnoreCase('cancel')) {
      SBR_3_0_DataStoreController.restoreOrderOnCancelActionType(
        (String) fields.get('Id')
      );
    } else {
      if (actionType.equalsIgnoreCase('edit')) {
        fields.put('Last_Edit_By__c', UserInfo.getUserId());
        //FRONT-17961 : Validate the order and fire Data Store Event
        SBR_3_0_DataStoreController.fireDataStoreEvent(
          'Order',
          (String) fields.get('Id')
        );
      }
    }
    srVar = database.update(fields);
    return srVar;
  }

  /**
   * @description : submits order for RM Sync
   * @author salesforce.com
   * @param recordId
   * @return Object
   **/
  public static Object submitRecord(Id recordId) {
    return SBR_3_0_CreateOrderService_V2.submitOrder(recordId);
  }
}