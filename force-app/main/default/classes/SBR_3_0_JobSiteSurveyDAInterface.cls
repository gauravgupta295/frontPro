/*********************************************************************************************************************
* Apex Class: SBR_3_0_JobSiteSurveyDAInterface
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Interface class for JobSite Survey Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE(yyyy/MM/DD)                DETAIL FEATURES
    1.0         Shreenivas Adapur       2024-01-24                       Initial version SF-6444 
*********************************************************************************************************************/
public interface SBR_3_0_JobSiteSurveyDAInterface {
   Jobsite_Survey__c getJobSiteSurveyAnalysisRgn (String recordId);
}