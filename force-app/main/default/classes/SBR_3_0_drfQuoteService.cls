/**
 * @description       : DML handler for Quote
 * @author            : soomjeet.sahoo
 * @group             : $groupname
 * @last modified on  : 05-20-2024
 * @last modified by  : soomjeet.sahoo
 **/
public without sharing class SBR_3_0_drfQuoteService implements SBR_3_0_drfDMLOpsInterface {
  /**
   * @description : Updates the record on view based on action type passed
   * @author soomjeet.sahoo | 05-20-2024
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
      SBR_3_0_DataStoreController.restoreQuoteOnCancelActionType(
        (String) fields.get('Id')
      );
    } else {
      if (actionType.equalsIgnoreCase('edit')) {
        fields.put('Last_Edit_By__c', UserInfo.getUserId());

        //FRONT-17961 : Validate the order and fire Data Store Event
        SBR_3_0_DataStoreController.fireDataStoreEventForQuoteFlowAction(
          new List<Id>{ (Id) fields.get('Id') }
        );
      }
      srVar = database.update(fields);
    }
    return srVar;
  }

  /**
   * @description : submits record for RM Sync
   * @author soomjeet.sahoo | 05-20-2024
   * @param recordId
   * @return Object
   **/
  public static Object submitRecord(Id recordId) {
    return SBR_3_0_API_CreateQuotesV2.submitQuote(recordId);
  }
}