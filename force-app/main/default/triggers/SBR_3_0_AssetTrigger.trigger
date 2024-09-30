/*********************************************************************************************************************
* Apex Class: SBR_3_0_AssetTrigger
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to check Asset After Update actions
* - SAL- 4736 - Check Status update and set the Counters on the Product Item record
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Bill Convis ServiceMax          2022-07-15           Initial version
    2.0         Tom Canter                         2022-09-30           SAL-6263 Added Outbox Events
    3.0         Evan Kuminski, Salesforce          2023-07-27           Remove logic for maintaining Quantity fields on Product Item
                                                                        Create Stocked Serial record(s) after Asset creation
*********************************************************************************************************************/
trigger SBR_3_0_AssetTrigger on Asset (after insert, after update) {
    new SBR_3_0_AssetTriggerHandler().run();
}