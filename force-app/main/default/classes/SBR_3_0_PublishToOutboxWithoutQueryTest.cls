/*********************************************************************************************************************
* Apex Class: SBR_3_0_PublishToOutboxWithoutQueryTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_PublishToOutboxWithoutQuery
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-08-28           Initial version
    2.0         Evan Kuminski, Salesforce           2023-10-05           New test case to slightly boost coverage
    3.0         Evan Kuminski, Salesforce           2023-10-19           Updated for new method signatures on constructors
*********************************************************************************************************************/

@IsTest
private class SBR_3_0_PublishToOutboxWithoutQueryTest {
    @TestSetup
    static void dataSetup() {
        WorkStepTemplate templateToPublish = SBR_3_0_ServiceTestDataFactory.createWorkStepTemplate(false);
        templateToPublish.SM_PS_Step_Number__c = 'TEST';
        insert templateToPublish;
    }

    @IsTest
    static void testStringBasedConstructors() {
        List<WorkStepTemplate> templatesToPublish = [SELECT Id FROM WorkStepTemplate];
        SBR_3_0_PublishToOutboxWithoutQuery publishToOutbox1, publishToOutbox2;
        Test.startTest();
        {
            publishToOutbox1 = new SBR_3_0_PublishToOutboxWithoutQuery(
                    templatesToPublish,
                    'WorkStepTemplate'
            );
            publishToOutbox2 = new SBR_3_0_PublishToOutboxWithoutQuery(
                    templatesToPublish,
                    'WorkStepTemplate',
                    new Set<SObjectField>{},
                    SBR_3_0_PublishToOutboxWithoutQuery.CREATE_RECORD_SOURCE_OF_UPDATE
            );
        }
        Test.stopTest();
        Assert.areEqual(WorkStepTemplate.getSObjectType(), publishToOutbox1.sObjType);
        Assert.areEqual(WorkStepTemplate.getSObjectType(), publishToOutbox2.sObjType);
    }

    @IsTest
    static void publishNewOutbox() {
        List<WorkStepTemplate> templatesToPublish = [SELECT Id FROM WorkStepTemplate];
        SBR_3_0_PublishToOutboxWithoutQuery publishToOutbox = new SBR_3_0_PublishToOutboxWithoutQuery(
                templatesToPublish,
                WorkStepTemplate.getSObjectType()
        );
        Test.startTest();
        {
            publishToOutbox.stageOutboxChanges();
            SBR_3_0_PublishToOutboxWithoutQuery.publishAllOutboxes();
        }
        Test.stopTest();
        List<Outbox__c> results = [SELECT Id FROM Outbox__c WHERE Record_Id__c = :templatesToPublish[0].Id];
        Assert.areEqual(1, results.size());
    }

    @IsTest
    static void publishUpdatedOutbox() {
        List<WorkStepTemplate> templatesToPublish = [SELECT Id FROM WorkStepTemplate];
        insert new Outbox__c(
                Record_Id__c=templatesToPublish[0].Id,
                Record_JSON__c='{}'
        );
        SBR_3_0_PublishToOutboxWithoutQuery publishToOutbox = new SBR_3_0_PublishToOutboxWithoutQuery(
                templatesToPublish,
                WorkStepTemplate.getSObjectType()
        );
        Test.startTest();
        {
            publishToOutbox.stageOutboxChanges();
            SBR_3_0_PublishToOutboxWithoutQuery.publishAllOutboxes();
        }
        Test.stopTest();
        List<Outbox__c> results = [SELECT Id, Record_JSON__c FROM Outbox__c WHERE Record_Id__c = :templatesToPublish[0].Id];
        Assert.areEqual(1, results.size());
        Assert.areNotEqual('{}', results[0].Record_JSON__c);
    }

    @IsTest
    static void publishUpdatedOutboxWithNonMatchingAdditionalFields() {
        List<WorkStepTemplate> templatesToPublish = [SELECT Id, SM_PS_Company_Code__c FROM WorkStepTemplate];
        WorkStepTemplate templateWithUpdatedCompanyCode = templatesToPublish[0].clone();
        templateWithUpdatedCompanyCode.SM_PS_Company_Code__c += 'TEST';
        insert new Outbox__c(
                Record_Id__c = templatesToPublish[0].Id,
                Record_JSON__c = JSON.serialize(templateWithUpdatedCompanyCode)
        );
        SBR_3_0_PublishToOutboxWithoutQuery publishToOutbox = new SBR_3_0_PublishToOutboxWithoutQuery(
                templatesToPublish,
                WorkStepTemplate.getSObjectType(),
                new Set<SObjectField>{WorkStepTemplate.SM_PS_Company_Code__c},
                SBR_3_0_PublishToOutboxWithoutQuery.CREATE_RECORD_SOURCE_OF_UPDATE
        );
        Test.startTest();
        {
            publishToOutbox.stageOutboxChanges();
            SBR_3_0_PublishToOutboxWithoutQuery.publishAllOutboxes();
        }
        Test.stopTest();
        List<Outbox__c> results = [SELECT Id, Record_JSON__c FROM Outbox__c WHERE Record_Id__c = :templatesToPublish[0].Id];
        Assert.areEqual(2, results.size());
    }
}