/*********************************************************************************************************************
* Apex Class: SBR_3_0_GetDodgeProjectInfo
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Get Dodge Token and WebURL for the Project 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                DETAIL FEATURES
    1.0         Nate Kanyok, Viren Patel           2022-09-06            Initial version    
*********************************************************************************************************************/
public with sharing class SBR_3_0_GetDodgeProjectInfo {

    // Example WebUrl 
    // https://connect.constructionpoints.com/ProjectReport/201900874568/?ref=SUNBELT_NEWS&tk=92fda4c6-dcd4-4682-8b97-60adbe121f71&rUrl=https://connect.dodgepipeline.com/dda/projects/201900874568
    
    private static final String DODGE_WEB_URL_PREFIX = 'https://connect.constructionpoints.com/ProjectReport/';
    private static final String DODGE_REF_PARAM ='/?ref=SUNBELT_NEWS';
    private static final String DODGE_TOKEN_PARAM ='&tk=';
    private static final String DODGE_RURL_PARAM ='&rUrl=';
    private static final String DODGE_REDIRECT_URL_PREFIX = 'https://connect.dodgepipeline.com/dda/projects/';
    private static final String YEAR_PREFIX = '20';
    private static final String PROJECT_ID_PREFIX = '00';

    @AuraEnabled (cacheable=true)
    public static String getDodgeWebUrl(String projectId) {
        String projectIdWithYear = getProjectIdWithYear(projectId);
        String token = getDodgeToken();

        if(String.IsNotBlank(projectIdWithYear)) {
            String webUrl = 
                DODGE_WEB_URL_PREFIX +
                projectIdWithYear +
                DODGE_REF_PARAM +
                DODGE_TOKEN_PARAM +
                token +
                DODGE_RURL_PARAM +
                DODGE_REDIRECT_URL_PREFIX +
                projectIdWithYear;
            
            return webUrl;
        }
        return null;
    }

    private static String getDodgeToken() {
        SBR_3_0_API_AccessToken_DodgeProject dtk = new SBR_3_0_API_AccessToken_DodgeProject();
        return (String) dtk.getNewToken();
    }

    private static String getProjectIdWithYear(String projectId) {


        Project__c projectData = SBR_3_0_ProjectDA.getProject(projectId);

        if (projectData == null) {
            return '';
        }

        String projectNumberField = projectData.Project_Number__c;

        String delimiter = '-';
        String year = projectNumberField.substringBefore(delimiter);
        String projectIdNumber = projectNumberField.substringAfter(delimiter);
        return YEAR_PREFIX + year + PROJECT_ID_PREFIX + projectIdNumber;
    }

}