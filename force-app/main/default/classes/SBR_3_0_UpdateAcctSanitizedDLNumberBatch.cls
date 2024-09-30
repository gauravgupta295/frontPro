/**
 *
 * @author Lakshya Khandelwal
 * @description Class to update the field Sanitisied DL Number on the Account object for the legacy accounts.
 * Since Sanitised_DL_Number__c field is a prerequisite for Hard stop experience, we need to run this batch once the duplicate rules are active.
 * Actual sanitization is happening in the account trigger handler. However, to perform a dummy update (with possibly a smaller batch in case we encounter
 * Governor limits), we need this batch.
 */
public class SBR_3_0_UpdateAcctSanitizedDLNumberBatch implements Database.Batchable<sObject> {
  private String query;
  public SBR_3_0_UpdateAcctSanitizedDLNumberBatch(String queryPassed){
    query = queryPassed;
  }
  public Database.QueryLocator start(Database.BatchableContext bc) {
    //String query = 'SELECT Id, Name, Sanitised_DL_Number__c, Drivers_License__c FROM Account WHERE Drivers_License__c != null';
    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext bc, List<Account> scope) {
    SBR_3_0_AccountOperations.setSanitisedDLNumber(scope);
    Database.update(scope, false);
  }

  public void finish(Database.BatchableContext bc) {
  }
}