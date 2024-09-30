/*********************************************************************************************************************
* Apex Class: Sbr_3_0_FetchLookupDataController
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Controller for lwc lwc Sbr_3_0_sfsGenericFetchLookupData
* - Test class-Sbr_3_0_FetchLookupDataControllerTest
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0              Vikas Kumar          2024-06-25             Initial version   
*********************************************************************************************************************/
public with sharing class Sbr_3_0_FetchLookupDataController {
  @AuraEnabled 
  public static QueryResult getSObjects(String queryString) {
    return new QueryResult(Database.query(queryString, System.AccessLevel.USER_MODE));
  }
  public class QueryResult {
        public QueryResult(List<SObject> results) {
            this.results = results;
            if (this.results.isEmpty() == false) {
            this.firstResult = this.results.get(0);
            }
        } 
        @AuraEnabled
        public final List<SObject> results;
        @AuraEnabled
        public final SObject firstResult;  
    }
}