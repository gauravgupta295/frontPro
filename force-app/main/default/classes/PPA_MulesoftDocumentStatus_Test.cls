@isTest
public with sharing class PPA_MulesoftDocumentStatus_Test {
    
    @TestSetup
    public static void testSetup(){
        PPA_GeneratePDFUtility_Test.makeData();
    }
    
    @isTest
    public static void getDocumentStatus200() {
        Map<String,String> returnVals = new Map<String,String>();
        Test.setMock(HttpCalloutMock.class, new PPA_GeneratePDFHttpCalloutMock_Test());
        PPA_Price_List__c priceList = [SELECT Id FROM PPA_Price_List__c LIMIT 1];
        
        Test.startTest();
        returnVals = PPA_MulesoftDocumentStatus.getDocumentStatus(priceList.Id, 'TEST', true, '12345', '12345', 1);
        Assert.areEqual('0', returnVals.get('errorCode'));
        Assert.areEqual('Completed', returnVals.get('status'));
        Test.stopTest();
    }

    @isTest
    public static void getDocumentStatus400() {
        Map<String,String> returnVals = new Map<String,String>();
        Test.setMock(HttpCalloutMock.class, new PPA_GeneratePDFHttpCalloutMock_Test());
        PPA_Price_List__c priceList = [SELECT Id FROM PPA_Price_List__c LIMIT 1];

        PPA_MulesoftDocumentApi__c docApi = [SELECT Id, PPA_Document_Endpoint__c FROM PPA_MulesoftDocumentApi__c LIMIT 1];
        docApi.PPA_Document_Endpoint__c = '/error';
        update docApi;
        
        Test.startTest();
        returnVals = PPA_MulesoftDocumentStatus.getDocumentStatus(priceList.Id, 'TEST', true, '12345', '12345', 1);
        Assert.areEqual('-1', returnVals.get('errorCode'));
        Test.stopTest();
    }
    
    @isTest
    public static void getDocumentStatusInProgress() {
        Map<String,String> returnVals = new Map<String,String>();
        Test.setMock(HttpCalloutMock.class, new PPA_GeneratePDFHttpCalloutMock_Test());
        PPA_Price_List__c priceList = [SELECT Id FROM PPA_Price_List__c LIMIT 1];

        PPA_MulesoftDocumentApi__c docApi = [SELECT Id, PPA_Document_Endpoint__c FROM PPA_MulesoftDocumentApi__c LIMIT 1];
        docApi.PPA_Document_Endpoint__c = '/status';
        update docApi;
        
        Test.startTest();
        returnVals = PPA_MulesoftDocumentStatus.getDocumentStatus(priceList.Id, 'TEST', true, '12345', '12345', 1);
        Assert.areEqual('0', returnVals.get('errorCode'));
        Test.stopTest();
    }    
}