/*********************************************************************************************************************
* Apex Class: SBR_3_0_AccountTriggerHandler
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to manage trigger logic for Accounts
* - SAL-473, SAL- 1502
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Harry Patel,Viren Patel           2022-03-15               Initial version 
    1.1         Nate Kanyok                       2022-08-17               Comment out  populateSFAccountNumber   
    1.2.        Neeraj Kumar                      2023-09-13               Calling createPrimaryContactmethod for primary contacts
*********************************************************************************************************************/

public with sharing class SBR_3_0_AccountTriggerHandler extends SBR_3_0_TriggerHandler {
  @TestVisible
  private Map<Id, Account> oldAccountMap;
  @TestVisible
  private Map<Id, Account> newAccountMap;

  Boolean isIntegrationUser = FeatureManagement.checkPermission(
    SBR_3_0_Constants.ACCOUNT_EXTERNAL_USER
  );
  Boolean isDataMigrationUser = FeatureManagement.checkPermission(
    SBR_3_0_Constants.DATA_MIGRATION_USER
  );

  public SBR_3_0_AccountTriggerHandler() {
    this.oldAccountMap = (Map<Id, Account>) Trigger.oldMap;
    this.newAccountMap = (Map<Id, Account>) Trigger.newMap;
  }

  public override void beforeInsert() {
    SBR_3_0_AccountOperations.updateSourceOfUpdate(Trigger.new);
    SBR_3_0_AccountOperations.prefixAccountNumberWithCompanyCode(Trigger.new);
    SBR_3_0_AccountOperations.linkSalesRepIds(Trigger.New);

    if (isIntegrationUser || isDataMigrationUser) {
      SBR_3_0_AccountOperations.validateStateCountry(null, Trigger.new);
      SBR_3_0_AccountOperations.validateInboundAccount(Trigger.New);
      //Added for SAL-22623
      SBR_3_0_AccountOperations.updateDriverslicense(Trigger.new);
    }
    SBR_3_0_AccountOperations.setSanitisedDLNumber(Trigger.new);
    //FRONT-9890
    SBR_3_0_AccountOperationsFrontLine.updateRMCashNumberState(
      Trigger.new,
      null
    );
  }

  public override void afterInsert() {
    SBR_3_0_AccountOperations.publishCreditAndNonCreditAccounts(
      this.newAccountMap
    );
    SBR_3_0_AccountOperations.updateLobOnChildRecords(
      this.newAccountMap.values(),
      null
    );
    // SBR_3_0_AccountOperations.fetchTerritoryIdDirect(NULL, this.newAccountMap);
    if (isIntegrationUser == false && isDataMigrationUser == false) {
      SBR_3_0_AccountOperations.fetchAddressLatLong(null, this.newAccountMap);
    }

    SBR_3_0_AccountOperationsFrontLine.createLocationAndJobSite(
      (List<Account>) Trigger.new,
      this.oldAccountMap
    );

    //FRONT-4951
    if (!System.isFuture() && !System.isBatch() && isIntegrationUser == false) {
      SBR_3_0_AccountOperationsFrontLine.checkAccount(
        (List<Account>) Trigger.new,
        this.newAccountMap,
        this.oldAccountMap,
        'POST'
      );
    }
    // FRONT-7377
    if (isIntegrationUser == true) {
      SBR_3_0_AccountOperationsFrontLine.createPrimaryContact(
        (List<Account>) Trigger.new
      );
    }
    // SF-5349 => Set default Rental Protection / RPP to TRUE - for Prospect Accounts
    SBR_3_0_AccountOperations.setRPPFieldToTrue((List<Account>) Trigger.new);
  }

  public override void afterUpdate() {
    SBR_3_0_AccountOperations.publishCreditAndNonCreditAccounts(
      this.newAccountMap
    );
    SBR_3_0_AccountOperations.publishProspectAccount(
      this.oldAccountMap,
      this.newAccountMap
    );
    SBR_3_0_AccountOperations.updateLobOnChildRecords(
      this.newAccountMap.values(),
      this.oldAccountMap
    );
    if (isIntegrationUser == false || Test.isRunningTest() == false) {
     SBR_3_0_AccountOperations.publishCreditOrCorp(
      this.oldAccountMap,
      this.newAccountMap
    ); //SAL-26003  // Uncommented this line for SF-5270
      } 
    if (isIntegrationUser == false && isDataMigrationUser == false) {
      SBR_3_0_AccountOperations.fetchterriFuture(
        this.oldAccountMap.values(),
        this.newAccountMap.values()
      );
      SBR_3_0_AccountOperations.fetchAddressLatLong(
        this.oldAccountMap,
        this.newAccountMap
      );
    }
    SBR_3_0_AccountOperationsFrontLine.createLocationAndJobSite(
      (List<Account>) Trigger.new,
      this.oldAccountMap
    );
    SBR_3_0_AccountOperationsFrontLine.updateJobsiteAddressForNCAccounts(
      (List<Account>) Trigger.new,
      this.oldAccountMap
    );
    //FRONT-4951
    if (!System.isFuture() && !System.isBatch()) {
      SBR_3_0_AccountOperationsFrontLine.checkAccount(
        (List<Account>) Trigger.new,
        this.newAccountMap,
        this.oldAccountMap,
        'PUT'
      );
    }
    // SF-5397
    SBR_3_0_AccountOperations.updateAccountRecordTypeOnChild(
      this.oldAccountMap,
      this.newAccountMap
    );
  }

  public override void beforeUpdate() {
    SBR_3_0_AccountOperations.preventOSRUpdateOfReadinessFields(
      this.oldAccountMap,
      this.newAccountMap
    );
    SBR_3_0_AccountOperations.updateAccToNonCredit(
      this.oldAccountMap,
      this.newAccountMap
    );
    SBR_3_0_AccountOperations.updateSourceOfUpdate(this.newAccountMap.values());
    SBR_3_0_AccountOperations.preventAccountNumberUpdate(
      this.oldAccountMap,
      this.newAccountMap
    );
    SBR_3_0_AccountOperations.linkSalesRepIds(
      this.oldAccountMap,
      this.newAccountMap
    );
    SBR_3_0_AccountOperations.preventUpdateOfAccFields(
      this.oldAccountMap,
      this.newAccountMap
    );

    if (isIntegrationUser || isDataMigrationUser) {
      SBR_3_0_AccountOperations.validateStateCountry(
        this.oldAccountMap,
        Trigger.new
      );
      SBR_3_0_AccountOperations.validateInboundAccount(
        this.oldAccountMap,
        this.newAccountMap
      );
      //Added for SAL-22623
      SBR_3_0_AccountOperations.updateDriverslicense(
        this.oldAccountMap,
        this.newAccountMap
      );
      SBR_3_0_AccountOperations.setRecordTypeForConvertedWG(
        this.oldAccountMap,
        this.newAccountMap
      ); // FRONT-11427
    }

    SBR_3_0_AccountOperations.setSanitisedDLNumber(Trigger.New);
    //Modified for FRONT-9890
    SBR_3_0_AccountOperationsFrontLine.updateRMCashNumberState(
      Trigger.new,
      this.oldAccountMap
    );

    SBR_3_0_AccountOperationsFrontLine.updateNonCredit(this.newAccountMap);
  }
}