/*********************************************************************************************************************
* Apex Class: SBR_3_0_JobSiteSurveyDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Data Access class for JobSite Survey
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE(yyyy/MM/DD)                DETAIL FEATURES
    1.0         Shreenivas Adapur       2024-01-24                       Initial version SF-6444
*********************************************************************************************************************/
public with sharing class SBR_3_0_JobSiteSurveyDA implements SBR_3_0_JobSiteSurveyDAInterface {
   public static Jobsite_Survey__c getJobSiteSurveyAnalysisRgn(String recordId){
        Jobsite_Survey__c jobSiteSurveyFields = [SELECT Id,sbr_ProfitCenterId__r.Name, sbr_ProfitCenterId__r.Analysis_Region_Key__c FROM Jobsite_Survey__c WHERE Id =:recordId LIMIT 1];
        return jobSiteSurveyFields;
    }
}