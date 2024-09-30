/*********************************************************************************************************************
* Apex Class: SBR_3_0_EqpMaintenanceStepTriggerTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Tests for Eqp Maintenance Step trigger
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-10-19           Initial version
*********************************************************************************************************************/

@IsTest
private class SBR_3_0_EqpMaintenanceStepTriggerTest {
    private static final String BASE_EQP_MAINTENANCE_STEP_JSON = JSON.serialize(new SM_PS_Eqp_Maintenance_Step__c());

    @IsTest
    private static void activateTrigger() {
        SM_PS_Eqp_Maintenance_Step__c eqpMaintenanceStep = new SM_PS_Eqp_Maintenance_Step__c();
        insert eqpMaintenanceStep;
        update eqpMaintenanceStep;
    }

    @IsTest
    private static void shouldPublishOutbox_givenInactiveRecord_shouldReturnFalse() {
        SM_PS_Eqp_Maintenance_Step__c oldEqpMaintenanceStep = new SM_PS_Eqp_Maintenance_Step__c();
        SM_PS_Eqp_Maintenance_Step__c newEqpMaintenanceStep = (SM_PS_Eqp_Maintenance_Step__c)JSON.deserialize(
                String.format('{0},"{1}":"{2}"}', new List<Object>{
                        BASE_EQP_MAINTENANCE_STEP_JSON.removeEnd('}'),
                        SM_PS_Eqp_Maintenance_Step__c.SM_PS_Status__c,
                        'Deactivated'
                }),
                SM_PS_Eqp_Maintenance_Step__c.class
        );
        Boolean result;
        Test.startTest();
        {
            result = SBR_3_0_EqpMaintenanceStepOperations.shouldPublishOutbox(oldEqpMaintenanceStep, newEqpMaintenanceStep);
        }
        Test.stopTest();
        Assert.isFalse(result);
    }
    
    @IsTest
    private static void testOutboxGeneration() {
        Id mockId = SM_PS_Eqp_Maintenance_Step__c.SObjectType.getDescribe().keyPrefix + '000000000000';
        Map<Id, SM_PS_Eqp_Maintenance_Step__c> oldEqpMaintenanceStepsById = new Map<Id, SM_PS_Eqp_Maintenance_Step__c>{
                mockId => (SM_PS_Eqp_Maintenance_Step__c) JSON.deserialize(
                        String.format(
                                '{0},"{1}":"{2}","{3}":"{4}","{5}":"{6}","{7}":"{8}"}',
                                new List<Object>{
                                        BASE_EQP_MAINTENANCE_STEP_JSON.removeEnd('}'),
                                        SM_PS_Eqp_Maintenance_Step__c.Id, mockId,
                                        SM_PS_Eqp_Maintenance_Step__c.SM_PS_Status__c, 'Active',
                                        SM_PS_Eqp_Maintenance_Step__c.Name, 0,
                                        SM_PS_Eqp_Maintenance_Step__c.SM_PS_Company_Code__c, '01'
                                }
                        ),
                        SM_PS_Eqp_Maintenance_Step__c.class
                )
        };
        List<SM_PS_Eqp_Maintenance_Step__c> newEqpMaintenanceSteps = new List<SM_PS_Eqp_Maintenance_Step__c>{
                (SM_PS_Eqp_Maintenance_Step__c) JSON.deserialize(
                        String.format(
                                '{0},"{1}":"{2}","{3}":"{4}","{5}":"{6}","{7}":"{8}"}',
                                new List<Object>{
                                        BASE_EQP_MAINTENANCE_STEP_JSON.removeEnd('}'),
                                        SM_PS_Eqp_Maintenance_Step__c.Id, mockId,
                                        SM_PS_Eqp_Maintenance_Step__c.SM_PS_Status__c, 'Active',
                                        SM_PS_Eqp_Maintenance_Step__c.Name, 1,
                                        SM_PS_Eqp_Maintenance_Step__c.SM_PS_Company_Code__c, '01'
                                }
                        ),
                        SM_PS_Eqp_Maintenance_Step__c.class
                )
        };

        Test.startTest();
        {
            SBR_3_0_EqpMaintenanceStepOperations.publishUpdatesToOutbox(newEqpMaintenanceSteps, oldEqpMaintenanceStepsById);
        }
        Test.stopTest();

        List<Outbox__c> results = [SELECT Id, Record_Id__c FROM Outbox__c];
        Assert.areEqual(1, results.size());
        Assert.areEqual(mockId, results[0].Record_Id__c);
    }
}