@isTest
private class SBR_3_0_UpdateAcctSanitizedDLNoBatchTest {
  @isTest
  private static void whenDLAccountNumberPresentSanitisedDLNumber() {
    SBR_3_0_TriggerHandler.bypass('SBR_3_0_AccountTriggerHandler');
    Account acc = SBR_3_0_TestDataFactory.createAccounts(1, false, 'Non_Credit')
      .get(0);
    acc.Drivers_License__c =
      'CA-' + SBR_3_0_TestDataFactory.generateRandomString(6);
    insert acc;

    Test.startTest();
    Database.executeBatch(new SBR_3_0_UpdateAcctSanitizedDLNumberBatch('SELECT Id, Name, Sanitised_DL_Number__c, Drivers_License__c FROM Account WHERE Drivers_License__c != null'), 1);
    Test.stopTest();

    Account updatedAccount = [
      SELECT Id, Sanitised_DL_Number__c
      FROM Account
      WHERE Id = :acc.Id
      LIMIT 1
    ];

    System.assertNotEquals(
      null,
      updatedAccount.Sanitised_DL_Number__c,
      'Account\'s Sanitised DL Number Field is changed'
    );
  }
}