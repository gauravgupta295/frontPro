/*********************************************************************************************************************
* Apex Class: SBR_3_0_WorkStepTemplateTriggerTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for the WorkStepTemplate trigger
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-08-28           Initial version
    2.0         Evan Kuminski, Salesforce           2023-10-05           Updated to reflect changes to how Record Source of Update is now set
                                                                         Moved repetitive SOQL queries to a new method
    3.0         Evan Kuminski, Salesforce           2023-10-19           Updated to reflect new locations of some constants
*********************************************************************************************************************/

@IsTest
private class SBR_3_0_WorkStepTemplateTriggerTest {
    @TestSetup
    static void dataSetup() {
        WorkStepTemplate template = SBR_3_0_ServiceTestDataFactory.createWorkStepTemplate(false);
        template.IsActive = true;
        template.SM_PS_Company_Code__c = '01';
        template.SM_PS_Labor_Code__c = '1234';
        template.SM_PS_Maintenance_Step_Y_N__c = 'N';
        template.SM_PS_Salesforce_Only__c = false;
        template.SM_PS_Search_Word__c = 'TEST';
        template.SM_PS_Step_Number__c = 'TEST';
        insert template;
    }

    @IsTest
    static void sendToRentalManWhenSendToRMCheckedSingleCompanyCode() {
        WorkStepTemplate template = [SELECT Id FROM WorkStepTemplate];
        Test.startTest();
        {
            template.SM_PS_Send_to_RM__c = true;
            update template;
        }
        Test.stopTest();
        List<Outbox__c> results = getOutboxesByRecordIdAndSourceOfUpdate(
                template.Id,
                SBR_3_0_PublishToOutboxWithoutQuery.CREATE_RECORD_SOURCE_OF_UPDATE
        );
        Assert.areEqual(1, results.size());
    }

    @IsTest
    static void sendToRentalManWhenSendToRMCheckedMultipleCompanyCodes() {
        WorkStepTemplate template = [SELECT Id FROM WorkStepTemplate];
        Test.startTest();
        {
            template.SM_PS_Company_Code__c = '02';
            template.SM_PS_Send_to_RM__c = true;
            update template;
        }
        Test.stopTest();
        List<Outbox__c> newOutboxes = getOutboxesByRecordIdAndSourceOfUpdate(
                template.Id,
                SBR_3_0_PublishToOutboxWithoutQuery.CREATE_RECORD_SOURCE_OF_UPDATE
        );
        List<Outbox__c> deleteOutboxes = getOutboxesByRecordIdAndSourceOfUpdate(
                template.Id,
                SBR_3_0_PublishToOutboxWithoutQuery.DELETE_RECORD_SOURCE_OF_UPDATE
        );
        Assert.areEqual(1, newOutboxes.size());
        Assert.areEqual(1, deleteOutboxes.size());
        Assert.isTrue(newOutboxes[0].Record_JSON__c.contains('"SM_PS_Company_Code__c":"02"'));
        Assert.isTrue(deleteOutboxes[0].Record_JSON__c.contains('"SM_PS_Company_Code__c":"01"'));
    }

    @IsTest
    static void sendToRentalManUpdateSentRecord() {
        WorkStepTemplate template = [SELECT Id FROM WorkStepTemplate];
        template.SM_PS_Send_to_RM__c = true;
        update template;
        Test.startTest();
        {
            template.SM_PS_Labor_Code__c = '2345';
            update template;
        }
        Test.stopTest();
        List<Outbox__c> results = getOutboxesByRecordIdAndSourceOfUpdate(
                template.Id,
                SBR_3_0_PublishToOutboxWithoutQuery.UPDATE_RECORD_SOURCE_OF_UPDATE
        );
        Assert.areEqual(1, results.size());
        Assert.isTrue(results[0].Record_JSON__c.contains('"SM_PS_Labor_Code__c":"2345"'));
    }

    @IsTest
    static void sendToRentalManDeactivateTemplate() {
        WorkStepTemplate template = [SELECT Id FROM WorkStepTemplate];
        template.SM_PS_Send_to_RM__c = true;
        update template;
        Test.startTest();
        {
            template.IsActive = false;
            update template;
        }
        Test.stopTest();
        List<Outbox__c> results = getOutboxesByRecordIdAndSourceOfUpdate(
                template.Id,
                SBR_3_0_PublishToOutboxWithoutQuery.DELETE_RECORD_SOURCE_OF_UPDATE
        );
        Assert.areEqual(1, results.size());
    }

    private static List<Outbox__c> getOutboxesByRecordIdAndSourceOfUpdate(Id recordId, String recordSourceOfUpdate) {
        return [
                SELECT
                        Id, Record_JSON__c, Record_Source_Of_Update__c
                FROM
                        Outbox__c
                WHERE
                        Record_Id__c = :recordId AND
                        Record_Source_Of_Update__c = :recordSourceOfUpdate
        ];
    }
}