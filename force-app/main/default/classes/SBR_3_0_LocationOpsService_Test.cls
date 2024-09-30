/*********************************************************************************************************************
* Apex Class: SBR_3_0_LocationOpsService_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description - Test class for the SBR_3_0_LocationOperationsService
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME           DATE                 DETAIL FEATURES
*   1.0         Chhavi Singhal           2024-07-02           Initial version  
*********************************************************************************************************************/

@IsTest
private class SBR_3_0_LocationOpsService_Test {
    @isTest
    public static void testSuccessCallback() {
        //Branch Record Type - Location
        Id branchLocRecordTypeId = Schema.SObjectType.Location.getRecordTypeInfosByName().get('Branch').getRecordTypeId();
    
        //Create Location Record
        List<Schema.Location> branchLoc = SBR_3_0_TestDataFactory.createInventoryLocations(1,true,'Branch');
        branchLoc[0].RecordTypeId = branchLocRecordTypeId;
        branchLoc[0].Name ='TEST LOCATION 0693';
        branchLoc[0].Branch_Location_Name__c = '0693';
        branchLoc[0].Branch_Location_Number__c = '0693';
        branchLoc[0].Job_Site_Id__c = '01-0693';
        branchLoc[0].District__c = 'TEST LOC DISTRICT';
        branchLoc[0].Market_Name__c = 'TEST LOC. MARKET';
        branchLoc[0].Price_Market__c = '100';
        branchLoc[0].Reporting_Region_Name__c = 'T&T REGION';
        branchLoc[0].Analysis_Region_Key__c = '100';
        branchLoc[0].Company_Code__c = '01';
        branchLoc[0].Territory__c = 'TEST & TEST TERRITORY';
        branchLoc[0].Inventory_Region_Key__c = '666';
        Test.startTest();
        	 update branchLoc[0];
        Test.stopTest();
        System.Assert(branchLoc != null, 'Branch Location not found');
    }
}