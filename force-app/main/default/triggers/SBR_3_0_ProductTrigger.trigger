trigger SBR_3_0_ProductTrigger on Product2 (before insert, before update)
{
    new SBR_3_0_ProductTriggerHandler().run();
}