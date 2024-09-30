/*********************************************************************************************************************
* Apex Class: SBR_3_0_GetDodgeProjectInfo_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test Class
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Nate Kanyok				              2022-09-07          Initial version    
*********************************************************************************************************************/

@isTest
public with sharing class SBR_3_0_GetDodgeProjectInfo_Test implements HttpCalloutMock {
	private static final String TOKENNAME = 'DodgeToken';
    private static final String SOAPAction = 'http://constructionpoints.com/2011/07/token/ISecureToken/GetToken';
    private static final String expectedURL = 'https://connect.constructionpoints.com/ProjectReport/202200703559/?ref=SUNBELT_NEWS&tk=&rUrl=https://connect.dodgepipeline.com/dda/projects/202200703559';
    
    @TestSetup
    static void makeData(){
        
        Project__c project = SBR_3_0_TestDataFactory.createProjects(1,false)[0];
        project.Project_Number__c = '22-703559';
        insert project;
        
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Dodge_Token_Endpoint';
        cred.Key_Id__c = 'keyid';
        cred.Secret__c ='credSecret';
        insert cred;
    }
    
    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.TEXT_XML);
        res.setHeader('SOAPAction',SOAPAction);
        res.setBody('{"access_token":"test"}');
        res.setStatusCode(200);
        return res;
    }
    
    @isTest
    static void testGetDodgeWebURL() {
        Test.setMock(HttpCalloutMock.class, new AccessToken_DodgeProject_Test());

        Project__c projectQuery = [
            SELECT
                Id,
            	Project_Number__c
            FROM
                Project__c 
            LIMIT 1
        ];
        
        Test.startTest();
        	String urlString = SBR_3_0_GetDodgeProjectInfo.getDodgeWebUrl(projectQuery.Id);
        	System.debug('url: '+urlString);
        Test.stopTest();
        
        System.assertEquals(expectedUrl, urlString);
    }

}