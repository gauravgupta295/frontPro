@isTest
public class PPA_MulesoftTokenManager_Test {

    @TestSetup
    public static void testSetup(){
        PPA_GeneratePDFUtility_Test.makeData();
    }
    
    @isTest
    public static void getAccessTokenTest200() {
        Map<String,String> returnVals = new Map<String,String>();
        Test.setMock(HttpCalloutMock.class, new PPA_GeneratePDFHttpCalloutMock_Test());
        
        Test.startTest();
        returnVals = PPA_MulesoftTokenManager.getAccessToken();
        Assert.areEqual('0', returnVals.get('errorCode'));
        Assert.areEqual('12345', returnVals.get('accessToken'));
        Test.stopTest();
    }

    @isTest
    public static void getAccessTokenTest400() {
        Map<String,String> returnVals = new Map<String,String>();
        Test.setMock(HttpCalloutMock.class, new PPA_GeneratePDFHttpCalloutMock_Test());

        PPA_MulesoftDocumentApi__c docApi = [SELECT Id, PPA_Token_Endpoint__c FROM PPA_MulesoftDocumentApi__c LIMIT 1];
        docApi.PPA_Token_Endpoint__c = '/error';
        update docApi;
        
        Test.startTest();
        returnVals = PPA_MulesoftTokenManager.getAccessToken();
        Assert.areEqual('-1', returnVals.get('errorCode'));
        Test.stopTest();
    }
}