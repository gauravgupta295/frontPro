/*********************************************************************************************************************
* Apex Class: SBR_3_0_SchedulerUpdate_Test
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - test class for SBR_3_0_SchedulerUpdateDFSCountOnAsset
----------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Ritesh Mohapatra      2023-06-01           Initial version    
*********************************************************************************************************************/
@IsTest
public class SBR_3_0_SchedulerUpdate_Test {

    @IsTest
    static void testSchedulableBatchJob(){
        
        Test.startTest();
        SBR_3_0_SchedulerUpdateDFSCountOnAsset sh1 = new SBR_3_0_SchedulerUpdateDFSCountOnAsset();
        String sch = '0 0 2 * * ?'; 
        System.schedule('Test Territory Check', sch, sh1); 
        Test.stopTest();
    }
}