/*********************************************************************************************************************
* Apex Class: SBR_3_0_LogException_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description Test class for SBR_3_0_LogException
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Konrad Haight           2022-03-08          Initial version    
*********************************************************************************************************************/
@isTest
private class SBR_3_0_LogException_Test {

    @IsTest
    static void validateExceptionLogging(){

        DmlException d = new DmlException();
        d.setMessage('Test');

        SBR_3_0_LogException.LogIt(d);

        Exception_Log__c el = [SELECT Id, Exception_Message__c FROM Exception_Log__c];

        System.assertEquals(d.getMessage(), el.Exception_Message__c, 'Error message mismatch' );
        System.assertEquals(el.Exception_Message__c, 'Test', 'Exception message did not match expected value');

    }

    @isTest
    static void testLogIt(){
        DmlException d = new DmlException();
        d.setMessage('Test');

        SBR_3_0_LogException.LogIt(d,'Test');

        Exception_Log__c el = [SELECT Id, Exception_Message__c FROM Exception_Log__c];

        System.assertEquals(d.getMessage(), el.Exception_Message__c, 'Error message mismatch' );
        System.assertEquals(el.Exception_Message__c, 'Test', 'Exception message did not match expected value');
    }

    @isTest
    static void testLogIt1(){
        DmlException d = new DmlException();
        d.setMessage('Test');

        SBR_3_0_LogException.LogIt(d,'123','Test Payload');

        Exception_Log__c el = [SELECT Id, RequestJSON__c, Related_To_Number__c, Exception_Message__c FROM Exception_Log__c];

        //Payload added to its own field now
        System.assertEquals(el.Exception_Message__c, 'Test', 'Exception message did not match expected value');
        System.assertEquals('123', el.Related_To_Number__c, 'Related to number did not match exepcted value');
        System.assertEquals('Test Payload' , el.RequestJSON__c, 'Payload did not match expected value');
    }
}