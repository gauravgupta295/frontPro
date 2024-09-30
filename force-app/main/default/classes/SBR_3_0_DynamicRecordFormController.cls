/*********************************************************************************************************************
* Apex Class: SBR_3_0_DynamicRecordFormController
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Controller class for sbr_3_0_dynamicRecordFrom component. It returns the configuration needed to render the dynamic form
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Komal Dwivedi          12-Oct-2023          Initial version
    2.0         Komal Dwivedi          25-Jan-2024          Refactored version. Moved code to another service. Also added logic of parent-child pages.
*********************************************************************************************************************/
public with sharing class SBR_3_0_DynamicRecordFormController {

  @AuraEnabled(cacheable=true)
  public static Object getConfigurations(String mappingName) {



    try {
      SBR_3_0_dynamicRecordFormService service = new SBR_3_0_dynamicRecordFormService(
        mappingName
      );
      return service.getConfigurationsByMappingNames();






















































































    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  //FRONT-13994, FRONT-13996, FRONT-20239, FRONT-18373
  @AuraEnabled
  public static Boolean checkRecord(String objectName, String recordId) {
    Boolean showToast = false;
    if (objectName == 'Order') {
      Order orderRec = [
        SELECT 
          Id,
          Pending_Tax_Calculation__c, 
          Status, 
          Is_Edit_In_Progress__c, 
          RecordType.DeveloperName 
        FROM Order 
        WHERE Id = :recordId
        ];
      if (
        orderRec.Pending_Tax_Calculation__c == true && 
        orderRec.RecordType.DeveloperName == 'Reservation_Order' && 
        orderRec.Is_Edit_In_Progress__c == true
        ) {
        showToast = true;
      }
    } else if (objectName == 'SBQQ__Quote__c') {
      SBQQ__Quote__c quoteRec = [
        SELECT
          Id,
          Pending_Tax_Calculation__c,
          SBQQ__Status__c,
          Is_Edit_In_Progress__c,
          RecordType.DeveloperName
        FROM SBQQ__Quote__c
        WHERE Id = :recordId
      ];
      if (
        quoteRec.Pending_Tax_Calculation__c == true && 
        quoteRec.Is_Edit_In_Progress__c == true
      ) {
        showToast = true;
      }
    }
    return showToast;
  }
}