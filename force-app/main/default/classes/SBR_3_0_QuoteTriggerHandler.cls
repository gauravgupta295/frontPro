/**
 * @description       :
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             :
 * @last modified on  : 10-17-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 **/
public with sharing class SBR_3_0_QuoteTriggerHandler extends SBR_3_0_TriggerHandler {
  @TestVisible
  private Map<Id, SBQQ__Quote__c> oldQuoteMap;
  @TestVisible
  private Map<Id, SBQQ__Quote__c> newQuoteMap;

  public static Boolean beforeUpdateRecursiveCheck = false;
  public static Boolean afterInsertRecursiveCheck = false;
  public static Boolean afterUpdateRecursiveCheck = false;
  //p2p specific logic to exclude record type
  @TestVisible
  public static Map<ID, Schema.RecordTypeInfo> rtMap;
  @TestVisible
  public static Id punchoutTypeId;

  /**
   * @description - constructor for SBR_3_0_QuoteTriggerHandler class to initialise oldMap and newMap
   */
  public SBR_3_0_QuoteTriggerHandler() {
    this.oldQuoteMap = (Map<Id, SBQQ__Quote__c>) Trigger.oldMap;
    this.newQuoteMap = (Map<Id, SBQQ__Quote__c>) Trigger.newMap;
  }

  public override void beforeInsert() {
    try {
      //p2p specific logic to exclude record type
      List<SBQQ__Quote__c> newQuotes = (List<SBQQ__Quote__c>) Trigger.new;
      Map<ID, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosById();
      List<SBQQ__Quote__c> newQuotesList = new List<SBQQ__Quote__c>();

      for (SBQQ__Quote__c o : newQuotes) {
        //p2p specific logic to exclude record type



        if (rtMap.get(o.RecordTypeId).getName() != 'Punchout') {
          newQuotesList.add(o);
        }
      }

      SBR_3_0_QuoteOperations.updateName(newQuotesList);
      SBR_3_0_QuoteOperations.updateEndDate(newQuotesList, null);
      SBR_3_0_QuoteOperations.populateAccountRecordType(newQuotesList, true); // SF-5397
      SBR_3_0_QuoteOperations.updateCreatedByUserBranch(newQuotesList);
      // SF-5331 => Set some Quote options to TRUE for Scaffold quotes
      SBR_3_0_QuoteOperations.enableScaffoldQuotesOptions(
        (List<SBQQ__Quote__c>) newQuotesList
      );
    } catch (Exception error) {
      throw new SBR_3_0_QuoteTriggerException();
    } finally {
    }
  }
  public override void afterInsert() {
    try {
      //p2p specific logic to exclude record type
      List<SBQQ__Quote__c> newQuotes = (List<SBQQ__Quote__c>) Trigger.new;
      Map<ID, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosById();
      List<SBQQ__Quote__c> newQuotesList = new List<SBQQ__Quote__c>();

      for (SBQQ__Quote__c o : newQuotes) {
        //p2p specific logic to exclude record type
        if (rtMap.get(o.RecordTypeId).getName() != 'Punchout') {
          newQuotesList.add(o);
        }
      }

      if (!afterInsertRecursiveCheck) {
        SBR_3_0_QuoteOperations.publishQuoteToOutbox(this.newQuoteMap);
        SBR_3_0_QuoteOperations.manageELaborQuoteLines(newQuotesList, null); //SAL-16963
        // SF-5349 => Set default Rental Protection / RPP to TRUE - for Prospect Accounts
        SBR_3_0_QuoteOperations.setRPPFieldToTrue((List<SBQQ__Quote__c>) newQuotesList);
        //Added by nitin to avoid recursion
        afterInsertRecursiveCheck = true;
      }
    } catch (Exception ex) {
      SBR_3_0_Log.logException(ex);
    } finally {
      SBR_3_0_Log.saveLog();
    }
  }

  public override void beforeUpdate() {
    try {
      //p2p specific logic to exclude record type
      List<SBQQ__Quote__c> newQuotes = (List<SBQQ__Quote__c>) Trigger.new;
      Map<ID, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosById();
      List<SBQQ__Quote__c> newQuotesList = new List<SBQQ__Quote__c>();

      for (SBQQ__Quote__c o : newQuotes) {
        //p2p specific logic to exclude record type
        if (rtMap.get(o.RecordTypeId).getName() != 'Punchout') {
          newQuotesList.add(o);
        }
      }

      if (!beforeUpdateRecursiveCheck) {
        // SAL-27468 : Block editing the quote if it's marked as Won, has an associated order, and the user is not an administrator (System / Business).
        SBR_3_0_QuoteOperations.PreventEditQuote(this.newQuoteMap,this.oldQuoteMap); // SAL-27468
        SBR_3_0_QuoteOperations.updateEndDate(newQuotesList, this.oldQuoteMap);
        SBR_3_0_QuoteOperations.handleDeliveryOverrideChanges(this.oldQuoteMap,this.newQuoteMap
        ); // SF-6005
        SBR_3_0_QuoteOperations.populateAccountRecordType(newQuotesList, false); // SF-5397
        SBR_3_0_QuoteOperations.handleDeliveryOptionChange(this.oldQuoteMap,this.newQuoteMap); //SF-6415
        beforeUpdateRecursiveCheck = true;
      }
    } catch (Exception ex) {
      SBR_3_0_Log.logException(ex);
    } finally {
      SBR_3_0_Log.saveLog();
    }
  }

  public override void afterUpdate() {
    try {
      //p2p specific logic to exclude record type
      List<SBQQ__Quote__c> newQuotes = (List<SBQQ__Quote__c>) Trigger.new;
      Map<ID, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosById();
      List<SBQQ__Quote__c> newQuotesList = new List<SBQQ__Quote__c>();

      for (SBQQ__Quote__c o : newQuotes) {
        //p2p specific logic to exclude record type
        if (rtMap.get(o.RecordTypeId).getName() != 'Punchout') {
          newQuotesList.add(o);
        }
      }

      if (!afterUpdateRecursiveCheck) {
        SBR_3_0_QuoteOperations.manageELaborQuoteLines(newQuotesList,this.oldQuoteMap);
      }
    } catch (Exception e) {
      SBR_3_0_Log.logException(e);
    } finally {
      SBR_3_0_Log.saveLog();
    }
  }
  /**
   * @description - This method is used to handle app exceptions
   */
  public class SBR_3_0_QuoteTriggerException extends Exception {
  }
}