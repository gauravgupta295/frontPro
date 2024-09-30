@isTest
private class SBR_3_0_ScheduleAddPriceBookEntries_Test {
    
    @isTest
    static void testScheduleAddPriceBookEntries() {
    
       SBR_3_0_ScheduleAddPriceBookEntries scheduler = new SBR_3_0_ScheduleAddPriceBookEntries(10);
        Test.startTest();
        String sch = '0 5 12 * * ?';
        System.schedule('Test_Scheduler', sch, scheduler);
        Test.stopTest();
        Assert.areEqual(1, [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'BatchApex' AND Status = 'Queued'],'Expected Value');
    }
}