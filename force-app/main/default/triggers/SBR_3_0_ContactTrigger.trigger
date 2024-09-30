trigger SBR_3_0_ContactTrigger on Contact (before insert, before update)
{
    new SBR_3_0_ContactTriggerHandler().run();
}