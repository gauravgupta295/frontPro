/*********************************************************************************************************************
* Apex Class: SBR_3_0_LocationDA_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_LocationDA
* - 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Saathvik Tulasi      2023-01-11             Initial version    
*********************************************************************************************************************/
@isTest(seeAllData=false) 
public class SBR_3_0_LocationDA_Test {
    @TestSetup
    static void makeData(){       
 		// Create Branch
        Schema.Location branchLocation = new Schema.Location();
        branchLocation.Branch_Location_Number__c = '720';
        branchLocation.Name = 'Test Branch Location';
        branchLocation.Street_Address__c = '12 Main Street';
        branchLocation.City__c = 'Toronto';
        branchLocation.Zip_Code__c = 'M7N7B3';
        branchLocation.State__c = 'ON';
        branchLocation.Country__c = 'CA';
        branchLocation.Job_Number__c='332112';
        branchLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        branchLocation.Company_Code__c = 'X';
        branchLocation.Time_Zone_Name__c = 'America/Chicago';
        branchLocation.Time_Zone__c = 3;
        branchLocation.Analysis_Region_Key__c = '921';
        insert branchLocation;
    }

	/************************************************************* Cover getBranchByBranchNumber Starts*************************************************************/
    public Static testMethod void getBranchByBranchNumber(){
		Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oUsers = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        List<Product2> lProducts = SBR_3_0_TestDataFactory.createProducts(3,TRUE);
        String branchNumber;
        String cc;
        System.runAs(oUsers){
            Test.startTest();
            Schema.Location loc = SBR_3_0_TestDataFactory.createLocations(1, FALSE, 'Branch')[0];
            loc.Branch_Location_Number__c = '1234';
            loc.Company_Code__c = '234';
            INSERT loc;
            Schema.Location oLocation = SBR_3_0_LocationDA.getBranchByBranchNumber('1234','234');
            Test.stopTest();
        }
    }
    /************************************************************* Cover getBranchByBranchNumber Ends*************************************************************/
    @isTest
    static void testGetLocations(){
        Schema.Location loc = [SELECT Id FROM Location Limit 1];
        Set<Id> locationIds = new Set<Id>();
        locationIds.add(loc.Id);
        
        Test.startTest();
        Map<Id, Schema.Location> retrievedLocation = SBR_3_0_LocationDA.getLocations(locationIds);
        Test.stopTest();
        
        System.assert(!retrievedLocation.isEmpty());
    }
    
    @isTest
    static void testGetLocation(){
        Test.startTest();
        List<Schema.Location> retrievedLocation = SBR_3_0_LocationDA.getLocation('720');
        Test.stopTest();
        
        System.assert(retrievedLocation.size() > 0);
    }
}