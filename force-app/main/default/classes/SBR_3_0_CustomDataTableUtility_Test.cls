@isTest
public with sharing class SBR_3_0_CustomDataTableUtility_Test{
    @isTest
    public static void getColumnsTest(){
        Test.startTest();
        List<CustomDataTableCmpColumn__mdt> tableCols = SBR_3_0_CustomDataTableUtility.getColumns('Contract Account Summary');
        Test.stopTest();
        System.assertEquals(7, tableCols.size(), '7 records are expected');
    }
}