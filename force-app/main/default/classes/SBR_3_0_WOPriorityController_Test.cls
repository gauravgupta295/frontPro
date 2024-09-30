/*********************************************************************************************************************
* Apex Class: SBR_3_0_WOPriorityController_Test
---------------------------------------------------------------------------------------------------------------------
* @description
* - Test class for SBR_3_0_WOPriorityController
---------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
*   1.0         Chhavi Singhal          5-Jan-2024          Initial version
*   1.1 		Ritesh Mohapatra  		1-Feb-2024			Added New Methods getStandardFiltersDetails() &  
															getCurrentUserLocation()
*********************************************************************************************************************/
@isTest
public class SBR_3_0_WOPriorityController_Test {
    public static Asset assetRec1 = new Asset();
    @TestSetup
    static void createDataWOPriorityController() {
        //Create Location
        Id user = UserInfo.getUserId();
        List<Schema.Location> branch = SBR_3_0_TestDataFactory.createInventoryLocations(1,true,'Branch');
        branch[0].Branch_Location_Number__c ='657';
        update branch[0];
        //Create User Location
        User_location__c userLocation = new User_location__c(branch__c = branch[0].Id,User__c = user);
        insert userLocation;
        
        //Asset RecordType
        RecordType rt = [SELECT Id, DeveloperName, IsActive, Name, SobjectType FROM RecordType WHERE IsActive = true AND SobjectType = 'Asset' AND Name = 'Rental Asset'];
        //Create Asset Record
        assetRec1.RecordTypeId = rt.Id;
        assetRec1.SM_PS_Current_Location__c = branch[0].id;
        assetRec1.SM_PS_Assigned_Location__c = branch[0].id;
        assetRec1.Status = 'Available';
        assetRec1.Name = '112233';
        assetRec1.SM_PS_Category__c = '657';
        assetRec1.SM_PS_Class__c = '657';
        assetRec1.SM_PS_Company_Code__c = '01';
        assetRec1.SM_PS_Cat_Class__c = 'TESTCATCLASS';
        assetRec1.SM_PS_Last_Transaction_Date__c = Date.today();
        insert assetRec1;
        
        //Create Service Resource Record (Technician)
        ServiceResource sr = new ServiceResource();
        sr.name = 'Test Resouce';
        sr.SF_PS_Company_Code__c = '01';
        sr.SF_PS_Hourly_Billing_Rate__c = 5.0;
        sr.SF_PS_Hourly_Internal_Rate__c = 5.0;
        sr.SF_PS_Overtime_Billing_Rate__c = 5.0;
        sr.SF_PS_Overtime_Internal_Rate__c = 5.0;
        sr.SF_PS_Labor_Type__c = 'I';
        sr.SF_PS_Type__c = 'D';
        sr.ResourceType = 'T';
        sr.IsActive = True;
        sr.SF_PS_Branch_Loc_Num__c = '1234';
        sr.SF_PS_Comments__c = 'Created By Test Factory';
        sr.SF_PS_RM_Created_DateTime__c = system.now().addHours(-1);
        sr.SF_PS_RM_Created_By__c = 'Test Factory';
        sr.SF_PS_RM_Update_DateTime__c = system.now().addMinutes(-10);
        sr.SF_PS_RM_Updated_By_User__c = 'API Call';
        sr.RelatedRecordId = UserInfo.getUserId();
        insert sr;
        
		//Create Operating Hours Record
        OperatingHours oh = new OperatingHours(Name='TEST_Hours',TimeZone='America/Halifax');
        insert oh;
        //Create Service Territory Record
        ServiceTerritory st = new ServiceTerritory( Name='New Test Territory',
                                                    OperatingHoursId=oh.Id,
                                                    IsActive=true,
                                                    Branch_Location_Number__c = '1234',
                                                    CountryCode = 'US');        
        insert st;
        
        //Create Work Order Record
        workOrder testWO = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        testWO.RecordTypeId = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByName().get('Credit').getRecordTypeId();
        testWO.Status = 'Open'; 
        testWO.SF_PS_Date_Opened__c = system.now().addDays(-1);
        testWO.CurrencyIsoCode = 'USD';
        testWO.AssetId = assetRec1.id;
        testWO.SF_PS_Service_Resource__c = sr.id;
        testWO.SF_PS_Expense_To_Location__c = st.id;
        insert testWO;
        
    }
    
    @isTest
    public static void testPositiveWOPriorityController() {
        List<SBR_3_0_WOPriority_Standard_Filters__mdt> stdFiltersList = new  List<SBR_3_0_WOPriority_Standard_Filters__mdt>();
        List<SBR_3_0_AssetInquiryPicklistValues__mdt> assetInqList = new List<SBR_3_0_AssetInquiryPicklistValues__mdt>();
		List<CustomDataTableCmpColumn__mdt> lstColumns = new List<CustomDataTableCmpColumn__mdt>();        
        Schema.Location userLoc = new Schema.Location();
        Schema.User_Location__c userLocRecord = new Schema.User_Location__c();
        List<String> pickListValues = new List<String>();
		Integer workOrderCount ;
	    List<WorkOrder> woList = new List<WorkOrder>();
        
        Test.startTest();
        		stdFiltersList = SBR_3_0_WOPriorityController.getStandardFiltersDetails('WorkOrder');
                assetInqList = SBR_3_0_WOPriorityController.getPicklistMetadata('District');
                assetInqList = SBR_3_0_WOPriorityController.getPicklistMetadata('Level');
        		userLocRecord = SBR_3_0_WOPriorityController.getCurrentUserLocationRecord();
                lstColumns = SBR_3_0_WOPriorityController.getItemSearchColumns();
                pickListValues = SBR_3_0_WOPriorityController.getPickListValuesFromFields('Asset','Status');
                workOrderCount = SBR_3_0_WOPriorityController.getFilteredWorkOrdersCount('SELECT count() FROM WorkOrder');
                woList = SBR_3_0_WOPriorityController.getFilteredWorkOrders('SELECT Id FROM WorkOrder');
                System.AssertNotEquals(woList,null,'Assert is failing');
            try{   
                userLoc = SBR_3_0_WOPriorityController.getCurrentUserLocation(); 
            } catch(Exception e){
                    
            }
        Test.stopTest();
    }
}