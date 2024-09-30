/*********************************************************************************************************************
* Apex Class: SBR_3_0_DuplicateResults
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to obtain records that triggered a DmlException of the error type DUPLICATES_DETECED
* - SAL-3038
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Konrad Haight           2022-05-12          Initial version    
*********************************************************************************************************************/
public without sharing class SBR_3_0_DuplicateResults {
  public static List<SObject> getDuplicatedRecords(
    Database.SaveResult saveResult
  ) {
    List<SObject> duplicateRecords = new List<SObject>();
    Boolean hasDuplicateResult;
    if (!saveResult.isSuccess()) {
      for (Database.Error error : saveResult.getErrors()) {
        if (error instanceof Database.DuplicateError) {
          Database.DuplicateError duplicateError = (Database.DuplicateError) error;
          Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();

          Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();

          Datacloud.MatchResult matchResult = matchResults[0];

          Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();

          // Add matched record to the duplicate records variable
          for (Datacloud.MatchRecord matchRecord : matchRecords) {
            System.debug('MatchRecord: ' + matchRecord.getRecord());
            duplicateRecords.add(matchRecord.getRecord());
          }
          hasDuplicateResult = !duplicateRecords.isEmpty();
        }
      }
    }
    return duplicateRecords;
  }
}