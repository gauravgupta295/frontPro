trigger SBR_3_0_EngineeringRequestTrigger on Engineering_Request__c (before insert) {
    new SBR_3_0_EngineeringRequestTriggerHandler().run();
}