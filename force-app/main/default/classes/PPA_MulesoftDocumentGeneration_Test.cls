@isTest
public class PPA_MulesoftDocumentGeneration_Test {

    @TestSetup
    public static void testSetup(){
        PPA_GeneratePDFUtility_Test.makeData();
    }
    
    @isTest
    public static void submitRequestTest200() {
        Map<String,String> returnVals = new Map<String,String>();
        Test.setMock(HttpCalloutMock.class, new PPA_GeneratePDFHttpCalloutMock_Test());
        PPA_Price_List__c priceList = [SELECT Id FROM PPA_Price_List__c LIMIT 1];

        Test.startTest();
        returnVals = PPA_MulesoftDocumentGeneration.submitRequest(priceList.Id, 'TEST', true, true);
        
        system.debug(returnVals);
        
        Assert.areEqual('0', returnVals.get('errorCode'));
        Assert.areEqual('In Progress', returnVals.get('status'));
        Test.stopTest();
    }

    @isTest
    public static void submitRequestTest400() {
        Map<String,String> returnVals = new Map<String,String>();
        Test.setMock(HttpCalloutMock.class, new PPA_GeneratePDFHttpCalloutMock_Test());
        PPA_Price_List__c priceList = [SELECT Id FROM PPA_Price_List__c LIMIT 1];

        PPA_MulesoftDocumentApi__c docApi = [SELECT Id, PPA_Document_Endpoint__c, PPA_Token_Endpoint__c FROM PPA_MulesoftDocumentApi__c LIMIT 1];
        docApi.PPA_Document_Endpoint__c = '/error';
        update docApi;

        Test.startTest();                
        returnVals = PPA_MulesoftDocumentGeneration.submitRequest(priceList.Id, 'TEST', true, true);
        Assert.areEqual('-1', returnVals.get('errorCode'));
        Test.stopTest();
    }

    @isTest
    public static void submitRequestTestPDFReturned() {
        Map<String,String> returnVals = new Map<String,String>();
        Test.setMock(HttpCalloutMock.class, new PPA_GeneratePDFHttpCalloutMock_Test());
        PPA_Price_List__c priceList = [SELECT Id FROM PPA_Price_List__c LIMIT 1];

        PPA_MulesoftDocumentApi__c docApi = [SELECT Id, PPA_Document_Endpoint__c, PPA_Token_Endpoint__c FROM PPA_MulesoftDocumentApi__c LIMIT 1];
        docApi.PPA_Document_Endpoint__c = '/pdf';
        update docApi;

        Test.startTest();                
        returnVals = PPA_MulesoftDocumentGeneration.submitRequest(priceList.Id, 'TEST', true, true);
        Assert.areEqual('0', returnVals.get('errorCode'));
        Test.stopTest();
    }

    @isTest
    public static void submitRequestTestInvalidContentType() {
        Map<String,String> returnVals = new Map<String,String>();
        Test.setMock(HttpCalloutMock.class, new PPA_GeneratePDFHttpCalloutMock_Test());
        PPA_Price_List__c priceList = [SELECT Id FROM PPA_Price_List__c LIMIT 1];

        PPA_MulesoftDocumentApi__c docApi = [SELECT Id, PPA_Document_Endpoint__c, PPA_Token_Endpoint__c FROM PPA_MulesoftDocumentApi__c LIMIT 1];
        docApi.PPA_Document_Endpoint__c = '/other';
        update docApi;

        Test.startTest();                
        returnVals = PPA_MulesoftDocumentGeneration.submitRequest(priceList.Id, 'TEST', true, true);
        Assert.areEqual('-1', returnVals.get('errorCode'));
        Test.stopTest();
    }
}