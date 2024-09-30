/*********************************************************************************************************************
* Apex Class: SBR_3_0_UpdateTechnicalAttributesBatTest
----------------------------------------------------------------------------------------------------------------------
* @description Test class for SBR_3_0_UpdateTechnicalAttributesBatch
----------------------------------------------------------------------------------------------------------------------
* History:
* VERSION     DEVELOPER NAME        DATE            MOD LOG
    1.0       Evan Kuminski         2024-Apr-17     Initial version
**********************************************************************************************************************/

@IsTest
private class SBR_3_0_UpdateTechnicalAttrBatch_Test {
    private static final String CALLOUT_RESPONSE_BODY = '{"success":true,"message":"Technical Attribute value(s) saved successfully.","data":{"targetObject":"SVMXA360__SM_TA_AssetTechnicalAttribute__c","source":"External System","objectName":"Asset","attributeList":[{"value":"21","unit":"","timeOfOccurence":"","recordName":"","recordId":"02i8D000002AJZDQA4","dataType":"Number","attributeKey":"Calendar_Days_Number","assetIdentifiers":[{"value":"","identifierName":""}]},{"value":"600","unit":"","timeOfOccurence":"","recordName":"","recordId":"02i8D000002AJZDQA4","dataType":"Number","attributeKey":"Rental_Days_Number","assetIdentifiers":[{"value":"","identifierName":""}]},{"value":"30","unit":"","timeOfOccurence":"","recordName":"","recordId":"02i8D000002AJZDQA4","dataType":"Number","attributeKey":"Meter_Number","assetIdentifiers":[{"value":"","identifierName":""}]}],"assetIdentifierFieldAPIName":"Name"}}';
    @TestSetup
    static void setup() {
        Asset testAsset = SBR_3_0_ServiceTestDataFactory.createAsset(false);
        testAsset.SM_PS_Date_Commissioned__c = Date.today();
        testAsset.RecordTypeId = Asset.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).recordTypeInfosByDeveloperName.get('Customer_Owned_Asset').recordTypeId;
        insert testAsset;

        insert new LoggerSettings__c(SetupOwnerId = UserInfo.getOrganizationId(), IsEnabled__c = true);
    }

    @IsTest
    static void constructorCalloutLimitDetectionTest() {
        Integer batchSize = 2000;
        Integer recordsPerCallout = batchSize / (2 * Limits.getLimitCallouts());

        Boolean hasEncounteredException = false;
        Test.startTest();
        {
            try {
                new SBR_3_0_UpdateTechnicalAttributesBatch(batchSize, recordsPerCallout);
            } catch (IllegalArgumentException ex) {
                hasEncounteredException = true;
            }
        }
        Test.stopTest();

        Assert.isTrue(hasEncounteredException, 'Expected an IllegalArgumentException');
    }

    @IsTest
    static void executeTest() {
        SBR_3_0_CalloutMock calloutMock = new SBR_3_0_CalloutMock(new SBR_3_0_CalloutMock.MockResponse(200, CALLOUT_RESPONSE_BODY));
        Test.setMock(HttpCalloutMock.class, calloutMock);

        Test.startTest();
        {
            (new SBR_3_0_UpdateTechnicalAttributesBatch()).execute(null);
        }
        Test.stopTest();

        Id assetId = [SELECT Id FROM Asset LIMIT 1].Id;

        Assert.areEqual(
                '{"source":"External System","objectName":"Asset","assetIdentifierFieldAPIName":"Name","attributeList":[{"value":"0","attributeKey":"Calendar_Days_Number","dataType":"Number","recordId":"' + assetId + '"}]}',
                calloutMock.requests[0].getBody(),
                'Request body appears to be malformed.'
        );
    }

    @IsTest
    static void makeCalloutGivenBadStatusCodeShouldGenerateExceptionLog() {
        SBR_3_0_CalloutMock calloutMock = new SBR_3_0_CalloutMock(new SBR_3_0_CalloutMock.MockResponse(500, CALLOUT_RESPONSE_BODY));
        Test.setMock(HttpCalloutMock.class, calloutMock);

        Test.startTest();
        {
            SBR_3_0_UpdateTechnicalAttributesBatch.makeCallout('Mock Body');
        }
        Test.stopTest();
        Test.getEventBus().deliver();

        Assert.areEqual(
            1,
            [SELECT COUNT() FROM Exception_Log__c],
            'A non-200 response should generate exactly one exception log'
        );
    }

    @IsTest
    static void makeCalloutGivenCalloutExceptionShouldGenerateExceptionLog() {
        SBR_3_0_CalloutMock calloutMock = new SBR_3_0_CalloutMock(new SBR_3_0_CalloutMock.MockResponse(200, CALLOUT_RESPONSE_BODY, new CalloutException('Test Exception')));
        Test.setMock(HttpCalloutMock.class, calloutMock);

        Test.startTest();
        {
            SBR_3_0_UpdateTechnicalAttributesBatch.makeCallout('Mock Body');
        }
        Test.stopTest();

        Assert.areEqual(
                1,
                [SELECT COUNT() FROM Exception_Log__c],
                'A callout triggering an exception should generate exactly one exception log'
        );
    }
}