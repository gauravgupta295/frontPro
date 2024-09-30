/*********************************************************************************************************************
* Apex Class: SBR_3_0_SubmitQuoteController 
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Controller for submitting quote to Rentalman via mulesoft 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Davinder Singh          2022-12-05            Initial version    
*********************************************************************************************************************/
public with sharing class SBR_3_0_SubmitQuoteController {
  @AuraEnabled(cacheable=true)
  public static PermissionWrapper checkUpdateablePermission(Id recordId) {
    System.debug('checking permissions for record: ' + recordId);
    PermissionWrapper result;

    if (recordId != null) {
      String objectApi = recordId.getSObjectType().getDescribe().getName();
      String objectLabel = recordId.getSObjectType().getDescribe().getLabel();

      if (objectApi == 'SBQQ__Quote__c') {
        result = new PermissionWrapper(
          true,
          objectApi,
          objectLabel,
          null,
          null
        );

        DescribeFieldResult des = Schema.sObjectType.SBQQ__Quote__c.fields.Rentalman_Quote_Id__c;
        if (
          !Schema.sObjectType.SBQQ__Quote__c.fields.Rentalman_Quote_Id__c.isUpdateable()
        ) {
          result = new PermissionWrapper(
            false,
            objectApi,
            objectLabel,
            des.getName(),
            des.getLabel()
          );
        }
        des = Schema.sObjectType.SBQQ__Quote__c.fields.Submitted_to_Wynne__c;
        if (
          !Schema.sObjectType.SBQQ__Quote__c.fields.Submitted_to_Wynne__c.isUpdateable()
        ) {
          result = new PermissionWrapper(
            false,
            objectApi,
            objectLabel,
            des.getName(),
            des.getLabel()
          );
        }
        return result;
      }
    }

    result = new PermissionWrapper(
      true,
      'Unsupported Object',
      'Unsupported Object',
      null,
      null
    );

    return result;
  }

  @AuraEnabled(cacheable=false)
  public static Boolean submitQuote(Id recordId) {

    SBQQ__Quote__c quote = SBR_3_0_QuoteDA.getQuote(recordId);

    try {
      if (
        quote.SBQQ__Account__r.RecordType.DeveloperName ==
        SBR_3_0_Constants.ACCOUNT_REC_TYPE_PROSPECT
      ) {
        throw new AuraHandledException(
          'You cannot submit this record when the Account is still a Prospect. Please have the customer complete the Credit Application, which can be sent from the Account record page.'
        );
      }
      System.debug('Before testCreate() executed ....');
      Object testCreate = SBR_3_0_API_CreateQuotesV2.submitQuote(recordId);

      return true;
    } catch (Exception ex) {
      System.debug('exception in submitQuote  ' + ex.getMessage());
      System.debug(ex);
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled(cacheable=false)
  public static String checkRequiredData(Id recordId) {
    try {
      DateTime now = DateTime.now();
      SBQQ__Quote__c quote = SBR_3_0_QuoteDA.getQuote(recordId);
      if (quote.Start_Date__c < now) {
        return 'Start Date must be greater than or equal than the current day/time. Please update and try again';
      }
      if (quote.SBQQ__Status__c == 'In Review') {
        return 'In Review quotes can not be submitted';
      }
      if (quote.Delivery_Date__c < now) {
        return 'Earliest Delivery Date must be greater than or equal than the current day/time. Please update and try again';
      }
      if (quote.Delivery_Date__c > quote.Start_Date__c) {
        return 'Earliest Delivery Date must be before or on the Start Date/Time. Please update and try again';
      }
    } catch (Exception ex) {
      insert new Exception_Log__c(
        Name = ex.getTypeName(),
        Exception_Message__c = ex.getMessage()
      );
    }
    return 'true';
  }

  public class PermissionWrapper {
    @AuraEnabled
    public Boolean hasPermission;
    @AuraEnabled
    public String objectApi;
    @AuraEnabled
    public String objectLabel;
    @AuraEnabled
    public String fieldAPIName;
    @AuraEnabled
    public String fieldLabel;

    public PermissionWrapper(
      Boolean hp,
      String obj,
      String objLabel,
      String fieldApi,
      String fieldLabel
    ) {
      this.hasPermission = hp;
      this.objectApi = obj;
      this.objectLabel = objLabel;
      this.fieldAPIName = fieldApi;
      this.fieldLabel = fieldLabel;
    }
  }
}