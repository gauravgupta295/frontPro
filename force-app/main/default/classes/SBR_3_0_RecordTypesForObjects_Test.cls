@isTest
public with sharing class SBR_3_0_RecordTypesForObjects_Test {
    @isTest
    static void givenValidsObjectReturnRecordType(){
        RecordType recordType = [SELECT Name FROM RecordType WHERE SObjectType = 'Account' LIMIT 1];
        Test.startTest();
            Map<Id,String> returnedRecordNames = SBR_3_0_RecordTypesForObject.getRecordTypeIdsToName('Account');
            System.assertEquals(recordType.Name, returnedRecordNames.values()[0]);
        Test.stopTest();
    }
    
    @isTest
    static void givenValidsObjectReturnIdOfRecordType(){
        RecordType recordTypeIds = [SELECT Name, Id FROM RecordType WHERE SobjectType = 'Account' LIMIT 1];

        Test.startTest();
            Map<String,Id> returnedRecordIds = SBR_3_0_RecordTypesForObject.getRecordTypeNameToIds('Account');
			Map<String,Id> getRecordTypeName = SBR_3_0_RecordTypesForObject.getRecordTypeNameToIds('Account');
        	Map<String,Id> getRecordTypeDevName = SBR_3_0_RecordTypesForObject.getRecordTypeDevNameToIds('Account');
            System.assertEquals(recordTypeIds.Id, returnedRecordIds.get(recordTypeIds.Name), 'Match');
        Test.stopTest();
    }
}