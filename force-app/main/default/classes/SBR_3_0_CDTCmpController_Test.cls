/*********************************************************************************************************************
* Apex Class: SBR_3_0_CustomDataTableCmpController
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_CustomDataTableController class
* - SAL-1351
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Avinash Rao             2022-05-23          Initial version    
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_CDTCmpController_Test { 
    
    static testMethod void testGetItemSearchColumns(){
        Test.startTest();
        List<CustomDataTableCmpColumn__mdt> tableCols = SBR_3_0_CustomDataTableCmpController.getItemSearchColumns();
        Integer count = 0;
        for(CustomDataTableCmpColumn__mdt col : tableCols){
            count = col.Context__c == 'Item Search'? count+1 : count;
        }
        Test.stopTest();
        System.assertEquals(5, count, 'There should be 5 metadata records returned for the Item Search Context.');
    }
}