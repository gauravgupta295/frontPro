@isTest
public class PPA_DocumentPayloadGenerator_Test {
    
    @TestSetup
    static void testSetup() {
        PPA_GeneratePDFUtility_Test.makeData();        
    }

    @isTest
    public static void generatePayloadTest() {
        Map<String,Object> returnVals = new Map<String,Object>();
        PPA_Price_List__c priceList = [SELECT Id FROM PPA_Price_List__c LIMIT 1];

        Test.startTest();
        returnVals = PPA_DocumentPayloadGenerator.generatePayload(priceList.Id, true, true);
        system.debug(returnVals);
        Assert.areEqual(12, returnVals.size());
        Assert.areEqual('TEST', returnVals.get('Name'));
        Test.stopTest();
    }

    @isTest
    public static void generatePayloadTestRenewal() {
        Map<String,Object> returnVals = new Map<String,Object>();
        PPA_Price_List__c priceList = [SELECT Id FROM PPA_Price_List__c LIMIT 1];
        priceList.RecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'PPA_Price_List__c' AND DeveloperName = 'PPA_Renewal'].Id;
        update priceList;

        Test.startTest();
        returnVals = PPA_DocumentPayloadGenerator.generatePayload(priceList.Id, true, true);
        system.debug(returnVals);
        Assert.areEqual(12, returnVals.size());
        Assert.areEqual('TEST', returnVals.get('Name'));
        Test.stopTest();
    }

    @isTest
    public static void generatePayloadTestException() {
        Map<String,Object> returnVals = new Map<String,Object>();

        Test.startTest();
        returnVals = PPA_DocumentPayloadGenerator.generatePayload('TEST', true, true);
        system.debug(returnVals);
        Assert.areEqual(0, returnVals.size());
        Test.stopTest();
    }
}