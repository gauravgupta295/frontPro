@isTest
public with sharing class PPA_ExceptionLogHandler_Test {

    @isTest
    public static void createExceptionLogTest() {
        Map<String,String> exceptionParams = new Map<String,String>();
        List<Exception_Log__c> logs = new List<Exception_Log__c>();

        exceptionParams.put('ClassName','TEST');
        exceptionParams.put('Message','TEST');
        exceptionParams.put('Type','TEST');
        exceptionParams.put('Limit','TEST');
        exceptionParams.put('LineNumber','1');
        exceptionParams.put('MethodName','TEST');
        exceptionParams.put('StackTrace','TEST');

        Test.startTest();
        PPA_ExceptionLogHandler.createExceptionLog(exceptionParams);
        logs = [SELECT Id FROM Exception_Log__c LIMIT 1];
        Assert.isNotNull(logs[0].Id, 'Exception record was not found');
        Test.stopTest();
    }
}